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
# Про форму колбэков рекламы: документация противоречит сама себе. Сигнатура
# в справочнике показывает onOpen/onClose/onError на верхнем уровне, а примеры
# по экосистеме оборачивают их в объект `callbacks`. Передаём ОБЕ формы разом
# и намеренно без самоссылки: цикл в объекте уронил бы JSON.stringify внутри
# SDK, если он там есть.

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
var _gameplay_running := false
var _ready_requested := false

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
# тегом в head (см. html/head_include в export_presets.cfg), а здесь только
# обёртки над ним, чтобы GDScript не собирал JS строками на каждом вызове.
func install_bridge() -> void:
	JavaScriptBridge.eval("""
	(function(){
	  if (window.R1604) { return; }
	  var R = {};
	  R.pausedByHost = false;
	  R.cloud = null;
	  R.cloudReady = false;
	  R.adBusy = false;
	  R.sdk = function(){ return window.__ysdk || null; };
	  R.ready = function(){
	    var s = R.sdk();
	    if (!s || !s.features || !s.features.LoadingAPI) { return false; }
	    try { s.features.LoadingAPI.ready(); return true; } catch (e) { return false; }
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
	    var finish = function(){ R.adBusy = false; R.adDone = 1; };
	    var handlers = { onOpen: function(){}, onClose: finish, onError: finish };
	    // Обе формы разом: справочник и примеры расходятся, какая верна.
	    // Без самоссылки — цикл уронил бы JSON.stringify внутри SDK.
	    var options = {
	      onOpen: handlers.onOpen, onClose: handlers.onClose, onError: handlers.onError,
	      callbacks: { onOpen: handlers.onOpen, onClose: handlers.onClose, onError: handlers.onError }
	    };
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
	  // Площадка просит паузу — например, когда показывает свою рекламу.
	  window.addEventListener('game_api_pause', function(){ R.pausedByHost = true; });
	  window.addEventListener('game_api_resume', function(){ R.pausedByHost = false; });
	  window.R1604 = R;
	})();
	""", true)

func js(expression: String) -> Variant:
	if not is_web():
		return null
	return JavaScriptBridge.eval(expression, true)

func _process(delta: float) -> void:
	if _polling:
		poll_init(delta)
	if available:
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

func finish_init() -> void:
	_polling = false
	initialised = true
	available = js("!!window.R1604 && !!window.R1604.sdk()") == true
	if available:
		is_mobile = js("window.R1604.isMobile()") == true
		language = str(js("window.R1604.lang()"))
		js("window.R1604.load()")
		request_cloud_progress()
	else:
		is_mobile = js("window.R1604 ? window.R1604.isMobile() : false") == true
	ready_changed.emit(available)
	if _ready_requested and available:
		js("window.R1604.ready()")

# Сообщить площадке, что в игру можно играть. Требование обязательное:
# по этому вызову Яндекс считает метрику готовности.
func report_ready() -> void:
	_ready_requested = true
	if available:
		js("window.R1604.ready()")

func gameplay_start() -> void:
	if available and not _gameplay_running:
		_gameplay_running = true
		js("window.R1604.gameplayStart()")

func gameplay_stop() -> void:
	if available and _gameplay_running:
		_gameplay_running = false
		js("window.R1604.gameplayStop()")

# Площадка сама просит паузу (например, под свою рекламу). Требование:
# геймплей и звук на это время останавливаются.
func poll_host_pause() -> void:
	var paused = js("window.R1604.pausedByHost === true")
	if paused == true and not get_tree().paused:
		get_tree().paused = true
		AudioServer.set_bus_mute(0, true)
	elif paused == false and AudioServer.is_bus_mute(0):
		AudioServer.set_bus_mute(0, false)

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
