class_name MapWorld
extends FarmWorld
## A map other than the farm in 3D (data/maps): its ground tiles laid into one texture, walls
## as boxes and its props (furniture, village houses, the shrine) built from the same
## placeholder surfaces as the farm buildings. Same units as FarmWorld: 1 unit = 1 cell.
##
## Indoors the camera looks in from +x / +z (the same fixed field camera), so only the back
## walls (top row, left column) stand full height; the front ones are cut down to a sill.
##
## Outdoors snow lies as on the farm (SnowLayer: the ground by tile kind, snow tops on the
## roofs, the shrine, the lantern caps and the rock); under a roof (rooms, the mine floors)
## there is none, whatever Game.snow_cover says.

const WALL_HIGH := 1.7
const WALL_LOW := 0.22
const VERMILION := Color("c8442c")

var map: MapData


func build(m: MapData) -> void:
	map = m
	_make_tile_ground()
	for y in map.h:
		for x in map.w:
			var c := Vector2i(x, y)
			if map.tile(c) == "wall":
				_wall(c)
			elif map.tile(c) == "rock_wall":
				_rock_wall(c)
			elif map.is_solid(c) and not map.door_at(c).is_empty() and map.prop_at(c).is_empty() and map.indoor:
				_box(Vector3(1, 0.06, 0.9), Vector3(x + 0.5, 0.03, y + 0.5), flat_material(Color("4a3424")))   # threshold
	for p in map.props:
		occlude(_make_prop.bind(p))
	if not map.sheltered:
		var rules: Dictionary = Game.snow_rules
		add_surroundings(map.w, map.h, func(c: Vector2i) -> String: return map.tile(c),
			func(c: Vector2i) -> float: return SnowLayer.map_hold(map, c, rules))


## The tiles as one picture under the whole map (unshaded, like the farm ground).
func _make_tile_ground() -> void:
	var img := Image.create(map.w * T, map.h * T, false, Image.FORMAT_RGBA8)
	for y in map.h:
		for x in map.w:
			var tile := PlaceholderArt.tex(MapView.ground_key(map, Vector2i(x, y))).get_image()
			tile.convert(Image.FORMAT_RGBA8)
			img.blit_rect(tile, Rect2i(0, 0, T, T), Vector2i(x * T, y * T))
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


