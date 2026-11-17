class_name FoliageArt
extends RefCounted
## The leaves and blossom painted on the trees' crowns (2026-11-17: the user wanted to see the leaves
## and the cherry's flowers, not plain lumps). One 32 x 32 tile a kind and season that repeats
## seamlessly, laid on the crowns' sprays at 16 texels a cell (Trees: a texel is a little over a screen
## pixel at the play camera, so a leaf or a flower is five or six pixels across). The 3D crowns
## multiply it by their vertex colours: so the leaf tiles are grey (a lit leaf 1.0, its vein and
## shaded side a little less, the gaps between leaves darker, GAP), and the colour stays the tree's own
## (a maple's crimson outside and amber inside, a ginkgo's gold). The cherry in bloom's tile is in
## colour over a pale blossom tint: five-petalled flowers with deep pink hearts, buds, deep pink gaps
## and now and then a dark twig. Leaves and flowers are strewn on a jittered grid, each over the last,
## so they pile like real foliage. The flat view stamps the same tiles onto its tree pictures
## (stamp). PlaceholderArt "foliage:<kind>:<season>".

const SIZE := 32
const GAP := 0.6   # the dark between leaves (a leaf tile)

# A maple leaf: five points, the stalk below. "X" leaf, "v" the vein down its middle.
const MAPLE := [
	"..X..",
	"X.X.X",
	"XXvXX",
	".XvX.",
	"..v..",
]
# A cherry leaf (summer, fall): a pointed oval, leaning.
const CHERRY_LEAF := [
	"..X",
	".XX",
	"XvX",
	"XX.",
	"X..",
]
# A ginkgo leaf: a fan on a stalk.
const GINKGO := [
	"XXXXX",
	"XXvXX",
	".XvX.",
	"..v..",
]
# A cherry flower: five petals round a deep pink heart. "W" petal lit, "w" petal shaded, "c" heart.
const FLOWER := [
	".W.W.",
	"WWwWW",
	".wcw.",
	"WwWwW",
	".W.w.",
]

const PETAL := Color(1.0, 1.0, 1.0)
const PETAL_SHADE := Color(0.98, 0.84, 0.9)
const HEART := Color(0.84, 0.3, 0.48)
const BUD := Color(0.93, 0.56, 0.68)
const BLOOM_GAP := Color(0.8, 0.52, 0.66)
const TWIG := Color(0.5, 0.36, 0.38)


## The tile for `kind` in `season` (an Image, 32 x 32, opaque).
static func make(kind: String, season: String) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind + season)
	if kind == "sakura" and season == "spring":
		_bloom(img, rng)
	else:
		var shape: Array = MAPLE
		if kind == "sakura":
			shape = CHERRY_LEAF
		elif kind == "ginkgo":
			shape = GINKGO
		_leaves(img, rng, shape, 3)
	return img


## Grey leaves of `shape` strewn over the tile every `step` texels, each turned one of four ways and lit from the upper
## left (its upper-left half 1.0, the rest 0.86, the vein 0.74), over the dark gaps.
static func _leaves(img: Image, rng: RandomNumberGenerator, shape: Array, step: int) -> void:
	img.fill(Color(GAP, GAP, GAP))
	for gy in range(0, SIZE, step):
		for gx in range(0, SIZE, step):
			var at := Vector2i(gx + rng.randi_range(-1, 1), gy + rng.randi_range(-1, 1))
			var turn := rng.randi_range(0, 3)
			var dim := rng.randf_range(0.0, 0.12)   # some leaves further in, a little darker
			_stamp(img, shape, at, turn, func(ch: String, x: int, y: int) -> Color:
				var v := 0.78 if ch == "v" else (1.0 if x + y < 4 else 0.86)
				v -= dim
				return Color(v, v, v))


