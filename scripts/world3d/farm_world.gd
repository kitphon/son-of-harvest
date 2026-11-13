class_name FarmWorld
extends Node3D
## The farm in 3D: 1 unit = 1 cell, x = column, z = row, y up.
## Ground = the 2D FarmView (ground only) rendered into a texture; obstacles and crops
## stand up as camera-facing sprites; buildings are textured boxes. Snow lying on the ground
## and roofs (Game.snow_cover) is drawn by SnowLayer shaders.

const T := 16
const PX := 0.045              # world units per sprite pixel (crops, items, animals, props)
## World units per pixel of a figure sprite (the farmer, villagers: FigureArt, 24 x 32). Their
## head tops about 1.2 units up, a little taller than the 1.08 of the old 24 px figures and under
## every eave (1.45); a pixel comes out about 1.5 screen pixels at the medium lens.
const FIGURE_PX := 0.04

var farm: FarmGrid
var gaps: Array[Vector2i] = []   # fence cells left open (the gate to the village)
var _objects: Node3D
var _sprites: Dictionary = {}   # Vector2i -> [art key, Sprite3D] standing on that cell
var _snow_mask: ImageTexture
var _mask_dirty := false   # the field changed since the snow mask was last drawn
var _snow_mats: Array[ShaderMaterial] = []
## The ground's wet look by cell (WetRules.farm_mask; WetLayer redraws it when wet_dirty).
var _wet_mask: ImageTexture
var wet_dirty := false   # the field changed since the wet mask was last drawn
## Buildings and trees that fade while they stand between the camera and the farmer.
var occluders := Occluders.new()
## Where the built meshes stand low enough to hide a figure's side, finer than the cells (ReachMap).
var reach: ReachMap
const FARM_HOUSE := "farmhouse"   # the farmhouse's Occluders tag (its hearth smoke follows it)
var surroundings: Surroundings   # the land past the map's edge (outdoors)
var backdrop: Backdrop           # the far mountain ridges past it (data/backdrop.json maps; else null)
var tufts: GrassTufts            # grass tufts on the grass cells (outdoors)
var rain: Dictionary = {}         # the rain dimples' style on the water (set_rain)
var prints: FootprintLayer      # footprints in lying snow (made when snow first lies)
var ice: Dictionary = {}          # the winter ice along the shore (set_ice)
var ice_snow := 0.0               # the snow lying on that ice (0..1)
var wind := 0.0                 # 0 calm .. 1 a gale (set_wind)
var _tuft_cells: Array[Vector2i] = []
var crops: CropClusters          # tall crops (rice, corn, cucumber, tomato) as clusters of small sprites; the village paddies' rice
## House windows and shoji doors that light up at night (NightLights draws them over the night tint):
## {key: picture, pos: centre, size: Vector2 (w, h), normal: Vector3 out of the wall}.
var windows: Array[Dictionary] = []
## The glow of a lamp inside on a glass roof at night (NightLights, under the roof's snow), as
## LitSpots.greenhouse_roof gives them: {corners, uvs, at, normal, own, share, ...}.
var roof_glows: Array[Dictionary] = []
## Stone lanterns lit at night (NightLights: a glow round the fire box, a pool round the foot):
## {pos: the fire box's centre}.
var lamps: Array[Dictionary] = []
## Kept out of the tree by the view (Main3D's kept worlds): field changes only mark it stale.
var away := false
var _stale := false
## A thrown item still in the air: its cell's sprite waits until the flight lands.
var hidden_item := Vector2i(-1, -1):
	set(value):
		hidden_item = value
		_rebuild_objects()


func setup(f: FarmGrid, open_cells: Array[Vector2i] = []) -> void:
	for step in setup_steps(f, open_cells):
		step.call()


## The build as steps to be called in order (setup runs them all at once; Main3D runs them
## over idle frames to have the farm ready before the farmer goes back to it).
func setup_steps(f: FarmGrid, open_cells: Array[Vector2i] = []) -> Array[Callable]:
	farm = f
	gaps = open_cells
	return [_make_ground, _make_buildings, _make_fence, _make_edges, _make_field, build_reach]


## The greenhouse's beds (Game.greenhouse, a sheltered FarmGrid) as a world of their own over
## the greenhouse map's floor (Main3D puts it at the map's plots corner): the beds' ground, the
## crops standing on them and what lies there, built and rebuilt as on the farm, with no
## buildings, fence, land past the edge, grass tufts or snow.
func setup_plots(f: FarmGrid) -> void:
	farm = f
	_make_ground()
	_make_field()


## What the world's meshes stand on at a figure's height (ReachMap), the land past the map's edge
## left out; wall_pull reads it. The last step of a build.
func build_reach() -> void:
	reach = ReachMap.new()
	reach.collect(self, [surroundings, backdrop])


## The land past the fence (Surroundings).
func _make_edges() -> void:
	var rules: Dictionary = Game.snow_rules
	add_surroundings(FarmGrid.W, FarmGrid.H,
		func(c: Vector2i) -> String: return PlaceholderArt.ground_key(farm, c).get_slice(":", 1),
		func(c: Vector2i) -> float: return SnowLayer.hold(farm, c, rules), "farm")


## The grass tufts, the tall crops and what stands or lies on the field, then the snow.
func _make_field() -> void:
	if not farm.sheltered:
		add_tufts()
	add_crops()
	_objects = Node3D.new()
	add_child(_objects)
	farm.cells_changed.connect(_rebuild_objects)
	_rebuild_objects()
	set_snow(0.0 if farm.sheltered else Game.snow_cover / 100.0)


