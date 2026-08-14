extends CircleLevel

# КРУГ IX — «ПРЕДАТЕЛЬСТВО». Комната 1604, 16:12 → 16:13.
#
# У Данте девятый круг — Коцит, замёрзшее озеро в самом сердце ада: чем
# глубже предательство, тем гуще лёд. Здесь номер за девять минут выстыл
# до пяти точек настоящего инея — там, где отопление работает исправно и
# холода взяться неоткуда. Не образ Данте в лоб, а то же самое ощущение:
# нечто самое близкое застывает первым.
#
# Глагол круга — ПРИЗНАТЬ. Тот же приём цепочки, что в Кругах VI и VIII, но
# здесь порядок — не игра в открывание и не разоблачение обмана, а то,
# как холод расходится от одной точки к другой: каждую можно отогреть
# только после предыдущей, потому что раньше в комнате просто не успело
# похолодеть настолько. Это последний круг из девяти, и он не решает
# головоломку хитрее прежних — он их завершает тем же самым языком.

enum Act { FROZEN, COMPLETE }

const ORDER := ["frost_mirror", "frost_glass", "frost_window", "frost_doorknob", "frost_floor"]

# id -> [позиция, поворот, заголовок, текст мёрзлого, текст отогретого,
# точка обзора].
const FROST := {
	"frost_mirror": [Vector3(-3.65, 1.15, -.15), 0.0, "Иней на зеркале",
		"Тонкий узор инея по нижнему краю стекла — там, где ванная теплее всего в номере.",
		"Иней стаял под ладонью и не появился снова. За стеклом — обычное отражение, без подмен и трещин.",
		Vector3(-3.20, 1.20, -.15)],
	"frost_glass": [Vector3(2.40, .85, 1.20), 0.0, "Лёд в стакане",
		"Стакан на столе покрыт наледью изнутри — как будто в нём давно не было ничего тёплого.",
		"Лёд растаял в ладони за секунды. Стакан обычный, пустой, комнатной температуры.",
		Vector3(2.00, 1.20, 1.20)],
	"frost_window": [Vector3(3.60, 1.55, -1.45), 0.0, "Иней на окне спальни",
		"Стекло изнутри в узорах, как в мороз — а за окном, если верить прошлым кругам, стояла обычная ночь.",
		"Узор стаял от одного касания. Стекло мокрое, обычное, без подмены за ним.",
		Vector3(3.15, 1.40, -1.45)],
	"frost_doorknob": [Vector3(-1.20, .90, -1.20), 0.0, "Ледяная дверная ручка",
		"Ручка внутренней двери холодна настолько, что к ней больно прикасаться голой рукой.",
		"Ручка отогрелась в ладони за несколько секунд. Обычная латунь, тёплая, как и должна быть.",
		Vector3(-1.20, 1.10, -1.60)],
	"frost_floor": [Vector3(2.20, .03, 2.00), 0.0, "Ледяное пятно на полу",
		"Ровный круг инея на паркете — на полпути между спальней и гостиной, там, где никто подолгу не стоит.",
		"Иней тает под ногой, оставляя обычный тёплый паркет. Это было последнее холодное место в номере.",
		Vector3(1.80, 1.20, 1.60)]
}

var act := Act.FROZEN
var thawed := {}
var step := 0
var frost_nodes := {}

func _ready() -> void:
	name = "TreacheryLevel"
	audit_tag = "TREACH"
	player = get_parent().get_node("Player")
	camera = player.get_node("Head/Camera3D")
	world_environment = get_parent().get_node_or_null("Environment")
	cache_room()
	build_systems()
	build_props()
	register_targets()
	wire_signals()
	full_reset()
	if OS.has_environment("TREACH_AUDIT"):
		await get_tree().process_frame
		run_audit()
	elif OS.has_environment("TREACH_WALKTHROUGH"):
		begin_walkthrough(OS.get_environment("TREACH_WALKTHROUGH"))
		await get_tree().process_frame
		run_audit()
	else:
		hud.show_message("КРУГ IX\nПРЕДАТЕЛЬСТВО", 3.2)
		show_controls()

func show_controls() -> void:
	var mark := epoch
	await get_tree().create_timer(4.2).timeout
	if mark != epoch:
		return
	hud.show_message("WASD — идти   ·   ЛКМ — рассмотреть   ·   E — тронуть   ·   H — подсказка", 5.4)

