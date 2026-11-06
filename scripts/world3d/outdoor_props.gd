class_name OutdoorProps
extends RefCounted
## The small things out in the countryside as real meshes (MapWorld and CountryProps call
## these): the bamboo clumps of the hill and the lanes (segmented culms with node rings, leaf
## sprays, swaying a little, their look by season, snow on the leaves), the village well under
## its board roof, the stone jizo in his red bib and cap, the woodpile under its lean-to and the
## stepping rocks of the river. All lit; only the placement is as before (same cells, same
## footprints). Same units as the farm: 1 unit = 1 cell. Snow lies on their tops where `snow`
## is true (SnowLayer's top shader shows it as the cover grows).

const TIMBER := Color("4a3424")
const STONE_DARK := Color("7e7a72")
const STONE := Color("8e8a80")
const STONE_LIGHT := Color("a29e94")
const RED := Color("c8342c")
const CLUMP_LOOKS := 8   # bamboo clump shapes; a cell picks one and turns it

## Bamboo colours by season: culm, node ring, three leaf tones. Evergreen: winter only dulls.
const BAMBOO := {
	"spring": {"culm": Color("86b552"), "node": Color("b4d27c"), "leaves": [Color("9cc85c"), Color("86b64c"), Color("74a440")]},
	"summer": {"culm": Color("5f9a3c"), "node": Color("98bc66"), "leaves": [Color("4f9138"), Color("3f7f30"), Color("5aa040")]},
	"fall": {"culm": Color("88a044"), "node": Color("b8c070"), "leaves": [Color("a8b43c"), Color("94a638"), Color("b89c30")]},
	"winter": {"culm": Color("6f8f50"), "node": Color("9ab07a"), "leaves": [Color("5a8442"), Color("4a7238"), Color("66904c")]},
}

static var _clumps := {}   # "season|snow|look" -> {mesh, snow}: built once, shared by every clump


## What a clump's cell turns it by: the look (0..CLUMP_LOOKS-1) and a yaw, from the cell only.
static func clump_look(c: Vector2i) -> int:
	return posmod(c.x * 7 + c.y * 13, 16) % CLUMP_LOOKS


static func clump_yaw(c: Vector2i) -> float:
	return posmod(hash(Vector2i(c.x * 3 + 1, c.y * 5 + 2)), 1009) / 1009.0 * TAU


# --- bamboo ---------------------------------------------------------------

## A clump of bamboo at `mid` (the middle of its cell): three or four culms leaning a little
## apart, their nodes ringed, leaf sprays near the tops. One mesh a clump (colours on the
## vertices, so it can fade as one) shared by the clumps of the same look, and a Sway moves
## it a little in the wind. `snow` adds the snow skin on the leaves.
static func bamboo(w: FarmWorld, mid: Vector3, c: Vector2i, season: String, snow: bool) -> void:
	var look := clump_look(c)
	var key := "%s|%s|%d" % [season, snow, look]
	if not _clumps.has(key):
		_clumps[key] = _build_clump(season, snow, look)
	var sway := _sway(w)
	var made: Dictionary = _clumps[key]
	var yaw := clump_yaw(c)
	var mi := MeshInstance3D.new()
	mi.mesh = made.mesh
	mi.material_override = _vertex_material()
	mi.position = mid
	w.add_child(mi)
	var skin: MeshInstance3D = null
	if made.snow != null:
		skin = MeshInstance3D.new()
		skin.mesh = made.snow
		skin.material_override = _snow_material(w)
		skin.position = mid
		skin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.add_child(skin)
	sway.add([mi, skin] if skin != null else [mi], yaw, c.x * 1.7 + c.y * 2.3)


