extends Node2D
class_name LevelGenerator

@export var room_template: PackedScene
@export var portal_template: PackedScene
@export var chest_template: PackedScene
@export var generation_radius: int = 2
@export var cleanup_radius: int = 5
@export var portal_interval_min: int = 10
@export var portal_interval_max: int = 15

const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const SIZES: Array[Vector2] = [Vector2(500, 400), Vector2(650, 500), Vector2(800, 600), Vector2(950, 700)]
const COLORS: Array[Color] = [
	Color(0.12, 0.10, 0.07), Color(0.10, 0.12, 0.10),
	Color(0.14, 0.11, 0.08), Color(0.09, 0.10, 0.12),
]

var room_map: Dictionary = {}
var corridors: Array[Sprite2D] = []
var rooms_since_portal: int = 0
var portal_target: int = 0
var player_grid: Vector2i = Vector2i.ZERO

func _ready() -> void:
	generate_floor()

func _process(_delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	var player_node = get_tree().get_first_node_in_group("player")
	if not player_node: return
	var grid = _world_to_grid(player_node.global_position)
	if grid != player_grid:
		player_grid = grid
		_ensure_area_around(player_grid)
		_cleanup_distant(player_grid)

func generate_floor() -> void:
	_clear_floor()
	rooms_since_portal = 0
	portal_target = randi_range(portal_interval_min, portal_interval_max)
	player_grid = Vector2i.ZERO
	_ensure_area_around(player_grid)
	_place_player()
	_place_enemies_and_items()

func _clear_floor() -> void:
	for room in room_map.values():
		if is_instance_valid(room): room.queue_free()
	room_map.clear()
	for c in corridors:
		if is_instance_valid(c): c.queue_free()
	corridors.clear()

func _world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(roundi(pos.x / 800.0), roundi(pos.y / 600.0))

func _grid_to_world(grid: Vector2i) -> Vector2:
	return Vector2(grid) * Vector2(800, 600)

func _ensure_area_around(center: Vector2i) -> void:
	for dx in range(-generation_radius, generation_radius + 1):
		for dy in range(-generation_radius, generation_radius + 1):
			var gp = center + Vector2i(dx, dy)
			if not room_map.has(gp):
				_generate_room_at(gp)

func _generate_room_at(grid_pos: Vector2i) -> Room:
	var size = SIZES[randi() % SIZES.size()]
	var floor_col = COLORS[randi() % COLORS.size()]
	var wall_col = floor_col * 1.8

	var room = room_template.instantiate() as Room
	room.configure(size.x, size.y, floor_col, wall_col)
	room.global_position = _grid_to_world(grid_pos) + Vector2(randf_range(-80, 80), randf_range(-60, 60))
	add_child(room)
	room_map[grid_pos] = room

	if size.x >= 800 and size.y >= 600:
		room.spawn_obstacles()

	var neighbors: Array[Vector2i] = []
	for dir in DIRS:
		if room_map.has(grid_pos + dir):
			neighbors.append(dir)

	var connect_count = mini(neighbors.size(), randi_range(1, 3))
	neighbors.shuffle()
	for k in connect_count:
		var dir = neighbors[k]
		var n_pos = grid_pos + dir
		var neighbor = room_map[n_pos] as Room
		room.add_connection(neighbor)
		neighbor.add_connection(room)
		var room_dir = _vector2i_to_door_dir(dir)
		var opp_dir = _vector2i_to_door_dir(-dir)
		room.add_door(room_dir)
		neighbor.add_door(opp_dir)
		_add_corridor(room, neighbor, room_dir, grid_pos, n_pos)

	rooms_since_portal += 1
	if rooms_since_portal >= portal_target and portal_template:
		_place_portal_in(room)
		rooms_since_portal = 0
		portal_target = randi_range(portal_interval_min, portal_interval_max)

	if grid_pos != Vector2i.ZERO:
		var roll = randf()
		if roll < 0.12: room.make_lockable()
		elif roll < 0.25 and chest_template:
			room.is_chest_room = true
			_place_chest_in(room)

	return room

func _add_corridor(a: Room, b: Room, dir: int, ga: Vector2i, gb: Vector2i) -> void:
	var sprite = Sprite2D.new()
	sprite.centered = true
	var mid = (a.global_position + b.global_position) / 2.0
	sprite.position = mid

	var gap = Vector2(abs(ga.x - gb.x) * 800.0, abs(ga.y - gb.y) * 600.0)
	var img: Image
	if dir == 0 or dir == 1:
		var cw = int(gap.x) if gap.x > 0 else int(a.room_half_w * 2)
		img = Image.create(maxi(20, cw), 12, false, Image.FORMAT_RGBA8)
	else:
		var ch = int(gap.y) if gap.y > 0 else int(a.room_half_h * 2)
		img = Image.create(12, maxi(20, ch), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.18, 0.16, 0.12, 1))
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)
	corridors.append(sprite)

func _place_chest_in(room: Room) -> void:
	var chest = chest_template.instantiate()
	chest.position = Vector2(0, -50)
	room.add_child(chest)

func _place_portal_in(room: Room) -> void:
	for child in room.get_children():
		if child is Area2D and child.name.begins_with("Portal"): return
	var portal = portal_template.instantiate()
	portal.position = Vector2(0, 0)
	room.add_child(portal)

func _cleanup_distant(center: Vector2i) -> void:
	var to_remove: Array[Vector2i] = []
	for gp in room_map.keys():
		var dist = (gp - center).abs()
		if dist.x > cleanup_radius or dist.y > cleanup_radius:
			to_remove.append(gp)
	for gp in to_remove:
		var room = room_map[gp] as Room
		if not is_instance_valid(room): room_map.erase(gp); continue
		for other in room.connections:
			if not is_instance_valid(other): continue
			other.connections.erase(room)
			var d = _get_dir_between(gp, _world_to_grid(other.global_position))
			_disable_door(other, d)
		room.queue_free()
		room_map.erase(gp)

func _disable_door(room: Room, dir: int) -> void:
	match dir:
		0: room.has_door_top = false; room.door_top.visible = false
		1: room.has_door_bottom = false; room.door_bottom.visible = false
		2: room.has_door_left = false; room.door_left.visible = false
		3: room.has_door_right = false; room.door_right.visible = false
	room._build_wall_collisions()

func _vector2i_to_door_dir(v: Vector2i) -> int:
	if v == Vector2i.UP: return 0; if v == Vector2i.DOWN: return 1
	if v == Vector2i.LEFT: return 2; return 3

func _get_dir_between(from: Vector2i, to: Vector2i) -> int:
	var diff = to - from
	if diff == Vector2i.UP: return 0; if diff == Vector2i.DOWN: return 1
	if diff == Vector2i.LEFT: return 2; return 3

func _place_player() -> void:
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and room_map.has(Vector2i.ZERO):
		var spawn = room_map[Vector2i.ZERO] as Room
		player_node.global_position = spawn.global_position + Vector2(0, -50)

func _place_enemies_and_items() -> void:
	var rooms_array: Array[Room] = []
	for room in room_map.values(): rooms_array.append(room)
	var enemy_spawner = get_node_or_null("EnemySpawner")
	if enemy_spawner: enemy_spawner.spawn_enemies(rooms_array)
	var item_spawner = get_node_or_null("ItemSpawner")
	if item_spawner: item_spawner.spawn_items(rooms_array)
