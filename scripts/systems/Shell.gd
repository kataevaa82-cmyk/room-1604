class_name Shell
extends CanvasLayer

# Всё, что вокруг круга: главное меню, выбор круга, пауза, переход между
# кругами и финал.
#
# Почему это ОТДЕЛЬНЫЙ CanvasLayer, а не часть Hud: аудит всех девяти кругов
# проверяет положение строки подсказок (`CircleLevel.message_on_screen()` →
# `hud.message.position`). Любая кнопка, добавленная в слои Hud, перекладывает
# его разметку и роняет проверку сразу во всех девяти. Оболочка живёт выше
# всего HUD (10..14) и его узлов не касается.
#
# Про переключение кругов: оно идёт полной перезагрузкой сцены, а не подменой
# уровня. Причина — в Game.gd; коротко: уровни правят саму комнату и за собой
# не убирают.

const LAYER := 20

# Названия кругов для экранов. Порядковый номер римскими — как в документах.
const CIRCLES := {
	1: ["I", "ЛИМБ", "Комната просыпается"],
	2: ["II", "УРАГАН", "Комната не унимается"],
	3: ["III", "НЕНАСЫТНОСТЬ", "Комната переполнена"],
	4: ["IV", "СКУПОСТЬ", "Комната в долгах"],
	5: ["V", "ГНЕВ", "Комната после ссоры"],
	6: ["VI", "ЕРЕСЬ", "Комната заперта изнутри"],
	7: ["VII", "НАСИЛИЕ", "Комната сжала кулак"],
	8: ["VIII", "ОБМАН", "Комната притворяется"],
	9: ["IX", "ПРЕДАТЕЛЬСТВО", "Комната выстыла"]
}

const CREAM := Color("ddd6c8")
const AMBER := Color("e8c07d")
const DIM := Color(.62, .60, .55)

# Сколько держится экран перехода. Это ПОТОЛОК, а не ожидание рекламы:
# закрытие ролика только сокращает время, но зависший ролик не может оставить
# игрока на экране перехода навсегда.
const TRANSITION_SECONDS := 4.6
# Сколько экран перехода держится в любом случае. Ролик, который не показался,
# рапортует о завершении мгновенно, и без этого порога игрок проскочил бы
# «КРУГ III ПРОЙДЕН», не успев прочитать.
const TRANSITION_MIN_READ := 1.8

enum Screen { NONE, MENU, CIRCLES_LIST, PAUSE, TRANSITION, FINALE }

var screen := Screen.NONE
var root: Control
var backdrop: ColorRect
var title: Label
var subtitle: Label
var buttons: VBoxContainer
var footer: Label

# Обратный отсчёт до следующего круга. Ноль и меньше — не идёт.
var countdown := 0.0
var pending_circle := 0
var finished_circle := 0
var advancing := false
# Показывается ли сейчас ролик. Нужен только чтобы уйти РАНЬШЕ таймера, когда
# игрок закрыл рекламу: удлинить ожидание этот флаг не может.
var waiting_for_ad := false

# Круг, который сейчас собран в сцене.
var circle := 1

# HUD круга. Оболочка его прячет, пока показывает свой экран: слои Hud (10–14)
# лежат ниже оболочки (20), но её подложка полупрозрачна, и сквозь неё
# просвечивали и слот инвентаря, и заголовок круга — два заголовка на экране
# разом. Прячем целиком сам CanvasLayer: его узлов оболочка при этом не
# касается, и разметка строки подсказок остаётся нетронутой (на ней держится
# message_on_screen() во всех девяти аудитах).
var hud: CanvasLayer

func setup(circle_number: int, circle_hud: CanvasLayer = null) -> void:
	name = "Shell"
	layer = LAYER
	# Оболочка обязана работать на паузе: на паузе её и показывают.
	process_mode = Node.PROCESS_MODE_ALWAYS
	circle = circle_number
	hud = circle_hud
	build()

# Обращение к слою площадки, если он есть. Вне веба и без SDK всё это молчит,
# и ни один игровой путь от ответа площадки не зависит.
func platform_call(method: String) -> void:
	if not has_node("/root/Platform"):
		return
	var platform := get_node("/root/Platform")
	if platform.has_method(method):
		platform.call(method)

