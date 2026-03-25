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
	"rare": { "start_wave": 1, "base_multi": 0.06 },
	"epic": { "start_wave": 2, "base_multi": 0.02 },
	"legendary": { "start_wave": 3, "base_multi": 0.0023 },
	
}
const SHOP_PROBABILITY_CONFIG = {
	"rare": { "start_wave": 1, "base_multi": 0.1 },
	"epic": { "start_wave": 2, "base_multi": 0.06 },
	"legendary": { "start_wave": 3, "base_multi": 0.01 },
	
}

const TIER_COLORS: Dictionary[UpgradeTier, Color] = {
	UpgradeTier.RARE: Color(0.0, 0.557, 0.741),
	UpgradeTier.EPIC: Color(0.478, 0.251, 0.71),
	UpgradeTier.LEGENDARY: Color(0.906, 0.212, 0.212)
	
}
const BLOCK_SOFT_CAP_PERCENT: float = 75.0

enum UpgradeTier{
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var available_players: Dictionary[String, PackedScene] = {
	"Egg" : preload("uid://v3s585564nk4"),
	"Tank" : preload("res://scenes/unit/players/player_tank.tscn"),
	"Fast" : preload("res://scenes/unit/players/player_fast.tscn"),
}
var coins := 0
var player: Player
var game_paused:= false
var equipped_weapons: Array[ItemWeapon]
var selected_weapon: ItemWeapon
var main_player_selected: UnitStats
var main_weapon_selected: ItemWeapon

func _ready() -> void:
	_apply_global_tooltip_theme()


func _apply_global_tooltip_theme() -> void:
	var root_window: Window = get_tree().root
	if root_window == null:
		return

	var theme: Theme
	if root_window.theme != null:
		theme = root_window.theme.duplicate()
	else:
		theme = Theme.new()

	var tooltip_panel_style: StyleBoxFlat = StyleBoxFlat.new()
	tooltip_panel_style.bg_color = Color(0.06, 0.06, 0.06, 1.0)
	tooltip_panel_style.border_color = Color(0.10, 0.82, 1.0, 1.0)
	tooltip_panel_style.border_width_left = 2
	tooltip_panel_style.border_width_top = 2
	tooltip_panel_style.border_width_right = 2
	tooltip_panel_style.border_width_bottom = 2
	tooltip_panel_style.corner_radius_top_left = 8
	tooltip_panel_style.corner_radius_top_right = 8
	tooltip_panel_style.corner_radius_bottom_right = 8
	tooltip_panel_style.corner_radius_bottom_left = 8
	tooltip_panel_style.content_margin_left = 12.0
	tooltip_panel_style.content_margin_top = 8.0
	tooltip_panel_style.content_margin_right = 12.0
	tooltip_panel_style.content_margin_bottom = 8.0

	theme.set_stylebox("panel", "TooltipPanel", tooltip_panel_style)
	theme.set_font_size("font_size", "TooltipLabel", 34)
	theme.set_color("font_color", "TooltipLabel", Color(1, 1, 1, 1))
	theme.set_color("font_outline_color", "TooltipLabel", Color(0, 0, 0, 1))
	theme.set_constant("outline_size", "TooltipLabel", 1)
	theme.set_constant("line_separation", "TooltipLabel", 2)

	root_window.theme = theme

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
	if weapon == null or weapon.data == null:
		return
	if not is_instance_valid(player):
		return
	if player.health_component == null or player.health_component.current_health <= 0.0:
		return

	var player_life_steal_percent: float = maxf(0.0, float(player.stats.life_steal))
	var weapon_life_steal_percent: float = maxf(0.0, float(weapon.data.stats.life_steal) * 100.0)
	var total_life_steal_percent: float = player_life_steal_percent + weapon_life_steal_percent
	if total_life_steal_percent <= 0.0:
		return

	var heal_points: int = _roll_stacked_percent(total_life_steal_percent)
	if heal_points <= 0:
		return

	var heal_amount: float = float(heal_points)
	player.health_component.heal(heal_amount)
	on_create_heal_text.emit(player, heal_amount)


func _roll_stacked_percent(chance_percent: float) -> int:
	if chance_percent <= 0.0:
		return 0

	var guaranteed_points: int = int(floor(chance_percent / 100.0))
	var remainder_chance: float = fmod(chance_percent, 100.0) / 100.0
	if remainder_chance > 0.0 and get_chance_success(remainder_chance):
		guaranteed_points += 1

	return max(0, guaranteed_points)


func get_effective_block_chance_percent(raw_block_chance_percent: float) -> float:
	if raw_block_chance_percent <= 0.0:
		return 0.0

	var soft_cap: float = BLOCK_SOFT_CAP_PERCENT
	var effective_block: float = soft_cap * (1.0 - exp(-raw_block_chance_percent / soft_cap))
	return clampf(effective_block, 0.0, soft_cap)
	
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
	
	# each tier starts from its configured wave and scales by base multiplier
	if current_wave >= config.rare.start_wave: 
		rare_chance = min(1.0, (current_wave - (config.rare.start_wave - 1)) * config.rare.base_multi)
		
	if current_wave >= config.epic.start_wave:
		epic_chance = min(1.0, (current_wave - (config.epic.start_wave - 1)) * config.epic.base_multi)
		
	if current_wave >= config.legendary.start_wave:
		legendary_chance = min(1.0, (current_wave - (config.legendary.start_wave - 1)) * config.legendary.base_multi)
	
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
	
	# debug print removed
		
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
	
	
