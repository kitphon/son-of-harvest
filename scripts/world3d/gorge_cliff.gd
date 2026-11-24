class_name GorgeCliff
extends RefCounted
## A gorge's rock wall as one natural cliff (2026-11-24, the user: Kajika-yu's wall read as brown
## blocks; a map with "cliff": "gorge", data/maps/kajika.json). Instead of a tall box a cell
## (MapWorld._rock_wall), its rock_wall cells are one height field: the cells blurred into a soft
## mass (its edge wobbling a little, so the foot does not run straight along the cell edges), rising
## steep from the foot to an uneven top (two value noises), stepped into a few ledges, and carried on
## past the map's edges as the apron's land runs on: the wall runs on past the north edge before it
## rounds away and tapers off past the side edges, so it never ends in a cut. Its faces are lit flat
## facets toned by how they face: the steep ones bare rock in bands of strata, now and then a streak
## of moss; the ledges and the top moss and grass (snow when snow lies); a few stones lie at its
## foot. Heights in world units (a cell is 1).

const STEP := 0.25        # cells between the height field's points
const SOFT := 0.55        # the rock cells' blur (half width, cells): the foot's curve
const TOP := 2.1          # the cliff's top on average
const TOP_VARY := [0.8, 0.35]   # the top's two noises: their reach (units)
const LEDGES := 2.6       # ledges a unit of height (the strata steps)
const LEDGE_PULL := 0.45  # how far the height is pulled onto a ledge (0 smooth .. 1 hard steps)
const NORTH := [2.0, 7.0] # past the north edge: full height so far, gone by then (cells)
const SIDE := 4.0         # past the west and east edges: gone by then (cells)
const WOBBLE := 0.22      # the foot's wobble (cells)
const STRATA: Array[Color] = [Color("5c544b"), Color("6b6257"), Color("4f4841")]
const MOSS_STREAK := Color("4d5e37")
const LEDGE := Color("586b3b")
const TOP_GRASS: Array[Color] = [Color("5f7a3a"), Color("6c8a42")]
const FOOT_STONES := 0.7  # stones along the foot, a cell of it

var w := 0
var h := 0
var rocks: Dictionary = {}   # Vector2i -> true: the rock cells, on the map and carried on past its edges


## The cliff of map `m` (its rock_wall cells).
static func of(m: MapData) -> GorgeCliff:
	var g := GorgeCliff.new()
	g.w = m.w
	g.h = m.h
	for y in range(-int(NORTH[1]) - 2, m.h):
		for x in range(-int(SIDE) - 2, m.w + int(SIDE) + 2):
			var c := Vector2i(x, y)
			if m.tile(Surroundings.edge_cell(c, m.w, m.h)) == "rock_wall":
				g.rocks[c] = true
	return g


## How much rock there is at `p` (cells), 0..1: the rock cells blurred, the edge wobbling.
func field(p: Vector2) -> float:
	var cx := floori(p.x)
	var cy := floori(p.y)
	var sum := 0.0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c := Vector2i(cx + dx, cy + dy)
			if rocks.has(c):
				sum += _cover(p.x - c.x) * _cover(p.y - c.y)
	sum = clampf(sum, 0.0, 1.0)
	var wob := sin(p.x * 1.3 + 0.7) * 0.6 + sin(p.x * 3.1 + p.y * 1.7) * 0.4
	return clampf(sum + wob * WOBBLE * 4.0 * sum * (1.0 - sum), 0.0, 1.0)


static func _cover(t: float) -> float:
	return smoothstep(-SOFT, SOFT, t) - smoothstep(-SOFT, SOFT, t - 1.0)


## How far the cliff carries on at `p` past the map's edges, 1..0.
func reach(p: Vector2) -> float:
	var side := maxf(maxf(-p.x, p.x - w), 0.0)
	var north := maxf(-p.y, 0.0)
	return (1.0 - smoothstep(0.0, SIDE, side)) * (1.0 - smoothstep(float(NORTH[0]), float(NORTH[1]), north))


