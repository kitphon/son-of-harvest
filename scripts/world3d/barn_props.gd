class_name BarnProps
extends RefCounted
## The barn in 3D: the building on the farm (FarmGrid.BARN) and the furniture inside
## (data/maps/barn.json props). Same placeholder surfaces and units as the coop (CoopProps);
## the animals and the fodder in the trough are AnimalLayer's.

const TIMBER := Color("2e221a")
const HAY := Color("c8b060")


## A cow shed in the satoyama way: dark cedar boards on a plastered band and a stone-grey
## skirting, a tiled (kawara) gable roof built as a mesh (Minka.gable) with real tile rolls, a wide two-leaf board door on the front (+z) over
## FarmGrid.BARN_DOOR, slatted windows and a hay-loft hatch under the gable on the +x face.
static func barn(w: FarmWorld) -> void:
	var r := Rect2(FarmGrid.BARN)
	var timber := FarmWorld.flat_material(TIMBER)
	var front := r.end.y - 0.12
	var back := r.position.y + 0.08
	var depth := front - back
	var mid_z := back + depth / 2
	var cx := r.get_center().x
	var wide := r.size.x - 0.16
	var wall := 1.45 + 0.4 * 0.55   # up to the soffit over the wall line (the roof below)
	w._box(Vector3(wide, 0.3, depth), Vector3(cx, 0.15, mid_z), FarmWorld.flat_material(Color("8a8680")))
	w._box(Vector3(wide - 0.02, 0.35, depth - 0.02), Vector3(cx, 0.3 + 0.175, mid_z), FarmWorld.surface_material("build:plaster"))
	w._box(Vector3(wide, wall - 0.65, depth), Vector3(cx, 0.65 + (wall - 0.65) / 2, mid_z), FarmWorld.surface_material("build:sugi"))
	for x in [r.position.x + 0.08, cx - 1.4, cx + 1.4, r.end.x - 0.08]:
		w._box(Vector3(0.12, wall, 0.1), Vector3(x, wall / 2, front + 0.02), timber)
	for z in [back, mid_z, front]:
		w._box(Vector3(0.1, wall, 0.12), Vector3(r.end.x - 0.06, wall / 2, z), timber)
	w._box(Vector3(wide + 0.06, 0.08, 0.08), Vector3(cx, wall - 0.04, front + 0.03), timber)
	w._box(Vector3(wide + 0.06, 0.06, 0.06), Vector3(cx, 0.65, front + 0.03), timber)
	# The tiled gable roof (Minka.gable with kawara rolls every quarter unit, as the tile
	# texture's rows): eaves 0.4 past the long walls and 0.3 past the gable ends, the soffit
	# 1.45 high at the front eave, rising 0.55 a unit (about 29°, a tile roof's gentle slope).
	# The gable ends are boards up to the roof; on the ridge a stack of ridge tiles with a
	# raised end tile (onigawara) at each end.
	var overhang := 0.4
	var eave := Rect2(cx - wide / 2 - 0.3, back - overhang, wide + 0.6, depth + overhang * 2)
	var crest := Minka.gable(w, eave, 1.45, 0.55, 0.15, "build:kawara", "build:kawara_edge", 0.25)
	var apex := 1.45 + eave.size.y / 2 * 0.55
	for x in [cx - wide / 2 - 0.002, cx + wide / 2 + 0.002]:
		Minka.gable_wall(w, x, back, front, wall, apex, "build:sugi", signf(x - cx))
	var ridge := Vector3(cx, crest - 0.04, mid_z)
	var dark := FarmWorld.flat_material(Color("3a3a40"))
	var light := FarmWorld.flat_material(Color("5a6470"))
	w._box(Vector3(eave.size.x - 0.1, 0.16, 0.36), ridge + Vector3(0, 0.08, 0), dark)
	w._box(Vector3(eave.size.x - 0.14, 0.04, 0.38), ridge + Vector3(0, 0.12, 0), light)
	w._box(Vector3(eave.size.x - 0.1, 0.1, 0.22), ridge + Vector3(0, 0.21, 0), dark)
	for end in [-1.0, 1.0]:
		var at := ridge + Vector3(end * (eave.size.x / 2 - 0.08), 0, 0)
		w._box(Vector3(0.14, 0.36, 0.42), at + Vector3(0, 0.18, 0), dark)
		w._box(Vector3(0.16, 0.1, 0.3), at + Vector3(end * 0.03, 0.4, 0), dark, Vector3(0, 0, -0.35 * end))
	# The hay-loft hatch high on the +x gable, a little door of planks.
	w._box(Vector3(0.03, 0.4, 0.5), Vector3(r.end.x - 0.04, wall + 0.3, mid_z), FarmWorld.surface_material("build:planks_dark"))
	# Two board door leaves over the door cell (one slid a little open), a dark gap, a step stone.
	var dx := FarmGrid.BARN_DOOR.x + 0.5
	w._box(Vector3(1.3, 1.25, 0.02), Vector3(dx, 0.63, front + 0.02), FarmWorld.flat_material(Color("1a1410")))
	w._box(Vector3(0.6, 1.25, 0.05), Vector3(dx - 0.36, 0.63, front + 0.05), FarmWorld.surface_material("build:planks_dark"))
	w._box(Vector3(0.6, 1.25, 0.05), Vector3(dx + 0.52, 0.63, front + 0.08), FarmWorld.surface_material("build:planks_dark"))
	for x in [dx - 0.36, dx + 0.52]:
		w._box(Vector3(0.5, 0.06, 0.03), Vector3(x, 0.4, front + 0.11), timber)
		w._box(Vector3(0.5, 0.06, 0.03), Vector3(x, 0.9, front + 0.11), timber)
	w._box(Vector3(1.6, 0.08, 0.08), Vector3(dx + 0.1, 1.3, front + 0.08), timber)   # door rail
	w._box(Vector3(0.9, 0.05, 0.3), Vector3(dx, 0.025, front + 0.32), FarmWorld.flat_material(Color("8a8680")))
	# Slatted windows either side of the door.
	for x in [r.position.x + 0.8, r.end.x - 0.8]:
		var at := Vector3(x, 1.15, front + 0.01)
		w._box(Vector3(0.7, 0.36, 0.02), at, FarmWorld.flat_material(Color("1a1410")))
		for i in 4:
			w._box(Vector3(0.06, 0.36, 0.04), at + Vector3(-0.24 + i * 0.16, 0, 0.02), FarmWorld.surface_material("build:planks"))


