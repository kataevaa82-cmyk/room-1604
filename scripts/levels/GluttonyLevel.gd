extends CircleLevel

# КРУГ III — «НЕНАСЫТНОСТЬ». Комната 1604, 16:06 → 16:07.
#
# Замысел целиком — в КРУГ_III.md. Коротко: у Данте третий круг — Обжорство, и
# наказаны там холодным гниющим дождём и лежанием в грязи. Здесь номер завален
# едой, которую никто не ел: рум-сервис приносил и приносил, всё стоит под
# колпаками и всё холодное.
#
# Механика круга — сам инвентарь. В первых двух кругах носимый предмет был один,
# и четыре слота были запасом. Здесь подносов шесть, слотов четыре, и это единственный
# круг, где по номеру приходится ходить туда-обратно. Ограничение стало содержанием.
#
# Сделан Акт I. Акты II и III описаны в документе.

enum Act { CARRY, DRIP, COMPLETE }

# Обстановка номера (`CircleLevel.ROOM_ZONES`) со своим текстом: круг про
# количество и холод, и почти каждая вещь в номере теперь стоит рядом с
# подносом или помнит, что мимо неё что-то проносили. Заголовок не меняем
# (null) — геометрия и назначение вещи те же, что и в остальных кругах.
const ROOM_ZONE_TEXT := {
	"console": [null, "Стол у входа. На углу мокрый круг от подноса, которого здесь уже нет.",
		"Ты вытер круг рукавом. Стол холодный, как будто поднос стоял тут всю ночь."],
	"entry_lamp": [null, "Латунная стойка. Абажур пахнет тем же, чем пахнет из-под колпаков.",
		"Ты качнул абажур. Запах не сдвинулся вместе с ним."],
	"hall_plant": [null, "Листья мокрые сверху — капает не только с потолка.",
		"Ты стряхнул каплю с листа. Она была не тёплой и не холодной — никакой."],
	"hall_painting": [null, "Горное озеро. Рама покрылась испариной, как крышка колпака.",
		"Ты провёл пальцем по раме. Влага не вода."],
	"entry_rug": [null, "Ворс примят не следами — здесь ставили и переставляли подносы.",
		"Ты отогнул угол. Под ковриком сухо, но пахнет так же, как сверху."],
	"hall_outlet": [null, "Круглое гнездо в латунной рамке.", "Гнездо пустое и холодное."],
	"drawer_left": [null, "Ящик с той стороны кровати, где подноса нет.",
		"Внутри пусто. Единственное пустое место в номере."],
	"drawer_right": [null, "Ящик с той стороны, где стоял поднос.",
		"Дерево изнутри чуть влажное — оттуда, где стоял поднос."],
	"radiator_bed": [null, "Секционный радиатор. Не греет — под колпаками и так всё не остыло.",
		"Вентиль ледяной. Отопление тут ни при чём."],
	"bed_outlet": [null, "Розетка у кровати. Рядом след — здесь тоже стоял поднос.",
		"Пусто, только след круглого дна на обоях."],
	"tub": [null, "Ванна. Ободок мокрый, и это не вода из крана.",
		"Ты провёл по дну. Холодное и липкое."],
	"toilet": [null, "Белый фаянс. Крышка опущена, на ней поднос не помещался бы, но пробовали.",
		"На крышке круглый след — тоже от подноса."],
	"towels": [null, "Сложены гостиничным углом. На верхнем пятно от колпака.",
		"Ты развернул полотенце. Пятно не отстирать — оно въелось."],
	"hand_towel": [null, "На латунном кольце. Пахнет тем же, чем весь номер.",
		"Полотенце качнулось и вернулось ровно как было."],
	"wastebasket": [null, "Корзина у раковины. Полна салфеток из-под колпаков.",
		"Ты заглянул внутрь. Салфетки ни разу не разворачивали."],
	"shower": [null, "Лейка на шланге. Капает — так же, как с потолка.",
		"Вентиль проворачивается свободно. Капля всё равно падает."],
	"toilet_paper": [null, "Рулон на латунном штыре, не тронут.",
		"Рулон провернулся со щелчком — единственная вещь в номере, которую не трогали."],
	"sofa": [null, "Бежевая обивка. Продавлена под тяжестью, которая на неё не садилась.",
		"Ты нажал на подушку. Она проседает так, будто под ней ещё один поднос."],
	"coffee_table": [null, "Лак весь в кольцах от колпаков — их тут переставляли десятки раз.",
		"Ты провёл пальцем. Кольца холодные на ощупь, хотя стол давно пуст."],
	"living_armchair": [null, "Оливковое кресло. На подлокотнике вмятина ровно под поднос.",
		"Кресло качнулось. Вмятина осталась той же формы."],
	"minibar": [null, "Низкий шкафчик со стеклянной дверцей. Внутри теснее, чем снаружи.",
		"Дверца не закрывается до конца — там ещё один поднос, задвинутый криво."],
	"living_mirror": [null, "Зеркало у минибара. Запотело снизу, будто рядом стояло что-то горячее.",
		"Ты протёр стекло. Запотевает заново за секунды."],
	"living_painting": [null, "Ночной отель, горит одно окно. Рама липкая по нижнему краю.",
		"Рама качнулась. Окно на картине осталось гореть."],
	"desk_lamp": [null, "Рабочая лампа. Абажур в мелких каплях.",
		"Щелчок. Лампа не загорелась — с ней капает то же, что с потолка."],
	"desk_chair": [null, "Отодвинут от стола ровно настолько, чтобы поднос поместился на столешнице.",
		"Стул откатился. На сиденье холодный круглый след."],
	"radiator_living": [null, "Такой же ледяной, как в спальне.",
		"Тот же холод и тот же свободный вентиль."],
	"door": [null, "Латунная ручка. Под дверью щель ровно под поднос.",
		"Замок проворачивается вхолостую. Щель под дверью пуста, пока в руках что-то есть."],
	"plate": [null, "Табличка 1604. Нижний край в тех же мутных каплях, что и всё остальное.",
		"Ты провёл по цифрам. Влажно и холодно."],
	"clock": [null, "Тёмный корпус, латунные кольца. Стекло чуть запотело снизу.",
		"Корпус холодный. Стрелку не сдвинуть ни в одну сторону."],
	"chair": [null, "Кресло у окна. На подлокотнике поднос стоял так долго, что остался отпечаток.",
		"Ты провёл рукой по отпечатку. Он не разглаживается."]
}

