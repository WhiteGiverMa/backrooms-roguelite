extends Node

@export var enemy_scenes: Array[PackedScene] = []
@export var enemies_per_floor_min: int = 2
@export var enemies_per_floor_max: int = 3

func spawn_enemies(rooms: Array[Room]) -> void:
	if RunManager.current_floor != 1:
		return

	var total = randi_range(enemies_per_floor_min, enemies_per_floor_max)
	var candidates: Array[Room] = []
	for i in range(1, rooms.size()):
		candidates.append(rooms[i])
	candidates.shuffle()

	var spawned := 0
	for room in candidates:
		if spawned >= total:
			break
		if enemy_scenes.is_empty():
			break

		var enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
		var enemy = enemy_scene.instantiate()
		var spawn_points = room.get_spawn_points()
		if spawn_points.size() > 0:
			enemy.global_position = spawn_points[randi() % spawn_points.size()].global_position
		else:
			enemy.global_position = room.global_position + Vector2(randf_range(-200, 200), randf_range(-100, 100))

		enemy.died.connect(room.check_cleared)
		enemy.z_index = 5
		add_child(enemy)
		room.enemies.append(enemy)
		spawned += 1
