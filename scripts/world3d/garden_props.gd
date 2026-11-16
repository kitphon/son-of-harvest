class_name GardenProps
extends RefCounted
## The temple garden's pond-side pieces (2026-11-15, after the user's photos of a Zen temple's
## pond garden): garden rocks set in and round the water, and clipped round shrubs (karikomi) on
## the mossy banks. The flat view draws them in MapView._draw_garden.
##  - `garden_rock` (map prop, `shape`): "tall" a standing stone with a small one at its foot,
##    "flat" a wide low slab, "low" a rounded stone and a pebble, "pair" a big stone with two
##    smaller ones against it (a little island in the water). Grey granite, darker low down, moss
##    on some upper facets; out in the water it stands on the sunk bed (SunkenGround.DROP), so its
##    foot is under the water's skin. Snow on the upper facets when it lies.
##  - `shrub`: a clipped mound of small leaves, faceted, lighter on top; in spring (days 16-30)
##    and the first days of summer the azalea's pink flowers dot it, in fall a few leaves redden,
##    in winter it is darker and snow lies on its top.

const KINDS := GardenLook.KINDS
const SHAPES := GardenLook.SHAPES
const STONE := GardenLook.STONE
const LEAF := GardenLook.LEAF
const LEAF_WINTER := GardenLook.LEAF_WINTER
const BLOOM := GardenLook.BLOOM
const FALL_RED := GardenLook.FALL_RED


## Builds prop `p` (garden_rock / shrub) of map `map` into `w`, centred at `mid` (y 0: the land).
static func prop(w: FarmWorld, p: Dictionary, mid: Vector3, map: MapData, season: String, day: int, snow: bool) -> void:
	var cell := Vector2i(p.cell)
	var wet := map.tile(cell) == "water"
	var seed := cell.x * 31 + cell.y * 17
	match str(p.kind):
		"garden_rock":
			# Out in the water it stands on the bed there: the pond's own depth at its spot (PondShape's slope), else the full drop.
			var pond := PondShape.of(map)
			var sink := (pond.sink(Vector2(mid.x, mid.z)) if pond != null and pond.cells.has(cell) else 1.0) if wet else 0.0
			rock(w, str(p.get("shape", "low")), mid + Vector3(0, -SunkenGround.DROP * sink, 0), SunkenGround.DROP * sink, seed, snow)
		"shrub": shrub(w, Rect2(Vector2(p.cell), Vector2(p.size)), season, day, seed, snow)


## A garden rock of `shape` standing at `foot` (its base), `under` deep in the water (that much
## taller, to show as much above the skin): rounded stones, worn smooth (pebble), never a point.
static func rock(w: FarmWorld, shape: String, foot: Vector3, under: float, seed: int, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var sn: SurfaceTool = null
	var snow_parts: FarmProps.Parts = null
	if snow:
		snow_parts = FarmProps.Parts.new()
		sn = snow_parts.st(FarmProps.Parts.SNOW)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var off := Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.08, 0.08))
	match shape:
		"tall":   # an upright stone, rounded on top
			pebble(p, sn, foot + off, 0.27, 0.56 + under, 0.22, seed + 1)
			pebble(p, sn, foot + off + Vector3(0.24, 0, 0.16), 0.15, 0.16 + under, 0.13, seed + 2)
		"flat":
			pebble(p, sn, foot + off, 0.42, 0.15 + under, 0.34, seed + 1)
		"pair":   # a little island of three
			pebble(p, sn, foot + off + Vector3(-0.08, 0, -0.05), 0.31, 0.36 + under, 0.27, seed + 1)
			pebble(p, sn, foot + off + Vector3(0.23, 0, 0.12), 0.21, 0.22 + under, 0.18, seed + 2)
			pebble(p, sn, foot + off + Vector3(-0.27, 0, 0.22), 0.15, 0.13 + under, 0.13, seed + 3)
		_:   # low
			pebble(p, sn, foot + off, 0.33, 0.26 + under, 0.28, seed + 1)
			pebble(p, sn, foot + off + Vector3(0.25, 0, -0.18), 0.13, 0.09 + under, 0.11, seed + 2)
	p.commit(w)
	if snow_parts != null:
		snow_parts.commit(w)


