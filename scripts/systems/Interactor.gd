class_name Interactor
extends Node3D

# Наведение и два глагола: ЛКМ — осмотреть, E — применить.
#
# Ключевое отличие от прежней версии: осмотреть можно почти всё в комнате,
# поэтому реакция прицела перестала быть указателем на решение. Она снова
# значит только «здесь есть что рассматривать».

signal used(id: String)
signal examined(id: String)

const REACH := 3.15

var camera: Camera3D
var hud: Hud
var ray: RayCast3D
var targets := {}
var aimed := ""
var locked := false
# Третий акт разрешает E по всей комнате, чтобы поиск отличий не превратился в
# чеклист. Но золотое [E] над каждой мелочью — это уже не подсказка, а шум:
# прицел перестаёт значить хоть что-нибудь ровно тогда, когда он нужнее всего.
# Флаг разводит маршрутизацию и показ: нажатие проходит везде, а обещание [E]
# даётся только там, где оно давалось и до слома комнаты.
var strict_prompt := false

func setup(target_camera: Camera3D, target_hud: Hud) -> void:
	name = "Interactor"
	camera = target_camera
	hud = target_hud
	ray = RayCast3D.new()
	ray.name = "AimRay"
	ray.target_position = Vector3(0, 0, -REACH)
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.collision_mask = 3
	ray.enabled = true
	camera.add_child(ray)

# opts: title, text, reverse, usable, examinable, prop (Node3D для режима осмотра)
func register(id: String, position: Vector3, size: Vector3, opts := {}) -> void:
	var area := Build.area(self, "Aim_" + id, position, size)
	area.set_meta("interaction_id", id)
	# Названия и описания зон приходят из const-таблиц кругов, то есть по-русски
	# и до всякого выбора языка. Переводим здесь, на входе: дальше по игре эти
	# строки идут уже в том виде, в каком их увидит игрок.
	var entry := {
		"area": area,
		"bounds": AABB(position - size * .5, size),
		"title": Loc.t(str(opts.get("title", ""))),
		"text": Loc.t(str(opts.get("text", ""))),
		"reverse": Loc.t(str(opts.get("reverse", ""))),
		"usable": bool(opts.get("usable", false)),
		# «Тихая» зона отвечает на E, но золотого [E] не обещает никогда.
		# Так добавляется отклик на десятки предметов обстановки, не превращая
		# прицел в разметку комнаты: он по-прежнему значит «здесь есть что
		# рассматривать», а не «здесь решение». Тот же принцип, по которому в
		# третьем акте нажатие проходит везде, а обещание — нет.
		"quiet": bool(opts.get("quiet", false)),
		"examinable": bool(opts.get("examinable", true)),
		"prop": opts.get("prop", null),
		"seen": false,
		# Тексты меняются по ходу круга, поэтому исходные храним для сброса.
		"default_text": Loc.t(str(opts.get("text", ""))),
		"default_reverse": Loc.t(str(opts.get("reverse", ""))),
		"default_usable": bool(opts.get("usable", false))
	}
	targets[id] = entry

func set_usable(id: String, value: bool) -> void:
	if targets.has(id):
		targets[id]["usable"] = value

func set_examinable(id: String, value: bool) -> void:
	if targets.has(id):
		targets[id]["examinable"] = value

func set_text(id: String, text: String, reverse := "") -> void:
	if not targets.has(id):
		return
	targets[id]["text"] = Loc.t(text)
	if not reverse.is_empty():
		targets[id]["reverse"] = Loc.t(reverse)

func entry(id: String) -> Dictionary:
	return targets.get(id, {})

func was_seen(id: String) -> bool:
	return targets.has(id) and bool(targets[id]["seen"])

func mark_seen(id: String) -> void:
	if targets.has(id):
		targets[id]["seen"] = true

func zone(id: String) -> Area3D:
	if not targets.has(id):
		return null
	return targets[id]["area"]

func set_strict_prompt(value: bool) -> void:
	strict_prompt = value

# Сделать зону «тихой»: E отвечает, золотого [E] нет никогда.
#
# Правит и default_usable, а не только usable, — иначе clear() из full_reset()
# вернул бы зону к «нельзя тронуть», и на втором прогоне круга половина отклика
# комнаты молча исчезла бы.
func make_quiet(id: String) -> void:
	if not targets.has(id):
		return
	targets[id]["usable"] = true
	targets[id]["default_usable"] = true
	targets[id]["quiet"] = true

# Возврат usable к исходным значениям, БЕЗ сброса «осмотрено» и текстов: после
# третьего акта комната помнит, что игрок уже видел и что успел прочитать.
func restore_defaults() -> void:
	for id in targets:
		targets[id]["usable"] = targets[id]["default_usable"]

func set_locked(value: bool) -> void:
	locked = value
	if locked:
		aimed = ""
		hud.set_aim(Hud.Aim.NONE)

func _process(_delta: float) -> void:
	if locked:
		return
	aimed = current_aim()
	if aimed.is_empty():
		hud.set_aim(Hud.Aim.NONE)
		return
	hud.set_aim(prompt_state(aimed))

# Решение о виде прицела вынесено из _process, чтобы аудит проверял именно тот
# код, который работает в игре: наведение мышью в headless-прогоне не
# воспроизвести, а копия правила в аудите зеленела бы независимо от правила.
func prompt_state(id: String) -> Hud.Aim:
	if not targets.has(id):
		return Hud.Aim.NONE
	var target: Dictionary = targets[id]
	if target["usable"] and not target["quiet"] and (not strict_prompt or target["default_usable"]):
		return Hud.Aim.USE
	if target["examinable"]:
		return Hud.Aim.EXAMINE
	return Hud.Aim.NONE

func current_aim() -> String:
	if not ray or not ray.is_colliding():
		return ""
	var collider := ray.get_collider()
	if not collider is Area3D:
		return ""
	var id := str(collider.get_meta("interaction_id", ""))
	return id if targets.has(id) else ""

func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if aimed.is_empty():
		# Осмотр «в пустоту» уровень трактует как «рассмотреть то, что в руке».
		if event.is_action_pressed("examine"):
			get_viewport().set_input_as_handled()
			examined.emit("")
		return
	var target: Dictionary = targets[aimed]
	if event.is_action_pressed("interact") and target["usable"]:
		get_viewport().set_input_as_handled()
		used.emit(aimed)
	elif event.is_action_pressed("examine") and target["examinable"]:
		get_viewport().set_input_as_handled()
		examined.emit(aimed)

func reset_texts() -> void:
	for id in targets:
		targets[id]["text"] = targets[id]["default_text"]
		targets[id]["reverse"] = targets[id]["default_reverse"]

func clear() -> void:
	reset_texts()
	restore_defaults()
	for id in targets:
		targets[id]["seen"] = false
	strict_prompt = false
	aimed = ""
	if hud:
		hud.set_aim(Hud.Aim.NONE)
