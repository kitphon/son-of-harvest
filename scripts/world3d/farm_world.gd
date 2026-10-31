class_name FarmWorld
extends Node3D
## The farm in 3D: 1 unit = 1 cell, x = column, z = row, y up.
## Ground = the 2D FarmView (ground only) rendered into a texture; obstacles and crops
## stand up as camera-facing sprites; buildings are textured boxes. Snow lying on the ground
## and roofs (Game.snow_cover) is drawn by SnowLayer shaders.

const T := 16
const PX := 0.045              # world units per sprite pixel (a 24 px farmer ~ 1.1 cells tall)

var farm: FarmGrid
var _objects: Node3D
var _snow_mask: ImageTexture
var _snow_mats: Array[ShaderMaterial] = []


func setup(f: FarmGrid) -> void:
	farm = f
	_make_ground()
	_make_buildings()
	_objects = Node3D.new()
	add_child(_objects)
	farm.cells_changed.connect(_rebuild_objects)
	_rebuild_objects()
	set_snow(Game.snow_cover / 100.0)


## Snow on the ground and roofs, 0 (none) .. 1 (all white where the ground holds it).
func set_snow(cover: float) -> void:
	for m in _snow_mats:
		m.set_shader_parameter("cover", cover)


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


## Buildings over the fixed cells laid out by FarmGrid.generate(). The camera looks from +x / +z,
## so doors and windows go on those faces.
func _make_buildings() -> void:
	_make_house()
	_make_chest()
	_make_bin()
	_make_stand()
	_make_fence()


## Shipping bin (cell 8, 3): a lidded cedar box on two runners, dark corner battens, a straw
## rope tied round its middle and two battens across the lid.
func _make_bin() -> void:
	var timber := flat_material(Color("2e221a"))
	for z in [3.2, 3.8]:
		_box(Vector3(0.9, 0.08, 0.12), Vector3(8.5, 0.04, z), timber)
	_box(Vector3(0.84, 0.5, 0.74), Vector3(8.5, 0.33, 3.5), surface_material("build:sugi"))
	for x in [8.08, 8.92]:
		for z in [3.13, 3.87]:
			_box(Vector3(0.06, 0.5, 0.06), Vector3(x, 0.33, z), timber)
	_box(Vector3(0.87, 0.05, 0.77), Vector3(8.5, 0.36, 3.5), flat_material(Color("c8b078")))   # rope
	_box(Vector3(0.94, 0.08, 0.84), Vector3(8.5, 0.62, 3.5), surface_material("build:planks"))
	for x in [8.22, 8.78]:
		_box(Vector3(0.08, 0.05, 0.86), Vector3(x, 0.685, 3.5), timber)
	_snow_top(Vector3(0.86, 0.04, 0.76), Vector3(8.5, 0.68, 3.5))


## Storage chest (cell 7, 3, FarmGrid.CHEST), by the house wall: a low cedar tansu on a dark
## plinth, two drawer fronts with black iron pulls and corner plates on the faces the camera
## sees, and a plank lid.
func _make_chest() -> void:
	var timber := flat_material(Color("2e221a"))
	var iron := flat_material(Color("1e1c1c"))
	_box(Vector3(0.78, 0.08, 0.56), Vector3(7.52, 0.04, 3.5), timber)
	_box(Vector3(0.74, 0.46, 0.52), Vector3(7.52, 0.31, 3.5), surface_material("build:sugi"))
	for y in [0.2, 0.42]:   # drawer fronts on the +z face, a pull in each
		_box(Vector3(0.64, 0.18, 0.02), Vector3(7.52, y, 3.77), surface_material("build:planks"))
		_box(Vector3(0.14, 0.03, 0.03), Vector3(7.52, y, 3.79), iron)
	for x in [7.16, 7.88]:  # corner plates down the front edges
		_box(Vector3(0.05, 0.46, 0.05), Vector3(x, 0.31, 3.76), iron)
	_box(Vector3(0.02, 0.1, 0.1), Vector3(7.9, 0.31, 3.5), iron)   # side handle
	_box(Vector3(0.8, 0.06, 0.58), Vector3(7.52, 0.57, 3.5), surface_material("build:planks_dark"))
	_snow_top(Vector3(0.74, 0.03, 0.52), Vector3(7.52, 0.61, 3.5))


