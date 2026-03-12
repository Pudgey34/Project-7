extends Panel

class_name SelectionPanel

signal on_selection_completed

@export var players: Array[UnitStats]
@export var start_weapons: Array[ItemWeapon]

@onready var player_container: HBoxContainer = %PlayerContainer
@onready var weapon_container: HBoxContainer = %WeaponContainer
@onready var player_icon: TextureRect = %PlayerIcon
@onready var player_title: Label = %PlayerTitle
@onready var player_description: RichTextLabel = %PlayerDescription
@onready var player_name: Label = %PlayerName

func _ready() -> void:
	# hides them if they arent being used
	for child in player_container.get_children(): child.queue_free()
	for child in weapon_container.get_children(): child.queue_free()
	show_player_info(false)
	load_players()
	load_weapons()
	
	
func load_players() -> void:
	if players.is_empty():
		return
	var first_player: UnitStats = players[0]
	for player: UnitStats in players:
		var card: SelectionCard = Global.SELECTION_CARD_SCENE.instantiate()
		card.pressed.connect(_on_player_selected.bind(player))
		player_container.add_child(card)
		_apply_character_select_card_palette(card)
		card.set_icon(player.icon)
	if is_instance_valid(first_player):
		_on_player_selected(first_player)
	
func load_weapons() -> void:
	if start_weapons.is_empty():
		return

	var first_weapon: ItemWeapon = start_weapons[0]
	
	for weapon: ItemWeapon in start_weapons:
		var card: SelectionCard = Global.SELECTION_CARD_SCENE.instantiate()
		card.pressed.connect(_on_weapon_selected.bind(weapon))
		weapon_container.add_child(card)
		_apply_character_select_card_palette(card)
		card.icon = weapon.item_icon

	if is_instance_valid(first_weapon):
		_on_weapon_selected(first_weapon)
	
func show_player_info(value: bool) -> void:
	player_icon.visible = value
	player_title.visible = value
	player_description.visible = value
	player_name.visible = value
	
func _on_player_selected(player: UnitStats) -> void:
	Global.main_player_selected = player
	show_player_info(true)
	
	player_icon.texture = player.icon
	player_name.text = player.name
	var desc_text = "[code]Health: [color=green]%s[/color]\nDamage: [color=green]%s[/color]\nSpeed: [color=green]%s[/color]\nLuck: [color=green]%s[/color]\nBlock Chance: [color=green]%s%%[/color]\n" % [player.health, player.damage, player.speed, player.luck, player.block_chance]
	if player.description:
		desc_text += "[color=#bdbdbd][font_size=14]%s[/font_size][/color]\n" % player.description
	player_description.text = desc_text + "[/code]"
	
func _on_weapon_selected(weapon: ItemWeapon) -> void:
	Global.main_weapon_selected = weapon


func _apply_character_select_card_palette(card: SelectionCard) -> void:
	var base_style := card.get_theme_stylebox("normal") as StyleBoxFlat
	if base_style == null:
		return

	var normal_style := base_style.duplicate() as StyleBoxFlat
	normal_style.bg_color = normal_style.bg_color.lightened(0.10)

	var active_style := normal_style.duplicate() as StyleBoxFlat
	active_style.border_width_left = 2
	active_style.border_width_top = 2
	active_style.border_width_right = 2
	active_style.border_width_bottom = 2
	active_style.border_color = Color(0.82, 0.82, 0.82, 1)

	card.add_theme_stylebox_override("normal", normal_style)
	card.add_theme_stylebox_override("hover", active_style)
	card.add_theme_stylebox_override("pressed", active_style)
	card.add_theme_stylebox_override("focus", active_style)


func _on_continue_button_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)

	if not Global.main_player_selected and not Global.main_weapon_selected:
		return
	on_selection_completed.emit()
	hide()
