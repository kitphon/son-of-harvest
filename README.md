# Harvest Son

A farming life-sim prototype in Godot 4: a 3D field seen through a fixed diagonal camera,
with the characters and field objects as pixel sprites. The rules follow our
design doc: [docs/DESIGN.md](docs/DESIGN.md) (Thai; a copy of the online doc
https://claude.ai/artifact/32gupMu1YQVJULs9n6nPEk).
All code, art, names and numbers are our own. Nothing is taken from any other game's files.

## Run
Double-click `play.bat` (title screen) or `play_demo.bat` (straight to the field, `--demo`);
both start `Godot_v4.7.2-stable_win64.exe` next to them and pass on any extra arguments.
Or open the folder in Godot 4.7 (`Godot_v4.7.2-stable_win64.exe`, kept next to the project but
not in git) and press F5. From a shell:

    Godot_v4.7.2-stable_win64_console.exe --path .

The game opens on the title screen (`scenes/title.tscn`): New game, Continue (greyed out when
`user://save1.json` is missing or can't be loaded) or Quit, with the arrows / W S and
Enter / Space or the mouse. The field itself is `scenes/main.tscn`.
The flat top-down view is still there as `scenes/main_2d.tscn` (F6 on that scene). It plays
the same game: both views hook their Player to `FarmActions.connect_view`.
Add `-- --demo` to skip the title and start at 10:00 with a few planted plots (for screenshots), and
`--weather=<sunny|rain|storm|snow|blizzard>` after it to force today's weather.

Tests (farm rules, headless):

    Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_farm.gd

Save / load, the title menu, weather, dialogue and events: the same with `res://tests/test_save.gd`,
`res://tests/test_title.gd`, `res://tests/test_weather.gd`, `res://tests/test_dialogue.gd` and
`res://tests/test_events.gd`. The flat view's action hookup: `res://tests/test_view2d.gd`
(every test script is listed in AGENTS.md → Run and check).

## Controls
| Key | Action |
| --- | --- |
| WASD / arrows | walk along the field's axes (Up = diagonally away from the camera); Shift = run |
| Space / J | use the tool on the cell in front; hold to charge (pips over the farmer), let go for a bigger area; tools level up with use (pips in the item box). With an item overhead on the farm: set it down on the cell in front |
| E / K | interact: harvest (the crop goes up overhead, into the hand slot), pick up an item lying in front, ship the rucksack's crops at the bin (with nothing to ship: read the note on it), buy seeds at the stand, open the storage chest right of the house, go through doors (walking into one works too), sleep at the futon in the house. With an item overhead on the farm: throw it up to 2 cells ahead; into the bin it's shipped, into the pond it's gone |
| E / Space / Enter, click | in a text box: show the whole line, then go on; arrows / W / S or the mouse pick a choice |
| 1-8 / Tab | pick a tool slot (at the start: hoe, watering can, sickle, hammer, axe, seeds, food, fishing rod; Space / J eats or drinks the food in hand, on any map; with a crop, egg, milk, fish or dish overhead it eats that instead) |
| Space / J with the rod | cast at water up to 2 cells ahead (the farm pond, the village pond, the river down the lane off the village's south edge); wait for the "!" and a plip, then Space / J / E in time to land the fish (it goes up overhead: throw it in the bin to ship it, or put it in the rucksack). Pressing before a bite reels in empty. Fish per place / season / hour / weather: `data/fish.json` |
| I | rucksack: arrows / WASD move, Enter / Space pick up and put down (stack, swap), E takes it in hand (tool slot = tool in hand, an item = the item hand), Esc / I close; mouse: left click pick / put, right click hold, F eats or drinks the thing under the cursor (food, crops, eggs, milk, fish; not out of the chest). The chest screen works the same. The clock stops while it is open |
| Q | next seed type, or next food with the food slot (for eating and for buying) |
| E at the kitchen stove / cupboard | (kitchen corner built) the cooking screen: up / down pick a recipe, Enter / Space / E cook it once, Esc / I leave (README → Cooking) |
| E at a shop counter | opens the shop (village store and smithy, inside their doors, while open): up / down pick, left / right how many, Enter / Space / E buy, sell or hand a tool in / pick it up, Tab / Q next tab, Esc / I leave; the mouse points and clicks |

These are the default keys. Esc → Settings → Controls rebinds them: pick an action, left / right
pick its first or second key or its pad button (the third column), Enter, then press the new
key or pad button, or pull a trigger (LT / RT) or push the right stick (RS-up / -down / -left /
-right) (Esc cancels; one another action has is swapped over, never leaving an
action without a key). Delete / Backspace empties a slot, "Reset to defaults" puts keys and
buttons back. Esc and the pad's Start always pause. Default pad: D-pad and the left stick
walk, A tool, B talk / throw, X run, RB / LB next tool / seed, Back rucksack, Y eat. The
defaults are in `data/controls.json`, the player's keys are saved under `controls` in
`user://settings.json`, the pad buttons (triggers and right-stick directions too, by id:
`right_trigger`, `rs_up`...) under `pad`. The triggers and the right stick are free by default;
the left stick always walks.

## Settings
Esc → Settings, rows from `data/settings.json` (a new setting is one entry there), each in
effect the moment it changes and saved to `user://settings.json` (version 2; a version 1 file's
"full" window is read as Borderless):
- Language: English or ไทย (Thai), first in the list and shown in its own language. The game is
  written in English; a language is a set of tables in `data/lang/<id>/*.json` keyed by the
  English text (`scripts/ui/lang.gd`): plain entries, patterns with `%s` / `%d` for text that
  changes ("Bought %s for %d G"; the `%s` part is looked up again, `{1}`, `{2}` reorder the
  parts), multi-line text line by line; anything without an entry stays English. Every Label
  translates itself (Lang puts a `LangTranslation` into Godot's TranslationServer); the text
  box, the cooking lists and the widths ask `Lang.t` / `PixelFont.shown_width` themselves.
  Thai is drawn by our pixel font (`data/font_pixel.json`): consonants at the lowercase height,
  vowels and tone marks in `marks`, placed by `PixelFont.shape` (a tone over a vowel above
  rises, marks over ป ฝ ฟ move left, ำ is a ring and า). Thai text needs spaces between
  phrases so the text box can wrap it. Done in Thai: all menus and screens, the HUD and key
  hints, the messages, item / place / people names and part of the dialogue (see
  `data/lang/th/dialogue.json`'s note). `-- --lang=th` tries a language for one run.
  Writing text so it can be translated: one key per sentence, never glued from pieces. Use a
  whole format for each wording (`"Found %s (rucksack full)."`, `"%s %d day."` and
  `"%s %d days."` rather than a word put in), `Lang.join([...])` for sentences said together
  (each looked up on its own), `Lang.list(names)` for "a, b and c" (the keys `"%s, %s"` and
  `"%s and %s"`), a data field for wording that differs per thing (a kitchen tool's `a_name`,
  "an iron rice pot"), and `PixelFont.shown_width` (not `width`) to measure shown text.
  `LangCatalog` (`scripts/ui/lang_catalog.gd`) gathers every English text from the dialogue,
  the data files and the scripts' string literals; `tools/lang_report.gd` prints how much of
  it each language covers (by dialogue / data / code, a text counts when it comes out wholly
  translated), lists table entries no text uses any more (stale) and pieces glued in the
  scripts, and writes `build/lang/<id>_todo.json` with the missing lines for a translator.
  `-- --lang=pseudo` is a test language with no tables: every text a third longer (padded
  with `=`), to see a longer language on screen; test_lang checks the screens with it.
  How the English itself is written (spelling, names, messages): docs/STYLE_EN.md.
- Display: Window, Full screen (exclusive) or Borderless (a window over the whole screen).
- Window size: 2x / 3x / 4x the 480 x 270 picture, while the display is a window. Sizes bigger
  than the screen are left out of the row; a saved size that doesn't fit shows (and is) the
  biggest that does, and comes back on a bigger screen.
- V-sync on / off; FPS limit Off / 30 / 60 / 120 / 144 (with v-sync on the screen's rate caps
  it too); Lightning flashes on / off (`-- --no-flashes` wins).
- UI size 100% / 125% / 150%: the HUD (each corner grows from its corner), the pause menu (it
  shows fewer rows and scrolls), the rucksack, shop, cooking and record screens and the text
  box, each grown only as far as it still fits on the 480 x 270 picture (the full-width text
  box has no room, so it stays at 100%; a menu too big for 150% gets 125%). Not whole sizes, so
  some pixels draw a little wider. `-- --ui=150%` tries a size for one run without saving it.
- Text speed: Slow / Normal / Fast (x0.5 / x1 / x2 the letters per second in
  `data/text_box.json`) or Instant (whole lines at once).
- Always run: the farmer runs, the run key walks. Show HUD: off hides the whole HUD.
- Key hints (on by default): a line over the tool bar says what the interact and tool buttons
  do at the spot in front, with the player's own keys ("E Talk  Space Water", "E Ship",
  "Space Cast" at water, "E/Space Reel in"); hidden while a menu, text box or event is up
  (`scripts/ui/action_hints.gd` picks the words and changes nothing). After a pad button or a
  stick push (past half way) the hints show the player's pad buttons ("B Talk  A Water"); the
  next key or click brings the keys back.
- Pad buttons: Auto / Xbox / PlayStation, next to Key hints. Auto reads the name and guid of the pad
  last used (`Controls.style_of`: Sony names or the vendor id 054c): a PlayStation pad shows Cross,
  Circle, Square, Triangle, L1 / R1, L2 / R2, Share, Options (data/controls.json `pad_names_ps`);
  any other pad keeps A, B, X, Y, LB / RB, LT / RT, Back, Start. Xbox or PlayStation forces one
  style for the key hints and the controls page. Saved with the settings, reset by Reset to defaults.
- Music / Sounds / Ambient volume sliders.
- Reset to defaults (the settings above; the keys have their own reset under Controls).

## What works (v0)
- Clock: 1 game minute = 0.5 s, day starts 6:00, 4 seasons x 30 days, day/night tint.
- Weather rolled a day ahead per season (`data/weather.json`); rain waters the field, storms
  can destroy crops.
- Farm grid 32 x 20: till, water (can refills at the pond), seed bag sows 3 x 3, crops grow
  one stage per watered night (`data/crops.json`), regrowing crops, out-of-season crops wither,
  weeds appear, rocks / branches / weeds / stumps cleared by the right tool.
- Shipping bin pays at 18:00 (or when you sleep); the seed stand sells this season's seeds,
  and food / drink when the food slot is in hand (`data/foods.json`: stamina +, fatigue −).
- Shops (`data/shops.json`, README → Shops): the village store sells seeds by season and food
  and buys crops, sells chickens, feed, medicine and bigger rucksacks, and takes orders for
  house extensions; the smithy upgrades tools and the rod for money over a few days.
- Stamina: each swing costs stamina; sleep before midnight restores it all, after midnight
  3/4, passing out at 2:00 half.
- Sound: every effect and ambient loop is made in code from recipes in `data/sfx.json`
  (`scripts/audio/sfx_synth.gd`, no sound files). Tools, footsteps by ground, bin lid,
  payday coins, menu, a chime at 6:00; rain, storm wind and thunder after lightning,
  cicadas on summer days, crickets at night, running water on the river map and a soft
  lapping within a few cells of the farm and village ponds (not in a storm or blizzard),
  cross-faded by weather / season / hour / map / nearness to water.
- Music: our own short loops written as notes in `data/music.json` (five-note scales, koto /
  shakuhachi / sho-like voices made by `scripts/audio/music_synth.gd`): a title theme, one
  per season, night and rain, cross-faded by scene / weather / hour; inside the Yorozu Store
  and the Kurogane Smithy their own tunes (rules with `maps`), a gentle score under the heart
  events and a bright one under the opening of a new game (rules with `events`: while one of
  those event scripts plays, `Sfx.event_playing()`). Esc → Settings has
  Music / Sounds / Ambient volume sliders.
- Chickens (`data/animals.json`, `Animals`): the thatched coop right of the stand is a map
  with a door. Inside: E on the feed box fills it from the feed sack (one portion a hen), on
  a nest takes an egg overhead (throw it into the bin to ship it), on the incubator puts a
  held egg in (a chick in 3 nights), on the hatch in the right wall lets the hens out to the
  yard on a sunny day (4 hours out = a meal), on a hen strokes her (or gives her Animal
  Medicine when she is sick). Happiness moves each night; it picks the egg grade (Egg, Good
  Egg, Golden Yolk Egg). Unhappy or hungry hens can fall sick; they get well with medicine
  or by themselves after 5 nights. A new game starts with two hens; `Game.add_animal(kind)`
  is the shop's hook. Overnight news is told when you next walk into the coop.
- Cows and sheep (same `Animals` rules): the barn with the tiled roof between the coop and
  the pond is a map. Inside: six straw stalls, the fodder trough (E on it or on the hay
  bundles fills it, one bundle an animal), the brush / milker / shears on the wall and the
  wide gate in the right wall (out to graze in front of the barn on a sunny day). E on a cow
  or a sheep does what is due: milk it / shear it when ready (overhead, ship it like an egg),
  else brush it, else talk to it. A fed, healthy cow has milk every morning (Milk, Rich Milk,
  Hillside Cream Milk by happiness), a sheep's wool grows back in 3 nights (Wool, Soft Wool,
  Cloud Wool; it looks shorn until then). Calves / lambs grow up in 14 / 10 nights. The
  barn starts empty: `Game.add_animal("cow" | "sheep", young)` and `Game.animals.add_fodder(n)`
  are the shop's hooks.
- The dog (Goro): wanders near its spot right of the stand, and once fond enough (about a
  week of pats) follows the farmer about the farm. E pets it (once a day counts), E again
  picks it up; either button sets it down in front. A day without either costs affection.
- Fatigue (hidden, data/body.json): rises with work in the rain or late at night, with staying
  up past 22:00 and with working on an empty stamina bar; only sleep lowers it, more the
  earlier you go to bed. Tired: the farmer slumps and sweats; exhausted: slower and can't run.
  Going to bed tired or after midnight means oversleeping; full fatigue is a collapse: wherever
  it happens the farmer wakes at 12:00 next day in the village clinic's bed (body.json collapse
  `wake_map` / `wake_spawn`) and Dr. Yae says her piece (triggers_clinic.json, flags
  `clinic_wake` / `clinic_free`); the first visit is free, later ones cost `fee` (the flag
  `clinic_visits` counts them). Still up at 2:00 is a pass-out: wake at home, no fee. The
  clinic (east of the smithy, open 9-17 every day) sells a herb tonic (fatigue -15).

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
village (`town`), the river south of it, past Minamino (`river`, its own fish table: place `river` in
`data/fish.json`; water at a map's side edge draws no bank, so the river flows on), Kaminoda up
the village's north lane (`kaminoda`: a farming hamlet of terraced paddies, a drying rack, a
well, jizo and a persimmon orchard; Genzo's and Haru's houses, `genzo_house` / `haru_house`),
Sakurazaka on the
village road's east end, on the way to the mine (`sakurazaka`: cherry trees along the road, a
creek under a plank bridge with its own stream fish, place `sakurazaka` in `data/fish.json`;
Fumi's Hanami teahouse, `teahouse`, and Ichiro the charcoal burner's house, `ichiro_house`),
Minamino
between the village's south lane and the river (`minamino`: vegetable gardens behind a board
fence, a well, a roadside water shrine, Kiku's persimmon orchard; Shige and Nana's house,
`shige_house`, and Kiku's, `kiku_house`), the bamboo hill above Kaminoda (`hill`: a switchback path through `bamboo` clumps to a lookout with a
little shrine; its view and shrine can be examined). Countryside props (CountryProps, both
views): `well`, `jizo`, `persimmon` and `sakura` (their leaves follow the season), `hasa` (a
rice drying rack, sheaves hung in fall), `woodpile`, `garden`, `wood_fence`. Ground tiles include the
solid `paddy` (a flooded rice paddy). A file has `id`, `size` [w, h], `indoor` (the clock stands still inside, as
DESIGN asks for every building), `ambient` (which `places` of the ambient rules in
`data/sfx.json` apply), optional `light` (a fixed room light instead of day / night),
`walls` (an indoor map's wall infill in 3D, `plaster` or `board`; RoomWalls builds the "wall"
cells as a timber frame, the back walls full height, the front ones a low sill, plus a step
edge where boards or tatami meet the earth and a shoe stone below the door's step) and
`background`, then:
- `legend` + `ground`: one row of characters per map row; each character is
  `{tile, solid?, step?}` (tile = a `ground:<kind>` placeholder, step = footstep sound kind);
- `props`: `{kind, cell, size?, solid? (default true), blocks? (only these cell offsets
  block), use?}`; `use: "sleep"` is the futon. Their 3D looks are in `scripts/world3d/map_world.gd`;
- `doors`: `{cells, to, spawn, facing, shop?, hours?, closed?}`, or `{cells, message}` for a
  door that only says something. A door with `shop` stays shut outside that shop's hours and
  says so; one with `hours` `["H:MM", "H:MM"]` (a villager's home) is open from the first
  time until the second and shows its `closed` message otherwise (`MapData.door_open`). Door cells are solid; walking into one, or
  using it, goes through. Cells just off the edge make a walk-off exit; on the farm
  `gate: true` leaves those fence cells open in the drawing;
- the coop (`coop`) uses props with `use` `feed_box`, `nest`, `incubator`, `feed_sack` and
  `hatch` (CoopActions), their 3D looks in `scripts/world3d/coop_props.gd`; the barn (`barn`)
  `fodder_box`, `fodder`, `barn_tools`, `barn_gate` (BarnActions), looks in `barn_props.gd`;
- the villagers' homes (`tome_house`, `kota_house`, `sayo_house`; Hachiro lives in the
  smithy) use `irori`, `tokonoma`, `butsudan`, `zabuton` (`solid: false`, optional `color`),
  `byobu`, `toy_box` and `mizugame`, their 3D looks in `scripts/world3d/room_props.gd` (RoomProps, with all the rooms' furniture); a
  `village_house` prop's `side_door` (cells from the left) draws a second, plain door (Sayo's
  rooms behind the store);
- a prop with `flag` (a story flag name) only shows while that flag is set, or with
  `flag_value` too only while the flag has that value (MapManager.with_flags; a map is read
  again when one of its flags changes, and the views pick it up on the next map change). The
  band 5 and 6 heart events' story props use it (StoryProps, art `story:<kind>` in both
  views): `door_bell` on the farm (`hachiro_bell`), `store_sign` with `style` old / new in the
  village (`sayo_sign`), `ume_jar` in the farmhouse (`tome_grandma`), `carp_streamer` on the
  farm (`kota_streamer`, band 6), `jizo_bibs` on the two jizo by the Kaminoda lane
  (`genzo_jizo`, band 5: new red bibs over the old) and `kiln_mark` on Ichiro's charcoal kiln
  (`kiln`, 2 x 2, below his house in Sakurazaka, two thumbprints over its mouth), which keeps
  standing; beside it the new kiln grows with the story: `kiln_site` (`ichiro_kiln`, band 5: a
  half-built mound of clay bricks with a pile of bricks, a timber form and a shovel) until
  `ichiro_mark` (band 6) is set, when `kiln_new` (the finished kiln with Ichiro's thumbprint)
  and `kiln_mark` (the farmer's) take its place. A prop's `unless` (a flag name) hides it
  while that flag is set. A story prop listed before the prop it
  sits on is the one `prop_at` finds, so its examine line takes over while its flag is set.
  A prop with `use: "examine"`
  plays its `sound` (data/sfx.json) and shows its `message` when used, on any map;
- the village clinic (`clinic`, door east of the smithy, shop `clinic`) has a `bed` spawn by
  its futon (a futon prop without `use` is only a bed), where a collapse wakes the farmer;
- `spawns`: named `[cell, facing]`, `start` needed (`--map=<id>@<spawn>`), the house has
  `home` (where a new day starts); the villagers' homes have `home` where their owner sits.

`Game.maps` (MapManager) holds the map, the farmer's position and facing (saved);
`Game.go_to_map()` changes it and emits `map_changed` (the views fade, rebuild, place the
farmer), and once the picture is back `map_entered(map_id)`, the hook for event triggers.

## Villagers
Each villager is a file `data/villagers/<id>.json` (shared numbers in `_common.json`: walk
speed in cells per game minute, cells per walk frame): `id`, `name`, optional `speed`, `look`
(`outfit` kimono / happi / shirt_shorts, `hair_style` bun / short / headband / long /
straw_hat, colours `hair`, `skin`, `top`, `waist`, `lower`, `accent`, `shoes`; drawn by
`PlaceholderArt` as `villager:<id>:<front|back>:<idle|walk>:<frame>`), `birthday`
(`{"season": "fall", "day": 24}`, optional; the farmhouse calendar names it), optional
`hearts` (false: a villager the farmer can't grow close to, like Dr. Yae at the clinic: no
birthday, heart events or place in the village record; `Villagers.friends()` is everyone
else (Tome, Hachiro, Sayo and Kota, and from Sakurazaka Fumi and Ichiro, and Genzo and Haru of Kaminoda, and Shige of Minamino), and the heart checks
in test_relationships loop over it; a friend needs a birthday with its lines and day plan, a
`heart_<id>` event at band 3 in the trigger table of every map they can be talked on, and a
part in the ending (`data/events/ending.json`); `heart_<id>_5` / `_6` are optional, checked
when the file is there), then:
- `rules`: `[{"if": {conditions}, "plan": "<name>"}]`, the first that holds picks the day's
  plan, else `default`. Conditions: `season`, `weekday`, `weather` (lists), `days`, `year`
  (`[first, last]`), `flags` / `not_flags` (story flags set / not set), `festival` (festival
  ids from `data/festivals.json`: today is one of them), `birthday` (true: today is this
  villager's own birthday; each villager has a `birthday` plan, e.g. Sayo shuts the store at
  12:30 for lunch at Tome's, Hachiro keeps the smithy shut);
- `plans`: name -> entries `{"at": "H:MM", "map": "<map id>" or "away", "from": [x, y],
  "route": [steps], "loop": [steps]}`. The first entry is at 06:00, times after midnight
  belong to the same day. `away` = in bed (or somewhere we don't draw): every villager is at
  home on their house map (`tome_house`, `kota_house`, `sayo_house`, `smithy`) in the early
  morning, around noon, in the evening and on wet days, and `away` from the time their door
  shuts (test_villagers checks a plan is on a house map only inside its door's hours). An entry onto a map
  needs `from` unless the entry before was on the same map (then it walks on from there).
  Steps: `{"to": [x, y]}` (walk straight there), `{"wait": minutes}`, `{"work": minutes}`
  (stands like a wait in the work pose, a hammer up and down, `work_strokes_per_minute` in
  _common.json; each blow knocks, Sfx `build_knock`), `{"fish": minutes}` (stands with a rod
  out, the line down from its tip; the tip dips one minute in every `fish_bob_minutes`; Kota and
  Hachiro at the river on a fair Sunday), `{"face": "up"}`. The
  route is walked once, then the loop over and over until the next entry. A route must
  arrive before the next entry starts, and test_villagers checks no walk crosses a solid cell.

`DayPlan` (scripts/villagers/day_plan.gd) turns a plan into timed legs and answers
`where(minute)`; `Villagers` loads the files, picks the plans for the day in
`Game.trigger_state` and answers `on_map(map, minute, state)`, `where(id, ...)` and
`is_on(id, map, ...)` (the hook for "the shop is shut while its keeper is out"). Positions are
a pure function of `Game.day_minutes()`, so a map shows everyone where their plan puts them
when the farmer walks in (the catch-up) and nothing has to be saved. The views add a
`VillagerSprites` (3D) / `VillagerView` (2D) to each map they build, homes included, so the
farmer can talk to them at home too (`-- --demo --map=tome_house --time=6:30`).

**Talking, gifts, affection.** E facing a villager (or facing a counter with them behind it)
turns them to the farmer (`Villagers.turn`) and calls `Game.talk_to(id, face)`:
- an item overhead (the rucksack's hand slot) is a gift: the reaction comes from the
  villager's `gifts` (`{"love" | "like" | "dislike" | "hate": [items]}`, `"fish:*"` = any
  fish, anything else neutral), the item is gone, affection changes by the reaction
  (`_common.json` `affection.gift`), at most one gift a day (a second stays in hand);
- a shopkeeper at their map's `keeper` spot opens the shop (`data/shops.json` `keeper`);
- anyone else opens their lines, `data/dialogue/talk_<id>.json`: an ordinary dialogue plus
  `picks`, `[{"if": {conditions}, "at": [line ids]}]`, the last row without `if`. Conditions
  are the rule ones above plus `time` (`["H:MM", "H:MM"]`), `band` (heart band `[low, high]`,
  0..6), `again` (already talked today), `birthday` (true on their birthday) and `map` (map ids:
  the map the villager stands on, e.g. Kota's and Hachiro's river lines); the day picks
  one of the row's lines. Gift answers are the lines `gift_love` .. `gift_hate` and
  `gift_again`; an optional `gift_birthday` answers a gift that isn't disliked on their birthday.
  An optional `gift_items` table gives a villager their own answer to keepsakes and dishes
  (`Talk.gift_line`): `{"keep:<id>" | "food:<recipe id>": line id}` for one item, or
  `"dish:<reaction>"` / `"keepsake:<reaction>"` for any dish (a food with a recipe in
  `data/recipes.json`) or keepsake met that way; anything else answers with `gift_<reaction>`.
The first talk of a day adds `affection.talk`. `Affection` (scripts/villagers/affection.gd,
`Game.affection`, saved since save version 3) keeps the points (0..`max`), the 7 heart
`bands` and the last talk / gift day per villager; `Game.affection.add(id, n)` is the hook,
and events use the `affection` step and the `talk` / `hearts` trigger keys (Events).
On a villager's birthday a gift counts `affection.birthday_times` over (5, good or bad), the
weather is fair (`Game.fair_tomorrow`, as on a festival, DESIGN) and the HUD tag under the clock
reads "<Name>'s birthday" (`HudLayout.day_tag`, `Game.birthdays_today`). Gift lists may name
mine finds (`mine:<id>`). Each
night a villager the farmer has met (affection above 0) who got neither a talk nor a gift that
day loses `affection.neglect.loss` with odds `neglect.chance` (`Affection.day_end`, from
`Game.end_day`). The text box shows the band as a heart after the speaker's name on the name
tag whenever a villager speaks (`Game.heart_band`, colours `hearts` in `data/text_box.json`,
`ui:heart:<band>` in PlaceholderArt). Heart events: a `talk` row with `hearts`
`{"<id>": [3, 6]}` in `triggers_town.json` (and the keepers' shop tables and the house
maps' tables) plays `data/events/heart_<id>.json` once (lines in
`data/dialogue/heart_events.json`; each sets the flag `heart_<id>`). The second one, a row
right after it with `{"<id>": [5, 6]}` and `seen: ["heart_<id>"]`, plays
`data/events/heart_<id>_5.json` (lines in `data/dialogue/heart_events_5.json`; flag
`heart_<id>_5`, plus `tome_grandma`, `sayo_sign` old / new or `hachiro_bell` from the scene).
The third, a row after that with `{"<id>": [6, 6]}` and `seen: ["heart_<id>_5"]`, plays
`data/events/heart_<id>_6.json` (lines in `data/dialogue/heart_events_6.json`, each with a
line of its own when the band 5 flag is set (Fumi's when her band 3 `fumi_honest` is); flag `heart_<id>_6`, plus `kota_streamer`,
`sayo_ledger`, `hachiro_strike`, `fumi_kettle`, `ichiro_mark`, `genzo_straw` or `haru_wave`); after it, the talk files' `dear_` lines (band 6 and the
flag) come before the band 4 .. 6 ones. Haru has all three (her band 5 answer sets `haru_stay` or `haru_go`, which her band 6 scene looks back on; her tables:
`triggers_kaminoda`, `triggers_hill`, `triggers_haru_house`, `triggers_town`; after band 5
her `sandals_` lines, after band 6 her `dear_` lines). Shige has the first two (`triggers_minamino`,
`triggers_shige_house`, `triggers_town`; after band 5 his `pumpkin_` lines). `-- --demo --hearts=N` starts everyone at the start of band N.

**Marriage** (`data/marriage.json`, `Marriage` in scripts/villagers/marriage.gd): courting ends
at the shrine. The candidates are Sayo and Fumi. The proposal item is the **mizuhiki knot**
(`keep:mizuhiki`, a keepsake, 1500 G at the general store, any season). Held overhead and
taken to a candidate (`Game.talk_to` → `Game.propose`) it is a proposal, not a gift: yes when
their band is 6, their band 6 scene (`heart_<id>_6`) was seen, the house's second room is
built (`built: "room"`) and the farmer isn't married or promised to someone else. Then the knot
is taken, the flags `engaged` = id, `engaged_<id>`, `wedding_day` (the day number,
`wedding_after_days` = 3 on, moved past festival days, `Game.festival_on_day`) are set and
`propose_<id>` plays. Otherwise they answer with `marriage.json`'s line `<id>_married`,
`_taken`, `_waiting`, `_band` or `_room` and the knot stays in hand; anyone else leaves it
in hand with a message. From the wedding day's morning (`Game.end_day` → `Marriage.day_start`)
the flag `wedding_due` is set (with a morning message and the HUD tag "Wedding day") until
`wedding_<id>` has played: a row in `triggers_town.json` from 10:00, on entering the village or
a minute later. The wedding stands the farmer before the shrine beside the bride, Tome in
front, the guests at the sides, sets `spouse` = id and `married_<id>` and clears the rest but
`wedding_day` (the village record's date, see Ending).
Married, the spouse's rules (`married_<id>` in their villager file) have them live at the
farmhouse (by the kotatsu in the second room, `house` [9, 3]) mornings and evenings and keep
their own work by day; their talk files have `engaged_`, `wed_morning_` / `wed_evening_` (at
home) and `wed_out_` lines, and Tome mentions the knot on Fridays once a candidate's band 6
scene is seen. Each morning the spouse helps on the farm (`help` in `marriage.json`,
`Marriage.help` from `Game.end_day` after the night): on a sunny day up to `water` (6) dry
plots with an unripe crop are watered, row by row from the field's top-left, and the coop's
feed box gets up to `feed` (3) portions from the farmer's own feed stock when it is short. The
farmer hears it on stepping out of the house (`help.messages`, with the spouse's name; joined
with the builder's news). The chore is also the spouse's talk that morning: flags `help_water` /
`help_feed` (cleared each night) pick the `help_water_` / `help_feed_` lines in their talk file,
but only before noon (`"time": ["00:00", "12:00"]` in the pick row); after noon the talk gives
the married lines.
The village record names the spouse under the title (Ending).
All of it is story flags, so it is saved with them. The view:
`-- --demo --map=town@shrine --time=10:00 --event=wedding_sayo`; married at home:
`-- --demo --map=house --built=room --flags=married_sayo,spouse=sayo --time=19:00`.
A villager stands `talk_turn_minutes` after a talk, and one walking into the farmer waits
(`bump_reach`); that time is their delay, the whole plan runs later, at most `delay_max`
minutes, cleared at 12:00 and 18:00. The farmer can't step within `block_reach` of anyone.
`-- --demo --map=town --time=14:30 --talk=tome` puts the farmer below Tome and talks.
Whistling (`data/whistles.json`, `Whistles`): once a game minute each villager walking their
plan on the farmer's map may start their own short tune (`tunes`, a few notes in a five-note
scale, played by MusicSynth on a near-pure flute voice) with odds `rules.chance`, at least
`gap_minutes` after the last one, only on a fair day (`looks`), by day (`hours`) and outdoors
(`places`, the map's `ambient`); not while acting in an event or turned to talk. The roll is a
hash of the villager, day and minute, so a day plays the same. `Sfx` plays the tune on the SFX
bus at `volume_db`, full within `hear_full` cells of the farmer and fading to nothing at
`hear_reach`; both views draw a rising note (`fx:note` / `fx:notes`) over the whistler while it
lasts. `-- --demo --map=town --time=10:00 --whistle` (or `--whistle=<id>`) has every walker
whistle at once.

## Shops
Shops live in `data/shops.json` (the Yorozu Store, the Kurogane Smithy, Dr. Yae's Hinata
Clinic, which sells only the herb tonic, and Fumi's Hanami Teahouse in Sakurazaka: tea, whipped
matcha and a sweet of the season, the matcha and the sweets sold nowhere else): per shop a `name`, its inside `map`, `open` [first hour,
closing hour), `days_off`, `keeper` (the villager at the counter: Sayo at the store, Hachiro
at the smithy; the counter sells only while their plan has them on the shop's map), `stock` per
season plus `any` (`{item, price?}`; without a price a seed bag costs its crop's `seed_price`,
a food its `price`), `buys` (kind -> percent: `crop` of its sell price, `food` of its price, `stone` / `ore` /
`gem` of a mine find's sell price) and `upgrades` (`tools` and per target level
`{price, days, items?}`; `items` = id -> how many, taken from the rucksack). The rules are `Shop`
(`scripts/shops/shop.gd`, pure logic on an Inventory and a money amount); Game wraps them
(`open_shop`, `shop_buy`, `shop_sell`, `shop_upgrade`, `shop_collect`) and saves
`shop_jobs` (a tool left at the smithy: tool, new level, ready day, its old slot).
`ShopMenu` (tabs, rows, cursor, count) and `ShopScreen` (paper / wood) are the screen.

The store also sells `supplies` (every season, listed first): a stock entry's `to` sends it
to the animal's home (`"animal"`: `animal:<kind>` through `Game.add_animal`,
`animal:<kind>:young` for a calf / lamb, refused with `full` when the home has no room; a kind
the game doesn't know has none), the coop's feed sack (`"feed"`) or the barn's loft
(`"fodder"`), and `name` names it. `rucksack.levels` are bigger bags (`slots`, `price`), bought once each in
order (the bag's size is the level, so nothing extra is saved). `builds.jobs` are house
extensions built by `builds.builder`: ordered and paid at the counter (Build tab), one at a
time, finished overnight on the ready day (`Game.end_day`), saved as `house` {built, job}.
What they change is data too: `chest_slots` grows the storage chest, and the map file's
`extensions` (data/maps/house.json) add props or replace `size` / `ground`
(`MapManager.set_built`, `with_extensions`). A prop with `use: "storage"` opens the chest.
From the morning after the order until it is done the story flag `house_work`
(`Game.BUILD_FLAG`, kept in step by `Game.sync_build_flag`) holds the job's id: the builder's
day plan follows it (Hachiro's `building` plan: on the farm hammering at the farmhouse wall
08:20-17:00, any weather but a storm), so does a talk pick (`build_1`..`3`) and the farm
map's `lumber` prop (left of the house front). His own counter then says `builds.away`
(`Game.keeper_away_text`). `-- --demo --building=kitchen --time=10:00` shows it.
The smithy's `upgrades.tool_levels` gives one tool its own price list (the rod, whose levels
are `rod.bite_factor` in data/fish.json: the bite chance per check is multiplied by it).

A map prop with `use: "shop"` and `shop: "<id>"` is a counter: E on it calls
`Game.open_shop(id)`, which says the closed message (or the shop's `away` note, by default
"Nobody is at the counter", while the keeper is out) or emits `shop_requested(id)`. Talking to the keeper calls the same function
(Villagers); each shop map has a `keeper` spawn
behind the counter and a `counter` spawn in front of it (`-- --demo --shop=<id>` starts there
with the screen open, hours ignored). The smithy takes the tool out of its slot; once the
days have passed (`Game.day_number()`), picking it up puts it back and calls
`Game.raise_tool_level()`.

## Mine
The village road's east end leads to the mine entrance (`data/maps/mine.json`); its cave mouth
goes down to `mine_floor`, one cave map that every floor is laid out on. `MineFloor`
(`scripts/mine/mine_floor.gd`, pure rules) makes a floor fresh on every entry from a seed,
the depth and the season: rocks and big rocks (hammer, hits per floor band), soft spots (hoe)
and one hole down hidden under one of them; what each hides is rolled when the floor is made.
Bands, counts, finds per source (weights, `none` = nothing), season factors and the mine
items (`mine:<id>`: name, kind stone / ore / gem, sell, icon look) are in `data/mine.json`.
`Game.go_to_map` makes the floor (`Game.maps.mine_floor`: its rocks are solid, its open hole
is a door to the next floor); `Game.mine_swing` costs stamina and fatigue like field work and
puts finds in the rucksack, else overhead, else on the ground (E picks them up). The ladder
goes straight back up. Only `mine.deepest` and `mine.landings` are saved; a save made down the
mine loads at the cave mouth. The views add a `MineLayer` (3D) / `MineView` (2D). Ores are rucksack items: the
Kurogane Smithy asks for them on its upgrade levels (akagane for level 2, then shirogane,
kogane and hoshigane for 5, some iron sand on the way; the rod has its own), taken from the
rucksack when the tool is handed in; its Tools tab says "Still needs ..." until they are
there. The smithy buys stones and ores, the store gems, a bit above the bin's price.
Light: `light.depths` in data/mine.json are [floor, colour] blended in between, so each
floor is darker than the one above; `MineLight` (`scripts/mine/mine_light.gd`) is a multiply
shader over the picture in both views with the farmer's lantern (`light.lantern`: radius in
cells, soft edge, colour): a warm pool round them that fades out through a 4 x 4 dither, its
rim amber, flickering on one clock in both views; the farmer carries the lantern (`mine:lantern`,
hung on the frame at `PlaceholderArt.lantern_at`). On a frozen floor a few pixels of the dark
glint pale blue. Winter: `winter` freezes floors 1 to `to`
in its seasons: a colder light, frost on part of the floor (only a look) and blocks of ice
(`kind: "ice"` in `MineFloor.rocks`, `hits` blows) hiding frost stone or rock crystal, never
the hole; deeper floors stay warm. `-- --season=winter` starts on day 1 of winter (e.g.
`-- --demo --season=winter --mine=3`).
Landings: every trip used to start at floor 1, so `landings` in data/mine.json makes floors 5,
10 and 15 landings. Each has a rope lift's cage by the ladder (`MineFloor.landing` / `lift`, solid,
inside the ladder's safe square so the layout is unchanged; `mine:landing` in both views).
Reaching one keeps it (`Game.mine_landings`, saved as `mine.landings` since save version 6;
older saves get every landing down to their deepest floor, since every trip then began at floor 1)
and sets the story flag `mine_lift`, which shows the winch beside the cave mouth (`rope_lift`, a
story prop, `story:rope_lift`). From then on the cave mouth asks in a text box (built in code:
`Game.ask_mine_lift`, `dialogue_made`): the ladder to floor 1 or the lift to a landing reached (the
deepest three). `Game.mine_go_down(depth)` refuses a landing not reached, so `mine_deepest`, the
ending's mine measure, still only counts floors walked to. `-- --demo --map=mine@cave
--landings=5,10 --lift` opens the choice; `-- --demo --mine=10` stands by a landing's lift.
Map files may say `sheltered: true` (no weather; buildings
are sheltered by default) apart from `indoor` (the clock stops).

## Forage
Wild things grow on fixed spots (`data/forage.json`): per map id a list of `{cell, spring?,
summer?, fall?, winter?}`, each season naming an item of `items` (`wild:<id>`: `name`, `sell`
in the bin, `look` for the placeholder icon) or nothing. The bamboo hill has fifteen spots:
bamboo shoots, bracken and butterbur buds in spring, wild raspberries and myoga in summer,
chestnuts, akebi and mushrooms (one matsutake spot) in fall, a few wild enoki in winter. The
village's three outer parts have smaller rounds with things of their own: Kaminoda (nine spots:
water dropwort by the paddies, horsetail, bamboo shoots, yam bulbils), Sakurazaka (ten: sansho
pepper and nameko in the woods, bracken, bamboo shoots, chestnuts) and Minamino (nine: wild
garlic, mulberries, ginkgo nuts by the water shrine, yam bulbils). E
facing a spot picks it: overhead with free hands, into the rucksack while the hands are full.
A picked spot is bare until the next morning (`Game.forage_picked`, map id -> cells, saved,
cleared in `end_day`). Wild things ship like crops, a few are eaten raw (foods.json `raw`),
some villagers like them as gifts and they cook (README → Cooking: wild greens and mushrooms
are recipe groups, three lessons and three cards). The rules are `Forage` (`scripts/items/forage.gd`); Game
has `forage_here()` / `forage_pick(c)`; `ForageLayer` (3D) and `ForageView` (flat) draw what
grows and redraw on `Game.forage_changed`. A new area's spots are one more list in the file.

## Goals
Tome's first-week list (`data/goals.json`) gives a new farm small goals with a reward each:
plant 9 plots (+150 G), say hello to 3 people (3 rice balls), pick 4 wild plants (cucumber
seeds), catch a fish (+120 G), ship 5 crops (2 bags of seed potatoes), earn 1000 G from the
cart (a chick in the coop, or 700 G if the coop is full). Tome hands it over in the opening.
Each goal is `{id, text, stat, count, reward, say}`; the stats are counted by
`Game.goal_stats()` (`planted`, `talked`, `fish`, `crops_shipped` from the run's own state,
`forage` and `earned` counted in `Goals.counts`). Every goal counts from the first morning;
the HUD shows the first one not done under the clock ("Goal Plant 9 plots 4/9", in the festival
tag's place on a plain day) and hides once the list is done. A goal reached is paid at once
(`Game.check_goals`, a few times a second while a view listens and nothing holds the screen),
the message line says what it gave, and its note (`data/dialogue/goals.json`, the farmer ticks
the line and reads the thank-you a villager wrote under it) opens in the text box. Rewards:
`money`, `items` (into the rucksack, else the chest), `animal` (`young` for a chick). Saved as
`goals: {done, counts}`; a save from before the list has all of it done. Plain `--demo` runs
turn the list off; `-- --demo --goals` turns it on (`--goals=plant,hello` marks those done).
The texts (goal names, the HUD and message templates in `messages`) are all in the data file.

## Cooking
The kitchen corner (house extension `kitchen`, ordered at the store) puts a stove (kamado) and a
cupboard (mizuya) in the farmhouse; both are props with `use: cook`, and E at either calls
`Game.open_cooking()`, which emits `cooking_requested` for the `CookingScreen` (both views).
Recipes are `data/recipes.json`: a recipe's id is the dish it makes, a food in
`data/foods.json` (so a dish eats, cycles in the food slot and shows its icon like any food),
`needs` are `{item, n}` or `{group, n}` (groups: a list of items used up in order, or a
`prefix` such as `fish:`), `makes` how many. `Cooking` (`scripts/cooking/cooking.gd`, pure
rules) takes the needs out of the rucksack, the hand and then the storage chest and puts the
dishes in the rucksack, all or nothing (tried on a copy first). The pantry (cooked rice, miso,
soy) is never counted; the rice crop is a real ingredient. A recipe is known from the start
(`start: true`), by a recipe card (`card: <item>`, a crop or a wild thing: the first shipped, by the bin
or thrown in, sets the flags of its cards, `Cooking.cards`) or once the flag
`recipe_<id>` is set; lessons are events (`data/events/recipe_<who>.json`, lines in
`data/dialogue/recipe_lessons.json`) played by `talk` rows with `hearts` and `not_flags` in
the trigger tables (Tome and Kota in the village, Sayo at the store, Hachiro at the smithy;
Haru and Genzo in Kaminoda, Haru on the hill too, Kiku in Minamino, and each in their house,
once known to band 1) and an `examine` row on the farmhouse radio on Saturdays. Flags are saved, so the save format
did not change. Raw farm goods are edible too: `data/foods.json` `raw` (crops, eggs, milk,
`fish:*`), through `Game.eat_item(item, places)`. Wild things cook too: the groups `sansai`
(wild greens, cheapest first) and `kinoko` (mushrooms, the matsutake last) and six recipes
(sansai tempura from Haru, kinoko jiru from Genzo, kusa mochi from Kiku; takenoko gohan, kuri
gohan and dobin mushi by the cards of the first bamboo shoot, chestnuts and matsutake). `-- --demo --cook` stands at the stove with
the screen open (the kitchen built, a few ingredients, one recipe learned, the knife but not
the pot it also needs, so its row says "no tool").
Kitchen tools: `tools` in recipes.json (knife, clay pot, teapot, iron rice pot, bamboo steamer,
mochi mallet; name, price, about) and a recipe's `tools` list. A recipe cooks only with its
tools in `Game.kitchen_tools` (`Cooking.missing_tools`; `Game.cook` says which are missing,
the cooking screen marks the row "no tool" and its "Uses ..." line marks a missing tool
"(store)"). The four start recipes need none. The Yorozu Store sells each tool once, at the
top of the buy tab after the rucksack, once the kitchen is built (`kitchen_tools` in
shops.json, `Shop.kitchen_offers` / `buy_kitchen_tool`, item `kitchen:<id>`, icons
`ui:kitchen:<id>`); tools take no rucksack slot. Saved as `kitchen_tools` (save version 5); a
version 4 save with a kitchen gets the tools of the recipes it already knew.
Dishes ship: `sell` in foods.json is what one fetches in the bin (`Game.sell_price`). E at
the bin takes dishes only from the hand (the rucksack's are lunch); throwing one in works too.
The Yorozu Store buys the kitchen's dishes from the rucksack or the hand (`buys` kind `dish`,
80% of `sell`; not the foods it stocks itself), and a dish overhead is a gift like any item
(`food:<id>` in a villager's `gifts`; one of a stack in hand goes).
Rice (`holds_water` in crops.json) keeps its watered cell wet night after night, like a paddy,
until it is picked. `-- --demo --season=fall` (or `summer`) sows that season's crops in the
demo field: ripe daikon (fall), ripe rice (summer).

## Dialogue
Dialogue lives in `data/dialogue/<id>.json`, opened with `Game.talk(id)` (or `-- --dialogue=<id>`
/ `<id>@<line id>`). A file is `{"lines": [...]}`; each line is one of:
- a text line: `text` (our pixel font only, at most 4 rows in the box), optional `speaker`
  (a key of `data/dialogue/speakers.json`: the name tag; no speaker = narration), `mood`
  (neutral, happy, sad, surprised, angry: the villager's portrait; one the art lacks shows
  neutral) or the older `face` (calm, smile, worried, surprised = neutral, happy, sad,
  surprised), `id` (to jump to), `next` (a line id
  or `"end"`; without it the following line, and after the last line the dialogue ends),
  `set` (flags to set when the line shows) and `choices`: 1-4 of `{text, next, set}` (a line
  with choices has no `next`);
- a branch: `{"if": "<flag>", "then": "<line id>"}` jumps when the flag is set (true, a
  number other than 0, a word other than ""), else goes on to the following line.

Flags are `Game.flags` (true / false, whole numbers or words), saved with the game. Typing
speed and punctuation pauses are in `data/text_box.json`. `DialogueRunner` refuses a file
with anything wrong (unknown keys or speakers, jumps to nowhere, letters the font lacks, text
too long) and says why; `tests/test_dialogue.gd` loads every file in the folder (and wants
every mood in the data to be one of `DialogueRunner.MOODS`).

**Portraits**: a line whose speaker is a villager (data/villagers) shows their portrait in a
wooden frame left of the text, `portrait:<villager>:<mood>` in PlaceholderArt (their colours
from the villager's look, background and marks from speakers.json); narration, the farmer and
anyone else get no frame, and their text and name tag start at the box's left edge
(`TextBoxLayout.text_x` / `text_w` / `name_x`). Every line is checked to fit the narrower
width beside a portrait.

## Events
An event is a small script in `data/events/<id>.json`: `{"steps": [...]}`, played by
`Game.play_event(id)` (or `-- --event=<id>`), a trigger table, or nothing else. While it plays
`Game.event_running` holds the clock (it counts as `Game.paused()`), the farmer moves only as
the script says, and keys go only to the text box. Each step is one of:
- `{"do": "say", "dialogue": "<id>", "at": "<line id>"}`: opens a dialogue from
  `data/dialogue` and waits until the box closes (`at` is optional; a dialogue line with
  `"next": "end"` stops it, so one file can hold several parts of an event); an optional
  `"mood"` is the portrait mood of its lines that name none (`Game.talk(id, at, mood)`);
- `{"do": "wait", "seconds": 0.5}` (0 to 60); with `"walkers": true` it also lasts until
  every actor walking `meanwhile` has arrived;
- `{"do": "face", "dir": "up|down|left|right"}`, or `"dir": "<villager id>"` to turn to that
  actor;
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
- `{"do": "affection", "who": "<villager id>", "amount": n}` (negative lowers it);
- `{"do": "place", "at": [x, y], "dir": "left"}`: the farmer stands on that cell at once (best
  under a black fade; `dir` optional);
- `{"do": "actor", "who": "<villager id>", "at": [x, y], "face": "down", "to": [x, y]}`: a
  villager from `data/villagers` acts in the event: `at` puts them on that cell of the map the
  event plays on, `to` walks them there (across, then up or down, at the farmer's walking pace,
  turning the corner the other way round if it would be the farmer's cell; the event waits
  until they arrive), `face` turns them (after the walk); any of the three. `"at": "plan"`
  starts them where their day plan has them on this map as the event begins (so a scene a
  talk plays keeps the villager where the farmer found them); if their plan has them on another
  map they come in 4 cells beside the farmer (`EventRunner.COME_IN`, on the side away from them)
  and walk up to the farmer by themselves. `to` may also be `"farmer"` (the cell in front of the
  farmer) or `"plan"` (back where `"at": "plan"` put them), and `face` may be `"farmer"`.
  `{"do": "actor", "who": "...", "leave": true}` takes them off. While acting, a villager's day
  plan is set aside (`Villagers.actors`); when the event ends every actor is gone again. The
  heart events start with `{"do": "actor", "who": "<id>", "at": "plan", "face": "farmer"}` and
  end with `"to": "plan"` and `leave`. `"holds": "<item>"` gives the actor an item to carry
  overhead in both views (a crop, `fish:<id>`, `mine:<id>`, an egg, milk or wool; `""` puts
  it away). `"meanwhile": true` (with `to`) lets the walk go on while the next steps play, so
  several actors walk at once;
- `{"do": "ending"}`: grades the run and shows the village record (README → Ending); the
  event waits until it is closed; `"page": "year"` shows the yearly page instead;
- a branch: `{"if": "<flag>", "then": "<step id>"}` or `{"unless": ...}`.

Any step can have an `id` and a `next` (a step id or `"end"`). `EventRunner` refuses a file with
anything wrong and says why.

**Trigger tables**: `data/events/triggers_<map id>.json` holds `{"rows": [...]}`. The view's
`EventPlayer` asks the table of the map the farmer is on when something happens (`on`):
`enter` (the farmer arrives on the map, also at the start of a game), `day_start` (a new day,
or a loaded game), `minute` (each clock minute) and `step` (the farmer steps onto another
cell), `examine` (the farmer presses interact facing a spot; see below) and `talk` (E facing
villager `who`, a key every talk row needs; the event plays instead of their lines). Any row
may add `hearts`: `{"<villager>": [lowest, highest]}` heart bands (Villagers). The first row in table order whose conditions all hold plays its `event`; a row plays
once (`Game.events_seen`, saved) unless it says `"once": false`. Conditions, each optional:
`year` / `days` `[first, last]`, `season` / `weekday` (`mon` .. `sun`; spring 1 of year 1 is a
Monday) / `weather` (today's: sunny, rain, storm, snow) lists, `time` `["6:00", "9:00"]` (from,
until; the end is not included), `flags` / `not_flags` (set or not set), `seen` / `not_seen`
(event ids) and `area` `[x, y, width, height]` in cells (where the farmer stands). Under
`-- --demo` the tables are off. Map switching calls `EventPlayer.enter_map(id)` with the new
map's id.

**Examine**: a row with `"on": "examine"` needs a `spot`, the cell the farmer faces: `[x, y]`
or `[x, y, width, height]` (a spot is only for examine rows). On interact (E) `FarmActions`
asks the map's table first; when a row matches its event plays and the normal interact
(doors, bin, chest, futon, picking up) is skipped. An item held overhead on the farm is still
thrown. Give examine rows `"once": false`, and put the special cases (snow, evening) above the
plain row for the same spot. Examining works under `-- --demo` too, since only a key press
starts it. Spots now: the shrine's offering box and the stone lanterns in the village
(`triggers_town.json`; the house doors are left to the doors), the name plate by the farmhouse door and the
board by the gate (`triggers_farm.json`), the calendar and the radio in the farmhouse
(`triggers_house.json`).

## Festivals
`data/festivals.json` holds the village festivals, one per season and all our own: Blossom
Day (spring 8, cherry trees and picnic mats), Lantern Night (summer 20, lantern strings,
stalls, a drum stage and fireworks), Moon Night (fall 15, pampas grass and a dango offering at
the shrine) and Year's Turn (winter 30, New Year bamboo and a bonfire at the shrine). Each has
`name`, `season`, `day`, `hours` (from, until), `map`, `place` (the cell it gathers round),
`event`, `closes` (shop ids shut all day), `props` (`{kind, cell, size?, cloth?}`, never solid)
and optional `fireworks` (from, until). `Festivals` (scripts/festivals/festivals.gd, pure
logic) answers the date lookup, the hours, the shops and the props; `Game.festival_today()`
gives today's id, also as `festival` in `Game.trigger_state` (villager rules use it).

On the day the HUD shows the name under the clock (in red while it is on), the farmhouse
calendar notes the date, the shops it closes say so at their door and counter, and the
weather is fair (the roll for it is replaced the evening before, DESIGN). During the hours
the map shows its decorations: `FestivalProps` (3D, added to the map's world) and
`FestivalView` (2D boxes). `FestivalGlow`, in main_3d's tint layer, draws the lanterns' and
fire's glow over the night tint and the fireworks (screen-space bursts, a pure function of
time). The festival's event plays once a year (`events_seen` key `festival:<id>:<year>`) when
the farmer walks onto the map in the hours, or is there when they start (EventPlayer).
`-- --demo --festival=<id>` starts on that day half an hour in, at its place.

**Contests.** Each festival has a `contest`: the Blossom Crop Show (a crop; one that grows in
spring counts `in_season` 1.5 times), the Lantern Night Catch (a fish), the Moon Offering (an
egg, milk or wool) and the First Stone of the Year (an ore or stone from the mine). Its
`table` is a cell of a `judge_table` prop (white cloth, red and white curtain, a name board).
E there empty-handed: the judge says the `ask` line of `data/dialogue/contests.json`. E with
an entry of the right kind (`Game.item_kind`) overhead hands it in; it scores its shipping
value, the `rivals` (villagers) roll their scores from `[lowest, highest]` with a seed of
festival and year, the farmer wins ties (`Festivals.judge`). The prize for the place
(`prizes`, `{money, item?, count?}`) is paid at once, flags `contest_place_<n>`,
`contest_won_<rival>` and `contest_prize` are set (the result lines branch on them;
`contest_wins` counts first prizes) and the contest's `event` (`data/events/contest_*.json`)
plays: the rivals walk up together from their festival plans (`"at": "plan"`, `meanwhile`)
with their own entries overhead (`holds`), stand in front of the table beside the farmer
while the results are read, then walk back and go on with their plans. Each contest and game has
one of the outer parts' villagers among its rivals: Shige (crops, a potato), Genzo (fish, a
loach from his paddy), Haru (the Moon Offering, an egg from her hens), Ichiro (the First Stone,
amber from a pine's roots; and the mochi pounding) and Nana (the pond race). One entry a year (`events_seen` key `contest:<id>:<year>`). `-- --demo
--festival=<id> --contest=<item>` stands at the table with the item and enters it.

**The crowd.** All four villagers go to every festival by festival day plans (rules with
`festival` in `data/villagers/<id>.json`): Kota and Tome from the morning; Hachiro (the
smithy is shut) at the picnic mats, the drum stage, the shrine's gravel and the bonfire; Sayo
under the blossoms from 13:00 to 15:45 on Blossom Day (the store stays open, her counter has
`festival_away`'s note in `data/shops.json`), at the night food stall, by the moon table after
closing, and between the shrine and the bonfire at Year's Turn. In a festival's hours each
says a `festival_<id>` line (`data/dialogue/talk_<id>.json`). A house job under way keeps
Hachiro building. The people of the outer parts come too, by three plans each
(`festival_day` for Blossom Day, `festival_night` for Lantern and Moon Night, `festival_year`):
a holiday at home (Fumi pours tea at her counter until she goes; her note is the teahouse's
`festival_away`), then down their lane into the village (Kaminoda from the north, Sakurazaka
from the east, Minamino from the south) to a spot of their own by the stalls, the mats or the
shrine, and back home after the hours. Dr. Yae stays by the clinic.

**A played contest: the mochi pounding.** A festival may also have a `game`, a contest that is
played rather than judged. Year's Turn has the Mochi Pounding at a `mochi_usu` prop (a hooped
mortar with the dough, the mallet leaning on it and a pail, right of the shrine path at
[20, 4]). E there with empty hands starts it (`Game.start_game`): of the game's `partners`
(Tome, Kota) the villager the farmer is closest to turns the dough (Tome on a tie) and the
MochiScreen opens over either view: the farmer with the mallet on the left, the mortar in the
middle, the partner on the right, and a ring that closes on the dough for each strike. E
(Enter / Space, a click) as it meets the mark: within `windows.great` seconds of the beat is
great, within `windows.good` good, otherwise a miss (the partner's hands are in the bowl), and a
beat let pass is a miss too (`points` great 3, good 1, miss -1; never below 0). The `rounds`
(8, 10 and 12 strikes, a beat of 1.0, 0.8 and 0.65 s, `gap` seconds between, `lead` before the
first; 90 points at best) get faster; the dough goes from rice to a round mochi as strikes
land. The timing is `MochiPound` (pure logic); the sounds are `mochi_count` (the count-in and
each new round), `mochi_pound`, `mochi_miss` (the mallet on the rim) and `mochi_turn` (the
partner folding the dough). The score is ranked like a contest (`Festivals.judge_game`: the
game's own `rivals` rolled per year, the partner sitting out), the prize paid, the place,
winner and `contest_partner_<id>` flags set for `mochi_result` in `data/dialogue/contests.json`,
the best score kept in the flag `game_best_<game id>`, and `contest_mochi` plays. One go a
year (`events_seen` key `game:<festival>:<year>`); the First Stone contest stays open beside
it. Placing gives a ribbon keyed by the game's id (`ribbon:mochi:<place>`, "Mochi Pounding
ribbon"). `-- --demo --festival=years_turn --contest=mochi` stands at the mortar with the game
on; `--contest=mochi:auto` swings by itself for screenshots.

**A second played contest: the fishing race.** Moon Night's `game` is the Moon Pond Race
(kind `fishing`, `FishingRace`), at a `race_flag` prop (a bamboo pole with an indigo banner
and the race's creel) at [30, 13], just north-west of the village pond. E there with empty
hands and the rod in a tool slot starts it: the rod goes in hand, a `lead` of 3 seconds counts
in (`mochi_count` clicks, `chime_morning` for the start), and for `seconds` (60) the farmer
fishes the pond with the real rod and bite rules (`data/fish.json`; casts cost stamina as
always). A fish landed goes into the race's creel instead of overhead (it still counts as
caught; once-only fish like the moonlit koi don't bite in a race), and the creel is let go at
the end. The clock holds while the race runs, so all its bites come at the hour it started. A
small wood box under the message line in both views (`RaceScreen`) shows the time left, a bar
running down, the fish count and the last eight fish landed; "Time!" is called (the line comes
in empty), and after two seconds the count is ranked like the mochi score (`judge_game`, the
game's five rivals rolled per year, no partner), the prize paid, `fishing_result` lines in
`contests.json`, `contest_fishing` plays, the best count kept in `game_best_fishing`, and a
ribbon `ribbon:fishing:<place>` ("Moon Pond Race ribbon"). Walking off the map mid-race ends
it with the creel as it is. A race in progress is saved (`fishing.race`: time and fish) and
goes on after loading. Balance: about 5 seconds a fish at dusk with the first rod, so a quick
player lands 9-11, a steady one 7-9; Hachiro rolls 6-11, Tome 4-9, Kota 3-8, Sayo 2-7.
`-- --demo --festival=moon_night --contest=fishing` stands below the flag facing the pond with
the race counting in; `--contest=fishing:auto` casts and reels by itself (about 20 s in is
mid-race, `--quit-after 690` with `--fixed-fps 30`).

**Stalls.** A festival may have a `stall` (`{id?, name, cell, stock}`; the cell is a `stall`
prop's), or a list of them, each with its own `id`. E at one in the hours opens it as a shop
with id `stall:<festival>` (or `stall:<festival>:<stall id>`): Blossom Day's Hanami Dango Stall
sells dango, sakura mochi and green tea; at Lantern Night the red Night Eats Stall sells
yakisoba, shaved ice and marble soda (foods with `shop` false and a price: only at a stall)
and the yellow Wind Chime Stall sells keepsakes, a wind chime and a paper fan (prices in the
stock rows); the blue and green stalls are only looks. At Moon Night the navy Moon Craft Stall
(`crafts`) sells a clay rabbit and a moon lantern, and the amber Chestnut Roaster (`eats`) roast
chestnuts and baked sweet potatoes; at Year's Turn the white Year-End Soba Stall (`soba`) sells
year-end soba and hot yuzu tea, and the red Lucky Charm Stall (`charms`) a daruma and an
omamori charm. A selling stall sets its stock out on the counter in both views.
`--shop=stall:<id>` (e.g. `stall:lantern_night:chimes`, `stall:moon_night:crafts`,
`stall:years_turn:charms`, with `--festival=<id>`) stands at it with the screen open.

**Keepsakes and ribbons** (`data/keepsakes.json`, `Keepsakes`). Keepsakes (`keep:<id>`) and
ribbons (`ribbon:<festival>:<place>`, or `ribbon:<game id>:<place>`) sit in the rucksack and are never eaten, shipped or sold.
Placing 1st, 2nd or 3rd in a contest gives a ribbon of that place (red, white, blue, like the
rosettes on the judges' table) on top of the prize, and notes it in the story flag `ribbons`
(`<festival>:<place>:<year>`, comma between; saved with the flags), even when the rucksack is
full. While that flag is set, a ribbon board hangs on the farmhouse's back wall (house map prop
`ribbon_board`, a story prop in both views) with one rosette per ribbon (the last 12); E on it
counts them. `--map=house --flags=ribbons=blossom_day:1:1` shows it.
A keepsake held overhead is a gift like any item: each villager loves one (Kota the clay
rabbit, Tome the omamori, Sayo the wind chime, Hachiro the daruma) and the lists in
`data/villagers/*.json` name the others they like or dislike; a ribbon is neutral to everyone.
Giving a villager the keepsake they love sets the story flag `kept_<villager>_<keepsake id>`
(`Keepsakes.given_flag`), and from then on it is on show in their home: a `keepsake` story prop
(`item`: the keepsake, drawn from its icon; on a little stand, or hung with `hang`) gated by
that flag in `data/maps/tome_house.json`, `kota_house.json`, `sayo_house.json` and
`smithy.json`. `--map=tome_house --flags=kept_tome_omamori` (or `--map=sayo_house
--flags=kept_sayo_wind_chime`) shows it.

**Music and payout.** A music rule with `festivals: [ids]` fits only while one of them is on
around the farmer (`Game.festival_now()`), so each festival plays its own score (`fest_*` in
`data/music.json`, with a taiko and a small kane bell), over night and season. On a festival
day the shipping bin is not paid (DESIGN): neither at 18:00 nor overnight; it is paid with
the next day's shipping (`Game.payout_held()`).

## Ending
On the first morning the farmer wakes in the farmhouse in year 3 or later (a `day_start` row
in `data/events/triggers_house.json`, once), Tome comes in with the village record
(`data/events/ending.json`, lines in `data/dialogue/ending.json`). Its `ending` step calls
`Game.show_ending()`: `Game.ending_values()` measures the run (shipped value at today's prices,
crop kinds shipped, happy animals, heart bands, neighbours known (the villagers without hearts,
the outer parts' people but Fumi, Ichiro, Genzo, Haru and Shige, and Dr. Yae, whose hidden affection from talks and gifts reached
`neighbour_band`), the deepest mine floor, fish kinds, house
extensions, tool levels, contests won, recipes known) and `Ending.grade` turns it into stars
per category, a rank and a title from `data/ending.json`; the EndingScreen shows it. A married
farmer's record has one line under the title, "Married Sayo on Spring 14" (`Ending.spouse_line`,
the texts in `data/ending.json` `spouse`; the wedding day is `wedding_day`, kept after the
wedding; "Married to Sayo" when that day is not known; nothing when single). The flags
`ending_rank_<n>` and `ending_friend_<id>` pick Tome's verdict and who comes in to close it
(the villager liked most, from heart band 3; else Tome). The game goes on afterwards
(`ending_seen`). DESIGN lists the ending as not studied, so every rule is ours. `-- --ending`
opens the record at the start; `--map=house --event=ending` plays the scene.

Every other New Year has a shorter yearly page: when the year turns, `Game.end_day` sets the
flag `record_due`, and on the first morning the farmer wakes in the farmhouse Tome brings the
page (`data/events/year_record.json`, lines in `data/dialogue/year_record.json`; a row after
the ending's in `triggers_house.json`, so year 3 gets the full record instead). Its step is
`{"do": "ending", "page": "year"}`: graded the same way, no visitor and no verdict;
`record_first` (year 2, the first page) or `record_more` (more stars than the last page) pick
Tome's words. Each page is kept in the save (`Game.year_pages`: year -> {values, field,
stars, rank}). The look back: a new game keeps its first day (`Game.first_day`: the record's
numbers and `Game.field_counts()`, i.e. weeds, rocks, branches and stumps, tilled cells and
money), and the record screen shows for every row the first day, now and (with an earlier
page) the gain since it; the field rows (`field` in `data/ending.json`) follow the categories
without stars. Saves from before the pages load with no page and the start's numbers as the
first day (the field's debris and tilling show "-"). `-- --ending=year` opens the yearly page
at the start; `--map=house --event=year_record` plays its scene. The screen is a paper scroll
(`EndingScreen`, art `ui:scroll:*` in `PlaceholderArt`): wooden rollers top and bottom, washi
between them; it unrolls in half a second, then the rows come up; stars are ink stamps and a
red seal sits after the title. Enter shows it all at once.

## Camera
`scripts/main_3d.gd` was built on the field camera geometry of Harvest Moon: Back to Nature, measured
in the reverse-engineering project: yaw 45°, pitch 26.6°, the player 25.2 cells from the eye,
vertical FOV 13.7° (a long, narrow lens, so the view looks nearly isometric). The camera
follows the player with no lag and stops a few cells inside the fence (or the map edge;
a room smaller than that stays centred). Inside, the same camera looks in from the front
corner, so the front walls are drawn as low sills (a cutaway) instead of moving the camera.
Outdoors, the land goes on past the map's edge (`scripts/world3d/surroundings.gd`): an apron
of ground whose cells repeat the nearest edge cell (roads, the river and paddies run on out of
sight), with a pine wood only where it stands behind the whole map on screen (the north and
west sides; `Trees.pine` in MultiMeshes, snow on its tiers in winter), so the view never shows
empty sky. Every tree is built by `scripts/world3d/trees.gd` (Trees: lumpy lit crowns that
follow the season, tiered pines). Grass tufts sway on the grass cells, the farm's untilled ground and the
apron (`scripts/world3d/grass_tufts.gd`: one MultiMesh each, tips by season, gone under snow).
Rice and corn grown past the sprout stand as clusters of small pixel sprites instead of one
sprite a cell (`scripts/world3d/crop_clusters.gd`: nine rice hills in three rows, six smaller
ones in two rows while young, three corn stalks; one MultiMesh of camera-facing quads per
picture `stalk:<id>:<growth>:<ripe|growing>:<variant>`, the tips swaying); the flat view keeps
the one sprite. The village paddies (Kaminoda) grow rice by the season: young in spring, tall
and green in summer, ripe in fall, none in winter. Tall things in front of the farmer (houses,
the coop and barn, trees, the torii: anything over 1 unit high) turn see-through while they
hide the farmer or the ground within about a cell of them (`scripts/world3d/occluders.gd`:
rays from the feet towards the camera; the materials' alpha, since the Compatibility renderer
draws nothing for `GeometryInstance3D.transparency`).
That camera is the "ps1" lens in `data/camera.json` (`scripts/world3d/camera_lens.gd`). Since
2026-11-03 the game uses our own "medium" lens instead (fov 28°, pitch 30°, the user's pick for
an HD-2D lite look: a little depth, near things larger, far things smaller); "wide" (fov 40°,
pitch 36°) is kept to try. Each lens stands the eye back so the picture at the farmer's feet is
the same height. `"use"` picks the game's lens; `-- --lens=<id>` tries another for one run.

## Farmhouse model
The farmhouse's roof is a real mesh, not boxes: `scripts/world3d/minka.gd` builds a thick
thatched hip roof (kayabuki) with SurfaceTool — the slopes, the trimmed eave edge, the soffit
and a snow layer — with UVs in world units (u along the eave, v down the slope, textures
`build:kaya` / `build:kaya_edge`), and a dark ridge with crossed riders. It is the sample that
sets the bar for the scenery. `tools/house_model.gd` shows the house on its own from four sides
(`--script res://tools/house_model.gd -- --shots=shots`, with a window) and writes it as a .glb
(`--headless ... -- --glb=models/farmhouse.glb`; `models/` has a `.gdignore`) to open in Blender.
The game builds the house from code; the .glb is a copy to look at or start real art from.
The coop and barn have gable roofs from the same file (`Minka.gable`: two slopes, the eave
bands, the verges at the gable ends, the soffit, snow; with `rolls` the slopes carry raised
round-tile rolls, used for the barn's kawara with the tile ends in `build:kawara_edge`), and
`Minka.gable_wall` fills the gable ends. The village houses use the kawara gable too, and
`Minka.ridge` lays a ridge-tile stack that curls up at both ends to an onigawara (village houses
and the barn). Add `--what=coop`, `--what=barn` or `--what=village` (a shop like Sayo's) to the
tool to see them (`shots/<what>_<view>.png`). The shrine pieces are meshes too
(`scripts/world3d/shrine.gd`: the torii's curved kasagi, the hokora, the six-sided stone
lanterns turned by `Shrine.lathe`); `--what=shrine` shows the town's shrine. The shipping bin,
storage chest and seed stand by the farmhouse are `scripts/world3d/farm_props.gd` (FarmProps:
`FarmProps.block` makes tapered blocks for splayed sides and bevelled lids, the stand has a
`Minka.gable` board roof and turned seed sacks); `--what=props` shows them from close by. In the
game, `--demo --map=farm@bin` stands the farmer in front of them.

## Light
The 3D view has a warm sun from the upper left of the screen over a cool sky light
(`scripts/main_3d.gd` SUN_* / SKY_*), so the walls turned down-left are sunlit and shade is a
little blue. Outdoors the sun casts shadows; the ground is lit only to take them (flat light,
`SnowLayer.SUN_SHARE`, measured so sunlit ground keeps its picture's colours and shade drops
to about two thirds). Shadows fade with the daylight (dusk, night) and are gone under cloud
(`data/weather_fx.json` "sun", `Game.sun_shadow()`); rooms and mine floors have none. A soft
glow lifts the brightest things (snow, lights). Sprites stay unshaded, with their own blob
shadows. Day / night itself is still the multiply tint over the picture: `data/light.json`
"sky" lists its colour through the day (`Game.light_color()`, `Game.sky_at`), plain white
7:00..16:00, a warm 17:30, a mauve dusk at 18:30 and a deep blue night (46529a) from 20:30 to
4:30, dawn back through mauve and peach to 7:00. Both views use it.

The clear colour behind the land follows the clock outdoors as well (data/light.json
"background": keys [minute, colour] blended like the sky; `Game.sky_color()`, `Game.sky_view()`).
Dawn peach and purple, the day blue 8fc6e8 from 10:00 to 16:00 (the colour the view had before),
a golden 17:30, mauve at dusk, a deep blue night. Under cloud it is greyed by "cloud_grey"
(scaled by 1 - the weather's "sun" value) and then takes the weather tint, so rain and storms are
greyer and darker. `Game.sky_background(inside, map_background)` gives a room or a mine floor its
own background from its map data, as before. `Main3D._update_tint` sets the view's clear colour
each game minute. The land covers most views, so the sky shows only where no land is drawn.

Outdoors the sun itself follows the clock (`data/light.json` "sun", `Game.sun_light()`, applied
by `Main3D._aim_sun` each game minute): it rises low and orange from the lower left of the
screen at 5:30 (long shadows up the screen to the right), climbs golden through the morning,
stands high (60°) and plain at noon, and sinks golden to the upper left (long shadows down the
screen to the right) until 18:30. Once the dusk tint has put its shadows out it eases back to
the plain fixed sun (48° from the left, SUN_COLOR) by 20:30, and leaves it again from 4:00, so
the night looks as before. Its energy stays SUN_ENERGY so the ground keeps its measured
`SUN_SHARE` brightness; only the colour and the angle change. Under cloud (weather_fx.json
"sun" 0) the colour stays plain. Rooms and mine floors keep the plain sun. The flat view has no
sun.

At dusk and night the farmhouse's and the village houses' windows and shoji doors light up
warm (a shop's door under its noren stays dark): `NightLights` (scripts/world3d/night_lights.gd,
in the tint's layer after the tint) adds each window's paper picture in warm light and a soft
glow over the night blue, as bright as `Game.window_light()` (data/light.json "windows": with
the dark between `dark_from` and `dark_full`, only in the lit `hours`, so they go out at 0:30
and come on again before dawn). The houses list their windows in `FarmWorld.windows` (built
with `_lit_picture`); a window turned from the camera or behind a solid building stays dark,
one behind a building faded see-through shines through as much as it is faded. The flat view
has no windows to light (its houses are flat blocks), only the darker night.

Light also falls on the ground: NightLights first adds a soft warm pool (its edge in dithered
steps, like the mine lantern) in front of every lit window and door and round the foot of
every stone lantern (`FarmWorld.lamps`, from `Shrine.stone_lantern`, whose fire box also
glows), on the same schedule as the windows (data/light.json "pools": colour, strength, size).
Then a BackBufferCopy keeps the picture, the panes and glows are added, and last the figures
(sprites marked with `NightLights.figure`: the farmer, villagers, animals) standing in front
of a glow are drawn back from the copy, so a window behind someone never tints them. Someone
standing in a pool keeps its light (the pools are under the copy).

A festival's lights light the ground too while it is on, as strong as FestivalGlow shows them
(`FestivalGlow.darkness`): `NightLights.festival_pools` (data/light.json "pools" → "festival")
gives a round pool under a standing lantern, the drum stage and the bonfire, a fainter one
under each string lantern, and a pool in front of each stall's counter for its lantern
(`FestivalProps.glows` carry the kind: round, line, stall). NightLights draws them in 3D and
the flat view's NightView under its decorations, from the same lights.

Real lights as well: `NightLamps` (scripts/world3d/night_lamps.gd, made by main_3d) keeps a few
OmniLight3Ds without shadows (data/light.json "lamps" → max, 8) at the lit windows (a little in
front of the pane), by the stone lanterns' fire boxes and at the festival lights, the ones
nearest the middle of the view, the farthest fading out before it is dropped so none pops. So
the lit meshes near them (the engawa, posts and lower walls, eaves, the stone lanterns, trees,
the stalls' counters, the chest and bin) take warm light. They burn with `Game.window_light()`
(festival lights with `FestivalGlow.darkness`) and are all off by day, so the daytime picture is
unchanged. The tint multiplies the picture afterwards, so each light's colour is the wanted
colour divided by the tint (as NightView's shader divides it out; at most `boost` times). The
ground, the water and the grass sit on `NightLamps.GROUND_LAYER`, outside the lights' cull
mask: their light is the drawn pools, and they cost no extra pass. Pale plaster is already near
white under the night sun before the tint, so it takes little of the lamps; dark wood shows them
best. The night blue itself is a touch lighter since the lamps came (46529a, was 404c8e). Unshaded
pieces (sprites, the festival decorations' flat colours) do not take the lamps.

## Showcase
Fixed views for trailer shots and for comparing a look before and after a change:
`data/showcase.json` lists 12 named views, each the command-line args of one run (the same
flags as AGENTS.md → Screenshot). The runner renders each with `--write-movie` (30 frames at
30 fps, `--quit-after 30`) and keeps the last frame.

- Render all: `python -I tools/showcase.py --out shots/showcase` (from the project folder;
  the Godot console binary is read from the project folder, or pass `--godot <exe>`).
- Some views: `--only farm_morning,rain` renders just those.
- Compare: take the "before" set first, change the look, then
  `python -I tools/showcase.py --out shots/after --compare shots/showcase`. It writes
  `shots/after/compare/<name>.png` (before | after side by side) and prints the mean absolute
  pixel difference per view (0 to 255 per channel).
- Add a view: one more `{"name", "args"}` entry in data/showcase.json. Names are unique; the
  test `tests/test_showcase.gd` checks the names and that the maps, spawns, festivals and lenses
  it names exist.

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
- `scripts/shops/shop.gd` (pure logic), `scripts/ui/shop_menu.gd` + `shop_screen.gd`: shops.
- `scripts/player/player.gd`: movement and collision (the 3D view hides it and follows it).
- `scripts/art/placeholder_art.gd`: pixel sprites made in code until there is real art.
- `scripts/world3d/farmer_anim.gd`: picks the farmer's frame (pose, facing, mirror, timing).
- `scripts/dialogue/dialogue_runner.gd` + `scripts/ui/text_box.gd`: dialogue stepping (pure
  logic) and the text box that draws it.
- `scripts/events/event_runner.gd`, `event_triggers.gd` (pure logic) and `event_player.gd`
  (the view's side: triggers, moving the farmer, the fade): event scripts.
- `scripts/world3d/night_lights.gd`: lit house windows, lantern glows and their warm ground pools at night over the 3D view (README → Light).
- `scripts/world3d/night_lamps.gd`: a few real warm lights (OmniLight3D, no shadows) at lit windows, stone lanterns and festival lights at night in the 3D view (README → Light).
- `data/*.json`: crops and weather, tuned without touching code (`data/light.json`: the day /
  night sky and the lit windows); `data/dialogue/`: dialogue;
  `data/events/`: events and trigger tables.
- `scripts/autoload/sfx.gd` (Sfx): plays sounds by key and the music, SFX / Ambient / Music
  busses with `set_volume(bus, 0..1)` (set from the volume settings);
  `scripts/audio/ambient_picker.gd` picks the ambient loops, `music_picker.gd` the track.
- `scripts/animals/animals.gd` (Animals, pure logic: homes, products, the dog) +
  `coop_actions.gd` / `barn_actions.gd` / `dog_actions.gd` (the farmer's actions);
  `scripts/world3d/animal_layer.gd` / `scripts/world/animal_view.gd` draw the animals, eggs,
  feed and the dog (and step the dog); `coop_props.gd` / `barn_props.gd` the buildings and
  furniture.
- `tools/make_icon.gd`: draws the app icon; `export_presets.cfg`: the Windows build.
- `tools/balance.py` (`python -I tools/balance.py`): income and costs per season for a steady
  year-1 plan, read from the data files (the smithy's ores kept back from the bin, contest
  prizes from the odds against the rivals, each recipe's gain over its raw ingredients); run it
  before and after changing prices.

## Plan and handoff
- ROADMAP.md: milestones and "Next up".
- WORKLOG.md: what was done, how it was checked, what is left.
- AGENTS.md (and CLAUDE.md): rules and how-to for the next agent, including the clean-room rule.
