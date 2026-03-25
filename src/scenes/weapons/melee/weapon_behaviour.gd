extends Node2D

class_name WeaponBehaviour

const FLING_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/projectile_fling.tscn")
const FLING_PROJECTILE_SPEED: float = 450.0
const FLING_PROJECTILE_PIERCE: int = 9999
const FLING_MULTI_SPREAD_DEGREES: float = 8.0

@export var weapon: Weapon

var critical := false

func execute_attack() -> void:
	pass
	
	
func get_damage() -> float:
	var damage := weapon.data.stats.damage + Global.player.stats.damage
	var crit_chance := weapon.data.stats.crit_chance
	if is_instance_valid(Global.player):
		crit_chance += max(0.0, float(Global.player.stats.crit_chance)) / 100.0
	crit_chance = clampf(crit_chance, 0.0, 1.0)
	if Global.get_chance_success(crit_chance):
		critical = true
		damage = ceil(damage * weapon.data.stats.crit_damage)
	return max(1.0, damage)


func try_spawn_melee_fling(attack_damage: float, attack_critical: bool) -> void:
	if weapon == null or weapon.data == null:
		return
	if weapon.data.type != ItemWeapon.WeaponType.MELEE:
		return
	if not is_instance_valid(Global.player):
		return

	var weapon_fling_chance_percent: float = maxf(0.0, float(weapon.data.stats.fling_chance))
	var player_fling_chance_percent: float = maxf(0.0, float(Global.player.stats.fling_chance))
	var fling_chance_percent: float = weapon_fling_chance_percent + player_fling_chance_percent
	if fling_chance_percent <= 0.0:
		return

	var fling_count: int = _roll_fling_projectile_count(fling_chance_percent)
	if fling_count <= 0:
		return

	var direction: Vector2 = Vector2.RIGHT.rotated(weapon.rotation)
	if weapon.closest_target != null and is_instance_valid(weapon.closest_target):
		direction = weapon.global_position.direction_to(weapon.closest_target.global_position)
	if direction == Vector2.ZERO:
		return
	direction = direction.normalized()

	var spawn_parent: Node = get_tree().current_scene
	if spawn_parent == null:
		spawn_parent = get_tree().root

	var spawn_position: Vector2 = _get_fling_spawn_position()

	for i: int in range(fling_count):
		var spread_index: float = float(i) - (float(fling_count - 1) * 0.5)
		var spread_radians: float = deg_to_rad(spread_index * FLING_MULTI_SPREAD_DEGREES)
		var fling_direction: Vector2 = direction.rotated(spread_radians).normalized()
		_spawn_single_fling_projectile(spawn_parent, spawn_position, fling_direction, attack_damage, attack_critical)


func _roll_fling_projectile_count(fling_chance_percent: float) -> int:
	var total_rolls: int = int(floor(fling_chance_percent / 100.0))
	var remainder_roll: float = fmod(fling_chance_percent, 100.0) / 100.0
	if remainder_roll > 0.0 and Global.get_chance_success(remainder_roll):
		total_rolls += 1
	return max(0, total_rolls)


func _spawn_single_fling_projectile(
	spawn_parent: Node,
	spawn_position: Vector2,
	direction: Vector2,
	attack_damage: float,
	attack_critical: bool
) -> bool:
	var projectile_node: Node = FLING_PROJECTILE_SCENE.instantiate()
	var projectile: Projectile = projectile_node as Projectile
	if projectile == null:
		return false

	spawn_parent.add_child(projectile)
	projectile.global_position = spawn_position
	projectile.set_projectile(
		direction * FLING_PROJECTILE_SPEED,
		attack_damage,
		attack_critical,
		weapon.data.stats.knockback,
		weapon.get_parent(),
		weapon,
		FLING_PROJECTILE_PIERCE,
		0
	)
	return true


func _get_fling_spawn_position() -> Vector2:
	if is_instance_valid(Global.player):
		var player_instance: Player = Global.player

		if player_instance.visuals != null and is_instance_valid(player_instance.visuals):
			var shadow_node: Node2D = player_instance.visuals.get_node_or_null("Shadow") as Node2D
			if shadow_node != null and is_instance_valid(shadow_node):
				return shadow_node.global_position

		if player_instance.hurtbox != null and is_instance_valid(player_instance.hurtbox):
			return player_instance.hurtbox.global_position

		return player_instance.global_position

	return weapon.global_position
