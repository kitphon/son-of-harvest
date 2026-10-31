class_name MapManager
extends RefCounted
## Which map the farmer is on and where they stand (player pixels, 16 per cell, and facing).
## Map files are read from data/maps/<id>.json once and shared. Game owns one of these
## (Game.maps), changes it through Game.go_to_map() and saves it; the views read it.

const DIR := "res://data/maps/"
const FARM := "farm"
const HOME := "house"           # where the farmer wakes up (its "home" spawn)
const T := 16

static var _cache: Dictionary = {}   # id -> MapData (null when the file is missing or broken)

var id := FARM
var pos := cell_pos(Vector2i(4, 4))  # the farmer's feet; the Player writes it as it walks
var facing := Vector2i.DOWN
## The mine floor laid out on this map while the farmer is down the mine (null elsewhere):
## its rocks are solid and its open hole is a door. Not saved (Game.to_dict).
var mine_floor: MineFloor = null


## The map with this id, or null (with an error printed) when there is no usable file.
static func data(map_id: String) -> MapData:
	if not _cache.has(map_id):
		var r := load_map(map_id)
		if r[0] != "":
			push_error("Map %s: %s" % [map_id, r[0]])
		_cache[map_id] = r[1]
	return _cache[map_id]


## Is there a map file with this id?
static func has(map_id: String) -> bool:
	return map_id != "" and FileAccess.file_exists(DIR + map_id + ".json")


## [error, MapData] read from data/maps/<id>.json, without the cache (for checks).
static func load_map(map_id: String) -> Array:
	var path := DIR + map_id + ".json"
	if map_id == "" or not FileAccess.file_exists(path):
		return ["no file " + path, null]
	var r := MapData.parse(JSON.parse_string(FileAccess.get_file_as_string(path)))
	if r[0] == "" and r[1].id != map_id:
		return ["the file's id is " + r[1].id, null]
	return r


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
	return current().is_solid(c) or (mine_floor != null and mine_floor.is_solid(c))


func door_at(c: Vector2i) -> Dictionary:
	var door := current().door_at(c)
	if door.is_empty() and mine_floor != null:
		return mine_floor.door_at(c)
	return door


## Footstep kind for a cell on this map, "" to let Sfx decide by the farm ground.
func step_at(c: Vector2i) -> String:
	return "" if on_farm() else current().step(c)


## The saved part: {id, x, y, facing} (pixels as whole numbers).
func to_dict() -> Dictionary:
	return {"id": id, "x": roundi(pos.x), "y": roundi(pos.y), "facing": [facing.x, facing.y]}


## [error, {id, pos, facing}] checked from saved data, nothing changed yet.
static func check_saved(v: Variant) -> Array:
	if not v is Dictionary:
		return ["Saved map is broken", null]
	var known: bool = v.get("id") is String and has(v.id)
	var m := data(v.id) if known else null
	if m == null:
		return ["Saved map is unknown", null]
	var x = SaveGame.whole(v.get("x"), 0, m.w * T - 1)
	var y = SaveGame.whole(v.get("y"), 0, m.h * T - 1)
	var f = MapData._cell(v.get("facing"))
	if x == null or y == null or not f in MapData.FACINGS.values():
		return ["Saved map position is broken", null]
	return ["", {"id": m.id, "pos": Vector2(x, y), "facing": f}]
