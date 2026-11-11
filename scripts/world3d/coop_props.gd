class_name CoopProps
extends RefCounted
## The chicken coop in 3D: the building on the farm (FarmGrid.COOP) and the furniture inside
## (data/maps/coop.json props). Built from the same placeholder surfaces as the farm
## buildings, in the same units (1 unit = 1 cell). The animals, eggs and feed are AnimalLayer.

const TIMBER := Color("2e221a")
const STRAW_COLOR := Color("d8bc78")
const ROPE_COLOR := Color("8a6a3a")


## A small coop of upright cedar boards on a charred-board skirting, under a thick thatched
## gable roof built as a mesh (Minka.gable) with a dark ridge bundle; a board sliding door on
## the front (+z) over FarmGrid.COOP_DOOR, a bamboo-barred window beside it and a hen hatch
## with a little ramp on the +x face.
static func coop(w: FarmWorld, built: Array = []) -> void:
	var r := Rect2(FarmGrid.coop_rect(built))
	var wing := "coop_wing" in built
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
	var sticks := [cx - 1.6, cx - 0.5, cx + 0.6, cx + 1.7]
	if wing:   # the longer ridge: two more pairs over the wing
		sticks.append_array([cx - 2.7, cx - 3.2])
	for x in sticks:   # crossed sticks holding the ridge down
		w._box(Vector3(0.05, 0.42, 0.05), ridge + Vector3(x - cx, 0.24, 0), timber, Vector3(0.6, 0, 0))
		w._box(Vector3(0.05, 0.42, 0.05), ridge + Vector3(x - cx, 0.24, 0), timber, Vector3(-0.6, 0, 0))
	# Board door on the door cell, with a dark frame; a step stone in front.
	var dx := FarmGrid.COOP_DOOR.x + 0.5
	w._box(Vector3(0.8, 1.0, 0.04), Vector3(dx, 0.5, front + 0.03), FarmWorld.surface_material("build:planks_dark"))
	w._box(Vector3(0.92, 0.07, 0.07), Vector3(dx, 1.03, front + 0.05), timber)
	w._box(Vector3(0.1, 0.05, 0.05), Vector3(dx + 0.26, 0.5, front + 0.07), FarmWorld.flat_material(Color("1e1c1c")))
	w._box(Vector3(0.5, 0.05, 0.28), Vector3(dx, 0.025, front + 0.3), FarmWorld.flat_material(Color("8a8680")))
	# A window with bamboo bars left of the door, another on the side.
	var windows := [Vector3(r.position.x + 1.0, 0.85, front + 0.01)]
	if wing:   # the wing has its own window and a bundle of straw leaning on its wall
		windows.append(Vector3(r.position.x + 2.6, 0.85, front + 0.01))
		for k in 3:
			w._box(Vector3(0.1, 0.7, 0.1), Vector3(r.position.x + 0.45 + k * 0.12, 0.35, front + 0.22), FarmWorld.flat_material(STRAW_COLOR), Vector3(0.0, 0.3 * k, 0.12 - 0.1 * k))
	for at in windows:
		w._box(Vector3(0.7, 0.4, 0.02), at, FarmWorld.flat_material(Color("1a1410")))
		for i in 5:
			w._box(Vector3(0.05, 0.4, 0.04), at + Vector3(-0.28 + i * 0.14, 0, 0.02), FarmWorld.flat_material(Color("9ab060")))
	# Hen hatch low on the +x face with a slatted ramp down to the ground.
	var hx := r.end.x - 0.1
	w._box(Vector3(0.03, 0.34, 0.32), Vector3(hx + 0.02, 0.3, mid_z), FarmWorld.flat_material(Color("1a1410")))
	w._box(Vector3(0.5, 0.03, 0.3), Vector3(hx + 0.24, 0.1, mid_z), FarmWorld.surface_material("build:planks"), Vector3(0, 0, -0.45))


## A coop prop by its kind (MapWorld calls this for the coop map's furniture): lit meshes made
## the way RoomProps makes the rooms' furniture (tapered blocks, lathe-turned straw and baskets),
## standing exactly where the old boxes stood, so the eggs, the feed and the incubator's egg that
## AnimalLayer lays on them still sit right (the nests' straw dips to 0.31, the trough's floor is 0.08).
static func prop(w: FarmWorld, p: Dictionary, mid: Vector3, r: Rect2) -> void:
	var parts := FarmProps.Parts.new()
	match str(p.kind):
		"feed_box": _feed_box(parts, mid, r)
		"nest": _nests(parts, mid, r)
		"incubator": _incubator(parts, mid)
		"feed_sack": _feed_sack(parts, mid)
		"hatch": _hatch(parts, mid, r)
	parts.commit(w)


