extends CircleLevel

# КРУГ VIII — «ОБМАН». Комната 1604, 16:11 → 16:12.
#
# У Данте восьмой круг — Злопазухи, десять рвов обмана, один за другим, и
# грешники каждого рва прикрывают следующий. Здесь это пять подделок в
# номере, вложенных одна в другую: разоблачённая обманка называет, где
# искать следующую, — обман прикрывает обман, пока не дойдёшь до последнего,
# самого простого и самого неправильного.
#
# Глагол круга — РАЗОБЛАЧИТЬ ПО ПОРЯДКУ. Тот же приём цепочки, что и в
# Круге VI, но там запертое просто открывали; здесь важно не открыть, а
# понять, что вещь — не то, чем кажется, прежде чем `E` это подтвердит.
# Тронуть не по порядку номер отказывает так же ровно, как Круг VI: ничего
# не отнимается, часы не отматываются назад.

enum Act { HIDDEN, COMPLETE }

const ORDER := ["fake_letter", "fake_bill", "fake_photo", "fake_key", "fake_view"]

# id -> [позиция, поворот, заголовок, текст скрытого обмана, текст
# разоблачения, точка обзора].
const DECEITS := {
	"fake_letter": [Vector3(1.90, .90, -1.75), 0.0, "Записка на кровати",
		"Подписана чужим именем, но почерк — твой собственный, только слегка изменённый наклон.",
		"Ты сверил почерк с обратной стороной квитанции. Совпадает буква в букву. Внизу приписка: «счёт из бара тоже не сходится».",
		Vector3(1.45, 1.20, -1.75)],
	"fake_bill": [Vector3(2.75, .85, 4.45), 0.0, "Счёт из бара",
		"Сумма пропечатана крупно и ровно — слишком ровно для кассового аппарата.",
		"Под верхним слоем другая цифра, вдвое меньше. Наклейку подменили. На обороте: «рамка на стене — тоже не та».",
		Vector3(2.75, 1.25, 4.05)],
	"fake_photo": [Vector3(2.10, 1.30, 3.85), 0.0, "Фотография в рамке",
		"Семейный снимок в латунной рамке — лица знакомые, но улыбки одинаковые до неестественности.",
		"Это типографский вкладыш, который продают вместе с рамкой. Настоящую фотографию из неё вынули. За стеклом след: «ключ на тумбочке — не от этого номера».",
		Vector3(1.65, 1.30, 3.85)],
	"fake_key": [Vector3(2.60, .65, -1.95), 0.0, "Запасной ключ на тумбочке",
		"Латунная бирка с номером — вроде бы 1604, но цифры чуть плотнее прижаты друг к другу, чем на табличке.",
		"Бирка перебита: под новой гравировкой другой номер — 1602. Ключ не от этой двери. На обороте нацарапано: «за окном — не улица».",
		Vector3(2.15, 1.05, -1.95)],
	"fake_view": [Vector3(.80, 1.45, 4.60), 0.0, "Вид за окном",
		"Улица за стеклом стоит неестественно ровно — ни одна тень не сдвинулась с тех пор, как ты первый раз посмотрел.",
		"Стекло на ощупь тёплое и плоское, без глубины. За ним не улица, а подсвеченная фотография, натянутая на раму.",
		Vector3(.80, 1.45, 4.15)]
}

var act := Act.HIDDEN
var exposed := {}
var step := 0
var deceit_nodes := {}

func _ready() -> void:
	name = "FraudLevel"
	audit_tag = "FRAUD"
	player = get_parent().get_node("Player")
	camera = player.get_node("Head/Camera3D")
	world_environment = get_parent().get_node_or_null("Environment")
	cache_room()
	build_systems()
	build_props()
	register_targets()
	wire_signals()
	full_reset()
	if OS.has_environment("FRAUD_AUDIT"):
		await get_tree().process_frame
		run_audit()
	elif OS.has_environment("FRAUD_WALKTHROUGH"):
		begin_walkthrough(OS.get_environment("FRAUD_WALKTHROUGH"))
		await get_tree().process_frame
		run_audit()
	else:
		hud.show_message("КРУГ VIII\nОБМАН", 3.2)
		show_controls()

func show_controls() -> void:
	var mark := epoch
	await get_tree().create_timer(4.2).timeout
	if mark != epoch:
		return
	hud.show_message("WASD — идти   ·   ЛКМ — рассмотреть   ·   E — тронуть   ·   H — подсказка", 5.4)

