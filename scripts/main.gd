extends Node3D

const SOFA_MODEL: PackedScene = preload("res://assets/models/sofa.glb")
const ARMCHAIR_MODEL: PackedScene = preload("res://assets/models/armchair.glb")
const BED_MODEL: PackedScene = preload("res://assets/models/bed.glb")
const BEDSIDE_TABLE_MODEL: PackedScene = preload("res://assets/models/bedside_table.glb")
const WARDROBE_MODEL: PackedScene = preload("res://assets/models/wardrobe.glb")
const CONSOLE_TABLE_MODEL: PackedScene = preload("res://assets/models/console_table.glb")
const COFFEE_TABLE_MODEL: PackedScene = preload("res://assets/models/coffee_table.glb")
const TV_STAND_MODEL: PackedScene = preload("res://assets/models/tv_stand.glb")
const TELEVISION_MODEL: PackedScene = preload("res://assets/models/television.glb")
const DESK_MODEL: PackedScene = preload("res://assets/models/desk.glb")
const DESK_CHAIR_MODEL: PackedScene = preload("res://assets/models/desk_chair.glb")
const MINIBAR_MODEL: PackedScene = preload("res://assets/models/minibar.glb")
const COFFEE_MACHINE_MODEL: PackedScene = preload("res://assets/models/coffee_machine.glb")
const BATHROOM_VANITY_MODEL: PackedScene = preload("res://assets/models/bathroom_vanity.glb")
const BATHROOM_BATHTUB_MODEL: PackedScene = preload("res://assets/models/bathroom_bathtub.glb")
const BATHROOM_TOILET_MODEL: PackedScene = preload("res://assets/models/bathroom_toilet.glb")
const BATHROOM_MIRROR_MODEL: PackedScene = preload("res://assets/models/bathroom_mirror.glb")
const BATH_SHOWER_FIXTURE_MODEL: PackedScene = preload("res://assets/models/bath_shower_fixture.glb")
const BATH_TOWEL_RACK_MODEL: PackedScene = preload("res://assets/models/bath_towel_rack.glb")
const BATH_HAND_TOWEL_MODEL: PackedScene = preload("res://assets/models/bath_hand_towel.glb")
const BATH_WASTEBASKET_MODEL: PackedScene = preload("res://assets/models/bath_wastebasket.glb")
const BATH_TOILET_PAPER_MODEL: PackedScene = preload("res://assets/models/bath_toilet_paper.glb")
const BATHROOM_SCONCE_MODEL: PackedScene = preload("res://assets/models/bathroom_sconce.glb")
const GRAND_WALL_CLOCK_MODEL: PackedScene = preload("res://assets/models/grand_wall_clock.glb")
const TABLE_LAMP_MODEL: PackedScene = preload("res://assets/models/table_lamp.glb")
const CEILING_LAMP_MODEL: PackedScene = preload("res://assets/models/ceiling_lamp.glb")
const WALL_LAMP_MODEL: PackedScene = preload("res://assets/models/wall_lamp.glb")
const MIRROR_MODEL: PackedScene = preload("res://assets/models/mirror.glb")
const ENTRANCE_DOOR_MODEL: PackedScene = preload("res://assets/models/entrance_door.glb")
const ENTRY_RUG_MODEL: PackedScene = preload("res://assets/models/entry_rug.glb")
const LIVING_RUG_MODEL: PackedScene = preload("res://assets/models/living_rug.glb")
const INTERIOR_OPEN_DOOR_MODEL: PackedScene = preload("res://assets/models/interior_open_door.glb")
const INTERIOR_OPEN_DOOR_RIGHT_MODEL: PackedScene = preload("res://assets/models/interior_open_door_right.glb")
const POTTED_PLANT_MODEL: PackedScene = preload("res://assets/models/potted_plant.glb")
const PLANT_SMALL_MODEL: PackedScene = preload("res://assets/models/plant_small.glb")
const BOOKS_MODEL: PackedScene = preload("res://assets/models/books.glb")
const RADIATOR_MODEL: PackedScene = preload("res://assets/models/radiator.glb")
const PHONE_MODEL: PackedScene = preload("res://assets/models/vintage_phone.glb")
const WRITING_SET_MODEL: PackedScene = preload("res://assets/models/writing_set.glb")
const COFFEE_SERVICE_MODEL: PackedScene = preload("res://assets/models/coffee_service.glb")
const FANCY_FRAME_MODEL: PackedScene = preload("res://assets/models/fancy_picture_frame.glb")
const WALL_SWITCH_MODEL: PackedScene = preload("res://assets/models/wall_switch.glb")
const WALL_OUTLET_MODEL: PackedScene = preload("res://assets/models/wall_outlet.glb")
const CURTAIN_ROD_MODEL: PackedScene = preload("res://assets/models/curtain_rod.glb")
const SUITE_CROWN_MOLDING_MODEL: PackedScene = preload("res://assets/models/suite_crown_molding.glb")
const WINDOW_SILL_MODEL: PackedScene = preload("res://assets/models/window_sill.glb")
# Отделка коридора. Все пять сгенерированы tools/make_corridor_props.py и
# авторские в финальном масштабе: MultiMesh ставит их как есть, без подгонки.
const CORRIDOR_WAINSCOT_MODEL: PackedScene = preload("res://assets/models/corridor_wainscot.glb")
const CORRIDOR_CORNICE_MODEL: PackedScene = preload("res://assets/models/corridor_cornice.glb")
const CORRIDOR_URN_MODEL: PackedScene = preload("res://assets/models/corridor_urn.glb")
const CORRIDOR_LIFT_DIAL_MODEL: PackedScene = preload("res://assets/models/corridor_lift_dial.glb")
const CORRIDOR_CEILING_ROSE_MODEL: PackedScene = preload("res://assets/models/corridor_ceiling_rose.glb")
const CORRIDOR_CARPET_TILE_MODEL: PackedScene = preload("res://assets/models/corridor_carpet_tile.glb")
const CORRIDOR_LIFT_RELIEF_MODEL: PackedScene = preload("res://assets/models/corridor_lift_relief.glb")
const CORRIDOR_LUGGAGE_CART_MODEL: PackedScene = preload("res://assets/models/corridor_luggage_cart.glb")
const CORRIDOR_SERVICE_TRAY_MODEL: PackedScene = preload("res://assets/models/corridor_service_tray.glb")
const CORRIDOR_DOOR_HANGER_MODEL: PackedScene = preload("res://assets/models/corridor_door_hanger.glb")
const HALL_PAINTING_TEXTURE: Texture2D = preload("res://assets/art/hall_lake_painting.jpg")
const LIVING_PAINTING_TEXTURE: Texture2D = preload("res://assets/art/living_hotel_painting.jpg")
const CORRIDOR_PASS_TEXTURE: Texture2D = preload("res://assets/art/corridor_alpine_pass.jpg")
const CORRIDOR_LIGHTHOUSE_TEXTURE: Texture2D = preload("res://assets/art/corridor_lighthouse.jpg")
const CORRIDOR_BRIDGE_TEXTURE: Texture2D = preload("res://assets/art/corridor_stone_bridge.jpg")
const BEDROOM_GARDEN_TEXTURE: Texture2D = preload("res://assets/art/bedroom_six_cypresses.jpg")
const CORRIDOR_ATMOSPHERE_SCRIPT: Script = preload("res://scripts/systems/CorridorAtmosphere.gd")
const LIMBO_LEVEL_SCRIPT: Script = preload("res://scripts/levels/LimboLevel.gd")
const LUST_LEVEL_SCRIPT: Script = preload("res://scripts/levels/LustLevel.gd")
const GLUTTONY_LEVEL_SCRIPT: Script = preload("res://scripts/levels/GluttonyLevel.gd")
const GREED_LEVEL_SCRIPT: Script = preload("res://scripts/levels/GreedLevel.gd")
const WRATH_LEVEL_SCRIPT: Script = preload("res://scripts/levels/WrathLevel.gd")
const HERESY_LEVEL_SCRIPT: Script = preload("res://scripts/levels/HeresyLevel.gd")
const VIOLENCE_LEVEL_SCRIPT: Script = preload("res://scripts/levels/ViolenceLevel.gd")
const FRAUD_LEVEL_SCRIPT: Script = preload("res://scripts/levels/FraudLevel.gd")
const TREACHERY_LEVEL_SCRIPT: Script = preload("res://scripts/levels/TreacheryLevel.gd")

const MODEL_MATERIAL_DEFAULTS := {
	"wood":"wood2", "_defaultMat":"wood2", "metal":"brass",
	"metalDark":"metal", "metalMedium":"metal", "metalLight":"chrome",
	"carpet":"beige", "carpetDarker":"rug_border", "carpetWhite":"cream",
	"glass":"glass", "lamp":"lamp_glow", "plant":"leaf", "woodDark":"wood"
}

var mats := {}
var shell_node: Shell

# Web exports are single-threaded on hosts without COOP/COEP.  Keep the 3D
# buffer at or below 896x504 while CanvasLayer UI stays at native resolution.
# This also prevents a 1440p/4K browser window from multiplying fragment work.
const WEB_3D_PIXEL_BUDGET := 896.0 * 504.0

func _ready() -> void:
	# Проверка прогресса идёт до сборки комнаты: ей комната не нужна, а сборка
	# занимает секунды.
	if OS.has_environment("FLOW_AUDIT"):
		run_flow_audit()
		return
	# Выбор круга сделан в отдельной лёгкой сцене menu.tscn. Здесь остаётся
	# служебная подготовка прямых запусков main.tscn и режимов аудита.
	Game.prepare_boot()
	# Сборка комнаты — самая долгая операция в игре, и в браузере она идёт в
	# один поток: пока она не кончится, страница не отдаёт ни одного кадра.
	# Разметка по шагам нужна, чтобы решать, что резать, по числам, а не на глаз.
	var build_started := Time.get_ticks_msec()
	var step_marks: Array = []
	make_materials();          step_marks.append(["materials", Time.get_ticks_msec()])
	build_environment();       step_marks.append(["environment", Time.get_ticks_msec()])
	build_architecture();      step_marks.append(["architecture", Time.get_ticks_msec()])
	build_hallway();           step_marks.append(["hallway", Time.get_ticks_msec()])
	build_bedroom();           step_marks.append(["bedroom", Time.get_ticks_msec()])
	build_living_room();       step_marks.append(["living_room", Time.get_ticks_msec()])
	build_bathroom();          step_marks.append(["bathroom", Time.get_ticks_msec()])
	build_lights();            step_marks.append(["lights", Time.get_ticks_msec()])
	build_finishing_details(); step_marks.append(["finishing", Time.get_ticks_msec()])
	build_player();            step_marks.append(["player", Time.get_ticks_msec()])
	build_limbo();             step_marks.append(["limbo", Time.get_ticks_msec()])
	# Строго после build_limbo(): cache_room() сметает все Light3D под корнем в
	# room_lights, и бра коридора иначе попали бы и в выключатели номера, и в
	# задачу «погасить всё».
	build_corridor();          step_marks.append(["corridor", Time.get_ticks_msec()])
	apply_runtime_quality();   step_marks.append(["quality", Time.get_ticks_msec()])
	report_build_times(build_started, step_marks)
	reveal_room_progressively(Time.get_ticks_msec())
	if OS.has_environment("ROOM1408_MODEL_AUDIT"):
		for model_root in get_tree().get_nodes_in_group("downloaded_models"):
			print("MODEL_PLACEMENT %s %s" % [model_root.get_path(), visual_bounds(model_root)])
		await clean_audit_quit()
	if OS.has_environment("ROOM1408_STATS"):
		var counts:={"nodes":0,"meshes":0,"collisions":0,"lights":0,"shadow_lights":0}
		collect_runtime_stats(self,counts)
		print("RUNTIME_STATS %s" % counts)
		await clean_audit_quit()
	if OS.has_environment("ROOM1408_NAV_AUDIT"):
		await get_tree().physics_frame
		run_navigation_audit()
		await clean_audit_quit()
	# Кадры экранов оболочки. Регрессия говорит только «не упало»; что меню
	# читается, помещается на экран и не налезает само на себя, видно лишь глазами.
	if OS.has_environment("SHELL_SHOT"):
		await shell_shot()
	if OS.has_environment("ROOM1408_SCREENSHOT"):
		for _i in range(6): await RenderingServer.frame_post_draw
		var shot_path:=OS.get_environment("ROOM1408_SCREENSHOT")
		if shot_path=="1" or shot_path.is_empty(): shot_path="res://preview.png"
		get_viewport().get_texture().get_image().save_png(shot_path)
		await clean_audit_quit()

# Строка на шаг, а не одна общая: общая говорит только «долго», а нужно знать,
# какой именно шаг резать на куски и где ставить деления прогресса.
func report_build_times(started: int, marks: Array) -> void:
	# Смена сцены стоит дороже самой сборки, поэтому она первой строкой: это
	# снос прошлой комнаты, загрузка main.tscn и разбор 72 preload-констант.
	if Game.scene_change_started > 0:
		print("BUILD_TIME scene_change %d" % [started - Game.scene_change_started])
	var previous := started
	for mark in marks:
		print("BUILD_TIME %s %d" % [mark[0], int(mark[1]) - previous])
		previous = int(mark[1])
	print("BUILD_TIME total %d" % [previous - started])

# Между концом сборки и первым показанным кадром стоят секунды: в Compatibility
# шейдер компилируется при первой отрисовке материала, и вся комната разом даёт
# чёрный экран без единого кадра. Открываем геометрию порциями — работа та же,
# но между порциями страница дышит и может рисовать индикатор.
#
# Скрываем только то, что было видно, и возвращаем ровно это: часть узлов
# спрятана по смыслу круга (тьма за дверью, подменные пропы), и общий
# visible = true сломал бы прохождение.
const REVEAL_BATCH := 12

func reveal_room_progressively(build_finished: int) -> void:
	# Лечение сугубо браузерное. На десктопе компиляция идёт в другом рендерере
	# и незаметна, а аудиты гоняются headless — там прятать геометрию незачем,
	# и лишние кадры ожидания только удлиняют прогон.
	# ROOM1604_FORCE_REVEAL гоняет тот же путь headless: браузера в аудитах нет,
	# а сломать видимость пропов (тьма за дверью, подменные предметы) прогрев
	# может и без него. Прогон круга под этим ключом ловит ровно такую поломку.
	if Engine.is_editor_hint() \
			or (not OS.has_feature("web") and not OS.has_environment("ROOM1604_FORCE_REVEAL")):
		Game.hide_loading()
		return
	var to_reveal: Array[Node] = []
	for node in find_children("*", "GeometryInstance3D", true, false):
		if (node as GeometryInstance3D).visible:
			(node as GeometryInstance3D).visible = false
			to_reveal.append(node)
	var total := to_reveal.size()
	if total == 0:
		Game.hide_loading()
		return
	# Ждём process_frame, а не frame_post_draw: последний headless не наступает
	# вовсе, и прогрев молча повисал бы, оставив комнату невидимой. Ждать шаг
	# главного цикла надёжнее и так же разводит порции по разным кадрам.
	await get_tree().process_frame
	print("BUILD_TIME first_frame_empty %d" % [Time.get_ticks_msec() - build_finished])
	var reveal_started := Time.get_ticks_msec()
	var shown := 0
	while shown < total:
		var batch_end := mini(shown + REVEAL_BATCH, total)
		while shown < batch_end:
			(to_reveal[shown] as GeometryInstance3D).visible = true
			shown += 1
		Game.set_loading_progress(float(shown) / float(total))
		await get_tree().process_frame
	print("BUILD_TIME reveal %d over %d meshes" % [Time.get_ticks_msec() - reveal_started, total])
	Game.hide_loading()

