extends Node

@export var health_pickup: PackedScene
@export var ammo_pickups: Array[PackedScene] = []
@export var sanity_pickup: PackedScene
@export var weapon_pickups: Array[PackedScene] = []
@export var currency_pickup: PackedScene


func spawn_items(rooms: Array[Room]) -> void:
	clear_items()
	spawn_items_in_rooms(rooms, true)


func spawn_items_in_rooms(rooms: Array[Room], skip_start_room: bool = false) -> void:
	for i in range(rooms.size()):
		var room = rooms[i]
		if skip_start_room and room.global_position == Vector2.ZERO:
			continue

		var spawn_points = room.get_spawn_points()
		if spawn_points.is_empty():
			continue

		var roll = randf()

		if roll < 0.3 and health_pickup:
			var item = health_pickup.instantiate()
			item.global_position = spawn_points[randi() % spawn_points.size()].global_position
			add_child(item)
			room.items.append(item)

		elif roll < 0.5 and not ammo_pickups.is_empty():
			var item = ammo_pickups[randi() % ammo_pickups.size()].instantiate()
			item.global_position = spawn_points[randi() % spawn_points.size()].global_position
			add_child(item)
			room.items.append(item)

		elif roll < 0.6 and sanity_pickup:
			var item = sanity_pickup.instantiate()
			item.global_position = spawn_points[randi() % spawn_points.size()].global_position
			add_child(item)
			room.items.append(item)

		elif roll < 0.7 and not weapon_pickups.is_empty():
			var item = weapon_pickups[randi() % weapon_pickups.size()].instantiate()
			item.global_position = spawn_points[randi() % spawn_points.size()].global_position
			add_child(item)
			room.items.append(item)

		if randf() < 0.2 and currency_pickup:
			var item = currency_pickup.instantiate()
			item.global_position = spawn_points[randi() % spawn_points.size()].global_position
			add_child(item)
			room.items.append(item)


func clear_items() -> void:
	for child in get_children():
		if child is Node2D:
			child.queue_free()
