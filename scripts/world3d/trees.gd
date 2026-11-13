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
const NEEDLES: Array[Color] = [Color("2f5a34"), Color("3a6a3c"), Color("467a44")]
const FRUIT := Color("e8782a")
const PETAL := Color("f6c4d2")
const MAPLE_FLAME := Color("dc6a1e")   # the orange lumps among a maple's reds in fall
const LUMP_SIDES := 7

## Leaf colours of the broadleaf kinds by season; a clear colour = bare branches.
const LEAVES := {
	"persimmon": {"spring": Color("5e9a3e"), "summer": Color("4a8434"), "fall": Color("a8402c"), "winter": Color(0, 0, 0, 0)},
	# A Japanese maple (momiji): fresh light green in spring, deep green in summer, vivid red in fall.
	"maple": {"spring": Color("86b844"), "summer": Color("2f6e32"), "fall": Color("c42a1e"), "winter": Color(0, 0, 0, 0)},
	"sakura": {"spring": Color("f2bccb"), "summer": Color("4e8a3a"), "fall": Color("c8783a"), "winter": Color(0, 0, 0, 0)},
}


## A broadleaf tree of `kind` (LEAVES) in `season` ("" = spring). Persimmons carry fruit in
## fall and keep it on the bare branches in winter; a cherry in bloom drops petals round it.
## `snow` lays snow on the upper side of the bare branches (winter only).
static func broadleaf(p: FarmProps.Parts, at: Vector3, kind: String, season: String, seed: int, snow := false) -> void:
	var colours: Dictionary = LEAVES[kind]
	var leaf: Color = colours.get(season, colours.spring)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var bark := p.st(SAKURA_BARK if kind == "sakura" else BARK)
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
