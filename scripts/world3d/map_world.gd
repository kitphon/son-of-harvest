class_name MapWorld
extends FarmWorld
## A map other than the farm in 3D (data/maps): its ground tiles laid into one texture, walls
## as boxes and its props (furniture, village houses, the shrine) built from the same
## placeholder surfaces as the farm buildings. Same units as FarmWorld: 1 unit = 1 cell.
##
## Indoors the camera looks in from +x / +z (the same fixed field camera), so only the back
## walls (top row, left column) stand full height; the front ones are cut down to a sill
## (RoomWalls builds them, and the step edges of the raised floors).
##
## Outdoors snow lies as on the farm (SnowLayer: the ground by tile kind, snow tops on the
## roofs, the shrine, the lantern caps and the rock); under a roof (rooms, the mine floors)
## there is none, whatever Game.snow_cover says.

const VERMILION := Color("c8442c")

var map: MapData


func build(m: MapData) -> void:
	for step in build_steps(m):
		step.call()


## The build as steps, each a few milliseconds or so, to be called in order (build runs them
## all at once; Main3D runs a neighbour map's over idle frames, ahead of the visit).
func build_steps(m: MapData) -> Array[Callable]:
	map = m
	var steps: Array[Callable] = [_make_tile_ground, _make_walls]
	for p in map.props:
		steps.append(occlude.bind(_prop.bind(p)))
	if not map.indoor:
		steps.append(_make_village_smoke)
	if not map.sheltered and not map.indoor:
		steps.append(func() -> void: add_child(DriftLayer.new(map)))   # petals, leaves, fireflies
		steps.append(func() -> void: add_child(PuddleLayer.new(map)))   # puddles on the paths in rain
	if not map.sheltered and not map.indoor:
		steps.append(_make_grass)
	if not map.sheltered:
		steps.append(_make_edges)
	return steps


## What the map's own look depends on (its tiles, doors, props, walls, inside or not, snow):
## names the kept ground picture and walls (MeshCache).
func _shape_id() -> String:
	return "%s|%d|%d|%d|%s|%s|%s" % [map.id, map.tiles.hash(), str(map.doors).hash(), str(map.props).hash(),
		map.walls, map.indoor, SnowLayer.map_has_snow(map)]


## Hearth smoke (HearthSmoke) from the ridge of every village house on an outdoor map. Its own
## nodes, not inside occlude or MeshCache: the houses' meshes stay as they are.
func _make_village_smoke() -> void:
	for p in map.props:
		if str(p.kind) != "village_house":
			continue
		var r := Rect2(Vector2(p.cell), Vector2(p.size))
		var at := HearthSmoke.village_vent(r, LitSpots.village_style(p))
		add_child(HearthSmoke.new(int(r.position.x) * 7 + int(r.position.y) * 13, at))


## Rock, door thresholds and a room's walls (RoomWalls), kept a run by the map's shape.
func _make_walls() -> void:
	MeshCache.build(self, "walls|" + _shape_id(), func() -> void:
		for y in map.h:
			for x in map.w:
				var c := Vector2i(x, y)
				if map.tile(c) == "rock_wall":
					_rock_wall(c)
				elif map.is_solid(c) and not map.door_at(c).is_empty() and map.prop_at(c).is_empty() and map.indoor:
					_box(Vector3(1, 0.06, 0.9), Vector3(x + 0.5, 0.03, y + 0.5), flat_material(Color("4a3424")))   # threshold
		RoomWalls.build(self, map))


## Grass tufts on the open grass and rice in the paddies (outdoors).
func _make_grass() -> void:
	var grass: Array[Vector2i] = []
	for y in map.h:
		for x in map.w:
			var c := Vector2i(x, y)
			if map.tile(c) == "grass" and map.prop_at(c).is_empty() and not map.is_solid(c):
				grass.append(c)
	var snowy := SnowLayer.map_has_snow(map)
	var hold_rules: Dictionary = Game.snow_rules
	add_tufts()
	plant_tufts(grass, func(c: Vector2i) -> float: return SnowLayer.map_hold(map, c, hold_rules) if snowy else 0.0)
	_plant_paddies(func(c: Vector2i) -> float: return SnowLayer.map_hold(map, c, hold_rules) if snowy else 0.0)


