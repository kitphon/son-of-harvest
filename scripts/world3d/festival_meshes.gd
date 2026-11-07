class_name FestivalMeshes
extends RefCounted
## The festival decorations as real lit meshes (FestivalProps calls these; the same places,
## sizes and heights as the boxes they replace): picnic mats with their lunch, the stalls, the
## judges' table, lantern strings, the drum stage, the moon offering, pampas, standing lanterns,
## New Year bamboo, the bonfire, the mochi mortar and the fishing race's flag. Wood, cloth and
## straw are lit plain colours; the paper of a lantern and the flame are unshaded (`Parts.glow`),
## as before. The lights themselves (FestivalProps.glows) are not made here.

const WOOD := Color("6a4a30")
const WOOD_DARK := Color("3a281a")
const INK := Color("2a2420")
const RED := Color("d8402c")
const WHITE := Color("f4f0e6")
const FLAME := Color("ffb040")


## One hanging paper lantern centred on `at`: a ribbed round body of lit paper, dark caps, a
## tassel under it and a cord of `cord` up from the top.
static func lantern(p: FarmProps.Parts, at: Vector3, color: Color, cord := 0.0) -> void:
	var base := at - Vector3(0, 0.11, 0)
	Shrine.lathe(p.glow(color), base, [Vector2(0.07, 0.0), Vector2(0.1, 0.04), Vector2(0.115, 0.11), Vector2(0.1, 0.18), Vector2(0.07, 0.22)], 10)
	var ink := p.st(INK)
	for rib in [Vector2(0.105, 0.05), Vector2(0.12, 0.11), Vector2(0.105, 0.17)]:
		Shrine.lathe(ink, base, [Vector2(rib.x + 0.004, rib.y - 0.004), Vector2(rib.x + 0.004, rib.y + 0.004)], 10)
	Shrine.lathe(ink, base, [Vector2(0.07, 0.215), Vector2(0.075, 0.245), Vector2(0.04, 0.255)], 10)
	Shrine.lathe(ink, base, [Vector2(0.07, 0.005), Vector2(0.07, -0.025), Vector2(0.0, -0.025)], 10)
	Shrine.lathe(p.st(Color("c89a40")), base + Vector3(0, -0.095, 0), [Vector2(0.003, 0.0), Vector2(0.012, 0.03), Vector2(0.01, 0.07)], 6)
	if cord > 0.0:
		OutdoorProps._tube(ink, base + Vector3(0, 0.255, 0), Vector3.UP, [Vector2(0.006, 0.0), Vector2(0.006, cord)], 4, null)


# --- mats ------------------------------------------------------------------------

## A mat spread on the grass (a border in a lighter shade) with a lunch box, two rice balls and
## teacups on it.
static func mat(w: FarmWorld, mid: Vector3, r: Rect2, color: Color) -> void:
	var p := FarmProps.Parts.new()
	var rect := Rect2(mid.x - (r.size.x - 0.1) / 2, mid.z - (r.size.y - 0.1) / 2, r.size.x - 0.1, r.size.y - 0.1)
	FarmProps.block(p.st(color), rect, 0.0, rect.grow(-0.015), 0.03)
	var edge := p.st(color.lightened(0.35))
	var inner := rect.grow(-0.07)
	for strip in [Rect2(inner.position.x, inner.position.y, inner.size.x, 0.04), Rect2(inner.position.x, inner.end.y - 0.04, inner.size.x, 0.04),
			Rect2(inner.position.x, inner.position.y + 0.04, 0.04, inner.size.y - 0.08), Rect2(inner.end.x - 0.04, inner.position.y + 0.04, 0.04, inner.size.y - 0.08)]:
		FarmProps.block(edge, strip, 0.03, strip, 0.034)
	RoomProps._cube(p.st(Color("2a1a14")), Vector3(mid.x - 0.15, 0.03, mid.z), Vector3(0.36, 0.1, 0.26), 0.012)   # the lunch box
	RoomProps._cube(p.st(Color("b02a24")), Vector3(mid.x - 0.15, 0.13, mid.z), Vector3(0.32, 0.03, 0.22), 0.008)   # its lid
	for k in 2:   # rice balls: a soft triangle with a strip of seaweed
		var at := Vector3(mid.x + 0.06 + k * 0.14, 0.03, mid.z - 0.1)
		var foot := Rect2(at.x - 0.05, at.z - 0.045, 0.1, 0.09)
		FarmProps.block(p.st(Color("f8f6ee")), foot, 0.03, foot.grow(-0.032), 0.1)
		FarmProps.block(ink_of(p), Rect2(at.x - 0.035, at.z + 0.038, 0.07, 0.01), 0.03, Rect2(at.x - 0.03, at.z + 0.028, 0.06, 0.01), 0.07)
	for x in [0.2, 0.34]:   # teacups with a little tea in them
		var at := Vector3(mid.x + x, 0.03, mid.z + 0.12)
		Shrine.lathe(p.st(Color("e8e0cc")), at, [Vector2(0.03, 0.0), Vector2(0.05, 0.08)], 8)
		Shrine.lathe(p.st(Color("8a9a40")), at, [Vector2(0.044, 0.083), Vector2(0.0, 0.083)], 8)
	p.commit(w)


static func ink_of(p: FarmProps.Parts) -> SurfaceTool:
	return p.st(Color("1e1c1a"))


# --- the stall ---------------------------------------------------------------------

