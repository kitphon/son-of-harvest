class_name PondPlantArt
extends RefCounted
## The pictures of the farm pond's plants (PondPlantRules; PlaceholderArt
## "pondplant:<kind>:<stage>:<variant>"), lit from the upper left in two or three tones:
## - reed (16 x 28, standing): a clump of thin stems and long blade leaves; young and short in
##   spring, tall and green in summer with brown cattail heads, gold in fall, pale straw in winter.
## - iris (14 x 18, standing): a fan of sword leaves; `bloom` with violet flowers and their yellow
##   blaze, `fade` the leaves yellowing at the tips.
## - lily (12 x 10, seen from above, lying on the water): a round pad with its notch and a
##   darker rim, a smaller one beside it; `bloom` a pink flower on it, `fade` yellow-brown.

const VARIANTS := 4
const REED := {
	"young": [Color("6f9a3e"), Color("8ab450"), Color("557a30")],
	"tall": [Color("4f8a34"), Color("6aa443"), Color("3c6c28")],
	"gold": [Color("b39a4a"), Color("cdb565"), Color("8a7434")],
	"dry": [Color("a89a78"), Color("c2b594"), Color("847660")],
}
const HEAD := {"tall": Color("6b4423"), "gold": Color("5a3a20"), "dry": Color("6e5a44")}
const IRIS_LEAF: Array[Color] = [Color("3f7a3a"), Color("5a9a48"), Color("2f5e2c")]
const IRIS_FADE: Array[Color] = [Color("8a8a3e"), Color("a8a050"), Color("6a6a30")]
const IRIS_FLOWER: Array[Color] = [Color("5b4bb0"), Color("7d6ad0"), Color("41348a")]
const BLAZE := Color("f0d040")
const PAD := {
	"young": [Color("5f9a44"), Color("7ab456"), Color("467a32")],
	"full": [Color("4f8a3c"), Color("6aa64e"), Color("3d6e2f")],
	"bloom": [Color("4f8a3c"), Color("6aa64e"), Color("3d6e2f")],
	"fade": [Color("a89a40"), Color("c0b058"), Color("7e7030")],
}
const PETAL: Array[Color] = [Color("f2a6c0"), Color("fbd2df"), Color("d97c9e")]


