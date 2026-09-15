class_name LevelMap
extends Control

# Схема рисуется кодом, поэтому остаётся резкой при любом размере окна и не
# добавляет в web-сборку ещё одну текстуру. Координаты совпадают с main.gd:
# X идёт слева направо, Z — сверху вниз.
const WORLD_MIN := Vector2(-6.8, -6.1)
const WORLD_MAX := Vector2(4.5, 5.75)

const INK := Color("b8ad99")
const LINE := Color("8f816d")
const AMBER := Color("e8c07d")
const PLAYER := Color("e9ecef")
const DIM := Color("746c61")

const ROOMS := [
	[Vector2(-6.7, -6.0), Vector2(3.5, -3.2), "КОРИДОР", Color("17191d")],
	[Vector2(-4.4, -3.2), Vector2(-1.95, -.95), "ПРИХОЖАЯ", Color("211d19")],
	[Vector2(-1.95, -3.2), Vector2(4.4, .75), "СПАЛЬНЯ", Color("1e1b1a")],
	[Vector2(-4.4, -.95), Vector2(-1.95, 3.2), "ВАННАЯ", Color("1a2021")],
	[Vector2(-1.95, .75), Vector2(4.4, 5.65), "ГОСТИНАЯ", Color("211d18")]
]

# Никаких названий предметов: только условные знаки. Они дают направление,
# но не раскрывают, что именно и в каком порядке придётся делать.
const MARKERS := [
	[Vector2(-2.65, -3.13), "threshold"],
	[Vector2(-2.05, -2.65), "light"],
	[Vector2(-1.86, -1.15), "light"],
	[Vector2(-2.75, .25), "light"],
	[Vector2(.18, .84), "light"],
	[Vector2(2.61, -2.78), "voice"],
	[Vector2(-1.55, -.15), "memory"],
	[Vector2(1.25, -3.08), "image"],
	[Vector2(-4.18, -.30), "reflection"],
	[Vector2(-3.18, 2.71), "water"],
	[Vector2(2.28, .835), "time"],
	[Vector2(-1.82, 3.15), "screen"],
	[Vector2(3.98, 1.55), "writing"],
	[Vector2(4.05, 4.68), "hunger"],
	[Vector2(2.20, 4.85), "seat"]
]

var player_world := Vector2.ZERO
var has_player := false

func _ready() -> void:
	custom_minimum_size = Vector2(760, 330)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_player_position(position: Vector3) -> void:
	player_world = Vector2(position.x, position.z)
	has_player = true
	queue_redraw()

func map_point(world: Vector2, area: Rect2) -> Vector2:
	var ratio := (world - WORLD_MIN) / (WORLD_MAX - WORLD_MIN)
	return area.position + ratio * area.size

func map_rect(minimum: Vector2, maximum: Vector2, area: Rect2) -> Rect2:
	var first := map_point(minimum, area)
	var last := map_point(maximum, area)
	return Rect2(first, last - first)

# Названия комнат приходят из константной таблицы, поэтому переводятся здесь, в
# единственном месте, где карта их рисует. Ширина считается уже по переведённой
# строке — иначе английское слово уехало бы мимо центра комнаты.
func centered_text(font: Font, center: Vector2, text: String, font_size: int, color: Color) -> void:
	var shown := Loc.t(text)
	var text_size := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, center + Vector2(-text_size.x * .5, text_size.y * .35), shown,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	var area := Rect2(Vector2(30, 10), Vector2(maxf(size.x - 60.0, 100.0), maxf(size.y - 54.0, 100.0)))
	draw_rect(Rect2(Vector2.ZERO, size), Color("090a0c"), true)
	for room in ROOMS:
		var rect := map_rect(room[0], room[1], area)
		draw_rect(rect, room[3], true)
		draw_rect(rect, LINE, false, 2.0, true)
		centered_text(ThemeDB.fallback_font, rect.get_center(), room[2], 13, DIM)

	# Дверные разрывы помогают читать план, но не подсказывают маршрут задачи.
	for door in [
		[Vector2(-2.65, -3.2), Vector2(-2.65, -2.98)],
		[Vector2(-1.95, -2.30), Vector2(-1.95, -1.40)],
		[Vector2(-2.85, -.95), Vector2(-2.05, -.95)],
		[Vector2(-1.0, .75), Vector2(-.10, .75)]
	]:
		var a := map_point(door[0], area)
		var b := map_point(door[1], area)
		draw_line(a, b, Color("090a0c"), 5.0, true)

	for marker in MARKERS:
		draw_marker(marker[1], map_point(marker[0], area))

	if has_player:
		var here := map_point(player_world, area)
		draw_circle(here, 7.0, Color("11151a"), true)
		draw_circle(here, 5.0, PLAYER, true)
		draw_circle(here, 8.0, PLAYER, false, 1.5, true)
		draw_string(ThemeDB.fallback_font, here + Vector2(11, 5), Loc.t("ВЫ"),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PLAYER)

	draw_string(ThemeDB.fallback_font, Vector2(0, size.y - 8),
		Loc.t("свет  ·  голос  ·  отражение  ·  время  ·  память  ·  порог"),
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, INK)

