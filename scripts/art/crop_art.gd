class_name CropArt
extends RefCounted
## The field's single-sprite crops (turnip, onion, carrot, daikon, potato, eggplant, pumpkin: every
## look whose shape is not a CropClusters plant) drawn part by part, 16 x 16, our own designs.
## Every part is a small shaded shape in three tones (shade, base, lit) with the light from the
## upper left, as the figures are; the rim round the whole silhouette is a deep shade of the
## leaf (a little of the produce's colour once ripe), not the black outline. Same keys, size and
## anchor as before: `crop:<id>:<growth 0..3>:<ripe|growing>`, the plant standing on row 14 and
## the rim on the last row. Growth 0 is the seed, 1 the sprout (these two for every crop, the
## tall ones too), 2 young, 3 grown, ripe at 3 with the produce showing. Palettes: data/crop_art.json.

const PATH := "res://data/crop_art.json"
const SIZE := 16
const GROUND := 14                      # the plant's foot row; the row below holds the rim
const LIT_AT := 0.38                    # a shape's brightness above this takes the lit tone
const SHADE_AT := -0.05                 # ... and below this the shade tone

static var _data := {}
## True while drawing only the produce (tests read its lighting); leaves, vines and soil are left out.
static var _po := false


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _data


## The shade, base and lit tones of a colour.
static func tones(c: Color) -> Array:
	var t: Dictionary = data().tone
	var mix: float = t.tint_mix
	return [c.darkened(t.shade).lerp(Color(t.shade_tint), mix), c, c.lightened(t.lit).lerp(Color(t.lit_tint), mix)]


## True for the looks CropArt draws at every growth (the others it draws only as seed and sprout).
static func draws_grown(shape: String) -> bool:
	return shape != "vine" and shape != "stalk" and shape != "grain"


## The picture of crop `id` at `growth` (0..3). `produce_only` leaves out the leaves, vines and soil.
static func draw(id: String, growth: int, ripe: bool, produce_only := false) -> Image:
	_po = produce_only
	var look := PlaceholderArt.crop_look(id)
	var shape: String = look.get("shape", "bush")
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var leaf := Color(look.get("leaf", "5f9e3a"))
	var fruit := Color(look.get("fruit", "e8a23a"))
	var lt := tones(leaf)
	if growth == 0:
		_seed(img, id)
	elif growth == 1:
		_sprout(img, look, lt)
	else:
		match shape:
			"root":
				_root(img, look, growth, ripe, lt)
			"ground":
				_ground(img, id, look, growth, ripe, lt)
			_:
				_bush(img, id, look, growth, ripe, lt)
	_po = false
	if produce_only:
		return img
	var d: Dictionary = data()
	var rim := leaf.darkened(d.rim)
	if ripe:
		rim = rim.lerp(fruit.darkened(d.rim), d.rim_fruit_mix)
	return _rim(img, rim)


# ---- the pieces ----

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < SIZE and y < SIZE:
		img.set_pixel(x, y, c)


