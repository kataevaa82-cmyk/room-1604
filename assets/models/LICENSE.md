# Ready-made models

All GLB files in this directory come from Kenney's Furniture Kit 1.0:

- Source: https://kenney.nl/assets/furniture-kit
- License: Creative Commons Zero (CC0) 1.0
- Author: Kenney (https://kenney.nl/)

The runtime files were renamed to keep their resource paths short:

| Runtime file | Original Kenney file |
| --- | --- |
| `armchair.glb` | `loungeChair.glb` |
| `bedside_table.glb` | `cabinetBedDrawerTable.glb` |
| `books.glb` | `books.glb` |
| `ceiling_lamp.glb` | `lampSquareCeiling.glb` |
| `coffee_machine.glb` | `kitchenCoffeeMachine.glb` |
| `coffee_table.glb` | `tableCoffee.glb` |
| `console_table.glb` | `sideTableDrawers.glb` |
| `desk.glb` | `desk.glb` |
| `desk_chair.glb` | `chairCushion.glb` |
| `entrance_door.glb` | `doorway.glb` |
| `entry_rug.glb` | `rugDoormat.glb` |
| `living_rug.glb` | `rugRectangle.glb` |
| `minibar.glb` | `kitchenFridgeSmall.glb` |
| `mirror.glb` | `bathroomMirror.glb` |
| `plant_small.glb` | `plantSmall2.glb` |
| `potted_plant.glb` | `pottedPlant.glb` |
| `sofa.glb` | `loungeSofa.glb` |
| `television.glb` | `televisionModern.glb` |
| `tv_stand.glb` | `cabinetTelevisionDoors.glb` |
| `wall_lamp.glb` | `lampWall.glb` |
| `wardrobe.glb` | `bookcaseClosedDoors.glb` |

## Picture frame

`fancy_picture_frame.glb` is based on **Fancy Picture Frame 01** by Poly Haven:

- Source: https://polyhaven.com/a/fancy_picture_frame_01
- License: Creative Commons Zero (CC0) 1.0
- Author: Poly Haven (https://polyhaven.com/)

## Original lightweight models

`interior_open_door.glb`, `interior_open_door_right.glb`, `radiator.glb`, `vintage_phone.glb`,
`writing_set.glb`, `coffee_service.glb`, `hotel_amenities.glb`,
`wall_switch.glb`, `wall_outlet.glb`, `curtain_rod.glb`, `crown_molding.glb`,
`window_sill.glb`, `suite_crown_molding.glb`, `grand_wall_clock.glb`, `bathroom_sconce.glb`, `bed.glb`, `table_lamp.glb`, `bathroom_vanity.glb`, `bathroom_mirror.glb`,
`bathroom_bathtub.glb`, `bathroom_toilet.glb`, `bath_shower_fixture.glb`,
`bath_towel_rack.glb`, `bath_hand_towel.glb`, `bath_wastebasket.glb`,
`bath_toilet_paper.glb`, and `bath_tissue_box.glb` were created specifically for
this project in Blender and contain no third-party assets.

### Corridor trim (reproducible)

`corridor_wainscot.glb`, `corridor_cornice.glb`, `corridor_urn.glb`,
`corridor_lift_dial.glb`, `corridor_ceiling_rose.glb`, `corridor_carpet_tile.glb`,
`corridor_lift_relief.glb`, `corridor_luggage_cart.glb`,
`corridor_service_tray.glb`, and `corridor_door_hanger.glb` are also original, and
unlike everything above they can be regenerated — the Blender script that builds
them is kept in the repository:

```
blender.exe --background --factory-startup --python tools/make_corridor_props.py -- assets/models
```

The models above were made the same way, but their scripts were not saved, so
they can no longer be reproduced. Keep new generators in `tools/`.
