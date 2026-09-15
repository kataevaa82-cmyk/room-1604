extends CircleLevel

# КРУГ I — «ЛИМБ». Комната 1604.
#
# Общее для всех кругов — в CircleLevel: ссылки на части номера, сборка систем,
# клавиша H и весь инструментарий аудита. Здесь только содержание первого круга.
#
# Правила круга, выбранные для этой переделки:
#   * никто не ведёт игрока — ни диктор, ни экран с заданиями;
#   * умереть нельзя, наказать игрока нельзя, отнять решённое нельзя;
#   * единственный явный индикатор — часы: 16:04:00 -> 16:05:00.
#
# Акт I  — обжиться и запомнить комнату (внимание двигает стрелку).
# Акт II — четыре независимые задачи в любом порядке.
# Акт III — комната ломается, игрок возвращает её по памяти. Без подсветки.

enum Act { PROLOGUE, INTRO, WATCHING, RESTORE, LEAVING, COMPLETE }

# Пролог: игрок стоит в коридоре шестнадцатого этажа и ещё не входил в номер.
# Он же учит глаголу, который потом ломает игроков, — «достать вещь из слота и
# приложить её к предмету»: карта-ключ открывает 1604 ровно так же, как позже
# заводной ключ заводит часы.
const CORRIDOR_SPAWN := Vector3(1.2, .05, -4.55)
const CORRIDOR_YAW := 1.93
# The trigger sits safely inside the room, not on the doorway plane. This gives
# the player enough clearance to pass the moving leaf before its collision is
# restored and it closes behind them.
const ROOM_THRESHOLD_Z := -2.55

const RESTORE_IDS := ["chair", "wardrobe", "painting", "phone", "pillow"]
const TASK_IDS := ["dark", "water", "peephole", "safe"]
# Человеческие названия задач — нужны клавише H, когда она называет цель прямо.
const TASK_NAMES := {
	"dark": "погасить весь свет и рассмотреть стену у кровати",
	"water": "открыть кран в ванной",
	"peephole": "посмотреть в глазок",
	"safe": "открыть сейф в шкафу"
}
const AWAKE_TARGET := 5
const SECONDS_PER_LOOK := 1.0
const SECONDS_PER_TASK := 8.0
const SECONDS_PER_RESTORE := 4.0
const BREAK_PENALTY := 5.0

# «Тихие» отклики: E работает, золотого [E] нет. Нужны затем, чтобы на попытку
# тронуть обстановку комната отвечала, а не молчала — но чтобы прицел при этом не
# размечал все семь десятков зон. Осмотренный текст предмета дополняется тем, что
# игрок с ним сделал, поэтому вещь помнит обращение.
#
# Сюда НЕЛЬЗЯ добавлять предметы из RESTORE_IDS: в третьем акте их возвращают на
# место, и лишний отклик перехватил бы возврат.
const QUIET_USE := {
	# прихожая
	"entry_rug": "Ты отогнул угол коврика. Под ним сухой пол и ни одной пылинки.",
	"hall_plant": "Лист поддался и остался в руке. На срезе он сухой насквозь.",
	"hall_outlet": "Гнездо пустое. Пальцем чувствуется только тёплая пыль.",
	# спальня
	"radiator_bed": "Вентиль провернулся до упора. В секциях не щёлкнуло и не потеплело.",
	"bed_outlet": "И это гнездо пустое. Светлый прямоугольник рядом — точно от лампы.",
	# ванная
	"towels": "Ты разворошил стопку. Все полотенца сухие, кроме верхнего.",
	"hand_towel": "Полотенце качнулось на кольце и вернулось ровно как было.",
	"wastebasket": "Ты заглянул внутрь. Даже пыли на дне нет.",
	"toilet_paper": "Рулон провернулся со щелчком. Обрыв ровный, как по линейке.",
	# гостиная
	"sofa": "Ты продавил подушку рукой. Вмятина осталась рядом с чужой.",
	"coffee_table": "Ты провёл пальцем по кольцу от стакана. Лак под ним матовый.",
	"living_armchair": "Кресло качнулось и осталось смотреть в окно.",
	"living_mirror": "Ты повернул зеркало. Угол, который в нём виден, не меняется.",
	"living_painting": "Рама качнулась. Горящее окно на картине осталось гореть.",
	"desk_chair": "Стул отъехал и остановился. Садиться некому.",
	"radiator_living": "Тот же холод и тот же свободный вентиль.",
	# коридор
	"corr_plate": "Латунь под пальцем тёплая. Цифры вдавлены глубоко.",
	"corr_sign": "Ты потрогал стёртую стрелку. Под краской ничего не прощупывается.",
	"corr_notice": "Стекло не поднимается. Приписку про часы читать приходится через него.",
	"corr_window": "Стекло не открывается и не холодеет от дыхания.",
	"corr_plant": "Земля в кадке твёрдая. Лист хрустнул под пальцами.",
	"corr_luggage": "Тележка не катится: колёса заклинило. Ремень на чемодане затянут наглухо.",
	"corr_tray": "Ты приподнял колпак. Под ним остывший ужин, к которому не притронулись."
}

@export var debug_limbo := false

var act := Act.PROLOGUE
var skip_prologue := false
var corridor_root: Node3D
var door_unlocked := false
var entered_room := false
var looked := {}
var awake_progress := 0
var tasks_done := {}
var restored := {}
var known_digits := {}
var door_attempts := 0
var door_open := false
var exit_started := false
var peephole_stage := 0
var faucet_on := false
var wardrobe_open := false
var safe_open := false
var lights_out := false
var mirror_fogged := false
var broken := false
var key_inserted := false
var tv_channel := 0
var phone_ringing := false
var phone_calls := 0
var final_running := false
var final_timer := 0.0

# Рантайм-пропы Круга I. Узлы самой комнаты, часы и лампы объявлены в CircleLevel.
var mirror_text: Label3D
var mirror_fog: MeshInstance3D
var mirror_fog_material: StandardMaterial3D
var tv_static: MeshInstance3D
var tv_text: Label3D
var phone_light: OmniLight3D
var wall_trace: Label3D
var key_prop: Node3D
var note_prop: Node3D
var card_prop: Node3D
var pillow_prop: Node3D
var handset_prop: Node3D
var phone_base_proxy: Node3D
var wardrobe_proxy: Node3D
var wardrobe_door: Node3D
var safe_prop: Node3D
var safe_light: OmniLight3D
var door_handle_lever: Node3D
var exit_darkness: MeshInstance3D
var containers := {}
# Четыре взаимодействия с последствиями: каждое срабатывает один раз за круг.
var writing_rubbed := false
var books_opened := false
var cups_turned := false
var painting_lifted := false

func _ready() -> void:
	name = "LimboLevel"
	player = get_parent().get_node("Player")
	camera = player.get_node("Head/Camera3D")
	world_environment = get_parent().get_node_or_null("Environment")
	# Скриншотные пресеты ставят камеру внутри номера. Пролог для них выключен,
	# иначе full_reset() утащил бы игрока обратно в коридор и все 35 ракурсов
	# ROOM1408_VIEW сломались бы разом.
	skip_prologue = not OS.get_environment("ROOM1408_VIEW").is_empty()
	cache_room()
	build_systems()
	build_props()
	register_targets()
	register_corridor()
	# Одним проходом после всех регистраций: зоны объявлены в трёх разных местах
	# (обстановка номера, коридор, ключевые предметы), и разводить тихий отклик по
	# всем трём — верный способ забыть про одно из них.
	for id in QUIET_USE:
		interactor.make_quiet(str(id))
	wire_signals()
	full_reset()
	if OS.has_environment("LIMBO_EXPORT_AUDIT"):
		await get_tree().process_frame
		run_export_audit()
	elif OS.has_environment("LIMBO_AUDIT"):
		await get_tree().process_frame
		run_audit()
	elif OS.has_environment("LIMBO_WALKTHROUGH"):
		# Тот же самый прогон круга, что и в аудите, но с картинкой: на каждом
		# рубеже сохраняется кадр. Именно один и тот же — иметь две копии
		# последовательности значит гарантированно их разойти, а порядок шагов в
		# этом проекте уже один раз оказался неигроцким и спрятал софтлок.
		begin_walkthrough(OS.get_environment("LIMBO_WALKTHROUGH"))
		await get_tree().process_frame
		run_audit()
	elif OS.has_environment("LIMBO_QA"):
		# Снимок конкретного экрана для визуальной проверки: LIMBO_QA=card
		# открывает режим осмотра карточки, LIMBO_QA=safe — кодовый замок.
		var qa := OS.get_environment("LIMBO_QA")
		if qa == "safe":
			code_lock.open()
		elif qa == "wardrobe_open":
			use_wardrobe()
		elif interactor.targets.has(qa):
			inspect.open(qa, interactor.entry(qa))
	else:
		hud.show_message("ЛИМБ\nШестнадцатый этаж" if act == Act.PROLOGUE else "ЛИМБ\nКомната 1604", 3.2)
		show_controls()

func show_controls() -> void:
	var mark := epoch
	await get_tree().create_timer(4.2).timeout
	if mark != epoch:
		return
	hud.show_message("WASD — идти   ·   ЛКМ — рассмотреть   ·   E — тронуть   ·   H — подсказка", 5.0)
	await get_tree().create_timer(5.4).timeout
	if mark != epoch or act != Act.PROLOGUE:
		return
	# Слоты и «ЛКМ в пустоту» — единственное, чему нельзя научиться самому.
	hud.show_message("1 2 3 4 — взять вещь из слота   ·   ЛКМ в пустоту — рассмотреть то, что в руке", 5.4)

func corridor() -> Node3D:
	# Коридор строится после build_limbo(), поэтому ищем его лениво.
	if not corridor_root:
		corridor_root = get_parent().get_node_or_null("Corridor")
	return corridor_root

# ---------------------------------------------------------------- комната ---


