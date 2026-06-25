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
	_apply_bus_volume("Master", value)

func set_sfx_volume(value: float) -> void:
	sfx_volume = value
	_apply_bus_volume("SFX", value)

func set_music_volume(value: float) -> void:
	music_volume = value
	_apply_bus_volume("Music", value)

## 安全设置 bus 音量：bus 不存在时静默跳过（草稿项目可能未配置 SFX/Music bus）。
func _apply_bus_volume(bus_name: String, linear_value: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear_value))
