class_name CircleLevel
extends Node3D

# Общая основа круга. Всё, что одинаково для девяти кругов ада, живёт здесь;
# содержание конкретного круга — в наследнике (LimboLevel, LustLevel, ...).
#
# Что здесь есть и почему именно здесь:
#
# * Ссылки на части номера (`cache_room`). Комната у кругов одна и та же — она и
#   есть ад, который повторяется. Разный у кругов не номер, а то, что с ним
#   происходит.
# * Сборка систем (`build_systems`). Системы в `scripts/systems/` уже общие,
#   здесь только порядок их создания и связывания.
# * Инструменты аудита: `require`, `aim_probe`, `check_no_overlap`,
#   `check_reachable`, `shot`, `message_on_screen`.
#
#   Это самая важная причина существования файла. Скопированный аудит, который
#   тихо перестал что-то проверять, — главная зафиксированная беда этого проекта:
#   круг вставал намертво, а проверка оставалась зелёной. Второй копии этих
#   функций быть не должно.
# * Клавиша H (`request_hint`). Ступени ведёт HintDirector, а когда сказать
#   нечего нового — круг называет цель сам, через `current_goal()`.
#
# Чего здесь НЕТ намеренно: актов, зон, предметов и разбора env-режимов в
# `_ready`. У каждого круга свои акты со своим перечислением, и попытка обобщить
# их привела бы к базовому классу, который знает про содержание кругов.

# Что печатать в провале аудита: у каждого круга свой маркер, чтобы
# verify_release различал, чей прогон упал.
var audit_tag := "LIMBO"

var player: CharacterBody3D
var camera: Camera3D
var world_environment: WorldEnvironment

var hud: Hud
var cue: CueAudio
var interactor: Interactor
var inspect: InspectView
var inventory: Inventory
var clock: ClockDirector
var anomalies: AnomalyDirector
var hints: HintDirector
var code_lock: CodeLock

# Счётчик перезапусков круга. Все отложенные продолжения (`await` в анимациях и
# цепочках) сверяются с ним: сброс увеличивает счётчик, и «хвост» прошлой жизни
# круга сам себя гасит вместо того, чтобы дописывать состояние поверх нового.
var epoch := 0
var level_elapsed := 0.0

# Узлы номера, найденные в готовой геометрии.
var chair: Node3D
var painting: Node3D
var phone: Node3D
var wardrobe_model: Node3D
var wardrobe_collision: StaticBody3D
var entrance_door: Node3D
var entrance_collision: StaticBody3D
var entrance_details: Array[Node3D] = []
var curtain_left: Node3D
var curtain_right: Node3D
var bed_curtain_left: Node3D
var bed_curtain_right: Node3D
var bed_lamp_meshes := []
var lamp_off_material: StandardMaterial3D

var clock_display: Label3D
var clock_glow: OmniLight3D
var lamp_lights: Array[OmniLight3D] = []
# Лампа в прихожей и лампа на письменном столе: свои меши и свой свет, чтобы их
# можно было гасить наравне с прикроватными.
var extra_lamps := []

var room_lights: Array[Light3D] = []
var room_light_energy: Array[float] = []
var switch_groups := {}
var switch_on := {}
var original := {}

# Мелкая награда за первое обращение к предмету и что уже сказано тихим откликом.
var rewarded := {}
var quiet_said := {}

# Режим прохождения: аудит тот же, но на каждом рубеже сохраняется кадр.
var walkthrough := false
var shot_dir := ""
var shot_index := 0

# ------------------------------------------------------------------ комната ---

