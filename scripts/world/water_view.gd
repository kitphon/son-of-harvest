class_name WaterView
extends Sprite2D
## The moving skin on the water in the flat view: the farm pond (FarmView), the village pond and
## the river (MapView). It is the 2D twin of the 3D sheet (scripts/world3d/water_surface.gd): pale
## sun glints and a few darker troughs drifting over the water, nothing else. The ground tile
## under it (PlaceholderArt "water") stays the still base.
## The picture is one pixel per map pixel (16 per cell) with alpha on the water pixels only: a
## land side keeps its bank (2 px) and foam line (1 px) still, as the 3D sheet insets 3 px there
## (LAND_INSET). The shader samples the pattern at the centre of its pixel, so the glints step in
## pixel-art jumps and keep the pixel grid. Nearest filtering, no smoothing. Under the view's
## CanvasModulate like the ground, so it darkens at dusk and night with it.
## The constants below copy the 3D sheet's SHADER (speeds, thresholds, colours). The alphas are
## lower here (glint 0.3, trough 0.2 against 0.5 and 0.32): the 3D sheet takes the sun's light
## term, this flat picture takes none, so the same alpha read too strong on the blue. They are
## not in data yet, so change both together.
## Ripple rings (`ripple()`) mirror the 3D sheet's: up to MAX_RIPPLES rings at a time, drawn in
## the same shader loop over map pixels (the centre is in map pixels, 16 per cell), one pixel
## wide, stepping out 14 px a second (a strong ring 1.3 times that, to 34 px; a gentle one to
## 22 px), fading in two steps. The bobber's landing, its slow breathing while it waits and a
## bite use them (main_2d.gd drives them, as Main3D does in 3D).
## Rain dimples (`set_rain()`) are the same hash layer as in 3D (cell, slot, centre; a ring grows
## 0..3 px); main_2d pushes Game.dimple_style() in the rain, none indoors.
## Winter ice (`set_ice()`) is the 3D sheet's: WaterIce.GLSL in this shader, the land
## round each cell in the mask's red channel (x 255, WaterIce.BITS); main_2d pushes
## Game.ice_style() and the snow lying, none indoors.

const T := 16
const INSET := 3   # px in from a land side (the bank and foam line of the ground tile)

const MAX_RIPPLES := 8
const RING_LIFE := 1.5        # seconds a gentle ring lasts
const RING_LIFE_STRONG := 1.9

const SHADER := """shader_type canvas_item;
uniform vec2 size_px = vec2(16.0, 16.0);   // the map in pixels
uniform vec3 glint_color : source_color = vec3(1.0, 0.93, 0.7);
uniform vec3 trough_color : source_color = vec3(0.13, 0.31, 0.56);
uniform vec2 drift = vec2(0.5, 0.25);
uniform vec3 ring_color : source_color = vec3(0.86, 0.95, 1.0);
uniform float clock = 0.0;
uniform float dimple_density = 0.0;   // chance a cell has a rain dimple in a time slot (0 = dry)
uniform float dimple_life = 0.9;      // seconds a dimple lasts
float hash2(vec2 v) { return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453); }
uniform vec4 ripples[8];   // x, y of the centre in map pixels, clock time it began, life (0 = unused; < 0 = strong)
//ICE//
void fragment() {
	vec4 mask = texture(TEXTURE, UV);
	if (mask.a < 0.5) {
		discard;   // a bank, the foam line or land
	}
	vec2 pix = floor(UV * size_px);
	vec2 p = (pix + 0.5) / 16.0;   // cell units, as the 3D sheet's world.xz
	float t = TIME;
	vec4 ice = ice_at(pix, mask.r * 255.0);
	float ring = 0.0;
	for (int i = 0; i < 8; i++) {
		vec4 r = ripples[i];
		float life = abs(r.w);
		float age = clock - r.z;
		if (r.w != 0.0 && age >= 0.0 && age < life) {
			float radius = floor(age * 14.0 * (r.w < 0.0 ? 1.3 : 1.0) + 0.5);
			float maxr = r.w < 0.0 ? 34.0 : 22.0;
			float d = length(pix + 0.5 - r.xy);
			if (radius <= maxr && abs(d - radius) < 0.8) {
				ring = max(ring, age / life < 0.55 ? 0.6 : 0.3);
			}
		}
	}
	if (dimple_density > 0.0) {   // as the 3D sheet: one small ring, 0..3 px, centred 3..12 px into its cell
		vec2 cell = floor(p);
		float u = clock / dimple_life + hash2(cell) * 7.0;
		float slot = mod(floor(u), 64.0);
		float age01 = fract(u);
		if (hash2(cell + vec2(slot * 0.37, slot * 1.13) + 21.0) < dimple_density) {
			vec2 centre = floor(vec2(3.0) + vec2(hash2(cell + vec2(slot, 5.0)), hash2(cell.yx + vec2(slot, 9.0))) * 10.0) + 0.5;
			float d = length((p - cell) * 16.0 - centre);
			if (abs(d - floor(age01 * 4.0)) < 0.8) {
				ring = max(ring, age01 < 0.5 ? 0.5 : 0.25);
			}
		}
	}
	vec2 q = p - drift * t * 0.18;
	float a = sin(q.x * 2.3 + q.y * 1.1 + t * 0.55) + sin(q.x * 1.3 - q.y * 2.5 - t * 0.4);
	float b = sin((q.x + q.y) * 3.7 + sin(q.y * 2.1 + t * 0.5) * 1.7 - t * 0.9);
	float h = 0.25 * a + 0.5 * b;   // -1 .. 1
	if (ice.a > 0.0) {   // the shore's ice in winter: no glints, rings or dimples on it
		COLOR = ice;
	} else if (ring > 0.0) {
		COLOR = vec4(ring_color, ring);
	} else if (h > 0.62) {
		COLOR = vec4(glint_color, 0.3);
	} else if (h < -0.7) {
		COLOR = vec4(trough_color, 0.2);
	} else {
		discard;
	}
}
"""

