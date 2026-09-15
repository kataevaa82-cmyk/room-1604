extends Node

# Локализация. Требование 2.14 площадки: язык определяется автоматически, через
# SDK, без единого действия игрока.
#
# Устройство намеренно нестандартное, и вот почему. Весь текст игры лежит в
# `const`-словарях уровней (ROOM_ZONES, QUIET_USE, STORY и прочие). Константы
# вычисляются при загрузке класса — раньше, чем существует любой TranslationServer
# и любой выбранный язык, поэтому `tr()` внутри них невозможен физически. Второй
# путь — переписать полторы тысячи мест на ключи — означал бы переписать всю игру.
#
# Поэтому ключ перевода — сам русский текст, а перевод происходит в тех
# немногих функциях, через которые текст попадает игроку на глаза:
# Hud.show_message, Interactor.register/set_text, Inventory.refresh,
# Build.label3d, Shell.make_label/make_button, LevelMap, CodeLock, InspectView,
# TouchControls, Game. Таблиц две: русская — сам исходник, английская — JSON.
#
# Следствие, ради которого всё и затевалось: **промах перевода не ломает игру**.
# Незнакомая строка возвращается как есть, по-русски. Ни одного пути, где
# отсутствующий перевод приводит к пустому экрану или падению.

signal language_changed(code: String)

const TABLE_PATH := "res://locale/en.json"

# Язык, на который уходит всё, что не русское. Яндекс отдаёт не только ru/en:
# бывают be, kk, uk, uz, tr. Английский — международный запасной вариант и
# единственный, кроме русского, который игра действительно умеет.
const FALLBACK := "en"

var language := "ru"

var _table := {}
var _loaded := false
# Шаблоны с подстановкой: [{regex, en, holders}]. Собираются один раз из тех же
# ключей таблицы, что содержат %s/%d. Зачем — см. match_template().
var _templates: Array = []
var _templates_built := false
var _in_template := false

func _ready() -> void:
	name = "Loc"
	# Автозагрузка обязана быть инертной в headless-аудитах: там нет игрока,
	# язык всегда русский, а лишний разбор JSON только тратит время прогона.
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_table()
	detect_language()

# ------------------------------------------------------------------ таблица ---

