class_name InspectView
extends Node

# Режим осмотра — главный новый глагол круга.
#
# Предмет поднимается к лицу, его можно повернуть мышью. Надписи, даты и номера
# лежат на ОБРАТНОЙ стороне вещей: пока игрок не догадается перевернуть предмет,
# он их не увидит. Это единственный источник конкретной информации в уровне,
# где нет ни диктора, ни экрана с заданиями.

signal opened(id: String)
signal closed(id: String)
signal turned_over(id: String)

const VIEW_SIZE := 640
const FIT := .52
# Верх описания предмета, отсчёт от низа экрана. Названо константой, потому что
# Hud поднимает над этой границей свою строку сообщений: две строки внизу экрана
# уже один раз наложились друг на друга и обе стали нечитаемыми.
const BODY_TOP := -168.0

var player: CharacterBody3D
var cue: CueAudio
var canvas: CanvasLayer
var dim: ColorRect
var frame: TextureRect
var title_label: Label
var body_label: Label
var hint_label: Label
var viewport: SubViewport
var holder: Node3D
var active := false
var current := ""
var reverse_text := ""
var reverse_shown := false
var turn_amount := 0.0

func setup(target_player: CharacterBody3D, audio: CueAudio) -> void:
	name = "InspectView"
	player = target_player
	cue = audio
	build_viewport()
	build_canvas()
	set_process_input(false)

func build_viewport() -> void:
	viewport = SubViewport.new()
	viewport.name = "InspectViewport"
	viewport.size = Vector2i(VIEW_SIZE, VIEW_SIZE)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.own_world_3d = true
	add_child(viewport)

	holder = Node3D.new()
	holder.name = "Holder"
	viewport.add_child(holder)

	var view_camera := Camera3D.new()
	view_camera.name = "InspectCamera"
	view_camera.position = Vector3(0, 0, 1.15)
	view_camera.fov = 42.0
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("6d6455")
	env.ambient_light_energy = 1.35
	view_camera.environment = env
	viewport.add_child(view_camera)

	var key_light := DirectionalLight3D.new()
	key_light.name = "InspectKey"
	key_light.rotation = Vector3(-0.62, 0.72, 0)
	key_light.light_energy = 1.15
	key_light.light_color = Color("ffe9c8")
	viewport.add_child(key_light)

func build_canvas() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "InspectCanvas"
	canvas.layer = 12
	canvas.visible = false
	add_child(canvas)

	dim = ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.025, .88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(dim)

	frame = TextureRect.new()
	frame.name = "Object"
	frame.texture = viewport.get_texture()
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.position = Vector2(-VIEW_SIZE / 2.0, -VIEW_SIZE / 2.0 - 30.0)
	frame.size = Vector2(VIEW_SIZE, VIEW_SIZE)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(frame)

	title_label = make_label(28, Color("e6dfd1"), Control.PRESET_CENTER_TOP, Vector2(-420, 58))
	body_label = make_label(21, Color("cfc7b7"), Control.PRESET_CENTER_BOTTOM, Vector2(-420, BODY_TOP))
	hint_label = make_label(15, Color(.75, .72, .66, .55), Control.PRESET_CENTER_BOTTOM, Vector2(-420, -96))
	hint_label.text = "мышь — повернуть   ·   ПКМ или Esc — положить обратно"

func make_label(size: int, color: Color, preset: int, offset: Vector2) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, .85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.set_anchors_preset(preset)
	label.position = offset
	label.size = Vector2(840, 96)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(label)
	return label

