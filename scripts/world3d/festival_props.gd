class_name FestivalProps
extends FarmWorld
## Today's festival decorations on one map in 3D (data/festivals.json → props): cherry trees
## and picnic mats, lantern strings and stalls, the moon offering, New Year bamboo, a mochi mortar, the fishing race's flag and a
## bonfire, the contest's judges' table. Built with the map's world when a festival falls on today and is held here, shown
## only during its hours. Lights (lanterns, the fire) are listed in `glows` for FestivalGlow,
## which draws their glow over the night tint. Placeholder looks like MapWorld's props.

const GROUP := "festival_props"
const LANTERN_RED := Color("d8402c")
const LANTERN_PAPER := Color("f0e6c8")
const FLAME := Color("ffb040")

var map_id := ""
var festival := ""
var glows: Array[Dictionary] = []   # {pos: Vector3, color: Color, size: cells across, pool: "round" / "line" / "stall"}
var wares := 0                      # item pictures on the selling stalls' counters


func _init(map: String) -> void:
	map_id = map


func _ready() -> void:
	add_to_group(GROUP)
	festival = Game.festival_today()
	if Festivals.get_festival(festival).get("map", "") == map_id:
		for p in Festivals.get_festival(festival).get("props", []):
			_make(p)
	else:
		festival = ""
	Game.minute_passed.connect(refresh)
	refresh()


## Shown only while the festival is on (its hours, on this map).
func refresh() -> void:
	visible = festival != "" and Festivals.on_now(festival, map_id, Game.hour * 60 + Game.minute)


## Are decorations standing now (for tests and FestivalGlow)?
func shown() -> bool:
	return visible and get_child_count() > 0


func _make(p: Dictionary) -> void:
	var size: Array = p.get("size", [1, 1])
	var r := Rect2(Vector2(p.cell[0], p.cell[1]), Vector2(size[0], size[1]))
	var mid := Vector3(r.get_center().x, 0, r.get_center().y)
	var cloth := Color(str(p.get("cloth", "c8442c")))
	match str(p.kind):
		"sakura": _sakura(mid)
		"picnic_mat": _mat(mid, r, Color("3a6ab0"))
		"red_mat": _mat(mid, r, Color("b02a24"))
		"stall":
			_stall(mid, r, cloth)
			_wares(mid, r, Festivals.stall_of_prop(festival, p))
		"judge_table": _judge_table(mid, r)
		"lantern_line": _lantern_line(r)
		"drum_stage": _drum_stage(mid)
		"moon_table": _moon_table(mid)
		"pampas": _pampas(mid)
		"paper_lantern": _paper_lantern(mid)
		"kadomatsu": _kadomatsu(mid)
		"bonfire": _bonfire(mid)
		"mochi_usu": _mochi_usu(mid)
		"race_flag": _race_flag(mid)
		_:
			push_warning("FestivalProps: no look for prop '%s'" % p.kind)
			_box(Vector3(r.size.x, 0.5, r.size.y) * 0.9, mid + Vector3(0, 0.25, 0), flat_material(Color.MAGENTA))


## A light at `pos` (FestivalGlow's glow, NightLamps' lamp) and the pool it casts on the ground
## (NightLights.festival_pools): "round" under it, "line" a string lantern's fainter one, "stall"
## in front of the counter of a stall `wide` cells across standing at `mid`.
func _glow(pos: Vector3, color: Color, size: float, pool := "round", mid := Vector3.ZERO, wide := 0.0) -> void:
	glows.append({"pos": pos, "color": color, "size": size, "pool": pool, "mid": mid, "wide": wide})


func _cylinder(top: float, bottom: float, height: float, at: Vector3, mat: Material, segments := 8) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = segments
	c.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	return mi


func _ball(radius: float, at: Vector3, mat: Material) -> void:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2
	s.radial_segments = 8
	s.rings = 4
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = mat
	mi.position = at
	add_child(mi)


