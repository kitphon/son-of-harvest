class_name WaterSurface
extends MeshInstance3D
## A gentle moving skin on the water: the farm pond, the village pond and the river. The
## ground picture under it (tile "water": blue, a few ripple dashes, a bank and a foam line on
## each land side) stays as the still base; this is a transparent sheet a hair above it that
## shows slow bands drifting over the pixel grid: pale warm sun glints and a few darker
## troughs, nothing else (most pixels are see-through, so the base shows). It is lit like the
## ground (SnowLayer.SUN_SHARE with the sky light), so it darkens with dusk and night and takes
## the sun's shadows. Water never holds snow (data/snow_cover.json), so the sheet is the same
## in winter. The pattern is a function of the world pixel (16 per cell), stepped, so it moves
## in pixel-art jumps and costs a few sines per pixel.
## Ripple rings (`ripple()`): up to MAX_RIPPLES rings at a time spread from a point, one pixel
## wide, stepping out a pixel at a time and fading in two steps; the bobber's landing, its slow
## breathing while it waits and the burst of a bite use them. They are drawn by the same sheet
## (a uniform array, a loop of eight in the shader), so they take the bank inset, the ground's
## light and the pixel grid for free and add no node. (The farmer never wades: water cells are
## blocked, so there is no ring at the feet; the bobber's rings are the only ones.)

const T := 16
const LAND_INSET := 3.0 / T   # a bank is 2 px wide and the foam line 1 px; the sheet starts after them
const LIFT := 0.01            # above the ground picture (the apron lies 0.02 below the map)

const MAX_RIPPLES := 8
const RING_LIFE := 1.5        # seconds a gentle ring lasts
const RING_LIFE_STRONG := 1.9

const SHADER := """shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
varying vec3 world;
uniform float sun_share = 0.045;
uniform vec3 glint_color : source_color = vec3(1.0, 0.93, 0.7);
uniform vec3 trough_color : source_color = vec3(0.13, 0.31, 0.56);
uniform vec2 drift = vec2(0.5, 0.25);
uniform vec3 ring_color : source_color = vec3(0.86, 0.95, 1.0);
uniform float clock = 0.0;
uniform vec4 ripples[8];   // x, z of the centre, clock time it began, life (0 = unused; < 0 = strong)
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = (floor(world.xz * 16.0) + 0.5) / 16.0;
	float t = TIME;
	float ring = 0.0;
	for (int i = 0; i < 8; i++) {
		vec4 r = ripples[i];
		float life = abs(r.w);
		float age = clock - r.z;
		if (r.w != 0.0 && age >= 0.0 && age < life) {
			float radius = floor(age * 14.0 * (r.w < 0.0 ? 1.3 : 1.0) + 0.5);
			float maxr = r.w < 0.0 ? 34.0 : 22.0;
			float d = length((p - r.xy) * 16.0);
			if (radius <= maxr && abs(d - radius) < 0.8) {
				ring = max(ring, age / life < 0.55 ? 0.6 : 0.3);
			}
		}
	}
	if (ring > 0.0) {
		ALBEDO = ring_color;
		ALPHA = ring;
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
	} else {
	vec2 q = p - drift * t * 0.18;
	float a = sin(q.x * 2.3 + q.y * 1.1 + t * 0.55) + sin(q.x * 1.3 - q.y * 2.5 - t * 0.4);
	float b = sin((q.x + q.y) * 3.7 + sin(q.y * 2.1 + t * 0.5) * 1.7 - t * 0.9);
	float h = 0.25 * a + 0.5 * b;   // -1 .. 1
	if (h > 0.62) {
		ALBEDO = glint_color;
		ALPHA = 0.5;
	} else if (h < -0.7) {
		ALBEDO = trough_color;
		ALPHA = 0.32;
	} else {
		discard;
	}
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	}
}
void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * sun_share;
}
"""

## The quads laid, as {cell, rect} (the rect in world x, z), for tests.
var quads: Array[Dictionary] = []

var clock := 0.0                         # seconds since the sheet was made; the rings' time
var ripples := PackedVector4Array()      # the slots the shader reads (see `ripple`)
var _next_slot := 0


func _process(delta: float) -> void:
	advance(delta)


## Moves the rings' clock on (called every frame; tests call it by hand).
func advance(delta: float) -> void:
	clock += delta
	var m := material_override as ShaderMaterial
	if m != null:
		m.set_shader_parameter("clock", clock)


## Starts a ring spreading from `at` (world x, z). A strong one (a bite) is quicker, wider
## and lasts longer. The oldest of the MAX_RIPPLES slots is reused when all are busy.
func ripple(at: Vector2, strong := false) -> void:
	if ripples.size() != MAX_RIPPLES:
		ripples.resize(MAX_RIPPLES)
	var life := RING_LIFE_STRONG if strong else RING_LIFE
	ripples[_next_slot] = Vector4(at.x, at.y, clock, -life if strong else life)
	_next_slot = (_next_slot + 1) % MAX_RIPPLES
	var m := material_override as ShaderMaterial
	if m != null:
		m.set_shader_parameter("ripples", ripples)


## How many rings are still spreading now.
func ripples_alive() -> int:
	var n := 0
	for r in ripples:
		if r.w != 0.0 and clock - r.z < absf(r.w):
			n += 1
	return n


## Lays the sheet over every water cell of a w x h map and the apron round it (cells past the
## edge take the nearest edge cell's kind, as Surroundings does). `kind_at(c)` is an in-map
## cell's ground kind. `back`: the apron past the north and west edges when it is shorter
## (Surroundings' rim before the far country), else `margin`.
func build(w: int, h: int, kind_at: Callable, margin: int, back := -1) -> void:
	var near := margin if back < 0 else back
	var cells: Array[Vector2i] = []
	for y in range(-near, h + margin):
		for x in range(-near, w + margin):
			var c := Vector2i(x, y)
			if is_water(kind_at, w, h, c):
				cells.append(c)
	set_cells(cells, func(c: Vector2i) -> bool: return is_water(kind_at, w, h, c))


static func is_water(kind_at: Callable, w: int, h: int, c: Vector2i) -> bool:
	return kind_at.call(Surroundings.edge_cell(c, w, h)) == "water"


## One quad a cell, pulled in from each side that touches land (`water_at(c)` false).
func set_cells(cells: Array[Vector2i], water_at: Callable) -> void:
	quads.clear()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in cells:
		var x0 := c.x + (0.0 if water_at.call(c + Vector2i.LEFT) else LAND_INSET)
		var x1 := c.x + 1.0 - (0.0 if water_at.call(c + Vector2i.RIGHT) else LAND_INSET)
		var z0 := c.y + (0.0 if water_at.call(c + Vector2i.UP) else LAND_INSET)
		var z1 := c.y + 1.0 - (0.0 if water_at.call(c + Vector2i.DOWN) else LAND_INSET)
		quads.append({"cell": c, "rect": Rect2(x0, z0, x1 - x0, z1 - z0)})
		var v := [Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x0, 0, z1)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v[i])
	mesh = st.commit() if not cells.is_empty() else null
	position = Vector3(0, LIFT, 0)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layers = NightLamps.GROUND_LAYER   # lit as the ground: the night's lamps leave it out
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("sun_share", SnowLayer.SUN_SHARE)
	ripples.resize(MAX_RIPPLES)
	m.set_shader_parameter("ripples", ripples)
	m.set_shader_parameter("clock", clock)
	material_override = m
