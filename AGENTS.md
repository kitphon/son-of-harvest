# Harvest Son — agent guide

Harvest Son is our own farming life-sim in Godot 4.7: a 3D field seen through a fixed diagonal
camera, with pixel sprites for the characters and field objects. Mechanics are inspired by
Harvest Moon: Back to Nature. Its rules were studied in a separate reverse-engineering project,
but everything in this repository is our own work.
This file is for any coding agent. Claude Code also reads CLAUDE.md, which imports this one.

## Rules (no exceptions)
1. **Clean room.** Never copy code, decompiled functions, data tables, text, names, graphics,
   music or sound from Harvest Moon (or any other game) into this repository. Mechanics and
   ideas may come from docs/DESIGN.md. Code is written fresh, and art, names, story and balance
   numbers are made up for this game. The RE project lives in `D:\REA-Harvest_moon_ps1`. Read
   its NOTES.md for how a system works, then write our own version. Measured facts like the
   camera angles are allowed; say where they came from in a comment.
2. **One finished task = one commit.** Record it in WORKLOG.md (and ROADMAP.md), then commit.
   Push only when a remote exists (none yet, as of 2026-10-31).
3. **A task is finished only when** the tests pass, the game starts with no errors, and
   `git status -sb` shows a clean tree.
4. **Never invent output.** Quote command output exactly. If something could not be run or
   checked, say so.

## Before doing anything
1. Read the top entries of WORKLOG.md (the last work, its results, anything **In progress**).
2. Read ROADMAP.md → "Next up" for the task to take.
3. Read docs/DESIGN.md (Thai) for the rules of the system you are touching.

## Run and check
The engine binaries `Godot_v4.7.2-stable_win64.exe` / `_console.exe` sit in the project folder
(git-ignored). From the project folder:

- Play: `Godot_v4.7.2-stable_win64.exe --path .` (main scene = the title screen
  `scenes/title.tscn`, which leads to the 3D view `scenes/main.tscn`; `scenes/main_2d.tscn` is
  the flat view). `-- --demo` skips the title and goes straight to the field.
- After adding or renaming a script with `class_name`, run the importer first:
  `Godot_v4.7.2-stable_win64_console.exe --headless --path . --import`
- Tests: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_farm.gd`
  must print `test_farm: OK (0 failed)`. Save / load: same with `res://tests/test_save.gd`
  must print `test_save: OK (0 failed)`. Title menu / new game: same with
  `res://tests/test_title.gd` must print `test_title: OK (0 failed)`. Weather (snow cover,
  lightning): `res://tests/test_weather.gd` must print `test_weather: OK (0 failed)`.
  Dialogue (runner, data, text box layout): `res://tests/test_dialogue.gd` must print
  `test_dialogue: OK (0 failed)`. Pause menu / settings / key remapping: `res://tests/test_menu.gd` must print
  `test_menu: OK (0 failed)`. Fatigue (tired states, oversleeping, collapse):
  `res://tests/test_body.gd` must print `test_body: OK (0 failed)`. Events (runner, trigger
  tables, event data): `res://tests/test_events.gd` must print `test_events: OK (0 failed)`.
  Maps (data/maps, doors, indoor clock, the fade in the real view): `res://tests/test_maps.gd`
  must print `test_maps: OK (0 failed)`. Rucksack / storage (inventory slots, move rules, menu
  cursor, chest): `res://tests/test_inventory.gd` must print `test_inventory: OK (0 failed)`.
  Food and drink (eating, specials, the stand, the food slot): `res://tests/test_food.gd` must
  print `test_food: OK (0 failed)`.
  Holding and throwing (items on the ground, throws, poses, item art): `res://tests/test_hold.gd`
  must print `test_hold: OK (0 failed)`.
  Villagers (rule lists, day plans, catch-up, paths, sprites in both views):
  `res://tests/test_villagers.gd` must print `test_villagers: OK (0 failed)`. Talking (talk
  files and picks, gifts, daily limits, affection save, shopkeepers, bump delay):
  `res://tests/test_talk.gd` must print `test_talk: OK (0 failed)`.
  Relationships (hearts on the name tag, birthdays and x5 gifts, the nightly loss, heart
  events): `res://tests/test_relationships.gd` must print `test_relationships: OK (0 failed)`.
  Shops (data/shops.json, buying / selling, tool upgrades, shop maps and doors, the screen):
  `res://tests/test_shops.gd` must print `test_shops: OK (0 failed)`.
  Animals (chickens, cows, sheep, the coop and barn, products, brushing, sickness, the dog,
  the save): `res://tests/test_animals.gd`
  must print `test_animals: OK (0 failed)`. Fishing (bites, fish tables, the catch, save, poses,
  fish art): `res://tests/test_fishing.gd` must print `test_fishing: OK (0 failed)`.
  Mine (data/mine.json, floors from a seed, rocks / soft spots / the hole, swings, the save,
  mine art): `res://tests/test_mine.gd` must print `test_mine: OK (0 failed)`.
  Festivals (calendar, festival day, shops shut, fair weather, the event once a year,
  decorations and lights in both views, the HUD tag): `res://tests/test_festivals.gd` must
  print `test_festivals: OK (0 failed)`.
- Smoke run (no errors expected): `... --headless --path . --quit-after 300` (title screen) and
  the same with `-- --demo` (the field), `-- --demo --map=town` (the village) and
  `-- --demo --mine=3` (a mine floor).
