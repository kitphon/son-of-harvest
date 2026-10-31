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

Save / load, the title menu, weather, dialogue and events: the same with `res://tests/test_save.gd`,
`res://tests/test_title.gd`, `res://tests/test_weather.gd`, `res://tests/test_dialogue.gd` and
`res://tests/test_events.gd`.

## Controls
| Key | Action |
| --- | --- |
| WASD / arrows | walk along the field's axes (Up = diagonally away from the camera); Shift = run |
| Space / J | use the tool on the cell in front; hold to charge (pips over the farmer), let go for a bigger area; tools level up with use (pips in the item box). With an item overhead on the farm: set it down on the cell in front |
| E / K | interact: harvest (the crop goes up overhead, into the hand slot), pick up an item lying in front, ship the rucksack's crops at the bin (with nothing to ship: read the note on it), buy seeds at the stand, open the storage chest right of the house, go through doors (walking into one works too), sleep at the futon in the house. With an item overhead on the farm: throw it up to 2 cells ahead; into the bin it's shipped, into the pond it's gone |
| E / Space / Enter, click | in a text box: show the whole line, then go on; arrows / W / S or the mouse pick a choice |
| 1-8 / Tab | pick a tool slot (at the start: hoe, watering can, sickle, hammer, axe, seeds, food, fishing rod; Space / J eats or drinks the food in hand) |
| Space / J with the rod | cast at water up to 2 cells ahead (the farm pond, the village pond); wait for the "!" and a plip, then Space / J / E in time to land the fish (it goes up overhead: throw it in the bin to ship it, or put it in the rucksack). Pressing before a bite reels in empty. Fish per place / season / hour / weather: `data/fish.json` |
| I | rucksack: arrows / WASD move, Enter / Space pick up and put down (stack, swap), E takes it in hand (tool slot = tool in hand, an item = the item hand), Esc / I close; mouse: left click pick / put, right click hold. The chest screen works the same. The clock stops while it is open |
| Q | next seed type, or next food with the food slot (for eating and for buying) |

## What works (v0)
- Clock: 1 game minute = 0.5 s, day starts 6:00, 4 seasons x 30 days, day/night tint.
- Weather rolled a day ahead per season (`data/weather.json`); rain waters the field, storms
  can destroy crops.
- Farm grid 32 x 20: till, water (can refills at the pond), seed bag sows 3 x 3, crops grow
  one stage per watered night (`data/crops.json`), regrowing crops, out-of-season crops wither,
  weeds appear, rocks / branches / weeds / stumps cleared by the right tool.
- Shipping bin pays at 18:00 (or when you sleep); the seed stand sells this season's seeds,
  and food / drink when the food slot is in hand (`data/foods.json`: stamina +, fatigue −).
- Stamina: each swing costs stamina; sleep before midnight restores it all, after midnight
  3/4, passing out at 2:00 half.
- Sound: every effect and ambient loop is made in code from recipes in `data/sfx.json`
  (`scripts/audio/sfx_synth.gd`, no sound files). Tools, footsteps by ground, bin lid,
  payday coins, menu, a chime at 6:00; rain, storm wind and thunder after lightning,
  cicadas on summer days, crickets at night, cross-faded by weather / season / hour.
- Music: our own short loops written as notes in `data/music.json` (five-note scales, koto /
  shakuhachi / sho-like voices made by `scripts/audio/music_synth.gd`): a title theme, one
  per season, night and rain, cross-faded by scene / weather / hour. Esc → Settings has
  Music / Sounds / Ambient volume sliders.
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

## Maps
Maps live in `data/maps/<id>.json`: the farm (`farm`, its ground and buildings stay
FarmGrid's, so the file only adds doors and spawns), the farmhouse inside (`house`) and the
village (`town`). A file has `id`, `size` [w, h], `indoor` (the clock stands still inside, as
DESIGN asks for every building), `ambient` (which `places` of the ambient rules in
`data/sfx.json` apply), optional `light` (a fixed room light instead of day / night) and
`background`, then:
- `legend` + `ground`: one row of characters per map row; each character is
  `{tile, solid?, step?}` (tile = a `ground:<kind>` placeholder, step = footstep sound kind);
- `props`: `{kind, cell, size?, solid? (default true), blocks? (only these cell offsets
  block), use?}`; `use: "sleep"` is the futon. Their 3D looks are in `scripts/world3d/map_world.gd`;
- `doors`: `{cells, to, spawn, facing}`, or `{cells, message}` for a door that only says
  something (village houses, no villagers yet). Door cells are solid; walking into one, or
  using it, goes through. Cells just off the edge make a walk-off exit; on the farm
  `gate: true` leaves those fence cells open in the drawing;
- `spawns`: named `[cell, facing]`, `start` needed (`--map=<id>@<spawn>`), the house has
  `home` (where a new day starts).

`Game.maps` (MapManager) holds the map, the farmer's position and facing (saved);
`Game.go_to_map()` changes it and emits `map_changed` (the views fade, rebuild, place the
farmer), and once the picture is back `map_entered(map_id)`, the hook for event triggers.

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
too long) and says why; `tests/test_dialogue.gd` loads every file in the folder.

