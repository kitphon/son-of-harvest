class_name BirdLayer
extends Node3D
## Small birds on an outdoor map in 3D (rules: BirdRules, data/birds.json; pictures: BirdArt):
## swallows darting low, crows flying home at dusk, a heron by the water, sparrows hopping by the
## houses. One camera-facing pixel sprite per bird (FarmWorld.make_sprite: unshaded like the
## crops, so the day / night tint and the sun's colour lie on them as on the field), a picture
## chosen by the bird's pose and frame and mirrored to the way it faces on the screen. The farmer's
## place comes from FarmWorld.set_farmer (`farmer`, cells), so sparrows and the heron fly off when
## he comes near, and `others` (cells) are the villagers, the dog and the walking child that
## startle them too. Each bird has a shadow (BirdRules.shadow_of): a soft dark blob on the ground
## under a bird standing or hopping, and a faint one cast along the sun for a bird in the air
## while the sun throws shadows (Game.sun_shadow: none at night or under cloud, rain or snow).
## The sprites are alpha-cut (drawn with the solid things, depth-tested): a building in front
## that fades to see-through (Occluders) blends over them, so a bird behind it shows through,
## and a bird in front of a roof is never hidden by it. Only outdoor maps build one.

const GROUP := "bird_layers"

var map: MapData
var farm: FarmGrid
var farmer := BirdRules.NO_FARMER
var others: Array = []   # the other walkers' places (cells), from FarmWorld.set_farmer
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _built_key := ""   # the farm's buildings when the blocked set was made (BirdRules.built_key)
var _state := {}
var _pool: Array[Sprite3D] = []
var _shown: Array[Dictionary] = []
var _shadow_pool: Array[MeshInstance3D] = []
var _shadows: Array[Dictionary] = []
static var _soft: Texture2D


func _init(m: MapData, f: FarmGrid = null) -> void:
	map = m
	farm = f
	name = "Birds"
	_t = 0.0 if not BirdRules.forced().is_empty() else float(m.w * 13 + m.h * 29) * 0.31   # `--birds`: from the start, so a frame is the same


func _ready() -> void:
	add_to_group(GROUP)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock and the weather, then places every bird of the kinds on show.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var amounts := BirdRules.amounts_now(game, map)
	_shown.clear()
	if not amounts.is_empty():
		var key := "%s|%d|%d" % [map.id, game.season, game.day]
		if key != _scene_key:
			_scene_key = key
			_state.clear()
			_scene = BirdRules.scene_of(map, farm, game.day + 28 * game.season)
		var bkey := BirdRules.built_key(game)
		if bkey != _built_key:   # a building finished today: its roof and walls block the shadows now
			_built_key = bkey
			_scene["blocked"] = BirdRules.blocked_cells(map, farm)
		for kind in BirdRules.KINDS:
			if amounts.has(kind):
				_shown.append_array(BirdRules.birds(kind, float(amounts[kind]), _t, _scene, farmer, _state, {}, others))
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var right := Vector2.RIGHT
	if cam != null:
		right = Vector2(cam.global_transform.basis.x.x, cam.global_transform.basis.x.z)
	while _pool.size() < _shown.size():
		var s := FarmWorld.make_sprite(PlaceholderArt.tex("bird:sparrow:stand:0"))
		s.visible = false
		add_child(s)
		_pool.append(s)
	for i in _pool.size():
		var s := _pool[i]
		if i >= _shown.size():
			s.visible = false
			continue
		var b := _shown[i]
		var to_right := (b.dir as Vector2).dot(right) > 0.0
		var tex := PlaceholderArt.tex(BirdRules.key_of(b) + (":r" if to_right else ""))
		s.texture = tex
		s.offset = Vector2(0, tex.get_height() / 2.0)
		s.position = b.pos
		s.visible = true
	_place_shadows(game)


## The shadows of the birds shown (BirdRules.shadow_of), one flat soft oval each, just over the ground.
func _place_shadows(game: Node) -> void:
	_shadows.clear()
	if not _shown.is_empty() and game != null:
		var sun: float = game.sun_shadow()
		var dir: Vector3 = game.sun_direction(game.sun_light())
		for b in _shown:
			var sh := BirdRules.shadow_of(b, sun, dir, {}, _scene.get("blocked", {}))
			if not sh.is_empty():
				sh.air = BirdRules.flying(b)
				_shadows.append(sh)
	while _shadow_pool.size() < _shadows.size():
		_shadow_pool.append(_make_shadow())
	for i in _shadow_pool.size():
		var m := _shadow_pool[i]
		if i >= _shadows.size():
			m.visible = false
			continue
		var sh := _shadows[i]
		var size: Vector2 = sh.size
		m.position = Vector3(sh.at.x, 0.015, sh.at.y)
		m.scale = Vector3(size.x, 1.0, size.y)
		(m.material_override as StandardMaterial3D).albedo_color = Color(0, 0, 0, float(sh.alpha))
		m.visible = true


func _make_shadow() -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	m.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = soft_texture()
	mat.albedo_color = Color(0, 0, 0, 0.3)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.layers = NightLamps.GROUND_LAYER   # lies on the ground: the night lamps leave it out as they do the ground
	m.visible = false
	m.name = "Shadow"
	add_child(m)
	return m


## A white disc fading out to its rim (the shadows' soft edge; tinted black by the material).
static func soft_texture() -> Texture2D:
	if _soft == null:
		var sh: Dictionary = BirdRules.config().get("shadow", {})   # a darker centre, a wide soft edge (core, core_alpha)
		_soft = blob_texture(float(sh.get("core", 0.4)), float(sh.get("core_alpha", 0.9)))
	return _soft


## The blob's texture for a darker centre of `core_alpha` out to the radius `core` (0..1), fading
## to nothing at the rim. Shared with the insects' shadows (InsectLayer).
static func blob_texture(core: float, core_alpha: float) -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(core, Color(1, 1, 1, core_alpha))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	return t


## The birds showing now (for tests).
func shown() -> Array[Dictionary]:
	return _shown


func shown_count() -> int:
	return _shown.size()


## The shadows showing now (for tests): [{at, size, alpha, air}].
func shadows() -> Array[Dictionary]:
	return _shadows
