# Пропсы коридора шестнадцатого этажа.
#
# Запуск:
#   blender.exe --background --factory-startup --python tools/make_corridor_props.py -- assets/models
#
# --factory-startup обязателен: чужие аддоны в пользовательском профиле лезут в
# glTF-экспорт и добавляют в файл то, чего мы не просили.
#
# Геометрические помощники и договорённости с игрой — в blender_prop_kit.py.
# После генерации обязательно:
#   godot_console.exe --headless --path C:\Комната --import
# иначе preload падает с «no resource loaders».

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from blender_prop_kit import Prop, run

# --------------------------------------------------------------------- пропсы ---

def wainscot():
    """Секция панелей под поручень. Тайл, который ставят в ряд вдоль стены.

    Ширина 0.85 подобрана под шаги плинтуса коридора, высота 0.70 — под низ
    пожарного шкафа (0.74): поручень выше начал бы резать шкаф насквозь.
    """
    prop = Prop("corridor_wainscot")
    width, height, depth = 0.85, 0.70, 0.055
    prop.box((0.0, -depth / 2.0, 0.05), (width, depth, 0.10), "wood")
    prop.box((0.0, -0.033, 0.665), (width, 0.066, 0.07), "wood")
    for side in (-1.0, 1.0):
        prop.box((side * 0.39, -depth / 2.0, 0.375), (0.07, depth, 0.53), "wood")
    # Филёнка утоплена: она тоньше рамы, поэтому в профиль читается впадиной.
    prop.box((0.0, -0.018, 0.375), (0.71, 0.036, 0.53), "panel")
    return prop


def urn():
    """Пепельница-урна с песком. Тело вращения на точёной ножке."""
    prop = Prop("corridor_urn")
    prop.lathe([
        (0.000, 0.000),
        (0.135, 0.000),
        (0.135, 0.035),
        (0.104, 0.058),
        (0.047, 0.100),
        (0.041, 0.340),
        (0.062, 0.402),
        (0.112, 0.500),
        (0.118, 0.575),
        (0.101, 0.600),
        (0.096, 0.585),
    ], "brass")
    # Песок чуть ниже кромки — сверху видно, что урна не пустая.
    prop.lathe([(0.096, 0.578), (0.070, 0.586), (0.000, 0.590)], "sand")
    return prop


def lift_dial():
    """Указатель этажа над дверьми лифта: латунная накладка со стрелкой."""
    prop = Prop("corridor_lift_dial")
    prop.box((0.0, -0.020, 0.130), (0.420, 0.040, 0.260), "brass")
    prop.box((0.0, -0.044, 0.130), (0.340, 0.008, 0.190), "dial")
    # Стрелка стоит на «16»: чуть правее верхней точки шкалы.
    prop.box((0.0, -0.052, 0.190), (0.014, 0.010, 0.120), "metal", rot_y=0.42)
    prop.lathe([(0.000, -0.050), (0.022, -0.050), (0.022, -0.056), (0.000, -0.056)],
               "metal", center=(0.0, 0.0))
    for step in range(5):
        angle = math.pi * (0.18 + 0.16 * step)
        prop.box((0.125 * math.cos(angle), -0.049, 0.130 + 0.072 * math.sin(angle)),
                 (0.016, 0.006, 0.016), "metal")
    return prop


def ceiling_rose():
    """Плоский потолочный плафон. Крепление в начале координат, свет вниз.

    Своего Light3D у плафона нет: девятнадцати источников в gl_compatibility уже
    достаточно, а видимость даёт эмиссия материала.
    """
    prop = Prop("corridor_ceiling_rose")
    prop.lathe([
        (0.000, 0.000),
        (0.170, 0.000),
        (0.170, -0.016),
        (0.144, -0.026),
    ], "brass")
    prop.lathe([
        (0.146, -0.022),
        (0.132, -0.052),
        (0.107, -0.082),
        (0.061, -0.100),
        (0.000, -0.107),
    ], "shade")
    return prop


def cornice():
    """Тайл потолочного карниза. Крепление — стык стены и потолка, свес вниз.

    Кладётся вплотную, поэтому у тайла нет полей: раскладка в build_corridor()
    даёт соседям чуть перекрыться, и шов прячется внутри соседнего тела.
    """
    prop = Prop("corridor_cornice")
    width = 0.85
    prop.box((0.0, -0.0275, -0.015), (width, 0.055, 0.030), "wood")
    prop.box((0.0, -0.0200, -0.048), (width, 0.040, 0.036), "wood")
    # Латунная нить по нижнему краю: единственная светлая линия на стыке.
    prop.box((0.0, -0.0140, -0.077), (width, 0.028, 0.022), "brass")
    return prop


def carpet_tile():
    """Тайл узора ковровой дорожки: ромб в ромбе плюс уголок.

    Дорожка лежит ровно в центре первого кадра игры, и до сих пор была ровным
    тёмным прямоугольником. Узор — самое заметное, что вообще можно добавить.

    Уголок стоит только у одного угла тайла (+x,+y). Соседний тайл ставит свой,
    и на каждом стыке четырёх тайлов оказывается ровно один уголок: положи по
    четырём углам — и на стыках они наложатся вчетверо и замерцают.
    """
    prop = Prop("corridor_carpet_tile")
    prop.plate([(0.200, 0.0), (0.0, 0.200), (-0.200, 0.0), (0.0, -0.200)],
               0.0, 0.004, "figure")
    prop.plate([(0.085, 0.0), (0.0, 0.085), (-0.085, 0.0), (0.0, -0.085)],
               0.004, 0.007, "accent")
    prop.plate([(0.280, 0.225), (0.225, 0.280), (0.170, 0.225), (0.225, 0.170)],
               0.0, 0.005, "corner")
    return prop


