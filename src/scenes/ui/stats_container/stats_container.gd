extends Panel

class_name StatsContainer

@onready var health_label: Label = %HealthLabel
@onready var hp_regen_label: Label = %HPRegenLabel
@onready var life_steal_label: Label = %LifeStealLabel
@onready var luck_label: Label = %LuckLabel
@onready var speed_label: Label = %SpeedLabel
@onready var attack_speed_label: Label = %AttackSpeedLabel
@onready var crit_chance_label: Label = %CritChanceLabel
@onready var pierce_label: Label = %PierceLabel
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
@onready var stats_crit_chance_panel: Panel = $MarginContainer/VBoxContainer/StatsCritChance
@onready var stats_pierce_panel: Panel = $MarginContainer/VBoxContainer/StatsPierce
@onready var stats_block_panel: Panel = $MarginContainer/VBoxContainer/StatsBlock
@onready var stats_harvesting_panel: Panel = $MarginContainer/VBoxContainer/StatsHarvesting
@onready var stats_max_weapons_panel: Panel = $MarginContainer/VBoxContainer/StatsMaxWeapons
@onready var stats_range_panel: Panel = $MarginContainer/VBoxContainer/StatsRange
@onready var stats_pickup_range_panel: Panel = $MarginContainer/VBoxContainer/StatsPickupRange
@onready var margin_container: MarginContainer = $MarginContainer
@onready var stats_vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var page_selector: HBoxContainer = $MarginContainer/VBoxContainer/PageSelector

var stat_panels: Array[Panel] = []

func _ready() -> void:
	_setup_stat_tooltips()
	_setup_stats_scroll()

func _process(_delta: float) -> void:
	if not is_instance_valid(Global.player):
		return

	var raw_health := int(round(Global.player.stats.health))
	var eff_health: int = maxi(1, raw_health)
	health_label.text = _format_stat_with_effective(float(raw_health), float(eff_health), false, true)

	var raw_hp_regen := float(Global.player.stats.hp_regen)
	var eff_hp_regen: float = maxf(0.0, raw_hp_regen)
	hp_regen_label.text = _format_stat_with_effective(raw_hp_regen, eff_hp_regen)

	var raw_life_steal := float(Global.player.stats.life_steal)
	var eff_life_steal: float = maxf(0.0, raw_life_steal)
	life_steal_label.text = _format_stat_with_effective(raw_life_steal, eff_life_steal, true)

	var raw_damage := int(round(Global.player.stats.damage))
	damage_label.text = str(raw_damage)

	var raw_pierce := int(round(Global.player.stats.pierce))
	var eff_pierce: int = maxi(0, raw_pierce)
	pierce_label.text = _format_stat_with_effective(float(raw_pierce), float(eff_pierce), false, true)

	var raw_range := float(Global.player.stats.range)
	range_label.text = _format_compact_number(raw_range)

	var raw_luck := float(Global.player.stats.luck)
	luck_label.text = _format_compact_number(raw_luck)

	var raw_speed := float(Global.player.stats.speed)
	speed_label.text = _format_compact_number(raw_speed)

	var raw_attack_speed_percent := float(Global.player.stats.attack_speed) * 100.0
	var eff_attack_speed_percent: float = maxf(10.0, raw_attack_speed_percent)
	attack_speed_label.text = _format_stat_with_effective(raw_attack_speed_percent, eff_attack_speed_percent, true)

	var raw_crit_chance := float(Global.player.stats.crit_chance)
	var eff_crit_chance: float = maxf(0.0, raw_crit_chance)
	crit_chance_label.text = _format_stat_with_effective(raw_crit_chance, eff_crit_chance, true)

	var raw_pickup_range := float(Global.player.stats.pickup_range)
	var eff_pickup_range: float = maxf(0.1, raw_pickup_range)
	pickup_range_label.text = _format_stat_with_effective(raw_pickup_range, eff_pickup_range)

	var raw_block := float(Global.player.stats.block_chance)
	var eff_block: float = maxf(0.0, raw_block)
	block_label.text = _format_stat_with_effective(raw_block, eff_block, true)

	var raw_harvesting := float(Global.player.stats.harvesting)
	harvesting_label.text = _format_compact_number(raw_harvesting)

	var raw_max_weapons := int(round(Global.player.stats.max_weapons))
	var eff_max_weapons: int = maxi(2, raw_max_weapons)
	if raw_max_weapons == eff_max_weapons:
		max_weapons_label.text = "%d/%d" % [Global.player.current_weapons.size(), eff_max_weapons]
	else:
		max_weapons_label.text = "%d/%d (%d)" % [Global.player.current_weapons.size(), raw_max_weapons, eff_max_weapons]


