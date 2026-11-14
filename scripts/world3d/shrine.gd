class_name Shrine
extends RefCounted
## The shrine pieces as real meshes (MapWorld calls these for the map props): a vermilion
## torii whose black top beam curves up to its ends, a small hokora under a board gable roof
## with crossed chigi, and a six-sided stone lantern (a Kasuga-style toro) turned on a lathe
## with flat facets. Same units as the farm: 1 unit = 1 cell. Built with Minka's helpers.

const VERMILION := Color("c8442c")
const BLACK := Color("2a2420")
const STONE := Color("9a968e")


## A torii over the shrine path across `r` (the posts on its end cells, at mid.z): two tapered
## posts on black footings, the tie beam (nuki) through them, a short strut with a name plaque,
## and the top beams: the vermilion shimaki under the black kasagi, both rising `curl` from the
## middle to their ends with the square of the way out (the torii's soft upward sweep).
## `kuroki`: a black-wood torii instead (posts and beams of dark unpainted wood, the top beam
## straight), the kind that stands in a bamboo grove (the village's little shrine, data/maps/town.json).
static func torii(w: FarmWorld, mid: Vector3, r: Rect2, kuroki := false) -> void:
	var red := Minka.plain(Color("4a3a2e") if kuroki else VERMILION)
	var black := Minka.plain(Color("2a221c") if kuroki else BLACK)
	var span := r.size.x - 1.0
	for x in [r.position.x + 0.5, r.end.x - 0.5]:
		_cylinder(w, 0.085, 0.11, 2.05, Vector3(x, 1.025, mid.z), red)
		_cylinder(w, 0.13, 0.15, 0.22, Vector3(x, 0.11, mid.z), black)
	w._box(Vector3(span + 0.56, 0.12, 0.14), Vector3(mid.x, 1.6, mid.z), red)    # nuki
	for x in [mid.x - span / 2 - 0.2, mid.x + span / 2 + 0.2]:                    # wedges by the posts
		w._box(Vector3(0.06, 0.14, 0.16), Vector3(x, 1.6, mid.z), red)
	w._box(Vector3(0.1, 0.34, 0.1), Vector3(mid.x, 1.84, mid.z), red)            # strut (gakuzuka)
	w._box(Vector3(0.3, 0.36, 0.04), Vector3(mid.x, 1.84, mid.z + 0.07), black)  # plaque
	w._box(Vector3(0.22, 0.28, 0.02), Vector3(mid.x, 1.84, mid.z + 0.09), Minka.plain(Color("c8a050")))
	var curl := 0.0 if kuroki else 0.16
	var half := span / 2 + 0.65
	var lift := func(x: float) -> float:
		var t := absf(x - mid.x) / half
		return curl * t * t
	var xs: Array[float] = []
	for i in 13:
		xs.append(mid.x - half + 2.0 * half * i / 12.0)
	var shimaki: Array[float] = []
	for x in xs:
		if absf(x - mid.x) <= span / 2 + 0.45:
			shimaki.append(x)
	var beams := SurfaceTool.new()
	var cap := SurfaceTool.new()
	var snow := SurfaceTool.new()
	for st in [beams, cap, snow]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Minka.beam(beams, shimaki, lift, 2.0, mid.z, 0.1, 0.0, 0.16)
	Minka.beam(cap, xs, lift, 2.0, mid.z, 0.15, 0.16, 0.11)
	Minka.beam(snow, xs, lift, 2.0, mid.z, 0.13, 0.27, 0.03)
	Minka.add_mesh(w, beams, red)
	Minka.add_mesh(w, cap, black)
	_snow(w, snow)