func build_props() -> void:
	clock_display = Build.label3d(self, "ClockDisplay", "16:04:00", Vector3(2.28, 1.74, .915), Vector3.ZERO, 30, .0032)
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

	mirror_text = Build.label3d(self, "MirrorMessage", "", Vector3(-4.12, 1.7, -.30), Vector3(0, PI / 2.0, 0), 30, .0025)
	mirror_text.modulate = Color(.20, .18, .16, 0.0)
	mirror_fog = Build.box(self, "MirrorFog", Vector3(-4.145, 1.69, -.30), Vector3(.012, .82, .68), Color(1, 1, 1, 0))
	mirror_fog_material = mirror_fog.material_override as StandardMaterial3D
	mirror_fog_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mirror_fog_material.albedo_color = Color(.82, .84, .80, 0.0)
	mirror_fog_material.roughness = 1.0

	tv_static = Build.box(self, "TelevisionStatic", Vector3(-1.725, 1.28, 3.15), Vector3(.012, .60, .98), Color("080a0c"))
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);} void fragment(){float n=hash(floor(UV*vec2(180.0,110.0))+floor(TIME*18.0)); float scan=step(.92,fract(UV.y*85.0-TIME*4.0)); vec3 c=vec3(.018+n*.10+scan*.035); ALBEDO=c; EMISSION=c*.35;}"
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	tv_static.material_override = shader_material
	tv_static.visible = false
	# Экран смотрит в +X, поэтому надпись на нём развёрнута на четверть оборота.
	tv_text = Build.label3d(self, "TelevisionCaption", "", Vector3(-1.70, 1.30, 3.15), Vector3(0, PI / 2.0, 0), 30, .0030)
	tv_text.modulate = Color(.78, .82, .80, .9)
	tv_text.outline_size = 0

	# Звонок телефона слышен быть не может: звук в круге выключен. Значит он
	# должен быть виден — аппарат подсвечивается импульсами.
	phone_light = OmniLight3D.new()
	phone_light.name = "PhoneRingLight"
	phone_light.position = Vector3(2.61, .88, -2.78)
	phone_light.light_color = Color("ffe2b0")
	phone_light.light_energy = 0.0
	phone_light.omni_range = 1.7
	phone_light.shadow_enabled = false
	add_child(phone_light)

	# След на стене спальни: виден только в полной темноте.
	wall_trace = Build.label3d(self, "WallTrace", "ТЫ УЖЕ БЫЛ ЗДЕСЬ", Vector3(2.25, 1.62, -3.02), Vector3.ZERO, 26, .0026)
	wall_trace.modulate = Color(.72, .68, .55, 0.0)
	wall_trace.outline_size = 0

	key_prop = Node3D.new()
	key_prop.name = "ClockKey"
	add_child(key_prop)
	Build.box(key_prop, "KeyStem", Vector3.ZERO, Vector3(.035, .035, .20), Color("b99555"))
	Build.torus(key_prop, "KeyRing", Vector3(0, 0, .11), .035, .055, Color("b99555"), Vector3(PI / 2.0, 0, 0))
	Build.box(key_prop, "KeyTag", Vector3(0, -.06, .11), Vector3(.07, .05, .008), Color("8d7a52"))
	key_prop.position = Vector3(-1.42, .62, -.15)
	key_prop.visible = false

	note_prop = Node3D.new()
	note_prop.name = "FoldedNote"
	add_child(note_prop)
	Build.box(note_prop, "Paper", Vector3.ZERO, Vector3(.14, .002, .10), Color("cabfa2"))
	note_prop.position = Vector3(1.25, .90, -2.42)
	note_prop.visible = false

	card_prop = Node3D.new()
	card_prop.name = "RoomCard"
	card_prop.position = Vector3(4.10, .795, 1.85)
	add_child(card_prop)
	Build.box(card_prop, "Card", Vector3.ZERO, Vector3(.22, .014, .14), Color("bba77e"))
	var card_face := Build.label3d(card_prop, "CardNumber", "1604", Vector3(0, .009, 0), Vector3(-PI / 2.0, 0, 0), 32, .0016)
	card_face.modulate = Color("32251b")
	var card_back := Build.label3d(card_prop, "CardCheckout", "ВЫЕЗД\n16:05", Vector3(0, -.009, 0), Vector3(PI / 2.0, 0, 0), 18, .00125)
	card_back.modulate = Color("32251b")

	pillow_prop = Node3D.new()
	pillow_prop.name = "LimboPillow"
	pillow_prop.position = Vector3(1.25, .93, -2.55)
	add_child(pillow_prop)
	var pillow_mesh := Build.sphere(pillow_prop, "Pillow", Vector3.ZERO, .5, Color("c9bea9"))
	pillow_mesh.scale = Vector3(.62, .16, .36)
	original.pillow = pillow_prop.transform

	wardrobe_proxy = Node3D.new()
	wardrobe_proxy.name = "WardrobeOpenProxy"
	add_child(wardrobe_proxy)
	Build.box(wardrobe_proxy, "CabinetBack", Vector3(-1.76, 1.05, -.15), Vector3(.05, 2.0, 1.1), Color("25150e"))
	Build.box(wardrobe_proxy, "CabinetTop", Vector3(-1.50, 2.04, -.15), Vector3(.55, .08, 1.1), Color("3d2417"))
	Build.box(wardrobe_proxy, "CabinetBottom", Vector3(-1.50, .06, -.15), Vector3(.55, .08, 1.1), Color("3d2417"))
	Build.box(wardrobe_proxy, "CabinetSideA", Vector3(-1.50, 1.05, -.68), Vector3(.55, 2.0, .06), Color("3d2417"))
	Build.box(wardrobe_proxy, "CabinetSideB", Vector3(-1.50, 1.05, .38), Vector3(.55, 2.0, .06), Color("3d2417"))
	wardrobe_door = Node3D.new()
	wardrobe_door.name = "WardrobeDoor"
	wardrobe_door.position = Vector3(-1.22, 1.12, -.68)
	wardrobe_proxy.add_child(wardrobe_door)
	Build.box(wardrobe_door, "DoorLeaf", Vector3(0, 0, .25), Vector3(.035, 1.75, .50), Color("3d2417"))
	original.wardrobe = wardrobe_door.transform
	wardrobe_proxy.visible = false

	safe_prop = Node3D.new()
	safe_prop.name = "WardrobeSafe"
	add_child(safe_prop)
	Build.box(safe_prop, "SafeBody", Vector3(-1.46, .62, -.15), Vector3(.34, .30, .40), Color("1a1a1c"))
	Build.box(safe_prop, "SafeDoor", Vector3(-1.28, .62, -.15), Vector3(.03, .26, .36), Color("242427"))
	var safe_digits := Build.label3d(safe_prop, "SafeDigits", "— — — —", Vector3(-1.26, .62, -.15), Vector3(0, -PI / 2.0, 0), 22, .0016)
	safe_digits.modulate = Color("c7b282")
	safe_digits.outline_size = 3
	safe_digits.outline_modulate = Color("17120d")
	safe_light = OmniLight3D.new()
	safe_light.name = "SafeInteriorLight"
	safe_light.position = Vector3(-1.08, .82, -.15)
	safe_light.light_color = Color("e3be79")
	safe_light.light_energy = 0.0
	safe_light.omni_range = 1.35
	safe_light.omni_attenuation = 1.65
	safe_light.shadow_enabled = false
	safe_prop.add_child(safe_light)
	safe_prop.visible = false

	phone_base_proxy = Node3D.new()
	phone_base_proxy.name = "PhoneBaseProxy"
	add_child(phone_base_proxy)
	Build.box(phone_base_proxy, "Base", Vector3(2.61, .64, -2.78), Vector3(.25, .12, .19), Color("10100f"))
	Build.torus(phone_base_proxy, "Dial", Vector3(2.61, .71, -2.72), .025, .055, Color("4c4438"), Vector3.ZERO)
	phone_base_proxy.visible = false

	handset_prop = Node3D.new()
	handset_prop.name = "PhoneHandset"
	handset_prop.position = Vector3(2.61, .77, -2.78)
	add_child(handset_prop)
	Build.capsule(handset_prop, "Receiver", Vector3.ZERO, .055, .30, Color("0b0b0a"), Vector3(0, 0, PI / 2.0))
	Build.sphere(handset_prop, "ReceiverLeft", Vector3(-.12, 0, 0), .075, Color("0b0b0a"))
	Build.sphere(handset_prop, "ReceiverRight", Vector3(.12, 0, 0), .075, Color("0b0b0a"))
	original.handset = handset_prop.transform
	handset_prop.visible = false

	door_handle_lever = Node3D.new()
	door_handle_lever.name = "DoorHandleLever"
	door_handle_lever.position = Vector3(.73, 1.08, .15)
	entrance_door.add_child(door_handle_lever)
	Build.box(door_handle_lever, "Lever", Vector3(-.055, 0, .025), Vector3(.18, .035, .035), Color("9a7038"))
	original.door_lever = door_handle_lever.transform

	exit_darkness = Build.box(self, "ExitDarkness", Vector3(-2.65, 1.15, -3.23), Vector3(.95, 2.3, .05), Color("000000"))
	exit_darkness.visible = false

	for i in range(2):
		var light := OmniLight3D.new()
		light.name = "BedsideLight%d" % i
		light.position = Vector3(0.0 if i == 0 else 2.37, 1.20, -2.82)
		light.light_color = Color("ffd09a")
		light.light_energy = .38
		light.omni_range = 2.2
		add_child(light)
		lamp_lights.append(light)

# ------------------------------------------------------------ что смотреть ---

func register_targets() -> void:
	# Осмотреть можно почти всё. Именно поэтому реакция прицела больше не
	# выдаёт решение: она значит «здесь есть что разглядывать», не более.
	# Дверь, глазок и табличка делят одну плоскость, поэтому зоны разведены по
	# высоте: ручка — внизу, глазок — на уровне глаз, табличка — над ним.
	# Иначе крупная зона двери перекрывает обе и они недостижимы лучом.
	interactor.register("door", Vector3(-2.65, .72, -2.88), Vector3(.8, 1.25, .35), {
		"title": "Входная дверь",
		"text": "Латунная ручка тёплая. Замок изнутри проворачивается вхолостую — механизм есть, но ему нечего открывать.",
		"usable": true})
	interactor.register("peephole", Vector3(-2.65, 1.58, -2.88), Vector3(.34, .30, .30), {
		"title": "Глазок",
		"text": "Стеклянная капля в двери.",
		"usable": true})
	interactor.register("plate", Vector3(-2.65, 1.92, -2.88), Vector3(.5, .28, .30), {
		"title": "Табличка",
		"text": "1604. Цифры привинчены намертво, латунь протёрта тысячей ладоней."})
	interactor.register("clock", Vector3(2.28, 1.72, .67), Vector3(1.0, 1.15, .38), {
		"title": "Настенные часы",
		"text": "Тёмный корпус, латунные кольца. Секундная стрелка стоит. Под циферблатом — квадратное гнездо под заводной ключ.",
		"usable": true})
	interactor.register("card", Vector3(4.10, .86, 1.85), Vector3(.40, .32, .40), {
		"title": "Карточка номера",
		"text": "Гостиничная карточка. На лицевой стороне тиснёное «1604».",
		"reverse": "На обороте: «ВЫЕЗД — 16:05».\nНиже, процарапано ногтем: 1",
		"prop": card_prop})
	interactor.register("painting", Vector3(1.25, 1.88, -2.94), Vector3(1.1, .8, .3), {
		"title": "Картина над кроватью",
		"text": "Озеро в золочёной раме. Вода на нём стоит совершенно ровно — ни ряби, ни ветра.",
		"reverse": "На подрамнике карандашом: 6",
		"prop": painting})
	interactor.register("phone", Vector3(2.68, .72, -2.75), Vector3(.32, .32, .38), {
		"title": "Телефон",
		"text": "Чёрный аппарат с диском. Гудка нет. В трубке — ровная тишина, будто линия обрывается в паре сантиметров от уха.",
		"prop": phone,
		"usable": true})
	interactor.register("bed", Vector3(1.25, .62, -2.10), Vector3(1.6, .7, 1.5), {
		"title": "Кровать",
		"text": "Постель заправлена по-гостиничному туго. Под подушкой что-то топорщится.",
		"usable": true})
	interactor.register("pillow", Vector3(1.85, .34, -.65), Vector3(.8, .65, .7), {
		"title": "Подушка",
		"text": "Она лежит на ковре.",
		"prop": pillow_prop})
	interactor.register("wardrobe", Vector3(-1.25, 1.05, -.15), Vector3(.45, 1.9, 1.1), {
		"title": "Шкаф",
		"text": "Тяжёлая дверца, латунная ручка. Внутри — гостиничный полумрак.",
		"usable": true})
	interactor.register("safe", Vector3(-1.46, .62, -.15), Vector3(.40, .36, .46), {
		"title": "Сейф",
		"text": "Маленький сейф в глубине шкафа. Четыре окошка под цифры.",
		"usable": true})
	interactor.register("chair", Vector3(3.44, .60, .15), Vector3(.78, 1.0, .78), {
		"title": "Кресло",
		"text": "Оливковое кресло у окна. Ткань на сиденье примята — кто-то сидел здесь долго."})
	interactor.register("mirror", Vector3(-4.05, 1.72, -.30), Vector3(.38, .95, .85), {
		"title": "Зеркало",
		"text": "Ты видишь в нём комнату. И себя — с небольшим опозданием.",
		"usable": true})
	interactor.register("faucet", Vector3(-3.93, .98, -.30), Vector3(.65, .45, .75), {
		"title": "Кран",
		"text": "Латунный смеситель. С носика набухает капля и не срывается.",
		"usable": true})
	interactor.register("tv", Vector3(-1.63, 1.25, 3.15), Vector3(.45, 1.0, 1.4), {
		"title": "Телевизор",
		"text": "Экран глухой. В нём отражается комната — но шторы в отражении задёрнуты.",
		"usable": true})
	interactor.register("curtains", Vector3(.8, 1.75, 5.25), Vector3(2.4, 1.6, .40), {
		"title": "Шторы",
		"text": "За стеклом ночь без единого огня. Ни машин, ни окон напротив, ни неба.",
		"usable": true})
	# Зона ящика стоит перед лицевой гранью стола: внутри его коллизии луч до
	# неё не доходит.
	interactor.register("desk", Vector3(3.60, .45, 2.02), Vector3(.20, .32, .40), {
		"title": "Ящик стола",
		"text": "Неглубокий ящик письменного стола. Ходит туго.",
		"usable": true})
	interactor.register("lamp_left", Vector3(0, 1.00, -2.85), Vector3(.34, .60, .34), {
		"title": "Лампа слева",
		"text": "Тканевый абажур, цепочка выключателя.",
		"usable": true})
	interactor.register("lamp_right", Vector3(2.32, 1.00, -2.85), Vector3(.34, .60, .34), {
		"title": "Лампа справа",
		"text": "Такая же лампа. Цепочка чуть раскачивается.",
		"usable": true})
	# Keep the interaction zone in front of the headboard so the bed collision
	# cannot intercept the ray before the player reaches the wall inscription.
	interactor.register("wall_trace", Vector3(2.25, 1.62, -2.72), Vector3(.72, .42, .18), {
		"title": "Стена у кровати",
		"text": "Обои в мелкую полоску. Ничего."})
	for switch_id in ["switch_hall", "switch_bedroom", "switch_bathroom", "switch_living"]:
		var positions := {
			"switch_hall": Vector3(-2.05, 1.18, -2.52),
			"switch_bedroom": Vector3(-1.72, 1.18, -1.15),
			"switch_bathroom": Vector3(-2.03, 1.18, .25),
			"switch_living": Vector3(.18, 1.30, .90)
		}
		# Зоны выключателей намеренно скромные: прежние были вдвое больше самой
		# клавиши и перехватывали лучи, идущие к соседней мебели.
		var sizes := {
			"switch_hall": Vector3(.34, .38, .28),
			"switch_bedroom": Vector3(.30, .38, .34),
			"switch_bathroom": Vector3(.28, .38, .34),
			"switch_living": Vector3(.34, .38, .28)
		}
		interactor.register(switch_id, positions[switch_id], sizes[switch_id], {
			"title": "Выключатель",
			"text": "Латунная клавиша. Щёлкает мягко и очень отчётливо.",
			"usable": true})
	register_room_objects()

# Обстановка номера, с которой тоже можно возиться. Сюжету она не нужна — она
# нужна, чтобы номер был номером, а не декорацией вокруг пяти важных вещей.
# Часть предметов открывается, часть гасится, за первое обращение к каждому
# стрелка получает пол-секунды.
# Коридор шестнадцатого этажа. Ни одна из этих зон не двигает часы: в прологе
# время ещё стоит. Их работа — научить двум глаголам и дать номеру 1604 вес
# раньше, чем игрок в него войдёт.
func register_corridor() -> void:
	interactor.register("corr_door", Vector3(-2.65, .95, -3.42), Vector3(.85, 1.2, .30), {
		"title": "Дверь 1604",
		"text": "Тёмное дерево, латунная ручка. Под ручкой — узкая прорезь под карту.",
		"usable": true})
	interactor.register("corr_plate", Vector3(-1.90, 1.75, -3.42), Vector3(.46, .26, .28), {
		"title": "Табличка 1604",
		"text": "Номер привинчен к стене рядом с дверью. Латунь протёрта до белизны — за эту цифру держались руками."})
	interactor.register("corr_sign", Vector3(-.80, 2.28, -3.42), Vector3(.92, .34, .28), {
		"title": "Указатель",
		"text": "«1601 — 1610». Стрелка под номерами стёрта: в какую сторону — уже не разобрать."})
	interactor.register("corr_notice", Vector3(-.80, 1.55, -3.40), Vector3(.48, .62, .24), {
		"title": "Распорядок под стеклом",
		"text": "Расчётный час — 16:05. Ниже от руки приписано: «просьба не переводить часы в номерах»."})
	interactor.register("corr_hose", Vector3(1.85, 1.05, -3.42), Vector3(.50, .66, .26), {
		"title": "Пожарный шкаф",
		"text": "За стеклом свёрнутый рукав. Пломба на дверце цела и покрыта пылью.",
		"usable": true})
	# У 1607 на ручке табличка. Своей зоны ей не дать: любая рамка вокруг таблички
	# утонула бы в зоне самой двери, и check_no_overlap() справедливо ругался бы.
	# Поэтому табличка живёт в тексте двери, на которой висит.
	for entry in [["corr_1603", -4.90, "1603", ""], ["corr_1605", -.90, "1605", ""],
			["corr_1607", 1.90, "1607",
			"\nНа ручке — табличка «не беспокоить». Просьбу выполнили."]]:
		interactor.register(str(entry[0]), Vector3(entry[1], 1.15, -5.78), Vector3(.86, 1.5, .26), {
			"title": "Номер %s" % entry[2],
			"text": "Дверь соседнего номера. Под ней не горит свет, и в прорези замка нет карты." + str(entry[3]),
			"usable": true})
	interactor.register("corr_lift", Vector3(3.30, 1.15, -4.60), Vector3(.28, 1.9, 1.9), {
		"title": "Лифт",
		"text": "Створки сомкнуты. Табло над ними погашено, кнопка вызова тёплая.",
		"usable": true})
	interactor.register("corr_cart", Vector3(-5.75, .85, -4.35), Vector3(.70, .95, 1.02), {
		"title": "Тележка горничной",
		"text": "Стопка полотенец, бельё, ни одной бутылки моющего. Тележку бросили посреди смены.",
		"usable": true})
	interactor.register("corr_window", Vector3(-6.50, 1.45, -4.60), Vector3(.30, 1.5, 1.0), {
		"title": "Окно в торце",
		"text": "Стекло холодное. За ним не город и не двор — ровная чернота без единого огня."})
	interactor.register("corr_plant", Vector3(-6.35, .55, -3.50), Vector3(.34, .90, .38), {
		"title": "Кадка с растением",
		"text": "Листья пыльные и жёсткие на ощупь. Земля в кадке сухая до трещин."})
	# Зона тележки на .08 впереди её же коллизии (та начинается на z=-4.00),
	# иначе луч наведения упёрся бы в габарит раньше, чем в зону.
	interactor.register("corr_luggage", Vector3(-1.6, .80, -3.78), Vector3(.90, 1.00, .60), {
		"title": "Багажная тележка",
		"text": "Латунная тележка для чемоданов. На полке — сложенное бельё и чей-то чемодан, пристёгнутый ремнём. Бирки на ручке нет."})
	interactor.register("corr_tray", Vector3(-.9, .13, -5.58), Vector3(.46, .26, .34), {
		"title": "Поднос под дверью",
		"text": "Ужин из рум-сервиса, выставленный в коридор. Колпак ещё на месте, бутылка не открыта, салфетка сложена. К еде не притронулись."})

