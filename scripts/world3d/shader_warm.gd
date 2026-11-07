class_name ShaderWarm
extends RefCounted
## Shader warm-up: the first frame that draws a material of a kind not drawn before compiles its
## shader (a long frame), and a kind no material uses any more is dropped and compiled again
## the next time (StandardMaterial3D shares one shader per set of features and frees it with
## its last user). Measured 2026-11-07 (tools/tmp throwaway, a window): the dearest were the
## fades of things in the farmer's way (Occluders switches their materials to alpha blending:
## frames of 30..90 ms on the hill, again on every fade, as the faded kind was freed between),
## then a map's first frames on parts of it not seen yet (~20 ms).
##
## So: every kind of material a world wears (`news`) is kept for the whole run, as a copy here
## (its shader stays alive, compiled once), with the faded twin of each one that fades; the new
## kinds are drawn once by `show` while the map change's fade holds black (MapFade.HOLD_FRAMES):
## a tiny quad each in front of the camera, so their shaders compile out of sight. Main3D takes
## them away before the picture comes back. The view's first map is warmed the same way, under
## MapFade.cover's black.
##
## The night's variants too (2026-11-07): the quads of kinds the night lamps light stand under a
## lamp of their own (WarmLamp), and Main3D draws one warm-up frame with the sun's shadows the
## other way round, so a lamp coming on at dusk and the sun's shadows going off find their
## shaders compiled. Measured in a window (a throwaway script: the farm, the village at 17:30,
## then a game minute a frame to 21:30, sound off): the frame the lamps came on 371 / 484 ms
## before, 160 / 167 after; the frame the shadows went off 500 / 483 -> 108 / 112.

const SIZE := 0.02     # the quads (world units), at NEAR + a little past the camera's near plane
const NEAR := 0.3
## The warm-up lamp: an OmniLight3D like NightLamps' (no shadows, the same cull mask) just in
## front of the quads, so the lit quads also draw the pass a lamp adds (the Compatibility
## renderer draws a lamp on a mesh as another pass, another shader variant). Its range reaches
## only the quads.
const LAMP_RANGE := 0.1
const LIT_KEY := "|lit"

static var _kinds := {}   # signature -> the kept copy (or twin)
static var _names: Array[String] = []   # StandardMaterial3D's stored bool / int / object properties
static var shown := 0     # quads drawn so far (tests)


## What decides a material's shader: for a StandardMaterial3D its stored switches and modes
## (bool and int properties) and which textures it has (colours and numbers are uniforms, the
## same shader); for a ShaderMaterial its Shader. `multi`: worn by a MultiMesh (another variant).
static func signature(m: Material, multi := false) -> String:
	if m is ShaderMaterial:
		var sh := (m as ShaderMaterial).shader
		return "shader:%d:%s" % [sh.get_instance_id() if sh != null else 0, multi]
	if not m is StandardMaterial3D:
		return ""
	if _names.is_empty():
		for prop in StandardMaterial3D.new().get_property_list():
			if prop.usage & PROPERTY_USAGE_STORAGE and prop.type in [TYPE_BOOL, TYPE_INT, TYPE_OBJECT] and prop.name != "script":
				_names.append(prop.name)
	var parts := PackedStringArray([str(multi)])
	for name in _names:
		var v: Variant = m.get(name)
		parts.append("1" if v is Object else ("0" if v == null else str(v)))
	return ",".join(parts)


## The kinds of material `world` wears that no world wore before this run, each as
## {mat, multi, shadow} (a kept copy to draw), the faded twins of the things that fade with them.
## They are kept from now on.
static func news(world: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var fading := {}
	if world is FarmWorld:
		for m in (world as FarmWorld).occluders.materials():
			fading[m] = true
	for n in world.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		var m := g.material_override
		if m == null or g is SpriteBase3D:
			continue
		var multi := g is MultiMeshInstance3D
		var shadow := g.cast_shadow
		var lit := (g.layers & NightLamps.LIT_MASK) != 0
		_add(m, multi, shadow, lit, out)
		if fading.has(m):
			_add(faded(m as StandardMaterial3D), multi, shadow, lit, out)
	return out


## Keeps `m`'s kind (and lists it in `out`) unless kept already. A kind on a mesh the night
## lamps light (`lit`) is kept apart from the same kind on the ground layer: only the lit one's
## quad takes the warm-up lamp, and the lit quad draws the plain pass too, so an unlit one after
## it adds nothing.
static func _add(m: Material, multi: bool, shadow: GeometryInstance3D.ShadowCastingSetting, lit: bool, out: Array[Dictionary]) -> void:
	var sig := signature(m, multi)
	if sig == "" or _kinds.has(sig + LIT_KEY) or (not lit and _kinds.has(sig)):
		return
	var keep: Material = MeshCache.copy(m) if m is StandardMaterial3D else m.duplicate()
	_kinds[sig + (LIT_KEY if lit else "")] = keep
	out.append({"mat": keep, "multi": multi, "shadow": shadow, "lit": lit})


## A copy of `m` as Occluders draws it faded (alpha blending, depth drawn always).
static func faded(m: StandardMaterial3D) -> StandardMaterial3D:
	var f := MeshCache.copy(m) as StandardMaterial3D
	f.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	f.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	f.albedo_color.a *= 1.0 - Occluders.FADED
	return f


## Draws `kinds` (from news) once: a tiny quad each just in front of `cam`, the lit ones under the
## warm-up lamp (WarmLamp), all under one node added to `parent` (free it before the picture
## shows). Null when there is nothing new.
static func show(parent: Node, cam: Camera3D, kinds: Array[Dictionary]) -> Node3D:
	if kinds.is_empty():
		return null
	var root := Node3D.new()
	root.name = "ShaderWarm"
	var quad := QuadMesh.new()
	quad.size = Vector2(SIZE, SIZE)
	var at := cam.global_transform if cam.is_inside_tree() else cam.transform
	var ahead := at.origin - at.basis.z * (cam.near + NEAR)
	var lamp := OmniLight3D.new()
	lamp.name = "WarmLamp"
	lamp.shadow_enabled = false
	lamp.light_cull_mask = NightLamps.LIT_MASK
	lamp.light_specular = 0.0
	lamp.omni_range = LAMP_RANGE
	lamp.position = ahead + at.basis.z * SIZE   # a little toward the camera: it faces the quads
	root.add_child(lamp)
	for k in kinds:
		var g: GeometryInstance3D
		if k.multi:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = quad
			mm.instance_count = 1
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			g = mmi
		else:
			var mi := MeshInstance3D.new()
			mi.mesh = quad
			g = mi
		g.material_override = k.mat
		g.cast_shadow = k.shadow
		g.layers = NightLamps.LIT_MASK if k.get("lit", true) else NightLamps.GROUND_LAYER
		g.transform = Transform3D(at.basis, ahead)
		root.add_child(g)
	parent.add_child(root)
	shown += kinds.size()
	return root


## How many kinds are kept (tests).
static func count() -> int:
	return _kinds.size()


## Forgets the kept kinds (tests).
static func clear() -> void:
	_kinds.clear()