## A wall cell: dark board skirting, plaster above and a timber top beam on the back walls;
## a low sill on the front ones, so the room stays in view.
func _wall(c: Vector2i) -> void:
	var at := Vector3(c.x + 0.5, 0, c.y + 0.5)
	var timber := flat_material(Color("2e221a"))
	if c.y > 0 and c.x > 0:
		_box(Vector3(1, WALL_LOW, 1), at + Vector3(0, WALL_LOW / 2, 0), surface_material("build:board"))
		_box(Vector3(1.02, 0.05, 1.02), at + Vector3(0, WALL_LOW + 0.025, 0), timber)
		return
	_box(Vector3(1, 0.5, 1), at + Vector3(0, 0.25, 0), surface_material("build:board"))
	_box(Vector3(1, WALL_HIGH - 0.5, 1), at + Vector3(0, 0.5 + (WALL_HIGH - 0.5) / 2, 0), surface_material("build:plaster"))
	_box(Vector3(1.02, 0.08, 1.02), at + Vector3(0, WALL_HIGH, 0), timber)
	# A post every other cell and a shoji window now and then on the room side.
	var room := Vector3(0, 0, 0.505) if c.y == 0 else Vector3(0.505, 0, 0)
	var yaw := 0.0 if c.y == 0 else 90.0
	var along := c.x if c.y == 0 else c.y
	if along % 2 == 0:
		_box(Vector3(0.1, WALL_HIGH, 0.1), at + room + Vector3(0, WALL_HIGH / 2, 0), timber)
	elif along % 4 == 3:
		_picture("build:shoji", Vector2(0.8, 0.6), at + room * 1.01 + Vector3(0, 1.15, 0), yaw)


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
	match str(p.kind):
		"futon": _futon(mid, r)
		"low_table": _low_table(mid)
		"tansu": _tansu(mid)
		"andon": _andon(mid)
		"kamado": _kamado(mid)
		"mizuya": _mizuya(mid)
		"nagamochi": _nagamochi(mid)
		"kotatsu": _kotatsu(mid)
		"village_house": _village_house(r, int(p.get("door", 1)), bool(p.get("noren", false)), int(p.get("side_door", -1)))
		"torii": Shrine.torii(self, mid, r)
		"hokora": Shrine.hokora(self, mid)
		"stone_lantern": Shrine.stone_lantern(self, mid)
		"pine": _pine(mid)
		"bamboo": _bamboo(mid, Vector2i(p.cell))
		"counter": _counter(mid, r)
		"shelf": _shelf(mid, r)
		"rice_sacks": _rice_sacks(mid)
		"forge": _forge(mid, r)
		"anvil": _anvil(mid)
		"tool_rack": _tool_rack(mid, r)
		"water_tub": _water_tub(mid)
		"river_rock": _river_rock(mid)
		"feed_box", "nest", "incubator", "feed_sack", "hatch": CoopProps.prop(self, p, mid, r)
		"fodder_box", "stalls", "hay", "barn_gate": BarnProps.prop(self, p, mid, r)
		"irori", "tokonoma", "butsudan", "zabuton", "byobu", "toy_box", "mizugame": HomeProps.prop(self, p, mid, r)
		"well", "jizo", "persimmon", "sakura", "hasa", "woodpile", "garden", "wood_fence": CountryProps.prop(self, p, mid, r, Game.season_name())
		"cave_mouth": _cave_mouth(mid, r)
		"door_bell", "store_sign", "ume_jar", "carp_streamer", "ribbon_board", "keepsake", "rope_lift": StoryProps.prop(self, p)
		"ladder": _ladder(mid)
		_:
			push_warning("MapWorld: no look for prop '%s'" % p.kind)
			_box(Vector3(r.size.x, 0.5, r.size.y) * 0.9, mid + Vector3(0, 0.25, 0), flat_material(Color.MAGENTA))


## A futon laid on the tatami: white mattress, an indigo quilt over the lower part, a pillow.
func _futon(mid: Vector3, r: Rect2) -> void:
	var long := Vector3(r.size.x, 0, r.size.y) - Vector3(0.12, 0, 0.12)
	_box(Vector3(long.x, 0.1, long.z), mid + Vector3(0, 0.05, 0), flat_material(Color("eeeae0")))
	var top := r.position.y + 0.06
	_box(Vector3(long.x + 0.04, 0.12, long.z * 0.62), Vector3(mid.x, 0.12, r.end.y - 0.06 - long.z * 0.31),
		surface_material("build:quilt"))
	_box(Vector3(long.x * 0.55, 0.1, 0.24), Vector3(mid.x, 0.15, top + 0.22), flat_material(Color("d8cfa8")))


## A low round table (chabudai) on four short legs.
func _low_table(mid: Vector3) -> void:
	var wood := flat_material(Color("5a3a24"))
	var top := CylinderMesh.new()
	top.top_radius = 0.42
	top.bottom_radius = 0.42
	top.height = 0.05
	top.radial_segments = 16
	var mi := MeshInstance3D.new()
	mi.mesh = top
	mi.material_override = surface_material("build:planks")
	mi.position = mid + Vector3(0, 0.3, 0)
	add_child(mi)
	for o in [Vector3(0.22, 0, 0.22), Vector3(-0.22, 0, 0.22), Vector3(0.22, 0, -0.22), Vector3(-0.22, 0, -0.22)]:
		_box(Vector3(0.06, 0.28, 0.06), mid + o + Vector3(0, 0.14, 0), wood)
	_box(Vector3(0.14, 0.08, 0.14), mid + Vector3(0.1, 0.36, -0.05), flat_material(Color("e8e0cc")))   # a teacup


