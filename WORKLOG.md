# Harvest Son — work log

Newest first. Format per entry:

```
## YYYY-MM-DD — <title>
Agent: <agent / product> (<model>) · Commit: <hash or "this commit">
- Done: what changed.
- Checked: how it was verified (test output, screenshot, pixel values).
- Left / next: what is still open.
```

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
