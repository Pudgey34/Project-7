extends Node2D

class_name Arena

const BG_MUSIC := preload("res://assets/audio/Bg Music.mp3")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/menu_panel/menu_panel.tscn"
const FIRST_WAVE_TUTORIAL_TEXT := "WASD - Move\nSpacebar - Dodge (invulnerable while dodging)"

@export var player: Player

@export var normal_color: Color
@export var blocked_color: Color
@export var critical_color: Color
@export var hp_color: Color
@export var use_save_data: bool


@onready var wave_index_label: Label = %WaveIndexLabel
@onready var wave_time_label: Label = %WaveTimeLabel
@onready var spawner: Spawner = $Spawner
#@onready var upgrade_panel: UpgradePanel = $GameUI/UpgradePanel
@onready var shop_panel: ShopPanel = %ShopPanel
@onready var upgrade_panel: UpgradePanel = %UpgradePanel
@onready var coins_bag: CoinsBag = %CoinsBag
@onready var selection_panel: SelectionPanel = %SelectionPanel
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var game_over_screen: GameOverScreen = %GameOverScreen

var gold_list: Array[Coins]
var should_advance_wave_on_shop_continue := true
var wave_start_coins := 0
var first_wave_tutorial_label: Label
var first_wave_tutorial_shown := false


func _ready() -> void:
	SoundManager.play_music(BG_MUSIC)
	_setup_first_wave_tutorial_label()

	Global.on_create_block_text.connect(_on_create_block_text)
	Global.on_create_damage_text.connect(_on_create_damage_text)
	Global.on_upgrade_selected.connect(_on_upgrade_selected)
	Global.on_create_heal_text.connect(_on_create_heal_text)
	Global.on_enemy_died.connect(_on_enemy_died)
	
	var should_use_save_data := use_save_data
	if ProgressData.menu_start_mode != ProgressData.MENU_START_UNSET:
		should_use_save_data = ProgressData.menu_start_mode == ProgressData.MENU_START_CONTINUE
		ProgressData.menu_start_mode = ProgressData.MENU_START_UNSET
	
	if should_use_save_data:
		ProgressData.load_game()
		if ProgressData.has_saved_game:
			selection_panel.hide()
			shop_panel.hide()
			upgrade_panel.hide()
			should_advance_wave_on_shop_continue = true
			
			var player_scene: PackedScene = null
			if not ProgressData.current_player_name.is_empty():
				player_scene = Global.available_players.get(ProgressData.current_player_name, null)

			# Fallback to the first available player if save key is missing/invalid.
			if player_scene == null:
				var available_scenes: Array = Global.available_players.values()
				if available_scenes.is_empty():
					push_error("No available player scenes found in Global.available_players.")
					return
				player_scene = available_scenes[0] as PackedScene
			
			Global.player = player_scene.instantiate()
			add_child(Global.player)
			_setup_player_runtime(Global.player)
			
			for stat_name in ProgressData.player_stats:
				Global.player.stats.set(stat_name, ProgressData.player_stats[stat_name])
				
			for weapon_data in Global.equipped_weapons:
				Global.player.add_weapon(weapon_data)
				
			for weapon_data in ProgressData.my_weapons:
				shop_panel.create_item_weapon(weapon_data)
				
			for passive_data in ProgressData.my_passives:
				var passive_item: ItemBase = null
				var passive_stack_count := 1

				if passive_data is Dictionary:
					passive_item = passive_data.get("item", null)
					passive_stack_count = int(passive_data.get("stack_count", 1))
				else:
					passive_item = passive_data

				if not passive_item:
					continue

				var item_card := shop_panel.create_item_card()
				shop_panel.passives_container.add_child(item_card)
				item_card.item = passive_item
				item_card.stack_count = max(1, passive_stack_count)
				
			spawner.wave_index = ProgressData.current_wave

			if ProgressData.resume_from_shop:
				shop_panel.show()
				should_advance_wave_on_shop_continue = false
				shop_panel.load_shop(spawner.wave_index)
				Global.game_paused = true
			else:
				Global.game_paused = false
				_begin_wave_checkpoint()
				spawner.start_wave()