## A festival stall (yatai): a plank counter with a lighter top, four posts with tie beams, a
## sloping roof in its cloth colour with a scalloped valance, a short split curtain under it
## and a hanging lantern at the front corner (the light is FestivalProps').
static func stall(w: FarmWorld, mid: Vector3, r: Rect2, cloth: Color) -> void:
	var p := FarmProps.Parts.new()
	var wd := r.size.x - 0.2
	var cx := mid.x
	var counter := Rect2(cx - wd / 2, mid.z - 0.4, wd, 0.6)
	FarmProps.block(p.st("build:planks"), counter, 0.0, counter, 0.7)
	var top := Rect2(cx - wd / 2 - 0.03, mid.z - 0.43, wd + 0.06, 0.66)
	FarmProps.block(p.st(Color("8a6a48")), top, 0.7, top.grow(-0.012), 0.745)
	var wood := p.st(WOOD)
	for x in [-wd / 2, wd / 2]:
		for z in [-0.4, 0.3]:
			var high := 1.42 if z < 0.0 else 1.58   # the roof slopes up to the front
			var foot := Rect2(cx + x - 0.035, mid.z + z - 0.035, 0.07, 0.07)
			FarmProps.block(wood, foot, 0.0, foot.grow(-0.006), high)
	for z in [-0.4, 0.3]:   # tie beams under the roof
		var high := 1.42 if z < 0.0 else 1.58
		var beam := Rect2(cx - wd / 2 - 0.04, mid.z + z - 0.03, wd + 0.08, 0.06)
		FarmProps.block(wood, beam, high - 0.07, beam, high)
	var half := (wd + 0.3) / 2
	OutdoorProps._slab(p.st(cloth), cx - half, cx + half, mid.z - 0.55, 1.43, mid.z + 0.45, 1.67, 0.05)
	var edge := p.st(cloth.darkened(0.2))   # the roof's front rim
	var rim := Rect2(cx - half, mid.z + 0.44, half * 2, 0.03)
	FarmProps.block(edge, rim, 1.6, rim, 1.68)
	var count := maxi(2, int(wd / 0.22))
	var pw := half * 2 / count
	var light := cloth.lerp(Color.WHITE, 0.25)
	for i in count:   # the valance: points hanging off the rim
		var x := cx - half + i * pw
		var tone := p.st(cloth if i % 2 == 0 else light)
		var wide := Rect2(x + 0.01, mid.z + 0.43, pw - 0.02, 0.02)
		FarmProps.block(tone, wide.grow_individual(-0.03, 0, -0.03, 0), 1.42, wide, 1.52)
		FarmProps.block(tone, wide, 1.52, wide, 1.6)
	var rod := Rect2(cx - wd / 2, mid.z + 0.33, wd, 0.03)   # the curtain rod and the curtain
	FarmProps.block(p.st(WOOD_DARK), rod, 1.41, rod, 1.44)
	var pieces := maxi(2, int(wd / 0.3))
	var cw := wd / pieces
	lantern(p, mid + Vector3(wd / 2, 1.2, 0.36), RED, 0.12)
	p.commit(w)
	# The curtain's pieces hang from the rod each on its own, so they blow out in the wind
	# (OutdoorProps.Sway, out of step); the roof, the valance and the rod stay still.
	for i in pieces:
		var piece := Rect2(cx - wd / 2 + i * cw + 0.015, mid.z + 0.345, cw - 0.03, 0.015)
		var cp := FarmProps.Parts.new()
		FarmProps.block(cp.st(light), piece, 1.17, piece, 1.41)
		OutdoorProps.commit_swaying(w, cp, Vector3(piece.get_center().x, 1.41, piece.get_center().y), "cloth", mid.x + i * 1.9)


# --- the judges' table -------------------------------------------------------------

