class_name MistLayer
extends Node3D
## Morning mist lying low over an outdoor map's water and paddies in 3D (rules: MistRules,
## data/mist.json): soft flat sheets just above the ground in one MultiMesh, drifting slowly on
## the world's wind (FarmWorld.wind, the rice's and the hearth smoke's) and thinning with it.
## No volumetric fog (the Compatibility renderer has none): each sheet is a horizontal quad whose
## shader fades it from the middle out and breaks it into wisps with a slow world-locked noise,
## so overlapping sheets read as one bank. Unshaded and never writing depth, so the day / night
## tint lies over it as over the field and whatever stands in it stays whole behind it. Coloured
## by MistRules.color_now (the dawn sky's hue). Only outdoor maps build one.

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

varying vec2 world_xz;

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
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float fall = smoothstep(1.0, 0.15, length(p));
	vec2 q = world_xz * 0.9 + vec2(TIME * 0.035, TIME * 0.012);
	float wisp = 0.6 * noise(q) + 0.4 * noise(q * 2.3 + 7.1);
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * fall * (0.35 + 0.9 * wisp);
}
"""

static var _shader: Shader

var map: MapData
var farm: FarmGrid
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _mm: MultiMesh
var _mmi: MultiMeshInstance3D


func _init(m: MapData, f: FarmGrid = null) -> void:
	map = m
	farm = f
	name = "Mist"
	_t = float(m.w * 23 + m.h * 11) * 0.41
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var q := PlaneMesh.new()
	q.size = Vector2.ONE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	q.material = mat
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = q
	_mm.instance_count = int(MistRules.config().max)
	_mm.visible_instance_count = 0
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = _mm
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mmi.extra_cull_margin = 50.0
	add_child(_mmi)


func _ready() -> void:
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock, the weather and the wind, then lays the sheets.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var world := get_parent() as FarmWorld
	var wind: float = world.wind if world != null else (float(game.wind_strength()) if game != null else 0.0)
	var amounts := MistRules.amounts_now(game, map, wind)
	if amounts.is_empty():
		_mm.visible_instance_count = 0
		return
	var key := "%s|%d|%d" % [map.id, game.season, game.day]
	if key != _scene_key:
		_scene_key = key
		_scene = MistRules.scene_of(map, farm)
	var shown := MistRules.sheets(_scene, amounts, _t, wind, game.season_name())
	shown = shown.slice(0, _mm.instance_count)
	var rgb := MistRules.color_now(game)
	_mm.visible_instance_count = shown.size()
	for i in shown.size():
		var s: Dictionary = shown[i]
		var size: Vector2 = s.size
		var b := Basis(Vector3.UP, -float(s.angle)) * Basis.from_scale(Vector3(size.x, 1.0, size.y))
		_mm.set_instance_transform(i, Transform3D(b, s.pos))
		_mm.set_instance_color(i, Color(rgb, float(s.alpha)))


## How many sheets are showing (for tests).
func shown_count() -> int:
	return _mm.visible_instance_count
