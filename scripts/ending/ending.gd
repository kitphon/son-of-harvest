class_name Ending
extends RefCounted
## The village record: grades the farmer's first two years from data/ending.json. Pure rules,
## no drawing: Game.ending_values() measures the run, `grade` turns the numbers into stars,
## a rank and the closing speaker, EndingScreen shows it. DESIGN lists the ending as not
## studied yet, so the categories, steps and titles are all ours.

const PATH := "res://data/ending.json"
const MEASURES: Array[String] = ["shipped_value", "crop_kinds", "animal_care", "heart_bands",
	"mine_deepest", "fish_kinds", "house_built", "tool_levels", "contest_wins", "recipes_known"]
const ELDER := "tome"   # the closing speaker when nobody is close enough

static var _data := {}


## data/ending.json, read once.
static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = d if d is Dictionary else {}
	return _data


## Stars for `value`: one for every step reached.
static func stars(value: int, steps: Array) -> int:
	var n := 0
	for s in steps:
		if value >= int(s):
			n += 1
	return n


## The rank index for `total` stars: the last rank whose min is reached.
static func rank_of(total: int, d := data()) -> int:
	var r := 0
	var ranks: Array = d.get("ranks", [])
	for i in ranks.size():
		if total >= int(ranks[i].min):
			r = i
	return r


## Who closes the ending: the villager with the most points if their band is at least
## friend_band (ties: the first id in sorted order), else the elder.
static func friend(points: Dictionary, d := data()) -> String:
	var best := ""
	var ids := points.keys()
	ids.sort()
	for id in ids:
		if best == "" or int(points[id]) > int(points[best]):
			best = id
	if best == "" or Affection.band_of(int(points[best])) < int(d.get("friend_band", 3)):
		return ELDER
	return best


## The record for measured `values` (measure -> number) and affection `points`:
## {rows: [{id, name, value, unit, stars, max}], stars, max, rank, title, friend}.
static func grade(values: Dictionary, points: Dictionary, d := data()) -> Dictionary:
	var rows: Array[Dictionary] = []
	var total := 0
	var most := 0
	for c in d.get("categories", []):
		var v := int(values.get(c.measure, 0))
		var s := stars(v, c.steps)
		rows.append({"id": c.id, "name": c.name, "value": v, "unit": String(c.get("unit", "")),
			"stars": s, "max": c.steps.size()})
		total += s
		most += c.steps.size()
	var r := rank_of(total, d)
	return {"rows": rows, "stars": total, "max": most, "rank": r,
		"title": String(d.ranks[r].title) if not d.get("ranks", []).is_empty() else "",
		"friend": friend(points, d)}


## A row's number as shown: thousands split with commas, then the unit.
static func value_text(row: Dictionary) -> String:
	var digits := str(int(row.get("value", 0)))
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0 and digits[i - 1] != "-":
			out += ","
		out += digits[i]
	var unit := String(row.get("unit", ""))
	return out + (" " + unit if unit != "" else "")


## "" when `d` is a record we can grade, else what is wrong with it.
static func check(d: Dictionary) -> String:
	if not d.get("categories") is Array or d.categories.is_empty():
		return "no categories"
	var seen := {}
	for c in d.categories:
		if not c is Dictionary or not c.get("id") is String or seen.has(c.id):
			return "a category needs its own id"
		seen[c.id] = true
		if not c.get("name") is String or c.name == "":
			return "%s has no name" % c.id
		if not c.get("measure") in MEASURES:
			return "%s measures nothing we know" % c.id
		if not c.get("steps") is Array or c.steps.is_empty():
			return "%s has no steps" % c.id
		var last := -1
		for s in c.steps:
			if not (s is float or s is int) or int(s) <= last:
				return "%s's steps must rise" % c.id
			last = int(s)
	if not d.get("ranks") is Array or d.ranks.is_empty() or int(d.ranks[0].get("min", -1)) != 0:
		return "the first rank starts at 0"
	var low := -1
	for r in d.ranks:
		if not r.get("title") is String or int(r.get("min", -1)) <= low:
			return "ranks need titles and rising mins"
		low = int(r.min)
	return ""
