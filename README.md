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
village (`town`), the river south of it (`river`, its own fish table: place `river` in
`data/fish.json`; water at a map's side edge draws no bank, so the river flows on). A file has `id`, `size` [w, h], `indoor` (the clock stands still inside, as
DESIGN asks for every building), `ambient` (which `places` of the ambient rules in
`data/sfx.json` apply), optional `light` (a fixed room light instead of day / night) and
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
  `byobu`, `toy_box` and `mizugame`, their 3D looks in `scripts/world3d/home_props.gd`; a
  `village_house` prop's `side_door` (cells from the left) draws a second, plain door (Sayo's
  rooms behind the store);
- a prop with `flag` (a story flag name) only shows while that flag is set, or with
  `flag_value` too only while the flag has that value (MapManager.with_flags; a map is read
  again when one of its flags changes, and the views pick it up on the next map change). The
  band 5 and 6 heart events' story props use it (StoryProps, art `story:<kind>` in both
  views): `door_bell` on the farm (`hachiro_bell`), `store_sign` with `style` old / new in the
  village (`sayo_sign`), `ume_jar` in the farmhouse (`tome_grandma`) and `carp_streamer` on the
  farm (`kota_streamer`, band 6). A prop with `use: "examine"`
  plays its `sound` (data/sfx.json) and shows its `message` when used, on any map;
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
(`{"season": "fall", "day": 24}`, optional; the farmhouse calendar names it), then:
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
  _common.json; each blow knocks, Sfx `build_knock`), `{"face": "up"}`. The
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
  0..6), `again` (already talked today) and `birthday` (true on their birthday); the day picks
  one of the row's lines. Gift answers are the lines `gift_love` .. `gift_hate` and
  `gift_again`; an optional `gift_birthday` answers a gift that isn't disliked on their birthday.
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
line of its own when the band 5 flag is set; flag `heart_<id>_6`, plus `kota_streamer`,
`sayo_ledger` or `hachiro_strike`); after it, the talk files' `dear_` lines (band 6 and the
flag) come before the band 4 .. 6 ones. `-- --demo --hearts=N` starts everyone at the start of band N.
A villager stands `talk_turn_minutes` after a talk, and one walking into the farmer waits
(`bump_reach`); that time is their delay, the whole plan runs later, at most `delay_max`
minutes, cleared at 12:00 and 18:00. The farmer can't step within `block_reach` of anyone.
`-- --demo --map=town --time=14:30 --talk=tome` puts the farmer below Tome and talks.

## Shops
Shops live in `data/shops.json`: per shop a `name`, its inside `map`, `open` [first hour,
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
`Game.open_shop(id)`, which says the closed message (or "Nobody is at the counter" while the
keeper is out) or emits `shop_requested(id)`. Talking to the keeper calls the same function
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
goes straight back up. Only `mine.deepest` is saved; a save made down the mine loads at the
cave mouth. The views add a `MineLayer` (3D) / `MineView` (2D). Ores are rucksack items: the
Kurogane Smithy asks for them on its upgrade levels (akagane for level 2, then shirogane,
kogane and hoshigane for 5, some iron sand on the way; the rod has its own), taken from the
rucksack when the tool is handed in; its Tools tab says "Still needs ..." until they are
there. The smithy buys stones and ores, the store gems, a bit above the bin's price.
Light: `light.depths` in data/mine.json are [floor, colour] blended in between, so each
floor is darker than the one above; `MineLight` (`scripts/mine/mine_light.gd`) is a multiply
shader over the picture in both views with the farmer's lantern (`light.lantern`: radius in
cells, soft edge, colour) in four rings round them. Winter: `winter` freezes floors 1 to `to`
in its seasons: a colder light, frost on part of the floor (only a look) and blocks of ice
(`kind: "ice"` in `MineFloor.rocks`, `hits` blows) hiding frost stone or rock crystal, never
the hole; deeper floors stay warm. `-- --season=winter` starts on day 1 of winter (e.g.
`-- --demo --season=winter --mine=3`). Map files may say `sheltered: true` (no weather; buildings
are sheltered by default) apart from `indoor` (the clock stops).

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
(`start: true`), by a recipe card (`card: <crop>`: the first of that crop shipped, by the bin
or thrown in, sets the flags of its cards, `Cooking.cards`) or once the flag
`recipe_<id>` is set; lessons are events (`data/events/recipe_<who>.json`, lines in
`data/dialogue/recipe_lessons.json`) played by `talk` rows with `hearts` and `not_flags` in
the trigger tables (Tome and Kota in the village, Sayo at the store, Hachiro at the smithy)
and an `examine` row on the farmhouse radio on Saturdays. Flags are saved, so the save format
did not change. Raw farm goods are edible too: `data/foods.json` `raw` (crops, eggs, milk,
`fish:*`), through `Game.eat_item(item, places)`. `-- --demo --cook` stands at the stove with
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
  end with `"to": "plan"` and `leave`;
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
plays. One entry a year (`events_seen` key `contest:<id>:<year>`). `-- --demo
--festival=<id> --contest=<item>` stands at the table with the item and enters it.

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
ribbons (`ribbon:<festival>:<place>`) sit in the rucksack and are never eaten, shipped or sold.
Placing 1st, 2nd or 3rd in a contest gives a ribbon of that place (red, white, blue, like the
rosettes on the judges' table) on top of the prize, and notes it in the story flag `ribbons`
(`<festival>:<place>:<year>`, comma between; saved with the flags), even when the rucksack is
full. While that flag is set, a ribbon board hangs on the farmhouse's back wall (house map prop
`ribbon_board`, a story prop in both views) with one rosette per ribbon (the last 12); E on it
counts them. `--map=house --flags=ribbons=blossom_day:1:1` shows it.
A keepsake held overhead is a gift like any item: each villager loves one (Kota the clay
rabbit, Tome the omamori, Sayo the wind chime, Hachiro the daruma) and the lists in
`data/villagers/*.json` name the others they like or dislike; a ribbon is neutral to everyone.

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
crop kinds shipped, happy animals, heart bands, the deepest mine floor, fish kinds, house
extensions, tool levels, contests won, recipes known) and `Ending.grade` turns it into stars
per category, a rank and a title from `data/ending.json`; the EndingScreen shows it. The flags
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
at the start; `--map=house --event=year_record` plays its scene.

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
- `scripts/shops/shop.gd` (pure logic), `scripts/ui/shop_menu.gd` + `shop_screen.gd`: shops.
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
