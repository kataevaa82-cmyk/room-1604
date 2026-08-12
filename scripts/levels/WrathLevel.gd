extends CircleLevel

# КРУГ V — «ГНЕВ». Комната 1604, 16:08 → 16:09.
#
# У Данте пятый круг — гневные, бьющие друг друга на поверхности Стикса, и
# угрюмые, захлёбывающиеся под ней молча. Здесь это одна комната после ссоры,
# о которой никто не говорит: пять предметов помнят вспышку, но номер молчит
# о ней, пока в него не всмотришься. Ни крика, ни разгрома напоказ — только
# то, что осталось, если приглядеться.
#
# Глагол круга — ВСМОТРЕТЬСЯ, ПОТОМ УСПОКОИТЬ. Два разных предыдущих круга
# сводились к «неси и отдай»; здесь в этом нет смысла — нести нечего. Каждую
# вспышку сначала рассматривают (ЛКМ), и только после этого E её унимает.
# Тронуть не посмотрев — значит промахнуться мимо мысли круга, и номер прямо
# об этом говорит, не наказывая: попытка ничего не отнимает и не двигает
# часы назад.

enum Act { STILL, COMPLETE }

# Вспышки гнева: id -> [позиция, поворот, заголовок, текст до осмотра, текст
# после осмотра, отклик на «унять», точка обзора].
const FLASHPOINTS := {
	"wrath_lamp": [Vector3(1.60, .70, -1.60), 1.35, "Опрокинутая лампа",
		"Настольная лампа лежит на боку. Абажур не разбит — её положили, не бросили.",
		"Шнур натянут в сторону кровати ровно настолько, чтобы дальше не тянулся. Лампу не швыряли — её отставили с дороги.",
		"Ты поднял лампу и поставил ровно. Она стоит, будто ничего не было.",
		Vector3(1.20, 1.20, -1.60)],
	"wrath_mirror": [Vector3(-3.55, 1.35, -.10), .40, "Ручное зеркало",
		"Лежит стеклом вниз на полке. Трещина через весь угол — старая, судя по пыли внутри неё.",
		"Трещина ровная, одним ударом. Никто не пытался её скрыть — просто положили лицом к стене.",
		"Ты перевернул зеркало стеклом вверх. Трещина никуда не делась, но теперь её видно сразу, а не украдкой.",
		Vector3(-3.15, 1.35, -.10)],
	"wrath_pillow": [Vector3(2.70, .68, -2.00), -.20, "Подушка с прорехой",
		"Один угол вспорот, перо не вылезло — прореха неглубокая, будто остановились на середине удара.",
		"Шов разошёлся по нитке, а не разрезан. Кто-то дёргал, а не резал.",
		"Ты подвернул прореху внутрь наволочки. Снаружи не видно.",
		Vector3(2.30, 1.15, -2.00)],
	"wrath_chair": [Vector3(2.35, .05, .95), 2.60, "Опрокинутый стул",
		"Лежит на боку у стола, ножками к двери — будто вставали резко и не подняли за собой.",
		"На сиденье вмятина глубже обычного. Кто-то сидел на нём долго перед тем, как встал.",
		"Ты поднял стул и задвинул под стол. Тишина в номере не изменилась, но стало ровнее.",
		Vector3(1.90, .90, .95)],
	"wrath_glass": [Vector3(1.60, .04, 3.50), .55, "Осколки в кучке",
		"Стакан разбит, но осколки сметены аккуратной горкой у плинтуса — не оставлены, а убраны.",
		"Кто-то подмёл после вспышки чем-то нашедшимся под рукой. Убирали не сразу, но убрали.",
		"Ты собрал осколки в ладонь и высыпал в мусорную корзину. Пол чист.",
		Vector3(1.20, 1.10, 3.50)]
}

var act := Act.STILL
var calmed := {}
var flash_nodes := {}

func _ready() -> void:
	name = "WrathLevel"
	audit_tag = "WRATH"
	player = get_parent().get_node("Player")
	camera = player.get_node("Head/Camera3D")
	world_environment = get_parent().get_node_or_null("Environment")
	cache_room()
	build_systems()
	build_props()
	register_targets()
	wire_signals()
	full_reset()
	if OS.has_environment("WRATH_AUDIT"):
		await get_tree().process_frame
		run_audit()
	elif OS.has_environment("WRATH_WALKTHROUGH"):
		begin_walkthrough(OS.get_environment("WRATH_WALKTHROUGH"))
		await get_tree().process_frame
		run_audit()
	else:
		hud.show_message("КРУГ V\nГНЕВ", 3.2)
		show_controls()

