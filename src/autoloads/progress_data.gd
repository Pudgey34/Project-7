extends Node

const save_path: String = "user://data.sav"
const settings_path: String = "user://settings.cfg"
const MENU_START_UNSET := -1
const MENU_START_NEW_GAME := 0
const MENU_START_CONTINUE := 1
const MIN_DB := -40.0

var current_wave: int
var player_stats: Dictionary = {}
var current_player_name: String
var my_weapons: Array = []
var my_passives: Array = []
var resume_from_shop: bool = true

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var fullscreen_enabled: bool = false

var has_saved_game: bool = false
var menu_start_mode: int = MENU_START_UNSET


func _ready() -> void:
	load_settings()


func has_save_file() -> bool:
	return FileAccess.file_exists(save_path)


func clear_save_game() -> void:
	has_saved_game = false
	current_wave = 0
	current_player_name = ""
	player_stats.clear()
	my_weapons.clear()
	my_passives.clear()
	resume_from_shop = true
	Global.equipped_weapons.clear()

	if not FileAccess.file_exists(save_path):
		return

	var global_path := ProjectSettings.globalize_path(save_path)
	var err := DirAccess.remove_absolute(global_path)
	if err != OK:
		push_warning("Failed to remove save file: %s" % global_path)


func get_save_summary() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {
			"has_save": false,
			"player_name": "",
			"wave": 1
		}

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {
			"has_save": false,
			"player_name": "",
			"wave": 1
		}

	var json_string := file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_string)
	if data == null or not (data is Dictionary):
		return {
			"has_save": false,
			"player_name": "",
			"wave": 1
		}

	var player_name := str(data.get("current_player_name", ""))
	if player_name.is_empty():
		player_name = "Unknown"

	return {
		"has_save": true,
		"player_name": player_name,
		"wave": int(data.get("current_wave", 1))
	}


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
	Global.coins = 0
	


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(settings_path)
	if err != OK:
		apply_settings()
		return

	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen_enabled = bool(config.get_value("display", "fullscreen", fullscreen_enabled))

	apply_settings()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen_enabled)
	config.save(settings_path)


func apply_settings() -> void:
	_set_bus_from_linear("Master", master_volume)
	_set_bus_from_linear("Music", music_volume)
	_set_bus_from_linear("SFX", sfx_volume)

	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_set_bus_from_linear("Master", master_volume)
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_set_bus_from_linear("Music", music_volume)
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_set_bus_from_linear("SFX", sfx_volume)
	save_settings()


func set_fullscreen_enabled(value: bool) -> void:
	fullscreen_enabled = value
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()


func _set_bus_from_linear(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return

	if value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, MIN_DB)
		return

	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func save_game(coins_override: int = -1) -> void:
	var coins_to_save := Global.coins
	var arena := get_tree().get_first_node_in_group("arena") as Arena

	if coins_override >= 0:
		coins_to_save = coins_override
	elif arena and not (arena.shop_panel.visible or arena.upgrade_panel.visible):
		coins_to_save = arena.get_wave_start_coins()

	var save_dict: Dictionary = {
		"coins": coins_to_save,
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


	if arena == null:
		return

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
