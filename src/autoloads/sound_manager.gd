extends Node

enum Sound {
	ENEMY_HIT,
	FIRE,
	UI,
	COIN,
	PURCHASE,
	ERROR,
	DASH,
	SELL,
	SATISFYING,
	PUNCH,
	SWORD,
	DEATH,
	PLAYER_FIRE,
	PISTOL_FIRE,
	LASER_FIRE,
	CLEAVE,
	CHARGE_HORN
}

const ENEMY_HIT_MAX_CONCURRENT: int = 2
const ENEMY_HIT_MIN_INTERVAL_SEC: float = 0.04
const PRIORITY_SOUNDS: Array[int] = [Sound.FIRE, Sound.CHARGE_HORN]
const PREEMPTIBLE_SOUNDS: Array[int] = [
	Sound.ENEMY_HIT,
	Sound.COIN,
	Sound.UI,
	Sound.PURCHASE,
	Sound.ERROR,
	Sound.SELL,
	Sound.SATISFYING
]

var sound_dictionary: Dictionary[Sound, Resource] = {
	Sound.ENEMY_HIT: preload("uid://blonjlaa37md0"),
	Sound.FIRE: preload("res://assets/audio/enemygun.mp3"),
	Sound.UI: preload("uid://6nolwqlami52"),
	Sound.COIN: preload("res://assets/audio/coin.mp3"),
	Sound.PURCHASE: preload("res://assets/audio/purchase.mp3"),
	Sound.ERROR: preload("res://assets/audio/error.mp3"),
	Sound.DASH: preload("res://assets/audio/dash.mp3"),
	Sound.SELL: preload("res://assets/audio/sell.mp3"),
	Sound.SATISFYING: preload("res://assets/audio/satisfying.mp3"),
	Sound.PUNCH: preload("uid://cucccrglm402c"),
	Sound.SWORD: preload("uid://bfbq5a1jaqovo"),
	Sound.DEATH: preload("res://assets/audio/death.mp3"),
	Sound.PLAYER_FIRE: preload("res://assets/audio/ShotgunFire.wav"),
	Sound.PISTOL_FIRE: preload("res://assets/audio/shot.mp3"),
	Sound.LASER_FIRE: preload("res://assets/audio/laser.mp3"),
	Sound.CLEAVE: preload("res://assets/audio/cleave.mp3"),
	Sound.CHARGE_HORN: preload("res://assets/audio/horn.mp3")
}

@export var stream_players: Array[AudioStreamPlayer]
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var current_music: AudioStream
var _last_enemy_hit_impact_sec: float = -1000.0
var _stream_sound_type_by_id: Dictionary = {}

func play_enemy_hit_impact() -> void:
	var now_sec: float = float(Time.get_ticks_msec()) / 1000.0
	if now_sec - _last_enemy_hit_impact_sec < ENEMY_HIT_MIN_INTERVAL_SEC:
		return

	if _get_active_sound_count(Sound.ENEMY_HIT) >= ENEMY_HIT_MAX_CONCURRENT:
		return

	_last_enemy_hit_impact_sec = now_sec
	play_sound(Sound.ENEMY_HIT)

func play_sound(type: int, randomize_pitch: bool = true, pitch_override: float = -1.0, volume_db_override: float = 0.0) -> void:
	if not sound_dictionary.has(type):
		return

	var stream: AudioStreamPlayer = _get_stream_for_sound(type)
	if not stream:
		return
	
	var audio: Resource = sound_dictionary[type] as Resource
	if audio == null:
		return

	_stream_sound_type_by_id[stream.get_instance_id()] = type
	stream.stream = audio
	stream.volume_db = volume_db_override
	if pitch_override > 0.0:
		stream.pitch_scale = pitch_override
	elif randomize_pitch:
		stream.pitch_scale = randf_range(0.8, 1.3)
	else:
		stream.pitch_scale = 1.0
	stream.play()


func play_music(stream: AudioStream, restart: bool = false, volume_db: float = -30.0) -> void:
	if stream == null:
		return

	if not restart and music_player.playing and current_music == stream:
		return

	current_music = stream
	music_player.volume_db = volume_db
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	current_music = null
	music_player.stop()
		

func _get_active_sound_count(type: int) -> int:
	var playing_count: int = 0
	for stream: AudioStreamPlayer in stream_players:
		if stream == null or not is_instance_valid(stream):
			continue
		if not stream.playing:
			continue

		var stream_type_variant: Variant = _stream_sound_type_by_id.get(stream.get_instance_id(), -1)
		var stream_type: int = int(stream_type_variant)
		if stream_type == type:
			playing_count += 1

	return playing_count


func get_free_stream_player() -> AudioStreamPlayer:
	for stream: AudioStreamPlayer in stream_players:
		if not stream.playing:
			return stream
			
			
	return null


func _get_stream_for_sound(type: int) -> AudioStreamPlayer:
	var free_stream: AudioStreamPlayer = get_free_stream_player()
	if free_stream != null:
		return free_stream

	if not _is_priority_sound(type):
		return null

	var preempt_stream: AudioStreamPlayer = _find_preemptible_stream()
	if preempt_stream != null:
		return preempt_stream

	var same_sound_stream: AudioStreamPlayer = _find_stream_playing_type(type)
	if same_sound_stream != null:
		return same_sound_stream

	return _find_any_playing_stream()


func _is_priority_sound(type: int) -> bool:
	return type in PRIORITY_SOUNDS


func _find_preemptible_stream() -> AudioStreamPlayer:
	for sound_type: int in PREEMPTIBLE_SOUNDS:
		var stream: AudioStreamPlayer = _find_stream_playing_type(sound_type)
		if stream != null:
			return stream
	return null


func _find_stream_playing_type(type: int) -> AudioStreamPlayer:
	for stream: AudioStreamPlayer in stream_players:
		if stream == null or not is_instance_valid(stream):
			continue
		if not stream.playing:
			continue

		var stream_type_variant: Variant = _stream_sound_type_by_id.get(stream.get_instance_id(), -1)
		var stream_type: int = int(stream_type_variant)
		if stream_type == type:
			return stream

	return null


func _find_any_playing_stream() -> AudioStreamPlayer:
	for stream: AudioStreamPlayer in stream_players:
		if stream == null or not is_instance_valid(stream):
			continue
		if stream.playing:
			return stream

	return null