func build_props() -> void:
	clock_display = Build.label3d(self, "ClockDisplay", "16:12:00", Vector3(2.28, 1.74, .915), Vector3.ZERO, 30, .0032)
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
	clock.start_label = "16:12"
	clock.end_label = "16:13"
	clock.refresh()

	var root := get_parent()
	# Ни одного нового ассета — тот же приём, что и во всех кругах после
	# второго.
	frost_nodes["frost_mirror"] = root.placed_model(self, "FrostMirror",
		load("res://assets/models/mirror.glb"), Vector3(-3.65, 1.15, -.30), Vector3(1.5, 0, 0),
		{"wood": "wood2", "glass": "mirror"})
	frost_nodes["frost_glass"] = root.placed_model(self, "FrostGlass",
		load("res://assets/models/c2_toothbrush_glass.glb"), Vector3(2.40, .81, 1.20), Vector3.ZERO,
		{"glass": "glass", "handle": "cream"})
	frost_nodes["frost_window"] = root.placed_model(self, "FrostWindow",
		load("res://assets/models/window_sill.glb"), Vector3(3.60, 1.55, -1.86), Vector3.ZERO,
		{"wood": "wood2", "metal": "brass"})
	frost_nodes["frost_doorknob"] = root.placed_model(self, "FrostDoorknob",
		load("res://assets/models/corridor_door_hanger.glb"), Vector3(-1.20, .90, -1.20), Vector3(0, PI / 2, 0),
		{"brass": "chrome", "tag": "flower_dark"})
	frost_nodes["frost_floor"] = root.placed_model(self, "FrostFloor",
		load("res://assets/models/corridor_carpet_tile.glb"), Vector3(2.20, .01, 2.00), Vector3.ZERO,
		{"carpet": "chrome"})

func register_targets() -> void:
	for id in FROST:
		var row: Array = FROST[id]
		interactor.register(str(id), row[0] + Vector3(0, .08, 0), Vector3(.26, .20, .26), {
			"title": str(row[2]), "text": str(row[3]), "usable": true})
	register_room_flavor(ROOM_ZONE_TEXT)
	register_switch_zones()

