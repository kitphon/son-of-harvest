class_name PixelFont
extends RefCounted
## Our bitmap font, read from data/font_pixel.json and packed into a FontFile, so Labels
## draw it like any font. Glyphs are keyed by character (code point), so Japanese can be
## added to the data later; nothing here assumes ASCII or a fixed width.
##
## Thai: consonants and the vowels that take room are plain glyphs. The marks that sit over
## or under the letter before them (vowels above / below, tone marks) are in "marks": they
## take no room and are drawn back over the letter before, their right edges lined up. A
## mark has four drawn variants, kept in the Private Use Area from MARK_BASE: low (as drawn),
## high (a tone mark over a vowel above: 2 rows higher), left (over a letter whose stem
## rises above the line, ป ฝ ฟ: 2 px to the left) and high-left. shape() picks them, so
## text must go through shape() (Lang.t does it) before a Label draws it.

const PATH := "res://data/font_pixel.json"
const MARK_BASE := 0xE000
const HIGH := 2        # rows a tone mark rises over a vowel above
const LEFT := 2        # px a mark moves left over a tall letter
const ABOVE := "ัิีึื็ํ่้๊๋์"   # marks over the letter
const UPPER := "ัิีึื็ํ"         # vowels above: a tone mark after one goes high
const TONES := "่้๊๋์"          # tone marks (and the silent mark)
const SARA_AM := "ำ"            # a ring over the letter, then า
const NIKHAHIT := "ํ"

static var _data: Dictionary
static var _font: FontFile
static var _adv: Dictionary      # code point -> advance in px (marks: 0)


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
	return _advances().has(ch.unicode_at(0))


## The characters of `text` the font cannot draw (empty when it can draw all of it).
static func missing(text: String) -> String:
	var out := ""
	for ch in shape(text):
		if ch != "\n" and not has_char(ch) and not ch in out:
			out += ch
	return out


## Width in pixels of one line of text, the same advances the FontFile uses.
static func width(text: String) -> int:
	var w := 0
	var adv := _advances()
	for ch in shape(text):
		w += int(adv.get(ch.unicode_at(0), 0))
	return maxi(w - int(data().spacing), 0)


## Width of `text` as a Label shows it in the player's language (Lang.t first).
static func shown_width(text: String) -> int:
	return width(Lang.t(text))


static func _glyph_w(ch: String) -> int:
	var rows: Array = data().glyphs[ch]
	return String(rows[0]).length()


static func _marks() -> Dictionary:
	return data().get("marks", {})


## The code point of a mark's variant: 0 low, 1 high, 2 left, 3 high and left.
static func mark_point(mark: String, variant: int) -> int:
	return MARK_BASE + _marks().keys().find(mark) * 4 + variant


## Thai text with each mark swapped for the variant that sits right, and ำ split into its
## ring (a mark) and า. Text without Thai marks comes back as it is; shaped text too.
static func shape(text: String) -> String:
	if not _has_thai_mark(text):
		return text
	var out := ""
	var base := ""
	var after_upper := false
	var n := text.length()
	for i in n:
		var ch := text[i]
		if ch == SARA_AM:
			out += String.chr(mark_point(NIKHAHIT, 2 if _tall(base) else 0)) + "า"
			after_upper = false
			base = "า"
			continue
		if _marks().has(ch):
			var high := TONES.contains(ch) and (after_upper or (i + 1 < n and text[i + 1] == SARA_AM))
			var left := ABOVE.contains(ch) and _tall(base)
			out += String.chr(mark_point(ch, (1 if high else 0) + (2 if left else 0)))
			after_upper = UPPER.contains(ch)
			continue
		out += ch
		base = ch
		after_upper = false
	return out


static func _has_thai_mark(text: String) -> bool:
	for ch in text:
		if ch == SARA_AM or _marks().has(ch):
			return true
	return false


static func _tall(ch: String) -> bool:
	return ch != "" and String(data().get("tall", "")).contains(ch)


## Every drawn glyph: [code point, rows, top row (0 = the line's top; marks go above or
## below), x offset, advance].
static func _all_glyphs() -> Array:
	var d := data()
	var out := []
	for ch in d.glyphs:
		var w := _glyph_w(ch)
		out.append([String(ch).unicode_at(0), d.glyphs[ch], 0, 0, w + int(d.spacing)])
	var marks := _marks()
	for m in marks:
		var rows: Array = marks[m].rows
		var top := int(marks[m].top)
		var w := String(rows[0]).length()
		var x := -(w + int(d.spacing))
		var can_rise: bool = TONES.contains(m)
		for v in 4:
			var t := top - (HIGH if (v & 1) and can_rise else 0)
			var dx := x - (LEFT if (v & 2) and ABOVE.contains(m) else 0)
			out.append([mark_point(m, v), rows, t, dx, 0])
		out.append([String(m).unicode_at(0), rows, top, x, 0])   # the bare mark: as low
	return out


static func _advances() -> Dictionary:
	if _adv.is_empty():
		for g in _all_glyphs():
			_adv[g[0]] = g[4]
	return _adv


## The highest row any glyph reaches (0 or less: marks go above the line's top).
static func _min_top() -> int:
	var m := 0
	for g in _all_glyphs():
		m = mini(m, int(g[2]))
	return m


## All glyphs side by side in one white-on-clear atlas, 1 px apart. Row 0 of the line is at
## y = -_min_top() (rows above it hold the marks that rise over the line).
static func atlas() -> Image:
	var glyphs := _all_glyphs()
	var lift := -_min_top()
	var w := 0
	var h := lift + size()
	for g in glyphs:
		w += String(g[1][0]).length() + 1
		h = maxi(h, lift + int(g[2]) + g[1].size())
	var img := Image.create_empty(maxi(w, 1), h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var x := 0
	for g in glyphs:
		var rows: Array = g[1]
		for y in rows.size():
			var row := String(rows[y])
			for i in row.length():
				if row[i] == "#":
					img.set_pixel(x + i, lift + int(g[2]) + y, Color.WHITE)
		x += String(rows[0]).length() + 1
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
	var lift := -_min_top()
	var x := 0
	for g in _all_glyphs():
		var cp: int = g[0]
		var rows: Array = g[1]
		var gw := String(rows[0]).length()
		f.set_glyph_advance(0, s, cp, Vector2(g[4], 0))
		f.set_glyph_offset(0, key, cp, Vector2(g[3], int(g[2]) - int(d.ascent)))
		f.set_glyph_size(0, key, cp, Vector2(gw, rows.size()))
		f.set_glyph_uv_rect(0, key, cp, Rect2(x, lift + int(g[2]), gw, rows.size()))
		f.set_glyph_texture_idx(0, key, cp, 0)
		x += gw + 1
	return f
