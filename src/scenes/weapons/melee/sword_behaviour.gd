extends WeaponBehaviour

@export var hitbox: HitboxComponent
## Total arc swept from left side to right side (degrees in weapon-local space)
@export_range(1.0, 360.0) var sweep_arc_degrees := 180.0
## How long the weapon takes to extend from the player out to the left arc start
@export_range(0.01, 1.0) var extend_duration := 0.08
## How long the main arc sweep from left to right takes
@export_range(0.01, 1.0) var sweep_duration := 0.35
## How long the weapon takes to return to the player after the sweep
@export_range(0.01, 1.0) var return_duration := 0.15

var _sweep_radius: float = 0.0

func execute_attack() -> void:
	weapon.is_attacking = true
	if weapon.closest_target and is_instance_valid(weapon.closest_target):
		var dist: float = weapon.global_position.distance_to(weapon.closest_target.global_position)
		_sweep_radius = minf(dist, weapon.data.stats.max_range)
	else:
		_sweep_radius = weapon.data.stats.max_range

	var half_arc: float = sweep_arc_degrees * 0.5
	var windup_degrees: float = -half_arc - 10.0
	var overshoot_degrees: float = half_arc + 5.0

	# Reset sprite to resting position on the player
	weapon.sprite.rotation_degrees = 0.0
	weapon.sprite.position = weapon.atk_start_pos

	hitbox.setup(get_damage(), critical, weapon.data.stats.knockback, weapon.get_parent(), weapon)

	var tween: Tween = create_tween()

	# Phase 1: extend from player out to the left arc start position
	tween.tween_property(weapon.sprite, "position", _angle_to_pos(-half_arc), extend_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(weapon.sprite, "rotation_degrees", -half_arc, extend_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Phase 2: tiny pull-back wind-up for anticipation feel
	tween.tween_property(weapon.sprite, "position", _angle_to_pos(windup_degrees), 0.04)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(weapon.sprite, "rotation_degrees", windup_degrees, 0.04)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Hitbox fires as the swing launches
	tween.tween_callback(hitbox.enable)

	# Phase 3: main swing arc — tween_method keeps it on the circle with cubic ease-out
	tween.tween_method(_set_blade_angle, windup_degrees, overshoot_degrees, sweep_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Phase 4: overshoot settle — snap to true end angle for follow-through feel
	tween.tween_property(weapon.sprite, "position", _angle_to_pos(half_arc), 0.05)
	tween.parallel().tween_property(weapon.sprite, "rotation_degrees", half_arc, 0.05)

	# Disable hitbox before return so it can't clip on the way back
	tween.tween_callback(hitbox.disable)

	# Phase 5: return directly to the resting position on the player (not along arc)
	tween.tween_property(weapon.sprite, "position", weapon.atk_start_pos, return_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(weapon.sprite, "rotation_degrees", 0.0, return_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(_on_attack_finished)

## Converts a sweep angle to a local sprite position at _sweep_radius distance.
## Used for the wind-up and overshoot phases where radius is fixed.
func _angle_to_pos(angle_degrees: float) -> Vector2:
	var angle_rad: float = deg_to_rad(angle_degrees)
	return Vector2(cos(angle_rad), sin(angle_rad)) * _sweep_radius

## Returns the live distance to the closest enemy, capped at max_range.
## Falls back to the cached _sweep_radius if no valid target exists.
func _get_live_radius() -> float:
	if weapon.closest_target and is_instance_valid(weapon.closest_target):
		return minf(
			weapon.global_position.distance_to(weapon.closest_target.global_position),
			weapon.data.stats.max_range
		)
	return _sweep_radius

## Called each frame during the main sweep arc.
## Uses live radius so the blade continuously tracks the closest enemy's distance.
func _set_blade_angle(angle_degrees: float) -> void:
	var angle_rad: float = deg_to_rad(angle_degrees)
	var live_radius: float = _get_live_radius()
	weapon.sprite.position = Vector2(cos(angle_rad), sin(angle_rad)) * live_radius
	weapon.sprite.rotation_degrees = angle_degrees

func _on_attack_finished() -> void:
	hitbox.disable()  # Safety fallback if tween is interrupted
	weapon.is_attacking = false
	critical = false