func cache_room() -> void:
	var root := get_parent()
	chair = root.find_child("BedroomReadingChair", true, false)
	painting = root.find_child("MeaningfulBedPainting", true, false)
	phone = root.find_child("VintageTelephone", true, false)
	wardrobe_model = root.find_child("Wardrobe", true, false)
	wardrobe_collision = root.find_child("WardrobeCollision", true, false)
	entrance_door = root.find_child("EntranceDoorModel", true, false)
	entrance_collision = root.find_child("EntranceDoorCollision", true, false)
	for detail_name in ["Peephole", "RoomNumberPlate", "RoomNumber1604"]:
		var detail := root.find_child(detail_name, true, false) as Node3D
		if detail:
			# The peephole and room number belong to the door leaf and must travel
			# with it while the entrance opens and closes.
			if detail.get_parent() != entrance_door:
				detail.reparent(entrance_door, true)
			entrance_details.append(detail)
	curtain_left = root.get_node("HotelSuite/LivingRoom/CurtainLeft")
	curtain_right = root.get_node("HotelSuite/LivingRoom/CurtainRight")
	bed_curtain_left = root.get_node("HotelSuite/Bedroom/CurtainLeft")
	bed_curtain_right = root.get_node("HotelSuite/Bedroom/CurtainRight")
	original.bed_curtain_left = bed_curtain_left.transform
	original.bed_curtain_right = bed_curtain_right.transform

	Build.move_pivot(chair, Vector3(3.48, 0, .15))
	Build.move_pivot(painting, Vector3(1.25, 1.88, -3.08))
	Build.move_pivot(phone, Vector3(2.61, .56, -2.78))
	Build.move_pivot(entrance_door, Vector3(-3.10, 0, -3.13))
	# Keep the physical blocker on the same pivot as the visual door. Without
	# this, the mesh animated but the collision stayed in the closed position.
	if entrance_collision and entrance_collision.get_parent() != entrance_door:
		entrance_collision.reparent(entrance_door, true)

	for light in root.find_children("*", "Light3D", true, false):
		room_lights.append(light)
		room_light_energy.append(light.light_energy)
	# Заливка лунного света намеренно не заведена ни на один выключатель:
	# когда игрок гасит всё, комната становится тёмной, но проходимой.
	var groups := {
		"switch_hall": ["HallAmber", "HallCeiling"],
		"switch_bedroom": ["BedroomAmber", "BedroomCeiling"],
		"switch_bathroom": ["BathroomSconce", "BathroomCeiling"],
		"switch_living": ["LivingAmber", "LivingSoftFill", "LivingCeiling"]
	}
	for switch_id in groups:
		var lights: Array[Light3D] = []
		for light_name in groups[switch_id]:
			var light := root.find_child(light_name, true, false) as Light3D
			if light:
				lights.append(light)
		switch_groups[switch_id] = lights
		switch_on[switch_id] = true

	lamp_off_material = StandardMaterial3D.new()
	lamp_off_material.albedo_color = Color("181512")
	lamp_off_material.roughness = .9
	for side in ["BedsideTableLeft", "BedsideTableRight"]:
		var lamp_root := root.get_node("HotelSuite/Bedroom/%s/BedLamp" % side)
		bed_lamp_meshes.append(lamp_root.find_children("*", "MeshInstance3D", true, false))
	for entry in [["EntryLamp", Vector3(-4.02, 1.20, -1.92)], ["DeskLamp", Vector3(4.02, 1.22, 1.12)]]:
		var lamp_root := root.find_child(str(entry[0]), true, false) as Node3D
		if not lamp_root:
			continue
		var light := OmniLight3D.new()
		light.name = str(entry[0]) + "GameplayLight"
		light.position = entry[1]
		light.light_color = Color("ffd09a")
		light.light_energy = .44
		light.omni_range = 2.2
		light.shadow_enabled = false
		add_child(light)
		extra_lamps.append({"meshes": lamp_root.find_children("*", "MeshInstance3D", true, false), "light": light})

	original.chair = chair.transform
	original.painting = painting.transform
	original.phone = phone.transform
	original.door = entrance_door.transform
	original.curtain_left = curtain_left.transform
	original.curtain_right = curtain_right.transform
	original.player = player.transform