## A cherry tree in bloom (Trees.broadleaf in spring): a crown of pink lumps, petals on the
## ground.
func _sakura(mid: Vector3) -> void:
	var parts := FarmProps.Parts.new()
	Trees.broadleaf(parts, mid, "sakura", "spring", int(mid.x * 7 + mid.z * 13))
	parts.commit(self)


## A mat spread on the grass with a lunch box and teacups on it.
func _mat(mid: Vector3, r: Rect2, color: Color) -> void:
	_box(Vector3(r.size.x - 0.1, 0.03, r.size.y - 0.1), mid + Vector3(0, 0.015, 0), flat_material(color))
	_box(Vector3(0.36, 0.12, 0.26), mid + Vector3(-0.15, 0.09, 0), flat_material(Color("2a1a14")))   # the lunch box
	_box(Vector3(0.3, 0.02, 0.2), mid + Vector3(-0.15, 0.16, 0), flat_material(Color("b02a24")))
	for x in [0.2, 0.34]:
		_cylinder(0.05, 0.04, 0.08, mid + Vector3(x, 0.07, 0.12), flat_material(Color("e8e0cc")))


## A festival stall (yatai): a plank counter, four posts, a sloping roof in its cloth colour,
## a short curtain over the front and a lantern at the front corner.
func _stall(mid: Vector3, r: Rect2, cloth: Color) -> void:
	var wood := flat_material(Color("6a4a30"))
	var w := r.size.x - 0.2
	_box(Vector3(w, 0.7, 0.6), mid + Vector3(0, 0.35, -0.1), surface_material("build:planks"))
	_box(Vector3(w + 0.06, 0.05, 0.66), mid + Vector3(0, 0.72, -0.1), flat_material(Color("8a6a48")))
	for x in [-w / 2, w / 2]:
		for z in [-0.4, 0.3]:
			_box(Vector3(0.06, 1.5, 0.06), mid + Vector3(x, 0.75, z), wood)
	_box(Vector3(w + 0.3, 0.06, 1.0), mid + Vector3(0, 1.55, -0.05), flat_material(cloth), Vector3(-0.25, 0, 0))
	_box(Vector3(w, 0.26, 0.02), mid + Vector3(0, 1.32, 0.36), flat_material(cloth.lerp(Color.WHITE, 0.25)))
	var lamp := mid + Vector3(w / 2, 1.2, 0.36)
	_lantern(lamp, LANTERN_RED, "stall", mid, w)


## A selling stall's stock set out along its counter, one item picture each (the same icons
## as in the rucksack).
func _wares(mid: Vector3, r: Rect2, stall: Dictionary) -> void:
	var stock: Array = stall.get("stock", [])
	var w := r.size.x - 0.5
	for i in stock.size():
		var s := make_sprite(PlaceholderArt.tex(PlaceholderArt.item_key(str(stock[i].item))))
		s.pixel_size = 0.028
		s.position = mid + Vector3(-w / 2 + w * (i + 0.5) / stock.size(), 0.75, 0.05)
		add_child(s)
		wares += 1