# Шесть подносов: id -> [точка на полу/мебели, поворот, заголовок, описание, точка обзора]
#
# Их намеренно больше, чем слотов инвентаря. Проверка в аудите закрепляет это
# неравенство: если подносов станет четыре или меньше, круг потеряет свою мысль,
# а аудит останется зелёным.
const TRAYS := {
	"tray_bed": [Vector3(1.25, .62, -1.30), .18, "Поднос на кровати",
		"Стоит поверх покрывала. Колпак холодный, под ним не остыло — оно и не было горячим.",
		Vector3(1.25, 1.35, -.55)],
	"tray_desk": [Vector3(3.70, .84, 1.62), -.40, "Поднос на столе",
		"Занял весь письменный стол. Приборы в салфетке, салфетка не развёрнута.",
		Vector3(3.00, 1.30, 1.62)],
	"tray_table": [Vector3(1.05, .43, 3.15), .32, "Поднос на журнальном столике",
		"Второй завтрак поверх первого. Нижний поднос к столу прилип.",
		Vector3(1.05, 1.30, 2.35)],
	"tray_floor_hall": [Vector3(-2.95, .02, -2.00), .62, "Поднос у входа",
		"Стоит на полу у самой двери. Кто-то ставил его, не заходя.",
		Vector3(-2.80, 1.20, -1.75)],
	"tray_floor_bath": [Vector3(-2.90, .02, .90), -.24, "Поднос в ванной",
		"На плитке, у самого унитаза. Колпак снят и лежит рядом.",
		Vector3(-2.60, 1.20, .40)],
	"tray_minibar": [Vector3(4.00, .96, 4.68), .12, "Поднос на минибаре",
		"Поставлен сверху, потому что внутрь уже не влезло.",
		Vector3(3.30, 1.35, 4.68)]
}
const SLOTS := 4

var act := Act.CARRY
var carried := {}
var removed := {}
var tray_nodes := {}