## The land past the map's edges (and the far ridges where they stand).
func _make_edges() -> void:
	var rules: Dictionary = Game.snow_rules
	add_surroundings(map.w, map.h, func(c: Vector2i) -> String: return map.tile(c),
		func(c: Vector2i) -> float: return SnowLayer.map_hold(map, c, rules), map.id)


## Rice in the paddy cells with no prop, by the season (CropClusters.paddy_key: the stubble in
## winter); in winter the water patches between the rows too (CropClusters.water_on).
func _plant_paddies(hold_at: Callable) -> void:
	var season := Game.season_name()
	var cells := MapView.paddy_cells_in(map, season)   # the same cells the flat view draws rice in
	if cells.is_empty():
		return
	add_crops()
	crops.plant(cells, hold_at)
	if CropClusters.water_on(season):
		crops.plant_water(cells.keys(), hold_at)


## The tiles as one picture under the whole map (unshaded, like the farm ground).
func _make_tile_ground() -> void:
	var picture := ground_picture()
	var mat: Material
	if SnowLayer.map_has_snow(map):
		var snow := ImageTexture.create_from_image(SnowLayer.map_mask_image(map, Game.snow_rules))
		mat = SnowLayer.ground_material(picture, snow)
		_snow_mats.append(mat)
	else:
		var flat := flat_material(Color.WHITE)
		flat.albedo_texture = picture
		flat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat = flat
	var plane := PlaneMesh.new()
	plane.size = Vector2(map.w, map.h)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = mat
	ground.position = Vector3(map.w / 2.0, 0, map.h / 2.0)
	ground.layers = NightLamps.GROUND_LAYER   # the night's lamps leave it to the drawn pools
	add_child(ground)


static var _grounds := {}   # map id and tiles -> the ground picture (the same every visit)

## The map's tiles laid into one picture (indoors with the corners shaded), kept a run.
func ground_picture() -> ImageTexture:
	var season := Game.season_name()
	var id := "%s|%d|%s|%s|%d" % [map.id, map.tiles.hash(), map.indoor, season, str(map.props).hash()]
	if not _grounds.has(id):
		var keys := ground_keys(map, season)
		var img := Image.create(map.w * T, map.h * T, false, Image.FORMAT_RGBA8)
		for y in map.h:
			for x in map.w:
				var tile := PlaceholderArt.image(keys[Vector2i(x, y)])
				img.blit_rect(tile, Rect2i(0, 0, T, T), Vector2i(x * T, y * T))
		if map.indoor:
			_shade_corners(img)
		_grounds[id] = ImageTexture.create_from_image(img)
	return _grounds[id]


## The ground key of every cell as the 3D view draws it (ground_picture): MapView.ground_key_at
## with the paddy cells that grow rice, so those take the flat view's calm ground (drained mud in
## winter, still water otherwise). Other paddy tiles keep the painted tile.
static func ground_keys(m: MapData, season_name: String) -> Dictionary:
	var keys := {}
	var paddies := MapView.paddy_cells_in(m, season_name)
	for y in m.h:
		for x in m.w:
			var c := Vector2i(x, y)
			keys[c] = MapView.ground_key_at(m, c, season_name, paddies)
	return keys


