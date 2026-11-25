class_name DappleLayer
extends MeshInstance3D
## The leaf shadows (komorebi, DappleRules) over a shaded map in 3D: one sheet over the whole map a
## little above the ground, multiplying what lies under it (the ground and the sunk water; props and
## figures standing in front of it keep their own light), its pattern in whole texture pixels, its
## strength following the sun's shadows, drifting as the wind stirs the leaves.

const LIFT := 0.03
const SHADER := """
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float strength = 0.0;
uniform vec3 shade_color : source_color = vec3(0.72, 0.78, 0.66);
uniform float clock = 0.0;
varying vec2 world_xz;

float hash(vec2 p) {
	return fract(sin(p.x * 127.1 + p.y * 311.7) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = p - i;
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 px = (floor(world_xz * 16.0) + 0.5) / 16.0;
	vec2 q = px * 0.9 + vec2(clock * 0.05, clock * 0.02);
	float n = 0.6 * noise(q) + 0.4 * noise(q * 2.3 + vec2(7.1, 3.3));
	float fleck = smoothstep(0.58, 0.68, n);
	ALBEDO = mix(vec3(1.0), mix(shade_color, vec3(1.0), fleck), strength);
}
"""

static var _shader: Shader

var map: MapData
var clock := 0.0


func _init(m: MapData) -> void:
	map = m
	name = "Dapple"
	var plane := PlaneMesh.new()
	plane.size = Vector2(m.w, m.h)
	mesh = plane
	position = Vector3(m.w / 2.0, LIFT, m.h / 2.0)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	var c := DappleRules.shade_color(m)
	mat.set_shader_parameter("shade_color", Vector3(c.r, c.g, c.b))
	material_override = mat
	clock = float(m.w * 7 + m.h * 3)


func _process(delta: float) -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var wind: float = float(game.wind_strength()) if game != null else 0.0
	clock += delta * (0.5 + wind)   # the leaves stir faster in the wind
	var s := DappleRules.strength(game, map)
	visible = s > 0.0
	var mat := material_override as ShaderMaterial
	mat.set_shader_parameter("strength", s)
	mat.set_shader_parameter("clock", clock)
