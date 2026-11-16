extends CanvasLayer
## HUD: полоски топлива/корпуса, статы, уведомления, экран поражения.
## Читает Game, слушает Events. 3D-разметка (прицел, метки врагов) — в hud_overlay.gd.

@onready var fuel_bg: ColorRect = $Root/BarsWrap/FuelBarBG
@onready var fuel_fill: ColorRect = $Root/BarsWrap/FuelBarBG/FuelFill
@onready var hull_bg: ColorRect = $Root/BarsWrap/HullBarBG
@onready var hull_fill: ColorRect = $Root/BarsWrap/HullBarBG/HullFill
@onready var score_label: Label = $Root/Stats/ScoreLabel
@onready var level_label: Label = $Root/Stats/LevelLabel
@onready var kills_label: Label = $Root/Stats/KillsLabel
@onready var speed_label: Label = $Root/Stats/SpeedLabel
@onready var assist_label: Label = $Root/Stats/AssistLabel
@onready var notice_label: Label = $Root/NoticeLabel
@onready var warn_label: Label = $Root/WarnLabel
@onready var game_over_panel: ColorRect = $Root/GameOverPanel
@onready var final_score_label: Label = $Root/GameOverPanel/VBox/FinalScoreLabel
@onready var final_level_label: Label = $Root/GameOverPanel/VBox/FinalLevelLabel
@onready var restart_button: Button = $Root/GameOverPanel/VBox/RestartButton

const NOTICE_TIME := 1.6
const MOVE_ACTIONS: Array[StringName] = [
	&"move_forward", &"move_back", &"strafe_left", &"strafe_right", &"strafe_up", &"strafe_down"]

var _notice_timer := 0.0


func _ready() -> void:
	Events.notify.connect(_on_notify)
	Events.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	game_over_panel.visible = false
	warn_label.modulate.a = 0.0
	notice_label.modulate.a = 0.0


func _process(delta: float) -> void:
	fuel_fill.size.x = fuel_bg.size.x * (Game.fuel / Game.max_fuel)
	hull_fill.size.x = hull_bg.size.x * (Game.hull / Game.max_hull)
	score_label.text = "Очки: %d" % int(Game.score)
	level_label.text = "Уровень: %d" % Game.level
	kills_label.text = "Убито пиратов: %d" % Game.kills

	var player := get_tree().get_first_node_in_group("player") as PlayerShip
	if player:
		speed_label.text = "Скорость: %d м/с" % int(player.velocity.length())
		assist_label.text = "Ассистент: " + ("ВКЛ" if player.flight_assist else "ВЫКЛ (дрифт)")

	var moving := false
	for action in MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			moving = true
			break
	warn_label.modulate.a = 1.0 if (not Game.has_fuel() and moving) else 0.0

	if _notice_timer > 0.0:
		_notice_timer -= delta
		notice_label.modulate.a = clampf(_notice_timer / NOTICE_TIME, 0.0, 1.0)


func _on_notify(text: String, color: Color) -> void:
	notice_label.text = text
	notice_label.modulate = Color(color.r, color.g, color.b, 1.0)
	_notice_timer = NOTICE_TIME


func _on_game_over() -> void:
	final_score_label.text = "Финальный счёт: %d" % int(Game.score)
	final_level_label.text = "Достигнутый уровень: %d" % Game.level
	game_over_panel.visible = true


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
