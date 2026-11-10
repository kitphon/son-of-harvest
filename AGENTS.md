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
   Push to `origin` (https://github.com/kitphon/son-of-harvest, branch `main`) after each commit.
3. **A task is finished only when** the tests pass, the game starts with no errors, and
   `git status -sb` shows a clean tree.
4. **Never invent output.** Quote command output exactly. If something could not be run or
   checked, say so.

## Before doing anything
1. Read the top entries of WORKLOG.md (the last work, its results, anything **In progress**).
2. Read ROADMAP.md → "Next up" for the task to take.
3. Read docs/DESIGN.md (Thai) for the rules of the system you are touching.
4. For anything about the look (art, models, light, camera), read docs/ART_DIRECTION.md.
5. For any English text the player sees, follow docs/STYLE_EN.md.

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
  must print `test_save: OK (0 failed)`. Title menu / new game (and the farmer's look step: data/farmer_looks.json, FarmerLooks, the preview, the default drawn as before, the art cache per look): same with
  `res://tests/test_title.gd` must print `test_title: OK (0 failed)`. Weather (snow cover,
  lightning, the day / night light of data/light.json, the sun by the clock, when windows light up, the sprites' share of the sun and their warm lift by night lights): `res://tests/test_weather.gd` must print `test_weather: OK (0 failed)`.
  Dialogue (runner, data, text box layout): `res://tests/test_dialogue.gd` must print
  `test_dialogue: OK (0 failed)`. Pause menu / settings (language and the Thai tables, display, text speed, HUD, key hints, reset) / key and pad remapping: `res://tests/test_menu.gd` must print
  `test_menu: OK (0 failed)`. Fatigue (tired states, oversleeping, collapse, waking in the clinic and the doctor's fee):
  `res://tests/test_body.gd` must print `test_body: OK (0 failed)`. Events (runner, trigger
  tables, event data): `res://tests/test_events.gd` must print `test_events: OK (0 failed)`.
  Maps (data/maps, doors, indoor clock, story props gated by flags, the fade in the real view, the land past outdoor edges, buildings turning see-through in front of the farmer, the houses' lit windows at night, the warm pools under windows and lanterns, the warm wash on the pale walls round lit windows and the earthen and charred board walls' own, the glow kept off figures in front, the real night lamps (NightLamps), rice and corn as clusters and the paddies' rice by season, the grass and rice parting round the farmer (Parting), the far mountains past the rim through the game's lens, the village houses' looks: hip roofs, two storeys, walls, meshes kept a run (MeshCache), the maps next door built ahead and the shader warm-up in the fade's black (ShaderWarm), the winter ice along the water's shore (WaterIce), Shino's drying cloth by her vats (DyeCloth: out in her hours on dry days, in on Sundays and her birthday, both views), the noren she dyed over the farmhouse door and her own (shino_noren), Nana's keepsakes in Minamino: Captain's jar by Shige's door, Captain the frog in the ditch behind the beds, her sky map on the hen barn (nana_captain, heart_nana_6, nana_sky), Kiku's persimmon by the farmhouse door or at the field's edge, drawn by the season and grown by the years since it was planted (kiku_scion, kiku_scion_day, Scion and data/scion.json: a sapling on its stake the first year, a young tree the second, a fruiting tree from the third; an old save gets the day it loads on; `--demo --flags=kiku_scion=door` or `=field`, add `--season=fall`; `--scion=young` or `--scion=tree` (or `--scion=N` days ago) for an older tree, e.g. `--demo --flags=kiku_scion=door --season=fall --scion=tree` the persimmons, `--season=winter --snow=80 --scion=tree` the snow on its bare branches)): `res://tests/test_maps.gd`
  must print `test_maps: OK (0 failed)`. Rucksack / storage (inventory slots, move rules, menu
  cursor, chest): `res://tests/test_inventory.gd` must print `test_inventory: OK (0 failed)`.
  Food and drink (eating, specials, the stand, the food slot, the eat / drink pose): `res://tests/test_food.gd` must
  print `test_food: OK (0 failed)`. Cooking (data/recipes.json, cooking rules, the cooking menu,
  recipe lessons and cards, dishes shipped, the kitchen stove): `res://tests/test_cooking.gd` must print
  `test_cooking: OK (0 failed)`.
  Holding and throwing (items on the ground, throws, poses, item art): `res://tests/test_hold.gd`
  must print `test_hold: OK (0 failed)`.
  Villagers (rule lists, day plans, catch-up, paths, sprites in both views, the refined figure art of data/villager_art.json, Hachiro building,
  the Sunday river visit and the fish pose, Ren's post step, Mio's ferry crossing (data/ferry.json, FerryRun, the pole pose), whistling: who may whistle when, the note puff):
  `res://tests/test_villagers.gd` must print `test_villagers: OK (0 failed)`. Talking (talk
  files and picks, gifts, daily limits, affection save, shopkeepers, bump delay):
  `res://tests/test_talk.gd` must print `test_talk: OK (0 failed)`.
  Relationships (hearts on the name tag, birthdays and x5 gifts, the nightly loss, heart
  events at bands 3, 5 and 6, birthday day plans, fair weather and the HUD tag, mine finds, dishes and
  keepsakes as gifts, marriage: the mizuhiki knot's rules and answers, the proposal, the wedding day
  and its trigger, the spouse's day plan and lines, their festival days and birthday at the farmhouse, the spouse's morning help, the save): `res://tests/test_relationships.gd` must print `test_relationships: OK (0 failed)`.
  Shops (data/shops.json, buying / selling, tool upgrades and their ores, mine finds sold, the smithy while Hachiro builds,
  shop maps and doors, the screen, Fumi's teahouse):
  `res://tests/test_shops.gd` must print `test_shops: OK (0 failed)`.
  Animals (chickens, cows, sheep, the coop and barn, products, brushing, sickness, the dog,
  the save): `res://tests/test_animals.gd`
  must print `test_animals: OK (0 failed)`. Fishing (bites, fish tables, the river, the catch, save, poses,
  fish art): `res://tests/test_fishing.gd` must print `test_fishing: OK (0 failed)`.
  Forage (data/forage.json, the hill's spots by season, picking, the morning regrowth, the save,
  shipping and eating, the views, the art): `res://tests/test_forage.gd` must print `test_forage: OK (0 failed)`.
  Mine (data/mine.json, floors from a seed, rocks / soft spots / the hole, swings, the save,
  light by depth and the lantern, frozen winter floors, the rope lift landings and their save, mine art): `res://tests/test_mine.gd` must print `test_mine: OK (0 failed)`.
  Ending (data/ending.json, grading, the values measured, the event and its trigger, the record
  screen, the yearly pages, the first-day look back and the married farmer's line, the child's name and stage in it): `res://tests/test_ending.gd` must print `test_ending: OK (0 failed)`.
  Festivals (calendar, festival day, shops shut, fair weather, the event once a year,
  decorations and lights in both views, the HUD tag, contests and prizes, the mochi pounding (timing, ranking, partner, ribbon, save, screen), the Moon Night fishing race (clock, creel, ranking, ribbon, save, box), the stalls and their
  wares at all four festivals, keepsakes, ribbons and the farmhouse ribbon board, the payout held back, the festival lights lighting the ground and the night lamps): `res://tests/test_festivals.gd` must
  print `test_festivals: OK (0 failed)`.
  The flat view (main_2d.tscn builds, its Player's actions reach FarmActions: tools, holding
  and throwing, the bin, eating, fishing, doors, talking, the shop counter, the mine; the
  throw's flight; rain / snow, lightning and the festival glow): `res://tests/test_view2d.gd` must print `test_view2d: OK (0 failed)`.
  The child (data/child.json, Child: the news and the birth days, the stages by days, the look from the parents, each spouse's three names, the hearts' band 3 floor, the save; the news and birth scenes per spouse: the due flags each morning, the farmhouse triggers, the names offered and the one picked, the Thai; `--demo --map=house --built=room --flags=married_sayo,spouse=sayo --event=child_birth_sayo --dialogue=child@sayo_pick` shows the name choice; the baby in the bamboo cradle: the cradle only in the baby stage, the lines by the clock, lifting the baby into the hold pose and laying them back, never thrown, the door waits, a save while holding loads with the baby in the cradle, both views; the crawler and the toddler: data/child.json days / figures / gifts, the plans by the spouse at home and in the yard by the kennel, wet and festival days in, the figures (FigureArt.draw_little), talk_child.json picked by stage with the name put in, gifts from the toddler on, the hearts never below band 3, both views; the child stage: the yard in the morning, out at the spouse's side from 10:00 on free floor on every spouse's maps (Child.place, with.tries), home together, the festival all day with them, in on wet days, the morning help (two weeds from band 5 on sunny days, the message after the spouse's, the help_weeds line), the child_ talk lines, both views at the store; holding the crawler (data/child.json hold): the tool button facing them lifts them into the hold pose (child:carry), either button sets them down in front or back where they were, they sit there until the stay ends, the door waits, a map change, the night and a load put them back to the plan, both views, the toddler and the child never lifted): `res://tests/test_child.gd` must print `test_child: OK (0 failed)`.
  Goals (Tome's first-week list: data/goals.json, what is counted, rewards paid once, the notes, the save, the HUD tag):
  `res://tests/test_goals.gd` must print `test_goals: OK (0 failed)`.
  Languages (LangCatalog finds the English, no glued pieces in the scripts, no stale table
  entries, the English style of docs/STYLE_EN.md, Lang.join / list, the pseudo language, the
  screens and the dialogue still fitting a third longer, the Thai dialogue fitting the box, the daily talk all Thai): `res://tests/test_lang.gd` must print `test_lang: OK (0 failed)`.
  Showcase (data/showcase.json: the fixed trailer views; every map, spawn, festival and lens they name exists): `res://tests/test_showcase.gd` must print `test_showcase: OK (0 failed)`. The views are rendered with `python -I tools/showcase.py --out shots/showcase` (README → Showcase).
  Puddles (data/puddles.json: rain and storm only, none in snow or with snow lying, growth over the first game hour, drying after a rainy day, placement on paths and gravel only, sizes, rain rings, both views): `res://tests/test_puddles.gd` must print `test_puddles: OK (0 failed)`.
  Drifting life (data/drift.json: spring petals, fall leaves, summer-night fireflies; season / weather / clock / indoor gating, the wind carrying them, counts, both views): `res://tests/test_drift.gd` must print `test_drift: OK (0 failed)`.
- Smoke run (no errors expected): `... --headless --path . --quit-after 300` (title screen) and
  the same with `-- --demo` (the field), `-- --demo --map=town` (the village) and
  `-- --demo --mine=3` (a mine floor).
- Screenshot: `Godot_v4.7.2-stable_win64_console.exe --path . --write-movie shots/frame.png
  --fixed-fps 30 --quit-after 20 -- --demo` writes `shots/frameNNNNNNNN.png` (git-ignored). `--demo`
  starts at 10:00 with planted plots (without `--demo` the frame shows the title screen);
  add `--weather=rain` (storm, snow, blizzard) to force the weather, `--no-flashes` to turn
  lightning off, `--snow=N` (0..100) for that much snow lying (on the farm and the outdoor
  maps: `--season=winter --map=town --snow=80`; add `--footprints` for a trail of footprints already pressed in it, `--map=town@shrine` shows it well), `--dialogue=<id>` (or `<id>@<line id>`) to open a text box from
  `data/dialogue`, `--pause` (or `--pause=settings`, `--pause=controls`) to open the pause menu, `--ui=150%` (125%) for a UI size this run only, `--lang=th` for the Thai text this run only (`--lang=pseudo`: every text a third longer) (with `--dialogue=opening@field` a Thai text box), `--lens=<id>` (ps1, wide; data/camera.json, the game uses medium) for another camera lens, `--goals` to turn Tome's first-week list on in a `--demo` run (plain demo runs have it off; `--goals=plant,hello` marks those done, so the HUD tag shows the next), `--look=style:2,hair:1,skin:3,clothes:4` for the farmer in that look (places in data/farmer_looks.json's lists, 0 = the default; ids work too), `--new-game` (without `--demo`) to open the new game's look step on the title screen, `--tired` to start
  exhausted (tired pose, slow walk), `--eat` (or `--eat=drink`) to stand mid-bite (or mid-sip)
  with the eat pose kept going, `--event=<id>` to play an event from `data/events`
  (`--demo` turns the trigger tables off, so plain demo frames have no events; to see a
  trigger fire, run `res://scenes/main.tscn` as the scene argument without `--demo`),
  `--map=<id>` (or `<id>@<spawn>`, e.g. `town@shrine`, `farm@gate`) to start on another map
  from `data/maps` (the villagers' homes: `--map=tome_house --time=6:30` shows Tome by her
  hearth; `kota_house`, `sayo_house`; `town@sayo` stands at Sayo's side door of the store;
  `--map=clinic --time=12:00` shows the village clinic with Dr. Yae at her counter, `town@clinic` its door), `--rucksack` (or `--rucksack=storage`) to open the rucksack (or the
  storage chest; `--demo` puts a few crops in both), `--hold` to start with a turnip overhead
  and a potato on the ground in front of the bin, `--time=H:MM` (after `--demo`) to set the
  clock (villagers stand where their plans say then; `--demo --map=town` at 10:00 shows Kota
  and Tome by the start spawn; add `--whistle` (or `--whistle=<id>`) and every walker whistles at
  once, a note puff over their head), `--shop=<id>` (general, smithy, clinic, teahouse; `general@build` opens a tab) to stand at that shop's
  counter with its screen open (hours ignored), `--talk=<villager>` (with `--map` / `--time`
  where they are, e.g. `--map=town --time=14:30 --talk=tome`) to stand below them and talk
  (add `--hearts=N` to start every villager at heart band N, e.g. to see the heart colours;
  the wedding: `--demo --map=town@shrine --time=10:00 --event=wedding_sayo` (or `wedding_fumi`),
  the first line at about 110 frames; married at home: `--demo --map=house --built=room
  --flags=married_sayo,spouse=sayo --time=19:00`; add `--baby` for a child born that day, asleep or awake in the
  bamboo cradle in the second room by `--time`, the farmer standing below it (named the spouse's first name, or
  `--flags=child_name=Sora`), `--baby=held` with the baby in the farmer's arms; `--child=crawler`
  (`toddler`, `child`) for the little one at that stage (born that many days ago; the year moves
  on to 2 when needed): `--demo --map=house --built=room --flags=married_sayo,spouse=sayo
  --child=crawler --time=18:00 --talk=child` the crawler by Sayo, talking; `--child=crawler:held` (same flags, `--time=7:00`) the crawler in the farmer's arms beside Sayo; `--demo
  --weather=sunny --flags=married_sayo,spouse=sayo --child=toddler --time=10:00 --map=farm@coop`
  the toddler in the yard by the kennel; `--demo --weather=sunny --flags=married_sayo,spouse=sayo
  --child=child --time=12:00 --map=store` the child by Sayo at the store),
  `--flags=a,b=c` to set story flags (`--flags=hachiro_bell` the bell by the farmhouse door,
  `--map=town@sayo --flags=sayo_sign=new` the store's new sign, `--map=house
  --flags=tome_grandma` Tome's plum jar; `--map=hill` the foot of the bamboo hill (its forage spots by `--season`), `hill@top` its
  lookout; `--map=kaminoda@well --time=8:30` the hamlet north of the village, Genzo and Haru out;
  `--map=sakurazaka@bridge --time=12:10` the cherry road east, Ichiro at lunch by the teahouse;
  `--map=sakurazaka@newkiln --flags=ichiro_kiln` the new kiln half built beside Ichiro's old one, `--flags=ichiro_mark` (or both) the finished kiln with the farmer's thumbprint;
  `--map=kaminoda@jizo --flags=genzo_jizo` the jizo in Genzo's new red bibs; `--demo --season=fall --map=minamino@river --flags=nana_scarf` the jizo by the Minamino lane in Nana's new red scarf;
  `--map=minamino@shige --time=9:00` the gardens south, Shige and Nana at work; `--map=minamino@shige --flags=heart_nana,nana_captain=jar` Captain's jar by Shige's door; `--map=minamino@barn --flags=heart_nana_6,nana_sky,nana_beside,nana_star=field` Nana's sky map on the hen barn and Captain the frog in the ditch behind the beds),
  `--built=kitchen,chest,room` to have those house extensions built (with `--map=house` to see
  them), `--building=<id>` (kitchen, chest, room) to have that extension under way since
  yesterday (`--time=10:00`: Hachiro hammering at the farmhouse wall by his lumber; the smithy
  counter has a note), `--cook` to stand at the kitchen stove with the cooking screen open (builds the kitchen;
  `--demo` adds eggs, a fish, a carrot and one learned recipe), `--map=coop` to look inside the chicken
  coop (`--demo` adds a chick, two eggs and a filled feed box), `--hens-out` (with
  `--map=farm@coop`) to have the hens out in the yard, `--map=barn` for the barn (`--demo`
  adds a cow with milk, a sheep in full wool and a calf; the dog follows the farmer),
  `--barn-out` (with `--map=farm@barn`) for the cows and sheep out grazing, `--fishing` (or `--fishing=wait`) to start at
  the farm pond with the line out and a fish biting (or still waiting; `--fishing=river`, `--fishing=river:wait` at the
  river south of the village, `--map=river` its path in), `--festival=<id>`
  (blossom_day, lantern_night, moon_night, years_turn; ids in `data/festivals.json`) to stand
  in the village on that festival's day half an hour into it (Lantern Night: into the
  fireworks; without `--demo`, with `res://scenes/main.tscn`, its event plays; add
  `--contest=<item>`, e.g. `--festival=blossom_day --contest=potato`, to stand at the judges'
  table with that item and enter it, the results' text box open after ~4 s, so use
  `--quit-after 120`; `--festival=years_turn --contest=mochi` starts the mochi pounding at the mortar, and
  `--contest=mochi:auto` swings on the beat by itself (about 5 s in is mid-round, `--quit-after 150`); `--festival=moon_night --contest=fishing` starts the fishing race at the village pond and `--contest=fishing:auto` casts and reels by itself (about 20 s in is mid-race, `--quit-after 690`); `--shop=stall:blossom_day` (or `stall:lantern_night:eats`, `stall:lantern_night:chimes`,
  `stall:moon_night:eats`, `stall:moon_night:crafts`, `stall:years_turn:soba`, `stall:years_turn:charms`) stands at
  that festival stall with it open; `--map=house --flags=ribbons=blossom_day:1:1` shows the
  ribbon board), `--ending` (or `--ending=year`) to open the village record (or the yearly page)
  (README → Ending; `--map=house --event=ending` plays the scene, `--event=year_record` the yearly one), `--mine=N` to stand at the
  ladder of a fresh mine floor N (darker deeper; `--map=mine` is the entrance, `--map=mine_floor` floor 1; every fifth floor down to 15 has a rope lift:
  `--map=mine@cave --landings=5,10 --lift` opens the cave mouth's choice of the ladder or the lift),
  `--day=N` to start on day N of the season (`--day=7` is the first Sunday: `--demo --day=7
  --weather=sunny --map=river@shore --time=14:45` shows Hachiro and Kota fishing the river),
  `--season=<id>` to start on day 1 of a season (`--season=winter --mine=3`: a frozen floor; with `--demo` the field has that season's crops: `--season=fall` ripe daikon, `--season=summer` ripe rice). Create `shots/` first. Look at the last frame. Delete
  `shots/` afterwards.
- Audio (sound and music data, synthesis, keys used in code, ambient and music pickers, the villagers' whistled tunes): `res://tests/test_audio.gd`
  must print `test_audio: OK (0 failed)`. Headless runs and Movie Maker runs start no sound
  (`Sfx.silent`); add `-- --movie-audio` to a Movie Maker run to record the mix as
  `shots/frame.wav`.
- Translation coverage: `--headless --path . --script res://tools/lang_report.gd` (add
  `-- --lang=th` for one language, `-- --list` for every missing line) prints what each
  language covers and writes `build/lang/<id>_todo.json`. A screenshot with `--lang=pseudo`
  shows every text a third longer (README → Settings → Language).
- Run Python as `python -I` (numpy and Pillow are installed) for pixel checks.
- Export (Windows): `Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release
  "Windows Desktop" build/HarvestSon.exe` (preset in `export_presets.cfg`, .pck embedded,
  `build/` git-ignored; run it in the background). It needs the 4.7.2 export templates in
  `%APPDATA%\Godot\export_templates.7.2.stable`; they are not installed as of 2026-10-31, and
  agents must not download them (README → Export has the steps for the user). Check the exe
  with `build/HarvestSon.exe --quit-after 300`.
- Farmhouse model: `--path . --script res://tools/house_model.gd -- --shots=shots` (with a
  window) writes `shots/house_<front|left|back|above>.png`; `--headless ... -- --glb=models/farmhouse.glb`
  rewrites the Blender copy (re-run it after changing the house; README → Farmhouse model).
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
