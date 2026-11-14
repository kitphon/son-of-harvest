class_name TempleProps
extends RefCounted
## The village's Arashiyama-style pieces (data/maps/town.json, since 2026-11-14), built from
## FarmProps.block parts in lit materials: the temple's earthen wall with its tiled coping
## (`tsuiji`), the roofed gate on the main street (`temple_gate`), the little station's
## platform under its canopy (`station`) and the line running east from it (`rails`). Our own
## shapes, read from no other game; the proportions are picked by eye at the medium lens.
## Same units as the farm: 1 unit = 1 cell. Snow tops only where snow lies (map_has_snow).

const KINDS: Array[String] = ["tsuiji", "temple_gate", "station", "rails"]

const OCHRE := Color("d2b06a")     # the wall's earthen plaster
const LINE := Color("efe8d8")      # the white bands along it (suji)
const BASE := Color("8a8680")      # the stone footing
const TILE_CAP := Color("4c5058")  # the ridge tiles
const PILLAR := Color("5a3a26")    # dark-stained timber
const STEEL := Color("6e6e72")
const BALLAST := Color("8a857a")
const SLEEPER := Color("4a3626")


static func prop(w: FarmWorld, p: Dictionary, r: Rect2, snow: bool) -> void:
	match str(p.kind):
		"tsuiji": tsuiji(w, r, snow)
		"temple_gate": gate(w, r, snow)
		"station": station(w, r, snow)
		"rails": rails(w, r)