## A chest of drawers (tansu) against the back wall: dark board drawers, iron pulls.
func _tansu(mid: Vector3) -> void:
	var at := mid + Vector3(0, 0, -0.2)
	_box(Vector3(0.9, 1.1, 0.5), at + Vector3(0, 0.55, 0), surface_material("build:planks_dark"))
	var iron := flat_material(Color("1e1a18"))
	for y in [0.25, 0.55, 0.85]:
		for x in [-0.22, 0.22]:
			_box(Vector3(0.1, 0.04, 0.04), at + Vector3(x, y, 0.26), iron)
	_box(Vector3(0.96, 0.05, 0.56), at + Vector3(0, 1.12, 0), flat_material(Color("2e221a")))


## A paper floor lantern (andon): a dark frame round warm-lit paper.
func _andon(mid: Vector3) -> void:
	_box(Vector3(0.28, 0.5, 0.28), mid + Vector3(0, 0.37, 0), flat_material(Color("ffe6a8")))
	var frame := flat_material(Color("2e221a"))
	for x in [-0.15, 0.15]:
		for z in [-0.15, 0.15]:
			_box(Vector3(0.04, 0.66, 0.04), mid + Vector3(x, 0.33, z), frame)
	_box(Vector3(0.34, 0.04, 0.34), mid + Vector3(0, 0.64, 0), frame)


## A clay cooking stove (kamado, kitchen extension): a pale clay block, a dark fire mouth in
## front, an iron pot on top.
func _kamado(mid: Vector3) -> void:
	_box(Vector3(0.8, 0.55, 0.7), mid + Vector3(0, 0.275, -0.05), flat_material(Color("c8b498")))
	_box(Vector3(0.3, 0.2, 0.04), mid + Vector3(0, 0.16, 0.31), flat_material(Color("2a1a10")))
	_box(Vector3(0.22, 0.06, 0.03), mid + Vector3(0, 0.12, 0.33), flat_material(Color("e8742a")))   # embers
	var pot := CylinderMesh.new()
	pot.top_radius = 0.2
	pot.bottom_radius = 0.16
	pot.height = 0.2
	pot.radial_segments = 12
	var mi := MeshInstance3D.new()
	mi.mesh = pot
	mi.material_override = flat_material(Color("2e2a28"))
	mi.position = mid + Vector3(0, 0.65, -0.05)
	add_child(mi)


## A kitchen cupboard (mizuya): dark wood below, sliding paper doors above, a bowl on the ledge.
func _mizuya(mid: Vector3) -> void:
	var at := mid + Vector3(0, 0, -0.15)
	_box(Vector3(0.9, 0.5, 0.55), at + Vector3(0, 0.25, 0), surface_material("build:planks_dark"))
	_box(Vector3(0.9, 0.6, 0.45), at + Vector3(0, 0.8, -0.05), flat_material(Color("efe6cc")))
	_box(Vector3(0.04, 0.6, 0.47), at + Vector3(0, 0.8, -0.05), flat_material(Color("2e221a")))
	_box(Vector3(0.96, 0.05, 0.58), at + Vector3(0, 1.12, 0), flat_material(Color("2e221a")))
	_box(Vector3(0.2, 0.08, 0.2), at + Vector3(0.2, 0.54, 0.12), flat_material(Color("3a5a8c")))


## A long lidded chest (nagamochi, bigger chest extension): planks with iron corners.
func _nagamochi(mid: Vector3) -> void:
	_box(Vector3(0.92, 0.5, 0.55), mid + Vector3(0, 0.25, -0.1), surface_material("build:planks"))
	_box(Vector3(0.96, 0.06, 0.6), mid + Vector3(0, 0.53, -0.1), flat_material(Color("4a3424")))
	var iron := flat_material(Color("1e1a18"))
	for x in [-0.42, 0.42]:
		_box(Vector3(0.08, 0.5, 0.04), mid + Vector3(x, 0.25, 0.19), iron)
	_box(Vector3(0.1, 0.1, 0.03), mid + Vector3(0, 0.38, 0.19), iron)