# Показан ли сейчас хоть какой-нибудь экран оболочки. Спрашивает сенсорное
# управление, чтобы не вести игрока по комнате пальцем по кнопке меню.
func is_open() -> bool:
	return screen != Screen.NONE

func set_hud_visible(value: bool) -> void:
	if not hud or not is_instance_valid(hud):
		return
	hud.visible = value
	# Дочерний CanvasLayer — самостоятельный слой отрисовки, и видимость
	# родителя на него НЕ распространяется. Строка сообщений живёт именно в
	# таком (Hud.message_layer, слой 14), поэтому без этого прохода заголовок
	# круга просвечивал сквозь экран перехода: два заголовка разом.
	for child in hud.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = value

func build() -> void:
	root = Control.new()
	root.name = "ShellRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	backdrop = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.02, 0.02, 0.03, 0.93)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column)

	title = make_label("", 46, AMBER)
	column.add_child(title)
	subtitle = make_label("", 21, DIM)
	column.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)

	buttons = VBoxContainer.new()
	buttons.name = "Buttons"
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(buttons)

	footer = make_label("", 16, DIM)
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.position = Vector2(0, -46)
	root.add_child(footer)

	hide_all()

func make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, .9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

# Кнопки крупные намеренно: этой же оболочкой пользуются с телефона пальцем,
# а не мышью. Меньше 44 пикселей по высоте на сенсоре не попасть.
func make_button(text: String, enabled := true) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 52)
	# custom_minimum_size задаёт минимум, а не максимум: без сжатия по центру
	# кнопка растягивается во всю ширину экрана и выглядит полосой.
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", CREAM if enabled else Color(.45, .43, .40))
	button.add_theme_color_override("font_hover_color", AMBER)
	button.add_theme_color_override("font_pressed_color", AMBER)
	button.disabled = not enabled
	return button

# Отцепляем сразу, а не только queue_free(): освобождение отложено до конца
# кадра, и следующий экран успел бы построиться рядом со старыми кнопками.
func clear_buttons() -> void:
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()

# ------------------------------------------------------------------ экраны ---

func hide_all() -> void:
	screen = Screen.NONE
	root.visible = false
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_hud_visible(true)
	get_tree().paused = false
	capture_mouse(true)
	# Геймплей начался по-настоящему: экранов оболочки больше нет.
	platform_call("gameplay_start")

func open(new_screen: Screen) -> void:
	screen = new_screen
	root.visible = true
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	set_hud_visible(false)
	# Любой экран оболочки — это не геймплей: меню, пауза, переход, финал.
	# Требование площадки — чтобы границы совпадали с настоящей игрой.
	platform_call("gameplay_stop")
	# Пауза — не для красоты: круг за меню продолжал бы отматывать часы назад,
	# а игрок этого не видит и повлиять не может.
	get_tree().paused = new_screen != Screen.TRANSITION and new_screen != Screen.FINALE
	capture_mouse(false)

# Мышь захватывается только в игре. В вебе захват всё равно требует жеста
# пользователя, поэтому promise-ошибку тут ловить нечего — просто просим.
func capture_mouse(playing: bool) -> void:
	if not Game.has_screen():
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if playing else Input.MOUSE_MODE_VISIBLE

func show_main_menu() -> void:
	open(Screen.MENU)
	title.text = "КОМНАТА 1604"
	subtitle.text = "Девять кругов. Одна и та же комната."
	clear_buttons()

	if Game.has_progress():
		var row: Array = CIRCLES.get(Game.current_circle, CIRCLES[1])
		var resume := make_button("Продолжить — круг %s, %s" % [str(row[0]), str(row[1])])
		resume.pressed.connect(func() -> void: start_circle(Game.current_circle))
		buttons.add_child(resume)

	var fresh := make_button("Начать заново" if Game.has_progress() else "Начать игру")
	fresh.pressed.connect(func() -> void:
		if Game.has_progress():
			confirm_restart()
		else:
			start_circle(1))
	buttons.add_child(fresh)

	var choose := make_button("Выбрать круг")
	choose.pressed.connect(show_circle_list)
	buttons.add_child(choose)

	var help := make_button("Управление")
	help.pressed.connect(show_controls)
	buttons.add_child(help)

	buttons.add_child(make_sound_button(show_main_menu))

	footer.text = "Пройдено кругов: %d из %d" % [Game.completed.size(), Game.LAST_CIRCLE]

