extends Node2D

class_name Spawner

signal on_wave_completed

@export var spawn_area_size := Vector2(1000,500)
@export var waves_data: Array[WaveData]
@export var enemy_collection: Array[UnitStats]

@onready var wave_timer: Timer = $WaveTimer
@onready var spawn_timer: Timer = $SpawnTimer

var wave_index := 1

var current_wave_data: WaveData
var spawned_enemies: Array[Enemy] = []
var is_wave_active := false

func find_wave_data() -> WaveData:
	for wave in waves_data:
		if wave and wave.is_valid_index(wave_index):
			return wave
	return null
	
func start_wave() -> void:
	current_wave_data = find_wave_data()
	if not current_wave_data:
		printerr("No valid wave.")
		is_wave_active = false
		spawn_timer.stop()
		wave_timer.stop()
		return
	is_wave_active = true
	wave_timer.wait_time = current_wave_data.wave_time
	wave_timer.start()
	
	set_spawn_timer()
	
	
func update_enemies_new_wave() -> void:
	for stat: UnitStats in enemy_collection:
		stat.health += stat.health_increase_per_wave
		stat.damage += stat.damage_increase_per_wave

func clear_enemies() -> void:
	if spawned_enemies.size() > 0:
		for enemy: Enemy in spawned_enemies:
			if is_instance_valid(enemy):
				enemy.destroy_enemy()
	spawned_enemies.clear()
	
	
func set_spawn_timer() -> void:
	if not is_wave_active:
		return

	match current_wave_data.spawn_type:
		WaveData.SpawnType.FIXED:
			spawn_timer.wait_time = current_wave_data.fixed_spawn_time
		WaveData.SpawnType.RANDOM:
			var min_t := current_wave_data.min_spawn_time
			var max_t := current_wave_data.max_spawn_time
			spawn_timer.wait_time = randf_range(min_t, max_t)
			
	if spawn_timer.is_stopped():
		spawn_timer.start()

func get_random_spawn_position() -> Vector2:
	var random_x := randf_range(-spawn_area_size.x, spawn_area_size.x)
	var random_y := randf_range(-spawn_area_size.y, spawn_area_size.y)
	
	return Vector2(random_x, random_y)
func spawn_enemy() -> void:
	var enemy_scene := current_wave_data.get_random_unit_scene() as PackedScene
	if not enemy_scene:
		return

	var spawn_pos := get_random_spawn_position()
	var spawn_anim := Global.SPAWN_EFFECT_SCENE.instantiate()
	get_parent().add_child(spawn_anim)
	spawn_anim.global_position = spawn_pos
	var spawn_wave_index := wave_index

	if spawn_anim.anim_player and not spawn_anim.anim_player.animation_finished.is_connected(_on_spawn_effect_finished):
		spawn_anim.anim_player.animation_finished.connect(_on_spawn_effect_finished.bind(spawn_anim, enemy_scene, spawn_pos, spawn_wave_index), CONNECT_ONE_SHOT)


func _on_spawn_effect_finished(_anim_name: StringName, spawn_anim: Node, enemy_scene: PackedScene, spawn_pos: Vector2, spawn_wave_index: int) -> void:
	if is_instance_valid(spawn_anim):
		spawn_anim.queue_free()

	while Global.game_paused:
		await get_tree().process_frame

	if wave_index != spawn_wave_index:
		return

	if not is_wave_active or wave_timer.is_stopped():
		return

	var enemy_instance := enemy_scene.instantiate() as Enemy
	enemy_instance.global_position = spawn_pos
	get_parent().add_child(enemy_instance)
	spawned_enemies.append(enemy_instance)

func get_wave_text() -> String:
	return "Wave %s" % wave_index
	
func get_wave_timer_text() -> String:
	return str(max(0, int(wave_timer.time_left)))


func pause_wave_timers() -> void:
	wave_timer.paused = true
	spawn_timer.paused = true


func resume_wave_timers() -> void:
	wave_timer.paused = false
	spawn_timer.paused = false

func _on_spawn_timer_timeout() -> void:
	if not current_wave_data or wave_timer.is_stopped():
		spawn_timer.stop()
		return

	var spawn_count: int = max(1, current_wave_data.spawn_count_per_tick)
	for i in spawn_count:
		spawn_enemy()

	set_spawn_timer()


func _on_wave_timer_timeout() -> void:
	is_wave_active = false
	Global.game_paused = true
	Global.get_harvesting_coins()
	on_wave_completed.emit()
	spawn_timer.stop()
	clear_enemies()
	update_enemies_new_wave()
	
