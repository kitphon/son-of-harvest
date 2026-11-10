# Harvest Son — work log

Newest first. Format per entry:

```
## YYYY-MM-DD — <title>
Agent: <agent / product> (<model>) · Commit: <hash or "this commit">
- Done: what changed.
- Checked: how it was verified (test output, screenshot, pixel values).
- Left / next: what is still open.
```

## 2026-11-10 — Crop art in the field, refined (the tall crops and the cluster plants)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: PlaceholderArt._crop's grown vine / stalk / grain looks (cucumber, tomato, corn, rice:
  `crop:<id>:2..3:*`, the one-sprite fallback) and _stalk (`stalk:<cucumber|tomato|corn|rice>:
  <2|3>:<growing|ripe>:<0..2>`, the CropClusters plants in both views) are laid in flat materials
  and toned by ItemArt.refine (data/item_art.json, no new entry): three tones lit from the upper
  left, deep-tone part lines, a rim in each material's deep tone instead of the 2a1e1e outline
  (_crop) or the one leaf-dark rim (_stalk). Materials: the stake, the leaf, the corn's stem
  (`_corn_stem`, the leaf a little yellower and darker), the tassel and the husk (new `_TASSEL`,
  `_HUSK`), the rice's front and back blades, the fruit (the cucumber's pale ripe colour). Dropped
  hand-shaded copies: the alternating light / dark leaves, the stake's dark column, the dark leaf
  stalks at the stake, the light growing tip, the fruit highlights, the cucumber's lit and dark
  columns (it is two pixels of one pale now), the ears' darker tips, the rice's lit middle blade.
  The corn's leaves are two pixels thick (one-pixel lines take no lit side) and the 16 x 16 rice
  fallback's blades two wide side by side; the cluster rice keeps its one-pixel blades. Removed
  dead code: _crop's seed / sprout / root / bush / ground branches (CropArt draws those), the
  `_root` helper, `_rim` and `_SOIL`, used only there. Same keys, sizes and anchors (bottom row);
  the single-sprite crops (CropArt) and the winter stubble are unchanged.
- Checked: new test_farm `_crop_art_refined` (every crop id, growth 0..3, ripe or not, and every
  stalk growth / state / variant: size and bottom row kept, no 2a1e1e pixel, at least four
  colours, the leaf in a refined tone); `_crop_art`'s black-outline check now covers the tall crops
  too. Three test_maps checks counted exact flat colours and now count the refined tones
  (ItemArt.tones): the vines' fruit only when ripe, the ripe cucumber not touching a leaf tone,
  the rice's gold ears. A 5x sheet of all the tall pictures and screenshots `--demo` (the cucumber
  stakes) and `--demo --season=summer` (corn rows toned green with deep-green rims, the ripe rice
  gold, no black outline) looked at; shots/ deleted. All tests/test_*.gd print `OK (0 failed)`;
  the four smoke runs print 0 ERROR and 0 WARNING lines.
- Left / next: the maple tree, festival decorations and story props still use the old outline.
## 2026-11-10 — Festival decorations, refined
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: PlaceholderArt._festival (sakura, picnic_mat, red_mat, stall in any cloth, judge_table,
  lantern_line, drum_stage, moon_table, pampas, race_flag, display_goldfish, display_masks,
  paper_lantern, kadomatsu, bonfire) lays each decoration in flat materials and passes it through
  ItemArt.refine instead of `_outline`: three tones lit from the upper left, deep-tone part lines,
  a rim in the material's own deep tone. `_lamp` now lays flat paper and cap materials (its own
  outline and lit stripe dropped; the ribs are fixed marks). Hand-shaded copies dropped (the
  puffs' lighter inner ovals, the roof bands, the mat hem, the pole highlight, the banner's dark
  side). Fixed marks: blossom spots, lid gold, tea, ink name and mask eyes, tacks, the cut ends,
  goldfish tail and fleck, mask paint. Laid after the refine with no rim: the sakura's petals,
  the mat's weave rows (in the mat's lit tone), the rosettes and the bonfire's flame. A few
  colours moved a step lighter where the refine's shade tones would have gone too dark (bark,
  planks, deck, logs). Same keys, sizes and anchors; the wares (`ware_*`) and the mochi usu are
  unchanged; the 3D lights and lamp glow are not touched.
- Checked: new test_festivals `_festival_deco_art_refined` (all 15 kinds keep festival_size, no
  2a1e1e pixel, at least four colours; a stall takes its cloth; the flame keeps ffb040 / fff0a0);
  all tests/test_*.gd and the four smoke runs, see the final report for the lines; screenshots
  `--demo --festival=blossom_day` and `--festival=lantern_night`.
- Left / next: crops (`_crop`, `_stalk`), the maple tree and story props still carry the old outline.
## 2026-11-10 — Maple tree art, refined
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: PlaceholderArt._maple_tree (`tree:maple:<season>:<snow>`, 24 x 32, the flat view's Japanese
  maple) now passes through ItemArt.refine (data/item_art.json, no new entry) instead of the
  2a1e1e `_outline`. The crown keeps its lumps and their leaf tones (spring 86b844, summer 2f6e32,
  fall c42a1e with the orange lumps dc6a1e), the trunk and bare winter branches keep their bark
  4a3428; the lumps' overlaps become part lines and the rim takes each material's deep tone. The
  winter snow (f4f8fc on the branches' upper side, only with snow) is a fixed colour, so it stays
  white. Same key, size and anchor; the 3D maple untouched.
- Checked: new test_view2d `_maple_art_refined`: all eight pictures (four seasons, snow on / off)
  are 24 x 32, have no 2a1e1e pixel and at least four colours. `_maples` (the existing picture
  checks: clear corners, bark, green / orange / red / snow by season) still passes. Screenshot
  `--demo --map=hill --season=fall` through `res://scenes/main_2d.tscn`: the two maples by the path
  read as round red crowns with orange lumps, a trunk and a rim in the deep tone; a 6x crop looked
  at, shots/ deleted. The 3D view of that frame shows bamboo and no maple (the 3D maple is elsewhere
  on the hill), so the check was on the flat view only.
- Left / next: the winter and spring pictures were not screenshotted (the tests cover their colours).
  Crop art in the field, festival decorations and story props still use the near-black outline.

## 2026-11-10 — Merge: HUD icons, field / mine art and the mochi mortar and mallet refined
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 3f5b0e9 HUD coin / stamina / weather icons (Sonnet), 7afcefd field obstacles, mine
  pieces and rope lift cage (Opus) and c106c07 the usu and kine (Haiku), each from its own worktree.
  scripts/art/placeholder_art.gd merged without a conflict (separate functions); WORKLOG and
  ROADMAP kept every side. ROADMAP Next up now opens the field crops' art as the next look task.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`; the
  smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print 0 ERROR or WARNING
  lines. No screenshot of the merged tree.
- Left / next: crops in the field (`_crop`, `_stalk`), the maple tree, festival decorations and
  story props still use the near-black outline; the Windows .exe still waits on the export templates.

## 2026-11-10 — HUD icon art (coin, stamina, weather), refined
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: `ui:coin`, `ui:stamina` and `ui:weather:<sunny|rain|storm|snow|blizzard>` in
  PlaceholderArt (`_ui`, `_weather_icon`) are laid in flat materials and passed through
  ItemArt.refine: the near-black outline is gone, replaced by tones lit from the upper left and a
  rim in each material's deep tone. The hand-placed light cloud top is dropped (refine lights the
  cloud). The sun's glint, raindrops, flakes, lightning and blizzard streaks are laid after the
  refine as fixed colours, so they get no rim. Same keys, sizes (9 x 9, 12 x 12) and main colours.
- Checked: test_weather `_hud_icons_refined` (sizes, no 2a1e1e, at least four colours each, the
  coin's lit gold tone); a throwaway 6x sheet of the seven icons looked at, then deleted; all
  tests/test_*.gd OK (0 failed); the four smoke runs print no ERROR or WARNING lines.
- Left / next: the 9 x 9 coin is busy at 6x (its hole gets a rim); look at it in the HUD at 1x
  if it should be calmer. The Windows .exe still waits on the export templates.

## 2026-11-10 — Field obstacles and mine art, refined
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: PlaceholderArt._obstacle (rock, branch, weed, stump), _mine (rock, big_rock, soft, hole,
  ice, lantern) and _lift_cage (`mine:landing`) now lay each sprite in flat materials and pass it
  through ItemArt.refine (data/item_art.json, no new entry needed) instead of the 2a1e1e
  outline: three tones lit from the upper left, deep-tone part lines, a rim in the material's
  own deep tone. Dropped hand-shaded copies: the rocks' lighter top ovals and lit bulge, the
  branch's dark under-line, the stump's darker roots, the soft spot's dark ring, the ice's
  shaded right side, lit left edge and lit tips, the cage's lighter timber and rope edges and
  plank top. Kept as fixed marks: the rocks' chips, cracks and seam, the stump's grooves and
  rings, the soft spot's clods and cracks, the hole's black pit, the ice's frost stone, air,
  crack, rime glints and glint, the rope's twist, the board ends and every lantern glow (panes
  and flame are not lit from outside). The hole's earth ring went from 2a221c to 3a3028 so its
  tones read; the cage's timber 6a4a2a to 7a5530 and planks 8a6a3a to 9a7848, the lanterns'
  iron 3a3430 to 4a4440 (the refined shade tones go darker). The frost sheet is left as it was
  (see-through, never had an outline). Same keys, sizes and anchors; the darkness by depth and
  the frozen floors are laid over these by the floor's light, as before.
- Checked: new test_mine `_mine_field_art_refined`: all 12 kinds keep their sizes, have no
  2a1e1e pixel and at least four colours; the main material shows its shade and lit tones (the
  hole's thin ring one of them, the lantern's one-pixel iron only its rim) and its own rim
  colour; the flame still glows. Screenshots `--demo`, `--demo --map=farm@gate` (rock, branch,
  weeds on the grass), `--demo --mine=3` and `--demo --season=winter --mine=3` (ice blocks, frost)
  and a 4x sheet of all 12 sprites looked at: toned, own-tone rims, no black outline; shots/
  deleted. All tests/test_*.gd print `OK (0 failed)`; the smoke runs print 0 ERROR / WARNING.
- Left / next: the HUD's coin / stamina / weather icons (ROADMAP Next up).

## 2026-11-10 — Mochi mortar and mallet art, refined
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: the Year's Turn mochi pounding's props in PlaceholderArt. `_usu(dough)` (32 x 24, the wooden
  mortar with its dough, every stage 0..3) is laid in flat materials: the body and cut top in
  MOCHI_WOOD, the bowl and foot in MOCHI_WOOD_DARK, the two hoops in MOCHI_HOOP, the dough as one
  mound in MOCHI_DOUGH. The hand-placed darker waist, lighter cut top and the separate darker dough
  underside are dropped (refine tones them). The rice grains (stage 0) and the shine (stage 3) stay
  fixed marks. `_kine()` (16 x 28, the mallet) is the head in MOCHI_WOOD with its end grain and
  hoop, and the handle in its own wood; the lighter handle column and the lighter top row are
  dropped. Both go through ItemArt.refine instead of _outline(). Same keys, sizes, dough stages and
  the grip (KINE_GRIP). MOCHI_DOUGH_SHADE is now only the rice grains' colour.
- Checked: test_festivals `_usu_kine_art_refined`: the four dough stages are 32 x 24 and differ, the
  mallet is 16 x 28, no picture has the 2a1e1e outline colour, each has several colours. One existing
  check in the same file changed: "the mortar and mallet pictures" expected the hoop pixel to be the
  raw MOCHI_HOOP colour; it is now one of the hoop's three refined tones (ItemArt.tones). Headless
  `--script res://tests/test_festivals.gd` prints `test_festivals: OK (0 failed)`. All 31
  tests/test_*.gd print `OK (0 failed)` (the runner counted 0 ERROR lines in each). Smoke runs
  (title, `-- --demo`, `-- --demo --map=town`, `-- --demo --mine=3`, `--quit-after 300`): exit 0, 0 ERROR
  and 0 WARNING lines. Screenshot `--demo --festival=years_turn --contest=mochi:auto`, frame 149:
  the mallet and mortar in the Mochi Pounding box read as toned wood with a lit top edge and no black
  outline; the dough shows in the bowl. A 5x crop was looked at; shots/ deleted.
- Left / next: the mochi box's mortar is small on screen (the game draws it at 32 x 24); no other
  mochi art changed. The HUD's coin, stamina and weather icons are still open in ROADMAP.

## 2026-11-10 — Merge: food, fish / mine / wild and kitchen / keepsake / ribbon icons refined
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged b2d3c84 food icons (Opus), 73fc8f4 fish, mine finds and wild things (Sonnet) and
  4b28a03 kitchen tools, keepsakes and ribbons (Haiku), each from its own worktree.
  scripts/art/placeholder_art.gd merged without a conflict; WORKLOG, ROADMAP and the run list of
  tests/test_inventory.gd kept every side. The two new test functions that git had interleaved
  (`_fish_mine_wild_art_refined`, `_kitchen_keep_ribbon_art_refined`) were put back whole from
  their branches. ROADMAP's open item now names only the HUD's coin, stamina and weather icons.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`
  (test_inventory rerun after the fix); the smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`) print 0 ERROR or WARNING lines. No screenshot of the merged tree.
- Left / next: the HUD's coin / stamina / weather icons still have the old outline; the Windows
  .exe still waits on the export templates.

## 2026-11-10 — Food icon art, refined
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the food icons (`ui:food:<id>`, every food and dish in data/foods.json, and so the onigiri
  in the tool bar) go through ItemArt.refine like the tools and crops. PlaceholderArt._food_icon
  now lays each shape in flat materials: the food `color`, the dish / wrapper `accent` and, for
  the dango, the stick and the plain white dumpling (new constants FOOD_STICK, FOOD_DANGO_WHITE,
  FOOD_EYE beside it). Dropped / merged hand-shaded copies: the onigiri's darker rice pixel, the
  sweet's highlight, the cup's darker saucer and lighter front (one accent), the bottle's lighter
  label (the cap's colour), the bowl's darker foot, lighter band and lighter food top, the plate's
  lighter face and the slice's lighter top row, the grilled fish's darker tail, the bag's darker
  fold and the sweet potato's highlight and darker tip. Kept as fixed marks: the slice's cut, the
  fish's eye and grill line, the chestnuts' shine dots (so the five chestnuts still read apart)
  and the bag's printed band. The cup's steam is still laid after the pass, soft white. Same keys,
  14 x 14, the same colours per food.
- Checked: new test_inventory `_food_art_refined`: for every food in data/foods.json the icon is
  14 x 14, has no 2a1e1e pixel, at least five colours, and its main material (the food for rice
  ball / round / skewer / bottle, the accent for cup / bowl / plate / fish plate / bag / sweet
  potato) shows its shade and lit tones and its rim colour; two cups still differ. A 6x sheet of
  all 38 food icons on the slot paper (throwaway script, not committed) looked at: toned,
  rimmed in their own deep tones, no black outline; shots/ deleted. All tests/test_*.gd print
  `OK (0 failed)`; the smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`)
  print 0 ERROR or WARNING lines.
- Left / next: fish, mine finds, wild things, kitchen tools, keepsakes, ribbons and the HUD's
  coin / stamina / weather icons (other agents / ROADMAP Next up). The bowls show only two rows
  of their food, as before.
## 2026-11-10 — Fish, mine find and wild thing icon art, refined
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: `ui:fish:*` (PlaceholderArt._fish_icon), `ui:mine:*` (_mine_icon) and `ui:wild:*` (_wild_icon)
  redrawn in flat materials (the hand-placed lighter / darker copies of the body, colour or accent
  dropped) and passed through ItemArt.refine like the tools and crops: three tones a material,
  deep part lines, own-tone rim instead of 2a1e1e. Small marks stay as fixed colours (the fish's
  eye, the stones' and gems' shine and glints, the ore's vein sparkle, the thumb mark, the frost,
  berry and nut highlights, the pod's seeds, the fern's curl eye, the mushroom's cap glint). The
  gem's crown, the crystal's lit facets and the shard's lit facet stay their own materials. Same
  keys, 14 x 14 sizes and per-item colours.
- Checked: new test_inventory `_fish_mine_wild_art_refined` (every fish, mine find and wild item:
  14 x 14, no 2a1e1e pixel, at least four colours, the main material's lit tone and its shade or
  deep one; thin fish bodies are all lit edge and part line, hence "or deep"). A 6x sheet of all 48
  icons on paper (throwaway script, not committed) looked at; deleted. All tests/test_*.gd print
  `OK (0 failed)`; smoke runs clean (see the commit).
- Left / next: the food, kitchen, keepsake and ribbon icons (other agents) and the HUD's coin /
  stamina / weather icons.
## 2026-11-10 — Kitchen tools, keepsakes and ribbons, refined
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: the cooking tools (`ui:kitchen:*`), the keepsakes (`ui:keep:*`) and the contest rosettes
  (`ui:ribbon:*`) laid in flat materials and passed through ItemArt.refine, as the tools before.
  Kitchen (PlaceholderArt._kitchen_icon): the hand-placed lighter and darker copies merged into
  one colour per material; the pot's glazed lid is its own material (7a4a36), the mochi mortar a
  red-brown lacquer (7a3a2a); the steamer's seam between its baskets is a clear row (the rim
  draws it); the rice in the mortar is a fixed mark. Keepsakes (_keepsake_icon): the shade and
  lit copies dropped (c and a are the materials); cords and strings 6a5a48, the fan's handle and
  ribs in its bamboo c8a060, the lantern's rims and ribs in ink 2e2a26; fixed marks: the chime's
  glint f4f8fc, the rabbit's inner ear e8a0a0, the moon f8f4e0. Ribbon branch of the icon
  switch: drawn inline (not through the shared _rosette, which the ribbon board still uses):
  one disc in the place's colour, two tails under a clear row, the gold button fixed; the darker
  pleat heart dropped. Same keys, sizes and the data colours of each item. The ribbon board,
  food, fish, mine and wild icons untouched.
- Checked: new test_inventory `_kitchen_keep_ribbon_art_refined`: all 6 cooking tools, the 7
  keepsakes and the 3 ribbons are 14 x 14, have no pixel in the old 2a1e1e and at least four
  colours. Test output lines: `test_inventory: OK (0 failed)`. A 16-icon sheet (throwaway script in
  the scratchpad, nothing committed) was looked at: the tools, keepsakes and rosettes read with
  three tones and the coloured rims. Every tests/test_*.gd (31 files) printed `OK (0 failed)` with
  no SCRIPT ERROR, Parse Error or FAIL line. Smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, each `--quit-after 300`) printed 0 ERROR or WARNING lines.
- Left / next: the food, fish, mine finds, wild things and the HUD's coin / stamina / weather
  icons still have the old outline (ROADMAP Next up). No flat-view or 3D screenshot of these
  icons yet.

## 2026-11-10 — Merge: item and tool icon art refined, dead animal art removed, flat-view animals checked
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged e486b39 Item and tool icon art, refined (Opus, own worktree), b891f56 the dead
  low-resolution animal art removed from PlaceholderArt (Sonnet, own worktree) and 84eddcf the
  flat-view screenshots of the refined animals (Haiku, own worktree, no code). Conflicts only in
  WORKLOG and ROADMAP; every side's entry kept. scripts/art/placeholder_art.gd took both the
  Opus and the Sonnet changes without a conflict.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`
  with no SCRIPT ERROR or Parse Error line; the smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`) print 0 ERROR or WARNING lines.
- Left / next: the rest of the item icons (food, fish, mine finds, wild things, kitchen tools,
  keepsakes, ribbons, the HUD's coin / stamina / weather) still have the old outline (ROADMAP
  Next up); the Windows .exe still waits on the export templates.

## 2026-11-10 — Item and tool icon art, refined
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the item and tool icons get the figures' and animals' refined look. New ItemArt
  (scripts/art/item_art.gd) tones an icon laid in flat material colours: every material in three
  tones (FigureArt.tones with new data/item_art.json's numbers, the villagers' tones, so what the
  farmer holds stands in the same light) by the side a pixel is open to (lit upper left, shade
  lower right), the lower / right edge of a part over another material in the part's deep tone
  (not on pieces one pixel thin), and a rim in the deep tone of the material it touches pulled
  towards `rim` by `rim_mix` 0.45 (less than the figures' 0.6, so the pale eggs, daikon, wool and
  milk keep a soft grey edge on the paper slots) instead of the near-black OUTLINE. Small marks
  (tuber eyes, ribs, kernel rows, the bundle's dots, the egg / glass shine, the best grade's
  sparkle, the whetted edges of the sickle and axe) are fixed colours left as they are.
  Redrawn in flat materials (the hand-placed lighter / darker copies of a material dropped, the
  pass makes them): `ui:tool:<hoe|can|sickle|hammer|axe|rod>` (tool colours now named constants;
  the rod's float now rimmed too, its line still laid after with no rim), `ui:seeds:<crop>`,
  `ui:item:<crop>` and the furoshiki bundle (PlaceholderArt._item_icon), `item:<crop>` held or on
  the ground (_item; the rice sheaf's straw one material with the stalk lines kept), and the eggs,
  milk and wool at 14 and 12 (the wool's two back puffs one material). Same keys, sizes, colours
  per crop / grade.
- Checked: new test_inventory `_item_art_refined`: data/item_art.json has its numbers; 6 tools,
  every crop's slot icon, held sprite and seed bag, the 9 animal goods at both sizes and a
  bundle keep 14 x 14 / 12 x 12, have no pixel in the old 2a1e1e, at least five colours, and
  (where one main material is named) its shade and lit tones and its rim colour; the egg grades
  differ; the white egg's rim is lighter than the old outline; the can's handle meets the tin in
  the handle's deep tone. A 6x sheet of all of them on the slot paper (throwaway script, not
  committed) and a 3D screenshot `--demo --rucksack` looked at (toned tools, seed bags, onigiri,
  turnip and potato in the slots); shots/ deleted. All tests/test_*.gd print `OK (0 failed)`; the
  smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print 0 ERROR or WARNING lines.
- Left / next: still the plain drawing with the old outline: the food icons (`ui:food:*`, also the
  onigiri in the tool bar), fish (`ui:fish:*`), mine finds (`ui:mine:*`), wild things
  (`ui:wild:*`), kitchen tools (`ui:kitchen:*`), keepsakes (`ui:keep:*`), ribbons
  (`ui:ribbon:*`) and the HUD's coin / stamina / weather icons. Each needs its few hand-shaded
  copies of a material merged before ItemArt.refine (the same way as here). No flat-view
  screenshot (the flat view uses the same icons).
## 2026-11-10 — Dead animal art removed
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: removed from scripts/art/placeholder_art.gd the unused first-generation animal drawings:
  `_animal` (the hen and its dispatch), `_chick`, the constants `_HEN_WHITE`, `_HEN_SHADE`, `_COMB`,
  `_BEAK`, `_CHICK`, the BEASTS entries cow, calf, sheep, sheep_shorn, lamb, and the branches of
  `_beast` only they used (rope / stub tails, fleece curls and wool cap, udder, cow eye, horns, the
  sideways ear, the unused `shade`). The key `animal:dog:held:N` now goes straight to `_beast`
  (the dog, unchanged). Grep over scripts/, tests/, tools/ and scenes/ found no other use of any
  removed name (no string-built keys or call()s reach them; every other animal key goes to AnimalArt).
- Checked: `--import`, every tests/test_*.gd prints `OK (0 failed)` with no SCRIPT ERROR or Parse
  Error (test_animals checks the held dog's 14 x 11 picture); the four smoke runs print 0 ERROR lines.
- Left / next: the Windows .exe still waits on the export templates.
## 2026-11-10 — Flat-view screenshots of the refined animals
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: no code changed. Took the flat view's first screenshots of the refined animals:
  `--path <worktree> --write-movie shots/frame.png --fixed-fps 30 --quit-after 20 res://scenes/main_2d.tscn -- --demo --map=barn`
  and the same with `--map=coop`. The scene argument form worked (the engine ran the flat view
  with no error). The last frame of each run was kept as shots/barn_2d.png and shots/coop_2d.png,
  and 4x nearest-neighbour crops of the animal areas were looked at; shots/ deleted afterwards.
- Checked: the barn frame shows a black cow with a pale muzzle and a dark calf, and a white
  sheep in full wool, the cow and calf in several browns and the sheep in cream with grey curls;
  the coop frame shows two white hens with red combs and grey wing shading, and a yellow chick on
  the straw. Each animal has several shades (base, lit and deep tones) and no near-black outline
  on the pale hens or sheep; the cow's rim is its own dark brown. Nothing broken seen. The frames
  are 480 x 270, so the animals are only about 15 to 25 pixels tall: the detail is hard to judge
  at that size. Colours counted in the animal areas: the barn 14 colours, the coop 14. Headless:
  `--headless --path . --script res://tests/test_view2d.gd` printed `test_view2d: OK (0 failed)`;
  `--headless --path . --script res://tests/test_animals.gd` printed `test_animals: OK (0 failed)`;
  neither printed a SCRIPT ERROR or Parse Error line.
- Left / next: a flat-view frame at a larger window size (the movie is 480 x 270 here) would show
  the animals' tones better. The egg items in the coop's boxes still have a near-black outline
  (an item, not an animal, so outside this task). The old hen and chick drawings in PlaceholderArt
  remain unused code.

## 2026-11-10 — Merge: animal art refined, the weed-flake audit, the persimmon hint checked
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged ab771d7 Animal art, refined (Opus, own worktree), 75d6381 the audit of the tests
  for the night's weed flake (Sonnet, own worktree) and ea273a0 the persimmon tree's hint checked
  (Haiku, own worktree). Conflicts only in WORKLOG and ROADMAP; every side's entry kept.
  tests/test_animals.gd took both sides' changes without a conflict.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`
  with no SCRIPT ERROR or Parse Error line; the smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`) print 0 ERROR or WARNING lines.
- Left / next: no flat-view screenshot of the refined animals; the old low-resolution hen and
  chick drawings in PlaceholderArt are unused code; the Windows .exe still waits on the export
  templates.

## 2026-11-10 — Animal art, refined
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the farm animals get the figures' refined look. AnimalArt (scripts/art/animal_art.gd) now
  draws every part in a material's three tones (FigureArt.tones with new data/animal_art.json's
  numbers, the villagers' tones, so the animals stand in the same light): ellipses lit on the
  upper left and shaded on the lower right, necks and tails toned by the side of the stroke, legs
  and hooves lit on the left column and shaded on the right, the far legs a step darker. A part's
  edge where it lies over another material is that part's deep tone (head over neck, the muzzle,
  the hen's wing with its scalloped feather edges, the wool's curls over the sheep's legs and face).
  The near-black OUTLINE is gone: the rim round the silhouette is the deep tone of the material it
  touches pulled towards `rim` by `rim_mix` 0.4 (less than the figures' 0.6, since the animals'
  pixels are half the size; the white hens and wool keep a soft grey edge, the black cattle a
  dark one of their own). The rim is laid before the mirror so the right facings still mirror the
  left exactly. All palettes (per kind, the birds, the eyes / nostrils / tongue / ear insides, the
  sick grey and mix) moved from code into data/animal_art.json; QUADS keeps only the geometry.
  The sick pose keeps its dull colours (toned from the dulled base). The dog held in the arms
  (PlaceholderArt._beast, 14 x 11) is toned through AnimalArt.refine_flat (BabyArt.refine, which
  now takes optional numbers), its eye and nose a dark brown instead of the outline colour. Same
  keys, sizes, poses, facings, SCALE, SHEAR and anchor (feet rim on the last row).
- Checked: new test_animals `_animal_art_refined`: the eight sizes as before; every kind x pose x
  frame x facing has no pixel in the old 2a1e1e, shows its main material's shade, base and lit
  tones, and has the material's deep tone pulled to the rim colour on its rim; the sick pose has
  none of the healthy base or lit tone; the hen and chick rims have no near-black colour and the
  pale coats' (hen, chick, sheep, lamb) lightest rim is above value 0.22 (the old outline was
  0.165); the hen's wing, the sheep's wool and the cow's muzzle show their deep part lines; the
  dog in the arms is 14 x 11 with no old outline colour and at least 8 colours. A 4x sheet of
  every kind and pose (throwaway script, not committed) and 3D screenshots `--demo --map=barn` and
  `--demo --map=coop` looked at (cow, calf and sheep in their stalls, hens and a chick on the
  straw: toned with soft rims); shots/ deleted. All tests/test_*.gd print `OK (0 failed)`; the
  smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print 0 ERROR or WARNING lines.
- Left / next: no flat-view screenshot of the animals (the flat view draws the same pictures at
  half size); the old low-resolution hen / chick / beast drawings other than the held dog are unused.
## 2026-11-10 — Audit of the tests for the night's weed flake
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: searched every tests/test_*.gd that runs a night (`end_day()` / `day_end`; 18 files) for
  checks that read a farm cell afterwards. To prove them, `FarmGrid.WEED_CHANCE` was temporarily set
  to 1.0 (every empty cell weeds each night) and all 31 tests were run. Failures: test_farm "daikon
  dries like any crop" (the empty plot's night weeded and untilled it, so the next sow failed),
  test_farm "a can with 2 water waters the first 2 cells" (the night weeded the tilled plots),
  test_animals "egg thrown into the bin is shipped" and "eggs in the rucksack ship at the bin too"
  and "milk thrown into the bin is shipped" (a weed on [8, 4], the cell between the farmer and the
  bin, makes `throw_target` answer "blocked"; the egg throw fails first, the later checks follow).
  Those tests use fixed seeds, so they passed every normal run, but they depended on the roll
  not hitting those cells. Fix: after the night each clears the weed (and re-tills the plot in
  test_farm) with a comment; no retry, no seed change, no rule change. The game is right (a weed
  stopping a throw is correct). Every other test, test_villagers included, printed `OK (0 failed)`
  with the chance at 1.0, so none else is at risk. The constant was reverted.
- Checked: forced 1.0 with the fixes: test_farm, test_animals, test_villagers `OK (0 failed)`. With
  the real chance all tests/test_*.gd print `OK (0 failed)`; smoke runs print 0 ERROR or WARNING lines.
- Left / next: none.
## 2026-11-10 — The persimmon tree's hint, checked
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: no bug found, no game code changed. The hint at Kiku's tree is ActionHints.interact_verb:
  "Pick" while fruit hangs (also with a persimmon in hand), "Look" on the bare tree. The test
  test_view2d `_persimmon` now checks the hint in the two missing cases: holding one with fruit
  left says "Pick" (and the press puts it in the rucksack, nothing thrown); hands empty on the
  bare tree says "Look" (the press gives the birds' line, nothing thrown, hands stay empty).
  The old check (holding, bare tree says "Look") stays.
- Checked: `--headless --path . --script res://tests/test_view2d.gd` printed `test_view2d: OK (0
  failed)` and `test_forage` printed `test_forage: OK (0 failed)` after `--import`. 3D frame
  (temporary shots/tree_shot.gd, the farmer put at (3, 5) facing up with Game.maps.pos and facing
  synced as Player does, presses through the Player's action signal): frame 169 after one press
  (held persimmon) shows the HUD "E Pick", the persimmon in the hand slot, and the crown with
  fewer fruit. A second frame after the rucksack and birds presses (still holding) shows the
  message "The rest are for the birds." and "E Look", nothing thrown. Its first run showed "E
  Throw" only because the script had not synced Game.maps.pos / facing (the HUD reads those, not
  the Player); the game code is not at fault. shots/ deleted.
- Left / next: the 3D frames were judged by eye at 480 x 270; the hint text is read from the
  picture, the verb values from the printed ActionHints output.

## 2026-11-10 — Merge: lumber flake, Kiku's picked lines all year, the persimmon pick in hand
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged e844018 the test_villagers lumber flake (Opus, own worktree), 3a6a44b Kiku's picked
  persimmon lines for winter, spring and summer (Sonnet, own worktree) and cc44f25 the persimmon
  picked with one already in hand, both views (Haiku, own worktree). Conflicts only in WORKLOG and
  ROADMAP; every side's entry kept.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`; the
  smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print 0 ERROR or WARNING lines.
- Left / next: ROADMAP "Next up" has no open item; the Windows .exe still waits on the export templates.

## 2026-11-10 — The test_villagers lumber flake: a night's weed, not the lumber
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: found the cause of the rare test_villagers failure. `_start_farm_views` orders the
  kitchen and calls `end_day()`; that night `FarmGrid.day_end` rolls a weed on every empty cell
  (WEED_CHANCE 1%, Game.rng randomized at start) before `sync_build_flag` sets the build flag, so
  the lumber is not there yet to keep weeds off its cells. A weed on [2, 5] made "the lumber
  blocks the farmer..., the cell he fetches from stays open" fail (`farm.is_solid([2, 5])`); one on
  [1, 4] stayed after the lumber left and made "the lumber's cells are open once it is gone" fail.
  The game is right (a weed may grow there before the builder comes; nothing grows under the
  lumber while it lies there); the test was asking the wrong thing. Those two checks now ask
  `FarmGrid.under_prop` (is the lumber on that cell), and the closing one checks both [1, 4] and
  [1, 5]; the "blocks" half still asks `is_solid` / `Game.maps.is_solid`. No retry, no seed.
- Checked: with temporary diagnostics printing the objects on [1, 4], [1, 5], [2, 5], 120 runs
  before the fix: 119 `test_villagers: OK (0 failed)`, 1 `FAILED (1 failed)` with `DIAG before:
  [0, 0, 3, "sunny", 2]` (3 = WEED on [2, 5]) and `FAIL: the lumber blocks the farmer (both views'
  Player asks Game.maps), the cell he fetches from stays open`; weeds on these cells showed in 6 of
  the 120 runs' diagnostics. Weeds forced on [1, 4] and [2, 5] the morning after the order: the old
  test printed both quoted FAIL lines and `test_villagers: FAILED (2 failed)`, the new one `OK (0
  failed)`. After the fix 100 of 100 runs printed `test_villagers: OK (0 failed)`. All
  tests/test_*.gd print `OK (0 failed)`; smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`) print 0 ERROR or WARNING lines.
- Left / next: nothing for this; other tests that read cells near the house after an
  `end_day()` could meet the same 1% weed.
## 2026-11-10 — Kiku talks about the picked persimmons outside fall
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: three new rows in data/dialogue/talk_kiku.json (winter, spring, summer; scion tree, Tuesday / Saturday, flag kiku_scion_picked) placed before the fall unpicked row, each with two lines: winter `scion_picked_winter_1..2` (hanging persimmons turning sweet, the one left on the tree for the birds), spring `scion_picked_spring_1..2` (the tree leafing out, keeping a seed in damp soil), summer `scion_picked_summer_1..2` (the green fruit set, some dropping in the heat). English and Thai (data/lang/th/dialogue.json). Before the first pick nothing changes; the fall picked lines are as before. No code changed.
- Checked: test_talk `_kiku_scion`: for each of winter / spring / summer over 700 days the new lines come on exactly 200 days (2 in 7), only Tuesdays and Saturdays, her close and dear lines on every other day, the unpicked days still pick the usual tree lines, both lines appear; through Game.talk_to the three seasons give their lines. test_talk and test_lang print OK (0 failed).
- Left / next: none.
## 2026-11-10 — Kiku's persimmon picked through the flat view
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: the first flat-view play of the picking found a bug (shared by both views, since both use
  FarmActions.on_action). With one persimmon in hand, the next press threw it at the tree ("No room
  to throw it."), so the second pick never reached the rucksack and the third never gave the birds
  line. Fix: on_action gives Kiku's fruiting tree (Game.scion_fruit_left >= 0) the interact press
  before the hands-full throw, so a press at the tree never throws at it. ActionHints.interact_verb
  says "Pick" while fruit hangs and "Look" on the bare tree (it used to say "Throw" when holding).
  Tests call FarmActions.interact directly, which is why test_forage missed the throw.
- Checked: test_view2d `_persimmon` (new) goes through Player's action signal: the full crown is
  drawn (art key story:scion:tree:fall:0); the first press picks one overhead ("Picked the ripe
  persimmon.", crown :4); the second puts one in the rucksack (count 2, crown :0); the third says
  "The rest are for the birds.", nothing thrown, hint "Look"; StoryView redraws the three pictures
  (draw signal) and they differ in pixels; the next morning (end_day) the crown is full again.
  Before the fix it failed 7 checks. The test loads ActionHints at run time: named as a class at
  parse time, it fails to compile in --script mode (Game is not yet an identifier), which made the
  HUD's ActionHints.pick fail too. Tests after the fix: `test_view2d: OK (0 failed)`. Every
  tests/test_*.gd (31 files) printed `OK (0 failed)` (test_audio also prints timing lines). Smoke
  runs (title, `-- --demo`, `-- --demo --map=town`, `-- --demo --mine=3`, `--quit-after 300`,
  headless): 0 SCRIPT ERROR / ERROR / WARNING lines. 3D screenshot: a temporary scene script
  (shots/pick_shot.gd) with `--path . --write-movie shots/frame.png --script ... -- --demo
  --flags=kiku_scion=door --season=fall --scion=tree` picked once through FarmActions at frame 60;
  frame 119 read: the crown has fewer persimmons than a full one and the message "Picked the ripe
  persimmon." shows. The farmer faced down (the field), so the hint read "Throw" for the field,
  not for the tree. shots/ deleted.
- Left / next: the 3D screenshot is 480 x 270 (movie size), so the crown's count is judged by the
  test's pixel checks, not by eye. The hint at the tree while holding a persimmon now says "Look"
  on a bare tree, not checked in a frame.

## 2026-11-10 — Merge: mochi box aside, villagers clear of contest spots, black goldfish
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 98be842 the mochi box at the left edge (Sonnet, own worktree), 618937c no villager
  in front of the farmer at a festival game (Opus, own worktree) and 58aca1f the black goldfish
  reads at the tub's size (Haiku, own worktree). Conflicts only in WORKLOG and ROADMAP; every
  side's entry kept. The Opus entry's "Left / next" (the mochi screen covers the middle) is done
  by the Sonnet side.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`; the
  smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --festival=years_turn --contest=mochi`, `--demo --festival=lantern_night --contest=scoop`) print
  0 ERROR or WARNING lines. Two agents each saw test_villagers fail once in their worktrees (the
  Haiku side quoted "the lumber blocks the farmer..." and "the lumber's cells are open once it is
  gone"), passing on rerun; on the merged tree it printed `test_villagers: OK (0 failed)` 11 of 11
  runs. Cause not found.
- Left / next: the test_villagers lumber flake (rare, cause unknown).

## 2026-11-10 — The black goldfish reads at the tub's size
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: look 2 (black) of the goldfish, PlaceholderArt `scoop:fish:2`, is a dark blue-grey
  (body 4a5668, value 0.41, not near black 3a3840 at 0.25) so it stands out from the tub's water
  (WATER 5a9ab8, value 0.72); fins pale (b8c4d4); the lit back edge lifted further (lightened 0.4
  instead of 0.22); a pale ring (dfe6ee) round each eye. Looks 0 and 1, the keys, the size and all
  rules are unchanged. Only look 2 branches in the drawing (`look == 2`).
- Checked: test_festivals `_scoop_art` keeps its checks (no black outline, several tones, looks
  differ) and adds two: the black fish's body centre differs from the water's value by at least
  0.25 (0.41 vs 0.72, a difference of 0.31), and its lit back edge (13, 3) is paler than the body
  by more than 0.1. The test uses the water colour as a literal with a comment, because
  referencing ScoopScreen from the test made Godot fail to compile the test script. `--demo
  --festival=lantern_night --contest=scoop:auto --quit-after 330`: last frame read, tub crop
  enlarged 6x: the black fish show as blue-grey with pale fins and eye rings. test_festivals OK (0
  failed), 0 SCRIPT ERROR lines. All tests/test_*.gd print `OK (0 failed)` except test_villagers,
  which failed once (2 failures in the lumber blocks checks) and then printed `OK (0 failed)` on
  two reruns, so it looks random, not from this change. Smoke runs (title, `--demo`, `--demo
  --map=town`, `--demo --mine=3`) print no ERROR or WARNING line. shots/ deleted.
- Left / next: the black fish's shape is still small at this size (about 20 x 10 px); a bigger
  tub or a larger sprite is not decided. test_villagers' lumber checks failed once in the run and
  should be looked at if it returns.
## 2026-11-10 — The mochi box moves aside so the farmer shows at the mortar
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: MochiScreen's box is narrower (paper 280 -> 220 px, stage 240 -> 208, the mortar, dough,
  figures and mallet grip moved 16 px left, the strike dots 6 px apart so 30 fit) and sits at the
  left edge, a little above the middle, like the scoop box. Hint shortened to "Tome turns. E:
  swing as the ring closes" (the Thai table's key renamed, its Thai line kept). Rules and numbers
  unchanged. The Moon Night race box (top middle, y 26..70) was checked in a `--festival=moon_night
  --contest=fishing:auto` frame: the farmer stands below it, not covered, so it is left as it is.
- Checked: test_festivals new checks (box at the left edge and left of the view's middle; the
  hint fits). Screenshot `--demo --festival=years_turn --contest=mochi:auto` frame 149: the box
  at the left, the hint whole, the ring and figures inside the paper. shots/ deleted.
- Left / next: none for this.
## 2026-11-10 — No villager stands in front of the farmer at a festival game
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the farmer plays every contest from the cell below its judges' table or game prop
  (Game `--contest=`); the camera looks from +x +y at yaw 45°, so the cells right of, below and
  down-right of that spot are in front of the farmer on screen. Festival plans that stood
  there were moved, in data only: Fumi's night-festival spot (14, 9) -> (12, 9), also when married
  (she stood down-right of the goldfish tub: the figure in front of the farmer at the scoop);
  Kota's loop by the stalls turns at (18, 8) instead of (16, 8) (right of the Lantern Night
  table); at Year's Turn Sayo (also married) stops at (19, 5) instead of on the mortar's spot
  (20, 5), Genzo stands at (18, 6) instead of (15, 5) (right of the table) and Ren (also
  married) at (13, 6) instead of (14, 6) (below the table). In the four judges' tables' result
  events the rival who walked up at the farmer's right moves a cell further out (and the one
  past him too): Blossom Day Tome 22, Sayo 23; Lantern Night Kota 17, Tome 18; Moon Night Tome
  24, Kota 25; Year's Turn Kota 17 (16 is a paper lantern). The festivals' crowds otherwise
  stand where they did.
- Checked: test_festivals `_contest_spots_clear`: for every festival's table and game, nobody
  stands on the farmer's spot or the three cells in front of it at any 2-minute step of the
  hours (unmarried, married to each candidate, and with the child out too; walkers passing
  are allowed), nobody at all there at the `--festival=` start time, and no result-event rival
  walks onto them. All 31 tests/test_*.gd print `OK (0 failed)`; the smoke runs (title,
  `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --festival=lantern_night
  --contest=scoop`, `--demo --festival=years_turn --contest=mochi`) print no ERROR or WARNING
  line. Screenshots `--demo --festival=lantern_night --contest=scoop:auto` frame 199 (the farmer
  crouched at the tub right of the box, nobody in front; crop looked at) and `--festival=years_turn
  --contest=mochi:auto` frame 149 (the screen, the crowd round it). shots/ deleted.
- Left / next: the mochi pounding's screen still covers the middle of the view.

## 2026-11-10 — The scoop box moves aside so the farmer shows at the tub
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: ScoopScreen's box is narrower (paper 280 -> 220 px, stage 240 -> 208, tub and bowl moved
  in) and sits at the left edge, a little above the middle, instead of over the middle of the
  view, where the camera keeps the farmer; so the new crouched scoop pose is seen beside the box
  while the game runs. The hint is shorter to fit: "E: dip with a fish under the paper" (the Thai
  table's key renamed, its Thai line kept). Rules and numbers unchanged.
- Checked: test_festivals new checks (the box starts at the left edge and ends left of the
  view's middle; the hint fits the paper). All 31 tests/test_*.gd print `OK (0 failed)`; the smoke
  runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --festival=lantern_night
  --contest=scoop`) print no ERROR or WARNING line. Screenshot `--demo --festival=lantern_night
  --contest=scoop:auto` frame 199: the box at the left, the hint whole, the farmer at about
  x 240, y 100 (found with the box hidden by a temporary edit, reverted) clear of the box; a
  villager stands partly in front of the farmer there. shots/ deleted.
- Left / next: the mochi pounding's screen still covers the middle; a villager can stand in front
  of the farmer at the tub.

## 2026-11-10 — Merge: farmer's scoop pose, goldfish art keys, Kiku's picked lines
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 29475b4 the farmer's pose at the goldfish tub (Opus, own worktree), b4f37bb the
  goldfish as PlaceholderArt keys (Sonnet, own worktree) and 754f9fd Kiku talks about the picked
  persimmons (Haiku, own worktree). Conflicts only in WORKLOG and ROADMAP; every side's entry kept.
  Each side's "Left / next" named the other's work; both are now in.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`; the
  smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --festival=lantern_night --contest=scoop`) print no ERROR or WARNING line.
- Left / next: the scoop screen (like the mochi screen) covers the farmer, so the new pose is not
  seen in play; a smaller box or a camera move during festival games would show it (not decided).
  The black goldfish reads a little blobby at the tub's size.

## 2026-11-10 — Goldfish art moved into PlaceholderArt
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: the scoop's goldfish are now PlaceholderArt keys `scoop:fish:0|1|2` (one per look of
  data/festivals.json `tub.looks`: orange, white with red, black), 20 x 10 top-down sprites facing
  right in the refined style: three tones lit from the upper left, a darker rim instead of a
  black outline, tail fan, side fins, patch, eye. `PlaceholderArt.scoop_fish_key(look)` clamps the
  look; ScoopScreen `_fish` draws that texture turned to the swim direction (tub and bowl)
  and its own polygon shapes and LOOKS table are gone. Rules and numbers untouched.
- Checked: test_festivals `_scoop_art` (keys, size, tones, no black outline, looks differ, the screen
  uses the textures); all tests/test_*.gd OK; smoke runs clean; screenshot of
  `--demo --festival=lantern_night --contest=scoop:auto --quit-after 330` shows the fish turned
  as they swim (crop looked at); shots/ deleted.
- Left / next: no farmer pose at the tub; the black fish reads a little blobby at the tub's size.
## 2026-11-10 — Kiku talks about the picked persimmons
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: Kiku now mentions the picking once the farmer has picked a persimmon from the grown twig
  tree. A new flag `kiku_scion_picked` (Scion.PICKED_FLAG) is set in Game.scion_pick on the first
  pick that goes into the hand or the rucksack. It is a flag, not the day's count `scion_picked`,
  because that count is zeroed every morning (Game.end_day) and could not tell "ever picked".
  data/dialogue/talk_kiku.json gets one twig row before the fall row: scion tree, fall,
  Tuesdays and Saturdays, flag kiku_scion_picked, four lines `scion_picked_1..4` (the fruit from
  the tree grown from her twig, pick gently, two a day and the birds, a proper orchard hand).
  The row sits before `scion_fall`, so once picked the fall question ("Have you picked any
  yet?") is not said again on those days, and the twig's share stays two days in seven. Other
  days, other seasons and an unpicked tree are unchanged. Thai for the four lines in
  data/lang/th/dialogue.json, Kiku's ยาย / จ้ะ voice.
- Checked: test_talk `_kiku_scion`: the picked lines on fall Tuesdays and Saturdays over four
  days, not on a Monday or in winter; over 700 days exactly 200 picked picks, all on Tuesdays or
  Saturdays; with the flag unset, 0 picked lines over 700 days; through Game.talk_to the picked
  case (`_kiku_talk(..., true)`) and the unpicked fall line. test_forage `_persimmon` checks the
  flag after the first real pick (E at the tree). Commands run on this worktree after
  `--import`: all 31 tests/test_*.gd print `OK (0 failed)` (test_lang and test_talk included);
  the smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--quit-after 300`)
  exit 0 with no ERROR or WARNING line.
- Left / next: the picked row runs only in fall, so in other seasons after the first pick her
  usual twig lines continue. Nobody has played the picking through the flat view with a
  half-picked tree yet.
## 2026-11-10 — The farmer's pose at the goldfish tub
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: while the goldfish scoop runs (Game.scooping) the farmer crouches at the tub in both views
  with the paper scoop and a small bowl. New FigureArt poses `scoop` (crouched 3 px, knees apart,
  leaning in, the scoop held out flat just over the water, the bowl at the belly; from the back
  the bowl is held out at the far side) and `scoop_lift` (just after a dip, for GoldfishScoop's
  `dip` lift: the body 1 px higher, the scoop tipped up with a fish on the paper and a drop
  falling). Drawn in the farmer's refined pass like the rod / eat poses (FigureArt `_poi`,
  `_bowl`); colours in data/farmer_art.json `scoop` (the ring and paper match ScoopScreen).
  Game.scoop_lifted (set each frame by ScoopScreen from `game.lifted()`, cleared on close, leave,
  finish_game and new_game) and Game.scoop_pose(); FarmerAnim.step takes it as a last argument and
  it wins over every other pose; main_3d and the flat Player pass it. Keys `player:<side>:scoop:0`
  / `scoop_lift:0` (PlaceholderArt comment). The pose ends when the go ends or is left.
- Checked: test_festivals `_scoop_pose_art` (colours in the data, one frame each, the scoop lower
  than the lift, ring and bowl band pixels in both poses from the front and the back, the scoop
  held out in front, the crouch lower than standing), `_scoop_play` (scoop_pose "scoop" on start,
  "scoop_lift" when lifted, "" after finish_game), the views (both views' FarmerAnim show `scoop`
  with the 3D sprite on that key, a dip turns both to `scoop_lift`, 0.5 s on back over the water,
  leaving the screen mid-game ends the pose in both); test_view2d `_figure` (the flat Player:
  scoop with the back key, scoop_lift, idle after). After `--import`, all 31 tests/test_*.gd print
  `OK (0 failed)` with no ERROR line; the smoke runs (title, `--demo`, `--demo --map=town`, `--demo
  --mine=3`, `--demo --festival=lantern_night --contest=scoop`) print no ERROR or WARNING line.
  Screenshot `--demo --festival=lantern_night --contest=scoop:auto`, frame 329: the scoop screen
  covers the middle of the view, so the farmer is hidden behind it (the mochi screen does the
  same); a second run with the box hidden by a scratch edit (reverted, not committed) shows the
  farmer from the back at the tub, red tenugui, the bowl with its red band out at one side and the
  pink scoop at the other (a villager stands partly in front). The pose sheet (idle / scoop /
  scoop_lift, front and back, 6x) was looked at too; shots/ deleted.
- Left / next: in play the ScoopScreen box hides the farmer and the tub (the pose shows only at
  the screen's edges or when the box is moved); a smaller box or a camera nudge while a festival
  game is up would let it be seen. The scoop's fish are still drawn shapes, not a PlaceholderArt key.

## 2026-11-10 — Merge: goldfish scoop, neglect-roll audit, Kiku's twig share
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 6268899 goldfish scoop at Lantern Night (Opus, own worktree), c3187f5 the
  neglect-roll test audit (Sonnet, own worktree) and 87b7659 Kiku's twig keeps her close and dear
  lines (Haiku, own worktree). Conflicts only in WORKLOG and ROADMAP; every side's entry kept.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`; the
  smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --festival=lantern_night --contest=scoop`) print no ERROR or WARNING line.
- Left / next: no farmer pose at the goldfish tub during the scoop; the scoop's fish are drawn
  shapes, not a PlaceholderArt key; nobody has played the scoop yet to tune its numbers.

## 2026-11-10 — Goldfish scoop: a played contest at Lantern Night
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: a third festival game kind, `scoop` (data/festivals.json lantern_night `game`; Festivals
  GAMES / `_check_scoop`: played at a stall prop with `display: goldfish` that sells nothing, so
  the indigo stall at [13, 7] that was only looks is now the game). `GoldfishScoop` (pure rules,
  scripts/festivals/goldfish_scoop.gd): a unit-circle tub with `tub.fish` goldfish on loops whose
  radius wanders (`orbit`, `drift`, `speed` either way round, three looks), rolled from a seed
  (festival + year, so a year's tub swims the same each time); the scoop hangs still at SPOT;
  press() dips it: within `reach.clean` a clean scoop, within `reach.edge` a rim scoop, else a
  splash; each dip uses `wear` of the `paper`; when it runs out the paper tears, the fish slips
  back and the go ends; a scooped fish's place refills after `refill` s; the scoop is lifted for
  `dip` s after each dip (no spamming). Game.start_game: kind scoop needs empty hands ("The scoop
  and the bowl take both hands..."), no partner, `Game.scooping` marks it busy; finish_game ranks
  it like the other games (judge_game, prizes, flags, `game_best_scoop`, ribbon `ribbon:scoop:<n>`
  "Goldfish Scoop ribbon", event `contest_scoop`, lines `scoop_result` in contests.json with a
  line for each rival winning and each place). `ScoopScreen` (both views, added in main_3d and
  main_2d): the tub from above on the stall's indigo cloth, the fish, the pink-framed paper scoop
  (a sweet-spot ring shows when a fish is right under it, ripples after a dip, wet patches as it
  weakens, shreds once torn), the paper bar, the bowl of fish scooped; calls Ready / Go! /
  Scooped! / Got it! / Splash / The paper tore! / Time!; sounds reuse mochi_count, chime_morning,
  fish_catch, hold_splash, fish_escape. Like the mochi pounding it holds the clock and is not
  saved part way (the go, the best count and the ribbon are saved). Thai for every new UI string,
  the game's name and the ten result lines. `--festival=lantern_night --contest=scoop` stands at
  the tub with the game counting in, `--contest=scoop:auto` dips by itself (AGENTS.md, README).
- Balance (ours): 45 s after a 3 s count-in, paper 100, wear clean 5 / rim 14 / splash 10,
  reach 0.14 / 0.26 tub radii, dip 0.4 s, six fish, refill 2 s. Measured over 40 tubs at 60 fps:
  dipping only when a fish is right under the paper: 9-19, median 16, tore 8 of 40 (19 clean
  dips is the paper's limit, so patience is rewarded and time and paper both bind); dipping at
  every fish in reach after a 0.1-0.3 s reaction: 7-10, median 8, always tears (rim scoops cost
  almost three clean ones); random eager dips near fish 4-10; random dips 1-8. Rivals: Shino 6-12
  (her trade is paper and water), Kota 4-10, Nana 3-9, Hachiro 2-8, so a steady player places
  2nd-3rd and a patient one wins. Prizes small: 300 G and two shaved ice, 120 G and a marble soda,
  60 G.
- Checked: test_festivals new `_scoop_data` (game, cell, not a shop, ribbon name fits, event,
  14 kinds of bad data refused, the tub stall needed, a selling stall refused, only a scoop has
  paper), `_scoop_timing` (count-in, clean / rim / splash / tear, lift, refill, time, seed,
  fish stay in the tub, Lantern Night balance over 12 seeds: patient median beats every rival's
  best, random dips under half), `_scoop_result_lines` (every place x winner), `_scoop_play`
  (farm none, held, start, busy, first prize, flags, record, one a year, the Catch contest beside
  it, save, E at the tub in year 2, last place, after the hours), and the views (both have the
  screen, each kind opens only its screen, the flat view's screen opens six fish and holds the
  clock, time / count text, a tear call, leaving mid-game frees the clock). The old check "the
  blue stall is only a look" now expects the scoop. After `--import`, all 31 tests/test_*.gd print `OK (0 failed)` with no ERROR line
  (`test_festivals: OK (0 failed)`); the smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, `--demo --festival=lantern_night --contest=scoop`) print no ERROR or
  WARNING line.
  Screenshot `--demo --festival=lantern_night --contest=scoop:auto`, frame 329 (about 8 s in):
  the box over the village reads "Goldfish Scoop  0:38  4 fish", tub with fish, the scoop over
  the water, the bowl with four fish, the paper bar about two thirds; the fish were drawn
  larger after a first look (crop at 3x looked at); shots/ deleted.
- Left / next: the 3D and flat stall still show the tub as decoration only (no farmer pose at the
  tub during the game); fish art in the screen is drawn shapes, not a PlaceholderArt key.

## 2026-11-10 — Audit: tests that could trip on the nightly neglect roll
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: audited every tests/test_*.gd that touches affection (child, ending, festivals, goals,
  relationships, talk, view2d, villagers, cooking, animals) for a points-at-a-band-edge setup followed
  by `end_day()` with no talk or gift that day (`Affection.day_end`, data/villagers/_common.json
  neglect chance 0.125, loss 1, `Game.rng` unseeded). Only the already-fixed test_child
  `_child_help_in_game` was at risk. The rest are safe: test_talk's `end_day()` calls follow a talk or a
  gift that day (no roll); test_child `_morning` sets Haru to the maximum (one point is no matter) and
  the child's neglect test calls `day_end` on purpose; test_relationships `_neglect` and
  `_neglect_in_game` seed their own rng (7 and 11) and are deterministic; `_marriage_in_game` sets Sayo
  and Fumi far above (Sayo) or only checks before (Fumi) any night; test_ending, test_festivals,
  test_goals and test_view2d never advance a day after setting points; the dog's affection
  (test_animals) is a separate counter with its own rules. No test changed, no game rule changed.
- Checked: mutation proof instead of luck: with `neglect.chance` forced to 1.0 (every night loses a
  point for everyone not talked to; reverted) the suites child, ending, festivals, goals, talk, events,
  save, shops, maps, animals and view2d still printed `OK (0 failed)`; only test_relationships failed,
  with its three checks that measure the chance itself ("left alone, Tome loses about 400 in 400 nights
  (lost 200)", "the loss is small", "but only a little"). A test that depended on losing no point would
  fail every run at 1.0, so none does. Loop runs on the unchanged tree (30 each): test_child, test_ending, test_festivals, test_goals, test_relationships, test_talk: 0 failures / 30 runs. All 31 tests/test_*.gd print `OK (0 failed)`; the four smoke runs print no ERROR or WARNING line.
- Left / next: none for this flake.

## 2026-11-10 — Kiku's twig keeps her close and dear lines
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: the four twig rows in data/dialogue/talk_kiku.json (`scion`) used to carry two twig lines
  and two of her own (dear_1 / close_1 for the sapling, dear_2 / close_2 for the young tree, dear_3
  / plain_2 for the tree), so from the planting day on every talk drew from a list where half the
  lines were hers and the rotation was halved. The fix is data only: each twig row now also names
  `weekday: [tue, sat]` and carries only its two twig lines. On Tuesdays and Saturdays Kiku says a
  twig line (about 2 talks in 7, the twig's fair share); on the other five days the rows below run
  exactly as before the planting, so her close and dear lines keep their full rotation there. The
  rows also no longer leak her heart lines to a stranger (the old sapling row had dear_1 with no
  band gate). Reasoning for the share: with a one-third twig share the rule can only come out of
  her other talks, and a fixed weekday pair is the simplest data-only split that needs no new pick
  key; 2 in 7 (29%) is closest to a third among whole weekdays. Lines, English and Thai (data/lang/th
  keyed by the English text) are unchanged; README → Villagers says so.
- Checked: test_talk `_kiku_scion` now counts over 700 days (each day's weekday from its number):
  for each stage the twig comes up on 25%..35% of talks, every talk on the other days is a close or
  dear line, and close / dear are at least 65% of all talks; unplanted, every band 6 talk is a close
  or dear line (700 of 700). Through Game.talk_to the planted cases now run on a Tuesday (the helper
  finds the season's first Tuesday; a season is not 28 days, so day 2 was not always one).
  Full run after `--import`: all 31 tests/test_*.gd print `OK (0 failed)` (test_talk, test_lang and
  test_relationships among them); the four smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, `--quit-after 300`) exit 0 with no ERROR or WARNING line.
- Left / next: the share of close and dear lines over all talks is about 71% after planting (5 of 7
  days), not 100%: the twig takes its share of the talks, so they cannot both stay at 100%. If the
  player wants a bigger or smaller twig share, change the weekday list. The old rows were not run
  against the new test, so the 50% share that prompted this was measured only by reading the rows.

## 2026-11-10 — Merge: Kaede's portrait hair, one thing in the arms, Kiku's twig lines
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 14bd884 Kaede's portrait hair (Opus, own worktree), dab3fa0 one thing in the arms
  (Sonnet, own worktree) and 670bdd6 Kiku talks about her persimmon twig (Haiku, own worktree).
  Conflicts only in WORKLOG and ROADMAP; every side's entry kept. The intermediate merge commit of
  dab3fa0 still had conflict markers in WORKLOG / ROADMAP; this commit removes them.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`; the
  four smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no ERROR or
  WARNING line.
- Left / next: other tests that set points on a band edge before `end_day()` are still not audited
  for the neglect roll; no flat-view screenshot of Kaede's portrait.

## 2026-11-10 — Kaede's portrait hair: tones for very dark materials
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: PortraitArt.tones now tones a very dark material from a lifted colour (new
  `PortraitArt.lift`; data/portrait_art.json `dark`: below 0.11, base_v 0.2). A material whose
  value is under `below` is lightened to value `base_v` first, then the usual shade / lit / deep
  rule runs. Before, Kaede's 1a1416 hair gave deep 0f0e12, shade 141217, base 1a1416: within a few
  steps of each other, so the hair read as one near-black blob (only the small lit strip showed).
  Now her hair is a dark charcoal base with the shade, the deep part lines and the lit side clearly
  apart, and still reads as black hair. A general rule in the tone step, not a per-portrait key;
  0.11 is chosen so Ichiro's 1e1a18 (v 0.12, the next darkest, mostly under his cap) is left as it
  was. The field figures (FigureArt) are not touched. The raw-hair brows over the face are unchanged.
- Checked: new test_dialogue `_dark_hair`: Kaede's hair counts as very dark; 1e1a18, 241a1a and two
  light colours are toned exactly as before; the dark hair's luminance steps deep < shade < base by
  at least 0.03 and lit 0.15 above base, base luminance at most 0.2; in all 5 of Kaede's moods and
  her child's 5 (child stage) the hair shows shade, base, lit and deep (at least 8 px each) with the
  lit pixels left of the shade ones. With base_v set to 0 (the old tones) the spread check fails
  (`[0.077, 0.084, 0.377, 0.058]`). Hashes of all 246 portraits and faces before / after: only
  portrait:kaede:* (5), face:kaede:* (4) and the child's portraits with her hair (15) changed.
  Screenshot `--demo --weather=sunny --map=town@shrine --time=9:00 --talk=kaede`: the text box
  portrait shows the toned black hair (4x crop looked at); shots/ deleted. After `--import`, all 31
  tests/test_*.gd print `OK (0 failed)` with no ERROR line; the four smoke runs print no ERROR or
  WARNING line.
- Left / next: no flat-view screenshot.
## 2026-11-10 — One thing in the arms: the dog, the baby and the crawler never together
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: answers the open question of "Hands full with the dog". Lifting the baby (Game.lift_baby,
  BabyActions.lift) and the crawler (Game.lift_crawler, BabyActions.lift_crawler) already refused
  with the dog in the arms (they test holding(), which includes arms_full()), and in FarmActions the
  dog / baby / crawler held branches come before every lift, so those two orders were impossible.
  The gap: DogActions.interact (pet, then pick up) did not look at what was held; Animals.dog_lift
  only checks the dog itself. Through FarmActions it was unreachable (the held branches catch it
  first), but a direct call with the baby or crawler in the arms lifted the dog too. Fix:
  DogActions.interact returns false (no pat, no pick-up, no message) when Game.holding().
- Checked: new test_child `_one_in_the_arms` tries all four orders (dog then baby at the cradle,
  dog then crawler, baby then dog, crawler then dog), through FarmActions buttons and the direct
  helpers. Before the fix: `FAIL: baby held: the dog is not picked up (DogActions)` and
  `FAIL: crawler held: the dog is not picked up (DogActions)`; after: `test_child: OK (0 failed)`.
  Note: with the dog held, the tool button at the cradle or the crawler sets the dog down (existing
  held-dog behaviour) and lifts nothing. Full run: see the commit report.
- Left / next: none for this question.
## 2026-11-10 — Kiku talks about her persimmon twig
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: Kiku's talk file gets four rows for the twig, placed before her heart rows and after the
  wet / festival / shrine rows. Her sapling lines (first year, the stake) and young-tree lines
  (second year) hold by stage; the fruiting tree gets fall lines (has the farmer picked any, the
  birds get the top ones) and other-season lines. The new pick key `scion` (Talk.holds, checked by
  Talk.check) takes a list of Scion stages; Game.talk_to puts the stage in as
  `Scion.stage` (or "" while nothing is planted). No other engine change. The rows also carry a
  few of her existing lines (dear_1..3, close_1/2, fall_1/2, plain_2), so her other lines keep
  coming after planting. 8 new lines, English in talk_kiku.json and Thai in data/lang/th/dialogue.json.
  README → Villagers lists the new key.
- Checked: test_talk `_kiku_scion` (pure picks per stage and season, nothing when not planted, a
  bad stage name is refused by Talk.check; through Game.talk_to: unplanted, sapling day 0, young
  at 130 days, fruiting tree in fall at 250 days, tree in winter). test_talk, test_lang and
  test_relationships print `OK (0 failed)`. All 31 tests/test_*.gd print `OK (0 failed)`. The four
  smoke runs (title, --demo, --demo --map=town, --demo --mine=3) print no ERROR or WARNING line.
- Left / next: the close and dear lines are shared into the tree rows, so they show less often
  after planting; no in-game screenshot of the lines was taken.

## 2026-11-10 — Merge: portraits refined, cradle / carry refined, test_child flake
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 4b30278 test_child help flake (Sonnet, own worktree), 96ca269 the baby's cradle and
  carry pictures refined (Sonnet, own worktree) and c2234c1 portraits refined (Opus, own worktree).
  Conflicts only in WORKLOG and ROADMAP; every side's entry kept. placeholder_art.gd and
  test_child.gd merged without conflict.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`;
  test_title prints only its two deliberate `No look ...` warnings. The four smoke runs print no
  ERROR or WARNING line.
- Left / next: every figure, the baby pictures and the portraits are now in the refined look (the
  older entries' "still plain" notes are closed by this merge). Other tests that set points on a
  band edge before `end_day()` were not audited for the neglect roll; Kaede's very dark hair shows
  its portrait tones only faintly. No flat-view screenshot of the merged tree.

## 2026-11-10 — test_child `_child_help_in_game` flake: the nightly neglect roll
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: root cause is a test setup problem, not a game bug. The test sets the child's affection to
  exactly the start of band 5 and calls `end_day()`. `Affection.day_end` rolls the neglect loss
  (data/villagers/_common.json, chance 0.125, loss 1) for everyone met who got no talk or gift that
  day, with the unseeded `Game.rng` (`rng.randomize()`); a lost point drops the child to band 4, so
  `Child.help` pulled nothing (the failing message was the spouse's feed line instead). About 1 run in
  8 failed. Fix in tests/test_child.gd: the child counts as talked to today before each of the two
  `end_day()` calls, which skips the roll. The game code is right and unchanged.
- Checked: `res://tests/test_child.gd` run 40 times in a loop before the fix: 7 failures / 40 (runs
  13, 15, 20, 31, 32, 37, 39; always the same five lines from "a sunny morning at band 5"); after the
  fix: 0 failures / 40 runs (at 1 in 8 per run, 0 of 40 by luck is about 0.4%).
  All 31 tests/test_*.gd print `OK (0 failed)`; four smoke runs print no ERROR.
- Left / next: other tests that set a villager's points to a band edge and then call `end_day()`
  could have the same 1-in-8 flake (not audited).

## 2026-11-10 — The baby's cradle and carry pictures, refined
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: PlaceholderArt `child:cradle` (20 x 16), `child:held` (12 x 12) and `child:carry` (16 x 14) now come
  out of the refined pass. Each picture is laid in flat material colours and new scripts/art/baby_art.gd
  (`BabyArt.refine`) tones them through FigureArt.tones with data/villager_art.json's numbers: shade / base /
  lit by the open side (upper-left light; skin shaded by its right side only), a line round the picture in
  the material's deep tone pulled to the rim colour (0.6), no black outline. Eyes, cheeks, mouth, dots and the
  cane weave stay as drawn; the weave is the cane's deep tone. New `baby` block in data/villager_art.json
  (cane, bound rim, rocker, pad, pale, eye, cheek, mouth). The eye is now 2a2a3a (the figures' eye) so no
  pixel is the old line colour. Keys, sizes, the four cradle looks and the child's colours are unchanged.
- Checked: test_child has new checks (four pictures: no pixel near black or the old 2a1e1e line, at least 8
  tones, carry stays 16 x 14; run with a fair-haired look since near-black hair has near-black tones of its
  own). Screenshots of `--baby`, `--baby=held` and `--child=crawler:held --time=7:00` looked at; shots/ deleted.
  Suites and smoke runs: see the merge report. test_child's weed / feed-box checks failed on 1 of 5 runs
  (the flake noted in the merge entry; unrelated, passes on rerun).
- Left / next: the portraits keep the plain drawing (another agent); the flake in test_child's morning
  help is still not looked into.
## 2026-11-10 — Portraits, refined
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the text box portraits get the figures' refined look. New PortraitArt
  (scripts/art/portrait_art.gd) and data/portrait_art.json: the portrait is drawn as before but on a
  clear picture, then every material of the head and shoulders (skin, hair, the top, its accent, the
  undershirt, the hairpin, the hat, the kimono collar and the straw hat's cord) is put in three
  tones lit from the upper left (a pixel within `band` 2 of its part's upper-left edge lit, of its
  lower-right edge shade; skin by its right side only, and skin is not lit or shaded against the
  hair over it). The black part lines become the deep tone of the material beside them, and lines
  against the background are pulled towards the rim. The drawing's own darker / lighter shades
  (neck, ears, the shaded cheek, the hair's combed lines, partings and shine, the top's folds,
  the accent's knots) are put on their material's tones. Then the nose, marks (stubble now finds the
  toned skin), eyes (data `eye`), mouth (the skin's deep tone) and the young cheeks go on top, and
  the background with its light from above goes under. Covers every `portrait:<villager>:<mood>`, the
  child's `portrait:child:...` at all three stages (`_child_portrait`), every PORTRAIT_HAIR style
  (they all go through `_portrait_of`) and the older generic `face:<speaker>:<expression>`. Numbers:
  the villagers' tones, deep 0.55, rim 1a1216 and rim_mix 0.6, so the face in the box matches the
  figure in the field; band 2 because a 40 x 40 face is about twice the scale of a figure's head.
  Keys, the 40 x 40 size, moods, colours and the hair drawing functions are unchanged. Portraits do
  not depend on the farmer's look (the farmer has no portrait in the game; the generic face:farmer
  is refined too).
- Checked: new test_dialogue `_refined_portraits`: every villager x 5 moods, the child at 3 stages
  for each of the 6 spouses who can marry x 5 moods, and every face:<speaker> x 4 expressions; each
  is 40 x 40 and opaque, has no pixel in the old line colour 2a1e1e, shows the skin's shade, base
  and lit tones with the lit pixels left of the shade ones, and has lines in the skin's deep tone;
  each child stage's moods differ; Hachiro's stubble is still drawn; Tome's eyes are in the eye
  colour. The existing portrait checks (sizes, moods differ, villagers differ, hair styles differ,
  keys) still pass. After `--import`, all 31 tests/test_*.gd print `OK (0 failed)` (test_title
  prints its two deliberate `No look ...` warnings). The four smoke runs print no ERROR or WARNING
  line. Screenshots `--demo --map=town --time=14:30 --talk=tome` and the same with `--lang=th`: Tome's
  portrait in the box shows the toned white hair, the warm skin shade on her right cheek and brown
  lines instead of black; a 4x crop looked right. A 3x sheet of every portrait (all villagers and
  moods, the child stages, the faces) looked right (throwaway script, not committed).
- Left / next: the baby's cradle and carry pictures are still the plain drawing. Very dark hair
  (Kaede's 1a1416) shows its tones only faintly.

## 2026-11-10 — Merge: inventory test leak, Nana's scarf on load, villager art refined
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 3a9aaa9 test_inventory frees its Game (Sonnet, own worktree), 710b6ae Nana's scarf
  set when an old save loads past fall 19 (Haiku, own worktree) and f9cf87b villager art, refined
  (Opus, own worktree). Conflicts only in WORKLOG and ROADMAP; every side's entry kept.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`;
  test_inventory no longer prints the exit ERROR / WARNING; test_title prints only its two
  deliberate `No look ...` warnings. The four smoke runs print no ERROR or WARNING line.
- Left / next: no flat-view screenshot of the refined villagers; the baby's cradle / carry pictures
  and the portraits keep the plain drawing; test_child's `_child_help_in_game` failed once in the
  Opus worktree and passed on every later run (looks timing-related, not looked into).

## 2026-11-10 — test_inventory no longer leaks a Game at exit
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: cause of `ERROR: 8 resources still in use at exit` (and `WARNING: 19 ObjectDB instances were
  leaked`): `_arms_full()` in tests/test_inventory.gd made a `game.gd` Node with `.new()` and never freed
  it (only `_game()` did). The leaked Game kept its scripts (farm_grid, inventory, affection, fishing,
  map_manager, animals, goals, game) loaded. Added `g.free()` at the end of `_arms_full()`. Test-only; the
  leak came in with that test (the dog / arms-full steps), not a game-code leak.
- Checked: before, `test_inventory: OK (0 failed)` then `WARNING: 19 ObjectDB instances were leaked at
  exit` and `ERROR: 8 resources still in use at exit`; after, only the OK line. All 31 tests/test_*.gd
  print `OK (0 failed)` with no ERROR/WARNING lines, except test_title, whose 2 WARNING lines
  (`No look part nose:1`) are the deliberate bad-look-id check, not exit errors. Four smoke runs: 0
  ERROR/WARNING lines.
- Left / next: nothing; no other suite printed the exit error.

## 2026-11-10 — Nana's scarf set when an old save loads past fall 19
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: Game.from_dict calls DateFlags.day_start for the loaded date, right after Scion.record, so a save
  from fall 20 or later without nana_scarf has the flag at once (the same function the morning uses; no
  copy of the rule). A save from before fall 20 does not get it. Closes the open item of the scarf entry
  below. Reasoning: a save loaded on fall 20 would otherwise show the jizo bare until the next morning.
- Checked: test_save has new load checks: years 1 fall 20, winter 1 and year 2 spring 1 load with the flag;
  fall 19, fall 1 and summer 28 of year 1 load without it. A new check runs Game.end_day (the morning) on a
  scratch game: moved from fall 18 to 19 it does not set the flag, from 19 to 20 it does. The fixture's
  flags carry nana_scarf (year 2 always has it under the rule), and the "no flags" load expects only that
  flag. Suites, run one by one on this tree after `--import`: all 31 print `OK (0 failed)`, test_save with
  no output lines besides its OK. test_inventory still prints its `ERROR: 8 resources still in use at exit`
  and `WARNING: 19 ObjectDB instances were leaked at exit` lines, and test_title its two look warnings; both
  noted before, not from this change. The four smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`) print no ERROR or WARNING line.
- Left / next: nothing open for the scarf. The rule counts a year after the first as past in every season
  (DateFlags.passed), so a year-2 save always carries the flag, as before this change.

## 2026-11-10 — Villager art, refined
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: FigureArt's refined pass (from "Farmer art, refined") now draws every figure. The refined
  pass is on for every draw; `farmer` only picks the numbers and the farmer's own pieces. The
  villagers (`farmer = false`) and the farmer's child as crawler, toddler and child (`draw_little`,
  and `draw_crawler`, which now runs through the same `_begin` / `_end`) use the new
  data/villager_art.json. Each material is drawn in shade / base / lit by the side of its part a
  pixel is open to (light from the upper left), lines between parts are in the material's deep
  tone instead of black, and the outer lines are pulled towards `rim`. The villagers' own pieces
  are materials too: data `materials` (the kimono's white tabi, the hat band, the hammer's wood
  and iron) and the look's shoulder bag (Ren), with the plain shades they are drawn in mapped onto
  their tones. Numbers: the farmer's tones, so everyone stands in the same light; rim_mix 0.6
  against the farmer's 0.5, so the white happi of Kaede and Yae and Tome's white hair still read on
  gravel and snow. Jika-tabi and the hip basket stay the farmer's (no villager wears the noragi).
  `tones()` takes an optional numbers dictionary; `villager_art()` is new. Every key, the 24 x 32
  size, the builds and the poses (idle, walk, work, fish, post, pole) are kept. The baby's cradle
  and carry pictures and the portraits are not FigureArt and are unchanged.
- Checked: the new test_villagers `_villager_art` covers 16 villagers x 13 pose frames x 2 sides
  plus the three child stages x 5 frames x 2 sides. Every frame is 24 x 32, the feet are on the
  ground and no black outline remains. At least 90% of the silhouette pixels on idle / walk are
  dark. Each villager's top shows shade, base and lit, with lit to the left of shade. Each front
  idle has more tone-edge pixels than the plain drawing (counts taken before the change, e.g.
  Sayo 256 -> 283, Nana 179 -> 204). Ren's bag and the hammer's iron show their tones, and the
  farmer's and the villagers' numbers are separate. test_villagers `_sprites`: "has the outline"
  became "no black outline, lines in the top's deep tone". test_farm's "villagers keep the plain
  outline" became "no black outline". test_title's farmer hashes are unchanged, so the farmer's
  frames are the same pixels as before. Ran all 31 tests/test_*.gd after `--import`: all print `OK (0 failed)`
  (test_inventory still prints the ObjectDB / `8 resources still in use` lines at exit; test_title
  prints its two bad-look warnings, as before). test_child failed once (5 checks in
  `_child_help_in_game`, the weeding news) on its first run, then passed three times, including on
  the unchanged code and in the full run. It looks timing-related; I did not look into it further. The four smoke runs print
  no ERROR / WARNING line. Screenshot `--demo --map=town --time=10:00` plus a 4x crop: Kota and
  Tome show the deep-tone lines and a dark rim on the grass and the path. A 3x sheet of every
  villager in idle / walk / work / fish / post / pole, front and back, and the child stages looked
  right (made with a throwaway script, not committed).
- Left / next: the flat view was not screenshot (it uses the same PlaceholderArt keys; test_view2d
  passes). One-pixel strips (the kimono's tabi, the hat band) keep their base tone. The cradle,
  carry and portrait pictures are still the plain drawing.

## 2026-11-10 — Merge: Nana's scarf from the morning after, Kiku's persimmons to pick, farmer art refined
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 3b4edc3 Nana's scarf set on the morning after her birthday (Haiku, own worktree),
  0037ed1 Kiku's grown persimmon tree can be picked (Sonnet, own worktree) and caf57c0 farmer art,
  refined (Opus, own worktree). Conflicts only in WORKLOG and ROADMAP; every side's entry kept.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`; the
  four smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no ERROR or
  WARNING lines. No screenshot of the merged tree (each branch took its own).
- Left / next: the half-picked persimmon tree and the farmer's back / fishing poses were not
  screenshot in the game; the villagers do not have the farmer's refined art pass yet;
  test_inventory prints `ERROR: 8 resources still in use at exit` at quit (suite passes; not
  checked whether it predates these changes).

## 2026-11-10 — Nana's scarf set on the morning after her birthday
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: `nana_scarf` no longer depends on the farmer being in Minamino on fall 19. New
  data/date_flags.json (rows `{flag, after: {season, day}}`) and DateFlags (scripts/farm/date_flags.gd,
  pure rules): each morning, Game sets a flag once the date has passed, in that year and in every
  later one. The row for nana_scarf is after fall 19, so the flag is set from fall 20 on. Game's
  morning calls it right after Scion.record. Reasoning: a map's trigger table only runs while the
  farmer is on that map, so the fallback has to be a morning rule. The fall 19 trigger row
  (9:40 on in Minamino) is unchanged and still puts the scarf on the day itself. The morning of
  fall 19 does not set the flag (the day is compared, not the 9:40 time).
- Checked: test_maps `_nana_scarf` has new checks: not set on spring 1, fall 18 or fall 19 of year
  1; set on the morning of fall 20 with the farmer away; set on winter 1 and on spring 1 of year 2;
  the rule is in the data. Suites, run one by one on this tree after `--import`: all 31 print
  `OK (0 failed)` (test_title prints two push_warning lines from its bad-look checks, and test_inventory
  prints `ERROR: 8 resources still in use at exit` at quit; date_flags.gd is not in that list; not checked
  whether these predate this change). The four smoke runs print no error or warning line.
- Left / next: an old save loaded on fall 20 or later gets the flag at its next morning, not at the
  load. The morning call in Game has no test of its own; the pure rule does. No screenshot (the
  prop is already drawn from the flag).
## 2026-11-10 — Kiku's persimmons can be picked
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: the grown persimmon tree (Scion stage "tree", fall) now bears fruit to pick. Facing it,
  the action button (FarmActions.scion_fruit, after forage) gives a ripe persimmon through
  Game.scion_pick: overhead, else the rucksack, else "No room for the ..."; once the day's picks
  are used it says "The rest are for the birds." (Kiku's own advice; English and Thai). The new
  item is `wild:persimmon` ("Ripe persimmon", data/forage.json items, no spot), so the existing
  item rules apply: it ships (30 G), is eaten raw (data/foods.json: stamina 5, fatigue -1) and is
  a gift Kiku likes (data/villagers/kiku.json). Balance (data/scion.json `pick`): 2 a day, back
  every morning (Game.end_day), about 60 G a day at most over a 30-day fall, a small treat beside
  the crops (a good crop of one plot is worth more); the fruit is only there in fall from the
  third year. `scion_picked` is saved as `forage.scion` (older saves: 0, clamped). The crown
  shows what is left: `drawn` 8 persimmons, each pick takes half (Scion.drawn_left), art key
  `story:scion:tree:fall:<snow>:<shown>` (suffix only after a pick). The 3D sprite re-textures on
  `forage_changed`, the flat StoryView redraws on it.
- Checked: test_forage `_persimmon` (picks, hand then rucksack, birds, 3D sprite and keys, save
  and old save, eat, sell, morning, wrong season / young tree), test_maps (fewer orange pixels
  per pick). All 31 tests/test_*.gd print `OK (0 failed)`; the four smoke runs (title, `--demo`, `--map=town`, `--mine=3`) print no error or warning lines; screenshot `--demo --flags=kiku_scion=door --season=fall --scion=tree`: the grown tree by the door with persimmons.
- Left / next: Kiku's talk lines do not mention the picking; the flat view was not screenshot
  with a half-picked tree.
## 2026-11-10 — Farmer art, refined (FigureArt's refined pass)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the farmer's frames (`player:<front|back>:<pose>:<frame>`, FigureArt.draw with farmer =
  true; the title screen's look preview too) get a refined pass, as the crops got from CropArt:
  every material of the look (hair, skin, noragi, collar band, monpe, head cloth, jika-tabi, the
  straw belt and hip basket, the white under-collar) is drawn in three tones, shade / base / lit,
  picked per pixel by which side of its part the pixel is open to (upper left lit, lower right
  shade; skin by its side only, since a shade along the chin read as a beard; the old plain `T` /
  `t+` shades are put on the same tones); the lines between parts are the material's own deep
  tone instead of the black outline, and the lines left on the outer edge are pulled darker
  towards a rim colour, so the silhouette stays clear. The jika-tabi now have a split toe, a
  brass clasp at the ankle and a pale rubber sole under the gathered monpe; the hip basket is
  woven (lit rim, checker weave, deep cord); the refined face has no jaw shade row. Numbers in
  the new data/farmer_art.json (shade 0.3, lit 0.22 with a cool shade tint and a warm lit tint,
  a warmer skin shade, deep 0.55, rim mix 0.5): chosen by eye against the grass and the deck,
  dark enough that the rim reads on both, light enough that the lit tones do not glare. Same rig,
  hands, rod tips, keys, 24 x 32 size, poses and every look option (style, hair, skin, clothes);
  villagers and the child figures (farmer = false) keep the plain drawing.
- Checked: test_farm `_farmer_art` (new): every pose, side and frame of the default look and of
  every style and clothes choice is 24 x 32 with a foot on row 30 and no black outline pixel; at
  least 90 % of the silhouette's edge pixels on idle / walk frames are dark; the top, monpe and
  skin use all three tones front and back, the noragi's and monpe's lit tones sit left of their
  shade; standing front / back have more tone-edge pixels than the plain drawing (305 / 268 now
  against 268 / 243 before); a villager-style draw keeps the outline. test_title's four golden
  hashes of the default look were re-recorded for the new art (the other look checks are
  unchanged and pass). After `--import`, all 31 tests/test_*.gd print `OK (0 failed)` (animals, audio,
  body, child, cooking, dialogue, drift, ending, events, farm, festivals, fishing, food, forage,
  goals, hold, inventory, lang, maps, menu, mine, puddles, relationships, save, shops, showcase,
  talk, title, view2d, villagers, weather). A first run of the whole list in one background loop
  stalled after test_ending (while screenshot runs went at the same time) and was stopped; every
  suite was then run again and passed.
  Smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--quit-after 300`): no
  error or warning lines. Looked at: a contact sheet old vs new (three looks x front / back, idle,
  walk, hold, fish, eat, tired), and screenshots `--demo` and `--demo
  --look=style:2,hair:1,skin:3,clothes:4` in the 3D view (zoomed on the farmer by the farmhouse
  deck) and `scenes/main_2d.tscn -- --demo` in the flat view.
- Left / next: a refined placeholder, not final hand art. Villagers still use the plain drawing
  (the same pass could be switched on for them next). Not screenshot: the back view and the
  fishing / eating poses in game (only on the contact sheet), the title screen's preview.

## 2026-11-09 — Merge: hands full with the dog, Nana's birthday scarf, Kiku's persimmon grows
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 7aa9895 hands full with the dog (Haiku, own worktree), 3ab9f07 Nana's birthday
  scarf on the jizo (Sonnet, own worktree) and 1dcf9a1 Kiku's persimmon grows over the years (Opus,
  own worktree). Conflicts in WORKLOG, ROADMAP and PlaceholderArt's story key comment (scion stages
  and jizo_scarf both kept). The first merge commit had kept conflict markers in WORKLOG / ROADMAP
  (CRLF lines missed by the resolver); fixed before anything was pushed.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`; the
  four smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error or
  warning lines. No screenshot of the merged tree (each branch took its own).
- Left / next: the dog and the baby / crawler held at once is not tested; the scarf is set only if
  the farmer is in Minamino on fall 19; the flat view's scarf height and the sapling at the field
  place were not screenshot; the grown persimmon has no fruit to pick.

## 2026-11-09 — Hands full with the dog: the rucksack never fills the hand while the dog is carried
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: Game.arms_full() now also counts the dog in the arms (animals.dog.held), so InventoryMenu
  (hold and choose, the carried stack too) refuses the hand slot with "Your hands are full." as
  it does for the baby and the crawler. holding() is now `held != "" or arms_full()`, the same
  set as before (the dog was already in holding()). Other callers checked: arms_full is used only
  by InventoryScreen and the menu; baby / crawler lifting, doors and the ground all go through
  holding(), which keeps the dog case, so nothing else changed.
- Checked: test_inventory `_arms_full` now loops over baby, crawler and dog. Before the fix:
  `FAIL: dog in the arms: arms full` and `FAIL: dog: hold puts nothing in the hand` (a script
  error followed, since the turnip did land in the hand). After the fix every suite prints
  `OK (0 failed)`: test_inventory, test_animals (the dog's pick-up and doors), test_farm,
  test_save, test_title, test_weather, test_dialogue, test_menu, test_body, test_events,
  test_maps, test_food, test_cooking, test_hold, test_villagers, test_talk, test_relationships,
  test_shops, test_fishing, test_forage, test_mine, test_ending, test_festivals, test_view2d,
  test_child, test_goals, test_lang, test_showcase, test_puddles, test_drift, test_audio (32 of
  32). Smoke run `--headless --quit-after 300 -- --demo`: no error or warning lines.
- Left / next: not checked: whether the dog and the crawler or baby can be in the arms at the same
  time (the test covers each one alone).

## 2026-11-09 — Nana's birthday scarf on the jizo by the Minamino lane
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: Nana's birthday plan and talk line (fall 19: she dresses the jizo by the lane in a new
  scarf) now leave something in the world. data/events/nana_scarf.json is a silent event that sets
  `nana_scarf`; a row in triggers_minamino.json plays it (enter / minute, fall 19, from 9:40 on, once)
  whenever the farmer is in Minamino that day after Nana is done at the jizo. The new `jizo_scarf`
  story prop (data/maps/minamino.json, cell 5, 18, gated by nana_scarf, examine line in English and
  Thai) is drawn over the jizo: 3D OutdoorProps.jizo_scarf (a knitted red band with cream stripes
  round the neck, one end hanging down the front), flat StoryView.KINDS + `story:jizo_scarf`
  (PlaceholderArt, 10 x 9). Own art, own colours (SCARF_RED d02a3c).
- Checked: `test_maps: OK (0 failed)` with the new _nana_scarf checks (the event, the trigger row's
  window, the prop by flag, the jizo still blocking, the art, one 3D mesh); full suite and smoke
  runs below. Screenshot `--demo --weather=sunny --season=fall --time=12:00 --map=minamino@river
  --flags=nana_scarf`, zoomed: the jizo wears a red scarf with cream stripes and a hanging end.
- Left / next: if the farmer is away from Minamino all of fall 19 the scarf is not set that year
  (no day-start hook off the farmer's map); the flat view's scarf height was not screenshot.

## 2026-11-09 — Kiku's persimmon grows over the years
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the twig planted in Kiku's band 6 scene now grows. The scene keeps its planting day: a
  new event step `{"do": "date", "flag": "kiku_scion_day"}` (EventRunner: today's
  Game.day_number into a flag; README → Events) after the scene's set step. Scion
  (scripts/farm/scion.gd, pure rules) and data/scion.json: stages by days since planting,
  sapling from 0 (16 x 26, the old picture), young from 120 (22 x 34, stake gone, a small round
  crown), tree from 240 (26 x 42, a wide crown, persimmons in fall, the one fruit left for the
  birds on a bare branch in winter, small green fruit in summer); snow on the bare winter
  branches from snow_cover 30. Reasoning: a year is 120 days (4 x 30); a real grafted persimmon
  takes years to bear, but a game's run is a few years, so the farmer sees fruit from the third
  year, one stage a year so each spring brings a visible change. Old saves (kiku_scion, no day):
  Scion.record gives it the day it is loaded on (Game.from_dict), also each morning and after a
  demo run's flags, so it starts as a sapling then. Art: PlaceholderArt
  `story:scion:<stage>:<season>:<snow 0|1>` (`_scion_story` split into sapling / young / tree,
  `_persimmon`, `_scion_crown`, `_scion_wrap`); StoryView.scion_key (both views; the flat view
  redraws each morning, the farm's 3D world is rebuilt each day). The 3D sprite now turns about
  y only (BILLBOARD_FIXED_Y) and stands 0.2 to the cell's front: a full billboard's top leaned back
  into the farmhouse eave (front z 4.05) and the grown crown was cut off. Same solid cell as
  before ([3, 4] door / [30, 8] field), never wider than 26 px, so the crown reaches at most
  5 px past the cell and clears the door column, path, spawn, bin, chest and Hachiro's row 5
  route. Demo flag `--scion=<stage>` (or `=N` days ago; plants by the door when kiku_scion is not
  set). AGENTS.md and README (Kiku, Events) updated.
- Checked: test_maps `_kiku_scion` (every stage and season drawn at its size and different,
  snow differs, three stages taller each time, at most 26 wide, persimmons only on the fall
  tree (>= 32 persimmon pixels, none on the young tree), stage by days: day 119 sapling, 120
  young, 240 tree, a day before planting a sapling; Scion.record once and only when planted;
  heart_kiku_6 has the date step and a date step keeps today's number; the art key follows
  age, season and snow); test_events refuses a date step without a flag; test_save: the day
  loads back, a save without it loads planted that day as a sapling. Screenshots (3D, `--demo
  --flags=kiku_scion=door`): `--season=fall --scion=tree` an orange-red crown hung with
  persimmons left of the farmer by the door, whole in front of the eave; `--scion=young` (spring)
  a thin trunk with pale new leaf clumps; `--season=winter --snow=80 --scion=tree` bare
  branches with snow along them, one persimmon left, the straw wrap at the foot; flat view
  (main_2d.tscn, fall tree) the persimmon tree left of the farmer by the house. All suites and
  the four smoke runs: see the final report.
- Left / next: the tree bears no fruit to pick (it is only drawn); the field place (30, 8) was
  not screenshotted.

## 2026-11-09 — Merge: hands full with the child, Kiku's persimmon sapling, Nana's keepsakes
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged cb1af67 hands full with the baby or crawler (Haiku, own worktree), 0a03f9e Kiku's
  persimmon sapling (Sonnet, own worktree) and d97fe6c Nana's keepsakes in the world (Opus, own
  worktree). Conflicts in WORKLOG, ROADMAP, AGENTS.md, StoryView.KINDS, StoryProps (header and the
  scion / captain_jar / frog / sky_map cases), PlaceholderArt's story key comment and test_maps
  (_kiku_scion and _nana_props both run): every side kept.
- Checked: on the merged tree after `--import`, all 32 tests/test_*.gd print `OK (0 failed)`; the
  four smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error or
  warning lines. No screenshot of the merged tree (each branch took its own).
- Left / next: the dog in the arms is not part of Game.arms_full(); the jizo's scarf from Nana's
  birthday has no flag; Kiku's sapling does not grow over the years.

## 2026-11-09 — Hands full: the rucksack never fills the hand while the baby or crawler is held
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: the bug existed. With the baby (or the crawler) in the arms, the rucksack / storage menu
  could still move an item into the hand slot (InventoryMenu.hold on a bag or chest item). Now
  Game.arms_full() (baby_held or crawler_held; holding() uses it) is the one rule: InventoryMenu
  takes it as its 4th argument (set by InventoryScreen from Game) and refuses a move into the hand
  with "Your hands are full." (hold and choose; a carried stack too). Picking up from the bag and
  swapping tools stay allowed; the ground and the chest's items already went through holding().
  Thai line already in data/lang/th/ui.json.
- Checked: test_inventory `_arms_full` (baby and crawler: hold, choose, the storage menu, closing
  puts the stack back, hands free again). Before the rule: `FAIL: baby: hold puts nothing in the
  hand` (the turnip went into the hand). After: `test_inventory: OK (0 failed)`. All 31 suites
  print `OK (0 failed)` (test_farm, test_save, test_title, test_weather, test_dialogue, test_menu,
  test_body, test_events, test_maps, test_inventory, test_food, test_cooking, test_hold,
  test_villagers, test_talk, test_relationships, test_shops, test_animals, test_fishing,
  test_forage, test_mine, test_ending, test_festivals, test_view2d, test_child, test_goals,
  test_lang, test_showcase, test_puddles, test_drift, test_audio). Smoke run `--quit-after 300
  -- --demo`: no error or warning lines.
- Left / next: not checked: the dog in the arms (animals.dog.held, also in holding()) is not part
  of arms_full, so the menu may still fill the hand while the dog is held. Not in this brief.
## 2026-11-09 — Kiku's persimmon sapling in the world
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: the twig from Kiku's band 6 scene now stands planted on the farm. Two story prop entries
  in data/maps/farm.json (kind `scion`, flag `kiku_scion`, flag_value `door` at cell [3, 4] left
  of the farmhouse door beside the path, `field` at [30, 8] at the field's right edge), both solid
  (nothing is farmed under it; clear of the door, spawn (4, 4), the bin, chest, the lumber, the
  streamer, Hachiro's row 5 route and the gate road). Drawn in both views: StoryView KINDS
  `scion` (art key `story:scion_<season>` from the game's season, redrawn each day start) and
  StoryProps `scion` (a sprite on its cell; the farm's 3D world is rebuilt each day);
  PlaceholderArt `_scion_story` (16 x 26: a young sapling beside a bamboo stake with a straw
  tie; spring pale buds, summer green, fall orange leaves and one small persimmon, winter a bare
  twig with a straw wrap round its foot). AGENTS.md note for `--flags=kiku_scion=door`.
- Checked: test_maps `_kiku_scion` (none before the choice, the cell by answer, solid and clear
  of fixtures / doors / row 5, four seasons drawn and different, the key follows the season, one
  3D sprite); all 31 tests/test_*.gd and the four smoke runs, see the final report. Screenshots
  (3D fall and winter, flat fall) show the sapling by the door; shots/ deleted.
- Left / next: the sapling does not grow over the years or bear fruit to pick; the field cell
  is only seen in a screenshot by walking there.

## 2026-11-09 — Nana's keepsakes in the world: Captain's jar, the frog in the ditch, the sky map
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done:
  - Band 3's answer now sets `nana_captain` (`pond` / `jar`; data/dialogue/heart_events.json).
  - Minamino (data/maps/minamino.json) gets two permanent props: Shige's little board hen barn
    (`hen_barn`, 19..20 x 4..5, east of his beds; the band 6 scene says the map is pinned to "the
    barn wall" and the hens complain) and the ditch behind his north bed (`ditch`, 15..17 x 2,
    where Nana found Captain). 3D: OutdoorProps.hen_barn (plank walls on a stone footing, a plank
    lean-to roof down to the front, corner posts, a board door, a hen hole with a cleated ramp,
    snow skin) and OutdoorProps.ditch (dark still water between muddy banks, reeds, snow skin),
    lit ArrayMeshes via CountryProps; flat view: MapView colours. A `barn` spawn (18, 6).
  - Story props (StoryProps in 3D, StoryView in the flat view, PlaceholderArt "story:" keys):
    `captain_jar` by Shige's door (10, 7) while `nana_captain` is `jar`, `unless` heart_nana_6
    (story:captain_jar, 10 x 13: glass jar, weed, the tadpole, paper lid with red string);
    `frog` on the ditch's back bank once heart_nana_6 (story:frog, 12 x 10, throat puffed to
    sing); `sky_map` on the hen barn's front once nana_sky (story:sky_map:<steady|beside>:<near|field>,
    30 x 20: a dim cream bedsheet, red pins, a crescent moon, dotted stars, her mother's blinking
    star, her father's big steady one or one beside hers (nana_beside), the farmer's gold star
    near his or out over three drawn field rows (nana_star); StoryView.sky_map_key from the
    shared flags). The sheet's top stays under 1.0 so it never fades on its own as a thing in the
    way (Occluders.MIN_HEIGHT: at 1.06 it went see-through beside the farmer).
  - Notes in heart_nana / heart_nana_6, minamino, README → Villagers, AGENTS.md (test_maps list,
    two `--flags` screenshot examples).
- Checked: test_maps `_nana_props` (nothing before the scenes or with Captain let go; the jar
  with `jar`; at band 6 the jar gone, frog and map shown for either band 3 answer; the band 3
  sets; the key by answers; four maps 30 x 20 all different; jar / frog sizes; barn, ditch and
  jar solid, Shige's door still opens; the 3D jar on its cell, the 3D frog in the ditch and the
  map on the barn's front in the answers' picture; the flat view's kinds and colours) and the
  minamino row of the no-stand-in-boxes check now covers hen_barn and ditch. After `--import`
  all 32 tests/test_*.gd print `OK (0 failed)`; the four smoke runs (title, `--demo`,
  `--demo --map=town`, `--demo --mine=3`) print no error or warning lines. Screenshots (frame
  39): `--demo --map=minamino@barn --time=10:00 --weather=sunny
  --flags=heart_nana_6,nana_sky,nana_beside,nana_star=field` shows the barn, the sheet with moon,
  stars and the gold star over the rows, the frog by the dark ditch; `--map=minamino@shige
  --flags=heart_nana,nana_captain=jar` the jar by the door; main_2d.tscn the same flags: the
  ditch strip with the frog and the map on the barn's box. shots/ deleted.
- Left / next: the jizo's new red scarf that Nana ties on her birthday still changes nothing
  in the world (no flag marks it); with Captain let go to the pond (`pond`) nothing shows until
  band 6.

## 2026-11-09 — Merge: holding the crawler, Kiku's band 6 scene, a portrait for the child
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 290e288 holding the crawler (Opus, own worktree), 5c73680 Kiku's band 6 scene
  (Sonnet, own worktree) and b4c970d a portrait for the child (Sonnet, own worktree). Conflicts
  in WORKLOG, ROADMAP (both Next up lines kept) and scripts/villagers/child.gd (the crawler's
  carry functions and the portrait functions both kept). The crawler entry below still lists the
  portrait and Kiku's band 6 as open; both are done (entries below it).
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`
  (test_child included; the portrait agent's one full-run test_child failure did not come back);
  the four smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error
  or warning lines.
- Left / next: the rucksack's hand slot may still take an item while the baby or crawler is
  held (untested); only the kiku_glad answer has its own band 6 line.

## 2026-11-09 — Holding the crawler
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done:
  - data/child.json `hold`: `stages` ["crawler"] (only the crawler is carried; the toddler
    walks), `stay_minutes` 30 (how long a set-down crawler sits where put before the plan has
    them again; the house's clock stands still, so in practice until the farmer leaves). Ours.
  - Child: `carried` (static: held, or set down {map, pos, facing, until}), `liftable`,
    `hold_stay`, `carried_place` (Villagers.where for id `child`: held = on no map, set down =
    that spot, still, turned to the farmer), `carry_key`; the data check covers `hold`.
  - Game: `crawler_held`, `crawler_at`, `lift_crawler`, `crawler_spot_free` (floor, no door,
    prop or anyone; on the farm no crop / item / fixture), `set_crawler_down` (front, else back
    where lifted), `crawler_back` on new game, map change, end of day and load; `holding()` and
    `held_key()` know the crawler. `--child=crawler:held` (after every flag: the farmer beside
    the crawler, facing them, lifted).
  - BabyActions `lift_crawler` / `crawler_held_action` (doors wait: "Set %s down first."),
    FarmActions wiring, ActionHints (Hold facing the crawler; Put down both buttons while held),
    PlaceholderArt `child:carry:<style>:<skin>:<hair>:<top>` (16 x 14, sitting up, happi, arms
    out), three Thai lines. README → Villagers, AGENTS.md (test_child, the flag).
- Checked: test_child new checks (Talk / Hold hints, lifted with the hand slot empty, the carry
  picture 16 x 14 in the child's colours, off the floor in both views while held, the door
  waits, set down in front turned to the farmer and drawn there in both views, the plan again
  after the stay, facing a wall: back where lifted, the futon sets them down first, map change
  / night / new game / load clear it, no lift with an item in hand, toddler and child never
  lifted); test_view2d `_crawler` (hold pose in the flat view, door, set down drawn). Mutation
  (`carried_place` not called): `test_child: FAILED (8 failed)`; restored. All 31 suites print
  `OK (0 failed)`; the four smoke runs print no error or warning lines. Screenshot `--demo
  --map=house --built=room --flags=married_sayo,spouse=sayo --child=crawler:held --time=7:00`
  frame 39: the crawler overhead in the indigo happi, the hint "E/Space Put down". shots/ deleted.
- Left / next: the child's portrait in the text box; Kiku's band 6 scene.

## 2026-11-09 — Kiku's band 6 scene: a twig of the oldest persimmon tree
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: heart_kiku_6 (under the oldest persimmon tree Kiku gives the farmer a twig cut from it,
  wrapped in wet moss, to plant; a line of its own for the band 5 answer, which now sets
  kiku_miss / kiku_glad; the farmer picks the farmhouse door or the field's edge, kiku_scion =
  door / field; sets heart_kiku_6 and kiku_graft), rows in triggers_minamino / kiku_house / town
  (hearts 6, seen heart_kiku_5), three dear_ talk lines, the music rule (Kiku's three events were
  not in it; added), Thai for every new line, tests in test_relationships (Kiku in the band 6
  loops, both answer branches, dear lines), README → Villagers and ROADMAP. Story and lines are ours.
- Checked: see the commit message / final report for the test lines.
- Left / next: nothing for hearts: every villager with hearts has all three scenes.

## 2026-11-09 — A portrait for the child
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: talking to the child (crawler, toddler, child stage) now frames a portrait in the text box.
  `Child.portrait_key` / `portrait_stage` build `portrait:child:<mood>:<stage>:<style>:<skin>:<hair>:<top>`
  (the spouse's hair colour, the hair style of that stage from `Child.small_style`: Sayo's bun
  for the toddler, her long hair for the child stage; the skin between the parents; the happi),
  `DialogueRunner.has_portrait` / `portrait_key` accept the child once out of the cradle (none for
  the baby or with no child), `PlaceholderArt._child_portrait` draws it through `_portrait_of`
  (the old `_portrait` body, now shared): a rounder, wider face with cheeks for the crawler and
  toddler, the young villagers' face for the child stage; cached by key like every texture. The
  name tag already shows the child's name (child_name flag); both views share the text box.
- Checked: tests/test_child.gd `_child_portrait` (key per stage, 40 x 40, every mood differs,
  cached, spouse's hair colour and mixed skin drawn, bun vs long, no portrait for the baby / no
  child, runner key); other tests and smoke runs: see the final report.
- Left / next: holding the crawler.

## 2026-11-09 — Merge: the child, step 5
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged 6f3404f the child, step 5 (Opus, own worktree) onto the Nana / Kiku merge.
  Conflicts in data/ending.json (Kiku's 15-friend scale and 40 stars kept, the child's
  child_line / child_undated / stages and their note added), the Thai dialogue (both sides'
  lines) and WORKLOG.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`;
  the four smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error
  or warning lines.
- Left / next: Kiku's band 6 scene; the child's portrait and holding the crawler (step 5 entry).

## 2026-11-09 — Merge: Nana's band 6 scene and hearts for Kiku
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged e99c579 Nana's band 6 scene (Sonnet, own worktree) and 7413aab hearts for Kiku
  (Sonnet, own worktree). Conflicts in the trigger tables (both sides' rows kept), music.json
  (heart_nana_6 and Kiku's two), the Thai dialogue (both sides' lines), test_relationships (the
  old "Nana has no band 6" check dropped, Kiku's kept), README / ROADMAP (Nana all three, Kiku
  bands 3 and 5; "Later for hearts" now only Kiku's band 6 scene) and WORKLOG. The Kiku entry
  below still lists Nana's band 6 as open; it is done (entry above it).
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`;
  the four smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error
  or warning lines.
- Left / next: the child, step 5 (in its own worktree); Kiku's band 6 scene.

## 2026-11-09 — Nana's band 6 scene: a star on her sky map for the farmer
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: heart_nana_6 (Captain is a frog and sings in the ditch; Nana pinned a bigger sky map to
  the barn wall and her father stood before it a long time; a line of its own for the band 5
  answer, which now sets nana_steady / nana_beside; one space left on the map for a star for
  the farmer, which the farmer places close to her father's or out over the farm field,
  nana_star = near / field; sets heart_nana_6 and nana_sky), rows in triggers_minamino /
  shige_house / town (hearts 6, seen heart_nana_5), three dear_ talk lines, music rule, Thai for
  every new line, tests in test_relationships (all friends loop incl. Nana, branches, dear lines),
  README → Villagers and ROADMAP notes. Story and lines are ours.
- Checked: see the commit message / final report for the test lines.
- Left / next: hearts for Kiku; the child, step 5.
## 2026-11-09 — Hearts for Kiku of Minamino
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done:
  - data/villagers/kiku.json: no longer `hearts: false`; birthday winter 25 (free day) with a
    `birthday` plan (home, the water shrine 8:30-10:00 to thank the spirit, her hearth after).
  - Talk (talk_kiku.json): birthday and gift_birthday, close lines from band 4, `bell_` lines
    once heart_kiku_5 is seen, forage lines from band 2 like the other friends (was band 1).
  - Heart events heart_kiku (band 3: the flood when she was nine and why she bows; daikon seed)
    and heart_kiku_5 (band 5: her brass bell, rung once for each person she misses, and
    whether the rim may ring for the glad ones; two daikon), dialogue in heart_events(_5).json,
    rows in triggers_minamino / kiku_house / town (before her mochi lesson), music rule.
  - Ending: a part and two lines for Kiku; calendar names her birthday; Thai for every new
    line. Record steps for fifteen friends (14 / 29 / 46 / 73 of 90) and Neighbours down to
    Dr. Yae (one step); the record has 40 stars now. README and ROADMAP updated.
  - Tests: test_relationships `_kiku_friend`, heart rows for her three maps, 15 friends;
    test_talk (her forage day moved into the friends' loop); test_ending counts.
- Checked: after `--import`, all 31 tests/test_*.gd print `OK (0 failed)` (test_lang and
  test_menu first failed on a stale Thai calendar key, fixed); the four smoke runs print no
  error or warning lines. Two fixes on the way: the font cannot draw ";" and a choice must fit.
- Left / next: Kiku's and Nana's band 6 scenes; the child, step 5.
## 2026-11-09 — The child, step 5: out with the spouse, the morning help, the record's line
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done:
  - data/child.json `days.child`: the child stage's own speed (1.0) and plans. `out` (sunny
    days): beside the spouse at home from 6:00, the yard by the kennel from 7:00, off along the
    farm path to the gate at 9:35; `festival` (the four festival days): with the spouse all day;
    `indoors` (rain, storm, snow): the second room. `with` says when the child is at the
    spouse's side wherever they are: `plans.out` 10:00-20:00, `plans.festival` 6:00-20:30,
    `join_at.mio` 10:30 (after her ferry), `side` [-1, 0], `tries` (the next free sides),
    `sides` (per spouse and map, none needed). `by_spouse.child` [1, 0] at home.
    Ours: the child goes along to the spouse's work late in the morning and comes home with
    them, and goes to every festival with them, as DESIGN's table says.
  - Child: `with_window`, `side_of`, `free_side` (while the spouse stands still, the first side
    that is in the map and not a wall, a door or a counter; MapManager.data), `place` (the
    time out with the spouse, else `by_spouse`); Villagers.where calls `place` for the id
    `child`. `small_style(style, stage)`: a stage's own `figures.<stage>.styles` first, so the
    child build wears the spouse's long hair and headband (no tenugui or straw hat).
  - The morning help: data/child.json `help` (stage child, band 5, weather sunny, weeds 2,
    messages one / more), `Child.help` / `help_text`, `FarmGrid.pull_weeds` (row by row from the
    field's top-left), `Game.child_help` from `end_day` after the spouse's help, the message
    `child_help_news` joined after the spouse's line on stepping out; flag `help_weeds` for the
    day. The spouse waters and feeds, the child only weeds.
  - Talk: 22 `child_` lines in talk_child.json (the yard, the weeds that morning, festivals,
    rain, close, again, and one for each spouse's work picked by `married_<id>` and that work's
    maps) and their Thai.
  - The record: data/ending.json `spouse.child_line` / `child_undated` / `stages`,
    `Ending.child_part`, `Ending.spouse_line(..., child)`; `Game._spouse_line(page)`: the record
    says "Married Sayo on Spring 14, with Hikari", the yearly page "..., with Hikari, walking
    now". Thai for the lines and the help messages.
  - README → Villagers (the child out with the spouse), → Ending; AGENTS.md (test_child,
    test_ending, the screenshot flags).
- Checked: test_child new checks (styles; the windows; Sayo's day: 6:30 beside her at home,
  the yard by the kennel at 7:30 / 8:20 / 9:10, crossing the farm at 9:55, at her side in the
  store at 12:00 turned to her, home with her at 18:00, away from 20:00; in on rain / storm /
  snow; every spouse on a Monday, a Sunday and the four festivals: by them every 5 minutes of
  the window, on free floor whenever standing, at least two maps on work days; Blossom Day
  13:30 in the village with Sayo; the store and festival talk picks; the weeds: none at band 4,
  on wet days or for a toddler, two at band 5 sunny with the flag, no watering, one / none, the
  messages and their Thai; in the game: the news after `end_day`, told on stepping out after
  Sayo's line, the `child_helped` line that morning, none at band 4; both views draw the child
  by Sayo in the store). test_ending: the child part, both lines, the longest line of every
  spouse x name x stage x page fits the paper in English and Thai, the record and the yearly
  page in the game at 70 and 200 days, no child no part. Mutation (`place` never seeing the
  spouse's position): `FAIL: 12:00: at Sayo's side in the store ((0.0, 0.0), (3.5, 2.5))`,
  `FAIL: home with Sayo in the evening`, `FAIL: noon: the child with Sayo in the store in both
  views`, `test_child: FAILED (61 failed)`; restored. All 31 suites printed `OK (0 failed)`. Smoke runs (title, `-- --demo`,
  `--map=town`, `--mine=3`, the child at the store, on Blossom Day and with Ren in
  main_2d.tscn) printed no error or warning lines. Screenshot `--demo --weather=sunny
  --flags=married_sayo,spouse=sayo --child=child --time=12:00 --map=store` frame 39: the child
  behind the counter at Sayo's left. shots/ deleted.
- Left / next: the five steps of DESIGN → ลูก are done. Not done: holding the crawler; a
  portrait for the child; the child hops a cell when the spouse stops where the first side is
  not free; on the walk between maps the child is not shown (as the spouses).

## 2026-11-08 — Merge: the child, step 4
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged c2ca432 the child, step 4 (Opus, own worktree) onto the Shige / Nana merge.
  Conflicts only in WORKLOG.md and data/lang/th/dialogue.json (both sides' Thai lines kept).
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`;
  the four smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error
  or warning lines.
- Left / next: the child, step 5; Nana's band 6 scene; hearts for Kiku.

## 2026-11-08 — The child, step 4: the crawler and the toddler about the house
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done:
  - data/child.json: `figures` (the FigureArt body per stage and cells per walk frame; the
    spouse's hair made small: long hair tied up in a bun, no headband, tenugui or straw hat),
    `days` (per stage a speed, rules and plans in the villager format; `by_spouse` offsets;
    `home` = house), `gifts_from` (toddler) and `gifts` (loves dango, sakura / kinako mochi,
    milk pudding, wild raspberries; likes mulberries, akebi, warabi mochi, tamagoyaki, onigiri,
    eggs, tomatoes; dislikes sansho, myoga, green tea, onion; hates fukinoto). Ours: the crawler
    never leaves the house (on the mat at the spouse's side, crawling about the second room at
    0.4 cells a minute while the spouse is out); the toddler (0.8) is beside the spouse at home,
    plays in the farm yard by the dog's kennel (11, 5) from 9:00 to 15:45 on dry days, stays in
    on rain, storm, snow and festival days; both in bed (`away`) from 20:00. The child stage
    uses the toddler's plans until step 5.
  - Child: `about`, `days_of`, `plan_name`, `plan`, `by_spouse` (while the plan and the spouse
    are both in the farmhouse: spouse + offset, turned to them; crawler [0, 1] on the mat in
    front of the spouse's (9, 3), toddler [1, 0] beside them, so the way into the second room
    at (8, 3) stays open), `colours`, `figure`, `small_style`, `figure_key`, `takes_gifts`,
    `named_dialogue`; `check` covers the new data. Villagers adds the little one to today's
    plans under the id `child` (`where` puts them by the spouse and adds `stage` and `look`),
    so both views (VillagerSprites, VillagerView), talking, blocking and the bump work as for
    a villager; `sprite_key` and `reaction` ask Child for the id `child`.
  - Art: `FigureArt.draw_little` / `draw_crawler` (on hands and knees, the big head in front,
    the indigo happi over the back with its crest from behind, the rump up, the soles turned up;
    a four-frame crawl) and a `toddler` build (head at row 18, shoulders 23); PlaceholderArt
    `child:figure:<build>:<style>:<skin>:<hair>:<top>:<front|back>:<idle|walk>:<frame>`.
  - Talk: data/dialogue/talk_child.json (30 lines: the crawler's babble and the toddler's
    first words, yard, rain, snow, close, busy, gift lines; the name put into `%s`), speaker
    `child` in speakers.json ("Little one"; the name tag shows the child's name and hearts:
    TextBox, `Game.heart_band`), new Talk pick key `stage`. `Game._talk_child`: a talk counts
    once a day, a gift from the toddler on, the crawler takes none ("%s is too little for
    presents yet."). `Affection.day_end` lets the nightly loss reach the child once met (last,
    so the villagers' rolls are unchanged), never below band 3; it now lists only ids that
    really lost some. Thai for every new line, the note and "Little one".
  - Debug flag `--child=<crawler|toddler|child>` (born that many days ago; year 2 when the
    calendar is too young); `--talk=<id>` now stands on the first free side when a wall is
    below (the crawler's mat). AGENTS.md and README → Villagers describe them.
- Checked: test_child new checks (data, about / not about, gifts from the toddler, small
  styles, the reactions; every house cell the plans use free in the second room and the
  doorway (8, 3) left open; the crawler at Sayo's side at 7:00 turned up, at home all day, at
  least three cells crawled, away at night, on_map with Sayo, its sprite key; the toddler
  beside Sayo, within 2.5 cells of the kennel at 9:30 / 11:00 / 13:20 / 15:00, home by 17:00,
  in on rain / storm / snow and a festival; the child stage on the toddler's plans in the child
  build; nobody under `child` without a birth; 12 different pictures (3 builds x front / back x
  still / walking), crawl frames differ, all on the bottom row, crawler lower than toddler lower
  than child, the toddler in the mixed skin; the talk file checks, no portrait, every line
  with the longest name fits, no gendered words, all Thai and fitting with the Thai name;
  picks by stage, time, map, band, again; E with the key hint Talk, the crawler's morning line
  with the name in it, a talk counts once, the hearts' band 3 on the tag, turned to the farmer,
  no gift from the crawler, 60 nights of neglect still band 3; the toddler loves dango and
  refuses a second gift; both views draw the crawler at (9.5, 4.5) and the toddler in the yard).
  Mutation (Child.by_spouse returning the plan's place): `FAIL: 7:00: the crawler on the mat in
  front of Sayo ((10.5, 2.5), (9.5, 3.5))`, `FAIL: turned up to Sayo, still`, `FAIL: the
  crawler on the mat at (9, 4) ((10, 2))`, `FAIL: at the spot in both`, `test_child: FAILED
  (4 failed)`; restored. All 31 suites printed `OK (0 failed)` (test_title's two WARNING lines
  come from its own bad-flag check). Smoke runs (title, `-- --demo`, `--map=town`, `--mine=3`,
  the crawler and toddler flags in 3D and the toddler in main_2d.tscn) printed no error or
  warning lines. Screenshots: `--demo --map=house --built=room --flags=married_sayo,spouse=sayo
  --child=crawler --time=18:00 --talk=child` frame 59: the crawler on the mat by Sayo at the
  kotatsu, the text box "Hikari" with a heart and the babble line; `--demo --weather=sunny
  --flags=married_sayo,spouse=sayo --child=toddler --time=10:00 --map=farm@coop` frame 39: the
  toddler in a bun and the indigo happi by the seed stand; `--lang=th --weather=rain
  --child=toddler --time=11:00 --talk=child`: the Thai name tag and the rain line in Thai. A
  sheet of all three builds front / back / crawl checked by eye. shots/ deleted.
- Left / next: step 5 (the child figure's own day plans with the spouse and at festivals, the
  morning help, the record's line). Not done: holding the crawler like the baby (DESIGN's
  table allows it); no portrait for the child in the text box; the toddler's yard loop is fixed
  near the kennel, not following the dog.
## 2026-11-08 — Merge: Shige's band 6 scene and hearts for Nana
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged f54c107 Shige's band 6 scene (Sonnet) and 6d5a3cf hearts for Nana (Sonnet),
  both made in their own worktrees. Conflicts resolved by keeping both: the trigger rows in
  triggers_minamino / triggers_shige_house / triggers_town, the heart music list, the Thai
  dialogue lines, README → Villagers, the ROADMAP prose (Later for hearts: Nana's band 6 scene,
  hearts for Kiku); test_relationships keeps only "Nana has heart events at 3 and 5", since
  Shige now has band 6.
- Checked: on the merged tree after `--import`, all 31 tests/test_*.gd print `OK (0 failed)`;
  the four smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error
  or warning lines.
- Left / next: the child, step 4 (in its own worktree); Nana's band 6 scene; hearts for Kiku.

## 2026-11-08 — Hearts for Nana of Minamino
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: Nana joins `Villagers.friends()` (hearts no longer false), the way Shige did. Birthday
  fall 19 (free of every other birthday and festival; Granny Kiku's persimmon season), with a
  `birthday` day plan: home until 9:00, dressing the jizo on the lane in a new red scarf
  9:00-11:40 (cell 4, 18), lunch at home, the village pond as on other days but till dusk
  (18:00), home by 18:40, bed at 20:30; the farmhouse calendar marks it (a tiny red scarf on the
  19th). Talk: birthday / gift_birthday, close lines from band 4, her forage lines now band 2
  to 5 like the other friends, `stars_` lines after the band 5 scene. `heart_nana` (band 3: her
  tadpole Captain from the ditch behind her father's beds; let him go to the pond or wait for
  legs; two packets of corn seed from her father's tallest row) and `heart_nana_5` (band 5: the
  map of the sky she drew on a seed sack, a blinking star picked for the mother she does not
  remember, and which star should be her father's, the big steady one or the one beside her
  mother's; two cucumbers). Trigger rows in triggers_minamino, triggers_shige_house and
  triggers_town; music rule; her part in the ending (data/events/ending.json,
  dialogue/ending.json: Captain is a frog now). Record steps: Friendships 12 / 25 / 40 / 63 of
  78 -> 13 / 27 / 43 / 68 of 84 (same share, fourteen friends), Neighbours 1 / 2 / 3 -> 1 / 2
  (two without hearts left: Kiku and Dr. Yae; steps must rise, so the record has 41 stars now,
  not 42; the rank steps 9 / 18 / 27 / 36 stay). Thai for every new line and the changed
  calendar key. README (Villagers, Ending) and ROADMAP updated. No band 6 scene (Shige's is
  another agent's task).
- Checked: test_relationships has `_nana_friend` (birthday plan incl. the jizo cell and the
  pond at dusk, close / star / birthday / forage picks, both answers of both scenes, both gifts,
  the calendar, the ending part, not a neighbour) and Nana in the heart rows (3 maps), keepsake
  homes (her clay rabbit stands in her house) and the friend count (14); test_talk moves her to
  the friends' forage days; test_ending counts Nana as a friend and Kiku and Dr. Yae as the
  neighbours. After `--import`, all 31 test scripts print `OK (0 failed)`; smoke runs (title,
  `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error or warning. Screenshot
  (`--demo --map=minamino --time=9:00 --event=heart_nana`, frame 149): Nana's name tag with her
  face over the first line of the scene, the farmer on the track.
- Left / next: Shige's and Nana's band 6 scenes; hearts for Kiku; Captain, the star map and
  the jizo's scarf change nothing in the world yet.
## 2026-11-08 — Shige's band 6 scene and his dear lines
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: `heart_shige_6` (data/events, lines in heart_events_6.json): the pumpkin vines grown from
  his late wife's tin came up by the fence, four pumpkins, and Nana cried over the first one as
  he predicted. A line of its own for the band 5 answer (band 5's choices now set `shige_fence`
  / `shige_share`; the share answer says both patches took), a word on the crows and the
  scarecrow, and the farmer picks what the first pumpkin is for, the pot or the tin
  (`shige_pumpkin` = pot / tin). Sets `heart_shige_6` and `shige_vine`. Rows in
  triggers_minamino, triggers_shige_house and triggers_town; music rule; three `dear_` talk
  lines at band 6 after the scene (the tin full again, Nana's pumpkin lantern, the dusk walk to
  the fence); Thai for every new line. test_relationships: Shige joins the band 5 / 6 loops
  (rows, playing, flags, looks back on the band 5 answer, dear lines) and checks both answers'
  lines. README → Villagers and ROADMAP updated; every villager with hearts has all three
  scenes now.
- Checked: `--import`, then all 31 tests/test_*.gd each print `OK (0 failed)`; smoke runs (title, `--demo`,
  `--demo --map=town`, `--demo --mine=3`) print no error or warning; a `--event=heart_shige_6`
  frame showed the text box with Shige's first line (he was not in view on that map).
- Left / next: hearts for Nana or Kiku; `shige_vine`, `shige_pumpkin` (and the earlier
  `shige_fence` / `shige_share`) are only flags so far, nothing in the world reads them.

## 2026-11-08 — Sayo's child name "Hinata" renamed "Hikari"
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: one of Sayo's three child names, "Hinata", was also the clinic's name (Hinata Clinic).
  It is now "Hikari" (light), a name not used elsewhere: data/child.json, her choice and
  answer in data/dialogue/child.json ("Hikari. Light. Every store needs some by the window."),
  the Thai (ฮิคาริ) in data/lang/th/dialogue.json, test_child, and DESIGN's example list.
- Checked: `test_child: OK (0 failed)`, `test_dialogue: OK (0 failed)`, `test_lang: OK (0
  failed)`, `test_events: OK (0 failed)`; the `-- --demo` smoke run printed no error or
  warning lines.
- Left / next: the child, step 4.

## 2026-11-08 — The child, step 3: the baby in a bamboo cradle, looked in on, held and laid back
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done:
  - `Child.sync_stage` keeps a flag `child_stage` (baby, crawler, toddler, child) in step with
    the day: each morning (`day_start`), at the birth (`event_step`), on loading a save and
    after the `--flags` / `--baby` flags. data/maps/house.json's `room` extension has a
    `cradle` prop at (10, 1) in the second room, gated by `child_stage` = "baby", so it stands
    from the birth until day 30 and only with the second room built.
  - data/child.json `cradle.times`: seven rows by the clock, each a picture (asleep, awake,
    cry) and a line with the name: asleep from 19:30 and through the night, crying for a feed
    from 4:30, wide awake from 6:30, a nap from 10:00, awake and kicking from 13:00, watching
    the lantern from 17:00 (the house's clock stands still indoors, so it is the hour the
    farmer came in). No gendered words; Thai for all of them in data/lang/th/ui.json.
  - Controls (BabyActions, FarmActions, ActionHints): E on the cradle looks in ("Look"); the
    tool button lifts the baby ("Hold") into the hold pose (`Game.baby_held`; the rucksack's
    hand slot stays empty); while held either button facing the cradle lays the baby back
    ("Put back"), anything else says "Your hands are full." (no throw, no setting down, no
    talk, gift or sleep). Door rule (my choice): the door waits with "Lay %s back in the
    cradle first.", as with the dog; as a safety net any map change (events, a collapse) and
    the night lay the baby back too. `baby_held` is not saved, so a game saved while holding
    loads with the baby in the cradle.
  - Art (PlaceholderArt "child:"): `child:cradle:<empty|asleep|awake|cry>:<skin>:<hair>:<top>`,
    a woven bamboo cradle on rockers (20 x 16) with the baby's head over the rim on a white
    pad under an indigo quilt, a fist up when awake, the mouth open when crying; and
    `child:held:<asleep|awake>:...`, a 12 x 12 bundle in indigo with the face in a white wrap,
    carried like an item. Colours from `Child.look` (the spouse's hair, the skin between,
    the happi's indigo) via `Game.child_look`.
  - Views: CradleLayer (3D, a visit layer, a billboard at the figures' pixel size) and
    CradleView (flat) read the cradle prop and `baby_held` every frame, so the cradle shows
    the moment the birth scene ends and empties when the baby is lifted; MapWorld and MapView
    leave the prop out of their own drawing.
  - Debug flags `--baby` (born today, the farmer below the cradle) and `--baby=held`, in
    AGENTS.md; README → Maps describes the prop and the rules.
- Checked: test_child new checks (stage flag by day, birth and morning; the cradle prop only
  with child_stage baby and the room built, solid with free cells in front; the line and the
  picture by the hour incl. 2:00 asleep, 5:00 crying, 8:00 / 15:00 awake, 11:00 a nap, five
  or more different lines, no he / she words, Thai; the four cradle pictures differ, the held
  one 12 x 12 in the child's skin; E's line at 8:00 and at 2:00; hints Look / Hold, Put back
  only at the cradle; the tool button lifts, held_key is the baby; interact and tool facing
  the floor keep the baby, nothing thrown or put down; the futon does nothing; the door keeps
  the farmer inside with the message; E and the tool button lay the baby back; a map change
  and end_day lay the baby back; no lifting with an item in hand; 30 days on a crawler and no
  cradle in either view; saved while holding, loaded with empty arms and the baby in the
  cradle). test_maps `_cradle`: the 3D house builds with no stand-in box, CradleLayer stands
  the picture on (10.5, 1.5) at FIGURE_PX, empty while held. test_view2d `_cradle`: the flat
  house draws it, the tool button lifts into the hold pose, the door waits, E lays back.
  Mutation (the door not waiting in BabyActions): `FAIL: the door rule says why: Your hands
  are full.`, `test_child: FAILED (1 failed)`; restored. All 31 suites printed
  `OK (0 failed)`; after the last art and flag edits test_child, test_hold, test_maps,
  test_view2d, test_save, test_lang and test_events ran again, all `OK (0 failed)`. Smoke
  runs (title, `-- --demo`, `-- --demo --map=house --built=room
  --flags=married_sayo,spouse=sayo --baby=held`) printed no error or warning lines.
  Screenshots (3D, `--demo --map=house --built=room --flags=married_sayo,spouse=sayo,child_name=Sora
  --baby --time=8:00`, frame 39): the cradle by the back wall of the second room, the baby
  awake with a fist up under the indigo quilt, Sayo at the kotatsu, the hints "E Look
  Space Hold". With `--baby=held`: the farmer in the hold pose with the swaddled baby
  overhead, the cradle empty, the hint "E/Space Put back". Flat view (`res://scenes/main_2d.tscn`
  with `--baby --map=house@start`): the cradle with the baby in the second room's corner.
  shots/ deleted.
- Left / next: step 4, crawler and toddler figures. No crying sound; the birth scene itself
  still shows no baby (the cradle appears as it ends).

## 2026-11-08 — The child, step 2: the news and the birth scenes for all eight spouses
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done:
  - `Child.day_start` (from `Game.end_day`, after the wedding check): each morning sets
    `child_news_due` or `child_birth_due` while `news_due` / `birth_due` hold (the spouse's band,
    festival days), else clears them; `Child.event_step` for a new event step
    `{"do": "child", "step": "news" | "birth"}` (EventRunner, `Game.child_event`): the news sets
    `child_news` to the day, the birth `child_born` and keeps the `child_name` the dialogue's
    choice set (a name not the spouse's falls back to their first). `Child.check` asks for both
    events per candidate. README → Events lists the step.
  - `data/events/child_news_<id>.json` and `child_birth_<id>.json` for Sayo, Fumi, Haru, Ichiro,
    Mio, Kaede, Shino and Ren; triggers_house.json plays them on `day_start` (waking in the
    farmhouse) with the due flag and `married_<id>`, once each, after the ending and the yearly
    page. The news: the spouse walks from the second room to the futon and tells it. The birth:
    the spouse in the second room, Dr. Yae and Tome beside them, the farmer walks over; Tome and
    Yae's lines (`birth`), the spouse's two lines and the choice of their three names
    (`<id>_names`, `<id>_pick`), the spouse's answer to the name (`<id>_<name>`), Tome's welcome
    (`born`).
  - `data/dialogue/child.json`: 75 lines in each spouse's voice (Sayo's ledger, Fumi's tea and
    her mother, Haru's straw sandals and few words, Ichiro's short sentences and a cedar cradle,
    Mio's river and father's boat, Kaede's fortunes and fox statues, Shino plain and brief,
    Ren's post); no gendered words for the child (the name, they, the little one). Thai for all
    of them and the 24 names (99 entries in data/lang/th/dialogue.json).
- Checked: test_child new checks: the due flags on the right mornings only (29 / 30 days,
  band 5, festival, after the news, after the birth, single), the event step, the trigger rows
  for every spouse (day_start only, once each, not without the married flag), both scenes per
  spouse with Yae and Tome at the birth, each spouse offering exactly their three names and
  each pick setting child_name and getting its answer, no he / she in the lines, Thai complete,
  `Game.end_day` setting child_news_due on the 30th day, the birth scene played on the real
  Game with the second name picked (Michi). Mutation test (day_start not clearing the news
  flag): `FAIL: band 5 the next morning: not due until the hearts are back`, `FAIL: not on a
  festival morning`, `FAIL: told: nothing due`, `test_child: FAILED (3 failed)`; restored.
  All 31 suites printed `OK (0 failed)`. Smoke runs (title, `-- --demo`, and `--demo
  --map=house --built=room --flags=married_sayo,spouse=sayo --event=child_news_sayo`) printed
  no error or warning lines.
  Screenshot: `--demo --map=house --built=room --flags=married_sayo,spouse=sayo --time=6:30
  --event=child_birth_sayo --dialogue=child@sayo_pick`, frame 129: the farmer before Sayo in
  the second room, Yae and Tome beside them, the text box with Sayo's line and the choice of
  Hinata, Sora and Aoi. (The `--dialogue` box is opened over the scene before its first talk;
  the event itself starts its talks from `birth`.) shots/ deleted.
- Left / next: step 3, the baby in a bamboo cradle in the second room. No baby is drawn in
  the birth scene yet (the cradle comes with step 3); there is no crying sound.

## 2026-11-08 — The child, step 1: data/child.json and Child (pure rules)
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: `data/child.json` (30 days to the news, band 6, 30 days to the birth, stages baby 0 /
  crawler 30 / toddler 60 / child 120, hearts start and floor at band 3, the look's skin mix
  and the indigo happi colours, three gender-neutral names for each of the eight spouses, all
  24 different; ours) and `scripts/villagers/child.gd` (`Child`, pure rules): `news_due`,
  `birth_due`, `tell_news`, `give_birth`, `age`, `stage` / `stage_at`, `look(spouse_look,
  farmer_skin)` (spouse's hair, skin halfway), `names(spouse)`, `start_points`, `min_points`,
  `check`. The save is the marriage flags `child_news`, `child_born`, `child_name` (day numbers
  and the name) and the child's hearts in Affection under id `child`: `Affection.of` starts it
  at band 3 and `Affection.add` keeps it from falling below. No events, art or UI (steps 2-5).
  New `tests/test_child.gd`, listed in AGENTS.md.
- Checked: test_child, test_relationships, test_save, test_events, test_lang, test_villagers,
  test_talk all `OK (0 failed)`; smoke runs (title and `-- --demo`) print no errors.
- Left / next: step 2, the news and birth events with the name chosen from the three.

## 2026-11-08 — The child's rules (design only)
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: docs/DESIGN.md → ความรักและแต่งงาน → ลูก, in Thai. The RE project has not studied
  children (DESIGN lists marriage as not yet studied), so the rules are ours:
  - one child, no gender in the rules or the lines (as for the farmer and spouse);
  - the news comes 30 days after the wedding while the spouse stays at band 6, not on a
    festival day; the birth comes 30 days later at the farmhouse (Dr. Yae and Tome);
  - the name is chosen from three the spouse offers: there is no name entry screen yet, and a
    list works in every language;
  - four stages by days since the birth: baby (a bamboo cradle in the second room, held in the
    house only), crawler, toddler (follows the spouse at home, the dog in the yard), and child
    from 120 days (out with the spouse by day, at festivals, no growing past it);
  - hearts like a villager's, starting at band 3 and never below it;
  - from band 5 the child pulls up to two weeds on dry mornings;
  - a line in the village record;
  - the save in the marriage flags and the affection table;
  - left out on purpose: a second child, choosing a gender, illness, taking the child out
    alone, a teenager;
  - five build steps, one commit each.

  Balance numbers (30 / 30 days, the stage lengths, 2 weeds, band 3 floor) are ours. They go
  in data/child.json in step 1.
- Checked: documentation only, no code or data changed, so the test suites were not run
  again (the last run on 2d74a94: all 30 `OK (0 failed)`). `git status -sb` clean after the
  commit.
- Left / next: step 1, data/child.json and the Child rules with tests.

## 2026-11-08 — Married spouses keep the farmhouse on festival days and birthdays
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: a spouse's own festival and birthday rules came before `married_<id>`, so on those days
  (and Ren on every Sunday) they woke in their old home and walked from there. Now each of the
  eight has married plans, listed first in their rules:
  - `married_festival_day`, `married_festival_night`, `married_festival_year` (Sayo: one per
    festival, as her single plans): at the farmhouse ([9, 3]) from 6:00, into the village by
    the farm road (town [0, 10]) at the time they used to arrive, along it to the same spot
    they stand at for the festival (a lead-in per side they used to come from: along row 10,
    row 11 or down the x 4 lane), back the same way at the festival's end and home a few
    minutes after the walk (rounded up to five), away at the old time or ten minutes after;
  - Sayo keeps the store on festival days as when single, her old house swapped for the
    farmhouse (her married days already come to the store's door);
  - `married_birthday`: the day where each likes to be (Fumi the cherry road after a morning
    at the counter, Haru the hill's lookout then the field, Ichiro the teahouse bench, Mio the
    far east shore, Kaede Minamino's roadside shrine, Shino the river shore, Ren the pond),
    from and back to the farmhouse along their married commute. Sayo's married days already
    held on her birthday;
  - Ren: `married_day_off`, the pond bench on Sundays.

  The plans were written into the villager files by a one-off script from the single plans
  (not kept); the files are the data.
- Checked: test_relationships `_spouse_special_days`:
  - every candidate on each festival, their birthday and (Ren) a Sunday gets a married plan
    that builds;
  - they are at the farmhouse at 6:30 and it is their last map of the day;
  - they never visit their old home (Fumi's home is her teahouse, where she works);
  - single, the old plan still holds.

  test_villagers checks every walk stays off solid cells. Output `test_relationships: OK (0
  failed)`, `test_villagers: OK (0 failed)`. Mutation test (Kaede's married Blossom Day rule
  removed): `FAIL: kaede married on blossom_day: a married plan (festival_day)`, `FAIL: ...
  wakes and ends the day at the farmhouse`, `FAIL: ... never back in kaede_house`,
  `test_relationships: FAILED (3 failed)`; restored. All 30 suites printed `OK (0 failed)`.
  Smoke runs printed no error or warning lines: title, --demo, --map=town, --mine=3,
  --festival=blossom_day --flags=married_mio,spouse=mio, --season=winter --day=4 --map=river
  --flags=married_shino,spouse=shino --time=11:00.
  Screenshot: `--day=8 --map=house --built=room --flags=married_kaede,spouse=kaede
  --time=7:00`: Kaede in the farmhouse on Blossom Day morning. (`--festival=` moves the
  farmer to the village, so the date was set instead.) shots/ deleted.
- Left / next: a child, the last marriage piece, starts with its rules in DESIGN.

## 2026-11-08 — Shino's noren over the farmhouse door and her own
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: her band 6 scene sets `shino_noren` (rows or flowers: "a noren on your door"), but no
  noren was ever hung. Now:
  - a `noren` story prop (StoryView.KINDS; StoryProps in 3D: a picture over the door at the
    prop's `front` and `y`, swaying in the world's Sway; StoryView in the flat view at the top
    of the door cell);
  - PlaceholderArt "story:noren_rows" (white sprouts on furrows across three indigo panels),
    "story:noren_flowers" (five-petal wildflowers, one with a yellow centre) and
    "story:noren_shino" (her dye house's mark, a ring round an indigo leaf), 22 x 10, slits
    between the panels;
  - farm.json: over the farmhouse door (4, 3), by the answer (flag_value rows / flowers),
    y 1.08: at 1.41 (the door's top) the deep thatch eave hid it from the camera;
  - minamino.json: her own new one over the dye house door (1, 13) once shino_noren is set
    either way;
  - the drying rack stays in on Sundays (`rest_weekdays`, her vats rest) and on its `keeper`'s
    birthday (read from data/villagers/shino.json: winter 4, she sits by the river)
    (DyeCloth.resting, out_now passes the weekday and date).
- Checked: test_maps:
  - `_shino_noren`: none before; the farmhouse's by the answer; hers either way; the three
    pictures differ; her door still opens; the 3D one hangs and sways;
  - `_dye_cloth`: in on a Sunday and on winter 4, out on Monday and winter 5.

  Output `test_maps: OK (0 failed)`. Mutation test (the rest days ignored): `FAIL: in on
  Sundays, when her vats rest`, `FAIL: in on her birthday (winter 4), out the day after`,
  `test_maps: FAILED (2 failed)`; restored, `test_maps: OK (0 failed)`. All 30 suites printed
  `OK (0 failed)`, and test_maps again after the farm noren was lowered. Smoke runs printed no
  error or warning lines: title, --demo, --map=town, --mine=3, --demo
  --flags=shino_noren=rows, --map=minamino@shino --day=7 --flags=shino_noren=flowers, main_2d
  --map=minamino@shino.
  Screenshots:
  - `--map=farm@bin --flags=shino_noren=flowers` (3D): the flowers noren over the farmhouse
    door, under the eave once lowered;
  - `--map=minamino@river --time=10:00 --flags=shino_noren=rows`: her mark over the dye house
    door;
  - main_2d `--map=farm@bin --flags=shino_noren=rows`: the rows noren on the flat farmhouse.

  shots/ deleted.
- Left / next: the farmhouse noren is the same in every season. Married spouses still wake in
  their old homes on their birthday and festival days (their own plans win); that is next.

## 2026-11-08 — Mio poles the ferry across
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the old ferry boat now goes out. On her fine mornings Mio takes it across the river and
  back.
  - data/ferry.json (FerryRun, scripts/villagers/ferry_run.gd, pure):
    - the poler (mio) and the map (river);
    - the boat's mooring middle (14.5, 7.5) and its place against the far bank (14.5, 9.55);
    - where she stands (the stern, 0.8 west), the landing's end she steps from, her lift in the
      boat (0.16);
    - the phases: board 2, out 10, wait 6, back 10, off 2 (30 minutes; a slow crossing of a
      narrow river, back by about 10:05);
    - no crossing in winter (the shore ice).
  - DayPlan: a new step `{"ferry": minutes}`; `where` gives `ferrying` / `ferried`.
    Villagers.where passes the place through FerryRun.ride:
    - down the landing into the stern (walking), poling out (facing down) and back (facing up),
      standing at the far bank, stepping off;
    - `lift` while in the boat; `poling` gives a new pose "pole".
  - FigureArt "pole": both hands on a long pole leaning down the figure's front to the water,
    high on it (0), then pushing down with the body dipping a pixel (1), each pole_minutes.
    Front and back.
  - mio.json: in her usual and married plans a 9:30 entry walks to the shore above the landing
    (14, 5), crosses, and goes back to her traps. Wet days, festivals and her birthday have
    their own plans and no crossing.
  - The boat moves:
    - 3D: OutdoorProps.ferry_boat puts its pieces in a BoatRide node moved each frame by
      FerryRun.boat_offset from Mio's place. The painted name (StoryProps) is reparented into
      it, and the spare pole is its own piece, hidden while it is in her hands.
    - Flat view: a new FerryView draws the boat and its name (MapView keeps the landing,
      StoryView skips the name) and moves with the same offset.
    - Villager sprites in both views stand `lift` higher.
- Checked:
  - test_villagers `_ferry_crossing`:
    - the step is read and lasts its minutes; the run is 30 minutes;
    - the phase order; the boat at the mooring, the far bank and back;
    - the boat's ends stay on water cells clear of the rocks all the way;
    - boarding walks into the stern; poling out lifts her, frames 0 / 1; the pole is in use;
    - she waits at the far bank and poles back facing up; she steps off with the boat tied;
    - no crossing in winter; the pole pose's frames differ, front and back;
    - both plans carry `{"ferry":30}`;
    - a sunny spring Monday takes the boat across between 9:30 and 10:20; none in winter; on a
      rainy morning she is not on the river.
  - test_maps `_ferry_boat`: the hull is in the moving piece, the name goes with it, and the flat
    view has the boat.

  Output `test_villagers: OK (0 failed)`, `test_maps: OK (0 failed)`. Mutation test (the boat
  kept at its mooring in "out" and "wait"): `FAIL: the boat leaves its mooring, lies at the far
  bank and comes back`, `FAIL: poling out, standing in the boat ...`, `FAIL: standing at the far
  bank`, `FAIL: on a fine spring morning she takes the boat across ...`, `test_villagers: FAILED
  (4 failed)`; restored, `test_villagers: OK (0 failed)`. All 30 suites printed `OK (0 failed)`.
  test_maps, test_villagers, test_view2d and test_relationships were run again after the
  spare-pole change: all `OK (0 failed)`. Smoke runs printed no error or warning lines: title,
  --demo, --map=town, --mine=3, --map=river@ferry --time=9:30 (and with --season=winter),
  main_2d --map=river@ferry --time=9:30.
  Screenshots:
  - `--map=river@ferry --time=9:38 --weather=sunny`: Mio poling the boat out mid-river.
  - main_2d at 9:47: the boat against the far bank, her in it.
  - `--time=9:55 --flags=mio_boat=father`: poling back from behind, the dragon plaque riding on
    the boat. The first frame showed the spare pole still lying on the seats while she held
    one, so it became its own piece and is hidden then.

  shots/ deleted.
- Left / next: nobody is ferried yet; the far bank has nothing to cross to. The farmer cannot
  ride along. Shino's dye house noren and the rack kept in when she is away are next.

## 2026-11-08 — Shino's indigo drying by her vats
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: Shino's dye house has its drying rack now.
  - minamino.json: a `cloth_rack` prop west of her vats (0..1, 15..17), with `hours`
    7:00-17:00 and three `shades` (5582bc, 2e5698, 1a2f64): the palest on the first pole by
    the vats, the darkest on the last. A bamboo moved from (1, 16) to (1, 19) to make room, and
    the forage spot at (1, 15) to (2, 17).
  - DyeCloth (scripts/world/dye_cloth.gd, pure rules): one pole a row of the rack, its shade,
    out in the rack's hours unless today's look is wet (rain, storm, snow, blizzard), and the
    hem's downwind shear (the 3D Sway's free cloth formula, its STREAM copied, since MapView
    compiles before the autoloads and the 3D scripts name Game; a test keeps them equal).
  - PlaceholderArt "cloth:<hex>" (22 x 24): the fold over the pole catching the light, its
    shadow, soft folds, a darker uneven hem, the selvedges, a few paler streaks.
  - 3D (OutdoorProps.cloth_rack): two bamboo posts and a pole a row, and the lengths as
    two-sided pictures in a DyeCloth.Show (visible by the clock each game minute) hung in the
    world's Sway as free cloth (lift 0), so they stream and flutter with the day's wind.
  - Flat view (DyeClothView, added by main_2d; MapView skips the prop): the posts and poles,
    and while out the lengths cut in six strips shifted downwind by whole pixels, the hem the
    most, redrawn at data/wind.json "flat".rate, lit by FlatLight.
- Checked: test_maps `_dye_cloth`:
  - the rack's place beside the vats, solid cells, Shino's spots and the lane open;
  - out at 7:00 / 10:00 / 16:59, in at 6:59, 17:00, 22:00, and on rain, storm, snow and
    blizzard days;
  - three shades, palest first; the pictures drawn and different;
  - the 3D rack: poles, three lengths shown at 10:00 sunny, each a cloth in the Sway, still in
    calm air and blown downwind at wind 0.5, hidden at 18:00 and on a rainy morning;
  - the flat strips: none in still air, rising to the hem in a gale; the flat view hangs the
    cloth at 10:00 and takes it in at 20:00.

  Output `test_maps: OK (0 failed)`. Mutation test (the wet check turned off): `FAIL: taken in
  on a rain day` (and storm, snow, blizzard, `and on a rainy morning`), `test_maps: FAILED (5
  failed)`; restored. The first full run printed `test_forage: FAILED (1 failed)` (`FAIL: data:
  minamino spot (1, 15) is on a free cell off the lanes`): the spot moved to (2, 17) (not
  (1, 18): `can be reached` failed there, walled in by bamboo), then `test_forage: OK (0
  failed)`. All 30 suites printed `OK (0 failed)`. Smoke runs (title, --demo, --map=town,
  --mine=3, --map=minamino@shino --time=16:58, main_2d --map=minamino@shino) printed no error or
  warning lines. Screenshots: `--map=minamino@shino --time=10:00 --weather=sunny` in 3D (three
  lengths blowing beside the vats; the first shades washed to sky blue in the sun, so they were
  darkened a step); main_2d with `--weather=storm` (taken in); the flat rack rendered alone
  (the HUD covers that corner in game): three lengths stepping from pale to dark, the hems
  leaning downwind. shots/ deleted.
- Left / next: the cloth is out on Sundays and her birthday too, when she is away. Mio poling
  the ferry across is next.

## 2026-11-08 — Mio's ferry boat and landing on the river
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the ferry Mio talks about in her heart scenes is on the river now.
  - river.json: a plank landing (`landing`, 13, 6) out over the water below her hut and the
    old flat-bottomed boat tied beside it (`ferry_boat`, 13..15, 7). Both stand on water cells,
    so the shore path stays open. A new spawn `ferry` (14, 5) looks at them.
  - 3D (OutdoorProps.ferry_boat / landing, lit meshes): a cedar hull sitting low in the water,
    flaring to dark gunwales, a raised narrowing bow at the east end, the dark floor inside,
    two thwarts, the long pole lying along the seats, a little foam round it, snow on a seat
    when snow lies. The landing is boards across two bearers on four posts in the river, with
    a mooring post.
  - Flat view (MapView._draw_river_wood): the same in pixels (hull, floor, seats, pointed
    bow, pole; the planks and the post). Flat colors for both in MapView.COLORS.
  - The name: a `boat_name` story prop gated by mio_boat (her band 6 answer), `style` father
    or new. PlaceholderArt "story:boat_father" is a pale painted plaque with her father's
    coiled red dragon (Tatsu); "story:boat_new" has a blue fish leaping a wave (the new name
    is never said, so it is a mark, not words). It is a picture on the hull's near side by
    the stern in 3D (StoryProps) and on the boat in the flat view (StoryView).
- Checked: test_maps `_ferry_boat`:
  - the boat (3 x 1) and the landing are in place, on water;
  - the shore cells stay open;
  - the spawn exists;
  - no name without mio_boat, the right name for father / new;
  - the two pictures are drawn and differ;
  - the 3D river builds the hull.

  Output `test_maps: OK (0 failed)`. Mutation test (the father name's flag removed): `FAIL: no
  name before Mio has named the boat`, `FAIL: her father's name or the new one, by her
  answer`, `test_maps: FAILED (3 failed)`; restored. All 30 suites printed `OK (0 failed)`.
  Smoke runs (title, --demo, --map=town, --mine=3, --map=river@ferry --flags=mio_boat=new,
  main_2d --map=river@ferry --flags=mio_boat=father) printed no error or warning lines.
  Screenshots: `--map=river@mio --time=9:00` (the boat and landing in 3D; with
  `--season=winter --snow=80` in the snow), main_2d with mio_boat=new (the flat boat with the
  fish mark). The first 3D name sat low by the boat's middle, mostly hidden and under the HUD
  from her door. It moved up to the gunwale by the stern, a little bigger. Then
  `--map=river@ferry --flags=mio_boat=father` / `=new`: the plaque reads on the stern side.
  shots/ deleted.
- Left / next: the boat stays tied; nobody poles it across yet. Shino's drying cloth is next.

## 2026-11-08 — Ren's mailbag and the delivery at each door
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: Ren used to stand two minutes at each door doing nothing. Now:
  - a villager's look can have `bag` (a color): FigureArt._bag draws a canvas shoulder bag,
    the strap from the near shoulder across the body to the bag at the far hip, a flap and a
    buckle, mirrored from the back. Ren's is `b89a68`. It is drawn on every pose, so both
    views have it;
  - a new day plan step `{"post": minutes}` (DayPlan.STEP_KEYS; legs carry `post`, `where`
    gives `posting` / `posted`; talking to him stops it like work and fishing);
  - a new villager pose "post" (Villagers.pose, sprite key `villager:<id>:<side>:post:<frame>`):
    the near hand up at the door with a pale letter (frame 0) for post_hold_minutes (1, in
    data/villagers/_common.json), then pushed in so only its end shows (frame 1);
  - the switch to frame 1 plays a new sound, letter_post (data/sfx.json: a soft paper rustle
    and a light tap, -18 dB), in the 3D view (VillagerSprites) and the flat view
    (VillagerView), on the map the farmer is on, like the hammer's knock;
  - ren.json: every stop at a door on his round (usual and married plans, 30 in all) is a
    post step instead of a wait. The waits at the counter and the pond stay.
- Checked: test_villagers `_post_step`:
  - the step is read, posting half a minute in, done after two;
  - the two frames by the minute;
  - a post of 0 minutes is refused;
  - the bag changes his picture;
  - the post frames differ from each other and from idle, front and back;
  - at least 13 post stops on his round;
  - at 8:35 on a Monday he is posting at Tome's door, facing it;
  - letter_post is in data/sfx.json.

  Output `test_villagers: OK (0 failed)`, `test_audio: OK (0 failed)` (52 sounds), then all 30
  suites printed `OK (0 failed)`. Mutation test (post_frame always 0): `FAIL: the letter held
  up, then slipped in (villager:ren:back:post:0, villager:ren:back:post:0)`,
  `test_villagers: FAILED (1 failed)`; restored. Smoke runs (title, --demo, --map=town,
  --mine=3, main_2d --demo --map=town --time=8:35) printed no error or warning lines. Looked at:
  a sheet of his poses (idle, walk, post 0 / 1, front and back). The first try put the bag
  too far into the middle of his chest, so it moved out to the hip. Then
  `--map=town@post --time=8:35` in the 3D view and in main_2d: Ren at Tome's door from behind,
  the satchel at his hip and the letter raised to the door. shots/ deleted.
- Left / next: the sound is heard anywhere on the map (as the hammer's is), not by distance.
  Mio's boat at the ferry landing is next.

## 2026-11-08 — Portrait hair styles: the candidates read apart
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the text box portrait (PlaceholderArt._portrait) drew its hair from the figure's
  hair_style, and the women's figures only use `bun` and `long`. So Sayo, Haru, Mio and Kaede
  had the same long-hair face, and Shino, Fumi, Tome, Kiku and Yae the same bun. Shino's read
  like a man's topknot. Now:
  - four portrait-only styles in PlaceholderArt.PORTRAIT_HAIR: hime (a blunt level fringe,
    straight locks cut at the chin, a ribbon over the crown), ponytail (tied high, the tail
    swinging out to the right, a side-swept fringe), braid (a middle parting, one braid over
    the left shoulder tied with a cord) and low_knot (parted in the middle, swept down over
    the ears to the jaw, a knot at the nape with a hairpin through it);
  - a speaker's face in data/dialogue/speakers.json can name one as `portrait_hair`
    (PlaceholderArt.portrait_hair_style), and the figures don't change. Haru has a braid (she
    weaves straw), Mio a ponytail, Kaede a hime cut (a shrine keeper's look) and Shino a low
    knot. Sayo keeps her long hair and Fumi her bun;
  - the hair behind the head is drawn in one place (_portrait_hair_behind: long, hime, the
    ponytail, the low knot);
  - the bun now has soft side wings over the ears instead of two thin strips, so the old women,
    Fumi and Yae read softer.
- Checked: test_dialogue:
  - every speaker's portrait_hair is a known style;
  - every style draws different hair;
  - the six women who can marry each have their own style;
  - Shino a low knot, Sayo long.

  Output `test_dialogue: OK (0 failed)`. Mutation test (Shino's portrait_hair removed):
  `FAIL: the women who can marry each wear their own portrait hair { "long": "sayo", "bun":
  "shino", ... }`, `test_dialogue: FAILED (2 failed)`; restored. Then all 30 suites printed
  `OK (0 failed)`. Smoke runs (title, --demo, --map=town, --mine=3) printed no error or
  warning lines. Looked at: a sheet of twelve portraits rendered from PlaceholderArt (scratch
  file, not kept): Haru, Mio, Kaede and Shino now each have their own outline, and Shino's hair
  falls to her jaw. Also `--map=minamino@shino --time=9:00 --talk=shino` (her portrait in the
  text box). shots/ deleted.
- Left / next: Nana's portrait still uses the plain short hair (she is a child; her figure is
  short-haired too). Real portrait art would replace these keys.

## 2026-11-08 — Ren the mail carrier, the last of the eight candidates
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: a new villager with hearts, our own: Ren carries the post. He talks a lot and knows
  who writes to whom, never what. A new little post office stands in the village's north-west
  corner by the farm road (a 3 x 3 village_house with timber walls at 0, 7, door 1, 9 onto the
  road; spawn `post`), the only free ground by the village's entry. Inside:
  data/maps/post_office.json (one room split by a long counter, pigeonholes and his chest
  behind it, a lamp and parcel sacks in front; door hours 6:00-21:00). data/villagers/ren.json:
  - sorting behind the counter 7:00-8:30;
  - the village round from 8:30 (Tome, Kota's family, the store, Sayo's side door, the smithy,
    the clinic);
  - Sakurazaka 9:45 (the teahouse, Ichiro), back through the village, Kaminoda 11:00 (Genzo,
    Haru);
  - lunch at the post office 12:05;
  - down the south lane at 13:00: the river 13:30 (Mio's hut) and Minamino's houses 13:55
    (Shino, Shige and Nana, Kaede, Kiku);
  - the counter again 15:20-17:30, bed 21:00.

  He has no wet-day plan (the post goes out in any weather). Sundays and his birthday (spring
  15) he reads by the village pond 9:00-15:00. Festivals in the village (blossom 7, 12; night
  26, 12; the year's 14, 6); after the night festivals he goes straight to bed, because the
  village doors' hours are checked and the post office shuts at 21:00. Look: a green happi and
  short hair; the portrait wears a green postal cap. Gifts: grilled fish, rice balls and green
  tea for the road and a daruma loved (kept on his chest once given). Sweet potato, chestnuts,
  amazake, chestnut rice, potatoes and amber liked. The herb tonic, shaved ice, dobin mushi
  (too fancy to eat walking) and clay disliked, a stone hated. talk_ren.json has every pick a
  friend needs plus counter and Sunday lines, round lines after band 5, dear after band 6, and
  gift and dish answers. Heart scenes:
  - band 3: whose letters weigh the most (Tome's, to her son in the city; Sayo sends the
    most), and seed potatoes Genzo had too many of;
  - band 5: head office wants a van twice a week instead of the round on foot: keep walking
    (ren_walk) or drive it himself (ren_van);
  - band 6: the round stays on foot after a letter signed by every house, or the van is his
    and he walks the last stretch to every door. Then his first letter, to the farmer, read now
    or kept sealed (ren_letter), and the farm becomes his first stop (ren_route).

  His heart rows are in every map his round reaches (town, post_office, sakurazaka, kaminoda,
  minamino, river). Calendar (spring 15), ending page, whistle, heart music. Marriage on the
  others' pattern: married he leaves the farmhouse at 6:45 and walks the same round, home by
  17:45. The wedding has Genzo, Fumi and Mio (people from his round) on his side. 95 new Thai
  lines (Ren ผม / เธอ) and 3 names. The ending's Friendships steps went from 11 / 23 / 37 / 58
  of 72 to 12 / 25 / 40 / 63 of 78 (thirteen villagers with hearts). test_maps' village mesh
  cache count is 6 houses now. All eight planned candidates are in.
- Checked: all 30 suites printed `OK (0 failed)` (test_animals .. test_weather, among them
  `test_relationships: OK (0 failed)`, `test_villagers: OK (0 failed)`,
  `test_talk: OK (0 failed)`, `test_lang: OK (0 failed)`, `test_maps: OK (0 failed)`,
  `test_ending: OK (0 failed)`, `test_festivals: OK (0 failed)`, `test_audio: OK (0 failed)`).
  Failures fixed on the way:
  - the night festivals ending at home after the door's hours;
  - a long chest poking into the wall (now parcel sacks);
  - the village's house count in test_maps;
  - no `birthday` plan (one plan for Sundays and the birthday was not enough);
  - his band 6 branch one line too early for the look-back check (a line added);
  - a type the test script couldn't infer.

  Mutation test (his married rule removed): `FAIL: married, Ren leaves the farmhouse for the
  post office and walks his round through every part, home by 17:45`,
  `test_relationships: FAILED (1 failed)`; restored. Smoke runs (title, --demo, --map=town,
  --mine=3, --map=town@post --time=8:40, --map=post_office --time=7:30, --map=sakurazaka
  --time=10:00) printed no error or warning lines. Screenshots:
  - `--map=town@post --time=8:35`: Ren setting out on the round; the post office turns
    see-through in front of the farmer;
  - `--map=post_office --time=7:30`: sorting behind the counter;
  - `--map=sakurazaka --time=10:00`: he is at the teahouse, off this frame;
  - `--map=town@post --time=8:31 --talk=ren`: his new-face line and capped portrait.

  shots/ deleted.
- Left / next: the marriage roster is complete. He has no mailbag in his hand or delivery
  animation (he stops at each door for two minutes). His birthday and festival plans win over
  the married ones, as for the others.

## 2026-11-08 — Shino the indigo dyer, the third new candidate
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: a new villager with hearts, our own: Shino dyes indigo. She came back from the city,
  where she studied textiles, to keep her family's dye house going. The house stands west of
  Minamino's lane down to the river (a village_house with timber walls at 0, 11, door 1, 13,
  two indigo vats in front at 2, 15 and 3, 15). To make room, the cherry moved from 2, 11 to
  3, 18 and the forage spot at 2, 13 moved to 5, 13. A water_tub prop can now have its own
  water `color`, in 3D (RoomProps._water_tub) and the flat view (MapView), for the indigo vats.
  Inside: data/maps/shino_house.json (a tatami room at the back with a chest, a pattern table
  and a lamp, an earth workroom with two vats, the stove and a water jar; door hours
  6:00-21:00). data/villagers/shino.json: the vats 6:30-11:30, lunch at home, rinsing cloth on
  the river's west shore 12:45-14:00 (2, 5, clear of the Sunday fishers and Mio), the vats again
  14:10-17:30, bed 21:00. On Sundays the vats rest and she picks wildflowers east of the lane
  9:00-15:00, so the river's Sunday checks still hold. Wet days at the vats inside. Festivals
  in the village (blossom 13, 12; the night ones 16, 12; the year's 19, 6: the first tries at
  9, 13 and 21, 6 were solid). Birthday winter 4, by the river all day. Look: indigo kimono, a
  bun, a gold hairpin in the portrait. Gifts: mulberries, akebi, warabi mochi, wild greens
  tempura and a painted paper fan loved (kept by her table once given). Mugwort, eggplant,
  teas, rice balls, chestnut rice and agate liked. Marble soda, milk pudding (the city's sweets)
  and iron sand (it dulls a vat) disliked, a stone hated. talk_shino.json has every pick a friend
  needs (vats mornings, rinsing at the river, pattern lines after band 5, dear after band 6,
  gift and dish answers). Heart scenes: band 3 the cloth turning blue in the air, which blue
  (one dip or twenty), eggplant seed from Kiku's garden. Band 5 her mother's 200 stencils: dye
  them (shino_mother) or cut her own (shino_own). Band 6 the year's first bolt sold out (her
  mother's cranes, or her wildflower stencil), a noren for the farmhouse door, the field's rows
  or her flowers (shino_noren), and the first cloth of every new vat promised (shino_first).
  Triggers in town, Minamino, the river and her house. Calendar (winter 4), ending page,
  whistle, heart music. Marriage on the others' pattern: married plans from the farmhouse
  kotatsu, the vats by day with lunch at the dye house, sewing by the kotatsu on wet days. The
  wedding at the shrine has Kiku, Kaede and Sayo on her side and Kota and Hachiro on the
  farmer's. 97 new Thai lines (Shino ฉัน / เธอ) and 3 names. The ending's Friendships steps
  went from 10 / 21 / 34 / 53 of 66 to 11 / 23 / 37 / 58 of 72 (twelve villagers with hearts).
- Checked: all 30 suites printed `OK (0 failed)`, among them
  `test_relationships: OK (0 failed)`, `test_villagers: OK (0 failed)`,
  `test_talk: OK (0 failed)`, `test_lang: OK (0 failed)`, `test_maps: OK (0 failed)`,
  `test_forage: OK (0 failed)`, `test_ending: OK (0 failed)` and `test_festivals: OK (0 failed)`.
  test_audio was rerun after its fix: `test_audio: OK (0 failed)`. Failures fixed on the way:
  `shino loves a dish and dislikes one (0, 1)`, two festival spots and walks through solid
  cells, `shino's whistle lasts 4.64 s` (now 11 notes at 92 bpm). The line generator also
  stopped half way over a "Grey" (STYLE_EN wants Gray); data/ was reset and it was rerun.
  Mutation test (her married rule removed): `FAIL: married, Shino works her vats in Minamino
  by day, lunch at the dye house, home to the farmhouse by 16:45`,
  `test_relationships: FAILED (1 failed)`; restored. Smoke runs (title, --demo, --map=town,
  --mine=3, --map=minamino@shino, --map=shino_house, --map=river --time=13:00) printed no
  error or warning lines. Screenshots: `--map=minamino@shino --time=9:00` (the dye house, Shino
  at the indigo vats), `--map=river --time=13:00` (rinsing on the west shore),
  `--map=shino_house --time=18:30` (the room and the two vats inside),
  `--map=minamino@shino --time=9:00 --talk=shino` (her new-face line and portrait).
  shots/ deleted.
- Left / next: Ren (the post office by the village's entry). Every woman's portrait is the
  same bun face (only the colors change), so Shino's reads a bit like the others; separate
  portrait hair styles would be new art. No cloth hangs to dry by the vats yet (that would be
  a new prop). Her birthday and festival plans win over the married ones, as for the others.

## 2026-11-08 — Kaede of the shrine, the second new candidate
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: a new villager with hearts, our own: Kaede keeps the village shrine, and Tome is
  teaching her the rites her grandfather (the last keeper) never wrote down. Where she lives:
  the village had no free 4 x 3 near the shrine (the ground north of the road is festival
  stalls and villagers' festival spots), so the shrine keepers' house stands in Minamino's
  east (a village_house at 22, 4, door 23, 6; nothing walked or foraged there) and she walks
  up each morning, bowing at Minamino's roadside shrine on the way. Inside:
  data/maps/kaede_house.json (tatami, family altar, alcove, low table for folding charms; door
  hours 6:00-21:00). data/villagers/kaede.json: sweeps the gravel before the hall 7:00-11:30,
  lunch on the step, folds charms by the hall 12:30-16:00, home 16:55, bed 21:00; wet days
  charms at home; festivals by the hall (20, 4) for their hours; birthday fall 4 (the first
  leaves on the shrine path; the 3rd was first, but the calendar check reads "4th"-style days)
  at Minamino's roadside shrine all day. Each walk between Minamino and the shrine has about 30
  minutes (15 was refused: the plan can't get there before the next entry). Look: white top,
  red lower, long black hair, a bun portrait. Gifts: dango, amazake, kinako mochi and an
  omamori from elsewhere loved (kept in her alcove once given), quartz liked, herb tonic, fish
  stewed with daikon and clay disliked, a stone hated. talk_kaede.json with every pick a friend
  needs (shrine mornings, rite lines after band 5, dear after band 6, gift and dish answers).
  Heart scenes: band 3 the shrine's white fox (a little, or only in daylight) and turnip seed
  from the offering box; band 5 she must lead the New Year rite alone: words written in her
  sleeve (kaede_sleeve) or said to the farmer now (kaede_recite); band 6 she led it (in her
  head to the farmer, or never looking at her sleeve) and the new fortune box's first draw,
  for the farmer or together (kaede_draw), the first fortune of every year promised
  (kaede_fortune). Triggers in town, Minamino and her house. Calendar, ending page, whistle,
  heart music. Marriage on the others' pattern; the wedding is at her own shrine with Tome
  leading the rite she taught her (Nana, Shige and Mio on her side). 96 new Thai lines and 3
  names. The ending's Friendships steps went 9 / 19 / 31 / 48 of 60 -> 10 / 21 / 34 / 53 of
  66 (eleven villagers with hearts). test_villagers' 10:00 and 14:20 village checks name her.
- Checked: all 30 suites `OK (0 failed)` (test_farm .. test_puddles, among them
  `test_relationships: OK (0 failed)`, `test_villagers: OK (0 failed)`, `test_talk: OK (0 failed)`,
  `test_lang: OK (0 failed)`, `test_festivals: OK (0 failed)`), then `test_ending: OK (0 failed)`
  again after the steps changed. Failures fixed on the way: four lines without their Thai in
  the generator (it stopped half way; data/ reset and rerun), walks too short, the 3rd as a
  birthday, no disliked dish, the two village lists. Mutation (her married rule removed):
  `FAIL: married, Kaede keeps the shrine by day, home to the farmhouse by 16:30`,
  `test_relationships: FAILED (1 failed)`; restored. Smoke runs (title, --demo, --map=town,
  --mine=3, --map=minamino@kaede, --map=kaede_house) printed no error or warning lines.
  Screenshots: `--map=town@shrine --time=9:00` (Kaede sweeping by the hall),
  `--map=minamino@kaede --time=17:30` (her house), `--map=kaede_house --time=18:00` (the room,
  her by the altar), `--map=town --time=14:00 --talk=kaede` (her portrait). shots/ deleted.
- Left / next: Shino (the indigo dyer). Her birthday and festival plans win over the married
  ones, as for the others.

## 2026-11-08 — Mio of the river, the first new candidate
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: a new villager with hearts, our own: Mio keeps the fish traps and the old ferry on
  the river south of the village. Her driftwood hut stands on the river's north bank (a
  village_house prop, yakisugi walls, at 12, 1, door 13, 3, a water tub beside it; the pine
  that stood there is gone) and has an inside of its own (data/maps/mio_hut.json: plank floor,
  low table, lamp, chest, tub and stove; door hours 6:00-21:00). data/villagers/mio.json: works
  her traps east of the path with the fishing pose 6:40-11:30 (16..18, 5, clear of Hachiro's
  and Kota's Sunday spots), lunch at the hut, up through Minamino to the store's front
  13:30-14:30 (she sells her catch to Sayo), mends nets by the path 15:05-18:00, bed at 21:00;
  wet days nets by the stove; festivals on the south road for their hours; birthday spring 12
  (snowmelt; no traps, the far east of the shore all day). Look: long hair, indigo work happi
  (a woman's look in sprite and portrait; the first try with a headband and short portrait hair
  read as a man, so it changed). Gifts: river fish and fish dishes, rice balls, amber (it washes
  up in rivers), the moon lantern above all (kept in her hut once given); dainty sweets and
  matcha disliked, a stone hated. talk_mio.json with every pick a friend needs (festivals,
  birthday, traps mornings, close, ferry after band 5, dear after band 6, gift and dish
  answers). Heart scenes: band 3 where the fish lie (fast water or the pool) and a daikon from
  behind the hut (events give crops or seeds only, so not a fish); band 5 the village wants the
  ferry landing gone: keep it (mio_keep, a bell for anyone who needs the slow way) or let it go
  (mio_let); band 6 the bell rang for a peddler, or she poled across once more for herself, the
  boat named (mio_boat: father / new), the morning's first crossing kept for the farmer
  (mio_ferry). triggers_river.json, triggers_mio_hut.json and rows in triggers_town.json. The
  calendar names her on spring 12, the ending has her page, her whistle tune, her heart scenes
  take the heart music. Then the marriage parts on the others' pattern (knot answers, proposal,
  wedding: Hachiro, Kota and Shige on her side, Sayo and Fumi on the farmer's; married plans
  from the farmhouse kotatsu, a wet day mending nets there; engaged / chore / married lines;
  Tome's hint). 97 new Thai lines and 3 names. The ending's Friendships steps went 8 / 17 / 28
  / 43 of 54 -> 9 / 19 / 31 / 48 of 60, the same share with ten villagers with hearts.
  test_villagers' Sunday river check now leaves Mio out of "who else is at the river" and
  checks she keeps a cell clear of Hachiro and Kota; the 14:20 village check names her at the
  store's front.
- Checked: 30 suites `OK (0 failed)` (test_farm .. test_puddles), among them `test_relationships: OK (0 failed)`, `test_villagers: OK (0 failed)`, `test_talk: OK (0 failed)`, `test_lang: OK (0 failed)`, `test_ending: OK (0 failed)`, `test_festivals: OK (0 failed)`, `test_maps: OK (0 failed)`. First run failures fixed on the way: a band 5 choice too long for the box (it broke every heart_events_5 scene), an event giving a dish (events give crops), a hair style only the farmer has, the hut's home cell under the table, river routes through the hut's wall, no mine find or keepsake liked, no dish answers, and test_villagers' empty-river and 14:20 checks. Mutation (her married rule removed): `FAIL: married, Mio works the river and sells at the store by day, home to the farmhouse at 18:00`, `test_relationships: FAILED (1 failed)`; restored. Smoke runs (title, --demo, --map=town, --mine=3, --map=river@mio, --map=mio_hut) printed no error or warning lines. Screenshots: `--map=river@mio --time=9:00` the hut on the north bank with its tub; `--map=mio_hut --time=7:00` the room; `--map=river@mio --time=15:30 --talk=mio` Mio by the path with her new-face line and portrait. shots/ deleted.
- Left / next: Kaede (keeps the village shrine). The river has no boat to see yet (the ferry is
  told, not shown; a boat prop would be new 3D and flat art). Mio's birthday and festival plans
  win over her married ones, as for the others.

## 2026-11-08 — Ichiro can be married
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: Ichiro joins data/marriage.json candidates (sayo, fumi, haru, ichiro), the first man
  among them, open to any farmer. His band 6 scene was already in; this adds the rest on Fumi's
  and Haru's pattern: marriage.json lines ichiro_married / _taken / _waiting / _band / _room,
  ichiro_yes (his father said a burner marries the kiln) and ichiro_wedding (Tome on his father
  never staying for tea, his promise of the kiln's first piece each winter, Fumi teasing that
  he gives speeches now); propose_ichiro.json and wedding_ichiro.json (Kota and Hachiro on the
  farmer's side, Fumi, Sayo and Haru on his); the wedding row in triggers_town.json; Tome's
  Friday hint for heart_ichiro_6. ichiro.json: married rules before the wet one; "married" is
  his usual day with the farmhouse kotatsu [9, 3] in place of his house (6:00-6:30 and from
  17:00, away at 20:00 as before); "married_wet" walks over to split wood in his old entry
  7:00-17:00 (his single wet day is that work, so he keeps it). talk_ichiro.json: engaged_,
  help_, wed_morning_ / wed_evening_ / wed_out_ picks after the festivals, before the wet one;
  dear lines only while single. Lines keep his short sentences (STYLE_EN, Voice). 32 new Thai
  lines (Ichiro ผม / เธอ, the farmer เรา / เธอ).
- Checked: test_relationships extended (Ichiro in candidates, his wedding row and guests, band 6
  rows on town and sakurazaka, married plan at 6:10 / 9:00 / 12:20 / 18:00 / 21:00, wet day in
  his old entry, single morning at his house, Tome's hint, dear lines only single; the
  per-candidate loops cover his answers, lines, chores and events). Output:
  `test_relationships: OK (0 failed)`, `test_talk: OK (0 failed)`, `test_lang: OK (0 failed)`,
  `test_events: OK (0 failed)`, `test_dialogue: OK (0 failed)`, `test_villagers: OK (0 failed)`,
  `test_ending: OK (0 failed)`, `test_save: OK (0 failed)`, `test_festivals: OK (0 failed)`.
  Mutation (his married_wet rule removed): `FAIL: a wet day Ichiro splits wood in his old entry,
  from the farmhouse`, `test_relationships: FAILED (1 failed)`; restored. Smoke runs (title,
  --demo) printed no error or warning lines. Screenshots: `--event=wedding_ichiro` frame 150
  (Tome's first line, Ichiro beside the farmer, Fumi, Sayo and Haru on the right) and
  `--map=house --built=room --flags=married_ichiro,spouse=ichiro --time=18:30` (Ichiro in the
  second room). shots/ deleted.
- Left / next: Mio, the first new candidate (a ferry hut on the river map, sprite, day plans,
  talk, heart scenes, then marriage). As with the others, his birthday and festival plans win
  over the married ones.

## 2026-11-08 — The flat view takes the world's light on its sprites
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: art direction section 3. `FlatLight` (scripts/world/flat_light.gd) brings the 3D sprites'
  light to the flat view by SpriteLight's own rules: the sun's share by the clock
  (SpriteLight.sun_tint of Game.sun_light; plain at noon, at night, indoors, down the mine, under
  cloud) and at night the warm lift (SpriteLight.spots_of from the map's NightView windows,
  lanterns and festival lights, SpriteLight.lift_at at the picture's middle, as high as the 3D
  sprite's: FarmWorld.FIGURE_PX / PX / AnimalLayer.ANIMAL_PX). Each picture is drawn with the
  modulate sun x (1 + warm x lift / tint), which under the CanvasModulate night tint is the 3D
  view's own x sun x tint + own x sun x warm x lift; only the picture's own pixels change, whole
  pixels, no blur. main_2d sets the light each game minute (and on a new map / day) and redraws
  the views in FlatLight.GROUP when it changed; the farmer (figure self_modulate, the carried item
  via Player.light), the villagers (self_modulate, the held item too, not the note puff) and a
  thrown item take it each frame. AnimalView (animals, dog, eggs), FarmView (crops, the tall
  crops' plants, items on the field), MapView (the paddies' plants, CropPatches.draw's new
  `light` callable at CropPatches.light_mid), ForageView and StoryView draw with it. The ground,
  fences, roofs, doors, map boxes, the marks and the mine lantern stay as drawn. One flat-only
  number, data/light.json sprites.lift.flat_floor 0.05 (the least the tint is divided by, as
  NightView's shader). No Occluders in the flat view, so no building stops a light (as its pools).
  The 3D view is untouched. FlatLight loads the 3D scripts lazily, so views compile before the
  autoloads in tests.
- Checked: test_view2d `_sprite_light` (the modulate's sum under the tint, the middle's height, the
  farmer golden at 6:30 and 17:30 and plain at noon and indoors, the field's and animals' views in
  the group, a plant's middle, the village's spots = SpriteLight.spots_of, the farmer by a lit
  window lifted by exactly lift_at, none in the dark, each villager by its own spot with the note
  puff unlit, no lift by day). test_view2d, test_weather, test_maps, test_farm, test_animals,
  test_villagers, test_forage, test_festivals, test_drift, test_mine OK; smoke runs of main_2d
  (`--demo`, `--map=town --time=21:00`, `--mine=3`) and main with `--demo` print no errors.
  Flat-view frames at 6:30, 12:00, 17:30 on the farm and 21:00 at town@sayo looked at: farmer
  mean RGB 94/74/50 at 6:30 against 103/96/76 at noon (grass 100/140/54 against 107/168/71, so
  the sprites are a little warmer than the ground, as in 3D); by the store's lit window at night
  the farmer reads warm (92/67/75) over the night-blue ground. Shots deleted.
- Left / next: festival decorations in the flat view stay as drawn (they are the lights).

## 2026-11-08 — Puddles in rain
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: art direction section 2. In rain and storm, puddles gather on the outdoor maps' path and gravel cells (free of solid ground and props) and on the farm's doorsteps (the farm has no dirt paths of its own), in both views. One pure rule script (`PuddleRules`, scripts/puddle_rules.gd; numbers in data/puddles.json): wetness from today's look, yesterday's look, the clock and the snow lying (grows to the look's max over the first game hour from 06:00; a rainy day's wetness dries out linearly over two hours the next morning; none with any snow lying, in snow looks, indoors or in the mine), the places (a hash of the cell and the map id; each puddle has its own start wetness, so a storm fills more than rain, and its own size kept inside its cell) and the rain rings (the water's dimple style, density x 2.5). `Game.weather_yesterday` is new (set at the day's end, not saved: a loaded save starts dry). 3D: `PuddleLayer` (one MultiMesh of flat lit quads at y 0.02; the shader draws the wobbly ellipse, rim, sky reflection and rings; the instances are rewritten only when the wetness moves a step of 1/50); built beside the DriftLayer on the farm world and every outdoor MapWorld. Flat: `PuddleView` (pixel ellipses, the same colours; rings redrawn 8 times a second only while it rains), added under the footprints in main_2d.
- Checked: test_puddles (new, in AGENTS.md's list): gating per look / snow / indoors / mine, growth and drying values, placement (only free path / gravel, inside the cell, none on grass or water, doorsteps on the farm), counts rising with wetness, rings, both views building and following the rules (06:00 none, 06:30 some, 07:30 more, dry the morning after, snow). The other tests and smoke runs: see the final report. Screenshots (3D town in rain, 3D farm in a storm, flat town in a storm): the puddles read as dark blue-grey pools with rings on the paths; deleted.
- Left / next: the farm has almost nothing to puddle on (only the doorsteps); real dirt paths there would show more. Colours and sizes are balance numbers in data/puddles.json.

## 2026-11-08 — Candidates: half villagers already here, half new
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the user wants half the eight candidates to be existing villagers and half new. The
  roster in docs/DESIGN.md (ความรักและแต่งงาน) is now Sayo, Fumi, Haru, Ichiro (existing; 3
  women, 1 man) and Mio, Kaede, Shino, Ren (new; 3 women, 1 man), still six women and two men.
  Yae is out (no hearts, birthday or scenes yet, so the most work of the existing ones) and
  Shino comes in: an indigo dyer, back from the city to her family's dye house, a new house by
  Minamino's lane down to the river (the map has no creek, so not "by a creek"). ROADMAP: the
  Yae task dropped, a Shino task added.
- Checked: docs only, no code or data changed. Not run: tests (nothing they read changed).
- Left / next: Ichiro as a candidate.

## 2026-11-08 — Haru can be married
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: Haru joins data/marriage.json candidates (sayo, fumi, haru), open to any farmer. Her
  band 6 scene was already in (99bf478), so this adds the rest on Fumi's pattern:
  marriage.json lines haru_married / _taken / _waiting / _band / _room, haru_yes and
  haru_wedding (Tome on Haru's grandmother weaving her own wedding sandals, Genzo asking who
  ties his sheaves); data/events/propose_haru.json and wedding_haru.json (guests Kota and
  Hachiro on the farmer's side, Genzo, Sayo and Fumi on hers); the wedding row in
  triggers_town.json; Tome's Friday knot hint for heart_haru_6. haru.json: married rules before
  the wet one; "married" wakes at the farmhouse kotatsu [9, 3], walks in from Kaminoda's south
  edge at 7:40 to the rack, keeps her day (her old house at lunch, the hill lookout 13:50-16:00),
  leaves by the south edge at 18:00, home 18:30; "married_wet" weaves by the kotatsu all day.
  Why the wet day at home: her single wet day is weaving at home too, and the farmhouse is home
  now. talk_haru.json: engaged_, help_water_ / help_feed_ (mornings), wed_morning_ /
  wed_evening_ / wed_out_ picks after the festivals (before the hill's), dear lines only while
  single. 32 new Thai lines (Haru ฉัน / เธอ, Tome ยาย / หลาน, the farmer เรา). No gendered
  word for the farmer (STYLE_EN).
- Checked: test_relationships extended (Haru in candidates, her wedding row and guests, band 6
  rows on town / kaminoda / hill / haru_house, married plan at 7:00 / 9:00 / 15:00 / 19:00 /
  22:00, wet day at home, single morning at her house, Tome's hint, dear lines only single; the
  per-candidate loops now cover her lines, answers, chores and events). Output:
  `test_relationships: OK (0 failed)`, `test_talk: OK (0 failed)`, `test_lang: OK (0 failed)`,
  `test_events: OK (0 failed)`, `test_dialogue: OK (0 failed)`, `test_villagers: OK (0 failed)`,
  `test_ending: OK (0 failed)`, `test_save: OK (0 failed)`. Mutation (her married rule removed):
  `FAIL: married, Haru goes up to Kaminoda and the hill by day and comes home to the farmhouse`,
  `test_relationships: FAILED (1 failed)`; restored. Smoke runs (title, --demo, married at the
  house at 19:00) printed no error or warning lines. Screenshots: `--event=wedding_haru` frame
  150 shows Tome's first line, Haru beside the farmer, Genzo, Sayo and Fumi on the right;
  `--map=house --built=room --flags=married_haru,spouse=haru --time=19:00` shows Haru in the
  second room. shots/ deleted.
- Left / next: Ichiro as a candidate (his band 6 scene is in). Like Sayo and Fumi, on her
  birthday and festival days Haru's own plans win over the married ones, so she wakes in her
  old house then.

## 2026-11-08 — Bush leaf detail (CropArt)
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: `scripts/art/crop_art.gd` `_bush` (potato, eggplant: look "bush") draws its leaf mass at growth 2 and 3 as separate leaves (`_foliage`, `_fan_leaf`): 5 leaves young, 7 grown, fanned from separate feet, each leaf lit on its upper-left side with a shade midrib (the vein) and a shaded underside under them, so the gaps between leaves read dark. Still three tones, the deep rim, no outline; same keys, size, anchor; flowers and ripe produce unchanged; other looks untouched. Produce-only drawing unchanged (no leaves).
- Checked: test_farm `_crop_art` now counts tone-edge pixels (pixels with a different opaque neighbour) of the bushes' young and grown pictures: before the change 62 and 119, after 78 and 135; both must be above the old counts. A first try with five broad leaves merged into one mass (107 grown), so the leaves were split into narrower ones. Enlarged sprite sheet looked at. Demo screenshot (`--demo`, frame 19) looked at; shots/ deleted.
- Left / next: real hand art for the crop keys.

## 2026-11-08 — Field crops refined (CropArt)
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: `scripts/art/crop_art.gd` (CropArt, palettes in `data/crop_art.json`) draws the single-sprite crops (looks root, bush, ground: turnip, onion, carrot, daikon, potato, eggplant, pumpkin) at growth 2 and 3 and every crop's seed and sprout (growth 0 and 1) part by part: shaded balls and leaves in three tones lit from the upper left, a shaded soil mound, a deep leaf-shade rim (mixed a little with the produce's colour when ripe) instead of the black outline. Ripe produce is distinct per crop; flowers on the grown potato, eggplant and pumpkin. `PlaceholderArt._crop` calls it; the tall crops' (vine, stalk, grain) grown looks keep the old drawing (the clusters' `stalk:` plants replace them). Same keys, 16 x 16 size and anchor; the withered, watered and snow handling is by key and tint, untouched. A refined placeholder, not the real hand art.
- Checked: test_farm `_crop_art` (every crop and growth keeps the old size, no black outline pixels on the CropArt pictures, young / grown / ripe differ, ripe crops differ, produce lit upper left over lower right); the full test list; a contact sheet old vs new, `--demo` frames in 3D (spring, fall, summer) and the flat view looked at.
- Left / next: real hand art for the crop keys; the bush leaf mass could use more leaf detail.

## 2026-11-08 — Seasonal drifting life outdoors
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: art direction sections 2 and 3. Spring cherry petals, fall maple / persimmon leaves and
  summer-night fireflies, outdoors only, in both views. One pure rule script (`DriftRules`,
  scripts/drift_rules.gd; numbers and colours in data/drift.json) gives what shows now (season,
  weather look, clock window with a fade, wraps midnight for fireflies; none on indoor or sheltered
  maps), how many (the data's `count` scaled by the look's share: rain thins petals / leaves, a
  storm or snow stops them, fireflies need clear air) and where each mote is at a time `t`, as a
  pure function (falling motes start near the map's own cherry / maple / persimmon props and the
  festival's cherries, else anywhere, and are carried along `wind_dir` at `drift` + `drift_wind` x
  data/wind.json's strength; fireflies keep to a home spot over water or grass, wander and blink).
  3D: `DriftLayer` (a child of the farm world and of every outdoor MapWorld; one unshaded
  billboard MultiMesh, tinted with the field) and `DriftGlow` in the tint's layer, which draws the
  fireflies as added pixels over the night tint (so they glow instead of being dimmed). Flat:
  `DriftView` (whole pixels; fireflies added with their colour divided by the night tint, as
  NightView does). Not in occlude or MeshCache.
- Checked: test_drift (new, in AGENTS.md's list): gating per season / look / hour / map (house and
  mine empty), counts within the data, wind carrying motes along its direction (gale vs calm, and
  over time), falling, heights, fireflies over both water and grass and blinking, scenes (trees,
  pond), both views building and showing by the rules. All tests of AGENTS.md's list and smoke
  runs: see the final report. Screenshots (3D spring at the bridge, fall, summer night by the farm
  pond, flat view spring and summer night): the effect reads but stays small; deleted.
- Left / next: nothing open; counts and sizes are balance numbers in data/drift.json.

## 2026-11-08 — The farmer's look chosen on a new game
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: ROADMAP "The farmer's look chosen on a new game". New game on the title screen now opens
  a look step (paper box in UiStyle): "Your farmer", rows Hair / Hair color / Skin / Clothes /
  Begin, "<" value ">" per row, and a wood-framed preview of the figure at 3x walking and
  turning to its four sides (front, back, both mirrored; 0.18 s a step, 2.4 s a side). Up /
  down pick a row, left / right turn it (wrapping), Enter on a part goes to the next row and on
  Begin starts, Esc / pause goes back to the menu with nothing started; keys, pad (the title's
  input now takes joypad events too, the menu's as well) and mouse. Begin: Game.new_game(), then
  the chosen look. Looks only: no rule reads it, no gendered word or build (every look is the
  adult body plan).
  Data: data/farmer_looks.json, four lists (style 6, hair 5, skin 5, clothes 5); the first of
  each is the old look (FigureArt.FARMER_LOOK), so the default draws as before. A clothes set
  holds the noragi, collar band, monpe, head cloth and jika-tabi colours together; the straw hat
  style brings its own straw colour (the accent). Colours chosen by eye against the field.
  Code: FarmerLooks (scripts/art: data, normalize, parse, stepped, figure_look, the debug flag,
  `current` + signature), LookMenu (scripts/ui, a MenuList), the title screen's look step.
  Game.farmer_look (setter keeps FarmerLooks.current in step) is reset by new_game, saved as
  `look` {style, hair, skin, clothes}; a save without it loads the default, a broken one ("Saved
  look is broken") is refused, an id the data no longer has falls back part by part (looks
  only, so the save still loads). PlaceholderArt draws "player:..." from FarmerLooks.current
  and caches it under `key@<signature>` for any look but the default (keys and cache of the
  default unchanged); tex() and image() both. Both views and the mochi screen get it through
  those keys. Thai for the step's words and every choice's name (data/lang/th/ui.json; "Begin",
  not "Start", which the table keeps as the pad button's name). Flags: `--look=style:2,hair:1,
  skin:3,clothes:4` (places or ids), `--new-game` (the look step at once); AGENTS.md, README → Run.
- Checked: test_title (new `_looks` and `_look_screen`): the data (4+ choices, unique ids,
  names, valid colours, styles FigureArt knows), the default's look equals FARMER_LOOK, md5 of
  four default frames equal the hashes taken before the change, every pose / frame / side of the
  default equal to FARMER_LOOK's, every choice of every part a different picture, the cache
  apart per look and back to the same texture on the default, normalize / parse / from_flag /
  stepped, LookMenu turning and wrapping; the screen: New game opens the step and hides the menu,
  the preview equals FigureArt's picture and follows a change, InputEventAction ui_right /
  ui_down / ui_left / ui_accept / ui_cancel, Esc changes nothing, Begin gives the new game the
  chosen look, a fresh run and the clock going, and the farmer's picture in that look; the game
  keeps, saves and resets the look. test_save: round trip, four broken looks refused, an old save
  without a look loads the default (the farmer's picture the old one), a gone id falls back.
  test_lang: the look step fits the pseudo language with every choice shown. Mutation: cache_key
  returning the bare key gave `FAIL: a look's pictures carry its signature, other art doesn't`,
  `FAIL: another look: its own picture`, `FAIL: the field's farmer is drawn in the chosen look`,
  `test_title: FAILED (3 failed)`; restored. Screenshots: the look step (English, Thai) and a
  `--demo --look=...` frame in the 3D and the flat view, read and deleted.
- Note: in test_lang the look step is checked before the pause screen: built after the pause
  screen had been opened and freed, the title screen left 136 objects and 39 textures leaked
  at exit (test still OK); not looked into further.
- Left / next: the farmer's text box portrait (data/dialogue speakers "farmer" face) does not
  follow the look yet.

## 2026-11-08 — The figures' night lift keeps to their own pixels
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the open problem of "The field's night lift keeps to its own pixels" for the figures.
  The depth-less "Warmth" pass (WARM_SHADER, drawing each lifted figure's whole quad back from
  the copy plus its own texel x warm x lift) is removed. The figures (FIGURES: farmer, villagers,
  animals, the dog; with the lit sprites they hold, not the marks over them) now take the lift
  in a new layer "FigureLift" right after "Field", with the same FIELD_SHADER and reading the
  same FieldCopy (no new copy): own texel x warm x lift added only where the copy shows that
  texel as the 3D view draws it (under the tint, modulate and sun share, `field_off`).
  `NightLights.figure_lifts(figs, spots, rules, occ)` gives {sprite, at, mid, k} per figure each
  frame (lift_at at SpriteLight.middle, the item rect's middle, which equals the old feet + half
  the picture), and `field_quads` makes the quads (frame = the sprite's current texture, flip_h
  reverses the uvs, pixel_size and offset through sprite_corners, so AnimalArt.SCALE counts).
  Same amount, falloff, lit side, buildings-between and cap. The lift's copy is shown while a
  field quad or a figure quad is lit. Workaround removed: a figure whose middle is behind a solid
  building is no longer skipped for the lift (the building's pixels are not the figure's, so it
  is lifted only where it shows); the skip stays for the draw-back. A lifted figure not behind a
  building is now added to the Figures draw-back (pass 4), so the glows and washes added after
  the copy stay off it as the old pass did (the copy holds its lift now).
  Figure-specific value, in data: data/light.json sprites.lift.bloom 0.024, one-sided (the copy
  may be up to match + bloom brighter than the texel, never more than match darker; FIELD_SHADER
  `bloom` uniform, 0 on the field's material, so the field is unchanged). Why: measured with a
  debug shader writing each figure pixel's best `off`, the unoccluded farmer by Tome's lit window
  (`--demo --map=town@tome --time=21:00`) had 58 of 878 pixels over 0.024 (by Genzo's door 29 of
  883), all brighter and warmer than the texel (mean +0.008/+0.005/+0.004, at most
  +0.041/+0.025/+0.025: the 3D view's glow round the window), which would have left them
  unlifted specks; with bloom 0.024 all 878 and 883 are under 0.02.
- Checked: test_weather `_figure_pass`: the farmer and a cow (pixel size PX / AnimalArt.SCALE) by
  the window take lift_at at their middle (= the old middle), the far one none, none by day, a
  box between a lantern and the figure keeps it off; one quad for the figure and its held item
  carrying (1, 1, 1, lift), the unlit mark left out; the quad follows flip_h and a new frame; the
  cow's quad is half the width of one at PX; bloom data sane; every one of the farmer's 358
  texels under the tint matches (also in a golden sun share, and with the measured glow added,
  the latter only with bloom); a pixel darker than the texel never matches; share of the lift
  that would land on an occluder in front (weighted by the texel's brightest channel): plaster
  e8e0cc 0.09, dark board 3a2c24 0.143, fence culm a89c5c 0.0, the cow's colours 0.113 (dark
  colours come close under the night tint; checked at most 0.2); no Warmth child, Figures last,
  FigureLift after Field and before Pools with its own material (field's bloom 0), off while
  nothing is lit. test_maps: the scene's NightLights order; at 21:00 the farmer put in front of a
  farmhouse window gets one FigureLift quad (1, 1, 1, k > 0.01), the copy and layer on, and is
  drawn back by _plan_warmth alone; at noon nothing lifted and the copy off.
  Mutations: figure_lifts measuring at the feet and field_off without bloom: `FAIL: figure pass:
  the farmer and the cow by the window take the lift at their middle, the far one none ([0.277,
  0.172])`, `FAIL: figure pass: the figure's own texels under the tint match, with a lit window's
  glow on them too (only with bloom) (358, 0 of 358)`, `test_weather: FAILED (2 failed)`; lifted
  figures not added to the draw-back: `FAIL: night lights: the farmer by a lit window takes the
  lift in pass 0 and is drawn back (1 quads)`, `test_maps: FAILED (1 failed)` (before the test
  called _plan_warmth alone this mutation passed, as the farmer is shielded anyway); restored.
  Then `test_weather: OK (0 failed)`, `test_maps: OK (0 failed)`, `test_villagers: OK (0
  failed)`, `test_animals: OK (0 failed)`, `test_view2d: OK (0 failed)`, `test_farm: OK (0
  failed)`, `test_festivals: OK (0 failed)`. Smoke runs (title, --demo, --demo --map=town, --demo
  --mine=3, --demo --map=town --time=20:00): 0 error / warning lines; the Movie Maker runs print
  none either. Pixels against the build before (HEAD NightLights swapped in, 480x270, frame 29,
  HUD forecast icon left out): `--demo --map=town --time=20:00` 0 px changed (the farmer by the
  lantern looks as before: warm face and shirt); `--demo --map=town@tome --time=21:00` 81 px, 67
  by 1 level, 14 by more, all one row under the farmer's feet where the picture shows the ground
  through (the old pass lifted it orange); `--demo --festival=lantern_night` 1137 px by > 1, 1124
  of them darker: a figure seen through a faded see-through roof at the bottom and the stall
  keeper behind the faded awning (debug: there the copy is +0.025 red / -0.040 blue off her
  texels, the awning's colours blended in), so they take less lift where seen through.
  Screenshot `--demo --map=town --time=20:00` looked at: the farmer by the stone lantern, warm,
  crisp; shots/ deleted.
- Left / next: a figure seen through a building faded see-through takes no lift there (as the
  field's objects); dark figure colours behind a dark occluder still pass the colour test (the
  measured shares above). The draw-back of a lifted figure still covers its whole quad (it only
  restores the copy there, so an occluder in front loses the glows added after the copy). Not
  measured: frame cost (one more layer on the same copy; the copy itself is now also on while
  only a figure is lit, a full-screen copy a frame at night by a light). Not seen in a
  screenshot: a figure partly behind a fence by a light (only the GDScript twin is tested).

## 2026-11-08 — Painted roofs in the flat view
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: the flat view's roofs are painted. New `scripts/art/roof_art.gd` (RoofArt) makes PlaceholderArt `roof:<material>:<shape>:<storeys>:<w>:<h>` pictures from above: kawara (tile rolls with a lit crown and dark trough, tile ends, capped ridge, dark eave lip with round tile ends on the south / east eaves), thatch (coop) and kaya (farmhouse, with moss flecks) as strands with lapped courses, a thick ridge and a cut edge. `hip` shows four slopes with capped hips, `storeys: 2` a pent roof with the main roof standing in 5 px and casting a shadow. North and west slopes are lit, south and east shaded (light from the upper left). MapView draws each village house's roof from its data (`roof`, `storeys` via LitSpots.village_style) at the old box's size (footprint minus 1 px a side); FarmView draws the house, coop and barn as one roof each (FarmView.ROOFS: kaya, thatch, kawara; roof_rect) with the doors over them. Collisions untouched (drawing only). Snow lying already whitened roofs through SnowLayer.roof_mask_image over the props; that is unchanged and still lies over the new roofs. SmokeView is a later child, so its puffs draw over them.
- Checked: test_view2d `_roofs`: every material x shape x storeys picture is the box's size, has at least 6 colours and covers its whole box; hip differs from gable, two storeys from one, thatch from kawara, kaya from thatch; the north slope is brighter than the south; the farm's roof rects are the old footprints. Output: `test_view2d: OK (0 failed)`, `test_maps: OK (0 failed)`, `test_weather: OK (0 failed)`, `test_farm: OK (0 failed)`. Smoke runs (main_2d, --quit-after 300): `-- --demo --map=town`, `-- --demo`, `-- --demo --season=winter --snow=80 --map=town`: 0 error lines each. Screenshots (frame 19, 480 x 270): the town shows grey-blue tile roofs, one hip with visible diagonals, rolls reading as stripes; the farm shows the farmhouse and coop in straw tones and the barn in grey-blue tile, doors in front; winter at 18:00 shows the snow overlay breaking up the roofs. shots/ deleted.
- Left / next: at the screenshots' size the pixel detail is small; I did not zoom in on it. Hearth smoke was not seen in a frame (none showed at that size) and was only checked in code: it is a later child of the view. The two-storey pent roof is covered by the generic pictures and the test but I did not screenshot a `storeys: 2` house (minamino, sakurazaka). The winter frame's snow looked pink at 18:00; I did not look into it (not touched by this change).

## 2026-11-08 — Calm paddy ground in the 3D view
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: the 3D view's ground under the Kaminoda paddies where rice is drawn is the flat view's calm
  ground: `paddy_mud` in winter (drained, the water patches lie on it) and `paddy_flood` in the other
  seasons, instead of the painted "paddy" tile with its tufts. One rule for both views, not a copy:
  MapView.paddy_cells_in (the paddy cells with no prop that grow rice, moved out of paddy_cells as a
  static) and MapView.ground_key_at (the ground key, CropPatches.paddy_ground for those cells; the
  flat view's ground_key_in now calls it). MapWorld.ground_keys(m, season) gives every cell's key as
  the 3D picture draws it; ground_picture uses it and its cache key takes the season and the props.
  _plant_paddies uses paddy_cells_in too, so the rice and the water patches sit on the same cells.
  A paddy tile with no rice (a prop on it) keeps the painted tile. Nothing else in the 3D view changed.
- Checked: test_maps `_paddy_ground_3d` (after `_paddy_winter`): rice cells in every season; a sample
  rice cell is `ground:paddy_mud:N` in winter and `ground:paddy_flood:N` in summer; every rice cell
  has its season's ground; the 3D key equals MapView.ground_key_in for every cell in all four seasons
  (MapView's season set as a field, the view is not in the tree); painted tiles kept. Output:
  `test_maps: OK (0 failed)`, `test_view2d: OK (0 failed)`, `test_farm: OK (0 failed)`. Mutation (3D
  picks no paddies): `FAIL: paddy ground 3d: a rice cell is paddy_mud in winter (ground:paddy:1) and
  paddy_flood in summer (ground:paddy:1)`, `FAIL: ... every rice cell has its season's calm ground (512
  off)`, `FAIL: ... the 3D and flat views pick the same ground key for every cell (512 differ)`,
  `test_maps: FAILED (3 failed)`; restored. Smoke `-- --demo --map=kaminoda --season=winter` and
  `--season=summer` (--quit-after 300): exit 0, no error or warning lines. Screenshot
  (`--map=kaminoda@well --season=winter --time=12:00`, frame 19): the village by the farmhouse, the
  paddies' stubble at the left edge behind the fence, drained brown-grey ground under it; too small to
  judge the mud's detail. shots/ deleted.
- Left / next: `--map=kaminoda` alone opened the farm in the screenshot (the spawn form `kaminoda@well`
  is what shows the village); the smoke runs with the plain `--map=kaminoda` form printed no errors but
  did not show the village. Summer's flood ground was not screenshotted. No windowed close look at the
  paddies. The 3D picture is built per map and season (a season change rebuilds it on the next visit).

## 2026-11-08 — Marriage for everyone: the roster and the rule
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the user wants six women and two men the farmer can marry, open to everyone. Written
  down, no code yet: docs/DESIGN.md gets a "ความรักและแต่งงาน" section (any candidate marries
  the farmer whatever the farmer's look, no orientation per candidate, no text split by the
  farmer's gender; the farmer's look chosen on a new game, looks only). The roster: Sayo, Fumi
  (done), Haru, Yae, Ichiro (existing villagers) and three new ones of our own, Mio (river
  ferry and fish traps), Kaede (keeps the village shrine) and Ren (the mail carrier). Why
  existing villagers first: their houses, maps and sprites are already there. Not candidates:
  Hachiro, Shige (a father), Genzo, Tome, Kiku (old), Kota, Nana (children). STYLE_EN gets the
  rule: no he / she, bride / groom, husband / wife, boy / girl for the farmer or the spouse.
  README → Marriage: "beside the bride" became "beside the one they marry". ROADMAP lists one
  task per candidate plus the look choice.
- Checked: grepped data/dialogue, data/events and data/*.json for gendered words: the only hit
  aimed near the farmer, Hachiro's "boy" at the Sayo wedding, answers Kota, so it stays.
  `test_lang: OK (0 failed)`, `test_relationships: OK (0 failed)`; the title smoke run
  (--quit-after 300) printed no error or warning lines.
- Left / next: Haru as a candidate (a band 6 scene, knot answers, proposal, wedding, married
  rules and lines, Thai). The 6:2 split leaves fewer men; more can be added to candidates later.
## 2026-11-07 — Painted paddy ground in the flat view
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: the flat view's calm paddy ground (CropPatches.paddy_ground, MapView.ground_key_in) is now
  painted in the same pixel style as the other ground tiles, not a flat fill. `paddy_mud` (winter,
  drained): dark mud with grain, pale wet-sheen streaks with a dark line under each, two puddles
  (blue-grey pool, darker lower edge, a light glint) and short straw bits. `paddy_flood` (spring to
  fall, still water): a soft sky reflection as two pale bands (the middle lighter than the ends),
  three small ripple lines (a pale stroke over a dark one) and a few specks. Every feature is drawn
  with the new `PlaceholderArt._wrap`, which wraps past the tile's edges, so the tiles repeat
  without a seam. The palette stays in PlaceholderArt, as the other ground tiles' does (the ground
  colours were never in data; data/paddy.json keeps the patch colours). The 3D view's painted
  paddy tile is unchanged.
- Checked: test_view2d `_paddy_tiles` (after `_paddy_ground`): each variant of both tiles has at
  least four colours; the wrap column and row are no harsher than the tile's worst inside
  neighbouring column or row (mean colour difference); the mud carries no water or stubble colour
  of data/paddy.json. Output: `test_view2d: OK (0 failed)`. test_maps: `test_maps: OK (0 failed)`.
  Smoke: `res://scenes/main_2d.tscn -- --demo --map=kaminoda --season=winter` and `--season=summer`
  (--quit-after 300) ran with no error lines. Screenshots (`--write-movie`, frame 19, zoomed 4x on
  the paddies): the winter mud reads as wet mud with puddles and straw under the stubble; in
  summer the water shows between the tall rice as small blue bits (the rice covers most of it).
  shots/ deleted.
- Left / next: the seam check is a heuristic (a mean over one column or row against the tile's
  own neighbours), not a pixel-exact tiling test. The flood tile's sky reflection shows only
  between rice in the flat view, so it was not judged alone at full size. Not run: a mutation
  test of the seam check.
## 2026-11-07 — Glint on the 3D winter water patches
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: the 3D view's winter paddy patches (CropClusters.plant_water, picture patch:paddy_water) glint as the flat view's do. WATER_SHADER now lights one or two texels on the picture's second row (columns 3..8 of 12, the paler oval) in data/paddy.json's water.shine, drifting sideways by whole texels: phase `t * speed * (1 + faster * wind) + place * TAU` with t kept to `rate` frames a second, wind = the rice's (set_wind now feeds the water material), place = fract of the patch's x and z (so patches are out of step and half have two lights). None while `cover` > 0. All on the GPU from the instance's own place, so no per-frame CPU work and no new instance data. Numbers in a new data/wind.json "3d".glint block (same values as "flat": 4, 0.9, 1.0, 2.0). CropClusters.glint_columns is the same sum in GDScript for the tests.
- Checked: test_maps `_paddy_glint`: numbers from data, the material carries them and water.shine, the shader holds the cover gate and second-row rule, two patches not in step, one or two lights (both seen) inside the oval, more column changes in a storm than a sunny day, a light takes 3+ places in 30 s, none under snow. Output: `test_maps: OK (0 failed)`, `test_weather: OK (0 failed)`, `test_view2d: OK (0 failed)`. Mutation 1 (snow gate removed): `FAIL: 3d glint: none with snow lying` then `test_maps: FAILED (1 failed)`; mutation 2 (phase ignored): `FAIL: 3d glint: two patches are not in step (120 of 120 frames in the same column)` then `test_maps: FAILED (1 failed)`; both restored. Smoke runs (title, --demo, --demo --map=town, --demo --mine=3, --demo --map=kaminoda --season=winter) printed no error or warning lines. Screenshot (--demo --map=kaminoda --season=winter, frame 19): water patches are far at the paddies at the screen's corner; a handful of e4eef0-like pixels were found there but a single glint texel could not be told apart from the stubble by eye. shots/ deleted.
- Left / next: the shader's output cannot be read headless, so the tests check the GDScript copy and the shader's source and parameters, not the rendered pixels; a windowed close look at a patch would confirm it. Float precision of `place` on the GPU may differ from the GDScript copy on rare patches.
## 2026-11-08 — The field's night lift keeps to its own pixels
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the open problem of "The field takes the night lift". The lift of the field (crop
  sprites, CropClusters plants, items, objects; SpriteLight.field_lifts, unchanged, once a game
  minute) moved out of the Warmth pass into a pass of its own, NightLights pass 0: a
  BackBufferCopy "FieldCopy" of the tinted picture right after the tint (before the pools), then
  the "Field" layer, then the pools (now a child "Pools"), then the old copy, washes, glows,
  figures, warmth. FIELD_SHADER adds own texel x warm colour x shade x lift (the same amount as
  before) only on the pixels inside the picture's outline where the copy shows that texel as
  the 3D view draws it under the tint (the plants' shade and sun in linear light, a sprite's
  modulate on its colour; also the texel half a texel either way, for texel edges), within
  data/light.json sprites.lift.match 0.024 (why: a few 8-bit steps and the faint bloom of the
  night picture, below the gap between two leaf greens under the tint, 0.033). So whatever stands
  in front (another plant, the fence, a figure, rain) keeps its own pixels. `NightLights.field_off`
  is the shader test in GDScript, `field_quads` the pass's quads ({pts, uvs, tex, color = shade,
  shade, shade, lift}). Sway and parting: CropClusters' shader swayed on TIME, which GDScript
  cannot read, so it now sways on a `clock` uniform that CropClusters advances each frame
  (process mode always, as TIME ran while paused) and sets on every picture;
  `CropClusters.tip_shift` is the vertex shader's sway, parting and lean in GDScript (the
  pushers are kept by set_pushers), and `NightLights.field_corners` moves a lit plant's two top
  corners by it. Figures out of the light are no longer drawn back over lifted field objects
  (nothing to cover now). The copy is shown only while some field quad is lit (a full-screen
  copy a frame at night near lit field objects). Why not the lift in the plants' own shaders:
  measured first, the 3D pass writes alpha 1 whatever ALPHA says (so no mask can ride on it),
  and a lift before the tint would clip at 1 and pass the glow's 0.9 threshold.
- Checked: test_weather `_field_pass`: each field lift is the window's energy x (1 - d/range)²
  capped; one quad per lit sprite and plant carrying (shade, shade, shade, lift); the clock is on
  every picture, advanced by _process, and the shader has no TIME; a lit plant's quad's top
  corners equal plant_corners plus tip_shift and change with the clock, the root kept; calm air
  sways only along the view's right, at most SWAY at its size, a stiff 0 none; feet behind the
  root push the tip away and down, and the drawn quad moves (> 0.5 px); field_off: a plant's and
  a sprite's own texel under the tint match (with a faint bloom too), a fence's culm colour and a
  paler leaf do not, the sun's share counted; the pass order FieldCopy < Field < Pools < copy,
  shader reads the screen and adds, copy off while nothing is lit. test_maps: the scene's
  NightLights in that order; the farm's CropClusters clock > 0 and on every picture at frame 3.
  Mutations: field_corners without the shift: `FAIL: field pass: a lit plant's quad sways with
  the plant, its root kept ((-0.020644, 0.0, 0.0))`, `FAIL: field pass: the drawn quad stands
  where the parted plant is (0.0 px)`, `test_weather: FAILED (2 failed)`; field_off returning 0
  and lift_at with (1 - d/range) unsquared: `FAIL: field pass: each lift is the window's energy x
  (1 - d / range)², capped (5 lifts)`, `FAIL: field pass: a fence or a paler leaf standing in
  front keeps its own pixel`, `FAIL: field pass: the sun's share is counted in what the view
  drew`, `test_weather: FAILED (3 failed)` (the old field checks did not catch the falloff
  change); the clock not advanced: `FAIL: the 3D view's tall crops sway on their clock, every
  picture told (1)`, `test_maps: FAILED (1 failed)`; all restored. Then `test_weather: OK (0
  failed)`, `test_maps: OK (0 failed)`, `test_farm: OK (0 failed)`, `test_view2d: OK (0
  failed)`, `test_festivals: OK (0 failed)`. Smoke runs (title, --demo, --demo --map=town,
  --demo --mine=3, --demo --season=summer --time=21:00): no error or warning lines.
  Pixels (480x270, last frame of 30, Game rng seed fixed for the comparison only, reverted;
  "off" = this build with lift max 0): measured against the build before, `--demo --time=21:00`:
  every pixel the new pass lifts (2553 with the farmer's own lift) equals the old frame within 1
  level (237 by 1, 0 by more); `--demo --map=town --time=20:00`: 0 px changed. A debug run
  painting matched pixels green and refused ones magenta: `--demo --time=21:00` 1418 matched
  (the 1418 px the old entry measured), 0 refused; `--demo --season=summer --time=21:00` 2790
  matched, 118 refused, all where an unlit corn stalk or a nearer lit one stands in front (the
  pixels the old overlay painted over); in a storm (`--weather=storm --no-flashes`) 2794 / 187
  with the quad following the sway, 2414 / 779 with the shift taken out. The summer frame looked
  at side by side: the same warm corn and sprouts by the house. Other frames differ from the old
  build only by the tall crops' sway phase (the clock starts with the view, not with the engine).
  shots/ deleted.
- Left / next: not measured on a slow machine (one more full-screen copy a frame while field
  objects by a light are on screen). During a lightning flash the copy does not match, so the
  field lift drops for those frames. A field object seen through a see-through faded building
  no longer takes the lift there. The figures still use the depth-less Warmth pass (a figure
  behind a plant takes its lift over the plant's pixels, as before).

## 2026-11-07 — Glint on the winter water patches
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: the flat view's winter water patches (CropPatches.draw_water, the Kaminoda paddies) glint.
  Each shown patch carries one or two pale pixels (data/paddy.json water.shine, e4eef0) on its top
  row, inside the paler oval. CropPatches.glint_dots puts them at whole pixels from the patch's own
  rectangle (water_rect, now shared with draw_water_spot; mirrored patches mirror the glint). The
  drift is the rice's wind: the phase advances at data/wind.json "flat".glint.speed (0.9 rad/s)
  times (1 + faster x wind), so a storm (wind 1.0, faster 1.0) runs it twice as quick as a sunny
  day, and the light moves `swing` (2 px) either side of the middle. Phase by place (a hash of the
  patch's x and z), so patches are not in step; one or two lights by the same hash. Redrawn 4 times
  a second (CropPatches.glint_now, MapView._glint_for: only in winter, redraw only when the frame
  changes). Still air keeps a slow shimmer. None while snow lies on the ground (cover > 0).
- Checked: test_view2d `_water_glint` (after `_paddy_ground`, rain and storm winds from
  data/wind.json): a patch's light takes at least 3 places in 30 s; two patches of the same size
  and facing are not in step (at most half the frames in the same column of their own patch);
  one or two pixels a patch (both seen); whole pixels inside their patch; more changes in a storm
  than under a calm sky; none with cover 1.0 or 0.4 or with no glint; the colour is data's
  water.shine. Output: `test_view2d: OK (0 failed)`. Mutation 1 (snow gate removed from
  glint_dots): `FAIL: flat glint: none under snow, none with no glint (288)` then
  `test_view2d: FAILED (1 failed)`, restored. Mutation 2 (phase ignored, `+ 0.0 * h * TAU`):
  `FAIL: flat glint: two patches are not in step (120 of 120 frames in the same column)` then
  `test_view2d: FAILED (1 failed)`, restored. Smoke: `res://scenes/main_2d.tscn -- --demo
  --map=kaminoda --season=winter` (--quit-after 300) and `--demo --map=town` ran with no errors. Screenshot
  (480 x 270, shots/frame00000019.png, Kaminoda winter, zoomed 8x): one pale pixel sits on several
  patches; subtle at 1x. shots/ deleted.
- Left / next: the glint is one pixel, no blink (only the drift; a blink would need a second
  rate). The 3D view's picture patch:paddy_water has no glint. Not timed on a slow machine.

## 2026-11-07 — Ambient loops made ahead, no hitch at first play
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: Sfx no longer synthesizes an ambient loop on the frame it first plays. New `Sfx.loop_stream(key)`
  (same pattern as `song_stream`): the loop is made on a WorkerThreadPool task and returns null until
  ready; `_ready` starts a job for every loop in AmbientPicker.loops when sound is on, and `_process`
  starts a loop only once `loop_stream` has it (a loop not ready is simply started a few frames later).
  Movie Maker runs make it at once; silent (headless / movie without --movie-audio) runs start nothing.
  `stream(key)` keeps its synchronous cache (now over the new `make_sound(key)`, same synthesis, same
  key seed), so one-shots and tests are unchanged. The music already had this (song_stream).
- Checked: measured on the main thread, one loop's synthesis cost: amb_rain 92, amb_wind 99, amb_cicadas
  196, amb_crickets 191, amb_river 293, amb_pond 242 ms (the old first-play stall; the crickets' 191 ms
  matches the 216..355 ms frame). New: the first `loop_stream` call costs 65 us on the main thread.
  Not measured: a full windowed frame-time run with sound on (no audio-on timing run was made).
  test_audio gained `_loop_checks`: first call null and job started, nothing cached by the caller, all
  loops cached after the worker, a ready key costs < 2 ms, and every worker loop's data / loop mode /
  loop end equals the plain SfxSynth synthesis. Mutation (loop_stream returns stream(key)): 3 FAIL lines,
  `test_audio: FAILED (3 failed)`; restored. test_audio and test_weather OK; smoke runs (title, --demo,
  --demo --map=town, --demo --mine=3) no error or warning lines.
- Left / next: the one-shots (play) are still made on first use but are short (not measured as hitches).

## 2026-11-07 — Stone lanterns wash the walls
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: a lit stone lantern (FarmWorld.lamps) standing in front of a house wall now puts a soft
  warm wash on it at night, in the same passes as the windows' (pale plaster in "Washes", earthen
  plaster and charred boards in "Finishes"). `NightLights.lamp_walls(windows)` groups the lit
  windows into walls (normal, plane, ends, finish, bands, posts, panes); `lamp_wash(lamp, wall,
  glow, rules)` is a disc centred on the point of the wall square to the fire box, `reach` cells
  round it, cut to the wall's ends, to the finish's bands and off its posts (as finish_wash), and
  round the panes; its strength is that material's window wash strength (and colour) times
  `share`, times (1 - distance / `out`); none behind the wall, from `out` away, past the wall's
  end, for a finish without rules or by day. `lamp_washes(...)` drops it where a building stands
  between the fire box and the wall (light_reaches); `_plan` also needs the wall seen from the eye,
  with the lantern never hiding its own wash. Data: `data/light.json` pools.wall.lamp {share 0.6,
  reach 1.0, out 1.6} (why: the fire box is a small light, so smaller than a window's reach 1.6
  and about half as strong; a lantern a cell's middle from the wall, 0.65 out, gets 0.6 x 0.59
  of the wall's strength). LitSpots now gives every lit window its wall's `span` (also plaster
  ones and the farmhouse's; `wall_span`), so plaster walls know their ends. No lantern stood by
  a wall, so the village (data/maps/town.json) gets two: cell (3, 7) by Tome's timber house and
  (32, 7) by the clinic's door, both off the villagers' routes and the festival stalls.
  ART_DIRECTION section 3 updated.
- Checked: test_maps `_lamp_wash`: data sane (share under 1, reach under the window's); the town's
  windows stand on fewer walls than windows, every pane on one, every window with a span; the
  new lanterns wash a plaster and an earthen wall, the shrine's two wash none; every wash on its
  wall plane, within its ends, above the ground, within `reach`, uvs centred square to the fire
  box, on the finish's bands and off posts, off the panes, weaker than the window's; on a test
  wall: fades with distance (exact value at 0.3), none at `out` or behind, half at glow 0.5,
  none by day, none past the wall's end, none for an unknown finish, a box between stops it.
  Mutation checks: without the distance falloff and the clip to the wall's ends, "it keeps within
  the wall's ends ..." and "the wash fades with the lantern's distance from the wall (0.240 near,
  0.240 further)" FAILED, `test_maps: FAILED (2 failed)`; without the building check, "a building
  between the lantern and the wall stops its wash" FAILED, `test_maps: FAILED (1 failed)`;
  restored after. First screenshot showed no change at all (pixel diff 0): the lantern's own
  occluder box hid its wash from the eye; fixed by passing the fire box as `own`. Then A/B
  frames (share 0.6 vs 0) at `--demo --map=town@tome --time=21:00`: 984 px changed, mean
  +14/+9/+5 rgb, on the earthen panel left of Tome's door only; `town@clinic`: 1451 px, mean
  +17/+10/+5, on the plaster left of the clinic door, the lantern and the farmer left out.
  `--demo --map=town --time=21:00` looked right by eye. All 28 test scripts print OK; smoke
  runs (title, --demo, --demo --map=town, --demo --mine=3) no error or warning lines.
- Left / next: only walls with lit windows are known (the faces the camera sees all have one);
  the flat view has no wall washes, so the lanterns' is 3D only, like the windows'.

## 2026-11-07 — Calm paddy ground in the flat view
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: the flat view's paddy cells that grow rice (MapView.paddy_cells, the Kaminoda paddies in
  every season) no longer draw the painted "paddy" tile, which had rows of green tufts that the
  rice and the stubble were drawn over. MapView._draw takes each such cell's ground from
  MapView.ground_key_in, which calls CropPatches.paddy_ground: drained plain mud in winter
  (`ground:paddy_mud:<variant>`, dark mud with faint grain, where the water patches lie), and
  flooded still water in spring to fall (`ground:paddy_flood:<variant>`, the same blue-green water
  as the old tile without its tufts, two faint sky strips). Both are new kinds in
  PlaceholderArt._ground. The paddy tile "ground:paddy:<n>" is unchanged and still used by the 3D
  view and by paddy tiles with a prop on them. set_season now also redraws the ground, since the
  picture depends on the season. Why mud in winter: the grey-blue water patches (5d7680) and the
  straw stubble (b89a5a) read clearly on dark mud; on the blue-green water they blended.
- Checked: test_view2d `_paddy_ground` (in the flat view's tests, after the water patches): the
  3D tile still has its tufts; for each season every rice cell's ground is paddy_flood (spring,
  summer, fall) or paddy_mud (winter), none with a tuft colour (4e7e34, 62983e, 94c464), every
  other cell keeps its ground_key; the drained mud carries no water or stubble colour. Mutation
  check: with paddy_ground returning the key unchanged, the test printed four FAIL lines ("flat
  paddy ground in spring/summer/fall/winter: 128 rice cells ... (128 off)") and `test_view2d:
  FAILED (4 failed)`; restored after. Screenshots (480x270 flat view, last frame of 20):
  `--demo --season=winter --map=kaminoda@well`, the paddies cropped and enlarged x3: the stubble
  and the grey-blue patches read on plain mud; `--season=summer` the same spot: the rice stands
  in flooded water with the blue-green between the rows. Smoke runs (title, --demo, --demo
  --map=town, --demo --mine=3, res://scenes/main_2d.tscn --demo --map=kaminoda --season=winter):
  no error or warning lines.
- Left / next: the calm mud and flood are flat-coloured with faint grain, not yet painted in the
  art style of the other ground tiles; the 3D view still shows the painted tufts (not changed, as
  asked).

## 2026-11-07 — The shore ice grows over the winter
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: the ice width is no longer one number all season. `data/snow_cover.json` "ice" gets `grow`:
  `curve` (day of the season, factor: 1 -> 0.35, 8 -> 0.65, 16 -> 0.95, 22 -> 1.0, 26 -> 0.8,
  30 -> 0.5, linear between), `cover_bonus` 0.2 (+20% at full snow cover, so snowy and blizzard days
  and the days after them, while the snow lies, are wider) and `max` 4.4. `WaterIce.grown_width(style,
  day, cover)` scales `width` [2, 4] by both and caps the top at `max`; `Game.ice_for(season, rules,
  day, cover)` returns the style with that width (no day = the plain mid-winter data), and
  `Game.ice_style()` passes today's day and `snow_cover`. Both views push the same style through
  `WaterIce.push` (FarmWorld/WaterSurface.set_ice, WaterView.set_ice), so the shader and the flat
  view follow one rule; they re-read it in `_show_weather` (each morning, each map change).
  Reasoning: ice thickens through the cold, is widest in the deep of winter (about day 22, the
  old 2..4), recedes in the last week as it warms, and snow insulates and adds a lip, so it
  widens a little under cover. `max` 4.4, not 4.8: with land on all sides the open middle pixels
  (centres 7.5 and 8.5) are 4.5 px from the bank line, so any width at or under 4.5 keeps them open;
  the bobber (a cell's middle) and every fishing rule are untouched.
- Checked: test_maps `_water_ice` new checks: thin early (day 1), widest at day 22, receding at day
  30; snow widens on the same day; every day 1..30 at cover 0 / 50 / 100 stays positive, ordered,
  at most `max` and within the open middle; no grown ice outside winter; WaterView takes the grown
  width in its shader uniform. A first try with max 4.8 FAILED the middle check, which is why it is
  4.4. Screenshots (`--demo --season=winter --weather=sunny --fishing=wait`, frame 19, 480 x 270,
  farm pond): day 1 a thin rim, day 20 a clearly wider ragged rim. Rough count of pale
  blue-white pixels in the frame (b > 200, r > 170, 8 < b - r < 45; includes some background):
  day 1 snow 0: 1893; day 20 snow 0: 2072; day 20 snow 80: 2080; day 30 snow 0: 1859.
- Left / next: only the pond's width is measured in screenshots (frame is small); ice on the paddies
  is still open; the flat view's growth is checked by the uniform test, not by a screenshot.

## 2026-11-07 — Shader warm-up for the night and the first map
Agent: Claude Code (claude-opus) · Commit: this commit
- Done: the two gaps left by "Shader warm-up, cheaper rebuilds". (1) Night variants:
  `ShaderWarm.news` notes whether each mesh is on the night lamps' layer (`lit`; a kind seen on
  the ground layer and later on a lit mesh is kept again as lit, not the other way), and `show`
  puts an OmniLight3D like NightLamps' (`WarmLamp`: no shadows, cull mask LIT_MASK, range 0.1,
  just toward the camera from the quads) over the quads, the lit ones on LIT_MASK and the
  ground's on GROUND_LAYER, so the lamp's extra pass compiles in the black. Measuring showed a
  second hitch at dusk: the frame the sun's shadows switch off (Game.sun_shadow reaches 0) also
  compiled new variants, so Main3D now draws one warm-up frame with the sun's shadows the other
  way round (`_warm_step`, then `_show_shadows` again; `_end_warm` restores them too). (2) The
  first map: `MapFade.cover()` starts the fade at black in its hold (no Game pause, no
  map_arrived at its end: the view still says that itself in `_ready`, so map_entered and the
  events run as before); Main3D calls it before the first `_enter_map`, so the first map's kinds
  are drawn under black like any map change's. Frames 1..3 of a run are black, the picture is
  back by frame 11 at 30 fps (a `--demo` movie: means 0,0,0 for frames 1..3, 122.7,126.9,79.6
  from frame 11 to 19; frame 19 looked at: shadows as before).
- Checked: all 28 test scripts print OK (0 failed). test_maps new checks: the town's quads under
  one lamp without shadows, cull mask LIT_MASK, range under NEAR and reaching every quad, lit
  quads on LIT_MASK and the ground's on GROUND_LAYER (13 of 16 kinds lit); a kind first on the
  ground then lit is kept again, then on the ground nothing new; in the scene the first map
  starts covered (busy, holding, alpha 1, not paused, its warm-up drawn); the sun's shadow switch
  seen both on and off while the warm-up was up, and off again in the house. With the lamp, the
  cover and the flip taken out, test_maps printed `test_maps: FAILED (3 failed)`, those three.
  Smoke runs (title, --demo, --demo --map=town, --demo --mine=3, --demo --time=21:00): no error
  or warning lines.
  Times, in a window (a throwaway SceneTree script, not kept: the farm at 17:30 as the first
  map, 90 frames, a map change to the village, 110 frames, then a game minute a frame from
  17:30 to 21:30 in the village; sound off, see below), "before" = this build with the lamp, the
  flip and the cover switched off, two runs each: the frame the lamps came on (17:55) 371 / 484
  -> 160 / 167 ms; the frame the sun's shadows went off (18:30) 500 / 483 -> 108 / 112 ms; the
  map change to the village, longest frame 387 / 287 -> 87 / 183 ms (the farm's kinds were
  warmed at the start). The first map's warm-up costs one black frame of 670 / 776 ms (before:
  its frames after the first, in view, at most 47 / 36 ms, but its unseen kinds then compiled
  at the next map change and at dusk). With the lamp alone (no flip, no cover) the lamps' frame
  was 104 / 120 ms and the shadows' 451 / 456 ms, so both parts count. A second warm-up lamp
  made no difference (180 / 101 ms), so it was not kept.
- Left / next: the frames where the lamps come on and the shadows go off are still 100..170 ms
  (not found: the sprites are unshaded, every mesh has a material_override; perhaps not
  shaders). With sound on, the frame at 20:00 in spring took 216..355 ms: the crickets' ambient
  loop is synthesized on the main thread when it first plays (Sfx._process -> stream(key));
  with sound off it was gone. Making ambient loops ahead, off the main thread, as the tunes are,
  would close it.

## 2026-11-07 — The field takes the night lift
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: ART_DIRECTION section 3's "the field's objects and crops take no night lift". The
  field's unshaded sprites now take the figures' warm lift by the same rule and numbers
  (data/light.json "sprites" → "lift": range 2.4, (1 - d/range)², a window only on its lit
  side, none past a solid building, capped at 0.6): crop sprites, the CropClusters plants
  (corn, rice, the vines), items lying on the ground, forage, eggs, story props, every lit
  sprite (SpriteLight.GROUP) that is not a figure or held by one. `SpriteLight.field_lifts`
  measures each at the middle of its picture (a plant: its root plus half its picture's height
  at its size; a plant its cell's snow may fold away takes none). NightLights' "Warmth" pass
  draws them before the figures, so a figure standing in front covers them (one out of the
  light but over a lifted object is drawn back plain). Same shader: the copy plus the picture's
  own pixel times the warm colour times the lift (a plant's colour also times its shade), so
  the pool under them is not counted twice. Why not the CropClusters `sun` uniform or a
  per-instance lift: the night tint (46529a) multiplies the 3D picture after it, and the
  Compatibility renderer clamps the 3D picture at 1, so the lift divided by the tint (x3 in
  red) would clip on most leaves and fruit; the overlay adds it after the tint, as for the
  figures. Cost: the lifts are worked out once a game minute (Game.minute_passed), or when the
  number of lit sprites changes, a CropClusters is replanted or a listed sprite was replaced;
  each frame only the few lifted ones are projected (a sprite that moved since is skipped until
  the next minute). A plant's quad (`NightLights.plant_corners`) stands like its billboard but
  does not follow its sway (about half a pixel at the tip in calm air).
- Checked: test_weather `_sprite_light` new checks: a crop sprite and an item in front of a lit
  window take the lift, the nearer more; none behind the window's wall or far off; figures and
  what they hold are left out; the corn cluster in front of the window lit (3 plants), the
  ones behind it and far off not; none by day; capped by many lights; a building between keeps
  a lantern's light off the field; a plant the snow may fold takes none; a plant's quad stands
  on its root at its picture's size. With `max` 0 test_weather printed `test_weather: FAILED
  (9 failed)`, 5 of them the new field checks, so they bite. All 28 test scripts print OK (0
  failed). Smoke runs (title, --demo, --demo --map=town, --demo --mine=3, --demo --time=21:00,
  --demo --season=summer --time=21:00, --demo --festival=lantern_night) print no error or
  warning lines.
  Pixels (480x270, last frame of 30; "before" = this build with field_lifts returning nothing;
  the farm frames were made steady for the comparison by a temporary fixed Game rng seed,
  reverted: two "after" runs then differed by 0 px): `--demo --time=21:00` 1418 px changed, all
  on the five objects nearest the farmhouse (three sprouts and two cabbages, lifts 0.06..0.08;
  mean 20.4,31.6,27.2 -> 25.0,35.4,28.2, at most +11 red, +10 green, +3 blue, none darker).
  `--demo --season=summer --time=21:00` 2694 px, on the sprouts and the corn plants by the house
  (24.9,36.0,28.7 -> 28.4,39.3,29.6, at most +19,+15,+5). `--festival=lantern_night`,
  `--map=town --time=21:00`, `--map=kaminoda --time=21:00`: 0 px (no field sprite near a light);
  `--map=kaminoda@genzo --time=21:00`: 91 px, all in the HUD forecast icon. Looked at, with the
  window energy raised x9 for the look only (reverted): the lit corn's warm pixels sit on the
  plants' own pixels, the ground pool round them unchanged.
- Left / next: the overlay knows no depth, so a lit plant behind another plant or a fence is
  drawn over it where they overlap; a plant's lift does not follow its sway or parting; the
  winter paddy water patches and the grass tufts take none (they lie in the pools).

## 2026-11-07 — Flat view water patches in winter
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: the flat view (MapView, the Kaminoda paddies) draws the winter grey-blue water patches that
  the 3D view has, under the stubble. The places are CropClusters.water_spots_for's (the same cells,
  row gaps, nudges, sizes and flips), read by CropPatches.water_to_draw and drawn by draw_water
  (called in MapView._draw_objects before the stubble). Only in a season with water
  (CropClusters.water_on: winter). A patch is left out where snow lies on its cell
  (SnowLayer.lies with the paddy's hold, as the stubble). The blob is a 12 x 5 pixel oval cut once
  from data/paddy.json's new keys water.color (5d7680), water.glint (7d939b) and water.sky
  (9aaeb4), the same colours as the 3D picture patch:paddy_water, centred on the place.
- Checked: test_view2d `_water_patches` (in `_tall_crops`): water only in winter (none in spring,
  summer or fall; winter has some); the same places and sizes as
  water_spots_for; no snow, all shown; heavy snow (1.0) hides the ones lying, none left under
  snow; the blob's colours are the three data colours and the 3D picture uses the same three.
  Mutation check: with the season gate removed the test printed `FAIL: flat water: none in spring,
  summer or fall` (restored after). The snow rule for the water was not mutated separately.
  All 26 test scripts print OK (0 failed). Smoke run `res://scenes/main_2d.tscn -- --demo
  --map=kaminoda --season=winter` (--quit-after 300): no error or warning lines. Screenshot
  (shots/frame00000019.png, 480 x 270, --demo, Kaminoda winter): the dark grey-blue patches show
  between the stubble rows, zoomed to check; shots/ then deleted.
- Left / next: the flat view's patches do not sway or flicker with the rice; the 3D view's
  picture patch:paddy_water is unchanged (its colours are now the same as data/paddy.json's).
  The screenshot was checked by eye only, no pixel count.

## 2026-11-07 — Tall crops sway in the flat view
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: the flat view's rice, corn, vines and the Kaminoda paddies sway with the wind like the 3D
  shader's. `CropPatches.sway_tip` is the shader's swing in pixels (CropClusters.SWAY, 1 + 1.5 x wind,
  gust swell and flutter, speed 1.3 + 0.9 x wind, phase by the plant's root place so by the cell's
  hash, a small lean downwind, times `stiff`: vines 0.6); `band_shifts` cuts the picture into
  `bands` strips and shifts each by whole pixels by the shader's (1 - v)^2 height weight, so the top
  moves most and the root row never. `draw` / `draw_spot` take an optional `sway` {wind, t}; empty =
  still as before (snow hiding is untouched). FarmView and MapView take Game.wind_strength() in
  `_process`, keep the time to `flat.rate` frames a second (data/wind.json "flat": rate 8, bands 4)
  and redraw their objects only when that frame changes and tall crops stand. Peaks: a sunny
  breeze under 1 px (a twitch at a gust's crest), rain 1 px, a storm 2 px or more, vines about
  0.6 of that.
- Checked: test_view2d `_tall_sway` (no wind none; calm under a pixel, more in rain and storm,
  storm 2 px; vines less than rice; same time and place same value; places out of step; bands top
  heaviest and root band 0; time quantised; the draw runs). Whole suite, smoke runs and a flat-view
  `--demo --season=summer --weather=storm` frame (tips differ between frames, pixels crisp).
- Left / next: the winter water patches are not in the flat view (another task); gusts are not
  synced between the views.

## 2026-11-07 — Sprites take the world's light
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: ART_DIRECTION section 3's "sprites stay unshaded". The sprites stay unshaded (crisp, the
  pixels as drawn) and take two touches of the world's light, numbers in data/light.json
  "sprites" (new `SpriteLight`, scripts/world3d/sprite_light.gd):
  1. By day a share of the sun's colour by the clock: `sun_tint` = the sun's colour (Game.sun_light)
     over the plain noon sun `ref` ffedcc per channel, at most 1, `share` 0.45 of the way from
     white. So noon, the night, rooms, mines and clouded days (all the plain colour) are exactly
     white and change nothing; 6:30 gives (1, 0.90, 0.81), 17:30 (1, 0.88, 0.80): green and blue held
     back, never brightened, so nothing washes out. Why 0.45: the meshes take the whole sun, but
     the sprites carry their own drawn light; under half keeps faces and clothes in their own
     colours while the figure sits in the same golden hour as the houses. `Main3D._aim_sun` calls
     `SpriteLight.apply` each game minute: the modulate colour of every sprite in the group (alpha
     kept: the occluders' fade, the note puff's), and the CropClusters' new `sun` uniform
     (`set_sun`; one uniform and one multiply in the fragment, nothing else there touched).
     `FarmWorld.make_sprite` puts every sprite in the group with the share of the moment;
     `SpriteLight.unlit` keeps the charge pips, the bite's "!", the whistle note and the mine
     lantern as drawn.
  2. At night a warm lift near lights: NightLights gets a fifth, last pass ("Warmth", WARM_SHADER)
     that draws each figure (the farmer, villagers, animals, with their held items) near a lit
     window, shoji door, stone lantern or festival light back from the copy plus its own picture's
     colour times `lift.color` ffa050 times the lift. `SpriteLight.spots_of` (windows `out` 0.3 in
     front of the pane, lanterns, festival lights by FestivalGlow.darkness, string lanterns 0.6) and
     `lift_at`: each within `range` 2.4 cells of the figure's middle gives energy x (1 - d/range)²,
     a window only on its lit side, none past a solid building (`NightLights.light_reaches`), capped
     at `max` 0.6. A first try took the colour from the copy over the tint and burnt the legs of a
     farmer standing in a window pool orange (the pool was counted twice); the picture's own
     pixel fixed it. The figures' quads come from a shared `NightLights._quads` (the draw-back
     uses it too, unchanged).
  3. No sun-and-shadow on the sprites: the only cheap scene query is Occluders' boxes, which hold
     the houses, coop and barn but not the trees, the fences or a hip roof's real outline, so a
     sprite would darken where the ground shows no shadow and stay bright in a tree's; a real one
     needs the shadow map in a per-sprite shader, which the SpriteShadow caster quad would shadow.
  The flat view is unchanged (its sprites take only the tint, as before).
- Checked: test_weather `_sprite_light` (share modest; ref = the plain sun; white at noon, night,
  indoors, under rain / storm / snow / blizzard; golden morning and evening, blue held back most,
  never over 1 or under 1 - share all day; make_sprite takes it now and later, alpha kept, a mark
  white, the crop pictures' uniform; the lift: in front of a window more the nearer, none behind
  its wall or far off or by day, capped, a lantern all round, festival lights by darkness, a
  wall's box blocks a lantern; Warmth is NightLights' last child). With `max` 0 it failed 4 checks,
  so it bites. All 28 test scripts print OK (0 failed). Smoke runs (title, --demo, --demo
  --map=town, --demo --mine=3, --demo --map=town --time=21:00, --festival=lantern_night) 0 error /
  warning lines; the Movie Maker runs print no shader errors.
  Pixels (480x270, last frame of 30, --demo; "off" = this build with share 0 and max 0, as the
  farm demo frames differ run to run even at HEAD; the village, rooms and barn are steady):
  `--map=town --time=7:00` 2447 px changed, all on the villagers (mean 139.9,121.0,117.7 ->
  139.9,112.9,102.8; red unchanged, at most -21 green / -35 blue). `--map=town --time=21:00`,
  `--map=house --time=21:00`, `--map=barn` (noon): 0 px outside the HUD forecast icon (no figure by a
  light; indoors plain). `--map=kaminoda@genzo --time=21:00` (the farmer by Genzo's lit door, before
  = HEAD): 1135 px, all on the farmer, 46.1,38.6,57.5 -> 107.1,71.3,74.2. `--festival=lantern_night`:
  6551 px on the figures among the lanterns, 56.1,44.6,58.9 -> 73.0,52.5,60.7. `--map=town --time=19:30`:
  972 px, a slight dusk warmth (green -2.5, blue -7.4). Looked at: the farmer by the farmhouse door at
  21:00 has a warm face and shirt, outlines and pixels crisp; the 17:30 farmer and cabbages a touch
  golden like the house; the room at 21:00 as before.
- Left / next: the field's objects and crops take no night lift (only the pools under them, as
  before); a figure partly behind a fence or a corner is lifted whole (the overlay knows no depth;
  one whose middle is behind a solid building is skipped); sprites take no sun shadow (above).
## 2026-11-07 — Merge: the flat view's paddies take the winter stubble
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged the two parallel branches "Tall crops in the flat view" and "Winter paddies". The
  flat view's MapView reads `CropClusters.paddy_key`, which now gives `stalk:rice:0:stubble` in
  winter, so the flat paddies show the cut stubble too (no water patches there). test_view2d's
  paddy check now expects the stubble in winter, in the same nine-hill count as summer.
- Checked: all 28 test scripts print OK (0 failed) on the merged tree (test_view2d failed 2 checks
  before the test update: "kaminoda winter: paddies grow nothing" and the winter count 1152).
  Flat screenshot `main_2d.tscn -- --demo --season=winter --map=kaminoda@well --snow=0`: the
  paddies show straw stubble over the paddy ground, no errors printed.
- Left / next: in the flat view the stubble sits on the paddy tile's painted tufts and reads busy;
  the flat paddies have no winter water patches.
## 2026-11-07 — Winter paddies: cut stubble and water patches
Agent: Claude Code (claude-haiku) · Commit: this commit
- Done: the Kaminoda paddies in winter. They had no rice at all (`PADDY` had no winter). Now
  `CropClusters.paddy_key("winter")` = `stalk:rice:0:stubble`: the cut rice in the same nine-hill
  layout as the rice (`LAYOUT "grain:0"`, sizes 0.9..1.1 of the picture), each hill a picture of
  four short straw stalks a pixel apart, cut at different heights, lighter cut ends, no rim
  (PlaceholderArt `_stubble`; the first draft had a rim and read as tan lumps, so it was redrawn).
  Winter water: `CropClusters.plant_water` puts flat patches (`patch:paddy_water`, 12 x 5 px,
  dull grey-blue oval with a paler strip) on the paddy cells, lying on the ground (own
  MultiMesh and shader, lifted 0.02 off the ground). Per row gap (z 0.33 and 0.67, between the
  layout's rows) a patch when the cell's hash passes `chance` 0.4, so about 0.8 a cell. Numbers
  in data/paddy.json (`water`: seasons, chance, z, x, nudge, size; reasoning in its `_about`).
  MapWorld._plant_paddies plants the water only when `CropClusters.water_on(season)` (winter).
  Snow: stubble and patches use the paddy's hold (0.5) and the same snow rule as the rice
  (`snow_at(root.xz, cover * INSTANCE_CUSTOM.r) > 0.5` folds them, under snow or its rim); the
  water's cover uniform is set by `set_cover` with the plants'. Spring to fall unchanged (the
  same keys, no water).
- Checked: test_maps `_crop_clusters` paddy loop for all four seasons (the keys, plant counts,
  holds, snow driven, water only in winter, every patch on a paddy) and `_paddy_winter`: the
  stubble picture is shorter than the young rice and has straw pixels, the patch is a 12 x 5
  grey-blue oval, data/paddy.json is winter only with two row gaps between the rows, the
  patches sit between the rows and inside their cell with a count near the chance, no fold at
  cover 0, the GDScript rule folds some plants and patches at cover 0.8 (not all: the paddy
  holds half), the shaders carry the rule, and set_snow drives the patches. Test output:
  `test_maps: OK (0 failed)`. All 28 test scripts print OK (0 failed) (the list in the output of
  the run). Smoke runs (`--quit-after 300`: title, `-- --demo`, `-- --demo --map=kaminoda`,
  `-- --demo --map=town`, `-- --demo --mine=3`) print no error or warning lines.
  Screenshots (480 x 270, `--demo --season=winter --map=kaminoda@well`, 10:00): snow 0 shows the
  stubble among the grey-blue patches (2x crop checked); snow 80 whitens the paddy's snowy cells,
  the stubble on them folds and the patches there are gone, stubble stands on the bare spots;
  summer (`--season=summer --snow=0`) keeps its tall rice unchanged.
- Left / next: the flat view has no paddy stubble or water (it draws one sprite a cell, the
  winter paddy stays bare there). At 480 x 270 the stubble is small; the first look was judged
  by an enlarged crop, not the game's own pixels at a distance. The water picture is one shape
  (flips and shades only).

## 2026-11-07 — Tall crops in the flat view
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: the flat view reads tall crops as 3D does. New `scripts/world/crop_patches.gd` (CropPatches): draws
  CropClusters.spots_for (same places, sizes, flips, shades and `stalk:<id>:<growth>:<ripe|growing>:<variant>`
  pictures, so a cell grows the same plants in both views; nothing jitters) as whole-pixel quads, the root row on
  the place, further back first. FarmView draws the cluster instead of the one sprite for rice and corn at growth
  2 and 3 and the vines (cucumber, tomato); MapView draws the Kaminoda paddies' rice under the props by season
  (young spring, tall summer, ripe fall, none winter; `paddy_cells`) and leaves a plant out where snow lies on
  the paddy (SnowLayer.lies with cover x map_hold, as the 3D shader; the farm's crops stay in snow as before).
  FarmView / MapView reach CropPatches through load() so they still compile in test scripts that run before the
  autoloads (CropClusters pulls FarmWorld and Game). MapView got `snow_rules` (set by show_snow).
- Checked: test_view2d `_tall_crops` (plant counts per crop and growth, the same hash every time, rects whole
  pixels and in the cell, flips mirrored, variants, gold ears, paddies by season and the snow gate); all test
  scripts print OK (0 failed). Screenshots (flat, 480x270): `--demo --season=summer` ripe straw-and-gold rice
  beside corn and young plants on the field, `--map=kaminoda@well` summer green rice, fall golden, winter
  with `--snow=80` no rice, snow patches over the ground.
- Left / next: no sway in the flat view; the winter paddy stubble another agent is adding to 3D is not in the flat
  view; the paddy ground picture still carries its own painted tufts.
## 2026-11-07 — Earthen and yakisugi walls take the night lamps
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: ART_DIRECTION section 3's "still open" from "Pale plaster takes the night lamps". The
  pale wash skipped the timber look's earthen plaster (tsuchi) and the yakisugi charred boards
  (their red already at the tint's cap, their blue under pale_from). New `NightLights.finish_wash`
  in the same pass after the copy (a "Finishes" layer beside "Washes", its own FINISH_SHADER):
  the same disc round each lit window and shoji door, but only on windows LitSpots dressed with
  their wall: `LitSpots.wall_look` gives the kind (`earth` for timber / upper_timber, `board`
  for yakisugi, none for plaster or the plaster upper floors) and the heights clear of the skirt,
  rails and front beam; `_dress` adds the wall's ends along it (in from the side's corners) and
  the front posts' widths (`LitSpots.front_posts`, now also what MapWorld._house_walls builds
  from), and the pieces are cut round them, so the timber stays dark. The shader keeps it to warm
  pixels that are not pale: the copy over the tint, red above both green and blue by warm_from
  0.03 .. warm_full 0.1 (earth 0.32 and boards 0.13 at night; roof tiles -0.07, grass -0.21,
  plaster about 0), times one minus the pale mask. Numbers in data/light.json pools.wall:
  `earth` ffa860 x 0.3 (a soft warm glow), `board` c8a07c x 0.1 (a faint warm-grey sheen, so the
  boards stay dark wood, not orange); a door up to 1.5 times as strong, like the pale wash. The
  village walls' heights (VILLAGE_WALL, TIMBER_SKIRT, TIMBER_RAIL, YAKISUGI_BAND, RAIL) and
  `village_body` moved to LitSpots, MapWorld uses them; FarmWorld._lit_spot keeps LitSpots' extra
  window fields. wall_wash's rects / pieces / strength split into helpers shared by both washes.
- Checked: test_maps `_finish_wash` (data present, boards fainter and greyer than earth; the
  town's timber and yakisugi windows dressed, the plaster ones none; every piece on the wall
  plane, within reach and the wall's ends, on a band, off every front post and the pane, UVs
  centred; bands clear of skirt, rails and beam; a timber house's posts cut at the corners and
  every cell edge; follows the glow, a door brighter; pass order copy < finishes < glows; the
  shader's mask on the pictures: earth 0.8+, boards > 0.1, plaster and kawara under 0.01).
  Leaving the posts uncut made it fail ("keeps off the front posts"), so it bites. All 28 test
  scripts print OK (0 failed). Smoke runs (title, --demo, --demo --map=town, --demo --mine=3,
  --demo --map=kaminoda --time=21:00) 0 error / warning lines; the window runs print no shader
  errors. Pixels (480x270, last frame, --weather=sunny, before = HEAD, after = this change):
  `--demo --map=kaminoda@genzo --time=21:00` (Genzo's timber house): 3339 px changed, all on the
  earthen panels (mean 72.6,57.7,62.1 -> 110.4,82.7,76.4; beside the door 88,74,77 -> 146,112,98,
  further off 70,56,68 -> 89,69,76), the posts, rail, board skirt, roof and the farmer unchanged
  (post 49,42,52 both). `--map=kaminoda@haru` (Haru's yakisugi house): 5004 px on its boards
  (mean 34.5,21.7,22.4 -> 44.8,29.9,28.8, at most +25,+20,+16; by the side window 39,21,19 ->
  52,31,27), still dark brown; a dark seam 23,20,33 and the pane 247,161,91 unchanged.
  `--map=town@start` (Tome's timber house): 2055 px, 77.0,63.4,71.1 -> 117.3,90.1,86.3;
  `--map=town@river` (Kota's yakisugi): 2141 px, 57.8,38.9,33.8 -> 69.9,48.7,41.5. Unchanged
  (0 px outside the HUD forecast icon): `--map=town@sayo` 21:00 (plaster), `--demo --time=21:00`
  (the farmhouse plaster), `--map=kaminoda@haru --time=10:00` (day). The flat view has no wall
  wash (its houses are seen from above), so nothing there.
- Left / next: stone lanterns still wash no walls; the plaster band under a yakisugi house's eaves
  and the upper floors keep the pale wash only; sprites stay unshaded.
## 2026-11-07 — Footprints read the snow patches
Agent: Claude Code (claude-sonnet) · Commit: this commit
- Done: ART_DIRECTION section 2, the footprints' open note. A print now appears only where snow lies at that spot.
  `SnowLayer.noise_at` / `lies` are the GDScript copy of the shader's `snow_at` (pixel of the 128 noise, 16 per cell,
  repeating every 8 cells; only "snow", not the rim, counts), `noise_texture()` shares the texture. `Footprints.ground_snow`
  = the ground's hold where snow lies at Game.snow_cover, else 0; both views feed it as `hold`, and each print keeps its `hold`.
  3D: the FootprintLayer shader includes `_SNOW_AT`, discards pixels where `snow_at(world.xz, cover * COLOR.r)` is not
  snow (COLOR.r = the print's hold, the cover uniform set each feed), so a print also vanishes if the snow melts back.
  Flat: FootprintView skips a print where snow no longer lies. Legibility: size 0.3 x 0.46 -> 0.38 x 0.58, colour 5f76ab -> 506aa8.
- Checked: all 28 test scripts print OK (0 failed); test_maps `_footprints` (share lying at cover 0.4, repeat, a trail on a row
  stops at bare patches and the counts differ by exactly the bare ones, shader text) and test_view2d `_footprints` (every print
  on snow, none while standing on a bare patch); smoke runs title, --demo, --map=town, --mine=3 clean. 3D shots at snow 40 and 80:
  prints sit on white only and are clearer at the larger size.
- Left / next: no before-screenshot kept; the flat view has no `--footprints` seeded trail, so it is checked by tests only.

## 2026-11-07 — Winter ice along the water's shore
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: ART_DIRECTION section 2 "no frozen water in winter". New `WaterIce`
  (scripts/world3d/water_ice.gd, no other dependencies): a piece of shader code pasted into the
  3D sheet (WaterSurface) and the flat view's skin (WaterView) at `//ICE//`, `push` (style and
  snow into the uniforms), `land_mask` (8 bits for the land round a cell) and `shore_px` (the
  shader's shore distance in GDScript, for tests). In winter outdoors the farm pond, the village
  water and the river get thin ice 2..4 px in from the bank line (ragged by value noise every
  4 px), pale blue-white (d6e5ef, alpha 0.92) with a one-pixel rim (9ab9d3, 0.7) where it meets
  open water, short diagonal cracks (35% of the dash segments) and frost specks (8%); with snow
  lying, 2 x 2 px flecks of snow on it (0.85 x the cover, more near the shore). Lit like the
  ground in 3D (the sheet's own light term), under the CanvasModulate in the flat view. 3D quads
  carry the land mask in UV2.x, the flat view in its mask's red channel. Glints, the bobber's
  rings and rain dimples are drawn on open water only. Width 4 at most keeps 8 px from any side
  open, so the bobber (a cell's middle) is always on water; fishing rules untouched. Numbers in
  `data/snow_cover.json` "ice" (seasons, width, alphas, cracks, frost, snow, colours), read by
  `Game.ice_style()` / `Game.ice_for`; pushed by Main3D._show_weather (`FarmWorld.set_ice`,
  also to child worlds, kept for a sheet built later) and main_2d._show_weather
  (`WaterView.set_ice`), none when sheltered.
  Width chosen 2..4 (not up to a third of a cell, 5.3) so a one-cell channel still has open
  water down its middle.
- Checked: test_maps `_water_ice` (winter only; width within a third of a cell; a cell's middle
  open with land all round; a one-cell channel keeps >= 2 px open; the pond's quads carry the
  right land masks, shore and inner cells both present; the shader draws ice before rings; the
  uniforms, colours and snow from the data; no snow without cover; spring clears it; a sheet built
  after set_ice has it; MapWorld passes it to the village water) and in the 3D scene (spring
  open, winter ice_on 1, back to 0); test_view2d `_check_water` (each cell's mask = WaterIce's
  land mask on the farm pond and town water; the ice first in the shader) and `_water` (the flat
  pond takes the data's ice and snow, none in spring; the scene ices its water in winter and
  thaws). All 28 test scripts print OK (0 failed); smoke runs (title, --demo, --demo
  --map=town, --demo --mine=3, --demo --season=winter, with --map=town) show no ERROR or WARNING
  lines; the window runs below print no shader errors. Screenshots (480 x 270, last
  frame): winter `--fishing=wait`: a pale ragged rim with blue crack dashes round the pond, the
  bobber's ring cut off where it meets the ice; `--snow=80`: white flecks on the rim; the river
  (`--fishing=river`): ice along the near bank, rings on open water; `--map=town@east`: the
  village pond rimmed; 19:30: the ice darkens with the ground; flat view (main_2d.tscn) farm pond
  with snow and the town pond rimmed. Before: plain blue water in all of them.
- Left / next: no ice on the paddies (they show only the ground picture in winter); the ice does
  not grow over the winter or with the cold (one width all season).
## 2026-11-07 — Hearth smoke in the flat view
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: the flat view (main_2d.tscn) now has the hearth smoke. The pure rules moved out of HearthSmoke
  into `SmokeRules` (scripts/smoke_rules.gd): the config, `strength_at` (meal windows and fade),
  `strength_now` (the clock plus the `hide_in` weather rule), the vents (`vent_at`, `farm_vent`,
  `village_vent`, `village_vents`) and `puff` (how far along its rise a puff is, as fractions: lean,
  sway, growth, opacity). HearthSmoke keeps its old static names (they delegate) and `_place` now takes
  its numbers from `SmokeRules.puff`; the arithmetic is the same, so the 3D result is unchanged.
  `SmokeView` (scripts/world/smoke_view.gd) is the flat layer: it reads the same vents (x / z in cells
  x 16 px, from above), climbs each puff up the screen from the vent, snaps puffs to whole pixels
  (a square with its corners off, 3 px growing 2.6x), leans them by Game.wind_strength and fades them
  with the same strength. Main2D adds one per map view (after NightView, under the figures); indoor
  maps get none. Flat numbers in data/smoke.json under `flat` (size_px 3, rise_px 26, lean_px 14,
  wobble_px 1.5, alpha 0.7; ours).
- Checked: test_view2d `_hearth_smoke` (farm: one vent that is the 3D one seen from above, shown at
  7:00 with 4 puffs inside the rise, gone at noon, eased at 6:10, a storm buries it, rain leans them
  further than sun; town: one vent per village house, all alight at 18:00, none at noon; Tome's
  house none) and test_maps (SmokeRules equals HearthSmoke, strength_now, farm vent, village vents,
  puff start and wind lean). Screenshots of `res://scenes/main_2d.tscn --demo --time=7:00` (farm) and
  `--map=town --time=18:00` show pale puffs over the roofs; a pixel diff of the farm at 7:00 against
  8:40 (no smoke) changes 89 pixels over the house and 0 elsewhere; at 12:00 the town has none.
- Left / next: the puffs are faint against the brown roof boxes in the flat view (the flat roofs
  are plain boxes); the smoke still shows only where the camera frames a roof.

## 2026-11-07 — Hearth smoke made visible; smoke and footprints merged
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged the hearth smoke (d9ab050) and footprints (eb04db7) branches (only the WORKLOG /
  ROADMAP entries clashed; both kept). The smoke's puffs were 0.08 units at 42% opacity, about two
  pixels on screen, and no screenshot had shown them. Now size 0.13, alpha 0.55, rise 1.2
  (data/smoke.json): pale puffs that read on the roof.
- Checked: all 28 test scripts print OK (0 failed) on the merge; smoke runs (title, demo, town,
  mine 3) 0 error lines. A throwaway script stood the farmer just north of Kota's house at 7:00
  (the spawns all put the ridges above the frame: vents project at y < 0 from every town spawn
  and the farm), frame 45: the puffs show over the ridge, white-cream, clearly smoke.
- Left / next: the smoke shows only when the farmer is north of or level with a house; the game's
  camera seldom frames ridges. Flat view still has no smoke.

## 2026-11-07 — Footprints in lying snow
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: where snow lies (cover at least 30%) out in the open, the farmer, the villagers and the
  dog press small prints, left and right in turn, a step of 0.55 cells apart, turned along the walk.
  `Footprints` (scripts/footprints.gd) is the rule set both views share: walkers as {id: cell
  position}, a ring of 160, prints age in game minutes (gone after 90, four times as fast while snow
  falls), none where the ground holds under 0.65 of the snow (tilled and wet soil, water: the snow
  there is patchy), none across a jump of 3 cells (a door), none indoors or in the mine. 3D:
  `FootprintLayer` (one MultiMesh of flat quads, a shader drawing a pixel-stepped sole and the ground
  shader's light), made by `FarmWorld.set_farmer` from the same walker list Parting uses; Main3D
  ages it each minute and clears it on a map change and on a new day. Flat: `FootprintView`
  (toe and heel blocks), fed from `Main2D._process` (farmer, `VillagerView.feet()`, the dog).
  Numbers in data/footprints.json (balance is ours: 0.65 min_hold keeps prints off the
  field, where the snow is patchy and prints on bare soil looked wrong). New screenshot arg
  `--footprints` (Game.demo_footprints, `FarmWorld.seed_prints`) pre-seeds a trail.
- Checked: all test scripts and the smoke runs (see the commit report). test_maps `_footprints`
  (data, spacing, sides, direction, standing / jump / return, two walkers, hold, the ring, fading
  and snowfall, threshold, shelter, the world feeding the farmer and a Parting.GROUP walker, cleared,
  melted below the threshold, Main3D's hooks); test_view2d `_footprints`. Screenshot
  `--demo --season=winter --map=town@shrine --snow=80 --footprints`, cropped and enlarged: soft
  blue dashes in a left / right pattern across the snow; at the 480 x 270 picture each is about
  9 x 4 px, so the sole's shape does not read, only the trail.
- Left / next: the prints do not read the snow's noise, so one can lie on a bare patch inside
  the snow; a sole shape that reads at this size (bigger, or two-tone) if the user wants it.
## 2026-11-07 — Hearth smoke at meal times
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: thin pale smoke from the farmhouse's ridge (FarmWorld._make_hearth_smoke) and from every
  village house's roof on outdoor maps (MapWorld._make_village_smoke), 6:00-8:30 and 17:00-19:30
  by the clock, eased in and out over 0.33 h at each end. HearthSmoke (scripts/world3d/hearth_smoke.gd)
  copies StallWares.Steam's approach: four lit puffs out of step, bigger and slower (rise 0.9,
  period 6 s, size 0.08 growing to 2.6x, alpha 0.42, colour ece8e0). Numbers in data/smoke.json
  (windows, fade_hours, hide_in, puffs, period, rise, size, grow, alpha, color, lean, wobble).
  The wind (FarmWorld.wind, from data/wind.json) leans the puffs; a storm look hides them. Each
  smoke is its own node, added outside occlude and MeshCache, so the house meshes and their
  cache are unchanged. Vent positions come from the roof formulas (HearthSmoke.vent_at /
  village_vent, copied constants as in Minka / _village_house).
  Note: there was no existing vent in scripts/world3d/minka.gd (the brief said there was). The
  farmhouse's roof is a hip roof, so its vent is the middle of the ridge (4.5, 3.68, 2.3).
  Data file is data/smoke.json, not weather_fx.json: weather_fx keys are weather looks and are
  iterated by tests and Game, so a new key there would be read as a look.
- Checked: test_maps `_hearth_smoke` (runs at frame 1; loads the script at run time, since a
  class name in the test would compile farm_world too early and fail): strength_at 7:00 and
  18:00 = 1, noon, 3:00, 6:00 and 20:00 = 0, mid-fade between; the farmhouse has one smoke at the
  ridge's middle, visible at 7:00 and hidden at 12:00; a storm hides it (checked when the look is
  storm in the season); a gale moves the puffs further than a calm day; the town has one smoke per
  village house, all shown at 7:00 and none at noon; a vent is over its roof (y 2..4.5); Tome's
  indoor house has none. Test results (run from the worktree, each script's final line):
  test_farm OK (0 failed), test_save OK (0 failed), test_title OK (0 failed), test_weather OK (0 failed),
  test_dialogue OK (0 failed), test_menu OK (0 failed), test_body OK (0 failed), test_events OK (0 failed),
  test_maps OK (0 failed), test_inventory OK (0 failed), test_food OK (0 failed), test_cooking OK (0 failed),
  test_hold OK (0 failed), test_villagers OK (0 failed), test_talk OK (0 failed), test_relationships OK (0 failed),
  test_shops OK (0 failed), test_animals OK (0 failed), test_fishing OK (0 failed), test_forage OK (0 failed),
  test_mine OK (0 failed), test_ending OK (0 failed), test_festivals OK (0 failed), test_view2d OK (0 failed),
  test_goals OK (0 failed), test_lang OK (0 failed), test_showcase OK (0 failed), test_audio OK (0 failed).
  No SCRIPT ERROR in any log. Smoke runs (title, `-- --demo`, `-- --demo --map=town`, `-- --demo --mine=3`,
  `--quit-after 300`): exit 0, no errors, no warnings.
  Screenshots (480 x 270, `--write-movie`): `--demo --time=7:00` and `--demo --map=town --time=18:00`
  (also `--map=town@sayo`, `--map=kaminoda@well` at 18:00, and `--lens=wide` at 7:00). In every
  framing the farmhouse ridge and the village ridges are cut off by the top edge of the frame, so
  the puffs are not visible in the pictures; the smoke is checked by the tests above only. Nothing
  else in the frames changed.
- Left / next: the flat view has no hearth smoke (left open). The smoke is not seen in any
  screenshot: a framing that shows a roof's ridge and the puffs above it (or a close-up camera for
  a check) is still to do. Puff size and alpha are not judged by eye yet.

## 2026-11-07 — Shader warm-up, cheaper rebuilds of houses, the stand and bamboo
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the open items of "Faster first visit to a map". Measured first (throwaway script in a
  window: each map entered, then the camera stepped over the whole map twice, frame times):
  the long frames on a map were not first draws but the fades of things in the farmer's way.
  Occluders switches a thing's materials to alpha blending, a new StandardMaterial3D shader;
  Godot frees a shader with its last material, so the faded kind was compiled again on every
  fade (30..90 ms frames, as many on the second pass over a map as on the first; with the
  fades off none over 25 ms, a map's first frames on unseen parts ~20 ms). Changes:
  `ShaderWarm` (scripts/world3d/shader_warm.gd): a material's kind is its switches, modes and
  which textures it has (`signature`; colours and numbers are uniforms, the same shader), plus
  whether a MultiMesh wears it; `news(world)` keeps a copy of every kind a world wears that no
  world wore before this run, and the faded twin of each that fades (so their shaders stay
  compiled for the run); `show` draws the new ones once as tiny quads in front of the camera.
  Main3D does that in `_enter_map` while the map change's fade holds black (MapFade.holding)
  and takes them away before the picture comes back (`warm`, `_warm`). Cheaper rebuilds:
  MeshCache.build now also keeps builds that list lit windows and lamps (NightLights group)
  and hang things in the world's Sway (a noren, stall curtains: the items kept with their
  nodes as pieces, the Sway itself a piece when the build made it), so a village house is kept
  whole (walls, roofs, windows, noren), as are the farmhouse with its windows and the stand
  with its noren; replayed materials are made from a recipe (the stored properties that differ
  from a new StandardMaterial3D) instead of duplicate() (64 us a material, ten times making
  one); Occluders.add copies a material only when something else holds it
  (`only_here`: its reference count; most builders make theirs fresh, and the copy was the
  bamboo hill's dearest part, 12 ms of the 113 clumps' 17); bamboo props skip MeshCache (the
  clump meshes are shared by OutdoorProps already). The flaky test_maps check "farm built
  again looks the same" (1 run in 4 on main: 153 of 332 meshes shared) built the farm on
  Game's field, which comes from an unseeded rng; it now uses a field generated from a fixed
  seed.
- Checked: all 28 test scripts print OK (0 failed). test_maps new `_occluder_own` (fresh
  materials used as they are, one shared by two meshes of the thing stays one, one held by a
  variable or a mesh outside copied; a recipe's material equals duplicate() property by
  property; with HELD_HERE 5 or 3 one of these fails), `_kept_lit_and_swaying` (the five
  village houses kept; a village built again lists the same windows and lamps and is in the
  NightLights group; its noren are its own nodes in its own Sway, same places among the
  children and the same poses in a wind; the farmhouse and stand kept, windows and Sway made),
  `_shader_warm` (kinds by switches not colours; faded and MultiMesh kinds apart; the
  village's kinds kept once with faded and MultiMesh ones; a quad each near the camera, none
  when nothing is new), and in the scene the house's kinds drawn during the door's fade and
  gone before it cleared; the old "a lit window build is not kept" now checks it is kept, and a
  MultiMesh build is the one not kept. Look: Game's rng fixed to one seed (temporarily, in
  HEAD exported to a copy and here), frame 39: farm, town, house, hill, mine 3, winter town
  snow 80, minamino, sakurazaka, kaminoda, town 21:00, store, river, fall farm, barn, farm
  21:00, winter hill snow 80: 0 pixels differ in all 16; a storm in the village 16822, all
  rain streaks and dimples (the particles' own randomness). Every world built twice before it
  shows (a temporary hack in both, so the shown one is replayed from MeshCache): 0 pixels in 14
  of 16; the town 1 pixel (HEAD differs by that pixel between built once and twice too);
  sakurazaka 73 (72 off by 1 in one channel on a yakisugi board wall and one corner pixel:
  coplanar faces drawn in another order since an occluded thing's fresh materials are no
  longer copied; with the copy forced back, 0). Smoke runs (title, --demo, --demo --map=town,
  --demo --mine=3): no errors or warnings.
  Times, in a window: `tools/build_times.gd` warm (a build again), HEAD vs now, two runs each:
  all 23 maps 484 / 522 -> 292 / 300 ms, town 44 / 42 -> 25 / 23, hill 97 / 104 -> 49 / 65,
  sakurazaka 46 / 62 -> 25 / 24, minamino 48 / 53 -> 25 / 27, kaminoda 50 / 65 -> 33 / 30,
  farm 51 / 45 -> 48 / 38, rooms 4..9 -> 2..5; first builds unchanged within the noise (all
  1352 / 1427 -> 1327 / 1408). The walk over eight maps and back to three (stepping the camera
  over each twice): frames over 25 ms on the first pass HEAD 43 (longest 115.7 ms), now
  without the warm-up 44 (87.1), now 1 (30.1, the store's first frames); on the second pass 38
  (98.3) -> 0 (8.1); on revisits 14 + 16 -> 0 + 0 (6.0); the first passes' frame time in all
  3438 -> 1630 ms (the bamboo hill no longer recompiles its fades every frame it fades). The
  black frames (build and warm-up) longest 216 ms in HEAD, 241 now (out of sight).
- Left / next: the night lamps' OmniLights make other shader variants on the things they light;
  those are not warmed (a lit night frame was not measured). The first map after the title has
  no fade, so its kinds are only warmed at the next map change. Coplanar faces on the yakisugi
  walls can fight (a pixel's draw order changes with material order). Not tried by hand.
## 2026-11-07 — Flat view stalls show their wares
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: the flat view's festival stalls drew the items' inventory pictures; they now draw the same
  wares the 3D StallWares builds. `PlaceholderArt._ware` paints one 8 x 12 picture per item with
  a 3D look (key `festival:ware_<name>:1x1`, sizes / anchors in festival_size / festival_anchor):
  dango skewers, sakura mochi, tea pot and cup, yakisoba on the griddle, shaved ice, soda bottles
  in a tub, chime, fans, chestnuts, sweet potatoes, clay rabbits, moon lantern, soba bowls, yuzu
  tea, daruma, charms on a rack; steam puffs (see-through pixels) over the hot ones.
  `FestivalView.ware_key` uses `StallWares.has_look` (no second table), an item with no look keeps
  its item picture; the display of the two bare Lantern Night stalls was already drawn.
- Checked: test_festivals `_flat_art` (every stocked item: its picture exists, 8 x 12, drawn, not
  magenta, standing on its ground, steam as StallWares.STEAMING; no-look items keep the item
  picture). All test scripts OK (0 failed), the four smoke runs clean. Looked at main_2d frames
  of all four festivals (enlarged crops): wares read at the counter, steam shows. 3D files
  untouched.
- Left / next: crowd or the player can cover a counter in a frame; wares are 8 px wide so three
  stock items touch edge to edge.
## 2026-11-07 — The flat view's maple is a tree picture
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: the open item of "Japanese maples" (the flat view drew a red box). Looking at the flat
  view first: persimmon, sakura, pine and bamboo are boxes there too (MapView.COLORS, one flat
  rect each); only the festival sakura has a picture. So the maple is a picture like the story
  props (StoryView): `PlaceholderArt` key `tree:maple:<season>:<snow 0|1>` (`_maple_tree`, 24 x 32,
  trunk foot at (12, 30)): a layered crown of eight lumps (wide lower tier of four, a middle
  pair, a centre and a top lump) in the 3D maple's colours, outlined; fall turns three lumps
  orange (MAPLE_FLAME); winter is bare branches with snow on their upper side when the map has
  snow. `MapView._draw_objects` draws it for kind `maple` (`MapView.maple_key`), foot on the
  cell's middle. The season reaches the view by `MapView.set_season` (called on the map's entry
  and on each day's start from main_2d). The COLORS entry stays (test_maps needs every prop kind
  to have one). The picture's colours are copied into PlaceholderArt (MAPLE_LEAVES, MAPLE_FLAME)
  rather than read from Trees: loading Trees makes the flat view's scripts depend on farm_world,
  which names the Game autoload and fails to compile in the --script tests. test_maps checks the
  copies equal Trees.LEAVES.maple and MAPLE_FLAME.
- Checked: all 28 test scripts print OK (0 failed), no SCRIPT ERROR in any run. test_view2d new
  `_maples`: the hill has its maples in the flat view; for spring, summer, fall and winter, with
  and without snow: a 24 x 32 picture, round (over 40 % clear), clear corners, a trunk or bare
  bark, green leaves only in spring and summer, orange only in fall, no leaves in winter, snow
  only in winter with snow. test_maps: the copies equal the 3D colours. Screenshots (flat view,
  `res://scenes/main_2d.tscn --demo --map=hill`, frame 39, removed afterwards): fall (two red
  maples among the lit grass, a little orange) and winter `--season=winter --snow=80` (bare
  branches with snow among the snow). Smoke runs of `--demo --map=hill --season=fall` and
  winter: no errors.
- Left / next: the flat maple is small (24 px crown) and its orange lumps are faint at the
  game's size; the spring and summer pictures were checked by the tests, not by a screenshot.
  Other flat tree kinds (persimmon, sakura, pine, bamboo) are still boxes.
## 2026-11-07 — Faster first visit to a map
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the open item of "Smooth map changes" (a first visit built in one frame). Measured
  with the new `tools/build_times.gd` (every map's build, first and again, `--parts` per step;
  a print in a window costs ~14 ms, so the times are kept and printed after): the dearest
  parts were not the farm buildings but the farm's bamboo fence (~160..220 ms, every day),
  the land past each outdoor map's edge (40..100 ms: thousands of tile pictures read back
  from their textures, every apron cell asking the edge cells' kind nine times), a new Shader
  parsed for every snow material (0.7 ms each, dozens a map), the rooms' corner shading
  (per pixel over the whole floor, ~40 ms a room) and the props' meshes. Changes, the look
  kept: `MeshCache` (scripts/world3d/mesh_cache.gd) keeps meshes for the run: `parts(id,
  build)` for FarmProps.Parts builds (the fence by its gate, the wood's three pine shapes),
  `build(w, id, make)` records the plain MeshInstance3Ds a build adds (mesh, transform,
  shadow, layers, its materials copied; snow materials go into the world's snow) and places
  them again with copies of the materials; a build that adds anything else (lit windows,
  lamps, a Sway, a MultiMesh, groups, metas) is not kept and always runs. Used for the
  farmhouse body, coop, barn, chest, bin (the stand has a noren: runs), every map prop but the
  story props (id: map, prop, season, snow), the village houses' walls and roofs (footprint
  and look), rock / thresholds / room walls (the map's shape). `PlaceholderArt.image(key)`
  keeps tile pictures as RGBA8 images; MapWorld keeps each map's ground picture;
  Surroundings asks every map cell's kind and hold once and keeps the apron picture, snow
  mask, pine spots and grass cells by them; SnowLayer.shader(code) shares one Shader per code
  (snow, water, backdrop); GrassTufts share one blade mesh; _shade_corners skips cells with no
  wall beside them. Building ahead: FarmWorld.setup_steps / MapWorld.build_steps split a build
  into steps (setup / build run them all); `Main3D._prebuild` builds the maps next door (the
  current map's doors, outdoor first, never a mine floor) while the farmer has stood still
  0.4 s and no fade runs, steps up to 4 ms a frame (PREBUILD_MS), and keeps them as kept
  worlds (away, out of the tree); room is made by dropping a kept map not next door, never past
  KEEP_WORLDS 6; `_enter_map` finishes a half-built one if it is the map entered, else drops it,
  and takes the entered map's kept world out before keeping the one left (a trim could drop it
  before). A new day drops the one under way with the kept ones.
- Checked: all 28 test scripts print OK (0 failed). test_maps new `_mesh_cache` (a recorded
  build placed again: same meshes and transforms, own materials, snow material in the new
  world's snow, the return value; a build with a lit window not kept, runs each time; parts
  built once; town, farm, house and hill built twice alike piece by piece with own materials and
  most meshes shared; kept tile images equal the textures' pictures) and `_prebuilt_worlds`
  (nothing while walking or before standing still; from the farm the village first, then house,
  coop, barn, kept out of the tree for today's key; entering the village uses the one built;
  a half-built one is finished on the way in; a new day drops them). With MeshCache handing out
  the recorded materials themselves and building ahead off, 7 of these failed. Look: Game's rng fixed to one seed
  (temporarily, in HEAD exported to a copy and here), 14 frames (`--demo` farm, town, house, hill,
  mine 3, winter town with snow 80, minamino, sakurazaka, kaminoda, town at 21:00, store, river,
  fall farm, barn), frame 39 each: 0 pixels differ in all 14. Entering the village built ahead
  vs built on entry (throwaway script, same seed): 0 pixels differ. Smoke runs (title, --demo,
  --demo --map=town, --demo --mine=3): no errors or warnings.
  Times, in a window, other agents running (noisy): `tools/build_times.gd`, first / again, HEAD
  vs now: farm 291 / 223 -> 269 / 49 ms, town 100 / 99 -> 108 / 47, hill 173 / 142 -> 188 / 98,
  minamino 155 / 170 -> 198 / 50, sakurazaka 114 / 127 -> 102 / 46, kaminoda 110 / 113 -> 125 /
  49, house 35 / 34 -> 18 / 6, store 57 / 54 -> 26 / 6, all 23 maps 1829 / 1758 -> 1426 / 494.
  Main3D._enter_map on a walk through first visits (throwaway script, 2.5 s idle between):
  HEAD town 104, sakurazaka 125, mine 75, teahouse 48, minamino 156, river 61, kiku_house 46,
  kaminoda 108, hill 149, store 56, farm (after dropped) 199, house 34 ms; now with building ahead
  all 0.7..2.5 ms except the store 24 ms (the village has ten doors; six kept); without it 86,
  117, 37, 25, 145, 59, 19, 100, 140, 24, 43, 12 ms. Building ahead: 611 step frames on that
  walk, most under 8 ms; the dearest frames 18..26 ms (a map's edges step; the hill's last two).
- Left / next: a map's first build still costs its cold time somewhere (now on idle frames
  while the farmer stands still: a frame of up to ~26 ms); the bamboo clumps and the stand
  (Sway) and the village houses' lit windows are made each build. First draws of new materials
  (shader compiles) are not warmed. Not tried by hand.
## 2026-11-07 — Lantern Night's two bare stalls get a display
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: the two Lantern Night stalls that sell nothing (WORKLOG "festival stalls' wares as lit
  meshes": "stay bare") now show a fair display, as a stall prop's new `display` key in
  data/festivals.json (`Festivals.DISPLAYS` = goldfish, masks; `Festivals._check_prop` refuses it on
  a non-stall or an unknown name). `StallWares.display` (3D): a goldfish-scooping tub (hooped wooden
  tub, blue floor, see-through water, four goldfish as `StallWares.Swimmers`, each a small lit mesh
  swimming its own circle and wiggling, kept under the water; a glass bowl of two spare fish, three
  paper scoops on a tray, a cloth sign on a stick) and a two-tier stand of masks (fox, demon,
  round-faced, rabbit, tanuki, all our own shapes, tilted back). Same slot limits as the wares (one
  lit mesh, counter front half, under 0.28, clear of the lantern). Flat view: `festival:display_goldfish`
  and `festival:display_masks` pictures drawn on the counter by FestivalView (`display_key`).
  `tools/house_model.gd --what=stalls` includes them. A lathe closes an end that has a radius (a
  lid!) - the tub's profile therefore ends on the axis and its hoops are bands (`_band`).
- Checked: test_maps `_stall_wares` (each display: one lit vertex-coloured mesh, no wares or
  pictures, on the counter within the posts and clear of the lantern, under TALL; the goldfish move,
  stay in the tub under the water and wiggle; every display used; no Lantern Night stall bare; run
  with TALL 0.2 it failed 7 checks, so it bites), test_festivals (data check of display; flat
  pictures drawn, not magenta, standing on the counter). Looked at `--what=stalls` renders from the
  game's angle and the flat pictures enlarged. An in-game `--festival=lantern_night --map=town@...`
  frame did not show the stalls (the spawn did not put them in view), so they were not seen in the
  running game's village, only in the stall renders.
- Left / next: nothing open for the stalls.
## 2026-11-07 — Pale plaster takes the night lamps (a warm wash on the walls round lit windows)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: docs/ART_DIRECTION.md section 3's open item. Why plaster took little of the lamps: the
  night tint multiplies the whole picture after the 3D lights, so nothing under it can be brighter
  than the tint (46529a), and white plaster already sits near that cap under the night sun
  (Sayo's store, unlit sunward plaster 58,66,121; lamp-lit plaster 70,82,114: red and green at the
  cap). No per-material or sun / tint balance under the tint can lift it past the cap, and a
  lighter tint with a dimmer sun would change the unshaded ground and sprites. So NightLights adds
  a fourth pass, "Washes", between the BackBufferCopy and the glows: `NightLights.wall_wash(win,
  glow, rules)` lays a soft disc on each lit window's / shoji door's wall plane, `reach` 1.6 cells
  either side, from the ground to `up` 0.6 over the window, in up to four pieces round the pane
  (the paper keeps the pane's own orange; a first try over the pane bleached a door to white),
  a door's up to 1.5 times as strong like its pool, on the windows' schedule and seen-through
  fade. Its shader (blend_add, screen texture) adds data/light.json "pools" → "wall" colour
  ffa050 times strength 0.4 in dithered steps, only where the copy's blue over the tint's blue
  (about the brightness before the tint) lies between pale_from 0.45 and pale_full 0.72: plaster
  and paper take it, dark boards, posts, roofs, the ground (real lamps and pools) do not. The wash
  rects join `_lit`, so figures in front are drawn back from the copy. Night sun, tint, ground,
  lamps and the day unchanged. The festival decorations were already lit meshes
  (FestivalMeshes, StallWares; only lantern paper and flames, which give light, are unshaded), so
  nothing to do there; docs corrected.
- Checked: test_maps `_wall_wash` (data present; for every town window: pieces on its wall plane,
  off the pane, spanning +-reach from the ground to over the window, UVs centred on the window;
  strength follows the glow, none at 0; a door brighter, no piece under a door; the pass order
  copy < washes < glows < figures; the shader reads the screen and the tint; plaster's picture
  blue over pale_full, the boards' under pale_from). Mutating the left piece over the pane and
  the UV centre made it fail (2 fails), so it bites. All 28 test scripts print OK (0 failed).
  Smoke runs (title, --demo, --demo --map=town, --demo --mine=3, --demo --festival=lantern_night,
  --demo --map=town@sayo --time=21:00) logged 0 error / warning lines. Pixels (480x270 frames,
  before / after): `--demo --map=town@sayo --time=21:00` 5521 px changed, all in x 220..388 y
  33..122 (Sayo's walls), mean on them 95,97,126 -> 159,139,148; plaster by the side window
  121,117,127 -> 222,181,158, further off 90,96,125 -> 175,149,151; no changed pixel whose blue
  was under 0.45 of the tint's (dark wood, ground untouched), the farmer's pixels unchanged. Same
  view at `--festival=lantern_night` (20:01): 134,124,127 -> 236,187,159 and 103,102,125 ->
  189,156,152. `--demo --time=21:00` (farmhouse plaster between timbers): 2976 px, mean 85,88,115
  -> 159,134,138. `--demo --map=town --time=21:00` (the timber house's earthen wall by its door):
  only the 3D pixels at the door's frame edge change (805 px with the HUD forecast); the earthen
  wall stays with the real lamps. Day `--demo --map=town --time=10:00`: only 91 px in the HUD's
  tomorrow-forecast icon differ, which is rolled at random per run (two after-runs are identical
  pixel for pixel); the 3D picture is identical.
- Left / next: earthen (tsuchi) and yakisugi walls keep the real lamps only (their red is at the
  cap); stone lanterns wash no walls (none stands by a plaster wall today); the flat view has no
  walls to wash; sprites stay unshaded.
## 2026-11-07 — Japanese maples
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: the "no maple" gap from the hill entry below was only a missing kind, so `maple` is one now.
  scripts/world3d/trees.gd: `LEAVES.maple` (spring light green 86b844, summer deep green 2f6e32,
  fall red c42a1e, bare in winter), its own small layered crown `_maple_crown` (a wide flat tier of
  five low lumps, a narrower tier of three, a cap; orange `MAPLE_FLAME` lumps among the reds in
  fall); the bare winter form and its snow are the shared ones. Prop kind `maple` in
  CountryProps / MapWorld; the flat view draws a red box (MapView.COLORS). Placed on free grass:
  hill (11, 11), (28, 2), (14, 7), (24, 20), (12, 19), (36, 22) (the two near the lookout were
  added after the lookout view showed no broadleaf tree), Kaminoda (28, 16), Sakurazaka (27, 4).
- Checked: all 28 test scripts print OK (0 failed) (run in one sequence). test_maps new checks: the
  maple in every season and seed (same reach / height / winding as the others), orange only in
  fall, snow on the bare maple, the maples on free grass in the hill / Kaminoda / Sakurazaka.
  Screenshots (480 x 270): `--demo --map=hill@top` in fall (a red and orange maple in the left of
  the view) and winter (bare, snow lying), and three temporary spawns (removed again) near
  (24, 20): spring fresh green, summer deep green, fall red with orange, winter bare with a
  little snow on the twigs. The lookout shows only that one broadleaf tree; the others are out of
  frame. Smoke runs (title, --demo, town, mine=3, hill and Kaminoda in fall, Sakurazaka in winter)
  logged no errors or warnings.
- Left / next: the maple is not in a festival view or the flat view's own picture (a box only).
## 2026-11-07 — Vines read better: the ripe cucumber stands apart
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: the open item of the 2026-11-07 vines entry. The cucumber's ripe fruit was the leaf's dark
  green (2a5a24) and vanished among the leaves. `data/crops.json` cucumber look gains `ripe_fruit`
  d4e46a (pale yellow-green; the item icon keeps `fruit`, so a picked cucumber looks as before).
  `PlaceholderArt._stalk` (vine branch): a ripe long fruit is a pale column with a lit top pixel and
  a darker column beside it (the dark edge). Where a ripe vine's fruit hangs, the leaves on that
  side within six rows are left off (`_hangs_by`, window 6.5: a leaf one step past the fruit still
  touched it), so the fruit shows against the stake. Tomato keeps its red fruit and gets the same
  leaf gap. Round fruit with no `ripe_fruit` key keep their colour.
  Parting: no code change. The villagers' and the dog's sprites feed the same `pushers` array as the
  farmer (`FarmWorld.set_farmer` -> `CropClusters.set_pushers`), and the vine shader scales every
  push by the layer's `stiff` (`part_push(root.xz) * k * stiff`), so they were already held as firm
  as the farmer. The new test pins it.
- Checked: test_maps. `_crop_clusters`: the ripe cucumber fruit (the 2 and 3 growth pictures, three
  variants) is paler than its leaves (luminance 0.85 vs 0.64, at least 0.15 apart) and no opaque
  pixel that is not fruit or leaf rim touches a fruit pixel (a first pass with the 4.5 window failed
  on one leaf five rows down; the test caught it). The old fruit-colour count reads `ripe_fruit` now.
  `_parting`: with a villager beside a cucumber stake, every vine picture's material has the vine's
  stiff (0.6), two pushers, the villager second, and the shader still multiplies by stiff. Enlarged
  sheet of the pictures (x8, nearest) before and after: the dark fruit under the leaves before, the
  pale fruit on bare stake after. In-game `--demo --season=spring` frame 39 (the ripe cucumbers are
  spring crops, not summer; the tomato has no grown stage in the demo): the pale fruit reads small
  at 480 x 270. All 30 test scripts print OK (0 failed). Smoke runs (title, --demo, --demo
  --map=town, --demo --mine=3): 0 error / warning lines.
- Left / next: the stake reads thin with the leaves left off; a fuller leaf set above the fruit
  would be the next pass. The item icon for a cucumber is still the dark fruit.
## 2026-11-07 — Rain dimples on the water
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: in rain and storm the farm pond, village water and river get many small short-lived rings at
  random spots. 3D: a second layer in WaterSurface's shader (`dimple_density`, `dimple_life`
  uniforms; a hash of the cell, the time slot and the clock picks which cells ring and where, a ring
  grows 0..3 px in its cell, so no ring slot is used); flat view: the same in WaterView's shader.
  Numbers in data/weather_fx.json ("dimples" on rain 0.22 / 0.9 s and storm 0.55 / 0.55 s; none on
  sunny, snow, blizzard). `Game.dimple_style()`, `FarmWorld.set_rain` (kept for worlds built later),
  `WaterSurface.set_rain`, `WaterView.set_rain`; Main3D / Main2D `_show_weather` push it, {} indoors.
- Checked: test_maps `_water`, test_view2d `_dimples`, test_weather `_rain_dimples` (dry by default,
  style reaches the shaders, storm > rain, none in sun / snow / blizzard / winter storm, no ring slots
  used). Screenshots: `--demo --weather=rain|storm --fishing=wait` (3D) and main_2d.tscn storm: pale
  rings over the pond, fainter in the flat view.
- Left / next: no ring at the feet.

## 2026-11-07 — The festival stalls' wares as lit meshes
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: docs/ART_DIRECTION.md section 1's open item. `scripts/world3d/stall_wares.gd` (StallWares)
  builds every selling stall's stock on its counter as one lit vertex-coloured mesh
  (`OutdoorProps._vertex_material`), colours from the items' looks: Blossom Day dango (three
  skewers on a lacquered tray, two standing in a cup), sakura mochi in their leaves on a plate, a
  teapot and cups of green tea; Lantern Night's eats yakisoba on an iron griddle with a spatula,
  shaved ice in footed glasses (strawberry, melon) by a little flag, marble soda in a tub of water
  with ice, its chime stall two wind chimes on a stand (the paper strips are their own pieces,
  blowing in the wind as cloth, `OutdoorProps.commit_swaying`) and three uchiwa in a block; Moon
  Night roast chestnuts in a pan on a clay brazier, sweet potatoes on hot stones (one broken
  open), clay rabbits on a red cloth, two moon lanterns; Year's Turn a bowl of soba (fishcake,
  prawn, onion) with chopsticks and stacked bowls, yuzu tea with the fruit and a leaf, two daruma
  (one eye painted in), omamori on a rack and a tray. Hot food steams (`StallWares.Steam`: three
  pale lit puffs rising 0.2 and fading, out of step). `FestivalProps._wares` calls it; an item
  without a mesh keeps its picture in its slot (none today). The slots are the pictures' slots
  moved to the counter's front half and 0.1 left (clear of the corner lantern), and wares stay
  under 0.28 high: seen from the game's camera (yaw 45, pitch 30) the old curtain hid nearly
  everything behind it, so its hem went up from 1.17 to 1.25 (still six pieces in the wind). Lights
  (FestivalProps.glows, NightLamps, NightLights' stall pools) unchanged. `tools/house_model.gd
  --what=stalls` renders each selling stall near from the game's angle. The flat view's stalls
  keep their item pictures.
- Checked: test_maps `_stall_wares` (every stall's items have a mesh; per stall no pictures, one
  ware mesh listing the stock, lit vertex colours, faces out, on the counter between the posts,
  y 0.745..1.02 at most, steam over each hot item that moves and fades, one stall light, curtain
  pieces + chime strips in WindSway; the picture fallback); a run with TALL set to 0.1 and green
  tea left out of STEAMING failed it (8 fails), so it bites. All 28 test scripts print OK (0 failed). Smoke runs
  (title, --demo, --demo --map=town, --demo --mine=3, --demo --festival=years_turn and
  lantern_night) logged 0 error / warning lines. Screenshots: `--demo
  --festival=<id>` for all four before / after (HEAD exported to a copy): the stalls are at the
  frame's edge there, the changed pixels only at the stalls' counters and curtains; with
  `--map=town@tome` / `town@shrine` / `town@north` added the stalls are in view: the Blossom Day
  counter shows the tray and the plate of mochi, Moon Night the rabbits on red cloth and two
  lanterns, Year's Turn the soba bowl and yuzu cups with steam rising (night, lit by the stall's
  lamp); the house_model views show all seven stalls near.
- Left / next: the flat view's stalls still draw the item pictures. The two stalls at Lantern
  Night that sell nothing stay bare. The steam is lit (dark at night under the lamp's light only).

## 2026-11-07 — Cucumber and tomato vines on stakes, and the wind on every tall crop
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: docs/ART_DIRECTION.md's open tall-crop item. `CropClusters` LAYOUT gains "vine"
  (cucumber, tomato from growth 2): two stakes a cell (places [0.3, 0.38] and [0.7, 0.72], nudge
  0.06, size 0.9..1.0) each a small `stalk:<id>:<growth>:<ripe|growing>:<variant>` picture
  (`PlaceholderArt._stalk` vine branch: a brown stake, leaves up it alternating sides, a light
  growing tip, and when ripe the fruit hanging: long dark cucumbers, round red tomatoes; rimmed in
  a deep leaf shade like rice). The crop art keys (`crop:<id>:<growth>:<state>`) and the flat view
  are untouched. A vine layer's material has `stiff` 0.6 (LAYOUT "stiff"): a stake holds the
  vine, so its sway and parting are a bit under rice's. The crop shader (all tall crops, rice and
  corn too, which until now ignored the wind) takes a `wind` uniform: the grass's swing and speed
  growth, gust swell and flutter, a small lean downwind (+x, through the parting's world push),
  none at wind 0 (`CropClusters.set_wind`, called by `FarmWorld.set_wind` and `add_crops`).
- Checked: all 30 test scripts print OK (0 failed); test_maps adjusted (tomato now a cluster key,
  the farm test's sprite crop is an onion; new checks: vine pictures show fruit only when ripe and
  are taller grown, two stakes a cell inside it, a ripe tomato cell is 2 plants and no sprite and
  a sprite again at its seed); test_weather: the crops' wind uniform on every picture and on ones
  made later, the shader carrying the wind. Smoke runs (title, --demo, --demo --map=town, --demo
  --mine=3): 0 error / warning lines each. Frames `--demo --season=spring` (the demo's ripe
  cucumbers, with and without `--weather=storm`) before and after, frame 39: before, one big
  black-outlined sprite a cell; after, two thin stakes with leaves and dark fruit, the storm's
  sway too small to read in a still. The demo has no summer tomato at a grown stage (one sprout).
- Left / next: the vine pictures are dense among the leaves; a cucumber's fruit (dark green) is
  hard to pick out from the leaves at this size. Villagers and the dog still part them as rice.

## 2026-11-07 — Barn stalls: straw bedding mesh
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: docs/ART_DIRECTION.md's open item "the stalls have no straw bedding mesh". `BarnProps._bedding`
  (scripts/world3d/barn_props.gd), called at the end of `_stalls`, makes the bedding in each stall: the
  open space between two partitions (a run of free cells: five single cells and the last space, two
  cells wide, so six stalls). Per stall: a tapered pad 0.03 high (0.9 x 0.76 of a cell, narrower
  on top), two or three lumps (0.24..0.34 x 0.2..0.28) up to 0.05, and 9 + 3 per cell of loose
  stalks (0.012 x 0.008 x 0.14..0.22, lying flat, yaw random) along the front and back edges and at
  the ends, clear of the partitions and the back wall. Three straw tones (c9ad6c, b89c5e, d9c184),
  lit plain colours like the coop's straw. A seed by the stall's place keeps each stall the same
  every run. The partitions, the posts, the rails and the stall places are unchanged; nothing in a
  stall rises above 0.05, so the cows and sheep and the eggs and feed AnimalLayer lays still sit right.
  Balance: the pad is low on purpose (a few hundredths), so animals still read as standing on the floor.
- Checked: test_maps `_straw_bedding` (new): six stall spaces; the bedding's middle stands 0.02..0.06
  up in every stall; no sampled spot in a stall rises above 0.06 and the bedding covers at least 60
  spots. Output: `test_maps: OK (0 failed)` (the existing `_stable_props` checks pass too: lit,
  faces wound outward, inside the cells, not in a wall). `test_animals: OK (0 failed)`. Smoke runs
  (`--quit-after 300`, exit 0, no error or warning lines): title (no args), `-- --demo`,
  `-- --demo --map=town`, `-- --demo --mine=3`. Before / after of `--demo --map=barn` (frame 59,
  shots/ deleted afterwards): before the stalls are bare straw floor with the partitions; after,
  each stall has a pale straw bed under the partitions' gaps, the floor between the stalls still
  the straw tile, the cows and sheep standing clear of it.
- Left / next: the bedding is not seen at the edge of a cow's stance in a frame (only checked by
  the spot test). Loose stalks are random by seed, not by hand-placed. Not pushed (the task said
  branch only).

## 2026-11-07 — The wind moves leaves and cloth: fence, kadomatsu, noren, curtains, banner
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: docs/ART_DIRECTION.md's open wind items. `OutdoorProps.Sway` (now the world's
  "WindSway", `OutdoorProps.SWAY`) moves three kinds: bamboo clumps as before; leaves
  (`add_leaves`) lean downwind (+x, as the grass) by 0.06 x wind with a wave of 0.08 x wind and
  gusts about their base; cloth (`add_cloth`) hangs from its top edge, the hem blowing out from
  its face (0.35 + a flutter of 0.22, never back into a wall; free on both faces it swings both
  ways) and streaming downwind by a shear of 0.3 (so the top stays on its rod), by the square
  root of the wind (cloth is light: a fair festival day's 0.15 moves it like 0.39). Leaves and
  cloth stand still at wind 0. Pieces: the kadomatsu's five pine sprigs (with their snow) and
  its plum twig, each its own piece (`OutdoorProps.commit_swaying`); a leafy side shoot on about
  one farm fence post in five (`OutdoorProps.fence_spray`, one shared vertex-colour mesh a season,
  paler than the clumps' leaves so it reads against the grass, no snow skin); the shop noren
  (`MapWorld._village_house`) and the seed stand's noren (`OutdoorProps.sway_picture`,
  `FarmWorld._picture` now returns its mesh); each festival stall's curtain piece; the race
  banner below its hem. Posts, culms, the tub, rods, roofs and the stalls' valance stay still.
  `FarmWorld.set_wind` passes the wind on to child worlds (today's FestivalProps, a world of
  its own). Balance: the numbers are ours, small enough that a calm day barely moves leaves.
- Checked: all 29 test scripts print OK (0 failed); `test_weather: OK (0 failed)` with the new
  `_wind_on_leaves_and_cloth` (values seen once: a sprig's tip 0.007 / 0.027 / 0.064 sunny / rain /
  storm, a noren's hem 0.102 / 0.215 / 0.337, its hem z 0.000..0.252 in a storm (never into the
  wall), the banner 0.067 / 0.242 and 0.150 back, hinges and rod 0.000000, at rest again at 0;
  the fence 19 shoots and the posts' meshes still, kadomatsu 6 pieces (22 meshes) moving and 8
  still, a stall's 6 curtain pieces, one banner, the village's 2 shop noren). test_maps adjusted
  (the WindSway name, the kadomatsu's 6 snow skins, the fence's bounds 0.15 past the line).
  Smoke runs (title, --demo, --demo --map=town, --demo --mine=3, and --demo
  --festival=years_turn) logged 0 error / warning lines. Before / after frames (HEAD in a
  copy against this tree, frame 59): `--festival=moon_night --contest=fishing:wait
  --weather=storm` the banner streams out from the pole; `--map=town@sayo --weather=storm` the
  store's noren lifts out and leans (shorter on screen); `--weather=sunny` farm: a pale shoot on a
  fence post, nothing else on the fence changed; `--festival=years_turn` (always fair) the
  pixels that changed lie on the two kadomatsu's pine and the stalls' curtains;
  `--festival=blossom_day` the changes are at the stall's curtain.
- Left / next: the seed stand's noren was not in any frame (only tested). The kadomatsu
  barely moves on a fair festival day by design (leaves take the wind straight, not by the
  square root). The tall vine crops (cucumber, tomato) still take no wind.

## 2026-11-07 — Flat view: the farmer wears the FigureArt figure
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: `Player` (scripts/player/player.gd) no longer draws the circle-and-rect stand-in. It owns a
  FarmerAnim and a Sprite2D "Figure" (24 x 32 FigureArt via `PlaceholderArt.tex`, feet 2 px below the
  spot as VillagerView does, mirrored by the facing), stepped each frame from moving / running /
  tired / holding / fishing / eating exactly as Main3D does. The held item, rod line, fishing "!",
  charge pips and mine lantern are placed from the picture's rows (`hold_row`, `rod_tip`, `lantern_at`,
  `head_top`); the eat morsel and the stand-in rod are gone (the picture draws them). A soft contact
  shadow stays under the feet. Movement and collision (FEET, 16 px cells) untouched. main_2d's
  throw now starts at the raised hands. ART_DIRECTION section 4 note updated.
- Checked: test_view2d `_figure` (sprite is 24 x 32 FigureArt, offset, each facing's key / pixels /
  mirror, hold and eat poses); all tests and smoke runs (see the report); flat-view screenshots
  before and after at --demo, --hold, --tired.
- Left / next: fishing and mine-lantern placement in the flat view were not looked at in a screenshot.
## 2026-11-07 — Broadleaf trees on the bamboo hill
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: six broadleaf trees on the bamboo hill (data/maps/hill.json props): persimmons at
  [10, 3], [10, 8], [38, 14] and sakuras at [31, 3], [22, 13], [2, 11], each on free grass (not on
  the paths, the forage spots, the bamboo or pines, the lookout gravel, the shrine or the lanterns).
  Data only, no code. Maple is not a kind yet (Trees.LEAVES has persimmon and sakura only), so the
  set is those two; a maple would need a LEAVES entry in scripts/world3d/trees.gd.
- Checked: all 28 test scripts print OK (0 failed), test_maps, test_forage and test_showcase among
  them. Smoke `--headless --path . --quit-after 300 -- --demo --map=hill`: exit 0, no error or
  warning lines. Screenshots of `--demo --map=hill --season=fall` and `--season=winter --snow=80`
  (default spawn) show bamboo and the path only; no new tree is in those frames. To see the trees,
  three spawns were added to hill.json for a few runs and removed again (file restored byte for
  byte before the commit): fall persimmon red at [10, 8], fall sakura gold at [31, 3], winter bare
  sakura at [22, 13] with snow on the ground. Snow on the bare branches is faint at 480 x 270.
- Left / next: no maple (see above). Trees are not checked from the lookout spawn.
## 2026-11-07 — Run through exits, walk at once after a map change
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the user's second playtest round (docs/FEEDBACK.md → Fixed). Running: Player found a
  door or map exit 1 px past the blocked feet, but a blocked step leaves the feet up to one
  step short (running 1.7 px), so a run stopped at the edge; the look now reaches
  `1 + step.length()` px past the feet. The freeze after arriving: measured in a window,
  Game.map_arrived took 1210 ms on the village (EventPlayer.enter_map → EventTriggers.open,
  which ran the full EventRunner check of all 37 rows' events, dialogue lines and all).
  `EventTriggers.open(map, deep := false)`: the game's look-up checks only that each row's
  event file is there and keeps the table per map (`_kept`); `deep` checks every event as
  before (test_events uses it for every table; `check_row` and `new` stay deep by default).
  MapFade now lets go of the pause and calls Game.map_arrived() when the fade starts back
  from black, not when it ends.
- Checked: all 28 test scripts print OK (0 failed); smoke runs (title, --demo, --demo --map=town,
  --demo --mine=3) logged no errors or warnings. test_maps new checks:
  running into the village's west exit 0.2, 1.0 and 1.6 px short of the edge goes through
  (with the old look 1.0 and 1.6 failed: "FAIL: walking: running into the village's west exit
  1.0 px short of the edge goes through ([], running true)"); the farmer may walk while the
  fade comes back. test_events: each table's quick look-up has the deep check's rows and is
  kept. In a window (throwaway script), farm → village holding right: the farmer moved from
  t=0.47 s after the door (was 0.88 s, with a 7 fps frame on arrival); no frame under 60 fps
  after arriving.
- Left / next: nothing open from this round.
## 2026-11-07 — Smooth map changes, no getting stuck
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the user's own playtest (docs/FEEDBACK.md → Fixed). Map changes: measured in a window,
  a build took one frame of 35 ms (house) .. 240 ms (farm), and MapFade's tween took that long
  frame as one step, so the picture popped back half faded and the stutter showed. MapFade now
  runs in _process: each step at most 1/30 s (OUT 0.2 s, IN 0.25 s), black kept HOLD_FRAMES 3
  frames after the swap (the build, the first draws and shader compiles), and a change during
  the hold or the way back goes dark and swaps again (the old tween lost it). Main3D keeps up to
  KEEP_WORLDS 6 worlds built today out of the tree (`_worlds`, keyed by `world_key`: the MapData
  instance (new when gates change), the farm, the date, the weather, the snow); per-visit layers
  (festival props, villagers, forage, animals, mine rocks) are made fresh each visit; a kept
  FarmWorld is `away` and only marks field changes stale (`come_back` catches up); a new day
  drops them; mine floors are never kept. Walking (Player): a straight walk blocked by a corner
  slides sideways up to 8 px (half a cell) or past a villager up to 12 px into the free way
  (`_slide`, only when the input is mainly one axis); a solid cell the feet already touch never
  blocks (`_free`), so nothing that comes over the feet can trap the farmer.
- Checked: all 28 test scripts print OK (0 failed); test_maps new `_walk_slide`, `_fade_steps`
  (a 1 s hitch moves the fade one small step, swap at black, 3 black frames, a second change
  swaps again) and `_kept_worlds` (the farm world waits out of the tree, a till marks it stale,
  back on the farm the same world with one fresh set of villagers, the house kept in turn, a new
  day builds anew). Smoke runs (title, --demo, --demo --map=town, --demo --mine=3) logged no
  errors. Timing in a window (a throwaway script, not kept): town → store → town: town 118.9 ms
  first, 1.1 ms back; farm 227.9 ms first, 1.8–2.8 ms back. Memory with 6 kept worlds: 143 MB /
  video 61 MB, against 115 / 40 MB keeping none.
- Left / next: a first visit still builds in one frame (now under black); the farm's buildings
  (~160 ms) are the dearest part if it needs to go faster. Not tried by hand with a pad.
## 2026-11-07 — Larger, more detailed farmer and villager figures
Agent: Claude Code (claude-opus-5-5) · Commit: d2d8064
- Done: docs/ART_DIRECTION.md section 4 item 1 (the user chose code-drawn placeholders refined
  by the agent for now). New `scripts/art/figure_art.gd` (FigureArt) draws the farmer and every
  villager as 24 x 32 figures (were 16 x 24), part by part back to front, each part with its own
  1 px outline (so a near arm reads against the body), light from the upper left (a darker right
  side, a lighter upper left). Own designs in Japanese country clothes: the farmer in an indigo
  noragi with kasuri flecks, a white collar band and a straw rope belt, slate monpe gathered at
  the ankle, dark jika-tabi, a red tenugui knotted behind, a straw hip basket; villagers' kimono
  (white under-collar V, obi with a cord, the drum bow on the back, wide sleeves, tabi and zori),
  happi (collar band, a crest on the back) over trousers, shirt and shorts; hair bun with a pin,
  short, hachimaki, long and tied, a wide straw hat. New look field `build` (data/villagers):
  elder (Tome, Kiku, Genzo: the head a pixel forward and lower) and child (Kota, Nana: shorter).
  Directions: four from two drawings, as before (front three-quarters to the lower left, back to
  the upper left, mirrored for Right / Up); eight would need diagonal facings that the grid
  rules do not have, so not done. Every pose kept with the same keys and frame counts (walk,
  run, tired with heavy lids and sweat, hold with the hands at the head's top, fish with the
  bamboo rod, eat / drink at the mouth, the villagers' hammer and rod). PlaceholderArt keeps
  its calls (`farmer_frames`, `rod_tip`, `farmer_drop`, `lantern_at` (now with `back`: the
  near hand is screen right from the front, screen left from the back), new `hold_row`,
  `villager_top`, `FIGURE_SIZE`, `VILLAGER_BUILDS`). Sizing: `FarmWorld.FIGURE_PX` 0.04 and
  `make_figure` for the farmer's and villagers' Sprite3Ds, so the farmer stands about 1.17
  units (was 1.08), still under the 1.45 eaves; a sprite pixel is about 1.5 screen pixels at
  the medium lens. Main3D places the held item, lantern and rod line from the figure's size;
  the bite "!" at 1.3 and the charge pips at 1.38 clear the taller head. VillagerSprites /
  VillagerView put a carried item and the whistle note on top of each head (a child's is
  lower); the flat view stands the 32 px villagers' feet where the 24 px ones stood. The mochi
  screen places both figures by their feet. Shadows and animals untouched (other agents).
- Checked: test_villagers `_figures` (new: 24 x 32; all 270 figure keys drawn, standing on the
  bottom row; the four facings are four different pictures; a face (eye colour) only from the
  front; children shorter than Hachiro and their head lower, adults taller than 24 px, Tome
  lower than Sayo; the farmer 1.08..1.45 units; `make_figure` at FIGURE_PX with the feet on the
  ground; every look's build known), test_hold (hands up at the head's top, bobbing), test_mine
  (the lantern inside the frame from both sides), test_farm / test_fishing / test_food at the
  new size. Before / after frames: `--demo`, `--demo --map=town --time=10:00`, `--talk=tome`
  (`--map=town --time=14:30`), `--hold`, `--fishing`, the flat view of town, `--mine=3 --tired`
  (the lantern in the near hand, sweat), `--eat`, the mochi pounding: feet on the ground, the
  held turnip on the hands, the line from the rod tip, Kota a child under his straw hat.
- Left / next: eight directions; the flat view's farmer is still the drawn stand-in (circles)
  and its villagers are 2 cells tall there; real art can replace the keys later.
## 2026-11-07 — Real sun shadows for the figures
Agent: Claude Code (claude-sonnet-5-5) · Commit: f261048
- Done: docs/ART_DIRECTION.md section 4 item 3: real shadows won over blobs. Finding: a Sprite3D
  billboard cast from a quad turning with the camera (a thin smudge on the farmhouse deck behind
  the farmer in the morning), so `FarmWorld.make_sprite` now sets `cast_shadow` OFF for every
  sprite. New `SpriteShadow` (scripts/world3d/sprite_shadow.gd) is a child of the figure's sprite:
  a shadows-only quad wearing the sprite's own picture (alpha scissor; size, offset, flip and
  texture read at runtime, so any redrawn sprite fits), turned square to the sun's horizontal
  heading (`face_yaw`; `Main3D._aim_sun` feeds `SpriteShadow.sun_yaw`, `_show_shadows` the
  strength), so the sun's shadow map throws the real silhouette in the same direction as the
  buildings' shadows. Plus a soft blob at the feet, sized from the sprite's opaque width: at
  `blob_in_sun` (0.35) of its strength under full sun shadows, whole where there are none (rain,
  snow, dusk, night, rooms, the mine). Used by the farmer, villagers, animals, the dog (the old
  per-class blobs and animal SHADOW sizes are gone) and, caster only, the field's object sprites.
  The switch: data/light.json "sprite_shadows" ("mode": "real" or "blob", blob numbers);
  `-- --sprite-shadows=blob` for one run.
- Checked: frames of `--demo` (7:00, 12:00, 17:30), `--demo --map=town` (8:30, 12:00, 17:30,
  real vs `--sprite-shadows=blob`, difference image), `--map=farm@barn --barn-out`, rain, 19:00,
  `--map=house`. Real reads right: long to one side in the morning and evening, short at noon,
  the sheep and the farmer shadowed on the barn's ground; in rain, at night and indoors the blob
  alone. test_weather `_sprite_shadows` (data, blob share by sun, the caster facing the sun at
  four poses, sizes from the texture, flip / picture / strength follow, blob mode, crops without
  a blob) and test_maps `_sprite_casts`. All tests/test_*.gd OK (0 failed); smoke runs (title,
  --demo, --demo --map=town, --demo --mine=3, --demo --map=barn) with no errors.
- Left / next: shadows are soft-edged blobs at 480 x 270 (the shadow map is smooth); a villager
  or the farmer in a roof's shadow shows no extra. Tall CropClusters (rice, corn) and the flat
  view cast / draw nothing new. The larger character and animal sprites (item 1 and 2) remain.
## 2026-11-07 — Animals redrawn: denser pixels, four facings
Agent: Claude Code (claude-sonnet-5-5) · Commit: 36d42c6
- Done: docs/ART_DIRECTION.md section 4 "Animals in the same style". New `scripts/art/animal_art.gd`
  (AnimalArt) draws hens, chicks, cows, calves, sheep, shorn sheep, lambs and the dog in code at
  `SCALE` = 2 times the farmer's pixel density (cow 52 x 38, sheep 40 x 32, dog 30 x 24, hen
  30 x 28, chick 18 x 16 art pixels), in three tones lit from the upper left, a wool cloud of
  curls, a udder, horns, pricked shiba ears with cream cheeks and chest, a hen's comb / wattle /
  scalloped wing / tail fan. Keys keep `animal:<kind>:<pose>:<frame>` and take an optional fifth
  part, the facing `dl` (default), `dr`, `ul`, `ur`: front or back 3/4 for the diagonal camera
  (the right ones are the left mirrored; seen from the front the face shows, from behind the ears,
  rump and tail), the figure tilted a little by a shear so the near end stands lower. Poses
  unchanged: idle (frame 1 lifts the head, flicks an ear), peck, walk, sick (lying, dull, eyes
  shut), dog sit; wool / shorn / young by kind. `AnimalLayer` sets `pixel_size = PX / SCALE` (same
  world size), faces beasts and the dog by their step (`AnimalArt.facing_of`) instead of flipping
  the sprite; `AnimalView` (flat) draws at half size. The dog held in the arms stays the old
  14 x 11 picture (it is drawn by Main3D / Player at the farmer's pixel size, not touched here).
  Shadow code untouched.
- Checked: test_animals (new `_animal_art`: every kind x pose x frame x facing draws at its size
  and stands on the bottom row, right = mirrored left, up differs from down, sick / walk / graze
  differ, relative sizes, facing from steps; the old size checks updated). Screenshots of
  `--map=coop`, `--map=barn`, `--map=farm@coop --hens-out`, `--map=farm@barn --barn-out` before
  and after: the new animals read clearly at 480 x 270. All tests and smoke runs: see below.
- Left / next: no "brushed" look (the layer does not show it; the old art did not either); the
  eight-frame walk and a lying cow beyond "sick" are not drawn; fish are items, not creatures.
  Section 4 still has the farmer / villager sprites and the shadow decision.

## 2026-11-07 — Roof snow without patch holes
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the long-open "patch holes" in the roof snow. Root cause: `SnowLayer.TOP_SHADER` (the
  snow tops on every roof, lid, cap and pad) fed the ground's raw `cover` into the ground's
  equalised noise, which by design leaves 1 - cover of the pixels bare, in clumps a few cells
  wide (the noise tile spans 8 cells). Right for a field at 0.8; on a 5 x 3 roof one of those
  bare clumps is a hole torn in the snow, with the grey tiles showing through (town@store at
  snow 80 had a hole over a third of the roof's width). Not the geometry, the normals, the
  see-through fade (it hides snow tops whole) or a renderer pitfall: the top shader reads no
  COLOR or INSTANCE_CUSTOM, and `world` comes from MODEL_MATRIX. Fix: snow tops take
  `min(cover / top_full, 1.0)` as their amount (`SnowLayer.TOP_FULL` = 0.5, set as the
  `top_full` uniform by `top_material()`; GDScript twin `top_amount`). So from half cover up
  roofs read as one even cover, and below it they thin in the same ragged patches (at snow 30
  about 57 % white plus the rim, the ground about 24 %), as snow melting off a roof. Our number: 0.5, so a roof is
  whole once half the ground is white (a snowy day lays 50, data/snow_cover.json "fall"). The
  ground, the flat view and the tufts' and crops' snow are unchanged (`_SNOW_AT` untouched).
- Checked: test_weather (new: on the noise image, roof snow is 100 % white at cover 0.8 and at
  TOP_FULL; the ground at 0.8 keeps bare patches; the ground at 1.0 is all snow; at 0.3 roofs
  are part bare yet whiter than the ground; the material carries top_full and the shader the
  clamp). Before / after frames of town, town@store, kaminoda@well and the farm at snow 80 and
  30: at 80 the town roofs' holes are gone, the farmhouse thatch and lids fully white; at 30
  roofs show patches, the ground looks the same as before. All tests OK, smoke runs clean.
- Left / next: nothing for the roof snow. The flat view's roof overlay (`roof_mask_image`,
  "roofs" 0.7) still uses the ground's pattern; not touched here (another agent's area).

## 2026-11-07 — Villagers and the dog part the grass and crops too
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: `Parting`'s `farmer` uniform is now `pushers[8]` plus `pusher_count`; `part_push`
  sums each pusher's push (same smoothstep math) and limits the total to `bend`, so the farmer
  alone looks exactly as before. `Parting.push_all` mirrors it in GDScript, `Parting.pick` takes
  the farmer first and then the others nearest them up to `max`, `Parting.feed` sets a material.
  The villagers' sprites (VillagerSprites) and the dog's (AnimalLayer) are in the group
  `Parting.GROUP`; `FarmWorld.set_farmer` (still the one line in Main3D._process) collects the
  visible ones of its own world and feeds the map's and apron's tufts and every crop picture
  (`set_farmer` on GrassTufts / CropClusters became `set_pushers`). data/wind.json "part".max = 8
  (the shader's array size; the cap is rarely met in a village).
- Checked: test_maps `_parting` extended (max in data within the array; farmer alone unchanged;
  a villager parts like the farmer; out of every radius stands; summed pushes never exceed bend;
  pick: farmer first, nearest next, capped; a figure in the group is a second pusher in a real
  MapWorld, a stray or hidden one is not; the sprites join the group). All tests/test_*.gd OK
  (0 failed); smoke runs (title, --demo, --demo --map=town, --demo --mine=3) with no errors or
  warnings. Screenshots `--demo --map=town --time=10:00` and `--map=kaminoda@well --time=8:30`
  render fine, but no villager stood in grass close enough to show a bend at 480 x 270.
- Left / next: the visible bend round a villager was not seen in a screenshot, only checked by
  the shader math in tests; the barn yard cows and sheep do not part anything.

## 2026-11-07 — Flat view: ripple rings round the bobber
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: `WaterView.ripple(pos, strong)` (scripts/world/water_view.gd) mirrors `WaterSurface.ripple`:
  eight slots in a uniform array read by the same shader loop, in map pixels (a cell's centre is
  (cell + 0.5) x 16), one pixel wide, 14 px a second (strong 1.3 times, to 34 px; gentle to 22 px),
  two fade steps. Lives RING_LIFE 1.5 s gentle, RING_LIFE_STRONG 1.9 s strong. The shader's ring
  test runs first, the glints and troughs after it. `advance()` moves its clock (`_process` calls it).
  `main_2d.gd` `_ring_bobber(delta)` (called in `_process`) mirrors `Main3D._ring_bobber` with the
  same timing: a strong ring as the line goes out and as a bite starts, 0.4 s between strong ones in
  a bite, a gentle one every 1.7 s while waiting. It reads the view's sheet as `view.get("_water")`
  (FarmView and MapView both keep it there), so a map with no water does nothing.
- Fixed on the way: the shader's `return` in the fragment function was refused by the compiler
  (Godot allows none there); the ring branch is now an if / else.
- Checked: test_view2d prints `test_view2d: OK (0 failed)` (the cast gives one strong ring over the
  pond in `_fishing`; `_ripples`: a call fills slot 0 gentle and slot 1 strong, the uniform array
  has eight entries, both expire after RING_LIFE and RING_LIFE_STRONG). All 28 tests/test_*.gd print
  OK (0 failed). Smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, and
  `res://scenes/main_2d.tscn -- --demo --fishing`) print no errors. Screenshot of the flat view with
  `--demo --fishing`: the rings show round the red bobber on the farm pond, pixel-crisp, banks and
  foam still (checked by a 6x crop of the last frame).
- Left / next: the flat view's bobber cadence is checked by reading, not by a timed test. The farmer
  does not ripple the water at the feet (the farmer never wades, as in 3D). The ring constants are
  copied from the 3D sheet, not read from data (as the water's other constants are).

## 2026-11-07 — Grass and rice part round the farmer
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: new `Parting` (scripts/world3d/parting.gd): a GLSL `part_push(root)` included in the
  grass tufts' and the crop clusters' shaders and the same math in GDScript (`Parting.push`)
  for the tests. A plant whose root is within `radius` of the farmer's feet has its tip pushed
  straight away and lowered by `dip` x the push; full bend within `full` x radius, easing to
  nothing at the radius by a smoothstep (and to nothing right under the feet, so a root there
  can't flip). By distance alone, so the plants spring back as the farmer walks on. The feet
  go in a `farmer` uniform: `Main3D._process` calls `FarmWorld.set_farmer(sprite.position)`
  (one line), which feeds the map's tufts, the apron's tufts (`Surroundings.tufts`, now kept)
  and every crop picture's material (`CropClusters.set_farmer`, also on the shared material so
  pictures made later start right). Tufts turn the push from world into their own turned and
  sized space; crops into the billboard's camera axes. Numbers in data/wind.json "part":
  radius 1.0 (the cells beside the feet bend, the next ones stand), full 0.3 (the plants the
  farmer's sprite hides are not the ones that show it, so the ease-out falls just beside the
  feet), grass bend 0.18 (a tuft is 0.15..0.3 high: at 0.12 a tuft beside the feet moved under
  a pixel at 480 x 270), crops 0.22 (a rice hill or corn stalk is 0.8..1.2 high, so a lean of
  about a fifth reads without flattening the cluster), dip 0.45. Villagers and the dog don't
  part anything (not done).
- Fixed on the way: the grass tufts' tips never moved. Their height share was the mesh's vertex
  colour red, and under the Compatibility renderer a MultiMesh without instance colours reads
  COLOR as black in the vertex shader (checked by painting COLOR.r into the tufts: all blue),
  so the sway, the wind and the tip colour were all at the root's values. The share is now the
  UV's y. So the tufts now really sway with data/wind.json, and their tips are a little lighter
  (the tip colour, not 80% of it).
- Checked: test_maps `_parting` (data in range; Parting.rules reads it; nothing from the radius
  out; pushed straight away in four directions; full near the feet, easing with no step over
  0.012 a hundredth of a cell; nothing jumps right under the feet; both shaders include and
  call part_push; FarmWorld.set_farmer reaches the map's and apron's tufts and every crop
  material with their own bend / radius / full; a crop picture made later has the feet).
  A deliberately wrong `full` in the data made it print one FAIL. After `--import` all 28
  tests/test_*.gd print `OK (0 failed)`; smoke runs (title, `--demo`, `--map=town`,
  `--mine=3`, `--map=kaminoda --season=summer`, `--season=winter --map=kaminoda --snow=80`)
  print no error or warning. Screenshots with a scratch script standing the farmer on a cell,
  bend 0 against the data's: in a Kaminoda paddy in summer the rice in front parts and shows
  the farmer's shirt and legs (1254 pixels changed, all in x 198..280, y 89..132 round the
  farmer); on the farm's grass a tuft by the feet lies over away from them; winter snow 40
  still folds tufts away, no shader errors under the GL renderer.
- Left / next: villagers and the dog don't part the grass; the parting has no lag or wobble
  (it follows the feet exactly); the flat view is unchanged.

## 2026-11-07 — Bamboo: the New Year bamboo and the farm fence as lit meshes
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: `FarmWorld._make_fence` no longer uses cylinders and boxes in MultiMeshes: new
  `OutdoorProps.pole` (a bamboo pole with node rings), `fence_post` (eight-sided culm, cut top
  with a dark hollow, two cord ties, snow cap), `fence_cane` and `fence_rail` (a node ring every
  half cell, snow on the upper rail); one `Parts` commit, same posts, canes, rails and gate cut
  as before. `FestivalMeshes.kadomatsu(w, mid, snow)` rebuilt: straw tub with cord bands and
  frayed straw, three bundled culms (1.3 / 1.05 / 0.85) with node rings and slanted cut faces,
  a straw wrap with cord turns, five pine sprigs, a plum twig, snow on tub and sprigs where the
  map has snow (`FestivalProps` passes `SnowLayer.map_has_snow`).
- Checked: test_maps `_bamboo_pieces` (fence with and without a gate: only ArrayMeshes, lit,
  faces out, on its line, 0.64..0.72 high, nothing in the gate cell, snow skin driven by
  set_snow; kadomatsu with and without snow: faces, three cut faces, node rings, 1.3..1.45 high,
  inside its cell); all tests/test_*.gd print OK (0 failed); smoke runs clean; screenshots of
  `--demo`, `--demo --season=winter --snow=80`, `--demo --festival=years_turn` (also in snow)
  looked right (the window renders 480x270, so details are small).
- Left / next: the fence and kadomatsu take no wind; the fence is about 80k triangles in one
  mesh (fine so far, a MultiMesh of a post would be the way to cut it).

## 2026-11-07 — Flat view: moving water on the pond and river
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: `WaterView` (scripts/world/water_view.gd), a Sprite2D over the water cells in the flat
  view: FarmView's pond and MapView's water (village pond, river), added under the objects and
  left out where a map has no water. One pixel per map pixel, alpha on the water pixels only, so a
  land side keeps its 2 px bank and 1 px foam line still (inset 3 px, as the 3D sheet's
  LAND_INSET). Shader: the 3D sheet's drifting glint and trough pattern, sampled at the pixel
  centres (pixel-stepped), same speeds, thresholds and colours; alphas 0.3 / 0.2 (3D 0.5 / 0.32)
  because the flat view has no sun term. Constants copied from water_surface.gd (not in data).
  The 3D water, grass tufts, crop clusters, outdoor props and festival meshes are untouched.
- Checked: test_view2d `_water` (one sheet per water cell; every pixel of the sheet matches the
  rule, banks and foam left still on the farm pond and the town's water; the shader uses TIME).
  test_maps needed its flat snow check to skip the WaterView (it is a Sprite2D). After `--import`,
  all 28 tests/test_*.gd print `OK (0 failed)` (animals, audio, body, cooking, dialogue, ending,
  events, farm, festivals, fishing, food, forage, goals, hold, inventory, lang, maps, menu, mine,
  relationships, save, shops, showcase, talk, title, view2d, villagers, weather). Smoke runs
  (title, `--demo`, `--map=town`, `--mine=3`) print no error or warning; `res://scenes/main_2d.tscn
  -- --demo` writes frames. The first render's glints were too strong (a pale blue block on the
  pond), so the alphas went down. Pond crop frames 5 and 19 differ in 222 of 2376 pixels (it moves).
- Left / next: the flat view has no rings (bobber ripples) yet; the village pond was off-screen in
  the one town frame checked (the test covers it, no screenshot of it); no frozen water in winter.

## 2026-11-07 — Village house variety: hip roofs, two storeys, three wall finishes
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: a `village_house` prop may set `roof` (gable / hip), `storeys` (1 / 2) and `wall`
  (plaster / yakisugi / timber); `LitSpots.village_style` reads them (unset = the old look).
  New `Minka.hip`: a kawara hip roof (one pitch all round, eave band, soffit, snow, tile rolls
  on all four slopes stopped at the hips, a tiled crest down each hip) and `hip_ridge_ends`.
  Two storeys: a tiled pent roof (a Minka.hip whose top hides inside the upper floor), the
  upper floor 0.3 in from the walls up to 2.9 with the main roof on it, upstairs shoji in
  LitSpots (lit at night, both views). Walls: plaster over a board skirt (as before), yakisugi
  (charred boards up to a plaster band), timber (new `build:tsuchi` earthen plaster, a post at
  every cell edge, a rail over the windows). `_village_house` split into `_house_walls` /
  `_house_roof`. Data: town (Tome hip / timber, smithy 2 storeys / yakisugi, clinic hip, Kota
  yakisugi, Sayo's store unchanged as its sign stands on the roof), Kaminoda (hip / timber,
  yakisugi), Minamino (2 storeys, hip / yakisugi), Sakurazaka (teahouse hip / 2 storeys,
  timber). `tools/house_model.gd --what=village --style=roof:hip,storeys:2,wall:timber`.
- Checked: test_maps `_hip_roof` (faces wound right, upright faces outwards, eave 1.45, ridge
  height, nothing past the eave line, rolls and hips at most 0.13 off the roof, rolls on the
  hip ends, snow) and `_village_styles` (all 12 roof / storey / wall combinations: faces,
  front eave, windows = LitSpots with 3 upstairs for two storeys, snow per roof, one fading
  thing as tall as the house; every map house's fields known, the mix covers every value,
  the store stays a one-storey gable; upper windows between the pent roof and the main eave's
  shadow line). After `--import` all 28 tests/test_*.gd print `OK (0 failed)`; smoke runs
  (title, `--demo`, `--map=town`, `--mine=3`, `--map=sakurazaka`, `--map=minamino`,
  `--season=winter --map=kaminoda --snow=80`) print no error or warning. Before / after
  screenshots at town@tome / smithy / clinic / kota / sayo, kaminoda@genzo / haru,
  minamino@shige / kiku, sakurazaka@teahouse / ichiro, 20:00 and winter snow 80: the hip roofs
  read with their hip ends, the two-storey houses with pent roof and upstairs windows (lit at
  night), dark yakisugi and ochre timber walls read apart from white plaster; snow lies on the
  hip ends and pent roofs. house_model front / left / back views of hip and two-storey looks.
- Left / next: the roof snow still shows the top shader's patch holes (as before); upstairs
  window pools land on the ground under the pent roof; the flat view's houses are unchanged
  (only their upstairs window glows are new).

## 2026-11-07 — Merge: village house variety, water ripples, wind by weather
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three art-direction agents in parallel worktrees, models picked by difficulty:
  ec260e8 village houses with hip roofs, two storeys and yakisugi / timber walls (Opus),
  8e00c11 ripple rings round the fishing bobber (Sonnet), 4297f2b the grass tufts and bamboo
  sway following the weather through data/wind.json (Haiku). WORKLOG conflicts resolved by
  keeping every entry; ART_DIRECTION, test_maps and main_3d.gd auto-merged.
- Checked: on merged main, `--import` exit 0; all 28 tests/test_*.gd print `OK (0 failed)`;
  smoke runs (title, `--demo`, `--map=town`, `--mine=3`, `--season=winter --map=kaminoda
  --snow=80`, `--fishing=wait`) print no error or warning. No new screenshot on merged main.
- Left / next: the agents' open notes (roof snow patch holes, no ring at the feet or rain
  dimples, banners and vines take no wind); ART_DIRECTION section 4 (characters) waits on the
  user's decision on who draws.

## 2026-11-06 — Water: ripple rings round the fishing bobber
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: WaterSurface gets `ripple(at, strong)`, `advance(delta)`, `ripples_alive()` and a uniform array
  of eight rings (x, z, start time, life; negative life = strong) with its own clock. The shader draws a
  ring one pixel wide, its radius stepping whole pixels (14 px/s, strong 1.3x and wider), alpha in two
  fade steps; it is part of the same sheet, so it keeps the bank inset, the ground light and the pixel
  grid. `Main3D._ring_bobber` (called from `_show_fishing`) starts a strong ring as the bobber lands and
  as a bite begins, a gentle one every 1.7 s while waiting, a strong one every 0.4 s while biting.
  No ring at the farmer's feet: the farmer never wades (water cells are blocked). Flat view unchanged.
- Checked: screenshots `--fishing=wait`, `--fishing`, `--fishing=river:wait` and
  `--festival=moon_night --contest=fishing:auto` (frames 300 / 450 / 600): pale pixel rings spread round
  the float, clipped at the bank, dimmed at night, bite shows a double ring. test_maps `_water` has new
  checks (slots, strength, life, reuse of the oldest, the shader's clock). Main3D cannot load in a
  headless script, so the bobber hookup is checked by the screenshots only.
- Left / next: no ring at the feet; rain does not dimple the water; the flat view's water is still.

## 2026-11-06 — The wind follows the weather (grass tufts and bamboo)
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: `data/wind.json` gives a strength 0..1 per weather look (sunny 0.15, rain 0.5, snow 0.3,
  storm 1.0, blizzard 0.9; there is no cloudy weather in weather.json). `Game.wind_strength()`
  reads it by today's look (`Game.wind_for`, a winter storm is a blizzard). `Main3D._show_weather`
  pushes it each morning and on a map change (0 when sheltered) through `FarmWorld.set_wind`:
  the grass tufts' shader gets a `wind` uniform (tips swing about 1 + 1.5 x wind times as far,
  the wave runs faster, a slow gust swell and a flutter, a small lean downwind), and the bamboo
  sway (`OutdoorProps.Sway.wind`) gets the same lean, speed and gusts on the CPU. Wind 0 is the
  old motion. Water, houses and fishing files untouched.
- Checked: test_weather `_wind_by_weather`: every weather look has a strength; sunny < rain <
  storm; calm, medium and strong from the data; a winter storm reads the blizzard strength; the
  tufts' uniform set and reset; over 60 s the bamboo's reach is larger in rain than calm and in a
  storm larger again (more than 2.5 times calm), and it turns more often; no wind keeps the old
  amplitude; FarmWorld.set_wind sets both, and a sway made after it takes the wind. The test waits
  one frame (the world scripts need the Game autoload). `--import` ran clean. `test_weather: OK (0
  failed)`. All 28 tests/test_*.gd print `OK (0 failed)`. Smoke runs (title, `--demo`,
  `--demo --map=town`, `--demo --mine=3`) print no error or warning. Screenshots
  `--demo --map=hill --weather=storm --no-flashes` and `--weather=sunny` (last frames): storm shows
  rain on the hill with the bamboo at the right and the grass; the still frames show no clear
  difference in the sway, which only moves in time, so the visible change is checked by the test.
- Left / next: a short clip (Movie Maker, a few seconds) would show the storm's sway and gusts;
  the banners, noren and the tall vine crops do not take the wind yet.

## 2026-11-06 — Merge: mountain backdrop, shared washi-and-wood UI, snow on bare branches
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three art-direction agents in parallel worktrees, models picked by difficulty:
  6c5e66f far mountain ridges and haze past a rim on the outdoor maps (Opus; finishes the old
  c8e1ed0 attempt), fba992d one shared UI style UiStyle with richer paper and wood frames
  (Sonnet), 7f5fad1 snow on the bare winter branches of persimmons and cherries (Haiku).
  WORKLOG conflicts resolved by keeping every entry; test_maps and ART_DIRECTION auto-merged.
- Checked: on merged main, after `--import`, all 28 tests/test_*.gd print `OK (0 failed)`;
  smoke runs (title, `--demo`, `--map=town`, `--mine=3`, `--season=winter --map=kaminoda
  --snow=80`) print no error or warning. Screenshot `--demo --season=winter --map=kaminoda@hill
  --snow=80`: the new HUD frames, a grey snow-capped ridge at the top right; the persimmon's
  branch snow is only a few pale pixels on the limbs at 480 x 270 (faint).
- Left / next: the ridges show only near north / west map edges; the branch snow is very
  subtle at game size; ART_DIRECTION section 4 (characters) waits on the user's decision on
  who draws.

## 2026-11-06 — Snow on the bare winter branches
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: `Trees.broadleaf` takes `snow` (default off). In winter, bare persimmons and cherries get
  a thin lit sheet over the upper side of each limb and twig (`Trees._branch_snow`, a quad with
  its normal up off the limb, lifted 0.008 off the wood, 1.3 times the limb's width, from a tenth
  along to 0.95). The sheet uses `Parts.SNOW`, so its amount is set by `set_snow` like the pads'
  (SnowLayer's top shader). CountryProps passes `SnowLayer.map_has_snow(w.map)`, so the
  outdoor maps with a persimmon or cherry get it when snow lies; the farm and rooms get none.
  Festival cherries unchanged.
- Checked: test_maps `_trees` adds a loop: persimmon and sakura, seeds 3 and 40, winter with snow
  (one snow mesh driven by `w._snow_mats`), winter without snow and spring with snow (none); the
  look checks (faults, reach, height) hold. `--import` ran clean. `test_maps: OK (0 failed)`.
  All 28 tests/test_*.gd print `OK (0 failed)`. Smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`) print no error. Screenshots `--demo --season=winter --map=hill --snow=80` and
  `--snow=0` show snow on the ground only: the hill has seven pines and bamboo, no broadleaf tree,
  so the new sheets are not in those frames. `--map=kaminoda@well` (snow 80 / 0) shows the
  village but no persimmon in frame; the branch snow is not seen in a screenshot yet.
- Left / next: a close-up screenshot of a bare persimmon (kaminoda's or minamino's) with snow 80
  to see the sheets; the hill has no broadleaf, so a tree there would need map data.

## 2026-11-06 — UI pass: one shared washi-and-wood look
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: the UI was already paper and wood, but each of nine files (HUD, text box, pause, shop,
  rucksack, cooking, mochi, race, title) built its own NinePatchRect and kept its own colour
  literals. New `scripts/ui/ui_style.gd` (UiStyle): `panel()` / `panel_at()` and the shared inks
  (INK, INK_SOFT, INK_OFF, RULE, BAR, PAPER_TEXT, SEAL, WASH, DIM); every screen now builds its
  panels through it and Hud / screen constants alias it. The frame art `ui:frame:paper|wood`
  (`PlaceholderArt._ui_frame`) is a 32 x 32 nine-patch, border still 4 px so no layout moved, with
  a 24 x 24 centre that tiles without seams: washi paper with speckle and long pale fibres, wood
  with plank seams and grain; the dark wood border has a bevel and grain dashes. Fixed seeds.
- Checked: before / after screenshots of `--pause`, `--rucksack`, `--shop=general`,
  `--dialogue=opening@field`, `--cook`, the title, `--pause --ui=150%`, `--shop=general --lang=th`
  (the paper now shows fibre, text fits as before). New test_menu `_shared_style` (no screen builds
  its own panel or names frame art, panels tile with a 4 px border, shared inks, washi centre
  stays light); test_farm's frame pixel check relaxed to lightness bands. All 28 tests/test_*.gd
  print `OK (0 failed)`.
- Left / next: pixel-art slots, cursor and icons are unchanged; the ending scroll and mochi stage
  keep their own art and a few literal colours (stamina fill, trodden ground).

## 2026-11-06 — The far country: mountain ridges and haze past a rim
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: ART_DIRECTION section 3's optional backdrop, after the user's go-ahead; finishes the
  in-progress branch c8e1ed0 (its path / samples / peak helpers kept, the rest rewritten).
  The fix for "the ridges never reach the frame": the medium lens looks 16 degrees down at the
  frame's top, so nothing standing on level ground more than ~10 cells past the farmer can show.
  So on the seven outdoor maps of `data/backdrop.json` (farm, town, hill, kaminoda, sakurazaka,
  minamino, river) Surroundings stops the land past the north and west edges after a 3-cell rim
  (`back`; the south / east apron keeps its 14) with a thinner wood there (25 % of cells, not
  45), and Backdrop (`scripts/world3d/backdrop.gd`) puts two ridge layers 18 and 34 cells out and
  below the ground's level (peaks -3.6..-6.4 and -8.6..-12.8): from within a few cells of the
  back edges the frame's top corners look over the rim down onto them, with sky above the peaks.
  Flat (unshaded) walls with alternating facet tones, a small shader: the season's colour, hazed
  with `Game.sky_color` (the far layer 0.55, the near 0.3; the clear background is the same colour,
  so dawn, dusk and night carry over), the feet fading into the sky's colour like mist, a jagged
  snow line by season (`caps`: winter 0.6, spring 0.25). Refreshed on minute_passed / day_started.
  WaterSurface.build takes the shorter back margin. Not in rooms, the mine or its cave mouth
  (`mine` keeps the full wood). The camera is unchanged. Numbers were picked with a projection of
  the medium lens (the rim's line of sight at the clamp is about -6.7 at 18 cells out, -13.7 at 34).
- Checked: test_maps `_backdrop`: the map list (and none for house, mine, mine_floor, store,
  clinic), the town's land stops at the rim with no pine past it, the ridge points past the rim
  and below the ground, winter caps / none in summer, season colour and sky haze, the haze equal to
  Game.sky_color after refresh, the far layer hazier, and through CameraLens "medium" with the
  target at Main3D's clamp on the north edge, the west edge and the corner: peaks of both layers
  in the 480 x 270 frame over the rim's line of sight, some with sky above; none from the
  middle of the village; the house and the mine keep their land. (Lowering the near layer to
  -8.6..-9.4 makes it fail: "near 0 peaks".) After `--import`, all 28 tests/test_*.gd print `OK (0 failed)`. Smoke runs (title, `--demo`, `--map=town`, `--mine=3`, `--map=mine`, `--map=river --season=winter`) print no error or warning.
  Screenshots (480 x 270 movie frames): `--demo --map=town@north` pale blue ridges with a spring
  cap at the top right between the pines; `town@tome` at 10:00 ridges at the top left, at 17:40
  pink with the dusk sky, at 21:00 dark under the night tint; `--season=winter --snow=80`
  (town@north, kaminoda@hill) snow-capped grey ridges; `--demo` (farm start) and `farm@coop` show
  none (the pines and buildings fill the top there); `hill@top` none (the hill's own wall).
- Left / next: the ridges show only near the north and west edges (by design: the lens cannot
  see a horizon); the cut rim reads as a crest, roads running north end there; no flat-view
  backdrop. Section 4 (characters) next, needs the user's decision on who draws.

## 2026-11-06 — Merge: hearts for Shige, Haru's band 6 scene, the worn old kiln
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three agents in parallel worktrees, models picked by difficulty: c9bd5a8 hearts for
  Shige (Opus), 99bf478 Haru's band 6 scene and dear lines (Sonnet), d8d2d6c cracks and a chip on
  Ichiro's old kiln (Haiku). Conflicts in WORKLOG, README, ROADMAP, triggers_town, music.json,
  th/dialogue.json and test_relationships resolved by keeping both sides (Haru now in the band 5
  and 6 loop, Shige checked for 3 and 5 only).
- Checked: on merged main, after `--import`, all 28 test scripts print `OK (0 failed)`; smoke
  runs (title, `--demo`, `--map=town`, `--mine=3`, `--event=heart_haru_6`, `--event=heart_shige`)
  print no error or warning.
- Left / next: Shige's band 6 scene; hearts for Nana or Kiku; the record is 42 stars now (rank
  steps 9/18/27/36 kept); `haru_wave` / `haru_tag` and Shige's scarecrow / pumpkins change
  nothing in the world yet; the flat-view kiln chip not seen in a screenshot.

## 2026-11-06 — Haru's band 6 scene and her dear lines
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: `heart_haru_6` (data/events, lines in heart_events_6.json): the city shop wrote again, this
  time to sell her sandals on its shelf with a tag, posted from Sayo's store; a line of its own
  for the band 5 answer (`haru_go`: "nobody holding the door"; otherwise the Genzo / rack line),
  the farmer picks the tag (place or name, `haru_tag`), and she asks the farmer to wave back from
  the field. Sets `heart_haru_6` and `haru_wave`. Band 5's stay / go choices now set `haru_stay` /
  `haru_go`. Rows in triggers_kaminoda, hill, haru_house and town; music rule; three `dear_` talk
  lines at band 6 after the scene; Thai for every new line. test_relationships covers the scene,
  rows, flags, both branches, tag lines and dear lines (Haru joins the generic band 6 loops).
- Checked: `--import`, then all 28 tests/test_*.gd print `OK (0 failed)`; smoke runs (title,
  `--demo`, `--map=town`, `--mine=3`, `--demo --map=kaminoda --event=heart_haru_6`) print no
  error or warning. No screenshot taken.
- Left / next: hearts for Shige, Nana or Kiku; `haru_wave` / `haru_tag` are only flags so far
  (nothing in the world reads them).

## 2026-11-06 — The old kiln looks worn
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: Ichiro's old charcoal kiln in Sakurazaka shows its age. In 3D `OutdoorProps.kiln` takes a
  `worn` flag (default on; the finished new kiln passes off, StoryProps kiln_new) and adds `_worn`:
  two hairline cracks in the clay face (one with a short branch), and a chip knocked out of the
  face's top right with a pale broken edge, all flat lit quads in colour 2e1d12 (`_seam`). They
  keep clear of the father's and Ichiro's thumbprints and the mouth. Flat view: new art key
  `story:kiln_worn` (32 x 32 overlay, the cracks and the chip), drawn by StoryView over the old
  kiln's box (MapView still draws the box; `kiln` is not in StoryView.KINDS). The clay is the
  kiln's own (the old kiln is a clay dome, so the "bricks" are a chipped piece of clay).
- Checked: test_maps has the seams as one lit mesh on the face inside the footprint with no
  faults; the new kiln has none; the old kiln keeps its seam mesh in the three Sakurazaka map
  states; the flat overlay is 32 x 32 with dark lines and a see-through background. All 28
  tests/test_*.gd print `OK (0 failed)`. Smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`) print no error or warning. Screenshots (480 x 270 movie frames, `--map=sakurazaka@kiln
  --flags=ichiro_kiln`): the 3D frame shows the old kiln's dark cracks on its front and left face,
  subtle; in the flat frame a dark crack shows on its box, and the HUD covers the rest of the kiln.
- Left / next: a closer look at the chip in both views (a larger render); the flat frame's HUD
  hides the kiln's corner at the spawn.
## 2026-11-06 — Hearts for Shige of Minamino
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: Shige joins `Villagers.friends()` (hearts no longer false). Birthday winter 18 (free of
  every other birthday and festival; the beds empty, next year's rows still only plans), with a
  `birthday` day plan: Nana hides his hoe, so home until 9:00, by the roadside shrine under the
  cherry 9:00-11:40, lunch at home, walking the beds by his house with empty hands 13:00-16:00,
  home by evening; the farmhouse calendar marks it (a little hoe on the 18th). Talk:
  birthday / gift_birthday, close lines from band 4, his forage lines now band 2 to 5 like the
  other friends, `pumpkin_` lines after band 5. `heart_shige` (band 3: Nana's scarecrow made to
  look like him; smile or keep her frown; two packets of tomato seed from the plants the crows
  left alone) and `heart_shige_5` (band 5: his late wife's tin of pumpkin seed, unsown eight
  years; sow it by her fence or share it with the farmer's field; a packet of pumpkin seed).
  Trigger rows in triggers_minamino, the new triggers_shige_house and triggers_town; music rule;
  his part in the ending (data/events/ending.json, dialogue/ending.json). Record steps:
  Friendships 7 / 15 / 25 / 38 of 48 -> 8 / 17 / 28 / 43 of 54 (same share), Neighbours
  1 / 2 / 3 / 4 -> 1 / 2 / 3 (three without hearts left: Nana, Kiku, Dr. Yae; steps must rise,
  so the record has 42 stars now, not 43; the rank steps 9 / 18 / 27 / 36 stay). Thai for
  every new line and the changed calendar key. README (Villagers, Ending) and ROADMAP updated.
- Checked: test_relationships has `_shige_friend` (birthday plan, close / pumpkin / birthday /
  forage picks, both answers of both scenes, both seeds, the calendar, the ending part, not a
  neighbour) and Shige in the heart rows (3 maps) and keepsake homes; test_talk moves him to the
  friends' forage days; test_ending uses Nana as the not-quite neighbour. After `--import`, all
  28 test scripts print `OK (0 failed)`; smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, `--demo --map=minamino --event=heart_shige`, `--event=heart_shige_5`, and
  `--map=house --event=ending --flags=ending_friend_shige`) exit 0 with no error or warning;
  a Thai frame of heart_shige's first line fits the box. One choice ("Keep the frown...") was
  shortened after test_relationships said it didn't fit.
- Left / next: Shige's and Haru's band 6 scenes; hearts for Nana or Kiku; the scarecrow and the
  pumpkin vines set no world change in Minamino yet.

## 2026-11-06 — Merge: hearts for Haru, the kiln's building stage, the chore talk before noon
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three agents worked in parallel worktrees, each on a model picked by difficulty:
  e4f2c98 hearts for Haru (birthday, close lines, band 3 and 5 scenes, ending part; Opus);
  726ec2e the new kiln's building stage for `ichiro_kiln` and readable thumbprints, the
  farmer's print moved to the new kiln (Sonnet); e6507d2 the spouse's chore lines only before
  noon (Haiku). Merged into main; only WORKLOG conflicted (all entries kept).
- Checked: on merged main, after `--import`, all 28 test scripts print `OK (0 failed)`; smoke
  runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error or warning.
- Left / next: Haru's band 6 scene; hearts for Shige, Nana or Kiku; the kiln's flat view not
  seen in a screenshot; the old kiln does not look cracked; Haru's stay / go answer sets no
  world change; the mountain backdrop waits on the user.

## 2026-11-06 — Hearts for Haru of Kaminoda
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: Haru joins `Villagers.friends()` (hearts no longer false). Birthday summer 27 (free of
  every other birthday and festival; the cucumbers at their best, before fall's straw), with a
  `birthday` day plan: home until 9:00, the hill lookout 9:20-15:00, her garden until dusk; the
  farmhouse calendar marks it. Talk: birthday / gift_birthday, close lines from band 4, her forage
  lines from band 2 to 5 like the other friends, `sandals_` lines after band 5. `heart_haru`
  (band 3: she sizes the farmer for straw sandals, tight or loose weave, two cucumber seeds) and
  `heart_haru_5` (band 5: her New Year's wish, a city craft shop wants her; stay or go, she
  stays and Sayo sells her sandals). Trigger rows in triggers_kaminoda, triggers_hill,
  triggers_haru_house and triggers_town (before the tempura lesson); music rule; her part in
  the ending (data/events/ending.json, dialogue/ending.json). Record steps: Friendships
  6 / 13 / 22 / 33 of 42 -> 7 / 15 / 25 / 38 of 48 (same share), Neighbours 2 / 3 / 4 / 5 ->
  1 / 2 / 3 / 4 (four without hearts left: Shige, Nana, Kiku, Dr. Yae). Fixed Genzo's band 3
  line calling Haru "he". Thai for every new line (and the changed calendar / Genzo keys).
- Checked: test_relationships has `_haru_friend` (birthday plan, close / sandal / hill /
  birthday picks, both answers of both scenes, the seed, the ending part, not a neighbour) and
  Haru in the heart rows (4 maps) and keepsake homes; test_talk moves her to the friends' forage
  days; test_ending uses Kiku as the neighbour. All 28 test scripts print `OK (0 failed)`; smoke
  runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, and `--demo --map=kaminoda
  --event=heart_haru`) print no error or warning; a Thai frame of heart_haru fits the box.
- Left / next: Haru's band 6 scene (`heart_haru_6`, dear lines); hearts for Shige, Nana or Kiku.

## 2026-11-06 — The new kiln goes up: a building stage and readable thumbprints
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: Sakurazaka's new kiln now follows the story in both views. `ichiro_kiln` (heart_ichiro_5) shows `kiln_site`
  beside the old kiln (cells 20-21 x 17-18): a half-built mound of clay bricks in two courses, a pile of bricks, a timber
  form in the open mouth and a shovel (3D lit mesh OutdoorProps.kiln_site, flat art `story:kiln_site`). `ichiro_mark`
  (heart_ichiro_6) replaces it with `kiln_new` (the finished kiln with Ichiro's print) and `kiln_mark` (the farmer's print
  moved from the old kiln to the new one, where the story puts it); the old kiln keeps its two prints. New map prop key
  `unless` (a flag that hides the prop; MapManager.shows / gate_flags) lets the site give way. Thumbprints are about 2.5
  times bigger: 0.2 x 0.15 cell ovals 0.3 apart on the face in 3D (4-5 px at the medium lens), 10 x 8 px art in the flat
  view. New spawn `newkiln`. Thai for the three new lines, README, AGENTS.md, ROADMAP, ART_DIRECTION.
- Checked: test_maps extended (gating of site / finished stages, solid cells, bricks only while building, prints counted,
  examine lines in order); all tests/test_*.gd print OK (0 failed); smoke runs show no errors. Screenshots
  `--demo --map=sakurazaka@newkiln --flags=ichiro_kiln` (brick mound, pile, shovel, form) and `...,ichiro_mark` (finished
  clay dome, two prints over the mouth, readable when enlarged 4x).
- Left / next: the flat view was only covered by tests, not by a screenshot; hearts for Haru, Shige, Nana or Kiku.

## 2026-11-06 — The spouse's chore talk only before noon
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: the four chore pick rows (help_water / help_feed in talk_sayo.json and talk_fumi.json) now
  have `"time": ["00:00", "12:00"]` next to their flags, so the chore line is picked only in the
  morning. The talk picker's `time` key (talk.gd, `[start, end)`, same as the wed_morning rows) is
  used as is. README → Villagers → Marriage and the ROADMAP line say so.
- Checked: tests/test_relationships.gd: at 10:00 with both chore flags the pick begins with
  help_water; at 14:00 it begins with wed_out (a married line instead), for Sayo and Fumi.
  Output: `test_relationships: OK (0 failed)`. All 28 tests/test_*.gd print `OK (0 failed)`;
  smoke run `--headless --path . --quit-after 300 -- --demo` shows no error or warning (exit 0).
- Left / next: the flags still clear at the next night, so an evening talk after the morning
  chore now gets the married lines; a live run at 14:00 is not done, only the picker test.

## 2026-11-06 — Merge: kiln mark and jizo bibs, Genzo band 6, the spouse's chore talk
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three agents worked in parallel worktrees, each on a model picked by difficulty:
  11eb048 story props for `ichiro_mark` (a new kiln at Sakurazaka with the farmer's thumbprint)
  and `genzo_jizo` (new red bibs on the Kaminoda jizo), both views (Opus); b2c0014 Genzo's band
  6 scene `heart_genzo_6` (Sonnet); 3e87b8b the spouse's talk names the morning's chore (Haiku).
  Merged into main; only WORKLOG conflicted (all entries kept).
- Checked: on merged main, after `--import`, all 28 test scripts print `OK (0 failed)`; smoke
  runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error or warning.
- Left / next: the thumbprints are small (2-3 px at the medium lens); the kiln does not show
  `ichiro_kiln`; the chore line is not limited to the morning; hearts for Haru, Shige, Nana or
  Kiku; the mountain backdrop waits on the user.

## 2026-11-06 — Genzo's band 6 scene
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: `heart_genzo_6` (data/events/heart_genzo_6.json, lines in heart_events_6.json): after the jizo bibs
  and his seed rice, Genzo has braided a straw rope for the jizo from the rice's straw and asks to tie it on
  together (a line of its own if the farmer tied the bibs, `genzo_jizo`). Sets `heart_genzo_6` and `genzo_straw`.
  Trigger rows in triggers_kaminoda, triggers_genzo_house and triggers_town, music rule, `dear_1..3` talk lines
  (band 6 after the scene; the jizo lines now stop at band 5), Thai for all new lines, README / ROADMAP.
- Checked: test_relationships now expects Genzo's band 5 / 6 events, `genzo_straw`, both branches of the looking-back
  line; all tests/test_*.gd print OK (0 failed); smoke runs (title, --demo, town, mine=3, kaminoda event) show no errors.
- Left / next: hearts for Haru, Shige, Nana or Kiku (ROADMAP).

## 2026-11-06 — The spouse's talk names the morning's chore
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: Marriage.help sets the flags help_water / help_feed for the day when the spouse watered
  plots or filled the coop's feed box, and erases both at the start of every night's help, so
  the flags only hold the chores of the latest morning. The spouse's pick rows (talk_sayo.json,
  talk_fumi.json) use them: after the engaged row and before the married house rows, a
  help_water row then a help_feed row, each with two lines (help_water_1/2, help_feed_1/2).
  Lines are English with Thai in data/lang/th/dialogue.json. The rows read plain flags, so the
  talk picker needs no new condition key. Also a note in README → Villagers → Marriage,
  ROADMAP, and the _help text of data/marriage.json.
- Checked: tests/test_relationships.gd: in the pure section, both chores set the flags, a rainy
  night erases the watering flag (and the feed flag follows whether feed went in), a full box
  on a rainy day sets none, single sets none, all four lines exist per spouse, the watering
  line wins when both flags are set, the feed line when only feed, no chore line without flags,
  the again line wins on a second talk. In the game: after a married end_day with watering,
  talking to Sayo says a help_water line (talk_sayo, recorded by dialogue_requested).
  Output: `test_relationships: OK (0 failed)`. All 28 test scripts print `OK (0 failed)`
  (the 28 names in tests/ each checked); smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, each `--quit-after 300`) print no error or warning.
- Left / next: the chore line shows on any talk that day, the morning is not checked by time;
  the same chore line for Fumi is not seen in a live run, only in the tests.
## 2026-11-06 — Story props for Genzo's jizo bibs and Ichiro's kiln mark
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the flags `genzo_jizo` (heart_genzo_5) and `ichiro_mark` (heart_ichiro_6) now leave
  props, gated like the other story props (MapManager.with_flags). Sakurazaka had no kiln, so
  a new prop kind `kiln` (2 x 2 at 23, 17, below Ichiro's house, solid, examine line) is a lit
  mesh (OutdoorProps.kiln: a baked-clay dome, a flat clay face with a stone-framed mouth and
  hearth stone, a chimney at the back, snow on the crown) with two thumbprints over the mouth
  (the father's, a little broader, and Ichiro's). The story prop `kiln_mark` on the same cells
  (flag ichiro_mark) adds the farmer's third (OutdoorProps.kiln_mark_at gives the three spots).
  `jizo_bibs` (flag genzo_jizo, not solid) on the two Kaminoda jizo (8, 12), (9, 12) ties a
  wider, brighter red bib (NEW_RED e23a2c) with a white hem, a small white crest and a fresh
  collar tie over the old bib. The story props are listed before the prop they sit on, so
  `prop_at` finds them and their examine line replaces the kiln's ("two thumbprints" ->
  "three ... the newest one is yours"); the jizo had no line and now has one with the flag.
  Flat view: StoryView draws `story:jizo_bibs` / `story:kiln_mark` (PlaceholderArt), MapView
  colours the kiln. New spawns `sakurazaka@kiln` and `kaminoda@jizo` for screenshots (AGENTS.md).
  Thai lines for the three messages in data/lang/th/items.json. README → Maps, ROADMAP,
  ART_DIRECTION updated.
- Checked: test_maps `_outdoor_props` builds the kiln (with and without snow: lit ArrayMeshes
  only, inside its 2 x 2 cells, 0.95..1.1 high, two thumbprints, snow skins only with snow),
  the three mark spots on its face, the bib inside the jizo's cell; Sakurazaka's map has no box
  left in the kiln's cells. New `_lane_and_kiln_props`: the events set the flags, the gate
  flags of both maps, the props only with their own flag (not in Minamino), the bibs over a
  still-solid jizo, the kiln leaving Ichiro's path / work spot open, the art drawn, in 3D two
  NEW_RED meshes / two -> three thumbprints with the flag, the flat view, and examining the
  kiln and the jizo through FarmActions.interact before and after the flags. All 28 test
  scripts print `OK (0 failed)`. Smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, plus the kiln in winter snow and the bibs) print no error or warning.
  Screenshots: `--demo --map=sakurazaka@kiln --time=10:00` with and without
  `--flags=ichiro_mark` show two vs three thumbprints over the kiln's mouth;
  `--map=kaminoda@jizo --flags=genzo_jizo` the bigger red bibs with white hems against the
  plain ones; winter `--snow=80` snow on the kiln's crown; the flat view shows the bib sprites
  on the jizo boxes and the marks on the kiln box.
- Left / next: the thumbprints are 2-3 screen pixels at the medium lens (readable side by
  side, small alone); the kiln's look does not change with ichiro_kiln (the farmer helping dig
  it); Genzo's band 6 scene is another agent's work.

## 2026-11-06 — GitHub remote
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: added `origin` = https://github.com/kitphon/son-of-harvest.git (the user made the
  repository) and pushed `main`; AGENTS.md rule 2 now says to push after each commit.
- Checked: `git push -u origin main` succeeded; `git status -sb` shows main tracking origin/main.
- Left / next: nothing for the remote.

## 2026-11-06 — Merge: spouse farm help, Ichiro / Genzo hearts, sky by the clock
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three agents worked in parallel worktrees: b4d5274 the spouse helps on the farm each
  morning (Opus), c55d7f9 Ichiro's band 6 scene and hearts for Genzo (Sonnet), 25a5613 the sky
  behind the land follows the clock outdoors (Haiku). Merged into main; only WORKLOG
  conflicted (both sides kept).
- Checked: on merged main, after `--import`, all 28 test scripts print `OK (0 failed)`; smoke
  runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`) print no error or warning.
- Left / next: the sky colour only shows where no land is drawn (needs the optional mountain
  backdrop, the user's call); Genzo has no band 6 scene yet; the kiln mark and the jizo bibs
  have flags but no props; a spouse talk line about the morning's chore.

## 2026-11-06 — The sky behind the land follows the clock
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: the 3D view's clear colour outdoors now follows the time of day, as the sun does.
  data/light.json has a "background" block: keys [minute, colour] (night 161f3b, dawn 6f5a86
  and peach f0a58a, morning a9d2ea, the day blue 8fc6e8 from 10:00 to 16:00, golden f2b27e at
  17:30, mauve c27a8c at 18:30, deep blue 5a5688 and 1e2650 by night) and "cloud_grey" 0.5.
  Game.sky_color() reads the keys (sky_at), Game.sky_view() (static, pure) greys the colour by
  1 - the weather's "sun" value times cloud_grey and then multiplies by the weather tint, so
  rain and storms are greyer and darker. Game.sky_background(inside, map_background) gives rooms
  and mine floors their own map background, as before. Main3D._update_tint sets
  env.background_color each game minute (the old one-off set in _enter_map is gone).
  ART_DIRECTION section 3 ticked for the sky; README → Light updated.
- Checked: tests/test_weather.gd `_sky_by_clock` checks the noon colour (8fc6e8), the 6:00 blend
  of the 5:30 and 6:30 keys, sky_at blending, the dark blue night at 0:00 / 2:00 / 23:30 (luminance
  under 0.15), noon > dusk > night, a warm 17:30 and 6:30, no 10-minute luminance step over 0.1,
  clear > rain > storm in luminance and chroma, a fully clouded grey at cloud_grey 1, and rooms
  keeping their own background at 6:00, 12:00 and 21:00. Output: `test_weather: OK (0 failed)`.
  Probe (headless, scene running, clear colour of the WorldEnvironment): 6:00 (0.697, 0.505,
  0.534), 12:00 (0.561, 0.776, 0.910) = 8fc6e8, 18:30 (0.754, 0.476, 0.549), 23:00 (0.097, 0.131,
  0.258). Screenshots `--demo --time=6:00`, `12:00`, `18:30` (before from the HEAD tree, after
  from this worktree): the land and trees cover the whole frame, so the sky barely shows and the
  before / after frames look the same to the eye (the mean pixel difference is small and sits in
  the grass and trees). The village wide view and the hill lookout at dusk also show no sky.
  All 28 test scripts print `OK (0 failed)`; smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, each `--quit-after 300`) print no error or warning.
- Left / next: the sky shows only where no land is drawn, which none of the framed views has;
  to see it the scene needs a horizon (the optional mountain backdrop in ART_DIRECTION section 3).

## 2026-11-06 — The spouse helps on the farm each morning
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: ROADMAP "Later for marriage". data/marriage.json gets a `help` block, used by
  `Marriage.help` (rules) from `Game.end_day` after the night: on a sunny day the spouse
  waters up to `water` = 6 dry tilled plots with an unripe crop (new
  `FarmGrid.water_dry_crops`, row by row from the top-left), and for each home in
  `feed_homes` (the coop) tops the feed box up by at most `feed` = 3 portions from the
  farmer's own stock (`Animals.fill_feed_box` takes an optional cap). Single or only engaged:
  nothing. What was done is told on stepping out of the house (`Game.help_news`, like the
  builder's news and joined with it): one whole sentence each for watered / fed / both with
  the spouse's name, Thai in data/lang/th/ui.json. `Marriage.check` checks the block.
  The village record already names the spouse under the title (`Ending.spouse_line`, also on
  the yearly page), so nothing was added there; ROADMAP's line now says so.
- Balance: 6 plots is two thirds of one seed bag's 3 x 3, so a small field gets a head start
  and a bigger one still needs the can; rain waters already, so sunny days only. 3 portions is
  half a full coop (6 hens), and it comes out of the farmer's feed, so feed still has to be
  bought and a busy coop still needs topping up. The barn is left to the farmer.
- Checked: `--import` ran clean. tests/test_relationships.gd: `_spouse_help_rules` (the cap,
  the next plots on a second call, ripe and unsown plots left dry, no watering in rain / storm
  / snow, the box topped up to one portion a hen and no further, an empty sack, no help single
  / engaged / spouse flag without married_<id>, a line for each case) and
  `_spouse_help_in_game` (end_day single and married, the news told once on stepping out,
  save / load keeps the wet plots and the help goes on). All 28 test scripts print
  `OK (0 failed)` (test_relationships, test_lang, test_ending, test_save among them) with no
  SCRIPT ERROR line. Smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`,
  `--demo --map=house --built=room --flags=married_sayo,spouse=sayo --time=19:00`, each
  `--quit-after 300`) print no error or warning line. No screenshot (the help is a message).
- Left / next: a child (the last "Later for marriage" item); a spouse talk line about the
  morning's chore could follow (the talk files have wed_morning_ lines).

## 2026-11-06 — Ichiro's band 6 scene and hearts for Genzo
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: ROADMAP "Later for hearts". Ichiro: heart_ichiro_6 (the first piece from the new
  kiln, a line of its own if the farmer said yes to the digging, ichiro_kiln; the space left
  in the kiln's clay for a third mark; sets heart_ichiro_6 and ichiro_mark), rows in the
  Sakurazaka, house and village tables, three `dear_` talk lines at band 6, heart music.
  Genzo of Kaminoda joins Villagers.friends(): birthday summer 13 (a "th" date; his plan: the
  well 10:00-14:00, home before and after), birthday / close / jizo talk lines, forage talk from
  band 2 on his Monday like the other friends, heart_genzo (band 3: well water tasted as his wife
  did, two packets of seed rice) and heart_genzo_5 (the jizo's red bibs tied for him), rows in
  the village, Kaminoda and his house's tables, a part in the ending (a closing word) and the
  calendar's note. No band 6 scene for Genzo (README: optional). Record: Friendships steps
  5 / 11 / 19 / 28 became 6 / 13 / 22 / 33 (seven friends, 42 at most, the same share as
  before), Neighbours 2 / 3 / 5 / 6 became 2 / 3 / 4 / 5 (five left without hearts). Thai for
  all 39 new lines and the calendar line (the old one's entry replaced).
- Checked: tests extended in test_relationships (Genzo's rows, plan, talk, scenes, record;
  Ichiro's band 6 branches and flags), test_talk (Genzo's forage day moved to the friends'
  list), test_ending (Haru instead of Genzo as the neighbour). See the commit's test output
  in the report. Screenshot `--demo --map=sakurazaka@bridge --event=heart_ichiro_6`: Ichiro's
  first line in the text box at the bridge.
- Left / next: a band 6 scene for Genzo; hearts for Haru, Shige, Nana or Kiku the same way.
  The mark in Ichiro's kiln clay and Genzo's red jizo bibs have no props yet (flags
  ichiro_mark, genzo_jizo are set for them).

## 2026-11-06 — Merge: night lights, countryside / festival meshes, showcase views
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three agents worked in parallel worktrees: cb0e67b night real lights, a lighter night
  and festival pools (Opus), cdf3074 the countryside props and festival decorations as lit
  meshes (Sonnet), c524227 the trailer-ready showcase views (Haiku). Merged into main. The
  night branch had changed FestivalProps' lantern / stall builders (pool kinds on `_glow`)
  that the mesh branch had moved into FestivalMeshes; kept the mesh branch's code and passed
  the pool kinds at the `_glow` calls in `FestivalProps._make` ("stall" with the counter's
  mid and width, "line" for string lanterns, round for the rest). README, ROADMAP and WORKLOG
  conflicts kept both sides.
- Checked: on merged main, all 28 test scripts print `OK (0 failed)` with no SCRIPT ERROR
  line; smoke runs (title, `--demo`, `--map=town`, `--mine=3`, `--map=town --time=21:00`,
  `--festival=lantern_night`, `--map=kaminoda --season=winter --snow=80`, and main_2d.tscn
  `--festival=lantern_night`) print no error or warning. Screenshot `--demo
  --festival=lantern_night`: the new lantern meshes, warm pools under them and the judges'
  table show.
- Left / next: the optional mountain backdrop waits on the user; section 4 (characters)
  needs the user's decision on who draws.

## 2026-11-06 — Trailer-ready screenshots: 12 fixed views and a runner
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: ART_DIRECTION section 5, "Trailer-ready screenshots". data/showcase.json lists 12
  named views (farm morning and noon, village morning and night, village with the wide lens,
  winter snow, rain, house inside, mine floor 3, bamboo hill, Lantern Night, river Sunday),
  each a list of the existing command-line flags. tools/showcase.py renders each with
  `--write-movie` (`--fixed-fps 30 --quit-after 30`), keeps the last frame as <out>/<name>.png,
  takes `--only`, `--godot` (default: the project folder, then its parent) and
  `--compare <dir>` (writes <out>/compare/<name>.png, before | after, and prints the mean
  absolute pixel difference). tests/test_showcase.gd checks the file parses, 10 to 12 unique
  names, every arg is a `--` flag, and every map (and its spawn), festival and lens named
  exists. README → Showcase; AGENTS.md → Run and check lists the test.
- Checked: `--import` ran clean. `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_showcase.gd` printed `test_showcase: OK (0 failed)`.
  `python -I tools/showcase.py --out shots/showcase --godot /d/Harvest-son/Godot_v4.7.2-stable_win64_console.exe` printed
  `rendered 12 of 12 view(s) into .../shots/showcase` with exit code 0 and no error lines.
  Viewed farm_morning.png (the farmhouse, 06:31 clock, planted plots) and lantern_night.png
  (the festival stalls and lanterns, 20:01): real game frames, not the title screen.
  All 28 other test scripts printed `OK (0 failed)`, among them test_lang, test_maps,
  test_view2d and test_title.
- Left / next: the set has no before/after pair yet; the first "before" run is this commit's
  `shots/showcase`, to compare after the next look change with `--compare`. The views run one
  at a time (about 10 s each on this machine), so the whole set takes a few minutes.

## 2026-11-06 — The countryside props and the festival decorations as lit meshes
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: ART_DIRECTION section 1's last box pieces. New scripts/world3d/field_props.gd
  (FieldProps, CountryProps calls it): the rice drying rack (tapered poles with straw lashing
  at the rails, paired rails at 0.75 and 1.2, in fall sheaves of straw draped over each rail,
  bound, with ears at the foot; a line of snow on the rails and pole tops), the kitchen garden
  (earth bed in a plank frame, ridges every half cell, rows alternating leafy greens, cabbage
  heads with outer leaves and spring onions; only the bed in winter; a snow cover where snow
  lies) and the board fence (capped posts every cell, weathered boards nailed to the +z / +x
  face a little off each other's height, nail heads, snow on caps and top boards). New
  scripts/world3d/festival_meshes.gd (FestivalMeshes, FestivalProps._make calls it): mats with
  a lunch box, rice balls and teacups; the stall (planks counter, posts, tie beams, sloped cloth
  roof, scalloped valance, curtain pieces, hanging lantern); the judges' table (striped drape,
  name board with brush strokes, tilted rosettes with tails); the lantern string (turned poles,
  sagging rope, ribbed lanterns on cords); the drum stage (braced legs, planks, cloth skirt, a
  barrel drum with skins and tacks on chocks, sticks); the moon stand with its dango pyramid;
  pampas in a glazed vase; the standing lantern; the kadomatsu (straw tub with rope bands,
  slant-cut bamboo with node rings and the hollow showing, pine boughs); the bonfire (rough
  stones, leaning and lying logs, embers and flames); the mortar with its hoops, dough, mallet
  and pail; the race flag (node-ringed pole, banner with a fish on both faces, the creel).
  Lantern paper, embers and flames stay unshaded (`Parts.glow`) as the flat colours were; the
  lights (FestivalProps.glows) are the same positions, sizes and colours, no light added or
  changed. `OutdoorProps._tube` now takes a null colour (a SurfaceTool must colour all its
  vertices or none), which the new code uses.
- Checked: test_maps `_field_props` (every hasa / garden / wood_fence on kaminoda, minamino,
  sakurazaka and town, in spring / fall / winter, with and without snow: lit ArrayMeshes only,
  faces turned out, inside their cells, 1.4 / 0.12..0.45 / 0.7 high, snow skin only where
  snow is, fall straw adds triangles, the winter garden is bare, no box left in the cells on
  kaminoda and minamino) and `_festival_meshes` (every prop of every festival: no primitives,
  faces out, near its cell, height band per kind, lights listed for the lit kinds, unshaded
  parts only on paper and flame). Screenshots `--demo --map=kaminoda@well --time=8:30`,
  `--map=minamino@shige --time=9:00`, `--festival=blossom_day`, `--festival=lantern_night`,
  `--season=winter --map=town --snow=80` (before / after), plus fall kaminoda, minamino@kiku in
  fall and moon_night. All 29 test scripts in tests/ print `OK (0 failed)` with no SCRIPT ERROR; smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, kaminoda winter snow 80, `--demo --festival=lantern_night`) print no error or warning.
- Left / next: the stall wares are still item pictures; banners and noren do not move in the
  wind; the camera shows the new pieces small (480x270 frames), a closer look at the drum stage
  and kadomatsu could refine proportions. Section 3's night item (real lights) belongs to the
  other branch.

## 2026-11-06 — Night: real warm lights, a lighter night, festival lights on the ground
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: ART_DIRECTION section 3, "Night: real warm lights at lanterns, windows and the festival
  stalls, the tint lighter". New `NightLamps` (scripts/world3d/night_lamps.gd, made by main_3d):
  data/light.json "lamps" → max (8) OmniLight3Ds, shadows off, no specular, range 2.8, at the
  lit windows (0.45 in front of the pane), by the stone lanterns' fire boxes (0.3 toward the
  camera) and at the festival lights; the ones nearest the point the camera looks at, the last
  kept fading over 1.5 cells as it nears the first one dropped (no popping). Energy: window
  1.1 / lamp 1.2 times Game.window_light, festival 1.0 (string lantern 0.6 of it) times
  FestivalGlow.darkness, so every light is off by day. The tint multiplies the picture
  afterwards, so the colour is ffa050 divided by the tint (normalised, the factor going into
  the energy, at most `boost` 6), the same trick as NightView's shader: it lands as ffa050.
  The ground (farm, maps, Surroundings), the water and the grass tufts go on
  `NightLamps.GROUND_LAYER` (2), outside the lamps' cull mask: their light stays the drawn
  pools (no double light, no extra ground pass in the Compatibility renderer's per-light passes).
  The night blue is a touch lighter: 46529a (luminance 0.33) for 404c8e (0.31), still well
  under the pre-FEEDBACK-6 night. Festival lights now light the ground in both views:
  `NightLights.festival_pools` (data/light.json "pools" → "festival": strength 0.36, round
  pools 0.7 x the glow's size, string lanterns 0.45 as strong, a stall's pool in front of its
  counter, 0.85 forward, 0.7 deep, the stall's width + 0.4); `FestivalProps.glows` carry the
  pool kind (round / line / stall, the stall's middle and width). NightLights plans them in
  3D (before the window-glow check, hidden by the map's buildings like the rest); the flat
  view's NightView takes the map id, reads FestivalProps.glows_of and adds them while the
  festival is on. Balance (ours): energies chosen by eye on the farm and village at 21:00 and
  Lantern Night; 0.6 / 0.7 first was too faint on the dark wood.
- Checked: all 27 test scripts print `OK (0 failed)` (test_animals .. test_weather, each line
  `test_<name>: OK (0 failed)`), and no test log has an ERROR line; smoke runs (title, `--demo`,
  `--demo --map=town`, `--demo --mine=3`, plus `--map=town --time=21:00`, `--festival=lantern_night`
  and main_2d.tscn on Lantern Night) exit 0 with no error or warning line. New checks:
  test_maps `_night_lamps` (a lamp per lit window / lantern, none at glow 0, positions and
  energies, dimming with the glow, nearest-first with the fade at the cut and a tie dropped, the
  tint division landing exactly warm, the boost cap, max <= 8, the ground / water / grass on
  GROUND_LAYER) and in the real view (8 lamps, no shadows, ground left out, 4 warm lamps at
  21:00 on the farm, all off at noon); test_festivals `_festival_lights` (a pool per festival
  light on the ground, the 4 stalls' in front of their counters, string lanterns fainter, none
  by day, scaling, lamp spots, the 3D view's planned pools, 7..8 lamps lit at the festival, the
  flat NightView's festival pools = the 3D ones); test_weather (the night a touch lighter
  than 404c8e, by 0.01..0.05); test_view2d `_night` now counts Lantern Night's pools after
  the windows'. Screenshots before / after: `--demo --time=21:00` (the engawa, posts and lower
  timbers warm; the chest and bin, mean RGB (93.5, 70.0, 55.4) -> (104.1, 74.7, 59.0));
  `--map=town --time=21:00` and `town@shrine` (the stone lantern's base warm orange);
  `--festival=lantern_night` (warm patches under the string lanterns, the torii posts warmer);
  daytime `--map=town --time=10:00` and `--festival=blossom_day` pixel-identical, the farm at
  10:00 differs only by its random debris.
- Left / next: pale plaster takes little of the lamps (it is near white under the night sun
  before the tint, so the lit picture clips); dimming the night sun under an even lighter tint
  would free it but changes the measured ground. Unshaded pieces (sprites, the festival props'
  flat colours, the town ground without snow) do not take the lamps. Next in ART_DIRECTION:
  the optional mountain backdrop (its branch waits on the user), then section 4.

## 2026-11-06 — Merge: sun by the clock, coop / barn insides, bamboo and outdoor props
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: three agents worked in parallel worktrees: 8e4cfd8 the sun follows the clock (Opus),
  e0f0389 the coop's and barn's insides as lit meshes (Sonnet), fb9b1d8 bamboo, well, jizo,
  woodpile and river rock as lit meshes (Sonnet). Merged into main, keeping both sides of the
  ROADMAP / ART_DIRECTION / WORKLOG conflicts; the code merged cleanly.
- Checked: on merged main, all 27 test scripts print `OK (0 failed)`, test_maps prints no
  SCRIPT ERROR line, and the smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`,
  `--demo --map=hill --season=winter --snow=80`, `--demo --map=barn`) print no error or warning.
- Left / next: ART_DIRECTION section 3's night item (real lights, festival stalls lighting the
  ground); the mountain backdrop branch still waits on the user.

## 2026-11-06 — The sun follows the clock (3D view)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: ART_DIRECTION section 3, "Morning and evening sun colour and angle following the
  clock". data/light.json "sun": `plain` (the fixed sun as before: 48°, yaw -40, ffedcc =
  Main3D SUN_COLOR, 0.7) and `keys` [minute, elevation, yaw, colour, energy], linear in
  between. `Game.sun_light(inside)` (with `sun_at`, `sun_plain`, `sun_direction`) gives the
  pose; `Main3D._aim_sun` puts it on the DirectionalLight3D with the tint each game minute.
  Rooms, mine floors and maps with their own light keep the plain sun; under cloud
  (weather_fx.json "sun" 0) the colour goes back to plain (no golden rainy evening).
  Balance (ours): the sun stays on the screen's left half so shadows always fall to the right
  where they show (the light pass's rule): it rises at 5:30 from the lower left (yaw -6, 8°,
  ff9c5c), 6:30 16° ffb878, 8:00 30°, 10:00 46° (near the old look), noon 60° plain, 14:00 50°,
  16:00 32°, 17:30 16° ffb070, 18:30 8° ff9858 from the upper left (yaw -80). So the morning's
  shadows run long up-right, the evening's down-right toward the viewer, noon's are short.
  It swings back to the plain pose 18:30 -> 20:30 and away again 4:00 -> 5:30, only while
  Game.sun_shadow() is 0 under the dusk / dawn tint, so the night picture is exactly as it was
  (FEEDBACK item 6). The energy stays 0.7 at every key: the ground shader takes the sun at
  SnowLayer.SUN_SHARE with no angle term, so its measured brightness holds; only the colour
  warms the sunlit ground, walls and snow (no re-measure needed: noon is the measured colour).
  The dawn swing was first 4:30 -> 5:30, a 6.7° step in 10 minutes; widened to 4:00.
- Checked: test_weather `_sun_by_clock` (plain = the measured sun, energy plain's at every key,
  keys cover the day, sun_at halfway / held past the ends / plain with no keys, 6:30 shadows
  up-right and 17:30 down-right in camera terms, long morning / evening shadows and short at
  noon, noon highest, golden low sun and plain noon, the lower the warmer, the plain sun at
  21:00 / 23:30 / 2:00 / 4:00, no step over 6° or 0.12 colour in 10 minutes, the swing back only
  with shadows off, rain / storm / snow / blizzard plain colour, indoors the plain sun at four
  hours); test_maps: in the real view the light follows Game.sun_light on the farm and is the
  plain sun in the house. Screenshots `--demo --weather=sunny` at 6:30, 10:00, 13:00, 17:30,
  19:00; `--map=town` at 7:00 (tree shadows long up-right over the path) and 17:00 (long
  down-right, the plaster wall peach); `--season=winter --map=town --snow=80 --time=16:30`
  (snow cream in the low sun, shadows blue on it); `--weather=rain --time=17:30` (plain).
  Farmhouse front wall mean RGB (python -I): 10:00 (165.7, 151.5, 128.3), 6:30 (183.0, 140.6,
  105.3), 13:00 (138.7, 128.0, 110.1, the high sun grazes it), 17:30 (171.8, 118.3, 74.8).
- Left / next: the sky background colour does not follow the sun; sprites (unshaded) take only
  the tint; the light moves in one-minute steps (0.5 s), no per-frame easing. Next in
  ART_DIRECTION: section 3's night item (real lights / a lighter tint, festival stalls).
## 2026-11-06 — The coop's and barn's insides as lit meshes
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: ART_DIRECTION section 1, the open item under "Room furniture as lit meshes". Every
  coop prop (`CoopProps.prop`: feed box, nests, incubator, feed sack, hen hatch) and barn prop
  (`BarnProps.prop`: fodder box, stalls, hay, barn gate) is now built in one `FarmProps.Parts`
  of SurfaceTool meshes like RoomProps: bevelled blocks (`RoomProps._cube`) in the
  `build:planks` / `planks_dark` / `hay` textures, lathe-turned straw bowls, the basket, the
  tawara and its ropes, tilted parts through `RoomProps._placed`. New: battens and a rope on the
  trough, straw nests with loose stalks, a woven incubator basket and a lit lantern (the only
  unshaded piece, RoomProps.LAMP), the spilled grain, the hatch door ajar on a slatted ramp,
  the barn's slatted fodder rack on the back wall, capped stall posts with tether rings,
  bundles of hay with a belly, a rope band and stalks at the ends, a leaning pitchfork, the
  gate's braced leaves with iron straps. Cells, heights (nest straw dips to 0.31, trough floors
  0.08 / 0.10, incubator straw 0.46) and collision are unchanged, so AnimalLayer's eggs and
  feed sit as before. The flat view is untouched. The buildings' outsides were not changed.
- Checked: new `_stable_props` in tests/test_maps.gd (all nine kinds are ArrayMeshes, lit,
  wound to their normals, inside their cells plus 0.2, clear of the back walls, only the lantern
  glows, and a vertical ray at each egg / feed spot hits a surface no higher than the sprite).
  Screenshots `--demo --map=coop` / `--map=barn` before and after at 10:00 and 20:00 (indoor
  light does not follow the clock, so the pairs look alike). All test scripts and the smoke runs:
  see the results of this commit.
- Left / next: outdoor small props (well, jizo, woodpile, river rock; another agent has the
  bamboo and the outdoor props), the sun by the clock (another agent).
## 2026-11-06 — Bamboo and the outdoor small props as lit meshes
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: ART_DIRECTION section 2 (bamboo) and section 1 (outdoor props). New
  `scripts/world3d/outdoor_props.gd` (OutdoorProps); MapWorld's `_bamboo` / `_river_rock` and
  CountryProps' well, jizo and woodpile call it (their old boxes and cylinders are gone;
  positions, cells, collision unchanged; the flat view untouched). Bamboo: culms of two
  6-sided tubes with node rings, leaf sprays and tip plumes, colours by season, spring shoots,
  fall leaf litter, snow skins on the upward leaves. A clump is one vertex-coloured lit mesh
  (stays fadable for Occluders), built once per season / snow / look (8 looks) and shared;
  `OutdoorProps.Sway` leans each clump about its foot (0.028 rad, own phase) like the grass
  sways. Well with curb, posts, windlass, bucket and a Minka.gable roof; jizo with red cap,
  collar and bib; woodpile of bark-and-cut-end logs under a lean-to; river rock as faceted
  boulders with a foam ring; snow caps where snow lies.
- Checked: test_maps `_outdoor_props` (each season and snow: one mesh, no primitives, no unlit,
  no faces turned in, node / leaf / culm colours of the season, 2.2..3.7 high, within 0.95 of
  its centre; the sway moves the basis never the foot; shared shapes; well, jizo, rock and
  1x1 / 2x1 woodpiles inside their cells with snow skins only when snow lies; on hill,
  kaminoda, minamino, sakurazaka and river one bamboo mesh per data clump and no box / cylinder
  left in the props' cells). Screenshots `--demo --map=hill` (summer, winter `--snow=80`),
  `--map=kaminoda@well`, `--map=sakurazaka@mine` (winter), `--map=river@shore`, before and
  after read. All 27 test scripts `OK (0 failed)`; smoke runs (title, `--demo`, `--map=town`,
  `--mine=3`, hill in winter) print no error.
- Left / next: the sway doesn't grow in a storm; drying rack, garden, board fence and the
  festival props still boxes; no snow on bare branches. Section 3 (sun by the clock) is next.

## 2026-11-05 — Merge: rice and corn clusters, moving water
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged the two art-direction branches (65bafcd rice / corn as sprite clusters,
  5421334 the water sheet), keeping both sides of the ROADMAP / ART_DIRECTION / WORKLOG
  conflicts and both new checks in tests/test_maps.gd (`_crop_clusters`, `_water`). The
  mountain backdrop branch is not merged: in progress, the ridges do not reach the frame
  with the fixed camera (its WORKLOG entry is on that branch); waiting on the user.
- Checked: see the test run of this commit (all 27 scripts) and the smoke runs.
- Left / next: ART_DIRECTION section 3 (morning / evening sun, night lights).

## 2026-11-05 — Rice and corn as clusters of pixel sprites
Agent: Claude Code (claude-opus-5-5) · Commit: 65bafcd
- Done: ART_DIRECTION section 2, "Rice and tall crops as clusters of pixel sprites". New
  `scripts/world3d/crop_clusters.gd` (CropClusters): in the 3D view, rice and corn grown past
  the sprout (growth 2 and 3 of `PlaceholderArt.cell_key`, looks "grain" and "stalk") stand as
  several small plants a cell instead of one Sprite3D: nine rice hills in three rows (young,
  growth 2: six smaller hills in two rows so the ground or water shows between), three corn
  stalks (one back, two front). Seeds, sprouts and every other crop stay single sprites, as
  does the flat view. New PlaceholderArt key `stalk:<id>:<growth>:<ripe|growing>:<variant>`
  (`_stalk`): one rice hill of five thin blades (9 x 16, young 9 x 11), ripe with straw stems
  and gold ears bowing over; one corn stalk (11 x 24, young 11 x 15) with alternate leaves, the
  tassel and, ripe, the cob in its husk; three variants each; rimmed in a deep shade of the leaf
  (`_rim`) instead of the black outline, which made a field of blades noisy. One MultiMesh a
  picture of quads sized FarmWorld.PX a pixel; the shader billboards each instance like a
  Sprite3D at its own size, flips half of them, shades each 0.9..1.06, sways the tips (0.03)
  and stays unshaded like the crop sprites. Places, nudges, sizes, flips and variants come
  from a hash of the cell, so a cell always grows the same plants. FarmWorld puts cluster cells
  into `crops.plant` instead of `_sprites` (replanted only when a cell's key changed). The
  village paddies (Kaminoda's "paddy" tiles with no prop) grow rice by season
  (`CropClusters.PADDY`; numbers ours): young in spring, tall and green in summer, ripe in
  fall, none in winter; their plants carry the paddy's snow hold and fold away under white
  ground (SnowLayer's noise), the cover driven by `set_snow`. A farm crop keeps hold 0 and
  stands in snow as its sprite always did.
- Checked: test_maps `_crop_clusters` (keys: rice and corn from growth 2 only; plants inside
  their cells and the same each time, 90 / 60 / 30 plants for 10 cells each of ripe rice, young
  rice, ripe corn; 9 pictures, a rice hill 9x16 (young 11 high), a corn stalk 24 high, 19 gold
  ear pixels; on a farm ripe rice is 9 plants and no sprite while a tomato is a sprite, back to
  a sprite at the sprout, nothing once cleared; Kaminoda 128 paddy cells: spring 768 plants of
  `stalk:rice:2:growing`, summer and fall 1152 of `3:growing` / `3:ripe`, none in winter, every
  plant on a paddy with the paddy's hold, snow driven). Screenshots: `--demo --season=summer`
  shows the corn as stalk clusters and the ripe rice as a dense gold field of bowed ears (4619
  gold-ish pixels in the lower right of the frame); `--season=fall` young green rice in rows;
  `--map=kaminoda@well` spring (young rows, the water showing between), summer (tall green),
  fall (ripe gold), winter `--snow=80` (no rice, snow on the paddies); `main_2d.tscn --demo
  --season=summer` unchanged (one sprite a cell). All 27 test scripts `OK (0 failed)`; smoke
  runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --map=kaminoda`)
  print no error or warning line.
- Left / next: cucumber and tomato vines (on stakes) stay one sprite; the plants don't part
  round the farmer or bend harder in a storm; no rice stubble in winter paddies. Next in
  ART_DIRECTION: section 3.

## 2026-11-05 — Water: a gentle moving surface (3D view)
Agent: Claude Code (claude-sonnet-5-5) · Commit: 5421334
- Done: `WaterSurface` (scripts/world3d/water_surface.gd), built by Surroundings under the farm
  and every outdoor map: one transparent quad per water cell (pulled in 3 px from each bank so
  the bank and foam line stay), a shader showing slow stepped bands on the 16 px grid: pale warm
  glints (alpha .5) and a few dark-blue troughs (alpha .32), the rest see-through over the still
  tile. Lit like the ground (SnowLayer.SUN_SHARE), so dusk and night darken it and shadows fall
  on it; no shadow cast; water holds no snow, so winter looks the same. Covers the apron too,
  so the river runs on past the edges moving. Balance: glints about 1 pixel in 6.
- Checked: test_maps `_water` (farm pond fully covered and nothing on land, inset only at
  banks, shader uses TIME, river and town covered, none indoors). Screenshots `--demo
  --fishing=wait` (the pond: soft pale and dark bands over the blue, bobber on top) and
  `--demo --map=river`; pixel diff of the pond between frames 30 and 59: 1578 pixels changed.
- Left / next: no ripple ring at the bobber; flat view unchanged.

## 2026-11-05 — Merge: pool edge, last Thai gaps, PlayStation pad names
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged the three feedback follow-ups (ff53903, 96a67e1, 219eae4), keeping both sides of
  the WORKLOG / FEEDBACK conflicts. The PlayStation names came after the Thai pass, so 12 texts
  were missing again: the pad names (Cross, Circle, Square, Triangle, Share, PS, Options, L1, R1,
  L2, R2) get Thai entries equal to the English, as the Xbox names do (printed on the pad), and
  "ps vita" (a word looked for in a pad's name) is in LangCatalog NOT_SHOWN.
- Checked: lang_report --lang=th `th: 1683 of 1683 done (100%), 0 missing, 0 stale`; all 27
  test scripts `OK (0 failed)` on the merged main; smoke runs (title, --demo, town, mine=3)
  with 0 error / warning lines.
- Left / next: none from these three; PlayStation names not tried on a real pad.

## 2026-11-05 — Flat view: the farmhouse's pool starts at the roof's edge
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: follow-up to the flat-view night entry below. The farmhouse's warm pools in front of its
  south wall (the shoji door and the two shoji) began at the wall line z 3.6, so 6.4 px of each
  pool lay over the roof's last row (the house boxes are cells y 1..3 in FarmGrid.generate, so
  the roof's lower edge is z 4 = 64 px). NightView (flat view only) now cuts a south-facing pool
  at that edge: `FARM_ROOF_EDGE` (set on the farm in `setup`), `pool_shape` (the polygon and its
  falloff UVs) and `clip_top` (Sutherland-Hodgman on the one edge, the cut points keep their
  UVs), so the falloff keeps its shape on the part that shows. The side window's pool (it lies
  beside the house, east of x 7) and the 3D view (NightLights.pools_from, unchanged) are not cut.
- Checked: test_view2d `_night`, farm part: three south pools (door and two shoji), the raw pool
  reaches above y 64, the cut ones are all at y >= 64 and have at least 3 points; the east pool
  is not cut. Screenshot `main_2d.tscn -- --demo --time=21:00`: at x 60 the pixels from y 58 to 63
  are the house (55,35,30) and (70,45,36) with the pane strips, y 64 is ground (28,52,41), and
  the first pool pixels are at y 65 (64,75,53). All 27 test scripts `OK (0 failed)` (test_view2d
  after the fix: `test_view2d: OK (0 failed)`); smoke runs (title `--quit-after 300`, `-- --demo`,
  `-- --demo --map=town`, `-- --demo --mine=3`, and main_2d at 21:00) print no error or warning
  line.
- Left / next: the village houses' pools start 2.3 px above the footprint's bottom edge, and their
  flat box is drawn 1 px inside it (`grow(-1)`), so about 1.3 px overlaps the box. Not changed:
  the village test expects the pool on the wall line, and the overlap is a pixel. The farmhouse's
  window halos (a square about 77 px) and the pane strips still sit over the house box, as they
  stand on its walls; only the pools were in scope.

## 2026-11-05 — Thai: the last gaps
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: follow-up to FEEDBACK item 1. The 133 texts lang_report listed as missing for th.
  Translated (data/lang/th/ui.json +108, items.json +2): the chick and the mizuhiki knot, the
  hens / barn animals out all night, Tome's goal list (the HUD tag, "Goal done: %s!", the six
  goals, the chick reward "ได้%sมาอยู่ในเล้า"), the tool and rod level-up lines, the rope lift's
  message and choices, Sayo's and Fumi's away notes, Hachiro's build notes (finished, away, late
  by a storm or his birthday; signed -ฮาจิโร่), the long date "%s, Year %d"
  ("วันที่ 15 ใบไม้ผลิ ปี 1"), "%d %s" in "Bought %s" (Thai "{2} x{1}", as "%s x%d"), and every
  saved-game, key / pad and settings error (shown after "โหลดเซฟไม่ได้: %s" on the title), all
  as "ข้อมูล...ในเซฟเสีย". The Thai notes have no quote marks (the pixel font has no `"`
  glyph; test_menu's glyph check caught it), the colon after "มีโน้ตวางบนเคาน์เตอร์" sets the
  note off. Kept as they are, on purpose: the pad button names A / B / X / Y,
  LB / RB / LT / RT, L3 / R3, Guide, Start (printed on the pad; the D-pad and right stick
  directions are Thai: "D-ขึ้น", "RS-ซ้าย"), "+%d G", and "English" in the language list (each
  language is named in its own words, as "ไทย" is). Left out of LangCatalog instead of
  translated, because the player never sees them: data/recipes.json `taught` (where a lesson
  comes from, a note for readers; no script reads it; KEY_SKIP), the night-light layer node
  names (Pools, Halos, Panes, Glows, Figures) and the class name Sprite3D, the regex "[A-Za-z]",
  the "{%d}" placeholder and lang_report's own "%s: \"%s\"" (NOT_SHOWN), and the game's name
  "Harvest Son" on the title, which stays as it is in every language.
- Checked: lang_report --lang=th: before "th: 1558 of 1691 done (92%), 133 missing, 0 stale"
  (dialogue 889 of 889, data 310 of 377, code 359 of 425); after "th: 1668 of 1668 done (100%),
  0 missing, 0 stale" (dialogue 889 of 889, data 364 of 364, code 415 of 415). All test scripts
  print OK (0 failed); smoke runs (title, --demo, --map=town, --mine=3) print no error or warning
  lines. Screenshots with --lang=th: the smithy screen (`--building=kitchen --shop=smithy`) and the
  controls menu (`--pause=controls`, the pad column's "D-ขึ้น" ... fit their column).
- Left / next: none for Thai; new English text needs its Thai entry (lang_report lists it).

## 2026-11-05 — Pad button names: PlayStation style
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: follow-up to the key hints' pad buttons. data/controls.json `pad_names_ps` (Cross, Circle,
  Square, Triangle, L1 / R1, L2 / R2, Share, PS, Options; sticks and the D-pad as before).
  `Controls.style_of(name, guid)` calls a pad PlayStation by Sony names (PS3 / PS4 / PS5,
  DualShock, DualSense, PlayStation, Sony) or the vendor id 054c in its SDL guid, else Xbox;
  `Controls.pad_name(button, style)`. `Game` remembers the device of the last pad input
  (`pad_device`), `pad_style()` (the new setting `pad_style` Auto / Xbox / PlayStation in
  data/settings.json after Key hints, or what the last pad is) and `pad_text(button)`; a
  change of pad while the pad is in use redraws the hints. `ActionHints.key_text` and the controls
  page use it (the pause menu reads `Controls.style_now`, kept by Game, because it has no Game
  to ask in tests). Thai: "Pad buttons", "Auto", "Xbox", "PlayStation" in data/lang/th/ui.json
  (button names stay as written, like the Xbox ones). README Settings.
- Checked: test_menu `_pad_style` (names from Sony / Xbox / Switch / guid, every input has a
  PlayStation name, Auto with an Xbox and a PlayStation pad, the setting wins either way, the HUD
  label and the controls page, saved and reset); all 27 test scripts `OK (0 failed)`; smoke runs
  (title, --demo, town, mine=3) print no error or warning lines; `--demo --pause=settings` frame
  shows the row "Pad buttons: Auto" under Key hints. Not tried with a real pad.
- Left / next: pad names are not translated; the Nintendo layout (A / B swapped) is shown Xbox style.

## 2026-11-05 — Night in the flat view: lit windows, lanterns and warm pools
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: follow-up to FEEDBACK item 6. The flat view (scenes/main_2d.tscn) now shows what the 3D
  view got at night. New `LitSpots` (scripts/world3d/lit_spots.gd) is the one layout of lit
  windows and lantern fire boxes in map units (the farmhouse, the village houses with their
  doors, side doors and the noren rule, the stone lanterns); FarmWorld and MapWorld build their
  shoji pictures from it (positions unchanged) and `NightLights.pools_from(windows, lamps,
  glow, rules)` (split out of `pools_of`) works the pools out for both views. New `NightView`
  (scripts/world/night_view.gd), a child of the FarmView / MapView put in by main_2d: it reads
  `Game.window_light()` (the same timing helper: dusk / dawn rise, lit hours) and data/light.json
  "windows" / "pools", and draws from above a 2 px warm strip on each lit window and door, a
  dithered round halo, a lantern's glow with a 4 px fire, and the pools as dithered steps (a Bayer
  pattern on world pixels, so it stays pixel-art at any zoom). It lies under the villagers,
  animals and the farmer (they are drawn after it), so nothing in front is tinted. Because the
  scene's CanvasModulate multiplies everything after the shader, the shader divides its colour
  by `tint` (set by main_2d), so the light lands on the night ground as in 3D.
- Checked: test_view2d `_night` (NightView on the village and the farm, spots = LitSpots, pools =
  NightLights.pools_from, full at 21:00, 18:30 between and the pools scale with it, none at noon,
  lit again at 5:30, the farmhouse's four windows, draw order under the figures, tint divided out);
  test_maps: the town's 3D windows and lanterns equal LitSpots.of_map. All 27 test scripts
  `OK (0 failed)`; smoke runs (title, --demo, town, mine=3, and main_2d at 21:00 in the town) clean.
  Screenshot `main_2d.tscn -- --demo --time=21:00` (frame 19): ground under the left window
  (36..56, 62..66) averages (104.7, 84.2, 55.7) against (28.0, 52.0, 41.0) 40 px off to the left
  (so warmer and brighter); the window strip pixel (255, 238, 136) over a wall at (129, 87, 57);
  the farmer standing in the door keeps his own colours.
- Left / next: the glow is not hidden by buildings in front (from above nothing is); the farmhouse's
  pool begins at the engawa line, 6 px over the roof's edge. No new text, so no Thai entries.

## 2026-11-05 — Thai: heart events, contests, marriage, record
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: follow-up to FEEDBACK item 1. Thai (keyed by the English line, as before) for every
  line of data/dialogue heart_events.json, heart_events_5.json, heart_events_6.json,
  contests.json, marriage.json, ending.json (the village record's pages), goals.json (Tome's list
  notes) and the last opening line: 267 entries in one block at the end of
  data/lang/th/dialogue.json. In data/lang/th/ui.json: the spouse line ("Married %s on %s" ->
  "แต่งงานกับ%s เมื่อ%s", "Married to %s"), the mizuhiki knot refusal, the wedding-day message and
  tag. The wedding date: `Game.short_date_of` now builds "Spring 14" from the new const
  `Game.SHORT_DATES` ("Spring %d" ...), so each season-day is a catalogued text a table words
  itself; Thai puts the day first ("เมื่อวันที่ 14 ใบไม้ผลิ"). English output is unchanged. Voices:
  Tome is "ยาย" to her "หลาน", Kota a boy, Sayo and Fumi warm, Hachiro and Ichiro short and
  gruff, Tsuru formal; names as in the Thai name tables. The _note at the top of dialogue.json
  was left alone (another change edits the same file) and still says heart events and contests
  are English.
- Checked: lang_report --lang=th: before 784 of 1685 done (dialogue 124 of 889, data 305 of 377,
  code 355 of 419); after 1060 of 1688 (dialogue 391 of 889, data 310 of 377, code 359 of 422),
  0 stale. All 28 test scripts print OK (0 failed); smoke runs (title, --demo, --map=town,
  --mine=3) print no error or warning lines. A `--demo --map=town --event=heart_fumi_5 --lang=th`
  frame shows Fumi's first line in Thai in the text box.
- Left / next: the villagers' daily talk (talk_*.json) came in the parallel branch (next entry);
  shop lines, recipes, goals names etc. are listed by `lang_report --list`.

## 2026-11-05 — Thai daily talk (FEEDBACK item 1 follow-up)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: Thai for every line of the villagers' daily talk: the twelve talk files
  (data/dialogue/talk_fumi, genzo, hachiro, haru, ichiro, kiku, kota, nana, sayo, shige, tome,
  yae; 498 lines: greetings, seasons, forage tips, gifts, festival, heart band and married
  lines) in data/lang/th/dialogue.json, keyed by the English line like the rest, in one block at
  the end of the table. rainy_day and pond_first already had Thai. Voices: Tome and Kiku are
  grandmothers (ยาย, the farmer หลาน), Kota and Nana children (ผม / หนู, the farmer พี่), Hachiro,
  Genzo, Ichiro and Shige men (ผม; Ichiro short and dry), Sayo, Fumi, Haru and Dr. Yae (ฉัน,
  the farmer เธอ); names as in data/lang/th/items.json. Spaces split the phrases for the
  wrap. The table's `_note` still lists the daily talk as English; left for the merge with the
  heart event / contest Thai being written alongside.
- Checked: test_lang `_thai_dialogue_fits` (new): every dialogue line with a Thai entry fits the
  box's 4 rows at the width beside a portrait, no row wider than the text, and no talk_*.json
  line left in English. tools/lang_report.gd -- --lang=th before: "th: 784 of 1685 done (46%),
  901 missing, 0 stale", dialogue "124 of  889"; after: "th: 1282 of 1685 done (76%), 403
  missing, 0 stale", dialogue "622 of  889". Screenshot `--demo --map=town --time=14:30
  --talk=tome --lang=th`: Tome's box shows "หืม? อ้อ ชาวไร่คนใหม่ ทางข้างบ่อน้ำ เป็นโคลนนะ
  ระวังลื่นล่ะ" on one row. All test scripts `OK (0 failed)` (test_menu and test_save failed
  once in the full run while another worktree's tests ran at the same time, and passed alone
  right after); smoke runs (title, --demo, town, mine=3) print no error or warning lines.
- Left / next: Thai for heart events, contests, marriage, ending lines (another task).

## 2026-11-05 — Key hints: the last device used (pad buttons for pad players)
Agent: Claude Code (claude-sonnet-5-5) · Commit: this commit
- Done: follow-up to "Key hints: what E / Space do at the spot in front". `Game._input` calls
  `Game.note_input`: a pad button press or a pad axis pushed to `PAD_DEADZONE` (0.5) sets
  `Game.pad_active`; a key press or mouse click clears it; mouse movement and drift below the
  deadzone change nothing. `input_device_changed(pad)` fires only on a real change and the HUD
  redraws its hints then. `ActionHints.key_text` returns the action's pad name from
  `Controls` (data/controls.json pad_names: "A", "B", "LB", "Start"; the player's own binding)
  while the pad is active, and the key when the action has no pad button. The controls page
  already shows keys and pad buttons side by side, so it needed no change; no new visible text,
  so no new Lang or Thai entries.
- Checked: test_menu `_last_device` (button and key switch, drift and mouse movement don't, a
  push does, one signal per change, HUD labels B / A on the pad, Y after remapping, keys again
  after a key press); all test scripts `OK (0 failed)`; smoke runs (title, --demo, town, mine=3)
  print no error or warning lines; `--demo` frame still shows "Space Till".
- Left / next: only the bound buttons of the Xbox-style names are shown; no PlayStation names.

## 2026-11-05 — Village record: the spouse's line
Agent: Claude Code (claude-haiku-5-5) · Commit: this commit
- Done: FEEDBACK item 3's follow-up ("no word about the spouse in the village record"). A
  married farmer's record (the year 3 ending and the yearly pages, one `show_ending`) has one
  line under the title: "Married Sayo on Spring 14". `Ending.spouse_line` (scripts/ending/ending.gd)
  fills the texts from data/ending.json `spouse` ("Married %s on %s", undated "Married to %s");
  `Game._spouse_line` gives the record `spouse` from the flag `spouse`, the name from Villagers
  and the day from `wedding_day`. `Game.short_date_of` ("Spring 14") is the new helper; `date_of`
  uses it. Choice: the wedding day flag is kept after the wedding (the two wedding events no
  longer clear `wedding_day`), so the date survives; it is the day the wedding was set for, which
  is the day it is held on unless the farmer first walks into the village a day or more later.
  Saves married before this have no date and get "Married to Sayo". Unmarried: no line. Grading is
  unchanged. EndingScreen (scripts/ui/ending_screen.gd) has a line under the seal for it: the
  paper is 11 px taller for every save, married or not, because the layout is fixed at build time
  (a blank strip, not text). The line is English only; no Thai entry yet (falls back to English).
- Checked: test_ending gets `_spouse`: the dated, undated and empty lines, the widths for the
  line in both forms (inside the paper, pseudo-free), a single record with no line, the married
  record naming Sayo and Spring 14, the screen showing it after the rows, `_on_paper` for it, the
  yearly page undated without a day, and nothing shown once single again. test_relationships'
  wedding check now expects `wedding_day` kept (it asserted cleared). Results (scratchpad run,
  one line each):
  test_animals: OK (0 failed) · test_audio: OK (0 failed) · test_body: OK (0 failed) ·
  test_cooking: OK (0 failed) · test_dialogue: OK (0 failed) · test_ending: OK (0 failed) ·
  test_events: OK (0 failed) · test_farm: OK (0 failed) · test_festivals: OK (0 failed) ·
  test_fishing: OK (0 failed) · test_food: OK (0 failed) · test_forage: OK (0 failed) ·
  test_goals: OK (0 failed) · test_hold: OK (0 failed) · test_inventory: OK (0 failed) ·
  test_lang: OK (0 failed) · test_maps: OK (0 failed) · test_menu: OK (0 failed) ·
  test_mine: OK (0 failed) · test_relationships: OK (0 failed) · test_save: OK (0 failed) ·
  test_shops: OK (0 failed) · test_talk: OK (0 failed) · test_title: OK (0 failed) ·
  test_view2d: OK (0 failed) · test_villagers: OK (0 failed) · test_weather: OK (0 failed).
  Smoke runs (title, --demo, --demo --map=town, --demo --mine=3) exit 0 with no error or
  warning lines. Screenshot `--demo --ending --flags=married_sayo,spouse=sayo` (frame 149): the
  line "Married to Sayo" sits under the title's seal and fits the paper; this run sets no
  wedding day, so the undated form shows (the dated form is the same length class and is
  checked by the width test). shots/ deleted.
- Left / next: no Thai for the line (data/lang/th has no marriage lines yet either). The blank
  strip under the title on single saves is a fixed layout cost; a dynamic reflow would remove it
  if it bothers anyone. The date is the wedding's set day, not the day it was actually held when
  the farmer was late to the village.

## 2026-11-05 — Night: warm pools under windows and lanterns, the glow kept off figures
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the follow-up to FEEDBACK item 6 (WORKLOG 2026-11-04 "Night", Left / next).
  `NightLights` (scripts/world3d/night_lights.gd) now draws three passes in the tint's layer:
  (1) a soft warm pool on the ground (additive, a ground quad with a round falloff cut into
  six dithered steps through a 4 x 4 Bayer, like the mine lantern) in front of every lit
  window and shoji door, against its wall, and round the foot of every stone lantern;
  (2) after a BackBufferCopy, the panes and halos as before, plus a small glow round each
  stone lantern's fire box (Shrine.stone_lantern now records it with `FarmWorld.lit_lamp`,
  kept in `FarmWorld.lamps`); (3) the figures (the farmer, villagers, animals and the dog,
  marked with `NightLights.figure`, with their held item / note children) that stand in front
  of a glow are drawn back from the copy over their own pixels (a screen-reading shader, the
  sprite's alpha as the mask), so the glow behind them no longer tints them. In front means:
  overlapping the glow on screen, out past the window's wall (for a lantern, nearer the eye),
  and not hidden behind a solid building (`NightLights.hidden`; else the hole would show).
  The pools sit under the copy, so someone standing in one keeps its light. Real lights were
  not used: the night is a multiply tint over the whole picture, so any warm light in the 3D
  scene comes out at most the tint's red (0.25); the overlay costs one quad a pool and no
  shadow maps, cheap for the village's 40-odd windows. Numbers ours, in data/light.json
  "pools": colour ff9a48 (a deeper orange than the panes so lit ground reads warm over the
  blue), window pools 0.34 strong (a bigger pane, a door, up to 1.5 times), two window
  widths across (at least 1.2 cells), 1.6 cells out; lanterns 0.42 in a 1.2-cell circle, the
  fire box glow 0.45 over 0.7 cells (1.1 washed the whole lantern out). They scale by
  `Game.window_light()`, so they rise and fade on the windows' dusk / dawn schedule and lit
  hours; a pool or lantern behind a solid building is not drawn, behind a faded one by its fade.
- Checked: test_maps `_light_pools` (the town's 2 stone lanterns in `lamps`; one pool a lit
  window and lantern; on the ground; none at glow 0; a window's pool starts at its wall and
  lies out in front, a lantern's a circle round its foot; at 12:00, 17:00, 18:30, 19:00,
  21:00, 23:50, 1:00, 2:00, 5:30 and 6:40 the pools' strengths are their full strength times
  the windows' glow, none when it is 0; a house in front hides a pool, the house that casts
  it never does), `_glow_off_figures` (shielded: in front and overlapping yes, behind the
  wall no, away on screen no, a side window by its +x wall, a lantern by nearness to the eye;
  a sprite's quad corners; hidden behind a solid house, not in front, not once it fades) and
  `_start_view` (the passes in order: pools, copy, glows, figures; the figures' shader reads
  the screen; the farmer is a figure). With the pools' glow gate removed, test_maps fails 7
  checks. A/B frame (`--demo --map=town@sayo --time=21:00`, the farmer beside Sayo's lit side
  door) with the figures pass switched off: 558 farmer pixels differ, mean RGB with the pass
  (30, 27, 49) (the night blue) against (55, 43, 57) without (warmed by the door's halo).
  All 27 test scripts `OK (0 failed)`; smoke runs (title, --demo, --demo --map=town, --demo
  --mine=3, --demo --time=21:00, --demo --map=town --time=21:00, --demo
  --map=sakurazaka@bridge --time=21:00, --demo --map=barn --time=21:00) print 0 error or
  warning lines. Frames at 21:00: the farm (warm pools under the three windows and the door,
  the farmer before the door not tinted), the town (the pool before the house door),
  Sakurazaka's bridge (the four lanterns' fire boxes glow, a pool round each foot).
- Left / next: the pools are not occluded per pixel (a whole pool shows or hides by its
  middle) and draw over a figure standing just in front of one (only the window and lantern
  glows are kept off figures); trees and props in front of a window still get its glow; the
  festival lanterns (FestivalGlow) still glow over figures; the flat view has no pools.

## 2026-11-05 — Art direction: grass tufts on the grass cells
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: section 2's second item. `scripts/world3d/grass_tufts.gd` (GrassTufts) is one
  MultiMesh of a five-blade tuft (a triangle a blade, both faces) per world: on the farm's
  bare untilled grass (no crop, thing or item lying there, not a fixed cell; replanted from
  `_rebuild_objects` only when the grass cells changed, so a swing on soil costs nothing),
  on outdoor maps' free grass cells with no prop (MapWorld), and on the apron's grass past
  the edge (Surroundings). Up to two a cell, 70% kept; place, turn, size and shade come from
  a hash of the cell, so tufts never move. The shader sways the tips (height share squared,
  phase by place) and lights them as the ground: normal up on both faces, the sun only at
  SnowLayer.SUN_SHARE. Tip colour by season (spring 92d464, summer 74b44a, fall straw
  c4b060, winter dry a89a68), the base 80% of it. Each tuft carries its cell's snow hold in
  its custom data and folds away where SnowLayer's noise makes the ground under its root
  white; its material is kept with the world's snow so set_snow drives it. First frames had
  the tufts dark olive: with culling off, the back faces turned their normals down and lost
  the sky light; the normal is now set to world up in the fragment shader.
- Checked: new test_maps `_grass`: tufts inside their cells, 70% of places within 10, the
  same each time; Kaminoda's tufts only on free grass with no prop, each with its cell's snow
  hold, the material in `_snow_mats`; the apron grows them; none in the house; on a
  generated farm none on tilled ground, things or fixed cells, and tilling a grassy cell
  clears its tufts. The MultiMesh's own data reads back empty under the headless renderer,
  so GrassTufts keeps `planted` for the test. With MapWorld's "no prop, not solid" rule
  removed the test fails ("573 tufts, 90 off free grass"). All 27 test scripts `OK (0
  failed)`; smoke runs (title, --demo, --demo --map=town, --demo --mine=3, --demo
  --map=kaminoda --season=winter --snow=80, --demo --map=house, --demo
  --festival=blossom_day) print 0 error or warning lines. Frames: the farm, Kaminoda in
  spring / summer / fall / winter at snow 50, at 20:00, the town at 10:00 and in rain.
- Left / next: the tufts don't part round the farmer or bend harder in a storm. Next in
  section 2: rice and tall crops as clusters of pixel sprites.

## 2026-11-05 — Art direction: trees as lit, seasonal meshes
Agent: Claude Code (claude-opus-5-5) · Commit: 578b60c
- Done: section 2's first item. `scripts/world3d/trees.gd` (Trees) builds every tree from
  `Shrine.lathe` and `FarmProps.block` in lit materials, replacing unshaded spheres,
  cylinders and cones. `Trees.broadleaf` (persimmon, sakura): a lathe trunk, limbs, and a
  crown of six faceted seven-sided lumps (darker round the middle, lighter on top, turned by a
  seed so no two trees match); leaves by season (`Trees.LEAVES`), bare in winter with five
  limbs and twigs, persimmons in fall and still hanging on the bare twigs in winter (the fall
  leaf went from c06a2a to a8402c, deep enough red for the orange fruit to show), petals
  under a cherry in bloom. `Trees.pine`: four tiers of low faceted cones, darker below; the
  village's pines (`garden`) lean, their tiers set off to alternate sides on short limbs;
  snow lies on each tier's top where the map has snow. Used by MapWorld's `pine`,
  CountryProps' `persimmon` / `sakura` (its `_tree` removed), FestivalProps' cherries and
  Surroundings: the wood past the map's edge is now three pine shapes in MultiMeshes, turned
  per cell, with snow on its tiers driven by set_snow (it had no snow before).
  `FarmProps.Parts` grew `meshes()`, `material()` and `casts_shadow()` so a MultiMesh can use
  its meshes. A first try at the pines as rounded pads read like umbrellas in the wood;
  steeper overlapping cones keep the conifer outline.
- Checked: new test_maps `_trees`: persimmon and sakura in all four seasons (two seeds) are
  all lit ArrayMeshes, faces wound right, inside 0.95 of the trunk and under 2.3 high,
  leaves except in winter, fruit only on persimmons in fall / winter, petals only under a
  cherry in spring; pines (garden or not, snow or not) inside the wood's margins once scaled
  1.3, snow only when asked; Kaminoda's wood is MultiMeshes with its snow materials in the
  world's `_snow_mats`. All 27 test scripts `OK (0 failed)`; smoke runs (title, --demo,
  --demo --map=town, --demo --mine=3, --demo --map=kaminoda --season=winter --snow=80, --demo
  --festival=blossom_day, --demo --map=hill) print 0 error or warning lines. Before / after
  frames: the farm (spring, winter at snow 80), Kaminoda in spring / fall / winter and at
  17:00, 20:00 and in rain, the hill (spring, winter), the town, Blossom Day.
- Left / next: the bamboo is still cylinders and boxes; bare branches carry no snow. Next in
  section 2: grass tufts on grass cells (MultiMesh, a small wind sway).

## 2026-11-05 — Art direction: the rooms' furniture as lit meshes
Agent: Claude Code (claude-opus-5-5) · Commit: 0f662b2
- Done: the next item of docs/ART_DIRECTION.md. `scripts/world3d/room_props.gd` (RoomProps)
  builds all 22 furniture kinds of the rooms (futon, low table, tansu, andon, kamado, mizuya,
  nagamochi, kotatsu, counter, shelf, rice sacks, forge, anvil, tool rack, water tub, irori,
  tokonoma, butsudan, zabuton, byobu, toy box, mizugame) from `FarmProps.block` and
  `Shrine.lathe` in lit materials, one mesh per material per piece. They replace MapWorld's
  box / cylinder versions (mostly unshaded flat colours) and HomeProps (file removed). New
  shapes: a two-section tansu (drawers, warabite pulls, corner plates, a sliding door, a side
  handle), a turned chabudai with a teacup and teapot, a kamado narrowing to its lip with an
  arched fire mouth, a flanged rice pot and two logs, a mizuya with a shoji lattice, a futon
  with a puffy quilt and a pale collar, a counter with battens, a kickboard, a bell on a
  cushion and an account book, shelves with boxes and turned jars, tawara lying on their
  sides with rope bands, the forge's hood narrowing into the chimney and a box bellows, an
  anvil waisted on a stump, the irori's turned kettle and fish catch, the butsudan's doors
  swung open on gold, a zig-zag byobu with painted hills. A tool rack longer in z than x now
  hangs on the left wall (Ichiro's floated mid-room before). Only light-givers stay
  unshaded (`RoomProps.GLOWS`: the andon's paper, embers, the forge fire, a candle flame)
  through the new `FarmProps.Parts.glow` (no shadow). `RoomProps._placed` turns a part via
  SurfaceTool.append_from with a transform (bales on their side, open doors, screens).
- Checked: new test_maps `_room_props`: every prop of these kinds on every map builds with
  no primitive meshes, nothing unshaded but GLOWS, every face wound to its normal, inside
  its footprint (+0.16), clear of the back walls by 0.035; every kind is used by a map file;
  the andon, kamado, forge, irori and butsudan glow. It caught the counter top and the shelf
  cap reaching 0.01-0.03 into the left wall's posts (trimmed). `_homes_3d`' mesh floor went
  from 60 to 30 (the pieces merge per material now). All 27 test scripts `OK (0 failed)`;
  smoke runs (title, --demo, --demo --map=town, --demo --mine=3, --demo --map=house
  --built=kitchen,chest,room, --demo --map=smithy, --demo --map=tome_house) print 0 error or
  warning lines. Before / after frames at 10:00 of the house with every extension, clinic,
  store, smithy, teahouse, Tome's (6:30), Ichiro's, Kota's and Shige's houses.
- Left / next: the coop and barn insides (nests, feed boxes, stalls, hay) and the outdoor
  small props (well, jizo, woodpile, river rock) still use boxes; section 2, nature, is next
  (trees first). Rooms keep a fixed light, so no night check was needed.

## 2026-11-04 — Art direction: interiors, walls and floor edges as lit meshes
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the next item of docs/ART_DIRECTION.md. `scripts/world3d/room_walls.gd` (RoomWalls)
  replaces MapWorld's per-cell wall boxes (mostly unlit) with lit meshes built from
  `FarmProps.block`. Back walls (top row, left column): a timber frame, posts every other cell
  and at the inner corner 0.04 proud, board skirting under a rail, recessed plaster, a
  nageshi beam at 1.28 and a head beam at 1.7; a shoji window in a dark frame with a plank
  sill every fourth cell, now under the nageshi. Front walls: a low board sill (0.27) on the
  room side of the cell with post stubs, stubs each side of the door; the rest of the cell
  shows the dark ground (the old full-cell sill read as a heavy band). Inner walls (the
  farmhouse's added room) are a low sill down the middle of their cells. A step edge
  (agari-kamachi) where boards or tatami meet the earth and a flat shoe stone below the
  door's step when that earth is clear. New map key `walls` ("plaster" / "board"): the coop
  and barn have cedar board walls and no shoji. The floor picture darkens softly along the
  walls (`MapWorld._shade_corners`: 30% at the back walls, 14% at the sills, over 7 px),
  standing in for the ambient occlusion the Compatibility renderer lacks. Lit, the back wall
  (towards the sun) and the left wall (in shade) now read apart.
- Checked: new test_maps `_room_walls` (house, clinic, store, smithy, coop, barn: every face
  wound to its normal, nothing unlit, the back wall's face at most 0.05 out (the ribbon board
  hangs at 0.08; the first window sill stood 0.07 out and failed it, now 0.045), front sills
  0.4 or lower, plaster vs board by `walls`, the shoe stone where the earth is clear, a bad
  `walls` value refused). All 27 test scripts `OK (0 failed)` (test_talk printed nothing in the
  batch run while screenshots ran beside it; alone: `test_talk: OK (0 failed)`). Smoke runs
  (title, --demo, --demo --map=town, --demo --mine=3, --demo --map=house, --demo --map=barn,
  --demo --map=house --built=room) print 0 error or warning lines. Before / after frames at
  10:00 of the house, clinic, store, Tome's house, teahouse, smithy, coop, barn and the house
  with all extensions and the ribbon board.
- Left / next: the furniture (futon, tansu, andon, kamado, counter, shelves, forge) is still
  plain boxes, mostly unlit; rebuild it with `FarmProps.block` next. Rooms keep a fixed light,
  so no night check was needed.

## 2026-11-04 — The English polished: one spelling, one way to write names and messages
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: step 2 of the language plan. Read all 1691 English texts through
  (`tools/lang_report.gd -- --english` writes them to build/lang/english.txt by place) and
  wrote the rules down in docs/STYLE_EN.md. American English throughout, since the seasons
  already say Fall: favorite, neighbor, honored, traveler (Passing Traveler), Neighbors, Gray
  stone, Mom (Kota), anymore, "in the mail", "an apartment with an elevator", "the calendar
  shows fall". Articles before a name were wrong for vowels ("Caught a Eel!", "Shipped a
  Eggplant"): now "Caught: %s!", "Caught: %s! %d in the creel.", "Shipped: %s (%d G).",
  "Picked up: %s.", "You won the %s!" (ribbons), "You won %s!" (prizes), "%s for the coop".
  Item and generic place names in sentence case (Golden yolk egg, Rich milk, Cloud wool,
  Animal medicine, Genzo's house, Sayo's rooms); proper names keep their capitals. Every
  message over the field and every shop / screen note is a sentence ending in . ! ? (about
  120 had none; "Game saved" and "Game saved." were both in use). Two more glued spots
  found and fixed: the animals' morning news (". ".join, now Lang.join) and the master tool's
  level-up line (a leading space in tools.json, now joined). A typo: "Lines up, everyone!".
  Thai keys renamed with the English (0 stale), the tests' expected messages too.
  test_lang now checks the style: no British spellings, no "a %s", item names in sentence
  case, every message in the scripts and the data ending like a sentence (a quoted note may
  end with its signature). The catalogue leaves out patterns, shader code and internal keys.
- Checked: all 27 test scripts `OK (0 failed)` (test_lang with the new style checks; 11
  scripts' expected messages updated); smoke runs (title, --demo, --demo --map=town, --demo
  --mine=3, --demo --lang=th) print 0 error or warning lines. lang_report: 1678 English texts
  (noise gone), Thai 784 covered, 0 stale, 0 glued pieces.
- Left / next: messages still name keys by their defaults ("I = rucksack", "Q = next seed",
  "E on an animal"), so a remapped key isn't shown; noted in STYLE_EN. The villagers' voices
  (Kota's "gonna", Tome's "child") are kept on purpose. Next language step: translate once
  the content settles.

## 2026-11-04 — Ready for translation: the English catalogue, whole sentences, a longer-language test
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the user aims at players worldwide, so step 1 of the language plan: make the game
  ready to translate. `LangCatalog` (scripts/ui/lang_catalog.gd) gathers the English: the
  dialogue, the words in the data files and the scripts' string literals (leaving out
  comments, print / error lines, the data checks' messages, ids, paths, art and sound
  scripts, NOT_SHOWN). `tools/lang_report.gd` prints per language how much is covered
  (`Lang.covered`: wholly, each %s part too, so a loose "%s, %s" no longer counts), the
  table entries no text uses (stale) and glued pieces, and writes build/lang/<id>_todo.json.
  About 25 places glued a sentence from pieces or put English words in, which no table can
  translate; each is now one whole key: the mine's "Found %s (rucksack full).", the animals'
  moods ("%s wags its tail"), "Sheared / Milked %s: %s", "You ate / drank the %s.", "Mine
  floor %d, %s", "Made %s x%d", "Your %s is back, now level %d (in the chest)", "closed %s",
  "any %s", "%s (buy at store)", "Written as: %s", "Could not load: %s", the shop's day /
  days, the season names (Game.SEASON_NAMES, they were id.capitalize()) and the tool rows'
  names (HudLayout.TOOL_NAMES: "Tool 2: Watering can", it said "Can"). Sentences said
  together go through `Lang.join` (each looked up alone), lists through `Lang.list` ("%s, %s",
  "%s and %s"), and the kitchen tools got an `a_name` ("an iron rice pot") in place of code
  picking a / an. Thai keys renamed to match (the old pieces removed); Thai got "a kitchen
  knife" etc., "%s, %s" and "Game saved.". A pseudo language (`--lang=pseudo`, no tables,
  every line padded a third wider with "=") finds what a longer language breaks: the HUD's
  goal tag measured the English (`PixelFont.width`, now `shown_width`), the clock now widens
  left for a longer date (a holder like the goal tag), the rucksack's place-name column is as
  wide as its widest name, and the shop's info line and the kitchen's recipe line wrap to a
  second row (both screens 11 px taller). README → Settings → Language says how to write
  text so it translates.
- Checked: lang_report before / after: 1691 English texts (dialogue 889, data 375, code
  427), 0 glued pieces (were ~25), Thai 785 done (46%: dialogue 124, data 305, code 356), 0
  stale (were 72). New test_lang `OK (0 failed)`: the catalogue's finds and leave-outs,
  join / list in English and Thai, pseudo, and every label on the HUD, the pause menu's
  three pages, rucksack, storage, the four shops' tabs and the kitchen inside its box and
  clear of its neighbours at +30%; every dialogue line still fits the box at +30%. With the
  goal-width fix undone the test fails ("Plant 9 plots 0/9===" 34 px out of its box).
  All 27 test scripts `OK (0 failed)`; smoke runs (title, --demo, --demo --map=town, --demo
  --mine=3, --demo --lang=pseudo, --demo --lang=th) print 0 error or warning lines. Frames of
  `--shop=general@build` in pseudo (the info line on two rows, the clock wider to the left)
  and in Thai (unchanged, one row) look right.
- Left / next: step 2, polishing the English. Thai still lacks 906 texts (most of them
  dialogue: the villagers' daily talk, heart events, contests); build/lang/th_todo.json lists
  them. Not checked at +30%: the title, the record, the mochi and race screens, the text
  box's choices. A lowercase one-word literal in a script ("ready") counts as text only when
  some table has it.

## 2026-11-04 — Art direction: the bin, chest and seed stand as meshes
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the three props by the farmhouse moved out of FarmWorld into
  `scripts/world3d/farm_props.gd` (FarmProps) and rebuilt from lit meshes instead of flat
  unlit boxes. `FarmProps.block` makes a tapered box (flat normals, UVs in world units, u along
  the edge, v down) for splayed sides and bevelled lids; `FarmProps.Parts` keeps one SurfaceTool
  per material. Bin: splayed cedar body on runners, corner battens, straw rope with knot, ends
  and a paper tag with a red stamp, bevelled plank lid with battens, a bevelled snow cap. Chest:
  tansu on a plinth, drawers with pulls, iron corner plates wrapping onto the +x face, side
  handle, bevelled lid. Stand: `Minka.gable` board roof, front eave 1.45 (was 1.32, under the
  1.45 rule), posts, tie beams, king posts, ridge beam and ridge board, a plank counter with a
  cedar front and side, three seed sacks turned with `Shrine.lathe` (burlap, neck cord, seeds
  heaped), honesty box with a coin slot, the noren 0.24 tall (was 0.32; it hid the counter) and
  a price board on the +x side (new `build:stand_sign`: brushed marks, no real text). New farm
  spawn `bin` (8, 6) to look at them; `house_model.gd --what=props` (with a nearer camera).
- Checked: test_maps `_farm_props` (a tapered block's 12 triangles all face out; bin, chest and
  stand: every face drawn the way its normal points, no unlit material; the stand's front eave
  1.45 or more). Frames of `--demo --map=farm@bin` at 10:00, 17:30, 20:30, winter snow 90 and
  rain: the bin, chest and stand shaded by the sun, snow caps on the lids and roof, the sacks
  visible under the noren. On a clean worktree of HEAD plus this change only (see the next
  line): all 26 test scripts `OK (0 failed)`; smoke runs (title, --demo, --demo --map=town,
  --demo --mine=3, --demo --map=farm@bin --season=winter --snow=80) print 0 error or warning lines.
- Left / next: another session was editing this checkout at the same time (cooking, recipes,
  lang, UI files; data/recipes.json mid-edit and unparsable); none of that is in this commit.
  Next art item: interiors.

## 2026-11-04 — Feedback items 4-8 merged into main
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged the three branches made in parallel by subagents: mine / dish balance (c336ef1,
  31b6d7f), night and lit windows (3365ff1), barn hay, title backing and safe saves (10b0184,
  34393ea). Conflicts only in WORKLOG / ROADMAP / FEEDBACK (both texts kept); the commit
  hashes filled in under FEEDBACK → Fixed. No feedback items are open now.
- Checked: on the merged tree all 26 test scripts `OK (0 failed)`; smoke runs (title, --demo,
  --demo --map=town, --demo --mine=3, --demo --time=21:00) print 0 error or warning lines.
- Left / next: the year bot and test_body / test_maps write the shared user://save1.json, so
  parallel Godot runs from worktrees can clobber the player's save (seen once, the file stayed
  whole). Thai for the new goal notes, marriage lines and daily talk is still to write.

## 2026-11-04 — "Saved food is broken": the title's check, atomic saves, a backup (FEEDBACK item 8)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: reproduced: the user's own save1.json (a complete file, `food` = `milk`) made the title
  say "The saved game can't be loaded: Saved food is broken". Cause: `SaveGame.check` loaded
  the file into a scratch Game that only had `crops`, so `foods` was empty and any saved food
  failed (the tests' games had no food table either, so they passed). The scratch game now gets
  every data table (`Game.DATA_TABLES`: crops, weather, tools, snow, body, foods, hold, fish,
  mine). Saving is made atomic as asked: `SaveGame.write` writes `<slot>.tmp`, reads it back,
  copies the slot it replaces to `<slot>.bak` when that slot is a good save, then renames the
  temp over the slot. Loading uses the backup when the slot is missing or cut off (never for a
  newer-version slot); the title then says "The last save is cut off; Continue loads the one
  before it" (`SaveGame.backup_note`). With no backup a cut file says "The save file is cut off
  or broken" and nothing changes. `SaveGame.snapshot` / `restore` keep the slot, backup and
  temp; test_body and test_maps (which sleep and so write the real slot) use them.
- Checked: test_save: the title's check passes a save holding milk (failed before the fix); the
  atomic write (no temp left, backup = the replaced save, a stray temp ignored and cleared);
  a slot cut in half loads the backup with the note; saving over a broken slot keeps the good
  backup; cut at 0, 1, 10, 1000 and length-1 with no backup: refused, game unchanged; a
  missing slot loads the backup; a newer slot is not swapped. The title frame with the user's
  real save now has Continue on and the cursor on it (it was off with the message). test_body
  and test_maps leave the real save1.json byte for byte (md5 the same before and after). All
  26 test scripts `OK (0 failed)`; the four smoke runs print no error or warning lines.
- Left / next: two Godots saving the same slot at once still race (last rename wins, the file
  is always whole). The real save1.json changed at 21:18 during this work (now with a `goals`
  key) from outside this worktree's tests; it is a whole, valid save.

## 2026-11-04 — Barn hay and the title's text backing (FEEDBACK item 7)
Agent: Claude Code (claude-opus-5-5) · Commit: 10b0184
- Done: the barn's "yellow lumps" were the hay bundles (barn_props.gd "hay") and the hay mounds
  in the trough (animal_layer.gd), both one flat unlit yellow (c8b060). They now use a lit
  material with a new `build:hay` texture (muted olive-gold grass strands, dark gaps), the
  bundles' rope bands `build:planks_dark`. The floor's `ground:straw` (coop and barn) is a
  denser, duller mat (30 stalks in three tones near the earth's, was 22 bright d8bc78 ones).
  Title screen: a paper-coloured wash (alpha 0.6, soft corners) behind the name and its
  vermilion stroke, and the note under the menu ("The saved game can't be loaded: ...") in its
  own paper frame sized to the text, instead of bare ink on the rice rows.
- Checked: frames of `--demo --map=barn` (and a spawn by the hay, added for the shot only):
  before, a flat yellow block in the lower right and bright straw flecks; after, stacked
  bundles with strands and shading, the bedding reads as straw. Title frame 39: the name and
  the note both readable, sky, hills and paddies still showing. All 26 test scripts
  `OK (0 failed)`; the four smoke runs print no error or warning lines.
- Left / next: the hay colour is our pick; real art may replace `build:hay`.

## 2026-11-04 — Night: a deep blue night and lit windows (FEEDBACK item 6)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the day / night table moved from game.gd to data/light.json "sky" (`Game.sky_at`,
  `light_data()` read lazily so tests without _ready get it). Daylight is unchanged (white
  7:00..16:00); the night is darker, 404c8e (luminance 0.31, was 0.42 / 0.45 / 0.72 = 0.46),
  reached at 20:30 through a warm 17:30 (ffd4a8), a mauve 18:30 (b88e9c) and 19:30 (625f9a);
  dawn runs 4:30 night → 5:30 7a74a4 → 6:30 e8cdbd → 7:00 white. Lit windows: the farmhouse's
  three shoji windows and its door, every village house's windows and side doors and the
  doors of homes (a shop's door under its noren stays dark) are recorded by
  `FarmWorld._lit_picture` in `windows`; `NightLights` (scripts/world3d/night_lights.gd, in
  main_3d's tint layer after the tint, additive) draws each window's own shoji picture in
  warm light (ffb25c) over its pane plus a soft halo, as bright as `Game.window_light()`
  (data/light.json "windows": 0 under 1 - luminance 0.25, full from 0.6, lit only 16:00..0:30
  and 5:00..7:30). A window turned from the camera or behind a solid building (an occluder box
  crossed by the line to the eye, not its own) stays dark; behind one faded see-through it
  shines by the fade. Numbers ours: the night blue was picked from screenshots so the farmer,
  paths, field and houses stay readable; windows go out at 0:30 since the village sleeps.
  The flat view gets the darker night (it reads Game.light_color) but has no windows to light.
- Checked: test_weather `_night_light` (daylight hours white, night blue, dark but over 0.2,
  darker than the old night by more than 0.12, dusk / dawn one-way with no 10-minute step over
  0.06, window glow off by day, at 2:00 and in a noon storm, full at 21:00, rising at
  18:30-19:00); test_maps `_lit_windows` (town's houses list windows, facing +z / +x, homes' doors
  lit, shops' not, how_seen: turned away 0, behind a solid box 0, behind a faded box = its fade,
  past it 1; corners; no lit windows in the house room) and the farm view has 4 windows and
  one NightLights. All 26 test scripts `OK (0 failed)`; smoke runs (title, --demo, --demo
  --map=town, --demo --mine=3, plus --demo --time=21:00 and --demo --map=town --time=21:00)
  print no error or warning lines. Screenshots (frame 19), mean luminance of the 3D picture
  without the HUD (crop 0,0-380,205), before → after: farm 21:00 42.9 → 34.7 (lit windows
  included), town 21:00 49.6 → 32.9, farm 18:30 89.0 → 57.5, town 18:30 104.9 → 64.3 (the 18:30 pair measured before the doors were lit too), farm 5:30
  71.8 → 49.8; farm 2:00 after 28.4. Noon unchanged: town 12:00 137.9 → 137.9 (the frames are
  pixel-identical), farm 12:00 113.1 → 112.6 (two runs of the same build already differ in
  ~1100 pixels: the farm frame is not deterministic). Looked at the frames: the farmhouse
  windows and door glow warm at 18:30, 21:00 and 5:30 and are dark at 2:00; Sayo's store side
  door and windows and Kaminoda's houses glow at 21:00.
- Left / next: no light falls on the ground round windows or lanterns (still the tint); the
  glow is a screen overlay, so a villager or the farmer standing right in front of a window
  gets its warm light on them; the flat view's houses have no windows.

## 2026-11-04 — Winter mine income halved again (FEEDBACK item 4)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: after the first cut (2026-11-03) a winter of daily lift trips from floor 15 still
  brought 73160 G, more than any whole season of the farm. data/mine.json: shirogane 40 → 30,
  kogane 55 → 30, hoshigane 220 → 110, jade 170 → 85, amber 100 → 55, rock crystal 70 → 40,
  frost stone 80 → 50 G; on floors 13+ a rock or soft spot hides nothing half the time (none
  36 → 50 and 40 → 50). Every find a deep floor hides is now worth about 695 G in winter (was
  1335); floor 10's band 470 (was 719); a frozen floor 9 with its ice 600 (was 933), still less
  than a deep one, so the lift stays the better trip. The landings (5, 10, 15) and the ores the
  smithy asks for are unchanged. data/festivals.json: the First Stone contest's rivals halved
  again (Hachiro 35-90, Kota 12-45, Sayo 6-32, Ichiro 22-65), so a hoshigane (110) still wins.
  Reasoning: winter has no field, so mining should be the winter's work and pay about what
  the animals do (26-27k G a winter), a good side income; it should not out-earn a farming
  season (year 1 fall 60936 G without the mine) or come anywhere near a farm year.
- Checked: year bot `tools/play_year.gd -- --years=2 --seed=1`, run alone, before (main with
  item 5's dish prices not yet in) → after (both items):
  ```
  Year 1 winter: income 100865 → 66433 G; mine 73160 → 38378, animals 26580 → 26930
  Year 1 mine by season: 2750 / 452 / 11788 / 73160 → 2320 / 422 / 6438 / 38378 (88150 → 47558)
  Year 1 income without mine and prizes: 169892 → 158118 G (dishes 25410 → 4430: item 5;
    fish 16670 → 22436, the fish are shipped raw now)
  Year 2 mine: 14605 / 16582 / 14647 / 86240 → 14518 / 3452 / 10592 / 43852 (132074 → 72414)
  Money at the end of year 1: 138552 → 86186 G; year 2: 445447 → 324078 G
  Record: 40 / 43 stars, rank 4, Deepest floor 22 (4 stars), contests won 6: unchanged
  play_year: OK (no problems seen)
  ```
  Year 1 now: the mine 47558 G against 158118 G from the farm; the winter mine (38378 G, less
  15390 G of stand food for the trips) is below the year's summer (44107) and fall (60936)
  farm income. test_mine gets `_worth`: a deep floor's finds under 800 G in winter, deeper
  floors still worth more, a frozen floor with its ice worth less than a deep one, hoshigane
  above every First Stone rival's top score. balance.py: year net 91587 → 87096 G, First
  Stone odds 88% → 90% first. All 26 test scripts `OK (0 failed)`; the smoke runs print no
  error or warning lines.
- Left / next: the bot still goes down every winter day; with the stand's food a winter trip
  nets about 800 G. FEEDBACK item 6 (night, lit windows) next.

## 2026-11-04 — Dish prices: a modest gain over the cheapest ingredients (FEEDBACK item 5)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: a dish's price is fixed but the fish group takes any fish, so one 18 G dace made an
  80 G grilled fish (+344%). The rule now (data/foods.json `_dish_prices`): a dish sells for
  about a third more than its cheapest ingredients shipped raw. Fish dishes: grilled fish
  80 → 25 G (18 G fish + 39%), ochazuke 130 → 80 (fish + 40 G tea, +38%), fish and daikon
  220 → 170 (+33%), dobin mushi 210 → 135 (+38%). The same shortcut with plain eggs and milk:
  tamagoyaki 120 → 80 (2 plain eggs, +33%), milk pudding 270 → 190 (+36%). A carp, a smelt,
  good eggs or good milk are now worth more raw than cooked; a dish is mostly for its stamina.
  tools/balance.py: the recipe table gets a "cheap" column (the best season's gain with plain
  eggs / milk and the season's cheapest fish, and that gain as a share of the raw price), and
  the steady plan no longer cooks tamagoyaki, milk pudding or grilled fish to sell (at the
  average grade they lose now): fall stays as it was minus tamagoyaki, winter is fish and
  daikon and kinako mochi.
- Checked: balance.py's recipe table, cheap column before → after: grilled fish 62 344% →
  7 39%, tamagoyaki 60 100% → 20 33%, ochazuke 72 124% → 22 38%, milk pudding 130 93% → 50
  36%, fish and daikon 92 72% → 42 33%, dobin mushi 112 114% → 37 38%; the rest unchanged
  (27-44%, but sansai tempura 338% and kinoko jiru 73%, made of cheap wild greens; left).
  balance.py year net 91503 → 91587 G. test_cooking gets `_prices`: every dish made from fish,
  eggs or milk sells for more than its cheapest ingredients and at most 50% more; a carp or a
  smelt is worth more raw than grilled; good eggs raw are worth a tamagoyaki (failed with the
  old 80 G as it should, then passed). All 26 test scripts `OK (0 failed)`; smoke runs print no
  error or warning lines. The year bot's numbers come with item 4 (next entry), run on both.
- Left / next: sansai tempura (2 greens at 8 G → 70 G) is the one cheap-ingredient outlier
  left; its greens are few a day, so it stays for now.

## 2026-11-04 — Marriage: courting ends at the shrine (FEEDBACK item 3)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: data/marriage.json + `Marriage` (scripts/villagers/marriage.gd). Candidates: Sayo and
  Fumi (the young friends; Tome, Kota, Hachiro and Ichiro are not). The proposal item is our
  own **mizuhiki knot** (`keep:mizuhiki`, a new keepsake with its own red / white knot icon),
  1500 G at the Yorozu Store all year. Held out to a candidate it is a proposal, not a gift
  (`Game.propose`): yes at band 6 after their band 6 scene and with the second room built
  (where would two live in one room); else they say why (`<id>_band`, `_room`, `_taken`,
  `_waiting`, `_married`) and the knot stays in hand; anyone else leaves it in hand with a
  message. Yes: the knot is taken, the flags `engaged`, `engaged_<id>`, `wedding_day` (3 days
  on, moved past festival days) set, and `propose_<id>` plays. From that morning
  `wedding_due` is set (morning message, HUD tag "Wedding day") until `wedding_<id>` has played
  (triggers_town.json from 10:00): the farmer before the shrine beside the bride, Tome ties the
  knot, Kota, Hachiro, Yae, Ichiro and the other candidate look on; it sets `spouse` and
  `married_<id>`. Married, Sayo / Fumi live at the farmhouse (by the kotatsu in the second
  room mornings and evenings, the store / teahouse by day; Sayo's Sunday tea at Tome's stays),
  with engaged lines and married lines at home (morning, evening) and out. Fumi got her band 6
  scene (heart_fumi_6: her mother's kettle, mended by Hachiro, pours its first cup for the
  farmer; a line of its own with `fumi_honest`; band 6 `dear_` lines) in the three tables
  she can be talked on. Tome mentions the knot on Fridays once a band 6 scene with a candidate
  is seen, and greets the newlyweds. The heart track plays for the new scenes. All state is
  story flags, so it saves with them. Numbers ours: 1500 G (a week of early shipping, small
  next to the 18000 G room it needs), 3 days to the wedding.
- Checked: test_relationships gets the marriage checks (the data, every answer in order,
  the wedding day past Blossom Day, due mornings, the trigger rows, the married plans and
  lines, Tome's hint, and in game: buying the knot, the answers with the knot kept, the
  proposal, three mornings, the wedding run to the end with the cast at the shrine, the flags
  after, a save and load); test_shops counts the knot in the store; test_villagers reads the
  plans with the extensions built. All 25 test scripts `OK (0 failed)`; the four smoke runs
  plus the wedding and a married farmhouse print no error or warning lines. Looked at the
  wedding (`--demo --map=town@shrine --time=10:00 --event=wedding_sayo`, frame 109): Tome by
  the shrine facing the couple, the guests at the sides, her first line in the box; and
  married Sayo in the farmhouse's second room at 19:00.
- Left / next: no word about the spouse in the village record yet, no spouse help on the farm
  or child; Ichiro has no band 6 scene. The farmer's own gender is never named in the lines.
  The see-through torii crosses Kota and Hachiro in the wedding frame (readable).

## 2026-11-04 — Feedback items 1-3 merged into main
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged the three branches made in parallel: Thai text (c3dce89, merge 0db242a),
  week-one goals (e3ad897, merge ff2d794) and marriage (be3a2bb, merge 379d92f). Conflicts were
  only in WORKLOG / ROADMAP / FEEDBACK / AGENTS.md (both texts kept), tools/house_model.gd.uid
  (main's uid kept) and game.gd (Goals and Marriage functions side by side). Adds the
  importer's tests/test_goals.gd.uid.
- Checked: all 26 test scripts `OK (0 failed)` on the merged tree; smoke runs (title, --demo,
  --demo --map=town, --demo --mine=3, --demo --lang=th --goals --map=town) print no error or
  warning lines.
- Left / next: the goal notes and marriage lines have no Thai yet (data/lang/th); FEEDBACK
  items 4 and 5 next.

## 2026-11-03 — Week-one goals: Tome's first-week list (feedback item 2)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: docs/FEEDBACK.md item 2 ("a slow start, no small goal in week one"). New
  `data/goals.json` (six goals, texts and HUD / message templates), `Goals`
  (`scripts/items/goals.gd`: done list, counted stats, the goal now, parse / save) and
  `data/dialogue/goals.json` (a thank-you note per goal from Tome, Sayo, Kota or Tsuru). The
  goals: plant 9 plots (+150 G), say hello to 3 people (3 rice balls), pick 4 wild plants (a
  bag of cucumber seeds), catch a fish (+120 G), ship 5 crops (2 bags of seed potatoes), earn
  1000 G from the cart (a chick in the coop; 700 G if the coop is full). Every goal counts from
  the first morning; `Game.check_goals` (a few times a second while the HUD listens and no
  menu, text box or event holds the screen) pays a reached goal at once, says it on the message
  line ("Goal done: Plant 9 plots! +150 G") and opens its note. `Game.goal_stats` counts
  planted plots, villagers talked to, fish, crops shipped from the run's own state, wild
  things picked (`forage_pick`) and the cart's pay (`pay_bin`) in `Goals.counts`. The HUD has a
  goal tag under the clock (right-aligned; in the festival tag's place on a plain day; hidden
  once the list is done). Tome hands the list over in the opening (one new line). Saved as
  `goals: {done, counts}` (no save version bump; a save without it has the whole list done so
  an old farm isn't flooded with rewards). Plain `--demo` runs have the list off; `--goals`
  (or `--goals=plant,hello`) turns it on. README → Goals, DESIGN (economy) note, AGENTS.md.
- Balance (ours): the 500 G start buys about six turnip bags and the first turnips are ripe on
  day 5, so the first four goals need nothing to ripen (day 1–3: the field, the village, the
  hill, the pond). The list is worth about 2,300 G (270 G cash, 180 G of rice balls, 480 G of
  seed bags, the chick, a 1,400 G hen at the store): small next to a season, but it brings the
  first new animal into week one instead of week three. Earn 1000 G is about day 7 for a player
  who works the field and picks forage.
- Checked: new tests/test_goals.gd (data, rules, every goal reached by playing on a scratch
  Game and paid once, several at once, a full coop and a full rucksack, notes waiting while a
  menu is open, the save, the HUD tag on the real Game) `test_goals: OK (0 failed)`; all 26
  test scripts `OK (0 failed)`; the four smoke runs and a 600-frame run of
  `res://scenes/main.tscn` (new game, opening, list on) print no error or warning lines.
  Screenshots: `--demo --goals=plant` (the tag "Goal Say hello to 3 people 0/3" under the
  clock), `--demo --goals` (650 G, "Goal done: Plant 9 plots! +150 G" and the farmer's line of
  the note in the text box), `--festival=blossom_day --goals=plant,hello,forage` (the tag under
  "Blossom Day").
- Left / next: the goal names are English only for now (the Thai text set is another agent's
  task; the strings are all in data/goals.json and data/dialogue/goals.json). The year bot
  (tools/play_year.gd) was not re-run. The flat view uses the same Hud, so it has the tag too
  (not looked at in a screenshot). A pause-menu page listing the whole list could come later.

## 2026-11-04 — Thai text: a language setting, data/lang/th, Thai glyphs in our pixel font
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: docs/FEEDBACK.md item 1. Esc → Settings → Language (first row): English / ไทย
  (data/settings.json `language`, saved in user://settings.json like the rest; `-- --lang=th`
  for one run). `Lang` (scripts/ui/lang.gd) reads data/lang/<id>/*.json, keyed by the English
  text: plain entries, patterns with %s / %d (the %s parts looked up again, {1} {2} to
  reorder), multi-line text line by line, a name lowered in a sentence still found; no entry =
  English. `LangTranslation` hands Godot's auto-translation to Lang, so every Label on screen
  switches at once without touching each `.text =`; the text box (DialogueRunner.text()),
  the cooking lists, the shop tabs and the widths (`PixelFont.shown_width`) ask Lang
  themselves. Game releases the translation on quit (the TranslationServer outlives scripts).
  Thai tables: ui.json (title, pause menu, settings, controls, HUD, key hints, rucksack,
  shops, kitchen, mochi / fishing race, village record, every message over the field, save
  errors), items.json (crops, animals, fish, food and dishes, forage, mine finds, keepsakes,
  kitchen tools, recipe notes, shops, maps, festivals, people, record rows, prop and door
  messages), dialogue.json (opening, first morning, shop greetings, pond, bin note, rainy day,
  clinic, farm / house / village / hill look-at lines, festival greetings, year record, recipe
  lessons: 103 entries, choices included). Written plainly for 15–20; Japanese dishes keep names Thai players use.
  Font: no system font and nothing downloaded: 47 Thai glyphs (39 consonants, 8 vowels and
  signs) drawn in data/font_pixel.json (5 rows at the lowercase height, ascenders for ป ฝ ฟ, descenders for ญ ฐ ฎ ฏ ฤ ภ) and 14
  marks in `marks`; PixelFont builds four placed copies of each mark in the Private Use Area
  (low, high over a vowel above, left over ป ฝ ฟ, both) and `PixelFont.shape` picks them and
  splits ำ into its ring and า. Not drawn yet: ฃ ฅ ฌ ฑ ฒ ฬ ฦ ๅ ฯ and Thai digits (the tables
  avoid them; the test fails if one is used).
  Plainer English: the onigiri note is "A rice ball with a quick pickle inside. Makes two."; a
  recipe whose kitchen tool is missing says which ("needs Clay pot", "needs 2 tools") and the
  tools line says "Clay pot (buy at store)" instead of "(store)".
- Checked: test_menu `_language`: the setting, the row text, Thai on / off through the
  TranslationServer, patterns, reorder, line by line, the English fallback, mark placement
  (ที่, ป้า, น้ำ), every Thai entry drawable with its parts, every Thai dialogue key still a line in
  data/dialogue and fitting the box (choices in their width). test_cooking: the row names the
  missing tool. All 25 test scripts print `OK (0 failed)`. Smoke runs (title, `--demo`,
  `--demo --map=town`, `--demo --mine=3`, plus `--demo --lang=th --map=town` and `--lang=th`):
  exit 0, no error or warning lines. Looked at (`--lang=th`): the settings page, the title
  menu, the HUD with the key hint, the rucksack, the Yorozu Store, the cooking screen and Tome's
  text box (`--dialogue=opening@field`): Thai draws, marks sit over their letters.
- Left / next: Thai for the villagers' daily talk (talk_*.json), heart events, contests and
  the ending scene; a native Thai reader should look over the glyphs (5 px high, some letters
  are close: ค ถ ศ, บ ข ช ซ). The flat view's labels translate the same way but were not
  looked at.

## 2026-11-04 — Shrine pieces as meshes: torii, hokora, stone lanterns
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: art direction roadmap 1, third item. New `scripts/world3d/shrine.gd` (Shrine) replaces
  MapWorld's `_torii`, `_hokora` and `_stone_lantern` (the town, the hill, Minamino,
  Sakurazaka, the mine entrance). The torii: tapered vermilion posts on black footings, the
  nuki with wedges, the strut with a plaque, the shimaki and the black kasagi as real beams
  (`Minka.beam`) rising 0.16 from the middle to the ends with the square of the way out, a
  snow strip on top. The hokora: a two-step stone base, a cedar body under a `Minka.gable` board
  roof (pitch 0.65) with plank gable ends, crossed chigi at both ridge ends and two katsuogi,
  two vermilion doors with gold rings, a straw shimenawa with zigzag paper streamers. The
  stone lantern: six-sided Kasuga style turned by `Shrine.lathe` (profiles of radius / height,
  flat facets, one face straight at +z): footing, round post, deck, fire box with warm
  windows on the two faces the camera sees, a wide cap with its corners turned up, the
  jewel; a snow cone on the cap. Pieces are lit (`Minka.plain`) where the old ones were
  unshaded, so the sun shapes them. Minka's helpers are now public (`quad`, `tri`, `beam`,
  `plain`, `add_mesh`). `tools/house_model.gd --what=shrine` shows the town's shrine.
- Checked: test_maps `_shrine`: the lantern's faces turned to their normals and away from its
  axis, the torii's and hokora's faces turned right, the kasagi's ends over 0.12 above its
  middle. The village snow check counted "more than 10" covers; with one snow mesh for the
  hokora roof (was two slabs) the town has exactly 10 (ground, five roofs, torii, hokora, two
  lanterns), so the check is now ">= 10" with that list in a comment. All 25 test scripts
  `OK (0 failed)`; the four smoke runs print no error or warning lines. Looked at: the shrine
  from four sides; town@shrine at 10:00, 20:00, winter snow 90; hill@top; sakurazaka@bridge;
  minamino@shige.
- Left / next: the seed stand, chest and bin by the farmhouse. Lanterns still do not light
  their surroundings at night (roadmap 3).

## 2026-11-03 — Village house roofs as kawara meshes, ridges curling up to onigawara
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: art direction roadmap 1, second item. `MapWorld._village_house` (every village house:
  town, Kaminoda, Minamino, Sakurazaka) now uses `Minka.gable` with kawara tile rolls every
  0.25: pitch 0.5 (about 27°), 0.14 thick, eaves 0.35 past the long walls and 0.25 past the
  ends, soffit 1.45 at the front eave; the walls go up to the soffit over the wall line (1.6 →
  1.625) and `Minka.gable_wall` closes the ends in plaster. New `Minka.ridge`: a dark
  ridge-tile stack (noshi) under a grey cap, both sweeping up 0.14 over the last 0.8 at each end
  (with the square of the way in, so the curve starts gently), a raised end tile (onigawara)
  leaning out with the curve at both ends; lit plain colours (`Minka._plain`) so the sun shapes
  the curve. The barn's box ridge is replaced by it too. The old prism gables and slabs are gone;
  the doors, noren and windows stay where they were. `tools/house_model.gd --what=village`
  shows a shop like Sayo's (6 x 3, noren, side door) from four sides.
- Checked: test_maps gets a ridge check (faces turned to their normals, level in the middle,
  over 0.1 higher at both ends). All 25 test scripts `OK (0 failed)`; the four smoke runs print
  no error or warning lines. Looked at: the shop from four sides; the village at 10:00 (town,
  town@sayo, sakurazaka@bridge), 17:00, 20:00, rain and winter snow 90; the barn; the
  see-through fade of a house between the camera and the farmer (rolls show through, faded).
  The roof snow has holes in a patch pattern: the same with the old roofs (checked against the
  last commit's code), so it comes from the snow top shader, not this change.
- Left / next: the shrine pieces (torii, hokora, stone lanterns). The houses still all share
  one shape; a hip roof or a second storey for some would add variety later.

## 2026-11-03 — Coop and barn roofs as meshes (Minka.gable), the farmhouse eave band turned out
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: art direction roadmap 1, first item. `Minka.gable` builds a thick gable roof (ridge
  along x): two slopes, the eave bands front and back, the verges closing both gable ends
  (the roof's cross section, as thick as the roof), the soffit, a snow layer; with `rolls` the
  slopes carry raised round-tile rolls (two leaning faces each and an end at the eave).
  `Minka.gable_wall` fills a gable end with a board triangle up to the soffit. The coop: thatch
  (`build:thatch` slopes, `build:kaya_edge` edges), 0.4 thick, pitch 0.75 (about 37°, lower
  than the house: a shed), eaves 0.35 past the long walls, 0.3 past the ends, its old ridge
  bundle and crossed sticks on the new crest (3.14). The barn: kawara, 0.15 thick, pitch 0.55
  (about 29°), 21 tile rolls a side every 0.25 (one per tile row of `build:kawara`), new
  texture `build:kawara_edge` (round tile ends lined up with the rolls), a ridge stack with a
  raised onigawara block at each end. Both soffits are 1.45 high at the front eave; the walls
  go up to the soffit over the wall line (coop 1.3 → 1.71, barn 1.6 → 1.67). The old prism
  gables and box slabs are gone.
  Bug found on the way: `Minka.roof`'s eave band normals pointed into the house (the "out"
  vector was turned the wrong way), so `_tri` made the band face inwards and it was culled
  from outside; it now faces out, so the farmhouse shows its straw edge. Shared as
  `Minka._eave_band`. `tools/house_model.gd` takes `--what=coop|barn`; models/farmhouse.glb
  re-written.
- Checked: test_maps gets checks for both gable kinds (crest height, every face turned to its
  normal, the face count 24 / 234, the front eave at 1.45 or more) and that upright faces
  (bands, verges, roll ends) point away from the building, for the farmhouse roof too (the
  old code printed band normal (0, 0, -1) on the front side). All 25 test scripts `OK (0
  failed)`; the four smoke runs print no error or warning lines. Looked at: the three
  buildings from four sides (house_model), the game by the coop and barn at 10:00, 17:00,
  20:00, rain and winter snow 90: the straw edge and verge read, the tile rolls catch the sun,
  snow covers both roofs with the eave rim showing.
- Left / next: the village houses' kawara roofs (`map_world.gd _village_house`) can use
  `Minka.gable` with rolls; curved ridge ends are still to do. The flat view is unchanged.

## 2026-11-03 — Deep mine finds tuned for the rope lift
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: with the lift a trip starts at floor 15 every day, and a winter of that out-earned
  every farming season together. data/mine.json: kogane 90 → 55, hoshigane 400 → 220, jade
  300 → 170, amber 150 → 100, rock crystal 120 → 70 G (`_prices` note); floors 13+ take 3 / 9
  blows (was 2 / 8) and a rock there hides nothing a little more often (none 28 → 36, stone
  12 → 14, kogane 22 → 20). data/festivals.json: the First Stone contest's rivals scaled by the
  same share (Hachiro 120-320 → 70-180, Kota 40-160 → 25-90, Sayo 20-120 → 12-65, Ichiro
  80-240 → 45-130), so a hoshigane or jade still has a chance.
- Checked: all 25 test scripts `OK (0 failed)`. Year bot (seed 1, `-- --years=2`, run alone, quoted):
  ```
  == Year 1 fall: income 77332 G, costs 47920 G, money 37385 -> 66797 G
     income: crops 21315, dishes 8270, animals 21480, fish 5010, forage 8969, mine 11788, prizes 500
  == Year 1 winter: income 100865 G, costs 28350 G, money 66797 -> 138552 G
     income: crops 0, dishes 0, animals 26580, fish 0, forage 625, mine 73160, prizes 500
     fishing: river 0 fish, 0 G, pond 0 fish, 0 G; mine: 29 trips (29 by the lift), deepest trip floor 20, food eaten there 4355 stamina
     contests: years_turn: mine:hoshigane, place 1
  == Year 2 winter: income 113385 G, costs 20070 G, money 352822 -> 445447 G
     income: crops 0, dishes 0, animals 26020, fish 0, forage 625, mine 86240, prizes 500
     Deepest floor       22  4 / 4 stars
     40 / 43 stars: rank 4, "Heart of the Village"; closest: hachiro
  play_year: OK (no problems seen)
  ```
  Mine income: year 1 201780 → 88150 G, year 2 298338 → 132074 G. Year 1 winter mine 171766 →
  73160 G. The record stays 40 / 43 stars; the deepest floor 25 → 22 (still 4 stars).
- Left / next: in year 1 the mine (88150 G) still out-earns crops (50110 G), all of it in
  winter when the field is empty; a winter living from the mine is fine, but if it should be
  smaller, the next step is the deep band's `none` weight or the food the stand sells.

## 2026-11-03 — Style roadmap kept in docs/ART_DIRECTION.md
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the art direction work written down so it can be continued later (the user asked):
  the look chosen (Japanese satoyama, HD-2D lite, the medium lens), the steps done with their
  commits, the rules for making pieces (scale, meshes in code, materials, snow, see-through,
  checking, light numbers), the limits (Compatibility renderer, 480 x 270, tint for night),
  a five-part roadmap with checkboxes (scenery, nature, light, characters, finish) and how to
  continue. ROADMAP "Next up" and AGENTS "Before doing anything" point to it.
  Nothing in the game changed.
- Checked: docs only; no tests needed. Commit hashes in the file checked with `git log`.
- Left / next: the user picks the next item (scenery or character sprites).

## 2026-11-03 — Modelled sample: the farmhouse gets a thatched kayabuki roof
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the first scenery piece built as a real mesh, to set the bar for the HD-2D lite look.
  `scripts/world3d/minka.gd` (Minka.roof) builds a thick thatched hip roof with SurfaceTool:
  four slopes, the trimmed eave band all round, the soffit, a snow layer (SnowLayer's top
  shader, no shadow), UVs in world units (u along the eave, v down the slope) so the straw runs
  down every face; a dark ridge beam with pairs of crossed riders. Triangles are turned to
  face their normals (Godot's clockwise fronts) whatever order the corners come in. The
  farmhouse uses it in place of the kawara slabs, gable and ridge cap: eaves 1.45 at the front
  (z 4.05, as before), pitch 1.25 (about 51°, steeper than the first try at 45°, which looked
  flat for kaya), half a unit thick (0.35 hid the eave band), ridge top 4.53. A timber band
  under the roof fills the gap between the 1.8 walls and the soffit. New textures `build:kaya`
  (grey-brown weathered straw, one soft course shadow a unit, moss flecks) and
  `build:kaya_edge` (the cut straw ends, dark under the slope, pale at the bottom).
  `tools/house_model.gd`: the house alone from four sides (`--shots`) and as a .glb (`--glb`);
  `models/farmhouse.glb` written (31500 bytes: 38 meshes, 13 materials, 7 images embedded, no
  required glTF extensions), `models/.gdignore` keeps Godot from importing it.
- Checked: test_maps gets 3 checks (ridge height, all 26 roof triangles face out, front eave
  at 1.45 or more). The house's four views and the game at 10:00, 17:00, 20:00, rain, winter
  snow 90 and from the coop looked at: the thatch reads as kaya, snow whitens the roof, the
  eave clears the farmer. All test scripts `OK (0 failed)`; the four smoke runs print no errors.
- Left / next: the user picks the next scenery step. In the game the camera shows mostly the
  front eave (the house stands at the farm's top edge); the whole roof shows in the tool's
  views. The flat view draws the house as a plain rect, unchanged.

## 2026-11-03 — The game uses the "medium" lens
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the user picked lens B from the screenshots; `data/camera.json` "use" is "medium"
  (fov 28°, pitch 30°, eye 12.1 away). README → Camera, AGENTS and Main3D's header say so.
  CAM_MARGIN is unchanged: the framing at the feet is the same as before.
- Checked: frames with the new lens at the farm gate, by the barn, the village's river edge,
  the hill top, Kaminoda, mine floor 3, inside the coop and the river shore: no empty sky or
  map edge shows anywhere. All test scripts `OK (0 failed)`; the four smoke runs print no errors.
- Left / next: the modelled farmhouse sample (thatched, built in code, exportable as .glb).

## 2026-11-03 — Camera lenses to choose from (data/camera.json)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the 3D camera's lens is data now. `CameraLens` (`scripts/world3d/camera_lens.gd`)
  reads `data/camera.json`: yaw 45° fixed, `pitch` and `fov` per lens, and the eye's distance
  = half_height / tan(fov / 2), so every lens frames the farmer's feet the same (half_height
  3.025 = the measured camera's). Lenses: "ps1" (the measured one, still used), "medium"
  (fov 28°, pitch 30°, eye 12.1 away), "wide" (fov 40°, pitch 36°, eye 8.3 away). These two
  numbers are ours, picked to give the user a clear choice. `-- --lens=<id>` for one run.
  Main3D's CAM_BACK / CAM_DIST / CAM_FOV are gone; the occluders get the lens's direction.
- Checked: test_maps gets 5 checks (ps1 = 25.2 away at yaw 45 / pitch 26.6 within 0.005, the
  old constant's rounding; every lens frames the feet alike; no flag = "use"). All test
  scripts `OK (0 failed)`; the smoke runs (plus `--lens=wide`) print no errors. Screenshots of the
  farm, village, shrine and house with each lens looked at: no empty sky or map edge shows
  with the wider lenses; the wide lens shows fewer field cells near the bottom edge.
- Left / next: the user picks a lens; set "use" to it (and retune CAM_MARGIN if the edges
  show). Then the modelled farmhouse sample.

## 2026-11-03 — Light pass: sun shadows on the ground, warm sun / cool shade
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: first step of the "HD-2D lite" art direction the user chose (Japanese countryside,
  pixel sprites in a lit 3D world). `scripts/main_3d.gd`: warm sun (ffeecc-ish, 0.7) from the
  upper left of the screen (-48°, -40°) so the long fronts are sunlit and shadows fall right,
  where they show; cool sky light (0.82, 0.88, 1.0 x 0.6); orthogonal sun shadows out to 45
  units; a soft glow (0.4, threshold 0.9). The ground shader (`SnowLayer.GROUND_SHADER`) is
  now lit, but only to take shadows: flat light, its picture read as sRGB, the sun scaled by
  `SUN_SHARE` = 0.045. That number is measured, not derived: at 0.04 / 0.07 the sunlit grass
  was (101,175,65) / (113,192,72) against (111,174,74) unshaded before; 0.045 gives
  (104,174,71), and shade (ambient alone) is (69,124,54), about two thirds. New rule
  `Game.sun_shadow()`: shadow strength by daylight luminance ((lum - 0.6) / 0.35) times the
  weather's `sun` (data/weather_fx.json: 0 for rain, storm, snow, blizzard; 1 when left out).
  Rooms and mine floors have no shadows. Sprites stay unshaded with their blob shadows.
  A saturation boost was tried and dropped (it shifted the pixel art's colours).
- Checked: test_weather gets 6 checks (full at 10:00, fading at 18:00, none at 22:00, none
  in rain / storm / snow). All test scripts `OK (0 failed)`; the four smoke runs print no
  errors. Screenshots (farm, village, coop, house, 19:30, 17:00, rain, winter snow, mine 3)
  looked at before and after: trees, houses and the coop cast shadows on the grass; rain and
  night have none; rooms and the mine unchanged.
- Left / next: camera trials (wider FOV, a little lower) for the user to pick from, then a
  modelled thatched farmhouse sample. Plaster walls in shade read a little blue; soften
  SKY_LIGHT if the user finds it cold. `data/mine.json` / `data/festivals.json` still hold
  another agent's uncommitted changes, left out of this commit.

## 2026-11-03 — Playtest feedback kept in docs/FEEDBACK.md
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the 15–20 / 21–30 playtest feedback written down in `docs/FEEDBACK.md`: 8 open items
  (Thai text, a week-one goal, where love leads, winter mine income, the grilled fish price,
  night light, small art things, the unconfirmed "Saved food is broken"), the order to fix them,
  what is already fixed (67cbaed, 7ca5b91) and what the players liked. Nothing in the game changed.
- Checked: docs only; no tests needed. The mine numbers are quoted from the entry below.
- Left / next: the user starts the fixes by saying "แก้ feedback"; item 1 (Thai text) first.
  `data/mine.json` / `data/festivals.json` have another agent's uncommitted changes, left out.

## 2026-11-03 — Year bot rides the mine lift
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: `tools/play_year.gd` starts each mine trip at the deepest landing reached
  (`Game.mine_start_floors().back()` through `Game.mine_go_down`), else by the ladder; the report
  counts the trips that rode the lift.
- Checked: all 25 test scripts `OK (0 failed)` on f606c5a. Report (seed 1, `-- --years=2`, quoted):
  ```
  == Year 1 fall: income 91299 G, costs 47520 G, money 37865 -> 81644 G
     income: crops 20125, dishes 6125, animals 21620, fish 7468, forage 9129, mine 26332, prizes 500
     fishing: river 334 fish, 14932 G, pond 0 fish, 0 G; mine: 7 trips (7 by the lift), deepest trip floor 19, food eaten there 1070 stamina
  == Year 1 winter: income 199601 G, costs 28170 G, money 81644 -> 257297 G
     income: crops 0, dishes 160, animals 26510, fish 40, forage 625, mine 171766, prizes 500
     fishing: river 0 fish, 0 G, pond 9 fish, 195 G; mine: 29 trips (29 by the lift), deepest trip floor 23, food eaten there 4305 stamina
  == Year 2 winter: income 221709 G, costs 19350 G, money 535103 -> 736702 G
     income: crops 0, dishes 0, animals 26160, fish 0, forage 625, mine 194424, prizes 500
     fishing: river 0 fish, 0 G, pond 6 fish, 195 G; mine: 29 trips (29 by the lift), deepest trip floor 25, food eaten there 4320 stamina
     Deepest floor       25  4 / 4 stars
     40 / 43 stars: rank 4, "Heart of the Village"; closest: hachiro
  play_year: OK (no problems seen)
  ```
  The deep floors are reached now (25 by the end; 4 stars, was 9 and fewer stars), and the
  record went 36 → 40 stars (the hearts merge and the deeper floor both count).
- Left / next: the mine is now far the best money: in year 1 winter it brought 171766 G of
  199601 G, one trip a day from floor 15 with the stand's food. Deep finds (or the lift's
  depth) need tuning in data/mine.json so winter mining doesn't beat a whole farming year.
  A first run of this bot stopped after year 1 spring with exit 0 while the test scripts ran at
  the same time (shared user://); run the bot alone.

## 2026-11-03 — Merge: forage talk from the outer parts' villagers
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged main into the forage talk branch (92fb776, entry below dated 2026-11-02).
  Main had given Fumi and Ichiro hearts in the meantime (ca99103), so their talk files clashed:
  their forage rows now follow the rule of the villagers with hearts (band 2..5, after the band
  5 flag lines, before the close lines), so a stranger and a dear friend don't hear them; the
  other five keep band 1..6. test_talk moves Fumi and Ichiro to the hearted forage checks.
- Not merged (main already had the same work, 688bc4c): the year bot's river fishing and mine
  food (branch worktree-agent-a188e6fd5ff01e5a5, 86c11fc) and a slower hammer with less
  experience per mine blow (worktree-agent-a4531e61007890ca2, 5fc9390; main set the hammer's
  steps to 240 / 720 / 1680 / 3360 instead). Both branches were deleted.
- Checked: all 25 test scripts print `OK (0 failed)` after the merge. The first run failed one
  check, test_relationships' "ichiro at band 4: forage_summer": it talked to him on a
  Wednesday, his forage day, where the forage line rightly comes before the close lines; the
  check now uses a Monday. Smoke runs (title, `--demo`, town, mine 3, sakurazaka) print no
  error or warning lines.
- Left / next: milestone 10, the .exe build once the export templates are installed.
## 2026-11-03 — Key hints: what E / Space do at the spot in front
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Why: the playtest's first point for players 15-20: the keys were only in the README and the
  opening only says "till the soil with the hoe"; nothing on screen said which button talks,
  ships or casts. The user picked this next.
- Done: `ActionHints` (scripts/ui/action_hints.gd) asks what FarmActions.on_action would do,
  in its order, without changing anything: reel in, put the dog down, Talk / Give to the
  villager in front, Enter / Go down / Look at a door, Tend an animal, Pick up a mine find,
  Pick a wild thing, Play / Enter contest / Shop at a festival spot, the prop's use (Sleep,
  Shop, Open, Cook, Feed, Take egg...), Pet the dog, Ship / Open / Buy at the bin, chest and
  stand, Pick up / Harvest; with hands full on the farm Throw / Put down. The tool button:
  Eat (food in hand or one held), Cast only facing water, Till / Water / Cut / Break / Chop /
  Sow on the farm, and down the mine Break / Dig only at a rock / soft spot. The HUD draws it
  in a paper box over the item box (HudLayout "hint", in the bottom-left group, so it grows with
  the UI size and never meets the other corners), keys in seal red, the player's first bound
  key for each action (Esc → Settings → Controls changes it here too); the same word on both
  buttons is one hint ("E/Space Reel in"); hidden while Game.paused() (menus, text boxes,
  events). New setting "Key hints" (data/settings.json `hints`, on by default, Game.key_hints)
  for players who know the keys.
- Checked: test_menu (new `_key_hints`: the pairs (both, one, shared, no key), the bound keys,
  facing the bin E Ship / Space Till, hands full Throw / Put down, the rod Cast at the pond only,
  a village door E Enter with no tool word, the HUD box shows and hides while paused and with the
  setting off; the settings list has `hints`) and every other test print `OK (0 failed)`; smoke
  runs (title, `--demo`, `--map=town`, `--mine=3`) print no error or warning lines.
  Screenshots: `--demo` "Space Till", `--hold` "E Throw  Space Put down" (also at `--ui=150%`),
  `--fishing=wait` the reel hint, `--mine=3` (before the mine fix it said "Space Dig" on bare
  floor; now only at a soft spot), the coop / store / festival with no hint when nothing is in
  front.
- Left / next: the hints are English like the rest of the text (Thai text is its own task);
  pad players see the keyboard keys, as there is no "last device used" yet.

## 2026-11-03 — Playtest fixes: land past the map edges, see-through buildings in the way
Agent: Claude Code (claude-opus-5-5) · Commit: 67cbaed
- Why: a playtest (screenshots of 19 scenes, read as players aged 15-20 and 21-30) found two
  things both groups see in the first hour: near a map's edge the 3D view looked off the world
  into empty sky (the village's north-west corner, the farm past its fence), and roofs in front
  of the farmer (the village, the festival square, winter) filled the lower half of the screen
  and hid the ground and villagers behind them. The user picked these two to fix first.
- Done: `Surroundings` (scripts/world3d/surroundings.gd): on every outdoor map (not sheltered:
  the farm, village, the three outer parts, hill, river, mine mouth) an apron of ground 14 cells
  round the map, each cell the nearest edge cell's kind (roads, the river and paddies run on;
  water banks drawn where kinds meet), snow on it as on the map; and a pine wood where a tree
  stands behind every map cell of its screen column (the north and west sides), never on or
  next to a road or water running out. `Occluders` (scripts/world3d/occluders.gd): every map
  prop, and the farm's house, stand, coop and barn, is one group of meshes with a box; anything
  over 1 unit high fades to 40 % while it stands nearer the camera than the farmer and a ray from
  the farmer (feet, waist, head) or from a ring 1.25 cells round the feet towards the camera hits
  its box. The fade is the materials' alpha (each group gets its own copies; snow tops hide,
  sprites use modulate): `GeometryInstance3D.transparency` drew nothing in the project's
  Compatibility renderer (the fade's data was right, the frame unchanged).
- Checked: test_maps (new: the village's apron, the west road running on, pines only behind
  the map and off the road, behind / in front of a village house, `hides` both ways, no apron
  in a room, the farm view's apron and four fading buildings) and every other test print
  `OK (0 failed)`; smoke runs (title, `--demo`, `--map=town`, `--mine=3`, `--map=river`,
  `--map=hill`) print no error or warning lines. Screenshots (3D): the village start, winter
  village with snow 80, farm gate, river, hill top, Kaminoda, the mine mouth, Blossom Day.
  Pixels of the empty-sky colour 8fc6e8 in the village frame: 22710 before, 0 after; 0 in all
  the other outdoor frames. The roof in front of the village start spawn and the festival
  square's roof show see-through, with the road / pond and villagers behind them visible.
- Left / next: the 2D view needs neither. Other playtest notes still open: on-screen key hints,
  Thai text, an early goal in week 1, the mine's share of winter money, night lights.
  tools/play_year.gd has another agent's uncommitted change, so it is left out of this commit.

## 2026-11-03 — Hearts for Fumi and Ichiro
Agent: Claude Code (claude-opus-5-5) · Commit: ca99103
- Done: Fumi (the Hanami teahouse) and Ichiro (the charcoal burner) of Sakurazaka are villagers
  with hearts: `"hearts": false` gone from their files, so `Villagers.friends()` (the name tag's
  heart, the nightly loss, birthdays, the record's Friendships row, the ending's closing word)
  takes them in with no code change. Birthdays: Fumi spring 26 (the last cherries; she shuts the
  counter 11:00-16:00 and stands under the trees by the bridge), Ichiro fall 9 (the burning
  season; no axe, a long sit on the teahouse gravel 10:00-14:00); both on the farmhouse calendar,
  birthday and gift_birthday lines. Talk: close lines from band 4, their own lines after the band
  5 scene (Fumi's letter in the stove, Ichiro's kiln). Their gift lists (a loved dish and a loved
  keepsake each, kept at home) were already there. Heart events, our own scenes: band 3 Fumi asks
  the farmer to taste her mother's bean paste and tell her true (`fumi_honest`), Ichiro knocks
  charcoal to hear it ring; band 5 a city tea merchant wants Fumi's teahouse (her line looks back
  on `fumi_honest`), Ichiro's father's kiln cracks and he asks for help (`ichiro_kiln`). New
  trigger tables `triggers_teahouse.json`, `triggers_sakurazaka.json`, `triggers_ichiro_house.json`
  and rows in `triggers_town.json` (festival days); heart music for them (data/music.json); an
  ending part each. No band 6 scenes for them yet.
- Balance: data/ending.json Friendships steps 4 / 8 / 14 / 20 (of 24, four villagers) →
  5 / 11 / 19 / 28 (of 36, six): about the same share. Neighbours 2 / 4 / 6 / 8 (of 8) → 2 / 3 / 5 / 6
  (of 6). tools/play_year.gd not run (another agent works on it), so the bot's star count with
  the new steps is not measured.
- Tests: test_relationships loops over the friends as before; the band 5 / 6 checks run where
  the event file is there (the first four must have both), keepsake homes for the two, and a new
  `_sakurazaka_friends` (birthday plans, close / after-scene lines, Fumi's band 5 branch, the
  ending part). test_ending: Shige is the neighbour not quite known, Fumi counts as a friend, the
  ending event plays for every friend.
- Checked: `test_relationships: OK (0 failed)`, `test_talk: OK (0 failed)`, `test_villagers: OK (0 failed)`,
  `test_events: OK (0 failed)`, `test_ending: OK (0 failed)`, `test_festivals: OK (0 failed)`,
  `test_save: OK (0 failed)`, `test_audio: OK (0 failed)` and every other test script OK.
  test_villagers failed once (`FAIL: the lumber blocks the farmer (both views' Player asks
  Game.maps), the cell he fetches from stays open`) and passed on the next two runs; that check is
  about Hachiro's building job, not these files. Smoke runs (title, `--demo`, `--map=town`,
  `--mine=3`, Sakurazaka at 13:20, Fumi's birthday, `--event=heart_fumi`, `--event=heart_ichiro_5`)
  printed no errors. Screenshot `--demo --map=sakurazaka --time=13:20 --talk=fumi --hearts=3`:
  Fumi on the gravel, her name tag with the heart, her spring line.
- Left / next: band 6 scenes for Fumi and Ichiro; the other outer villagers stay without hearts.

## 2026-11-03 — Mine landings: rope lifts on floors 5, 10 and 15
Agent: Claude Code (claude-opus-5-5) · Commit: b754692 (merged in ecb27b6)
- Done: every trip down the mine began at floor 1, so floors 15 and 20 (the ending's mine steps)
  took more food than a day's pack. `landings` in data/mine.json makes floors 5, 10 and 15
  landings: a rope lift's cage stands by the ladder (`MineFloor.landing` / `lift`, solid, at
  [9, 1] inside the ladder's safe square, so no floor's layout changes; `mine:landing` art, a
  rope down to a timber cage with a lit lantern, in both views). Reaching one keeps it
  (`Game.mine_landings`, news said once on arrival) and sets the story flag `mine_lift`, which
  shows the winch beside the cave mouth (`rope_lift` story prop on data/maps/mine.json,
  `story:rope_lift`, both views; E on it says what it is). From then on the cave mouth opens a
  text box: the ladder to floor 1 or the lift to each landing reached (the deepest three; the
  box holds four choices). The text box can now show lines built in code (`Game.dialogue_made`)
  and tells Game when it closes (`Game.dialogue_closed`), which takes the farmer down
  (`Game.mine_go_down`, refusing a landing not reached). Save version 6: `mine.landings`;
  a version 5 or older save gets every landing down to its deepest floor (every trip began at
  floor 1 then, so they were walked through) and the winch's flag. `mine_deepest`, the ending's
  measure, still only counts floors reached on foot: the lift only goes where the farmer has
  been. Debug: `-- --demo --map=mine@cave --landings=5,10 --lift` opens the choice.
- Balance: every fifth floor, because a 150-stamina pack (the year bot's) went about five to
  nine floors a trip; from landing 15 floor 20 is one pack down. Not changed: the ending's steps.
- Checked: `test_mine: OK (0 failed)` (new: landing data and layout unchanged by the lift, the
  game flow at the cave mouth, the choice as a running dialogue, deepest kept honest, the save,
  the version 5 migration, bad lists refused, the art sizes); test_save, test_view2d,
  test_ending and every other test print OK (0 failed). Smoke runs (title, `--demo`, `--map=town`,
  `--mine=3`, `--map=mine`, `--mine=10`, the lift choice, the flat view at `--mine=5`) print no
  errors or warnings. Screenshots: the cave mouth with the winch and the three choices (3D),
  floor 10's lift and its news (3D), floor 5's lift (flat view).
- Left / next: tools/play_year.gd doesn't ride the lift yet (not touched here; another agent
  works on it), so its report's deepest trip floor is still from floor 1.

## 2026-11-03 — Fish prices: crops and animals lead year 1, fishing a side income
Agent: Claude Code (claude-opus-5-5) · Commit: b8b2d80 (merged in this commit)
- Done: data/fish.json prices only (no code). The fish that bite at every hour go to about
  20 G: crucian carp 30 → 20, pond loach 25 → 18, dace 40 → 18, pale chub 55 → 26; carp
  80 → 60, river sculpin 90 → 60; sweetfish 120 → 90 and a morning fish now (hours 5-18 →
  5-12); the salmon run keeps its 450 G but is rarer in the river (weight 10 → 6). Masu trout,
  char, catfish, eel and the two once-only fish are unchanged. A `_prices` note in the file.
- Why (ours): the year-1 field is capped by the can's level, not by stamina, so every point
  of stamina left after the field went into the evening's fishing, and the bot's catch was
  worth what a bite pays times the spare stamina / 4. The river paid 47-102 G a bite in the
  afternoon and evening (dace and chub at every hour, sweetfish until 18:00, the salmon run
  until 17:00): 12-25 G a stamina point, against about 4 G a point for the stand's food. Now an
  evening bite pays 22-32 G (spring and summer at the farm pond, 28 G; fall's river with the
  salmon until 17:00, 59 G), about 5-8 G a stamina point: still more than the food it costs,
  so fishing pays, but the money is in the fish of their hour (dawn trout and char, the summer
  morning's sweetfish, the salmon, night catfish and eel). The average bite by hour came from
  the table (a small script, sunny, once-only fish left out): river spring 6:00 58 G, 16:00
  22 G; summer 6:00 48 G, 16:00 22 G; fall 6:00 102 G, 16:00 59 G, 18:00 22 G.
- Before (seed 1, `-- --years=2`, data as of 40ca5ed, quoted from the run; same as the last
  entry's report):
  ```
  == Year 1 spring: income 35939 G, costs 13980 G, money 500 -> 22459 G
     income: crops 11285, dishes 0, animals 2210, fish 12860, forage 7170, mine 1914, prizes 500
     fishing: river 361 fish, 17810 G, pond 0 fish, 0 G; mine: 8 trips, deepest trip floor 8, food eaten there 350 stamina
  == Year 1 summer: income 60187 G, costs 30210 G, money 22459 -> 52436 G
     income: crops 16830, dishes 4860, animals 8040, fish 23115, forage 4772, mine 2070, prizes 500
     fishing: river 363 fish, 26865 G, pond 0 fish, 0 G; mine: 7 trips, deepest trip floor 5, food eaten there 200 stamina
  == Year 1 fall: income 73974 G, costs 46970 G, money 52436 -> 79440 G
     income: crops 21855, dishes 835, animals 21480, fish 18485, forage 8499, mine 2320, prizes 500
     fishing: river 392 fish, 30245 G, pond 0 fish, 0 G; mine: 4 trips, deepest trip floor 9, food eaten there 325 stamina
  == Year 1 winter: income 84921 G, costs 27450 G, money 79440 -> 135731 G
     income: crops 0, dishes 0, animals 26440, fish 160, forage 675, mine 57146, prizes 500
     fishing: river 10 fish, 400 G, pond 0 fish, 0 G; mine: 29 trips, deepest trip floor 10, food eaten there 4255 stamina
  ```
- After (same run, new prices):
  ```
  == Year 1 spring: income 29176 G, costs 14200 G, money 500 -> 15476 G
     income: crops 9880, dishes 0, animals 2280, fish 7314, forage 6756, mine 2446, prizes 500
     fishing: river 0 fish, 0 G, pond 360 fish, 10088 G; mine: 6 trips, deepest trip floor 8, food eaten there 400 stamina
  == Year 1 summer: income 54773 G, costs 30480 G, money 15476 -> 39769 G
     income: crops 20425, dishes 17130, animals 7690, fish 4570, forage 3616, mine 1342, prizes 0
     fishing: river 0 fish, 0 G, pond 379 fish, 11430 G; mine: 5 trips, deepest trip floor 5, food eaten there 150 stamina
  == Year 1 fall: income 70356 G, costs 47140 G, money 39769 -> 62985 G
     income: crops 22445, dishes 4160, animals 21620, fish 6858, forage 10141, mine 4632, prizes 500
     fishing: river 372 fish, 13608 G, pond 0 fish, 0 G; mine: 6 trips, deepest trip floor 9, food eaten there 600 stamina
  == Year 1 winter: income 79689 G, costs 25220 G, money 62985 -> 118619 G
     income: crops 0, dishes 560, animals 26720, fish 95, forage 600, mine 51214, prizes 500
     fishing: river 0 fish, 0 G, pond 16 fish, 410 G; mine: 29 trips, deepest trip floor 10, food eaten there 4285 stamina
  == Year 2 spring: income 64023 G, costs 10760 G, money 118619 -> 172642 G
     income: crops 15910, dishes 11295, animals 28820, fish 276, forage 4290, mine 3432, prizes 0
  == Year 2 summer: income 67939 G, costs 11890 G, money 172642 -> 228691 G
     income: crops 23655, dishes 8700, animals 28470, fish 598, forage 3154, mine 3362, prizes 0
  == Year 2 fall: income 91847 G, costs 16920 G, money 228691 -> 303618 G
     income: crops 33860, dishes 7425, animals 28540, fish 6926, forage 7834, mine 6762, prizes 500
  == Year 2 winter: income 88953 G, costs 19890 G, money 303618 -> 371991 G
     income: crops 0, dishes 0, animals 25950, fish 0, forage 625, mine 62178, prizes 200
     Fish kinds        8  3 / 4 stars
     Contests won        4  3 / 4 stars
     36 / 43 stars: rank 4, "Heart of the Village"; closest: hachiro
  play_year: OK (no problems seen)
  ```
  Year 1 shipped: crops 49970 → 52750 G, animals 58170 → 58310 G, fish 54620 → 18837 G (the
  catch at the bin's prices 75320 → 35536 G; the rest of the catch was gifted or cooked).
  Fish were 1.09x the crops and are now 0.36x; crops + animals are 111060 G against 18837 G of
  fish. The bot now fishes the farm pond in spring and summer (the river pays less there in
  the evening) and the river in fall (the salmon), 350-380 fish a season as before. Year-1
  money at the end of winter 135731 → 118619 G; the record keeps 36 / 43, rank 4 (Fish kinds
  6 → 8 with the pond fished again, 3 stars; Contests won 6 → 4, 3 stars: a fish entry scores
  its price). No collapses.
- Checked: test_fishing, test_farm, test_festivals, test_shops, test_cooking, test_food,
  test_talk, test_relationships, test_ending, test_view2d, test_hold and test_forage each print
  `OK (0 failed)`; the smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`,
  `--demo --fishing=river`) print no error lines.
- Left / next: year-1 summer dishes 4860 → 17130 G: the bot cooks the cheap fish into grilled
  fish (data/foods.json sells it at 80 G, a fish in, no other ingredient), so some of the old
  fish money comes back through the kitchen. Look at grilled fish's price (foods.json, not
  changed here) if that turns out to be the new shortcut.

## 2026-11-03 — Year bot: river fishing, food for the mine, forage, the new areas; rod and hammer
Agent: Claude Code (claude-opus-5-5) · Commit: 688bc4c (merged in d0581e3)
- Done: `tools/play_year.gd` on the new main. It walks the new areas instead of jumping: the
  village → Sakurazaka → the mine, the village → Minamino → the river, the village → Kaminoda →
  the hill (houses of any area are left through their own door). Forage: every area walked
  through is picked clean (`Game.forage_pick`, nearest spot first), and on dry days the mine
  doesn't take (before 14:00) it does a round of Kaminoda and the hill; wild things count as
  their own income source. River: the evening's fishing (now until 20:00, stamina allowing)
  goes to the river's shore when a bite there is worth more on average than at the farm pond
  (`Fishing.candidates` for the season, hour and weather, fish caught once left out); the report
  counts fish and G per place. Mine: before a trip it ships what it carries (room for finds),
  takes the kept dishes (3 of each with 40+ stamina stay in the chest) and buys the stand's
  food with the most stamina per G (dango) up to 150 stamina, RESERVE kept; down there it eats
  the most filling one that fits under the max when stamina drops below 20, and goes up at
  17:00, at fatigue 75, or when a swing can't happen (the first version hung on a rain day with
  the hands and the rucksack full: no time passed). Stand foods are no longer shipped.
- Balance, from the first run on the new main (seed 1, before the two changes below):
  ```
     income: crops 10710, dishes 0, animals 2280, fish 31070, forage 7632, mine 1846, prizes 500
     fishing: river 695 fish, 35740 G, pond 0 fish, 0 G; mine: 5 trips, deepest trip floor 9, food eaten there 450 stamina
     income: crops 22040, dishes 5460, animals 7450, fish 43480, forage 4746, mine 358, prizes 500
     fishing: river 775 fish, 48525 G, pond 0 fish, 0 G; mine: 2 trips, deepest trip floor 5, food eaten there 0 stamina
  ```
  (1) Fish out-earned crops about three to one in year 1 (105445 G vs 55865 G): a cast cost 2
  stamina, so the river (dace 40 G and chub 55 G at every hour) was fished from mid-afternoon to
  20:00 every day for about 25 fish. data/tools.json rod stamina 2 → 4: still about 12 G a
  stamina point (the stand sells stamina at about 4 G), but spare stamina now limits it.
  (2) The hammer (axe's numbers, 90 / 270 / 630 / 1260) was at level 4 after the first spring and
  5 in fall of year 1 from mine swings, so the smithy's hammer upgrades never did anything. Now
  the sickle's 240 / 720 / 1680 / 3360. Not changed: the mine steps 5 / 10 / 15 / 20. Floor 10
  (2 stars) is what the bot gets with a 150-stamina pack after its village round; the trips end
  when the pack is eaten (about 147 stamina a winter trip), so 15 and 20 are for a player who
  goes down early with more food, which is what data/ending.json says they should take.
- Report (seed 1, `-- --years=2`, after both changes, quoted from the run):
  ```
  == Year 1 spring: income 35939 G, costs 13980 G, money 500 -> 22459 G
     income: crops 11285, dishes 0, animals 2210, fish 12860, forage 7170, mine 1914, prizes 500
     tools: hoe 2, can 2, sickle 1, hammer 3, axe 1, rod 1
     fishing: river 361 fish, 17810 G, pond 0 fish, 0 G; mine: 8 trips, deepest trip floor 8, food eaten there 350 stamina
  == Year 1 summer: income 60187 G, costs 30210 G, money 22459 -> 52436 G
     income: crops 16830, dishes 4860, animals 8040, fish 23115, forage 4772, mine 2070, prizes 500
     tools: hoe 2, can 3, sickle 2, hammer 4, axe 1, rod 1
     fishing: river 363 fish, 26865 G, pond 0 fish, 0 G; mine: 7 trips, deepest trip floor 5, food eaten there 200 stamina
  == Year 1 fall: income 73974 G, costs 46970 G, money 52436 -> 79440 G
     income: crops 21855, dishes 835, animals 21480, fish 18485, forage 8499, mine 2320, prizes 500
     tools: hoe 2, can 3, sickle 2, hammer 4, axe 1, rod 1
     fishing: river 392 fish, 30245 G, pond 0 fish, 0 G; mine: 4 trips, deepest trip floor 9, food eaten there 325 stamina
  == Year 1 winter: income 84921 G, costs 27450 G, money 79440 -> 135731 G
     income: crops 0, dishes 0, animals 26440, fish 160, forage 675, mine 57146, prizes 500
     tools: hoe 4, can 4, sickle 2, hammer 5, axe 2, rod 2
     fishing: river 10 fish, 400 G, pond 0 fish, 0 G; mine: 29 trips, deepest trip floor 10, food eaten there 4255 stamina
  == Year 2 spring: income 72718 G, costs 11830 G, money 135731 -> 197799 G
     income: crops 18175, dishes 14695, animals 28540, fish 830, forage 4410, mine 5568, prizes 500
     tools: hoe 4, can 4, sickle 2, hammer 5, axe 2, rod 2
     fishing: river 93 fish, 4460 G, pond 0 fish, 0 G; mine: 6 trips, deepest trip floor 9, food eaten there 590 stamina
  == Year 2 summer: income 72393 G, costs 10030 G, money 197799 -> 260162 G
     income: crops 25585, dishes 6030, animals 28540, fish 5320, forage 4038, mine 2680, prizes 200
     tools: hoe 4, can 4, sickle 2, hammer 5, axe 2, rod 2
     fishing: river 110 fish, 8160 G, pond 0 fish, 0 G; mine: 4 trips, deepest trip floor 7, food eaten there 345 stamina
  == Year 2 fall: income 88846 G, costs 16470 G, money 260162 -> 332538 G
     income: crops 34425, dishes 4750, animals 28610, fish 7845, forage 8758, mine 3958, prizes 500
     tools: hoe 4, can 5, sickle 2, hammer 5, axe 2, rod 2
     fishing: river 186 fish, 17205 G, pond 0 fish, 0 G; mine: 8 trips, deepest trip floor 7, food eaten there 405 stamina
  == Year 2 winter: income 87853 G, costs 18900 G, money 332538 -> 400381 G
     income: crops 0, dishes 0, animals 25950, fish 0, forage 675, mine 61128, prizes 100
     tools: hoe 5, can 5, sickle 2, hammer 5, axe 2, rod 2
     fishing: river 0 fish, 0 G, pond 0 fish, 0 G; mine: 29 trips, deepest trip floor 10, food eaten there 4260 stamina
  == Spring 1, Year 3: the village record (the ending played)
     Shipped      573531  4 / 4 stars
     Crops grown       11  4 / 4 stars
     Happy animals        9  3 / 4 stars
     Friendships       24  4 / 4 stars
     Neighbours        7  3 / 4 stars
     Deepest floor       10  2 / 4 stars
     Fish kinds        6  2 / 4 stars
     House built        3  3 / 3 stars
     Tool levels       14  3 / 4 stars
     Contests won        6  4 / 4 stars
     Recipes          19  4 / 4 stars
     36 / 43 stars: rank 4, "Heart of the Village"; closest: hachiro
     goals not reached: none
  play_year: OK (no problems seen)
  ```
  Against 2026-11-01: deepest floor 6 → 10 (steps 5 / 10 / 15 / 20: 1 → 2 stars); year-1 mine
  income 18k → 63450 G (winter 57146 G, with 14490 G of food bought for it); the hammer now
  reaches 3 / 4 / 4 / 5 by season in year 1 (was 4-5 by fall); year-1 fish shipped 9k at the
  pond → 54620 G at the river (year 2: 13995 G, when the bigger field takes the stamina);
  forage 21116 G in year 1. Rank 4, "Heart of the Village" (was rank 3, 30 / 39 before the new
  areas added Neighbours and recipes). No collapses in year 1, none in year 2.
- Checked: all 25 test scripts print `OK (0 failed)` (with the new rod and hammer numbers);
  the bot prints `play_year: OK (no problems seen)`.
- Left / next: fish still out-earn crops in each season of year 1 (the small year-1 field
  leaves stamina over; lower common river fish prices if a player finds it too strong); the
  smithy's hammer 2 / 3 still come after the bot's mining has levelled it; floors 15 / 20 need a
  longer trip than the bot's plan.

## 2026-11-02 — Forage talk from the outer parts' villagers
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the seven villagers without hearts each have a forage line per season in their talk
  files (`forage_<season>`), about what grows in their own part per data/forage.json: Genzo
  (Kaminoda) the dropwort at the paddy edges in spring and winter, mugwort on the terrace dikes,
  nameko by his woodpile; Haru bamboo shoots by the hill lane and wild garlic past the lower
  paddies, raspberries, yam bulbils and chestnuts, winter enoki by Genzo's woodpile; Fumi
  (Sakurazaka) butterbur buds and myoga on the creek banks above the bridge, chestnuts by the
  pines behind the teahouse, enoki by the far pine; Ichiro bamboo shoots in his grove, sansho,
  nameko and akebi by his house and woodpiles, winter enoki; Shige (Minamino) horsetail along the
  river lane, mulberries at the track's east end, nameko by the south pines, enoki and
  Kaminoda's winter dropwort; Nana wild garlic by the shrine, mulberries by the top beds, yam
  bulbils, "snow mushrooms"; Kiku horsetail below her orchard, mugwort for kusa mochi, the
  ginkgo nuts by the water shrine, winter enoki. Every place was checked against the spots'
  cells and the maps' props. Data only, no code change.
- Rules (ours): one weekday each, spread so the people of one part differ (Genzo mon, Shige tue,
  Ichiro wed, Haru thu, Kiku fri, Fumi sat, Nana sun), gated at band 1..6: these villagers have
  no hearts, only a hidden affection whose band 1 means "known" (the recipe lessons and the
  record's Neighbours use the same mark), and a stranger (band 0) gets new_1 first anyway. The
  rows sit right after the wet-day row, so rain keeps its line and festivals, Haru on the hill,
  Kiku's shrine hour and Nana at the pond keep theirs; on the weekday the line takes over the
  time and season lines (Ichiro's woods and lunch lines included). The rest of the week is
  unchanged.
- Checked: test_talk's `_picks` checks each of the seven in every season on their weekday at
  band 1 and 6, none at band 0, none on another weekday, the wet line on a rainy day; the file
  checks open every new line and its portrait. All 25 test scripts print `OK (0 failed)`; smoke
  runs (title, `--demo`, town, mine 3, kaminoda, minamino, sakurazaka) print no errors or
  warnings.
- Left / next: milestone 10, the .exe build once the export templates are installed.


## 2026-11-02 — Forage talk from the villagers with hearts
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: Tome, Hachiro, Sayo and Kota each have a forage line per season in their talk files
  (`forage_<season>`), each pointing at what really grows where in data/forage.json: Tome the
  hill's butterbur, raspberries, chestnuts and the matsutake near the top, winter enoki;
  Hachiro bamboo shoots, Sakurazaka's sansho, a warning about mushrooms, the mine in winter;
  Sayo Minamino's horsetail, mulberries and ginkgo nuts, Kaminoda's winter dropwort; Kota old
  bamboo shoots, raspberries, akebi, mushrooms. Data only, no code change.
- Rules (ours): a forage row per season, picked on one weekday per villager (Tome thu,
  Hachiro tue, Sayo wed, Kota fri) at band 2..5, placed right before the close (band 4..6)
  lines, so a friend hears it one day a week and the rest of the week is unchanged; strangers
  (band 0..1) and band 6 with the dear lines never hear it.
- Checked: test_talk's `_picks` checks each villager's line in every season at band 2 and
  5, none at band 1 and none on another weekday; the file checks open every new line and its
  portrait mood. All 25 test scripts print `OK (0 failed)`; smoke runs (title, `--demo`,
  town, mine 3) print no errors or warnings.
- Left / next: milestone 10, the .exe build once the export templates are installed.

## 2026-11-02 — Wild things in recipes
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: six kitchen recipes of wild things (data/recipes.json, dishes in foods.json, our names
  and looks): sansai tempura (2 wild greens, pot), kinoko jiru (a mushroom and a soup
  vegetable, knife and pot), kusa mochi (2 rice and mugwort, mallet, makes 3), takenoko gohan
  (rice and a bamboo shoot, makes 2), kuri gohan (rice and chestnuts, makes 2), dobin mushi
  (matsutake and a fish, teapot). New groups `sansai` (horsetail, mugwort, bracken, dropwort,
  wild garlic, butterbur, myoga: cheapest first) and `kinoko` (oyster, nameko, enoki, matsutake
  last). Haru, Genzo and Kiku teach the first three once known to band 1 (recipe_<who> events,
  lines in recipe_lessons.json; new trigger tables for kaminoda, minamino and their three
  houses, and a row on the hill for Haru's afternoons). The first bamboo shoot, chestnuts or
  matsutake shipped brings a card for the other three (cards now take wild items; no code
  change). Each dish is liked by one villager (Genzo, Haru, Kiku, Tome, Hachiro, Ichiro).
  The village record's recipe steps moved from 6 / 8 / 10 / 13 to 7 / 10 / 14 / 19.
  tools/balance.py values wild ingredients from forage.json.
- Balance (ours): gain over shipping the ingredients raw (balance.py, cheapest of a group):
  tempura 54, kinoko jiru 40, kusa mochi 72, takenoko gohan 50, kuri gohan 55, dobin mushi
  57-87; in line with the old recipes (40-67). Dobin mushi pays its teapot back in 5 cookings
  but needs the hill's single matsutake spot.
- Checked: test_cooking's new `_wild` (cards for the three wild things, shipped and thrown;
  the cheapest greens used and the butterbur bud kept; the nameko used before the matsutake;
  each lesson picked in its maps, not to a stranger, not twice, not by the wrong person); its
  data checks now accept wild items. First full run: test_ending failed ("the top recipes
  step is every recipe (19)"), fixed by the new steps. All 25 test scripts print `OK (0
  failed)`; smoke runs (title, `--demo`, town, mine 3, kaminoda, minamino; and main.tscn on
  kaminoda, minamino, hill, kiku_house with their trigger tables) print no errors;
  `play_year.gd -- --years=2` learned recipe_genzo, recipe_haru and recipe_kiku in play and
  printed `Recipes          16  3 / 4 stars`, `30 / 43 stars: rank 3, "Keeper of the
  Satoyama"` and `play_year: OK (no problems seen)`; screenshots: the cooking screen lists the
  new dishes with icons ("11 of 19 known"), Genzo's lesson in Kaminoda with his portrait.
- Left / next: a talk line or two about foraging from the villagers with hearts.

## 2026-11-01 — Forage in Kaminoda, Sakurazaka and Minamino
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: data/forage.json has spots in the three outer parts (28 in all, on grass next to
  paddies, bamboo, pines, the creek and the water shrine, off the lanes) and nine new wild
  things of their own (our names and looks): water dropwort, horsetail, wild garlic, mugwort,
  sansho pepper, mulberries, ginkgo nuts, yam bulbils, nameko. Each part has one found nowhere
  else (Kaminoda water dropwort, Sakurazaka sansho, Minamino mulberries and ginkgo nuts).
  Mulberries are eaten raw (foods.json). A few gift likes: Kiku and Nana mulberries, Ichiro
  ginkgo nuts and nameko, Haru dropwort and wild garlic, Shige yam bulbils; Nana dislikes sansho.
  No code changed: the rules, views and save already worked per map.
- Balance (ours): a part's round is about 50-130 G a day in spring to fall, 25-50 in winter
  (Kaminoda 96 / 46 / 97 / 49, Sakurazaka 108 / 132 / 119 / 25, Minamino 48 / 64 / 104 / 25),
  under the hill's 210 / 163 / 275 / 75. Common greens are cheap (8-12 G). The parts lie on the
  ways to the hill, the mine and the river, so most of it is picked in passing; all four areas
  in one spring day come to about 460 G, but that takes most of the day's walking. A first
  draft gave the parts 120 G each in spring; spring spots and the greens' prices were cut.
- Checked: test_forage now also checks no spot is on a lane, each part has 4+ spots in spring,
  summer and fall and one in winter, and a thing of its own; a pick in Kaminoda (water
  dropwort, kept apart from the hill's picks); Minamino's 3D layer; mulberries edible; the
  icons of all 19 wild things drawn (first run: dropwort was also in Sakurazaka, moved). All 25
  test scripts print `OK (0 failed)`; smoke runs (title, `--demo`, town, mine 3, the three
  parts) print no errors; screenshots: bamboo shoots in Kaminoda in spring, ginkgo nuts by
  Minamino's shrine in fall (that spot moved from the map's edge, out of frame, to [3, 5]).
- Left / next: wild things in recipes; a talk line or two about foraging.

## 2026-11-01 — The new villagers as contest rivals
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: one villager from the outer parts joins the rivals of every contest and game
  (data/festivals.json): Shige at the Blossom Crop Show ([45, 80], a potato), Genzo at the
  Lantern Night Catch ([40, 130], a loach from his paddy), Haru at the Moon Offering ([50, 135],
  an egg from her hens), Ichiro at the First Stone ([80, 240], amber from a pine's roots) and at
  the mochi pounding ([36, 72]), Nana in the Moon Pond Race ([2, 7], like Sayo). In the four
  result events they walk up from their festival plans with their entries overhead and stand
  at the end of the line (Shige [18, 9], Genzo [13, 8], Haru [20, 9], Ichiro [11, 5]), then go
  back. Each has a winner's line in data/dialogue/contests.json (six new, our own).
- Balance (ours): the new ranges sit inside the old rivals' spread, never above the best one,
  so a good entry still wins; one more rival only thins the lower places a little.
  `tools/balance.py` before / after: Lantern Night 32 / 68 / 0 % → 26 / 67 / 7 % (first /
  second / third), the others within two points; contest prizes 29 G less over the year
  (year net 99674 → 99645 G).
- Checked: test_festivals' rival checks now cover the new rivals (at the table, entries of the
  kind, back to their plans, every place and winner's line); its fixed counts moved (four
  rivals, last place 5 / 6, six bad prizes); all 25 test scripts print `OK (0 failed)`; smoke
  runs (title, `--demo`, town, mine 3, Blossom Day) print no errors; a screenshot of
  `--festival=blossom_day --contest=potato` shows Shige holding a potato at the left of the line.
- Left / next: forage in the other parts; wild things in recipes.

## 2026-11-01 — The new villagers in the village record
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: a Neighbours row on the village record and the yearly pages (data/ending.json
  category `neighbours`, measure `neighbours_known`, steps 2 / 4 / 6 / 8): the villagers
  without hearts (Genzo, Haru, Fumi, Ichiro, Shige, Nana, Kiku and Dr. Yae) whose hidden
  affection, which talks and gifts already raise for them, reached `neighbour_band` (1, i.e. 20
  points: about twenty days of talk or ten of talk and a liked gift). Game.ending_values
  measures it; Ending.MEASURES has it (old saved pages without it still load). The record now
  has 43 stars, so the rank steps moved from 8 / 16 / 24 / 33 to 9 / 18 / 27 / 36, keeping
  each rank at about the same share. The closing visitor is still the friend liked most (the
  people with hearts).
- Checked: test_ending (no neighbours at the start; Genzo and Dr. Yae known at band 1, Fumi
  one point short not; friends don't count there; the top step is everyone without hearts);
  `tools/play_year.gd -- --years=2` printed `Neighbours 7 3 / 4 stars`, `31 / 43 stars: rank
  3, "Keeper of the Satoyama"` and `play_year: OK (no problems seen)` (Fumi stays at band 0:
  the bot rarely finds her inside the teahouse); all 25 test scripts print `OK (0 failed)`;
  smoke runs (title, `--demo`, town, mine 3, `--ending=year`) print no errors; a screenshot
  of `--ending` shows the 11 rows and 3 field rows fitting on the scroll.
- Left / next: the new villagers as contest rivals; forage in the other parts.

## 2026-11-01 — The new villagers at the festivals
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: Genzo, Haru, Fumi, Ichiro, Shige, Nana and Kiku each have three festival plans and
  rules for them (first in their rule lists, before the wet-day one): `festival_day` (Blossom
  Day), `festival_night` (Lantern Night and Moon Night) and `festival_year` (Year's Turn). The
  day is a holiday at home (Fumi at her teahouse counter until she leaves), then the walk down
  their lane, through the village door of their part, to a spot of their own: Genzo and Haru on
  a picnic mat, Fumi by the dango stall, Kiku under a cherry, Shige by the small mat, Ichiro by
  the east cherries, Nana running along the south lane on Blossom Day; by the stalls and on the
  road at the night festivals; on the shrine gravel (Fumi at the soba stall, Ichiro by the
  bonfire) at Year's Turn, Nana running by the torii. They arrive in the first quarter hour
  and leave at 15:45 / 21:40 / 23:00 (Kiku, the oldest and slowest, at 21:00 and 22:30), home
  and to bed after. Leg times were worked out from each one's walk speed with a few minutes
  spare (a generator script, not kept). Each has a `festival_<id>` line for all four
  festivals (28 new lines, our own). The teahouse has a `festival_away` note. Dr. Yae stays
  by the clinic.
- Checked: test_festivals' crowd check now covers every villager but Yae (in the village in
  the hours, the festival line, no two on one cell), plus the outer parts only in Blossom
  Day's hours and Fumi's Lantern Night; first run of test_villagers found Nana's Blossom loop
  walking through a fence at (12, 14): moved east. All 25 test scripts print `OK (0 failed)`;
  smoke runs (title, `--demo`, town, mine 3, `--festival=years_turn`) print no errors;
  screenshots of Blossom Day at 10:31 and Year's Turn at 19:31 show the bigger crowd.
- Left / next: the new villagers in the village record and as contest rivals; forage in the
  other parts.

## 2026-11-01 — Forage on the bamboo hill
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: DESIGN's forage rule (fixed spots per area, the kind changes with the season, a picked
  spot is back after a night). `data/forage.json`: ten wild items (`wild:<id>`: bamboo shoot,
  bracken, butterbur bud, wild raspberry, myoga ginger, chestnuts, akebi, oyster mushroom,
  matsutake, wild enoki; names, bin prices, looks) and fifteen spots on the hill by bamboo
  clumps and pines (10 in spring, 9 in summer, 11 in fall, 3 in winter). `Forage`
  (scripts/items/forage.gd) is the rules; Game keeps `forage_picked` (saved under `forage`,
  cleared in end_day, old saves load with nothing picked), `forage_here()` and
  `forage_pick(c)` (overhead with free hands, else into the rucksack, else "No room");
  FarmActions.interact picks a spot on any map. Wild things ship (sell_price), have names,
  icons (PlaceholderArt `ui:wild:<id>`, seven shapes) and stand on their cells in both views
  (ForageLayer, ForageView; redrawn on `Game.forage_changed`). Raspberries and akebi are eaten
  raw; Genzo, Haru, Tome and Kota like some as gifts.
- Balance (ours): bin prices 12-30 G (matsutake 80), so a full round of the hill is about
  210 G a day in spring, 160 in summer, 275 in fall and 75 in winter. That is roughly one turnip
  bag's harvest a day in the first spring (a real help while the field is small) and a small
  share once the farm runs; the cost is the walk (the hill is two maps from the village) and no
  stamina, as foraging is a walker's income.
- Checked: new tests/test_forage.gd prints `test_forage: OK (0 failed)` (first runs: the views
  must be loaded at run time in a --script test, the hand's item ships with the rucksack, saved
  cells come back as floats); test_food's raw check accepts wild items; all 25 test scripts
  print `OK (0 failed)`; smoke runs (title, `--demo`, town, mine 3, the hill in fall) print no
  errors; screenshots of the hill's foot in spring (a bamboo shoot, a butterbur bud, bracken)
  and its top in fall (akebi).
- Left / next: forage in Kaminoda / Sakurazaka / Minamino, wild things in recipes, the new
  villagers at the festivals.

## 2026-11-01 — The Hanami teahouse is a shop
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: shop `teahouse` in data/shops.json (Fumi keeper, open 9:00-18:00 every day like its
  door): green tea (45 G), dango and whipped matcha the year round, and a sweet per season:
  sakura mochi, warabi mochi, chestnut yokan, zenzai. Four new foods in data/foods.json (shop
  false, sold only here; looks cup / plate / plate / bowl). Balance: matcha 150 G for fatigue
  -8 sits between tea (-5, 40 G) and the clinic's tonic (-15, 400 G); the sweets give 20-36
  stamina for 100-160 G, about amazake's rate per G, a treat on the way to the mine rather than
  a cheaper store. The teahouse counter is a shop counter now, with `keeper` [4, 1] behind its
  right end (Fumi's plan steps start there) and `counter` [4, 3] in front. A shop may have an
  `away` note for while its keeper is out (Shop.away, used by Game.keeper_away_text; default
  "Nobody is at the counter"): Fumi's says she is out front, back at three (she sweeps and
  walks 13:00-15:00). The new sweets are on a few gift lists (Tome zenzai, Kota warabi mochi,
  Sayo chestnut yokan, Fumi matcha); Fumi's summer line mentions the warabi mochi.
  test_festivals' "every stall-only food is on a stall" check now also accepts a shop's stock.
- Checked: test_shops `_teahouse` (stock per season, the foods only here, keeper spot,
  Talk.keeper_shop, open at 10:00, her note at 13:30, open on a wet day, closed at 18:00, a
  matcha bought); all 24 test scripts print `OK (0 failed)`; smoke runs (title, `--demo`, town,
  mine 3, the teahouse at 10:00) print no errors; screenshots of `--season=summer
  --shop=teahouse` (the four rows with their icons) and Fumi behind the counter at 10:00.
- Left / next: forage on the hill, the new villagers at the festivals and in the record.

## 2026-11-01 — The export templates archive taken out of the history
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: on the user's word, the 1.28 GB `Godot_v4.7.2-stable_export_templates.tpz` committed by
  mistake with the wide farm is gone from git: `git filter-branch --index-filter 'git rm
  --cached --ignore-unmatch ...' -- 0c5c6a8..main` rewrote the seven commits after 0c5c6a8
  (no other branch held them; no remote), then refs/original was deleted, the reflogs expired
  and `git gc --prune=now` run. New hashes: b5b9d65 (wide farm), 22b8191 (wide village),
  0ea1c5e (bamboo hill), ef4efa3 (back to the old sizes), 12fa5b3 (Kaminoda), 6eec48e
  (Sakurazaka), 2567c6b (Minamino); the WORKLOG's old hashes are updated. The archive itself
  stays on the disk for installing the templates (README → Export), ignored by `*.tpz`.
- Checked: `git diff --stat 9299ad2 2567c6b` printed nothing (the last tree is unchanged);
  `git log --all -- Godot_v4.7.2-stable_export_templates.tpz` prints nothing; `git count-objects
  -vH` size-pack 1.86 MiB (was 1.22 GiB loose); the archive on disk is 1281349702 bytes.

## 2026-11-01 — Minamino: the village's south part, Shige, Nana and Kiku
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: `data/maps/minamino.json` (30 x 20) between the village's south lane and the river
  (village → Minamino → river, both ways). The lane runs on down to the river, a cart track
  east; vegetable gardens behind a low board fence and by Shige's house, a well, a little
  roadside water shrine with a stone lantern and gravel, a jizo by the way down, bamboo in a
  corner, Kiku's house in her persimmon orchard with a drying rack. Rooms: `shige_house` (Shige
  and Nana; toy box, altar, keepsake spots for both) and `kiku_house` (hearth, alcove). Three
  villagers without hearts: Shige the vegetable grower (gardens at work pose, the well at five,
  mends tools when wet), Nana his daughter (helps in the morning, runs up to the village pond
  to play by Kota 14:00-17:00, so the village has three out then) and Kiku of the persimmon
  orchard (orchard, the roadside shrine at two); looks, faces, whistles, gifts, own lines.
  The Sunday river walks pass through Minamino now: Hachiro leaves the smithy at 8:40 (was
  9:00) and is back at 15:55 (was 15:45); Kota reaches the river at 14:20 (was 14:10) and is
  home at 17:30 as before.
- Checked: test_maps (village ↔ Minamino ↔ river; doors and rooms of Minamino), test_fishing
  walks through Minamino to the river, test_villagers (Hachiro in Minamino at 9:15, whistlers
  any villager, Kota, Nana and Tome in the village at 14:20); all 24 test scripts print `OK (0
  failed)` (first run: Kiku's whistle 4.55 s, over the 4 s cap: faster tune); smoke runs (title,
  `--demo`, town, mine 3, Minamino 14:30, the river, a Sunday 9:10 in Minamino) print no errors;
  screenshots of Shige and Nana at the gardens and Kiku at the shrine in fall.
- Left / next: the user should walk the new parts. Ideas: forage on the hill, the new
  villagers at the festivals, a shop at the teahouse.

## 2026-11-01 — Sakurazaka: the village's east part, the teahouse, Fumi and Ichiro
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: `data/maps/sakurazaka.json` (30 x 20) between the village road's east end and the mine
  (both doors re-pointed: village → Sakurazaka → mine, the mine's way back comes out at its
  east end). The road climbs east under cherry trees, crosses a creek on a plank bridge (floor
  tiles over the water, four stone lanterns), a bamboo grove north-east of the creek, a jizo, a
  kitchen garden. North of the road Fumi's Hanami teahouse (noren, raked gravel; `teahouse`, a
  room with a counter, shelves, low tables and cushions; open 9:00-18:00); south of it Ichiro's
  house (`ichiro_house`: a big earth entry with his tool rack and charcoal sacks) with firewood
  stacked by it. The creek is a fishing place (`sakurazaka` in data/fish.json: dace, masu trout,
  char, sculpin, lighter weights than the river). Two villagers without hearts: Fumi (her
  counter, sweeping the gravel after lunch, a stroll to the bridge) and Ichiro (cutting wood in
  the grove at work pose, lunch on the teahouse gravel, stacking firewood; works indoors when
  wet), each with looks, a face, a whistle, gifts, own lines and keepsake spots.
- Checked: test_maps' door / room checks run for Sakurazaka too; test_mine follows the new
  chain; test_fishing's "only the river" check allows the creek for the stream fish; all 24
  test scripts print `OK (0 failed)` (first run found plan walks through furniture, a whistle
  note too low and a gift line's mood: fixed); smoke runs (title, `--demo`, town, mine entrance,
  mine 3, Sakurazaka at 12:30) print no errors; screenshots of the bridge with cherries and
  lanterns (Ichiro at lunch by the teahouse) and Fumi in her teahouse.
- Left / next: the south part between the village and the river, its people.

## 2026-11-01 — Kaminoda: the village's north part, countryside props, Genzo and Haru
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the first of the village's outer parts (the user asked for north / south / east parts,
  more houses and more people, more rural Japanese). `data/maps/kaminoda.json` (32 x 20), up the
  village's north lane (which led straight to the hill before): a farming hamlet with terraced
  paddies, lower paddies along a dike, two rice drying racks, a well at the crossroads, a pair of
  jizo by the way in, a persimmon orchard, two cherry trees, a woodpile and a kitchen garden
  behind a low fence; its lane north climbs to the bamboo hill (its door now comes back here).
  Two houses with rooms (`genzo_house`, `haru_house`, 9 x 7 like the village homes; door hours,
  a closed message, a keepsake spot each). New prop kinds in `scripts/world3d/country_props.gd`
  (CountryProps, flat colours in MapView): well, jizo, persimmon and sakura (leaves by season,
  bare in winter, persimmons hang in fall and winter), hasa (sheaves in fall), woodpile, garden,
  wood_fence. Two villagers without hearts: Genzo, an old rice farmer (walks his terraces, the
  dike after lunch, the well at five; home on wet days) and Haru, a straw weaver (her garden, the
  drying rack, the hill lookout in the afternoon; weaves at home when wet), each with looks, a
  face, a whistle, gifts (a loved dish and keepsake each, a mine find), our own talk lines
  (season, weather, the hill, gift and dish answers).
- Checked: test_maps' new checks (village ↔ Kaminoda ↔ hill doors; every Kaminoda door can be
  walked to and each room's way out comes back in front of it); test_villagers' doctor check
  now counts every villager without hearts; all 24 test scripts print `OK (0 failed)`; smoke
  runs (title, `--demo`, town, mine 3, Kaminoda and the hill at 14:30) print no errors;
  screenshots of Kaminoda in spring (well, woodpile, racks, paddies) and fall (sheaves on the
  racks) and Genzo by his hearth at 6:30. One test_villagers run failed the lumber check once
  ("the cell he fetches from stays open"); the two runs after passed: it may be flaky.
- Left / next: the east part (between the village and the mine), the south part (between the
  village and the river), their people.

## 2026-11-01 — Back to the old farm and village sizes (more areas instead)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the user played the wide maps: the walks were too long and dull, the village had no
  character of its own, the new ground too empty and not rural Japanese enough. They want the
  old maps kept and more areas added instead (north, south and east parts of the village), more
  houses and more villagers. So b5b9d65 (farm 64 x 48) and 22b8191 (village 56 x 36) are undone
  by hand: the farm is 32 x 20 with its gate on the right fence again, the village 36 x 22, the
  river and mine doors, the Sunday river walks, Hachiro's farm route and the tests as before.
  Kept: the 3D farm view's cheaper redraw (unchanged sprites kept, snow mask only while snow
  lies), the `paddy` tile (for the new areas) and the bamboo hill. A save made while the farm was
  64 x 48 loads cut back to 32 x 20 (`FarmGrid.WIDE_W / WIDE_H`, `_cut_back`: what was inside the
  fence line stays). The village gets a lane north at x 10-11 (spawn `north`) that leads to the
  hill for now; the north part of the village will sit between them.
- Found: the farm commit also committed `Godot_v4.7.2-stable_export_templates.tpz` (1.28 GB),
  which had been put in the project folder during the session; the revert took it off the disk,
  so it was written back from git (same size) and is untracked now, `*.tpz` in .gitignore. The
  history was rewritten afterwards to drop it (see the entry above).
- Checked: test_farm's `_wide_save` (a 64 x 48 save loads cut back, inside kept, border fenced),
  test_maps (north lane ↔ hill); all 24 test scripts print `OK (0 failed)`.
- Left / next: countryside props, the north / east / south parts of the village, new villagers.

## 2026-11-01 — The bamboo hill (a new map up the village's north lane)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: `data/maps/hill.json` (40 x 30, outdoor): a two-cell path switching back and forth up
  the slope from the foot (door at its bottom edge, x 19-20, back to the village lane's top
  at (45, 1)) to a lookout of raked gravel under a cliff (`rock_wall` along the top, scree in the
  corners) with a little mountain shrine (hokora) and two stone lanterns. 113 `bamboo` clumps
  (a new prop: three or four leaning stalks, pale node rings, leaf sprays, the spot picks the
  look; a flat colour in the 2D view) stand in groves off the path, scattered once with a seeded
  script (odds 0.3, never next to the path) and kept as data, plus seven pines. Village: the lane
  at x 45-46 ends in a door to the hill, spawn `hill`. Events (`triggers_hill.json`,
  `data/dialogue/examine_hill.json`, our own lines): examine the shrine, the view (a winter
  line too), and a line on first stepping onto the lookout.
- Checked: test_maps (doors both ways, clumps solid on grass, the lookout reachable from the
  foot by a flood fill, the cliff) and test_events (shrine, view, winter view, first climb only
  at the lookout); all 24 test scripts print `OK (0 failed)`; smoke runs print no errors;
  screenshots of `--map=hill` (path and groves) and `--map=hill@top` (shrine, lanterns, cliff).
- Left / next: the hill has nothing to gather yet: forage (bamboo shoots in spring, mushrooms
  in fall) would give it a reason to climb; villagers could walk up it too.

## 2026-11-01 — The village widened to 56 x 36 (rice paddies, longer roads)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: data/maps/town.json 36 x 22 → 56 x 36. As on the farm, the old part keeps its place
  (top left), so the villagers' plans, festival places, events and examine spots all still
  hold. The new ground east and south is rice paddies: a new `paddy` ground tile (solid, legend
  `p`; PlaceholderArt `ground:paddy:<n>`: still water catching the sky, rows of rice tufts;
  snow holds 0.5 on it), in blocks with grass dikes between. The road runs on east to the mine
  (door at x 56, the mine's way back spawns at (54, 10)), a farm track goes down the east side
  (x 45-46) to a track along the south paddies (y 28), a lane runs north at x 45-46 to the top
  edge for the hill (next task), the river lane is 14 cells longer (door at y 36; the river's
  way back spawns at (4, 34)), and 17 pines dot the new edges. The longer lane moves the
  Sunday river walks (1.5 cells a game minute): Hachiro leaves the smithy at 8:50 (was 9:00)
  and is back at 15:55 (was 15:45), Kota leaves home at 13:50 (was 14:00).
- Checked: test_maps' new checks (size, paddy solid and drawn as paddy, tracks / hill lane /
  east road open, the mine and river return spawns), river / mine door checks moved to the new
  edges, the festival test's off-map stall moved to x 55; all 24 test scripts print `OK (0
  failed)`; smoke runs (title, `--demo`, `--map=town`, `--mine=3`, a Sunday 9:10 in the village)
  print no errors; screenshots of `--map=town@river` in spring and under snow (paddies read as
  water with rice rows, snow lies patchy on them).
- Left / next: the bamboo hill off the lane north (x 45-46, y 0).

## 2026-11-01 — The farm widened to 64 x 48 (woodlot, top gate, old saves grow)
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: the user found the maps small next to other farming games; the plan is farm, then
  village, then a new area. `FarmGrid.W / H` 32 x 20 → 64 x 48 (data/maps/farm.json `size`).
  The yard (house, chest, bin, stand, coop, barn, pond) stays where it was, so every farm
  coordinate in the data and tests still holds; the field fills the new ground. The village gate
  moved from the right fence (31, 5-6) to the top fence (31-32, 0) right of the pond, so the
  walk to the village is no longer than before (a right-edge gate would have been 60 cells,
  about 20 game minutes, from the house); the town's farm door spawns there facing down, the
  gate board's examine spots are either side of it, and Hachiro's building route comes in by it.
  `FarmGrid.WOODLOT` (48..62, 32..46): debris odds 0.45 instead of 0.15, mostly stumps and
  branches, as a place for the axe. A save of the old size (`OLD_W` x `OLD_H`, read from its
  `w` / `h`) grows on load (`_widen`): cells, buildings and items in place, the old right and
  bottom fences opened up, new ground scattered from a fixed seed (the same every load), the
  fence round the new border; no save version bump needed. The 3D view's object sprites were
  rebuilt from scratch on every field change: 35 ms a change at the new size (6 ms at the old);
  now bare cells are skipped first, a sprite whose art key is unchanged is kept, and the snow
  mask is drawn only while snow lies (or when it starts): 5.4 ms (10 redraws in 54 ms, headless).
- Checked: test_farm's new `_wide_farm` (woodlot denser and woodier, the old save's cells /
  buildings / items in place, old fence lines open, new border fenced, same ground every load,
  a wide save loads as it is, another size refused); two checks moved (dog off the farm at x 70,
  the gate board at (30, 0)); all 24 test scripts print `OK (0 failed)`; smoke runs (title,
  `--demo`, `--map=town`, `--mine=3`) print no errors; screenshots of `--demo`, `--map=farm@gate`
  (the gap in the top fence behind the farmer) and `--season=winter --snow=80` (snow drawn).
- Left / next: the village to about 56 x 36, then a new area off the village (bamboo hill).

## 2026-11-01 — Merged two branches: fishing race, villager whistling
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time: `claude/fishing-race-7c15bf` (c68610e, clean
  merge, merge 357991e) then `claude/whistling-7063b0` (c79ea15, merge 9262266).
  Only WORKLOG.md conflicted (both added a top entry); both entries were kept, whistling above
  the fishing race, and their "this commit" became the branch commit hashes.
- Checked on merged main: the importer ran; all 24 test scripts print `OK (0 failed)` after each
  merge; headless smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --festival=moon_night --contest=fishing:auto`) printed no errors or warnings.
- Left / next: the year-bot session (river fishing, mine food) is still running on its own
  branch; the race's rival numbers and the whistles need a person to play / hear them.

## 2026-11-01 — Villagers whistle as they walk (data/whistles.json, Whistles, note puff)
Agent: Claude Code (claude-opus-5-5) · Commit: c79ea15
- Done: `data/whistles.json` holds the rules and one short tune per villager (our own motifs,
  4-9 notes in a five-note scale: Kota quick and high, Tome slow, Hachiro sturdy, Sayo lilting,
  Yae a careful little figure), played by MusicSynth on a `whistle` flute voice that is nearly a
  pure sine. `scripts/villagers/whistles.gd` (Whistles, pure logic): once a game minute each
  villager on the farmer's map who is walking (`Villagers.pose`, new, also used by sprite_key),
  on a sunny look, 7:00-18:59, on an outdoor map, not acting in an event, starts their tune with
  odds 0.06, at least 40 minutes after the last; the roll is seeded from a hash of villager, day
  and minute (a plain string hash was too even from minute to minute: no hits at all), so it is
  frame-rate free and a day replays the same. Level 1 within 3 cells of the farmer, falling
  (squared) to 0 at 14. `Sfx._whistle_step` / `Sfx.whistle` play it on the SFX bus at -14 dB +
  the level; the tunes are made on worker threads at start (`song_stream("whistle:<id>")`, in
  Movie Maker at once). Both views draw `fx:note` / `fx:notes` (dark ink, pale rim) rising and
  swaying over the whistler (`Whistles.puff_look`). `-- --whistle` (or `=<id>`) makes every walker
  whistle at once, for screenshots. Balance reasoning: 0.06 a walking minute with a 40 minute
  gap is about one tune per game hour (30 s) of a villager walking in view, so it is an
  occasional touch, not a radio.
- Checked: all 24 test scripts print `OK (0 failed)` (test_villagers: new `_whistles` checks for
  the rules, odds, gap, level, puff, a fair day in the village, wet / indoor / night days with no
  tunes, `--whistle`, and the puff in both views; test_audio: every tune renders normalized, its
  length, quiet ends, not cut off, notes 500-2500 Hz, each tune different, `Sfx.whistle` at its
  dB and nothing out of hearing). Headless smoke runs (title, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, `--demo --map=town --whistle`) printed no errors or warnings. Screenshots
  `--demo --map=town --time=10:00 --whistle` in the 3D view (a single note over Kota, zoomed
  in to check) and in `main_2d.tscn` (the beamed pair over Kota); `shots/` deleted.
- Left / next: **the whistling has not been heard by a person** (headless and Movie Maker runs
  are silent): the tunes' pitch, loudness (-14 dB) and how often they come need a listen in a
  real run.

## 2026-11-01 — Fishing race: Moon Night's Moon Pond Race (a second played contest)
Agent: Claude Code (claude-opus-5-5) · Commit: c68610e
- Done: Moon Night (fall 15, 18:00-23:00, town) gets a festival `game` of the new kind `fishing`:
  the Moon Pond Race at a `race_flag` prop (bamboo pole, indigo banner with a white fish, a
  creel) at [30, 13] by the village pond. Moon Night was picked because it had no played game
  (Lantern Night already has the judged fish contest) and the village pond is on its map.
  `FishingRace` (scripts/festivals/fishing_race.gd, pure): a `lead` count-in, `seconds` of
  racing, then the "Time!" call; the creel; to_dict / parse. Game: `start_game` for a race needs
  empty hands and the rod in a tool slot (it goes in hand), `race` is stepped in `_process`,
  `cast_line` refuses outside the race time (`race_wait`), `reel_in` puts a race catch in the
  creel instead of overhead (still counted in fish_caught; once-only fish are left out of a
  race's candidates), the clock holds while a race runs (`ticking()`), time stops the line,
  `_end_race` hands the count to `finish_game` (no partner, so no contest_partner flag), and
  leaving the map ends the race with the creel as it is. The race is saved in `fishing.race`
  ({time, fish}; refused when broken or on a day without one). Festivals: `GAMES` has fishing ->
  race_flag, `seconds` is a game key, `_check_game` checks a race (lead 0-10, seconds 10-600, no
  mochi keys) and refuses `seconds` on a mochi game. `RaceScreen` (scripts/ui/race_screen.gd) in
  both views: a wood box under the message line with the name, the fish count, the time left
  (red in the last 10 s), a bar, the last 8 fish pictures, "Ready... 3" / "Go!" / "Time!", and
  the cues (`mochi_count` clicks, `chime_morning`). MochiScreen now opens only for kind mochi.
  The 3D flag (FestivalProps) and the flat picture (`festival:race_flag`), the `contest_fishing`
  event and `fishing_result` lines (Tsuru, a line for each rival who wins, the places).
  `--contest=fishing` (stands below the flag facing the pond, race on) and `fishing:auto`
  (casts, reels 0.25 s into each bite). README → Festivals, AGENTS.md.
- Balance (ours): 60 s, lead 3 s. At 18:30 the bite chance is 0.32 a check after 2.5 s, so a fish
  takes about 5 s; the auto bot (perfect reactions, first rod) landed 12 in a headless run
  (`--fixed-fps 30 --quit-after 2100`, read with a temporary print, since removed). A person who
  reacts and recasts a little slower should get 7-10. Rivals: Hachiro 6-11, Tome 4-9, Kota 3-8,
  Sayo 2-7. Prizes 400 G + 2 grilled fish, 150 G + 1, 80 G (like the mochi pounding: once a
  year). The creel is let go, so the race adds no shipping money.
- Checked: all 24 test scripts print `OK (0 failed)`. test_festivals adds: the race data and bad
  data, the clock, the result lines for every place / winner, and playing it in Game (the rod,
  the count-in, casting at the pond, the creel, no moonlit koi in 40 catches at 22:00, a save
  mid-race, first prize and ribbon, one go a year, leaving mid-race), the 3D flag, the box in
  both views, the mochi screen leaving a race alone; `_flat_art` checks the new picture.
  Headless runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --festival=moon_night --contest=fishing[:auto]`, `--demo --festival=years_turn
  --contest=mochi:auto`, `res://scenes/main.tscn --quit-after 400`) printed no errors.
  Screenshots at frame 689 of `--contest=fishing:auto`: the 3D view (0:41, 4 fish, the banner by
  the pond) and the flat view (0:41, 5 fish, "A Crucian carp! 5 in the creel"); `shots/` deleted.
- Left / next: a person should play the race (and the mochi pounding) to tune the rivals; the
  year bot (tools/play_year.gd, another session's) does not play the race yet.

## 2026-11-01 — Merged six branches: scroll, mine art, portraits, festival crowd, mochi contest, year bot
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time, all tests after each, onto the main that already had
  the ten merges above: `claude/ending-scroll-702690` (5c16326), `claude/mine-art-72ed93`
  (0c1f08c), `claude/portraits-ce4710` (da7eb7f), `claude/festival-crowd-26fd41` (00682e8),
  `claude/mochi-contest-73fb06` (7e363ae), `claude/year-bot-d873b4` (553b859, 4621641).
  WORKLOG was rebuilt each time from main's file with the branch's new entry on top (mine-art's
  file had mixed line endings, year-bot's an empty line after every line). The scroll keeps the UI
  size setting (`UiScale.apply_layer` on the scroll's rect). Portraits: the moods were moved onto
  main's talk files line by line; main's newer lines (gift, river, Yae's) had `face`, now `mood`
  (calm → neutral, smile → happy, worried → sad), since test_talk wants a mood on every villager
  line; Yae gets a portrait from her speakers.json colours; the rivals test's Judge stub takes the
  new `mood` argument. Festival crowd: main already had the rivals walking up (contest-rivals,
  574de93: `holds`, `meanwhile`, `walkers`), so main's contest events, EventRunner, villager views
  and event tests were kept and the branch's own version (`hold`, `"wait": false`, `walks`) was
  not taken; what came in is the gathering: Hachiro's and Sayo's festival day plans (Hachiro's
  festival rules go before main's river Sundays), the festival talk picks and lines (as moods),
  Sayo's Blossom Day counter note, `_crowd` / `_store_note` checks, README "The crowd". Mochi: the
  flat view now draws decorations as pictures (flat-decor), so the mortar became a
  `festival:mochi_usu` picture (the 32 x 24 usu, half pounded) instead of the branch's special
  case. The importer had to run for the new `MochiPound` / `MochiScreen` class names.
- Checked on merged main: all 24 test scripts print `OK (0 failed)`; headless runs (title,
  `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --season=winter --mine=3`, `--demo
  --ending`, `--demo --ending=year`, `--demo --festival=years_turn --contest=mochi:auto`, `--demo
  --festival=blossom_day --contest=potato`, `--demo --map=town --time=14:30 --talk=tome`, `--demo
  --map=clinic`, `res://scenes/main.tscn --quit-after 400`, `main_2d.tscn -- --demo
  --festival=years_turn`) printed no errors or warnings. `tools/play_year.gd` on merged main:
  `play_year: OK (no problems seen)`, 27 / 39 stars, rank 3; every villager, Yae too, reaches
  band 6 in year 1 even with the slower gifts. Screenshots: Yae's text box (her portrait) and the
  flat view at Year's Turn (the mortar by the shrine path); `shots/` deleted.
- Left / next: the mochi timing needs a person to play it; friendships may still fill too fast
  (all band 6 in year 1 in the bot); the .exe once the export templates are installed.

## 2026-11-01 — Year playtest bot (tools/play_year.gd); gifts slower, mine steps lower
Agent: Claude Code (claude-opus-5-5) · Commit: 4621641 (the bot's first version: 553b859)
- Done: `tools/play_year.gd` (`--headless --path . --script res://tools/play_year.gd`, `-- --years=2
  --seed=N`): a bot that plays through the real rules (Game's clock, stamina, fatigue, sleep;
  FarmActions.use_tool / buy_seeds; the shops with their hours, days off and keepers; Animals; the
  mine; fishing; cooking; talks and gifts; contests; the maps' trigger tables through a small
  headless EventPlayer, so heart events, lessons, the radio, the year page and the ending play).
  It keeps the save slot as it was and checks a save round trip each season. Its plan: 3 x 3 plots
  by the can's level with a mix of the season's crops, the coop and the barn, the mine on rain days
  and in winter (down as soon as the hole is found), a daily village round with a talk and the best
  gift carried, the goals of balance.py plus the kitchen tools, the four contests. Since 553b859:
  the smithy is visited after 10:00 (no time passes in the store), the crop mix, deeper mining.
- Balance, from the report: (1) Gifts were far too strong: with 8 / 3 every villager was at band
  5-6 by the end of summer (Sayo 232 in spring), against `_common.json`'s own note. Now love 4,
  like 2 (talk 1): a liked gift a day reaches band 3 in 30 days, a loved one in 18, band 6 in about
  47 days of loved gifts. The daily-gifting bot still has everyone at band 6 by the end of fall;
  that is the most a player can do, so it stays. (2) The ending's mine steps 12 / 20 / 30 couldn't
  be reached: every trip starts at floor 1, a floor costs ~20 stamina to find its hole, and the bot
  mining every winter day got to floor 6. Now 5 / 10 / 15 / 20 (20 = a whole day's trip with food).
  Not changed: the hammer reaches level 4-5 from mine swings alone (exp 90 / 270) while the hoe,
  sickle and axe stay low; the mine is where hammer work is, so it is left as it is.
- Report (seed 1, `-- --years=2`, after both changes, quoted from the run; the record was graded
  with the old mine steps, and floor 6 earns 1 star with either):
  ```
  == Year 1 spring: income 15102 G, costs 12100 G, money 500 -> 3502 G
     bought: can 2, hoe 2, rucksack, 2 chicken, chest
  == Year 1 summer: income 29309 G, costs 29310 G, money 3502 -> 3501 G
     bought: sickle 2, can 3, kitchen, kitchen tools, 1 cow, 2 chicken
  == Year 1 fall: income 49538 G, costs 45060 G, money 3501 -> 7979 G
     bought: 1 sheep, hammer 2, rucksack, 1 cow, room
  == Year 1 winter: income 42046 G, costs 7990 G, money 7979 -> 41345 G
     bought: can 4, hoe 3, axe 2, hammer 3, rod 2
  == Year 2 spring: income 50042 G ... money 41345 -> 83237 G
  == Year 2 summer: income 58937 G ... money 83237 -> 132784 G
  == Year 2 fall: income 61682 G ... money 132784 -> 182716 G
  == Year 2 winter: income 40516 G ... money 182716 -> 218132 G
  == Spring 1, Year 3: the village record (the ending played)
     Shipped 344472 3/4, Crops 11 4/4, Happy animals 9 3/4, Friendships 24 4/4, Deepest floor 6 1/4,
     Fish kinds 4 2/4, House built 3 3/3, Tool levels 13 3/4, Contests won 4 3/4, Recipes 13 4/4
     30 / 39 stars: rank 3, "Keeper of the Satoyama"; closest: hachiro
     goals not reached: none
  play_year: OK (no problems seen)
  ```
  No collapses or passing out in two years; no ores short (each upgrade was bought the first time
  it was due, the smithy's 3 akagane included). Year 1 income: balance.py 155387 G, the bot 135995 G
  (crops 77k vs 60k, animals 50k vs 51k, mine 18k vs 26k, fish 9k vs 14k). The steady plan landing
  in Keeper of the Satoyama is what data/ending.json aims at. No game bugs were found (the save
  round trip held every season).
- Checked: all 24 test scripts print `OK (0 failed)` (test_relationships checks the gift pace,
  test_ending that the deepest mine step is at most 20); headless runs (title `--quit-after 300`,
  `--demo`, `--demo --map=town`, `--demo --mine=3`) printed no errors or warnings.
- Left / next: the bot fishes only at the farm pond (4 kinds) and doesn't buy food for the mine;
  a run takes about 8 minutes a year.

## 2026-11-01 — A played contest: the mochi pounding at Year's Turn
Agent: Claude Code (claude-opus-5-5) · Commit: 7e363ae
- Done: a festival can have a `game` beside its `contest` (data/festivals.json; checked by
  `Festivals._check_game`). Year's Turn has the Mochi Pounding at a new `mochi_usu` prop
  ([20, 4], right of the shrine path): E there with empty hands (`Game.start_game`, from
  `FarmActions.festival_spot`) picks the partner (`Festivals.partner_for`: of Tome and Kota the
  one with more affection, Tome on a tie) and opens the new MochiScreen over either view (wood
  box with name / round / score, a paper stage: the farmer swinging the mallet, the mortar,
  the partner turning the dough, a ring closing on the dough per strike, a dot per strike).
  `MochiPound` (pure logic) keeps the time: rounds of 8 / 10 / 12 strikes at 1.0 / 0.8 /
  0.65 s, 1.6 s gaps, a 2 s lead with a count-in; within 0.07 s great (3), within 0.16 s good
  (1), off the beat or a beat let pass a miss (-1), never below 0; 90 at best. The score is
  ranked by `Festivals.judge_game` (the judging is now shared with contests in `_rank`; the
  partner is rolled but sits out, so the others' scores don't depend on who turns), then
  `Game.finish_game` pays the prize (400 G and 3 kinako mochi / 150 G and 1 / 80 G), sets the
  contest flags (shared `_result_flags`, plus `contest_partner_<id>`), keeps the best score in
  flag `game_best_mochi`, gives a ribbon keyed by the game id (`ribbon:mochi:<place>`;
  `Festivals.ribbon_label` names it "Mochi Pounding ribbon") and plays `contest_mochi` (lines
  `mochi_*` in data/dialogue/contests.json: each rival's win, the place, the partner's last
  word). One go a year (`game:<festival>:<year>`); the First Stone contest is unchanged and
  still open the same night. Art: `mochi:usu:<dough 0..3>` (the dough goes from rice to a
  round mochi as strikes land) and `mochi:kine` (swung round its grip); the mortar in 3D
  (hooped log, dough, leaning mallet, a pail) and in the flat view (its picture). Sounds:
  `mochi_count`, `mochi_pound`, `mochi_miss`, `mochi_turn`. Debug: `--festival=years_turn
  --contest=mochi` (and `:auto`, which swings by itself). README → Festivals, AGENTS.md.
- Balance: rivals Hachiro 48-80, Tome 30-70, Sayo 24-62, Kota 18-58 (out of 90); a player
  landing most strikes as good or great makes 45-65, so first place wants mostly greats.
- Checked: new checks in test_festivals (game data and bad data refused, the timing with a
  hand-made two-round game, a perfect Year's Turn game = 90, the ranking with each partner,
  ties, prizes, the result lines for every place / winner / partner, the game in Game: empty
  hands, busy, one go a year, prize, ribbon, flags, save and load, year 2 with Kota, the screen
  in both views, the 3D mortar, the art). All 24 test scripts print `OK (0 failed)`. Headless
  smoke runs (title, `--demo`, `--map=town`, `--mine=3`, `--festival=years_turn`,
  `--festival=blossom_day --contest=potato`, `res://scenes/main.tscn`) and full auto-played
  games in both views (`--fixed-fps 30 --quit-after 1100 -- --demo --festival=years_turn
  --contest=mochi:auto`, main and main_2d) printed no errors. Screenshots: 3D mid round 1
  (ring on the dough, mallet down, "Great!", 13 pts), the flat view mid round 1, and 3D at
  ~33 s with Tsuru's result line; `shots/` deleted.
- Left / next: a person has to play it for feel (the windows and the rival ranges are a first
  guess); the partner only stands on the screen, not by the mortar in the world; a fishing race
  would be a second `game` kind.

## 2026-11-01 — Festival crowd: rivals walk up with their entries, Hachiro and Sayo come too
Agent: Claude Code (claude-opus-5-5) · Commit: 00682e8
- Done: the two "people" items of "Later for festivals". (1) Rivals at the table: EventRunner's
  actor step takes `hold` (an item carried overhead, `""` puts it down; `EventRunner.holdable`:
  crops, animal goods, `fish:` / `mine:` / `food:` / `keep:` ids) and `"wait": false` (the walk
  starts and the next step begins; walks go on in `_walks`, moved at the start of each update),
  and `{"do": "wait", "walks": true}` waits until every walker has arrived. The four result
  events (data/events/contest_*.json) bring their three rivals from where their plans have them
  (`"at": "plan"`, or in from beside the farmer) to cells round the judges' table, entries held
  (Blossom: Tome's turnip, Kota's cucumber, Sayo's potato; Lantern: ayu, crucian carp, Hachiro's
  catfish; Moon: a good egg, wool, good milk; Year's Turn: amber, gold ore, crystal), then the
  results, then all walk back and leave. VillagerSprites / VillagerView draw the held item on
  the head (`held_by` for tests). The actor checks use `Villagers.file_ids()` now: Villagers'
  own check reads the festivals, whose contest events are checked here, so `all()` was empty
  mid-load. (2) The crowd: Hachiro and Sayo have one festival plan per festival (rules after
  Hachiro's building rule, so a house job still comes first). Hachiro (smithy shut): picnic
  mats 9:40-16:20, the drum stage from 16:40, the shrine gravel by the moon table from 17:40,
  the bonfire from 18:40. Sayo: Blossom Day keeps the store open but she is under the blossoms
  13:00-15:45 and the counter says the new `festival_away` note (data/shops.json, `Shop.festival_away`,
  `Game.keeper_away_text`); the night food stall from 16:50 (store shut); the moon table after
  closing (17:50); the shrine by the bonfire at Year's Turn (18:40). After a late festival both go
  straight to bed (away) at their doors, since their homes' doors shut at 21:00. All four
  villagers got four `festival_<id>` talk lines, picked in the festival's hours right after the
  birthday row. Positions are ours, picked on the town map so the "across, then up or down"
  walks don't cross the tables.
- Checked: test_festivals (every villager on the festival map mid-festival and saying its line,
  not before the hours; every rival present; Sayo at the store in the morning and after 15:45,
  Hachiro building first; each contest event: the results open in under 3.8 s with every rival
  standing round the table, not on the farmer's cell, holding an entry of the contest's kind,
  walking back afterwards, no actors left; Sayo's note at 14:00, the store open at 16:00; the
  held entry drawn in both views and gone after), test_events (two actors walk at once, hold and
  put down, a wait for walks, the new bad steps refused), test_talk (a festival line before the
  heart lines, only in the hours). All 24 test scripts print `OK (0 failed)`; smoke runs
  (title `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --festival=moon_night`, `--demo --festival=years_turn`, `--demo --festival=lantern_night
  --contest=fish:ayu`, `res://scenes/main.tscn --quit-after 400 -- --festival=blossom_day`,
  `main_2d.tscn -- --demo --festival=blossom_day --contest=potato`) printed no errors or
  warnings. Screenshot `--demo --festival=blossom_day --contest=potato --quit-after 120`:
  the result box opens by frame 60, Tome with her turnip left of the farmer, Kota with the
  cucumber and Sayo with the potato right of the judges' table; `shots/` deleted.
- Left / next: the played contest (another session's mochi pounding at Year's Turn; it may touch
  contest_year.json too, merge both); Kota and Tome still use one festival plan for all four
  (standing at the Blossom Day spots); rivals don't set their entries down on the table.

## 2026-11-01 — Villager portraits by mood
Agent: Claude Code (claude-opus-5-5) · Commit: da7eb7f
- Done: the ROADMAP "real portraits" item. Each villager (data/villagers) gets their own 40 x 40
  text box portrait, `portrait:<id>:<mood>` in PlaceholderArt (`_portrait`, `_portrait_body`,
  `_portrait_hair`, `_portrait_mood`, new functions; the generic `face:` key is left as it
  was): their colours from the villager's look, shaped by hair style (Tome's grey bun and
  hairpin, Hachiro's spiky hair under a tenugui headband, Sayo's long hair, fringe and
  kanzashi, Kota's straw hat) and outfit (kimono collar, happi bands, a boy's shirt), with the
  background and marks (wrinkles, stubble, mole, child, plaster) from speakers.json. Moods
  (`DialogueRunner.MOODS`): neutral, happy, sad (brows up, a tear), surprised, angry (brows
  down, gritted teeth, a cross mark); one the art lacks draws neutral. Dialogue lines take an
  optional `mood`; the older `face` still works and names one (calm, smile, worried,
  surprised = neutral, happy, sad, surprised); a line can't have both, and a mood needs a
  speaker. An event's say step takes an optional `mood` for its lines that name none
  (`Game.talk(id, at, mood)` keeps it in `Game.dialogue_mood`, which the text box hands to its
  runner; the signal is unchanged). `DialogueRunner.portrait()` / `portrait_key()` give the
  key, "" for narration and any speaker who isn't a villager (the farmer, Tsuru), and the text
  box then shows no frame and starts the text and the name tag at the box's left edge
  (`TextBoxLayout.text_x`, `text_w`, `text_rect`, `name_x`; lines are still checked at the
  narrower width, so they fit both ways). Data: the four talk files and the three heart event
  dialogues now use `mood` (mapped from their faces); Hachiro's and Kota's hated gifts and
  Kota's "Fine!" in his first heart event are angry. Other dialogue files keep `face` (fewer
  merge conflicts with the sessions working on festivals and contests). README → Dialogue
  and Events describe it.
- Checked: all test scripts print `OK (0 failed)` (test_dialogue: mood parsing, the face
  alias, the say default, unknown moods fall back, no frame for narration / farmer / Tsuru,
  every mood in the data known and used, 5 different moods x 4 different villagers, layout
  with and without a portrait inside box and screen, text clear of the frame; test_talk: every
  talk line has the villager's portrait and a mood, loved gifts pleased, disliked / hated ones
  sad or angry; test_events: a say step's mood checked and passed on). Headless runs (title
  `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --map=town
  --time=14:30 --talk=tome`, `--demo --event=heart_kota`, `--demo --dialogue=bin_note`, the
  flat view with `--talk=tome`) printed no errors or warnings. Screenshots: `--demo --map=town
  --time=14:30 --talk=tome` (Tome's portrait in the frame, name tag with heart), `--demo
  --dialogue=bin_note` (the farmer's line: no frame, tag and text at the left edge) and the
  flat view `--talk=kota --hearts=3` (Kota under his straw hat); a contact sheet of all 20
  portraits looked right; `shots/` deleted.
- Left / next: real drawn portraits can replace the `portrait:` keys one by one; the other
  dialogue files can move from `face` to `mood` after the merges.

## 2026-11-01 — Mine art: ice, frost, frost stone, a soft flickering lantern in hand
Agent: Claude Code (claude-opus-5-5) · Commit: 0c1f08c
- Done: better pixel placeholders for the winter mine and the lantern, no rule changes, same
  keys. `mine:ice` is a chunk with a jagged lit top, a clear blue front lit from the left, air
  caught in it, a crack, rime round its foot and the frost stone's dark splinter frozen inside;
  `mine:frost` a see-through sheet with three rime feathers and glints; the frost stone icon
  (`shard` look) two faceted splinters rising apart from a frosted rock. `MineLight`'s lantern
  is no longer four hard rings: the falloff is cut into eight steps through a 4 x 4 ordered
  dither (a soft speckled edge that stays pixel art), the rim runs amber towards the middle's
  lantern colour, three unrelated waves flicker reach and brightness, and on a frozen floor
  (`cold`, set by `aim` from `MineFloor.frozen`) about 0.7 % of 3 x 3 px spots in the dark
  twinkle pale blue. Both views use the one shader on the one clock, so they match. The farmer
  carries the lantern down the mine: new key `mine:lantern` (7 x 11: iron loop, cap, glowing
  panes, flame), `PlaceholderArt.lantern_at(pose, frame)` puts its loop in the near hand (it
  swings with the walk; at the hip while holding something overhead or fishing); main_3d hangs
  a child Sprite3D there along the camera's axes like the rod tip, the flat view's Player draws
  it beside the body.
- Checked: all 24 test scripts print `OK (0 failed)` (test_mine has new checks: the lantern key's
  size, the stone dark inside the ice, frost mostly see-through, a bright warm flame, the
  lantern on the frame in every pose and swinging, the dithered shader, `cold` on a frozen floor
  only). Headless runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo
  --season=winter --mine=3`, and main_2d.tscn with the last) printed no errors or warnings.
  Screenshots of `--demo --season=winter --mine=3` and `--demo --mine=8` in both views before /
  after: the ring edges are gone, the lantern shows in the farmer's hand in both views, ice
  reads as ice. Pixel check (`python -I`, MineLight over plain white in a throwaway scene,
  radius 3.2 cells x 32 px, angular mean per 1 px of radius): the old shader's biggest step
  between neighbouring radii was 48.1 grey levels with 5 distinct greys in the edge band, the
  new one 5.1 with 9; centre (249, 224, 175) unchanged, rim warmer (150, 126, 94).
- Left / next: the lantern only lights the floor's multiply (it doesn't light rocks from one
  side); real art later replaces these keys.

## 2026-11-01 — The village record as a paper scroll
Agent: Claude Code (claude-opus-5-5) · Commit: 5c16326
- Done: ROADMAP "real art for the scroll". `EndingScreen` (village record and yearly page) is
  now a hanging scroll instead of the wood box: a wooden roller top and bottom (brass collars,
  lacquered knobs), washi paper between them (a seamless 32 x 32 fibre tile), cut edges a
  shade darker and the top roller's shadow. On open the paper unrolls downwards in 0.5 s
  (eased; the top roller stays, the bottom one rides under the paper, the paper clips its
  contents), then the rows come up as before; Enter / click during the unroll opens it fully
  with every row. "Village Record" and "N of M stars" moved onto the paper's top line, the
  heading under it. Stars are 7 x 7 ink stamps (vermilion with thin spots; unearned ones a
  faint unstamped star), a 14 x 14 red seal (a sprout carved in a square, our own mark) sits
  after "Written as: <title>" with the hint on the same line, every other row has a faint wash
  and a small arrow points from the first-day number to today's (hidden if there is no room).
  Art: `ui:scroll:<washi|roller_<w>|star_on|star_off|seal|arrow>` in PlaceholderArt
  (`_scroll_art`, `_scroll_roller`). The scroll is 372 x 241 on the 480 x 270 base screen, which
  the window scales by whole steps, so it fits every window size. No rule changes. README ->
  Ending describes the look.
- Checked: test_ending gains `_scroll`: the scroll fits the screen, opens rolled up, unrolls in
  <= 16 frames at 30 fps without shrinking, ends open with the bottom roller under the paper,
  rows wait for it, then rows / title / seal show and it stays open; every visible label and
  picture lies inside the paper's margins for the real record, every rank title (the seal
  clears the hint) and big numbers (9,999,999 G, 999 for counts), columns stay apart and gains
  clear the stars. All 24 test scripts print `OK (0 failed)`; headless runs (title, `--demo`,
  `--demo --map=town`, `--demo --mine=3`, `--demo --ending`, `--demo --ending=year`, `--demo
  --map=house --event=ending`) printed no errors or warnings. Screenshots of `--demo --ending`
  and `--demo --ending=year` (frame 119, plus frames 3 / 8 mid-unroll) and zoomed crops of the
  rollers, stars and seal checked; `shots/` deleted.
- Left / next: real art can replace the `ui:scroll:*` keys; a person could judge the unroll
  speed in play (no sound of its own; it keeps the row and coin sounds).

## 2026-11-01 — Merged ten branches: settings, water sounds, flat decorations, village snow, eat pose, rivals, river visits, gift lines, clinic, tool perk
Agent: Claude Code (claude-opus-5-5) · Commit: this commit
- Done: merged with `--no-ff`, one at a time, all tests after each: `claude/tool-l5-build-msg-a89fb6`
  (9461b44), `claude/settings-more-d823c2` (75c7f1b), `claude/river-ambient-b92ea4` (ac9d30c),
  `claude/flat-decor-34b3f5` (c827518), `claude/village-snow-cf3215` (130b5c9),
  `claude/eat-pose-612e16` (8df7399), `claude/contest-rivals-28449d` (574de93),
  `claude/river-visits-b88717` (0b9b3ee), `claude/gift-lines-c06e56` (272bf26),
  `claude/clinic-e95f60` (5b9bcbf). Six of the branches (settings-more, flat-decor,
  village-snow, eat-pose, contest-rivals, clinic) had WORKLOG.md with an empty line after every
  line (about 5,800 lines instead of 2,960); their WORKLOG was not taken: each merge kept
  main's file and put the branch's own entry on top with the extra empty lines dropped, and
  "this commit" in it became the branch hash. AGENTS.md conflicted twice on the screenshot
  flags (`--ui`, `--snow`, `--eat` all kept). The clinic merge conflicted in ROADMAP (the tool
  perk sentence and the clinic sentence both kept), data/foods.json `_about` (the herb tonic
  note and the eat `pose` note both kept), `Game.end_day` (`build_news` is set, then the farmer
  wakes at `go_to_spawn(wake_map, wake_spawn)`, the clinic's replacement for `go_home()`) and
  tests/test_villagers.gd (`_river_sunday()` and `_doctor()` both run). After it test_talk
  failed 5 checks: the gift-lines branch wants every villager to answer their loved keepsake
  and dishes in their own words, and the clinic's Dr. Yae had none; data/dialogue/talk_yae.json
  now has `gift_items` (keep:omamori, dish:love / like / neutral / dislike) and six lines of
  our own.
- Checked on merged main: all 24 test scripts print `OK (0 failed)`; headless runs (title
  `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --map=clinic`,
  `--demo --season=winter --map=town`, `--demo --map=river --time=10:00`,
  `res://scenes/main.tscn --quit-after 400`, `main_2d.tscn -- --demo --festival=moon_night`)
  printed no errors or warnings. Screenshots: `--demo --season=winter --map=town --snow=80`
  (snow on the village ground and both roofs, Kota and Tome by the spawn) and `--demo
  --festival=blossom_day --contest=potato --quit-after 120` (the rivals at the judges' table
  with their entries overhead, Tsuru's results box open); `shots/` deleted.
- Left / next: giving Yae the omamori sets `kept_yae_omamori` but the clinic map has no prop
  for it yet; why six worktrees wrote doubled WORKLOG lines is not known (all other files were
  fine); a person still has to listen to the water sounds and play a real year.

## 2026-11-01 — Clinic: a collapse wakes the farmer in Dr. Yae's clinic
Agent: Claude Code (claude-opus-5-5) · Commit: 5b9bcbf
- Done: a village clinic (DESIGN: a collapse wakes in the clinic at 12:00 next day with a fee).
  `data/maps/clinic.json` (Hinata Clinic, 9 x 7: tatami sick room with a futon that is only a
  bed, a byobu and an andon; medicine shelves, the doctor's counter, a water jar; spawns
  `start`, `bed`, `counter`, `keeper`), a 4 x 3 `village_house` east of the smithy in
  `town.json` at [31, 4] with its door at [33, 6] (`shop: clinic`), a path down to the road
  (x 33, rows 7-9) and the spawn `clinic`; far from the river lane (x 4) and clear of
  Hachiro's walk (x 30). Dr. Yae (`data/villagers/yae.json`, our own: white coat, teal sash,
  dark bun) keeps the counter 8:30-18:00, walks to the torii 13:00-13:50 on dry days, stays in
  on wet ones, and is away before and after; talk file `talk_yae.json`, speakers.json "Dr.
  Yae" with portrait colours, gifts (daikon, miso soup, mugwort tea, the omamori; no sweets,
  no stones). She is a villager with `"hearts": false` (new optional key, `Villagers.check`
  wants a bool): no birthday, heart events or place in the village record.
  `Villagers.friends()` is everyone else; `Game.ending_values` / `ending_record` and the
  heart-only loops of test_relationships (birthdays, birthday plans and weather, heart event
  rows and scenes, band 6 lines, the HUD tag) use it; the gift checks (mine find, dish, one
  keepsake loved) still cover her. Collapse: `body.json` collapse has `wake_map` "clinic",
  `wake_spawn` "bed"; `Game.knock_out` passes them to `end_day(wake_map, wake_spawn)` (which
  now ends with `go_to_spawn` instead of `go_home`; pass-out still wakes at home), counts the
  flag `clinic_visits` and sets `clinic_wake` (+ `clinic_free`); `triggers_clinic.json` plays
  `clinic_wake` on entering while that flag is set (`once: false`): Yae walks from her counter
  to the bed, says `wake_free` or `wake_fee` (`dialogue/clinic.json`), the flags are cleared,
  she goes back. The shop `clinic` (open 9-17 every day, keeper yae) sells the herb tonic
  (foods.json `herb_tonic`: stamina +20, fatigue -15, drink; price 0 there and `shop: false`
  so neither the stand nor the festival-stall rule picks it up, 400 G in shops.json).
- Balance (ours): the first collapse is free (`free_visits` 1: a warning, with Yae's line
  saying the next one is billed), every later one costs 80 G (`fee`, was a flat 30 G at home;
  DESIGN's source has 10 G), never more than the money in hand: about two turnips' worth on
  top of a lost morning, so it stings without wrecking a week. Wake at 12:00, half stamina and
  fatigue -40 stay as they were. The tonic at 400 G is dearer than amazake (220, stamina) and
  mugwort tea (350, half swing fatigue), as the one food that takes a big bite out of fatigue:
  a remedy for a hard week, roughly a collapse's fee plus a lost morning.
- Checked: all 24 test scripts print `OK (0 failed)` (new checks: test_body collapse in the
  field and in the mine wakes on the clinic bed spawn, free then paid, the flags, the trigger
  row, the event and its lines, pass-out still at home with no fee; test_maps the clinic door,
  house, path, spawns, bed without sleep, the door shut at 20:00 and open at 10:00;
  test_villagers Yae has no hearts, friends() leaves her out, keeper spot at noon in sun /
  rain / snow, away at 7:00 / 19:00, in at opening and closing, at the torii at 13:20 on a dry
  day). Headless runs (title `--quit-after 300`, `--demo`, `--demo --map=town`, `--demo
  --mine=3`, `--demo --map=clinic`, `--demo --map=town@clinic --time=13:10`,
  `res://scenes/main.tscn --quit-after 400`) printed no errors or warnings. Screenshots:
  `--demo --map=clinic --time=12:00` (bed, screen, lamp, shelves, Yae behind the counter),
  `--map=town@clinic --time=13:02` (the clinic house, Yae setting off) and `--map=clinic@bed
  --flags=clinic_wake,clinic_free --event=clinic_wake` (Yae at the bedside, the free line in
  the box); `shots/` deleted.
- Left / next: Yae shows a heart on her name tag like everyone (affection still counts for
  her); a real collapse in a play session not watched by a person; the merge with the
  villager / town.json branches will conflict in town.json and test_relationships.

## 2026-11-01 — Gift lines of their own; a loved keepsake kept at home
Agent: Claude Code (claude-opus-5-5) · Commit: 272bf26
- Done: (1) Villagers answer keepsakes and dishes in their own words. Each talk file
  (data/dialogue/talk_<id>.json) has an optional `gift_items` table: `keep:<id>` or
  `food:<recipe id>` names a line for that item, `dish:<reaction>` / `keepsake:<reaction>` a
  line for any dish (a food with a recipe in data/recipes.json; bought sweets aren't dishes) or
  keepsake met that way. `Talk.gift_line(id, item, reaction)` picks item, then kind+reaction,
  then the old `gift_<reaction>`; `Talk.check` refuses keys that aren't keepsakes, dishes or a
  known reaction, and lines that don't exist. `Game.talk_to` uses it (gift_again and
  gift_birthday stay first, so a birthday gift still gets the birthday answer). 41 entries, 51 lines,
  all written for this game: each villager answers the keepsake they love in two lines, the
  others they like / dislike in one, plus `keepsake:neutral`, `dish:love` .. `dish:dislike`
  and their two favourite dishes by name. (2) Giving a villager the keepsake they love sets
  the story flag `kept_<villager>_<keepsake>` (`Keepsakes.given_flag`), and a new story prop
  kind `keepsake` (`item`, optional `hang`) gated by it shows it in their home: Tome's omamori
  on a stand by her altar (tome_house [6,1]), Kota's clay rabbit beside the alcove (kota_house
  [5,1]), Sayo's wind chime hung by her window (sayo_house [4,1], not solid) and Hachiro's
  daruma between forge and tool rack (smithy [4,1]). StoryView draws the keepsake's own icon
  on a small stand (or hung) in the flat view; StoryProps builds a wooden stand with the icon
  sprite on it (or hangs it from a short cord) in 3D. A keepsake only liked sets nothing.
  README (Villagers, Keepsakes) explains both.
- Checked: test_talk (gift_items format errors refused, Talk.gift_line picks and fallbacks,
  every named line opens, each villager has a line for their loved keepsake and the four dish
  reactions) and test_relationships (the two answers that changed: Sayo's wind chime now
  `gift_wind_chime`, her fish dish `gift_dish_dislike`; each home has its keepsake only with
  its flag, spawns stay free, the icon key, built in 3D and listed for the flat view; on the
  real Game a liked fan sets no flag, the loved rabbit sets `kept_kota_clay_rabbit`, shows in
  the cached map and comes back with a save). All 24 test scripts print `OK (0 failed)` (the
  worktree's class cache needed `--import` first: WeatherView from the last merge was missing,
  which hung test_view2d once). Headless runs (title `--quit-after 300`, `--demo`, `--demo
  --map=town`, `--demo --mine=3`, `--demo --map=smithy --flags=kept_hachiro_daruma`, `--demo
  --map=sayo_house --flags=kept_sayo_wind_chime`) printed no errors or warnings. Screenshots:
  `--demo --map=tome_house --flags=kept_tome_omamori` (the green charm on its stand between
  altar and chest), `--map=sayo_house --flags=kept_sayo_wind_chime` (the chime hanging by the
  window) and the flat view `main_2d.tscn -- --demo --map=kota_house
  --flags=kept_kota_clay_rabbit` (the rabbit on its stand); `shots/` deleted.
- Left / next: festival ribbons still answer with the plain lines (neutral to all); a
  keepsake given before this change sets no flag (no save has one yet).

## 2026-11-01 — Villagers at the river: Hachiro and Kota fish it on fair Sundays
Agent: Claude Code (claude-opus-5-5) · Commit: 0b9b3ee
- Done: Hachiro's Sunday moved from the village pond to the river: a fair Sunday (rule
  `weekday sun, weather sunny`) he walks the road west and down the lane behind Kota's house
  (town [4,21]), is on the river map from 9:30 at [10,5] facing the water, rod out (45 min,
  a 5 min stretch, a step to [11,5], 30 min, back), and leaves at 15:00 along the row above
  (so he doesn't walk through Kota), smithy by 15:45; a wet Sunday is a new `sunday_in` plan
  at the anvil (the smithy is shut Sundays, so he isn't at the counter spot). Kota has a
  `river` plan on Sundays that aren't wet (after his festival / birthday / stays_in rules, so
  summer Sundays too): the usual morning, then 14:10-17:00 on the shore at [6,5] / [7,5],
  home by 17:30. New day plan step `{"fish": minutes}` (DayPlan legs carry `fish`, `where`
  gives `fishing` / `fished`; a talk sets `fishing` false); `Villagers.sprite_key` gives pose
  `fish`, frame by `fish_frame` (the tip dips one minute in every `fish_bob_minutes`, 6, in
  _common.json; ours, by eye); PlaceholderArt draws `villager:<id>:<side>:fish:<0|1>`: a thin
  rod from the hand out to the sprite's right edge, the line hanging from the tip (both views
  use the same key). Talk picks have a new `map` condition (map ids; `Game.talk_to` passes
  the map the villager stands on): Hachiro and Kota each have three `river_` lines, picked at
  the river before their band lines (after `again` / `birthday` / dear). Game takes
  `--day=N` (day of the season; 7 = the first Sunday). Gift lists and keepsakes untouched.
- Checked: test_villagers (fish step, the river Sunday times and places, no walking into
  each other, wet / Monday / summer, the fish frames, both views on the river at 14:30 showing
  both in place with the fish pose) and test_talk (the `map` condition refused for an unknown
  map, river picks, E at the river opens a river line) print `OK (0 failed)`, as do all 24
  test scripts. Headless runs (title `--quit-after 300`, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, `--demo --day=7 --map=river --time=10:00`) printed no errors or warnings.
  Screenshot `--demo --day=7 --weather=sunny --map=river@shore --time=14:45`: Kota (straw hat)
  and Hachiro (headband) on the gravel shore, rods and lines visible; `shots/` deleted.
- Left / next: the rod is small inside the 16 px sprite (the line ends on the gravel, not in
  the water); a wider fish frame would read better once real art comes. Tome and Sayo have no
  river visits.

## 2026-11-01 — Contest rivals walk up to the judges' table
Agent: Claude Code (claude-opus-5-5) · Commit: 574de93
- Done: the four contest result events (`data/events/contest_*.json`) now bring the rolled
  rivals on stage: each starts where their festival plan has them (`"at": "plan"`; one whose
  plan is elsewhere comes in beside the farmer), walks to a cell in front of the judges' table
  beside the farmer with an entry of the contest's kind overhead, faces the table, stands there
  while the result line is read, then walks back to their plan's spot and leaves the stage (the
  plan takes over again). Entries (ours): Blossom Day Kota cucumber, Tome turnip, Sayo potato;
  Lantern Night Hachiro namazu, Kota ayu, Tome funa; Moon Night Sayo milk_good, Tome egg_best,
  Kota wool; Year's Turn Hachiro kogane, Kota suisho, Sayo meno. Three small EventRunner
  additions: actor `holds` (an item carried overhead, kept in the actor's dict so
  Villagers.actors passes it to the views; "" puts it away), actor `meanwhile` (with `to`: the
  walk goes on in the background while the next steps play, so the rivals walk together) and
  wait `walkers` (also waits until those walks have arrived; some festival plans are 10+ cells
  from the table). VillagerSprites (3D) and VillagerView (2D) draw `holds` on top of the head
  with the item art the farmer uses (`PlaceholderArt.world_item_key`). Festivals' data check
  now only checks that a contest's event file exists: reading it in full checks its actor
  villagers, whose rules ask for the festivals being loaded (a load cycle that gave "unknown
  villager"); test_festivals reads every contest event in full instead.
- Checked: test_festivals `_rivals` plays each contest event with the real festival plans at
  opening + 30 min: all three rivals stand still on distinct non-prop cells in the farmer's row
  facing up when the result line opens, each holds an item of the contest's kind with a sell
  price, they are back on their plan spots before leaving, and the stage is empty at the end;
  bad `holds` / `meanwhile` without `to` are refused; both views show an actor's entry and drop
  it after the event. All 24 test scripts print
  `OK (0 failed)`; headless runs (title `--quit-after 300`, `--demo`, `--demo --map=town`,
  `--demo --mine=3`, `--demo --festival=blossom_day --contest=potato`, `--demo
  --festival=years_turn --contest=mine:hisui`) printed no errors or warnings. Screenshot `--demo --festival=blossom_day
  --contest=potato --quit-after 120`: Kota with the cucumber, the farmer, Tome with the turnip
  and Sayo with the potato in front of the table, the results box open; `shots/` deleted.
- Left / next: the entries are not set down on the table; the rivals walk through props on
  the way (scripted walks don't collide).

## 2026-11-01 — Eat / drink pose
Agent: Claude Code (claude-opus-5-5) · Commit: 8df7399
- Done: anything eaten (the food slot, F in the rucksack, a raw item overhead) starts a short
  pose in `Game.eat_item`: `Game.eat_pose` ("eat" / "drink") and `eat_left` seconds from the
  new data/foods.json `pose` (eat 1.2 s = three bites at FarmerAnim.EAT_FPS 5, drink 1.0 s =
  one sip a second at DRINK_FPS 2; chosen to feel like a quick snack, not a wait). It counts
  down in `Game._process` only while no menu / text box / event is open, so F in the rucksack
  plays it once the rucksack closes; not saved, cleared by new_game. Player stands still with
  no tool / interact while `Game.eating()` (both views use Player). FarmerAnim takes
  `eating` (after fishing and holding, before tired). Placeholder frames `player:<front|back>:
  eat:<0|1>` (bite: a morsel at the lips; chew: the hand lower, body dipped a pixel) and
  `drink:<0|1>` (cup at the lips, tipped up), from `_MOUTH_HANDS` in placeholder_art.gd; the
  back view hides what's in the hand. The flat view draws a hand and a morsel / cup at the face,
  bobbing at the same rates. The existing eat / drink sounds play as before (no new sfx key).
  New CLI flag `--eat` / `--eat=drink` (pose kept going, for screenshots), in AGENTS.md.
- Checked: test_food gained the pose checks (starts with its length, nothing eaten = no pose,
  waits while a text box is open, ends after its time, the Player neither steps nor emits an
  action during it and does both after, FarmerAnim keys and priorities, the frames drawn and
  distinct from idle). All 24 test scripts print `OK (0 failed)` (after `--import`: this
  worktree's class cache lacked WeatherView, which first made main_2d fail to parse in the
  festivals / view2d runs). Smoke runs (title, `--demo`, `--demo --map=town`, `--demo
  --mine=3`, `--demo --eat=drink`) printed no errors. Screenshots `--demo --eat` (frames 16 bite
  / 19 chew), `--demo --eat=drink` and `main_2d.tscn -- --demo --eat` looked at zoomed in;
  `shots/` deleted.
- Left / next: real art for the poses; the cup is pale against light walls.

## 2026-11-01 — Snow lies in the village too (outdoor maps and their roofs, both views)
Agent: Claude Code (claude-opus-5-5) · Commit: 130b5c9
- Done: Game.snow_cover now whitens every outdoor map from data/maps, not only the farm.
  SnowLayer gets `map_hold` / `map_mask_image` (a map cell holds snow by its tile kind from
  data/snow_cover.json "ground"; new kinds gravel 0.75, scree 0.7, rock_wall 0.5; water 0) and
  `map_has_snow` (false for sheltered maps: rooms, coop, barn, shops and the mine floors, and
  for the farm, which keeps its own mask). 3D: MapWorld lays the tile picture through the
  snow ground shader on outdoor maps and adds snow tops on the village house roofs, the
  hokora roof, the torii's top beam, the stone lantern caps and the rock (the mine
  entrance); its `_snow_top` does nothing under a roof. 2D: MapView draws its props and doors
  on an `_objects` child so `show_snow` can put the ground snow between the tiles and the
  props (as FarmView does), plus a second overlay over the props for the roofs seen from
  above (`SnowLayer.roof_mask_image`, data/snow_cover.json "roofs": village_house and hokora
  hold 0.7, so the brown shows through; the front row of each house stays bare, so its wall
  and door read). main_2d calls show_snow / set_snow for map views too (and on the new day).
  New launch flag `--snow=N` (0..100) sets the snow lying for screenshots (AGENTS.md).
- Checked: new `_map_snow` checks in tests/test_maps.gd (hold values for grass / path /
  gravel / pond, which maps get snow and which don't, room mask empty, mask size, roof mask
  over houses but not their front row or the road, the 2D sprites' order and cover, no snow
  sprites indoors, the 3D village's shader materials take the cover, none in the mine floor
  or the house). All 24 test scripts printed `OK (0 failed)` (before the last roof-mask tweak
  and `--snow` flag; test_maps, test_weather and test_view2d were re-run after it: `OK (0
  failed)`). Headless smoke runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`,
  `--demo --season=winter` on town / river / mine / house, the flat view on town and house
  with `--snow=80`) printed no errors or warnings. Screenshots: 3D `--demo --season=winter
  --map=town --snow=80` (white ground with path showing through, snow on the roofs), the flat
  view `--map=town@sayo --snow=60` (snowy roofs, brown house fronts and doors, the pond bare),
  3D `--map=mine --snow=70` (snow on the rock tops and lantern cap); `shots/` deleted.
- Left / next: pines and festival props take no snow; on day 1 of winter (`--season=winter`
  alone) the cover is still 0 until it snows, as on the farm.

## 2026-11-01 — Festival decorations drawn in the flat view
Agent: Claude Code (claude-opus-5-5) · Commit: c827518
- Done: `scenes/main_2d.tscn`'s festival decorations were flat boxes; now each is a pixel
  picture of the 3D prop. PlaceholderArt has `festival:<kind>:<w>x<h>[:<cloth>]` keys for all
  twelve kinds of data/festivals.json (sakura, picnic / red mat, stall, judges' table, lantern
  string, drum stage, moon offering, pampas, paper lantern, kadomatsu, bonfire), drawn front-on
  from the 3D shapes in FestivalProps: a prop point (x, y up, z) lands at anchor + (x, z - y) * 16
  px (`festival_size` / `festival_anchor`). A stall's roof and curtain take its `cloth`. FestivalView
  (`art_key`, `ground_mid`, `art_origin`) stands each picture on the middle of its cells,
  sorted so nearer ones overlap farther ones; the stalls' wares sit on the counter, clear of the
  corner lantern. The lights for FestivalGlow move with the same projection (`glow_pos`: x,
  z - y), so each glow sits on its drawn lantern / drum / fire instead of on the ground.
  3D props and festival rules are unchanged.
- Checked: test_festivals `_flat_art` (every prop of the four festivals has its own key and
  picture size, no magenta, stands on its ground row, its anchor lands on the 3D prop's middle,
  and every 3D light lands on an opaque non-outline pixel of a picture: 1 / 41 / 4 / 5 lights);
  with `glow_pos` put back on the ground as a test of the test, that check failed for all four
  (0 / 1, 3 / 41, 2 / 4, 3 / 5). test_view2d: Lantern Night's glows equal `glow_pos` of the
  3D lights and sit above their cells, the art keys are the festival keys. All 24 test scripts
  print `OK (0 failed)`; headless runs (title, `--demo`, `--demo --map=town`, `--demo --mine=3`,
  `main_2d.tscn -- --demo --festival=<each of the four>`) printed no errors or warnings.
  Screenshots of the flat view at each festival: cherry trees with petals and picnic mats,
  lantern strings on poles glowing at night over the cloth-roofed stalls and the drum stage,
  the moon offering between pampas vases and two paper lanterns, the kadomatsu, the bonfire
  and the white / red Year's Turn stalls; glows on the lamps. `shots/` deleted.
- Left / next: the pictures are drawn under the characters (like StoryView's props), so the
  farmer walking behind a tall stall is drawn over it; y-sorting with the sprites would be a
  separate change.

## 2026-11-01 — River and pond water ambient
Agent: Claude Code (claude-opus-5-5) · Commit: ac9d30c
- Done: two new synthesized loops in data/sfx.json: `amb_river` (6 s: a band of white noise
  250-2200 Hz swelling slowly, a brown-noise rumble, 240 small filtered clicks for the
  bubbling, 30 deeper ones, a faint high sparkle; -15 dB) and `amb_pond` (6 s: slow brown and
  mid-band swells at 0.5 Hz like small waves on a bank, a few soft plops; -22 dB). Two new
  optional keys on the ambient rules, read by `AmbientPicker.pick` (now also given the map id
  and the farmer's distance to water): `maps` (map ids the rule is for) and `near` (cells: full
  level up to a cell from water, falling to 0 at `near` cells, `AmbientPicker.near_level`).
  `Sfx.water_distance()` measures from `Game.maps.pos` to the nearest edge of a water cell (the
  farm's pond cells in FarmGrid, `water` tiles on other maps; cached per map id; -1 with none).
  Rules: river on `river` at 0.8 in sunny / snow, 0.6 in rain (under the rain loop); pond on
  `farm` and `town`, near 6, 0.6, sunny / snow. Neither plays in a storm or blizzard (the rain
  and wind loops cover them) nor indoors (no `places`, so outdoor only). The river is still
  `ambient: outdoor` in its map file, so birds / rain / crickets rules work there as before;
  no map file changed. Levels are ours: the river about as loud as the rain, the pond a
  background layer you notice only by the bank. Rain / storm rules unchanged.
- Checked: test_audio has 20 new checks (river on its map in sunny / snow / rain, softer under
  rain, gone in storm and blizzard, not indoors / in the village / on the farm / without a map;
  the pond by the water, fainter at 4 cells, gone at 8 and without water, the village pond,
  not in a storm / indoors; near_level; Sfx.water_distance beside the pond, at the house, on
  the river shore, none in the store). All 24 test scripts print `OK (0 failed)` (the worktree
  needed `--import` first: its class cache predated the WeatherView merge). Headless smoke runs
  (title, `--demo`, `--map=town`, `--mine=3`, `--map=river`, `--map=river --weather=storm`,
  `--fishing`, `--map=house`) print no errors or warnings. Recorded `--demo --map=river
  --weather=sunny --movie-audio` (10 s, 48 kHz stereo 32-bit) and the same on the farm; a
  python -I numpy check: river rms 0.0993 / 0.0843 / 0.1078 at 2 / 4 / 6 s, and the river
  minus the farm recording (same music, sample-aligned) rms 0.0022 in the first second,
  0.0112 / 0.0143 / 0.0124 / 0.0141 at 2 / 4 / 6 / 8 s, i.e. the river loop fading in over
  its 4 s and then steady about 17 dB under the music. These Movie Maker runs print
  `WARNING: N ObjectDB instances were leaked at exit` (4 at the river, 2 on the farm); the old
  code prints the same (2 on the river map, 4 on the farm in rain), so it comes from loops
  still playing when a `--movie-audio` run quits, not from this change. `shots/` deleted.
- Left / next: a person still has to listen to both loops (and the levels against the music).

## 2026-11-01 — Settings 2: FPS limit, UI size, window sizes that fit, triggers / right stick
Agent: Claude Code (claude-opus-5-5) · Commit: 75c7f1b
- Done: the open points of "Settings: display, v-sync...". (1) FPS limit (Off / 30 / 60 / 120 /
  144, `values` in data/settings.json) → `Game.max_fps` and `Engine.max_fps`. (2) UI size
  (100% / 125% / 150%) → `Game.ui_scale`; new `UiScale` (scripts/ui/ui_scale.gd) grows a
  piece about the pivot that splits the screen the way its free space is split (a centred box
  grows from its middle, one by an edge keeps hugging it), only as far as it fits, in 25%
  steps. The HUD grows per corner group (`HudLayout.GROUPS`, `scaled_box`, live on
  settings_changed); the pause menu shows fewer rows (`PauseScreen.visible_rows`: 15 / 13 /
  10) and rebuilds the moment the size changes; the rucksack, shop, cooking and record screens
  scale their CanvasLayer; the text box goes through the same rule but at 472 px wide it has
  no room, so it stays 100% (said in README). `-- --ui=150%` overrides it for one run
  (screenshots), not saved. VISIBLE went from 14 to 15 so the settings page (now 15 rows)
  still fits at 100% without scrolling. (3) Window size: `Game.too_big_windows()` lists the
  sizes that don't fit the screen; `Settings.hidden` keeps them out of the row (adjust steps
  over them), `Settings.shown()` / `value_text` / `option_value` give the biggest size that
  fits for a saved one that doesn't (it stays saved, so a bigger screen gets it back); the
  first option always stays. (4) Pad slots take axes: `Controls.PAD_AXES` (left_trigger,
  right_trigger, rs_up / down / left / right) as codes from `AXIS_BASE` (1000 + axis * 2 + side),
  names LT / RT / RS-up... in data/controls.json `pad_names`, saved by id under `pad`, put in
  the InputMap as InputEventJoypadMotion; the left stick can't be bound. The controls page
  takes a trigger pull or right-stick push past 0.6 (`Controls.motion_code`) while a pad
  slot listens. None is on an action by default. Reset to defaults covers all of it.
  Reasoning: 144 for the common fast screens; 150% is the most the HUD corners take without
  meeting on 480 x 270; 0.6 so a resting or drifting stick doesn't bind.
- Checked: `tests/test_menu.gd` prints `test_menu: OK (0 failed)` with new checks (FPS and UI
  size defaults, steps, values, broken files, reset, Game fields and Engine.max_fps; hidden
  window sizes for 1080p / 1440p / a tiny screen, the shown size, stepping over, the menu row;
  UiScale pivot / fit / steps, HUD corners on screen and apart at every size, the live HUD
  boxes at 150% and back, pause rows fit; axis codes, names, binding and swaps, the left stick
  refused, motion codes, the input map, the file round trip, an unknown id refused, the menu
  taking a trigger). All 24 test scripts printed `OK (0 failed)`, except test_villagers once
  printed `test_villagers: FAILED (1 failed)` in the full run; five reruns printed `OK (0
  failed)` (a random roll, nothing it touches changed here). Headless `--quit-after 300`
  (title, `--demo`, `--demo --map=town`, `--demo --mine=3`, `--demo --pause=settings`,
  `--demo --pause=controls --ui=150%`, `--demo --ui=150% --dialogue=bin_note`) and
  `res://scenes/main.tscn --quit-after 400` printed no errors or warnings. Movie Maker frames
  looked at: `--demo --pause=settings` (all 15 rows, no scroll bar), the same at `--ui=150%`
  (bigger box, scroll bar), `--pause=controls --ui=150%` (fills the picture, three columns),
  `--demo --ui=150% --hold` (HUD corners grown, hand box beside the tools); `shots/` deleted.
- Left / next: the text box can't grow on a 480 px picture (it would need a narrower layout
  or the UI drawn at window resolution); triggers / right stick not tried on a real pad;
  the window-size hiding not seen on a screen smaller than 4x.

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
