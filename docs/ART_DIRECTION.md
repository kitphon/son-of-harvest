# Harvest Son — art direction and style roadmap

What the game should look like, what is already done towards it, and the steps left, so the
work can be picked up again later. ROADMAP.md → "Next up" points here; README → Camera,
Light and Farmhouse model hold the technical detail of what is built.

## The look we chose (2026-11-03)
- **Theme: Japanese countryside (satoyama).** The user prefers Japanese art over a Thai
  re-theme. Keep the village, names, food and festivals Japanese (ROADMAP → Mood and tone).
  Don't propose another theme.
- **Style: "HD-2D lite".** Pixel-art sprites (characters, crops, items) standing in a lit,
  stylized low-poly 3D world: real sun shadows, warm light and cool shade, a little depth from
  the lens. Bright and cozy, not realistic. The light and depth carry the mood more than detail.
- **Camera: the "medium" lens** (data/camera.json: fov 28°, pitch 30°, yaw 45°). It is our
  own lens, picked by the user from screenshots of three. "ps1" (the measured Back to Nature
  camera) and "wide" stay in the file to compare with `-- --lens=<id>`.
- **Who makes what.** Scenery and props: built in code by the agent (meshes with SurfaceTool,
  exportable as .glb). Character sprites: the part that most needs an artist's hand; the user
  or a hired artist, unless the user asks the agent to refine the placeholders.
- **Clean room as always.** Reference pictures may set a mood. Never copy a building, character,
  layout or texture from another game or film.

