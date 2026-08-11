# Общий набор для генераторов пропсов этого проекта.
#
# Отдельным файлом, чтобы у геометрических помощников была одна копия: два
# генератора со своими копиями Prop разойдутся, и разница вылезет не в коде, а
# в готовых .glb, где её никто не заметит.
#
# Пользоваться так (см. make_corridor_props.py, make_circle2_props.py):
#
#     import sys, os
#     sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
#     from blender_prop_kit import Prop, run
#     run({"my_prop.glb": my_prop_factory})
#
# Договорённости с игрой, которые нельзя менять в одиночку:
#
# 1. Имена материалов — это контракт. main.gd::apply_model_palette() смотрит на
#    resource_name материала и подменяет его материалом сцены; незнакомое имя
#    молча становится "wood2".
# 2. Модели авторские в финальном масштабе (метры) и с началом координат в точке
#    крепления: MultiMesh ставит меш как есть, без подгонки размера.
# 3. Blender Z-вверх, glTF Y-вверх. Экспортёр поворачивает сам, поэтому здесь
#    высота — это Z, а «наружу от стены» — это -Y (в Godot станет +Z).

import math
import os
import sys

import bmesh
import bpy

SEGMENTS = 16

# Цвета нужны только чтобы .glb можно было открыть и увидеть предмет: в игре
# материалы всё равно подменяются палитрой сцены.
COLORS = {
    "wood": (0.29, 0.16, 0.09, 1.0),
    "panel": (0.82, 0.76, 0.66, 1.0),
    "brass": (0.48, 0.33, 0.15, 1.0),
    "metal": (0.14, 0.14, 0.13, 1.0),
    "sand": (0.66, 0.61, 0.50, 1.0),
    "dial": (0.82, 0.76, 0.66, 1.0),
    "shade": (0.85, 0.77, 0.62, 1.0),
    "figure": (0.40, 0.33, 0.26, 1.0),
    "accent": (0.44, 0.28, 0.24, 1.0),
    "corner": (0.67, 0.57, 0.47, 1.0),
    "chrome": (0.72, 0.72, 0.70, 1.0),
    "glass": (0.30, 0.38, 0.36, 1.0),
    "tag": (0.44, 0.28, 0.24, 1.0),
}


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_material(name):
    material = bpy.data.materials.new(name=name)
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled:
        principled.inputs["Base Color"].default_value = COLORS.get(name, (0.6, 0.6, 0.6, 1.0))
        principled.inputs["Roughness"].default_value = 0.65
    return material