func _setup_first_wave_tutorial_label() -> void:
	first_wave_tutorial_label = Label.new()
	first_wave_tutorial_label.name = "FirstWaveTutorialLabel"
	first_wave_tutorial_label.text = FIRST_WAVE_TUTORIAL_TEXT
	first_wave_tutorial_label.visible = false
	first_wave_tutorial_label.z_index = 100
	first_wave_tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	first_wave_tutorial_label.add_theme_font_size_override("font_size", 28)
	first_wave_tutorial_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	first_wave_tutorial_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	first_wave_tutorial_label.add_theme_constant_override("outline_size", 3)
	first_wave_tutorial_label.anchors_preset = Control.PRESET_TOP_WIDE
	first_wave_tutorial_label.offset_top = 180
	first_wave_tutorial_label.offset_bottom = 280
	$GameUI.add_child(first_wave_tutorial_label)


func _show_first_wave_tutorial() -> void:
	if first_wave_tutorial_shown:
		return

	if spawner.wave_index != 1:
		return

	if first_wave_tutorial_label == null or not is_instance_valid(first_wave_tutorial_label):
		return

	first_wave_tutorial_shown = true
	first_wave_tutorial_label.visible = true
	await get_tree().create_timer(7.0).timeout
	if is_instance_valid(first_wave_tutorial_label):
		first_wave_tutorial_label.visible = false

func get_wave_start_coins() -> int:
	return wave_start_coins

func _begin_wave_checkpoint() -> void:
	wave_start_coins = Global.coins

func _process(delta:float) -> void:
	if Global.game_paused: return
	wave_index_label.text = spawner.get_wave_text()
	wave_time_label.text = spawner.get_wave_timer_text()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if _can_toggle_pause_menu() and not pause_menu.visible:
		_open_pause_menu()
		get_viewport().set_input_as_handled()
		return

	if pause_menu.visible:
		_close_pause_menu()
		get_viewport().set_input_as_handled()


func _can_toggle_pause_menu() -> bool:
	return not selection_panel.visible and not shop_panel.visible and not upgrade_panel.visible and not game_over_screen.visible


func _open_pause_menu() -> void:
	Global.game_paused = true
	spawner.pause_wave_timers()
	pause_menu.open_menu()


func _close_pause_menu() -> void:
	pause_menu.close_menu()
	spawner.resume_wave_timers()
	Global.game_paused = false


func _setup_player_runtime(player_instance: Player) -> void:
	if player_instance == null:
		return

	if not player_instance.health_component.on_unit_died.is_connected(_on_player_died):
		player_instance.health_component.on_unit_died.connect(_on_player_died)


func _on_player_died() -> void:
	Global.game_paused = true
	ProgressData.clear_save_game()
	spawner.pause_wave_timers()
	pause_menu.close_menu()
	await get_tree().create_timer(1.0).timeout
	game_over_screen.open_screen()
	
	
	
	
func create_floating_text(unit: Node2D) -> FloatingText:
	var instance := Global.FLOATING_TEXT_SCENE.instantiate() as FloatingText
	get_tree().root.add_child(instance)
	var random_pos := randf_range(0, TAU)*35
	var spawn_pos := unit.global_position + Vector2.RIGHT.rotated(random_pos)
	instance.global_position = spawn_pos
	return instance
	
func show_upgrades() -> void:
	upgrade_panel.load_upgrades(spawner.wave_index)
	upgrade_panel.show()
	
func start_new_wave() -> void:
	Global.game_paused = false
	Global.player.update_player_new_wave()
	spawner.wave_index += 1
	_begin_wave_checkpoint()
	spawner.start_wave()
	