func draw_marker(kind: String, center: Vector2) -> void:
	draw_circle(center, 8.5, Color(0.035, .035, .04, .92), true)
	draw_circle(center, 8.5, AMBER, false, 1.15, true)
	match kind:
		"light":
			draw_line(center + Vector2(-4, 0), center + Vector2(4, 0), AMBER, 1.5, true)
			draw_line(center + Vector2(0, -4), center + Vector2(0, 4), AMBER, 1.5, true)
		"voice":
			for radius in [2.0, 4.5, 7.0]:
				draw_arc(center + Vector2(-3, 0), radius, -.7, .7, 10, AMBER, 1.2, true)
		"time":
			draw_circle(center, 5.2, AMBER, false, 1.2, true)
			draw_line(center, center + Vector2(0, -3.5), AMBER, 1.2, true)
			draw_line(center, center + Vector2(3, 1.5), AMBER, 1.2, true)
		"reflection":
			draw_polyline(PackedVector2Array([center + Vector2(0, -6), center + Vector2(5, 0),
				center + Vector2(0, 6), center + Vector2(-5, 0), center + Vector2(0, -6)]), AMBER, 1.2, true)
		"memory":
			draw_rect(Rect2(center - Vector2(4.5, 6), Vector2(9, 12)), AMBER, false, 1.2, true)
			draw_line(center + Vector2(0, -5), center + Vector2(0, 5), AMBER, 1.0, true)
		"image":
			draw_rect(Rect2(center - Vector2(6, 4), Vector2(12, 8)), AMBER, false, 1.2, true)
			draw_line(center + Vector2(-4, 2), center + Vector2(-1, -1), AMBER, 1.0, true)
			draw_line(center + Vector2(-1, -1), center + Vector2(4, 2), AMBER, 1.0, true)
		"screen":
			draw_rect(Rect2(center - Vector2(6, 4.5), Vector2(12, 8)), AMBER, false, 1.2, true)
			draw_line(center + Vector2(-2, 5), center + Vector2(2, 5), AMBER, 1.2, true)
		"water":
			draw_arc(center + Vector2(0, 2), 4.5, 0.0, PI, 12, AMBER, 1.2, true)
			draw_line(center + Vector2(-4.5, 2), center + Vector2(0, -6), AMBER, 1.2, true)
			draw_line(center + Vector2(4.5, 2), center + Vector2(0, -6), AMBER, 1.2, true)
		"writing":
			for y in [-4.0, 0.0, 4.0]:
				draw_line(center + Vector2(-5, y), center + Vector2(5, y), AMBER, 1.1, true)
		"hunger":
			draw_circle(center + Vector2(-2, 0), 3.5, AMBER, false, 1.1, true)
			draw_line(center + Vector2(3, -5), center + Vector2(3, 5), AMBER, 1.1, true)
		"threshold":
			draw_line(center + Vector2(-4, 6), center + Vector2(-4, -6), AMBER, 1.3, true)
			draw_arc(center + Vector2(-4, 6), 10.0, -PI * .5, 0.0, 10, AMBER, 1.1, true)
		"seat":
			draw_arc(center, 5.5, 0.0, PI, 12, AMBER, 1.2, true)
			draw_line(center + Vector2(-5.5, 0), center + Vector2(-5.5, 5), AMBER, 1.2, true)
			draw_line(center + Vector2(5.5, 0), center + Vector2(5.5, 5), AMBER, 1.2, true)
