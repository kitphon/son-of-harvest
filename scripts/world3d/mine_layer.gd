class_name MineLayer
extends Node3D
## A mine floor in 3D, over the cave's MapWorld: rocks and big rocks stand up as sprites, soft
## spots and the open hole lie flat on the ground, finds left lying stand on their cells.
## Reads a MineFloor and rebuilds on its `changed`. Same units as FarmWorld (1 unit = 1 cell).

var floor_: MineFloor


func setup(f: MineFloor) -> void:
	floor_ = f
	floor_.changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	for c in floor_.soft:
		_flat("mine:soft", c, 0.012)
	if floor_.open:
		_flat("mine:hole", floor_.stairs, 0.014)
	for c in floor_.rocks:
		var s := FarmWorld.make_sprite(PlaceholderArt.tex("mine:" + str(floor_.rocks[c].kind)))
		s.position = Vector3(c.x + 0.5, 0, c.y + 0.5)
		add_child(s)
	for c in floor_.loose:
		var s := FarmWorld.make_sprite(PlaceholderArt.tex(PlaceholderArt.world_item_key(floor_.loose[c])))
		s.position = Vector3(c.x + 0.5, 0, c.y + 0.5)
		add_child(s)


## A picture laid on the ground over one cell, a hair above it so it never flickers.
func _flat(key: String, c: Vector2i, y: float) -> void:
	var quad := PlaneMesh.new()
	quad.size = Vector2(1, 1)
	var mat := FarmWorld.flat_material(Color(1, 1, 1, 0.99))
	mat.albedo_texture = PlaceholderArt.tex(key)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	mi.position = Vector3(c.x + 0.5, y, c.y + 0.5)
	add_child(mi)