## Seed stand (cell 10, 3): a roadside stall with a small board gable roof on four posts, an
## indigo noren under the front eave, the seed sacks and a little honesty box on the counter.
func _make_stand() -> void:
	var timber := flat_material(Color("2e221a"))
	_box(Vector3(0.9, 0.6, 0.6), Vector3(10.5, 0.3, 3.65), surface_material("build:planks"))
	for x in [10.08, 10.92]:
		for z in [3.32, 3.98]:
			_box(Vector3(0.07, 1.32, 0.07), Vector3(x, 0.66, z), timber)
	_box(Vector3(0.92, 0.06, 0.06), Vector3(10.5, 1.29, 3.98), timber)   # noren beam
	# Gable roof, ridge along x at z 3.65; the eaves end at 1.32 high, z 3.2 / 4.1.
	var dark := surface_material("build:planks_dark")
	var half := 0.45
	var rise := 0.2
	var slope := atan2(rise, half)
	var length := Vector2(half, rise).length() + 0.06
	for side in [1, -1]:
		var center := Vector3(10.5, 1.32 + rise / 2 + 0.03, 3.65 + side * half / 2)
		_box(Vector3(1.12, 0.05, length), center, dark, Vector3(slope * side, 0, 0))
		var up := Vector3(0, cos(slope), sin(slope) * side)
		_snow_top(Vector3(1.04, 0.03, length - 0.08), center + up * 0.04, Vector3(slope * side, 0, 0))
	_box(Vector3(1.16, 0.06, 0.08), Vector3(10.5, 1.32 + rise + 0.05, 3.65), timber)
	_picture("build:noren", Vector2(0.84, 0.32), Vector3(10.5, 1.1, 4.0))
	var sacks := [Color("e8d8a8"), Color("c9a26b"), Color("b8c890")]
	for i in 3:
		_box(Vector3(0.22, 0.14, 0.22), Vector3(10.22 + i * 0.28, 0.67, 3.62), flat_material(sacks[i]))
	_box(Vector3(0.14, 0.12, 0.1), Vector3(10.78, 0.66, 3.88), surface_material("build:sugi"))


## A small Japanese farmhouse on cells x 2..6, z 1..3: dark board skirting under white
## plaster between dark timbers, a grey tiled gable roof with a heavy ridge, and an engawa
## (veranda) along the front under the eaves, with a shoji door and windows on the faces the
## camera sees (+z, +x).
func _make_house() -> void:
	var timber := flat_material(Color("2e221a"))
	var front := 3.6                     # wall face; the engawa fills z 3.6 .. 4.0
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
	# Gable over the walls, ridge along x over the walls' middle.
	var rise := 1.0
	var ridge := Vector3(4.5, 1.8 + rise, mid)
	var gable := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(depth, rise, 5)
	gable.mesh = prism
	gable.material_override = surface_material("build:plaster")
	gable.position = Vector3(4.5, 1.8 + rise / 2, mid)
	gable.rotation_degrees.y = 90
	add_child(gable)
	# Roof slabs from the ridge to just past the engawa (eave ~1.45 high at z ~4.05, above the
	# farmer's head on the cell in front), then the ridge cap.
	var kawara := surface_material("build:kawara")
	var slope := atan2(rise, depth / 2)
	var length := (4.05 - mid) / cos(slope)
	for side in [1, -1]:
		var down := Vector3(0, -sin(slope), cos(slope) * side)
		var up := Vector3(0, cos(slope), sin(slope) * side)
		var center := ridge + down * (length / 2 - 0.05) + up * 0.06
		_box(Vector3(5.7, 0.1, length), center, kawara, Vector3(slope * side, 0, 0))
		_snow_top(Vector3(5.5, 0.05, length - 0.12), center + up * 0.07 + down * 0.02, Vector3(slope * side, 0, 0))
	_box(Vector3(5.9, 0.18, 0.26), ridge + Vector3(0, 0.12, 0), flat_material(Color("3a424c")))
	for x in [1.62, 7.38]:
		_box(Vector3(0.16, 0.3, 0.32), Vector3(x, ridge.y + 0.16, mid), flat_material(Color("3a424c")))
	# Shoji door over the door cell (4, 3), shoji windows beside it and on the +x face.
	_picture("build:shoji_door", Vector2(0.9, 1.3), Vector3(4.5, 0.32 + 0.65, front + 0.005))
	_picture("build:shoji", Vector2(0.8, 0.6), Vector3(2.8, 1.2, front + 0.005))
	_picture("build:shoji", Vector2(0.8, 0.6), Vector3(6.2, 1.2, front + 0.005))
	_picture("build:shoji", Vector2(0.8, 0.6), Vector3(7.005, 1.2, mid), 90)


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


