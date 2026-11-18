class_name PondPlantRules
extends RefCounted
## Irises and lily pads in and round the farm pond (data/pond_plants.json; 2026-11-18, the
## user: the farm pond looked plain). Pure: which spots a map has, what each looks like on a day
## (its picture's key, or "" when it is not there), and where it stands. PondPlantLayer (3D) and
## FarmView (flat) draw them; PondPlantArt paints the pictures.

const PATH := "res://data/pond_plants.json"
const KINDS: Array[String] = ["iris", "lily"]   # reeds tried and taken out (2026-11-18, the user: their spiky clumps did not look good)

static var _cfg: Dictionary = {}


static func data() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _cfg


## The spots on map `map_id`: [{kind, pos: Vector2 (cells), variant}], irises before pads.
static func spots(map_id: String, cfg: Dictionary = {}) -> Array:
	var c := cfg if not cfg.is_empty() else data()
	var here: Dictionary = (c.ponds as Dictionary).get(map_id, {})
	var out: Array = []
	for kind in KINDS:
		var list: Array = here.get(kind, [])
		for i in list.size():
			out.append({"kind": kind, "pos": Vector2(float(list[i][0]), float(list[i][1])), "variant": i})
	return out


## Whether day `day` of `season` lies in one of `windows` ([[season, first, last], ...]).
static func in_window(windows: Array, season: String, day: int) -> bool:
	for w in windows:
		if str(w[0]) == season and day >= int(w[1]) and day <= int(w[2]):
			return true
	return false


## The stage of `kind` in `season` ("" when it is not there).
static func stage(kind: String, season: String, cfg: Dictionary = {}) -> String:
	var c := cfg if not cfg.is_empty() else data()
	return str((c.seasons[kind] as Dictionary).get(season, ""))


## Whether `spot` flowers on day `day` of `season`: an iris in its window; a pad in its window
## when its variant is one of `flower`.
static func flowers(spot: Dictionary, season: String, day: int, cfg: Dictionary = {}) -> bool:
	var c := cfg if not cfg.is_empty() else data()
	var windows: Array = (c.bloom as Dictionary).get(spot.kind, [])
	if not in_window(windows, season, day):
		return false
	return spot.kind != "lily" or int(spot.variant) in (c.flower as Array).map(func(v): return int(v))


## The picture of `spot` on day `day` of `season`: pondplant:<kind>:<stage>:<variant>, the stage
## "bloom" for a flowering one; "" when nothing shows.
static func key(spot: Dictionary, season: String, day: int, cfg: Dictionary = {}) -> String:
	var st := stage(spot.kind, season, cfg)
	if st == "":
		return ""
	if flowers(spot, season, day, cfg):
		st = "bloom"
	return "pondplant:%s:%s:%d" % [spot.kind, st, int(spot.variant) % PondPlantArt.VARIANTS]