func show_controls() -> void:
	var mark := epoch
	await get_tree().create_timer(4.2).timeout
	if mark != epoch:
		return
	hud.show_message("WASD — идти   ·   ЛКМ — рассмотреть   ·   E — тронуть   ·   H — подсказка", 5.4)

func build_props() -> void:
	clock_display = Build.label3d(self, "ClockDisplay", "16:08:00", Vector3(2.28, 1.74, .915), Vector3.ZERO, 30, .0032)
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
	clock.start_label = "16:08"
	clock.end_label = "16:09"
	clock.refresh()

	var root := get_parent()
	# Все пять вспышек переиспользуют готовые модели: круг не добавляет ни
	# одного нового ассета, тот же приём, что и в Кругах III и IV.
	flash_nodes["wrath_lamp"] = root.placed_model(self, "WrathLamp",
		load("res://assets/models/table_lamp.glb"), Vector3(1.60, .10, -1.60), Vector3(0, .3, 1.4),
		{"metal": "brass", "shade": "shade"})
	flash_nodes["wrath_mirror"] = root.placed_model(self, "WrathMirror",
		load("res://assets/models/mirror.glb"), Vector3(-3.55, 1.10, -.10), Vector3(1.5, .4, 0),
		{"wood": "wood2", "glass": "mirror"})
	flash_nodes["wrath_pillow"] = root.placed_model(self, "WrathPillow",
		load("res://assets/models/bath_hand_towel.glb"), Vector3(2.70, .64, -2.00), Vector3(0, -.2, .3),
		{"fabric": "cream", "metal": "brass"})
	flash_nodes["wrath_chair"] = root.placed_model(self, "WrathChair",
		load("res://assets/models/desk_chair.glb"), Vector3(2.35, .05, .95), Vector3(1.4, 2.6, 0),
		{"wood": "wood2", "fabric": "olive"})
	flash_nodes["wrath_glass"] = root.placed_model(self, "WrathGlass",
		load("res://assets/models/c2_toothbrush_glass.glb"), Vector3(1.60, .02, 3.50), Vector3(0, .55, 0),
		{"glass": "glass", "handle": "cream"})

func register_targets() -> void:
	for id in FLASHPOINTS:
		var row: Array = FLASHPOINTS[id]
		interactor.register(str(id), row[0] + Vector3(0, .10, 0), Vector3(.30, .24, .30), {
			"title": str(row[2]), "text": str(row[3]), "usable": true})
	register_room_flavor(ROOM_ZONE_TEXT)
	register_switch_zones()

