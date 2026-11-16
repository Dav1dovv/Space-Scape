class_name ShipStats
extends Resource
## Все «ощущения» корабля в одном ресурсе. Геймдизайнер крутит цифры в инспекторе,
## не трогая код. Можно сделать несколько .tres — разные корабли.

@export_group("Тяга, м/с²")
@export var thrust := 38.0
@export var reverse_thrust := 22.0
@export var strafe := 26.0
@export var boost_mult := 1.9

@export_group("Скорость, м/с")
@export var max_speed := 60.0
@export var boost_max_speed := 95.0
## Насколько быстро гасится превышение лимита после форсажа.
@export var overspeed_decay := 35.0

@export_group("Прицел (мышь / правый стик)")
## Радиан на пиксель мыши. Клавиши [ и ] меняют прямо в игре.
@export var mouse_sensitivity := 0.0030
@export var invert_y := false
## Скорость поворота прицела правым стиком, рад/с.
@export var stick_aim_rate := 2.2
## Крен Q/E, рад/с, и как быстро он набирается.
@export var aim_roll_rate := 1.9
@export var aim_roll_accel := 6.0
## Насколько прицел может «убежать» вперёд корабля, градусы.
@export var max_aim_lead_deg := 45.0
## Пушки на подвесе: стреляют в прицел, если он в пределах этого угла от носа.
@export var gun_gimbal_deg := 12.0

@export_group("Вращение корабля, рад/с")
@export var pitch_rate := 2.0
@export var yaw_rate := 1.6
@export var roll_rate := 2.4
## Угловое ускорение — «вес» корабля: плавный разгон и плавная остановка поворота.
@export var angular_accel := 8.0
## Жёсткость доворота к прицелу.
@export var turn_gain := 5.0
## Визуальный крен в поворотах, как у самолёта.
@export var bank_amount := 0.35

@export_group("Ассистент полёта")
## Гашение бокового скольжения: корабль «едет туда, куда смотрит».
@export var assist_lateral_damping := 2.2
## Медленное торможение, когда газ отпущен.
@export var assist_forward_damping := 0.5
@export var brake_damping := 3.5

@export_group("Топливо, ед/с")
@export var fuel_thrust_rate := 6.0
@export var fuel_strafe_rate := 3.5
@export var fuel_boost_rate := 12.0

@export_group("Оружие")
@export var fire_cooldown := 0.11
@export var bullet_speed := 190.0
## Мягкий автодоводка: конус в градусах и дальность.
@export var aim_assist_angle := 4.0
@export var aim_assist_range := 240.0
