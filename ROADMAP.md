# Harvest Son — roadmap

Goal: a cozy farming life-sim with Back-to-Nature-style camera and feel, made entirely of our
own code, art, story and numbers, shipped as a Windows .exe from Godot 4.7.
Rules per system: docs/DESIGN.md. What was done and how it was checked: WORKLOG.md.

## Mood and tone
The game should feel Japanese: a quiet countryside village in the spirit of rural Japan
(satoyama), cozy and nostalgic rather than generic western farm. Let it guide every look
and feel choice from here on, always with our own designs:
- Buildings: wooden houses with tiled or thatched roofs, engawa porches, sliding doors,
  noren curtains on shops, stone lanterns, a small shrine with a torii.
- Nature: rice paddies, bamboo, cherry blossoms in spring, cicadas and fireflies in summer,
  red maples in fall, quiet snow in winter.
- Festivals and seasons follow Japanese customs (hanami, summer matsuri with lanterns and
  fireworks, moon viewing, New Year).
- Food, crops and items lean Japanese (rice, daikon, eggplant, green tea, mochi, onigiri).
- Music and sound: soft, acoustic, with Japanese instruments (shakuhachi, koto, shamisen)
  and nature sounds.
- UI: warm paper and wood textures; a pixel font that can show Japanese text later.
The farm pieces are done in this style: the house (kawara roof, plaster and timber, engawa,
shoji), a low bamboo lattice fence with rope ties, the seed stand as a roadside stall with
a board roof and an indigo noren, and a lidded cedar shipping bin with a straw rope.