const ROOM_ZONE_TEXT := {
	"console": [null, "Столик у двери. Ключ на нём положен ровно — слишком ровно для того, кто хлопал дверью.",
		"Ты сдвинул ключ. Он лежал ровно нарочно, чтобы не пришлось про него говорить."],
	"entry_lamp": [null, "Латунная стойка. Абажур стоит криво — задели, когда проходили быстрым шагом.",
		"Ты поправил абажур. Свет лёг ровнее."],
	"hall_plant": [null, "Земля примята с одной стороны — горшок толкнули и не подняли.",
		"Ты выпрямил горшок. Земля осталась примятой."],
	"hall_painting": [null, "Горное озеро. Рама висит чуть криво — по ней явно провели рукой.",
		"Ты поправил раму. Она встала ровно и осталась так."],
	"entry_rug": [null, "Ворс примят глубже обычного в одном месте — там стояли и не двигались долго.",
		"Ты разгладил ворс ногой. Он всё равно примят — под ним не разгладить."],
	"hall_outlet": [null, "Круглое гнездо в латунной рамке.", "Гнездо пустое и холодное."],
	"drawer_left": [null, "Ящик задвинут с силой — перекошен на полозьях.",
		"Ты выровнял ящик. Он всё равно закрывается туже, чем должен."],
	"drawer_right": [null, "Ящик закрыт ровно — эта сторона ссоры не касалась.",
		"Пусто, и ничего не сдвинуто."],
	"radiator_bed": [null, "Секционный радиатор. На нём вмятина — ударили ладонью, не кулаком.",
		"Вентиль проворачивается вхолостую, как и раньше."],
	"bed_outlet": [null, "Ещё одно гнездо. Провод рядом выдернут и воткнут заново, косо.",
		"Ты поправил вилку. Гнездо держит её нетвёрдо."],
	"tub": [null, "Ванна. Кран откручен сильнее, чем нужно, — выкручивали в сердцах.",
		"Ты примерно завернул кран. Он всё равно скрипит на последнем обороте."],
	"toilet": [null, "Белый фаянс. Крышка опущена резко — скол свежий на углу.",
		"Скол не сгладить. Бачок набирает воду ровно, как обычно."],
	"towels": [null, "Сложены не гостиничным углом — переложены второпях, чтобы выглядело как обычно.",
		"Ты переложил стопку заново. Теперь она и правда как обычно."],
	"hand_towel": [null, "На латунном кольце, скомкано в кулак и расправлено обратно.",
		"Полотенце качнулось и вернулось ровно как было."],
	"wastebasket": [null, "Плетёная корзина. В ней смятый листок без единого слова — только нажим ручки.",
		"Ты расправил листок. Ни слова — только борозды от нажима."],
	"shower": [null, "Лейка на шланге. Вентиль горячей воды докручен до упора и не сдвигается.",
		"Вентиль проворачивается свободно. Капля всё равно падает."],
	"toilet_paper": [null, "Рулон смят с одного бока — схватили резко и отпустили.",
		"Рулон провернулся со щелчком."],
	"sofa": [null, "Бежевая обивка. Одна подушка лежит не на своём месте, углом наружу.",
		"Ты поправил подушку. Диван снова выглядит нетронутым."],
	"coffee_table": [null, "Лак задет по прямой линии — что-то тяжёлое протащили по столу.",
		"Ты провёл пальцем по царапине. Она не разглаживается."],
	"living_armchair": [null, "Оливковое кресло развёрнуто спинкой к комнате — так садятся, когда не хотят никого видеть.",
		"Ты развернул кресло обратно. Оно послушно осталось стоять так."],
	"minibar": [null, "Шкафчик со стеклянной дверцей. Дверца прикрыта не до щелчка.",
		"Ты закрыл дверцу до щелчка. Внутри пусто и тихо."],
	"living_mirror": [null, "Небольшое зеркало. На стекле у самого края отпечаток ладони.",
		"Ты стёр отпечаток рукавом. Стекло чистое, но холодное."],
	"living_painting": [null, "Ночной отель, горит одно окно. Нижний угол рамы стёрт — держались за него.",
		"Рама на месте. Стёртый угол так и остался светлее остальных."],
	"desk_lamp": [null, "Рабочая лампа. Абажур развёрнут в сторону от стола, будто от него отворачивались.",
		"Щелчок. Лампа не загорелась."],
	"desk_chair": [null, "Другой стул у стола — на нём всё спокойно, ссора была не здесь.",
		"Стул откатился и остановился."],
	"radiator_living": [null, "Такой же холодный, как в спальне.",
		"Тот же холод и тот же свободный вентиль."],
	"door": [null, "Латунная ручка холодная и слегка разболтана — хлопали не один раз.",
		"Замок проворачивается вхолостую."],
	"plate": [null, "Табличка 1604. Нижний край задет — что-то прошло рядом на уровне косяка.",
		"Ты провёл по цифрам. Держатся крепко."],
	"clock": [null, "Тёмный корпус, латунные кольца. Стекло циферблата с мелкой трещиной у края.",
		"Корпус тёплый. Стрелку не сдвинуть ни в одну сторону."],
	"chair": [null, "Кресло у окна. Плед на подлокотнике сброшен наполовину на пол.",
		"Ты поправил плед. Кресло снова выглядит нетронутым."]
}

func reach_origins() -> Dictionary:
	var origins := {}
	for id in FLASHPOINTS:
		origins[str(id)] = (FLASHPOINTS[id] as Array)[6]
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
	if FLASHPOINTS.has(id) and not already_seen and not calmed.has(id):
		# Второй, более подробный текст открывается только реальным осмотром —
		# то же правило, что у оборота предмета в Круге I.
		interactor.set_text(id, str((FLASHPOINTS[id] as Array)[4]))
	inspect.open(id, interactor.entry(id))
	interactor.mark_seen(id)

func on_used(id: String) -> void:
	if inspect.active or code_lock.active:
		return
	if FLASHPOINTS.has(id):
		calm(id)
		return
	if id.begins_with("switch_"):
		toggle_switch(id)
		return
	if ROOM_ZONES.has(id):
		use_room_zone(id)
		return

func calm(id: String) -> void:
	if calmed.has(id):
		return
	if not interactor.was_seen(id):
		# Тронуть не посмотрев — мимо мысли круга. Отказ ничего не отнимает и
		# не двигает часы назад: проект запрещает наказывать игрока.
		hud.show_message("Сначала рассмотри, что здесь случилось — ЛКМ.", 2.8)
		return
	calmed[id] = true
	interactor.set_text(id, str((FLASHPOINTS[id] as Array)[5]))
	cue.play("latch")
	clock.advance(7.0, "calm")
	var left := FLASHPOINTS.size() - calmed.size()
	if left > 0:
		hud.show_message("Тише. Осталось: %d." % left, 3.0)
		focus_next_flashpoint()
		return
	act = Act.COMPLETE
	clock_display.text = "16:09:00"
	hints.set_enabled(false)
	clock.ceiling = ClockDirector.SPAN
	hud.show_message("В номере пять раз стало тише. Больше вспышек не осталось.", 4.2)
	clock.run_out(6.0)

