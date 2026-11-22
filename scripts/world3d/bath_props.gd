class_name BathProps
extends RefCounted
## The bath lane's own props in 3D (Yumachi, 2026-11-22; docs/DESIGN.md → ที่อาบน้ำ).
## `chimney`: the public bath's tall square chimney (entotsu) at its east wall's front corner, rising well
## over the two-storey roof (its ridge near 3.7) so it reads from the lane: a stone plinth, a
## tapering shaft of weathered render, dark iron bands, a sooty lip and an open top. The flat
## view draws it in MapView.draw_chimney.
## Inside the bath (data/maps/sento.json, Baths step 2) the KINDS: `yubune` the big tiled tub along
## the back wall (its water's top at WATER, the farmer sat in it drawn from there: data/baths.json
## lift), `kran` the washing island (taps and little mirrors on a tiled panel, a stool and a bucket at
## each place), `milk_fridge` the glass-fronted cooler of milk bottles, `basket_shelf` the cubbies
## of rattan baskets for clothes, `bench` a long bench, `getabako` the shoe lockers with wooden
## keys, `bath_noren` the indigo curtain hung in the partition's doorway on a rod between two posts,
## `bath_mural` the mountain painted across the back wall over the tub (BathArt). The flat view
## draws them in BathLook.

const HEIGHT := 5.2          # the top of the lip, world units (a cell is 1)
const SHAFT := Color("8c8174")
const BAND := Color("37302b")
const SOOT := Color("2a2522")
const KINDS := BathLook.KINDS
const RIM := 0.5             # the tub's tiled rim, units up
const WATER := 0.42          # its water's top (data/baths.json sento lift)
const WATER_COLOR := BathLook.WATER_COLOR
const STONE_CAP := BathLook.STONE_CAP
const BRASS := BathLook.BRASS
const CHROME := Color("c8ced2")
const MIRROR := BathLook.MIRROR
const ENAMEL := BathLook.ENAMEL
const BOTTLE := Color("f8f8f2")
const CAP := BathLook.CAP
const STEAM_PUFFS := 4


