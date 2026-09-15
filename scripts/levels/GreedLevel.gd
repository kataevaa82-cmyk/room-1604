extends CircleLevel

# КРУГ IV — «СКУПОСТЬ И МОТОВСТВО». Комната 1604, 16:07 → 16:08.
#
# Замысел целиком — в КРУГ_IV.md. Коротко: у Данте четвёртый круг сталкивает
# скупых и расточительных — они вечно катят друг на друга тяжести и обзывают
# один другого. Здесь номер набит и долгами, и запрятанными деньгами
# одновременно: кто-то прятал, кто-то не расплатился, и это один и тот же
# человек. Ни намёка на самого Данте: только суммы, спрятанные не на виду,
# и счета, оставленные там, где их не сразу заметишь.
#
# Глагол круга — РАСПЛАТИТЬСЯ, а не «вынести» (Круг III) и не «расстаться»
# (Круг II). Пять заначек, пять долгов, и деньги подходят к долгу только по
# сумме: не тот конверт в неверном месте не примут, счётчик не сдвинется, и
# придётся вернуться и вспомнить, где какая сумма спрятана. Пять заначек на
# четыре слота — та же теснота, что и в Круге III, но здесь она не про то,
# сколько удержать в руках, а про то, что схрон и долг должны совпасть.

enum Act { SETTLE, COMPLETE }

# Заначки денег: id -> [позиция, поворот, заголовок, текст осмотра, id долга,
# который эта сумма закрывает, точка обзора]. Пять заначек на четыре слота —
# без этого неравенства круг теряет мысль, ровно как Круг III без шести
# подносов на четыре слота.
#
# Каждая точка стоит на измеренной поверхности комнаты, а не в воздухе: высоты
# взяты из габаритов самой мебели (кровать .64, бачок .805, тумба под
# телевизором .76, ковёр .05, пол 0). Прежние координаты висели: три заначки и
# четыре счёта держались на высоте от 0.6 до 1.4 м без единой опоры под ними.
# Идентификаторы оставлены прежними — их игрок не видит, а переименование
# порвало бы связки долгов и точки обзора без всякой пользы.
const MONEY := {
	"cash_mattress": [Vector3(1.70, .64, -1.75), 0.0, "Под матрасом",
		"Плотный конверт, засунутый между матрасом и решёткой. Пятнадцать тысяч, не тронуты.",
		"debt_room_bill", Vector3(1.30, 1.20, -1.75)],
	"cash_robe": [Vector3(-1.60, .76, 3.20), .30, "За телевизором",
		"Три тысячи мелкими купюрами, свёрнутые в трубочку. Лежат на тумбе, задвинутые за корпус телевизора.",
		"debt_bar_tab", Vector3(-1.05, 1.20, 3.20)],
	"cash_jacket": [Vector3(-4.14, .805, .96), .20, "За бачком",
		"Восемьсот рублей мелкими купюрами, свёрнутые вдвое. Бачок и правда откручивали — вот зачем.",
		"debt_maid_tip", Vector3(-3.55, 1.20, .96)],
	"cash_rug": [Vector3(1.80, .05, 3.60), 0.0, "На ковре у кресла",
		"Сто двадцать тысяч одной пачкой. Угол ковра отогнут и не долежал ровно — пачку прятали под него и вынули не до конца.",
		"debt_neighbor_debt", Vector3(1.80, 1.15, 3.20)],
	"cash_floor": [Vector3(.20, 0.0, 1.20), 0.0, "В щели у плинтуса",
		"Сорок тысяч, перетянутые аптечной резинкой. Резинка ссохлась и вот-вот лопнет.",
		"debt_porter_loan", Vector3(.60, 1.10, 1.20)]
}
const SLOTS := 4

