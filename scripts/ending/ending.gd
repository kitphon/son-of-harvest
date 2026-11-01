class_name Ending
extends RefCounted
## The village record: grades the farmer's first two years from data/ending.json, and again
## each New Year after (a yearly page). Pure rules, no drawing: Game.ending_values() measures
## the run, `grade` turns the numbers into stars, a rank and the closing speaker, `compare`
## puts the first day's numbers and the gain since the last page beside them, EndingScreen
## shows it. DESIGN lists the ending as not studied yet, so the categories, steps and titles
## are all ours.

const PATH := "res://data/ending.json"
const MEASURES: Array[String] = ["shipped_value", "crop_kinds", "animal_care", "heart_bands",
	"neighbours_known", "mine_deepest", "fish_kinds", "house_built", "tool_levels", "contest_wins", "recipes_known"]
## The field's numbers, kept the first day and on every page (Game.field_counts()).
const FIELD_MEASURES: Array[String] = ["debris", "tilled", "money"]
const PAGES: Array[String] = ["ending", "year"]
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


## The record with the look back put beside it: every category row gets `then` (its number
## on the first day, -1 when not known) and `gain` (since the `last` page, null without one);
## `field` rows (data/ending.json field: the field's numbers then and now, no stars) follow
## the same shape. `first` = {values, field} kept on the first day, `last` = the latest
## earlier page ({year, values, field, stars, rank}) or {}; `field_now` = Game.field_counts().
## Adds {field, first (no earlier page), last_year, gained_stars}.
static func compare(record: Dictionary, first: Dictionary, last: Dictionary, field_now: Dictionary, d := data()) -> Dictionary:
	var r := record.duplicate(true)
	var cats := {}
	for c in d.get("categories", []):
		cats[c.id] = c.measure
	for row in r.rows:
		_beside(row, cats.get(row.id, ""), first.get("values", {}), last.get("values", {}), not last.is_empty())
	var field: Array[Dictionary] = []
	for f in d.get("field", []):
		var row := {"id": f.id, "name": f.name, "value": int(field_now.get(f.measure, 0)),
			"unit": String(f.get("unit", ""))}
		_beside(row, f.measure, first.get("field", {}), last.get("field", {}), not last.is_empty())
		field.append(row)
	r.field = field
	r.first = last.is_empty()
	r.last_year = int(last.get("year", 0))
	r.gained_stars = int(r.stars) - int(last.get("stars", 0)) if not last.is_empty() else int(r.stars)
	return r


static func _beside(row: Dictionary, measure: String, then: Dictionary, last: Dictionary, has_last: bool) -> void:
	row.then = int(then[measure]) if then.has(measure) else -1
	row.gain = int(row.value) - int(last[measure]) if has_last and last.has(measure) else null


## What a page keeps in the save: {year, values, field, stars, rank}.
static func page_of(year: int, values: Dictionary, field: Dictionary, record: Dictionary) -> Dictionary:
	return {"year": year, "values": values.duplicate(), "field": field.duplicate(),
		"stars": int(record.stars), "rank": int(record.rank)}


## The latest page in `pages` (year -> page) from before `year`, or {}.
static func last_page(pages: Dictionary, year: int) -> Dictionary:
	var best := 0
	for y in pages:
		if int(y) < year and int(y) > best:
			best = int(y)
	return pages.get(best, {})


## A row's number as shown: thousands split with commas, then the unit.
static func value_text(row: Dictionary) -> String:
	return number_text(int(row.get("value", 0)), String(row.get("unit", "")))


## The first day's number of a row ("-" when not known, for saves from before it was kept).
static func then_text(row: Dictionary) -> String:
	var t := int(row.get("then", -1))
	return "-" if t < 0 else number_text(t, String(row.get("unit", "")))


## The gain since the last page: "+1,200", "-3", "" with no change or no last page.
static func gain_text(row: Dictionary) -> String:
	var g: Variant = row.get("gain")
	if g == null or int(g) == 0:
		return ""
	return ("+" if int(g) > 0 else "-") + number_text(absi(int(g)), "")


static func number_text(value: int, unit := "") -> String:
	var digits := str(value)
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0 and digits[i - 1] != "-":
			out += ","
		out += digits[i]
	return out + (" " + unit if unit != "" else "")


## {values, field} or a page as loaded from a save: [error, the clean copy]. `page` also
## needs year, stars and rank. Measures we don't know are refused, missing ones left out.
static func parse_kept(v: Variant, page: bool) -> Array:
	if not v is Dictionary or not v.get("values") is Dictionary or not v.get("field") is Dictionary:
		return ["broken", {}]
	var out := {"values": {}, "field": {}}
	for part in [["values", MEASURES], ["field", FIELD_MEASURES]]:
		for k in v[part[0]]:
			var n = SaveGame.whole(v[part[0]][k], 0, 1 << 50)
			if not k in part[1] or n == null:
				return ["broken", {}]
			out[part[0]][k] = n
	if page:
		for k in ["year", "stars", "rank"]:
			var n = SaveGame.whole(v.get(k), 0 if k != "year" else 1, 9999)
			if n == null:
				return ["broken", {}]
			out[k] = n
	return ["", out]


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
	var fields := {}
	for f in d.get("field", []):
		if not f is Dictionary or not f.get("id") is String or fields.has(f.id) or not f.get("name") is String \
				or not f.get("measure") in FIELD_MEASURES:
			return "a field row needs its own id, a name and a field measure"
		fields[f.id] = true
	if not d.get("ranks") is Array or d.ranks.is_empty() or int(d.ranks[0].get("min", -1)) != 0:
		return "the first rank starts at 0"
	var low := -1
	for r in d.ranks:
		if not r.get("title") is String or int(r.get("min", -1)) <= low:
			return "ranks need titles and rising mins"
		low = int(r.min)
	return ""
