extends Node2D

class_name WeaponBehaviour

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
		
	