# Долги: id -> [позиция, поворот, заголовок, текст, точка обзора]. Каждый
# закрывается только той суммой, что названа в MONEY[cash_id][4] — иначе круг
# превращается в Круг III с другими словами.
const DEBTS := {
	"debt_room_bill": [Vector3(4.05, .76, 1.95), 0.0, "Счёт за номер",
		"Пятнадцать тысяч, просрочено на неделю. Лежит на письменном столе, печать отеля смазана — его переставляли много раз.",
		Vector3(3.45, 1.15, 1.95)],
	"debt_bar_tab": [Vector3(2.20, .90, 4.60), 0.0, "Счёт из бара",
		"Три тысячи, почерком от руки. Листок бросили на кресло у минибара. Внизу подпись — не твоя, но похожа.",
		Vector3(2.20, 1.30, 4.05)],
	# Подноса для полотенец в номере нет ни одного — записка перенесена на борт
	# ванны, единственную горизонтальную поверхность ванной рядом с полотенцами.
	"debt_maid_tip": [Vector3(-2.60, .70, 2.60), 0.0, "Чаевые горничной",
		"Записка на борту ванны: «Недодано восемьсот». Почерк ровный, без злости.",
		Vector3(-2.40, 1.25, 2.10)],
	"debt_neighbor_debt": [Vector3(3.70, .90, 3.60), 0.0, "Долг соседям по этажу",
		"Сто двадцать тысяч, дата двухмесячной давности. Лежит на диване, число обведено дважды.",
		Vector3(3.30, 1.30, 3.60)],
	"debt_porter_loan": [Vector3(2.66, .55, -2.80), 0.0, "Занял у портье",
		"Сорок тысяч без расписки — на слово. Записка оставлена на тумбочке у кровати. Слово, судя по всему, не сдержали.",
		Vector3(2.66, 1.15, -2.15)]
}

var act := Act.SETTLE
var carried := {}
var settled := {}
var money_nodes := {}
var debt_nodes := {}

func _ready() -> void:
	name = "GreedLevel"
	audit_tag = "GREED"
	player = get_parent().get_node("Player")
	camera = player.get_node("Head/Camera3D")
	world_environment = get_parent().get_node_or_null("Environment")
	cache_room()
	build_systems()
	build_props()
	register_targets()
	wire_signals()
	full_reset()
	if OS.has_environment("GREED_AUDIT"):
		await get_tree().process_frame
		run_audit()
	elif OS.has_environment("GREED_WALKTHROUGH"):
		begin_walkthrough(OS.get_environment("GREED_WALKTHROUGH"))
		await get_tree().process_frame
		run_audit()
	else:
		hud.show_message("КРУГ IV\nСКУПОСТЬ И МОТОВСТВО", 3.2)
		show_controls()

func show_controls() -> void:
	var mark := epoch
	await get_tree().create_timer(4.2).timeout
	if mark != epoch:
		return
	hud.show_message("WASD — идти   ·   ЛКМ — рассмотреть   ·   E — тронуть   ·   1 2 3 4 — слот   ·   H — подсказка", 5.4)

func build_props() -> void:
	clock_display = Build.label3d(self, "ClockDisplay", "16:07:00", Vector3(2.28, 1.74, .915), Vector3.ZERO, 30, .0032)
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
	clock.start_label = "16:07"
	clock.end_label = "16:08"
	clock.refresh()

	var root := get_parent()
	# Деньги переиспользуют связку писем Круга II — та же форма, что и пачка
	# купюр, перетянутая лентой. Круг не добавляет ни одного нового ассета.
	var money_scene := load("res://assets/models/c2_letter_bundle.glb") as PackedScene
	for id in MONEY:
		var row: Array = MONEY[id]
		money_nodes[id] = root.placed_model(self, "Cash_" + str(id), money_scene,
			row[0], Vector3(0, row[1], 0), {"paper": "cream", "ribbon": "brass"})
	# Долги — переиспользованный одиночный лист письма: обычный счёт на бумаге.
	var debt_scene := load("res://assets/models/c2_letter_sheet.glb") as PackedScene
	for id in DEBTS:
		var row: Array = DEBTS[id]
		debt_nodes[id] = root.placed_model(self, "Debt_" + str(id), debt_scene,
			row[0], Vector3(0, row[1], 0), {"paper": "cream"})

