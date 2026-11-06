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
| Shrine pieces | 63b877f | `scripts/world3d/shrine.gd` (Shrine): the torii with tapered posts on black footings, a plaque, and the shimaki and black kasagi as beams sweeping up 0.16 to their ends; the hokora on a two-step stone base under a `Minka.gable` board roof with chigi and katsuogi, vermilion doors, a shimenawa with paper streamers; a six-sided Kasuga-style stone lantern turned with `Shrine.lathe` (flat facets), lit windows on the two faces the camera sees, corners turned up. Minka's mesh helpers (`quad`, `tri`, `beam`, `plain`, `add_mesh`) are public for this. `house_model.gd --what=shrine`. |
| Bin, chest, seed stand | a3f4619 | `scripts/world3d/farm_props.gd` (FarmProps), all lit: the bin a cedar box splayed a little wider at the top on runners, corner battens, a straw rope with a knot, hanging ends and a paper tag, a bevelled plank lid with battens; the chest a tansu with drawer fronts, iron pulls, corner plates wrapping onto the +x face, a side handle, a bevelled lid; the stand a `Minka.gable` board roof (front eave 1.45) on posts with tie beams, king posts, ridge beam and board, a counter, three turned burlap seed sacks with a neck cord and seeds showing, an honesty box with a coin slot, the noren (shorter, so the sacks show) and a price board (`build:stand_sign`). `FarmProps.block` = a tapered box with flat normals and world-unit UVs; `FarmProps.Parts` = one SurfaceTool per material. `house_model.gd --what=props`; `--map=farm@bin` in the game. |
| Interiors | b6f6098 | `scripts/world3d/room_walls.gd` (RoomWalls) builds every indoor "wall" cell as lit meshes: the back walls a timber frame (posts every other cell and at the inner corner standing 0.04 proud, board skirting under a rail, recessed plaster or, with `walls: "board"` (coop, barn), cedar boards, a nageshi beam at 1.28, a head beam), a shoji window in a dark frame with a plank sill every fourth cell of a plaster wall; the front walls a low board sill (0.27) on the room side of their cells with post stubs and stubs each side of the door; a step edge (agari-kamachi) where boards or tatami meet the earth and a flat shoe stone below the door's step. The floor picture darkens softly along the walls (`MapWorld._shade_corners`, more under the tall back walls), standing in for the ambient occlusion the renderer lacks. Lit, the back wall (sunward) and the left wall (in shade) now read apart. |
| Furniture | 0f662b2 | `scripts/world3d/room_props.gd` (RoomProps) builds all 22 kinds of room furniture (the farmhouse, homes, shops, clinic, smithy) from `FarmProps.block` and `Shrine.lathe` in lit materials, replacing MapWorld's boxes and cylinders (mostly unlit) and HomeProps (removed): a two-section tansu with drawer fronts, warabite pulls, corner plates and a sliding door; a turned chabudai with a teacup and pot; a kamado narrowing to its lip with an arched fire mouth, a flanged rice pot and logs; a mizuya with shoji lattice; a futon with a puffy quilt and collar; a counter with battens, a bell on a cushion and an account book; shelves of boxes and turned jars; tawara on their sides with rope bands; the forge's hood narrowing to the chimney and a box bellows; an anvil on a stump; tool racks (on the left wall when longer in z); an irori with a turned kettle and fish catch; the butsudan's doors swung open; a zig-zag byobu. Only light-givers stay unshaded (`RoomProps.GLOWS`: the andon's paper, embers, fire, a candle flame) via `Parts.glow`. `_placed` turns a part (append_from with a transform). |
| Trees | 578b60c | `scripts/world3d/trees.gd` (Trees), all lit: `Trees.broadleaf` (persimmon, sakura) a lathe trunk with limbs and a crown of six faceted lumps (seven-sided `_lump`s, the four round the middle darker, the top one lighter, each turned at random by the seed), leaves by season from `Trees.LEAVES` (the persimmon's fall red deep enough for its fruit to show), bare in winter with five limbs and twigs, persimmons hanging on the twig ends into the snow, petals under a cherry in bloom; `Trees.pine` a trunk and four tiers of low faceted cones, darker below, a `garden` pine (the village's) leaning with its tiers set off to alternate sides on short limbs, the wood's straight; snow on each tier's top (`Parts.SNOW`) where snow lies. Used by MapWorld (`pine`), CountryProps (`persimmon`, `sakura`), FestivalProps (the cherries) and Surroundings: the wood past the edge is three pine shapes in MultiMeshes (`Parts.meshes()` / `Parts.material`), turned per cell, its snow driven by `set_snow` (it had none). |
| Grass tufts | (this commit) | `scripts/world3d/grass_tufts.gd` (GrassTufts): one MultiMesh of a five-blade tuft (one triangle a blade, both faces) on the grass cells: the farm's bare untilled ground (replanted when the field changes, skipped when no grass changed), outdoor maps' free grass with no prop, and the apron past the edge. Up to two a cell, 70% kept, nudged, turned, sized and shaded by a hash of the cell so they never move. The shader sways the tips (height share squared, phase by place) and lights them as the ground (normal up on both faces, the sun only at `SUN_SHARE`); the base 80% of the tip colour, the tip by season (fresh, deep, straw, dry). Each tuft carries its cell's snow hold and folds away where the ground under its root is white (SnowLayer's noise). |
| Rice and tall crops | (this commit) | `scripts/world3d/crop_clusters.gd` (CropClusters): rice and corn grown past the sprout (growth 2 and 3, looks "grain" and "stalk") stand as several small pixel plants a cell instead of one sprite: nine rice hills in three rows (young: six smaller ones in two rows, the ground showing between), three corn stalks. Each picture (`stalk:<id>:<growth>:<ripe|growing>:<variant>` in PlaceholderArt, three variants leaning the blades or setting the leaves another way, rimmed in a deep leaf shade instead of the black outline) is one MultiMesh of camera-facing quads (the shader billboards each instance at its own size, flips half, shades each a little, sways the tips); places, sizes, flips and variants by a hash of the cell. Ripe rice goes straw-stemmed with gold ears bowing. Unshaded like the crop sprites. The village paddies (Kaminoda) grow rice by season (`CropClusters.PADDY`): young in spring, tall and green in summer, ripe in fall, none in winter; their plants carry the paddy's snow hold and fold away under white ground. The flat view keeps one sprite a cell. |
| Sun by the clock | (this commit) | data/light.json "sun": keys of [minute, elevation, yaw, colour, energy], read by `Game.sun_light()` (`sun_at`, `sun_plain`, `sun_direction`) and put on the DirectionalLight3D by `Main3D._aim_sun` each game minute. A low orange sun from the lower left at 5:30, golden through the morning, high (60°) and plain at noon, golden from the upper left in the evening, so long shadows fall up-right in the morning and down-right in the evening and are short at noon. It eases back to the plain fixed sun (48°, -40°, SUN_COLOR) only after the dusk tint has put the shadows out, so the night is unchanged. Energy stays SUN_ENERGY (the ground's SUN_SHARE holds); clouded weather keeps the plain colour; rooms and mines keep the plain sun. |
| Outdoor props, bamboo | (this commit) | `scripts/world3d/outdoor_props.gd` (OutdoorProps), all lit, no boxes or cylinders. Bamboo: a clump is three or four culms (6-sided tubes bowed in two pieces, 2.2..2.9 high, tilting a little apart) with a node ring every 0.3 or so, five-leaf sprays on a twig at the upper nodes and a seven-leaf plume at each tip (long double-sided diamonds, drooping), colours by season (`OutdoorProps.BAMBOO`: fresh in spring with husked shoots at the foot, deep in summer, olive with fallen leaves in fall, dull in winter), snow skins on the upward leaves where snow lies (`Parts.SNOW`'s top shader, one material for the whole map). A clump is ONE mesh with colours on the vertices (`vertex_color_use_as_albedo`, so it still fades as one for the Occluders), built once per season / snow / look (8 looks picked by the cell) and shared; each cell turns it by its own yaw. `OutdoorProps.Sway` (a node in the world) leans each clump about its foot, two slow waves out of step, a phase by cell, 0.028 rad at most. Well: a ten-sided curb in three courses with a lighter rim and dark water, timber posts, a windlass with crank, rope and a hanging bucket, under a `Minka.gable` board roof. Jizo: a two-step block, a robed lathe body, a round head, a red cap, collar and bib. Woodpile: split logs (bark prisms with pale cut ends) in four rows under a plank lean-to sloping to the front, timber posts, snow on the roof. River rock: two faceted boulders (dark and wet low, lighter and sometimes mossy on top) in a ragged ring of foam, snow on the upward facets. |

## How the pieces are made (keep to these)
- **Scale.** 1 cell = 1 world unit; textures are 16 px a unit, nearest filtering. A 24 px
  farmer is about 1.1 units tall. Doors and eaves must clear the farmer (front eaves at 1.45
  or more).
- **Meshes in code.** Build with SurfaceTool as in `scripts/world3d/minka.gd` (`roof` for a
  hip roof, `gable` for a gable roof, `FarmProps.block` for tapered boxes and bevelled lids, thatch or kawara with tile rolls, `ridge` for a tiled
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
  (`--what=coop` / `--what=barn` / `--what=village` / `--what=shrine` / `--what=props` for those; add a `CENTERS` entry and a builder for more).
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
      ridge ends (`Minka.ridge`) and real tile rows. (4395016) Still open: more variety
      (a hip roof on some, a second storey, a different wall), and the roof snow shows the
      top shader's patch holes (as before; the snow shader, not the roof).
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
      Still open: the stalls have no straw bedding mesh (the floor tile is the straw).
- [x] The outdoor small props: well, jizo, woodpile and river rock as lit meshes
      (`outdoor_props.gd`: OutdoorProps). (this commit) Still open: the other countryside
      props in `country_props.gd` (drying rack, garden, board fence) and the festival props
      still use boxes.

### 2. Nature
- [x] Trees: stylized round crowns (several lumps, lit and shaded) for broadleaf trees; pines
      with layered tiers; per season (blossom, green, red / gold, bare with snow). (578b60c)
      Still open: no snow on bare branches.
- [x] Bamboo: segmented culms with node rings, leaf sprays, swaying, by season, snow on the
      leaves (`OutdoorProps.bamboo`). (this commit) Still open: the sway is one gentle wave
      and doesn't grow in a storm; the New Year bamboo and the farm's bamboo fence stay boxes
      and cylinders.
- [x] Grass tufts on grass cells (MultiMesh, a small wind sway in the shader). (this commit)
      Still open: the tufts don't part round the farmer or bend harder in a storm.
- [x] Rice and tall crops as clusters of pixel sprites (the paddies, the field in summer).
      (this commit) Still open: the other tall crops (cucumber and tomato vines on stakes)
      stay one sprite; the paddies have no stubble or water showing in winter beyond the
      ground picture; the plants don't part round the farmer.
- [x] Water: a gentle moving surface for the pond and river (`water_surface.gd`: WaterSurface,
      a transparent sheet over the water cells, glints and troughs drifting over the pixel grid,
      lit like the ground). (this commit)
      Still open: no ripple ring round the bobber or the farmer's feet; the flat view's water
      is still the still tile; no frozen water in winter (the game has none).

### 3. Light and atmosphere
- [ ] Night: real warm lights at lanterns, windows and the festival stalls, the tint lighter.
      Done so far (FEEDBACK item 6): a darker deep blue night with a smooth dusk / dawn in
      data/light.json, and the house windows and shoji doors glow warm (NightLights overlay).
      Then warm pools on the ground under windows and round the stone lanterns, the
      lanterns' fire boxes glowing, the glow kept off figures in front.
      Still open: real lights / a lighter tint, festival stalls lighting the ground.
- [x] Morning and evening sun colour and angle following the clock (data/light.json "sun",
      `Game.sun_light`, `Main3D._aim_sun`: low orange sun from the lower left at 5:30, golden
      morning, high plain noon, golden evening from the upper left, back to the plain night
      sun once the dusk tint has put the shadows out; rooms, mines and clouded days keep the
      plain colour). (this commit)
      Still open: the sky colour behind the land (background) does not follow; the sprites
      (unshaded) take only the tint, not the sun's colour.
- [ ] Optional: a distant mountain backdrop and light haze far off.

### 4. Characters (needs the user's decision on who draws)
- [ ] Larger, more detailed farmer and villager sprites, four or eight directions.
- [ ] Animals in the same style.
- [ ] Keep the blob shadows, or switch to real sprite shadows (test how billboards cast).

### 5. Finish
- [ ] UI pass in the same warm style (paper, wood) at the new look.
- [ ] Trailer-ready screenshots: a set of fixed views to compare before and after each step.

## How to continue
1. Read this file, then the top WORKLOG entries.
2. Take the first unticked item above; ask the user first if it says so.
3. Before changing anything, take "before" screenshots of the views it touches
   (`--write-movie`, AGENTS.md → Screenshot) to compare with afterwards.
4. Build it, check it in all the conditions listed above, add tests for its rules.
5. Tick it here with the commit hash, add the WORKLOG entry, commit.
