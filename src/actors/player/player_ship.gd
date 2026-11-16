class_name PlayerShip
extends Area3D
## Корабль игрока с 6 степенями свободы.
##
## Схема управления «прицел ведёт, корабль следует» (как в War Thunder / Everspace 2):
##   • мышь напрямую поворачивает ПРИЦЕЛ (aim_quaternion) в его собственных осях —
##     поэтому нет «шарнирного замка», петли и бочки работают в любой ориентации;
##   • камера смотрит туда же, куда прицел, — игрок всегда контролирует взгляд;
##   • корабль догоняет прицел с ограниченным угловым ускорением — у него есть вес,
##     плавный вход в поворот и плавная остановка без перелёта.
## Перемещение: W/S тяга, A/D стрейф, Пробел/Ctrl вверх-вниз. Крен: Q/E.

const ProjectileScene := preload("res://src/actors/projectiles/projectile.tscn")
const RAM_DAMAGE_PER_METER := 3.7

@export var stats: ShipStats

var velocity := Vector3.ZERO
## Локальная угловая скорость корабля: x — тангаж, y — рыскание, z — крен.
var angular_velocity := Vector3.ZERO
## Куда хочет смотреть игрок. Камера следует за ним, корабль догоняет.
var aim_quaternion := Quaternion.IDENTITY
var flight_assist := true
var is_thrusting := false
var is_boosting := false
## Цель автодоводки (или null).
var aim_target: Node3D = null

var _mouse_delta := Vector2.ZERO
var _aim_roll_speed := 0.0
var _fire_timer := 0.0
var _invuln_timer := 0.0
var _muzzle_index := 0
var _flame_power := 0.0
var _strafe_input := Vector2.ZERO

@onready var model: Node3D = $Model
@onready var engine_flame: Node3D = $Model/EngineFlame
@onready var muzzles: Array[Marker3D] = [$Model/MuzzleL, $Model/MuzzleR]


func _ready() -> void:
	if stats == null:
		stats = ShipStats.new()
	add_to_group("player")
	collision_layer = Layers.PLAYER
	collision_mask = Layers.ASTEROIDS | Layers.ENEMIES
	area_entered.connect(_on_area_entered)
	Events.game_over.connect(_on_game_over)
	aim_quaternion = quaternion


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta += event.relative
	elif event.is_action_pressed("recenter_aim"):
		aim_quaternion = quaternion
	elif event.is_action_pressed("toggle_assist"):
		flight_assist = not flight_assist
		Events.notify.emit("АССИСТЕНТ ПОЛЁТА: " + ("ВКЛ" if flight_assist else "ВЫКЛ"), Color(0.81, 0.91, 1.0))
	elif event.is_action_pressed("sensitivity_up"):
		_change_sensitivity(1.15)
	elif event.is_action_pressed("sensitivity_down"):
		_change_sensitivity(1.0 / 1.15)


func _change_sensitivity(factor: float) -> void:
	stats.mouse_sensitivity = clampf(stats.mouse_sensitivity * factor, 0.0005, 0.02)
	Events.notify.emit("ЧУВСТВИТЕЛЬНОСТЬ МЫШИ: %.1f" % (stats.mouse_sensitivity * 1000.0), Color(0.81, 0.91, 1.0))


func _physics_process(delta: float) -> void:
	if Game.is_over:
		return
	_update_aim(delta)
	_update_rotation(delta)
	_update_translation(delta)
	_update_aim_assist()
	_update_weapons(delta)
	_update_visuals(delta)


# --- Прицел: мышь/стик поворачивают «желаемую ориентацию» --------------------