def lift_relief():
    """Накладка на створку лифта: латунная рама, тёмные каннелюры, ромб.

    Игрок выходит из лифта — створки видит первыми. Ставится поверх готовых
    хромированных боксов створок, а не вместо них: так исходный лифт цел.
    """
    prop = Prop("corridor_lift_relief")
    prop.box((0.0, -0.011, 1.835), (0.720, 0.022, 0.030), "brass")
    prop.box((0.0, -0.011, 0.015), (0.720, 0.022, 0.030), "brass")
    for side in (-1.0, 1.0):
        prop.box((side * 0.345, -0.011, 0.925), (0.030, 0.022, 1.850), "brass")
    for step in range(7):
        prop.box((-0.240 + 0.080 * step, -0.009, 0.925), (0.022, 0.018, 1.600), "metal")
    # Ромб-медальон: тот же бокс, повёрнутый на 45° в плоскости створки.
    prop.box((0.0, -0.020, 1.150), (0.130, 0.020, 0.130), "brass", rot_y=math.pi / 4.0)
    return prop


def luggage_cart():
    """Латунная багажная тележка с чемоданом. Брошена посреди коридора."""
    prop = Prop("corridor_luggage_cart")
    prop.box((0.0, 0.0, 0.300), (0.950, 0.580, 0.050), "wood")
    prop.box((0.0, 0.0, 0.120), (0.880, 0.520, 0.035), "wood")
    for dx in (-0.44, 0.44):
        for dy in (-0.26, 0.26):
            prop.lathe([(0.0, 0.085), (0.016, 0.085), (0.016, 1.340), (0.0, 1.340)],
                       "brass", center=(dx, dy), segments=10)
    for dy in (-0.26, 0.26):
        prop.box((0.0, dy, 1.340), (0.880, 0.028, 0.028), "brass")
    for dx in (-0.44, 0.44):
        prop.box((dx, 0.0, 1.340), (0.028, 0.520, 0.028), "brass")
    # Колёса катятся вдоль тележки, поэтому ось у них по Y.
    for dx in (-0.40, 0.40):
        for dy in (-0.24, 0.24):
            prop.lathe([(0.0, dy - 0.015), (0.045, dy - 0.015),
                        (0.045, dy + 0.015), (0.0, dy + 0.015)],
                       "metal", center=(dx, 0.045), segments=10, axis="y")
    prop.box((-0.230, 0.0, 0.375), (0.340, 0.300, 0.100), "cream")
    prop.box((0.260, 0.0, 0.395), (0.340, 0.220, 0.140), "wood")
    return prop


def service_tray():
    """Поднос рум-сервиса на полу: клош, бутылка, салфетка.

    Единственная вещь в коридоре, которая говорит, что здесь кто-то был.
    """
    prop = Prop("corridor_service_tray")
    prop.box((0.0, 0.0, 0.012), (0.420, 0.320, 0.024), "brass")
    for dy in (-0.155, 0.155):
        prop.box((0.0, dy, 0.032), (0.420, 0.012, 0.016), "brass")
    for dx in (-0.205, 0.205):
        prop.box((dx, 0.0, 0.032), (0.012, 0.320, 0.016), "brass")
    prop.lathe([(0.115, 0.024), (0.112, 0.055), (0.092, 0.085),
                (0.052, 0.104), (0.0, 0.110)], "chrome", center=(0.045, 0.0))
    prop.lathe([(0.0, 0.024), (0.028, 0.024), (0.028, 0.100), (0.018, 0.130),
                (0.014, 0.200), (0.0, 0.205)], "glass", center=(-0.150, 0.065),
               segments=10)
    prop.box((0.130, -0.100, 0.031), (0.100, 0.070, 0.014), "cream")
    return prop


def door_hanger():
    """Табличка «не беспокоить» на ручке соседнего номера. Висит вниз."""
    prop = Prop("corridor_door_hanger")
    for side in (-1.0, 1.0):
        prop.box((side * 0.018, 0.0, -0.022), (0.006, 0.004, 0.044), "brass")
    prop.box((0.0, 0.0, -0.002), (0.042, 0.004, 0.006), "brass")
    prop.box((0.0, 0.0, -0.115), (0.075, 0.004, 0.140), "tag")
    return prop


PROPS = {
    "corridor_wainscot.glb": wainscot,
    "corridor_cornice.glb": cornice,
    "corridor_urn.glb": urn,
    "corridor_lift_dial.glb": lift_dial,
    "corridor_ceiling_rose.glb": ceiling_rose,
    "corridor_carpet_tile.glb": carpet_tile,
    "corridor_lift_relief.glb": lift_relief,
    "corridor_luggage_cart.glb": luggage_cart,
    "corridor_service_tray.glb": service_tray,
    "corridor_door_hanger.glb": door_hanger,
}



run({
    "corridor_wainscot.glb": wainscot,
    "corridor_cornice.glb": cornice,
    "corridor_urn.glb": urn,
    "corridor_lift_dial.glb": lift_dial,
    "corridor_ceiling_rose.glb": ceiling_rose,
    "corridor_carpet_tile.glb": carpet_tile,
    "corridor_lift_relief.glb": lift_relief,
    "corridor_luggage_cart.glb": luggage_cart,
    "corridor_service_tray.glb": service_tray,
    "corridor_door_hanger.glb": door_hanger,
})