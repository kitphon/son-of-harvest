# Harvest Son — work log

Newest first. Format per entry:

```
## YYYY-MM-DD — <title>
Agent: <agent / product> (<model>) · Commit: <hash or "this commit">
- Done: what changed.
- Checked: how it was verified (test output, screenshot, pixel values).
- Left / next: what is still open.
```

## 2026-10-31 — Chickens: the coop, feeding, happiness, egg grades, sickness, incubator
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: milestone 7 starts with chickens (DESIGN "สัตว์"; ideas only, our numbers and code).
  - Rules in the new pure-logic `Animals` (`scripts/animals/animals.gd`, `Game.animals`),
    every number in the new `data/animals.json`. A hen is {kind, name, happy, age, sick,
    sick_days, petted, out_hours}; happiness 0..100, new hens 30. Each night
    (`day_end`, from `Game.end_day`): a hen eats from the feed box or counts as fed after 4
    hours outside in good weather (+3 fed, +2 sun), unfed −8, petted +2, still out at night
    −10 (they come in by themselves), sick −3 a night. Adults that ate and aren't sick lay
    one egg into the nests (at most the coop's 6), graded by happiness: under 40 Egg (50 G),
    under 75 Good Egg (75 G), else Golden Yolk Egg (110 G). Happiness ≤ 5 gives a 35% chance
    of falling sick, a night without food 10% more; Animal Medicine (`medicine`) cures at
    once, otherwise she is well after 5 nights (no deaths: DESIGN's advice that risks stay
    recoverable). Each clock hour while out (`hour_passed`): +1 grazing hour in sunny
    weather, −3 happiness in bad weather. The hatch opens only on sunny days 6:00–17:59.
    Chicks (age 0) grow up after 7 nights; the incubator hatches a held egg in 3 nights and
    takes a coop place meanwhile. Names from a list in the data (Kome, Mochi, ...).
  - The coop: a farm building at x 13..17, y 1..3 (`FarmGrid.COOP`, door `COOP_DOOR` 15, 3;
    older saves get it on cleared ground through `add_missing_fixed`) and a map
    `data/maps/coop.json` (straw floor, earth by the door, indoor = clock stops): feed box
    along the back wall, three straw nests, incubator basket with a lantern, a tawara feed
    sack (40 portions on a new game), the hen hatch in the right wall. `CoopActions` (E):
    feed box tops up one portion a hen from the sack, the sack tells what's left, a nest
    puts the oldest egg overhead (the hand slot, so it ships by throwing it into the bin,
    and eggs in the rucksack ship at the bin too: `Game.sell_price` / `item_name` know animal
    goods), the incubator takes a held egg, the hatch lets the hens out / in, a hen (on her
    spot from the data) gets stroked, or the medicine when sick. The night's news ("Mochi
    looks sick", "A chick hatched") is told on the next walk into the coop.
  - Shop hook for the shops session: `Game.add_animal("chicken")` (false when the coop is
    full), `Game.animals.add_feed(n)`; `medicine` is an item nothing sells yet. A new game
    starts with two hens.
  - Views: `AnimalLayer` (3D) puts the hens near their spots (wandering, pecking, walking;
    sick ones sit fluffed up), eggs in the nests, an egg in the incubator and a grain mound a
    portion in the feed box; out on the farm the hens peck about the yard in front of the
    coop. `CoopProps` builds the thatched coop (cedar boards, kaya roof with ridge sticks,
    board door, bamboo-barred window, a hatch with a ramp) and the furniture. 2D: `AnimalView`
    draws hens and eggs, MapView colours for the new props.
  - Art in `placeholder_art.gd`: `animal:<chicken|chick>:<idle|peck|walk|sick>:<frame>`,
    eggs per grade (`item:egg*`, slot icons too), `ground:straw`, `build:thatch`. Sounds
    `hen_cluck` and `feed_pour` in `data/sfx.json`.
  - Save version 2 (`SaveGame.VERSION`; `_parse` passes the version to `Game.from_dict`):
    `animals` holds the flock, feed, eggs, incubator, hatch state; a version 2 save without
    it is refused, a version 1 save loads with the new-game flock and gets the coop.
  - Debug flags: `-- --demo --map=coop` (a chick, two eggs, a filled box with --demo),
    `--hens-out` (with `--map=farm@coop`).
- Checked: new `test_animals: OK (0 failed)` (data, start flock, capacity, grades, feed box,
  fed / unfed / petted / grazing / rain / night out, nest cap, sickness, cure, recovery,
  chicks growing, incubator, round trip and 8 broken saves, Game hook / prices / clock hour /
  night eggs / egg thrown into the bin / bag shipping, version 1 and 2 loads, coop actions
  through FarmActions with the real autoload, coop map and spots, coop on an older farm,
  art sizes). `test_audio`, `test_body`, `test_dialogue`, `test_events`, `test_farm`,
  `test_food`, `test_hold`, `test_inventory`, `test_maps`, `test_menu`, `test_save`,
  `test_title`, `test_weather` all `OK (0 failed)` (test_title's "newer version" case now
  uses `SaveGame.VERSION + 1`). Headless `--quit-after 300` (title, `-- --demo`,
  `--demo --map=town`, `--demo --map=coop`, `--demo --map=farm@coop`),
  `res://scenes/main.tscn --quit-after 400` and `res://scenes/main_2d.tscn -- --demo
  --map=coop` printed no errors or warnings. Movie Maker frames: `--demo --map=coop` (two
  hens and a chick on the straw, eggs in the nests, trough, tawara sack, incubator) and
  `--demo --map=farm@coop --hens-out` (thatched coop right of the stand, hens and the chick
  in the yard).
- Left / next: not played in a real window (keys, doors, the hatch, throwing an egg). No
  shop sells chickens, feed or medicine yet (shops session). Hens out in the yard can't be
  talked to; the clock stands still in the coop, so hens out only graze while the farmer is
  outdoors. Cows / sheep / dog next in milestone 7.

## 2026-10-31 — Merged six branches: music, events, maps, rucksack, food, hold / throw
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time, tests after each, in this order:
  `claude/music-volume-b700e8` (5c826bd), `claude/event-scripts-bc6b2b` (30b267a),
  `claude/map-switching-a30ee8` (2ada014), `claude/rucksack-storage-c06aae` (a459971),
  `claude/food-items-40a9a2` (605572d), `claude/hold-throw-f0459f` (22c67cb). WORKLOG kept
  main's entries plus each branch's new one; AGENTS / README / ROADMAP kept both sides (test
  list, debug flags, keys), "Next up" now points at villagers with schedules. Code joins:
  - Events + maps: EventPlayer loads a map's trigger table on `Game.map_entered`; test_maps
    marks the farm's morning events seen so its door check isn't taken over by them, and
    checks that the triggers follow the map into the house.
  - Rucksack + maps: the farm house door leads inside now, so FarmActions keeps only the
    chest from the rucksack branch; sleeping stays at the futon.
  - Food + rucksack: "food" is the 7th tool slot (`data/inventory.json`: 7 tool slots, an
    onigiri at the start), food items are `food:<id>` in the slots with their own icons
    (`PlaceholderArt.item_key` takes the food in hand), the hand box moved right of the wider
    tool bar, the save keeps the inventory and the food in hand.
  - Hold / throw + rucksack: the item held overhead is the rucksack's hand slot
    (`Game.held` reads / writes Inventory "hand"; a throw or put-down takes one off it), so
    there is one hand, not two; a harvest goes up into it, the save keeps it through the
    inventory (no separate `held` key). Throwing / putting down only on the farm; walking
    into a door still goes through. The world sprite key is now
    `PlaceholderArt.world_item_key` (crops as produce, other items as their icon) next to
    the slot icon key `item_key`. New check in test_hold (a stack in the hand throws one at
    a time); test_save / test_inventory / test_title updated for the 7th slot and the hand.
- Checked on merged main: `test_audio`, `test_body`, `test_dialogue`, `test_events`,
  `test_farm`, `test_food`, `test_hold`, `test_inventory`, `test_maps`, `test_menu`,
  `test_save`, `test_title`, `test_weather` all print `OK (0 failed)`; headless
  `--quit-after 300` (title, `-- --demo`, `--demo --map=town`, `--demo --hold`,
  `--demo --rucksack`) and `res://scenes/main.tscn --quit-after 400` (triggers on) printed
  no errors or warnings; no conflict markers. Movie Maker frames: `--demo --hold` (turnip
  overhead and in the hand box, 7 tool slots ending in the onigiri, chest by the house),
  `--demo --rucksack` (7 tool slots, food icons in the bag).
- Left / next: nothing of the six was played in a real window (keys, doors, throws, menus,
  events), and nobody has heard the music. The 2D view doesn't draw the throw arc yet (the
  hold branch added it to 3D only).

## 2026-10-31 — Holding and throwing items, shipping by throwing into the bin
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: items are things in the world (DESIGN "ไอเท็มในโลก"). Rules:
  - `FarmGrid.items` (cell -> item id) for things lying on the ground; `can_place` = farm
    cell with no obstacle, crop or other item; `place_item` / `take_item_at` / `item_at`.
    Items don't block walking (a dropped one can't trap the farmer); till and sow skip their
    cells, weeds don't grow under them, they stay overnight.
  - `FarmGrid.throw_target(origin, facing, reach, ship_into, lost_in)`: the item flies over
    crops and items; a `ship_into` cell (bin) catches it, a `lost_in` cell (pond) swallows it,
    anything else solid (building, fence, obstacle) stops it and it drops on the farthest
    free cell before; no free cell on the way = "blocked", no throw. The field is fenced, so
    nothing leaves it.
  - `Game.held` (one item in the holding hand) and `Game.shipped` (count per item, DESIGN's
    "times shipped"). `pick_up(c)` takes the item lying there, else harvests a ripe crop
    into the hand (not the bag any more); `put_down(c)`; `throw_held(origin, facing)` ships
    at `sell_price` into `bin_total` (the same 18:00 / sleep payout), loses or lands it and
    emits `thrown(item, from, to, result)` for the views. An item without a price bounces
    off the bin. `ship_produce()` (the bag route at the bin) counts shipping too.
  - `FarmActions.on_action`: with hands full, interact throws and the tool button sets the
    item down on the cell in front; the Player doesn't start a charge then. Messages:
    "Shipped a Turnip (60 G)", "The ... sank in the pond", "No room to throw it" / "to put it
    down". Sounds: `hold_throw` at once; `hold_land`, `hold_splash` or `bin_lid` after
    `flight_seconds` (new recipes in data/sfx.json).
  - Numbers in the new `data/hold.json` (ours): throw 2 cells, flight 0.35 s, arc 1.2 cells
    over the head, bin ships, pond swallows.
  - Art: `player:<front|back>:hold_idle:0` and `hold_walk:<0-3>` (both arms raised up the
    sides of the head, hands on the cap; shorter steps; the load bobs with the body,
    `PlaceholderArt.farmer_drop`). `item:<id>` 12 x 12 produce icons from each crop's look
    (root with leaves, long / round fruit, tuber, cob, ribbed squash). FarmerAnim takes a
    `holding` flag (wins over tired; a run steps at the run rate).
  - Views: 3D carries the item as a Sprite3D on the hands, flies a thrown one in an arc and
    shows a landed one on its cell when it gets there (`FarmWorld.hidden_item`); items lying
    on cells are sprites in both views; the 2D placeholder farmer raises arms and draws the
    item overhead.
  - Save: `held` and `shipped` in `Game.to_dict()`, `items` in the farm; older saves load
    empty-handed with nothing on the ground. New `-- --hold` debug flag.