## Next up
The user chose to refine the placeholders first (real art later). Farmer, crops, field
objects, ground tiles, buildings, weather particles and the paper / wood HUD with our pixel
font are done. Charging tools are done, and tools level up with use (tool experience,
thresholds in data/tools.json; `Game.raise_tool_level()` is the hook for the blacksmith in
milestone 8); a charging tool at level 5 swings for 60% of the stamina (tools.json `master`). Fatigue, tired poses, oversleeping and collapse are done (data/body.json); a
collapse wakes the farmer in the village clinic (data/maps/clinic.json, Dr. Yae, the first
visit free, then a fee; the clinic sells a herb tonic).
Holding and throwing is done: a harvest goes up overhead, E throws it (into the bin = shipped,
into the pond = gone), Space sets it down, items lie on the field and are saved
(data/hold.json).
Weather is done for now (snow lies in winter on the farm and the outdoor maps, lightning flashes in storms; flashes can be
turned off in Esc → Settings or with `-- --no-flashes`), the text box is done (data/dialogue,
DialogueRunner, TextBox) and the pause menu (Esc: resume, save, settings, back to title;
settings in `data/settings.json` / `user://settings.json`, so a volume setting is one data
entry).
Eating / drinking is done: food and drink in `data/foods.json` (stamina +, fatigue −, specials
for max stamina and half swing fatigue for a day), eaten from the 7th tool slot (Q = next
food) and sold at the seed stand while that slot is in hand. Raw crops, eggs, milk and fish
are food too (`raw` in foods.json; F in the rucksack, or the food slot with one overhead); the
farmer stands through a short eat / drink pose afterwards (foods.json `pose`, both views), and
cooking is in: the kitchen corner's stove opens a cooking screen, recipes in
`data/recipes.json` take ingredients from the rucksack and the chest, the dishes are foods;
four recipes are known at the start, five are taught by Tome, Sayo, Hachiro, Kota and the
radio (flags `recipe_<id>`; README → Cooking). Daikon (fall) and rice (summer into fall; a
watered paddy stays wet) are crops, their seeds at the store and the stand; four more recipes
come as recipe cards in the bin with the first daikon / rice shipped; dishes ship at their
`sell` in foods.json (held out at the bin or thrown in), are gifts (each villager loves two
dishes and dislikes some) and the store buys them at 80%. Cooking tools are in (six tools at
the store once the kitchen is built; taught and card recipes need them, the start four don't).
Event scripts and trigger tables per map are done (data/events, EventRunner /
EventTriggers / EventPlayer; README → Events); EventPlayer loads a map's table on
`Game.map_entered(map_id)`, so a new map's events are one `data/events/triggers_<map id>.json`.
The "examine" cause is done (E facing a spot in a trigger table: shrine, lanterns, empty
houses, name plate, gate board, calendar, radio). Later for events: villagers as actors.
Maps are in (data/maps: farm, farmhouse inside with the futon, a first village with a
shrine; doors, a fade, clock stopped indoors). The villagers' homes are in: Tome's and Kota's
houses and Sayo's rooms behind the store (irori, tokonoma, altar, screens), doors open by their
`hours` and shut at night with a message.
Sound effects, ambient loops and music are in (milestone 10), with Music / Sounds / Ambient
volume sliders in Esc → Settings. The four festivals have their own scores, the store and the smithy theirs (`maps` rules),
the heart events and the opening theirs (`events` rules). Later for audio: more tracks are
new scores and rules in `data/music.json`; the music has not been heard by a person yet. The
river map has its own running-water loop and the ponds a quieter lapping by the water
(`maps` / `near` ambient rules in data/sfx.json); not heard by a person yet either.
The rucksack and the storage chest are done (I opens the rucksack, the chest stands right of
the house; slot counts in data/inventory.json, so a shop's rucksack upgrade is one number via
`Inventory.grow("bag", n)`). The item held overhead is the rucksack's hand slot. Keys can be
rebound in Esc → Settings → Controls (defaults in data/controls.json, saved in the settings
file); pad buttons, triggers and right-stick directions too (a third column, saved under
`pad`). Esc → Settings also has display mode, window size (sizes too big for the screen left
out), v-sync, an FPS limit, UI size (100-150%, each piece as far as it fits), text speed,
always run, show HUD and reset to defaults (README → Settings).
Villagers with daily schedules are in (data/villagers: Tome, Hachiro, Sayo, Kota; rule
list → day plan, positions follow the clock, so entering the village shows everyone where
their plan puts them; README → Villagers). Talking, gifts and affection are in: E facing a
villager turns them round and picks a line from `data/dialogue/talk_<id>.json` (season,
weather, time, heart band, flags, talked already); an item overhead is a gift (likes in the
villager file, one a day); a daily talk adds a little; `Game.affection` is saved (version 3)
with an `affection` event step and `talk` / `hearts` trigger keys. Sayo keeps the store and
Hachiro the smithy: talking to them at the counter opens the shop, which sells only while
they are in. Villagers block the farmer and wait when they bump into the farmer (delay, at most 30
minutes). They are at home (house maps; Hachiro in the smithy) in the early morning, at noon,
in the evening and on wet days, `away` in bed after their door shuts; Sayo has tea at Tome's
on Sunday afternoons. On a fair Sunday Hachiro fishes the river (9:30-15:00) and Kota joins
him in the afternoon (a `fish` day plan step: the villager's rod pose in both views; river talk
lines picked by the `map` condition). Villager portraits are in: the text box frames a villager's own face
(`portrait:<id>:<mood>`, neutral / happy / sad / surprised / angry; a `mood` on dialogue lines and
event say steps; narration and other speakers have no frame). Villagers whistle now and then
as they walk their plan outdoors on a fair day: a short tune of their own (data/whistles.json),
softer the farther off, with a note puff over them in both views.
Relationships are in (milestone 9): the heart band shows as a coloured heart on the text
box's name tag, each villager has a birthday (on the farmhouse calendar; gifts x5, a birthday
line), villagers left alone may lose a point at night, and each has a heart event at band 3
(data/events/heart_<id>.json) and a second one at band 5 (heart_<id>_5.json); on a birthday the
villager follows a `birthday` day plan, the weather is fair and the HUD tag names it. Gift
lists include mine finds. The band 5 scenes' story flags show in the world, in both views
(map props gated by `flag` / `flag_value`, StoryProps / StoryView): Hachiro's iron bell by the
farmhouse door (rings when used), the store's new sign on its roof (old name or Sayo's own red
board) and Tome's jar of pickled plums in the farmhouse. Each villager has a band 6 scene too
(heart_<id>_6.json, after the band 5 one; Kota's carp streamer flies by the farmhouse) and
band 6 talk lines after it. The villager acts in every heart scene: they stay where the talk
found them (or walk up to the farmer when played elsewhere), face the farmer through their
lines and go back to their day plan (actor steps `"at": "plan"`, `"to": "farmer" / "plan"`,
`"face": "farmer"`).
Shops are in (data/shops.json): the Yorozu Store and the Kurogane Smithy in the village, with
opening hours and days off, a buy / sell screen and tool upgrades over days (saved). A
shopkeeper only has to stand at the map's `keeper` spawn and call `Game.open_shop(id)`.
The store also sells chickens (only with room in the coop), feed, Animal Medicine and two
bigger rucksacks, and takes orders for house extensions (bigger chest, kitchen corner, second
room) that Hachiro builds over days; the smithy improves the rod (bite factor per level in
data/fish.json). The store also sells cows, sheep, calves, lambs (only with room in the barn)
and fodder. While an extension is under way Hachiro builds on the farm (his `building` day
plan from the morning after the order: hammering at the farmhouse wall by a stack of lumber,
a knock per blow, his own lines; the smithy counter has a note instead of him). The lumber
is solid (farm map props with `solid` block in FarmGrid), and a day he doesn't build (a storm)
doesn't count: the job is due a day later and the note and the build tab say so; that
morning the farmer hears it on stepping out of the house (shops.json builds `off_day`).
Chickens are in (milestone 7): the thatched coop right of the stand is a map (feed box,
nests, incubator, hen hatch); rules in `Animals`, numbers in `data/animals.json`, saved
(save version 2). The shop sells chickens through `Game.add_animal("chicken")`, feed through
`Game.animals.add_feed(n)` and Animal Medicine as the rucksack item `medicine` (all sold at the store).
Cows, sheep and the dog are in too: the tiled barn between the coop and the pond is a map
(stalls, fodder trough, hay, tools on the wall, a gate out to the pasture), milk daily and
wool every 3 nights graded by happiness, brushing, calves / lambs (save version 4). The barn
starts empty; the shop sells cows / sheep through `Game.add_animal("cow" | "sheep", young)`
and fodder through `Game.animals.add_fodder(n)`. The dog Goro follows the farmer once fond.
Fishing is in (milestone 9): the rod is the 8th tool slot, a cast waits for a bite ("!" and a
plip), a press in time lands a fish overhead (ship it in the bin or keep it in the rucksack);
fish, odds, bite timing and the pity rule are in `data/fish.json`. The river south of the
village (map `river`) has its own fish table; fish are food (foods.json `fish:*`) and on the
villagers' gift lists. The 2D view's action hookup is done (`FarmActions.connect_view`, checked
by tests/test_view2d.gd), and it has the 3D view's weather and festival lights too (rain /
snow particles with splashes, the weather tint, lightning flashes, the lanterns' glow and the
fireworks), and its festival decorations are pixel pictures of the 3D props
(PlaceholderArt `festival:` keys), each light hung where its lamp is drawn.
Talking, gifts and affection are in (a `talk` row with `who` in a trigger table plays an
event when the farmer talks to a villager); the keepers are `sayo` (store) and `hachiro`
(smithy). The opening event and the first shop visits are done (data/events/opening.json,
store_intro, smithy_intro; villagers act in events with the `actor` step).
Mining is in (milestone 9): the mine entrance at the village road's east end, floors laid out
fresh from a seed on every entry (data/mine.json; README → Mine), the hammer on rocks, the hoe
on soft spots, a hole down under one of them, ores / stones / gems into the rucksack, only the
deepest floor saved. Mine extras are in too: the Kurogane Smithy asks for ores in its tool
upgrades (`items` on the upgrade levels in data/shops.json), the smithy buys stones and ores
and the store buys gems (`buys` by kind), each floor is darker than the one above with a
lantern circle round the farmer (both views), and in winter floors 1-9 are frozen (frost,
ice blocks hiding frost stone, a cold light; `winter` in data/mine.json). The ice, frost,
frost stone and lantern have better pixel placeholders: a dithered, flickering warm lantern pool
in both views, the lantern in the farmer's hand, ice glints in a frozen floor's dark.
Festivals are in (milestone 9): `data/festivals.json` (date, hours, map, place, event, shops
shut, decorations, fireworks), the HUD tag under the clock, the calendar notes, fair weather
on the day, Kota and Tome out all day. Each festival has a contest at a judges' table (best
spring crop, biggest fish, best egg / milk / wool, brightest mine stone; villager rivals rolled
per year, prizes by place, a result event), its own music (`festivals` in the music rules) and
the shipping payout waits for the next day; Blossom Day has a dango stall and Lantern Night a
night-eats stall and a wind chime stall that sell, and a placing gives a ribbon to keep, shown
on a board in the farmhouse (README → Festivals); at the results the rivals walk up to the
table with their entries overhead and go back to their plans after. Year's Turn also has a contest that is
played, the mochi pounding (a festival `game`: swing on the beat while Tome or Kota turns the dough,
ranked against rolled rivals, prizes and a ribbon). Moon Night has a second played contest, the
Moon Pond Race (a festival `game` of kind fishing: 60 seconds at the village pond with the real
rod and bites, one point a fish, against four rolled rivals; prizes, a ribbon, a result event, a
race in progress is saved; a small box with the time and the creel in both views). Later for
festivals: a person should play both games to tune their numbers. Done: the whole village
gathers (Hachiro and Sayo have festival day plans too, all four have a line for each festival,
Sayo leaves a note on the store counter on Blossom Day), stalls at Moon Night and Year's Turn (a food
stall and a keepsake stall each), keepsakes as gifts (each villager loves one), the villagers'
own lines for keepsakes and dishes, and a loved keepsake shown in its owner's home.
The balance pass is done (milestone 8): our own crop, product, animal and extension prices,
`python -I tools/balance.py` prints income per season for a steady year-1 plan (WORKLOG has
the before / after table); it also keeps the smithy's ores back from the bin (an upgrade
waits while they are short), counts contest prizes from the odds against the rivals, and prints
each recipe's gain over its raw ingredients, its kitchen tools and the cookings that pay them
back (the plan buys the tools as a one-off cost in the season it first needs them). The hammer now levels like the sickle (it reached 4 after one spring of mining at the axe's numbers; WORKLOG 2026-11-03).
The ending is in (milestone 9): on the first morning of year 3 Tome brings the village record
(stars per category, a rank and a title from data/ending.json; README → Ending), then the
villager liked most says a word and the game goes on. Every other New Year Tome brings a
shorter yearly page, and every page shows the first day's numbers and field beside today's
and the gain since the last page. The record is drawn as a paper scroll that unrolls on open
(rollers, washi, ink-stamp stars, a red seal by the title).
The year playtest is done: `tools/play_year.gd` plays two years through the real rules and
prints a report per season and the village record (WORKLOG 2026-11-01); gifts were made slower
and the ending's mine steps lower from it. Since 2026-11-03 it walks the new areas (Sakurazaka to
the mine, Minamino to the river), picks forage on the way and on a Kaminoda / hill round, fishes
the river when a bite pays more there, and carries food down the mine; the rod's cast now costs
4 stamina and the hammer levels slower (WORKLOG). Later for it: fish still out-earn crops in
year 1 (spare stamina). The deep floors are reachable now: floors 5, 10 and 15 are rope lift
landings, and once reached a trip can start there from the cave mouth (README → Mine); the bot
doesn't ride the lift yet (tools/play_year.gd: pick the deepest landing at the cave mouth).
Bigger world (the user found the maps small, 2026-11-01): widening the farm and village made
the walks long and dull, so they are back to their old sizes; the world grows by areas instead.
Done: Kaminoda, the hamlet up the village's north lane (paddies, drying racks, a well, jizo;
Genzo and Haru and their houses) with the bamboo hill above it, and countryside props. Sakurazaka
on the way to the mine (cherry road, creek, teahouse; Fumi and Ichiro). Minamino on the
way to the river (gardens, persimmon orchard, a water shrine; Shige, Nana and Kiku). Seven new
villagers in all, without hearts at first; Fumi and Ichiro have hearts now (birthdays spring 26 /
fall 9, close lines, heart events at bands 3 and 5, a word at the ending); they come to all four festivals too (a spot each, a line each). The Hanami teahouse is a shop (Fumi's: tea, whipped matcha
and a sweet of the season sold nowhere else, while she is behind her counter). Forage is in
(data/forage.json: fifteen spots on the bamboo hill, what grows changes by the season, a picked
spot grows back overnight; README → Forage). The village record has a Neighbours
row (the villagers without hearts known to band 1; six of them since Fumi and Ichiro got hearts).
Later for hearts: band 6 scenes for Fumi and Ichiro; hearts for Genzo, Haru, Shige, Nana or Kiku the same way (README → Villagers says what a friend needs). Shige, Genzo, Haru, Ichiro and Nana are
contest rivals (one in every contest and game). Forage spots are in the three outer parts too
(their own wild things: water dropwort, sansho, mulberries, ginkgo nuts and more). Wild things
cook: six recipes of wild greens, mushrooms, bamboo shoots, chestnuts and matsutake (Haru, Genzo
and Kiku teach three once they know the farmer; the first bamboo shoot, chestnuts or matsutake
shipped brings a card). Tome, Hachiro, Sayo and Kota talk about forage too (a line per season,
one weekday each, from band 2).
After that: milestone 10, building the .exe once the export templates are installed (README → Export).
Later for the HUD: kana / kanji glyphs in `data/font_pixel.json` once there is Japanese text.
Open from the user: the farmer sprite still looks a bit odd to them (no details given, set
aside on 2026-10-31); ask what bothers them when coming back to the farmer.

