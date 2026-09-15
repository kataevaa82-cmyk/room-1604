class_name TouchControls
extends CanvasLayer

# Сенсорное управление для телефонов и планшетов.
#
# Показывается только на сенсорных устройствах. На столе его нет вовсе — там
# клавиатура и мышь, как требует площадка «по умолчанию для десктопа».
#
# Почему это ОТДЕЛЬНЫЙ CanvasLayer, а не часть Hud: аудит всех девяти кругов
# проверяет положение строки подсказок (`hud.message.position`). Кнопки,
# добавленные в слои Hud, переложили бы его разметку и уронили проверку сразу
# во всех девяти. Слой 15 — выше HUD (10..14), ниже оболочки меню (20).
#
# Как ввод попадает в игру:
#   * Ходьба — Input.action_press с силой: игрок опрашивает Input.get_vector(),
#     и синтетическое состояние действия его устраивает.
#   * Взгляд — прямой вызов player.apply_look(): ограничение наклона живёт
#     там же, где для мыши.
#   * Кнопки — настоящие события через Input.parse_input_event(). Action_press
#     здесь не годится: он меняет состояние, но НЕ порождает InputEvent, а
#     круги и инвентарь слушают именно события (_unhandled_input).

const LAYER := 15

# Радиус, за которым отклонение джойстика считается предельным.
const STICK_RADIUS := 110.0
const STICK_DEAD_ZONE := 0.14
# Чувствительность перетаскивания взгляда относительно мыши. Палец проходит
# больше пикселей, чем мышь, поэтому множитель меньше единицы.
const LOOK_SCALE := 0.62

var player: CharacterBody3D
var shell: CanvasLayer

var root: Control
var stick_base: Control
var stick_knob: Control

# Пальцы разведены по назначению: один ведёт джойстик, другой крутит взгляд.
# Без этого второй палец перехватывал бы управление у первого.
var stick_finger := -1
var look_finger := -1
var stick_origin := Vector2.ZERO
var stick_vector := Vector2.ZERO

# Какие действия сейчас «нажаты» синтетически — чтобы отпустить их ровно один раз.
var pressed_actions := {}

static func wanted() -> bool:
	if OS.has_environment("FORCE_TOUCH"):
		return true
	if not DisplayServer.is_touchscreen_available():
		return false
	return true

func setup(target_player: CharacterBody3D, target_shell: CanvasLayer) -> void:
	name = "TouchControls"
	layer = LAYER
	player = target_player
	shell = target_shell
	build()

func build() -> void:
	root = Control.new()
	root.name = "TouchRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	build_stick()
	build_buttons()

func build_stick() -> void:
	stick_base = make_ring(Vector2(STICK_RADIUS * 2.0, STICK_RADIUS * 2.0), Color(1, 1, 1, .10))
	stick_base.visible = false
	root.add_child(stick_base)
	stick_knob = make_ring(Vector2(64, 64), Color(1, 1, 1, .22))
	stick_knob.visible = false
	root.add_child(stick_knob)

func make_ring(size: Vector2, color: Color) -> Control:
	var box := ColorRect.new()
	box.size = size
	box.color = color
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box

# Кнопки крупные: меньше 64 пикселей пальцем стабильно не попасть, а
# промахнувшийся игрок читает это как «игра не отвечает».
func make_touch_button(text: String, size: Vector2) -> Button:
	var button := Button.new()
	button.text = Loc.t(text)
	button.custom_minimum_size = size
	button.size = size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("ddd6c8"))
	button.modulate.a = .82
	return button

func build_buttons() -> void:
	# Правый нижний угол — под большой палец правой руки.
	var use := make_touch_button("E", Vector2(96, 96))
	use.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	use.position = Vector2(-124, -128)
	use.pressed.connect(func() -> void: send_action("interact"))
	root.add_child(use)

	var look_at := make_touch_button("ОСМОТР", Vector2(132, 72))
	look_at.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	look_at.position = Vector2(-160, -212)
	look_at.pressed.connect(func() -> void: send_action("examine"))
	root.add_child(look_at)

	var back := make_touch_button("НАЗАД", Vector2(112, 60))
	back.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	back.position = Vector2(-140, -292)
	back.pressed.connect(func() -> void: send_action("inspect_close"))
	root.add_child(back)

	var hint := make_touch_button("?", Vector2(64, 64))
	hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hint.position = Vector2(-88, 20)
	hint.pressed.connect(func() -> void: send_key(KEY_H))
	root.add_child(hint)

	var pause := make_touch_button("| |", Vector2(64, 64))
	pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause.position = Vector2(-160, 20)
	pause.pressed.connect(func() -> void: send_key(KEY_ESCAPE))
	root.add_child(pause)

	var map := make_touch_button("КАРТА", Vector2(88, 64))
	map.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	map.position = Vector2(-264, 20)
	map.add_theme_font_size_override("font_size", 16)
	map.pressed.connect(func() -> void: send_key(KEY_M))
	root.add_child(map)

	# Слоты инвентаря. Нужны в кругах III и IV, где предметы носят в руках.
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	slots.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	slots.position = Vector2(-296, -60)
	root.add_child(slots)
	for index in range(4):
		var slot := make_touch_button(str(index + 1), Vector2(64, 48))
		var key := KEY_1 + index
		slot.pressed.connect(func() -> void: send_key(key))
		slots.add_child(slot)

