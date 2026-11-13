class_name HoshigakiArt
extends RefCounted
## The pictures of the drying persimmon strings (hoshigaki, HoshigakiRules, data/hoshigaki.json).
## Our own pixel drawing: a twisted straw rope (light and dark straw in turns) hanging from a small
## loop, the peeled persimmons tied to it by their stalks, each stalk's T-shaped cross piece
## (a dark bar) caught in the rope, the fruit hanging off it left and right in turn, its dried
## calyx on top. Each fruit is an acorn-shaped oval in three tones lit from the upper left
## (light, base, dark) of its drying stage, smaller and darker the longer it has hung; the last
## stage carries a pale sugar bloom. Keys "hoshigaki:<fruit>:<stage>:<big|small>" (PlaceholderArt):
## `big` the 3D picture (HoshigakiLayer), `small` the flat view's (HoshigakiView). The rope is
## the picture's middle column (`rope_x`); its top row is the hang point.

const LOOP := 2   # rows of rope loop above the first stalk
const TAIL := 2   # rows of rope tail below the last fruit


## The rope's column in a picture for `small` (the freshest fruit's width: fruit never cross it).
static func rope_x(small: bool) -> int:
	return _size(0, small).x


## The picture of a string of `fruit` persimmons at drying stage `st`.
static func make(fruit: int, st: int, small: bool) -> Image:
	var cfg := HoshigakiRules.config()
	var stages: Array = cfg.stages
	st = clampi(st, 0, stages.size() - 1)
	fruit = maxi(1, fruit)
	var look: Dictionary = stages[st]
	var step := HoshigakiRules.STEP_SMALL if small else HoshigakiRules.STEP_BIG
	var wmax := _size(0, small).x
	var c := wmax
	var w := _size(st, small).x
	var h := _size(st, small).y
	var width := 2 * wmax + 1
	var height := LOOP + (fruit - 1) * step + 1 + h + TAIL
	var img := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	var rope: Dictionary = cfg.rope
	var straw_l := Color(str(rope.light))
	var straw_d := Color(str(rope.dark))
	var stem := Color(str(rope.stem))
	var calyx := Color(str(rope.calyx))
	var light := Color(str(look.light))
	var base := Color(str(look.base))
	var dark := Color(str(look.dark))
	var bloom := Color(str(look.get("bloom", look.light)))
	# The rope: twisted straw, light and dark in turns of two rows, a loop on top.
	for y in height:
		img.set_pixel(c, y, straw_l if (y / 2) % 2 == 0 else straw_d)
	img.set_pixel(c, 0, straw_d)
	for i in fruit:
		var ty := LOOP + i * step   # the stalk's cross piece
		var left := i % 2 == 0
		var x0 := c - w if left else c + 1
		var mid := x0 + w / 2 if left else x0 + (w - 1) / 2
		# The T: the stalk's cross piece caught in the rope (a dark knot on it), the stalk reaching
		# out over the fruit's inner shoulder.
		img.set_pixel(c, ty, stem)
		img.set_pixel(c - 1 if left else c + 1, ty, stem)
		# The fruit under it: rows ty + 1 .. ty + h, narrowing to a point at the bottom.
		var cx := x0 + w / 2.0
		var cy := ty + 1 + h / 2.0
		for y in range(ty + 1, ty + 1 + h):
			for x in range(x0, x0 + w):
				var dx := (x + 0.5 - cx) / (w / 2.0)
				var dy := (y + 0.5 - cy) / (h / 2.0)
				var narrow := 1.0 + maxf(0.0, dy) * 0.35   # an acorn: narrower towards the point
				if dx * dx * narrow * narrow + dy * dy > 1.25:
					continue
				var lit := -0.75 * dx - 0.65 * dy   # > 0 towards the upper left, the light's side
				var col := base
				if lit > 0.35:
					col = light
				elif lit < -0.4:
					col = dark
				img.set_pixel(x, y, col)
		img.set_pixel(mid, ty + 1, calyx)   # the dried calyx on the fruit's top
		if look.has("bloom") and h >= 4 and (i % 3) != 2:
			img.set_pixel(x0 + (1 if left else w - 2), ty + 1 + h / 2, bloom)   # the sugar bloom
	return img


## The fruit's (w, h) in pixels at stage `st` (big or small).
static func _size(st: int, small: bool) -> Vector2i:
	var look: Dictionary = (HoshigakiRules.config().stages as Array)[st]
	var s: Array = look.small if small else look.big
	return Vector2i(int(s[0]), int(s[1]))
