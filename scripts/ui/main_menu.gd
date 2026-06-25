extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var upgrades_button: Button = $CenterContainer/VBoxContainer/UpgradesButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var version_label: Label = $CenterContainer/VBoxContainer/VersionLabel

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	upgrades_button.pressed.connect(_on_upgrades_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	version_label.text = "v" + ProjectSettings.get_setting("application/config/version")

func _on_start_pressed() -> void:
	RunManager.reset()
	GameManager.start_run()

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/upgrades_screen.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
