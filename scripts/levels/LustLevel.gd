extends CircleLevel

# КРУГ II — «УРАГАН». Комната 1604, 16:05 → 16:06.
#
# Замысел целиком — в КРУГ_II.md. Коротко: у Данте второй круг наказан вечным
# ураганом, который носит души и не даёт им остановиться. Здесь ураган буквальный,
# а содержание — чужая близость намёками: номер накрыт на двоих, а ты один.
#
# Комната та же, что в Круге I, и это главный приём: игрок узнаёт её раньше, чем
# замечает подмену. Часть обстановки первого круга спрятана, на её месте — чужие
# вещи.
#
# Сделан Акт I: унять ветер, закрыв четыре источника сквозняка. Акты II и III
# описаны в документе и не реализованы.
#
# Общее для всех кругов — в CircleLevel: части номера, сборка систем, клавиша H,
# весь инструментарий аудита.

enum Act { GALE, LETTERS, HOLD, COMPLETE }

# Акт II. Письма читаются по цепочке: каждое прочитанное называет место, где
# спрятано следующее. Порядок держится содержанием, а не интерфейсом — списка
# заданий в этой игре нет принципиально.
#
# Цепочка нарочно ведёт по вещам, с которыми игрок уже сталкивался в первом акте:
# связка на тумбочке, подушка, платье, зеркало, чемодан. Двух новых зон хватает.
const LETTER_CHAIN := ["c2_letters", "c2_pillow", "c2_dress", "c2_mirror", "c2_suitcase"]
const LETTER_TEXTS := [
	"«…я оставил остальные там, где ты их найдёшь, а он — нет. Первое под тем, на чём ты спишь.»",
	"«…ты просила не писать на адрес отеля. Я пишу. Следующее — в кармане платья, которое ты не надела.»",
	"«…платье так и висит. Ты сказала, что наденешь его, когда всё решится. Смотри за зеркалом.»",
	"«…за зеркалом удобно: горничная туда не лезет. Последнее — в его чемодане. Он не откроет, он не читает.»",
	"«…хватит. Забери их все и отдай ветру — иначе они останутся здесь, и ты вместе с ними. Открой фрамугу.»"
]
# Акт III. Комната возвращает на место СВОИ вещи, а не отнимает у игрока
# прочитанное или найденное: правило круга — наказать игрока нельзя, отнять
# решённое нельзя. Это давление, а не кара.
const HOLD_ANOMALIES := ["hold_sheets", "hold_dress", "hold_case"]

# Обстановка номера. Комната та же, что в Круге I, поэтому и геометрия зон та же —
# но текст свой: в этом круге каждая вещь говорит про двоих.
#
# Без этой таблицы номер во втором круге почти не отвечал на E: одиннадцать зон
# против шестидесяти девяти в первом. Пустая комната читается как недоделанная,
# сколько бы ни было сюжета.
#
# Формат: id -> [центр, габарит, заголовок, описание, отклик на E]
# Непустой отклик делает зону «тихой»: E отвечает, золотого [E] нет. Прицел
# по-прежнему значит «здесь есть что рассмотреть», а не «здесь решение».
#
# Спрятанных Кругом II предметов здесь нет намеренно (письменный набор, книги,
# кофемашина, сервиз, телевизор): зона над невидимой вещью — это [E] по пустоте.
# Геометрия обстановки — `CircleLevel.ROOM_ZONES`, общая для всех кругов.
# Здесь только то, чем Круг II отличается: текст и тихий отклик, [заголовок
# (null — оставить общий), текст, отклик]. Каждая вещь говорит про двоих —
# в этом и была мысль круга, когда обстановку впервые подняли из Круга I.
const ROOM_ZONE_TEXT := {
	"console": [null, "Узкий столик у двери. На нём кольцо от бокала и вторая, поменьше.",
		"Ящик выдвинут. Внутри шпилька и чужой билет с оторванным углом."],
	"entry_lamp": [null, "Латунная стойка. Абажур повёрнут к двери, будто кого-то ждали.",
		"Ты повернул абажур к стене. Свет стал ровнее и от этого хуже."],
	"hall_plant": [null, "Мелкие плотные листья. В земле потушена сигарета — не твоя.",
		"Ты вынул окурок. След от помады на фильтре не стёрся."],
	"hall_painting": [null, "Горное озеро. Рама висит ровно, а гвоздь в стене второй — рядом пустой.",
		"Ты отвёл картину. За ней светлый прямоугольник шире самой рамы."],
	"entry_rug": [null, "Плотный ворс, примят двумя парами следов. Обе пары внутрь.",
		"Ты отогнул угол. Под ковриком сухо и пусто."],
	"drawer_left": [null, "Ящик с той стороны кровати, где спал не ты.",
		"В ящике шпилька, флакон без этикетки и открытка без подписи."],
	"drawer_right": [null, "Твоя сторона. Ящик задвинут до упора.",
		"Пусто. Ты сам его опустошил, когда заселялся."],
	# Штору в спальне отдельной зоной НЕ заводим: она висит там же, где зона окна
	# window_bed, и check_no_overlap() справедливо на это ругался. Про парусящую
	# ткань говорит текст самого окна.
	"radiator_bed": [null, "Секционный, с латунным вентилем. На нём сохнет чулок.",
		"Чулок сухой насквозь и холодный. Ты повесил его обратно."],
	"bed_outlet": [null, "Ещё одно гнездо. Рядом на обоях светлый прямоугольник.",
		"Пусто. Из этого гнезда что-то выдернули с корнем."],
	"tub": [null, "Чугунная, с латунной арматурой. Ободок мокрый.",
		"Ты провёл по дну. Вода тёплая — здесь мылись час назад."],
	"toilet": [null, "Белый фаянс. Бачок полон.",
		"Бачок ухнул и снова начал набираться. Звука воды нет."],
	"towels": [null, "Сложены гостиничным углом. Использованы оба.",
		"Ты разворошил стопку. Оба полотенца влажные."],
	"hand_towel": [null, "На латунном кольце. Смято посередине.",
		"Полотенце качнулось и вернулось ровно как было."],
	"wastebasket": [null, "Плетёная корзина у раковины.",
		"На дне обрывки конверта. Адрес разорван так, что не собрать."],
	"shower": [null, "Лейка на гибком шланге. С неё капает.",
		"Вентиль проворачивается свободно. Капля всё равно падает."],
	"toilet_paper": [null, "Рулон надорван ровно, будто по линейке.",
		"Рулон провернулся со щелчком."],
	# Зона столика стоит на ближнем к игроку борту, а не по центру: по центру она
	# вкладывалась в зону винного набора, который на этом столике и стоит, и луч
	# к столику упирался бы в бутылку. Тот же приём, что у ванны и дивана в Круге I.
	"sofa": [null, "Бежевая обивка. Продавлен в двух местах, рядом.",
		"Ты нажал на подушку. Две вмятины не расходятся."],
	"coffee_table": [null, "На лаке два кольца от бокалов, вплотную.",
		"Ты провёл пальцем. Кольца не стираются — они въелись."],
	"living_armchair": [null, "Оливковое, развёрнуто не к окну, а к дивану.",
		"Кресло качнулось и осталось смотреть на диван."],
	"minibar": [null, "Низкий шкафчик со стеклянной дверцей.",
		"Внутри пусто, кроме счёта: две порции, один номер — твой."],
	"living_mirror": [null, "Небольшое зеркало в латунной раме. По краю след помады.",
		"Ты стёр след ладонью. Он остался, только размазанный."],
	"living_painting": [null, "Ночной отель. Горит одно окно — шестнадцатый этаж, четвёртое справа.",
		"Рама качнулась. Окно на картине осталось гореть."],
	"desk_lamp": [null, "Рабочая лампа с зелёным абажуром. Выключена.",
		"Щелчок. Лампа не загорелась."],
	"desk_chair": [null, "Отодвинут от стола ровно настолько, чтобы сесть вдвоём не вышло.",
		"Стул отъехал и остановился."],
	"radiator_living": [null, "Такой же холодный, как в спальне.",
		"Тот же холод и тот же свободный вентиль."],
	"door": [null, "Латунная ручка. Замок изнутри проворачивается вхолостую.",
		"Дверь не поддалась. Расчётный час прошёл час назад."],
	"plate": [null, "Номер привинчен изнутри. Латунь протёрта до белизны.",
		"Ты провёл по цифрам. Четвёрка держится на одном винте."],
	"clock": [null, "Тёмный корпус, латунные кольца. Минутная стрелка стоит на пятой минуте.",
		"Корпус тёплый. Стрелку не сдвинуть ни в одну сторону."],
	"chair": [null, "Оливковое кресло. На подлокотнике висит чужой шарф.",
		"Шарф ещё держит запах духов. Ты положил его обратно."]
}

