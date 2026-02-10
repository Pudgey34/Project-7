extends Node
const FLASH_MATERIAL = preload("uid://bys1rfyuawvhe")

var player: Player

func get_chance_success(chance: float) -> bool:
	var random := randf_range(0,1.0)
	if random < chance:
		return true
	return false
