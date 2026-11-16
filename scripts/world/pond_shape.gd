class_name PondShape
extends RefCounted
## The temple pond's soft shore (2026-11-16, the user: the pond looked too square, its edge a
## straight drop): the jade water cells (legend `look: jade`) seen as one smooth shape. `field(p)`
## is the cells' squares blurred by a smoothstep of half width SOFT (a sum over the 3 x 3 cells
## round p, so it is cheap): 1 out in open water, 0 on dry land, 0.5 on the shoreline, which runs
## along a straight cell edge but rounds every corner, convex and concave, to about SOFT. Between
## SHORE and DEEP the bank slopes from the land's height down to the bed (`sink`, 0..1 of
## SunkenGround.DROP). One shape drives the 3D ground's height (SunkenGround), the ground picture
## of both views (paint: moss, earth and pebbles down the bank, grass where a corner of water is
## rounded off) and where the koi may swim (KoiPondRules). Pure: no world classes.

const SOFT := 0.6     # half width of the smoothing, cells (corners round to about this)
const SHORE := 0.5    # the field's level on the shoreline
const DEEP := 0.97    # the field's level where the bank's slope reaches the bed
const LOOK := "jade"
const T := 16

const MOSS: Array[Color] = [Color("5f7a3a"), Color("6c8a42")]
const EARTH: Array[Color] = [Color("5a4a34"), Color("4e4030")]
const PEBBLE: Array[Color] = [Color("7a766c"), Color("8e8a80")]
const WET := Color("3c3a2c")
const EDGE := Color("4f9686")   # the water's own line at the foot of the bank
const JADE := Color("3a7f72")

var cells: Dictionary = {}   # Vector2i -> true: the pond's water cells
var bounds := Rect2i()       # the cells the shape reaches (its water cells grown by one)

static var _kept: Dictionary = {}


## The pond of map `m` (its `jade` water cells), kept a run; null when it has none.
static func of(m: MapData) -> PondShape:
	if m == null:
		return null
	var id := "%s|%d|%d" % [m.id, m.tiles.hash(), m.looks.hash()]
	if not _kept.has(id):
		var s := PondShape.new()
		for y in m.h:
			for x in m.w:
				var c := Vector2i(x, y)
				if m.tile(c) == "water" and m.look(c) == LOOK:
					s.cells[c] = true
		if s.cells.is_empty():
			_kept[id] = null
		else:
			var r := Rect2i(s.cells.keys()[0], Vector2i.ONE)
			for c in s.cells:
				r = r.merge(Rect2i(c, Vector2i.ONE))
			s.bounds = r.grow(1).intersection(Rect2i(0, 0, m.w, m.h))
			_kept[id] = s
	return _kept[id]


## A shape from a set of cells (tests).
static func from_cells(water: Array[Vector2i]) -> PondShape:
	var s := PondShape.new()
	for c in water:
		s.cells[c] = true
	var r := Rect2i(water[0], Vector2i.ONE)
	for c in water:
		r = r.merge(Rect2i(c, Vector2i.ONE))
	s.bounds = r.grow(1)
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
	return clampf(sum, 0.0, 1.0)


## A unit interval's share at `t` from its start, blurred.
static func _cover(t: float) -> float:
	return smoothstep(-SOFT, SOFT, t) - smoothstep(-SOFT, SOFT, t - 1.0)


## How far down the ground lies at `p`: 0 on the land and the shoreline, 1 on the bed (times
## SunkenGround.DROP), easing down the bank between.
func sink(p: Vector2) -> float:
	return smoothstep(SHORE, DEEP, field(p))


## Whether `p` is out over the pond's flat bed (past the bank's slope).
func on_bed(p: Vector2) -> bool:
	return field(p) >= DEEP


## The ground picture over `bounds` repainted for the soft shore: `base(px)` gives the plain
## picture's pixel at a map pixel (Vector2i), `grass(px)` a grass pixel there. Over the bed the
## plain water stays; down the bank moss, then earth with pebbles, then wet earth and the water's
## line at its foot; on the land side of the shoreline the land stays, and where a water cell's
## corner is rounded off it turns to grass.
func paint(base: Callable, grass: Callable) -> Image:
	var img := Image.create(bounds.size.x * T, bounds.size.y * T, false, Image.FORMAT_RGBA8)
	var o := bounds.position * T
	for py in img.get_height():
		for px in img.get_width():
			var at := o + Vector2i(px, py)
			var p := (Vector2(at) + Vector2(0.5, 0.5)) / T
			var f := field(p)
			var water := cells.has(Vector2i(floori(p.x), floori(p.y)))
			var col: Color
			if f >= DEEP:
				col = base.call(at) if water else JADE
			elif f >= SHORE:
				col = bank_colour((f - SHORE) / (DEEP - SHORE), at)
			else:
				col = grass.call(at) if water else base.call(at)
			img.set_pixel(px, py, col)
	return img


## The bank's colour `u` of the way down (0 at the shoreline, 1 at the bed), at map pixel `at`.
static func bank_colour(u: float, at: Vector2i) -> Color:
	var h := posmod(at.x * 73 + at.y * 151 + (at.x * at.y) % 7, 97)
	if u > 0.86:
		return EDGE if u > 0.93 else WET
	if u < 0.5:   # moss over the upper bank, a pebble here and there
		return MOSS[h % 2] if h % 9 != 0 else PEBBLE[0]
	if h % 6 == 0 or h % 11 == 0:
		return PEBBLE[h % 2]
	return EARTH[h % 2]
