class_name SteamWisps
extends Node3D
## Steam rising off a hot spring's open water in thin wisps (MistRules.wisp_spots / wisps,
## data/mist.json `onsen` `wisps`; 2026-11-28, the user asked for the pool to feel alive): soft
## upright quads in one MultiMesh, each facing the camera, its foot on the water, rising, swelling
## and fading, broken into strands by a slow noise in world space that climbs with them. Over the
## mist's flat sheets that lie on the water (MistLayer). Unshaded and never writing depth, so the
## day / night tint lies over them and what stands in them stays whole; the steam's own colour
## (MistRules.color_now's `onsen`). Only maps with water of look `onsen` build one (MapWorld).

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

varying vec3 world;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float up = 1.0 - UV.y;   // 0 at its foot on the water, 1 at its top
	float body = smoothstep(1.0, 0.25, abs(p.x) * (1.2 - 0.5 * up)) * smoothstep(0.0, 0.15, up) * (1.0 - smoothstep(0.55, 1.0, up));
	vec2 q = vec2(world.x * 2.6 + world.z * 1.7 + p.x * 1.5, world.y * 2.2 - TIME * 0.55);
	float strand = 0.65 * noise(q) + 0.35 * noise(q * 2.4 + 3.7);
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * body * smoothstep(0.15, 0.7, strand);
}
"""

static var _shader: Shader

var map: MapData
var water_y := 0.0           # the water's top the wisps rise from
var spots: Array[Vector2] = []
var _t := 0.0
var _mm: MultiMesh
var _shown: Array[Dictionary] = []


func _init(m: MapData, water_top: float) -> void:
	map = m
	water_y = water_top
	name = "SteamWisps"
	spots = MistRules.wisp_spots(PondShape.of(m, "onsen"))
	_t = float(m.w * 13 + m.h * 7) * 0.37
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	q.material = mat
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = q
	_mm.instance_count = int((MistRules.config().get("onsen", {}).get("wisps", {}) as Dictionary).get("count", 0))
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.extra_cull_margin = 30.0
	add_child(mmi)


func _ready() -> void:
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the steam's thickness now and lays the wisps, each turned to the camera.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var world := get_parent() as FarmWorld
	var wind: float = world.wind if world != null else 0.0
	var amount := float(MistRules.amounts_now(game, map, wind).get("onsen", 0.0))
	_shown = MistRules.wisps(spots, amount, _t, wind)
	_shown = _shown.slice(0, _mm.instance_count)
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var right := Vector3.RIGHT
	var up := Vector3.UP
	var back := Vector3.BACK
	if cam != null:
		right = cam.global_basis.x
		up = cam.global_basis.y
		back = cam.global_basis.z
	var col := MistRules.color_now(game, {}, "onsen") if game != null else Color.WHITE
	_mm.visible_instance_count = _shown.size()
	for i in _shown.size():
		var s: Dictionary = _shown[i]
		var size: Vector2 = s.size
		var pos: Vector3 = s.pos
		var foot := Vector3(pos.x, water_y + pos.y, pos.z)
		_mm.set_instance_transform(i, Transform3D(Basis(right * size.x, up * size.y, back), foot + up * size.y * 0.5))
		_mm.set_instance_color(i, Color(col, float(s.alpha)))


## The wisps showing now (for tests): MistRules.wisps.
func shown() -> Array[Dictionary]:
	return _shown
