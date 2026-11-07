class_name FarmWorld
extends Node3D
## The farm in 3D: 1 unit = 1 cell, x = column, z = row, y up.
## Ground = the 2D FarmView (ground only) rendered into a texture; obstacles and crops
## stand up as camera-facing sprites; buildings are textured boxes. Snow lying on the ground
## and roofs (Game.snow_cover) is drawn by SnowLayer shaders.

const T := 16
const PX := 0.045              # world units per sprite pixel (a 24 px farmer ~ 1.1 cells tall)

var farm: FarmGrid
var gaps: Array[Vector2i] = []   # fence cells left open (the gate to the village)
var _objects: Node3D
var _sprites: Dictionary = {}   # Vector2i -> [art key, Sprite3D] standing on that cell
var _snow_mask: ImageTexture
var _mask_dirty := false   # the field changed since the snow mask was last drawn
var _snow_mats: Array[ShaderMaterial] = []
## Buildings and trees that fade while they stand between the camera and the farmer.
var occluders := Occluders.new()
var surroundings: Surroundings   # the land past the map's edge (outdoors)
var backdrop: Backdrop           # the far mountain ridges past it (data/backdrop.json maps; else null)
var tufts: GrassTufts            # grass tufts on the grass cells (outdoors)
var wind := 0.0                  # 0 calm .. 1 a gale (set_wind)
var _tuft_cells: Array[Vector2i] = []
var crops: CropClusters          # tall crops (rice, corn) as clusters of small sprites; the village paddies' rice
## House windows and shoji doors that light up at night (NightLights draws them over the night tint):
## {key: picture, pos: centre, size: Vector2 (w, h), normal: Vector3 out of the wall}.
var windows: Array[Dictionary] = []
## Stone lanterns lit at night (NightLights: a glow round the fire box, a pool round the foot):
## {pos: the fire box's centre}.
var lamps: Array[Dictionary] = []
## A thrown item still in the air: its cell's sprite waits until the flight lands.
var hidden_item := Vector2i(-1, -1):
	set(value):
		hidden_item = value
		_rebuild_objects()


func setup(f: FarmGrid, open_cells: Array[Vector2i] = []) -> void:
	farm = f
	gaps = open_cells
	_make_ground()
	_make_buildings()
	var rules: Dictionary = Game.snow_rules
	add_surroundings(FarmGrid.W, FarmGrid.H,
		func(c: Vector2i) -> String: return PlaceholderArt.ground_key(farm, c).get_slice(":", 1),
		func(c: Vector2i) -> float: return SnowLayer.hold(farm, c, rules), "farm")
	add_tufts()
	add_crops()
	_objects = Node3D.new()
	add_child(_objects)
	farm.cells_changed.connect(_rebuild_objects)
	_rebuild_objects()
	set_snow(Game.snow_cover / 100.0)


## The farm map's story props (Hachiro's door bell), shown while their flags are set.
func make_story_props(m: MapData) -> void:
	for p in m.props:
		if p.kind in StoryView.KINDS:
			StoryProps.prop(self, p)


## Snow on the ground and roofs, 0 (none) .. 1 (all white where the ground holds it).
func set_snow(cover: float) -> void:
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
	s.offset = Vector2(0, tex.get_height() / 2.0)   # stand on the ground
	return s


static func flat_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _make_ground() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(FarmGrid.W * T, FarmGrid.H * T)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var view := FarmView.new()
	view.ground_only = true
	view.farm = farm
	vp.add_child(view)
	add_child(vp)

	_snow_mask = ImageTexture.create_from_image(SnowLayer.mask_image(farm, Game.snow_rules))
	var mat := SnowLayer.ground_material(vp.get_texture(), _snow_mask)
	_snow_mats.append(mat)
	var plane := PlaneMesh.new()
	plane.size = Vector2(FarmGrid.W, FarmGrid.H)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = mat
	ground.position = Vector3(FarmGrid.W / 2.0, 0, FarmGrid.H / 2.0)
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
func _picture(key: String, size: Vector2, center: Vector3, normal_yaw := 0.0) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = picture_material(key)
	mi.position = center
	mi.rotation_degrees.y = normal_yaw
	add_child(mi)


## A window from LitSpots on a house wall (see `_lit_picture`).
func _lit_spot(spot: Dictionary) -> void:
	var n: Vector3 = spot.normal
	_lit_picture(spot.key, spot.size, spot.pos, rad_to_deg(atan2(n.x, n.z)))


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
	occlude(_make_house)
	FarmProps.chest(self)
	FarmProps.bin(self)
	occlude(func(): FarmProps.stand(self))
	occlude(func(): CoopProps.coop(self))
	occlude(func(): BarnProps.barn(self))
	_make_fence()