func load_table() -> void:
	if _loaded:
		return
	_loaded = true
	if not ResourceLoader.exists(TABLE_PATH) and not FileAccess.file_exists(TABLE_PATH):
		return
	var file := FileAccess.open(TABLE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	# Испорченный или неполный файл означает «играем по-русски», а не падение.
	if parsed is Dictionary:
		_table = parsed

# ----------------------------------------------------------------- язык ------

# Определение языка идёт двумя шагами, и это не перестраховка.
#
# Мост R1604.lang() отвечает синхронно и сразу: пока SDK не ответил, он отдаёт
# navigator.language. Меню строится за первый кадр, ждать площадку оно не может
# и не должно. Когда SDK доложится (до восьми секунд), Platform поднимет
# ready_changed, и язык уточняется по environment.i18n.lang — тому самому
# источнику, которого требует пункт 2.14.
func detect_language() -> void:
	# Служебная дверь для разработки и проверок: та же схема, что у LIMBO_CIRCLE.
	# Нужна, чтобы снять английские кадры прохождения — без неё язык вне веба
	# нечем переключить, а смотреть английский текст в игре надо глазами.
	var forced := OS.get_environment("ROOM1604_LANG")
	if forced != "":
		language = normalize(forced)
		publish_language()
		return
	# Ручной выбор игрока сильнее площадки: если человек однажды переключил
	# язык сам, ответ SDK не должен переключить его обратно. Автоопределение
	# при этом никуда не девается — оно работает ровно до первого выбора.
	var chosen := saved_override()
	if chosen != "":
		language = normalize(chosen)
		publish_language()
		return
	if not is_web():
		return
	set_language(str(js_lang()))
	# set_language() молчит, когда язык не изменился, а выставить поле наружу
	# надо в любом случае — русский тоже результат определения, а не «ничего».
	publish_language()
	if has_node("/root/Platform"):
		var platform := get_node("/root/Platform")
		if not platform.ready_changed.is_connected(_on_platform_ready):
			platform.ready_changed.connect(_on_platform_ready)

# Уточнение языка по ответу площадки. Ровно один случай, когда уточнять нечем:
# площадки нет. Platform.language при этом так и лежит со значением по
# умолчанию «ru» — его же он выставляет и когда SDK не отдался за восемь секунд,
# и когда игру открыли вообще не на Яндексе. Без этой проверки игрок с
# английским браузером на любом другом хостинге получал бы английское меню,
# которое через несколько секунд молча становится русским.
func _on_platform_ready(available: bool) -> void:
	if not available:
		return
	if saved_override() != "":
		return
	if has_node("/root/Platform"):
		set_language(str(get_node("/root/Platform").language))
		publish_language()

func saved_override() -> String:
	if has_node("/root/Game"):
		return str(get_node("/root/Game").language_override)
	return ""

# Переключение языка руками. Выбор запоминается вместе с прогрессом, поэтому
# переживает и перезагрузку страницы, и переход между кругами.
func choose_language(code: String) -> void:
	var resolved := normalize(code)
	if has_node("/root/Game"):
		get_node("/root/Game").set_language_override(resolved)
	set_language(resolved)

func other_language() -> String:
	return "en" if language == "ru" else "ru"

func js_lang() -> String:
	if not is_web():
		return "ru"
	var value = JavaScriptBridge.eval("window.R1604 ? window.R1604.lang() : ''", true)
	return str(value) if value != null else ""

func is_web() -> bool:
	return OS.has_feature("web") and not Engine.is_editor_hint()

# Код языка от площадки приходит в разном виде: "ru", "en-US", "EN". Приводим к
# двум буквам и решаем ровно один вопрос — русский или запасной.
func normalize(code: String) -> String:
	var lower := code.strip_edges().to_lower().replace("_", "-")
	var head := lower.split("-")[0] if lower.contains("-") else lower
	if head == "ru":
		return "ru"
	if head == "":
		return "ru"
	return FALLBACK

func set_language(code: String) -> void:
	var resolved := normalize(code)
	if resolved == language:
		return
	language = resolved
	publish_language()
	# Экран, уже собранный на прежнем языке, обязан пересобраться сам: сигнал
	# для меню, которое строится один раз и живёт до старта круга.
	language_changed.emit(language)

# Язык, на котором игра сейчас говорит, выставляется наружу в window.R1604.
# Единственная причина: иначе выполнение требования 2.14 нечем подтвердить.
# Текст игры живёт внутри WebGL-канваса, прочитать его со страницы нельзя, и
# браузерная проверка (tools/verify_yandex_web.py) читает вместо него это поле.
#
# Заодно страница приводится в соответствие с игрой: атрибут lang документа и
# заголовок вкладки. Godot ставит заголовок из имени проекта на старте движка,
# то есть после загрузочного экрана, — значит последнее слово должно остаться
# за игрой, иначе английский игрок получит русскую вкладку.
func publish_language() -> void:
	if not is_web():
		return
	JavaScriptBridge.eval(
		"window.room1604SetGameLanguage && window.room1604SetGameLanguage('%s')" % language, true)

# --------------------------------------------------------------- перевод -----

# Перевод одной строки. Промах возвращает исходник.
func t(text: String) -> String:
	if language == "ru" or text == "" or _table.is_empty():
		return text
	var hit = _table.get(text)
	if hit != null and str(hit) != "":
		return str(hit)
	# Составные строки собираются из кусков в самой игре: осмотренный предмет
	# дописывает к описанию отклик, подсказка склеивает две фразы. Целиком такой
	# строки в таблице нет и быть не может, зато есть каждая её строка.
	if text.contains("\n"):
		var parts := text.split("\n")
		var out := PackedStringArray()
		var any := false
		for part in parts:
			var piece := line_translation(part)
			if piece != part:
				any = true
			out.append(piece)
		if any:
			return "\n".join(out)
		return text
	return line_translation(text)

# Перевод одной строки без переносов: таблица, потом шаблон с подстановкой.
func line_translation(line: String) -> String:
	if line.strip_edges() == "":
		return line
	var hit = _table.get(line)
	if hit != null and str(hit) != "":
		return str(hit)
	# Защита от бесконечного хода: match_template переводит подставленные
	# значения через t(), и без флага строка могла бы гонять по кругу.
	if not _in_template:
		_in_template = true
		var shaped := match_template(line)
		_in_template = false
		if shaped != line:
			return shaped
	return line

# Форматная строка. Подставлять надо в переведённый шаблон, а не переводить
# уже собранную строку: "Осталось: 3" в таблице нет, а "Осталось: %d" — есть.
func f(text: String, args) -> String:
	return t(text) % args

# --------------------------------------------------------------- шаблоны -----
#
# Восемь десятков строк игра собирает раньше, чем показать: `hud.show_message(
# "Осталось: %d." % left)`. В вывод приходит уже «Осталось: 3.» — строки, которой
# в таблице нет и быть не может.
#
# Можно было переписать все восемьдесят мест на Loc.f(). Не стал: это правки
# внутри девяти кругов, каждый из которых закрыт своим аудитом, ради текста,
# который логики не касается. Вместо этого шаблон узнаётся обратным ходом —
# ключ «Осталось: %d.» превращается в регулярное выражение, готовая строка
# сопоставляется с ним, а числа переставляются в английский шаблон.
#
# Ошибиться здесь безопасно: не совпало ни с чем — вернулся русский исходник.
const HOLDER_PATTERN := "%[-+ #0-9.]*[sdfxXocv]"

func build_templates() -> void:
	if _templates_built:
		return
	_templates_built = true
	var holder := RegEx.new()
	holder.compile(HOLDER_PATTERN)
	var keys := []
	for key in _table:
		if str(key).contains("%"):
			keys.append(str(key))
	# Длинные шаблоны проверяются первыми: у «Осталось: %d.» и «Протечек
	# осталось: %d.» общий хвост, и выиграть должен более определённый.
	keys.sort_custom(func(a, b): return a.length() > b.length())
	for key in keys:
		var holders := holder.search_all(key)
		if holders.is_empty():
			continue
		var pattern := "^"
		var cursor := 0
		for found in holders:
			pattern += escape_literal(key.substr(cursor, found.get_start() - cursor))
			pattern += capture_for(found.get_string())
			cursor = found.get_end()
		pattern += escape_literal(key.substr(cursor)) + "$"
		var compiled := RegEx.new()
		if compiled.compile(pattern) != OK:
			continue
		_templates.append({"regex": compiled, "en": str(_table[key])})

func capture_for(placeholder: String) -> String:
	if placeholder.ends_with("d") or placeholder.ends_with("x") \
			or placeholder.ends_with("X") or placeholder.ends_with("o"):
		return "([+-]?[0-9a-fA-F]+)"
	if placeholder.ends_with("f"):
		return "([+-]?[0-9]+(?:\\.[0-9]+)?)"
	# %s и %v заглатывают что угодно, поэтому нежадно: иначе первый же %s съел
	# бы всю строку до конца и остаток шаблона не совпал бы никогда.
	return "(.+?)"

func escape_literal(text: String) -> String:
	var out := ""
	for index in text.length():
		var symbol := text[index]
		if "\\^$.|?*+()[]{}".contains(symbol):
			out += "\\"
		out += symbol
	return out

func match_template(text: String) -> String:
	build_templates()
	for entry in _templates:
		var found: RegExMatch = (entry["regex"] as RegEx).search(text)
		if found == null:
			continue
		var result: String = entry["en"]
		var holder := RegEx.new()
		holder.compile(HOLDER_PATTERN)
		var slots := holder.search_all(result)
		if slots.size() != found.get_group_count():
			# Перевод потерял или добавил подстановку. Молча подставлять некуда,
			# и лучше показать русский оригинал, чем английский с дырой.
			continue
		# Подставляем с конца: позиции начала слотов не съезжают по ходу замены.
		for index in range(slots.size() - 1, -1, -1):
			var slot: RegExMatch = slots[index]
			# Значение подстановки само может быть названием предмета из таблицы
			# («Следующая: Зеркало»), поэтому переводится отдельно.
			var value := t(found.get_string(index + 1))
			result = result.substr(0, slot.get_start()) + value + result.substr(slot.get_end())
		return result
	return text

func table_size() -> int:
	return _table.size()
