class_name Explosion
extends Node3D
## Взрыв/искры без ассетов: вспышка-сфера + облако осколков (CPUParticles3D —
## работает на рендерере Compatibility). Использование: Explosion.spawn(pos, color, size)

const LIFETIME := 0.9

var _color := Color.WHITE
var _size := 1.0


static func spawn(at: Vector3, color: Color, size: float = 1.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var root: Node = tree.get_first_node_in_group("fx_root")
	if root == null:
		root = tree.current_scene
	var e := Explosion.new()
	e._color = color
	e._size = size
	root.add_child(e)
	e.global_position = at
	e.reset_physics_interpolation()


func _ready() -> void:
	_spawn_flash()
	_spawn_debris()
	get_tree().create_timer(LIFETIME + 0.3).timeout.connect(queue_free)


func _glow_material(energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.BLACK
	m.emission_enabled = true
	m.emission = _color
	m.emission_energy_multiplier = energy
	return m


func _spawn_flash() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 6
	sphere.material = _glow_material(6.0)
	var flash := MeshInstance3D.new()
	flash.mesh = sphere
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.scale = Vector3.ONE * 0.3 * _size
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "scale", Vector3.ONE * 2.2 * _size, 0.08)
	tw.tween_property(flash, "scale", Vector3.ONE * 0.01, 0.2)


func _spawn_debris() -> void:
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * 0.35
	cube.material = _glow_material(3.0)

	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))

	var p := CPUParticles3D.new()
	p.mesh = cube
	p.amount = int(clampf(16.0 * _size, 6.0, 64.0))
	p.lifetime = LIFETIME
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 5.0 * _size
	p.initial_velocity_max = 16.0 * _size
	p.damping_min = 3.0
	p.damping_max = 7.0
	p.scale_amount_min = 0.5 * _size
	p.scale_amount_max = 1.2 * _size
	p.scale_amount_curve = curve
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	add_child(p)
	p.emitting = true