# ------------------------------------------------------------- обстановка ---
#
# Тридцать «тихих» зон обстановки номера плюс четыре выключателя: одна и та же
# геометрия во всех кругах, свой текст у каждого. Родилось в Круге II
# (`ROOM_ZONES`/`ROOM_ORIGINS`), но жило только там; Круг III начался с семью
# зонами против сорока пяти — комната читалась недоделанной, сколько бы ни
# было сюжета. Третья копия тех же координат была бы уже перебором, поэтому
# таблицы и логика вокруг них переехали сюда один раз для всех девяти кругов.
#
# Формат строки ROOM_ZONES: [позиция, габариты, заголовок, текст осмотра, тихий
# отклик на E]. `register_room_flavor(overrides)` даёт каждому кругу заменить
# заголовок/текст/отклик по id, не трогая геометрию и не заводя вторую таблицу.
const ROOM_ZONES := {
	"console": [Vector3(-3.92, .50, -1.72), Vector3(.40, .44, .80), "Консоль у входа",
		"Узкий столик у двери.", "Ты провёл ладонью по столешнице. Пыли нет."],
	"entry_lamp": [Vector3(-4.02, 1.15, -1.92), Vector3(.40, .78, .40), "Лампа в прихожей",
		"Латунная стойка с абажуром.", "Абажур качнулся и встал как был."],
	"hall_plant": [Vector3(-4.00, 1.00, -1.52), Vector3(.30, .40, .30), "Растение",
		"Мелкие плотные листья в глиняном горшке.", "Земля сухая на два пальца в глубину."],
	"hall_painting": [Vector3(-4.10, 1.93, -1.72), Vector3(.26, .64, .84), "Картина с озером",
		"Горное озеро в латунной раме.", "Рама держится ровно, гвоздь один."],
	"entry_rug": [Vector3(-2.72, .14, -2.35), Vector3(.80, .22, .36), "Коврик у двери",
		"Плотный ворс у самого входа.", "Ты отогнул угол. Под ковриком голый паркет."],
	"hall_outlet": [Vector3(-2.05, .32, -2.54), Vector3(.28, .26, .24), "Розетка",
		"Круглое гнездо в латунной рамке.", "Гнездо пустое и холодное."],
	"drawer_left": [Vector3(0, .30, -2.57), Vector3(.44, .36, .22), "Левая тумбочка",
		"Ящик с той стороны кровати.", "Ящик поддался и встал на место."],
	"drawer_right": [Vector3(2.5, .30, -2.57), Vector3(.44, .36, .22), "Правая тумбочка",
		"Ящик с ближней стороны кровати.", "Пусто. Задвинут до упора."],
	"radiator_bed": [Vector3(4.02, .42, -1.10), Vector3(.22, .45, .75), "Радиатор",
		"Секционный, с латунным вентилем.", "Вентиль проворачивается вхолостую."],
	"bed_outlet": [Vector3(3.30, .32, -2.97), Vector3(.28, .26, .22), "Розетка у кровати",
		"Ещё одно гнездо в стене.", "Пусто, как и первое."],
	"tub": [Vector3(-3.18, .55, 2.30), Vector3(1.40, .35, .22), "Ванна",
		"Чугунная, с латунной арматурой.", "Ободок сухой на ощупь."],
	"toilet": [Vector3(-3.89, .42, .96), Vector3(.52, .68, .60), "Унитаз",
		"Белый фаянс, бачок полон.", "Бачок ухнул и снова начал набираться."],
	"towels": [Vector3(-2.12, .80, 1.25), Vector3(.22, .70, .78), "Полотенца",
		"Сложены гостиничным углом.", "Ты поправил стопку. Полотенца сухие."],
	"hand_towel": [Vector3(-2.12, .80, .40), Vector3(.22, .36, .40), "Полотенце для рук",
		"На латунном кольце.", "Полотенце качнулось и вернулось ровно как было."],
	"wastebasket": [Vector3(-3.98, .22, .43), Vector3(.30, .40, .30), "Корзина",
		"Плетёная корзина у раковины.", "На дне ничего, кроме пыли."],
	"shower": [Vector3(-3.70, 1.35, 2.98), Vector3(.44, .90, .22), "Душ",
		"Лейка на гибком шланге.", "Вентиль проворачивается свободно."],
	"toilet_paper": [Vector3(-4.14, .67, 1.52), Vector3(.20, .34, .38), "Держатель",
		"Рулон на латунном штыре.", "Рулон провернулся со щелчком."],
	"sofa": [Vector3(3.22, .55, 3.15), Vector3(.20, .40, 1.50), "Диван",
		"Бежевая обивка гостиной.", "Ты нажал на подушку. Она выпрямилась медленно."],
	"coffee_table": [Vector3(1.05, .32, 2.72), Vector3(.60, .30, .20), "Журнальный столик",
		"Лакированная столешница.", "Ты провёл пальцем по лаку. Гладко."],
	"living_armchair": [Vector3(2.20, .55, 4.36), Vector3(.70, .40, .20), "Кресло в гостиной",
		"Оливковое кресло у окна.", "Кресло качнулось и осталось стоять как было."],
	"minibar": [Vector3(4.00, .53, 4.68), Vector3(.42, .72, .80), "Минибар",
		"Низкий шкафчик со стеклянной дверцей.", "Внутри пусто и холодно."],
	"living_mirror": [Vector3(4.14, 1.30, 4.68), Vector3(.20, .75, .68), "Зеркало у минибара",
		"Небольшое зеркало в латунной раме.", "Стекло чистое, отражение обычное."],
	"living_painting": [Vector3(4.13, 1.72, 3.15), Vector3(.22, .60, 1.26), "Картина с отелем",
		"Ночной отель, горит одно окно.", "Рама качнулась. Окно на картине осталось гореть."],
	"desk_lamp": [Vector3(4.02, 1.14, 1.12), Vector3(.40, .78, .40), "Лампа на столе",
		"Рабочая лампа с зелёным абажуром.", "Цепочка выключателя звякнула."],
	"desk_chair": [Vector3(3.28, .50, 1.55), Vector3(.46, .88, .46), "Стул",
		"Отодвинут от письменного стола.", "Стул откатился и остановился."],
	"radiator_living": [Vector3(.80, .42, 5.35), Vector3(1.15, .45, .22), "Радиатор в гостиной",
		"Такой же, как в спальне.", "Тот же холод и тот же свободный вентиль."],
	"door": [Vector3(-2.65, .72, -2.88), Vector3(.8, 1.25, .35), "Входная дверь",
		"Латунная ручка, замок изнутри.", "Замок проворачивается вхолостую."],
	"plate": [Vector3(-2.65, 1.92, -2.88), Vector3(.5, .28, .30), "Табличка 1604",
		"Номер привинчен изнутри.", "Ты провёл по цифрам. Держатся крепко."],
	"clock": [Vector3(2.28, 1.72, .67), Vector3(1.0, 1.15, .38), "Настенные часы",
		"Тёмный корпус, латунные кольца.", "Корпус тёплый на ощупь."],
	"chair": [Vector3(3.44, .60, .15), Vector3(.78, 1.0, .78), "Кресло у окна",
		"Оливковое кресло у окна.", "Ты провёл рукой по спинке."]
}
# Точки обзора для каждой зоны обстановки: та же геометрия во всех кругах,
# подход к вещам у игрока один и тот же.
const ROOM_ORIGINS := {
	"console": Vector3(-3.40, 1.30, -1.72), "entry_lamp": Vector3(-3.45, 1.30, -1.92),
	"hall_plant": Vector3(-3.45, 1.30, -1.52), "hall_painting": Vector3(-3.40, 1.80, -1.72),
	"entry_rug": Vector3(-2.72, 1.30, -1.70), "hall_outlet": Vector3(-2.05, 1.10, -1.90),
	"drawer_left": Vector3(0, 1.10, -2.00), "drawer_right": Vector3(2.50, 1.10, -2.00),
	"radiator_bed": Vector3(3.35, 1.00, -1.10),
	"bed_outlet": Vector3(3.30, 1.10, -2.30), "tub": Vector3(-3.18, 1.30, 2.00),
	"toilet": Vector3(-3.30, 1.20, .96), "towels": Vector3(-2.70, 1.20, 1.25),
	"hand_towel": Vector3(-2.70, 1.10, .40), "wastebasket": Vector3(-3.50, 1.10, .43),
	"shower": Vector3(-2.90, 1.45, 2.98), "toilet_paper": Vector3(-3.60, 1.00, 1.52),
	"sofa": Vector3(2.90, 1.30, 3.15), "coffee_table": Vector3(1.05, 1.30, 2.30),
	"living_armchair": Vector3(2.20, 1.30, 4.10), "minibar": Vector3(3.30, 1.20, 4.68),
	"living_mirror": Vector3(3.40, 1.40, 4.68), "living_painting": Vector3(3.30, 1.75, 3.15),
	"desk_lamp": Vector3(3.40, 1.25, 1.12), "desk_chair": Vector3(2.70, 1.20, 1.55),
	"radiator_living": Vector3(.80, 1.10, 4.60),
	"door": Vector3(-2.65, 1.20, -1.75), "plate": Vector3(-2.65, 1.60, -1.75),
	"clock": Vector3(2.28, 1.55, 2.05), "chair": Vector3(2.55, 1.35, .15)
}
# Выключатели: единственная «громкая» обстановка — у них есть настоящее
# последствие, свет гаснет и загорается. Габариты скромные: зона крупнее
# клавиши перехватывает лучи к соседней мебели.
const SWITCH_ZONES := [
	["switch_hall", Vector3(-2.05, 1.18, -2.52), Vector3(.34, .38, .28), "Выключатель в прихожей"],
	["switch_bedroom", Vector3(-1.72, 1.18, -1.15), Vector3(.30, .38, .34), "Выключатель в спальне"],
	["switch_bathroom", Vector3(-2.03, 1.18, .25), Vector3(.28, .38, .34), "Выключатель в ванной"],
	["switch_living", Vector3(.18, 1.30, .90), Vector3(.34, .38, .28), "Выключатель в гостиной"]
]
const SWITCH_ORIGINS := {
	"switch_hall": Vector3(-2.05, 1.45, -1.82), "switch_bedroom": Vector3(-.95, 1.45, -1.15),
	"switch_bathroom": Vector3(-2.75, 1.45, .25), "switch_living": Vector3(.18, 1.45, 1.55)
}

