class_name PondShape
extends RefCounted
## The temple pond's soft shore (2026-11-16, the user: the pond looked too square, its edge a
## straight drop): the jade water cells (legend `look: jade`) seen as one smooth shape. `field(p)`
## is the cells' squares blurred by a smoothstep of half width SOFT (a sum over the 3 x 3 cells
## round p, so it is cheap): 1 out in open water, 0 on dry land, 0.5 on the shoreline, which runs
## along a straight cell edge but rounds every corner, convex and concave, to about SOFT. Between
## SHORE and DEEP the bank slopes from the land's height down to the bed (`sink`, 0..1 of
## SunkenGround.DROP). The shoreline wobbles a little (WOBBLE: a few slow waves added near the
## shore only, so the bed stays 1 and the land 0), so it does not run straight along the cell edges,
## and small stones lie along the waterline (shore_stones: GardenProps in 3D, MapView flat), as on
## a rock-edged garden pond (the user, 2026-11-16: the edge still looked unnatural). The lawn round
## the pond meets the gravel in a smooth arc too (lawn_field: the grass and water cells blurred
## wider, LAWN_SOFT, so the cells' staircase becomes one curve; only the picture, the cells walk as
## before: the user, 2026-11-16, drew the curve wanted). One shape drives the 3D ground's height (SunkenGround), the ground picture
## of both views (paint: moss, earth and pebbles down the bank, grass where a corner of water is
## rounded off) and where the koi may swim (KoiPondRules). Pure: no world classes.
## The same soft shore on the plainer ponds (2026-11-18, the user: the farm pond and Ogura pond by
## the bamboo should have a shore like the temple's, but less, so the temple keeps its own look):
## look `pond` (a map's legend, or the farm's pond: of_farm). Its water stays a natural blue-green,
## its stones are fewer and smaller (STYLES), and it has no lawn curve, garden rocks, shrubs or
## koi (those stay the temple garden's).
## Kajika-yu's hot spring (2026-11-24, the user's photo of a forest onsen): look `onsen`, milky
## turquoise water, a shore thick with stones; mossy boulders stand in and round it as map props.

const SOFT := 0.85    # half width of the smoothing, cells (corners round to about this)
const LAWN_SOFT := 1.4   # the lawn's edge against the gravel: a wider smoothing, so a staircase of cells reads as one arc
const LAWN_REACH := 3    # cells past the pond's bounds the lawn's edge is repainted
const WOBBLE := 0.16  # how much the slow waves move the field near the shore (about a fifth of a cell)
const SHORE := 0.5    # the field's level on the shoreline
const LIP := 0.07     # the bank's top stays flat this far past the shoreline, so the grass edge lies on level ground
const DEEP := 0.8     # the field's level where the bank's slope reaches the bed (a steep, narrow bank, so a two-cell arm of the pond is still deep: the user, 2026-11-16)
const LOOK := "jade"
const LOOKS: Array[String] = ["jade", "pond", "onsen"]   # the water looks laid with a soft shore, each its own shape
## A look's own touches: `water` the colour where the rounded shore runs past a water cell,
## `keep` how many in 1000 of the waterline's spots get a stone, `size` its smallest and `grow` its spread,
## `wobble` how far the shoreline's slow waves reach (times WOBBLE: the plain pond's wilder, 2026-11-18).
const STYLES := {
	"jade": {"water": Color("3a7f72"), "keep": 560, "size": 0.35, "grow": 1.0 / 1.5, "wobble": 1.0},
	"pond": {"water": Color("3d7790"), "keep": 300, "size": 0.25, "grow": 0.45, "wobble": 1.7},
	"onsen": {"water": Color("3f8a78"), "keep": 820, "size": 0.4, "grow": 0.9, "wobble": 1.4},
}
const T := 16

const MOSS: Array[Color] = [Color("5f7a3a"), Color("6c8a42")]
const EARTH: Array[Color] = [Color("5a4a34"), Color("4e4030")]
const PEBBLE: Array[Color] = [Color("7a766c"), Color("8e8a80")]
const WET := Color("3c3a2c")
const EDGE := Color("4f9686")   # the water's own line at the foot of the bank
const JADE := Color("3a7f72")
const GRASS_U := 0.42        # how far down the bank (0..1) the grass runs before the moss and earth
const STONE_LEVEL := 0.68    # the field's level the shore stones sit on (down the bank, at the waterline)
const STONE_STEP := 0.2      # cells between the points tried along it
const STONE_GAP := 0.42      # cells at least between two stones
## How far round a garden rock's cell centre no small stone lies, by its shape (the rest ROCK_CLEAR):
## the small stones crowding a big rock's foot read as spiky clutter (the user, 2026-11-28, Kajika-yu's west shore).
const ROCK_CLEAR := 0.9
const ROCK_CLEAR_SHAPES := {"boulder": 1.8, "granite": 1.6}
## How far round a path cell's centre by the hot spring no small stone lies: the way in where the
## path meets the water stays open (2026-11-28, the user: the stones there filled the soak view's foreground).
const PATH_CLEAR := 1.3
const REFLECT := Color("1d4a36")   # the wood's green mirrored in the hot spring near its far banks
const REFLECT_REACH := 2.2   # cells out from the far banks the mirrored wood reaches
const REFLECT_MOST := 0.55   # how far the water takes its colour right under the bank