const SOURCE_IDS := ["vent", "window_living", "window_bed", "transom"]
# Человеческие названия — нужны клавише H, когда она называет цель прямо.
const SOURCE_NAMES := {
	"vent": "решётка вентиляции в ванной",
	"window_living": "окно в гостиной",
	"window_bed": "окно в спальне",
	"transom": "фрамуга над входной дверью"
}
# Что Круг II убирает из номера. Та же комната, но неправильная: вещи, к которым
# игрок привык в первом круге, исчезли. Прячется предмет вместе со своей зоной,
# иначе прицел обещает [E] над пустотой.
const HIDDEN_NODES := ["WritingSet", "BedroomBooks", "CoffeeTableBooks", "Television",
	"CoffeeMachine", "CoffeeService"]

# Сколько источников ещё открыто. Пока больше нуля — в номере ураган.
var act := Act.GALE
var closed := {}
var catch_taken := false
var wind_time := 0.0
var flicker_at := 0.0
var letters_shuffled_at := 0.0

var letter_step := 0
var bundle_taken := false
var released := false

var suitcase_prop: Node3D
var dress_prop: Node3D
var bundle_prop: Node3D
var catch_prop: Node3D
var letters: MultiMeshInstance3D
var letter_home: Array[Transform3D] = []
var hidden_originals := {}

func _ready() -> void:
	name = "LustLevel"
	audit_tag = "LUST"
	player = get_parent().get_node("Player")
	camera = player.get_node("Head/Camera3D")
	world_environment = get_parent().get_node_or_null("Environment")
	cache_room()
	build_systems()
	build_props()
	register_targets()
	wire_signals()
	full_reset()
	if OS.has_environment("LUST_AUDIT"):
		await get_tree().process_frame
		run_audit()
	elif OS.has_environment("LUST_WALKTHROUGH"):
		# Тот же самый прогон, что и в аудите, но с картинкой. Именно тот же:
		# вторая копия последовательности разойдётся с первой, а в этом проекте
		# порядок шагов уже однажды оказался неигроцким и спрятал софтлок.
		begin_walkthrough(OS.get_environment("LUST_WALKTHROUGH"))
		await get_tree().process_frame
		run_audit()
	else:
		hud.show_message("КРУГ II\nУРАГАН", 3.2)
		show_controls()

func show_controls() -> void:
	var mark := epoch
	await get_tree().create_timer(4.2).timeout
	if mark != epoch:
		return
	hud.show_message("WASD — идти   ·   ЛКМ — рассмотреть   ·   E — тронуть   ·   H — подсказка", 5.0)

# ------------------------------------------------------------------- пропсы ---

func build_props() -> void:
	clock_display = Build.label3d(self, "ClockDisplay", "16:05:00", Vector3(2.28, 1.74, .915), Vector3.ZERO, 30, .0032)
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
	# Расчётный час уже прошёл: игрок в номере, из которого его выселили час назад.
	clock.start_label = "16:05"
	clock.end_label = "16:06"
	clock.refresh()

	var root := get_parent()
	# Решётка вентиляции в ванной: высоко на западной стене, над ванной.
	root.placed_model(self, "C2Vent", load("res://assets/models/c2_vent_grille.glb"),
		Vector3(-4.20, 1.94, 1.90), Vector3(0, PI / 2, 0), {"metal": "metal", "brass": "brass"})
	# Чужие вещи. Ни одной откровенности — только парность.
	suitcase_prop = root.placed_model(self, "C2Suitcase", load("res://assets/models/c2_suitcase.glb"),
		Vector3(1.95, 0, -.15), Vector3(0, .28, 0),
		{"leather": "wood2", "brass": "brass", "handle": "cream"})
	root.placed_model(self, "C2WineSet", load("res://assets/models/c2_wine_set.glb"),
		Vector3(1.05, .40, 3.15), Vector3(0, -.4, 0), {"brass": "brass", "glass": "glass"})
	root.placed_model(self, "C2Toothbrushes", load("res://assets/models/c2_toothbrush_glass.glb"),
		Vector3(-3.86, .92, -.30), Vector3.ZERO, {"glass": "glass", "handle": "cream"})
	dress_prop = root.placed_model(self, "C2Dress", load("res://assets/models/c2_dress_hanger.glb"),
		Vector3(-.51, .01, -.15), Vector3(0, PI / 2, 0), {"brass": "brass", "fabric": "flower_dark"})
	bundle_prop = root.placed_model(self, "C2Letters", load("res://assets/models/c2_letter_bundle.glb"),
		Vector3(2.42, .58, -2.62), Vector3(0, .5, 0), {"paper": "cream", "ribbon": "flower_dark"})
	# Шпингалет лежит под чемоданом: пока чемодан не тронут, его не видно.
	catch_prop = root.placed_model(self, "C2Catch", load("res://assets/models/c2_window_catch.glb"),
		Vector3(1.62, .01, -.32), Vector3(0, -.6, 0), {"brass": "brass", "handle": "chrome"})
	catch_prop.visible = false

	build_letters()
	register_hold_anomalies()

