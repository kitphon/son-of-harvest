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
milestone 8). Fatigue, tired poses, oversleeping and collapse are done (data/body.json).
Holding and throwing is done: a harvest goes up overhead, E throws it (into the bin = shipped,
into the pond = gone), Space sets it down, items lie on the field and are saved
(data/hold.json).
Weather is done for now (snow lies in winter, lightning flashes in storms; flashes can be
turned off in Esc → Settings or with `-- --no-flashes`), the text box is done (data/dialogue,
DialogueRunner, TextBox) and the pause menu (Esc: resume, save, settings, back to title;
settings in `data/settings.json` / `user://settings.json`, so a volume setting is one data
entry).
Eating / drinking is done: food and drink in `data/foods.json` (stamina +, fatigue −, specials
for max stamina and half swing fatigue for a day), eaten from the 7th tool slot (Q = next
food) and sold at the seed stand while that slot is in hand. Raw crops, eggs, milk and fish
are food too (`raw` in foods.json; F in the rucksack, or the food slot with one overhead), and
cooking is in: the kitchen corner's stove opens a cooking screen, recipes in
`data/recipes.json` take ingredients from the rucksack and the chest, the dishes are foods;
four recipes are known at the start, five are taught by Tome, Sayo, Hachiro, Kota and the
radio (flags `recipe_<id>`; README → Cooking). Later for food: daikon and rice crops for the
recipes, dishes as gifts / sold, cooking tools.
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
volume sliders in Esc → Settings. The four festivals have their own scores. Later for audio: more tracks (shops, events)
are new scores and rules in `data/music.json`; the music has not been heard by a person yet.
The rucksack and the storage chest are done (I opens the rucksack, the chest stands right of
the house; slot counts in data/inventory.json, so a shop's rucksack upgrade is one number via
`Inventory.grow("bag", n)`). The item held overhead is the rucksack's hand slot. Keys can be
rebound in Esc → Settings → Controls (defaults in data/controls.json, saved in the settings
file). Later for menus: remapping pad buttons.
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
on Sunday afternoons. Later for villagers: whistling, real portraits.
Relationships are in (milestone 9): the heart band shows as a coloured heart on the text
box's name tag, each villager has a birthday (on the farmhouse calendar; gifts x5, a birthday
line), villagers left alone may lose a point at night, and each has a heart event at band 3
(data/events/heart_<id>.json) and a second one at band 5 (heart_<id>_5.json); on a birthday the
villager follows a `birthday` day plan, the weather is fair and the HUD tag names it. Gift
lists include mine finds. Later for relationships: a band 6 scene, the story flags the band 5
scenes set (tome_grandma, sayo_sign, hachiro_bell) shown in the world (the bell by the farmhouse
door, the store's new sign).
Shops are in (data/shops.json): the Yorozu Store and the Kurogane Smithy in the village, with
opening hours and days off, a buy / sell screen and tool upgrades over days (saved). A
shopkeeper only has to stand at the map's `keeper` spawn and call `Game.open_shop(id)`.
The store also sells chickens (only with room in the coop), feed, Animal Medicine and two
bigger rucksacks, and takes orders for house extensions (bigger chest, kitchen corner, second
room) that Hachiro builds over days; the smithy improves the rod (bite factor per level in
data/fish.json). The store also sells cows, sheep, calves, lambs (only with room in the barn)
and fodder. Later for shops: Hachiro seen at work while building.
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
fish, odds, bite timing and the pity rule are in `data/fish.json`. Later for fishing: a river,
fish as food / gifts, and
the 2D view's action hookup (main_2d.gd doesn't connect the Player's actions yet).
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
ice blocks hiding frost stone, a cold light; `winter` in data/mine.json). Later for the mine:
real art for the ice and the lantern (mine finds are in the gift lists now).
Festivals are in (milestone 9): `data/festivals.json` (date, hours, map, place, event, shops
shut, decorations, fireworks), the HUD tag under the clock, the calendar notes, fair weather
on the day, Kota and Tome out all day. Each festival has a contest at a judges' table (best
spring crop, biggest fish, best egg / milk / wool, brightest mine stone; villager rivals rolled
per year, prizes by place, a result event), its own music (`festivals` in the music rules) and
the shipping payout waits for the next day; Blossom Day has a dango stall that sells (README →
Festivals). Later for festivals: rivals walking up to the table with their entries, a ribbon
item to keep, a contest that is played (a mochi-pounding rhythm, a fishing race), stalls at
Lantern Night that sell, more villagers gathering once they talk.
The balance pass is done (milestone 8): our own crop, product, animal and extension prices,
`python -I tools/balance.py` prints income per season for a steady year-1 plan (WORKLOG has
the before / after table). Later for balance: the smithy now asks for ores (they go to
upgrades, not the bin) and cooking and contests add income, so re-run it with those in; play a
real year.
The ending is in (milestone 9): on the first morning of year 3 Tome brings the village record
(stars per category, a rank and a title from data/ending.json; README → Ending), then the
villager liked most says a word and the game goes on. Later for the ending: a look back at
the first day (the field then and now), a record every New Year, real art for the scroll.
Next: milestone 10, **Settings** (what the settings screen still lacks) and building the .exe
once the export templates are installed (README → Export); a playtest of a real year to
check the balance and the ending's steps.
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
   - [x] Pixel font for the HUD, clock box, a proper item / tool display (Japanese glyphs later)
