extends Area2D

class_name Coins

@export var move_speed := 1000.0
@export var collect_distance := 15.0

var value := 1
var target_screen_pos := Vector2.INF
var target_pos: Vector2 
var collected := false
var picked_up_by_player := false

func _process(delta: float) -> void:
	if collected and target_screen_pos == Vector2.INF:
		if is_instance_valid(Global.player):
			target_pos = Global.player.global_position
	
	if target_screen_pos != Vector2.INF:
		target_pos = get_canvas_transform().affine_inverse() * target_screen_pos
		
	if target_pos != Vector2.ZERO:
		global_position = global_position.move_toward(target_pos, move_speed * delta)
		
	if global_position.distance_to(target_pos) < collect_distance:
		add_coins()
		
func add_coins() -> void:
	var coins_to_add: int = value
	if picked_up_by_player:
		coins_to_add += 1
		_heal_player_from_pickup()
	Global.coins += coins_to_add
	SoundManager.play_sound(SoundManager.Sound.COIN)
	queue_free()

func set_collection_target(screen_pos: Vector2) -> void:
	target_screen_pos = screen_pos
	

func _on_area_entered(area: Area2D) -> void:
	if (area.collision_layer & 64) == 0:
		return

	picked_up_by_player = true
	collected = true


func _heal_player_from_pickup() -> void:
	var player: Player = Global.player
	if not is_instance_valid(player):
		return
	if player.health_component.current_health <= 0:
		return

	player.health_component.heal(1.0)
	Global.on_create_heal_text.emit(player, 1.0)