## Done
| Step | Commit | What |
|---|---|---|
| Light pass | 4dcda4b | Warm sun from the upper left, cool sky light, sun shadows on the lit ground, soft glow. Shadows fade at dusk / night and are off in rain and snow (`Game.sun_shadow()`, weather_fx.json "sun"). |
| Camera lenses | 0a87140 | `CameraLens` + data/camera.json; every lens frames the farmer's feet the same. |
| Lens choice | f7ab692 | The game uses "medium". |
| Modelled sample | 1b59453 | The farmhouse's thick thatched kayabuki roof (`Minka.roof`), textures `build:kaya` / `build:kaya_edge`, `tools/house_model.gd`, `models/farmhouse.glb`. |
| Coop and barn roofs | a60c0e1 | `Minka.gable` (thick gable roof: slopes, eave bands, verges, soffit, snow; optional kawara tile rolls) and `Minka.gable_wall`; the coop thatched (0.4 thick, about 37°), the barn kawara with rolls every 0.25 and a ridge stack with onigawara ends (about 29°); walls raised to the soffit; `build:kawara_edge`. The farmhouse's eave band faced inwards (culled) and now faces out. `house_model.gd --what=coop/barn`. |
| Village house roofs | 4395016 | Every `village_house` (town, Kaminoda, Minamino, Sakurazaka) has a `Minka.gable` kawara roof with tile rolls (pitch 0.5, about 27°), plaster gable ends, walls up to the soffit, and `Minka.ridge`: a ridge-tile stack and grey cap curving up over the last 0.8 to an onigawara at each end (the barn too). `house_model.gd --what=village`. |
| Village house variety | this commit | A `village_house` prop may set `roof` ("gable" / "hip"), `storeys` (1 / 2) and `wall` ("plaster" / "yakisugi" / "timber"); `LitSpots.village_style` reads them (unset: gable, 1, plaster). `Minka.hip`: a kawara hip roof (yosemune), one pitch all round so the hips run at 45°, eave band all round, soffit, snow, tile rolls on all four slopes stopped at the hips, a low tiled crest down each hip; `Minka.hip_ridge_ends` for its main ridge. Two storeys (zushi-nikai): a tiled pent roof (a `Minka.hip` whose top hides inside the upper floor) at the ground floor's eaves, the upper floor 0.3 in from the walls up to 2.9, the main roof on it, upstairs shoji (LitSpots, lit at night) between the pent roof and the main eave's shadow line. Walls: plaster over a board skirt; yakisugi (charred boards up to a plaster band under the eave); timber (earthen `build:tsuchi` between a post at every cell edge and a rail over the windows). The mix: Tome's house hip / timber, the smithy two storeys / yakisugi, the clinic hip, Kota's yakisugi, Sayo's store unchanged (its sign stands on the roof), the teahouse hip and two storeys, and the outer villages' houses one of each. `house_model.gd --what=village --style=roof:hip,storeys:2,wall:timber`. |
| Shrine pieces | 63b877f | `scripts/world3d/shrine.gd` (Shrine): the torii with tapered posts on black footings, a plaque, and the shimaki and black kasagi as beams sweeping up 0.16 to their ends; the hokora on a two-step stone base under a `Minka.gable` board roof with chigi and katsuogi, vermilion doors, a shimenawa with paper streamers; a six-sided Kasuga-style stone lantern turned with `Shrine.lathe` (flat facets), lit windows on the two faces the camera sees, corners turned up. Minka's mesh helpers (`quad`, `tri`, `beam`, `plain`, `add_mesh`) are public for this. `house_model.gd --what=shrine`. |
| Bin, chest, seed stand | a3f4619 | `scripts/world3d/farm_props.gd` (FarmProps), all lit: the bin a cedar box splayed a little wider at the top on runners, corner battens, a straw rope with a knot, hanging ends and a paper tag, a bevelled plank lid with battens; the chest a tansu with drawer fronts, iron pulls, corner plates wrapping onto the +x face, a side handle, a bevelled lid; the stand a `Minka.gable` board roof (front eave 1.45) on posts with tie beams, king posts, ridge beam and board, a counter, three turned burlap seed sacks with a neck cord and seeds showing, an honesty box with a coin slot, the noren (shorter, so the sacks show) and a price board (`build:stand_sign`). `FarmProps.block` = a tapered box with flat normals and world-unit UVs; `FarmProps.Parts` = one SurfaceTool per material. `house_model.gd --what=props`; `--map=farm@bin` in the game. |
| Interiors | b6f6098 | `scripts/world3d/room_walls.gd` (RoomWalls) builds every indoor "wall" cell as lit meshes: the back walls a timber frame (posts every other cell and at the inner corner standing 0.04 proud, board skirting under a rail, recessed plaster or, with `walls: "board"` (coop, barn), cedar boards, a nageshi beam at 1.28, a head beam), a shoji window in a dark frame with a plank sill every fourth cell of a plaster wall; the front walls a low board sill (0.27) on the room side of their cells with post stubs and stubs each side of the door; a step edge (agari-kamachi) where boards or tatami meet the earth and a flat shoe stone below the door's step. The floor picture darkens softly along the walls (`MapWorld._shade_corners`, more under the tall back walls), standing in for the ambient occlusion the renderer lacks. Lit, the back wall (sunward) and the left wall (in shade) now read apart. |
| Furniture | 0f662b2 | `scripts/world3d/room_props.gd` (RoomProps) builds all 22 kinds of room furniture (the farmhouse, homes, shops, clinic, smithy) from `FarmProps.block` and `Shrine.lathe` in lit materials, replacing MapWorld's boxes and cylinders (mostly unlit) and HomeProps (removed): a two-section tansu with drawer fronts, warabite pulls, corner plates and a sliding door; a turned chabudai with a teacup and pot; a kamado narrowing to its lip with an arched fire mouth, a flanged rice pot and logs; a mizuya with shoji lattice; a futon with a puffy quilt and collar; a counter with battens, a bell on a cushion and an account book; shelves of boxes and turned jars; tawara on their sides with rope bands; the forge's hood narrowing to the chimney and a box bellows; an anvil on a stump; tool racks (on the left wall when longer in z); an irori with a turned kettle and fish catch; the butsudan's doors swung open; a zig-zag byobu. Only light-givers stay unshaded (`RoomProps.GLOWS`: the andon's paper, embers, fire, a candle flame) via `Parts.glow`. `_placed` turns a part (append_from with a transform). |
| Animals | (this commit) | `AnimalArt`: hens, chicks, cows, calves, sheep (wool and shorn), lambs and the dog as 2x-density sprites with four facings and the old states; see section 4. |
| Wind by weather | (this commit) | `data/wind.json` (strength 0..1 per weather look: sunny 0.15, rain 0.5, snow 0.3, storm 1.0, blizzard 0.9; there is no cloudy weather in data/weather.json), read by `Game.wind_strength()` (`wind_for`) each morning and on a map change (`Main3D._show_weather`, sheltered = 0), pushed by `FarmWorld.set_wind` to the grass tufts' shader (`wind` uniform: the tips swing about 1 + 1.5 x wind times as far, the wave runs faster (grass 1.6 + 0.9 x wind a second), a slow gust swell and a flutter, a small lean downwind) and to the bamboo sway (`OutdoorProps.Sway.wind`: the same lean, speed and gusts on the CPU, since the bamboo is not a shader). Zero wind is the old motion. Not on the water, houses or fishing. Test: test_weather `_wind_by_weather`. (this commit) The same Sway (`OutdoorProps.SWAY`, "WindSway") also moves leaves and cloth, still at zero wind: leaves (`add_leaves`: the kadomatsu's five pine sprigs and plum twig, each its own piece, and a leafy side shoot on about one fence post in five, `OutdoorProps.fence_spray`) lean downwind (+x, as the grass) by 0.06 x wind and a wave of 0.08 x wind with gusts, about their base; cloth (`add_cloth`: the shop noren (`MapWorld._village_house`), the seed stand's noren, each festival stall's curtain piece, the race banner) hangs from its top edge, the hem blowing out from its face (0.35 + a flutter, never back into a wall; the banner, free on both faces, swings both ways) and streaming downwind by a shear (so the top stays on its rod), by the square root of the wind (cloth is light: a fair festival day still stirs it). `FarmWorld.set_wind` passes the wind on to FestivalProps (a world of its own). Posts, culms, tubs, rods, roofs and the stalls' valance stay still. Test: test_weather `_wind_on_leaves_and_cloth`. The tall crops (`CropClusters`: rice, corn and the vines on stakes) take the wind too: `CropClusters.set_wind` (from `FarmWorld.set_wind`) feeds a `wind` uniform to every picture's shader, the grass's swing, gust swell and flutter and a small lean downwind, none at wind 0. Test: test_weather `_wind_by_weather`. |
| Trees | 578b60c | `scripts/world3d/trees.gd` (Trees), all lit: `Trees.broadleaf` (persimmon, sakura, maple) a lathe trunk with limbs and a crown of six faceted lumps (seven-sided `_lump`s, the four round the middle darker, the top one lighter, each turned at random by the seed), leaves by season from `Trees.LEAVES` (the persimmon's fall red deep enough for its fruit to show), bare in winter with five limbs and twigs, persimmons hanging on the twig ends into the snow, petals under a cherry in bloom; `Trees.pine` a trunk and four tiers of low faceted cones, darker below, a `garden` pine (the village's) leaning with its tiers set off to alternate sides on short limbs, the wood's straight; snow on each tier's top (`Parts.SNOW`) where snow lies. Used by MapWorld (`pine`), CountryProps (`persimmon`, `sakura`, `maple`), FestivalProps (the cherries) and Surroundings: the wood past the edge is three pine shapes in MultiMeshes (`Parts.meshes()` / `Parts.material`), turned per cell, its snow driven by `set_snow` (it had none). |
| Grass tufts | (this commit) | `scripts/world3d/grass_tufts.gd` (GrassTufts): one MultiMesh of a five-blade tuft (one triangle a blade, both faces) on the grass cells: the farm's bare untilled ground (replanted when the field changes, skipped when no grass changed), outdoor maps' free grass with no prop, and the apron past the edge. Up to two a cell, 70% kept, nudged, turned, sized and shaded by a hash of the cell so they never move. The shader sways the tips (height share squared, phase by place) and lights them as the ground (normal up on both faces, the sun only at `SUN_SHARE`); the base 80% of the tip colour, the tip by season (fresh, deep, straw, dry). Each tuft carries its cell's snow hold and folds away where the ground under its root is white (SnowLayer's noise). |
| Rice and tall crops | (this commit) | `scripts/world3d/crop_clusters.gd` (CropClusters): rice and corn grown past the sprout (growth 2 and 3, looks "grain" and "stalk") stand as several small pixel plants a cell instead of one sprite: nine rice hills in three rows (young: six smaller ones in two rows, the ground showing between), three corn stalks, and the vine crops (cucumber, tomato, look "vine") as two stakes a cell with the vine's leaves up each and, when ripe, the fruit hanging (a firmer `stiff` 0.6 sway and parting than rice: a stake holds the vine). Each picture (`stalk:<id>:<growth>:<ripe|growing>:<variant>` in PlaceholderArt, three variants leaning the blades or setting the leaves another way, rimmed in a deep leaf shade instead of the black outline) is one MultiMesh of camera-facing quads (the shader billboards each instance at its own size, flips half, shades each a little, sways the tips); places, sizes, flips and variants by a hash of the cell. Ripe rice goes straw-stemmed with gold ears bowing. Unshaded like the crop sprites. The village paddies (Kaminoda) grow rice by season (`CropClusters.PADDY`): young in spring, tall and green in summer, ripe in fall; in winter the cut stubble stands in the same nine-hill layout, with a few grey-blue water patches between the rows (`CropClusters.plant_water`, data/paddy.json). Their plants carry the paddy's snow hold and fold away under white ground, and the water patches vanish where snow lies on them. The flat view draws the same plants (`scripts/world/crop_patches.gd`, CropPatches: CropClusters' own places, sizes, flips, shades and `stalk:` pictures, whole pixels, further back first; the tips sway by whole pixels with the wind, `CropPatches.sway_tip` = the shader's swing, vines 0.6, redrawn 8 times a second, data/wind.json "flat") in FarmView for the field's tall crops and in MapView for the Kaminoda paddies by season (the winter stubble too), left out where snow lies on a paddy (SnowLayer.lies). The winter water patches show there too (CropPatches.draw_water: the same CropClusters.water_spots_for places, a 12 x 5 pixel blob in data/paddy.json's water.color, water.glint and water.sky, under the stubble, winter only, left out under snow). |
| Sprite shadows | (this commit) | Real sun shadows for the farmer, villagers, animals, the dog and the field's object sprites (`scripts/world3d/sprite_shadow.gd`, `SpriteShadow`; data/light.json "sprite_shadows"). Tested: a Sprite3D billboard casts from a quad that turns with the camera, so its shadow was a thin smudge on whatever stood behind (the farmhouse deck) and would change with the lens; every `FarmWorld.make_sprite` now casts nothing. Instead each figure carries a shadows-only quad wearing its own picture (alpha-scissor cut, read from the sprite's texture, offset and flip at runtime, so any sprite size works), kept square to the sun's horizontal heading (`face_yaw`, fed by `Main3D._aim_sun`), so the sun's shadow map throws the real silhouette: long and to one side in the morning and evening, short at noon, in the same direction as the buildings' shadows. Compared at 7:00, 8:30, 12:00, 17:30, rain, 19:00, the barn yard and the farmhouse room: real won (the blob's direction never agreed with the roofs' shadows and said nothing about the hour). A faint contact blob stays under the feet (`blob_in_sun` 0.35 of it) and grows back to the whole blob as the sun shadows fade (dusk, night) and where there are none (rain, snow, rooms, the mine); the blob's size comes from the sprite's opaque width. Crops of the field get the caster only. `"mode": "blob"` (or `-- --sprite-shadows=blob`) brings back the old blob alone. |
| Sun by the clock | (this commit) | data/light.json "sun": keys of [minute, elevation, yaw, colour, energy], read by `Game.sun_light()` (`sun_at`, `sun_plain`, `sun_direction`) and put on the DirectionalLight3D by `Main3D._aim_sun` each game minute. A low orange sun from the lower left at 5:30, golden through the morning, high (60°) and plain at noon, golden from the upper left in the evening, so long shadows fall up-right in the morning and down-right in the evening and are short at noon. It eases back to the plain fixed sun (48°, -40°, SUN_COLOR) only after the dusk tint has put the shadows out, so the night is unchanged. Energy stays SUN_ENERGY (the ground's SUN_SHARE holds); clouded weather keeps the plain colour; rooms and mines keep the plain sun. |
| Figures | (this commit) | `scripts/art/figure_art.gd` (FigureArt): the farmer and every villager as 24 x 32 pixel figures in Japanese country clothes (noragi, kimono, happi; tenugui, hachimaki, straw hat), adult / elder / child builds from the look's `build`, an outline round each part, front and back three-quarter views mirrored for four directions; every pose kept (walk, run, tired, hold, fish, eat, drink, work, the villagers' rod). 3D sprites at `FarmWorld.FIGURE_PX` (0.04): about 1.17 units tall. Tests: test_villagers `_figures`. |
| Outdoor props, bamboo | (this commit) | `scripts/world3d/outdoor_props.gd` (OutdoorProps), all lit, no boxes or cylinders. Bamboo: a clump is three or four culms (6-sided tubes bowed in two pieces, 2.2..2.9 high, tilting a little apart) with a node ring every 0.3 or so, five-leaf sprays on a twig at the upper nodes and a seven-leaf plume at each tip (long double-sided diamonds, drooping), colours by season (`OutdoorProps.BAMBOO`: fresh in spring with husked shoots at the foot, deep in summer, olive with fallen leaves in fall, dull in winter), snow skins on the upward leaves where snow lies (`Parts.SNOW`'s top shader, one material for the whole map). A clump is ONE mesh with colours on the vertices (`vertex_color_use_as_albedo`, so it still fades as one for the Occluders), built once per season / snow / look (8 looks picked by the cell) and shared; each cell turns it by its own yaw. `OutdoorProps.Sway` (a node in the world) leans each clump about its foot, two slow waves out of step, a phase by cell, 0.028 rad at most. Well: a ten-sided curb in three courses with a lighter rim and dark water, timber posts, a windlass with crank, rope and a hanging bucket, under a `Minka.gable` board roof. Jizo: a two-step block, a robed lathe body, a round head, a red cap, collar and bib. Woodpile: split logs (bark prisms with pale cut ends) in four rows under a plank lean-to sloping to the front, timber posts, snow on the roof. River rock: two faceted boulders (dark and wet low, lighter and sometimes mossy on top) in a ragged ring of foam, snow on the upward facets. |

## How the pieces are made (keep to these)
- **Scale.** 1 cell = 1 world unit; textures are 16 px a unit, nearest filtering. Figures
  (FigureArt, 24 x 32) are drawn at `FarmWorld.FIGURE_PX` (0.04): the farmer is about 1.17
  units tall. Doors and eaves must clear the farmer (front eaves at 1.45
  or more).
- **Meshes in code.** Build with SurfaceTool as in `scripts/world3d/minka.gd` (`roof` for a
  thatched hip roof, `hip` for a tiled one, `gable` for a gable roof, `FarmProps.block` for tapered boxes and bevelled lids, thatch or kawara with tile rolls, `ridge` for a tiled
  ridge with curled ends, `beam` for any beam along a curve; `Shrine.lathe` for round or
  many-sided things): flat normals
  per face, triangles turned to their normal with `Minka.tri` (Godot draws clockwise fronts), UVs
  in world units laid along the surface (u along an edge, v down a slope) so stripes and
  courses line up. Boxes (`FarmWorld._box`) are still fine for small parts. `RoomProps._cube` (a box on its bottom middle, optional bevel), `_front` (a thin panel on a +z face) and `_placed` (build round the origin, then turn and move it in) save repeating the rectangles.
- **Materials.** Lit `StandardMaterial3D` with a PlaceholderArt texture for surfaces the sun
  should shape (walls, roofs); `FarmWorld.flat_material` (unshaded) only for small dark or
  bright details. Every new texture is a PlaceholderArt key (`build:<name>`), drawn in code.
- **Snow.** Anything with a top that snow should cover gets a copy of its upper faces with
  `SnowLayer.top_material()` (added to `_snow_mats`, no shadow), like Minka's snow layer.
- **See-through.** Build a tall thing inside `occlude(...)` so it fades when it hides the
  farmer; keep its materials StandardMaterial3D (the occluder fades their alpha).
- **Checking.** `tools/house_model.gd` shows the farmhouse alone from four sides
  (`--what=coop` / `--what=barn` / `--what=village` / `--what=shrine` / `--what=props` / `--what=stalls` for those; add a `CENTERS` entry and a builder for more).
  Check that upright faces point outwards (test_maps `_walls_facing_in`): `Minka.tri` turns a face
  to the normal it is given, so a wrong normal makes a face that is culled from outside. Look at the game at 10:00,
  17:00, 20:00, rain and winter snow, and inside the see-through fade, before committing.
  Tests: geometry rules go in test_maps (see `_minka`).
- **Light numbers.** The ground's sun share (`SnowLayer.SUN_SHARE` 0.045) was measured so
  sunlit ground keeps its colours; if SUN_* / SKY_* in main_3d.gd change, measure it again
  (WORKLOG 2026-11-03 "Light pass" has the method).

## Limits to know
- **Renderer: Compatibility (OpenGL).** No SSAO, SSIL, SDFGI or volumetric fog. Moving to
  Forward+ would allow soft corner shading but costs speed and needs re-checking every view;
  only on the user's word.
- **Resolution.** The game draws at 480 x 270 and scales up, so fine detail under about 1/16
  of a unit disappears; make shapes read at that size.
- **Day / night** is still a multiply tint over the picture (data/light.json), not real lights;
  house windows glow warm over it at night (`NightLights`, a screen overlay that skips
  windows behind solid buildings and is kept off figures in front), with warm dithered pools
  on the ground under lit windows and round the stone lanterns (data/light.json "pools").

## Roadmap (in order; tick and add the commit as each lands)
### 1. Scenery to the farmhouse's bar
- [x] The coop and barn (`coop_props.gd`, `barn_props.gd`): gable roofs as meshes
      (`Minka.gable`), thatch on the coop, kawara with tile rolls on the barn. (a60c0e1)
- [x] Village houses (`map_world.gd _village_house`): kawara roofs as meshes with curved
      ridge ends (`Minka.ridge`) and real tile rows. (4395016)
- [x] Village house variety: per-house `roof` (gable / hip: `Minka.hip`), `storeys` (2: a
      low upper floor over a tiled pent roof, upstairs windows lit at night) and `wall`
      (plaster / yakisugi / timber) fields in data/maps. (this commit) The roof snow's patch
      holes are fixed: snow tops fill at cover / `SnowLayer.TOP_FULL` (0.5), so roofs, lids
      and caps are whole from half cover up and only thin in patches when little lies; the
      ground keeps its equalised patches.
- [x] Shrine pieces: torii with curved kasagi and real cross section, the hokora, stone
      lanterns (`shrine.gd`: `Shrine.torii`, `hokora`, `stone_lantern`). (63b877f)
- [x] The seed stand, chest and bin by the farmhouse (`farm_props.gd`: `FarmProps.bin`,
      `chest`, `stand`). (this commit)
- [x] Interiors (house, homes, shops, clinic): wall and floor meshes in the same manner
      (`room_walls.gd`: RoomWalls; `MapWorld._shade_corners`). (b6f6098)
- [x] Room furniture as lit meshes (`room_props.gd`: RoomProps, all 22 kinds). (0f662b2)
- [x] The coop's and barn's insides as lit meshes (`coop_props.gd`, `barn_props.gd`: the feed
      trough with battens and a rope, nests with a lathe-turned straw bowl, the incubator's
      woven basket and lantern, the tawara feed sack, the hen hatch with its ramp; the fodder
      trough with its slatted rack, stalls with capped posts and tether rings, hay as bulging
      bound bundles with a pitchfork, the barn gate with braced leaves). Same places and
      heights as before, so the eggs and the feed AnimalLayer lays on them still sit right
      (test_maps `_stable_props`). (this commit)
      The stalls' straw bedding is a mesh too (`BarnProps._bedding`, this commit): in each of the
      six spaces between the partitions a low tapered pad 0.03 high in three straw tones, two or
      three lumps up to 0.05 and nine loose stalks lying flat near its edges; nothing in a stall
      rises above 0.05, so the animals and the items they stand by sit as before (test_maps
      `_straw_bedding`). The floor tile stays the straw under it.
- [x] The outdoor small props: well, jizo, woodpile and river rock as lit meshes
      (`outdoor_props.gd`: OutdoorProps). (fb9b1d8) Since 2026-11-06 also Ichiro's charcoal kiln
      (a clay dome, a stone-framed mouth, thumbprints about 0.2 cell wide over it; the new kiln half built from courses of clay bricks, then finished) and the jizo's new red bibs.
- [x] The rest of the countryside props and the festival decorations as lit meshes: the rice
      drying rack (lashed poles, paired rails, straw sheaves in fall), the kitchen garden (a
      planked bed with ridges and rows of greens, cabbages and spring onions, bare in winter),
      the board fence (`field_props.gd`: FieldProps); mats with their lunch, the stalls (counter,
      posts, a cloth roof with a valance and a split curtain), the judges' table, lantern strings,
      the drum stage and its drum, the moon offering, pampas, the standing lantern, New Year
      bamboo, the bonfire, the mochi mortar and the race flag (`festival_meshes.gd`:
      FestivalMeshes). Same cells, heights and lights as the boxes (test_maps `_field_props`,
      `_festival_meshes`). (this commit) the stalls' curtains, the race banner and the noren take the wind ("Wind by weather").
- [x] The festival stalls' wares as lit meshes (`stall_wares.gd`: StallWares, one vertex-coloured
      mesh a stall, colours from the items' looks): dango skewers on a lacquered tray and two
      standing in a cup, sakura mochi in their leaves on a plate, a side-handled teapot and cups of
      green tea; yakisoba heaped on an iron griddle with a spatula, shaved ice in footed glasses
      with syrup and a little flag, marble soda bottles in a tub of water with ice; wind chimes on a
      stand (their paper strips blow in the wind with the curtain), round paper fans in a block;
      roast chestnuts in a pan on a clay brazier, sweet potatoes on hot stones (one broken open);
      clay rabbits on a red cloth, moon lanterns; a bowl of year-end soba (fishcake, prawn, onion)
      with chopsticks and a stack of bowls, yuzu tea with the fruit; daruma (one eye painted in),
      omamori charms on a rack and a tray. Hot food steams (`StallWares.Steam`: pale lit puffs
      rising 0.2 and fading). Same slots along the counter as the pictures (moved to its front
      half and a little left, clear of the corner lantern) and no taller than 0.28, so the game's
      camera sees them under the curtain, whose hem went up from 1.17 to 1.25. An item with no
      mesh keeps its picture. The lights are unchanged. `house_model.gd --what=stalls` shows
      each selling stall near, from the game's angle. Test: test_maps `_stall_wares`. (this commit)
      The flat view's stalls still show the item pictures.
      (this commit) Lantern Night's two stalls that sell nothing are no longer bare: a stall prop
      may carry `"display": "goldfish"` or `"masks"` (data/festivals.json, `Festivals.DISPLAYS`,
      refused on anything but a stall). `StallWares.display` builds a goldfish-scooping tub (a
      hooped wooden tub with a blue floor, a see-through water disc, four goldfish as small
      lit meshes of their own swimming round on circles of their own and wiggling as they go, a
      glass bowl of spare fish, three paper scoops on a tray, a little cloth sign) and a two-tier
      stand of masks (our own fox, demon, round-faced, rabbit and tanuki masks, tilted back to
      look up at the street). Same limits as the wares: one lit vertex-coloured mesh on the
      counter's front half, under 0.28 high, clear of the corner lantern. The flat view draws a
      matching `festival:display_<id>:1x1` picture on the counter (FestivalView.display_key).
      `house_model.gd --what=stalls` renders them too. Tests: test_maps `_stall_wares`,
      test_festivals (`_flat_art`, the data check).
      The flat view's stalls show their wares too (2026-11-07, this commit): each item with a 3D
      look (`StallWares.LOOKS`, the one list; `FestivalView.ware_key`) is drawn as its own 8 x 12
      pixel picture `festival:ware_<name>:1x1` (`PlaceholderArt._ware`: skewers, bowls, griddle,
      glass, chimes, fans, daruma, charms ...) along the counter, semi-transparent steam puffs
      over the hot ones (`StallWares.STEAMING`); an item with no look keeps its item picture.
      Test: test_festivals `_flat_art`.

### 2. Nature
- [x] Trees: stylized round crowns (several lumps, lit and shaded) for broadleaf trees; pines
      with layered tiers; per season (blossom, green, red / gold, bare with snow). (578b60c)
      (this commit) Snow on bare branches: in winter on snowy outdoor maps, a thin lit sheet lies
      over the upper side of each limb and twig (`Trees.broadleaf(..., snow)`, `_branch_snow`),
      its amount driven by set_snow like the pads'; none without snow. Pines and the wood unchanged.
      The bamboo hill has six broadleaf trees now (data/maps/hill.json: three persimmons and three
      sakuras on free grass): red and gold in fall, bare with snow in winter.
      (this commit) Japanese maples (momiji): `Trees.broadleaf(..., "maple", ...)` with its own small
      layered crown (`_maple_crown`: a wide flat tier of five low lumps, a narrower tier of three, a
      cap), fresh green in spring, deep green in summer, vivid red with orange lumps
      (`MAPLE_FLAME`) in fall, bare with snow in winter (the shared bare form). Six on the hill, one each
      in Kaminoda and Sakurazaka (props `maple`; the flat view draws a red box like the other
      trees). The hill's trees were checked from the lookout (`--map=hill@top`): a maple stands
      in the left of the view, the rest are out of frame.
- [x] Bamboo: segmented culms with node rings, leaf sprays, swaying, by season, snow on the
      leaves (`OutdoorProps.bamboo`). (this commit) The wind follows the weather (data/wind.json,
      see "Wind by weather" in the table): in a storm the clumps lean further, sway faster and
      gust; in rain a middle sway; at calm the old wave. (this commit) The New Year bamboo
      (`FestivalMeshes.kadomatsu`: straw-bound tub with cord bands and frayed straw, three
      culms of different heights with node rings and slanted cuts, a straw wrap with cord,
      pine sprigs, a plum twig, snow where it snows) and the farm's bamboo fence
      (`OutdoorProps.fence_post` / `fence_cane` / `fence_rail`, built by `FarmWorld._make_fence`:
      eight-sided posts and thin canes with node rings and cut tops, horizontal rails, cord
      ties, snow on the caps and the upper rail) are lit meshes now, same footprint and
      heights (test_maps `_bamboo_pieces`). (this commit) In the wind the kadomatsu's pine sprigs and plum twig lean a little and the fence has a leafy side shoot on about one post in five that does; the posts, culms and tub stay still ("Wind by weather").
- [x] Grass tufts on grass cells (MultiMesh, a small wind sway in the shader). (this commit)
      (this commit) They bend harder in a storm and a gust comes through now and then, from the
      same wind (`wind` uniform, "Wind by weather" in the table). (this commit) They part round
      the farmer: tips within about a cell of the feet bend straight away and a little down,
      fully close in and easing out by a smoothstep, springing back as the farmer walks on
      (`scripts/world3d/parting.gd`: Parting, its GLSL `part_push` in the shader, the `pushers`
      array uniform fed each frame by `FarmWorld.set_farmer` from `Main3D._process`; numbers in
      data/wind.json "part"). The tufts' height share moved from the vertex colour to the UV:
      under the Compatibility renderer the MultiMesh's COLOR read black in the vertex shader, so
      the tips had never swayed. (this commit) The villagers and the dog part them too: their
      sprites join the group `Parting.GROUP`, and `set_farmer` feeds the shader up to `part.max`
      (8) pushers, the farmer first and then the nearest to them; pushes add but never bend a
      tip past `bend`, so the farmer alone looks as before.
- [x] Rice and tall crops as clusters of pixel sprites (the paddies, the field in summer).
      (this commit) Cucumber and tomato vines on stakes join them (two stakes a cell, fruit when ripe).
      stay one sprite. (this commit) Winter paddies: the cut rice stands as stubble in the same
      nine-hill layout (`stalk:rice:0:stubble`, short straw stalks a pixel apart, no rim), and where
      the water still stands between the rows a few flat grey-blue patches lie on the ground
      (`patch:paddy_water`, CropClusters.plant_water). Both fold away or vanish under snow lying on
      them, by the paddy's hold and the crops' own snow rule. Numbers in data/paddy.json. The rice and corn part round the farmer as the grass does
      (Parting; bend 0.22 against the grass's 0.18), so the farmer's legs show between the
      hills when standing in rice.
- [x] Water: a gentle moving surface for the pond and river (`water_surface.gd`: WaterSurface,
      a transparent sheet over the water cells, glints and troughs drifting over the pixel grid,
      lit like the ground). (this commit)
      Ripple rings (`WaterSurface.ripple()`, a uniform array of eight in the sheet's shader, one pixel
      wide, stepping out a pixel at a time, two fade steps, lit like the ground): a strong ring as the
      bobber lands and as a fish bites (then every 0.4 s), a gentle ring every 1.7 s while it waits
      (`Main3D._ring_bobber`). (this commit)
      Rain dimples (this commit): in rain and storm the pond, the village water and the river show many
      small rings popping at random spots (a hash of the cell, a time slot and the clock in the same
      shader, no use of the bobber's eight slots; a dimple grows 0..3 px in its cell, two fade steps),
      more and quicker in a storm (`data/weather_fx.json` dimples: density, life per look; none in
      sun, snow, blizzard or indoors); `Game.dimple_style()`, `FarmWorld.set_rain`, `WaterView.set_rain`.
      Still open: no ring at the farmer's feet (the farmer never wades: water cells are blocked).
      [x] Winter ice (this commit): in winter outdoors the pond, the village water and the river get
      thin ice along the shore (`WaterIce`, scripts/world3d/water_ice.gd, one piece of shader code
      pasted into both the 3D sheet and WaterView): 2..4 px in from the bank line, ragged (value noise
      every 4 px), pale blue-white with a one-pixel darker rim where it meets the open water, short
      diagonal cracks and frost specks, lit like the ground in 3D. With snow lying, 2 x 2 px flecks of
      snow on it (`snow` 0.85 x the cover, more near the shore). Each 3D quad carries the land round
      its cell (UV2.x, 8 bits); the flat view keeps it in its mask's red channel. The middle of every
      cell stays open (8 px from any side), so the bobber floats on water and fishing is untouched;
      glints, the bobber's rings and rain dimples are drawn on open water only. Numbers and colours in
      `data/snow_cover.json` "ice" (seasons, width, alphas, cracks, frost, snow, colours);
      `Game.ice_style()`, `FarmWorld.set_ice`, `WaterView.set_ice`; none in spring to fall or indoors.
      The ice grows over the winter (`ice.grow`: a day curve thin at the start, widest about day 22, receding
      to the end, +20% under snow cover, capped at 4.4 px; `WaterIce.grown_width`), in both views.
      Tests: test_maps `_water_ice` (and the scene: winter ices the farm pond, spring thaws it),
      test_view2d `_water` / `_check_water`.
      (this commit) Flat view: `WaterView` (scripts/world/water_view.gd), a Sprite2D over the water
      cells of FarmView (the pond) and MapView (the village pond, the river), under the objects. One
      pixel per map pixel, alpha on the water pixels only: a land side keeps its bank and foam line
      still (the sheet starts 3 px in, as in 3D). The shader is the 3D sheet's pattern on the pixel
      centres (glints and troughs drifting, the same speeds, thresholds and colours), with alphas
      0.3 / 0.2 instead of 0.5 / 0.32, since the flat view has no sun term to darken them. The
      constants are copied, not read from data. Ripple rings (this commit): `WaterView.ripple(pos,
      strong)` takes map pixels (a cell's centre is (cell + 0.5) x 16) and fills one of eight slots
      in the same shader loop as 3D (14 px a second, a strong ring 1.3 times that to 34 px, a gentle
      one to 22 px, one pixel wide, two fade steps, the same 0.6 / 0.3 alphas in `ring_color`). The
      bobber drives them from `main_2d.gd` `_ring_bobber`, the 3D timing: a strong ring as it lands
      and as a bite starts, then 0.4 s between strong ones in a bite, a gentle one every 1.7 s while
      it waits. Test: test_view2d `_water` (the sheet covers the water pixels only on the farm pond
      and the town's water, the shader uses TIME) and `_ripples` (a call fills a slot, the rings
      expire); test_maps keeps its snow checks off the sheet.
- [x] Footprints in lying snow (this commit): while `Game.snow_cover` is at least `min_cover` (30) out
      in the open, the farmer, every villager and the dog leave small pressed prints, left and right
      in turn (`side` 0.11 off the line, a step of 0.55 cells apart, turned along the walk), a cool
      blue-grey dent (`color` 5f76ab, alpha 0.95) lit like the ground. `Footprints` (scripts/footprints.gd)
      holds the rules both views share: walkers fed as {id: cell position} (the 3D view reuses
      the walker list `FarmWorld.set_farmer` collects for Parting: the farmer and Parting.GROUP; the flat
      view feeds the farmer, VillagerView.feet() and the dog), a ring of at most `cap` (160) prints, ages
      in game minutes and gone after `life` (90), four times as fast while snow falls (`snowing_rate`:
      fresh snowfall fills them), none on ground that holds under `min_hold` of the snow (tilled and
      wet soil, water), none across a jump (a door), none indoors or in the mine. Cleared on a map
      change (`Main3D._enter_map`, a new view in 2D) and on a new day. 3D: `FootprintLayer`
      (scripts/world3d/footprint_layer.gd), one MultiMesh of flat quads at y 0.025 with a shader that draws
      a pixel-stepped sole and the ground shader's light (`SnowLayer.SUN_SHARE`), no shadows;
      flat: `FootprintView` draws a toe block and a heel block. Numbers: data/footprints.json.
      Screenshot: `--demo --season=winter --map=town@shrine --snow=80 --footprints`
      (a trail already pressed). Tests: test_maps `_footprints`, test_view2d `_footprints`.
      Then (2026-11-07): prints read the snow noise: a print is made only where snow lies at that spot
      (`Footprints.ground_snow`, `SnowLayer.lies` / `noise_at`, the GDScript copy of the shader's snow_at),
      the 3D shader discards a print's pixels on bare or rim pixels (COLOR.r carries the ground's hold),
      the flat view skips a print the snow has thinned from; size 0.38 x 0.58, colour 506aa8 for the 480 x 270 picture.

### 3. Light and atmosphere
- [x] Night: real warm lights at lanterns, windows and the festival stalls, the tint lighter.
      Done so far (FEEDBACK item 6): a darker deep blue night with a smooth dusk / dawn in
      data/light.json, and the house windows and shoji doors glow warm (NightLights overlay).
      Then warm pools on the ground under windows and round the stone lanterns, the
      lanterns' fire boxes glowing, the glow kept off figures in front.
      Then real lights: NightLamps, at most 8 OmniLight3Ds without shadows at the lit windows,
      stone lanterns and festival lights nearest the view's middle (data/light.json "lamps"),
      their colour divided by the tint so they land warm; the ground, water and grass left to
      the drawn pools; the night blue a touch lighter (46529a); the festival's lights and
      stalls lighting the ground in both views (NightLights.festival_pools). (this commit)
      Pale plaster takes them too (this commit): the tint multiplies the picture after the
      lights, so nothing under it can be brighter than the tint (46529a) and near-white
      plaster had no room left for the lamps. NightLights now adds a warm wash
      (`wall_wash`, data/light.json "pools" → "wall") on the wall round every lit window and
      shoji door over the tint, like the pools, in its own pass after the copy; its shader
      keeps it to pale pixels (the copy's blue over the tint's blue between pale_from and
      pale_full), so plaster and paper take it and dark boards, posts, roofs and the ground
      (lit by the real lamps and the pools) do not; the pane itself is left out; figures in
      front are drawn back. The night sun, the tint, the ground and the day are unchanged.
      Earthen and yakisugi walls take them too (this commit): their red already sat at the
      tint's cap and the pale wash skipped them, so `NightLights.finish_wash` (data/light.json
      "pools" → "wall" → "finishes") adds their own: a soft warm glow on the timber look's
      earthen plaster (`earth`), a faint warm-grey sheen on the charred boards (`board`), so
      they stay dark wood. The pieces are cut to the material (LitSpots.wall_look: clear of
      the skirt, rails and beam, within the wall, round every front post) and its shader keeps
      them to warm, not pale pixels (red over the tint above green and blue), so roofs, posts,
      the ground, the plaster's result, figures and the day are unchanged.
      Sprites take the world's light (this commit): they stay unshaded (crisp, as drawn) but
      take a share (0.45) of the sun's colour by the clock, golden morning and evening, plain
      at noon, at night, in rooms, mines and under cloud, only ever holding green and blue back
      (SpriteLight, data/light.json "sprites"; the crop clusters too); and at night a figure
      near a lit window, door, stone lantern or festival light is drawn back over the tint with
      warm light added in proportion to its own colours (NightLights' last pass, "Warmth"), so
      it reads warm by the light and stays blue in the dark. Sun-and-shadow on the sprites was
      left out: Occluders' boxes are the only cheap query and hold the houses but not the trees
      or the roofs' outline, so it would not match the shadows on the ground.
      The field takes the same night lift (2026-11-07): crop sprites, the CropClusters plants,
      items lying on the ground, forage, eggs and the other unshaded field sprites near a light
      are drawn back in the Warmth pass, before the figures (so a figure in front covers them),
      by the same rule and numbers (`SpriteLight.field_lifts`, measured at the middle of each
      picture; worked out once a game minute or when the field changes, only projected per
      frame), their own pixels times the warm colour, so the pool under them is not counted
      twice. A cluster plant's quad does not follow its sway (well under a pixel in calm air).
      Still open: stone lanterns wash no walls (none stands by one); the overlay knows no
      depth, so a lit plant behind another plant or a fence is drawn over it where they overlap.
      The festival decorations are lit meshes since
      FestivalMeshes / StallWares; only what gives light (lantern paper, flames) is unshaded.
- [x] Morning and evening sun colour and angle following the clock (data/light.json "sun",
      `Game.sun_light`, `Main3D._aim_sun`: low orange sun from the lower left at 5:30, golden
      morning, high plain noon, golden evening from the upper left, back to the plain night
      sun once the dusk tint has put the shadows out; rooms, mines and clouded days keep the
      plain colour). (this commit)
      The sky colour behind the land follows the clock outdoors too (this commit:
      data/light.json "background", `Game.sky_color`, `Game.sky_background`, applied by
      `Main3D._update_tint`): dawn purple to peach, the day blue 8fc6e8 at noon, golden at
      17:30, mauve at dusk, deep blue at night; greyer and darker under cloud. Rooms and mines
      keep their own background. The sky shows only over the rim near the north and west
      edges, above the mountain backdrop (below); in the middle of a map the land hides it. The sprites
      (unshaded) take a share of the sun's colour since "Sprites take the world's light".
- [x] Optional: a distant mountain backdrop and light haze far off. (this commit:
      data/backdrop.json, scripts/world3d/backdrop.gd, README → Camera) On the seven outdoor
      maps the land past the north and west edges stops at a 3-cell rim with a thinner wood;
      two ridge layers stand far out and below the ground's level, so the fixed medium lens
      (16° down at the frame's top) looks over the rim onto them from near those edges, the
      sky's colour above the peaks. Flat coloured by season, hazed with the sky by the clock
      (the far layer more), feet fading into it, snow caps in winter. Not in rooms or the mine.

- [x] Hearth smoke at meal times: thin pale smoke rising from the farmhouse's ridge and every
      village house's roof, 6:00-8:30 and 17:00-19:30 by the clock, fading in and out at each
      end; the puffs drift with the wind and a storm buries them (HearthSmoke,
      scripts/world3d/hearth_smoke.gd; numbers in data/smoke.json). Outdoor maps only, separate
      nodes (not in occlude or MeshCache). The flat view has it too (SmokeView, scripts/world/smoke_view.gd:
      pixel puffs climbing from the same vents seen from above; the timing, fade, storm rule, vents
      and a puff's path are SmokeRules, scripts/smoke_rules.gd, shared by both views).
      (this commit)

### 4. Characters (needs the user's decision on who draws)
- [x] Larger, more detailed farmer and villager sprites, four or eight directions. (d2d8064:
      the user asked the agent to refine the code-drawn placeholders for now; real art later.
      `scripts/art/figure_art.gd` (FigureArt): 24 x 32 figures (were 16 x 24) about 2.6 heads
      tall, drawn part by part with an outline round each part, light from the upper left. Four
      directions from two drawings (front three-quarters to the lower left, back to the upper
      left, mirrored for Right / Up); eight would need diagonal facings, which the grid rules
      don't have. The farmer in an indigo noragi with kasuri flecks and a white collar band, a
      straw rope belt, slate monpe gathered at the ankle, jika-tabi, a red tenugui knotted
      behind and a straw hip basket. Villagers: kimono with obi, cord and drum bow, happi with
      a collar band and a crest on the back, shirt and shorts; hair bun with a pin, short, a
      hachimaki, long and tied, a wide straw hat; `build` in the look: elder (stooping a
      little: Tome, Kiku, Genzo) or child (shorter: Kota, Nana). 3D sprites at
      `FarmWorld.FIGURE_PX` 0.04, so the farmer stands about 1.17 units (was 1.08), a pixel
      about 1.5 screen pixels at the medium lens. Still open: no eight directions. Flat view: the farmer is the same FigureArt
      picture now (`Player`: a Sprite2D "Figure", feet 2 px below the spot like the villagers', FarmerAnim
      picking pose and frame: walk, run, tired, hold, fish, eat, drink); the carried item, the rod line,
      the lantern and the "!" are placed from the picture's rows. Test: test_view2d `_figure`.)
- [x] Animals in the same style. (36d42c6: `scripts/art/animal_art.gd` (AnimalArt) draws hens, chicks, Japanese Black cows and calves, cream-wool sheep, shorn sheep, lambs and the shiba-like dog at twice the farmer's pixel density (`AnimalArt.SCALE`; the layer sets `pixel_size = PX / SCALE`, so world sizes stay), in three tones lit from the upper left, with a warm dark rim. Keys `animal:<kind>:<pose>:<frame>[:<dl|dr|ul|ur>]`: four facings for the diagonal camera (front, back; right = left mirrored), the whole figure tilted a little so the near end stands lower; `AnimalArt.facing_of` turns a step into a facing. States kept: idle (head lift, ear flick), peck / graze, walk (diagonal leg pairs), sick (lying, dull, eyes shut), the dog sitting, wool or shorn, young. Only the dog held in the arms keeps its small old picture. Flat view: `AnimalView._draw_animal` draws them at half size. Test: test_animals `_animal_art`.)
- [x] Keep the blob shadows, or switch to real sprite shadows (test how billboards cast). (f261048: real shadows won; `SpriteShadow`, data/light.json "sprite_shadows", see the Done table)

### 5. Finish
- [x] UI pass in the same warm style (paper, wood) at the new look. (this commit: `scripts/ui/ui_style.gd` (UiStyle) is the one source of panels and ink colours; the frame art `ui:frame:paper|wood` is now a 32 x 32 nine-patch with a tiling 24 x 24 centre: washi speckle and long fibres, wood grain and plank seams; checked by test_menu `_shared_style`)
- [x] Trailer-ready screenshots: a set of fixed views to compare before and after each step. (this commit: data/showcase.json, tools/showcase.py, README → Showcase)

## How to continue
1. Read this file, then the top WORKLOG entries.
2. Take the first unticked item above; ask the user first if it says so.
3. Before changing anything, take "before" screenshots of the views it touches
   (`--write-movie`, AGENTS.md → Screenshot) to compare with afterwards.
4. Build it, check it in all the conditions listed above, add tests for its rules.
5. Tick it here with the commit hash, add the WORKLOG entry, commit.
