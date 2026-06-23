extends Control

@onready var floor_label: Label = $CenterContainer/VBoxContainer/FloorLabel
@onready var kills_label: Label = $CenterContainer/VBoxContainer/KillsLabel
@onready var rooms_label: Label = $CenterContainer/VBoxContainer/RoomsLabel
@onready var time_label: Label = $CenterContainer/VBoxContainer/TimeLabel
@onready var currency_label: Label = $CenterContainer/VBoxContainer/CurrencyLabel
@onready var retry_button: Button = $CenterContainer/VBoxContainer/RetryButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton

func _ready() -> void:
	var summary = RunManager.get_run_summary()
	floor_label.text = "到达楼层: %d" % summary["floor"]
	kills_label.text = "击杀: %d" % summary["kills"]
	rooms_label.text = "清理房间: %d" % summary["rooms"]

	var mins = int(summary["time"]) / 60
	var secs = int(summary["time"]) % 60
	time_label.text = "存活时间: %02d:%02d" % [mins, secs]

	currency_label.text = "获得货币: %d" % int(summary["floor"] * 10 + summary["kills"] * 2 + summary["rooms"] * 3)

	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_retry_pressed() -> void:
	RunManager.reset()
	GameManager.start_run()

func _on_menu_pressed() -> void:
	GameManager.return_to_menu()