# Переключатель звука. Настройка сохраняется вместе с прогрессом, поэтому
# выключенный звук остаётся выключенным и после перезапуска.
func make_sound_button(refresh: Callable) -> Button:
	var button := make_button("Звук: %s" % ("вкл" if Game.sound_on else "выкл"))
	button.pressed.connect(func() -> void:
		Game.set_sound(not Game.sound_on)
		refresh.call())
	return button

func confirm_restart() -> void:
	open(Screen.MENU)
	title.text = "НАЧАТЬ ЗАНОВО?"
	subtitle.text = "Пройденные круги будут забыты."
	clear_buttons()
	var yes := make_button("Да, с первого круга")
	yes.pressed.connect(func() -> void:
		Game.reset_progress()
		start_circle(1))
	buttons.add_child(yes)
	var no := make_button("Нет, вернуться")
	no.pressed.connect(show_main_menu)
	buttons.add_child(no)
	footer.text = ""

func show_circle_list() -> void:
	open(Screen.CIRCLES_LIST)
	title.text = "ВЫБРАТЬ КРУГ"
	subtitle.text = "Открыт следующий за последним пройденным."
	clear_buttons()

	# Девять кнопок в столбик не помещаются на телефоне, поэтому сетка 3×3.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons.add_child(grid)
	for number in range(Game.FIRST_CIRCLE, Game.LAST_CIRCLE + 1):
		var row: Array = CIRCLES[number]
		var unlocked := Game.is_unlocked(number)
		var mark := "✓ " if Game.is_completed(number) else ""
		var button := make_button("%s%s · %s" % [mark, str(row[0]), str(row[1])], unlocked)
		button.custom_minimum_size = Vector2(230, 52)
		if unlocked:
			var target := number
			button.pressed.connect(func() -> void: start_circle(target))
		grid.add_child(button)

	var back := make_button("Назад")
	back.pressed.connect(show_main_menu)
	buttons.add_child(back)
	footer.text = "Закрытые круги откроются по мере прохождения."

func show_controls() -> void:
	open(Screen.MENU)
	title.text = "УПРАВЛЕНИЕ"
	subtitle.text = "WASD — идти   ·   мышь — смотреть   ·   Shift — быстрее\n" \
		+ "ЛКМ — рассмотреть   ·   ПКМ — положить   ·   E — тронуть\n" \
		+ "1–4 — слот инвентаря   ·   H — подсказка   ·   Esc — пауза"
	clear_buttons()
	var back := make_button("Назад")
	back.pressed.connect(show_main_menu)
	buttons.add_child(back)
	footer.text = "Умереть и проиграть нельзя. Часы в гостиной — это прогресс."

func show_pause() -> void:
	open(Screen.PAUSE)
	var row: Array = CIRCLES.get(circle, CIRCLES[1])
	title.text = "ПАУЗА"
	subtitle.text = "Круг %s · %s" % [str(row[0]), str(row[1])]
	clear_buttons()
	var resume := make_button("Продолжить")
	resume.pressed.connect(hide_all)
	buttons.add_child(resume)
	var restart := make_button("Начать круг сначала")
	restart.pressed.connect(func() -> void: start_circle(circle))
	buttons.add_child(restart)
	buttons.add_child(make_sound_button(show_pause))
	var menu := make_button("В главное меню")
	menu.pressed.connect(func() -> void: Game.go_to_menu(get_tree()))
	buttons.add_child(menu)
	footer.text = "Прогресс по кругам сохраняется сам."

# --------------------------------------------------------------- переходы ---

