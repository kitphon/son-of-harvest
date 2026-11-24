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
## `bath_mural` the mountain painted across the back wall over the tub (BathArt), `glass_door` the
## bath's sliding door in a side wall (the changing room's right wall, the bath's left one: a wooden
## frame, frosted panes, half open). The flat view draws them in BathLook.
## Up the gorge (Kajika-yu, data/maps/kajika.json, Baths step 4): `onsen` names the hot spring pool
## in the ground (its water and stony shore are the map's own, look `onsen`: PondShape, SunkenGround;
## the farmer sat in it at ONSEN_WATER, data/baths.json kajika lift), so it builds nothing but its
## steam; `oke` a wooden bathing bucket of pale cypress with two dark hoops, a white towel hung
## over its rim, on a flat mossy stone by the water; `bath_hut` the little cedar changing hut with a hip roof of
## bark and an indigo noren over its doorway; `bamboo_screen` a screen of upright culms bound with
## two black cords (between the hut and the pool). After the user's second photo (2026-11-24):
## `bath_pavilion` the changing house standing at the back of the pool, facing it: a stone base, a
## raised cedar deck along its front, cedar walls with lattice (koshi) panels either side of a dark
## doorway hung with the noren, a gable roof of cedar shingles with its gable to the water, pale
## bargeboards and a dark name board under the gable, two stone steps, its doorway lit at night;
## `yukimi_doro` the snow-viewing lantern with its wide hat, standing on a pale rock out in the water.

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
const ONSEN_WATER := WaterSurface.LIFT - SunkenGround.DROP   # the hot spring's water top, sunk with the map's water (data/baths.json kajika lift)
const CEDAR := BathLook.CEDAR
const BARK := BathLook.BARK
const CULM := BathLook.CULM
const CORD := Color("2a2420")
const OKE := BathLook.OKE
const PAVILION_WOOD := Color("8a6444")
const PAVILION_DARK := Color("4a3424")
const SHINGLE := Color("5a4636")
const BARGE := Color("c8a274")
const GRANITE := GardenLook.GRANITE
const HOOP := Color("3a2c22")
const TOWEL := Color("f2f0ea")


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
static func prop(w: FarmWorld, p: Dictionary, mid: Vector3, r: Rect2, snowy := false) -> void:
	var parts := FarmProps.Parts.new()
	match str(p.kind):
		"onsen": pass   # the pool is the map's ground (look onsen); MapWorld adds its steam
		"bath_hut": _hut(w, parts, r, snowy)
		"bamboo_screen": _screen(parts, r)
		"oke": _oke(parts, r, snowy)
		"bath_pavilion": _pavilion(w, parts, r, snowy)
		"yukimi_doro": _yukimi(w, parts, r, snowy)
		"yubune": _yubune(parts, r)
		"kran": _kran(parts, r)
		"milk_fridge": _milk_fridge(parts, mid)
		"basket_shelf": _basket_shelf(parts, r)
		"bench": _bench(parts, r)
		"getabako": _getabako(parts, r)
		"bath_noren": _noren(w, parts, r)
		"bath_mural": _mural(w, r)
		"glass_door": _glass_door(parts, r)
	parts.commit(w)


## Steam off the tub's water: a few grown Steam nodes over it, each out of step (MapWorld adds
## them after the cached meshes). Returns them (for tests).
static func steam(w: Node3D, r: Rect2, water := WATER, grow := 0.8) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for k in STEAM_PUFFS:
		var s := StallWares.Steam.new(int(r.position.x) * 11 + k * 29)
		s.scale = Vector3.ONE * FootBath.STEAM_SCALE * grow
		s.position = Vector3(r.position.x + r.size.x * (0.15 + 0.7 * k / float(STEAM_PUFFS - 1)), water + 0.12, r.get_center().y + [0.2, -0.1, 0.25, 0.0][k % 4])
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


