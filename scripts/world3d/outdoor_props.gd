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
const NEW_RED := Color("e23a2c")     # the jizo's new bibs (genzo_jizo), brighter than the old
const KILN_CLAY := Color("9a7656")
const KILN_FACE := 0.8               # the kiln's clay face, this far in front of its middle
const CLUMP_LOOKS := 8   # bamboo clump shapes; a cell picks one and turns it
const SWAY := "WindSway"  # the world's node that moves things in the wind (Sway)

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


## The new bib tied over the old one (StoryProps, genzo_jizo: heart_genzo_5): bright red cloth
## wider and longer than the old bib under it, a white hem along its bottom, a small white
## crest sewn on its front and a fresh collar tie at the neck. `mid` is the jizo's own (the middle of its cell).
static func jizo_bibs(w: FarmWorld, mid: Vector3) -> void:
	var p := FarmProps.Parts.new()
	var red := p.st(NEW_RED)
	var at := Vector3(mid.x, 0, mid.z)
	Shrine.lathe(red, at, [Vector2(0.072, 0.418), Vector2(0.096, 0.43), Vector2(0.098, 0.468), Vector2(0.07, 0.49)], 10)   # the tie
	FarmProps.block(red, Rect2(mid.x - 0.11, mid.z + 0.124, 0.22, 0.022), 0.2, Rect2(mid.x - 0.09, mid.z + 0.09, 0.18, 0.024), 0.47)
	var white := p.st(Color("f2ece0"))
	FarmProps.block(white, Rect2(mid.x - 0.112, mid.z + 0.122, 0.224, 0.028), 0.19,
		Rect2(mid.x - 0.108, mid.z + 0.118, 0.216, 0.028), 0.235)   # the hem
	FarmProps.block(white, Rect2(mid.x - 0.022, mid.z + 0.124, 0.044, 0.012), 0.32,
		Rect2(mid.x - 0.022, mid.z + 0.12, 0.044, 0.012), 0.37)   # a crest sewn on
	p.commit(w)


# --- the charcoal kiln --------------------------------------------------------

## Where the thumbprints sit on the kiln's clay face over its mouth, for the kiln on `r`:
## 0 the father's, 1 Ichiro's, 2 the farmer's (StoryProps, ichiro_mark). The middle of each.
static func kiln_mark_at(r: Rect2, i: int) -> Vector3:
	var mid := r.get_center()
	return Vector3(mid.x - 0.3 + i * 0.3, 0.6, mid.y + KILN_FACE + 0.003)


## One thumbprint pressed into the face at `at`: a dark oval in a lighter rim, facing the front.
## `big` is the father's broad thumb.
static func kiln_mark(w: FarmWorld, at: Vector3, big := false) -> void:
	var p := FarmProps.Parts.new()
	var s := 1.12 if big else 1.0
	# About 0.2 cells across: 4 px or more at the medium lens, so the print reads as a print.
	_oval(p.st(KILN_CLAY.lightened(0.25)), at, 0.1 * s, 0.075 * s)
	_oval(p.st(Color("4a2e1c")), at + Vector3(0, 0, 0.002), 0.07 * s, 0.054 * s)
	p.commit(w)


## Ichiro's charcoal kiln (sumigama) on `r` (2 x 2 cells): a low dome of baked clay, a flat clay
## face at the front (+z) with a stone-framed mouth, a clay chimney at the back, and two
## thumbprints over the mouth (the father's and Ichiro's; the farmer's is a story prop). Snow
## on the dome's crown and the face's top.
static func kiln(w: FarmWorld, r: Rect2, mid: Vector3, snow: bool, prints: Array = [0, 1], worn := true) -> void:
	var p := FarmProps.Parts.new()
	var clay := p.st(KILN_CLAY)
	var dome_at := Vector3(mid.x, 0, mid.z - 0.1)
	Shrine.lathe(p.st(KILN_CLAY.darkened(0.15)), dome_at, [Vector2(0.84, 0.0), Vector2(0.85, 0.12)], 14)   # the soot-dark foot
	Shrine.lathe(clay, dome_at, [Vector2(0.85, 0.12), Vector2(0.8, 0.36), Vector2(0.64, 0.58), Vector2(0.4, 0.73), Vector2(0.0, 0.8)], 14)
	var face := mid.z + KILN_FACE
	FarmProps.block(p.st(KILN_CLAY.lightened(0.06)), Rect2(mid.x - 0.48, face - 0.3, 0.96, 0.3), 0.0, Rect2(mid.x - 0.44, face - 0.26, 0.88, 0.26), 0.7)
	FarmProps.block(p.st(Color("1e1612")), Rect2(mid.x - 0.15, face - 0.01, 0.3, 0.014), 0.0, Rect2(mid.x - 0.11, face - 0.01, 0.22, 0.014), 0.38)   # the mouth
	var stone := p.st(STONE)
	for x in [mid.x - 0.2, mid.x + 0.2]:
		FarmProps.block(stone, Rect2(x - 0.035, face - 0.03, 0.07, 0.06), 0.0, Rect2(x - 0.03, face - 0.025, 0.06, 0.05), 0.42)
	FarmProps.block(p.st(STONE_LIGHT), Rect2(mid.x - 0.27, face - 0.035, 0.54, 0.07), 0.42, Rect2(mid.x - 0.26, face - 0.03, 0.52, 0.06), 0.5)   # the lintel
	FarmProps.block(p.st(STONE_DARK), Rect2(mid.x - 0.3, face, 0.6, 0.12), 0.0, Rect2(mid.x - 0.28, face + 0.01, 0.56, 0.1), 0.04)   # the hearth stone
	Shrine.lathe(p.st(KILN_CLAY.darkened(0.3)), Vector3(mid.x + 0.3, 0, mid.z - 0.72), [Vector2(0.09, 0.3), Vector2(0.085, 0.98), Vector2(0.07, 1.02)], 8)   # the chimney
	if worn:
		_worn(p, mid, face)
	p.commit(w)
	for i in prints:   # 0 the father's, 1 Ichiro's: the old kiln has both, the new one only Ichiro's
		kiln_mark(w, kiln_mark_at(r, i), i == 0)
	if snow:
		var sn := FarmProps.Parts.new()
		var s := sn.st(FarmProps.Parts.SNOW)
		Shrine.lathe(s, dome_at, [Vector2(0.62, 0.6), Vector2(0.4, 0.742), Vector2(0.0, 0.812)], 14)
		var top := Rect2(mid.x - 0.44, face - 0.26, 0.88, 0.26)
		FarmProps.block(s, top.grow(-0.01), 0.7, top.grow(-0.03), 0.72)
		sn.commit(w)