func _ready() -> void:
	name = "GluttonyLevel"
	audit_tag = "GLUT"
	player = get_parent().get_node("Player")
	camera = player.get_node("Head/Camera3D")
	world_environment = get_parent().get_node_or_null("Environment")
	cache_room()
	build_systems()
	build_props()
	register_targets()
	wire_signals()
	full_reset()
	if OS.has_environment("GLUT_AUDIT"):
		await get_tree().process_frame
		run_audit()
	elif OS.has_environment("GLUT_WALKTHROUGH"):
		# Тот же самый прогон, что и в аудите, но с картинкой.
		begin_walkthrough(OS.get_environment("GLUT_WALKTHROUGH"))
		await get_tree().process_frame
		run_audit()
	else:
		hud.show_message("КРУГ III\nНЕНАСЫТНОСТЬ", 3.2)
		show_controls()

func show_controls() -> void:
	var mark := epoch
	await get_tree().create_timer(4.2).timeout
	if mark != epoch:
		return
	hud.show_message("WASD — идти   ·   ЛКМ — рассмотреть   ·   E — тронуть   ·   1 2 3 4 — слот   ·   H — подсказка", 5.4)

func build_props() -> void:
	clock_display = Build.label3d(self, "ClockDisplay", "16:06:00", Vector3(2.28, 1.74, .915), Vector3.ZERO, 30, .0032)
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
	clock.start_label = "16:06"
	clock.end_label = "16:07"
	clock.refresh()

	# Поднос переиспользован из коридора шестнадцатого этажа: та же модель, тот же
	# вес в пакете. Круг не добавляет ни одного нового ассета.
	var root := get_parent()
	var tray_scene := load("res://assets/models/corridor_service_tray.glb") as PackedScene
	for id in TRAYS:
		var row: Array = TRAYS[id]
		tray_nodes[id] = root.placed_model(self, "Tray_" + str(id), tray_scene,
			row[0], Vector3(0, row[1], 0),
			{"brass": "brass", "chrome": "chrome", "glass": "glass", "cream": "cream"})

func register_targets() -> void:
	for id in TRAYS:
		var row: Array = TRAYS[id]
		interactor.register(str(id), row[0] + Vector3(0, .10, 0), Vector3(.46, .30, .38), {
			"title": str(row[2]), "text": str(row[3]), "usable": true})
	# Дверь регистрируется вместе с обстановкой ниже: она и есть зона "door" из
	# ROOM_ZONES, а её текст переопределён в ROOM_ZONE_TEXT под этот круг.
	# Обстановка номера: та же геометрия, что и в остальных кругах, свой текст —
	# про количество и холод. Без неё круг только сюжетные семь зон, и комната
	# читается недоделанной, сколько бы подносов в ней ни стояло.
	register_room_flavor(ROOM_ZONE_TEXT)
	register_switch_zones()

func reach_origins() -> Dictionary:
	var origins := {"door": Vector3(-2.65, 1.20, -1.75)}
	for id in TRAYS:
		origins[str(id)] = (TRAYS[id] as Array)[4]
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
		var selected := inventory.selected()
		if not selected.is_empty():
			inspect.open(selected, inventory.entry(selected))
		return
	if not interactor.targets.has(id):
		return
	inspect.open(id, interactor.entry(id))
	interactor.mark_seen(id)

func on_used(id: String) -> void:
	if inspect.active or code_lock.active:
		return
	if id == "door":
		put_out()
		return
	if TRAYS.has(id):
		take_tray(id)
		return
	if id.begins_with("switch_"):
		toggle_switch(id)
		return
	if ROOM_ZONES.has(id):
		use_room_zone(id)
		return

func take_tray(id: String) -> void:
	if carried.has(id) or removed.has(id):
		return
	# Четыре слота — это и есть механика круга: подносов шесть, и в руках все не
	# удержать. Отказ обязан объяснять причину, иначе читается как поломка.
	if inventory.items.size() >= SLOTS:
		hud.show_message("В руках больше не держится. Вынеси то, что взял.", 3.2)
		return
	carried[id] = true
	tray_nodes[id].visible = false
	interactor.set_usable(id, false)
	var zone := interactor.zone(id)
	if zone:
		# Зону гасим вместе с подносом: [E] над пустым местом — это обещание,
		# которого комната не выполнит.
		zone.collision_layer = 0
	inventory.add(id, "поднос", tray_nodes[id],
		str((TRAYS[id] as Array)[3]),
		"На обороте наклейка службы: номер 1604, время не пропечаталось.")
	announce_pickup(id, "Поднос у тебя в руках.")
	focus_door()