# Отклики обстановки, переопределённые кругом поверх ROOM_ZONES[id][4]. Текст
# на E не хранится в Area3D, поэтому override живёт здесь, а не в interactor.
var flavor_response := {}

# Регистрирует все тридцать зон обстановки. overrides позволяет кругу заменить
# заголовок/текст/отклик по id без второй таблицы координат: значение — массив
# [заголовок, текст, отклик], где любой элемент можно оставить null.
func register_room_flavor(overrides: Dictionary = {}) -> void:
	for id in ROOM_ZONES:
		var row: Array = ROOM_ZONES[id]
		var title: String = str(row[2])
		var text: String = str(row[3])
		if overrides.has(id):
			var ov = overrides[id]
			if ov is Array:
				if ov.size() > 0 and ov[0] != null: title = str(ov[0])
				if ov.size() > 1 and ov[1] != null: text = str(ov[1])
				if ov.size() > 2 and ov[2] != null: flavor_response[str(id)] = str(ov[2])
			else:
				text = str(ov)
		interactor.register(str(id), row[0], row[1], {
			"title": title, "text": text, "usable": true, "quiet": true})

func register_switch_zones() -> void:
	for row in SWITCH_ZONES:
		interactor.register(str(row[0]), row[1], row[2], {
			"title": str(row[3]),
			"text": "Латунная клавиша. Щёлкает мягко и очень отчётливо.",
			"usable": true})