- Screenshot: `Godot_v4.7.2-stable_win64_console.exe --path . --write-movie shots/frame.png
  --fixed-fps 30 --quit-after 20 -- --demo` writes `shots/frameNNNNNNNN.png` (git-ignored). `--demo`
  starts at 10:00 with planted plots (without `--demo` the frame shows the title screen);
  add `--weather=rain` (storm, snow, blizzard) to force the weather, `--no-flashes` to turn
  lightning off, `--dialogue=<id>` (or `<id>@<line id>`) to open a text box from
  `data/dialogue`, `--pause` (or `--pause=settings`, `--pause=controls`) to open the pause menu, `--tired` to start
  exhausted (tired pose, slow walk), `--event=<id>` to play an event from `data/events`
  (`--demo` turns the trigger tables off, so plain demo frames have no events; to see a
  trigger fire, run `res://scenes/main.tscn` as the scene argument without `--demo`),
  `--map=<id>` (or `<id>@<spawn>`, e.g. `town@shrine`, `farm@gate`) to start on another map
  from `data/maps`, `--rucksack` (or `--rucksack=storage`) to open the rucksack (or the
  storage chest; `--demo` puts a few crops in both), `--hold` to start with a turnip overhead
  and a potato on the ground in front of the bin, `--time=H:MM` (after `--demo`) to set the
  clock (villagers stand where their plans say then; `--demo --map=town` at 10:00 shows Kota
  and Tome by the start spawn), `--shop=<id>` (general, smithy; `general@build` opens a tab) to stand at that shop's
  counter with its screen open (hours ignored), `--talk=<villager>` (with `--map` / `--time`
  where they are, e.g. `--map=town --time=14:30 --talk=tome`) to stand below them and talk
  (add `--hearts=N` to start every villager at heart band N, e.g. to see the heart colours),
  `--built=kitchen,chest,room` to have those house extensions built (with `--map=house` to see
  them), `--map=coop` to look inside the chicken
  coop (`--demo` adds a chick, two eggs and a filled feed box), `--hens-out` (with
  `--map=farm@coop`) to have the hens out in the yard, `--map=barn` for the barn (`--demo`
  adds a cow with milk, a sheep in full wool and a calf; the dog follows the farmer),
  `--barn-out` (with `--map=farm@barn`) for the cows and sheep out grazing, `--fishing` (or `--fishing=wait`) to start at
  the farm pond with the line out and a fish biting (or still waiting), `--festival=<id>`
  (blossom_day, lantern_night, moon_night, years_turn; ids in `data/festivals.json`) to stand
  in the village on that festival's day half an hour into it (Lantern Night: into the
  fireworks; without `--demo`, with `res://scenes/main.tscn`, its event plays), `--mine=N` to stand at the
  ladder of a fresh mine floor N (`--map=mine` is the entrance, `--map=mine_floor` floor 1). Create `shots/` first. Look at the last frame. Delete
  `shots/` afterwards.
- Audio (sound and music data, synthesis, keys used in code, ambient and music pickers): `res://tests/test_audio.gd`
  must print `test_audio: OK (0 failed)`. Headless runs and Movie Maker runs start no sound
  (`Sfx.silent`); add `-- --movie-audio` to a Movie Maker run to record the mix as
  `shots/frame.wav`.
- Run Python as `python -I` (numpy and Pillow are installed) for pixel checks.
- Export (Windows): `Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release
  "Windows Desktop" build/HarvestSon.exe` (preset in `export_presets.cfg`, .pck embedded,
  `build/` git-ignored; run it in the background). It needs the 4.7.2 export templates in
  `%APPDATA%\Godot\export_templates.7.2.stable`; they are not installed as of 2026-10-31, and
  agents must not download them (README → Export has the steps for the user). Check the exe
  with `build/HarvestSon.exe --quit-after 300`.
- App icon: `icon.png` (project) and `icon.ico` (exe) are drawn by `tools/make_icon.gd`; change
  the drawing there and re-run it (`--headless --path . --script res://tools/make_icon.gd`).

## How the code is built
- **Logic is separate from drawing.** Rules live in `scripts/farm/farm_grid.gd` (FarmGrid,
  pure logic, tested headless) and `scripts/autoload/game.gd` (Game: clock, calendar, weather,
  money, bag, stamina, light). Views only read them and redraw on signals (`cells_changed`,
  `changed`, `minute_passed`, `day_started`).
- **Data-driven.** Crops and weather odds are in `data/*.json`, dialogue in `data/dialogue/`, events and trigger tables in `data/events/`. Put new content (crops, items,
  villagers, schedules, events) in data files, not in code.
- `scripts/farm_actions.gd` maps the player's actions to rules. Both views share it.
- The 3D view (`scripts/main_3d.gd`, `scripts/world3d/farm_world.gd`) hides the 2D Player
  (movement and collision in cell pixels, 16 px = 1 cell = 1 world unit) and follows it with a
  Sprite3D. Change the camera only on purpose (see README → Camera).
- Placeholder art comes from `scripts/art/placeholder_art.gd`. Real art replaces it key by key.
- Every new rule gets a check in `tests/` (extend test_farm.gd or add a test script).

## How the user wants the work done
- The user is Thai. Answer them in Thai; keep code, comments and project files in English
  (docs/DESIGN.md is Thai and stays Thai).
- Decisions are delegated: pick the approach, report at the end of a milestone.
- Balance numbers are ours to choose. Keep them in data files and note the reasoning in WORKLOG.

## After every change
1. WORKLOG.md: add an entry at the top (format in that file).
2. ROADMAP.md: tick what is done and keep "Next up" pointing at the next task.
3. Commit with a message that says what changed. End it with the trailer
   `Agent: <agent / product> (<model>)`. Keep the git author as it is.
4. `git status -sb` must show `## main` with no changed or untracked files.
5. Report the commit hash (`git log --oneline -1`).
6. If you must stop mid-task, commit what works and add a WORKLOG entry marked
   **In progress** saying exactly where you stopped and what the next step is.