func announce_pickup(id: String, headline: String) -> void:
	var slot := inventory.slot_of(id)
	if slot < 1:
		hud.show_message(headline, 3.0)
		return
	hud.show_message("%s\nСлот %d. Занято %d из %d." % [headline, slot, inventory.items.size(), SLOTS], 4.2)

func put_out() -> void:
	var selected := inventory.selected()
	if selected.is_empty() or not TRAYS.has(selected):
		if carried.is_empty():
			hud.show_message("Дверь заперта. Выносить пока нечего.", 3.0)
		else:
			hud.show_message("Возьми поднос в руку цифрой слота, потом нажми E на двери.", 3.4)
		return
	carried.erase(selected)
	removed[selected] = true
	inventory.remove(selected)
	cue.play("latch")
	clock.advance(7.0, "tray")
	var left := TRAYS.size() - removed.size()
	if left > 0:
		hud.show_message("Поднос ушёл в щель. Осталось %d." % left, 3.2)
		focus_next_tray()
		return
	empty_room()

func empty_room() -> void:
	act = Act.DRIP
	hints.set_enabled(false)
	clock.ceiling = ClockDirector.SPAN
	hud.show_message("Номер пуст. Впервые видно ковёр целиком.", 4.0)
	# Акты II и III не реализованы: круг доводит минуту и на этом кончается.
	# Так честнее, чем оставить игрока в пустой комнате без следующего шага.
	clock.run_out(6.0)

func on_minute_reached() -> void:
	act = Act.COMPLETE
	clock_display.text = "16:07:00"
	hud.show_message("КРУГ III — НЕНАСЫТНОСТЬ\nАкт I пройден", 4.0)

func focus_next_tray() -> void:
	for id in TRAYS:
		if removed.has(id) or carried.has(id):
			continue
		hints.set_focus((TRAYS[id] as Array)[0], [
			"В номере ещё стоит еда.",
			"Осталось подносов: %d. Их надо вынести за дверь." % (TRAYS.size() - removed.size()),
			"Возьми поднос (E), потом нажми E на входной двери. В руках держится %d." % SLOTS])
		hints.reset_timer()
		return
	focus_door()

func focus_door() -> void:
	hints.set_focus(Vector3(-2.65, .72, -2.88), [
		"Руки заняты.",
		"Подносы выставляют за входную дверь.",
		"Выбери поднос цифрой слота и нажми E на входной двери."])
	hints.reset_timer()

func reward(id: String) -> void:
	if rewarded.has(id):
		return
	rewarded[id] = true
	clock.advance(.5)

func current_goal() -> String:
	match act:
		Act.CARRY:
			if not carried.is_empty():
				return "В руках подносов: %d. Выставь их за входную дверь: выбери слот цифрой и нажми E на двери." \
					% carried.size()
			return "Вынеси всю еду из номера. Осталось подносов: %d из %d. Больше %d в руках не держится." \
				% [TRAYS.size() - removed.size(), TRAYS.size(), SLOTS]
		Act.DRIP:
			return "Номер пуст. Минута добегает сама."
		Act.COMPLETE:
			return "Акт I третьего круга пройден."
	return "Оглядись."

func full_reset() -> void:
	epoch += 1
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	act = Act.CARRY
	carried.clear()
	removed.clear()
	rewarded.clear()
	quiet_said.clear()
	for id in tray_nodes:
		tray_nodes[id].visible = true
	player.transform = original.player
	player.global_position = Vector3(1.25, .05, .15)
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	interactor.clear()
	interactor.set_locked(false)
	for id in TRAYS:
		var zone := interactor.zone(str(id))
		if zone:
			zone.collision_layer = 2
	inventory.clear()
	inspect.close()
	code_lock.close()
	anomalies.clear()
	hints.clear()
	hud.reset()
	clock.reset()
	clock.start_label = "16:06"
	clock.end_label = "16:07"
	clock.refresh()
	clock.start()
	clock.ceiling = 50.0
	hints.set_enabled(true)
	focus_next_tray()

