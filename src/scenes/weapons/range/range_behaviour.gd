extends WeaponBehaviour

class_name RangeBehaviour

@onready var muzzle: Marker2D = $"../Sprite2D/Muzzle"
# MAYBE DO THIS? @onready var muzzle: Marker2D = $Muzzle

func execute_attack() -> void:
	weapon.is_attacking = true

	create_projectile()
	SoundManager.play_sound(_get_fire_sound(), false)
	
	var tween := create_tween()
	
	var attack_pos := Vector2(weapon.atk_start_pos.x - weapon.data.stats.recoil, weapon.atk_start_pos.y)
	var rotation_amount := -0.3

	
	tween.tween_property(weapon.sprite, "position", attack_pos, weapon.data.stats.recoil_duration)
	tween.parallel().tween_property(weapon.sprite, "rotation", rotation_amount, weapon.data.stats.recoil_duration)
	

	
	tween.tween_property(weapon.sprite, "position", weapon.atk_start_pos, weapon.data.stats.recoil_duration)
	tween.parallel().tween_property(weapon.sprite, "rotation", 0.0, weapon.data.stats.recoil_duration)

	
	await tween.finished

	weapon.is_attacking =false
	
	critical = false


func _get_fire_sound() -> int:
	if weapon == null or weapon.data == null:
		return SoundManager.Sound.PLAYER_FIRE

	var weapon_name: String = weapon.data.item_name
	if weapon_name.begins_with("Pistol"):
		return SoundManager.Sound.PISTOL_FIRE

	return SoundManager.Sound.PLAYER_FIRE
	
func create_projectile() -> void: 
	var instance := weapon.data.stats.projectile_scene.instantiate() as Projectile
	get_tree().root.add_child(instance)
	instance.global_position = muzzle.global_position
	
	
	var velocity := Vector2.RIGHT.rotated(weapon.rotation) * weapon.data.stats.projectile_speed 
	var total_pierce := weapon.data.stats.pierce
	if is_instance_valid(Global.player):
		total_pierce += max(0, Global.player.stats.pierce)

	instance.set_projectile(velocity, get_damage(), critical, weapon.data.stats.knockback, weapon.get_parent(), weapon, total_pierce)
	
