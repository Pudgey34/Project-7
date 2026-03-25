extends ItemBase

class_name ItemPassive

@export var add_value: float 
@export var add_stats: String
@export var remove_value: float 
@export var remove_stats: String

func get_description() -> String:
	var description := "[code]"
	
	if add_value != 0:
		description += "[color=green]+%s %s[/color]\n" % [_format_stat_value(add_stats, add_value), _format_stat_name(add_stats)]

	if remove_value !=0:
		description += "[color=red]-%s %s[/color]\n" % [_format_stat_value(remove_stats, remove_value), _format_stat_name(remove_stats)]	
			
	description += "[/code]"
	return description

func _format_stat_name(stat_name: String) -> String:
	return stat_name.replace("_", " ")

func _format_stat_value(stat_name: String, value: float) -> String:
	if _is_percentage_stat(stat_name):
		return "%s%%" % _format_number(value)

	return _format_number(value)
	
func apply_passive() -> void:
	if add_value != 0:
		Global.player.stats[add_stats] += _get_applied_stat_delta(add_stats, add_value)
		
	if remove_value != 0:
		Global.player.stats[remove_stats] -= _get_applied_stat_delta(remove_stats, remove_value)


func _get_applied_stat_delta(stat_name: String, value: float) -> float:
	if stat_name == "attack_speed":
		return value / 100.0

	return value

func _is_percentage_stat(stat_name: String) -> bool:
	return stat_name == "attack_speed" or stat_name == "life_steal" or stat_name == "block_chance" or stat_name == "crit_chance" or stat_name == "fling_chance"

func _format_number(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))

	return str(snappedf(value, 0.1))