## The contest's judges' table: a long low table under a white cloth, a red and white striped
## curtain along its front, a name board (with its brushed name) on two posts behind it and
## three ribbon rosettes (red, white, blue) waiting for the winners.
static func judge_table(w: FarmWorld, mid: Vector3, r: Rect2) -> void:
	var p := FarmProps.Parts.new()
	var wd := r.size.x - 0.15
	var body := Rect2(mid.x - wd / 2, mid.z - 0.325, wd, 0.55)
	FarmProps.block(p.st(WOOD), body, 0.0, body, 0.5)
	var cloth := Rect2(mid.x - wd / 2 - 0.02, mid.z - 0.35, wd + 0.04, 0.6)
	FarmProps.block(p.st(Color("f4f0e6")), cloth, 0.5, cloth.grow(-0.01), 0.54)
	var stripes := int(wd / 0.25)
	for i in stripes:
		var piece := Rect2(mid.x - wd / 2 + i * wd / stripes, mid.z + 0.225, wd / stripes - 0.004, 0.02)
		FarmProps.block(p.st(RED if i % 2 == 0 else WHITE), piece, 0.06, piece, 0.5)
	var post := p.st(WOOD)
	for x in [-wd / 2 + 0.1, wd / 2 - 0.1]:
		var foot := Rect2(mid.x + x - 0.025, mid.z - 0.375, 0.05, 0.05)
		FarmProps.block(post, foot, 0.0, foot.grow(-0.004), 1.3)
	var frame := Rect2(mid.x - (wd - 0.06) / 2, mid.z - 0.38, wd - 0.06, 0.05)
	FarmProps.block(p.st(WOOD_DARK), frame, 0.97, frame, 1.33)
	var board := Rect2(mid.x - (wd - 0.16) / 2, mid.z - 0.335, wd - 0.16, 0.012)
	FarmProps.block(p.st(Color("e8dcc0")), board, 1.0, board, 1.3)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(mid.x) * 5 + int(mid.z)
	var ink := p.st(INK)   # the brushed name: a run of strokes
	var x := mid.x - (wd - 0.4) / 2
	while x < mid.x + (wd - 0.4) / 2 - 0.1:
		var sw := rng.randf_range(0.05, 0.1)
		var stroke := Rect2(x, mid.z - 0.323, sw, 0.012)
		FarmProps.block(ink, stroke, rng.randf_range(1.08, 1.12), stroke, rng.randf_range(1.2, 1.25))
		x += sw + 0.03
	for i in 3:   # rosettes lying on the cloth, tipped toward the viewer
		var colour: Color = [RED, Color("f4f0e6"), Color("2c4a8a")][i]
		var at := mid + Vector3((i - 1) * 0.3, 0.6, -0.05)
		var tilt := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(70)), at)
		RoomProps._placed(p.st(colour), tilt, func(t: SurfaceTool) -> void:
			Shrine.lathe(t, Vector3.ZERO, [Vector2(0.07, -0.01), Vector2(0.07, 0.01)], 10))
		RoomProps._placed(p.st(colour.lightened(0.3)), tilt, func(t: SurfaceTool) -> void:
			Shrine.lathe(t, Vector3.ZERO, [Vector2(0.032, 0.01), Vector2(0.03, 0.025)], 8))
		for tail in [-1.0, 1.0]:   # the two ribbon tails
			RoomProps._placed(p.st(colour), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(70)) * Basis(Vector3.BACK, tail * 0.25), at + Vector3(tail * 0.02, -0.05, 0.015)),
				func(t: SurfaceTool) -> void: RoomProps._cube(t, Vector3(0, -0.06, 0), Vector3(0.035, 0.12, 0.006)))
	p.commit(w)


# --- the lantern string ------------------------------------------------------------

## A string of lanterns along `r`: a pole at each end, a sagging rope between them and a lantern
## every cell, red and white in turn. The lanterns hang at (x + 0.5, 1.62), as FestivalProps'
## lights are.
static func lantern_line(w: FarmWorld, r: Rect2) -> void:
	var p := FarmProps.Parts.new()
	var z := r.get_center().y
	var wood := p.st(Color("5a4030"))
	var x0 := r.position.x + 0.1
	var x1 := r.end.x - 0.1
	for x in [x0, x1]:
		Shrine.lathe(wood, Vector3(x, 0, z), [Vector2(0.06, 0.0), Vector2(0.045, 1.0), Vector2(0.036, 1.9)], 6)
		Shrine.lathe(p.st(INK), Vector3(x, 1.9, z), [Vector2(0.05, 0.0), Vector2(0.04, 0.03)], 6)
	var rope := func(x: float) -> float:
		var u := (x - x0) / maxf(x1 - x0, 0.01)
		return 1.82 - 0.07 * 4.0 * u * (1.0 - u)
	var steps := maxi(4, int((x1 - x0) / 0.25))
	for i in steps:
		var a := Vector3(x0 + (x1 - x0) * i / steps, rope.call(x0 + (x1 - x0) * i / steps), z)
		var b := Vector3(x0 + (x1 - x0) * (i + 1) / steps, rope.call(x0 + (x1 - x0) * (i + 1) / steps), z)
		OutdoorProps._tube(p.st(INK), a, (b - a).normalized(), [Vector2(0.01, 0.0), Vector2(0.01, a.distance_to(b))], 4, null)
	for i in int(r.size.x):
		var x := r.position.x + i + 0.5
		var cord: float = rope.call(x) - (1.62 + 0.255)
		lantern(p, Vector3(x, 1.62, z), RED if i % 2 == 0 else Color("f0e6c8"), maxf(cord, 0.02))
	p.commit(w)


# --- the drum stage ----------------------------------------------------------------

