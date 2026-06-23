extends Node

signal floor_changed(new_floor: int)
signal sanity_changed(new_sanity: float)
signal ammo_changed(current: int, max_ammo: int)

var current_floor: int = 1
var sanity: float = 100.0
var max_sanity: float = 100.0
var rooms_cleared: int = 0
var enemies_killed: int = 0
var time_elapsed: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		time_elapsed += delta

func next_floor() -> void:
	current_floor += 1
	floor_changed.emit(current_floor)
	rooms_cleared = 0

func modify_sanity(amount: float) -> void:
	sanity = clamp(sanity + amount, 0.0, max_sanity)
	sanity_changed.emit(sanity)
	if sanity <= 0.0:
		GameManager.game_over()

func add_kill() -> void:
	enemies_killed += 1

func add_room_cleared() -> void:
	rooms_cleared += 1

func get_run_summary() -> Dictionary:
	return {
		"floor": current_floor,
		"kills": enemies_killed,
		"rooms": rooms_cleared,
		"time": time_elapsed
	}

func reset() -> void:
	current_floor = 1
	sanity = max_sanity
	rooms_cleared = 0
	enemies_killed = 0
	time_elapsed = 0.0
