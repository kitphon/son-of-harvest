class_name KoiArt
extends RefCounted
## The pictures of the carp streamers (koinobori, KoinoboriRules): the three carp (black, red,
## blue), the five-colour fukinagashi streamer and the spinning wheel on top of the pole. Our own
## pixel drawings, not a copy of anything. Every carp is a tube drawn along a bending spine from
## its mouth ring (the picture's anchor, `anchor`, where it hangs on the pole) to its forked tail,
## shaded in three tones lit from the upper left (light, base, dark) with a pale belly, a few
## scale marks, an eye and a one-pixel outline. Keys "koi:<id>:<level>:<frame>" (PlaceholderArt):
##  - `id`: black, red, blue (data/koinobori.json "carp"), stream or wheel;
##  - `level`: 0 limp, hanging straight down and narrow; 1 half filled, slanting down and
##    curling; 2 full, streaming out downwind (+x) (the wheel has only 0);
##  - `frame`: 0 or 1, the tail swung one way or the other (the wheel: 0 .. frames - 1, the
##    blades turned a sixth of their own period a frame).

const FILL := [0.45, 0.8, 1.0]          # the body's thickness at each level
const ANGLE := [1.5, 0.62, -0.03]       # the spine's first direction, radians down from +x
const WAVE := [0.14, 0.26, 0.3]         # the tail's sideways swing
const LIGHT := Vector2(-0.55, -0.83)    # towards the light, upper left
const OUTLINE_DARKEN := 0.55
const RING := Color("ece4c8")
const WHEEL_SIZE := 13


## The picture of `key`'s parts: `id`, `level`, `frame`.
static func make(id: String, level: int, frame: int) -> Image:
	if id == "wheel":
		return _wheel(frame)
	var cfg := KoinoboriRules.config()
	if id == "stream":
		var s: Dictionary = cfg.streamer
		var stripes: Array[Color] = []
		for c in s.stripes:
			stripes.append(Color(str(c)))
		return _tube(float(s.length), float(s.radius), level, frame, {"stripes": stripes, "stream": true})
	for c: Dictionary in cfg.carp:
		if str(c.id) == id:
			return _tube(float(c.length), float(c.radius), level, frame, c)
	return Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)


## The padding round a tube of `radius`, and so the anchor's x and y in its picture.
static func pad(radius: float) -> int:
	return int(ceil(radius)) + 2


## The picture's size of the carp or streamer of `length` and `radius`.
static func size_of(length: float, radius: float) -> int:
	return int(ceil(length)) + 2 * pad(radius)


static func _tube(length: float, radius: float, level: int, frame: int, look: Dictionary) -> Image:
	var p := pad(radius)
	var size := size_of(length, radius)
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var stream := bool(look.get("stream", false))
	var fillk: float = FILL[level]
	var steps := int(ceil(length))
	var swing := (1.0 if frame == 0 else -1.0)
	# the spine: points, directions, radii
	var pts: Array[Vector2] = []
	var nrm: Array[Vector2] = []
	var rad: Array[float] = []
	var pos := Vector2(p, p)
	for j in steps + 1:
		var s := float(j) / float(steps)
		var th: float = ANGLE[level] + (0.6 * s if level == 1 else 0.0) + float(WAVE[level]) * swing * sin(s * 2.6) * s
		var dir := Vector2(cos(th), sin(th))
		pts.append(pos)
		nrm.append(Vector2(-dir.y, dir.x))   # the body's lower side (down when it streams)
		rad.append(radius * fillk * _profile(s, stream))
		pos += dir * (length / float(steps))
	var tones := {}
	if not stream:
		for k in ["light", "base", "dark", "belly", "fin"]:
			tones[k] = Color(str(look[k]))
	var fin_start := 0.84
	for y in size:
		for x in size:
			var pp := Vector2(x + 0.5, y + 0.5)
			var best := -1
			var best_rho := 9.0
			for j in steps + 1:
				var r := rad[j]
				if r <= 0.0:
					continue
				var rho := pp.distance_to(pts[j]) / r
				if rho < best_rho:
					best_rho = rho
					best = j
			if best < 0 or best_rho > 1.0:
				continue
			var s := float(best) / float(steps)
			var r := rad[best]
			var off := (pp - pts[best]) / r        # the surface point, in radii from the spine
			var l := off.dot(nrm[best])            # across the body: -1 upper side .. +1 lower side
			if not stream and s > 0.92 and absf(l) < (s - 0.92) / 0.08 * 0.55:
				continue                            # the fork of the tail
			if stream and s > 0.96 and int(floor((l + 1.0) * 2.5)) % 2 == 0:
				continue                            # the hem's scallops
			var sh := off.dot(LIGHT)
			var col: Color
			if stream:
				var stripes: Array = look.stripes
				col = stripes[clampi(int(floor((l + 1.0) * 0.5 * stripes.size())), 0, stripes.size() - 1)]
				col = col.lightened(0.16) if sh > 0.45 else (col.darkened(0.24) if sh < -0.4 else col)
			else:
				col = tones.base
				if s >= fin_start:
					col = tones.fin
				elif l > 0.5:
					col = tones.belly
				if sh > 0.4:
					col = tones.light if s < fin_start and l <= 0.5 else col.lightened(0.14)
				elif sh < -0.35:
					col = tones.dark if s < fin_start and l <= 0.5 else col.darkened(0.2)
				elif s > 0.2 and s < fin_start and l <= 0.5 and (int(s * length) + int(roundf(l * r)) * 2) % 4 == 0:
					col = tones.dark.lerp(tones.base, 0.55)   # a scale mark
			img.set_pixel(x, y, col)
	if not stream:
		_eye(img, pts, nrm, rad, length, fillk, tones.dark)
	_ring(img, pts[0], nrm[0], maxf(radius * fillk * 0.6, 1.5), stream)
	_outline(img, tones.dark if not stream else Color("2a2030"))
	return img