# Проверка прогресса: сохранение, разблокировка кругов, порченые данные и
# слияние с облаком. Всё это невидимо до того дня, когда игрок теряет пройденное,
# поэтому проверяется отдельно и на своём файле, а не на сохранении живого игрока.
#
# Как и остальные проверки проекта, не использует assert: он вырезается в
# release, и сломанная логика молча печатала бы «OK».
func run_flow_audit()->void:
	Game.save_path="user://progress_flow_audit.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
	Game.completed.clear()
	Game.current_circle=Game.FIRST_CIRCLE
	Game.sound_on=true

	if not flow_require(Game.resolve_circle()==1,"свежий запуск ведёт не в первый круг"): return
	if not flow_require(not Game.has_progress(),"на чистом старте есть что продолжать"): return
	if not flow_require(Game.is_unlocked(1),"первый круг закрыт"): return
	if not flow_require(not Game.is_unlocked(2),"второй круг открыт до прохождения первого"): return

	# Прошли первый круг: открывается второй, продолжать предлагается с него.
	Game.mark_completed(1)
	if not flow_require(Game.is_completed(1),"первый круг не отметился пройденным"): return
	if not flow_require(Game.current_circle==2,"после первого круга продолжение не со второго"): return
	if not flow_require(Game.is_unlocked(2),"второй круг не открылся"): return
	if not flow_require(not Game.is_unlocked(3),"третий круг открылся раньше времени"): return
	if not flow_require(Game.is_unlocked(1),"пройденный круг закрылся для повтора"): return

	# Требование Яндекса: обновление страницы не теряет сохранённое.
	# Проверяем именно перечитыванием с диска, а не памятью процесса.
	Game.completed.clear()
	Game.current_circle=Game.FIRST_CIRCLE
	Game.load_progress()
	if not flow_require(Game.is_completed(1),"сохранение не пережило перечитывание"): return
	if not flow_require(Game.current_circle==2,"перечитанное сохранение ведёт не туда"): return

	# Настройка звука переживает перезапуск наравне с прогрессом.
	Game.set_sound(false)
	Game.sound_on=true
	Game.load_progress()
	if not flow_require(not Game.sound_on,"выключенный звук не сохранился"): return
	Game.set_sound(true)

	# Девятый круг — последний: продолжать после него некуда, дальше только финал.
	for number in range(1,Game.LAST_CIRCLE+1):
		Game.mark_completed(number)
	if not flow_require(Game.all_circles_done(),"пройдены не все круги"): return
	if not flow_require(Game.current_circle==Game.LAST_CIRCLE,
			"после девятого круга продолжение уехало за границу: %d"%Game.current_circle): return
	if not flow_require(Game.is_unlocked(Game.LAST_CIRCLE),"девятый круг закрыт после прохождения"): return

	# Меньший облачный прогресс не имеет права затирать больший локальный:
	# иначе первый заход с пустого облака стирает всё, пройденное офлайн.
	var before:int=Game.completed.size()
	Game.merge_cloud_progress({"circle":2,"completed":[1]})
	if not flow_require(Game.completed.size()==before,
			"облако затёрло больший локальный прогресс: %d из %d"%[Game.completed.size(),before]): return
	# Больший облачный, наоборот, принимается.
	Game.completed.clear()
	Game.current_circle=Game.FIRST_CIRCLE
	Game.merge_cloud_progress({"circle":4,"completed":[1,2,3]})
	if not flow_require(Game.completed.size()==3,"больший облачный прогресс не принят"): return

	# Порченое сохранение обязано означать «начать сначала», а не падение.
	Game.progress_from_dictionary({"circle":"вздор","completed":["ерунда",99,-4,{}]})
	if not flow_require(Game.completed.is_empty(),"мусор из сохранения попал в прогресс"): return
	if not flow_require(Game.current_circle==Game.FIRST_CIRCLE,"порченое сохранение увело не в первый круг"): return

	# Служебная дверь разработки обязана продолжать работать: на ней держатся
	# все девять аудитов кругов.
	Game.circle_to_load=0
	if not flow_require(Game.resolve_circle()==1,"без переменных ведёт не в первый круг"): return
	Game.circle_to_load=7
	if not flow_require(Game.resolve_circle()==7,"выбор игрока не перевесил значение по умолчанию"): return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
	print("FLOW_AUDIT_OK progress: %d circles, save/reload, sound, cloud merge, corrupt save"%Game.LAST_CIRCLE)
	await get_tree().create_timer(.2).timeout
	get_tree().quit()

# Снимает по кадру с каждого экрана оболочки. Запускать без --headless: без
# настоящего окна рисовать нечего.
func shell_shot()->void:
	var directory:=OS.get_environment("SHELL_SHOT")
	if directory=="1" or directory.is_empty(): directory="res://qa_screens/shell"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if not shell_node:
		printerr("SHELL_SHOT_FAIL: оболочка не построена")
		get_tree().quit(1)
		return
	# Прогресс подделываем на время съёмки, чтобы попали в кадр и «Продолжить»,
	# и открытые круги, и отметки пройденного. На диск это не уходит: путь
	# сохранения уводится в сторону.
	Game.save_path="user://progress_shell_shot.cfg"
	Game.completed={1:true,2:true,3:true}
	Game.current_circle=4

	var screens:={
		"menu":func()->void: shell_node.show_main_menu(),
		"circles":func()->void: shell_node.show_circle_list(),
		"controls":func()->void: shell_node.show_controls(),
		"pause":func()->void: shell_node.show_pause(),
		"map":func()->void: shell_node.show_map(),
		"transition":func()->void:
			shell_node.finished_circle=3
			shell_node.pending_circle=4
			shell_node.show_transition()
			# Отсчёт глушим: иначе кадр снимется уже после перезагрузки сцены.
			shell_node.countdown=0.0,
		"finale":func()->void: shell_node.show_finale(),
		# Последним — сама игра: экраны оболочки убраны, видно HUD и, если
		# включено сенсорное управление, его кнопки.
		"play":func()->void: shell_node.hide_all()
	}
	var index:=0
	for label in screens:
		(screens[label] as Callable).call()
		for _i in range(6): await RenderingServer.frame_post_draw
		index+=1
		var path:="%s/%02d_%s.png"%[directory,index,label]
		get_viewport().get_texture().get_image().save_png(path)
		print("SHELL_SHOT %s"%path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
	print("SHELL_SHOT_OK %d screens"%index)
	await get_tree().create_timer(.2).timeout
	get_tree().quit()

func flow_require(condition:bool,message:String)->bool:
	if condition: return true
	printerr("FLOW_AUDIT_FAIL: %s"%message)
	get_tree().quit(1)
	return false

func clean_audit_quit() -> void:
	# Узел уровня ищем по способности, а не по имени: имя зависит от круга, и
	# захардкоженный «LimboLevel» молча переставал бы гасить звук во всех
	# остальных восьми.
	for child in get_children():
		if child.has_method("prepare_shutdown"):
			child.prepare_shutdown()
	await get_tree().create_timer(.4).timeout
	get_tree().quit()

func mat(key:String, color:Color, rough:=0.72, metallic:=0.0, emission:=Color(0,0,0,1)) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=rough; m.metallic=metallic
	if emission.r+emission.g+emission.b>0.0: m.emission_enabled=true; m.emission=emission; m.emission_energy_multiplier=.45
	mats[key]=m; return m

func make_materials() -> void:
	# Painted plaster keeps the ceiling trim readable instead of turning it
	# into the thick black beam produced by the furniture-wood palette.
	mat('crown',Color('c8bda8'),0.84,0.0,Color('241f19')); mat('crown_accent',Color('aa8752'),0.48,0.18)
	mat("wall",Color("a18f74")); mat("wood",Color("29170f"),0.48); mat("wood2",Color("4a2a18"),0.5)
	mat("carpet",Color("665443"),0.95); mat("beige",Color("aa9277"),0.9); mat("cream",Color("d1c3a8"),0.82)
	mat("olive",Color("4c5031"),0.92); mat("brass",Color("7b5527"),0.34,0.65); mat("metal",Color("252422"),0.38,0.72); mat("chrome",Color("b8b9b6"),0.24,0.45)
	mat("tile",Color("b9ad98"),0.76); mat("porcelain",Color("d7d0bf"),0.35); mat("screen",Color("080b0e"),0.22)
	mat("night",Color("07101d"),0.8,0.0,Color("07101d")); mat("light",Color("ead8b5"),0.45,0.0,Color("ffd8a2")); mat("lamp_glow",Color("d8c39e"),0.68,0.0,Color("f6d39c")); var lamp_glow:StandardMaterial3D=mats.lamp_glow; lamp_glow.emission_energy_multiplier=.16
	mat("picture_glow",Color("a97842"),.58,0.0,Color("d49a56")); var picture_glow:StandardMaterial3D=mats.picture_glow; picture_glow.emission_energy_multiplier=.10
	mat("painting",Color("263120"),0.8); mat("glass",Color(0.25,0.32,0.35,0.32),0.15)
	mat("painting_sky",Color("625d50"),0.88); mat("painting_hill",Color("293226"),0.94); mat("painting_water",Color("4a6061"),0.72); mat("painting_moon",Color("c8b487"),0.82); mat("rug_border",Color("3c2b20"),0.94); mat("tulle",Color(0.82,0.79,0.70,.18),0.95); mat("window_glass",Color(0.16,0.22,0.31,.12),0.12)
	mat("leaf",Color("354126"),0.9); mat("flower",Color("b99a72"),0.86); mat("flower_dark",Color("70483e"),0.9)
	mat("night_sky",Color("071326"),0.98,0.0,Color("071326")); mat("city_dark",Color("090b11"),0.96); mat("city_mid",Color("121725"),0.92)
	mat("window_warm",Color("c49b5d"),0.82,0.0,Color("bd8d49")); mat("window_cool",Color("66789a"),0.86,0.0,Color("4a5d83")); mat("moon",Color("c6c3b0"),0.9,0.0,Color("777d8f"))
	var g:StandardMaterial3D=mats.glass; g.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; g.cull_mode=BaseMaterial3D.CULL_DISABLED
	var t:StandardMaterial3D=mats.tulle; t.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; t.cull_mode=BaseMaterial3D.CULL_DISABLED; t.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
	# Основные материалы не используют карты по мегабайту на каждый предмет:
	# древесные поры, тканое переплетение и стеклянная кромка считаются в шейдере.
	# Это даёт микрофактуру в бликах почти без роста PCK.
	# Three tiny procedural finishes keep the wood readable without bitmap maps:
	# dark walnut trim, matte architectural timber, and softly lacquered furniture.
	var dark_wood:=Shader.new(); dark_wood.code="shader_type spatial; render_mode diffuse_burley; float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);} void fragment(){ float bend=UV.y+sin(UV.x*9.0)*.018; float broad=sin(bend*58.0)*.5+.5; float fine=sin(bend*123.0+sin(UV.x*17.0))*.5+.5; float pore=smoothstep(.88,1.0,h(floor(UV*vec2(96.0,52.0)))); ALBEDO=vec3(.092,.038,.019)+broad*vec3(.016,.007,.003)+fine*vec3(.006,.0025,.001)-pore*vec3(.009,.004,.002); ROUGHNESS=.46+pore*.09; SPECULAR=.42; }"; var dwm:=ShaderMaterial.new(); dwm.shader=dark_wood; mats["wood"]=dwm
	var warm_wood:=Shader.new(); warm_wood.code="shader_type spatial; render_mode diffuse_burley; float h(vec2 p){return fract(sin(dot(p,vec2(91.7,273.1)))*19341.17);} void fragment(){ float bend=UV.y+sin(UV.x*7.0)*.022; float broad=sin(bend*48.0)*.5+.5; float fine=sin(bend*105.0+sin(UV.x*13.0))*.5+.5; float pore=smoothstep(.91,1.0,h(floor(UV*vec2(82.0,46.0)))); ALBEDO=vec3(.185,.078,.034)+broad*vec3(.026,.012,.005)+fine*vec3(.008,.0035,.0015)-pore*vec3(.010,.004,.002); ROUGHNESS=.53+pore*.08; SPECULAR=.34; }"; var wwm:=ShaderMaterial.new(); wwm.shader=warm_wood; mats["wood2"]=wwm
	var lacquered_wood:=Shader.new(); lacquered_wood.code="shader_type spatial; render_mode diffuse_burley; float h(vec2 p){return fract(sin(dot(p,vec2(63.7,241.9)))*31831.31);} void fragment(){ float bend=UV.y+sin(UV.x*8.0)*.024; float broad=sin(bend*51.0)*.5+.5; float fine=sin(bend*116.0+sin(UV.x*15.0)*1.2)*.5+.5; float pore=smoothstep(.94,1.0,h(floor(UV*vec2(88.0,48.0)))); ALBEDO=vec3(.160,.050,.020)+broad*vec3(.032,.012,.004)+fine*vec3(.009,.003,.001)-pore*vec3(.010,.003,.001); ROUGHNESS=.30+pore*.10+(1.0-broad)*.025; SPECULAR=.58; }"; var lwm:=ShaderMaterial.new(); lwm.shader=lacquered_wood; mats["wood_lacquer"]=lwm
	# Slight brushing and rare dull specks turn the many golden fittings into
	# aged hotel brass without adding a shared metal texture.
	var aged_brass:=Shader.new(); aged_brass.code="shader_type spatial; render_mode diffuse_burley; float h(vec2 p){return fract(sin(dot(p,vec2(103.1,257.7)))*31871.17);} void fragment(){ float brushed=sin(UV.y*146.0+sin(UV.x*19.0))*.5+.5; float speck=h(floor(UV*vec2(74.0,91.0))); float tarnish=smoothstep(.935,1.0,speck); ALBEDO=vec3(.305,.170,.055)+brushed*vec3(.014,.008,.002)-tarnish*vec3(.040,.020,.001)+tarnish*vec3(0.0,.008,.005); METALLIC=.58; ROUGHNESS=.31+tarnish*.18+(1.0-brushed)*.025; SPECULAR=.50; }"; var abm:=ShaderMaterial.new(); abm.shader=aged_brass; mats["brass"]=abm
	var beige_fabric:=Shader.new(); beige_fabric.code="shader_type spatial; render_mode diffuse_burley; void fragment(){ float warp=sin(UV.x*74.0)*.5+.5; float weft=sin(UV.y*91.0)*.5+.5; float thread=warp*weft-.25; ALBEDO=vec3(.49,.405,.315)+thread*.008; ROUGHNESS=.91+(1.0-warp*weft)*.065; }"; var bfm:=ShaderMaterial.new(); bfm.shader=beige_fabric; mats["beige"]=bfm
	var cream_fabric:=Shader.new(); cream_fabric.code="shader_type spatial; render_mode diffuse_burley; void fragment(){ float warp=sin(UV.x*69.0)*.5+.5; float weft=sin(UV.y*87.0)*.5+.5; float thread=warp*weft-.25; ALBEDO=vec3(.72,.66,.55)+thread*.007; ROUGHNESS=.84+(1.0-warp*weft)*.10; }"; var cfm:=ShaderMaterial.new(); cfm.shader=cream_fabric; mats["linen"]=cfm
	# The same weave becomes warmer and faintly emissive on lampshades, so the
	# shade itself glows instead of looking like an opaque white prop.
	var warm_shade:=Shader.new(); warm_shade.code="shader_type spatial; render_mode diffuse_burley; void fragment(){ float warp=sin(UV.x*67.0)*.5+.5; float weft=sin(UV.y*83.0)*.5+.5; float thread=warp*weft-.25; ALBEDO=vec3(.64,.54,.40)+thread*.007; EMISSION=vec3(.040,.024,.011)+thread*vec3(.004,.002,.001); ROUGHNESS=.88+(1.0-warp*weft)*.08; }"; var wsm:=ShaderMaterial.new(); wsm.shader=warm_shade; mats["shade"]=wsm
	var olive_fabric:=Shader.new(); olive_fabric.code="shader_type spatial; render_mode diffuse_burley; void fragment(){ float warp=sin(UV.x*72.0)*.5+.5; float weft=sin(UV.y*89.0)*.5+.5; float thread=warp*weft-.25; float edge=pow(1.0-clamp(abs(dot(normalize(NORMAL),normalize(VIEW))),0.0,1.0),2.0); ALBEDO=vec3(.225,.235,.120)+thread*.009+edge*vec3(.020,.023,.010); ROUGHNESS=.91+(1.0-warp*weft)*.075; }"; var ofm:=ShaderMaterial.new(); ofm.shader=olive_fabric; mats["olive"]=ofm
	var carpet_fiber:=Shader.new(); carpet_fiber.code="shader_type spatial; render_mode diffuse_burley; float h(vec2 p){return fract(sin(dot(p,vec2(41.3,289.1)))*27183.19);} void fragment(){ float fiber=h(floor(UV*vec2(185.0,185.0))); float line=(sin(UV.y*215.0)*.5+.5)*.012; ALBEDO=vec3(.31,.25,.195)+vec3((fiber-.5)*.032)+line; ROUGHNESS=.98; }"; var cpm:=ShaderMaterial.new(); cpm.shader=carpet_fiber; mats["carpet"]=cpm
	var hotel_glass:=Shader.new(); hotel_glass.code="shader_type spatial; render_mode blend_mix,cull_disabled; void fragment(){ float edge=pow(1.0-clamp(abs(dot(normalize(NORMAL),normalize(VIEW))),0.0,1.0),3.0); ALBEDO=mix(vec3(.075,.105,.115),vec3(.22,.26,.27),edge); ALPHA=.10+edge*.34; ROUGHNESS=.09+edge*.12; METALLIC=.08; }"; var hgm:=ShaderMaterial.new(); hgm.shader=hotel_glass; mats["glass"]=hgm
	# Suite windows keep the distant city visible, while a sparse animated rain
	# pattern gives the pane thickness and weather without a texture or particles.
	var night_window:=Shader.new(); night_window.code="shader_type spatial; render_mode blend_mix,cull_disabled; float h(float n){return fract(sin(n)*43758.5453);} void fragment(){ float col=floor(UV.x*28.0); float seed=h(col+7.3); float speed=.012+seed*.020; float phase=fract(UV.y+TIME*speed+seed*4.7); float thin=1.0-smoothstep(.055,.18,abs(fract(UV.x*28.0)-.5)); float active=step(.72,h(col*3.1+1.7)); float head=smoothstep(.968,.997,phase); float tail=smoothstep(.72,.95,phase)*(1.0-smoothstep(.95,.985,phase)); float rain=(head+tail*.22)*thin*active; float edge=pow(1.0-clamp(abs(dot(normalize(NORMAL),normalize(VIEW))),0.0,1.0),3.0); float haze=(sin(UV.y*23.0+sin(UV.x*11.0))*.5+.5)*.012; ALBEDO=vec3(.030,.050,.078)+vec3(haze)+rain*vec3(.13,.16,.19)+edge*vec3(.065,.080,.10); ALPHA=.095+edge*.12+rain*.16; ROUGHNESS=.10+rain*.24+haze*2.0; }"; var nwm:=ShaderMaterial.new(); nwm.shader=night_window; mats["window_glass"]=nwm
	# Без ReflectionProbe настоящий металл в Compatibility-рендерере проваливался
	# в чёрный. Здесь серебрение светлое само по себе, а блики остаются физическими.
	var hotel_mirror:=Shader.new(); hotel_mirror.code="shader_type spatial; render_mode diffuse_burley; void fragment(){ float edge=pow(1.0-clamp(abs(dot(normalize(NORMAL),normalize(VIEW))),0.0,1.0),2.5); float warm=smoothstep(.05,.95,UV.y)*.040; float age=(sin(UV.x*43.0+sin(UV.y*19.0))*.5+.5)*.010; ALBEDO=vec3(.39,.415,.44)+vec3(warm,warm*.72,warm*.40)+age; EMISSION=vec3(.070,.078,.092)+edge*vec3(.030,.034,.040); METALLIC=.04; ROUGHNESS=.16+age*2.0; }"; var hmm:=ShaderMaterial.new(); hmm.shader=hotel_mirror; mats["mirror"]=hmm
	var hotel_tile:=Shader.new(); hotel_tile.code="shader_type spatial; render_mode diffuse_burley; float h(vec2 p){return fract(sin(dot(p,vec2(37.1,213.7)))*19183.17);} void fragment(){ float cloud=sin(UV.x*17.0+sin(UV.y*11.0))*sin(UV.y*19.0)*.012; float speck=(h(floor(UV*vec2(92.0)))-.5)*.010; ALBEDO=vec3(.57,.535,.47)+cloud+speck; ROUGHNESS=.60+speck*2.0; }"; var htm:=ShaderMaterial.new(); htm.shader=hotel_tile; mats["tile"]=htm
	var sheer:=Shader.new(); sheer.code="shader_type spatial; render_mode blend_mix,cull_disabled; void fragment(){ float warp=smoothstep(.80,1.0,sin(UV.x*92.0)*.5+.5); float weft=smoothstep(.84,1.0,sin(UV.y*117.0)*.5+.5); float thread=max(warp,weft); ALBEDO=vec3(.78,.75,.67); ALPHA=.045+thread*.16; ROUGHNESS=.92; }"; var sm:=ShaderMaterial.new(); sm.shader=sheer; mats["tulle"]=sm
	# Процедурные обои коридора: мелкое тканое зерно и почти исчезающая полоска.
	# Шейдер весит несколько строк вместо новой повторяющейся текстуры.
	var corridor_wallpaper:=Shader.new(); corridor_wallpaper.code="shader_type spatial; render_mode diffuse_burley; void fragment(){ float weave=(sin(UV.x*720.0)+sin(UV.y*560.0))*.006; float stripe=(.5+.5*cos(UV.x*62.8319))*.012; ALBEDO=vec3(.50,.46,.41)+weave-stripe; ROUGHNESS=.96; }"; var cwm:=ShaderMaterial.new(); cwm.shader=corridor_wallpaper; mats["corridor_wall"]=cwm
	# Дождевые дорожки на торцевом окне — тоже процедурные и поэтому бесплатны
	# для размера сборки. Они двигаются медленно и не используются как скример.
	var corridor_glass:=Shader.new(); corridor_glass.code="shader_type spatial; render_mode blend_mix,depth_draw_opaque,cull_disabled; float hash(float n){return fract(sin(n)*43758.5453);} void fragment(){ float col=floor(UV.x*34.0); float speed=.035+hash(col)*.045; float y=fract(UV.y+TIME*speed+hash(col)*3.1); float streak=smoothstep(.965,.995,y)*smoothstep(.30,.0,abs(fract(UV.x*34.0)-.5)); ALBEDO=vec3(.035,.055,.078)+vec3(.10,.11,.12)*streak; ALPHA=.30+streak*.22; ROUGHNESS=.24; }"; var cgm:=ShaderMaterial.new(); cgm.shader=corridor_glass; mats["corridor_glass"]=cgm

func box(parent:Node, name:String, pos:Vector3, size:Vector3, material:String, collision:=false) -> MeshInstance3D:
	var mi:=MeshInstance3D.new(); mi.name=name; var mesh:=BoxMesh.new(); mesh.size=size; mi.mesh=mesh; mi.position=pos; mi.material_override=mats[material]; parent.add_child(mi)
	if collision:
		var body:=StaticBody3D.new(); body.name=name+"Collision"; var cs:=CollisionShape3D.new(); var sh:=BoxShape3D.new(); sh.size=size; cs.shape=sh; body.add_child(cs); mi.add_child(body)
	return mi

func cyl(parent:Node,name:String,pos:Vector3,radius:float,height:float,material:String,rot:=Vector3.ZERO) -> MeshInstance3D:
	var mi:=MeshInstance3D.new(); mi.name=name; var mesh:=CylinderMesh.new(); mesh.top_radius=radius; mesh.bottom_radius=radius; mesh.height=height; mesh.radial_segments=12; mi.mesh=mesh; mi.position=pos; mi.rotation=rot; mi.material_override=mats[material]; parent.add_child(mi); return mi

func rounded(parent:Node,name:String,pos:Vector3,size:Vector3,material:String,rot:=Vector3.ZERO)->MeshInstance3D:
	var mi:=MeshInstance3D.new(); mi.name=name; var mesh:=CapsuleMesh.new(); mesh.radius=.5; mesh.height=2.0; mesh.radial_segments=12; mesh.rings=4; mi.mesh=mesh; mi.position=pos; mi.rotation=rot; mi.scale=size; mi.material_override=mats[material]; parent.add_child(mi); return mi

func sphere(parent:Node,name:String,pos:Vector3,size:Vector3,material:String)->MeshInstance3D:
	var mi:=MeshInstance3D.new(); mi.name=name; var mesh:=SphereMesh.new(); mesh.radius=.5; mesh.height=1.0; mesh.radial_segments=10; mesh.rings=5; mi.mesh=mesh; mi.position=pos; mi.scale=size; mi.material_override=mats[material]; parent.add_child(mi); return mi

func torus(parent:Node,name:String,pos:Vector3,inner:float,outer:float,material:String,rot:=Vector3.ZERO,scale_:=Vector3.ONE)->MeshInstance3D:
	var mi:=MeshInstance3D.new(); mi.name=name; var mesh:=TorusMesh.new(); mesh.inner_radius=inner; mesh.outer_radius=outer; mesh.rings=12; mesh.ring_segments=8; mi.mesh=mesh; mi.position=pos; mi.rotation=rot; mi.scale=scale_; mi.material_override=mats[material]; parent.add_child(mi); return mi

func multi_cyl(parent:Node,name:String,positions:Array, radius:float,height:float,material:String,rot:=Vector3.ZERO)->MultiMeshInstance3D:
	var node:=MultiMeshInstance3D.new(); node.name=name; var mesh:=CylinderMesh.new(); mesh.top_radius=radius; mesh.bottom_radius=radius; mesh.height=height; mesh.radial_segments=10; mesh.material=mats[material]; var mm:=MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D; mm.mesh=mesh; mm.instance_count=positions.size(); var basis:=Basis.from_euler(rot)
	for i in range(positions.size()): mm.set_instance_transform(i,Transform3D(basis,positions[i]))
	node.multimesh=mm; parent.add_child(node); return node

func multi_box(parent:Node,name:String,positions:Array,size:Vector3,material:String)->MultiMeshInstance3D:
	var node:=MultiMeshInstance3D.new(); node.name=name; var mesh:=BoxMesh.new(); mesh.size=size; mesh.material=mats[material]; var mm:=MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D; mm.mesh=mesh; mm.instance_count=positions.size()
	for i in range(positions.size()): mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,positions[i]))
	node.multimesh=mm; parent.add_child(node); return node

