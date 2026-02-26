extends Button

class_name SelectionCard

func _ready() -> void:
	# Get the normal style
	var normal_style := get_theme_stylebox("normal") as StyleBoxFlat
	if normal_style:
		# Create a bordered version for selected/hover/pressed states
		var bordered_style := normal_style.duplicate() as StyleBoxFlat
		bordered_style.border_width_left = 3
		bordered_style.border_width_top = 3
		bordered_style.border_width_right = 3
		bordered_style.border_width_bottom = 3
		bordered_style.border_color = Color.WHITE
		
		add_theme_stylebox_override("hover", bordered_style)
		add_theme_stylebox_override("pressed", bordered_style)
		add_theme_stylebox_override("focus", bordered_style)

func set_icon(texture: Texture2D) -> void:
	icon = texture