func register_targets() -> void:
	for id in MONEY:
		var row: Array = MONEY[id]
		interactor.register(str(id), row[0] + Vector3(0, .06, 0), Vector3(.22, .16, .20), {
			"title": str(row[2]), "text": str(row[3]), "usable": true})
	for id in DEBTS:
		var row: Array = DEBTS[id]
		interactor.register(str(id), row[0] + Vector3(0, .04, 0), Vector3(.22, .14, .20), {
			"title": str(row[2]), "text": str(row[3]), "usable": true})
	# Обстановка номера: та же геометрия, что и в остальных кругах. Круг про
	# деньги, поэтому почти каждая вещь тоже смотрит на деньги — свои тексты.
	register_room_flavor(ROOM_ZONE_TEXT)
	register_switch_zones()

const ROOM_ZONE_TEXT := {
	"console": [null, "Столик у двери. На нём круглый след — что-то тяжёлое стояло здесь и его унесли.",
		"Ты провёл ладонью. Под пылью ничего не спрятано."],
	"entry_lamp": [null, "Латунная стойка. Абажур снят и надет заново — криво.",
		"Внутри абажура пусто. Кто-то уже проверял."],
	"hall_plant": [null, "Земля рыхлая сверху — недавно копали и закопали обратно.",
		"Ты разрыл землю пальцами. Ничего, кроме земли."],
	"hall_painting": [null, "Горное озеро. Рама держится на одном гвозде — за неё заглядывали.",
		"За рамой светлый прямоугольник и больше ничего."],
	"entry_rug": [null, "Плотный ворс. Угол отогнут и не долежал ровно.",
		"Под ковриком пусто — здесь уже искали до тебя."],
	"hall_outlet": [null, "Круглое гнездо в латунной рамке.", "Гнездо пустое и холодное."],
	"drawer_left": [null, "Ящик с той стороны кровати. Замок сломан не тобой.",
		"Пусто. Замок сломали, чтобы проверить, а не украсть."],
	"drawer_right": [null, "Ящик задвинут неровно — кто-то торопился его закрыть.",
		"Внутри квитанция без суммы. Сумму стёрли ластиком."],
	"radiator_bed": [null, "Секционный радиатор. За ним щель шире, чем нужно для тепла.",
		"Рука проходит в щель по локоть. Там пусто и холодно."],
	"bed_outlet": [null, "Ещё одно гнездо. Рядом на обоях след от чего-то плоского.",
		"Пусто. Плоское отсюда унесли, а не спрятали."],
	"tub": [null, "Ванна. На дне сухой мелкий мусор — обрывки резинки для купюр.",
		"Ты провёл по дну. Резинки лопаются, деньги — нет."],
	"toilet": [null, "Белый фаянс. Бачок откручен и закручен заново, не до конца.",
		"Бачок сухой изнутри. Кто-то уже проверял и здесь."],
	"towels": [null, "Сложены гостиничным углом, но пересчитаны — стопка не круглым числом.",
		"Ты пересчитал. Одного полотенца не хватает — забрали, не потеряли."],
	"hand_towel": [null, "На латунном кольце. Кольцо погнуто — на нём что-то вешали потяжелее.",
		"Полотенце качнулось и вернулось ровно как было."],
	"wastebasket": [null, "Плетёная корзина. На дне бумажная лента от пачки купюр.",
		"Лента пустая. То, что она держала, уже потрачено."],
	"shower": [null, "Лейка на шланге. Капает — считать капли тоже кто-то пробовал.",
		"Вентиль проворачивается свободно. Капля всё равно падает."],
	"toilet_paper": [null, "Рулон почти новый — экономили даже на этом.",
		"Рулон провернулся со щелчком."],
	"sofa": [null, "Бежевая обивка. Один шов распорот и зашит заново, грубо.",
		"Ты нажал на шов. Внутри обивки, кроме поролона, ничего нет."],
	"coffee_table": [null, "Лак поцарапан по кругу — что-то тяжёлое двигали туда-сюда.",
		"Ты провёл пальцем по царапинам. Считать по ним нечего."],
	"living_armchair": [null, "Оливковое кресло. Подлокотник продавлен неровно, с одной стороны сильнее.",
		"Кресло качнулось. С тяжёлой стороны пружина севшая."],
	"minibar": [null, "Шкафчик со стеклянной дверцей. Внутри аккуратно, будто считали каждую позицию.",
		"Внутри пусто и подписанный счёт — минибаром никто не пользовался."],
	"living_mirror": [null, "Небольшое зеркало. Рама снята и повешена заново, чуть криво.",
		"За рамой ничего. Только пыльный след от чего-то плоского."],
	"living_painting": [null, "Ночной отель, горит одно окно. Холст чуть отходит от подрамника снизу.",
		"Ты пощупал холст снизу. Ровный, без вложений."],
	"desk_lamp": [null, "Рабочая лампа. Абажур снят и надет заново — под ним смотрели.",
		"Щелчок. Лампа не загорелась."],
	"desk_chair": [null, "Отодвинут ровно настолько, чтобы заглянуть под сиденье.",
		"Стул откатился. Под сиденьем только пыль."],
	"radiator_living": [null, "Такой же простуженный, как в спальне.",
		"Тот же холод и тот же свободный вентиль."],
	"door": [null, "Латунная ручка. На косяке карандашные чёрточки — считали дни, не деньги.",
		"Замок проворачивается вхолостую."],
	"plate": [null, "Табличка 1604. Один из винтов заменён на другой, светлее.",
		"Ты провёл по цифрам. Держатся крепко, но не одинаково."],
	"clock": [null, "Тёмный корпус, латунные кольца. Внутри что-то тихо позвякивает при качании.",
		"Корпус тёплый. Стрелку не сдвинуть ни в одну сторону."],
	"chair": [null, "Кресло у окна. На сиденье вмятина глубже, чем от одного человека.",
		"Ты провёл рукой по вмятине. Она не одна — их две, друг на друге."]
}

