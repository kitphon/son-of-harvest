class_name StallWares
extends RefCounted
## The festival stalls' wares as lit meshes on the counter (FestivalProps._wares): one mesh a
## stall, painted by its vertices (OutdoorProps._vertex_material), the goods set out in the
## slots the item pictures had: dango skewers on a tray, sakura mochi on a plate, green tea with
## a pot, yakisoba heaped on a griddle, shaved ice in footed glasses with a little flag, marble
## soda bottles standing in a tub of water, wind chimes on a stand (their paper strips blow in the
## wind), paper fans in a block, roast chestnuts in a pan on a brazier, sweet potatoes on hot
## stones, clay rabbits on a cloth, moon lanterns, a bowl of year-end soba by a stack of bowls,
## yuzu tea with the fruit, daruma, and charms hung on a little rack. Hot food gives off steam
## (Steam: a few pale puffs rising and fading). The colours follow the items' looks in
## data/foods.json and data/keepsakes.json. An item with no look here keeps its picture.

const COUNTER_TOP := 0.745   # FestivalMeshes.stall's counter top
const SLOT_Z := 0.0          # toward the counter's front (its top spans -0.43..0.23 from the stall's middle),
                             # so the wares show under the curtain from the game's camera
const TALL := 0.28           # no ware stands higher above the counter (the curtain hides more)

const WOOD := Color("6a4a30")
const WOOD_LIGHT := Color("a8845a")
const LACQUER := Color("2a1a14")
const LACQUER_RED := Color("a82a20")
const IRON := Color("2e2a28")
const INK := Color("1e1c1a")
const PORCELAIN := Color("ece4d4")
const GLASS := Color("b8d8e4")

## The items with a mesh here.
const LOOKS := ["food:dango", "food:sakura_mochi", "food:green_tea", "food:yakisoba", "food:shaved_ice", "food:marble_soda",
	"keep:wind_chime", "keep:paper_fan", "food:roast_chestnuts", "food:baked_imo", "keep:clay_rabbit", "keep:moon_lantern",
	"food:year_soba", "food:yuzu_tea", "keep:daruma", "keep:omamori"]
## The stalls that sell nothing set out a display instead (a stall prop's "display" in
## data/festivals.json): a goldfish-scooping tub with swimming fish, a stand of festival masks.
const DISPLAYS := Festivals.DISPLAYS
## The hot ones: steam rises from them.
const STEAMING := ["food:yakisoba", "food:roast_chestnuts", "food:baked_imo", "food:year_soba", "food:yuzu_tea", "food:green_tea"]


static func has_look(item: String) -> bool:
	return item in LOOKS


## Where slot `i` of `n` stands on the counter of a stall `r` round `mid` (on its top): spread
## along it, a little left of the middle, clear of the lantern at the right front corner.
static func slot(mid: Vector3, r: Rect2, i: int, n: int) -> Vector3:
	var w := r.size.x - 0.6
	return Vector3(mid.x - 0.1 - w / 2 + w * (i + 0.5) / n, COUNTER_TOP, mid.z + SLOT_Z)


## Sets `items` (item ids) out along the counter of the stall `r` round `mid`: one lit mesh for
## them all (its meta "wares" lists the items built), steam over the hot ones. The indices of
## the items with no look here (the caller puts their pictures there).
static func build(w: FarmWorld, mid: Vector3, r: Rect2, items: Array) -> Array[int]:
	var missing: Array[int] = []
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var built := []
	for i in items.size():
		var item := str(items[i])
		if not has_look(item):
			missing.append(i)
			continue
		var at := slot(mid, r, i, items.size())
		var steam_at: Variant = _ware(item, st, at, w, int(mid.x * 7 + i * 3))
		built.append(item)
		if steam_at is Vector3:
			var s := Steam.new(int(mid.x * 13 + i * 5))
			s.position = steam_at
			w.add_child(s)
	if not built.is_empty():
		var mi := Minka.add_mesh(w, st, OutdoorProps._vertex_material())
		mi.set_meta("wares", built)
	return missing


## Sets the display `kind` (one of DISPLAYS) out on the counter of the stall `r` round `mid`: one
## lit mesh (its meta "display" is `kind`), the goldfish as small meshes of their own that swim.
## False for a kind that is not known.
static func display(w: FarmWorld, mid: Vector3, r: Rect2, kind: String) -> bool:
	if kind not in DISPLAYS:
		return false
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := slot(mid, r, 0, 1)
	match kind:
		"goldfish": _goldfish(st, w, mid, a)
		"masks": _masks(st, w, mid, a)
	var mi := Minka.add_mesh(w, st, OutdoorProps._vertex_material())
	mi.set_meta("display", kind)
	return true


## Builds `item` round `a` into `st`; where its steam rises (a Vector3) or null.
static func _ware(item: String, st: SurfaceTool, a: Vector3, w: FarmWorld, sd: int) -> Variant:
	match item:
		"food:dango": return _dango(st, a, w, sd)
		"food:sakura_mochi": return _sakura_mochi(st, a, w, sd)
		"food:green_tea": return _green_tea(st, a, w, sd)
		"food:yakisoba": return _yakisoba(st, a, w, sd)
		"food:shaved_ice": return _shaved_ice(st, a, w, sd)
		"food:marble_soda": return _marble_soda(st, a, w, sd)
		"keep:wind_chime": return _wind_chime(st, a, w, sd)
		"keep:paper_fan": return _paper_fan(st, a, w, sd)
		"food:roast_chestnuts": return _roast_chestnuts(st, a, w, sd)
		"food:baked_imo": return _baked_imo(st, a, w, sd)
		"keep:clay_rabbit": return _clay_rabbit(st, a, w, sd)
		"keep:moon_lantern": return _moon_lantern(st, a, w, sd)
		"food:year_soba": return _year_soba(st, a, w, sd)
		"food:yuzu_tea": return _yuzu_tea(st, a, w, sd)
		"keep:daruma": return _daruma(st, a, w, sd)
		"keep:omamori": return _omamori(st, a, w, sd)
	return null


# --- small pieces -------------------------------------------------------------------

static func _paint(st: SurfaceTool, c: Color) -> SurfaceTool:
	st.set_color(c)
	return st


## A lathe shape in colour `c`.
static func _turn(st: SurfaceTool, c: Color, at: Vector3, profile: Array, sides := 8) -> void:
	Shrine.lathe(_paint(st, c), at, profile, sides)


## A box on its bottom middle in colour `c` (RoomProps._cube).
static func _box(st: SurfaceTool, c: Color, at: Vector3, size: Vector3, bevel := 0.0) -> void:
	RoomProps._cube(_paint(st, c), at, size, bevel)


## A tube from `base` along `dir` in colour `c` (OutdoorProps._tube).
static func _rod(st: SurfaceTool, c: Color, base: Vector3, dir: Vector3, length: float, rad: float, sides := 5) -> void:
	OutdoorProps._tube(st, base, dir.normalized(), [Vector2(rad, 0.0), Vector2(rad, length)], sides, c)