# MultiMesh из первого меша .glb — для того, что повторяется десятками.
#
# Тридцать секций карниза отдельными узлами — это тридцать узлов и тридцать
# вызовов отрисовки; здесь один. material_override применять НЕЛЬЗЯ: он
# сплющивает все поверхности в один материал, и филёнка панели стала бы цветом
# рамы, а латунная нить карниза — деревом. Поэтому палитра ложится на сам ресурс
# меша, по поверхностям — та же логика, что в apply_model_palette().
#
# Меш у PackedScene общий, так что правка материалов видна всем его копиям. Для
# этих пяти моделей это и нужно: других потребителей у них нет.
func multi_model(parent:Node,name:String,scene:PackedScene,transforms:Array,palette:Dictionary={})->MultiMeshInstance3D:
	var probe:=scene.instantiate() as Node3D
	var found:=probe.find_children("*","MeshInstance3D",true,false)
	var mesh:ArrayMesh=(found[0] as MeshInstance3D).mesh as ArrayMesh
	for surface_index in mesh.get_surface_count():
		var source_material:=mesh.surface_get_material(surface_index)
		var source_name:String=source_material.resource_name if source_material else ""
		var key:String=palette.get(source_name,MODEL_MATERIAL_DEFAULTS.get(source_name,"wood2"))
		if mats.has(key): mesh.surface_set_material(surface_index,mats[key])
	probe.free()
	var node:=MultiMeshInstance3D.new(); node.name=name
	var mm:=MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D; mm.mesh=mesh; mm.instance_count=transforms.size()
	for i in range(transforms.size()): mm.set_instance_transform(i,transforms[i])
	node.multimesh=mm; parent.add_child(node); return node

# Раскладка одинаковых тайлов вдоль стены, пролётами.
#
# fill=true заполняет пролёт целиком: тайлы слегка наезжают друг на друга, шов
# уходит внутрь соседнего тела и не мерцает. Так кладётся карниз, которому рваться
# незачем. fill=false кладёт целое число тайлов и центрует их в пролёте — так
# кладутся панели, у которых поля по краям читаются как обрамление проёма.
# along_x=true — тайлы идут по X (дальняя и ближняя стены), иначе по Z (торцы).
func wall_tiles(out:Array,spans:Array,tile:float,height:float,rot:float,plane:float,along_x:bool,fill:bool)->void:
	var basis:=Basis.from_euler(Vector3(0,rot,0))
	for span in spans:
		var width:float=span[1]-span[0]
		if width<tile*.75: continue
		var count:int=int(ceil(width/tile)) if fill else int(floor(width/tile))
		if count<1: continue
		var step:float=width/count if fill else tile
		var first:float=span[0]+step*.5 if fill else span[0]+(width-tile*count)*.5+tile*.5
		for i in range(count):
			var at:float=first+step*i
			out.append(Transform3D(basis,Vector3(at,height,plane) if along_x else Vector3(plane,height,at)))

func group(name:String,parent:Node=self)->Node3D:
	var n:=Node3D.new(); n.name=name; parent.add_child(n); return n

func model_box_collision(parent:Node,name:String,pos:Vector3,size:Vector3)->void:
	var body:=StaticBody3D.new(); body.name=name; body.position=pos
	var shape_node:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=size; shape_node.shape=shape
	body.add_child(shape_node); parent.add_child(body)

func apply_model_palette(model:Node3D,overrides:Dictionary={}) -> void:
	for child in model.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material:=mesh_instance.mesh.surface_get_material(surface_index)
			var source_name:String=source_material.resource_name if source_material else ""
			var material_key:String=overrides.get(source_name,MODEL_MATERIAL_DEFAULTS.get(source_name,"wood2"))
			if mats.has(material_key): mesh_instance.set_surface_override_material(surface_index,mats[material_key])

func replace_model_material(model:Node3D,name_fragment:String,replacement:Material)->void:
	for child in model.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source:=mesh_instance.mesh.surface_get_material(surface_index)
			if source and source.resource_name.to_lower().contains(name_fragment.to_lower()):
				mesh_instance.set_surface_override_material(surface_index,replacement)

func absolute_vector(value:Vector3)->Vector3:
	return Vector3(abs(value.x),abs(value.y),abs(value.z))

func rotated_box_size(size:Vector3,rotation:Vector3)->Vector3:
	var basis:=Basis.from_euler(rotation)
	return absolute_vector(basis.x)*size.x+absolute_vector(basis.y)*size.y+absolute_vector(basis.z)*size.z

func fitted_model(parent:Node,name:String,scene:PackedScene,anchor:Vector3,target_size:Vector3,rotation:=Vector3.ZERO,palette:Dictionary={},recolor:=true) -> Node3D:
	var root:=group(name,parent); root.add_to_group("downloaded_models")
	var model:=scene.instantiate() as Node3D; model.name=name+"Mesh"; root.add_child(model)
	var raw_bounds:=visual_bounds(model)
	model.scale=Vector3(target_size.x/raw_bounds.size.x,target_size.y/raw_bounds.size.y,target_size.z/raw_bounds.size.z)
	model.rotation=rotation
	model.force_update_transform()
	var fitted_bounds:=visual_bounds(model)
	model.position+=Vector3(anchor.x-fitted_bounds.get_center().x,anchor.y-fitted_bounds.position.y,anchor.z-fitted_bounds.get_center().z)
	if recolor: apply_model_palette(model,palette)
	return root

func fitted_model_flush(parent:Node,name:String,scene:PackedScene,anchor:Vector3,target_size:Vector3,rotation:Vector3,axis:int,wall_plane:float,room_sign:float,palette:Dictionary={}) -> Node3D:
	var root:=fitted_model(parent,name,scene,anchor,target_size,rotation,palette)
	var bounds:=visual_bounds(root)
	# The wall-facing edge, rather than the model center, is snapped to the finish plane.
	# This keeps brackets touching the wall after non-uniform fitting and rotation.
	if axis==Vector3.AXIS_X:
		var back_x:float=bounds.position.x if room_sign>0.0 else bounds.end.x
		root.position.x+=wall_plane-back_x
	else:
		var back_z:float=bounds.position.z if room_sign>0.0 else bounds.end.z
		root.position.z+=wall_plane-back_z
	root.force_update_transform()
	return root

