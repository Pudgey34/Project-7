extends Control

class_name DashIndicator

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var cooldown_label: Label = $CooldownLabel

func _ready() -> void:
	# Style the vertical progress bar to match the health bar
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color(0.13725491, 0.019607844, 0.02745098, 1)
	back_style.corner_radius_top_left = 8
	back_style.corner_radius_top_right = 8
	back_style.corner_radius_bottom_left = 8
	back_style.corner_radius_bottom_right = 8
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.3, 0.8, 1.0, 1.0)  # Cyan color
	fill_style.border_width_left = 3
	fill_style.border_width_top = 3
	fill_style.border_width_right = 3
	fill_style.border_width_bottom = 3
	fill_style.border_color = Color(0.13725491, 0.019607844, 0.02745098, 1)
	fill_style.border_blend = true
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_left = 8
	fill_style.corner_radius_bottom_right = 8
	
	progress_bar.add_theme_stylebox_override("background", back_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	progress_bar.max_value = 1.0
	progress_bar.value = 1.0

func _process(delta: float) -> void:
	if not is_instance_valid(Global.player):
		return
	
	var player: Player = Global.player
	
	# Check if dash is available
	if player.dash_cooldown_timer.is_stopped():
		cooldown_label.text = ""
		progress_bar.value = 1.0
	else:
		# Calculate progress (inverted so it fills up)
		var time_left = player.dash_cooldown_timer.time_left
		var progress = 1.0 - (time_left / player.dash_cooldown)
		progress_bar.value = progress
		cooldown_label.text = "%.1f" % time_left
