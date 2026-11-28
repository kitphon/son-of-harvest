class_name KakehiFlow
extends Node3D
## The moving water of a bamboo spout (Kakehi; the culm and its stand are BathProps' kept meshes):
## the thin stream falling in an arc from its open end to the pool's water (two crossed ribbons,
## so it reads from any side, streaks running down them), a patch of white foam where it lands,
## and a ring spreading on the water sheet from there every Kakehi.RING_EVERY seconds. Unshaded,
## so the day / night tint lies over it as over the water. MapWorld makes one a spout, each time
## (it moves: not kept).

const STEPS := 8                 # pieces of the arc
const WIDTH := Vector2(0.08, 0.11)   # the stream's width at the mouth and where it lands
const FOAM := 0.42               # the foam's size, units

const STREAM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

void fragment() {
	float across = abs(UV.x * 2.0 - 1.0);
	float streak = 0.5 + 0.5 * sin(UV.y * 46.0 - TIME * 24.0 + floor(UV.x * 3.0) * 2.1);
	ALBEDO = mix(vec3(0.72, 0.86, 0.84), vec3(1.0), 0.35 + 0.45 * streak);
	ALPHA = (1.0 - smoothstep(0.45, 1.0, across)) * (0.5 + 0.35 * streak);
}
"""

const FOAM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	vec2 cell = floor(UV * 14.0);
	float flick = hash(cell + floor(TIME * 9.0));
	ALBEDO = vec3(0.95, 0.98, 0.97);
	ALPHA = smoothstep(1.0, 0.2, r) * (0.25 + 0.6 * step(0.45 + r * 0.4, flick));
}
"""

static var _stream_shader: Shader
static var _foam_shader: Shader

var spot: Dictionary          # Kakehi.places
var water_y := 0.0            # the water's top it falls to
var _clock := 0.0
var stream: MeshInstance3D
var foam: MeshInstance3D


func _init(places: Dictionary, water_top: float) -> void:
	spot = places
	water_y = water_top
	name = "Kakehi"
	if _stream_shader == null:
		_stream_shader = Shader.new()
		_stream_shader.code = STREAM_SHADER
		_foam_shader = Shader.new()
		_foam_shader.code = FOAM_SHADER
	stream = MeshInstance3D.new()
	stream.name = "Stream"
	stream.mesh = _arc_mesh()
	stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sm := ShaderMaterial.new()
	sm.shader = _stream_shader
	stream.material_override = sm
	add_child(stream)
	foam = MeshInstance3D.new()
	foam.name = "Foam"
	var plane := PlaneMesh.new()
	plane.size = Vector2(FOAM, FOAM)
	foam.mesh = plane
	foam.position = Vector3(spot.landing.x, water_y + 0.012, spot.landing.y)
	foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fm := ShaderMaterial.new()
	fm.shader = _foam_shader
	foam.material_override = fm
	add_child(foam)


func _process(delta: float) -> void:
	var from := _clock
	_clock += delta
	if Kakehi.rings_between(from, _clock) > 0:
		var world := get_parent() as FarmWorld
		if world != null and world.surroundings != null and world.surroundings.water != null:
			world.surroundings.water.ripple(spot.landing, false)


## Where the stream is `t` (0 at the mouth, 1 on the water) along its fall (Kakehi.arc_at).
func arc_at(t: float) -> Vector3:
	return Kakehi.arc_at(spot, water_y, t)


## The stream as two ribbons crossed along the arc (one wide across the way it runs, one along it).
func _arc_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var d: Vector2 = spot.dir
	var across := Vector3(-d.y, 0, d.x)
	var run := Vector3(d.x, 0, d.y)   # the second ribbon wide along the way it runs: across the steep fall
	for wide in [across, run]:
		for i in STEPS:
			var t0 := float(i) / STEPS
			var t1 := float(i + 1) / STEPS
			var a := arc_at(t0)
			var b := arc_at(t1)
			var w0: Vector3 = wide * lerpf(WIDTH.x, WIDTH.y, t0) * 0.5
			var w1: Vector3 = wide * lerpf(WIDTH.x, WIDTH.y, t1) * 0.5
			if wide == run:   # a little thinner seen side on
				w0 *= 0.6
				w1 *= 0.6
			for q in [[a - w0, Vector2(0, t0)], [a + w0, Vector2(1, t0)], [b + w1, Vector2(1, t1)], [a - w0, Vector2(0, t0)], [b + w1, Vector2(1, t1)], [b - w1, Vector2(0, t1)]]:
				st.set_uv(q[1])
				st.set_normal(Vector3.UP)
				st.add_vertex(q[0])
	return st.commit()