func open(id: String, data: Dictionary) -> void:
	if active:
		return
	active = true
	current = id
	reverse_text = str(data.get("reverse", ""))
	reverse_shown = false
	turn_amount = 0.0

	clear_holder()
	var prop = data.get("prop", null)
	if prop is Node3D:
		var copy := (prop as Node3D).duplicate() as Node3D
		holder.add_child(copy)
		copy.transform = Transform3D.IDENTITY
		# Предмет, уже убранный со сцены в инвентарь, копируется скрытым —
		# в руках он всё равно должен быть виден.
		copy.visible = true
		strip(copy)
		fit(copy)
		frame.visible = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		frame.visible = false

	title_label.text = str(data.get("title", ""))
	body_label.text = str(data.get("text", ""))
	# У вещи без модели крутить нечего, а оборот раньше открывался только по
	# накрученному движению мыши — то есть был недостижим. Показываем сразу.
	var reveal_now := not frame.visible and not reverse_text.is_empty()
	if reveal_now:
		body_label.text += "\n" + reverse_text
		reverse_shown = true
	hint_label.text = "мышь — повернуть   ·   ПКМ или Esc — положить обратно" \
		if frame.visible else "ПКМ или Esc — положить обратно"
	hint_label.visible = true
	holder.rotation = Vector3.ZERO
	canvas.visible = true
	if player:
		player.set_physics_process(false)
		player.velocity = Vector3.ZERO
	set_process_input(true)
	if cue:
		cue.play("paper", -4.0)
	opened.emit(id)
	if reveal_now:
		turned_over.emit(id)

func close() -> void:
	if not active:
		return
	var id := current
	active = false
	current = ""
	canvas.visible = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	clear_holder()
	set_process_input(false)
	if player:
		player.set_physics_process(true)
	closed.emit(id)

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
		var motion := event as InputEventMouseMotion
		holder.rotate_object_local(Vector3.UP, -motion.relative.x * .0075)
		holder.rotate_object_local(Vector3.RIGHT, -motion.relative.y * .0075)
		turn_amount += absf(motion.relative.x) * .0075 + absf(motion.relative.y) * .0035
		check_reverse()
		return
	if event.is_action_pressed("inspect_close") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		close()
		return
	# ЛКМ гасим молча: во время вращения по нему щёлкают рефлекторно, и он не
	# должен доставать до комнаты за затемнением.
	if event.is_action_pressed("examine"):
		get_viewport().set_input_as_handled()

# Обратная сторона открывается не по таймеру, а когда предмет действительно
# повернули примерно на пол-оборота.
func check_reverse() -> void:
	if reverse_shown or reverse_text.is_empty() or turn_amount < 2.6:
		return
	reverse_shown = true
	body_label.text = reverse_text
	if cue:
		cue.play("tick", -6.0)
	turned_over.emit(current)

func fit(node: Node3D) -> void:
	var bounds := bounds_of(node)
	if bounds.size.length() <= 0.0001:
		return
	# Плоские вещи — карточку, записку, картину — показываем лицом, а не ребром:
	# самая тонкая ось разворачивается на камеру. Иначе лист бумаги выглядит
	# полоской, и переворачивать его бессмысленно.
	# Лицевой стороной считаем +Y для лежащих вещей и +X для висящих: её и
	# доворачиваем к камере, чтобы оборот оставался находкой, а не первым видом.
	if bounds.size.y < bounds.size.x and bounds.size.y < bounds.size.z:
		node.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	elif bounds.size.x < bounds.size.y and bounds.size.x < bounds.size.z:
		node.rotate_object_local(Vector3.UP, -PI / 2.0)
	var largest: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	var factor: float = FIT / largest
	node.scale = Vector3.ONE * factor
	# basis уже содержит и разворот, и масштаб, поэтому центр смещаем через него.
	node.position = -(node.basis * bounds.get_center())

func bounds_of(node: Node3D) -> AABB:
	var result := AABB()
	var started := false
	for child in node.find_children("*", "VisualInstance3D", true, false):
		var visual := child as VisualInstance3D
		var local := visual.get_aabb()
		var offset := node.global_transform.affine_inverse() * visual.global_transform
		var transformed := offset * local
		if not started:
			result = transformed
			started = true
		else:
			result = result.merge(transformed)
	if node is VisualInstance3D:
		var own := (node as VisualInstance3D).get_aabb()
		result = own if not started else result.merge(own)
	return result

func strip(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionShape3D or child is CollisionObject3D or child is Light3D or child is Camera3D:
			child.queue_free()
		else:
			strip(child)

func clear_holder() -> void:
	for child in holder.get_children():
		child.queue_free()
