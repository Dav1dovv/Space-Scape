extends Area2D
class_name Asteroid

enum Type { NORMAL, FUEL, REPAIR }

var velocity := Vector2.ZERO
var tier := 0 # 0 = крупный, 1 = средний, 2 = мелкий
var type: int = Type.NORMAL
var hp := 30.0
var radius := 40.0
var rot_speed := 0.0

@onready var outline: Line2D = $Outline
@onready var collision: CollisionShape2D = $CollisionShape2D

const RADII := [40.0, 25.0, 14.0]
const HPS := [30.0, 15.0, 8.0]

func _ready() -> void:
	add_to_group("asteroids")
	radius = RADII[tier]
	hp = HPS[tier]
	collision.shape = collision.shape.duplicate()
	(collision.shape as CircleShape2D).radius = radius
	_build_shape()
	rot_speed = randf_range(-0.4, 0.4)
	match type:
		Type.FUEL:
			outline.default_color = Color(0.3, 0.85, 1.0)
		Type.REPAIR:
			outline.default_color = Color(0.34, 1.0, 0.56)
		_:
			outline.default_color = Color(0.73, 0.76, 0.8)

func _build_shape() -> void:
	var n = randi_range(7, 10)
	var pts := PackedVector2Array()
	for i in range(n):
		var a = float(i) / float(n) * TAU
		var r = radius * randf_range(0.72, 1.15)
		pts.append(Vector2(cos(a), sin(a)) * r)
	pts.append(pts[0])
	outline.points = pts

func _process(delta: float) -> void:
	rotation += rot_speed * delta
	if type != Type.NORMAL:
		modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 300.0)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		destroy(false)

func destroy(skip_split: bool) -> void:
	match type:
		Type.FUEL:
			GameState.fuel = clamp(GameState.fuel + 25.0, 0.0, GameState.max_fuel)
			GameState.add_score(10.0)
			GameState.notify_text.emit("+ТОПЛИВО", Color(0.3, 0.85, 1.0))
		Type.REPAIR:
			GameState.hull = clamp(GameState.hull + 30.0, 0.0, GameState.max_hull)
			GameState.add_score(10.0)
			GameState.notify_text.emit("+РЕМОНТ", Color(0.34, 1.0, 0.56))
		_:
			var pts = [15.0, 10.0, 5.0]
			GameState.add_score(pts[tier])

	if not skip_split and tier < 2:
		var main = get_tree().current_scene
		main.spawn_asteroid_at(global_position, tier + 1)
		main.spawn_asteroid_at(global_position, tier + 1)

	queue_free()