## The farm map's story props (Hachiro's door bell), shown while their flags are set.
func make_story_props(m: MapData) -> void:
	for p in m.props:
		if p.kind in StoryView.KINDS:
			StoryProps.prop(self, p)


## Back in the view after being kept: catches up on the field changes made meanwhile.
func come_back() -> void:
	away = false
	if _stale:
		_stale = false
		_rebuild_objects()


## Snow on the ground and roofs, 0 (none) .. 1 (all white where the ground holds it).
func set_snow(cover: float) -> void:
	if farm != null and farm.sheltered:
		cover = 0.0   # the greenhouse's beds: never under snow
	if cover > 0.0 and _mask_dirty:
		_update_mask()
	for m in _snow_mats:
		m.set_shader_parameter("cover", cover)
	if crops != null:
		crops.set_cover(cover)


static func make_sprite(tex: Texture2D) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = PX
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # a billboard casts a wrong sliver (SpriteShadow)
	s.offset = Vector2(0, tex.get_height() / 2.0)   # stand on the ground
	SpriteLight.lit(s)   # the sun's colour by the clock, a share of it
	return s


## A figure's sprite (farmer, villager): make_sprite at FIGURE_PX, feet on the ground, upright.
static func make_figure(tex: Texture2D) -> Sprite3D:
	var s := make_sprite(tex)
	s.pixel_size = FIGURE_PX
	upright(s)
	return s


## Figures that stand upright (upright): Main3D stretches them each frame (stand_all).
const UPRIGHT := "upright_figures"


## Stands figure `s` upright (playtest 2026-11-13: figures sank into walls): a full billboard
## leans back with the camera's pitch, so a figure's head stood ~0.6 units behind its feet, inside
## a wall the feet were 3 px from. Turned about y only it stays vertical over its feet; stand_all
## stretches it up so it covers the same pixels on screen as the billboard did. Its sprite
## children (a held item, a note, the marks over the head) are turned the same way (upright_child).
static func upright(s: SpriteBase3D) -> void:
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.add_to_group(UPRIGHT)


## A sprite child of an upright figure: upright too, so the figure's stretch fits it (a full
## billboard under a stretched parent would come out stretched on screen).
static func upright_child(s: SpriteBase3D) -> SpriteBase3D:
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	return s


## How much an upright picture `h` units tall standing at `feet` must be stretched up for its top
## to show where a camera-facing billboard's top would, for a camera at `cam` (looking down). In
## the camera's frame the feet are `y0` up and `d` ahead, and the world's up is (0, c, s) there: the
## billboard's top shows at (y0 + h) / d, the stretched picture's at (y0 + k h c) / (d - k h s).
## A little under 1 / cos(pitch) at the middle of the screen (the top is nearer the eye; 1.09 at
## the medium lens), more near its bottom edge.
static func stretch(cam: Transform3D, feet: Vector3, h: float) -> float:
	var local := cam.affine_inverse() * feet
	var up := cam.basis.inverse() * Vector3.UP
	var d := -local.z
	var den := d * up.y + up.z * (local.y + h)
	return d / den if d > 0.01 and den > 0.01 else 1.0


## Stretches every upright figure in `tree` for camera `cam` (Main3D, after the camera moved),
## and draws it clear of a wall or prop behind its feet (wall_pull) when `solid` (a cell ->
## bool, the map's solid cells) is given, `reach` (the built world's low geometry) as well. A
## figure is never drawn nearer the eye than another whose feet are in front of it and whose
## picture it overlaps (cap_pulls).
static func stand_all(tree: SceneTree, cam: Camera3D, solid := Callable(), reach: ReachMap = null) -> void:
	var xf := cam.global_transform
	var figs: Array[Dictionary] = []
	for s: SpriteBase3D in tree.get_nodes_in_group(UPRIGHT):
		if s.is_visible_in_tree() and s is Sprite3D and s.texture != null:
			s.scale = Vector3(1, stretch(xf, s.global_position, s.texture.get_height() * s.pixel_size), 1)
			var pull := 0.0
			var ext := extents(s)
			if solid.is_valid():
				pull = wall_pull(s.global_position, ext.x, ext.y, xf, solid, {}, reach)
			figs.append({"s": s, "pull": pull, "ext": ext})
	cap_pulls(figs, cam)
	for f in figs:
		set_pull(f.s, f.pull)


## Caps each figure's pull in `figs` ({s: Sprite3D, pull, ext: Vector2 reach left / right}; pull is
## changed) so no figure is drawn nearer the eye than another whose feet are in front of it (nearer
## the camera) and whose picture on screen it overlaps: a pulled figure stays behind the figure
## standing in front of its feet (the other's own pull counts, it is drawn nearer by that much). Nearest
## figures are settled first. `gap` (data/camera.json "figure_pull") keeps them apart in depth.
static func cap_pulls(figs: Array[Dictionary], cam: Camera3D) -> void:
	var gap := float(pull_rules().get("gap", 0.02))
	var inv := cam.global_transform.affine_inverse()
	for f in figs:
		var s: Sprite3D = f.s
		var local: Vector3 = inv * s.global_position
		var d := maxf(-local.z, 0.01)
		f["depth"] = d
		var top: Vector3 = inv * (s.global_position + Vector3(0, s.texture.get_height() * s.pixel_size * s.scale.y, 0))
		# The picture's box on the screen (the camera's frame over the depth); the top is the figure's
		# head, the feet its bottom.
		f["x0"] = (local.x - f.ext.x) / d
		f["x1"] = (local.x + f.ext.y) / d
		f["y0"] = local.y / d
		f["y1"] = top.y / (maxf(-top.z, 0.01))
	var order := figs.duplicate()
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.depth < b.depth)
	for i in order.size():
		var f: Dictionary = order[i]
		if f.pull <= 0.0:
			continue
		for j in i:
			var o: Dictionary = order[j]   # nearer the eye than f
			if o.depth >= f.depth - 1e-4:
				continue
			if f.x0 >= o.x1 or o.x0 >= f.x1 or f.y0 >= o.y1 or o.y0 >= f.y1:
				continue   # side by side or one above the other on the screen
			f.pull = minf(f.pull, maxf(f.depth - (o.depth - o.pull) - gap, 0.0))


