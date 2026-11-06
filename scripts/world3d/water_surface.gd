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

const T := 16
const LAND_INSET := 3.0 / T   # a bank is 2 px wide and the foam line 1 px; the sheet starts after them
const LIFT := 0.01            # above the ground picture (the apron lies 0.02 below the map)

const SHADER := """shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
varying vec3 world;
uniform float sun_share = 0.045;
uniform vec3 glint_color : source_color = vec3(1.0, 0.93, 0.7);
uniform vec3 trough_color : source_color = vec3(0.13, 0.31, 0.56);
uniform vec2 drift = vec2(0.5, 0.25);
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = (floor(world.xz * 16.0) + 0.5) / 16.0;
	float t = TIME;
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
void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * sun_share;
}
"""

## The quads laid, as {cell, rect} (the rect in world x, z), for tests.
var quads: Array[Dictionary] = []


## Lays the sheet over every water cell of a w x h map and the apron round it (cells past the
## edge take the nearest edge cell's kind, as Surroundings does). `kind_at(c)` is an in-map
## cell's ground kind.
func build(w: int, h: int, kind_at: Callable, margin: int) -> void:
	var cells: Array[Vector2i] = []
	for y in range(-margin, h + margin):
		for x in range(-margin, w + margin):
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
	material_override = m
