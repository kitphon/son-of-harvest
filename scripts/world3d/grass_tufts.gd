class_name GrassTufts
extends MultiMeshInstance3D
## Tufts of grass standing on the grass cells (the farm's untilled ground, outdoor maps, the
## apron past their edges): one MultiMesh of a small fan of blades, a gentle sway in the
## wind from the shader, lit like the ground (flat, the sun only for its shadows, so a tuft
## is no brighter than the grass it grows from). Each tuft carries its cell's snow hold in
## its custom data and folds away where the ground under its root lies white (the same
## noise as SnowLayer's ground), so snow never shows green blades through it. The tips take
## the season's colour: fresh in spring, deep in summer, straw in fall, dry in winter.

const PER_CELL := 2         # tufts a grass cell may hold
const SHARE := 70           # % of those places that grow one, picked by the place
const TIPS := {"spring": Color("92d464"), "summer": Color("74b44a"), "fall": Color("c4b060"), "winter": Color("a89a68")}
const BLADES := [[0.2, 0.4], [0.16, 2.1], [0.24, 3.4], [0.14, 4.6], [0.18, 5.7]]   # height, angle
const SWAY := 0.035         # how far a tip swings (units)

## What was planted: the spots_for() entries with their snow `hold` (the MultiMesh's own
## data can't be read back under the headless renderer).
var planted: Array[Dictionary] = []

const SHADER := "shader_type spatial;\nrender_mode cull_disabled;\n" + SnowLayer._SNOW_AT + """
uniform vec3 tip : source_color = vec3(0.55, 0.8, 0.35);
uniform float sun_share = 0.7;
uniform float sway = 0.035;
void vertex() {
	vec3 root = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	if (snow_at(root.xz, cover * INSTANCE_CUSTOM.r) > 0.5) {
		VERTEX = vec3(0.0);   // under snow: folded away
	} else {
		float k = COLOR.r * COLOR.r;
		float t = TIME * 1.6 + root.x * 0.7 + root.z * 0.45;
		VERTEX.x += sin(t) * sway * k;
		VERTEX.z += sin(t * 0.8 + 1.3) * sway * 0.5 * k;
	}
	COLOR.rgb = mix(tip * 0.8, tip, COLOR.r) * (0.9 + 0.2 * INSTANCE_CUSTOM.g);
}
void fragment() {
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);   // lit as the ground, both faces
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * sun_share;
}
"""


func _init() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = tuft_mesh()
	var m := SnowLayer._material(SHADER)
	m.set_shader_parameter("sun_share", SnowLayer.SUN_SHARE)
	m.set_shader_parameter("sway", SWAY)
	m.set_shader_parameter("tip", TIPS.get(Game.season_name(), TIPS.spring))
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## The tufts' material (FarmWorld keeps it with its snow so set_snow drives the cover).
func snow_material() -> ShaderMaterial:
	return material_override


## Grows tufts on `cells` (grass cells); `hold_at(c)` is how much snow the cell holds.
func plant(cells: Array[Vector2i], hold_at: Callable) -> void:
	var spots := spots_for(cells)
	multimesh.instance_count = spots.size()
	for i in spots.size():
		var s: Dictionary = spots[i]
		multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, s.turn).scaled(Vector3.ONE * s.size), s.pos))
		s.hold = float(hold_at.call(s.cell))
		multimesh.set_instance_custom_data(i, Color(s.hold, s.shade, 0, 0))
	planted = spots


## Where the tufts stand on `cells`: up to PER_CELL a cell, each place kept or not, nudged,
## turned, sized and shaded by its own hash, so a cell always grows the same tufts.
static func spots_for(cells: Array[Vector2i]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in cells:
		for k in PER_CELL:
			if _rand(c, k, 0) * 100.0 >= SHARE:
				continue
			var pos := Vector3(c.x + 0.15 + 0.7 * _rand(c, k, 1), 0.0, c.y + 0.15 + 0.7 * _rand(c, k, 2))
			out.append({"cell": c, "pos": pos, "turn": _rand(c, k, 3) * TAU,
				"size": 0.8 + 0.45 * _rand(c, k, 4), "shade": _rand(c, k, 5)})
	return out


## One tuft: a fan of thin blades round its root, each leaning out; the vertex colour's red is
## the height share (0 at the root, 1 at the tip) for the shader's shading and sway.
static func tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in BLADES:
		var high: float = b[0]
		var a: float = b[1]
		var out := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-out.z, 0, out.x) * 0.035
		var foot := out * 0.025
		for p in [[foot - side, 0.0], [foot + side, 0.0], [out * 0.07 + Vector3(0, high, 0), 1.0]]:
			st.set_color(Color(p[1], 0, 0))
			st.set_normal(Vector3.UP)
			st.add_vertex(p[0])
	return st.commit()


## A number 0..1 fixed by the cell, the place in it and what it is for.
static func _rand(c: Vector2i, k: int, what: int) -> float:
	return posmod(hash(Vector4i(c.x, c.y, k, what)), 10007) / 10007.0
