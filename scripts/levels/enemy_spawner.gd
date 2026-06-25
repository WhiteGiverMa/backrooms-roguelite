extends Node

@export var enemy_scenes: Array[PackedScene] = []
@export var enemies_per_room_min: int = 1
@export var enemies_per_room_max: int = 3
@export var boss_scene: PackedScene

func spawn_enemies(rooms: Array[Room]) -> void:
	for i in range(rooms.size()):
		var room = rooms[i]
		if i == 0:
			continue

		var count = randi_range(enemies_per_room_min, enemies_per_room_max)
		var spawn_points = room.get_spawn_points()

		for j in count:
			if enemy_scenes.is_empty():
				break
			var enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
			var enemy = enemy_scene.instantiate()

			if spawn_points.size() > j:
				enemy.global_position = spawn_points[j].global_position
			else:
				enemy.global_position = room.global_position + Vector2(
					randf_range(-200, 200),
					randf_range(-100, 100)
				)

			enemy.died.connect(room.check_cleared)
			enemy.z_index = 5
			add_child(enemy)
			room.enemies.append(enemy)