## The contest's judges' table: a long low table under a white cloth, a red and white
## curtain along its front, a name board on two posts behind it and three ribbon rosettes
## (red, white, blue) waiting for the winners.
func _judge_table(mid: Vector3, r: Rect2) -> void:
	var w := r.size.x - 0.15
	var wood := flat_material(Color("6a4a30"))
	_box(Vector3(w, 0.5, 0.55), mid + Vector3(0, 0.25, -0.05), wood)
	_box(Vector3(w + 0.04, 0.04, 0.6), mid + Vector3(0, 0.52, -0.05), flat_material(Color("f4f0e6")))
	var stripes := int(w / 0.25)
	for i in stripes:
		var c := LANTERN_RED if i % 2 == 0 else Color("f4f0e6")
		_box(Vector3(w / stripes, 0.42, 0.02), mid + Vector3(-w / 2 + (i + 0.5) * w / stripes, 0.27, 0.24), flat_material(c))
	for x in [-w / 2 + 0.1, w / 2 - 0.1]:
		_box(Vector3(0.05, 1.3, 0.05), mid + Vector3(x, 0.65, -0.35), wood)
	_box(Vector3(w - 0.1, 0.3, 0.04), mid + Vector3(0, 1.15, -0.35), flat_material(Color("e8dcc0")))
	_box(Vector3(w - 0.4, 0.05, 0.05), mid + Vector3(0, 1.15, -0.32), flat_material(Color("2a2420")))   # the brushed name
	for i in 3:
		var at := mid + Vector3((i - 1) * 0.3, 0.6, -0.05)
		var rosette := _cylinder(0.07, 0.07, 0.02, at, flat_material([LANTERN_RED, Color("f4f0e6"), Color("2c4a8a")][i]), 10)
		rosette.rotation_degrees = Vector3(70, 0, 0)


## One hanging paper lantern: a round body, dark caps top and bottom.
func _lantern(at: Vector3, color: Color, pool := "line", mid := Vector3.ZERO, wide := 0.0) -> void:
	_cylinder(0.11, 0.11, 0.22, at, flat_material(color), 10)
	var cap := flat_material(Color("2a2420"))
	_cylinder(0.07, 0.07, 0.03, at + Vector3(0, 0.12, 0), cap)
	_cylinder(0.07, 0.07, 0.03, at - Vector3(0, 0.12, 0), cap)
	_glow(at, color.lerp(Color("ffd890"), 0.5), 1.4, pool, mid, wide)


## A string of lanterns over the cells: a pole at each end, a rope and a lantern every cell,
## red and white in turn.
func _lantern_line(r: Rect2) -> void:
	var z := r.get_center().y
	var wood := flat_material(Color("5a4030"))
	for x in [r.position.x + 0.1, r.end.x - 0.1]:
		_box(Vector3(0.08, 1.9, 0.08), Vector3(x, 0.95, z), wood)
	_box(Vector3(r.size.x - 0.2, 0.02, 0.02), Vector3(r.get_center().x, 1.82, z), flat_material(Color("2a2420")))
	for i in int(r.size.x):
		_lantern(Vector3(r.position.x + i + 0.5, 1.62, z), LANTERN_RED if i % 2 == 0 else LANTERN_PAPER)


## A drum stage: a platform on legs with red and white cloth round it and a big drum on top.
func _drum_stage(mid: Vector3) -> void:
	var wood := flat_material(Color("5a3a24"))
	for o in [Vector3(-0.8, 0, -0.8), Vector3(0.8, 0, -0.8), Vector3(-0.8, 0, 0.8), Vector3(0.8, 0, 0.8)]:
		_box(Vector3(0.1, 0.9, 0.1), mid + o + Vector3(0, 0.45, 0), wood)
	_box(Vector3(1.8, 0.1, 1.8), mid + Vector3(0, 0.92, 0), surface_material("build:planks"))
	for i in 6:
		var c := LANTERN_RED if i % 2 == 0 else Color("f4f0e6")
		_box(Vector3(0.3, 0.4, 0.02), mid + Vector3(-0.75 + i * 0.3, 0.65, 0.91), flat_material(c))
		_box(Vector3(0.02, 0.4, 0.3), mid + Vector3(0.91, 0.65, -0.75 + i * 0.3), flat_material(c))
	var drum := _cylinder(0.32, 0.32, 0.5, mid + Vector3(0, 1.32, 0), flat_material(Color("8a4a2a")), 12)
	drum.rotation_degrees = Vector3(0, 45, 90)
	_glow(mid + Vector3(0, 1.3, 0), Color("ffd890"), 2.2)


