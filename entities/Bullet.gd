extends Area2D

var velocity := Vector2.ZERO
var damage := 10.0
var ttl := 1.1

func _ready() -> void:
	add_to_group("player_bullets")
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	ttl -= delta
	if ttl <= 0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("asteroids") or area.is_in_group("pirates"):
		area.take_damage(damage)
		queue_free()