## A drum stage: a plank platform on braced legs with a red and white cloth hanging round its
## front and right side, and a big barrel drum (skins, a ring of tacks) on two chocks, the two
## sticks lying by it.
static func drum_stage(w: FarmWorld, mid: Vector3) -> void:
	var p := FarmProps.Parts.new()
	var wood := p.st(Color("5a3a24"))
	for o in [Vector3(-0.8, 0, -0.8), Vector3(0.8, 0, -0.8), Vector3(-0.8, 0, 0.8), Vector3(0.8, 0, 0.8)]:
		var foot := Rect2(mid.x + o.x - 0.05, mid.z + o.z - 0.05, 0.1, 0.1)
		FarmProps.block(wood, foot, 0.0, foot.grow(-0.012), 0.9)
	for z in [-0.8, 0.8]:
		RoomProps._cube(wood, Vector3(mid.x, 0.3, mid.z + z), Vector3(1.6, 0.05, 0.04))
	for x in [-0.8, 0.8]:
		RoomProps._cube(wood, Vector3(mid.x + x, 0.3, mid.z), Vector3(0.04, 0.05, 1.6))
	var deck := Rect2(mid.x - 0.9, mid.z - 0.9, 1.8, 1.8)
	FarmProps.block(p.st("build:planks"), deck, 0.87, deck.grow(-0.012), 0.97)
	for i in 6:
		var c := p.st(RED if i % 2 == 0 else WHITE)
		var front := Rect2(mid.x - 0.9 + i * 0.3 + 0.004, mid.z + 0.9, 0.292, 0.02)
		FarmProps.block(c, front, 0.45, front, 0.86)
		var side := Rect2(mid.x + 0.9, mid.z - 0.9 + i * 0.3 + 0.004, 0.02, 0.292)
		FarmProps.block(c, side, 0.45, side, 0.86)
	# The drum lies on its side along a diagonal (as the cylinder it replaces did), on chocks.
	var axis := Basis(Vector3.UP, -PI / 4) * Basis(Vector3.BACK, -PI / 2)
	var centre := Vector3(mid.x, 1.32, mid.z)
	var drum := Transform3D(axis, centre)
	for s in [-0.17, 0.17]:
		var chock := centre + axis * Vector3(0, s, 0)
		RoomProps._cube(p.st(Color("4a2e1a")), Vector3(chock.x, 0.97, chock.z), Vector3(0.14, 0.1, 0.14), 0.02)
	RoomProps._placed(p.st(Color("8a4a2a")), drum, func(t: SurfaceTool) -> void:
		Shrine.lathe(t, Vector3.ZERO, [Vector2(0.3, -0.25), Vector2(0.34, -0.14), Vector2(0.36, 0.0), Vector2(0.34, 0.14), Vector2(0.3, 0.25)], 14))
	var skin := p.st(Color("e8d8b0"))
	RoomProps._placed(skin, drum, func(t: SurfaceTool) -> void:
		Shrine.lathe(t, Vector3.ZERO, [Vector2(0.285, 0.25), Vector2(0.0, 0.252)], 14))
	RoomProps._placed(skin, drum, func(t: SurfaceTool) -> void:
		Shrine.lathe(t, Vector3.ZERO, [Vector2(0.0, -0.252), Vector2(0.285, -0.25)], 14))
	var tacks := p.st(Color("26221f"))
	for y in [-0.215, 0.215]:   # the rings of tacks at both skins
		RoomProps._placed(tacks, drum, func(t: SurfaceTool) -> void:
			Shrine.lathe(t, Vector3.ZERO, [Vector2(0.318, y - 0.014), Vector2(0.318, y + 0.014)], 14))
	var stick := p.st(Color("c8a06a"))
	OutdoorProps._tube(stick, Vector3(mid.x - 0.6, 0.97, mid.z + 0.55), Vector3(0.97, 0.0, 0.24).normalized(), [Vector2(0.02, 0.0), Vector2(0.013, 0.42)], 6, null)
	OutdoorProps._tube(stick, Vector3(mid.x - 0.55, 0.97, mid.z + 0.65), Vector3(0.97, 0.0, 0.24).normalized(), [Vector2(0.02, 0.0), Vector2(0.013, 0.42)], 6, null)
	p.commit(w)


# --- the moon offering -----------------------------------------------------------

## The moon offering: a plain wooden stand (sanbo) with a paper under a pyramid of round dango.
static func moon_table(w: FarmWorld, mid: Vector3) -> void:
	var p := FarmProps.Parts.new()
	var wood := p.st(Color("d8c8a0"))
	var foot := Rect2(mid.x - 0.25, mid.z - 0.25, 0.5, 0.5)
	FarmProps.block(wood, foot, 0.0, foot.grow(-0.03), 0.3)
	FarmProps.block(p.st(INK), Rect2(mid.x - 0.1, mid.z + 0.238, 0.2, 0.012), 0.07, Rect2(mid.x - 0.1, mid.z + 0.238, 0.2, 0.012), 0.2)   # the stand's opening
	var plate := Rect2(mid.x - 0.3, mid.z - 0.3, 0.6, 0.6)
	FarmProps.block(p.st(Color("e8dcc0")), plate, 0.3, plate.grow(-0.02), 0.34)
	var paper := Rect2(mid.x - 0.19, mid.z - 0.19, 0.38, 0.38)
	FarmProps.block(p.st(WHITE), paper, 0.34, paper.grow(-0.01), 0.345)
	var dango := p.st(Color("f8f4ea"))
	for y in 3:
		var n := 3 - y
		for i in n:
			for j in n:
				RoomProps._ball(dango, Vector3(mid.x + (i - (n - 1) / 2.0) * 0.12, 0.345 + y * 0.1, mid.z + (j - (n - 1) / 2.0) * 0.12), 0.06)
	p.commit(w)


## Pampas grass in a tall vase: a round glazed vase, grey stalks leaning apart with pale
## silver plumes, a few long blades round the mouth.
static func pampas(w: FarmWorld, mid: Vector3) -> void:
	var p := FarmProps.Parts.new()
	var glaze := p.st(Color("4a5a6a"))
	Shrine.lathe(glaze, mid, [Vector2(0.09, 0.0), Vector2(0.125, 0.1), Vector2(0.13, 0.22), Vector2(0.105, 0.34), Vector2(0.075, 0.4), Vector2(0.092, 0.435)], 10)
	Shrine.lathe(p.st(Color("5c6e80")), mid, [Vector2(0.092, 0.435), Vector2(0.092, 0.45), Vector2(0.075, 0.45)], 10)
	Shrine.lathe(p.st(INK), mid, [Vector2(0.075, 0.447), Vector2(0.0, 0.447)], 10)
	var stalk := p.st(Color("8a8a6a"))
	var plume := p.st(Color("e4dcc4"))
	var top := mid + Vector3(0, 0.44, 0)
	for i in 5:
		var lean := Vector3((i - 2) * 0.12, 0, (i % 2) * 0.08 - 0.04)
		var d := Vector3(lean.x * 0.9, 1.0, lean.z * 0.9).normalized()
		OutdoorProps._tube(stalk, top, d, [Vector2(0.013, 0.0), Vector2(0.006, 0.78)], 5, null)
		var tip := top + d * 0.78
		OutdoorProps._tube(plume, tip, d, [Vector2(0.01, 0.0), Vector2(0.038, 0.09), Vector2(0.034, 0.2), Vector2(0.0, 0.3)], 6, null)
	var blade := p.st(Color("8a9a6a"))
	for k in 6:
		var a := TAU * k / 6.0 + 0.3
		var d := Vector3(cos(a) * cos(1.1), sin(1.1), sin(a) * cos(1.1)).normalized()
		OutdoorProps._leaf(blade, null, top, d, 0.62, 0.05, Color.WHITE)
	p.commit(w)


