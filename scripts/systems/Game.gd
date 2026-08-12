extends Node

# Единственный узел, переживающий перезагрузку сцены.
#
# Зачем он вообще нужен: круги переключаются полной перезагрузкой сцены, а не
# подменой уровня на лету. Причина не в лени — уровень правит саму комнату и
# ничего за собой не убирает:
#
#   * LustLevel.hide_circle_one_things() прячет узлы родителя и восстановления
#     не делает вовсе;
#   * CircleLevel.cache_room() двигает pivot креслу, картине, телефону и двери
#     и добавляет в сцену два новых OmniLight3D на каждый экземпляр уровня;
#   * круги III–IX ставят свои пропсы через placed_model() в родителя.
#
# Подмена уровня на лету протащила бы всё это в следующий круг. Перезагрузка
# сцены — единственная честная граница, а экран перехода (и реклама на нём)
# ровно тем и хорош, что закрывает собой время пересборки комнаты.
#
# Переменные окружения при этом остаются главнее ничего не значащего нуля:
# аудит и разработка обращаются к кругам через LIMBO_CIRCLE, и этот путь
# обязан работать ровно как раньше.

const FIRST_CIRCLE := 1
const LAST_CIRCLE := 9
const MENU_SCENE := "res://menu.tscn"
const GAME_SCENE := "res://main.tscn"

# Круг, который соберётся при следующей загрузке сцены.
# 0 — «не задано»: значит, круг берётся из окружения или первый по умолчанию.
var circle_to_load := 0

# С чем загружается сцена: показать меню или сразу играть.
enum Boot { MENU, PLAY }
var boot_intent := Boot.MENU

# Решается один раз на старте, до перехода из лёгкой сцены меню в main.tscn.
# Комната больше не строится под меню: выбранный круг загружается только после
# нажатия кнопки игроком.
func prepare_boot() -> void:
	# FLOW_AUDIT перечислен здесь, а не в is_audit(): разбирает его main.gd, то
	# есть игровая сцена, и до неё надо дойти. Без этой строки проверка
	# прогресса упиралась в меню и висела там до убийства процесса — молча, ни
	# строчки в вывод, будто её и не запускали.
	if is_audit() or not has_screen() or OS.has_environment("LIMBO_CIRCLE") \
			or OS.has_environment("SHELL_SHOT") or OS.has_environment("FLOW_AUDIT"):
		boot_intent = Boot.PLAY
		return
	if circle_to_load == 0:
		circle_to_load = current_circle

func should_show_menu() -> bool:
	return boot_intent == Boot.MENU and not is_audit() and has_screen()

# Уйти в отдельную сцену меню. Она не содержит и не отрисовывает 3D-комнату.
func go_to_menu(tree: SceneTree) -> void:
	boot_intent = Boot.MENU
	circle_to_load = current_circle
	tree.paused = false
	# Scene changes requested from a Button.pressed callback must be deferred.
	# Otherwise the menu can be freed while Godot is still dispatching the
	# signal; on HTML5 this occasionally leaves the old menu visible and makes
	# the button look unresponsive.
	tree.change_scene_to_file.call_deferred(MENU_SCENE)

# Пойти в игровую сцену и собрать указанный круг с чистой комнаты.
func go_to_circle(tree: SceneTree, circle: int) -> void:
	if not is_valid_circle(circle):
		return
	boot_intent = Boot.PLAY
	circle_to_load = circle
	remember_circle(circle)
	tree.paused = false
	# The call originates from a menu button signal. Defer it until the current
	# GUI event has finished so the menu can be released cleanly on desktop and
	# in the browser export alike.
	tree.change_scene_to_file.call_deferred(GAME_SCENE)

const SAVE_PATH_DEFAULT := "user://progress.cfg"
# Путь — переменная, а не константа, только ради проверки прогресса: она обязана
# писать в свой файл, а не в сохранение живого игрока.
var save_path := SAVE_PATH_DEFAULT
const SAVE_VERSION := 1

# Звук полностью выключен по решению владельца. Флаг общий, чтобы ни игрок, ни
# атмосфера коридора не создавали даже беззвучные AudioStreamPlayer и сэмплы.
const AUDIO_ENABLED := false
var sound_on := false