func reach_origins() -> Dictionary:
	var origins := {}
	for id in MONEY:
		origins[str(id)] = (MONEY[id] as Array)[5]
	for id in DEBTS:
		origins[str(id)] = (DEBTS[id] as Array)[4]
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
			inspect.open(selected, inventory.data(selected))
		return
	if not interactor.targets.has(id):
		return
	inspect.open(id, interactor.entry(id))
	interactor.mark_seen(id)

func on_used(id: String) -> void:
	if inspect.active or code_lock.active:
		return
	if MONEY.has(id):
		take_cash(id)
		return
	if DEBTS.has(id):
		settle_debt(id)
		return
	if id.begins_with("switch_"):
		toggle_switch(id)
		return
	if ROOM_ZONES.has(id):
		use_room_zone(id)
		return

func take_cash(id: String) -> void:
	if carried.has(id) or settled_by(id):
		return
	if inventory.items.size() >= SLOTS:
		hud.show_message("В руках больше не держится. Сперва пристрой то, что взял.", 3.2)
		return
	carried[id] = true
	money_nodes[id].visible = false
	interactor.set_usable(id, false)
	var zone := interactor.zone(id)
	if zone:
		zone.collision_layer = 0
	inventory.add(id, "деньги", money_nodes[id],
		str((MONEY[id] as Array)[2]),
		str((MONEY[id] as Array)[3]))
	var slot := inventory.slot_of(id)
	hud.show_message("%s у тебя в руках.\nСлот %d. Занято %d из %d." \
			% [str((MONEY[id] as Array)[2]), maxi(slot, 1), inventory.items.size(), SLOTS], 4.2)
	focus_open_debt()

func settled_by(cash_id: String) -> bool:
	return settled.has(str((MONEY[cash_id] as Array)[4]))