# --- the standing lantern ----------------------------------------------------------

## A standing paper lantern: a stone foot, a thin pole through a ribbed round lantern of lit
## paper with dark caps (the light is FestivalProps').
static func paper_lantern(w: FarmWorld, mid: Vector3) -> void:
	var p := FarmProps.Parts.new()
	var foot := Rect2(mid.x - 0.1, mid.z - 0.1, 0.2, 0.2)
	FarmProps.block(p.st(Color("8e8a80")), foot, 0.0, foot.grow(-0.02), 0.07)
	Shrine.lathe(p.st(INK), mid, [Vector2(0.036, 0.07), Vector2(0.03, 1.1)], 6)
	var base := Vector3(mid.x, 1.07, mid.z)
	Shrine.lathe(p.glow(Color("f0e6c8")), base, [Vector2(0.1, 0.0), Vector2(0.16, 0.06), Vector2(0.17, 0.18), Vector2(0.16, 0.3), Vector2(0.1, 0.36)], 12)
	var ink := p.st(INK)
	for rib in [Vector2(0.168, 0.09), Vector2(0.176, 0.18), Vector2(0.168, 0.27)]:
		Shrine.lathe(ink, base, [Vector2(rib.x, rib.y - 0.006), Vector2(rib.x, rib.y + 0.006)], 12)
	Shrine.lathe(ink, base, [Vector2(0.1, 0.355), Vector2(0.1, 0.4), Vector2(0.05, 0.41)], 10)
	Shrine.lathe(ink, base, [Vector2(0.1, 0.005), Vector2(0.1, -0.03), Vector2(0.0, -0.03)], 10)
	p.commit(w)


# --- New Year bamboo -------------------------------------------------------------

const KADO_STRAW := Color("c8a868")
const KADO_CORD := Color("6a4a26")
const KADO_CULM := Color("5a9a48")
const KADO_NODE := Color("8abf6c")