# Акт III: комната возвращает на место свои вещи, стоит отвести взгляд.
#
# Ни одна из этих аномалий не касается инвентаря и прочитанных писем. Отнимать у
# игрока найденное правила круга запрещают, поэтому «не отпускает» — это про
# обстановку, которая не хочет меняться, а не про наказание.
func register_hold_anomalies() -> void:
	anomalies.register("hold_sheets", null, func() -> void:
		scatter_letters(true),
		func() -> void:
			scatter_letters(true),
		{"watch": Vector3(1.20, .30, 1.60), "delay": 1.2})
	anomalies.register("hold_dress", dress_prop, func() -> void:
		dress_prop.position.z += .38,
		func() -> void:
			dress_prop.position = Vector3(-.51, .01, -.15),
		{"watch": Vector3(-.70, 1.50, -.15), "delay": 1.6})
	anomalies.register("hold_case", suitcase_prop, func() -> void:
		suitcase_prop.rotation.y = -.42,
		func() -> void:
			suitcase_prop.rotation.y = .28,
		{"watch": Vector3(1.95, .30, -.55), "delay": 1.4})

# Разлетевшиеся письма: один MultiMesh на всю россыпь. Ветер их перекладывает,
# и это самое заметное, что в комнате движется, — а звука у нас нет вовсе.
func build_letters() -> void:
	var sheet := load("res://assets/models/c2_letter_sheet.glb") as PackedScene
	var probe := sheet.instantiate() as Node3D
	var source := probe.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mesh := source.mesh as ArrayMesh
	for surface in mesh.get_surface_count():
		mesh.surface_set_material(surface, get_parent().mats["cream"])
	probe.free()
	letters = MultiMeshInstance3D.new()
	letters.name = "C2Letters Scattered"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = 14
	letters.multimesh = mm
	add_child(letters)
	scatter_letters(true)

func scatter_letters(initial: bool) -> void:
	var mm := letters.multimesh
	if initial:
		letter_home.clear()
	for i in range(mm.instance_count):
		var seed_value := i * 977 + (0 if initial else int(wind_time * 7.0) * 131)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var spot := Vector3(rng.randf_range(-2.2, 3.6), .015, rng.randf_range(-2.6, 4.6))
		var basis := Basis.from_euler(Vector3(0, rng.randf_range(-PI, PI), 0))
		var transform := Transform3D(basis, spot)
		mm.set_instance_transform(i, transform)
		if initial:
			letter_home.append(transform)

# ------------------------------------------------------------------- зоны ---

func register_targets() -> void:
	interactor.register("vent", Vector3(-4.10, 1.94, 1.90), Vector3(.24, .30, .34), {
		"title": "Решётка вентиляции",
		"text": "Решётка над ванной. Из шахты тянет ровно и сильно, ламели дрожат.",
		"usable": true})
	interactor.register("window_living", Vector3(.80, 1.45, 5.16), Vector3(1.10, .90, .30), {
		"title": "Окно в гостиной",
		"text": "Створка отошла и держится на одном шпингалете. Шторы у окна не опускаются ни на секунду.",
		"usable": true})
	interactor.register("window_bed", Vector3(3.86, 1.45, -1.10), Vector3(.30, .90, 1.00), {
		"title": "Окно в спальне",
		"text": "Такая же отошедшая створка. Ветер идёт снизу, из щели под рамой.",
		"usable": true})
	interactor.register("transom", Vector3(-2.65, 2.24, -2.86), Vector3(.80, .26, .30), {
		"title": "Фрамуга над дверью",
		"text": "Узкое окошко над входной дверью откинуто внутрь. Его надо закрыть, чтобы остановить сквозняк, но шпингалет сорван. Поищи его под чужим чемоданом у кровати.",
		"usable": true})
	interactor.register("c2_suitcase", Vector3(1.95, .30, -.15), Vector3(.56, .52, .34), {
		"title": "Чужой чемодан",
		"text": "Не твой. Стоит там, где ты бы его не поставил, и застёгнут не тобой.",
		"usable": true})
	interactor.register("c2_letters", Vector3(2.42, .62, -2.62), Vector3(.30, .16, .26), {
		"title": "Связка писем",
		"text": "Письма, перехваченные лентой. Почерк один и тот же, адресат — не ты."})
	interactor.register("c2_wine", Vector3(1.05, .52, 3.15), Vector3(.34, .34, .28), {
		"title": "Бутылка и два бокала",
		"text": "Оба бокала использованы. Вино в бутылке ещё есть."})
	interactor.register("c2_brushes", Vector3(-3.78, .96, -.30), Vector3(.20, .28, .22), {
		"title": "Стакан с щётками",
		"text": "Две щётки в одном стакане. Стоят так, будто ими пользовались утром."})
	interactor.register("c2_dress", Vector3(-1.21, 1.50, -.30), Vector3(.30, .80, .46), {
		"title": "Платье на вешалке",
		"text": "Тёмное платье на плечиках. Размер не твой, и висит оно в твоём шкафу."})
	# Две зоны второго акта. Заведены сразу и здесь, и в reach_origins(): зона,
	# которой нет в словаре точек обзора, НЕ проверяется вовсе.
	interactor.register("c2_pillow", Vector3(1.25, .66, -2.55), Vector3(1.10, .22, .40), {
		"title": "Подушки",
		"text": "Две подушки, обе смяты. С той стороны кровати спали тоже."})
	interactor.register("c2_mirror", Vector3(-4.08, 1.20, -.30), Vector3(.24, .70, .70), {
		"title": "Зеркало в ванной",
		"text": "Зеркало отходит от стены на палец: его снимали и вешали обратно."})
	# Обстановка номера: та же геометрия, что и в остальных кругах (`CircleLevel.
	# ROOM_ZONES`), свои тексты поверх неё — каждая вещь говорит про двоих.
	# Выключатели — «громкие»: у них есть настоящее последствие, свет гаснет и
	# загорается, за это [E] над ними заслужено, в отличие от тихой обстановки.
	register_room_flavor(ROOM_ZONE_TEXT)
	register_switch_zones()

