class_name Trees
extends RefCounted
## Trees as stylized low-poly meshes, lit so the sun shapes them: broadleaf trees with a crown
## of several faceted lumps (darker below, lighter on top) on a trunk with limbs, by season
## (blossom, green, red / gold, bare branches in winter, persimmons hanging on into the
## snow), and pines of flat layered pads of needles, snow lying on the pads in winter. A bare
## broadleaf takes snow on the upper side of its limbs and twigs when `snow` is asked (SnowLayer's
## top shader shows how much, as it does on the pads). Built
## into a FarmProps.Parts round `at` (the foot of the trunk); `seed` varies the shape so a
## row of trees never repeats. 1 unit = 1 cell; a crown reaches about 0.8 round and 2.1 up.

const BARK := Color("4a3428")
const SAKURA_BARK := Color("3e302c")
const GINKGO_BARK := Color("6a5a4c")   # the ginkgo's paler grey-brown bark
const GINKGO_LEAF := Color("eec02a")   # its fallen leaves, a gold carpet round its foot in fall
const NEEDLES: Array[Color] = [Color("2f5a34"), Color("3a6a3c"), Color("467a44")]
const FRUIT := Color("e8782a")
const PETAL := Color("f6c4d2")
const MAPLE_FLAME := Color("dc6a1e")   # the orange lumps among a maple's reds in fall
const MAPLE_AMBER := Color("e0a028")   # the amber low and inside a maple's crown in fall
const MAPLE_NEW := Color("b0583a")     # a maple's red-bronze new leaves among the spring green
const LUMP_SIDES := 7

## Leaf colours of the broadleaf kinds by season; a clear colour = bare branches.
const LEAVES := {
	"persimmon": {"spring": Color("5e9a3e"), "summer": Color("4a8434"), "fall": Color("a8402c"), "winter": Color(0, 0, 0, 0)},
	# A Japanese maple (momiji): fresh light green in spring, deep green in summer, vivid red in fall.
	"maple": {"spring": Color("86b844"), "summer": Color("2f6e32"), "fall": Color("c42a1e"), "winter": Color(0, 0, 0, 0)},
	"sakura": {"spring": Color("f2bccb"), "summer": Color("4e8a3a"), "fall": Color("c4562e"), "winter": Color(0, 0, 0, 0)},
	# A Japanese ginkgo (icho): fresh yellow-green in spring, mid green in summer, bright gold in fall.
	"ginkgo": {"spring": Color("9cc84a"), "summer": Color("4f8a32"), "fall": Color("f0c020"), "winter": Color(0, 0, 0, 0)},
}


## A broadleaf tree of `kind` (LEAVES) in `season` ("" = spring). Persimmons carry fruit in
## fall and keep it on the bare branches in winter; a cherry in bloom drops petals round it.
## `snow` lays snow on the upper side of the bare branches (winter only).
static func broadleaf(p: FarmProps.Parts, at: Vector3, kind: String, season: String, seed: int, snow := false) -> void:
	var colours: Dictionary = LEAVES[kind]
	var leaf: Color = colours.get(season, colours.spring)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var bark := p.st(bark_of(kind))
	Shrine.lathe(bark, at, [Vector2(0.13, 0.0), Vector2(0.1, 0.12), Vector2(0.085, 0.7), Vector2(0.065, 1.2)], 6)
	var bare := leaf.a == 0.0
	var fruit := kind == "persimmon" and season in ["fall", "winter"]
	var snow_st: SurfaceTool = p.st(FarmProps.Parts.SNOW) if snow and bare else null
	var ends: Array[Vector3] = []   # where the bare twigs end (fruit hangs there in winter)
	var limbs := 5 if bare else 3
	var turn := rng.randf() * TAU
	for i in limbs:
		var yaw := turn + TAU * i / limbs + rng.randf_range(-0.3, 0.3)
		var tilt := rng.randf_range(0.55, 0.85)
		var base := at + Vector3(0, rng.randf_range(0.85, 1.1), 0)
		var long := rng.randf_range(0.55, 0.72) if bare else 0.45
		var dir := _dir(yaw, tilt)
		_limb(bark, base, dir, long, 0.045)
		if not bare:
			continue
		if snow_st:
			_branch_snow(snow_st, base, dir, long, 0.045)
		var tip := base + dir * long
		ends.append(tip)
		for side in [-1.0, 1.0]:   # two twigs off each limb
			var from := base + dir * long * 0.6
			var twig := _dir(yaw + side * 0.6, tilt - 0.25 * side + 0.1)
			_limb(bark, from, twig, 0.3, 0.025)
			if snow_st:
				_branch_snow(snow_st, from, twig, 0.3, 0.025)
			ends.append(from + twig * 0.3)
	if bare:
		if fruit:
			for e in ends:
				if rng.randf() < 0.6:
					_lump(p.st(FRUIT), e + Vector3(0, -0.07, 0), 0.055, 1.0, 6)
		return
	if kind == "maple":
		_maple_crown(p, at, leaf, season, rng, turn)
		return
	# The crown: a big lump in the middle, four round it a little lower, one on top.
	var lumps: Array = [[Vector3(0, 1.5, 0), 0.5, leaf]]
	for i in 4:
		var a := turn + TAU * i / 4 + rng.randf_range(-0.35, 0.35)
		var d := rng.randf_range(0.34, 0.42)
		var shade := leaf.darkened(0.14) if i % 2 == 0 else leaf.darkened(0.06)
		lumps.append([Vector3(cos(a) * d, rng.randf_range(1.3, 1.5), sin(a) * d), rng.randf_range(0.33, 0.4), shade])
	lumps.append([Vector3(rng.randf_range(-0.1, 0.1), 1.86, rng.randf_range(-0.1, 0.1)), 0.34, leaf.lightened(0.12)])
	for l in lumps:
		_lump(p.st(l[2]), at + l[0], l[1], 0.82, LUMP_SIDES, rng.randf() * TAU)
	if fruit:
		for l in lumps.slice(1, 5):
			var c: Vector3 = l[0]
			var out := Vector3(c.x, 0, c.z).normalized()
			_lump(p.st(FRUIT), at + c + out * float(l[1]) * 0.92 + Vector3(0, -0.05, 0), 0.06, 1.0, 6)
	if kind == "sakura" and season in ["", "spring"]:
		fallen_petals(p, at, seed)


