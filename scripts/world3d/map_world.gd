class_name MapWorld
extends FarmWorld
## A map other than the farm in 3D (data/maps): its ground tiles laid into one texture, walls
## as boxes and its props (furniture, village houses, the shrine) built from the same
## placeholder surfaces as the farm buildings. Same units as FarmWorld: 1 unit = 1 cell.
##
## Indoors the camera looks in from +x / +z (the same fixed field camera), so only the back
## walls (top row, left column) stand full height; the front ones are cut down to a sill.

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
			elif map.is_solid(c) and not map.door_at(c).is_empty() and map.prop_at(c).is_empty() and map.indoor:
				_box(Vector3(1, 0.06, 0.9), Vector3(x + 0.5, 0.03, y + 0.5), flat_material(Color("4a3424")))   # threshold
	for p in map.props:
		_make_prop(p)


## The tiles as one picture under the whole map (unshaded, like the farm ground).
func _make_tile_ground() -> void:
	var img := Image.create(map.w * T, map.h * T, false, Image.FORMAT_RGBA8)
	for y in map.h:
		for x in map.w:
			var tile := PlaceholderArt.tex(MapView.ground_key(map, Vector2i(x, y))).get_image()
			tile.convert(Image.FORMAT_RGBA8)
			img.blit_rect(tile, Rect2i(0, 0, T, T), Vector2i(x * T, y * T))
	var mat := flat_material(Color.WHITE)
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
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
		"village_house": _village_house(r, int(p.get("door", 1)), bool(p.get("noren", false)))
		"torii": _torii(mid, r)
		"hokora": _hokora(mid)
		"stone_lantern": _stone_lantern(mid)
		"pine": _pine(mid)
		"counter": _counter(mid, r)
		"shelf": _shelf(mid, r)
		"rice_sacks": _rice_sacks(mid)
		"forge": _forge(mid, r)
		"anvil": _anvil(mid)
		"tool_rack": _tool_rack(mid, r)
		"water_tub": _water_tub(mid)
		"feed_box", "nest", "incubator", "feed_sack", "hatch": CoopProps.prop(self, p, mid, r)
		"fodder_box", "stalls", "hay", "barn_gate": BarnProps.prop(self, p, mid, r)
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
## with the ridge along x, a shoji door on the front (+z) face at `door` cells from the left,
## shoji windows, and an indigo noren over the door of a shop.
func _village_house(r: Rect2, door: int, noren: bool) -> void:
	var timber := flat_material(Color("2e221a"))
	var front := r.end.y - 0.15
	var depth := front - r.position.y - 0.1
	var mid_z := r.position.y + 0.1 + depth / 2
	var cx := r.get_center().x
	var wide := r.size.x - 0.2
	_box(Vector3(wide, 0.5, depth), Vector3(cx, 0.25, mid_z), surface_material("build:board"))
	_box(Vector3(wide, 1.1, depth), Vector3(cx, 1.05, mid_z), surface_material("build:plaster"))
	for x in [r.position.x + 0.1, cx, r.end.x - 0.1]:
		_box(Vector3(0.1, 1.6, 0.08), Vector3(x, 0.8, front + 0.02), timber)
	_box(Vector3(wide + 0.06, 0.07, 0.06), Vector3(cx, 1.58, front + 0.03), timber)
	var rise := 0.8
	var gable := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(depth, rise, wide)
	gable.mesh = prism
	gable.material_override = surface_material("build:plaster")
	gable.position = Vector3(cx, 1.6 + rise / 2, mid_z)
	gable.rotation_degrees.y = 90
	add_child(gable)
	var ridge := Vector3(cx, 1.6 + rise, mid_z)
	var slope := atan2(rise, depth / 2)
	var length := (depth / 2 + 0.35) / cos(slope)
	var kawara := surface_material("build:kawara")
	for side in [1, -1]:
		var down := Vector3(0, -sin(slope), cos(slope) * side)
		var up := Vector3(0, cos(slope), sin(slope) * side)
		_box(Vector3(wide + 0.5, 0.09, length), ridge + down * (length / 2 - 0.05) + up * 0.05, kawara,
			Vector3(slope * side, 0, 0))
	_box(Vector3(wide + 0.7, 0.16, 0.22), ridge + Vector3(0, 0.1, 0), flat_material(Color("3a424c")))
	var dx := r.position.x + door + 0.5
	_picture("build:shoji_door", Vector2(0.85, 1.05), Vector3(dx, 0.55, front + 0.005))
	if noren:
		_picture("build:noren", Vector2(0.95, 0.36), Vector3(dx, 1.0, front + 0.03))
	for x in range(int(r.position.x), int(r.end.x)):
		if absf(x + 0.5 - dx) > 1.2 and (x - int(r.position.x)) % 2 == 1:
			_picture("build:shoji", Vector2(0.7, 0.5), Vector3(x + 0.5, 1.1, front + 0.005))
	_picture("build:shoji", Vector2(0.7, 0.5), Vector3(r.end.x - 0.1 + 0.005, 1.1, mid_z), 90)


