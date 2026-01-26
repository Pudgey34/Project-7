extends Unit
class_name Player

var move_dir: Vector2

# MOVEMENT
func _process(delta: float) -> void:
	move_dir = Input.get_vector("move_left","move_right","move_up","move_down")
	
	var current_velocity := move_dir * 500
	position += current_velocity * delta
	update_animations()
	update_rotation()
	
	
# ANIMATE IF IDLE OR MOVING
func update_animations() -> void:
	if move_dir.length() > 0:
		anim_player.play("move")
	else:
		anim_player.play("idle")

# ADJUST FACING DIRECTION LEFT OR RIGHT IF MOVING LEFT OR RIGHT
func update_rotation() -> void:
	if move_dir == Vector2.ZERO:
		return
		
	if move_dir.x >= 0.1:
		visuals.scale = Vector2(-0.5,0.5)
	else:
		visuals.scale = Vector2(0.5,0.5)