## The old kiln's wear (kiln, `worn`): two hairline cracks in the clay face, a short branch off
## one, and a chipped-off piece at the face's top right with its pale broken edge. Flat quads
## on the face (a few thousandths in front of it), in one dark colour, kept clear of the mouth
## and the thumbprints. The new kiln is not worn.
static func _worn(p: FarmProps.Parts, mid: Vector3, face: float) -> void:
	var crack := p.st(Color("2e1d12"))
	var z := face + 0.004
	_seam(crack, Vector2(mid.x - 0.46, 0.5), Vector2(mid.x - 0.42, 0.26), z, 0.008)
	_seam(crack, Vector2(mid.x - 0.43, 0.38), Vector2(mid.x - 0.34, 0.34), z, 0.006)   # the branch
	_seam(crack, Vector2(mid.x + 0.44, 0.52), Vector2(mid.x + 0.38, 0.3), z, 0.007)   # clear of the prints
	# the chip: a notch the clay broke out of, dark inside, with a pale edge along its top
	var c := Vector2(mid.x + 0.36, 0.64)
	_seam(crack, c, c + Vector2(0.09, 0.0), z, 0.02)
	_seam(p.st(KILN_CLAY.lightened(0.3)), c + Vector2(0.0, 0.03), c + Vector2(0.09, 0.03), z + 0.001, 0.008)


## One flat seam on the face from `a` to `b` (x, y), `half` wide, facing +z at depth `z`.
static func _seam(st: SurfaceTool, a: Vector2, b: Vector2, z: float, half: float) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * half
	var p0 := Vector3(a.x + n.x, a.y + n.y, z)
	var p1 := Vector3(a.x - n.x, a.y - n.y, z)
	var p2 := Vector3(b.x - n.x, b.y - n.y, z)
	var p3 := Vector3(b.x + n.x, b.y + n.y, z)
	_tri(st, p0, p1, p2, Vector3(0, 0, 1))
	_tri(st, p0, p2, p3, Vector3(0, 0, 1))