func register_room_objects() -> void:
	var flavor := {
		# прихожая
		"console": [Vector3(-3.92, .50, -1.72), Vector3(.40, .44, .80), "Консоль у входа",
			"Узкий столик тёмного дерева. Единственный ящик задвинут не до конца.", true],
		"entry_lamp": [Vector3(-4.02, 1.15, -1.92), Vector3(.40, .78, .40), "Лампа в прихожей",
			"Латунная стойка, тканевый абажур. Цепочка выключателя качается, хотя сквозняка нет.", true],
		"hall_plant": [Vector3(-4.00, 1.00, -1.52), Vector3(.30, .40, .30), "Растение",
			"Мелкие плотные листья. Земля сухая на палец вглубь, но лист не свернулся ни один.", false],
		"hall_painting": [Vector3(-4.10, 1.93, -1.72), Vector3(.26, .64, .84), "Картина с озером",
			"Горное озеро в предрассветной дымке. Вода написана без единого блика.", true],
		"entry_rug": [Vector3(-2.72, .14, -2.35), Vector3(.80, .22, .36), "Коврик у двери",
			"Плотный ворс. Примят двумя следами — оба лицом к двери, ни одного обратно.", false],
		"hall_outlet": [Vector3(-2.05, .32, -2.54), Vector3(.28, .26, .24), "Розетка",
			"Круглое гнездо в латунной рамке. Пахнет тёплой пылью.", false],
		# спальня
		"drawer_left": [Vector3(0, .30, -2.57), Vector3(.44, .36, .22), "Левая тумбочка",
			"Ящик прикроватной тумбочки.", true],
		"drawer_right": [Vector3(2.5, .30, -2.57), Vector3(.44, .36, .22), "Правая тумбочка",
			"Такой же ящик с другой стороны кровати.", true],
		# Книги, сервиз, письменный набор и картина в прихожей — usable потому,
		# что у каждого есть последствие: три первых отдают цифру кода, четвёртая
		# отводится от стены. За это [E] над ними честно заслужено, в отличие от
		# тихих зон из QUIET_USE.
		"books": [Vector3(4.00, .52, .45), Vector3(.26, .28, .34), "Книги",
			"Три томика без названий на корешках. Страницы разрезаны только до середины.", true],
		"bed_curtain": [Vector3(4.02, 1.45, -1.10), Vector3(.22, 1.5, 1.25), "Штора в спальне",
			"Тяжёлая оливковая ткань. За ней окно, за окном — ровно ничего.", true],
		"radiator_bed": [Vector3(4.02, .42, -1.10), Vector3(.22, .45, .75), "Радиатор",
			"Секционный, с латунным вентилем. Холодный, хотя в номере тепло.", false],
		"bed_outlet": [Vector3(3.30, .32, -2.97), Vector3(.28, .26, .22), "Розетка у кровати",
			"Ещё одно круглое гнездо. Рядом на обоях — светлый прямоугольник от чего-то, что тут стояло.", false],
		# ванная
		# Зоны ванны, дивана и кресла стоят на ближнем к игроку борту: внутри
		# коллизии самой мебели луч до них не доходит.
		"tub": [Vector3(-3.18, .55, 2.30), Vector3(1.40, .35, .22), "Ванна",
			"Чугунная, с латунной арматурой. Сухая до скрипа.", true],
		"toilet": [Vector3(-3.89, .42, .96), Vector3(.52, .68, .60), "Унитаз",
			"Белый фаянс. Бачок полон.", true],
		"towels": [Vector3(-2.12, .80, 1.25), Vector3(.22, .70, .78), "Полотенца",
			"Сложены гостиничным углом. Верхнее чуть влажное.", false],
		"hand_towel": [Vector3(-2.12, .80, .40), Vector3(.22, .36, .40), "Полотенце для рук",
			"На латунном кольце. Висит идеально ровно.", false],
		"wastebasket": [Vector3(-3.98, .22, .43), Vector3(.30, .40, .30), "Корзина",
			"Пустая. Даже пакета нет.", false],
		"shower": [Vector3(-3.70, 1.35, 2.98), Vector3(.44, .90, .22), "Душ",
			"Лейка на гибком шланге, вентиль перекрыт.", true],
		"toilet_paper": [Vector3(-4.14, .67, 1.52), Vector3(.20, .34, .38), "Держатель",
			"Рулон надорван ровно, будто по линейке.", false],
		# гостиная
		"sofa": [Vector3(3.22, .55, 3.15), Vector3(.20, .40, 1.50), "Диван",
			"Бежевая обивка. Подушка с краю продавлена — здесь сидели, и долго.", false],
		"coffee_table": [Vector3(1.05, .32, 3.15), Vector3(.60, .30, 1.05), "Журнальный столик",
			"Пустая столешница. На лаке — кольцо от стакана, которого нет.", false],
		"living_armchair": [Vector3(2.20, .55, 4.36), Vector3(.70, .40, .20), "Кресло в гостиной",
			"Оливковое, развёрнуто к окну.", false],
		"minibar": [Vector3(4.00, .53, 4.68), Vector3(.42, .72, .80), "Минибар",
			"Низкий шкафчик со стеклянной дверцей.", true],
		"coffee_machine": [Vector3(3.88, 1.10, 4.45), Vector3(.30, .34, .28), "Кофемашина",
			"Хромированная, с одной кнопкой.", true],
		"coffee_service": [Vector3(3.78, 1.06, 4.84), Vector3(.42, .22, .30), "Кофейный сервиз",
			"Две чашки. Обе перевёрнуты вверх дном, обе сухие.", true],
		"living_mirror": [Vector3(4.14, 1.30, 4.68), Vector3(.20, .75, .68), "Зеркало у минибара",
			"Небольшое зеркало в латунной раме. Отражает угол, которого отсюда не видно.", false],
		"living_painting": [Vector3(4.13, 1.72, 3.15), Vector3(.22, .60, 1.26), "Картина с отелем",
			"Ночной отель. Горит одно окно — шестнадцатый этаж, четвёртое справа.", false],
		"writing_set": [Vector3(3.70, .84, 1.62), Vector3(.34, .18, .30), "Письменный набор",
			"Бювар, перо, стопка бумаги. Верхний лист вдавлен чужим почерком.", true],
		"desk_lamp": [Vector3(4.02, 1.14, 1.12), Vector3(.40, .78, .40), "Лампа на столе",
			"Рабочая лампа с зелёным абажуром.", true],
		"desk_chair": [Vector3(3.28, .50, 1.55), Vector3(.46, .88, .46), "Стул",
			"Отодвинут от стола ровно настолько, чтобы сесть.", false],
		"radiator_living": [Vector3(.80, .42, 5.35), Vector3(1.15, .45, .22), "Радиатор в гостиной",
			"Такой же холодный, как в спальне.", false]
	}
	for id in flavor:
		var data: Array = flavor[id]
		interactor.register(str(id), data[0], data[1], {
			"title": str(data[2]), "text": str(data[3]), "usable": bool(data[4])})

	reset_containers()

# Что прячется в открываемых предметах. Счёт из минибара и коробок дают
# запасные дороги к коду — игрок не обязан находить именно картину.
# Вынесено отдельно: сброс круга возвращает содержимое, но зоны не пересоздаёт.
func reset_containers() -> void:
	containers = {
		"console": "В ящике — сложенная гостиничная карта города. Все улицы на ней безымянные.",
		"drawer_left": "Внутри Библия и блокнот. Из блокнота вырван верхний лист.",
		"drawer_right": "Внутри спичечный коробок.",
		"desk": "В ящике только скрепки и один волос.",
		"minibar": "Бутылки не тронуты. Сверху лежит счёт."
	}

func wire_signals() -> void:
	interactor.used.connect(on_used)
	interactor.examined.connect(on_examined)
	inspect.turned_over.connect(on_turned_over)
	clock.minute_reached.connect(on_minute_reached)
	code_lock.opened.connect(on_safe_opened)
	# Пока предмет в руках или открыт сейф, отсчёт до подсказки замирает: игрок
	# не застрял, а читает. Клавиша H при этом продолжает работать.
	inspect.opened.connect(func(_id: String) -> void:
		hints.set_paused(true)
		hud.set_message_raised(true))
	inspect.closed.connect(func(_id: String) -> void:
		hints.set_paused(false)
		hud.set_message_raised(false))
	code_lock.shown.connect(func() -> void: hints.set_paused(true))
	code_lock.hidden.connect(func() -> void: hints.set_paused(false))

# ------------------------------------------------------------------ осмотр ---

func on_examined(id: String) -> void:
	# Пока открыт осмотр или сейф, мир под затемнением не должен ловить клики:
	# иначе случайный ЛКМ во время вращения предмета «осматривает» то, чего
	# игрок вообще не видел, и двигает часы.
	if inspect.active or code_lock.active:
		return
	if id.is_empty():
		# ЛКМ в пустоту — рассмотреть то, что в руке. Иначе оборот записки и
		# бирки ключа, где лежат цифры кода, был бы недоступен.
		var item := inventory.selected_data()
		if not item.is_empty():
			inspect.open(str(item["id"]), {
				"title": str(item["name"]), "text": str(item["text"]),
				"reverse": str(item["reverse"]), "prop": item["prop"]})
		return
	var data := interactor.entry(id)
	inspect.open(id, data)
	interactor.mark_seen(id)
	if not looked.has(id):
		looked[id] = true
		# Акт I: комната просыпается от внимания. Пять первых осмотров —
		# это и обучение глаголу, и обход всего номера.
		if act == Act.INTRO and awake_progress < AWAKE_TARGET:
			awake_progress += 1
			clock.advance(SECONDS_PER_LOOK, "look")
			if awake_progress >= AWAKE_TARGET:
				enter_watching()
	if id == "mirror" and lights_out:
		learn_digit("4")
	if id == "wall_trace" and lights_out:
		complete_task("dark")

func on_turned_over(id: String) -> void:
	match id:
		"card": learn_digit("1")
		"painting": learn_digit("6")
		"note": learn_digit("0")

func learn_digit(digit: String) -> void:
	if known_digits.has(digit):
		return
	known_digits[digit] = true
	cue.play("tick", 1.0)
	# Звук выключен, поэтому панель сейфа — единственное место, где сбор цифр
	# вообще становится виден. Без этой строки known_digits оставался мёртвым:
	# охота за цифрами шла, а на замке ничего не появлялось.
	code_lock.set_known(known_digits.keys())

# ---------------------------------------------------------------- действия ---

func on_used(id: String) -> void:
	if inspect.active or code_lock.active:
		return
	if id.begins_with("corr_"):
		use_corridor(id)
		return
	if act == Act.RESTORE and id in RESTORE_IDS and not restored.get(id, false):
		restore_object(id)
		return
	match id:
		"door": use_door()
		"peephole": use_peephole()
		"clock": use_clock()
		"faucet": use_faucet()
		"mirror": use_mirror()
		"wardrobe": use_wardrobe()
		"safe": use_safe()
		"bed": use_bed()
		"phone": use_phone()
		"tv": use_tv()
		"curtains": use_curtains()
		"bed_curtain": use_bed_curtain()
		"lamp_left": toggle_bedside(0)
		"lamp_right": toggle_bedside(1)
		"wall_trace": use_wall_trace()
		"entry_lamp": toggle_extra_lamp(0)
		"desk_lamp": toggle_extra_lamp(1)
		"toilet": use_flavor(id, "Бачок ухнул и снова начал набираться. Звука воды при этом нет.")
		"tub": use_flavor(id, "Кран открыт. Из него не идёт ничего — ни воды, ни воздуха.")
		"shower": use_flavor(id, "Вентиль проворачивается свободно, до упора и обратно.")
		"coffee_machine": use_flavor(id, "Кнопка утоплена. Машина молчит и не греется.")
		"writing_set": use_writing_set()
		"books": use_books()
		"coffee_service": use_coffee_service()
		"hall_painting": use_hall_painting()
		_:
			if QUIET_USE.has(id):
				use_quiet(id)
			elif containers.has(id):
				open_container(id)
			elif id.begins_with("switch_"):
				toggle_switch(id)
			elif act == Act.RESTORE:
				# В третьем акте E разрешён везде, поэтому промах — обычное дело.
				# Он ничего не отнимает и звучит глухо.
				cue.play("latch", -14.0)

# Мелкая награда за первое обращение к любой обстановке. Потолок акта не даёт
# этим полусекундам довести минуту раньше времени.
func reward(id: String) -> void:
	# В прологе часы стоят: коридор не должен съедать бюджет первого акта.
	if act == Act.PROLOGUE:
		return
	if rewarded.has(id) or act == Act.INTRO and awake_progress < AWAKE_TARGET:
		return
	rewarded[id] = true
	clock.advance(.5)

# ----------------------------------------------------------------- пролог ---

