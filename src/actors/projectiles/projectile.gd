class_name Projectile
extends Node3D
## Общий снаряд для игрока и врагов (команда задаёт цвет и маску столкновений).
## Попадание — рейкастом между кадрами, поэтому быстрые пули не «пролетают сквозь» мелкие цели.

enum Team { PLAYER, ENEMY }

const COLORS := {
	Team.PLAYER: Color(0.3, 0.85, 1.0),
	Team.ENEMY: Color(1.0, 0.36, 0.36),
}

static var _materials := {}

@export var lifetime := 1.6

var team: Team = Team.PLAYER
var velocity := Vector3.ZERO
var damage := 10.0

var _mask := 0
var _ttl := 0.0

@onready var _mesh: MeshInstance3D = $Mesh


## Вызывать после add_child.
func launch(p_team: Team, origin: Vector3, p_velocity: Vector3, p_damage: float) -> void:
	team = p_team
	velocity = p_velocity
	damage = p_damage
	_ttl = lifetime
	global_position = origin
	if team == Team.PLAYER:
		_mask = Layers.ASTEROIDS | Layers.ENEMIES
	else:
		_mask = Layers.ASTEROIDS | Layers.PLAYER
		_mesh.scale = Vector3(2.5, 2.5, 0.8)  # вражеские крупнее — их проще читать и уклоняться
	_mesh.material_override = _material_for(team)
	_orient()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	var from := global_position
	var to := from + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to, _mask)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target: Object = hit.collider
		if target.has_method("take_damage"):
			target.take_damage(damage)
		if team == Team.PLAYER:
			Events.target_hit.emit(hit.position)
		Explosion.spawn(hit.position, COLORS[team], 0.25)
		queue_free()
		return

	global_position = to
	_ttl -= delta
	if _ttl <= 0.0:
		queue_free()


func _orient() -> void:
	if velocity.length_squared() < 0.001:
		return
	var dir := velocity.normalized()
	var up := Vector3.UP if absf(dir.y) < 0.98 else Vector3.RIGHT
	look_at(global_position + dir, up)


static func _material_for(p_team: Team) -> StandardMaterial3D:
	if not _materials.has(p_team):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color.BLACK
		m.emission_enabled = true
		m.emission = COLORS[p_team]
		m.emission_energy_multiplier = 5.0
		_materials[p_team] = m
	return _materials[p_team]
