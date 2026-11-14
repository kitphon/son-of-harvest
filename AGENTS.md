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
  must print `test_farm: OK (0 failed)` (it also checks the greenhouse's beds: any season, no weather, their save). Save / load: same with `res://tests/test_save.gd`
  must print `test_save: OK (0 failed)`. Title menu / new game (and the farmer's look step: data/farmer_looks.json, FarmerLooks, the preview, the default drawn as before, the art cache per look): same with
  `res://tests/test_title.gd` must print `test_title: OK (0 failed)`. Weather (snow cover,
  lightning, the day / night light of data/light.json, the sun by the clock, when windows light up, the sprites' share of the sun and their warm lift by night lights): `res://tests/test_weather.gd` must print `test_weather: OK (0 failed)`.
  Dialogue (runner, data, text box layout, the refined portraits of data/portrait_art.json): `res://tests/test_dialogue.gd` must print
  `test_dialogue: OK (0 failed)`. Pause menu / settings (language and the Thai tables, display, text speed, HUD, key hints, reset) / key and pad remapping: `res://tests/test_menu.gd` must print
  `test_menu: OK (0 failed)`. Fatigue (tired states, oversleeping, collapse, waking in the clinic and the doctor's fee):
  `res://tests/test_body.gd` must print `test_body: OK (0 failed)`. Events (runner, trigger
  tables, event data): `res://tests/test_events.gd` must print `test_events: OK (0 failed)`.
  Maps (data/maps, doors, indoor clock, the Arashiyama-style village at 56 x 48 (the wide river and the long bridge, its stone street, the temple wall and gate, the bamboo path, the stations and lines, the black torii, shop fronts: TempleProps, `"street": "east"`; spawns `temple`, `bridge`, `bamboo`, `park`, `station`), story props gated by flags, the fade in the real view, the land past outdoor edges, buildings turning see-through in front of the farmer, the figures standing upright and stretched for the camera (FarmWorld.upright / stretch) and drawn clear of a wall behind their feet (FarmWorld.wall_pull, data/camera.json figure_pull: the solid cells and the built meshes' low footprint in ReachMap, never nearer the eye than a figure in front of their feet: FarmWorld.cap_pulls; `tools/reach_dump.gd` measures it), the houses' lit windows at night, the warm pools under windows and lanterns, the warm wash on the pale walls round lit windows and the earthen and charred board walls' own, the glow kept off figures in front, the real night lamps (NightLamps), rice and corn as clusters and the paddies' rice by season, the grass and rice parting round the farmer (Parting), the far mountains past the rim through the game's lens, the village houses' looks: hip roofs, two storeys, walls, meshes kept a run (MeshCache), the maps next door built ahead and the shader warm-up in the fade's black (ShaderWarm), the winter ice along the water's shore (WaterIce), Shino's drying cloth by her vats (DyeCloth: out in her hours on dry days, in on Sundays and her birthday, both views), the noren she dyed over the farmhouse door and her own (shino_noren), Nana's keepsakes in Minamino: Captain's jar by Shige's door, Captain the frog in the ditch behind the beds, her sky map on the hen barn (nana_captain, heart_nana_6, nana_sky), Kiku's persimmon by the farmhouse door or at the field's edge, drawn by the season and grown by the years since it was planted (kiku_scion, kiku_scion_day, Scion and data/scion.json: a sapling on its stake the first year, a young tree the second, a fruiting tree from the third; an old save gets the day it loads on; `--demo --flags=kiku_scion=door` or `=field`, add `--season=fall`; `--scion=young` or `--scion=tree` (or `--scion=N` days ago) for an older tree, e.g. `--demo --flags=kiku_scion=door --season=fall --scion=tree` the persimmons, `--season=winter --snow=80 --scion=tree` the snow on its bare branches)): `res://tests/test_maps.gd`
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
  files and picks, gifts, daily limits, affection save, shopkeepers, bump delay, E's reach to the side and a step on, slipping past a villager in the way, the villager stepping aside and the farmer the other way (Villagers.give_way, _common.json give_way)):
  `res://tests/test_talk.gd` must print `test_talk: OK (0 failed)`.
  Relationships (hearts on the name tag, birthdays and x5 gifts, the nightly loss, heart
  events at bands 3, 5 and 6, birthday day plans, fair weather and the HUD tag, mine finds, dishes and
  keepsakes as gifts, marriage: the mizuhiki knot's rules and answers, the proposal, the wedding day
  and its trigger, the spouse's day plan and lines, their festival days and birthday at the farmhouse, the spouse's morning help, the save): `res://tests/test_relationships.gd` must print `test_relationships: OK (0 failed)`.
  Shops (data/shops.json, buying / selling, tool upgrades and their ores, mine finds sold, the smithy while Hachiro builds,
  shop maps and doors, the screen, Fumi's teahouse):
  `res://tests/test_shops.gd` must print `test_shops: OK (0 failed)`.
  Animals (chickens, cows, sheep, the coop and barn extensions: wings, capacity, spots, the moved props, Hachiro building on the farm, the fodder silo: its job, footprint, grass from the sickle, the nightly fodder, taking it to the loft, the save, its grass pile beside it by the stores (SiloPile: stages, the art, snow, both views) and its line on the pause menu's main page; `--demo --built=silo --map=farm@silo` (add `--silo=30` or `--silo=30:4` after `--built=silo` for that much grass and fodder in it; `farm@gate` keeps the farmer off the pile), `--demo --built=silo --silo=30:4 --pause` the pause menu's silo line, `--demo --building=silo --time=10:00 --map=farm@gate`, the greenhouse's job and Hachiro's days at it in test_shops, its beds' rules in test_farm, its map, door and 3D in test_maps, its save in test_save and the flat view in test_view2d: `--demo --built=greenhouse --map=farm@greenhouse`, `--demo --building=greenhouse --time=10:00 --map=farm@greenhouse`, `--demo --map=greenhouse --season=winter` (the beds inside, sown by `--demo` with crops of every season), old age and the old look, the dog's age, the coop and barn, products, brushing, sickness, the dog,
  the save, the carrying cow's and ewe's look in both views, aging: the age on E, old, the peaceful passing): `res://tests/test_animals.gd`
  must print `test_animals: OK (0 failed)`. Fishing (bites, fish tables, the river, the catch, the fish log counts and its save, poses,
  fish art): `res://tests/test_fishing.gd` must print `test_fishing: OK (0 failed)`.
  Forage (data/forage.json, the hill's spots by season, picking, the morning regrowth, the save,
  shipping and eating, the views, the art): `res://tests/test_forage.gd` must print `test_forage: OK (0 failed)`.
  Mine (data/mine.json, floors from a seed, rocks / soft spots / the hole, swings, the save,
  light by depth and the lantern, frozen winter floors, the rope lift landings and their save, mine art): `res://tests/test_mine.gd` must print `test_mine: OK (0 failed)`.
  Ending (data/ending.json, grading, the values measured, the event and its trigger, the record
  screen, the yearly pages, the first-day look back and the married farmer's line, the child's name and stage in it): `res://tests/test_ending.gd` must print `test_ending: OK (0 failed)`.
  Festivals (calendar, festival day, shops shut, fair weather, the event once a year,
  decorations and lights in both views, the HUD tag, contests and prizes, the mochi pounding (timing, ranking, partner, ribbon, save, screen), the Moon Night fishing race (clock, creel, ranking, ribbon, save, box), the Lantern Night goldfish scoop (the tub, dips, paper wear and tear, balance, ranking, the farmer's scoop pose at the tub, ribbon, save, screen), the stalls and their
  wares at all four festivals, keepsakes, ribbons and the farmhouse ribbon board, the payout held back, the festival lights lighting the ground and the night lamps): `res://tests/test_festivals.gd` must
  print `test_festivals: OK (0 failed)`.
  The flat view (main_2d.tscn builds, its Player's actions reach FarmActions: tools, holding
  and throwing, the bin, eating, fishing, doors, talking, the shop counter, the mine; the
  throw's flight; the standing figures sorting by their feet in FigureLayer: the farmer, villagers, animals and the dog, the carried item with the farmer; rain / snow, lightning and the festival glow): `res://tests/test_view2d.gd` must print `test_view2d: OK (0 failed)`.
  The child (data/child.json, Child: the news and the birth days, the stages by days, the look from the parents, each spouse's three names, the hearts' band 3 floor, the save; the news and birth scenes per spouse: the due flags each morning, the farmhouse triggers, the names offered and the one picked, the Thai; `--demo --map=house --built=room --flags=married_sayo,spouse=sayo --event=child_birth_sayo --dialogue=child@sayo_pick` shows the name choice; the baby in the bamboo cradle: the cradle only in the baby stage, the lines by the clock, lifting the baby into the hold pose and laying them back, never thrown, the door waits, a save while holding loads with the baby in the cradle, both views; the crawler and the toddler: data/child.json days / figures / gifts, the plans by the spouse at home and in the yard by the kennel, wet and festival days in, the figures (FigureArt.draw_little), talk_child.json picked by stage with the name put in, gifts from the toddler on, the hearts never below band 3, both views; the child stage: the yard in the morning, out at the spouse's side from 10:00 on free floor on every spouse's maps (Child.place, with.tries), home together, the festival all day with them, in on wet days, the morning help (two weeds from band 5 on sunny days, the message after the spouse's, the help_weeds line), the child_ talk lines, both views at the store; holding the crawler (data/child.json hold): the tool button facing them lifts them into the hold pose (child:carry), either button sets them down in front or back where they were, they sit there until the stay ends, the door waits, a map change, the night and a load put them back to the plan, both views, the toddler and the child never lifted): `res://tests/test_child.gd` must print `test_child: OK (0 failed)`.
  Goals (Tome's first-week list: data/goals.json, what is counted, rewards paid once, the notes, the save, the HUD tag):
  `res://tests/test_goals.gd` must print `test_goals: OK (0 failed)`.
  Languages (LangCatalog finds the English, no glued pieces in the scripts, no stale table
  entries, the English style of docs/STYLE_EN.md, Lang.join / list, the pseudo language, the
  screens and the dialogue still fitting a third longer, the Thai dialogue fitting the box, the daily talk all Thai): `res://tests/test_lang.gd` must print `test_lang: OK (0 failed)`.
  Tool-use effects (data/tool_fx.json, ToolFxRules: what each tool throws on each target (soil clods and dust, the can's spray and splash rings, grass bits, wood chips, stone chips and a spark, an ore's glint, a puff for a miss, a leaf puff on a harvest), the ground's colours (dry, wet by wet.json's tilled tone, snow, the mine), the particles and their cap, the farmer's swing_<tool> poses (seeds' scatter too, every tool inside the picture, the charge's wind-up), the cell's change, the tool sound and the effect all on the swing's hit frame in both views (stamina on the press; a map change, the day's end and a save land a swing in the air first, a load drops it), till / water / sow / harvest by hand, snow bits that read on snow, the bursts freeing themselves): `res://tests/test_tool_fx.gd` must print `test_tool_fx: OK (0 failed)`.
  Showcase (data/showcase.json: the fixed trailer views; every map, spawn, festival and lens they name exists): `res://tests/test_showcase.gd` must print `test_showcase: OK (0 failed)`. The views are rendered with `python -I tools/showcase.py --out shots/showcase` (README → Showcase).
  Puddles (data/puddles.json: rain and storm only, none in snow or with snow lying, growth over the first game hour, drying after a rainy day, placement on paths and gravel only, sizes, rain rings, both views): `res://tests/test_puddles.gd` must print `test_puddles: OK (0 failed)`.
  Wet look (data/wet.json: rain and storm wet the open air over the first game hour and it dries by late morning after; none under snow, indoors, under glass or in the mine; surfaces: tilled soil darkest, kawara glossiest, thatch little; the ground masks, the 3D materials wetted and put back exactly, the ground shader's `wet`, the flat view's tints, stone props and eave glints): `res://tests/test_wet.gd` must print `test_wet: OK (0 failed)`.
  Insects (data/insects.json, InsectRules, InsectArt: honeybees (`bee`) in spring and early summer on fair days, working the cherry trees' blossom (high), crops, forage spots and garden beds (low) with short hovers and quick zigzag hops (`--demo --season=spring --time=11:00 --map=kaminoda --insects=bee` by the cherry tree at the start; both views), white and pale yellow butterflies over the crops, forage spots, garden beds and open grass of spring and early summer days (1-16 of summer), red dragonflies (akatombo) in small swarms over the paddies, the river and pond and open ground in late summer (17-28) and fall, hovering, darting and hovering again, now and then landing on a fence post, a drying rack's pole, a tall crop's top or a rice tip and resting with the wings flat; season / day of the season / weather / clock / wind / indoor gating (none at night, in rain, storm or snow, in rooms or the mine; the wind thins them), the places and counts, the perches, the rest and the lift-off, the farmer and the other walkers startling a resting dragonfly and making a butterfly veer, the drawn pictures, both views, the flat view's fliers in the Air pass with the birds' (z flat.air_z) and the resting ones in the y-sorted FigureLayer by the ground under them, their shadows (a blob under a perched dragonfly, a very faint sun-cast oval under a flier in sun, none over buildings: InsectRules.shadow_of on the birds' helpers, data/insects.json `shadow`; the 3D blobs on GROUND_LAYER); `--demo --season=fall --time=11:00 --map=farm@gate --insects=dragonfly:perched` one resting on the perch nearest the farmer; `--demo --season=fall --time=11:00 --map=kaminoda --insects` the dragonflies by the paddies, `--demo --time=11:00 --insects=butterfly` the butterflies over the farm's plots: `--insects` forces them (add `=dragonfly,butterfly` to pick kinds), placed round the farmer at the start; the flat view: `res://scenes/main_2d.tscn` as the scene argument): `res://tests/test_insects.gd` must print `test_insects: OK (0 failed)`.
  Drifting life (data/drift.json: spring petals, fall leaves, summer-night fireflies; season / weather / clock / indoor gating, the wind carrying them, counts, both views): `res://tests/test_drift.gd` must print `test_drift: OK (0 failed)`.
  Morning mist (data/mist.json: low sheets over the water and the paddies at dawn, thickest 5:00-6:30 and gone by 8:00; season / weather / wind / indoor gating, the density curve, the cells it rises from, the drift on the wind, both views; `--demo --weather=sunny --time=6:15 --map=river@shore`, `--season=fall --time=6:00 --map=kaminoda` the paddies): `res://tests/test_mist.gd` must print `test_mist: OK (0 failed)`.
  Birds (data/birds.json, BirdRules, BirdArt: swallows by day in spring and summer, a flock of crows at dusk in every season, a heron by the water in the morning, sparrows by the houses; season / weather / clock / indoor gating, the places and heights, the farmer startling sparrows and the heron and the villagers, the dog and the walking child doing it too (not the crawler), the shadows: a soft blob under a bird on the ground, a faint one cast along the sun for a flier only while Game.sun_shadow() is on (none in rain, snow, at night), the drawn pictures, both views, the flat view's two passes in main_2d: birds on the ground sorted with the villagers, the animals and the farmer by their feet (a node each in the y-sorted FigureLayer), fliers (Air, z_index flat.air_z) over the roofs, props and figures, under the weather and the night tint; `--demo --time=10:00 --map=town@clinic --birds=sparrow --weather=sunny` the sparrows and their blobs; `--demo --time=17:30 --map=town@shrine --birds` forces them: add `=crow,swallow,heron,sparrow` to pick kinds, they stand or cross round the farmer at the start, so look at frames 8-12, swallows cross a 12-cell view in about 3 s; `--demo --time=7:00 --map=kaminoda --birds=heron` the heron by the paddies; the flat view: `res://scenes/main_2d.tscn` as the scene argument): `res://tests/test_birds.gd` must print `test_birds: OK (0 failed)`. Breath in the cold (data/breath.json, BreathRules, BreathLayer, BreathView: who breathes, the cold by season / day / clock / weather, the puffs' own gaps, the mouth by facing, the wind and the fade, the wisp of sub-puffs, the cap, the crawler, a lifted sprite's lift, the flat view's whole pixels and its puffs sorting with the figures by their owner's feet; `--demo --season=winter --time=6:30 --map=town --breath` the puffs, `--breath=strong` more of them): `res://tests/test_breath.gd` must print `test_breath: OK (0 failed)`.
  Cicadas (data/cicadas.json, CicadaRules, CicadaArt, CicadaLayer, CicadaView: the day cicada's chorus (amb_cicadas) from early summer, fullest mid / late summer round midday, lingering a few early fall days, the evening cicada's falling call (amb_higurashi) at dusk in late summer; none at night, in rain, storm or snow, indoors or in the mine, nor in spring and winter; louder on the wooded hill, softer on the farm, a little under the wind; the Sfx autoload adding them to the ambient loops (they left data/sfx.json's ambient rules; a loop layer with `phrase` keeps its own length); a few clinging to the camera side of the trees' trunks (sakura, persimmon, maple, the foot of a leaning village pine, and Kiku's persimmon as a young or fruiting tree: CicadaRules.add_scion, its trunk on the picture's plane, the farm's 3D CicadaLayer and the flat view's cicadas drawn over the story props), pumping as they sing, flying off with a buzz (cicada_buzz) from the farmer and the other walkers and back to the same spot once they have gone; both views; `--demo --map=sakurazaka@teahouse --season=summer --day=20 --time=12:00 --cicadas` (or `--cicadas=semi`, `=higurashi`) one on every tree near the farmer; the flat view: `res://scenes/main_2d.tscn` as the scene argument): `res://tests/test_cicadas.gd` must print `test_cicadas: OK (0 failed)`.
  Icicles (data/icicles.json, IcicleRules, IcicleLayer, IcicleView: winter only with snow lying on the roofs (min_cover), none indoors, in the mine or the greenhouse; grown over the winter's days and with the snow, melted back round a sunny midday and frozen again by night, the drip; spots along an eave from a hash of its ends, inside it and tucked under it; the eave lines Minka lists (Minka.note_eave, FarmWorld.eaves: the farmhouse, the village houses' front eaves, kept through MeshCache, none from the greenhouse's glass); the flat view's strips under the painted roofs' bottom eave, clear of the doors; both views; `--demo --season=winter --snow=80 --map=town --icicles` (or `--icicles=long`), the flat view: `res://scenes/main_2d.tscn` as the scene argument): `res://tests/test_icicles.gd` must print `test_icicles: OK (0 failed)`.
  Carp streamers (data/koinobori.json, KoinoboriRules, KoiArt, KoinoboriProps, KoinoboriView: koinobori on a bamboo pole in front of Kota's house in the village in late spring (spring days 16-30, 6:00-18:00; taken down in rain, storm and outside those days), a pinwheel, the five-colour streamer and the black, red and blue carp, limp in a calm and filling out, flapping and streaming in the wind of data/wind.json (the gusts, the flap rate, the wheel's speed); the gating, the pictures, the prop's cell free of paths, doors and spawns with every door and spawn still reachable, both views; `--demo --season=spring --map=town@koinobori --koinobori` forces the pole up whatever the date, hour and weather, `--koinobori=0` in a dead calm (limp carp), `--koinobori=0.8` in a strong wind (streaming); the flat view: `res://scenes/main_2d.tscn` as the scene argument; `town@koinobori` is the riverside path three cells west of its foot, by Kota's house): `res://tests/test_koinobori.gd` must print `test_koinobori: OK (0 failed)`.
  Hoshigaki (data/hoshigaki.json, HoshigakiRules, HoshigakiArt, HoshigakiLayer, HoshigakiView: strings of peeled persimmons drying under the farmhouse's front eave and under the front eave of some village houses (HoshigakiRules.village_hangs, a hash of the house's cell) in fall days 10-30, taken in on a day of rain, storm or snow, none indoors, in the mine or the greenhouse; dried by the days hung from fresh bright orange to a shrunken deep red-brown with a sugar bloom (the picture stages); a slow sway with data/wind.json, still in calm; the picture: a straw rope, 6-10 persimmons in three tones lit from the upper left, the stalk's knot on the rope; the 3D strings on the real eave lines (FarmWorld.eaves), tucked under the soffit, clear of the doors, fading with their house (Occluders.fade_of_tag); the flat view's smaller strings under the painted roofs' bottom eave, clear of the doors; `--demo --season=fall --day=20 --weather=sunny --time=11:00 --hoshigaki` the farmhouse's, add `--map=town` the village's, `--hoshigaki=0` fresh, `--hoshigaki=18` fully dried; the flat view: `res://scenes/main_2d.tscn` as the scene argument): `res://tests/test_hoshigaki.gd` must print `test_hoshigaki: OK (0 failed)`.
  Furin (data/furin.json, FurinRules, FurinLayer, FurinView, the picture PlaceholderArt "furin": the wind chime under the farmhouse's eave over the engawa, out on the farm's open air in summer, taken in during a storm or a blizzard, never indoors or in other seasons; still in dead calm, swinging further and quicker with the wind (data/wind.json) and a slow gust swell; the bell lit from the upper left in three tones with its red band, clapper and paper strip; both views on the farm, none on the hill): `res://tests/test_furin.gd` must print `test_furin: OK (0 failed)`. A summer farm frame: `--demo --season=summer --weather=sunny --time=10:00 --map=farm` (3D; the chime is left of the door, above the engawa), and the same with `res://scenes/main_2d.tscn` as the scene argument (flat).
- Smoke run (no errors expected): `... --headless --path . --quit-after 300` (title screen) and
  the same with `-- --demo` (the field), `-- --demo --map=town` (the village) and
  `-- --demo --mine=3` (a mine floor).
- Windowed run (headless runs and Movie Maker make no sound jobs, so they cannot catch a crash in
  the sound threads): `Godot_v4.7.2-stable_win64_console.exe --path . --quit-after 150 -- --demo`
  must exit 0 (a crash shows as exit 139 / signal 11).
- Screenshot: `Godot_v4.7.2-stable_win64_console.exe --path . --write-movie shots/frame.png
  --fixed-fps 30 --quit-after 20 -- --demo` writes `shots/frameNNNNNNNN.png` (git-ignored). `--demo`
  starts at 10:00 with planted plots (without `--demo` the frame shows the title screen);
  add `--weather=rain` (storm, snow, blizzard) to force the weather, `--no-flashes` to turn
  lightning off, `--wet=1.0` (0..1) to force the wet look of rain (darker, glossier ground, roofs and stone; still none indoors or with snow lying; `--demo --map=town --weather=rain --time=11:00` is the real thing, `--time=6:30` half wet), `--snow=N` (0..100) for that much snow lying (on the farm and the outdoor
  maps: `--season=winter --map=town --snow=80`; add `--footprints` for a trail of footprints already pressed in it, `--map=town@shrine` shows it well), `--dialogue=<id>` (or `<id>@<line id>`) to open a text box from
  `data/dialogue`, `--pause` (or `--pause=settings`, `--pause=controls`, `--pause=fishlog`: the fish log with a few catches in it; `--pause=shipped`: the shipped page with a few items shipped) to open the pause menu, `--ui=150%` (125%) for a UI size this run only, `--lang=th` for the Thai text this run only (`--lang=pseudo`: every text a third longer) (with `--dialogue=opening@field` a Thai text box), `--lens=<id>` (ps1, wide; data/camera.json, the game uses medium) for another camera lens, `--goals` to turn Tome's first-week list on in a `--demo` run (plain demo runs have it off; `--goals=plant,hello` marks those done, so the HUD tag shows the next), `--look=style:2,hair:1,skin:3,clothes:4` for the farmer in that look (places in data/farmer_looks.json's lists, 0 = the default; ids work too), `--new-game` (without `--demo`) to open the new game's look step on the title screen, `--insects` (or `--insects=dragonfly,butterfly`; `--insects=dragonfly:perched` holds the first dragonfly resting on the perch nearest the farmer; add `:rice`, `:corn`, `:tomato`, `:cucumber`, `:eggplant`, `:paddy`, `:fence` for the nearest of that kind) to force butterflies and red dragonflies in round the farmer (`--demo --season=fall --time=11:00 --map=kaminoda --insects`, `--demo --time=11:00 --insects=butterfly`), `--crops=tomato,eggplant[:stage]` (the stage a number, `ripe` when none: `--crops=tomato:2`) to plant that row of crops on the demo field, along its top row in equal runs, placed even out of season (eggplant is fall's; Game.demo_crops_of): `--demo --season=summer --time=11:00 --crops=tomato,eggplant --insects=dragonfly:perched:tomato` (or `:eggplant`) the perched dragonfly on that plant; `--demo --flags=kiku_scion=door --scion=tree --season=summer --day=20 --time=12:00 --cicadas` the cicadas on Kiku's persimmon (the forced ones start settled on the trunks for `forced_calm` 3 s, so frame ~30 shows one; the farmer starting beside the tree sends them off after that, and `--walk=right:0.6` takes him off so they come back to the trunk about 20 s later: render ~800 frames, `--quit-after 800`), 3D and flat (`res://scenes/main_2d.tscn`, `--quit-after 40` for the first look); `--cicadas` (or `--cicadas=semi,higurashi`) to have cicadas sing and cling to every tree's trunk whatever the season and clock (`--demo --map=sakurazaka@teahouse --season=summer --day=20 --time=12:00 --cicadas`), `--tired` to start
  exhausted (tired pose, slow walk), `--walk=<up|down|left|right>[:seconds]` (after `--demo`) to hold that move key (for good without a time; `--demo --map=coop --walk=up:2` the farmer against the coop's back wall), `--swing=<tool>` (hoe, water, sickle, axe, hammer, seeds; after `--demo`) to have the farmer swing that tool in place on repeat at the cell in front, made ready each time (bare ground, a dry tilled cell, a weed, a branch, a rock; down the mine a rock or a soft spot; a seed of the season for seeds); `--charge=<tool>` (hoe, water, sickle, axe, hammer; after `--demo`) to hold the use button down with that tool from the start, never let go: the wind-up pose and the charge pips stay up (`--demo --charge=hoe:left` turns him left first, `--quit-after 60` lets the charge climb; both views); `--swing=<tool>:<up|down|left|right>` turns him that way first (`--demo --map=farm@gate --swing=hoe:up` shows a back facing): the first hit lands about frame 13, its bits in flight in frames 15-25 (`--demo --swing=hoe`, `--demo --weather=rain --time=11:00 --swing=hoe`, `--demo --season=winter --snow=80 --swing=hoe`, `--demo --mine=3 --swing=hammer`), `--eat` (or `--eat=drink`) to stand mid-bite (or mid-sip)
  with the eat pose kept going, `--event=<id>` to play an event from `data/events`
  (`--demo` turns the trigger tables off, so plain demo frames have no events; to see a
  trigger fire, run `res://scenes/main.tscn` as the scene argument without `--demo`),
  `--map=<id>` (or `<id>@<spawn>`, e.g. `town@shrine`, `farm@gate`) to start on another map
  from `data/maps` (the villagers' homes: `--map=tome_house --time=6:30` shows Tome by her
  hearth; `kota_house`, `sayo_house`; `town@sayo` stands at Sayo's side door of the store;
  `--map=clinic --time=12:00` shows the village clinic with Dr. Yae at her counter, `town@clinic` its door), `--rucksack` (or `--rucksack=storage`) to open the rucksack (or the
  storage chest; `--demo` puts a few crops in both), `--cord` (with `--demo --map=barn`) to hold the Musubi cord below a happy grown animal, the hint "Tie", `--full` (after `--demo`) to fill the coop and the barn to their places (with `--built=coop_wing` / `barn_wing`, the extended ones: `--demo --built=coop_wing --map=coop --full`), `--dog-held` to start with the dog in the farmer's arms (add `--old` for the old dog's grey face), `--hold` to start with a turnip overhead
  and a potato on the ground in front of the bin, `--time=H:MM` (after `--demo`) to set the
  clock (villagers stand where their plans say then; `--demo --map=town@temple --time=7:40` shows
  Tome at the temple gate; add `--whistle` (or `--whistle=<id>`) and every walker whistles at
  once, a note puff over their head), `--shop=<id>` (general, smithy, clinic, teahouse; `general@build` opens a tab; `--shop-row=N` puts the cursor on row N of the open tab and scrolls to it, e.g. `--demo --built=greenhouse --shop=general --shop-row=99` the last "under glass" row) to stand at that shop's
  counter with its screen open (hours ignored), `--talk=<villager>` (with `--map` / `--time`
  where they are, e.g. `--map=town --time=14:30 --talk=tome`) to stand below them and talk
  (`--pass=<villager>` instead stands two cells below them and walks up into them and past: `--demo --map=town --time=10:00 --pass=kota`, frames 14-22 show the give-way step;
  add `--hearts=N` to start every villager at heart band N, e.g. to see the heart colours;
  the wedding: `--demo --map=town@temple --time=10:00 --event=wedding_sayo` (or `wedding_fumi`),
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
  coop (`--demo` adds a chick, two eggs and a filled feed box), `--map=greenhouse` for the greenhouse's beds inside (`--demo` sows them with crops of every season; add `--season=winter`), `farm@greenhouse` the cell before its door on the farm (with `--built=greenhouse` the glasshouse, `--building=greenhouse --time=10:00` Hachiro at work), `--icicles` (or `--icicles=long`) to hang the icicles on every roof's eaves outdoors whatever the season, snow and clock (`--icicles` 0.7 of their full length, `=long` all of it; IcicleRules, `--demo --season=winter --snow=80 --map=town --icicles`, the flat view with `res://scenes/main_2d.tscn`), `--hoshigaki` (or `--hoshigaki=<days hung>`) to hang the drying persimmon strings under the farmhouse's and some village houses' eaves outdoors whatever the date and weather (days hung: the real ones in the fall window, else 6; HoshigakiRules, `--demo --season=fall --day=20 --weather=sunny --time=11:00 --hoshigaki`, `--map=town`, the flat view with `res://scenes/main_2d.tscn`), `--breath` (or `--breath=strong`, the puffs come faster) to force the breath in the cold on an outdoor map at any season and clock (BreathRules, `--demo --season=winter --time=6:30 --map=town --breath`), `--no-hud` to leave the HUD off for a frame (the flat view's silo sits under the clock), `--hens-out` (with
  `--map=farm@coop`) to have the hens out in the yard, `--map=barn` for the barn (`--demo`
  adds a cow with milk, a sheep in full wool and a calf; the dog follows the farmer; add `--carrying` for a carrying cow and ewe beside them, rounder and lower in the belly; `--old` makes every grown animal and the dog old: "(old)" in its name, a greying face, its age on E),
  `--barn-out` (with `--map=farm@barn`) for the cows and sheep out grazing, `--fishing` (or `--fishing=wait`) to start at
  the farm pond with the line out and a fish biting (or still waiting; `--fishing=river`, `--fishing=river:wait` at the
  river south of the village, `--map=river` its path in), `--festival=<id>`
  (blossom_day, lantern_night, moon_night, years_turn; ids in `data/festivals.json`) to stand
  in the village on that festival's day half an hour into it (Lantern Night: into the
  fireworks; without `--demo`, with `res://scenes/main.tscn`, its event plays; add
  `--contest=<item>`, e.g. `--festival=blossom_day --contest=potato`, to stand at the judges'
  table with that item and enter it, the results' text box open after ~4 s, so use
  `--quit-after 120`; `--festival=years_turn --contest=mochi` starts the mochi pounding at the mortar, and
  `--contest=mochi:auto` swings on the beat by itself (about 5 s in is mid-round, `--quit-after 150`); `--festival=moon_night --contest=fishing` starts the fishing race at the village pond and `--contest=fishing:auto` casts and reels by itself (about 20 s in is mid-race, `--quit-after 690`); `--festival=lantern_night --contest=scoop` starts the goldfish scoop at the goldfish stall and `--contest=scoop:auto` dips by itself (about 10 s in is mid-game, `--quit-after 330`); `--shop=stall:blossom_day` (or `stall:lantern_night:eats`, `stall:lantern_night:chimes`,
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
- Saves: a player's run saves to `user://save1.json`; every test or tool (`--script`), Movie Maker
  run and `--demo` run uses `user://dev/save1.json` instead (SaveGame.slot / is_dev_run), so no
  check can overwrite the player's game. Never write SaveGame.SLOT directly from a test or tool.
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
- Map overviews: `--path . --script res://tools/map_overview.gd -- --out=shots/maps` (with a window) writes
  every map whole in the flat view as `shots/maps/<id>.png` (`--maps=town,farm`, `--season=`, `--time=H:MM`).
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
