class_name FarmProps
extends RefCounted
## The small things by the farmhouse as real meshes (FarmWorld builds them): the shipping bin,
## the storage chest and the seed stand. Each is made of tapered blocks (`block`: flat faces,
## bevelled lids, splayed sides) and lathe-turned shapes (Shrine.lathe) in lit materials, so
## the sun shapes them like the buildings. Same units as the farm: 1 unit = 1 cell.

const WOOD := Color("3a2c22")    # dark posts and battens
const IRON := Color("26221f")
const STRAW := Color("c8b078")


## Shipping bin (cell 8, 3): a cedar box a little wider at the top, on two runners, dark corner
## battens, a straw rope tied round its middle with a knot and a paper tag on the front, under a
## thick plank lid with bevelled edges and two battens across.
static func bin(w: FarmWorld) -> void:
	var p := Parts.new()
	for z in [3.22, 3.78]:   # runners, their ends cut back at the top
		block(p.st("build:planks_dark"), Rect2(8.04, z - 0.05, 0.92, 0.1), 0.0, Rect2(8.08, z - 0.05, 0.84, 0.1), 0.07)
	block(p.st("build:sugi"), Rect2(8.1, 3.15, 0.8, 0.7), 0.07, Rect2(8.07, 3.12, 0.86, 0.76), 0.58)
	for x in [8.07, 8.93]:   # corner battens, standing a hair proud of the splayed corners
		for z in [3.12, 3.88]:
			var c := Vector2(x - signf(x - 8.5) * 0.015, z - signf(z - 3.5) * 0.015)
			block(p.st("build:planks_dark"), Rect2(c.x - 0.035, c.y - 0.035, 0.07, 0.07), 0.07,
				Rect2(c.x - 0.035 + signf(x - 8.5) * 0.015, c.y - 0.035 + signf(z - 3.5) * 0.015, 0.07, 0.07), 0.58)
	var rope := p.st(STRAW)
	block(rope, Rect2(8.065, 3.115, 0.87, 0.77), 0.35, Rect2(8.06, 3.11, 0.88, 0.78), 0.41)
	block(rope, Rect2(8.58, 3.88, 0.1, 0.04), 0.33, Rect2(8.59, 3.88, 0.08, 0.05), 0.43)   # the knot
	for lean in [-1.0, 1.0]:   # its two ends hanging
		var foot := Vector2(8.63 + lean * 0.05, 3.9)
		block(rope, Rect2(foot.x - 0.015, foot.y, 0.03, 0.025), 0.2, Rect2(8.62 + lean * 0.01, 3.89, 0.03, 0.025), 0.34)
	block(p.st(Color("f2ece0")), Rect2(8.33, 3.885, 0.12, 0.012), 0.18, Rect2(8.33, 3.885, 0.12, 0.012), 0.34)   # tag
	block(p.st(Color("b83a2a")), Rect2(8.36, 3.896, 0.06, 0.004), 0.23, Rect2(8.36, 3.896, 0.06, 0.004), 0.29)
	var lid := p.st("build:planks")
	var rim := Rect2(8.03, 3.08, 0.94, 0.84)
	block(lid, rim, 0.58, rim, 0.64)
	block(lid, rim, 0.64, rim.grow(-0.08), 0.7)
	for x in [8.25, 8.75]:
		block(p.st("build:planks_dark"), Rect2(x - 0.04, 3.17, 0.08, 0.66), 0.7, Rect2(x - 0.035, 3.18, 0.07, 0.64), 0.74)
	block(p.st(Parts.SNOW), rim.grow(-0.01), 0.645, rim.grow(-0.09), 0.765)
	p.commit(w)


