class_name FootprintLayer
extends Node3D
## Footprints in lying snow in the 3D view (rules: Footprints). One MultiMesh of small flat
## soles just over the ground; a print is a cool blue-grey dent (a pixel-stepped sole drawn by
## the shader) that fades with its age. Lit like the ground: the same sun share, so it takes
## shadows and the day / night light, and it casts none.

const LIFT := 0.025   # over the ground, which snow lies on at y = 0
const GRID := Vector2(5.0, 8.0)   # the sole's pixel grid

const SHADER := "shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
" + SnowLayer._SNOW_AT + """
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
uniform vec3 tone : source_color = vec3(0.37, 0.46, 0.67);
uniform float strength = 0.8;
uniform float sun_share = 0.045;
uniform vec2 grid = vec2(5.0, 8.0);
float inside(vec2 p, vec2 c, vec2 r) {
	vec2 q = (p - c) / r;
	return dot(q, q) <= 1.0 ? 1.0 : 0.0;
}
void fragment() {
	// Only where snow lies at this pixel (the ground shader's own test; COLOR.r = what the ground holds)
	if (snow_at(world.xz, cover * COLOR.r) < 1.5) discard;
	vec2 p = (floor(UV * grid) + 0.5) / grid;   // pixel-stepped: the toe at v = 0
	float sole = max(inside(p, vec2(0.5, 0.3), vec2(0.5, 0.29)), inside(p, vec2(0.5, 0.8), vec2(0.34, 0.19)));
	ALBEDO = tone;
	ALPHA = sole * strength * COLOR.a;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * sun_share;
}
"""

var trail: Footprints
var _mm: MultiMesh
var _node: MultiMeshInstance3D
var _mat: ShaderMaterial
var _dirty := false


func _init() -> void:
	trail = Footprints.from_game()
	var quad := QuadMesh.new()
	quad.orientation = PlaneMesh.FACE_Y
	var size: Array = trail.rules.size
	quad.size = Vector2(float(size[0]), float(size[1]))
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = quad
	_mm.instance_count = int(trail.rules.cap)
	_mm.visible_instance_count = 0
	var mat := ShaderMaterial.new()
	mat.shader = SnowLayer.shader(SHADER)
	mat.set_shader_parameter("tone", Color(str(trail.rules.color)))
	mat.set_shader_parameter("strength", float(trail.rules.alpha))
	mat.set_shader_parameter("sun_share", SnowLayer.SUN_SHARE)
	mat.set_shader_parameter("grid", GRID)
	mat.set_shader_parameter("noise", SnowLayer.noise_texture())
	_mat = mat
	_node = MultiMeshInstance3D.new()
	_node.multimesh = _mm
	_node.material_override = mat
	_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_node)


## The walkers' places now ({id: Vector2 cell position}); makes prints while snow lies enough.
func feed(walkers: Dictionary, cover: float, sheltered: bool, hold: Callable) -> void:
	_mat.set_shader_parameter("cover", cover / 100.0)
	if not trail.active(cover, sheltered):
		if not trail.prints.is_empty():
			clear()
		return
	if trail.feed(walkers, hold) > 0:
		_dirty = true
	if _dirty:
		_redraw()


func age(minutes: float, snowing: bool) -> void:
	trail.age(minutes, snowing)
	_redraw()


func clear() -> void:
	trail.clear()
	_redraw()


func count() -> int:
	return _mm.visible_instance_count


func _redraw() -> void:
	_dirty = false
	var n := mini(trail.prints.size(), _mm.instance_count)
	_mm.visible_instance_count = n
	for i in n:
		var p: Dictionary = trail.prints[i]
		var at := Vector3(p.pos.x, LIFT, p.pos.y)
		var basis := Basis.looking_at(Vector3(p.dir.x, 0.0, p.dir.y), Vector3.UP)   # the toe, -z, ahead
		_mm.set_instance_transform(i, Transform3D(basis, at))
		_mm.set_instance_color(i, Color(float(p.get("hold", 1.0)), 1, 1, trail.strength(p)))
