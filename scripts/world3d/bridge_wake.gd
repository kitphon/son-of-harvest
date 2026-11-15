class_name BridgeWake
extends MeshInstance3D
## The river breaking round a bridge's legs (TempleProps.bridge), so the water is seen running on
## under the deck: at each leg a small white wake on the water's skin, a V of dashed foam lines
## opening downstream (the river runs east, +x), the dashes stepping along it at the current's
## pace, and a little cap of foam against the leg's upstream face. Drawn in whole world pixels
## (16 a cell) like the water's skin (WaterSurface), unshaded, a hair over it on the sunk water.
## One mesh for all the legs; its UVs are each quad's place from its leg, in cells.

const SHADER := """shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 foam : source_color = vec4(0.93, 0.97, 1.0, 0.8);
uniform float speed = 9.0;   // px a second downstream
void fragment() {
	vec2 q = floor(UV * 16.0) + 0.5;   // px from the leg: x downstream, y across
	float spread = 1.2 + max(q.x, 0.0) * 0.3;
	float wake = step(abs(abs(q.y) - spread), 0.55) * step(0.0, q.x);
	float dash = step(fract((q.x - TIME * speed) / 6.0), 0.5);
	float fade = 1.0 - clamp(q.x / 16.0, 0.0, 1.0);
	float cap = step(length(vec2(q.x + 1.0, q.y * 0.8)), 2.2) * step(0.35, fract(TIME * 1.7 + q.y * 0.31));
	ALBEDO = foam.rgb;
	ALPHA = max(wake * dash * fade, cap * 0.9) * foam.a;
}
"""

const BACK := 0.25    # cells of the quad upstream of a leg (for the cap)
const AHEAD := 1.2    # cells downstream (the V)
const ACROSS := 0.45  # cells either side

static var _shader: Shader


## The wakes round `legs` (cells, x / z), on the sunk water's skin.
static func make(legs: Array[Vector2]) -> BridgeWake:
	var w := BridgeWake.new()
	w.name = "BridgeWake"
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := -SunkenGround.DROP + WaterSurface.LIFT + 0.006
	for leg in legs:
		var c := [Vector2(-BACK, -ACROSS), Vector2(AHEAD, -ACROSS), Vector2(AHEAD, ACROSS), Vector2(-BACK, ACROSS)]
		for i in [0, 1, 2, 0, 2, 3]:
			var o: Vector2 = c[i]
			st.set_normal(Vector3.UP)
			st.set_uv(o)
			st.add_vertex(Vector3(leg.x + o.x, y, leg.y + o.y))
	if not legs.is_empty():
		w.mesh = st.commit()
	w.material_override = mat
	w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return w


## How many legs it breaks round (for tests).
func legs() -> int:
	if mesh == null or mesh.get_surface_count() == 0:
		return 0
	return mesh.surface_get_array_len(0) / 6
