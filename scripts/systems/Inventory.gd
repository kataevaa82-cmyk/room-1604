class_name Inventory
extends Node

# Четыре слота. Предмет не применяется сам: игрок выбирает его цифрой и сам
# решает, куда приложить. Именно этого не хватало прежней версии, где ключ
# срабатывал автоматически в единственном разрешённом месте.

signal changed()
signal selection_changed(id: String)

const CAPACITY := 4

var items: Array[Dictionary] = []
var selected_index := -1
var hud: Hud
var cue: CueAudio
var slot_labels: Array[Label] = []

func setup(target_hud: Hud, audio: CueAudio) -> void:
	name = "Inventory"
	hud = target_hud
	cue = audio
	for i in range(CAPACITY):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(126, 34)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		hud.slots_row.add_child(panel)
		slot_labels.append(label)
	refresh()

func add(id: String, display_name: String, prop: Node3D = null, text := "", reverse := "") -> bool:
	if has(id) or items.size() >= CAPACITY:
		return false
	items.append({"id": id, "name": display_name, "prop": prop, "text": text, "reverse": reverse})
	if selected_index < 0:
		selected_index = items.size() - 1
	if cue:
		cue.play("paper")
	refresh()
	changed.emit()
	return true

func remove(id: String) -> void:
	for i in range(items.size()):
		if items[i]["id"] == id:
			items.remove_at(i)
			selected_index = clampi(selected_index, -1, items.size() - 1)
			if items.is_empty():
				selected_index = -1
			refresh()
			changed.emit()
			return

func has(id: String) -> bool:
	for item in items:
		if item["id"] == id:
			return true
	return false

# Номер слота так, как он подписан на панели (1..4). 0 — предмета нет.
# Нужен подсказкам: жёстко названная клавиша врёт, потому что порядок слотов
# зависит от того, что игрок подобрал раньше.
func slot_of(id: String) -> int:
	for i in range(items.size()):
		if items[i]["id"] == id:
			return i + 1
	return 0

func selected() -> String:
	if selected_index < 0 or selected_index >= items.size():
		return ""
	return str(items[selected_index]["id"])

func selected_data() -> Dictionary:
	if selected_index < 0 or selected_index >= items.size():
		return {}
	return items[selected_index]

func data(id: String) -> Dictionary:
	for item in items:
		if item["id"] == id:
			return item
	return {}

func select_by_id(id: String) -> void:
	for i in range(items.size()):
		if items[i]["id"] == id:
			selected_index = i
			refresh()
			selection_changed.emit(id)
			return

func select(index: int) -> void:
	if index < 0 or index >= items.size() or index == selected_index:
		return
	selected_index = index
	if cue:
		cue.play("switch", -6.0)
	refresh()
	selection_changed.emit(selected())

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	var key := (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_4:
		select(key - KEY_1)

func refresh() -> void:
	for i in range(CAPACITY):
		var label := slot_labels[i]
		var panel := label.get_parent() as PanelContainer
		if i >= items.size():
			label.text = ""
			panel.modulate.a = 0.0
			continue
		panel.modulate.a = 1.0
		var chosen := i == selected_index
		label.text = "%d  %s" % [i + 1, items[i]["name"]]
		label.add_theme_color_override("font_color", Color("e8c07d") if chosen else Color(.78, .75, .69, .7))

func clear() -> void:
	items.clear()
	selected_index = -1
	refresh()
	changed.emit()
