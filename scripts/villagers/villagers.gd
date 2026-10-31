class_name Villagers
extends RefCounted
## The village's people (data/villagers/<id>.json) and where they are. Each villager has a
## rule list: every morning the first rule whose conditions all hold (weekday, season,
## weather, day of the month, year, story flags) picks the day's plan, else `default`
## (DESIGN: villagers). The plan (DayPlan) says where they are at any minute, so the views ask
## `on_map` every frame and get everyone who should stand on that map right now; nothing is
## simulated off screen and nothing needs saving. Pure logic, the state comes in as Game's
## trigger_state, so tests run it headless. Format: README.md, Villagers.

const GameRules := preload("res://scripts/autoload/game.gd")   # SEASONS, WEEKDAYS
const DIR := "res://data/villagers/"
const COMMON := DIR + "_common.json"
const RULE_KEYS: Array[String] = ["season", "weekday", "weather", "days", "year", "flags", "not_flags", "festival"]
const FILE_KEYS: Array[String] = ["_note", "id", "name", "speed", "look", "rules", "default", "plans"]

static var _people := {}       # id -> the file's data (only files that passed the check)
static var _common: Variant = null   # data/villagers/_common.json, read on first use
static var _loaded := false
static var _today_key := ""
static var _today := {}        # id -> DayPlan for the day in _today_key


## Every usable villager, id -> data. A broken file is left out with an error printed.
static func all() -> Dictionary:
	if not _loaded:
		_loaded = true
		for id in file_ids():
			var r := load_villager(id)
			if r[0] != "":
				push_error("Villager %s: %s" % [id, r[0]])
			else:
				_people[id] = r[1]
	return _people


## The ids of every villager file in data/villagers (files starting with _ are shared data).
static func file_ids() -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".json") and not f.begins_with("_"):
			out.append(f.get_basename())
	out.sort()
	return out


## [error, data] for data/villagers/<id>.json, every plan built once to check it.
static func load_villager(id: String) -> Array:
	var path := DIR + id + ".json"
	if not FileAccess.file_exists(path):
		return ["no file " + path, null]
	var v: Variant = _json(path)
	var err := check(v)
	if err == "" and v.id != id:
		err = "the file's id is " + str(v.id)
	return [err, v if err == "" else null]


## "" when `v` is a villager we can use, else what is wrong with it.
static func check(v: Variant) -> String:
	if not v is Dictionary:
		return "not an object"
	for k in v:
		if not k in FILE_KEYS:
			return "unknown key " + k
	if not v.get("id") is String or v.id == "" or not v.get("name") is String or v.name == "":
		return "needs an id and a name"
	if not v.get("look") is Dictionary:
		return "needs a look"
	if v.has("speed") and not ((v.speed is float or v.speed is int) and v.speed > 0):
		return "speed is cells per minute above 0"
	var plans: Variant = v.get("plans")
	if not plans is Dictionary or plans.is_empty():
		return "needs plans"
	if not plans.has(v.get("default")):
		return "the default plan is not in plans"
	for name in plans:
		var r := DayPlan.build(plans[name], speed_of(v))
		if r[0] != "":
			return "plan %s: %s" % [name, r[0]]
	if not v.get("rules", []) is Array:
		return "rules is a list"
	for i in v.get("rules", []).size():
		var rule: Variant = v.rules[i]
		if not rule is Dictionary or not rule.get("if") is Dictionary or not plans.has(rule.get("plan")):
			return "rule %d needs if {...} and a plan from plans" % i
		var err := check_conditions(rule.if)
		if err != "":
			return "rule %d: %s" % [i, err]
	return ""


