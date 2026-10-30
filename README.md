# Harvest Son

A farming life-sim prototype in Godot 4 (2D, top-down, pixel style). The rules follow our
design doc: [docs/DESIGN.md](docs/DESIGN.md) (Thai; a copy of the online doc
https://claude.ai/artifact/32gupMu1YQVJULs9n6nPEk).
All code, art, names and numbers are our own. Nothing is taken from any other game's files.

## Run
Open the folder in Godot 4.7 (`Godot_v4.7.2-stable_win64.exe`, kept next to the project but
not in git) and press F5. From a shell:

    Godot_v4.7.2-stable_win64_console.exe --path .

Tests (farm rules, headless):

    Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_farm.gd

## Controls
| Key | Action |
| --- | --- |
| WASD / arrows | walk (Shift = run) |
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

## Layout
- `scripts/autoload/game.gd`: global state (clock, calendar, weather, money, bag, stamina).
- `scripts/farm/farm_grid.gd`: farm rules, pure logic (no drawing).
- `scripts/farm/farm_view.gd`, `scripts/player/player.gd`, `scripts/ui/hud.gd`: placeholder
  drawing, to be replaced by sprites / TileMapLayer.
- `scripts/main.gd`: builds the scene and maps player actions to farm rules.
- `data/*.json`: crops and weather, tuned without touching code.

## Next
Sprite art (16 x 16 tiles, 16 x 32 characters), charging tools, fatigue, save / load, a town
map with villagers and schedules, events and dialogue (Dialogic 2), animals, shops.
