extends ItemBase

class_name ItemWeapon

enum WeaponType{
	MELEE,
	RANGE
}

@export var type: WeaponType
@export var scene: PackedScene
@export var stats: WeaponStats
@export var upgrade_to: ItemWeapon

func get_description() -> String:
	var desc = "[code]"
	desc += "Damage: [color=green]%s[/color]\n" % stats.damage
	desc += "Cooldown: [color=green]%s[/color]\n" % stats.cooldown
	desc += "Range: [color=green]%s[/color]\n" % stats.max_range
	desc += "Accuracy: [color=green]%s%%[/color]\n" % (stats.accuracy * 100)
	desc += "Critical: [color=green]%s%%[/color]\n" % (stats.crit_chance * 100)
	desc += "Crit Damage: [color=green]%sx[/color]\n" % stats.crit_damage
	desc += "Pierce: [color=green]%s[/color]\n" % stats.pierce
	if stats.knockback > 0:
		desc += "Knockback: [color=green]%s[/color]\n" % stats.knockback
	if stats.life_steal > 0:
		desc += "Life Steal: [color=green]%s%%[/color]\n" % (stats.life_steal * 100)
	desc += "[/code]"
	return desc
