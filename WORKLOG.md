# Harvest Son — work log

Newest first. Format per entry:

```
## YYYY-MM-DD — <title>
Agent: <agent / product> (<model>) · Commit: <hash or "this commit">
- Done: what changed.
- Checked: how it was verified (test output, screenshot, pixel values).
- Left / next: what is still open.
```

## 2026-11-01 — Leftovers: tool level 5 perk, the storm morning's word, kitchen tools in balance.py
Agent: Claude Code (claude-opus-5-5) · Commit: 9461b44
- Done: (1) Level 5 of a charging tool added no charge step (max_charge ends 4, 4). Now it is
  the master level: data/tools.json `master` {level 5, stamina_pct 60, level_up text} makes a
  swing cost 60% of its charge step's stamina, rounded up, at least 1 (`Game.swing_stamina`,
  `Game.is_master`; used by FarmActions.use_tool and Game.mine_swing). Work fatigue per swing
  stays; the overwork fatigue from missing stamina drops with the cost. The level 5 level-up
  message adds " It hardly tires you any more." Why 60%: the top hoe swing (10) becomes 6, the
  level 4 cost of a smaller area, so the full 3x5 area is worth using all day; a 1-stamina
  swing stays 1. The rod keeps its own levels (bite factor), no perk. (2) The morning a job is
  under way and Hachiro's day plan isn't `building`, end_day sets `Game.build_news` from
  data/shops.json builds `off_day` (by the plan that keeps him: `forge` = the storm text,
  `birthday` = his birthday text; our wording, e.g. "Word from the smithy: \"Too wild out to
  raise beams. No building today; the kitchen corner will be a day late. -Hachiro\""). It is
  told once, in `map_arrived` on the first map that isn't the house (the wake-up message would
  cover it at once in the house); not saved. `_count_build_day` and the news share
  `_builder_off_plan()`. (3) tools/balance.py: the plan buys each kitchen tool (data/recipes.json
  tools) in the first season COOKED needs it, a one-off "tools" cost column in the season
  table; the recipe table has each recipe's tool cost and "pays" (cookings at its best
  season's gain to earn the tools back; shared tools counted in full).
- Checked: test_farm (master stamina in the rules and on the real Game's hoe, level 4 full
  cost, 1 stays 1, rod / seeds no perk, the level 5 message), test_shops (the storm morning:
  word waiting, not told in the house, told on the farm, told once; a fair morning has none;
  every off_day key is a plan of the builder). All 24 test scripts print `OK (0 failed)`;
  headless `--quit-after 300` title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --building=kitchen --weather=storm --map=farm`: no errors or warnings. `python -I
  tools/balance.py` (before: summer net 19007, fall 33523, year net 105874 G):
  ```
   season |   crops |    cook |    eggs |    milk |    wool |    fish |    mine |   prize |  income |   seeds |    feed | animals |   tools |   other |     net
   spring |   10260 |       0 |    3792 |       0 |       0 |    2797 |     205 |     476 |   17531 |    2380 |     590 |    2800 |       0 |    2050 |    9711
   summer |   18828 |     576 |    7492 |    2616 |       0 |    3501 |     970 |     295 |   34279 |    3016 |    1406 |    8800 |    1500 |    2050 |   17507
     fall |   30758 |    1525 |    8325 |    5886 |    1981 |    3442 |    2062 |     406 |   54384 |    7060 |    2151 |    9600 |    4700 |    2050 |   28823
   winter |       0 |    1382 |    8325 |    9810 |    2830 |    4161 |   22221 |     464 |   49193 |       0 |    4410 |       0 |       0 |    1150 |   43633
  year net 99674 G (mine: finds shipped, less the ores kept for the smithy; tools: kitchen tools, once)

   summer: bought upgrade hoe 2 (1000), kitchen (6500), upgrade sickle 2 (1000), upgrade can 3 (2500); 10717 G left; ores kept 248 G
     fall: bought rucksack 2 (6500), room (18000); 15040 G left
   winter: bought upgrade hoe 3 (2500), upgrade can 4 (5000), upgrade hammer 2 (1000); 50174 G left; ores kept 494 G

             recipe | spring | summer |   fall | winter |  tools |  pays
        turnip_stew |     45 |     45 |     45 |     45 |   1500 |    34
        potato_stew |     55 |     55 |     55 |     55 |   1500 |    28
           ochazuke |     32 |     17 |     18 |     47 |    400 |     9
   simmered_pumpkin |     60 |     60 |     60 |     60 |   1500 |    25
       milk_pudding |     60 |     60 |     60 |     60 |   1500 |    25
    furofuki_daikon |     30 |     30 |     30 |     30 |   1500 |    50
        daikon_fish |     52 |     37 |     38 |     67 |   1500 |    23
     takikomi_gohan |     65 |     65 |     65 |     65 |   1800 |    28
       kinako_mochi |     65 |     65 |     65 |     65 |   2000 |    31
  ```
  (start recipes need no tools: "-"; spring line and the contest table unchanged.)
- Left / next: in year 1 the plan's cooking (3483 G over raw) doesn't pay back its 6200 G of
  tools; they pay off in year 2, or cheaper tools / dearer dishes if a playtest finds cooking
  not worth it. No screenshot of the storm word (it needs a real night; `--building` starts the
  job without one).

## 2026-11-01 — Merged six branches: building fixes, 2D weather, heart actors, stalls, river, yearly record
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time, all tests after each: `claude/building-fixes-32aab9`
  (a45b4cf), `claude/view2d-weather-3f603c` (0aa5bea), `claude/heart-actors-57fa63` (23e7c76),
  `claude/festival-stalls-2-3fff25` (eae7754), `claude/river-fishing-6316ec` (19eee8c),
  `claude/ending-yearly-9bd17d` (cc830c2). WORKLOG conflicted each time (entries kept, their
  "this commit" now name the hashes). The river merge conflicted in the four villager files
  (both branches added gifts: the keepsakes and the river fish are both kept, Hachiro's note
  keeps the storm-day line and the salmon) and in ROADMAP's fishing paragraph (the river text
  with the 2D view's weather sentence). The yearly record merge conflicted in
  `EventRunner` validation (the `face` step keeps villager targets, the new `ending` step keeps
  its page check). Two checks were flaky on the randomly rolled field and failed after the
  merges: test_maps asked `is_solid` for the cells beside the lumber (a rock or weed may lie
  there; it now asks `under_prop`), test_ending wanted more than 50 debris on the first day
  (a roll gave exactly 50; now more than 20).
- Checked on merged main: all 24 test scripts print `OK (0 failed)`; headless runs (title
  `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --fishing=river`, `--demo --festival=moon_night`, `--demo --ending`, `--demo
  --event=heart_kota_6`, `--demo --building=kitchen --flags=kota_streamer --time=10:00`,
  `main_2d.tscn -- --demo --weather=storm`, `res://scenes/main.tscn --quit-after 400`) printed
  no errors or warnings. Screenshots: `--demo --building=kitchen --flags=kota_streamer
  --time=10:00` (Hachiro at the wall, the lumber, the streamer) and the flat view at
  `--festival=moon_night` (lanterns glowing, villagers out); `shots/` deleted.
- Left / next: a person has to listen to the music; a playtest of a real year; the .exe once
  the export templates are installed.

## 2026-11-01 — Building fixes: solid lumber on the farm, a storm day doesn't count
Agent: Claude Code (claude-opus-5-5) · Commit: a45b4cf
- Done: the two open points of "Hachiro seen at work while building". (1) Farm map props can
  be solid now: the farm's collision is FarmGrid's, so FarmGrid has `prop_blocks` (a Callable,
  not saved) that Game points at the farm map (`Game.farm_prop_blocks`: MapData's solid cells,
  i.e. the props the story flags show, with `solid` true or left out). `FarmGrid.is_solid`
  and `can_farm` ask it (`under_prop`), so the farmer in both views (Player asks
  Game.maps), the dog and throws stop at the prop, nothing is tilled, watered or put down
  under it, and no weed grows there at night. In data/maps/farm.json the lumber ([1,4]-[1,5])
  and Kota's carp streamer pole ([1,6]) are solid; the bell on the house wall stays `solid:
  false`. Hachiro's farm walks keep to x >= 2, so his path is unchanged; the props stand
  outside the field (rows 7+), and a crop someone planted there before stays in the cell's
  data and grows back into view once the prop goes. (2) A day of the job that the builder
  spends on another day plan doesn't count: data/shops.json builds `plan` names his building
  plan ("building"); `Game._count_build_day()` runs in end_day before the date moves and, when
  BUILD_FLAG is set and `Villagers.pick_plan` for the day gave another plan (a storm keeps him
  at the forge; his birthday would too), pushes `house_job.ready` a day and counts `late`
  (saved in the house job, optional, 0..9999; older saves have none). `sync_build_flag`
  subtracts `late` so the flag still starts on the morning after the order. The smithy note
  becomes builds `away_late` ("...The storm cost me a day; done on Spring 5. -Hachiro"), the
  store's build tab row carries `late` and its info line says builds `late` ("Done on <date>, a
  day late: a storm kept Hachiro at the forge.").
- Checked: `test_maps.gd` (with the lumber and the streamer flags the cells [1,4], [1,5], [1,6]
  are solid in FarmGrid and Game.maps, not farmable, not tillable; [2,4], [2,5], [1,7] open; the
  bell's prop not solid; a throw left at the lumber lands on [2,5]; 400 nights grow no weed
  under them but one beside; the lumber can still be examined; open again without the flags),
  `test_villagers.gd` (his building walks miss the solid prop cells as well as the fixed ones;
  in the farm view test the lumber blocks the farmer and is gone after the job), `test_shops.gd`
  (a storm on the order day costs nothing; a storm on day 1 moves the kitchen to day 4 with
  late 1; the smithy note and the build tab text; saved, loaded, broken late values refused;
  not done on day 3, done on day 4; a rain day still counts for the chest).
  All 24 test scripts print `OK (0 failed)`; headless runs (title `--quit-after 300`, `--demo`,
  `--demo --map=town`, `--demo --mine=3`, `--demo --building=kitchen --time=10:00`, `--demo
  --map=smithy --building=chest --shop=smithy`, `res://scenes/main.tscn --quit-after 400`,
  `main_2d.tscn -- --demo --building=kitchen`) printed no errors or warnings. Screenshot `--demo
  --building=kitchen --time=10:00`: Hachiro hammering at the wall, the lumber left of him as
  before; `shots/` deleted.
- Left / next: no player-facing message on the storm morning itself (the note and the build tab
  say it); the farm's other props (the bell) still not solid by design.

## 2026-11-01 — The flat view gets the weather and festival lights
Agent: Claude Code (claude-opus-5-5) · Commit: 0aa5bea
- Done: `scenes/main_2d.tscn` now shows what the 3D view shows for weather and festivals, reading
  the same rules. New `WeatherView` (scripts/world/weather_view.gd): rain streaks with splash
  rings, or snow, from `Game.weather_style()` (amount, speed, wind), in the canvas so the day /
  night tint (which already carries the weather tint) falls on them, kept over the screen by
  `follow`; outdoors only (`Game.sheltered()`), redone on map change and each morning. Amount is
  the 3D look's x0.25 (`WeatherView.AMOUNT`, by eye: the screen shows less ground than the 3D
  volume), a drop streaks 0.45 s, a flake drifts 4 s. Lightning: the same `Lightning` timer and
  thunder, a flash ColorRect added over the picture under the HUD; the flash colour is now
  `Lightning.flash_color` (main_3d uses it too), and the flashes setting / `--no-flashes` turn it
  off through `Game.lightning_style()` as before. Festival lights: `FestivalProps.glows_of`
  lists a festival's lights without keeping the meshes; `FestivalView` keeps them flattened onto
  the ground in `glows` (group `festival_view`) and `FestivalGlow` draws them in the flat view as
  well (plus its fireworks, unchanged). Fix on the way: main_3d's settings change re-armed
  lightning under a roof (the mine); both views now keep it off when sheltered.
- Checked: tests/test_view2d.gd has 16 new checks (no rain or lightning down the mine, storm rain
  and splashes in the village with the look's amount, the tint, a flash within 10 s, no flash
  while the clock stands, none with flashes off, winter storm = snow, the emitters follow the
  camera, Lantern Night's FestivalView with the same light count as the 3D props, the glow layer
  and fireworks on, sunny = nothing falls). All test scripts print `OK (0 failed)`; headless smoke
  runs printed no errors. Screenshots of `main_2d.tscn -- --demo --weather=storm` (slanting rain,
  splash rings, the dark storm tint; frame 121 is a flash, the HUD not lit) and `--demo
  --festival=lantern_night` (glows round each lantern of both strings, two fireworks over the
  shrine); `shots/` deleted.
- Left / next: the flat view's festival decorations are still flat boxes; the particle amount
  was set by eye on one screenshot each.

## 2026-11-01 — Villagers act in their heart scenes
Agent: Claude Code (claude-opus-5-5) · Commit: 23e7c76
- Done: all 12 heart events (`heart_<id>`, `_5`, `_6` for Tome, Kota, Sayo, Hachiro) start
  with `{"do": "actor", "who": "<id>", "at": "plan", "face": "farmer"}` and `{"do": "face",
  "dir": "<id>"}`, and end with `"to": "plan"` and `leave`, so the villager stands facing the
  farmer through their lines and then goes back to their day plan. EventRunner, generally:
  `on_stage` (the villagers on the event's map as it starts; EventPlayer fills it from
  `Villagers.on_map`); actor `at` may be `"plan"` (their spot from `on_stage`; when their
  plan has them on another map they come in `COME_IN` = 4 cells beside the cell in front of
  the farmer, on the side away from the farmer, and walk up by themselves); `to` may be
  `"farmer"` (the cell in front of the farmer) or `"plan"` (back where `at: plan` put them);
  `face` may be `"farmer"`; the farmer's `face` step takes a villager id (turn to that actor).
  Two fixes the scenes needed: an actor step's `face` now turns them after its walk (before,
  the walk's direction overwrote it; no existing event had both), and an actor walk turns its
  corner the other way round when the corner would be the farmer's cell. README → Events.
- Checked: test_events (Kota on stage: stays put, faces the farmer, never walks, gone at the
  end; off stage: comes in from the left, walks up, both face each other for the lines,
  walks back off; Tome's walk round the farmer; 5 new refused steps) and test_relationships
  (every heart event, on stage and off: the villager stands still facing the farmer, and the
  farmer them, each time a line opens; walked only when off stage; no actors after). All 24
  test scripts print `OK (0 failed)`; headless runs (title `--quit-after 300`, `--demo`,
  `--demo --map=town`, `--demo --mine=3`, `--demo --map=town --time=10:00 --event=heart_tome`,
  `--demo --map=smithy --time=10:00 --event=heart_hachiro_6`, `res://scenes/main.tscn
  --quit-after 400`) printed no errors or warnings. Screenshots `--demo --event=heart_kota_6`
  in 3D (1 s: Kota walking up; 3.3 s: his line open, Kota in front of the farmer facing him)
  and the flat view (Kota below the farmer facing up), and `--demo --map=smithy --time=10:00
  --event=heart_hachiro_6` (Hachiro behind his counter facing the farmer); `shots/` deleted.
- Left / next: no gestures yet (the scenes only stand and talk); a talk across a shop
  counter keeps the keeper behind it, which is what we want.

## 2026-11-01 — Stalls at Moon Night and Year's Turn; keepsakes as gifts
Agent: Claude Code (claude-opus-5-5) · Commit: eae7754
- Done: Moon Night gets two stalls on the same spots as Lantern Night's first two ([9, 7] navy,
  [13, 7] amber; clear of the moon offering and the judges' table): Moon Craft Stall
  (`stall:moon_night:crafts`: clay rabbit 240 G, moon lantern 160 G) and Chestnut Roaster
  (`stall:moon_night:eats`: roast chestnuts 90 G, baked sweet potato 130 G). Year's Turn's white
  stall at [14, 2], until now only a look, becomes Year-End Soba Stall (`stall:years_turn:soba`:
  year-end soba 160 G, hot yuzu tea 70 G), and a new red stall at [22, 2] by the bonfire is the
  Lucky Charm Stall (`stall:years_turn:charms`: daruma 280 G, omamori charm 150 G). Four
  stall-only foods (data/foods.json, `shop` false with a price) and four keepsakes
  (data/keepsakes.json), all names ours. The stand already sells amazake, so the soba stall pours
  yuzu tea instead. New icon shapes in PlaceholderArt: foods `bag` (a paper bag of chestnuts)
  and `imo` (a split sweet potato); keepsakes `rabbit`, `lantern`, `daruma`, `charm`.
  Keepsakes as gifts: they could already be held and given, so this is data: each villager loves
  one keepsake (Kota the clay rabbit, Tome the omamori, Sayo the wind chime, Hachiro the
  daruma), likes a few, and two dislike one (Hachiro the tinkling chime at his forge, Sayo the
  daruma, Kota the omamori: he wants a toy). Some stall foods are liked too (Kota chestnuts and
  sweet potato, Tome yuzu tea and sweet potato, Sayo yuzu tea, Hachiro soba and chestnuts).
  Ribbons stay off the lists (neutral).
- Balance reasoning: stall food is priced like Lantern Night's: the price buys about as much
  stamina per G as the stand's food or a little less (it is a treat, bought on the night):
  chestnuts 15 stamina for 90 G (a snack, like shaved ice), sweet potato 30 for 130 G and soba 35
  for 160 G (meals, like yakisoba at 35 for 150 G), yuzu tea 8 for 70 G with a bigger fatigue
  drop (-6, a warm drink on a cold night, like marble soda). Keepsakes cost 150-280 G, between the
  paper fan (120) and the wind chime (300); a loved keepsake (+8) costs more than a loved dish
  the farmer cooks, but can be had without a kitchen, once a year at the festival.
- Tests: test_festivals `_fall_winter_stalls` (both festivals' stalls, hours, prices, E in front
  of each, shut outside the hours, a keepsake bought to keep, every keepsake icon drawn and
  different, the new food shapes); test_relationships `_keepsake_gifts` (the listed keepsakes
  exist, every villager loves exactly one, every keepsake is liked somewhere, a ribbon is
  neutral) and `_keepsake_gift_in_game` (a wind chime overhead given to Sayo: gift_love, +8,
  gone from the hands); test_food knows the two new icon shapes.
- Checked: all 24 test scripts print `OK (0 failed)` (test_food failed 2 checks, "has a known
  icon shape", until its shape list had `bag` and `imo`). Headless `--quit-after 300` runs (title,
  `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --festival=moon_night`, `--demo
  --festival=years_turn --time=21:00`, `main_2d.tscn -- --demo --festival=moon_night`) printed no
  errors or warnings. Screenshots `--demo --festival=moon_night --shop=stall:moon_night:crafts`
  and `--festival=years_turn --shop=stall:years_turn:charms`: the screens list "Clay rabbit 240 G
  / Moon lantern 160 G" and "Daruma 280 G / Omamori charm 150 G" with their icons, "Open
  18:00-23:00, Moon Night only" / "Open 19:00-24:00, Year's Turn only"; a Moon Night scene frame
  at 19:00 shows the stalls lit by the shrine; `shots/` deleted.
- Left / next: villagers' own talk lines about a keepsake given (they answer with the plain gift
  lines); the keepsakes are not seen in the world after they are given.