# Точки обзора обстановки и выключателей одним словарём: круг подмешивает его
# в свой reach_origins() через merge(), сюжетные зоны остаются его заботой.
func flavor_origins() -> Dictionary:
	var origins := {}
	for id in ROOM_ORIGINS:
		origins[id] = ROOM_ORIGINS[id]
	for id in SWITCH_ORIGINS:
		origins[id] = SWITCH_ORIGINS[id]
	return origins

# Тихий отклик обстановки: не затирает описание предмета, а дописывает к нему
# то, что игрок сделал. Повторный осмотр показывает оба текста.
func use_room_zone(id: String) -> void:
	if id == "entry_lamp" or id == "desk_lamp":
		toggle_extra_lamp(0 if id == "entry_lamp" else 1, id)
		return
	var line: String = flavor_response.get(id, str(ROOM_ZONES[id][4]))
	hud.show_message(line, 3.0)
	if not quiet_said.has(id):
		quiet_said[id] = true
		interactor.set_text(id, str(ROOM_ZONES[id][3]) + "\n" + line)
	reward(id)

func toggle_extra_lamp(index: int, id: String = "") -> void:
	if index < 0 or index >= extra_lamps.size():
		return
	var lamp: Dictionary = extra_lamps[index]
	var light := lamp["light"] as OmniLight3D
	var turn_on := not light.visible
	light.visible = turn_on
	for mesh in lamp["meshes"]:
		mesh.material_override = null if turn_on else lamp_off_material
	cue.play("switch")
	hud.show_message("Щелчок. Лампа %s." % ("зажглась" if turn_on else "погасла"), 2.2)
	var target_id := id if not id.is_empty() else ("entry_lamp" if index == 0 else "desk_lamp")
	interactor.set_text(target_id, "Лампа с выключателем. Сейчас %s." % ("включена" if turn_on else "выключена"))
	reward(target_id)

