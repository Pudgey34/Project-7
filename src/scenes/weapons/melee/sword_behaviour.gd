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
## Minimum swing radius — prevents the blade from swinging too close to the player's body
@export_range(0.0, 200.0) var min_range := 60.0
## Maximum tip-to-tip chord width of the swing in pixels.
## At large ranges the arc angle narrows automatically to keep this width constant.
@export_range(50.0, 600.0) var max_arc_chord := 220.0

var _sweep_radius: float = 0.0

func execute_attack() -> void:
	weapon.is_attacking = true
	if SoundManager and SoundManager.has_method("play_sound"):
		SoundManager.play_sound(SoundManager.Sound.SWORD)
	if weapon.closest_target and is_instance_valid(weapon.closest_target):
		var dist: float = weapon.global_position.distance_to(weapon.closest_target.global_position)
		_sweep_radius = clampf(dist, min_range, weapon.data.stats.max_range)
	else:
		_sweep_radius = weapon.data.stats.max_range

	# Clamp arc so the tip-to-tip chord never exceeds max_arc_chord.
	# chord = 2 * r * sin(θ/2)  →  θ = 2 * arcsin(chord / (2r))
	var chord_arc: float = rad_to_deg(2.0 * asin(clampf(max_arc_chord / (2.0 * _sweep_radius), 0.0, 1.0)))
	var half_arc: float = minf(sweep_arc_degrees, chord_arc) * 0.5
	var windup_degrees: float = -half_arc - 10.0
	var overshoot_degrees: float = half_arc + 5.0

	# Reset sprite to resting position on the player
	weapon.sprite.rotation_degrees = 0.0
	weapon.sprite.position = weapon.atk_start_pos

	var attack_damage: float = get_damage()
	var attack_critical: bool = critical
	hitbox.setup(attack_damage, attack_critical, weapon.data.stats.knockback, weapon.get_parent(), weapon)
	try_spawn_melee_fling(attack_damage, attack_critical)

	var tween: Tween = create_tween()

	# Phase 1: extend from player out to the left arc start position
	tween.tween_property(weapon.sprite, "position", _angle_to_pos(-half_arc), extend_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(weapon.sprite, "rotation_degrees", -half_arc, extend_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Hitbox fires as the swing launches
	tween.tween_callback(hitbox.enable)

	# Phase 2: tiny pull-back wind-up for anticipation feel
	tween.tween_property(weapon.sprite, "position", _angle_to_pos(windup_degrees), 0.04)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(weapon.sprite, "rotation_degrees", windup_degrees, 0.04)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Phase 3: main swing arc — tween_method keeps it on the circle with cubic ease-out
	tween.tween_method(_set_blade_angle, windup_degrees, overshoot_degrees, sweep_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Disable hitbox before return so it can't clip on the way back
	tween.tween_callback(hitbox.disable)
	# Phase 4: overshoot settle — snap to true end angle for follow-through feel
	tween.tween_property(weapon.sprite, "position", _angle_to_pos(half_arc), 0.05)
	tween.parallel().tween_property(weapon.sprite, "rotation_degrees", half_arc, 0.05)

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
		return clampf(
			weapon.global_position.distance_to(weapon.closest_target.global_position),
			min_range,
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