## The new kiln going up beside the old one (StoryProps kiln_site; ichiro_kiln, until ichiro_mark):
## a half-built mound of clay bricks in courses (a low ring with a gap for the mouth, a lower
## second course), a stack of fresh bricks beside it, a wooden form for the arch and a shovel
## stuck upright in the dirt. Snow on the mound's top.
static func kiln_site(w: FarmWorld, r: Rect2, mid: Vector3, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var brick := p.st(Color("b4553a"))
	var brick2 := p.st(Color("9a4630"))
	var at := Vector2(mid.x, mid.z - 0.1)
	# Two courses of bricks round the mound, each brick a little block; the front is left open.
	for course in 2:
		var n := 14 - course * 2
		var rad := 0.74 - course * 0.1
		for k in n:
			var a := TAU * (k + 0.5 * course) / n
			if sin(a) > 0.82:   # towards +z, the open mouth
				continue
			var c := at + Vector2(cos(a), sin(a)) * rad
			var y0 := course * 0.15
			var st := brick if (k + course) % 2 == 0 else brick2
			FarmProps.block(st, Rect2(c.x - 0.12, c.y - 0.09, 0.24, 0.18), y0, Rect2(c.x - 0.11, c.y - 0.08, 0.22, 0.16), y0 + 0.14)
	# the wet clay filling the inside of the ring
	Shrine.lathe(p.st(KILN_CLAY.darkened(0.1)), Vector3(at.x, 0, at.y), [Vector2(0.62, 0.0), Vector2(0.6, 0.2), Vector2(0.36, 0.3), Vector2(0.0, 0.32)], 12)
	# a stack of fresh bricks, three courses, in front-right
	var sx := mid.x + 0.62
	var sz := mid.z + 0.5
	for row in 3:
		for k in 3 - row:
			var bx := sx - 0.14 * (2 - row) * 0.5 + k * 0.15 - 0.15
			FarmProps.block(brick if (row + k) % 2 == 0 else brick2, Rect2(bx, sz, 0.14, 0.2), row * 0.07, Rect2(bx + 0.005, sz + 0.005, 0.13, 0.19), row * 0.07 + 0.065)
	# the timber form for the arch: two posts and a crosspiece in the open mouth
	var wood := p.st(Color("7a5a3a"))
	for x in [mid.x - 0.28, mid.x + 0.28]:
		FarmProps.block(wood, Rect2(x - 0.04, mid.z + 0.55, 0.08, 0.08), 0.0, Rect2(x - 0.035, mid.z + 0.555, 0.07, 0.07), 0.45)
	FarmProps.block(wood, Rect2(mid.x - 0.3, mid.z + 0.55, 0.6, 0.08), 0.42, Rect2(mid.x - 0.3, mid.z + 0.555, 0.6, 0.07), 0.5)
	# the shovel: a pale handle and a steel blade, stuck in the dirt left of the mound
	FarmProps.block(p.st(Color("c9a468")), Rect2(mid.x - 0.82, mid.z + 0.4, 0.05, 0.05), 0.0, Rect2(mid.x - 0.815, mid.z + 0.405, 0.04, 0.04), 0.78)
	FarmProps.block(p.st(Color("8a8f96")), Rect2(mid.x - 0.88, mid.z + 0.39, 0.17, 0.07), 0.0, Rect2(mid.x - 0.86, mid.z + 0.395, 0.13, 0.06), 0.24)
	p.commit(w)
	if snow:
		var sn := FarmProps.Parts.new()
		Shrine.lathe(sn.st(FarmProps.Parts.SNOW), Vector3(at.x, 0, at.y), [Vector2(0.4, 0.3), Vector2(0.2, 0.335), Vector2(0.0, 0.345)], 12)
		sn.commit(w)


## A flat oval facing +z round `at`, half-widths rx (across) and ry (up).
static func _oval(st: SurfaceTool, at: Vector3, rx: float, ry: float) -> void:
	const N := 12
	for k in N:
		var a0 := TAU * k / N
		var a1 := TAU * (k + 1) / N
		_tri(st, at, at + Vector3(cos(a0) * rx, sin(a0) * ry, 0), at + Vector3(cos(a1) * rx, sin(a1) * ry, 0), Vector3(0, 0, 1))


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


# --- Shige's hen barn and the ditch behind his beds ---------------------------

## The z of the hen barn's front wall over footprint `r` (Nana's sky map is pinned to it).
static func hen_barn_front(r: Rect2) -> float:
	return r.end.y - 0.2


## Shige's little board hen barn (Minamino, east of his beds) over the cells `r`: plank walls
## on a low stone footing, a plank lean-to roof sloping down to the front (+z) past the walls,
## timber corner posts, a board door on the right of the front and a little hen hole low on
## the left with a cleated ramp up to it. Snow on the roof.
static func hen_barn(w: FarmWorld, r: Rect2, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var x0 := r.position.x + 0.1
	var x1 := r.end.x - 0.1
	var z0 := r.position.y + 0.15
	var z1 := hen_barn_front(r)
	var eave := 1.28   # the walls' top at the front, inside the roof's slab
	var ridge := 1.66  # the roof's back edge
	FarmProps.block(p.st(STONE_DARK), Rect2(x0 - 0.02, z0 - 0.02, x1 - x0 + 0.04, z1 - z0 + 0.04), 0.0, Rect2(x0 - 0.02, z0 - 0.02, x1 - x0 + 0.04, z1 - z0 + 0.04), 0.08)
	FarmProps.block(p.st("build:planks"), Rect2(x0, z0, x1 - x0, z1 - z0), 0.08, Rect2(x0, z0, x1 - x0, z1 - z0), eave)
	# The sides rise with the roof towards the back: a board wedge on each end.
	var walls := p.st("build:planks")
	var uv := func(q: Vector3) -> Vector2: return Vector2(q.z, -q.y)
	for side in [[x0, -1.0], [x1, 1.0]]:
		var x: float = side[0]
		Minka.tri(walls, Vector3(x, eave, z0), Vector3(x, eave, z1), Vector3(x, ridge - 0.04, z0), Vector3(side[1], 0, 0), uv)
	Minka.quad(walls, Vector3(x0, eave, z0), Vector3(x1, eave, z0), Vector3(x1, ridge - 0.04, z0), Vector3(x0, ridge - 0.04, z0), Vector3(0, 0, -1), uv)
	var post := p.st(TIMBER)
	for x in [x0, x1]:
		for z in [z0, z1]:
			FarmProps.block(post, Rect2(x - 0.04, z - 0.04, 0.08, 0.08), 0.0, Rect2(x - 0.04, z - 0.04, 0.08, 0.08), eave + (ridge - 0.05 - eave) * (z1 - z) / (z1 - z0))
	FarmProps.block(post, Rect2(x0, z1 - 0.01, x1 - x0, 0.05), eave - 0.08, Rect2(x0, z1 - 0.01, x1 - x0, 0.05), eave)   # the front beam
	# The board door on the right and the hen hole with its ramp on the left.
	var dx := x1 - 0.5
	FarmProps.block(p.st("build:planks_dark"), Rect2(dx - 0.28, z1, 0.56, 0.035), 0.08, Rect2(dx - 0.28, z1, 0.56, 0.035), 1.08)
	FarmProps.block(post, Rect2(dx - 0.28, z1 + 0.035, 0.56, 0.02), 0.62, Rect2(dx - 0.28, z1 + 0.035, 0.56, 0.02), 0.68)   # its cross batten
	FarmProps.block(p.st(Color("3a3a40")), Rect2(dx - 0.22, z1 + 0.035, 0.05, 0.03), 0.5, Rect2(dx - 0.22, z1 + 0.035, 0.05, 0.03), 0.56)   # the latch
	var hx := x0 + 0.3
	FarmProps.block(p.st(Color("1a1410")), Rect2(hx - 0.12, z1, 0.24, 0.012), 0.08, Rect2(hx - 0.12, z1, 0.24, 0.012), 0.27)
	_slab(p.st("build:planks_dark"), hx - 0.09, hx + 0.09, z1 + 0.01, 0.1, z1 + 0.4, 0.02, 0.025)
	# The lean-to roof, out past the walls on every side.
	_slab(p.st("build:planks_dark"), x0 - 0.14, x1 + 0.14, z0 - 0.16, ridge, z1 + 0.28, eave - 0.02, 0.045)
	p.commit(w)
	if snow:
		var sn := FarmProps.Parts.new()
		_slab_top(sn.st(FarmProps.Parts.SNOW), x0 - 0.11, x1 + 0.11, z0 - 0.13, ridge, z1 + 0.25, eave - 0.02)
		sn.commit(w)


## The ditch behind Shige's beds (where Nana found Captain) along the cells `r`: a narrow run of
## still dark water between low muddy banks, a few reeds standing out of it. Outdoors a snow skin
## lies over it all when snow does (the snow top material shows it by the cover).
static func ditch(w: FarmWorld, r: Rect2, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var zc := r.get_center().y
	var x0 := r.position.x + 0.05
	var x1 := r.end.x - 0.05
	var flat := func(q: Vector3) -> Vector2: return Vector2(q.x, q.z)
	Minka.quad(p.st(Color("34504a")), Vector3(x0, 0.03, zc - 0.17), Vector3(x1, 0.03, zc - 0.17),
		Vector3(x1, 0.03, zc + 0.17), Vector3(x0, 0.03, zc + 0.17), Vector3.UP, flat)
	Minka.quad(p.st(Color("5a7a70")), Vector3(x0, 0.031, zc - 0.17), Vector3(x1, 0.031, zc - 0.17),
		Vector3(x1, 0.031, zc - 0.11), Vector3(x0, 0.031, zc - 0.11), Vector3.UP, flat)   # the sky caught along the far edge
	var mud := p.st(Color("6a5238"))
	for z in [zc - 0.3, zc + 0.17]:
		FarmProps.block(mud, Rect2(x0, z, x1 - x0, 0.13), 0.0, Rect2(x0, z + 0.02, x1 - x0, 0.09), 0.07)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x) * 13 + int(r.position.y) * 7 + 3
	var reed := p.st(Color("6e8a3a"))
	for i in int(r.size.x * 3):
		var x := x0 + 0.12 + rng.randf() * (x1 - x0 - 0.24)
		var z := zc + (rng.randf_range(-0.22, -0.12) if i % 2 == 0 else rng.randf_range(0.12, 0.22))
		var h := rng.randf_range(0.28, 0.5)
		FarmProps.block(reed, Rect2(x - 0.012, z - 0.012, 0.024, 0.024), 0.0, Rect2(x - 0.004, z - 0.004, 0.008, 0.008), h)
	p.commit(w)
	if snow:   # snow on the banks (and a skin over the still water) when it lies
		var sn := FarmProps.Parts.new()
		var none := func(_q: Vector3) -> Vector2: return Vector2.ZERO
		Minka.quad(sn.st(FarmProps.Parts.SNOW), Vector3(x0, 0.082, zc - 0.29), Vector3(x1, 0.082, zc - 0.29),
			Vector3(x1, 0.082, zc + 0.29), Vector3(x0, 0.082, zc + 0.29), Vector3.UP, none)
		sn.commit(w)


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


## Mio's old ferry boat on the river (a flat-bottomed wooden boat, long along x over its cells):
## a cedar hull sitting low in the water, flaring out to its gunwales, a raised square bow at
## the east end, two thwarts, the dark wet floor inside and the long pole lying along the seats.
## Its name, once painted (StoryProps "boat_name"), is a picture on the side facing the camera.
static func ferry_boat(w: FarmWorld, r: Rect2, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var hull := p.st(Color("8a6440"))
	var rim := p.st(Color("5e4228"))
	var inside := p.st(Color("4a3424"))
	var cz := r.get_center().y
	var x0 := r.position.x + 0.15
	var x1 := r.end.x - 0.45
	var half := 0.3
	FarmProps.block(hull, Rect2(x0 + 0.1, cz - half + 0.08, x1 - x0 - 0.1, (half - 0.08) * 2), -0.06,
		Rect2(x0, cz - half, x1 - x0, half * 2), 0.18)
	FarmProps.block(hull, Rect2(x1, cz - half + 0.12, 0.08, (half - 0.12) * 2), -0.06,   # the bow, rising and narrowing
		Rect2(x1, cz - half + 0.06, 0.3, (half - 0.06) * 2), 0.26)
	FarmProps.block(inside, Rect2(x0 + 0.06, cz - half + 0.06, x1 - x0 - 0.06, (half - 0.06) * 2), 0.18,
		Rect2(x0 + 0.06, cz - half + 0.06, x1 - x0 - 0.06, (half - 0.06) * 2), 0.185)
	for z in [cz - half, cz + half - 0.05]:   # the gunwales
		FarmProps.block(rim, Rect2(x0, z, x1 - x0 + 0.3, 0.05), 0.18, Rect2(x0, z, x1 - x0 + 0.3, 0.05), 0.22)
	FarmProps.block(rim, Rect2(x0 - 0.02, cz - half, 0.06, half * 2), 0.14, Rect2(x0 - 0.02, cz - half, 0.06, half * 2), 0.22)   # the stern board
	for x in [x0 + 0.55, x1 - 0.5]:   # two thwarts across
		FarmProps.block(rim, Rect2(x, cz - half, 0.12, half * 2), 0.19, Rect2(x, cz - half, 0.12, half * 2), 0.23)
	_foam(p.st(Color("d4e4e6")), Vector3(r.get_center().x, 0, cz), (r.size.x) * 0.48, 0.42, 0.03, int(r.position.x * 7))
	if snow:
		FarmProps.block(p.st(FarmProps.Parts.SNOW), Rect2(x0 + 0.5, cz - 0.2, 0.5, 0.4), 0.185, Rect2(x0 + 0.55, cz - 0.16, 0.4, 0.32), 0.22)
	var first := w.get_child_count()
	p.commit(w)
	var ride := BoatRide.new()   # the boat moves as one when Mio takes it across (FerryRun)
	ride.name = BoatRide.NAME
	for n in w.get_children().slice(first):
		w.remove_child(n)
		ride.add_child(n)
	var pole := FarmProps.Parts.new()   # the pole along the seats: in Mio's hands while she crosses
	FarmProps.block(pole.st(Color("b89a68")), Rect2(x0 + 0.2, cz - 0.03, x1 - x0, 0.05), 0.23,
		Rect2(x0 + 0.2, cz - 0.03, x1 - x0, 0.05), 0.26)
	first = w.get_child_count()
	pole.commit(w)
	var lying := Node3D.new()
	lying.name = BoatRide.POLE
	for n in w.get_children().slice(first):
		w.remove_child(n)
		lying.add_child(n)
	ride.add_child(lying)
	w.add_child(ride)


## The ferry boat's pieces (and its painted name, StoryProps), moved by FerryRun.boat_offset
## each frame from where the poler's plan has them: tied at the mooring, or out on the river.
class BoatRide extends Node3D:
	const NAME := "FerryBoat"
	const POLE := "Pole"

	func _process(_delta: float) -> void:
		refresh()

	func refresh() -> void:
		var game := get_node_or_null("/root/Game")
		if game == null:
			return
		var w := Villagers.where(FerryRun.villager(), game.day_minutes(), game.trigger_state(Vector2i.ZERO))
		var off := FerryRun.boat_offset(w)
		position = Vector3(off.x, 0, off.y)
		get_node(POLE).visible = not FerryRun.in_use(w)


## A small plank landing from the shore out over the water (Mio's ferry stage): boards laid
## across two bearers on four posts standing in the river, a mooring post at the far corner.
static func landing(w: FarmWorld, r: Rect2) -> void:
	var p := FarmProps.Parts.new()
	var post := p.st(Color("4a3424"))
	var board := p.st(Color("9a7650"))
	var dark := p.st(Color("7a5a3a"))
	var top := 0.16
	for x in [r.position.x + 0.15, r.end.x - 0.22]:
		for z in [r.position.y - 0.25, r.end.y - 0.2]:
			FarmProps.block(post, Rect2(x, z, 0.07, 0.07), -0.1, Rect2(x, z, 0.07, 0.07), top)
	var n := 6
	var deck := r.size.y + 0.35
	for i in n:
		var x := r.position.x + 0.1 + i * (r.size.x - 0.2) / n
		FarmProps.block(board if i % 2 == 0 else dark, Rect2(x, r.position.y - 0.3, (r.size.x - 0.2) / n - 0.015, deck), top,
			Rect2(x, r.position.y - 0.3, (r.size.x - 0.2) / n - 0.015, deck), top + 0.04)
	FarmProps.block(post, Rect2(r.end.x - 0.2, r.end.y - 0.18, 0.09, 0.09), top, Rect2(r.end.x - 0.19, r.end.y - 0.17, 0.07, 0.07), top + 0.32)
	p.commit(w)


## Shino's drying rack beside her dye vats (DyeCloth, a "cloth_rack" prop): a pole across each
## row of its cells on two bamboo posts, and one long indigo length over each pole, the shades
## of DyeCloth.shades, hanging free on both faces and swaying in the wind (Sway, lift 0). The
## lengths stand in a DyeCloth.Show, out only in the rack's hours on dry days; the frame stays.
static func cloth_rack(w: FarmWorld, p: Dictionary, r: Rect2) -> DyeCloth.Show:
	var parts := FarmProps.Parts.new()
	var post := parts.st(Color("a89a60"))
	var pole := parts.st(Color("cdbd80"))
	var top := DyeCloth.POLE_Y
	var x0 := r.position.x + 0.1
	var x1 := r.end.x - 0.16
	var shades := DyeCloth.shades(p)
	for i in shades.size():
		var z := r.position.y + i + 0.5
		for x in [x0, x1]:
			FarmProps.block(post, Rect2(x, z - 0.03, 0.06, 0.06), 0.0, Rect2(x + 0.005, z - 0.025, 0.05, 0.05), top + 0.12)
		FarmProps.block(pole, Rect2(x0 - 0.06, z - 0.025, x1 - x0 + 0.18, 0.05), top - 0.025,
			Rect2(x0 - 0.06, z - 0.025, x1 - x0 + 0.18, 0.05), top + 0.025)
	parts.commit(w)
	var show := DyeCloth.Show.new()
	show.name = "DyeCloth"
	show.rack = p
	w.add_child(show)
	var size := Vector2(x1 - x0 - 0.12, DyeCloth.DROP)
	for i in shades.size():
		var quad := QuadMesh.new()
		quad.size = size
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		var mat := FarmWorld.picture_material(DyeCloth.art_key(shades[i]))
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED   # seen from both sides as it swings
		mi.material_override = mat
		show.add_child(mi)
		var hinge := Vector3((x0 + x1 + 0.06) / 2, top, r.position.y + i + 0.5)
		_sway(w).add_cloth([mi], hinge, 0.0, 1.3 * i + r.position.x, Vector3(0, -size.y / 2, 0), 0.0)
	return show


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


# --- the farm's bamboo fence ---------------------------------------------------------

## The fence's aged bamboo: culm, node ring, cut face, hollow and the cord of the ties.
const FENCE_CULM := Color("a6a45e")
const FENCE_NODE := Color("c8c488")
const FENCE_CUT := Color("e4dcaa")
const FENCE_HOLLOW := Color("4a4630")
const FENCE_CORD := Color("3a2c20")
const FENCE_POST_H := 0.64
const FENCE_CANE_H := 0.52
const FENCE_RAILS: Array[float] = [0.2, 0.44]


## A bamboo pole from `base` along `dir`, tapering r0 to r1, a node ring every `spacing`
## (the first at `first`), the rings on `node_st`.
static func pole(st: SurfaceTool, node_st: SurfaceTool, base: Vector3, dir: Vector3, r0: float, r1: float, length: float,
		spacing: float, first: float, sides := 6) -> void:
	_tube(st, base, dir, [Vector2(r0, 0.0), Vector2(r1, length)], sides, null)
	var s := first
	while s < length - 0.03:
		var r := lerpf(r0, r1, s / length)
		_tube(node_st, base + dir * s, dir, [Vector2(r, -0.012), Vector2(r * 1.3, 0.0), Vector2(r, 0.012)], sides, null)
		s += spacing


## A fence post at (x, z): a thick eight-sided culm with node rings, a cut top (pale face, dark
## hollow), a cord tie at each rail height; snow caps it.
static func fence_post(p: FarmProps.Parts, x: float, z: float) -> void:
	var at := Vector3(x, 0, z)
	pole(p.st(FENCE_CULM), p.st(FENCE_NODE), at, Vector3.UP, 0.062, 0.054, FENCE_POST_H, 0.21, 0.1, 8)
	Shrine.lathe(p.st(FENCE_CUT), at, [Vector2(0.054, FENCE_POST_H), Vector2(0.0, FENCE_POST_H)], 8)
	Shrine.lathe(p.st(FENCE_HOLLOW), at, [Vector2(0.03, FENCE_POST_H + 0.003), Vector2(0.0, FENCE_POST_H + 0.003)], 8)
	var cord := p.st(FENCE_CORD)
	for y in FENCE_RAILS:   # the cord turns round the post and the rail
		_tube(cord, at + Vector3(0, y - 0.035, 0), Vector3.UP,
			[Vector2(0.066, 0.0), Vector2(0.074, 0.012), Vector2(0.074, 0.058), Vector2(0.066, 0.07)], 8, null)
	var sn := p.st(FarmProps.Parts.SNOW)
	FarmProps.block(sn, Rect2(x - 0.06, z - 0.06, 0.12, 0.12), FENCE_POST_H + 0.006, Rect2(x - 0.035, z - 0.035, 0.07, 0.07), FENCE_POST_H + 0.034)


## A thin cane standing at (x, z) between the posts: a node ring in the middle, a cut top.
static func fence_cane(p: FarmProps.Parts, x: float, z: float) -> void:
	var at := Vector3(x, 0, z)
	pole(p.st(FENCE_CULM), p.st(FENCE_NODE), at, Vector3.UP, 0.045, 0.04, FENCE_CANE_H, 0.26, 0.26, 6)
	Shrine.lathe(p.st(FENCE_CUT), at, [Vector2(0.04, FENCE_CANE_H), Vector2(0.0, FENCE_CANE_H)], 6)


## A cross rail from `a` to `b` (both at the rail's height, along x or z): a bamboo pole with a
## node ring each half cell, snow lying on the upper rail.
static func fence_rail(p: FarmProps.Parts, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var length := d.length()
	pole(p.st(FENCE_CULM), p.st(FENCE_NODE), a, d / length, 0.036, 0.036, length, 0.5, 0.25, 6)
	if a.y > FENCE_RAILS[0] + 0.01:
		var lo := Vector3(minf(a.x, b.x), 0, minf(a.z, b.z))
		var hi := Vector3(maxf(a.x, b.x), 0, maxf(a.z, b.z))
		var along_x := absf(d.x) > absf(d.z)
		var r0 := Rect2(lo.x, lo.z - 0.032, hi.x - lo.x, 0.064) if along_x else Rect2(lo.x - 0.032, lo.z, 0.064, hi.z - lo.z)
		FarmProps.block(p.st(FarmProps.Parts.SNOW), r0,
			a.y + 0.03, r0.grow(-0.012), a.y + 0.052)


## Where a fence post keeps a live side shoot: its node 0.52 up (under the cut top).
const FENCE_SPRAY_Y := 0.52
static var _sprays := {}   # season -> the shared spray mesh

## A leafy side shoot on a fence post at (x, z): a thin twig out of the post's upper node along
## `yaw` (along the fence line, so it stays over the line) and four small bamboo leaves fanned
## a little round it, drooping, in the season's leaf colours. One shared mesh a season (vertex
## colours, lit), turned and placed per post; the world's Sway leans it in the wind about the
## node (the post itself stays still). No snow skin: the leaves are too small to carry one.
static func fence_spray(w: FarmWorld, x: float, z: float, yaw: float, season: String, phase: float) -> MeshInstance3D:
	if not _sprays.has(season):
		_sprays[season] = _build_spray(season)
	var sway := _sway(w)
	var mi := MeshInstance3D.new()
	mi.mesh = _sprays[season]
	mi.material_override = _vertex_material()
	w.add_child(mi)
	var foot := Vector3(x, FENCE_SPRAY_Y, z)
	sway.add_leaves([mi], foot, yaw, phase)
	return mi


static func _build_spray(season: String) -> ArrayMesh:
	var leaves: Array = BAMBOO.get(season, BAMBOO.summer).leaves
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var twig := Vector3(1.0, 0.7, 0.0).normalized()
	_tube(st, Vector3(0.05, 0, 0), twig, [Vector2(0.009, 0.0), Vector2(0.005, 0.12)], 4, Color("6a7a40"))
	var base := Vector3(0.05, 0, 0) + twig * 0.12
	# Paler and yellower than the clumps' leaves (young leaves in the sun), so the small shoot
	# reads against the grass behind it.
	for j in 5:
		var a := (j - 2.0) * 0.2
		var rise := -0.12 - 0.14 * (j % 2)
		var d := Vector3(cos(a) * cos(rise), sin(rise), sin(a) * cos(rise)).normalized()
		var col := (leaves[j % leaves.size()] as Color).lerp(Color("e8e070"), 0.35)
		_leaf(st, null, base, d, 0.28 + 0.03 * (j % 2), 0.08, col)
	return st.commit()


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


## The world's one Sway (made on the first thing that moves in the wind).
static func _sway(w: FarmWorld) -> Sway:
	var s: Sway = w.get_node_or_null(SWAY)
	if s == null:
		s = Sway.new()
		s.name = SWAY
		s.wind = w.wind
		w.add_child(s)
	return s


## Commits `p` to `w` as one piece that moves in the wind about `hinge` (a world point; the
## geometry is in world units, so at rest it stands as built): `kind` "leaves" lean a little
## about it (a sprig, a twig), "cloth" hangs from its top edge and blows out (`lift`, see
## Sway.add_cloth). The Sway is made first, so its node is not one of the meshes. The meshes.
static func commit_swaying(w: FarmWorld, p: FarmProps.Parts, hinge: Vector3, kind: String, phase: float,
		lift := Sway.CLOTH_LIFT) -> Array:
	var sway := _sway(w)
	var first := w.get_child_count()
	p.commit(w)
	var nodes := w.get_children().slice(first)
	if kind == "cloth":
		sway.add_cloth(nodes, hinge, 0.0, phase, -hinge, lift)
	else:
		sway.add_leaves(nodes, hinge, 0.0, phase, -hinge)
	return nodes


## A cloth picture (a noren: a QuadMesh `size` across, centred on its node, facing its yaw)
## hung by its top edge, blowing out from the wall in the wind.
static func sway_picture(w: FarmWorld, mi: MeshInstance3D, size: Vector2, phase: float) -> void:
	_sway(w).add_cloth([mi], mi.position + Vector3(0, size.y / 2, 0), mi.rotation.y, phase, Vector3(0, -size.y / 2, 0))


## Moves things in the wind (FarmWorld.set_wind, data/wind.json). Three kinds:
##  - bamboo clumps (`add`): each leans a little to and fro about its foot, two slow waves out
##    of step, its own phase by cell; at wind 0 the old calm wave;
##  - leaves (`add_leaves`: the kadomatsu's pine sprigs and plum twig, the sprays on the fence
##    posts): a small lean downwind (+x, as the grass leans) about their base and a quicker
##    wave on it;
##  - cloth (`add_cloth`: the noren, the stalls' curtains, the race banner): hung by its top
##    edge, the bottom blows out from its face (`lift`) and streams downwind (a shear, so the
##    top edge stays on its rod), fluttering in gusts.
## Leaves and cloth stand still at wind 0, as they did before. Posts, culms and rods are not in
## it. `pose(t)` sets everything for a time (tests).
class Sway extends Node3D:
	const AMPLITUDE := 0.028   # radians: about 0.07 units at the tip of a 2.5 high culm
	const LEAF_LEAN := 0.06    # leaves: radians downwind per unit of wind ...
	const LEAF_WAVE := 0.08    # ... and the wave on it (a pine sprig's tip moves about 0.06 in a gale)
	const CLOTH_LIFT := 0.35   # a hanging cloth's steady blow-out per unit of wind (sine of the angle)
	const CLOTH_FLUTTER := 0.22
	const CLOTH_STREAM := 0.3  # the downwind shear per unit of wind (the hem moves this x its drop)
	var wind := 0.0            # 0 dead calm .. 1 a gale (FarmWorld.set_wind, data/wind.json)
	var _items: Array[Dictionary] = []
	var _time := 0.0

	## A bamboo clump's meshes (standing at its foot, turned by `yaw`).
	func add(nodes: Array, yaw: float, phase: float) -> void:
		_put({"kind": "clump", "nodes": nodes, "yaw": yaw, "phase": phase})

	## Leaves leaning about `hinge`: each node is its mesh moved by `offset` (-hinge for a mesh
	## built in world units), turned by `yaw`, leaned at the hinge.
	func add_leaves(nodes: Array, hinge: Vector3, yaw: float, phase: float, offset := Vector3.ZERO) -> void:
		_put({"kind": "leaves", "nodes": nodes, "hinge": hinge, "yaw": yaw, "phase": phase, "offset": offset})

	## A cloth hung by its top edge at `hinge`, its face turned by `yaw` (it looks along local
	## +z). `lift`: the steady blow-out per unit of wind; CLOTH_LIFT for a cloth before a wall or
	## a counter (it only ever lifts away from it), 0 for one free on both faces (it swings both ways).
	func add_cloth(nodes: Array, hinge: Vector3, yaw: float, phase: float, offset := Vector3.ZERO, lift := CLOTH_LIFT) -> void:
		_put({"kind": "cloth", "nodes": nodes, "hinge": hinge, "yaw": yaw, "phase": phase, "offset": offset, "lift": lift})

	func _put(it: Dictionary) -> void:
		_items.append(it)
		_apply(it)

	## Thing `i` as it was added ({kind, nodes, yaw, phase ...}; MeshCache keeps it) and one
	## added again from such a dictionary (posed at once).
	func item(i: int) -> Dictionary:
		return _items[i]

	func put(it: Dictionary) -> void:
		_put(it)

	func count() -> int:
		return _items.size()

	## How many things of `kind` ("clump", "leaves", "cloth") it moves.
	func count_of(kind: String) -> int:
		return _items.filter(func(it): return it.kind == kind).size()

	## Thing `i`'s meshes and its hinge (a clump's: its foot).
	func nodes_of(i: int) -> Array:
		return _items[i].nodes

	func hinge_of(i: int) -> Vector3:
		return _items[i].get("hinge", (_items[i].nodes[0] as Node3D).position)

	func kind_of(i: int) -> String:
		return _items[i].kind

	func angle_of(i: int) -> float:
		return _angle(float(_items[i].phase))

	## Where the point `local` of thing `i` (in its own frame at the hinge, before its yaw: for
	## a cloth y down the drop, z out of its face) is now, against the hinge.
	func moved(i: int, local: Vector3) -> Vector3:
		var it: Dictionary = _items[i]
		match str(it.kind):
			"leaves": return _lean(float(it.phase)) * local
			"cloth": return _cloth(float(it.phase), float(it.lift), float(it.yaw)) * local
		return Basis(Vector3.BACK, _angle(float(it.phase))) * local

	func _process(delta: float) -> void:
		pose(_time + delta)

	func pose(t: float) -> void:
		_time = t
		for it in _items:
			if it.kind != "clump" and wind == 0.0 and it.get("still", false):
				continue   # calm: already set at rest
			_apply(it)

	## The slow gust swell on the leaves and cloth (1 at no wind).
	func _gust(phase: float) -> float:
		return 1.0 + wind * (0.8 * sin(_time * 0.55 + phase * 0.3) + 0.4 * sin(_time * 1.7 + phase * 0.5))

	## In a wind the lean grows (1 + 1.5 x wind), the wave runs faster (1 + 0.6 x wind) and comes
	## in gusts (a slow swell on the amplitude). At wind 0 it is the calm wave it always was.
	func _angle(phase: float) -> float:
		var gust := 1.0 + wind * (0.8 * sin(_time * 0.55) + 0.4 * sin(_time * 1.7))
		var t := _time * (1.0 + 0.6 * wind)
		return AMPLITUDE * (1.0 + 1.5 * wind) * gust * (0.7 * sin(t * 1.3 + phase) + 0.3 * sin(t * 2.9 + phase * 1.7))

	## Leaves: a lean downwind (+x) with a quicker wave on it, a smaller nod across; none at 0.
	func _lean(phase: float) -> Basis:
		var t := _time * (1.4 + 0.8 * wind)
		var wave := 0.65 * sin(t * 1.9 + phase) + 0.35 * sin(t * 4.3 + phase * 1.3)
		var a := -wind * (LEAF_LEAN + LEAF_WAVE * _gust(phase) * wave)
		var nod := wind * LEAF_WAVE * 0.5 * sin(t * 2.6 + phase * 0.7)
		return Basis(Vector3.BACK, a) * Basis(Vector3.RIGHT, nod)

	## Cloth, in its own frame (x along the rod, y up, z out of the face): the drop (local -y)
	## blows out by `lift` and a flutter (never back past the face when `lift` > 0) and streams
	## downwind by a shear, as much as the rod lies across the wind (`yaw`). None at 0.
	## Cloth is light: it takes a breeze by the square root of the wind (a calm sunny day's 0.15
	## moves it like 0.39), so the festival days (always fair) still see their curtains stir.
	func _cloth(phase: float, lift: float, yaw: float) -> Basis:
		var k := sqrt(wind)
		var t := _time * (1.6 + 1.0 * wind)
		var wave := 0.6 * sin(t * 2.3 + phase) + 0.4 * sin(t * 5.1 + phase * 1.3)
		var wave2 := 0.6 * sin(t * 1.7 + phase * 0.8) + 0.4 * sin(t * 3.7 + phase * 1.9)
		var g := _gust(phase)
		var out := k * (lift + CLOTH_FLUTTER * g * wave)
		if lift > 0.0:
			out = maxf(out, 0.0)
		out = clampf(out, -0.7, 0.7)
		var stream := cos(yaw) * k * (CLOTH_STREAM + 0.15 * g * wave2)
		# A point (x, y) of the cloth (y <= 0 below the rod) goes to (x - stream y, c y, -out y).
		return Basis(Vector3.RIGHT, Vector3(-stream, sqrt(1.0 - out * out), -out), Vector3.BACK)

	func _apply(it: Dictionary) -> void:
		var yaw_b := Basis(Vector3.UP, float(it.yaw))
		if it.kind == "clump":
			var bc := Basis(Vector3.BACK, _angle(float(it.phase))) * yaw_b
			for n: Node3D in it.nodes:
				n.basis = bc
			return
		var b: Basis
		if it.kind == "cloth":   # the motion in the cloth's own frame, then turned to its face
			b = yaw_b * _cloth(float(it.phase), float(it.lift), float(it.yaw))
		else:                    # the lean is downwind in the world
			b = _lean(float(it.phase)) * yaw_b
		var xf := Transform3D(b, (it.hinge as Vector3) + b * (it.offset as Vector3))
		for n: Node3D in it.nodes:
			n.transform = xf
		it.still = wind == 0.0