static func make(kind: String, stage: String, variant: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%d" % [kind, stage, variant])
	match kind:
		"reed":
			return _reed(stage, rng)
		"iris":
			return _iris(stage, rng)
		"lily":
			return _lily(stage, rng)
	return Image.create(1, 1, false, Image.FORMAT_RGBA8)


static func _put(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


## A line of pixels from (x0, y0) up to (x1, y1), coloured by `col(t)` (t 0 at the foot, 1 at the tip).
static func _line(img: Image, x0: float, y0: float, x1: float, y1: float, col: Callable) -> void:
	var n := int(maxf(absf(x1 - x0), absf(y1 - y0))) + 1
	for i in n + 1:
		var t := float(i) / n
		_put(img, roundi(lerpf(x0, x1, t)), roundi(lerpf(y0, y1, t)), col.call(t))


static func _reed(stage: String, rng: RandomNumberGenerator) -> Image:
	var img := Image.create(16, 28, false, Image.FORMAT_RGBA8)
	var tones: Array = REED.get(stage, REED.tall)
	var tall := 13 if stage == "young" else (17 if stage == "dry" else 22)
	var foot := 27
	# Blade leaves: long thin arcs out to the sides, the left (lit) ones paler.
	for i in 6:
		var x0 := 6.0 + rng.randf_range(0, 4)
		var lean := rng.randf_range(-6.0, 6.0)
		var h := tall * rng.randf_range(0.45, 0.8)
		var lit: Color = tones[1] if lean < 0 else tones[0]
		_line(img, x0, foot, x0 + lean, foot - h, func(t: float) -> Color: return tones[2] if t < 0.2 else lit)
	# Stems: near upright, the tallest ones carrying a cattail head in summer, fall and winter.
	var stems := 5 if stage != "young" else 4
	for i in stems:
		var x0 := 4.0 + i * 2.0 + rng.randf_range(-0.5, 0.5)
		var h := tall * rng.randf_range(0.75, 1.0)
		if stage == "dry" and i % 2 == 1:
			h *= 0.6   # broken off in the cold
		var lean := rng.randf_range(-1.5, 1.5)
		var x1 := x0 + lean
		var c: Color = tones[1] if i < stems / 2 else tones[0]
		_line(img, x0, foot, x1, foot - h, func(t: float) -> Color: return tones[2] if t < 0.15 else c)
		if HEAD.has(stage) and i % 2 == 0 and h > tall * 0.8:
			var hx := roundi(x1)
			var hy := roundi(foot - h) + 2
			for dy in 5:
				_put(img, hx, hy + dy, HEAD[stage])
				_put(img, hx + 1, hy + dy, (HEAD[stage] as Color).darkened(0.25))
			_put(img, hx, hy, (HEAD[stage] as Color).lightened(0.2))
	return img


static func _iris(stage: String, rng: RandomNumberGenerator) -> Image:
	var img := Image.create(14, 18, false, Image.FORMAT_RGBA8)
	var tones: Array[Color] = IRIS_FADE if stage == "fade" else IRIS_LEAF
	var foot := 17
	# A fan of sword leaves from one foot, each two pixels wide at the base.
	for i in 7:
		var x0 := 5.0 + i * 0.6
		var lean := (i - 3) * 1.4 + rng.randf_range(-0.6, 0.6)
		var h := rng.randf_range(10.0, 15.0)
		var lit: Color = tones[1] if i < 3 else tones[0]
		_line(img, x0, foot, x0 + lean, foot - h, func(t: float) -> Color:
			if stage == "fade" and t > 0.7:
				return Color("b89a50")
			return tones[2] if t < 0.2 else lit)
		_line(img, x0 + 1, foot, x0 + 1 + lean * 0.8, foot - h * 0.6, func(_t: float) -> Color: return tones[2])
	if stage == "bloom":   # violet flowers held over the leaves, the blaze on the falls
		for f in [Vector2i(3, 4), Vector2i(9, 2), Vector2i(7, 7)].slice(0, 2 + rng.randi_range(0, 1)):
			_line(img, 6, foot - 6, f.x, f.y + 3, func(_t: float) -> Color: return tones[2])
			for d in [Vector2i(0, 0), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 2), Vector2i(1, 2), Vector2i(0, -1)]:
				var col: Color = IRIS_FLOWER[1] if d.x < 0 or d.y < 0 else (IRIS_FLOWER[2] if d.y == 2 else IRIS_FLOWER[0])
				_put(img, f.x + d.x, f.y + d.y, col)
			_put(img, f.x, f.y + 1, BLAZE)
	return img


static func _lily(stage: String, rng: RandomNumberGenerator) -> Image:
	var img := Image.create(12, 10, false, Image.FORMAT_RGBA8)
	var tones: Array = PAD.get(stage, PAD.full)
	var pads := [[Vector2(4.5, 5.0), 3.8 if stage != "young" else 3.0], [Vector2(9.0, 3.0), 2.2]]
	if rng.randf() < 0.5:
		pads[1][0] = Vector2(9.0, 7.0)
	for p in pads:
		var c: Vector2 = p[0]
		var r: float = p[1]
		var notch := rng.randf_range(0.0, TAU)
		for y in 10:
			for x in 12:
				var d := Vector2(x + 0.5, y + 0.5) - c
				var e := Vector2(d.x, d.y * 1.3).length()   # seen from above at the camera's slant: a little flattened
				if e > r:
					continue
				var a := absf(wrapf(d.angle() - notch, -PI, PI))
				if a < 0.35 and e > r * 0.2:
					continue   # the notch from the rim to the middle
				var col: Color = tones[0]
				if e > r - 1.0:
					col = tones[2]
				elif d.x + d.y < -r * 0.5:
					col = tones[1]
				_put(img, x, y, col)
	if stage == "bloom":   # a pink flower on the big pad
		var f := Vector2i(4, 4)
		for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1)]:
			_put(img, f.x + d.x, f.y + d.y, PETAL[1] if d.y < 0 else PETAL[0])
		_put(img, f.x - 1, f.y + 1, PETAL[2])
		_put(img, f.x + 1, f.y + 1, PETAL[2])
		_put(img, f.x, f.y, BLAZE)
	return img
