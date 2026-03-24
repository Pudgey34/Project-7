extends HBoxContainer

class_name PlayerHud

@onready var health_bar: HealthBar = %HealthBar
@onready var dash_indicator: DashIndicator = $DashIndicator

func _ready() -> void:
	var health_amount := health_bar.get_node_or_null("HealthAmount") as Label
	if health_amount:
		health_amount.add_theme_font_size_override("font_size", 30)
		health_amount.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		health_amount.add_theme_constant_override("outline_size", 3)

	var cooldown_label := dash_indicator.get_node_or_null("CooldownLabel") as Label
	if cooldown_label:
		cooldown_label.label_settings = null
		cooldown_label.add_theme_font_size_override("font_size", 22)
		cooldown_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		cooldown_label.add_theme_constant_override("outline_size", 2)

func _process(delta: float) -> void:
	if not is_instance_valid(Global.player):
		visible = false
		return

	var arena := get_tree().get_first_node_in_group("arena") as Arena
	if arena and (arena.shop_panel.visible or arena.upgrade_panel.visible):
		visible = false
		return

	visible = true
	var player: Player = Global.player
	if player.health_component.max_health <= 0:
		return

	var current := player.health_component.current_health
	var max_health := player.health_component.max_health
	health_bar.update_bar(current / max_health, current)
