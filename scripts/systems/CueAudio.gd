class_name CueAudio
extends Node

# Весь звук уровня синтезируется в рантайме: для Яндекс Игр вес сборки важнее,
# чем качество сэмплов. Ни одного .ogg, ни одной озвучки.

const FREQUENCY := {
	"tick": 1250.0, "locked": 145.0, "unlock": 620.0, "tv": 95.0,
	"drip": 720.0, "water": 260.0, "metal": 980.0, "flicker": 70.0,
	"card": 840.0, "switch": 510.0, "wipe": 330.0, "paper": 640.0,
	"creak": 110.0, "ring": 880.0, "dial": 1480.0, "rewind": 220.0,
	"latch": 300.0, "breath": 90.0
}
const DURATION := {
	"water": .45, "flicker": .18, "tv": .12, "unlock": .14, "switch": .055,
	"wipe": .16, "paper": .22, "creak": .55, "ring": .35, "rewind": .30,
	"latch": .10, "breath": .70
}
const LOUD := ["unlock", "flicker", "ring", "creak"]

var streams := {}
var hum: AudioStreamPlayer
var positional := {}

# Звук выключен по решению владельца после первого прогона: процедурные
# сигналы звучали дёшево и мешали. Система оставлена целиком — когда появятся
# настоящие сэмплы, достаточно вернуть enabled = true, все вызовы на местах.
var enabled := false

func _ready() -> void:
	name = "CueAudio"
	if enabled:
		build_hum()

# Звук без позиции — для UI-подтверждений и общекомнатных событий.
func play(kind: String, volume_shift := 0.0) -> void:
	if not enabled:
		return
	if not streams.has(kind):
		streams[kind] = build_stream(kind)
	var player := AudioStreamPlayer.new()
	player.stream = streams[kind]
	player.volume_db = (-9.0 if kind in LOUD else -16.0) + volume_shift
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

# Звук из точки комнаты. Основной канал подсказок в круге без проводника:
# игрок должен повернуть голову на источник, а не прочитать инструкцию.
func play_at(kind: String, position: Vector3, volume_shift := 0.0) -> void:
	if not enabled:
		return
	if not streams.has(kind):
		streams[kind] = build_stream(kind)
	var player := AudioStreamPlayer3D.new()
	player.stream = streams[kind]
	player.unit_size = 4.0
	player.max_db = 0.0
	player.volume_db = (-4.0 if kind in LOUD else -10.0) + volume_shift
	add_child(player)
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()

func build_stream(kind: String) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var frequency: float = FREQUENCY.get(kind, 440.0)
	var duration: float = DURATION.get(kind, .075)
	var frames := int(wav.mix_rate * duration)
	var samples := PackedByteArray()
	samples.resize(frames)
	for i in range(frames):
		var progress := float(i) / float(frames)
		var envelope := 1.0 - progress
		var value := sin(TAU * frequency * float(i) / wav.mix_rate) * 29.0 * envelope
		match kind:
			"water":
				value = noise(float(i) * 12.9898) * 21.0 * minf(1.0, envelope * 6.0)
			"tv", "flicker":
				value = noise(float(i) * 9.731) * (18.0 if kind == "tv" else 25.0) * envelope
			"creak":
				# Скрип: тон ползёт вверх и дрожит — дверь, петля, половица.
				var bend := frequency * (1.0 + progress * 1.6)
				value = sin(TAU * bend * float(i) / wav.mix_rate) * 22.0 * envelope
				value += noise(float(i) * 4.11) * 7.0 * envelope
			"ring":
				# Телефонный звонок: две частоты и заметная амплитудная пульсация.
				var beat := 0.5 + 0.5 * sin(TAU * 22.0 * progress)
				value = (sin(TAU * frequency * float(i) / wav.mix_rate) + sin(TAU * frequency * 1.25 * float(i) / wav.mix_rate)) * 13.0 * beat * envelope
			"rewind":
				# Откат времени: тон падает вниз.
				var falling := frequency * (1.0 - progress * 0.55)
				value = sin(TAU * falling * float(i) / wav.mix_rate) * 24.0 * envelope
			"breath":
				value = noise(float(i) * 2.017) * 12.0 * sin(PI * progress)
		samples[i] = int(clamp(128.0 + value, 0.0, 255.0))
	wav.data = samples
	return wav

func noise(seed_value: float) -> float:
	return fmod(abs(sin(seed_value) * 43758.5453), 1.0) * 2.0 - 1.0

func build_hum() -> void:
	hum = AudioStreamPlayer.new()
	hum.name = "RoomHum"
	hum.volume_db = -31.0
	add_child(hum)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 11025
	wav.stereo = false
	var samples := PackedByteArray()
	samples.resize(11025)
	for i in range(samples.size()):
		var phase := float(i) / float(samples.size())
		var value := sin(TAU * 54.0 * phase) * 5.0 + sin(TAU * 81.0 * phase) * 3.0
		samples[i] = int(clamp(128.0 + value, 0.0, 255.0))
	wav.data = samples
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples.size()
	hum.stream = wav

func start_hum() -> void:
	if enabled and hum and not hum.playing:
		hum.play()

func stop_hum() -> void:
	if hum:
		hum.stop()

func shutdown() -> void:
	if hum:
		hum.stop()
		hum.stream = null
	streams.clear()