func toggle_switch(id: String) -> void:
	var on: bool = not bool(switch_on.get(id, true))
	switch_on[id] = on
	for light in lights_of(id):
		light.visible = on
	cue.play("switch")
	hud.show_message("Щелчок. Свет %s." % ("вернулся" if on else "погас"), 2.4)
	interactor.set_text(id, "Латунная клавиша. Сейчас %s." % ("включено" if on else "выключено"))
	reward(id)

func lights_of(switch_id: String) -> Array:
	var group = switch_groups.get(switch_id, [])
	return group if group is Array else []

# Мелкая награда за первое обращение к предмету обстановки: полсекунды один раз.
func reward(id: String) -> void:
	if rewarded.has(id):
		return
	rewarded[id] = true
	clock.advance(.5)

func build_systems() -> void:
	cue = CueAudio.new()
	add_child(cue)
	hud = Hud.new()
	add_child(hud)
	interactor = Interactor.new()
	add_child(interactor)
	interactor.setup(camera, hud)
	inspect = InspectView.new()
	add_child(inspect)
	inspect.setup(player, cue)
	inventory = Inventory.new()
	add_child(inventory)
	inventory.setup(hud, cue)
	anomalies = AnomalyDirector.new()
	add_child(anomalies)
	anomalies.setup(camera, cue)
	hints = HintDirector.new()
	add_child(hints)
	hints.setup(hud, cue)
	code_lock = CodeLock.new()
	add_child(code_lock)
	code_lock.setup(player, cue)

# --------------------------------------------------------------- подсказки ---

# Клавиша H. Первые нажатия ведут по ступеням подсказки, а когда самая прямая
# ступень уже показана — круг называет цель прямым текстом.
#
# Молчащая клавиша читается как сломанная, поэтому ответ обязателен всегда.
func request_hint() -> void:
	if hints.request():
		return
	hints.emphasize()
	hud.show_message(current_goal(), 4.6)

# Цель прямым текстом. Круг обязан переопределить: он один знает свои акты.
func current_goal() -> String:
	return "Оглядись."

func prepare_shutdown() -> void:
	if cue:
		cue.shutdown()

func _exit_tree() -> void:
	prepare_shutdown()

# ------------------------------------------------------------------- аудит ---

