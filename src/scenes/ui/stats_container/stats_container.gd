extends Panel

class_name StatsContainer
@onready var health_label: Label = %HealthLabel
@onready var hp_regen_label: Label = %HPRegenLabel
@onready var life_steal_label: Label = %LifeStealLabel
@onready var luck_label: Label = %LuckLabel
@onready var speed_label: Label = %SpeedLabel
@onready var block_label: Label = %BlockLabel
@onready var harvesting_label: Label = %HarvestingLabel
@onready var damage_label: Label = %DamageLabel
@onready var stats_health_panel: Panel = $MarginContainer/VBoxContainer/StatsHealth
@onready var stats_hp_regen_panel: Panel = $MarginContainer/VBoxContainer/StatsHPRegen
@onready var stats_life_steal_panel: Panel = $MarginContainer/VBoxContainer/StatsLifeSteal
@onready var stats_damage_panel: Panel = $MarginContainer/VBoxContainer/StatsDamage
@onready var stats_luck_panel: Panel = $MarginContainer/VBoxContainer/StatsLuck
@onready var stats_speed_panel: Panel = $MarginContainer/VBoxContainer/StatsSpeed
@onready var stats_block_panel: Panel = $MarginContainer/VBoxContainer/StatsBlock
@onready var stats_harvesting_panel: Panel = $MarginContainer/VBoxContainer/StatsHarvesting

func _ready() -> void:
	_setup_stat_tooltips()

func _process(_delta: float) -> void:
	if not is_instance_valid(Global.player):
		return
	
	health_label.text = str(Global.player.stats.health)
	hp_regen_label.text = str(Global.player.stats.hp_regen)
	life_steal_label.text = str(Global.player.stats.life_steal) + "%"
	damage_label.text = str(Global.player.stats.damage)
	luck_label.text = str(Global.player.stats.luck)
	speed_label.text = str(Global.player.stats.speed)
	block_label.text = str(Global.player.stats.block_chance) + "%"
	harvesting_label.text = str(Global.player.stats.harvesting)

func _setup_stat_tooltips() -> void:
	_set_tooltip_for_stat(stats_health_panel, "Max HP. Increases how much damage you can take before dying.")
	_set_tooltip_for_stat(stats_hp_regen_panel, "HP Regen. Amount of health restored over time.")
	_set_tooltip_for_stat(stats_life_steal_panel, "Life Steal. Chance to heal when your attacks hit.")
	_set_tooltip_for_stat(stats_damage_panel, "Damage. Added to your weapons to increase hit damage.")
	_set_tooltip_for_stat(stats_luck_panel, "Luck. Improves odds for better upgrade and item choices.")
	_set_tooltip_for_stat(stats_speed_panel, "Speed. Increases movement speed.")
	_set_tooltip_for_stat(stats_block_panel, "Block. Chance to negate incoming damage.")
	_set_tooltip_for_stat(stats_harvesting_panel, "Harvesting. Extra coins gained at the end of each wave.")

func _set_tooltip_for_stat(panel: Control, description: String) -> void:
	panel.tooltip_text = description
