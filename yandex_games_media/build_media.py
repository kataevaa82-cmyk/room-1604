"""Build submission-ready Yandex Games media for Room 1604.

The script only performs deterministic finishing: exact crops, resizing, a
subtle common grade, and a narrow frame. Generated key art stays separate from
real gameplay screenshots so the latter remain an honest representation of
the game.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parent
ART_GENERATED = ROOT / "art" / "generated"
ART_FINAL = ROOT / "art" / "final"
DESKTOP_RAW = ROOT / "screenshots" / "desktop" / "raw"
DESKTOP_FINAL = ROOT / "screenshots" / "desktop" / "final"
MOBILE_RAW = ROOT / "screenshots" / "mobile_landscape" / "raw"
MOBILE_FINAL = ROOT / "screenshots" / "mobile_landscape" / "final"
PREVIEW = ROOT / "preview"

GOLD = (201, 157, 82)
PALE_GOLD = (239, 207, 150)
INK = (7, 7, 8)
SERIF_BOLD = Path(r"C:\Windows\Fonts\georgiab.ttf")
SANS = Path(r"C:\Windows\Fonts\segoeui.ttf")


def ensure_dirs() -> None:
    for directory in (ART_FINAL, DESKTOP_FINAL, MOBILE_FINAL, PREVIEW):
        directory.mkdir(parents=True, exist_ok=True)


def crop_focus(image: Image.Image, size: tuple[int, int], focus=(0.5, 0.5)) -> Image.Image:
    """Aspect-fill an image, biasing the crop toward a normalized focus point."""
    image = image.convert("RGB")
    target_w, target_h = size
    source_ratio = image.width / image.height
    target_ratio = target_w / target_h
    if source_ratio > target_ratio:
        crop_h = image.height
        crop_w = round(crop_h * target_ratio)
    else:
        crop_w = image.width
        crop_h = round(crop_w / target_ratio)
    center_x = focus[0] * image.width
    center_y = focus[1] * image.height
    left = round(center_x - crop_w / 2)
    top = round(center_y - crop_h / 2)
    left = max(0, min(left, image.width - crop_w))
    top = max(0, min(top, image.height - crop_h))
    cropped = image.crop((left, top, left + crop_w, top + crop_h))
    return cropped.resize(size, Image.Resampling.LANCZOS)


def add_left_title(image: Image.Image, large: bool = False) -> Image.Image:
    """Add the exact in-game title over a controlled dark falloff."""
    out = image.convert("RGBA")
    width, height = out.size
    falloff = Image.new("RGBA", out.size, (0, 0, 0, 0))
    pixels = falloff.load()
    fade_end = int(width * (0.58 if large else 0.68))
    for x in range(fade_end):
        t = x / max(fade_end - 1, 1)
        alpha = round(176 * (1.0 - t) ** 1.8)
        for y in range(height):
            pixels[x, y] = (2, 3, 5, alpha)
    out = Image.alpha_composite(out, falloff)
    draw = ImageDraw.Draw(out)

    if large:
        x, y = int(width * 0.07), int(height * 0.18)
        small_size, number_size = round(height * 0.115), round(height * 0.24)
        rule_width = round(width * 0.26)
    else:
        x, y = int(width * 0.07), int(height * 0.19)
        small_size, number_size = round(height * 0.078), round(height * 0.17)
        rule_width = round(width * 0.30)

    small = ImageFont.truetype(str(SERIF_BOLD), small_size)
    number = ImageFont.truetype(str(SERIF_BOLD), number_size)
    shadow = (0, 0, 0, 220)
    draw.text((x + 2, y + 3), "КОМНАТА", font=small, fill=shadow)
    draw.text((x, y), "КОМНАТА", font=small, fill=PALE_GOLD)
    line_y = y + small_size + round(height * 0.025)
    draw.line((x, line_y, x + rule_width, line_y), fill=GOLD + (220,), width=max(1, height // 240))
    number_y = line_y + round(height * 0.02)
    draw.text((x + 3, number_y + 4), "1604", font=number, fill=shadow)
    draw.text((x, number_y), "1604", font=number, fill=(246, 220, 169, 255))
    return out.convert("RGB")


def build_art() -> list[Path]:
    key_art = Image.open(ART_GENERATED / "key-art-master.png")
    icon_master = Image.open(ART_GENERATED / "icon-master.png").convert("RGB")
    outputs: list[Path] = []

    hero = crop_focus(key_art, (1920, 1080), focus=(0.56, 0.50))
    hero_path = ART_FINAL / "key-art-1920x1080.png"
    hero.save(hero_path, format="PNG", optimize=True)
    outputs.append(hero_path)

    cover = add_left_title(crop_focus(key_art, (800, 470), focus=(0.55, 0.50)))
    cover_path = ART_FINAL / "cover-800x470.png"
    cover.save(cover_path, format="PNG", optimize=True)
    outputs.append(cover_path)

    showcase = add_left_title(crop_focus(key_art, (1560, 520), focus=(0.55, 0.49)), large=True)
    showcase_path = ART_FINAL / "showcase-cover-1560x520.jpg"
    showcase.save(showcase_path, format="JPEG", quality=95, subsampling=0, optimize=True)
    outputs.append(showcase_path)

    icon = crop_focus(icon_master, (512, 512), focus=(0.50, 0.48))
    icon = ImageEnhance.Contrast(icon).enhance(1.05)
    icon_path = ART_FINAL / "icon-512.png"
    icon.save(icon_path, format="PNG", optimize=True)
    outputs.append(icon_path)

    # Scale all essential detail into the central maskable safe zone. A blurred
    # full-bleed version avoids transparent or flat corners under any mask.
    mask_background = crop_focus(icon_master, (512, 512), focus=(0.50, 0.48))
    mask_background = mask_background.filter(ImageFilter.GaussianBlur(18))
    mask_background = ImageEnhance.Brightness(mask_background).enhance(0.32)
    safe = crop_focus(icon_master, (380, 380), focus=(0.50, 0.48))
    mask_background.paste(safe, ((512 - 380) // 2, (512 - 380) // 2))
    maskable_path = ART_FINAL / "icon-maskable-512.png"
    mask_background.save(maskable_path, format="PNG", optimize=True)
    outputs.append(maskable_path)
    return outputs


def subtle_vignette(image: Image.Image) -> Image.Image:
    small = (max(64, image.width // 8), max(36, image.height // 8))
    core = Image.new("L", small, 0)
    draw = ImageDraw.Draw(core)
    margin_x, margin_y = small[0] // 9, small[1] // 8
    draw.ellipse((margin_x, margin_y, small[0] - margin_x, small[1] - margin_y), fill=255)
    core = core.filter(ImageFilter.GaussianBlur(max(small) // 7))
    edge = ImageOps.invert(core).resize(image.size, Image.Resampling.BICUBIC)
    edge = edge.point(lambda value: round(value * 0.38))
    shade = Image.new("RGB", image.size, INK)
    return Image.composite(shade, image, edge)


def finish_screenshot(source: Path, destination: Path) -> None:
    shot = Image.open(source).convert("RGB")
    shot = crop_focus(shot, (1872, 1053))
    shot = ImageEnhance.Contrast(shot).enhance(1.055)
    shot = ImageEnhance.Color(shot).enhance(0.94)
    shot = ImageEnhance.Sharpness(shot).enhance(1.08)
    shot = subtle_vignette(shot)

    canvas = Image.new("RGB", (1920, 1080), INK)
    x, y = 24, 13
    canvas.paste(shot, (x, y))
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((20, 9, 1899, 1070), outline=(74, 53, 30), width=1)
    draw.rectangle((22, 11, 1897, 1068), outline=GOLD, width=2)
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination, format="PNG", optimize=True)


def build_screenshots() -> tuple[list[Path], list[Path]]:
    desktop_sources = [
        (DESKTOP_RAW / "02_prologue_corridor.png", "01-hotel-corridor.png"),
        (DESKTOP_RAW / "03_prologue_door_open.png", "02-door-1604.png"),
        (DESKTOP_RAW / "08_act3_broken.png", "03-hidden-message.png"),
        (DESKTOP_RAW / "circle2" / "03_c2_suitcase.png", "04-search-the-room.png"),
        (DESKTOP_RAW / "circle2" / "06_c2_letter.png", "05-five-letters.png"),
        (DESKTOP_RAW / "circle2" / "05_c2_calm.png", "06-the-wind-stops.png"),
    ]
    mobile_sources = [
        (MOBILE_RAW / "touch_corridor" / "08_play.png", "01-touch-hotel-corridor.png"),
        (MOBILE_RAW / "touch_livingcorner" / "08_play.png", "02-touch-room-1604.png"),
    ]

    desktop_outputs: list[Path] = []
    mobile_outputs: list[Path] = []
    for source, name in desktop_sources:
        destination = DESKTOP_FINAL / name
        finish_screenshot(source, destination)
        desktop_outputs.append(destination)
    for source, name in mobile_sources:
        destination = MOBILE_FINAL / name
        finish_screenshot(source, destination)
        mobile_outputs.append(destination)
    return desktop_outputs, mobile_outputs


def contact_sheet(images: list[Path], destination: Path, columns: int, title: str) -> None:
    thumb_w, thumb_h = 480, 270
    gap, title_h = 16, 62
    rows = (len(images) + columns - 1) // columns
    sheet_w = columns * thumb_w + (columns + 1) * gap
    sheet_h = title_h + rows * thumb_h + (rows + 1) * gap
    sheet = Image.new("RGB", (sheet_w, sheet_h), (10, 9, 9))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype(str(SANS), 28)
    draw.text((gap, 15), title, font=font, fill=PALE_GOLD)
    for index, path in enumerate(images):
        row, column = divmod(index, columns)
        x = gap + column * (thumb_w + gap)
        y = title_h + gap + row * (thumb_h + gap)
        thumb = crop_focus(Image.open(path), (thumb_w, thumb_h))
        sheet.paste(thumb, (x, y))
    sheet.save(destination, format="JPEG", quality=91, optimize=True)


def build_previews(art: list[Path], desktop: list[Path], mobile: list[Path]) -> None:
    contact_sheet(desktop, PREVIEW / "desktop-screenshots.jpg", 3, "Desktop screenshots — final")
    contact_sheet(mobile, PREVIEW / "mobile-screenshots.jpg", 2, "Mobile landscape screenshots — final")

    cover = Image.open(ART_FINAL / "cover-800x470.png").convert("RGB")
    showcase = Image.open(ART_FINAL / "showcase-cover-1560x520.jpg").convert("RGB")
    icon = Image.open(ART_FINAL / "icon-512.png").convert("RGB")
    maskable = Image.open(ART_FINAL / "icon-maskable-512.png").convert("RGB")
    canvas = Image.new("RGB", (1400, 920), (10, 9, 9))
    canvas.paste(crop_focus(showcase, (1320, 440)), (40, 72))
    canvas.paste(crop_focus(cover, (680, 400)), (40, 548))
    canvas.paste(icon.resize((320, 320), Image.Resampling.LANCZOS), (760, 588))
    canvas.paste(maskable.resize((320, 320), Image.Resampling.LANCZOS), (1040, 588))
    draw = ImageDraw.Draw(canvas)
    title_font = ImageFont.truetype(str(SANS), 30)
    label_font = ImageFont.truetype(str(SANS), 20)
    draw.text((40, 22), "Yandex Games art kit — Комната 1604", font=title_font, fill=PALE_GOLD)
    draw.text((40, 520), "Cover 800×470", font=label_font, fill=(190, 182, 166))
    draw.text((760, 558), "Icon", font=label_font, fill=(190, 182, 166))
    draw.text((1040, 558), "Maskable icon", font=label_font, fill=(190, 182, 166))
    canvas.save(PREVIEW / "art-kit-overview.jpg", format="JPEG", quality=92, optimize=True)


def validate(paths: list[Path]) -> None:
    expected = {
        "icon-512.png": ((512, 512), "PNG"),
        "icon-maskable-512.png": ((512, 512), "PNG"),
        "cover-800x470.png": ((800, 470), "PNG"),
        "showcase-cover-1560x520.jpg": ((1560, 520), "JPEG"),
    }
    for path in paths:
        with Image.open(path) as image:
            if path.name in expected:
                wanted_size, wanted_format = expected[path.name]
                assert image.size == wanted_size, (path, image.size, wanted_size)
                assert image.format == wanted_format, (path, image.format, wanted_format)
            if "screenshots" in path.parts and "final" in path.parts:
                assert image.size == (1920, 1080), (path, image.size)
                assert image.mode == "RGB", (path, image.mode)
                assert image.format == "PNG", (path, image.format)
            print(f"OK  {path.relative_to(ROOT)}  {image.size[0]}x{image.size[1]}  {image.mode}  {image.format}")


def main() -> None:
    ensure_dirs()
    art = build_art()
    desktop, mobile = build_screenshots()
    build_previews(art, desktop, mobile)
    validate(art + desktop + mobile)


if __name__ == "__main__":
    main()

