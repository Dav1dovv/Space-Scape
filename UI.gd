extends CanvasLayer

@onready var fuel_bg: ColorRect = $Root/BarsWrap/FuelBarBG
@onready var fuel_fill: ColorRect = $Root/BarsWrap/FuelBarBG/FuelFill
@onready var hull_bg: ColorRect = $Root/BarsWrap/HullBarBG
@onready var hull_fill: ColorRect = $Root/BarsWrap/HullBarBG/HullFill
@onready var score_label: Label = $Root/Stats/ScoreLabel
@onready var level_label: Label = $Root/Stats/LevelLabel
@onready var kills_label: Label = $Root/Stats/KillsLabel
@onready var notice_label: Label = $Root/NoticeLabel
@onready var warn_label: Label = $Root/WarnLabel
@onready var game_over_panel: ColorRect = $Root/GameOverPanel
@onready var final_score_label: Label = $Root/GameOverPanel/VBox/FinalScoreLabel
@onready var final_level_label: Label = $Root/GameOverPanel/VBox/FinalLevelLabel
@onready var restart_button: Button = $Root/GameOverPanel/VBox/RestartButton

var notice_timer := 0.0

func _ready() -> void:
	GameState.notify_text.connect(_on_notify)
	GameState.game_over_triggered.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	game_over_panel.visible = false
	warn_label.modulate.a = 0.0
	notice_label.modulate.a = 0.0

func _process(delta: float) -> void:
	fuel_fill.size.x = fuel_bg.size.x * (GameState.fuel / GameState.max_fuel)
	hull_fill.size.x = hull_bg.size.x * (GameState.hull / GameState.max_hull)
	score_label.text = "Очки: %d" % int(GameState.score)
	level_label.text = "Уровень: %d" % GameState.level
	kills_label.text = "Убито пиратов: %d" % GameState.kills

	var moving = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
		or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) \
		or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D)
	warn_label.modulate.a = 1.0 if (GameState.fuel <= 0 and moving) else 0.0

	if notice_timer > 0:
		notice_timer -= delta
		notice_label.modulate.a = clamp(notice_timer / 1.6, 0.0, 1.0)
	else:
		notice_label.modulate.a = 0.0

func _on_notify(text: String, color: Color) -> void:
	notice_label.text = text
	notice_label.modulate = Color(color.r, color.g, color.b, 1.0)
	notice_timer = 1.6

func _on_game_over() -> void:
	final_score_label.text = "Финальный счёт: %d" % int(GameState.score)
	final_level_label.text = "Достигнутый уровень: %d" % GameState.level
	game_over_panel.visible = true

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
