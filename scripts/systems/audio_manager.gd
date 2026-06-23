extends Node

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_pool_size: int = 8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music"
	for i in sfx_pool_size:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)

func play_music(stream: AudioStream) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_sfx(stream: AudioStream, pitch_variation: float = 0.1) -> void:
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
			p.play()
			return
	var p = sfx_players[0]
	p.stream = stream
	p.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	p.play()

func set_master_volume(value: float) -> void:
	master_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func set_sfx_volume(value: float) -> void:
	sfx_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func set_music_volume(value: float) -> void:
	music_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