## New Year bamboo (kadomatsu): a straw-bound tub (cord bands, a frayed straw lip, straw ends
## splayed at the foot), three green culms of different heights bundled with a straw wrap and
## cord, each with node rings and its top cut on a slant (pale face, dark hollow), pine sprigs
## fanned round the foot with a twig of plum blossom. `snow` lays snow on the tub and the sprigs.
static func kadomatsu(w: FarmWorld, mid: Vector3, snow := false) -> void:
	var p := FarmProps.Parts.new()
	var straw := p.st(KADO_STRAW)
	Shrine.lathe(straw, mid, [Vector2(0.27, 0.0), Vector2(0.285, 0.1), Vector2(0.28, 0.2), Vector2(0.27, 0.3), Vector2(0.245, 0.39),
		Vector2(0.272, 0.41), Vector2(0.25, 0.425)], 12)
	var cord := p.st(KADO_CORD)
	for band in [Vector2(0.29, 0.1), Vector2(0.285, 0.2), Vector2(0.275, 0.3)]:
		OutdoorProps._tube(cord, mid + Vector3(0, band.y - 0.022, 0), Vector3.UP,
			[Vector2(band.x, 0.0), Vector2(band.x + 0.01, 0.01), Vector2(band.x + 0.01, 0.034), Vector2(band.x, 0.044)], 12, null)
	Shrine.lathe(p.st(Color("6a4a2a")), mid, [Vector2(0.245, 0.405), Vector2(0.0, 0.405)], 12)
	# Straw ends splayed out at the foot and fraying over the lip.
	for k in 14:
		var a := TAU * (k + 0.3) / 14.0
		var out := Vector3(cos(a), 0, sin(a))
		var foot := mid + out * 0.27 + Vector3(0, 0.01, 0)
		OutdoorProps._tube(straw, foot, (out * 0.5 + Vector3(0, 0.85, 0)).normalized(), [Vector2(0.012, 0.0), Vector2(0.004, 0.09 + 0.02 * (k % 3))], 4, null)
		OutdoorProps._tube(straw, mid + out * 0.255 + Vector3(0, 0.42, 0), (out * 0.9 + Vector3(0, 0.4, 0)).normalized(),
			[Vector2(0.01, 0.0), Vector2(0.003, 0.07)], 4, null)
	# The culms: bundle, cut on a slant, node rings.
	var node := p.st(KADO_NODE)
	var bundle := mid + Vector3(0, 0, 0.0267)
	for s in [[Vector3(0, 0, -0.06), 1.3, 0.05, 0.0], [Vector3(-0.1, 0, 0.07), 1.05, 0.052, 0.09], [Vector3(0.1, 0, 0.07), 0.85, 0.046, 0.17]]:
		_cut_stalk(p, mid + (s[0] as Vector3) + Vector3(0, 0.4, 0), float(s[2]), float(s[1]) - 0.4, float(s[3]))
	# The wrap: a band of straw with two cord turns over it.
	OutdoorProps._tube(straw, bundle + Vector3(0, 0.56, 0), Vector3.UP,
		[Vector2(0.172, 0.0), Vector2(0.182, 0.02), Vector2(0.182, 0.1), Vector2(0.172, 0.12)], 12, null)
	for y in [0.575, 0.665]:
		OutdoorProps._tube(cord, bundle + Vector3(0, y, 0), Vector3.UP,
			[Vector2(0.182, 0.0), Vector2(0.19, 0.008), Vector2(0.19, 0.024), Vector2(0.182, 0.032)], 12, null)
	if snow:
		Shrine.lathe(p.st(FarmProps.Parts.SNOW), mid, [Vector2(0.225, 0.43), Vector2(0.15, 0.455), Vector2(0.04, 0.46)], 12)
	p.commit(w)
	# Pine sprigs round the foot: a cone of dark boughs and fans of needles on each. Each sprig
	# (with its snow) and the plum twig is its own piece, leaning a little in the wind about
	# where it is stuck in (OutdoorProps.Sway); the tub and the culms stay still.
	for j in 5:
		var sp := FarmProps.Parts.new()
		var pine := sp.st(Color("2f5a34"))
		var needle := sp.st(Color("3a6e3c"))
		var rim := sp.st(Color("224a2a"))
		var a := 0.5 + TAU * j / 5.0
		var at := mid + Vector3(cos(a) * 0.185, 0.41, sin(a) * 0.185)
		Shrine.lathe(pine, at, [Vector2(0.13, 0.0), Vector2(0.07, 0.12), Vector2(0.0, 0.28 + 0.02 * (j % 2))], 8)
		Shrine.lathe(rim, at, [Vector2(0.15, -0.01), Vector2(0.13, 0.0)], 8)
		for k in 9:
			var b: float = a + (k - 4) * 0.33
			var d := Vector3(cos(b) * 0.8, 0.55 + 0.25 * (k % 3), sin(b) * 0.8).normalized()
			OutdoorProps._tube(needle, at + Vector3(0, 0.03, 0), d, [Vector2(0.011, 0.0), Vector2(0.003, 0.2 + 0.04 * (k % 2))], 4, null)
		if snow:
			Shrine.lathe(sp.st(FarmProps.Parts.SNOW), at + Vector3(0, 0.03, 0), [Vector2(0.095, 0.0), Vector2(0.0, 0.25)], 8)
		OutdoorProps.commit_swaying(w, sp, at, "leaves", mid.x + j * 1.3)
	# A plum twig leaning out at the back, three blossoms.
	var tp := FarmProps.Parts.new()
	var twig := tp.st(Color("4a3424"))
	var d_t := Vector3(-0.4, 0.8, -0.35).normalized()
	var t_foot := mid + Vector3(0.1, 0.43, -0.05)
	OutdoorProps._tube(twig, t_foot, d_t, [Vector2(0.012, 0.0), Vector2(0.006, 0.34)], 4, null)
	var bloom := tp.st(Color("f4d8e0"))
	for q in [0.14, 0.24, 0.34]:
		Shrine.lathe(bloom, t_foot + d_t * q + Vector3(0, 0.008, 0), [Vector2(0.04, 0.0), Vector2(0.03, 0.02), Vector2(0.0, 0.025)], 5)
	OutdoorProps.commit_swaying(w, tp, t_foot, "leaves", mid.x + 7.7)


## A bamboo culm of radius `rad` standing on `foot`, `len` high at its lowest point, tapering a
## little, a node ring every 0.28 (the first at `phase`), its top cut slantwise: a pale cut face
## with the dark hollow in the middle.
static func _cut_stalk(p: FarmProps.Parts, foot: Vector3, rad: float, len: float, phase := 0.0) -> void:
	const SIDES := 8
	const SLOPE := 0.7
	var green := p.st(KADO_CULM)
	var none := func(_q: Vector3) -> Vector2: return Vector2.ZERO
	var r_top := rad * 0.9
	var ring_top: Array[Vector3] = []
	var ring_foot: Array[Vector3] = []
	for k in SIDES:
		var a := TAU * k / SIDES
		ring_foot.append(foot + Vector3(cos(a) * rad, 0, sin(a) * rad))
		ring_top.append(foot + Vector3(cos(a) * r_top, len + 0.03 + SLOPE * r_top * cos(a), sin(a) * r_top))
	var face := foot + Vector3(0, len + 0.03, 0)
	var n_cut := Vector3(-SLOPE, 1.0, 0).normalized()
	var pale := p.st(Color("d8e8b0"))
	var dark := p.st(Color("3a4a2a"))
	for k in SIDES:
		var k2 := (k + 1) % SIDES
		var am := TAU * (k + 0.5) / SIDES
		Minka.quad(green, ring_foot[k], ring_foot[k2], ring_top[k2], ring_top[k], Vector3(cos(am), 0, sin(am)), none)
		Minka.tri(pale, face, ring_top[k], ring_top[k2], n_cut, none)
		var lift := Vector3(0, 0.004, 0)
		var inner_a: Vector3 = face + (ring_top[k] - face) * 0.55 + lift
		var inner_b: Vector3 = face + (ring_top[k2] - face) * 0.55 + lift
		Minka.tri(dark, face + lift, inner_a, inner_b, n_cut, none)
	var node := p.st(KADO_NODE)
	var y := 0.2 + phase
	while y < len - 0.1:
		var r := lerpf(rad, r_top, y / len)
		OutdoorProps._tube(node, foot + Vector3(0, y, 0), Vector3.UP, [Vector2(r, -0.012), Vector2(r * 1.3, 0.0), Vector2(r, 0.012)], SIDES, null)
		y += 0.28


