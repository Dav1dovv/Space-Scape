class_name PirateShip
extends Area3D
## Пират: подлетает на дистанцию боя, кружит вокруг игрока по своей орбите
## и стреляет с упреждением (неидеальным — от выстрелов можно увернуться стрейфом).

const ProjectileScene := preload("res://src/actors/projectiles/projectile.tscn")

const ENGAGE_RANGE := 170.0
const FIRE_RANGE := 120.0
const PREFERRED_DISTANCE := 38.0
const MAX_SPEED := 40.0
const ACCELERATION := 28.0
const TURN_RATE := 2.2
const BULLET_SPEED := 110.0
const BULLET_DAMAGE := 8.0
const FIRE_CONE_DOT := 0.9
const LEAD_ACCURACY := 0.8

var velocity := Vector3.ZERO
var hp := 40.0
var max_hp := 40.0

var _fire_timer := 0.0
var _orbit_axis := Vector3.UP
var _dead := false


func _ready() -> void:
	add_to_group("pirates")
	add_to_group("targetable")
	collision_layer = Layers.ENEMIES
	collision_mask = 0
	hp = 40.0 + Game.level * 4.0
	max_hp = hp
	_fire_timer = randf_range(0.8, 1.8)
	_orbit_axis = Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)).normalized()


func _physics_process(delta: float) -> void:
	if Game.is_over:
		return
	var player := get_tree().get_first_node_in_group("player") as PlayerShip
	if player == null:
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player / maxf(dist, 0.001)

	# Рулёжка: сближение/отход + облёт по касательной
	var desired := dir
	if dist < ENGAGE_RANGE:
		var radial := 0.0
		if dist > PREFERRED_DISTANCE * 1.3:
			radial = 1.0
		elif dist < PREFERRED_DISTANCE * 0.7:
			radial = -1.0
		var tangent := dir.cross(_orbit_axis).normalized()
		desired = (dir * radial + tangent * 0.8).normalized()
	velocity += desired * ACCELERATION * delta
	velocity *= exp(-0.3 * delta)
	velocity = velocity.limit_length(MAX_SPEED)
	global_position += velocity * delta

	_face(dir, delta)

	_fire_timer -= delta
	if dist < FIRE_RANGE and _fire_timer <= 0.0 and (-global_basis.z).dot(dir) > FIRE_CONE_DOT:
		_fire_timer = randf_range(1.0, 1.8) - minf(Game.level * 0.05, 0.4)
		_fire(player)


func _face(dir: Vector3, delta: float) -> void:
	var up := global_basis.y
	if absf(dir.dot(up)) > 0.98:
		up = global_basis.z
	var target_q := Basis.looking_at(dir, up).get_rotation_quaternion()
	quaternion = quaternion.slerp(target_q, 1.0 - exp(-TURN_RATE * delta)).normalized()


func _fire(player: PlayerShip) -> void:
	var root := get_tree().get_first_node_in_group("projectile_root")
	if root == null:
		return
	var t := global_position.distance_to(player.global_position) / BULLET_SPEED
	var aim := player.global_position + (player.velocity - velocity) * t * LEAD_ACCURACY
	var dir := (aim - global_position).normalized()
	dir = (dir + Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)) * 0.02).normalized()
	var projectile: Projectile = ProjectileScene.instantiate()
	root.add_child(projectile)
	projectile.launch(Projectile.Team.ENEMY, global_position + dir * 2.0,
		dir * BULLET_SPEED + velocity, BULLET_DAMAGE)


func take_damage(amount: float) -> void:
	if _dead:
		return
	hp -= amount
	if hp <= 0.0:
		_dead = true
		Game.register_kill()
		Events.enemy_killed.emit(global_position)
		Explosion.spawn(global_position, Color(1.0, 0.45, 0.3), 2.2)
		queue_free()
