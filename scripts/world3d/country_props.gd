class_name CountryProps
extends RefCounted
## The countryside things of the village's outer parts in 3D: a well, a stone jizo in a red
## bib, a persimmon and a cherry tree (Trees: their look follows the season), a rice drying rack, a
## stack of firewood, a kitchen garden and a low board fence. Same placeholder surfaces and
## units as MapWorld (1 unit = 1 cell).

const TIMBER := Color("4a3424")
const STONE := Color("8e8a80")
const KINDS: Array[String] = ["well", "jizo", "persimmon", "sakura", "hasa", "woodpile", "garden", "wood_fence"]


## A countryside prop by its kind (MapWorld calls this). `season` picks the trees' and the
## drying rack's look ("" = spring).
static func prop(w: MapWorld, p: Dictionary, mid: Vector3, r: Rect2, season: String) -> void:
	var timber := FarmWorld.flat_material(TIMBER)
	var stone := FarmWorld.flat_material(STONE)
	match str(p.kind):
		"well":
			# A stone well curb, dark water inside, two posts with a little board roof and a
			# crossbar with a pulley, a wooden bucket on the rim.
			_cyl(w, 0.38, 0.4, 0.5, mid + Vector3(0, 0.25, 0), stone, 12)
			_cyl(w, 0.3, 0.3, 0.02, mid + Vector3(0, 0.46, 0), FarmWorld.flat_material(Color("1e2a30")), 12)
			for x in [-0.36, 0.36]:
				w._box(Vector3(0.07, 1.3, 0.07), mid + Vector3(x, 0.65, 0), timber)
			w._box(Vector3(0.8, 0.05, 0.05), mid + Vector3(0, 1.05, 0), timber)
			_cyl(w, 0.07, 0.07, 0.04, mid + Vector3(0, 1.0, 0.0), FarmWorld.flat_material(Color("6a5a48")), 8)
			for side in [-1, 1]:
				w._box(Vector3(0.95, 0.04, 0.45), mid + Vector3(0, 1.38, 0.17 * side), FarmWorld.surface_material("build:planks_dark"), Vector3(0.45 * side, 0, 0))
				w._snow_top(Vector3(0.9, 0.03, 0.4), mid + Vector3(0, 1.42, 0.17 * side), Vector3(0.45 * side, 0, 0))
			_cyl(w, 0.09, 0.08, 0.14, mid + Vector3(0.24, 0.57, 0.22), FarmWorld.flat_material(Color("9a7048")), 8)
		"jizo":
			# A small stone jizo on a block: a round body and head, a red cloth bib.
			w._box(Vector3(0.34, 0.12, 0.3), mid + Vector3(0, 0.06, 0), stone)
			_cyl(w, 0.11, 0.13, 0.32, mid + Vector3(0, 0.28, 0), stone, 10)
			var head := SphereMesh.new()
			head.radius = 0.1
			head.height = 0.2
			_mesh(w, head, mid + Vector3(0, 0.52, 0), stone)
			w._box(Vector3(0.2, 0.12, 0.04), mid + Vector3(0, 0.36, 0.12), FarmWorld.flat_material(Color("c8342c")))
			w._snow_top(Vector3(0.14, 0.03, 0.14), mid + Vector3(0, 0.62, 0))
		"persimmon", "sakura":
			var parts := FarmProps.Parts.new()
			Trees.broadleaf(parts, mid, str(p.kind), season, int(p.cell[0]) * 31 + int(p.cell[1]) * 17)
			parts.commit(w)
		"hasa":
			# A rice drying rack (hasa-kake) along its cells: poles, two rails; sheaves of golden
			# straw hung over the rails in fall.
			var long := r.size.x
			for i in int(long) + 1:
				w._box(Vector3(0.07, 1.4, 0.07), Vector3(r.position.x + clampf(i, 0.15, long - 0.15), 0.7, mid.z), timber)
			for y in [0.75, 1.2]:
				w._box(Vector3(long - 0.2, 0.05, 0.05), mid + Vector3(0, y, 0), timber)
			if season == "fall":
				var straw := FarmWorld.flat_material(Color("d8b85a"))
				var n := int(long * 4)
				for i in n:
					var x := r.position.x + 0.2 + (long - 0.4) * (i + 0.5) / n
					for y in [0.75, 1.2]:
						w._box(Vector3(0.18, 0.4, 0.16), Vector3(x, y - 0.18, mid.z), straw)
		"woodpile":
			# Split firewood stacked under a lean-to board roof.
			var log_mat := FarmWorld.flat_material(Color("8a6440"))
			var ends := FarmWorld.flat_material(Color("c8a478"))
			for row in 3:
				for i in int(r.size.x * 3) - row:
					var x := r.position.x + 0.2 + (i + row * 0.5) * 0.3
					var at := Vector3(x, 0.1 + row * 0.17, mid.z)
					_cyl(w, 0.09, 0.09, 0.6, at, log_mat, 6, Vector3(PI / 2, 0, 0))
					w._box(Vector3(0.15, 0.15, 0.01), at + Vector3(0, 0, 0.3), ends)
			w._box(Vector3(r.size.x, 0.04, 0.8), mid + Vector3(0, 0.75, -0.05), FarmWorld.surface_material("build:planks_dark"), Vector3(-0.25, 0, 0))
			w._snow_top(Vector3(r.size.x - 0.05, 0.03, 0.75), mid + Vector3(0, 0.79, -0.05), Vector3(-0.25, 0, 0))
		"garden":
			# A kitchen garden: a low bed of dark earth with rows of greens (bare in winter).
			w._box(Vector3(r.size.x - 0.1, 0.1, r.size.y - 0.1), mid + Vector3(0, 0.05, 0), FarmWorld.flat_material(Color("6a4a30")))
			if season != "winter":
				var leaf := FarmWorld.flat_material(Color("5a9a3a") if season != "fall" else Color("7a9a3a"))
				for row in int(r.size.y * 2):
					for i in int(r.size.x * 3):
						var at := Vector3(r.position.x + 0.2 + i * 0.32, 0.16, r.position.y + 0.25 + row * 0.5)
						w._box(Vector3(0.16, 0.12, 0.16), at, leaf, Vector3(0, 0.6 * ((i + row) % 3), 0))
		"wood_fence":
			# A low cedar board fence along its cells (x or z, by its size).
			var along_x: bool = r.size.x >= r.size.y
			var long: float = r.size.x if along_x else r.size.y
			var boards := FarmWorld.surface_material("build:planks")
			for i in int(long) + 1:
				var t := clampf(i, 0.1, long - 0.1)
				var at := Vector3(r.position.x + t, 0.35, mid.z) if along_x else Vector3(mid.x, 0.35, r.position.y + t)
				w._box(Vector3(0.08, 0.7, 0.08), at, timber)
			for y in [0.22, 0.5]:
				var size := Vector3(long, 0.12, 0.04) if along_x else Vector3(0.04, 0.12, long)
				w._box(size, mid + Vector3(0, y, 0), boards)


static func _cyl(w: MapWorld, top: float, bottom: float, height: float, at: Vector3, mat: Material, segments: int, rot := Vector3.ZERO) -> void:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = segments
	var mi := _mesh(w, c, at, mat)
	mi.rotation = rot


static func _mesh(w: MapWorld, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	w.add_child(mi)
	return mi
