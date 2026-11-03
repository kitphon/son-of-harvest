class_name CoopProps
extends RefCounted
## The chicken coop in 3D: the building on the farm (FarmGrid.COOP) and the furniture inside
## (data/maps/coop.json props). Built from the same placeholder surfaces as the farm
## buildings, in the same units (1 unit = 1 cell). The animals, eggs and feed are AnimalLayer.

const TIMBER := Color("2e221a")
const STRAW := Color("d8bc78")


## A small coop of upright cedar boards on a charred-board skirting, under a thick thatched
## gable roof built as a mesh (Minka.gable) with a dark ridge bundle; a board sliding door on
## the front (+z) over FarmGrid.COOP_DOOR, a bamboo-barred window beside it and a hen hatch
## with a little ramp on the +x face.
static func coop(w: FarmWorld) -> void:
	var r := Rect2(FarmGrid.COOP)
	var timber := FarmWorld.flat_material(TIMBER)
	var front := r.end.y - 0.15
	var back := r.position.y + 0.1
	var depth := front - back
	var mid_z := back + depth / 2
	var cx := r.get_center().x
	var wide := r.size.x - 0.2
	var wall := 1.45 + 0.35 * 0.75   # up to the soffit over the wall line (the roof below)
	w._box(Vector3(wide, 0.4, depth), Vector3(cx, 0.2, mid_z), FarmWorld.surface_material("build:board"))
	w._box(Vector3(wide, wall - 0.4, depth), Vector3(cx, 0.4 + (wall - 0.4) / 2, mid_z), FarmWorld.surface_material("build:sugi"))
	for x in [r.position.x + 0.1, cx - 1.0, cx + 1.0, r.end.x - 0.1]:
		w._box(Vector3(0.1, wall, 0.08), Vector3(x, wall / 2, front + 0.02), timber)
	for z in [back, mid_z, front]:
		w._box(Vector3(0.08, wall, 0.1), Vector3(r.end.x - 0.08, wall / 2, z), timber)
	w._box(Vector3(wide + 0.06, 0.07, 0.06), Vector3(cx, wall - 0.03, front + 0.03), timber)
	# The thatched gable roof (Minka.gable): eaves 0.35 past the long walls and 0.3 past the
	# gable ends, the soffit 1.45 high at the front eave (above the farmer at the door), rising
	# 0.75 a unit (about 37°, lower than the farmhouse's: a shed, not a home), 0.4 of straw thick.
	# The walls go up to meet the soffit, the gable ends are boards up to the roof.
	var overhang := 0.35
	var eave := Rect2(cx - wide / 2 - 0.3, back - overhang, wide + 0.6, depth + overhang * 2)
	var crest := Minka.gable(w, eave, 1.45, 0.75, 0.4, "build:thatch", "build:kaya_edge")
	var apex := 1.45 + eave.size.y / 2 * 0.75
	for x in [cx - wide / 2 - 0.002, cx + wide / 2 + 0.002]:
		Minka.gable_wall(w, x, back, front, wall, apex, "build:sugi", signf(x - cx))
	var ridge := Vector3(cx, crest, mid_z)
	w._box(Vector3(eave.size.x + 0.1, 0.2, 0.34), ridge + Vector3(0, 0.06, 0), FarmWorld.flat_material(Color("5a4a30")))
	for x in [cx - 1.6, cx - 0.5, cx + 0.6, cx + 1.7]:   # crossed sticks holding the ridge down
		w._box(Vector3(0.05, 0.42, 0.05), ridge + Vector3(x - cx, 0.24, 0), timber, Vector3(0.6, 0, 0))
		w._box(Vector3(0.05, 0.42, 0.05), ridge + Vector3(x - cx, 0.24, 0), timber, Vector3(-0.6, 0, 0))
	# Board door on the door cell, with a dark frame; a step stone in front.
	var dx := FarmGrid.COOP_DOOR.x + 0.5
	w._box(Vector3(0.8, 1.0, 0.04), Vector3(dx, 0.5, front + 0.03), FarmWorld.surface_material("build:planks_dark"))
	w._box(Vector3(0.92, 0.07, 0.07), Vector3(dx, 1.03, front + 0.05), timber)
	w._box(Vector3(0.1, 0.05, 0.05), Vector3(dx + 0.26, 0.5, front + 0.07), FarmWorld.flat_material(Color("1e1c1c")))
	w._box(Vector3(0.5, 0.05, 0.28), Vector3(dx, 0.025, front + 0.3), FarmWorld.flat_material(Color("8a8680")))
	# A window with bamboo bars left of the door, another on the side.
	for at in [Vector3(r.position.x + 1.0, 0.85, front + 0.01)]:
		w._box(Vector3(0.7, 0.4, 0.02), at, FarmWorld.flat_material(Color("1a1410")))
		for i in 5:
			w._box(Vector3(0.05, 0.4, 0.04), at + Vector3(-0.28 + i * 0.14, 0, 0.02), FarmWorld.flat_material(Color("9ab060")))
	# Hen hatch low on the +x face with a slatted ramp down to the ground.
	var hx := r.end.x - 0.1
	w._box(Vector3(0.03, 0.34, 0.32), Vector3(hx + 0.02, 0.3, mid_z), FarmWorld.flat_material(Color("1a1410")))
	w._box(Vector3(0.5, 0.03, 0.3), Vector3(hx + 0.24, 0.1, mid_z), FarmWorld.surface_material("build:planks"), Vector3(0, 0, -0.45))