## Built round the origin by `make`, then moved by `xf` (RoomProps._placed), in colour `c`.
static func _moved(st: SurfaceTool, c: Color, xf: Transform3D, make: Callable) -> void:
	var tmp := SurfaceTool.new()
	tmp.begin(Mesh.PRIMITIVE_TRIANGLES)
	tmp.set_color(c)
	make.call(tmp)
	st.append_from(tmp.commit(), 0, xf)


## A round disc `rad` across and `thick` thick, its face looking +z, centred on `at` (fans,
## faces), leaned back by `lean` radians.
static func _disc(st: SurfaceTool, c: Color, at: Vector3, rad: float, thick: float, lean := 0.0, sides := 10) -> void:
	var xf := Transform3D(Basis(Vector3.RIGHT, lean) * Basis(Vector3.RIGHT, PI / 2), at)
	_moved(st, c, xf, func(t: SurfaceTool) -> void:
		Shrine.lathe(t, Vector3(0, -thick / 2, 0), [Vector2(rad, 0.0), Vector2(rad, thick), Vector2(0.0, thick)], sides))


## A cup or bowl: a wall from `foot` (radius at the bottom) out to `rim` at height `h`, a thin
## lip, the inside wall down to `fill` (its height) and the fill's surface in `inside`.
static func _vessel(st: SurfaceTool, at: Vector3, foot: float, rim: float, h: float, wall: Color, fill: float, inside: Color, lining := Color(0, 0, 0, 0)) -> void:
	var lip := 0.006
	var r_fill := lerpf(foot, rim, fill / h) - lip
	_turn(st, wall, at, [Vector2(foot, 0.0), Vector2(rim, h), Vector2(rim - lip, h)], 10)
	_turn(st, lining if lining.a > 0.0 else wall, at, [Vector2(rim - lip, h), Vector2(r_fill, fill)], 10)
	_turn(st, inside, at, [Vector2(r_fill, fill), Vector2(0.0, fill)], 10)


## A flat tray `size` (x, z) on the counter.
static func _tray(st: SurfaceTool, c: Color, at: Vector3, size: Vector2, high := 0.022) -> void:
	_box(st, c, at, Vector3(size.x, high, size.y), 0.006)


# --- the wares ---------------------------------------------------------------------
# Each builds round `a` (its slot on the counter top) into `st`; `w` for parts of their own (a
# chime's strip in the wind); returns where steam rises (a Vector3) or null. STEAMING lists the
# hot ones (the ones that return a point).