- Checked: new `test_hold: OK (0 failed)` (placing rules, till / sow / weeds, every throw
  outcome incl. bin at 2 cells, pond, house, fence, crops in the way, Game pick up / put down
  / throw / pay out / blocked / no-price item / bag counting / new game, poses, item art);
  `test_save: OK (0 failed)` (held, shipped, ground items round trip; 6 bad game values and
  4 bad item lists refused; a save without them loads); `test_farm`, `test_title`,
  `test_weather`, `test_dialogue`, `test_menu`, `test_body`, `test_audio` all `OK (0 failed)`.
  Headless `--quit-after 300` (title, `-- --demo`, `-- --demo --hold`) printed no errors.
  Movie Maker frames `--demo --hold`: 3D farmer with arms up and the turnip on the hands, the
  potato lying in front of the bin; 2D view shows both too. A throw run with a temporary
  scene (not committed) showed the turnip in its arc, landed on its cell, then picked up.
- Left / next: no way yet to take an item out of the bag into the hand (rucksack menu,
  another session). Throwing into the bin from the side the camera can't see is untested in
  a real window; keys E / Space need a try by hand. The HUD doesn't name the held item.

## 2026-10-31 — Eating / drinking, food items
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: food and drink as data in the new `data/foods.json`: onigiri, green tea, dango, milk
  bottle, sakura mochi, amazake, mugwort tea (sold) and kagami mochi (not sold; for a later
  event / festival). Each has price, stamina +, fatigue (negative), `drink`, an icon look,
  and optional specials from DESIGN's eating rule: `max_stamina` (raises the max, cap 200)
  and `work_fatigue_half` (swing fatigue halved until the day ends, `Game.work_fatigue_half`,
  cleared in `end_day()` / `new_game()`). `Game.eat(id)` uses one `food:<id>` from the bag,
  adds stamina up to the max, lowers fatigue, applies specials, says "You ate / drank the ..."
  and resets the told tired state so a later one is told again. Rule of ours: a food that
  would do nothing (stamina full, no fatigue, no special) is kept ("You're full...").
  Selection: a 7th slot "food" in `Game.TOOLS` (key 7), `Game.food_index`, Q cycles foods
  while it is in hand (seeds otherwise); Space eats. The stand sells the food in hand while
  the food slot is picked (`FarmActions.buy_food`), seeds otherwise. HUD: tool bar and item
  box 20 px wider (148) for the 7th slot; the slot shows the food in hand, the item box its
  name and count (`Hud.slot_icon`). Sounds `eat` (two soft crunches) and `drink` (two gulps)
  in `data/sfx.json`. Icons `ui:food:<id>` (rice ball, round sweet, skewer, cup with steam,
  bottle) in `placeholder_art.gd`. New games start with one onigiri; `--demo` adds two
  onigiri and a green tea. Save: `food` (by name) and `work_fatigue_half` (bool); older saves
  load with the first food and no effect.
