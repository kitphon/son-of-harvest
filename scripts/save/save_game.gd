class_name SaveGame
extends RefCounted
## Writes the whole run (Game + FarmGrid) to a versioned JSON file and reads it back.
## What the state is stays in Game / FarmGrid (to_dict / from_dict); this file only deals
## with the file and the format version. Reading checks everything before changing anything,
## so a missing or broken file leaves the game as it was.

const VERSION := 1
const SLOT := "user://save1.json"


## Returns "" when written, else what went wrong.
static func write(game, path := SLOT) -> String:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return "Could not save (%s)" % error_string(FileAccess.get_open_error())
	f.store_string(JSON.stringify({"version": VERSION, "game": game.to_dict()}, "\t"))
	f.close()
	return ""


## Returns "" when loaded, else what was wrong (and the game is unchanged).
static func read(game, path := SLOT) -> String:
	var parsed := _parse(path)
	if parsed[0] != "":
		return parsed[0]
	return game.from_dict(parsed[1])


## Would `read` succeed? Returns "" or what is wrong, without touching `game`: the file is
## loaded into a scratch Game that shares only the crop data, then thrown away.
static func check(game, path := SLOT) -> String:
	var parsed := _parse(path)
	if parsed[0] != "":
		return parsed[0]
	var scratch: Node = game.get_script().new()
	scratch.crops = game.crops
	scratch.farm = FarmGrid.new(game.crops)
	var err: String = scratch.from_dict(parsed[1])
	scratch.free()
	return err


## [error, the saved game's dictionary] read from the file, error "" when it is usable.
static func _parse(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return ["No saved game", null]
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return ["The save file is broken", null]
	var data: Dictionary = json.data
	var version = whole(data.get("version"), 1, 1 << 30)
	if version == null:
		return ["The save file has no version", null]
	if version > VERSION:
		return ["The save file is from a newer version (%d)" % version, null]
	if not data.get("game") is Dictionary:
		return ["The save file is broken", null]
	return ["", data.game]


## A whole number in [lo, hi] from parsed JSON (numbers come back as floats), else null.
static func whole(v: Variant, lo: int, hi: int) -> Variant:
	if not (v is int or v is float) or v != floorf(v) or v < lo or v > hi:
		return null
	return int(v)
