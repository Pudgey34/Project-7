extends Node2D

class_name Projectile

@export var hitbox: HitboxComponent

var velocity: Vector2
var remaining_pierce: int = 0
var remaining_bounce: int = 0
var hit_target_ids: Array[int] = []

func _ready() -> void:
	add_to_group("projectiles")

func _process(delta: float) -> void:
	if Global.game_paused:
		return
	position += velocity * delta

func set_projectile(
	velocity: Vector2,
	damage: float,
	critical: bool,
	knockback: float,
	unit: Node2D,
	weapon: Weapon,
	pierce: int = 0,
	bounce: int = 0
) -> void:
	self.velocity = velocity
	remaining_pierce = max(0, pierce)
	remaining_bounce = max(0, bounce)
	hit_target_ids.clear()
	rotation = velocity.angle()
	if hitbox:
		hitbox.setup(damage, critical, knockback, unit, weapon)
	


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_hitbox_component_on_hit_hurtbox(hurtbox: HurtboxComponent) -> void:
	var hurtbox_id: int = hurtbox.get_instance_id()
	if hurtbox_id in hit_target_ids:
		return

	hit_target_ids.append(hurtbox_id)

	if _try_bounce_to_next_target(hurtbox):
		return

	if remaining_pierce <= 0:
		queue_free()
		return

	remaining_pierce -= 1


func _try_bounce_to_next_target(current_hurtbox: HurtboxComponent) -> bool:
	if remaining_bounce <= 0:
		return false

	var next_target: HurtboxComponent = _find_next_bounce_target(current_hurtbox)
	if next_target == null or not is_instance_valid(next_target):
		return false

	var to_target: Vector2 = global_position.direction_to(next_target.global_position)
	if to_target == Vector2.ZERO:
		return false

	var speed: float = maxf(1.0, velocity.length())
	velocity = to_target * speed
	rotation = velocity.angle()
	remaining_bounce -= 1
	return true


func _find_next_bounce_target(current_hurtbox: HurtboxComponent) -> HurtboxComponent:
	if hitbox == null or not is_instance_valid(hitbox):
		return null

	var source_unit: Node2D = hitbox.source
	if source_unit == null or not is_instance_valid(source_unit):
		return null

	if source_unit is Player:
		return _find_closest_enemy_hurtbox(current_hurtbox)

	if source_unit is Enemy:
		return _find_player_hurtbox(current_hurtbox)

	return null


func _find_closest_enemy_hurtbox(current_hurtbox: HurtboxComponent) -> HurtboxComponent:
	var nearest_hurtbox: HurtboxComponent = null
	var nearest_distance_sq: float = INF

	for enemy_node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = enemy_node as Enemy
		if enemy == null:
			continue
		if not is_instance_valid(enemy) or enemy.is_dying:
			continue
		if enemy.health_component == null or enemy.health_component.current_health <= 0:
			continue

		var hurtbox_node: Node = enemy.get_node_or_null("HurtboxComponent")
		var enemy_hurtbox: HurtboxComponent = hurtbox_node as HurtboxComponent
		if enemy_hurtbox == null or not is_instance_valid(enemy_hurtbox):
			continue
		if enemy_hurtbox == current_hurtbox:
			continue

		var hurtbox_id: int = enemy_hurtbox.get_instance_id()
		if hurtbox_id in hit_target_ids:
			continue

		var dist_sq: float = global_position.distance_squared_to(enemy_hurtbox.global_position)
		if dist_sq < nearest_distance_sq:
			nearest_distance_sq = dist_sq
			nearest_hurtbox = enemy_hurtbox

	return nearest_hurtbox


func _find_player_hurtbox(current_hurtbox: HurtboxComponent) -> HurtboxComponent:
	if not is_instance_valid(Global.player):
		return null
	if Global.player.health_component == null or Global.player.health_component.current_health <= 0:
		return null

	var player_hurtbox: HurtboxComponent = Global.player.hurtbox
	if player_hurtbox == null or not is_instance_valid(player_hurtbox):
		return null
	if player_hurtbox == current_hurtbox:
		return null

	var hurtbox_id: int = player_hurtbox.get_instance_id()
	if hurtbox_id in hit_target_ids:
		return null

	return player_hurtbox
