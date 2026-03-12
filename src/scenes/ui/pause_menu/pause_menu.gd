extends Panel
class_name PauseMenu

signal resumed
signal back_to_main_menu_requested
signal quit_requested

@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var quit_button: Button = %QuitButton

@onready var options_overlay: Panel = %OptionsOverlay
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var back_button: Button = %BackButton


func _ready() -> void:
	_connect_button_sounds(continue_button)
	_connect_button_sounds(options_button)
	_connect_button_sounds(main_menu_button)
	_connect_button_sounds(quit_button)
	_connect_button_sounds(back_button)

	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

	master_slider.value_changed.connect(_on_master_slider_value_changed)
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggle_toggled)

	_sync_options_ui_from_current_settings()
	close_menu()


func open_menu() -> void:
	_sync_options_ui_from_current_settings()
	_set_options_visible(false)
	show()


func close_menu() -> void:
	hide()
	_set_options_visible(false)


func _connect_button_sounds(button: Button) -> void:
	button.mouse_entered.connect(_on_button_hovered)
	button.focus_entered.connect(_on_button_hovered)


func _on_button_hovered() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)


func _on_continue_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	resumed.emit()


func _on_options_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	_sync_options_ui_from_current_settings()
	_set_options_visible(true)


func _on_main_menu_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	back_to_main_menu_requested.emit()


func _on_quit_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	quit_requested.emit()


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
