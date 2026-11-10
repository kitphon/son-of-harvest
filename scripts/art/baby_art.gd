class_name BabyArt
extends RefCounted
## The refined pass for the baby's pictures: the bamboo cradle, the baby held and the crawler
## carried (PlaceholderArt child:cradle / child:held / child:carry). The same look as FigureArt's
## figures (data/villager_art.json): every material in three tones (shade / base / lit) by the
## side of it that is open (light from the upper left), a line round the whole picture in the
## material's deep tone pulled towards the rim colour, no black outline. PlaceholderArt lays
## each picture in flat colours, one per material; refine() tones them.


## Our own numbers for the pieces only these pictures have (data/villager_art.json "baby").
static func colours() -> Dictionary:
	return FigureArt.villager_art().baby


## The picture `img` (flat material colours, the size kept) toned and lined. `fixed` are the
## colours left as they are (eyes, mouth, cheeks, dots, weave); a colour in `skins` is toned
## with the warm shade and shaded by its right side only (a shade under the chin read as a beard).
static func refine(img: Image, fixed: Array, skins: Array) -> Image:
	var a := FigureArt.villager_art()
	var size := img.get_size()
	var src := img.duplicate() as Image
	var keep := {}
	for c: Color in fixed:
		keep[c.to_html()] = true
	var skin_keys := {}
	for c: Color in skins:
		skin_keys[c.to_html()] = true
	var cache := {}   # colour key -> its tones
	for y in size.y:
		for x in size.x:
			var col := src.get_pixel(x, y)
			if col.a == 0.0 or keep.has(col.to_html()):
				continue
			var k := col.to_html()
			var skin := skin_keys.has(k)
			if not cache.has(k):
				cache[k] = FigureArt.tones(col, skin, a)
			var same := func(dx: int, dy: int) -> bool:
				var q: Vector2i = Vector2i(x + dx, y + dy)
				return q.x >= 0 and q.y >= 0 and q.x < size.x and q.y < size.y and src.get_pixelv(q) == col
			var lit: bool = not same.call(-1, 0) or not same.call(0, -1)
			var shade: bool = not same.call(1, 0) or (not same.call(0, 1) and not skin)
			var role := 2 if lit and not shade else (0 if shade and not lit else 1)
			img.set_pixel(x, y, cache[k][role])
	var rim := Color(str(a.rim))
	for y in size.y:
		for x in size.x:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= size.x or q.y >= size.y or src.get_pixelv(q).a == 0.0:
					continue
				var n := src.get_pixelv(q)
				var line: Color = cache[n.to_html()][3] if cache.has(n.to_html()) else n.darkened(0.55)
				line = line.lerp(rim, float(a.rim_mix))
				line.a = 1.0
				img.set_pixel(x, y, line)
				break
	return img