## A rounded stone at `at` (its foot), `rx` x `rz` wide and `h` high: rings swelling out above the
## foot and closing over a low dome (no apex point), a little uneven; dark low down, lighter up,
## moss on some top facets, snow on the upward ones (`sn`, or null).
static func pebble(p: FarmProps.Parts, sn: SurfaceTool, at: Vector3, rx: float, h: float, rz: float, seed: int) -> void:
	const SIDES := 10
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var rings := [[0.0, 0.88], [0.32, 1.0], [0.62, 0.94], [0.84, 0.7], [0.96, 0.36]]
	var phase := rng.randf() * TAU
	var rows: Array = []
	for ring in rings:
		var row: Array[Vector3] = []
		for k in SIDES:
			var a := phase + TAU * k / SIDES
			var rr: float = float(ring[1]) * (1.0 + rng.randf_range(-0.06, 0.06))
			row.append(at + Vector3(cos(a) * rx * rr, h * float(ring[0]), sin(a) * rz * rr))
		rows.append(row)
	var top := at + Vector3(0, h, 0)
	var centre := at + Vector3(0, h * 0.4, 0)
	var facet := func(a: Vector3, b: Vector3, c: Vector3, tone: int) -> void:
		var n := (b - a).cross(c - a).normalized()
		if n.dot((a + b + c) / 3.0 - centre) < 0.0:
			n = -n
		var col: Color = STONE[tone]
		if tone == 2 and rng.randf() < 0.3:
			col = GardenLook.MOSS
		var j := 1.0 + rng.randf_range(-0.05, 0.05)
		OutdoorProps.tri(p.st(Color(col.r * j, col.g * j, col.b * j)), a, b, c, n)
		if sn != null and n.y > 0.45:
			var lift := Vector3(0, 0.012, 0)
			OutdoorProps.tri(sn, a + lift, b + lift, c + lift, Vector3.UP)
	for ri in rows.size() - 1:
		var tone := 0 if ri == 0 else (1 if ri < 3 else 2)
		for k in SIDES:
			var k2 := (k + 1) % SIDES
			facet.call(rows[ri][k], rows[ri][k2], rows[ri + 1][k2], tone)
			facet.call(rows[ri][k], rows[ri + 1][k2], rows[ri + 1][k], tone)
	for k in SIDES:
		facet.call(rows[4][k], rows[4][(k + 1) % SIDES], top, 2)


## Whether a shrub flowers on day `day` of `season` (GardenLook.blooms).
static func blooms(season: String, day: int) -> bool:
	return GardenLook.blooms(season, day)


## A clipped round shrub over `r` (cells): a faceted mound a little narrower than its footprint.
static func shrub(w: FarmWorld, r: Rect2, season: String, day: int, seed: int, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var tones := LEAF_WINTER if season == "winter" else LEAF
	var c := r.get_center()
	var rx := r.size.x * 0.42
	var rz := r.size.y * 0.4
	var h := 0.42 + rng.randf_range(-0.04, 0.05)
	const SIDES := 10
	# rings from the foot up: [height share, radius share]
	var rings := [[0.0, 0.86], [0.3, 1.0], [0.62, 0.9], [0.88, 0.55]]
	var rows: Array = []
	for ring in rings:
		var row: Array[Vector3] = []
		for k in SIDES:
			var a := TAU * k / SIDES
			var rr: float = float(ring[1]) * (1.0 + rng.randf_range(-0.05, 0.05))
			row.append(Vector3(c.x + cos(a) * rx * rr, h * float(ring[0]), c.y + sin(a) * rz * rr))
		rows.append(row)
	var apex := Vector3(c.x, h, c.y)
	var bloom := blooms(season, day)
	var sn: SurfaceTool = p.st(FarmProps.Parts.SNOW) if snow else null
	var facet := func(a: Vector3, b: Vector3, cc: Vector3, tone: int) -> void:
		var n := (b - a).cross(cc - a).normalized()
		if n.dot((a + b + cc) / 3.0 - Vector3(c.x, h * 0.35, c.y)) < 0.0:
			n = -n
		var col: Color = tones[tone]
		var roll := rng.randf()
		if bloom and tone > 0 and roll < 0.35:
			col = BLOOM
		elif season == "fall" and tone > 0 and roll < 0.2:
			col = FALL_RED
		var j := 1.0 + rng.randf_range(-0.06, 0.06)
		OutdoorProps.tri(p.st(Color(col.r * j, col.g * j, col.b * j)), a, b, cc, n)
		if sn != null and n.y > 0.5:
			var lift := Vector3(0, 0.012, 0)
			OutdoorProps.tri(sn, a + lift, b + lift, cc + lift, Vector3.UP)
	for ri in rows.size() - 1:
		for k in SIDES:
			var k2 := (k + 1) % SIDES
			facet.call(rows[ri][k], rows[ri][k2], rows[ri + 1][k2], mini(ri, 2))
			facet.call(rows[ri][k], rows[ri + 1][k2], rows[ri + 1][k], mini(ri, 2))
	for k in SIDES:
		facet.call(rows[3][k], rows[3][(k + 1) % SIDES], apex, 2)
	p.commit(w)
