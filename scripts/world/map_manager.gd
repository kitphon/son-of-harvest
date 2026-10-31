class_name MapManager
extends RefCounted
## Which map the farmer is on and where they stand (player pixels, 16 per cell, and facing).
## Map files are read from data/maps/<id>.json once and shared, with the house extensions
## that are built applied (a file's "extensions"; Game sets `built`). Game owns one of these
## (Game.maps), changes it through Game.go_to_map() and saves it; the views read it.

const DIR := "res://data/maps/"
const FARM := "farm"
const HOME := "house"           # where the farmer wakes up (its "home" spawn)
const T := 16

static var _cache: Dictionary = {}   # id -> MapData (null when the file is missing or broken)
static var built: Array[String] = []  # extensions in effect (data/shops.json builds; Game.house_built)

var id := FARM
var pos := cell_pos(Vector2i(4, 4))  # the farmer's feet; the Player writes it as it walks
var facing := Vector2i.DOWN


## The map with this id, or null (with an error printed) when there is no usable file.
static func data(map_id: String) -> MapData:
	if not _cache.has(map_id):
		var r := load_map(map_id)
		if r[0] != "":
			push_error("Map %s: %s" % [map_id, r[0]])
		_cache[map_id] = r[1]
	return _cache[map_id]


## Puts these extensions in effect; the maps are read again when it changes something.
static func set_built(list: Array) -> void:
	var want: Array[String] = []
	want.assign(list)
	if want != built:
		built = want
		_cache.clear()


## Is there a map file with this id?
static func has(map_id: String) -> bool:
	return map_id != "" and FileAccess.file_exists(DIR + map_id + ".json")


## [error, MapData] read from data/maps/<id>.json, without the cache (for checks), with the
## extensions `ext` (default: the ones in effect) applied.
static func load_map(map_id: String, ext: Variant = null) -> Array:
	var path := DIR + map_id + ".json"
	if map_id == "" or not FileAccess.file_exists(path):
		return ["no file " + path, null]
	var raw = JSON.parse_string(FileAccess.get_file_as_string(path))
	var r := MapData.parse(with_extensions(raw, built if ext == null else ext))
	if r[0] == "" and r[1].id != map_id:
		return ["the file's id is " + r[1].id, null]
	return r


## A map file's data with the extensions in `ext` applied, in the file's order: their props
## are added, any other key replaces the map's own. The "extensions" key itself goes.
static func with_extensions(raw: Variant, ext: Array) -> Variant:
	if not raw is Dictionary or not raw.get("extensions") is Dictionary:
		return raw
	var out: Dictionary = raw.duplicate(true)
	out.erase("extensions")
	for key in raw.extensions:
		var patch = raw.extensions[key]
		if not key in ext or not patch is Dictionary:
			continue
		for k in patch:
			if k == "props":
				var props: Array = out.get("props", []).duplicate()
				props.append_array(patch.props.duplicate(true))
				out.props = props
			else:
				out[k] = patch[k].duplicate(true) if patch[k] is Array or patch[k] is Dictionary else patch[k]
	return out


## Every map id with a file in data/maps.
static func ids() -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".json"):
			out.append(f.get_basename())
	return out


## Where the farmer's feet go on a cell: the middle, a little towards the bottom edge.
static func cell_pos(c: Vector2i) -> Vector2:
	return Vector2(c.x * T + 8, c.y * T + 10)


func current() -> MapData:
	return data(id)


func on_farm() -> bool:
	return id == FARM


func place(map_id: String, cell: Vector2i, face: Vector2i) -> void:
	id = map_id
	pos = cell_pos(cell)
	facing = face


## Is the cell blocked on the current map? The farm asks its FarmGrid.
func is_solid(c: Vector2i, farm: FarmGrid) -> bool:
	if on_farm():
		return farm.is_solid(c)
	return current().is_solid(c)


func door_at(c: Vector2i) -> Dictionary:
	return current().door_at(c)


## Footstep kind for a cell on this map, "" to let Sfx decide by the farm ground.
func step_at(c: Vector2i) -> String:
	return "" if on_farm() else current().step(c)


## The saved part: {id, x, y, facing} (pixels as whole numbers).
func to_dict() -> Dictionary:
	return {"id": id, "x": roundi(pos.x), "y": roundi(pos.y), "facing": [facing.x, facing.y]}


## [error, {id, pos, facing}] checked from saved data, nothing changed yet. `ext`: the
## extensions the save has built (default: the ones in effect).
static func check_saved(v: Variant, ext: Variant = null) -> Array:
	if not v is Dictionary:
		return ["Saved map is broken", null]
	var known: bool = v.get("id") is String and has(v.id)
	var m: MapData = null
	if known:
		m = data(v.id) if ext == null else load_map(v.id, ext)[1]
	if m == null:
		return ["Saved map is unknown", null]
	var x = SaveGame.whole(v.get("x"), 0, m.w * T - 1)
	var y = SaveGame.whole(v.get("y"), 0, m.h * T - 1)
	var f = MapData._cell(v.get("facing"))
	if x == null or y == null or not f in MapData.FACINGS.values():
		return ["Saved map position is broken", null]
	return ["", {"id": m.id, "pos": Vector2(x, y), "facing": f}]
