extends Node2D

class_name ChargeBehaviour

@export var enemy: Enemy
@export var anim_effects: AnimationPlayer
@export var prep_time: float = 1.0
@export var cooldown: float = 3.0
@export var dash_speed_multiplier: float = 7.0
@export var lead_time: float = 0.2
@export var pass_distance: float = 145.0
@export var stationary_pass_distance: float = 48.0
@export var dash_max_time: float = 0.55
@export var charge_end_distance: float = 14.0
@export var charge_hitbox_scale: float = 1.6
@export var charge_flash_speed: float = 0.82

var current_cooldown: float = 0.0
var is_charging: bool = false
var is_preparing_charge: bool = false
var charge_direction: Vector2 = Vector2.ZERO
var dash_time_left: float = 0.0
var base_hitbox_scale: Vector2 = Vector2.ONE
var has_base_hitbox_scale: bool = false

func _ready() -> void:
	current_cooldown = cooldown

func _process(delta: float) -> void:
	if Global.game_paused:
		return
	if enemy == null:
		return

	if is_charging:
		_update_charge(delta)
		return

	if is_preparing_charge:
		return

	if current_cooldown > 0:
		current_cooldown -= delta
	else:
		if is_instance_valid(Global.player):
			start_charge()


func start_charge() -> void:
	if is_charging or is_preparing_charge:
		return
	if enemy == null or not is_instance_valid(enemy):
		return

	is_preparing_charge = true
	enemy.can_move = false
	SoundManager.play_sound(SoundManager.Sound.CHARGE_HORN, false, -1.0, -12.0)

	if anim_effects != null and anim_effects.has_animation("charge"):
		anim_effects.play("charge", -1.0, charge_flash_speed)
		await anim_effects.animation_finished
	elif prep_time > 0.0:
		await get_tree().create_timer(prep_time).timeout

	if enemy == null or not is_instance_valid(enemy):
		is_preparing_charge = false
		return
	if not is_instance_valid(Global.player):
		end_charge()
		return

	var charge_target_position: Vector2 = _get_charge_target_position()
	charge_direction = enemy.global_position.direction_to(charge_target_position)
	if charge_direction == Vector2.ZERO:
		charge_direction = Vector2.RIGHT
	else:
		charge_direction = charge_direction.normalized()

	dash_time_left = dash_max_time
	_apply_charge_hitbox_scale()
	is_charging = true
	is_preparing_charge = false


func _update_charge(delta: float) -> void:
	var movement: Vector2 = charge_direction * (enemy.stats.speed * dash_speed_multiplier) * delta
	var next_position: Vector2 = enemy.global_position + movement
	var clamped_position: Vector2 = _clamp_to_arena(next_position)
	var hit_arena_edge: bool = absf(clamped_position.x - next_position.x) > 0.01 or \
		absf(clamped_position.y - next_position.y) > 0.01
	enemy.global_position = clamped_position
	dash_time_left -= delta

	var hit_player: bool = is_instance_valid(Global.player) and \
		enemy.global_position.distance_to(Global.player.global_position) <= charge_end_distance
	if hit_player or dash_time_left <= 0.0 or hit_arena_edge:
		end_charge()


func _get_charge_target_position() -> Vector2:
	if not is_instance_valid(Global.player):
		return enemy.global_position

	var player: Player = Global.player as Player
	if player == null or not is_instance_valid(player):
		return enemy.global_position

	if player.move_dir.length() > 0.05:
		var moving_dir: Vector2 = player.move_dir.normalized()
		var lead_offset: Vector2 = moving_dir * float(player.stats.speed) * lead_time
		var pass_offset: Vector2 = moving_dir * pass_distance
		return player.global_position + lead_offset + pass_offset

	var toward_player: Vector2 = enemy.global_position.direction_to(player.global_position)
	if toward_player == Vector2.ZERO:
		toward_player = Vector2.RIGHT
	return player.global_position + toward_player.normalized() * stationary_pass_distance


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


func end_charge() -> void:
	is_preparing_charge = false
	if is_charging:
		is_charging = false
	_reset_charge_hitbox_scale()
	current_cooldown = cooldown
	if enemy != null and is_instance_valid(enemy):
		enemy.can_move = true