# Прогресс игрока. Круг, на котором остановился, и что уже пройдено.
var current_circle := FIRST_CIRCLE
var completed := {}

# Облачное хранилище Яндекса, если оно есть. Подставляется слоем платформы
# позже; пока его нет, прогресс живёт только локально, и это уже выполняет
# требование Яндекса «обновление страницы не теряет сохранение».
var cloud: Object = null

signal progress_changed()

func _ready() -> void:
	name = "Game"
	# Автозагрузка живёт и в headless-прогонах аудита: она обязана быть там
	# инертной. Ничего не пишем на диск и не трогаем ввод — только считаем
	# номер круга, когда спросят.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_audit():
		load_progress()
		# Облако — поверх локального. Platform поднимается следом за Game и сам
		# доложит, когда площадка ответит; ждать его никто не обязан.
		if has_node("/root/Platform"):
			cloud = get_node("/root/Platform")

func set_sound(enabled: bool) -> void:
	if sound_on == enabled:
		return
	sound_on = enabled
	save_progress()

# ---------------------------------------------------------------- прогресс ---

# Требование Яндекса: «сохранение изменений происходит сразу после действия», и
# обновление страницы сохранённое не теряет. Поэтому запись идёт сразу по факту
# события, а не по таймеру и не при выходе — выхода в вебе можно и не дождаться.
func mark_completed(circle: int) -> void:
	if not is_valid_circle(circle):
		return
	completed[circle] = true
	current_circle = mini(circle + 1, LAST_CIRCLE)
	save_progress()
	progress_changed.emit()

func remember_circle(circle: int) -> void:
	if not is_valid_circle(circle) or current_circle == circle:
		return
	current_circle = circle
	save_progress()
	progress_changed.emit()

func is_completed(circle: int) -> bool:
	return completed.has(circle)

# Самый дальний круг, куда пускает меню: следующий за последним пройденным.
# Пройденные круги остаются открытыми — переигрывать их можно всегда.
func highest_unlocked() -> int:
	var highest := FIRST_CIRCLE
	for circle in completed:
		highest = maxi(highest, mini(int(circle) + 1, LAST_CIRCLE))
	return highest

func is_unlocked(circle: int) -> bool:
	return is_valid_circle(circle) and circle <= highest_unlocked()

# Есть ли что продолжать. Нужно меню, чтобы решить, показывать ли «Продолжить».
func has_progress() -> bool:
	return not completed.is_empty() or current_circle > FIRST_CIRCLE

func all_circles_done() -> bool:
	for circle in range(FIRST_CIRCLE, LAST_CIRCLE + 1):
		if not completed.has(circle):
			return false
	return true

func reset_progress() -> void:
	completed.clear()
	current_circle = FIRST_CIRCLE
	save_progress()
	progress_changed.emit()

# ------------------------------------------------------------- сохранение ---

func progress_to_dictionary() -> Dictionary:
	var done: Array[int] = []
	for circle in completed:
		done.append(int(circle))
	done.sort()
	return {"version": SAVE_VERSION, "circle": current_circle, "completed": done, "sound": sound_on}

func progress_from_dictionary(data: Dictionary) -> void:
	# Чужие и старые данные разбираем терпимо: испорченное сохранение обязано
	# означать «начать сначала», а не падение на старте.
	completed.clear()
	var circles = data.get("completed", [])
	if circles is Array:
		for circle in circles:
			if typeof(circle) == TYPE_INT or typeof(circle) == TYPE_FLOAT:
				if is_valid_circle(int(circle)):
					completed[int(circle)] = true
	var saved := int(data.get("circle", FIRST_CIRCLE))
	current_circle = saved if is_valid_circle(saved) else FIRST_CIRCLE
	sound_on = bool(data.get("sound", true))

