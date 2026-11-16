extends Node
## Глобальная шина событий (autoload "Events").
## Системы общаются через сигналы и ничего не знают друг о друге:
## астероид не знает про спавнер, HUD не знает про камеру и т.д.

signal notify(text: String, color: Color)
signal leveled_up(level: int)
signal game_over

signal player_hit(amount: float)
signal player_fired

## Попадание снаряда игрока — для хит-маркера в HUD.
signal target_hit(position: Vector3)
signal enemy_killed(position: Vector3)

## split = true, если астероид должен распасться на осколки.
signal asteroid_destroyed(position: Vector3, velocity: Vector3, tier: int, kind: int, split: bool)
