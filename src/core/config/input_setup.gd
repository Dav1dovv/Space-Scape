class_name InputSetup
extends RefCounted
## Регистрирует действия ввода в коде, чтобы project.godot оставался чистым.
## Клавиши — по physical_keycode, поэтому работают на любой раскладке (RU/EN/AM).
## Если действие уже настроено в Project Settings → Input Map, оно не перезаписывается.


static func register() -> void:
	# --- Перемещение (3 оси) ---
	_bind("move_forward", [KEY_W], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_bind("move_back", [KEY_S], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_bind("strafe_left", [KEY_A], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind("strafe_right", [KEY_D], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind("strafe_up", [KEY_SPACE], [JOY_BUTTON_DPAD_UP], [])
	_bind("strafe_down", [KEY_CTRL, KEY_C], [JOY_BUTTON_DPAD_DOWN], [])

	# --- Вращение (3 оси). Тангаж/рыскание — мышь двигает прицел, плюс правый стик ---
	_bind("roll_left", [KEY_Q], [JOY_BUTTON_LEFT_SHOULDER], [])
	_bind("roll_right", [KEY_E], [JOY_BUTTON_RIGHT_SHOULDER], [])
	_bind("look_left", [], [], [[JOY_AXIS_RIGHT_X, -1.0]])
	_bind("look_right", [], [], [[JOY_AXIS_RIGHT_X, 1.0]])
	_bind("look_up", [], [], [[JOY_AXIS_RIGHT_Y, -1.0]])
	_bind("look_down", [], [], [[JOY_AXIS_RIGHT_Y, 1.0]])

	# --- Системы ---
	_bind("boost", [KEY_SHIFT], [], [[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	_bind("brake", [KEY_X], [JOY_BUTTON_X], [])
	_bind("toggle_assist", [KEY_Z], [JOY_BUTTON_Y], [])
	_bind("recenter_aim", [KEY_R], [JOY_BUTTON_RIGHT_STICK], [], [MOUSE_BUTTON_MIDDLE])
	_bind("fire", [], [], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]], [MOUSE_BUTTON_LEFT])
	_bind("sensitivity_down", [KEY_BRACKETLEFT], [], [])
	_bind("sensitivity_up", [KEY_BRACKETRIGHT], [], [])


static func _bind(action: StringName, keys: Array, joy_buttons: Array, joy_axes: Array, mouse_buttons: Array = []) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.2)
	for key in keys:
		var e := InputEventKey.new()
		e.physical_keycode = key
		InputMap.action_add_event(action, e)
	for button in joy_buttons:
		var e := InputEventJoypadButton.new()
		e.button_index = button
		InputMap.action_add_event(action, e)
	for axis in joy_axes:
		var e := InputEventJoypadMotion.new()
		e.axis = axis[0]
		e.axis_value = axis[1]
		InputMap.action_add_event(action, e)
	for button in mouse_buttons:
		var e := InputEventMouseButton.new()
		e.button_index = button
		InputMap.action_add_event(action, e)
