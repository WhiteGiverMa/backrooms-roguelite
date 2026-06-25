## SettingsScreen — 设置界面。
## 主音量 / 音效音量 / 音乐音量滑块；开发者模式 checkbox；
## 开发者模式开启时显示「移除战争迷雾」checkbox；返回按钮。
extends Control

@onready var master_slider: HSlider = $MarginContainer/VBoxContainer/MasterRow/MasterSlider
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/SfxRow/SfxSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/MusicRow/MusicSlider
@onready var dev_mode_check: CheckBox = $MarginContainer/VBoxContainer/DevModeCheck
@onready var disable_fog_check: CheckBox = $MarginContainer/VBoxContainer/DisableFogCheck
@onready var disable_fog_label: Label = $MarginContainer/VBoxContainer/DisableFogLabel
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	# 音量滑块：0~100，映射到 0.0~1.0
	master_slider.value = Settings.master_volume * 100.0
	sfx_slider.value = Settings.sfx_volume * 100.0
	music_slider.value = Settings.music_volume * 100.0
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)

	# 开发者模式
	dev_mode_check.button_pressed = Settings.dev_mode
	dev_mode_check.toggled.connect(_on_dev_mode_toggled)

	# 移除战争迷雾
	disable_fog_check.button_pressed = Settings.disable_fog
	disable_fog_check.toggled.connect(_on_disable_fog_toggled)

	# 监听 dev_mode 变化以联动显示
	Settings.dev_mode_changed.connect(_on_dev_mode_changed)
	# 监听 disable_fog 变化以同步 checkbox（开发者模式关闭时会联动关闭 fog）
	Settings.disable_fog_changed.connect(_on_disable_fog_changed)
	_update_fog_visibility()

	back_button.pressed.connect(_on_back_pressed)


# ===== 音量 =====

func _on_master_changed(value: float) -> void:
	Settings.master_volume = value / 100.0

func _on_sfx_changed(value: float) -> void:
	Settings.sfx_volume = value / 100.0

func _on_music_changed(value: float) -> void:
	Settings.music_volume = value / 100.0


# ===== 开发者模式 =====

func _on_dev_mode_toggled(pressed: bool) -> void:
	Settings.dev_mode = pressed

func _on_dev_mode_changed(enabled: bool) -> void:
	_update_fog_visibility()


# ===== 移除战争迷雾 =====

func _on_disable_fog_toggled(pressed: bool) -> void:
	Settings.disable_fog = pressed

func _on_disable_fog_changed(enabled: bool) -> void:
	# 同步 checkbox 显示状态（Settings 联动关闭时会触发）
	if disable_fog_check.button_pressed != enabled:
		disable_fog_check.button_pressed = enabled

func _update_fog_visibility() -> void:
	var show_fog: bool = Settings.dev_mode
	disable_fog_check.visible = show_fog
	disable_fog_label.visible = show_fog


# ===== 返回 =====

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