# --- the bonfire -------------------------------------------------------------------

## A shrine bonfire: a ring of rough stones, logs stood leaning together over two lying ones,
## a bed of embers and the flames (unshaded, as before). The light is FestivalProps'.
static func bonfire(w: FarmWorld, mid: Vector3) -> void:
	var p := FarmProps.Parts.new()
	var tones: Array[Color] = [Color("5c5852"), Color("78746c"), Color("8c8880")]
	for i in 8:
		var a := i * TAU / 8
		OutdoorProps._boulder(p, null, mid + Vector3(cos(a) * 0.36, 0, sin(a) * 0.36), 0.085, 0.1, 0.085, i * 7 + 3, tones)
	var bark := p.st(Color("4a3020"))
	for t in [0.4, -0.4]:   # two lying logs, crossed
		var d := Vector3(cos(t + PI / 4), 0, sin(t + PI / 4))
		OutdoorProps._tube(bark, mid - d * 0.35 + Vector3(0, 0.09, 0), d, [Vector2(0.045, 0.0), Vector2(0.042, 0.7)], 7, null)
	var char := p.st(Color("1e1410"))
	for k in 4:   # four leaning logs
		var a := TAU * k / 4.0 + 0.6
		var out := Vector3(cos(a), 0, sin(a))
		var d := (-out * 0.45 + Vector3(0, 0.75, 0)).normalized()
		var foot := mid + out * 0.27 + Vector3(0, 0.05, 0)
		OutdoorProps._tube(bark, foot, d, [Vector2(0.045, 0.0), Vector2(0.04, 0.4)], 7, null)
		OutdoorProps._tube(char, foot + d * 0.4, d, [Vector2(0.04, 0.0), Vector2(0.036, 0.14)], 7, null)
	Shrine.lathe(p.glow(Color("ff7a30")), mid, [Vector2(0.27, 0.045), Vector2(0.0, 0.045)], 12)
	var flame := p.glow(FLAME)
	Shrine.lathe(flame, mid + Vector3(0, 0.15, 0), [Vector2(0.22, 0.0), Vector2(0.2, 0.12), Vector2(0.13, 0.28), Vector2(0.05, 0.45), Vector2(0.0, 0.58)], 10)
	for k in 4:   # tongues leaning out
		var a := TAU * k / 4.0 + 0.3
		var out := Vector3(cos(a), 0, sin(a))
		var lean := Basis(Vector3.UP.cross(out).normalized(), 0.4)
		RoomProps._placed(flame, Transform3D(lean, mid + out * 0.15 + Vector3(0, 0.15, 0)), func(t: SurfaceTool) -> void:
			Shrine.lathe(t, Vector3.ZERO, [Vector2(0.07, 0.0), Vector2(0.06, 0.1), Vector2(0.0, 0.3)], 6))
	Shrine.lathe(p.glow(Color("fff0a0")), mid + Vector3(0, 0.15, 0), [Vector2(0.11, 0.0), Vector2(0.09, 0.12), Vector2(0.0, 0.4)], 8)
	p.commit(w)


# --- the festival games ------------------------------------------------------------

## The mochi pounding's mortar (a festival game's prop): a hooped log hollowed on top with the
## white dough in it, the mallet leaning on its side and a pail of water for the hands.
static func mochi_usu(w: FarmWorld, mid: Vector3) -> void:
	var p := FarmProps.Parts.new()
	var wood := p.st(PlaceholderArt.MOCHI_WOOD)
	Shrine.lathe(wood, mid, [Vector2(0.31, 0.0), Vector2(0.33, 0.1), Vector2(0.33, 0.5)], 12)
	var hoop := p.st(PlaceholderArt.MOCHI_HOOP)
	for y in [0.12, 0.4]:
		Shrine.lathe(hoop, mid, [Vector2(0.342, y - 0.02), Vector2(0.342, y + 0.02)], 12)
	Shrine.lathe(p.st(PlaceholderArt.MOCHI_WOOD.lightened(0.12)), mid, [Vector2(0.33, 0.5), Vector2(0.32, 0.515), Vector2(0.24, 0.515)], 12)
	var hollow := p.st(PlaceholderArt.MOCHI_WOOD_DARK)
	Shrine.lathe(hollow, mid, [Vector2(0.24, 0.515), Vector2(0.2, 0.44), Vector2(0.0, 0.44)], 12)
	Shrine.lathe(p.st(PlaceholderArt.MOCHI_DOUGH), mid, [Vector2(0.17, 0.44), Vector2(0.18, 0.48), Vector2(0.14, 0.55), Vector2(0.07, 0.6), Vector2(0.0, 0.61)], 12)
	# The mallet (kine): a handle leaning against the mortar and its barrel head.
	var handle_foot := mid + Vector3(0.62, 0, 0.05)
	var d := Vector3(-0.12, 1.0, 0.0).normalized()
	OutdoorProps._tube(p.st(Color("c8a06a")), handle_foot, d, [Vector2(0.03, 0.0), Vector2(0.024, 0.85)], 7, null)
	var head := handle_foot + d * 0.85
	RoomProps._turn_x(wood, head - Vector3(0.15, 0, 0), [Vector2(0.075, 0.0), Vector2(0.095, 0.08), Vector2(0.095, 0.22), Vector2(0.075, 0.3)], 10)
	# The water pail.
	var pail_at := mid + Vector3(-0.45, 0, 0.15)
	Shrine.lathe(p.st(Color("8a7a5a")), pail_at, [Vector2(0.1, 0.0), Vector2(0.12, 0.18)], 10)
	for y in [0.04, 0.14]:
		Shrine.lathe(p.st(Color("5a4a34")), pail_at, [Vector2(0.1 + (y * 0.11) + 0.004, y - 0.01), Vector2(0.1 + (y * 0.11) + 0.004, y + 0.01)], 10)
	Shrine.lathe(p.st(Color("6aa0c8")), pail_at, [Vector2(0.112, 0.17), Vector2(0.0, 0.17)], 10)
	p.commit(w)