## Cherry blossom: flowers on a jittered grid over deep pink gaps, a bud here and there, a dark
## twig now and then.
static func _bloom(img: Image, rng: RandomNumberGenerator) -> void:
	img.fill(BLOOM_GAP)
	for i in 6:   # a few dark twigs under the flowers
		var p := Vector2i(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		for k in 3:
			img.set_pixelv(Vector2i(posmod(p.x + k, SIZE), posmod(p.y + (k if i % 2 == 0 else -k), SIZE)), TWIG)
	for gy in range(0, SIZE, 5):
		for gx in range(0, SIZE, 5):
			var at := Vector2i(gx + rng.randi_range(-1, 1) + (2 if (gy / 5) % 2 == 1 else 0), gy + rng.randi_range(-1, 1))
			if rng.randf() < 0.15:   # a bud
				for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
					img.set_pixelv(Vector2i(posmod(at.x + 2 + o.x, SIZE), posmod(at.y + 2 + o.y, SIZE)), BUD)
				continue
			_stamp(img, FLOWER, at, rng.randi_range(0, 1) * 2, func(ch: String, _x: int, _y: int) -> Color:
				match ch:
					"c": return HEART
					"w": return PETAL_SHADE
				return PETAL)


## A leaf tuft for the crowns' ragged edges (Trees: cut-out cards sticking out of the clumps), EDGE x
## EDGE, clear round it: three leaves of the kind's shape (grey, as the tiles) or, for a cherry in
## bloom, two flowers and a bud in colour. PlaceholderArt "foliage_edge:<kind>:<season>".
const EDGE := 8


static func edge(kind: String, season: String) -> Image:
	var img := Image.create(EDGE, EDGE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if kind == "sakura" and season == "spring":
		var petals := func(ch: String, _x: int, _y: int) -> Color:
			match ch:
				"c": return HEART
				"w": return PETAL_SHADE
			return PETAL
		_stamp(img, FLOWER, Vector2i(0, 0), 0, petals, false)
		_stamp(img, FLOWER, Vector2i(3, 3), 2, petals, false)
		for o in [Vector2i(6, 0), Vector2i(7, 0), Vector2i(6, 1), Vector2i(7, 1)]:
			img.set_pixelv(o, BUD)
		return img
	var shape: Array = MAPLE
	if kind == "sakura":
		shape = CHERRY_LEAF
	elif kind == "ginkgo":
		shape = GINKGO
	var grey := func(ch: String, x: int, y: int) -> Color:
		var v := 0.78 if ch == "v" else (1.0 if x + y < 4 else 0.86)
		return Color(v, v, v)
	_stamp(img, shape, Vector2i(0, 2), 3, grey, false)
	_stamp(img, shape, Vector2i(3, 3), 1, grey, false)
	_stamp(img, shape, Vector2i(2, 0), 0, grey, false)
	return img


## Lays `shape` (rows of characters, "." clear) with its corner at `at`, turned `turn` quarter turns,
## wrapping round the tile's edges (`wrap`, else cut off at them); `colour` gives each pixel's colour
## from its character and place.
static func _stamp(img: Image, shape: Array, at: Vector2i, turn: int, colour: Callable, wrap := true) -> void:
	var h := shape.size()
	var w := (shape[0] as String).length()
	for y in h:
		for x in w:
			var ch := (shape[y] as String)[x]
			if ch == ".":
				continue
			var q := Vector2i(x, y)
			match turn:
				1: q = Vector2i(h - 1 - y, x)
				2: q = Vector2i(w - 1 - x, h - 1 - y)
				3: q = Vector2i(y, w - 1 - x)
			var p := at + q
			if wrap:
				p = Vector2i(posmod(p.x, img.get_width()), posmod(p.y, img.get_height()))
			elif p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
				continue
			img.set_pixelv(p, colour.call(ch, x, y))


## Stamps the tile of `kind` in `season` onto a flat tree picture's crown: every pixel that was crown
## in `before` (the picture before ItemArt toned it: not clear, not `bark`, not in `keep`) takes the
## tile's pattern: a leaf tile darkens the gaps and veins (multiplied), the bloom tile lays its
## flowers, hearts and buds over the pink.
static func stamp(img: Image, before: Image, kind: String, season: String, bark: Color, keep: Array = []) -> void:
	var tile := PlaceholderArt.image("foliage:%s:%s" % [kind, season])
	var bloom := kind == "sakura" and season == "spring"
	for y in img.get_height():
		for x in img.get_width():
			var b := before.get_pixel(x, y)
			if b.a < 0.5 or b.is_equal_approx(bark) or keep.any(func(k: Color) -> bool: return b.is_equal_approx(k)):
				continue
			var c := img.get_pixel(x, y)
			var t := tile.get_pixel(x % SIZE, y % SIZE)
			if bloom:
				if t.is_equal_approx(PETAL) or t.is_equal_approx(PETAL_SHADE):
					img.set_pixel(x, y, Color(1.0, 0.96, 0.97).lerp(c, 0.25 if t.is_equal_approx(PETAL) else 0.45))
				elif t.is_equal_approx(HEART) or t.is_equal_approx(BUD):
					img.set_pixel(x, y, t)
				elif t.is_equal_approx(TWIG):
					img.set_pixel(x, y, c.darkened(0.3))
				continue
			var k := clampf(t.r / 0.9, 0.7, 1.1)   # the tile's light against a plain leaf
			img.set_pixel(x, y, Color(clampf(c.r * k, 0, 1), clampf(c.g * k, 0, 1), clampf(c.b * k, 0, 1), c.a))