func placed_model(parent:Node,name:String,scene:PackedScene,position:Vector3,rotation:=Vector3.ZERO,palette:Dictionary={}) -> Node3D:
	var root:=group(name,parent); root.add_to_group("downloaded_models")
	var model:=scene.instantiate() as Node3D; model.name=name+"Mesh"; model.position=position; model.rotation=rotation; root.add_child(model)
	apply_model_palette(model,palette)
	return root

func visual_bounds(root:Node3D)->AABB:
	var found:=false
	var minimum:=Vector3.ZERO
	var maximum:=Vector3.ZERO
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		var local_bounds:=mesh_instance.get_aabb()
		for corner_index in range(8):
			var corner:=local_bounds.position+Vector3(
				local_bounds.size.x if corner_index&1 else 0.0,
				local_bounds.size.y if corner_index&2 else 0.0,
				local_bounds.size.z if corner_index&4 else 0.0)
			var point:=mesh_instance.global_transform*corner
			if not found:
				minimum=point; maximum=point; found=true
			else:
				minimum=minimum.min(point); maximum=maximum.max(point)
	return AABB(minimum,maximum-minimum)

func wall(parent:Node,name:String,pos:Vector3,size:Vector3)->void: box(parent,name,pos,size,"wall",true)

# Small picture lamps are visual fixtures only: a brass tube plus a narrow
# emissive underside. They add no Light3D, shadow map, texture, or collision.
func picture_light_x_wall(parent:Node,name:String,pos:Vector3,size:Vector2,inward:float)->void:
	var width:float=clamp(size.x*.62,.34,.68)
	var light_pos:=pos+Vector3(inward*.105,size.y*.5+.145,0)
	cyl(parent,name+"Tube",light_pos,.022,width,"brass",Vector3(PI/2,0,0))
	box(parent,name+"WarmEdge",light_pos+Vector3(inward*.018,-.026,0),Vector3(.030,.022,width*.90),"picture_glow")
	box(parent,name+"Bracket",pos+Vector3(inward*.052,size.y*.5+.145,0),Vector3(.105,.028,.028),"brass")

func picture_light_z_wall(parent:Node,name:String,pos:Vector3,size:Vector2,inward:float)->void:
	var width:float=clamp(size.x*.62,.34,.68)
	var light_pos:=pos+Vector3(0,size.y*.5+.145,inward*.105)
	cyl(parent,name+"Tube",light_pos,.022,width,"brass",Vector3(0,0,PI/2))
	box(parent,name+"WarmEdge",light_pos+Vector3(0,-.026,inward*.018),Vector3(width*.90,.022,.030),"picture_glow")
	box(parent,name+"Bracket",pos+Vector3(0,size.y*.5+.145,inward*.052),Vector3(.028,.028,.105),"brass")

func textured_picture_x_wall(parent:Node,name:String,pos:Vector3,size:Vector2,texture:Texture2D,inward:float)->void:
	var picture:=group(name,parent)
	var canvas:=MeshInstance3D.new(); canvas.name=name+"Canvas"; var quad:=QuadMesh.new(); quad.size=Vector2(size.x-.17,size.y-.17); canvas.mesh=quad; canvas.position=pos+Vector3(inward*.055,0,0); canvas.rotation.y=PI/2
	var art_material:=StandardMaterial3D.new(); art_material.albedo_texture=texture; art_material.roughness=.86; art_material.cull_mode=BaseMaterial3D.CULL_DISABLED; art_material.emission_enabled=true; art_material.emission_texture=texture; art_material.emission=Color.WHITE; art_material.emission_energy_multiplier=.045; canvas.material_override=art_material; picture.add_child(canvas)
	box(picture,name+"OuterTop",pos+Vector3(0,size.y/2,0),Vector3(.07,.085,size.x+.14),"brass"); box(picture,name+"OuterBottom",pos+Vector3(0,-size.y/2,0),Vector3(.07,.085,size.x+.14),"brass")
	box(picture,name+"OuterLeft",pos+Vector3(0,0,-size.x/2),Vector3(.07,size.y+.08,.085),"brass"); box(picture,name+"OuterRight",pos+Vector3(0,0,size.x/2),Vector3(.07,size.y+.08,.085),"brass")
	var liner_pos:=pos+Vector3(inward*.041,0,0)
	box(picture,name+"InnerTop",liner_pos+Vector3(0,size.y/2-.065,0),Vector3(.035,.028,size.x-.02),"wood"); box(picture,name+"InnerBottom",liner_pos+Vector3(0,-size.y/2+.065,0),Vector3(.035,.028,size.x-.02),"wood")
	box(picture,name+"InnerLeft",liner_pos+Vector3(0,0,-size.x/2+.065),Vector3(.035,size.y-.02,.028),"wood"); box(picture,name+"InnerRight",liner_pos+Vector3(0,0,size.x/2-.065),Vector3(.035,size.y-.02,.028),"wood")
	picture_light_x_wall(picture,name+"PictureLight",pos,size,inward)

# Та же лёгкая рама для стен коридора, идущих вдоль X. Картина — обычный Quad,
# а не тяжёлая модель: три полотна вместе весят меньше 55 КБ и не добавляют
# геометрии, коллизий или источников света.
func textured_picture_z_wall(parent:Node,name:String,pos:Vector3,size:Vector2,texture:Texture2D,inward:float)->void:
	var picture:=group(name,parent)
	var canvas:=MeshInstance3D.new(); canvas.name=name+"Canvas"; var quad:=QuadMesh.new(); quad.size=Vector2(size.x-.17,size.y-.17); canvas.mesh=quad; canvas.position=pos+Vector3(0,0,inward*.055)
	var art_material:=StandardMaterial3D.new(); art_material.albedo_texture=texture; art_material.roughness=.88; art_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	# Едва заметная самоподсветка сохраняет детали тёмного масла под локальными
	# бра, но не заставляет холст выглядеть экраном и не добавляет Light3D.
	art_material.emission_enabled=true; art_material.emission_texture=texture; art_material.emission=Color.WHITE; art_material.emission_energy_multiplier=.08
	canvas.material_override=art_material; picture.add_child(canvas)
	box(picture,name+"OuterTop",pos+Vector3(0,size.y/2,0),Vector3(size.x+.14,.085,.07),"brass"); box(picture,name+"OuterBottom",pos+Vector3(0,-size.y/2,0),Vector3(size.x+.14,.085,.07),"brass")
	box(picture,name+"OuterLeft",pos+Vector3(-size.x/2,0,0),Vector3(.085,size.y+.08,.07),"brass"); box(picture,name+"OuterRight",pos+Vector3(size.x/2,0,0),Vector3(.085,size.y+.08,.07),"brass")
	var liner_pos:=pos+Vector3(0,0,inward*.041)
	box(picture,name+"InnerTop",liner_pos+Vector3(0,size.y/2-.065,0),Vector3(size.x-.02,.028,.035),"wood"); box(picture,name+"InnerBottom",liner_pos+Vector3(0,-size.y/2+.065,0),Vector3(size.x-.02,.028,.035),"wood")
	box(picture,name+"InnerLeft",liner_pos+Vector3(-size.x/2+.065,0,0),Vector3(.028,size.y-.02,.035),"wood"); box(picture,name+"InnerRight",liner_pos+Vector3(size.x/2-.065,0,0),Vector3(.028,size.y-.02,.035),"wood")
	picture_light_z_wall(picture,name+"PictureLight",pos,size,inward)

func build_environment()->void:
	var envn:=WorldEnvironment.new(); envn.name="Environment"; var env:=Environment.new(); env.background_mode=Environment.BG_COLOR; env.background_color=Color("050910")
	# Холодная слабая среда и локальные тёплые лампы дают материалам разные
	# температурные планы. Прежняя коричневая заливка окрашивала в сепию и дерево,
	# и стекло, и бельё, поэтому они читались одним плоским материалом.
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("59677d"); env.ambient_light_energy=.15
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC; env.adjustment_enabled=true; env.adjustment_brightness=1.01; env.adjustment_contrast=1.015; env.adjustment_saturation=.94
	envn.environment=env; add_child(envn)

func build_architecture()->void:
	var suite:=group("HotelSuite"); var a:=group("Architecture",suite)
	box(a,"CarpetFloor",Vector3(0,-.08,0),Vector3(8.8,.16,6.4),"carpet",true); box(a,"Ceiling",Vector3(0,2.76,0),Vector3(8.8,.12,6.4),"cream",false)
	# Southern living-room extension doubles its usable depth while private rooms keep their scale.
	box(a,"LivingExtensionFloor",Vector3(1.225,-.08,4.425),Vector3(6.35,.16,2.45),"carpet",true); box(a,"LivingExtensionCeiling",Vector3(1.225,2.76,4.425),Vector3(6.35,.12,2.45),"cream",false)
	wall(a,"WestWall",Vector3(-4.4,1.35,0),Vector3(.18,2.7,6.4))
	# East exterior wall is segmented around the bedroom window instead of hiding it behind a solid collider.
	wall(a,"EastWallNorth",Vector3(4.4,1.35,-2.55),Vector3(.18,2.7,1.3)); wall(a,"EastWallSouth",Vector3(4.4,1.35,2.675),Vector3(.18,2.7,5.95)); wall(a,"EastWallBelowWindow",Vector3(4.4,.325,-1.1),Vector3(.18,.65,1.6)); wall(a,"EastWallAboveWindow",Vector3(4.4,2.475,-1.1),Vector3(.18,.45,1.6))
	# North exterior with a true 0.90 m entrance opening and a solid lintel above it.
	wall(a,"NorthA",Vector3(-3.75,1.35,-3.2),Vector3(1.3,2.7,.18)); wall(a,"NorthB",Vector3(1.10,1.35,-3.2),Vector3(6.6,2.7,.18)); wall(a,"EntranceHeader",Vector3(-2.65,2.40,-3.2),Vector3(.90,.60,.18))
	fitted_model(a,"EntranceDoorModel",ENTRANCE_DOOR_MODEL,Vector3(-2.65,0,-3.13),Vector3(.9,2.1,.12),Vector3.ZERO,{"wood":"wood","metal":"brass"}); model_box_collision(a,"EntranceDoorCollision",Vector3(-2.65,1.05,-3.13),Vector3(.9,2.1,.12))
	cyl(a,"Peephole",Vector3(-2.65,1.82,-2.995),.035,.035,"brass",Vector3(PI/2,0,0))
	box(a,"RoomNumberPlate",Vector3(-2.65,1.45,-2.995),Vector3(.40,.17,.025),"brass")
	var room_number:=Label3D.new(); room_number.name="RoomNumber1604"; room_number.text="1604"; room_number.font_size=48; room_number.pixel_size=.0025; room_number.modulate=Color("21140d"); room_number.position=Vector3(-2.65,1.45,-2.975); a.add_child(room_number)
	# Bathroom keeps its original south wall; the living-room facade moves 2.45 m farther out.
	wall(a,"SouthA",Vector3(-3.2,1.35,3.2),Vector3(2.4,2.7,.18)); wall(a,"LivingSouthRight",Vector3(3.45,1.35,5.65),Vector3(1.9,2.7,.18)); wall(a,"LivingSouthLeftPier",Vector3(-1.3,1.35,5.65),Vector3(1.4,2.7,.18)); wall(a,"LivingSouthRightPier",Vector3(2.35,1.35,5.65),Vector3(.3,2.7,.18)); wall(a,"LivingSouthBelowWindow",Vector3(.8,.3875,5.65),Vector3(2.8,.775,.18)); wall(a,"LivingSouthAboveWindow",Vector3(.8,2.4125,5.65),Vector3(2.8,.575,.18)); box(a,"LivingWindow",Vector3(.8,1.45,5.63),Vector3(2.8,1.35,.035),"window_glass")
	wall(a,"LivingExtensionWestWall",Vector3(-1.95,1.35,4.425),Vector3(.14,2.7,2.45))
	var living_window_verticals:Array=[]; for x in [-.6,.8,2.2]: living_window_verticals.append(Vector3(x,1.45,5.505))
	multi_box(a,"LivingWindowVerticals",living_window_verticals,Vector3(.075,1.42,.10),"wood2")
	var living_window_horizontals:Array=[]; for y in [.76,1.45,2.14]: living_window_horizontals.append(Vector3(.8,y,5.505))
	multi_box(a,"LivingWindowHorizontals",living_window_horizontals,Vector3(2.88,.075,.10),"wood2")
	fitted_model(a,"LivingWindowSill",WINDOW_SILL_MODEL,Vector3(.8,.655,5.48),Vector3(1.95,.12,.18),Vector3.ZERO,{"wood":"wood2","brass":"brass"})
	# Main partitions, with door gaps.
	# Clear internal openings: bathroom 0.80 m, bedroom 0.90 m, living room 0.90 m.
	wall(a,"HallBathWallA",Vector3(-3.825,1.35,-.95),Vector3(1.15,2.7,.14)); wall(a,"HallBathWallB",Vector3(-2.20,1.35,-.95),Vector3(.50,2.7,.14))
	wall(a,"VerticalPartition",Vector3(-1.95,1.35,1.1),Vector3(.14,2.7,4.2)); wall(a,"HallBedroomA",Vector3(-1.95,1.35,-2.75),Vector3(.14,2.7,.90)); wall(a,"HallBedroomB",Vector3(-1.95,1.35,-1.175),Vector3(.14,2.7,.45))
	wall(a,"BedLivingA",Vector3(-1.475,1.35,.75),Vector3(.95,2.7,.14)); wall(a,"BedLivingB",Vector3(2.15,1.35,.75),Vector3(4.50,2.7,.14))
	wall(a,"BathroomDoorHeader",Vector3(-2.85,2.40,-.95),Vector3(.80,.60,.14)); wall(a,"BedroomDoorHeader",Vector3(-1.95,2.40,-1.85),Vector3(.14,.60,.90)); wall(a,"LivingDoorHeader",Vector3(-.55,2.40,.75),Vector3(.90,.60,.14))
	# Window on east bedroom wall.
	box(a,"BedroomWindow",Vector3(4.31,1.45,-1.1),Vector3(.035,1.6,1.6),"window_glass")
	var bedroom_window_verticals:Array=[]; for z in [-1.9,-1.1,-.3]: bedroom_window_verticals.append(Vector3(4.18,1.45,z))
	multi_box(a,"BedroomWindowVerticals",bedroom_window_verticals,Vector3(.10,1.68,.075),"wood2")
	var bedroom_window_horizontals:Array=[]; for y in [.64,1.45,2.26]: bedroom_window_horizontals.append(Vector3(4.18,y,-1.1))
	multi_box(a,"BedroomWindowHorizontals",bedroom_window_horizontals,Vector3(.10,.075,1.68),"wood2")
	fitted_model(a,"BedroomWindowSill",WINDOW_SILL_MODEL,Vector3(4.20,.655,-1.1),Vector3(.76,.12,.18),Vector3(0,PI/2,0),{"wood":"wood2","brass":"brass"})
	# Blender-built open doors use exact metre-scale geometry, so the leaves remain legible and never seal the passage.
	placed_model(a,"BedroomOpenDoor",INTERIOR_OPEN_DOOR_MODEL,Vector3(-1.95,0,-1.85),Vector3(0,PI/2,0),{"wood":"wood2","woodDark":"wood","brass":"brass"})
	placed_model(a,"BathroomOpenDoor",INTERIOR_OPEN_DOOR_RIGHT_MODEL,Vector3(-2.85,0,-.95),Vector3.ZERO,{"wood":"wood2","woodDark":"wood","brass":"brass"})
	placed_model(a,"LivingOpenDoor",INTERIOR_OPEN_DOOR_MODEL,Vector3(-.55,0,.75),Vector3.ZERO,{"wood":"wood2","woodDark":"wood","brass":"brass"})
	# Baseboards follow partition segments without bridging door openings.
	box(a,"HallBathBaseA",Vector3(-3.825,.12,-.86),Vector3(1.15,.22,.06),"wood2"); box(a,"HallBathBaseB",Vector3(-2.20,.12,-.86),Vector3(.50,.22,.06),"wood2")
	box(a,"BedLivingBaseA",Vector3(-1.475,.12,.84),Vector3(.95,.22,.06),"wood2"); box(a,"BedLivingBaseB",Vector3(2.15,.12,.84),Vector3(4.50,.22,.06),"wood2")
	# Baseboards.
	box(a,"NorthBaseboard",Vector3(0,.12,-3.05),Vector3(8.5,.24,.08),"wood2"); box(a,"BathroomSouthBaseboard",Vector3(-3.2,.12,3.05),Vector3(2.25,.24,.08),"wood2"); box(a,"LivingSouthBaseboard",Vector3(1.225,.12,5.50),Vector3(6.1,.24,.08),"wood2")
	box(a,"WestBaseboard",Vector3(-4.28,.12,0),Vector3(.08,.24,6.0),"wood2"); box(a,"EastBaseboard",Vector3(4.28,.12,1.225),Vector3(.08,.24,8.35),"wood2"); box(a,"ExtensionWestBaseboard",Vector3(-1.86,.12,4.425),Vector3(.08,.24,2.25),"wood2")

