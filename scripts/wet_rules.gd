class_name WetRules
extends RefCounted
## The wet look of the open air in rain (data/wet.json): the logic both views share. How wet
## things are now (grows over the first game hour of rain, as the puddles do, and dries over the
## next morning after it stops; none under snow, indoors or under glass), what each kind of
## surface looks like wet (darker, a little more saturated, glossier: tilled soil darkest, kawara
## tile glossiest, thatch little), and the per-cell surface masks and colour tints the views draw
## with. The 3D view (WetLayer, the ground shader's `wet` uniforms) and the flat view (MapView,
## FarmView: tints on the ground tiles, the painted roofs and the stone props) only apply them.
## Pure: nothing here draws. At wetness 0 every tint is white and every tone the colour itself.

const DATA_PATH := "res://data/wet.json"
## How the ground mask stores a surface (mask_color): red its `dark`, green half its `sat`, blue
## its `gloss`; a cell that never gets wet is NEUTRAL.
const NEUTRAL := Color(1.0, 0.5, 0.0, 1.0)

static var _cfg: Dictionary = {}
## A wetness forced for every outdoor map (`--wet=1.0` for frames); below 0 = by the weather.
## Snow lying and indoors still keep it away.
static var forced := -1.0
static var _avg := {}       # picture key -> its mean colour (opaque pixels)
static var _keys := {}      # Texture2D -> its PlaceholderArt key (key_of)
static var _keys_seen := -1


