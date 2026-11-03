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
const GROUND_SHADER := "shader_type spatial;\n" + _COMMON + """
uniform sampler2D ground : source_color, filter_nearest;
uniform sampler2D mask : filter_linear;
uniform float sun_share = 0.7;
void fragment() {
	vec3 g = texture(ground, UV).rgb;
	float s = snow_at(world.xz, cover * texture(mask, UV).r);
	ALBEDO = s > 1.5 ? snow_color : (s > 0.5 ? mix(g, rim_color, 0.7) : g);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * sun_share;
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

## Lit, so roof tops keep the sun's shading; bare spots are cut away and show the roof below.
const TOP_SHADER := "shader_type spatial;\n" + _COMMON + """
void fragment() {
	float s = snow_at(world.xz + vec2(world.y * 0.37), cover);
	if (s < 0.5) discard;
	ALBEDO = s > 1.5 ? snow_color : rim_color;
}
"""

static var _noise: ImageTexture


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


static func _mask(w: int, h: int, hold_at: Callable) -> Image:
	var img := Image.create_empty(w * MASK_PER_CELL, h * MASK_PER_CELL, false, Image.FORMAT_L8)
	for y in h:
		for x in w:
			var v: float = hold_at.call(Vector2i(x, y))
			img.fill_rect(Rect2i(x * MASK_PER_CELL, y * MASK_PER_CELL, MASK_PER_CELL, MASK_PER_CELL), Color(v, v, v))
	return img


static func ground_material(ground: Texture2D, mask: Texture2D) -> ShaderMaterial:
	var m := _material(GROUND_SHADER)
	m.set_shader_parameter("sun_share", SUN_SHARE)
	m.set_shader_parameter("ground", ground)
	m.set_shader_parameter("mask", mask)
	return m


## For the 2D view: put on a node that draws the mask texture over the whole farm.
static func canvas_material() -> ShaderMaterial:
	return _material(CANVAS_SHADER)


static func top_material() -> ShaderMaterial:
	return _material(TOP_SHADER)


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


static func _material(code: String) -> ShaderMaterial:
	if _noise == null:
		_noise = ImageTexture.create_from_image(noise_image())
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("noise", _noise)
	return m