func use_corridor(id: String) -> void:
	match id:
		"corr_door": use_room_door()
		"corr_lift":
			hud.show_message("Кнопка вдавливается и не загорается. За створками — тишина.", 3.2)
			interactor.set_text(id, "Створки сомкнуты. Кнопка вдавлена и не отпускается обратно.")
		"corr_cart":
			hud.show_message("Полотенца сухие и холодные. Под ними — пусто.", 3.0)
			interactor.set_text(id, "Тележка разобрана до пустых полок. Полотенца никто не менял.")
		"corr_hose":
			hud.show_message("Пломба не поддаётся. Стекло не открыть.", 2.8)
		"corr_1603", "corr_1605", "corr_1607":
			hud.show_message("Заперто. Изнутри не отвечают.", 2.6)
			interactor.set_text(id, "Дверь заперта. Ты стучал — за ней даже не скрипнуло.")

func set_entrance_door_open(open: bool, duration: float = .8) -> void:
	door_open = open
	if entrance_collision:
		entrance_collision.collision_layer = 0 if open else 1
		entrance_collision.collision_mask = 0 if open else 1
	var target_rotation := -1.35 if open else 0.0
	if not entrance_door:
		return
	if duration <= 0.0:
		entrance_door.rotation.y = target_rotation
	else:
		create_tween().tween_property(entrance_door, "rotation:y", target_rotation, duration).set_trans(Tween.TRANS_SINE)

func use_room_door() -> void:
	if act != Act.PROLOGUE:
		return
	if door_unlocked:
		if door_open:
			set_entrance_door_open(false)
			hud.show_message("Дверь закрыта.", 2.2)
		else:
			set_entrance_door_open(true)
			hud.show_message("Дверь открыта. Входи.", 2.2)
		return
	if inventory.selected() != "keycard":
		if inventory.has("keycard"):
			hud.show_message("Карта в кармане, а не в руке. Нажми %d." % inventory.slot_of("keycard"), 3.0)
		else:
			cue.play("locked")
			hud.show_message("Заперто.", 2.0)
		return
	door_unlocked = true
	inventory.remove("keycard")
	cue.play("unlock")
	interactor.set_usable("corr_door", false)
	var zone := interactor.zone("corr_door")
	if zone:
		# Зона снаружи больше не нужна: иначе она останется золотым «[E]» и в
		# третьем акте, где E разрешён по всему подряд, и у выхода в финале.
		zone.collision_layer = 0
	if entrance_collision:
		entrance_collision.collision_layer = 0
		entrance_collision.collision_mask = 0
	set_entrance_door_open(true, .9)
	hud.show_message("Замок мигнул зелёным. Карта осталась в прорези.", 3.4)
	hints.set_focus(Vector3(-2.65, 1.20, -2.60), [
		"Дверь открыта.",
		"Порог перед тобой. Войди в номер.",
		"Просто иди вперёд, через дверной проём."])

func enter_room() -> void:
	if entered_room or act != Act.PROLOGUE:
		return
	entered_room = true
	act = Act.INTRO
	var mark := epoch
	# Дверь закрывается за спиной сама. Это единственный момент круга, где
	# комната действует раньше игрока.
	set_entrance_door_open(false, .55)
	cue.play("latch")
	hud.show_message("Дверь закрылась за спиной.", 2.8)
	set_intro_hints()
	await get_tree().create_timer(3.0).timeout
	if mark != epoch:
		return
	hud.show_message("ЛИМБ\nКомната 1604", 3.0)

func set_intro_hints() -> void:
	# Первый акт тоже ведут подсказки: без них «рассмотри пять вещей» —
	# правило, о котором игроку никто не сказал.
	hints.set_focus(Vector3(2.28, 1.72, .67), [
		"Комната ждёт, когда её рассмотрят.",
		"Наведись на любую вещь и нажми ЛКМ. Часы отзываются на внимание.",
		"Рассмотри пять любых предметов — ЛКМ на каждом. И крути их мышью: на обороте бывает написано."])
	hints.set_enabled(true)

# Цель прямым текстом. Счётчики берутся из состояния круга, а номера слотов — из
# инвентаря: жёстко названная клавиша врёт, потому что порядок подбора у каждого
# игрока свой. На этом владелец уже спотыкалась с ключом от часов.
func current_goal() -> String:
	match act:
		Act.PROLOGUE:
			if door_unlocked:
				return "Дверь 1604 открыта. Иди вперёд, через порог."
			return "Найди дверь 1604. Возьми карту-ключ клавишей %d и нажми E на двери." \
				% maxi(inventory.slot_of("keycard"), 1)
		Act.INTRO:
			return "Рассмотри пять любых предметов: наведись и нажми ЛКМ. Осмотрено %d из %d." \
				% [awake_progress, AWAKE_TARGET]
		Act.WATCHING:
			var left: Array[String] = []
			for id in TASK_IDS:
				if not tasks_done.get(id, false):
					left.append(str(TASK_NAMES.get(id, id)))
			if left.is_empty():
				return "Все четыре дела сделаны. Комната вот-вот изменится сама — оглядись."
			return "Осталось сделать: %s. Порядок любой." % ", ".join(left)
		Act.RESTORE:
			var back := restored.size()
			if back < RESTORE_IDS.size():
				return "Пять вещей стоят не так, как стояли: кресло, шкаф, картина, трубка, подушка. Возвращено %d из %d — нажимай E на том, что сдвинуто." \
					% [back, RESTORE_IDS.size()]
			if not key_inserted:
				return "Комната цела. В часах пустое гнездо: возьми заводной ключ клавишей %d и нажми E на часах в гостиной." \
					% maxi(inventory.slot_of("key"), 1)
			return "Ключ на месте. Смотри на часы — стрелка добегает минуту."
		Act.LEAVING:
			return "Замок открыт. Иди к входной двери и нажми E."
		Act.COMPLETE:
			return "Круг пройден."
	return "Оглядись."

# Подобранный предмет бесполезен, пока игрок не знает, что его можно достать:
# осмотр вещи из инвентаря — это ЛКМ в пустоту, и об этом не говорит ничто.
# Номер слота берём фактический, а не выдуманный.
func announce_pickup(id: String, headline: String) -> void:
	var slot := inventory.slot_of(id)
	if slot < 1:
		hud.show_message(headline, 3.0)
		return
	hud.show_message("%s\nСлот %d. Нажми %d, потом ЛКМ в пустоту — рассмотришь."
		% [headline, slot, slot], 4.6)

# Надпись над изголовьем. E делает то же, что и осмотр, — показывает буквы, —
# потому что подсказка обещает именно «наведи прицел на надпись и нажми E», а
# отдельная строка в HUD затёрла бы описание зоны и оставила бы след
# нерассмотренным. Задачу «dark» закрывает on_examined().
func use_wall_trace() -> void:
	on_examined("wall_trace")

func use_flavor(id: String, result: String) -> void:
	hud.show_message(result, 3.0)
	interactor.set_text(id, result)
	reward(id)

# Тихий отклик. В отличие от use_flavor() не затирает описание предмета, а
# дописывает к нему то, что игрок сделал: вещь помнит обращение, и повторный
# осмотр показывает и то, и другое. Своя отметка о сказанном, а не rewarded:
# в прологе reward() выходит сразу и ничего не помечает, а коридорные зоны как
# раз прологовые — иначе строка дописывалась бы на каждое нажатие.
func use_quiet(id: String) -> void:
	var line := str(QUIET_USE[id])
	hud.show_message(line, 3.0)
	if not quiet_said.has(id):
		quiet_said[id] = true
		var base := str(interactor.entry(id).get("default_text", ""))
		interactor.set_text(id, base + "\n" + line if not base.is_empty() else line)
	reward(id)

# --- четыре взаимодействия, которые не просто отвечают, а что-то дают ---

# Вдавленный чужим почерком лист: заштриховать — и проступит номер комнаты.
# Единственное место круга, где цифры кода добываются работой, а не осмотром.
func use_writing_set() -> void:
	if writing_rubbed:
		hud.show_message("Лист уже заштрихован. Проступившее «16» никуда не денется.", 3.0)
		return
	writing_rubbed = true
	learn_digit("1")
	learn_digit("6")
	cue.play("wipe")
	var revealed := "Ты заштриховал вдавленный лист грифелем. Проступило начало числа: 16."
	hud.show_message(revealed, 4.2)
	interactor.set_text("writing_set",
		"Бювар, перо, стопка бумаги.\n" + revealed)
	reward("writing_set")

# Книги с разрезанными до середины страницами: между ними заложен счёт.
func use_books() -> void:
	if books_opened:
		hud.show_message("Между страниц больше ничего не заложено.", 2.8)
		return
	books_opened = true
	learn_digit("0")
	cue.play("wipe")
	var revealed := "Том раскрылся там, где разрезано. Между страниц — счёт за номер, в графе суммы обведён ноль."
	hud.show_message(revealed, 4.4)
	interactor.set_text("books", "Три томика без названий на корешках.\n" + revealed)
	reward("books")

# Две перевёрнутые чашки. Под одной — след и цифра по пыли.
func use_coffee_service() -> void:
	if cups_turned:
		hud.show_message("Чашки стоят как надо. Четвёрка под пылью осталась.", 2.8)
		return
	cups_turned = true
	learn_digit("4")
	cue.play("switch", -4.0)
	var revealed := "Ты перевернул чашки как положено. Под одной — сухое кольцо и четвёрка, выведенная пальцем по пыли."
	hud.show_message(revealed, 4.4)
	interactor.set_text("coffee_service", "Две чашки.\n" + revealed)
	reward("coffee_service")

# Картину можно отвести от стены. За ней ничего — и это тоже ответ.
func use_hall_painting() -> void:
	var painting_node := get_parent().find_child("HallLakePainting", true, false)
	if painting_node and not painting_lifted:
		painting_lifted = true
		var tween := create_tween()
		tween.tween_property(painting_node, "rotation:z", .09, .45).set_trans(Tween.TRANS_SINE)
		tween.tween_property(painting_node, "rotation:z", .0, .8).set_trans(Tween.TRANS_SINE)
	use_flavor("hall_painting",
		"Ты отвёл картину от стены. За ней светлый прямоугольник обоев и больше ничего.")

func open_container(id: String) -> void:
	var opened: String = containers[id]
	interactor.set_text(id, opened)
	hud.show_message(opened, 3.4)
	reward(id)
	match id:
		"drawer_right":
			if not inventory.has("matchbox"):
				inventory.add("matchbox", "коробок", null,
					"Спичечный коробок гостиницы. Спички целы, ни одна не зажжена.",
					"На обороте карандашом: 6")
				announce_pickup("matchbox", "Спичечный коробок — в карман.")
		"minibar":
			if not inventory.has("bill"):
				inventory.add("bill", "счёт", null,
					"Счёт из минибара. Ни одной позиции не отмечено.",
					"Внизу проставлено: К ОПЛАТЕ 1604")
				announce_pickup("bill", "Счёт из минибара — в карман.")
	containers.erase(id)

func toggle_extra_lamp(index: int, id: String = "") -> void:
	if index < 0 or index >= extra_lamps.size():
		return
	var lamp: Dictionary = extra_lamps[index]
	var light: OmniLight3D = lamp["light"]
	var turn_on := not light.visible
	light.visible = turn_on
	for mesh in lamp["meshes"]:
		mesh.material_override = null if turn_on else lamp_off_material
	cue.play("switch")
	hud.show_message("Щелчок. Лампа %s." % ("зажглась" if turn_on else "погасла"), 2.2)
	var target_id := id if not id.is_empty() else ("entry_lamp" if index == 0 else "desk_lamp")
	interactor.set_text(target_id, "Лампа с выключателем. Сейчас %s." % ("включена" if turn_on else "выключена"))
	reward("lamp%d" % index)
	evaluate_darkness()

func use_door() -> void:
	if act == Act.LEAVING:
		open_exit()
		return
	# Дверь заперта всю середину круга. Осмотр прямо обещает, что замок
	# «проворачивается вхолостую», а свободный тумблер позволял открыть её в
	# любой момент и выйти из номера мимо всего прохождения круга.
	if act != Act.PROLOGUE:
		cue.play("locked")
		hud.show_message("Замок проворачивается вхолостую. Дверь не поддаётся.", 2.4)
		rattle_door_handle()
		return
	door_attempts += 1
	cue.play("locked")
	rattle_door_handle()

# Ручка дёргается и встаёт обратно — единственный отклик запертой двери. Один
# на пролог и на середину круга, чтобы они не разъехались при следующей правке.
func rattle_door_handle() -> void:
	var tween := create_tween()
	tween.tween_property(door_handle_lever, "rotation:z", -.38, .10).set_trans(Tween.TRANS_BACK)
	tween.tween_property(door_handle_lever, "rotation:z", 0.0, .13)

func use_peephole() -> void:
	if tasks_done.get("peephole", false):
		hud.show_message("В глазке темно. Коридора, по которому ты пришёл, там больше нет." if broken else "Коридора нет.", 3.4)
		return
	# Одного взгляда достаточно: повторные осмотры больше не требуются для
	# продвижения задачи.
	peephole_stage = 1
	hud.show_message("В глазке — эта же комната. У окна что-то только что промелькнуло.", 4.0)
	cue.play("breath", -2.0)
	learn_digit("4")
	complete_task("peephole")
	return
	peephole_stage += 1
	match peephole_stage:
		1:
			hud.show_message("Пустой коридор. Ковёр, лампы, ни одной двери.", 3.4)
			cue.play("breath", -8.0)
		2:
			hud.show_message("Лампы в коридоре гаснут одна за другой — от дальней к ближней.", 3.6)
			cue.play("flicker", -6.0)
		_:
			hud.show_message("В глазке — эта же комната. Со спины у окна кто-то стоит.", 4.0)
			cue.play("breath", -2.0)
			learn_digit("4")
			complete_task("peephole")

func use_clock() -> void:
	if key_inserted:
		return
	if inventory.selected() != "key":
		if inventory.has("key"):
			hud.show_message("Ключ в кармане, а не в руке. Нажми %d." % inventory.slot_of("key"), 2.8)
		else:
			cue.play("latch", -12.0)
		return
	key_inserted = true
	inventory.remove("key")
	cue.play("metal")
	if act == Act.RESTORE:
		if restored.size() >= RESTORE_IDS.size():
			# Комната уже цела, и ключ был последним, чего не хватало. Без
			# этого вызова круг вставал намертво: start_final() уходил по
			# ветке «нет ключа» и больше никем не вызывался, а потолок часов
			# 59.0 не давал минуте добежать самой.
			start_final()
			return
		# Ключ вставлен, но время не идёт: комната сначала должна вернуться
		# в порядок. Об этом не говорит никто — это показывает стрелка.
		await get_tree().create_timer(.5).timeout
		clock.rewind(2.0)
		hud.show_message("Стрелка дёрнулась и отползла назад.", 3.0)

