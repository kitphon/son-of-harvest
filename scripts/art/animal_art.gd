class_name AnimalArt
extends RefCounted
## The farm animals as pixel sprites, drawn in code (our own designs): hens and chicks, Japanese
## Black cattle and calves, cream-wool sheep (shorn, and lambs), a red-tan shiba-like dog.
## Keys "animal:<kind>:<pose>:<frame>[:<facing>]" (PlaceholderArt hands them here).
##
## - Twice the pixel density of the farmer's sprites (SCALE art pixels per world pixel), so the
##   3D view sets pixel_size = FarmWorld.PX / SCALE and the animals keep their world size.
## - Four facings for the diagonal camera: "dl" (down-left, towards the camera and to screen
##   left, the default), "dr", "ul" (away, up-left) and "ur". The right ones are the left ones
##   mirrored. Seen from the front the face shows (both eyes, the muzzle); seen from behind the
##   back of the head, the ears and the rump with its tail. The whole figure is tilted a little
##   (SHEAR): at the game's low camera the near end of a body stands lower on screen.
## - Poses: idle (frame 1 lifts the head, flicks an ear), peck (head to the ground: grazing,
##   pecking, eating), walk (diagonal pairs of legs), sick (lying, dull colours, eyes shut);
##   the dog also sit. The dog "held" in the arms stays the old 14 x 11 picture at the farmer's
##   pixel size (PlaceholderArt._beast), toned by refine_flat.
## - The refined look of the figures (FigureArt), numbers and colours in data/animal_art.json:
##   every material in three tones (shade / base / lit, lit from the upper left), a part's edge
##   over another material in its deep tone, and a rim in the deep tone of the material it
##   touches instead of a near-black outline. The sick pose keeps its dull colours.

const SCALE := 2
const ART_PATH := "res://data/animal_art.json"
const FACINGS := ["dl", "dr", "ul", "ur"]
const KINDS := ["chicken", "chick", "cow", "calf", "sheep", "sheep_shorn", "lamb", "dog"]
const SHEAR := 0.085   # rows a column moves per column away from the middle

## Per kind (all in art pixels): canvas w x h; body ellipse b = [x, y, rx, ry]; leg columns
## [near front, far front, near hind, far hind], their top row and length; head hd = [x, y, r].
## Colours are in data/animal_art.json "kinds".
const QUADS := {
	"cow": {"w": 52, "h": 38, "b": [28.0, 16.0, 15.0, 8.5], "hd": [9.0, 12.0, 5.8],
		"legs": [14, 18, 36, 40], "leg_y": 20, "leg_len": 14, "leg_w": 3, "tail": "rope", "horns": true,
		"ear": "flap"},
	"calf": {"w": 34, "h": 26, "b": [18.0, 11.0, 9.5, 5.4], "hd": [6.5, 9.0, 3.6],
		"legs": [9, 12, 23, 26], "leg_y": 13, "leg_len": 10, "leg_w": 2, "tail": "rope", "ear": "flap"},
	"sheep": {"w": 40, "h": 32, "b": [23.0, 14.0, 12.0, 8.0], "hd": [8.0, 17.0, 4.4],
		"legs": [14, 17, 28, 31], "leg_y": 20, "leg_len": 10, "leg_w": 2, "tail": "stub", "fleece": true,
		"ear": "flap"},
	"sheep_shorn": {"w": 40, "h": 32, "b": [23.0, 16.0, 10.0, 5.6], "hd": [9.0, 15.0, 4.0],
		"legs": [15, 18, 28, 31], "leg_y": 20, "leg_len": 10, "leg_w": 2, "tail": "stub", "ear": "flap",
		"ribs": true},
	"lamb": {"w": 26, "h": 22, "b": [15.0, 10.0, 7.2, 4.8], "hd": [5.5, 12.0, 3.2],
		"legs": [10, 12, 18, 20], "leg_y": 13, "leg_len": 8, "leg_w": 2, "tail": "stub", "fleece": true,
		"ear": "flap"},
	"dog": {"w": 30, "h": 24, "b": [16.0, 11.0, 8.6, 4.8], "hd": [6.0, 7.0, 3.8],
		"legs": [9, 11, 21, 23], "leg_y": 13, "leg_len": 9, "leg_w": 2, "tail": "curl", "ear": "prick",
		"urajiro": true},
}

static var _art := {}
static var _reg := {}   # a tone's colour key -> [its material's base key, its deep tone]


