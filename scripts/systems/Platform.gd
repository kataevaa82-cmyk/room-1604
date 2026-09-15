extends Node

# Слой площадки: SDK Яндекс Игр в вебе, полная заглушка везде ещё.
#
# Правило, из которого всё следует: игра обязана работать целиком без SDK.
# EXE на столе, запуск из редактора, headless-аудит — везде здесь тишина и
# честные значения по умолчанию. Ни один игровой путь не должен ждать ответа
# площадки, чтобы продолжиться.
#
# Что делает SDK по требованиям Яндекса:
#   * LoadingAPI.ready() — когда в игру можно играть;
#   * GameplayAPI.start()/stop() — по настоящим границам геймплея;
#   * game_api_pause/game_api_resume — площадка просит встать на паузу;
#   * межстраничная реклама только в логической паузе (у нас — переход
#     между кругами);
#   * player.setData()/getData() — облачное сохранение поверх локального.
#
# Колбэки рекламы передаются в объекте `callbacks` — это актуальная форма из
# справочника SDK. Любой исход (закрытие, отказ в показе, ошибка) освобождает
# экран перехода, поэтому реклама никогда не становится тупиком.

signal ready_changed(available: bool)

const POLL_INTERVAL := 0.25
const POLL_TIMEOUT := 8.0

var available := false
var initialised := false
var is_mobile := false
var language := "ru"

var _poll_time := 0.0
var _waited := 0.0
var _polling := false
var _ready_requested := false
var _ready_reported := false
var _gameplay_desired := false
var _gameplay_reported := false
var _host_paused := false
var _tree_paused_by_host := false
var _audio_was_muted := false
var _host_pause_callback: JavaScriptObject

func _ready() -> void:
	name = "Platform"
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_web():
		set_process(false)
		return
	install_bridge()
	_polling = true

func is_web() -> bool:
	return OS.has_feature("web") and not Engine.is_editor_hint()

# Мост на стороне страницы. Ставится один раз; сам SDK подключается статическим
# тегом в head (его вставляет tools/export_web.ps1), а здесь только
# обёртки над ним, чтобы GDScript не собирал JS строками на каждом вызове.
func install_bridge() -> void:
	JavaScriptBridge.eval("""
	(function(){
	  if (window.R1604) { return; }
	  var R = {};
	  R.pausedByHost = window.__ysdkPaused === true;
	  R.cloud = null;
	  R.cloudReady = false;
	  R.adBusy = false;
	  R.readyReported = window.__room1604LoadingReadyReported === true;
	  // Эти поля отражают уже применённое Godot состояние. Браузерная проверка
	  // релиза использует их, чтобы отличить сигнал страницы от реальной паузы.
	  R.runtimePaused = false;
	  R.runtimeMuted = false;
	  R.sdk = function(){ return window.__ysdk || null; };
	  R.ready = function(){
	    if (R.readyReported || window.__room1604LoadingReadyReported === true) { R.readyReported = true; return true; }
	    var s = R.sdk();
	    if (!s || !s.features || !s.features.LoadingAPI) { return false; }
	    try { s.features.LoadingAPI.ready(); window.__room1604LoadingReadyReported = true; R.readyReported = true; return true; } catch (e) { return false; }
	  };
	  R.gameplayStart = function(){
	    var s = R.sdk();
	    if (!s || !s.features || !s.features.GameplayAPI) { return; }
	    try { s.features.GameplayAPI.start(); } catch (e) {}
	  };
	  R.gameplayStop = function(){
	    var s = R.sdk();
	    if (!s || !s.features || !s.features.GameplayAPI) { return; }
	    try { s.features.GameplayAPI.stop(); } catch (e) {}
	  };
	  R.isMobile = function(){
	    var s = R.sdk();
	    try {
	      if (s && s.deviceInfo && typeof s.deviceInfo.isMobile === 'function') {
	        return !!(s.deviceInfo.isMobile() || s.deviceInfo.isTablet());
	      }
	    } catch (e) {}
	    // Без SDK решаем сами: игра должна быть играбельной и вне Яндекса.
	    return ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);
	  };
	  R.lang = function(){
	    var s = R.sdk();
	    try {
	      if (s && s.environment && s.environment.i18n && s.environment.i18n.lang) {
	        return s.environment.i18n.lang;
	      }
	    } catch (e) {}
	    return (navigator.language || 'ru').slice(0, 2);
	  };
	  // Реклама. adDone взводится в 1 и когда ролик закрылся, и когда он не
	  // показался, и когда упал: игра ждёт ЛЮБОГО исхода, а не успеха.
	  R.adDone = 0;
	  R.showAd = function(){
	    var s = R.sdk();
	    R.adDone = 0;
	    if (!s || !s.adv || R.adBusy) { R.adDone = 1; return; }
	    R.adBusy = true;
	    var finish = function(){ room1604SetPauseReason('ad', false); R.adBusy = false; R.adDone = 1; };
	    var options = { callbacks: {
	      onOpen: function(){ room1604SetPauseReason('ad', true); }, onClose: finish, onError: finish
	    }};
	    try { s.adv.showFullscreenAdv(options); } catch (e) { finish(); }
	  };
	  // Облачное сохранение. Результат кладём в поле, GDScript его забирает:
	  // промисы через мост не пробрасываются.
	  R.load = function(){
	    var s = R.sdk();
	    R.cloudReady = false;
	    R.cloud = null;
	    if (!s) { R.cloudReady = true; return; }
	    s.getPlayer({ scopes: false }).then(function(p){
	      R.player = p;
	      return p.getData(['room1604']);
	    }).then(function(data){
	      R.cloud = (data && data.room1604) ? JSON.stringify(data.room1604) : null;
	      R.cloudReady = true;
	    }).catch(function(){ R.cloudReady = true; });
	  };
	  R.save = function(json){
	    if (!R.player) { return; }
	    try { R.player.setData({ room1604: JSON.parse(json) }, true); } catch (e) {}
	  };
	  window.R1604 = R;
	})();
	""", true)
	# Критические pause/resume-сигналы приходят напрямую из страницы. Опрос в
	# _process остаётся запасным путём для старых шаблонов и локального запуска.
	_host_pause_callback = JavaScriptBridge.create_callback(receive_host_pause)
	var browser_window = JavaScriptBridge.get_interface("window")
	if browser_window:
		browser_window.room1604GodotPause = _host_pause_callback
	apply_host_pause(js("window.__ysdkPaused === true") == true)