func lamp(parent:Node,name:String,p:Vector3)->void:
	fitted_model(parent,name,TABLE_LAMP_MODEL,p,Vector3(.34,.74,.34),Vector3.ZERO,{"metal":"brass","lamp":"lamp_glow","woodDark":"wood","cream":"shade"})

func wall_switch(parent:Node,name:String,p:Vector3,rotation:=PI/2)->void:
	fitted_model(parent,name,WALL_SWITCH_MODEL,p-Vector3(0,.085,0),Vector3(.10,.17,.035),Vector3(0,rotation,0),{"porcelain":"cream","brass":"brass","screen":"screen"})

func wall_outlet(parent:Node,name:String,p:Vector3,rotation:=0.0)->void:
	fitted_model(parent,name,WALL_OUTLET_MODEL,p-Vector3(0,.08,0),Vector3(.115,.16,.035),Vector3(0,rotation,0),{"porcelain":"cream","cream":"cream","brass":"brass","screen":"screen"})

func table(parent:Node,name:String,p:Vector3,size:Vector3)->Node3D:
	var g:=group(name,parent); box(g,"Top",p+Vector3(0,size.y,0),Vector3(size.x,.09,size.z),"wood2",true)
	for dx in [-1,1]: for dz in [-1,1]: box(g,"Leg",p+Vector3(dx*(size.x/2-.07),size.y/2,dz*(size.z/2-.07)),Vector3(.09,size.y,.09),"wood")
	return g

func build_hallway()->void:
	var h:=group("Hallway",get_node("HotelSuite"))
	var t:=fitted_model(h,"ConsoleTable",CONSOLE_TABLE_MODEL,Vector3(-4.05,0,-1.72),Vector3(.82,.78,.35),Vector3(0,PI/2,0),{"wood":"wood_lacquer","metal":"brass"})
	model_box_collision(t,"ConsoleCollision",Vector3(-4.05,.39,-1.72),Vector3(.35,.78,.82))
	lamp(t,"EntryLamp",Vector3(-4.02,.78,-1.92))
	fitted_model(t,"HallTablePlant",PLANT_SMALL_MODEL,Vector3(-4.02,.78,-1.52),Vector3(.24,.38,.24),Vector3.ZERO,{"plant":"leaf","wood":"brass"})
	fitted_model(h,"EntryRug",ENTRY_RUG_MODEL,Vector3(-2.72,.012,-2.48),Vector3(.90,.025,.60),Vector3(0,PI/2,0),{"wood":"beige"})
	textured_picture_x_wall(h,"HallLakePainting",Vector3(-4.255,1.93,-1.72),Vector2(.82,.62),HALL_PAINTING_TEXTURE,1.0)
	wall_switch(h,"HallSwitch",Vector3(-2.05,1.25,-2.65),-PI/2)
	wall_outlet(h,"HallOutlet",Vector3(-2.05,.32,-2.65),-PI/2)

func bed(parent:Node,p:Vector3)->void:
	var b:=fitted_model(parent,"Bed",BED_MODEL,p,Vector3(1.90,1.45,2.05),Vector3.ZERO,{"wood":"wood_lacquer","woodDark":"wood","carpet":"olive","carpetWhite":"linen","metal":"brass"}); model_box_collision(b,"BedBaseCollision",p+Vector3(0,.34,.08),Vector3(1.90,.60,1.90)); model_box_collision(b,"HeadboardCollision",p+Vector3(0,.72,-.98),Vector3(1.90,1.44,.12))

func build_bedroom()->void:
	var r:=group("Bedroom",get_node("HotelSuite")); bed(r,Vector3(1.25,0,-2.0))
	for x in [.0,2.5]: var side_name:="BedsideTableLeft" if x<1.0 else "BedsideTableRight"; var n:=fitted_model(r,side_name,BEDSIDE_TABLE_MODEL,Vector3(x,0,-2.82),Vector3(.5,.55,.45),Vector3.ZERO,{"wood":"wood_lacquer","metal":"brass","_defaultMat":"wood"}); model_box_collision(n,side_name+"Collision",Vector3(x,.275,-2.82),Vector3(.5,.55,.45)); var lamp_x:float=x if x<1.0 else 2.37; lamp(n,"BedLamp",Vector3(lamp_x,.55,-2.82))
	fitted_model(r,"VintageTelephone",PHONE_MODEL,Vector3(2.61,.56,-2.78),Vector3(.28,.25,.22),Vector3.ZERO,{"screen":"screen","brass":"brass"})
	var w:=fitted_model(r,"Wardrobe",WARDROBE_MODEL,Vector3(-1.55,0,-.15),Vector3(1.2,2.1,.6),Vector3(0,PI/2,0),{"wood":"wood_lacquer","metal":"brass"}); model_box_collision(w,"WardrobeCollision",Vector3(-1.55,1.05,-.15),Vector3(.6,2.1,1.2))
	var bed_painting:=fitted_model(r,"MeaningfulBedPainting",FANCY_FRAME_MODEL,Vector3(1.25,1.88,-3.08),Vector3(.98,.64,.08),Vector3.ZERO,{},false)
	var bed_canvas:=StandardMaterial3D.new(); bed_canvas.albedo_texture=BEDROOM_GARDEN_TEXTURE; bed_canvas.roughness=.90; bed_canvas.emission_enabled=true; bed_canvas.emission_texture=BEDROOM_GARDEN_TEXTURE; bed_canvas.emission=Color.WHITE; bed_canvas.emission_energy_multiplier=.035
	replace_model_material(bed_painting,"canvas",bed_canvas)
	picture_light_z_wall(r,"BedPaintingLight",Vector3(1.25,1.88,-3.08),Vector2(.98,.64),1.0)
	chair(r,Vector3(3.48,0,.15),-2.35,"BedroomReadingChair")
	var reading_table:=fitted_model(r,"BedroomReadingTable",BEDSIDE_TABLE_MODEL,Vector3(3.82,0,.45),Vector3(.44,.48,.40),Vector3.ZERO,{"wood":"wood_lacquer","metal":"brass"}); model_box_collision(reading_table,"BedroomReadingTableCollision",Vector3(3.82,.24,.45),Vector3(.44,.48,.40))
	fitted_model(reading_table,"BedroomBooks",BOOKS_MODEL,Vector3(3.82,.48,.45),Vector3(.25,.10,.18),Vector3.ZERO,{"carpetDarker":"painting","carpetWhite":"cream","metal":"brass","plant":"olive"})
	curtains(r,Vector3(4.18,1.45,-1.1),true); radiator(r,Vector3(4.12,.42,-1.1),true,.78); wall_outlet(r,"BedroomOutlet",Vector3(3.3,.32,-3.08))

func sofa(parent:Node,p:Vector3,rotation:=0.0)->void:
	var target:=Vector3(1.90,.90,.86)
	var s:=fitted_model(parent,"Sofa",SOFA_MODEL,p,target,Vector3(0,rotation,0),{"carpet":"beige","carpetWhite":"linen","wood":"wood2"})
	var collision_size:=rotated_box_size(Vector3(1.82,.82,.76),Vector3(0,rotation,0))
	model_box_collision(s,"SofaCollision",p+Vector3(0,.41,0),collision_size)

func toilet(parent:Node,p:Vector3)->void:
	var t:=fitted_model(parent,"Toilet",BATHROOM_TOILET_MODEL,p,Vector3(.50,.82,.72),Vector3(0,PI/2,0),{"porcelain":"porcelain","cream":"cream","brass":"brass","screen":"screen"})
	model_box_collision(t,"ToiletCollision",p+Vector3(.04,.36,0),Vector3(.66,.72,.48))

func chair(parent:Node,p:Vector3,rotation:=0.0,name:="OliveArmchair")->void:
	var target:=Vector3(.84,.90,.84)
	var c:=fitted_model(parent,name,ARMCHAIR_MODEL,p,target,Vector3(0,rotation,0),{"carpet":"olive","carpetWhite":"olive","wood":"wood2"})
	model_box_collision(c,name+"Collision",p+Vector3(0,.42,0),Vector3(.76,.84,.76))

func desk_chair(parent:Node,p:Vector3)->void:
	var c:=fitted_model(parent,"DeskChair",DESK_CHAIR_MODEL,p,Vector3(.46,.90,.45),Vector3(0,PI/2,0),{"wood":"wood2","carpet":"olive"}); model_box_collision(c,"DeskChairCollision",p+Vector3(0,.45,0),Vector3(.45,.90,.46))

func build_living_room()->void:
	var r:=group("LivingRoom",get_node("HotelSuite"))
	# The seating axis is now explicit: sofa east, television west, table centered between them.
	sofa(r,Vector3(3.70,0,3.15),-PI/2)
	chair(r,Vector3(2.20,0,4.85),-2.35,"LivingArmchair")
	var coffee:=fitted_model(r,"CoffeeTable",COFFEE_TABLE_MODEL,Vector3(1.05,0,3.15),Vector3(1.20,.42,.70),Vector3(0,PI/2,0),{"wood":"wood_lacquer"}); model_box_collision(coffee,"CoffeeTableCollision",Vector3(1.05,.21,3.15),Vector3(.70,.42,1.20))
	var tv:=group("TVArea",r); var tv_stand:=fitted_model(tv,"TVStand",TV_STAND_MODEL,Vector3(-1.70,0,3.15),Vector3(1.40,.76,.45),Vector3(0,PI/2,0),{"wood":"wood_lacquer","metal":"brass"}); model_box_collision(tv_stand,"TVStandCollision",Vector3(-1.70,.38,3.15),Vector3(.45,.76,1.40)); fitted_model(tv,"Television",TELEVISION_MODEL,Vector3(-1.82,.76,3.15),Vector3(1.25,.85,.08),Vector3(0,PI/2,0),{"metalDark":"screen","metal":"metal"})
	var d:=fitted_model(r,"WritingDesk",DESK_MODEL,Vector3(3.98,0,1.55),Vector3(1.35,.76,.58),Vector3(0,-PI/2,0),{"wood":"wood_lacquer","metal":"brass"}); model_box_collision(d,"DeskCollision",Vector3(3.98,.38,1.55),Vector3(.58,.76,1.35)); lamp(d,"DeskLamp",Vector3(4.02,.76,1.12)); fitted_model(d,"WritingSet",WRITING_SET_MODEL,Vector3(3.70,.79,1.62),Vector3(.38,.07,.28),Vector3(0,PI/2,0),{"painting":"painting","cream":"cream","brass":"brass"}); desk_chair(r,Vector3(3.28,0,1.55))
	var m:=fitted_model(r,"Minibar",MINIBAR_MODEL,Vector3(4.05,0,4.68),Vector3(.88,.96,.50),Vector3(0,-PI/2,0),{"metalLight":"wood_lacquer","metalDark":"screen","glass":"glass","metal":"brass"}); model_box_collision(m,"MinibarCollision",Vector3(4.05,.48,4.68),Vector3(.50,.96,.88))
	fitted_model(m,"CoffeeMachine",COFFEE_MACHINE_MODEL,Vector3(3.88,.98,4.45),Vector3(.30,.36,.26),Vector3(0,-PI/2,0),{"metalMedium":"screen","metal":"chrome","carpetWhite":"porcelain"})
	fitted_model(m,"CoffeeService",COFFEE_SERVICE_MODEL,Vector3(3.78,.98,4.84),Vector3(.44,.22,.28),Vector3(0,PI/2,0),{"wood":"wood","porcelain":"porcelain","screen":"screen","brass":"brass"})
	fitted_model(r,"LivingMirror",MIRROR_MODEL,Vector3(4.23,1.10,4.68),Vector3(.72,.92,.08),Vector3(0,-PI/2,0),{"wood":"wood2","metal":"brass","glass":"mirror"})
	curtains(r,Vector3(.8,1.45,5.49),false); radiator(r,Vector3(.8,.42,5.43),false,1.2)
	textured_picture_x_wall(r,"LivingHotelPainting",Vector3(4.255,1.72,3.15),Vector2(1.32,.66),LIVING_PAINTING_TEXTURE,-1.0)
	wall_outlet(r,"LivingDeskOutlet",Vector3(4.28,.32,1.05),-PI/2)
	fitted_model(r,"GrandWallClock",GRAND_WALL_CLOCK_MODEL,Vector3(2.28,1.34,.835),Vector3(.94,.98,.13),Vector3.ZERO,{"wood":"wood_lacquer","woodDark":"wood","brass":"brass","cream":"cream","screen":"screen"})

func curtains(parent:Node,p:Vector3,east:bool)->void:
	if east:
		box(parent,"Tulle",p+Vector3(-.08,0,0),Vector3(.035,1.95,1.25),"tulle")
		box(parent,"CurtainLeft",p+Vector3(-.03,0,-.62),Vector3(.18,2.25,.4),"olive"); box(parent,"CurtainRight",p+Vector3(-.03,0,.62),Vector3(.18,2.25,.4),"olive")
		var folds:Array=[]
		for side in [-1,1]:
			for i in range(4): folds.append(p+Vector3(-.15,0,side*(.47+float(i)*.1)))
		multi_cyl(parent,"CurtainFolds",folds,.055,2.2,"olive")
		fitted_model(parent,"BedroomCurtainRod",CURTAIN_ROD_MODEL,p+Vector3(-.18,1.05,0),Vector3(1.75,.18,.18),Vector3(0,PI/2,0),{"brass":"brass","woodDark":"wood"})
	else:
		box(parent,"Tulle",p+Vector3(0,0,-.08),Vector3(2.35,1.95,.035),"tulle")
		box(parent,"CurtainLeft",p+Vector3(-1.25,0,-.03),Vector3(.45,2.25,.18),"olive"); box(parent,"CurtainRight",p+Vector3(1.25,0,-.03),Vector3(.45,2.25,.18),"olive")
		var folds:Array=[]
		for side in [-1,1]:
			for i in range(4): folds.append(p+Vector3(side*(1.08+float(i)*.1),0,-.15))
		multi_cyl(parent,"CurtainFolds",folds,.055,2.2,"olive")
		fitted_model(parent,"LivingCurtainRod",CURTAIN_ROD_MODEL,p+Vector3(0,1.05,-.19),Vector3(3.05,.18,.18),Vector3.ZERO,{"brass":"brass","woodDark":"wood"})

func radiator(parent:Node,p:Vector3,east:bool,width:float)->void:
	var rotation:=Vector3(0,PI/2,0) if east else Vector3.ZERO
	fitted_model(parent,"Radiator",RADIATOR_MODEL,Vector3(p.x,.05,p.z),Vector3(width,.60,.20),rotation,{"metal":"metal","brass":"brass"})