## The renderer has no ambient occlusion, so the floor darkens softly where it meets the
## walls, more under the tall back walls than the low front sills (indoor maps only).
func _shade_corners(img: Image) -> void:
	const REACH := 7.0   # pixels
	var sides := [[Vector2i.UP, 0.3], [Vector2i.LEFT, 0.3], [Vector2i.DOWN, 0.14], [Vector2i.RIGHT, 0.14]]
	for y in map.h:
		for x in map.w:
			var c := Vector2i(x, y)
			if map.tile(c) == "wall":
				continue
			var walls: Array = []   # the sides of this cell that meet a wall
			for i in sides.size():
				var o: Vector2i = sides[i][0]
				if map.in_bounds(c + o) and map.tile(c + o) == "wall":
					walls.append(i)
			if walls.is_empty():
				continue
			for py in T:
				for px in T:
					var shade := 1.0
					for i: int in walls:
						var d := float([py, px, T - 1 - py, T - 1 - px][i])   # pixels from that edge
						var k := maxf(0.0, 1.0 - (d + 0.5) / REACH)
						shade *= 1.0 - float(sides[i][1]) * k * k
					if shade < 1.0:
						var at := Vector2i(x * T + px, y * T + py)
						var col := img.get_pixelv(at)
						img.set_pixelv(at, Color(col.r * shade, col.g * shade, col.b * shade, col.a))


## Bare rock (the mine, the cliff over its mouth). The camera looks in from +x / +z, so rock
## with open ground behind it (above or to the left in the map) would hide that ground: it is
## only a low ridge of rubble; the rest stands as tall, uneven blocks of stone.
func _rock_wall(c: Vector2i) -> void:
	var at := Vector3(c.x + 0.5, 0, c.y + 0.5)
	var low := false
	for o in [Vector2i.UP, Vector2i.LEFT, Vector2i(-1, -1)]:
		var b: Vector2i = c + o
		low = low or (map.in_bounds(b) and map.tile(b) != "rock_wall")
	var rock := surface_material("ground:rock_wall:%d" % posmod(c.x * 5 + c.y * 3, PlaceholderArt.GROUND_VARIANTS))
	if low:
		var h := 0.25 + 0.08 * posmod(c.x + c.y * 2, 3)
		_box(Vector3(1, h, 1), at + Vector3(0, h / 2, 0), rock)
		_snow_top(Vector3(0.94, 0.03, 0.94), at + Vector3(0, h + 0.015, 0))
		return
	var tall := 1.3 + 0.12 * posmod(c.x * 3 + c.y * 7, 4)
	_box(Vector3(1.02, tall, 1.02), at + Vector3(0, tall / 2, 0), rock)
	_snow_top(Vector3(0.96, 0.03, 0.96), at + Vector3(0, tall + 0.015, 0))


## Snow tops only where snow lies (outdoors).
func _snow_top(size: Vector3, center: Vector3, rot := Vector3.ZERO) -> void:
	if SnowLayer.map_has_snow(map):
		super._snow_top(size, center, rot)


## A prop, its meshes kept a run (MeshCache) by the map, the prop, the season and whether snow
## lies, which is all its look depends on; story props (shown by flags) are always made.
func _prop(p: Dictionary) -> void:
	# Story props (shown by flags) are always made; so is bamboo, whose clump meshes
	# OutdoorProps already shares (placing them is cheaper than keeping each clump here).
	if str(p.kind) in StoryView.KINDS or str(p.kind) == "bamboo":
		_make_prop(p)
		return
	MeshCache.build(self, "prop|%s|%s|%s|%s" % [map.id, p, Game.season_name(), SnowLayer.map_has_snow(map)], _make_prop.bind(p))


