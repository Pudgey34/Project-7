extends Panel
class_name ShopPanel

signal on_shop_next_wave

const SHOP_CARD_SCENE = preload("uid://bqr2tbjs3nfti")
const WEAPONS_TITLE_BASE := "Weapons"
const SELL_BUTTON_BASE := "Sell Weapon"
const REROLL_BUTTON_BASE := "reroll"

@export var shop_items: Array[ItemBase]
@export var reroll_base_cost := 10
@export var reroll_cost_step := 5

@onready var items_container: HBoxContainer = %ItemsContainer
@onready var passives_container: GridContainer = %PassivesContainer
@onready var weapons_container: GridContainer = %WeaponsContainer
@onready var weapons_title: Label = $"MarginContainer/Control/WeaponsTitle"
@onready var reroll_button: Button = %RerollButton

@onready var combine_button: Button = %CombineButton
@onready var sell_button: Button = $"MarginContainer/Control/VBoxContainer/SellButton"



var context_card: ItemCard
var reroll_cost := 0
var current_shop_wave := 1

func _ready() -> void: 
	for child in passives_container.get_children(): child.queue_free()
	for child in weapons_container.get_children(): child.queue_free()
	combine_button.disabled = true
	reroll_cost = max(0, reroll_base_cost)
	_wire_shop_card_signals()
	_update_weapons_title()
	_update_sell_button_text()
	_update_reroll_button_text()

func _update_weapons_title() -> void:
	if not is_instance_valid(weapons_title):
		return

	var max_weapons := 2
	if is_instance_valid(Global.player):
		max_weapons = Global.player.stats.max_weapons

	weapons_title.text = "%s (Max: %d)" % [WEAPONS_TITLE_BASE, max_weapons]

