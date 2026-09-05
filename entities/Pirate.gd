extends Area2D

const PirateBulletScene := preload("res://entities/PirateBullet.tscn")

var velocity := Vector2.ZERO
var hp := 40.0
var max_hp := 40.0
var radius := 16.0
var fire_timer := 0.0

@onready var hp_fill: ColorRect = $HPBarFill

func _ready() -> void:
	add_to_group("pirates")
	hp = 40.0 + GameState.level * 4.0
	max_hp = hp
	fire_timer = randf_range(0.5, 1.5)

func _physics_process(delta: float) -> void:
	if GameState.game_over:
		return
	var ship = get_tree().get_first_node_in_group("player")
	if ship == null:
		return
	var to_ship: Vector2 = ship.global_position - global_position
	var dist_sq = to_ship.length_squared()
	rotation = to_ship.angle()

	if dist_sq < 750.0 * 750.0:
		velocity += to_ship.normalized() * 90.0 * delta

	velocity *= 0.985
	if velocity.length() > 150.0:
		velocity = velocity.normalized() * 150.0
	global_position += velocity * delta

	fire_timer -= delta
	if dist_sq < 700.0 * 700.0 and fire_timer <= 0:
		fire_timer = randf_range(1.0, 1.8)
		_fire(to_ship.angle())

	hp_fill.size.x = 24.0 * (hp / max_hp)

func _fire(angle: float) -> void:
	var b = PirateBulletScene.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position
	b.velocity = Vector2(cos(angle), sin(angle)) * 480.0

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		GameState.add_score(40.0)
		GameState.kills += 1
		queue_free()
