# Harvest Son

A farming life-sim prototype in Godot 4: a 3D field seen through a fixed diagonal camera,
with the characters and field objects as pixel sprites. The rules follow our
design doc: [docs/DESIGN.md](docs/DESIGN.md) (Thai; a copy of the online doc
https://claude.ai/artifact/32gupMu1YQVJULs9n6nPEk).
All code, art, names and numbers are our own. Nothing is taken from any other game's files.

## Run
Open the folder in Godot 4.7 (`Godot_v4.7.2-stable_win64.exe`, kept next to the project but
not in git) and press F5. From a shell:

    Godot_v4.7.2-stable_win64_console.exe --path .

The flat top-down view is still there as `scenes/main_2d.tscn` (F6 on that scene).
Add `-- --demo` to start at 10:00 with a few planted plots (for screenshots).

Tests (farm rules, headless):

    Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_farm.gd

## Controls
| Key | Action |
| --- | --- |
| WASD / arrows | walk along the field's axes (Up = diagonally away from the camera); Shift = run |
| Space / J | use the tool on the cell in front |
| E / K | interact: harvest, ship at the bin, buy seeds at the stand, sleep at the door |
| 1-6 / Tab | pick a tool: hoe, watering can, sickle, hammer, axe, seeds |
| Q | next seed type (for sowing and for buying) |

## What works (v0)
- Clock: 1 game minute = 0.5 s, day starts 6:00, 4 seasons x 30 days, day/night tint.
- Weather rolled a day ahead per season (`data/weather.json`); rain waters the field, storms
  can destroy crops.
- Farm grid 32 x 20: till, water (can refills at the pond), seed bag sows 3 x 3, crops grow
  one stage per watered night (`data/crops.json`), regrowing crops, out-of-season crops wither,
  weeds appear, rocks / branches / weeds / stumps cleared by the right tool.
- Shipping bin pays at 18:00 (or when you sleep); the seed stand sells this season's seeds.
- Stamina: each swing costs stamina; sleep before midnight restores it all, after midnight
  3/4, passing out at 2:00 half.

## Camera
`scripts/main_3d.gd` uses the field camera geometry of Harvest Moon: Back to Nature, measured
in the reverse-engineering project: yaw 45°, pitch 26.6°, the player 25.2 cells from the eye,
vertical FOV 13.7° (a long, narrow lens, so the view looks nearly isometric). The camera
follows the player with no lag and stops a few cells inside the fence.

## Layout
- `scripts/autoload/game.gd`: global state (clock, calendar, weather, money, bag, stamina, light).
- `scripts/farm/farm_grid.gd`: farm rules, pure logic (no drawing).
- `scripts/farm_actions.gd`: player actions -> farm rules, shared by both views.
- `scripts/main_3d.gd` + `scripts/world3d/farm_world.gd`: the 3D view (ground texture, sprites,
  building boxes, camera). `scripts/main_2d.gd` + `scripts/farm/farm_view.gd`: the 2D view;
  FarmView also draws the 3D ground texture.
- `scripts/player/player.gd`: movement and collision (the 3D view hides it and follows it).
- `scripts/art/placeholder_art.gd`: pixel sprites made in code until there is real art.
- `data/*.json`: crops and weather, tuned without touching code.

## Next
Sprite art (16 x 16 tiles, 16 x 32 characters), charging tools, fatigue, save / load, a town
map with villagers and schedules, events and dialogue (Dialogic 2), animals, shops.
