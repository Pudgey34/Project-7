extends Area2D

class_name HurtboxComponent

signal on_damaged(hitbox: HitboxComponent)

@export var continuous_damage_interval := 0.8

var active_hitboxes: Array[HitboxComponent] = []
var damage_timer: float = 0.0

func _process(delta: float) -> void:
	if Global.game_paused:
		return

	# Only apply continuous damage for the player
	if not owner is Player:
		return
		
	if active_hitboxes.is_empty():
		return
	
	damage_timer -= delta
	if damage_timer <= 0.0:
		damage_timer = continuous_damage_interval
		for hitbox in active_hitboxes:
			if is_instance_valid(hitbox):
				on_damaged.emit(hitbox)

func _on_area_entered(area: Area2D) -> void:
	if Global.game_paused:
		return

	if area is HitboxComponent:
		on_damaged.emit(area)
		# Only track active hitboxes for the player
		if owner is Player and area not in active_hitboxes:
			active_hitboxes.append(area)

func _on_area_exited(area: Area2D) -> void:
	if area is HitboxComponent:
		active_hitboxes.erase(area)
