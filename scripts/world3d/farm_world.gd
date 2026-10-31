class_name FarmWorld
extends Node3D
## The farm in 3D: 1 unit = 1 cell, x = column, z = row, y up.
## Ground = the 2D FarmView (ground only) rendered into a texture; obstacles and crops
## stand up as camera-facing sprites; buildings are textured boxes.

const T := 16
const PX := 0.045              # world units per sprite pixel (a 24 px farmer ~ 1.1 cells tall)

var farm: FarmGrid
var _objects: Node3D


func setup(f: FarmGrid) -> void:
	farm = f
	_make_ground()
	_make_buildings()
	_objects = Node3D.new()
	add_child(_objects)
	farm.cells_changed.connect(_rebuild_objects)
	_rebuild_objects()


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

	var mat := flat_material(Color.WHITE)
	mat.albedo_texture = vp.get_texture()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
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
	var planks := surface_material("build:planks")
	var dark := surface_material("build:planks_dark")
	# Shipping bin (cell 8, 3): a dark crate with a lid and a band.
	_box(Vector3(0.9, 0.55, 0.8), Vector3(8.5, 0.275, 3.5), dark)
	_box(Vector3(1.0, 0.1, 0.9), Vector3(8.5, 0.6, 3.5), planks)
	_box(Vector3(0.92, 0.08, 0.82), Vector3(8.5, 0.35, 3.5), flat_material(Color("4a4440")))
	# Seed stand (cell 10, 3): counter, two posts, a striped awning, seed sacks on top.
	_box(Vector3(0.9, 0.6, 0.6), Vector3(10.5, 0.3, 3.65), planks)
	for x in [10.12, 10.88]:
		_box(Vector3(0.08, 1.3, 0.08), Vector3(x, 0.65, 3.3), dark)
	_box(Vector3(1.1, 0.05, 0.75), Vector3(10.5, 1.3, 3.55), surface_material("build:awning"),
		Vector3(deg_to_rad(18), 0, 0))
	var sacks := [Color("e8d8a8"), Color("c9a26b"), Color("b8c890")]
	for i in 3:
		_box(Vector3(0.22, 0.14, 0.22), Vector3(10.22 + i * 0.28, 0.67, 3.7), flat_material(sacks[i]))
	_make_fence(dark)


func _make_house() -> void:
	# Walls: cells x 2..6, z 1..3 (5 x 3), 1.8 high.
	_box(Vector3(5, 1.8, 3), Vector3(4.5, 0.9, 2.5), surface_material("build:wall"))
	# Gable under the roof, ridge along x.
	var gable := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(3, 1.3, 5)
	gable.mesh = prism
	gable.material_override = surface_material("build:wall")
	gable.position = Vector3(4.5, 1.8 + 0.65, 2.5)
	gable.rotation_degrees.y = 90
	add_child(gable)
	# Two roof slabs with a little overhang, from the ridge down past the walls.
	var roof := surface_material("build:roof")
	var slope := atan2(1.3, 1.5)
	var length := Vector2(1.5, 1.3).length() + 0.4
	for side in [1, -1]:
		var down := Vector3(0, -sin(slope), cos(slope) * side)
		var up := Vector3(0, cos(slope), sin(slope) * side)
		var center := Vector3(4.5, 3.1, 2.5) + down * (length / 2 - 0.05) + up * 0.06
		_box(Vector3(5.6, 0.12, length), center, roof, Vector3(slope * side, 0, 0))
	_box(Vector3(0.4, 1.0, 0.4), Vector3(6.0, 3.0, 1.9), surface_material("build:stone"))   # chimney
	# Door on the front face (z = 4), over the door cell (4, 3); windows either side and on +x.
	_picture("build:door", Vector2(0.8, 1.2), Vector3(4.5, 0.6, 4.005))
	_picture("build:window", Vector2(0.72, 0.6), Vector3(3.0, 1.1, 4.005))
	_picture("build:window", Vector2(0.72, 0.6), Vector3(6.0, 1.1, 4.005))
	_picture("build:window", Vector2(0.72, 0.6), Vector3(7.005, 1.1, 2.5), 90)


## Post and rail fence along the border cells: a post per cell (one MultiMesh), two rails a side.
func _make_fence(mat: Material) -> void:
	var w := float(FarmGrid.W)
	var h := float(FarmGrid.H)
	var spots: Array[Vector3] = []
	for x in FarmGrid.W:
		spots.append(Vector3(x + 0.5, 0.3, 0.5))
		spots.append(Vector3(x + 0.5, 0.3, h - 0.5))
	for z in range(1, FarmGrid.H - 1):
		spots.append(Vector3(0.5, 0.3, z + 0.5))
		spots.append(Vector3(w - 0.5, 0.3, z + 0.5))
	var post := BoxMesh.new()
	post.size = Vector3(0.14, 0.6, 0.14)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = post
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, Transform3D(Basis(), spots[i]))
	var posts := MultiMeshInstance3D.new()
	posts.multimesh = mm
	posts.material_override = mat
	add_child(posts)
	for y in [0.22, 0.46]:
		_box(Vector3(w - 1, 0.07, 0.05), Vector3(w / 2, y, 0.5), mat)
		_box(Vector3(w - 1, 0.07, 0.05), Vector3(w / 2, y, h - 0.5), mat)
		_box(Vector3(0.05, 0.07, h - 1), Vector3(0.5, y, h / 2), mat)
		_box(Vector3(0.05, 0.07, h - 1), Vector3(w - 0.5, y, h / 2), mat)


func _rebuild_objects() -> void:
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