# --------------------------------------------------------------- отправка ---

# Настоящее событие, а не Input.action_press: круги и инвентарь слушают
# _unhandled_input, а состояние действия событий не порождает.
func send_action(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)

func send_key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventKey.new()
	release.keycode = keycode
	release.physical_keycode = keycode
	release.pressed = false
	Input.parse_input_event(release)

# ------------------------------------------------------------------ ввод ---

func shell_open() -> bool:
	# Пока показан экран меню, паузы или перехода, сенсорное управление молчит:
	# иначе палец по кнопке меню одновременно вёл бы игрока по комнате.
	if shell == null or not is_instance_valid(shell):
		return false
	return shell.has_method("is_open") and shell.is_open()

# Именно _unhandled_input, а не _input: _input срабатывает РАНЬШЕ обработки
# интерфейса, и касание экранной кнопки одновременно начинало бы поворот
# камеры. Здесь кнопки забирают нажатие первыми, а сюда доходит только то,
# что легло на пустую часть экрана.
func _unhandled_input(event: InputEvent) -> void:
	if shell_open():
		release_all()
		return
	if event is InputEventScreenTouch:
		handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		handle_drag(event as InputEventScreenDrag)

func handle_touch(event: InputEventScreenTouch) -> void:
	var half := get_viewport().get_visible_rect().size.x * .5
	if event.pressed:
		# Левая половина экрана — ходьба, правая — взгляд. Кнопки перехватывают
		# касание раньше, поэтому сюда доходит только «чистая» часть экрана.
		if event.position.x < half and stick_finger < 0:
			stick_finger = event.index
			stick_origin = event.position
			stick_vector = Vector2.ZERO
			show_stick(true)
		elif event.position.x >= half and look_finger < 0:
			look_finger = event.index
	else:
		if event.index == stick_finger:
			stick_finger = -1
			stick_vector = Vector2.ZERO
			show_stick(false)
			release_movement()
		elif event.index == look_finger:
			look_finger = -1

func handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == stick_finger:
		var offset := event.position - stick_origin
		stick_vector = offset / STICK_RADIUS
		if stick_vector.length() > 1.0:
			stick_vector = stick_vector.normalized()
		place_knob()
	elif event.index == look_finger and player:
		player.apply_look(event.relative * LOOK_SCALE)

func show_stick(visible_now: bool) -> void:
	stick_base.visible = visible_now
	stick_knob.visible = visible_now
	if visible_now:
		stick_base.position = stick_origin - stick_base.size * .5
		place_knob()

func place_knob() -> void:
	stick_knob.position = stick_origin + stick_vector * STICK_RADIUS - stick_knob.size * .5

func _process(_delta: float) -> void:
	if stick_finger < 0 or shell_open():
		return
	apply_movement()

# Ходьбу отдаём состоянием действия: игрок опрашивает Input.get_vector(), и
# синтетическая сила его устраивает. Порог мёртвой зоны нужен, чтобы палец,
# лежащий неподвижно, не вёл игрока сам.
func apply_movement() -> void:
	var vector := stick_vector
	if vector.length() < STICK_DEAD_ZONE:
		release_movement()
		return
	set_axis("move_right", "move_left", vector.x)
	set_axis("move_back", "move_forward", vector.y)

func set_axis(positive: String, negative: String, value: float) -> void:
	if value > STICK_DEAD_ZONE:
		hold(positive, absf(value))
		let_go(negative)
	elif value < -STICK_DEAD_ZONE:
		hold(negative, absf(value))
		let_go(positive)
	else:
		let_go(positive)
		let_go(negative)

func hold(action: String, strength: float) -> void:
	Input.action_press(action, clampf(strength, 0.0, 1.0))
	pressed_actions[action] = true

func let_go(action: String) -> void:
	if not pressed_actions.has(action):
		return
	Input.action_release(action)
	pressed_actions.erase(action)

func release_movement() -> void:
	for action in ["move_forward", "move_back", "move_left", "move_right"]:
		let_go(action)

# Отпустить всё разом. Зовётся, когда открылся экран оболочки: иначе игрок
# продолжил бы идти, пока висит меню, — и после закрытия шёл бы дальше сам.
func release_all() -> void:
	release_movement()
	if stick_finger >= 0:
		stick_finger = -1
		stick_vector = Vector2.ZERO
		show_stick(false)
	look_finger = -1
