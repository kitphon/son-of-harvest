class_name PuddleLayer
extends Node3D
## Puddles on the bare ground of an outdoor map in rain, in 3D (rules: PuddleRules,
## data/puddles.json): one MultiMesh of flat quads just over the ground, one for each place the
## rules give. Each quad is an ellipse a little wobbly on its edge, a dark wet tone with a thin darker rim
## and a soft sky reflection on its far side; while it rains the shader draws rain rings in it
## (the water's own dimple style). Lit like the ground (the sun's share only), so it takes the
## day / night light. The instances are rewritten only when the wetness moves a step.

const GROUP := "puddle_layers"
const LIFT := 0.02   # over the ground

const SHADER := "shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
uniform vec3 wet_color : source_color = vec3(0.23, 0.28, 0.34);
uniform vec3 sky_color : source_color = vec3(0.7, 0.77, 0.85);
uniform vec3 rim_color : source_color = vec3(0.16, 0.2, 0.25);
uniform vec3 ring_color : source_color = vec3(0.84, 0.88, 0.93);
uniform float core_alpha = 0.66;
uniform float rim_alpha = 0.42;
uniform float sky_amount = 0.55;
uniform float rain_on = 0.0;
uniform float dimple_density = 0.5;
uniform float dimple_life = 0.9;
uniform float ring_reach = 0.55;
uniform float sun_share = 0.045;
float h21(vec2 v) { return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float seed = COLOR.r;
	float ang = atan(p.y, p.x);
	float wob = 1.0 + 0.1 * sin(ang * 3.0 + seed * 40.0) + 0.06 * sin(ang * 5.0 + seed * 17.0);
	float d = length(p) / wob;
	if (d > 1.0) { discard; }
	vec3 c = wet_color;
	float a = core_alpha;
	if (d > 0.78) {
		c = rim_color;
		a = rim_alpha;
	} else {
		float far = clamp(0.5 - p.y * 0.5, 0.0, 1.0);   // the far (upper) side holds the sky
		c = mix(c, sky_color, sky_amount * smoothstep(0.4, 0.95, far) * (1.0 - d * 0.5));
	}
	if (rain_on > 0.5) {
		for (int i = 0; i < 2; i++) {
			float u = TIME / dimple_life + h21(vec2(seed * 91.0, float(i) + 5.0)) * 7.0;
			float slot = floor(u);
			float ph = fract(u);
			if (h21(vec2(seed * 53.0 + slot * 0.37, float(i) + 17.0)) < dimple_density) {
				vec2 ctr = vec2(cos(h21(vec2(seed + slot, 3.0 + float(i))) * 6.2832), sin(h21(vec2(seed + slot, 8.0 + float(i))) * 6.2832))
					* h21(vec2(slot * 1.7, seed * 29.0 + float(i))) * 0.5;
				float ring = abs(length(p - ctr) - ph * ring_reach);
				if (ring < 0.07 && d < 0.9) {
					c = mix(c, ring_color, 1.0 - ph);
					a = max(a, 0.9 * (1.0 - ph));
				}
			}
		}
	}
	ALBEDO = c;
	ALPHA = a;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * sun_share;
}
"

var map: MapData
var farm: FarmGrid
var _places: Array[Dictionary] = []
var _step := -1
var _day_key := ""
var _raining := false
var _mm: MultiMesh
var _mmi: MultiMeshInstance3D
var _mat: ShaderMaterial


func _init(m: MapData, f: FarmGrid = null) -> void:
	map = m
	farm = f
	name = "Puddles"
	var cfg := PuddleRules.config()
	var quad := QuadMesh.new()
	quad.orientation = PlaneMesh.FACE_Y
	quad.size = Vector2.ONE
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = quad
	_mat = ShaderMaterial.new()
	_mat.shader = SnowLayer.shader(SHADER)
	_mat.render_priority = -1   # under the figures standing at its edge
	_mat.set_shader_parameter("sun_share", SnowLayer.SUN_SHARE)
	_mat.set_shader_parameter("wet_color", Color(str(cfg.colors.wet)))
	_mat.set_shader_parameter("sky_color", Color(str(cfg.colors.sky)))
	_mat.set_shader_parameter("rim_color", Color(str(cfg.colors.rim)))
	_mat.set_shader_parameter("ring_color", Color(str(cfg.colors.ring)))
	_mat.set_shader_parameter("core_alpha", float(cfg.alpha.core))
	_mat.set_shader_parameter("rim_alpha", float(cfg.alpha.rim))
	_mat.set_shader_parameter("sky_amount", float(cfg.alpha.sky))
	_mat.set_shader_parameter("ring_reach", float(cfg.dimple.ring))
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = _mm
	_mmi.material_override = _mat
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mmi.extra_cull_margin = 50.0
	add_child(_mmi)
	_set_places(PuddleRules.puddles(m, f))
	visible = false


func _ready() -> void:
	add_to_group(GROUP)
	refresh()


func _process(_delta: float) -> void:
	refresh()


func _set_places(places: Array[Dictionary]) -> void:
	_places = places
	_mm.visible_instance_count = 0
	_mm.instance_count = _places.size()
	_mm.visible_instance_count = 0
	_step = -1


## Reads the weather and the clock; redoes the quads when the wetness moved a step.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if game == null:
		return
	var wet := PuddleRules.wetness_now(game, map)
	var step := PuddleRules.step_of(wet)
	var key := "%s|%d|%d" % [map.id, game.season, game.day]
	if key != _day_key:   # a new day: the farm's doorsteps may have moved (a coop, a barn)
		_day_key = key
		if farm != null:
			_set_places(PuddleRules.puddles(map, farm))
	if step != _step:
		_step = step
		_place(float(step) / 50.0)
	var rain := wet > 0.0 and PuddleRules.raining_now(game, map)
	if rain != _raining:
		_raining = rain
		_mat.set_shader_parameter("rain_on", 1.0 if rain else 0.0)
		if rain:
			var style: Dictionary = game.dimple_style()
			_mat.set_shader_parameter("dimple_density", float(style.get("density", 0.2)) * float(PuddleRules.config().dimple.scale))
			_mat.set_shader_parameter("dimple_life", float(style.get("life", 0.9)))


func _place(wet: float) -> void:
	var n := 0
	for p in _places:
		var s := PuddleRules.scale_of(p, wet)
		if s <= 0.0:
			continue
		var b := Basis.IDENTITY.scaled(Vector3(float(p.rx) * 2.0 * s, 1.0, float(p.ry) * 2.0 * s))
		var at := Vector3(float(p.cell.x) + 0.5 + float(p.ox), LIFT, float(p.cell.y) + 0.5 + float(p.oy))
		_mm.set_instance_transform(n, Transform3D(b, at))
		_mm.set_instance_color(n, Color(float(p.seed), 1, 1, 1))
		n += 1
	_mm.visible_instance_count = n
	visible = n > 0


## How many puddles show (for tests).
func shown_count() -> int:
	return _mm.visible_instance_count


## Is the rain drawing rings in them now (for tests)?
func raining() -> bool:
	return _raining
