extends Unit

class_name Enemy

const ARENA_MIN_X: float = -1000.0
const ARENA_MAX_X: float = 1000.0
const ARENA_MIN_Y: float = -500.0
const ARENA_MAX_Y: float = 500.0
const EDGE_SOFT_MARGIN: float = 120.0
const EDGE_PUSH_WEIGHT: float = 1.4

@export var flock_push := 10.0
@export var visual_scale := 0.5
@onready var vision_area: Area2D = $VisionArea
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var hitbox: HitboxComponent = $HitboxComponent

var can_move := true
var is_dying := false

var knockback_velocity: Vector2
const KNOCKBACK_DECAY := 8.0

func _ready() -> void:
	# Duplicate stats resource to prevent modifying the original resource file
	stats = stats.duplicate()
	
	super._ready()
	hitbox.setup(stats.damage, false, 0, self, null)

func _process(delta: float) -> void:
	if Global.game_paused or is_dying: return
	if not can_move:
		return
		
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		
	var movement: Vector2 = Vector2.ZERO
	if can_move_towards_player():
		movement = get_move_direction() * stats.speed
	
	var next_position: Vector2 = global_position + (movement + knockback_velocity) * delta
	global_position = clamp_to_arena(next_position)
	update_animations(movement)
	update_rotation()


func update_animations(movement: Vector2) -> void:
	var walk_anim := ""
	if anim_player.has_animation("walk"):
		walk_anim = "walk"
	elif anim_player.has_animation("move"):
		walk_anim = "move"

	# Always play walk/move animation if available
	if walk_anim != "" and anim_player.current_animation != walk_anim:
		anim_player.play(walk_anim)
	elif walk_anim == "" and anim_player.has_animation("idle") and anim_player.current_animation != "idle":
		anim_player.play("idle")
		
func get_move_direction() -> Vector2:
	if not is_instance_valid(Global.player):
		return Vector2.ZERO
		
	var direction: Vector2 = global_position.direction_to(Global.player.global_position)
	for area: Node2D in vision_area.get_overlapping_areas():
		if area != self and area.is_inside_tree():
			var vector: Vector2 = global_position - area.global_position
			var distance: float = vector.length()
			if distance < 50.0:  # only repel when very close
				direction += flock_push * vector.normalized() / maxf(distance, 0.001)

	direction += _get_edge_recenter_vector()
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	return direction.normalized()


func _get_edge_recenter_vector() -> Vector2:
	var recenter: Vector2 = Vector2.ZERO

	var min_x_soft: float = ARENA_MIN_X + EDGE_SOFT_MARGIN
	var max_x_soft: float = ARENA_MAX_X - EDGE_SOFT_MARGIN
	var min_y_soft: float = ARENA_MIN_Y + EDGE_SOFT_MARGIN
	var max_y_soft: float = ARENA_MAX_Y - EDGE_SOFT_MARGIN

	if global_position.x < min_x_soft:
		recenter.x += (min_x_soft - global_position.x) / EDGE_SOFT_MARGIN
	elif global_position.x > max_x_soft:
		recenter.x -= (global_position.x - max_x_soft) / EDGE_SOFT_MARGIN

	if global_position.y < min_y_soft:
		recenter.y += (min_y_soft - global_position.y) / EDGE_SOFT_MARGIN
	elif global_position.y > max_y_soft:
		recenter.y -= (global_position.y - max_y_soft) / EDGE_SOFT_MARGIN

	return recenter * EDGE_PUSH_WEIGHT


static func clamp_to_arena(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, ARENA_MIN_X, ARENA_MAX_X),
		clampf(pos.y, ARENA_MIN_Y, ARENA_MAX_Y)
	)

func update_rotation() -> void:
	if not is_instance_valid(Global.player):
		return
	var player_pos := Global.player.global_position
	var moving_right := global_position.x < player_pos.x
	visuals.scale = Vector2(-visual_scale, visual_scale) if moving_right else Vector2(visual_scale, visual_scale)

func can_move_towards_player() -> bool:
	return is_instance_valid(Global.player) and\
	global_position.distance_to(Global.player.global_position) > 60

func apply_knockback(knock_dir: Vector2, knock_power: float) -> void:
	knockback_velocity = knock_dir.normalized() * knock_power * 200.0  # adjust multiplier
	if knockback_timer.time_left > 0:
		knockback_timer.stop()
	knockback_timer.start()
	
	
func destroy_enemy() -> void:
	if is_dying or is_queued_for_deletion():
		return

	is_dying = true
	can_move = false
	_disable_death_runtime_state()

	if anim_player != null and anim_player.has_animation("die"):
		anim_player.play("die")
		var die_duration: float = maxf(0.05, anim_player.current_animation_length)
		await get_tree().create_timer(die_duration).timeout

	if is_inside_tree() and not is_queued_for_deletion():
		queue_free()


func _disable_death_runtime_state() -> void:
	if hitbox != null and is_instance_valid(hitbox):
		hitbox.disable()

	var hurtbox_component: HurtboxComponent = get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox_component != null:
		hurtbox_component.set_deferred("monitoring", false)
		hurtbox_component.set_deferred("monitorable", false)

	for child: Node in get_children():
		if child == anim_player:
			continue
		child.set_process(false)
		child.set_physics_process(false)

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