func _make_prop(p: Dictionary) -> void:
	var r := Rect2(Vector2(p.cell), Vector2(p.size))
	var mid := Vector3(r.get_center().x, 0, r.get_center().y)
	if str(p.kind) in RoomProps.KINDS:
		RoomProps.prop(self, p, mid, r)
		return
	match str(p.kind):
		"village_house": _village_house(r, int(p.get("door", 1)), bool(p.get("noren", false)), int(p.get("side_door", -1)), LitSpots.village_style(p))
		"torii": Shrine.torii(self, mid, r)
		"hokora": Shrine.hokora(self, mid)
		"stone_lantern": Shrine.stone_lantern(self, mid)
		"pine": _pine(mid, Vector2i(p.cell))
		"bamboo": _bamboo(mid, Vector2i(p.cell))
		"river_rock": _river_rock(mid)
		"ferry_boat": OutdoorProps.ferry_boat(self, r, SnowLayer.map_has_snow(map))
		"landing": OutdoorProps.landing(self, r)
		"cloth_rack": OutdoorProps.cloth_rack(self, p, r)
		"feed_box", "nest", "incubator", "feed_sack", "hatch": CoopProps.prop(self, p, mid, r)
		"fodder_box", "stalls", "hay", "barn_gate": BarnProps.prop(self, p, mid, r)
		"well", "jizo", "persimmon", "sakura", "maple", "hasa", "woodpile", "garden", "wood_fence", "kiln": CountryProps.prop(self, p, mid, r, Game.season_name())
		"cave_mouth": _cave_mouth(mid, r)
		"door_bell", "store_sign", "ume_jar", "carp_streamer", "ribbon_board", "keepsake", "rope_lift", "jizo_bibs", "kiln_mark", "kiln_site", "kiln_new", "boat_name", "noren": StoryProps.prop(self, p)
		"ladder": _ladder(mid)
		"cradle": pass   # the baby's cradle: CradleLayer shows it (it changes as the farmer lifts the baby)
		_:
			push_warning("MapWorld: no look for prop '%s'" % p.kind)
			_box(Vector3(r.size.x, 0.5, r.size.y) * 0.9, mid + Vector3(0, 0.25, 0), flat_material(Color.MAGENTA))


## A village house over its footprint, a shoji door on the front (+z) face at `door` cells
## from the left, shoji windows, and an indigo noren over the door of a shop. `side_door`
## (cells from the left, -1 for none) is a second, plain door: the way into the rooms behind
## a shop. `style` (LitSpots.village_style, from the map prop) picks its look:
##  - `roof`: a kawara gable (Minka.gable, plaster gable ends) or hip roof (Minka.hip), tile
##    rolls and a ridge (Minka.ridge) curving up to its end tiles, along x;
##  - `storeys` 2: a low upper floor (zushi-nikai) standing in LitSpots.UPPER_INSET from the
##    walls below, a tiled pent roof (a hip roof whose top hides inside it) all round at the
##    first floor's eaves, the main roof on the upper floor;
##  - `wall`: plaster (a dark board skirt, white plaster), yakisugi (charred boards up to a
##    plaster band under the eaves) or timber (earthen plaster between posts and rails).
func _village_house(r: Rect2, door: int, noren: bool, side_door := -1, style := {}) -> void:
	var roof := str(style.get("roof", "gable"))
	var storeys := int(style.get("storeys", 1))
	var finish := str(style.get("wall", "plaster"))
	var front := LitSpots.village_front(r)
	# Eaves 0.35 past the walls (0.25 past a gable end), the soffit 1.45 high at the front eave,
	# rising 0.5 a unit (about 27°, a gentle tile roof); the walls go up to the soffit.
	var overhang := 0.35
	var pitch := 0.5
	var wall := LitSpots.VILLAGE_WALL   # 1.45 + overhang * pitch
	var body := LitSpots.village_body(r)
	# The walls and roofs depend on the footprint and the look only: kept a run (MeshCache).
	MeshCache.build(self, "village_house|%s|%s|%s|%s|%s" % [body, roof, storeys, finish, SnowLayer.map_has_snow(map)], func() -> void:
		_house_walls(body, 0.0, wall, finish, true)
		if storeys < 2:
			_house_roof(body, wall, overhang, pitch, roof, _gable_key(finish))
		else:
			# The pent roof round the first floor, then the upper floor standing in from it.
			Minka.hip(self, body.grow(overhang), 1.45, pitch, 0.14, "build:kawara", "build:kawara_edge", 0.25)
			var up := body.grow(-LitSpots.UPPER_INSET)
			_house_walls(up, wall - 0.3, LitSpots.UPPER_TOP, "upper_" + finish, false)
			_house_roof(up, LitSpots.UPPER_TOP, overhang, pitch, roof, _gable_key(finish)))
	var dx := r.position.x + door + 0.5
	if noren:   # a shop's door stays dark at night: its noren hangs over the paper
		_picture("build:shoji_door", Vector2(0.85, 1.05), Vector3(dx, 0.55, front + 0.005))
		var cloth := _picture("build:noren", Vector2(0.95, 0.36), Vector3(dx, 1.0, front + 0.03))
		OutdoorProps.sway_picture(self, cloth, Vector2(0.95, 0.36), dx * 1.1)   # it blows out in the wind
	for spot in LitSpots.village_house(r, door, noren, side_door, storeys, finish):
		_lit_spot(spot)


