extends CircleLevel

# КРУГ VII — «НАСИЛИЕ». Комната 1604, 16:10 → 16:11.
#
# У Данте седьмой круг — насилие: против ближнего, против себя, против
# природы и искусства. Правила проекта запрещают смерть, наказание игрока и
# любой физический вред как аттракцион, поэтому здесь нет ни капли того
# насилия, что было применено, — только следы того, что удержали в
# последний момент. Пять мест в номере: там ударили и не достигли цели —
# кулак разжали раньше, чем он долетел до стены. Ничего не сломано. Именно
# в этом и ужас: комната цела, а разжимать пришлось.
#
# Глагол круга — РАЗЖАТЬ. В отличие от Круга V, где номер уже утих и
# оставалось признать случившееся, здесь ничего не случилось — осталось
# только напряжение, которое всё ещё нужно снять. Тот же двухшаговый приём
# «сначала осмотри — потом тронь», что в Круге V, но с другим отказом на
# спешку: тронуть не посмотрев здесь не «промах мимо мысли», а буквально
# «не разобравшись — не разжимай», и номер честно объясняет разницу.

enum Act { TENSE, COMPLETE }

# Следы удержанного насилия: id -> [позиция, поворот, заголовок, текст до
# осмотра, текст после осмотра, отклик на «разжать», точка обзора].
const MARKS := {
	"wall_scuff": [Vector3(1.30, 1.10, -2.50), 0.0, "Царапина на обоях",
		"На уровне плеча, глубокая, но обои не прорваны — задели костяшками и одёрнули руку.",
		"След уходит по дуге вбок в последний момент — удар свернул сам себя, не долетев.",
		"Ты провёл ладонью по царапине. Она никуда не денется, но рука разжалась и осталась разжатой.",
		Vector3(1.30, 1.30, -2.05)],
	"door_scuff": [Vector3(-1.20, .45, -1.30), .20, "Царапина у дверного косяка",
		"Носком задели косяк — обувь оставила след, а не выбитая щепка.",
		"След от удара остановился на самом дереве. Ещё сантиметр — и косяк бы треснул, но не треснул.",
		"Ты стёр пыль со следа. Косяк цел, и это цело по-настоящему.",
		Vector3(-1.20, 1.00, -1.75)],
	"glass_gripped": [Vector3(2.50, .90, .60), .10, "Стакан со сжатым следом",
		"Стекло держит трещину-паутинку у самого дна — от хватки, не от удара о стол.",
		"Трещина остановилась ровно там, где кончилось терпение. Стакан устоял на столе.",
		"Ты разжал пальцы вокруг стакана — хотя стакан давно уже никто не держит. Он остаётся цел.",
		Vector3(2.10, 1.25, .60)],
	"curtain_bent": [Vector3(4.08, 2.45, -.75), 0.0, "Погнутый карниз",
		"Штора дёрнута с такой силой, что карниз выгнулся дугой — но с креплений не сорвалась.",
		"Ткань цела, только дуга в металле. Дёрнули один раз и остановились сами.",
		"Ты выправил карниз руками. Он поддался — не всё, что согнуто, гнётся навсегда.",
		Vector3(3.45, 2.10, -.75)],
	"phone_cord": [Vector3(2.30, .65, -2.90), .30, "Перекрученный телефонный шнур",
		"Шнур скручен в тугие петли — трубку сжимали в руке долго, прежде чем положить на место.",
		"На пластике трубки нет трещин. Шнур перекручен, но не порван — руку разжали, не рванули.",
		"Ты раскрутил шнур обратно. Он лёг свободно, будто и не было того звонка.",
		Vector3(1.90, 1.05, -2.90)]
}

var act := Act.TENSE
var released := {}
var mark_nodes := {}

func _ready() -> void:
	name = "ViolenceLevel"
	audit_tag = "VIOL"
	player = get_parent().get_node("Player")
	camera = player.get_node("Head/Camera3D")
	world_environment = get_parent().get_node_or_null("Environment")
	cache_room()
	build_systems()
	build_props()
	register_targets()
	wire_signals()
	full_reset()
	if OS.has_environment("VIOL_AUDIT"):
		await get_tree().process_frame
		run_audit()
	elif OS.has_environment("VIOL_WALKTHROUGH"):
		begin_walkthrough(OS.get_environment("VIOL_WALKTHROUGH"))
		await get_tree().process_frame
		run_audit()
	else:
		hud.show_message("КРУГ VII\nНАСИЛИЕ", 3.2)
		show_controls()

