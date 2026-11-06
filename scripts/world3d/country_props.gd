class_name CountryProps
extends RefCounted
## The countryside things of the village's outer parts in 3D: a well and a stone jizo in a red
## bib (OutdoorProps), a persimmon and a cherry tree (Trees: their look follows the season), a rice drying rack, a
## stack of firewood, a kitchen garden and a low board fence. Same placeholder surfaces and
## units as MapWorld (1 unit = 1 cell).

const TIMBER := Color("4a3424")
const KINDS: Array[String] = ["well", "jizo", "persimmon", "sakura", "hasa", "woodpile", "garden", "wood_fence"]


## A countryside prop by its kind (MapWorld calls this). `season` picks the trees' and the
## drying rack's look ("" = spring).
static func prop(w: MapWorld, p: Dictionary, mid: Vector3, r: Rect2, season: String) -> void:
	var timber := FarmWorld.flat_material(TIMBER)
	match str(p.kind):
		"well": OutdoorProps.well(w, mid)
		"jizo": OutdoorProps.jizo(w, mid, SnowLayer.map_has_snow(w.map))
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
		"woodpile": OutdoorProps.woodpile(w, r, mid, SnowLayer.map_has_snow(w.map))
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
