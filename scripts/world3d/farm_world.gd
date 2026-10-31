class_name FarmWorld
extends Node3D
## The farm in 3D: 1 unit = 1 cell, x = column, z = row, y up.
## Ground = the 2D FarmView (ground only) rendered into a texture; obstacles and crops
## stand up as camera-facing sprites; buildings are boxes.

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


func _box(size: Vector3, center: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	mesh.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = center
	add_child(mi)


## Boxes over the fixed cells laid out by FarmGrid.generate().
func _make_buildings() -> void:
	# House: cells x 2..6, z 1..3; walls, roof, door on the front (z = 4) face.
	_box(Vector3(5, 1.8, 3), Vector3(4.5, 0.9, 2.5), Color("d8c8a8"))
	_box(Vector3(5.4, 0.7, 3.4), Vector3(4.5, 2.15, 2.5), Color("a0522d"))
	_box(Vector3(0.8, 1.2, 0.1), Vector3(4.5, 0.6, 4.0), Color("4a2a14"))
	_box(Vector3(0.9, 0.6, 0.9), Vector3(8.5, 0.3, 3.5), Color("7a6a50"))     # shipping bin
	_box(Vector3(0.9, 0.9, 0.9), Vector3(10.5, 0.45, 3.5), Color("d9b45a"))   # seed stand
	_box(Vector3(1.1, 0.15, 1.1), Vector3(10.5, 1.0, 3.5), Color("c8452c"))
	# Fence: four low rails along the border cells.
	var w := float(FarmGrid.W)
	var h := float(FarmGrid.H)
	var fence := Color("b08a5a")
	_box(Vector3(w, 0.5, 0.15), Vector3(w / 2, 0.25, 0.5), fence)
	_box(Vector3(w, 0.5, 0.15), Vector3(w / 2, 0.25, h - 0.5), fence)
	_box(Vector3(0.15, 0.5, h), Vector3(0.5, 0.25, h / 2), fence)
	_box(Vector3(0.15, 0.5, h), Vector3(w - 0.5, 0.25, h / 2), fence)


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
