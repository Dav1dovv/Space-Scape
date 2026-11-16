class_name ChaseCamera
extends Camera3D
## Камера смотрит туда же, куда ПРИЦЕЛ игрока (не корабль).
## Игрок напрямую управляет взглядом — отсюда ощущение контроля.
## Корабль догоняет прицел с запаздыванием, поэтому видно, как он входит в поворот
## и кренится. Позиция жёстко привязана к кораблю (без «болтанки»), сглажены только
## откат при разгоне, FOV и лёгкая тряска.

@export var target_path: NodePath
@export var offset := Vector3(0.0, 2.2, 9.5)
## Насколько быстро камера догоняет прицел. Выше — резче, ниже — мягче.
@export var rotation_sharpness := 14.0
## Небольшой откат назад при разгоне — ощущение рывка.
@export var speed_pullback := 0.03
@export var pullback_sharpness := 3.0
@export var base_fov := 70.0
@export var speed_fov_bonus := 6.0
@export var boost_fov_bonus := 5.0
@export var fov_sharpness := 2.5
@export var max_shake_degrees := 1.0

var _trauma := 0.0
var _rotation := Quaternion.IDENTITY
var _pullback := Vector3.ZERO

@onready var _target: PlayerShip = get_node_or_null(target_path)


func _ready() -> void:
	top_level = true
	process_physics_priority = 100  # после корабля
	Events.player_hit.connect(func(amount: float) -> void: add_trauma(clampf(amount / 30.0, 0.2, 0.6)))
	Events.game_over.connect(func() -> void: add_trauma(1.0))
	if _target:
		_rotation = _target.aim_quaternion
		global_transform = Transform3D(Basis(_rotation), _target.global_position + Basis(_rotation) * offset)
		reset_physics_interpolation()


func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	_rotation = _rotation.slerp(_target.aim_quaternion, 1.0 - exp(-rotation_sharpness * delta)).normalized()
	var b := Basis(_rotation)

	_pullback = _pullback.lerp(-_target.velocity * speed_pullback, 1.0 - exp(-pullback_sharpness * delta))
	var pos := _target.global_position + b * offset + _pullback

	_trauma = maxf(_trauma - delta * 2.0, 0.0)
	if _trauma > 0.0:
		var s := deg_to_rad(max_shake_degrees) * _trauma * _trauma
		b = b * Basis.from_euler(Vector3(randf_range(-s, s), randf_range(-s, s), 0.0))

	global_transform = Transform3D(b, pos)

	var speed_ratio := clampf(_target.velocity.length() / _target.stats.max_speed, 0.0, 1.5)
	var target_fov := base_fov + speed_fov_bonus * speed_ratio + (boost_fov_bonus if _target.is_boosting else 0.0)
	fov = lerpf(fov, target_fov, 1.0 - exp(-fov_sharpness * delta))