## data/wet.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## Game hours since the day began (`day_start`; the small hours belong to the day before): 0..24.
static func since_start(hour: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	return fposmod(hour - float(cfg.day_start), 24.0)


## How wet the open air is, 0..1: from today's weather `look`, yesterday's `prev_look` ("" =
## none), the clock `hour` (a float, 0..24) and the snow lying (0..100). Rain wets to the look's
## max over grow_hours; what yesterday's rain left dries over dry_hours; snow lying keeps it away.
static func wetness(look: String, prev_look: String, hour: float, snow_cover: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	if snow_cover > 0.0:
		return 0.0
	var since := since_start(hour, cfg)
	var carry := float(cfg.looks.get(prev_look, {}).get("max", 0.0)) \
		* clampf(1.0 - since / maxf(float(cfg.dry_hours), 0.001), 0.0, 1.0)
	var top := float(cfg.looks.get(look, {}).get("max", 0.0))
	if top <= 0.0:
		return carry
	return maxf(top * clampf(since / maxf(float(cfg.grow_hours), 0.001), 0.0, 1.0), carry)


## The wetness of an `indoor` place (or under glass, in the mine) by the game (`game` is the Game
## autoload): 0 there, 0 under snow, `forced` when set, else wetness() by today's and
## yesterday's weather and the clock.
static func wetness_of(game: Object, indoor: bool, cfg := {}) -> float:
	if game == null or indoor or float(game.snow_cover) > 0.0:
		return 0.0
	if forced >= 0.0:
		return clampf(forced, 0.0, 1.0)
	var season: String = game.season_name()
	var hour := float(game.hour) + float(game.minute) / 60.0
	var yesterday := str(game.weather_yesterday)
	return wetness(game.weather_look(game.weather_today, season),
		game.weather_look(yesterday, season) if yesterday != "" else "",
		hour, float(game.snow_cover), cfg)


## The wetness now on map `m` (MapData): 0 indoors, under glass or in the mine.
static func wetness_now(game: Object, m: MapData, cfg := {}) -> float:
	return wetness_of(game, m == null or m.indoor or m.sheltered, cfg)


## The wetness in steps of 1/50, so the views redo their look only when it moves a step.
static func step_of(wet: float) -> int:
	return roundi(clampf(wet, 0.0, 1.0) * 50.0)


## The rule of surface `kind` ({dark, sat, gloss}); {} for none (it never looks wet).
static func surface(kind: String, cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	return cfg.surfaces.get(kind, {})


## The surface of a ground kind (a map tile, the farm's ground picture kind): "" for none.
static func ground_surface(kind: String, cfg := {}) -> String:
	if cfg.is_empty():
		cfg = config()
	return str(cfg.ground.get(kind, ""))


## The farm cell's ground kind as its picture shows it (grass, tilled, wet, path, water, bed).
static func farm_kind(farm: FarmGrid, c: Vector2i) -> String:
	return PlaceholderArt.ground_key(farm, c).get_slice(":", 1)


## Colour `c` as surface `rule` looks at wetness `wet`: darker by `dark`, its saturation (about
## the grey of the same brightness) raised by `sat`, both eased in by the wetness. The ground
## shader does the same sum.
static func tone(c: Color, rule: Dictionary, wet: float) -> Color:
	if wet <= 0.0 or rule.is_empty():
		return c
	var d := lerpf(1.0, float(rule.dark), wet)
	var s := lerpf(1.0, float(rule.sat), wet)
	var l := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	return Color(clampf((l + (c.r - l) * s) * d, 0.0, 1.0), clampf((l + (c.g - l) * s) * d, 0.0, 1.0),
		clampf((l + (c.b - l) * s) * d, 0.0, 1.0), c.a)


## The multiplier that takes colour `base` to its wet tone (per channel, at most 1): for a picture
## drawn with a modulate (flat view) or a textured material (3D), by its mean colour.
static func tint_for(base: Color, rule: Dictionary, wet: float) -> Color:
	if wet <= 0.0 or rule.is_empty():
		return Color.WHITE
	var t := tone(base, rule, wet)
	var ch := func(a: float, b: float) -> float: return clampf(b / a, 0.0, 1.0) if a > 0.001 else 1.0
	return Color(ch.call(base.r, t.r), ch.call(base.g, t.g), ch.call(base.b, t.b), 1.0)


## The mean colour of picture `key`'s opaque pixels (kept).
static func mean_of(key: String) -> Color:
	if not _avg.has(key):
		var img := PlaceholderArt.image(key)
		var sum := Vector3.ZERO
		var n := 0
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a > 0.5:
					sum += Vector3(p.r, p.g, p.b)
					n += 1
		var m := sum / maxf(n, 1)
		_avg[key] = Color(m.x, m.y, m.z) if n > 0 else Color.WHITE
	return _avg[key]


## The modulate a picture `key` of surface `kind` is drawn with at wetness `wet` (flat view):
## white when dry or of no surface.
static func picture_tint(key: String, kind: String, wet: float, cfg := {}) -> Color:
	if wet <= 0.0 or kind == "":
		return Color.WHITE
	var rule := surface(kind, cfg)
	if rule.is_empty():
		return Color.WHITE
	return tint_for(mean_of(key), rule, wet)


## The mask colour of a surface (see NEUTRAL): what the ground shader reads per cell.
static func mask_color(kind: String, cfg := {}) -> Color:
	var rule := surface(kind, cfg)
	if rule.is_empty():
		return NEUTRAL
	return Color(clampf(float(rule.dark), 0.0, 1.0), clampf(float(rule.sat) / 2.0, 0.0, 1.0),
		clampf(float(rule.gloss), 0.0, 1.0), 1.0)


## A ground mask, one pixel a cell (w x h), laid out as the ground pictures: `kind_at(c)` gives a
## cell's ground kind (a map tile, the farm's picture kind).
static func mask_image(w: int, h: int, kind_at: Callable, cfg := {}) -> Image:
	if cfg.is_empty():
		cfg = config()
	var img := Image.create_empty(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)
	var colors := {}
	for y in h:
		for x in w:
			var kind: String = kind_at.call(Vector2i(x, y))
			if not colors.has(kind):
				colors[kind] = mask_color(ground_surface(kind, cfg), cfg)
			img.set_pixel(x, y, colors[kind])
	return img


## The farm's ground mask (mask_image by the cells' pictures).
static func farm_mask(farm: FarmGrid, cfg := {}) -> Image:
	return mask_image(farm.w, farm.h, func(c: Vector2i) -> String: return farm_kind(farm, c), cfg)


## A map's ground mask (mask_image by its tiles; none at all on an indoor or sheltered map).
static func map_mask(m: MapData, cfg := {}) -> Image:
	if m.indoor or m.sheltered:
		return mask_image(m.w, m.h, func(_c: Vector2i) -> String: return "", cfg)
	return mask_image(m.w, m.h, func(c: Vector2i) -> String: return m.tile(c), cfg)


static var _neutral: ImageTexture

## A 1 x 1 NEUTRAL mask (a ground with no wet mask of its own).
static func neutral_texture() -> ImageTexture:
	if _neutral == null:
		var img := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		img.set_pixel(0, 0, NEUTRAL)
		_neutral = ImageTexture.create_from_image(img)
	return _neutral


## The PlaceholderArt key of texture `tex` ("" when it is not one of its pictures).
static func key_of(tex: Texture2D) -> String:
	if tex == null:
		return ""
	if not _keys.has(tex) and PlaceholderArt._cache.size() != _keys_seen:
		_keys_seen = PlaceholderArt._cache.size()
		for k: String in PlaceholderArt._cache:
			_keys[PlaceholderArt._cache[k]] = k
	return str(_keys.get(tex, ""))


## The surface of picture key `key` by data/wet.json `materials` (the key or a variant of it).
static func picture_surface(key: String, cfg := {}) -> String:
	if cfg.is_empty():
		cfg = config()
	if key == "":
		return ""
	if cfg.materials.has(key):
		return str(cfg.materials[key])
	var i := key.rfind(":")
	if i > 0 and cfg.materials.has(key.substr(0, i)):
		return str(cfg.materials[key.substr(0, i)])
	return ""


## The surface of a lit plain colour: a grey one is stone, any other `plain.other`.
static func plain_surface(c: Color, cfg := {}) -> String:
	if cfg.is_empty():
		cfg = config()
	return str(cfg.plain.stone if c.s < float(cfg.plain.grey) else cfg.plain.other)


## Marks a 3D material as surface `kind` (data/wet.json surfaces), so it gets wet although it is
## unshaded or see-through (the silo's and the greenhouse's flat-coloured parts, the glass). Returns `m`.
static func mark(m: StandardMaterial3D, kind: String) -> StandardMaterial3D:
	m.set_meta("wet_surface", kind)
	return m


## The surface a 3D material shows ("" for none: unshaded, glowing, see-through, unlisted pictures
## unless marked).
static func material_surface(m: StandardMaterial3D, cfg := {}) -> String:
	if cfg.is_empty():
		cfg = config()
	if m.has_meta("wet_surface"):
		return str(m.get_meta("wet_surface"))
	if m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or m.emission_enabled:
		return ""
	var solid: Variant = m.get_meta("solid") if m.has_meta("solid") else null   # Occluders' fade keeps the real one
	var transparency: int = solid[0] if solid != null else m.transparency
	if transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		return ""
	if m.albedo_texture != null:
		return picture_surface(key_of(m.albedo_texture), cfg)
	return plain_surface(m.albedo_color, cfg)


## Wets a 3D material to `wet` (0 puts it back exactly as it was): its albedo to the surface's wet
## tone (a picture by its mean colour), its roughness and specular toward `gloss` by the surface's
## gloss. The albedo's alpha is left alone (Occluders' fades). Returns whether it is a wet surface.
static func wet_material(m: StandardMaterial3D, wet: float, cfg := {}) -> bool:
	if cfg.is_empty():
		cfg = config()
	if wet <= 0.0:
		if m.has_meta("wet_dry"):
			var d: Array = m.get_meta("wet_dry")
			var c: Color = d[0]
			m.albedo_color = Color(c.r, c.g, c.b, m.albedo_color.a)
			m.roughness = d[1]
			m.metallic_specular = d[2]
			m.remove_meta("wet_dry")
			return true
		return false
	if not m.has_meta("wet_dry"):
		var kind := material_surface(m, cfg)
		if kind == "":
			return false
		var mean := mean_of(key_of(m.albedo_texture)) if m.albedo_texture != null else Color.WHITE
		m.set_meta("wet_dry", [m.albedo_color, m.roughness, m.metallic_specular, kind, mean])
	var dry: Array = m.get_meta("wet_dry")
	var rule := surface(dry[3], cfg)
	var base: Color = dry[0]
	var c: Color
	if m.albedo_texture != null:
		var t := tint_for(dry[4], rule, wet)
		c = Color(base.r * t.r, base.g * t.g, base.b * t.b)
	else:
		c = tone(base, rule, wet)
	m.albedo_color = Color(c.r, c.g, c.b, m.albedo_color.a)
	var g := float(rule.gloss) * wet
	m.roughness = lerpf(dry[1], float(cfg.gloss.roughness), g)
	m.metallic_specular = lerpf(dry[2], float(cfg.gloss.specular), g)
	return true


## The flat view's glints on a glass roof over `r` (px) at wetness `wet`: a few pale pixels spread
## over the panes by a hash (data/wet.json flat.glints); none below `glints.min`.
static func glints(r: Rect2, wet: float, cfg := {}) -> Array[Vector2]:
	if cfg.is_empty():
		cfg = config()
	var out: Array[Vector2] = []
	var d: Dictionary = cfg.flat.glints
	if wet < float(d.min) or r.size.x < 6.0 or r.size.y < 6.0:
		return out
	var every := maxi(int(d.every), 3)
	var y := r.position.y + 2.0
	while y < r.end.y - 2.0:
		var x := r.position.x + 2.0 + floorf(DriftRules.rnd(int(y), int(r.position.x), 5) * every)
		while x < r.end.x - 2.0:
			if DriftRules.rnd(int(x), int(y), 9) < 0.5:
				out.append(Vector2(x, y))
			x += every
		y += 3.0
	return out


## The flat view's eave glints of a painted roof over `r` (px) at wetness `wet`: the pixels on its
## bottom eave lip, one every `drips.every` px by a hash; none below `drips.min`.
static func drips(r: Rect2, wet: float, cfg := {}) -> Array[Vector2]:
	if cfg.is_empty():
		cfg = config()
	var out: Array[Vector2] = []
	var d: Dictionary = cfg.flat.drips
	if wet < float(d.min) or r.size.x < 3.0:
		return out
	var every := maxi(int(d.every), 2)
	var y := r.end.y - 1.0
	var x := r.position.x + 1.0 + floorf(DriftRules.rnd(int(r.position.x), int(r.position.y), 7) * every)
	while x < r.end.x - 1.0:
		out.append(Vector2(x, y))
		x += every - 1 + floorf(DriftRules.rnd(int(x), int(y), 13) * 3.0)
	return out