func _format_sell_price(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return str(snapped(value, 0.1))

func _update_sell_button_text() -> void:
	if not is_instance_valid(sell_button):
		return

	var text := SELL_BUTTON_BASE
	if context_card and context_card.item and context_card.item.item_type == ItemBase.ItemType.WEAPON:
		var weapon := context_card.item as ItemWeapon
		if weapon:
			var sell_price := weapon.item_cost * 0.5
			text = "%s\n(%s)" % [SELL_BUTTON_BASE, _format_sell_price(sell_price)]

	sell_button.text = text

func _update_reroll_button_text() -> void:
	if not is_instance_valid(reroll_button):
		return

	reroll_button.text = "%s\n(%d)" % [REROLL_BUTTON_BASE, reroll_cost]

func _clear_shop_offer_cards() -> void:
	for child in items_container.get_children():
		items_container.remove_child(child)
		child.queue_free()

func _populate_shop_offer_cards(current_wave: int) -> void:
	_clear_shop_offer_cards()

	var config := Global.SHOP_PROBABILITY_CONFIG
	var selected_items := Global.select_items_for_offer(shop_items, current_wave, config)
	for shop_item : ItemBase in selected_items:
		var card_instance := SHOP_CARD_SCENE.instantiate() as ShopCard
		items_container.add_child(card_instance)
		card_instance.shop_item = shop_item

	_wire_shop_card_signals()

func _wire_shop_card_signals() -> void:
	for child in items_container.get_children():
		if child is ShopCard:
			var card := child as ShopCard
			if not card.on_item_purchased.is_connected(_on_item_purchased):
				card.on_item_purchased.connect(_on_item_purchased)
			if not card.on_purchase_failed.is_connected(_on_item_purchase_failed):
				card.on_purchase_failed.connect(_on_item_purchase_failed)
	
	
func load_shop(current_wave: int) -> void:
	current_shop_wave = current_wave
	reroll_cost = max(0, reroll_base_cost)
	_populate_shop_offer_cards(current_wave)
	_update_reroll_button_text()
	_update_weapons_title()
		
func create_item_card() -> ItemCard:
	var item_card := Global.ITEM_CARD_SCENE.instantiate() as ItemCard
	item_card.on_item_card_selected.connect(_on_item_card_selected)
	return item_card
	
func create_item_weapon(weapon: ItemWeapon) -> void:
	var card := create_item_card()
	weapons_container.add_child(card)
	card.item = weapon
		


func _on_new_wave_button_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	on_shop_next_wave.emit()

func _on_reroll_button_pressed() -> void:
	if Global.coins < reroll_cost:
		SoundManager.play_sound(SoundManager.Sound.ERROR, false, 0.82, -8.0)
		_show_shop_popup("Insufficient Funds", Color(1.0, 0.40, 0.40, 1.0))
		return

	Global.coins -= reroll_cost
	reroll_cost += max(0, reroll_cost_step)
	_populate_shop_offer_cards(current_shop_wave)
	SoundManager.play_sound(SoundManager.Sound.UI)
	_update_reroll_button_text()

func _on_item_purchased(item: ItemBase) -> void:
	if item.item_type == ItemBase.ItemType.WEAPON:
		if not is_instance_valid(Global.player):
			return

		var item_card := create_item_card()
		var weapon := item as ItemWeapon

		if Global.equipped_weapons.size() >= Global.player.stats.max_weapons:
			if _try_auto_merge_weapon_purchase(weapon):
				return
			return

		weapons_container.add_child(item_card)
		Global.player.add_weapon(weapon)
		Global.equipped_weapons.append(weapon)
		item_card.item = item
		SoundManager.play_sound(SoundManager.Sound.PURCHASE, false)
		
	elif item.item_type == ItemBase.ItemType.PASSIVE:
		# Check if this passive already exists
		var existing_card: ItemCard = null
		for card in passives_container.get_children():
			if card is ItemCard and card.item and card.item.item_name == item.item_name:
				existing_card = card
				break
		
		if existing_card:
			# Increment the stack count on the existing card
			existing_card.increment_stack()
		else:
			# Create new card for first purchase
			var item_card := create_item_card()
			passives_container.add_child(item_card)
			item_card.item = item
		
		# Apply passive effects
		var passive := item as ItemPassive
		passive.apply_passive()
		SoundManager.play_sound(SoundManager.Sound.PURCHASE, false)

	_update_weapons_title()


func _try_auto_merge_weapon_purchase(purchased_weapon: ItemWeapon) -> bool:
	if not purchased_weapon or not purchased_weapon.upgrade_to:
		return false

	var merge_weapon_node: Weapon = null
	for current_weapon in Global.player.current_weapons:
		if current_weapon and current_weapon.data \
		and current_weapon.data.item_name == purchased_weapon.item_name \
		and current_weapon.data.item_tier == purchased_weapon.item_tier \
		and current_weapon.data.upgrade_to:
			merge_weapon_node = current_weapon
			break

	if not merge_weapon_node:
		return false

	var merge_card: ItemCard = null
	for card in weapons_container.get_children():
		if card is ItemCard and card.item \
		and card.item.item_name == purchased_weapon.item_name \
		and card.item.item_tier == purchased_weapon.item_tier:
			merge_card = card
			break

	if not merge_card:
		return false

	Global.player.current_weapons.erase(merge_weapon_node)
	Global.equipped_weapons.erase(merge_weapon_node.data)
	merge_weapon_node.queue_free()
	merge_card.queue_free()

	var upgraded_weapon: ItemWeapon = load(purchased_weapon.upgrade_to.resource_path)
	if not upgraded_weapon:
		return false

	Global.player.add_weapon(upgraded_weapon)
	Global.equipped_weapons.append(upgraded_weapon)

	var new_card := create_item_card()
	weapons_container.add_child(new_card)
	new_card.item = upgraded_weapon
	SoundManager.play_sound(SoundManager.Sound.SATISFYING, false)
	_show_shop_popup("Auto Merged!", Color(0.58, 1.0, 0.64, 1.0))
	return true

func _on_item_purchase_failed(reason: String) -> void:
	if reason == "insufficient_funds":
		_show_shop_popup("Insufficient Funds", Color(1.0, 0.40, 0.40, 1.0))
	elif reason == "inventory_full":
		_show_shop_popup("Inventory Full", Color(1.0, 0.78, 0.34, 1.0))

func _show_shop_popup(message: String, color: Color) -> void:
	var popup_parent := get_node_or_null("MarginContainer/Control") as Control
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
	feedback_label.global_position = Vector2(parent_center.x - feedback_label.size.x * 0.5, popup_parent.get_global_rect().position.y + 92.0)
	feedback_label.pivot_offset = feedback_label.size * 0.5
	feedback_label.scale = Vector2(0.72, 0.72)
	feedback_label.modulate.a = 1.0

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().set_parallel(true)
	tween.tween_property(feedback_label, "global_position:y", feedback_label.global_position.y - 26.0, 0.85)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.85)
	tween.finished.connect(feedback_label.queue_free)