func run_audit() -> void:
	await get_tree().physics_frame
	# Неравенство «подносов больше, чем слотов» — это и есть мысль круга.
	# Без проверки её можно потерять правкой данных, и аудит останется зелёным.
	if not require(TRAYS.size() > SLOTS,
			"circle III lost its point: %d trays for %d slots" % [TRAYS.size(), SLOTS]): return
	# Подносы плюс обстановка номера (ROOM_ZONES, куда входит и дверь) и четыре
	# выключателя: то же число закреплено проверкой, что и в круге II, чтобы
	# пустая по интерактивности комната не вернулась незаметно.
	var expected := TRAYS.size() + ROOM_ZONES.size() + 4
	if not require(interactor.targets.size() == expected,
			"unexpected zone count: %d, expected %d" % [interactor.targets.size(), expected]): return
	for id in ROOM_ZONES:
		if not require(interactor.entry(str(id))["usable"], "room zone is not usable: %s" % id): return
		if not require(interactor.prompt_state(str(id)) == Hud.Aim.EXAMINE,
				"room zone promises [E]: %s" % id): return
	# Четыре подноса стоят прямо на чужой мебели — на столе, на столике, на
	# минибаре и на рулоне у самого входа, — и их зоны честно пересекаются с
	# зонами этой мебели. Тот же осознанный приём, что и с сейфом внутри шкафа
	# в Круге I: пересечение — часть замысла, а не недосмотр.
	if not check_no_overlap([
			["tray_desk", "desk_chair"], ["tray_desk", "desk_lamp"],
			["tray_table", "coffee_table"],
			["tray_minibar", "minibar"], ["tray_minibar", "living_mirror"],
			["tray_floor_hall", "entry_rug"]]): return
	if not check_reachable(reach_origins()): return
	if not check_actions_bound(TRAYS.keys() + ["door"]): return
	if not require(message_on_screen(), "message sits off screen"): return
	if not require(act == Act.CARRY, "circle III did not start in the carry act"): return
	if not require(current_goal().contains("Вынеси"), "H says nothing useful in act I"): return
	await shot("c3_loaded", Vector3(1.25, .05, .15), .4, -.20)

	# Инвентарь обязан упереться в потолок: берём четыре подноса и просим пятый.
	var ids := TRAYS.keys()
	for index in range(SLOTS):
		on_used(str(ids[index]))
	if not require(inventory.items.size() == SLOTS,
			"inventory did not fill up: %d" % inventory.items.size()): return
	on_used(str(ids[SLOTS]))
	if not require(inventory.items.size() == SLOTS, "the fifth tray fit into four slots"): return
	if not require(not carried.has(str(ids[SLOTS])), "the fifth tray was taken anyway"): return
	await shot("c3_hands_full", Vector3(-2.65, .05, -1.90), 0.0, -.10)

	# Выносим всё, возвращаясь за остатком: именно так и пойдёт живой игрок.
	var guard_carry := 0
	while removed.size() < TRAYS.size() and guard_carry < 40:
		guard_carry += 1
		if not carried.is_empty():
			inventory.select_by_id(str(carried.keys()[0]))
			on_used("door")
			continue
		for id in TRAYS:
			if not removed.has(str(id)) and inventory.items.size() < SLOTS:
				on_used(str(id))
	if not require(removed.size() == TRAYS.size(),
			"not every tray was put out: %d" % removed.size()): return
	if not require(inventory.items.size() == 0, "trays stayed in the inventory"): return
	if not require(act == Act.DRIP, "emptying the room did not end act I"): return
	await shot("c3_empty", Vector3(1.25, .05, .15), .4, -.20)

	var guard := 0
	while act != Act.COMPLETE and guard < 200:
		await get_tree().create_timer(.1).timeout
		guard += 1
	if not require(act == Act.COMPLETE, "clock never reached 16:07"): return
	if not require(clock_display.text == "16:07:00", "clock shows %s" % clock_display.text): return
	await shot("c3_complete")

	full_reset()
	if not require(act == Act.CARRY and removed.is_empty() and carried.is_empty(),
			"full_reset did not clean up"): return
	for id in tray_nodes:
		if not require(tray_nodes[id].visible, "full_reset left a tray hidden: %s" % id): return

	print("GLUT_AUDIT_OK circle III act I: %d zones, %d trays, %d slots, clock 16:06->16:07"
		% [interactor.targets.size(), TRAYS.size(), SLOTS])
	prepare_shutdown()
	await get_tree().create_timer(.35).timeout
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if (event as InputEventKey).keycode == KEY_H:
		get_viewport().set_input_as_handled()
		request_hint()
