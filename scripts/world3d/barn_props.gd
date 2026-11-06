class_name BarnProps
extends RefCounted
## The barn in 3D: the building on the farm (FarmGrid.BARN) and the furniture inside
## (data/maps/barn.json props). Same placeholder surfaces and units as the coop (CoopProps);
## the animals and the fodder in the trough are AnimalLayer's.

const TIMBER := Color("2e221a")


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
	# The gable ends are boards up to the roof; on the ridge a stack of ridge tiles curving up
	# to a raised end tile (onigawara) at each end (Minka.ridge).
	var overhang := 0.4
	var eave := Rect2(cx - wide / 2 - 0.3, back - overhang, wide + 0.6, depth + overhang * 2)
	var crest := Minka.gable(w, eave, 1.45, 0.55, 0.15, "build:kawara", "build:kawara_edge", 0.25)
	var apex := 1.45 + eave.size.y / 2 * 0.55
	for x in [cx - wide / 2 - 0.002, cx + wide / 2 + 0.002]:
		Minka.gable_wall(w, x, back, front, wall, apex, "build:sugi", signf(x - cx))
	Minka.ridge(w, eave.position.x + 0.05, eave.end.x - 0.05, crest - 0.04, mid_z)
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


## A barn prop by its kind (MapWorld calls this for the barn map's furniture): lit meshes made
## the way RoomProps makes the rooms' furniture, standing where the old boxes stood (the hay in
## the trough is AnimalLayer's, resting at 0.22).
static func prop(w: FarmWorld, p: Dictionary, mid: Vector3, r: Rect2) -> void:
	var parts := FarmProps.Parts.new()
	match str(p.kind):
		"fodder_box": _fodder_box(parts, mid, r)
		"stalls": _stalls(parts, p, r)
		"hay": _hay(parts, mid, r)
		"barn_gate": _gate(parts, mid, r)
	parts.commit(w)