# Проверки аудита не используют assert: в release-сборке он вырезается, и
# сломанная цепочка молча печатала бы «OK». Здесь провал гасит процесс с
# ненулевым кодом и в отладочной сборке, и в собранном EXE.
func require(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("%s_AUDIT_FAIL: %s" % [audit_tag, message])
	prepare_shutdown()
	get_tree().quit(1)
	return false

# Пересекающиеся зоны — главный источник «предмет не наводится»: та, что ближе к
# игроку, молча съедает соседнюю. Проверять полсотни зон лучами непрактично, а
# попарное пересечение ловит тот же класс поломок целиком и мгновенно.
#
# allowed — пары, которым пересекаться разрешено осознанно (сейф внутри шкафа).
func check_no_overlap(allowed: Array = []) -> bool:
	var ids := interactor.targets.keys()
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var a := str(ids[i])
			var b := str(ids[j])
			if [a, b] in allowed or [b, a] in allowed:
				continue
			var box_a: AABB = interactor.targets[a]["bounds"]
			var box_b: AABB = interactor.targets[b]["bounds"]
			if box_a.intersects(box_b):
				if not require(false, "zones overlap: %s and %s" % [a, b]):
					return false
	return true

# Каждая зона должна ловиться настоящим лучом камеры с той точки, откуда игрок на
# неё смотрит. Аудит, который дёргает функции уровня напрямую, поломок наведения
# не видит вовсе: зоны глазка и таблички тихо тонули внутри крупной зоны двери, а
# сейф был закрыт физической коробкой шкафа и не открывался.
#
# origins — точка обзора для каждой зоны. Зона, которой нет в словаре, НЕ
# проверялась вовсе — и это была дыра ровно того сорта, ради которого написан
# весь этот файл: забыть зону в reach_origins() было МОЛЧАЛИВЫМ способом
# отключить ей проверку наведения, и аудит оставался зелёным. Поэтому теперь
# первым делом сверяются сами списки: каждая зарегистрированная зона обязана
# иметь точку обзора, и наоборот.
#
# exempt — зоны, которым точка обзора не положена осознанно (зона, которую
# игрок не наводит руками, а уровень дёргает сам).
func check_reachable(origins: Dictionary, exempt: Array = []) -> bool:
	var missing: Array[String] = []
	for id in interactor.targets:
		if not origins.has(id) and not (str(id) in exempt):
			missing.append(str(id))
	if not require(missing.is_empty(),
			"zones registered without a reach origin (%d): %s" % [missing.size(), ", ".join(missing)]):
		return false
	# Обратная сторона: точка обзора без зоны — это опечатка в id, из-за которой
	# настоящая зона осталась непроверенной.
	var orphans: Array[String] = []
	for id in origins:
		if not interactor.targets.has(id):
			orphans.append(str(id))
	if not require(orphans.is_empty(),
			"reach origins without a zone (%d): %s" % [orphans.size(), ", ".join(orphans)]):
		return false

	# Собираем все промахи за один проход: чинить полсотни зон по одной — это
	# полсотни пересборок.
	var failures: Array[String] = []
	for id in origins:
		var reason := aim_probe(str(id), origins[id])
		if not reason.is_empty():
			failures.append(reason)
	return require(failures.is_empty(), "unreachable zones (%d):\n  %s" % [failures.size(), "\n  ".join(failures)])

func aim_check(id: String, origin: Vector3) -> bool:
	var reason := aim_probe(id, origin)
	return require(reason.is_empty(), reason)

func aim_probe(id: String, origin: Vector3) -> String:
	var area := interactor.zone(id)
	if not area:
		return "no zone registered for %s" % id
	var ray := interactor.ray
	var saved_transform := ray.global_transform
	var saved_target := ray.target_position
	ray.global_position = origin
	ray.target_position = ray.to_local(area.global_position)
	ray.force_raycast_update()
	var collider := ray.get_collider()
	var hit_name := "ничего"
	var hit_id := ""
	if collider is Node:
		hit_name = (collider as Node).name
		if collider is Area3D:
			hit_id = str((collider as Area3D).get_meta("interaction_id", ""))
	var distance := origin.distance_to(area.global_position)
	ray.global_transform = saved_transform
	ray.target_position = saved_target
	ray.force_raycast_update()
	if hit_id != id:
		return "%s: перекрыт (%s)" % [id, hit_name]
	if distance > Interactor.REACH:
		return "%s: %.2f м, вне досягаемости" % [id, distance]
	return ""

# Мёртвое [E]: зона обещает действие (usable), а on_used() её не разбирает ни
# одной веткой — нажатие уходит в пустоту. Проверка наведения такую поломку не
# видит вовсе: зона прекрасно ловится лучом, просто ничего не делает.
#
# story — id, которые круг разбирает своими ветками. Обстановка и выключатели
# разбираются одинаково во всех девяти кругах, поэтому они зашиты здесь и
# кругам их перечислять не нужно.
func check_actions_bound(story: Array) -> bool:
	var unbound: Array[String] = []
	for id in interactor.targets:
		# Смотрим и на исходное значение: `usable` меняется по ходу круга
		# (взятый поднос гасит свою зону), и проверка только текущего состояния
		# молча пропускала бы всё, что круг успел выключить или ещё не включил.
		if not bool(interactor.targets[id]["usable"]) \
				and not bool(interactor.targets[id]["default_usable"]):
			continue
		var key := str(id)
		if key in story or ROOM_ZONES.has(key) or key.begins_with("switch_"):
			continue
		unbound.append(key)
	return require(unbound.is_empty(),
		"usable zones with no action bound (%d): %s" % [unbound.size(), ", ".join(unbound)])

# Строка сообщений обязана стоять на экране, а не за его краем: привязки Control
# внутри CanvasLayer здесь не разрешаются, и подсказки однажды не показывались
# вовсе, кроме как поверх панели сейфа.
func message_on_screen() -> bool:
	var height := get_viewport().get_visible_rect().size.y
	return hud.message.position.y > 0.0 and hud.message.position.y + Hud.MESSAGE_HEIGHT <= height

# Включить режим прохождения: тот же аудит, но с кадром на каждом рубеже.
func begin_walkthrough(directory: String) -> void:
	walkthrough = true
	shot_dir = directory
	if shot_dir == "1" or shot_dir.is_empty():
		shot_dir = "res://qa_screens/walk"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(shot_dir))

