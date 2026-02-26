extends Button

class_name ItemCard

signal on_item_card_selected(card: ItemCard)

@export var item: ItemBase: set = _set_item
@onready var item_icon: TextureRect = $ItemIcon
@onready var stack_label: Label = $StackLabel

var stack_count: int = 1: set = _set_stack_count

func _ready() -> void:
	_update_stack_label()

func _set_item(value: ItemBase) -> void:
	item = value
	item_icon.texture = item.item_icon
	
	var style := Global.get_tier_style(item.item_tier)
	
	add_theme_stylebox_override("normal", style)
	
	# Create hover style with white border
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.border_width_left = 3
	hover_style.border_width_top = 3
	hover_style.border_width_right = 3
	hover_style.border_width_bottom = 3
	hover_style.border_color = Color.WHITE
	
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("focus", hover_style)
	add_theme_stylebox_override("pressed", hover_style)

func _set_stack_count(value: int) -> void:
	stack_count = value
	_update_stack_label()

func _update_stack_label() -> void:
	if not is_node_ready() or not stack_label:
		return
	
	if stack_count > 1:
		stack_label.text = "X%d" % stack_count
		stack_label.visible = true
	else:
		stack_label.visible = false

func increment_stack() -> void:
	stack_count += 1

func _on_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	if item.item_type == ItemBase.ItemType.WEAPON:
		#Global.selected_weapon = item as ItemWeapon
		on_item_card_selected.emit(self)