## The numbers and colours of data/animal_art.json.
static func art() -> Dictionary:
	if _art.is_empty():
		_art = JSON.parse_string(FileAccess.get_file_as_string(ART_PATH))
	return _art


## A material from its base colour: {base, shade, lit, deep} (FigureArt.tones with our numbers).
static func mat(base: Color) -> Dictionary:
	var tn := FigureArt.tones(base, false, art())
	var m := {"shade": tn[0], "base": tn[1], "lit": tn[2], "deep": tn[3], "id": FigureArt._key(tn[1])}
	for c: Color in tn:
		_note(c, m)
	return m


## Marks `c` as one of material m's colours (for the part lines and the rim).
static func _note(c: Color, m: Dictionary) -> void:
	var k := FigureArt._key(c)
	if not _reg.has(k):
		_reg[k] = [m.id, m.deep]


## The tones of a kind's material ("body", "head", "muzzle", "leg", "hoof", ...; birds: "hen",
## "chick", "comb", ...), dulled when sick as the sick pose draws it.
static func tones_of(kind: String, part: String, sick := false) -> Dictionary:
	return mat(_colour(kind, part, sick))


static func _colour(kind: String, part: String, sick: bool) -> Color:
	var a := art()
	if QUADS.has(kind):
		var c := Color(str(a.kinds[kind][part]))
		if sick and part in ["body", "head", "leg"]:
			var sk: Dictionary = a.sick
			var g := Color(str(sk.grey))
			c = c.lerp(g, float(sk.leg_mix)) if part == "leg" else c.lerp(g, float(sk.mix)).darkened(float(sk.dark))
		return c
	var b: Dictionary = a.birds
	if part == "chick":
		return Color(str(b.chick)).lerp(Color(str(b.chick_sick)), float(b.chick_sick_mix)) if sick else Color(str(b.chick))
	var c2 := Color(str(b[part]))
	if sick and part in ["hen", "wing", "tail"]:
		c2 = c2.darkened(float(b.hen_sick))
	return c2


static func _feat(k: String) -> Color:
	return Color(str(art().features[k]))


## Birds: canvas, and the ground row.
const BIRDS := {
	"chicken": {"w": 30, "h": 28},
	"chick": {"w": 18, "h": 16},
}


## The picture for a key's parts: kind, pose, frame and facing ("dl" when left out).
static func make(kind: String, pose: String, frame: int, facing: String = "dl") -> Image:
	if not facing in FACINGS:
		facing = "dl"
	var away := facing.begins_with("u")
	var img: Image
	if QUADS.has(kind):
		img = _quad(kind, pose, frame, away)
	else:
		img = _bird(kind, pose, frame, away)
	img = _rim(_tilt(img, away))   # the rim before the mirror, so the right facings mirror exactly
	if facing.ends_with("r"):
		img.flip_x()
	return img


## The picture size for a kind (every pose and facing has it).
static func size_of(kind: String) -> Vector2i:
	var s: Dictionary = QUADS[kind] if QUADS.has(kind) else BIRDS[kind]
	return Vector2i(s.w, s.h)


## Facing from a step on the ground (cells x, z): the camera looks along (-1, 0, -1), so screen
## right is +x -z and towards the camera +x +z. A zero step keeps `keep`.
static func facing_of(step: Vector2, keep: String = "dl") -> String:
	var right := step.x - step.y
	var down := step.x + step.y
	if absf(right) < 0.001 and absf(down) < 0.001:
		return keep
	var v := "d" if down >= 0.0 else "u"
	var h := "r" if right > 0.0 else "l"
	if absf(down) < 0.001:
		v = keep.substr(0, 1)
	if absf(right) < 0.001:
		h = keep.substr(1, 1)
	return v + h


## A picture laid in flat colours (one a material; `fixed` left as they are) toned like the
## animals: shade / base / lit by the side of a part that is open, a rim in the deep tone pulled
## towards the rim colour. For the dog held in the arms (PlaceholderArt._beast).
static func refine_flat(img: Image, fixed: Array) -> Image:
	return BabyArt.refine(img, fixed, [], art())


# --- drawing helpers -------------------------------------------------------

