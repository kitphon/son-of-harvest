class_name Festivals
extends RefCounted
## The festival calendar (data/festivals.json): which festival falls on a date, whether it is
## on at a minute of the day, which shops it shuts, which decorations stand on a map and
## whether its event is due. Pure logic like Villagers: the date and clock come in as
## arguments (or Game.trigger_state), so tests run it headless. Format: README.md, Festivals.

const GameRules := preload("res://scripts/autoload/game.gd")   # SEASONS, DAYS_PER_SEASON
const PATH := "res://data/festivals.json"
const KEYS: Array[String] = ["_note", "name", "season", "day", "hours", "map", "place", "event",
	"closes", "props", "fireworks"]
const PROP_KEYS: Array[String] = ["kind", "cell", "size", "cloth"]

static var _data: Variant = null   # data/festivals.json, read on first use
static var _error := ""


## Every festival, id -> its data ({} with an error printed when the file is broken).
static func all() -> Dictionary:
	if _data == null:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		_error = check(d)
		if _error != "":
			push_error("Festivals: " + _error)
			_data = {}
		else:
			_data = d.festivals
	return _data


static func error() -> String:
	all()
	return _error


## The id of the festival on `season` (name) `day`, or "".
static func on_date(season: String, day: int) -> String:
	var fests := all()
	for id in fests:
		if fests[id].season == season and int(fests[id].day) == day:
			return id
	return ""


static func get_festival(id: String) -> Dictionary:
	return all().get(id, {})


static func name_of(id: String) -> String:
	return str(get_festival(id).get("name", ""))


## Is festival `id` held at `minute` (minutes since midnight) of its day?
static func in_hours(id: String, minute: int) -> bool:
	var f := get_festival(id)
	return not f.is_empty() and _within(f.hours, minute)


## Is festival `id` going on at `minute` on map `map_id`?
static func on_now(id: String, map_id: String, minute: int) -> bool:
	return in_hours(id, minute) and get_festival(id).map == map_id


## Does festival `id` keep shop `shop_id` shut all day?
static func closes(id: String, shop_id: String) -> bool:
	return shop_id in get_festival(id).get("closes", [])


## The decorations of today's festival `id` standing on `map_id` at `minute` ([] outside the
## hours or on another map).
static func props_now(id: String, map_id: String, minute: int) -> Array:
	return get_festival(id).get("props", []) if on_now(id, map_id, minute) else []


## Are fireworks going up at `minute` for festival `id`?
static func fireworks_now(id: String, minute: int) -> bool:
	var f := get_festival(id)
	return f.has("fireworks") and _within(f.fireworks, minute)


## The events_seen key that marks festival `id` as visited in `year` (its event plays once a year).
static func seen_key(id: String, year: int) -> String:
	return "festival:%s:%d" % [id, year]


## The event to play now for a farmer on `map_id` in trigger state `s` (Game.trigger_state,
## with `festival` = today's id), or "" when none is due.
static func due_event(map_id: String, s: Dictionary) -> String:
	var id: String = s.get("festival", "")
	if id == "" or not on_now(id, map_id, int(s.time)) or s.seen.has(seen_key(id, int(s.year))):
		return ""
	return get_festival(id).event


## The festival on the day after `season` (index) `day`, for the weather roll ("" for none).
static func tomorrow(season: int, day: int) -> String:
	if day < GameRules.DAYS_PER_SEASON:
		return on_date(GameRules.SEASONS[season], day + 1)
	return on_date(GameRules.SEASONS[(season + 1) % GameRules.SEASONS.size()], 1)


## `-- --festival=<id>` (screenshots): Game `g` on that festival's day, half an hour into it
## (into the fireworks when it has them), fair weather, the farmer at its place facing up.
static func start_at(g: Node, id: String) -> void:
	var f := get_festival(id)
	if f.is_empty():
		push_warning("No festival " + id)
		return
	g.season = GameRules.SEASONS.find(f.season)
	g.day = int(f.day)
	var t := EventTriggers.clock(f.fireworks[0] if f.has("fireworks") else f.hours[0]) + 30
	g.hour = t / 60
	g.minute = t % 60
	g.weather_today = "sunny"
	g.maps.place(f.map, Vector2i(int(f.place[0]), int(f.place[1])), Vector2i.UP)


static func _within(hours: Array, minute: int) -> bool:
	return minute >= EventTriggers.clock(hours[0]) and minute < EventTriggers.clock(hours[1])


# --- checking the data ------------------------------------------------------

## "" when `d` is a festival file we can use, else what is wrong with it.
static func check(d: Variant) -> String:
	if not d is Dictionary or not d.get("festivals") is Dictionary:
		return "no festivals"
	var dates := {}
	for id in d.festivals:
		var err := check_festival(d.festivals[id])
		if err != "":
			return "%s: %s" % [id, err]
		var date := "%s %d" % [d.festivals[id].season, int(d.festivals[id].day)]
		if dates.has(date):
			return "%s and %s are both on %s" % [dates[date], id, date]
		dates[date] = id
	return ""


static func check_festival(f: Variant) -> String:
	if not f is Dictionary:
		return "not an object"
	for k in f:
		if not k in KEYS:
			return "unknown key " + k
	if not f.get("name") is String or f.name == "":
		return "needs a name"
	if not f.get("season") in GameRules.SEASONS:
		return "bad season"
	if not EventRunner._whole(f.get("day"), 1, GameRules.DAYS_PER_SEASON):
		return "day is 1..%d" % GameRules.DAYS_PER_SEASON
	for k in ["hours", "fireworks"]:
		if (k == "hours" or f.has(k)) and not _hours_ok(f.get(k)):
			return "%s needs [\"H:MM\", \"H:MM\"], the first earlier" % k
	if not f.get("map") is String or not MapManager.has(f.map):
		return "no map %s" % f.get("map")
	var m := MapManager.data(f.map)
	var place: Variant = f.get("place")
	if not place is Array or place.size() != 2 or not m.in_bounds(Vector2i(int(place[0]), int(place[1]))) \
			or m.is_solid(Vector2i(int(place[0]), int(place[1]))):
		return "place needs an open cell [x, y] on the map"
	var ev := EventRunner.open(str(f.get("event", "")), null)
	if ev.error != "":
		return "event: " + ev.error
	for s in f.get("closes", []):
		if not s in Shop.ids():
			return "closes an unknown shop %s" % s
	if not f.get("props", []) is Array:
		return "props is a list"
	for p in f.get("props", []):
		var err := _check_prop(p, m)
		if err != "":
			return "prop %s: %s" % [p, err]
	return ""


static func _check_prop(p: Variant, m: MapData) -> String:
	if not p is Dictionary or not p.get("kind") is String:
		return "needs a kind"
	for k in p:
		if not k in PROP_KEYS:
			return "unknown key " + k
	var c: Variant = p.get("cell")
	var size: Variant = p.get("size", [1, 1])
	if not c is Array or c.size() != 2 or not size is Array or size.size() != 2 or size[0] < 1 or size[1] < 1:
		return "needs cell [x, y] and size [w, h]"
	if not m.in_bounds(Vector2i(int(c[0]), int(c[1]))) or not m.in_bounds(Vector2i(int(c[0] + size[0] - 1), int(c[1] + size[1] - 1))):
		return "off the map"
	return ""


static func _hours_ok(h: Variant) -> bool:
	return h is Array and h.size() == 2 and EventTriggers.clock(h[0]) >= 0 and EventTriggers.clock(h[1]) > EventTriggers.clock(h[0])