func on_minute_reached() -> void:
	clock_display.text = "16:09:00"

func focus_next_flashpoint() -> void:
	for id in FLASHPOINTS:
		if not calmed.has(str(id)):
			hints.set_focus((FLASHPOINTS[id] as Array)[0], [
				"В номере ещё есть след вспышки.",
				"Осталось унять: %d. Сперва рассмотри находку — ЛКМ." % (FLASHPOINTS.size() - calmed.size()),
				"Наведись и нажми ЛКМ, потом E, чтобы унять: %s." % str((FLASHPOINTS[id] as Array)[2])])
			hints.reset_timer()
			return
	hints.clear_focus()

func current_goal() -> String:
	match act:
		Act.STILL:
			return "Найди следы вспышки и всмотрись в них — осталось %d из %d. Осмотренное можно унять клавишей E." \
				% [FLASHPOINTS.size() - calmed.size(), FLASHPOINTS.size()]
		Act.COMPLETE:
			return "Круг V пройден."
	return "Оглядись."

func full_reset() -> void:
	epoch += 1
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	act = Act.STILL
	calmed.clear()
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
	clock.start_label = "16:08"
	clock.end_label = "16:09"
	clock.refresh()
	clock.start()
	clock.ceiling = 50.0
	hints.set_enabled(true)
	focus_next_flashpoint()

func run_audit() -> void:
	await get_tree().physics_frame
	var expected := FLASHPOINTS.size() + ROOM_ZONES.size() + 4
	if not require(interactor.targets.size() == expected,
			"unexpected zone count: %d, expected %d" % [interactor.targets.size(), expected]): return
	for id in ROOM_ZONES:
		if not require(interactor.entry(str(id))["usable"], "room zone is not usable: %s" % id): return
	if not check_no_overlap(): return
	if not check_reachable(reach_origins()): return
	if not check_actions_bound(FLASHPOINTS.keys()): return
	if not require(message_on_screen(), "message sits off screen"): return
	if not require(act == Act.STILL, "circle V did not start in the still act"): return
	if not require(current_goal().contains("вспышки"), "H says nothing useful in act I"): return
	await shot("c5_loaded", Vector3(1.25, .05, .15), .4, -.20)

	# Тронуть не посмотрев — обязано отказывать и ничего не отнимать.
	var ids := FLASHPOINTS.keys()
	on_used(str(ids[0]))
	if not require(not calmed.has(str(ids[0])), "flashpoint calmed without being examined: %s" % ids[0]): return
	if not require(interactor.entry(str(ids[0]))["text"] == str((FLASHPOINTS[ids[0]] as Array)[3]),
			"text changed before the flashpoint was ever examined"): return
	await shot("c5_untouched", (FLASHPOINTS[ids[0]] as Array)[6])

	# Теперь смотрим и унимаем по очереди, как и пойдёт живой игрок.
	for id in ids:
		on_examined(str(id))
		if not require(interactor.was_seen(str(id)), "examine did not mark %s as seen" % id): return
		inspect.close()
		on_used(str(id))
		if not require(calmed.has(str(id)), "flashpoint did not calm after being examined: %s" % id): return
	if not require(calmed.size() == FLASHPOINTS.size(),
			"not every flashpoint was calmed: %d" % calmed.size()): return
	if not require(act == Act.COMPLETE, "calming every flashpoint did not end act I"): return
	await shot("c5_calm", Vector3(1.25, .05, .15), .4, -.20)

	var wait_guard := 0
	while clock_display.text != "16:09:00" and wait_guard < 200:
		await get_tree().create_timer(.1).timeout
		wait_guard += 1
	if not require(clock_display.text == "16:09:00", "clock shows %s" % clock_display.text): return
	await shot("c5_complete")

	full_reset()
	if not require(act == Act.STILL and calmed.is_empty(), "full_reset did not clean up"): return

	print("WRATH_AUDIT_OK circle V: %d zones, %d flashpoints, clock 16:08->16:09"
		% [interactor.targets.size(), FLASHPOINTS.size()])
	prepare_shutdown()
	await get_tree().create_timer(.35).timeout
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if (event as InputEventKey).keycode == KEY_H:
		get_viewport().set_input_as_handled()
		request_hint()