func show_controls() -> void:
	var mark := epoch
	await get_tree().create_timer(4.2).timeout
	if mark != epoch:
		return
	hud.show_message("WASD — идти   ·   ЛКМ — рассмотреть   ·   E — тронуть   ·   H — подсказка", 5.4)

func build_props() -> void:
	clock_display = Build.label3d(self, "ClockDisplay", "16:10:00", Vector3(2.28, 1.74, .915), Vector3.ZERO, 30, .0032)
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
	clock.start_label = "16:10"
	clock.end_label = "16:11"
	clock.refresh()

	var root := get_parent()
	# Ни одного нового ассета — тот же приём, что в Кругах III–VI.
	mark_nodes["wall_scuff"] = root.placed_model(self, "WallScuff",
		load("res://assets/models/wall_outlet.glb"), Vector3(1.30, 1.10, -2.94), Vector3.ZERO,
		{"metal": "brass", "plastic": "cream"})
	mark_nodes["door_scuff"] = root.placed_model(self, "DoorScuff",
		load("res://assets/models/corridor_door_hanger.glb"), Vector3(-1.20, .45, -1.30), Vector3(0, PI / 2, 0),
		{"brass": "brass", "tag": "flower_dark"})
	mark_nodes["glass_gripped"] = root.placed_model(self, "GlassGripped",
		load("res://assets/models/c2_toothbrush_glass.glb"), Vector3(2.50, .86, .60), Vector3.ZERO,
		{"glass": "glass", "handle": "cream"})
	mark_nodes["curtain_bent"] = root.placed_model(self, "CurtainBent",
		load("res://assets/models/curtain_rod.glb"), Vector3(4.08, 2.45, -1.11), Vector3(0, PI / 2, .10),
		{"metal": "brass"})
	mark_nodes["phone_cord"] = root.placed_model(self, "PhoneCord",
		load("res://assets/models/vintage_phone.glb"), Vector3(2.30, .56, -2.90), Vector3(0, -.3, 0),
		{"plastic": "cream", "metal": "brass"})

func register_targets() -> void:
	for id in MARKS:
		var row: Array = MARKS[id]
		interactor.register(str(id), row[0] + Vector3(0, .08, 0), Vector3(.24, .20, .24), {
			"title": str(row[2]), "text": str(row[3]), "usable": true})
	register_room_flavor(ROOM_ZONE_TEXT)
	register_switch_zones()

