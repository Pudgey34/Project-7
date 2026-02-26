extends Unit

class_name Enemy

@export var flock_push := 10.0
@onready var vision_area: Area2D = $VisionArea
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var hitbox: HitboxComponent = $HitboxComponent

var can_move := true

var knockback_velocity: Vector2
const KNOCKBACK_DECAY := 8.0

func _ready() -> void:
	# Duplicate stats resource to prevent modifying the original resource file
	stats = stats.duplicate()
	
	super._ready()
	hitbox.setup(stats.damage, false, 0, self, null)

func _process(delta: float) -> void:
	if Global.game_paused: return
	if not can_move:
		return
		
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		
	var movement = Vector2.ZERO
	if can_move_towards_player():
		movement = get_move_direction() * stats.speed
	
	position += (movement + knockback_velocity) * delta
	update_rotation()
		
func get_move_direction() -> Vector2:
	if not is_instance_valid(Global.player):
		return Vector2.ZERO
		
	var direction := global_position.direction_to(Global.player.global_position)
	for area: Node2D in vision_area.get_overlapping_areas():
		if area != self and area.is_inside_tree():
			var vector := global_position - area.global_position
			var distance := vector.length()
			if distance < 50.0:  # only repel when very close
				direction += flock_push * vector.normalized() / distance
		
	return direction.normalized()

func update_rotation() -> void:
	if not is_instance_valid(Global.player):
		return
	var player_pos := Global.player.global_position
	var moving_right := global_position.x < player_pos.x
	visuals.scale = Vector2(-0.5,0.5) if moving_right else Vector2(0.5,0.5)

func can_move_towards_player() -> bool:
	return is_instance_valid(Global.player) and\
	global_position.distance_to(Global.player.global_position) > 60

func apply_knockback(knock_dir: Vector2, knock_power: float) -> void:
	knockback_velocity = knock_dir.normalized() * knock_power * 200.0  # adjust multiplier
	if knockback_timer.time_left > 0:
		knockback_timer.stop()
	knockback_timer.start()
	
	
func destroy_enemy() -> void:
	can_move = false
	anim_player.play("die")
	await anim_player.animation_finished
	queue_free()

func reset_knockback() -> void:
	knockback_velocity = Vector2.ZERO

func _on_knockback_timer_timeout() -> void:
	reset_knockback()
	
func _on_hurtbox_component_on_damaged(hitbox: HitboxComponent) -> void:
	super._on_hurtbox_component_on_damaged(hitbox)
	
	if hitbox.knockback_power > 0 and is_instance_valid(hitbox.source):
		var dir := hitbox.source.global_position.direction_to(global_position)
		apply_knockback(dir, hitbox.knockback_power)


func _on_health_component_on_unit_died() -> void:
	Global.on_enemy_died.emit(self)
