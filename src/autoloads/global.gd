extends Node

signal on_create_block_text(unit: Node2D)
signal on_create_damage_text(unit: Node2D, hitbox: HitboxComponent)
signal on_create_heal_text(unit: Node2D, heal: float)

signal on_upgrade_selected
signal on_enemy_died(enemy: Enemy)
const COINS_SCENE = preload("uid://dkvbklgbghtf3")
const FLASH_MATERIAL = preload("uid://bys1rfyuawvhe")
const SPAWN_EFFECT_SCENE = preload("uid://c340vhcs6rned")

const FLOATING_TEXT_SCENE = preload("uid://cnjxlvdplj5ds")
const ITEM_CARD_SCENE = preload("uid://c8bnprxgjttxt")
const COMMON_STYLE = preload("uid://cxtqhn2pkqjsg")
const EPIC_STYLE = preload("uid://duhsf70p3qe8m")
const LEGENDARY_STYLE = preload("uid://bls2cae0qlmoq")
const RARE_STYLE = preload("uid://c8jt2o1rli1d6")
const SELECTION_CARD_SCENE = preload("uid://cxd4eej5fewhn")

const UPGRADE_PROBABILITY_CONFIG = {
	"rare": { "start_wave": 2, "base_multi": 0.06 },
	"epic": { "start_wave": 4, "base_multi": 0.02 },
	"legendary": { "start_wave": 7, "base_multi": 0.0023 },
	
}
const SHOP_PROBABILITY_CONFIG = {
	"rare": { "start_wave": 2, "base_multi": 0.1 },
	"epic": { "start_wave": 4, "base_multi": 0.06 },
	"legendary": { "start_wave": 7, "base_multi": 0.01 },
	
}

const TIER_COLORS: Dictionary[UpgradeTier, Color] = {
	UpgradeTier.RARE: Color(0.0, 0.557, 0.741),
	UpgradeTier.EPIC: Color(0.478, 0.251, 0.71),
	UpgradeTier.LEGENDARY: Color(0.906, 0.212, 0.212)
	
}

enum UpgradeTier{
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var available_players: Dictionary[String, PackedScene] = {
	"Egg" : preload("uid://v3s585564nk4")
}
var coins := 500
var player: Player
var game_paused:= false
var equipped_weapons: Array[ItemWeapon]
var selected_weapon: ItemWeapon
var main_player_selected: UnitStats
var main_weapon_selected: ItemWeapon

func get_harvesting_coins() -> void:
	if not is_instance_valid(player):
		return
	coins += player.stats.harvesting
	

func get_chance_success(chance: float) -> bool:
	var random := randf_range(0,1.0)
	if random < chance:
		return true
	return false
	
func get_selected_player() -> Player:
	var player_scene := available_players[main_player_selected.name]
	var player_instance := player_scene.instantiate()
	player = player_instance
	return player
	
func apply_life_steal(weapon: Weapon) -> void:
	var steal_chance := (player.stats.life_steal / 100.0) + weapon.data.stats.life_steal
	if get_chance_success(steal_chance):
		player.health_component.heal(1.0)
		on_create_heal_text.emit(player, 1.0)
	
func get_tier_style(tier: UpgradeTier) -> StyleBoxFlat:
	match tier:
		UpgradeTier.COMMON:
			return COMMON_STYLE
		UpgradeTier.RARE:
			return RARE_STYLE
		UpgradeTier.EPIC:
			return EPIC_STYLE
		_:
			return LEGENDARY_STYLE

func calculate_tier_probability(current_wave: int, config: Dictionary) -> Array[float]:
	var common_chance := 0.0
	var rare_chance := 0.0
	var epic_chance := 0.0
	var legendary_chance := 0.0
	
	# starts increasing at wave 2, base 0%
	if current_wave >= config.rare.start_wave: 
		rare_chance = min(1.0, (current_wave - 1) * config.rare.base_multi)
		
	# starts increasing at wave 4, base 0%
	if current_wave >= config.epic.start_wave:
		epic_chance = min(1.0, (current_wave - 3) * config.epic.base_multi)
		
	# starts increasing at wave 7, base 0%
	if current_wave >= config.legendary.start_wave:
		legendary_chance = min(1.0, (current_wave - 6) * config.legendary.base_multi)
	
	# 10 luck = 10% chance of higher tier 
	var luck_factor := 1.0 + (Global.player.stats.luck/ 100.0)
	rare_chance *= luck_factor
	epic_chance *= luck_factor
	legendary_chance *= luck_factor
	
	# normalize probabilities
	var total_non_common_chances := rare_chance + epic_chance + legendary_chance
	if total_non_common_chances > 1.0:
		var scale_down := 1.0/total_non_common_chances
		rare_chance*= scale_down
		epic_chance*= scale_down
		legendary_chance*= scale_down
		total_non_common_chances = 1.0
	
	# common takes remaining probabilitiy
	common_chance = 1.0 - total_non_common_chances
	
	# debug print
	print("Wave: %d, Luck: %.1f => Chances: C: %.2f R: %.2f E:%.2f L:%.2f" %
	[current_wave, Global.player.stats.luck, common_chance, rare_chance, epic_chance, legendary_chance] )
		
	return [
		max(0.0,common_chance),
		max(0.0,rare_chance),
		max(0.0,epic_chance),
		max(0.0,legendary_chance),
	]
	
func select_items_for_offer(item_pool: Array, current_wave: int, config: Dictionary) -> Array:
	
	# 
	var tier_chances := calculate_tier_probability(current_wave, config)
	
	var legendary_limit = tier_chances[3]
	var epic_limit = legendary_limit + tier_chances[2]
	var rare_limit = epic_limit + tier_chances[1]
	
	var offered_items: Array = []
	var attempts := 0
	while offered_items.size() < 4 and attempts < 100:
		attempts += 1
		var roll := randf()
		var chosen_tier_index := 0
		if roll < legendary_limit:
			chosen_tier_index = 3 # legendary
		elif roll < epic_limit:
			chosen_tier_index = 2 #epic
		elif roll < rare_limit:
			chosen_tier_index = 1 #rare
			
		var potential_items: Array = []
		var current_search_tier_index := chosen_tier_index
		
		while potential_items.is_empty() and current_search_tier_index >= 0:
			potential_items = item_pool.filter(func(item: ItemBase): return item.item_tier == current_search_tier_index)
			
			if potential_items.is_empty():
				current_search_tier_index -= 1
			else: 
				break
		if not potential_items.is_empty():
			var selected_item = potential_items.pick_random()
			
			if not offered_items.has(selected_item):
				offered_items.append(selected_item)
	return offered_items
	
	