## A coop prop by its kind (MapWorld calls this for the coop map's furniture).
static func prop(w: FarmWorld, p: Dictionary, mid: Vector3, r: Rect2) -> void:
	var timber := FarmWorld.flat_material(TIMBER)
	match str(p.kind):
		"feed_box":
			# A long low trough of planks along the back wall (the feed in it is AnimalLayer's).
			var at := mid + Vector3(0, 0, -0.1)
			w._box(Vector3(r.size.x - 0.2, 0.08, 0.5), at + Vector3(0, 0.04, 0), timber)
			for z in [-0.22, 0.22]:
				w._box(Vector3(r.size.x - 0.2, 0.3, 0.06), at + Vector3(0, 0.19, z), FarmWorld.surface_material("build:planks"))
			for x in [-1, 1]:
				w._box(Vector3(0.06, 0.3, 0.5), at + Vector3(x * (r.size.x / 2 - 0.13), 0.19, 0), FarmWorld.surface_material("build:planks"))
		"nest":
			# Straw nests in open board boxes against the left wall, one per cell.
			for i in int(r.size.y):
				var c := Vector3(mid.x - 0.1, 0, r.position.y + i + 0.5)
				w._box(Vector3(0.6, 0.06, 0.8), c + Vector3(0, 0.25, 0), FarmWorld.surface_material("build:planks_dark"))
				w._box(Vector3(0.06, 0.24, 0.8), c + Vector3(-0.3, 0.4, 0), FarmWorld.surface_material("build:planks_dark"))
				w._box(Vector3(0.6, 0.12, 0.06), c + Vector3(0, 0.34, 0.38), FarmWorld.surface_material("build:planks_dark"))
				w._box(Vector3(0.5, 0.06, 0.68), c + Vector3(0, 0.31, 0), FarmWorld.flat_material(STRAW))
				for z in [-0.35, 0.35]:
					w._box(Vector3(0.06, 0.28, 0.06), c + Vector3(0.27, 0.14, z), timber)
		"incubator":
			# A lidded straw basket on a low stand, a small warm lantern beside it.
			w._box(Vector3(0.7, 0.2, 0.6), mid + Vector3(0, 0.1, -0.1), timber)
			var basket := CylinderMesh.new()
			basket.top_radius = 0.3
			basket.bottom_radius = 0.24
			basket.height = 0.3
			basket.radial_segments = 12
			var mi := MeshInstance3D.new()
			mi.mesh = basket
			mi.material_override = FarmWorld.surface_material("build:thatch")
			mi.position = mid + Vector3(-0.05, 0.35, -0.1)
			w.add_child(mi)
			w._box(Vector3(0.12, 0.2, 0.12), mid + Vector3(0.3, 0.3, 0.12), FarmWorld.flat_material(Color("ffd890")))
			w._box(Vector3(0.16, 0.04, 0.16), mid + Vector3(0.3, 0.42, 0.12), timber)
		"feed_sack":
			# A straw rice bag (tawara) of feed lying on its side, tied with three ropes.
			var bale := CylinderMesh.new()
			bale.top_radius = 0.26
			bale.bottom_radius = 0.26
			bale.height = 0.75
			bale.radial_segments = 12
			var mb := MeshInstance3D.new()
			mb.mesh = bale
			mb.material_override = FarmWorld.surface_material("build:thatch")
			mb.position = mid + Vector3(0, 0.26, 0)
			mb.rotation_degrees.x = 90
			w.add_child(mb)
			for z in [-0.25, 0.0, 0.25]:
				w._box(Vector3(0.56, 0.56, 0.04), mid + Vector3(0, 0.26, z), FarmWorld.flat_material(Color("8a6a38")))
			w._box(Vector3(0.4, 0.4, 0.02), mid + Vector3(0, 0.26, 0.39), FarmWorld.flat_material(Color("c8a868")))
		"hatch":
			# The hen hatch in the right wall: a little board door in a dark frame.
			var at := Vector3(r.position.x + 0.42, 0, mid.z)
			w._box(Vector3(0.08, 0.5, 0.5), at + Vector3(0, 0.25, 0), timber)
			w._box(Vector3(0.04, 0.4, 0.38), at + Vector3(-0.05, 0.22, 0), FarmWorld.surface_material("build:planks"))
			w._box(Vector3(0.5, 0.03, 0.34), at + Vector3(-0.3, 0.1, 0), FarmWorld.surface_material("build:planks"), Vector3(0, 0, 0.35))
