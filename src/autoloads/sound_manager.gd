extends Node

enum Sound {
	ENEMY_HIT,
	FIRE,
	UI,
	COIN,
	PURCHASE,
	ERROR
}

var sound_dictionary: Dictionary[Sound, Resource] = {
	Sound.ENEMY_HIT: preload("uid://blonjlaa37md0"),
	Sound.FIRE: preload("uid://g72hyxdnaath"),
	Sound.UI: preload("uid://6nolwqlami52"),
	Sound.COIN: preload("res://assets/audio/coin.mp3"),
	Sound.PURCHASE: preload("res://assets/audio/purchase.mp3"),
	Sound.ERROR: preload("res://assets/audio/error.mp3")
}

@export var stream_players: Array[AudioStreamPlayer]
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var current_music: AudioStream

func play_sound(type: int, randomize_pitch: bool = true) -> void:
	var stream := get_free_stream_player()
	if not stream:
		return
	
	var audio := sound_dictionary[type]
	stream.stream = audio
	if randomize_pitch:
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
		

func get_free_stream_player() -> AudioStreamPlayer:
	for stream: AudioStreamPlayer in stream_players:
		if not stream.playing:
			return stream
			
			
	return null
