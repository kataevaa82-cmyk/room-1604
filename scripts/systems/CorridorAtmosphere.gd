extends Node

# Тихая атмосфера коридора без внешних аудиофайлов. Оба сигнала собираются в
# памяти при запуске, поэтому система не увеличивает PCK: у лифта едва слышен
# ровный электрический гул. Никаких внезапных стуков, скрипов и пугающих cue.
# Свет дышит не сильнее двух процентов и редко проседает на одну десятую секунды.

var player: CharacterBody3D
var corridor_lights: Array[OmniLight3D] = []
var base_energy: Array[float] = []
var hum: AudioStreamPlayer3D
var elapsed := 0.0
var flicker_at := 13.0
var flicker_until := -1.0
var flicker_index := -1

func _ready() -> void:
	player = get_tree().current_scene.get_node_or_null("Player") as CharacterBody3D
	for node in get_parent().find_children("CorridorLight*", "OmniLight3D", true, false):
		var light := node as OmniLight3D
		corridor_lights.append(light)
		base_energy.append(light.light_energy)
	# Аудиоустройство в headless-аудите не нужно; световая часть остаётся и
	# проверяется тем же запуском сцены.
	if DisplayServer.get_name() != "headless":
		build_audio()

func build_audio() -> void:
	hum = AudioStreamPlayer3D.new()
	hum.name = "ElevatorElectricalHum"
	hum.stream = make_hum()
	hum.position = Vector3(3.12, 1.75, -4.60)
	hum.volume_db = -39.0
	hum.max_distance = 8.0
	hum.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	get_parent().add_child.call_deferred(hum)
	hum.ready.connect(func() -> void: hum.play())

func make_hum() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 11025
	wav.stereo = false
	var frames := wav.mix_rate * 2
	var samples := PackedByteArray()
	samples.resize(frames)
	var low_noise := 0.0
	for i in range(frames):
		var seconds := float(i) / float(wav.mix_rate)
		var raw := fmod(absf(sin(float(i) * 12.9898) * 43758.5453), 1.0) * 2.0 - 1.0
		low_noise = lerpf(low_noise, raw, .012)
		var value := sin(TAU * 50.0 * seconds) * 2.2 \
			+ sin(TAU * 100.0 * seconds) * .7 + low_noise * 3.2
		samples[i] = int(clampf(128.0 + value, 0.0, 255.0))
	wav.data = samples
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = frames
	return wav

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= flicker_at:
		flicker_index = randi_range(0, maxi(corridor_lights.size() - 1, 0))
		flicker_until = elapsed + .10
		flicker_at = elapsed + randf_range(14.0, 29.0)
	for i in range(corridor_lights.size()):
		if not is_instance_valid(corridor_lights[i]):
			continue
		var breath := .99 + sin(elapsed * .34 + float(i) * 1.7) * .01
		var dip := .72 if i == flicker_index and elapsed < flicker_until else 1.0
		corridor_lights[i].light_energy = base_energy[i] * breath * dip
	if hum and player:
		var target := -39.0 if player.global_position.z < -3.0 else -60.0
		hum.volume_db = lerpf(hum.volume_db, target, minf(delta * 1.4, 1.0))
