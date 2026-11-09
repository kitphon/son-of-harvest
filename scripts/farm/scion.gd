class_name Scion
extends RefCounted
## Kiku's persimmon twig growing (pure rules, data/scion.json). It is planted once the farmer
## chose its place in her band 6 scene (kiku_scion = door / field); the scene's date step keeps
## that day in kiku_scion_day. The tree's stage is the last of the data's stages whose
## from_days the days since then have reached. A save from before the day was kept has none:
## record() gives it the day it is first seen (a load, a morning, a demo run's flags), so the
## tree starts as a sapling then. Both views draw art_key (StoryView.art_key, StoryProps).

const PATH := "res://data/scion.json"
const FLAG := "kiku_scion"

static var _data: Variant = null


static func rules() -> Dictionary:
	if _data == null:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		_data = d if d is Dictionary else {}
	return _data


static func day_flag() -> String:
	return str(rules().get("day_flag", "kiku_scion_day"))


## Whether the twig stands planted (the farmer picked a place).
static func planted(flags: Dictionary) -> bool:
	var v: Variant = flags.get(FLAG, "")
	return v is String and v != ""


## Gives a planted twig without a planting day (an old save, `--flags=kiku_scion=door`) today
## as that day. True when it did.
static func record(flags: Dictionary, today: int) -> bool:
	if not planted(flags) or flags.get(day_flag()) is int:
		return false
	flags[day_flag()] = today
	return true


## Days since it was planted (0 on the day; today when no day is kept).
static func age(flags: Dictionary, today: int) -> int:
	var d: Variant = flags.get(day_flag())
	return maxi(today - (int(d) if d is int else today), 0)


## The stage's id for this many days since planting.
static func stage_at(days: int) -> String:
	var out := "sapling"
	for s in rules().get("stages", []):
		if days >= int(s.from_days):
			out = str(s.id)
	return out


static func stage(flags: Dictionary, today: int) -> String:
	return stage_at(age(flags, today))


static func stage_ids() -> Array:
	return rules().get("stages", []).map(func(s): return str(s.id))


## The first day (since planting) of a stage, -1 when there is no such stage.
static func from_days(id: String) -> int:
	for s in rules().get("stages", []):
		if str(s.id) == id:
			return int(s.from_days)
	return -1


## The picture's size in px (w, h).
static func size(id: String) -> Vector2i:
	for s in rules().get("stages", []):
		if str(s.id) == id:
			return Vector2i(int(s.size[0]), int(s.size[1]))
	return Vector2i(16, 26)


## Persimmons hang on it: a fruiting stage in the fruit season.
static func fruits(id: String, season: String) -> bool:
	return id in rules().get("fruit", []) and season == str(rules().get("fruit_season", "fall"))


## Snow on its winter branches with this much snow lying (0..100).
static func snowy(season: String, cover: int) -> bool:
	return season == "winter" and cover >= int(rules().get("snow_cover", 30))


## story:scion:<stage>:<season>:<snow 0|1>, PlaceholderArt's picture of it.
static func art_key(id: String, season: String, snow: bool) -> String:
	return "story:scion:%s:%s:%d" % [id, season, 1 if snow else 0]
