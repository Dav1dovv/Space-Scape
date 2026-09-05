extends Area2D

@onready var thruster: Line2D = $ThrusterFlame
@onready var body: Line2D = $Body

const BulletScene := preload("res://entities/Bullet.tscn")

var velocity := Vector2.ZERO

const THRUST_FORCE := 230.0
const WASD_FORCE := 170.0
const BOOST_MULT := 1.9
const FRICTION := 0.992
const MAX_SPEED := 520.0
const FUEL_THRUST_RATE := 9.0
const FUEL_WASD_RATE := 5.5
const FUEL_BOOST_RATE := 14.0
const FIRE_COOLDOWN := 0.17
const BULLET_SPEED := 760.0

var fire_timer := 0.0
var invuln_timer := 0.0

func _ready() -> void:
	add_to_group("player")
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if GameState.game_over:
		return

	var to_mouse = get_global_mouse_position() - global_position
	rotation = to_mouse.angle()

	var accel := Vector2.ZERO
	var moving := false

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and GameState.fuel > 0:
		accel += Vector2(cos(rotation), sin(rotation)) * THRUST_FORCE
		GameState.fuel -= FUEL_THRUST_RATE * delta
		moving = true

	var wasd := false
	if GameState.fuel > 0:
		if Input.is_key_pressed(KEY_W):
			accel.y -= WASD_FORCE
			wasd = true
		if Input.is_key_pressed(KEY_S):
			accel.y += WASD_FORCE
			wasd = true
		if Input.is_key_pressed(KEY_A):
			accel.x -= WASD_FORCE
			wasd = true
		if Input.is_key_pressed(KEY_D):
			accel.x += WASD_FORCE
			wasd = true
	if wasd:
		GameState.fuel -= FUEL_WASD_RATE * delta
		moving = true

	if Input.is_key_pressed(KEY_SPACE) and GameState.fuel > 0 and moving:
		accel *= BOOST_MULT
		GameState.fuel -= FUEL_BOOST_RATE * delta

	GameState.fuel = clamp(GameState.fuel, 0.0, GameState.max_fuel)

	velocity += accel * delta

	if Input.is_key_pressed(KEY_SHIFT):
		velocity *= pow(0.9, delta * 60.0)

	velocity *= pow(FRICTION, delta * 60.0)
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED

	global_position += velocity * delta

	thruster.visible = moving and GameState.fuel > 0
	if thruster.visible:
		_flicker_thruster()

	fire_timer -= delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and fire_timer <= 0:
		fire_timer = FIRE_COOLDOWN
		_fire()

	if invuln_timer > 0:
		invuln_timer -= delta
	body.default_color = Color(1.0, 0.4, 0.4) if (invuln_timer > 0 and int(invuln_timer * 20) % 2 == 0) else Color(0.3, 0.85, 1.0)

func _flicker_thruster() -> void:
	var jitter = randf_range(0, 8)
	thruster.points = PackedVector2Array([Vector2(-6, 0), Vector2(-16 - jitter, 4), Vector2(-16 - jitter, -4)])

func _fire() -> void:
	var b = BulletScene.instantiate()
	get_tree().current_scene.get_node("Entities").add_child(b)
	b.global_position = global_position + Vector2(cos(rotation), sin(rotation)) * 18.0
	b.velocity = Vector2(cos(rotation), sin(rotation)) * BULLET_SPEED + velocity * 0.3
	b.damage = GameState.bullet_damage()

func take_damage(amount: float) -> void:
	if invuln_timer > 0 or GameState.game_over:
		return
	GameState.hull -= amount
	invuln_timer = 0.5
	if GameState.hull <= 0:
		GameState.hull = 0
		GameState.trigger_game_over()

func _on_area_entered(area: Area2D) -> void:
	if GameState.game_over:
		return
	if area.is_in_group("asteroids"):
		take_damage(area.radius * 0.55)
		var kb = (global_position - area.global_position).normalized()
		velocity += kb * 140.0
		area.destroy(true)
	elif area.is_in_group("pirates"):
		take_damage(16.0)
	elif area.is_in_group("pirate_bullets"):
		take_damage(8.0)
		area.queue_free()
