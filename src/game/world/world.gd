extends Node3D
## Корневая сцена забега. Только жизненный цикл и режим мыши —
## вся логика живёт в системах (Spawner, ChaseCamera, HUD) и акторах.


func _ready() -> void:
	Game.reset()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Events.game_over.connect(_on_game_over)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not Game.is_over:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _on_game_over() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