## A maple's crown: small and layered, a wide flat tier of five low lumps, a narrower tier of
## three above it and a cap, so it reads as stacked sprays of leaves. In fall some lumps turn
## orange among the reds.
static func _maple_crown(p: FarmProps.Parts, at: Vector3, leaf: Color, season: String, rng: RandomNumberGenerator, turn: float) -> void:
	var lumps: Array = []
	for i in 5:
		var a := turn + TAU * i / 5 + rng.randf_range(-0.25, 0.25)
		var d := rng.randf_range(0.36, 0.44)
		lumps.append([Vector3(cos(a) * d, rng.randf_range(1.22, 1.34), sin(a) * d), rng.randf_range(0.3, 0.35), 0.58, leaf.darkened(0.16 if i % 2 == 0 else 0.08)])
	for i in 3:
		var a := turn + 0.6 + TAU * i / 3 + rng.randf_range(-0.2, 0.2)
		var d := rng.randf_range(0.14, 0.2)
		lumps.append([Vector3(cos(a) * d, rng.randf_range(1.5, 1.6), sin(a) * d), rng.randf_range(0.28, 0.32), 0.6, leaf.darkened(0.03)])
	lumps.append([Vector3(rng.randf_range(-0.05, 0.05), 1.78, rng.randf_range(-0.05, 0.05)), 0.26, 0.7, leaf.lightened(0.1)])
	lumps.append([Vector3(0, 1.45, 0), 0.34, 0.7, leaf])
	for i in lumps.size():
		var c: Color = lumps[i][3]
		if season == "fall" and i in [1, 4, 6]:
			c = MAPLE_FLAME.darkened(0.04 * (i % 3))
		_lump(p.st(c), at + lumps[i][0], lumps[i][1], lumps[i][2], LUMP_SIDES, rng.randf() * TAU)


## Petals lying round a cherry in bloom.
static func fallen_petals(p: FarmProps.Parts, at: Vector3, seed: int) -> void:
	var petal := p.st(PETAL)
	for i in 12:
		var a := i * 2.4 + seed
		var d := 0.25 + (i % 4) * 0.17
		var c := at + Vector3(cos(a) * d, 0, sin(a) * d)
		FarmProps.block(petal, Rect2(c.x - 0.035, c.z - 0.035, 0.07, 0.07), 0.002, Rect2(c.x - 0.035, c.z - 0.035, 0.07, 0.07), 0.01)