static func _build_clump(season: String, snow: bool, look: int) -> Dictionary:
	var look_colours: Dictionary = BAMBOO[season]
	var culm_col: Color = look_colours.culm
	var node_col: Color = look_colours.node
	var leaves: Array = look_colours.leaves
	var rng := RandomNumberGenerator.new()
	rng.seed = look * 977 + 5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sn: SurfaceTool = null
	if snow:
		sn = SurfaceTool.new()
		sn.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 3 + look % 2
	for i in n:
		var a := TAU * (i + rng.randf() * 0.4) / n
		var foot := Vector3(cos(a), 0, sin(a)) * 0.2
		var tall := rng.randf_range(2.2, 2.9)
		var low_end := tall * 0.55
		var d1 := _dir(a, rng.randf_range(0.02, 0.05))
		var d2 := _dir(a + rng.randf_range(-0.4, 0.4), rng.randf_range(0.07, 0.11))
		var mid_p := foot + d1 * low_end
		var r0 := 0.05
		var r1 := 0.04
		var r2 := 0.026
		var tint := 1.0 + rng.randf_range(-0.07, 0.07)
		var col := Color(culm_col.r * tint, culm_col.g * tint, culm_col.b * tint)
		_tube(st, foot, d1, [Vector2(r0, 0.0), Vector2(r1, low_end)], 6, col)
		_tube(st, mid_p, d2, [Vector2(r1, 0.0), Vector2(r2, tall - low_end)], 6, col)
		var s := rng.randf_range(0.22, 0.32)
		var nodes: Array[float] = []
		while s < tall - 0.12:
			nodes.append(s)
			s += rng.randf_range(0.27, 0.4)
		for s_k in nodes:
			var at: Vector3
			var dir: Vector3
			var r: float
			if s_k <= low_end:
				at = foot + d1 * s_k
				dir = d1
				r = lerpf(r0, r1, s_k / low_end)
			else:
				at = mid_p + d2 * (s_k - low_end)
				dir = d2
				r = lerpf(r1, r2, (s_k - low_end) / (tall - low_end))
			_tube(st, at, dir, [Vector2(r, -0.012), Vector2(r * 1.32, 0.0), Vector2(r, 0.012)], 6, node_col)
			if s_k > tall * 0.58:
				_spray(st, sn, at, dir, a, rng, leaves, 5, false)
		var tip := mid_p + d2 * (tall - low_end)
		_spray(st, sn, tip, d2, a, rng, leaves, 7, true)
	if season == "spring":   # young shoots in their husks at the foot
		for k in 2:
			var a := rng.randf() * TAU
			var at := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.28, 0.4)
			_tube(st, at, Vector3.UP, [Vector2(0.035, 0.0), Vector2(0.032, 0.09), Vector2(0.018, 0.16), Vector2(0.0, 0.21)],
				6, Color("b09a6a"))
	if season == "fall":   # fallen leaves on the ground
		st.set_color(Color("b8a040"))
		for k in 8:
			var a := rng.randf() * TAU
			var at := Vector3(cos(a), 0.012, sin(a)) * rng.randf_range(0.25, 0.45)
			var along := Vector3(cos(a + 1.0), 0, sin(a + 1.0)) * 0.07
			var across := Vector3(-along.z, 0, along.x) * 0.25
			_tri(st, at - along, at + across, at + along, Vector3.UP)
			_tri(st, at - along, at + along, at - across, Vector3.UP)
	return {"mesh": st.commit(), "snow": sn.commit() if sn != null else null}


## A spray of leaves off a node: `count` long thin leaves fanned round, drooping (the plume at
## a culm's tip also stands some upright), on a short twig.
static func _spray(st: SurfaceTool, sn: SurfaceTool, at: Vector3, dir: Vector3, yaw: float, rng: RandomNumberGenerator,
		leaves: Array, count: int, plume: bool) -> void:
	var out := yaw + rng.randf_range(-1.5, 1.5)
	var twig := Vector3(cos(out), 0.25, sin(out)).normalized()
	var base := at + twig * 0.09
	if not plume:
		_tube(st, at, twig, [Vector2(0.011, 0.0), Vector2(0.007, 0.09)], 4, Color("5a7a3c"))
	for j in count:
		var a := out + (j - (count - 1) / 2.0) * (TAU / count) * 0.62 + rng.randf_range(-0.2, 0.2)
		var rise := rng.randf_range(-0.55, -0.15)
		if plume and j < 2:
			rise = rng.randf_range(0.15, 0.4)
		var d := Vector3(cos(a) * cos(rise), sin(rise), sin(a) * cos(rise)).normalized()
		_leaf(st, sn, base, d, rng.randf_range(0.34, 0.42), 0.09, leaves[rng.randi() % leaves.size()])