## Milestones

1. **Core loop** — time → farm → ship → sleep
   - [x] Clock (0.5 s per minute, day at 6:00, 4 x 30 days), day/night light
   - [x] Weather rolled a day ahead, rain waters the field, storm damage
   - [x] Farm grid, hoe / can / sickle / hammer / axe, seed bag 3 x 3, growth, regrowth, withering, weeds
   - [x] Shipping bin (paid 18:00 or on sleep), seed stand, sleep / pass out, stamina
   - [x] HUD, 2D view, 3D view with the HM field camera (yaw 45°, pitch 26.6°, FOV 13.7°)
   - [x] Clock pauses in menus (`Game.pause()` / `unpause()`)
   - [x] Clock pauses indoors (`Game.ticking()` is false on a map with `indoor: true`)
   - [x] A new area off the village: the bamboo hill (`hill`, bamboo clumps, a lookout shrine, examine events)
   - [x] Countryside props: well, jizo, persimmon, cherry, rice drying rack, woodpile, garden, board fence
   - [x] The village's north part: Kaminoda (to the hill), with Genzo and Haru
   - [x] The village's east part: Sakurazaka (to the mine), with Fumi and Ichiro
   - [x] The village's south part: Minamino (to the river), with Shige, Nana and Kiku
   - [x] The Hanami teahouse sells tea, matcha and seasonal sweets (shop `teahouse`, Fumi)
   - [x] Forage on the bamboo hill: fixed spots, seasonal wild things, back the next morning
   - [x] The outer parts' villagers come to every festival, with a line for each
   - [x] The village record counts the neighbours known (a Neighbours row, ranks moved up)
   - [x] The outer parts' villagers as contest rivals (one in every contest and game, a winner's line each)
   - [x] Forage in Kaminoda, Sakurazaka and Minamino (28 spots, nine new wild things)
   - [x] Wild things in recipes (six dishes: three lessons from Haru, Genzo and Kiku, three bin cards)
   - [x] Forage talk: a line per season from Tome, Hachiro, Sayo and Kota (one weekday each, band 2..5)