const ROOM_ZONE_TEXT := {
	"console": [null, "Столик у двери. Латунь на ощупь холоднее комнаты, будто из другого номера.",
		"Ты подержал ладонь на латуни. Она нагрелась, как обычный металл."],
	"entry_lamp": [null, "Латунная стойка. От неё едва заметно тянет холодом, хотя лампа не горела всю ночь.",
		"Ты обхватил стойку ладонью. Холод ушёл быстро — он был неглубоким."],
	"hall_plant": [null, "Листья подёрнуты инеем по краю, хотя за окном давно не было мороза.",
		"Иней стаял от прикосновения. Листья обычные, только влажные."],
	"hall_painting": [null, "Горное озеро. Рама холоднее стены вокруг неё на пару градусов.",
		"Ты подержал ладонь на раме. Она сравнялась с температурой стены."],
	"entry_rug": [null, "Плотный ворс. Под ногами в этом месте прохладнее, чем на остальном полу.",
		"Ты потоптался на месте. Пол стал ощущаться как везде."],
	"hall_outlet": [null, "Круглое гнездо в латунной рамке.", "Гнездо пустое и холодное."],
	"drawer_left": [null, "Ящик с той стороны кровати. Металлическая ручка ледяная, будто её только что вынули из мороза.",
		"Ты подержал ручку в ладони. Она отдала холод и стала обычной."],
	"drawer_right": [null, "Ящик закрыт обычно — эта сторона не выстыла ничем.",
		"Пусто, и холода здесь не было вовсе."],
	"radiator_bed": [null, "Секционный радиатор. На ощупь тёплый, но воздух рядом с ним предательски холодный.",
		"Вентиль проворачивается вхолостую, как и раньше."],
	"bed_outlet": [null, "Ещё одно гнездо. Вокруг него на обоях едва заметный ледяной ободок.",
		"Ободок стаял под пальцем. Розетка обычная, тёплая."],
	"tub": [null, "Ванна. Вода в кране идёт тёплая, но сама эмаль ледяная на ощупь.",
		"Ты провёл по эмали. Она нагрелась от ладони и осталась такой."],
	"toilet": [null, "Белый фаянс. Бачок покрыт испариной, будто внутри лёд, а не вода.",
		"Испарина стёрлась. Бачок набирает воду ровно, как обычно."],
	"towels": [null, "Сложены гостиничным углом, но на ощупь сырые и холодные, будто из ледника, а не из шкафа.",
		"Ты подержал полотенце в руках. Оно согрелось и стало сухим на вид."],
	"hand_towel": [null, "На латунном кольце, ледяное с одного края.",
		"Полотенце качнулось и вернулось ровно как было, уже тёплым."],
	"wastebasket": [null, "Плетёная корзина. Дно покрыто мелкой изморозью, как в леднике.",
		"Изморозь стаяла от тепла ладони. Корзина обычная, пустая."],
	"shower": [null, "Лейка на шланге. С неё капает не вода, а что-то, что тает на лету.",
		"Вентиль проворачивается свободно. Капля всё равно падает, но уже обычная, тёплая."],
	"toilet_paper": [null, "Рулон на латунном штыре, ледяной с наружного слоя.",
		"Рулон провернулся со щелчком, уже без холода."],
	"sofa": [null, "Бежевая обивка. Одно место продавлено и ледяное — там будто сидели очень долго и очень неподвижно.",
		"Ты положил ладонь на обивку. Холод ушёл почти сразу."],
	"coffee_table": [null, "Лак покрыт тонкой изморозью, хотя стол стоит вдали от окна.",
		"Ты провёл ладонью по столешнице. Изморозь стаяла без следа."],
	"living_armchair": [null, "Оливковое кресло. Подлокотники ледяные, будто на них давно не лежали тёплые руки.",
		"Кресло качнулось. Подлокотники нагрелись от прикосновения."],
	"minibar": [null, "Шкафчик со стеклянной дверцей. Стекло запотело изнутри морозным узором.",
		"Узор стаял. Внутри пусто и уже не холодно."],
	"living_mirror": [null, "Небольшое зеркало. По самому краю рамы полоска инея.",
		"Ты стёр иней пальцем. Стекло чистое, отражение обычное."],
	"living_painting": [null, "Ночной отель, горит одно окно. Холст на ощупь холоднее воздуха вокруг.",
		"Ты подержал ладонь на холсте. Он сравнялся с температурой стены."],
	"desk_lamp": [null, "Рабочая лампа. Абажур ледяной, будто никогда не грелся от лампочки внутри.",
		"Щелчок. Лампа не загорелась, но абажур уже тёплый."],
	"desk_chair": [null, "Отодвинут от стола. Сиденье ледяное — на нём давно никто не согревался.",
		"Стул откатился и остановился, уже не таким холодным."],
	"radiator_living": [null, "Такой же обманчиво холодный, как в спальне.",
		"Тот же холод и тот же свободный вентиль, чуть слабее прежнего."],
	"door": [null, "Латунная ручка. Холоднее, чем должна быть в тёплой комнате.",
		"Замок проворачивается вхолостую, но ручка уже не леденит руку."],
	"plate": [null, "Табличка 1604. Иней тонкой линией лёг вдоль нижнего края цифр.",
		"Ты провёл по цифрам. Иней стаял, цифры на ощупь обычные."],
	"clock": [null, "Тёмный корпус, латунные кольца. Стекло циферблата холоднее, чем корпус вокруг него.",
		"Корпус тёплый. Стрелку не сдвинуть ни в одну сторону."],
	"chair": [null, "Кресло у окна. Плед ледяной, будто пролежал всю ночь у открытой форточки.",
		"Ты подержал плед в руках. Он согрелся и обмяк, как обычная ткань."]
}

func reach_origins() -> Dictionary:
	var origins := {}
	for id in FROST:
		origins[str(id)] = (FROST[id] as Array)[5]
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
	if FROST.has(id):
		thaw(id)
		return
	if id.begins_with("switch_"):
		toggle_switch(id)
		return
	if ROOM_ZONES.has(id):
		use_room_zone(id)
		return

func thaw(id: String) -> void:
	if thawed.has(id):
		return
	if step >= ORDER.size() or str(ORDER[step]) != id:
		# Не по порядку — отказ, а не провал: холод расходится от точки к
		# точке, и дальняя не оттает, пока не оттаяла ближняя.
		hud.show_message("Здесь ещё не успело остыть настолько. Начни с другого места.", 2.8)
		return
	thawed[id] = true
	step += 1
	interactor.set_text(id, str((FROST[id] as Array)[4]))
	cue.play("latch")
	clock.advance(7.0, "thaw")
	if step < ORDER.size():
		hud.show_message("Отогрето. Осталось: %d." % (ORDER.size() - step), 3.0)
		focus_current_frost()
		return
	act = Act.COMPLETE
	clock_display.text = "16:13:00"
	hints.set_enabled(false)
	clock.ceiling = ClockDirector.SPAN
	hud.show_message("В номере больше нет холода. Девятая минута — последняя из тех, что здесь считают.", 4.6)
	clock.run_out(6.0)