## The cliff's height at `p` (cells), units: 0 off the rock.
func height(p: Vector2) -> float:
	var s := smoothstep(0.28, 0.8, field(p))
	if s <= 0.0:
		return 0.0
	var top := TOP + float(TOP_VARY[0]) * (VistaRules.noise(p * 0.32 + Vector2(3.1, 7.7)) - 0.5) \
		+ float(TOP_VARY[1]) * (VistaRules.noise(p * 1.4 + Vector2(11.0, 2.0)) - 0.5)
	var hh := top * s * reach(p)
	return lerpf(hh, roundf(hh * LEDGES) / LEDGES, LEDGE_PULL * s)


## Builds the cliff into `world` (snow on its flat faces when `snowy`).
func build(world: FarmWorld, snowy: bool) -> void:
	var parts := FarmProps.Parts.new()
	var x0 := -SIDE - 0.5
	var x1 := float(w) + SIDE + 0.5
	var z0 := -float(NORTH[1]) - 0.5
	var z1 := float(_last_row()) + 2.0
	var nx := int(ceil((x1 - x0) / STEP))
	var nz := int(ceil((z1 - z0) / STEP))
	var hs := PackedFloat32Array()
	hs.resize((nx + 1) * (nz + 1))
	for j in nz + 1:
		for i in nx + 1:
			hs[j * (nx + 1) + i] = height(Vector2(x0 + i * STEP, z0 + j * STEP))
	var at := func(i: int, j: int) -> Vector3:
		return Vector3(x0 + i * STEP, hs[j * (nx + 1) + i], z0 + j * STEP)
	for j in nz:
		for i in nx:
			var a: Vector3 = at.call(i, j)
			var b: Vector3 = at.call(i + 1, j)
			var c: Vector3 = at.call(i + 1, j + 1)
			var d: Vector3 = at.call(i, j + 1)
			if maxf(maxf(a.y, b.y), maxf(c.y, d.y)) < 0.02:
				continue   # open ground: the map's own
			_facet(parts, a, c, b, snowy)
			_facet(parts, a, d, c, snowy)
	_foot_stones(parts, snowy)
	parts.commit(world)


func _last_row() -> int:
	var last := 0
	for c: Vector2i in rocks:
		last = maxi(last, c.y)
	return last


## One flat triangle, toned by how it faces (its normal turned up).
func _facet(parts: FarmProps.Parts, a: Vector3, b: Vector3, c: Vector3, snowy: bool) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.y < 0.0:
		n = -n
		var t := b
		b = c
		c = t
	var mid := (a + b + c) / 3.0
	OutdoorProps.tri(parts.st(face_key(n, mid, snowy)), a, b, c, n)


## The surface a facet facing `n` at `mid` takes: the flat ones grass (snow when snowy), the
## ledges moss, the steep ones rock in bands of strata with a streak of moss now and then.
static func face_key(n: Vector3, mid: Vector3, snowy: bool) -> Variant:
	var spot := Vector2(mid.x, mid.z)
	if n.y > 0.8 and mid.y > 0.05:
		if snowy:
			return FarmProps.Parts.SNOW
		return TOP_GRASS[int(VistaRules.noise(spot * 1.7) * 2.0) % 2]
	if n.y > 0.5:
		return SNOW if snowy and n.y > 0.65 else LEDGE
	if VistaRules.noise(spot * 2.2 + Vector2(0.0, mid.y * 1.5)) > 0.78:
		return MOSS_STREAK
	var band := int(floor(mid.y * 4.0 + VistaRules.noise(spot * 0.8) * 1.6)) % STRATA.size()
	return STRATA[band]


const SNOW := FarmProps.Parts.SNOW


## A few stones along the cliff's foot on the map (where the rock gives way to open ground).
func _foot_stones(parts: FarmProps.Parts, snowy: bool) -> void:
	var sn: SurfaceTool = parts.st(FarmProps.Parts.SNOW) if snowy else null
	var k := 0
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			if rocks.has(c) or not rocks.has(c + Vector2i.UP):
				continue
			var seed := x * 41 + y * 13
			if posmod(seed, 10) >= int(FOOT_STONES * 10.0):
				continue
			var off := VistaRules.noise(Vector2(x, y) * 3.3)
			var foot := Vector3(x + 0.25 + 0.5 * off, -0.03, y + 0.38)
			GardenProps.stone(parts, sn, foot, 0.14 + 0.1 * off, 0.12 + 0.12 * (1.0 - off), 0.12, seed + k)
			k += 1