## A kotatsu (second room): a low table under a quilt that falls to the floor.
func _kotatsu(mid: Vector3) -> void:
	_box(Vector3(0.9, 0.3, 0.9), mid + Vector3(0, 0.15, 0), surface_material("build:quilt"))
	_box(Vector3(0.8, 0.05, 0.8), mid + Vector3(0, 0.33, 0), surface_material("build:planks"))
	_box(Vector3(0.14, 0.1, 0.14), mid + Vector3(-0.15, 0.4, 0.1), flat_material(Color("e8a23a")))   # a mikan


## A village house over its footprint: board skirting, plaster walls, a kawara gable roof
## built as a mesh (Minka.gable with tile rolls, Minka.ridge curving up to its end tiles)
## with the ridge along x, a shoji door on the front (+z) face at `door` cells from the left,
## shoji windows, and an indigo noren over the door of a shop. `side_door` (cells from the
## left, -1 for none) is a second, plain door: the way into the rooms behind a shop.
func _village_house(r: Rect2, door: int, noren: bool, side_door := -1) -> void:
	var timber := flat_material(Color("2e221a"))
	var back := r.position.y + 0.1
	var front := r.end.y - 0.15
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
	_picture("build:shoji_door", Vector2(0.85, 1.05), Vector3(dx, 0.55, front + 0.005))
	if noren:
		_picture("build:noren", Vector2(0.95, 0.36), Vector3(dx, 1.0, front + 0.03))
	var sx := r.position.x + side_door + 0.5 if side_door >= 0 else -100.0
	if side_door >= 0:
		_picture("build:shoji_door", Vector2(0.75, 1.0), Vector3(sx, 0.52, front + 0.005))
	for x in range(int(r.position.x), int(r.end.x)):
		if absf(x + 0.5 - dx) > 1.2 and absf(x + 0.5 - sx) > 0.9 and (x - int(r.position.x)) % 2 == 1:
			_picture("build:shoji", Vector2(0.7, 0.5), Vector3(x + 0.5, 1.1, front + 0.005))
	_picture("build:shoji", Vector2(0.7, 0.5), Vector3(r.end.x - 0.1 + 0.005, 1.1, mid_z), 90)


## A pine: a dark trunk and three layered cones of needles.
func _pine(mid: Vector3) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.07
	trunk.bottom_radius = 0.1
	trunk.height = 0.9
	trunk.radial_segments = 6
	var t := MeshInstance3D.new()
	t.mesh = trunk
	t.material_override = flat_material(Color("4a3424"))
	t.position = mid + Vector3(0, 0.45, 0)
	add_child(t)
	var needles := [Color("2f5a34"), Color("3a6a3c"), Color("467a44")]
	for i in 3:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.62 - i * 0.14
		cone.height = 0.75
		cone.radial_segments = 8
		var mi := MeshInstance3D.new()
		mi.mesh = cone
		var m := StandardMaterial3D.new()
		m.albedo_color = needles[i]
		mi.material_override = m
		mi.position = mid + Vector3(0, 0.9 + i * 0.42, 0)
		add_child(mi)


## A clump of bamboo: three or four tall green stalks leaning a little apart, a pale node
## ring every half unit, and leaf sprays near their tops. The clump's spot picks its look.
func _bamboo(mid: Vector3, c: Vector2i) -> void:
	var seed := posmod(c.x * 7 + c.y * 13, 16)
	var stalk_mat := flat_material(Color("6e9c42") if seed % 3 else Color("7aa84c"))
	var node_mat := flat_material(Color("a8c878"))
	var leaf_mat := flat_material(Color("4e8a3a"))
	var n := 3 + seed % 2
	for i in n:
		var angle := TAU * (i + seed * 0.13) / n
		var foot := mid + Vector3(cos(angle), 0, sin(angle)) * 0.2
		var tall := 2.2 + 0.25 * ((seed + i * 5) % 4)
		var lean := Vector3(cos(angle), 0, sin(angle)) * 0.06
		var stalk := CylinderMesh.new()
		stalk.top_radius = 0.035
		stalk.bottom_radius = 0.045
		stalk.height = tall
		stalk.radial_segments = 6
		var s := MeshInstance3D.new()
		s.mesh = stalk
		s.material_override = stalk_mat
		s.position = foot + Vector3(0, tall / 2, 0)
		s.rotation = Vector3(lean.z, 0, -lean.x)
		add_child(s)
		var y := 0.5
		while y < tall - 0.3:
			_box(Vector3(0.1, 0.03, 0.1), foot + Vector3(lean.x * y, y, lean.z * y), node_mat)
			y += 0.5
		var top := foot + Vector3(lean.x * tall, tall, lean.z * tall)
		_box(Vector3(0.55, 0.06, 0.18), top + Vector3(0.12, -0.15, 0), leaf_mat, Vector3(0, angle, 0.35))
		_box(Vector3(0.45, 0.06, 0.16), top + Vector3(-0.1, -0.45, 0.05), leaf_mat, Vector3(0, angle + 1.4, -0.3))


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


