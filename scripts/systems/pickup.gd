extends Area2D
class_name Pickup

enum PickupType { HEALTH, AMMO, SANITY, WEAPON, KEY, CURRENCY }

@export var pickup_type: PickupType = PickupType.HEALTH
@export var value: float = 25.0
@export var weapon_scene: PackedScene
## 弹药拾取时使用的弹药类型（如 "pistol", "stun"）
@export var ammo_type: String = "pistol"
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
			if body.has_method("add_ammo"):
				body.add_ammo(ammo_type, int(value))
		PickupType.SANITY:
			RunManager.modify_sanity(value)
		PickupType.WEAPON:
			if weapon_scene:
				var weapon = weapon_scene.instantiate()
				body.add_weapon(weapon)
				# 赠送起步弹药（不覆盖已有储备）
				if weapon.ammo_type != "" and body.has_method("get_ammo_reserve") and body.has_method("add_ammo"):
					if body.get_ammo_reserve(weapon.ammo_type) == 0:
						body.add_ammo(weapon.ammo_type, weapon.max_ammo * 3)
		PickupType.CURRENCY:
			MetaProgression.currency += int(value)

	queue_free()
