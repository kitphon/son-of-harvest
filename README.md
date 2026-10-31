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

The game opens on the title screen (`scenes/title.tscn`): New game, Continue (greyed out when
`user://save1.json` is missing or can't be loaded) or Quit, with the arrows / W S and
Enter / Space or the mouse. The field itself is `scenes/main.tscn`.
The flat top-down view is still there as `scenes/main_2d.tscn` (F6 on that scene).
Add `-- --demo` to skip the title and start at 10:00 with a few planted plots (for screenshots), and
`--weather=<sunny|rain|storm|snow|blizzard>` after it to force today's weather.

Tests (farm rules, headless):

    Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_farm.gd

Save / load, the title menu, weather and dialogue: the same with `res://tests/test_save.gd`,
`res://tests/test_title.gd`, `res://tests/test_weather.gd` and `res://tests/test_dialogue.gd`.

## Controls
| Key | Action |
| --- | --- |
| WASD / arrows | walk along the field's axes (Up = diagonally away from the camera); Shift = run |
| Space / J | use the tool on the cell in front; hold to charge (pips over the farmer), let go for a bigger area; tools level up with use (pips in the item box) |
| E / K | interact: harvest, ship at the bin (with nothing to ship: read the note on it), buy seeds at the stand, sleep at the door |
| E / Space / Enter, click | in a text box: show the whole line, then go on; arrows / W / S or the mouse pick a choice |
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
- Sound: every effect and ambient loop is made in code from recipes in `data/sfx.json`
  (`scripts/audio/sfx_synth.gd`, no sound files). Tools, footsteps by ground, bin lid,
  payday coins, menu, a chime at 6:00; rain, storm wind and thunder after lightning,
  cicadas on summer days, crickets at night, cross-faded by weather / season / hour.
- Fatigue (hidden, data/body.json): rises with work in the rain or late at night, with staying
  up past 22:00 and with working on an empty stamina bar; only sleep lowers it, more the
  earlier you go to bed. Tired: the farmer slumps and sweats; exhausted: slower and can't run.
  Going to bed tired or after midnight means oversleeping; full fatigue is a collapse (wake at
  12:00 next day, a doctor's fee).

## Export (Windows .exe)
The preset "Windows Desktop" in `export_presets.cfg` builds `build/HarvestSon.exe` (git-ignored)
with the game data embedded in the exe, our icon (`icon.ico`), version 0.1.0 and
"Harvest Son Team" as the company. Tests and tools are left out of the build.

Godot needs its export templates for exactly 4.7.2 once per machine:
1. In the editor: Editor → Manage Export Templates → Download and Install (official mirror),
   or download `Godot_v4.7.2-stable_export_templates.tpz` from godotengine.org and choose
   "Install from File".
2. Check that `%APPDATA%\Godot\export_templates.7.2.stable\windows_release_x86_64.exe` exists.
3. Build from a shell in the project folder:

       Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" build/HarvestSon.exe

   (or Project → Export → Windows Desktop → Export Project in the editor).
4. Try it: `build\HarvestSon.exe` (or `build\HarvestSon.exe --quit-after 300` for a quick start check).

The icon is drawn in code by `tools/make_icon.gd` (a sprout over field rows, 16 x 16 pixels
scaled up); it writes `icon.png` (project icon) and `icon.ico` (16 to 256 px, for the exe):

    Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/make_icon.gd

## Dialogue
Dialogue lives in `data/dialogue/<id>.json`, opened with `Game.talk(id)` (or `-- --dialogue=<id>`
/ `<id>@<line id>`). A file is `{"lines": [...]}`; each line is one of:
- a text line: `text` (our pixel font only, at most 4 rows in the box), optional `speaker`
  (a key of `data/dialogue/speakers.json`: name tag and portrait colours; no speaker =
  narration), `face` (calm, smile, surprised, worried), `id` (to jump to), `next` (a line id
  or `"end"`; without it the following line, and after the last line the dialogue ends),
  `set` (flags to set when the line shows) and `choices`: 1-4 of `{text, next, set}` (a line
  with choices has no `next`);
- a branch: `{"if": "<flag>", "then": "<line id>"}` jumps when the flag is set (true, a
  number other than 0, a word other than ""), else goes on to the following line.

Flags are `Game.flags` (true / false, whole numbers or words), saved with the game. Typing
speed and punctuation pauses are in `data/text_box.json`. `DialogueRunner` refuses a file
with anything wrong (unknown keys or speakers, jumps to nowhere, letters the font lacks, text
too long) and says why; `tests/test_dialogue.gd` loads every file in the folder. Event
scripts (milestone 6) will build on this format.

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
- `scripts/world3d/farmer_anim.gd`: picks the farmer's frame (pose, facing, mirror, timing).
- `scripts/dialogue/dialogue_runner.gd` + `scripts/ui/text_box.gd`: dialogue stepping (pure
  logic) and the text box that draws it.
- `data/*.json`: crops and weather, tuned without touching code; `data/dialogue/`: dialogue.
- `scripts/autoload/sfx.gd` (Sfx): plays sounds by key, SFX / Ambient busses with
  `set_volume(bus, 0..1)`; `scripts/audio/ambient_picker.gd` picks the ambient loops.
- `tools/make_icon.gd`: draws the app icon; `export_presets.cfg`: the Windows build.

## Plan and handoff
- ROADMAP.md: milestones and "Next up".
- WORKLOG.md: what was done, how it was checked, what is left.
- AGENTS.md (and CLAUDE.md): rules and how-to for the next agent, including the clean-room rule.