## The pull's numbers (data/camera.json "figure_pull"), read once.
static var _pull_rules := {}


static func pull_rules() -> Dictionary:
	if _pull_rules.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/camera.json"))
		_pull_rules = data.get("figure_pull", {}) if data is Dictionary else {}
		_pull_rules["read"] = true
	return _pull_rules


## How far (view depth, world units) an upright figure standing at `feet` must be drawn towards
## the eye so no part of it shows inside a solid cell behind it (playtest 2026-11-13: a figure's
## side went into a wall's corner). The upright picture is a plane through the feet along the
## camera's right; at the 45-degree view its ends reach diagonally, `left` / `right` units to
## either side (its opaque pixels: extents), so the end towards a wall the feet stand in front of
## crosses into it and the wall hides it. What stands there is the map's solid cells and, when
## `reach` is given, the low geometry of the built world (ReachMap: a prop drawn bigger than its
## cell, a post, a rail). Each point of the plane inside such a thing is followed along the view
## ray until it comes out; that counts only when it comes out through a face the feet stand beyond
## (towards the camera along x or z): a wall behind the feet. A wall in front of the figure (its
## way out is a face beyond the feet) keeps hiding it as it should. The pull is the longest way
## out, plus `margin`, at most `most`. Drawn nearer along the ray, the figure covers exactly the
## same pixels; only the depth test changes.
static func wall_pull(feet: Vector3, left: float, right: float, cam: Transform3D, solid: Callable, rules := {}, reach: ReachMap = null) -> float:
	if rules.is_empty():
		rules = pull_rules()
	var along := Vector3(cam.basis.x.x, 0, cam.basis.x.z).normalized()   # the picture's right
	var toward := Vector3(cam.basis.z.x, 0, cam.basis.z.z)   # level, towards the eye
	var level := toward.length()   # a unit along the view ray moves this far over the ground
	if level < 0.01:
		return 0.0
	toward /= level
	var step := maxf(float(rules.get("step", 0.04)), 0.005)
	var most := float(rules.get("most", 0.6))
	var march := maxf(float(rules.get("march", 0.02)), 0.005)
	var far := float(rules.get("follow", 3.0))   # the longest way out looked for over the ground
	var need := 0.0
	for side: float in [-1.0, 1.0]:
		var reach_len := right if side > 0.0 else left
		var k := 0.0
		while k < reach_len:
			k = minf(k + step, reach_len)
			var p := feet + along * side * k
			var t: Variant = _tile_at(p, solid, reach)
			if t == null:
				continue
			var run := 0.0
			while run < far:
				run += march
				var q := p + toward * run
				var u: Variant = _tile_at(q, solid, reach)
				if u == null:
					if _leaves_behind(t, q, feet, toward):
						need = maxf(need, run)
					break
				t = u
	if need <= 0.0:
		return 0.0
	return minf(need / level + float(rules.get("margin", 0.03)), most)


## The solid cell or reach tile (a Rect2 on the ground) that ground point `p` is in, or null.
static func _tile_at(p: Vector3, solid: Callable, reach: ReachMap) -> Variant:
	var c := Vector2i(floori(p.x), floori(p.z))
	if solid.call(c):
		return Rect2(Vector2(c), Vector2.ONE)
	if reach != null:
		var fx := floori(p.x / reach.res)
		var fz := floori(p.z / reach.res)
		if reach.has_tile(fx, fz):
			return Rect2(Vector2(fx, fz) * reach.res, Vector2(reach.res, reach.res))
	return null


## The ray left tile `t` at `q` (the first free point): through a face towards the camera that the
## feet stand beyond (a wall behind them)?
static func _leaves_behind(t: Rect2, q: Vector3, feet: Vector3, toward: Vector3) -> bool:
	if toward.x > 0.0 and q.x >= t.end.x and feet.x >= t.end.x:
		return true
	if toward.x < 0.0 and q.x < t.position.x and feet.x <= t.position.x:
		return true
	if toward.z > 0.0 and q.z >= t.end.y and feet.z >= t.end.y:
		return true
	return toward.z < 0.0 and q.z < t.position.y and feet.z <= t.position.y


static var _extent_cache := {}   # texture RID -> Vector2(left, right) opaque columns in pixels from the middle


## How far sprite `s`'s opaque pixels reach to the picture's left and right of its middle, in
## world units (its mirror, offset and width scale taken in).
static func extents(s: Sprite3D) -> Vector2:
	var rid := s.texture.get_rid()
	var px: Variant = _extent_cache.get(rid)
	if px == null:
		px = opaque_columns(s.texture.get_image())
		_extent_cache[rid] = px
	var e: Vector2 = px
	if s.flip_h:
		e = Vector2(e.y, e.x)
	var k := s.pixel_size * (s.global_transform.basis.x.length() if s.is_inside_tree() else s.scale.x)
	return Vector2(maxf(e.x - s.offset.x, 0.0), maxf(e.y + s.offset.x, 0.0)) * k


