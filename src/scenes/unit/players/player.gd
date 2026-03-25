extends Unit
class_name Player

@export var dash_duration := 0.5
@export var dash_speed_multi := 2.5
@export var dash_cooldown := 0.5
const HP_REGEN_TICK_INTERVAL := 1.0

@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var hp_regen_timer: Timer = $HPRegenTimer
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var coin_pickup_collision: CollisionShape2D = $CoinPickupArea/CollisionShape2D
@onready var trail: Trail = %Trail
@onready var weapon_container: WeaponContainer = $WeaponContainer

var current_weapons: Array[Weapon] = []

var move_dir: Vector2
var is_dashing := false
var dash_available := true
var moved_right := true
var base_coin_pickup_radius := 0.0
var is_dead := false

func _ready() -> void:
	# Duplicate stats resource to prevent modifying the original resource file
	stats = stats.duplicate()
	
	super._ready()
	var world_health_bar := get_node_or_null("HealthBar") as Control
	if world_health_bar:
		world_health_bar.hide()

	var world_dash_indicator := get_node_or_null("DashIndicator") as Control
	if world_dash_indicator:
		world_dash_indicator.hide()

	if not health_component.on_unit_died.is_connected(_on_health_component_on_unit_died):
		health_component.on_unit_died.connect(_on_health_component_on_unit_died)
	dash_timer.wait_time = dash_duration
	dash_cooldown_timer.wait_time = dash_cooldown
	hp_regen_timer.start(HP_REGEN_TICK_INTERVAL)
	setup_coin_pickup_radius()
	

	#add_weapon(preload("uid://bxayqlg74oyri"))
	#add_weapon(preload("uid://ci0b8f4wu1e2p"))
	#add_weapon(preload("uid://ci0b8f4wu1e2p"))
	#add_weapon(preload("uid://ci0b8f4wu1e2p"))
	#add_weapon(preload("uid://cd4k14vsu0efd"))


func setup_coin_pickup_radius() -> void:
	if not coin_pickup_collision:
		return

	var coin_shape := coin_pickup_collision.shape as CircleShape2D
	if not coin_shape:
		return

	coin_shape = coin_shape.duplicate()
	coin_pickup_collision.shape = coin_shape

	base_coin_pickup_radius = coin_shape.radius
	coin_shape.radius = base_coin_pickup_radius * max(0.1, stats.pickup_range)


func _process(delta: float) -> void:
	_sync_pause_dependent_timers()
	if Global.game_paused: return
	move_dir = Input.get_vector("move_left","move_right","move_up","move_down")
	
	var current_velocity := move_dir * stats.speed
	if is_dashing:
		current_velocity *= dash_speed_multi 
	
	position += current_velocity * delta
	position.x = clamp(position.x, -1000,1000)
	position.y = clamp(position.y, -500,500)

	
	if can_dash():
		start_dash()
		
	update_animations()
	update_rotation()


func _sync_pause_dependent_timers() -> void:
	var should_pause := Global.game_paused
	dash_timer.paused = should_pause
	dash_cooldown_timer.paused = should_pause
	hp_regen_timer.paused = should_pause
	
	
func update_animations() -> void:
	if move_dir.length() > 0:
		anim_player.play("move")
	else:
		anim_player.play("idle")

func update_rotation() -> void:
	if move_dir == Vector2.ZERO:
		return
		
	if move_dir.x >= 0.1:
		moved_right = true
	elif move_dir.x <= -0.1:
		moved_right = false
	else:
		return
		
	visuals.scale.x = -0.5 if moved_right else 0.5
	visuals.scale.y = 0.5
	
func add_weapon(data: ItemWeapon) -> void:
	if current_weapons.size() >= stats.max_weapons:
		return

	var weapon := data.scene.instantiate() as Weapon
	add_child(weapon)
	
	weapon.setup_weapon(data)
	current_weapons.append(weapon)
	weapon_container.update_weapons_position(current_weapons)
	
	
		
func start_dash() -> void:
	is_dashing = true
	dash_timer.start()
	SoundManager.play_sound(SoundManager.Sound.DASH, false, -1.0, -4.0)
	trail.start_trail()
	visuals.modulate.a = 0.5
	collision.set_deferred("disabled",true)
	# Enable invulnerability frames
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	
func can_dash() -> bool:
	return not is_dashing and dash_cooldown_timer.is_stopped() and\
	Input.is_action_just_pressed("dash") and\
	move_dir != Vector2.ZERO
	
func is_facing_right() -> bool:
	return visuals.scale.x == -0.5

func update_player_new_wave() -> void:
	stats.health += stats.health_increase_per_wave
	health_component.setup(stats)


func _on_dash_timer_timeout() -> void:
	is_dashing = false
	visuals.modulate.a = 1.0
	move_dir = Vector2.ZERO
	collision.set_deferred("disabled",false)
	# Disable invulnerability frames
	hurtbox.set_deferred("monitoring", true)
	hurtbox.set_deferred("monitorable", true)
	dash_cooldown_timer.start()
	


func _on_hp_regen_timer_timeout() -> void:
	if health_component.current_health <= 0:
		return
	
	if health_component.current_health < stats.health:
		var heal: float = maxf(0.0, float(stats.hp_regen))
		if heal <= 0.0:
			return
		health_component.heal(heal)
		Global.on_create_heal_text.emit(self, heal)


func _on_health_component_on_unit_died() -> void:
	if is_dead:
		return

	is_dead = true
	is_dashing = false
	dash_timer.stop()
	dash_cooldown_timer.stop()
	collision.set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	coin_pickup_collision.set_deferred("disabled", true)

	if anim_player.has_animation("die"):
		anim_player.play("die")
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout

	queue_free()