## A long plank trough along the back wall: a dark floor on two runners, bevelled side planks
## with a lighter worn lip, a post every two units, end boards, and above it against the wall a
## rack of upright slats between two rails where the fodder is pulled from.
static func _fodder_box(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var at := mid + Vector3(0, 0, 0.05)
	var length := r.size.x - 0.1
	var half := length / 2
	var planks := p.st("build:planks")
	var dark := p.st("build:planks_dark")
	var timber := p.st(TIMBER)
	RoomProps._cube(dark, at, Vector3(length, 0.1, 0.6))
	for z in [-0.27, 0.27]:
		RoomProps._cube(planks, at + Vector3(0, 0.05, z), Vector3(length - 0.12, 0.4, 0.06), 0.02)
		RoomProps._cube(p.st(Color("b08a58")), at + Vector3(0, 0.45, z), Vector3(length - 0.12, 0.012, 0.09))
	for x in [-1.0, 1.0]:
		RoomProps._cube(dark, at + Vector3(x * (half - 0.03), 0.0, 0), Vector3(0.06, 0.45, 0.6), 0.015)
	var posts := int(round(length / 2.0))
	for k in posts + 1:
		var x := -half + 0.08 + k * (length - 0.16) / posts
		for z in [-0.295, 0.295]:
			RoomProps._cube(timber, at + Vector3(x, 0, z), Vector3(0.1, 0.5, 0.06), 0.015)
	# The slatted rack on the back wall (its face is at z 1.0).
	var rack_z := r.position.y + 0.1
	var x0 := r.position.x + 0.15
	var x1 := r.end.x - 0.15
	for y in [0.62, 0.98]:
		RoomProps._cube(timber, Vector3((x0 + x1) / 2, y, rack_z), Vector3(x1 - x0, 0.06, 0.07), 0.01)
	var slats := int((x1 - x0) / 0.28)
	for k in slats + 1:
		RoomProps._cube(planks, Vector3(x0 + k * (x1 - x0) / slats, 0.62, rack_z), Vector3(0.05, 0.42, 0.045), 0.01)


## A post and two rails on each blocking cell, between the straw stalls: round-capped posts
## on a sill beam, bevelled rails, and an iron tether ring on the front post.
static func _stalls(p: FarmProps.Parts, prop_data: Dictionary, r: Rect2) -> void:
	var timber := p.st(TIMBER)
	var planks := p.st("build:planks")
	var iron := p.st(RoomProps.IRON)
	for b in prop_data.get("blocks", []):
		var c := Vector3(r.position.x + b[0] + 0.5, 0, r.position.y + b[1] + 0.5)
		RoomProps._cube(p.st("build:planks_dark"), c, Vector3(0.1, 0.08, 0.96), 0.01)
		for z in [-0.42, 0.42]:
			RoomProps._cube(timber, c + Vector3(0, 0.08, z), Vector3(0.11, 0.84, 0.11), 0.02)
			RoomProps._cube(p.st(Color("4a3a2a")), c + Vector3(0, 0.92, z), Vector3(0.14, 0.04, 0.14), 0.015)
		for y in [0.35, 0.72]:
			RoomProps._cube(planks, c + Vector3(0, y, 0), Vector3(0.07, 0.11, 0.84), 0.015)
		RoomProps._cube(iron, c + Vector3(0.062, 0.55, 0.42), Vector3(0.02, 0.07, 0.07))   # the tether ring
		RoomProps._cube(iron, c + Vector3(0.062, 0.6, 0.42), Vector3(0.02, 0.025, 0.045))


## Bundles of hay fodder stacked two high, each three tapered blocks (a bulging belly) bound with a
## rope band and bristling with loose stalks at the front; a pitchfork leans on the stack.
## Lit and textured with grass strands (a flat colour read as plain yellow lumps).
static func _hay(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	for k in int(r.size.x) * 2:
		var at := Vector3(r.position.x + 0.5 * k + 0.25, 0, mid.z)
		_bundle(p, at, 0.0, 0.46, 0.7)
		if k % 3 != 2:
			_bundle(p, at + Vector3(-0.05, 0, -0.02), 0.34, 0.46, 0.66)
	var tines := p.st(RoomProps.IRON)
	var lean := Transform3D(Basis(Vector3.BACK, -0.28), Vector3(r.end.x - 0.36, 0.0, mid.z + 0.3))
	RoomProps._placed(p.st("build:planks"), lean, func(t: SurfaceTool) -> void:
		RoomProps._cube(t, Vector3.ZERO, Vector3(0.04, 1.0, 0.04), 0.008))
	RoomProps._placed(tines, lean, func(t: SurfaceTool) -> void:
		RoomProps._cube(t, Vector3(0, 0.95, 0), Vector3(0.05, 0.03, 0.14))
		for z in [-0.06, 0.0, 0.06]:
			RoomProps._cube(t, Vector3(0, 0.98, z), Vector3(0.015, 0.14, 0.015)))


## One bundle of hay: its bottom at `y`, `w` wide in x, `d` deep in z, 0.34 high with a belly
## wider than its ends, tied with a rope round the middle.
static func _bundle(p: FarmProps.Parts, at: Vector3, y: float, w: float, d: float) -> void:
	var hay := p.st("build:hay")
	var lo := RoomProps._rect(at, w - 0.04, d - 0.04)
	var belly := RoomProps._rect(at, w, d)
	var top := RoomProps._rect(at, w - 0.08, d - 0.08)
	FarmProps.block(hay, lo, y, belly, y + 0.12)
	FarmProps.block(hay, belly, y + 0.12, belly, y + 0.22)
	FarmProps.block(hay, belly, y + 0.22, top, y + 0.34)
	var band := RoomProps._rect(at + Vector3(0, 0, 0.15), w + 0.012, 0.05)
	FarmProps.block(p.st("build:planks_dark"), band, y + 0.01, band, y + 0.33)
	for x in [-0.1, 0.12]:   # stalks sticking out of the front
		RoomProps._cube(hay, at + Vector3(x, y + 0.12 + x * 0.3, d / 2 - 0.02), Vector3(0.12, 0.02, 0.07))


## The wide gate in the right wall: a dark opening between two posts under a beam, two plank
## leaves braced with battens and a diagonal each, iron straps, and a bar across.
static func _gate(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var at := Vector3(r.position.x + 0.42, 0, mid.z)
	var timber := p.st(TIMBER)
	var planks := p.st("build:planks")
	var iron := p.st(RoomProps.IRON)
	RoomProps._cube(p.st(Color("1a1410")), at, Vector3(0.08, 1.2, 1.0))
	for z in [-0.52, 0.52]:
		RoomProps._cube(timber, at + Vector3(0, 0, z), Vector3(0.12, 1.3, 0.1), 0.015)
	RoomProps._cube(timber, at + Vector3(0, 1.22, 0), Vector3(0.12, 0.1, 1.14), 0.015)
	for s in [-1.0, 1.0]:
		var leaf := at + Vector3(-0.06, 0.01, s * 0.24)
		RoomProps._cube(planks, leaf, Vector3(0.05, 1.1, 0.46), 0.01)
		for y in [0.1, 0.9]:
			RoomProps._cube(timber, leaf + Vector3(-0.04, y, 0), Vector3(0.03, 0.08, 0.44))
		RoomProps._placed(timber, Transform3D(Basis(Vector3.RIGHT, -s * 1.1), leaf + Vector3(-0.04, 0.55, 0)),
			func(t: SurfaceTool) -> void: RoomProps._cube(t, Vector3(0, -0.04, 0), Vector3(0.03, 0.08, 0.9)))
		for y in [0.3, 0.8]:
			RoomProps._cube(iron, leaf + Vector3(-0.03, y, -s * 0.12), Vector3(0.015, 0.05, 0.22))
	RoomProps._cube(timber, at + Vector3(-0.1, 0.56, 0), Vector3(0.06, 0.08, 1.0), 0.012)
	for z in [-0.4, 0.4]:
		RoomProps._cube(iron, at + Vector3(-0.135, 0.54, z), Vector3(0.012, 0.12, 0.08))