# Кадр прохождения. Вне режима прохождения ничего не делает, поэтому обычный
# headless-аудит от этих вызовов не становится ни медленнее, ни другим.
#
# Камеру ставим явно: аудит зовёт обработчики напрямую и игрока по комнате не
# водит, поэтому без позы кадр покажет не то, что проверяется, а куда игрок
# случайно смотрел на прошлом шаге.
func shot(label: String, at := Vector3.ZERO, yaw := 0.0, pitch := 0.0) -> void:
	if not walkthrough:
		return
	if at != Vector3.ZERO:
		player.global_position = at
		player.rotation.y = yaw
		player.get_node("Head").rotation.x = pitch
		player.force_update_transform()
	# Ждём проявления строки сообщений: у неё .3 с на появление, и без паузы кадр
	# застаёт подсказку почти прозрачной — то есть скрывает ровно то, ради чего
	# прогон и делается. Кадров ждём с запасом: снимок берётся из уже показанного
	# буфера и отстаёт от состояния.
	await get_tree().create_timer(1.2).timeout
	for _i in range(8):
		await RenderingServer.frame_post_draw
	shot_index += 1
	var path := "%s/%02d_%s.png" % [shot_dir, shot_index, label]
	get_viewport().get_texture().get_image().save_png(path)
	print("WALK_SHOT %s" % path)

func collect_resource_files(path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if not directory:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var full_path := path.path_join(entry)
		if directory.current_is_dir():
			collect_resource_files(full_path, output)
		else:
			output.append(full_path)
		entry = directory.get_next()
	directory.list_dir_end()