## A hokora (a small wayside shrine) at `mid`: a two-step stone base, a cedar body with two
## vermilion doors and a straw rope (shimenawa) with paper streamers across the front, under a
## dark board gable roof (Minka.gable) with crossed chigi at the ridge ends and two logs
## (katsuogi) across the ridge.
static func hokora(w: FarmWorld, mid: Vector3) -> void:
	var stone := Minka.plain(Color("8a8680"))
	w._box(Vector3(1.6, 0.16, 1.4), mid + Vector3(0, 0.08, 0), stone)
	w._box(Vector3(1.3, 0.14, 1.1), mid + Vector3(0, 0.23, 0), stone)
	# The roof first, so the body can rise to its soffit: eaves 0.2 past the body all round,
	# 1.1 high at the eaves, rising 0.65 a unit (a steep little roof).
	var body := Vector2(1.0, 0.8)
	var low := 1.1
	var pitch := 0.65
	var eave := Rect2(mid.x - body.x / 2 - 0.2, mid.z - body.y / 2 - 0.2, body.x + 0.4, body.y + 0.4)
	var crest := Minka.gable(w, eave, low, pitch, 0.07, "build:planks_dark", "build:planks_dark")
	var wall := low + 0.2 * pitch
	var apex := low + eave.size.y / 2 * pitch
	w._box(Vector3(body.x, wall - 0.3, body.y), mid + Vector3(0, 0.3 + (wall - 0.3) / 2, 0),
		FarmWorld.surface_material("build:sugi"))
	for x in [mid.x - body.x / 2 - 0.002, mid.x + body.x / 2 + 0.002]:
		Minka.gable_wall(w, x, mid.z - body.y / 2, mid.z + body.y / 2, wall, apex, "build:sugi", signf(x - mid.x))
	var front := mid.z + body.y / 2
	var red := Minka.plain(VERMILION)
	var gold := Minka.plain(Color("c8a050"))
	for side in [-1.0, 1.0]:
		w._box(Vector3(0.22, 0.5, 0.03), Vector3(mid.x + side * 0.12, 0.66, front + 0.01), red)
		w._box(Vector3(0.04, 0.04, 0.02), Vector3(mid.x + side * 0.04, 0.66, front + 0.03), gold)
	w._box(Vector3(0.52, 0.04, 0.04), Vector3(mid.x, 0.93, front + 0.02), Minka.plain(BLACK))   # lintel
	# The shimenawa: a fat straw rope under the eave, three zigzag paper streamers hanging.
	w._box(Vector3(body.x + 0.08, 0.07, 0.07), Vector3(mid.x, 1.08, front + 0.06), Minka.plain(Color("c8b078")))
	var paper := Minka.plain(Color("f4f0e6"))
	for x in [-0.3, 0.0, 0.3]:
		for k in 3:
			w._box(Vector3(0.06, 0.06, 0.01), Vector3(mid.x + x + (0.02 if k % 2 else -0.02), 1.0 - k * 0.06, front + 0.1), paper)
	# Ridge: a dark beam, chigi crossed at both ends, two katsuogi logs lying across.
	var wood := Minka.plain(Color("3a2c22"))
	w._box(Vector3(eave.size.x + 0.04, 0.07, 0.12), Vector3(mid.x, crest + 0.02, mid.z), wood)
	for end in [-1.0, 1.0]:
		var x: float = mid.x + end * (eave.size.x / 2 - 0.02)
		for lean in [-1.0, 1.0]:
			w._box(Vector3(0.03, 0.34, 0.07), Vector3(x, crest + 0.1, mid.z + lean * 0.07), wood,
				Vector3(lean * atan(pitch), 0, 0))
	for x in [-0.2, 0.2]:
		_cylinder(w, 0.045, 0.045, 0.26, Vector3(mid.x + x, crest + 0.1, mid.z), gold, Vector3(PI / 2, 0, 0))


