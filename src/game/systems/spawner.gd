class_name Spawner
extends Node
## Держит «живой» космос вокруг игрока: досыпает астероиды и пиратов
## в сферической оболочке, удаляет слишком далёкие, делит астероиды на осколки.

const AsteroidScene := preload("res://src/actors/asteroid/asteroid.tscn")
const PirateScene := preload("res://src/actors/pirate/pirate.tscn")

@export var actors_root_path: NodePath

@export_group("Астероиды")
@export var base_asteroid_count := 28
@export var asteroids_per_level := 2
@export var initial_radius := Vector2(25.0, 200.0)
@export var spawn_radius := Vector2(180.0, 240.0)
@export var asteroid_speed := Vector2(1.0, 6.0)

@export_group("Пираты")
@export var pirate_spawn_radius := Vector2(170.0, 220.0)
## Шанс за физический тик (60/с).
@export var pirate_spawn_chance := 0.012
@export var max_pirates := 8

@export_group("Очистка")
@export var despawn_distance := 300.0

var _player: Node3D

@onready var _actors_root: Node3D = get_node(actors_root_path)


func _ready() -> void:
	Events.asteroid_destroyed.connect(_on_asteroid_destroyed)
	_spawn_initial.call_deferred()


func _spawn_initial() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	for i in base_asteroid_count:
		spawn_asteroid(_player.global_position, initial_radius)


func _physics_process(_delta: float) -> void:
	if Game.is_over or not is_instance_valid(_player):
		return
	var center := _player.global_position
	_despawn_far("asteroids", center)
	_despawn_far("pirates", center)

	var asteroid_target := base_asteroid_count + Game.level * asteroids_per_level
	if get_tree().get_nodes_in_group("asteroids").size() < asteroid_target:
		spawn_asteroid(center, spawn_radius)

	var pirate_target := mini(1 + int(Game.level / 2.0), max_pirates)
	if get_tree().get_nodes_in_group("pirates").size() < pirate_target and randf() < pirate_spawn_chance:
		spawn_pirate(center)


func spawn_asteroid(center: Vector3, radius_range: Vector2) -> void:
	var pos := center + _random_unit() * randf_range(radius_range.x, radius_range.y)
	var roll := randf()
	var tier := 0 if roll < 0.3 else (1 if roll < 0.65 else 2)
	spawn_asteroid_at(pos, tier, _random_unit() * randf_range(asteroid_speed.x, asteroid_speed.y))


func spawn_asteroid_at(pos: Vector3, tier: int, velocity: Vector3) -> void:
	var asteroid: AsteroidBody = AsteroidScene.instantiate()
	asteroid.setup(tier, _roll_kind(tier), velocity)
	_actors_root.add_child(asteroid)
	asteroid.global_position = pos
	asteroid.reset_physics_interpolation()


func spawn_pirate(center: Vector3) -> void:
	var pirate: PirateShip = PirateScene.instantiate()
	_actors_root.add_child(pirate)
	pirate.global_position = center + _random_unit() * randf_range(pirate_spawn_radius.x, pirate_spawn_radius.y)
	pirate.reset_physics_interpolation()


func _roll_kind(tier: int) -> AsteroidBody.Kind:
	if tier == 2:
		return AsteroidBody.Kind.NORMAL
	var r := randf()
	if r < 0.62:
		return AsteroidBody.Kind.NORMAL
	if r < 0.82:
		return AsteroidBody.Kind.FUEL
	return AsteroidBody.Kind.REPAIR


func _on_asteroid_destroyed(pos: Vector3, velocity: Vector3, tier: int, _kind: int, split: bool) -> void:
	if not split:
		return
	# Отложенно: сигнал может прийти во время обработки столкновений,
	# а создавать физические объекты в этот момент нельзя.
	for i in 2:
		var offset := _random_unit() * AsteroidBody.RADII[tier] * 0.5
		var kick := _random_unit() * randf_range(3.0, 7.0)
		spawn_asteroid_at.call_deferred(pos + offset, tier + 1, velocity + kick)


func _despawn_far(group: StringName, center: Vector3) -> void:
	var limit := despawn_distance * despawn_distance
	for node in get_tree().get_nodes_in_group(group):
		if (node as Node3D).global_position.distance_squared_to(center) > limit:
			node.queue_free()


static func _random_unit() -> Vector3:
	return Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)).normalized()