# --- shop insides (data/maps/store.json, smithy.json) --------------------------

## A shop counter along its cells: a dark board front, a light plank top that overhangs on
## the customer's side, and a small brass bell at the left end.
func _counter(mid: Vector3, r: Rect2) -> void:
	var long := Vector3(r.size.x - 0.08, 0, r.size.y - 0.2)
	_box(Vector3(long.x, 0.72, long.z), mid + Vector3(0, 0.36, 0), surface_material("build:planks_dark"))
	_box(Vector3(long.x + 0.06, 0.06, long.z + 0.16), mid + Vector3(0, 0.75, 0.04), surface_material("build:planks"))
	_box(Vector3(long.x, 0.05, 0.03), mid + Vector3(0, 0.12, long.z / 2 + 0.01), flat_material(Color("2e221a")))
	_box(Vector3(0.12, 0.1, 0.12), Vector3(r.position.x + 0.35, 0.83, mid.z), flat_material(Color("c8a040")))


## Goods shelves against the back wall: a dark frame with three boards, each full of little
## boxes, jars and seed packets in a row of colours.
func _shelf(mid: Vector3, r: Rect2) -> void:
	var at := mid + Vector3(0, 0, -0.22)
	var wide := r.size.x - 0.1
	var frame := surface_material("build:planks_dark")
	for x in [-wide / 2 + 0.04, wide / 2 - 0.04]:
		_box(Vector3(0.08, 1.4, 0.42), at + Vector3(x, 0.7, 0), frame)
	_box(Vector3(wide, 1.4, 0.04), at + Vector3(0, 0.7, -0.2), frame)
	var goods := [Color("c8442c"), Color("e8d8a0"), Color("4a78c0"), Color("7aa848"), Color("f0a8b8"), Color("c9a26b")]
	for i in 3:
		var y := 0.25 + i * 0.42
		_box(Vector3(wide, 0.04, 0.42), at + Vector3(0, y, 0), surface_material("build:planks"))
		var n := int(wide / 0.24)
		for k in n:
			var h := 0.14 + 0.06 * ((k + i) % 3)
			var x := -wide / 2 + 0.18 + k * (wide - 0.36) / maxf(n - 1, 1)
			_box(Vector3(0.16, h, 0.2), at + Vector3(x, y + 0.02 + h / 2, 0.04), flat_material(goods[(k * 2 + i) % goods.size()]))


## Two straw rice sacks (tawara) on their sides, tied with rope.
func _rice_sacks(mid: Vector3) -> void:
	var straw := flat_material(Color("d8c088"))
	var rope := flat_material(Color("8a6a3a"))
	for i in 2:
		var bale := CylinderMesh.new()
		bale.top_radius = 0.2
		bale.bottom_radius = 0.2
		bale.height = 0.6
		bale.radial_segments = 10
		var mi := MeshInstance3D.new()
		mi.mesh = bale
		mi.material_override = straw
		mi.position = mid + Vector3(0, 0.2 + i * 0.36, 0.1 - i * 0.1)
		mi.rotation_degrees = Vector3(0, 0, 90)
		add_child(mi)
		for x in [-0.18, 0.18]:
			_box(Vector3(0.04, 0.42, 0.42), mi.position + Vector3(x, 0, 0), rope)


