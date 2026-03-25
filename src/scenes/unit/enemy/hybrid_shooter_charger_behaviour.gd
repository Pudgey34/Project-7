extends Node2D

class_name HybridShooterChargerBehaviour

@export var enemy: Enemy
@export var fire_pos: Marker2D
@export var anim_effects: AnimationPlayer
@export var projectile_scene: PackedScene
@export var projectile_speed := 420.0
@export var projectile_count := 4
@export var arc_angle := 42.0
@export var fire_full_circle := false
@export_range(1, 64, 1) var full_circle_projectile_count := 16
@export var shoot_cooldown := 2.4
@export var shoot_recovery := 0.8
@export var charge_cooldown := 5.2
@export var charge_speed_multiplier := 3.8
@export var charge_lead_time := 0.2
@export var charge_pass_distance := 155.0
@export var charge_stationary_pass_distance := 55.0
@export var charge_max_time := 0.55
@export var charge_end_distance := 10.0
@export var charge_hitbox_scale := 1.7
@export var charge_flash_speed := 0.82

var shoot_timer := 0.0
var charge_timer := 0.0
var is_busy := false
var is_charging := false
var charge_direction := Vector2.ZERO
var charge_time_left := 0.0
var base_hitbox_scale := Vector2.ONE
var has_base_hitbox_scale := false


func _ready() -> void:
	shoot_timer = shoot_cooldown
	charge_timer = charge_cooldown


func _process(delta: float) -> void:
	if Global.game_paused:
		return
	if enemy == null or not is_instance_valid(enemy):
		return

	if is_charging:
		_update_charge(delta)
		return

	if is_busy:
		return

	shoot_timer -= delta
	charge_timer -= delta

	if charge_timer <= 0.0 and is_instance_valid(Global.player):
		_start_charge()
		return

	if shoot_timer <= 0.0:
		shoot_timer = shoot_cooldown
		_shoot()


func _start_charge() -> void:
	is_busy = true
	enemy.can_move = false
	SoundManager.play_sound(SoundManager.Sound.CHARGE_HORN, false, -1.0, -12.0)

	if anim_effects != null and anim_effects.has_animation("charge"):
		anim_effects.play("charge", -1.0, charge_flash_speed)
		await anim_effects.animation_finished
		if enemy == null or not is_instance_valid(enemy):
			return

	if not is_instance_valid(Global.player):
		is_busy = false
		charge_timer = charge_cooldown
		enemy.can_move = true
		return

	var charge_target_position: Vector2 = _get_charge_target_position()
	charge_direction = enemy.global_position.direction_to(charge_target_position)
	if charge_direction == Vector2.ZERO:
		charge_direction = Vector2.RIGHT
	else:
		charge_direction = charge_direction.normalized()
	charge_time_left = charge_max_time
	_apply_charge_hitbox_scale()
	is_charging = true
	is_busy = false


func _update_charge(delta: float) -> void:
	var movement: Vector2 = charge_direction * (enemy.stats.speed * charge_speed_multiplier) * delta
	var next_position: Vector2 = enemy.global_position + movement
	var clamped_position: Vector2 = _clamp_to_arena(next_position)
	var hit_arena_edge: bool = absf(clamped_position.x - next_position.x) > 0.01 or \
		absf(clamped_position.y - next_position.y) > 0.01
	enemy.global_position = clamped_position
	charge_time_left -= delta

	var hit_player: bool = is_instance_valid(Global.player) and \
		enemy.global_position.distance_to(Global.player.global_position) <= charge_end_distance
	if hit_player or charge_time_left <= 0.0 or hit_arena_edge:
		_end_charge()


func _end_charge() -> void:
	is_charging = false
	charge_timer = charge_cooldown
	_reset_charge_hitbox_scale()
	if enemy != null and is_instance_valid(enemy):
		enemy.can_move = true


func _get_charge_target_position() -> Vector2:
	if not is_instance_valid(Global.player):
		return enemy.global_position

	var player: Player = Global.player as Player
	if player == null or not is_instance_valid(player):
		return enemy.global_position

	if player.move_dir.length() > 0.05:
		var moving_dir: Vector2 = player.move_dir.normalized()
		var lead_offset: Vector2 = moving_dir * float(player.stats.speed) * charge_lead_time
		var pass_offset: Vector2 = moving_dir * charge_pass_distance
		return player.global_position + lead_offset + pass_offset

	var toward_player: Vector2 = enemy.global_position.direction_to(player.global_position)
	if toward_player == Vector2.ZERO:
		toward_player = Vector2.RIGHT
	return player.global_position + toward_player.normalized() * charge_stationary_pass_distance


func _apply_charge_hitbox_scale() -> void:
	if enemy.hitbox == null or not is_instance_valid(enemy.hitbox):
		return

	if not has_base_hitbox_scale:
		base_hitbox_scale = enemy.hitbox.scale
		has_base_hitbox_scale = true

	enemy.hitbox.scale = base_hitbox_scale * charge_hitbox_scale


func _reset_charge_hitbox_scale() -> void:
	if enemy.hitbox == null or not is_instance_valid(enemy.hitbox):
		return
	if not has_base_hitbox_scale:
		return

	enemy.hitbox.scale = base_hitbox_scale


func _clamp_to_arena(pos: Vector2) -> Vector2:
	return Enemy.clamp_to_arena(pos)


func _shoot() -> void:
	if fire_pos == null or projectile_scene == null:
		return
	if not fire_full_circle and not is_instance_valid(Global.player):
		return

	is_busy = true
	enemy.can_move = false
	SoundManager.play_sound(SoundManager.Sound.FIRE, false, -1.0, -4.0)

	if fire_full_circle:
		_shoot_full_circle()
	else:
		_shoot_forward_spread()

	await get_tree().create_timer(shoot_recovery).timeout
	if enemy != null and is_instance_valid(enemy):
		enemy.can_move = true
	is_busy = false


func _shoot_forward_spread() -> void:
	if not is_instance_valid(Global.player):
		return

	var base_direction: Vector2 = enemy.global_position.direction_to(Global.player.global_position)
	var total_projectiles: int = max(1, projectile_count)
	var start_angle: float = -arc_angle / 2.0
	var angle_step: float = 0.0
	if total_projectiles > 1:
		angle_step = arc_angle / float(total_projectiles - 1)

	for i: int in range(total_projectiles):
		var shot_angle := start_angle + (angle_step * float(i))
		var velocity := base_direction.rotated(deg_to_rad(shot_angle)) * projectile_speed
		_spawn_projectile(velocity)


func _shoot_full_circle() -> void:
	var total_projectiles: int = max(1, full_circle_projectile_count)
	var base_angle: float = 0.0
	if is_instance_valid(Global.player):
		base_angle = enemy.global_position.direction_to(Global.player.global_position).angle()

	for i: int in range(total_projectiles):
		var angle: float = base_angle + (TAU * float(i) / float(total_projectiles))
		var velocity: Vector2 = Vector2.RIGHT.rotated(angle) * projectile_speed
		_spawn_projectile(velocity)


func _spawn_projectile(velocity: Vector2) -> void:
	var projectile := projectile_scene.instantiate() as Projectile
	if projectile == null:
		return

	get_tree().root.add_child(projectile)
	projectile.global_position = fire_pos.global_position
	projectile.set_projectile(velocity, enemy.stats.damage, false, 0, enemy, null, 0)
