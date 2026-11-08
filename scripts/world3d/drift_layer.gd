class_name DriftLayer
extends Node3D
## Seasonal life drifting through an outdoor map in 3D (rules: DriftRules, data/drift.json):
## cherry petals in spring and maple / persimmon leaves in fall, a few tiny quads in one
## MultiMesh that fall and blow along with the world's wind (FarmWorld.wind, the rice's and the
## hearth smoke's), and the summer night's fireflies, which are not drawn here: they glow, so
## DriftGlow draws them over the night tint from `fireflies()`. Only outdoor maps build one.
## Unshaded like the crop sprites, so the day / night tint dims petals and leaves with the field.

const GROUP := "drift_layers"

var map: MapData
var farm: FarmGrid
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _mm: MultiMesh
var _mmi: MultiMeshInstance3D
var _flies: Array[Dictionary] = []


func _init(m: MapData, f: FarmGrid = null) -> void:
	map = m
	farm = f
	name = "Drift"
	_t = float(m.w * 31 + m.h * 17) * 0.37
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	q.material = mat
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = q
	var cfg := DriftRules.config()
	_mm.instance_count = maxi(int(cfg.petal.count), int(cfg.leaf.count))
	_mm.visible_instance_count = 0
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = _mm
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mmi.extra_cull_margin = 50.0
	add_child(_mmi)


func _ready() -> void:
	add_to_group(GROUP)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock, the weather and the wind, then places the petals or leaves and works out the
## fireflies.
func refresh() -> void:
	_flies.clear()
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var amounts := DriftRules.amounts_now(game, map)
	if amounts.is_empty():
		_mm.visible_instance_count = 0
		return
	var key := "%s|%d|%d" % [map.id, game.season, game.day]
	if key != _scene_key:
		_scene_key = key
		_scene = DriftRules.scene_of(map, farm, DriftRules.festival_props_today(game, map))
	var world := get_parent() as FarmWorld
	var wind: float = world.wind if world != null else float(game.wind_strength())
	var shown: Array[Dictionary] = []
	for kind in ["petal", "leaf"]:
		if amounts.has(kind):
			shown.append_array(DriftRules.motes(kind, float(amounts[kind]), _t, wind, _scene))
	if amounts.has("firefly"):
		_flies = DriftRules.motes("firefly", float(amounts.firefly), _t, wind, _scene)
	shown = shown.slice(0, _mm.instance_count)
	_mm.visible_instance_count = shown.size()
	for i in shown.size():
		var m: Dictionary = shown[i]
		var s: float = m.size
		var b := Basis.IDENTITY.scaled(Vector3(s, s * 0.7, 1.0))
		_mm.set_instance_transform(i, Transform3D(b, m.pos))
		var c: Color = m.color
		c.a = float(m.alpha)
		_mm.set_instance_color(i, c)


## The fireflies now: [{pos: Vector3, alpha, color, size}] (DriftGlow draws them).
func fireflies() -> Array[Dictionary]:
	return _flies


## How many petals or leaves are showing (for tests).
func shown_count() -> int:
	return _mm.visible_instance_count