func build_bathroom()->void:
	var r:=group("Bathroom",get_node("HotelSuite"))
	box(r,"TileFloor",Vector3(-3.2,.01,1.12),Vector3(2.35,.04,4.0),"tile")
	# A clear central aisle now runs from the inward-opening door to the bath.
	var vanity:=fitted_model(r,"BathroomVanity",BATHROOM_VANITY_MODEL,Vector3(-4.02,0,-.30),Vector3(1.08,1.16,.56),Vector3(0,PI/2,0),{"wood":"wood_lacquer","woodDark":"wood","porcelain":"porcelain","cream":"cream","brass":"brass","screen":"screen","chrome":"chrome"})
	model_box_collision(vanity,"VanityCollision",Vector3(-4.02,.45,-.30),Vector3(.56,.90,1.06))
	box(r,"VanityMirrorBacking",Vector3(-4.2275,1.69,-.30),Vector3(.015,1.08,.82),"wood2")
	fitted_model_flush(r,"BathroomMirror",BATHROOM_MIRROR_MODEL,Vector3(-4.18,1.18,-.30),Vector3(.76,1.02,.075),Vector3(0,PI/2,0),Vector3.AXIS_X,-4.225,1.0,{"wood":"wood2","brass":"brass","glass":"mirror"})
	for i in range(2):
		var lamp_z:float=-.78 if i==0 else .18
		fitted_model_flush(r,"VanitySconce%d" % i,BATHROOM_SCONCE_MODEL,Vector3(-4.16,1.58,lamp_z),Vector3(.19,.46,.20),Vector3(0,PI/2,0),Vector3.AXIS_X,-4.225,1.0,{"brass":"brass","cream":"shade","lamp":"lamp_glow"})
	fitted_model(r,"Wastebasket",BATH_WASTEBASKET_MODEL,Vector3(-3.98,0,.43),Vector3(.27,.42,.27),Vector3.ZERO,{"brass":"brass","screen":"screen"})
	toilet(r,Vector3(-3.89,0,.96))
	fitted_model_flush(r,"ToiletPaperHolder",BATH_TOILET_PAPER_MODEL,Vector3(-4.245,.67,1.52),Vector3(.38,.42,.20),Vector3(0,PI/2,0),Vector3.AXIS_X,-4.225,1.0,{"brass":"brass","linen":"linen","cream":"cream","screen":"screen"})
	fitted_model_flush(r,"HandTowelRing",BATH_HAND_TOWEL_MODEL,Vector3(-2.055,.88,.40),Vector3(.42,.58,.18),Vector3(0,-PI/2,0),Vector3.AXIS_X,-2.02,-1.0,{"brass":"brass","linen":"linen","cream":"cream"})
	fitted_model_flush(r,"BathTowelRack",BATH_TOWEL_RACK_MODEL,Vector3(-2.055,.80,1.25),Vector3(.82,.92,.30),Vector3(0,-PI/2,0),Vector3.AXIS_X,-2.02,-1.0,{"brass":"brass","linen":"linen","cream":"beige"})
	var tub:=fitted_model(r,"Bathtub",BATHROOM_BATHTUB_MODEL,Vector3(-3.18,0,2.71),Vector3(1.74,.70,.74),Vector3(0,PI,0),{"porcelain":"porcelain","cream":"cream","brass":"brass","chrome":"chrome","glass":"glass"})
	model_box_collision(tub,"BathtubCollision",Vector3(-3.18,.35,2.71),Vector3(1.74,.70,.74))
	fitted_model_flush(r,"ShowerFixture",BATH_SHOWER_FIXTURE_MODEL,Vector3(-3.70,.72,3.04),Vector3(.47,1.55,.42),Vector3(0,PI,0),Vector3.AXIS_Z,3.055,-1.0,{"brass":"brass","chrome":"chrome","screen":"screen"})
	# A half-width screen keeps the shower usable without turning the tub into a bulky cabin.
	box(r,"BathScreenGlass",Vector3(-3.70,1.36,2.315),Vector3(.78,1.34,.025),"glass")
	box(r,"BathScreenTopRail",Vector3(-3.70,2.035,2.30),Vector3(.84,.035,.045),"brass")
	for x in [-4.10,-3.30]: box(r,"BathScreenPost",Vector3(x,1.36,2.30),Vector3(.035,1.39,.045),"brass")
	box(r,"BathMat",Vector3(-3.18,.035,2.03),Vector3(1.25,.035,.46),"beige")
	fitted_model_flush(r,"BathroomOutlet",WALL_OUTLET_MODEL,Vector3(-3.58,1.14,-.865),Vector3(.115,.16,.035),Vector3.ZERO,Vector3.AXIS_Z,-.875,1.0,{"porcelain":"cream","cream":"cream","brass":"brass","screen":"screen"})

func add_light(parent:Node,name:String,p:Vector3,color:Color,energy:float,range_:float,shadows:=false)->void:
	var l:=OmniLight3D.new(); l.name=name; l.position=p; l.light_color=color; l.light_energy=energy; l.omni_range=range_; l.shadow_enabled=shadows
	if shadows: l.shadow_opacity=.52; l.shadow_blur=1.35
	parent.add_child(l)

func build_lights()->void:
	# В спальне источник опущен к прикроватным лампам: кровать получает локальный
	# тёплый остров вместо равномерного потолочного пересвета, а лунная заливка
	# отделяет тёмное дерево и шторы по краям.
	var l:=group("Lights",get_node("HotelSuite")); add_light(l,"BedroomAmber",Vector3(1.25,1.35,-2.48),Color("f2bc7d"),.40,3.35,true); add_light(l,"LivingAmber",Vector3(.9,1.95,3.7),Color("efb876"),.50,4.7,true); add_light(l,"HallAmber",Vector3(-3.0,1.85,-2.0),Color("e7b879"),.31,2.65,false); add_light(l,"BathroomSconce",Vector3(-3.92,1.82,-.40),Color("efd2a4"),.42,2.8,true)
	# The visible ceiling fixtures also need their own pools of light. Previously
	# the switch changed only the room fill, so the bedroom chandelier appeared
	# unchanged even though the interaction state toggled.
	add_light(l,"HallCeiling",Vector3(-3.05,2.18,-2.05),Color("f2c486"),.18,2.45,false); add_light(l,"BedroomCeiling",Vector3(1.2,2.18,-1.3),Color("f4c98d"),.62,3.4,true); add_light(l,"BathroomCeiling",Vector3(-3.25,2.18,1.0),Color("ead8b8"),.18,2.35,false); add_light(l,"LivingCeiling",Vector3(.8,2.18,3.7),Color("f0c181"),.22,2.8,false)
	# Мягкая заливка гостиной перенесена от уже светлой восточной стены к ТВ и
	# дивану: она проявляет древесную фактуру и ковёр, не включая сам экран.
	add_light(l,"LivingSoftFill",Vector3(-.25,1.30,3.10),Color("d6b68e"),.21,3.45,false); add_light(l,"BathroomSoftFill",Vector3(-2.45,1.65,1.9),Color("ddd4c4"),.2,2.7,false)
	# Moon fills sit just inside the panes so folds and wooden mullions catch a
	# cool rim; their short range keeps the warm centre of each room intact.
	add_light(l,"BedroomMoonFill",Vector3(4.08,1.72,-1.1),Color("8498bb"),.22,3.05,false); add_light(l,"LivingMoonFill",Vector3(.8,1.72,5.53),Color("7d91b6"),.16,3.15,false)

func build_finishing_details()->void:
	var suite:=get_node("HotelSuite"); var p:=group("Props",suite)
	# One Blender mesh contains four exact continuous loops with true mitered corners.
	var suite_crown:=placed_model(p,"SuiteCrownMolding",SUITE_CROWN_MOLDING_MODEL,Vector3.ZERO,Vector3.ZERO,{"wood":"wood2","brass":"brass"})
	apply_model_palette(suite_crown,{'wood':'crown','brass':'crown_accent'})
	# Thin stepped faces near the ceiling do not cast useful shadows and otherwise create shadow-map combing at grazing angles.
	for crown_mesh in suite_crown.find_children("*","MeshInstance3D",true,false):
		var crown_instance:=crown_mesh as MeshInstance3D
		crown_instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface_index in crown_instance.mesh.get_surface_count():
			var crown_material:=crown_instance.get_surface_override_material(surface_index) as BaseMaterial3D
			if crown_material:
				var two_sided:=crown_material.duplicate() as BaseMaterial3D
				two_sided.cull_mode=BaseMaterial3D.CULL_DISABLED
				crown_instance.set_surface_override_material(surface_index,two_sided)
	# Flush-mount cream-and-brass ceiling fixtures.
	var ceiling_positions:=[Vector3(-3.05,2.39,-2.05),Vector3(1.2,2.39,-1.3),Vector3(.8,2.39,3.7),Vector3(-3.25,2.39,1.0)]
	for i in range(ceiling_positions.size()): fitted_model(p,"CeilingLamp%d" % i,CEILING_LAMP_MODEL,ceiling_positions[i],Vector3(.42,.23,.42),Vector3(PI,0,0),{"lamp":"lamp_glow","metal":"brass"})
	# Living-room rug and recognizable ready-made table details.
	fitted_model(p,"LivingRug",LIVING_RUG_MODEL,Vector3(1.10,.015,3.20),Vector3(3.15,.035,2.45),Vector3.ZERO,{"carpet":"beige","carpetDarker":"rug_border"})
	fitted_model(p,"CoffeeTablePlant",POTTED_PLANT_MODEL,Vector3(1.08,.43,2.92),Vector3(.28,.48,.28),Vector3.ZERO,{"plant":"leaf","wood":"brass","woodDark":"wood"})
	fitted_model(p,"CoffeeTableBooks",BOOKS_MODEL,Vector3(1.04,.43,3.43),Vector3(.25,.10,.20),Vector3(0,.18,0),{"carpetDarker":"painting","carpetWhite":"cream","metal":"brass","plant":"olive"})
	# Bathroom tile field, courses and warm grout lines on the west wall.
	box(p,"BathroomTileWall",Vector3(-4.275,1.35,1.15),Vector3(.03,2.5,3.8),"tile")
	var grout_h:Array=[]
	for y in range(1,6): grout_h.append(Vector3(-4.25,float(y)*.45,1.15))
	multi_box(p,"BathroomGroutHorizontal",grout_h,Vector3(.025,.012,3.8),"cream")
	var grout_v:Array=[]
	for z in range(-2,7): grout_v.append(Vector3(-4.245,1.35,-.7+float(z)*.45))
	multi_box(p,"BathroomGroutVertical",grout_v,Vector3(.03,2.5,.012),"cream")
	# The wet wall behind the bath uses the same tile module and batched grout grid.
	box(p,"BathroomSouthTileWall",Vector3(-3.175,1.35,3.105),Vector3(2.25,2.5,.03),"tile")
	var south_grout_h:Array=[]
	for y in range(1,6): south_grout_h.append(Vector3(-3.175,float(y)*.45,3.08))
	multi_box(p,"BathroomSouthGroutHorizontal",south_grout_h,Vector3(2.25,.012,.025),"cream")
	var south_grout_v:Array=[]
	for i in range(5): south_grout_v.append(Vector3(-4.075+float(i)*.45,1.35,3.075))
	multi_box(p,"BathroomSouthGroutVertical",south_grout_v,Vector3(.012,2.5,.03),"cream")
	# Layered distant night views: sky, irregular skyline, warm/cool windows and a visible moon.
	var city:=group("NightCity",p)
	box(city,"SouthNightSky",Vector3(.8,2.35,9.0),Vector3(9.0,4.7,.08),"night_sky")
	box(city,"SouthTowerA",Vector3(-1.75,.78,8.72),Vector3(1.15,1.56,.28),"city_dark"); box(city,"SouthTowerB",Vector3(-.45,.58,8.68),Vector3(1.20,1.16,.34),"city_mid"); box(city,"SouthTowerC",Vector3(.85,.94,8.73),Vector3(1.28,1.88,.26),"city_dark"); box(city,"SouthTowerD",Vector3(2.22,.70,8.69),Vector3(1.10,1.40,.32),"city_mid"); box(city,"SouthTowerE",Vector3(3.35,.48,8.74),Vector3(.95,.96,.24),"city_dark")
	cyl(city,"SouthMoon",Vector3(2.45,2.12,8.60),.21,.035,"moon",Vector3(PI/2,0,0))
	var south_warm:=[Vector3(-1.95,.55,8.53),Vector3(-1.55,1.02,8.53),Vector3(-.72,.42,8.49),Vector3(.55,.62,8.52),Vector3(1.00,1.22,8.52),Vector3(2.02,.52,8.49),Vector3(2.43,.96,8.49)]
	var south_cool:=[Vector3(-1.55,.72,8.52),Vector3(-.25,.78,8.48),Vector3(.62,1.48,8.52),Vector3(2.15,.74,8.48),Vector3(3.20,.35,8.53)]
	multi_box(city,"SouthWarmWindows",south_warm,Vector3(.13,.10,.025),"window_warm"); multi_box(city,"SouthCoolWindows",south_cool,Vector3(.11,.08,.025),"window_cool")
	box(city,"EastNightSky",Vector3(8.2,2.35,-1.1),Vector3(.08,4.7,8.0),"night_sky")
	box(city,"EastTowerA",Vector3(7.90,.72,-2.15),Vector3(.28,1.44,1.05),"city_mid"); box(city,"EastTowerB",Vector3(7.86,1.02,-.92),Vector3(.36,2.04,1.10),"city_dark"); box(city,"EastTowerC",Vector3(7.91,.62,.35),Vector3(.26,1.24,1.15),"city_mid")
	var east_warm:=[Vector3(7.68,.48,-2.35),Vector3(7.68,.92,-2.05),Vector3(7.65,.58,-1.15),Vector3(7.65,1.28,-.82),Vector3(7.69,.42,.18)]
	var east_cool:=[Vector3(7.67,.70,-1.85),Vector3(7.64,1.58,-1.02),Vector3(7.68,.78,.42)]
	multi_box(city,"EastWarmWindows",east_warm,Vector3(.025,.10,.13),"window_warm"); multi_box(city,"EastCoolWindows",east_cool,Vector3(.025,.08,.11),"window_cool")
	# Switches and outlets anchor the scale throughout the suite.
	var switch_positions:=[Vector3(-1.86,1.2,-1.15),Vector3(-1.86,1.2,.25),Vector3(.18,1.2,.84)]
	for i in range(switch_positions.size()): wall_switch(p,"WallSwitch%d" % i,switch_positions[i],0.0 if i==2 else PI/2)

