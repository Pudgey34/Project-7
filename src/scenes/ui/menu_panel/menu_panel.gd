extends Panel

const ARENA_SCENE_PATH := "res://scenes/arena/arena.tscn"
const MIN_DB := -40.0
const BG_MUSIC := preload("res://assets/audio/Bg Music.mp3")

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var options_overlay: Panel = $OptionsOverlay
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var back_button: Button = %BackButton


func _ready() -> void:
	SoundManager.play_music(BG_MUSIC)

	_connect_button_sounds(new_game_button)
	_connect_button_sounds(continue_button)
	_connect_button_sounds(options_button)
	_connect_button_sounds(quit_button)
	_connect_button_sounds(back_button)

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	master_slider.value_changed.connect(_on_master_slider_value_changed)
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggle_toggled)

	_update_continue_button_state()
	_sync_options_ui_from_current_settings()


func _update_continue_button_state() -> void:
	var has_save := ProgressData.has_save_file()
	continue_button.disabled = not has_save

	if has_save:
		continue_button.modulate = Color(1, 1, 1, 1)
		continue_button.tooltip_text = ""
	else:
		continue_button.modulate = Color(0.55, 0.55, 0.55, 1)
		continue_button.tooltip_text = "No save data found"


func _connect_button_sounds(button: Button) -> void:
	button.mouse_entered.connect(_on_button_hovered)
	button.focus_entered.connect(_on_button_hovered)


func _on_button_hovered() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)


func _on_new_game_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	ProgressData.set_menu_start_mode(ProgressData.MENU_START_NEW_GAME)
	get_tree().change_scene_to_file(ARENA_SCENE_PATH)


func _on_continue_pressed() -> void:
	if not ProgressData.has_save_file():
		return

	SoundManager.play_sound(SoundManager.Sound.UI)
	ProgressData.set_menu_start_mode(ProgressData.MENU_START_CONTINUE)
	get_tree().change_scene_to_file(ARENA_SCENE_PATH)

func _on_options_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	_sync_options_ui_from_current_settings()
	_set_options_visible(true)

func _on_quit_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	get_tree().quit()


func _on_back_button_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	_set_options_visible(false)


func _set_options_visible(value: bool) -> void:
	options_overlay.visible = value


func _sync_options_ui_from_current_settings() -> void:
	master_slider.value = _get_bus_linear_volume("Master", 1.0)
	music_slider.value = _get_bus_linear_volume("Music", 1.0)
	sfx_slider.value = _get_bus_linear_volume("SFX", 1.0)

	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func _get_bus_linear_volume(bus_name: String, default_value: float) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return default_value

	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))


func _set_bus_from_slider(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return

	if value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, MIN_DB)
		return

	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func _on_master_slider_value_changed(value: float) -> void:
	_set_bus_from_slider("Master", value)


func _on_music_slider_value_changed(value: float) -> void:
	_set_bus_from_slider("Music", value)


func _on_sfx_slider_value_changed(value: float) -> void:
	_set_bus_from_slider("SFX", value)


func _on_fullscreen_toggle_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _unhandled_input(event: InputEvent) -> void:
	if options_overlay.visible and event.is_action_pressed("ui_cancel"):
		_set_options_visible(false)
		get_viewport().set_input_as_handled()