## The opaque columns of `img` as (pixels left of the middle, pixels right of it).
static func opaque_columns(img: Image) -> Vector2:
	if img == null or img.is_empty():
		return Vector2.ZERO
	var lo := img.get_width()
	var hi := -1
	for x in img.get_width():
		for y in img.get_height():
			if img.get_pixel(x, y).a > 0.5:
				lo = mini(lo, x)
				hi = maxi(hi, x)
				break
	if hi < 0:
		return Vector2.ZERO
	var mid := img.get_width() / 2.0
	return Vector2(mid - lo, hi + 1 - mid)


## The upright figure's own picture as the default sprite material draws it (unshaded, the
## modulate as vertex colour, alpha cut), turned about y like BILLBOARD_FIXED_Y, with every vertex
## moved `pull` towards the eye along its view ray: the same pixels, nearer in the depth test.
const PULL_SHADER := "shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D tex : source_color, filter_nearest;
uniform float pull = 0.0;
uniform float cut = 0.5;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	vec4 v = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float d = -v.z;
	if (PROJECTION_MATRIX[3][3] == 0.0 && d > 0.01) {
		v.xyz *= max(d - pull, 0.01) / d;
	}
	POSITION = PROJECTION_MATRIX * v;
	if (!OUTPUT_IS_SRGB) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
}
void fragment() {
	vec4 c = texture(tex, UV) * COLOR;
	if (c.a < cut) {
		discard;
	}
	ALBEDO = c.rgb;
}
"
static var _pull_shader: Shader


## Draws upright sprite `s` (and its upright, alpha-cut sprite children: the held item, the
## lantern, the marks) `pull` nearer the eye (wall_pull). At 0 they keep the sprite's own
## material, as drawn before; otherwise each wears a pull material of its own.
static func set_pull(s: Sprite3D, pull: float) -> void:
	for n: Node in [s] + s.get_children():
		var t := n as Sprite3D
		if t == null or (t != s and (t.billboard != BaseMaterial3D.BILLBOARD_FIXED_Y or t.alpha_cut != SpriteBase3D.ALPHA_CUT_DISCARD)):
			continue
		if pull <= 0.0 or t.texture == null:
			if t.material_override != null and t.has_meta("pull_mat"):
				t.material_override = null
			continue
		var m: ShaderMaterial = t.get_meta("pull_mat") if t.has_meta("pull_mat") else null
		if m == null:
			if _pull_shader == null:
				_pull_shader = Shader.new()
				_pull_shader.code = PULL_SHADER
			m = ShaderMaterial.new()
			m.shader = _pull_shader
			t.set_meta("pull_mat", m)
		m.set_shader_parameter("tex", t.texture)
		m.set_shader_parameter("pull", pull)
		m.set_shader_parameter("cut", t.alpha_scissor_threshold)
		t.material_override = m


## How far sprite `s` is drawn towards the eye now (0: its own material).
static func pull_of(s: Sprite3D) -> float:
	if s.material_override == null or not s.has_meta("pull_mat"):
		return 0.0
	return float((s.material_override as ShaderMaterial).get_shader_parameter("pull"))


static func flat_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _make_ground() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(farm.w * T, farm.h * T)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var view := FarmView.new()
	view.ground_only = true
	view.farm = farm
	vp.add_child(view)
	add_child(vp)

	var mat: Material
	if farm.sheltered:   # under glass: no snow mask, the beds' picture as it is
		var flat := flat_material(Color.WHITE)
		flat.albedo_texture = vp.get_texture()
		flat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat = flat
	else:
		_snow_mask = ImageTexture.create_from_image(SnowLayer.mask_image(farm, Game.snow_rules))
		_wet_mask = ImageTexture.create_from_image(WetRules.farm_mask(farm))
		mat = SnowLayer.ground_material(vp.get_texture(), _snow_mask, _wet_mask)
		_snow_mats.append(mat)
	var plane := PlaneMesh.new()
	plane.size = Vector2(farm.w, farm.h)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = mat
	ground.position = Vector3(farm.w / 2.0, 0, farm.h / 2.0)
	ground.layers = NightLamps.GROUND_LAYER   # the night's lamps leave it to the drawn pools
	add_child(ground)


