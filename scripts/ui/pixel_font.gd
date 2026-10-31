class_name PixelFont
extends RefCounted
## Our bitmap font, read from data/font_pixel.json and packed into a FontFile, so Labels
## draw it like any font. Glyphs are keyed by character (code point), so Japanese can be
## added to the data later; nothing here assumes ASCII or a fixed width.

const PATH := "res://data/font_pixel.json"

static var _data: Dictionary
static var _font: FontFile


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _data


## Line height in pixels (the font size Labels should ask for).
static func size() -> int:
	return int(data().ascent) + int(data().descent)


static func font() -> FontFile:
	if _font == null:
		_font = _build()
	return _font


static func has_char(ch: String) -> bool:
	return data().glyphs.has(ch)


## The characters of `text` the font cannot draw (empty when it can draw all of it).
static func missing(text: String) -> String:
	var out := ""
	for ch in text:
		if ch != "\n" and not has_char(ch) and not ch in out:
			out += ch
	return out


## Width in pixels of one line of text, the same advances the FontFile uses.
static func width(text: String) -> int:
	var w := 0
	for ch in text:
		if has_char(ch):
			w += _glyph_w(ch) + int(data().spacing)
	return maxi(w - int(data().spacing), 0)


static func _glyph_w(ch: String) -> int:
	var rows: Array = data().glyphs[ch]
	return String(rows[0]).length()


## All glyphs side by side in one white-on-clear atlas, 1 px apart.
static func atlas() -> Image:
	var d := data()
	var w := 0
	for ch in d.glyphs:
		w += _glyph_w(ch) + 1
	var img := Image.create_empty(maxi(w, 1), size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var x := 0
	for ch in d.glyphs:
		var rows: Array = d.glyphs[ch]
		for y in rows.size():
			var row := String(rows[y])
			for i in row.length():
				if row[i] == "#":
					img.set_pixel(x + i, y, Color.WHITE)
		x += _glyph_w(ch) + 1
	return img


static func _build() -> FontFile:
	var d := data()
	var s := size()
	var key := Vector2i(s, 0)
	var f := FontFile.new()
	f.font_name = "Harvest Son Pixel"
	f.fixed_size = s
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.generate_mipmaps = false
	f.allow_system_fallback = false
	f.set_cache_ascent(0, s, int(d.ascent))
	f.set_cache_descent(0, s, int(d.descent))
	f.set_texture_image(0, key, 0, atlas())
	var x := 0
	for ch in d.glyphs:
		var cp := String(ch).unicode_at(0)
		var gw := _glyph_w(ch)
		f.set_glyph_advance(0, s, cp, Vector2(gw + int(d.spacing), 0))
		f.set_glyph_offset(0, key, cp, Vector2(0, -int(d.ascent)))
		f.set_glyph_size(0, key, cp, Vector2(gw, s))
		f.set_glyph_uv_rect(0, key, cp, Rect2(x, 0, gw, s))
		f.set_glyph_texture_idx(0, key, cp, 0)
		x += gw + 1
	return f