func use_faucet() -> void:
	if faucet_on:
		return
	faucet_on = true
	cue.play_at("water", Vector3(-3.93, 1.04, -.30))
	mirror_fogged = true
	var fog_color := mirror_fog_material.albedo_color
	fog_color.a = .5
	var tween := create_tween()
	tween.tween_property(mirror_fog_material, "albedo_color", fog_color, 2.2)
	await get_tree().create_timer(2.4).timeout
	if not mirror_fogged:
		return
	mirror_text.text = "1604"
	interactor.set_text("mirror", "Запотевшее стекло. Проступили четыре цифры — их вывели пальцем с той стороны.")
	var text_tween := create_tween()
	text_tween.tween_property(mirror_text, "modulate:a", .9, 1.1)
	complete_task("water")

func use_mirror() -> void:
	if not mirror_fogged:
		cue.play("wipe", -8.0)
		return
	mirror_text.visible = not mirror_text.visible
	cue.play("wipe")

func use_wardrobe() -> void:
	if wardrobe_open:
		return
	wardrobe_open = true
	cue.play_at("creak", Vector3(-1.25, 1.05, -.15), -4.0)
	wardrobe_model.visible = false
	wardrobe_proxy.visible = true
	var tween := create_tween()
	tween.tween_property(wardrobe_door, "rotation:y", -1.2, .8).set_trans(Tween.TRANS_SINE)
	safe_prop.visible = true
	safe_light.light_energy = 0.0
	create_tween().tween_property(safe_light, "light_energy", .72, .5).set_delay(.18)
	# Открытый шкаф перестаёт быть глухим ящиком: снимаем и зону шкафа, и его
	# физическую коробку — иначе сейф внутри не навести ни лучом, ни взглядом.
	interactor.zone("wardrobe").collision_layer = 0
	if wardrobe_collision:
		wardrobe_collision.collision_layer = 0

func use_safe() -> void:
	if safe_open:
		return
	code_lock.open()

func on_safe_opened() -> void:
	safe_open = true
	key_prop.visible = true
	inventory.add("key", "заводной ключ", key_prop,
		"Латунный заводной ключ с бумажной биркой.",
		"На бирке выцветшими чернилами: «1604 — не переводить».")
	key_prop.visible = false
	interactor.set_text("safe", "Сейф открыт. Внутри было пусто, если не считать ключа.")
	announce_pickup("key", "Заводной ключ.")
	complete_task("safe")

func use_bed() -> void:
	if inventory.has("note") or note_prop.visible:
		return
	note_prop.visible = true
	cue.play("paper")
	inventory.add("note", "записка", note_prop,
		"Листок гостиничной бумаги, сложенный вчетверо.",
		"Развёрнуто: «свет мешает смотреть».\nВ углу — 0")
	note_prop.visible = false
	announce_pickup("note", "Под подушкой был сложенный листок.")

# Телефон — единственный в круге, кто говорит с игроком напрямую. Он не выдаёт
# решение, он называет комнату и глагол; искать всё равно приходится самому.
func use_phone() -> void:
	if act == Act.PROLOGUE:
		return
	if not phone_ringing:
		cue.play("dial", -4.0)
		hud.show_message("Гудка нет.", 2.0)
		return
	phone_ringing = false
	phone_light.light_energy = 0.0
	phone_calls += 1
	cue.play("dial", -2.0)
	clock.advance(2.0, "phone")
	hints.reset_timer()
	hud.show_message("Сквозь помехи — голос:\n%s" % phone_line(), 4.8)
	interactor.set_text("phone", "Трубка снова на рычаге. В ней ровный шум без гудка.")

func phone_line() -> String:
	if not tasks_done.get("water", false):
		return "«…открой воду. Она пишет на стекле.»"
	if not tasks_done.get("safe", false):
		return "«…в шкафу. Цифры ты видел ещё в коридоре.»"
	if not tasks_done.get("peephole", false):
		return "«…посмотри в глазок. Три раза, не меньше.»"
	if not tasks_done.get("dark", false):
		return "«…свет мешает смотреть. Погаси всё.»"
	return "«…поздно.»"

# Звонок ставится в очередь после каждой решённой задачи, но никогда не звонит
# в третьем акте: там телефон — предмет, который надо вернуть на место.
func arm_phone() -> void:
	if act != Act.WATCHING or broken or phone_ringing:
		return
	if tasks_done.size() >= TASK_IDS.size():
		return
	var mark := epoch
	await get_tree().create_timer(9.0).timeout
	if mark != epoch or act != Act.WATCHING or broken or phone_ringing:
		return
	start_ring()

func start_ring() -> void:
	phone_ringing = true
	var mark := epoch
	interactor.set_text("phone", "Аппарат звонит. Корпус подрагивает на тумбочке.")
	while phone_ringing and mark == epoch and act == Act.WATCHING and not broken:
		hud.show_message("В спальне звонит телефон.", 2.4)
		for _pulse in range(4):
			if not phone_ringing or mark != epoch:
				break
			cue.play("ring", -4.0)
			var beat := create_tween()
			beat.tween_property(phone_light, "light_energy", 1.25, .16)
			beat.tween_property(phone_light, "light_energy", 0.0, .40)
			await get_tree().create_timer(.95).timeout
		await get_tree().create_timer(3.4).timeout
	if mark == epoch:
		phone_light.light_energy = 0.0

# Телевизор перестал быть выключателем шума: четыре канала, и два последних
# рассказывают то, чего игрок ещё не видел.
func use_tv() -> void:
	tv_channel = (tv_channel + 1) % 4
	cue.play("tv")
	match tv_channel:
		0:
			tv_static.visible = false
			tv_text.text = ""
			hud.show_message("Экран погас.", 2.0)
			interactor.set_text("tv", "Тёмный экран. В нём отражается комната — вся, кроме тебя.")
		1:
			tv_static.visible = true
			tv_text.text = ""
			hud.show_message("Один только шум.", 2.2)
			interactor.set_text("tv", "Экран забит помехами. Звука нет ни на одном канале.")
		2:
			tv_static.visible = true
			tv_text.text = Loc.t("16 ЭТАЖ\nКОРИДОР")
			hud.show_message("Служебный канал: камера коридора. Коридор пуст.", 3.6)
			interactor.set_text("tv", "Служебный канал. Камера смотрит в коридор шестнадцатого этажа.")
		3:
			tv_static.visible = true
			tv_text.text = "1604"
			hud.show_message("Тот же канал показывает эту комнату.\nКамера стоит там, где стоишь ты.", 4.2)
			interactor.set_text("tv", "На экране комната 1604. Ракурс — от двери, с высоты твоих глаз.")
	reward("tv_ch%d" % tv_channel)

# Штора в спальне раньше была надписью. Теперь она ездит — и это единственный
# способ посмотреть в окно, потому что зона окна неизбежно утонула бы в её
# габаритах.
func use_bed_curtain() -> void:
	var closed := not is_equal_approx(bed_curtain_left.position.z, original.bed_curtain_left.origin.z)
	var target_left: float = original.bed_curtain_left.origin.z if closed else -1.30
	var target_right: float = original.bed_curtain_right.origin.z if closed else -.90
	create_tween().tween_property(bed_curtain_left, "position:z", target_left, .65).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(bed_curtain_right, "position:z", target_right, .65).set_trans(Tween.TRANS_SINE)
	cue.play("wipe", -4.0)
	if closed:
		hud.show_message("Штора отъехала. За стеклом ровная чернота без единого огня.", 3.2)
		interactor.set_text("bed_curtain", "Штора отведена. Окно открыто взгляду, и смотреть в нём не на что.")
	else:
		hud.show_message("Штора закрыла окно. В спальне стало на тон темнее.", 3.0)
		interactor.set_text("bed_curtain", "Штора задёрнута наглухо. Ткань холоднее, чем воздух вокруг.")
	reward("bed_curtain")

func use_curtains() -> void:
	var closed := not is_equal_approx(curtain_left.position.x, original.curtain_left.origin.x)
	var target_left: float = original.curtain_left.origin.x if closed else .575
	var target_right: float = original.curtain_right.origin.x if closed else 1.025
	create_tween().tween_property(curtain_left, "position:x", target_left, .65).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(curtain_right, "position:x", target_right, .65).set_trans(Tween.TRANS_SINE)
	cue.play("wipe", -4.0)
	# Без звука движение штор — единственная обратная связь, и её мало.
	hud.show_message("Шторы разъехались." if closed else "Шторы сошлись.", 2.2)
	reward("curtains")

func toggle_bedside(index: int) -> void:
	var turn_on := not lamp_lights[index].visible
	lamp_lights[index].visible = turn_on
	for mesh in bed_lamp_meshes[index]:
		mesh.material_override = null if turn_on else lamp_off_material
	cue.play("switch")
	hud.show_message("Щелчок. Прикроватная лампа %s." % ("зажглась" if turn_on else "погасла"), 2.2)
	evaluate_darkness()

func toggle_switch(id: String) -> void:
	var turn_on := not bool(switch_on[id])
	switch_on[id] = turn_on
	for light: Light3D in switch_groups[id]:
		var index := room_lights.find(light)
		if index >= 0:
			light.light_energy = room_light_energy[index] if turn_on else 0.0
	cue.play("switch")
	evaluate_darkness()
	show_switch_progress(id,turn_on)

func show_switch_progress(id: String, turn_on: bool) -> void:
	if act != Act.WATCHING or tasks_done.get('dark',false):
		return
	var off_count := 0
	for value in switch_on.values():
		if not bool(value):
			off_count += 1
	var room_names := {
		'switch_hall':'Прихожая',
		'switch_bedroom':'Спальня',
		'switch_bathroom':'Ванная',
		'switch_living':'Гостиная'
	}
	var room: String = room_names.get(id,'Комната')
	if turn_on:
		hud.show_message('%s: свет снова включён. Настенные выключатели: %d из 4.' % [room,off_count],2.8)
	elif off_count < 4:
		hud.show_message('%s: свет выключен. Настенные выключатели: %d из 4.\nКарта M отмечает остальные знаками света.' % [room,off_count],3.4)
	else:
		hud.show_message('Все четыре настенных выключателя погашены.\nОстались четыре отдельные лампы.',3.4)

# Темнота — не выключатель сюжета, а состояние комнаты. Следы проступают и
# исчезают ровно столько раз, сколько игрок гасит и зажигает свет.
func evaluate_darkness() -> void:
	var dark := true
	for switch_id in switch_on:
		if switch_on[switch_id]:
			dark = false
	for light in lamp_lights:
		if light.visible:
			dark = false
	for lamp in extra_lamps:
		if (lamp["light"] as OmniLight3D).visible:
			dark = false
	if dark == lights_out:
		return
	lights_out = dark
	var alpha := .82 if dark else 0.0
	create_tween().tween_property(wall_trace, "modulate:a", alpha, 1.3)
	interactor.set_text("wall_trace",
		"Обои в мелкую полоску. Поперёк них проступили буквы — их не написали, они просто есть." if dark
		else "Обои в мелкую полоску. Ничего.")
	# Подсказка второго акта прямо просит нажать E на надписи, но зона была
	# объявлена без usable: [E] над ней не загоралось никогда, а нажатие не
	# доходило до уровня — ветка "wall_trace" в on_used() была мертва, и задача
	# закрывалась только левой кнопкой. Право на E живёт ровно столько, сколько
	# видны буквы; в третьем акте флаг не трогаем — там E разрешён везде.
	if act != Act.RESTORE:
		interactor.set_usable("wall_trace", dark)
	if dark:
		cue.play("breath", -6.0)
		if act == Act.WATCHING and not tasks_done.get("dark", false):
			hud.show_message("Свет погас. Подойди к стене у кровати и нажми E.", 3.6)
			hints.set_focus(Vector3(2.25, 1.45, -2.10), [
				"На стене у кровати проступили буквы.",
				"Свет погас. Теперь рассмотри след над изголовьем.",
				"Спальня: наведи прицел на надпись и нажми E."], lights_of("switch_bedroom"))
		interactor.set_text("mirror", "В темноте стекло отдаёт слабым светом. На нём проступила цифра: 4")
	elif not mirror_fogged:
		interactor.set_text("mirror", "Ты видишь в нём комнату. И себя — с небольшим опозданием.")

# ------------------------------------------------------------------- акты ---

func enter_watching() -> void:
	if act != Act.INTRO:
		return
	act = Act.WATCHING
	clock.start()
	clock.set_pressure(true)
	clock.ceiling = 44.0
	clock.advance(3.0, "act1")
	cue.play("flicker", -4.0)
	hud.show_message("Часы дёрнулись.", 2.6)
	hints.set_enabled(true)
	update_focus()
	anomalies.arm_all(["amb_lamp", "amb_curtain", "amb_tv"])

func complete_task(id: String) -> void:
	if tasks_done.get(id, false):
		return
	tasks_done[id] = true
	clock.advance(SECONDS_PER_TASK, id)
	hints.reset_timer()
	update_focus()
	arm_phone()
	if tasks_done.size() >= TASK_IDS.size():
		break_room()