## The fishing race's start (a festival game's prop): a bamboo pole with node rings, a tall indigo
## banner (a pale hem, a white fish on it) hung from a crossbar, and the race's creel at its
## foot, a woven basket with bands and a domed lid.
static func race_flag(w: FarmWorld, mid: Vector3) -> void:
	var p := FarmProps.Parts.new()
	var at := mid + Vector3(-0.25, 0, 0)
	var pole := p.st(Color("b89a5a"))
	Shrine.lathe(pole, at, [Vector2(0.036, 0.0), Vector2(0.033, 0.85), Vector2(0.029, 1.7)], 8)
	var node := p.st(Color("d4b878"))
	for y in [0.4, 0.85, 1.3]:
		Shrine.lathe(node, at, [Vector2(0.04, y - 0.012), Vector2(0.04, y + 0.012)], 8)
	OutdoorProps._tube(pole, Vector3(at.x, 1.62, at.z), Vector3.RIGHT, [Vector2(0.016, 0.0), Vector2(0.014, 0.52)], 6, null)
	var cloth := PlaceholderArt.RACE_CLOTH
	# The banner below its hem is its own piece, swinging from the crossbar in the wind
	# (OutdoorProps.Sway, free on both faces); the pole, the bar and the hem round it stay still.
	var fp := FarmProps.Parts.new()
	var banner := Rect2(at.x + 0.03, at.z - 0.01, 0.44, 0.02)
	FarmProps.block(fp.st(cloth), banner, 0.555, banner, 1.605)
	var hem := Rect2(at.x + 0.025, at.z - 0.013, 0.45, 0.026)
	FarmProps.block(p.st(cloth.lightened(0.25)), hem, 1.55, hem, 1.61)
	FarmProps.block(fp.st(cloth.darkened(0.25)), Rect2(at.x + 0.46, at.z - 0.012, 0.012, 0.024), 0.56, Rect2(at.x + 0.46, at.z - 0.012, 0.012, 0.024), 1.55)
	# The fish: an ellipse nose up and a split tail, on both faces.
	var none := func(_q: Vector3) -> Vector2: return Vector2.ZERO
	var mark := fp.st(PlaceholderArt.RACE_MARK)
	var cx := at.x + 0.25
	for side in [1.0, -1.0]:
		var zf: float = at.z + side * 0.012
		var n := Vector3(0, 0, side)
		var c := Vector3(cx, 1.2, zf)
		for k in 10:
			var a0 := TAU * k / 10.0
			var a1 := TAU * (k + 1) / 10.0
			Minka.tri(mark, c, c + Vector3(cos(a0) * 0.05, sin(a0) * 0.15, 0), c + Vector3(cos(a1) * 0.05, sin(a1) * 0.15, 0), n, none)
		Minka.tri(mark, Vector3(cx, 1.05, zf), Vector3(cx - 0.075, 0.98, zf), Vector3(cx - 0.02, 0.99, zf), n, none)
		Minka.tri(mark, Vector3(cx, 1.05, zf), Vector3(cx + 0.075, 0.98, zf), Vector3(cx + 0.02, 0.99, zf), n, none)
	# The creel.
	var creel_at := mid + Vector3(0.2, 0, 0.15)
	var basket := PlaceholderArt.RACE_CREEL
	Shrine.lathe(p.st(basket), creel_at, [Vector2(0.13, 0.0), Vector2(0.15, 0.13), Vector2(0.16, 0.26)], 10)
	var band := p.st(basket.darkened(0.3))
	for y in [0.06, 0.13, 0.2]:
		var rad: float = 0.13 + 0.03 * y / 0.26 * 1.0 + 0.007
		Shrine.lathe(band, creel_at, [Vector2(rad, y - 0.008), Vector2(rad, y + 0.008)], 10)
	Shrine.lathe(p.st(basket.darkened(0.25)), creel_at, [Vector2(0.168, 0.26), Vector2(0.168, 0.285), Vector2(0.11, 0.32), Vector2(0.035, 0.34), Vector2(0.0, 0.342)], 10)
	Shrine.lathe(p.st(basket.darkened(0.45)), creel_at + Vector3(0, 0.34, 0), [Vector2(0.025, 0.0), Vector2(0.03, 0.025), Vector2(0.0, 0.04)], 6)
	p.commit(w)
	OutdoorProps.commit_swaying(w, fp, Vector3(banner.get_center().x, 1.58, at.z), "cloth", mid.x, 0.0)
