class_name AnomalyDirector
extends Node

# Комната меняется только тогда, когда на неё не смотрят.
#
# Это самый дешёвый настоящий хоррор из доступных: ни моделей, ни анимаций,
# ни звука — игрок отворачивается, и мир за спиной становится другим. Прежняя
# версия делала это ровно один раз через затемнение экрана; здесь это правило.

signal triggered(id: String)

const CHECK_INTERVAL := .18

var camera: Camera3D
var cue: CueAudio
var space: PhysicsDirectSpaceState3D
var entries := {}
var check_timer := 0.0

func setup(target_camera: Camera3D, audio: CueAudio) -> void:
	name = "AnomalyDirector"
	camera = target_camera
	cue = audio

# apply/revert — Callable без аргументов. watch — точка, которая должна быть
# вне поля зрения; по умолчанию берётся позиция самого узла.
func register(id: String, node: Node3D, apply: Callable, revert: Callable, opts := {}) -> void:
	entries[id] = {
		"node": node,
		"apply": apply,
		"revert": revert,
		"watch": opts.get("watch", Vector3.INF),
		"cue": str(opts.get("cue", "")),
		"delay": float(opts.get("delay", 0.0)),
		"armed": false,
		"applied": false,
		"waited": 0.0
	}

func arm(id: String) -> void:
	if entries.has(id) and not entries[id]["applied"]:
		entries[id]["armed"] = true
		entries[id]["waited"] = 0.0

func arm_all(ids: Array) -> void:
	for id in ids:
		arm(id)

func is_applied(id: String) -> bool:
	return entries.has(id) and bool(entries[id]["applied"])

func applied_count(ids: Array) -> int:
	var total := 0
	for id in ids:
		if is_applied(id):
			total += 1
	return total

# Немедленное применение — для сюжетных сломов, которые не ждут отворота.
func force(id: String) -> void:
	if not entries.has(id) or entries[id]["applied"]:
		return
	apply_entry(id)

func revert(id: String) -> void:
	if not entries.has(id) or not entries[id]["applied"]:
		return
	var entry: Dictionary = entries[id]
	entry["applied"] = false
	entry["armed"] = false
	var callable: Callable = entry["revert"]
	if callable.is_valid():
		callable.call()

func revert_all() -> void:
	for id in entries:
		revert(id)

func _physics_process(delta: float) -> void:
	if entries.is_empty() or not camera or not camera.is_inside_tree():
		return
	check_timer -= delta
	if check_timer > 0.0:
		return
	check_timer = CHECK_INTERVAL
	space = camera.get_world_3d().direct_space_state
	for id in entries:
		var entry: Dictionary = entries[id]
		if not entry["armed"] or entry["applied"]:
			continue
		if not is_unobserved(entry):
			entry["waited"] = 0.0
			continue
		entry["waited"] += CHECK_INTERVAL
		if entry["waited"] >= float(entry["delay"]):
			apply_entry(id)

func apply_entry(id: String) -> void:
	var entry: Dictionary = entries[id]
	entry["applied"] = true
	entry["armed"] = false
	var callable: Callable = entry["apply"]
	if callable.is_valid():
		callable.call()
	if cue and not str(entry["cue"]).is_empty():
		cue.play_at(str(entry["cue"]), watch_point(entry), -3.0)
	triggered.emit(id)

func watch_point(entry: Dictionary) -> Vector3:
	var watch: Vector3 = entry["watch"]
	if watch != Vector3.INF:
		return watch
	var node: Node3D = entry["node"]
	if node and node.is_inside_tree():
		return node.global_position
	return Vector3.ZERO

func is_unobserved(entry: Dictionary) -> bool:
	var point := watch_point(entry)
	if not camera.is_position_in_frustum(point):
		return true
	# Точка в кадре — но стена между камерой и предметом всё равно означает,
	# что игрок его не видит.
	if not space:
		return false
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, point)
	query.collision_mask = 1
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	return not hit.is_empty()

func clear() -> void:
	revert_all()
	for id in entries:
		entries[id]["armed"] = false
		entries[id]["applied"] = false
		entries[id]["waited"] = 0.0
