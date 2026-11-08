class_name RoofArt
extends RefCounted
## Roofs seen from above for the flat view, in the pixel style of the other art: PlaceholderArt
## "roof:<material>:<shape>:<storeys>:<w>:<h>" (w and h in pixels). Materials: kawara (grey-blue
## clay tile rolls, the village houses and the barn), thatch (the coop's straw-gold grass) and
## kaya (the farmhouse's old grey-brown thatch). Shapes: gable (two slopes under one ridge) and
## hip (four slopes, the hips running to the corners). Two storeys: a pent roof round the lower
## floor with the main roof standing in from it (LitSpots.UPPER_INSET). Light from the upper
## left, as in the rest of the art: the north and west slopes are lit, the south and east ones
## shaded. The rolls and strands run down each slope, as the 3D view's roofs do (Minka).

const INSET := 5   # LitSpots.UPPER_INSET (0.3 of a cell) in pixels
const SHADE := {"n": 1.14, "w": 1.06, "s": 0.92, "e": 0.8}   # a slope's brightness by the way it faces

const KAWARA := {
	"base": Color("5a6470"), "dark": Color("3a424c"), "crown": Color("7a8692"), "mid": Color("68737f"),
	"line": Color("444c56"), "lip": Color("2e343c"), "end": Color("9aa6b0"), "cap": Color("8e9aa6"), "cap_dark": Color("2a3038"),
}
const THATCH := {
	"base": Color("a88a52"), "dark": Color("806838"), "crown": Color("c4a868"), "mid": Color("94784a"),
	"line": Color("6a5430"), "lip": Color("54442a"), "end": Color("c4a868"), "cap": Color("7a6234"), "cap_dark": Color("4a3a20"),
}
const KAYA := {
	"base": Color("85714e"), "dark": Color("625236"), "crown": Color("a08c64"), "mid": Color("76633f"),
	"line": Color("5a4a32"), "lip": Color("463a28"), "end": Color("a08c64"), "cap": Color("6a5a3c"), "cap_dark": Color("3c3220"), "moss": Color("6a7444"),
}


## The PlaceholderArt key of a roof over `size` pixels.
static func key(material: String, shape: String, storeys: int, size: Vector2i) -> String:
	return "roof:%s:%s:%d:%d:%d" % [material, shape, storeys, size.x, size.y]


## The picture for a "roof:..." key's parts.
static func draw(parts: PackedStringArray) -> Image:
	var material := parts[1]
	var hip := parts[2] == "hip"
	var storeys := int(parts[3])
	var w := int(parts[4])
	var h := int(parts[5])
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var pal: Dictionary = {"kawara": KAWARA, "thatch": THATCH, "kaya": KAYA}.get(material, KAWARA)
	if storeys >= 2 and w > INSET * 4 and h > INSET * 4:
		_paint(img, Rect2i(0, 0, w, h), pal, material, true)
		var up := Rect2i(INSET, INSET, w - INSET * 2, h - INSET * 2)
		# The upper roof's shadow on the pent roof, to its south and east.
		var shade := Color(0, 0, 0, 0.35)
		for y in range(INSET + 2, INSET + up.size.y + 2):
			for x in range(INSET + 2, INSET + up.size.x + 2):
				if x < w and y < h:
					img.set_pixel(x, y, img.get_pixel(x, y).blend(shade))
		_paint(img, up, pal, material, hip)
	else:
		_paint(img, Rect2i(0, 0, w, h), pal, material, hip)
	return img


static func _noise(a: int, b: int) -> float:
	var n: int = (a * 73856093) ^ (b * 19349663) ^ 83492791
	n = (n ^ (n >> 13)) * 1274126177
	return float(posmod(n >> 8, 1024)) / 1024.0


static func _shaded(c: Color, face: String) -> Color:
	var k: float = SHADE[face]
	return Color(clampf(c.r * k, 0, 1), clampf(c.g * k, 0, 1), clampf(c.b * k, 0, 1), 1.0)


