extends CircleLevel

# КРУГ VI — «ЕРЕСЬ». Комната 1604, 16:09 → 16:10.
#
# У Данте шестой круг — еретики в раскалённых гробницах за отказ верить в
# бессмертие души: они замуровали себя в собственной убеждённости. Здесь это
# номер, где пять вещей заколочены, заклеены и зашиты — не спрятаны, а
# заперты нарочно, чтобы к ним не возвращаться. За каждой — короткая записка,
# которая называет, что заперто следующим. Открыть одно — узнать, где искать
# следующее; открыть не по порядку нельзя, номер отвечает «ещё не время».
#
# Глагол круга — ВСКРЫТЬ ПО ПОРЯДКУ. Круг V не признавал порядка вовсе — пять
# вспышек унимались в любой последовательности. Здесь порядок и есть мысль
# круга: ересь — это упрямство, а не забывчивость, и потому её нельзя снять
# в произвольном месте. Тот же приём цепочки, что у писем Круга II, но не про
# расставание, а про то, что раз запертое признаёшь по одному, а не разом.

enum Act { SEALED, COMPLETE }

# Порядок вскрытия жёстко задан: он и есть механика круга.
const ORDER := ["seal_box", "seal_drawer", "seal_curtain", "seal_book", "seal_board"]

# id -> [позиция, поворот, заголовок, текст запертого, текст вскрытого,
# точка обзора].
const SEALS := {
	"seal_box": [Vector3(1.90, .66, -1.45), 0.0, "Заклеенная коробка",
		"Скотч в три слоя, углы проклеены отдельно. На боку ничего не написано.",
		"Внутри старые квитанции без адреса. На последней карандашом: «ящик у окна, задвинуть до конца».",
		Vector3(1.45, 1.15, -1.45)],
	"seal_drawer": [Vector3(-3.65, 1.10, -.40), .20, "Заколоченный ящик",
		"Задвинут и заколочен снаружи одним гвоздём — не для того, чтобы держал, а чтобы напоминал.",
		"Гвоздь вышел легко. Внутри моток шторной тесьмы и записка: «подол не трогать» — но с зачёркнутым «не».",
		Vector3(-3.20, 1.15, -.40)],
	"seal_curtain": [Vector3(.80, 1.10, 4.95), 0.0, "Зашитый подол шторы",
		"Подол зашит грубой ниткой в две строчки — не для красоты, для того, чтобы не поднимался.",
		"Нитка разошлась в один рывок. В подоле зашита книга — та же, что стоит на полке нетронутой.",
		Vector3(.80, 1.15, 4.50)],
	"seal_book": [Vector3(2.55, .85, 1.35), .30, "Склеенные страницы книги",
		"Страницы с тридцать четвёртой слиплись намертво — не от воды, клеем.",
		"Страницы разошлись с треском. На тридцать пятой одна строчка, обведённая много раз: половица у камина.",
		Vector3(2.10, 1.20, 1.35)],
	"seal_board": [Vector3(2.00, .05, 3.85), 0.0, "Прибитая половица",
		"Одна половица прибита четырьмя гвоздями — на остальных ни одного.",
		"Половица поддалась. Под ней пусто — то, что там лежало, вскрывать было уже незачем.",
		Vector3(1.55, .90, 3.85)]
}

var act := Act.SEALED
var opened := {}
var step := 0
var seal_nodes := {}

func _ready() -> void:
	name = "HeresyLevel"
	audit_tag = "HERESY"
	player = get_parent().get_node("Player")
	camera = player.get_node("Head/Camera3D")
	world_environment = get_parent().get_node_or_null("Environment")
	cache_room()
	build_systems()
	build_props()
	register_targets()
	wire_signals()
	full_reset()
	if OS.has_environment("HERESY_AUDIT"):
		await get_tree().process_frame
		run_audit()
	elif OS.has_environment("HERESY_WALKTHROUGH"):
		begin_walkthrough(OS.get_environment("HERESY_WALKTHROUGH"))
		await get_tree().process_frame
		run_audit()
	else:
		hud.show_message("КРУГ VI\nЕРЕСЬ", 3.2)
		show_controls()

