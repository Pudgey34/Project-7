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

	for i: int in range(active_hitboxes.size() - 1, -1, -1):
		var active_hitbox: HitboxComponent = active_hitboxes[i]
		if not is_instance_valid(active_hitbox) or not active_hitbox.is_damage_active():
			active_hitboxes.remove_at(i)

	if active_hitboxes.is_empty():
		return
	
	damage_timer -= delta
	if damage_timer <= 0.0:
		damage_timer = continuous_damage_interval
		for active_hitbox: HitboxComponent in active_hitboxes:
			if is_instance_valid(active_hitbox) and active_hitbox.is_damage_active():
				on_damaged.emit(active_hitbox)


func receive_hit_from_hitbox(hitbox: HitboxComponent) -> void:
	if Global.game_paused:
		return
	if not is_instance_valid(hitbox):
		return
	if not hitbox.is_damage_active():
		return
	on_damaged.emit(hitbox)

func _on_area_entered(area: Area2D) -> void:
	if Global.game_paused:
		return

	if area is HitboxComponent:
		# Only track active hitboxes for the player
		var hitbox: HitboxComponent = area as HitboxComponent
		if owner is Player and hitbox not in active_hitboxes:
			active_hitboxes.append(hitbox)

func _on_area_exited(area: Area2D) -> void:
	if area is HitboxComponent:
		active_hitboxes.erase(area)
