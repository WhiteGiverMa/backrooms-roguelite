extends Node2D
class_name LevelGenerator

@export var room_templates: Array[PackedScene] = []
@export var corridor_template: PackedScene
@export var rooms_per_floor: int = 8
@export var room_size: Vector2 = Vector2(640, 480)
@export var corridor_width: int = 160

var generated_rooms: Array[Room] = []
var room_positions: Array[Vector2] = []
var spawn_room: Room = null
var exit_room: Room = null

func _ready() -> void:
	generate_floor()

func generate_floor() -> void:
	_clear_floor()
	_generate_room_layout()
	_place_rooms()
	_connect_rooms()
	_place_player()
	_place_enemies_and_items()

func _clear_floor() -> void:
	for room in generated_rooms:
		if is_instance_valid(room):
			room.queue_free()
	generated_rooms.clear()
	room_positions.clear()
	spawn_room = null
	exit_room = null

func _generate_room_layout() -> void:
	var grid: Dictionary = {}
	var start = Vector2i.ZERO
	grid[start] = true
	room_positions.append(Vector2(start) * room_size)

	var frontier: Array[Vector2i] = [start]
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

	for i in range(rooms_per_floor - 1):
		if frontier.is_empty():
			break

		var idx = randi() % frontier.size()
		var current = frontier[idx]

		var valid_dirs: Array[Vector2i] = []
		for dir in directions:
			var neighbor = current + dir
			if not grid.has(neighbor):
				valid_dirs.append(dir)

		if valid_dirs.is_empty():
			frontier.remove_at(idx)
			continue

		var chosen_dir = valid_dirs[randi() % valid_dirs.size()]
		var new_pos = current + chosen_dir
		grid[new_pos] = true
		room_positions.append(Vector2(new_pos) * room_size)
		frontier.append(new_pos)

		if frontier.size() > 1 and randf() < 0.3:
			frontier.remove_at(idx)

func _place_rooms() -> void:
	for i in room_positions.size():
		var template = room_templates[randi() % room_templates.size()]
		var room = template.instantiate()
		add_child(room)
		room.global_position = room_positions[i]
		room.room_id = i
		generated_rooms.append(room)

	spawn_room = generated_rooms[0]
	exit_room = generated_rooms[generated_rooms.size() - 1]
	exit_room.is_exit = true

func _connect_rooms() -> void:
	for i in generated_rooms.size():
		for j in range(i + 1, generated_rooms.size()):
			var a = generated_rooms[i]
			var b = generated_rooms[j]
			var dist = a.global_position.distance_to(b.global_position)
			var expected_dist = room_size.length() * 0.8

			if dist < room_size.x * 1.5:
				a.add_connection(b)
				b.add_connection(a)

func _place_player() -> void:
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and spawn_room:
		player_node.global_position = spawn_room.global_position + Vector2(0, -50)

func _place_enemies_and_items() -> void:
	var enemy_spawner = get_node_or_null("EnemySpawner")
	if enemy_spawner:
		enemy_spawner.spawn_enemies(generated_rooms)

	var item_spawner = get_node_or_null("ItemSpawner")
	if item_spawner:
		item_spawner.spawn_items(generated_rooms)
