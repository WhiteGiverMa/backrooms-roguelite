extends Node

@export var health_pickup: PackedScene
@export var ammo_pickup: PackedScene
@export var sanity_pickup: PackedScene
@export var weapon_pickups: Array[PackedScene] = []
@export var currency_pickup: PackedScene

func spawn_items(rooms: Array[Room]) -> void:
	for i in range(rooms.size()):
		var room = rooms[i]
		if i == 0:
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

		elif roll < 0.5 and ammo_pickup:
			var item = ammo_pickup.instantiate()
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
