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
The farm pieces are done in this style: the house (a thick thatched kayabuki roof since 2026-11-03, plaster and timber, engawa,
shoji), a low bamboo lattice fence with rope ties, the seed stand as a roadside stall with
a board roof and an indigo noren, and a lidded cedar shipping bin with a straw rope.

## Next up
[x] test_child help flake (2026-11-10): the nightly neglect roll (1 in 8) could drop the child below band 5 before the morning help; the test now counts a talk today before `end_day()`, 7 failures in 40 runs before, see WORKLOG.
[x] Portraits, refined (2026-11-10): every text box portrait (each villager in each mood, the child at crawler, toddler and child, the generic face: keys) in the figures' refined look: three tones per material lit from the upper left, deep-tone part lines and a darker rim instead of the black outline, eyes and mouth in their own colours; keys, size, moods and colours kept (PortraitArt, data/portrait_art.json; test_dialogue `_refined_portraits`). Next for the look: the baby's cradle and carry pictures are still the plain drawing.
[x] test_inventory exit leak (2026-11-10): `_arms_full()` freed no Game node; `g.free()` added, the suite quits with no ERROR line.
[x] Nana's scarf on a loaded save (2026-11-10): Game.from_dict applies DateFlags for the loaded date, so a save from fall 20 on gets nana_scarf at the load, not at the next morning; test_save covers the load (before and after fall 19) and the morning through Game.end_day.
[x] The baby's cradle and carry pictures, refined (2026-11-10): the bamboo cradle (three tones of cane, bound rim, rockers, pad, quilt; the weave in the cane's deep tone), the baby held and the crawler carried in the same refined pass, light from the upper left, deep-tone rim instead of the black outline; every key, size, look (empty / asleep / awake / cry) and the child's colours kept (BabyArt.refine, data/villager_art.json "baby"; test_child checks no black outline, several tones, sizes).
[x] Villager art, refined (2026-11-10): every villager's frames and the farmer's child (crawler, toddler, child) in the farmer's refined pass: three tones per material lit from the upper left, deep-tone part lines and a darker rim instead of the black outline, their own pieces (Ren's mailbag, the hammer, the kimono's tabi, the hat band) toned too; every look, key, pose and size kept, both views (FigureArt, data/villager_art.json; test_villagers `_villager_art`; the farmer's hashes in test_title unchanged). The baby's cradle and carry pictures followed (next entry); the portraits are still the plain drawing.
[x] Nana's scarf from the morning after (2026-11-10): data/date_flags.json and DateFlags (pure) set nana_scarf on each morning from fall 20 on, in any later year, so the jizo's scarf no longer needs the farmer in Minamino on fall 19 (the fall 19 trigger stays); Game's morning calls it; test_maps `_nana_scarf`.
[x] Kiku's persimmons to pick (2026-11-10): the fruiting tree (third year on, fall) gives two ripe persimmons a day (`wild:persimmon`, 30 G, eaten raw, Kiku likes it) to the action button facing it, overhead or into the rucksack; the third press says the rest are for the birds; back in the morning, saved (`forage.scion`), the drawn crown loses half its fruit per pick in both views (data/scion.json `pick`; test_forage `_persimmon`, test_maps).
[x] Farmer art, refined (2026-11-10): the farmer's frames in three tones per material lit from the upper left, deep-tone part lines and a darker rim instead of the black outline, split-toe jika-tabi with a pale sole, a woven hip basket; every look, key and pose kept, both views (FigureArt refined pass, data/farmer_art.json; test_farm `_farmer_art`, test_title's hashes). The villagers followed the same day (Villager art, refined).
[x] Hands full with the dog (2026-11-09): Game.arms_full() is also true while the dog is held in the arms, so the rucksack and chest menus refuse the hand slot with "Your hands are full."; holding() now is held or arms_full(); test_inventory `_arms_full` covers the dog.
[x] Nana's birthday scarf (2026-11-09): the silent event nana_scarf sets the flag of the same name once the farmer is in Minamino on fall 19 from 9:40 (triggers_minamino.json); the jizo by the lane at (5, 18) then wears a red scarf, the `jizo_scarf` story prop in both views (OutdoorProps.jizo_scarf, StoryView, `story:jizo_scarf`), with an examine line in English and Thai; test_maps `_nana_scarf`.
[x] Kiku's persimmon grows (2026-11-09): the band 6 scene keeps the planting day (event `date` step, kiku_scion_day); Scion and data/scion.json draw a sapling the first year, a young tree the second and a fruiting tree from the third (persimmons in fall, one left in winter, snow on bare branches), both views; an old save is planted the day it loads; `--scion=<stage>` (test_maps, test_events, test_save).
[x] Hands full with the baby or the crawler (2026-11-09): the rucksack and chest menus never put an item in the hand slot while Game.arms_full() (hold, choose; a carried stack too), with the existing "Your hands are full." line; test_inventory `_arms_full`.
[x] Kiku's persimmon sapling (2026-11-09): the twig planted by the farmhouse door or at the field's edge (kiku_scion door / field) is a story prop on the farm in both views, a sapling with a stake and straw tie drawn by season (test_maps).
[x] Nana's keepsakes in the world (2026-11-09): her band 3 answer sets nana_captain (pond / jar); with jar, Captain's jar stands by Shige's door in Minamino until her band 6 scene; then Captain the frog sits in the ditch behind Shige's beds (heart_nana_6) and her sky map on a bedsheet hangs on the front of Shige's new little hen barn (nana_sky), its stars by her answers (nana_beside, nana_star; StoryView.sky_map_key); the hen barn and the ditch are new permanent Minamino props (OutdoorProps.hen_barn / ditch), story props in both views (PlaceholderArt story:captain_jar, story:frog, story:sky_map:<steady|beside>:<near|field>; test_maps _nana_props). Still open: the jizo's new red scarf Nana ties on her birthday changes nothing in the world (no flag for it yet).
[x] Kiku's band 6 scene (2026-11-09): heart_kiku_6 (a twig cut from the oldest persimmon tree for the farmer to plant; a line of its own for the band 5 answer, which now sets kiku_miss / kiku_glad; the farmer picks the farmhouse door or the field's edge, kiku_scion = door / field; sets heart_kiku_6 and kiku_graft), rows in three trigger tables, three dear_ talk lines, the music rule, Thai, tests. Every villager with hearts now has all three scenes.
[x] A portrait for the child (2026-11-09): the text box shows the little one's own face when the farmer talks to them (crawler, toddler, child; `portrait:child:<mood>:<stage>:<style>:<skin>:<hair>:<top>`, Child.portrait_key, PlaceholderArt._child_portrait): the spouse's hair colour and style at that stage, the skin between the parents, the small happi; a rounder face with cheeks for the crawler and toddler, the young villagers' face for the child stage; no portrait for the baby; the name tag shows their name (test_child).
[x] Shige's band 6 scene (2026-11-08): heart_shige_6 (the pumpkin vines by the fence came up, Nana cried over the first one; a line of its own for the band 5 answer, which now sets shige_fence / shige_share; the farmer picks the pot or the tin, shige_pumpkin; sets heart_shige_6 and shige_vine), rows in triggers_minamino / shige_house / town, three dear_ talk lines, music rule, Thai, tests. Every villager with hearts has all three scenes now.
[x] The child, step 1 (2026-11-08): data/child.json and Child (pure rules): the news 30 days after the wedding while the spouse's hearts stay at band 6 and not on a festival day, the birth 30 days after the news, the stage by days since the birth (baby 0-29, crawler 30-59, toddler 60-119, child from 120), the look from the parents (the spouse's hair, the skin between the two), each spouse's three names, the save (child_news, child_born, child_name flags, the child's hearts under id "child"); tests. (docs/DESIGN.md → ลูก)
[x] The child, step 2 (2026-11-08): the news event and the birth event with the name chosen from the spouse's three, for all eight spouses, English and Thai (child_news_<id> / child_birth_<id>, data/dialogue/child.json, Child.day_start sets the due flags each morning, the event's child step sets child_news / child_born / child_name; test_child).
[x] The child, step 3 (2026-11-08): the baby in a bamboo cradle in the second room (house.json cradle prop gated by child_stage "baby", Child.sync_stage; CradleLayer in 3D, CradleView in the flat view, PlaceholderArt child:cradle / child:held in the child's colours), E looks in (data/child.json cradle.times: asleep, crying before dawn, awake, a nap; English and Thai), the tool button lifts the baby into the hold pose, either button at the cradle lays them back, never thrown or set down, the door waits, map changes, the night and a loaded save put the baby back (BabyActions, Game.baby_held; `--baby`, `--baby=held`; test_child, test_maps, test_view2d).
[x] The child, step 4 (2026-11-08): crawler and toddler figures (FigureArt.draw_little: on hands and knees, the toddler build; `child:figure:...`), day plans in data/child.json `days` (the crawler on the mat at the spouse's side or crawling about the second room; the toddler beside the spouse at home and in the yard by the dog's kennel on dry days, in on wet and festival days; in bed from 20:00), shown by Villagers under the id `child` in both views, talk (talk_child.json picked by stage, the name put in, English and Thai) and gifts from the toddler on (data/child.json gifts), the child's hearts on the name tag (from band 3, never below it, the nightly loss included); `--child=<stage>`, `--talk=child` (test_child).
[x] The child, step 5 (2026-11-09): the child stage's own day plans in data/child.json days.child (beside the spouse at home, the yard by the kennel from 7:00, off by the gate at 9:35, from 10:00 at the spouse's side wherever their work takes them and home together, Mio's after her ferry; a festival day with them all day; in on wet days; Child.place, free cells by with.tries), the figure in the child build with the spouse's long hair and headband, child_ talk lines (the yard, the weeds, festivals, rain, one per spouse's work), the morning help (up to two weeds pulled at band 5 on sunny days, Child.help / FarmGrid.pull_weeds, told after the spouse's line, flag help_weeds), the village record's line with the child's name and the yearly page with their stage (Ending.child_part), English and Thai (test_child, test_ending).
[x] Holding the crawler (2026-11-09): the tool button facing the crawler lifts them into the hold pose (PlaceholderArt child:carry, 16 x 14 in the child's colours), either button sets them down on the free cell in front or back where they were lifted, never thrown or left as an item; set down they sit there for data/child.json hold.stay_minutes, then the day plan has them again; the door waits, a map change, the night and a load put them back to the plan (Child.carried, Game.lift_crawler / set_crawler_down, BabyActions; both views; `--child=crawler:held`; test_child, test_view2d). The toddler and the child are not lifted. Next for the child: the portrait in the text box.
[x] The child's rules written (2026-11-08): docs/DESIGN.md → ลูก: one child, gender-neutral, the news and the birth, names chosen from the spouse's list, four stages by days, hearts, the morning help, the record, the save, what is left out on purpose, and the five build steps.
[x] Married spouses keep the farmhouse on their special days (2026-11-08): each of the eight has married festival plans (from the farmhouse along the farm road into the village for the festival's hours, home after; Sayo keeps the store from her married mornings) and a married birthday plan (the day at their favourite spot, home by evening), Ren a married Sunday off, all listed before the single plans so they win (test_relationships _spouse_special_days).
[x] Shino's noren (2026-11-08): the noren she dyed in her band 6 scene (shino_noren) now hangs over the farmhouse door, the field's rows or her wildflowers by the farmer's answer, and her own new one with the dye house's mark (a ring round an indigo leaf) over her door, swaying in the wind in 3D, drawn in the flat view (a `noren` story prop, PlaceholderArt story:noren_<rows|flowers|shino>); her drying rack stays in on Sundays and her birthday (DyeCloth rest_weekdays, keeper; test_maps _shino_noren, _dye_cloth).
[x] Mio poles the ferry across (2026-11-08): a {"ferry": minutes} day plan step (data/ferry.json, FerryRun): at 9:30 on her fine days (usual and married plans) she steps down the landing into the stern, poles the old boat across to the far bank in a new pole pose, waits, poles back and steps off, tied up again by about 10:05; the boat, its painted name and her figure move together in both views (OutdoorProps.ferry_boat's BoatRide, FerryView), the spare pole in her hands; not in winter, nor on wet days (test_villagers _ferry_crossing, test_maps _ferry_boat).
[x] Shino's cloth drying by the vats (2026-11-08): a bamboo rack west of her vats in Minamino (cloth_rack, 0..1, 15..17), three poles with a length of indigo over each, the palest by the vats and the darkest last, swaying in the day's wind (OutdoorProps.cloth_rack in 3D on the world's Sway, DyeClothView in the flat view, the same shear); out 7:00-17:00 on dry days, taken in at night and in rain, storm, snow and blizzard, the bare frame left (DyeCloth; test_maps _dye_cloth).
[x] Mio's boat at the ferry landing (2026-11-08): her plank landing and her father's old ferry boat on the river below her hut (OutdoorProps.ferry_boat / landing in 3D, MapView._draw_river_wood in the flat view; spawn river@ferry), and once she has named it (mio_boat) the name painted on its side: her father's red dragon or the new name's fish (story:boat_father / boat_new, a boat_name story prop; test_maps _ferry_boat).
[x] Ren's mailbag and the delivery (2026-11-08): a canvas mailbag on his figure (look.bag, FigureArt._bag: the strap across the body, the bag at the hip, in both views), and a new day plan step {"post": minutes}: at each door of his round the post pose holds a letter up to the door, then slips it in with a soft paper sound (Sfx letter_post) when the farmer is on that map (DayPlan, Villagers.post_frame, data/villagers/_common.json post_hold_minutes; test_villagers _post_step).
[x] Portrait hair styles in the text box (2026-11-08): four portrait-only styles (hime, ponytail, braid, low knot; PlaceholderArt.PORTRAIT_HAIR), chosen by speakers.json `portrait_hair` without changing the figures: Haru a braid, Mio a ponytail, Kaede a hime cut, Shino a low knot, so the six women who can marry each have their own (Sayo's long hair and Fumi's bun stay); the bun's side hair now covers the ears (test_dialogue).
[x] The flat view takes the world's light on its sprites (2026-11-08): the farmer, villagers, animals, the dog, crops and plants, items, forage and story props take the sun's share by the clock and the warm night lift by lit windows, lanterns and festival lights, by SpriteLight's own rules, drawn as a modulate under the night tint (FlatLight, data/light.json sprites.lift.flat_floor; test_view2d `_sprite_light`; ART_DIRECTION section 3).
[x] Puddles in rain (2026-11-08): small puddles gather on the bare ground of the outdoor maps' paths and gravel (and the farm's doorsteps) in rain and storm, growing over the first game hour and drying over two after a rainy day; none in snow, with snow lying, on grass, tilled plots, water, buildings, indoors or in the mine; a dark wet tone with a soft sky reflection and rain rings, in both views (PuddleRules, data/puddles.json, PuddleLayer, PuddleView; test_puddles; ART_DIRECTION section 2).
[x] Seasonal drifting life outdoors (2026-11-08): cherry petals in spring, maple / persimmon leaves in fall, fireflies on clear summer nights, outdoor maps only, in both views, carried by the same wind as the rice and the hearth smoke (DriftRules, data/drift.json, DriftLayer / DriftGlow, DriftView; test_drift; ART_DIRECTION sections 2 and 3).
[x] The figures' night lift keeps to their own pixels (2026-11-08): the farmer, villagers, animals and the dog take the night lift in a "FigureLift" layer right after the field's, from the same copy of the tinted picture, only on pixels where it shows the figure's own texel (data/light.json sprites.lift.match, plus `bloom` for the 3D view's glow by a lit window), so a plant, fence or building corner in front keeps its pixels and a figure half behind a fence is lifted only where it shows; the old "Warmth" pass and its behind-a-building skip are gone. Same lift, falloff, lit side, buildings between and cap (NightLights.figure_lifts; ART_DIRECTION section 3).
[x] Painted roofs in the flat view (2026-11-08): the village houses, farmhouse, coop and barn are pixel roofs seen from above, not brown boxes: kawara tile rolls (gable, hip, two-storey pent), straw thatch on the coop, grey-brown kaya on the farmhouse, light from the upper left, same sizes and collisions; snow lying whitens them through the existing roof mask and the hearth smoke draws over them (RoofArt, PlaceholderArt "roof:", FarmView.ROOFS, MapView; test_view2d _roofs; ART_DIRECTION).
[x] Calm paddy ground in the 3D view (2026-11-08): the Kaminoda paddies where rice is drawn use the flat view's calm ground in 3D too, paddy_mud in winter and paddy_flood in the other seasons, from one rule shared by both views (MapView.paddy_cells_in / ground_key_at, MapWorld.ground_keys); the painted paddy tile stays where no rice grows (test_maps `_paddy_ground_3d`; ART_DIRECTION, Rice and tall crops).
Marriage for everyone (planned 2026-11-08, docs/DESIGN.md → ความรักและแต่งงาน): eight
candidates, six women and two men, half of them villagers already here (Sayo, Fumi, Haru, Ichiro) and half new (Mio, Kaede, Shino, Ren), each open to the farmer whatever the farmer's look. One
candidate per commit, Sayo and Fumi as the pattern (band 3 / 5 / 6 scenes, knot answers,
proposal, wedding, married rules and lines, Thai).
[x] The roster and the rule written down (2026-11-08): DESIGN, STYLE_EN (no gendered words for the farmer or spouse).
[x] Haru a candidate (2026-11-08): her band 6 scene was already in; the knot answers, the proposal, the wedding at the shrine (Genzo among the guests), married plans (up to Kaminoda and the hill by day, the farmhouse mornings and evenings, weaving by the kotatsu on wet days), engaged / married / chore lines, Tome's Friday hint, Thai.
[x] Ichiro a candidate (2026-11-08): the knot answers, the proposal, the wedding at the shrine (Fumi among the guests), married plans (the woods, the teahouse lunch and his woodpile by day, the farmhouse from 17:00, splitting wood in his old entry on wet days), engaged / married / chore lines, Tome's Friday hint, Thai.
[x] Mio (new) a candidate (2026-11-08): keeps the fish traps and the old ferry on the river, lives in a driftwood hut on its north bank (mio_hut); day plans (traps mornings, selling her catch at the store's front, mending nets, festivals, her birthday spring 12), talk and gifts, heart scenes 3 / 5 / 6 (where the fish lie; keep or let go the ferry; naming the boat), the ending's page, whistle, then the knot, proposal, wedding (Hachiro and Kota among her guests), married life; Thai.
[x] Kaede (new) a candidate (2026-11-08): keeps the village shrine, Tome teaching her the rites; lives in the shrine keepers' house in Minamino's east (kaede_house), bows at Minamino's roadside shrine on her way up; day plans (sweeping the gravel, charms by the hall, festivals by the hall, her birthday fall 4), talk and gifts, heart scenes 3 / 5 / 6 (the shrine's white fox; the New Year rite alone, words in the sleeve or said aloud; the first fortune from the new box), the ending's page, whistle, then the knot, proposal, wedding at her own shrine (Nana, Shige and Mio among her guests), married life; Thai.
[x] Shino (new) a candidate (2026-11-08): dyes indigo, back from the city to her family's dye house west of Minamino's lane down to the river (shino_house, two indigo vats in front); day plans (the vats mornings and late afternoons, rinsing cloth on the river's west shore after lunch, wildflowers on Sundays, the vats inside on wet days, festivals, her birthday winter 4 by the river), talk and gifts, heart scenes 3 / 5 / 6 (which blue; her mother's stencils or her own; the first bolt and a noren for the farmhouse), the ending's page, whistle, then the knot, proposal, wedding (Kiku, Kaede and Sayo among her guests), married life; Thai.
[x] Ren (new) a candidate (2026-11-08): carries the post, lives behind the counter of a new little post office by the farm road (post_office); his round reaches every part six days a week, rain or shine (the village houses, Sakurazaka, Kaminoda, the river, Minamino), sorting at the counter mornings and late afternoons, Sundays and his birthday (spring 15) by the village pond, festivals; talk and gifts, heart scenes 3 / 5 / 6 (whose letters weigh most; the van or the round on foot; his first letter, to the farmer), the ending's page, whistle, then the knot, proposal, wedding (Genzo, Fumi and Mio among his guests), married life; Thai. All eight candidates are in.
[x] The farmer's look chosen on a new game (2026-11-08): New game opens a look step on the title screen (hair style, hair color, skin, clothes; a few choices each in data/farmer_looks.json, the first of each the old look), a walking preview turning round, keys / pad / mouse, English and Thai; saved, old saves load the old look; FigureArt draws the farmer from it in both views and every pose, the art cache kept per look (FarmerLooks, LookMenu; `--look=`, `--new-game`; test_title, test_save, test_lang).

[x] Painted paddy ground in the flat view (2026-11-07): the Kaminoda paddies' ground is painted in the ground tiles' pixel style, drained mud with wet sheen, puddles and straw in winter, still water with a soft sky reflection and ripple lines in the other seasons, every feature wrapping so the tiles repeat (PlaceholderArt "paddy_mud" / "paddy_flood", PlaceholderArt._wrap; test_view2d _paddy_tiles; ART_DIRECTION, Rice and tall crops).
[x] Glint on the 3D winter water patches (2026-11-07): the 3D view's paddy patches (CropClusters.plant_water) carry the same wind-driven glint, worked out in WATER_SHADER from the patch's place (phase and one-or-two by hash, rice's wind, quicker in rain and storm, none while snow lies), numbers in data/wind.json "3d".glint, colour data/paddy.json water.shine.
[x] The field's night lift keeps to its own pixels (2026-11-08): the lift of crops, cluster plants, items and objects near a light is drawn in its own pass from a copy of the tinted picture before the pools, only on pixels where that copy shows the picture's own texel (data/light.json sprites.lift.match), so a plant, fence or figure in front keeps its pixels; a cluster plant's quad follows its sway and parting (the plants sway on CropClusters.clock, CropClusters.tip_shift). Same lift, falloff and cap (ART_DIRECTION section 3).
[x] Glint on the winter water patches (2026-11-07): each flat-view water patch of the Kaminoda paddies shows one or two pale pixels that drift with the rice's wind, quicker in rain and storm, out of step by place, none under snow (CropPatches.glint_dots, data/paddy.json water.shine, data/wind.json "flat".glint; ART_DIRECTION, Rice and tall crops).
[x] Ambient loops made ahead (2026-11-07): Sfx.loop_stream builds the six ambient loops on a worker thread from start-up and a loop starts once ready, so the first play of the crickets (about 190 ms on the main thread) no longer stalls a frame.
[x] Stone lanterns wash the walls (2026-11-07): a lit stone lantern in front of a house wall puts a soft warm disc on it, smaller and weaker than a window's, of the wall's own material (plaster, earth, board), fading to nothing 1.6 cells out, cut to the wall's ends, bands, posts and panes, stopped by a building between (NightLights.lamp_walls / lamp_wash / lamp_washes, data/light.json pools.wall.lamp); two new village lanterns by Tome's door and the clinic's show it.
[x] Calm paddy ground in the flat view (2026-11-07): the Kaminoda paddies where rice is drawn use plain drained mud in winter and flooded still water in the other seasons instead of the painted tuft tile, so the stubble and the water patches read clearly (CropPatches.paddy_ground, MapView.ground_key_in; the 3D view keeps its tile).
[x] The shore ice grows (2026-11-07): the winter ice is thin at the start of winter, widest about day 22 and receding by the end, and wider while snow lies (data/snow_cover.json ice.grow: curve, cover_bonus, max 4.4; WaterIce.grown_width, Game.ice_for / ice_style), the same in 3D and the flat view, the open middle kept for fishing.
[x] Shader warm-up for the night and the first map (2026-11-07): the warm-up quads of kinds the night lamps light stand under a lamp of their own, one warm-up frame draws with the sun's shadows the other way round, and the first map after the title is built and warmed under a short black cover (ShaderWarm WarmLamp, Main3D._warm_step, MapFade.cover). The village's dusk frames: lamps on 371 / 484 -> 160 / 167 ms, shadows off 500 / 483 -> 108 / 112 ms.
[x] The field takes the night lift (2026-11-07): crop sprites, the crop clusters' plants, items on the ground and the other unshaded field sprites near a lit window, door, stone lantern or festival light take the figures' warm lift (same range, falloff, lit side, buildings between, cap), worked out once a game minute, drawn before the figures in NightLights' "Warmth" pass (SpriteLight.field_lifts; ART_DIRECTION section 3). The flat view is unchanged.
[x] Flat view water patches (2026-11-07): the Kaminoda paddies' winter water patches, the 3D view's water_spots_for places, drawn under the stubble in the flat view as pixel blobs in data/paddy.json's colours, left out under snow (CropPatches.draw_water; ART_DIRECTION, Rice and tall crops).
[x] Tall crops sway in the flat view (2026-11-07): the tips of rice, corn, vines and the paddies shift by whole pixels with the wind of data/wind.json (stronger in rain and storm, vines stiffer, phase by place; CropPatches.sway_tip, data/wind.json "flat"; ART_DIRECTION, Rice and tall crops).
[x] Sprites take the world's light (2026-11-07): the unshaded sprites take a share of the sun's colour by the clock (golden morning and evening, plain at noon, night, indoors and under cloud) and, at night, a warm lift near lit windows, doors, stone lanterns and festival lights, staying blue in the dark (SpriteLight, NightLights "Warmth", data/light.json "sprites"; ART_DIRECTION section 3). No sun shadow on the sprites (would not match the ground's); the flat view is unchanged.
[x] Winter paddies (2026-11-07): the cut rice stands as stubble in the nine-hill layout and a few grey-blue water patches lie between the rows, both folding away or vanishing under snow lying on them by the paddy's hold (CropClusters.paddy_key / plant_water, data/paddy.json; ART_DIRECTION, Rice and tall crops).
[x] Tall crops in the flat view (2026-11-07): rice, corn and the vine crops past the sprout are several small pixel plants a cell, as in 3D, and the Kaminoda paddies grow rice by season (CropPatches, the same CropClusters places and `stalk:` pictures; no sway yet; ART_DIRECTION).
[x] Earthen and yakisugi walls take the night lamps (2026-11-07): a soft warm glow on the timber look's earthen plaster and a faint warm-grey sheen on the charred boards round lit windows and doors, cut clear of posts and rails (NightLights.finish_wash, data/light.json pools.wall.finishes; ART_DIRECTION section 3).
[x] Footprints read the snow patches (2026-11-07): a print appears only where snow really lies (the cover's noise, 3D shader and GDScript copy, flat view), bigger and a little darker (data/footprints.json; ART_DIRECTION, section 2).
[x] Hearth smoke in the flat view (2026-11-07): pixel puffs over the farmhouse and village roofs at the same vents, hours, fade, wind drift and storm rule as the 3D smoke; the rules moved to SmokeRules and both views call them (SmokeView, data/smoke.json "flat"; ART_DIRECTION section 3).
[x] Hearth smoke (2026-11-07): thin pale smoke from the farmhouse's ridge and the village roofs at meal times, drifting with the wind, buried in a storm (HearthSmoke, data/smoke.json; ART_DIRECTION section 3). The flat view is left open.
[x] Footprints in lying snow (2026-11-07): the farmer, villagers and dog press small blue-grey soles into snow of 30% cover or more (ring of 160, fading in 90 game minutes, faster in snowfall, cleared on a map change and a new day), 3D and flat (data/footprints.json; ART_DIRECTION, section 2).
[x] Flat view maple (2026-11-07): the maple is a small layered tree picture in the flat view (PlaceholderArt tree:maple, by season and snow), not a box (WORKLOG "The flat view's maple is a tree picture").
[x] Vines read better (2026-11-07): a ripe cucumber's fruit is pale yellow-green with a lit edge and a dark side, the leaves left off beside the fruit (both vines); the villagers' and the dog's parting on a stake checked to take the vine's stiffness like the farmer's (ART_DIRECTION, Rice and tall crops).
[x] Winter ice on the water (2026-11-07): thin ice along the shore of the pond, the village water and the river in winter outdoors (pale rim, cracks, frost, a snow dusting by the snow lying), the middle open for fishing, 3D and flat (data/snow_cover.json ice, WaterIce; ART_DIRECTION, Water).
[x] Rain dimples on the water (2026-11-07): small rings at random spots in rain and storm, 3D and flat (data/weather_fx.json dimples; ART_DIRECTION, Water).
[x] Barn stalls: straw bedding as lit meshes (2026-11-07): a low pad, lumps and loose stalks in each stall (ART_DIRECTION, the barn's insides).
[x] Playtest fixes (2026-11-07): smooth map changes (a steady fade, worlds kept for going back) and no getting stuck on corners or villagers.
[x] Playtest fixes, second round (2026-11-07): running goes through exits; no freeze after a map change (trigger tables kept, the fade lets go sooner).
[x] Flat view farmer: the FigureArt figure (24 x 32, FarmerAnim poses) instead of the drawn stand-in (Player "Figure" sprite).
[x] Cucumber and tomato vines on stakes as clusters, the wind on every tall crop (2026-11-07; ART_DIRECTION, Rice and tall crops).
[x] Festival stalls' wares as lit meshes (2026-11-07): every selling stall's goods on its counter (StallWares: skewers, bowls, griddle, chimes, fans, daruma, charms; steam over hot food), the curtain a little shorter so they show (ART_DIRECTION section 1).
[x] Flat view stalls show their wares (2026-11-07): every item with a 3D look is a pixel-drawn ware on the counter (festival:ware_<name>, steam over hot food) instead of the item picture (ART_DIRECTION section 1).
[x] Lantern Night's two bare stalls (2026-11-07): a goldfish-scooping tub with swimming fish and paper scoops, and a stand of festival masks, as a stall prop's `display` (StallWares, both views; ART_DIRECTION section 1).
[x] Pale plaster takes the night lamps (2026-11-07): a warm wash on the pale walls round every lit window and door, over the tint, kept to pale pixels (NightLights.wall_wash, data/light.json pools.wall; README → Light).
[x] Maples (2026-11-07): a Japanese maple tree kind (`Trees` "maple", small layered crown; green, deep green, red and orange, bare with snow), six on the bamboo hill and one each in Kaminoda and Sakurazaka; the hill's trees checked from the lookout (ART_DIRECTION, Trees).
[x] Hill trees (2026-11-07): six broadleaf trees on the bamboo hill (data/maps/hill.json: persimmons and sakuras), red or gold in fall, bare with snow in winter (ART_DIRECTION, Trees).
[x] Faster first visit to a map (2026-11-07): meshes the same every build kept a run (MeshCache), the maps next door built ahead while the farmer stands still (Main3D._prebuild); tools/build_times.gd times every build.
[x] Shader warm-up and cheaper rebuilds (2026-11-07): every kind of material (and its faded twin) kept a run and drawn once in the map change's black (ShaderWarm), no more long frames when a house or a bamboo clump fades in the farmer's way; village houses, the farmhouse and the stand kept whole by MeshCache (windows, noren in the wind); rebuilds about 40% quicker.
Art direction (2026-11-03): the user wants an "HD-2D lite" look, Japanese countryside: pixel
sprites in a lit 3D world. [x] Light pass (sun shadows on the ground, warm sun / cool shade,
glow; README → Light). [x] Camera lenses (data/camera.json: ps1, medium, wide; `--lens`);
the user picked "medium", now the game's lens. [x] Modelled sample: the farmhouse's thatched
kayabuki roof (scripts/world3d/minka.gd, README → Farmhouse model, models/farmhouse.glb).
[x] The coop (thatch) and barn (kawara with tile rolls) roofs as meshes (`Minka.gable`).
[x] The village houses' kawara roofs as meshes, ridges curling up to onigawara (`Minka.ridge`).
[x] The New Year bamboo (kadomatsu) and the farm's bamboo fence as lit meshes (`FestivalMeshes.kadomatsu`, `OutdoorProps.fence_*`).
[x] Village house variety: hip roofs (`Minka.hip`), two storeys with a pent roof, yakisugi and timber walls (data/maps fields).
[x] The shrine pieces as meshes (scripts/world3d/shrine.gd: torii, hokora, stone lanterns).
[x] The seed stand, chest and bin by the farmhouse as meshes (scripts/world3d/farm_props.gd).
[x] Interiors: walls as timber frames, low front sills, step edges and a shoe stone, soft
floor shading by the walls (scripts/world3d/room_walls.gd).
[x] Room furniture as lit meshes, all 22 kinds (scripts/world3d/room_props.gd).
[x] UI pass: one shared look (washi paper in dark wood frames, `UiStyle`) for the HUD and every screen.
The full style roadmap, the rules for making pieces and how to continue: docs/ART_DIRECTION.md.
[x] Trees: lumpy lit crowns by season, tiered pines with snow, snow on bare winter branches,
the wood as MultiMeshes (scripts/world3d/trees.gd).
[x] Grass tufts on the grass cells, swaying, by season, hidden under snow
(scripts/world3d/grass_tufts.gd).
[x] Rice and corn as clusters of small pixel sprites, the village paddies' rice by season
(scripts/world3d/crop_clusters.gd).
[x] Animals redrawn in the same style: 2x pixel density, four facings, all states (scripts/art/animal_art.gd). Next art step: section 4's remaining items (farmer / villager sprites, shadows) in docs/ART_DIRECTION.md.
[x] The grass tufts and the rice / corn part round the farmer in the 3D view (scripts/world3d/parting.gd, data/wind.json "part").
[x] Roof snow without patch holes: snow tops whole from half cover up, thinning in patches only
when little lies (`SnowLayer.TOP_FULL`, scripts/world3d/snow_layer.gd).
[x] The villagers and the dog part the grass and crops too (up to 8 pushers, the farmer first; `Parting.GROUP`).
[x] Water: a gentle moving surface on the farm pond, the village pond and the river
(scripts/world3d/water_surface.gd).
[x] Flat view water: the same drifting glints and troughs on the pond and river, pixel-stepped,
banks left still (scripts/world/water_view.gd, WaterView, in FarmView and MapView).
[x] The coop's and barn's insides as lit meshes (scripts/world3d/coop_props.gd, barn_props.gd).
[x] Bamboo (segmented, swaying, by season, snowy) and the well, jizo, woodpile and river rock
as lit meshes (scripts/world3d/outdoor_props.gd).
[x] Water: ripple rings round the fishing bobber (WaterSurface.ripple, scripts/world3d/water_surface.gd).
[x] Flat view water ripples: the same bobber rings on the pond in the flat view (WaterView.ripple, driven by main_2d.gd `_ring_bobber`).
[x] Wind follows the weather: data/wind.json per weather, pushed to the grass tufts and the bamboo sway
(a calm sunny day, medium in rain, strong in a storm or blizzard; docs/ART_DIRECTION.md, the table).
[x] The wind also moves the fence's leafy shoots, the kadomatsu's pine and plum, the shop and stand
noren, the festival stalls' curtains and the race banner (OutdoorProps.Sway leaves / cloth); posts stay still.
[x] The drying rack, kitchen garden and board fence (scripts/world3d/field_props.gd) and every festival
decoration (scripts/world3d/festival_meshes.gd) as lit meshes.
[x] The sun's colour and angle follow the clock outdoors: low and golden morning and evening,
high and plain at noon (data/light.json "sun", README → Light).
[x] The sky behind the land follows the clock outdoors: dawn peach, the day blue at noon, mauve
dusk, a deep blue night, greyer and darker under cloud (data/light.json "background", README → Light).
[x] Real sun shadows for the figures: farmer, villagers, animals and field objects (`SpriteShadow`, data/light.json "sprite_shadows", README → Light); a faint blob stays, whole in rain, at night and indoors.
[x] Trailer-ready screenshots: 12 fixed views (data/showcase.json), rendered and compared by
tools/showcase.py (README → Showcase).
[x] Night: real warm lights (NightLamps, at most 8 OmniLight3Ds without shadows at the lit
windows, stone lanterns and festival lights; data/light.json "lamps"), the night blue a touch
lighter, the festival's lights and stalls lighting the ground in both views (README → Light).
[x] The far country: mountain ridges past a rim on the north and west sides of the outdoor
maps, hazed with the sky by the clock, snow caps in winter (data/backdrop.json, README → Camera).
[x] Characters, step 1: larger, more detailed farmer and villager sprites (24 x 32, Japanese
country clothes, builds for elders and children; scripts/art/figure_art.gd, FigureArt), four
directions (front / back, mirrored), drawn in code by the agent until real art comes.
Next: section 4 is done (figures d2d8064, animals 36d42c6, real sprite shadows f261048). Open there: eight directions, real art by an artist. "ทำ art direction ต่อ" from the user
means take the next unticked item in docs/ART_DIRECTION.md.
Playtest feedback waiting to be fixed is kept in docs/FEEDBACK.md (the user starts it with
"แก้ feedback"). [x] Item 1: Thai text (Settings → Language, data/lang/th, Thai glyphs in our
pixel font). [x] Item 2, a goal for week one: Tome's first-week
list (data/goals.json, README → Goals, the HUD's goal tag). [x] Item 3, where love leads: marriage
(data/marriage.json, README → Villagers → Marriage). [x] Item 5: dish prices a modest gain over the cheapest ingredients (data/foods.json `_dish_prices`). [x] Item 4: winter mine income about halved (data/mine.json `_prices`). [x] Item 6, night: a deep blue night,
smooth dusk / dawn and lit house windows (data/light.json, README → Light), then warm pools on the ground under windows and lanterns, the glow kept off figures in front, and the same in the flat view (NightView). [x] Item 7: the barn's hay and straw,
the title text's backing. [x] Item 8: the title's save check (it lacked the food table) and
atomic saves with a backup. No feedback items are open now. [x] Thai for the villagers'
daily talk, heart events, contests, marriage and the record (data/lang/th/dialogue.json).
[x] The last Thai gaps (goals, level-ups, shop notes, pad names, save errors): th at 100%.
Languages (the user aims at players worldwide, 2026-11-04): [x] Step 1, ready for translation:
LangCatalog and tools/lang_report.gd (coverage per language, stale entries, a todo file),
no text glued from pieces in the scripts, `--lang=pseudo` and test_lang (the screens and the
dialogue fit a third longer). [x] Step 2, the English polished to docs/STYLE_EN.md
(American spelling, no "a %s", item names in sentence case, messages that end like
sentences; test_lang checks it). Next: once the content settles, translate in one go
(Latin-script languages first; Chinese / Japanese need a licensed CJK pixel font).
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
Courting ends in marriage (data/marriage.json, README → Villagers → Marriage): Sayo or Fumi,
asked with a mizuhiki knot from the store once at band 6 after their band 6 scene and with
the second room built; the wedding is at the shrine three days later, then the spouse lives
at the farmhouse, names the spouse in the village record and helps each morning (a few dry
plots watered on sunny days, the coop's feed box topped up; marriage.json help). A child
follows (data/child.json, the five steps of docs/DESIGN.md → ลูก, all done 2026-11-09).
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
4 stamina and the hammer levels slower (WORKLOG). [x] Fish no longer out-earn crops in year 1:
the everyday fish sell for about 20 G, the money is in the fish of their hour (year-1 fish
54620 → 18837 G against 111060 G of crops and animals; WORKLOG 2026-11-03 Fish prices).
The deep floors are reachable now: floors 5, 10 and 15 are rope lift landings, and once reached
a trip can start there from the cave mouth (README → Mine). Later for it: grilled fish (80 G
from one cheap fish) may be the next shortcut; the bot rides the lift
now and reaches floor 25, but winter mining from floor 15 out-earns a farming year
(171766 G in year 1 winter; WORKLOG 2026-11-03): the deep finds were lowered (year-1 mine 201780 → 88150 G; WORKLOG 2026-11-03 Deep mine finds).
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
row (the villagers without hearts known to band 1; one now, one step; two before Kiku got hearts, three before Nana got hearts, four before Shige got hearts, five before Haru did, six before Genzo did, eight before Fumi and Ichiro did).
Haru of Kaminoda has hearts now too (birthday summer 27, close lines, heart events at bands 3, 5 and 6, a word at the ending; Neighbours four now). So has Shige of Minamino (birthday winter 18, close lines, heart events at bands 3, 5 and 6: the scarecrow, his wife's pumpkin seed and the first pumpkins, a word at the ending; Neighbours three then). So has Nana, his daughter (birthday fall 19, close lines, heart events at bands 3, 5 and 6: Captain the tadpole, her map of the sky and a star on it for the farmer, a word at the ending; Neighbours two now, Kiku and Dr. Yae, the record 41 stars). So has Kiku, the old woman of the orchard (birthday winter 25, close lines, heart events at bands 3, 5 and 6: why she bows to the water spirit, her little brass bell and a twig of the oldest persimmon tree for the farmer, a word at the ending; Neighbours is Dr. Yae alone now, one step, the record 40 stars). Every villager with hearts has all three scenes now. Shige, Genzo, Haru, Ichiro and Nana are
contest rivals (one in every contest and game). Forage spots are in the three outer parts too
(their own wild things: water dropwort, sansho, mulberries, ginkgo nuts and more). Wild things
cook: six recipes of wild greens, mushrooms, bamboo shoots, chestnuts and matsutake (Haru, Genzo
and Kiku teach three once they know the farmer; the first bamboo shoot, chestnuts or matsutake
shipped brings a card). Tome, Hachiro, Sayo and Kota talk about forage too (a line per season,
one weekday each, from band 2), and so do the outer parts' villagers about their own part
(one weekday each; Fumi, Ichiro, Genzo, Haru, Shige, Nana and Kiku, who have hearts now, from band 2 like the first
four).
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
   - [x] The 3D view never looks off the world (land and a pine wood past outdoor map edges) and buildings / trees in front of the farmer turn see-through (playtest feedback, 2026-11-03)
   - [x] Key hints over the tool bar: what E / Space do at the spot in front, with the player's keys; Esc → Settings → Key hints (playtest feedback, 2026-11-03)
   - [x] Key hints show the player's pad buttons while the pad was the last device used (`Game.pad_active`, `input_device_changed`)
   - [x] Pad button names: PlayStation names (Cross, Circle, L1...) for a PlayStation pad, Esc -> Settings -> Pad buttons: Auto / Xbox / PlayStation
   - [x] Night (docs/FEEDBACK.md item 6): a darker deep blue night, smooth dusk and dawn (data/light.json), farmhouse and village house windows lit warm at night in the 3D view (NightLights)
   - [x] Night follow-up: warm pools on the ground under lit windows and round the stone lanterns, lanterns' fire boxes glow, the windows' glow kept off the farmer, villagers and animals in front (data/light.json "pools")
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
   - [x] Forage talk from the outer parts' seven villagers (their part's wild things, one weekday each; band 2..5 for Fumi and Ichiro, band 1 on for the rest)
2. **Look and feel**
   - [x] Farmer placeholder frames (3/4 front / back x idle / walk / run) + animation timing
   - [x] Farmer real art (same keys: `player:<front|back>:<pose>:<frame>`): the refined pass (2026-11-10): FigureArt draws the farmer (farmer = true) in three tones per material lit from the upper left, lines between parts in each material's deep tone, a darker rim round the silhouette, jika-tabi with a split toe, a clasp and a rubber sole, a woven hip basket (data/farmer_art.json); every look option, key, size and pose kept; the villagers and the child got the same pass the same day (data/villager_art.json, keys `villager:...` and `child:figure:...` kept). Real hand art is still to come.
   - [x] Field object and crop placeholders (per crop look in `data/crops.json`, 4 growth looks + ripe)
   - [x] Field object and crop art (same keys: `crop:<id>:<growth>:<ripe|growing>`): the refined placeholder pass (2026-11-08): CropArt draws the single-sprite crops part by part, three tones, deep leaf-shade rim. Real hand art is still to come.
   - [x] Bush leaf detail (2026-11-08): the potato and eggplant bushes at growth 2 and 3 are a fan of separate leaves with lit upper-left edges and shade midribs over a shaded underside (CropArt._foliage; test_farm `_crop_art` counts the tone-edge pixels).
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
   - [x] Marriage (docs/FEEDBACK.md item 3): Fumi's band 6 scene, the mizuhiki knot (the store), the proposal rules (band 6, the band 6 scene, the second room), the answers, the proposal and the wedding at the shrine, the spouse living at the farmhouse with married lines (data/marriage.json)
   - [x] Heart flags in the lanes: the jizo's new red bibs in Kaminoda (genzo_jizo) and Ichiro's new charcoal kiln in Sakurazaka, half built after ichiro_kiln and finished with the farmer's thumbprint after ichiro_mark, lit meshes and flat-view art
   - [x] The spouse helps each morning: a few dry plots watered on sunny days, the coop's feed box topped up from the farmer's stock (marriage.json help), told on stepping out
   - [x] The old kiln looks worn: two hairline cracks, a branch and a chip on its clay face (3D lit quads, `OutdoorProps.kiln` worn; flat overlay `story:kiln_worn` drawn over its cells); the new kiln stays whole
   - [x] The spouse's talk names the morning's chore (help_water / help_feed lines in talk_sayo.json and talk_fumi.json), before noon only
   - [x] Ending: the village record on the first morning of year 3 (data/ending.json: ten categories graded in stars, five ranks), Tome's verdict, the closest villager's word; the game goes on
   - [x] The record names a married farmer's spouse under the title (the wedding day kept for it; undated for older saves), on the yearly page too (FEEDBACK item 3 follow-up)
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
