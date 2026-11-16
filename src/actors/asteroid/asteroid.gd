class_name AsteroidBody
extends Area3D
## Астероид: 3 размера, 3 типа (обычный / топливо / ремонт).
## Сам себя не делит — сообщает в Events.asteroid_destroyed, а осколки создаёт Spawner.

enum Kind { NORMAL, FUEL, REPAIR }

const RADII: Array[float] = [6.0, 3.5, 1.8]
const HPS: Array[float] = [30.0, 15.0, 8.0]
const SCORES: Array[float] = [15.0, 10.0, 5.0]
const KIND_COLORS := {
	Kind.NORMAL: Color(0.52, 0.49, 0.46),
	Kind.FUEL: Color(0.3, 0.85, 1.0),
	Kind.REPAIR: Color(0.34, 1.0, 0.56),
}

var tier := 0
var kind: Kind = Kind.NORMAL
var velocity := Vector3.ZERO
var radius := 6.0
var hp := 30.0

var _spin_axis := Vector3.UP
var _spin_speed := 0.0
var _material: StandardMaterial3D
var _hit_flash := 0.0
var _dead := false

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _collision: CollisionShape3D = $CollisionShape3D


## Вызывать ДО add_child — _ready() строит меш по этим параметрам.
func setup(p_tier: int, p_kind: Kind, p_velocity: Vector3) -> AsteroidBody:
	tier = clampi(p_tier, 0, 2)
	kind = p_kind
	velocity = p_velocity
	return self


func _ready() -> void:
	add_to_group("asteroids")
	add_to_group("targetable")
	collision_layer = Layers.ASTEROIDS
	collision_mask = 0

	radius = RADII[tier]
	hp = HPS[tier]
	var shape := SphereShape3D.new()
	shape.radius = radius * 0.85
	_collision.shape = shape

	_mesh.mesh = AsteroidMeshFactory.build(radius, randi())
	_material = _make_material()
	_mesh.material_override = _material

	_spin_axis = Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)).normalized()
	_spin_speed = randf_range(-0.6, 0.6)
	rotate(_spin_axis, randf() * TAU)


func _make_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.roughness = 0.95
	if kind == Kind.NORMAL:
		m.albedo_color = KIND_COLORS[kind]
	else:
		m.albedo_color = Color(0.18, 0.18, 0.2)
		m.emission_enabled = true
		m.emission = KIND_COLORS[kind]
	return m


func _process(delta: float) -> void:
	if kind != Kind.NORMAL:
		_material.emission_energy_multiplier = 1.0 + 0.8 * sin(Time.get_ticks_msec() / 300.0)
	if _hit_flash > 0.0:
		_hit_flash -= delta
		_material.albedo_color = Color.WHITE if _hit_flash > 0.0 else _base_albedo()


func _base_albedo() -> Color:
	return KIND_COLORS[kind] if kind == Kind.NORMAL else Color(0.18, 0.18, 0.2)


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	rotate(_spin_axis, _spin_speed * delta)


func take_damage(amount: float) -> void:
	if _dead:
		return
	hp -= amount
	_hit_flash = 0.06
	if hp <= 0.0:
		destroy(true)


func destroy(allow_split: bool) -> void:
	if _dead:
		return
	_dead = true
	match kind:
		Kind.FUEL:
			Game.add_fuel(25.0)
			Game.add_score(10.0)
			Events.notify.emit("+ТОПЛИВО", KIND_COLORS[kind])
		Kind.REPAIR:
			Game.add_hull(30.0)
			Game.add_score(10.0)
			Events.notify.emit("+РЕМОНТ", KIND_COLORS[kind])
		_:
			Game.add_score(SCORES[tier])

	Explosion.spawn(global_position, KIND_COLORS[kind].lightened(0.3), radius * 0.45)
	Events.asteroid_destroyed.emit(global_position, velocity, tier, kind, allow_split and tier < 2)
	queue_free()