static func check_conditions(c: Dictionary) -> String:
	for k in c:
		if not k in RULE_KEYS:
			return "unknown condition " + k
	if c.has("season") and not EventTriggers._names_ok(c.season, Array(GameRules.SEASONS)):
		return "bad season list"
	if c.has("weekday") and not EventTriggers._names_ok(c.weekday, Array(GameRules.WEEKDAYS)):
		return "bad weekday list"
	if c.has("weather") and not EventTriggers._names_ok(c.weather, Array(EventTriggers.WEATHERS)):
		return "bad weather list"
	for k in ["days", "year"]:
		if c.has(k) and not EventTriggers._range_ok(c[k]):
			return "%s needs [first, last]" % k
	for k in ["flags", "not_flags"]:
		if c.has(k) and not EventTriggers._names_ok(c[k], []):
			return "%s needs a list of names" % k
	if c.has("festival") and not EventTriggers._names_ok(c.festival, Festivals.all().keys()):
		return "festival needs a list of festival ids (data/festivals.json)"
	return ""


## Do all of a rule's conditions hold in `s` (Game.trigger_state)? Left-out ones always do.
static func conditions_hold(c: Dictionary, s: Dictionary) -> bool:
	if c.has("season") and not s.season in c.season:
		return false
	if c.has("weekday") and not s.weekday in c.weekday:
		return false
	if c.has("weather") and not s.weather in c.weather:
		return false
	if c.has("days") and not EventTriggers._within(s.day, c.days):
		return false
	if c.has("year") and not EventTriggers._within(s.year, c.year):
		return false
	if c.has("festival") and not s.get("festival", "") in c.festival:
		return false
	for f in c.get("flags", []):
		if not EventRunner.is_set(s.flags, f):
			return false
	for f in c.get("not_flags", []):
		if EventRunner.is_set(s.flags, f):
			return false
	return true


## The name of the plan villager `v` follows on a day with state `s`: the first rule that holds.
static func pick_plan(v: Dictionary, s: Dictionary) -> String:
	for rule in v.get("rules", []):
		if conditions_hold(rule.if, s):
			return rule.plan
	return v.default


static func common() -> Dictionary:
	if _common == null:
		_common = _json(COMMON) if FileAccess.file_exists(COMMON) else {}
	return _common


static func speed_of(v: Dictionary) -> float:
	return float(v.get("speed", common().get("walk_speed", 1.5)))


## Cells walked per walk frame (4 frames = two steps).
static func stride() -> float:
	return float(common().get("stride", 0.5))


## Today's plans, id -> DayPlan, chosen for the day in `s` and kept until the day (or its
## weather or flags) changes.
static func today(s: Dictionary) -> Dictionary:
	var key := "%d/%s/%d/%s/%s" % [s.year, s.season, s.day, s.weather, str(s.flags)]
	if key != _today_key:
		_today_key = key
		_today = {}
		var people := all()
		for id in people:
			_today[id] = DayPlan.build(people[id].plans[pick_plan(people[id], s)], speed_of(people[id]))[1]
	return _today


## Where villager `id` is at minute `t` of the game day (DayPlan.where), {} for no such villager.
static func where(id: String, t: float, s: Dictionary) -> Dictionary:
	var plans := today(s)
	return plans[id].where(t) if plans.has(id) else {}


## Everyone on map `map_id` at minute `t`: [{id, pos, facing, moving, walked}], by id.
static func on_map(map_id: String, t: float, s: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var plans := today(s)
	for id in plans:
		var w: Dictionary = plans[id].where(t)
		if w.map == map_id:
			w.id = id
			out.append(w)
	return out


## Is villager `id` on map `map_id` now? The hook for "the shop is shut while its keeper is out".
static func is_on(id: String, map_id: String, t: float, s: Dictionary) -> bool:
	return where(id, t, s).get("map", "") == map_id


## The sprite key for a villager as on_map gives them (PlaceholderArt "villager:..."): walk
## frames go by the distance walked, so steps match the ground at any speed.
static func sprite_key(w: Dictionary) -> String:
	var back := FarmerAnim.is_back(w.facing)
	var frame := int(w.walked / stride()) % 4 if w.moving else 0
	return "villager:%s:%s:%s:%d" % [w.id, "back" if back else "front", "walk" if w.moving else "idle", frame]


static func look(id: String) -> Dictionary:
	return all().get(id, {}).get("look", {})


static func _json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))
