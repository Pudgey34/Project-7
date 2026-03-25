extends Panel

const ARENA_SCENE_PATH := "res://scenes/arena/arena.tscn"
const BG_MUSIC := preload("res://assets/audio/Bg Music.mp3")
const BG_MUSIC_VOLUME_DB := -27.0

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var testing_mode_toggle: CheckButton = %TestingModeToggle
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var options_overlay: Panel = $OptionsOverlay
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var back_button: Button = %BackButton


func _ready() -> void:
	SoundManager.play_music(BG_MUSIC, false, BG_MUSIC_VOLUME_DB)

	_connect_button_sounds(new_game_button)
	_connect_button_sounds(continue_button)
	_connect_button_sounds(testing_mode_toggle)
	_connect_button_sounds(options_button)
	_connect_button_sounds(quit_button)
	_connect_button_sounds(back_button)

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	testing_mode_toggle.toggled.connect(_on_testing_mode_toggled)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	master_slider.value_changed.connect(_on_master_slider_value_changed)
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggle_toggled)

	_update_continue_button_state()
	_sync_options_ui_from_current_settings()
	testing_mode_toggle.set_pressed_no_signal(Global.testing_mode_enabled)
	_update_testing_mode_toggle_text()


func _update_continue_button_state() -> void:
	var save_summary := ProgressData.get_save_summary()
	var has_save: bool = save_summary.get("has_save", false)
	continue_button.disabled = not has_save

	if has_save:
		var player_name: String = save_summary.get("player_name", "Unknown")
		var wave: int = save_summary.get("wave", 1)
		continue_button.text = "Continue\n%s - Wave %d" % [player_name, wave]
		continue_button.modulate = Color(1, 1, 1, 1)
		continue_button.tooltip_text = ""
	else:
		continue_button.text = "Continue"
		continue_button.modulate = Color(0.55, 0.55, 0.55, 1)
		continue_button.tooltip_text = "No save data found"


func _connect_button_sounds(button: Button) -> void:
	button.mouse_entered.connect(_on_button_hovered)
	button.focus_entered.connect(_on_button_hovered)


func _on_button_hovered() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)


func _update_testing_mode_toggle_text() -> void:
	if Global.testing_mode_enabled:
		testing_mode_toggle.text = "Testing Mode (make player invincible): ON"
	else:
		testing_mode_toggle.text = "Testing Mode (make player invincible): OFF"


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


func _on_testing_mode_toggled(enabled: bool) -> void:
	Global.testing_mode_enabled = enabled
	_update_testing_mode_toggle_text()

func _on_options_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	_sync_options_ui_from_current_settings()
	_set_options_visible(true)

func _on_quit_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	ProgressData.save_game()
	get_tree().quit()


func _on_back_button_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	_set_options_visible(false)


func _set_options_visible(value: bool) -> void:
	options_overlay.visible = value


func _sync_options_ui_from_current_settings() -> void:
	master_slider.set_value_no_signal(ProgressData.master_volume)
	music_slider.set_value_no_signal(ProgressData.music_volume)
	sfx_slider.set_value_no_signal(ProgressData.sfx_volume)
	fullscreen_toggle.set_pressed_no_signal(ProgressData.fullscreen_enabled)


func _on_master_slider_value_changed(value: float) -> void:
	ProgressData.set_master_volume(value)


func _on_music_slider_value_changed(value: float) -> void:
	ProgressData.set_music_volume(value)


func _on_sfx_slider_value_changed(value: float) -> void:
	ProgressData.set_sfx_volume(value)


func _on_fullscreen_toggle_toggled(button_pressed: bool) -> void:
	ProgressData.set_fullscreen_enabled(button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if options_overlay.visible and event.is_action_pressed("ui_cancel"):
		_set_options_visible(false)
		get_viewport().set_input_as_handled()