## A low bamboo lattice fence (yotsume-gaki look) along the border cells: a thick bamboo post
## per cell, thin canes standing between the posts, two cross canes a side, and dark rope ties
## where the cross canes meet the posts. Its line runs through the border cells' middles.
func _make_fence() -> void:
	var w := float(FarmGrid.W)
	var h := float(FarmGrid.H)
	var bamboo := surface_material("build:bamboo")
	var line: Array[Vector2] = []      # (x, z) of every post
	for x in FarmGrid.W:
		line.append(Vector2(x + 0.5, 0.5))
		line.append(Vector2(x + 0.5, h - 0.5))
	for z in range(1, FarmGrid.H - 1):
		line.append(Vector2(0.5, z + 0.5))
		line.append(Vector2(w - 0.5, z + 0.5))
	var posts: Array[Transform3D] = []
	var ties: Array[Transform3D] = []
	for p in line:
		posts.append(Transform3D(Basis(), Vector3(p.x, 0.32, p.y)))
		for y in [0.2, 0.44]:
			ties.append(Transform3D(Basis(), Vector3(p.x, y, p.y)))
	# Thin canes a third of a cell apart along each side, skipping the post spots.
	var canes: Array[Transform3D] = []
	for i in range(1, (FarmGrid.W - 1) * 3):
		if i % 3 != 0:
			for z in [0.5, h - 0.5]:
				canes.append(Transform3D(Basis(), Vector3(0.5 + i / 3.0, 0.26, z)))
	for i in range(1, (FarmGrid.H - 1) * 3):
		if i % 3 != 0:
			for x in [0.5, w - 0.5]:
				canes.append(Transform3D(Basis(), Vector3(x, 0.26, 0.5 + i / 3.0)))
	var post := CylinderMesh.new()
	post.top_radius = 0.06
	post.bottom_radius = 0.06
	post.height = 0.64
	post.radial_segments = 8
	_multi(post, posts, bamboo)
	var cane := CylinderMesh.new()
	cane.top_radius = 0.045
	cane.bottom_radius = 0.045
	cane.height = 0.52
	cane.radial_segments = 6
	_multi(cane, canes, bamboo)
	var tie := BoxMesh.new()
	tie.size = Vector3(0.15, 0.06, 0.15)
	_multi(tie, ties, flat_material(Color("2a2420")))
	# Cross canes: cylinders lying along x (front / back) and along z (left / right).
	for y in [0.2, 0.44]:
		for z in [0.5, h - 0.5]:
			_rail(w - 1, Vector3(w / 2, y, z), Vector3(0, 0, PI / 2), bamboo)
		for x in [0.5, w - 0.5]:
			_rail(h - 1, Vector3(x, y, h / 2), Vector3(PI / 2, 0, 0), bamboo)


func _rail(length: float, center: Vector3, rot: Vector3, mat: Material) -> void:
	var m := CylinderMesh.new()
	m.top_radius = 0.035
	m.bottom_radius = 0.035
	m.height = length
	m.radial_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = center
	mi.rotation = rot
	add_child(mi)


## A snow top over a roof slab or lid: a thin slab just above it, a little smaller, so the
## eaves keep a dark rim.
func _snow_top(size: Vector3, center: Vector3, rot := Vector3.ZERO) -> void:
	var m := SnowLayer.top_material()
	_snow_mats.append(m)
	var top := _box(size, center, m, rot)
	top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _rebuild_objects() -> void:
	_snow_mask.update(SnowLayer.mask_image(farm, Game.snow_rules))
	for child in _objects.get_children():
		child.queue_free()
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			var c := Vector2i(x, y)
			if not farm.can_farm(c):
				continue
			var key := PlaceholderArt.cell_key(farm, farm.cell(c))
			if key == "":
				continue
			var s := make_sprite(PlaceholderArt.tex(key))
			s.position = Vector3(x + 0.5, 0, y + 0.5)
			_objects.add_child(s)