## The sliding door between the changing room and the bath, standing in its side-wall cell (a door
## cell, so the wall leaves it open): a wooden frame up to the wall's beam, two frosted panes along
## z, the near one slid half over the far one so the way through shows, a pull on each.
static func _glass_door(p: FarmProps.Parts, r: Rect2) -> void:
	var x := r.get_center().x
	var z0 := r.position.y
	var z1 := r.end.y
	var frame := p.st(RoomProps.TIMBER)
	for z in [z0 + 0.03, z1 - 0.03]:
		RoomProps._cube(frame, Vector3(x, 0, z), Vector3(0.12, 1.6, 0.06))
	RoomProps._cube(frame, Vector3(x, 1.52, r.get_center().y), Vector3(0.12, 0.1, r.size.y))
	RoomProps._cube(frame, Vector3(x, 0, r.get_center().y), Vector3(0.14, 0.04, r.size.y))   # the sill's track
	var glass := p.st(Color(0.8, 0.9, 0.92))
	for k in 2:   # the far pane closed at the back, the near one slid behind it: the front half open
		var zc := z0 + 0.3 + k * 0.08
		var off := 0.03 * (1 - 2 * k)
		RoomProps._cube(p.st(RoomProps.WOOD), Vector3(x + off, 0.04, zc), Vector3(0.04, 1.44, 0.5))
		RoomProps._cube(glass, Vector3(x + off + (0.021 if k == 0 else -0.021), 0.12, zc), Vector3(0.006, 1.28, 0.42))
		for y in [0.55, 1.0]:   # the panes' crossbars
			RoomProps._cube(p.st(RoomProps.WOOD), Vector3(x + off, y, zc), Vector3(0.05, 0.03, 0.5))


## The changing hut over its cells: cedar board walls on a stone sill, a hip roof of cedar bark wider
## than the walls, a dark doorway in the front (+z) with the indigo noren over it and baskets on a low
## shelf glimpsed inside. Snow on the roof (`snowy`).
static func _hut(w: FarmWorld, p: FarmProps.Parts, r: Rect2, snowy: bool) -> void:
	var foot := r.grow(-0.12)
	FarmProps.block(p.st(Color(Shrine.STONE)), foot.grow(0.04), 0.0, foot.grow(0.04), 0.08)
	FarmProps.block(p.st(CEDAR), foot, 0.08, foot, 1.5)
	var seams := int(foot.size.x * 4)
	for k in seams:   # the boards' seams on the front
		var x := foot.position.x + (k + 1) * foot.size.x / (seams + 1)
		RoomProps._front(p.st(CEDAR.darkened(0.3)), x - 0.008, x + 0.008, 0.08, 1.5, foot.end.y + 0.002)
	var door := Rect2(r.get_center().x - 0.32, 0.08, 0.64, 1.2)
	RoomProps._front(p.st(Color("1e1814")), door.position.x, door.end.x, door.position.y, door.end.y, foot.end.y + 0.004)
	for k in 3:   # baskets on a low shelf inside
		RoomProps._front(p.st(RoomProps.STRAW), door.position.x + 0.06 + k * 0.19, door.position.x + 0.2 + k * 0.19, 0.3, 0.42, foot.end.y + 0.006)
	var eave := foot.grow(0.22)
	var ridge := Rect2(foot.get_center().x - foot.size.x * 0.3, foot.get_center().y - 0.02, foot.size.x * 0.6, 0.04)
	FarmProps.block(p.st(BARK), eave, 1.5, eave, 1.56)
	FarmProps.block(p.st(BARK.lightened(0.08)), eave, 1.56, ridge, 2.05)
	if snowy:
		FarmProps.block(p.st(FarmProps.Parts.SNOW), eave.grow(-0.02), 1.58, ridge, 2.08)
	w._picture("build:noren", Vector2(0.62, 0.5), Vector3(r.get_center().x, 1.12, foot.end.y + 0.03))


## A screen of upright bamboo culms along its cells (along z when it is longer that way), side by
## side, bound by two black cords.
static func _screen(p: FarmProps.Parts, r: Rect2) -> void:
	var along_z := r.size.y >= r.size.x
	var length := r.size.y if along_z else r.size.x
	var n := int(length / 0.08)
	for k in n:
		var t := (k + 0.5) / n
		var h := 1.3 + 0.06 * ((k * 7) % 3)
		var at := Vector3(r.get_center().x, 0, r.position.y + t * length) if along_z else Vector3(r.position.x + t * length, 0, r.get_center().y)
		RoomProps._cube(p.st(CULM if k % 4 != 0 else CULM.darkened(0.12)), at, Vector3(0.07, h, 0.07))
	for y in [0.45, 1.05]:
		var size := Vector3(0.1, 0.035, length) if along_z else Vector3(length, 0.035, 0.1)
		RoomProps._cube(p.st(CORD), Vector3(r.get_center().x, y, r.get_center().y), size)


