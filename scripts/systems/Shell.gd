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
const LEVEL_MAP_SCRIPT := preload("res://scripts/systems/LevelMap.gd")

# Названия кругов для экранов. Порядковый номер римскими — как в документах.
#
# Третья колонка — строка-приманка, которую видно на переходе между кругами.
# Она намеренно говорит гостиничным языком и ни разу не называет ад: игрок
# заселился в обычный номер и до последней минуты не должен знать, куда попал.
# Названия кругов при этом настоящие — единственная подсказка, и пусть она
# останется единственной.
const CIRCLES := {
	1: ["I", "ЛИМБ", "Ключ подошёл. Дверь закрылась сама"],
	2: ["II", "УРАГАН", "Накрыто на двоих. Вы заселялись один"],
	3: ["III", "НЕНАСЫТНОСТЬ", "Ужин, которого никто не заказывал"],
	4: ["IV", "СКУПОСТЬ", "Кто-то считал деньги и не досчитал"],
	5: ["V", "ГНЕВ", "Здесь только что кричали"],
	6: ["VI", "ЕРЕСЬ", "Всё заперто. Изнутри"],
	7: ["VII", "НАСИЛИЕ", "Кто-то держался за это до последнего"],
	8: ["VIII", "ОБМАН", "Ни одна вещь не та, за которую себя выдаёт"],
	9: ["IX", "ПРЕДАТЕЛЬСТВО", "Номер выстывает. Отопление ни при чём"]
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

enum Screen { NONE, MENU, CIRCLES_LIST, PAUSE, MAP, TRANSITION, FINALE }

var screen := Screen.NONE
var root: Control
var backdrop: ColorRect
var title: Label
var subtitle: Label
var buttons: VBoxContainer
var footer: Label
var eyebrow: Label
var divider: ColorRect

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
var map_return_to_pause := false

func setup(circle_number: int, circle_hud: CanvasLayer = null) -> void:
	name = "Shell"
	layer = LAYER
	# Оболочка обязана работать на паузе: на паузе её и показывают.
	process_mode = Node.PROCESS_MODE_ALWAYS
	circle = circle_number
	hud = circle_hud
	build()
	# Меню рисуется за первый кадр, а SDK отвечает позже — до восьми секунд.
	# Значит уже показанный экран обязан уметь пересобраться под новый язык,
	# иначе игрок с английской локалью успеет увидеть русское меню и остаться
	# с ним. Пересобирается ровно тот экран, что открыт сейчас.
	if has_node("/root/Loc"):
		var loc := get_node("/root/Loc")
		if not loc.language_changed.is_connected(_on_language_changed):
			loc.language_changed.connect(_on_language_changed)

# Пересобирать разрешено не всякий экран. show_transition() просит межстраничную
# рекламу и заводит обратный отсчёт — повторный вызов показал бы второй ролик на
# одном переходе, чего правила площадки не допускают. Поэтому у перехода
# переписывается только текст, а у карты сохраняется, куда с неё возвращаться.
func _on_language_changed(_code: String) -> void:
	# Надпись над названием живёт в build(), а не в экранах: она общая для всех
	# и потому пересборкой экрана не обновляется. Обновляем отдельно.
	if is_instance_valid(eyebrow):
		eyebrow.text = Loc.t('ОТЕЛЬ  ·  16-Й ЭТАЖ')
	match screen:
		Screen.MENU: show_main_menu()
		Screen.CIRCLES_LIST: show_circle_list()
		Screen.PAUSE: show_pause()
		Screen.FINALE: show_finale()
		Screen.MAP:
			var back_to_pause := map_return_to_pause
			show_map()
			map_return_to_pause = back_to_pause
		Screen.TRANSITION:
			title.text = Loc.f("КРУГ %s ПРОЙДЕН", [circle_numeral(finished_circle)])
			subtitle.text = Loc.f("%s\n\nДальше — круг %s, %s.\n%s", [
				circle_name(finished_circle), circle_numeral(pending_circle),
				circle_name(pending_circle), circle_line(pending_circle)])
			footer.text = Loc.t("Прогресс сохранён.")

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

	# A restrained hotel-lobby backdrop: warm light near the title, cool falloff
	# at the edges and barely visible wall panels. It is procedural, so the web
	# build gains no texture and the menu remains sharp at every size.
	var atmosphere := ColorRect.new()
	atmosphere.name = 'Atmosphere'
	atmosphere.color = Color.WHITE
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var atmosphere_shader := Shader.new()
	atmosphere_shader.code = 'shader_type canvas_item; float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);} void fragment(){vec2 p=UV-vec2(.5); float warm=exp(-dot(p+vec2(.03,.13),p+vec2(.03,.13))*8.0); float edge=smoothstep(.72,.22,length(p*vec2(1.0,.76))); float panels=(.5+.5*cos(UV.x*62.8319))*.012; float grain=(h(floor(UV*vec2(420.0,240.0)))-.5)*.010; vec3 ink=vec3(.012,.017,.026)+warm*vec3(.055,.031,.012)+edge*vec3(.008,.009,.010)+panels+grain; COLOR=vec4(ink,.62);}'
	var atmosphere_material := ShaderMaterial.new()
	atmosphere_material.shader = atmosphere_shader
	atmosphere.material = atmosphere_material
	root.add_child(atmosphere)

	# A thin framed field keeps the shell coherent without becoming a heavy,
	# opaque dialog. Full-rect anchors keep it safe on phones.
	var card := Panel.new()
	card.name = 'MenuFrame'
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 22.0; card.offset_top = 18.0
	card.offset_right = -22.0; card.offset_bottom = -18.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.018,0.021,0.028,.58)
	card_style.border_color = Color('55462f')
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(10)
	card.add_theme_stylebox_override('panel',card_style)
	root.add_child(card)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column)

	eyebrow = make_label('ОТЕЛЬ  ·  16-Й ЭТАЖ',13,Color('9f8e73'))
	eyebrow.add_theme_constant_override('outline_size',3)
	column.add_child(eyebrow)
	divider = ColorRect.new()
	divider.color = Color('765d38')
	divider.custom_minimum_size = Vector2(150,1)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider)

	title = make_label("", 46, AMBER)
	column.add_child(title)
	subtitle = make_label("", 21, DIM)
	column.add_child(subtitle)
	title.add_theme_constant_override('outline_size',6)
	title.add_theme_color_override('font_outline_color',Color(0.025,0.018,0.012,.95))
	title.add_theme_constant_override('font_spacing_glyph',2)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size.x = 420

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
	label.text = Loc.t(text)
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
func button_style(background: Color, border: Color, border_width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func make_button(text: String, enabled := true) -> Button:
	var button := Button.new()
	button.add_theme_stylebox_override('normal',button_style(Color(0.035,0.040,0.052,.92),Color('423a30')))
	button.add_theme_stylebox_override('hover',button_style(Color(0.105,0.080,0.048,.96),Color('c09659'),2))
	button.add_theme_stylebox_override('pressed',button_style(Color(0.135,0.094,0.048,.98),Color('e8c07d'),2))
	button.add_theme_stylebox_override('focus',button_style(Color(0.070,0.061,0.050,.96),Color('d0a664'),2))
	button.add_theme_stylebox_override('disabled',button_style(Color(0.025,0.027,0.032,.74),Color('302d29')))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = Loc.t(text)
	button.custom_minimum_size = Vector2(360, 52)
	# custom_minimum_size задаёт минимум, а не максимум: без сжатия по центру
	# кнопка растягивается во всю ширину экрана и выглядит полосой.
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", CREAM if enabled else Color(.45, .43, .40))
	button.add_theme_color_override("font_hover_color", AMBER)
	button.add_theme_color_override("font_pressed_color", AMBER)
	button.disabled = not enabled
	return button

# Переключатель языка. Сам язык игра определяет по площадке и без игрока —
# это требование 2.14, и оно выполняется до всякого нажатия. Кнопка нужна для
# другого: чтобы человек с русской локалью мог посмотреть английскую версию, а
# с английской — русскую, не меняя настроек аккаунта.
#
# Названия языков через таблицу перевода НЕ идут: «English» и «Русский» — это
# эндонимы, они одинаковы на любом языке интерфейса и переводу не подлежат.
func make_language_button() -> Button:
	var button := make_button("")
	button.text = "English" if Loc.language == "ru" else "Русский"
	button.pressed.connect(func() -> void: Loc.choose_language(Loc.other_language()))
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
	get_viewport().disable_3d = false
	set_hud_visible(true)
	get_tree().paused = false
	capture_mouse(true)
	# Геймплей начался по-настоящему: экранов оболочки больше нет.
	platform_call("gameplay_start")

func open(new_screen: Screen) -> void:
	screen = new_screen
	root.visible = true
	# Dense screens need the vertical room for their 3x3 grid or map. The main
	# menu keeps the hotel eyebrow and divider as its signature.
	eyebrow.visible = new_screen not in [Screen.CIRCLES_LIST,Screen.MAP]
	divider.visible = eyebrow.visible
	root.modulate.a = 0.0
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(root,'modulate:a',1.0,.18)
	get_viewport().disable_3d = new_screen == Screen.MAP
	backdrop.color = Color(0.02, 0.02, 0.03, 0.93)
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

# Названия кругов подставляются в форматные строки, а не показываются сами по
# себе. Переводить их надо отдельно от шаблона: в переводе «Продолжить — круг
# %s, %s» самих названий нет.
func circle_numeral(number: int) -> String:
	var row: Array = CIRCLES.get(number, CIRCLES[1])
	return str(row[0])

func circle_name(number: int) -> String:
	var row: Array = CIRCLES.get(number, CIRCLES[1])
	return Loc.t(str(row[1]))

func circle_line(number: int) -> String:
	var row: Array = CIRCLES.get(number, CIRCLES[1])
	return Loc.t(str(row[2]))

func show_main_menu() -> void:
	open(Screen.MENU)
	title.text = Loc.t("КОМНАТА 1604")
	subtitle.text = Loc.t("Вы заселились в 16:04.\nЧасы в гостиной с тех пор прошли одну минуту.")
	clear_buttons()

	if Game.has_progress():
		var resume := make_button(Loc.f("Продолжить — круг %s, %s",
			[circle_numeral(Game.current_circle), circle_name(Game.current_circle)]))
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

	buttons.add_child(make_language_button())

	footer.text = Loc.f("Пройдено кругов: %d из %d", [Game.completed.size(), Game.LAST_CIRCLE])

func confirm_restart() -> void:
	open(Screen.MENU)
	title.text = Loc.t("НАЧАТЬ ЗАНОВО?")
	subtitle.text = Loc.t("Пройденные круги будут забыты.")
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
	title.text = Loc.t("ВЫБРАТЬ КРУГ")
	subtitle.text = Loc.t("Каждый круг — одна минута на настенных часах: 16:04, 16:05, 16:06…")
	clear_buttons()

	# Девять кнопок в столбик не помещаются на телефоне, поэтому сетка 3×3.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons.add_child(grid)
	for number in range(Game.FIRST_CIRCLE, Game.LAST_CIRCLE + 1):
		var unlocked := Game.is_unlocked(number)
		var mark := "✓ " if Game.is_completed(number) else ""
		var button := make_button("%s%s · %s" % [mark, circle_numeral(number), circle_name(number)], unlocked)
		button.custom_minimum_size = Vector2(230, 52)
		if unlocked:
			var target := number
			button.pressed.connect(func() -> void: start_circle(target))
		grid.add_child(button)

	var back := make_button("Назад")
	back.pressed.connect(show_main_menu)
	buttons.add_child(back)
	footer.text = Loc.t("Закрытые круги откроются по мере прохождения.")

func show_controls() -> void:
	open(Screen.MENU)
	title.text = Loc.t("УПРАВЛЕНИЕ")
	# Три строки управления переводятся по одной: так перевод остаётся
	# построчным и в таблице, и на экране, а склейка не превращается в
	# четвёртый ключ, которого нигде нет.
	subtitle.text = Loc.t("WASD — идти   ·   мышь — смотреть   ·   Shift — быстрее") + "\n" \
		+ Loc.t("ЛКМ — рассмотреть   ·   ПКМ — положить   ·   E — тронуть") + "\n" \
		+ Loc.t("1–4 — слот инвентаря   ·   H — подсказка   ·   M — карта   ·   Esc — пауза")
	clear_buttons()
	var back := make_button("Назад")
	back.pressed.connect(show_main_menu)
	buttons.add_child(back)
	footer.text = Loc.t("Здесь нельзя погибнуть. Это не значит, что можно уйти.")

func show_pause() -> void:
	open(Screen.PAUSE)
	title.text = Loc.t("ПАУЗА")
	subtitle.text = Loc.f("Круг %s · %s", [circle_numeral(circle), circle_name(circle)])
	clear_buttons()
	var resume := make_button("Продолжить")
	resume.pressed.connect(hide_all)
	buttons.add_child(resume)
	var restart := make_button("Начать круг сначала")
	restart.pressed.connect(func() -> void: start_circle(circle))
	buttons.add_child(restart)
	var map_button := make_button("Карта этажа")
	map_button.pressed.connect(show_map)
	buttons.add_child(map_button)
	var menu := make_button("В главное меню")
	menu.pressed.connect(func() -> void: Game.go_to_menu(get_tree()))
	buttons.add_child(menu)
	footer.text = Loc.t("Отель сам помнит, где вы остановились.")

func show_map() -> void:
	map_return_to_pause = screen == Screen.PAUSE
	open(Screen.MAP)
	# Карта непрозрачна и не нуждается в мире под собой. Это полностью снимает
	# 3D-рендер на время чтения карты, особенно полезно в браузере и на телефоне.
	get_viewport().disable_3d = true
	backdrop.color = Color(0.015, 0.016, 0.020, 1.0)
	title.text = Loc.t("ПЛАН 16-ГО ЭТАЖА")
	subtitle.text = Loc.t("Знаки отмечают места, которые комната почему-то запомнила.")
	clear_buttons()
	var level_map := LEVEL_MAP_SCRIPT.new()
	var player := get_parent().get_node_or_null("Player") as Node3D
	if player:
		level_map.set_player_position(player.global_position)
	buttons.add_child(level_map)
	var close := make_button("Закрыть карту")
	close.pressed.connect(close_map)
	buttons.add_child(close)
	footer.text = Loc.t("M или Esc — закрыть карту")

func close_map() -> void:
	get_viewport().disable_3d = false
	if map_return_to_pause:
		map_return_to_pause = false
		show_pause()
	else:
		hide_all()

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
	title.text = Loc.f("КРУГ %s ПРОЙДЕН", [circle_numeral(finished_circle)])
	subtitle.text = Loc.f("%s\n\nДальше — круг %s, %s.\n%s", [
		circle_name(finished_circle), circle_numeral(pending_circle),
		circle_name(pending_circle), circle_line(pending_circle)])
	clear_buttons()
	var go := make_button("Дальше")
	go.pressed.connect(advance_now)
	buttons.add_child(go)
	countdown = TRANSITION_SECONDS
	footer.text = Loc.t("Прогресс сохранён.")
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
	subtitle.text = Loc.t("Девять кругов пройдены.") + "\n\n" \
		+ Loc.t("Комната та же, что была в 16:04.\nЭто и есть худшее, что она умеет.")
	clear_buttons()
	var again := make_button("В главное меню")
	again.pressed.connect(func() -> void: Game.go_to_menu(get_tree()))
	buttons.add_child(again)
	footer.text = Loc.f("Пройдено кругов: %d из %d", [Game.completed.size(), Game.LAST_CIRCLE])

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
	var key := (event as InputEventKey).keycode
	if key == KEY_M:
		if screen == Screen.NONE or screen == Screen.PAUSE:
			get_viewport().set_input_as_handled()
			show_map()
		elif screen == Screen.MAP:
			get_viewport().set_input_as_handled()
			close_map()
		return
	if key != KEY_ESCAPE:
		return
	if screen == Screen.TRANSITION or screen == Screen.FINALE:
		return
	get_viewport().set_input_as_handled()
	if screen == Screen.NONE:
		show_pause()
	elif screen == Screen.PAUSE:
		hide_all()
	elif screen == Screen.MAP:
		close_map()