## The moon offering: a small white wooden stand with a pyramid of round dango.
func _moon_table(mid: Vector3) -> void:
	_box(Vector3(0.5, 0.3, 0.5), mid + Vector3(0, 0.15, 0), flat_material(Color("d8c8a0")))
	_box(Vector3(0.6, 0.04, 0.6), mid + Vector3(0, 0.32, 0), flat_material(Color("e8dcc0")))
	var dango := flat_material(Color("f8f4ea"))
	for y in 3:
		var n := 3 - y
		for i in n:
			for j in n:
				_ball(0.06, mid + Vector3((i - (n - 1) / 2.0) * 0.12, 0.4 + y * 0.1, (j - (n - 1) / 2.0) * 0.12), dango)


## Pampas grass in a tall vase: grey stalks with pale silver plumes.
func _pampas(mid: Vector3) -> void:
	_cylinder(0.1, 0.13, 0.45, mid + Vector3(0, 0.22, 0), flat_material(Color("4a5a6a")))
	var stalk := flat_material(Color("8a8a6a"))
	var plume := flat_material(Color("e4dcc4"))
	for i in 5:
		var lean := Vector3((i - 2) * 0.12, 0, (i % 2) * 0.08 - 0.04)
		_box(Vector3(0.02, 0.9, 0.02), mid + lean * 0.5 + Vector3(0, 0.85, 0), stalk, Vector3(lean.z, 0, -lean.x))
		_box(Vector3(0.07, 0.3, 0.07), mid + lean + Vector3(0, 1.35, 0), plume, Vector3(lean.z, 0, -lean.x))


## A standing paper lantern on a short pole.
func _paper_lantern(mid: Vector3) -> void:
	_box(Vector3(0.06, 1.1, 0.06), mid + Vector3(0, 0.55, 0), flat_material(Color("2a2420")))
	_cylinder(0.16, 0.16, 0.36, mid + Vector3(0, 1.25, 0), flat_material(LANTERN_PAPER), 10)
	_cylinder(0.1, 0.1, 0.04, mid + Vector3(0, 1.45, 0), flat_material(Color("2a2420")))
	_glow(mid + Vector3(0, 1.25, 0), Color("ffe0a0"), 1.8)


## New Year bamboo: three cut green stalks of different heights in a straw-bound base, pine sprigs.
func _kadomatsu(mid: Vector3) -> void:
	_cylinder(0.24, 0.26, 0.4, mid + Vector3(0, 0.2, 0), flat_material(Color("c8a868")))
	_box(Vector3(0.54, 0.04, 0.54), mid + Vector3(0, 0.3, 0), flat_material(Color("6a4a2a")))
	var bamboo := flat_material(Color("5a9a48"))
	for s in [[Vector3(0, 0, -0.06), 1.3], [Vector3(-0.1, 0, 0.07), 1.05], [Vector3(0.1, 0, 0.07), 0.85]]:
		_cylinder(0.05, 0.05, s[1], mid + s[0] + Vector3(0, s[1] / 2.0, 0), bamboo)
		_cylinder(0.04, 0.04, 0.01, mid + s[0] + Vector3(0, s[1] + 0.005, 0), flat_material(Color("d8e8b0")))
	var pine := flat_material(Color("2f5a34"))
	for a in [0.0, 2.1, 4.2]:
		_cylinder(0.0, 0.14, 0.24, mid + Vector3(cos(a) * 0.17, 0.46, sin(a) * 0.17), pine)


## A shrine bonfire: a ring of stones, crossed logs and the flame.
func _bonfire(mid: Vector3) -> void:
	var stone := flat_material(Color("7a766e"))
	for i in 8:
		var a := i * TAU / 8
		_box(Vector3(0.14, 0.1, 0.14), mid + Vector3(cos(a) * 0.36, 0.05, sin(a) * 0.36), stone)
	var log_mat := flat_material(Color("4a3020"))
	for a in [0.4, -0.4]:
		_box(Vector3(0.7, 0.08, 0.08), mid + Vector3(0, 0.1, 0), log_mat, Vector3(0, a + PI / 4, 0.25))
	_cylinder(0.0, 0.22, 0.55, mid + Vector3(0, 0.38, 0), flat_material(FLAME))
	_cylinder(0.0, 0.11, 0.35, mid + Vector3(0, 0.32, 0), flat_material(Color("fff0a0")))
	_glow(mid + Vector3(0, 0.4, 0), FLAME, 3.0)


