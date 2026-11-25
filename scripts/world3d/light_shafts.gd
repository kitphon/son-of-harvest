class_name LightShafts
extends Node3D
## Shafts of sunlight slanting down through the steam over a shaded map's water (2026-11-25, the
## user: Kajika-yu shadier; a map's `shade` `shafts`): a few long soft quads from the canopy's height
## down to the water, turned to the play camera's fixed yaw and leaning a little, glowing additively,
## brightest along their middle and fading at both ends; their strength by DappleRules.shaft_strength
## (the sun's shadows times the clock's curve: the low sun of morning and late afternoon), a slow
## shimmer each its own. The 3D view only: seen from above in the flat view they would be nothing.

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float strength = 0.0;
uniform vec3 color : source_color = vec3(1.0, 0.94, 0.78);
uniform float phase = 0.0;

void fragment() {
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	across = across * across;
	float along = smoothstep(0.0, 0.55, UV.y) * (1.0 - smoothstep(0.88, 1.0, UV.y));   // out of the leaves, brightest low in the steam, gone at the water
	float shimmer = 0.75 + 0.25 * sin(TIME * 0.6 + phase + UV.y * 2.0);
	ALBEDO = color * strength * across * along * shimmer;
}
"""
const LENGTH := 5.5     # units, from the leaves to the water
const WIDTH := 1.3
const LEAN := 18.0      # degrees off upright on screen
const YAW := 45.0       # faced to the play camera (CameraLens.YAW)

static var _shader: Shader

var map: MapData
var _mats: Array[ShaderMaterial] = []


func _init(m: MapData) -> void:
	map = m
	name = "LightShafts"
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var cfg: Dictionary = m.shade.get("shafts", {})
	var col := Color(str(cfg.get("color", "fff0c8")))
	for k in (cfg.get("at", []) as Array).size():
		var at: Array = cfg.at[k]
		var quad := QuadMesh.new()
		quad.size = Vector2(WIDTH * (0.8 + 0.25 * (k % 3)), LENGTH)
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := ShaderMaterial.new()
		mat.shader = _shader
		mat.set_shader_parameter("color", Vector3(col.r, col.g, col.b))
		mat.set_shader_parameter("phase", float(k) * 1.7)
		mi.material_override = mat
		_mats.append(mat)
		var lean := deg_to_rad(LEAN + 4.0 * (k % 2))
		mi.basis = Basis(Vector3.UP, deg_to_rad(YAW)) * Basis(Vector3.BACK, lean)
		var foot := Vector3(float(at[0]) + 0.5, BathProps.ONSEN_WATER, float(at[1]) + 0.5)
		mi.position = foot + mi.basis.y * (LENGTH / 2.0)
		add_child(mi)


func _process(_delta: float) -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var s := DappleRules.shaft_strength(game, map)
	visible = s > 0.0
	for mat in _mats:
		mat.set_shader_parameter("strength", s)


## How many shafts stand (for tests).
func count() -> int:
	return _mats.size()