var look := LOOK             # the water's look (LOOKS): the jade temple pond or a plain one
var cells: Dictionary = {}   # Vector2i -> true: the pond's water cells
var bounds := Rect2i()       # the cells the shape reaches (its water cells grown by one)
var picture := Rect2i()      # the cells the repainted picture covers (bounds and the lawn's edge round it)
var lawn: Dictionary = {}    # Vector2i -> true: grass or water cells (the lawn) near the pond
var swaps: Dictionary = {}   # Vector2i -> its tile: grass and gravel cells in `picture` whose picture follows the lawn's curve
var rocks: Array = []        # [centre (cells), clear reach (cells)]: the hot spring's garden rocks, no small stone at their foot
var paths: Array[Vector2] = []   # the centres of the path cells by the hot spring (no small stone near: PATH_CLEAR)
var _stones: Array = []      # shore_stones, worked out once

static var _kept: Dictionary = {}


## The pond of map `m` with water look `look` (its water cells of that look), kept a run; null
## when it has none. The plain `jade` one is the temple's (the koi swim in it).
static func of(m: MapData, look := LOOK) -> PondShape:
	if m == null:
		return null
	var id := "%s|%d|%d|%s" % [m.id, m.tiles.hash(), m.looks.hash(), look]
	if not _kept.has(id):
		var s := PondShape.new()
		s.look = look
		for y in m.h:
			for x in m.w:
				var c := Vector2i(x, y)
				if m.tile(c) == "water" and m.look(c) == look:
					s.cells[c] = true
		if s.cells.is_empty():
			_kept[id] = null
		else:
			for pr in m.props if look == "onsen" else []:   # the hot spring's big rocks (the temple pond keeps its stones as they were)
				if str(pr.get("kind", "")) == "garden_rock":
					var shift: Array = pr.get("offset", [0, 0])
					var at := Vector2(pr.cell) + Vector2(0.5, 0.5) + Vector2(float(shift[0]), float(shift[1]))
					s.rocks.append([at, float(ROCK_CLEAR_SHAPES.get(str(pr.get("shape", "")), ROCK_CLEAR))])
			var r := Rect2i(s.cells.keys()[0], Vector2i.ONE)
			for c in s.cells:
				r = r.merge(Rect2i(c, Vector2i.ONE))
			s.bounds = r.grow(1).intersection(Rect2i(0, 0, m.w, m.h))
			s.picture = s.bounds
			_kept[id] = s
			if look == "onsen":   # the path cells by it (after the bounds: they are what it looks round)
				var by := s.bounds.grow(2)
				for y in range(by.position.y, by.end.y):
					for x in range(by.position.x, by.end.x):
						if m.in_bounds(Vector2i(x, y)) and m.tile(Vector2i(x, y)) == "path":
							s.paths.append(Vector2(x, y) + Vector2(0.5, 0.5))
			if look != LOOK:   # the lawn's curve against the gravel is the temple garden's only
				return s
			s.picture = s.bounds.grow(LAWN_REACH).intersection(Rect2i(0, 0, m.w, m.h))
			var near := s.picture.grow(2)
			for y in range(near.position.y, near.end.y):
				for x in range(near.position.x, near.end.x):
					var c := Vector2i(x, y)
					var tile := m.tile(c) if m.in_bounds(c) else ""
					if tile == "grass" or tile == "water":
						s.lawn[c] = true
					if s.picture.has_point(c) and (tile == "grass" or tile == "gravel"):
						s.swaps[c] = tile
	return _kept[id]


## Every soft pond on map `m` (one a look of LOOKS that it has), the temple's first.
static func all_of(m: MapData) -> Array[PondShape]:
	var out: Array[PondShape] = []
	for look in LOOKS:
		var s := of(m, look)
		if s != null:
			out.append(s)
	return out


