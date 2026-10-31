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
food) and sold at the seed stand while that slot is in hand. Later for food: raw crops as
food (DESIGN: about +3 / −1), cooking, a real shop with opening hours (milestone 5 / 8).
Event scripts and trigger tables per map are done (data/events, EventRunner /
EventTriggers / EventPlayer; README → Events); EventPlayer loads a map's table on
`Game.map_entered(map_id)`, so a new map's events are one `data/events/triggers_<map id>.json`.
The "examine" cause is done (E facing a spot in a trigger table: shrine, lanterns, empty
houses, name plate, gate board, calendar, radio). Later for events: villagers as actors.
Maps are in (data/maps: farm, farmhouse inside with the futon, a first village with a
shrine; doors, a fade, clock stopped indoors). Villagers (milestone 5, next item) get their
own map props / doors from the same files; the village houses' doors only show a message
until then.
Sound effects, ambient loops and music are in (milestone 10), with Music / Sounds / Ambient
volume sliders in Esc → Settings. Later for audio: more tracks (festivals, shops, events)
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
minutes). Later for villagers: their own house maps (`away` until then), hearts shown in the
text box, birthdays (gifts x5), the small daily affection loss when nobody talks to them,
whistling, real portraits.
Shops are in (data/shops.json): the Yorozu Store and the Kurogane Smithy in the village, with
opening hours and days off, a buy / sell screen and tool upgrades over days (saved). A
shopkeeper only has to stand at the map's `keeper` spawn and call `Game.open_shop(id)`.
Later for shops: house extensions and the rucksack upgrade for sale.
Chickens are in (milestone 7): the thatched coop right of the stand is a map (feed box,
nests, incubator, hen hatch); rules in `Animals`, numbers in `data/animals.json`, saved
(save version 2). The shop sells chickens through `Game.add_animal("chicken")`, feed through
`Game.animals.add_feed(n)` and Animal Medicine as the rucksack item `medicine` (not sold yet).
Fishing is in (milestone 9): the rod is the 8th tool slot, a cast waits for a bite ("!" and a
plip), a press in time lands a fish overhead (ship it in the bin or keep it in the rucksack);
fish, odds, bite timing and the pity rule are in `data/fish.json`. Later for fishing: a river,
better rods from the blacksmith (a bite-chance factor per rod level), fish as food / gifts, and
the 2D view's action hookup (main_2d.gd doesn't connect the Player's actions yet).
Talking, gifts and affection are in (a `talk` row with `who` in a trigger table plays an
event when the farmer talks to a villager); the keepers are `sayo` (store) and `hachiro`
(smithy). The opening event and the first shop visits are done (data/events/opening.json,
store_intro, smithy_intro; villagers act in events with the `actor` step).
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
6. **Events and dialogue**
   - [x] Text box (typewriter, portraits, choices, flags); our own, data/dialogue
   - [x] Event scripts + trigger tables per map (data/events; three small farm events)
   - [x] "Examine" trigger cause: E facing a spot plays an event (village, farm, farmhouse)
   - [x] Opening event (Tome on the farm), first visits to the shops (Sayo, Hachiro); `actor` / `place` event steps
7. **Animals**
   - [x] Chickens: coop map, feed box, happiness, egg grades, sickness / medicine, going out, incubator (data/animals.json)
   - [ ] Cows / sheep (barn, milk / wool, brushing), dog
8. **Shops and economy**
   - [x] Shops with prices from data, tool upgrades (data/shops.json; store and smithy in the village)
   - [ ] House extensions, rucksack upgrade for sale
   - [ ] Balance pass (income per season, seed costs)
9. **Festivals, mining / fishing, relationships, endings**
   - [x] Fishing: rod (8th tool slot), cast at the farm / village pond, bite cue, fish per place / season / hour / weather (data/fish.json)
   - [ ] Festivals, mining, relationships, endings
10. **Audio and release**
    - [x] Sound effects and ambient loops (synthesized from data/sfx.json, SFX / Ambient busses)
    - [x] Music; volume sliders in the settings screen (`Sfx.set_volume`)
    - [x] Windows export preset (`export_presets.cfg`, .pck embedded) and our app icon
    - [ ] Build the .exe and check it starts (needs the 4.7.2 export templates; README → Export)
    - [ ] Settings

## Tools of record
Godot 4.7.2 (GL Compatibility), GDScript, headless tests in `tests/`, Movie Maker screenshots.
