extends Projectile

class_name FlingProjectile

@export var spin_speed_radians := 18.0

func _process(delta: float) -> void:
	if Global.game_paused:
		return

	super._process(delta)
	rotation += spin_speed_radians * delta
