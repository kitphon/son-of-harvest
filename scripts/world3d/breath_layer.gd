class_name BreathLayer
extends Node3D
## Breath in the cold on an outdoor map in 3D (rules: BreathRules, data/breath.json): a small
## pale puff at the mouth of each figure that breathes, drawn as unshaded camera-facing quads in
## one MultiMesh (tinted with the field like DriftLayer, so the night tint dims them). The figures:
## the farmer, passed in by FarmWorld.set_farmer (`farmer`), and every node in the GROUP
## (`breath_figures`) of this world that is shown: the villagers and the walking child (their
## sprites set `breath_kind` and `facing` meta), the farm dog and the grown animals (`breath_kind`
## "animal"). Facing comes from the figure or, for the animals, from the way it last walked.
## Only outdoor maps build one.

const GROUP := "breath_figures"        # the figures that breathe (their sprites join it)
const LAYERS := "breath_layers"

var map: MapData
var farm: FarmGrid
var farmer := {}   # {} or {cell, facing, running, tired} from FarmWorld.set_farmer (the farmer's feet)
var _t := 0.0
var _state := {}
var _mm: MultiMesh
var _mmi: MultiMeshInstance3D
var _puffs: Array[Dictionary] = []


func _init(m: MapData, f: FarmGrid = null) -> void:
	map = m
	farm = f
	name = "Breath"
	_t = 0.0 if not BreathRules.forced().is_empty() else float(m.w * 17 + m.h * 23) * 0.29   # `--breath`: from the start, so a frame is the same
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.albedo_texture = soft_texture()   # a round puff, soft at its rim (not a square)
	q.material = mat
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = q
	_mm.instance_count = 64
	_mm.visible_instance_count = 0
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = _mm
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mmi.extra_cull_margin = 50.0
	add_child(_mmi)


func _ready() -> void:
	add_to_group(LAYERS)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock, the weather and the wind, then places the puffs of the figures that show one.
func refresh() -> void:
	_puffs.clear()
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var strength := BreathRules.strength_now(game, map)
	if strength <= 0.0:
		_mm.visible_instance_count = 0
		return
	var world := get_parent() as FarmWorld
	var wind: float = world.wind if world != null else float(game.wind_strength())
	_puffs = BreathRules.puffs_now(figures(), _state, _t, strength, wind)
	var shown := mini(_puffs.size(), _mm.instance_count)
	_mm.visible_instance_count = shown
	for i in shown:
		var p := _puffs[i]
		var s: float = p.size
		_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(s, s, 1.0)), p.pos))
		var c: Color = p.color
		c.a = float(p.alpha)
		_mm.set_instance_color(i, c)


## The figures that breathe now: [{id, cell, facing, kind, moving, running, tired}], the farmer
## first, then the shown sprites of the group under this world (cells = their feet on the ground).
func figures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not farmer.is_empty():
		out.append({"id": BreathRules.FARMER, "cell": farmer.cell, "facing": farmer.facing, "kind": "person",
			"running": bool(farmer.running), "tired": bool(farmer.tired)})
	var world := get_parent()
	if world == null or not is_inside_tree():
		return out
	for n in get_tree().get_nodes_in_group(GROUP):
		var s := n as Node3D
		if s == null or not s.visible or not world.is_ancestor_of(s):
			continue
		out.append({"id": str(s.get_instance_id()), "cell": Vector2(s.position.x, s.position.z),
			"facing": s.get_meta("facing", Vector2.ZERO), "kind": str(s.get_meta("breath_kind", "person"))})
	return out


static var _soft: Texture2D


## A white disc fading out to its rim: the puffs' picture (tinted by the instance colour).
static func soft_texture() -> Texture2D:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.5, Color(1, 1, 1, 0.85))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 16
		t.height = 16
		_soft = t
	return _soft


## The puffs showing now (for tests): [{pos, alpha, size, color, u, id}].
func puffs() -> Array[Dictionary]:
	return _puffs


## How many puffs are drawn now (for tests).
func shown_count() -> int:
	return _mm.visible_instance_count