func _on_item_card_selected(card: ItemCard) -> void:
	context_card = card
	_update_sell_button_text()
	
	var can_merge := false
	
	if card.item.item_type != ItemBase.ItemType.WEAPON:
		combine_button.disabled = true
		return
	
	if card.item.item_type == ItemBase.ItemType.WEAPON:
		var count := 0
		for weapon: ItemWeapon in Global.equipped_weapons:
			if weapon.item_name == card.item.item_name:
				count += 1
		if count >= 2:
			can_merge = true
			
			
	combine_button.disabled = not can_merge
	


func _on_combine_button_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	if not context_card:
		return
		
	var clicked_weapon := context_card.item as ItemWeapon
	if not clicked_weapon.upgrade_to:
		return
		
	var weapons_to_remove: Array[Weapon] = Global.player.current_weapons.filter(func(w: Weapon):
		return w.data.item_name == clicked_weapon.item_name).slice(0,2)
	
	var card_to_remove = weapons_container.get_children().filter(func(c: ItemCard):
		return c.item.item_name == clicked_weapon.item_name).slice(0,2)
	
	if weapons_to_remove.size() < 2 or card_to_remove.size() < 2:
		return
		
	
	# delete weapons
	for weapon : Weapon in weapons_to_remove: 
		Global.player.current_weapons.erase(weapon)
		Global.equipped_weapons.erase(weapon.data)
		weapon.queue_free()
		
	#delete cards
	for card: ItemCard in card_to_remove:
		card.queue_free()
	
	var upgraded_weapon: ItemWeapon = load(clicked_weapon.upgrade_to.resource_path)
	Global.player.add_weapon(upgraded_weapon)
	Global.equipped_weapons.append(upgraded_weapon)
	
	var new_card := create_item_card()
	weapons_container.add_child(new_card)
	new_card.item = upgraded_weapon
	SoundManager.play_sound(SoundManager.Sound.SATISFYING, false)
	
	context_card = null
	_update_sell_button_text()
		
		


func _on_sell_button_pressed() -> void:
	if not context_card:
		return
		
	var clicked_weapon := context_card.item as ItemWeapon
	if not clicked_weapon:
		return

	var coins := clicked_weapon.item_cost * 0.5
	
	var weapon_to_remove : Weapon = Global.player.current_weapons.filter(func(w: Weapon):
		return w.data.item_name == clicked_weapon.item_name).front()
		
	if weapon_to_remove:
		Global.player.current_weapons.erase(weapon_to_remove)
		Global.equipped_weapons.erase(weapon_to_remove.data)
		weapon_to_remove.queue_free()
		SoundManager.play_sound(SoundManager.Sound.SELL, false)
	else:
		return
		
	context_card.queue_free()
	context_card = null
	
	Global.coins += coins 
	_update_sell_button_text()
	_update_weapons_title()
