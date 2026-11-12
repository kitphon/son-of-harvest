class_name SnowLayer
extends RefCounted
## Snow lying on the farm and the outdoor maps: the 3D ground shader that lays it over the ground picture, the
## shader for snow tops on roofs and lids, the 2D view's overlay (the same pattern), and the
## per-cell mask of how much snow each kind of ground holds (data/snow_cover.json "ground":
## tilled and wet soil hold less, so plots stay readable). The amount itself is Game.snow_cover; this only draws it.
##
## Where snow lies is a noise pattern on the world's pixel grid (16 per cell), equalised so a
## cover of 0.4 whitens 40 % of the pixels. Pixels just past the snow line get a pale blue-grey
## rim, so patches have soft, ragged edges instead of hard squares.

const MASK_PER_CELL := 4       # mask pixels per cell; linear filtering blends kinds over 1/4 cell
const NOISE_SIZE := 128        # noise texture pixels; it spans NOISE_CELLS cells and repeats
const NOISE_CELLS := 8.0
## Snow tops (roofs, lids, caps, pads) fill up faster than the ground: whole at this much
## cover and above, below it the ground's pattern at cover / TOP_FULL. The ground's equalised
## noise leaves 1 - cover of the pixels bare in clumps a few cells wide: right for a field,
## but on a small roof it reads as holes torn in the snow. Snow that sticks to a roof covers
## it evenly and only thins (melts off in patches) when little lies.
const TOP_FULL := 0.5
## The flat view's farm roofs (farm_roof_mask_image): a mask pixel a picture pixel, so the snow
## keeps to the roofs' drawn shapes.
const ROOF_PER_CELL := 16
## Bare pixels kept round a roof's snow: its eaves' dark rim, as the 3D snow tops stop short of
## the eaves, and round a door drawn on it.
const ROOF_RIM := 1

const _SNOW_AT := """
uniform sampler2D noise : repeat_enable, filter_nearest;
uniform float cover = 0.0;
uniform vec3 snow_color : source_color = vec3(0.94, 0.96, 0.99);
uniform vec3 rim_color : source_color = vec3(0.74, 0.79, 0.88);
// 2 = snow, 1 = rim, 0 = bare, for `amount` 0..1 of the pixels at this spot.
float snow_at(vec2 p, float amount) {
	vec2 px = (floor(p * 16.0) + 0.5) / 16.0;
	float n = texture(noise, px / 8.0).r;   // NOISE_CELLS
	float a = amount * 1.08;
	return n < a - 0.08 ? 2.0 : (n < a ? 1.0 : 0.0);
}
"""

const _COMMON := _SNOW_AT + """
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
"""

## The sun's share of the light on the ground: with Main3D's sky light it makes sunlit ground
## about white, so the ground picture keeps its colours where the sun falls and darkens in shade.
const SUN_SHARE := 0.045

## Lit only to take shadows: flat light (no slope shading), the sun scaled by sun_share.
## In rain the bare ground looks wet (WetRules, data/wet.json): `wet` 0..1 and `wet_mask` (one
## pixel a cell: red the surface's dark, green half its saturation gain, blue its gloss) darken
## and saturate it, add a sky sheen and a glint toward the sun by the gloss. At wet 0 it is as
## before (no wetness while snow lies, so the snow's pixels are never wet).
const GROUND_SHADER := "shader_type spatial;\n" + _COMMON + """
uniform sampler2D ground : source_color, filter_nearest;
uniform sampler2D mask : filter_linear;
uniform float sun_share = 0.7;
uniform float wet = 0.0;
uniform sampler2D wet_mask : filter_nearest;
uniform vec3 sheen_color : source_color = vec3(0.64, 0.7, 0.77);
uniform float sheen = 0.16;
uniform float glint = 0.5;
varying float gloss;
void fragment() {
	vec3 g = texture(ground, UV).rgb;
	float s = snow_at(world.xz, cover * texture(mask, UV).r);
	gloss = 0.0;
	if (wet > 0.0) {
		vec4 k = texture(wet_mask, UV);
		float l = dot(g, vec3(0.299, 0.587, 0.114));
		g = clamp((vec3(l) + (g - vec3(l)) * mix(1.0, k.g * 2.0, wet)) * mix(1.0, k.r, wet), 0.0, 1.0);
		gloss = k.b * wet;
		g = mix(g, sheen_color, gloss * sheen);
	}
	ALBEDO = s > 1.5 ? snow_color : (s > 0.5 ? mix(g, rim_color, 0.7) : g);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * sun_share;
	if (gloss > 0.0) {
		vec3 hv = normalize(LIGHT + VIEW);
		SPECULAR_LIGHT += ATTENUATION * LIGHT_COLOR * sun_share * pow(max(dot(NORMAL, hv), 0.0), 24.0) * gloss * glint * 8.0;
	}
}
"""

