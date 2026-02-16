extends WeaponBehaviour

class_name RangeBehaviour

@onready var muzzle: Marker2D = $"../Sprite2D/Muzzle"
# MAYBE DO THIS? @onready var muzzle: Marker2D = $Muzzle

func execute_attack() -> void:
	weapon.is_attacking = true
	
	print("Shoot!")
	
	var tween := create_tween()
	
	var attack_pos := Vector2(weapon.atk_start_pos.x - weapon.data.stats.recoil, weapon.atk_start_pos.y)
	var rotation_amount := -0.6

	
	tween.tween_property(weapon.sprite, "position", attack_pos, weapon.data.stats.recoil_duration)
	tween.parallel().tween_property(weapon.sprite, "rotation", rotation_amount, weapon.data.stats.recoil_duration)

	
	tween.tween_property(weapon.sprite, "position", weapon.atk_start_pos, weapon.data.stats.recoil_duration)
	tween.parallel().tween_property(weapon.sprite, "rotation", 0.0, weapon.data.stats.recoil_duration)

	
	await tween.finished

	weapon.is_attacking =false
	
	critical = false 