func build_player()->void:
	var p:=CharacterBody3D.new(); p.name="Player"; p.position=Vector3(1.25,.05,.15)
	var view:=OS.get_environment("ROOM1408_VIEW")
	# Обычный старт — коридор перед номером: игрок ещё не входил. Остальные
	# пресеты остаются внутриквартирными, их геометрию менять нельзя.
	if view.is_empty() or view=="corridor": p.position=Vector3(1.2,.05,-4.55); p.rotation.y=1.93
	elif view=="living": p.position=Vector3(3.3,.05,2.7); p.rotation.y=2.25
	elif view=="livingwide": p.position=Vector3(-.9,.05,1.35); p.rotation.y=PI-.25
	elif view=="livingcorner": p.position=Vector3(3.55,.05,4.45); p.rotation.y=.95
	elif view=="livingtable": p.position=Vector3(.9,.05,2.35); p.rotation.y=PI
	elif view=="bathroom": p.position=Vector3(-2.60,.05,1.45); p.rotation.y=PI/2
	elif view=="hall": p.position=Vector3(-2.55,.05,-2.40); p.rotation.y=1.95
	elif view=="entrydoor": p.position=Vector3(-3.0,.05,-1.35)
	elif view=="wardrobe": p.position=Vector3(.5,.05,-.15); p.rotation.y=PI/2
	elif view=="bed": p.position=Vector3(1.25,.05,.35)
	elif view=="desk": p.position=Vector3(2.55,.05,2.8); p.rotation.y=-.75
	elif view=="bedwindow": p.position=Vector3(2.75,.05,-1.15); p.rotation.y=-PI/2
	elif view=="livingwindow": p.position=Vector3(.8,.05,3.55); p.rotation.y=PI
	elif view=="livingpainting": p.position=Vector3(.2,.05,3.15); p.rotation.y=-PI/2
	elif view=="switch": p.position=Vector3(-3.00,.05,-2.65); p.rotation.y=-PI/2
	elif view=="phone": p.position=Vector3(1.85,.05,-2.05); p.rotation.y=-.75
	elif view=="anomaly": p.position=Vector3(1.25,.05,-1.30); p.rotation.y=-.75
	elif view=="card": p.position=Vector3(3.0,.05,2.10); p.rotation.y=-1.18
	elif view=="key": p.position=Vector3(1.25,.05,-.20); p.rotation.y=0.0
	elif view=="restore_chair": p.position=Vector3(2.25,.05,-.10); p.rotation.y=-1.77
	elif view=="restore_painting": p.position=Vector3(1.25,.05,-1.50); p.rotation.y=0.0
	elif view=="restore_phone": p.position=Vector3(1.65,.05,-2.0); p.rotation.y=-.88
	elif view=="restore_pillow": p.position=Vector3(1.85,.05,.20); p.rotation.y=0.0
	elif view=="minibar": p.position=Vector3(2.85,.05,4.25); p.rotation.y=-1.25
	elif view=="beddoor": p.position=Vector3(-.85,.05,-1.85); p.rotation.y=PI/2
	elif view=="bathdoor": p.position=Vector3(-2.85,.05,-1.55); p.rotation.y=PI
	elif view=="livingdoor": p.position=Vector3(-.55,.05,.1); p.rotation.y=PI
	elif view=="sofa": p.position=Vector3(1.25,.05,2.65); p.rotation.y=-2.34
	elif view=="armchair": p.position=Vector3(.5,.05,3.3); p.rotation.y=2.36
	elif view=="toilet": p.position=Vector3(-2.45,.05,.15); p.rotation.y=PI/2
	elif view=="flowers": p.position=Vector3(-2.95,.05,-1.35); p.rotation.y=1.02
	elif view=="tub": p.position=Vector3(-2.25,.05,1.35); p.rotation.y=2.28
	elif view=="tv": p.position=Vector3(-.25,.05,3.55); p.rotation.y=PI/2
	elif view=="sink": p.position=Vector3(-2.42,.05,.34); p.rotation.y=PI/2
	elif view=="outlet": p.position=Vector3(-2.58,.05,-2.65); p.rotation.y=-PI/2
	elif view=="clock": p.position=Vector3(2.28,.05,2.45)
	elif view=="towels": p.position=Vector3(-3.55,.05,.58); p.rotation.y=-PI/2
	# Два коридорных ракурса: от спавна не видно ни урны, ни указателя этажа над
	# лифтом — они позади и сбоку, а проверять отделку надо глазами.
	elif view=="corridorlift": p.position=Vector3(-.2,.05,-4.62); p.rotation.y=-PI/2
	elif view=="corridorurn": p.position=Vector3(1.15,.05,-5.05); p.rotation.y=PI
	elif view=="corridortray": p.position=Vector3(.9,.05,-4.35); p.rotation.y=.93
	p.set_script(load("res://scripts/player.gd")); p.floor_snap_length=.20; p.floor_max_angle=deg_to_rad(48.0); var cs:=CollisionShape3D.new(); var cap:=CapsuleShape3D.new(); cap.radius=.3; cap.height=1.7; cs.shape=cap; cs.position.y=.85; p.add_child(cs); var head:=Node3D.new(); head.name="Head"; head.position.y=1.62; p.add_child(head); var cam:=Camera3D.new(); cam.name="Camera3D"; cam.current=true; cam.fov=72; head.add_child(cam); add_child(p)
	if view=="livingcorner": head.rotation.x=-.28
	elif view=="livingtable": head.rotation.x=-.20
	elif view=="desk": head.rotation.x=-.3
	elif view=="bed": head.rotation.x=-.22
	elif view=="phone": head.rotation.x=-.58
	elif view=="anomaly": head.rotation.x=-.22
	elif view=="card": head.rotation.x=-.55
	elif view=="key": head.rotation.x=-.78
	elif view=="corridorlift": head.rotation.x=.16
	elif view=="corridorurn": head.rotation.x=-.44
	elif view=="corridortray": head.rotation.x=-.26
	elif view=="restore_chair": head.rotation.x=-.25
	elif view=="restore_painting": head.rotation.x=0.0
	elif view=="restore_phone": head.rotation.x=-1.0
	elif view=="restore_pillow": head.rotation.x=-.70
	elif view=="minibar": head.rotation.x=-.38
	elif view=="sofa": head.rotation.x=-.22
	elif view=="armchair": head.rotation.x=-.28
	elif view=="toilet": head.rotation.x=-.35
	elif view=="flowers": head.rotation.x=-.4
	elif view=="tub": head.rotation.x=-.28
	elif view=="tv": head.rotation.x=-.12
	elif view=="sink": head.rotation.x=-.35
	elif view=="outlet": head.position.y=.70; head.rotation.x=-.68
	elif view=="clock": head.rotation.x=.10
	elif view=="bathroom": head.rotation.x=-.15
	elif view=="towels": head.rotation.x=-.12
	elif view=="switch": head.rotation.x=-.35

# ------------------------------------------------------------------ коридор ---
# Шестнадцатый этаж перед номером. Отдельный корень, а не часть HotelSuite:
# в финале он целиком гасится одним visible=false, и «за дверью нет коридора»
# перестаёт быть только фразой.
func build_corridor()->void:
	var c:=group("Corridor")
	box(c,"CorridorFloor",Vector3(-1.6,-.08,-4.6),Vector3(10.02,.16,2.62),"carpet",true)
	box(c,"CorridorCeiling",Vector3(-1.6,2.76,-4.6),Vector3(10.02,.12,2.62),"cream",false)
	box(c,"CorridorFarWall",Vector3(-1.6,1.35,-6.0),Vector3(10.02,2.7,.18),"corridor_wall",true)
	box(c,"CorridorWestWall",Vector3(-6.7,1.35,-4.6),Vector3(.18,2.7,2.62),"corridor_wall",true)
	box(c,"CorridorEastWall",Vector3(3.5,1.35,-4.6),Vector3(.18,2.7,2.62),"corridor_wall",true)
	# Северная стена номера кончается на x=-4.4, а коридор тянется дальше на запад.
	box(c,"CorridorRoomSideFiller",Vector3(-5.505,1.35,-3.2),Vector3(2.21,2.7,.18),"corridor_wall",true)
	box(c,"CorridorRunner",Vector3(-1.6,.012,-4.6),Vector3(9.6,.025,1.35),"rug_border")
	box(c,"CorridorBaseFar",Vector3(-1.6,.12,-5.86),Vector3(9.9,.24,.08),"wood2")
	# Плинтус у стены номера прерывается на дверном проёме 1604.
	box(c,"CorridorBaseNearWest",Vector3(-4.85,.12,-3.34),Vector3(3.5,.24,.08),"wood2")
	box(c,"CorridorBaseNearEast",Vector3(.6,.12,-3.34),Vector3(5.6,.24,.08),"wood2")

	# Соседние номера. Открыть их нельзя — дальняя стена сплошная, двери на ней
	# только читаются как двери.
	for entry in [[-4.9,"1603"],[-.9,"1605"],[1.9,"1607"]]:
		var x:float=entry[0]; var number:String=entry[1]
		fitted_model(c,"CorridorDoor"+number,ENTRANCE_DOOR_MODEL,Vector3(x,0,-5.93),Vector3(.9,2.1,.12),Vector3(0,PI,0),{"wood":"wood","metal":"brass"})
		door_plate(c,number,Vector3(x,1.75,-5.86),1.0)
	# Табличка 1604 со стороны коридора: та, что в номере, смотрит внутрь.
	door_plate(c,"1604",Vector3(-1.95,1.75,-3.30),-1.0)
	# Transom above entrance 1604: glass panel and frame.
	box(c,"EntranceDoorTransomGlass",Vector3(-1.95,2.28,-3.36),Vector3(1.42,.34,.035),"glass")
	box(c,"EntranceDoorTransomTop",Vector3(-1.95,2.47,-3.36),Vector3(1.50,.055,.08),"wood2")
	box(c,"EntranceDoorTransomLeft",Vector3(-2.67,2.28,-3.36),Vector3(.055,.40,.08),"wood2")
	box(c,"EntranceDoorTransomRight",Vector3(-1.23,2.28,-3.36),Vector3(.055,.40,.08),"wood2")

	for i in range(4):
		var x:=-5.4+i*2.9
		fitted_model(c,"CorridorSconce%d"%i,WALL_LAMP_MODEL,Vector3(x,2.05,-5.83),Vector3(.26,.30,.16),Vector3.ZERO,{"metal":"brass","lamp":"lamp_glow","cream":"shade"})
		var l:=OmniLight3D.new(); l.name="CorridorLight%d"%i; l.position=Vector3(x,2.0,-5.45)
		# Не одинаковая заливка, а чередование старых ламп: чуть разные температура
		# и мощность дробят длинную кишку коридора на тёплые островки.
		l.light_color=[Color("d7a46c"),Color("efc58a"),Color("d4a06a"),Color("e8bb80")][i]
		l.light_energy=[.43,.56,.40,.52][i]; l.omni_range=3.75
		# Одна центральная тень даёт глубину тележке и филёнкам; четыре карты теней
		# были бы слишком дороги для WebGL на слабом ноутбуке.
		l.shadow_enabled=i==1; l.shadow_opacity=.48; l.shadow_blur=1.35; c.add_child(l)

	# Три небольших гостиничных полотна занимают свободные простенки, а не
	# конкурируют с дверями и бра. Пара на стене номера обрамляет вход 1604;
	# маяк напротив виден в первом проходе по коридору. Сюжеты разные, палитра
	# одна — холодное масло с единственной тёплой точкой.
	textured_picture_z_wall(c,"CorridorPassPainting",Vector3(-3.75,1.62,CORRIDOR_NEAR),Vector2(.92,.66),CORRIDOR_PASS_TEXTURE,-1.0)
	textured_picture_z_wall(c,"CorridorBridgePainting",Vector3(2.72,1.62,CORRIDOR_NEAR),Vector2(.92,.66),CORRIDOR_BRIDGE_TEXTURE,-1.0)
	textured_picture_z_wall(c,"CorridorLighthousePainting",Vector3(-3.62,1.55,CORRIDOR_FAR),Vector2(1.08,.72),CORRIDOR_LIGHTHOUSE_TEXTURE,1.0)

	# Лифт в восточном торце: игрок как будто только что из него вышел.
	box(c,"LiftFrame",Vector3(3.39,1.10,-4.6),Vector3(.04,2.25,1.98),"metal")
	box(c,"LiftLeafLeft",Vector3(3.36,1.05,-4.17),Vector3(.04,2.08,.84),"chrome")
	box(c,"LiftLeafRight",Vector3(3.36,1.05,-5.03),Vector3(.04,2.08,.84),"chrome")
	box(c,"LiftButtonPlate",Vector3(3.37,1.15,-3.66),Vector3(.03,.22,.14),"brass")
	cyl(c,"LiftButton",Vector3(3.35,1.15,-3.66),.022,.02,"lamp_glow",Vector3(0,0,PI/2))

	# Окно в западном торце. За стеклом намеренно ничего нет.
	box(c,"CorridorWindowNight",Vector3(-6.60,1.45,-4.6),Vector3(.02,1.5,1.4),"night")
	box(c,"CorridorWindow",Vector3(-6.57,1.45,-4.6),Vector3(.035,1.5,1.4),"corridor_glass")
	box(c,"CorridorWindowMullion",Vector3(-6.55,1.45,-4.6),Vector3(.06,1.5,.075),"wood2")
	box(c,"CorridorWindowTransom",Vector3(-6.55,1.45,-4.6),Vector3(.06,.075,1.4),"wood2")

	var cart:=group("MaidCart",c)
	box(cart,"CartBody",Vector3(-5.75,.42,-4.35),Vector3(.52,.84,.98),"metal",true)
	box(cart,"CartTop",Vector3(-5.75,.87,-4.35),Vector3(.56,.06,1.02),"wood2")
	box(cart,"CartLinen",Vector3(-5.75,.98,-4.58),Vector3(.40,.18,.42),"cream")
	box(cart,"CartTowels",Vector3(-5.75,.95,-4.12),Vector3(.38,.13,.40),"beige")
	for dz in [-.36,.36]: cyl(cart,"CartWheel",Vector3(-5.75,.06,-4.35+dz),.055,.44,"metal",Vector3(0,0,PI/2))

	fitted_model(c,"CorridorPlant",POTTED_PLANT_MODEL,Vector3(-6.35,0,-3.50),Vector3(.34,.90,.34),Vector3.ZERO,{"plant":"leaf","wood":"brass"})
	box(c,"CorridorSign",Vector3(-.8,2.28,-3.36),Vector3(.86,.30,.05),"metal")
	var sign:=Label3D.new(); sign.name="CorridorSignText"; sign.text="1601 — 1610"; sign.font_size=40; sign.pixel_size=.0022; sign.modulate=Color("c3ae86"); sign.position=Vector3(-.8,2.28,-3.40); sign.rotation.y=PI; c.add_child(sign)
	# Пожарный шкаф и рамка с распорядком: стена номера иначе стоит пустая на семь метров.
	box(c,"CorridorHoseCabinet",Vector3(1.85,1.05,-3.36),Vector3(.46,.62,.14),"wood")
	box(c,"CorridorHoseGlass",Vector3(1.85,1.05,-3.44),Vector3(.36,.50,.02),"glass")
	box(c,"CorridorNoticeFrame",Vector3(-.8,1.55,-3.34),Vector3(.44,.58,.04),"brass")
	box(c,"CorridorNoticeSheet",Vector3(-.8,1.55,-3.37),Vector3(.36,.50,.01),"cream")
	# Рамка больше не содержит пустой белый прямоугольник: заголовок и строки
	# распорядка собраны семью крошечными мешами, без отдельной текстуры и шрифта.
	box(c,"CorridorNoticeHeader",Vector3(-.8,1.72,-3.382),Vector3(.25,.025,.006),"wood")
	for i in range(6):
		var line_width:=.25 if i in [0,3] else .29
		box(c,"CorridorNoticeLine%d"%i,Vector3(-.8,1.64-float(i)*.055,-3.382),Vector3(line_width,.010,.006),"metal")
	decorate_corridor(c)
	var atmosphere:=Node.new(); atmosphere.name="CorridorAtmosphere"; atmosphere.set_script(CORRIDOR_ATMOSPHERE_SCRIPT); c.add_child(atmosphere)

# Отделка коридора: карниз, панели, плафоны, урна и указатель этажа.
#
# Плоскости отделки — это внутренние грани стен, а не их центры: дальняя стена
# стоит центром на z=-6.0 при толщине .18, поэтому облицовывать надо z=-5.91.
# Ошибка на полтолщины прячет отделку внутрь стены, и снаружи её просто не видно.
const CORRIDOR_FAR := -5.91
const CORRIDOR_NEAR := -3.30
const CORRIDOR_WEST := -6.61
const CORRIDOR_EAST := 3.41
const CORRIDOR_CEILING := 2.70

