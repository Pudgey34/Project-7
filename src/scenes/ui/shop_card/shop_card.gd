extends Panel

class_name ShopCard

signal on_item_purchased(item: ItemBase)
signal on_purchase_failed(reason: String)
signal on_lock_toggled(locked: bool)

const AFFORDABLE_PRICE_COLOR := Color(1, 1, 1, 1)
const UNAFFORDABLE_PRICE_COLOR := Color(1, 0.35, 0.35, 1)
const LOCK_OPEN_ICON: Texture2D = preload("res://assets/sprites/open.png")
const LOCK_CLOSED_ICON: Texture2D = preload("res://assets/sprites/close.png")
const LOCK_OPEN_TOOLTIP := "Unlocked"
const LOCK_CLOSED_TOOLTIP := "Locked (persists through rerolls and next waves)"

@export var shop_item: ItemBase: set = _set_shop_item

@onready var item_icon: TextureRect = %ItemIcon
@onready var item_name: Label = %ItemName
@onready var item_description: RichTextLabel = %ItemDescription
@onready var coins_label: Label = %CoinsLabel
@onready var item_type: Label = %ItemType
@onready var lock_button: Button = %LockButton

var _last_can_afford: Variant = null
var is_locked := false


func _ready() -> void:
	_update_lock_visuals()


func set_locked(value: bool) -> void:
	is_locked = value
	_update_lock_visuals()

func _set_shop_item(value: ItemBase) -> void:
	shop_item = value
	if value == null:
		return

	item_icon.texture = value.item_icon
	item_name.text = value.item_name
	item_type.text = ItemBase.ItemType.keys()[value.item_type]
	item_description.text = value.get_description()
	coins_label.text = str(value.item_cost)
	tooltip_text = _get_plain_tooltip_text(value)
	_update_price_color()
	
	var style := Global.get_tier_style(value.item_tier)
	add_theme_stylebox_override("panel", style)


func _process(_delta: float) -> void:
	_update_price_color()


func _update_price_color() -> void:
	if not shop_item:
		return

	var can_afford := Global.coins >= shop_item.item_cost
	if _last_can_afford != null and can_afford == _last_can_afford:
		return

	_last_can_afford = can_afford
	if can_afford:
		coins_label.self_modulate = AFFORDABLE_PRICE_COLOR
	else:
		coins_label.self_modulate = UNAFFORDABLE_PRICE_COLOR


func _update_lock_visuals() -> void:
	if not is_instance_valid(lock_button):
		return

	lock_button.icon = LOCK_CLOSED_ICON if is_locked else LOCK_OPEN_ICON
	lock_button.tooltip_text = LOCK_CLOSED_TOOLTIP if is_locked else LOCK_OPEN_TOOLTIP

func _get_plain_tooltip_text(value: ItemBase) -> String:
	var description := value.get_description()
	if description.is_empty():
		return value.item_name

	var regex := RegEx.new()
	regex.compile("\\[[^\\]]*\\]")
	var plain_description := regex.sub(description, "", true).strip_edges()

	if plain_description.is_empty():
		return value.item_name

	return "%s\n%s" % [value.item_name, plain_description]
	


func _on_buy_button_pressed() -> void:
	if Global.coins < shop_item.item_cost:
		SoundManager.play_sound(SoundManager.Sound.ERROR, false, 0.82, -8.0)
		on_purchase_failed.emit("insufficient_funds")
		return

	var max_weapons := 2
	if is_instance_valid(Global.player):
		max_weapons = Global.player.stats.max_weapons

	if shop_item.item_type == ItemBase.ItemType.WEAPON and Global.equipped_weapons.size() >= max_weapons:
		var weapon_item := shop_item as ItemWeapon
		if not _can_auto_merge_on_full_inventory(weapon_item):
			SoundManager.play_sound(SoundManager.Sound.ERROR, false, 0.82, -8.0)
			on_purchase_failed.emit("inventory_full")
			return
	
	Global.coins -= shop_item.item_cost
	on_item_purchased.emit(shop_item)
	queue_free()


func _on_lock_button_pressed() -> void:
	is_locked = not is_locked
	_update_lock_visuals()
	on_lock_toggled.emit(is_locked)
	SoundManager.play_sound(SoundManager.Sound.UI)


func _can_auto_merge_on_full_inventory(weapon_item: ItemWeapon) -> bool:
	if not weapon_item or not weapon_item.upgrade_to:
		return false

	for equipped in Global.equipped_weapons:
		if equipped is ItemWeapon \
		and equipped.item_name == weapon_item.item_name \
		and equipped.item_tier == weapon_item.item_tier \
		and equipped.upgrade_to:
			return true

	return false
		