## A long low trough of cedar boards along the back wall: a dark floor, two bevelled side planks
## with battens on the outside, end boards, corner posts and a rope round it (the feed in it is
## AnimalLayer's, resting on the floor at 0.08).
static func _feed_box(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var at := mid + Vector3(0, 0, -0.1)
	var length := r.size.x - 0.2
	var half := length / 2
	var planks := p.st("build:planks")
	var dark := p.st("build:planks_dark")
	var timber := p.st(TIMBER)
	RoomProps._cube(dark, at, Vector3(length, 0.08, 0.5))
	for z in [-0.22, 0.22]:
		RoomProps._cube(planks, at + Vector3(0, 0.04, z), Vector3(length - 0.12, 0.28, 0.06), 0.015)
	for x in [-1.0, 1.0]:
		RoomProps._cube(dark, at + Vector3(x * (half - 0.03), 0.0, 0), Vector3(0.06, 0.32, 0.5), 0.015)
		for z in [-0.215, 0.215]:
			RoomProps._cube(timber, at + Vector3(x * (half - 0.05), 0, z), Vector3(0.07, 0.36, 0.05), 0.012)
	for k in 3:   # battens up the outside
		var x := (k - 1) * (half - 0.4) * 0.9
		for z in [-0.255, 0.255]:
			RoomProps._cube(timber, at + Vector3(x, 0.05, z), Vector3(0.05, 0.22, 0.012))
	for z in [-0.262, 0.262]:   # a rope round the middle
		RoomProps._cube(p.st(ROPE_COLOR), at + Vector3(0, 0.15, z), Vector3(0.07, 0.04, 0.012))
	for z in [-0.22, 0.22]:   # a worn lighter lip along each top edge
		RoomProps._cube(p.st(Color("b08a58")), at + Vector3(0, 0.32, z), Vector3(length - 0.12, 0.012, 0.07))


## Straw nests in open board boxes against the left wall, one per cell: a floor on four legs, a
## back board and side boards, and a lathe-turned bowl of straw with a rolled rim (its middle
## dips to 0.31, where the egg sprite lies), a few loose stalks over the edge.
static func _nests(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var dark := p.st("build:planks_dark")
	var planks := p.st("build:planks")
	var timber := p.st(TIMBER)
	var straw := p.st(STRAW_COLOR)
	for i in int(r.size.y):
		var c := Vector3(mid.x - 0.1, 0, r.position.y + i + 0.5)
		RoomProps._cube(dark, c + Vector3(0, 0.2, 0), Vector3(0.6, 0.06, 0.8), 0.01)
		for x in [-0.25, 0.25]:
			for z in [-0.35, 0.35]:
				RoomProps._cube(timber, c + Vector3(x, 0, z), Vector3(0.06, 0.2, 0.06))
		RoomProps._cube(planks, c + Vector3(-0.27, 0.26, 0), Vector3(0.06, 0.34, 0.8), 0.012)
		for z in [-0.375, 0.375]:
			RoomProps._cube(planks, c + Vector3(0.0, 0.26, z), Vector3(0.6, 0.15, 0.05), 0.012)
		Shrine.lathe(straw, c + Vector3(0.02, 0.26, 0), [Vector2(0.0, 0.03), Vector2(0.27, 0.0), Vector2(0.32, 0.05),
			Vector2(0.31, 0.09), Vector2(0.26, 0.1), Vector2(0.2, 0.06), Vector2(0.0, 0.05)], 10)
		for k in 3:   # loose stalks over the rim and the floor
			var yaw := 0.9 + k * 1.7 + i
			var spot := c + Vector3(0.12 + 0.05 * k, 0.265, -0.3 + 0.28 * k)
			RoomProps._placed(straw, Transform3D(Basis(Vector3.UP, yaw), spot),
				func(t: SurfaceTool) -> void: RoomProps._cube(t, Vector3.ZERO, Vector3(0.22, 0.015, 0.02)))


## A woven basket on a low stand, straw in it (the incubator's egg lies at 0.48), a small warm
## lantern beside it on the stand.
static func _incubator(p: FarmProps.Parts, mid: Vector3) -> void:
	var base := mid + Vector3(0, 0, -0.1)
	var timber := p.st(TIMBER)
	for x in [-0.28, 0.28]:
		for z in [-0.23, 0.23]:
			RoomProps._cube(timber, base + Vector3(x, 0, z), Vector3(0.07, 0.17, 0.07))
	RoomProps._cube(p.st("build:planks_dark"), base + Vector3(0, 0.15, 0), Vector3(0.7, 0.05, 0.6), 0.012)
	var at := base + Vector3(-0.05, 0.2, 0)
	var weave := p.st(Color("b89455"))
	Shrine.lathe(weave, at, [Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.25, 0.06), Vector2(0.28, 0.16),
		Vector2(0.285, 0.25), Vector2(0.285, 0.3), Vector2(0.25, 0.3), Vector2(0.245, 0.27), Vector2(0.0, 0.26)], 12)
	for band in [[0.07, 0.13, 0.268], [0.2, 0.25, 0.292]]:
		Shrine.lathe(p.st(ROPE_COLOR), at, [Vector2(band[2], band[0]), Vector2(band[2] + 0.003, band[1])], 12)
	Shrine.lathe(p.st(STRAW_COLOR), at + Vector3(0, 0.26, 0), [Vector2(0.0, 0.0), Vector2(0.225, 0.0), Vector2(0.21, 0.012), Vector2(0.0, 0.01)], 12)
	var lamp := base + Vector3(0.28, 0.2, 0.02)
	RoomProps._cube(timber, lamp, Vector3(0.14, 0.03, 0.14), 0.008)
	RoomProps._cube(p.glow(RoomProps.LAMP), lamp + Vector3(0, 0.03, 0), Vector3(0.1, 0.14, 0.1))
	for x in [-0.055, 0.055]:
		for z in [-0.055, 0.055]:
			RoomProps._cube(timber, lamp + Vector3(x, 0.03, z), Vector3(0.015, 0.15, 0.015))
	Shrine.lathe(timber, lamp + Vector3(0, 0.18, 0), [Vector2(0.09, 0.0), Vector2(0.07, 0.03), Vector2(0.0, 0.07)], 4)


## A straw rice bag (tawara) of feed lying on its side: a barrel of rice straw with flat ends,
## three ropes round it, a pale cut end, a little spill of grain beside it.
static func _feed_sack(p: FarmProps.Parts, mid: Vector3) -> void:
	var at := mid + Vector3(0, 0.28, -0.375)
	var turn := Transform3D(Basis(Vector3.RIGHT, PI / 2), at)
	var barrel := [Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.25, 0.04), Vector2(0.27, 0.2), Vector2(0.28, 0.375),
		Vector2(0.27, 0.55), Vector2(0.25, 0.71), Vector2(0.2, 0.75), Vector2(0.0, 0.75)]
	RoomProps._placed(p.st(Color("c8a868")), turn, func(t: SurfaceTool) -> void: Shrine.lathe(t, Vector3.ZERO, barrel, 12))
	for y in [0.14, 0.375, 0.61]:
		var rad := 0.268 + 0.012 * (1.0 - absf(y - 0.375) / 0.375) + 0.01
		RoomProps._placed(p.st(Color("8a6a38")), turn, func(t: SurfaceTool) -> void:
			Shrine.lathe(t, Vector3.ZERO, [Vector2(rad, y - 0.025), Vector2(rad, y + 0.025)], 12))
	RoomProps._placed(p.st(Color("e0cc98")), turn, func(t: SurfaceTool) -> void:
		Shrine.lathe(t, Vector3.ZERO, [Vector2(0.0, 0.751), Vector2(0.17, 0.751), Vector2(0.0, 0.76)], 8))
	Shrine.lathe(p.st(Color("d8b060")), mid + Vector3(0.33, 0, 0.3), [Vector2(0.0, 0.0), Vector2(0.14, 0.0),
		Vector2(0.1, 0.05), Vector2(0.0, 0.09)], 8)