func _setup_stats_scroll() -> void:
	stat_panels = [
		stats_health_panel,
		stats_hp_regen_panel,
		stats_life_steal_panel,
		stats_block_panel,
		stats_damage_panel,
		stats_pierce_panel,
		stats_attack_speed_panel,
		stats_crit_chance_panel,
		stats_range_panel,
		stats_speed_panel,
		stats_pickup_range_panel,
		stats_harvesting_panel,
		stats_max_weapons_panel,
		stats_luck_panel,
	]

	for panel: Panel in stat_panels:
		panel.visible = true

	if is_instance_valid(page_selector):
		page_selector.visible = false
		page_selector.queue_free()

	if stats_vbox.get_parent() == margin_container:
		var scroll_container: ScrollContainer = ScrollContainer.new()
		scroll_container.name = "StatsScrollContainer"
		scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin_container.add_child(scroll_container)
		margin_container.move_child(scroll_container, 0)
		stats_vbox.reparent(scroll_container)

		var v_scroll_bar: VScrollBar = scroll_container.get_v_scroll_bar()
		if v_scroll_bar != null:
			v_scroll_bar.custom_minimum_size.x = 14.0

	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _setup_stat_tooltips() -> void:
	_set_tooltip_for_stat(stats_health_panel, "Max HP. Increases how much damage you can take before dying.")
	_set_tooltip_for_stat(stats_hp_regen_panel, "HP Regen. Amount of health restored over time.")
	_set_tooltip_for_stat(stats_life_steal_panel, "Life Steal. Chance to heal when your attacks hit.")
	_set_tooltip_for_stat(stats_damage_panel, "Damage. Added to your weapons to increase hit damage.")
	_set_tooltip_for_stat(stats_pierce_panel, "Pierce. Adds extra enemies your ranged attacks can pass through.")
	_set_tooltip_for_stat(stats_range_panel, "Range. Flat bonus added to your weapons' range.")
	_set_tooltip_for_stat(stats_luck_panel, "Luck. Improves odds for better upgrade and item choices.")
	_set_tooltip_for_stat(stats_speed_panel, "Speed. Increases movement speed.")
	_set_tooltip_for_stat(stats_attack_speed_panel, "Attack Speed. Increases attack frequency. 100% is base speed.")
	_set_tooltip_for_stat(stats_crit_chance_panel, "Crit Chance. Added to your weapons' critical hit chance.")
	_set_tooltip_for_stat(stats_pickup_range_panel, "Pickup Range. Multiplier for how far away you can collect drops.")
	_set_tooltip_for_stat(stats_block_panel, "Block. Chance to negate incoming damage.")
	_set_tooltip_for_stat(stats_harvesting_panel, "Harvesting. Extra coins gained at the end of each wave.")
	_set_tooltip_for_stat(stats_max_weapons_panel, "Max Weapons. Maximum number of weapons you can equip at once.")


func _get_max_weapon_range() -> float:
	if not is_instance_valid(Global.player):
		return 0.0

	var max_range := 0.0
	var range_bonus: float = float(Global.player.stats.range)
	for weapon in Global.player.current_weapons:
		if weapon and weapon.data and weapon.data.stats:
			max_range = max(max_range, weapon.data.stats.max_range + range_bonus)

	return max_range

func _set_tooltip_for_stat(panel: Control, description: String) -> void:
	panel.tooltip_text = description


func _format_compact_number(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))

	return str(snappedf(value, 0.1))


func _format_stat_with_effective(raw_value: float, effective_value: float, is_percent := false, as_int := false) -> String:
	var suffix := "%" if is_percent else ""
	var raw_text := _format_number_for_stat(raw_value, as_int)
	var effective_text := _format_number_for_stat(effective_value, as_int)

	if is_equal_approx(raw_value, effective_value):
		return "%s%s" % [raw_text, suffix]

	return "%s%s (%s%s)" % [raw_text, suffix, effective_text, suffix]


func _format_number_for_stat(value: float, as_int := false) -> String:
	if as_int:
		return str(int(round(value)))
	return _format_compact_number(value)