## An earthen wall (tsuiji-bei) along the long side of `r`, in the middle of its cells: a stone
## footing, ochre plaster with five white bands on both faces, a coping of kawara tiles sloping
## both ways from a dark ridge.
static func tsuiji(w: FarmWorld, r: Rect2, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var along_x := r.size.x >= r.size.y
	var mid := r.get_center()
	# (along from, along to, across from, across to) -> a ground rectangle
	var rc := func(a0: float, a1: float, b0: float, b1: float) -> Rect2:
		return Rect2(a0, mid.y + b0, a1 - a0, b1 - b0) if along_x else Rect2(mid.x + b0, a0, b1 - b0, a1 - a0)
	var a0: float = r.position.x if along_x else r.position.y
	var a1: float = r.end.x if along_x else r.end.y
	FarmProps.block(p.st(BASE), rc.call(a0, a1, -0.2, 0.2), 0.0, rc.call(a0, a1, -0.19, 0.19), 0.18)
	FarmProps.block(p.st(OCHRE), rc.call(a0, a1, -0.16, 0.16), 0.18, rc.call(a0, a1, -0.15, 0.15), 1.22)
	for i in 5:
		var y := 0.72 + i * 0.1
		for side in [-1.0, 1.0]:
			var b: float = 0.15 * side
			var lo: Rect2 = rc.call(a0 + 0.02, a1 - 0.02, minf(b, b + 0.012 * side), maxf(b, b + 0.012 * side))
			FarmProps.block(p.st(LINE), lo, y, lo, y + 0.03)
	FarmProps.block(p.st("build:kawara"), rc.call(a0 - 0.02, a1 + 0.02, -0.3, 0.3), 1.22, rc.call(a0 - 0.02, a1 + 0.02, -0.05, 0.05), 1.42)
	FarmProps.block(p.st(TILE_CAP), rc.call(a0 - 0.02, a1 + 0.02, -0.06, 0.06), 1.4, rc.call(a0 - 0.02, a1 + 0.02, -0.05, 0.05), 1.5)
	if snow:
		FarmProps.block(p.st(FarmProps.Parts.SNOW), rc.call(a0, a1, -0.27, 0.27), 1.27, rc.call(a0, a1, -0.04, 0.04), 1.52)
	p.commit(w)


## The temple's gate on a wall running along z (its passage the cells of `r`, open east-west):
## four dark pillars on the passage's ends, tie beams and a plaque over the opening, a stone
## sill, and a kawara roof with its ridge along the wall, its eaves well past the pillars.
static func gate(w: FarmWorld, r: Rect2, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var cx := r.get_center().x
	var z0 := r.position.y
	var z1 := r.end.y
	var wood := p.st(PILLAR)
	for x in [cx - 0.32, cx + 0.32]:
		for z in [z0, z1]:
			FarmProps.block(wood, Rect2(x - 0.09, z - 0.09, 0.18, 0.18), 0.0, Rect2(x - 0.08, z - 0.08, 0.16, 0.16), 2.02)
		FarmProps.block(wood, Rect2(x - 0.07, z0 - 0.1, 0.14, z1 - z0 + 0.2), 1.66, Rect2(x - 0.07, z0 - 0.1, 0.14, z1 - z0 + 0.2), 1.8)
		FarmProps.block(wood, Rect2(x - 0.08, z0 - 0.2, 0.16, z1 - z0 + 0.4), 1.9, Rect2(x - 0.08, z0 - 0.2, 0.16, z1 - z0 + 0.4), 2.02)
	for z in [z0, z1]:
		FarmProps.block(wood, Rect2(cx - 0.45, z - 0.07, 0.9, 0.14), 1.9, Rect2(cx - 0.45, z - 0.07, 0.9, 0.14), 2.02)
	# The plaque on the street (east) face, over the opening.
	var mz := (z0 + z1) / 2.0
	FarmProps.block(p.st(Color("2a2420")), Rect2(cx + 0.39, mz - 0.32, 0.03, 0.64), 1.66, Rect2(cx + 0.39, mz - 0.32, 0.03, 0.64), 1.9)
	FarmProps.block(p.st(Color("c8a050")), Rect2(cx + 0.42, mz - 0.26, 0.01, 0.52), 1.7, Rect2(cx + 0.42, mz - 0.26, 0.01, 0.52), 1.86)
	FarmProps.block(p.st(BASE), Rect2(cx - 0.5, z0, 1.0, z1 - z0), 0.0, Rect2(cx - 0.48, z0, 0.96, z1 - z0), 0.05)
	# The roof: a gable along z, a dark board soffit under its eaves.
	var e0 := z0 - 0.75
	var e1 := z1 + 0.75
	FarmProps.block(p.st("build:planks_dark"), Rect2(cx - 0.86, e0, 1.72, e1 - e0), 2.02, Rect2(cx - 0.86, e0, 1.72, e1 - e0), 2.08)
	FarmProps.block(p.st("build:kawara"), Rect2(cx - 0.9, e0, 1.8, e1 - e0), 2.08, Rect2(cx - 0.05, e0, 0.1, e1 - e0), 2.72)
	FarmProps.block(p.st(TILE_CAP), Rect2(cx - 0.08, e0 - 0.04, 0.16, e1 - e0 + 0.08), 2.68, Rect2(cx - 0.06, e0 - 0.02, 0.12, e1 - e0 + 0.04), 2.84)
	for z in [e0 - 0.06, e1 + 0.06]:   # the ridge's end tiles, standing up a little
		FarmProps.block(p.st(TILE_CAP), Rect2(cx - 0.1, z - 0.05, 0.2, 0.1), 2.66, Rect2(cx - 0.08, z - 0.04, 0.16, 0.08), 2.98)
	if snow:
		FarmProps.block(p.st(FarmProps.Parts.SNOW), Rect2(cx - 0.84, e0 + 0.03, 1.68, e1 - e0 - 0.06), 2.13, Rect2(cx - 0.04, e0 + 0.03, 0.08, e1 - e0 - 0.06), 2.76)
	p.commit(w)


## The little station over `r` (x along the line): a stone platform with a pale edge on the
## line's side (+z), a canopy of a shallow kawara gable on a row of posts, a ticket booth at
## the west end, a bench and the name board.
static func station(w: FarmWorld, r: Rect2, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var x0 := r.position.x + 0.05
	var x1 := r.end.x - 0.05
	var z0 := r.position.y + 0.1
	var z1 := r.end.y
	FarmProps.block(p.st(BASE), Rect2(x0, z0, x1 - x0, z1 - z0), 0.0, Rect2(x0, z0, x1 - x0, z1 - z0), 0.3)
	FarmProps.block(p.st(Color("d8d2c0")), Rect2(x0, z1 - 0.12, x1 - x0, 0.12), 0.3, Rect2(x0, z1 - 0.12, x1 - x0, 0.12), 0.31)
	var wood := p.st(PILLAR)
	var zp := z0 + 0.55
	var x := x0 + 0.5
	while x < x1:
		FarmProps.block(wood, Rect2(x - 0.06, zp - 0.06, 0.12, 0.12), 0.3, Rect2(x - 0.05, zp - 0.05, 0.1, 0.1), 2.05)
		x += 1.6
	FarmProps.block(wood, Rect2(x0 + 0.3, zp - 0.07, x1 - x0 - 0.6, 0.14), 1.92, Rect2(x0 + 0.3, zp - 0.07, x1 - x0 - 0.6, 0.14), 2.05)
	var zc := (z0 + z1) / 2.0
	FarmProps.block(p.st("build:planks_dark"), Rect2(x0 - 0.2, z0 - 0.2, x1 - x0 + 0.4, z1 - z0 + 0.45), 2.05, Rect2(x0 - 0.2, z0 - 0.2, x1 - x0 + 0.4, z1 - z0 + 0.45), 2.1)
	FarmProps.block(p.st("build:kawara"), Rect2(x0 - 0.25, z0 - 0.25, x1 - x0 + 0.5, z1 - z0 + 0.55), 2.1, Rect2(x0 - 0.25, zc - 0.04, x1 - x0 + 0.5, 0.08), 2.45)
	FarmProps.block(p.st(TILE_CAP), Rect2(x0 - 0.27, zc - 0.06, x1 - x0 + 0.54, 0.12), 2.42, Rect2(x0 - 0.27, zc - 0.05, x1 - x0 + 0.54, 0.1), 2.52)
	if snow:
		FarmProps.block(p.st(FarmProps.Parts.SNOW), Rect2(x0 - 0.2, z0 - 0.2, x1 - x0 + 0.4, z1 - z0 + 0.45), 2.15, Rect2(x0 - 0.2, zc - 0.03, x1 - x0 + 0.4, 0.06), 2.5)
	# The ticket booth: plaster walls, a window on its line side, a board roof inside the canopy.
	FarmProps.block(p.st("build:plaster"), Rect2(x0 + 0.1, z0 + 0.05, 0.9, 0.8), 0.3, Rect2(x0 + 0.1, z0 + 0.05, 0.9, 0.8), 1.5)
	FarmProps.block(p.st(Color("2a3036")), Rect2(x0 + 0.3, z0 + 0.85, 0.5, 0.02), 0.95, Rect2(x0 + 0.3, z0 + 0.85, 0.5, 0.02), 1.3)
	FarmProps.block(p.st(PILLAR), Rect2(x0 + 0.05, z0, 1.0, 0.9), 1.5, Rect2(x0 + 0.05, z0, 1.0, 0.9), 1.56)
	# A bench along the back, the name board on two posts at the east end.
	FarmProps.block(p.st("build:planks"), Rect2(x0 + 1.6, z0 + 0.15, 1.4, 0.3), 0.62, Rect2(x0 + 1.6, z0 + 0.15, 1.4, 0.3), 0.68)
	for bx in [x0 + 1.7, x0 + 2.85]:
		FarmProps.block(wood, Rect2(bx, z0 + 0.2, 0.06, 0.2), 0.3, Rect2(bx, z0 + 0.2, 0.06, 0.2), 0.62)
	var nx := x1 - 0.9
	for px in [nx - 0.45, nx + 0.45]:
		FarmProps.block(wood, Rect2(px - 0.03, z1 - 0.35, 0.06, 0.06), 0.3, Rect2(px - 0.03, z1 - 0.35, 0.06, 0.06), 1.35)
	FarmProps.block(p.st(Color("f2eee2")), Rect2(nx - 0.5, z1 - 0.34, 1.0, 0.03), 1.0, Rect2(nx - 0.5, z1 - 0.34, 1.0, 0.03), 1.32)
	FarmProps.block(p.st(Color("2a2420")), Rect2(nx - 0.32, z1 - 0.305, 0.64, 0.01), 1.1, Rect2(nx - 0.32, z1 - 0.305, 0.64, 0.01), 1.22)
	p.commit(w)


## The line along x across `r`: a bed of ballast, sleepers every 0.45 and two steel rails.
static func rails(w: FarmWorld, r: Rect2) -> void:
	var p := FarmProps.Parts.new()
	var zc := r.get_center().y
	FarmProps.block(p.st(BALLAST), Rect2(r.position.x, zc - 0.42, r.size.x, 0.84), 0.0, Rect2(r.position.x, zc - 0.36, r.size.x, 0.72), 0.05)
	var x := r.position.x + 0.2
	while x < r.end.x:
		FarmProps.block(p.st(SLEEPER), Rect2(x - 0.06, zc - 0.34, 0.12, 0.68), 0.05, Rect2(x - 0.06, zc - 0.34, 0.12, 0.68), 0.09)
		x += 0.45
	for dz in [-0.2, 0.2]:
		FarmProps.block(p.st(STEEL), Rect2(r.position.x, zc + dz - 0.025, r.size.x, 0.05), 0.09, Rect2(r.position.x, zc + dz - 0.018, r.size.x, 0.036), 0.15)
	p.commit(w)