## The farm's pond (FarmGrid's `pond` cells) as a plain soft pond, kept a run; null when the farm
## has none (the greenhouse's grid).
static func of_farm(farm: FarmGrid) -> PondShape:
	if farm == null:
		return null
	var water: Array[Vector2i] = []
	for c in farm.fixed:
		if farm.fixed[c] == "pond":
			water.append(c)
	if water.is_empty():
		return null
	water.sort()
	var id := "farm|%d|%d|%s" % [farm.w, farm.h, str(water).hash()]
	if not _kept.has(id):
		var s := from_cells(water, "pond")
		s.bounds = s.bounds.intersection(Rect2i(0, 0, farm.w, farm.h))
		s.picture = s.bounds
		_kept[id] = s
	return _kept[id]


## The colour of open water where the rounded shore runs past a water cell (STYLES).
func water_colour() -> Color:
	return STYLES[look].water


## A shape from a set of cells (tests).
static func from_cells(water: Array[Vector2i], with_look := LOOK) -> PondShape:
	var s := PondShape.new()
	s.look = with_look
	for c in water:
		s.cells[c] = true
	var r := Rect2i(water[0], Vector2i.ONE)
	for c in water:
		r = r.merge(Rect2i(c, Vector2i.ONE))
	s.bounds = r.grow(1)
	s.picture = s.bounds
	return s


## How much water there is at `p` (cells), 0..1 (see the class note).
func field(p: Vector2) -> float:
	var cx := floori(p.x)
	var cy := floori(p.y)
	var sum := 0.0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c := Vector2i(cx + dx, cy + dy)
			if cells.has(c):
				sum += _cover(p.x - c.x) * _cover(p.y - c.y)
	sum = clampf(sum, 0.0, 1.0)
	return clampf(sum + wobble(p) * float(STYLES[look].wobble) * 4.0 * sum * (1.0 - sum), 0.0, 1.0)


## A few slow waves over the map (cells), -WOBBLE..WOBBLE: the shoreline's bays and points.
static func wobble(p: Vector2) -> float:
	var w := sin(p.x * 1.7 + p.y * 0.6 + 0.4) * 0.5 + sin(p.y * 2.3 - p.x * 0.9 + 1.9) * 0.35 + sin((p.x + p.y) * 4.1 + 0.7) * 0.15
	return WOBBLE * w


## How much lawn there is at `p` (cells), 0..1: the grass and water cells blurred by LAWN_SOFT, with
## a little of the wobble; 0.5 is the lawn's edge against the gravel.
func lawn_field(p: Vector2) -> float:
	var cx := floori(p.x)
	var cy := floori(p.y)
	var sum := 0.0
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var c := Vector2i(cx + dx, cy + dy)
			if lawn.has(c):
				sum += _cover_by(p.x - c.x, LAWN_SOFT) * _cover_by(p.y - c.y, LAWN_SOFT)
	sum = clampf(sum, 0.0, 1.0)
	return clampf(sum + wobble(p * 0.6) * 2.0 * sum * (1.0 - sum), 0.0, 1.0)


static func _cover_by(t: float, soft: float) -> float:
	return smoothstep(-soft, soft, t) - smoothstep(-soft, soft, t - 1.0)


## A unit interval's share at `t` from its start, blurred.
static func _cover(t: float) -> float:
	return smoothstep(-SOFT, SOFT, t) - smoothstep(-SOFT, SOFT, t - 1.0)


## How far down the ground lies at `p`: 0 on the land, the shoreline and the bank's lip (LIP), 1
## on the bed (times SunkenGround.DROP), easing down the bank between.
func sink(p: Vector2) -> float:
	return smoothstep(SHORE + LIP, DEEP, field(p))


## Whether `p` is out over the pond's flat bed (past the bank's slope).
func on_bed(p: Vector2) -> bool:
	return field(p) >= DEEP


## The ground picture over `picture` repainted for the soft shore: `base(px)` gives the plain
## picture's pixel at a map pixel (Vector2i), `grass(px)` a grass pixel there. Over the bed the
## plain water stays; the land's own grass runs on over the bank's top, darkening as it goes down
## (GRASS_U of the way, no dither, so the grass edge reads as one smooth curve: the user,
## 2026-11-16, saw square blocks there), then moss, earth with pebbles, wet earth and the water's
## line at its foot; on the land side of the shoreline the land stays, and where a water cell's
## corner is rounded off it turns to grass.
func paint(base: Callable, grass: Callable, gravel := Callable()) -> Image:
	var img := Image.create(picture.size.x * T, picture.size.y * T, false, Image.FORMAT_RGBA8)
	var o := picture.position * T
	# The land's picture at a map pixel: a grass or gravel cell by the lawn's curve, else as it is.
	var land_at := func(at: Vector2i, q: Vector2) -> Color:
		var cell := Vector2i(floori(q.x), floori(q.y))
		if not swaps.has(cell) or not gravel.is_valid():
			return base.call(at)
		var want := "grass" if lawn_field(q) >= 0.5 else "gravel"
		if want == swaps[cell]:
			return base.call(at)
		return grass.call(at) if want == "grass" else gravel.call(at)
	for py in img.get_height():
		for px in img.get_width():
			var at := o + Vector2i(px, py)
			var p := (Vector2(at) + Vector2(0.5, 0.5)) / T
			var f := field(p)
			var water := cells.has(Vector2i(floori(p.x), floori(p.y)))
			var col: Color
			if f >= DEEP:
				col = base.call(at) if water else water_colour()
				if look == "onsen":
					col = col.lerp(REFLECT, reflection(p))
			elif f >= SHORE:
				var u := (f - SHORE) / (DEEP - SHORE)
				var edge := GRASS_U + _soft_noise(at) * 0.12   # where the grass gives way, a gentle wave
				if u < edge:   # the grass going over the bank's top, darker the further down
					var land: Color = grass.call(at) if water else land_at.call(at, p)
					col = land.darkened(0.28 * u / edge)
				else:
					col = bank_colour((u - edge) / (1.0 - edge), at)
			else:
				col = grass.call(at) if water else land_at.call(at, p)
			img.set_pixel(px, py, col)
	return img