## One leaf: a long diamond from `base` along `d`, widest 40% of the way, seen from both sides.
## `sn` (or null) gets its snow skin.
static func _leaf(st: SurfaceTool, sn: SurfaceTool, base: Vector3, d: Vector3, length: float, width: float, col: Color) -> void:
	var side := d.cross(Vector3.UP)
	if side.length() < 0.01:
		side = Vector3.RIGHT
	side = side.normalized() * (width / 2.0)
	var mid := base + d * length * 0.4
	var tip := base + d * length + Vector3(0, -0.025, 0)
	var n := side.normalized().cross(d).normalized()
	if n.y < 0.0:
		n = -n
	st.set_color(col)
	for sign in [1.0, -1.0]:
		_tri(st, base, mid + side, tip, n * sign)
		_tri(st, base, tip, mid - side, n * sign)
	if sn != null and n.y > 0.35:
		var up := Vector3(0, 0.014, 0)
		var s0 := base + d * length * 0.1 + up
		var sm := base + d * length * 0.4 + up
		var st_tip := base + d * length * 0.8 + up
		_tri(sn, s0, sm + side * 0.7, st_tip, Vector3.UP)
		_tri(sn, s0, st_tip, sm - side * 0.7, Vector3.UP)


# --- the well ---------------------------------------------------------------

## A well in its cell: a round stone curb of three courses (the rim lighter, the water dark
## below it), two timber posts carrying a windlass with a crank, a rope and a wooden bucket
## hanging over the water, under a small board gable roof (Minka.gable, which carries the snow),
## the ridge along x.
static func well(w: FarmWorld, mid: Vector3) -> void:
	var p := FarmProps.Parts.new()
	var at := Vector3(mid.x, 0, mid.z)
	Shrine.lathe(p.st(STONE_DARK), at, [Vector2(0.41, 0.0), Vector2(0.41, 0.16)], 10)
	Shrine.lathe(p.st(STONE), at, [Vector2(0.385, 0.16), Vector2(0.385, 0.33)], 10)
	# The rim, then the inner wall down to the water (the lathe's end cap is the dark water).
	Shrine.lathe(p.st(STONE_LIGHT), at, [Vector2(0.42, 0.33), Vector2(0.42, 0.47), Vector2(0.27, 0.47)], 10)
	Shrine.lathe(p.st(Color("5a564e")), at, [Vector2(0.27, 0.47), Vector2(0.27, 0.3)], 10)
	Shrine.lathe(p.st(Color("1e2c34")), at, [Vector2(0.268, 0.302), Vector2(0.0, 0.302)], 10)
	var timber := p.st(TIMBER)
	for x in [-0.42, 0.42]:
		FarmProps.block(timber, Rect2(mid.x + x - 0.045, mid.z - 0.045, 0.09, 0.09), 0.0,
			Rect2(mid.x + x - 0.035, mid.z - 0.035, 0.07, 0.07), 1.44)
	var wood := p.st(Color("6a5440"))   # the windlass roller and the crank
	RoomProps._placed(wood, Transform3D(Basis(Quaternion(Vector3.UP, Vector3.RIGHT)), Vector3(mid.x, 1.0, mid.z)),
		func(t: SurfaceTool) -> void: Shrine.lathe(t, Vector3.ZERO, [Vector2(0.05, -0.43), Vector2(0.05, 0.43)], 8))
	FarmProps.block(wood, Rect2(mid.x + 0.455, mid.z - 0.015, 0.04, 0.03), 0.8, Rect2(mid.x + 0.455, mid.z - 0.015, 0.04, 0.03), 1.0)
	FarmProps.block(wood, Rect2(mid.x + 0.455, mid.z + 0.03, 0.04, 0.07), 0.8, Rect2(mid.x + 0.455, mid.z + 0.03, 0.04, 0.07), 0.84)
	FarmProps.block(p.st(FarmProps.STRAW), Rect2(mid.x - 0.008, mid.z - 0.008, 0.016, 0.016), 0.74, Rect2(mid.x - 0.008, mid.z - 0.008, 0.016, 0.016), 0.98)
	var bucket_at := Vector3(mid.x, 0.6, mid.z)   # hangs over the water
	Shrine.lathe(p.st(Color("9a7048")), bucket_at, [Vector2(0.055, 0.0), Vector2(0.07, 0.14)], 8)
	Shrine.lathe(p.st(Color("3a2c22")), bucket_at, [Vector2(0.0615, 0.05), Vector2(0.0615, 0.065)], 8)
	Shrine.lathe(p.st(Color("3a2c22")), bucket_at, [Vector2(0.0675, 0.115), Vector2(0.0675, 0.13)], 8)
	var eave := Rect2(mid.x - 0.5, mid.z - 0.4, 1.0, 0.8)
	var crest := Minka.gable(w, eave, 1.22, 0.6, 0.045, "build:planks_dark", "build:planks_dark")
	FarmProps.block(p.st(TIMBER), Rect2(mid.x - 0.52, mid.z - 0.045, 1.04, 0.09), crest - 0.03, Rect2(mid.x - 0.52, mid.z - 0.03, 1.04, 0.06), crest + 0.05)
	p.commit(w)