func js(expression: String) -> Variant:
	if not is_web():
		return null
	return JavaScriptBridge.eval(expression, true)

func _process(delta: float) -> void:
	if _polling:
		poll_init(delta)
	# Потеря фокуса приходит через HTML-мост и обязана работать даже без SDK,
	# например на локальном или резервном хостинге.
	poll_host_pause()

# SDK грузится асинхронно, и ждать его вечно нельзя: если скрипт не отдался
# (игра открыта не на Яндексе, сеть отвалилась), через POLL_TIMEOUT просто
# идём дальше без площадки.
func poll_init(delta: float) -> void:
	_waited += delta
	_poll_time += delta
	if _poll_time < POLL_INTERVAL:
		return
	_poll_time = 0.0
	if js("window.__ysdkReady === true") == true:
		finish_init()
		return
	if _waited >= POLL_TIMEOUT:
		# Скрипт SDK не отдался: игра открыта не на Яндексе или сеть молчит.
		# Идём дальше без площадки — это обычный рабочий режим, не ошибка.
		_polling = false
		initialised = true
		available = false
		ready_changed.emit(false)
		# Вне Яндекса или при сетевой ошибке API вызвать невозможно. Только после
		# завершения ожидания разрешаем запасной путь убрать загрузочный экран.
		sync_ready()

func finish_init() -> void:
	_polling = false
	initialised = true
	available = js("!!window.R1604 && !!window.R1604.sdk()") == true
	if available:
		is_mobile = js("window.R1604.isMobile()") == true
		language = str(js("window.R1604.lang()"))
		# События game_api_pause/resume подписаны через ysdk.on() в раннем
		# HTML-bootstrap. Забираем состояние, если стартовая реклама успела
		# открыться ещё до запуска Godot.
		js("window.R1604.pausedByHost = window.__ysdkPaused === true")
		js("window.R1604.load()")
		request_cloud_progress()
	else:
		is_mobile = js("window.R1604 ? window.R1604.isMobile() : false") == true
	ready_changed.emit(available)
	sync_ready()
	sync_gameplay()

