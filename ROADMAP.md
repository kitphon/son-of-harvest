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
Next: milestone 3, **eating / drinking** (food items with stamina / fatigue effects in data;
`Game.add_fatigue()` takes a negative amount). After that milestone 6, **event scripts +
trigger tables per map**, built on the dialogue format.
Sound effects and ambient loops are in (milestone 10, first step); later for audio: music,
and the settings screen's volume sliders call `Sfx.set_volume("SFX" / "Ambient", 0..1)`.
Later for menus: rucksack / storage, key remapping.
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
   - [ ] Clock pauses indoors (no indoors yet)
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
   - [ ] Eating / drinking, food items
   - [x] Holding and throwing items (shipping by throwing into the bin; data/hold.json)
4. **Save / load and menus**
   - [x] Save game (Game + FarmGrid to a versioned JSON file), load; F5 / F9, saves on sleep
   - [x] Title screen (new game / continue / quit), Continue only for a save that loads
   - [x] Pause menu (resume / save / settings / back to title), settings file (flashes, window)
   - [ ] Rucksack / storage menus, key remapping
5. **Town and villagers**
   - [ ] Map switching (farm ↔ town ↔ houses), doors, indoor clock pause
   - [ ] Villagers with daily schedules from data (rule list → day plan), catch-up on map entry
   - [ ] Talking, gifts, affection, shop opening hours
6. **Events and dialogue**
   - [x] Text box (typewriter, portraits, choices, flags); our own, data/dialogue
   - [ ] Event scripts + trigger tables per map
   - [ ] Opening event, first visits to the shops
7. **Animals**
   - [ ] Chickens, cows / sheep, dog: feeding, happiness, produce grades, sickness
8. **Shops and economy**
   - [ ] Shops with prices from data, house extensions, tool upgrades
   - [ ] Balance pass (income per season, seed costs)
9. **Festivals, mining / fishing, relationships, endings**
10. **Audio and release**
    - [x] Sound effects and ambient loops (synthesized from data/sfx.json, SFX / Ambient busses)
    - [ ] Music; volume sliders in the settings screen (`Sfx.set_volume`)
    - [x] Windows export preset (`export_presets.cfg`, .pck embedded) and our app icon
    - [ ] Build the .exe and check it starts (needs the 4.7.2 export templates; README → Export)
    - [ ] Settings

## Tools of record
Godot 4.7.2 (GL Compatibility), GDScript, headless tests in `tests/`, Movie Maker screenshots.