func build_props() -> void:
	clock_display = Build.label3d(self, "ClockDisplay", "16:11:00", Vector3(2.28, 1.74, .915), Vector3.ZERO, 30, .0032)
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
	clock.start_label = "16:11"
	clock.end_label = "16:12"
	clock.refresh()

	var root := get_parent()
	# Ни одного нового ассета — тот же приём, что в Кругах III–VII.
	deceit_nodes["fake_letter"] = root.placed_model(self, "FakeLetter",
		load("res://assets/models/c2_letter_sheet.glb"), Vector3(1.90, .90, -1.75), Vector3.ZERO,
		{"paper": "cream"})
	deceit_nodes["fake_bill"] = root.placed_model(self, "FakeBill",
		load("res://assets/models/writing_set.glb"), Vector3(2.75, .53, 4.45), Vector3(0, .3, 0),
		{"wood": "wood2", "brass": "brass", "paper": "cream"})
	deceit_nodes["fake_photo"] = root.placed_model(self, "FakePhoto",
		load("res://assets/models/fancy_picture_frame.glb"), Vector3(2.10, 1.30, 4.05), Vector3(0, PI, 0),
		{"frame": "brass"})
	deceit_nodes["fake_key"] = root.placed_model(self, "FakeKey",
		load("res://assets/models/corridor_door_hanger.glb"), Vector3(2.60, .65, -1.95), Vector3(0, .4, 0),
		{"brass": "brass", "tag": "flower_dark"})
	deceit_nodes["fake_view"] = root.placed_model(self, "FakeView",
		load("res://assets/models/window_sill.glb"), Vector3(.80, 1.45, 4.95), Vector3.ZERO,
		{"wood": "wood2", "metal": "brass"})

func register_targets() -> void:
	for id in DECEITS:
		var row: Array = DECEITS[id]
		interactor.register(str(id), row[0] + Vector3(0, .06, 0), Vector3(.26, .20, .26), {
			"title": str(row[2]), "text": str(row[3]), "usable": true})
	register_room_flavor(ROOM_ZONE_TEXT)
	register_switch_zones()

