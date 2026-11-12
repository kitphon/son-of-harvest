class_name SpriteShadow
extends Node3D
## The shadow of a camera-facing figure (farmer, villager, animal) in the 3D view. Two parts,
## both children of the figure's Sprite3D, so they move with it and hide with it:
##  - a soft blob, a flat dark oval on the ground at its feet, sized from the sprite's opaque
##    pixels (read from the texture at runtime, so a redrawn, larger or smaller sprite gets a
##    fitting one);
##  - a caster, a vertical quad wearing the sprite's own picture (its alpha cuts the outline),
##    standing at the feet and turned to face the sun, set to cast shadows only. A Sprite3D
##    billboard would cast from a quad that turns with the camera, so its shadow is a thin,
##    wrong sliver that changes as the camera lens does; this quad stays square to the sun's
##    horizontal direction, so the sun's shadow map throws the figure's real silhouette on the
##    ground, long and up the screen in the morning, short at noon, down it in the evening.
## data/light.json "sprite_shadows" ("mode": "real" or "blob") picks the look: "real" uses the
## caster by sun and keeps only a faint contact blob (`blob_in_sun` of the blob) while the sun
## shadows are on, the full blob when they are off (rain, night, rooms, the mine); "blob" is
## the blob alone, always at full strength, as the game had it. `-- --sprite-shadows=blob` (or
## `real`) overrides the file for one run. Main3D feeds `sun_yaw` and `sun_strength` each game
## minute (the same strength it gives the light's shadow opacity).

## The sun's horizontal heading and strength now, set by Main3D from the DirectionalLight3D.
static var sun_yaw := 0.0         # radians: the quad's rotation about Y so it faces the sun
static var sun_strength := 0.0    # 0..1, Game.sun_shadow() outdoors, 0 inside

static var _cfg := {}             # the rules, read once (reset to {} to read again)
static var _mode := ""            # the mode, read once
static var _sizes := {}           # texture instance id -> opaque width in pixels

var sprite: Sprite3D
var _blob: MeshInstance3D
var _blob_mat: StandardMaterial3D
var _caster: MeshInstance3D
var _caster_mat: StandardMaterial3D
var _quad: QuadMesh
var _tex: Texture2D
var _blob_alpha := 0.3
var _last_alpha := -1.0
var _with_blob := true


## Gives `s` its shadow. `alpha` is the blob's strength with no sun (the game's old 0.3).
## With `with_blob` false only the sun's caster is made (crops: no oval under every plant).
static func attach(s: Sprite3D, alpha := 0.3, with_blob := true) -> SpriteShadow:
	var sh := SpriteShadow.new()
	sh.name = "SpriteShadow"
	sh.sprite = s
	sh._blob_alpha = alpha
	sh._with_blob = with_blob
	sh._build()
	s.add_child(sh)
	return sh


## The rules (data/light.json "sprite_shadows"); defaults are the same as the data.
static func rules() -> Dictionary:
	if _cfg.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
		_cfg = merged(data.get("sprite_shadows", {}) if data is Dictionary else {})
	return _cfg


## The defaults (the same as the data) with `from_file` laid over them.
static func merged(from_file: Variant) -> Dictionary:
	var r: Dictionary = {"mode": "real", "blob_in_sun": 0.35, "blob_width": 1.0, "blob_depth": 0.6,
		"blob_min": 0.4}
	if from_file is Dictionary:
		r.merge(from_file, true)
	return r


## "real" or "blob": the data's mode, or this run's `--sprite-shadows=` argument.
static func mode() -> String:
	if _mode == "":
		_mode = str(rules().get("mode", "real"))
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--sprite-shadows="):
				_mode = arg.trim_prefix("--sprite-shadows=")
	return _mode


## How strong the blob is: whole with no sun shadows, `blob_in_sun` of it under full sun in
## "real" mode, always whole in "blob" mode. `strength` is 0..1 (SpriteShadow.sun_strength).
static func blob_share(real_mode: bool, strength: float, in_sun: float) -> float:
	if not real_mode:
		return 1.0
	return lerpf(1.0, in_sun, clampf(strength, 0.0, 1.0))


## The rotation about Y that turns a vertical quad to face the sun: its normal points toward
## the light's source, against the horizontal part of `dir` (the way the light shines).
static func face_yaw(dir: Vector3) -> float:
	var h := Vector2(dir.x, dir.z)
	if h.length() < 0.001:
		return 0.0
	h = h.normalized()
	return atan2(-h.x, -h.y)


## The width of `tex`'s opaque pixels, in pixels (cached).
static func opaque_width(tex: Texture2D) -> int:
	if tex == null:
		return 0
	var id := tex.get_instance_id()
	if not _sizes.has(id):
		var img := tex.get_image()
		_sizes[id] = int(img.get_used_rect().size.x) if img != null else tex.get_width()
	return int(_sizes[id])


func _build() -> void:
	var r := rules()
	var px := sprite.pixel_size
	var w := maxf(float(opaque_width(sprite.texture)) * px * float(r.blob_width), float(r.blob_min))
	_blob = MeshInstance3D.new()
	var disc := PlaneMesh.new()
	disc.size = Vector2(w, w * float(r.blob_depth))
	_blob.mesh = disc
	_blob_mat = StandardMaterial3D.new()
	_blob_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_blob_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_blob_mat.albedo_color = Color(0, 0, 0, _blob_alpha)
	_blob.material_override = _blob_mat
	_blob.position = Vector3(0, 0.01, 0)
	_blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_blob.visible = _with_blob
	add_child(_blob)

	_caster = MeshInstance3D.new()
	_quad = QuadMesh.new()
	_caster.mesh = _quad
	_caster_mat = StandardMaterial3D.new()
	_caster_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_caster_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_caster_mat.alpha_scissor_threshold = 0.5
	_caster_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_caster_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_caster.material_override = _caster_mat
	_caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	add_child(_caster)
	_sync(true)


func _process(_delta: float) -> void:
	_sync(false)


func _sync(force: bool) -> void:
	var real := mode() == "real"
	var strength := sun_strength if real else 0.0
	var a := _blob_alpha * blob_share(real, strength, float(rules().blob_in_sun))
	if not is_equal_approx(a, _last_alpha):
		_last_alpha = a
		_blob_mat.albedo_color = Color(0, 0, 0, a)
	_caster.visible = real and strength > 0.0
	if not _caster.visible:
		return
	_caster.rotation.y = sun_yaw
	var tex := sprite.texture
	if tex != _tex or force:
		_tex = tex
		if tex == null:
			_caster.visible = false
			return
		var px := sprite.pixel_size
		_quad.size = Vector2(tex.get_width(), tex.get_height()) * px
		_quad.center_offset = Vector3(sprite.offset.x * px, sprite.offset.y * px, 0)
		_caster_mat.albedo_texture = tex
	_caster.scale.x = -1.0 if sprite.flip_h else 1.0
	_caster.scale.y = 1.0 / maxf(sprite.scale.y, 0.01)   # an upright figure's stretch is for the camera, not the sun