- Balance (ours): cheap snacks 40–90 G for +5..+25 stamina; tea is the fatigue drink (−5 for
  40 G); amazake is the big one (+50 / −6 for 220 G, near a day's crop money early on);
  mugwort tea 350 G for the half-fatigue day, so it pays only on a long rainy or late day.
- Checked: new `tests/test_food.gd` (data, eating, full rule, specials, cap, half fatigue,
  stand buying, the food slot through FarmActions) and extended `test_save` (food fields,
  bad values, old saves), `test_title` (starting bag), `test_farm` (7 slots fit, food icon),
  `test_audio` (food slot has no tool sound). All of `test_audio`, `test_body`,
  `test_dialogue`, `test_farm`, `test_food`, `test_menu`, `test_save`, `test_title`,
  `test_weather` print `OK (0 failed)`. Headless `--quit-after 300` (title and `-- --demo`)
  printed nothing. Movie Maker `--demo` frame: 7 slots on the bar, the onigiri in the last
  one. An 8x icon sheet of every food was looked at (steam drawn after the outline).
- Left / next: eating hasn't been tried in a real game window. No eating animation yet
  (the farmer just stands). Raw crops aren't edible yet; no cooking.

## 2026-10-31 — Rucksack and storage chest menus
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: an inventory with slots instead of the old bag of counts. `Inventory`
  (`scripts/items/inventory.gd`, pure logic) has four places: `tools` (the rucksack's tool
  slots = the HUD tool bar; `Game.tool_index` is the slot in hand), `bag` (item slots),
  `hand` (one item held in the other hand, per DESIGN "two hands") and `chest` (the storage
  chest). Rules: tools only in tool slots and the chest, never stacking; every other id (any
  string, so food items from another branch fit) in the bag, hand and chest, stacking up to
  `stack_max`; add (stacks first, then empty slots, returns what didn't fit), take (all or
  nothing), lift / drop (pick up, put down, stack with a remainder, swap), move, stow (a
  carried stack back home), grow (bigger rucksack later, never shrinks). Numbers and the
  starting things in the new `data/inventory.json`. `InventoryMenu` (cursor rows of 8, carry,
  choose / hold / close, no drawing) and `InventoryScreen` (wood + paper box, pixel font,
  slot grid with counts on a paper plate, vermilion cursor brackets, the carried stack on the
  cursor, name / level line, a note line and a key hint). I (pad Back) opens the rucksack; the
  new placeholder chest (cell 7,3 right of the house: a cedar tansu with iron pulls, 3D model
  and a 2D colour) opens the storage screen on E. Both pause the clock through `Game.pause()`
  and refuse to open over a menu or text box; a carried stack is put back on close, and if
  there is no room the screen stays open and says so. HUD: the tool bar draws the tool slots
  (an empty slot = "No tool"), and a small wood box right of it shows the hand's item. Game
  callers kept: `count` / `add_item` (now returns what didn't fit) / `take_item`, and `bag`
  is a property over the carried totals (setting it fills the rucksack, the rest goes to the
  chest). New: `can_carry`, `item_name`, `open_inventory`, signal `inventory_requested`.
  Harvesting and buying seeds with a full rucksack say "Your rucksack is full" and leave the
  crop / money alone; shipping takes crops from the rucksack and the hand, not the chest.
  Save: `inventory` (every slot) and `tool_slot` replace `bag` and `tool`; a save without
  `inventory` is migrated (tools in their start slots, the tool in hand found by name, the
  bag's counts into the rucksack, overflow into a growing chest), and a farm without the chest
  gets it on a cleared cell (`FarmGrid.add_missing_fixed`). A saved place with fewer slots
  than the data now has is filled up to the data's count. `--rucksack` / `--rucksack=storage`
  open the screens at the start; `--demo` puts a few crops in the rucksack and the chest.
- Balance (ours): 6 tool slots (the six tools; the HUD bar holds six), 8 rucksack slots,
  24 chest slots, stacks of 99. A small rucksack keeps the chest worth walking to; the shop
  upgrade later is a bigger `bag` number.
- Checked: new `test_inventory: OK (0 failed)` (data, stacking, limits, places, take, grow,
  set_carried, move / swap / partial stack / refusals, lift / drop / stow, save format and
  bad slots, slot count migration, menu rows / cursor wrap / pick / put / swap / stack /
  hold / close with and without room, Game bag calls, shipping, empty tool slot, full
  rucksack, item names, chest on the farm and on an old farm, the I key, icons);
  `test_save: OK (0 failed)` (round trip with chest, hand and a tool in the chest; bad
  `tool_slot` / `inventory` refused; a save from before slots loads with the tool by name,
  the bag in the rucksack and the chest added; bad old tool / bag refused); `test_farm`,
  `test_title` (new game: hoe in hand, starting bag, empty chest and hand), `test_weather`,
  `test_dialogue`, `test_menu`, `test_body`, `test_audio` all `OK (0 failed)`. Headless
  `--quit-after 300` (title, `-- --demo`) and the 2D scene with `-- --rucksack` printed no
  errors. Movie Maker frames `--demo --rucksack` and `--demo --rucksack=storage`: the box
  sits in the middle over the field, tools with the hoe slot marked, seed bags / turnip /
  potato with counts 2, 6, 3, 4, chest with cucumber x12 and turnip seeds x5, the info line
  "Cucumber x12", the chest stands between the house and the bin. Not checked: the keys and
  mouse in a real game window, and opening the chest by walking up to it (only the flag).
- Left / next: key remapping (rest of milestone 4). The hand item is shown and kept but does
  nothing yet; holding / throwing (another branch) can build on `Inventory` place `hand`.
  Fridge / tool box as more storage places later (one more entry in `PLACES` and the data).

## 2026-10-31 — Map switching: farmhouse inside, first village, doors, indoor clock pause
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: maps are data, `data/maps/<id>.json` (format in README → Maps): `farm` (only doors and
  spawns; ground and buildings stay FarmGrid's), `house` (8 x 7: packed-earth entry, wooden
  step, tatami room, futon, low round table, tansu chest, andon lantern) and `town` (36 x 22:
  east-west road from the farm gate, a gravel shrine yard with a hokora, stone lanterns and a
  vermilion torii over the path, four kawara-roof houses, one with a noren, pines, a pond).
  `MapData` (parse and check a file: cells, solids, props with `blocks`, doors, spawns) and
  `MapManager` (`Game.maps`: map id, the farmer's pixels and facing, cached map files).
  Game: `map_changed` / `map_entered(map_id)` signals, `go_to_map()`, `use_door()`,
  `map_arrived()` (the view calls it after the fade; the hook for event triggers),
  `go_home()`, `indoors()`. Clock: `ticking()` is false indoors (DESIGN: time stops in
  buildings); `paused()` is not, so the farmer still walks. A door is a solid cell (or cells
  just off the edge): walking into it or using it goes through; doors without a target show
  a message (the village houses, nobody lives there yet). The farm house door now leads in;
  sleeping moved to the futon; every new day (sleep, pass out, collapse) starts in the house
  by the futon. The farm's right fence has a two-cell gate to the village (fence cells left
  open in both views, FarmGrid and old saves unchanged). Arriving on a farm cell where a weed
  grew pushes it aside. Player: collision through `Game.maps.is_solid`, writes its position
  to `Game.maps`, sends "enter" when pushing into a door; tools do nothing off the farm.
  Views: main_3d / main_2d rebuild the world (FarmWorld, or the new MapWorld / MapView) on
  `map_changed` behind `MapFade` (0.25 s each way, holds a Game pause, lets go if the scene
  is left mid-fade). Indoors: fixed warm room light, no weather particles or lightning, dark
  background, camera centred on a small room; front walls drawn as low sills (cutaway) so the
  fixed camera needs no change. Sound: ambient rules take `places` (missing = outdoor), with
  muffled rain / storm wind indoors; new sounds `step_floor` (tatami / boards) and
  `door_slide`. New placeholder tiles `ground:tatami|floor|earth|gravel|wall` and
  `build:quilt`. Save: `map` {id, x, y, facing} checked on load; a save without it loads on
  the farm at the house door. Debug flag `-- --map=<id>` or `<id>@<spawn>` (`town@shrine`,
  `farm@gate`).
- Checked: `test_farm`, `test_save` (map round trip, load emits `map_changed`, loaded indoors
  the clock stands, refused broken map entries, old save loads on the farm), `test_title`,
  `test_weather`, `test_dialogue`, `test_menu`, `test_body`, `test_audio` and the new
  `test_maps` (every map file loads, doors lead to known maps onto free cells and have a way
  back, broken maps refused, house / town cells and torii posts, pond banks, ambient by place,
  clock stops indoors and runs outside, locked doors, day end at home, futon sleeps, no tools
  indoors, walking into the door, and the real 3D scene: fade holds the pause, rebuilds as the
  house, `map_entered` after the fade, no pause left) all print `OK (0 failed)`. Headless
  `--quit-after 300`: title, `-- --demo`, `-- --demo --map=town`, `-- --demo --map=house`,
  `-- --demo --weather=storm --map=town`, and main_2d with house / town / farm printed no
  errors. Movie Maker frames: `--map=house` (tatami room, futon, table, chest, lantern, cut
  walls), `--map=town` and `town@shrine` (road, houses, torii, gravel yard, pine),
  `farm@gate` (the gap in the right fence).
- Left / next: no snow lying in the village or on its roofs yet (SnowLayer is farm-only); the
  village ground is open grass with no fence at its edges; the fade and walking through doors
  were checked headless and in code, not played in a window. Village doors open once
  villagers and shops exist (milestone 5).

## 2026-10-31 — Event scripts and trigger tables per map
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: events are data in `data/events/<id>.json`, a list of steps: say (a dialogue from
  data/dialogue, from a line id, waits for the box to close), wait, face, walk (to / by cells,
  across then up or down, walk or run speed), set / clear flags, give item, money, fade to
  black / clear, sound; branch steps `if` / `unless` a flag, and `id` / `next` jumps like
  dialogue. `EventRunner` (pure logic) checks a file and refuses it with a reason, runs the
  steps on `update(delta)` and keeps the scripted farmer position / facing / walking and the
  fade amount; a loop with no wait stops after 1000 steps per update. Trigger tables per map,
  `data/events/triggers_<map id>.json`: rows with `on` (enter, day_start, minute, step) and
  optional year, season, days, weekday, time window, weather, flags / not_flags, seen /
  not_seen and area; the first matching row in table order wins (DESIGN: the table order is
  the priority) and a row plays once unless `"once": false`. `EventTriggers` is pure logic on
  `Game.trigger_state(cell)`. `EventPlayer` (in both views, after the Player) checks the map's
  table on map entry, day start (deferred, after the wake hour is set), each clock minute and
  each new cell, plays events, copies the runner onto the Player, draws the fade (layer 9:
  over the HUD, under the text box) and takes keys between dialogue steps. `enter_map(id)` is
  the hook for map switching. Game: `event_running` (in `paused()`, so the clock, the farmer,
  F5 / F9 and Esc wait), `events_seen` (saved as a sorted list, new_game clears it),
  `play_event(id)` / `event_requested`, `weekday()` (spring 1 of year 1 is a Monday, the week
  runs on; DESIGN lists weekdays in the calendar), `add_money()` (not below 0). Pause screen
  doesn't open during an event. Our sample events with our own text: `first_morning` (new
  game, spring 1, 6:00-9:00: up from black with the morning chime, a look over the farm, two
  steps out, back to the door, Tsuru's sack of three turnip seed bags), `rainy_day` (the first
  rainy morning: rain waters the field, but wet work tires), `pond_first` (the first step next
  to the pond). `-- --event=<id>` plays one; `-- --demo` turns the triggers off so field
  screenshots stay free of events.
- Checked: new `test_events: OK (0 failed)` (all data loads; first_morning step by step: fade,
  chime, the box holding the event, the walk path and speed, seeds and flag; branches, money
  floor, flags, run speed, the endless-loop guard, 28 bad scripts and 19 bad rows refused,
  first-match order, once / once false, every condition, the farm table with a new game,
  weekdays, the event pause), `test_save: OK (0 failed)` (events_seen round trip, 4 bad
  values refused, a save without it loads with none seen), and `test_audio`, `test_body`,
  `test_dialogue`, `test_farm`, `test_menu`, `test_title`, `test_weather` all `OK (0 failed)`.
  Headless `--quit-after 300` (title, `-- --demo`) and `--quit-after 400 -- --demo
  --event=first_morning` printed no errors. Movie Maker run of `res://scenes/main.tscn` (no
  demo, so the trigger fires on entry), 150 frames: frame 30 is the field fading in from
  black with the clock held at 06:00, frame 149 shows the farmer's first line in the text box.
- Left / next: the walk, the sack and the rainy / pond events were checked in the tests, not
  watched in a window (the text box needs key presses). No "examine" cause yet (E on a spot):
  it would touch farm_actions, which another session has open. Villagers as actors come with
  villagers. The target brackets stay visible during an event.

## 2026-10-31 — Music and volume sliders
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: music made the same way as the sounds. `data/music.json` holds our own scores: seven
  short loops (title, spring, summer, fall, winter, night, rain; 17-32 s each), written for
  this game as scale degrees in five-note scales (yo, in, minyo, ritsu), with five instrument
  recipes: koto-like pluck (rotating-phasor partials, higher ones fade faster), rin bell,
  wood block, shakuhachi-like flute (scoop into the note, delayed vibrato, breath noise) and
  a sho-like pad. New `MusicSynth` (score reader: degree / "+" chord / "_" hold / "." rest,
  voices with fewer bars repeat; notes cached per pitch and length; what rings past the end
  is added onto the start, so loops have no seam) and `MusicPicker` (first rule that fits:
  title screen, storm (rain track at 0.6), rain, night 19:00-6:00, then the season).
  `Sfx` gets a Music bus, one player per track, renders a track on a WorkerThreadPool task
  when first wanted (at once in Movie Maker runs, where frames don't wait), fades in from
  silence in `start_fade` 1 s and cross-fades between tracks in `fade_seconds` 3 s; the
  scene is "title" while `Game.clock_running` is off. Volumes: three range entries in
  `data/settings.json` (Music 70, Sounds 80, Ambient 60 %, step 10) with a "bus";
  `Settings.bus_volumes()` turns them into 0..1 and `Sfx.apply_settings()` calls
  `set_volume` on start and on `Game.settings_changed`. Ranges show a unit ("70%"); the
  pause screen draws a 10-notch slider on range rows (`PauseMenu.slider()`), left / right
  stop at 0 and 100, Enter steps up and wraps.
- Balance (ours): music bus 0.7 by default, tracks -4..-6 dB so the field sounds stay on top;
  night and storm softer.
- Checked: all eight tests print OK (`test_audio`: scores well formed, every track's first two
  bars sound with no silent second, title as a full loop has its exact length / no seam /
  same seed same music, picker per scene / weather / season / hour, Sfx targets in a storm
  and on the title; `test_menu`: volume defaults, %, clamp at 0 / 100, round trip, broken
  values 150 / -10 / "loud" / 45.5 refused, pause menu rows and sliders, a changed setting
  reaches the bus at once). Headless `--quit-after 300` (title and `-- --demo`) printed
  nothing. Movie Maker `--demo --pause=settings`: the Settings page shows Music 70%, Sounds
  80%, Ambient 60% with filled notches (7 / 8 / 6 of 10). With `--movie-audio` (120 frames)
  `shots/frame.wav` has 383864 non-zero samples, rms about 0.09 after the 1 s fade-in
  (spring track; no ambient at spring 10:00). Render time about 0.6-1.2 s per track on a
  worker thread. Windowed runs with the real audio driver (volumes set to 0 in a temporary
  settings file, then the user's file put back) printed no errors or leaks.
- Left / next: nobody has listened to the music yet; tune the scores / voices by ear.
  `--movie-audio` runs and runs with `--audio-driver Dummy` report 2 leaked objects per
  playing loop at exit (the same happens on main with an ambient loop): the mixer doesn't
  let go of the playback there before the engine quits; normal runs are clean.

## 2026-10-31 — Merged six branches: export, text box, sound, pause, tool exp, fatigue
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time, in this order: `claude/win-export-659b37`
  (2dfd4ba, b7e0600), `claude/text-box-3ca660` (83f324d), `claude/sound-fx-bf7df1` (5129d6f),
  `claude/pause-menu-5d4b39` (01e532e), `claude/tool-upgrades-4ff024` (3b4e94d),
  `claude/fatigue-1d9971` (23754d0). WORKLOG was rebuilt each time as main's entries plus
  the branch's new ones; AGENTS / README / ROADMAP kept both sides (test list, debug flags,
  README sections), and "Next up" now points at eating / drinking. Code joins:
  - `Game`: dialogue flags, tool exp and fatigue sit side by side in the fields,
    `to_dict()` / `from_dict()` and the save tests (bad-value list and old-save checks).
  - The pause rule takes in the text box: `Game.paused()` is true while `dialogue_open`,
    so `ticking()`, the player freeze and the lightning step have one check; the player
    keeps the pause branch's `_after_menu` guard for both. Esc doesn't open the pause menu
    over a text box. New check in `tests/test_menu.gd`.
  - `main_2d` / `main_3d` add both TextBox and PauseScreen; the lightning step uses
    `Game.ticking()` and still calls `Sfx.thunder_after_flash()`.
  - `farm_actions.use_tool` plays the tool sound and counts tool exp.
  - The pause branch moved `--no-flashes` into `apply_settings()`, so it was not brought
    back into `new_game()`; `--tired` was kept.
  - Rule clash: the tool-exp test expected "no stamina = no swing", but the fatigue branch
    lets a swing go through and turns the missing stamina into fatigue. The test in
    `tests/test_farm.gd` now checks the fatigue rule (the swing tills and gives exp).
- Checked on merged main: `test_audio`, `test_body`, `test_dialogue`, `test_farm`, `test_menu`,
  `test_save`, `test_title`, `test_weather` all print `OK (0 failed)`; headless
  `--quit-after 300` (title, and `-- --demo --weather=storm`) printed no errors or warnings;
  no conflict markers (`git grep`); Movie Maker frame `--demo --tired --dialogue=bin_note`
  shows the text box with the portrait over the field and the HUD.
- Left / next: export templates for 4.7.2 aren't installed, so no .exe was built (README →
  Export). Sound can't be heard here. The pause menu, text box keys, charging and F5 / F9 still
  need a try in a real game window.

## 2026-10-31 — Fatigue, tired poses, oversleeping and collapse
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: a second body value, `Game.fatigue` (0..100, hidden like DESIGN says), with every rule
  number in the new `data/body.json`. Work: a swing adds fatigue in rain / storm, from 22:00,
  more after midnight; a swing without enough stamina now still happens, stamina stops at 0
  and every missing point becomes fatigue (overwork), so `spend_stamina` no longer refuses
  ("Too tired" is gone). Staying up: fatigue on the hour at 22, 23, 0 and 1. Sleep: fatigue
  - (base + per hour from bedtime to 6:00), so going to bed early rests more. Oversleeping:
  `wake_hour()` = the later of a fatigue-at-bedtime table and a bed-after-midnight table;
  `sleep()` jumps the clock to it and says "You overslept until 8:00.". States:
  `body_state()` fine / tired / exhausted from fatigue or a low stamina share;
  `speed_factor()` (tired 0.85, exhausted 0.6) and `can_run()` (not when exhausted) are used
  by the Player; `check_body()` runs every minute, tells a worse state once and collapses the
  farmer at 100. `knock_out(kind)` is shared by the 2:00 pass out and the new `collapse()`:
  day ends without rest, wake hour, fee (never below 0 G), stamina share and fatigue change
  from data, message. No clinic yet, so the farmer wakes at home. Save: `fatigue` in
  SAVED_NUMBERS (0..100) with default 0 for older saves; `new_game()` resets it and the
  warning state. Art: new placeholder poses `player:<front|back>:tired_idle:<0-1>` (slow
  breath) and `tired_walk:<0-3>` (short dragging steps): body 1-2 px lower, arms a pixel
  lower, a sweat drop by the brow. FarmerAnim takes a `tired` flag (main_3d passes
  `body_state() != "fine"`); a tired run stays a run. New `-- --tired` flag for screenshots.
- Balance (ours): work +1 rain / +1 late / +2 after midnight, overwork 1 per missing stamina;
  awake 22:00 +2, 23:00 +3, 0:00 +4, 1:00 +5; sleep rest 10 + 4 per hour (bed at 22:00 =
  -42); oversleep fatigue 40 -> 7:00, 60 -> 8:00, 80 -> 10:00, bed at 0:xx -> 7:00, 1:xx ->
  8:00; tired at fatigue 50 or stamina <= 30 %, exhausted at 80 or stamina 0; pass out wakes
  8:00 with half stamina and fatigue +10; collapse wakes 12:00 next day, 30 G, half stamina,
  fatigue -40. A normal day (bed by 22:00, no overwork) never builds fatigue; it takes about
  a full stamina bar of overwork or several late nights in a row to collapse.
- Checked: `test_farm: OK (0 failed)` (tired poses / frames, overwork swing),
  `test_save: OK (0 failed)` (fatigue round trip; refused -1, 101, 2.5, "lots"; a save without
  fatigue loads at 0), `test_title: OK (0 failed)` (new game resets fatigue and the warning),
  `test_weather: OK (0 failed)`, new `test_body: OK (0 failed)` (states, speed, running,
  warning once, work / late / overwork fatigue, the 22:00 tick, sleep rest, oversleep
  tables, sleep and collapse and pass out results, fee floor; it puts the real save slot
  back since `sleep()` writes it). Headless `--quit-after 300` (title, `-- --demo`,
  `-- --demo --tired`) printed no errors. Movie Maker frame `--demo --tired`: the farmer
  stands slumped with a light blue sweat drop left of the face, HUD intact. Not checked:
  the slower walk and the messages in a real game window; the 2D view has no tired look.
- Left / next: food lowering fatigue (eating milestone); the clinic for the collapse when
  the town exists; DESIGN's per-threshold tired animation is a message plus the tired poses
  for now.

## 2026-10-31 — Tool levels from experience
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: every swing of hoe / can / sickle / hammer / axe gives the tool experience
  (`Game.tool_exp`, per tool). FarmActions tells `Game.add_tool_exp()` whether the swing
  changed a cell (tilled, watered, hit or cleared something): `exp_per_swing.work` if so,
  `.miss` if it hit nothing. A use that never swung (too tired, empty can) and filling the
  can at the pond give nothing; the seed bag has no levels. Each tool's `exp_to_level` in
  `data/tools.json` holds the total exp for levels 2..5; passing one calls
  `Game.raise_tool_level()`, which adds one level, shows the tool's own `level_up` line
  through `Game.message` ("The hoe bites into the soil more easily. Hoe level 2!") and
  redraws. The blacksmith (milestone 8) can call the same function; a raised tool keeps its
  exp and needs the next absolute step. Exp stops at the last step (level 5 is the cap).
  HUD: after the tool name in the item box, the charge-pip texture shows the level (5 pips,
  vermilion up to the level); nothing for the seed bag. Save: `tool_exp` in `to_dict()` /
  `from_dict()` (known tools, whole 0..the tool's last step); a save without it loads at 0.
  `reset_tool_levels()` (new game) clears exp too. README controls mention it.
  Also removed merge markers left in AGENTS.md, ROADMAP.md and WORKLOG.md by the last merge
  (both sides kept).
- Balance (ours): work 3, miss 1, so aiming matters but a miss isn't worthless (design: work
  teaches more than a miss). Hoe and can need 300 / 900 / 2100 / 4200: a day's stamina is
  about 30-50 swings, roughly 90-150 exp, so level 2 in 2-3 days, level 3 in about a week,
  level 4 near the end of spring, level 5 in summer, leaving room for the shop to be the
  quicker way later. Sickle 240 / 720 / 1680 / 3360 (weeds come back slower than soil to
  work). Hammer and axe 90 / 270 / 630 / 1260, since the farm only has so many rocks,
  branches and stumps (a stump is 4 hits, so it alone is 12 exp).
- Checked: `test_farm: OK (0 failed)` (data: 4 rising exp steps per tool, message takes the
  level; on the Game autoload: tilling gives work exp, a swing on tilled soil miss exp, only
  the used tool learns, too tired = no swing and no exp, empty can and pond fill none,
  watering work, a stump hit that holds still counts; one exp short stays level 1, the swing
  that reaches the step makes level 2 with one message, level 2 charges twice and a charge-2
  hoe swing then tills its whole 5-cell area; a huge gain passes three levels with three
  messages, stops at level 5 with exp at the cap, `raise_tool_level` refuses past 5, the
  seed bag gets nothing; raise without exp keeps exp and the next level needs its own step;
  the can name, 5 pips and "40/40" fit the item box). `test_save: OK (0 failed)` (exp round
  trip; refused: not a dictionary, -1, unknown tool, 1.5, over the cap, seeds; an old save
  without it loads at 0 and keeps its levels). `test_title: OK (0 failed)` (new game clears
  exp), `test_weather: OK (0 failed)`. Headless `--quit-after 300` (title and `-- --demo`)
  printed nothing. Movie Maker frame (`--demo` with a temporary hoe level 3, removed): "Hoe"
  then 3 vermilion pips (200, 68, 44) and 2 paper ones in the item box.
  Not checked: the level-up message in a real game window.
- Left / next: shop upgrades (milestone 8) call `raise_tool_level`; level 5 still adds no
  charge (it could make swings cheaper later). Next: fatigue / collapse.

## 2026-10-31 — Pause menu, settings, clock stops in menus
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: Esc (or a pad's Start, new `pause` action) opens `PauseScreen`
  (scripts/ui/pause_screen.gd) in both views: the field dims, a wood box with a paper page
  in our pixel font, pages Paused (Resume / Save / Settings / Back to title), Settings and
  "Save first?" (Save, then go / Go without saving / Cancel). Arrows or W / S move,
  Enter / Space choose, left / right change a setting, Esc goes back a page or closes; the
  mouse points and clicks. Page logic is `PauseMenu` (no drawing); the cursor and skipping
  moved from TitleMenu into a shared `MenuList` that both menus use. Pause rule in Game:
  `pause()` / `unpause()` count open menus (nested menus work, never below 0), `paused()`,
  `ticking()` = clock running and no menu; the clock, lightning and F5 / F9 respect it.
  The farmer stands still in a menu, a charge is dropped (DESIGN: opening a menu resets the
  charge), and the Enter / Space that closed the menu doesn't swing the tool until let go.
  Particles keep falling. Settings: `Settings` (scripts/save/settings.gd) with the list in
  `data/settings.json` (kinds bool / choice / range, so the sound session's volume is one
  entry: a `range` with min / max / step), saved to `user://settings.json` with a version,
  apart from the game save. A broken file (not JSON, no or newer version, a wrong value) is
  refused whole and every setting stays at its default; a missing setting takes its default,
  an unknown one is skipped. `Game.apply_settings()` sets `flashes_enabled` (`--no-flashes`
  wins over the file) and the window (2x / 3x / 4x of 480 x 270, or full screen; skipped
  headless); `settings_changed` resets the 3D lightning. `-- --pause` / `--pause=settings`
  open the menu at the start for screenshots.
- Checked: new `tests/test_menu.gd` prints `test_menu: OK (0 failed)` (pause rule on a scratch
  Game: no minutes pass while paused, nesting, an extra close; flashes from settings and
  `--no-flashes` winning; settings defaults, flip / wrap / stop at the ends, round trip,
  9 broken files refused with nothing changed, older / newer keys, a range setting;
  PauseMenu pages, labels, cursor after back / cancel; MenuList skipping; on the Game
  autoload a Player in a menu: no walking, charge dropped, the closing key doesn't swing,
  walks again after). `test_farm`, `test_save`, `test_title`, `test_weather` all
  `OK (0 failed)`. Headless `--quit-after 300` (title, `--demo --weather=storm`,
  `--demo --pause`) and the 2D scene printed no errors. Movie Maker `--demo --weather=snow
  --pause` (60 frames): the box is centred, clock still 10:00 after 2 s, snow falling;
  `--pause=settings` shows "Lightning: On / Window: 3x / Back"; the dim takes the sky from
  (143, 198, 232) to (90, 117, 132). Not checked: real key presses, mouse clicks, the pad
  button and the window resize in a game window (no input headless).
- Left / next: volume (sound session, data entry + reading it); key remapping; the clock
  pause indoors comes with map switching.

## 2026-10-31 — Sound effects and ambient sound (milestone 10, first step)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: new `Sfx` autoload (`scripts/autoload/sfx.gd`) plays sounds by key from the new
  `data/sfx.json` (per key: bus, volume_db, pitch range, layers; loops have a length).
  Every sound is our own, synthesized at run time by `SfxSynth` (`scripts/audio/sfx_synth.gd`:
  filtered white / brown noise, sine partials with a glide, a plucked string, clusters of
  tiny noise grains; attack / decay / release, tremolo and gate envelopes; loops cross-fade
  their tail into the start; each sound is normalized and made once, on first use, from a
  fixed seed). Chosen over WAVs from a Python script: no binary files in git, the recipes are
  small text that merges and tunes like the other data, and nothing must be re-run by hand.
  Making all 21 sounds takes about 0.8 s, spread over first uses. Busses `SFX` and
  `Ambient` are made at start (0.8 / 0.6 from the data); `Sfx.set_volume(bus, 0..1)` /
  `get_volume` for the settings screen (0 mutes). Ambient: `AmbientPicker` (pure) turns the
  weather look, season and hour into loop levels from the rules in the data (rain 0.7, storm
  rain + wind, snow a soft wind, blizzard wind, summer 7-18 cicadas, summer / fall 19-4
  crickets, spring 20-3 a few crickets); Sfx cross-fades to them over 4 s and fades them out
  while the clock stands (title screen, later menus). Hooks (one line each): FarmActions
  plays `tool_<tool>` per swing, seed scatter, pond fill, bin lid, picking a crop; Player
  calls `Sfx.walk()` (a footstep every 14 px: soil on tilled cells, snow from 50 snow cover,
  else grass); the title menu plays move / confirm; main_3d plays thunder 1.5-4 s after a
  lightning flash starts (`Lightning.started`, new). Sfx itself listens to Game: a chime on
  `day_started` (6:00) and coins when the bin's value went into the money (payday), so
  game.gd is untouched. Headless and Movie Maker runs start no players (`Sfx.silent`; a sound
  playing when the engine quits there is reported as a leak); `-- --movie-audio` keeps sound
  in a Movie Maker run. On quit Sfx stops everything and waits 60 ms for the mixer.
- Balance (ours): one-shots -8 to -14 dB, footsteps -19 / -20 dB, loops -12 to -24 dB, so
  insects and rain stay under the tools; pitch spread ±10-15 % on tools and steps.
- Checked: `test_audio: OK (0 failed)` (data loads; every recipe renders normalized, with
  numbers, quiet ends, sane lengths; loops have their exact length, the Ambient bus and no
  seam; 16-bit streams, loop mode; same seed same sound; every key played in code, per tool,
  per ground and per ambient rule is in the data; picker cases for storm, rain, summer noon
  and night, after midnight, dawn, fall noon, winter night, spring, snow, blizzard, hour
  wrap; one `Lightning.started` per flash; on the autoload: busses, volume set / clamp /
  mute, playing every one-shot, footstep grounds, storm loops picked and started, nothing
  while the clock stands). `test_farm`, `test_save`, `test_title`, `test_weather`: OK (0
  failed). Headless `--quit-after 300` (title), `-- --demo --weather=storm` (600 frames),
  `-- --demo` and the 2D scene printed nothing but the banner; a windowed run with the real
  audio driver (`--quit-after 300 -- --demo --weather=storm`) printed nothing either.
  Movie Maker with `--movie-audio` (storm, 10 s) recorded a mix that rises from rms 0.004
  to 0.03 over the first 4 s (the fade-in) and peaks at 0.30 (python numpy on frame.wav);
  that run ends with a leak warning (Movie Maker drives the mixer frame by frame), which is
  why such runs are silent unless asked. Not checked: how anything sounds; no one has heard
  these sounds yet (no speakers here), so the recipes need a listening pass.
- Left / next: listen and tune `data/sfx.json`; volume sliders in the settings screen (pause
  menu session); music; thunder is tied to the flashes, so with `--no-flashes` there is none;
  the ambient also stops while a pause menu stops the clock.

## 2026-10-31 — Text box (dialogue)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: our own dialogue system (no Dialogic). Format in `data/dialogue/<id>.json`
  (README → Dialogue): a list of lines with `speaker`, `face` (calm / smile / surprised /
  worried), `text`, `next` (a line id or "end"; default the next line), `set` (flags), up to 4
  `choices` (text, next, set) and branch lines `{"if": flag, "then": id}`. Speakers (name tag
  and portrait colours) in `data/dialogue/speakers.json`, typing speed and punctuation pauses
  in `data/text_box.json` (40 letters/s, 0.2 s after . ! ?, 0.08 s after a comma).
  `DialogueRunner` (scripts/dialogue, pure logic) checks a dialogue before running it (keys,
  ids, targets, speakers, faces, flags, the font has every letter, the text fits 4 rows,
  choices fit) and refuses bad data with `error`; then reveals letters, a press shows the
  whole line or goes on, choices move / wrap / pick and write flags. `TextBoxLayout` holds
  the box geometry and a word wrap that keeps the text length (so the typewriter's first n
  letters draw the same words as the full line). `TextBox` (scripts/ui/text_box.gd, both
  views): a paper box across the bottom over the tool bar, a 40 x 40 portrait in a wooden
  frame (new `face:<speaker>:<expression>` placeholders: cap or hair bun, eyes / brows /
  mouth per expression), a wooden name tag, a blinking vermilion arrow when a press goes on,
  a choice box above the right end; E / Space / Enter or a click, arrows / W / S and the
  mouse for choices; it takes every key while open (no tools, no F5 / F9). Game: new
  `flags` (saved, checked, an old save without them loads with none; reset by `new_game()`),
  `dialogue_open` (the clock skips its tick, the farmer stands, a charge is dropped; the key
  that closed the box doesn't act again) and `talk(id, at)` / `dialogue_requested` so
  FarmActions can ask the view. Kept apart from the pause rule of the pause-menu session.
  Sample: checking the shipping bin with nothing to ship opens `bin_note` (a note from Tsuru,
  the village head, one question: write your name on the lid?); afterwards the flag
  `bin_note_read` gives a one-line reminder. Debug flag `-- --dialogue=<id>[@<line id>]`.
- Checked: new `tests/test_dialogue.gd` prints `test_dialogue: OK (0 failed)` (all data files
  load; letter timing and punctuation pause; press reveals then steps; choices wait for the
  full line, wrap, pick by cursor or number, set flags; branch both ways, a self-loop ends;
  `at` start; 31 kinds of bad data refused; wrap rows fit and keep the length; 40 x 40 faces
  differ per expression; `talk()` emits; the clock holds while open). `test_save: OK (0
  failed)` (flags round trip with an int kept an int; 5 bad flag sets refused; old save
  without flags), `test_title: OK (0 failed)` (new game clears flags), `test_farm: OK (0
  failed)`, `test_weather: OK (0 failed)`. Headless `--quit-after 300` plain, `-- --demo`,
  `--dialogue=bin_note`, `--dialogue=bin_note@ask` and the 2D scene: no errors
  (`--dialogue=nope` reports "No dialogue nope" as meant). Movie Maker: frame 29 of
  `--demo --dialogue=bin_note` shows the box mid-line ("Nothing to ship yet. Oh, th") with the
  farmer portrait and name tag; frame 119 of `--dialogue=bin_note@ask` shows Tsuru with both
  choices and the clock still at 10:00. A temporary scene (removed) sent real key events
  through the viewport: E stepped and picked, key 2 did not change the tool, Enter closed it,
  the clock stayed at 09:00. Not checked: the mouse, in a real window.
- Left / next: event scripts and trigger tables per map (milestone 6, item 2) build on this;
  kana / kanji glyphs once there is Japanese text; the player's and farm's names in text.
  Fixed on the way: conflict markers left in AGENTS.md, ROADMAP.md and WORKLOG.md by the
  last merge (both sides kept).

## 2026-10-31 — Snow in the 2D view
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: FarmView now draws in two layers, ground tiles (its own `_draw`) and sprites /
  buildings (a child `_objects` node), so snow can go between them. `show_snow(rules)` adds
  a Sprite2D with the SnowLayer hold mask stretched over the farm (linear filter, as the 3D
  mask) and the new `SnowLayer.CANVAS_SHADER`: the same `snow_at` noise test as the 3D ground
  (shared `_SNOW_AT`; canvas pixels / 16 = cells = 3D x / z), so a farm has the same snow
  patches and blue-grey rims in both views. `set_snow(cover)` sets the shader cover and hides
  the overlay at 0; `cells_changed` rebuilds the mask (`FarmView.snow_mask`), so tilled and
  wet plots hold less snow as in 3D. FarmView stays free of the Game autoload: main_2d.gd
  passes `Game.snow_rules` and calls `set_snow(Game.snow_cover / 100.0)` on start and on
  `day_started` (as main_3d.gd). The ground-only FarmView used for the 3D ground texture is
  unchanged (no snow, no object layer).
- Checked: test_weather extended (overlay spans the farm, hidden at cover 0, takes the cover,
  tilling a grass cell drops its mask value 1.0 -> 0.6): `test_weather: OK (0 failed)`,
  `test_farm: OK (0 failed)`, `test_save: OK (0 failed)`, `test_title: OK (0 failed)`.
  Headless `--quit-after 300` (title; `-- --demo --weather=snow`; `scenes/main_2d.tscn --
  --demo --weather=blizzard`) printed no errors or warnings. Movie Maker frame of
  `scenes/main_2d.tscn -- --demo --weather=snow`: ragged snow patches with rims over grass,
  plots and crops readable on top; near-white pixels 0.412 of a grass area vs 0.156 over the
  plots. A 3D frame with `--weather=snow` still shows snow on ground and roof after the
  shader split. `shots/` deleted.
- Left / next: no snow on the 2D building boxes (they are flat placeholders).

## 2026-10-31 — Windows export preset and app icon
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: `export_presets.cfg` with a "Windows Desktop" preset: `build/HarvestSon.exe`
  (`/build/` git-ignored), .pck embedded in the exe, x86_64, tests/ and tools/ left out,
  data/*.json included, exe resources: icon `icon.ico`, product "Harvest Son", company
  "Harvest Son Team", version 0.1.0.0, "(c) 2026 Harvest Son Team". project.godot:
  `config/version="0.1.0"`, `config/icon="res://icon.png"`. Our icon is a 16 x 16 pixel
  drawing in `tools/make_icon.gd` (a sprout with two leaves over tilled ridges and furrows,
  a grass strip, a pale morning sky with a small sun, round dark outline; ground colours
  from PlaceholderArt) scaled up nearest-neighbour: `icon.png` 256 px and `icon.ico` with
  PNG entries 16 / 32 / 48 / 64 / 128 / 256 (written by hand, Godot has no .ico saver).
  README → Export (steps to install the templates and build), AGENTS.md → Export / App icon.
- Checked: `make_icon: icon.png OK, icon.ico OK`; icon.png looked at (sprout, rows, sun read
  at a glance). Export templates are **not installed** (`%APPDATA%\Godot\export_templates`
  is empty) and were not downloaded, so no exe was built or started. The export command was
  run to check the preset; it stops only on the missing templates:
  `No export template found at the expected path:
  C:/Users/Champ/AppData/Roaming/Godot/export_templates/4.7.2.stable/windows_release_x86_64.exe`
  then `ERROR: Project export for preset "Windows Desktop" failed.`
  `test_farm: OK (0 failed)`, `test_save: OK (0 failed)`, `test_title: OK (0 failed)`,
  `test_weather: OK (0 failed)`; headless `--quit-after 300` (title, `-- --demo`, and
  `scenes/main_2d.tscn -- --demo`) printed no errors or warnings.
- Left / next: the user installs the 4.7.2 templates (README → Export), then build and run
  `build/HarvestSon.exe --quit-after 300`; check the icon in Explorer. Settings menu later.

## 2026-10-31 — Fix conflict markers left in the docs
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the snow / lightning merge (139faab) committed `<<<<<<<` / `>>>>>>>` blocks in
  AGENTS.md, ROADMAP.md and WORKLOG.md (the resolve script stopped early and that went
  unnoticed; the code files were fine). Resolved them by keeping both sides: AGENTS lists
  test_title and test_weather, the title-screen smoke run and `--no-flashes`; ROADMAP "Next
  up" names tool upgrades, weather done and the pause menu; WORKLOG keeps all three entries.
- Checked: `git grep` finds no conflict markers on main.
- Left / next: the six branches started from 992327f still carry the markers; resolve them
  at merge time.

## 2026-10-31 — Merged charging tools, title screen and snow / lightning
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three parallel sessions merged into main with `--no-ff`:
  `claude/charging-tools-1fea05` (df973c1), `claude/title-screen-ee5824` (a9b71e4),
  `claude/snow-lightning-b2757e` (4328c29). Conflicts in `game.gd` (tools_data / snow_rules),
  `tests/test_save.gd` (tool levels and snow cover checks), AGENTS.md (test and flag lists),
  ROADMAP.md and WORKLOG.md were resolved by keeping both sides. `Game.new_game()` did not
  reset `snow_cover` (the title screen's "nothing left over" rule), so it does now, and
  `tests/test_title.gd` sets snow cover and a tool level before the reset check.
- Checked on merged main: `test_farm: OK (0 failed)`, `test_save: OK (0 failed)`,
  `test_title: OK (0 failed)`, `test_weather: OK (0 failed)`; headless `--quit-after 300`
  (title screen, and `-- --demo --weather=storm`) printed no errors or warnings; Movie Maker
  frame `--demo --weather=snow` shows snow on the ground and roof with the HUD intact.
- Left / next: charging, the title menu and F5 / F9 still need real key presses in a game
  window; snow is not shown in the 2D view. ROADMAP → tool levels and upgrades.

## 2026-10-31 — Charging tools
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: hold the use button with hoe / can / sickle / hammer / axe to charge; the charge goes
  up one step every 0.6 s (the farmer stands still), letting go swings the tool at that step.
  New `data/tools.json`: per tool `max_charge` per level (5 levels: 1, 2, 3, 4, 4) and per
  charge step an `area` drawn as text facing down (`@` farmer, `#` cell), `stamina`, and for
  hammer / axe `hits` (one cell, harder) instead of a bigger area; the can has
  `water_per_cell`. FarmGrid: `area_offsets()` reads a drawing, `turn()` turns it to the
  facing, `area_cells()` drops cells off the grid and on buildings / pond / fence;
  `hit(c, tool, power)` adds several hits at once. Game: `tool_levels` (all 1 in a new game),
  `max_charge()`, `charge_after(seconds)`, `charge_rule()` (a charge above the level is cut to
  it); `TOOL_COST` became `SEED_COST` (the seed bag doesn't charge). FarmActions works from the
  farmer's cell and facing: hoe tills / sickle cuts every area cell, the can pours one water
  per area cell nearest rows first and stops early when short, the pond fills it at any charge.
  The Player signal is now `action(kind, origin, facing, charge)`. Marker: while charging the
  target brackets cover the whole area and pips (vermilion = reached, paper = still to come)
  float over the farmer (3D Sprite3D, 2D drawn); no HUD change. Save: `tool_levels` in
  `Game.to_dict()` / `from_dict()` (known tools, whole 1..levels); a save without it loads
  with every tool at level 1. README controls updated.
- Balance (ours): areas hoe 1 / line 3 / line 5 / 3 x 3 / 3 x 5, can 1 / 3 / 3 x 2 / 3 x 3 /
  5 x 3, sickle 1 / 3 / 5 (sides too) / 8 around / 24 around; stamina hoe 2-3-5-7-10,
  can and sickle 1-2-3-4-6, hammer and axe 2-3-5-7-9 with hits 1-2-4-6-8. A charge always
  costs less than tapping each cell, so charging pays; level 1 already has one charge so the
  mechanic is there from day one. Level 5 adds no charge yet (left for upgrades to give
  something else, e.g. cheaper swings).
- Checked: `test_farm: OK (0 failed)` (area drawings, the four facings, every charge step has
  an area and costs more than the last, edge cells: fence, off the grid, house, pond; power
  hits; levels and charge timing; pips texture; FarmActions on the Game autoload: charged hoe
  line, stamina, a charge past the level, can 6 cells for 6 water, a 2-water can, pond fill,
  sickle 3 across, axe two hits, too tired). `test_save: OK (0 failed)` (levels round trip;
  refused: not a dictionary, 0, 6, unknown tool, 2.5; an old save without levels loads at 1).
  Headless `--quit-after 300` (with and without `--demo`) and the 2D scene printed no errors.
  Movie Maker frame (`--demo`, a temporary press of the use button on a level-4 hoe, removed)
  shows 3 of 4 pips over the farmer and brackets on the 3 x 3 area ahead. Not checked:
  holding the key in a real game window.
- Left / next: tool upgrades (raise `tool_levels`, shop later); over-charge not modelled.

## 2026-10-31 — Title screen (new game / continue)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: `scenes/title.tscn` (scripts/ui/title_screen.gd) is the main scene now. "Harvest Son"
  in our pixel font at 3x with a vermilion stroke, over a new placeholder picture
  `title:bg` (early morning: banded sky, pale sun, two hazy ridges, a cedar hill with a small
  torii, a thatched farm house, flooded rice paddies with seedlings). A paper box with
  New game / Continue / Quit; arrows or W / S move (skipping items that are off, wrapping),
  Enter / Space choose, the mouse points and clicks. The choices are `TitleMenu`
  (scripts/ui/title_menu.gd, no drawing). Continue is greyed out unless
  `SaveGame.check()` passes: the new check parses the slot and runs `from_dict` on a scratch
  Game (only the crop data shared), so nothing is applied; `read` and `check` share
  `_parse`. The cursor starts on Continue when there is a save. A save that exists but
  can't be loaded shows why under the menu. `Game.new_game()` now resets every run value
  (calendar, clock, weather today, money, bin, stamina / max, water, tool, seed, clock
  remainder) besides the new farm and bag, so a new game after a played one starts clean.
  The title stops the clock and takes all key events in `_input`, so F5 / F9 can't save a
  blank farm over the slot from the title. `-- --demo` skips the title (straight to the
  field), so the screenshot and smoke commands work as before. AGENTS.md / README updated.
- Checked: new `tests/test_title.gd` prints `test_title: OK (0 failed)` (no file → Continue
  off, cursor on New game, up / down skip it and wrap, the mouse can't point at it; empty,
  non-JSON, cut-off, no-version, newer-version, bad-day and unknown-crop files → off; a good
  save → on, cursor on Continue, checking left the game equal, reading it gives the saved
  state; new game after changing year, season, clock, weather, bin, stamina, water, tool,
  seed, bag and the farm equals a fresh new game with the same seed, with a new farm and no
  tilled soil). `test_save: OK (0 failed)`, `test_farm: OK (0 failed)`. Headless
  `--quit-after 300` with and without `-- --demo` printed no errors. A temporary script
  (deleted) wrote a save, opened the title (Continue on, cursor on it, clock stopped),
  chose Continue (field, day 9, 4321 G, clock running), went back and chose New game
  (field, day 1, 500 G); the temporary save was removed. Movie Maker frame without
  `--demo` shows the title picture, the name and the menu with Continue greyed out.
  Not checked: pressing keys / clicking in a real game window (no input headless).
- Left / next: no pause menu or "back to title" yet; charging tools (other session) should
  add any new run state to the reset list in `Game.new_game()`.

## 2026-10-31 — Snow lying on the ground, lightning flashes
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: `Game.snow_cover` (0..100) is set each morning by `Game.next_snow_cover()` from
  today's look and `data/snow_cover.json`: a snow day adds 50, a blizzard 100 (cap 100);
  any other day melts 20 in winter and 100 in the other seasons, rain / storm 60 more. So
  snow lies from the first snowfall through winter, a full cover lasts 5 clear winter days,
  rain washes it off sooner, and spring 1 is always clear of it. Saved in `to_dict()`
  (0..100, checked); an older save without it loads with no snow. The 3D view reads it:
  `SnowLayer` (scripts/world3d/snow_layer.gd) puts a shader on the ground plane that
  whitens a share of the pixels on the 16-per-cell grid, picked by an equalised seamless
  noise (cover 0.4 = 40 % of pixels), with a pale blue-grey rim round each patch so there
  are no hard edges. A per-cell mask (4 px a cell, linear) says how much each ground holds
  (data: grass 1.0, path 0.85, tilled 0.6, wet 0.3, water 0), so plots and watered soil stay
  readable; crops are sprites and stay as they are. The house roof, stall roof and bin lid
  get thin lit snow tops with the same pattern (bare spots cut away, eaves keep a dark rim).
  Lightning: `Lightning` (scripts/weather/lightning.gd, pure timing) gives a brightness per
  frame from `weather_fx.json` storm → `lightning`: first flash after 1.5-5 s, then every
  6-16 s, each flash a bright 0.08 s pulse and a softer 0.25 s one 0.2 s later, both fading.
  The 3D view adds that much pale sky blue (`dce4ff` x 0.3) over the picture with an
  additive ColorRect above the day / weather tint. Only rain storms flash (not blizzards),
  nothing while the clock is stopped. `Game.flashes_enabled` turns it off (for now with
  `-- --no-flashes`; the settings menu should show it). Strength first tried at 0.4: the
  peak frame doubled the picture's mean brightness and washed it out, so 0.3.
- Checked: new `tests/test_weather.gd` prints `test_weather: OK (0 failed)` (cover rule:
  build-up, blizzard, cap, thinning, 3-10 clear days to melt, rain melts more, gone outside
  winter; through `Game.end_day()`: winter storm morning 100, winter 30 thins, spring 1 0;
  ground hold grass > tilled > wet > 0 and the mask; equalised noise 40 % below 0.4;
  lightning only in storms, short, first flash in range, gaps >= 6 s over 10 simulated
  minutes, <= 3 pulses a second, none without a style, none with flashes off, none in a
  winter storm). `test_save: OK (0 failed)` (snow cover round trip, 101 / "deep" refused,
  old save without it loads), `test_farm: OK (0 failed)`; headless `--quit-after 300` (plain
  and `--demo --weather=storm`) printed no errors. Movie Maker `--demo --weather=snow` and
  `--weather=blizzard`: ragged white patches on grass, plots mostly soil, white roof and lid
  tops. `--weather=storm`, 200 frames, mean brightness of the field area: median 78.0,
  flash frames 148-149 and 154-160, peak 121.9; with `--no-flashes` no frame above
  median + 3 (max 78.6, run at strength 0.4).
- Left / next: the 2D view shows no snow; flashes off is a flag, not yet in a menu.

## 2026-10-31 — Merged HUD, Japanese props and save / load
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three parallel sessions worked on their own branches; merged into main with
  `--no-ff`: `claude/hud-clock-box-3f2c0e` (f39b130), `claude/japanese-props-2cc38b`
  (a070ba6), `claude/save-load-310e1b` (9b09560). Only WORKLOG.md conflicted (both entries
  kept, newest first); code and ROADMAP merged on their own.
- Checked on merged main: `test_farm: OK (0 failed)`, `test_save: OK (0 failed)`; headless
  `--quit-after 300` printed no errors or warnings; Movie Maker frame with
  `--demo --weather=rain` shows the new HUD boxes, bamboo fence, cedar bin and rain together.
- Left / next: F5 / F9 not yet pressed in a real game window; ROADMAP → charging tools.

## 2026-10-31 — Save game and load
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: `SaveGame` (scripts/save/save_game.gd) writes `user://save1.json` as
  `{"version": 1, "game": {...}}` and reads it back. The state itself comes from
  `Game.to_dict()` / `from_dict()` (calendar, clock, weather today / tomorrow, money, bin,
  stamina / max, water, tool and seed by name, bag) and `FarmGrid.to_dict()` /
  `from_dict()` (every cell: tilled, wet, obj, crop, stage, days, hits; plus the fixed
  cells, so a later layout change keeps). Loading checks everything first (types, ranges,
  known crop ids, stage within the crop's stages, grid size) and only then applies, so a
  missing, broken, newer-version or tampered file changes nothing and returns a message.
  The FarmGrid is filled in place (views keep their reference); it emits `cells_changed`,
  then Game emits `day_started` (views put the farmer home, redo weather and light) and
  `changed`. Sleeping saves the game ("Good morning! Game saved."); F5 quick save,
  F9 quick load, both report through `Game.message`. Tool / seed are saved by name so
  reordering `data/crops.json` doesn't change the selection.
- Checked: new `tests/test_save.gd` prints `test_save: OK (0 failed)` (round trip of a farm
  with a sown, watered potato, tilled / wet soil, a half-hit stump, a rock and a changed
  Game state: loaded `to_dict()` equals the saved one, ints stay ints, the same FarmGrid
  object, signals fired once, the crop keeps growing; refused: missing file, empty /
  non-JSON / wrong-shape / newer-version files, bad day, hour, stamina, tool, seed, bag,
  weather, farm size, cell count, crop id, stage, obj, building cell; failed loads left the
  state equal). `test_farm: OK (0 failed)`; headless `--quit-after 300` (with and without
  `--demo`) printed no errors. Not checked: pressing F5 / F9 in a game window (no input
  can be sent headless).
- Left / next: title screen with new game / continue; the game still starts a new farm.

## 2026-10-31 — Japanese fence, seed stall and shipping bin
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the last western farm pieces follow ROADMAP "Mood and tone". Fence: a low bamboo
  lattice (yotsume-gaki look, our own layout) on the same border cells: a bamboo post per
  cell, thin canes a third of a cell apart, two cross canes a side and dark rope ties at the
  posts (posts, canes and ties are one MultiMesh each). Seed stand (cell 10, 3): a roadside
  stall with four posts, a small board gable roof (eaves 1.32 high) and an indigo noren with
  a white sprout mark under the front eave; the three seed sacks stay and a small cedar
  honesty box sits on the counter. Shipping bin (cell 8, 3): a lidded cedar box on two dark
  runners with corner battens, a straw rope round the middle and two battens on the lid.
  All stay inside their cells; FarmGrid cells and collision are unchanged. New surfaces
  `build:sugi`, `build:bamboo`, `build:noren`; removed `build:awning` and the unused
  `build:stone`. Canes at radius 0.03 nearly vanished at 480 x 270, so they are 0.045.
- Checked: `test_farm: OK (0 failed)` (building-surface check lists the new surfaces);
  headless `--quit-after 300` printed no errors or warnings; Movie Maker frames with `--demo`
  (plus a temporary script, deleted, that ran the farmer right for 48 frames) show the
  bamboo fence, the stall with roof and noren, and the cedar bin.
- Left / next: nothing open for these props.

## 2026-10-31 — Pixel font, paper / wood HUD boxes
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: our own bitmap font in `data/font_pixel.json` (glyph rows of `#` / `.`, 7 px above
  the baseline + 2 px descenders, variable width, 1 px spacing; A-Z, a-z, 0-9 and the
  punctuation the game uses). `PixelFont` (scripts/ui/pixel_font.gd) packs it into a
  FontFile at start, keyed by code point, so kana / kanji can be added to the data later.
  The HUD (scripts/ui/hud.gd) is now nine-patch boxes of wood with a paper inside
  (PlaceholderArt `ui:` keys): a clock box top right (date, the time drawn at 2x, today's
  and tomorrow's weather icons; a winter storm shows the blizzard icon), a wooden tool bar
  bottom left (six slots with tool icons, the seed slot shows a seed bag in the current
  crop's colour, the tool in hand framed in vermilion) under a paper box with the item name
  and its count (water 32/40, seeds x2), a status box bottom right (coin + money, shipping
  bin, a rice-ball icon + stamina bar: green, yellow at 50%, red at 25%), and the message
  line in a paper strip top left that fits its text and hides after 3 s. Box positions and
  tool names live in `HudLayout` (scripts/ui/hud_layout.gd) so headless tests can read
  them without the Game autoload.
- Checked: `test_farm: OK (0 failed)` (new: the font has every glyph of the dates, tool
  and seed names and of every `message.emit` string in game.gd / farm_actions.gd, FontFile
  widths match `PixelFont.width`, line height 9, glyph rows even, the `ui:` pieces are
  drawn, boxes on screen and apart, the longest date fits the clock box). Putting a `€`
  into the checked text made it print `FAIL: font has the HUD's glyphs (missing '€')`.
  Headless `--quit-after 300` printed no errors or warnings. Movie Maker frames with
  `--demo` and `--demo --weather=rain` show the new boxes (one run, with a throwaway
  autoload since removed, showed the seed slot, a long message and a half stamina bar).
- Left / next: no Japanese glyphs yet; tool slots have no key numbers; the turnip seed
  bag's label is pale on the bag.

## 2026-10-31 — Rain / snow particles and weather tint
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: `WeatherFX` (scripts/world3d/weather_fx.gd) puts CPUParticles3D around the camera
  target: rain as 1 x 8 streaks aligned to their velocity with splash rings on the ground,
  snow as 4 x 4 flakes (billboards) that drift. Particles live in world space and fade in /
  out, the volume is shifted towards the camera because high particles show farther away.
  The look per weather is data (`data/weather_fx.json`: tint, amount, fall speed, wind);
  a storm in winter uses the "blizzard" look (`Game.weather_look`). The old rain darkening
  (x 0.8) is now the data tint times the day light, so the 2D view gets it too. Numbers:
  rain tint c4cfe0 (cool grey-blue), storm 97a2b8 (heavier, wind 4 so the rain slants),
  snow e4eaf5 (barely cooler), blizzard a9b3c6. `-- --weather=<kind>` forces today's weather.
  Rain particle sprites come from PlaceholderArt (`fx:rain|snow|splash`).
- Checked: `test_farm: OK (0 failed)` (new: every weather in weather.json has a look,
  winter storm = blizzard, rainy noon light = rain tint, storm darker, fx sprites drawn);
  headless `--quit-after 300` printed no errors or warnings; Movie Maker frames with
  `--demo --weather=` rain, storm, snow and blizzard show streaks + splash rings, slanted
  storm rain, flakes, and the tints. Thinner streaks (0.025) broke up at 480 x 270, so
  they are 0.05 wide.
- Left / next: no snow lying on the ground, no lightning; pixel font / HUD box next.

## 2026-10-31 — Japanese farmhouse
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the house follows ROADMAP "Mood and tone" now: dark charred-board skirting, white
  plaster between dark timber posts and beams, a grey-blue kawara tile roof (rows of
  rounded tiles running down the slope) with a heavy ridge cap and raised ends, an engawa
  plank veranda along the front under the eaves (walls moved back to z 3.6 inside the
  same footprint, so collision is unchanged), two eave posts, a step stone, a shoji sliding
  door over the door cell and shoji windows. The western chimney, board wall, shingle
  roof, plank door and glass window surfaces were removed. The eave ends at about z 4.05,
  1.45 high, so it stays above the farmer on the cell in front of the door.
- Checked: `test_farm: OK (0 failed)` (the building-surface check now lists the new
  surfaces); headless `--quit-after 300` printed no errors or warnings; Movie Maker frame
  with `--demo` shows the new house with the farmer in front of the engawa.
- Left / next: fence, seed-stand awning and bin are still western (listed in ROADMAP).

## 2026-10-31 — Mood and tone: Japanese countryside
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: at the user's request, ROADMAP got a "Mood and tone" section: the game should feel
  like rural Japan (satoyama village, Japanese buildings, nature, festivals, food, music
  and UI), with our own designs. The current western-style house and fence should move
  that way when next touched.
- Checked: docs only.
- Left / next: ROADMAP → Next up (rain / snow particles and weather tint).

## 2026-10-31 — Textured house, shipping bin, seed stand and fence
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the user said the farmer still looks a bit odd but asked to set it aside and move
  on (noted in ROADMAP). PlaceholderArt draws building surfaces (`build:<kind>`): board
  walls, shingle roof, stone, light / dark planks, a striped awning (16 x 16 = 1 unit,
  repeated with mesh-space triplanar mapping), a door (16 x 24) and a window (12 x 10). The
  house is walls + a wall-textured gable prism + two shingled roof slabs with overhang, a
  stone chimney, the door over the door cell and windows on the +z / +x faces the camera
  sees. The bin is a dark crate with a lid and a band; the stand has a counter, posts, a
  tilted striped awning and three seed sacks. The fence is a post per border cell (one
  MultiMesh) with two rails per side.
- Checked: `test_farm: OK (0 failed)` (new: every building surface is drawn, opaque, and
  the repeating ones are 16 x 16); headless `--quit-after 300` printed no errors or
  warnings; Movie Maker frames with `--demo`: one at the start (house, door, windows, roof,
  chimney, fence) and one after a temporary script walked the farmer right for 40 frames
  (bin, stand with awning and sacks, fence); the script was deleted afterwards.
- Left / next: the house back and west faces are never seen, so they have no windows.

## 2026-10-31 — Farmer in three-quarter views, target brackets
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: after playing, the user found the walk odd (only a flat front and back, no side)
  and the white cell highlight not under the farmer. Measured with
  `Camera3D.unproject_position` while walking: Right goes to the lower right of the screen,
  Down lower left, Left upper left, Up upper right, so every direction is a screen diagonal.
  The farmer is now drawn three-quarters: the front view turned to the lower left, the back
  view to the upper left (mirrored for Right / Up as before). Steps go sideways on screen:
  contact frames spread the legs with the opposite arm forward, pass frames lift one foot.
  The highlight is the tool's target (the cell in front), by design; it is now corner
  brackets instead of a filled square so it reads as a target, with a comment saying so.
- Checked: `test_farm: OK (0 failed)`; headless `--quit-after 300` printed no errors or
  warnings; a temporary SceneTree script pressed each direction (walk, then run) under Movie
  Maker, and the frames show the farmer facing the way they move in all 8 cases, with the
  brackets on the cell in front. The script was deleted afterwards.
- Left / next: no tool-swing animation yet (milestone 3).

## 2026-10-31 — Ground tiles
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: PlaceholderArt draws 16 x 16 ground tiles: grass and path in 4 variants each (picked
  from the cell position so the field is not stamped), tilled soil with furrows (dark trench,
  lit ridge every 4 rows), wet soil much darker with a glint, pond water with ripples and a
  bank + foam line on each side that touches land (`ground:water:<mask>`). `ground_key()`
  picks the tile per cell (buildings stand on path, the fence on grass). FarmView draws these
  tiles, so the 3D ground texture and the 2D view both use them; the flat colours are gone
  except the 2D building / fence markers.
- Checked: `test_farm: OK (0 failed)` (new: tilled / wet / grass keys follow the cell, wet
  tile mean luminance at least 0.12 below dry, pond corner / middle masks, tiles fully
  opaque 16 x 16); headless `--quit-after 300` printed no errors or warnings; Movie Maker
  frames: 3D `--demo` shows wet and dry columns clearly apart and furrows visible; 2D shows
  grass variety, path under buildings and the pond with banks.
- Left / next: the pond is not in the 3D demo frame (camera starts by the house), so its
  banks were seen in the 2D view only.

## 2026-10-31 — Crop and field-object placeholders
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: rock / branch / weed / stump and every crop are drawn in the farmer's style: 2-3
  shades, then an automatic 1 px dark outline around the silhouette. Each crop has a `look`
  in `data/crops.json` (shape root / bush / vine / stalk / ground, leaf and fruit colours,
  extras like leaf style, bulb size, fruit shape, flower). Seed and sprout are shared (sprout
  in the crop's leaf colour); young, grown and ripe follow the shape. Vines and corn are
  16 x 24 with a stake / tall stalk. Keys are now `crop:<id>:<growth>:<ripe|growing>`;
  `PlaceholderArt.cell_key()` replaces FarmWorld's own key function and the 2D view draws the
  same sprites instead of circles. Cucumber leaves were lightened after the first sheet so the
  dark fruit shows.
- Checked: `test_farm: OK (0 failed)` (new: every crop has a look, all 45 crop sprites are
  16 wide and stand on their bottom row, the 9 ripe sprites all differ, cell keys for seed /
  ripe / obstacle); headless `--quit-after 300` printed no errors or warnings; a 4x sheet of
  all crops x growth looks + obstacles; Movie Maker frames of the 3D and 2D views with `--demo`.
- Left / next: the demo field shows no ripe crop (stages 1-3 of turnip / potato / cucumber);
  ripe looks were checked on the sheet only. Seasons other than spring not seen in game.

## 2026-10-31 — Farmer placeholder frames and walk / run animation
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the user chose to refine placeholders before real art. Scale check first: in a demo
  frame one sprite pixel is ~2 x 2 screen pixels (shirt 8 px tall -> 16 px on screen), so the
  16 x 24 size stays and 1 px details (outline, eyes) read. PlaceholderArt draws the farmer
  from a pixel map (head / torso, front and back) plus legs, hands and bag placed per frame,
  with a dark outline. Keys `player:<front|back>:<idle|walk|run>:<frame>`; idle 1 frame, walk
  and run 4 (contact, left step, contact, right step; body drops 1 px on contact; run lifts
  feet higher, spreads legs and swings hands more). New `FarmerAnim` picks the key: walk 8 fps
  (two steps per 0.5 s, ~1 cell per step at 60 px/s), run 12 fps; a new pose starts on a step
  frame so a key press shows at once. Player now exposes `moving` / `running`.
- Checked: `test_farm: OK (0 failed)` (8 new animation / frame checks); headless
  `--quit-after 300` printed no errors or warnings; a 6x frame sheet of all 18 frames looked
  right after two fixes (hands needed an outline and to sit against the body); demo Movie
  Maker frame shows the new farmer idle by the house.
- Left / next: walking was not seen in a movie frame (needs key presses); it was checked on
  the frame sheet and in the tests only. No real-key play yet.

## 2026-10-31 — Handoff docs
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: AGENTS.md (rules incl. clean room, how to run / test / screenshot, code layout, what
  to do after each change), CLAUDE.md, ROADMAP.md (10 milestones, Next up), this log.
- Checked: docs only. Commands in AGENTS.md are the ones used in the entries below.
- Left / next: ROADMAP → Next up (farmer sprites).

## 2026-10-31 — 3D view with Back to Nature's field camera
Agent: Claude Code (claude-opus-5-5) · Commit: 5a5eadd
- Done: the main scene is 3D (`main_3d.gd`, `world3d/farm_world.gd`). Camera: yaw 45°, pitch
  26.6°, eye 25.2 cells from the player, vertical FOV 13.69°. These are taken from the RE
  project's NOTES.md (GTE R / H = 1000 / TR depth 10087 from the ePSXe save state; 400 PS1
  units = 1 cell). Movement stays on the field axes in 4 facings, as measured there (Up walks
  diagonally away). Ground = FarmView (ground only) in a SubViewport texture. Rocks, branches,
  weeds, stumps, crops and the farmer are billboard Sprite3Ds from PlaceholderArt. The farmer
  uses the front image for Down / Right and the back image for Up / Left, with Right / Up
  mirrored. House / bin / stand / fence are boxes. Day / night = a multiply ColorRect under
  the HUD. Shared action code moved to `farm_actions.gd`. The 2D view is kept as
  `scenes/main_2d.tscn`. `-- --demo` starts at 10:00 with planted plots.
- Checked: `test_farm: OK (0 failed)`; Movie Maker frames with and without `--demo` show the
  diamond field, sprites and wet / dry soil with no errors. Sky pixel at 6:01 (102, 144, 200)
  vs computed (102, 143, 200).
- Left / next: not played with real key presses yet. Camera clamp margins (4, 3) are a
  guess. The 3D view rebuilds every object sprite on any cell change (fine at 640 cells).

## 2026-10-31 — v0: core farming loop and design doc
Agent: Claude Code (claude-opus-5-5) · Commit: 50a8a8b
- Done: Godot 4.7 project. Game autoload (clock 0.5 s / minute, day at 6:00, 4 x 30 days,
  weather a day ahead from `data/weather.json`, money, bag, stamina, sleep / pass out at 2:00,
  payout at 18:00). FarmGrid 32 x 20 (till, water, 3 x 3 sowing, growth on watered nights,
  regrowth, out-of-season withering, weeds 1 %, storm loss 1/16, obstacles with tool + hit
  counts). Crops in `data/crops.json` (9 crops, our own numbers). Player (8-way move, 4 facings,
  tile collision), HUD, seed stand, pond refills the can. docs/DESIGN.md = copy of the online
  design doc (rev 8).
- Checked: `tests/test_farm.gd` → `test_farm: OK (0 failed)` (16 checks); a headless run of
  300 frames gave no errors; a Movie Maker frame showed the farm, buildings, player and HUD.
- Left / next: balance numbers are first guesses; no save / load; placeholder drawing only.