func decorate_corridor(c:Node3D)->void:
	# Карниз идёт по всем четырём стенам без разрывов: на высоте потолка ему
	# нечего обходить, а углы перекрываются на считанные миллиметры.
	var cornice:Array=[]
	wall_tiles(cornice,[[CORRIDOR_WEST,CORRIDOR_EAST]],.85,CORRIDOR_CEILING,0.0,CORRIDOR_FAR,true,true)
	wall_tiles(cornice,[[CORRIDOR_WEST,CORRIDOR_EAST]],.85,CORRIDOR_CEILING,PI,CORRIDOR_NEAR,true,true)
	wall_tiles(cornice,[[CORRIDOR_FAR,CORRIDOR_NEAR]],.85,CORRIDOR_CEILING,PI/2,CORRIDOR_WEST,false,true)
	wall_tiles(cornice,[[CORRIDOR_FAR,CORRIDOR_NEAR]],.85,CORRIDOR_CEILING,-PI/2,CORRIDOR_EAST,false,true)
	multi_model(c,"CorridorCornice",CORRIDOR_CORNICE_MODEL,cornice,{"wood":"wood2","brass":"brass"})

	# Панели стоят на плинтусе (его верх — .24), а не на полу: иначе они лезли бы
	# в него и мерцали на стыке. Верх панели при этом остаётся на .94 — ниже низа
	# пожарного шкафа (.74) он не поднимается только потому, что под шкафом пролёт
	# разорван, см. пропуски ниже.
	var wainscot:Array=[]
	# Дальняя стена: три фальшивых двери соседних номеров (x=-4.9, -.9, 1.9,
	# шириной .9) разрывают пролёт — панель поперёк двери выглядела бы наклейкой.
	wall_tiles(wainscot,[[-6.61,-5.35],[-4.45,-1.35],[-.45,1.45],[2.35,3.41]],
			.85,.24,0.0,CORRIDOR_FAR,true,false)
	# Ближняя стена: пропускаем проём 1604 (x -3.1..-2.2) и пожарный шкаф
	# (x 1.62..2.08), который начинается на .74 и панель бы перерезала.
	wall_tiles(wainscot,[[-6.61,-3.1],[-2.2,1.62],[2.08,3.41]],
			.85,.24,PI,CORRIDOR_NEAR,true,false)
	# Филёнка обязана быть светлее стены. С "beige" (aa9277) против стены (a18f74)
	# поле пропадало, оставалась одна тёмная рама — и панели читались не отделкой,
	# а балюстрадой с дырами. "cream" даёт нужный контраст.
	multi_model(c,"CorridorWainscot",CORRIDOR_WAINSCOT_MODEL,wainscot,{"wood":"wood2","panel":"cream"})

	# Плафоны встают между бра, в шахматном порядке с ними. Своих Light3D у них
	# нет: девятнадцати источников сцене уже достаточно, а видно их по эмиссии.
	var roses:Array=[]
	for x in [-4.0,-1.1,1.8]:
		roses.append(Transform3D(Basis.IDENTITY,Vector3(x,CORRIDOR_CEILING,-4.6)))
	multi_model(c,"CorridorCeilingRoses",CORRIDOR_CEILING_ROSE_MODEL,roses,{"brass":"brass","shade":"lamp_glow"})

	# Урна с песком у стены номера, между рамкой распорядка и пожарным шкафом.
	# Стоит перед панелями, поэтому вынесена от стены на глубину их свеса.
	var urn:=placed_model(c,"CorridorUrn",CORRIDOR_URN_MODEL,Vector3(1.15,0,-3.55),
			Vector3.ZERO,{"brass":"brass","sand":"beige"})
	model_box_collision(urn,"CorridorUrnCollision",Vector3(1.15,.30,-3.55),Vector3(.27,.60,.27))

	# Указатель этажа над дверьми лифта: стрелка стоит на шестнадцатом.
	placed_model(c,"CorridorLiftDial",CORRIDOR_LIFT_DIAL_MODEL,Vector3(CORRIDOR_EAST,2.30,-4.6),
			Vector3(0,-PI/2,0),{"brass":"brass","dial":"cream","metal":"metal"})

	# Узор дорожки. Дорожка лежит в самом центре первого кадра игры и до сих
	# пор была ровным тёмным прямоугольником — это самое заметное, что вообще
	# можно было добавить. Тайл .45 ложится по ширине ровно трижды.
	# Верх дорожки — .0245, узор кладём на .026: вплотную он бы мерцал.
	var carpet:Array=[]
	for ix in range(21):
		for iz in range(3):
			carpet.append(Transform3D(Basis.IDENTITY,Vector3(-6.10+.45*ix,.026,-5.05+.45*iz)))
	multi_model(c,"CorridorCarpetPattern",CORRIDOR_CARPET_TILE_MODEL,carpet,
			{"figure":"carpet","accent":"flower_dark","corner":"beige"})

	# Накладки на створки лифта: игрок выходит из лифта и видит их первыми.
	# Кладутся поверх хромированных боксов створок (их корридорная грань — 3.34),
	# а не вместо: сам лифт при этом остаётся как был.
	var leaves:Array=[]
	for z in [-4.17,-5.03]:
		leaves.append(Transform3D(Basis.from_euler(Vector3(0,-PI/2,0)),Vector3(3.34,.12,z)))
	multi_model(c,"CorridorLiftRelief",CORRIDOR_LIFT_RELIEF_MODEL,leaves,
			{"brass":"brass","metal":"metal"})

	# Брошенная багажная тележка у стены номера, восточнее проёма 1604.
	#
	# Сначала она стояла у дальней стены на x=-3.05 — и аудит остался зелёным, но
	# проверка corridor_far_wall_boundary стала упираться в тележку вместо стены,
	# то есть перестала проверять стену. Тестовая точка (-2.65, -5.4) оказалась
	# внутри тележки. У дальней стены свободного места нет вовсе: между игроком в
	# точке x=-2.65 (занимает до -2.95) и игроком в точке x=-4.0 (занимает от
	# -3.7) остаётся .75 м, а тележка шириной .95.
	#
	# У стены номера места хватает: спереди до линии z=-4.55 остаётся .25 м, а до
	# подхода к двери (-2.65) — .27 м по x. Заодно тележка попадает в первый кадр.
	var cart:=placed_model(c,"CorridorLuggageCart",CORRIDOR_LUGGAGE_CART_MODEL,
			Vector3(-1.6,0,-3.70),Vector3(0,PI,0),
			{"wood":"wood2","brass":"brass","metal":"metal","cream":"cream"})
	model_box_collision(cart,"CorridorCartCollision",Vector3(-1.6,.675,-3.70),Vector3(.95,1.35,.60))

	# Поднос рум-сервиса под дверью 1605 и табличка на ручке 1607 — единственные
	# две вещи, которые говорят, что в этом коридоре кто-то был. Поднос стоит на
	# голом полу: дорожка кончается на z=-5.275, а он у самого плинтуса.
	placed_model(c,"CorridorServiceTray",CORRIDOR_SERVICE_TRAY_MODEL,Vector3(-.9,0,-5.62),
			Vector3.ZERO,{"brass":"brass","chrome":"chrome","glass":"glass","cream":"cream"})
	placed_model(c,"CorridorDoorHanger",CORRIDOR_DOOR_HANGER_MODEL,Vector3(1.62,1.12,-5.862),
			Vector3.ZERO,{"brass":"brass","tag":"flower_dark"})

func door_plate(parent:Node,number:String,pos:Vector3,face_z:float)->void:
	box(parent,"Plate"+number,pos,Vector3(.40,.17,.025),"brass")
	var label:=Label3D.new(); label.name="PlateText"+number; label.text=number; label.font_size=48; label.pixel_size=.0025; label.modulate=Color("21140d")
	label.position=pos+Vector3(0,0,.022*face_z)
	if face_z<0.0: label.rotation.y=PI
	parent.add_child(label)

# Какой круг собирать. Номер спрашивается у автозагрузки Game, а она разрешает
# его так: выбор игрока (меню, переход между кругами) → LIMBO_CIRCLE → первый.
#
# LIMBO_CIRCLE остаётся рабочей дверью разработки и аудита и стоит в этом
# порядке выше значения по умолчанию: на нём держатся все девять аудитов.
const CIRCLE_SCRIPTS := {
	1: ["LimboLevel", LIMBO_LEVEL_SCRIPT],
	2: ["LustLevel", LUST_LEVEL_SCRIPT],
	3: ["GluttonyLevel", GLUTTONY_LEVEL_SCRIPT],
	4: ["GreedLevel", GREED_LEVEL_SCRIPT],
	5: ["WrathLevel", WRATH_LEVEL_SCRIPT],
	6: ["HeresyLevel", HERESY_LEVEL_SCRIPT],
	7: ["ViolenceLevel", VIOLENCE_LEVEL_SCRIPT],
	8: ["FraudLevel", FRAUD_LEVEL_SCRIPT],
	9: ["TreacheryLevel", TREACHERY_LEVEL_SCRIPT]
}

func build_limbo()->void:
	var circle:int=Game.resolve_circle()
	var row:Array=CIRCLE_SCRIPTS.get(circle,CIRCLE_SCRIPTS[1])
	var level:=Node3D.new()
	level.name=str(row[0])
	level.set_script(row[1])
	add_child(level)
	build_shell(circle,level)

# Меню, пауза и переходы между кругами. В прогонах аудита не строится вовсе:
# игрока там нет, а перезагрузка сцены посреди проверки уничтожила бы её.
func build_shell(circle:int,level:Node)->void:
	if Game.is_audit() or not Game.has_screen():
		return
	var shell:=Shell.new()
	# Сначала в дерево, потом настройка: setup() трогает get_tree().
	add_child(shell)
	# HUD отдаём оболочке, чтобы она прятала его под своими экранами: иначе
	# сквозь полупрозрачную подложку просвечивают слот инвентаря и заголовок круга.
	shell.setup(circle,level.get("hud") as CanvasLayer)
	shell_node=shell
	# Круг сообщает о завершении единственным общим сигналом: часы добежали до
	# конца минуты. Он срабатывает ровно один раз (страж `finished`) и только
	# через run_out(), которым каждый из девяти кругов и заканчивается, —
	# поэтому подходит всем без единой правки в самих кругах.
	#
	# Раньше времени сработать не может: во время игры потолок акта держит
	# стрелку на 50 из 60, и SPAN достижим только финальным добегом.
	var clock:=level.get("clock") as ClockDirector
	if clock:
		clock.minute_reached.connect(shell.on_circle_finished)
	else:
		push_warning("Shell: у круга %d нет часов, переход между кругами не подключён" % circle)
	if Game.should_show_menu():
		shell.show_main_menu()
	else:
		# Круг начинается сразу (пришли из перехода или через LIMBO_CIRCLE):
		# оболочка скрыта, значит идёт настоящий геймплей.
		shell.hide_all()
	# Сенсорное управление — только на сенсорных устройствах: на столе площадка
	# требует клавиатуру и мышь по умолчанию.
	if TouchControls.wanted():
		var touch:=TouchControls.new()
		add_child(touch)
		touch.setup(get_node("Player") as CharacterBody3D,shell)
	# Обязательный вызов площадки: комната собрана, экран показан, играть можно.
	# Раньше этого места звать нельзя — Яндекс по нему считает готовность.
	if has_node("/root/Platform"):
		get_node("/root/Platform").report_ready()

# Выбирается после сборки комнаты и коридора, чтобы настройка затронула каждый
# источник света. WebGL-профиль нужен и настольным браузерам: web-сборка без
# потоков заметно медленнее нативной даже на ноутбуке с мышью.
func apply_runtime_quality()->void:
	if OS.has_feature("web") and not Engine.is_editor_hint():
		apply_web_quality()
	elif TouchControls.wanted():
		apply_touch_quality()

# Браузерный профиль: интерфейс остаётся чётким, уменьшается только 3D-буфер.
# Тени от OmniLight3D особенно дороги в Compatibility/WebGL и почти незаметны
# в движении при текущем мягком свете, поэтому в вебе они отключены полностью.
func apply_web_quality()->void:
	var viewport:=get_viewport()
	viewport.scaling_3d_mode=Viewport.SCALING_3D_MODE_BILINEAR
	update_web_3d_scale()
	if not viewport.size_changed.is_connected(update_web_3d_scale):
		viewport.size_changed.connect(update_web_3d_scale)
	var shadowed:=disable_runtime_shadows()
	print("WEB_QUALITY 3d_scale=%.3f shadows_off=%d"%[viewport.scaling_3d_scale,shadowed])

func update_web_3d_scale()->void:
	var viewport:=get_viewport()
	var size:=viewport.get_visible_rect().size
	if size.x<=0.0 or size.y<=0.0:
		return
	var scale:=sqrt(WEB_3D_PIXEL_BUDGET/(size.x*size.y))
	viewport.scaling_3d_scale=clampf(scale,.35,.75)

func disable_runtime_shadows()->int:
	var shadowed:=0
	for light in find_children("*","Light3D",true,false):
		var source:=light as Light3D
		if source.shadow_enabled:
			source.shadow_enabled=false
			shadowed+=1
	return shadowed

# Настройки под слабое нативное сенсорное устройство.
#
# Комната освещена девятнадцатью источниками, и в gl_compatibility тени от них
# — самое дорогое, что здесь есть. Гасим тени и рисуем 3D в три четверти
# разрешения: интерфейс при этом остаётся резким, потому что он рисуется
# отдельно, поверх.
func apply_touch_quality()->void:
	var viewport:=get_viewport()
	viewport.scaling_3d_mode=Viewport.SCALING_3D_MODE_BILINEAR
	viewport.scaling_3d_scale=0.75
	var shadowed:=disable_runtime_shadows()
	print("TOUCH_QUALITY 3d_scale=0.75 shadows_off=%d"%shadowed)

func run_navigation_audit()->void:
	var player:=get_node("Player") as CharacterBody3D
	var routes:={
		"interroom":[Vector3(1.25,.05,.15),Vector3(-.55,.05,.15),Vector3(-.55,.05,1.15),Vector3(-1.0,.05,1.15),Vector3(-.55,.05,1.15),Vector3(-.55,.05,.15),Vector3(-.55,.05,-1.85),Vector3(-2.3,.05,-1.85),Vector3(-2.8,.05,-1.45),Vector3(-2.8,.05,-.35),Vector3(-2.65,.05,.55),Vector3(-3.0,.05,1.25)],
		"bedroom_window":[Vector3(1.25,.05,.15),Vector3(2.7,.05,-.65),Vector3(3.5,.05,-.7)],
		"bedroom_wardrobe":[Vector3(1.25,.05,.15),Vector3(-.7,.05,.15),Vector3(-.7,.05,-.2)],
		"bedroom_door":[Vector3(-1.35,.05,-1.85),Vector3(-2.45,.05,-1.85)],
		"bathroom_door":[Vector3(-2.85,.05,-1.45),Vector3(-2.85,.05,-.35)],
		"living_door":[Vector3(-.55,.05,.15),Vector3(-.55,.05,1.25)],
		"living_amenities":[Vector3(-.55,.05,1.15),Vector3(.2,.05,2.2),Vector3(.2,.05,4.2),Vector3(1.2,.05,4.7),Vector3(.2,.05,4.2),Vector3(.2,.05,2.2),Vector3(2.7,.05,2.2),Vector3(3.0,.05,3.15),Vector3(3.0,.05,4.2),Vector3(3.2,.05,4.8)]
	}
	# Коридор: от лифта до западного торца и обратно к двери 1604, в обход тележки.
	routes["corridor_walk"]=[Vector3(1.2,.05,-4.55),Vector3(2.9,.05,-4.55),Vector3(-2.65,.05,-4.55),Vector3(-2.65,.05,-3.65),Vector3(-2.65,.05,-4.55),Vector3(-4.0,.05,-4.55),Vector3(-4.0,.05,-5.4),Vector3(-6.2,.05,-5.4)]
	for label in routes:
		if not audit_route(player,label,routes[label]): return
	if not audit_boundary(player,"bedroom_window_boundary",Vector3(3.65,.05,-1.1),Vector3(1.0,0,0)): return
	if not audit_boundary(player,"living_window_boundary",Vector3(.8,.05,4.9),Vector3(0,0,1.0)): return
	if not audit_boundary(player,"corridor_far_wall_boundary",Vector3(-2.65,.05,-5.4),Vector3(0,0,-1.0)): return
	# В прологе дверь 1604 обязана держать: иначе игрок войдёт мимо карты-ключа.
	if not audit_boundary(player,"room_door_closed_boundary",Vector3(-2.65,.05,-3.75),Vector3(0,0,1.0)): return
	print("NAV_AUDIT_OK all rooms, doors, window boundaries, corridor, wardrobe and living amenities")

func audit_route(player:CharacterBody3D,label:String,route:Array)->bool:
	player.global_position=route[0]
	for target in route.slice(1):
		var motion:Vector3=target-player.global_position
		var hit:=player.move_and_collide(motion,true)
		if hit:
			push_error("NAV_AUDIT_BLOCKED %s at %s toward %s by %s" % [label,player.global_position,target,hit.get_collider().name]); return false
		player.global_position=target
	print("NAV_ROUTE_OK %s" % label); return true

func audit_boundary(player:CharacterBody3D,label:String,start:Vector3,motion:Vector3)->bool:
	player.global_position=start
	var hit:=player.move_and_collide(motion,true)
	if not hit:
		push_error("NAV_BOUNDARY_OPEN %s from %s" % [label,start]); return false
	print("NAV_BOUNDARY_OK %s blocked by %s" % [label,hit.get_collider().name]); return true

func collect_runtime_stats(node:Node,counts:Dictionary)->void:
	counts.nodes+=1
	if node is MeshInstance3D: counts.meshes+=1
	if node is CollisionShape3D: counts.collisions+=1
	if node is Light3D:
		counts.lights+=1
		if node.shadow_enabled: counts.shadow_lights+=1
	for child in node.get_children(): collect_runtime_stats(child,counts)