const ROOM_ZONE_TEXT := {
	"console": [null, "Столик у двери. Инкрустация под латунь на самом деле краска — на сколе виден пластик.",
		"Ты поскрёб инкрустацию ногтем. Под ней действительно пластик, а не металл."],
	"entry_lamp": [null, "Латунная стойка. На вид литая, но по звуку от щелчка — полая внутри.",
		"Ты постучал по стойке. Звук глухой и лёгкий — не литьё, штамповка под литьё."],
	"hall_plant": [null, "Листья ровные и глянцевые сверх меры — не поливали, потому что не растение.",
		"Ты потрогал лист. Он гладкий и прохладный — ткань, а не зелень."],
	"hall_painting": [null, "Горное озеро. Мазки нанесены слишком равномерно для руки — как будто по трафарету.",
		"Ты провёл пальцем по холсту. Фактура печатная, а не масляная — репродукция под оригинал."],
	"entry_rug": [null, "Плотный ворс. С изнанки бирка обрезана — там, где обычно пишут состав и происхождение.",
		"Ты заглянул под край. Бирка срезана нарочно — коврик выдают за что-то дороже, чем он есть."],
	"hall_outlet": [null, "Круглое гнездо в латунной рамке.", "Гнездо пустое и холодное."],
	"drawer_left": [null, "Ящик с той стороны кровати. Ручка приклеена, а не привинчена — держится, пока не дёрнешь сильно.",
		"Ты подёргал ручку. Она держится на клею — не настоящее крепление."],
	"drawer_right": [null, "Ящик закрыт обычно — эта сторона не подделана ничем.",
		"Пусто, и всё здесь настоящее."],
	"radiator_bed": [null, "Секционный радиатор. Тёплый на вид, но на ощупь ровно комнатной температуры — не работает и не должен.",
		"Вентиль проворачивается вхолостую, как и раньше."],
	"bed_outlet": [null, "Ещё одно гнездо. Провода за ним не подключены ни к чему — розетка нарисована для вида.",
		"Ты пощупал изнутри. Пусто и без единого провода."],
	"tub": [null, "Ванна. Отблеск на эмали — не глазурь, а лак поверх обычного металла.",
		"Ты провёл по дну. Лак липнет к пальцу — не настоящая эмаль."],
	"toilet": [null, "Белый фаянс. Клеймо производителя нарисовано, не отлито в форме.",
		"Клеймо стирается пальцем наполовину — краска, не литьё."],
	"towels": [null, "Сложены гостиничным углом. Вышитая монограмма отеля — просто печать, нитки нет.",
		"Ты провёл по монограмме. Гладкая, без единого стежка — печать на ткани."],
	"hand_towel": [null, "На латунном кольце. Кольцо на вид тяжёлое — но пустотелое, судя по звону.",
		"Полотенце качнулось и вернулось ровно как было."],
	"wastebasket": [null, "Плетёная корзина. Плетение с одной стороны — с другой ровный пластик под цвет лозы.",
		"Ты провёл по задней стенке. Пластик, отлитый под плетение."],
	"shower": [null, "Лейка на шланге. Отверстия для воды пробиты не насквозь с половины лейки.",
		"Половина отверстий глухая. Лейка декоративная наполовину."],
	"toilet_paper": [null, "Рулон на латунном штыре. Штырь на вид латунный, а магнитится — значит, крашеная сталь.",
		"Рулон провернулся со щелчком."],
	"sofa": [null, "Бежевая обивка. На вид ткань, на ощупь — тиснёный винил под ткань.",
		"Ты провёл ладонью. Прохладный и гладкий — не текстиль."],
	"coffee_table": [null, "Лак ровный и без единой поры — не дерево, а плёнка на прессованной плите.",
		"Ты постучал по краю. Звук пустой — не массив, а плита."],
	"living_armchair": [null, "Оливковое кресло. Строчка на подлокотнике декоративная — под ней клеевой шов, не нитка.",
		"Кресло качнулось и осталось стоять как было."],
	"minibar": [null, "Шкафчик со стеклянной дверцей. Стекло — на самом деле прозрачный пластик, царапины уже есть.",
		"Ты постучал по дверце. Звук пластиковый, глухой — не стекло."],
	"living_mirror": [null, "Небольшое зеркало. Отражение чуть теплее по цвету, чем должно — амальгама подкрашена.",
		"Ты приблизил лицо. Отражение своё, просто цвет неверный — дешёвая амальгама."],
	"living_painting": [null, "Ночной отель, горит одно окно. Рама — пластик под латунь, слишком лёгкая в руке.",
		"Рама на месте. На вес она куда легче, чем кажется."],
	"desk_lamp": [null, "Рабочая лампа. Абажур — не ткань, а тиснёный пластик под лён.",
		"Щелчок. Лампа не загорелась."],
	"desk_chair": [null, "Отодвинут от стола. Обивка сиденья — виниловая имитация кожи, свежая, без единой потёртости.",
		"Стул откатился и остановился."],
	"radiator_living": [null, "Такой же ненастоящий, как в спальне.",
		"Тот же холод и тот же свободный вентиль."],
	"door": [null, "Латунная ручка. На самом деле хромированная сталь, покрашенная под латунь — краска стёрлась у основания.",
		"Замок проворачивается вхолостую."],
	"plate": [null, "Табличка 1604. Цифры приклеены отдельно, не выгравированы — под пальцем чувствуется край наклейки.",
		"Ты провёл по цифрам. Край наклейки чувствуется отчётливо."],
	"clock": [null, "Тёмный корпус, латунные кольца. Стрелки нарисованы на стекле, а не движутся отдельно от циферблата.",
		"Корпус тёплый. Стрелку не сдвинуть ни в одну сторону."],
	"chair": [null, "Кресло у окна. Плед выглядит шерстяным, но искрит от прикосновения — синтетика.",
		"Ты провёл рукой по пледу. Искрит едва заметно — точно не шерсть."]
}

func reach_origins() -> Dictionary:
	var origins := {}
	for id in DECEITS:
		origins[str(id)] = (DECEITS[id] as Array)[5]
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
	if DECEITS.has(id):
		expose(id)
		return
	if id.begins_with("switch_"):
		toggle_switch(id)
		return
	if ROOM_ZONES.has(id):
		use_room_zone(id)
		return

