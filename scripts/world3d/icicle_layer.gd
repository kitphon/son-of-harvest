class_name IcicleLayer
extends Node3D
## Icicles on the roofs' eaves in 3D (IcicleRules, data/icicles.json): one MultiMesh of thin
## six-sided cones hanging point down from the eave lines the roof builders listed
## (FarmWorld.eaves: Minka's thatch, gable and hip roofs, so the farmhouse, the coop, the barn,
## the seed stand, the village houses and their pent roofs, the shrine, the well), each at its
## spot from IcicleRules.spots. Pale blue-white and see-through, lit like the walls round them
## (the sun's highlight, the night lamps' warmth), a paler rim where they turn from the eye.
## While they drip a few drops fall from the tips (a second MultiMesh, moved by its shader).
## The instances are rewritten only when the length moves a step. Made with an outdoor world;
## a room, the mine or the greenhouse never gets one.

const GROUP := "icicle_layers"

const SHADER := "shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, shadows_disabled;
uniform vec3 ice_color : source_color = vec3(0.86, 0.91, 0.96);
uniform vec3 core_color : source_color = vec3(0.62, 0.74, 0.84);
uniform vec3 tip_color : source_color = vec3(0.96, 0.98, 0.99);
uniform float alpha_top = 0.85;
uniform float alpha_tip = 0.5;
varying float along;
varying float own;
void vertex() {
	own = 1.0 - INSTANCE_CUSTOM.x;   // the fade of its own building (see-through in front of the farmer)
	along = clamp(0.5 - VERTEX.y, 0.0, 1.0);   // 0 at the eave, 1 at the point
}
void fragment() {
	float face = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 c = mix(core_color, ice_color, face);   // the sides turning away show the deeper blue
	c = mix(c, tip_color, smoothstep(0.55, 1.0, along));
	ALBEDO = c;
	ALPHA = mix(alpha_top, alpha_tip, along) * own;
	ROUGHNESS = 0.18;
	SPECULAR = 0.9;
	RIM = 0.5;
	RIM_TINT = 0.4;
}
"

## A falling drop: each instance's custom data is (seed, period, fall, building fade); it slides down
## from the tip, stretching a little, and fades as it goes (and with its building).
const DROP_SHADER := "shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled, unshaded;
uniform vec3 drop_color : source_color = vec3(0.9, 0.95, 0.98);
uniform float light = 1.0;
varying float fade;
varying float own;
void vertex() {
	own = 1.0 - INSTANCE_CUSTOM.w;
	float t = fract(TIME / INSTANCE_CUSTOM.y + INSTANCE_CUSTOM.x);
	VERTEX.y *= 1.0 + t * 1.5;
	VERTEX.y -= t * t * INSTANCE_CUSTOM.z;
	fade = 1.0 - t;
}
void fragment() {
	ALBEDO = drop_color * light;
	ALPHA = 0.8 * fade * own;
}
"

var _spots: Array[Dictionary] = []
var _hung: Array = []   # [top, length] of each instance placed (the headless renderer keeps no transforms)
var _step := -1
var _fades := {}   # tag -> its building's fade now (0 opaque .. Occluders.FADED)
var _cone_fade: Array[float] = []   # the fade written to each icicle (the headless renderer keeps no custom data)
var _cone_tag: Array[String] = []   # the tag of each icicle instance placed
var _drop_tag: Array[String] = []   # the tag of each drop instance placed
var _drip := false
var _mm: MultiMesh
var _drops: MultiMesh
var _drop_node: MultiMeshInstance3D
var _drop_mat: ShaderMaterial
var map: MapData


## The icicles of map `m` along `eaves` (FarmWorld.eaves).
func _init(m: MapData, eaves: Array[Dictionary]) -> void:
	map = m
	name = "Icicles"
	var cfg := IcicleRules.config()
	if IcicleRules.outdoors(m):
		for e in eaves:
			for s in IcicleRules.spots(e.a, e.b, e.out, cfg):
				s.tag = str(e.get("tag", ""))
				_spots.append(s)
	var cone := CylinderMesh.new()
	cone.top_radius = 1.0
	cone.bottom_radius = 0.0
	cone.height = 1.0
	cone.radial_segments = 6
	cone.rings = 1
	cone.cap_bottom = false
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = cone
	_mm.instance_count = _spots.size()
	_mm.visible_instance_count = 0
	var mat := ShaderMaterial.new()
	mat.shader = SnowLayer.shader(SHADER)
	var col: Dictionary = cfg.colors
	mat.set_shader_parameter("ice_color", Color(str(col.ice)))
	mat.set_shader_parameter("core_color", Color(str(col.core)))
	mat.set_shader_parameter("tip_color", Color(str(col.tip)))
	mat.set_shader_parameter("alpha_top", float(cfg.alpha.top))
	mat.set_shader_parameter("alpha_tip", float(cfg.alpha.tip))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.extra_cull_margin = 50.0
	add_child(mmi)
	var bead := SphereMesh.new()
	bead.radius = 0.014
	bead.height = 0.034
	bead.radial_segments = 6
	bead.rings = 3
	_drops = MultiMesh.new()
	_drops.transform_format = MultiMesh.TRANSFORM_3D
	_drops.use_custom_data = true
	_drops.mesh = bead
	var dripping := _spots.filter(func(s: Dictionary) -> bool: return s.drip)
	_drops.instance_count = dripping.size()
	_drops.visible_instance_count = 0
	_drop_mat = ShaderMaterial.new()
	_drop_mat.shader = SnowLayer.shader(DROP_SHADER)
	_drop_mat.set_shader_parameter("drop_color", Color(str(col.drop)))
	_drop_node = MultiMeshInstance3D.new()
	_drop_node.multimesh = _drops
	_drop_node.material_override = _drop_mat
	_drop_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_drop_node.extra_cull_margin = 50.0
	_drop_node.visible = false
	add_child(_drop_node)
	visible = false


