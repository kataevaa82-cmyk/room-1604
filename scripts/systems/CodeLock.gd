class_name CodeLock
extends Node

# Кодовый замок с настоящим вводом с клавиатуры.
#
# Одно из немногих мест круга, где игрок действует руками, а не нажимает E по
# подсвеченному объекту. Код можно собрать по обратным сторонам вещей и следам
# в темноте — а можно просто сообразить, что номер комнаты написан на двери.
# Догадливого игрока за сообразительность не наказываем.

signal opened()
signal rejected()
signal shown()
signal hidden()

const LENGTH := 4

var cue: CueAudio
var player: CharacterBody3D
var canvas: CanvasLayer
var digits_label: LineEdit
var caption: Label
var found_label: Label
var code := "1604"
var typed := ""
var known := {}
var active := false
var syncing_text := false

func setup(target_player: CharacterBody3D, audio: CueAudio) -> void:
	name = "CodeLock"
	player = target_player
	cue = audio
	build()
	set_process_input(false)

func build() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "CodeLockCanvas"
	canvas.layer = 13
	canvas.visible = false
	add_child(canvas)

	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.015, 0.02, .9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(dim)

	var title := Label.new()
	title.text = Loc.t("СЕЙФ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("bdb49f"))
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-300, -150)
	title.size = Vector2(600, 36)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(title)

	# Это настоящий LineEdit, а не нарисованная строка. В веб-сборке Godot
	# связывает его со скрытым HTML <input inputmode="numeric"> и поэтому по
	# касанию открывается системная клавиатура телефона. Раньше здесь был Label:
	# панель выглядела как поле ввода, но фокусировать было физически нечего.
	digits_label = LineEdit.new()
	digits_label.alignment = HORIZONTAL_ALIGNMENT_CENTER
	digits_label.add_theme_font_size_override("font_size", 76)
	digits_label.add_theme_color_override("font_color", Color("d8c79b"))
	digits_label.add_theme_color_override("caret_color", Color("d8c79b"))
	digits_label.add_theme_color_override("font_placeholder_color", Color("d8c79b"))
	for style_name in ["normal", "focus", "read_only"]:
		digits_label.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	digits_label.set_anchors_preset(Control.PRESET_CENTER)
	digits_label.position = Vector2(-300, -70)
	digits_label.size = Vector2(600, 96)
	digits_label.placeholder_text = "—   —   —   —"
	digits_label.max_length = LENGTH
	digits_label.virtual_keyboard_enabled = true
	digits_label.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	digits_label.context_menu_enabled = false
	digits_label.text_changed.connect(on_text_changed)
	canvas.add_child(digits_label)

	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 17)
	caption.add_theme_color_override("font_color", Color(.74, .71, .65, .6))
	caption.set_anchors_preset(Control.PRESET_CENTER)
	caption.position = Vector2(-360, 74)
	caption.size = Vector2(720, 30)
	caption.text = Loc.t("цифры — ввод   ·   Backspace — стереть   ·   ПКМ или Esc — отойти")
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(caption)

	# Строка находок. Цифры разбросаны по оборотам вещей и по следу в темноте,
	# и раньше их сбор ни во что не выливался: панель молчала одинаково и для
	# того, кто обшарил номер, и для того, кто просто прочитал номер на двери.
	# Теперь найденное видно здесь — но это награда, а не пропуск: код можно
	# набрать сразу и целиком.
	found_label = Label.new()
	found_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	found_label.add_theme_font_size_override("font_size", 19)
	found_label.add_theme_color_override("font_color", Color(.68, .63, .52, .55))
	found_label.set_anchors_preset(Control.PRESET_CENTER)
	found_label.position = Vector2(-360, 34)
	found_label.size = Vector2(720, 28)
	found_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	found_label.visible = false
	canvas.add_child(found_label)

func set_code(value: String) -> void:
	code = value

# digits — цифры, которые игрок действительно где-то увидел.
func set_known(digits: Array) -> void:
	known.clear()
	for digit in digits:
		known[str(digit)] = true
	refresh_known()

func clear_known() -> void:
	known.clear()
	refresh_known()

func refresh_known() -> void:
	if not found_label:
		return
	if known.is_empty():
		found_label.visible = false
		found_label.text = ""
		return
	var parts: Array[String] = []
	for i in range(code.length()):
		parts.append(code[i] if known.has(code[i]) else "—")
	found_label.visible = true
	found_label.text = Loc.t("ты уже видел:") + "   " + "   ·   ".join(parts)

func open() -> void:
	if active:
		return
	active = true
	typed = ""
	refresh()
	refresh_known()
	canvas.visible = true
	if player:
		player.set_physics_process(false)
		player.velocity = Vector3.ZERO
	set_process_input(true)
	# open() вызывается из пользовательского E/тапа. Фокус ставим после того,
	# как CanvasLayer стал видимым: на мобильном это автоматически показывает
	# числовую виртуальную клавиатуру, а повторный тап по полю делает то же самое.
	digits_label.call_deferred("grab_focus")
	shown.emit()

func close() -> void:
	if not active:
		return
	active = false
	digits_label.release_focus()
	if OS.has_feature("web"):
		DisplayServer.virtual_keyboard_hide()
	canvas.visible = false
	set_process_input(false)
	if player:
		player.set_physics_process(true)
	hidden.emit()

func _input(event: InputEvent) -> void:
	if not active:
		return
	# Пока набирают код, камера за панелью крутиться не должна.
	if event is InputEventMouseMotion or event.is_action_pressed("examine"):
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	var key := (event as InputEventKey).keycode
	if key == KEY_ESCAPE:
		close()
		return
	if key == KEY_BACKSPACE:
		typed = typed.substr(0, maxi(0, typed.length() - 1))
		refresh()
		if cue:
			cue.play("switch", -6.0)
		return
	if key >= KEY_0 and key <= KEY_9 and typed.length() < LENGTH:
		accept_text(typed + str(key - KEY_0))

# Виртуальная клавиатура меняет text самого LineEdit, физическая приходит в
# _input(). Оба пути сводятся сюда, чтобы код, звук и проверка не расходились.
func on_text_changed(value: String) -> void:
	if not active or syncing_text:
		return
	var digits := ""
	for character in value:
		if character >= "0" and character <= "9":
			digits += character
			if digits.length() == LENGTH:
				break
	accept_text(digits)

func accept_text(value: String) -> void:
	var previous := typed
	typed = value.left(LENGTH)
	refresh()
	if typed.length() > previous.length() and cue:
		cue.play("dial", -8.0)
	if typed.length() == LENGTH:
		check()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("inspect_close"):
		get_viewport().set_input_as_handled()
		close()

func check() -> void:
	if typed == code:
		if cue:
			cue.play("unlock")
		close()
		opened.emit()
		return
	if cue:
		cue.play("locked")
	rejected.emit()
	var tween := create_tween()
	tween.tween_property(digits_label, "modulate", Color("a35c4d"), .12)
	tween.tween_interval(.35)
	tween.tween_callback(func() -> void:
		typed = ""
		refresh()
		digits_label.modulate = Color.WHITE
	)

func refresh() -> void:
	if digits_label.text != typed:
		syncing_text = true
		digits_label.text = typed
		syncing_text = false
	digits_label.caret_column = typed.length()