## The bank's colour `u` of the way down below the grass (0 at the grass's foot, 1 at the bed),
## at map pixel `at`: moss in soft patches, then earth with pebbles, wet earth and the water's
## line at the foot; the borders follow a smooth noise (whole patches, not single pixels).
static func bank_colour(u: float, at: Vector2i) -> Color:
	var h := posmod(at.x * 73 + at.y * 151 + (at.x * at.y) % 7, 97)
	var n := _soft_noise(at)
	var v := u + n * 0.2
	if u > 0.88:
		return EDGE if u > 0.94 else WET
	if v > 0.82:
		return WET
	if v < 0.32:   # moss next to the grass, two shades in patches
		return MOSS[1] if n > 0.1 else MOSS[0]
	if h % 7 == 0 or h % 13 == 0:
		return PEBBLE[h % 2]
	return EARTH[0] if n > -0.2 else EARTH[1]


## A smooth noise over the map's pixels, -1..1 (slow waves: patches several pixels across).
static func _soft_noise(at: Vector2i) -> float:
	return sin(at.x * 0.45 + at.y * 0.21) * 0.5 + sin(at.y * 0.53 - at.x * 0.17) * 0.5


## Small stones along the waterline: {pos: Vector2 (cells), size: 0..1, seed}. Points every
## STONE_STEP cells over the shape where the field crosses STONE_LEVEL, kept by a hash of the spot
## (a little over half of them) and at least STONE_GAP apart, none at a garden rock's foot (rocks,
## ROCK_CLEAR) nor where a path meets the hot spring (paths, PATH_CLEAR). Worked out once.
func shore_stones() -> Array:
	if not _stones.is_empty() or cells.is_empty():
		return _stones
	var steps := int(1.0 / STONE_STEP)
	for y in range(bounds.position.y * steps, bounds.end.y * steps):
		for x in range(bounds.position.x * steps, bounds.end.x * steps):
			var p := Vector2(x, y) * STONE_STEP
			var f := field(p)
			if absf(f - STONE_LEVEL) > 0.07:
				continue
			var h := posmod(x * 7919 + y * 104729, 1000)
			if h > int(STYLES[look].keep):
				continue
			var close := false
			for rk in rocks:
				if (rk[0] as Vector2).distance_to(p) < float(rk[1]):
					close = true
					break
			for c in paths:
				if c.distance_to(p) < PATH_CLEAR:
					close = true
					break
			for st in _stones:
				if (st.pos as Vector2).distance_to(p) < STONE_GAP:
					close = true
					break
			if not close:
				_stones.append({"pos": p, "size": float(STYLES[look].size) + (h % 100) / 100.0 * float(STYLES[look].grow), "seed": h})
	return _stones


## How much of the wood is mirrored in the water at `p` (0..REFLECT_MOST): near the far banks, north
## and west of it (the side the play camera looks toward, where the trees stand over the water: the
## user's photos), fading out over REFLECT_REACH cells, a little along the near banks too.
func reflection(p: Vector2) -> float:
	var far := 0.0
	for k in 4:
		var d := REFLECT_REACH * (k + 1) / 4.0
		var back := minf(field(p + Vector2(0, -d)), field(p + Vector2(-d, 0)))
		if back < SHORE:
			far = maxf(far, 1.0 - d / (REFLECT_REACH + 0.4))
	var near := 0.0
	for o in [Vector2(0, 0.8), Vector2(0.8, 0)]:
		if field(p + o) < SHORE:
			near = 0.35
	return clampf(maxf(far, near), 0.0, 1.0) * REFLECT_MOST