## Lit material with a PlaceholderArt surface repeated once per world unit. Triplanar in the
## mesh's own space, so slanted roof slabs get their shingles straight.
static func surface_material(key: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = PlaceholderArt.tex(key)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_triplanar = true
	return m


## Lit material with one picture stretched over a quad (door, window).
static func picture_material(key: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = PlaceholderArt.tex(key)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return m


func _box(size: Vector3, center: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	mi.rotation = rot
	add_child(mi)
	return mi


## A picture on a wall: `normal_yaw` 0 faces +z (towards the camera side), 90 faces +x.
func _picture(key: String, size: Vector2, center: Vector3, normal_yaw := 0.0) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = picture_material(key)
	mi.position = center
	mi.rotation_degrees.y = normal_yaw
	add_child(mi)
	return mi


## A window from LitSpots on a house wall (see `_lit_picture`).
func _lit_spot(spot: Dictionary) -> void:
	var n: Vector3 = spot.normal
	_lit_picture(spot.key, spot.size, spot.pos, rad_to_deg(atan2(n.x, n.z)))
	windows.back().merge(spot)   # and what else LitSpots gave it (its wall's finish)


## A window (or a shoji door) on a house wall that glows at night: the same as `_picture`,
## and kept in `windows` for NightLights.
func _lit_picture(key: String, size: Vector2, center: Vector3, normal_yaw := 0.0) -> void:
	_picture(key, size, center, normal_yaw)
	var normal := Vector3(0, 0, 1).rotated(Vector3.UP, deg_to_rad(normal_yaw))
	windows.append({"key": key, "pos": center, "size": size, "normal": normal})
	if not is_in_group(NightLights.GROUP):
		add_to_group(NightLights.GROUP)


## A stone lantern's fire box at `at` that burns at night (kept in `lamps` for NightLights).
func lit_lamp(at: Vector3) -> void:
	lamps.append({"pos": at})
	if not is_in_group(NightLights.GROUP):
		add_to_group(NightLights.GROUP)


## Buildings over the fixed cells laid out by FarmGrid.generate(). The camera looks from +x / +z,
## so doors and windows go on those faces.
func _make_buildings() -> void:
	# The same every time: kept a run (MeshCache), the lit windows and the stand's noren with
	# the rest.
	occlude(_make_house, FARM_HOUSE)
	_make_hearth_smoke()
	MeshCache.build(self, "farm|chest", func(): FarmProps.chest(self))
	MeshCache.build(self, "farm|bin", func(): FarmProps.bin(self))
	occlude(func(): MeshCache.build(self, "farm|stand", func(): FarmProps.stand(self)))
	var built: Array = Game.house_built.duplicate()   # the wings (coop_wing, barn_wing) make the buildings longer
	var coop_id := "farm|coop" + ("|wing" if "coop_wing" in built else "")
	var barn_id := "farm|barn" + ("|wing" if "barn_wing" in built else "")
	occlude(func(): MeshCache.build(self, coop_id, func(): CoopProps.coop(self, built)))
	occlude(func(): MeshCache.build(self, barn_id, func(): BarnProps.barn(self, built)))
	if "silo" in built:   # the fodder silo, once Hachiro has built it
		occlude(func(): MeshCache.build(self, "farm|silo", func(): SiloProps.silo(self)))
		SiloProps.pile(self)   # its grass pile, by the stores (not kept: it changes with each cut)
	if "greenhouse" in built:   # the glasshouse in the field's corner, once Hachiro has built it
		occlude(func(): MeshCache.build(self, "farm|greenhouse", func(): GreenhouseProps.greenhouse(self)))


## Runs a builder and keeps what it made as one thing that fades when in the way (if tall).
func occlude(build: Callable, tag := "") -> void:
	var first := get_child_count()
	build.call()
	occluders.add_children_from(self, first, tag)


## The apron and the wood past a w x h map's edge (Surroundings), its snow with the rest; on
## the maps of data/backdrop.json the land stops at the rim and the far ridges stand past it.
func add_surroundings(w: int, h: int, kind_at: Callable, hold_at: Callable, map_id := "") -> void:
	surroundings = Surroundings.new()
	add_child(surroundings)
	var far := Backdrop.on_map(map_id)
	if far:
		surroundings.build(w, h, kind_at, hold_at, Backdrop.rim(), Backdrop.rim_pines())
	else:
		surroundings.build(w, h, kind_at, hold_at)
	if far:
		backdrop = Backdrop.new()
		add_child(backdrop)
		backdrop.build(w, h)
	if surroundings.water != null:
		surroundings.water.set_rain(rain)
		surroundings.water.set_ice(ice, ice_snow)
	_snow_mats.append(surroundings.material)
	_snow_mats.append_array(surroundings.snow_mats)


## The grass tufts (GrassTufts), their snow with the rest; `plant_tufts` grows them.
func add_tufts() -> void:
	tufts = GrassTufts.new()
	add_child(tufts)
	_snow_mats.append(tufts.snow_material())
	tufts.set_wind(wind)


## The wind, 0 (calm) .. 1 (a gale), pushed to the grass tufts' shader and the world's Sway
## (bamboo, the fence's leafy shoots, the kadomatsu's greens, noren, stall curtains, banners),
## and on to the layers that are worlds of their own (FestivalProps) (data/wind.json through
## Game.wind_strength; main_3d sets it each morning and on a map change).
func set_wind(strength: float) -> void:
	wind = clampf(strength, 0.0, 1.0)
	if tufts != null:
		tufts.set_wind(wind)
	if crops != null:
		crops.set_wind(wind)
	var sway := get_node_or_null(OutdoorProps.SWAY) as OutdoorProps.Sway
	if sway != null:
		sway.wind = wind
	for n in get_children():   # layers that are worlds of their own (today's FestivalProps)
		if n is FarmWorld:
			(n as FarmWorld).set_wind(wind)


## Rain dimples on the water (a weather_fx.json "dimples" style; {} = none), passed to the sheet
## and to the layers that are worlds of their own.
func set_rain(style: Dictionary) -> void:
	rain = style
	if surroundings != null and surroundings.water != null:
		surroundings.water.set_rain(rain)
	for n in get_children():
		if n is FarmWorld:
			(n as FarmWorld).set_rain(rain)


## Winter ice along the shore of the water (Game.ice_style(); {} = none) and the snow lying on
## it (0..1), passed to the sheet and to the layers that are worlds of their own.
func set_ice(style: Dictionary, snow := 0.0) -> void:
	ice = style
	ice_snow = snow
	if surroundings != null and surroundings.water != null:
		surroundings.water.set_ice(ice, ice_snow)
	for n in get_children():
		if n is FarmWorld:
			(n as FarmWorld).set_ice(ice, ice_snow)


## The farmer's feet (Main3D, each frame): the grass tufts and tall crops round them part
## (Parting), on the map and on the apron past its edge. So do they round the villagers and
## the dog on this map (their sprites are in Parting.GROUP), the nearest to the farmer first.
func set_farmer(feet: Vector3, facing := Vector2.ZERO, running := false, tired := false) -> void:
	var others: Array = []
	var startle: Array = []   # the walkers the birds take fright at (the crawler does not: BirdRules.scares)
	var walkers := {"farmer": Vector2(feet.x, feet.z)}   # for the footprints (Footprints): the same walkers
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group(Parting.GROUP):
			var s := n as Node3D
			if s != null and s.visible and is_ancestor_of(s):
				others.append(Vector2(s.position.x, s.position.z))
				walkers[s.get_instance_id()] = Vector2(s.position.x, s.position.z)
				if s.get_meta("bird_scare", true):
					startle.append(Vector2(s.position.x, s.position.z))
	var pushers := Parting.pick(Vector2(feet.x, feet.z), others, int(Parting.rules("grass").max))
	if tufts != null:
		tufts.set_pushers(pushers)
	if surroundings != null and surroundings.tufts != null:
		surroundings.tufts.set_pushers(pushers)
	if crops != null:
		crops.set_pushers(pushers)
	var birds := get_node_or_null("Birds") as BirdLayer
	if birds != null:
		birds.farmer = Vector2(feet.x, feet.z)   # sparrows and the heron fly off from him
		birds.others = startle                   # and from the villagers, the dog and the walking child
	var breath := get_node_or_null("Breath") as BreathLayer
	if breath != null:   # the farmer's breath (BreathLayer): his feet, the way he faces, running or tired
		breath.farmer = {"cell": Vector2(feet.x, feet.z), "facing": facing, "running": running, "tired": tired, "lift": feet.y}   # his puffs follow a lifted sprite
	var insects := get_node_or_null("Insects") as InsectLayer
	if insects != null:
		insects.farmer = Vector2(feet.x, feet.z)   # a resting dragonfly lifts off and a butterfly veers from him
		insects.others = startle                   # and from the villagers, the dog and the walking child
	var cicadas := get_node_or_null("Cicadas") as CicadaLayer
	if cicadas != null:
		cicadas.farmer = Vector2(feet.x, feet.z)   # a clinging cicada flies off from him
		cicadas.others = startle                   # and from the villagers, the dog and the walking child
	_leave_prints(walkers)


## Footprints: the walkers (set_farmer) leave them while enough snow lies out in the open.
func _leave_prints(walkers: Dictionary) -> void:
	var cover := float(Game.snow_cover)
	if prints == null:
		if not Footprints.from_game().active(cover, Game.sheltered()):
			return
		prints = FootprintLayer.new()
		add_child(prints)
	prints.feed(walkers, cover, Game.sheltered(), Footprints.ground_snow)


## `--footprints` (screenshots): a trail already pressed behind the farmer at `feet` (the older
## prints part-filled) and another walker's crossing it, by feeding made-up steps.
func seed_prints(feet: Vector3) -> void:
	_leave_prints({"farmer": Vector2(feet.x - 5.0, feet.z + 3.0), "walker": Vector2(feet.x + 3.0, feet.z + 5.0)})
	if prints == null:
		return
	for i in 16:
		var t := (i + 1) / 16.0
		_leave_prints({"farmer": Vector2(feet.x - 5.0 + 5.0 * t, feet.z + 3.0 - 2.0 * t + sin(t * 5.0) * 0.4),
			"walker": Vector2(feet.x + 3.0 - 8.0 * t, feet.z + 5.0 - 3.0 * t)})
	var n: int = prints.trail.prints.size()
	for i in n:
		prints.trail.prints[i].age = 40.0 * (1.0 - float(i) / n)
	prints.age(0.0, false)


## Game time passes: the prints age (quicker while snow falls over them).
func age_prints(minutes: float) -> void:
	if prints != null:
		prints.age(minutes, str(Game.weather_style().get("fall", "")) == "snow" and not Game.sheltered())


func clear_prints() -> void:
	if prints != null:
		prints.clear()


## The tall crops' clusters (CropClusters); FarmWorld plants them with the field, MapWorld
## on the paddies.
func add_crops() -> void:
	crops = CropClusters.new()
	add_child(crops)
	crops.set_cover(Game.snow_cover / 100.0)
	crops.set_wind(wind)


## Tufts on `cells` (only when the grass changed: a tool swing that touches no grass keeps them).
func plant_tufts(cells: Array[Vector2i], hold_at: Callable) -> void:
	if tufts != null and cells != _tuft_cells:
		_tuft_cells = cells
		tufts.plant(cells, hold_at)


## A small Japanese farmhouse on cells x 2..6, z 1..3: dark board skirting under white
## plaster between dark timbers, a thick thatched hip roof (Minka) with a crossed ridge, and an engawa
## (veranda) along the front under the eaves, with a shoji door and windows on the faces the
## camera sees (+z, +x).
func _make_house() -> void:
	MeshCache.build(self, "farm|house", func() -> void:
		_house_body()
		# Shoji door over the door cell (4, 3), shoji windows beside it and on the +x face.
		for spot in LitSpots.farmhouse():
			_lit_spot(spot))


## The farmhouse's hearth smoke (HearthSmoke) from the middle of its ridge: the roof of
## _house_body (eave Rect2(1.45, 0.55, 6.1, 3.5), soffit 1.45, pitch 1.25, the ridge along x).
## Not inside occlude (it is no wall of its own), but it fades with the house (HearthSmoke.house_keep, by FARM_HOUSE).
func _make_hearth_smoke() -> void:
	add_child(HearthSmoke.new(4, SmokeRules.farm_vent(), FARM_HOUSE))


## The farmhouse's walls, frame, engawa and roof (_make_house).
func _house_body() -> void:
	var timber := flat_material(Color("2e221a"))
	var front := LitSpots.FARM_FRONT      # wall face; the engawa fills z 3.6 .. 4.0
	var depth := front - 1.0
	var mid := 1.0 + depth / 2
	_box(Vector3(5, 0.6, depth), Vector3(4.5, 0.3, mid), surface_material("build:board"))
	_box(Vector3(5, 1.2, depth), Vector3(4.5, 1.2, mid), surface_material("build:plaster"))
	# Timber frame standing a little proud of the walls: posts, a sill beam and a top beam.
	for x in [2.0, 3.6, 5.4, 7.0]:
		_box(Vector3(0.12, 1.8, 0.08), Vector3(x, 0.9, front + 0.02), timber)
	for z in [1.0, mid, front]:
		_box(Vector3(0.08, 1.8, 0.12), Vector3(7.02, 0.9, z), timber)
	for y in [0.62, 1.76]:
		_box(Vector3(5.1, 0.08, 0.06), Vector3(4.5, y, front + 0.03), timber)
		_box(Vector3(0.06, 0.08, depth + 0.1), Vector3(7.03, y, mid), timber)
	# Engawa: a plank deck on a dark base, two eave posts at its front corners.
	_box(Vector3(5, 0.24, 0.38), Vector3(4.5, 0.12, front + 0.2), timber)
	_box(Vector3(5.1, 0.08, 0.42), Vector3(4.5, 0.28, front + 0.2), surface_material("build:planks"))
	for x in [2.08, 6.92]:
		_box(Vector3(0.1, 1.5, 0.1), Vector3(x, 0.75, front + 0.36), timber)
	_box(Vector3(0.6, 0.06, 0.3), Vector3(4.5, 0.03, front + 0.55), flat_material(Color("8a8680")))   # step stone
	# A thick thatched hip roof (Minka) over walls raised to meet it: steep slopes (rise 1.25
	# per run, about 51°) from a soffit 1.45 high at the front eave (z 4.05, above the farmer's
	# head on the cell in front) to a ridge along x, the eaves half a cell past the walls all
	# round, half a unit of straw thick.
	_box(Vector3(5, 0.34, depth), Vector3(4.5, 1.93, mid), timber)   # under the roof, fills the gap to the soffit
	Minka.roof(self, Rect2(1.45, 0.55, 6.1, 3.5), 1.45, 1.25, 0.5)


## Many copies of one mesh in a single MultiMesh.
func _multi(mesh: Mesh, transforms: Array[Transform3D], mat: Material) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)


## A low bamboo lattice fence (yotsume-gaki look) along the border cells, lit meshes
## (OutdoorProps.fence_post / fence_cane / fence_rail): a thick bamboo post per cell, thin canes
## standing between the posts, two cross rails a side, cord ties where the rails meet the posts,
## snow on the caps and the upper rail. Its line runs through the border cells' middles.
func _make_fence() -> void:
	var w := float(FarmGrid.W)
	var h := float(FarmGrid.H)
	var line: Array[Vector2] = []      # (x, z) of every post, none in the gate
	for x in FarmGrid.W:
		line.append(Vector2(x + 0.5, 0.5))
		line.append(Vector2(x + 0.5, h - 0.5))
	for z in range(1, FarmGrid.H - 1):
		line.append(Vector2(0.5, z + 0.5))
		line.append(Vector2(w - 0.5, z + 0.5))
	# The same for the same gate, so built once a run (MeshCache) and placed after that.
	MeshCache.commit(self, MeshCache.parts("farm_fence:%s" % [gaps], _fence_parts.bind(line)))
	# About one post in five keeps a leafy side shoot along the line (not at the corners or
	# beside the gate); only the shoots move in the wind (OutdoorProps.Sway), the fence stands.
	for q in line:
		var along := Vector2(1, 0) if q.y == 0.5 or q.y == h - 0.5 else Vector2(0, 1)
		var corner := (q.x == 0.5 or q.x == w - 0.5) and (q.y == 0.5 or q.y == h - 0.5)
		if corner or posmod(int(q.x) * 7 + int(q.y) * 11, 5) != 0 or _open(q) or _open(q + along) or _open(q - along):
			continue
		var flip := posmod(int(q.x) + int(q.y), 2) == 0
		var yaw := (0.0 if along.x > 0.0 else PI / 2) + (PI if flip else 0.0)
		OutdoorProps.fence_spray(self, q.x, q.y, yaw, Game.season_name(), q.x * 1.3 + q.y * 0.7)


## The fence's posts, canes and rails (OutdoorProps.fence_*) on the post spots `line` into `p`.
func _fence_parts(p: FarmProps.Parts, line: Array[Vector2]) -> void:
	var w := float(FarmGrid.W)
	var h := float(FarmGrid.H)
	for q in line:
		if not _open(q):
			OutdoorProps.fence_post(p, q.x, q.y)
	# Thin canes a third of a cell apart along each side, skipping the post spots.
	for i in range(1, (FarmGrid.W - 1) * 3):
		if i % 3 != 0:
			for z in [0.5, h - 0.5]:
				if not _open(Vector2(0.5 + i / 3.0, z), true):
					OutdoorProps.fence_cane(p, 0.5 + i / 3.0, z)
	for i in range(1, (FarmGrid.H - 1) * 3):
		if i % 3 != 0:
			for x in [0.5, w - 0.5]:
				if not _open(Vector2(x, 0.5 + i / 3.0), true):
					OutdoorProps.fence_cane(p, x, 0.5 + i / 3.0)
	# Cross rails run post to post, cut at the gate (the opening spans the gate cells and a
	# post each side).
	for y in OutdoorProps.FENCE_RAILS:
		for z in [0.5, h - 0.5]:
			for run in _runs(func(t: float): return Vector2(t, z), w):
				OutdoorProps.fence_rail(p, Vector3(run.x, y, z), Vector3(run.y, y, z))
		for x in [0.5, w - 0.5]:
			for run in _runs(func(t: float): return Vector2(x, t), h):
				OutdoorProps.fence_rail(p, Vector3(x, y, run.x), Vector3(x, y, run.y))


## Is the fence spot (x, z) in a gate cell? `between` also counts the stretch from a gate
## cell to the next post (canes between the posts beside the gate).
func _open(p: Vector2, between := false) -> bool:
	for g in gaps:
		var r := Rect2(Vector2(g) - (Vector2(0.5, 0.5) if between else Vector2.ZERO),
			Vector2.ONE * (2.0 if between else 1.0))
		if r.has_point(p):
			return true
	return false


## The stretches [from, to] of one fence side (post middles 0.5 .. length - 0.5) that are not
## gate; `at` turns a distance along the side into the (x, z) spot.
func _runs(at: Callable, length: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var start := 0.5
	var t := 0.5
	while t <= length - 0.5:
		if _open(at.call(t)):
			if t - 1.0 > start:
				out.append(Vector2(start, t - 1.0))
			start = t + 1.0
		t += 1.0
	if length - 0.5 > start:
		out.append(Vector2(start, length - 0.5))
	return out


## A snow top over a roof slab or lid: a thin slab just above it, a little smaller, so the
## eaves keep a dark rim.
func _snow_top(size: Vector3, center: Vector3, rot := Vector3.ZERO) -> void:
	var m := SnowLayer.top_material()
	_snow_mats.append(m)
	var top := _box(size, center, m, rot)
	top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _update_mask() -> void:
	_snow_mask.update(SnowLayer.mask_image(farm, Game.snow_rules))
	_mask_dirty = false


## Redraws the ground's wet mask from the field as it is now (WetLayer, while it is wet).
func update_wet_mask() -> void:
	wet_dirty = false
	if _wet_mask != null:
		_wet_mask.update(WetRules.farm_mask(farm))


func _rebuild_objects() -> void:
	if away:
		_stale = true
		return
	# The snow mask only matters while snow lies; otherwise it waits for set_snow (none under glass).
	_mask_dirty = not farm.sheltered
	wet_dirty = _wet_mask != null
	if Game.snow_cover > 0 and not farm.sheltered:
		_update_mask()
	# Only cells whose picture changed get a new sprite, and bare cells are skipped first (the
	# wide farm has 3000 cells; a full rebuild per tool swing was a visible hitch).
	var grass: Array[Vector2i] = []
	for i in farm.cells.size():   # tufts on bare grass: not tilled, nothing standing or lying
		var d: Dictionary = farm.cells[i]
		var c := Vector2i(i % farm.w, i / farm.w)
		if not farm.sheltered and farm.fixed_at(c) == "" and not d.tilled and d.obj == FarmGrid.Obj.NONE and d.crop == "" and not farm.items.has(c):
			grass.append(c)
	var rules: Dictionary = Game.snow_rules
	plant_tufts(grass, func(c: Vector2i) -> float: return SnowLayer.hold(farm, c, rules))
	var seen := {}
	var clusters := {}   # tall crops grown past the sprout: CropClusters, not one sprite
	for i in farm.cells.size():
		var d: Dictionary = farm.cells[i]
		var c := Vector2i(i % farm.w, i / farm.w)
		if d.obj == FarmGrid.Obj.NONE and d.crop == "" and not farm.items.has(c):
			continue
		if not farm.can_farm(c):
			continue
		var key := PlaceholderArt.cell_key(farm, d)
		if farm.item_at(c) != "":
			key = PlaceholderArt.world_item_key(farm.item_at(c))   # items only lie on empty cells
		if key == "":
			continue
		var cluster := CropClusters.key_for(key)
		if cluster != "" and c != hidden_item:
			clusters[c] = cluster
			continue
		seen[c] = true
		var old: Array = _sprites.get(c, [])
		var s: Sprite3D
		if not old.is_empty() and old[0] == key:
			s = old[1]
		else:
			if not old.is_empty():
				old[1].queue_free()
			s = make_sprite(PlaceholderArt.tex(key))
			s.position = Vector3(c.x + 0.5, 0, c.y + 0.5)
			_objects.add_child(s)
			SpriteShadow.attach(s, 0.0, false)   # a crop throws the sun's shadow, no blob
			_sprites[c] = [key, s]
		s.visible = c != hidden_item
	for c in _sprites.keys():
		if not seen.has(c):
			_sprites[c][1].queue_free()
			_sprites.erase(c)
	if crops != null:
		crops.plant(clusters, func(_c: Vector2i) -> float: return 0.0)   # a crop stands in snow, as its sprite did