## The bathing bucket on its stone: a flat stone (GardenProps.stone, moss on its top), a cypress
## bucket on it (a little wider at the rim), two dark hoops, the rim's lip, and a folded white towel
## hung over the rim on the near side, down the bucket's front. Snow on the stone (`snowy`).
static func _oke(p: FarmProps.Parts, r: Rect2, snowy: bool) -> void:
	var at := Vector3(r.get_center().x, 0.0, r.get_center().y)
	var sn: SurfaceTool = p.st(FarmProps.Parts.SNOW) if snowy else null
	GardenProps.stone(p, sn, at + Vector3(0, -0.02, 0), 0.38, 0.16, 0.32, int(r.position.x) * 13 + int(r.position.y))
	var base := at + Vector3(-0.04, 0.13, -0.02)
	Shrine.lathe(p.st(OKE), base, [Vector2(0.15, 0.0), Vector2(0.18, 0.24)], 12)
	Shrine.lathe(p.st(OKE.darkened(0.25)), base, [Vector2(0.172, 0.21), Vector2(0.172, 0.24), Vector2(0.15, 0.24), Vector2(0.15, 0.03)], 12)   # the rim's lip and the dark inside
	for y in [0.05, 0.17]:
		var rr := lerpf(0.15, 0.18, y / 0.24) + 0.008
		Shrine.lathe(p.st(HOOP), base, [Vector2(rr, y), Vector2(rr, y + 0.025)], 12)
	var towel := p.st(TOWEL)
	RoomProps._cube(towel, base + Vector3(0.0, 0.235, 0.05), Vector3(0.2, 0.025, 0.28))   # folded over the rim
	RoomProps._cube(towel, base + Vector3(0.0, 0.08, 0.19), Vector3(0.2, 0.16, 0.025))    # hanging down its front