# --- the jizo -----------------------------------------------------------------

## A stone jizo on a two-step block: a robed body, a round head, a red cap, a red bib and a
## red collar at the neck. Snow on the cap, the shoulders and the block.
static func jizo(w: FarmWorld, mid: Vector3, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var stone := p.st(STONE)
	FarmProps.block(p.st(STONE_DARK), Rect2(mid.x - 0.18, mid.z - 0.16, 0.36, 0.32), 0.0, Rect2(mid.x - 0.165, mid.z - 0.145, 0.33, 0.29), 0.08)
	FarmProps.block(stone, Rect2(mid.x - 0.14, mid.z - 0.12, 0.28, 0.24), 0.08, Rect2(mid.x - 0.13, mid.z - 0.11, 0.26, 0.22), 0.15)
	var at := Vector3(mid.x, 0, mid.z)
	Shrine.lathe(stone, at, [Vector2(0.115, 0.15), Vector2(0.125, 0.2), Vector2(0.105, 0.34), Vector2(0.075, 0.44)], 10)
	Shrine.lathe(stone, at, [Vector2(0.05, 0.44), Vector2(0.075, 0.47), Vector2(0.09, 0.52), Vector2(0.085, 0.58),
		Vector2(0.06, 0.63), Vector2(0.02, 0.655), Vector2(0.0, 0.66)], 10)
	var red := p.st(RED)
	Shrine.lathe(red, at, [Vector2(0.068, 0.42), Vector2(0.09, 0.43), Vector2(0.092, 0.465), Vector2(0.066, 0.485)], 10)   # collar
	Shrine.lathe(red, at, [Vector2(0.094, 0.56), Vector2(0.094, 0.585), Vector2(0.07, 0.637), Vector2(0.03, 0.667), Vector2(0.0, 0.677)], 10)   # cap
	FarmProps.block(red, Rect2(mid.x - 0.06, mid.z + 0.105, 0.12, 0.02), 0.27, Rect2(mid.x - 0.075, mid.z + 0.085, 0.15, 0.022), 0.46)   # bib
	p.commit(w)
	if snow:
		var sn := FarmProps.Parts.new()
		var s := sn.st(FarmProps.Parts.SNOW)
		Shrine.lathe(s, at, [Vector2(0.072, 0.634), Vector2(0.032, 0.67), Vector2(0.0, 0.684)], 10)
		var top := Rect2(mid.x - 0.13, mid.z - 0.11, 0.26, 0.22)
		FarmProps.block(s, top.grow(-0.01), 0.152, top.grow(-0.035), 0.17)
		sn.commit(w)


# --- the woodpile -------------------------------------------------------------

## Split firewood stacked four rows high, the cut ends facing the front (+z), over the cells
## `r` (as long as it is wide), between timber posts under a plank lean-to roof that slopes
## down to the front. Snow on the roof.
static func woodpile(w: FarmWorld, r: Rect2, mid: Vector3, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x) * 31 + int(r.position.y) * 17 + 7
	var barks: Array[Color] = [Color("7a5a3a"), Color("86643f"), Color("6e5236")]
	var cuts: Array[Color] = [Color("d6b886"), Color("cfae7c"), Color("dcc08c")]
	var long := r.size.x
	for row in 4:
		var offset := 0.095 if row % 2 == 1 else 0.0
		var count := int((long - 0.3) / 0.19) + 1 - (row % 2)
		for i in count:
			var x := r.position.x + 0.15 + offset + i * 0.19 + (long - 0.3 - (int((long - 0.3) / 0.19)) * 0.19) / 2.0
			var rr := rng.randf_range(0.075, 0.093)
			var length := 0.62 + rng.randf_range(-0.05, 0.05)
			var zc := mid.z + rng.randf_range(-0.03, 0.03)
			var y := 0.095 + row * 0.16
			var tone := rng.randi() % 3
			_tube(p.st(barks[tone]), Vector3(x, y, zc - length / 2), Vector3(0, 0, 1), [Vector2(rr, 0.0), Vector2(rr, length)], 7, Color.WHITE)
			var disc := p.st(cuts[rng.randi() % 3])
			for k in 7:
				var a0 := TAU * k / 7.0
				var a1 := TAU * (k + 1) / 7.0
				var c := Vector3(x, y, zc + length / 2 + 0.002)
				_tri(disc, c, c + Vector3(cos(a0), sin(a0), 0) * rr * 0.93, c + Vector3(cos(a1), sin(a1), 0) * rr * 0.93, Vector3(0, 0, 1))
	var post := p.st(TIMBER)
	for x in [r.position.x + 0.06, r.end.x - 0.06]:
		FarmProps.block(post, Rect2(x - 0.04, mid.z - 0.44, 0.08, 0.08), 0.0, Rect2(x - 0.035, mid.z - 0.435, 0.07, 0.07), 0.96)
		FarmProps.block(post, Rect2(x - 0.04, mid.z + 0.38, 0.08, 0.08), 0.0, Rect2(x - 0.035, mid.z + 0.385, 0.07, 0.07), 0.74)
	_slab(p.st("build:planks_dark"), r.position.x + 0.0, r.end.x - 0.0, mid.z - 0.46, 1.0, mid.z + 0.48, 0.78, 0.04)
	p.commit(w)
	if snow:
		var sn := FarmProps.Parts.new()
		_slab_top(sn.st(FarmProps.Parts.SNOW), r.position.x + 0.03, r.end.x - 0.03, mid.z - 0.43, 1.0, mid.z + 0.45, 0.78)
		sn.commit(w)


## A sloping plank slab: x from `x0` to `x1`, its top at height `yb` at z `zb` (the back) and
## `yf` at `zf` (the front), `thick` thick; world-unit UVs.
static func _slab(st: SurfaceTool, x0: float, x1: float, zb: float, yb: float, zf: float, yf: float, thick: float) -> void:
	var uv := func(q: Vector3) -> Vector2: return Vector2(q.x, q.z + q.y)
	var up := Vector3(0, zf - zb, yb - yf).normalized()
	var t := Vector3(0, thick, 0)
	var a := Vector3(x0, yb, zb)
	var b := Vector3(x1, yb, zb)
	var c := Vector3(x1, yf, zf)
	var d := Vector3(x0, yf, zf)
	Minka.quad(st, a, b, c, d, up, uv)
	Minka.quad(st, a - t, b - t, c - t, d - t, -up, uv)
	Minka.quad(st, d - t, c - t, c, d, Vector3(0, 0, 1), uv)
	Minka.quad(st, a - t, b - t, b, a, Vector3(0, 0, -1), uv)
	Minka.quad(st, a - t, d - t, d, a, Vector3(-1, 0, 0), uv)
	Minka.quad(st, b - t, c - t, c, b, Vector3(1, 0, 0), uv)


## The snow skin over a slab's top, a hair above it.
static func _slab_top(st: SurfaceTool, x0: float, x1: float, zb: float, yb: float, zf: float, yf: float) -> void:
	var none := func(_q: Vector3) -> Vector2: return Vector2.ZERO
	var lift := Vector3(0, 0.012, 0)
	Minka.quad(st, Vector3(x0, yb, zb) + lift, Vector3(x1, yb, zb) + lift, Vector3(x1, yf, zf) + lift, Vector3(x0, yf, zf) + lift,
		Vector3(0, zf - zb, yb - yf).normalized(), none)


# --- the river rock -----------------------------------------------------------

## A stepping rock out in the river: a wide faceted boulder with a smaller one against it, the
## stone dark and wet low down, lighter (and here and there mossy) on top, a pale ring of
## foam where the current breaks round it. Snow on the upper facets.
static func river_rock(w: FarmWorld, mid: Vector3, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var sn: SurfaceTool = null
	var snow_parts: FarmProps.Parts = null
	if snow:
		snow_parts = FarmProps.Parts.new()
		sn = snow_parts.st(FarmProps.Parts.SNOW)
	var seed := int(mid.x * 13 + mid.z * 29)
	var tones: Array[Color] = [Color("5c5852"), Color("78746c"), Color("8c8880")]
	_foam(p.st(Color("d4e4e6")), mid, 0.38, 0.32, 0.1, seed)
	_boulder(p, sn, mid, 0.38, 0.27, 0.32, seed + 1, tones)
	_boulder(p, sn, mid + Vector3(0.17, 0.1, -0.08), 0.2, 0.2, 0.17, seed + 2, tones)
	p.commit(w)
	if snow_parts != null:
		snow_parts.commit(w)


## A faceted boulder of half-widths rx / rz and height h standing on `at`: four rings of
## corners (the base, the belly, the shoulder, the apex), each corner nudged, flat facets
## coloured by height (and a few mossy), the upward ones copied into `sn` (or null).
static func _boulder(p: FarmProps.Parts, sn: SurfaceTool, at: Vector3, rx: float, h: float, rz: float, seed: int, tones: Array[Color]) -> void:
	const SIDES := 8
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var rings := [[0.0, 0.92], [0.36, 1.0], [0.74, 0.74]]
	var phase := rng.randf() * TAU
	var rows: Array = []
	for ring in rings:
		var row: Array[Vector3] = []
		for k in SIDES:
			var a := phase + TAU * k / SIDES
			var rr: float = float(ring[1]) * (1.0 + rng.randf_range(-0.13, 0.13))
			row.append(at + Vector3(cos(a) * rx * rr, h * float(ring[0]) * (1.0 + rng.randf_range(-0.06, 0.06)), sin(a) * rz * rr))
		rows.append(row)
	var apex := at + Vector3(rng.randf_range(-0.04, 0.04), h, rng.randf_range(-0.04, 0.04))
	var centre := at + Vector3(0, h * 0.4, 0)
	var facet := func(a: Vector3, b: Vector3, c: Vector3, tone: int) -> void:
		var n := (b - a).cross(c - a).normalized()
		var mid := (a + b + c) / 3.0
		if n.dot(mid - centre) < 0.0:
			n = -n
		var col := tones[tone]
		if tone == 2 and rng.randf() < 0.25:
			col = Color("6f7f55")
		var j := 1.0 + rng.randf_range(-0.05, 0.05)
		var sh := p.st(Color(col.r * j, col.g * j, col.b * j))
		_tri(sh, a, b, c, n)
		if sn != null and n.y > 0.45:
			var lift := Vector3(0, 0.012, 0)
			_tri(sn, a + lift, b + lift, c + lift, Vector3.UP)
	for ri in 2:
		for k in SIDES:
			var k2 := (k + 1) % SIDES
			var a: Vector3 = rows[ri][k]
			var b: Vector3 = rows[ri][k2]
			var c: Vector3 = rows[ri + 1][k2]
			var d: Vector3 = rows[ri + 1][k]
			facet.call(a, b, c, ri)
			facet.call(a, c, d, ri)
	for k in SIDES:
		facet.call(rows[2][k], rows[2][(k + 1) % SIDES], apex, 2)


## A flat ring of foam round a rock: from `rx` / `rz` out `reach` more, ragged, just over the ground.
static func _foam(st: SurfaceTool, at: Vector3, rx: float, rz: float, reach: float, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	const N := 14
	var inner: Array[Vector3] = []
	var outer: Array[Vector3] = []
	for k in N:
		var a := TAU * k / N
		var e := 1.0 + reach * rng.randf_range(0.5, 1.2) / rx
		inner.append(at + Vector3(cos(a) * rx * 0.85, 0.022, sin(a) * rz * 0.85))
		outer.append(at + Vector3(cos(a) * rx * e, 0.022, sin(a) * rz * e))
	for k in N:
		var k2 := (k + 1) % N
		_tri(st, inner[k], inner[k2], outer[k2], Vector3.UP)
		_tri(st, inner[k], outer[k2], outer[k], Vector3.UP)


# --- helpers ------------------------------------------------------------------

## A triangle facing `n` (corners turned to it), no UVs.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	Minka.tri(st, a, b, c, n, func(_q: Vector3) -> Vector2: return Vector2.ZERO)


## A tapering tube from `base` along `dir` (a unit vector), a flat-faced prism of `sides`
## sides through the profile `prof` (Vector2 radius, distance along dir), open at its ends;
## `col` (a Color, or null for none) paints it for vertex colour materials; a SurfaceTool must
## take colours on all its vertices or none.
static func _tube(st: SurfaceTool, base: Vector3, dir: Vector3, prof: Array, sides: int, col: Variant = null) -> void:
	var basis := Basis(Quaternion(Vector3.UP, dir)) if dir.cross(Vector3.UP).length() > 0.0001 else Basis.IDENTITY
	if col is Color:
		st.set_color(col)
	for i in prof.size() - 1:
		var p: Vector2 = prof[i]
		var q: Vector2 = prof[i + 1]
		for k in sides:
			var a0 := TAU * k / sides
			var a1 := TAU * (k + 1) / sides
			var am := (a0 + a1) / 2.0
			var n := basis * (Vector3(cos(am), 0, sin(am)) * (q.y - p.y) + Vector3.UP * (p.x - q.x)).normalized()
			var c0 := base + basis * Vector3(cos(a0) * p.x, p.y, sin(a0) * p.x)
			var c1 := base + basis * Vector3(cos(a1) * p.x, p.y, sin(a1) * p.x)
			var d1 := base + basis * Vector3(cos(a1) * q.x, q.y, sin(a1) * q.x)
			var d0 := base + basis * Vector3(cos(a0) * q.x, q.y, sin(a0) * q.x)
			_tri(st, c0, c1, d1, n)
			if q.x > 0.0001:
				_tri(st, c0, d1, d0, n)


static func _dir(yaw: float, tilt: float) -> Vector3:
	return Vector3(cos(yaw) * sin(tilt), cos(tilt), sin(yaw) * sin(tilt))


## Lit, painted by the vertices (so one mesh of many colours is one material that can fade).
static func _vertex_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	return m


## One snow skin material for all the bamboo of a world (set_snow drives it).
static func _snow_material(w: FarmWorld) -> ShaderMaterial:
	if w.has_meta("bamboo_snow"):
		return w.get_meta("bamboo_snow")
	var m := SnowLayer.top_material()
	w._snow_mats.append(m)
	w.set_meta("bamboo_snow", m)
	return m


## The world's one Sway (made on the first clump).
static func _sway(w: FarmWorld) -> Sway:
	var s: Sway = w.get_node_or_null("BambooSway")
	if s == null:
		s = Sway.new()
		s.name = "BambooSway"
		w.add_child(s)
	return s


## Moves the bamboo clumps in the wind: each leans a little to and fro about its foot, two
## slow waves out of step, its own phase by cell. `pose(t)` sets them for a time (tests).
class Sway extends Node3D:
	const AMPLITUDE := 0.028   # radians: about 0.07 units at the tip of a 2.5 high culm
	var _items: Array[Dictionary] = []
	var _time := 0.0

	func add(nodes: Array, yaw: float, phase: float) -> void:
		_items.append({"nodes": nodes, "yaw": yaw, "phase": phase})
		_apply(_items[_items.size() - 1])

	func count() -> int:
		return _items.size()

	func angle_of(i: int) -> float:
		return _angle(float(_items[i].phase))

	func _process(delta: float) -> void:
		pose(_time + delta)

	func pose(t: float) -> void:
		_time = t
		for it in _items:
			_apply(it)

	func _angle(phase: float) -> float:
		return AMPLITUDE * (0.7 * sin(_time * 1.3 + phase) + 0.3 * sin(_time * 2.9 + phase * 1.7))

	func _apply(it: Dictionary) -> void:
		var b := Basis(Vector3.BACK, _angle(float(it.phase))) * Basis(Vector3.UP, float(it.yaw))
		for n: Node3D in it.nodes:
			n.basis = b
