class_name ItemArt
extends RefCounted
## The refined pass for the item and tool icons PlaceholderArt draws (ui:tool:*, ui:seeds:*,
## ui:item:*, item:<crop>, the animal goods): the same look as the figures (FigureArt) and the
## animals (AnimalArt). PlaceholderArt lays each icon in flat colours, one per material; refine()
## tones every material in three tones (shade / base / lit) by the side of its part a pixel is
## open to (light from the upper left), lays the lower and right edge of a part over another
## material in the part's deep tone, and rims the silhouette in the deep tone of the material it
## touches, pulled towards a dark rim colour, instead of the old near-black outline. Numbers in
## data/item_art.json. Same keys and sizes as before.

const PATH := "res://data/item_art.json"

static var _data := {}


static func art() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _data


## The shade, base, lit and deep tones of a material colour (FigureArt.tones with our numbers).
static func tones(c: Color) -> Array:
	return FigureArt.tones(c, false, art())


## The rim colour beside a material `c`: its deep tone pulled towards the rim colour.
static func rim_of(c: Color) -> Color:
	var a := art()
	var line: Color = (tones(c)[3] as Color).lerp(Color(str(a.rim)), float(a.rim_mix))
	line.a = 1.0
	return line


## `img` (flat material colours) toned, lined and rimmed in place; the size is kept. `fixed` are
## colours left as they are (small marks: tuber eyes, ribs, dots, sparkles); the rim beside one
## is its own colour darkened by fixed_dark, pulled the same way.
static func refine(img: Image, fixed: Array = []) -> Image:
	var a := art()
	var size := img.get_size()
	var src := img.duplicate() as Image
	var keep := {}
	for c: Color in fixed:
		keep[FigureArt._key(c)] = true
	var cache := {}   # colour key -> its tones
	var at := func(x: int, y: int) -> Color:
		if x < 0 or y < 0 or x >= size.x or y >= size.y:
			return Color(0, 0, 0, 0)
		return src.get_pixel(x, y)
	for y in size.y:
		for x in size.x:
			var col := src.get_pixel(x, y)
			var k := col.to_html()
			if col.a == 0.0 or keep.has(k):
				continue
			if not cache.has(k):
				cache[k] = tones(col)
			var l: Color = at.call(x - 1, y)
			var u: Color = at.call(x, y - 1)
			var r: Color = at.call(x + 1, y)
			var d: Color = at.call(x, y + 1)
			# The lower / right edge of a part over another material (not a piece one pixel thin).
			var part := (r.a > 0.0 and r != col and l == col) or (d.a > 0.0 and d != col and u == col)
			var lit := l != col or u != col
			var shade := r != col or d != col
			var role := 3 if part else (2 if lit and not shade else (0 if shade and not lit else 1))
			img.set_pixel(x, y, cache[k][role])
	var rim := Color(str(a.rim))
	for y in size.y:
		for x in size.x:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for dv in [Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)]:
				var q: Vector2i = Vector2i(x, y) + dv
				if q.x < 0 or q.y < 0 or q.x >= size.x or q.y >= size.y or src.get_pixelv(q).a == 0.0:
					continue
				var n := src.get_pixelv(q)
				var line: Color
				if cache.has(n.to_html()):
					line = (cache[n.to_html()][3] as Color).lerp(rim, float(a.rim_mix))
				else:
					line = n.darkened(float(a.fixed_dark)).lerp(rim, float(a.rim_mix))
				line.a = 1.0
				img.set_pixel(x, y, line)
				break
	return img
