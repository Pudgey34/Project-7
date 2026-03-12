extends Node

const save_path: String = "user://data.sav"
const MENU_START_UNSET := -1
const MENU_START_NEW_GAME := 0
const MENU_START_CONTINUE := 1

var current_wave: int
var player_stats: Dictionary = {}
var current_player_name: String
var my_weapons: Array = []
var my_passives: Array = []
var resume_from_shop: bool = true

var has_saved_game: bool = false
var menu_start_mode: int = MENU_START_UNSET


func has_save_file() -> bool:
	return FileAccess.file_exists(save_path)


func set_menu_start_mode(mode: int) -> void:
	menu_start_mode = mode
	if mode == MENU_START_NEW_GAME:
		_prepare_new_game_state()


func _prepare_new_game_state() -> void:
	current_wave = 0
	player_stats.clear()
	current_player_name = ""
	my_weapons.clear()
	my_passives.clear()
	resume_from_shop = true
	has_saved_game = false

	Global.game_paused = false
	Global.player = null
	Global.equipped_weapons.clear()
	Global.main_player_selected = null
	Global.main_weapon_selected = null
	Global.coins = 500

func save_game() -> void:
	var save_dict: Dictionary = {
		"coins": Global.coins,
		"current_wave": 0,
		"resume_from_shop": true,
		"player_stats": {},
		"current_player_name": "",
		"equipped_weapons": [],
		"purchased_weapons": [],
		"purchased_passives": []
	}
	
	if Global.player and is_instance_valid(Global.player):
		save_dict["current_player_name"] = Global.player.stats.name
		var stats := Global.player.stats
		
		for stat in stats.get_script().get_script_property_list():
			if stat.type == TYPE_FLOAT or stat.type == TYPE_INT:
				save_dict["player_stats"][stat.name] = stats.get(stat.name)
		print(save_dict["player_stats"])


	var arena = get_tree().get_first_node_in_group("arena") as Arena
	save_dict["current_wave"] = arena.spawner.wave_index
	save_dict["resume_from_shop"] = arena.shop_panel.visible or arena.upgrade_panel.visible
	for weapon in Global.equipped_weapons:
		save_dict["equipped_weapons"].append(weapon.resource_path)
		
	var shop: ShopPanel = arena.shop_panel
	if shop:
		for card in shop.weapons_container.get_children():
			save_dict["purchased_weapons"].append(card.item.resource_path)
		for card in shop.passives_container.get_children():
			save_dict["purchased_passives"].append({
				"resource_path": card.item.resource_path,
				"stack_count": card.stack_count
			})
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var json_string := JSON.stringify(save_dict)
	file.store_string(json_string)
	file.close()
	
func load_game() -> void:
	has_saved_game = false
	if not FileAccess.file_exists(save_path):
		return
	var file = FileAccess.open(save_path, FileAccess.READ)
	var json_string := file.get_as_text() 
	var data = JSON.parse_string(json_string)
	file.close()
	
	Global.coins = data.get("coins", 0)
	current_wave = data.get("current_wave", 1)
	resume_from_shop = data.get("resume_from_shop", true)
	current_player_name = data.get("current_player_name", "")
	
	my_weapons.clear()
	for path in data.get("purchased_weapons", []):
		my_weapons.append(load(path))
	my_passives.clear()
	for passive_data in data.get("purchased_passives", []):
		if passive_data is Dictionary:
			var resource_path: String = passive_data.get("resource_path", "")
			if resource_path.is_empty():
				continue

			var passive_resource := load(resource_path)
			if passive_resource:
				my_passives.append({
					"item": passive_resource,
					"stack_count": int(passive_data.get("stack_count", 1))
				})
		elif passive_data is String:
			var legacy_passive := load(passive_data)
			if legacy_passive:
				my_passives.append({
					"item": legacy_passive,
					"stack_count": 1
				})
		
	player_stats = data.get("player_stats",{})
	
	Global.equipped_weapons.clear()
	for path in data.get("equipped_weapons", []):
		Global.equipped_weapons.append(load(path))
	
	has_saved_game = true
	

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		print("SAVING")