## The hen hatch in the right wall: a dark opening in a board frame with a lintel and sill, a
## small plank door standing a little open, and a slatted ramp down to the straw.
static func _hatch(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var at := Vector3(r.position.x + 0.42, 0, mid.z)
	var timber := p.st(TIMBER)
	RoomProps._cube(p.st(Color("1a1410")), at, Vector3(0.06, 0.48, 0.34))
	for z in [-0.23, 0.23]:
		RoomProps._cube(timber, at + Vector3(0, 0, z), Vector3(0.09, 0.52, 0.07), 0.01)
	RoomProps._cube(timber, at + Vector3(0, 0.48, 0), Vector3(0.1, 0.07, 0.6), 0.012)
	RoomProps._cube(p.st("build:planks"), at + Vector3(-0.03, 0, 0), Vector3(0.1, 0.04, 0.4), 0.01)
	var door := Transform3D(Basis(Vector3.UP, 0.5), at + Vector3(-0.06, 0.05, 0.19))
	RoomProps._placed(p.st("build:planks"), door, func(t: SurfaceTool) -> void:
		RoomProps._cube(t, Vector3(0, 0, -0.17), Vector3(0.035, 0.4, 0.34), 0.008))
	RoomProps._placed(timber, door, func(t: SurfaceTool) -> void:
		for y in [0.1, 0.32]:
			RoomProps._cube(t, Vector3(-0.02, y, -0.17), Vector3(0.012, 0.05, 0.3)))
	var ramp := Transform3D(Basis(Vector3.BACK, 0.35), at + Vector3(-0.3, 0.1, 0))
	RoomProps._placed(p.st("build:planks"), ramp, func(t: SurfaceTool) -> void:
		RoomProps._cube(t, Vector3(0, -0.015, 0), Vector3(0.5, 0.03, 0.3), 0.006))
	RoomProps._placed(timber, ramp, func(t: SurfaceTool) -> void:
		for x in [-0.18, -0.06, 0.06, 0.18]:
			RoomProps._cube(t, Vector3(x, 0.015, 0), Vector3(0.025, 0.02, 0.28)))
