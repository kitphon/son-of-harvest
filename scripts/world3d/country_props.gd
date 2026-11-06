class_name CountryProps
extends RefCounted
## The countryside things of the village's outer parts in 3D: a well and a stone jizo in a red
## bib (OutdoorProps), a persimmon and a cherry tree (Trees: their look follows the season), a rice
## drying rack, a stack of firewood, a kitchen garden and a low board fence (FieldProps), all lit
## meshes. Same units as MapWorld (1 unit = 1 cell).

const KINDS: Array[String] = ["well", "jizo", "persimmon", "sakura", "hasa", "woodpile", "garden", "wood_fence"]


## A countryside prop by its kind (MapWorld calls this). `season` picks the trees' and the
## drying rack's look ("" = spring).
static func prop(w: MapWorld, p: Dictionary, mid: Vector3, r: Rect2, season: String) -> void:
	match str(p.kind):
		"well": OutdoorProps.well(w, mid)
		"jizo": OutdoorProps.jizo(w, mid, SnowLayer.map_has_snow(w.map))
		"persimmon", "sakura":
			var parts := FarmProps.Parts.new()
			Trees.broadleaf(parts, mid, str(p.kind), season, int(p.cell[0]) * 31 + int(p.cell[1]) * 17)
			parts.commit(w)
		"hasa": FieldProps.hasa(w, r, mid, season, SnowLayer.map_has_snow(w.map))
		"woodpile": OutdoorProps.woodpile(w, r, mid, SnowLayer.map_has_snow(w.map))
		"garden": FieldProps.garden(w, r, mid, season, SnowLayer.map_has_snow(w.map))
		"wood_fence": FieldProps.board_fence(w, r, mid, SnowLayer.map_has_snow(w.map))
