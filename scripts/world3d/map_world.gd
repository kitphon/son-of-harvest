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
	map = m
	_make_tile_ground()
	for y in map.h:
		for x in map.w:
			var c := Vector2i(x, y)
			if map.tile(c) == "rock_wall":
				_rock_wall(c)
			elif map.is_solid(c) and not map.door_at(c).is_empty() and map.prop_at(c).is_empty() and map.indoor:
				_box(Vector3(1, 0.06, 0.9), Vector3(x + 0.5, 0.03, y + 0.5), flat_material(Color("4a3424")))   # threshold
	RoomWalls.build(self, map)
	for p in map.props:
		occlude(_make_prop.bind(p))
	if not map.sheltered and not map.indoor:
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
	if not map.sheltered:
		var rules: Dictionary = Game.snow_rules
		add_surroundings(map.w, map.h, func(c: Vector2i) -> String: return map.tile(c),
			func(c: Vector2i) -> float: return SnowLayer.map_hold(map, c, rules))


## Rice in the paddy cells with no prop, by the season (CropClusters.paddy_key; none in winter).
func _plant_paddies(hold_at: Callable) -> void:
	var key := CropClusters.paddy_key(Game.season_name())
	if key == "":
		return
	var cells := {}
	for y in map.h:
		for x in map.w:
			var c := Vector2i(x, y)
			if map.tile(c) == "paddy" and map.prop_at(c).is_empty():
				cells[c] = key
	if not cells.is_empty():
		add_crops()
		crops.plant(cells, hold_at)


## The tiles as one picture under the whole map (unshaded, like the farm ground).
func _make_tile_ground() -> void:
	var img := Image.create(map.w * T, map.h * T, false, Image.FORMAT_RGBA8)
	for y in map.h:
		for x in map.w:
			var tile := PlaceholderArt.tex(MapView.ground_key(map, Vector2i(x, y))).get_image()
			tile.convert(Image.FORMAT_RGBA8)
			img.blit_rect(tile, Rect2i(0, 0, T, T), Vector2i(x * T, y * T))
	if map.indoor:
		_shade_corners(img)
	var mat: Material
	if SnowLayer.map_has_snow(map):
		var snow := ImageTexture.create_from_image(SnowLayer.map_mask_image(map, Game.snow_rules))
		mat = SnowLayer.ground_material(ImageTexture.create_from_image(img), snow)
		_snow_mats.append(mat)
	else:
		var flat := flat_material(Color.WHITE)
		flat.albedo_texture = ImageTexture.create_from_image(img)
		flat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat = flat
	var plane := PlaneMesh.new()
	plane.size = Vector2(map.w, map.h)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = mat
	ground.position = Vector3(map.w / 2.0, 0, map.h / 2.0)
	add_child(ground)


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
			for py in T:
				for px in T:
					var shade := 1.0
					for i in sides.size():
						var o: Vector2i = sides[i][0]
						if not map.in_bounds(c + o) or map.tile(c + o) != "wall":
							continue
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


func _make_prop(p: Dictionary) -> void:
	var r := Rect2(Vector2(p.cell), Vector2(p.size))
	var mid := Vector3(r.get_center().x, 0, r.get_center().y)
	if str(p.kind) in RoomProps.KINDS:
		RoomProps.prop(self, p, mid, r)
		return
	match str(p.kind):
		"village_house": _village_house(r, int(p.get("door", 1)), bool(p.get("noren", false)), int(p.get("side_door", -1)))
		"torii": Shrine.torii(self, mid, r)
		"hokora": Shrine.hokora(self, mid)
		"stone_lantern": Shrine.stone_lantern(self, mid)
		"pine": _pine(mid, Vector2i(p.cell))
		"bamboo": _bamboo(mid, Vector2i(p.cell))
		"river_rock": _river_rock(mid)
		"feed_box", "nest", "incubator", "feed_sack", "hatch": CoopProps.prop(self, p, mid, r)
		"fodder_box", "stalls", "hay", "barn_gate": BarnProps.prop(self, p, mid, r)
		"well", "jizo", "persimmon", "sakura", "hasa", "woodpile", "garden", "wood_fence": CountryProps.prop(self, p, mid, r, Game.season_name())
		"cave_mouth": _cave_mouth(mid, r)
		"door_bell", "store_sign", "ume_jar", "carp_streamer", "ribbon_board", "keepsake", "rope_lift": StoryProps.prop(self, p)
		"ladder": _ladder(mid)
		_:
			push_warning("MapWorld: no look for prop '%s'" % p.kind)
			_box(Vector3(r.size.x, 0.5, r.size.y) * 0.9, mid + Vector3(0, 0.25, 0), flat_material(Color.MAGENTA))


## A village house over its footprint: board skirting, plaster walls, a kawara gable roof
## built as a mesh (Minka.gable with tile rolls, Minka.ridge curving up to its end tiles)
## with the ridge along x, a shoji door on the front (+z) face at `door` cells from the left,
## shoji windows, and an indigo noren over the door of a shop. `side_door` (cells from the
## left, -1 for none) is a second, plain door: the way into the rooms behind a shop.
func _village_house(r: Rect2, door: int, noren: bool, side_door := -1) -> void:
	var timber := flat_material(Color("2e221a"))
	var back := r.position.y + 0.1
	var front := LitSpots.village_front(r)
	var depth := front - back
	var mid_z := back + depth / 2
	var cx := r.get_center().x
	var wide := r.size.x - 0.2
	# The roof (Minka.gable, kawara with tile rolls): eaves 0.35 past the long walls and 0.25
	# past the gable ends, the soffit 1.45 high at the front eave, rising 0.5 a unit (about
	# 27°, a gentle tile roof); the walls go up to the soffit, the gable ends are plaster.
	var overhang := 0.35
	var pitch := 0.5
	var wall := 1.45 + overhang * pitch
	_box(Vector3(wide, 0.5, depth), Vector3(cx, 0.25, mid_z), surface_material("build:board"))
	_box(Vector3(wide, wall - 0.5, depth), Vector3(cx, 0.5 + (wall - 0.5) / 2, mid_z), surface_material("build:plaster"))
	for x in [r.position.x + 0.1, cx, r.end.x - 0.1]:
		_box(Vector3(0.1, wall, 0.08), Vector3(x, wall / 2, front + 0.02), timber)
	_box(Vector3(wide + 0.06, 0.07, 0.06), Vector3(cx, wall - 0.03, front + 0.03), timber)
	var eave := Rect2(cx - wide / 2 - 0.25, back - overhang, wide + 0.5, depth + overhang * 2)
	var crest := Minka.gable(self, eave, 1.45, pitch, 0.14, "build:kawara", "build:kawara_edge", 0.25)
	var apex := 1.45 + eave.size.y / 2 * pitch
	for x in [cx - wide / 2 - 0.002, cx + wide / 2 + 0.002]:
		Minka.gable_wall(self, x, back, front, wall, apex, "build:plaster", signf(x - cx))
	Minka.ridge(self, eave.position.x + 0.05, eave.end.x - 0.05, crest - 0.04, mid_z)
	var dx := r.position.x + door + 0.5
	if noren:   # a shop's door stays dark at night: its noren hangs over the paper
		_picture("build:shoji_door", Vector2(0.85, 1.05), Vector3(dx, 0.55, front + 0.005))
		_picture("build:noren", Vector2(0.95, 0.36), Vector3(dx, 1.0, front + 0.03))
	for spot in LitSpots.village_house(r, door, noren, side_door):
		_lit_spot(spot)


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
