extends Area2D
class_name Pickup

enum PickupType { HEALTH, AMMO, SANITY, WEAPON, KEY, CURRENCY }

@export var pickup_type: PickupType = PickupType.HEALTH
@export var value: float = 25.0
@export var weapon_scene: PackedScene
@export var float_amplitude: float = 5.0
@export var float_speed: float = 2.0

var base_y: float

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.y = base_y + sin(Time.get_ticks_msec() * 0.001 * float_speed) * float_amplitude

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	match pickup_type:
		PickupType.HEALTH:
			body.heal(value)
		PickupType.AMMO:
			if body.current_weapon:
				body.current_weapon.current_ammo = min(
					body.current_weapon.current_ammo + int(value),
					body.current_weapon.max_ammo + int(MetaProgression.get_upgrade_value("starting_ammo"))
				)
		PickupType.SANITY:
			RunManager.modify_sanity(value)
		PickupType.WEAPON:
			if weapon_scene:
				var weapon = weapon_scene.instantiate()
				body.add_weapon(weapon)
		PickupType.CURRENCY:
			MetaProgression.currency += int(value)

	queue_free()