## A vermilion torii over the shrine path: two round posts on the end cells, the black-capped
## top beam (kasagi) curving past them and the tie beam (nuki) below it.
func _torii(mid: Vector3, r: Rect2) -> void:
	var red := flat_material(VERMILION)
	var span := r.size.x - 1.0
	for x in [r.position.x + 0.5, r.end.x - 0.5]:
		var post := CylinderMesh.new()
		post.top_radius = 0.09
		post.bottom_radius = 0.11
		post.height = 2.1
		post.radial_segments = 10
		var mi := MeshInstance3D.new()
		mi.mesh = post
		mi.material_override = red
		mi.position = Vector3(x, 1.05, mid.z)
		add_child(mi)
		_box(Vector3(0.3, 0.12, 0.3), Vector3(x, 0.06, mid.z), flat_material(Color("2a2420")))
	_box(Vector3(span + 0.5, 0.12, 0.16), Vector3(mid.x, 1.62, mid.z), red)                       # nuki
	_box(Vector3(span + 1.1, 0.16, 0.24), Vector3(mid.x, 2.1, mid.z), red)                        # shimaki
	_box(Vector3(span + 1.3, 0.1, 0.28), Vector3(mid.x, 2.22, mid.z), flat_material(Color("2a2420")))   # kasagi
	_box(Vector3(0.1, 0.36, 0.1), Vector3(mid.x, 1.86, mid.z), red)                               # the strut


## A small wooden shrine (hokora) on a stone base, with a gable roof and a vermilion door.
func _hokora(mid: Vector3) -> void:
	var stone := flat_material(Color("8a8680"))
	_box(Vector3(1.6, 0.3, 1.4), mid + Vector3(0, 0.15, 0), stone)
	_box(Vector3(1.0, 0.8, 0.8), mid + Vector3(0, 0.7, 0), surface_material("build:sugi"))
	_box(Vector3(0.4, 0.5, 0.02), mid + Vector3(0, 0.62, 0.41), flat_material(VERMILION))
	var slope := atan2(0.35, 0.55)
	for side in [1, -1]:
		_box(Vector3(1.4, 0.06, 0.7), mid + Vector3(0, 1.28, 0.27 * side), surface_material("build:planks_dark"),
			Vector3(slope * side, 0, 0))
	_box(Vector3(1.5, 0.08, 0.1), mid + Vector3(0, 1.46, 0), flat_material(Color("2e221a")))


## A stone lantern (toro): base, post, the light box with a warm window, a wide cap.
func _stone_lantern(mid: Vector3) -> void:
	var stone := flat_material(Color("9a968e"))
	_box(Vector3(0.5, 0.12, 0.5), mid + Vector3(0, 0.06, 0), stone)
	_box(Vector3(0.18, 0.55, 0.18), mid + Vector3(0, 0.39, 0), stone)
	_box(Vector3(0.4, 0.08, 0.4), mid + Vector3(0, 0.7, 0), stone)
	_box(Vector3(0.3, 0.26, 0.3), mid + Vector3(0, 0.87, 0), stone)
	_box(Vector3(0.16, 0.14, 0.02), mid + Vector3(0, 0.88, 0.152), flat_material(Color("ffd890")))
	_box(Vector3(0.56, 0.1, 0.56), mid + Vector3(0, 1.05, 0), stone)
	_box(Vector3(0.12, 0.1, 0.12), mid + Vector3(0, 1.15, 0), stone)


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