## The body's thickness (0..1) at `s`, 0 at the mouth to 1 at the tail: a mouth ring, the belly
## swelling to the full round by the shoulders, then tapering to the tail's stalk and its fins.
static func _profile(s: float, stream: bool) -> float:
	if stream:
		return 1.0 - 0.4 * s
	if s < 0.28:
		var k := s / 0.28
		return lerpf(0.55, 1.0, k * k * (3.0 - 2.0 * k))
	if s < 0.84:
		return lerpf(1.0, 0.32, (s - 0.28) / 0.56)
	return minf(0.32 + 2.4 * (s - 0.84), 0.7)   # the tail fins spread


static func _eye(img: Image, pts: Array[Vector2], nrm: Array[Vector2], rad: Array[float], length: float, fillk: float, dark: Color) -> void:
	var j := clampi(int(round(maxf(2.5, length * 0.17))), 1, pts.size() - 1)
	var at := pts[j] - nrm[j] * rad[j] * 0.38
	var x := int(floor(at.x))
	var y := int(floor(at.y))
	if fillk < 0.6:
		_px(img, x, y, Color("141418"))
		return
	_px(img, x, y, Color("f6f2e4"))
	_px(img, x + 1, y, Color("f6f2e4"))
	_px(img, x, y + 1, Color("f6f2e4"))
	_px(img, x + 1, y + 1, Color("141418"))


## The mouth ring: a short pale bar across the mouth, where it is tied to the pole.
static func _ring(img: Image, at: Vector2, nrm: Vector2, half: float, stream: bool) -> void:
	var n := int(ceil(half * 2.0))
	for k in n + 1:
		var q := at + nrm * (-half + 2.0 * half * float(k) / float(maxi(n, 1)))
		_px(img, int(floor(q.x)), int(floor(q.y)), RING if not stream else Color("d8d0b4"))


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


## A darker pixel round the shape's outside (4-neighbours), `tone` a shade darker still.
static func _outline(img: Image, tone: Color) -> void:
	var edge := tone.darkened(OUTLINE_DARKEN)
	var w := img.get_width()
	var h := img.get_height()
	var add: Array[Vector2i] = []
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + (d as Vector2i)
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and img.get_pixel(q.x, q.y).a > 0.0:
					add.append(Vector2i(x, y))
					break
	for c in add:
		img.set_pixel(c.x, c.y, edge)


## The pinwheel on top of the pole (13 x 13, hub in the middle), seen a little aslant: six open
## vanes, gold and red in turn, lit from the upper left; `frame` turns them a sixth of the
## pair's period (so the frames run round smoothly). A gilt ball at the hub.
static func _wheel(frame: int) -> Image:
	var img := Image.create_empty(WHEEL_SIZE, WHEEL_SIZE, false, Image.FORMAT_RGBA8)
	var gold := Color("e8b830")
	var red := Color("c8402c")
	var c := (WHEEL_SIZE - 1) / 2.0
	var turn := float(frame) * TAU / 18.0
	for y in WHEEL_SIZE:
		for x in WHEEL_SIZE:
			var dx := (x + 0.5 - c - 0.5) / 0.8     # squashed across: the wheel faces the wind, we see it aslant
			var dy := y + 0.5 - c - 0.5
			var d := sqrt(dx * dx + dy * dy)
			if d > 5.8 or d < 1.3:
				continue
			var a := atan2(dy, dx) + turn
			var sector := a / (TAU / 6.0)
			var idx := posmod(int(floor(sector)), 6)
			var f: float = sector - floorf(sector)
			if f > 0.66:
				continue                              # the gap between two vanes
			var col := gold if idx % 2 == 0 else red
			var sh := Vector2(dx, dy).normalized().dot(LIGHT)
			col = col.lightened(0.18) if sh > 0.5 else (col.darkened(0.25) if sh < -0.4 else col)
			img.set_pixel(x, y, col)
	for y in range(int(c) - 1, int(c) + 2):    # the hub's gilt ball
		for x in range(int(c) - 1, int(c) + 2):
			if absf(x - c) + absf(y - c) < 2.2:
				img.set_pixel(x, y, Color("fff0a0") if (x < c and y < c) else Color("c89a20"))
	_outline(img, Color("5a3a18"))
	return img
