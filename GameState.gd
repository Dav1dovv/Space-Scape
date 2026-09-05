extends Node

signal leveled_up(new_level)
signal notify_text(text, color)
signal game_over_triggered

var score := 0.0
var level := 1
var fuel := 100.0
var max_fuel := 100.0
var hull := 100.0
var max_hull := 100.0
var kills := 0
var game_over := false

func add_score(amount: float) -> void:
	score += amount
	var new_level = int(score / 150.0) + 1
	if new_level > level:
		level = new_level
		max_fuel += 10.0
		max_hull += 10.0
		fuel = min(fuel + 15.0, max_fuel)
		hull = min(hull + 15.0, max_hull)
		leveled_up.emit(level)
		notify_text.emit("УРОВЕНЬ %d — СИСТЕМЫ УЛУЧШЕНЫ" % level, Color(1.0, 0.67, 0.25))

func bullet_damage() -> float:
	return 10.0 + float(level - 1) * 2.0

func trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	game_over_triggered.emit()

func reset() -> void:
	score = 0.0
	level = 1
	fuel = 100.0
	max_fuel = 100.0
	hull = 100.0
	max_hull = 100.0
	kills = 0
	game_over = false
