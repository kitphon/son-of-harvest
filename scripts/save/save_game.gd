class_name SaveGame
extends RefCounted
## Writes the whole run (Game + FarmGrid) to a versioned JSON file and reads it back.
## What the state is stays in Game / FarmGrid (to_dict / from_dict); this file only deals
## with the file and the format version. Reading checks everything before changing anything,
## so a missing or broken file leaves the game as it was.

## 2: animals (Game.animals); 3: affection (Game.affection); 4: the barn and the dog; 5: kitchen
## tools (Game.kitchen_tools); 6: the mine's rope lift landings (Game.mine_landings). Older
## saves load with defaults (the starting flock, everyone a stranger, the new-game fodder and
## dog, the tools of the recipes already known, every landing down to the deepest floor).
const VERSION := 6
const SLOT := "user://save1.json"
## Saving writes <slot>.tmp first and renames it over the slot only once it is whole, so a
## reader (another Godot, a crash mid-write) never sees half a file; the slot it replaces is
## kept as <slot>.bak while it was a good save, and loading falls back to that backup when
## the slot itself is missing or cut off (FEEDBACK item 8).
const TEMP := ".tmp"
const BACKUP := ".bak"


## Returns "" when written, else what went wrong (the old save is then left as it was).
static func write(game, path := SLOT) -> String:
	if game.has_method("finish_swing"):
		game.finish_swing()   # a tool swing in the air lands first, so the save holds its result
	var text := JSON.stringify({"version": VERSION, "game": game.to_dict()}, "\t")
	var temp := path + TEMP
	var f := FileAccess.open(temp, FileAccess.WRITE)
	if f == null:
		return "Could not save (%s)" % error_string(FileAccess.get_open_error())
	f.store_string(text)
	var err := f.get_error()
	f.close()
	if err != OK or FileAccess.get_file_as_string(temp) != text:
		DirAccess.remove_absolute(_abs(temp))
		return "Could not save (the file did not write whole)"
	if FileAccess.file_exists(path) and _parse_one(path)[0] == "":
		DirAccess.copy_absolute(_abs(path), _abs(path + BACKUP))
	err = DirAccess.rename_absolute(_abs(temp), _abs(path))
	if err != OK:
		DirAccess.remove_absolute(_abs(temp))
		return "Could not save (%s)" % error_string(err)
	return ""


## Returns "" when loaded, else what was wrong (and the game is unchanged).
static func read(game, path := SLOT) -> String:
	var parsed := _parse(path)
	if parsed[0] != "":
		return parsed[0]
	return game.from_dict(parsed[1], parsed[2])


## Would `read` succeed? Returns "" or what is wrong, without touching `game`: the file is
## loaded into a scratch Game that shares the game's data tables (crops, foods, tools, the
## mine...), then thrown away. (It used to share only the crops, so every save holding a
## food failed here with "Saved food is broken" and the title turned Continue off.)
static func check(game, path := SLOT) -> String:
	var parsed := _parse(path)
	if parsed[0] != "":
		return parsed[0]
	var scratch: Node = game.get_script().new()
	for key in game.DATA_TABLES:
		scratch.set(key, game.get(key))
	scratch.farm = FarmGrid.new(game.crops)
	var err: String = scratch.from_dict(parsed[1], parsed[2])
	scratch.free()
	return err


## "" or a note for the title screen when Continue will load the backup: the slot itself is
## missing or broken but its backup is good.
static func backup_note(path := SLOT) -> String:
	var own: String = _parse_one(path)[0]
	if own == "" or _parse_one(path + BACKUP)[0] != "":
		return ""
	if own == "No saved game":
		return "The last save is missing; Continue loads the one before it"
	return "The last save is cut off; Continue loads the one before it"


## [error, the saved game's dictionary, its version] from the slot, or from its backup when
## the slot is missing or broken and the backup is good; error "" when it is usable.
static func _parse(path: String) -> Array:
	var parsed := _parse_one(path)
	if parsed[0] == "" or str(parsed[0]).begins_with("The save file is from a newer"):
		return parsed
	var backup := _parse_one(path + BACKUP)
	return backup if backup[0] == "" else parsed


## The same for one file, no backup.
static func _parse_one(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return ["No saved game", null, 0]
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return ["The save file is cut off or broken", null, 0]
	var data: Dictionary = json.data
	var version = whole(data.get("version"), 1, 1 << 30)
	if version == null:
		return ["The save file has no version", null, 0]
	if version > VERSION:
		return ["The save file is from a newer version (%d)" % version, null, 0]
	if not data.get("game") is Dictionary:
		return ["The save file is cut off or broken", null, 0]
	return ["", data.game, version]


## A whole number in [lo, hi] from parsed JSON (numbers come back as floats), else null.
static func whole(v: Variant, lo: int, hi: int) -> Variant:
	if not (v is int or v is float) or v != floorf(v) or v < lo or v > hi:
		return null
	return int(v)


## Every file of a slot (the save, its backup, a left-over temp file) as {path: text}, the
## missing ones as null; `restore` puts them back. Tests that must write the real slot use it.
static func snapshot(path := SLOT) -> Dictionary:
	var snap := {}
	for p in [path, path + BACKUP, path + TEMP]:
		snap[p] = FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else null
	return snap


static func restore(snap: Dictionary) -> void:
	for p in snap:
		if snap[p] == null:
			if FileAccess.file_exists(p):
				DirAccess.remove_absolute(_abs(p))
		else:
			var f := FileAccess.open(p, FileAccess.WRITE)
			f.store_string(snap[p])
			f.close()


static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path)