func clean_arena() -> void:
	if gold_list.size() > 0:
		var target_center_pos := coins_bag.global_position + coins_bag.size / 2.0
		for gold in gold_list:
			if is_instance_valid(gold):
				var gold_item := gold as Coins
				gold_item.set_collection_target(target_center_pos)
	gold_list.clear()
	spawner.clear_enemies()
	

func wait_for_coins_collection() -> void:
	var max_wait_time := 5.0  # Maximum 5 seconds to wait
	var elapsed_time := 0.0
	var check_interval := 0.05
	var found_any_coins := false
	
	while elapsed_time < max_wait_time:
		var has_coins = false
		for child in get_children():
			if child is Coins:
				# Make sure any coins found also get sucked up
				var coin := child as Coins
				var target_center_pos := coins_bag.global_position + coins_bag.size / 2.0
				coin.set_collection_target(target_center_pos)
				has_coins = true
				found_any_coins = true
		
		if not has_coins:
			break
		
		await get_tree().create_timer(check_interval).timeout
		elapsed_time += check_interval

	if not found_any_coins:
		await get_tree().create_timer(1.0).timeout

func spawn_coins(enemy: Enemy) -> void:
	var random_angle := randf_range(0, TAU)
	var offset := Vector2.RIGHT.rotated(random_angle) * 35
	var spawn_pos := enemy.global_position + offset
	
	
	var gold_instance := Global.COINS_SCENE.instantiate()
	gold_list.append(gold_instance)
	
	gold_instance.global_position = spawn_pos
	gold_instance.value = enemy.stats.gold_drop
	call_deferred("add_child", gold_instance)
	

func _on_create_block_text(unit: Node2D) -> void:
	var text := create_floating_text(unit)
	text.setup("Blocked!", blocked_color)
	
func _on_create_damage_text(unit: Node2D, hitbox: HitboxComponent) -> void:
	var text := create_floating_text(unit)
	var color:= critical_color if hitbox.critical else normal_color
	text.setup(str(hitbox.damage), color)
	
	
func _on_create_heal_text(unit: Node2D, heal: float) -> void:
	var text := create_floating_text(unit)
	text.setup("+ %s" % heal, hp_color)
	
	
func _on_upgrade_selected() -> void:
	#print("Upgrade Selected.")
	upgrade_panel.hide()
	shop_panel.load_shop(spawner.wave_index)
	shop_panel.show()
	#start_new_wave()


func _on_spawner_on_wave_completed() -> void:
	if not Global.player: return
	clean_arena()
	await wait_for_coins_collection()
	show_upgrades()


func _on_shop_panel_on_shop_next_wave() -> void:
	shop_panel.hide()
	if should_advance_wave_on_shop_continue:
		start_new_wave()
	else:
		should_advance_wave_on_shop_continue = true
		Global.game_paused = false
		_begin_wave_checkpoint()
		spawner.start_wave()
	
func _on_enemy_died(enemy: Enemy) -> void:
	spawn_coins(enemy)


func _on_selection_panel_on_selection_completed() -> void:
	var player := Global.get_selected_player()
	add_child(player)
	_setup_player_runtime(player)
	player.add_weapon(Global.main_weapon_selected)
	shop_panel.create_item_weapon(Global.main_weapon_selected)
	Global.equipped_weapons.append(Global.main_weapon_selected)
	
	shop_panel.load_shop(spawner.wave_index)
	_begin_wave_checkpoint()
	spawner.start_wave()
	Global.game_paused = false
	_show_first_wave_tutorial()


func _on_pause_menu_resumed() -> void:
	_close_pause_menu()


func _on_pause_menu_back_to_main_menu_requested() -> void:
	# Persist the current run before returning to menu so Continue picks this session.
	ProgressData.save_game()
	Global.game_paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_pause_menu_quit_requested() -> void:
	# Persist current run so Continue works after quitting mid-wave.
	ProgressData.save_game()
	get_tree().quit()


func _on_game_over_screen_back_to_main_menu_requested() -> void:
	Global.game_paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