3. **Tools and the body**
   - [x] Charging tools (hold to cover more cells, per tool level; data/tools.json)
   - [x] Tool levels and upgrades (experience from use; shop upgrades with milestone 8)
   - [x] Fatigue, tired animations, oversleeping, collapse (data/body.json)
   - [x] Eating / drinking, food items (data/foods.json, food slot, sold at the stand)
   - [x] Raw farm goods as food, cooking at the kitchen corner (data/recipes.json, recipe lessons)
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
6. **Events and dialogue**
   - [x] Text box (typewriter, portraits, choices, flags); our own, data/dialogue
   - [x] Event scripts + trigger tables per map (data/events; three small farm events)
   - [x] "Examine" trigger cause: E facing a spot plays an event (village, farm, farmhouse)
   - [x] Opening event (Tome on the farm), first visits to the shops (Sayo, Hachiro); `actor` / `place` event steps
7. **Animals**
   - [x] Chickens: coop map, feed box, happiness, egg grades, sickness / medicine, going out, incubator (data/animals.json)
   - [x] Cows / sheep (barn map, fodder, stalls, milk / wool by happiness, brushing, grazing, calves / lambs), the farm dog (data/animals.json)
8. **Shops and economy**
   - [x] Shops with prices from data, tool upgrades (data/shops.json; store and smithy in the village)
   - [x] House extensions, rucksack upgrade for sale (store: chickens, feed, medicine; smithy: the rod)
   - [x] Balance pass (income per season, seed, animal and extension costs; `tools/balance.py`); the store sells cows, sheep, calves, lambs and fodder
9. **Festivals, mining / fishing, relationships, endings**
   - [x] Fishing: rod (8th tool slot), cast at the farm / village pond, bite cue, fish per place / season / hour / weather (data/fish.json)
   - [x] Mining: entrance east of the village, floors laid out fresh from a seed, rocks / soft spots / hole down, ores and gems per depth and season (data/mine.json)
   - [x] Mine extras: ores for the smithy's upgrades, shops buying stones / ores / gems, light by depth with a lantern (both views), frozen floors in winter
   - [x] Festivals: one per season in data/festivals.json (Blossom Day, Lantern Night with fireworks, Moon Night, Year's Turn), HUD tag, shops shut, decorations in both views, an event once a year, villagers gather
   - [x] Festival contests with prizes and result events, festival music, payout held on the day, Blossom Day's stall
   - [x] Relationships: hearts on the text box's name tag, birthdays (calendar, gifts x5, birthday lines), the nightly loss for villagers left alone, a heart event per villager at band 3
   - [x] Relationships 2: a second heart event per villager at band 5, birthday day plans, fair weather and the HUD tag on a birthday, mine finds in the gift lists
   - [x] Ending: the village record on the first morning of year 3 (data/ending.json: ten categories graded in stars, five ranks), Tome's verdict, the closest villager's word; the game goes on
10. **Audio and release**
    - [x] Sound effects and ambient loops (synthesized from data/sfx.json, SFX / Ambient busses)
    - [x] Music; volume sliders in the settings screen (`Sfx.set_volume`)
    - [x] Windows export preset (`export_presets.cfg`, .pck embedded) and our app icon
    - [ ] Build the .exe and check it starts (needs the 4.7.2 export templates; README → Export)
    - [ ] Settings

## Tools of record
Godot 4.7.2 (GL Compatibility), GDScript, headless tests in `tests/`, Movie Maker screenshots.