## The walls of a village house (or of its upper floor) over `body` (x / z), from `base` up to
## `top`, in the finish `finish` (see _village_house; "upper_..." for an upper floor: plaster,
## or the earthen plaster of the timber look), with the timber posts and beam on its front
## (+z) face. `skirt`: a ground floor (its finish reaches the ground).
func _house_walls(body: Rect2, base: float, top: float, finish: String, skirt: bool) -> void:
	var timber := flat_material(Color("2e221a"))
	var cx := body.get_center().x
	var mid_z := body.get_center().y
	var front := body.end.y
	var size := Vector2(body.size.x, body.size.y)
	var layer := func(key: String, y0: float, y1: float) -> void:
		_box(Vector3(size.x, y1 - y0, size.y), Vector3(cx, (y0 + y1) / 2, mid_z), surface_material(key))
	# Front posts: the corners and the middle (an upper floor's middle only when it is wide
	# enough to keep it off the window there); the timber look has one at every cell's edge.
	# Rails stay clear of the doors (up to 1.08) and the windows (0.85 .. 1.35).
	var posts := LitSpots.front_posts(body, finish, skirt)
	var rail := func(y: float) -> void:
		_box(Vector3(size.x + 0.05, 0.07, size.y + 0.05), Vector3(cx, y, mid_z), timber)
	match finish:
		"yakisugi":   # charred boards most of the way up, a white band under the eaves
			layer.call("build:board", base, top - LitSpots.YAKISUGI_BAND)
			layer.call("build:plaster", top - LitSpots.YAKISUGI_BAND, top)
			rail.call(top - LitSpots.YAKISUGI_BAND)
		"timber":   # earthen plaster over a low skirt, framed by a post at every cell's edge
			layer.call("build:board", base, LitSpots.TIMBER_SKIRT)
			layer.call("build:tsuchi", LitSpots.TIMBER_SKIRT, top)
			rail.call(LitSpots.TIMBER_RAIL)
			for z in [body.position.y + 0.02, front - 0.02]:   # the +x face's corner posts
				_box(Vector3(0.06, top - base, 0.1), Vector3(body.end.x + 0.02, (base + top) / 2, z), timber)
		"upper_timber":
			layer.call("build:tsuchi", base, top)
		"upper_plaster", "upper_yakisugi":
			layer.call("build:plaster", base, top)
		_:   # plaster over a board skirt
			layer.call("build:board", base, base + 0.5)
			layer.call("build:plaster", base + 0.5, top)
	for x: float in posts:
		_box(Vector3(0.1, top - base, 0.08), Vector3(x, (base + top) / 2, front + 0.02), timber)
	_box(Vector3(size.x + 0.06, LitSpots.RAIL, 0.06), Vector3(cx, top - 0.03, front + 0.03), timber)


## The texture of a gable end over walls of `finish`: earthen for the timber look, else plaster.
static func _gable_key(finish: String) -> String:
	return "build:tsuchi" if finish == "timber" else "build:plaster"