## The mochi pounding's mortar (a festival game's prop): a hooped log hollowed on top with
## the white dough in it, the mallet leaning on its side and a pail of water for the hands.
func _mochi_usu(mid: Vector3) -> void:
	var wood := flat_material(PlaceholderArt.MOCHI_WOOD)
	_cylinder(0.3, 0.33, 0.5, mid + Vector3(0, 0.25, 0), wood, 12)
	for y in [0.12, 0.4]:
		_cylinder(0.335, 0.335, 0.04, mid + Vector3(0, y, 0), flat_material(PlaceholderArt.MOCHI_HOOP), 12)
	_cylinder(0.22, 0.22, 0.02, mid + Vector3(0, 0.505, 0), flat_material(PlaceholderArt.MOCHI_WOOD_DARK), 12)
	_cylinder(0.12, 0.18, 0.1, mid + Vector3(0, 0.55, 0), flat_material(PlaceholderArt.MOCHI_DOUGH), 12)   # the dough mound
	var handle := flat_material(Color("c8a06a"))
	_box(Vector3(0.05, 0.9, 0.05), mid + Vector3(0.42, 0.45, 0.05), handle, Vector3(0, 0, 0.25))
	var head := _cylinder(0.09, 0.09, 0.3, mid + Vector3(0.53, 0.88, 0.05), wood, 10)
	head.rotation_degrees = Vector3(0, 0, 90)
	_cylinder(0.12, 0.1, 0.18, mid + Vector3(-0.45, 0.09, 0.15), flat_material(Color("8a7a5a")), 10)   # the pail
	_cylinder(0.1, 0.1, 0.01, mid + Vector3(-0.45, 0.17, 0.15), flat_material(Color("6aa0c8")), 10)


## The fishing race's start (a festival game's prop): a bamboo pole with a tall indigo banner
## hung from a crossbar, a white fish on it, and the race's creel at its foot.
func _race_flag(mid: Vector3) -> void:
	var pole := flat_material(Color("b89a5a"))
	var at := mid + Vector3(-0.25, 0, 0)
	_cylinder(0.03, 0.035, 1.7, at + Vector3(0, 0.85, 0), pole)
	_box(Vector3(0.5, 0.03, 0.03), at + Vector3(0.25, 1.62, 0), pole)
	_box(Vector3(0.44, 1.05, 0.02), at + Vector3(0.25, 1.08, 0), flat_material(PlaceholderArt.RACE_CLOTH))
	_box(Vector3(0.14, 0.32, 0.03), at + Vector3(0.25, 1.18, 0), flat_material(PlaceholderArt.RACE_MARK))   # the fish
	_box(Vector3(0.22, 0.05, 0.03), at + Vector3(0.25, 0.98, 0), flat_material(PlaceholderArt.RACE_MARK))   # its tail
	_cylinder(0.16, 0.13, 0.26, mid + Vector3(0.2, 0.13, 0.15), flat_material(PlaceholderArt.RACE_CREEL), 10)
	_cylinder(0.165, 0.165, 0.03, mid + Vector3(0.2, 0.2, 0.15), flat_material(PlaceholderArt.RACE_CREEL.darkened(0.25)), 10)


## The lights a festival's decorations give on a map (as in `glows`), without keeping the
## meshes: the flat view's FestivalView reads them for FestivalGlow.
static func glows_of(fest: String, map: String) -> Array[Dictionary]:
	var fp := FestivalProps.new(map)
	fp.festival = fest
	for p in Festivals.get_festival(fest).get("props", []):
		fp._make(p)
	var out := fp.glows
	fp.free()
	return out
