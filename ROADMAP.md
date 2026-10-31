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
Already-built placeholders (western-style house and fence) should move towards this when
they are next touched.

## Next up
The user chose to refine the placeholders first (real art later). Farmer, crops, field
objects, ground tiles and buildings are done. Next: milestone 2, **rain / snow particles and
a weather tint** (GPUParticles3D or CPUParticles3D around the camera target; rain streaks,
snow flakes, a grey-blue multiply on rainy days through the existing tint). Then the pixel
font / HUD clock box.
Open from the user: the farmer sprite still looks a bit odd to them (no details given, set
aside on 2026-10-31); ask what bothers them when coming back to the farmer.

## Milestones

1. **Core loop** — time → farm → ship → sleep
   - [x] Clock (0.5 s per minute, day at 6:00, 4 x 30 days), day/night light
   - [x] Weather rolled a day ahead, rain waters the field, storm damage
   - [x] Farm grid, hoe / can / sickle / hammer / axe, seed bag 3 x 3, growth, regrowth, withering, weeds
   - [x] Shipping bin (paid 18:00 or on sleep), seed stand, sleep / pass out, stamina
   - [x] HUD, 2D view, 3D view with the HM field camera (yaw 45°, pitch 26.6°, FOV 13.7°)
   - [ ] Clock pauses indoors / in menus (no indoors yet)
2. **Look and feel**
   - [x] Farmer placeholder frames (3/4 front / back x idle / walk / run) + animation timing
   - [ ] Farmer real art (same keys: `player:<front|back>:<pose>:<frame>`)
   - [x] Field object and crop placeholders (per crop look in `data/crops.json`, 4 growth looks + ripe)
   - [ ] Field object and crop real art (same keys: `crop:<id>:<growth>:<ripe|growing>`)
   - [x] Ground tiles instead of flat colours (grass, soil dry / wet / tilled, paths, water)
   - [x] House, bin, stand, fence as models or textured boxes
   - [ ] Rain / snow particles, weather tint
   - [ ] Pixel font for the HUD, clock box, a proper item / tool display
3. **Tools and the body**
   - [ ] Charging tools (hold to cover more cells, per tool level)
   - [ ] Tool levels and upgrades
   - [ ] Fatigue, tired animations, oversleeping, collapse
   - [ ] Eating / drinking, food items
   - [ ] Holding and throwing items (shipping by throwing into the bin)
4. **Save / load and menus**
   - [ ] Save game (Game + FarmGrid to a file), load, title screen
   - [ ] Rucksack / storage menus, settings, key remapping
5. **Town and villagers**
   - [ ] Map switching (farm ↔ town ↔ houses), doors, indoor clock pause
   - [ ] Villagers with daily schedules from data (rule list → day plan), catch-up on map entry
   - [ ] Talking, gifts, affection, shop opening hours
6. **Events and dialogue**
   - [ ] Text box (typewriter, portraits, choices); Dialogic 2 or our own
   - [ ] Event scripts + trigger tables per map
   - [ ] Opening event, first visits to the shops
7. **Animals**
   - [ ] Chickens, cows / sheep, dog: feeding, happiness, produce grades, sickness
8. **Shops and economy**
   - [ ] Shops with prices from data, house extensions, tool upgrades
   - [ ] Balance pass (income per season, seed costs)
9. **Festivals, mining / fishing, relationships, endings**
10. **Audio and release**
    - [ ] Music, sound effects
    - [ ] Windows export (.exe), icon, settings

## Tools of record
Godot 4.7.2 (GL Compatibility), GDScript, headless tests in `tests/`, Movie Maker screenshots.
