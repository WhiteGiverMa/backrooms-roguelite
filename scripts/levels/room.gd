extends Node2D
class_name Room

@export var room_id: int = 0
@export var is_exit: bool = false
@export var connections: Array[Room] = []

var enemies: Array[Enemy] = []
var items: Array[Node2D] = []
var is_cleared: bool = false
var is_lockable_room: bool = false
var is_chest_room: bool = false
var has_door_top: bool = false
var has_door_bottom: bool = false
var has_door_left: bool = false
var has_door_right: bool = false
var door_locked_top: bool = false
var door_locked_bottom: bool = false
var door_locked_left: bool = false
var door_locked_right: bool = false

const DOOR_GAP: float = 100.0
const WALL_THICKNESS: float = 8.0
const ROOM_HALF_W: float = 400.0
const ROOM_HALF_H: float = 300.0

@onready var exit_indicator: Sprite2D = $ExitIndicator
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var door_top: ColorRect = $DoorTop
@onready var door_bottom: ColorRect = $DoorBottom
@onready var door_left: ColorRect = $DoorLeft
@onready var door_right: ColorRect = $DoorRight
@onready var lock_collision_top: CollisionShape2D = $StaticBody2D/LockCollisionTop
@onready var lock_collision_bottom: CollisionShape2D = $StaticBody2D/LockCollisionBottom
@onready var lock_collision_left: CollisionShape2D = $StaticBody2D/LockCollisionLeft
@onready var lock_collision_right: CollisionShape2D = $StaticBody2D/LockCollisionRight

func _ready() -> void:
	if exit_indicator:
		exit_indicator.visible = is_exit
	_build_wall_collisions()

func add_connection(other: Room) -> void:
	if other in connections:
		return
	connections.append(other)

func make_lockable() -> void:
	is_lockable_room = true
	_update_door_colors()

func add_door(dir: int) -> void:
	match dir:
		0:
			has_door_top = true
			door_top.visible = true
		1:
			has_door_bottom = true
			door_bottom.visible = true
		2:
			has_door_left = true
			door_left.visible = true
		3:
			has_door_right = true
			door_right.visible = true
	_build_wall_collisions()
	_update_door_colors()

func has_door(dir: int) -> bool:
	match dir:
		0: return has_door_top
		1: return has_door_bottom
		2: return has_door_left
		3: return has_door_right
	return false

func _update_door_colors() -> void:
	if is_lockable_room:
		_update_lockable_door(door_top, door_locked_top)
		_update_lockable_door(door_bottom, door_locked_bottom)
		_update_lockable_door(door_left, door_locked_left)
		_update_lockable_door(door_right, door_locked_right)

func _update_lockable_door(door: ColorRect, locked: bool) -> void:
	if not door.visible:
		return
	door.color = Color(0.7, 0.2, 0.2, 1) if locked else Color(0.5, 0.5, 0.5, 1)

func get_nearest_door_dir(global_pos: Vector2) -> int:
	if not is_lockable_room:
		return -1
	var local = to_local(global_pos)
	var best_dir := -1
	var best_dist := 80.0
	var checks = [
		[0, Vector2(0, -ROOM_HALF_H)],
		[1, Vector2(0, ROOM_HALF_H)],
		[2, Vector2(-ROOM_HALF_W, 0)],
		[3, Vector2(ROOM_HALF_W, 0)],
	]
	for c in checks:
		var d = c[0] as int
		if not has_door(d):
			continue
		var dist = local.distance_to(c[1] as Vector2)
		if dist < best_dist:
			best_dist = dist
			best_dir = d
	return best_dir

func toggle_door_lock(dir: int) -> bool:
	if not is_lockable_room:
		return false
	match dir:
		0: door_locked_top = not door_locked_top
		1: door_locked_bottom = not door_locked_bottom
		2: door_locked_left = not door_locked_left
		3: door_locked_right = not door_locked_right
	_update_door_colors()
	_update_lock_collisions()
	return is_door_locked(dir)

func is_door_locked(dir: int) -> bool:
	match dir:
		0: return door_locked_top
		1: return door_locked_bottom
		2: return door_locked_left
		3: return door_locked_right
	return false

func _update_lock_collisions() -> void:
	lock_collision_top.disabled = not door_locked_top
	lock_collision_bottom.disabled = not door_locked_bottom
	lock_collision_left.disabled = not door_locked_left
	lock_collision_right.disabled = not door_locked_right

func _clear_collisions() -> void:
	for child in static_body.get_children():
		# 保留 tscn 中声明的 LockCollision* 节点，只清理动态加的墙碰撞。
		if child.name.begins_with("LockCollision"):
			continue
		child.queue_free()

func _build_wall_collisions() -> void:
	_clear_collisions()
	var hw = ROOM_HALF_W
	var hh = ROOM_HALF_H
	var wt = WALL_THICKNESS

	if not has_door_top:
		_add_collision_rect(Vector2(0, -hh - wt / 2.0), Vector2(hw * 2, wt))
	else:
		_add_top_bottom_segments(-hh - wt / 2.0, hw, wt)
	if not has_door_bottom:
		_add_collision_rect(Vector2(0, hh + wt / 2.0), Vector2(hw * 2, wt))
	else:
		_add_top_bottom_segments(hh + wt / 2.0, hw, wt)
	if not has_door_left:
		_add_collision_rect(Vector2(-hw - wt / 2.0, 0), Vector2(wt, hh * 2))
	else:
		_add_left_right_segments(-hw - wt / 2.0, hh, wt)
	if not has_door_right:
		_add_collision_rect(Vector2(hw + wt / 2.0, 0), Vector2(wt, hh * 2))
	else:
		_add_left_right_segments(hw + wt / 2.0, hh, wt)

func _add_top_bottom_segments(y: float, hw: float, wt: float) -> void:
	var half_gap = DOOR_GAP / 2.0
	var seg_width = hw - half_gap
	_add_collision_rect(Vector2(-hw + seg_width / 2.0, y), Vector2(seg_width, wt))
	_add_collision_rect(Vector2(hw - seg_width / 2.0, y), Vector2(seg_width, wt))

func _add_left_right_segments(x: float, hh: float, wt: float) -> void:
	var half_gap = DOOR_GAP / 2.0
	var seg_height = hh - half_gap
	_add_collision_rect(Vector2(x, -hh + seg_height / 2.0), Vector2(wt, seg_height))
	_add_collision_rect(Vector2(x, hh - seg_height / 2.0), Vector2(wt, seg_height))

func _add_collision_rect(pos: Vector2, size: Vector2) -> void:
	var shape = RectangleShape2D.new()
	shape.size = size
	var col = CollisionShape2D.new()
	col.shape = shape
	col.position = pos
	static_body.add_child(col)

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