## A barn prop by its kind (MapWorld calls this for the barn map's furniture).
static func prop(w: FarmWorld, p: Dictionary, mid: Vector3, r: Rect2) -> void:
	var timber := FarmWorld.flat_material(TIMBER)
	match str(p.kind):
		"fodder_box":
			# A long plank trough along the back wall (the hay in it is AnimalLayer's).
			var at := mid + Vector3(0, 0, 0.05)
			w._box(Vector3(r.size.x - 0.1, 0.1, 0.6), at + Vector3(0, 0.05, 0), timber)
			for z in [-0.27, 0.27]:
				w._box(Vector3(r.size.x - 0.1, 0.42, 0.06), at + Vector3(0, 0.25, z), FarmWorld.surface_material("build:planks"))
			for x in [-1, 1]:
				w._box(Vector3(0.06, 0.42, 0.6), at + Vector3(x * (r.size.x / 2 - 0.08), 0.25, 0), FarmWorld.surface_material("build:planks"))
		"stalls":
			# A post and two rails on each blocking cell, between the straw stalls.
			for b in p.get("blocks", []):
				var c := Vector3(r.position.x + b[0] + 0.5, 0, r.position.y + b[1] + 0.5)
				for z in [-0.42, 0.42]:
					w._box(Vector3(0.1, 0.9, 0.1), c + Vector3(0, 0.45, z), timber)
				for y in [0.4, 0.8]:
					w._box(Vector3(0.06, 0.08, 0.95), c + Vector3(0, y, 0), FarmWorld.surface_material("build:planks"))
		"hay":
			# Bundles of hay fodder stacked two high, tied with rope.
			var hay := FarmWorld.flat_material(HAY)
			var rope := FarmWorld.flat_material(Color("8a6a38"))
			for k in int(r.size.x) * 2:
				var at := Vector3(r.position.x + 0.5 * k + 0.25, 0, mid.z)
				w._box(Vector3(0.46, 0.34, 0.7), at + Vector3(0, 0.17, 0), hay)
				w._box(Vector3(0.47, 0.35, 0.05), at + Vector3(0, 0.17, 0.15), rope)
				if k % 3 != 2:
					w._box(Vector3(0.46, 0.32, 0.66), at + Vector3(0.05, 0.51, -0.02), hay)
		"barn_gate":
			# The wide gate in the right wall: two board leaves under a beam, a bar across.
			var at := Vector3(r.position.x + 0.42, 0, mid.z)
			w._box(Vector3(0.1, 1.2, 1.0), at + Vector3(0, 0.6, 0), FarmWorld.flat_material(Color("1a1410")))
			w._box(Vector3(0.05, 1.1, 0.46), at + Vector3(-0.06, 0.56, -0.24), FarmWorld.surface_material("build:planks"))
			w._box(Vector3(0.05, 1.1, 0.46), at + Vector3(-0.06, 0.56, 0.24), FarmWorld.surface_material("build:planks"))
			w._box(Vector3(0.06, 0.08, 1.0), at + Vector3(-0.1, 0.6, 0), timber)
