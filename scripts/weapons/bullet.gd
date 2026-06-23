extends Area2D
class_name Bullet

var direction: Vector2 = Vector2.RIGHT
var speed: float = 800.0
var damage: float = 15.0
var lifetime: float = 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is TileMap:
		_spawn_impact()
		queue_free()
	elif body is Enemy:
		body.take_damage(damage)
		_spawn_impact()
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	pass

func _spawn_impact() -> void:
	pass