## A shaded ball: three tones by how the light meets it (offset from the middle in half-widths:
## up and left is bright). `top` tones take the rows above `top_y` (a turnip's purple crown).
## `spec` puts a paler pixel on the lit shoulder.
static func _ball(img: Image, cx: float, cy: float, rx: float, ry: float, t: Array,
		top: Array = [], top_y := -99.0, spec := false) -> void:
	for y in range(floori(cy - ry), ceili(cy + ry) + 1):
		for x in range(floori(cx - rx), ceili(cx + rx) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny > 1.0:
				continue
			var b := -nx * 0.5 - ny * 0.7 + 0.35 * sqrt(1.0 - nx * nx - ny * ny)
			var set: Array = top if (not top.is_empty() and y + 0.5 < top_y) else t
			_px(img, x, y, set[2] if b > LIT_AT else (set[0] if b < SHADE_AT else set[1]))
	if spec:
		var sx := clampi(roundi(cx - rx * 0.4), 0, SIZE - 1)
		var sy := clampi(roundi(cy - ry * 0.45), 0, SIZE - 1)
		if img.get_pixel(sx, sy).a > 0:
			_px(img, sx, sy, (t[2] as Color).lightened(0.3))


## A leaf blob (a bush's mass, a gourd leaf): the ball, unless only the produce is drawn.
static func _blob(img: Image, cx: float, cy: float, rx: float, ry: float, t: Array) -> void:
	if not _po:
		_ball(img, cx, cy, rx, ry, t)


## A leaf from `a` (the foot) to `b` (the tip), widest near the first third, `w` wide at most.
## Its side towards the light takes the lit tone, the far side the shade.
static func _leaf(img: Image, a: Vector2, b: Vector2, w: float, t: Array) -> void:
	if _po:
		return
	var axis := b - a
	var len := axis.length()
	var dir := axis / len
	var perp := Vector2(-dir.y, dir.x)
	if perp.dot(Vector2(-0.5, -0.7)) < 0.0:
		perp = -perp
	for y in range(floori(minf(a.y, b.y) - w - 1), ceili(maxf(a.y, b.y) + w + 1) + 1):
		for x in range(floori(minf(a.x, b.x) - w - 1), ceili(maxf(a.x, b.x) + w + 1) + 1):
			var p := Vector2(x + 0.5, y + 0.5) - a
			var u := p.dot(dir) / len
			if u < -0.02 or u > 1.02:
				continue
			var hw := maxf(w * sin(PI * pow(clampf(u, 0.0, 1.0), 0.75)), 0.55)
			var s := p.dot(perp)
			if absf(s) <= hw:
				var k := s / hw
				_px(img, x, y, t[2] if k > 0.3 else (t[0] if k < -0.4 else t[1]))


## A thin stem from a to b.
static func _stem(img: Image, a: Vector2, b: Vector2, c: Color) -> void:
	if _po:
		return
	var n := maxi(ceili(absf(b.x - a.x)), ceili(absf(b.y - a.y)))
	for i in n + 1:
		var p := a.lerp(b, float(i) / maxi(n, 1))
		_px(img, floori(p.x), floori(p.y), c)


## A small mound of soil, shaded; the seed lies in it, a root crop stands out of it.
static func _mound(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	if not _po:
		_ball(img, cx, cy, rx, ry, tones(Color(data().soil)))


static func _seed(img: Image, id: String) -> void:
	var g := GROUND
	_mound(img, 8, g - 0.7, 3.8, 1.5)
	var seeds: Dictionary = data().seed
	var t := tones(Color(seeds.get(id, seeds.default)))
	if not _po:
		_px(img, 6, g - 1, t[2])
		_px(img, 9, g, t[1])
		_px(img, 7, g, t[0])


## The sprout, by what the crop will grow: two seed leaves, upright blades, a feathery frond,
## or round leaves low on the ground.
static func _sprout(img: Image, look: Dictionary, lt: Array) -> void:
	var g := GROUND
	var shape: String = look.get("shape", "bush")
	var leaves: String = look.get("leaves", "broad")
	_mound(img, 8, g - 0.7, 3.6, 1.3)
	if shape == "grain" or leaves == "thin":
		_leaf(img, Vector2(7.5, g - 1), Vector2(5, g - 7), 0.8, lt)
		_leaf(img, Vector2(8.5, g - 1), Vector2(8.5, g - 8), 0.8, lt)
		_leaf(img, Vector2(9, g - 1), Vector2(11.5, g - 6), 0.8, lt)
	elif leaves == "feathery":
		_stem(img, Vector2(8, g - 1), Vector2(8, g - 5), lt[0])
		_leaf(img, Vector2(8, g - 4), Vector2(5, g - 7), 1.0, lt)
		_leaf(img, Vector2(8, g - 4), Vector2(11, g - 7), 1.0, lt)
		_leaf(img, Vector2(8, g - 4), Vector2(8, g - 8), 0.9, lt)
	elif shape == "ground":
		_leaf(img, Vector2(8, g - 1), Vector2(3, g - 4), 1.7, lt)
		_leaf(img, Vector2(8, g - 1), Vector2(13, g - 4.5), 1.7, lt)
	elif shape == "stalk":
		_leaf(img, Vector2(8, g - 1), Vector2(7, g - 9), 1.0, lt)
		_leaf(img, Vector2(8, g - 3), Vector2(12, g - 7), 0.9, lt)
	else:
		_stem(img, Vector2(8, g - 1), Vector2(8, g - 3), lt[0])
		_leaf(img, Vector2(8, g - 3), Vector2(3.5, g - 6.5), 1.7, lt)
		_leaf(img, Vector2(8, g - 3), Vector2(12.5, g - 7.5), 1.7, lt)


# ---- root crops: turnip, onion, carrot, daikon ----

# Per kind: bulb half width, half height, how far its middle stands above the ground row when
# ripe, and how far above the ground the leaves start.
const _ROOTS := {
	"turnip": [4.4, 3.6, 2.6, 5], "onion": [3.8, 3.2, 2.8, 6],
	"carrot": [3.0, 2.4, 1.2, 3], "daikon": [2.7, 4.6, 3.3, 6],
}


static func _root(img: Image, look: Dictionary, growth: int, ripe: bool, lt: Array) -> void:
	var g := GROUND
	var big := growth >= 3
	var leaves: String = look.get("leaves", "broad")
	var b: Array = look.get("bulb", [4.0, 2.5])
	var ft := tones(Color(look.get("fruit", "e8a23a")))
	var top: Array = tones(Color(look.fruit_top)) if look.has("fruit_top") else []
	var kind := "turnip"
	if leaves == "thin":
		kind = "onion"
	elif leaves == "feathery":
		kind = "carrot"
	elif float(b[1]) > float(b[0]) * 1.3:
		kind = "daikon"
	var geo: Array = _ROOTS[kind]
	var rx: float = geo[0]
	var ry: float = geo[1]
	# Ripe, the bulb stands out of the soil; grown, only its crown shows; young, nothing.
	var cy: float = g - float(geo[2]) if ripe else (g + 1.2 if big else g + 4.0)
	var leaf_y: float = g - float(geo[3]) if ripe else g - 1.0
	var s := minf(1.0, (leaf_y - 2.0) / 9.0)
	var base := Vector2(8, leaf_y)
	match leaves:
		"thin":
			var tips := [[3, 9], [6, 11], [10.5, 10], [13.5, 8]] if big else [[5, 5], [7, 7], [10, 6], [12, 4]]
			for i in tips.size():
				_leaf(img, Vector2(6.0 + i * 1.3, leaf_y), Vector2(tips[i][0], leaf_y - tips[i][1] * s), 0.9, lt)
		"feathery":
			var tips: Array = [Vector2(3, -6), Vector2(8, -9), Vector2(13, -6)] if big else [Vector2(5, -4), Vector2(8, -6), Vector2(11, -4)]
			for tp: Vector2 in tips:
				var tip := Vector2(tp.x, leaf_y + tp.y * s)
				_stem(img, base, tip, lt[0])
				for d in [Vector2(-2.6, -2.0), Vector2(0, -3.2), Vector2(2.6, -2.0)]:
					_leaf(img, tip, tip + d * (1.0 if big else 0.75), 0.9, lt)
				var mid := base.lerp(tip, 0.55)
				_leaf(img, mid, mid + Vector2(-2.4 if tip.x < 8 else 2.4, -1.6), 0.8, lt)
		_:
			var tips: Array = [[2.5, -7, 2.0], [13.5, -7.5, 2.0], [8, -9.5, 2.5]] if big else [[4, -4.5, 1.5], [12, -4.5, 1.5], [8, -6, 1.8]]
			for tp in tips:
				_leaf(img, base, Vector2(tp[0], leaf_y + tp[1] * s), tp[2], lt)
	if ripe or big:
		match kind:
			"turnip":
				_ball(img, 8, cy, rx, ry, ft, top, cy - 0.6, true)
			"onion":
				_ball(img, 8, cy, rx, ry, ft, [], -99.0, true)
				if ripe:
					var ny := int(cy - ry)
					_px(img, 7, ny - 1, ft[2])
					_px(img, 8, ny - 1, ft[0])
					_px(img, 7, ny - 2, ft[1])
					_px(img, 8, ny - 2, ft[0])
					for y in range(ny + 2, int(cy + ry)):
						_px(img, 9, y, ft[0])   # a papery seam down the dark side
			"carrot":
				_ball(img, 8, cy, rx, ry, ft, [], -99.0, true)
				if ripe:
					_px(img, 6, g - 2, ft[0])
					_px(img, 9, g - 2, ft[0])
			"daikon":
				_ball(img, 8, cy, rx, ry, ft, top, g - 5.4, true)
	_mound(img, 8, g - 0.2, 5.0, 1.4)


# ---- bush crops: potato, eggplant ----

## The bush's leaf mass: separate leaves fanned from one foot, the outer ones first. Each leaf is
## lit on its upper-left side and has a shade midrib (the vein); a shaded underside sits below
## them, so the gaps between leaves read dark.
static func _foliage(img: Image, big: bool, lt: Array) -> void:
	var g := GROUND
	# Per leaf: foot x, foot y, tip x, tip y, half width. The outer leaves come first.
	var leaves: Array = [[5.5, g - 2.0, 1.5, g - 5.5, 1.9], [10.5, g - 2.0, 14.5, g - 5.5, 1.9],
		[6.5, g - 2.5, 3.0, g - 10.5, 1.9], [9.5, g - 2.5, 13.0, g - 10.5, 1.9],
		[7.0, g - 2.5, 5.5, g - 13.0, 1.8], [9.0, g - 2.5, 10.5, g - 13.0, 1.8],
		[8.0, g - 2.5, 8.0, g - 12.5, 2.0]] if big else [[6.0, g - 2.0, 3.0, g - 5.5, 1.7],
		[10.0, g - 2.0, 13.0, g - 5.5, 1.7], [7.0, g - 2.5, 5.5, g - 8.0, 1.8],
		[9.0, g - 2.5, 10.5, g - 8.0, 1.8], [8.0, g - 2.5, 8.0, g - 9.5, 2.0]]
	if big:
		_ball(img, 8, g - 2.6, 5.6, 1.6, [lt[0], lt[0], lt[0]])
	else:
		_ball(img, 8, g - 2.2, 4.0, 1.4, [lt[0], lt[0], lt[0]])
	for lf: Array in leaves:
		_fan_leaf(img, Vector2(lf[0], lf[1]), Vector2(lf[2], lf[3]), lf[4], lt)


## One leaf of the fan and its midrib.
static func _fan_leaf(img: Image, foot: Vector2, tip: Vector2, w: float, lt: Array) -> void:
	_leaf(img, foot, tip, w, lt)
	_stem(img, foot, foot.lerp(tip, 0.7), lt[0])

static func _bush(img: Image, id: String, look: Dictionary, growth: int, ripe: bool, lt: Array) -> void:
	var g := GROUND
	var big := growth >= 3
	var ft := tones(Color(look.get("fruit", "e8a23a")))
	if not _po:
		_foliage(img, big, lt)
	if big and not _po and data().flower.has(id):
		var fl := tones(Color(data().flower[id]))
		for p in [Vector2i(5, g - 10), Vector2i(10, g - 11), Vector2i(8, g - 7)]:
			_px(img, p.x, p.y, fl[2])
			_px(img, p.x + 1, p.y, fl[1])
			_px(img, p.x, p.y + 1, fl[1])
			_px(img, p.x + 1, p.y + 1, fl[0])
	if not ripe:
		_mound(img, 8, g - 0.4, 4.4, 1.2)
		return
	if look.get("fruit_shape", "") == "tuber":
		var eye := Color(data().tuber_eye)
		for p in [[3.4, g - 0.5, 2.5, 1.6], [12.6, g - 0.6, 2.5, 1.6], [8.2, g - 0.5, 2.7, 1.6]]:
			_ball(img, p[0], p[1], p[2], p[3], ft, [], -99.0, true)
			_px(img, int(p[0]) + 1, int(p[1]), eye)
	else:
		var cap := tones(Color(data().stem))
		for p in [[4.4, g - 4.6, 3.4], [11.6, g - 5.2, 3.4], [8.0, g - 3.2, 2.8]]:
			_ball(img, p[0], p[1], 1.9, p[2], ft, [], -99.0, true)
			var ty := int(p[1] - p[2])
			var x := int(p[0])
			_px(img, x - 1, ty, cap[2])
			_px(img, x, ty, cap[1])
			_px(img, x + 1, ty, cap[0])
			_px(img, x, ty - 1, cap[1])
	_mound(img, 8, g - 0.4, 4.4, 1.2)


# ---- ground crops: pumpkin ----

static func _ground(img: Image, id: String, look: Dictionary, growth: int, ripe: bool, lt: Array) -> void:
	var g := GROUND
	var big := growth >= 3
	var ft := tones(Color(look.get("fruit", "e8882a")))
	var stem := tones(Color(data().stem))
	_stem(img, Vector2(2, g - 0.5), Vector2(14, g - 1.5), lt[0])
	_stem(img, Vector2(3, g - 1.5), Vector2(13, g - 0.5), lt[0])
	if big:
		if not ripe:
			_blob(img, 8, g - 6.5, 3.4, 2.4, lt)
		_blob(img, 3.8, g - 3.0, 3.4, 2.6, lt)
		_blob(img, 12.2, g - 3.5, 3.4, 2.6, lt)
	else:
		_blob(img, 4.5, g - 2.5, 2.8, 2.0, lt)
		_blob(img, 11.5, g - 3.0, 2.8, 2.2, lt)
	if big and not ripe and not _po and data().flower.has(id):
		var fl := tones(Color(data().flower[id]))
		for p in [Vector2i(7, g - 9), Vector2i(8, g - 9), Vector2i(9, g - 9), Vector2i(8, g - 10), Vector2i(8, g - 8)]:
			_px(img, p.x, p.y, fl[1])
		_px(img, 7, g - 9, fl[2])
		_px(img, 8, g - 9, fl[0])
	if ripe:
		# Three lobes: the outer two first, the middle one over them; the seams are their shade tones.
		_ball(img, 4.8, g - 3.4, 2.7, 3.4, ft)
		_ball(img, 11.2, g - 3.4, 2.7, 3.4, ft)
		_ball(img, 8, g - 3.8, 3.0, 4.1, ft, [], -99.0, true)
		if not _po:
			_px(img, 7, g - 8, stem[1])
			_px(img, 8, g - 8, stem[0])
			_px(img, 7, g - 9, stem[2])
			_px(img, 8, g - 9, stem[1])
			_px(img, 9, g - 10, stem[1])
	_mound(img, 8, g - 0.3, 5.2, 1.2)


## The silhouette's rim in colour `c`: every clear pixel touching the picture by its 4 neighbours.
static func _rim(img: Image, c: Color) -> Image:
	var src := img.duplicate() as Image
	for y in SIZE:
		for x in SIZE:
			if src.get_pixel(x, y).a > 0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < SIZE and q.y < SIZE and src.get_pixelv(q).a > 0:
					img.set_pixel(x, y, c)
					break
	return img