func reach_origins() -> Dictionary:
	# Точка обзора для каждой зоны. Зона, которой нет в словаре, НЕ проверяется,
	# поэтому новую зону надо заводить сразу в двух местах. В кругах II–IX эту
	# проверку велено гонять с самой первой зоны, а не когда их станет полсотни.
	var origins := {
		"vent": Vector3(-3.30, 1.80, 1.90),
		"window_living": Vector3(.80, 1.45, 4.30),
		"window_bed": Vector3(3.00, 1.45, -1.10),
		"transom": Vector3(-2.65, 1.90, -2.00),
		"c2_suitcase": Vector3(1.95, 1.20, .70),
		"c2_letters": Vector3(2.42, 1.30, -2.00),
		"c2_wine": Vector3(1.05, 1.30, 2.45),
		"c2_brushes": Vector3(-3.20, 1.30, -.30),
		"c2_dress": Vector3(-.60, 1.45, -.30),
		"c2_pillow": Vector3(1.25, 1.35, -1.60),
		# Смотрят на зеркало с подхода и чуть сверху: стакан с щётками стоит ниже
		# и луч проходит над ним.
		"c2_mirror": Vector3(-3.20, 1.32, -.30)
	}
	# Обстановка и выключатели проверяются наравне с сюжетными зонами: зона,
	# которой нет в этом словаре, не проверяется вовсе.
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

# ------------------------------------------------------------------ ветер ---

func _process(delta: float) -> void:
	level_elapsed += delta
	# Ветер идёт в первом акте и возвращается вполсилы в третьем. Во втором акте
	# в номере тишина — на ней и держится весь второй акт.
	if act != Act.GALE and act != Act.HOLD:
		return
	wind_time += delta
	var strength := .45 if act == Act.HOLD \
		else float(SOURCE_IDS.size() - closed.size()) / float(SOURCE_IDS.size())
	blow_curtains(strength)
	# Мигание переиспользует уже существующие светильники: девятнадцати источников
	# в gl_compatibility достаточно, ни одного нового Light3D круг не добавляет.
	if wind_time >= flicker_at:
		flicker_at = wind_time + randf_range(1.4, 3.2) / maxf(strength, .2)
		gust_flicker(strength)
	# Ветер перекладывает бумаги: без звука это главный признак, что он идёт.
	if wind_time >= letters_shuffled_at:
		letters_shuffled_at = wind_time + 2.4
		scatter_letters(false)

func blow_curtains(strength: float) -> void:
	var swing := sin(wind_time * 2.7) * .16 * strength
	var swing_bed := sin(wind_time * 3.4 + 1.1) * .14 * strength
	curtain_left.position.x = original.curtain_left.origin.x + swing
	curtain_right.position.x = original.curtain_right.origin.x - swing
	bed_curtain_left.position.z = original.bed_curtain_left.origin.z + swing_bed
	bed_curtain_right.position.z = original.bed_curtain_right.origin.z - swing_bed

func gust_flicker(strength: float) -> void:
	for index in range(room_lights.size()):
		var light := room_lights[index]
		if not is_instance_valid(light) or randf() > .45:
			continue
		var base := room_light_energy[index]
		var tween := create_tween()
		tween.tween_property(light, "light_energy", base * (1.0 - .7 * strength), .07)
		tween.tween_property(light, "light_energy", base, .18)

func calm_curtains() -> void:
	curtain_left.transform = original.curtain_left
	curtain_right.transform = original.curtain_right
	bed_curtain_left.transform = original.bed_curtain_left
	bed_curtain_right.transform = original.bed_curtain_right
	for index in range(room_lights.size()):
		if is_instance_valid(room_lights[index]):
			room_lights[index].light_energy = room_light_energy[index]

# --------------------------------------------------------------- действия ---

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
	# Письмо отдаётся только той вещи, до которой цепочка дошла. Осмотр не по
	# порядку показывает обычное описание и НЕ двигает цепочку: иначе игрок,
	# который щёлкает по всему подряд, проскочил бы половину переписки.
	if act == Act.LETTERS and letter_step < LETTER_CHAIN.size() \
			and id == LETTER_CHAIN[letter_step]:
		reveal_letter(id)
	inspect.open(id, interactor.entry(id))
	interactor.mark_seen(id)

func reveal_letter(id: String) -> void:
	var index := letter_step
	letter_step += 1
	interactor.set_text(id, str(LETTER_TEXTS[index]))
	clock.advance(6.0, "letter")
	cue.play("paper")
	if letter_step >= LETTER_CHAIN.size():
		# Последнее письмо само называет глагол финала: отдать связку ветру.
		# Среда учит действию, а не экран с заданием.
		enter_hold()
		return
	hud.show_message("Письмо %d из %d." % [letter_step, LETTER_CHAIN.size()], 3.0)
	focus_next_letter()

func focus_next_letter() -> void:
	if letter_step >= LETTER_CHAIN.size():
		hints.clear_focus()
		return
	var id: String = LETTER_CHAIN[letter_step]
	var zone := interactor.zone(id)
	var point := zone.global_position if zone else Vector3.ZERO
	hints.set_focus(point, [
		"В письме сказано, где следующее.",
		"Перечитай последнее письмо — место названо прямо в нём.",
		"Следующее письмо здесь: %s. Наведись и нажми ЛКМ." % str(interactor.entry(id).get("title", id))])
	hints.reset_timer()