## 2026-11-01 — River fishing
Agent: Claude Code (claude-opus-5-5) · Commit: 19eee8c
- Done: a new map `river` (data/maps/river.json, 20 x 14): the lane behind Kota's house now runs
  down column 4 off the village's south edge (town door `[3..5, 22]`, spawn `river`), a grassy
  slope to a gravel shore, the river across the whole map (rows 6-9), three stepping rocks
  (`river_rock`, new prop: boulders and a pale water line in 3D, a grey box in the flat view)
  and pines on the far bank. A map of its own rather than more water in the village: the
  village has no room for a river without moving houses that day plans and events use, and
  fish tables already key on the map id (place `river` in data/fish.json), so casting,
  catching overhead, the rucksack and the save needed no code. `MapView.ground_key` (both
  views) draws no bank where water meets the map's edge, so the river flows on.
  Fish (ours, data/fish.json): Dace `ugui` 40 G all year (the common one, so every season /
  hour / weather has a bite), Pale chub `oikawa` 55 G spring-fall 5-19h, River sculpin
  `kajika` 90 G winter / spring at night (17-7h), Autumn salmon `sake` 450 G in fall by day
  (x1.5 in rain / storm: the run comes up on high water), River elder `nushi` 2500 G, once
  only, summer dawn (3-7h) in rain or storm. The stream fish bite more in the river than in
  the village pond (ayu 40, yamame 25, iwana 18, unagi 8 vs 30 / 15 / 8 / 6); no pond fish
  (crucian carp, loach, smelt) in it. Reasoning: dace slightly above crucian carp (30) since
  the walk is longer; the salmon is the river's season prize like ayu is summer's; the elder
  sits just above the moonlit koi (2000) and is harder to time.
  Food: every fish eats through foods.json `fish:*`, checked for a river catch. Gifts: Kota
  loves the river elder (and likes any fish via `fish:*`), Hachiro loves the fall salmon, Tome
  likes the salmon and sweetfish, Sayo dislikes the bony dace (with loach and crucian carp).
  CLI `--fishing=river` (or `river:wait`) stands on the shore with the line out (AGENTS.md,
  README → controls and Maps).
- Checked: test_fishing (river data, seasons / hours / weather, the once-only elder, the
  lane door from the village, a cast from the shore, 30 catches all river fish, overhead and
  into the rucksack, edible, the gift reactions) and test_maps (doors both ways, edge banks,
  rocks in water, the river builds in 3D with no stand-ins) print OK; all 24 test scripts
  print `OK (0 failed)`; headless runs (title, `--demo`, `--demo --map=town`, `--demo
  --mine=3`, `--demo --map=river`, `--demo --map=town@river`) printed nothing. Screenshots
  `--demo --fishing=river` in 3D and in `main_2d.tscn`: the farmer on the shore, the bobber
  in the current, "!" over the head, the river running off both sides; `shots/` deleted.
- Left / next: no villager visits the river yet (Kota or Hachiro could fish there on
  Sundays); no river ambient sound (it uses `outdoor`).

## 2026-11-01 — Yearly pages of the village record, the first day beside today
Agent: Claude Code (claude-opus-5-5) · Commit: cc830c2
- Done: every New Year now has a page. `Game.end_day` sets the flag `record_due` when the year
  turns; a `day_start` row after the ending's in `triggers_house.json` (`once: false`, flag
  `record_due`) plays the new event `year_record` (Tome comes in, greets, shows the page, says a
  line and leaves; `data/dialogue/year_record.json`, our text), so year 3 still gets the full
  ending and years 2 and 4+ the short page. Year 2 does get a page: the farmer's first, with its
  own line (`record_first`, only in year 2); later years say `record_more` (more stars than the
  last page) or a steady-year line. Event step `{"do": "ending", "page": "year"}` (EventRunner
  checks the page). `Game.show_ending(page)` grades as before, then `Ending.compare` puts the
  first day's number (`then`, -1 when unknown) and the gain since the latest earlier page
  (`gain`) beside each row, adds the field rows (`field` in data/ending.json: weeds and rocks,
  tilled soil, money from `Game.field_counts()`), and writes `Game.year_pages[year]`
  (`Ending.page_of`: values, field, stars, rank). The look back: `new_game` keeps
  `Game.first_day` (the record's numbers and the field counts) before `--demo` digs the field.
  The EndingScreen is 360 px wide with columns First day / Now / Gained (Gained hidden without an
  earlier page), the field rows under a rule with no stars, and a heading line "A page for the
  farmer" (ending) or "The farmer's page, year N"; `-- --ending=year` opens the yearly page.
- Save: no version bump (still 5). The run state goes in a new key `records` = {first_day,
  pages: [page, ...]} (checked by `Ending.parse_kept`); a save without it (any older one) loads
  with no page and the start's numbers as the first day (`Game.start_values()`, money
  `START_MONEY`), the field's debris and tilling unknown and shown as "-".
- Checked: all 24 test scripts print `OK (0 failed)` (test_ending: compare / gains / pages /
  the trigger / first day / the yearly event / the screen's columns and widths; test_save: the
  round trip, seven broken `records`, a save without them). Mutating `gain_text` and the page
  parse made 5 test_ending and 2 test_save checks fail, then restored. Headless runs (title
  `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --ending`,
  `--demo --ending=year`, `--demo --map=house --event=year_record`, `--demo --map=house
  --event=ending`, `res://scenes/main.tscn --quit-after 400`, `main_2d.tscn -- --demo --ending`)
  printed no errors or warnings. Screenshots `--demo --ending` and `--demo --ending=year`
  (frame 89): both headings, First day / Now columns, the field rows (weeds and rocks 51 -> 54,
  tilled 0 -> 27, money 500 G -> 500 G on the demo field), the box fits the 480x270 view;
  `shots/` deleted. The Gained column was not seen on screen (no earlier page in a demo run);
  its text and column widths are checked in test_ending.
- Left / next: real art for the scroll; a person should read a yearly page in a played run.