func update_focus() -> void:
	if act != Act.WATCHING:
		return
	# Три ступени на каждую задачу: намёк, ясное указание, прямое.
	if not tasks_done.get("water", false):
		hints.set_focus(Vector3(-3.93, 1.20, -.30), [
			"В ванной капает, хотя кран закрыт.",
			"Стоит открыть воду в ванной и посмотреть, что станет с зеркалом.",
			"Ванная: нажми E на кране. Когда зеркало запотеет — рассмотри его."],
			lights_of("switch_bathroom"))
	elif not tasks_done.get("safe", false):
		hints.set_focus(Vector3(-1.25, 1.05, -.15), [
			"Шкаф в спальне закрыт неплотно.",
			"В шкафу что-то есть. Внутри стоит сейф на четыре цифры.",
			"Спальня: открой шкаф, потом сейф. Код — номер этой комнаты."],
			lights_of("switch_bedroom"))
	elif not tasks_done.get("peephole", false):
		hints.set_focus(Vector3(-2.65, 1.58, -2.88), [
			"От двери тянет холодом.",
			"В двери есть глазок. Одного взгляда достаточно.",
			"Прихожая: наведи прицел на глазок над ручкой и нажми E один раз."],
			lights_of("switch_hall"))
	elif not tasks_done.get("dark", false):
		hints.set_focus(Vector3(-2.05, 1.18, -2.52), [
			"При таком свете на стенах ничего не разобрать.",
			"Свет мешает смотреть. Погаси в номере всё.",
			"Погаси четыре выключателя и все четыре лампы, потом рассмотри стену у кровати."],
			lights_of("switch_hall"))
	else:
		hints.clear_focus()

	# Once the darkness task becomes current, make the final hint name useful
	# landmarks and point to the in-game map instead of only repeating a count.
	if tasks_done.get('water',false) and tasks_done.get('safe',false) and tasks_done.get('peephole',false) and not tasks_done.get('dark',false):
		hints.set_focus(Vector3(-2.05,1.18,-2.52),[
			'Свет мешает увидеть то, что прячется на стенах.',
			'Погаси четыре настенных выключателя и четыре отдельные лампы.',
			'Выключатели стоят у проходов: в прихожей возле входа, в спальне и ванной по сторонам коридора, в гостиной справа от прохода. Нажми M: четыре знака света отмечают их на карте.'],
			lights_of('switch_hall'))

func lights_of(switch_id: String) -> Array:
	var group = switch_groups.get(switch_id, [])
	return group if group is Array else []

func break_room() -> void:
	if broken:
		return
	broken = true
	act = Act.RESTORE
	# Телефон замолкает: в третьем акте он уже не собеседник, а предмет,
	# который надо вернуть на рычаг.
	phone_ringing = false
	phone_light.light_energy = 0.0
	var mark := epoch
	interactor.set_locked(true)
	hints.set_enabled(false)
	cue.play("flicker")
	hud.fade.modulate.a = 1.0
	await get_tree().create_timer(.85).timeout
	if mark != epoch:
		return
	apply_break()
	hud.fade.modulate.a = 0.0
	interactor.set_locked(false)
	clock.rewind(BREAK_PENALTY)
	# В третьем акте E работает по всей комнате: подсвечивать сдвинутые вещи
	# было бы тем же чеклистом, только без телевизора.
	for id in interactor.targets:
		interactor.set_usable(id, true)
	# ...но обещание [E] остаётся только там, где оно давалось до слома комнаты.
	# Иначе прицел золотится над всеми 55 зонами ровно тогда, когда им ищут пять
	# отличий, и перестаёт значить хоть что-нибудь. Нажатие при этом проходит
	# везде. Флаг живёт до конца круга: дверь, часы и сейф объявлены usable при
	# регистрации, поэтому свою подсказку в финале не теряют, а снимать флаг в
	# последнем акте значило бы вернуть то же золото на все зоны.
	interactor.set_strict_prompt(true)
	clock.ceiling = 59.0
	hints.set_enabled(true)
	hints.set_focus(Vector3(2.28, 1.72, .67), [
		"Комната стала другой, пока свет не горел.",
		"Пять вещей стоят не так, как стояли. Верни их на место.",
		"Обойди спальню: кресло, шкаф, картина, трубка телефона и подушка. E на каждой."])

func apply_break() -> void:
	chair.rotation.y = original.chair.basis.get_euler().y + 1.35
	painting.rotation.z = .13
	pillow_prop.position = Vector3(1.85, .14, -.65)
	pillow_prop.rotation = Vector3(.08, .25, .20)
	phone.visible = false
	phone_base_proxy.visible = true
	handset_prop.visible = true
	handset_prop.position = Vector3(2.35, .66, -2.58)
	handset_prop.rotation = Vector3(.08, .55, .18)
	if not wardrobe_open:
		wardrobe_model.visible = false
		wardrobe_proxy.visible = true
	wardrobe_door.rotation.y = -1.2
	# Сейф свою роль отыграл, а шкаф теперь надо возвращать на место, поэтому
	# зоны меняются местами: наводиться должен шкаф, а не то, что внутри него.
	safe_prop.visible = false
	interactor.zone("safe").collision_layer = 0
	interactor.zone("wardrobe").collision_layer = 2
	if wardrobe_collision:
		wardrobe_collision.collision_layer = 1
	interactor.set_text("chair", "Кресло развёрнуто к кровати. Раньше оно смотрело в окно.")
	interactor.set_text("painting", "Рама висит криво.")
	interactor.set_text("pillow", "Подушка на ковре, далеко от кровати.")
	interactor.set_text("phone", "Трубка снята и лежит рядом с аппаратом.")
	interactor.set_text("wardrobe", "Дверца шкафа открыта настежь.")

func restore_object(id: String) -> void:
	restored[id] = true
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match id:
		"chair": tween.tween_property(chair, "transform", original.chair, .55)
		"painting": tween.tween_property(painting, "transform", original.painting, .45)
		"pillow": tween.tween_property(pillow_prop, "transform", original.pillow, .55)
		"phone":
			tween.tween_property(handset_prop, "transform", original.handset, .45)
			tween.finished.connect(finish_phone)
		"wardrobe":
			tween.tween_property(wardrobe_door, "transform", original.wardrobe, .55)
			tween.finished.connect(finish_wardrobe)
	clock.advance(SECONDS_PER_RESTORE, "restore")
	hints.reset_timer()
	focus_next_restore()
	if restored.size() >= RESTORE_IDS.size():
		start_final()

func finish_phone() -> void:
	handset_prop.visible = false
	phone_base_proxy.visible = false
	phone.visible = true

func finish_wardrobe() -> void:
	wardrobe_proxy.visible = false
	wardrobe_model.visible = true
	safe_prop.visible = false
	var zone := interactor.zone("wardrobe")
	if zone:
		zone.collision_layer = 2
	if wardrobe_collision:
		wardrobe_collision.collision_layer = 1

func focus_next_restore() -> void:
	var guidance := {
		"chair": [Vector3(3.48, .95, .15), "Кресло у окна стоит не так, как стояло.",
			"Кресло развернули. Раньше оно смотрело в окно.",
			"Спальня, у окна: наведись на кресло и нажми E."],
		"wardrobe": [Vector3(-1.25, 1.20, -.15), "Что-то в спальне осталось нараспашку.",
			"Дверца шкафа открыта, а была закрыта.",
			"Спальня: наведись на шкаф и нажми E, чтобы закрыть дверцу."],
		"painting": [Vector3(1.25, 1.88, -2.94), "Над кроватью сбилась линия.",
			"Картина над кроватью висит криво.",
			"Спальня: наведись на картину над кроватью и нажми E."],
		"phone": [Vector3(2.50, .80, -2.68), "Кто-то не положил на место то, чем не пользовался.",
			"Трубка телефона снята и лежит рядом с аппаратом.",
			"Спальня, правая тумбочка: наведись на трубку телефона и нажми E."],
		"pillow": [Vector3(1.85, .35, -.65), "На полу лежит то, чему место на кровати.",
			"Подушка оказалась на ковре.",
			"Спальня: наведись на подушку на ковре и нажми E."]
	}
	for id in RESTORE_IDS:
		if not restored.get(id, false):
			var data: Array = guidance[id]
			hints.set_focus(data[0], [data[1], data[2], data[3]], lights_of("switch_bedroom"))
			return
	hints.set_enabled(false)

func start_final() -> void:
	if final_running:
		return
	final_running = true
	hints.set_enabled(false)
	clock.set_pressure(false)
	if not key_inserted:
		hud.show_message("Комната цела. Часам не хватает ключа.", 3.4)
		hints.set_enabled(true)
		hints.set_focus(Vector3(2.28, 1.72, .67), [
			"Часам чего-то не хватает.",
			"В часах пустое гнездо под заводной ключ.",
			"Возьми ключ в руку клавишей %d и нажми E на часах в гостиной."
				% maxi(inventory.slot_of("key"), 1)])
		# Сразу самая прямая ступень, без лестницы от туманного к ясному.
		#
		# Здесь комната уже цела, все пять вещей на местах, и осталось ровно одно
		# действие. Мяться в этом месте — прямой путь к тому, чтобы игрок решил,
		# что круг сломан: именно тут владелец встала в первый живой прогон, и
		# именно тут прогон со скриншотами показал, что H отвечает «часам чего-то
		# не хватает» вместо того, чтобы назвать ключ и слот.
		hints.show_stage(3)
		final_running = false
		return
	run_final()

func run_final() -> void:
	var mark := epoch
	hud.show_message("Секундная стрелка сдвинулась.", 2.8)
	clock.run_out(6.5)
	# Тиканье ускоряется, пока стрелка добегает минуту. Ждать нечего —
	# это происходит на глазах и заканчивается щелчком замка.
	var interval := .62
	for i in range(12):
		if mark != epoch:
			return
		cue.play("tick", 2.0)
		await get_tree().create_timer(interval).timeout
		interval = maxf(.16, interval - .045)
	cue.stop_hum()

func on_minute_reached() -> void:
	if act == Act.RESTORE and not final_running:
		# Часы дошли до 16:05 раньше сюжета — довести круг всё равно надо.
		final_running = true
	act = Act.LEAVING
	cue.play("unlock")
	clock_display.text = "16:05:00"
	hud.show_message("Замок щёлкнул сам.", 3.0)
	interactor.set_usable("door", true)
	hints.set_enabled(true)
	hints.set_focus(Vector3(-2.65, 1.35, -2.88), [
		"Дверь больше не держит.",
		"Замок открыт. Выход — входная дверь в прихожей.",
		"Прихожая: нажми E на двери и выйди через порог."],
		lights_of("switch_hall"))

func open_exit() -> void:
	if door_open:
		return
	door_open = true
	var mark := epoch
	interactor.set_locked(true)
	exit_darkness.visible = true
	var hall := corridor()
	if hall:
		# Коридор, по которому игрок сюда пришёл, перестаёт существовать.
		# «За дверью нет коридора» — теперь это видно, а не сказано.
		hall.visible = false
	for detail in entrance_details:
		detail.visible = false
	set_entrance_door_open(true, 1.1)
	await get_tree().create_timer(1.2).timeout
	if mark != epoch:
		return
	interactor.set_locked(false)
	hud.show_message("За дверью нет коридора.", 2.6)

func complete_exit() -> void:
	if exit_started or act != Act.LEAVING:
		return
	exit_started = true
	act = Act.COMPLETE
	var mark := epoch
	interactor.set_locked(true)
	create_tween().tween_property(hud.fade, "modulate:a", 1.0, 1.4)
	await get_tree().create_timer(1.5).timeout
	if mark != epoch:
		return
	hud.show_message("КРУГ I — ЛИМБ\nпройден", 3.0)

# ------------------------------------------------------------------ рантайм ---

func _process(delta: float) -> void:
	if act == Act.COMPLETE:
		return
	level_elapsed += delta
	if act == Act.PROLOGUE and door_unlocked and not entered_room:
		if player.global_position.z > ROOM_THRESHOLD_Z:
			enter_room()
	if act == Act.LEAVING and door_open and not exit_started:
		if player.global_position.z < -2.95 and absf(player.global_position.x + 2.65) < .65:
			complete_exit()
	if debug_limbo:
		hud.debug_label.visible = true
		hud.debug_label.text = "act: %s\nчасы: %s (%.1f)\nосмотрено: %d\nзадачи: %d/4 · возвращено: %d/5\nF8 — сброс" % [
			Act.keys()[act], clock_display.text, clock.value, looked.size(),
			tasks_done.size(), restored.size()]

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	var key := (event as InputEventKey).keycode
	# Подсказка по требованию: не надо ждать таймера, если застрял прямо сейчас.
	if key == KEY_H:
		get_viewport().set_input_as_handled()
		request_hint()
		return
	if debug_limbo and key == KEY_F8:
		full_reset()

# ------------------------------------------------------------------- сброс ---

func full_reset() -> void:
	epoch += 1
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	act = Act.INTRO if skip_prologue else Act.PROLOGUE
	door_unlocked = skip_prologue
	entered_room = skip_prologue
	level_elapsed = 0.0
	looked.clear()
	tasks_done.clear()
	restored.clear()
	known_digits.clear()
	quiet_said.clear()
	writing_rubbed = false
	books_opened = false
	cups_turned = false
	painting_lifted = false
	awake_progress = 0
	door_attempts = 0
	door_open = false
	exit_started = false
	peephole_stage = 0
	faucet_on = false
	wardrobe_open = false
	safe_open = false
	lights_out = false
	mirror_fogged = false
	broken = false
	key_inserted = false
	final_running = false

	chair.transform = original.chair
	painting.transform = original.painting
	phone.transform = original.phone
	phone.visible = true
	phone_base_proxy.visible = false
	handset_prop.transform = original.handset
	handset_prop.visible = false
	wardrobe_door.transform = original.wardrobe
	wardrobe_proxy.visible = false
	wardrobe_model.visible = true
	safe_prop.visible = false
	safe_light.light_energy = 0.0
	key_prop.visible = false
	note_prop.visible = false
	pillow_prop.transform = original.pillow
	entrance_door.transform = original.door
	door_handle_lever.transform = original.door_lever
	set_entrance_door_open(false, 0.0)
	for detail in entrance_details:
		detail.visible = true
	curtain_left.transform = original.curtain_left
	curtain_right.transform = original.curtain_right
	player.transform = original.player
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)

	mirror_text.text = ""
	mirror_text.modulate.a = 0.0
	mirror_fog_material.albedo_color = Color(.82, .84, .80, 0.0)
	wall_trace.modulate.a = 0.0
	tv_static.visible = false
	tv_text.text = ""
	tv_channel = 0
	phone_ringing = false
	phone_calls = 0
	phone_light.light_energy = 0.0
	bed_curtain_left.transform = original.bed_curtain_left
	bed_curtain_right.transform = original.bed_curtain_right
	exit_darkness.visible = false

	for i in range(room_lights.size()):
		room_lights[i].light_energy = room_light_energy[i]
	for switch_id in switch_on:
		switch_on[switch_id] = true
	for index in range(lamp_lights.size()):
		lamp_lights[index].visible = true
		for mesh in bed_lamp_meshes[index]:
			mesh.material_override = null
	if entrance_collision:
		entrance_collision.collision_layer = 1
		entrance_collision.collision_mask = 1
	for detail in entrance_details:
		detail.visible = true

	var wardrobe_zone := interactor.zone("wardrobe")
	if wardrobe_zone:
		wardrobe_zone.collision_layer = 2
	var safe_zone := interactor.zone("safe")
	if safe_zone:
		safe_zone.collision_layer = 2
	if wardrobe_collision:
		wardrobe_collision.collision_layer = 1
	# clear() возвращает и тексты, и признак «можно тронуть» к тому, что было
	# объявлено при регистрации, поэтому список здесь больше не дублируется.
	interactor.clear()
	interactor.set_locked(false)
	inventory.clear()
	inspect.close()
	code_lock.close()
	code_lock.clear_known()
	anomalies.clear()
	hints.clear()
	hud.reset()
	clock.reset()
	clock.ceiling = 8.0
	cue.start_hum()
	register_ambient_anomalies()
	for lamp in extra_lamps:
		(lamp["light"] as OmniLight3D).visible = true
		for mesh in lamp["meshes"]:
			mesh.material_override = null
	rewarded.clear()
	reset_containers()

	var hall := corridor()
	if hall:
		hall.visible = true
	var outside_zone := interactor.zone("corr_door")
	if outside_zone:
		outside_zone.collision_layer = 0 if skip_prologue else 2
	if skip_prologue:
		set_intro_hints()
		return

	# Пролог: игрок снова в коридоре, с картой в первом слоте и закрытой дверью.
	player.velocity = Vector3.ZERO
	player.global_position = CORRIDOR_SPAWN
	player.rotation.y = CORRIDOR_YAW
	player.get_node("Head").rotation.x = 0.0
	entrance_door.rotation.y = 0.0
	inventory.add("keycard", "карта-ключ", card_prop,
		"Пластиковая карта-ключ в бумажном конверте.",
		"На конверте вписано от руки: 1604 · выезд 16:05")
	inventory.deselect()
	hints.set_focus(Vector3(-2.65, 1.20, -3.42), [
		"Твой номер где-то на этом этаже.",
		"Номер 1604. Табличка висит рядом с дверью.",
		"Возьми карту-ключ клавишей 1 и нажми E на двери 1604."])
	hints.set_enabled(true)

