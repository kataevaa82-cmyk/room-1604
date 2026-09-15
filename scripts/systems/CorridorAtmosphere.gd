extends Node

# Свет коридора дышит не сильнее двух процентов и редко проседает на одну
# десятую секунды. Звуковая часть удалена полностью.

var corridor_lights: Array[OmniLight3D] = []
var base_energy: Array[float] = []
var elapsed := 0.0
var update_accumulator := 0.0
var flicker_at := 13.0
var flicker_until := -1.0
var flicker_index := -1

func _ready() -> void:
	for node in get_parent().find_children("CorridorLight*", "OmniLight3D", true, false):
		var light := node as OmniLight3D
		corridor_lights.append(light)
		base_energy.append(light.light_energy)

func _process(delta: float) -> void:
	elapsed += delta
	update_accumulator += delta
	# Медленное «дыхание» света не требует 60 обновлений в секунду. Ограничение
	# до 20 Гц убирает лишние записи в RenderingServer на каждом web-кадре.
	if update_accumulator < .05:
		return
	update_accumulator = 0.0
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