## 2026-11-01 — Merged six branches: music, 2D actions, cooking tools, band 6, festival stalls, Hachiro building
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time, all tests after each: `claude/music-shops-events-bbe890`
  (d6289eb, clean), `claude/view2d-actions-d5c8d6` (c62eb4b), `claude/cooking-tools-7e74bb` (33b28aa),
  `claude/heart-band6-9d88b6` (6479d92), `claude/festival-stalls-4ae036` (22082ca),
  `claude/hachiro-building-e4bbf1` (de398ee); WORKLOG conflicted each time (entries kept, their
  "this commit" now name the hashes). Fixes the branches needed together: the heart music rule in
  `data/music.json` now lists the four `heart_<id>_6` events (test_audio checks every heart event
  file and failed 4 checks after the band 6 merge); the story prop kinds (StoryView.KINDS,
  MapWorld, StoryProps, PlaceholderArt `story:` keys) keep the carp streamer, the ribbon board and
  the lumber; `game.gd` keeps `kitchen_tools` and `BUILD_FLAG`; the store's `_about` keeps both
  notes. Kota's carp streamer and Hachiro's lumber were both on farm cell [1, 4]; the lumber stays
  (Hachiro's building day plan works beside it) and the streamer moved to [1, 6], the front left by
  the fence (tried [1, 2] first: the house hides it from the camera); test_maps follows.
- Checked on merged main: all 24 test scripts print `OK (0 failed)`; headless runs (title
  `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --cook`,
  `--demo --festival=lantern_night`, `--demo --building=kitchen`, `--demo --event=heart_kota_6`,
  `--demo --shop=smithy`, `--demo --flags=kota_streamer`, `main_2d.tscn -- --demo`,
  `res://scenes/main.tscn --quit-after 400`) printed no errors or warnings. Screenshot `--demo
  --building=kitchen --flags=kota_streamer,hachiro_bell --time=9:00`: Hachiro by the lumber at the
  house front, the bell by the door, the streamer at the front left corner, all in view; `shots/`
  deleted.
- Left / next: a person has to listen to the new music; the playtest of a real year (with the
  kitchen tools' cost); the .exe once the export templates are installed.

## 2026-10-31 — Hachiro seen at work while building
Agent: Claude Code (claude-opus-5-5) · Commit: de398ee
- Done: while a house extension is under way the story flag `house_work` holds its id
  (`Game.BUILD_FLAG`, set by `Game.sync_build_flag` at day start, on load and when a job
  finishes; from the morning after the order to the ready day, so ordering at the store never
  teleports Hachiro mid-day). His file has a `building` plan picked by
  `{"flags": ["house_work"], "weather": [sunny, rain, snow]}` right after the birthday rule
  (Sundays too, since the job has a due day; a storm keeps him at the forge): out the village
  road's west end at 7:30, along the farm's row 5 to the cell left of the door, hammering at
  the farmhouse wall from about 8:20, every 40 minutes a few minutes at the lumber, lunch at
  12:00, back at the smithy by 18:00. New day plan step `{"work": minutes}` (a wait in the work
  pose; DayPlan.where gives `working` / `worked`), sprite key `villager:<id>:<side>:work:<0|1>`
  (hammer raised over the shoulder, then the blow with a 1 px dip; PlaceholderArt), 2 blows a
  game minute (`work_strokes_per_minute` in _common.json, by eye: a steady beat at 0.25 s);
  both villager views play the new `build_knock` sound (a short wooden knock, data/sfx.json)
  on each blow. A talk turn puts the hammer down. Farm map prop `lumber` (cells 1,4-1,5, gated
  on `house_work`, examine message): boards on bearers with a saw, boxes in 3D (StoryProps),
  `story:lumber` in the flat view (StoryView). First placed between the house's west wall and
  the fence, but there the 3D eave hid it, so it moved in front, left of where he works.
  Three talk lines `build_1..3` while he works (08:00-17:00 with the flag). The smithy's
  counter respects it through the keeper rule (he is not on the smithy map), and now says the
  builder's note `builds.away` in data/shops.json (`Game.keeper_away_text`) instead of
  "Nobody is at the counter". CLI `--building=<id>` (AGENTS.md, README → Shops).
- Checked: new checks in `test_villagers.gd` (work steps, work frames and keys, the art's two
  hammer frames for everyone, the building day: road at 7:45, at the wall working at 10:00,
  fetching boards, lunch, afternoon, home, Sunday, storm, birthday; his farm walks miss every
  FarmGrid fixed cell; both views on the farm the morning after an order show him in the work
  pose at (2.5, 4.5) and the lumber, gone with the flag once built) and `test_shops.gd`
  (order day no flag and the smithy open; day 1 the note at the smithy, the store open, a
  storm opens the smithy; the talk pick; the flag saved, loaded, cleared on load without a
  job; done on day 3, the counter back). All 23 test scripts print `OK (0 failed)`; headless
  runs (title `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --building=kitchen --time=10:00`, `--demo --map=town --building=room --time=7:50`, `--demo
  --map=smithy --building=chest --shop=smithy`, `res://scenes/main.tscn --quit-after 400`,
  `main_2d.tscn -- --demo --building=kitchen`) printed no errors or warnings. Screenshots
  `--demo --building=kitchen --time=10:00` in 3D (Hachiro with the hammer raised at the wall,
  the board stack with its saw left of him) and the flat view (both at the house's left);
  `shots/` deleted.
- Left / next: the farmer can walk through the lumber on the farm (farm props aren't solid;
  the farm's collision is FarmGrid's); the job's day count still finishes overnight whether
  or not he worked (a storm day).

## 2026-10-31 — Lantern Night stalls that sell, contest ribbons and the ribbon board
Agent: Claude Code (claude-opus-5-5) · Commit: 22082ca
- Done: a festival's `stall` may be a list of stalls, each with an `id`; the shop id is
  `stall:<festival>:<stall id>` (`stall:<festival>` for a lone stall without an id, so Blossom
  Day is unchanged). `Festivals.stalls / stall_of / stall_at / stall_of_prop`, the data check
  refuses a repeated or bad stall id; `Game.open_stall(shop_id)` opens the stall E is pressed
  at (`FarmActions.festival_spot`). Lantern Night: the red stall at (9, 7) is the Night Eats
  Stall (new foods, only sold at a stall: yakisoba 150 G / +35 stamina, shaved ice 80 G / +8
  and -6 fatigue, marble soda 60 G / +6 and -4 fatigue; priced near the stand's dango and
  sakura mochi for what they give, shaved ice and soda are the cooling ones), the yellow one
  at (22, 7) the Wind Chime Stall (keepsakes: wind chime 300 G, paper fan 120 G, a treat with
  no use, so priced like a few snacks). A selling stall sets its stock out on its counter
  (item icons, 3D sprites and flat view). New `data/keepsakes.json` and `Keepsakes`
  (scripts/items/keepsakes.gd): keepsakes `keep:<id>` and ribbons `ribbon:<festival>:<place>`
  have names and icons (a glass chime, a round fan, a rosette per place: red, white, blue like
  the judges' table) and are never eaten, shipped or sold (no sell price, the store doesn't
  buy them, the bin leaves them). `Game.enter_contest` gives a ribbon for 1st to 3rd on top
  of the prize and notes it in the story flag `ribbons` (`<festival>:<place>:<year>`, so it
  is saved with the flags and needs no save change), even when the rucksack is full. That
  flag gates a new farmhouse prop: the ribbon board on the back wall over (2, 1), one small
  rosette per ribbon (the last 12), E on it counts them. The ending record is left alone
  (its steps were just re-set). README → Festivals, AGENTS.md flags and tests updated.
- Checked: new checks in `test_festivals.gd` (stall ids and the data check, which stall
  props sell, both night stalls' stock, prices and hours, every stall-only food on a stall,
  names fit the item box, E at each stall and at a look-only one, buying a chime and shaved
  ice, keepsakes not shipped / sold / eaten, icons drawn, ribbon ids / names for every
  festival and place, a ribbon for first place in year 2, an egg fourth at the Moon Offering
  gets none, a full rucksack still records it, the board's prop, look and text, the record
  and a ribbon through `to_dict` / `from_dict`, wares on the counters in 3D: 3 at Blossom
  Day, 5 at Lantern Night). All 23 test scripts print `OK (0 failed)`. Headless
  `--quit-after 300` runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --festival=lantern_night`, with `--shop=stall:lantern_night:chimes`, `--festival=blossom_day
  --shop=stall:blossom_day`, `--map=house --flags=ribbons=blossom_day:1:1`, and
  `main_2d.tscn -- --demo --festival=lantern_night`) printed no errors or warnings. Movie
  Maker frames: `--festival=lantern_night` (lanterns, fireworks, the chime on the yellow
  stall's counter at the right edge), `--festival=lantern_night --map=town@tome` (the red
  stall with its three dishes on the counter), `--shop=stall:lantern_night:chimes` (the
  screen: Wind chime 300 G, Paper fan 120 G, "Lantern Night only"), `--map=house
  --flags=ribbons=blossom_day:1:1` (the board on the back wall with a red rosette; the first
  try put it behind the wall post, moved 0.05 out). `shots/` deleted.
- Left / next: the board's rosettes are small from the camera; keepsakes do nothing yet
  (could go in the gift lists, left out while the heart work is open in another branch);
  stalls at Moon Night and Year's Turn. Not played in a real window.

## 2026-10-31 — Band 6 heart scenes
Agent: Claude Code (claude-opus-5-5) · Commit: 6479d92
- Done: a third heart event per villager, `data/events/heart_<id>_6.json` with lines in
  `data/dialogue/heart_events_6.json` (our own story, following on from bands 3 and 5).
  Tome: her son asks her to move to the city, she stays (a line of its own with
  `tome_grandma`); Kota: gives the farmer a carp streamer of the old black carp (a line of
  its own with `kota_carp_promise`), sets `kota_streamer`; Sayo: her father's note on the last
  page of his ledger (a line of its own once `sayo_sign` is set), she starts her own ledger
  with the farmer's name first, sets `sayo_ledger`; Hachiro: the farmer strikes one blow on
  the sickle he forges each year for his teacher's grave (a hammer sound between two parts; a
  line of its own with `hachiro_bell`), sets `hachiro_strike`. Each also sets
  `heart_<id>_6` and adds 5 affection, as the earlier ones. Trigger rows right after the band
  5 ones in every table that has those (town, the three homes, store, smithy): `hearts`
  `[6, 6]`, `seen: ["heart_<id>_5"]`, once. Talk files: a `dear_1..3` pick at band 6 with the
  flag `heart_<id>_6`, before the band 4 .. 6 lines. Kota's streamer shows in the world: a
  new story prop `carp_streamer` on the farm map at (1, 4), the front corner left of the
  house, gated by `kota_streamer` (art `story:carp_streamer`, 26 x 40, pole and carp in one
  picture; 3D as a standing sprite at 0.05 px so the carp sits just over the eave; the 2D
  view draws it through StoryView). (1, 2) was tried first and hid behind the roof. Sayo's
  ledger and Hachiro's sickle get no prop: neither is something that would be seen.
  The font has no double quote, so Sayo reads her father's note in single quotes.
- Checked: `test_relationships.gd` (band 6 plays at band 6 only, only after band 5 was
  seen, band 5 comes first at band 6, each plays once, on every map; each band 6 event runs
  on the real Game with and without the band 5 flag, sets its flags; both branches of every
  look-back line; the band 6 talk lines only after the scene and at band 6, taking turns) and
  `test_maps.gd` (the streamer shows only with its flag, beside the bell, on a free cell, its
  art drawn). All 23 test scripts print `OK (0 failed)`; headless runs (title, `--demo`,
  `--demo --map=town`, `--demo --mine=3`, `--demo --flags=kota_streamer,hachiro_bell`,
  `--demo --event=heart_hachiro_6 --hearts=6 --map=smithy`, `main_2d.tscn -- --demo
  --flags=kota_streamer`) printed no errors or warnings. Screenshots: `--demo --map=town
  --time=14:30 --event=heart_kota_6 --hearts=6` frame 59 shows Kota's first line with the
  band 6 heart on the tag; `--demo --flags=kota_streamer,hachiro_bell` shows the streamer
  left of the house (carp, white spot, red ring, gold ball) and the bell, in 3D and 2D.
  `shots/` deleted.
- Left / next: the villagers aren't placed as actors in any heart scene (the text box
  speaks over an empty spot); a later pass could add `actor` steps.

## 2026-10-31 — Cooking tools
Agent: Claude Code (claude-opus-5-5) · Commit: 33b28aa
- Done: six kitchen tools of our own in `data/recipes.json` `tools`: kitchen knife 600 G,
  clay pot 900, teapot 400, iron rice pot 1200, bamboo steamer 1500, mochi mallet 2000
  (6,600 G in all, about one more kitchen corner). Recipes gain a `tools` list: the stews,
  simmered pumpkin, furofuki daikon and fish and daikon need knife + pot, ochazuke the teapot,
  takikomi gohan knife + rice pot, milk pudding the steamer, kinako mochi the mallet. The four
  start recipes need none (Cooking.check refuses a start recipe with tools), so nothing that
  cooks in a new game changes. Prices: the knife and pot first (they open five recipes), the
  dear ones gate the dishes that sell best (mochi x3, pudding). `Game.cook` refuses with
  "You need a clay pot for that" before touching the ingredients; the cooking screen's row
  says "no tool" and a new line "Uses Kitchen knife, Clay pot (store)" marks what is missing.
  The Yorozu Store (`kitchen_tools` in shops.json) lists the tools not owned at the top of
  the buy tab, after the rucksack, once the kitchen is built; each is bought once (item
  `kitchen:<id>`, no rucksack slot, icons `ui:kitchen:<id>`). Saved as `kitchen_tools`, save
  version 4 -> 5: a version 4 save with the kitchen built gets the tools of the recipes it
  already knew, so an old save's cooking keeps working. `--demo --cook` now owns the knife
  only, to show a missing tool. README → Cooking updated.
- Checked: new `_tools()` in `test_cooking.gd` (data and icons, the font, the about line
  width, every tools line fits the page, bad data refused, nothing sold before the kitchen,
  each tool once, money, the smithy sells none, the menu's state and line, cooking after
  buying the pot, save round trip, 4 broken lists refused, a version 5 save without the key,
  a version 4 save's migration with and without the kitchen); the stew checks now buy the
  tools first; `test_shops.gd` checks the knife heads the buy tab with a kitchen;
  `test_animals.gd`'s "save version 4" check now reads `>= 4`. All 23 test scripts print
  `OK (0 failed)`. Headless runs (title `--quit-after 300`, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, `--demo --cook`, `--demo --shop=general`, `--demo --map=house
  --built=kitchen`) printed no errors or warnings. Screenshots `--demo --cook` (turnip stew
  "no tool", the others ready) and `--demo --built=kitchen --shop=general` (the six tools with
  icons after the rucksack) looked right; `shots/` deleted.
- Left / next: the balance script doesn't count tool prices in a recipe's gain; the playtest
  of a real year should. Other branches bumping the save version will conflict on
  `SaveGame.VERSION` at merge time.

## 2026-10-31 — The 2D view plays: the Player's actions hooked up
Agent: Claude Code (claude-opus-5-5) · Commit: c62eb4b
- Done: `scripts/main_2d.gd` never connected `Player.action`, so in `scenes/main_2d.tscn` the
  farmer walked but no tool, door, talk, throw, cast or counter did anything. The hookup is now
  shared: `FarmActions.connect_view(player)` connects the action signal and runs the `--talk=`
  start flag (`FarmActions.talk_flag`, moved out of main_3d.gd), and both views call it after
  building their first map. Everything else the 3D view reaches already went through Game
  signals (text box, rucksack / storage, shops, cooking, ending, events, map fades), which the
  2D scene already had screens for. Drawing only in the 2D view: a thrown item now flies in an
  arc (`Game.thrown`, a Sprite2D, the same flight_seconds / arc_height as 3D) and FarmView
  hides it on its landing cell until it arrives (`hidden_item`, as FarmWorld). The Player
  already draws the held item, the rod, line, bobber and "!" and the charge pips in 2D.
- Checked: new `tests/test_view2d.gd` builds main_2d.tscn on a new game and sends actions
  through the Player's signal: the hoe tills and costs stamina, the can waters, the tool
  button puts an item down and E picks it up, E throws (lands, flies, hidden then shown), the
  empty bin's note, the food slot eats a turnip overhead, the rod casts and lands a fish on a
  bite, walking into the farmhouse door swaps to the house MapView at the spawn, talking to
  Tome at 14:30 opens her lines and counts the talk, the Yorozu counter opens the store
  screen at 11:00, the hammer breaks a rock on a mine floor (with MineView). With
  `connect_view` taken out of main_2d.gd it printed 16 FAILs. All 24 test scripts print
  `OK (0 failed)`; headless `--quit-after 300` runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, `--demo --map=town --time=14:30 --talk=tome`, and main_2d.tscn with
  `--demo`, `--demo --fishing`, `--demo --mine=3`, `--demo --hold`, `--demo --map=town
  --time=14:30 --talk=tome`) printed no errors or warnings. 2D frames looked at: the talk run
  shows Tome's text box over the village, the fishing run the line, bobber and "!" at the
  pond; `shots/` deleted.
- Left / next: the 2D view has no rain / snow particles, lightning flash or festival glow
  (drawing only, the 3D ones are 3D nodes).

## 2026-10-31 — Shop and event music: the store, the smithy, heart events, the opening
Agent: Claude Code (claude-opus-5-5) · Commit: d6289eb
- Done: four new scores of our own in `data/music.json`, all in the yo scale except the
  smithy: `store` (C, 100 bpm: a koto tune over a new `shamisen` pluck instrument chugging
  off the beat, a woodblock and sho chords; easy to stand in while shopping), `smithy` (D in
  minyo, 84 bpm: a low shakuhachi line, a koto ostinato, the kane bell as the anvil on 1, 3
  and 3.5, a taiko on the downbeat), `heart` (E flat, 63 bpm in 6: a soft shakuhachi over a
  koto arpeggio, sho and a rin now and then), `morning` (G, 108 bpm: a bright koto tune, a
  long shakuhachi line above it, koto bass, woodblock and taiko). Levels -5 / -6 dB like the
  other tracks. `MusicPicker.pick` takes the map id and the event playing; a rule with
  `maps` fits only on those maps, one with `events` only while one of those event scripts
  plays. Rules: `heart` for the eight heart_* events and `morning` for `opening` and
  `first_morning`, right after the title rule (so they win over festivals, shops, weather
  and night); `store` on map store and `smithy` on map smithy, after the festivals and before
  rain / night (a shop is indoors, its tune plays whatever the weather or hour). The first
  visit events (store_intro, smithy_intro) keep the shop tune instead of a bright one: a
  3 s cross-fade for a short scene in the same room would only interrupt. `Sfx` passes
  `Game.maps.id` and `Sfx.event_playing()` (the EventPlayer's runner id while
  `Game.event_running`).
- Checked: `test_audio.gd` new checks: the new scores pass the existing score checks (scale,
  bars, range, two bars not silent); store / smithy picks over storm, rain and night; town and
  house keep the old picks; every `data/events/heart_*.json` picks heart (also at the store
  counter and on Blossom Day); opening and first_morning pick morning; the shop intros keep
  the shop music; pond_first and festival_blossom keep the music around them; rule maps and
  events exist as files; a sweep over scene x 5 looks x 4 seasons x 6 hours x 5 festivals x
  5 maps (none, farm, town, house, mine_floor) x 3 events (none, pond_first,
  festival_blossom) gives exactly what the rules without maps / events give; on the real Sfx,
  map store picks `{"store": 1.0}`. All 23 test scripts print `OK (0 failed)`. Headless runs
  (title `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --shop=general`, `--demo --shop=smithy`, `--demo --map=town --time=14:30
  --event=heart_tome`, `res://scenes/main.tscn --quit-after 400`) printed no errors or
  warnings. Movie Maker with `--movie-audio`, 300 frames each, levels after the first 3 s
  (python -I, wave + numpy): `--shop=general` rms 0.0563 (-25.0 dBFS) peak 0.2792 (-11.1);
  `--shop=smithy` rms 0.0627 (-24.1) peak 0.2640 (-11.6); `--map=town --time=14:30
  --event=heart_tome` rms 0.0672 (-23.4) peak 0.2808 (-11.0); `--event=opening` rms 0.0620
  (-24.1) peak 0.3155 (-10.0); so not silent, but these mixes include the ambient and sound
  effects too, and the numbers don't say which track played (the picks are checked in the
  tests). The movie runs print `WARNING: 2 ObjectDB instances were leaked at exit`; the same
  warning shows with the code before this change (`--shop=general --movie-audio`), so it is
  not from this work. `shots/` deleted.
- Left / next: a person still has to listen to all four tunes (and the older ones); mine
  floors and villagers' homes still use the season / night music.

## 2026-10-31 — Merged three branches: dish gifts, ending / balance, heart flags in the world
Agent: Claude Code (claude-opus-5-5) · Commit: 0585a07
- Done: merged with `--no-ff`, one at a time, all tests after each:
  `claude/dish-gifts-4909dc` (73c84fe, clean), `claude/ending-balance-4cc810` (df904b6;
  WORKLOG and ROADMAP conflicted, both entries kept, the ROADMAP food / next lines joined),
  `claude/heart-flags-world-6c7f7a` (7139105; WORKLOG conflicted, entries kept). The entries'
  "this commit" now name their hashes. Fix found in the smoke runs: `--flags=sayo_sign` (true,
  no answer) stopped `MapManager.shows()` with `Invalid operands 'bool' and 'String' in
  operator '=='`; a prop's `flag_value` now compares types first, with a check in test_maps.
- Checked on merged main: all 23 test scripts print `OK (0 failed)`; headless runs (title
  `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --map=town
  --time=14:30 --talk=tome`, `--demo --shop=general`, `--demo --ending`, `--demo --map=town
  --flags=hachiro_bell,sayo_sign,tome_grandma` and `--flags=sayo_sign=new`,
  `res://scenes/main.tscn --quit-after 400`, `main_2d.tscn -- --demo`) printed no errors or
  warnings after the fix. No screenshots taken in this merge.
- Left / next: cooking tools; a playtest of a real year; the .exe once the export templates
  are installed.

## 2026-10-31 — Dishes as gifts, the store buys dishes
Agent: Claude Code (claude-opus-5-5) · Commit: 73c84fe
- Done: every villager file lists kitchen dishes in `gifts` (`food:<id>`): Tome loves
  furofuki daikon and pumpkin nimono, likes miso soup, ochazuke, turnip stew, takikomi gohan
  and kinako mochi, dislikes milk pudding; Hachiro loves grilled fish, fish and daikon and
  potato stew, likes miso soup, tamagoyaki, turnip stew and takikomi gohan, dislikes milk
  pudding and kinako mochi (no sweets, as with dango); Sayo loves tamagoyaki and milk pudding
  (eggs and milk, as her egg_best), likes kinako mochi, pumpkin nimono, takikomi gohan and
  ochazuke, dislikes grilled fish and fish and daikon (no river fish); Kota loves milk pudding
  and kinako mochi (sweets), likes tamagoyaki, grilled fish, onigiri and potato stew,
  dislikes ochazuke and furofuki daikon (tea and plain daikon are grown-up food). Point
  values: the existing reaction scale in `_common.json` (love 8, like 3, ...), birthday x5
  included; a dish isn't worth more than a loved crop, since one gift a day already caps
  gifts and a bigger dish score would make the crop and mine likes pointless. Fix in
  `Game.talk_to`: a gift takes one of the stack in hand (dishes come several at a time;
  before, a stack of 3 overhead vanished with one gift). The Yorozu Store `buys` kind
  `dish`: 80% of a dish's `sell` (`Shop.buy_back`), only foods with a sell and `shop` false,
  so the store never buys back what its own shelf sells (onigiri). 80% because it matches
  its cut on crops: cash at once and from the rucksack (the bin takes dishes only from the
  hand) for a fifth less than the bin pays at 18:00.
- Checked: new checks in `test_relationships.gd` (dish gift lists are real foods, each
  villager loves and dislikes a dish, every kitchen dish is liked by someone, a loved dish x5
  on a birthday; on the real Game a stack of 2 grilled fish on Hachiro's birthday: the
  birthday answer, x5, one left overhead; Sayo answers gift_dislike) and `test_shops.gd`
  (every dish bought at sell x 80%, foods without sell or on a shelf not bought, the smithy
  buys none, the sell tab lists a stew and not a dango, selling from the rucksack and the
  hand); the old "the store doesn't buy dishes" check is gone. All 23 test scripts print
  `OK (0 failed)`; headless runs (title `--quit-after 300`, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, `--demo --map=town --time=14:30 --talk=tome`, `--demo --shop=general`)
  printed no errors or warnings.
- Left / next: cooking tools; no dish-specific gift lines (the usual gift_<reaction> answers).

## 2026-10-31 — Ending steps for 11 crops / 13 recipes; balance with ores, contests, cooking
Agent: Claude Code (claude-opus-5-5) · Commit: df904b6
- Done: `data/ending.json`: "Crops grown" [2, 4, 7, 9] -> [3, 6, 9, 11], "Recipes"
  [2, 4, 6, 9] -> [6, 8, 10, 13]. Reasoning: with 11 crops the old steps gave the last star
  by early fall; now spring's three crops earn one star, summer's (with rice) make 6-7, and
  the last two need most of fall's four (daikon included). The 4 start recipes earned two free
  stars before; now they earn none, the four band-1 lessons and the radio make 9 (2 stars), the
  two bin cards (first daikon / rice) bring 13 for the last star, so a run that never grows
  daikon or rice stops at 3. Other categories unchanged (still fit tools/balance.py below).
  `tests/test_ending.gd`: the top crop step is every crop, the top recipe step every recipe, and
  the start recipes earn no star (so the steps follow new content). `tools/balance.py`: mine
  finds are counted per item (`mine_floor_finds`, `mine_season_finds`); a tool upgrade takes
  its ores from the stock of finds (they no longer reach the bin) and waits while they are
  short; a "prize" column from each festival's contest (Monte Carlo, 2000 rolls, a fixed seed:
  the plan's best crop ripe by the day, best catch so far, best egg / milk of the morning, best
  mine find of the season, against the rivals' rolls; prize items left out); the place odds and
  wins a year; a per-recipe table of what one cooking fetches over its ingredients shipped raw.
  Daikon and rice were already in the plan (fall 20 % / summer 15 %). `data/festivals.json`:
  Year's Turn rivals hachiro [50, 160] -> [120, 320], kota [20, 110] -> [40, 160], sayo
  [10, 90] -> [20, 120]: the plan won it 100 % of the time (a jade, 300 G, comes up on floors
  8-10 almost every winter, over every rival's best); now a deep winter wins 88 % and a
  shallow one (amber 150 / crystal 120) mostly loses. No crop or dish prices changed: every
  recipe gains 7-67 G a cooking over its raw ingredients, cooking stays a small extra.
- Balance, before (the old tool, same data, from the daikon / rice entry):
  ```
   season |   crops |    cook |    eggs |    milk |    wool |    fish |    mine |  income |   seeds |    feed | animals |   other |     net
   spring |   10260 |       0 |    3792 |       0 |       0 |    2797 |     259 |   17109 |    2380 |     590 |    2800 |    2050 |    9288
   summer |   18828 |     576 |    7492 |    2616 |       0 |    3501 |    1218 |   34232 |    3016 |    1406 |    8800 |    2050 |   18959
     fall |   30758 |    1525 |    8325 |    5886 |    1981 |    3442 |    2062 |   53978 |    7060 |    2151 |    9600 |    2050 |   33117
   winter |       0 |    1382 |    8325 |    9810 |    2830 |    4161 |   22715 |   49223 |       0 |    4410 |       0 |    1150 |   43663
   spring: rucksack 1, chest, can 2, hoe 2; 2788 G left · summer: kitchen, sickle 2, can 3; 11748
   fall: rucksack 2, room; 20365 · winter: hoe 3, can 4, hammer 2; 55528 G left
  ```
  After (`python -I tools/balance.py`):
  ```
   season |   crops |    cook |    eggs |    milk |    wool |    fish |    mine |   prize |  income |   seeds |    feed | animals |   other |     net
   spring |   10260 |       0 |    3792 |       0 |       0 |    2797 |     205 |     476 |   17531 |    2380 |     590 |    2800 |    2050 |    9711
   summer |   18828 |     576 |    7492 |    2616 |       0 |    3501 |     970 |     295 |   34279 |    3016 |    1406 |    8800 |    2050 |   19007
     fall |   30758 |    1525 |    8325 |    5886 |    1981 |    3442 |    2062 |     406 |   54384 |    7060 |    2151 |    9600 |    2050 |   33523
   winter |       0 |    1382 |    8325 |    9810 |    2830 |    4161 |   22221 |     464 |   49193 |       0 |    4410 |       0 |    1150 |   43633
  year net 105874 G (mine: finds shipped, less the ores kept for the smithy)

   spring: bought rucksack 1 (2000), chest (3000), upgrade can 2 (1000); 4211 G left; ores kept 54 G; upgrade hoe 2 waits for akagane
   summer: bought upgrade hoe 2 (1000), kitchen (6500), upgrade sickle 2 (1000), upgrade can 3 (2500); 12217 G left; ores kept 248 G
     fall: bought rucksack 2 (6500), room (18000); 21240 G left
   winter: bought upgrade hoe 3 (2500), upgrade can 4 (5000), upgrade hammer 2 (1000); 56374 G left; ores kept 494 G
     ores left: satetsu 168.1, akagane 185.2, shirogane 102.9, kogane 32.2

     blossom_day (  crop):  92% /   8% /   0% /   0%; 476 G
   lantern_night (  fish):  32% /  68% /   0% /   0%; 295 G
      moon_night (animal):  72% /  18% /   9% /   1%; 406 G
      years_turn (  mine):  88% /  12% /   0% /   0%; 464 G
     wins expected a year: 2.8
  ```
  Year net 105 027 -> 105 874 G: the ores kept cost under 800 G a year, prizes add about
  1 640. Contests: ~2.8 wins a year, about 5-6 in two years, so "Contests won" [1, 2, 4, 6]
  stays (the last star needs nearly every contest). Lantern Night is the hard one: morning /
  evening fishing brings an ayu (120) and Hachiro rolls over that 70 % of the time; a night
  eel (300) wins it.
- Note for later (data/shops.json not touched, another session works there): the smithy's
  level 2 asks 3 akagane, and a spring with the plan's two mine trips (floors 1-3) finds about
  4.3, so the second upgrade waits for summer. Fine if the player is meant to mine for it; if
  not, level 2 could ask 2 akagane, or akagane could weigh more on floors 1-3 (data/mine.json).
- Checked: all 23 test scripts print `OK (0 failed)` (test_ending with the new checks).
  Headless `--quit-after 300` (title, `--demo`, `--demo --map=town`, `--demo --mine=3`,
  `--demo --ending`, `--demo --festival=years_turn`, `--demo --festival=blossom_day
  --contest=potato`) and `res://scenes/main.tscn --quit-after 400` printed no errors or
  warnings.
- Left / next: still nobody has played two real years; the contest odds are the plan's guess.

## 2026-10-31 — Heart flags in the world: the door bell, the store's sign, Tome's plum jar
Agent: Claude Code (claude-opus-5-5) · Commit: 7139105
- Done: map props can be gated by a story flag: `"flag"` (shows while set, EventRunner.is_set)
  and optional `"flag_value"` (shows while the flag has that value). MapManager filters them
  (`with_flags`, `gate_flags`, `shows`) after the extensions; it shares Game.flags
  (`set_flags`, called by Game at new game and load) and reads a cached map again when one of
  its gate flags changes, so the event's `set` step is enough (the views show it from the next
  map change). New props: `door_bell` on the farm at (5, 3) by the house door (hachiro_bell;
  `use: "examine"` plays `chime_morning` and says a line), two `store_sign` props on the store
  in the village (sayo_sign old / new: the old name repainted in gold on dark wood, or Sayo's
  own lacquer-red board), `ume_jar` in the farmhouse at (5, 1) (tome_grandma: Tome's pickled
  plums, her note read when examined). Art: PlaceholderArt `story:door_bell`, `story:sign_old`,
  `story:sign_new`, `story:ume_jar`. 3D: StoryProps (the bell a hanging sprite on an iron arm
  by the door post, the sign a picture on posts over the roof's front slope, the jar a sprite);
  FarmWorld.make_story_props draws the farm's. 2D: StoryView draws the same pictures (MapView
  skips those kinds). A prop with `use: "examine"` (any map, the farm too) plays its `sound` and
  shows its `message` (FarmActions.examine_prop). `--flags=a,b=c` sets flags for screenshots.
  README → Maps and AGENTS document it.
- Checked: test_maps has new checks (no story prop without its flag, each with it, the sign by
  value, gate flags, the jar's cell with every extension, art drawn, the cached maps follow
  Game.flags, a new game clears them, the bell and sign come back from a save, 3D town has the
  sign picture, 3D farm the bell sprite, the 2D view gets one sign, using the bell rings it).
  All 23 test scripts print `OK (0 failed)`; headless runs (title `--quit-after 300`, `--demo`,
  `--demo --map=town`, `--demo --mine=3`, `--demo --flags=hachiro_bell,sayo_sign=old,tome_grandma
  --map=town`, `main_2d.tscn -- --demo --flags=hachiro_bell`) printed no errors or warnings.
  Movie Maker frames looked at: the bell by the farmhouse door (moved down from under the eave
  after the first frame hid it), the new and the old sign on the store roof, the jar by the
  chest (made bigger after the first frame), and the bell, sign and jar in the 2D view.
- Left / next: the props appear on the next map change, not while standing on the map where
  the event plays; a band 6 scene.

## 2026-10-31 — play.bat / play_demo.bat: double-click to play
Agent: Claude Code (claude-opus-5-5) · Commit: 4a36ea4
- Done: `play.bat` starts `Godot_v4.7.2-stable_win64.exe --path .` from its own folder (full
  `%~dp0` paths, since this machine sets NoDefaultCurrentDirectoryInExePath and cmd would not
  find files in the current folder), says so and waits if the binary is missing, and passes on
  extra arguments. `play_demo.bat` calls it with `-- --demo` last. `.gitattributes` keeps
  `*.bat` in CRLF. README → Run mentions both.
- Checked: `cmd /c play.bat --quit-after 200` and `cmd /c play_demo.bat --quit-after 200` each
  started the game (command lines `--path . --quit-after 200` and `--path . --quit-after 200
  -- --demo`) and it quit on its own.
- Left / next: the real .exe still needs the export templates (README → Export).

## 2026-10-31 — Merged three branches: settings, relationships 2, daikon and rice
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time, all tests after each, in this order:
  `claude/settings-4fed9a` (605ef62), `claude/relationships-2-f6ce52` (cc8b29c),
  `claude/food-crops-9a8f14` (29f5c36). Only WORKLOG.md conflicted (each branch's new entry at
  the top); all three entries were kept. AGENTS, README, ROADMAP, `scripts/autoload/game.gd`
  and `scripts/ui/hud.gd` merged by themselves.
- Checked on merged main: all 23 test scripts print `OK (0 failed)`; headless runs (title
  `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --pause=settings`, `--demo --event=heart_tome_5`, `--demo --season=summer`, `--demo --cook`,
  `--demo --ending`, `res://scenes/main.tscn --quit-after 400`, `main_2d.tscn -- --demo`)
  printed no errors or warnings. Movie Maker frame `--demo --season=summer`: the field with
  ripe rice and the HUD.
- Left / next: dishes as gifts (villager likes); the ending's recipe and crop-kind steps
  re-checked now that there are 13 recipes and 11 crops; the .exe once the export templates
  are installed; a playtest of a real year.

## 2026-10-31 — Settings: display, v-sync, text speed, HUD / run toggles, reset, pad remapping
Agent: Claude Code (claude-opus-5-5) · Commit: 605ef62
- Done: `data/settings.json` now has Display (window / full screen / borderless), Window size
  (2x-4x; the old "full" option moved to Display), V-sync, Lightning, Text speed (slow /
  normal / fast / instant, `values` x0.5 / x1 / x2 / 0), Always run, Show HUD and the three
  volumes. `Settings` file version 2 (a v1 "full" window reads as borderless),
  `option_value()` for a choice's `values`. `Game.apply_settings()` sets the window mode
  (exclusive full screen / Godot's borderless full screen / a window, scaled down by
  `Game.window_scale()` when it doesn't fit the screen), v-sync, `text_speed`, `always_run`,
  `hud_visible`; the Hud hides on `settings_changed`, the text box calls
  `DialogueRunner.set_speed()` (0 = whole lines), the player's run key inverts with Always
  run. The settings page ends with "Reset to defaults" (settings only; keys keep their own
  reset) and a note line. Pad remapping: every action has one pad slot (defaults in
  data/controls.json: D-pad + left stick walk, A tool, B talk, X run, RB / LB next tool / seed,
  Back rucksack, Y eat; Start stays on Pause, the stick is fixed), `Controls.bind_pad` swaps like
  keys, `clear_pad`, saved under `pad` in user://settings.json, names in `pad_names`. The
  controls page has a third column (300 px wide); Enter on it waits for a pad button, Esc or
  Start cancels. Reasoning: borderless by default for the old "full" because that is what it
  was (Godot's WINDOW_MODE_FULLSCREEN); text speeds are round factors of the 40 letters/s.
- Checked: `tests/test_menu.gd` prints `test_menu: OK (0 failed)` with new checks (new
  defaults, value text, option values, v1 migration, broken files, reset, window scale fit,
  Game fields from the settings, the HUD hiding live, text speed on the runner, pad defaults /
  swaps / Start reserved / clear / input map incl. the stick / file round trip and broken
  files, the pad slot in the menu); all 24 tests print OK. Headless `--quit-after 300` (title,
  `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --pause=settings`,
  `--demo --dialogue=bin_note`) and `res://scenes/main.tscn --quit-after 400` printed no
  errors or warnings. Movie Maker frames
  `--demo --pause=settings` (13 rows fit, sliders aligned) and `--pause=controls` (three
  columns, pad names) looked at.
- Left / next: no right-stick or trigger binding (triggers are axes); a "Window size" above
  what fits shows 4x while the window is 3x; no FPS limit or UI scale setting.

## 2026-10-31 — Relationships 2: band 5 heart events, birthday plans, fair weather, HUD tag
Agent: Claude Code (claude-opus-5-5) · Commit: cc8b29c
- Done: a second heart event per villager at band 5, our own scenes
  (`data/events/heart_<id>_5.json`, lines in new `data/dialogue/heart_events_5.json`): Tome
  has written to her son about the farmer and offers to be "Grandma" (choice, `tome_grandma`);
  Kota saw the old carp and let it be (a line of its own when `kota_carp_promise` from his
  band 3 scene is set) and wants to help at harvest; Sayo asks what goes on the store's
  repainted sign (`sayo_sign` old / new); Hachiro gives the farmer an iron door bell
  (`hachiro_bell`). Each adds 5 affection and sets `heart_<id>_5`. Rows sit right after the
  band 3 row in every table where that villager can be talked to (town, the house maps, store,
  smithy), with `hearts [5, 6]` and `seen: [heart_<id>]`, so the band 3 scene always comes
  first. Band 4 was left out: two scenes a year per villager read better than three short ones.
  Birthday as a day-plan condition: `{"if": {"birthday": true}}` in the rule lists
  (`Villagers.conditions_hold` with the villager's id; Talk's own `birthday` state still wins
  for talk picks). Birthday plans: Tome prays at the shrine 7:00-10:00 and is home for visitors
  the rest of the day; Kota is at the pond 7:30-17:30 after the carp; Sayo keeps the store until
  12:30, lunches at Tome's (Tome is home 12:00-14:00 then) and spends the afternoon in her
  rooms (a Sunday birthday stays her day off); Hachiro keeps the smithy shut, the shrine in the
  morning, the pond until 16:00. Fair weather: `Game.fair_tomorrow()` (a festival or a
  birthday tomorrow) replaces the roll in `end_day` (DESIGN). HUD: the festival tag under the
  clock shows "<Name>'s birthday" on a birthday (`HudLayout.day_tag`, `Game.birthdays_today`;
  "Hachiro's birthday" is 79 px, fits the 92 px box). Mine finds in gift lists: Tome likes
  jade and agate; Kota loves crystal, likes amber and frost stone; Sayo likes amber and crystal,
  dislikes clay; Hachiro loves hoshigane, likes the other ores, dislikes a grey stone.
  README (Villagers, Relationships), AGENTS test line, ROADMAP.
- Checked: `test_relationships` (new checks: band 5 rows on every map, band 3 first, once each;
  both events per villager run to the end on the real Game, Kota's both ways; birthday plans
  picked only on the day, Sayo's Sunday, Hachiro out of the smithy and Sayo at Tome's;
  fair weather the day of each birthday with all-rain odds, the day after rolls; the HUD tag
  on the real HUD; mine gift items exist) prints `test_relationships: OK (0 failed)`;
  test_villagers' refused-condition case is now `{"birthday": "yes"}`. All 24 test scripts print
  `OK (0 failed)`. Headless `--quit-after 300` (title, `--demo`, `--map=town`, `--mine=3`,
  `--map=tome_house`, `--event=heart_tome_5`, `--map=town --event=heart_kota_5`,
  `--season=fall --map=town --time=12:00`) and `res://scenes/main.tscn --quit-after 400`
  printed no errors or warnings. Movie Maker frame `--demo --map=smithy --event=heart_hachiro_5`: Hachiro
  behind the counter, the text box "Hold out your hand. No, the other one." with his heart.
- Left / next: no band 6 scene; the band 5 flags (`tome_grandma`, `sayo_sign`, `hachiro_bell`)
  change nothing in the world yet (a bell by the farmhouse door, the store's new sign); the
  storm-to-rain rule before a festival (DESIGN) is still not done.

## 2026-10-31 — Daikon and rice: two crops, four recipes, dishes shipped
Agent: Claude Code (claude-opus-5-5) · Commit: 29f5c36
- Done: `data/crops.json` gains daikon (fall, stages 2/3/3 = 8 days, sell 110, seed 260, a
  root with a white shoulder) and rice (summer and fall, 4/5/5 = 14 days, sell 110, seed 300,
  `holds_water`). Rice's rule, kept simple: a watered rice cell stays wet every night until it
  is picked or lost (`FarmGrid.day_end`), like a flooded paddy; it can be sown late in summer
  and ripen in fall. New placeholder shape `grain` (a clump of blades; ripe, straw stems and
  gold ears bowing over; the item is a tied sheaf). Seeds: the store sells rice in summer and
  fall, daikon in fall (the stand follows the crops' seasons). Raw daikon / rice eat a little.
  `data/recipes.json`: daikon joins the pickle and soup groups; four new recipes,
  furofuki daikon (1 daikon), fish and daikon (daikon + any fish), takikomi gohan (rice +
  carrot, makes 2), kinako mochi (2 rice, makes 3). They are learned by a new `card` key: the
  first of that crop shipped (E at the bin or thrown in) sets the flags of its cards and says
  "A recipe card in the bin lid: ..." (`Cooking.cards`, `Game._note_shipped`; deferred so
  it follows the bin's own line). No event or trigger files were touched (the other sessions
  work there). Dishes ship: a `sell` per dish in foods.json, `Game.sell_price("food:<id>")`;
  E at the bin takes dishes only from the hand (the rucksack's are lunch), throwing works too;
  shipped dishes count in the ending's shipped value. The store does not buy dishes.
  `-- --demo --season=fall|summer` sows that season's crops in the demo field (spring as
  before). test_save's "bad seed" example was "rice"; now "moonflower".
- Balance (ours): daikon is set next to carrot per plot over a season (30 days: carrot
  4 x 9 x 85 - 800 = 2260 G a bag, daikon 3 x 9 x 110 - 780 = 2190); rice earns less per bag
  than onion (2 harvests a summer: 1380 vs 1575) but needs one watering per crop instead of
  fourteen. Dish `sell` is about 1.3 x the shipping value of ordinary ingredients (cheapest
  crop of a group, middle-grade eggs 46 / milk 164, a fish about 60): onigiri 20, miso soup
  45, grilled fish 80, tamagoyaki 120, turnip stew 200, potato stew 240, ochazuke 130,
  pumpkin nimono 125, milk pudding 270, furofuki daikon 140, fish and daikon 220, takikomi
  gohan 130, kinako mochi 95. Cooking a cheap fish or a turnip pays best; cooking an ayu or a
  carrot into miso soup loses money, on purpose. `tools/balance.py` now plants rice (15 % of
  summer bags) and daikon (20 % of fall) and adds a "cook" column: dishes cooked per season
  from summer (the kitchen) less their ingredients' raw value. `python -I tools/balance.py`:
  ```
   season |   crops |    cook |    eggs |    milk |    wool |    fish |    mine |  income |   seeds |    feed | animals |   other |     net
   spring |   10260 |       0 |    3792 |       0 |       0 |    2797 |     259 |   17109 |    2380 |     590 |    2800 |    2050 |    9288
   summer |   18828 |     576 |    7492 |    2616 |       0 |    3501 |    1218 |   34232 |    3016 |    1406 |    8800 |    2050 |   18959
     fall |   30758 |    1525 |    8325 |    5886 |    1981 |    3442 |    2062 |   53978 |    7060 |    2151 |    9600 |    2050 |   33117
   winter |       0 |    1382 |    8325 |    9810 |    2830 |    4161 |   22715 |   49223 |       0 |    4410 |       0 |    1150 |   43663

   spring: bought rucksack 1 (2000), chest (3000), upgrade can 2 (1000), upgrade hoe 2 (1000); 2788 G left
   summer: bought kitchen (6500), upgrade sickle 2 (1000), upgrade can 3 (2500); 11748 G left
     fall: bought rucksack 2 (6500), room (18000); 20365 G left
   winter: bought upgrade hoe 3 (2500), upgrade can 4 (5000), upgrade hammer 2 (1000); 55528 G left
  ```
  Before (main): summer net 19119, fall 31980, winter 42282, 53169 G left at year end; now
  105 027 G net for the year (was 102 669). Cooking is a small extra (about 3 500 G a year),
  not a new main income; the goals are bought in the same seasons.
- Checked: all 23 tests print `OK (0 failed)` (new checks in test_farm: daikon / rice data,
  a dry paddy, rice ripe from one watering across summer into fall, the plot dries once
  empty, daikon dries like any crop and withers in winter, ripe looks all distinct;
  test_cooking: cards are real crops, every dish has a sell, cards learned by the bin and by
  a throw, kinako mochi and fish and daikon cooked, cards survive a save, the bin leaves the
  rucksack's dishes and ships the hand's, shipped dishes in the record; test_shops: every
  crop's seeds sold in each of its seasons, the store buys daikon / rice but not dishes;
  test_food: every crop eats raw, a dish's sell is under its stand price). Headless
  `--quit-after 300` (title, `--demo`, `--demo --map=town`, `--demo --mine=3`,
  `--demo --season=fall`, `--demo --cook`, `--demo --shop=general`) and
  `res://scenes/main.tscn --quit-after 400` printed no errors or warnings. Movie Maker
  frames `--demo --season=fall` (pumpkin sprouts, young rice clumps, ripe daikon with white
  shoulders) and `--demo --season=summer` (ripe rice, straw and gold ears) looked at.
- Left / next: dishes as gifts need villager likes in data/villagers (another session works
  there); the store buying dishes; cooking tools. The ending's steps were not changed: 13
  recipes (4 at the start) and 11 crop kinds now, so "Recipes" [2, 4, 6, 9] and the crop
  kinds steps are easier than planned; re-check them in a playtest pass.

## 2026-10-31 — The ending: the village record on the first morning of year 3
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: DESIGN lists the ending as not studied, so the rules are ours. New `Ending`
  (scripts/ending/ending.gd, pure): `grade(values, points)` gives stars per category (one per
  step reached), a rank by stars in all, a title, and the closing speaker (the villager with
  the most points from heart band 3, else Tome); `check` refuses bad data; `value_text`
  formats numbers. `data/ending.json`: ten categories (shipped value at today's prices, crop
  kinds shipped, happy animals at half happiness or more, heart bands added up, deepest mine
  floor, fish kinds, house extensions, tool levels above 1 over the five field tools, contests
  won, recipes known), 39 stars, five ranks (Passing Traveller 0, New Hand on the Farm 8,
  Village Farmer 16, Keeper of the Satoyama 24, Heart of the Village 33). Reasoning: from
  tools/balance.py's year-1 plan (about 150 000 G gross a year, rising in year 2), a steady
  two years ships 250 000 G or more (3 stars), grows every crop (4), fills a coop and barn
  (3), talks daily (band 3-4 each, 3), builds all three extensions (3) and lands about 26-30
  stars: Keeper; a casual run lands in Village Farmer; the top rank needs nearly everything.
  `Game.ending_values()` / `ending_record()` / `show_ending()` (sets `ending_rank_<n>`,
  `ending_friend_<id>`, clears older ones; `ending_open` while the screen is up, never without
  one). New event step `{"do": "ending"}` (EventRunner waits on `ending_open`). The scene
  `data/events/ending.json` + `data/dialogue/ending.json`, our own: a black fade, the farmer
  at the futon, Tome slides the door open and brings the record, the EndingScreen, her verdict
  per rank, then the closest villager comes in for a word (Tome herself when nobody is close),
  `ending_seen`; the game goes on. Played once by a `day_start` row in triggers_house.json for
  year 3 or later (a missed morning comes the next day). `EndingScreen`
  (scripts/ui/ending_screen.gd, both views): wood and paper like the other screens, rows
  revealed one by one with stars as seal-red boxes, "Written as: <title>"; Enter shows all,
  then closes. `-- --ending` opens it. README → Ending, AGENTS test line and flag.
- Checked: new `tests/test_ending.gd` prints `test_ending: OK (0 failed)` (data, grading,
  ranks, friend pick, trigger once in year 3+, values on the real Game, the event to the end
  for each closing villager, the screen waits / reveals / closes and the event goes on); all
  23 tests print OK. Headless `--quit-after 300` (title, `--demo`, `--demo --ending`,
  `--demo --map=house --event=ending`, `--demo --map=town`), `res://scenes/main.tscn
  --quit-after 400` and `main_2d.tscn -- --demo --ending` printed no errors or warnings.
  Movie Maker frames: `--demo --map=house --ending` (the record, 3 of 39 stars, Passing
  Traveller) and `--demo --map=house --event=ending` (Tome at the door, the opening line).
- Left / next: nobody has played two real years, so the steps are a guess from
  tools/balance.py; a playtest should tune them. Not done: a record every New Year, a look
  back at the first day, real scroll art.

## 2026-10-31 — Merged six branches: balance, mine extras, homes, relationships, contests, cooking
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time, all tests after each, in this order:
  `claude/balance-pass-73de78` (5cacb8f), `claude/mine-extras-68e7bd` (4903e47),
  `claude/villager-homes-fbc926` (3d032b5), `claude/relationships-b9b5eb` (02f8e7a),
  `claude/festival-contests-43ab9f` (98ddaac), `claude/cooking-0acc52` (2c0989d). WORKLOG kept
  every branch's entry; AGENTS / ROADMAP kept both sides (test list, debug flags, sections);
  "Next up" points at endings (milestone 9). Joins:
  - `data/shops.json`: the balance prices (big rucksack 6500) with the mine's `buys`
    (store: gems 120 %) and ore `items` on upgrades; `_about` describes fodder, young animals,
    stone / ore / gem buys and upgrade items.
  - Heart events and recipe talks: the villagers are now at home part of the day, so the heart
    rows (and the cooking branch's recipe rows) are also in new `triggers_tome_house.json`,
    `triggers_kota_house.json`, `triggers_sayo_house.json`; `test_relationships` checks the
    house maps too. The cooking branch's `quiet_house` examine rows on Tome's / Kota's doors
    were dropped (the doors open now).
  - Festival contests score an entry's shipping value, and the balance pass lowered spring
    crops (potato 80 -> 55, turnip 60 -> 35, cucumber 60 -> 30), so Blossom Day's rivals were
    scaled down to match (Kota 40-75, Tome 45-85, Sayo 30-65; a good in-season potato scores
    83). `test_festivals` now works the potato's score out from `crops.json`. The other
    contests were left: fish and mine prices didn't change, milk / wool rose a little and eggs
    fell.
  - `Game.new_game` keeps both `--hearts=` and `--cook`. Save version stays 4.
- Checked on merged main: all 22 tests (the 20 before plus `test_cooking`,
  `test_relationships`) print `OK (0 failed)`; headless `--quit-after 300` (title, `--demo`,
  `--map=town`, `--mine=3`, `--season=winter --mine=3`, `--map=tome_house`, `kota_house`,
  `sayo_house`, `--festival=blossom_day`, `--contest=potato`, `--shop=stall:blossom_day`,
  `--cook`, `--hearts=4 --map=town --time=14:30 --talk=tome`, `--shop=smithy`,
  `--shop=general`, `--map=barn`, `--fishing`) and `res://scenes/main.tscn --quit-after 400`
  printed no errors or warnings. Movie Maker frames: `--demo --map=tome_house` (irori, tatami,
  tokonoma), `--demo --festival=blossom_day --contest=potato` (judges' table, results box).
- Left / next: none of it was played in a real window and the festival music wasn't heard.
  `tools/balance.py` doesn't count contest prizes, cooking or ores going to the smithy yet;
  re-run the balance with those in.

## 2026-10-31 — Balance pass: income per season; cows, sheep and fodder at the store
Agent: Claude Code (claude-opus-5-5) · Commit: this commit · Branch: claude/balance-pass-73de78
- Done: milestone 8's balance pass, numbers in data files only.
  - `tools/balance.py` (`python -I tools/balance.py`) reads crops, animals, fish, mine and
    shops and plays a steady year-1 plan (our guess, constants at the top of the script):
    5 / 8 / 10 seed bags kept planted in spring / summer / fall with a crop mix per season,
    2 more hens on Spring 20 and Summer 10, a cow on Summer 15, a sheep on Fall 10 and a
    second cow on Fall 25, grades 25 / 55 / 20 % low / middle / top, grazing 40 % of days
    (no feed), fishing 8 days a season (16 in winter) x 6 fish, mine trips 2 / 3 / 3 / 12 from
    floor 1 down to floor 3 / 5 / 7 / 10 breaking 40 % of the rocks, 60 G of snacks a day, one
    medicine a season; the season goals (rucksacks, extensions, tool upgrades) are bought in
    order as soon as the money is there.
  - Before (old data; the store had no cows, sheep or fodder):

    | season | crops | eggs | milk | wool | fish | mine | income | seeds | feed | animals | other | net |
    |---|---|---|---|---|---|---|---|---|---|---|---|---|
    | spring | 19800 | 6212 | 0 | 0 | 2797 | 259 | 29068 | 3560 | 492 | 3000 | 2100 | 19916 |
    | summer | 30384 | 12272 | 0 | 0 | 3501 | 1218 | 47374 | 3120 | 972 | 3000 | 2100 | 38182 |
    | fall | 48060 | 13635 | 0 | 0 | 3442 | 2062 | 67199 | 8160 | 1080 | 0 | 2100 | 55859 |
    | winter | 0 | 13635 | 0 | 0 | 4161 | 22715 | 40512 | 0 | 1800 | 0 | 1200 | 37512 |

    Every spring goal was bought by mid-spring with 13 416 G over, the second room in early
    fall, 106 969 G at the end of the year: nothing to save up for. The crop table was also
    too close to the source game's prices, so it is redone from scratch.
  - After:

    | season | crops | eggs | milk | wool | fish | mine | income | seeds | feed | animals | other | net |
    |---|---|---|---|---|---|---|---|---|---|---|---|---|
    | spring | 10260 | 3792 | 0 | 0 | 2797 | 259 | 17109 | 2380 | 590 | 2800 | 2050 | 9288 |
    | summer | 19332 | 7492 | 2616 | 0 | 3501 | 1218 | 34159 | 2784 | 1406 | 8800 | 2050 | 19119 |
    | fall | 31005 | 8325 | 5886 | 1981 | 3442 | 2062 | 52701 | 6920 | 2151 | 9600 | 2050 | 31980 |
    | winter | 0 | 8325 | 9810 | 2830 | 4161 | 22715 | 47842 | 0 | 4410 | 0 | 1150 | 42282 |

    Goals: spring buys the first rucksack, the bigger chest and the can / hoe to level 2 with
    2 788 G left; summer the kitchen corner, sickle 2, can 3 (11 907 left); fall the big
    rucksack and the second room (19 387 left); winter hoe 3, can 4, hammer 2 (53 169 left
    for year 2's level 4 / 5 tools and more animals). Crops carry spring (60 % of its
    income); animals are 22 % of the income outside the mine in spring, 32 % in fall and
    83 % in winter, where the mine is the other half.
  - Crops (`data/crops.json`, sell per item / seed bag / days to ripe, regrow): turnip
    35 / 80 / 4; potato 55 / 130 / 6; cucumber 30 / 220 / 9, every 3; tomato 35 / 240 / 9,
    every 3; onion 75 / 150 / 8; corn 70 / 320 / 11, every 4; carrot 85 / 200 / 7; eggplant
    45 / 200 / 9, every 3; pumpkin 190 / 520 / 13. Reasoning, in G a cell a day after seeds
    (regrowers sown on day 1): spring 6.2-6.8, summer 7.3 (corn 10.5), fall 9.0-10.2, so each
    season pays a bit more than the last; turnips are the cheap start (500 G buys 6 bags),
    slow crops pay about the same per day as fast ones for less replanting.
  - Animals (`data/animals.json`): eggs 30 / 45 / 70 (a hen ~40 G a day after feed, pays back
    in ~5 weeks), milk 110 / 160 / 240 (a cow ~150 a day after fodder, ~6 weeks), wool
    180 / 280 / 420 every 3 days (a sheep ~80 a day, ~6 weeks); the kinds' `price` notes match
    the store.
  - Store (`data/shops.json`): chicken 1400, cow 6000, calf 3200, sheep 3600, lamb 1900,
    chicken feed 12, fodder 25 a bundle, medicine 250; rucksacks 2000 / 6500; chest 3000,
    kitchen corner 6500, second room 18000. Smithy upgrade prices untouched (another session
    adds ore costs there); `data/mine.json` and `data/fish.json` untouched: fish is a steady
    side income (~3-4k a season) and the mine pays by going deep (floor 8+ ~400 G a floor),
    which makes it winter's big earner; once the smithy wants ores, part of that goes into
    upgrades instead of the bin.
  - Barn goods: new stock entries `animal:cow`, `animal:cow:young` (calf), `animal:sheep`,
    `animal:sheep:young` (lamb) with `to: "animal"` and `full: "The barn is full"`, and
    `fodder` with the new `to: "fodder"`. `Shop.animal_of(item)` -> {kind, young};
    `Game.shop_buy` calls `add_animal(kind, young)` / `animals.add_fodder(n)`, `shop_room`
    checks the kind's home; `Animals.stock_of(home)`; the shop screen's info line names the
    coop or the barn and shows the loft's fodder. README → Shops says so.
  - Tests: `test_shops` `_barn_goods` (prices all year, a calf / lamb cheaper, room 6 in an
    empty barn, no money refused, grown cows, cows don't use the coop's room, a calf and a lamb
    young, too many refused whole, full barn refused in Game and the menu, fodder into the loft
    and not the rucksack); the old checks read prices from the data now (turnip bags, hens,
    feed, medicine, kitchen, rucksack 2). `test_farm` reads the turnip / cucumber growth days
    from crops.json.
- Checked: all 20 tests print `OK (0 failed)`; headless `--quit-after 300` (title, `-- --demo`,
  `--map=town`, `--mine=3`, `--shop=general`, `--map=barn`) and `res://scenes/main.tscn
  --quit-after 400` printed no errors or warnings.
- Left / next: the plan is a model, not play: a real year should be played to check it (how
  many bags a person really waters, how deep the mine goes in winter). The shop screen's new
  info lines (barn room, fodder) were not looked at in a frame. Re-run the script when the
  smithy asks for ores and when cooking / contests add income.

## 2026-10-31 — Mine extras: ores for the smithy, finds sold in shops, light by depth, frozen floors
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: (1) The Kurogane Smithy asks for ores: `items` on its upgrade levels in
  data/shops.json (new keys only, on their own lines): level 2 = 3 akagane, 3 = 3 shirogane +
  2 iron sand, 4 = 3 kogane + 3 iron sand, 5 = 2 hoshigane + 2 kogane; the rod 2 akagane / 2
  shirogane / 2 kogane. `Shop.start_upgrade` takes them from the rucksack only (an ore
  overhead doesn't count) and says e.g. "Bring 1 Akagane ore" (`Shop.short_of`,
  `materials_text`; offers now give whole-number counts). `ShopMenu` marks such a row `short`
  with `lack`; the screen greys it and says "Still needs 3 Akagane ore." (an offer: "Needs 3
  Akagane ore. 2 days."). Tabs are now buy, tools, sell, build, so the smithy opens on Tools.
  (2) `buys` take the mine kinds: the smithy pays 150% for stone and 120% for ore, the store
  120% for gems; `Shop.buy_back` reads the find's sell price from data/mine.json.
  Reasoning: the ore per level follows the depth bands (akagane from floor 1, shirogane from
  4, kogane from 8, hoshigane from 13), so each tool level asks for one band deeper; the shops
  pay a little over the bin so a trip in their hours pays, while the bin still takes anything
  at any time. (3) Light by depth: `light.depths` in data/mine.json (floor 1 b8aa98 .. floor
  24 24202e, blended), kept on the floor (`MineFloor.light`, `light_at`). New `MineLight`
  (scripts/mine/mine_light.gd): a multiply shader with a lantern circle round the farmer
  (radius 3.2 cells, four rings, a slight flame flicker). 3D: the tint rect uses it down the
  mine and aims it through the camera; 2D: a rect over the view (CanvasModulate white there).
  (4) Winter: `winter` in data/mine.json freezes floors 1-9 in winter (`is_frozen`): light
  times c4d6f4, frost on 30% of the open floor (a look), 3-5 ice blocks (`kind: "ice"`, 2
  blows) placed after the hole so it is never under them, hiding the new Frost stone
  (`mine:hyoseki`, gem, 80 G, a shard icon) or rock crystal. Arrival says "Mine floor 3,
  frozen". New art `mine:ice`, `mine:frost`. New debug flag `--season=<id>`.
- Checked: all 20 tests print `OK (0 failed)` (`test_mine` adds the light blend, no floor
  lighter than the one above, the lantern and the shader's aim, 200 frozen floors, ice blows
  and finds, the winter game; `test_shops` adds ore levels each rarer than the last, names,
  rucksack-only ores, finds sold per shop, the screen's ore lines). Headless
  `--quit-after 300` printed no errors or warnings: title, `-- --demo`, `--map=town`,
  `--mine=3`, `--mine=20`, `--season=winter --mine=3`, `--map=mine_floor`, `--shop=smithy`,
  and `res://scenes/main_2d.tscn -- --demo --mine=12`. Movie Maker frames looked at:
  `--mine=2` (warm brown, a faint lantern), `--mine=20` (dark, a clear warm circle round the
  farmer), `--season=winter --mine=3` (frost patches, ice, a cooler grey, "Mine floor 3,
  frozen"), the flat view `--mine=16` (dark with the lantern circle), `--shop=smithy` (Tools
  first, "Still needs 3 Akagane ore.").
- Left / next: not played in a real window. The balance pass (another branch) may change the
  upgrade prices in shops.json; the `items` keys sit on their own lines to keep the merge easy.

## 2026-10-31 — Villagers' homes: Tome's and Kota's houses, Sayo's rooms, door hours
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three new indoor maps in `data/maps`, Japanese style of our own: `tome_house` (earth
  entry with stove and water jar, tatami room round a sunken hearth with a hanging kettle, the
  alcove with a scroll and a branch, the family altar, a chest, two cushions), `kota_house`
  (hearth, folding screen, alcove, Kota's toy box with a top and a kite) and `sayo_house`
  (Sayo's rooms behind the store: low table, alcove, screen, kitchen corner). New props drawn
  in both views: `irori`, `tokonoma`, `butsudan`, `zabuton` (not solid, `color`), `byobu`,
  `toy_box`, `mizugame` (`scripts/world3d/home_props.gd`, flat colours in MapView). The
  village doors that only gave a message now lead in: Tome's (5, 6), Kota's (8, 15), and a new
  plain side door (25, 15) right of the store's noren (`village_house` `side_door`). Doors take
  `hours` `["H:MM", "H:MM"]` and a `closed` message (`MapData.door_open`, `Game.use_door`):
  Tome 6:00-19:00 (she goes to bed early), Kota 6:00-20:00, Sayo 6:00-21:00. The old
  `quiet_house` examine rows on those doors (and the event / its line) are gone, since
  examine runs before the door. Schedules: `away` now means in bed; everyone is on their house
  map in the early morning, at noon, in the evening and all day when wet (Kota walks from his
  toys to the hearth now and then), Hachiro at the anvil in the smithy off hours (its shop
  door is shut then, so it's for later), and each goes `away` when their door shuts (Tome 19:00,
  Kota 20:00, Sayo and Hachiro 21:00). Sayo leaves by the side door; on Sundays she waits by
  Tome's house and has tea with her inside 12:40-15:00. Keeper hours unchanged (Sayo at the
  store 9:00-17:00, Hachiro at the smithy 10:00-16:00). Town spawns `tome`, `kota`, `sayo`;
  each home has a `home` spawn. Hachiro's "empty house" line and note now say Kota's roof.
- Checked: all 20 tests print `OK (0 failed)`. New checks: test_maps (the three doors lead in
  with hours and come back out in front of them, `door_open` at 6:00 / 7:00 / 19:00 / 1:00,
  broken hours refused, `Game.use_door` refuses Tome's door at 19:30 with its message and
  lets the farmer in at 8:00, every prop kind on every map has a flat colour, each home builds
  in 3D with no magenta stand-in), test_villagers (everyone home at 6:20, lunch, evening, all
  day in rain, Sayo at Tome's on Sunday, everyone `away` at 22:00, Tome can be talked to at
  home, every stretch on a house map lies inside its door's hours), test_events (house doors
  have no examine row). Smoke runs (title, `--demo`, `--map=town`, `--mine=3`, each home,
  `--map=town@sayo --time=19:00`, `res://scenes/main.tscn`) printed no errors or warnings.
  Movie Maker frames: `--demo --map=tome_house --time=6:30` (Tome on her cushion right of the
  hearth, kettle over the embers, scroll in the alcove), `--map=kota_house --time=7:30` (Kota at
  his toy box), `--map=sayo_house --time=7:30` (Sayo by the low table), `--map=town@sayo
  --time=10:00` (the side door beside the store's noren).
- Left / next: not played in a real window. The talk files have no home-specific lines yet
  (a `map` pick condition would allow "welcome in" lines). Hachiro's home is the smithy floor;
  a room of his own behind it, and festival-night door hours, are later.

## 2026-10-31 — Relationships: hearts in the text box, birthdays, the nightly loss, heart events
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: (1) Hearts: whenever a villager speaks, the wooden name tag grows a 9 x 8 heart after
  the name in the colour of their heart band (`Game.heart_band(speaker)`, -1 for the farmer,
  narration and anyone without a villager file; colours `hearts` in `data/text_box.json`: an
  empty paper heart for band 0, warmer reds up to the seal vermilion, a dark crimson with a
  gold glint for band 6; `ui:heart:<band>` in PlaceholderArt). TextBox is shared, so both
  views have it. (2) Birthdays: `birthday` `{season, day}` in each villager file (Kota spring
  19, Sayo summer 6, Tome fall 24, Hachiro winter 11; one per season, none on a festival),
  checked by `Villagers.check`; `Villagers.has_birthday` / `birthdays_on`. The farmhouse
  calendar gets a birthday part per season after the festival. A gift on the day counts
  `birthday_times` (5) over, good or bad (DESIGN); a pick condition `birthday` and a
  `birthday` line in each talk file, plus an optional `gift_birthday` answer for a gift that
  isn't disliked. (3) The nightly loss: `Affection.day_end` from `Game.end_day` (before the
  date moves): a villager the farmer has met (affection above 0) who got neither a talk nor a
  gift that day loses `neglect.loss` 1 with odds `neglect.chance` 1/8. Reasoning: DESIGN's
  rule is 1 in 10 for 1; ours is a touch stronger so a forgotten friend shows it, but a whole
  season (30 nights) away costs about 4 points, a fifth of band 1 and nothing near a band of a
  close friend, so a busy week never undoes a year; strangers (0) don't change. (4) Heart
  events, our own short scenes, one per villager at band 3: `heart_tome` (her eggplant seed,
  gives `seeds:eggplant`), `heart_kota` (the old carp in the pond, a promise choice that sets
  `kota_carp_promise`), `heart_sayo` (her father's ledger), `heart_hachiro` (the farmer's
  hands). Each adds 5 affection and sets `heart_<id>`; lines in
  `data/dialogue/heart_events.json`. Trigger rows `talk` + `who` + `hearts {id: [3, 6]}` first
  in `triggers_town.json`, and Sayo's / Hachiro's also in `triggers_store` / `triggers_smithy`
  so they play at the counter instead of the shop. Debug flag `--hearts=N` (all villagers at
  the start of band N). No new saved state, so `SaveGame.VERSION` stays 4 and older saves
  load as before (test_save / test_talk version checks unchanged).
- Checked: new `tests/test_relationships.gd` (heart art per band, the name tag and heart in a
  real TextBox, birthdays in data and calendar, x5 gifts and lines on the real Game, the
  nightly loss over 400 nights and through `end_day`, the heart event rows on every map and
  each event run to its end) prints `test_relationships: OK (0 failed)`; all 22 tests print
  `OK (0 failed)`; headless `--quit-after 300` (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, `--demo --map=house`) and `res://scenes/main.tscn --quit-after 400` printed
  no errors or warnings. Movie Maker frames: `--demo --map=town --time=14:30 --hearts=4
  --talk=tome` (3D: "Tome" with a red heart on the tag, her close_1 line) and
  `res://scenes/main_2d.tscn ... --demo --hearts=6 --dialogue=talk_kota@new_1` (2D: the band 6
  crimson heart with its gold glint).
- Left / next: endings (milestone 9). Not played in a real window; the heart events were run
  headless only, not watched. Later for relationships: events at higher bands, the birthday as
  a day-plan condition and fair weather on it (DESIGN), heart events in the villagers' houses.

## 2026-10-31 — Festival contests, festival music, payout held, Blossom Day's stall
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: (1) Contests, all our own, one per festival in `data/festivals.json` → `contest`:
  Blossom Crop Show (a crop), Lantern Night Catch (a fish), Moon Offering (egg, milk or wool),
  First Stone of the Year (a mine ore or stone). A new `judge_table` prop (white cloth, red and
  white curtain, name board, three rosettes; 3D in FestivalProps, a box in FestivalView) holds
  the `table` cell. E there in the hours: empty-handed Tsuru says what to bring
  (`data/dialogue/contests.json` `<id>_ask`); with the right kind overhead (`Game.item_kind`)
  the entry is handed in and judged at once (`Game.enter_contest`, `Festivals.judge`): it
  scores its shipping value (a crop of the festival's season x `in_season` 1.5 at Blossom Day),
  three villager rivals roll from their ranges with a seed of festival + year, the farmer wins
  ties. The place's prize is paid (`Prize: 500 G and 2 x Sakura mochi` in the HUD), flags
  `contest_place_<n>` / `contest_won_<rival>` / `contest_prize` are set (cleared from last
  time; `contest_wins` counts first prizes), and `data/events/contest_*.json` plays a chime,
  the result lines (opening, the winning rival's line, the farmer's place) and coins if a
  prize came. One entry a year (`events_seen` `contest:<id>:<year>`). Festivals.check
  validates the contest (kind, table on a judge_table, ask line, rivals are villager files,
  prizes by place, event). Balance (ours, modest for the balance pass): prizes 500 / 200 / 100 G
  plus a food for first (sakura mochi x2, mugwort tea, dango x3, kagami mochi); rival ranges
  sit so that a good entry of the season usually wins (Blossom: rivals 50-125, a potato in
  season scores 120; Lantern: Hachiro 90-190, an iwana 200 wins; Moon: 40-170, rich milk 150 is
  near the top; Year: Hachiro 50-160, amber 150 / jade 300). (2) Music: a rule key `festivals`
  (`MusicPicker.pick(..., festival)`, Sfx passes `Game.festival_now()`: today's festival in its
  hours on its map); four new scores `fest_blossom` (yo, koto and flute with taiko),
  `fest_lanterns` (minyo matsuri, taiko and a kane bell, 128 bpm), `fest_moon` (3/4, rin and
  sho), `fest_year` (slow sho chords, rin); new instruments `taiko`, `kane`. The festival rules
  come before rain and night. (3) Payout: `Game.pay_bin` holds on a festival day (DESIGN), at
  18:00 and overnight, with a message; the next day's payout includes it. (4) Stall: a festival
  `stall` (`{name, cell, stock}` on a `stall` prop) opens as shop `stall:<festival>` in the
  hours (`Game.open_stall`, `Game.shop` builds it from `Festivals.stall_shop_data`); Blossom
  Day's Hanami Dango Stall sells dango, sakura mochi and green tea at their own prices; its
  screen says "Open 10:00-16:00, Blossom Day only". `Game.item_name` names foods now. Flags
  `--contest=<item>` (with `--festival`) and `--shop=stall:<id>`.
- Checked: all 20 tests print `OK (0 failed)` (test_festivals adds contest data / judging /
  every result-line path / entering in the game / the stall / the payout; test_audio adds the
  festival music rule). Headless `--quit-after 300` smoke runs (title, `--demo`, `--map=town`,
  `--mine=3`, all four `--festival=<id>`, two `--contest` runs, the stall) and
  `res://scenes/main.tscn --festival=blossom_day` printed no errors or warnings. Movie Maker
  frames: `--demo --festival=blossom_day --contest=potato` (judges' table by the cherries,
  Tsuru's results line), `--demo --festival=lantern_night --contest=fish:iwana` (the table
  among the stalls, lanterns and a firework), `--demo --festival=blossom_day
  --shop=stall:blossom_day` (the stall's buy list).
- Left / next: the new scores were not heard by a person; rivals don't walk up with their
  entries yet (only lines); the result line after the opening needs a key press, so frames
  show the opening. The other stalls at Lantern Night are still only looks.

## 2026-10-31 — Cooking at the kitchen corner; raw farm goods as food
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: raw food: `data/foods.json` got a `raw` table (every crop, the three egg and milk
  grades, `fish:*` for any fish; DESIGN's "about +3 / -1": vegetables 2-5 stamina / -1 fatigue,
  eggs 4-8, milk 8-14 and drunk, fish 3). `Game.food_info` / `edible` / `eat_item(item,
  places)` eat any of them (`eat(id)` is now a wrapper; same rules: kept when it would do
  nothing). Eaten from the rucksack with the new `eat` action (F, Esc → Settings → Controls;
  `InventoryMenu.eat`, not out of the chest) or overhead: with the food slot in hand the tool
  button eats an edible held item instead of setting it down (`FarmActions.eat_held`). The food
  slot now works on every map (it used to be the farm and the mine only). `Game.item_name`
  names `food:<id>` items. Q with the food slot cycles the stand's foods plus any food
  carried, so kitchen dishes and specials only show up while you have some.
  Cooking: new `Cooking` (scripts/cooking/cooking.gd, pure rules) and `data/recipes.json`.
  A recipe's id is its dish, a food in foods.json (`shop: false`), so dishes eat, show and
  cycle like any food. Needs are items or groups (pickling vegetable, soup vegetable, egg,
  milk in grade order; any fish by prefix); they come out of the rucksack, the hand, then the
  storage chest, tried on a copy first so a missing ingredient or a full rucksack changes
  nothing (a slot the ingredients free counts). The pantry (rice, miso, soy) is not tracked.
  Nine dishes of our own: onigiri x2 (a pickle vegetable; the stand's food), miso soup,
  grilled fish, tamagoyaki (2 eggs) known from the start; turnip stew (2 turnips + carrot,
  Tome), potato stew (2 potatoes + onion, Sayo), ochazuke (fish + green tea, Hachiro),
  pumpkin nimono x2 (Kota) and milk pudding (milk + egg, the farmhouse radio's Saturday
  cooking hour). No daikon or rice crop exists yet, so turnip stands in for daikon.
  Numbers: a dish is worth more stamina than its ingredients eaten raw and roughly what the
  stand charges per stamina (onigiri 15 for 60 G): miso soup 20 / -3, grilled fish 28 / -2,
  tamagoyaki 35 / -3, turnip stew 50 / -5, potato stew 55 / -4, ochazuke 35 / -6 (the tea),
  pumpkin nimono 32 / -3 each, milk pudding 42 / -5. The kitchen's kamado and mizuya props
  have `use: cook` (house.json, plus a `kitchen` spawn); E calls `Game.open_cooking()` →
  `cooking_requested` → `CookingScreen` (both views): the known recipes with icons, ready /
  missing, the about line, "Needs 2 any egg (3)", Enter cooks once (a new `cook` sizzle in
  data/sfx.json). New icon shapes bowl, plate, fish_plate in PlaceholderArt.
  Learning: a recipe is known when `start` or when the flag `recipe_<id>` is set; flags are
  already saved, so the save format and `SaveGame.VERSION` did not change. Lessons are events
  `data/events/recipe_{tome,sayo,hachiro,kota,radio}.json` (lines in
  `data/dialogue/recipe_lessons.json`) played by one trigger row each: `talk` with `who`,
  `hearts` [1, 6] and `not_flags` in triggers_town (Tome, Kota), triggers_store (Sayo, also at
  the counter: the lesson plays instead of the shop that once), triggers_smithy (Hachiro);
  `examine` on the radio with `weekday: sat` in triggers_house. `-- --cook` stands at the stove
  with the screen open (`--demo` adds eggs, a fish, a carrot, an onion and the turnip stew).
- Checked: new `tests/test_cooking.gd` (data, font and icons, kitchen needed, known / unknown,
  makes 2, rucksack + chest, group order, any fish, the hand, a failed cooking changes
  nothing, full rucksack and a freed slot, flags through to_dict / from_dict, CookingMenu
  rows / needs text / choose / wrap / mouse, every taught recipe has an event and a trigger
  row, Tome's talk row and the radio by weekday, E at both kitchen props in the real Game, the
  screen opening / cooking / closing) and the extended `tests/test_food.gd` (raw data, raw
  eating, drink sound for milk, fish:*, inedible things, the hand, the rucksack's eat key,
  the new Q cycle, eating indoors, eating the held tomato, not the held wool) print OK; all 21
  tests in AGENTS.md print `OK (0 failed)`. Headless smoke runs (title, `--demo`, `--map=town`,
  `--mine=3`, `--map=house --built=kitchen,chest,room`, `--demo --cook`, `main.tscn`,
  `main_2d.tscn --demo --cook`) printed no errors or warnings. Movie Maker frame `--demo --cook`
  (frame 19): the farmhouse with the "Kitchen  5 of 9 known" box, onigiri x2, miso soup,
  grilled fish, tamagoyaki, turnip stew all "ready" in vermilion with their icons, "A rolled
  omelette, a little sweet." / "Needs 2 any egg (2)" (the highlight followed the real
  window's mouse).
- Left / next: not played by hand in a real window; the sizzle was not heard. No daikon or
  rice crop (recipes would take them once they exist); dishes can't be sold or given yet
  (gift lists don't name them); no cooking tools (pot, knife) or failed dishes. Merge note:
  shared touches are Game (food / cooking section, `--cook`), FarmActions (eat_held, food
  before the farm check), data/controls.json (`eat`), foods.json (`raw`, dishes), house.json,
  four trigger tables (one row each) and sfx.json (`cook`).

## 2026-10-31 — Merged six branches: talking, opening event, shop extras, barn, mine, festivals
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time, all tests after each, in this order:
  `claude/talk-gifts-9356cc` (c3ddc09), `claude/opening-event-97bc8c` (3a3c5e4),
  `claude/shop-extras-868703` (6dd2e34), `claude/barn-animals-b077fb` (4e43d8c),
  `claude/mining-cf98d9` (a5c4d62), `claude/festivals-a062df` (f0b26ab). WORKLOG kept every
  branch's entry; AGENTS / README / ROADMAP kept both sides (test list, debug flags, sections);
  "Next up" now points at the balance pass, then relationships and endings. Code joins:
  - Save version: talking and the barn both raised it to 3. Now 3 = affection, 4 = the barn
    and the dog (`SaveGame.VERSION := 4`; `Animals.parse` gives the new-game fodder and dog to
    saves before 4). `test_animals` checks a version 3 save without the barn loads and a
    version 4 one without it is refused; `test_talk` checks version 3 or later.
  - Event steps: `affection` (talking) and `place` / `actor` (opening) side by side in
    `EventRunner.COMMANDS`. `Villagers.where` gives an event actor's place first, then the
    plan with the talk turn.
  - Shops: `data/shops.json` `_about` describes both the keeper rule and the new stock /
    rucksack / builds keys; keepers Sayo and Hachiro kept, the rod in the smithy's tools.
    `open_shop` checks a festival / hours (`_shop_shut`) and then the keeper.
  - `FarmActions`: the dog in arms first, then talk, then hold / throw; `interact` asks the
    coop, the barn, then mine pick-ups. `main_3d` sets up the animal layer with the player
    (dog) and adds the mine layer. Map props: barn and mine kinds in both views.
  - `Game`: new-game, save and load keep affection, house extensions, the mine's deepest floor
    and the barn; `trigger_state` has both `hearts` and `festival`; villager rules accept
    `festival` and files accept `gifts`.
- Checked on merged main: all 20 tests (`test_animals`, `test_audio`, `test_body`,
  `test_dialogue`, `test_events`, `test_farm`, `test_festivals`, `test_fishing`, `test_food`,
  `test_hold`, `test_inventory`, `test_maps`, `test_menu`, `test_mine`, `test_save`,
  `test_shops`, `test_talk`, `test_title`, `test_villagers`, `test_weather`) print
  `OK (0 failed)`; headless `--quit-after 300` (title, `-- --demo`, `--map=town`, `--map=barn`,
  `--mine=3`, `--festival=lantern_night`, `--map=farm@barn --barn-out`, `--shop=general`,
  `--map=town --time=14:30 --talk=tome`, `--map=house --built=kitchen,chest,room`,
  `--fishing`, `--map=coop`) and `res://scenes/main.tscn --quit-after 400` (also with
  `--festival=blossom_day`) printed no errors or warnings. Movie Maker frames:
  `--demo --festival=lantern_night` (lanterns, a firework, "Lantern Night" under the clock),
  `--demo --map=town --time=14:30 --talk=tome` (Tome's talk box with her portrait).
- Left / next: none of the six was played in a real window, and the new sounds were not
  heard. The smithy doesn't ask for ores yet; cows / sheep / fodder aren't in the store's
  stock (hooks: `Game.add_animal("cow" | "sheep", young)`, `Game.animals.add_fodder(n)`).

## 2026-10-31 — Talking, gifts, affection; keepers at their counters; bump delay
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: E facing a villager (or a counter with them behind it, `Talk.facing_villager`) turns
  them to the farmer and calls `Game.talk_to(id, face)`. New `Talk`
  (scripts/villagers/talk.gd): each villager's lines are `data/dialogue/talk_<id>.json`, a
  normal dialogue plus `picks` (first row whose `if` holds; rule conditions plus `time`,
  heart `band`, `again`; the day picks one of the row's lines, so a villager repeats a line
  all day and changes it tomorrow) and the gift answers `gift_love` .. `gift_hate`,
  `gift_again`. About 20 lines each for Tome, Hachiro, Sayo and Kota, our own, quiet
  village tone; speakers.json got their portrait colours (bun / cap styles for now). New
  `Affection` (scripts/villagers/affection.gd, `Game.affection`): points 0..255, 7 heart
  bands, the last talk / gift day per villager. Gifts: E with an item overhead gives it;
  reactions from the villager file's `gifts` lists (`fish:*` = any fish, the rest neutral),
  one gift a day (a second is refused and stays in hand). Numbers in
  `data/villagers/_common.json`: talk +1 once a day, gifts +8 / +3 / +1 / -3 / -8, bands start
  at 0, 20, 50, 90, 140, 190, 235. Reasoning: a daily talk alone reaches band 3 around the end
  of year 1, a loved gift every day gets there within a season, so gifts matter but talking
  isn't worthless; the gift steps are a bit softer than a straight copy of DESIGN's table.
  Save version 3 writes `affection`; older saves load with everyone at 0 (a version 3 save
  without it is refused); `Affection.parse` keeps ids of villagers whose file is gone.
  Event hooks: `affection` step (`who`, `amount`), a `talk` trigger cause with `who` (the
  event plays instead of the lines; EventPlayer.talked_to) and a `hearts` row key for any
  cause; `Game.trigger_state` carries `hearts`.
  Shopkeepers: shops.json keepers are Sayo (store) and Hachiro (smithy). Sayo's plan now
  stands her at the store's keeper spot 9:00-17:00 and her day off moved from Wednesday to
  Sunday (the store's day off). Hachiro, whose house is the smithy since the shops merge,
  mends the empty house 8:00-9:30, keeps the smithy 10:00-16:00 (also in bad weather, where he
  used to stay in) and fishes on Sundays; the smithy's day off moved from Wednesday to
  Sunday to match. Talking to a keeper at their spot opens the shop (and counts as the day's
  talk); `Game.open_shop` also says "Nobody is at the counter" when a shop's keeper isn't on
  its map (the hours still come first, the screenshot flag skips both).
  Bump delay (the later roadmap item, small enough): a talk holds the villager
  `talk_turn_minutes` (2) after it, a villager walking into the farmer (within 0.9 cells,
  heading their way) waits; both add to their delay, so the whole plan runs later, at most
  30 minutes, cleared at 12:00 and 18:00 (`Villagers.plan_minute`, `bump`, called from
  `Game._process` while the clock runs). The farmer can't step within 0.7 cells of a
  villager but can always step away (`Player._try_move` → `Game.villager_in_way`). Nothing
  of this is saved (a load starts every villager on time).
  `-- --talk=<villager>` (3D view) puts the farmer below them, facing up, and presses E.
  test_animals now checks `SaveGame.VERSION >= 2` so later version bumps don't break it.
- Checked: new `tests/test_talk.gd` (talk files run, picks per season / weather / time /
  band / day, file and villager errors, reactions, daily limits, bands, save round trip,
  version 2 save, broken data, keepers across the counter, the keeper-out message, event
  step and trigger rows, delay, bump and blocking) and every test in AGENTS.md print
  `OK (0 failed)` (test_villagers updated for the keepers being indoors). Headless
  `--quit-after 300` (title, `-- --demo`, `--demo --map=town`, `--demo --map=store@counter`,
  `--demo --map=town --time=14:30 --talk=tome`) and `res://scenes/main.tscn --quit-after 400`
  printed no errors or warnings. Movie Maker frame `--demo --map=town --time=14:30
  --talk=tome` (frame 39): the farmer below Tome by the pond, Kota beside them, the paper
  text box with Tome's grey-bun portrait, the "Tome" name tag and "Hm? Ah, the new farmer.
  The path" typing out.
- Left / next: not played in a real window (talking, gifting, bumping by hand). No hearts in
  the text box yet, no birthdays, no daily affection loss for ignored villagers, no
  whistling; the portraits reuse the bun / cap styles. The 2D view still has no action
  hookup, so talking works in the 3D view only. Merge note: Game, SaveGame (version 3),
  EventTriggers / EventRunner, shops.json keepers and Sayo / Hachiro plans are the shared
  touches.
## 2026-10-31 — Shop intros: Hachiro keeps the smithy (matches the talking branch)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the talking branch (`claude/talk-gifts-9356cc`) made Hachiro the smith (his house
  door has been the smithy since the shops merge) and Sayo the store keeper, standing on the
  shop maps at the keeper spot (3, 2) in opening hours. To merge cleanly: `gen.json` is
  gone; `smithy_intro` now has Hachiro turn from the forge to the keeper spot (flag
  `met_hachiro`, lines rewritten for him; "shut on Sundays", their new day off); both
  intros leave the keeper standing at (3, 2) facing down, where their plans put them after
  the event (no walking off any more); the opening's road line names Hachiro.
  `data/dialogue/speakers.json` is now the same as on the talking branch (tome, hachiro,
  sayo, kota with their colours), so it merges without a conflict. The actor override
  moved into `Villagers.where` and `on_map` asks `where`, the same shape as on that branch.
  This replaces the Gen parts of the entry below.
- Checked: all 17 tests in AGENTS.md print `OK (0 failed)` (`test_events` now checks the
  smithy intro with `hachiro` and `met_hachiro`); headless `--quit-after 300` (title,
  `--demo`, `--demo --map=town`, `--demo --map=store`, `--demo --event=opening`,
  `--demo --event=smithy_intro --map=smithy`) and `res://scenes/main.tscn --quit-after 900`
  printed no errors or warnings. Movie Maker: smithy intro frame 149 shows Hachiro (headband)
  behind the counter with his portrait and name tag; `res://scenes/main.tscn` frame 159
  still shows the opening's text box with Tome by the pond.
- Left / next: on this branch alone the keepers still vanish after their intro (their plans
  here don't stand them in the shops); after the merge Game.open_shop needs the keeper on
  the shop map, which the plans give in opening hours, and the intro plays only then (the
  door is shut outside the hours).

## 2026-10-31 — Opening event and first visits to the shops
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: a new game now opens with `opening` (data/events/opening.json, lines in
  data/dialogue/opening.json, our own): the screen comes up on the farmer just inside the
  farm gate; Grandma Tome is waiting by the pond, greets them (the village head Tsuru sent
  her), points out the field, the shipping bin and stand, and the road east to the village
  (the store's Sayo, the smithy's Gen), gives 2 bags of seed potatoes (flag `met_tome`) and
  walks home through the gate. `triggers_farm.json` plays it where `first_morning` used to be
  (spring 1, year 1, 6:00-9:00), with `not_seen: ["first_morning"]` so saves from before the
  opening never get it; `first_morning` stays as the runner test's sample and for `--event`.
  First visits: new `triggers_store.json` / `triggers_smithy.json` play `store_intro` (Sayo
  behind the counter: what Yorozu sells, that she buys crops, hours) and `smithy_intro` (Gen
  turns from the forge: tool upgrades over days, hours) once each on `enter` (flags
  `met_sayo`, `met_gen`); lines in data/dialogue/shop_intros.json. Events got two steps:
  `place` (the farmer onto a cell at once) and `actor` (a villager placed with `at`, turned
  with `face`, walked with `to`, taken off with `leave`; EventRunner.actors, gone when the
  event ends). EventPlayer copies the actors into `Villagers.actors`, which `on_map` uses in
  place of their day plan, so both views draw them with no view changes. New villager file
  `gen.json` (the smith, plan `away` all day: only seen in his intro for now) and speakers
  tome, sayo, gen. Continue: the opening is in `events_seen` from the moment it starts, and
  the save keeps that list, so a loaded game never replays it; `--demo` still keeps the
  trigger tables off (unchanged EventPlayer rule). Numbers: 2 potato bags (a starter gift
  next to the turnips already in the bag, not enough to skip the stand).
- Checked: `test_events` (new: the farm table picks the opening on a new game, not after a
  save round trip, not for an older save that saw the first morning; the whole opening
  played with boxes closed: gate position, Tome placed / walking / turning all four ways /
  gone, lines in order, potatoes and flag; 9 bad actor / place steps refused; both shop
  tables once each with the keeper as actor; in the tree: a new game's EventPlayer plays the
  opening with Tome on the farm in `Villagers.on_map`, a loaded save doesn't, the store and
  smithy intros play on the first entering only) and all the other tests in AGENTS.md print
  `OK (0 failed)` (17 scripts). A mutation (store table removed, opening's `not_seen`
  changed) made 4 checks fail, so they bite. Headless `--quit-after 300` (title, `--demo`,
  `--demo --map=town`, `--demo --map=store`, `--demo --event=opening`,
  `--demo --event=smithy_intro --map=smithy`) and `res://scenes/main.tscn --quit-after 900`
  printed no errors or warnings. Movie Maker: `res://scenes/main.tscn` frame 159 shows the
  opening's text box ("So this is the farm...") with Tome standing by the pond; the smithy
  intro frame shows Gen behind the counter with his portrait (headband made off-white after
  the first frame looked like the farmer's red cap).
- Left / next: the keepers vanish when their intro ends (they go to the back first);
  standing at the counters all day comes with the talking branch, which should use the ids
  `sayo` and `gen` (an actor overrides the plan by id). The opening was not played in a
  real window with key presses (tests close the boxes), and the actors' walk speed is the
  farmer's, not the villager speed in `_common.json`.
## 2026-10-31 — Store extras: rucksacks, house extensions, chickens / feed / medicine; the rod at the smithy
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: milestone 8's open item and the loose ends of the last merge.
  - Store `supplies` (every season, listed first in Buy): Chicken (`animal:chicken`, `to:
    "animal"` → `Game.add_animal`, all or nothing within the coop's room, "The coop is full"),
    Chicken feed (`to: "feed"` → `animals.add_feed(n)`), Animal Medicine (`medicine` into the
    rucksack). A stock entry's `name` names it; an animal kind the game doesn't know has no
    room, so a cow row would refuse until the barn branch lands (no cow / sheep stock added).
  - Rucksack: `rucksack.levels` in the store's data (12 slots, then 16), shown as the first
    Buy row while a bigger one exists; `Shop.buy_rucksack` grows the bag (`Inventory.grow`).
    The bag's size is the level, so nothing new is saved for it.
  - House extensions: `builds` in the store's data (builder Hachiro, the carpenter villager,
    so no new map or door): Bigger storage chest (chest 24 → 48 slots, a nagamochi lid in
    the house with `use: "storage"` opening the same chest), Kitchen corner (kamado and
    mizuya on the earth floor; `Game.has_built("kitchen")` is the hook for cooking), Second
    room (house 8 → 12 wide, a tatami room east through an opening, kotatsu / tansu / andon).
    A Build tab orders one at a time, paid now; `Game.end_day` finishes it going into the
    ready day with a morning message. The map changes are data: `extensions` in
    data/maps/house.json (props added, size / ground replaced), applied by
    `MapManager.with_extensions` for the list in `MapManager.built` (`set_built` drops the map
    cache). Saved as `house` {built, job}; older saves load with none; the saved position is
    checked against the house the save has built.
  - Rod: the smithy's tool list has the rod with its own price list (`upgrades.tool_levels`);
    data/fish.json `rod.bite_factor` [1.0, 1.2, 1.4, 1.6] gives its levels, the bite chance per
    check is multiplied by it. `Game.leveled_tools()` (charging tools + rod) feeds new games
    and the save (older saves: rod level 1); the rod gets no experience and still doesn't charge.
  - New 3D props (kamado, mizuya, nagamochi, kotatsu) and flat colours; screen rows / info
    lines for the new goods (room in the coop, feed in the sack, bag slots, build state and
    finish day); `--shop=<id>@<tab>` and `--built=a,b` debug flags.
- Balance (ours): Chicken 1500 G (a plain egg 50 G less 10 G feed pays it back in about five
  weeks, a happy hen's 110 G egg in about two); feed 10 G a portion (a fifth of a plain egg,
  and grazing saves it); medicine 300 G (sickness costs up to 5 nights of eggs, so it pays
  but is no reflex buy). Rucksack 2000 G (12 slots, about the first smithy upgrade) and
  6000 G (16). Extensions: chest 3000 G / 2 days, kitchen 5000 G / 3 days, second room
  15000 G / 5 days (the room is comfort, priced near a level-4 tool). Rod 800 / 2000 / 4500 G
  for levels 2-4 (2 / 2 / 3 days): cheaper than tools since it only speeds bites (+20% each).
- Checked: `test_shops: OK (0 failed)` with new checks: data (supplies, rod levels, every mix
  of extensions parses with door / futon / spawns free), rucksack (offers, no money, two
  levels through Game and the menu, max level), chickens (no money, too many for the room,
  4 grown hens, coop full, the menu's refusal, unknown kind), feed and medicine (bought / no
  money), builds (no money, order note, one at a time, unknown builds, the Build rows, not
  done before the ready day, done on it with the stove on the map and the morning message,
  already built, chest 48 slots and the storage lid, the second room, new game resets),
  the rod (offer, no money, hand in / collect at level 2 with factor 1.2, top level refused),
  saving (house and rod level round trip, the job finishing after load, a save from before,
  standing in an unbuilt room refused, 8 broken house values, a rod past its top). A planted
  wrong value in three of them was reported, then removed. All 17 tests in AGENTS.md print
  `OK (0 failed)`. Headless `--quit-after 300` (title, `--demo`, `--demo --map=town`,
  `--shop=general`, `--shop=general@build`, `--shop=smithy`, `--map=house
  --built=kitchen,chest,room`), `res://scenes/main.tscn --quit-after 400` and the 2D scene
  with `--map=house --built=room` printed no errors or warnings. Movie Maker frames:
  `--demo --shop=general` (Bigger rucksack (12 slots) 2000 G, Chicken 1500 G, Chicken feed
  10 G, Animal Medicine 300 G above the spring seeds; the rows over 500 G in the soft ink,
  pixel (122, 96, 64) against (59, 42, 26)), `--shop=general@build` (three extensions with
  prices and "48 slots, with a second lid in the house. 2 days."), `--map=house
  --built=kitchen,chest,room` (pot on the kamado, the nagamochi by the tansu, the second
  room with kotatsu and tansu to the right).
- Left / next: not played in a real window. The new goods use the furoshiki fallback icon.
  The kitchen does nothing yet (cooking later); Hachiro's schedule doesn't show him building;
  the rod has no look per level. Cow / sheep rows go in `supplies` once the barn branch merges.
## 2026-10-31 — Cows, sheep and the barn; the farm dog
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: milestone 7's second item (DESIGN "สัตว์"; ideas only, our numbers and code).
  - `Animals` now keeps a state per home (`state[home] = {out, stock, box}`; `outside`,
    `feed_stock`, `feed_box` stay as the coop's names, so the chicken code is unchanged).
    Helpers `home_of`, `in_home`, `home_on_map`, `spot(i)` / `animal_at(home, c)` count spots
    within each home (the coop spots no longer shift when barn animals join the list).
    `fill_feed_box` / `toggle_out` / `why_not_out` / `out_list` / `add_feed` take a home,
    default "coop". An animal also has `brushed` and `prod_days`.
  - Cows and sheep (`data/animals.json` kinds, home `barn`, capacity 6): fed from the barn's
    fodder box (20 bundles on a new game), grazing outside counts as a meal like the hens,
    brushing (+3 a night, once a day) next to petting (+2), the same sickness / medicine /
    recovery rules. `gives: {product, every, tool}`: a grown, fed, healthy night adds one to
    `prod_days` (capped at `every`, so unmilked milk doesn't pile up); `take_product` returns
    the grade by happiness (below 40 / 75 / else, like eggs). Numbers and why: a cow gives
    Milk 100 / Rich Milk 150 / Hillside Cream Milk 220 G every morning and costs 5000 G, so
    about a month pays her back, slower than crops at first but steady; a sheep costs 3000 G
    and gives Wool 120 / Soft Wool 200 / Cloud Wool 320 G every 3 nights (40-107 G a day),
    cheaper to start, less a day, same fodder. Calves grow up in 14 nights, lambs in 10
    (`Game.add_animal(kind, true)`). The barn starts empty (buying is the shop branch's).
  - The barn on the farm: `FarmGrid.BARN` x 19..23, y 1..3, door `BARN_DOOR` (21, 3), between
    the coop (13..17) and the pond (25..28), on ground that starts clear; older farms get it
    through `add_missing_fixed`. Pasture (`homes.barn.yard`) x 19..28, y 5..6, clear of the
    pond and the field. Map `data/maps/barn.json` (15 x 8, indoor): straw stall row with
    board rails between the six stalls (prop `stalls` with `blocks`), the long fodder trough
    along the back wall, the tool board, a hay stack (the fodder stock) and the gate in the
    right wall. `BarnActions`: E on the trough or the hay tops the box up and tells what's
    left, the tools tell how they're used, the gate lets them out / in; E on a cow or sheep
    does what is due: take the product overhead when ready and the hands are free (the
    tools hang in the barn, so no new tool slots), else brush, else talk, then the mood.
    Products ship like eggs (thrown into the bin, or from the rucksack). Night news is told
    in the coop or the barn.
  - The dog (`dog` in the data, saved): Goro, affection 0..100 from 10, +2 petted and +1
    picked up (once a day each), -1 for a day with neither. Pure steps in `Animals.dog_step`
    (towards the farmer once affection >= 20 and the farmer is 3..9 cells off, stopping 2
    off; else a step 30% of the time within 4 cells of its spot (11, 5); never into solid
    cells or onto the farmer); `dog_walk(delta, ...)` paces them (0.3 s), called by
    AnimalLayer / AnimalView with the Player's cell. `DogActions`: E pets, E again picks it up
    (`Game.holding()` is true and `Game.held_key()` draws it overhead in both views), either
    button sets it down in front, doors say to put it down first. The night puts it home.
  - Art (`placeholder_art.gd`): `animal:<cow|calf|sheep|sheep_shorn|lamb|dog>:<idle|peck|walk|sick>:<f>`
    (dog also `sit`, `held`) from one side-view quadruped drawer: Japanese Black cattle,
    cream sheep with dark faces (thin and grey once shorn), a red-tan shiba-like dog with a
    curled tail. Milk bottles and wool bundles per grade (world and slot icons). 3D:
    `BarnProps` (board barn on a plaster band, kawara gable roof, two-leaf door, slatted
    windows, loft hatch; trough, stall rails, hay bundles, gate) and the hay mounds in the
    trough; 2D: MapView / FarmView colours. Sounds `cow_moo`, `sheep_baa`, `dog_bark`,
    `brush_stroke`, `milk_squirt`, `shear_snip`.
  - Save version 3 (`SaveGame.VERSION`): `animals.barn` and `animals.dog`; a version 3 save
    without them is refused, a version 2 save gets the new-game fodder and dog, animals
    without `brushed` / `prod_days` get false / 0.
  - Debug: `-- --demo --map=barn` (a cow with milk, a sheep in wool, a calf, a full trough;
    `--demo` also makes the dog fond enough to follow), `--barn-out` with `--map=farm@barn`.
- Checked: `test_animals: OK (0 failed)` (380 checks; new: barn data and places, spots per
  home, fodder, milking cycle and grades, shearing cycle and the shorn look, brushing,
  grazing, left out, sick cow, calf growing, the dog's pet / lift / put / night / follow /
  wander / walls / pacing, barn + dog round trip and 11 broken saves, version 2 / 3 loads,
  Game hooks / prices / milk into the bin, BarnActions and DogActions through FarmActions
  with the real autoload, the barn map, the barn on old farms, pasture open, art sizes).
  All 17 test scripts print `OK (0 failed)`. (One run of `test_save` failed 7 checks with
  "The save file is broken" while other sessions ran tests: every worktree shares the same
  `user://` folder; run alone twice it printed `test_save: OK (0 failed)` both times.)
  Headless `--quit-after 300` (title, `-- --demo`, `--demo --map=town`, `--demo --map=barn`,
  `--demo --map=coop`, `--demo --map=farm@barn --barn-out`), `res://scenes/main.tscn
  --quit-after 400` and `res://scenes/main_2d.tscn` (`--demo --map=barn`, `--demo
  --barn-out`) printed no errors or warnings. Movie Maker frames: `--demo --map=barn` (black
  cow, sheep and calf in the straw stalls, hay in the trough, rails, hay bundles),
  `--demo --map=farm@barn --barn-out` (the tiled barn between the coop and the pond, a
  sheep and the cow grazing), `--demo` at frame 90 (Goro has followed the farmer from the
  stand and sits two cells off).
- Left / next: not played in a real window (keys, the dog's pace, carrying it). No shop sells
  cows, sheep, fodder or medicine yet (shops branch; hooks above). Barn animals out on the
  farm can't be tended; the dog can't be called or taught tricks; no festivals for animals
  yet. Main's merge: other branches may also raise `SaveGame.VERSION` to 3.
## 2026-10-31 — Mining: the mine entrance and floors made fresh from a seed
Agent: Claude Code (claude-opus-5-5) · Commit: this commit · Branch: claude/mining-cf98d9
- Done: milestone 9's mining part, our own design (DESIGN has no mine rules).
  - Maps: the village road's east end (new walk-off door on `town.json` cells (36, 10-11),
    the only change to a shared map) leads to `mine` (a hollow under a cliff, a timber-framed
    adit with a shimenawa rope, two stone lanterns, pines). Its cave mouth goes down to
    `mine_floor`, one 18 x 14 cave every floor is laid out on (rock walls, a pillar, the
    ladder up in the back wall). New map key `sheltered` (no weather; buildings by default):
    the cave isn't `indoor`, so the clock runs down there, with its own light.
  - Rules: `MineFloor` (scripts/mine/mine_floor.gd, pure) lays a floor out from a seed, the
    depth and the season: rocks / big rocks / soft spots by the floor band's counts, never on
    walls, doors or next to the ladder, each with its find rolled up front; one hole down under
    a soft spot (30 %) or a rock, at least 5 cells from the ladder. `hit` (hits per rock kind
    and band), `dig`, `area_cells` (walls cut a charged hoe), finds left lying (`leave` /
    `take`). The open hole is a door (`down: true`) to the next floor.
  - Game: `Game.maps.mine_floor` (MapManager: rocks solid, the hole a door); `go_to_map` makes
    floor 1 from the cave mouth and depth + 1 from a hole, each with a new seed; the ladder goes
    straight back up. `mine_swing(tool, origin, facing, charge)`: hammer / hoe only, the charge
    rule's stamina and the usual work fatigue (rain, late, overwork), tool experience; finds go
    to the rucksack, else overhead, else stay on the ground (`mine_pick_up`, E). "Mine floor N"
    on arrival. `sell_price` / `item_name` know `mine:<id>`, so finds ship and show names.
  - Data (`data/mine.json`): four bands (floors 1, 4, 8, 13+) with counts, hits and finds per
    source; season factors (spring clay x1.5, summer amber x1.5, fall agate x1.5, winter rock
    crystal x2); 11 items: Grey stone 2 G, Potter's clay 6, Iron sand 10, Akagane ore 18,
    Shirogane ore 40, Kogane ore 90, Hoshigane ore 400, Agate 60, Rock crystal 120, Amber 150,
    Jade 300. Balance reasoning: a floor-1 rock is worth about 4 G on average against 2
    stamina a tap, less than a crop day, so the mine pays by going deeper (floor 8+ rocks take
    2 taps but average ~24 G); ores keep their sell prices low because the smithy is meant to
    want them for upgrades. The smithy can name `mine:akagane` .. `mine:hoshigane` in
    `upgrades.items`; data/shops.json is untouched (another branch).
  - Save: only `mine: {deepest}` (0..9999; older saves: 0). A save made down the mine (F5)
    writes the cave mouth as the position; a save that says `mine_floor` also loads there.
  - Views and art: `MineLayer` (3D: rocks as sprites, soft spots / the hole as flat quads,
    loose finds) and `MineView` (2D); `MapWorld` draws `rock_wall` cells as stone blocks (tall
    where nothing open lies behind them from the camera, else a low rubble ridge), the
    `cave_mouth` and `ladder` props; the target brackets and charge marks show down the mine.
    PlaceholderArt: `mine:<rock|big_rock|soft|hole>`, ground `cave`, `rock_wall`, `scree`,
    item icons `ui:mine:<id>` from the looks in data (stone, lump, sand, ore with a vein, cut
    gem, amber drop, crystal cluster). Sounds `rock_break`, `mine_find`, `mine_down` in
    data/sfx.json.
  - Flags: `-- --demo --mine=N` (a fresh floor N at the ladder), `--map=mine`, `--map=mine_floor`.
- Checked: new `tests/test_mine.gd` (data, bands, season factors, 2000-floor find shares
  within 2 % of the weights, same seed = same floor, 1200 floors keep the layout rules and
  have one hole, hole under soft ground ~30 %, hits / dig / hole as a door, area cut by walls,
  the doors between village / entrance / cave, going down and back up on Game, stamina per
  charge, rain fatigue, big rock after 4 taps, hoe finds, wrong tool / full hands cost
  nothing, full rucksack -> overhead -> ground -> E, prices and names, the save (deepest,
  position, old saves, 5 broken ones), the art) prints `test_mine: OK (0 failed)`; all 17
  other tests print `OK (0 failed)` (test_save once failed in the full run on its
  `user://test_save.json`, which the parallel sessions' tests share; it passed alone 4 times).
  Headless `--quit-after 300` (title, `-- --demo`, `--demo --map=town`, `--demo --map=mine`,
  `--demo --map=mine_floor`, `--demo --mine=9`, `--demo --weather=storm --mine=2`,
  `res://scenes/main_2d.tscn -- --demo --mine=3`) and `res://scenes/main.tscn --quit-after 400`
  (also `-- --map=mine`) printed no errors or warnings. Movie Maker frames: `--demo --mine=3` and
  `--demo --mine=9` (cave floor, rock walls, the ladder behind the farmer, rocks, soft spots,
  "Mine floor N" in the message box), `--demo --map=mine@cave` (the adit with its timber frame
  and shimenawa, scree, lanterns).
- Left / next: not played in a real window (swinging, the hole, the 2D view only ran
  headless); the new sounds were not heard. The smithy doesn't ask for ores yet and shops
  don't buy mine items (shops branch). No winter variant (optional; a frozen pond or snow cave
  could be a second cave map picked by season in data/mine.json). Finds left on the ground
  are lost when leaving the floor. The parallel sessions share `user://`, so their tests can
  collide on the same file.
## 2026-10-31 — Festivals: one per season, decorations, lights, an event once a year
Agent: Claude Code (claude-opus-5-5) · Commit: this commit (branch `claude/festivals-a062df`)
- Done: `data/festivals.json` with four festivals of our own, all in the village: Blossom Day
  (spring 8, 10:00-16:00, cherry trees, picnic mats, a dango stall; smithy shut), Lantern Night
  (summer 20, 17:00-22:00, four lantern strings, four stalls, a drum stage, fireworks
  19:30-22:00; both shops shut), Moon Night (fall 15, 18:00-23:00, pampas grass, a dango
  offering, red mats and paper lanterns at the shrine; smithy shut), Year's Turn (winter 30,
  19:00-24:00, New Year bamboo at the torii, a bonfire, an amazake stall; both shops shut).
  New `Festivals` (scripts/festivals/festivals.gd, pure logic, checks the file: dates unique,
  maps / place / events / shops exist, props on the map). Game: `festival_today()`,
  `festival` in `trigger_state`, shops closed for a festival say so at door and counter
  (`_shop_shut`), the weather rolled for a festival day is replaced with sunny the evening
  before (DESIGN), `--festival=<id>`. EventPlayer plays the festival's event on "enter" /
  "minute" in its hours, once a year (`events_seen` key `festival:<id>:<year>`, saved like any
  seen event); events `festival_*` + `data/dialogue/festivals.json` (narration, Tsuru, the
  farmer). HUD: a paper tag under the clock with the name (seal red while on). The farmhouse
  calendar notes each season's festival. Villagers: new rule condition `festival`; Kota and
  Tome get one `festival` plan (out 9:30-23:55 by the torii). Views: `FestivalProps` (3D, built
  with the map's world, shown in the hours) and `FestivalView` (2D boxes); `FestivalGlow` in
  main_3d's tint layer draws the lantern / fire glow over the night tint (strength by
  darkness) and screen-space fireworks (a launch every 1.1 s, a pure function of time).
  Balance / choices: dates spread mid-season (8, 20, 15) and the year's last evening; shops
  shut where the keepers would be at the festival; props are never solid so they can't trap
  the farmer or break villager routes.
- Checked: new `test_festivals` (data and 11 broken festivals, calendar / tomorrow, hours,
  props on / off, due event per year, villager plans, fireworks bursts and darkness, Game's
  day, the fair-weather roll through `end_day`, smithy / store shut with the message, the
  door shut, the EventPlayer playing the event when the hours start and not again that year
  but again in year 2, both views showing / hiding the props, 1 glow for Blossom Day and 41
  for Lantern Night, the HUD tag) and the 17 other tests all print `OK (0 failed)`. Headless
  `--quit-after 300` (title, `-- --demo`, `--demo --map=town`, `--demo --festival=lantern_night`,
  `--festival=blossom_day`, `--demo --festival=years_turn --map=farm`) and
  `res://scenes/main.tscn --quit-after 400` printed no errors or warnings. Movie Maker frames:
  each festival with `--demo --festival=<id>` (lanterns glowing and a burst over the road at
  20:01, cherry trees at 10:30, the offering and pampas at 18:30, the bonfire and bamboo at
  19:30; the HUD tag under the clock), and `res://scenes/main.tscn -- --festival=blossom_day`
  (the Blossom Day text box typing).
- Left / next: not played in a real window (event timing, how the glow reads on a real
  screen); no festival music (needs a `festival` condition in the music rules and the
  picker's call in Sfx); no contests / prizes (DESIGN's open question); the shipping payout
  isn't held back on a festival day yet; the speakers file has no villagers, so festival
  lines are narration, Tsuru and the farmer (the talking branch can add villager lines); the
  2D view has no glow or fireworks. Shared files touched (small): game.gd (+ ~25 lines),
  villagers.gd (condition), kota / tome (one rule + one plan each), event_player.gd, hud.gd,
  main_3d / main_2d (one line each), examine_house.json (calendar lines).

## 2026-10-31 — Merged six branches: key remap, examine, villagers, shops, chickens, fishing
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time, all tests after each, in this order:
  `claude/key-remap-174d29` (a262366), `claude/examine-events-2eb476` (5abb1cb),
  `claude/villager-schedules-7ac4c0` (c8ca779), `claude/shops-f496a9` (3f2724a),
  `claude/chickens-c6a5f5` (3a5c7a3), `claude/fishing-72b72b` (e2026a2). WORKLOG kept every
  branch's entry; AGENTS / README / ROADMAP kept both sides (test list, debug flags,
  sections); "Next up" now points at talking / gifts / affection with the shopkeepers at
  their counters. Code joins:
  - Examine + shops: the smithy door (27, 6) had a `quiet_house` examine row; it is a shop
    door now, so the row is gone from `data/events/triggers_town.json`.
  - Shops + chickens + fishing in Game: new-game state, save keys (`shop_jobs`, `animals`,
    `fishing`) and their loaders all kept side by side; `sell_price` asks fish, then crops,
    then `animals.sell_price`; `item_name` knows animal items and fish.
  - Key remap + fishing: the fishing branch still called `_setup_input()` before the
    settings were read; key remap moved that call after the settings, so only the
    `fish_data` load was kept.
  - Shops + chickens in the map views: the store / smithy props and the coop props are
    both in `MapView` colours and `MapWorld`'s prop match.
  - `tests/test_villagers.gd.uid` (made by the importer) was added with the shops merge.
- Checked on merged main: all 17 tests (`test_animals`, `test_audio`, `test_body`,
  `test_dialogue`, `test_events`, `test_farm`, `test_fishing`, `test_food`, `test_hold`,
  `test_inventory`, `test_maps`, `test_menu`, `test_save`, `test_shops`, `test_title`,
  `test_villagers`, `test_weather`) print `OK (0 failed)`; headless `--quit-after 300` (title,
  `-- --demo`, `--map=town`, `--map=coop`, `--fishing`, `--shop=smithy`, `--pause=controls`,
  `--map=farm@coop --hens-out`) and `res://scenes/main.tscn --quit-after 400` printed no
  errors or warnings. Movie Maker frames: `--demo --fishing` (line, bobber, "!", rod in the
  8th slot, the coop roof by the house), `--demo --map=town` (Kota and Tome on the road).
- Left / next: none of the six was played in a real window (rebinding, E on spots, shop
  screens, the coop, casting), and the new sounds were not heard. Shops don't sell chickens,
  feed or medicine yet (hooks: `Game.add_animal`, `Game.animals.add_feed`); the rod isn't in
  the smithy's upgrade list; fishing has no 2D hookup.

## 2026-10-31 — Key remapping (Esc → Settings → Controls)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the keys moved out of `Game._setup_input` into `data/controls.json` (13 actions in
  menu order with labels and up to 2 default keys each, pad buttons, fixed keys; plus one
  "Tool N: <tool>" action per tool in Game.TOOLS on the number keys, so a new tool gets a
  rebindable key by itself). New `Controls` (scripts/save/controls.gd): key slots per action,
  `bind` (a key another action has is swapped over; refused when that would leave the other
  action with no key, and for Esc, which always pauses and cancels a rebind), `clear` (never
  the last key), `reset`, `apply` (rewrites the InputMap), to / from the settings file by key
  name. `Settings` keeps it as `controls` and writes it under "controls" in
  `user://settings.json`; a broken keys section refuses the whole file like any broken
  setting, a file without one keeps the defaults, a missing action keeps its defaults less
  keys the file gives to others. Game reads the settings first, then applies the keys.
  PauseMenu: "Controls" row on the settings page opens the "controls" page (one row per
  action, Reset to defaults, Back); left / right pick the key slot, Enter listens, the next
  key goes in (`press`), Esc / a click cancels, Delete / Backspace clears; a note line says
  what happened ("I was on Rucksack: swapped", "Q is the only key for ...") or shows the hint.
  PauseScreen draws it wider (250 px) with two key columns (the picked one in the seal red,
  empty slots as a soft "-"), scrolls 14 rows at a time with a thin bar; while listening
  every key goes to the menu. `-- --pause=controls` opens it. Pad buttons stay as in data
  (Start = pause, Back = rucksack), not remappable yet.
- Checked: `test_menu` (new `_controls`, `_controls_menu`: defaults, labels in the pixel
  font, InputMap, bind / swap / refuse / clear, settings round trip, 8 broken files, older
  files, reset, the menu flow) and all the other tests in AGENTS.md print `OK (0 failed)`;
  headless `--quit-after 300` (title, `-- --demo`, `--demo --map=town`,
  `--demo --pause=controls`) and `res://scenes/main.tscn --quit-after 400` printed no errors
  or warnings. Movie Maker frame `--demo --pause=controls`: the wood / paper box with
  "Controls", Move up .. Tool 1: Hoe in view, W / Up in two columns, "W" in red under the
  cursor, "Pause (Esc)" with "-" slots, scroll bar, hint "Enter: new key   Del: clear".
- Left / next: not tried with a real keyboard in a window (rebinding needs real key
  presses); pad remapping; menus still also take the arrow keys (Godot's ui_* actions).

## 2026-10-31 — "Examine" event cause: E facing a spot plays an event
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: trigger tables get a fifth cause, `examine`, with a `spot` condition (the cell faced,
  `[x, y]` or `[x, y, width, height]`; required on examine rows, refused on others; all the
  other conditions still apply). `EventPlayer.examine(spot)` (in group `event_player`) picks
  the map's first matching row and plays it; `FarmActions.on_action` asks it before its own
  interact, so a matching spot wins over doors / bin / futon / pick-up, and an item held
  overhead on the farm is still thrown. Walking into a door ("enter") never examines.
  Examining works under `--demo` (only a key press starts it). New content, our own words:
  - Village (`triggers_town.json`, new): the shrine's offering box (bow, or drop in a coin:
    the choice sets `shrine_coin`, the event pays 5 G with the `coins` sound and clears the
    flag), the two stone lanterns (snow > evening 17:00-24:00 > day), the three empty houses'
    doors (`quiet_house`; walking in still shows the doors' message). The shop door (23, 15)
    is left to the shops branch, and town.json is untouched.
  - Farm: the name plate on the house wall beside the door (text changes once `bin_named` is
    set) and the board on the fence beside the gate.
  - Farmhouse (`triggers_house.json`, new): the paper calendar on the north wall above the
    low table, one text per season (no TV in a satoyama house; the radio on the chest of
    drawers takes its place). The calendar is not drawn yet; the text describes it.
  - Dialogue in `data/dialogue/examine_{town,farm,house}.json`, 14 small event files.
  All examine rows say `"once": false`.
- Checked: `test_events` adds spot validation, spot matching (cell / rectangle / outside /
  other causes / time still counts), every new table's picks, the coin branch (95 G, flag
  cleared), and on the real Game in the tree: holding a turnip throws instead of examining,
  E facing the name plate plays `farm_nameplate`, no second examine while one plays, nothing on
  open ground. `test_audio`, `test_body`, `test_dialogue`, `test_events`, `test_farm`,
  `test_food`, `test_hold`, `test_inventory`, `test_maps`, `test_menu`, `test_save`,
  `test_title`, `test_weather` all print `OK (0 failed)`. Headless `--quit-after 300` (title,
  `--demo`, `--demo --map=town`, `--demo --map=house`) and `res://scenes/main.tscn
  --quit-after 400` (triggers on; also `-- --map=town@shrine`) printed no errors or warnings.
  Movie Maker frame `--demo --map=town@shrine --event=shrine_offering`: the farmer turned to
  face up, the text box shows the offering line with the two choices "Drop in a coin (5 G)"
  and "Just bow".
- Left / next: not pressed in a real window (the frame used `--event`, so the farmer stood at
  the spawn, not in front of the box). The coin can be given with less than 5 G (money stops at
  0). The calendar and the radio have no art. When villagers get their houses, drop the
  `quiet_house` rows for those doors.

## 2026-10-31 — Villagers with daily schedules from data
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: DESIGN "ชาวบ้าน" (a daily plan chosen each morning by the first matching rule,
  catch-up on map entry), our own version:
  - `data/villagers/<id>.json`: four made-up villagers for the village map: Grandma Tome
    (west house; shrine every morning, pond in the afternoon; in on wet days, late in
    winter, sweeps the shrine on Sundays), Hachiro the carpenter (east house; mends the empty
    house south of the road on work days, lunch at home, pond in the evening, fishes on
    Sundays), Sayo (keeps the noren shop: sweeps before 9:00, at the door 9:00-17:00, shrine
    in the evening, Wednesdays off visiting Tome), Kota (a boy: plays along the road, fishes
    in the afternoon, hunts cicadas at the shrine in summer). Rules: season / weekday /
    weather / days / year / flags / not_flags, first match wins, else `default`.
  - `DayPlan` (pure logic): entries {at, map or "away", from, route, loop} with steps to /
    wait / face become timed legs; `where(minute)` gives map, position, facing, moving and
    distance walked. Plans are checked when loaded (first entry 06:00, times in order, a
    from when coming onto a map, a route that arrives before the next entry, a loop that
    takes time). Times are minutes of the game day from 6:00 (`DayPlan.day_minute`, after
    midnight = past 24:00).
  - `Villagers`: loads the files, picks today's plans from `Game.trigger_state`, answers
    `on_map`, `where`, `is_on` (hook for shop hours), `sprite_key`. Positions are a pure
    function of `Game.day_minutes()` (new: the clock with the part-minute), so the catch-up
    comes for free and nothing needs saving.
  - Views: `VillagerSprites` (3D billboards with shadows) / `VillagerView` (2D sprites) added
    to every map world; one line each in main_3d / main_2d.
  - Art: `villager:<id>:<front|back>:<idle|walk>:<frame>`, 16 x 24 like the farmer, a hair
    style (bun, short, headband, long, straw hat) over a shared face and an outfit (kimono to
    the ankles with sandals, happi with trousers, shirt and shorts), colours from the look.
  - Numbers (ours): walk 1.5 cells per game minute (3 cells / s, below the farmer's 3.75),
    Kota 2.0; a walk frame per half cell.
  - `--time=H:MM` debug flag (after `--demo`) sets the clock for screenshots.
- Checked: `test_villagers: OK (0 failed)` (plan timing and loops, carry-on, refused plans,
  rule order, files, no walk crosses a solid cell, today's village, sprites, both views at
  14:20 placing everyone where the plan says); the thirteen other tests all print
  OK (0 failed); headless `--quit-after 300` (title, `--demo`, `--demo --map=town`,
  `--demo --map=town --time=14:30`), `res://scenes/main_2d.tscn -- --demo --map=town` and
  `res://scenes/main.tscn --quit-after 400` printed no errors or warnings. Movie Maker frames:
  `--demo --map=town` (10:00: Kota in his straw hat and Tome in her purple kimono near the
  start spawn), `--demo --map=town@shrine --time=12:10` (Hachiro walking home along the road,
  hidden behind the south house roof where he passes it).
- Left / next: villagers don't block the farmer yet (so no bump delay); `away` stands for
  their houses until those maps exist (the village doors still only give a message); indoors
  the clock stops, so a villager on an indoor map would stand still; talking, gifts,
  affection and shop hours are next. Not seen in a real window yet.

## 2026-10-31 — Shops with prices from data, the smithy's tool upgrades
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: first part of milestone 8 (DESIGN "ร้านและประตู": doors with opening rules).
  - `data/shops.json`: Yorozu Store (general, 9:00-17:00, closed Sun; seeds by season, food
    all year, sakura mochi in spring, amazake in winter; buys crops at 80% of their sell
    price) and Kurogane Smithy (10:00-16:00, closed Wed; upgrades hoe / can / sickle / hammer /
    axe). A stock entry without a price uses the item's own (crops.json `seed_price`,
    foods.json `price`); milk is 100 G here (90 G at the stand) to show a shop price.
  - `Shop` (`scripts/shops/shop.gd`, pure logic): hours / days off / closed text, stock per
    season, buy (in stock, money, rucksack room, all or nothing), sell (only what it buys,
    only what is carried, percent rounded down), upgrade offer / hand-in (one job at a time,
    the tool must be in a tool slot, optional `items` materials for ore later) / give back
    (old slot, another tool slot, else the chest). Returns `{ok, money, note}`, touches no Game.
  - Game: `shop()`, `open_shop(id, force)` (closed message or `shop_requested`),
    `shop_buy` / `shop_sell` / `shop_upgrade` / `shop_collect` (raises the level with
    `raise_tool_level()` and lifts the tool's experience to that level's start),
    `day_number()` / `date_of()`, `shop_jobs` saved (older saves load with none, broken jobs
    refused). A door with `shop` stays shut outside its hours and says so.
  - Maps: `data/maps/store.json` (shelves, counter, rice sacks) and `smithy.json` (forge,
    anvil, tool rack, counter, quench tub), both indoor with `counter` and `keeper` spawns;
    the town's noren house (door 23,15) and the north-east house (door 27,6, now with a
    noren) lead in. New 3D props in `map_world.gd`, flat colours in `map_view.gd`. A prop
    with `use: "shop"` is a counter (FarmActions.interact → `Game.open_shop`).
  - Screen: `ShopMenu` (tabs buy / sell / tools from what the shop does, rows, a count that
    wraps within money / room / what is carried, choose → Game) and `ShopScreen` (wood box,
    shop name and money, tabs, 7 rows with icons that scroll, info / note / keys / hours
    lines; keys and mouse, pauses Game). In both views. New flag `-- --demo --shop=<id>`.
  - Hook for villagers: `keeper` in the data, the `keeper` spawn behind each counter, and
    `Game.open_shop()` as the one entry a shopkeeper's talk can call.
- Balance (ours): upgrades 1000 / 2500 / 5000 / 10000 G for levels 2-5, 2 / 3 / 3 / 4 days,
  so level 2 is a week or two of spring turnips and the top level a late-game goal; buying
  crops back at 80% keeps the bin (full price, paid at 18:00) the better deal and the shop
  the quick cash.
- Checked: new `test_shops: OK (0 failed)` (data against maps / crops / foods / tools, hours,
  stock and prices, buy / sell edge cases, upgrade hand-in / materials / give back, doors,
  Game buy / sell / upgrade over two nights / collect, ShopMenu, save round trip and 7 bad
  job lists, the real counter opening the screen and Esc closing it; a planted failing check
  was reported, then removed). `test_farm`, `test_save`, `test_title`, `test_weather`,
  `test_dialogue`, `test_menu`, `test_body`, `test_events`, `test_maps`, `test_inventory`,
  `test_food`, `test_hold`, `test_audio` all `OK (0 failed)`. Headless `--quit-after 300`
  (title, `--demo`, `--demo --map=town`, `town@store`, `store`, `smithy`, `--shop=general`,
  `--shop=smithy`), `res://scenes/main.tscn --quit-after 400` and the 2D scene with
  `--shop=general` printed no errors or warnings. Movie Maker frames: `--demo --shop=general`
  (the buy screen: 7 of 9 rows, prices, "In your rucksack: 2", hours line), `--shop=smithy`
  (tools tab, Lv 1 > 2 at 1000 G), `--map=store`, `--map=smithy`, `--map=town@smithy`.
- Left / next: not played in a real window (keys, mouse, scrolling past row 7). No shopkeeper
  stands at the counter yet (villagers session); the seed stand on the farm still sells too.
  House extensions and the rucksack upgrade (`Inventory.grow`) are not for sale yet; ore for
  upgrades waits for mining.

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

## 2026-10-31 — Fishing: the rod, bites, fish per place / season / hour / weather
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: DESIGN "การตกปลา" as our own rules and numbers.
  - `Fishing` (scripts/fishing/fishing.gd, pure): states idle / wait / bite. A cast waits at
    least `min_wait_seconds` (2.5 s), then every `check_seconds` (1 s) a fish bites with the
    chance for the hour (dawn 0.4, noon 0.12, dusk / night ~0.3) times the weather (rain 1.3,
    storm 1.5, snow 0.9, blizzard 0.7). A bite lasts `bite_seconds` (0.9 s); too late = it gets
    away. Pity rule: after `sure_after` (7) casts in a row with no fish the next check always
    bites (ours; DESIGN notes 11 -> 12th). Reeling in at once doesn't count as a dry cast, so
    quick recasts aren't a shortcut. `candidates()` = fish id -> weight for place / season /
    hour (wraps past midnight) / weather factor / once-only; `pick()` by weight.
  - `data/fish.json`: ten Japanese freshwater fish (crucian carp, carp, pond loach, pond smelt,
    sweetfish, masu trout, char, catfish, eel, and our once-only Moonlit koi on clear fall
    nights after 22:00 in the village). Places are map ids: `farm` (the farm pond) and `town`
    (the village pond, fed by a mountain stream so stream fish come down into it). Crucian
    carp bites everywhere always, so no spot is ever empty. Prices 25-300 G (2000 for the koi),
    in line with crops (turnip 60 G).
  - Game: `TOOLS` + "rod"; `data/inventory.json` 8 tool slots, the rod last in the start
    tools; `data/tools.json` `rod` {stamina 2, reach 2} (taps only, no levels yet).
    `cast_line` (first water cell up to the reach; a solid cell blocks), `reel_in` (a catch goes
    up overhead into the hand slot as `fish:<id>`), `fishing_event` signal ("bite" / "escaped",
    stepped in `_process` while nothing is paused), `fish_caught`. A map change and the night
    take the line out. `sell_price` / `item_name` know fish, so the bin ships a thrown fish
    ("The ... swam away" when thrown into the pond).
  - FarmActions: the rod casts on any map (the other tools stay farm-only); with the line out
    either button reels in; sounds `tool_rod`, `fish_bite`, `fish_catch`, `fish_escape` (new
    recipes in data/sfx.json). The Player stands still while the line is out.
  - Save: `fishing` {caught, dry_casts}; saves from before fishing get the rod (free tool slot,
    else the chest) and nothing caught.
  - Art / views: poses `fish_wait` (rod up) and `fish_bite` (leaning in, tip jerking down;
    `PlaceholderArt.rod_tip`), `fish_fx:bobber`, `fish_fx:alert` ("!" on a paper bubble),
    `ui:fish:<id>` icons from each fish's look (deep / long / slim / trout / eel / catfish),
    `ui:tool:rod`. 3D: bobber rocking on its cell (dips and shakes on a bite), a line from the
    rod tip to it, the "!" over the head, the target brackets hidden. 2D: rod, line, bobber and
    "!" in Player._draw. HUD tool bar widened for 8 slots (hand box moved right).
  - Debug flag `--fishing` (or `--fishing=wait`): at the farm pond, line out, a fish biting.
- Checked: all 14 tests print `OK (0 failed)` (test_audio, test_body, test_dialogue,
  test_events, test_farm, test_fishing, test_food, test_hold, test_inventory, test_maps,
  test_menu, test_save, test_title, test_weather); test_save's bad tool slot is now 8 and
  test_inventory's tool list has the rod. Headless `--quit-after 300` (title, `--demo`,
  `--demo --map=town`, `--demo --fishing`, `--demo --fishing=wait`), `res://scenes/main.tscn
  --quit-after 400` and `res://scenes/main_2d.tscn --quit-after 200 -- --demo --fishing`
  printed no errors or warnings. Movie Maker frames `--demo --fishing` (farmer by the pond,
  rod bent, line to the dunked red bobber, "!" over the head, rod selected in the 8-slot bar)
  and `--demo --fishing=wait` (rod up, bobber afloat).
- Left / next: not played in a real window (timing of the bite window by hand, the sounds
  unheard). No river yet (the village pond stands in for stream fish), no rod levels, fish
  aren't food or gifts. The 2D view still doesn't connect the Player's actions (from before).

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
