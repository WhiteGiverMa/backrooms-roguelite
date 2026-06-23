extends Node

signal game_paused
signal game_resumed
signal player_died
signal run_started
signal run_ended

enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.MAIN_MENU

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_run() -> void:
	current_state = GameState.PLAYING
	run_started.emit()
	get_tree().change_scene_to_file("res://scenes/levels/game_level.tscn")

func pause_game() -> void:
	if current_state != GameState.PLAYING:
		return
	current_state = GameState.PAUSED
	get_tree().paused = true
	game_paused.emit()

func resume_game() -> void:
	if current_state != GameState.PAUSED:
		return
	current_state = GameState.PLAYING
	get_tree().paused = false
	game_resumed.emit()

func game_over() -> void:
	current_state = GameState.GAME_OVER
	player_died.emit()
	MetaProgression.add_run_reward()
	await get_tree().create_timer(2.0).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

func return_to_menu() -> void:
	current_state = GameState.MAIN_MENU
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
