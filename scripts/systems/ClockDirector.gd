class_name ClockDirector
extends Node

# Часы в гостиной — единственный явный индикатор прогресса во всём круге.
#
# 16:04:00 -> 16:05:00. Шестьдесят секунд на циферблате = весь уровень.
# Каждое верное действие толкает стрелку вперёд, застой отматывает её назад.
# Игрок всегда видит цель, не читая ни одной подсказки.

signal advanced(amount: float)
signal rewound(amount: float)
signal minute_reached()

const SPAN := 60.0
const IDLE_BEFORE_DRIFT := 32.0
const DRIFT_RATE := 0.55
const DRIFT_FLOOR_MARGIN := 6.0

var display: Label3D
var glow: OmniLight3D
var cue: CueAudio
var value := 0.0
var running := false
var pressure := false
var idle_time := 0.0
var floor_value := 0.0
var finished := false
var moving := false
# Потолок текущего акта. Мелкие награды за возню с предметами не должны
# доводить минуту раньше сюжета: у стрелки всегда остаётся запас до развязки.
var ceiling := SPAN
# Какую минуту показывает циферблат. У Круга I это 16:04 → 16:05, у Круга II
# 16:05 → 16:06: расчётный час уже прошёл. Раньше подписи были вписаны в refresh()
# намертво, и второй круг показывал бы время первого.
var start_label := "16:04"
var end_label := "16:05"

func setup(clock_display: Label3D, clock_glow: OmniLight3D, audio: CueAudio) -> void:
	name = "ClockDirector"
	display = clock_display
	glow = clock_glow
	cue = audio
	reset()

func reset() -> void:
	value = 0.0
	floor_value = 0.0
	idle_time = 0.0
	running = false
	pressure = false
	finished = false
	moving = false
	ceiling = SPAN
	refresh()

func start() -> void:
	running = true

# Давление включается только со второго акта: в первом игрок ещё осваивается.
func set_pressure(enabled: bool) -> void:
	pressure = enabled
	idle_time = 0.0

func advance(amount: float, reason := "") -> void:
	if finished or amount <= 0.0:
		return
	idle_time = 0.0
	var target := minf(value + amount, minf(ceiling, SPAN))
	if target <= value + 0.001:
		return
	# Отмотать ниже уже достигнутой ступени нельзя: ошибка давит, но не отнимает
	# сделанное. Игрок никогда не теряет решённую задачу.
	floor_value = maxf(floor_value, target - DRIFT_FLOOR_MARGIN)
	slide_to(target, .55)
	if cue:
		cue.play("tick", 2.0)
	pulse(Color("f0d59a"), .85)
	advanced.emit(amount)
	if not reason.is_empty():
		set_meta("last_reason", reason)

# Финальный добег: оставшиеся секунды проходят на глазах у игрока за
# заданное время. Это и есть замена прежнему восьмисекундному ожиданию.
func run_out(duration: float) -> void:
	if finished:
		return
	idle_time = 0.0
	ceiling = SPAN
	floor_value = SPAN
	slide_to(SPAN, duration)

func rewind(amount: float) -> void:
	if finished or amount <= 0.0:
		return
	var target := maxf(value - amount, floor_value)
	if is_equal_approx(target, value):
		return
	slide_to(target, .9)
	if cue:
		cue.play("rewind", -2.0)
	pulse(Color("8892a8"), .5)
	rewound.emit(amount)

func slide_to(target: float, duration: float) -> void:
	moving = true
	var tween := create_tween()
	tween.tween_method(set_value, value, target, duration).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func() -> void:
		moving = false
		if value >= SPAN - 0.001 and not finished:
			finished = true
			minute_reached.emit()
	)

func set_value(new_value: float) -> void:
	value = new_value
	refresh()

func refresh() -> void:
	if not display:
		return
	if value >= SPAN - 0.001:
		display.text = "%s:00" % end_label
	else:
		display.text = "%s:%02d" % [start_label, int(floor(value))]

func pulse(color: Color, energy: float) -> void:
	if not glow:
		return
	glow.light_color = color
	glow.visible = true
	glow.light_energy = energy
	var tween := create_tween()
	tween.tween_property(glow, "light_energy", 0.0, .7)
	tween.finished.connect(func() -> void: glow.visible = false)

func _process(delta: float) -> void:
	if not running or finished or moving or not pressure:
		return
	idle_time += delta
	if idle_time < IDLE_BEFORE_DRIFT:
		return
	var target := maxf(value - DRIFT_RATE * delta, floor_value)
	if is_equal_approx(target, value):
		return
	set_value(target)

func remaining() -> float:
	return SPAN - value

func progress() -> float:
	return value / SPAN
