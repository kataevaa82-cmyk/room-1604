# Промпты генерации

Арты созданы встроенным режимом `imagegen` (не CLI и не API fallback), затем
детерминированно обрезаны и масштабированы до размеров Яндекс Игр скриптом
`build_media.py`.

## Key art

```text
Use case: ads-marketing
Asset type: Yandex Games cinematic key art master, landscape
Primary request: Create premium cinematic key art for the Russian first-person psychological horror game “КОМНАТА 1604”, faithfully inspired by the supplied real gameplay screenshots.
Input images: all supplied images are supporting visual references for the actual game's angular low-poly hotel architecture, green upholstery, warm lamps, dark wood, cream walls, night windows, and first-person mood; do not copy any UI or subtitles.
Scene/backdrop: a long, elegant but oppressive hotel corridor on the sixteenth floor at night, leading toward one slightly open dark wooden room door with a small brass plate reading exactly “1604”; a sliver of warm amber light leaks through the door, while the far corridor recedes into cold blue-black darkness.
Subject: the mysterious door 1604 is the unmistakable focal point; no people, no monsters, no gore.
Style/medium: polished stylized 3D game key art, cinematic psychological horror, realistic lighting and materials while retaining the game's angular low-poly identity.
Composition/framing: wide 16:9 master, strong one-point perspective, door placed near the right third, generous but textured dark negative space at upper left for later title placement, important elements centered safely for future 800×470 and 1560×520 crops.
Lighting/mood: warm tungsten versus cold moonlit shadows, subtle fog, ominous, elegant, suspenseful rather than violent.
Color palette: near-black, walnut brown, muted olive green, antique brass, restrained amber.
Constraints: the digits on the brass door plate must read only “1604”; preserve a plausible hotel environment from the references; no added story characters.
Avoid: any logos, title text, slogans, UI, HUD, watermark, extra numbers, people, faces, creatures, blood, gore, weapons, photoreal human imagery, bright saturated neon.
```

## Icon

```text
Use case: ads-marketing
Asset type: Yandex Games square game icon master
Primary request: Create a bold, instantly readable square icon for the psychological horror game “КОМНАТА 1604”, visually matching the supplied corridor key art.
Input images: the supplied key art is a style reference only; carry over its dark walnut, antique brass, warm amber rim light, cold blue-black shadows, elegant hotel atmosphere.
Subject: an extreme close-up of a heavy dark hotel door and a centered antique brass room plate engraved with exactly “1604”; a narrow black gap at the door edge emits an eerie warm glow; one subtle old-fashioned keyhole below the plate.
Style/medium: polished stylized 3D game art with a restrained low-poly character, high contrast, premium store icon.
Composition/framing: square, symmetrical, the brass plate and digits fill the central circular safe zone; large simple shapes; readable at 64 pixels; generous safe margins for a maskable icon.
Lighting/mood: ominous, elegant, mysterious; warm brass and door-edge glow against near-black wood.
Color palette: near-black, walnut, antique brass, amber, tiny hint of cold teal in shadows.
Text (verbatim): “1604” only, as engraved digits on the brass plate.
Constraints: all essential content fits inside the central 70% safe area; the digits must be exactly 1604; no title words.
Avoid: logos, letters, slogans, UI, HUD, watermark, extra numbers, people, faces, hands, monsters, blood, gore, weapons, clutter, bright saturated colors.
```

