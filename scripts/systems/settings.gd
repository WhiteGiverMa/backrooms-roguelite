## Settings — 全局设置 autoload。
## 持久化开发者模式、战争迷雾开关、音量到 user://settings.json。
## _ready 时加载并应用到 AudioManager。
extends Node

const SAVE_PATH: String = "user://settings.json"

# ===== 设置项（带信号，UI 可监听变化）=====

signal dev_mode_changed(enabled: bool)
signal disable_fog_changed(enabled: bool)

## 开发者模式。开启后才能用反引号键呼出控制台，设置界面才会显示开发者选项。
## 关闭时联动关闭「移除战争迷雾」（该选项依赖开发者模式）。
var dev_mode: bool = false:
	set(value):
		if dev_mode == value:
			return
		dev_mode = value
		dev_mode_changed.emit(value)
		# 联动：关闭开发者模式时强制关闭移除战争迷雾
		if not value and disable_fog:
			disable_fog = false
		save()

## 移除战争迷雾。仅开发者模式开启时可设置。进入关卡时若为 true，迷雾初始关闭。
## 控制台 /fog 命令仍可在游戏中重新打开迷雾。
var disable_fog: bool = false:
	set(value):
		if disable_fog == value:
			return
		disable_fog = value
		disable_fog_changed.emit(value)
		save()

# ===== 音量（0.0 ~ 1.0）=====

var master_volume: float = 1.0:
	set(value):
		master_volume = clamp(value, 0.0, 1.0)
		AudioManager.set_master_volume(master_volume)
		save()

var sfx_volume: float = 1.0:
	set(value):
		sfx_volume = clamp(value, 0.0, 1.0)
		AudioManager.set_sfx_volume(sfx_volume)
		save()

var music_volume: float = 1.0:
	set(value):
		music_volume = clamp(value, 0.0, 1.0)
		AudioManager.set_music_volume(music_volume)
		save()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	# 启动时应用音量到音频总线
	AudioManager.set_master_volume(master_volume)
	AudioManager.set_sfx_volume(sfx_volume)
	AudioManager.set_music_volume(music_volume)


# ===== 持久化 =====

func save() -> void:
	var data := {
		"dev_mode": dev_mode,
		"disable_fog": disable_fog,
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Settings: 无法写入 %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(data))

func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not data is Dictionary:
		return
	# 用 set 走 setter（但不触发 save 避免循环写入；这里直接赋字段绕过 setter 的 save）
	# 注意：直接赋字段不会触发信号，但 _ready 时 UI 还没建好，无需信号
	if data.has("dev_mode"):
		dev_mode = bool(data["dev_mode"])
	if data.has("disable_fog"):
		disable_fog = bool(data["disable_fog"])
	if data.has("master_volume"):
		master_volume = float(data["master_volume"])
	if data.has("sfx_volume"):
		sfx_volume = float(data["sfx_volume"])
	if data.has("music_volume"):
		music_volume = float(data["music_volume"])