func settle_debt(debt_id: String) -> void:
	if settled.has(debt_id):
		hud.show_message("Здесь уже расплатились.", 2.6)
		return
	var selected := inventory.selected()
	if selected.is_empty() or not MONEY.has(selected):
		hud.show_message("Нечем платить. Выбери деньги цифрой слота.", 3.0)
		return
	var target: String = (MONEY[selected] as Array)[4]
	if target != debt_id:
		# Сумма не совпадает — это и есть головоломка круга, а не просто «неси
		# и клади». Деньги остаются в руках: круг не наказывает, только отказывает.
		hud.show_message("Сумма не сходится. Здесь ждут другое.", 3.0)
		return
	settled[debt_id] = true
	carried.erase(selected)
	inventory.remove(selected)
	# Оплата обязана быть видна, а не только прочитана. Раньше деньги исчезали из
	# комнаты навсегда, а все пять счетов оставались лежать там же: к концу круга
	# на виду было пять бумаг при нуле денег, и число денег переставало сходиться
	# с числом счетов. Теперь счёт уходит, а на его место ложится та пачка,
	# которой его закрыли, — пять заначек становятся пятью оплаченными местами.
	debt_nodes[debt_id].visible = false
	var cash := money_nodes[selected] as Node3D
	cash.position = (DEBTS[debt_id] as Array)[0] - (MONEY[selected] as Array)[0]
	cash.visible = true
	cue.play("latch")
	clock.advance(7.0, "debt")
	interactor.set_text(debt_id, str((DEBTS[debt_id] as Array)[3]) + "\nОплачено.")
	var left := DEBTS.size() - settled.size()
	if left > 0:
		hud.show_message("Расплатился. Осталось долгов: %d." % left, 3.2)
		focus_open_debt()
		return
	act = Act.COMPLETE
	clock_display.text = "16:08:00"
	hints.set_enabled(false)
	clock.ceiling = ClockDirector.SPAN
	hud.show_message("Все долги закрыты. Впервые за круг в номере ничего не должны.", 4.2)
	clock.run_out(6.0)

func on_minute_reached() -> void:
	clock_display.text = "16:08:00"

func focus_open_debt() -> void:
	for id in DEBTS:
		if not settled.has(str(id)):
			hints.set_focus((DEBTS[id] as Array)[0], [
				"В номере ещё есть кому платить.",
				"Долгов осталось: %d. Деньги подходят к долгу только по сумме." % (DEBTS.size() - settled.size()),
				"Выбери деньги цифрой слота и нажми E на нужном счёте — суммы совпадут, если место верное."])
			hints.reset_timer()
			return
	hints.clear_focus()

func reward(id: String) -> void:
	if rewarded.has(id):
		return
	rewarded[id] = true
	clock.advance(.5)

func current_goal() -> String:
	match act:
		Act.SETTLE:
			if not carried.is_empty():
				return "В руках деньги. Найди долг с той же суммой и нажми E — не тот счёт их не примет."
			return "Расплатись по всем долгам. Осталось: %d из %d. Деньги спрятаны по номеру, суммы решают, куда их нести." \
				% [DEBTS.size() - settled.size(), DEBTS.size()]
		Act.COMPLETE:
			return "Круг IV пройден."
	return "Оглядись."

func full_reset() -> void:
	epoch += 1
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	act = Act.SETTLE
	carried.clear()
	settled.clear()
	rewarded.clear()
	quiet_said.clear()
	for id in money_nodes:
		money_nodes[id].visible = true
		# Сдвиг на место оплаченного счёта живёт до сброса — иначе на втором
		# прогоне круга заначки нашлись бы там, где их уже потратили.
		money_nodes[id].position = Vector3.ZERO
	for id in debt_nodes:
		debt_nodes[id].visible = true
	player.transform = original.player
	player.global_position = Vector3(1.25, .05, .15)
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	lock_entrance_door()
	interactor.clear()
	interactor.set_locked(false)
	for id in MONEY:
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
	clock.start_label = "16:07"
	clock.end_label = "16:08"
	clock.refresh()
	clock.start()
	clock.ceiling = 50.0
	hints.set_enabled(true)
	focus_open_debt()