## The flat 2D view: drawn over the ground tiles (under the field sprites) as the mask texture
## stretched over the farm, so TEXTURE is the hold and the node's position gives the same
## pixel pattern as the 3D ground (canvas pixels / 16 = cells = 3D x / z).
const CANVAS_SHADER := "shader_type canvas_item;
" + _SNOW_AT + """
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy / 16.0; }
void fragment() {
	float s = snow_at(world, cover * texture(TEXTURE, UV).r);
	COLOR = s > 1.5 ? vec4(snow_color, 1.0) : (s > 0.5 ? vec4(rim_color, 0.7) : vec4(0.0));
}
"""

## The flat view's farm roofs: like CANVAS_SHADER, the amount the 3D snow tops' (whole from
## top_full up, TOP_SHADER) times what the roof holds (the mask's red, nearest: its drawn shape);
## the back slopes (the mask's green 0) a shade darker, as the roofs' pictures are, so a white
## roof still shows its ridge.
const ROOF_CANVAS_SHADER := "shader_type canvas_item;
" + _SNOW_AT + """
uniform float top_full = 0.5;
uniform float back_shade = 0.88;
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy / 16.0; }
void fragment() {
	vec4 m = texture(TEXTURE, UV);
	float s = snow_at(world, min(cover / top_full, 1.0) * m.r);
	float shade = mix(back_shade, 1.0, m.g);
	COLOR = s > 1.5 ? vec4(snow_color * shade, 1.0) : (s > 0.5 ? vec4(rim_color * shade, 0.7) : vec4(0.0));
}
"""

## Lit, so roof tops keep the sun's shading; bare spots are cut away and show the roof below.
## The amount is top_amount(cover): whole from TOP_FULL up.
const TOP_SHADER := "shader_type spatial;\n" + _COMMON + """
uniform float top_full = 0.5;
void fragment() {
	float s = snow_at(world.xz + vec2(world.y * 0.37), min(cover / top_full, 1.0));
	if (s < 0.5) discard;
	ALBEDO = s > 1.5 ? snow_color : rim_color;
}
"""

static var _noise: ImageTexture
static var _noise_img: Image   # the same noise for GDScript lookups (noise_at)
static var _shaders := {}   # code -> its Shader, one a run (a new Shader per material parsed its code each time)


## How much snow a cell's ground holds, 0..1, by its ground kind (grass, path, tilled, ...).
static func hold(farm: FarmGrid, c: Vector2i, rules: Dictionary) -> float:
	var kind := PlaceholderArt.ground_key(farm, c).get_slice(":", 1)
	return clampf(float(rules.get("ground", {}).get(kind, 1.0)), 0.0, 1.0)


## How much snow a map cell holds, 0..1, by its tile kind; none under a roof (sheltered).
static func map_hold(m: MapData, c: Vector2i, rules: Dictionary) -> float:
	if m.sheltered:
		return 0.0
	return clampf(float(rules.get("ground", {}).get(m.tile(c), 1.0)), 0.0, 1.0)


## Does snow lie on this map at all (outdoors, not the farm's own ground)?
static func map_has_snow(m: MapData) -> bool:
	return not m.sheltered and not m.farm


## The per-cell hold as an image (MASK_PER_CELL pixels a cell, laid out like the ground).
static func mask_image(farm: FarmGrid, rules: Dictionary) -> Image:
	return _mask(FarmGrid.W, FarmGrid.H, func(c: Vector2i) -> float: return hold(farm, c, rules))


## The same for a map from data/maps.
static func map_mask_image(m: MapData, rules: Dictionary) -> Image:
	return _mask(m.w, m.h, func(c: Vector2i) -> float: return map_hold(m, c, rules))


## A map's roofs as the flat view sees them from above (data/snow_cover.json "roofs": the
## prop kinds with a roof and how much snow they hold): over their footprints but the front
## row, so the house front and its door stay plain to see.
static func roof_mask_image(m: MapData, rules: Dictionary) -> Image:
	var roofs: Dictionary = rules.get("roofs", {})
	return _mask(m.w, m.h, func(c: Vector2i) -> float:
		var p := m.prop_at(c)
		if not map_has_snow(m) or not roofs.has(str(p.get("kind", ""))) or c.y == p.cell.y + p.size.y - 1:
			return 0.0
		return clampf(float(roofs[p.kind]), 0.0, 1.0))


## The farm's roofs as the flat view draws them (FarmView), for its roof snow
## (roof_canvas_material): ROOF_PER_CELL pixels a cell, each pixel's red what that roof holds
## (data/snow_cover.json "farm_roofs": FarmGrid building kinds with a roof), 0 off the roofs, its
## green 1 on a slope facing the camera (south) and 0 on a back slope.
## The 3D view's roofs fill whole from TOP_FULL cover, eaves and all, so these do too: the
## painted roofs (the farmhouse, coop, barn) over their whole box but a ROOF_RIM round it and round
## the doors drawn on it; the silo's cone; the greenhouse's two glass slopes and the ridge cap
## between them, as its 3D snow lies: in the bays between the rafters, stopping short of the eaves
## (it slides off glass), never on the glazed front wall below.
static func farm_roof_mask_image(farm: FarmGrid, rules: Dictionary) -> Image:
	var roofs: Dictionary = rules.get("farm_roofs", {})
	var img := Image.create_empty(farm.w * ROOF_PER_CELL, farm.h * ROOF_PER_CELL, false, Image.FORMAT_RGB8)
	var px := float(ROOF_PER_CELL) / FarmView.T   # mask pixels a picture pixel
	for kind: String in roofs:
		var hold := clampf(float(roofs[kind]), 0.0, 1.0)
		var box := FarmView.roof_rect(farm, kind)
		if hold <= 0.0 or not box.has_area():
			continue
		var put := func(r: Rect2, front := true) -> void:
			var ri := Rect2i(Vector2i((r.position * px).round()), Vector2i((r.size * px).round()))
			if ri.has_area():
				img.fill_rect(ri, Color(hold, 1.0 if front else 0.0, 0.0))
		var o := box.position
		match kind:
			"greenhouse":
				var wide := box.size.x
				var foot := box.size.y - FarmView.GREENHOUSE_WALL   # the roof's foot, over the front wall
				var ridge := FarmView.GREENHOUSE_RIDGE
				var bays: Array[float] = [1.0]
				for x in range(8, int(wide), 8):   # a rafter every 8 px (_draw_greenhouse)
					bays.append(float(x))
				bays.append(wide - 1.0)
				for i in bays.size() - 1:
					var x0: float = bays[i] + (1.0 if i > 0 else 0.0)
					put.call(Rect2(o + Vector2(x0, 3), Vector2(bays[i + 1] - x0, ridge - 3)), false)   # the back slope
					put.call(Rect2(o + Vector2(x0, ridge + 2), Vector2(bays[i + 1] - x0, foot - 4 - ridge - 2)))   # the front
				put.call(Rect2(o + Vector2(0, ridge), Vector2(wide, 2)))   # the ridge cap
			"silo":
				# The cone (_draw_silo): its apex at (16, 1), its foot along y 14 from x 1 to 31.
				for y in range(3, 13):
					var half := floorf(15.0 * (y - 1) / 13.0) - 1.0
					put.call(Rect2(o + Vector2(16 - half, y), Vector2(half * 2, 1)))
			_:
				var inner := box.grow(-ROOF_RIM)
				var ridge := floorf(box.size.y / 2.0)   # the roofs' pictures (RoofArt) are gables along x
				put.call(Rect2(inner.position, Vector2(inner.size.x, ridge - ROOF_RIM)), false)
				put.call(Rect2(inner.position + Vector2(0, ridge - ROOF_RIM), Vector2(inner.size.x, inner.size.y - ridge + ROOF_RIM)))
				for y in range(int(box.position.y / FarmView.T), int(box.end.y / FarmView.T)):
					for x in range(int(box.position.x / FarmView.T), int(box.end.x / FarmView.T)):
						if farm.fixed_at(Vector2i(x, y)) != kind:   # a door: bare, with a rim round it
							var hole := Rect2(Vector2(x, y) * FarmView.T, Vector2.ONE * FarmView.T).grow(ROOF_RIM)
							var hi := Rect2i(Vector2i((hole.position * px).round()), Vector2i((hole.size * px).round()))
							img.fill_rect(hi.intersection(Rect2i(Vector2i.ZERO, img.get_size())), Color.BLACK)
	return img


static func _mask(w: int, h: int, hold_at: Callable) -> Image:
	var img := Image.create_empty(w * MASK_PER_CELL, h * MASK_PER_CELL, false, Image.FORMAT_L8)
	for y in h:
		for x in w:
			var v: float = hold_at.call(Vector2i(x, y))
			img.fill_rect(Rect2i(x * MASK_PER_CELL, y * MASK_PER_CELL, MASK_PER_CELL, MASK_PER_CELL), Color(v, v, v))
	return img


## `wet_mask`: the ground's WetRules mask (one pixel a cell, laid out as `ground`); none = never wet.
static func ground_material(ground: Texture2D, mask: Texture2D, wet_mask: Texture2D = null) -> ShaderMaterial:
	var m := _material(GROUND_SHADER)
	m.set_shader_parameter("sun_share", SUN_SHARE)
	m.set_shader_parameter("ground", ground)
	m.set_shader_parameter("mask", mask)
	m.set_shader_parameter("wet_mask", wet_mask if wet_mask != null else WetRules.neutral_texture())
	var sheen: Dictionary = WetRules.config().sheen
	m.set_shader_parameter("sheen_color", Color(str(sheen.color)))
	m.set_shader_parameter("sheen", float(sheen.share))
	m.set_shader_parameter("glint", float(sheen.glint))
	return m


## Is `m` a ground material (ground_material: it takes the `wet` uniform)?
static func is_ground(m: Material) -> bool:
	return m is ShaderMaterial and (m as ShaderMaterial).shader == shader(GROUND_SHADER)


## For the 2D view: put on a node that draws the mask texture over the whole farm.
static func canvas_material() -> ShaderMaterial:
	return _material(CANVAS_SHADER)


## For the flat view's farm roofs: put on a node that draws farm_roof_mask_image over the farm.
static func roof_canvas_material() -> ShaderMaterial:
	var m := _material(ROOF_CANVAS_SHADER)
	m.set_shader_parameter("top_full", TOP_FULL)
	return m


static func top_material() -> ShaderMaterial:
	var m := _material(TOP_SHADER)
	m.set_shader_parameter("top_full", TOP_FULL)
	return m


## The share of a snow top's pixels under snow (the shader's amount) at ground `cover` 0..1.
static func top_amount(cover: float) -> float:
	return minf(cover / TOP_FULL, 1.0)


## A pixel with noise value `n` at `amount`: 2 snow, 1 rim, 0 bare (snow_at past its noise
## lookup, for the tests).
static func snow_kind(n: float, amount: float) -> int:
	var a := amount * 1.08
	return 2 if n < a - 0.08 else (1 if n < a else 0)


## The noise value (0..1) of the world pixel under `at` (cells): the shader's texture(noise, px / 8)
## in GDScript, for the footprints and the tests. The pattern repeats every NOISE_CELLS cells.
static func noise_at(at: Vector2) -> float:
	if _noise_img == null:
		_noise_img = noise_image()
	var x := posmod(floori(at.x * 16.0), NOISE_SIZE)
	var y := posmod(floori(at.y * 16.0), NOISE_SIZE)
	return _noise_img.get_pixel(x, y).r


## Does snow lie (not bare, not the rim) at `at` (cells) when `amount` 0..1 of the pixels
## are under it (cover * what the ground holds)? snow_at's 2 in GDScript.
static func lies(at: Vector2, amount: float) -> bool:
	return snow_kind(noise_at(at), amount) == 2


## Seamless noise, equalised: every value 0..1 is equally common, so `cover` is the share of
## pixels that are white.
static func noise_image(seed_value := 7) -> Image:
	var fn := FastNoiseLite.new()
	fn.seed = seed_value
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.035
	fn.fractal_octaves = 3
	var img := fn.get_seamless_image(NOISE_SIZE, NOISE_SIZE)
	img.convert(Image.FORMAT_L8)
	var order: Array = []
	for y in NOISE_SIZE:
		for x in NOISE_SIZE:
			order.append(Vector3i(img.get_pixel(x, y).r8, x, y))
	order.sort()
	var count := order.size()
	for i in count:
		var v := (i + 0.5) / count
		img.set_pixel(order[i].y, order[i].z, Color(v, v, v))
	return img


## The one Shader for `code` (shared by every material made from it).
static func shader(code: String) -> Shader:
	if not _shaders.has(code):
		var sh := Shader.new()
		sh.code = code
		_shaders[code] = sh
	return _shaders[code]


## The noise as the shaders' texture (for the footprints' own snow test).
static func noise_texture() -> ImageTexture:
	if _noise == null:
		_noise = ImageTexture.create_from_image(noise_image())
	return _noise


static func _material(code: String) -> ShaderMaterial:
	if _noise == null:
		_noise = ImageTexture.create_from_image(noise_image())
	var m := ShaderMaterial.new()
	m.shader = shader(code)
	m.set_shader_parameter("noise", _noise)
	return m