func show_controls() -> void:
	var mark := epoch
	await get_tree().create_timer(4.2).timeout
	if mark != epoch:
		return
	hud.show_message("WASD — идти   ·   ЛКМ — рассмотреть   ·   E — тронуть   ·   H — подсказка", 5.4)

func build_props() -> void:
	clock_display = Build.label3d(self, "ClockDisplay", "16:09:00", Vector3(2.28, 1.74, .915), Vector3.ZERO, 30, .0032)
	clock_glow = OmniLight3D.new()
	clock_glow.name = "ClockGlow"
	clock_glow.position = Vector3(2.28, 1.74, 1.02)
	clock_glow.omni_range = 1.1
	clock_glow.shadow_enabled = false
	clock_glow.visible = false
	add_child(clock_glow)
	clock = ClockDirector.new()
	add_child(clock)
	clock.setup(clock_display, clock_glow, cue)
	clock.start_label = "16:09"
	clock.end_label = "16:10"
	clock.refresh()

	var root := get_parent()
	# Все пять переиспользуют готовые модели: круг не добавляет ни одного
	# нового ассета, тот же приём, что и в Кругах III–V.
	seal_nodes["seal_box"] = root.placed_model(self, "SealBox",
		load("res://assets/models/hotel_amenities.glb"), Vector3(1.90, .30, -1.45), Vector3.ZERO,
		{"metal": "brass", "glass": "glass", "soap": "cream"})
	seal_nodes["seal_drawer"] = root.placed_model(self, "SealDrawer",
		load("res://assets/models/bath_tissue_box.glb"), Vector3(-3.65, .85, -.40), Vector3(0, .2, 0),
		{"cardboard": "wood2", "tissue": "cream"})
	seal_nodes["seal_curtain"] = root.placed_model(self, "SealCurtain",
		load("res://assets/models/c2_dress_hanger.glb"), Vector3(.80, 1.86, 4.95), Vector3(0, PI / 2, 0),
		{"brass": "brass", "fabric": "linen"})
	seal_nodes["seal_book"] = root.placed_model(self, "SealBook",
		load("res://assets/models/books.glb"), Vector3(2.55, .48, 1.35), Vector3(.25, .10, .30),
		{"carpetDarker": "painting", "carpetWhite": "cream", "metal": "brass", "plant": "olive"})
	seal_nodes["seal_board"] = root.placed_model(self, "SealBoard",
		load("res://assets/models/window_sill.glb"), Vector3(2.00, .02, 3.85), Vector3(0, PI / 2, 0),
		{"wood": "wood2", "metal": "brass"})

func register_targets() -> void:
	for id in SEALS:
		var row: Array = SEALS[id]
		interactor.register(str(id), row[0] + Vector3(0, .08, 0), Vector3(.26, .22, .26), {
			"title": str(row[2]), "text": str(row[3]), "usable": true})
	register_room_flavor(ROOM_ZONE_TEXT)
	register_switch_zones()