var water_cells := 0   # how many water cells the picture covers (0 = no sheet)
var clock := 0.0                         # seconds since the sheet was made; the rings' time
var ripples := PackedVector4Array()      # the slots the shader reads (see `ripple`)
var _next_slot := 0
var rain_density := 0.0                  # set_rain: 0 when dry
var rain_life := 0.9
var ice: Dictionary = {}                 # set_ice: {} when there is none
var ice_snow := 0.0                      # the snow lying on it (0..1)


func _process(delta: float) -> void:
	advance(delta)


## Moves the rings' clock on (called every frame; tests call it by hand).
func advance(delta: float) -> void:
	clock += delta
	var m := material as ShaderMaterial
	if m != null:
		m.set_shader_parameter("clock", clock)


## Starts a ring spreading from `at` (map pixels; a cell's centre is (cell + 0.5) * T). A strong
## one (a bite) is quicker, wider and lasts longer. The oldest of the MAX_RIPPLES slots is reused
## when all are busy.
func ripple(at: Vector2, strong := false) -> void:
	if ripples.size() != MAX_RIPPLES:
		ripples.resize(MAX_RIPPLES)
	var life := RING_LIFE_STRONG if strong else RING_LIFE
	ripples[_next_slot] = Vector4(at.x, at.y, clock, -life if strong else life)
	_next_slot = (_next_slot + 1) % MAX_RIPPLES
	var m := material as ShaderMaterial
	if m != null:
		m.set_shader_parameter("ripples", ripples)


## Rain dimples (data/weather_fx.json "dimples" of today's look; {} = dry), the 3D sheet's
## second layer: many small rings popping at random spots from the clock alone.
func set_rain(style: Dictionary) -> void:
	rain_density = clampf(float(style.get("density", 0.0)), 0.0, 1.0)
	rain_life = maxf(float(style.get("life", 0.9)), 0.1)
	var m := material as ShaderMaterial
	if m != null:
		m.set_shader_parameter("dimple_density", rain_density)
		m.set_shader_parameter("dimple_life", rain_life)


## Winter ice along the shore, as the 3D sheet's (WaterSurface.set_ice: the same style from
## Game.ice_style(), the same uniforms and WaterIce.GLSL); {} = none.
func set_ice(style: Dictionary, snow := 0.0) -> void:
	ice = style
	ice_snow = clampf(snow, 0.0, 1.0)
	var m := material as ShaderMaterial
	if m != null:
		WaterIce.push(m, ice, ice_snow)


## The land round the cell holding map pixel `p` as WaterIce.BITS (0 off the water). For tests.
func land_at(p: Vector2i) -> int:
	var img := texture.get_image()
	if img == null or p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
		return 0
	var c := img.get_pixelv(p)
	return roundi(c.r * 255.0) if c.a > 0.5 else 0


## How many rings are still spreading now.
func ripples_alive() -> int:
	var n := 0
	for r in ripples:
		if r.w != 0.0 and clock - r.z < absf(r.w):
			n += 1
	return n


## Sets the picture for a w x h map. `water_at(c)` is true on a water cell (in bounds only).
## `edge_bank`: a land side past the map's edge still gets its bank (the farm's ground does; a
## map's tile does not). Call once before it is in the tree or right after; it draws nothing
## itself.
func build(w: int, h: int, water_at: Callable, edge_bank: bool) -> void:
	water_cells = 0
	var img := Image.create(w * T, h * T, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			if not water_at.call(c):
				continue
			water_cells += 1
			var x0 := 0 if not _land(water_at, w, h, c + Vector2i.LEFT, edge_bank) else INSET
			var x1 := T if not _land(water_at, w, h, c + Vector2i.RIGHT, edge_bank) else T - INSET
			var y0 := 0 if not _land(water_at, w, h, c + Vector2i.UP, edge_bank) else INSET
			var y1 := T if not _land(water_at, w, h, c + Vector2i.DOWN, edge_bank) else T - INSET
			var land := WaterIce.land_mask(c, func(n: Vector2i) -> bool: return not _land(water_at, w, h, n, edge_bank))
			img.fill_rect(Rect2i(c.x * T + x0, c.y * T + y0, x1 - x0, y1 - y0), Color8(land, 255, 255, 255))
	centered = false
	position = Vector2.ZERO
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture = ImageTexture.create_from_image(img)
	var sh := Shader.new()
	sh.code = SHADER.replace("//ICE//", WaterIce.GLSL)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("size_px", Vector2(w * T, h * T))
	ripples.resize(MAX_RIPPLES)
	m.set_shader_parameter("ripples", ripples)
	m.set_shader_parameter("clock", clock)
	m.set_shader_parameter("dimple_density", rain_density)
	m.set_shader_parameter("dimple_life", rain_life)
	WaterIce.push(m, ice, ice_snow)
	material = m
	visible = water_cells > 0


## The mask's alpha at map pixel `p` (true = the surface is drawn there). For tests.
func surface_at(p: Vector2i) -> bool:
	var img := texture.get_image()
	if img == null or p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
		return false
	return img.get_pixelv(p).a > 0.5


static func _land(water_at: Callable, w: int, h: int, n: Vector2i, edge_bank: bool) -> bool:
	if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
		return edge_bank
	return not water_at.call(n)