class Prop:
    """Копилка вершин и граней с материалом на грань."""

    def __init__(self, name):
        self.name = name
        self.verts = []
        self.faces = []

    def box(self, center, size, material, rot_y=0.0):
        cx, cy, cz = center
        hx, hy, hz = size[0] / 2.0, size[1] / 2.0, size[2] / 2.0
        base = len(self.verts)
        cos_a, sin_a = math.cos(rot_y), math.sin(rot_y)
        for bit in range(8):
            lx = hx if bit & 1 else -hx
            ly = hy if bit & 2 else -hy
            lz = hz if bit & 4 else -hz
            # Поворот вокруг оси Y: нужен только стрелке указателя этажа.
            rx = lx * cos_a + lz * sin_a
            rz = -lx * sin_a + lz * cos_a
            self.verts.append((cx + rx, cy + ly, cz + rz))
        for quad in ((0, 2, 6, 4), (1, 5, 7, 3), (0, 4, 5, 1),
                     (2, 3, 7, 6), (0, 1, 3, 2), (4, 6, 7, 5)):
            self.faces.append((tuple(base + i for i in quad), material))

    def plate(self, points, bottom, top, material):
        """Плита по контуру: плоский многоугольник, выдавленный по высоте.

        Нужна узору ковра — ромб боксом не выложишь.
        """
        base = len(self.verts)
        count = len(points)
        for x, y in points:
            self.verts.append((x, y, bottom))
        for x, y in points:
            self.verts.append((x, y, top))
        self.faces.append((tuple(base + i for i in range(count)), material))
        self.faces.append((tuple(base + count + i for i in range(count)), material))
        for i in range(count):
            j = (i + 1) % count
            self.faces.append(((base + i, base + j, base + count + j, base + count + i), material))

    def lathe(self, profile, material, center=(0.0, 0.0), segments=SEGMENTS, axis="z"):
        """Тело вращения. profile — пары (радиус, положение вдоль оси).

        Точка с радиусом 0 замыкает профиль конусом, поэтому донья и верхушки
        получаются сами и телу не нужны отдельные заглушки. axis="y" нужен
        колёсам тележки: они катятся вдоль X, значит их ось смотрит по Y.
        """
        first, second = center
        rings = []
        for radius, along in profile:
            if abs(radius) < 1e-6:
                rings.append(("point", len(self.verts)))
                self.verts.append(self._revolved(axis, first, second, along, 0.0, 0.0))
                continue
            rings.append(("ring", len(self.verts)))
            for step in range(segments):
                angle = 2.0 * math.pi * step / segments
                self.verts.append(self._revolved(axis, first, second, along,
                                                 radius * math.cos(angle),
                                                 radius * math.sin(angle)))
        for index in range(len(rings) - 1):
            a_kind, a_base = rings[index]
            b_kind, b_base = rings[index + 1]
            for step in range(segments):
                nxt = (step + 1) % segments
                if a_kind == "point" and b_kind == "ring":
                    self.faces.append(((a_base, b_base + step, b_base + nxt), material))
                elif a_kind == "ring" and b_kind == "point":
                    self.faces.append(((a_base + step, a_base + nxt, b_base), material))
                elif a_kind == "ring" and b_kind == "ring":
                    self.faces.append(((a_base + step, a_base + nxt,
                                        b_base + nxt, b_base + step), material))

    @staticmethod
    def _revolved(axis, first, second, along, offset_a, offset_b):
        if axis == "z":
            return (first + offset_a, second + offset_b, along)
        if axis == "y":
            return (first + offset_a, along, second + offset_b)
        return (along, first + offset_a, second + offset_b)

    def build(self):
        order = []
        for _, material in self.faces:
            if material not in order:
                order.append(material)
        mesh = bpy.data.meshes.new(self.name)
        bm = bmesh.new()
        verts = [bm.verts.new(v) for v in self.verts]
        bm.verts.ensure_lookup_table()
        for indices, material in self.faces:
            try:
                face = bm.faces.new([verts[i] for i in indices])
            except ValueError:
                continue  # грань-дубликат: у соседних боксов совпали стенки
            face.material_index = order.index(material)
        # Заводить винтом правильную намотку вручную — лишняя работа и лишний
        # источник ошибок: у нас все тела замкнутые, нормали считаются сами.
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bm.to_mesh(mesh)
        bm.free()
        for material in order:
            mesh.materials.append(make_material(material))
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.collection.objects.link(obj)
        return obj


def export(path):
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_normals=True,
        export_tangents=False,
        export_texcoords=False,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
        export_extras=False,
        export_yup=True,
    )



def run(props, out_dir=None):
    """Сгенерировать и выгрузить набор пропсов. out_dir по умолчанию из argv после --."""
    if out_dir is None:
        if "--" not in sys.argv:
            raise SystemExit("нужен путь: ... --python <скрипт> -- assets/models")
        out_dir = sys.argv[sys.argv.index("--") + 1]
    out_dir = os.path.abspath(out_dir)
    os.makedirs(out_dir, exist_ok=True)
    for filename, factory in props.items():
        reset_scene()
        obj = factory().build()
        path = os.path.join(out_dir, filename)
        export(path)
        triangles = sum(len(polygon.vertices) - 2 for polygon in obj.data.polygons)
        print("PROP_OK %-30s %6d bytes  %4d tris  materials=%s"
              % (filename, os.path.getsize(path), triangles,
                 ",".join(m.name for m in obj.data.materials)))