## A Kasuga-style stone lantern (toro) at `mid`, six-sided: the footing, a round post, the
## middle deck, the fire box with warm windows on the two faces the camera sees, the wide
## sloping cap with its corners turned up, and the jewel on top. Each part is a lathe profile
## (radius, height) turned with flat facets.
static func stone_lantern(w: FarmWorld, mid: Vector3) -> void:
	var stone := Minka.plain(STONE)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	lathe(st, mid, [Vector2(0.27, 0.0), Vector2(0.27, 0.08), Vector2(0.2, 0.14), Vector2(0.11, 0.16)], 6)   # footing
	lathe(st, mid, [Vector2(0.09, 0.14), Vector2(0.08, 0.6)], 8)                                             # post
	lathe(st, mid, [Vector2(0.1, 0.58), Vector2(0.22, 0.66), Vector2(0.22, 0.72), Vector2(0.17, 0.74)], 6)  # deck
	lathe(st, mid, [Vector2(0.15, 0.74), Vector2(0.15, 0.98)], 6)                                            # fire box
	lathe(st, mid, [Vector2(0.15, 0.97), Vector2(0.33, 1.0), Vector2(0.33, 1.04), Vector2(0.1, 1.16)], 6)   # cap
	lathe(st, mid, [Vector2(0.06, 1.15), Vector2(0.07, 1.2), Vector2(0.06, 1.25), Vector2(0.0, 1.3)], 8)   # jewel
	Minka.add_mesh(w, st, stone)
	# Windows in the faces turned to the camera (+z and the next face round towards +x).
	var glow := FarmWorld.flat_material(Color("ffd890"))
	var apothem := 0.15 * cos(PI / 6)
	for angle in [0.0, 60.0]:
		var dir := Vector3(sin(deg_to_rad(angle)), 0, cos(deg_to_rad(angle)))
		w._box(Vector3(0.1, 0.12, 0.01), mid + Vector3(0, 0.86, 0) + dir * (apothem + 0.004), glow,
			Vector3(0, deg_to_rad(angle), 0))
	w.lit_lamp(LitSpots.lantern(mid))
	# The cap's corners turned up: a little curl of stone at each of the six.
	for k in 6:
		var a := TAU * (k + 0.5) / 6
		w._box(Vector3(0.05, 0.06, 0.05), mid + Vector3(sin(a), 0, cos(a)) * 0.33 + Vector3(0, 1.06, 0), stone)
	var snow := SurfaceTool.new()
	snow.begin(Mesh.PRIMITIVE_TRIANGLES)
	lathe(snow, mid, [Vector2(0.32, 1.06), Vector2(0.1, 1.18)], 6)
	_snow(w, snow)


## Turns `profile` (radius, height from the bottom up) round `at` with `sides` flat facets, the
## corners half a facet off +z, so with six sides one face looks straight down +z. A radius of 0
## ends in a point; a bottom or top with a radius is closed.
static func lathe(st: SurfaceTool, at: Vector3, profile: Array, sides: int) -> void:
	var none := func(_p: Vector3) -> Vector2: return Vector2.ZERO
	var corner := func(r: float, y: float, k: int) -> Vector3:
		var a := TAU * (k + 0.5) / sides
		return at + Vector3(sin(a) * r, y, cos(a) * r)
	for i in profile.size() - 1:
		var p: Vector2 = profile[i]
		var q: Vector2 = profile[i + 1]
		for k in sides:
			var a := TAU * (k + 1.0) / sides   # the facet's middle direction
			var out := Vector3(sin(a), 0, cos(a))
			var n := (out * (q.y - p.y) + Vector3.UP * (p.x - q.x)).normalized()
			var a0: Vector3 = corner.call(p.x, p.y, k)
			var a1: Vector3 = corner.call(p.x, p.y, k + 1)
			var b0: Vector3 = corner.call(q.x, q.y, k)
			var b1: Vector3 = corner.call(q.x, q.y, k + 1)
			if q.x > 0.0001:
				Minka.quad(st, a0, a1, b1, b0, n, none)
			else:
				Minka.tri(st, a0, a1, b0, n, none)
	for end in [0, profile.size() - 1]:
		var e: Vector2 = profile[end]
		if e.x < 0.0001:
			continue
		var n := Vector3.DOWN if end == 0 else Vector3.UP
		for k in sides:
			Minka.tri(st, at + Vector3(0, e.y, 0), corner.call(e.x, e.y, k), corner.call(e.x, e.y, k + 1), n, none)


static func _cylinder(w: FarmWorld, top: float, bottom: float, high: float, at: Vector3,
		mat: Material, rot := Vector3.ZERO) -> void:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = high
	m.radial_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = at
	mi.rotation = rot
	w.add_child(mi)


## A snow cover made in `st`: SnowLayer's top shader, kept with the world's snow, no shadow.
static func _snow(w: FarmWorld, st: SurfaceTool) -> void:
	var mat := SnowLayer.top_material()
	w._snow_mats.append(mat)
	Minka.add_mesh(w, st, mat).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
