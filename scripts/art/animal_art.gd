class_name AnimalArt
extends RefCounted
## The farm animals as pixel sprites, drawn in code (our own designs): hens and chicks, Japanese
## Black cattle and calves, cream-wool sheep (shorn, and lambs), a red-tan shiba-like dog.
## Keys "animal:<kind>:<pose>:<frame>[:<facing>]" (PlaceholderArt._animal hands them here).
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
##   pixel size (PlaceholderArt._beast).

const SCALE := 2
const OUTLINE := Color("2a1e1e")
const FACINGS := ["dl", "dr", "ul", "ur"]
const KINDS := ["chicken", "chick", "cow", "calf", "sheep", "sheep_shorn", "lamb", "dog"]
const SHEAR := 0.085   # rows a column moves per column away from the middle

const _HEN := Color("f4f0e6")
const _COMB := Color("c8442c")
const _BEAK := Color("e8a23a")
const _LEG := Color("d9972f")
const _CHICK := Color("f2d25a")
const _PINK := Color("d89a90")
const _EYE_LIGHT := Color("e8e0d0")

## Per kind (all in art pixels): canvas w x h; body ellipse b = [x, y, rx, ry]; leg columns
## [near front, far front, near hind, far hind], their top row and length; head hd = [x, y, r].
const QUADS := {
	"cow": {"w": 52, "h": 38, "body": Color("302823"), "head": Color("302823"), "muzzle": Color("b8a898"),
		"leg": Color("2a2420"), "hoof": Color("574d44"), "b": [28.0, 16.0, 15.0, 8.5], "hd": [9.0, 12.0, 5.8],
		"legs": [14, 18, 36, 40], "leg_y": 20, "leg_len": 14, "leg_w": 3, "tail": "rope", "horns": Color("e0d8c0"),
		"ear": "flap", "hi": 0.2},
	"calf": {"w": 34, "h": 26, "body": Color("43372f"), "head": Color("43372f"), "muzzle": Color("c0b0a0"),
		"leg": Color("382e28"), "hoof": Color("605850"), "b": [18.0, 11.0, 9.5, 5.4], "hd": [6.5, 9.0, 3.6],
		"legs": [9, 12, 23, 26], "leg_y": 13, "leg_len": 10, "leg_w": 2, "tail": "rope", "ear": "flap", "hi": 0.2},
	"sheep": {"w": 40, "h": 32, "body": Color("f3ecda"), "head": Color("3a302c"), "muzzle": Color("52463f"),
		"leg": Color("3a302c"), "hoof": Color("2a2220"), "b": [23.0, 14.0, 12.0, 8.0], "hd": [8.0, 17.0, 4.4],
		"legs": [14, 17, 28, 31], "leg_y": 20, "leg_len": 10, "leg_w": 2, "tail": "stub", "fleece": true,
		"ear": "flap", "hi": 0.0},
	"sheep_shorn": {"w": 40, "h": 32, "body": Color("dcc6bd"), "head": Color("3a302c"), "muzzle": Color("52463f"),
		"leg": Color("3a302c"), "hoof": Color("2a2220"), "b": [23.0, 16.0, 10.0, 5.6], "hd": [9.0, 15.0, 4.0],
		"legs": [15, 18, 28, 31], "leg_y": 20, "leg_len": 10, "leg_w": 2, "tail": "stub", "ear": "flap",
		"hi": 0.1, "ribs": true},
	"lamb": {"w": 26, "h": 22, "body": Color("f7f1e4"), "head": Color("4a403a"), "muzzle": Color("5e524b"),
		"leg": Color("4a403a"), "hoof": Color("2a2220"), "b": [15.0, 10.0, 7.2, 4.8], "hd": [5.5, 12.0, 3.2],
		"legs": [10, 12, 18, 20], "leg_y": 13, "leg_len": 8, "leg_w": 2, "tail": "stub", "fleece": true,
		"ear": "flap", "hi": 0.0},
	"dog": {"w": 30, "h": 24, "body": Color("c8783c"), "head": Color("c8783c"), "muzzle": Color("f2e2c8"),
		"leg": Color("c8783c"), "hoof": Color("f2e2c8"), "b": [16.0, 11.0, 8.6, 4.8], "hd": [6.0, 7.0, 3.8],
		"legs": [9, 11, 21, 23], "leg_y": 13, "leg_len": 9, "leg_w": 2, "tail": "curl", "ear": "prick",
		"hi": 0.16, "urajiro": true},
}

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
	img = _tilt(img, away)
	if facing.ends_with("r"):
		img.flip_x()
	return _outline(img)


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