func register_ambient_anomalies() -> void:
	anomalies.register("amb_lamp", null, func() -> void:
		lamp_lights[1].visible = false
		for mesh in bed_lamp_meshes[1]:
			mesh.material_override = lamp_off_material
		evaluate_darkness(),
		func() -> void:
			lamp_lights[1].visible = true
			for mesh in bed_lamp_meshes[1]:
				mesh.material_override = null,
		{"watch": Vector3(2.37, 1.0, -2.82), "cue": "switch", "delay": 3.0})
	anomalies.register("amb_curtain", curtain_left, func() -> void:
		curtain_left.position.x += .14,
		func() -> void:
			curtain_left.transform = original.curtain_left,
		{"watch": Vector3(.8, 1.35, 5.0), "cue": "wipe", "delay": 6.0})
	anomalies.register("amb_tv", tv_static, func() -> void:
		tv_static.visible = true,
		func() -> void:
			tv_static.visible = false,
		{"watch": Vector3(-1.7, 1.28, 3.15), "cue": "tv", "delay": 9.0})

# ------------------------------------------------------------------ аудит ---

# Состав собранного пакета: в PCK не должно быть исходников ТЗ, QA-снимков и
# видео. Для Яндекс Игр вес пакета — отдельное требование.
func run_export_audit() -> void:
	var files: Array[String] = []
	collect_resource_files("res://", files)
	var forbidden: Array[String] = []
	for path in files:
		var normalized := path.trim_prefix("res://")
		if normalized.begins_with("Задания/") or normalized.begins_with("qa_screens/") or normalized.ends_with(".avi"):
			forbidden.append(normalized)
	if not require(forbidden.is_empty(), "forbidden export resources: " + str(forbidden)): return
	# На телефоне панель сейфа обязана быть настоящим полем ввода. Label здесь
	# выглядит правильно, но не может вызвать системную клавиатуру браузера.
	if not require(code_lock.digits_label is LineEdit, "safe code is not a LineEdit"): return
	if not require(code_lock.digits_label.virtual_keyboard_enabled,
			"safe code has virtual keyboard disabled"): return
	if not require(code_lock.digits_label.virtual_keyboard_type == LineEdit.KEYBOARD_TYPE_NUMBER,
			"safe code does not request a numeric keyboard"): return
	if not require(ResourceLoader.exists("res://main.tscn"), "main scene missing"): return
	if not require(ResourceLoader.exists("res://scripts/levels/LimboLevel.gd"), "level script missing"): return
	for system in ["Interactor", "InspectView", "Inventory", "ClockDirector", "AnomalyDirector", "HintDirector", "CodeLock", "CueAudio", "Hud", "Build"]:
		if not require(ResourceLoader.exists("res://scripts/systems/%s.gd" % system), "system missing: %s" % system): return
	print("LIMBO_EXPORT_AUDIT_OK resources=%d forbidden=0 systems=10" % files.size())
	prepare_shutdown()
	await get_tree().create_timer(.4).timeout
	get_tree().quit()

func reach_origins() -> Dictionary:
	var origins := {
		"door": Vector3(-2.65, 1.20, -1.75), "peephole": Vector3(-2.65, 1.55, -1.75),
		"plate": Vector3(-2.65, 1.60, -1.75), "clock": Vector3(2.28, 1.55, 2.05),
		"card": Vector3(3.48, 1.35, 1.85), "desk": Vector3(3.40, 1.20, 1.95),
		"painting": Vector3(1.25, 1.60, -2.05), "bed": Vector3(1.25, 1.45, -1.30),
		"pillow": Vector3(1.85, 1.45, .05), "wardrobe": Vector3(-.45, 1.45, -.15),
		"chair": Vector3(2.55, 1.35, .15), "phone": Vector3(2.61, 1.40, -2.0),
		"mirror": Vector3(-3.15, 1.55, -.30), "faucet": Vector3(-2.75, 1.45, -.30),
		"tv": Vector3(-.45, 1.45, 3.15), "curtains": Vector3(.8, 1.55, 4.35),
		"lamp_left": Vector3(0, 1.45, -1.75), "lamp_right": Vector3(2.37, 1.45, -1.75),
		"wall_trace": Vector3(2.25, 1.45, -2.10), "switch_hall": Vector3(-2.05, 1.45, -1.82),
		"switch_bedroom": Vector3(-.95, 1.45, -1.15), "switch_bathroom": Vector3(-2.75, 1.45, .25),
		"switch_living": Vector3(.18, 1.45, 1.55),
		# обстановка
		"console": Vector3(-3.40, 1.30, -1.72), "entry_lamp": Vector3(-3.45, 1.30, -1.92),
		"hall_plant": Vector3(-3.45, 1.30, -1.52), "hall_painting": Vector3(-3.40, 1.80, -1.72),
		"entry_rug": Vector3(-2.72, 1.30, -1.70), "hall_outlet": Vector3(-2.05, 1.10, -1.90),
		"drawer_left": Vector3(0, 1.10, -2.00), "drawer_right": Vector3(2.50, 1.10, -2.00),
		"books": Vector3(3.95, 1.20, -.25), "bed_curtain": Vector3(3.30, 1.45, -1.10),
		"radiator_bed": Vector3(3.35, 1.00, -1.10), "bed_outlet": Vector3(3.30, 1.10, -2.30),
		"tub": Vector3(-3.18, 1.30, 2.00), "toilet": Vector3(-3.30, 1.20, .96),
		"towels": Vector3(-2.70, 1.20, 1.25), "hand_towel": Vector3(-2.70, 1.10, .40),
		"wastebasket": Vector3(-3.50, 1.10, .43), "shower": Vector3(-2.90, 1.45, 2.98),
		"toilet_paper": Vector3(-3.60, 1.00, 1.52), "sofa": Vector3(2.90, 1.30, 3.15),
		"coffee_table": Vector3(1.05, 1.30, 2.40), "living_armchair": Vector3(2.20, 1.30, 4.10),
		"minibar": Vector3(3.30, 1.20, 4.68), "coffee_machine": Vector3(3.30, 1.35, 4.45),
		"coffee_service": Vector3(3.20, 1.30, 4.84), "living_mirror": Vector3(3.40, 1.40, 4.68),
		"living_painting": Vector3(3.30, 1.75, 3.15), "writing_set": Vector3(3.30, 1.30, 1.62),
		"desk_lamp": Vector3(3.40, 1.25, 1.12), "desk_chair": Vector3(2.70, 1.20, 1.55),
		"radiator_living": Vector3(.80, 1.10, 4.60),
		# коридор
		"corr_door": Vector3(-2.65, 1.55, -4.30), "corr_plate": Vector3(-1.90, 1.60, -4.20),
		"corr_sign": Vector3(-.80, 1.60, -4.30), "corr_notice": Vector3(-.80, 1.55, -4.15),
		"corr_hose": Vector3(1.85, 1.30, -4.25), "corr_1603": Vector3(-4.90, 1.40, -4.85),
		"corr_1605": Vector3(-.90, 1.40, -4.85), "corr_1607": Vector3(1.90, 1.40, -4.85),
		"corr_lift": Vector3(2.55, 1.35, -4.60), "corr_cart": Vector3(-5.05, 1.30, -4.35),
		"corr_window": Vector3(-5.70, 1.50, -4.60), "corr_plant": Vector3(-5.75, 1.30, -3.50),
		# Поднос стоит на полу, поэтому смотрят на него сверху и с подхода: луч
		# успевает дойти до зоны раньше, чем до зоны двери 1605 за ней.
		"corr_luggage": Vector3(-1.6, 1.35, -4.55), "corr_tray": Vector3(-.9, 1.05, -4.90)
	}
	return origins

# В первом круге темнота — обязательная задача, поэтому недостаточно проверить
# только итоговое состояние. Каждый из четырёх настенных выключателей и каждая
# из четырёх отдельных ламп должны честно пройти полный цикл и вернуться во
# включённое состояние до сюжетного выключения всего номера.
func audit_light_controls() -> bool:
	var switch_ids := ["switch_hall", "switch_bedroom", "switch_bathroom", "switch_living"]
	for switch_id in switch_ids:
		if not require(bool(switch_on.get(switch_id, false)), "%s did not start on" % switch_id): return false
		var controlled := lights_of(switch_id)
		if not require(not controlled.is_empty(), "%s controls no lights" % switch_id): return false
		toggle_switch(switch_id)
		if not require(not bool(switch_on[switch_id]), "%s did not switch off" % switch_id): return false
		for light: Light3D in controlled:
			if not require(light.light_energy <= .001, "%s left a light on" % switch_id): return false
		toggle_switch(switch_id)
		if not require(bool(switch_on[switch_id]), "%s did not switch back on" % switch_id): return false
		for light: Light3D in controlled:
			if not require(light.light_energy > .001, "%s did not restore its light" % switch_id): return false

	if not require(lamp_lights.size() == 2, "bedside lamp lights missing"): return false
	if not require(extra_lamps.size() == 2, "entry or desk lamp light missing"): return false
	for index in range(lamp_lights.size()):
		if not require(lamp_lights[index].visible, "bedside lamp %d did not start on" % index): return false
		toggle_bedside(index)
		if not require(not lamp_lights[index].visible, "bedside lamp %d did not switch off" % index): return false
		toggle_bedside(index)
		if not require(lamp_lights[index].visible, "bedside lamp %d did not switch back on" % index): return false
	for index in range(extra_lamps.size()):
		var light := (extra_lamps[index] as Dictionary)["light"] as OmniLight3D
		if not require(light.visible, "extra lamp %d did not start on" % index): return false
		toggle_extra_lamp(index)
		if not require(not light.visible, "extra lamp %d did not switch off" % index): return false
		toggle_extra_lamp(index)
		if not require(light.visible, "extra lamp %d did not switch back on" % index): return false
	return true

