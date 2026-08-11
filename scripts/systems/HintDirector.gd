class_name HintDirector
extends Node

# Подсказки круга.
#
# После первого живого прогона владелец попросил подсказок больше, поэтому
# прежний режим «только среда» снят: теперь каждая ступень говорит словами и
# делает это заметно раньше. Три ступени идут от намёка к прямому указанию,
# последняя повторяется, и в любой момент подсказку можно вызвать клавишей H.

# Ступени укорочены дважды по просьбе владельца: сначала 20/45/80, теперь так.
# Восемьдесят секунд молчания — это очень долго, если ты уже не понимаешь, что
# делать; к этому моменту игрок успевает решить, что игра сломана.
const SOFT := 12.0
const CLEAR := 28.0
const OBVIOUS := 55.0
const REPEAT := 25.0

var hud: Hud
var cue: CueAudio
var focus_point := Vector3.ZERO
var focus_lights: Array = []
var texts: Array = []
var idle := 0.0
var stage := 0
var repeat_at := 0.0
var enabled := false
# Пока открыт осмотр или сейф, игрок занят и никуда не застрял, а строка
# сообщений теперь рисуется поверх затемнения и наезжала бы на описание вещи.
# Таймер на это время замирает; клавиша H всё равно работает — явную просьбу
# игрока молчанием не встречают.
var paused := false

func setup(target_hud: Hud, audio: CueAudio) -> void:
	name = "HintDirector"
	hud = target_hud
	cue = audio

# texts — три строки: намёк, ясное указание, прямое. Уровень задаёт их вместе
# с точкой, куда смотреть, и светом той комнаты.
func set_focus(point: Vector3, hint_texts: Array = [], lights: Array = []) -> void:
	focus_point = point
	texts = hint_texts
	focus_lights = lights
	reset_timer()

func clear_focus() -> void:
	focus_lights = []
	texts = []
	enabled = false
	reset_timer()

func set_enabled(value: bool) -> void:
	enabled = value
	reset_timer()

func reset_timer() -> void:
	idle = 0.0
	stage = 0
	repeat_at = 0.0

func set_paused(value: bool) -> void:
	paused = value

func _process(delta: float) -> void:
	if not enabled or paused:
		return
	idle += delta
	var next := 3 if idle >= OBVIOUS else (2 if idle >= CLEAR else (1 if idle >= SOFT else 0))
	if next > stage:
		show_stage(next)
		return
	# Последнюю ступень повторяем: единственный показ могли пропустить, стоя
	# спиной, и круг вставал бы намертво.
	if stage >= 3 and idle >= repeat_at:
		repeat_at = idle + REPEAT
		show_stage(3)

# Вызов по клавише H: следующая ступень немедленно, без ожидания.
#
# Возвращает false, когда сказать нечего нового: либо подсказок для этого места
# нет вовсе, либо самая прямая ступень уже показана. Тогда отвечает уровень — он
# знает акт и счётчики и может назвать цель прямым текстом. Раньше H в этих
# окнах молчала совсем, и это выглядело так, будто клавиша не работает.
func request() -> bool:
	if not enabled or texts.is_empty() or stage >= 3:
		return false
	show_stage(stage + 1)
	return true

# Подсветить предмет, ничего не говоря: уровень сам скажет словами.
func emphasize() -> void:
	glow()

func show_stage(value: int) -> void:
	stage = maxi(stage, value)
	if value >= 3:
		repeat_at = idle + REPEAT
	var index := value - 1
	if index >= 0 and index < texts.size() and hud:
		hud.show_message(str(texts[index]), 4.0 if value >= 2 else 3.2)
	match value:
		2: flicker()
		3: glow()

func flicker() -> void:
	for light: Light3D in focus_lights:
		if not is_instance_valid(light):
			continue
		var base := light.light_energy
		var tween := create_tween()
		tween.tween_property(light, "light_energy", base * .12, .09)
		tween.tween_property(light, "light_energy", base, .13)
		tween.tween_property(light, "light_energy", base * .25, .07)
		tween.tween_property(light, "light_energy", base, .22)

# Прямая ступень: предмет подсвечивается сам, чтобы его нельзя было не заметить.
func glow() -> void:
	if focus_point == Vector3.ZERO:
		return
	var light := OmniLight3D.new()
	light.name = "HintGlow"
	light.light_color = Color("e8c98d")
	light.light_energy = 0.0
	light.omni_range = 1.45
	light.shadow_enabled = false
	light.position = focus_point
	add_child(light)
	var tween := create_tween()
	tween.tween_property(light, "light_energy", .9, .7)
	tween.tween_property(light, "light_energy", .0, 1.9)
	tween.finished.connect(light.queue_free)

func clear() -> void:
	clear_focus()
	paused = false
	for light in find_children("HintGlow", "OmniLight3D", true, false):
		light.queue_free()