const ROOM_ZONE_TEXT := {
	"console": [null, "Столик у двери. Ящика в нём нет — на его месте заглушка вровень с деревом.",
		"Заглушка не снимается. Кто-то решил, что этому месту лучше быть пустым, и заколотил решение."],
	"entry_lamp": [null, "Латунная стойка. Провод примотан к ножке скотчем — чтобы не тянулся к розетке.",
		"Ты отмотал провод. Он всё равно ведёт только до той же розетки."],
	"hall_plant": [null, "В горшке, кроме земли, обрывок бумаги, вдавленный глубоко — прятали, не выбрасывали.",
		"Бумага размокла настолько, что текста не разобрать. Может, в этом и был смысл."],
	"hall_painting": [null, "Горное озеро. С обратной стороны рамы бумажная лента — заклеена намертво.",
		"Лента не поддаётся. За ней явно что-то есть, но не сегодня."],
	"entry_rug": [null, "Плотный ворс. Один угол пришит к полу через ковёр — редкий, но настоящий стежок.",
		"Нитка крепкая. Кто-то не хотел, чтобы этот угол когда-нибудь поднимали."],
	"hall_outlet": [null, "Круглое гнездо в латунной рамке.", "Гнездо пустое и холодное."],
	"drawer_left": [null, "Ящик с той стороны кровати. Ручка снята и лежит рядом — чтобы не открывали по привычке.",
		"Ты вставил ручку обратно. Ящик открылся без сопротивления — заперт он был только с виду."],
	"drawer_right": [null, "Ящик закрыт обычным способом — эта сторона ни от чего не отгорожена.",
		"Пусто, и ничего не заперто."],
	"radiator_bed": [null, "Секционный радиатор. Вентиль стянут проволокой — открутить не выйдет.",
		"Проволока держит крепко. Вентиль остаётся там, где его оставили навсегда."],
	"bed_outlet": [null, "Ещё одно гнездо. Заклеено бумажным квадратом изнутри розетки.",
		"Бумага отклеилась легко. За ней обычная пустая розетка — прятать было нечего."],
	"tub": [null, "Ванна. Слив закрыт пробкой, примотанной проволокой — чтобы точно не вынули.",
		"Проволока держит. Вода в ванне давно бы ушла, если бы могла."],
	"toilet": [null, "Белый фаянс. Крышка бачка привинчена — обычно её просто кладут.",
		"Винты не поддаются руке. Кто-то не хотел, чтобы туда заглядывали."],
	"towels": [null, "Сложены гостиничным углом, перевязаны бечёвкой — как будто их решили больше не трогать.",
		"Бечёвка снялась одним движением. Полотенца обычные, ничего в них не было завязано."],
	"hand_towel": [null, "На латунном кольце, приклеено скотчем снизу — не падает, даже если дёрнуть.",
		"Полотенце качнулось и вернулось ровно как было."],
	"wastebasket": [null, "Плетёная корзина. Дно выстлано газетой, придавленной камнем — от сквозняка, не от находки.",
		"Ты убрал камень. Под газетой пусто — камень был просто камнем."],
	"shower": [null, "Лейка на шланге. Вентиль холодной воды замотан изолентой в несколько слоёв.",
		"Изолента держит. Вентиль остаётся закрытым, что бы под ним ни думали."],
	"toilet_paper": [null, "Рулон на латунном штыре, обмотан ниткой — чтобы не разматывался сам.",
		"Нитка лопнула. Рулон обычный, беспокоиться было не о чем."],
	"sofa": [null, "Бежевая обивка. Один шов прошит заново, крупными стежками — заделали, а не распороли.",
		"Ты провёл по шву. Он держит крепко и ничего не выдаёт."],
	"coffee_table": [null, "Лак цел. Под столешницей приклеен конверт — на ощупь пустой.",
		"Конверт снялся вместе с пылью. Внутри действительно пусто — искали не там."],
	"living_armchair": [null, "Оливковое кресло. Один подлокотник обмотан бечёвкой — трещину скрыли, не починили.",
		"Бечёвка держит крепко. Трещина под ней осталась той же."],
	"minibar": [null, "Шкафчик со стеклянной дверцей. Ручка примотана проволокой к корпусу.",
		"Проволока не поддаётся. Дверца остаётся закрытой из принципа, не из необходимости."],
	"living_mirror": [null, "Небольшое зеркало. Заклеено бумагой крест-накрест, как перед ремонтом.",
		"Бумага держится крепко. За ней обычное стекло — прятать в зеркале нечего."],
	"living_painting": [null, "Ночной отель, горит одно окно. Рама прибита к стене — обычно её просто вешают.",
		"Гвозди сидят намертво. Кто-то решил, что этой картине не бывать снятой."],
	"desk_lamp": [null, "Рабочая лампа. Выключатель заклеен в положении «выключено».",
		"Скотч не поддаётся с первого раза. Лампа так и остаётся тёмной."],
	"desk_chair": [null, "Стул придвинут вплотную и связан со столом бечёвкой — не отодвинуть.",
		"Бечёвка ослабла, но не разошлась. Стул стоит там же."],
	"radiator_living": [null, "Такой же стянутый проволокой, как в спальне.",
		"Тот же холод и тот же неподатливый вентиль."],
	"door": [null, "Латунная ручка. Внутри замка что-то забито — ключ входит только наполовину.",
		"Замок проворачивается вхолостую, и не глубже, чем раньше."],
	"plate": [null, "Табличка 1604. Один винт залит воском — чтобы не выкрутили случайно.",
		"Воск сухой и старый. Табличка держится, потому что её и не пытались снять."],
	"clock": [null, "Тёмный корпус, латунные кольца. Заводной ключ примотан к ножке скотчем, чтобы не потерялся — или не использовался.",
		"Корпус тёплый. Стрелку не сдвинуть ни в одну сторону."],
	"chair": [null, "Кресло у окна. Плед пришит к спинке в двух местах — чтобы не соскальзывал, или не снимался.",
		"Стежки держат крепко. Плед остаётся на месте, что бы с ним ни делали."]
}