func expose(id: String) -> void:
	if exposed.has(id):
		return
	if step >= ORDER.size() or str(ORDER[step]) != id:
		# Не по порядку — отказ, а не провал: обман прикрывает обман, и
		# следующий не найти, пока не разоблачён текущий.
		hud.show_message("Пока не за что зацепиться. Разберись с тем, что уже нашёл.", 2.8)
		return
	exposed[id] = true
	step += 1
	interactor.set_text(id, str((DECEITS[id] as Array)[4]))
	cue.play("latch")
	clock.advance(7.0, "expose")
	if step < ORDER.size():
		hud.show_message("Разоблачено. Осталось: %d." % (ORDER.size() - step), 3.0)
		focus_current_deceit()
		return
	act = Act.COMPLETE
	clock_display.text = "16:12:00"
	hints.set_enabled(false)
	clock.ceiling = ClockDirector.SPAN
	hud.show_message("Пять подделок разоблачены. В номере не осталось ничего, чем оно притворялось.", 4.2)
	clock.run_out(6.0)

func on_minute_reached() -> void:
	clock_display.text = "16:12:00"

func focus_current_deceit() -> void:
	if step >= ORDER.size():
		hints.clear_focus()
		return
	var id: String = ORDER[step]
	hints.set_focus((DECEITS[id] as Array)[0], [
		"В номере ещё есть подделка.",
		"Разоблачено по порядку: %d из %d." % [step, ORDER.size()],
		"Следующая по цепочке — здесь: %s. Наведись и нажми E." % str((DECEITS[id] as Array)[2])])
	hints.reset_timer()

func current_goal() -> String:
	match act:
		Act.HIDDEN:
			var id: String = ORDER[step] if step < ORDER.size() else ""
			var title := str((DECEITS[id] as Array)[2]) if not id.is_empty() else ""
			return "Разоблачай подделки по цепочке — %d из %d. Следующая: %s." \
				% [step, ORDER.size(), title]
		Act.COMPLETE:
			return "Круг VIII пройден."
	return "Оглядись."

func full_reset() -> void:
	epoch += 1
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	act = Act.HIDDEN
	exposed.clear()
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
	clock.start_label = "16:11"
	clock.end_label = "16:12"
	clock.refresh()
	clock.start()
	clock.ceiling = 50.0
	hints.set_enabled(true)
	focus_current_deceit()

func run_audit() -> void:
	await get_tree().physics_frame
	if not require(DECEITS.size() == ORDER.size(), "DECEITS/ORDER size mismatch"): return
	var expected := DECEITS.size() + ROOM_ZONES.size() + 4
	if not require(interactor.targets.size() == expected,
			"unexpected zone count: %d, expected %d" % [interactor.targets.size(), expected]): return
	for id in ROOM_ZONES:
		if not require(interactor.entry(str(id))["usable"], "room zone is not usable: %s" % id): return
	if not check_no_overlap(): return
	if not check_reachable(reach_origins()): return
	if not check_actions_bound(DECEITS.keys()): return
	if not require(message_on_screen(), "message sits off screen"): return
	if not require(act == Act.HIDDEN, "circle VIII did not start in the hidden act"): return
	if not require(current_goal().contains("подделки"), "H says nothing useful in act I"): return
	await shot("c8_loaded", Vector3(1.25, .05, .15), .4, -.20)

	on_used(str(ORDER[2]))
	if not require(not exposed.has(str(ORDER[2])), "out-of-order deceit exposed anyway: %s" % ORDER[2]): return
	if not require(step == 0, "step advanced on an out-of-order attempt"): return
	await shot("c8_out_of_order", (DECEITS[ORDER[0]] as Array)[5])

	for index in range(ORDER.size()):
		var id: String = ORDER[index]
		if not require(step == index, "step out of sync before exposing %s" % id): return
		on_used(id)
		if not require(exposed.has(id), "deceit did not expose in order: %s" % id): return
	if not require(step == ORDER.size(), "not every deceit was exposed: %d" % step): return
	if not require(act == Act.COMPLETE, "exposing every deceit did not end act I"): return
	await shot("c8_exposed", Vector3(1.25, .05, .15), .4, -.20)

	var wait_guard := 0
	while clock_display.text != "16:12:00" and wait_guard < 200:
		await get_tree().create_timer(.1).timeout
		wait_guard += 1
	if not require(clock_display.text == "16:12:00", "clock shows %s" % clock_display.text): return
	await shot("c8_complete")

	full_reset()
	if not require(act == Act.HIDDEN and exposed.is_empty() and step == 0,
			"full_reset did not clean up"): return

	print("FRAUD_AUDIT_OK circle VIII: %d zones, %d deceits, clock 16:11->16:12"
		% [interactor.targets.size(), DECEITS.size()])
	prepare_shutdown()
	await get_tree().create_timer(.35).timeout
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if (event as InputEventKey).keycode == KEY_H:
		get_viewport().set_input_as_handled()
		request_hint()
