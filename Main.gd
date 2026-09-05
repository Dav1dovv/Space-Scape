extends Node2D

@onready var entities: Node2D = $Entities
@onready var ship: Area2D = $Ship

const AsteroidScene := preload("res://entities/Asteroid.tscn")
const PirateScene := preload("res://entities/Pirate.tscn")

func _ready() -> void:
	GameState.reset()
	for i in range(14):
		spawn_asteroid(true)

func _process(_delta: float) -> void:
	if GameState.game_over:
		return

	while get_tree().get_nodes_in_group("asteroids").size() < 12 + GameState.level:
		spawn_asteroid(false)

	var pirate_target = min(2 + int(GameState.level / 2.0), 8)
	if get_tree().get_nodes_in_group("pirates").size() < pirate_target and randf() < 0.02:
		spawn_pirate()

	for a in get_tree().get_nodes_in_group("asteroids"):
		if a.global_position.distance_squared_to(ship.global_position) > 1700.0 * 1700.0:
			a.queue_free()
	for p in get_tree().get_nodes_in_group("pirates"):
		if p.global_position.distance_squared_to(ship.global_position) > 1600.0 * 1600.0:
			p.queue_free()

func spawn_asteroid(initial: bool) -> void:
	var ang = randf_range(0, TAU)
	var d = randf_range(200, 1000) if initial else randf_range(700, 1050)
	var pos = ship.global_position + Vector2(cos(ang), sin(ang)) * d
	var tier: int
	if randf() < 0.5:
		tier = 2
	elif randf() < 0.7:
		tier = 1
	else:
		tier = 0
	spawn_asteroid_at(pos, tier)

func spawn_asteroid_at(pos: Vector2, tier: int) -> void:
	var a = AsteroidScene.instantiate()
	a.tier = tier
	if tier == 2:
		a.type = Asteroid.Type.NORMAL
	else:
		var r = randf()
		if r < 0.62:
			a.type = Asteroid.Type.NORMAL
		elif r < 0.82:
			a.type = Asteroid.Type.FUEL
		else:
			a.type = Asteroid.Type.REPAIR
	# tier/type должны быть выставлены ДО add_child — _ready() срабатывает
	# в момент входа в дерево и красит контур по текущим значениям
	entities.add_child(a)
	a.global_position = pos
	var speed = randf_range(10, 45)
	var dir = randf_range(0, TAU)
	a.velocity = Vector2(cos(dir), sin(dir)) * speed

func spawn_pirate() -> void:
	var ang = randf_range(0, TAU)
	var d = randf_range(800, 1100)
	var p = PirateScene.instantiate()
	entities.add_child(p)
	p.global_position = ship.global_position + Vector2(cos(ang), sin(ang)) * d