## Storage chest (cell 7, 3, FarmGrid.CHEST), by the house wall: a low cedar tansu on a dark
## plinth, two drawers with black iron pulls (warabite) on the front, iron corner plates
## wrapping the corners the camera sees and a handle on the +x side, under a bevelled lid.
static func chest(w: FarmWorld) -> void:
	var p := Parts.new()
	block(p.st("build:planks_dark"), Rect2(7.13, 3.22, 0.78, 0.56), 0.0, Rect2(7.14, 3.23, 0.76, 0.54), 0.08)
	block(p.st("build:sugi"), Rect2(7.15, 3.24, 0.74, 0.52), 0.08, Rect2(7.15, 3.24, 0.74, 0.52), 0.54)
	var iron := p.st(IRON)
	for y in [0.2, 0.41]:   # drawer fronts, a pull on each: a round plate and a hanging bar
		block(p.st("build:planks"), Rect2(7.2, 3.76, 0.64, 0.02), y - 0.09, Rect2(7.21, 3.76, 0.62, 0.02), y + 0.09)
		block(iron, Rect2(7.48, 3.78, 0.08, 0.012), y - 0.01, Rect2(7.48, 3.78, 0.08, 0.012), y + 0.05)
		block(iron, Rect2(7.45, 3.79, 0.14, 0.02), y - 0.04, Rect2(7.45, 3.79, 0.14, 0.02), y - 0.015)
	# Corner plates down both front edges, the right one wrapping round onto the +x face.
	for r in [Rect2(7.145, 3.755, 0.06, 0.015), Rect2(7.835, 3.755, 0.06, 0.015), Rect2(7.89, 3.69, 0.012, 0.08)]:
		block(iron, r, 0.08, r, 0.54)
	block(iron, Rect2(7.89, 3.44, 0.012, 0.12), 0.27, Rect2(7.89, 3.44, 0.012, 0.12), 0.35)   # side handle
	block(iron, Rect2(7.9, 3.42, 0.02, 0.16), 0.24, Rect2(7.9, 3.42, 0.02, 0.16), 0.27)
	var rim := Rect2(7.12, 3.21, 0.8, 0.58)
	block(p.st("build:planks_dark"), rim, 0.54, rim, 0.58)
	block(p.st("build:planks_dark"), rim, 0.58, rim.grow(-0.05), 0.61)
	block(p.st(Parts.SNOW), rim.grow(-0.01), 0.585, rim.grow(-0.06), 0.635)
	p.commit(w)


## Seed stand (cell 10, 3): a roadside stall under a small board gable roof (Minka.gable) on
## four posts, tie beams and a ridge board; an indigo noren under the front eave, a price board
## on the +x side; on the plank counter, three open seed sacks (turned, with their seeds
## showing and a cord round the neck) and a little honesty box with a coin slot.
static func stand(w: FarmWorld) -> void:
	var p := Parts.new()
	# Roof: eaves 1.45 high at the front (z 4.12, clear of the farmer at the counter), rising
	# 0.5 a unit to a ridge along x at z 3.65.
	var eave := Rect2(9.92, 3.18, 1.16, 0.94)
	var crest := Minka.gable(w, eave, 1.45, 0.5, 0.05, "build:planks_dark", "build:planks_dark")
	var post := p.st(WOOD)
	for x in [10.06, 10.94]:
		for z in [3.28, 4.0]:
			block(post, Rect2(x - 0.035, z - 0.035, 0.07, 0.07), 0.0, Rect2(x - 0.035, z - 0.035, 0.07, 0.07), 1.52)
		block(post, Rect2(x - 0.03, 3.24, 0.06, 0.82), 1.42, Rect2(x - 0.03, 3.24, 0.06, 0.82), 1.5)   # tie beam
		block(post, Rect2(x - 0.025, 3.62, 0.05, 0.06), 1.5, Rect2(x - 0.025, 3.63, 0.05, 0.04), 1.69)   # king post
	for z in [3.28, 4.0]:   # beams along the front (the noren hangs from it) and back
		block(post, Rect2(10.0, z - 0.03, 1.0, 0.06), 1.42, Rect2(10.0, z - 0.03, 1.0, 0.06), 1.5)
	block(post, Rect2(9.96, 3.61, 1.08, 0.08), 1.62, Rect2(9.96, 3.62, 1.08, 0.06), 1.69)   # ridge beam
	block(post, Rect2(9.9, 3.57, 1.2, 0.16), crest - 0.02, Rect2(9.9, 3.62, 1.2, 0.06), crest + 0.06)   # ridge board
	# Counter: a plank top over a cedar front and side.
	block(p.st("build:planks"), Rect2(10.01, 3.3, 0.98, 0.69), 0.6, Rect2(10.0, 3.29, 1.0, 0.71), 0.66)
	block(p.st("build:sugi"), Rect2(10.08, 3.9, 0.84, 0.05), 0.1, Rect2(10.08, 3.9, 0.84, 0.05), 0.6)
	block(p.st("build:sugi"), Rect2(10.9, 3.32, 0.05, 0.6), 0.1, Rect2(10.9, 3.32, 0.05, 0.6), 0.6)
	block(p.st("build:planks_dark"), Rect2(10.08, 3.32, 0.84, 0.6), 0.08, Rect2(10.08, 3.32, 0.84, 0.6), 0.12)
	# Seed sacks: burlap, open at the top, a cord round the neck, the seeds heaped inside.
	var seeds := [Color("e8d8a8"), Color("c9a26b"), Color("b8c890")]
	var burlap := [Color("b0946a"), Color("a08660"), Color("bca274")]
	for i in 3:
		var at := Vector3(10.24 + i * 0.26, 0.66, 3.52 + (0.04 if i == 1 else 0.0))
		Shrine.lathe(p.st(burlap[i]), at, [Vector2(0.08, 0.0), Vector2(0.11, 0.05), Vector2(0.105, 0.12),
			Vector2(0.075, 0.17), Vector2(0.07, 0.19), Vector2(0.09, 0.23)], 8)
		Shrine.lathe(p.st(Color("5a4630")), at, [Vector2(0.077, 0.165), Vector2(0.077, 0.19)], 8)
		Shrine.lathe(p.st(seeds[i]), at, [Vector2(0.085, 0.215), Vector2(0.0, 0.25)], 8)
	# Honesty box: a cedar box with a dark coin slot in its lid.
	block(p.st("build:sugi"), Rect2(10.74, 3.8, 0.16, 0.12), 0.66, Rect2(10.75, 3.81, 0.14, 0.1), 0.79)
	block(p.st(IRON), Rect2(10.78, 3.85, 0.08, 0.02), 0.79, Rect2(10.78, 3.85, 0.08, 0.02), 0.795)
	p.commit(w)
	w._picture("build:noren", Vector2(0.84, 0.24), Vector3(10.5, 1.3, 4.035))
	w._picture("build:stand_sign", Vector2(0.5, 0.3), Vector3(10.97, 1.08, 3.64), 90)