func _ready() -> void:
	add_to_group(GROUP)
	refresh()


func _process(_delta: float) -> void:
	refresh()
	_follow_buildings()


## Each building's icicles and drops take its fade (Occluders.fade_of_tag of the world they hang in).
func _follow_buildings() -> void:
	var occ: Variant = get_parent().get("occluders") if get_parent() != null else null   # FarmWorld's (untyped: no load cycle)
	if occ == null:
		return
	var tags := {}
	for t in _cone_tag:
		tags[t] = true
	for t in _drop_tag:
		tags[t] = true
	for t: String in tags:
		if t == "":
			continue
		var f: float = occ.fade_of_tag(t)
		if not is_equal_approx(f, float(_fades.get(t, 0.0))):
			_fades[t] = f
			_apply_fade(t)


func _apply_fade(t: String) -> void:
	var f := float(_fades.get(t, 0.0))
	for i in _cone_tag.size():
		if _cone_tag[i] == t:
			_mm.set_instance_custom_data(i, Color(f, 0, 0, 0))
			_cone_fade[i] = f
	for i in _drop_tag.size():
		if _drop_tag[i] == t:
			var c := _drops.get_instance_custom_data(i)
			c.a = f
			_drops.set_instance_custom_data(i, c)


## How see-through the icicles of `tag`'s building are now (for tests): 0 opaque .. Occluders.FADED.
func fade_of_tag(tag: String) -> float:
	return float(_fades.get(tag, 0.0))


## The building tag of icicle instance `i` (for tests).
func tag_of_instance(i: int) -> String:
	return _cone_tag[i]


## The fade written into icicle instance `i` (for tests).
func instance_fade(i: int) -> float:
	return _cone_fade[i]


## Reads the season, the snow, the weather and the clock; redoes the icicles when their length
## moved a step, the drops when the dripping starts or stops.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if game == null:
		return
	var cfg := IcicleRules.config()
	var a := IcicleRules.amount_now(game, map, cfg)
	var step := IcicleRules.step_of(a, cfg)
	var drip := IcicleRules.dripping_now(game, map, cfg)
	if step != _step:
		_step = step
		_place(float(step) * float(cfg.step), cfg)
		_drip = not drip   # the drops follow the new lengths
	if drip != _drip:
		_drip = drip
		_place_drops(float(step) * float(cfg.step), cfg)


func _place(a: float, cfg: Dictionary) -> void:
	var n := 0
	_hung.clear()
	_cone_tag.clear()
	_cone_fade.clear()
	for s in _spots:
		var l := IcicleRules.length_of(s, a, cfg)
		if l <= 0.0:
			continue
		var w := float(s.width)
		var top: Vector3 = s.at
		_mm.set_instance_transform(n, Transform3D(Basis.IDENTITY.scaled(Vector3(w, l, w)), top - Vector3(0, l / 2.0, 0)))
		_mm.set_instance_custom_data(n, Color(float(_fades.get(str(s.tag), 0.0)), 0, 0, 0))
		_hung.append([top, l])
		_cone_tag.append(str(s.tag))
		_cone_fade.append(float(_fades.get(str(s.tag), 0.0)))
		n += 1
	_mm.visible_instance_count = n
	visible = n > 0


func _place_drops(a: float, cfg: Dictionary) -> void:
	var n := 0
	_drop_tag.clear()
	if _drip:
		for s in _spots:
			if not s.drip:
				continue
			var l := IcicleRules.length_of(s, a, cfg)
			if l <= 0.0:
				continue
			var top: Vector3 = s.at
			_drops.set_instance_transform(n, Transform3D(Basis.IDENTITY, top - Vector3(0, l, 0)))
			_drops.set_instance_custom_data(n, Color(float(s.seed), IcicleRules.drip_period(float(s.seed), cfg), float(cfg.drip.fall), float(_fades.get(str(s.tag), 0.0))))
			_drop_tag.append(str(s.tag))
			n += 1
	_drops.visible_instance_count = n
	_drop_node.visible = n > 0


## How many icicles show (for tests).
func shown_count() -> int:
	return _mm.visible_instance_count if visible else 0


## How many drops are falling (for tests).
func drop_count() -> int:
	return _drops.visible_instance_count if _drop_node.visible else 0


## Every spot this layer hangs icicles at (for tests).
func spot_list() -> Array[Dictionary]:
	return _spots


## The top and length of the icicle at instance `i` now (for tests): [top, length].
func instance(i: int) -> Array:
	return _hung[i]