# Прогон всей новой цепочки без игрока. Прежний аудит проверял старый сценарий
# шаг в шаг и после переделки не имел смысла.
func run_audit() -> void:
	await get_tree().physics_frame
	if not require(interactor.targets.size() >= 20, "too few inspectable targets"): return
	for id in ["card", "painting", "clock", "mirror", "wardrobe", "safe", "bed", "peephole"]:
		if not require(interactor.targets.has(id), "missing target: %s" % id): return
	# Сейф намеренно живёт внутри шкафа: их зоны разводятся переключением слоя.
	if not check_no_overlap([["safe", "wardrobe"]]): return
	# Сейф в начале круга закрыт коробкой шкафа (его слой снят), поэтому в общий
	# просмотр он не входит — его наводят отдельным aim_check ниже, ровно там,
	# где шкаф уже открыт. Это единственная зона-исключение во всех девяти кругах.
	if not check_props_placed(["MirrorFog", "TelevisionStatic", "ExitDarkness"]): return
	if not check_reachable(reach_origins(), ["safe"]): return
	# Мёртвое [E]. Круг I разбирает больше всех: явные ветки match, тихие отклики,
	# открываемые ящики, коридор по префиксу и пятёрка третьего акта.
	var bound := ["door", "peephole", "clock", "faucet", "mirror", "wardrobe", "safe",
		"bed", "phone", "tv", "curtains", "bed_curtain", "lamp_left", "lamp_right",
		"wall_trace", "entry_lamp", "desk_lamp", "toilet", "tub", "shower",
		"coffee_machine", "writing_set", "books", "coffee_service", "hall_painting"]
	bound += QUIET_USE.keys()
	bound += containers.keys()
	bound += RESTORE_IDS
	for id in interactor.targets:
		if str(id).begins_with("corr_"):
			bound.append(str(id))
	if not check_actions_bound(bound): return
	if not require(entrance_details.size() == 3, "door details missing"): return
	for detail in entrance_details:
		if not require(detail.get_parent() == entrance_door, "%s is not attached to the door" % detail.name): return
	if not require(entrance_collision.get_parent() == entrance_door, "door collision is not attached to the door"): return
	var bedroom_ceiling := get_parent().find_child("BedroomCeiling", true, false) as OmniLight3D
	if not require(bedroom_ceiling and bedroom_ceiling.light_energy >= .40, "bedroom ceiling light is too dim"): return

	# Пролог: игрок в коридоре и входит в номер сам. Аудит обязан идти тем же
	# путём, каким идёт живой игрок, — иначе первый акт отработает не в том
	# состоянии и всё, что за ним, окажется проверено вхолостую.
	if not require(act == Act.PROLOGUE, "level did not start in the corridor"): return
	if not require(inventory.has("keycard"), "keycard was not issued"): return
	# Карта единственная, поэтому add() выбирает её сама: первый глагол игрок
	# делает одной клавишей E, а не разгадывает слоты на пустом месте.
	if not require(inventory.selected().is_empty(), "keycard is unexpectedly in hand at spawn"): return
	await shot("prologue_lift", Vector3(-.2, .05, -4.62), -PI / 2, .16)
	await shot("prologue_corridor", CORRIDOR_SPAWN, CORRIDOR_YAW, 0.0)
	if not require(current_goal().contains("1604"), "H says nothing useful in the prologue"): return
	inventory.select_by_id("keycard")
	use_room_door()
	if not require(door_unlocked, "keycard did not open room 1604"): return
	if not require(not inventory.has("keycard"), "keycard stayed in the inventory"): return
	await shot("prologue_door_open", Vector3(-2.65, .05, -4.20), PI, -.05)
	player.global_position = Vector3(-2.65, .05, -2.60)
	await get_tree().physics_frame
	enter_room()
	if not require(act == Act.INTRO, "crossing the threshold did not start act I"): return
	await shot("act1_hall", Vector3(-2.55, .05, -2.40), 1.95, -.05)
	if not require(interactor.zone("corr_door").collision_layer == 0, "corridor door zone stayed live inside the room"): return

	# Акт I: внимание будит комнату.
	for id in ["door", "clock", "card", "painting", "bed"]:
		on_examined(id)
		inspect.close()
	if not require(act == Act.WATCHING, "act I did not open act II"): return
	await get_tree().create_timer(.8).timeout
	if not require(clock.value > 0.0, "clock did not move on looking"): return

	# Обороты вещей: цифры кода. Звук выключен, поэтому единственный видимый
	# отклик на находку — строка на панели сейфа, и проверять надо именно её,
	# а не словарь уровня: known_digits уже однажды оказался мёртвым.
	for id in ["card", "painting", "note"]:
		on_turned_over(id)
	if not require(known_digits.size() == 3, "turning items over taught no digits"): return
	if not require(code_lock.known.size() == 3, "digits never reached the safe panel"): return
	if not require(current_goal().contains("из %d" % AWAKE_TARGET) or act != Act.INTRO,
			"H does not count the looks in act I"): return

	# Четыре взаимодействия с последствиями. Проверяем не «функция позвалась», а
	# что четвёртая цифра дошла до панели сейфа: до этого её нельзя было добыть
	# нигде, кроме зеркала в темноте.
	use_writing_set()
	use_books()
	use_coffee_service()
	use_hall_painting()
	if not require(writing_rubbed and books_opened and cups_turned and painting_lifted,
			"interactions with consequences did not fire"): return
	if not require(code_lock.known.has("4"), "the cups did not teach the safe panel a four"): return
	# Повторное обращение не должно ломаться и не должно выдавать цифру заново.
	var known_after := code_lock.known.size()
	use_writing_set()
	use_books()
	use_coffee_service()
	if not require(code_lock.known.size() == known_after, "repeat use handed out digits again"): return

	# Тихие отклики: E отвечает, золотого [E] не обещает. Проверять надо и то, и
	# другое — «отвечает» без второй половины легко вырождается в «обещает», и
	# прицел снова размечает всю комнату.
	if not require(interactor.entry("towels")["usable"], "quiet zone is not usable at all"): return
	if not require(interactor.prompt_state("towels") == Hud.Aim.EXAMINE,
			"quiet zone promises [E]"): return
	on_used("towels")
	if not require(quiet_said.has("towels"), "quiet zone did not answer E"): return
	# Сравниваем с переведённым откликом, а не с русским словом внутри него:
	# иначе проверка держится на языке интерфейса и падает на английской
	# сборке, хотя игра работает правильно. По-русски Loc.t() — тождество,
	# поэтому смысл проверки не изменился.
	if not require(interactor.entry("towels")["text"].contains(Loc.t(str(QUIET_USE["towels"]))),
			"quiet answer never reached the item description"): return

	# Клавиша H обязана отвечать даже там, где ступеней подсказки нет вовсе.
	hints.set_enabled(false)
	request_hint()
	# hud.show_message() отдаёт строку уже на языке игрока, а current_goal()
	# возвращает исходник — сравнивать надо одно с другим через тот же перевод.
	if not require(hud.message.text == Loc.t(current_goal()),
			"H stayed silent with hints disabled"): return
	hints.set_enabled(true)

	# Строка сообщения и описание предмета не должны налезать друг на друга.
	# Пока сообщение рисовалось под затемнением осмотра, они мирно делили один и
	# тот же низ экрана; после переноса на layer 14 обе строки стали нечитаемыми.
	# Поймал это прогон со скриншотами, а не аудит.
	#
	# Считаем по отступам, а не по get_global_rect(): в headless у Control нет
	# разметки, прямоугольники выходят вырожденными, и проверка через intersects()
	# зеленела при заведомо наложенных строках. Оба ярлыка привязаны к
	# CENTER_BOTTOM, поэтому их вертикальные отрезки сравнимы напрямую — и это
	# условие тоже проверяется, иначе сравнение потеряет смысл при смене привязки.
	# Сравнивать разрешённые прямоугольники нельзя: у Hud и InspectView ярлыки
	# оказались в разных системах отсчёта (одна вернула -150, другая 552), а в
	# headless разметки Control нет вовсе, и проверка через intersects() зеленела
	# при заведомо наложенных строках. Поэтому сверяем авторские константы —
	# они обе отсчитываются от низа экрана — и фактическую высоту ярлыка, которая
	# от переноса строк вырастает.
	on_examined("card")
	if not require(hud.message_raised, "message did not rise while the inspect view was open"): return
	if not require(Hud.MESSAGE_Y_RAISED + Hud.MESSAGE_HEIGHT <= InspectView.BODY_TOP,
			"raised message still reaches the inspect description"): return
	# Строка обязана стоять на экране, а не за его краем — и в поднятом положении,
	# и в обычном. Привязка к низу экрана здесь не разрешалась, ярлык уезжал за
	# верхнюю границу, и подсказки не показывались вовсе, кроме как поверх панели
	# сейфа (её полноэкранный слой заставлял разметку пересчитаться). Проверять
	# только одно из двух положений мало: сломанным оказалось именно обычное.
	if not require(message_on_screen(), "raised message sits off screen"): return
	inspect.close()
	if not require(not hud.message_raised, "message stayed raised after the inspect closed"): return
	if not require(message_on_screen(), "message sits off screen in its normal place"): return

	# Акт II: четыре задачи в произвольном порядке.
	use_bed()
	if not require(inventory.has("note"), "note not taken"): return
	# Инвентарь ровно на четыре слота, а предметов в обороте тоже четыре. Если
	# карта-ключ хоть раз останется в кармане, заводной ключ из сейфа некуда
	# будет положить, и круг станет непроходимым молча.
	open_container("drawer_right")
	open_container("minibar")
	if not require(inventory.has("matchbox") and inventory.has("bill"), "container items not taken"): return
	if not audit_light_controls(): return
	# Пока горит свет, на стене нет ничего, и обещать [E] не за что.
	if not require(interactor.prompt_state("wall_trace") == Hud.Aim.EXAMINE,
		"lit wall promises [E] before the letters show"): return
	for switch_id in ["switch_hall", "switch_bedroom", "switch_bathroom", "switch_living"]:
		toggle_switch(switch_id)
	toggle_bedside(0)
	toggle_bedside(1)
	toggle_extra_lamp(0)
	toggle_extra_lamp(1)
	if not require(lights_out, "room did not go dark"): return
	await shot("act2_dark", Vector3(1.25, .05, -1.30), 0.0, -.10)
	# Аудит шёл сюда левой кнопкой и потому не замечал, что E над надписью мертво:
	# подсказка обещает E, значит проверять надо именно его — и обещание [E] тоже.
	if not require(interactor.prompt_state("wall_trace") == Hud.Aim.USE,
		"wall inscription does not promise [E] in the dark"): return
	on_used("wall_trace")
	await shot("act2_wall_trace")
	inspect.close()
	if not require(tasks_done.get("dark", false), "dark task not completed"): return

	use_peephole()
	use_peephole()
	use_peephole()
	if not require(tasks_done.get("peephole", false), "peephole task not completed"): return

	# Новые взаимодействия второго акта. Ни одно из них не обязательно для
	# прохождения, но каждое должно отвечать, иначе это снова просто текст.
	for _channel in range(4):
		use_tv()
	if not require(tv_channel == 0 and not tv_static.visible, "tv channels did not cycle back to off"): return
	use_tv()
	use_tv()
	if not require(tv_channel == 2 and tv_text.text.contains(Loc.t("КОРИДОР")), "tv service channel missing"): return
	use_bed_curtain()
	await get_tree().create_timer(.75).timeout
	if not require(not is_equal_approx(bed_curtain_left.position.z, original.bed_curtain_left.origin.z), "bedroom curtain did not move"): return
	use_bed_curtain()
	var calls_before := phone_calls
	start_ring()
	await get_tree().process_frame
	if not require(phone_ringing, "phone did not start ringing"): return
	use_phone()
	if not require(phone_calls == calls_before + 1 and not phone_ringing, "answering the phone did nothing"): return

	use_wardrobe()
	if not require(interactor.zone("wardrobe").collision_layer == 0, "wardrobe zone still blocks the safe"): return
	if not aim_check("safe", Vector3(-.45, 1.10, -.15)): return
	# Панель сейфа с найденными цифрами: ровно то, что до сегодняшнего дня было
	# мёртвым кодом. На кадре должна быть строка «ты уже видел».
	code_lock.open()
	await shot("act2_safe_panel", Vector3(-.45, .05, -.15), -PI / 2, 0.0)
	code_lock.close()
	on_safe_opened()
	if not require(inventory.has("key"), "key not received from safe"): return
	if not require(inventory.slot_of("key") > 0, "key has no slot: inventory overflowed"): return

	use_faucet()
	await get_tree().create_timer(2.6).timeout
	if not require(tasks_done.get("water", false), "water task not completed"): return

	if not require(broken, "room did not break after four tasks"): return
	await get_tree().create_timer(1.1).timeout
	if not require(act == Act.RESTORE, "act III did not start"): return
	# В третьем акте сдвинутые вещи должны снова ловиться лучом — особенно шкаф,
	# чья зона на время сейфа была отключена.
	for pair in [["wardrobe", Vector3(-.45, 1.45, -.15)], ["chair", Vector3(2.55, 1.35, .15)],
			["painting", Vector3(1.25, 1.60, -2.05)], ["phone", Vector3(2.61, 1.40, -2.0)],
			["pillow", Vector3(1.85, 1.45, .05)]]:
		if not aim_check(str(pair[0]), pair[1]): return

	# Третий акт: E проходит по всей комнате, но золотое [E] — нет. Иначе прицел
	# размечает все 67 зон ровно тогда, когда ими ищут пять отличий. Кресло
	# сдвинуто и нажимается, а обещать [E] над ним нельзя; часы и дверь объявлены
	# usable при регистрации и свою подсказку сохраняют.
	if not require(interactor.strict_prompt, "act III did not tighten the prompt"): return
	if not require(interactor.entry("chair")["usable"], "moved chair is not pressable"): return
	if not require(interactor.prompt_state("chair") == Hud.Aim.EXAMINE,
			"moved chair still promises [E]"): return
	if not require(interactor.prompt_state("clock") == Hud.Aim.USE,
			"clock lost its [E] in act III"): return
	if not require(interactor.prompt_state("door") == Hud.Aim.USE,
			"door lost its [E] in act III"): return

	await shot("act3_broken", Vector3(1.25, .05, -1.30), -.75, -.10)
	if not require(current_goal().contains("Возвращено 0"), "H does not count the restores"): return
	request_hint()

	# Порядок здесь важен: сначала пять предметов, и только потом ключ в часы.
	# Именно так идёт живой игрок, которого ведут подсказки, и именно на этом
	# круг вставал намертво. Прежняя версия проверяла обратный порядок и
	# поэтому оставалась зелёной при неиграбельном финале.
	for id in RESTORE_IDS:
		on_used(id)
	if not require(restored.size() == RESTORE_IDS.size(), "not everything was restored"): return
	if not require(not key_inserted, "key was inserted before the restore pass"): return
	if not require(not final_running, "final started without the key"): return
	# Самое узкое место круга: комната цела, а что делать — непонятно. Именно здесь
	# владелец встала в первый живой прогон. H обязана назвать и ключ, и слот.
	if not require(current_goal().contains("часах") and current_goal().contains("ключ"),
			"H does not point at the clock when the room is whole"): return
	request_hint()
	await shot("act3_restored_hint", Vector3(2.28, .05, 2.05), 0.0, .0)

	inventory.select_by_id("key")
	if not require(inventory.selected() == "key", "key is not the selected item"): return
	use_clock()
	if not require(key_inserted, "key was not inserted into the clock"): return

	var guard := 0
	while act != Act.LEAVING and guard < 200:
		await get_tree().create_timer(.1).timeout
		guard += 1
	if not require(act == Act.LEAVING, "clock never reached 16:05"): return
	if not require(clock.finished, "clock did not finish"): return
	await shot("final_1605", Vector3(2.28, .05, 2.05), 0.0, .06)

	open_exit()
	if not require(corridor() != null, "corridor was never built"): return
	if not require(not corridor().visible, "corridor survived the exit"): return
	await get_tree().create_timer(1.4).timeout
	await shot("final_no_corridor", Vector3(-2.65, .05, -1.90), 0.0, -.02)
	player.global_position = Vector3(-2.65, .05, -3.05)
	await get_tree().process_frame
	complete_exit()
	await get_tree().create_timer(1.7).timeout
	if not require(act == Act.COMPLETE, "circle did not complete"): return
	await shot("complete")

	# Сброс возвращает круг в исходное состояние без перезагрузки сцены.
	full_reset()
	if not require(act == Act.PROLOGUE and clock.value == 0.0 and looked.is_empty(), "full_reset did not clean up"): return
	if not require(corridor().visible and inventory.has("keycard"), "full_reset did not restore the prologue"): return
	# Ужатый прицел и найденные цифры — состояние третьего акта, и во втором
	# прогоне его быть не должно: сброс идёт без перезагрузки сцены, поэтому всё,
	# что круг включил, обязан выключить он сам.
	if not require(not interactor.strict_prompt, "full_reset left the prompt tightened"): return
	if not require(code_lock.known.is_empty(), "full_reset left digits on the safe panel"): return

	print("LIMBO_AUDIT_OK circle I: %d targets, 4 tasks, 5 restores, clock 16:04->16:05" % interactor.targets.size())
	prepare_shutdown()
	await get_tree().create_timer(.35).timeout
	get_tree().quit()
