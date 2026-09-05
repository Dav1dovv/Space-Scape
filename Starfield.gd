extends Node2D

@onready var ship: Node2D = get_node("../Ship")

var stars_far: Array = []
var stars_near: Array = []
const TILE_FAR := 2500.0
const TILE_NEAR := 2000.0

func _ready() -> void:
	randomize()
	for i in range(140):
		stars_far.append(Vector3(randf_range(0, TILE_FAR), randf_range(0, TILE_FAR), randf_range(0.6, 1.8)))
	for i in range(90):
		stars_near.append(Vector3(randf_range(0, TILE_NEAR), randf_range(0, TILE_NEAR), randf_range(0.6, 1.8)))
	z_index = -100

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_layer(stars_far, TILE_FAR, 0.35, Color(1, 1, 1, 0.5))
	_draw_layer(stars_near, TILE_NEAR, 0.7, Color(1, 1, 1, 0.85))

func _draw_layer(stars: Array, tile: float, parallax: float, color: Color) -> void:
	var cam: Vector2 = ship.global_position * parallax
	for s in stars:
		var wx = cam.x + fposmod(s.x - cam.x, tile) - tile / 2.0
		var wy = cam.y + fposmod(s.y - cam.y, tile) - tile / 2.0
		draw_circle(Vector2(wx, wy), s.z, color)