func reach_origins() -> Dictionary:
	var origins := {}
	for id in SEALS:
		origins[str(id)] = (SEALS[id] as Array)[5]
	for id in flavor_origins():
		origins[id] = flavor_origins()[id]
	return origins

func wire_signals() -> void:
	interactor.used.connect(on_used)
	interactor.examined.connect(on_examined)
	inspect.opened.connect(func(_id: String) -> void:
		hints.set_paused(true)
		hud.set_message_raised(true))
	inspect.closed.connect(func(_id: String) -> void:
		hints.set_paused(false)
		hud.set_message_raised(false))
	clock.minute_reached.connect(on_minute_reached)

func on_examined(id: String) -> void:
	if inspect.active or code_lock.active:
		return
	if id.is_empty():
		return
	if not interactor.targets.has(id):
		return
	inspect.open(id, interactor.entry(id))
	interactor.mark_seen(id)

func on_used(id: String) -> void:
	if inspect.active or code_lock.active:
		return
	if SEALS.has(id):
		open_seal(id)
		return
	if id.begins_with("switch_"):
		toggle_switch(id)
		return
	if ROOM_ZONES.has(id):
		use_room_zone(id)
		return

func open_seal(id: String) -> void:
	if opened.has(id):
		return
	if step >= ORDER.size() or str(ORDER[step]) != id:
		# Не по порядку — отказ, а не провал: ничего не отнимается, часы не
		# отматываются назад. Ересь круга в том, что порядок нельзя обойти,
		# а не в том, что ошибку наказывают.
		hud.show_message("Ещё не время. Сначала — другое.", 2.8)
		return
	opened[id] = true
	step += 1
	interactor.set_text(id, str((SEALS[id] as Array)[4]))
	cue.play("latch")
	clock.advance(7.0, "seal")
	if step < ORDER.size():
		hud.show_message("Вскрыто. Осталось: %d." % (ORDER.size() - step), 3.0)
		focus_current_seal()
		return
	act = Act.COMPLETE
	clock_display.text = "16:10:00"
	hints.set_enabled(false)
	clock.ceiling = ClockDirector.SPAN
	hud.show_message("Всё вскрыто по порядку. В номере не осталось ни одной запертой вещи.", 4.2)
	clock.run_out(6.0)

func on_minute_reached() -> void:
	clock_display.text = "16:10:00"

