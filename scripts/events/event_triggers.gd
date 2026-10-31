class_name EventTriggers
extends RefCounted
## One map's trigger table (data/events/triggers_<map id>.json): rows of conditions, each
## naming the event to play when they all hold. The view asks on a cause (the farmer enters
## the map, a new day starts, a clock minute passes, the farmer steps onto another cell); the
## first row in table order that matches wins, so the order is the priority. A row plays once
## unless it says `"once": false`. Pure logic: the state comes in as a dictionary
## (Game.trigger_state), so tests check it headless. Format: README.md → Events.

const GameRules := preload("res://scripts/autoload/game.gd")   # SEASONS, WEEKDAYS
const CAUSES: Array[String] = ["enter", "day_start", "minute", "step"]
const WEATHERS: Array[String] = ["sunny", "rain", "storm", "snow"]
const ROW_KEYS: Array[String] = ["_note", "event", "on", "once", "year", "season", "days",
	"weekday", "time", "weather", "flags", "not_flags", "seen", "not_seen", "area"]

var map_id := ""
var error := ""      # "" or why the table was refused (then it has no rows)
var rows: Array = []


static func path(map: String) -> String:
	return EventRunner.DIR + "triggers_%s.json" % map


## The table for map `map`. A map without a file has no events (not an error).
static func open(map: String) -> EventTriggers:
	var data: Variant = {"rows": []}
	if FileAccess.file_exists(path(map)):
		data = JSON.parse_string(FileAccess.get_file_as_string(path(map)))
	var t := EventTriggers.new(data)
	t.map_id = map
	return t


func _init(data: Variant) -> void:
	error = _check(data)
	if error != "":
		rows = []


## The event the first matching row names, or "" when none matches.
func pick(cause: String, state: Dictionary) -> String:
	for row in rows:
		if matches(row, cause, state):
			return row.event
	return ""


## Does `row` hold for `cause` in `state` ({year, season, day, weekday, time (minutes since
## midnight), weather, flags, seen, cell})? Conditions a row leaves out always hold.
static func matches(row: Dictionary, cause: String, s: Dictionary) -> bool:
	var on: Variant = row.on
	if not cause in (on if on is Array else [on]):
		return false
	if row.get("once", true) and s.seen.has(row.event):
		return false
	if row.has("year") and not _within(s.year, row.year):
		return false
	if row.has("season") and not s.season in row.season:
		return false
	if row.has("days") and not _within(s.day, row.days):
		return false
	if row.has("weekday") and not s.weekday in row.weekday:
		return false
	if row.has("time") and not (s.time >= clock(row.time[0]) and s.time < clock(row.time[1])):
		return false
	if row.has("weather") and not s.weather in row.weather:
		return false
	for f in row.get("flags", []):
		if not EventRunner.is_set(s.flags, f):
			return false
	for f in row.get("not_flags", []):
		if EventRunner.is_set(s.flags, f):
			return false
	for e in row.get("seen", []):
		if not s.seen.has(e):
			return false
	for e in row.get("not_seen", []):
		if s.seen.has(e):
			return false
	if row.has("area"):
		var a: Array = row.area
		if not Rect2i(int(a[0]), int(a[1]), int(a[2]), int(a[3])).has_point(s.cell):
			return false
	return true


## "H:MM" -> minutes since midnight (-1 when it isn't a time). "24:00" is the end of the day.
static func clock(t: Variant) -> int:
	if not t is String or t.count(":") != 1:
		return -1
	var p: PackedStringArray = t.split(":")
	if not p[0].is_valid_int() or not p[1].is_valid_int() or p[1].length() != 2:
		return -1
	var m := p[0].to_int() * 60 + p[1].to_int()
	return m if p[1].to_int() < 60 and m >= 0 and m <= 24 * 60 else -1


static func _within(v: int, pair: Array) -> bool:
	return v >= int(pair[0]) and v <= int(pair[1])


# --- checking the data ------------------------------------------------------

func _check(data: Variant) -> String:
	if not data is Dictionary or not data.get("rows") is Array:
		return "Trigger table has no rows list"
	rows = data.rows
	for i in rows.size():
		var err := check_row(rows[i])
		if err != "":
			return "Row %d: %s" % [i, err]
	return ""


## "" when `row` is a trigger we can check, else what is wrong with it.
static func check_row(row: Variant) -> String:
	if not row is Dictionary:
		return "not a dictionary"
	for k in row:
		if not k in ROW_KEYS:
			return "unknown key %s" % k
	if not row.get("event") is String:
		return "no event"
	var r := EventRunner.open(row.event, null)
	if r.error != "":
		return "event %s: %s" % [row.event, r.error]
	var on: Variant = row.get("on")
	var causes: Array = on if on is Array else [on]
	if causes.is_empty() or not causes.all(func(c): return c is String and c in CAUSES):
		return "on must be one or more of %s" % ", ".join(CAUSES)
	if row.has("once") and not row.once is bool:
		return "once is true or false"
	for k in ["year", "days"]:
		if row.has(k) and not _range_ok(row[k]):
			return "%s needs [first, last]" % k
	if row.has("season") and not _names_ok(row.season, Array(GameRules.SEASONS)):
		return "bad season list"
	if row.has("weekday") and not _names_ok(row.weekday, Array(GameRules.WEEKDAYS)):
		return "bad weekday list"
	if row.has("weather") and not _names_ok(row.weather, Array(WEATHERS)):
		return "bad weather list"
	if row.has("time"):
		var t: Variant = row.time
		if not t is Array or t.size() != 2 or clock(t[0]) < 0 or clock(t[1]) <= clock(t[0]):
			return "time needs [\"H:MM\", \"H:MM\"], the first earlier"
	for k in ["flags", "not_flags", "seen", "not_seen"]:
		if row.has(k) and not _names_ok(row[k], []):
			return "%s needs a list of names" % k
	if row.has("area"):
		var a: Variant = row.area
		if not a is Array or a.size() != 4 or not a.all(func(v): return EventRunner._whole(v, -999, 999)) or a[2] < 1 or a[3] < 1:
			return "area needs [x, y, width, height]"
	return ""


static func _range_ok(v: Variant) -> bool:
	return v is Array and v.size() == 2 and EventRunner._whole(v[0], 1, 9999) \
		and EventRunner._whole(v[1], 1, 9999) and v[0] <= v[1]


## A non-empty list of names, each in `allowed` (any non-empty word when `allowed` is empty).
static func _names_ok(v: Variant, allowed: Array) -> bool:
	if not v is Array or v.is_empty():
		return false
	for n in v:
		if not n is String or n == "" or (not allowed.is_empty() and not n in allowed):
			return false
	return true