# Ни одна бумага в круге не имеет права висеть в воздухе. Проверка родилась из
# живой жалобы: четыре счёта из пяти и три заначки стояли на высоте от 0.6 до
# 1.4 м, под ними не было ничего, и комната читалась как склад летающих бумаг.
#
# Опора ищется двумя способами сразу, и достаточно любого. Коллизия мебели не
# совпадает с её видимой формой (у дивана короб кончается на .82, а сиденье — на
# .90), поэтому одного луча мало; габариты видимых мешей, наоборот, врут на
# кровати, где в AABB попадает изголовье на 1.45. Вместе они дают то, что видит
# игрок: под предметом либо есть поверхность вплотную, либо предмет висит.
const REST_TOLERANCE := .06

func rest_gap(pos: Vector3, meshes: Array) -> float:
	var gap := pos.y
	var params := PhysicsRayQueryParameters3D.create(pos + Vector3(0, .02, 0), pos - Vector3(0, 3.0, 0))
	params.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	if not hit.is_empty():
		gap = minf(gap, pos.y - (hit["position"] as Vector3).y)
	for mesh in meshes:
		var instance := mesh as MeshInstance3D
		var box: AABB = instance.global_transform * instance.get_aabb()
		if pos.x < box.position.x or pos.x > box.end.x:
			continue
		if pos.z < box.position.z or pos.z > box.end.z:
			continue
		if box.end.y > pos.y + .01:
			continue
		gap = minf(gap, pos.y - box.end.y)
	return gap

func collect_props(node: Node, out: Array) -> void:
	if node is MeshInstance3D:
		var owner_name := str(node.name)
		var parent := node.get_parent()
		while parent:
			if str(parent.name).begins_with("Cash_") or str(parent.name).begins_with("Debt_"):
				return
			parent = parent.get_parent()
		if not (owner_name.begins_with("Cash_") or owner_name.begins_with("Debt_")):
			out.append(node)
	for child in node.get_children():
		collect_props(child, out)

func check_props_rest() -> bool:
	var meshes: Array = []
	collect_props(get_parent(), meshes)
	for source in [MONEY, DEBTS]:
		for id in source:
			var pos: Vector3 = (source[id] as Array)[0]
			var gap := rest_gap(pos, meshes)
			if not require(gap <= REST_TOLERANCE,
					"%s hangs in the air: %.2f m above anything below it" % [id, gap]):
				return false
	return true