## Paints one roof over `r` of `img`. A hip roof's four slopes meet along the diagonals; a gable's
## two meet at the ridge across the middle, its ends cut off flat (the verge).
static func _paint(img: Image, r: Rect2i, pal: Dictionary, material: String, hip: bool) -> void:
	var w := r.size.x
	var h := r.size.y
	for y in h:
		for x in w:
			var d := {"n": y, "s": h - 1 - y, "w": x if hip else 9999, "e": (w - 1 - x) if hip else 9999}
			var edge := mini(mini(y, h - 1 - y), mini(x, w - 1 - x))   # the eave or verge, nearest side
			var best := "n"
			var best_d := 9999
			var second := 9999
			for f in ["n", "w", "s", "e"]:
				var v: int = d[f]
				if v < best_d:
					second = best_d
					best_d = v
					best = f
				elif v < second:
					second = v
			var c: Color
			if best_d == second and hip and best_d < 9999 and not ((best == "n" or best == "s") and absi(d.n - d.s) <= 2 and d.w > d.n and d.e > d.n and d.w > d.s and d.e > d.s):
				# Where two slopes meet in a hip: capped in tile.
				c = pal.cap
			elif absi(d.n - d.s) <= 2 and (best == "n" or best == "s") and (not hip or (d.w > best_d and d.e > best_d)):
				# The ridge: a capped line, lit on its upper edge, dark below it.
				var up: bool = d.n - d.s <= 0
				c = pal.crown if up and absi(d.n - d.s) == 2 else (pal.cap if up else pal.cap_dark)
				if material == "kawara" and (x % 4) == 0:
					c = pal.cap_dark   # the capping tiles' joints
			else:
				c = _slope(pal, material, best, best_d, x, y)
			# The eave's dark lip, and on the south and east slopes a row of round tile ends under it.
			if edge == 0:
				c = pal.lip
			elif edge == 1 and best_d == 1:
				if material == "kawara" and (best == "s" or best == "e"):
					c = pal.end if ((x if best == "s" else y) % 4) in [1, 2] else pal.line
				elif material != "kawara":
					c = pal.line.lerp(pal.base, 0.3)   # thatch's cut edge, the straw ends in shadow
			img.set_pixel(r.position.x + x, r.position.y + y, c)
	# Hip lines get a dark pixel beside them, so they read as raised.
	if hip:
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var px := r.position + Vector2i(x, y)
				if img.get_pixel(px.x, px.y) == pal.cap and img.get_pixel(px.x + 1, px.y) != pal.cap and (x + y) % 2 == 0:
					img.set_pixel(px.x + 1, px.y, pal.cap_dark)


## A pixel of a slope facing `face`: `along` pixels in from its eave.
static func _slope(pal: Dictionary, material: String, face: String, along: int, x: int, y: int) -> Color:
	var across := x if face == "n" or face == "s" else y
	if material == "kawara":
		# Rounded rolls 4 px wide (a dark trough, a lit crown), a tile end every 4 px down the slope.
		var base: Color = pal.base
		match across % 4:
			0: base = pal.dark
			1: base = pal.crown
			2: base = pal.mid
		if along % 4 == 3:
			base = base.lerp(pal.line, 0.6)
		return _shaded(base, face)
	# Thatch: strands running down the slope in lighter and darker straw, a shadow where a course laps.
	var t := _noise(across, 1 if face == "n" or face == "w" else 2)
	var c: Color = pal.base
	if t < 0.25:
		c = pal.mid
	elif t > 0.8:
		c = pal.crown
	elif t > 0.65:
		c = pal.dark
	if _noise(across, along / 5 + 7) > 0.8:
		c = pal.crown if t > 0.5 else pal.dark
	if along % 7 == 6:
		c = c.lerp(pal.line, 0.55)
	if pal.has("moss") and _noise(x, y + 31) > 0.975:
		c = pal.moss
	return _shaded(c, face)
