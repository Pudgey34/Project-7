extends WeaponBehaviour

class_name MeleeBehaviour

@export var hitbox: HitboxComponent

func execute_attack() -> void:
	weapon.is_attacking = true
	if SoundManager and SoundManager.has_method("play_sound"):
		SoundManager.play_sound(SoundManager.Sound.PUNCH)
	
	var tween := create_tween()
	
	var recoil_pos := Vector2(weapon.atk_start_pos.x - weapon.data.stats.recoil, weapon.atk_start_pos.y)
	tween.tween_property(weapon.sprite, "position", recoil_pos, weapon.data.stats.recoil_duration)
	
	var attack_damage: float = get_damage()
	var attack_critical: bool = critical

	hitbox.enable()
	hitbox.setup(attack_damage, attack_critical, weapon.data.stats.knockback, weapon.get_parent(), weapon)
	try_spawn_melee_fling(attack_damage, attack_critical)

	var attack_pos := Vector2(weapon.atk_start_pos.x + weapon.data.stats.max_range, weapon.atk_start_pos.y)
	tween.tween_property(weapon.sprite, "position", attack_pos, weapon.data.stats.attack_duration)
	

	tween.tween_property(weapon.sprite, "position", weapon.atk_start_pos, weapon.data.stats.back_duration)
	
	tween.finished.connect(func():
		hitbox.disable()
		weapon.is_attacking =false
		critical = false
	)
