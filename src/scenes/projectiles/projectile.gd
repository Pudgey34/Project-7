extends Node2D

class_name Projectile

@export var hitbox: HitboxComponent

var velocity: Vector2
var remaining_pierce := 0
var hit_target_ids: Array[int] = []

func _process(delta: float) -> void:
	if Global.game_paused:
		return
	position += velocity * delta

func set_projectile(velocity: Vector2, damage: float, critical: bool, knockback: float, unit: Node2D, weapon: Weapon, pierce: int = 0) -> void:
	self.velocity = velocity
	remaining_pierce = max(0, pierce)
	hit_target_ids.clear()
	rotation = velocity.angle()
	if hitbox:
		hitbox.setup(damage, critical, knockback, unit, weapon)
	


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_hitbox_component_on_hit_hurtbox(hurtbox: HurtboxComponent) -> void:
	var hurtbox_id := hurtbox.get_instance_id()
	if hurtbox_id in hit_target_ids:
		return

	hit_target_ids.append(hurtbox_id)

	if remaining_pierce <= 0:
		queue_free()
		return

	remaining_pierce -= 1
