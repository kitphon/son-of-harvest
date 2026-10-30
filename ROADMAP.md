# Harvest Son — roadmap

Goal: a cozy farming life-sim with Back-to-Nature-style camera and feel, made entirely of our
own code, art, story and numbers, shipped as a Windows .exe from Godot 4.7.
Rules per system: docs/DESIGN.md. What was done and how it was checked: WORKLOG.md.

## Next up
Milestone 1 is done as a rough loop. Next is milestone 2, step 1: **real sprites for the
farmer** (16 x 24 or 16 x 32, 4 facings x walk / run / idle, mirrored like now). Load them
from `art/` through PlaceholderArt's keys (or replace that class with a sprite loader). Add
walk animation timing to the 3D sprite. Before drawing, check what reads well at the camera's
scale (~1.1 cells tall, ~50 px on a 270-line screen) with one test frame.
Ask the user whether they draw the art themselves or want placeholders refined first.

## Milestones

1. **Core loop** — time → farm → ship → sleep
   - [x] Clock (0.5 s per minute, day at 6:00, 4 x 30 days), day/night light
   - [x] Weather rolled a day ahead, rain waters the field, storm damage
   - [x] Farm grid, hoe / can / sickle / hammer / axe, seed bag 3 x 3, growth, regrowth, withering, weeds
   - [x] Shipping bin (paid 18:00 or on sleep), seed stand, sleep / pass out, stamina
   - [x] HUD, 2D view, 3D view with the HM field camera (yaw 45°, pitch 26.6°, FOV 13.7°)
   - [ ] Clock pauses indoors / in menus (no indoors yet)
2. **Look and feel**
   - [ ] Farmer sprites + walk / run animation
   - [ ] Field object and crop sprites (one set per crop and stage)
   - [ ] Ground tiles instead of flat colours (grass, soil dry / wet / tilled, paths, water)
   - [ ] House, bin, stand, fence as models or textured boxes
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