## A flat ellipse.
static func _disc(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(floori(cy - ry), ceili(cy + ry) + 1):
		for x in range(floori(cx - rx), ceili(cx + rx) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(img, x, y, 1, 1, c)


## An ellipse in three tones, lit from the upper left: light on the upper left, base, and a
## darker lower right.
static func _blob(img: Image, cx: float, cy: float, rx: float, ry: float, base: Color, hi := 0.16) -> void:
	var light := base.lightened(hi)
	var dark := base.darkened(0.24)
	for y in range(floori(cy - ry), ceili(cy + ry) + 1):
		for x in range(floori(cx - rx), ceili(cx + rx) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy > 1.0:
				continue
			var t := dx * 0.4 + dy * 0.85
			_px(img, x, y, 1, 1, dark if t > 0.5 else (light if t < -0.5 else base))


## Round blobs along a line, from radius r0 to r1 (a neck, a tail).
static func _stroke(img: Image, a: Vector2, b: Vector2, r0: float, r1: float, c: Color) -> void:
	var n := maxi(int(a.distance_to(b)), 1)
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t)
		var r := lerpf(r0, r1, t)
		_disc(img, p.x, p.y, r, r, c)


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


## A dark rim round the silhouette, a little warmer than black.
static func _outline(img: Image) -> Image:
	var src := img.duplicate() as Image
	var size := img.get_size()
	for y in size.y:
		for x in size.x:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < size.x and q.y < size.y and src.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break
	return img


## A fluffy mass: a ring of round curls round a core, the lower right curls shaded.
static func _cloud(img: Image, cx: float, cy: float, rx: float, ry: float, base: Color, curl: float) -> void:
	var light := base.lightened(0.1)
	var dark := base.darkened(0.16)
	var deep := base.darkened(0.3)
	_blob(img, cx, cy, rx - 1.0, ry - 1.0, base, 0.0)
	var n := 12
	for i in n:
		var a := TAU * i / n
		var px := cx + cos(a) * (rx - curl * 0.6)
		var py := cy + sin(a) * (ry - curl * 0.6)
		for y in range(floori(py - curl), ceili(py + curl) + 1):
			for x in range(floori(px - curl), ceili(px + curl) + 1):
				var dx := x + 0.5 - px
				var dy := y + 0.5 - py
				var d := sqrt(dx * dx + dy * dy)
				if d > curl:
					continue
				var t := (dx * 0.5 + dy * 0.85) / curl
				var c := base
				if t > 0.55:
					c = dark if sin(a) < 0.55 else deep
				elif t < -0.45:
					c = light
				_px(img, x, y, 1, 1, c)


## Eyes: two rows, a pale glint above a dark pupil (or a shut lid).
static func _eye(img: Image, x: float, y: float, shut: bool, glint: Color, pupil: Color) -> void:
	if shut:
		_px(img, roundi(x), roundi(y) + 1, 2, 1, pupil)
		return
	_px(img, roundi(x), roundi(y), 2, 2, pupil)
	_p(img, x, y, glint)


# --- four-legged animals ----------------------------------------------------

static func _quad(kind: String, pose: String, frame: int, away: bool) -> Image:
	var s: Dictionary = QUADS[kind]
	var img := _blank(s.w, s.h)
	var sick := pose == "sick"
	var sit := pose == "sit"
	var down := not away
	var base: Color = s.body
	var head_c: Color = s.head
	var leg_c: Color = s.leg
	var hoof_c: Color = s.hoof
	if sick:
		base = base.lerp(Color("8a8478"), 0.28).darkened(0.06)
		head_c = head_c.lerp(Color("8a8478"), 0.28).darkened(0.06)
		leg_c = leg_c.lerp(Color("8a8478"), 0.2)
	var hi: float = s.hi
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
			_leg(img, s, k, swing, sit, leg_c.darkened(0.25), hoof_c.darkened(0.25), -1)
	# The tail goes behind the body seen from the front, over the rump seen from behind.
	if not away:
		_tail(img, s, bx, by, rx, ry, base, false, sick)
	# The body.
	if fleece:
		_cloud(img, bx, by, rx, ry, base, 3.0 if s.w > 30 else 2.2)
	else:
		_blob(img, bx, by, rx, ry, base, hi)
		_blob(img, bx + rx * 0.5, by + ry * 0.05, rx * 0.5, ry * 0.96, base, hi)    # haunch
		_blob(img, bx - rx * 0.5, by - ry * 0.02, rx * 0.46, ry * 0.94, base, hi)   # shoulder
		if s.has("urajiro"):   # cream chest and underside
			_blob(img, bx - rx * 0.62, by + ry * 0.42, rx * 0.34, ry * 0.62, s.muzzle, 0.0)
			_blob(img, bx + rx * 0.05, by + ry * 0.7, rx * 0.7, ry * 0.3, s.muzzle, 0.0)
		if s.has("ribs"):
			for i in 3:
				var rxp := bx - 4.0 + i * 3.0
				_px(img, roundi(rxp), roundi(by - ry * 0.25), 1, 3, base.darkened(0.2))
		if kind == "cow" and not sick:   # the udder
			_disc(img, bx + rx * 0.3, by + ry + 0.4, 2.6, 1.8, Color("d4aca4"))
	# Near legs over the body's lower edge.
	if not sick:
		for k in [0, 2]:
			_leg(img, s, k, swing, sit, leg_c, hoof_c, 1)
	else:   # folded: a forelimb tucked out in front, the hooves showing under the belly
		_disc(img, bx - rx * 0.55, by + ry - 0.5, 3.4, 1.6, leg_c)
		_px(img, roundi(bx - rx * 0.55) - 4, roundi(by + ry) - 1, 2, 2, hoof_c)
		_px(img, roundi(bx + rx * 0.4), roundi(by + ry) - 1, 3, 2, hoof_c)
	if sit:   # a haunch on the ground and a hind foot
		_blob(img, bx + rx * 0.35, by + ry * 0.35, rx * 0.55, ry * 0.9, base, hi)
		_px(img, roundi(bx + rx * 0.05), ground - 2, 5, 2, hoof_c)
	if away:
		_tail(img, s, bx, by, rx, ry, base, true, sick)
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
	_stroke(img, shoulder, head + Vector2(r * 0.5, r * 0.3), ry * 0.78 if not (fleece or kind == "sheep_shorn") else ry * 0.55, r * 0.75 if not fleece else r * 0.6, head_c if not (fleece or kind == "sheep_shorn") else base)
	_head(img, s, kind, head, r, pose, frame, away, sick, base, head_c)
	return img


static func _leg(img: Image, s: Dictionary, k: int, swing: int, sit: bool, c: Color, hoof: Color, near: int) -> void:
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
	_px(img, x, top, w, len, c)
	if s.leg_len >= 9:
		_px(img, x - (1 if w >= 2 else 0), top, w + (1 if w >= 2 else 0), 3, c)
	_px(img, x, top + len - 2, w, 2, hoof)
	_px(img, x, top + 2, 1, maxi(len - 4, 1), c.lightened(0.1))


static func _tail(img: Image, s: Dictionary, bx: float, by: float, rx: float, ry: float, base: Color, over: bool, sick: bool) -> void:
	var x := bx + rx - 1.0 if not over else bx + rx * 0.45
	match s.tail:
		"rope":
			var top := Vector2(x, by - ry * 0.7)
			var tip := Vector2(x + (1.0 if not over else 0.0), by + ry * 0.95 + (2.0 if sick else 0.0))
			_stroke(img, top, tip, 0.7, 0.7, base.darkened(0.15))
			_disc(img, tip.x, tip.y + 1.0, 1.6, 2.4, Color("181210"))
		"stub":
			_blob(img, x, by - ry * 0.25, 2.2 if s.w > 30 else 1.6, 2.2 if s.w > 30 else 1.6,
				base.darkened(0.05) if s.has("fleece") else base, 0.0)
		"curl":   # a ring curled over the back, a cream tip
			var cx := bx + rx * 0.7 if not over else bx + rx * 0.3
			var cy := by - ry - 1.0
			_disc(img, cx, cy, 3.4, 3.2, s.body.darkened(0.12))
			_disc(img, cx, cy, 2.4, 2.2, s.body.lightened(0.05))
			_disc(img, cx - 0.4, cy + 0.2, 1.1, 1.0, s.body.darkened(0.2))
			_px(img, roundi(cx) - 3, roundi(cy) + 1, 2, 2, s.muzzle)


static func _head(img: Image, s: Dictionary, kind: String, h: Vector2, r: float, pose: String, frame: int,
		away: bool, sick: bool, base: Color, head_c: Color) -> void:
	var fleece: bool = s.has("fleece")
	var muzzle: Color = s.muzzle
	var shut := sick
	var eye_g: Color = _EYE_LIGHT if kind in ["cow", "calf"] else Color("f8f0e0")
	var eye_p: Color = Color("4a2c1c") if kind in ["cow", "calf"] else Color("14100e")
	var flick := pose == "idle" and frame % 2 == 1
	# Ears first (behind the skull), the near one flicking.
	_ears(img, s, h, r, away, flick, head_c)
	if away:
		# The muzzle peeks out below and ahead of the skull.
		_blob(img, h.x - r * 0.25, h.y + r * 0.55, r * 0.55, r * 0.45, muzzle, 0.0)
	_blob(img, h.x, h.y, r * 1.08, r, head_c, s.hi)
	if not away:
		# The muzzle, wider seen from the front.
		var mw := r * 0.85
		var mh := r * 0.62
		_blob(img, h.x - r * 0.55, h.y + r * 0.62, mw, mh, muzzle, 0.1)
		if kind in ["cow", "calf", "dog"]:
			_p(img, h.x - r * 1.0, h.y + r * 0.45, Color("1a1412"))     # a nostril
			_p(img, h.x - r * 0.35, h.y + r * 0.45, Color("1a1412"))
		if kind == "dog":
			_blob(img, h.x + r * 0.05, h.y + r * 0.35, r * 0.55, r * 0.4, muzzle, 0.0)   # cream cheeks
			_blob(img, h.x - r * 0.55, h.y + r * 0.62, mw, mh, muzzle, 0.0)
			_px(img, roundi(h.x - r * 0.95), roundi(h.y + r * 0.2), 2, 2, Color("1a1412"))   # nose
			if pose != "sick":   # a tongue when sitting up
				if pose == "sit":
					_px(img, roundi(h.x - r * 0.6), roundi(h.y + r * 1.05), 2, 2, Color("d8707a"))
		elif kind in ["sheep", "sheep_shorn", "lamb"]:
			_px(img, roundi(h.x - r * 0.95), roundi(h.y + r * 0.5), 2, 1, Color("2a2220"))
		# Both eyes: the near one nearer the muzzle, the far one a little smaller in.
		_eye(img, h.x - r * 0.62, h.y - r * 0.28, shut, eye_g, eye_p)
		_eye(img, h.x + r * 0.2, h.y - r * 0.3, shut, eye_g, eye_p)
	if fleece:   # a wool cap and fringe
		_cloud(img, h.x + r * 0.3, h.y - r * 0.75, r * 0.95, r * 0.5, base, 1.6)
	if kind == "cow" or kind == "calf":
		if s.has("horns") and not sick:
			_px(img, roundi(h.x - r * 0.55), roundi(h.y - r) - 2, 1, 3, s.horns)
			_px(img, roundi(h.x + r * 0.45), roundi(h.y - r) - 2, 1, 3, s.horns)
		else:   # a tuft of forelock
			_px(img, roundi(h.x - 1.0), roundi(h.y - r) - 1, 3, 2, head_c.lightened(0.1))
	if kind == "dog" and away:
		_px(img, roundi(h.x - 1.0), roundi(h.y - r * 0.2), 2, 3, s.body.darkened(0.2))   # the nape


static func _ears(img: Image, s: Dictionary, h: Vector2, r: float, away: bool, flick: bool, c: Color) -> void:
	var inner: Color = Color("c8908a") if s.ear == "flap" else Color("e8b8a0")
	var y := h.y - r * 0.55
	if s.ear == "prick":
		for side in [-1, 1]:
			var x: float = h.x + side * r * 0.72 - (0.0 if side < 0 else 0.0)
			var up := 4.0 if not (flick and side > 0) else 3.0
			for i in int(up):
				var wid := maxi(2 - i / 2, 1)
				_px(img, roundi(x) - 1 + (1 if side > 0 else 0) - i / 3 * side, roundi(h.y - r * 0.5) - i, wid + 1, 1, c.darkened(0.1))
			_px(img, roundi(x) - (0 if side < 0 else 0), roundi(h.y - r * 0.5) - 1, 1, 2, inner)
		return
	# Flap ears out to the sides, lowered a pixel when one flicks.
	_disc(img, h.x - r * 1.15, y + (1.0 if flick else 0.0), r * 0.62, r * 0.3, c.darkened(0.08))
	_disc(img, h.x + r * 1.15, y, r * 0.6, r * 0.3, c.darkened(0.14))
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
	var white := _HEN.darkened(0.12) if sick else _HEN
	var shade := white.darkened(0.14)
	var deep := white.darkened(0.3)
	var swing := (frame % 2) * 2 - 1 if pose == "walk" else 0
	var ground: int = s.h - 3
	var bx := 15.0
	var by := 15.0 + (1.0 if sick else 0.0)
	# Legs and toes (the far one a shade darker).
	for k in 2:
		var off := swing * (1 if k == 0 else -1)
		var lift := 2 if off < 0 else 0
		var x := 11 + k * 5 + off
		var c := _LEG if k == 0 else _LEG.darkened(0.2)
		_px(img, x, by + 4 + (1 if k == 1 else 0), 1, ground - roundi(by) - 4 - lift - (1 if k == 1 else 0), c)
		var fy: int = ground - lift - (1 if k == 1 else 0)
		_px(img, x - 2, fy, 4, 1, c)
		_px(img, x - 1, fy - 1, 1, 1, c)
	# Tail feathers behind (front view) or over the rump (back view).
	var tail_over := away
	if not tail_over:
		_hen_tail(img, bx, by, white, shade, deep, away)
	# Body: a round breast, a back sloping to the tail.
	_blob(img, bx, by, 8.6, 6.4 + (0.6 if sick else 0.0), white, 0.0)
	_blob(img, bx + 2.5, by - 1.0, 6.2, 5.4, white, 0.0)
	_disc(img, bx - 0.5, by + 5.2, 6.4, 1.4, deep)   # the shaded belly
	# The folded wing with scalloped feather edges.
	_blob(img, bx + 1.0, by + 0.5, 5.8, 3.8, shade.lightened(0.05), 0.08)
	for i in 4:
		_px(img, roundi(bx - 3.0 + i * 2.5), roundi(by + 3.6) - (i % 2), 2, 1, deep)
	_px(img, roundi(bx - 1.0), roundi(by - 1.0), 5, 1, white.lightened(0.05))
	if tail_over:
		_hen_tail(img, bx, by, white, shade, deep, away)
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
	_blob(img, head.x, head.y, 3.4, 3.3, white, 0.04)
	var hx := head.x
	var hy := head.y
	# A comb of three points, and the wattle.
	for i in 3:
		_disc(img, hx - 1.5 + i * 1.6, hy - 3.6 - (1 if i == 1 else 0), 1.2, 1.4, _COMB)
	if not away:
		_px(img, roundi(hx) - 5, roundi(hy) + 0, 3, 1, _BEAK)           # beak
		_px(img, roundi(hx) - 4, roundi(hy) + 1, 2, 1, _BEAK.darkened(0.15))
		_disc(img, hx - 2.2, hy + 3.0, 0.9, 1.4, _COMB)                 # wattle
		_eye(img, hx - 1.8, hy - 1.4, sick, Color("fff8e8"), Color("14100e"))
		_disc(img, hx - 1.0, hy + 0.6, 1.5, 1.1, Color("e8c8c0"))     # earlobe cheek
	else:
		_px(img, roundi(hx) - 1, roundi(hy) + 1, 3, 2, deep)            # back of the neck feathers
	return img


static func _hen_tail(img: Image, bx: float, by: float, white: Color, shade: Color, deep: Color, away: bool) -> void:
	var x := bx + 6.5
	var fan := [[x, by - 2.0, 2.4, 4.6], [x + 2.0, by - 4.0, 2.0, 4.6], [x + 3.6, by - 2.5, 1.8, 4.0], [x + 0.8, by - 6.0, 2.0, 4.2]]
	if away:   # seen from behind the tail is a fan right in the middle
		fan = [[bx + 0.5, by - 4.5, 2.4, 4.8], [bx - 2.0, by - 3.5, 2.0, 4.2], [bx + 3.0, by - 3.5, 2.0, 4.2], [bx + 0.5, by - 7.0, 2.2, 3.4]]
	for f in fan:
		_blob(img, f[0], f[1], f[2], f[3], shade, 0.06)
		_disc(img, f[0], f[1] - f[3] * 0.65, f[2] * 0.8, f[3] * 0.3, deep)   # darker tips


static func _chick(pose: String, frame: int, away: bool) -> Image:
	var s: Dictionary = BIRDS.chick
	var img := _blank(s.w, s.h)
	var sick := pose == "sick"
	var body := _CHICK.lerp(Color("a8a088"), 0.3) if sick else _CHICK
	var swing := (frame % 2) * 2 - 1 if pose == "walk" else 0
	var ground: int = s.h - 3
	var bx := 10.0
	var by := 9.5 + (1.0 if sick else 0.0)
	for k in 2:
		var off := swing * (1 if k == 0 else -1)
		var lift := 1 if off < 0 else 0
		var x := 7 + k * 4 + off
		_px(img, x, ground - 3 - lift, 1, 3, _BEAK)
		_px(img, x - 1, ground - lift, 3, 1, _BEAK)
	_blob(img, bx, by, 6.0, 4.6 + (0.8 if sick else 0.0), body, 0.1)
	_px(img, roundi(bx) + 4, roundi(by) - 4, 2, 2, body.darkened(0.1))   # a tail tuft
	_px(img, roundi(bx) + 5, roundi(by) - 5, 1, 1, body.darkened(0.1))
	_blob(img, bx + 1.0, by + 0.8, 3.0, 2.0, body.darkened(0.1), 0.0)       # a stub of a wing
	var head := Vector2(5.0, 5.5)
	if pose == "peck":
		head = Vector2(4.0, ground - 3.5 + (frame % 2))
	elif sick:
		head = Vector2(5.0, 8.0)
	if away:
		head += Vector2(1.0, -0.5)
	_blob(img, head.x, head.y, 3.6, 3.4, body, 0.1)
	if not away:
		_px(img, roundi(head.x) - 5, roundi(head.y) + 0, 2, 1, _BEAK)
		_px(img, roundi(head.x) - 4, roundi(head.y) + 1, 2, 1, _BEAK.darkened(0.15))
		_eye(img, head.x - 1.6, head.y - 1.2, sick, Color("fff8e8"), Color("14100e"))
	_px(img, roundi(head.x), roundi(head.y) - 4, 1, 1, body.lightened(0.1))   # a tuft on the crown
	return img