2. **Look and feel**
   - [x] Farmer placeholder frames (3/4 front / back x idle / walk / run) + animation timing
   - [ ] Farmer real art (same keys: `player:<front|back>:<pose>:<frame>`)
   - [x] Field object and crop placeholders (per crop look in `data/crops.json`, 4 growth looks + ripe)
   - [ ] Field object and crop real art (same keys: `crop:<id>:<growth>:<ripe|growing>`)
   - [x] Ground tiles instead of flat colours (grass, soil dry / wet / tilled, paths, water)
   - [x] House, bin, stand, fence as models or textured boxes
   - [x] Rain / snow particles, weather tint
   - [x] Snow lying on the ground and roofs (cover rule in Game + data), lightning flashes
   - [x] Snow on the ground in the 2D view too (same pattern as 3D, under the sprites)
   - [x] Snow on the outdoor maps too (village, river path, mine entrance) and their roofs,
     in both views; rooms and the mine floors stay bare (`-- --snow=N` for screenshots)
   - [x] The 2D view plays the same game: its Player's actions go through FarmActions
     (`connect_view`), thrown items fly in an arc
   - [x] The 2D view's weather and festival lights: rain / snow (WeatherView), lightning flashes
     (respecting the flashes setting), the lanterns' glow and fireworks (FestivalGlow)
   - [x] The 2D view's festival decorations as pixel pictures (`festival:` art keys, all four festivals)
   - [x] Pixel font for the HUD, clock box, a proper item / tool display (Japanese glyphs later)