func focus_current_seal() -> void:
	if step >= ORDER.size():
		hints.clear_focus()
		return
	var id: String = ORDER[step]
	hints.set_focus((SEALS[id] as Array)[0], [
		"В номере ещё есть запертое.",
		"Вскрыто по порядку: %d из %d." % [step, ORDER.size()],
		"Следующее по порядку — здесь: %s. Наведись и нажми E." % str((SEALS[id] as Array)[2])])
	hints.reset_timer()

func current_goal() -> String:
	match act:
		Act.SEALED:
			var id: String = ORDER[step] if step < ORDER.size() else ""
			var title := str((SEALS[id] as Array)[2]) if not id.is_empty() else ""
			return "Вскрывай запертое по порядку — %d из %d. Следующее: %s." \
				% [step, ORDER.size(), title]
		Act.COMPLETE:
			return "Круг VI пройден."
	return "Оглядись."

func full_reset() -> void:
	epoch += 1
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	act = Act.SEALED
	opened.clear()
	step = 0
	rewarded.clear()
	quiet_said.clear()
	player.transform = original.player
	player.global_position = Vector3(1.25, .05, .15)
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	interactor.clear()
	interactor.set_locked(false)
	inspect.close()
	code_lock.close()
	anomalies.clear()
	hints.clear()
	hud.reset()
	clock.reset()
	clock.start_label = "16:09"
	clock.end_label = "16:10"
	clock.refresh()
	clock.start()
	clock.ceiling = 50.0
	hints.set_enabled(true)
	focus_current_seal()

func run_audit() -> void:
	await get_tree().physics_frame
	if not require(SEALS.size() == ORDER.size(), "SEALS/ORDER size mismatch"): return
	var expected := SEALS.size() + ROOM_ZONES.size() + 4
	if not require(interactor.targets.size() == expected,
			"unexpected zone count: %d, expected %d" % [interactor.targets.size(), expected]): return
	for id in ROOM_ZONES:
		if not require(interactor.entry(str(id))["usable"], "room zone is not usable: %s" % id): return
	if not check_no_overlap(): return
	if not check_reachable(reach_origins()): return
	if not require(message_on_screen(), "message sits off screen"): return
	if not require(act == Act.SEALED, "circle VI did not start in the sealed act"): return
	if not require(current_goal().contains("по порядку"), "H says nothing useful in act I"): return
	await shot("c6_loaded", Vector3(1.25, .05, .15), .4, -.20)

	# Не по порядку — обязано отказывать.
	on_used(str(ORDER[2]))
	if not require(not opened.has(str(ORDER[2])), "out-of-order seal opened anyway: %s" % ORDER[2]): return
	if not require(step == 0, "step advanced on an out-of-order attempt"): return
	await shot("c6_out_of_order", (SEALS[ORDER[0]] as Array)[5])

	# Теперь вскрываем строго по порядку, как и пойдёт живой игрок.
	for index in range(ORDER.size()):
		var id: String = ORDER[index]
		if not require(step == index, "step out of sync before opening %s" % id): return
		on_used(id)
		if not require(opened.has(id), "seal did not open in order: %s" % id): return
	if not require(step == ORDER.size(), "not every seal was opened: %d" % step): return
	if not require(act == Act.COMPLETE, "opening every seal did not end act I"): return
	await shot("c6_open", Vector3(1.25, .05, .15), .4, -.20)

	var wait_guard := 0
	while clock_display.text != "16:10:00" and wait_guard < 200:
		await get_tree().create_timer(.1).timeout
		wait_guard += 1
	if not require(clock_display.text == "16:10:00", "clock shows %s" % clock_display.text): return
	await shot("c6_complete")

	full_reset()
	if not require(act == Act.SEALED and opened.is_empty() and step == 0,
			"full_reset did not clean up"): return

	print("HERESY_AUDIT_OK circle VI: %d zones, %d seals, clock 16:09->16:10"
		% [interactor.targets.size(), SEALS.size()])
	prepare_shutdown()
	await get_tree().create_timer(.35).timeout
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if (event as InputEventKey).keycode == KEY_H:
		get_viewport().set_input_as_handled()
		request_hint()