static func chimney(w: FarmWorld, mid: Vector3, snowy: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Four sides: the corners half a facet off +z, so a face looks down +z (Shrine.lathe).
	Shrine.lathe(st, mid, [Vector2(0.5, 0.0), Vector2(0.5, 0.35), Vector2(0.42, 0.42)], 4)   # plinth
	Minka.add_mesh(w, st, Minka.plain(Color(Shrine.STONE)))
	var shaft := SurfaceTool.new()
	shaft.begin(Mesh.PRIMITIVE_TRIANGLES)
	Shrine.lathe(shaft, mid, [Vector2(0.4, 0.42), Vector2(0.27, HEIGHT - 0.25)], 4)
	Minka.add_mesh(w, shaft, Minka.plain(SHAFT))
	# Iron bands round the shaft, each a little proud of it where it stands.
	var bands := SurfaceTool.new()
	bands.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in [1.6, 2.9, 4.1]:
		var r := lerpf(0.4, 0.27, (y - 0.42) / (HEIGHT - 0.25 - 0.42)) + 0.025
		Shrine.lathe(bands, mid, [Vector2(r, y), Vector2(r, y + 0.09)], 4)
	Minka.add_mesh(w, bands, Minka.plain(BAND))
	# The lip at the top, sooty, its mouth a dark hollow inside it.
	var lip := SurfaceTool.new()
	lip.begin(Mesh.PRIMITIVE_TRIANGLES)
	Shrine.lathe(lip, mid, [Vector2(0.27, HEIGHT - 0.25), Vector2(0.33, HEIGHT - 0.2), Vector2(0.33, HEIGHT), Vector2(0.24, HEIGHT), Vector2(0.24, HEIGHT - 0.15)], 4)   # down into the mouth, its floor closed dark
	Minka.add_mesh(w, lip, Minka.plain(SOOT))
	if snowy:
		var snow := SurfaceTool.new()
		snow.begin(Mesh.PRIMITIVE_TRIANGLES)
		Shrine.lathe(snow, mid, [Vector2(0.47, 0.42), Vector2(0.4, 0.47)], 4)
		Shrine.lathe(snow, mid, [Vector2(0.34, HEIGHT), Vector2(0.3, HEIGHT + 0.04), Vector2(0.25, HEIGHT + 0.04)], 4)
		Shrine._snow(w, snow)


## A bath prop by its kind (MapWorld calls this for the KINDS).
static func prop(w: FarmWorld, p: Dictionary, mid: Vector3, r: Rect2) -> void:
	var parts := FarmProps.Parts.new()
	match str(p.kind):
		"yubune": _yubune(parts, r)
		"kran": _kran(parts, r)
		"milk_fridge": _milk_fridge(parts, mid)
		"basket_shelf": _basket_shelf(parts, r)
		"bench": _bench(parts, r)
		"getabako": _getabako(parts, r)
		"bath_noren": _noren(w, parts, r)
		"bath_mural": _mural(w, r)
	parts.commit(w)


## Steam off the tub's water: a few grown Steam nodes over it, each out of step (MapWorld adds
## them after the cached meshes). Returns them (for tests).
static func steam(w: Node3D, r: Rect2) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for k in STEAM_PUFFS:
		var s := StallWares.Steam.new(int(r.position.x) * 11 + k * 29)
		s.scale = Vector3.ONE * FootBath.STEAM_SCALE * 0.8
		s.position = Vector3(r.position.x + r.size.x * (0.15 + 0.7 * k / float(STEAM_PUFFS - 1)), WATER + 0.12, r.get_center().y + [0.2, -0.1, 0.25, 0.0][k % 4])
		s.name = "BathSteam%d" % k
		w.add_child(s)
		out.append(s)
	return out


## The tub against the back wall: tiled sides with a pale stone cap round the top, the water
## filling it to WATER, a brass spout on the back wall at the left end pouring into it.
static func _yubune(p: FarmProps.Parts, r: Rect2) -> void:
	var tub := Rect2(r.position.x + 0.03, r.position.y + 0.02, r.size.x - 0.06, r.size.y - 0.08)
	var side := 0.14
	var tile := p.st("bath:tile")
	for wall in [Rect2(tub.position.x, tub.end.y - side, tub.size.x, side), Rect2(tub.position.x, tub.position.y, side, tub.size.y),
			Rect2(tub.end.x - side, tub.position.y, side, tub.size.y), Rect2(tub.position.x, tub.position.y, tub.size.x, side)]:
		FarmProps.block(tile, wall, 0.0, wall, RIM)
		FarmProps.block(p.st(STONE_CAP), wall.grow(0.015), RIM, wall.grow(0.005), RIM + 0.05)
	var inner := tub.grow(-side)
	FarmProps.block(p.st(WATER_COLOR), inner, 0.0, inner, WATER)
	for k in 5:   # a few lighter ripples on the water
		var x := inner.position.x + 0.3 + k * (inner.size.x - 0.6) / 4.0
		var z := inner.position.y + 0.25 + 0.3 * (k % 3)
		RoomProps._cube(p.st(WATER_COLOR.lightened(0.25)), Vector3(x, WATER, z), Vector3(0.28, 0.004, 0.03))
	var spout := Vector3(tub.position.x + 0.5, 0.86, r.position.y)
	RoomProps._cube(p.st(BRASS), spout + Vector3(0, -0.06, 0.02), Vector3(0.16, 0.16, 0.06))
	RoomProps._cube(p.st(BRASS), spout + Vector3(0, 0.0, 0.1), Vector3(0.06, 0.05, 0.16))
	RoomProps._cube(p.st(WATER_COLOR.lightened(0.4)), Vector3(spout.x, WATER, spout.z + 0.17), Vector3(0.03, 0.86 - WATER, 0.03))


## The washing island across its cells: a low tiled base, a panel up the middle with a mirror and
## two taps (hot and cold) over a ledge at each place, a wooden stool and a bucket before each on
## the near side (+z, toward the eye).
static func _kran(p: FarmProps.Parts, r: Rect2) -> void:
	var z := r.position.y + 0.3
	var base := Rect2(r.position.x + 0.05, z - 0.08, r.size.x - 0.1, 0.36)
	FarmProps.block(p.st("bath:tile"), base, 0.0, base, 0.32)
	FarmProps.block(p.st(STONE_CAP), base.grow(0.01), 0.32, base, 0.35)
	var panel := Rect2(r.position.x + 0.05, z - 0.06, r.size.x - 0.1, 0.08)
	FarmProps.block(p.st("bath:tile"), panel, 0.35, panel, 1.15)
	FarmProps.block(p.st(STONE_CAP), panel.grow(0.01), 1.15, panel, 1.19)
	var face := panel.end.y
	for k in int(r.size.x):
		var x := r.position.x + k + 0.5
		RoomProps._front(p.st(MIRROR), x - 0.2, x + 0.2, 0.62, 1.02, face)
		RoomProps._front(p.st(Color("e2eef2")), x - 0.18, x - 0.1, 0.94, 1.0, face + 0.002)   # a glint on the glass
		for dx in [-0.12, 0.12]:
			RoomProps._cube(p.st(CHROME), Vector3(x + dx, 0.46, face), Vector3(0.05, 0.05, 0.06))
			RoomProps._cube(p.st(Color("c04a3a") if dx < 0.0 else Color("3a6ac0")), Vector3(x + dx, 0.51, face + 0.01), Vector3(0.03, 0.015, 0.03))
		RoomProps._cube(p.st(CHROME), Vector3(x, 0.44, face + 0.02), Vector3(0.18, 0.03, 0.05))   # the spout between them
		RoomProps._cube(p.st(RoomProps.WOOD), Vector3(x - 0.08, 0.0, r.position.y + 0.78), Vector3(0.24, 0.2, 0.2), 0.02)   # the stool
		var bucket := Vector3(x + 0.22, 0.0, r.position.y + 0.8)
		Shrine.lathe(p.st(Color("b08a5a")), bucket, [Vector2(0.09, 0.0), Vector2(0.11, 0.12)], 10)
		Shrine.lathe(p.st(RoomProps.TIMBER), bucket, [Vector2(0.1, 0.03), Vector2(0.104, 0.05)], 10)


## The milk cooler against the back wall: a white enamel cabinet, a lit sign along its top, three
## shelves of bottles with paper caps behind its glass front, the glass a pale frame.
static func _milk_fridge(p: FarmProps.Parts, mid: Vector3) -> void:
	var at := mid + Vector3(0, 0, -0.18)
	RoomProps._cube(p.st(ENAMEL), at, Vector3(0.64, 1.3, 0.5), 0.02)
	var front := at.z + 0.25
	RoomProps._front(p.st(Color("2c3a40")), at.x - 0.26, at.x + 0.26, 0.16, 1.08, front)   # the dark inside
	for row in 3:
		var y := 0.2 + row * 0.3
		RoomProps._front(p.st(Color("d8dcd8")), at.x - 0.26, at.x + 0.26, y - 0.02, y, front + 0.002)
		for k in 5:
			var x := at.x - 0.2 + k * 0.1
			RoomProps._cube(p.st(BOTTLE), Vector3(x, y, front - 0.04), Vector3(0.06, 0.17, 0.06))
			RoomProps._cube(p.st(CAP), Vector3(x, y + 0.17, front - 0.04), Vector3(0.065, 0.02, 0.065))
	var frame := p.st(Color("b8c4c8"))
	RoomProps._front(frame, at.x - 0.29, at.x - 0.26, 0.14, 1.1, front + 0.004)   # the glass door's frame
	RoomProps._front(frame, at.x + 0.26, at.x + 0.29, 0.14, 1.1, front + 0.004)
	RoomProps._front(frame, at.x - 0.29, at.x + 0.29, 1.08, 1.11, front + 0.004)
	RoomProps._front(p.glow(Color("fff2c8")), at.x - 0.28, at.x + 0.28, 1.14, 1.26, front + 0.004)   # the lit sign
	RoomProps._front(p.st(Color("3a6ac0")), at.x - 0.2, at.x + 0.2, 1.17, 1.23, front + 0.008)


## Cubbies of rattan baskets for clothes against the back wall: a wooden case, three rows of
## open boxes across its cells, a basket in each, some with a folded towel.
static func _basket_shelf(p: FarmProps.Parts, r: Rect2) -> void:
	var at := Vector3(r.get_center().x, 0, r.position.y + 0.3)
	var wide := r.size.x - 0.12
	RoomProps._cube(p.st("build:planks_dark"), at, Vector3(wide, 1.24, 0.42))
	var front := at.z + 0.21
	var cols := int(r.size.x) * 2
	var cell := wide / cols
	for row in 3:
		var y := 0.08 + row * 0.4
		for k in cols:
			var x := at.x - wide / 2 + (k + 0.5) * cell
			RoomProps._front(p.st(Color("2a2018")), x - cell / 2 + 0.03, x + cell / 2 - 0.03, y, y + 0.34, front)   # the cubby's dark inside
			RoomProps._cube(p.st(RoomProps.STRAW if (row + k) % 3 != 0 else Color("c8a868")), Vector3(x, y, front - 0.04), Vector3(cell - 0.1, 0.18, 0.2), 0.02)
			if (row * 5 + k) % 4 == 0:   # a folded towel in this one
				RoomProps._cube(p.st(Color("f2f0ea")), Vector3(x, y + 0.18, front - 0.04), Vector3(cell - 0.16, 0.05, 0.14))


## A long bench along its cells: a thick plank seat on square legs (along the left wall, pulled to it).
static func _bench(p: FarmProps.Parts, r: Rect2) -> void:
	var thin := 0.38
	var seat := Rect2(r.position.x + 0.08, r.get_center().y - thin / 2, r.size.x - 0.16, thin)
	if r.size.x < r.size.y:
		seat = Rect2(r.position.x + 0.1, r.position.y + 0.08, thin, r.size.y - 0.16)
	var legs := p.st(RoomProps.TIMBER)
	for cx in [seat.position.x + 0.06, seat.end.x - 0.06]:
		for cz in [seat.position.y + 0.08, seat.end.y - 0.08]:
			RoomProps._cube(legs, Vector3(cx, 0, cz), Vector3(0.06, 0.38, 0.06))
	FarmProps.block(p.st("build:planks"), seat, 0.38, seat, 0.44)
	FarmProps.block(p.st("build:planks"), seat, 0.44, seat.grow(-0.02), 0.45)


## The shoe lockers: a dark wooden case of small doors, four across a cell and five up, each with
## a pale wooden key tag.
static func _getabako(p: FarmProps.Parts, r: Rect2) -> void:
	var at := Vector3(r.get_center().x, 0, r.get_center().y - 0.1)
	var wide := r.size.x - 0.1
	RoomProps._cube(p.st("build:planks_dark"), at, Vector3(wide, 1.1, 0.5), 0.02)
	var front := at.z + 0.25
	var cols := int(r.size.x) * 4
	var cell := wide / cols
	for row in 5:
		var y := 0.08 + row * 0.2
		for k in cols:
			var x := at.x - wide / 2 + (k + 0.5) * cell
			RoomProps._front(p.st("build:planks"), x - cell / 2 + 0.015, x + cell / 2 - 0.015, y, y + 0.18, front)
			RoomProps._front(p.st(Color("e0c898")), x - 0.025, x + 0.025, y + 0.06, y + 0.14, front + 0.004)


## The noren in the partition's doorway: two posts, a rod across, the indigo cloth hung from it
## across the way in (the cells run along z, so the cloth faces along x).
static func _noren(w: FarmWorld, p: FarmProps.Parts, r: Rect2) -> void:
	var x := r.get_center().x
	for z in [r.position.y + 0.04, r.end.y - 0.04]:
		RoomProps._cube(p.st(RoomProps.TIMBER), Vector3(x, 0, z), Vector3(0.07, 1.55, 0.07))
	RoomProps._cube(p.st(RoomProps.TIMBER), Vector3(x, 1.46, r.get_center().y), Vector3(0.05, 0.05, r.size.y))
	w._picture("build:noren", Vector2(r.size.y - 0.1, 0.62), Vector3(x, 1.14, r.get_center().y), 90.0)


## The mountain painted on the back wall over the tub, a little proud of its posts and beam.
static func _mural(w: FarmWorld, r: Rect2) -> void:
	w._picture("bath:mural", Vector2(r.size.x - 0.06, 1.04), Vector3(r.get_center().x, 1.08, r.position.y + 1.06))