func run_audit() -> void:
	await get_tree().physics_frame
	# Пять заначек на четыре слота и пять долгов, каждый берёт только свою
	# сумму, — это и есть мысль круга. Без проверки её можно потерять правкой
	# данных, и аудит останется зелёным.
	if not require(MONEY.size() > SLOTS,
			"circle IV lost its point: %d stashes for %d slots" % [MONEY.size(), SLOTS]): return
	if not require(MONEY.size() == DEBTS.size(),
			"stash/debt count mismatch: %d vs %d" % [MONEY.size(), DEBTS.size()]): return
	if not check_props_rest(): return
	var expected := MONEY.size() + DEBTS.size() + ROOM_ZONES.size() + 4
	if not require(interactor.targets.size() == expected,
			"unexpected zone count: %d, expected %d" % [interactor.targets.size(), expected]): return
	for id in ROOM_ZONES:
		if not require(interactor.entry(str(id))["usable"], "room zone is not usable: %s" % id): return
	if not check_no_overlap(): return
	if not check_props_placed([]): return
	if not check_reachable(reach_origins()): return
	if not check_actions_bound(MONEY.keys() + DEBTS.keys()): return
	if not require(message_on_screen(), "message sits off screen"): return
	if not require(act == Act.SETTLE, "circle IV did not start in the settle act"): return
	if not require(current_goal().contains("Расплатись"), "H says nothing useful in act I"): return
	await shot("c4_loaded", Vector3(1.25, .05, .15), .4, -.20)

	# Неверная сумма обязана отказывать, а не проходить: берём первую заначку и
	# пробуем закрыть ею чужой долг.
	var money_ids := MONEY.keys()
	var debt_ids := DEBTS.keys()
	on_used(str(money_ids[0]))
	if not require(carried.has(str(money_ids[0])), "first cash was not picked up"): return
	inventory.select_by_id(str(money_ids[0]))
	var wrong_debt := ""
	for id in debt_ids:
		if str(id) != str((MONEY[money_ids[0]] as Array)[4]):
			wrong_debt = str(id)
			break
	on_used(wrong_debt)
	if not require(not settled.has(wrong_debt), "wrong sum was accepted at %s" % wrong_debt): return
	if not require(carried.has(str(money_ids[0])), "cash vanished after a rejected match"): return
	await shot("c4_wrong_sum", Vector3(1.25, .05, .15), .4, -.20)

	# Инвентарь обязан упереться в потолок: пять заначек, четыре слота.
	for index in range(1, SLOTS):
		on_used(str(money_ids[index]))
	if not require(inventory.items.size() == SLOTS,
			"inventory did not fill up: %d" % inventory.items.size()): return
	on_used(str(money_ids[SLOTS]))
	if not require(inventory.items.size() == SLOTS, "the fifth stash fit into four slots"): return
	if not require(not carried.has(str(money_ids[SLOTS])), "the fifth stash was taken anyway"): return
	await shot("c4_hands_full", Vector3(1.25, .05, .15), .4, -.20)

	# Расплачиваемся по всем долгам верными суммами, возвращаясь за остатком —
	# так и пойдёт живой игрок, которому не хватило слотов на все пять.
	var guard := 0
	while settled.size() < DEBTS.size() and guard < 60:
		guard += 1
		var progressed := false
		for id in carried.keys():
			var debt: String = (MONEY[id] as Array)[4]
			if not settled.has(debt):
				inventory.select_by_id(str(id))
				on_used(debt)
				progressed = true
				break
		if progressed:
			continue
		for id in MONEY:
			if not carried.has(str(id)) and not settled_by(str(id)) and inventory.items.size() < SLOTS:
				on_used(str(id))
				progressed = true
				break
		if not progressed:
			break
	if not require(settled.size() == DEBTS.size(),
			"not every debt was settled: %d" % settled.size()): return
	if not require(inventory.items.size() == 0, "cash stayed in the inventory"): return
	if not require(act == Act.COMPLETE, "settling every debt did not end act I"): return
	# Комната обязана показывать то же число, что и счётчик: ни одного
	# неоплаченного счёта на виду и ровно пять пачек на их местах. Прежде здесь
	# не проверялось ничего, и все пять счетов спокойно лежали на полу до конца.
	for id in debt_nodes:
		if not require(not debt_nodes[id].visible, "settled debt is still on display: %s" % id): return
	var shown := 0
	for id in money_nodes:
		if money_nodes[id].visible:
			shown += 1
	if not require(shown == DEBTS.size(),
			"visible cash does not match settled debts: %d vs %d" % [shown, DEBTS.size()]): return
	await shot("c4_settled", Vector3(1.25, .05, .15), .4, -.20)

	var wait_guard := 0
	while clock_display.text != "16:08:00" and wait_guard < 200:
		await get_tree().create_timer(.1).timeout
		wait_guard += 1
	if not require(clock_display.text == "16:08:00", "clock shows %s" % clock_display.text): return
	await shot("c4_complete")

	full_reset()
	if not require(act == Act.SETTLE and settled.is_empty() and carried.is_empty(),
			"full_reset did not clean up"): return
	for id in money_nodes:
		if not require(money_nodes[id].visible, "full_reset left cash hidden: %s" % id): return
		if not require(money_nodes[id].position.is_equal_approx(Vector3.ZERO),
				"full_reset left cash at the debt it paid: %s" % id): return
	for id in debt_nodes:
		if not require(debt_nodes[id].visible, "full_reset left a debt hidden: %s" % id): return

	print("GREED_AUDIT_OK circle IV: %d zones, %d stashes, %d debts, %d slots, clock 16:07->16:08"
		% [interactor.targets.size(), MONEY.size(), DEBTS.size(), SLOTS])
	prepare_shutdown()
	await get_tree().create_timer(.35).timeout
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if (event as InputEventKey).keycode == KEY_H:
		get_viewport().set_input_as_handled()
		request_hint()
