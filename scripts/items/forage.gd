class_name Forage
extends RefCounted
## Wild things to pick (data/forage.json): fixed spots on a map, what grows on each one by
## the season ("wild:<id>" items), and which spots were picked today. A picked spot is back
## the next morning (Game clears `picked` in end_day). Pure rules on plain data, no drawing:
## Game keeps the picked spots and saves them, ForageLayer / ForageView draw what grows.
## Format: README.md, Forage.

const PATH := "res://data/forage.json"
const PREFIX := "wild:"

static var _data: Variant = null


static func data() -> Dictionary:
	if _data == null:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		if not d is Dictionary:
			push_error("Forage: can't read " + PATH)
			d = {}
		_data = d
	return _data


## A wild item's data ({} for anything that isn't "wild:<id>").
static func item(id: String) -> Dictionary:
	return data().get("items", {}).get(id.trim_prefix(PREFIX), {}) if id.begins_with(PREFIX) else {}


## The spots of map `map_id`: [{cell: Vector2i, spring?, summer?, fall?, winter?}].
static func spots(map_id: String) -> Array:
	var out := []
	for s in data().get("spots", {}).get(map_id, []):
		var spot: Dictionary = s.duplicate()
		spot.cell = Vector2i(int(s.cell[0]), int(s.cell[1]))
		out.append(spot)
	return out


## What grows on map `map_id` in `season` and has not been picked: cell -> "wild:<id>".
## `picked` is the map's picked cells (Vector2i -> true).
static func growing(map_id: String, season: String, picked: Dictionary = {}) -> Dictionary:
	var out := {}
	for s in spots(map_id):
		var id := str(s.get(season, ""))
		if id != "" and not picked.has(s.cell):
			out[s.cell] = PREFIX + id
	return out