static func _blank(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _px(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if r.has_area():
		img.fill_rect(r, c)


static func _p(img: Image, x: float, y: float, c: Color) -> void:
	_px(img, roundi(x), roundi(y), 1, 1, c)


## The material (its base key) a drawn pixel belongs to, "" for none, "?" for a feature.
static func _mat_at(img: Image, x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return ""
	var c := img.get_pixel(x, y)
	if c.a == 0.0:
		return ""
	var r: Array = _reg.get(FigureArt._key(c), [])
	return r[0] if not r.is_empty() else "?"


## A flat ellipse.
static func _disc(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(floori(cy - ry), ceili(cy + ry) + 1):
		for x in range(floori(cx - rx), ceili(cx + rx) + 1):
			if _in(x, y, cx, cy, rx, ry):
				_px(img, x, y, 1, 1, c)


static func _in(x: int, y: int, cx: float, cy: float, rx: float, ry: float) -> bool:
	var dx := (x + 0.5 - cx) / rx
	var dy := (y + 0.5 - cy) / ry
	return dx * dx + dy * dy <= 1.0


## An ellipse in a material's three tones, lit from the upper left: the lit tone on the upper
## left, the base, the shade on the lower right. With `line`, its edge where it lies over another
## material is the material's deep tone (the line between two parts).
static func _blob(img: Image, cx: float, cy: float, rx: float, ry: float, m: Dictionary, line := true) -> void:
	line = line and rx >= 2.5 and ry >= 2.0
	var put := []
	for y in range(floori(cy - ry), ceili(cy + ry) + 1):
		for x in range(floori(cx - rx), ceili(cx + rx) + 1):
			if not _in(x, y, cx, cy, rx, ry):
				continue
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var t := dx * 0.4 + dy * 0.85
			var c: Color = m.shade if t > 0.5 else (m.lit if t < -0.5 else m.base)
			if line:
				var edge := not (_in(x - 1, y, cx, cy, rx, ry) and _in(x + 1, y, cx, cy, rx, ry)
					and _in(x, y - 1, cx, cy, rx, ry) and _in(x, y + 1, cx, cy, rx, ry))
				var under := _mat_at(img, x, y)
				if edge and under != "" and under != m.id:
					c = m.deep
			put.append([x, y, c])
	for q in put:
		_px(img, q[0], q[1], 1, 1, q[2])


## Round blobs along a line, from radius r0 to r1 (a neck, a tail), in a material's tones by the
## side of the stroke a pixel is on.
static func _stroke(img: Image, a: Vector2, b: Vector2, r0: float, r1: float, m: Dictionary) -> void:
	var n := maxi(int(a.distance_to(b)), 1)
	var best := {}   # pixel -> [distance / radius, offset / radius]
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t)
		var r := lerpf(r0, r1, t)
		for y in range(floori(p.y - r), ceili(p.y + r) + 1):
			for x in range(floori(p.x - r), ceili(p.x + r) + 1):
				var o := (Vector2(x + 0.5, y + 0.5) - p) / r
				var d := o.length()
				if d > 1.0:
					continue
				var k := Vector2i(x, y)
				if not best.has(k) or d < best[k][0]:
					best[k] = [d, o]
	for k: Vector2i in best:
		var o: Vector2 = best[k][1]
		var tt := o.x * 0.4 + o.y * 0.85
		_px(img, k.x, k.y, 1, 1, m.shade if tt > 0.5 else (m.lit if tt < -0.5 else m.base))


## A column of a material (a leg, a hoof): the left column lit, the right one shaded.
static func _bar(img: Image, x: int, y: int, w: int, h: int, m: Dictionary) -> void:
	_px(img, x, y, w, h, m.base)
	if w >= 2:
		_px(img, x, y, 1, h, m.lit)
		_px(img, x + w - 1, y, 1, h, m.shade)
	elif h >= 2:
		_px(img, x, y, 1, 1, m.lit)


## Tilts the figure (see SHEAR) and sets its lowest row on the canvas's second last row.
static func _tilt(img: Image, away: bool) -> Image:
	var size := img.get_size()
	var out := _blank(size.x, size.y)
	var mid := size.x / 2.0
	var shifts := PackedInt32Array()
	var low := -999
	for x in size.x:
		var d := (mid - x) * SHEAR      # the left end is the head's
		var sh := roundi(-d if away else d)
		shifts.append(sh)
		for y in size.y:
			if img.get_pixel(x, y).a > 0.0:
				low = maxi(low, y + sh)
	if low == -999:
		return img
	var lift := low - (size.y - 2)
	for x in size.x:
		for y in size.y:
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				var ny := y + shifts[x] - lift
				if ny >= 0 and ny < size.y:
					out.set_pixel(x, ny, c)
	return out


## The rim round the silhouette: the deep tone of the material it touches, pulled towards the
## rim colour (data/animal_art.json), instead of one near-black outline. A feature colour (an
## eye, a nostril) on the edge gives its own colour darkened.
static func _rim(img: Image) -> Image:
	var a := art()
	var rim := Color(str(a.rim))
	var mix: float = a.rim_mix
	var src := img.duplicate() as Image
	var size := img.get_size()
	for y in size.y:
		for x in size.x:
			if src.get_pixel(x, y).a > 0.0:
				continue
			# The pixel below first (under a foot, the foot), then the sides, then above.
			for d in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
				var q: Vector2i = Vector2i(x, y) - d
				if q.x < 0 or q.y < 0 or q.x >= size.x or q.y >= size.y:
					continue
				var n := src.get_pixelv(q)
				if n.a == 0.0:
					continue
				var r: Array = _reg.get(FigureArt._key(n), [])
				var deep: Color = r[1] if not r.is_empty() else n.darkened(float(a.deep))
				var c := deep.lerp(rim, mix)
				c.a = 1.0
				img.set_pixel(x, y, c)
				break
	return img


## A fluffy mass: a ring of round curls round a core, the lower right curls shaded, the lowest
## a step deeper; a curl's edge over another material is the wool's deep tone.
static func _cloud(img: Image, cx: float, cy: float, rx: float, ry: float, m: Dictionary, curl: float) -> void:
	var low: Color = m.shade.lerp(m.deep, 0.35)
	_note(low, m)
	_blob(img, cx, cy, rx - 1.0, ry - 1.0, m)
	var n := 12
	for i in n:
		var a := TAU * i / n
		var px := cx + cos(a) * (rx - curl * 0.6)
		var py := cy + sin(a) * (ry - curl * 0.6)
		var put := []
		for y in range(floori(py - curl), ceili(py + curl) + 1):
			for x in range(floori(px - curl), ceili(px + curl) + 1):
				var dx := x + 0.5 - px
				var dy := y + 0.5 - py
				var d := sqrt(dx * dx + dy * dy)
				if d > curl:
					continue
				var t := (dx * 0.5 + dy * 0.85) / curl
				var c: Color = m.base
				if t > 0.55:
					c = m.shade if sin(a) < 0.55 else low
				elif t < -0.45:
					c = m.lit
				var under := _mat_at(img, x, y)
				if d > curl - 1.0 and under != "" and under != m.id:
					c = m.deep
				put.append([x, y, c])
		for q in put:
			_px(img, q[0], q[1], 1, 1, q[2])


## Eyes: two rows, a pale glint above a dark pupil (or a shut lid in the head's deep tone).
static func _eye(img: Image, x: float, y: float, shut: bool, glint: Color, pupil: Color, lid: Color) -> void:
	if shut:
		_px(img, roundi(x), roundi(y) + 1, 2, 1, lid)
		return
	_px(img, roundi(x), roundi(y), 2, 2, pupil)
	_p(img, x, y, glint)


# --- four-legged animals ----------------------------------------------------

static func _quad(kind: String, pose: String, frame: int, away: bool) -> Image:
	var s: Dictionary = QUADS[kind]
	var img := _blank(s.w, s.h)
	var sick := pose == "sick"
	var sit := pose == "sit"
	var body := tones_of(kind, "body", sick)
	var head_m := tones_of(kind, "head", sick)
	var leg := tones_of(kind, "leg", sick)
	var hoof := tones_of(kind, "hoof", sick)
	var far := float(art().far_leg)
	var leg_far := mat(leg.base.darkened(far))
	var hoof_far := mat(hoof.base.darkened(far))
	var b: Array = s.b
	var bx: float = b[0]
	var by: float = b[1]
	var rx: float = b[2]
	var ry: float = b[3]
	var fleece: bool = s.has("fleece")
	if sick:
		by += s.leg_len - 3.0
		ry = maxf(ry - 0.5, 3.0)
	elif sit:
		by += 2.5
	var ground: int = s.leg_y + s.leg_len
	# Far legs first, a step up and a shade darker.
	var swing := (frame % 2) * 2 - 1 if pose == "walk" else 0
	if not sick:
		for k in [1, 3]:
			if sit and k == 3:
				continue
			_leg(img, s, k, swing, sit, leg_far, hoof_far, -1)
	# The tail goes behind the body seen from the front, over the rump seen from behind.
	if not away:
		_tail(img, s, kind, bx, by, rx, ry, body, false, sick)
	# The body.
	if fleece:
		_cloud(img, bx, by, rx, ry, body, 3.0 if s.w > 30 else 2.2)
	else:
		_blob(img, bx, by, rx, ry, body)
		_blob(img, bx + rx * 0.5, by + ry * 0.05, rx * 0.5, ry * 0.96, body)    # haunch
		_blob(img, bx - rx * 0.5, by - ry * 0.02, rx * 0.46, ry * 0.94, body)   # shoulder
		if s.has("urajiro"):   # cream chest and underside
			var cream := tones_of(kind, "muzzle")
			_blob(img, bx - rx * 0.62, by + ry * 0.42, rx * 0.34, ry * 0.62, cream, false)
			_blob(img, bx + rx * 0.05, by + ry * 0.7, rx * 0.7, ry * 0.3, cream, false)
		if s.has("ribs"):
			for i in 3:
				var rxp := bx - 4.0 + i * 3.0
				_px(img, roundi(rxp), roundi(by - ry * 0.25), 1, 3, body.shade)
		if kind == "cow" and not sick:   # the udder
			_blob(img, bx + rx * 0.3, by + ry + 0.4, 2.6, 1.8, tones_of(kind, "udder"), false)
	# Near legs over the body's lower edge.
	if not sick:
		for k in [0, 2]:
			_leg(img, s, k, swing, sit, leg, hoof, 1)
	else:   # folded: a forelimb tucked out in front, the hooves showing under the belly
		_blob(img, bx - rx * 0.55, by + ry - 0.5, 3.4, 1.6, leg, false)
		_bar(img, roundi(bx - rx * 0.55) - 4, roundi(by + ry) - 1, 2, 2, hoof)
		_bar(img, roundi(bx + rx * 0.4), roundi(by + ry) - 1, 3, 2, hoof)
	if sit:   # a haunch on the ground and a hind foot
		_blob(img, bx + rx * 0.35, by + ry * 0.35, rx * 0.55, ry * 0.9, body)
		_bar(img, roundi(bx + rx * 0.05), ground - 2, 5, 2, hoof)
	if away:
		_tail(img, s, kind, bx, by, rx, ry, body, true, sick)
	# Head and neck.
	var hd: Array = s.hd
	var r: float = hd[2]
	var head := Vector2(hd[0], hd[1])
	var shoulder := Vector2(bx - rx * 0.72, by - ry * 0.35)
	match pose:
		"peck":
			head = Vector2(hd[0] - 1.5 + (frame % 2), ground - r * 0.95 - 1.0 + (frame % 2) * 0.5)
		"idle":
			if frame % 2 == 1:
				head.y -= 1.0
		"sick":
			head = Vector2(hd[0] + rx * 0.35, by - ry * 0.35)
			shoulder = Vector2(bx - rx * 0.6, by - ry * 0.2)
		"sit":
			head = Vector2(hd[0] + 1.0, hd[1] - 1.0)
	if away:   # seen from behind the head sits a little higher and in, hidden by the shoulders
		head += Vector2(1.5, -1.0)
	var woolly := fleece or kind == "sheep_shorn"
	_stroke(img, shoulder, head + Vector2(r * 0.5, r * 0.3), ry * 0.78 if not woolly else ry * 0.55,
		r * 0.75 if not fleece else r * 0.6, head_m if not woolly else body)
	_head(img, s, kind, head, r, pose, frame, away, sick, body, head_m)
	return img


static func _leg(img: Image, s: Dictionary, k: int, swing: int, sit: bool, m: Dictionary, hoof: Dictionary, near: int) -> void:
	if sit and k >= 2:
		return
	var off: int = swing if k % 3 == 0 else -swing
	var lift := 2 if off < 0 else 0
	var w: int = s.leg_w
	var x: int = s.legs[k] + off + (1 if near < 0 else 0)
	var top: int = s.leg_y - (1 if near < 0 else 0)
	var len: int = s.leg_len - lift + (1 if near < 0 else 0)
	if sit:
		top -= 1
		len += 1
	# A thicker upper leg, a slimmer lower one, a hoof.
	_bar(img, x, top, w, len, m)
	if s.leg_len >= 9 and w >= 2:
		_bar(img, x - 1, top, w + 1, 3, m)
	_bar(img, x, top + len - 2, w, 2, hoof)


static func _tail(img: Image, s: Dictionary, kind: String, bx: float, by: float, rx: float, ry: float, body: Dictionary, over: bool, sick: bool) -> void:
	var x := bx + rx - 1.0 if not over else bx + rx * 0.45
	match s.tail:
		"rope":
			var top := Vector2(x, by - ry * 0.7)
			var tip := Vector2(x + (1.0 if not over else 0.0), by + ry * 0.95 + (2.0 if sick else 0.0))
			_stroke(img, top, tip, 0.7, 0.7, mat(body.base.darkened(0.15)))
			_blob(img, tip.x, tip.y + 1.0, 1.6, 2.4, tones_of(kind, "tail_tip"), false)
		"stub":
			var big: bool = s.w > 30
			_blob(img, x, by - ry * 0.25, 2.2 if big else 1.6, 2.2 if big else 1.6,
				mat(body.base.darkened(0.05)) if s.has("fleece") else body, big)
		"curl":   # a ring curled over the back, its hole dark, a cream tip
			var cx := bx + rx * 0.7 if not over else bx + rx * 0.3
			var cy := by - ry - 1.0
			_blob(img, cx, cy, 3.4, 3.2, body)
			_disc(img, cx - 0.4, cy + 0.2, 1.1, 1.0, body.shade)
			_px(img, roundi(cx) - 3, roundi(cy) + 1, 2, 2, tones_of(kind, "muzzle").base)


static func _head(img: Image, s: Dictionary, kind: String, h: Vector2, r: float, pose: String, frame: int,
		away: bool, sick: bool, body: Dictionary, head_m: Dictionary) -> void:
	var fleece: bool = s.has("fleece")
	var muzzle := tones_of(kind, "muzzle")
	var shut := sick
	var cattle := kind in ["cow", "calf"]
	var eye_g := _feat("cow_eye_glint" if cattle else "eye_glint")
	var eye_p := _feat("cow_eye" if cattle else "eye")
	var nostril := _feat("nostril")
	var flick := pose == "idle" and frame % 2 == 1
	# Ears first (behind the skull), the near one flicking.
	_ears(img, s, h, r, away, flick, head_m)
	if away:
		# The muzzle peeks out below and ahead of the skull.
		_blob(img, h.x - r * 0.25, h.y + r * 0.55, r * 0.55, r * 0.45, muzzle, false)
	_blob(img, h.x, h.y, r * 1.08, r, head_m)
	if not away:
		# The muzzle, wider seen from the front.
		var mw := r * 0.85
		var mh := r * 0.62
		_blob(img, h.x - r * 0.55, h.y + r * 0.62, mw, mh, muzzle)
		if cattle or kind == "dog":
			_p(img, h.x - r * 1.0, h.y + r * 0.45, nostril)
			_p(img, h.x - r * 0.35, h.y + r * 0.45, nostril)
		if kind == "dog":
			_blob(img, h.x + r * 0.05, h.y + r * 0.35, r * 0.55, r * 0.4, muzzle, false)   # cream cheeks
			_blob(img, h.x - r * 0.55, h.y + r * 0.62, mw, mh, muzzle, false)
			_px(img, roundi(h.x - r * 0.95), roundi(h.y + r * 0.2), 2, 2, nostril)   # nose
			if pose == "sit":   # a tongue when sitting up
				_px(img, roundi(h.x - r * 0.6), roundi(h.y + r * 1.05), 2, 2, _feat("tongue"))
		elif kind in ["sheep", "sheep_shorn", "lamb"]:
			_px(img, roundi(h.x - r * 0.95), roundi(h.y + r * 0.5), 2, 1, muzzle.deep)
		# Both eyes: the near one nearer the muzzle, the far one a little smaller in.
		_eye(img, h.x - r * 0.62, h.y - r * 0.28, shut, eye_g, eye_p, head_m.deep)
		_eye(img, h.x + r * 0.2, h.y - r * 0.3, shut, eye_g, eye_p, head_m.deep)
	if fleece:   # a wool cap and fringe
		_cloud(img, h.x + r * 0.3, h.y - r * 0.75, r * 0.95, r * 0.5, body, 1.6)
	if cattle:
		if s.has("horns") and not sick:
			var horn := tones_of(kind, "horns")
			for hx: float in [h.x - r * 0.55, h.x + r * 0.45]:
				_px(img, roundi(hx), roundi(h.y - r) - 2, 1, 3, horn.base)
				_px(img, roundi(hx), roundi(h.y - r) - 2, 1, 1, horn.lit)
		else:   # a tuft of forelock
			_px(img, roundi(h.x - 1.0), roundi(h.y - r) - 1, 3, 2, head_m.lit)
	if kind == "dog" and away:
		_px(img, roundi(h.x - 1.0), roundi(h.y - r * 0.2), 2, 3, body.shade)   # the nape


static func _ears(img: Image, s: Dictionary, h: Vector2, r: float, away: bool, flick: bool, m: Dictionary) -> void:
	var inner := _feat("ear_inner" if s.ear == "flap" else "prick_inner")
	var y := h.y - r * 0.55
	if s.ear == "prick":
		for side in [-1, 1]:
			var x: float = h.x + side * r * 0.72
			var up := 4.0 if not (flick and side > 0) else 3.0
			for i in int(up):
				var wid := maxi(2 - i / 2, 1)
				var ex: int = roundi(x) - 1 + (1 if side > 0 else 0) - i / 3 * side
				var ey := roundi(h.y - r * 0.5) - i
				_px(img, ex, ey, wid + 1, 1, m.base)
				_px(img, ex, ey, 1, 1, m.lit)
				_px(img, ex + wid, ey, 1, 1, m.shade)
			_px(img, roundi(x), roundi(h.y - r * 0.5) - 1, 1, 2, inner)
		return
	# Flap ears out to the sides, lowered a pixel when one flicks; the far one darker.
	_blob(img, h.x - r * 1.15, y + (1.0 if flick else 0.0), r * 0.62, r * 0.3, m, false)
	_blob(img, h.x + r * 1.15, y, r * 0.6, r * 0.3, mat(m.base.darkened(0.08)), false)
	_p(img, h.x - r * 1.05, y + (1.0 if flick else 0.0), inner)


# --- birds ---------------------------------------------------------------------

static func _bird(kind: String, pose: String, frame: int, away: bool) -> Image:
	if kind == "chick":
		return _chick(pose, frame, away)
	return _hen(pose, frame, away)


static func _hen(pose: String, frame: int, away: bool) -> Image:
	var s: Dictionary = BIRDS.chicken
	var img := _blank(s.w, s.h)
	var sick := pose == "sick"
	var white := tones_of("chicken", "hen", sick)
	var wing := tones_of("chicken", "wing", sick)
	var tail := tones_of("chicken", "tail", sick)
	var comb := tones_of("chicken", "comb")
	var beak := tones_of("chicken", "beak")
	var leg := tones_of("chicken", "leg")
	var leg_far := mat(leg.base.darkened(float(art().far_leg)))
	var swing := (frame % 2) * 2 - 1 if pose == "walk" else 0
	var ground: int = s.h - 3
	var bx := 15.0
	var by := 15.0 + (1.0 if sick else 0.0)
	# Legs and toes (the far one a shade darker).
	for k in 2:
		var off := swing * (1 if k == 0 else -1)
		var lift := 2 if off < 0 else 0
		var x := 11 + k * 5 + off
		var m: Dictionary = leg if k == 0 else leg_far
		_px(img, x, by + 4 + (1 if k == 1 else 0), 1, ground - roundi(by) - 4 - lift - (1 if k == 1 else 0), m.base)
		var fy: int = ground - lift - (1 if k == 1 else 0)
		_px(img, x - 2, fy, 4, 1, m.base)
		_px(img, x + 1, fy, 1, 1, m.shade)
		_px(img, x - 1, fy - 1, 1, 1, m.lit)
	# Tail feathers behind (front view) or over the rump (back view).
	if not away:
		_hen_tail(img, bx, by, tail, away)
	# Body: a round breast, a back sloping to the tail.
	_blob(img, bx, by, 8.6, 6.4 + (0.6 if sick else 0.0), white)
	_blob(img, bx + 2.5, by - 1.0, 6.2, 5.4, white)
	_disc(img, bx - 0.5, by + 5.2, 6.4, 1.4, white.shade)   # the shaded belly
	# The folded wing with scalloped feather edges in its deep tone.
	_blob(img, bx + 1.0, by + 0.5, 5.8, 3.8, wing)
	for i in 4:
		_px(img, roundi(bx - 3.0 + i * 2.5), roundi(by + 3.6) - (i % 2), 2, 1, wing.deep)
	_px(img, roundi(bx - 1.0), roundi(by - 1.0), 5, 1, wing.lit)
	if away:
		_hen_tail(img, bx, by, tail, away)
	# Neck and head.
	var head := Vector2(6.5, 7.0)
	match pose:
		"peck":
			head = Vector2(4.0, ground - 4.0 + (frame % 2))
		"sick":
			head = Vector2(6.5, 10.0)
	if away:
		head += Vector2(1.5, -0.5)
	_stroke(img, Vector2(bx - 5.0, by - 2.5), head + Vector2(1.5, 1.5), 3.0, 2.4, white)
	_blob(img, head.x, head.y, 3.4, 3.3, white, false)
	var hx := head.x
	var hy := head.y
	# A comb of three points, and the wattle.
	for i in 3:
		_blob(img, hx - 1.5 + i * 1.6, hy - 3.6 - (1 if i == 1 else 0), 1.2, 1.4, comb, false)
	if not away:
		_px(img, roundi(hx) - 5, roundi(hy) + 0, 3, 1, beak.base)           # beak
		_px(img, roundi(hx) - 5, roundi(hy) + 0, 1, 1, beak.lit)
		_px(img, roundi(hx) - 4, roundi(hy) + 1, 2, 1, beak.shade)
		_blob(img, hx - 2.2, hy + 3.0, 0.9, 1.4, comb, false)              # wattle
		_eye(img, hx - 1.8, hy - 1.4, sick, _feat("eye_glint"), _feat("eye"), white.deep)
		_blob(img, hx - 1.0, hy + 0.6, 1.5, 1.1, tones_of("chicken", "cheek"), false)   # earlobe cheek
	else:
		_px(img, roundi(hx) - 1, roundi(hy) + 1, 3, 2, white.shade)          # back of the neck feathers
	return img


static func _hen_tail(img: Image, bx: float, by: float, m: Dictionary, away: bool) -> void:
	var x := bx + 6.5
	var fan := [[x, by - 2.0, 2.4, 4.6], [x + 2.0, by - 4.0, 2.0, 4.6], [x + 3.6, by - 2.5, 1.8, 4.0], [x + 0.8, by - 6.0, 2.0, 4.2]]
	if away:   # seen from behind the tail is a fan right in the middle
		fan = [[bx + 0.5, by - 4.5, 2.4, 4.8], [bx - 2.0, by - 3.5, 2.0, 4.2], [bx + 3.0, by - 3.5, 2.0, 4.2], [bx + 0.5, by - 7.0, 2.2, 3.4]]
	var tip: Color = m.shade.lerp(m.deep, 0.3)
	_note(tip, m)
	for f in fan:
		_blob(img, f[0], f[1], f[2], f[3], m, false)
		_disc(img, f[0], f[1] - f[3] * 0.65, f[2] * 0.8, f[3] * 0.3, tip)   # darker tips


static func _chick(pose: String, frame: int, away: bool) -> Image:
	var s: Dictionary = BIRDS.chick
	var img := _blank(s.w, s.h)
	var sick := pose == "sick"
	var body := tones_of("chick", "chick", sick)
	var wing := mat(body.base.darkened(0.1))
	var beak := tones_of("chick", "beak")
	var swing := (frame % 2) * 2 - 1 if pose == "walk" else 0
	var ground: int = s.h - 3
	var bx := 10.0
	var by := 9.5 + (1.0 if sick else 0.0)
	for k in 2:
		var off := swing * (1 if k == 0 else -1)
		var lift := 1 if off < 0 else 0
		var x := 7 + k * 4 + off
		var c: Color = beak.base if k == 0 else beak.shade
		_px(img, x, ground - 3 - lift, 1, 3, c)
		_px(img, x - 1, ground - lift, 3, 1, c)
	_blob(img, bx, by, 6.0, 4.6 + (0.8 if sick else 0.0), body)
	_px(img, roundi(bx) + 4, roundi(by) - 4, 2, 2, body.shade)   # a tail tuft
	_px(img, roundi(bx) + 5, roundi(by) - 5, 1, 1, body.shade)
	_blob(img, bx + 1.0, by + 0.8, 3.0, 2.0, wing)       # a stub of a wing
	var head := Vector2(5.0, 5.5)
	if pose == "peck":
		head = Vector2(4.0, ground - 3.5 + (frame % 2))
	elif sick:
		head = Vector2(5.0, 8.0)
	if away:
		head += Vector2(1.0, -0.5)
	_blob(img, head.x, head.y, 3.6, 3.4, body)
	if not away:
		_px(img, roundi(head.x) - 5, roundi(head.y) + 0, 2, 1, beak.base)
		_px(img, roundi(head.x) - 4, roundi(head.y) + 1, 2, 1, beak.shade)
		_eye(img, head.x - 1.6, head.y - 1.2, sick, _feat("eye_glint"), _feat("eye"), body.deep)
	_px(img, roundi(head.x), roundi(head.y) - 4, 1, 1, body.lit)   # a tuft on the crown
	return img
