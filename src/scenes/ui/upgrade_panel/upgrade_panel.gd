extends Panel

class_name UpgradePanel

const UPGRADE_CARD_SCENE = preload("uid://dodlei8lt3pwn")

@export var upgrade_list: Array[ItemUpgrade]
@export var reroll_wave_multiplier := 1

var items_container: HBoxContainer
var reroll_button: Button

var current_upgrade_wave := 1
var current_reroll_cost := 0
var reroll_uses_this_wave := 0

func _ready() -> void:
	_resolve_ui_refs()
	if is_instance_valid(reroll_button):
		reroll_button.pressed.connect(_on_reroll_button_pressed)
	_refresh_reroll_state()

func load_upgrades(current_wave: int) -> void:
	_resolve_ui_refs()
	current_upgrade_wave = max(1, current_wave)
	reroll_uses_this_wave = 0
	_refresh_reroll_state()
	_roll_upgrades()

func _resolve_ui_refs() -> void:
	if not is_instance_valid(items_container):
		items_container = get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/ItemsContainer") as HBoxContainer
	if not is_instance_valid(reroll_button):
		reroll_button = get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/RerollButton") as Button

func _roll_upgrades() -> void:
	_resolve_ui_refs()
	if not is_instance_valid(items_container):
		push_warning("UpgradePanel: ItemsContainer is missing; cannot roll upgrades.")
		return

	for child in items_container.get_children():
		child.queue_free()
		
	var config := Global.UPGRADE_PROBABILITY_CONFIG
	var selected_upgrades := Global.select_items_for_offer(upgrade_list, current_upgrade_wave, config)
	
	for random_upg: ItemUpgrade in selected_upgrades:
		var card_instance := UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
		items_container.add_child(card_instance)
		card_instance.item_data = random_upg

func _get_base_reroll_cost() -> int:
	var base_cost: float = float(max(1, current_upgrade_wave * reroll_wave_multiplier))
	return int(round(base_cost))

func _refresh_reroll_state() -> void:
	var base_cost := _get_base_reroll_cost()
	current_reroll_cost = int(round(float(base_cost) * pow(2.0, float(reroll_uses_this_wave))))
	_update_reroll_button_text()

func _update_reroll_button_text() -> void:
	if not is_instance_valid(reroll_button):
		return
	reroll_button.text = "Reroll\n(%d)" % current_reroll_cost

func _on_reroll_button_pressed() -> void:
	if Global.coins < current_reroll_cost:
		SoundManager.play_sound(SoundManager.Sound.ERROR, false, 0.82, -8.0)
		_show_upgrade_popup("Insufficient Funds", Color(1.0, 0.40, 0.40, 1.0))
		return

	Global.coins -= current_reroll_cost
	reroll_uses_this_wave += 1
	_refresh_reroll_state()
	_roll_upgrades()
	SoundManager.play_sound(SoundManager.Sound.UI)

func _show_upgrade_popup(message: String, color: Color) -> void:
	var popup_parent := get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer") as Control
	if not popup_parent:
		popup_parent = self

	var feedback_label := Label.new()
	feedback_label.text = message
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_label.top_level = true
	feedback_label.z_index = 500
	feedback_label.size = Vector2(520.0, 72.0)
	feedback_label.add_theme_font_size_override("font_size", 42)
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	feedback_label.add_theme_constant_override("outline_size", 8)

	popup_parent.add_child(feedback_label)
	await get_tree().process_frame
	var parent_center := popup_parent.get_global_rect().get_center()
	feedback_label.global_position = parent_center - (feedback_label.size * 0.5)
	feedback_label.pivot_offset = feedback_label.size * 0.5
	feedback_label.scale = Vector2(0.72, 0.72)
	feedback_label.modulate.a = 1.0

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(feedback_label, "position:y", feedback_label.position.y - 48.0, 0.65).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.35).set_delay(0.8).set_ease(Tween.EASE_IN)
	tween.finished.connect(feedback_label.queue_free)