func _update_aim(delta: float) -> void:
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	var d := _mouse_delta * stats.mouse_sensitivity + stick * stats.stick_aim_rate * delta
	_mouse_delta = Vector2.ZERO

	var pitch := -d.y * (-1.0 if stats.invert_y else 1.0)  # мышь вверх → нос вверх
	var yaw := -d.x                                        # мышь вправо → нос вправо

	# Крен набирается плавно, а не рывком
	var roll_in := Input.get_axis("roll_right", "roll_left")
	_aim_roll_speed = move_toward(_aim_roll_speed, roll_in * stats.aim_roll_rate, stats.aim_roll_accel * delta)

	# Поворот в ЛОКАЛЬНЫХ осях прицела — петля работает из любой ориентации
	aim_quaternion = (aim_quaternion
		* Quaternion(Vector3.UP, yaw)
		* Quaternion(Vector3.RIGHT, pitch)
		* Quaternion(Vector3.BACK, _aim_roll_speed * delta)).normalized()

	# Прицел не убегает слишком далеко от носа — корабль всегда в кадре и «тянется» за ним
	var lead := quaternion.angle_to(aim_quaternion)
	var max_lead := deg_to_rad(stats.max_aim_lead_deg)
	if lead > max_lead:
		aim_quaternion = quaternion.slerp(aim_quaternion, max_lead / lead).normalized()


# --- Корабль догоняет прицел: ограниченная скорость и ускорение -------------

func _update_rotation(delta: float) -> void:
	var err := (quaternion.inverse() * aim_quaternion).normalized()
	if err.w < 0.0:
		err = -err  # кратчайший путь
	var v := Vector3(err.x, err.y, err.z)
	var s := v.length()
	var e := Vector3.ZERO if s < 1e-6 else v / s * (2.0 * atan2(s, err.w))

	var rates := Vector3(stats.pitch_rate, stats.yaw_rate, stats.roll_rate)
	var desired := Vector3.ZERO
	for i in 3:
		var a := absf(e[i])
		# min(линейно, sqrt(2·a·угол)) — профиль «успеть затормозить»: без перелёта и дрожи
		var w := minf(minf(a * stats.turn_gain, sqrt(2.0 * stats.angular_accel * a)), rates[i])
		desired[i] = signf(e[i]) * w
	angular_velocity = angular_velocity.move_toward(desired, stats.angular_accel * delta)

	var w_len := angular_velocity.length()
	if w_len > 1e-5:
		quaternion = (quaternion * Quaternion(angular_velocity / w_len, w_len * delta)).normalized()


# --- Перемещение по 3 осям ---------------------------------------------------

func _update_translation(delta: float) -> void:
	var b := global_basis
	var forward := -b.z
	var thrust_in := Input.get_axis("move_back", "move_forward")
	_strafe_input = Vector2(
		Input.get_axis("strafe_left", "strafe_right"),
		Input.get_axis("strafe_down", "strafe_up"))

	var accel := Vector3.ZERO
	var fuel_cost := 0.0
	is_boosting = false

	if Game.has_fuel():
		if thrust_in > 0.0:
			accel += forward * thrust_in * stats.thrust
			fuel_cost += stats.fuel_thrust_rate * thrust_in
		elif thrust_in < 0.0:
			accel += forward * thrust_in * stats.reverse_thrust
			fuel_cost += stats.fuel_thrust_rate * -thrust_in
		if _strafe_input != Vector2.ZERO:
			accel += (b.x * _strafe_input.x + b.y * _strafe_input.y) * stats.strafe
			fuel_cost += stats.fuel_strafe_rate * _strafe_input.length()
		if Input.is_action_pressed("boost") and accel != Vector3.ZERO:
			is_boosting = true
			accel *= stats.boost_mult
			fuel_cost += stats.fuel_boost_rate
		Game.consume_fuel(fuel_cost * delta)

	is_thrusting = accel != Vector3.ZERO
	velocity += accel * delta

	if Input.is_action_pressed("brake") and Game.has_fuel():
		velocity *= exp(-stats.brake_damping * delta)
	elif flight_assist and Game.has_fuel():
		var forward_speed := velocity.dot(forward)
		var lateral := velocity - forward * forward_speed
		if _strafe_input == Vector2.ZERO:
			lateral *= exp(-stats.assist_lateral_damping * delta)
		if is_zero_approx(thrust_in):
			forward_speed *= exp(-stats.assist_forward_damping * delta)
		velocity = forward * forward_speed + lateral

	var cap := stats.boost_max_speed if is_boosting else stats.max_speed
	var speed := velocity.length()
	if speed > cap:
		velocity = velocity / speed * maxf(cap, speed - stats.overspeed_decay * delta)

	global_position += velocity * delta


# --- Оружие ------------------------------------------------------------------

