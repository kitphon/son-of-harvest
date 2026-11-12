class_name BirdArt
extends RefCounted
## The small birds as pixel sprites, drawn in code (our own designs): a swallow, a crow, a grey
## heron and a sparrow. Keys "bird:<kind>:<pose>:<frame>[:r]" (PlaceholderArt hands them here).
##
## - Poses: swallow and crow "fly" (frames 0 wings up, 1 wings out, 2 wings down); heron "stand"
##   (0 upright, 1 peering with the neck lowered) and "fly" (0..2); sparrow "stand", "peck" (head
##   to the ground), "hop" (feet tucked) and "fly" (0 wings up, 1 down).
## - Drawn facing screen-left, the head at the left; the key's last part ":r" is the picture
##   mirrored (a bird heading right). The bottom row is the feet (or the belly of a flier), so a
##   bird sits on its place.
## - The same refined pass as the figures and animals (FigureArt, AnimalArt): every part in three
##   tones (shade / base / lit, lit from the upper left) and a rim in the part's own deep tone on
##   the lower and right edges instead of a black outline. Colours in data/birds.json "art" and
##   "tone". Each picture is a pure function of its key, so a frame is repeatable.

const SIZES := {
	"swallow": Vector2i(14, 10), "crow": Vector2i(18, 12),
	"heron:stand": Vector2i(16, 30), "heron:fly": Vector2i(30, 14),
	"sparrow:ground": Vector2i(10, 7), "sparrow:fly": Vector2i(10, 8),
}
const POSES := {
	"swallow": {"fly": 3}, "crow": {"fly": 3},
	"heron": {"stand": 2, "fly": 3}, "sparrow": {"stand": 1, "peck": 1, "hop": 1, "fly": 2},
}


## The picture of a bird (facing left, or mirrored when `right`).
static func make(kind: String, pose: String, frame: int, right := false) -> Image:
	var size := size_of(kind, pose)
	var g := PackedStringArray()
	g.resize(size.x * size.y)
	match kind:
		"swallow":
			_swallow(g, size, frame)
		"crow":
			_crow(g, size, frame)
		"heron":
			if pose == "stand":
				_heron_stand(g, size, frame)
			else:
				_heron_fly(g, size, frame)
		_:
			_sparrow(g, size, pose, frame)
	var img := _finish(g, size, kind)
	if right:
		img.flip_x()
	return img


static func size_of(kind: String, pose := "fly") -> Vector2i:
	match kind:
		"heron":
			return SIZES["heron:stand"] if pose == "stand" else SIZES["heron:fly"]
		"sparrow":
			return SIZES["sparrow:fly"] if pose == "fly" else SIZES["sparrow:ground"]
	return SIZES[kind]


## How many frames a pose has (0 for a pose the kind does not have).
static func frames(kind: String, pose: String) -> int:
	return int((POSES.get(kind, {}) as Dictionary).get(pose, 0))


# --- shapes -------------------------------------------------------------------------------------

static func _px(g: PackedStringArray, s: Vector2i, x: int, y: int, part: String) -> void:
	if x >= 0 and y >= 0 and x < s.x and y < s.y:
		g[y * s.x + x] = part