const ROOM_ZONE_TEXT := {
	"console": [null, "Столик у двери. На краю след ладони, вдавленный — держались, чтобы не пойти дальше.",
		"Ты положил руку на тот же след. Столик даже не качнулся."],
	"entry_lamp": [null, "Латунная стойка. Основание чуть сдвинуто — толкнули и тут же поймали.",
		"Ты вернул стойку на место. Она встала так, будто её и не трогали."],
	"hall_plant": [null, "Горшок наклонён на пару градусов — толкнули носком и остановили рукой.",
		"Ты выровнял горшок. Земля даже не осыпалась."],
	"hall_painting": [null, "Горное озеро. Рама чуть провёрнута на гвозде — рванули и отпустили сразу.",
		"Ты поправил раму. Гвоздь держит крепко, будто рывка и не было."],
	"entry_rug": [null, "Плотный ворс. Загнут с одного края — потянули носком и остановились.",
		"Ты расправил край. Ворс лёг ровно."],
	"hall_outlet": [null, "Круглое гнездо в латунной рамке.", "Гнездо пустое и холодное."],
	"drawer_left": [null, "Ящик задвинут с явным нажимом — толкнули сильнее, чем нужно, и вовремя остановились.",
		"Ты выровнял ящик. Он закрывается так же туго."],
	"drawer_right": [null, "Ящик закрыт обычно — этой стороны напряжение не коснулось.",
		"Пусто, и ничего не сдвинуто через силу."],
	"radiator_bed": [null, "Секционный радиатор. На краю вмятина от удара ладонью, не кулаком.",
		"Вентиль проворачивается вхолостую, как и раньше."],
	"bed_outlet": [null, "Ещё одно гнездо. Вилка воткнута с явным нажимом — до упора и дальше некуда.",
		"Ты поправил вилку. Гнездо держит её ровно."],
	"tub": [null, "Ванна. Кран довёрнут до предела — рука соскользнула бы дальше, если бы было куда.",
		"Ты чуть отвернул кран. Он поддался легче, чем ожидалось."],
	"toilet": [null, "Белый фаянс. Крышка опущена резко, но цела — удар пришёлся вскользь.",
		"Скол на углу неглубокий. Бачок набирает воду ровно, как обычно."],
	"towels": [null, "Сложены гостиничным углом, но одна стопка сдвинута — смахнули и удержали остальное.",
		"Ты выровнял стопку. Полотенца легли как обычно."],
	"hand_towel": [null, "На латунном кольце, натянуто в сторону — дёрнули и отпустили, не сорвав.",
		"Полотенце качнулось и вернулось ровно как было."],
	"wastebasket": [null, "Плетёная корзина. Вмята с одного бока — пнули и тут же придержали ногой.",
		"Ты выправил бок корзины. Плетение цело."],
	"shower": [null, "Лейка на шланге. Шланг перетянут узлом, туго — и распущен наполовину.",
		"Ты распустил узел до конца. Шланг лёг свободно."],
	"toilet_paper": [null, "Рулон смят с одного бока — схватили резко и отпустили, не оторвав.",
		"Рулон провернулся со щелчком."],
	"sofa": [null, "Бежевая обивка. Одна подушка вдавлена глубже других — на неё опёрлись всем весом.",
		"Ты взбил подушку. Диван снова выглядит нетронутым."],
	"coffee_table": [null, "Лак цел, но по краю след от удара кольцом — стукнули и отдёрнули руку.",
		"Ты провёл пальцем по следу. Он не разглаживается, но и не углубляется."],
	"living_armchair": [null, "Оливковое кресло. Подлокотник продавлен резким нажимом, а не весом тела.",
		"Кресло качнулось и осталось стоять как было."],
	"minibar": [null, "Шкафчик со стеклянной дверцей. Стекло цело, но дверца перекошена — дёрнули и удержали.",
		"Ты поправил дверцу. Она закрылась мягче, чем ожидалось."],
	"living_mirror": [null, "Небольшое зеркало. На раме вмятина от костяшек — по раме, не по стеклу.",
		"Ты провёл по раме. Стекло цело — целились рядом, не в него."],
	"living_painting": [null, "Ночной отель, горит одно окно. Угол рамы примят пальцами, сильно.",
		"Рама на месте. Вмятина осталась, но холст не порван."],
	"desk_lamp": [null, "Рабочая лампа. Абажур смят с одного бока — схватили и не швырнули.",
		"Щелчок. Лампа не загорелась."],
	"desk_chair": [null, "Отодвинут резким толчком — ножки поцарапали пол, но стул устоял.",
		"Стул откатился и остановился."],
	"radiator_living": [null, "Такой же напряжённый, как в спальне.",
		"Тот же холод и тот же свободный вентиль."],
	"door": [null, "Латунная ручка. Погнута едва заметно — рванули на себя и отпустили.",
		"Замок проворачивается вхолостую."],
	"plate": [null, "Табличка 1604. Один угол чуть отогнут — задели и не довели дело до конца.",
		"Ты прижал угол обратно. Табличка держится крепко."],
	"clock": [null, "Тёмный корпус, латунные кольца. На стекле след пальца, вдавленный сильнее обычного.",
		"Корпус тёплый. Стрелку не сдвинуть ни в одну сторону."],
	"chair": [null, "Кресло у окна. Плед стянут в тугой узел и наполовину распущен.",
		"Ты распустил узел до конца. Плед лёг свободно."]
}

func reach_origins() -> Dictionary:
	var origins := {}
	for id in MARKS:
		origins[str(id)] = (MARKS[id] as Array)[6]
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
	var already_seen := interactor.was_seen(id)
	if MARKS.has(id) and not already_seen and not released.has(id):
		interactor.set_text(id, str((MARKS[id] as Array)[4]))
	inspect.open(id, interactor.entry(id))
	interactor.mark_seen(id)

func on_used(id: String) -> void:
	if inspect.active or code_lock.active:
		return
	if MARKS.has(id):
		release_mark(id)
		return
	if id.begins_with("switch_"):
		toggle_switch(id)
		return
	if ROOM_ZONES.has(id):
		use_room_zone(id)
		return