## The changing house over its cells, its front (+z) to the pool (see the class note).
static func _pavilion(w: FarmWorld, p: FarmProps.Parts, r: Rect2, snowy: bool) -> void:
	var foot := Rect2(r.position.x + 0.15, r.position.y + 0.1, r.size.x - 0.3, r.size.y - 0.75)
	var deck := Rect2(foot.position.x - 0.05, foot.end.y, foot.size.x + 0.1, 0.42)
	FarmProps.block(p.st(Color(Shrine.STONE)), foot.grow(0.06), 0.0, foot.grow(0.06), 0.3)   # the stone base
	FarmProps.block(p.st(Color(Shrine.STONE)), deck, 0.0, deck, 0.22)
	FarmProps.block(p.st(PAVILION_WOOD.lightened(0.12)), deck, 0.22, deck, 0.3)   # the deck's boards
	for k in 2:   # two stone steps up to it in the middle
		var s := Rect2(r.get_center().x - 0.42, deck.end.y + k * 0.16, 0.84, 0.18)
		FarmProps.block(p.st(Color(Shrine.STONE).lightened(0.06)), s, 0.0, s, 0.2 - k * 0.1)
	var top := 1.85
	FarmProps.block(p.st(PAVILION_WOOD), foot, 0.3, foot, top)   # the walls
	var front := foot.end.y + 0.004
	var cx := r.get_center().x
	# The doorway, dark, the noren over it; the lattice panels either side.
	RoomProps._front(p.st(Color("1c1510")), cx - 0.38, cx + 0.38, 0.3, 1.5, front)
	w._picture("build:noren", Vector2(0.76, 0.42), Vector3(cx, 1.28, front + 0.02))
	for side: float in [-1.0, 1.0]:
		var a0 := cx + side * 0.48
		var a1 := cx + side * (foot.size.x / 2 - 0.12)
		var lo := minf(a0, a1)
		var hi := maxf(a0, a1)
		RoomProps._front(p.st(Color("2a1e16")), lo, hi, 0.55, 1.55, front)   # the dim room behind
		var slats := int((hi - lo) / 0.07)
		for k in slats + 1:   # the koshi's upright slats
			var x := lo + k * (hi - lo) / maxf(slats, 1)
			RoomProps._cube(p.st(PAVILION_WOOD.lightened(0.18)), Vector3(x, 0.55, front + 0.01), Vector3(0.025, 1.0, 0.02))
		RoomProps._cube(p.st(PAVILION_DARK), Vector3((lo + hi) / 2, 0.5, front + 0.012), Vector3(hi - lo + 0.04, 0.06, 0.03))
		RoomProps._cube(p.st(PAVILION_DARK), Vector3((lo + hi) / 2, 1.55, front + 0.012), Vector3(hi - lo + 0.04, 0.06, 0.03))
	for x in [foot.position.x, foot.end.x, cx - 0.42, cx + 0.42]:   # posts on the front
		RoomProps._cube(p.st(PAVILION_DARK), Vector3(x, 0.3, front + 0.015), Vector3(0.08, top - 0.3, 0.05))
	RoomProps._cube(p.st(PAVILION_DARK), Vector3(cx, top - 0.08, front + 0.02), Vector3(foot.size.x + 0.1, 0.1, 0.06))   # the beam
	# The gable roof: its ridge along z, the gable to the front; eaves past the walls.
	var ov := 0.38
	var x0 := foot.position.x - ov
	var x1 := foot.end.x + ov
	var z0 := foot.position.y - 0.3
	var z1 := deck.end.y + 0.12
	var ridge := top + 0.95
	var shingle := p.st(SHINGLE)
	for side in [[x0, cx], [x1, cx]]:
		var ex: float = side[0]
		var a := Vector3(ex, top - 0.05, z0)
		var b := Vector3(ex, top - 0.05, z1)
		var c := Vector3(cx, ridge, z1)
		var d := Vector3(cx, ridge, z0)
		var n := (b - a).cross(c - a).normalized()
		if n.y < 0.0:
			n = -n
		OutdoorProps.tri(shingle, a, b, c, n)
		OutdoorProps.tri(shingle, a, c, d, n)
		OutdoorProps.tri(p.st(SHINGLE.darkened(0.35)), a, c, b, -n)   # its underside
		OutdoorProps.tri(p.st(SHINGLE.darkened(0.35)), a, d, c, -n)
		for k in 4:   # rows of shingles: lighter lines across the slope
			var t := (k + 1) / 5.0
			var q0 := a.lerp(d, t) + n * 0.01
			var q1 := b.lerp(c, t) + n * 0.01
			OutdoorProps.tri(p.st(SHINGLE.lightened(0.15)), q0, q1, q1 + (c - b).normalized() * 0.03, n)
			OutdoorProps.tri(p.st(SHINGLE.lightened(0.15)), q0, q1 + (c - b).normalized() * 0.03, q0 + (d - a).normalized() * 0.03, n)
		if snowy:
			var up := Vector3(0, 0.03, 0)
			OutdoorProps.tri(p.st(FarmProps.Parts.SNOW), a + up, b + up, c + up, Vector3.UP)
			OutdoorProps.tri(p.st(FarmProps.Parts.SNOW), a + up, c + up, d + up, Vector3.UP)
	# The gable's triangle of wall at the front, its bargeboards and the name board.
	var gz := foot.end.y + 0.002
	OutdoorProps.tri(p.st(PAVILION_WOOD.darkened(0.08)), Vector3(foot.position.x, top, gz), Vector3(foot.end.x, top, gz), Vector3(cx, ridge - 0.08, gz), Vector3.BACK)
	for ex: float in [x0, x1]:
		var lo := Vector3(ex, top - 0.1, z1 + 0.01)
		var hi := Vector3(cx, ridge + 0.02, z1 + 0.01)
		var along := (hi - lo).normalized()
		var up := Vector3(-along.y, along.x, 0) * (1.0 if ex < cx else -1.0)
		if up.y < 0.0:
			up = -up
		OutdoorProps.tri(p.st(BARGE), lo, hi, hi + up * 0.1, Vector3.BACK)
		OutdoorProps.tri(p.st(BARGE), lo, hi + up * 0.1, lo + up * 0.1, Vector3.BACK)
	RoomProps._cube(p.st(PAVILION_DARK), Vector3(cx, top + 0.18, gz + 0.03), Vector3(0.9, 0.3, 0.04))   # the name board
	for k in 3:   # its pale letters
		RoomProps._cube(p.st(BARGE.lightened(0.3)), Vector3(cx - 0.24 + k * 0.24, top + 0.25, gz + 0.055), Vector3(0.12, 0.14, 0.01))
	w.lit_lamp(Vector3(cx, 1.0, front + 0.3))   # the doorway's light at night


