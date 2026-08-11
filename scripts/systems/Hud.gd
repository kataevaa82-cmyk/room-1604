class_name Hud
extends CanvasLayer

# Весь экранный интерфейс круга. Принцип: экран не даёт заданий.
# Прицел показывает только «сюда можно смотреть», строка внизу — редкая мысль
# игрока, а не подсказка. Всё остальное игрок читает по самой комнате.

enum Aim { NONE, EXAMINE, USE }

# Обычное место строки сообщений и поднятое — на время осмотра предмета.
#
# Описание предмета в InspectView живёт на bottom-168..-72, а сообщение на
# bottom-150..-72: то есть на одном и том же месте. Пока сообщение рисовалось ПОД
# затемнением осмотра, это было незаметно; после переноса на layer 14 они стали
# налезать друг на друга, и обе строки становились нечитаемыми.
#
# Отсчёт от НИЗА экрана до верха ярлыка. Высота фиксирована, текст в ней
# центрируется по вертикали, поэтому запас на перенос строк заложен сразу: при
# автоподборе высоты ярлык вытягивался вниз (78 объявленных превращались в 111 на
# двух строках) и наползал на описание предмета.
const MESSAGE_WIDTH := 860.0
const MESSAGE_HEIGHT := 150.0
const MESSAGE_Y := -222.0
const MESSAGE_Y_RAISED := -330.0

const DOT_COLOR := Color(1, 1, 1, .55)
const TICK_IDLE := Color(1, 1, 1, .0)
const TICK_EXAMINE := Color(.90, .88, .82, .55)
const TICK_USE := Color(.91, .75, .45, .85)

var ticks: Array[ColorRect] = []
var dot: ColorRect
var prompt: Label
var message_layer: CanvasLayer
var message: Label
var fade: ColorRect
var slots_row: HBoxContainer
var debug_label: Label
var aim_state := Aim.NONE
var message_tween: Tween
var message_raised := false

func _ready() -> void:
	name = "Hud"
	layer = 10
	build_crosshair()
	build_prompt()
	build_message()
	build_inventory_row()
	build_fade()
	build_debug()

func build_crosshair() -> void:
	var root := Control.new()
	root.name = "Crosshair"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.position = Vector2(-16, -16)
	root.size = Vector2(32, 32)
	add_child(root)
	dot = ColorRect.new()
	dot.color = DOT_COLOR
	dot.position = Vector2(15, 15)
	dot.size = Vector2(2, 2)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dot)
	# Четыре штриха, расходящиеся от центра. В покое они прозрачны,
	# поэтому прицел не размечает комнату заранее.
	for i in range(4):
		var tick := ColorRect.new()
		tick.color = TICK_IDLE
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var horizontal := i < 2
		tick.size = Vector2(6, 1) if horizontal else Vector2(1, 6)
		root.add_child(tick)
		ticks.append(tick)
	place_ticks(3.0)

func place_ticks(spread: float) -> void:
	ticks[0].position = Vector2(15.5 - spread - 6.0, 15.5)
	ticks[1].position = Vector2(15.5 + spread, 15.5)
	ticks[2].position = Vector2(15.5, 15.5 - spread - 6.0)
	ticks[3].position = Vector2(15.5, 15.5 + spread)

func set_aim(state: Aim) -> void:
	if state == aim_state:
		return
	aim_state = state
	var color := TICK_IDLE
	var spread := 3.0
	match state:
		Aim.EXAMINE:
			color = TICK_EXAMINE
			spread = 5.0
		Aim.USE:
			color = TICK_USE
			spread = 7.5
	for tick in ticks:
		tick.color = color
	place_ticks(spread)
	prompt.visible = state == Aim.USE

func build_prompt() -> void:
	prompt = Label.new()
	prompt.name = "UsePrompt"
	prompt.text = "[E]"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color("e8c07d"))
	prompt.set_anchors_preset(Control.PRESET_CENTER)
	prompt.position = Vector2(-60, 26)
	prompt.size = Vector2(120, 26)
	prompt.visible = false
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt)

func build_message() -> void:
	# Строка сообщений живёт выше всего остального: выше затемнения осмотра (12),
	# выше панели сейфа (13) и выше собственной чёрной заливки HUD. Иначе
	# подсказка по H во время осмотра уходит под затемнение, а финальный титр —
	# под fade, который строится позже и потому рисуется поверх соседей.
	#
	message_layer = CanvasLayer.new()
	message_layer.name = "MessageLayer"
	message_layer.layer = 14
	add_child(message_layer)
	message = Label.new()
	message.name = "Message"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 25)
	message.add_theme_color_override("font_color", Color("ddd6c8"))
	message.add_theme_color_override("font_shadow_color", Color(0, 0, 0, .9))
	message.add_theme_constant_override("shadow_offset_x", 2)
	message.add_theme_constant_override("shadow_offset_y", 2)
	# Никаких привязок: строка ставится в абсолютных пикселях.
	#
	# Привязка к низу экрана здесь не разрешалась — ярлык оставался на сыром
	# offset (-150 вместо 570) и уезжал за верхнюю границу. Причём подло: строка
	# всё-таки появлялась, пока открыт осмотр или сейф, потому что их
	# полноэкранные слои заставляли разметку пересчитаться. То есть подсказки в
	# обычной игре не показывались вовсе, а на панели сейфа показывались — и
	# заметить это можно было только глядя на кадры прохождения.
	message.set_anchors_preset(Control.PRESET_TOP_LEFT)
	message.modulate.a = 0.0
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_layer.add_child(message)
	place_message()
	get_viewport().size_changed.connect(place_message)

func show_message(text: String, duration := 2.8) -> void:
	if message_tween and message_tween.is_valid():
		message_tween.kill()
	message.text = text
	message_tween = create_tween()
	message_tween.tween_property(message, "modulate:a", 1.0, .3)
	message_tween.tween_interval(duration)
	message_tween.tween_property(message, "modulate:a", 0.0, .5)

func place_message() -> void:
	var view := get_viewport().get_visible_rect().size
	message.size = Vector2(MESSAGE_WIDTH, MESSAGE_HEIGHT)
	message.position = Vector2((view.x - MESSAGE_WIDTH) * .5,
		view.y + (MESSAGE_Y_RAISED if message_raised else MESSAGE_Y))

func set_message_raised(value: bool) -> void:
	message_raised = value
	place_message()

func clear_message() -> void:
	if message_tween and message_tween.is_valid():
		message_tween.kill()
	message.text = ""
	message.modulate.a = 0.0

func build_inventory_row() -> void:
	slots_row = HBoxContainer.new()
	slots_row.name = "InventoryRow"
	slots_row.add_theme_constant_override("separation", 8)
	slots_row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	slots_row.position = Vector2(26, -74)
	slots_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slots_row)

func build_fade() -> void:
	fade = ColorRect.new()
	fade.name = "Fade"
	fade.color = Color.BLACK
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0.0
	add_child(fade)

func build_debug() -> void:
	debug_label = Label.new()
	debug_label.name = "Debug"
	debug_label.position = Vector2(16, 16)
	debug_label.add_theme_font_size_override("font_size", 15)
	debug_label.visible = false
	debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(debug_label)

func reset() -> void:
	clear_message()
	set_message_raised(false)
	fade.modulate.a = 0.0
	set_aim(Aim.NONE)
	prompt.visible = false