func release_mark(id: String) -> void:
	if released.has(id):
		return
	if not interactor.was_seen(id):
		# Не разобравшись — не разжимай. Отказ ничего не отнимает и не двигает
		# часы назад: проект запрещает наказывать игрока.
		hud.show_message("Сначала пойми, что здесь удержали, — ЛКМ.", 2.8)
		return
	released[id] = true
	interactor.set_text(id, str((MARKS[id] as Array)[5]))
	cue.play("latch")
	clock.advance(7.0, "release")
	var left := MARKS.size() - released.size()
	if left > 0:
		hud.show_message("Разжато. Осталось: %d." % left, 3.0)
		focus_next_mark()
		return
	act = Act.COMPLETE
	clock_display.text = "16:11:00"
	hints.set_enabled(false)
	clock.ceiling = ClockDirector.SPAN
	hud.show_message("В номере не осталось ни одного сжатого кулака.", 4.2)
	clock.run_out(6.0)

func on_minute_reached() -> void:
	clock_display.text = "16:11:00"

func focus_next_mark() -> void:
	for id in MARKS:
		if not released.has(str(id)):
			hints.set_focus((MARKS[id] as Array)[0], [
				"В номере ещё есть удержанный удар.",
				"Осталось разжать: %d. Сперва пойми, что случилось, — ЛКМ." % (MARKS.size() - released.size()),
				"Наведись и нажми ЛКМ, потом E: %s." % str((MARKS[id] as Array)[2])])
			hints.reset_timer()
			return
	hints.clear_focus()

func current_goal() -> String:
	match act:
		Act.TENSE:
			return "Найди следы удержанного удара и разбери, что случилось, — осталось %d из %d. Понятое можно разжать клавишей E." \
				% [MARKS.size() - released.size(), MARKS.size()]
		Act.COMPLETE:
			return "Круг VII пройден."
	return "Оглядись."

func full_reset() -> void:
	epoch += 1
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	act = Act.TENSE
	released.clear()
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
	clock.start_label = "16:10"
	clock.end_label = "16:11"
	clock.refresh()
	clock.start()
	clock.ceiling = 50.0
	hints.set_enabled(true)
	focus_next_mark()

func run_audit() -> void:
	await get_tree().physics_frame
	var expected := MARKS.size() + ROOM_ZONES.size() + 4
	if not require(interactor.targets.size() == expected,
			"unexpected zone count: %d, expected %d" % [interactor.targets.size(), expected]): return
	for id in ROOM_ZONES:
		if not require(interactor.entry(str(id))["usable"], "room zone is not usable: %s" % id): return
	if not check_no_overlap(): return
	if not check_props_placed([]): return
	if not check_reachable(reach_origins()): return
	if not check_actions_bound(MARKS.keys()): return
	if not require(message_on_screen(), "message sits off screen"): return
	if not require(act == Act.TENSE, "circle VII did not start in the tense act"): return
	if not require(current_goal().contains("удержанного"), "H says nothing useful in act I"): return
	await shot("c7_loaded", Vector3(1.25, .05, .15), .4, -.20)

	var ids := MARKS.keys()
	on_used(str(ids[0]))
	if not require(not released.has(str(ids[0])), "mark released without being examined: %s" % ids[0]): return
	if not require(interactor.entry(str(ids[0]))["text"] == str((MARKS[ids[0]] as Array)[3]),
			"text changed before the mark was ever examined"): return
	await shot("c7_untouched", (MARKS[ids[0]] as Array)[6])

	for id in ids:
		on_examined(str(id))
		if not require(interactor.was_seen(str(id)), "examine did not mark %s as seen" % id): return
		inspect.close()
		on_used(str(id))
		if not require(released.has(str(id)), "mark did not release after being examined: %s" % id): return
	if not require(released.size() == MARKS.size(),
			"not every mark was released: %d" % released.size()): return
	if not require(act == Act.COMPLETE, "releasing every mark did not end act I"): return
	await shot("c7_released", Vector3(1.25, .05, .15), .4, -.20)

	var wait_guard := 0
	while clock_display.text != "16:11:00" and wait_guard < 200:
		await get_tree().create_timer(.1).timeout
		wait_guard += 1
	if not require(clock_display.text == "16:11:00", "clock shows %s" % clock_display.text): return
	await shot("c7_complete")

	full_reset()
	if not require(act == Act.TENSE and released.is_empty(), "full_reset did not clean up"): return

	print("VIOL_AUDIT_OK circle VII: %d zones, %d marks, clock 16:10->16:11"
		% [interactor.targets.size(), MARKS.size()])
	prepare_shutdown()
	await get_tree().create_timer(.35).timeout
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if (event as InputEventKey).keycode == KEY_H:
		get_viewport().set_input_as_handled()
		request_hint()