3. **Tools and the body**
   - [x] Charging tools (hold to cover more cells, per tool level; data/tools.json)
   - [x] Tool levels and upgrades (experience from use; shop upgrades with milestone 8)
   - [x] Fatigue, tired animations, oversleeping, collapse (data/body.json)
   - [x] The village clinic: Dr. Yae (a villager without hearts), a collapse wakes there, fee, herb tonic
   - [x] Eating / drinking, food items (data/foods.json, food slot, sold at the stand)
   - [x] Raw farm goods as food, cooking at the kitchen corner (data/recipes.json, recipe lessons)
   - [x] Daikon and rice crops, their recipes (recipe cards), dishes shipped at a sell price
   - [x] Dishes as gifts (villager likes), the store buying dishes
   - [x] Cooking tools (data/recipes.json tools, sold at the Yorozu Store after the kitchen, saved)
   - [x] Holding and throwing items (shipping by throwing into the bin; data/hold.json)
4. **Save / load and menus**
   - [x] Save game (Game + FarmGrid to a versioned JSON file), load; F5 / F9, saves on sleep
   - [x] Title screen (new game / continue / quit), Continue only for a save that loads
   - [x] Pause menu (resume / save / settings / back to title), settings file (flashes, window)
   - [x] Rucksack / storage menus (Inventory, InventoryMenu / InventoryScreen, chest by the house)
   - [x] Key remapping (Esc → Settings → Controls; data/controls.json, keys in user://settings.json)
5. **Town and villagers**
   - [x] Map switching (farm ↔ town ↔ houses), doors, indoor clock pause (data/maps, MapManager, fade)
   - [x] Villagers with daily schedules from data (rule list → day plan), catch-up on map entry
   - [x] Talking, gifts, affection, shopkeepers at their counters (data/dialogue/talk_<id>.json, Affection)
   - [x] Villagers' homes: Tome's / Kota's houses, Sayo's rooms (data/maps, HomeProps), door hours, home schedules
   - [x] Villagers at the river: Hachiro and Kota fish it on fair Sundays (`fish` step and rod pose, `map` talk condition, river lines, `--day=N`)
6. **Events and dialogue**
   - [x] Text box (typewriter, portraits, choices, flags); our own, data/dialogue
   - [x] Villager portraits by mood (`portrait:<id>:<mood>`, `mood` on lines and say steps)
   - [x] Event scripts + trigger tables per map (data/events; three small farm events)
   - [x] "Examine" trigger cause: E facing a spot plays an event (village, farm, farmhouse)
   - [x] Opening event (Tome on the farm), first visits to the shops (Sayo, Hachiro); `actor` / `place` event steps
7. **Animals**
   - [x] Chickens: coop map, feed box, happiness, egg grades, sickness / medicine, going out, incubator (data/animals.json)
   - [x] Cows / sheep (barn map, fodder, stalls, milk / wool by happiness, brushing, grazing, calves / lambs), the farm dog (data/animals.json)
8. **Shops and economy**
   - [x] Shops with prices from data, tool upgrades (data/shops.json; store and smithy in the village)
   - [x] House extensions, rucksack upgrade for sale (store: chickens, feed, medicine; smithy: the rod)
   - [x] Hachiro seen at work while building (day plan on the house_work flag, work pose and knock, lumber prop, talk lines, smithy note)
   - [x] Building fixes: solid story props on the farm (the lumber, the streamer pole; `solid` read by FarmGrid.prop_blocks), a day Hachiro doesn't build (storm) pushes the due day (note and build tab say so)
   - [x] Balance pass (income per season, seed, animal and extension costs; `tools/balance.py`); the store sells cows, sheep, calves, lambs and fodder
   - [x] Leftovers: a level 5 perk for the charging tools (lighter swings), the morning word when a storm keeps Hachiro off the job, kitchen tool prices in `tools/balance.py`
9. **Festivals, mining / fishing, relationships, endings**
   - [x] Fishing: rod (8th tool slot), cast at the farm / village pond, bite cue, fish per place / season / hour / weather (data/fish.json)
   - [x] The river: a map off the village's south lane, its own fish (dace, chub, sculpin, fall salmon, the once-only river elder), river fish on gift lists
   - [x] Mining: entrance east of the village, floors laid out fresh from a seed, rocks / soft spots / hole down, ores and gems per depth and season (data/mine.json)
   - [x] Mine extras: ores for the smithy's upgrades, shops buying stones / ores / gems, light by depth with a lantern (both views), frozen floors in winter
   - [x] Mine art: ice blocks, frost, frost stone, a soft flickering lantern pool (both views), the farmer's lantern in hand
   - [x] Mine landings: rope lifts on floors 5 / 10 / 15, a trip can start at one reached (choice at the cave mouth), saved (version 6)
   - [x] Festivals: one per season in data/festivals.json (Blossom Day, Lantern Night with fireworks, Moon Night, Year's Turn), HUD tag, shops shut, decorations in both views, an event once a year, villagers gather
   - [x] Festival contests with prizes and result events, festival music, payout held on the day, Blossom Day's stall
   - [x] Lantern Night's stalls (night eats, wind chimes and keepsakes), contest ribbons and the farmhouse ribbon board
   - [x] A played contest: the mochi pounding at Year's Turn (rhythm game with a partner, rolled rivals, prizes, ribbon)
   - [x] A second played contest: the Moon Pond Race at Moon Night (60 s of real fishing at the village pond, rolled rivals, prizes, ribbon, save)
   - [x] Relationships: hearts on the text box's name tag, birthdays (calendar, gifts x5, birthday lines), the nightly loss for villagers left alone, a heart event per villager at band 3
   - [x] Relationships 2: a second heart event per villager at band 5, birthday day plans, fair weather and the HUD tag on a birthday, mine finds in the gift lists
   - [x] Heart flags in the world: the door bell (hachiro_bell), the store's sign (sayo_sign old / new), Tome's plum jar (tome_grandma), as flag-gated map props in both views
   - [x] Gift lines of their own: villagers answer keepsakes and dishes in their own words (`gift_items` in the talk files, fallback to gift_<reaction>); a loved keepsake, once given, stands in their home (kept_<villager>_<keepsake>, both views)
   - [x] Band 6 heart scenes: Tome stays in the village, Kota's carp streamer (a farm prop), Sayo's new ledger, Hachiro's sickle; band 6 talk lines
   - [x] Hearts for Fumi and Ichiro (Sakurazaka): birthdays with day plans, close lines, heart events at bands 3 and 5, a part in the ending; the record's Friendships / Neighbours steps rescaled
   - [x] Actors in the heart scenes: the villager stands facing the farmer through their lines in both views, then goes back to their day plan
   - [x] Ending: the village record on the first morning of year 3 (data/ending.json: ten categories graded in stars, five ranks), Tome's verdict, the closest villager's word; the game goes on
   - [x] Ending steps re-set for 11 crops / 13 recipes; balance re-run with smithy ores, contest prizes, cooking, daikon and rice
   - [x] Yearly pages: a shorter village record every New Year (year 2, year 4 on), the first day kept in the save and shown beside today's numbers, the gain since the last page
   - [x] The record as a paper scroll: wooden rollers, washi, unrolls on open, ink-stamp stars, a red seal by the title, an arrow from the first day to now
10. **Audio and release**
    - [x] Sound effects and ambient loops (synthesized from data/sfx.json, SFX / Ambient busses)
    - [x] Music; volume sliders in the settings screen (`Sfx.set_volume`)
    - [x] Water ambient: running water on the river map, lapping near the farm / village ponds (`maps` / `near` rules)
    - [x] Shop and event music: the Yorozu Store, the Kurogane Smithy, heart events, the opening (`maps` / `events` music rules)
    - [x] Windows export preset (`export_presets.cfg`, .pck embedded) and our app icon
    - [ ] Build the .exe and check it starts (needs the 4.7.2 export templates; README → Export)
    - [x] Settings: display mode, window size, v-sync, text speed, always run, show HUD, reset to defaults, pad remapping
    - [x] Settings 2: FPS limit, UI size, window sizes that fit the screen, triggers / right stick in pad slots

## Tools of record
Godot 4.7.2 (GL Compatibility), GDScript, headless tests in `tests/`, Movie Maker screenshots.
