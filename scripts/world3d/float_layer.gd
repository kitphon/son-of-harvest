class_name FloatLayer
extends Node3D
## Leaves and petals floating on a soft pond's water in 3D (DriftRules.afloat, data/drift.json
## "afloat"; 2026-11-28): maple leaves in fall, cherry petals in spring, each a small flat quad
## lying on the water's top in one MultiMesh, cut to its shape by a picture drawn here (a
## five-lobed maple leaf, a notched petal) and tinted by its colour, turning slowly as it drifts.
## Unshaded like the falling ones (DriftLayer), so the day / night tint lies over them.
## MapWorld makes one on maps whose water has a look listed in "afloat" `looks`.

const LIFT := 0.012   # over the water's top

static var _pictures := {}

var map: MapData
var water_y := 0.0
var _t := 0.0
var _mms := {}        # kind -> MultiMesh
var _shown: Array[Dictionary] = []


func _init(m: MapData, water_top: float) -> void:
	map = m
	water_y = water_top
	name = "Afloat"
	_t = float(m.w * 29 + m.h * 13) * 0.53
	var a: Dictionary = DriftRules.config().get("afloat", {})
	for kind in ["leaf", "petal"]:
		var plane := PlaneMesh.new()
		plane.size = Vector2.ONE
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 0.5
		mat.albedo_texture = picture(kind)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		plane.material = mat
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = plane
		mm.instance_count = int(((a.get(kind, {}) as Dictionary).get("count", [0, 0]) as Array)[1])
		mm.visible_instance_count = 0
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.extra_cull_margin = 30.0
		add_child(mmi)
		_mms[kind] = mm


func _ready() -> void:
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Places what floats now.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var world := get_parent() as FarmWorld
	_shown = DriftRules.afloat_now(game, map, _t, world.wind if world != null else 0.0)
	var n := {"leaf": 0, "petal": 0}
	for f in _shown:
		var mm: MultiMesh = _mms[f.kind]
		var i: int = n[f.kind]
		if i >= mm.instance_count:
			continue
		var s: float = f.size
		var b := Basis(Vector3.UP, float(f.angle)).scaled(Vector3(s, 1.0, s))
		mm.set_instance_transform(i, Transform3D(b, Vector3(f.pos.x, water_y + LIFT, f.pos.y)))
		var c: Color = f.color
		mm.set_instance_color(i, Color(c, 1.0) if c.a > 0.5 else Color(c, 0.0))   # alpha-cut: in or out
		n[f.kind] = i + 1
	for kind in _mms:
		(_mms[kind] as MultiMesh).visible_instance_count = n[kind]


## What floats now (for tests): DriftRules.afloat.
func shown() -> Array[Dictionary]:
	return _shown


## The white picture a floater is cut to (16 x 16): a maple leaf with five pointed lobes and a
## stalk, or a cherry petal notched at its tip.
static func picture(kind: String) -> Texture2D:
	if _pictures.has(kind):
		return _pictures[kind]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) / 16.0 * 2.0 - Vector2.ONE
			var on := false
			if kind == "leaf":
				var a := atan2(p.x, -p.y)
				var r := p.length()
				on = r < 0.55 + 0.4 * pow(absf(cos(a * 2.5)), 3.0) and not (p.y > 0.25 and absf(p.x) < 0.5 and r > 0.45)
				on = on or (absf(p.x) < 0.07 and p.y > 0.2 and p.y < 0.95)   # the stalk
			else:
				on = pow(p.x / 0.6, 2.0) + pow((p.y + 0.05) / 0.9, 2.0) < 1.0 and not (p.y < -0.6 and absf(p.x) < 0.15)
			img.set_pixel(x, y, Color(1, 1, 1, 1) if on else Color(1, 1, 1, 0))
	var t := ImageTexture.create_from_image(img)
	_pictures[kind] = t
	return t
