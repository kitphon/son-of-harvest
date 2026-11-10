class_name PortraitArt
extends RefCounted
## The refined pass for the text box portraits (PlaceholderArt's portrait:... and face:... keys),
## the same look as the figures' (FigureArt): every material of the head and shoulders in three
## tones lit from the upper left, the black part lines turned into the deep tone of the material
## they hold, and the lines on the outer silhouette pulled towards a dark rim. Numbers in
## data/portrait_art.json.
##
## A portrait is drawn on a transparent 40 x 40 picture first (the plain drawing: flat colours
## with LINE between parts), then refine() tones it, then the eyes, mouth and marks go on top
## and the background goes under.

const PATH := "res://data/portrait_art.json"
const LINE := Color("2a1e1e")   # the plain drawing's part lines (PlaceholderArt.OUTLINE)

static var _art := {}
static var _q: Image


## The numbers (data/portrait_art.json).
static func art() -> Dictionary:
	if _art.is_empty():
		_art = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _art


## The shade, base, lit and deep tones of material colour `col` by the portrait's numbers.
static func tones(col: Color, skin := false) -> Array:
	return FigureArt.tones(col, skin, art())


## The colour the eyes are drawn in.
static func eye() -> Color:
	return Color(str(art().get("eye", "2a2a3a")))


## The colour of the mouth: the skin's deep tone.
static func mouth(skin: Color) -> Color:
	return tones(skin, true)[3]


## Is `col` (a pixel) one of the shade / base / lit tones of material `base`?
static func is_tone(col: Color, base: Color, skin := false) -> bool:
	var k := _key(col)
	var tn := tones(base, skin)
	return k == _key(tn[0]) or k == _key(tn[1]) or k == _key(tn[2])


## Tones `img` in place. `mats` lists the materials drawn in it: {base: Color, skin: bool,
## extra: [[Color, role], ...]}, where the extras are the plain darker / lighter shades the
## drawing used for that material, put on the tone `role` (0 shade, 1 base: toned by its side,
## 2 lit, 3 deep). The data's own `materials` are added. Pixels of no material keep their colour.
static func refine(img: Image, mats: Array) -> void:
	var a := art()
	var all := mats.duplicate()
	for h in a.get("materials", []):
		all.append({"base": Color(str(h))})
	var mat := {}   # colour key -> [tones, role, skin, group]
	for i in all.size():
		var m: Dictionary = all[i]
		var tn := tones(m.base, bool(m.get("skin", false)))
		for e in m.get("extra", []):
			if not mat.has(_key(e[0])):
				mat[_key(e[0])] = [tn, int(e[1]), bool(m.get("skin", false)), i]
	for i in all.size():   # a base colour wins over another material's extra shade
		var m: Dictionary = all[i]
		mat[_key(m.base)] = [tones(m.base, bool(m.get("skin", false))), 1, bool(m.get("skin", false)), i]
	var src := img.duplicate() as Image
	var band := maxi(int(a.get("band", 1)), 1)
	var line_key := _key(LINE)
	var rim := Color(str(a.rim))
	var mix: float = a.rim_mix
	for y in img.get_height():
		for x in img.get_width():
			var col := src.get_pixel(x, y)
			if col.a == 0.0:
				continue
			var k := _key(col)
			if k == line_key:
				img.set_pixel(x, y, _line(src, x, y, mat, line_key, rim, mix))
				continue
			var m: Variant = mat.get(k)
			if m == null:
				continue
			var role: int = m[1]
			if role == 1:
				var lit := _open(src, x, y, Vector2i(-1, 0), band, m, mat, line_key) or _open(src, x, y, Vector2i(0, -1), band, m, mat, line_key)
				# Skin is shaded by its side only: a shade along the chin read as a beard.
				var shade := _open(src, x, y, Vector2i(1, 0), band, m, mat, line_key) \
					or (not bool(m[2]) and _open(src, x, y, Vector2i(0, 1), band, m, mat, line_key))
				role = 2 if lit and not shade else (0 if shade and not lit else 1)
			img.set_pixel(x, y, (m[0] as Array)[role])


## Is the part edge within `band` pixels of (x, y) in direction `d`? The edge is the background,
## a part line, or (for any material but skin, which lies under the hair) another material.
## The picture's own border is not an edge (the shoulders run off it).
static func _open(src: Image, x: int, y: int, d: Vector2i, band: int, m: Array, mat: Dictionary, line_key: String) -> bool:
	for i in range(1, band + 1):
		var p := Vector2i(x, y) + d * i
		if p.x < 0 or p.y < 0 or p.x >= src.get_width() or p.y >= src.get_height():
			return false
		var c := src.get_pixelv(p)
		if c.a == 0.0:
			return true
		var k := _key(c)
		if k == line_key:
			return true
		var other: Variant = mat.get(k)
		if other == null or int(other[3]) != int(m[3]):
			return not bool(m[2])
	return false


## A part line's new colour: the deep tone of the material beside it (right, up, left, down,
## then the corners), pulled towards the rim when it borders the background.
static func _line(src: Image, x: int, y: int, mat: Dictionary, line_key: String, rim: Color, mix: float) -> Color:
	var col := LINE.lerp(rim, mix)
	for d: Vector2i in [Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		var p := Vector2i(x, y) + d
		if p.x < 0 or p.y < 0 or p.x >= src.get_width() or p.y >= src.get_height():
			continue
		var m: Variant = mat.get(_key(src.get_pixelv(p)))
		if m != null:
			col = (m[0] as Array)[3]
			break
	col.a = 1.0
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var p := Vector2i(x, y) + d
		if p.x >= 0 and p.y >= 0 and p.x < src.get_width() and p.y < src.get_height() and src.get_pixelv(p).a == 0.0:
			return col.lerp(rim, mix)
	return col


## The colour as an RGBA8 picture stores it, as a key.
static func _key(col: Color) -> String:
	if _q == null:
		_q = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	_q.set_pixel(0, 0, col)
	return _q.get_pixel(0, 0).to_html()
