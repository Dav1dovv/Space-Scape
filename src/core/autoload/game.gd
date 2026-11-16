extends Node
## Состояние забега (autoload "Game").
## Только данные и правила прогрессии — никаких ссылок на сцены.

const SCORE_PER_LEVEL := 150.0

var score := 0.0
var level := 1
var fuel := 100.0
var max_fuel := 100.0
var hull := 100.0
var max_hull := 100.0
var kills := 0
var is_over := false


func _ready() -> void:
	InputSetup.register()


func reset() -> void:
	score = 0.0
	level = 1
	fuel = 100.0
	max_fuel = 100.0
	hull = 100.0
	max_hull = 100.0
	kills = 0
	is_over = false


func add_score(amount: float) -> void:
	if is_over:
		return
	score += amount
	var new_level := int(score / SCORE_PER_LEVEL) + 1
	if new_level > level:
		level = new_level
		max_fuel += 10.0
		max_hull += 10.0
		fuel = minf(fuel + 15.0, max_fuel)
		hull = minf(hull + 15.0, max_hull)
		Events.leveled_up.emit(level)
		Events.notify.emit("УРОВЕНЬ %d — СИСТЕМЫ УЛУЧШЕНЫ" % level, Color(1.0, 0.67, 0.25))


func register_kill() -> void:
	kills += 1
	add_score(40.0)


func has_fuel() -> bool:
	return fuel > 0.0


func consume_fuel(amount: float) -> void:
	fuel = maxf(fuel - amount, 0.0)


func add_fuel(amount: float) -> void:
	fuel = clampf(fuel + amount, 0.0, max_fuel)


func add_hull(amount: float) -> void:
	hull = clampf(hull + amount, 0.0, max_hull)


func damage_player(amount: float) -> void:
	if is_over:
		return
	hull = maxf(hull - amount, 0.0)
	if hull <= 0.0:
		is_over = true
		Events.game_over.emit()


func bullet_damage() -> float:
	return 10.0 + float(level - 1) * 2.0