## The kawara roof over walls `body` whose tops are at `wall`: eaves `overhang` out, rising
## `pitch`; "hip" (Minka.hip) or a gable (Minka.gable, the ends 0.25 out, gable walls of
## `gable_key`).
func _house_roof(body: Rect2, wall: float, overhang: float, pitch: float, kind: String, gable_key := "build:plaster") -> void:
	var low := wall - overhang * pitch
	var mid_z := body.get_center().y
	if kind == "hip":
		var hip_eave := body.grow(overhang)
		var hip_crest := Minka.hip(self, hip_eave, low, pitch, 0.14, "build:kawara", "build:kawara_edge", 0.25)
		var ends := Minka.hip_ridge_ends(hip_eave)
		Minka.ridge(self, ends.x, ends.y, hip_crest - 0.04, mid_z, 0.1, minf(0.8, (ends.y - ends.x) * 0.4))
		return
	var eave := Rect2(body.position.x - 0.25, body.position.y - overhang, body.size.x + 0.5, body.size.y + overhang * 2)
	var crest := Minka.gable(self, eave, low, pitch, 0.14, "build:kawara", "build:kawara_edge", 0.25)
	var apex := low + eave.size.y / 2 * pitch
	for x in [body.position.x - 0.002, body.end.x + 0.002]:
		Minka.gable_wall(self, x, body.position.y, body.end.y, wall, apex, gable_key, signf(x - body.get_center().x))
	Minka.ridge(self, eave.position.x + 0.05, eave.end.x - 0.05, crest - 0.04, mid_z)


## A village pine (Trees.pine): it leans, its pads of needles set off to alternate sides;
## snow on the pads where snow lies.
func _pine(mid: Vector3, c: Vector2i) -> void:
	var parts := FarmProps.Parts.new()
	Trees.pine(parts, mid, c.x * 31 + c.y * 17, true, SnowLayer.map_has_snow(map))
	parts.commit(self)


## A clump of bamboo (OutdoorProps.bamboo): segmented culms, leaf sprays, swaying; the
## clump's cell picks its look, the season its colours.
func _bamboo(mid: Vector3, c: Vector2i) -> void:
	OutdoorProps.bamboo(self, mid, c, Game.season_name(), SnowLayer.map_has_snow(map))


# --- the mine (data/maps/mine.json, mine_floor.json) ---------------------------

## The adit in the cliff: a black opening framed by two timber posts and a lintel, a straw
## rope (shimenawa) with paper streamers hung across it, as at a mountain shrine.
func _cave_mouth(mid: Vector3, r: Rect2) -> void:
	var front := r.end.y + 0.02
	var wide := r.size.x - 0.3
	_box(Vector3(wide, 1.3, 0.04), Vector3(mid.x, 0.65, front), flat_material(Color("0c0a08")))
	var timber := surface_material("build:sugi")
	for x in [mid.x - wide / 2, mid.x + wide / 2]:
		_box(Vector3(0.16, 1.45, 0.16), Vector3(x, 0.72, front + 0.06), timber)
	_box(Vector3(wide + 0.4, 0.16, 0.2), Vector3(mid.x, 1.5, front + 0.06), timber)
	_box(Vector3(wide + 0.1, 0.07, 0.07), Vector3(mid.x, 1.36, front + 0.17), flat_material(Color("c8b070")))
	for i in 4:
		var x := mid.x - wide / 2 + 0.3 + i * (wide - 0.6) / 3.0
		_box(Vector3(0.08, 0.22, 0.01), Vector3(x, 1.2, front + 0.2), flat_material(Color("f4f0e6")))
	_box(Vector3(0.5, 0.05, 0.3), Vector3(mid.x, 0.025, front + 0.35), flat_material(Color("8a8680")))   # a step stone


## The ladder back up, leaning on the rock in the floor's back wall, a little light from above.
func _ladder(mid: Vector3) -> void:
	var at := mid + Vector3(0, 0, 0.58)   # just in front of the rock face
	var wood := flat_material(Color("8a6a3a"))
	for x in [-0.25, 0.25]:
		_box(Vector3(0.07, 1.6, 0.07), at + Vector3(x, 0.8, 0.06), wood, Vector3(-0.12, 0, 0))
	for i in 5:
		_box(Vector3(0.5, 0.05, 0.05), at + Vector3(0, 0.2 + i * 0.3, 0.12 - 0.036 * i), flat_material(Color("c89c5a")))
	_box(Vector3(0.9, 0.02, 0.6), mid + Vector3(0, 0.015, 0.9), flat_material(Color(1.0, 0.95, 0.8, 0.25)))


## A stepping rock out in the river (OutdoorProps.river_rock).
func _river_rock(mid: Vector3) -> void:
	OutdoorProps.river_rock(self, mid, SnowLayer.map_has_snow(map))