func on_used(id: String) -> void:
	if inspect.active or code_lock.active:
		return
	# Фрамуга меняет смысл по акту: в первом её закрывают, в третьем — снова
	# открывают, чтобы отдать письма ветру. Без этой развилки финал упирался бы
	# в «здесь уже закрыто» и вставал намертво.
	if id == "transom" and act == Act.HOLD:
		release_letters()
		return
	match id:
		"vent", "window_living", "window_bed", "transom": close_source(id)
		"c2_suitcase": use_suitcase()
		"c2_letters":
			if act == Act.HOLD:
				take_bundle()
			else:
				hud.show_message("Связка перехвачена лентой. Читать — ЛКМ.", 2.8)
		_:
			if id.begins_with("switch_"):
				toggle_switch(id)
				return
			if ROOM_ZONES.has(id):
				use_room_zone(id)
				return
			# Отклик зависит от акта: в тишине второго акта ветра нет и говорить
			# про него нельзя.
			match act:
				Act.GALE: hud.show_message("Ветер вырывает это из рук.", 2.4)
				Act.LETTERS: hud.show_message("Это можно только рассмотреть — ЛКМ.", 2.6)
				_: cue.play("latch", -14.0)

# Выключатели гасят только тёплый свет: лунная заливка остаётся, и в темноте
# номер по-прежнему проходим. Гасить свет в этом круге не требуется ни для чего —
# это возня, за которую стрелка даёт полсекунды один раз.
#
# В темноте ураган читается сильнее: мигать становится нечему, и остаются только
# шторы. Это осознанный побочный эффект, а не недосмотр.
# toggle_switch/lights_of/use_room_zone/reward — общие для всех кругов, теперь
# в CircleLevel.

func use_suitcase() -> void:
	if catch_taken:
		hud.show_message("Чемодан заперт наглухо. Под ним больше ничего нет.", 3.0)
		return
	catch_taken = true
	catch_prop.visible = true
	interactor.set_text("c2_suitcase",
		"Не твой. Ты сдвинул его — под ним лежал латунный шпингалет.")
	inventory.add("catch", "шпингалет", catch_prop,
		"Латунный шпингалет со сорванным винтом.",
		"На обороте выбито: 1604")
	announce_pickup("catch", "Под чемоданом — шпингалет для фрамуги.")
	reward("c2_suitcase")

# Подобранный предмет бесполезен, пока игрок не знает, что его можно достать:
# осмотр вещи из инвентаря — это ЛКМ в пустоту, и об этом не говорит ничто.
func announce_pickup(id: String, headline: String) -> void:
	var slot := inventory.slot_of(id)
	if slot < 1:
		hud.show_message(headline, 3.0)
		return
	hud.show_message("%s\nСлот %d. Нажми %d, потом ЛКМ в пустоту — рассмотришь."
		% [headline, slot, slot], 4.6)

func close_source(id: String) -> void:
	if closed.has(id):
		hud.show_message("Здесь уже закрыто.", 2.2)
		return
	# Фрамуга — последний источник и единственный, которому нужен предмет в руке.
	# Ровно тот же глагол, что открывал дверь 1604 в прологе первого круга.
	if id == "transom" and inventory.selected() != "catch":
		if inventory.has("catch"):
			hud.show_message("Шпингалет в кармане, а не в руке. Нажми %d."
				% inventory.slot_of("catch"), 3.2)
		else:
			hud.show_message("Шпингалет сорван. Поищи его под чужим чемоданом.", 3.6)
			hints.set_focus(Vector3(1.95, .30, -.55), [
				"Фрамуга видна, но запереть её пока нечем.",
				"Сорванный шпингалет должен быть где-то в комнате.",
				"Сдвинь чужой чемодан у кровати: наведи прицел и нажми E."])
			hints.reset_timer()
		return
	closed[id] = true
	if id == "transom":
		inventory.remove("catch")
		set_transom_open(false)
	interactor.set_usable(id, false)
	interactor.set_text(id, "Закрыто. Отсюда больше не тянет.")
	clock.advance(9.0, "source")
	cue.play("latch")
	var left := SOURCE_IDS.size() - closed.size()
	if left > 0:
		hud.show_message("Стало тише. Открыто ещё %d." % left, 3.0)
		focus_next_source()
		return
	calm_room()

func calm_room() -> void:
	act = Act.LETTERS
	calm_curtains()
	hud.show_message("Ветер стих. Впервые слышно, как тихо в номере.", 4.0)
	# Потолок второго акта: минута не должна добежать раньше развязки.
	clock.ceiling = 52.0
	clock.set_pressure(true)
	letter_step = 0
	focus_next_letter()

# Акт III. Прочитано всё, и комната начинает возвращать свои вещи на место,
# стоит отвести взгляд. Ветер возвращается вполсилы.
func enter_hold() -> void:
	act = Act.HOLD
	clock.ceiling = ClockDirector.SPAN
	wind_time = 0.0
	interactor.set_usable("transom", true)
	interactor.set_text("transom",
		"Фрамуга закрыта твоими руками. Возьми связку писем с тумбочки, затем открой фрамугу со связкой в руке — отдай письма ветру.")
	interactor.set_usable("c2_letters", true)
	anomalies.arm_all(HOLD_ANOMALIES)
	hud.show_message("Ветер вернулся. Комната ставит свои вещи обратно, стоит отвернуться.", 4.6)
	hints.set_focus(Vector3(2.42, .62, -2.62), [
		"В последнем письме сказано, что делать.",
		"Письма надо забрать все и отдать ветру.",
		"Возьми связку писем (E на тумбочке), потом открой фрамугу над входной дверью."])
	hints.reset_timer()

func take_bundle() -> void:
	if bundle_taken:
		hud.show_message("Связка уже в руках.", 2.2)
		return
	bundle_taken = true
	bundle_prop.visible = false
	inventory.add("bundle", "связка писем", bundle_prop,
		"Чужая переписка, перехваченная лентой.",
		"На ленте выцветшая метка прачечной: 1604")
	announce_pickup("bundle", "Связка писем у тебя в руках.")
	hints.set_focus(Vector3(-2.65, 2.24, -2.86), [
		"Осталось одно место, куда их можно отдать.",
		"Фрамуга над входной дверью — ты сам её закрыл.",
		"Возьми связку клавишей %d и нажми E на фрамуге." % maxi(inventory.slot_of("bundle"), 1)])
	hints.reset_timer()

