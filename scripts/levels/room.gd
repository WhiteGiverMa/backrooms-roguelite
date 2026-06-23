extends Node2D
class_name Room

@export var room_id: int = 0
@export var is_exit: bool = false
@export var connections: Array[Room] = []

var enemies: Array[Enemy] = []
var items: Array[Node2D] = []
var is_cleared: bool = false

@onready var exit_indicator: Sprite2D = $ExitIndicator

func _ready() -> void:
	if exit_indicator:
		exit_indicator.visible = is_exit

func add_connection(other: Room) -> void:
	if other in connections:
		return
	connections.append(other)

func on_player_enter() -> void:
	pass

func on_player_exit() -> void:
	pass

func check_cleared() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			return
	is_cleared = true
	RunManager.add_room_cleared()

func get_spawn_points() -> Array[Marker2D]:
	var points: Array[Marker2D] = []
	for child in get_children():
		if child is Marker2D and child.name.begins_with("SpawnPoint"):
			points.append(child)
	return points
