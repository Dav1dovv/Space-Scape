extends Area2D

var velocity := Vector2.ZERO
var ttl := 1.4

func _ready() -> void:
	add_to_group("pirate_bullets")

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	ttl -= delta
	if ttl <= 0:
		queue_free()
