class_name ToolFxLayer
extends Node3D
## The tool-use effects in 3D (rules: ToolFxRules, data/tool_fx.json): on each Game.tool_fx (the
## hit frame of the farmer's swing, or a harvest pick-up) a Burst of its own, one MultiMesh of tiny
## unshaded billboard quads with vertex colours like DriftLayer's petals, so the scene's day / night
## and mine tint (Main3D's full-screen tint) dims them with the field; their colours take the sun's
## share on the sprites too (SpriteLight.now). The bits fly, fall, bounce or settle and fade; a
## burst frees itself once its last particle is gone. Main3D adds one to every world it shows.

const GROUP := "tool_fx_layers"

static var _seed := 0


func _init() -> void:
	name = "ToolFx"


func _ready() -> void:
	add_to_group(GROUP)
	Game.tool_fx.connect(add_burst)


## Starts a burst (ToolFxRules.burst) here; returns its node (null for an empty one).
func add_burst(b: Dictionary) -> Burst:
	if b.is_empty():
		return null
	_seed += 1
	var n := Burst.new(ToolFxRules.particles(b, _seed * 7919 + 13))
	add_child(n)
	return n


## The bursts still flying.
func bursts() -> Array[Burst]:
	var out: Array[Burst] = []
	for c in get_children():
		if c is Burst and not c.is_queued_for_deletion():
			out.append(c)
	return out


## One swing's bits: steps them each frame, draws their specks, frees itself when none are left.
class Burst extends MultiMeshInstance3D:
	var parts: Array[Dictionary] = []
	var _mm := MultiMesh.new()

	func _init(p: Array[Dictionary]) -> void:
		parts = p
		name = "Burst"
		var q := QuadMesh.new()
		q.size = Vector2.ONE
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.billboard_keep_scale = true
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		q.material = mat
		_mm.transform_format = MultiMesh.TRANSFORM_3D
		_mm.use_colors = true
		_mm.mesh = q
		_mm.instance_count = 0
		multimesh = _mm
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		extra_cull_margin = 4.0
		_draw_specks()

	func _process(delta: float) -> void:
		advance(delta)

	## Moves the bits on by `delta` seconds and redraws; frees the burst when they are all gone.
	func advance(delta: float) -> void:
		parts = ToolFxRules.step(parts, delta)
		if parts.is_empty():
			queue_free()
			return
		_draw_specks()

	func _draw_specks() -> void:
		var sp := ToolFxRules.specks(parts)
		if _mm.instance_count < sp.size():
			_mm.instance_count = sp.size() + 8
		_mm.visible_instance_count = sp.size()
		var sun := SpriteLight.now
		for i in sp.size():
			var s: Dictionary = sp[i]
			var w: float = maxf(1.0, roundf(s.size)) * FarmWorld.PX
			_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(w, w, 1.0)), s.pos + Vector3(0, w * 0.5, 0)))
			var c: Color = s.color
			_mm.set_instance_color(i, Color(c.r * sun.r, c.g * sun.g, c.b * sun.b, c.a))