## A tapered block: the rectangle `lo` (x, z) at height `y0` up to `hi` at `y1`, each face flat
## and turned out from the middle, the sides' UVs in world units (u along the edge, v down) so
## the planks run level, the top's (x, z). Equal rectangles make a box; a smaller `hi` a bevel.
static func block(st: SurfaceTool, lo: Rect2, y0: float, hi: Rect2, y1: float) -> void:
	var a := [Vector3(lo.position.x, y0, lo.position.y), Vector3(lo.end.x, y0, lo.position.y),
		Vector3(lo.end.x, y0, lo.end.y), Vector3(lo.position.x, y0, lo.end.y)]
	var b := [Vector3(hi.position.x, y1, hi.position.y), Vector3(hi.end.x, y1, hi.position.y),
		Vector3(hi.end.x, y1, hi.end.y), Vector3(hi.position.x, y1, hi.end.y)]
	var mid := (lo.get_center() + hi.get_center()) / 2.0
	for k in 4:
		var a0: Vector3 = a[k]
		var a1: Vector3 = a[(k + 1) % 4]
		var b0: Vector3 = b[k]
		var b1: Vector3 = b[(k + 1) % 4]
		var n := (a1 - a0).cross(b0 - a0).normalized()
		var face := (a0 + a1 + b0 + b1) / 4.0
		if n.dot(Vector3(face.x - mid.x, 0, face.z - mid.y)) < 0.0:
			n = -n
		var along := (a1 - a0).normalized()
		Minka.quad(st, a0, a1, b1, b0, n,
			func(q: Vector3) -> Vector2: return Vector2((q - a0).dot(along), y1 - q.y))
	var flat := func(q: Vector3) -> Vector2: return Vector2(q.x, q.z)
	Minka.quad(st, b[0], b[1], b[2], b[3], Vector3.UP, flat)
	Minka.quad(st, a[0], a[1], a[2], a[3], Vector3.DOWN, flat)


## One SurfaceTool per material, made into meshes at the end: a "build:<name>" key is a lit
## PlaceholderArt surface (UVs in world units), a Color a lit plain colour, SNOW the snow top,
## and `glow(color)` an unshaded colour that casts no shadow (embers, flames, lit paper).
class Parts:
	const SNOW := "snow"
	const GLOW := "glow:"
	var _tools := {}

	func glow(color: Color) -> SurfaceTool:
		return st(GLOW + color.to_html(false))

	func st(key: Variant) -> SurfaceTool:
		if not _tools.has(key):
			var t := SurfaceTool.new()
			t.begin(Mesh.PRIMITIVE_TRIANGLES)
			_tools[key] = t
		return _tools[key]

	func commit(w: FarmWorld) -> void:
		for key in _tools:
			var mi := Minka.add_mesh(w, _tools[key], material(key, w._snow_mats))
			if not casts_shadow(key):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	## The meshes by key, without placing them (for a MultiMesh: the wood past the edge).
	func meshes() -> Dictionary:
		var out := {}
		for key in _tools:
			out[key] = _tools[key].commit()
		return out

	## The material for a key; a snow material goes into `snow_mats` (set_snow drives it).
	static func material(key: Variant, snow_mats: Array[ShaderMaterial]) -> Material:
		if key is Color:
			return Minka.plain(key)
		if key == SNOW:
			var snow := SnowLayer.top_material()
			snow_mats.append(snow)
			return snow
		if key.begins_with(GLOW):
			return FarmWorld.flat_material(Color(key.substr(GLOW.length())))
		return FarmWorld.picture_material(key)

	static func casts_shadow(key: Variant) -> bool:
		return not (key is String and (key == SNOW or key.begins_with(GLOW)))
