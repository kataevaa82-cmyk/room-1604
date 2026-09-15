class_name Build
extends RefCounted

# Примитивы, из которых собираются все рантайм-пропы уровней.
# Вынесено из LimboController, чтобы круги II-IX не копировали одно и то же.

static func box(parent: Node, name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = position
	node.material_override = flat(color)
	parent.add_child(node)
	return node

static func torus(parent: Node, name: String, position: Vector3, inner: float, outer: float, color: Color, rotation: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	node.mesh = mesh
	node.position = position
	node.rotation = rotation
	var material := flat(color)
	material.metallic = .7
	node.material_override = material
	parent.add_child(node)
	return node

static func capsule(parent: Node, name: String, position: Vector3, radius: float, height: float, color: Color, rotation: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	node.mesh = mesh
	node.position = position
	node.rotation = rotation
	node.material_override = flat(color, .4)
	parent.add_child(node)
	return node

static func sphere(parent: Node, name: String, position: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	node.mesh = mesh
	node.position = position
	node.material_override = flat(color, .4)
	parent.add_child(node)
	return node

static func label3d(parent: Node, name: String, text: String, position: Vector3, rotation: Vector3, font_size: int, pixel_size: float) -> Label3D:
	var label := Label3D.new()
	label.name = name
	# Надписи внутри комнаты — тоже текст для игрока: след на стене, оборот
	# карточки. Часы и номера при этом состоят из цифр, и перевод их не тронет:
	# промах таблицы возвращает исходную строку.
	label.text = Loc.t(text)
	label.position = position
	label.rotation = rotation
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.outline_size = 4
	parent.add_child(label)
	return label

static func flat(color: Color, roughness := .55) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

# Материал для следов, проступающих в темноте: почти не виден при свете,
# светится сам по себе, когда комнату гасят.
static func latent(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.0
	return material

static func area(parent: Node, name: String, position: Vector3, size: Vector3) -> Area3D:
	var node := Area3D.new()
	node.name = name
	node.position = position
	node.collision_layer = 2
	node.collision_mask = 0
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	node.add_child(shape_node)
	parent.add_child(node)
	return node

# Переносит origin узла в заданную точку, не сдвигая его визуально:
# нужно, чтобы вращать дверцу шкафа или картину вокруг правильной оси.
static func move_pivot(node: Node3D, pivot: Vector3) -> void:
	if not node or not node.position.is_zero_approx():
		return
	for child in node.get_children():
		if child is Node3D:
			child.position -= pivot
	node.position = pivot