# Развязка круга: открыть то, что закрывал весь первый акт, и отдать письма.
func release_letters() -> void:
	if released:
		return
	if inventory.selected() != "bundle":
		if inventory.has("bundle"):
			hud.show_message("Связка в кармане, а не в руке. Нажми %d."
				% inventory.slot_of("bundle"), 3.2)
		else:
			# Нажатие без связки ничего не открывает. Прежний текст утверждал обратное,
			# хотя створка оставалась закрытой, и игрок закономерно не понимал, что
			# именно от него требуется для финала.
			hud.show_message("Сначала забери связку писем с тумбочки. Потом возьми её в руку и открой фрамугу.", 4.4)
			interactor.set_text("transom",
				"Фрамуга закрыта. Сначала возьми связку писем с тумбочки, затем открой её со связкой в руке.")
			hints.set_focus(Vector3(2.42, .62, -2.62), [
				"Ветер ждёт не пустых рук.",
				"Сначала нужна связка писем с тумбочки.",
				"Возьми связку клавишей E, выбери её слот и вернись к фрамуге."])
			hints.reset_timer()
		return
	released = true
	inventory.remove("bundle")
	closed.erase("transom")
	set_transom_open(true)
	interactor.set_usable("transom", false)
	interactor.set_text("transom", "Фрамуга откинута. Писем за ней уже нет.")
	anomalies.clear()
	hints.set_enabled(false)
	cue.play("wipe")
	# Пол должен очиститься вместе со связкой: сообщение обещает «всё до
	# последнего листа», и оставшиеся на полу бумаги делали его неправдой.
	letters.visible = false
	hud.show_message("Ты разжал руку. Ветер забрал всё до последнего листа.", 4.6)
	clock.run_out(6.0)

func on_minute_reached() -> void:
	act = Act.COMPLETE
	clock_display.text = "16:06:00"
	calm_curtains()
	hud.show_message("КРУГ II — УРАГАН\nпройден", 4.0)

func focus_next_source() -> void:
	for id in SOURCE_IDS:
		if closed.has(id):
			continue
		var points := {
			"vent": Vector3(-4.10, 1.94, 1.90),
			"window_living": Vector3(.80, 1.45, 5.16),
			"window_bed": Vector3(3.86, 1.45, -1.10),
			"transom": Vector3(-2.65, 2.24, -2.86)
		}
		var direct := "Осталось закрыть: %s. Нажми E." % SOURCE_NAMES[id]
		if id == "transom":
			if inventory.has("catch"):
				direct = "Выбери шпингалет клавишей %d и нажми E на фрамуге." \
					% maxi(inventory.slot_of("catch"), 1)
			else:
				direct = "Для фрамуги нужен сорванный шпингалет. Сдвинь чужой чемодан у кровати клавишей E."
		hints.set_focus(points[id], [
			"Ветер идёт откуда-то ещё.",
			"В номере открыто ещё %d места. Найди, откуда тянет." % (SOURCE_IDS.size() - closed.size()),
			direct])
		hints.reset_timer()
		return
	hints.clear_focus()

# reward() — общая для всех кругов, теперь в CircleLevel.

# Цель прямым текстом: клавиша H обязана отвечать всегда, иначе читается как
# сломанная. Номер слота берётся из инвентаря, а не выдумывается.
func current_goal() -> String:
	match act:
		Act.GALE:
			var left: Array[String] = []
			for id in SOURCE_IDS:
				if not closed.has(id):
					left.append(str(SOURCE_NAMES[id]))
			if left.size() == 1 and left[0] == SOURCE_NAMES["transom"]:
				if inventory.has("catch"):
					return "Осталась фрамуга над входной дверью. Возьми шпингалет клавишей %d и нажми E." \
						% maxi(inventory.slot_of("catch"), 1)
				return "Осталась фрамуга над входной дверью. Шпингалет сорван — сдвинь чужой чемодан у кровати."
			return "Ветер не даёт ничего сделать. Закрой источники сквозняка — осталось %d: %s." \
				% [left.size(), ", ".join(left)]
		Act.LETTERS:
			if letter_step >= LETTER_CHAIN.size():
				return "Все письма прочитаны."
			var next_id: String = LETTER_CHAIN[letter_step]
			var title := str(interactor.entry(next_id).get("title", next_id))
			return "Прочитано писем: %d из %d. Следующее спрятано здесь: %s — наведись и нажми ЛКМ." \
				% [letter_step, LETTER_CHAIN.size(), title]
		Act.HOLD:
			if released:
				return "Письма отданы. Минута добегает сама."
			if inventory.has("bundle"):
				return "Открой фрамугу над входной дверью: возьми связку клавишей %d и нажми E." \
					% maxi(inventory.slot_of("bundle"), 1)
			return "Забери связку писем с тумбочки (E) и отдай её ветру — открой фрамугу над входной дверью."
		Act.COMPLETE:
			return "Круг II пройден."
	return "Оглядись."

# ------------------------------------------------------------------ сброс ---

func full_reset() -> void:
	epoch += 1
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	act = Act.GALE
	closed.clear()
	rewarded.clear()
	quiet_said.clear()
	catch_taken = false
	letter_step = 0
	bundle_taken = false
	released = false
	bundle_prop.visible = true
	dress_prop.position = Vector3(-.70, 1.86, -.15)
	suitcase_prop.rotation.y = .28
	wind_time = 0.0
	flicker_at = 0.0
	letters_shuffled_at = 0.0
	catch_prop.visible = false
	player.transform = original.player
	player.global_position = Vector3(1.25, .05, .15)
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	lock_entrance_door()
	set_transom_open(true, 0.0)
	hide_circle_one_things()
	calm_curtains()
	interactor.clear()
	interactor.set_locked(false)
	inventory.clear()
	inspect.close()
	code_lock.close()
	anomalies.clear()
	hints.clear()
	hud.reset()
	clock.reset()
	clock.start_label = "16:05"
	clock.end_label = "16:06"
	clock.refresh()
	clock.start()
	# Потолок акта: мелкие награды за возню с чужими вещами не должны довести
	# минуту раньше, чем игрок уймёт ветер.
	clock.ceiling = 44.0
	if letters:
		letters.visible = true
		scatter_letters(true)
	hints.set_enabled(true)
	focus_next_source()

# The sash is a real part of the shared doorway, not only an interaction zone.
# Open means its lower edge is tilted into the room; closed returns it flush.
func set_transom_open(open: bool, duration: float = .45) -> void:
	if not entrance_transom:
		return
	var target := -.42 if open else 0.0
	if duration <= 0.0:
		entrance_transom.rotation.x = target
	else:
		create_tween().tween_property(entrance_transom, "rotation:x", target, duration) \
			.set_trans(Tween.TRANS_SINE)

