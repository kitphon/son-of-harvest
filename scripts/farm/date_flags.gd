class_name DateFlags
extends RefCounted
## Flags that are set on a morning once the date has passed (pure rules, data/date_flags.json).
## A row names a flag and the date it is set after (`after`: season and day). From the next day
## on, in that year and every later one, the flag is set on the morning, so an event that waits
## for the farmer to be somewhere on that day (triggers_minamino.json) still has a fallback when
## they were never there. Game's morning calls day_start after the date has moved on.

const PATH := "res://data/date_flags.json"
const GameRules := preload("res://scripts/autoload/game.gd")   # SEASONS

static var _data: Variant = null


static func rows() -> Array:
	if _data == null:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		_data = d if d is Dictionary else {}
	return _data.get("rows", [])


## A date's place in the year, by season then day (-1 for an unknown season).
static func position(season: String, day: int) -> int:
	var i: int = GameRules.SEASONS.find(season)
	return i * 100 + day if i >= 0 else -1


## Whether `row`'s date is past on this day. Year 1 is the first time it can come round, so any
## later year is past too.
static func passed(row: Dictionary, year: int, season: String, day: int) -> bool:
	var a: Dictionary = row.get("after", {})
	var at := position(str(a.get("season", "")), int(a.get("day", 0)))
	if at < 0:
		return false
	return year > 1 or position(season, day) > at


## Sets each flag whose date has passed (not cleared once set). Called each morning.
static func day_start(flags: Dictionary, year: int, season: String, day: int) -> void:
	for row in rows():
		var flag := str(row.get("flag", ""))
		if flag != "" and passed(row, year, season, day) and not EventRunner.is_set(flags, flag):
			flags[flag] = true