func save_progress() -> void:
	if is_audit():
		return
	var data := progress_to_dictionary()
	var config := ConfigFile.new()
	config.set_value("progress", "version", SAVE_VERSION)
	config.set_value("progress", "circle", data["circle"])
	config.set_value("progress", "completed", data["completed"])
	config.set_value("progress", "sound", sound_on)
	config.save(save_path)
	# Облако — поверх локального, а не вместо него: сеть может не ответить, и
	# игрок не должен из-за этого потерять прогресс.
	if cloud and cloud.has_method("save_progress"):
		cloud.save_progress(data)

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	progress_from_dictionary({
		"circle": config.get_value("progress", "circle", FIRST_CIRCLE),
		"completed": config.get_value("progress", "completed", []),
		"sound": config.get_value("progress", "sound", true)
	})

# Прогресс из облака приходит асинхронно и может оказаться дальше локального —
# тогда он побеждает. Меньший облачный прогресс локальный не затирает: игрок,
# прошедший круги офлайн, не должен их лишиться из-за пустого облака.
func merge_cloud_progress(data: Dictionary) -> void:
	if data.is_empty():
		return
	var mine := progress_to_dictionary()
	var theirs := data.duplicate()
	var my_count := (mine["completed"] as Array).size()
	var their_list = theirs.get("completed", [])
	var their_count := (their_list as Array).size() if their_list is Array else 0
	if their_count <= my_count:
		return
	# Звук — настройка этого устройства, а не прогресс: из облака он не
	# приезжает. Иначе выключенный здесь звук включился бы обратно чужой
	# записью с другого устройства.
	var keep_sound := sound_on
	progress_from_dictionary(theirs)
	sound_on = keep_sound
	save_progress()
	progress_changed.emit()

# Какой круг собирать. Порядок разрешения намеренно такой:
#
#   1. circle_to_load — то, что выбрал сам игрок (меню, переход между кругами);
#   2. LIMBO_CIRCLE — служебная дверь разработки и аудита;
#   3. первый круг.
#
# Пункт 2 обязан продолжать работать: на нём держатся все девять аудитов.
func resolve_circle() -> int:
	if is_valid_circle(circle_to_load):
		return circle_to_load
	var from_env := OS.get_environment("LIMBO_CIRCLE")
	if from_env.is_valid_int() and is_valid_circle(int(from_env)):
		return int(from_env)
	return FIRST_CIRCLE

func is_valid_circle(number: int) -> bool:
	return number >= FIRST_CIRCLE and number <= LAST_CIRCLE

# Идёт ли прогон аудита. Любой режимный флаг круга означает, что игрока нет и
# показывать ему нечего: ни меню, ни экрана перехода.
func is_audit() -> bool:
	# FLOW_AUDIT сюда НЕ входит намеренно: save_progress() молчит на аудитах,
	# чтобы не затирать сохранение живого игрока, а проверке прогресса нужно
	# именно настоящее сохранение на диск (у неё для этого свой save_path).
	# Мимо меню её проводит prepare_boot(), а не этот список.
	for name_of_mode in ["LIMBO_AUDIT", "LIMBO_EXPORT_AUDIT", "LUST_AUDIT", "GLUT_AUDIT",
			"GREED_AUDIT", "WRATH_AUDIT", "HERESY_AUDIT", "VIOL_AUDIT", "FRAUD_AUDIT",
			"TREACH_AUDIT", "ROOM1408_MODEL_AUDIT", "ROOM1408_STATS", "ROOM1408_NAV_AUDIT",
			"ROOM1408_SCREENSHOT"]:
		if OS.has_environment(name_of_mode):
			return true
	for name_of_walk in ["LIMBO_WALKTHROUGH", "LUST_WALKTHROUGH", "GLUT_WALKTHROUGH",
			"GREED_WALKTHROUGH", "WRATH_WALKTHROUGH", "HERESY_WALKTHROUGH",
			"VIOL_WALKTHROUGH", "FRAUD_WALKTHROUGH", "TREACH_WALKTHROUGH"]:
		if OS.has_environment(name_of_walk):
			return true
	return false

# Есть ли вообще экран, на который можно что-то показать.
# Тот же признак, которым пользуется player.gd, когда решает, строить ли шаги.
func has_screen() -> bool:
	return DisplayServer.get_name() != "headless"