# Убрать из номера часть обстановки Круга I. Зона гасится вместе с предметом:
# иначе прицел золотится над пустым местом, а check_reachable() падает на зоне,
# которую больше нечем перекрыть.
func hide_circle_one_things() -> void:
	var root := get_parent()
	for node_name in HIDDEN_NODES:
		var node := root.find_child(node_name, true, false) as Node3D
		if not node:
			continue
		hidden_originals[node_name] = node.visible
		node.visible = false

# ------------------------------------------------------------------ аудит ---

func run_audit() -> void:
	await get_tree().physics_frame
	# Одиннадцать сюжетных зон плюс обстановка. Число закреплено намеренно: пустая
	# комната во втором круге была настоящей недоделкой, и проверка не даст её
	# вернуть незаметно.
	var expected := 11 + ROOM_ZONES.size() + 4
	if not require(interactor.targets.size() == expected,
			"unexpected zone count: %d, expected %d" % [interactor.targets.size(), expected]): return
	# Обстановка обязана отвечать на E и при этом не обещать золотого [E].
	for id in ROOM_ZONES:
		if not require(interactor.entry(str(id))["usable"], "room zone is not usable: %s" % id): return
		if not require(interactor.prompt_state(str(id)) == Hud.Aim.EXAMINE,
				"room zone promises [E]: %s" % id): return
	for id in SOURCE_IDS:
		if not require(interactor.targets.has(id), "missing draught source: %s" % id): return
	if not require(entrance_transom != null, "visible entrance transom is missing"): return
	if not require(is_equal_approx(entrance_transom.rotation.x, -.42),
			"transom did not start visibly open"): return
	if not require(str(interactor.entry("transom")["text"]).contains("надо закрыть"),
			"transom examination does not explain the first action"): return
	# В кругах II–IX эти две проверки велено гонять с самой первой зоны: аудит,
	# дёргающий функции уровня напрямую, поломок наведения не видит вовсе.
	if not check_no_overlap(): return
	if not check_props_placed([]): return
	if not check_reachable(reach_origins()): return
	if not check_actions_bound(SOURCE_IDS + ["c2_suitcase", "c2_letters"]): return
	if not require(message_on_screen(), "message sits off screen"): return

	# Вещи Круга I должны исчезнуть вместе со своими зонами.
	var root := get_parent()
	for node_name in HIDDEN_NODES:
		var node := root.find_child(node_name, true, false) as Node3D
		if node and not require(not node.visible, "circle I prop still visible: %s" % node_name): return

	if not require(act == Act.GALE, "circle II did not start in the gale"): return
	if not require(current_goal().contains("сквозняка"), "H says nothing useful in act I"): return
	# Разлетевшиеся письма — главный видимый признак урагана, кроме штор.
	if not require(letters and letters.multimesh.instance_count == 14,
			"scattered letters were not built"): return
	# Проверяем letter_home — собственную запись уровня о том, куда он разложил
	# письма, а не читаем обратно из MultiMesh: в headless буфер живёт в сервере
	# отрисовки, которого нет, и get_instance_transform() возвращает единичную
	# матрицу для всех экземпляров. Тот же класс ловушки, что get_global_rect()
	# у Control. Что письма действительно видны на полу, показывает кадр прогона.
	if not require(letter_home.size() == 14, "letter positions were not recorded: %d" % letter_home.size()): return
	for home in letter_home:
		var spot := home.origin
		if not require(spot.y > 0.0 and absf(spot.x) < 5.0 and absf(spot.z) < 6.0,
				"a letter landed outside the room at %s" % spot): return
	request_hint()
	await shot("c2_gale", Vector3(1.25, .05, 2.65), PI, -.30)

	# Ветер обязан быть виден: без звука это единственный его признак. Проверяем
	# фактический сдвиг шторы, а не то, что функция позвалась.
	var before := curtain_left.position.x
	wind_time = 0.58
	blow_curtains(1.0)
	if not require(not is_equal_approx(curtain_left.position.x, before), "wind does not move the curtains"): return

	# Сначала фрамуга с пустыми руками — так и пойдёт живой игрок, который дошёл
	# до неё раньше, чем сдвинул чемодан. Проверять «выбран другой предмет» смысла
	# нет: носимый предмет в круге один, и он всегда выбран, а deselect инвентарь
	# не умеет. Достижимое состояние — «шпингалета нет вовсе».
	on_used("transom")
	if not require(not closed.has("transom"), "transom closed without the catch"): return
	if not require(current_goal().contains("сквозняка"), "H lost the goal at the transom"): return
	if not require(hud.message.text.contains("чемоданом"),
			"empty-handed transom attempt does not point at the suitcase"): return
	await shot("c2_transom_open", Vector3(-2.65, .05, -1.55), 0.0, -.30)

	# Шпингалет лежит под чемоданом и до этого невидим.
	if not require(not catch_prop.visible, "window catch was visible before the suitcase"): return
	on_used("c2_suitcase")
	if not require(inventory.has("catch"), "suitcase did not yield the catch"): return
	if not require(catch_prop.visible, "window catch stayed hidden"): return
	if not require(hud.message.text.contains("для фрамуги"),
			"catch pickup does not explain what the item is for"): return
	# Точка съёмки взята с проходимого маршрута bedroom_window: shot() ставит
	# игрока без проверки коллизий, и произвольная точка легко оказывается внутри
	# стены — первый кадр вышел ровно таким, однородно-коричневым.
	await shot("c2_suitcase", Vector3(2.70, .05, -.10), 1.04, -1.00)

	# Фрамуга — последний источник и единственный с предметом в руке. Порядок здесь
	# игроцкий: сначала три простых, потом та, что требует шпингалета.
	for id in ["vent", "window_living", "window_bed"]:
		on_used(id)
		if not require(closed.has(id), "source did not close: %s" % id): return
	if not require(act == Act.GALE, "gale ended before the last source"): return
	if not require(current_goal().contains("фрамуга"), "H does not point at the transom"): return

	inventory.select_by_id("catch")
	if not require(inventory.selected() == "catch", "catch is not the selected item"): return
	on_used("transom")
	if not require(closed.has("transom"), "transom did not close with the catch"): return
	if not require(not inventory.has("catch"), "catch stayed in the inventory"): return
	if not require(act == Act.LETTERS, "closing all four sources did not calm the room"): return
	await get_tree().create_timer(.5).timeout
	if not require(is_zero_approx(entrance_transom.rotation.x),
			"transom sash did not visibly close"): return
	await shot("c2_transom_closed", Vector3(-2.65, .05, -1.55), 0.0, -.30)
	# Улёгшиеся шторы обязаны вернуться точно на место, а не «примерно».
	if not require(curtain_left.transform.is_equal_approx(original.curtain_left),
			"curtains did not settle back"): return
	# Тот же ракурс, что у кадра урагана: разницу видно только при сравнении.
	await shot("c2_calm", Vector3(1.25, .05, 2.65), PI, -.30)

	# --- Акт II: цепочка писем ---
	if not require(letter_step == 0, "letter chain started before act II"): return
	# Осмотр не по порядку не должен двигать цепочку. Так и пойдёт живой игрок,
	# который щёлкает по всему подряд: если чемодан отдаст последнее письмо
	# первым, половина переписки пропадёт молча.
	on_examined("c2_suitcase")
	inspect.close()
	if not require(letter_step == 0, "out-of-order examine advanced the letter chain"): return

	# Обстановка обязана отвечать делом, а не молчанием. Проверяем на представителе:
	# отклик доходит и до строки сообщений, и до описания самой вещи.
	on_used("sofa")
	if not require(quiet_said.has("sofa"), "room zone did not answer E"): return
	if not require(interactor.entry("sofa")["text"].contains("вмятины"),
			"room answer never reached the item description"): return

	# Выключатели обязаны гасить свет по-настоящему, а не только писать об этом.
	var lit := lights_of("switch_bedroom")
	if not require(not lit.is_empty(), "switch_bedroom controls no lights"): return
	if not require(lit[0].visible, "bedroom light was already off"): return
	on_used("switch_bedroom")
	if not require(not lit[0].visible, "the switch did not turn the light off"): return
	if not require(interactor.prompt_state("switch_bedroom") == Hud.Aim.USE,
			"switch does not promise [E]"): return
	on_used("switch_bedroom")
	if not require(lit[0].visible, "the switch did not turn the light back on"): return

	for index in range(LETTER_CHAIN.size()):
		var id: String = LETTER_CHAIN[index]
		if not require(letter_step == index, "letter chain out of step at %s" % id): return
		on_examined(id)
		if not require(letter_step == index + 1, "letter did not advance at %s" % id): return
		# Текст письма обязан оказаться в самом предмете: игрок читает его в
		# режиме осмотра, а не в строке сообщений.
		if not require(interactor.entry(id)["text"] == LETTER_TEXTS[index],
				"letter text never reached the item %s" % id): return
		inspect.close()
		if index == 1:
			await shot("c2_letter", Vector3(1.25, .05, -1.60), 0.0, -.82)
	if not require(act == Act.HOLD, "reading all letters did not start act III"): return

	# --- Акт III: комната не отпускает ---
	# Отвернуться в headless нельзя, поэтому аномалии применяем принудительно и
	# проверяем, что вещь действительно сдвинулась.
	var dress_before := dress_prop.position.z
	var case_before := suitcase_prop.rotation.y
	anomalies.force("hold_dress")
	anomalies.force("hold_case")
	if not require(not is_equal_approx(dress_prop.position.z, dress_before),
			"act III did not move the dress"): return
	if not require(not is_equal_approx(suitcase_prop.rotation.y, case_before),
			"act III did not move the suitcase"): return
	await shot("c2_hold", Vector3(1.25, .05, .15), 0.0, -.10)

	# Фрамуга без связки в руках отдавать нечего, но и вставать не должна.
	var transom_before_empty_use := entrance_transom.rotation.x
	on_used("transom")
	if not require(not released, "letters were released with empty hands"): return
	if not require(is_equal_approx(entrance_transom.rotation.x, transom_before_empty_use),
			"empty-handed final attempt opened the transom"): return
	if not require(hud.message.text.contains("Сначала забери связку"),
			"empty-handed final attempt does not point at the letter bundle"): return
	on_used("c2_letters")
	if not require(inventory.has("bundle"), "the bundle was not taken"): return
	if not require(not bundle_prop.visible, "the bundle stayed on the table"): return
	if not require(current_goal().contains("фрамугу"), "H does not point at the transom in act III"): return
	inventory.select_by_id("bundle")
	on_used("transom")
	if not require(released, "the transom did not release the letters"): return
	if not require(not inventory.has("bundle"), "the bundle stayed in the inventory"): return
	await get_tree().create_timer(.5).timeout
	if not require(is_equal_approx(entrance_transom.rotation.x, -.42),
			"transom sash did not visibly reopen"): return
	if not require(anomalies.applied_count(HOLD_ANOMALIES) == 0,
			"act III anomalies survived the release"): return
	# Сообщение обещает, что ветер забрал всё: пол обязан очиститься.
	if not require(not letters.visible, "scattered letters survived the release"): return

	var guard := 0
	while act != Act.COMPLETE and guard < 200:
		await get_tree().create_timer(.1).timeout
		guard += 1
	if not require(act == Act.COMPLETE, "clock never reached 16:06"): return
	if not require(clock_display.text == "16:06:00", "clock shows %s" % clock_display.text): return
	await shot("c2_complete")

	full_reset()
	if not require(act == Act.GALE and closed.is_empty(), "full_reset did not clean up"): return
	if not require(not catch_prop.visible, "full_reset left the catch visible"): return
	if not require(clock.value == 0.0, "full_reset did not rewind the clock"): return
	if not require(letter_step == 0 and not released, "full_reset kept the letters read"): return
	if not require(bundle_prop.visible and letters.visible, "full_reset left the letters gone"): return
	if not require(is_equal_approx(dress_prop.position.z, -.15),
			"full_reset left the dress moved"): return

	print("LUST_AUDIT_OK circle II: %d zones, %d sources, %d letters, clock 16:05->16:06"
		% [interactor.targets.size(), SOURCE_IDS.size(), LETTER_CHAIN.size()])
	prepare_shutdown()
	await get_tree().create_timer(.35).timeout
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if (event as InputEventKey).keycode == KEY_H:
		get_viewport().set_input_as_handled()
		request_hint()