## Направление прицела (центр экрана).
func aim_forward() -> Vector3:
	return -(Basis(aim_quaternion).z)


## Куда реально полетят пули: в прицел (с упреждением по захваченной цели),
## но не дальше угла подвеса пушек от носа корабля.
func fire_direction() -> Vector3:
	var desired := aim_forward()
	if is_instance_valid(aim_target):
		var to := aim_target.global_position - global_position
		var t := to.length() / stats.bullet_speed
		var target_velocity: Vector3 = aim_target.get("velocity")
		desired = (to + (target_velocity - velocity) * t).normalized()
	var nose := -global_basis.z
	var angle := nose.angle_to(desired)
	var gimbal := deg_to_rad(stats.gun_gimbal_deg)
	if angle > gimbal:
		desired = nose.slerp(desired, gimbal / angle)
	return desired.normalized()


func _update_aim_assist() -> void:
	aim_target = null
	var forward := aim_forward()
	var best := cos(deg_to_rad(stats.aim_assist_angle))
	for node in get_tree().get_nodes_in_group("targetable"):
		var target := node as Node3D
		var to := target.global_position - global_position
		var dist := to.length()
		if dist < 1.0 or dist > stats.aim_assist_range:
			continue
		var alignment := forward.dot(to / dist)
		if alignment > best:
			best = alignment
			aim_target = target


func _update_weapons(delta: float) -> void:
	_fire_timer -= delta
	var can_fire := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or not Input.get_connected_joypads().is_empty()
	if can_fire and Input.is_action_pressed("fire") and _fire_timer <= 0.0:
		_fire_timer = stats.fire_cooldown
		_fire()


func _fire() -> void:
	var root := get_tree().get_first_node_in_group("projectile_root")
	if root == null:
		return
	var muzzle := muzzles[_muzzle_index]
	_muzzle_index = 1 - _muzzle_index
	var projectile: Projectile = ProjectileScene.instantiate()
	root.add_child(projectile)
	projectile.launch(Projectile.Team.PLAYER, muzzle.global_position,
		fire_direction() * stats.bullet_speed + velocity, Game.bullet_damage())
	Events.player_fired.emit()


# --- Урон --------------------------------------------------------------------

func take_damage(amount: float) -> void:
	if _invuln_timer > 0.0 or Game.is_over:
		return
	_invuln_timer = 0.5
	Game.damage_player(amount)
	Events.player_hit.emit(amount)


func _on_area_entered(area: Area3D) -> void:
	if Game.is_over:
		return
	var away := (global_position - area.global_position).normalized()
	if area is AsteroidBody:
		take_damage(area.radius * RAM_DAMAGE_PER_METER)
		velocity += away * 12.0
		area.destroy(false)
	elif area is PirateShip:
		take_damage(16.0)
		velocity += away * 14.0
		area.velocity -= away * 14.0


func _on_game_over() -> void:
	Explosion.spawn(global_position, Color(1.0, 0.6, 0.2), 3.0)
	visible = false
	set_deferred("monitoring", false)


# --- Визуал: пламя, крен в поворотах, наклон при стрейфе, мигание ----------

func _update_visuals(delta: float) -> void:
	var target_power := 0.12
	if is_thrusting:
		target_power = 1.7 if is_boosting else 1.0
	_flame_power = lerpf(_flame_power, target_power, 1.0 - exp(-10.0 * delta))
	var flicker := randf_range(0.9, 1.1)
	var width := clampf(0.6 + _flame_power * 0.4, 0.6, 1.3)
	engine_flame.scale = Vector3(width, width, maxf(_flame_power * flicker * 1.6, 0.05))

	# Координированный поворот: при рыскании модель кренится, как самолёт.
	# Это только визуал — оси управления остаются чистыми.
	var tilt := Vector3(
		_strafe_input.y * 0.12 - angular_velocity.x * 0.08,
		0.0,
		angular_velocity.y * stats.bank_amount - _strafe_input.x * 0.25)
	model.rotation = model.rotation.lerp(tilt, 1.0 - exp(-5.0 * delta))

	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		model.visible = int(_invuln_timer * 20.0) % 2 == 0
	else:
		model.visible = true