static func _disc(g: PackedStringArray, s: Vector2i, part: String, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in s.y:
		for x in s.x:
			var dx := (float(x) + 0.5 - cx) / rx
			var dy := (float(y) + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				g[y * s.x + x] = part


static func _tri(g: PackedStringArray, s: Vector2i, part: String, a: Vector2, b: Vector2, c: Vector2) -> void:
	var d := (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
	if absf(d) < 0.0001:
		return
	for y in s.y:
		for x in s.x:
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			var l1 := ((b.y - c.y) * (p.x - c.x) + (c.x - b.x) * (p.y - c.y)) / d
			var l2 := ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) / d
			var l3 := 1.0 - l1 - l2
			if l1 >= -0.08 and l2 >= -0.08 and l3 >= -0.08:
				g[y * s.x + x] = part


static func _line(g: PackedStringArray, s: Vector2i, part: String, a: Vector2, b: Vector2, thick := 1) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		for t in thick:
			_px(g, s, int(floor(p.x)) + t, int(floor(p.y)), part)


static func _swallow(g: PackedStringArray, s: Vector2i, frame: int) -> void:
	_tri(g, s, "back", Vector2(9, 5), Vector2(13.5, 2.5), Vector2(10, 6.2))   # the forked tail
	_tri(g, s, "back", Vector2(9, 5.2), Vector2(13.5, 8.2), Vector2(10, 6.2))
	_disc(g, s, "back", 7.0, 5.4, 3.7, 1.6)
	_disc(g, s, "back", 3.6, 4.8, 1.6, 1.4)
	_disc(g, s, "belly", 7.0, 6.1, 3.0, 0.9)
	_disc(g, s, "throat", 3.0, 5.6, 1.1, 0.8)
	_px(g, s, 1, 5, "beak")
	match frame:
		0:
			_tri(g, s, "wing", Vector2(5, 4.5), Vector2(8.5, 4.5), Vector2(10.5, 0.2))
		1:
			_tri(g, s, "wing", Vector2(5, 4.8), Vector2(8.5, 4.8), Vector2(13.0, 3.2))
		_:
			_tri(g, s, "wing", Vector2(5, 5.6), Vector2(8.5, 5.6), Vector2(10.0, 9.8))


static func _crow(g: PackedStringArray, s: Vector2i, frame: int) -> void:
	_tri(g, s, "body", Vector2(12, 5), Vector2(17.5, 4.6), Vector2(17.5, 8.4))
	_disc(g, s, "body", 9.0, 6.4, 4.6, 2.2)
	_disc(g, s, "body", 4.6, 5.4, 2.1, 1.9)
	_tri(g, s, "beak", Vector2(0.4, 5.2), Vector2(3.0, 4.2), Vector2(3.0, 6.4))
	match frame:
		0:
			_tri(g, s, "wing", Vector2(6, 5), Vector2(12.5, 5), Vector2(11.5, 0.2))
			_tri(g, s, "wing", Vector2(6, 5), Vector2(11.5, 0.2), Vector2(5.5, 1.2))
		1:
			_tri(g, s, "wing", Vector2(6, 5.4), Vector2(12.5, 5.4), Vector2(17.0, 3.2))
			_tri(g, s, "wing", Vector2(6, 5.4), Vector2(17.0, 3.2), Vector2(9.5, 2.0))
		_:
			_tri(g, s, "wing", Vector2(6, 6.4), Vector2(12.5, 6.4), Vector2(12.5, 11.8))
			_tri(g, s, "wing", Vector2(6, 6.4), Vector2(12.5, 11.8), Vector2(6.0, 10.6))


static func _heron_stand(g: PackedStringArray, s: Vector2i, frame: int) -> void:
	_line(g, s, "leg", Vector2(8, 15), Vector2(8, 28))
	_line(g, s, "leg", Vector2(10, 15), Vector2(10, 27))
	_line(g, s, "leg", Vector2(6, 29), Vector2(9, 29))
	_line(g, s, "leg", Vector2(9, 28), Vector2(12, 28))
	_tri(g, s, "body", Vector2(12, 11), Vector2(15.5, 15), Vector2(11, 14.5))   # the tail end
	_disc(g, s, "body", 9.0, 13.0, 4.8, 2.9)
	_disc(g, s, "wing", 10.0, 13.2, 3.6, 1.8)
	if frame == 0:   # upright: the neck rises in an S
		_line(g, s, "neck", Vector2(6, 12), Vector2(5.5, 9), 2)
		_line(g, s, "neck", Vector2(5, 9), Vector2(4.5, 5), 2)
		_disc(g, s, "neck", 4.5, 3.4, 1.8, 1.5)
		_line(g, s, "crest", Vector2(5.5, 2.4), Vector2(10, 3.4))
		_tri(g, s, "beak", Vector2(0.4, 4.4), Vector2(3.0, 2.8), Vector2(3.4, 4.2))
	else:   # peering: the neck folded down, head forward
		_line(g, s, "neck", Vector2(6, 12), Vector2(4.5, 10.5), 2)
		_line(g, s, "neck", Vector2(4, 10), Vector2(3.5, 8.5), 2)
		_disc(g, s, "neck", 3.2, 8.0, 1.8, 1.5)
		_line(g, s, "crest", Vector2(4.4, 7.0), Vector2(8.5, 8.6))
		_tri(g, s, "beak", Vector2(0.2, 11.0), Vector2(2.2, 8.2), Vector2(3.6, 9.0))


static func _heron_fly(g: PackedStringArray, s: Vector2i, frame: int) -> void:
	_line(g, s, "leg", Vector2(20, 8), Vector2(29, 9.6))
	_line(g, s, "leg", Vector2(20, 8.8), Vector2(29, 10.8))
	_disc(g, s, "body", 15.0, 7.4, 5.2, 2.1)
	_disc(g, s, "neck", 9.5, 6.4, 2.2, 1.5)   # the neck tucked into an S
	_disc(g, s, "neck", 7.0, 6.0, 1.5, 1.3)
	_line(g, s, "beak", Vector2(3, 6.6), Vector2(5.8, 6.1))
	match frame:
		0:
			_tri(g, s, "wing", Vector2(12, 6), Vector2(19.5, 6), Vector2(20.5, 0.2))
			_tri(g, s, "wing", Vector2(12, 6), Vector2(20.5, 0.2), Vector2(9, 1.0))
		1:
			_tri(g, s, "wing", Vector2(12, 6.6), Vector2(19.5, 6.6), Vector2(29.5, 4.2))
			_tri(g, s, "wing", Vector2(12, 6.6), Vector2(29.5, 4.2), Vector2(8, 3.2))
		_:
			_tri(g, s, "wing", Vector2(12, 8), Vector2(19.5, 8), Vector2(20.5, 13.6))
			_tri(g, s, "wing", Vector2(12, 8), Vector2(20.5, 13.6), Vector2(10, 12.8))


static func _sparrow(g: PackedStringArray, s: Vector2i, pose: String, frame: int) -> void:
	if pose == "fly":
		_disc(g, s, "back", 5.2, 4.0, 2.8, 1.5)
		_disc(g, s, "back", 2.6, 3.4, 1.5, 1.3)
		_disc(g, s, "belly", 5.0, 4.6, 2.2, 0.8)
		_px(g, s, 0, 3, "beak")
		_tri(g, s, "wing", Vector2(7.6, 4.0), Vector2(9.9, 3.4), Vector2(9.9, 5.4))
		if frame == 0:
			_tri(g, s, "wing", Vector2(3.6, 3.4), Vector2(7.0, 3.4), Vector2(7.6, 0.2))
		else:
			_tri(g, s, "wing", Vector2(3.6, 4.4), Vector2(7.0, 4.4), Vector2(7.6, 7.8))
		return
	var low := pose == "peck"
	var hy := 4.0 if low else 2.7
	_disc(g, s, "back", 5.2, 3.9 if low else 4.0, 3.0, 1.7)
	_disc(g, s, "belly", 4.8, 4.8 if low else 4.9, 2.3, 1.1)
	_disc(g, s, "back", 2.6, hy, 1.5, 1.4)
	_px(g, s, 1, int(hy) + 1, "bib")
	_px(g, s, 2, int(hy) + 1, "bib")
	_px(g, s, 2, int(hy), "cheek")
	_px(g, s, 3, int(hy), "cheek")
	_px(g, s, 0, int(hy) + 1 if low else int(hy), "beak")
	_disc(g, s, "wing", 5.6, 3.8 if low else 3.9, 2.0, 1.1)
	_tri(g, s, "wing", Vector2(7.5, 3.4), Vector2(9.9, 2.4 if low else 3.6), Vector2(9.9, 5.4 if not low else 4.2))
	if pose == "hop":   # legs spread for the landing
		_px(g, s, 2, 6, "beak")
		_px(g, s, 6, 6, "beak")
	else:
		_px(g, s, 3, 6, "beak")
		_px(g, s, 5, 6, "beak")


# --- tones --------------------------------------------------------------------------------------

## Colours the grid: each part's base colour (data/birds.json "art"), shade / lit by where the pixel
## is in its part (lit upper left), a deep rim on the lower and right edges of parts with some body.
static func _finish(g: PackedStringArray, s: Vector2i, kind: String) -> Image:
	var cfg := BirdRules.config()
	var art: Dictionary = (cfg.art as Dictionary)[kind]
	var tone: Dictionary = cfg.tone
	var cool := Color(str(tone.cool))
	var warm := Color(str(tone.warm))
	var box := {}   # part -> Rect2i of its pixels
	var count := {}
	for y in s.y:
		for x in s.x:
			var part := g[y * s.x + x]
			if part == "":
				continue
			count[part] = int(count.get(part, 0)) + 1
			var r := Rect2i(x, y, 1, 1)
			box[part] = r if not box.has(part) else (box[part] as Rect2i).merge(r)
	var img := Image.create(s.x, s.y, false, Image.FORMAT_RGBA8)
	for y in s.y:
		for x in s.x:
			var part := g[y * s.x + x]
			if part == "":
				continue
			var base := Color(str(art.get(part, art.values()[0])))
			var r: Rect2i = box[part]
			var rel := ((float(x - r.position.x) + 0.5) / float(r.size.x) + (float(y - r.position.y) + 0.5) / float(r.size.y)) * 0.5
			var col := base
			if rel < 0.36:
				col = base.lerp(warm, float(tone.lit))
			elif rel > 0.68:
				col = base.lerp(cool, float(tone.shade))
			var open_right := _empty(g, s, x + 1, y)
			var open_below := _empty(g, s, x, y + 1)
			if (open_right or open_below) and minf(r.size.x, r.size.y) >= 3 and int(count[part]) > 8:
				col = base.lerp(cool, float(tone.deep))
			elif (open_right or open_below) and rel > 0.5:
				col = base.lerp(cool, float(tone.shade))
			img.set_pixel(x, y, col)
	return img


static func _empty(g: PackedStringArray, s: Vector2i, x: int, y: int) -> bool:
	return x < 0 or y < 0 or x >= s.x or y >= s.y or g[y * s.x + x] == ""
