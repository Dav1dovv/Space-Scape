class_name SpaceDust
extends MultiMeshInstance3D
## Космическая пыль вокруг камеры. В открытом космосе без ориентиров скорость
## не чувствуется — пылинки вытягиваются в штрихи по вектору скорости.
## Одна MultiMesh = один draw call на все частицы.

@export var count := 350
@export var box_size := 70.0
@export var thickness := 0.04
@export var min_streak := 0.08
@export var streak_per_speed := 0.035
@export var player_path: NodePath

var _offsets := PackedVector3Array()

@onready var _player: PlayerShip = get_node_or_null(player_path)


func _ready() -> void:
	top_level = true
	# Пыль обновляется каждый кадр отрисовки — интерполяция физики ей не нужна
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	global_transform = Transform3D.IDENTITY
	custom_aabb = AABB(Vector3.ONE * -1.0e6, Vector3.ONE * 2.0e6)  # не отсекать
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.75, 0.85, 1.0, 0.5)
	# Плавно гасим у краёв куба, чтобы «перескок» пылинки был незаметен
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	mat.distance_fade_min_distance = box_size * 0.5
	mat.distance_fade_max_distance = box_size * 0.2

	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	mesh.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	multimesh = mm

	_offsets.resize(count)
	for i in count:
		_offsets[i] = Vector3(randf(), randf(), randf()) * box_size


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var center := cam.global_position
	var vel := _player.velocity if is_instance_valid(_player) else Vector3.ZERO
	var speed := vel.length()

	var b := Basis.IDENTITY.scaled(Vector3.ONE * thickness)
	if speed > 0.5:
		var dir := vel / speed
		var up := Vector3.UP if absf(dir.y) < 0.98 else Vector3.RIGHT
		var look := Basis.looking_at(dir, up)
		b = Basis(look.x * thickness, look.y * thickness, look.z * (min_streak + speed * streak_per_speed))

	var half := box_size * 0.5
	for i in count:
		var o := _offsets[i]
		var p := Vector3(
			fposmod(o.x - center.x + half, box_size) - half,
			fposmod(o.y - center.y + half, box_size) - half,
			fposmod(o.z - center.z + half, box_size) - half) + center
		multimesh.set_instance_transform(i, Transform3D(b, p))