## Events
An event is a small script in `data/events/<id>.json`: `{"steps": [...]}`, played by
`Game.play_event(id)` (or `-- --event=<id>`), a trigger table, or nothing else. While it plays
`Game.event_running` holds the clock (it counts as `Game.paused()`), the farmer moves only as
the script says, and keys go only to the text box. Each step is one of:
- `{"do": "say", "dialogue": "<id>", "at": "<line id>"}`: opens a dialogue from
  `data/dialogue` and waits until the box closes (`at` is optional; a dialogue line with
  `"next": "end"` stops it, so one file can hold several parts of an event);
- `{"do": "wait", "seconds": 0.5}` (0 to 60);
- `{"do": "face", "dir": "up|down|left|right"}`;
- `{"do": "walk", "to": [x, y]}` or `"by": [dx, dy]` (cells; the farmer walks across first,
  then up or down, to the middle of the cell, at walking speed or with `"run": true`; scripted
  walks don't collide, so keep them on open ground);
- `{"do": "set", "flags": {"name": value}}` / `{"do": "clear", "flags": ["name"]}` (Game.flags,
  the same flags as dialogue);
- `{"do": "give", "item": "<crop or seeds:crop>", "count": 1}`, `{"do": "money", "amount": n}`
  (negative pays; money never goes below 0);
- `{"do": "fade", "to": "black|clear", "seconds": 0.5}` (the screen is always clear again when
  the event ends);
- `{"do": "sound", "key": "<key in data/sfx.json>"}`;
- a branch: `{"if": "<flag>", "then": "<step id>"}` or `{"unless": ...}`.

Any step can have an `id` and a `next` (a step id or `"end"`). `EventRunner` refuses a file with
anything wrong and says why.

**Trigger tables**: `data/events/triggers_<map id>.json` holds `{"rows": [...]}`. The view's
`EventPlayer` asks the table of the map the farmer is on when something happens (`on`):
`enter` (the farmer arrives on the map, also at the start of a game), `day_start` (a new day,
or a loaded game), `minute` (each clock minute) and `step` (the farmer steps onto another
cell). The first row in table order whose conditions all hold plays its `event`; a row plays
once (`Game.events_seen`, saved) unless it says `"once": false`. Conditions, each optional:
`year` / `days` `[first, last]`, `season` / `weekday` (`mon` .. `sun`; spring 1 of year 1 is a
Monday) / `weather` (today's: sunny, rain, storm, snow) lists, `time` `["6:00", "9:00"]` (from,
until; the end is not included), `flags` / `not_flags` (set or not set), `seen` / `not_seen`
(event ids) and `area` `[x, y, width, height]` in cells (where the farmer stands). Under
`-- --demo` the tables are off. Map switching calls `EventPlayer.enter_map(id)` with the new
map's id.

## Camera
`scripts/main_3d.gd` uses the field camera geometry of Harvest Moon: Back to Nature, measured
in the reverse-engineering project: yaw 45°, pitch 26.6°, the player 25.2 cells from the eye,
vertical FOV 13.7° (a long, narrow lens, so the view looks nearly isometric). The camera
follows the player with no lag and stops a few cells inside the fence (or the map edge;
a room smaller than that stays centred). Inside, the same camera looks in from the front
corner, so the front walls are drawn as low sills (a cutaway) instead of moving the camera.

## Layout
- `scripts/autoload/game.gd`: global state (clock, calendar, weather, money, bag, stamina, light).
- `scripts/farm/farm_grid.gd`: farm rules, pure logic (no drawing).
- `scripts/farm_actions.gd`: player actions -> farm rules, shared by both views.
- `scripts/main_3d.gd` + `scripts/world3d/farm_world.gd`: the 3D view (ground texture, sprites,
  building boxes, camera). `scripts/main_2d.gd` + `scripts/farm/farm_view.gd`: the 2D view;
  FarmView also draws the 3D ground texture.
- `scripts/world/map_data.gd` + `map_manager.gd`: maps from `data/maps` (cells, props, doors)
  and where the farmer is; `scripts/world/map_view.gd` / `scripts/world3d/map_world.gd` draw
  maps other than the farm; `scripts/ui/map_fade.gd`: the fade between maps.
- `scripts/player/player.gd`: movement and collision (the 3D view hides it and follows it).
- `scripts/art/placeholder_art.gd`: pixel sprites made in code until there is real art.
- `scripts/world3d/farmer_anim.gd`: picks the farmer's frame (pose, facing, mirror, timing).
- `scripts/dialogue/dialogue_runner.gd` + `scripts/ui/text_box.gd`: dialogue stepping (pure
  logic) and the text box that draws it.
- `scripts/events/event_runner.gd`, `event_triggers.gd` (pure logic) and `event_player.gd`
  (the view's side: triggers, moving the farmer, the fade): event scripts.
- `data/*.json`: crops and weather, tuned without touching code; `data/dialogue/`: dialogue;
  `data/events/`: events and trigger tables.
- `scripts/autoload/sfx.gd` (Sfx): plays sounds by key and the music, SFX / Ambient / Music
  busses with `set_volume(bus, 0..1)` (set from the volume settings);
  `scripts/audio/ambient_picker.gd` picks the ambient loops, `music_picker.gd` the track.
- `tools/make_icon.gd`: draws the app icon; `export_presets.cfg`: the Windows build.

## Plan and handoff
- ROADMAP.md: milestones and "Next up".
- WORKLOG.md: what was done, how it was checked, what is left.
- AGENTS.md (and CLAUDE.md): rules and how-to for the next agent, including the clean-room rule.