## Runs a builder and keeps what it made as one thing that fades when in the way (if tall).
func occlude(build: Callable) -> void:
	var first := get_child_count()
	build.call()
	occluders.add_children_from(self, first)


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
	_snow_mats.append(surroundings.material)
	_snow_mats.append_array(surroundings.snow_mats)


## The grass tufts (GrassTufts), their snow with the rest; `plant_tufts` grows them.
func add_tufts() -> void:
	tufts = GrassTufts.new()
	add_child(tufts)
	_snow_mats.append(tufts.snow_material())
	tufts.set_wind(wind)


## The wind, 0 (calm) .. 1 (a gale), pushed to the grass tufts' shader and the bamboo sway
## (data/wind.json through Game.wind_strength; main_3d sets it each morning and on a map change).
func set_wind(strength: float) -> void:
	wind = clampf(strength, 0.0, 1.0)
	if tufts != null:
		tufts.set_wind(wind)
	var sway := get_node_or_null("BambooSway") as OutdoorProps.Sway
	if sway != null:
		sway.wind = wind


## The farmer's feet (Main3D, each frame): the grass tufts and tall crops round them part
## (Parting), on the map and on the apron past its edge. So do they round the villagers and
## the dog on this map (their sprites are in Parting.GROUP), the nearest to the farmer first.
func set_farmer(feet: Vector3) -> void:
	var others: Array = []
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group(Parting.GROUP):
			var s := n as Node3D
			if s != null and s.visible and is_ancestor_of(s):
				others.append(Vector2(s.position.x, s.position.z))
	var pushers := Parting.pick(Vector2(feet.x, feet.z), others, int(Parting.rules("grass").max))
	if tufts != null:
		tufts.set_pushers(pushers)
	if surroundings != null and surroundings.tufts != null:
		surroundings.tufts.set_pushers(pushers)
	if crops != null:
		crops.set_pushers(pushers)


## The tall crops' clusters (CropClusters); FarmWorld plants them with the field, MapWorld
## on the paddies.
func add_crops() -> void:
	crops = CropClusters.new()
	add_child(crops)
	crops.set_cover(Game.snow_cover / 100.0)


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
	# Shoji door over the door cell (4, 3), shoji windows beside it and on the +x face.
	for spot in LitSpots.farmhouse():
		_lit_spot(spot)


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
	var p := FarmProps.Parts.new()
	var line: Array[Vector2] = []      # (x, z) of every post, none in the gate
	for x in FarmGrid.W:
		line.append(Vector2(x + 0.5, 0.5))
		line.append(Vector2(x + 0.5, h - 0.5))
	for z in range(1, FarmGrid.H - 1):
		line.append(Vector2(0.5, z + 0.5))
		line.append(Vector2(w - 0.5, z + 0.5))
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
	p.commit(self)


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


func _rebuild_objects() -> void:
	# The snow mask only matters while snow lies; otherwise it waits for set_snow.
	_mask_dirty = true
	if Game.snow_cover > 0:
		_update_mask()
	# Only cells whose picture changed get a new sprite, and bare cells are skipped first (the
	# wide farm has 3000 cells; a full rebuild per tool swing was a visible hitch).
	var grass: Array[Vector2i] = []
	for i in farm.cells.size():   # tufts on bare grass: not tilled, nothing standing or lying
		var d: Dictionary = farm.cells[i]
		var c := Vector2i(i % FarmGrid.W, i / FarmGrid.W)
		if farm.fixed_at(c) == "" and not d.tilled and d.obj == FarmGrid.Obj.NONE and d.crop == "" and not farm.items.has(c):
			grass.append(c)
	var rules: Dictionary = Game.snow_rules
	plant_tufts(grass, func(c: Vector2i) -> float: return SnowLayer.hold(farm, c, rules))
	var seen := {}
	var clusters := {}   # tall crops grown past the sprout: CropClusters, not one sprite
	for i in farm.cells.size():
		var d: Dictionary = farm.cells[i]
		var c := Vector2i(i % FarmGrid.W, i / FarmGrid.W)
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
			_sprites[c] = [key, s]
		s.visible = c != hidden_item
	for c in _sprites.keys():
		if not seen.has(c):
			_sprites[c][1].queue_free()
			_sprites.erase(c)
	if crops != null:
		crops.plant(clusters, func(_c: Vector2i) -> float: return 0.0)   # a crop stands in snow, as its sprite did