## The snow-viewing lantern on its rock in the water: a pale rock rising out of the sunk water (the
## pool's own depth there), and on it three short legs, a hexagonal fire box with lit windows,
## the wide hat with its corners turned up, a jewel on top. Lit at night.
static func _yukimi(w: FarmWorld, p: FarmProps.Parts, r: Rect2, snowy: bool) -> void:
	var mid := Vector3(r.get_center().x, 0.0, r.get_center().y)
	var bed := -SunkenGround.DROP
	var sn: SurfaceTool = p.st(FarmProps.Parts.SNOW) if snowy else null
	GardenProps.stone(p, sn, mid + Vector3(0, bed, 0), 0.5, 0.5 - bed, 0.42, int(r.position.x) * 7 + 3, GRANITE, false)
	var base := mid + Vector3(0, 0.46, 0)
	var stone := p.st(GRANITE[2])
	for k in 3:   # three short splayed legs
		var a := TAU * k / 3.0 + 0.3
		var leg := base + Vector3(sin(a), 0, cos(a)) * 0.16
		RoomProps._cube(stone, leg, Vector3(0.07, 0.22, 0.07))
	Shrine.lathe(stone, base + Vector3(0, 0.2, 0), [Vector2(0.24, 0.0), Vector2(0.24, 0.05), Vector2(0.16, 0.08)], 6)   # the deck
	Shrine.lathe(stone, base + Vector3(0, 0.27, 0), [Vector2(0.14, 0.0), Vector2(0.14, 0.24)], 6)   # the fire box
	var apothem := 0.14 * cos(PI / 6)
	for angle in [0.0, 60.0, -60.0]:
		var dir := Vector3(sin(deg_to_rad(angle)), 0, cos(deg_to_rad(angle)))
		var c := base + Vector3(0, 0.39, 0) + dir * (apothem + 0.004)
		var side := Vector3(dir.z, 0, -dir.x)
		var glow := p.st(Color("ffd890"))
		OutdoorProps.tri(glow, c - side * 0.05 - Vector3(0, 0.06, 0), c + side * 0.05 - Vector3(0, 0.06, 0), c + side * 0.05 + Vector3(0, 0.06, 0), dir)
		OutdoorProps.tri(glow, c - side * 0.05 - Vector3(0, 0.06, 0), c + side * 0.05 + Vector3(0, 0.06, 0), c - side * 0.05 + Vector3(0, 0.06, 0), dir)
	var hat := base + Vector3(0, 0.5, 0)
	Shrine.lathe(stone, hat, [Vector2(0.12, 0.0), Vector2(0.52, 0.06), Vector2(0.52, 0.1), Vector2(0.16, 0.24)], 6)   # the wide hat
	for k in 6:   # its corners turned up
		var a := TAU * (k + 0.5) / 6
		RoomProps._cube(stone, hat + Vector3(sin(a), 0, cos(a)) * 0.52 + Vector3(0, 0.06, 0), Vector3(0.07, 0.08, 0.07))
	Shrine.lathe(stone, hat + Vector3(0, 0.23, 0), [Vector2(0.06, 0.0), Vector2(0.07, 0.06), Vector2(0.0, 0.13)], 8)   # the jewel
	if sn != null:
		Shrine.lathe(sn, hat + Vector3(0, 0.02, 0), [Vector2(0.5, 0.1), Vector2(0.15, 0.25)], 6)
	w.lit_lamp(base + Vector3(0, 0.39, 0))
