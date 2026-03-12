extends Panel
class_name GameOverScreen

signal back_to_main_menu_requested

@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	hide()


func open_screen() -> void:
	show()


func close_screen() -> void:
	hide()


func _on_main_menu_button_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	back_to_main_menu_requested.emit()