## Three skewers of dango (pink, white, green) lying on a lacquered tray, two more standing in a cup.
static func _dango(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	_tray(st, Color("7a2a1e"), a + Vector3(-0.04, 0, 0), Vector2(0.32, 0.24))
	var balls: Array[Color] = [Color("f0a8b8"), Color("f6f2e6"), Color("8ab858")]
	for z in [-0.075, 0.0, 0.075]:
		var y := 0.022 + 0.03
		_rod(st, Color("d8c08a"), a + Vector3(-0.19, y, z), Vector3.RIGHT, 0.29, 0.005, 4)
		for k in 3:
			RoomProps._ball(_paint(st, balls[k]), a + Vector3(-0.1 + k * 0.064, 0.022, z), 0.03)
	var cup := a + Vector3(0.16, 0, -0.05)
	_vessel(st, cup, 0.032, 0.036, 0.07, Color("4a5a6a"), 0.05, Color("3a3028"))
	for k in 2:   # two upright skewers in the cup
		var d := Vector3(-0.15 + k * 0.3, 1.0, 0.1).normalized()
		_rod(st, Color("d8c08a"), cup + Vector3(0, 0.03, 0), d, 0.2, 0.005, 4)
		for b in 3:
			var c := cup + Vector3(0, 0.03, 0) + d * (0.08 + b * 0.045)
			RoomProps._ball(_paint(st, balls[b]), c - Vector3(0, 0.024, 0), 0.024)
	return null


## Sakura mochi on a round plate: pink cakes half wrapped in a green leaf, a salted blossom on each.
static func _sakura_mochi(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	_turn(st, PORCELAIN, a, [Vector2(0.09, 0.0), Vector2(0.15, 0.02), Vector2(0.145, 0.028), Vector2(0.0, 0.022)], 12)
	for o in [Vector3(-0.06, 0, -0.045), Vector3(0.06, 0, -0.045), Vector3(0.0, 0, 0.06)]:
		var at: Vector3 = a + o + Vector3(0, 0.022, 0)
		_turn(st, Color("f4b8c8"), at, [Vector2(0.03, 0.0), Vector2(0.046, 0.018), Vector2(0.044, 0.04), Vector2(0.03, 0.06), Vector2(0.0, 0.068)], 8)
		_turn(st, Color("6a9a48"), at, [Vector2(0.034, -0.002), Vector2(0.05, 0.018), Vector2(0.049, 0.032)], 8)   # the leaf round its foot
		_turn(st, Color("e85a78"), at + Vector3(0, 0.066, 0), [Vector2(0.012, 0.0), Vector2(0.0, 0.006)], 5)
	return null


## Green tea: a brown side-handled pot and two celadon cups of tea on a tray.
static func _green_tea(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	_tray(st, WOOD_LIGHT, a, Vector2(0.38, 0.24))
	var pot := a + Vector3(-0.09, 0.022, 0)
	var clay := Color("6a3a24")
	_turn(st, clay, pot, [Vector2(0.045, 0.0), Vector2(0.065, 0.03), Vector2(0.062, 0.07), Vector2(0.04, 0.09), Vector2(0.0, 0.094)], 10)
	_turn(st, clay.darkened(0.25), pot + Vector3(0, 0.09, 0), [Vector2(0.012, 0.0), Vector2(0.01, 0.018), Vector2(0.0, 0.022)], 6)
	_rod(st, clay, pot + Vector3(0.05, 0.04, 0), Vector3(1, 0.7, 0), 0.06, 0.01, 5)    # the spout
	_rod(st, clay.darkened(0.1), pot + Vector3(-0.03, 0.05, 0.04), Vector3(-0.3, 0.1, 1), 0.09, 0.012, 5)   # the side handle
	for x in [0.05, 0.13]:
		_vessel(st, a + Vector3(x, 0.022, 0.02), 0.026, 0.036, 0.06, Color("b8ccb0"), 0.048, Color("8aa840"))
	return a + Vector3(0.09, 0.09, 0.02)


## Yakisoba heaped on an iron griddle: brown noodles with cabbage, red ginger and green flakes,
## a spatula lying on the edge.
static func _yakisoba(st: SurfaceTool, a: Vector3, _w: FarmWorld, sd: int) -> Variant:
	_box(st, IRON, a, Vector3(0.42, 0.03, 0.3), 0.006)
	var heap := a + Vector3(0.0, 0.03, 0.0)
	var noodle := Color("b8743a")
	_turn(st, noodle, heap, [Vector2(0.15, 0.0), Vector2(0.13, 0.03), Vector2(0.08, 0.06), Vector2(0.0, 0.07)], 10)
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	for k in 14:   # tangles of noodle, cabbage, ginger and green flakes over the heap
		var ang := rng.randf() * TAU
		var rad := sqrt(rng.randf()) * 0.12
		var y := 0.07 * (1.0 - rad / 0.15) - 0.008
		var at := heap + Vector3(cos(ang) * rad, y, sin(ang) * rad * 0.9)
		var c: Color = [noodle.darkened(0.15), Color("d8e0a8"), Color("d83a3a"), Color("3a6a2a"), noodle.lightened(0.1)][k % 5]
		if k % 5 == 0 or k % 5 == 4:
			RoomProps._ball(_paint(st, c), at, 0.018)
		else:
			_box(st, c, at, Vector3(0.026, 0.012, 0.02))
	_box(st, Color("a8a8a8"), a + Vector3(0.15, 0.03, 0.08), Vector3(0.07, 0.006, 0.05))   # the spatula
	_rod(st, WOOD_LIGHT, a + Vector3(0.18, 0.036, 0.08), Vector3(1, 0.15, 0.4), 0.08, 0.008, 4)
	return heap + Vector3(0, 0.08, 0)


## Shaved ice in two footed glasses, strawberry and melon syrup over the snow, a little flag (a
## white cloth with a blue wave under a red band) on a stick.
static func _shaved_ice(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	for g in [[Vector3(-0.08, 0, 0.02), Color("c8442c")], [Vector3(0.06, 0, -0.04), Color("6ac84a")]]:
		var at: Vector3 = a + g[0]
		_turn(st, GLASS, at, [Vector2(0.034, 0.0), Vector2(0.034, 0.006), Vector2(0.012, 0.014), Vector2(0.012, 0.032), Vector2(0.04, 0.042), Vector2(0.056, 0.09)], 10)
		_turn(st, Color("f4f8fc"), at, [Vector2(0.056, 0.09), Vector2(0.056, 0.11), Vector2(0.042, 0.148), Vector2(0.0, 0.168)], 10)
		_turn(st, g[1], at, [Vector2(0.047, 0.128), Vector2(0.032, 0.155), Vector2(0.0, 0.172)], 10)
	var pole := a + Vector3(0.17, 0, -0.14)
	_box(st, WOOD, pole, Vector3(0.06, 0.02, 0.06))
	_rod(st, Color("c8a06a"), pole, Vector3.UP, 0.26, 0.007, 4)
	var cloth := Vector3(pole.x - 0.004 - 0.06, a.y, pole.z + 0.01)
	_box(st, Color("f4f0e6"), cloth + Vector3(0, 0.1, 0), Vector3(0.12, 0.15, 0.006))
	_box(st, Color("c8442c"), cloth + Vector3(0, 0.21, 0.004), Vector3(0.12, 0.04, 0.006))
	_box(st, Color("2c6aa8"), cloth + Vector3(0, 0.11, 0.004), Vector3(0.12, 0.03, 0.006))
	return null


## Marble soda: aqua bottles with blue caps standing in a hooped tub of water with ice in it.
static func _marble_soda(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	var tub := a + Vector3(-0.02, 0, 0)
	_vessel(st, tub, 0.12, 0.14, 0.11, WOOD_LIGHT, 0.085, Color("5a9ac8"), WOOD)
	for y in [0.025, 0.085]:
		_turn(st, Color("3a2e22"), tub, [Vector2(0.123 + y * 0.18 + 0.004, y - 0.008), Vector2(0.123 + y * 0.18 + 0.004, y + 0.008)], 10)
	var water := tub + Vector3(0, 0.085, 0)
	for o in [Vector3(-0.05, 0, -0.03), Vector3(0.04, 0, -0.05), Vector3(0.0, 0, 0.05), Vector3(0.07, 0, 0.04)]:
		var at: Vector3 = water + o - Vector3(0, 0.06, 0)
		_turn(st, Color("7ac8c0"), at, [Vector2(0.022, 0.04), Vector2(0.024, 0.11), Vector2(0.015, 0.14), Vector2(0.011, 0.155),
			Vector2(0.017, 0.168), Vector2(0.012, 0.185), Vector2(0.012, 0.205)], 8)
		_turn(st, Color("2c4ac8"), at + Vector3(0, 0.205, 0), [Vector2(0.014, 0.0), Vector2(0.014, 0.014), Vector2(0.0, 0.016)], 8)
		RoomProps._ball(_paint(st, Color("e8f4f4")), at + Vector3(0, 0.148, 0), 0.01)   # the marble showing in the neck
	for o in [Vector3(-0.08, 0, 0.06), Vector3(0.09, 0, -0.06)]:
		_box(st, Color("eef6f8"), water + o - Vector3(0, 0.008, 0), Vector3(0.03, 0.02, 0.028))
	return null


## Two wind chimes hanging from a little stand: glass bells with a red band, a clapper cord and a
## paper strip under each; the strips blow in the wind (OutdoorProps.commit_swaying).
static func _wind_chime(st: SurfaceTool, a: Vector3, w: FarmWorld, sd: int) -> Variant:
	var wood := Color("5a3a24")
	_box(st, wood, a, Vector3(0.4, 0.025, 0.08), 0.005)
	for x in [-0.18, 0.18]:
		_box(st, wood, a + Vector3(x, 0.025, 0), Vector3(0.025, 0.25, 0.025))
	var bar := a + Vector3(0, 0.25, 0)
	_box(st, wood, bar, Vector3(0.42, 0.02, 0.03))
	var strips: Array[Color] = [Color("f4f0e6"), Color("e8d0e0")]
	for k in 2:
		var x := -0.08 + k * 0.16
		var top := bar + Vector3(x, 0, 0)
		_rod(st, INK, top, Vector3.DOWN, 0.02, 0.003, 3)
		var bell := top - Vector3(0, 0.02 + 0.058, 0)
		_turn(st, Color("a8d4ec"), bell, [Vector2(0.0, 0.0), Vector2(0.044, 0.0), Vector2(0.042, 0.025), Vector2(0.03, 0.05), Vector2(0.0, 0.058)], 10)
		_turn(st, Color("c8442c"), bell, [Vector2(0.0445, 0.006), Vector2(0.0425, 0.02)], 10)
		_rod(st, INK, bell, Vector3.DOWN, 0.03, 0.003, 3)
		var hinge := bell - Vector3(0, 0.03, 0)
		var sp := FarmProps.Parts.new()
		RoomProps._cube(sp.st(strips[k]), hinge - Vector3(0, 0.1, 0), Vector3(0.04, 0.1, 0.006))
		OutdoorProps.commit_swaying(w, sp, hinge, "cloth", sd + k * 2.3, 0.0)
	return null


## Round paper fans (uchiwa) standing in a wooden block: one white with a red sun, one indigo
## with a pale moon, one cream with a blue wave band.
static func _paper_fan(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	_box(st, WOOD, a + Vector3(0, 0, -0.04), Vector3(0.36, 0.05, 0.07), 0.008)
	var fans := [[Color("f0e6c8"), Color("c8442c"), 0.04], [Color("2c4a8a"), Color("f0dc98"), 0.035], [Color("f4f0e6"), Color("2c4a8a"), 0.0]]
	for k in 3:
		var x := -0.12 + k * 0.12
		var lean := -0.22 + 0.03 * k
		var foot := a + Vector3(x, 0.03, -0.04)
		var up := Vector3(0, cos(lean), sin(lean))
		_rod(st, Color("c8a06a"), foot, up, 0.07, 0.007, 4)
		var face: Vector3 = foot + up * 0.14
		var f: Array = fans[k]
		_disc(st, f[0], face, 0.075, 0.006, lean)
		var front := Vector3(0, sin(-lean), cos(lean)) * 0.004
		if float(f[2]) > 0.0:
			_disc(st, f[1], face + front + up * 0.01, f[2], 0.003, lean)
		else:   # a band across the face
			_moved(st, f[1], Transform3D(Basis(Vector3.RIGHT, lean), face + front - up * 0.02), func(t: SurfaceTool) -> void:
				RoomProps._cube(t, Vector3(0, -0.018, 0), Vector3(0.13, 0.03, 0.004)))
	return null


## Roast chestnuts: a clay brazier with a wide iron pan on it, chestnuts among black pebbles,
## a long handle.
static func _roast_chestnuts(st: SurfaceTool, a: Vector3, _w: FarmWorld, sd: int) -> Variant:
	var at := a + Vector3(-0.03, 0, 0)
	_turn(st, Color("8a6a4a"), at, [Vector2(0.1, 0.0), Vector2(0.12, 0.06), Vector2(0.115, 0.08)], 10)
	_box(st, Color("e85a20"), at + Vector3(0, 0.02, 0.112), Vector3(0.07, 0.03, 0.012))   # the fire's mouth
	var pan := at + Vector3(0, 0.08, 0)
	_vessel(st, pan, 0.11, 0.16, 0.05, IRON, 0.035, Color("3a3634"))
	_rod(st, Color("5a3a24"), pan + Vector3(0.15, 0.04, 0), Vector3(1, 0.1, 0.3), 0.12, 0.01, 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	for k in 12:
		var ang := TAU * k / 12.0 + rng.randf() * 0.4
		var rad := 0.04 + 0.08 * float(k % 3) / 2.0
		var c := pan + Vector3(cos(ang) * rad, 0.03, sin(ang) * rad)
		_turn(st, Color("6a3a1e"), c, [Vector2(0.0, 0.0), Vector2(0.022, 0.006), Vector2(0.025, 0.02), Vector2(0.016, 0.034), Vector2(0.0, 0.042)], 6)
		_turn(st, Color("d8b080"), c, [Vector2(0.0225, 0.004), Vector2(0.0255, 0.012)], 6)   # the pale bottom showing
	return pan + Vector3(0, 0.05, 0)


## Baked sweet potatoes on hot stones in a wooden box, one broken open (yellow inside).
static func _baked_imo(st: SurfaceTool, a: Vector3, _w: FarmWorld, sd: int) -> Variant:
	var box := Vector3(0.38, 0.08, 0.28)
	_box(st, WOOD, a, Vector3(box.x, 0.02, box.z))
	for side in [-1.0, 1.0]:
		_box(st, WOOD, a + Vector3(side * (box.x / 2 - 0.01), 0, 0), Vector3(0.02, box.y, box.z))
		_box(st, WOOD, a + Vector3(0, 0, side * (box.z / 2 - 0.01)), Vector3(box.x - 0.04, box.y, 0.02))
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	_box(st, Color("4a4642"), a + Vector3(0, 0.02, 0), Vector3(box.x - 0.04, 0.03, box.z - 0.04))
	for k in 18:   # the stones' top
		var at := a + Vector3(rng.randf_range(-0.15, 0.15), 0.035, rng.randf_range(-0.1, 0.1))
		RoomProps._ball(_paint(st, Color("6a6660") if k % 2 == 0 else Color("3e3a36")), at, 0.018)
	var skin := Color("7a3a5a")
	for k in 3:
		var at := a + Vector3(-0.12, 0.08, -0.07 + k * 0.07)
		RoomProps._turn_x(_paint(st, skin.darkened(0.08 * k)), at, [Vector2(0.0, 0.0), Vector2(0.022, 0.02), Vector2(0.03, 0.08), Vector2(0.025, 0.17), Vector2(0.0, 0.22)], 7)
		if k == 1:   # broken open: the yellow flesh along its top
			var r := Rect2(at.x + 0.05, at.z - 0.018, 0.12, 0.036)
			FarmProps.block(_paint(st, Color("f2c040")), r, 0.024 + at.y, r.grow(-0.006), 0.034 + at.y)
	return a + Vector3(0, 0.1, 0)


## Clay rabbits (white with red marks, red eyes) sitting on a red cloth.
static func _clay_rabbit(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	_box(st, Color("b02a24"), a, Vector3(0.36, 0.008, 0.22))
	for r in [[Vector3(-0.08, 0, 0.0), 1.0], [Vector3(0.09, 0, -0.03), 0.75]]:
		var s: float = r[1]
		var at: Vector3 = a + r[0] + Vector3(0, 0.008, 0)
		var clay := Color("f4f0e6")
		_turn(st, clay, at, [Vector2(0.03 * s, 0.0), Vector2(0.05 * s, 0.02 * s), Vector2(0.046 * s, 0.05 * s), Vector2(0.026 * s, 0.07 * s), Vector2(0.0, 0.075 * s)], 8)
		var head := at + Vector3(0, 0.06 * s, 0.03 * s)
		RoomProps._ball(_paint(st, clay), head, 0.03 * s)
		for e in [-1.0, 1.0]:
			_rod(st, clay, head + Vector3(e * 0.012 * s, 0.05 * s, -0.005 * s), Vector3(e * 0.15, 1, -0.35), 0.06 * s, 0.009 * s, 4)
			_box(st, Color("c8442c"), head + Vector3(e * 0.013 * s, 0.032 * s, 0.026 * s), Vector3(0.008 * s, 0.008 * s, 0.006 * s))   # an eye
		_box(st, Color("c8442c"), at + Vector3(0, 0.03 * s, -0.045 * s), Vector3(0.03 * s, 0.012 * s, 0.01 * s))   # a red mark on its back
	return null


## Moon lanterns: round lanterns of pale yellow paper (ribs, dark caps) on little stands, an
## indigo band round each.
static func _moon_lantern(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	for l in [[Vector3(-0.08, 0, 0.0), 0.85], [Vector3(0.11, 0, -0.04), 0.65]]:
		var s: float = l[1]
		var at: Vector3 = a + l[0]
		_box(st, WOOD, at, Vector3(0.1 * s, 0.02, 0.1 * s), 0.004)
		_rod(st, INK, at + Vector3(0, 0.02, 0), Vector3.UP, 0.05 * s, 0.006, 4)
		var base := at + Vector3(0, 0.02 + 0.05 * s, 0)
		_turn(st, INK, base, [Vector2(0.04 * s, 0.0), Vector2(0.045 * s, 0.015 * s)], 10)
		_turn(st, Color("f0dc98"), base + Vector3(0, 0.015 * s, 0), [Vector2(0.045 * s, 0.0), Vector2(0.08 * s, 0.04 * s), Vector2(0.088 * s, 0.09 * s),
			Vector2(0.08 * s, 0.14 * s), Vector2(0.045 * s, 0.18 * s)], 12)
		_turn(st, Color("2a3460"), base + Vector3(0, 0.015 * s, 0), [Vector2(0.0885 * s, 0.075 * s), Vector2(0.0885 * s, 0.105 * s)], 12)
		_turn(st, INK, base + Vector3(0, 0.195 * s, 0), [Vector2(0.045 * s, 0.0), Vector2(0.04 * s, 0.015 * s), Vector2(0.0, 0.02 * s)], 10)
	return null


## Year-end soba: a black lacquer bowl (red inside) of noodles in broth with a fishcake slice,
## green onion and a prawn, chopsticks on a rest, a stack of bowls waiting.
static func _year_soba(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	var bowl := a + Vector3(-0.06, 0, 0.02)
	_turn(st, LACQUER, bowl, [Vector2(0.035, 0.0), Vector2(0.038, 0.012)], 10)
	_vessel(st, bowl + Vector3(0, 0.012, 0), 0.045, 0.095, 0.07, LACQUER, 0.052, Color("6a4a2a"), LACQUER_RED)
	var top := bowl + Vector3(0, 0.064, 0)
	_turn(st, Color("8a7a5a"), top, [Vector2(0.07, 0.0), Vector2(0.05, 0.012), Vector2(0.0, 0.018)], 10)   # the soba
	_disc(st, Color("f4e8e8"), top + Vector3(0.03, 0.02, 0.015), 0.022, 0.008, -1.2)   # a fishcake slice, its pink rim
	_turn(st, Color("e87890"), top + Vector3(0.03, 0.016, 0.015), [Vector2(0.0225, 0.0), Vector2(0.0225, 0.004)], 10)
	_rod(st, Color("e8783a"), top + Vector3(-0.05, 0.014, -0.01), Vector3(1, 0.15, -0.25), 0.08, 0.012, 5)   # the prawn
	for k in 5:
		_box(st, Color("5aa83a"), top + Vector3(-0.01 + k * 0.012, 0.014, 0.035 - k * 0.006), Vector3(0.008, 0.006, 0.008))
	_box(st, Color("8a6a48"), a + Vector3(0.0, 0, 0.13), Vector3(0.03, 0.012, 0.02))   # the rest
	for k in 2:
		_rod(st, Color("c8a06a"), a + Vector3(-0.14, 0.012, 0.125 + k * 0.012), Vector3(1, 0.04, 0), 0.24, 0.004, 4)
	var stack := a + Vector3(0.16, 0, -0.08)
	for k in 3:   # bowls stacked upside down
		_turn(st, LACQUER if k % 2 == 0 else LACQUER.lightened(0.08), stack + Vector3(0, k * 0.022, 0),
			[Vector2(0.075, 0.0), Vector2(0.07, 0.02), Vector2(0.04, 0.032), Vector2(0.0, 0.032)], 10)
	_turn(st, LACQUER_RED, stack + Vector3(0, 0.066, 0), [Vector2(0.03, 0.0), Vector2(0.03, 0.01), Vector2(0.0, 0.01)], 8)
	return top + Vector3(0, 0.04, 0)


## Hot yuzu tea: two tall cups of golden tea on a tray, yuzu fruit beside them with a leaf.
static func _yuzu_tea(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	_tray(st, Color("6a4a30"), a + Vector3(-0.05, 0, 0), Vector2(0.24, 0.2))
	for x in [-0.1, 0.0]:
		_vessel(st, a + Vector3(x, 0.022, 0.0), 0.03, 0.038, 0.09, Color("e8e0cc"), 0.075, Color("f0c030"))
		_turn(st, Color("3a5a7a"), a + Vector3(x, 0.022, 0.0), [Vector2(0.0335, 0.03), Vector2(0.035, 0.045)], 10)   # a blue band
	for o in [Vector3(0.13, 0, -0.04), Vector3(0.16, 0, 0.06), Vector3(0.09, 0, 0.08)]:
		var at: Vector3 = a + o
		_turn(st, Color("f0c020"), at, [Vector2(0.02, 0.0), Vector2(0.036, 0.015), Vector2(0.038, 0.032), Vector2(0.026, 0.052), Vector2(0.0, 0.058)], 8)
		_rod(st, Color("4a6a2a"), at + Vector3(0, 0.054, 0), Vector3.UP, 0.01, 0.005, 4)
	OutdoorProps._leaf(st, null, a + Vector3(0.13, 0.058, -0.04), Vector3(-0.6, 0.2, 0.7).normalized(), 0.08, 0.04, Color("4a7a3a"))
	return a + Vector3(-0.05, 0.12, 0.0)


## Daruma: a big red one with a white face (one eye painted in, one still blank), black brows
## and beard and a gold mark on the belly, a small one beside it.
static func _daruma(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	for d in [[Vector3(-0.06, 0, 0.0), 1.0], [Vector3(0.13, 0, -0.03), 0.62]]:
		var s: float = d[1]
		var at: Vector3 = a + d[0]
		_turn(st, Color("c8282c"), at, [Vector2(0.06 * s, 0.0), Vector2(0.088 * s, 0.04 * s), Vector2(0.09 * s, 0.08 * s), Vector2(0.075 * s, 0.13 * s),
			Vector2(0.045 * s, 0.165 * s), Vector2(0.0, 0.178 * s)], 12)
		var face := at + Vector3(0, 0.112 * s, 0.079 * s)
		_disc(st, Color("f4ecd8"), face, 0.048 * s, 0.012 * s, -0.25)
		var ahead := Vector3(0, sin(0.25), cos(0.25)) * 0.007 * s
		for e in [-1.0, 1.0]:
			_disc(st, Color("f8f8f4"), face + ahead + Vector3(e * 0.018 * s, 0.006 * s, 0), 0.012 * s, 0.003 * s, -0.25, 8)
			_box(st, INK, face + ahead + Vector3(e * 0.018 * s, 0.024 * s, -0.004 * s), Vector3(0.022 * s, 0.006 * s, 0.006 * s))   # a brow
		_disc(st, INK, face + ahead * 1.6 + Vector3(-0.018 * s, 0.006 * s, 0), 0.007 * s, 0.003 * s, -0.25, 8)   # the one eye painted in
		_box(st, INK, face + ahead + Vector3(0, -0.03 * s, 0.002 * s), Vector3(0.04 * s, 0.01 * s, 0.006 * s))   # the beard
		_box(st, Color("e8c050"), at + Vector3(0, 0.035 * s, 0.085 * s), Vector3(0.04 * s, 0.03 * s, 0.008 * s))   # the gold mark
	return null


## Omamori charms: brocade pouches with a gold band and a cord knot hung on a little rack, more
## lying on a tray in front.
static func _omamori(st: SurfaceTool, a: Vector3, _w: FarmWorld, _sd: int) -> Variant:
	var rack := a + Vector3(0, 0, -0.08)
	_box(st, WOOD, rack, Vector3(0.36, 0.02, 0.06), 0.004)
	for x in [-0.165, 0.165]:
		_box(st, WOOD, rack + Vector3(x, 0.02, 0), Vector3(0.022, 0.2, 0.022))
	var bar := rack + Vector3(0, 0.2, 0)
	_box(st, WOOD, bar, Vector3(0.36, 0.02, 0.025))
	var colours: Array[Color] = [Color("3a6a4a"), Color("c82a2a"), Color("2a4a9a"), Color("6a3a8a")]
	for k in 4:
		var x := -0.105 + k * 0.07
		_rod(st, Color("f0e6c8"), bar + Vector3(x, 0, 0.0), Vector3.DOWN, 0.02, 0.003, 3)
		_charm(st, bar + Vector3(x, -0.02 - 0.09, 0.0), colours[k])
	_tray(st, Color("7a2a1e"), a + Vector3(0, 0, 0.1), Vector2(0.3, 0.09), 0.012)
	for k in 3:   # lying on the tray, face up
		var at := a + Vector3(-0.08 + k * 0.08, 0.012, 0.1)
		_moved(st, colours[(k + 1) % 4], Transform3D(Basis(Vector3.RIGHT, -PI / 2 + 0.15), at + Vector3(0, 0.007, 0.045)), func(t: SurfaceTool) -> void:
			_charm_shape(t, Vector3.ZERO, colours[(k + 1) % 4]))
	return null


## One charm hanging: a pouch on its bottom middle at `at`, its shoulders cut in, a gold band, the
## cord's knot on top.
static func _charm(st: SurfaceTool, at: Vector3, c: Color) -> void:
	_paint(st, c)
	_charm_shape(st, at, c)


static func _charm_shape(st: SurfaceTool, at: Vector3, c: Color) -> void:
	var body := Rect2(at.x - 0.024, at.z - 0.006, 0.048, 0.012)
	st.set_color(c)
	FarmProps.block(st, body, at.y, body, at.y + 0.075)
	FarmProps.block(st, body, at.y + 0.075, body.grow_individual(-0.01, 0, -0.01, 0), at.y + 0.09)
	var band := Rect2(at.x - 0.025, at.z - 0.007, 0.05, 0.014)
	st.set_color(Color("e8c050"))
	FarmProps.block(st, band, at.y + 0.045, band, at.y + 0.058)
	RoomProps._ball(_paint(st, Color("f0e6c8")), at + Vector3(0, 0.088, 0), 0.008)


# --- displays: stalls that sell nothing ------------------------------------------------
# A fair game or a show of goods to look at, on a stall prop with `"display": "<id>"`
# (data/festivals.json); no stock, no shop. Same limits as the wares: lit vertex colours,
# on the counter's front half, under TALL, clear of the lantern at the right front corner.

## Goldfish scooping: a round wooden tub of water with goldfish swimming slowly round in it
## (Swimmers), a second little basin of spare fish, and three paper scoops (poi) on a tray.
static func _goldfish(st: SurfaceTool, w: FarmWorld, mid: Vector3, a: Vector3) -> void:
	var tub := a + Vector3(-0.22, 0, -0.04)
	var wood := Color("8a6a44")
	var bottom := Color("5a8aa8")
	# One profile out, up the wall, over the lip and back down inside (a lathe closes an end that has a
	# radius, so it must finish on the axis), the floor as its own piece.
	_turn(st, wood, tub, [Vector2(0.0, 0.0), Vector2(0.19, 0.0), Vector2(0.205, 0.05), Vector2(0.21, 0.1), Vector2(0.195, 0.1), Vector2(0.18, 0.014), Vector2(0.0, 0.014)], 14)
	_turn(st, bottom, tub, [Vector2(0.18, 0.016), Vector2(0.0, 0.016)], 14)
	for y in [0.02, 0.07]:   # two iron hoops round the outside
		_band(st, IRON, tub, 0.19 + 0.2 * y + 0.004, y, y + 0.014, 14)
	var swim := Swimmers.new(int(mid.x * 11))
	swim.position = tub
	w.add_child(swim)
	# The spare fish in a little glass bowl, three of them standing still.
	var bowl := a + Vector3(0.1, 0, 0.1)
	_vessel(st, bowl, 0.04, 0.06, 0.08, GLASS, 0.06, Color("8ac4d8"))
	var fish_mesh: ArrayMesh = Swimmers.fish_mesh(Color("f08a2a"), Color("e8601c"))
	for k in 2:
		st.append_from(fish_mesh, 0, Transform3D(Basis(Vector3.UP, 0.8 + k * 2.2).scaled(Vector3.ONE * 0.6), bowl + Vector3(0.015 - k * 0.03, 0.035 + k * 0.01, 0.0)))
	# Three paper scoops on a tray: a white paper disc in a thin ring on a short handle.
	_tray(st, Color("7a2a1e"), a + Vector3(0.36, 0, -0.1), Vector2(0.3, 0.2), 0.014)
	for k in 3:
		var ring := a + Vector3(0.28 + k * 0.08, 0.014, -0.12 + (k % 2) * 0.1)
		_turn(st, Color("c8a06a"), ring, [Vector2(0.034, 0.0), Vector2(0.034, 0.008), Vector2(0.0, 0.008)], 10)
		_turn(st, Color("f2ecdc"), ring + Vector3(0, 0.002, 0), [Vector2(0.03, 0.0), Vector2(0.03, 0.009), Vector2(0.0, 0.009)], 10)
		_rod(st, Color("c8a06a"), ring + Vector3(0.03, 0.004, 0.0), Vector3(1, 0.1, 0.2), 0.07, 0.004, 4)
	# A cloth sign on a stick: "scoop", a white fish on blue.
	_rod(st, WOOD, a + Vector3(0.5, 0, 0.1), Vector3.UP, 0.2, 0.006, 4)
	_box(st, Color("2a4a8a"), a + Vector3(0.5, 0.1, 0.1), Vector3(0.08, 0.1, 0.006))
	_box(st, Color("f2ecdc"), a + Vector3(0.5, 0.14, 0.104), Vector3(0.03, 0.04, 0.004))


## A thin upright band of radius `r` round `at` from height y0 to y1, facing out (a hoop).
static func _band(st: SurfaceTool, c: Color, at: Vector3, r: float, y0: float, y1: float, sides: int) -> void:
	_paint(st, c)
	var none := func(_p: Vector3) -> Vector2: return Vector2.ZERO
	for k in sides:
		var a0 := TAU * (k + 0.5) / sides
		var a1 := TAU * (k + 1.5) / sides
		var n := Vector3(sin((a0 + a1) / 2), 0, cos((a0 + a1) / 2))
		Minka.quad(st, at + Vector3(sin(a0) * r, y0, cos(a0) * r), at + Vector3(sin(a1) * r, y0, cos(a1) * r),
			at + Vector3(sin(a1) * r, y1, cos(a1) * r), at + Vector3(sin(a0) * r, y1, cos(a0) * r), n, none)


## Festival masks on a two-tier wooden stand: fox, demon, round-faced and rabbit masks in the
## back row, fox, tanuki and round-faced ones in front, leaning back to look up at the street.
static func _masks(st: SurfaceTool, _w: FarmWorld, _mid: Vector3, a: Vector3) -> void:
	var centre := a + Vector3(0.0, 0, 0.0)
	var back_h := 0.08
	_box(st, WOOD, centre + Vector3(0, 0, -0.07), Vector3(0.98, back_h, 0.13), 0.004)
	_box(st, WOOD_LIGHT, centre + Vector3(0, back_h, -0.07), Vector3(0.99, 0.008, 0.14), 0.003)
	_box(st, WOOD, centre + Vector3(0, 0, 0.08), Vector3(0.98, 0.04, 0.14), 0.004)
	_box(st, WOOD_LIGHT, centre + Vector3(0, 0.04, 0.08), Vector3(0.99, 0.008, 0.15), 0.003)
	var back: Array = ["fox", "demon", "round", "rabbit"]
	for k in back.size():
		_mask(st, back[k], centre + Vector3(-0.36 + k * 0.24, back_h + 0.008 + 0.06, -0.07), -0.3, k)
	var front: Array = ["tanuki", "fox", "round"]
	for k in front.size():
		_mask(st, front[k], centre + Vector3(-0.24 + k * 0.24, 0.048 + 0.06, 0.085), -0.3, k + 1)


## One mask of `kind` with its face centre at `at`, leaned back by `lean`; `v` picks a variant of
## its colours. Faces look +z.
static func _mask(st: SurfaceTool, kind: String, at: Vector3, lean: float, v: int) -> void:
	var tmp := SurfaceTool.new()
	tmp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var white := Color("f4f0e4")
	var red := Color("c8282c")
	match kind:
		"fox":
			var tint := red if v % 2 == 0 else Color("2a4a8a")
			for e in [-1.0, 1.0]:
				_turn(tmp, white, Vector3(e * 0.034, 0.03, -0.004), [Vector2(0.02, 0.0), Vector2(0.0, 0.05)], 3)
				_turn(tmp, tint, Vector3(e * 0.034, 0.03, 0.002), [Vector2(0.011, 0.0), Vector2(0.0, 0.032)], 3)
			_disc(tmp, white, Vector3.ZERO, 0.05, 0.012)
			_box(tmp, white, Vector3(0, -0.044, 0.004), Vector3(0.05, 0.04, 0.03), 0.004)   # the snout
			_disc(tmp, INK, Vector3(0, -0.03, 0.026), 0.008, 0.006, 0.0, 8)   # the nose
			for e in [-1.0, 1.0]:
				_box(tmp, tint, Vector3(e * 0.03, 0.01, 0.0075), Vector3(0.026, 0.008, 0.004))   # the cheek stripes
				_box(tmp, tint, Vector3(e * 0.03, -0.004, 0.0075), Vector3(0.02, 0.006, 0.004))
				_box(tmp, INK, Vector3(e * 0.022, 0.022, 0.0075), Vector3(0.02, 0.005, 0.004))   # a slanted eye slit
		"demon":
			for e in [-1.0, 1.0]:
				_turn(tmp, Color("f4e8c8"), Vector3(e * 0.034, 0.038, -0.004), [Vector2(0.012, 0.0), Vector2(0.0, 0.04)], 5)
			_disc(tmp, Color("c02a2a") if v % 2 == 0 else Color("2a5a9a"), Vector3.ZERO, 0.052, 0.014)
			for e in [-1.0, 1.0]:
				_box(tmp, INK, Vector3(e * 0.022, 0.018, 0.0085), Vector3(0.03, 0.007, 0.004))   # heavy brows
				_disc(tmp, Color("f8e8a0"), Vector3(e * 0.02, 0.005, 0.0085), 0.009, 0.004, 0.0, 8)   # gold eyes
				_box(tmp, white, Vector3(e * 0.016, -0.034, 0.0085), Vector3(0.007, 0.014, 0.004))   # tusks
			_box(tmp, INK, Vector3(0, -0.025, 0.0085), Vector3(0.04, 0.008, 0.004))
		"round":
			_disc(tmp, INK, Vector3(0, 0.012, -0.004), 0.054, 0.01)   # the black hair
			_disc(tmp, white, Vector3(0, -0.004, 0.0), 0.046, 0.014)
			for e in [-1.0, 1.0]:
				_disc(tmp, Color("e8707c"), Vector3(e * 0.027, -0.01, 0.008), 0.011, 0.004, 0.0, 8)   # red cheeks
				_box(tmp, INK, Vector3(e * 0.019, 0.007, 0.008), Vector3(0.016, 0.004, 0.004))       # closed eyes
			_disc(tmp, red, Vector3(0, -0.026, 0.008), 0.006, 0.004, 0.0, 8)
			_box(tmp, INK, Vector3(0, 0.032, 0.0), Vector3(0.05, 0.01, 0.014))   # a hair parting on top
		"rabbit":
			for e in [-1.0, 1.0]:
				_box(tmp, white, Vector3(e * 0.024, 0.032, -0.004), Vector3(0.022, 0.06, 0.008), 0.004)   # long ears
				_box(tmp, Color("f0a8b8"), Vector3(e * 0.024, 0.04, 0.001), Vector3(0.011, 0.04, 0.004))
			_disc(tmp, white, Vector3.ZERO, 0.048, 0.012)
			for e in [-1.0, 1.0]:
				_disc(tmp, red, Vector3(e * 0.02, 0.008, 0.0075), 0.008, 0.004, 0.0, 8)
			_disc(tmp, Color("f0a8b8"), Vector3(0, -0.016, 0.0075), 0.006, 0.004, 0.0, 8)
		_:   # tanuki
			for e in [-1.0, 1.0]:
				RoomProps._ball(_paint(tmp, Color("5a4030")), Vector3(e * 0.04, 0.04, -0.004), 0.016)
			_disc(tmp, Color("7a5a3c"), Vector3.ZERO, 0.05, 0.012)
			_disc(tmp, Color("d8c4a0"), Vector3(0, -0.018, 0.0075), 0.026, 0.004, 0.0, 10)   # the pale muzzle
			for e in [-1.0, 1.0]:
				_disc(tmp, INK, Vector3(e * 0.02, 0.01, 0.0075), 0.013, 0.004, 0.0, 8)   # dark eye patches
				_disc(tmp, Color("f4f0e4"), Vector3(e * 0.02, 0.011, 0.0115), 0.003, 0.002, 0.0, 6)
			_disc(tmp, INK, Vector3(0, -0.012, 0.0115), 0.007, 0.004, 0.0, 8)
	st.append_from(tmp.commit(), 0, Transform3D(Basis(Vector3.RIGHT, lean).scaled(Vector3.ONE * 1.2), at))


## Goldfish swimming slowly round in a tub (the tub is the parent's mesh): each fish is its own
## small lit mesh on a circle of its own, wiggling a little as it goes; a thin see-through disc
## of water over them. Centred on the tub's bottom middle.
class Swimmers extends Node3D:
	const WATER_Y := 0.082
	const FISH_Y := 0.045
	var _t := 0.0
	var _fish: Array[MeshInstance3D] = []
	var _orbit: Array[Vector3] = []   # per fish: radius, speed (radians / s, signed), phase

	func _init(sd := 0) -> void:
		var looks := [[Color("f08a2a"), Color("e8601c")], [Color("e8481c"), Color("c82a18")], [Color("f4a84a"), Color("f8f0e0")], [Color("f08a2a"), Color("f8f0e0")]]
		for k in looks.size():
			var mi := MeshInstance3D.new()
			mi.mesh = StallWares.Swimmers.fish_mesh(looks[k][0], looks[k][1])
			mi.material_override = OutdoorProps._vertex_material()
			mi.scale = Vector3.ONE * 1.5
			add_child(mi)
			_fish.append(mi)
			var dir := 1.0 if (k + sd) % 2 == 0 else -1.0
			_orbit.append(Vector3(0.05 + 0.035 * (k % 3), dir * (0.6 + 0.12 * k), float(k) * 1.7 + sd % 7))
		var water := MeshInstance3D.new()
		var wst := SurfaceTool.new()
		wst.begin(Mesh.PRIMITIVE_TRIANGLES)
		Shrine.lathe(wst, Vector3(0, WATER_Y, 0), [Vector2(0.185, 0.0), Vector2(0.0, 0.0)], 14)
		water.mesh = wst.commit()
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.55, 0.82, 0.95, 0.6)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		water.material_override = m
		water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(water)
		_place()

	func _process(delta: float) -> void:
		_t += delta
		_place()

	func _place() -> void:
		for k in _fish.size():
			var o := _orbit[k]
			var a: float = o.z + _t * o.y
			_fish[k].position = Vector3(cos(a) * o.x, FISH_Y + sin(_t * 1.3 + k) * 0.004, sin(a) * o.x)
			# Heading along the circle (the head is +x); the body swings a little either side.
			var heading := atan2(-cos(a) * signf(o.y), -sin(a) * signf(o.y))
			_fish[k].rotation = Vector3(0, heading + sin(_t * 5.0 + k * 1.9) * 0.22, 0)

	## Where the fish are now (tub-relative), for tests.
	func positions() -> Array[Vector3]:
		var out: Array[Vector3] = []
		for mi in _fish:
			out.append(mi.position)
		return out

	## A fish of body colour `body`, fins and tail `fin`: head toward +x, about 0.1 long.
	static func fish_mesh(body: Color, fin: Color) -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var tmp := SurfaceTool.new()
		tmp.begin(Mesh.PRIMITIVE_TRIANGLES)
		# The body, a lathe along y turned onto the x axis, the head at +x.
		Shrine.lathe(StallWares._paint(tmp, body), Vector3(-0.045, 0, 0), [Vector2(0.0, 0.0), Vector2(0.014, 0.015), Vector2(0.022, 0.04), Vector2(0.019, 0.07), Vector2(0.01, 0.09), Vector2(0.0, 0.098)], 8)
		st.append_from(tmp.commit(), 0, Transform3D(Basis(Vector3.BACK, -PI / 2), Vector3.ZERO))
		var ft := SurfaceTool.new()
		ft.begin(Mesh.PRIMITIVE_TRIANGLES)
		# A tail fan behind and a fin on the back, thin and upright.
		StallWares._box(ft, fin, Vector3(-0.062, -0.02, 0.0), Vector3(0.035, 0.04, 0.004))
		StallWares._box(ft, fin, Vector3(-0.012, 0.016, 0.0), Vector3(0.03, 0.02, 0.004))
		st.append_from(ft.commit(), 0, Transform3D.IDENTITY)
		return st.commit()


# --- steam ---------------------------------------------------------------------------

## Steam over hot food: a few pale puffs rising about 0.2 above it, growing and fading as they go,
## out of step. Lit (it darkens at night with everything else), no shadow.
class Steam extends Node3D:
	const PUFFS := 3
	const RISE := 0.2   # low enough to show under the curtain
	const PERIOD := 2.6   # seconds for one puff to rise and fade
	var _t := 0.0
	var _puffs: Array[MeshInstance3D] = []
	var _seed := 0

	func _init(sd := 0) -> void:
		_seed = sd
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		Shrine.lathe(st, Vector3(0, -0.03, 0), [Vector2(0.02, 0.0), Vector2(0.035, 0.015), Vector2(0.035, 0.035), Vector2(0.02, 0.055), Vector2(0.0, 0.06)], 7)
		var mesh := st.commit()
		for k in PUFFS:
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			var m := StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(1, 1, 1, 0)
			mi.material_override = m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
			_puffs.append(mi)
		_t = float(sd % 97) / 97.0 * PERIOD
		_place()

	func _process(delta: float) -> void:
		_t += delta
		_place()

	## Puff `k` at its point of the rise: up, drifting a little sideways, larger, fading in then out.
	func _place() -> void:
		for k in _puffs.size():
			var u := fposmod(_t / PERIOD + float(k) / PUFFS, 1.0)
			var mi := _puffs[k]
			mi.position = Vector3(sin(u * 5.0 + k * 2.1 + _seed) * 0.025 + u * 0.03, u * RISE, cos(u * 4.0 + k) * 0.015)
			mi.scale = Vector3.ONE * (1.0 + u * 1.2)
			var m: StandardMaterial3D = mi.material_override
			m.albedo_color = Color(1, 1, 1, 0.6 * sin(PI * u))

	## How strong the steam is now (the puffs' alphas, for tests).
	func strength() -> float:
		var s := 0.0
		for mi in _puffs:
			s += (mi.material_override as StandardMaterial3D).albedo_color.a
		return s
