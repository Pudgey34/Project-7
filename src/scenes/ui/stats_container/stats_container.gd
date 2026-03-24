extends Panel

class_name StatsContainer

const STATS_PER_PAGE := 7

@onready var health_label: Label = %HealthLabel
@onready var hp_regen_label: Label = %HPRegenLabel
@onready var life_steal_label: Label = %LifeStealLabel
@onready var luck_label: Label = %LuckLabel
@onready var speed_label: Label = %SpeedLabel
@onready var attack_speed_label: Label = %AttackSpeedLabel
@onready var block_label: Label = %BlockLabel
@onready var harvesting_label: Label = %HarvestingLabel
@onready var max_weapons_label: Label = %MaxWeaponsLabel
@onready var damage_label: Label = %DamageLabel
@onready var range_label: Label = %RangeLabel
@onready var pickup_range_label: Label = %PickupRangeLabel
@onready var stats_health_panel: Panel = $MarginContainer/VBoxContainer/StatsHealth
@onready var stats_hp_regen_panel: Panel = $MarginContainer/VBoxContainer/StatsHPRegen
@onready var stats_life_steal_panel: Panel = $MarginContainer/VBoxContainer/StatsLifeSteal
@onready var stats_damage_panel: Panel = $MarginContainer/VBoxContainer/StatsDamage
@onready var stats_luck_panel: Panel = $MarginContainer/VBoxContainer/StatsLuck
@onready var stats_speed_panel: Panel = $MarginContainer/VBoxContainer/StatsSpeed
@onready var stats_attack_speed_panel: Panel = $MarginContainer/VBoxContainer/StatsAttackSpeed
@onready var stats_block_panel: Panel = $MarginContainer/VBoxContainer/StatsBlock
@onready var stats_harvesting_panel: Panel = $MarginContainer/VBoxContainer/StatsHarvesting
@onready var stats_max_weapons_panel: Panel = $MarginContainer/VBoxContainer/StatsMaxWeapons
@onready var stats_range_panel: Panel = $MarginContainer/VBoxContainer/StatsRange
@onready var stats_pickup_range_panel: Panel = $MarginContainer/VBoxContainer/StatsPickupRange
@onready var prev_page_button: Button = %PrevPageButton
@onready var next_page_button: Button = %NextPageButton
@onready var page_label: Label = %PageLabel

var stat_panels: Array[Panel] = []
var current_page := 0
var total_pages := 1

func _ready() -> void:
	_setup_stat_tooltips()
	_setup_stat_pages()
	prev_page_button.pressed.connect(_on_prev_page_pressed)
	next_page_button.pressed.connect(_on_next_page_pressed)

func _process(_delta: float) -> void:
	if not is_instance_valid(Global.player):
		return
	
	health_label.text = str(Global.player.stats.health)
	hp_regen_label.text = str(Global.player.stats.hp_regen)
	life_steal_label.text = str(Global.player.stats.life_steal) + "%"
	damage_label.text = str(Global.player.stats.damage)
	range_label.text = str(_get_max_weapon_range())
	luck_label.text = str(Global.player.stats.luck)
	speed_label.text = str(Global.player.stats.speed)
	attack_speed_label.text = "%s%%" % _format_compact_number(Global.player.stats.attack_speed * 100.0)
	pickup_range_label.text = str(snappedf(Global.player.stats.pickup_range, 0.01))
	block_label.text = str(Global.player.stats.block_chance) + "%"
	harvesting_label.text = str(Global.player.stats.harvesting)
	max_weapons_label.text = "%d/%d" % [Global.player.current_weapons.size(), Global.player.stats.max_weapons]


func _setup_stat_pages() -> void:
	stat_panels = [
		stats_health_panel,
		stats_hp_regen_panel,
		stats_life_steal_panel,
		stats_damage_panel,
		stats_range_panel,
		stats_luck_panel,
		stats_speed_panel,
		stats_attack_speed_panel,
		stats_pickup_range_panel,
		stats_block_panel,
		stats_harvesting_panel,
		stats_max_weapons_panel,
	]

	total_pages = maxi(1, int(ceil(float(stat_panels.size()) / float(STATS_PER_PAGE))))
	current_page = clampi(current_page, 0, total_pages - 1)
	_refresh_page_visibility()


func _refresh_page_visibility() -> void:
	var start_index := current_page * STATS_PER_PAGE
	var end_index := start_index + STATS_PER_PAGE

	for i in stat_panels.size():
		var is_on_page := i >= start_index and i < end_index
		stat_panels[i].visible = is_on_page

	page_label.text = "%d/%d" % [current_page + 1, total_pages]
	prev_page_button.disabled = current_page == 0
	next_page_button.disabled = current_page >= total_pages - 1


func _on_prev_page_pressed() -> void:
	if current_page <= 0:
		return

	SoundManager.play_sound(SoundManager.Sound.UI)
	current_page -= 1
	_refresh_page_visibility()


func _on_next_page_pressed() -> void:
	if current_page >= total_pages - 1:
		return

	SoundManager.play_sound(SoundManager.Sound.UI)
	current_page += 1
	_refresh_page_visibility()

func _setup_stat_tooltips() -> void:
	_set_tooltip_for_stat(stats_health_panel, "Max HP. Increases how much damage you can take before dying.")
	_set_tooltip_for_stat(stats_hp_regen_panel, "HP Regen. Amount of health restored over time.")
	_set_tooltip_for_stat(stats_life_steal_panel, "Life Steal. Chance to heal when your attacks hit.")
	_set_tooltip_for_stat(stats_damage_panel, "Damage. Added to your weapons to increase hit damage.")
	_set_tooltip_for_stat(stats_range_panel, "Range. Maximum range among your equipped weapons.")
	_set_tooltip_for_stat(stats_luck_panel, "Luck. Improves odds for better upgrade and item choices.")
	_set_tooltip_for_stat(stats_speed_panel, "Speed. Increases movement speed.")
	_set_tooltip_for_stat(stats_attack_speed_panel, "Attack Speed. Increases attack frequency. 100% is base speed.")
	_set_tooltip_for_stat(stats_pickup_range_panel, "Pickup Range. Multiplier for how far away you can collect drops.")
	_set_tooltip_for_stat(stats_block_panel, "Block. Chance to negate incoming damage.")
	_set_tooltip_for_stat(stats_harvesting_panel, "Harvesting. Extra coins gained at the end of each wave.")
	_set_tooltip_for_stat(stats_max_weapons_panel, "Max Weapons. Maximum number of weapons you can equip at once.")


func _get_max_weapon_range() -> float:
	if not is_instance_valid(Global.player):
		return 0.0

	var max_range := 0.0
	for weapon in Global.player.current_weapons:
		if weapon and weapon.data and weapon.data.stats:
			max_range = max(max_range, weapon.data.stats.max_range)

	return max_range

func _set_tooltip_for_stat(panel: Control, description: String) -> void:
	panel.tooltip_text = description


func _format_compact_number(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))

	return str(snappedf(value, 0.1))