func on_minute_reached() -> void:
	clock_display.text = "16:13:00"

func focus_current_frost() -> void:
	if step >= ORDER.size():
		hints.clear_focus()
		return
	var id: String = ORDER[step]
	hints.set_focus((FROST[id] as Array)[0], [
		"В номере ещё есть холод.",
		"Отогрето по порядку: %d из %d." % [step, ORDER.size()],
		"Следующая точка — здесь: %s. Наведись и нажми E." % str((FROST[id] as Array)[2])])
	hints.reset_timer()

func current_goal() -> String:
	match act:
		Act.FROZEN:
			var id: String = ORDER[step] if step < ORDER.size() else ""
			var title := str((FROST[id] as Array)[2]) if not id.is_empty() else ""
			return "Отогревай холод по порядку — %d из %d. Следующее место: %s." \
				% [step, ORDER.size(), title]
		Act.COMPLETE:
			return "Круг IX пройден."
	return "Оглядись."

func full_reset() -> void:
	epoch += 1
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	act = Act.FROZEN
	thawed.clear()
	step = 0
	rewarded.clear()
	quiet_said.clear()
	player.transform = original.player
	player.global_position = Vector3(1.25, .05, .15)
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	lock_entrance_door()
	interactor.clear()
	interactor.set_locked(false)
	inspect.close()
	code_lock.close()
	anomalies.clear()
	hints.clear()
	hud.reset()
	clock.reset()
	clock.start_label = "16:12"
	clock.end_label = "16:13"
	clock.refresh()
	clock.start()
	clock.ceiling = 50.0
	hints.set_enabled(true)
	focus_current_frost()

func run_audit() -> void:
	await get_tree().physics_frame
	if not require(FROST.size() == ORDER.size(), "FROST/ORDER size mismatch"): return
	var expected := FROST.size() + ROOM_ZONES.size() + 4
	if not require(interactor.targets.size() == expected,
			"unexpected zone count: %d, expected %d" % [interactor.targets.size(), expected]): return
	for id in ROOM_ZONES:
		if not require(interactor.entry(str(id))["usable"], "room zone is not usable: %s" % id): return
	if not check_no_overlap(): return
	if not check_reachable(reach_origins()): return
	if not check_actions_bound(FROST.keys()): return
	if not require(message_on_screen(), "message sits off screen"): return
	if not require(act == Act.FROZEN, "circle IX did not start in the frozen act"): return
	if not require(current_goal().contains("холод"), "H says nothing useful in act I"): return
	await shot("c9_loaded", Vector3(1.25, .05, .15), .4, -.20)

	on_used(str(ORDER[2]))
	if not require(not thawed.has(str(ORDER[2])), "out-of-order frost thawed anyway: %s" % ORDER[2]): return
	if not require(step == 0, "step advanced on an out-of-order attempt"): return
	await shot("c9_out_of_order", (FROST[ORDER[0]] as Array)[5])

	for index in range(ORDER.size()):
		var id: String = ORDER[index]
		if not require(step == index, "step out of sync before thawing %s" % id): return
		on_used(id)
		if not require(thawed.has(id), "frost did not thaw in order: %s" % id): return
	if not require(step == ORDER.size(), "not every frost was thawed: %d" % step): return
	if not require(act == Act.COMPLETE, "thawing every frost did not end act I"): return
	await shot("c9_thawed", Vector3(1.25, .05, .15), .4, -.20)

	var wait_guard := 0
	while clock_display.text != "16:13:00" and wait_guard < 200:
		await get_tree().create_timer(.1).timeout
		wait_guard += 1
	if not require(clock_display.text == "16:13:00", "clock shows %s" % clock_display.text): return
	await shot("c9_complete")

	full_reset()
	if not require(act == Act.FROZEN and thawed.is_empty() and step == 0,
			"full_reset did not clean up"): return

	print("TREACH_AUDIT_OK circle IX: %d zones, %d frost points, clock 16:12->16:13"
		% [interactor.targets.size(), FROST.size()])
	prepare_shutdown()
	await get_tree().create_timer(.35).timeout
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if (event as InputEventKey).keycode == KEY_H:
		get_viewport().set_input_as_handled()
		request_hint()
