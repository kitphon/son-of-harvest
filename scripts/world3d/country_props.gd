class_name CountryProps
extends RefCounted
## The countryside things of the village's outer parts in 3D: a well and a stone jizo in a red
## bib (OutdoorProps), a persimmon, a cherry and a maple tree (Trees: their look follows the season; the cherry
## and maple in leaf with a swaying crown, Trees.place_crowned), a rice
## drying rack, a stack of firewood, a kitchen garden, a low board fence (FieldProps) and Ichiro's
## charcoal kiln, Shige's little hen barn and the ditch behind his beds (OutdoorProps), all lit
## meshes. Same units as MapWorld (1 unit = 1 cell).

const KINDS: Array[String] = ["well", "jizo", "persimmon", "sakura", "maple", "ginkgo", "hasa", "woodpile", "garden", "wood_fence", "kiln", "hen_barn", "ditch"]


## A countryside prop by its kind (MapWorld calls this). `season` picks the trees' and the
## drying rack's look ("" = spring).
static func prop(w: MapWorld, p: Dictionary, mid: Vector3, r: Rect2, season: String) -> void:
	match str(p.kind):
		"well": OutdoorProps.well(w, mid)
		"jizo": OutdoorProps.jizo(w, mid, SnowLayer.map_has_snow(w.map))
		"persimmon", "sakura", "maple", "ginkgo":
			var seed := int(p.cell[0]) * 31 + int(p.cell[1]) * 17
			var scale := float(p.get("scale", 1.0))   # a map's trees of mixed sizes (data/maps: Nishiki Hill)
			if Trees.crowned(str(p.kind), season):   # in leaf or bloom: the swaying crown (the cherry grand)
				Trees.place_crowned(w, mid, str(p.kind), season, seed, scale)
				return
			var parts := FarmProps.Parts.new()
			Trees.broadleaf(parts, Vector3.ZERO, str(p.kind), season, seed, SnowLayer.map_has_snow(w.map))
			var first := w.get_child_count()
			parts.commit(w)
			for n in w.get_children().slice(first):   # the bare tree, built at the origin, set on its cell at its size
				(n as Node3D).transform = Transform3D(Basis.from_scale(Vector3(scale, scale, scale)), mid)
		"hasa": FieldProps.hasa(w, r, mid, season, SnowLayer.map_has_snow(w.map))
		"woodpile": OutdoorProps.woodpile(w, r, mid, SnowLayer.map_has_snow(w.map))
		"garden": FieldProps.garden(w, r, mid, season, SnowLayer.map_has_snow(w.map))
		"wood_fence": FieldProps.board_fence(w, r, mid, SnowLayer.map_has_snow(w.map))
		"kiln": OutdoorProps.kiln(w, r, mid, SnowLayer.map_has_snow(w.map))
		"hen_barn": OutdoorProps.hen_barn(w, r, SnowLayer.map_has_snow(w.map))
		"ditch": OutdoorProps.ditch(w, r, SnowLayer.map_has_snow(w.map))