## The forge in the back corner: a stone hearth with a glowing fire bed, a hood and a
## chimney up through the beam, a pair of bellows at the side.
func _forge(mid: Vector3, r: Rect2) -> void:
	var stone := flat_material(Color("7a746c"))
	var at := mid + Vector3(-0.05, 0, -0.1)
	_box(Vector3(r.size.x - 0.3, 0.6, r.size.y - 0.4), at + Vector3(0, 0.3, 0), stone)
	_box(Vector3(r.size.x - 0.8, 0.04, r.size.y - 0.9), at + Vector3(0, 0.61, 0.05), flat_material(Color("ff8a30")))
	_box(Vector3(0.5, 0.05, 0.4), at + Vector3(0.05, 0.64, 0.05), flat_material(Color("ffd060")))
	_box(Vector3(r.size.x - 0.5, 0.35, r.size.y - 0.7), at + Vector3(0, 1.35, -0.1), stone)
	_box(Vector3(0.5, 0.6, 0.5), at + Vector3(0, 1.8, -0.2), stone)
	_box(Vector3(0.36, 0.28, 0.5), at + Vector3(r.size.x / 2 - 0.05, 0.3, 0.2), flat_material(Color("6a4a30")))


## An anvil on a tree stump.
func _anvil(mid: Vector3) -> void:
	var stump := CylinderMesh.new()
	stump.top_radius = 0.24
	stump.bottom_radius = 0.28
	stump.height = 0.4
	stump.radial_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = stump
	mi.material_override = flat_material(Color("6a4a30"))
	mi.position = mid + Vector3(0, 0.2, 0)
	add_child(mi)
	var iron := flat_material(Color("2a2a2e"))
	_box(Vector3(0.22, 0.14, 0.2), mid + Vector3(0, 0.47, 0), iron)
	_box(Vector3(0.5, 0.1, 0.22), mid + Vector3(0.04, 0.59, 0), iron)
	_box(Vector3(0.14, 0.06, 0.12), mid + Vector3(-0.27, 0.6, 0), iron)   # the horn


## Finished tools hung on a board against the back wall: handles of wood, heads of iron.
func _tool_rack(mid: Vector3, r: Rect2) -> void:
	var at := mid + Vector3(0, 0, -0.38)
	_box(Vector3(r.size.x - 0.2, 0.9, 0.06), at + Vector3(0, 1.0, 0), surface_material("build:board"))
	var wood := flat_material(Color("a8743f"))
	var iron := flat_material(Color("8a9096"))
	var n := int(r.size.x) * 2 - 1
	for k in n:
		var x := -(r.size.x - 0.6) / 2 + k * (r.size.x - 0.6) / maxf(n - 1, 1)
		_box(Vector3(0.05, 0.6, 0.05), at + Vector3(x, 0.95, 0.06), wood)
		_box(Vector3(0.16 if k % 2 == 0 else 0.06, 0.1 if k % 2 == 0 else 0.2, 0.05), at + Vector3(x, 1.3, 0.07), iron)


## A stepping rock out in the river: a wide low boulder with a smaller one leaning on it,
## a pale wet line where the current breaks round them.
func _river_rock(mid: Vector3) -> void:
	var stone := flat_material(Color("6e6a62"))
	_box(Vector3(0.82, 0.26, 0.7), mid + Vector3(0, 0.13, 0), stone)
	_box(Vector3(0.46, 0.2, 0.4), mid + Vector3(0.16, 0.34, -0.08), flat_material(Color("85817a")))
	_box(Vector3(0.94, 0.03, 0.82), mid + Vector3(0, 0.02, 0), flat_material(Color("c8dce0")))


## A wooden quench tub with dark water.
func _water_tub(mid: Vector3) -> void:
	var tub := CylinderMesh.new()
	tub.top_radius = 0.3
	tub.bottom_radius = 0.26
	tub.height = 0.42
	tub.radial_segments = 12
	var mi := MeshInstance3D.new()
	mi.mesh = tub
	mi.material_override = surface_material("build:sugi")
	mi.position = mid + Vector3(0, 0.21, 0)
	add_child(mi)
	_box(Vector3(0.44, 0.02, 0.44), mid + Vector3(0, 0.4, 0), flat_material(Color("2a4a5a")))