# Сообщить площадке, что в игру можно играть. Требование обязательное:
# по этому вызову Яндекс считает метрику готовности.
func report_ready() -> void:
	_ready_requested = true
	sync_ready()

func sync_ready() -> void:
	if not _ready_requested:
		return
	if available:
		if _ready_reported:
			return
		if js("window.R1604.ready()") == true:
			_ready_reported = true
			# Сначала сообщаем площадке, затем открываем игроку уже переведённое
			# меню. Так GameReady не запаздывает относительно интерактивности, а
			# язык SDK не переключается у игрока на глазах.
			js("window.room1604GameReady && window.room1604GameReady()")
		return
	# Пока YaGames.init() ещё ожидается, лоадер обязан оставаться на месте.
	# Если ожидание завершилось без SDK, не превращаем сторонний хостинг в тупик.
	if initialised:
		js("window.room1604GameReady && window.room1604GameReady()")

func gameplay_start() -> void:
	_gameplay_desired = true
	sync_gameplay()

func gameplay_stop() -> void:
	_gameplay_desired = false
	sync_gameplay()

# Отделяем желаемое состояние от уже отправленного. Меню может закрыться до
# завершения YaGames.init(), а пауза площадки может вклиниться в любой момент.
# После инициализации и после resume отправляется ровно одно актуальное событие.
func sync_gameplay() -> void:
	if not available:
		return
	var should_run := _gameplay_desired and not _host_paused
	if should_run and not _gameplay_reported:
		js("window.R1604.gameplayStart()")
		_gameplay_reported = true
	elif not should_run and _gameplay_reported:
		js("window.R1604.gameplayStop()")
		_gameplay_reported = false

# Площадка сама просит паузу (например, под свою рекламу). Требование:
# геймплей и звук на это время останавливаются.
func poll_host_pause() -> void:
	var paused_now: bool = js("window.R1604.pausedByHost === true") == true
	apply_host_pause(paused_now)

func receive_host_pause(arguments: Array) -> void:
	if arguments.is_empty():
		return
	apply_host_pause(bool(arguments[0]))

func apply_host_pause(paused_now: bool) -> void:
	if paused_now == _host_paused:
		return
	_host_paused = paused_now
	if _host_paused:
		_tree_paused_by_host = not get_tree().paused
		if _tree_paused_by_host:
			get_tree().paused = true
		_audio_was_muted = AudioServer.is_bus_mute(0)
		AudioServer.set_bus_mute(0, true)
	else:
		if _tree_paused_by_host:
			get_tree().paused = false
		_tree_paused_by_host = false
		AudioServer.set_bus_mute(0, _audio_was_muted)
	publish_pause_state()
	sync_gameplay()

func publish_pause_state() -> void:
	if not is_web():
		return
	var paused_text := "true" if get_tree().paused else "false"
	var muted_text := "true" if AudioServer.is_bus_mute(0) else "false"
	js("window.R1604.runtimePaused=%s;window.R1604.runtimeMuted=%s" % [paused_text, muted_text])

# --------------------------------------------------------------- реклама ---

# Показать межстраничную рекламу. Возвращает true, если показ вообще начат:
# вызывающий всё равно НЕ обязан её дожидаться — на экране перехода крутится
# собственный таймер, и зависший ролик игрока не задержит.
func show_interstitial() -> bool:
	if not available:
		return false
	js("window.R1604.showAd()")
	return true

func interstitial_finished() -> bool:
	if not available:
		return true
	return js("window.R1604.adDone === 1") == true

# ------------------------------------------------------------- сохранение ---

func save_progress(data: Dictionary) -> void:
	if not available:
		return
	js("window.R1604.save(%s)" % JSON.stringify(JSON.stringify(data)))

# Облако отвечает асинхронно. Ждём его в фоне и, когда придёт, отдаём в Game —
# он сам решит, принимать ли (меньший облачный прогресс локальный не затирает).
func request_cloud_progress() -> void:
	var waited := 0.0
	while waited < POLL_TIMEOUT:
		await get_tree().create_timer(POLL_INTERVAL).timeout
		waited += POLL_INTERVAL
		if js("window.R1604.cloudReady === true") == true:
			break
	var raw = js("window.R1604.cloud")
	if raw == null or str(raw).is_empty():
		return
	var parsed = JSON.parse_string(str(raw))
	if parsed is Dictionary:
		Game.merge_cloud_progress(parsed as Dictionary)
