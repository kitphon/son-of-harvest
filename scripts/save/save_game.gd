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
	if not FileAccess.file_exists(path):
		return "No saved game"
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return "The save file is broken"
	var data: Dictionary = json.data
	var version = whole(data.get("version"), 1, 1 << 30)
	if version == null:
		return "The save file has no version"
	if version > VERSION:
		return "The save file is from a newer version (%d)" % version
	if not data.get("game") is Dictionary:
		return "The save file is broken"
	return game.from_dict(data.game)


## A whole number in [lo, hi] from parsed JSON (numbers come back as floats), else null.
static func whole(v: Variant, lo: int, hi: int) -> Variant:
	if not (v is int or v is float) or v != floorf(v) or v < lo or v > hi:
		return null
	return int(v)