## A pine: a trunk and flat pads of needles in tiers, the lower ones wider, darker. A
## `garden` pine leans and sets its pads off to alternate sides (a village pine); otherwise
## it stands straight with the pads stacked (the wood). `snow` adds a snow cover on each pad's
## top (SnowLayer's top shader shows it as the cover grows).
static func pine(p: FarmProps.Parts, at: Vector3, seed: int, garden: bool, snow: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var lean := _lean(rng, garden)
	var tiers := [[0.55, 0.62], [0.88, 0.5], [1.2, 0.38], [1.5, 0.26]]
	var top := 1.75
	var bark := p.st(BARK)
	_limb(bark, at, lean, top, 0.13, 0.04)
	var side := rng.randf() * TAU
	for i in tiers.size():
		var y: float = tiers[i][0]
		var r: float = tiers[i][1] * rng.randf_range(0.92, 1.08)
		var c := at + lean * y
		if garden and i < tiers.size() - 1:
			var off := Vector3(cos(side + PI * i), 0, sin(side + PI * i)) * 0.16
			_limb(bark, c - Vector3(0, 0.08, 0), (off + Vector3(0, 0.12, 0)).normalized(), off.length() * 1.2, 0.03)
			c += off
		var green: Color = NEEDLES[[0, 1, 1, 2][i]]
		var yaw := rng.randf() * TAU
		_pad(p.st(green), c, r, yaw)
		if snow:
			_pad_snow(p.st(FarmProps.Parts.SNOW), c, r, yaw)


## The way a pine of `seed` leans (a unit vector; a `garden` pine leans more): the cicadas on its
## trunk sit along it (CicadaRules.scene_of).
static func pine_lean(seed: int, garden: bool) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return _lean(rng, garden)


## A pine's lean from its first two draws of `rng` (pine and pine_lean share it).
static func _lean(rng: RandomNumberGenerator, garden: bool) -> Vector3:
	return _dir(rng.randf() * TAU, rng.randf_range(0.08, 0.16) if garden else rng.randf_range(0.0, 0.04))


## A tier of needles of radius r, its foot at `c`: a low cone, the edge drooping a little.
static func _pad(st: SurfaceTool, c: Vector3, r: float, yaw: float) -> void:
	var profile := [Vector2(r * 0.3, 0.0), Vector2(r, 0.06), Vector2(r * 0.75, 0.18), Vector2(r * 0.25, 0.36), Vector2(0.0, 0.42)]
	RoomProps._placed(st, Transform3D(Basis(Vector3.UP, yaw), c), func(t: SurfaceTool) -> void: Shrine.lathe(t, Vector3.ZERO, profile, LUMP_SIDES))


## The snow on a pad: a skin a hair over its upper faces.
static func _pad_snow(st: SurfaceTool, c: Vector3, r: float, yaw: float) -> void:
	var profile := [Vector2(r * 0.78, 0.186), Vector2(r * 0.27, 0.366), Vector2(0.0, 0.428)]
	RoomProps._placed(st, Transform3D(Basis(Vector3.UP, yaw), c), func(t: SurfaceTool) -> void: Shrine.lathe(t, Vector3.ZERO, profile, LUMP_SIDES))


## A faceted lump of leaves (or a fruit) of radius `r` round `c`, `squash` its height share.
static func _lump(st: SurfaceTool, c: Vector3, r: float, squash: float, sides: int, yaw := 0.0) -> void:
	var k := r * squash
	var profile := [Vector2(r * 0.5, 0.0), Vector2(r * 0.92, k * 0.3), Vector2(r, k * 0.75), Vector2(r * 0.85, k * 1.2),
		Vector2(r * 0.45, k * 1.55), Vector2(0.0, k * 1.7)]
	RoomProps._placed(st, Transform3D(Basis(Vector3.UP, yaw), c - Vector3(0, k * 0.85, 0)),
		func(t: SurfaceTool) -> void: Shrine.lathe(t, Vector3.ZERO, profile, sides))


## Snow lying on the upper side of a bare limb or twig made by `_limb` (the same `base`, `dir`,
## `long` and `thick`; the tip is half as thick): one thin sheet a little wider than the wood,
## lifted just off its top, from a tenth of the way along to nearly the end. Its normal is the
## limb's up (world up turned off the limb), so it is lit like the pads' snow.
static func _branch_snow(st: SurfaceTool, base: Vector3, dir: Vector3, long: float, thick: float) -> void:
	var up := Vector3.UP - dir * dir.y
	if up.length() < 0.05:
		return
	up = up.normalized()
	var side := dir.cross(up).normalized()
	var flat := func(q: Vector3) -> Vector2: return Vector2(q.x, q.z)
	var rows: Array = []
	for s: float in [0.1, 0.95]:
		var half: float = lerpf(thick, thick * 0.5, s) * 0.5   # the limb's half-width there (_limb)
		var top: Vector3 = base + dir * long * s + up * (half + 0.008)
		rows.append([top - side * half * 1.3, top + side * half * 1.3])
	Minka.quad(st, rows[0][0], rows[0][1], rows[1][1], rows[1][0], up, flat)


## A tapering limb from `base` along `dir` (a unit vector), `long` units, `thick` across at its
## foot and `tip` at its end.
static func _limb(st: SurfaceTool, base: Vector3, dir: Vector3, long: float, thick: float, tip := -1.0) -> void:
	var end := thick * 0.5 if tip < 0.0 else tip
	var basis := Basis(Quaternion(Vector3.UP, dir)) if dir.cross(Vector3.UP).length() > 0.0001 else Basis.IDENTITY
	var lo := Rect2(-thick / 2, -thick / 2, thick, thick)
	var hi := Rect2(-end / 2, -end / 2, end, end)
	RoomProps._placed(st, Transform3D(basis, base), func(t: SurfaceTool) -> void: FarmProps.block(t, lo, 0.0, hi, long))


## The unit vector `tilt` radians off straight up, leaning towards `yaw` round y.
static func _dir(yaw: float, tilt: float) -> Vector3:
	return Vector3(cos(yaw) * sin(tilt), cos(tilt), sin(yaw) * sin(tilt))


## --- Grand swaying crowns (2026-11-17) -------------------------------------------------------
## The cherries, maples and ginkgos in leaf (or in bloom) are built as a trunk with spreading limbs and a
## crown of separate sprays, each its own mesh that the world's Sway rocks about the fork it grows
## from (OutdoorProps.Sway "crown": a gentle stir even in a calm, more in a wind, every spray on its
## own beat), so the crown seems to rustle. The sprays carry their colours on the vertices, every
## facet toned a little apart (lighter where it faces up), and the cherry's are dotted with small
## white-pink florets, the summer crowns with light new leaves, the fall ones with gold and orange:
## a pattern of leaves and flowers instead of flat lumps. The cherry is grand: seven limbs spreading
## wide in two rings, a spray of blossom at the end of each and one on top, about 1.45 round and 2.95 up, petals
## under it far round. The trunk below 1.2 is the old one's (the cicadas cling to it). A few shapes
## per kind and season (CROWN_SHAPES) are built once and shared, each tree turned by its seed.
## Bare (winter) trees and the persimmon keep broadleaf.

const CROWN_SHAPES := 6
const CROWN_KINDS: Array[String] = ["sakura", "maple", "ginkgo"]
const FLORET := Color("fff2f6")       # the small open flowers dotted over a cherry in bloom
const BLOSSOM_DEEP := Color("e898b0")  # the deeper pink of the buds under a cherry's sprays
const CHERRY_GOLD := Color("d89a3c")   # the gold sprays among a cherry's orange-brown in fall
const LEAF_TILE := 2.0   # cells a leaf tile (FoliageArt, 32 texels) covers on a crown: 16 texels a cell
const BLOOM := Color("fff0f4")   # a cherry in bloom's sprays: the pale tint its flower tile is laid over
const LIMBS := 7   # a grand cherry's limbs, each ending in a spray (every other one rising steeper)
static var _crowns := {}   # "kind|season|shape" -> {trunk: {key: ArrayMesh}, sprays: [{mesh: ArrayMesh, hinge: Vector3}]}


## Whether a `kind` tree in `season` is built with a swaying crown (place_crowned).
static func crowned(kind: String, season: String) -> bool:
	if not kind in CROWN_KINDS:
		return false
	var colours: Dictionary = LEAVES[kind]
	return (colours.get(season if season != "" else "spring", colours.spring) as Color).a > 0.0


## A tree's crown shape and turn by its seed.
static func crown_shape(seed: int) -> int:
	return posmod(seed * 7 + 3, CROWN_SHAPES)


static func crown_yaw(seed: int) -> float:
	return fposmod(seed * 0.618, 1.0) * TAU


## The built pieces of a `kind` tree in `season` of `shape` (tree-local: the trunk's foot at
## the origin): {trunk: {Parts key: ArrayMesh}, sprays: [{mesh, hinge}]}, each spray's mesh
## round its hinge (the fork it sways about). Built once and kept.
static func crown_of(kind: String, season: String, shape: int) -> Dictionary:
	var s := season if season != "" else "spring"
	var key := "%s|%s|%d" % [kind, s, shape]
	if not _crowns.has(key):
		_crowns[key] = _build_crown(kind, s, shape)
	return _crowns[key]


## Places a crowned tree (crowned() true) with its foot at `at` into `w`: the trunk's meshes in
## their materials, then each spray as a mesh of vertex colours, all turned by the seed's yaw,
## the sprays handed to the world's Sway; `scale` sizes the whole tree (a map prop's `scale`: small,
## middling and big trees mixed). Returns the spray nodes.
static func place_crowned(w: FarmWorld, at: Vector3, kind: String, season: String, seed: int, scale := 1.0) -> Array:
	var made := crown_of(kind, season, crown_shape(seed))
	var yaw := crown_yaw(seed)
	var turn := Basis(Vector3.UP, yaw).scaled(Vector3(scale, scale, scale))
	var sway := OutdoorProps._sway(w)
	for key in made.trunk:
		var mi := MeshInstance3D.new()
		mi.mesh = made.trunk[key]
		mi.material_override = FarmProps.Parts.material(key, w._snow_mats)
		mi.transform = Transform3D(turn, at)
		if not FarmProps.Parts.casts_shadow(key) or (key is Color and (key == PETAL or key == GINKGO_LEAF)):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.add_child(mi)
	var nodes: Array = []
	var sprays: Array = made.sprays
	for i in sprays.size():
		var mi := MeshInstance3D.new()
		mi.mesh = sprays[i].mesh
		mi.material_override = leaf_material(kind, season)
		var hinge: Vector3 = at + turn * (sprays[i].hinge as Vector3)
		mi.transform = Transform3D(turn, hinge)
		mi.set_meta("crown", true)   # a tree's spray (not a bamboo clump: test_maps tells them apart)
		w.add_child(mi)
		sway.add_crown([mi], hinge, yaw, seed * 0.71 + i * 1.93, scale)
		nodes.append(mi)
	return nodes


static func _build_crown(kind: String, season: String, shape: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind) + shape * 7919 + 17
	var leaf: Color = LEAVES[kind][season]
	var p := FarmProps.Parts.new()
	var bark := p.st(bark_of(kind))
	if kind == "maple":   # a short trunk that splits low into stems (_maple_sprays)
		Shrine.lathe(bark, Vector3.ZERO, [Vector2(0.12, 0.0), Vector2(0.095, 0.12), Vector2(0.085, 0.62)], 6)
	else:
		Shrine.lathe(bark, Vector3.ZERO, [Vector2(0.13, 0.0), Vector2(0.1, 0.12), Vector2(0.085, 0.7), Vector2(0.065, 1.2)], 6)
	var sprays: Array = []
	if kind == "sakura":
		_sakura_sprays(p, bark, sprays, leaf, season, rng)
	elif kind == "ginkgo":
		_ginkgo_sprays(p, bark, sprays, leaf, season, rng)
	else:
		_maple_sprays(bark, sprays, leaf, season, rng)
	var out := []
	for s: Dictionary in sprays:
		out.append({"mesh": (s.st as SurfaceTool).commit(), "hinge": s.hinge})
	return {"trunk": p.meshes(), "sprays": out}


## The grand cherry: seven limbs from 1.0-1.2 up, every other one leaning well out (a low wide ring)
## and the rest rising steeper (a higher ring), each forking once, a spray at each limb's end
## (seven lumps of blossom; the low ring's with two small deeper ones hanging under), one more big
## spray over the trunk; petals lying far round its foot in spring.
static func _sakura_sprays(p: FarmProps.Parts, bark: SurfaceTool, sprays: Array, leaf: Color, season: String, rng: RandomNumberGenerator) -> void:
	if season == "spring":
		leaf = BLOOM   # in bloom the flower tile carries the pinks: the sprays are its pale tint
	var turn := rng.randf() * TAU
	for i in LIMBS:
		var yaw := turn + TAU * i / LIMBS + rng.randf_range(-0.2, 0.2)
		var tilt := rng.randf_range(0.9, 1.2) if i % 2 == 0 else rng.randf_range(0.6, 0.8)   # every other limb rises steeper: a second, higher ring
		var base := Vector3(0, rng.randf_range(1.0, 1.2), 0)
		var long := rng.randf_range(0.74, 0.86) if i % 2 == 0 else rng.randf_range(0.7, 0.8)
		var dir := _dir(yaw, tilt)
		_limb(bark, base, dir, long, 0.09, 0.04)
		var fork := base + dir * long * 0.5
		var twig := _dir(yaw + (0.55 if i % 2 == 0 else -0.55), tilt - 0.35)
		_limb(bark, fork, twig, 0.4, 0.045, 0.02)
		var tip := base + dir * long
		var centre := tip + Vector3(0, 0.24, 0) + Vector3(cos(yaw), 0, sin(yaw)) * 0.05
		sprays.append(_spray(centre, fork, leaf, season, rng, rng.randf_range(0.33, 0.37), 6, i % 2 == 0))
	var top := Vector3(rng.randf_range(-0.05, 0.05), 2.45, rng.randf_range(-0.05, 0.05))
	_limb(bark, Vector3(0, 1.15, 0), (top - Vector3(0, 1.15, 0)).normalized(), 1.1, 0.07, 0.03)
	sprays.append(_spray(top, Vector3(0, 1.3, 0), leaf, season, rng, 0.42, 7, false))
	if season == "spring":
		var petal := p.st(PETAL)
		for i in 34:
			var a := i * 2.4 + rng.randf()
			var d := 0.25 + (i % 7) * 0.18
			var c := Vector3(cos(a) * d, 0, sin(a) * d)
			FarmProps.block(petal, Rect2(c.x - 0.035, c.z - 0.035, 0.07, 0.07), 0.002, Rect2(c.x - 0.035, c.z - 0.035, 0.07, 0.07), 0.01)


## A Japanese maple as it grows: a short trunk splitting at 0.55 into three stems leaning out, each
## forking into two limbs that run out nearly level, so the crown is a wide low umbrella (about 1.15
## round, 2.1 up), broader than it is tall. Its leaves lie in thin flat layers along the limbs, an
## outer pad near each tip and a higher one further in, with gaps between them where the limbs show,
## the pads' edges ragged with small leaf clusters, a few drooping; one more pad on top. Each limb's
## pads are one spray swaying about its fork. The colours run as on a real tree: in fall crimson at
## the top and the outside, fading through orange to amber low and inside; in spring fresh green with
## red-bronze new leaves among it; in summer deep green, darker inside.
static func _maple_sprays(bark: SurfaceTool, sprays: Array, leaf: Color, season: String, rng: RandomNumberGenerator) -> void:
	var turn := rng.randf() * TAU
	var base := Vector3(0, 0.55, 0)
	for s in 3:
		var sy := turn + TAU * s / 3.0 + rng.randf_range(-0.3, 0.3)
		var sdir := _dir(sy, rng.randf_range(0.3, 0.48))
		var slong := rng.randf_range(0.55, 0.68)
		_limb(bark, base, sdir, slong, 0.075, 0.05)
		var fork := base + sdir * slong
		for side in [-1.0, 1.0]:
			var ldir := _dir(sy + side * rng.randf_range(0.35, 0.6), rng.randf_range(1.05, 1.3))
			var llong := rng.randf_range(0.38, 0.5)
			_limb(bark, fork, ldir, llong, 0.045, 0.018)
			var st := _spray_tool()
			var outer := fork + ldir * llong * 0.95 + Vector3(0, 0.1, 0)
			var inner := fork + ldir * llong * 0.45 + Vector3(0, 0.32, 0)
			_maple_pad(st, outer - fork, outer, rng.randf_range(0.3, 0.34), leaf, season, rng)
			_maple_pad(st, inner - fork, inner, rng.randf_range(0.24, 0.28), leaf, season, rng)
			sprays.append({"st": st, "hinge": fork})
	var top := _spray_tool()
	var hinge := Vector3(0, 1.3, 0)
	var crown := Vector3(rng.randf_range(-0.06, 0.06), 1.88, rng.randf_range(-0.06, 0.06))
	_limb(bark, base, (crown - base).normalized(), (crown - base).length() * 0.85, 0.05, 0.02)
	_maple_pad(top, crown - hinge, crown, 0.3, leaf, season, rng)
	sprays.append({"st": top, "hinge": hinge})


## A maple's layer of leaves round `c` (`world` its place in the tree, for its colour): a thin flat
## middle and four lobes round it, ragged at the edge with small leaf clusters, a few hanging lower.
static func _maple_pad(st: SurfaceTool, c: Vector3, world: Vector3, r: float, leaf: Color, season: String, rng: RandomNumberGenerator) -> void:
	_leafy_lump(st, c, r, 0.36, _maple_tone(leaf, season, world, rng), rng)
	var turn := rng.randf() * TAU
	for i in 4:
		var a := turn + TAU * i / 4.0 + rng.randf_range(-0.3, 0.3)
		var at := c + Vector3(cos(a), 0, sin(a)) * r * rng.randf_range(0.55, 0.7) + Vector3(0, rng.randf_range(-0.04, 0.04), 0)
		_leafy_lump(st, at, r * rng.randf_range(0.5, 0.62), 0.42, _maple_tone(leaf, season, world + (at - c), rng), rng)
	for i in 10:   # the ragged edge: small clusters round the rim, every third hanging lower
		var a := rng.randf() * TAU
		var at := c + Vector3(cos(a), 0, sin(a)) * r * rng.randf_range(0.95, 1.2) + Vector3(0, -0.05 - (0.07 if i % 3 == 0 else 0.0), 0)
		_coloured_lump(st, at, rng.randf_range(0.05, 0.075), 0.7, 5, rng.randf() * TAU, _maple_tone(leaf, season, world + (at - c), rng), 0.0, rng)


## A maple leaf cluster's colour at `at` (tree-local): fall runs from amber low and inside through
## orange to the season's crimson at the top and the outside; spring is fresh green with a share of
## red-bronze new leaves; summer is deep green, darker inside.
static func _maple_tone(leaf: Color, season: String, at: Vector3, rng: RandomNumberGenerator) -> Color:
	var high := clampf((at.y - 1.2) / 0.75, 0.0, 1.0)
	var out := clampf(Vector2(at.x, at.z).length() / 1.0, 0.0, 1.0)
	var t := clampf(0.55 * high + 0.45 * out + rng.randf_range(-0.15, 0.15), 0.0, 1.0)
	match season:
		"fall":   # mostly crimson: orange and amber only low and inside
			var f := clampf(0.3 + t, 0.0, 1.0)
			if f < 0.45:
				return MAPLE_AMBER.lerp(MAPLE_FLAME, f / 0.45)
			return MAPLE_FLAME.lerp(leaf, clampf((f - 0.45) / 0.35, 0.0, 1.0))
		"spring":
			return MAPLE_NEW if rng.randf() < 0.18 else leaf.darkened(0.1 * (1.0 - t))
	return leaf.darkened(0.16 * (1.0 - t))


## A ginkgo: tall and upright, its leader running on up from the trunk to 2.7, short limbs off it
## and its crown an upright oval of sprays in tiers (four low and wide, three in the middle, two
## near the top, one on it), about 0.95 round and 3.2 up; in fall a gold carpet of fallen leaves
## round its foot.
static func _ginkgo_sprays(p: FarmProps.Parts, bark: SurfaceTool, sprays: Array, leaf: Color, season: String, rng: RandomNumberGenerator) -> void:
	_limb(bark, Vector3(0, 1.15, 0), Vector3.UP, 1.55, 0.065, 0.025)
	var turn := rng.randf() * TAU
	# [count, height, out, lump radius]
	for tier in [[4, 1.45, 0.42, 0.3], [3, 1.95, 0.34, 0.28], [2, 2.45, 0.22, 0.25]]:
		for i in int(tier[0]):
			var a: float = turn + TAU * i / float(tier[0]) + rng.randf_range(-0.25, 0.25) + float(tier[1])
			var out := Vector3(cos(a), 0, sin(a))
			var fork := Vector3(0, float(tier[1]) - 0.25, 0)
			var centre := fork + out * float(tier[2]) + Vector3(0, 0.22, 0)
			_limb(bark, fork, (centre - fork).normalized(), (centre - fork).length() * 0.8, 0.035, 0.015)
			var st := _spray_tool()
			var r: float = float(tier[3]) * rng.randf_range(0.92, 1.08)
			_leafy_lump(st, centre - fork, r, 0.95, leaf.darkened(0.1 if i % 2 == 0 else 0.03), rng)
			_leafy_lump(st, centre - fork + out * r * 0.5 + Vector3(0, r * 0.3, 0), r * 0.72, 0.95, leaf, rng)
			_leafy_lump(st, centre - fork - out * r * 0.2 + Vector3(0, -r * 0.45, 0), r * 0.6, 0.9, leaf.darkened(0.14), rng)
			_dots(st, centre - fork, r * 1.05, leaf, season, rng, 5)
			sprays.append({"st": st, "hinge": fork})
	var top := _spray_tool()
	var hinge := Vector3(0, 2.45, 0)
	_leafy_lump(top, Vector3(0, 0.42, 0), 0.22, 1.1, leaf.lightened(0.08), rng)
	_dots(top, Vector3(0, 0.45, 0), 0.22, leaf, season, rng, 3)
	sprays.append({"st": top, "hinge": hinge})
	if season == "fall":
		var fallen := p.st(GINKGO_LEAF)
		for i in 48:
			var a := i * 2.4 + rng.randf()
			var d := 0.2 + (i % 8) * 0.1
			var c := Vector3(cos(a) * d, 0, sin(a) * d)
			var s := rng.randf_range(0.06, 0.1)
			FarmProps.block(fallen, Rect2(c.x - s / 2, c.z - s / 2, s, s), 0.002, Rect2(c.x - s / 2, c.z - s / 2, s, s), 0.012)


## The material of a `kind` tree's sprays in `season`: their vertex colours times the leaf or blossom
## tile (FoliageArt) at LEAF_TILE, the texels kept sharp. A new one each
## call (each tree fades on its own: Occluders).
static func leaf_material(kind: String, season: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.albedo_texture = PlaceholderArt.tex("foliage:%s:%s" % [kind, season if season != "" else "spring"])
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST   # crisp pixels, as the rest of the game (mipmaps blurred the leaves away)
	return m


## A kind's bark colour.
static func bark_of(kind: String) -> Color:
	match kind:
		"sakura": return SAKURA_BARK
		"ginkgo": return GINKGO_BARK
	return BARK


static func _spray_tool() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


## A cherry's spray round `centre`, built round `hinge`: a big lump of radius `r`, `ring` lumps
## round it a little lower (every other one darker; some gold in fall), two small deeper ones
## hanging under it when `hang`, and its florets or new leaves dotted over the top.
static func _spray(centre: Vector3, hinge: Vector3, leaf: Color, season: String, rng: RandomNumberGenerator, r: float, ring: int, hang: bool) -> Dictionary:
	var st := _spray_tool()
	var c := centre - hinge
	_leafy_lump(st, c, r, 0.78, leaf, rng)
	var turn := rng.randf() * TAU
	for i in ring:
		var a := turn + TAU * i / ring + rng.randf_range(-0.3, 0.3)
		var d := r * rng.randf_range(0.75, 0.95)
		var shade := leaf.darkened(0.12 if i % 2 == 0 else 0.05)
		if season == "fall" and i % 3 == 1:
			shade = CHERRY_GOLD
		_leafy_lump(st, c + Vector3(cos(a) * d, rng.randf_range(-0.12, 0.04), sin(a) * d), r * rng.randf_range(0.62, 0.78), 0.72, shade, rng)
	if hang:
		for i in 2:
			var a := turn + PI * i + 0.6
			var deep := BLOSSOM_DEEP if season == "spring" else leaf.darkened(0.22)
			_leafy_lump(st, c + Vector3(cos(a) * r * 0.55, -r * 0.62, sin(a) * r * 0.55), r * 0.42, 0.9, deep, rng)
	_dots(st, c, r * 1.05, leaf, season, rng, 9)
	return {"st": st, "hinge": hinge}


## Small dots over the upper side of a spray round `c` (reach `r`): florets on a cherry in bloom,
## light new leaves in summer, gold and orange in fall (none on a maple in spring: its new
## leaves are light already).
static func _dots(st: SurfaceTool, c: Vector3, r: float, leaf: Color, season: String, rng: RandomNumberGenerator, count: int) -> void:
	var tones: Array[Color] = []
	match season:
		"spring":
			if leaf == LEAVES.sakura.spring or leaf == BLOOM:
				tones = [FLORET, Color("fbdce6")]
		"summer": tones = [leaf.lightened(0.28), leaf.lightened(0.18)]
		"fall":
			if leaf == LEAVES.ginkgo.fall:   # paler and deeper golds over a ginkgo
				tones = [Color("ffe066"), Color("e0a010")]
			else:
				tones = [Color("e8b040"), Color("e07a28"), leaf.lightened(0.2)]
	if tones.is_empty():
		return
	for i in count:
		var a := rng.randf() * TAU
		var up := rng.randf_range(0.25, 0.85)   # how far up the dome
		var d := Vector3(cos(a) * sqrt(1.0 - up * up), up, sin(a) * sqrt(1.0 - up * up))
		_coloured_lump(st, c + d * r, rng.randf_range(0.055, 0.08), 1.0, 5, rng.randf() * TAU, tones[i % tones.size()], 0.0, rng)


## A lump of leaves (_lump's shape) laid straight into a vertex-colour SurfaceTool, each facet
## its own tone round `col` (a little lighter or darker by chance, lighter facing up), so the
## crown reads as leaves and blossom instead of one flat colour.
static func _leafy_lump(st: SurfaceTool, c: Vector3, r: float, squash: float, col: Color, rng: RandomNumberGenerator) -> void:
	_coloured_lump(st, c, r, squash, LUMP_SIDES, rng.randf() * TAU, col, 0.07, rng)


static func _coloured_lump(st: SurfaceTool, c: Vector3, r: float, squash: float, sides: int, yaw: float, col: Color, jitter: float, rng: RandomNumberGenerator) -> void:
	var k := r * squash
	var profile := [Vector2(r * 0.5, 0.0), Vector2(r * 0.92, k * 0.3), Vector2(r, k * 0.75), Vector2(r * 0.85, k * 1.2),
		Vector2(r * 0.45, k * 1.55), Vector2(0.0, k * 1.7)]
	var tmp := SurfaceTool.new()
	tmp.begin(Mesh.PRIMITIVE_TRIANGLES)
	Shrine.lathe(tmp, Vector3.ZERO, profile, sides)
	var arr := tmp.commit_to_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var xf := Transform3D(Basis(Vector3.UP, yaw), c - Vector3(0, k * 0.85, 0))
	for i in range(0, v.size(), 3):
		var face := col
		if jitter > 0.0:
			var t := rng.randf_range(-jitter, jitter) + (0.06 if n[i].y > 0.6 else 0.0)
			face = col.lightened(t) if t > 0.0 else col.darkened(-t)
		st.set_color(face)
		# The leaf tile (FoliageArt) laid on the facet from the side it faces most: its UVs are the
		# spray's own coordinates on the other two axes, LEAF_TILE cells a tile.
		var fn := xf.basis * n[i]
		var axis := 0 if absf(fn.x) >= absf(fn.y) and absf(fn.x) >= absf(fn.z) else (1 if absf(fn.y) >= absf(fn.z) else 2)
		for j in 3:
			var q := xf * v[i + j]
			var uv := Vector2(q.z, q.y) if axis == 0 else (Vector2(q.x, q.z) if axis == 1 else Vector2(q.x, q.y))
			st.set_uv(uv / LEAF_TILE)
			st.set_normal(xf.basis * n[i + j])
			st.add_vertex(q)
