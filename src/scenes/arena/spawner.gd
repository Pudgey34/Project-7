extends Node2D

class_name Spawner

signal on_wave_completed

@export var spawn_area_size := Vector2(1000,500)
@export var waves_data: Array[WaveData]
@export var enemy_collection: Array[UnitStats]
@export var post_wave_multiplier_start_wave: int = 5
@export_range(0.0, 1.0, 0.01) var post_wave_health_multiplier_step: float = 0.10
@export_range(0.0, 1.0, 0.01) var post_wave_damage_multiplier_step: float = 0.10

@onready var wave_timer: Timer = $WaveTimer
@onready var spawn_timer: Timer = $SpawnTimer

var wave_index := 1

var current_wave_data: WaveData
var spawned_enemies: Array[Enemy] = []
var is_wave_active := false

func find_wave_data() -> WaveData:
	var best_wave: WaveData = null
	var best_from := -999999
	var best_span := 999999

	for wave in waves_data:
		if wave == null or not wave.is_valid_index(wave_index):
			continue

		var span: int = max(0, wave.to - wave.from)
		if best_wave == null or wave.from > best_from or (wave.from == best_from and span < best_span):
			best_wave = wave
			best_from = wave.from
			best_span = span

	return best_wave
	
func start_wave() -> void:
	current_wave_data = find_wave_data()
	if not current_wave_data:
		is_wave_active = false
		spawn_timer.stop()
		wave_timer.stop()
		return
	is_wave_active = true
	wave_timer.wait_time = current_wave_data.wave_time
	wave_timer.start()
	
	spawn_opening_units()
	set_spawn_timer()
	
	
func update_enemies_new_wave() -> void:
	for stat: UnitStats in enemy_collection:
		stat.health += stat.health_increase_per_wave
		stat.damage += stat.damage_increase_per_wave
		stat.speed += stat.speed_increase_per_wave

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
	var enemy_scene: PackedScene = current_wave_data.get_random_unit_scene()
	if not enemy_scene:
		return
	spawn_enemy_from_scene(enemy_scene)

func spawn_enemy_from_scene(enemy_scene: PackedScene) -> void:
	if not enemy_scene:
		return
	var spawn_pos := get_random_spawn_position()
	var spawn_anim := Global.SPAWN_EFFECT_SCENE.instantiate()
	get_parent().add_child(spawn_anim)
	spawn_anim.global_position = spawn_pos
	var spawn_wave_index := wave_index

	if spawn_anim.anim_player and not spawn_anim.anim_player.animation_finished.is_connected(_on_spawn_effect_finished):
		spawn_anim.anim_player.animation_finished.connect(_on_spawn_effect_finished.bind(spawn_anim, enemy_scene, spawn_pos, spawn_wave_index), CONNECT_ONE_SHOT)

func spawn_opening_units() -> void:
	if not is_wave_active or not current_wave_data:
		return

	if current_wave_data.opening_units.is_empty():
		return

	for opening_scene: PackedScene in current_wave_data.opening_units:
		if opening_scene == null:
			continue
		spawn_enemy_from_scene(opening_scene)


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
	_apply_post_wave_enemy_multipliers(enemy_instance, spawn_wave_index)
	enemy_instance.global_position = spawn_pos
	get_parent().add_child(enemy_instance)
	spawned_enemies.append(enemy_instance)


func _apply_post_wave_enemy_multipliers(enemy_instance: Enemy, spawn_wave_index: int) -> void:
	if enemy_instance == null or enemy_instance.stats == null:
		return

	var health_multiplier: float = _get_post_wave_multiplier(spawn_wave_index, post_wave_health_multiplier_step)
	var damage_multiplier: float = _get_post_wave_multiplier(spawn_wave_index, post_wave_damage_multiplier_step)
	if is_equal_approx(health_multiplier, 1.0) and is_equal_approx(damage_multiplier, 1.0):
		return

	var instance_stats: UnitStats = enemy_instance.stats.duplicate()
	instance_stats.health = maxi(1, int(round(float(instance_stats.health) * health_multiplier)))
	instance_stats.damage = float(instance_stats.damage) * damage_multiplier
	enemy_instance.stats = instance_stats


func _get_post_wave_multiplier(spawn_wave_index: int, per_wave_step: float) -> float:
	if per_wave_step <= 0.0:
		return 1.0
	if spawn_wave_index < post_wave_multiplier_start_wave:
		return 1.0

	var scaled_waves: int = spawn_wave_index - post_wave_multiplier_start_wave + 1
	return pow(1.0 + per_wave_step, float(scaled_waves))

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
	
