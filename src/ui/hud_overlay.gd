extends Control
## Разметка поверх 3D: кольцо прицела, перекрестие пушек (куда реально летят пули),
## захват автодоводки, рамки пиратов с HP и стрелки на пиратов за краем экрана.
## В 3D без этих подсказок игрок теряется — это главный инструмент читаемости.

const RETICLE_DISTANCE := 150.0
const EDGE_MARGIN := 48.0
const UI_COLOR := Color(0.81, 0.91, 1.0)
const ENEMY_COLOR := Color(1.0, 0.36, 0.36)
const LOCK_COLOR := Color(1.0, 0.67, 0.25)

var _hit_flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Events.target_hit.connect(func(_p: Vector3) -> void: _hit_flash = 0.15)


func _process(delta: float) -> void:
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	var player := get_tree().get_first_node_in_group("player") as PlayerShip
	if cam == null or player == null or Game.is_over:
		return
	var center := size * 0.5
	_draw_reticles(cam, player)
	for node in get_tree().get_nodes_in_group("pirates"):
		_draw_enemy(cam, node as PirateShip, center)


## Кольцо — куда смотрит прицел (туда поворачивает корабль).
## Перекрестие — куда реально летят пули (пушки на подвесе, с упреждением).
## Когда они совпадают — корабль «довернулся», можно стрелять точно.
func _draw_reticles(cam: Camera3D, player: PlayerShip) -> void:
	var origin := player.global_position
	var aim_world := origin + player.aim_forward() * RETICLE_DISTANCE
	if not cam.is_position_behind(aim_world):
		draw_arc(cam.unproject_position(aim_world), 16.0, 0.0, TAU, 40, Color(UI_COLOR, 0.45), 1.5, true)

	var gun_world := origin + player.fire_direction() * RETICLE_DISTANCE
	if not cam.is_position_behind(gun_world):
		var p := cam.unproject_position(gun_world)
		var c := Color(UI_COLOR, 0.9)
		for dir: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			draw_line(p + dir * 5.0, p + dir * 11.0, c, 2.0, true)
		if _hit_flash > 0.0:
			var k := 10.0 + (0.15 - _hit_flash) * 40.0
			for d: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				draw_line(p + d * k * 0.5, p + d * k, Color.WHITE, 2.0, true)

	if is_instance_valid(player.aim_target) and not cam.is_position_behind(player.aim_target.global_position):
		var t := cam.unproject_position(player.aim_target.global_position)
		var s := 18.0
		draw_polyline(PackedVector2Array([
			t + Vector2(0, -s), t + Vector2(s, 0), t + Vector2(0, s), t + Vector2(-s, 0), t + Vector2(0, -s)]),
			LOCK_COLOR, 1.5, true)


func _draw_enemy(cam: Camera3D, enemy: PirateShip, center: Vector2) -> void:
	var pos := enemy.global_position
	var safe := Rect2(Vector2.ZERO, size).grow(-EDGE_MARGIN)
	var behind := cam.is_position_behind(pos)
	var sp := cam.unproject_position(pos)

	if not behind and safe.has_point(sp):
		var dist := cam.global_position.distance_to(pos)
		var r := clampf(900.0 / dist, 10.0, 42.0)
		var l := r * 0.45
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var c := sp + corner * r
			draw_line(c, c - Vector2(corner.x * l, 0), ENEMY_COLOR, 1.5)
			draw_line(c, c - Vector2(0, corner.y * l), ENEMY_COLOR, 1.5)
		var bar := Rect2(sp + Vector2(-r, r + 6.0), Vector2(r * 2.0, 3.0))
		draw_rect(bar, Color(1, 1, 1, 0.15))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * enemy.hp / enemy.max_hp, bar.size.y)), ENEMY_COLOR)
		draw_string(get_theme_default_font(), sp + Vector2(r + 4.0, 4.0), "%dм" % int(dist),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(ENEMY_COLOR, 0.8))
		return

	# Цель за краем экрана или сзади — стрелка на краю
	var local := cam.global_basis.inverse() * (pos - cam.global_position)
	var d := Vector2(local.x, -local.y)
	d = Vector2.DOWN if d.length_squared() < 0.0001 else d.normalized()
	var half := safe.size * 0.5
	var t := minf(half.x / maxf(absf(d.x), 0.001), half.y / maxf(absf(d.y), 0.001))
	var p := center + d * t
	var perp := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([p + d * 10.0, p - d * 6.0 + perp * 8.0, p - d * 6.0 - perp * 8.0]), ENEMY_COLOR)