# Круг доигран. Экран перехода показывается поверх уже завершившегося круга,
# без паузы: круг всё равно закончился, и его финальная реплика должна
# дочитаться.
func on_circle_finished() -> void:
	if advancing or screen == Screen.TRANSITION or screen == Screen.FINALE:
		return
	advancing = true
	finished_circle = circle
	Game.mark_completed(circle)
	if circle >= Game.LAST_CIRCLE:
		show_finale()
		return
	pending_circle = circle + 1
	show_transition()

func show_transition() -> void:
	open(Screen.TRANSITION)
	# Экран перехода полупрозрачнее прочих: под ним видно комнату, которую
	# игрок только что прошёл.
	backdrop.color = Color(0.02, 0.02, 0.03, 0.86)
	var done: Array = CIRCLES[finished_circle]
	var next: Array = CIRCLES[pending_circle]
	title.text = "КРУГ %s ПРОЙДЕН" % str(done[0])
	subtitle.text = "%s\n\nДальше — круг %s, %s.\n%s" \
		% [str(done[1]), str(next[0]), str(next[1]), str(next[2])]
	clear_buttons()
	var go := make_button("Дальше")
	go.pressed.connect(advance_now)
	buttons.add_child(go)
	countdown = TRANSITION_SECONDS
	footer.text = "Прогресс сохранён."
	# Место для межстраничной рекламы Яндекса — это ровно логическая пауза,
	# которой требуют правила площадки. Слой платформы подключается сюда
	# отдельным шагом; таймер выше от него не зависит намеренно.
	request_interstitial()

# Межстраничная реклама. Показывается только здесь — на переходе между
# кругами, то есть в логической паузе, как того требуют правила площадки.
# Вне веба и без SDK метод молчит.
#
# Важно: показ рекламы НЕ удлиняет ожидание. Таймер countdown идёт своим
# ходом, и зависший ролик не может задержать игрока на экране перехода.
# Закрытие ролика лишь позволяет уйти раньше.
func request_interstitial() -> void:
	if not has_node("/root/Platform"):
		return
	var platform := get_node("/root/Platform")
	if not platform.show_interstitial():
		return
	waiting_for_ad = true

func advance_now() -> void:
	if pending_circle <= 0:
		return
	var target := pending_circle
	pending_circle = 0
	countdown = 0.0
	Game.go_to_circle(get_tree(), target)

func show_finale() -> void:
	open(Screen.FINALE)
	backdrop.color = Color(0.02, 0.02, 0.03, 0.95)
	title.text = "16:13"
	subtitle.text = "Девять кругов пройдены.\n\n" \
		+ "Комната та же, что была в 16:04.\nЭто и есть худшее, что она умеет."
	clear_buttons()
	var again := make_button("В главное меню")
	again.pressed.connect(func() -> void: Game.go_to_menu(get_tree()))
	buttons.add_child(again)
	footer.text = "Пройдено кругов: %d из %d" % [Game.completed.size(), Game.LAST_CIRCLE]

func start_circle(number: int) -> void:
	Game.go_to_circle(get_tree(), number)

func _process(delta: float) -> void:
	if countdown <= 0.0:
		return
	# Ролик закрылся раньше таймера — идём дальше сразу, чтобы не держать
	# игрока перед уже пустым экраном. Но не раньше, чем экран успели прочитать.
	var shown_for := TRANSITION_SECONDS - countdown
	if waiting_for_ad and shown_for >= TRANSITION_MIN_READ and has_node("/root/Platform") \
			and get_node("/root/Platform").interstitial_finished():
		waiting_for_ad = false
		advance_now()
		return
	countdown -= delta
	if countdown <= 0.0:
		advance_now()

# Esc обрабатываем здесь, а не в игроке: у игрока Esc только отпускает мышь, и
# на паузу это не тянет. Событие гасим, чтобы игрок его уже не увидел.
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if (event as InputEventKey).keycode != KEY_ESCAPE:
		return
	if screen == Screen.TRANSITION or screen == Screen.FINALE:
		return
	get_viewport().set_input_as_handled()
	if screen == Screen.NONE:
		show_pause()
	elif screen == Screen.PAUSE:
		hide_all()
