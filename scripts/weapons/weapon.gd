extends Node2D
class_name Weapon

@export var weapon_name: String = "Pistol"
@export var damage: float = 15.0
@export var fire_rate: float = 0.3
@export var max_ammo: int = 12
@export var reload_time: float = 1.5
@export var bullet_speed: float = 800.0
@export var spread_angle: float = 3.0
@export var bullets_per_shot: int = 1
@export var automatic: bool = false
@export var bullet_scene: PackedScene

var current_ammo: int
var fire_timer: float = 0.0
var is_reloading: bool = false
var reload_timer: float = 0.0
var owner_player: Player = null

func _ready() -> void:
	current_ammo = max_ammo + int(MetaProgression.get_upgrade_value("starting_ammo"))

func _process(delta: float) -> void:
	fire_timer = max(0.0, fire_timer - delta)
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()

func equip(player: Player) -> void:
	owner_player = player
	if not is_inside_tree():
		return
	var pivot = player.get_node("WeaponPivot")
	if get_parent() != pivot:
		reparent(pivot)
	position = Vector2(20, 0)
	RunManager.ammo_changed.emit(current_ammo, max_ammo)

func unequip() -> void:
	owner_player = null

func try_shoot(origin: Vector2, direction: Vector2) -> bool:
	if is_reloading or fire_timer > 0.0 or current_ammo <= 0:
		if current_ammo <= 0 and not is_reloading:
			start_reload()
		return false

	fire_timer = fire_rate
	current_ammo -= 1

	for i in bullets_per_shot:
		var spread = randf_range(-spread_angle, spread_angle)
		var bullet_dir = direction.rotated(deg_to_rad(spread))
		_spawn_bullet(origin, bullet_dir)

	RunManager.ammo_changed.emit(current_ammo, max_ammo)
	return true

func _spawn_bullet(origin: Vector2, direction: Vector2) -> void:
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	owner_player.get_parent().add_child(bullet)
	bullet.global_position = origin
	bullet.direction = direction
	bullet.speed = bullet_speed
	bullet.damage = damage + MetaProgression.get_upgrade_value("damage")

func start_reload() -> void:
	if is_reloading or current_ammo >= max_ammo:
		return
	is_reloading = true
	reload_timer = reload_time - MetaProgression.get_upgrade_value("reload_speed")

func _finish_reload() -> void:
	is_reloading = false
	current_ammo = max_ammo + int(MetaProgression.get_upgrade_value("starting_ammo"))
	RunManager.ammo_changed.emit(current_ammo, max_ammo)
