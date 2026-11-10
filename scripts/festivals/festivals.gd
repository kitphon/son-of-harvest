class_name Festivals
extends RefCounted
## The festival calendar (data/festivals.json): which festival falls on a date, whether it is
## on at a minute of the day, which shops it shuts, which decorations stand on a map and
## whether its event is due, its contest (what it takes, how it is judged, the prizes), its
## played game (the mochi pounding, MochiPound; the fishing race, FishingRace; the goldfish
## scoop, GoldfishScoop) and its stall. Pure logic like Villagers: the date and clock come in as arguments (or
## Game.trigger_state), so tests run it headless. Format: README.md, Festivals.

const GameRules := preload("res://scripts/autoload/game.gd")   # SEASONS, DAYS_PER_SEASON
const PATH := "res://data/festivals.json"
const KEYS: Array[String] = ["_note", "name", "season", "day", "hours", "map", "place", "event",
	"closes", "props", "fireworks", "contest", "game", "stall"]
## The displays a stall prop may set out when it sells nothing (StallWares builds them).
const DISPLAYS: Array[String] = ["goldfish", "masks"]
const PROP_KEYS: Array[String] = ["kind", "cell", "size", "cloth", "display"]
const CONTEST_KEYS: Array[String] = ["_note", "name", "takes", "table", "ask", "in_season", "rivals",
	"prizes", "event"]
const GAME_KEYS: Array[String] = ["_note", "id", "name", "kind", "cell", "partners", "lead", "gap", "rounds",
	"windows", "points", "seconds", "paper", "dip", "wear", "reach", "tub", "rivals", "prizes", "event"]
## What a played game can be, and the prop it is played at.
const GAMES := {"mochi": "mochi_usu", "fishing": "race_flag", "scoop": "stall"}
## The keys only a goldfish scoop has, and the fish looks ScoopScreen draws (red, red and white, black).
const SCOOP_KEYS: Array[String] = ["paper", "dip", "wear", "reach", "tub"]
const SCOOP_LOOKS := 3
const STALL_KEYS: Array[String] = ["_note", "id", "name", "cell", "stock"]
## What a contest can take: Game.item_kind of the entry.
const KINDS: Array[String] = ["crop", "fish", "animal", "mine"]
const DIALOGUE := "contests"     # data/dialogue/contests.json: the contests' ask and result lines
const STALL_PREFIX := "stall:"   # a stall's shop id is "stall:<festival id>[:<stall id>]"

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


# --- contests -----------------------------------------------------------------

## Festival `id`'s contest ({} for none).
static func contest(id: String) -> Dictionary:
	return get_festival(id).get("contest", {})


## The events_seen key that marks the farmer's entry in festival `id`'s contest in `year`
## (one entry a year).
static func entered_key(id: String, year: int) -> String:
	return "contest:%s:%d" % [id, year]


## Is `cell` part of the judges' table of festival `id`'s contest (the prop round its table cell)?
static func at_table(id: String, cell: Vector2i) -> bool:
	var c := contest(id)
	return not c.is_empty() and _prop_rect(id, _cell(c.table)).has_point(cell)


## What an entry worth `value` in the bin and grown in `item_seasons` scores at festival
## `id`'s contest: its value, times `in_season` when it grows in the festival's season.
static func entry_score(id: String, item_seasons: Array, value: int) -> int:
	var bonus := float(contest(id).get("in_season", 1.0)) if get_festival(id).get("season") in item_seasons else 1.0
	return int(round(value * bonus))


## Judges festival `id`'s contest in `year` with the farmer's entry scoring `score`: every
## rival's score is rolled from their range with a seed of the festival and year (one year
## always comes out the same), and the farmer wins ties. Returns {place (1 = first), score,
## rivals: [{who, score}] best first, winner ("farmer" or a rival's id), prize ({} or
## {money, item?, count?})}.
static func judge(id: String, year: int, score: int) -> Dictionary:
	return _rank(contest(id), "%s:%d" % [id, year], score)


## Ranks a farmer scoring `score` against the rivals of contest or game `c`, rolled with seed
## `key`. Rival `skip` (the game's partner) is rolled but sits out, so the others' scores
## stay the same whoever the partner is.
static func _rank(c: Dictionary, key: String, score: int, skip := "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var rivals: Array = []
	var place := 1
	for r in c.get("rivals", []):
		var s := rng.randi_range(int(r.score[0]), int(r.score[1]))
		if r.who == skip:
			continue
		rivals.append({"who": r.who, "score": s})
		if s > score:
			place += 1
	rivals.sort_custom(func(a, b): return a.score > b.score)
	var prizes: Array = c.get("prizes", [])
	return {"place": place, "score": score, "rivals": rivals,
		"winner": "farmer" if place == 1 else rivals[0].who,
		"prize": prizes[place - 1] if place <= prizes.size() else {}}


# --- the played game (mochi pounding, fishing race, goldfish scoop) --------------------------------------------

## Festival `id`'s played game ({} for none).
static func game(id: String) -> Dictionary:
	return get_festival(id).get("game", {})


## The festival whose game has id `game_id` ("" for none).
static func festival_of_game(game_id: String) -> String:
	for id in all():
		if str(game(id).get("id", "")) == game_id:
			return id
	return ""


## The events_seen key that marks the farmer's go at festival `id`'s game in `year` (one a year).
static func played_key(id: String, year: int) -> String:
	return "game:%s:%d" % [id, year]


## Is `cell` part of the prop festival `id`'s game is played at?
static func at_game(id: String, cell: Vector2i) -> bool:
	var g := game(id)
	return not g.is_empty() and _prop_rect(id, _cell(g.cell)).has_point(cell)


## Who turns the dough for the farmer at festival `id`'s game: of its partners, the one
## `points` (a Callable: villager id -> affection) is highest for, the first on a tie.
static func partner_for(id: String, points: Callable) -> String:
	var best := ""
	for who in game(id).get("partners", []):
		if best == "" or int(points.call(who)) > int(points.call(best)):
			best = who
	return best


## Judges festival `id`'s game in `year` like a contest (judge): the farmer scored `score`
## with `partner` turning the dough, who is then no rival.
static func judge_game(id: String, year: int, score: int, partner := "") -> Dictionary:
	return _rank(game(id), "%s:game:%d" % [id, year], score, partner)


## The name a ribbon key stands for: a festival's, or a festival game's ("" for neither).
static func ribbon_label(key: String) -> String:
	if all().has(key):
		return name_of(key)
	var fid := festival_of_game(key)
	return str(game(fid).name) if fid != "" else ""


# --- the stalls -----------------------------------------------------------------

## Festival `id`'s stalls: its `stall` as a list (one object or a list of them; [] for none).
static func stalls(id: String) -> Array:
	var s: Variant = get_festival(id).get("stall", [])
	return s if s is Array else [s]


## Festival `id`'s stall with stall id `sid` ("" = the one without an id), {} for none.
static func stall(id: String, sid := "") -> Dictionary:
	for s in stalls(id):
		if str(s.get("id", "")) == sid:
			return s
	return {}


## The shop id of stall `s` of festival `id`: "stall:<festival>", or "stall:<festival>:<stall
## id>" for a stall with an id (a festival with more than one stall).
static func stall_shop_id(id: String, s := {}) -> String:
	return STALL_PREFIX + id + (":" + str(s.id) if s.has("id") else "")


## The festival and the stall a stall's shop id stands for: [festival id, its stall ({} for none)].
static func stall_of(shop_id: String) -> Array:
	if not shop_id.begins_with(STALL_PREFIX):
		return ["", {}]
	var rest := shop_id.trim_prefix(STALL_PREFIX)
	return [rest.get_slice(":", 0), stall(rest.get_slice(":", 0), rest.get_slice(":", 1) if ":" in rest else "")]


## The shop id of the stall of festival `id` whose prop covers `cell` ("" for none).
static func stall_at(id: String, cell: Vector2i) -> String:
	for s in stalls(id):
		if _prop_rect(id, _cell(s.cell)).has_point(cell):
			return stall_shop_id(id, s)
	return ""


## Is `cell` part of one of festival `id`'s stalls (the stall prop round its cell)?
static func at_stall(id: String, cell: Vector2i) -> bool:
	return stall_at(id, cell) != ""


## The stall that stands in prop `p` of festival `id` ({} when the prop is only a look):
## FestivalProps and FestivalView set its wares out on the counter.
static func stall_of_prop(id: String, p: Dictionary) -> Dictionary:
	for s in stalls(id):
		if _rect(p).has_point(_cell(s.cell)):
			return s
	return {}


## Stall `shop_id` ("stall:<festival>[:<stall id>]") as shop data for Shop.make ({"shops":
## {<shop_id>: ...}}): its name, the festival's map, its stock in every season and the
## festival's hours (whole hours, for the screen; Game.open_stall checks the festival
## itself). {} for none.
static func stall_shop_data(shop_id: String) -> Dictionary:
	var fs := stall_of(shop_id)
	var s: Dictionary = fs[1]
	if s.is_empty():
		return {}
	var f := get_festival(fs[0])
	var hours := [EventTriggers.clock(f.hours[0]) / 60, ceili(EventTriggers.clock(f.hours[1]) / 60.0)]
	return {"shops": {shop_id: {"name": s.name, "map": f.map, "open": hours, "stock": {"any": s.stock}}}}


## The cells of the prop of festival `id` that covers `cell` (an empty rect when none does).
static func _prop_rect(id: String, cell: Vector2i) -> Rect2i:
	for p in get_festival(id).get("props", []):
		var r := _rect(p)
		if r.has_point(cell):
			return r
	return Rect2i()


static func _rect(p: Dictionary) -> Rect2i:
	var size: Array = p.get("size", [1, 1])
	return Rect2i(_cell(p.get("cell")), Vector2i(int(size[0]), int(size[1])))


static func _cell(a: Variant) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1])) if a is Array and a.size() == 2 else Vector2i(-1, -1)


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
	if f.has("contest"):
		var err := _check_contest(f.contest, f)
		if err != "":
			return "contest: " + err
	if f.has("game"):
		var err := _check_game(f.game, f)
		if err != "":
			return "game: " + err
	if f.has("stall"):
		var ids := {}
		for st in (f.stall if f.stall is Array else [f.stall]):
			var err := _check_stall(st, f)
			if err != "":
				return "stall: " + err
			if ids.has(st.get("id", "")):
				return "stall: two stalls with the same id (or both without one)"
			ids[st.get("id", "")] = true
	return ""


static func _check_contest(c: Variant, f: Dictionary) -> String:
	if not c is Dictionary:
		return "not an object"
	for k in c:
		if not k in CONTEST_KEYS:
			return "unknown key " + k
	if not c.get("name") is String or c.name == "":
		return "needs a name"
	if not c.get("takes") in KINDS:
		return "takes one of %s" % [KINDS]
	if not _prop_under(f, c.get("table"), "judge_table"):
		return "table needs a cell [x, y] of a judge_table prop"
	if c.has("in_season") and not EventRunner._number(c.in_season, 1.0, 10.0):
		return "in_season is a factor from 1 to 10"
	if not c.get("ask") is String or DialogueRunner.open(DIALOGUE, {}, c.ask).error != "":
		return "ask needs a line of data/dialogue/%s.json" % DIALOGUE
	return _check_rivals(c, 1)


## The rivals, prizes and result event of contest or game `c`; the farmer makes `places`
## more places than there are rivals.
static func _check_rivals(c: Dictionary, places: int) -> String:
	var rivals: Variant = c.get("rivals")
	if not rivals is Array or rivals.is_empty():
		return "needs rivals"
	for r in rivals:
		if not r is Dictionary or not r.get("who") in Villagers.file_ids() or not r.get("score") is Array \
				or r.score.size() != 2 or not EventRunner._whole(r.score[0], 0, 99999) \
				or not EventRunner._whole(r.score[1], int(r.score[0]), 99999):
			return "a rival needs who (a villager) and score [lowest, highest]"
	var prizes: Variant = c.get("prizes")
	if not prizes is Array or prizes.is_empty() or prizes.size() > rivals.size() + places:
		return "prizes is a list by place, at most one per place"
	for p in prizes:
		if not p is Dictionary or not EventRunner._whole(p.get("money", 0), 0, 99999):
			return "a prize is {money, item?, count?}"
		for k in p:
			if not k in ["money", "item", "count"]:
				return "a prize has no " + k
		if p.has("item") and (not p.item is String or p.item == ""):
			return "a prize item is an item id"
		if p.has("count") and not EventRunner._whole(p.count, 1, 99):
			return "a prize count is 1 to 99"
	# Only that the event is there: its actor steps name villagers, and checking those reads the
	# villagers' rules, which ask for the festivals being checked here. tests/test_festivals.gd
	# reads every contest's event in full.
	if not EventRunner.read(str(c.get("event", ""))) is Dictionary:
		return "event: no event %s" % str(c.get("event", ""))
	return ""


static func _check_game(g: Variant, f: Dictionary) -> String:
	if not g is Dictionary:
		return "not an object"
	for k in g:
		if not k in GAME_KEYS:
			return "unknown key " + k
	if not g.get("id") is String or not g.id.is_valid_identifier():
		return "an id is a short name of letters, digits and _"
	if not g.get("name") is String or g.name == "":
		return "needs a name"
	if not g.get("kind") in GAMES:
		return "kind is one of %s" % [GAMES.keys()]
	if not _prop_under(f, g.get("cell"), GAMES[g.kind]):
		return "cell needs a cell [x, y] of a %s prop" % GAMES[g.kind]
	if g.kind == "scoop":
		return _check_scoop(g, f)
	for k in SCOOP_KEYS:
		if g.has(k):
			return "only a goldfish scoop has " + k
	if g.kind == "fishing":
		for k in g:
			if k in ["partners", "gap", "rounds", "windows", "points"]:
				return "a fishing race has no " + k
		if not EventRunner._number(g.get("lead", 0.0), 0.0, 10.0):
			return "lead is 0 to 10 seconds"
		if not EventRunner._number(g.get("seconds"), 10.0, 600.0):
			return "seconds is 10 to 600"
		return _check_rivals(g, 1)
	if g.has("seconds"):
		return "only a fishing race has seconds"
	var partners: Variant = g.get("partners")
	if not partners is Array or partners.is_empty() or partners.any(func(p): return not p in Villagers.file_ids()):
		return "partners is a list of villagers"
	for k in ["lead", "gap"]:
		if not EventRunner._number(g.get(k), 0.0, 10.0):
			return "%s is 0 to 10 seconds" % k
	var rounds: Variant = g.get("rounds")
	if not rounds is Array or rounds.is_empty():
		return "needs rounds"
	var fastest := 99.0
	for r in rounds:
		if not r is Dictionary or not EventRunner._whole(r.get("beats"), 1, 99) or not EventRunner._number(r.get("beat"), 0.2, 5.0):
			return "a round is {beats (1 to 99), beat (0.2 to 5 seconds)}"
		fastest = minf(fastest, float(r.beat))
	var w: Variant = g.get("windows")
	if not w is Dictionary or not EventRunner._number(w.get("great"), 0.01, 1.0) \
			or not EventRunner._number(w.get("good"), float(w.great), 1.0) or float(w.good) >= fastest / 2.0:
		return "windows is {great, good} in seconds, great <= good < half the fastest beat"
	var pts: Variant = g.get("points")
	if not pts is Dictionary or not EventRunner._whole(pts.get("great"), 0, 99) \
			or not EventRunner._whole(pts.get("good"), 0, int(pts.great)) or not EventRunner._whole(pts.get("miss"), -99, 0):
		return "points is {great, good, miss}, great >= good >= 0 >= miss"
	# A partner who is also a rival sits out, so there is one place fewer.
	var rivals: Array = g.get("rivals") if g.get("rivals") is Array else []
	var sits_out := rivals.any(func(r): return r is Dictionary and r.get("who") in partners)
	return _check_rivals(g, 0 if sits_out else 1)


## A goldfish scoop (kind scoop, GoldfishScoop): played at a stall prop that sets out the
## goldfish tub (display goldfish) and sells nothing.
static func _check_scoop(g: Dictionary, f: Dictionary) -> String:
	for k in g:
		if k in ["partners", "gap", "rounds", "windows", "points"]:
			return "a goldfish scoop has no " + k
	var tub_prop := false
	for p in f.get("props", []):
		if p is Dictionary and p.get("kind") == "stall" and p.get("display") == "goldfish" and _rect(p).has_point(_cell(g.cell)):
			tub_prop = true
	if not tub_prop:
		return "cell needs a cell [x, y] of a stall prop with display goldfish"
	for st in (f.get("stall") if f.get("stall") is Array else [f.get("stall", {})]):
		if st is Dictionary and st.has("cell") and _prop_rect_in(f, _cell(st.cell)).has_point(_cell(g.cell)):
			return "the goldfish stall sells nothing (a stall entry stands on it)"
	if not EventRunner._number(g.get("lead", 0.0), 0.0, 10.0):
		return "lead is 0 to 10 seconds"
	if not EventRunner._number(g.get("seconds"), 10.0, 600.0):
		return "seconds is 10 to 600"
	if not EventRunner._number(g.get("paper"), 1.0, 999.0):
		return "paper is 1 to 999"
	if not EventRunner._number(g.get("dip"), 0.05, 2.0):
		return "dip is 0.05 to 2 seconds"
	var w: Variant = g.get("wear")
	if not w is Dictionary or w.size() != 3 or not EventRunner._number(w.get("clean"), 0.0, 999.0) 			or not EventRunner._number(w.get("edge"), float(w.clean), 999.0) or not EventRunner._number(w.get("splash"), 1.0, 999.0):
		return "wear is {clean, edge, splash}, clean <= edge, splash at least 1"
	var r: Variant = g.get("reach")
	if not r is Dictionary or r.size() != 2 or not EventRunner._number(r.get("clean"), 0.01, 1.0) 			or not EventRunner._number(r.get("edge"), float(r.clean), 1.0):
		return "reach is {clean, edge} in tub radii, clean <= edge <= 1"
	var t: Variant = g.get("tub")
	if not t is Dictionary or not EventRunner._whole(t.get("fish"), 1, 12) or not EventRunner._whole(t.get("looks"), 1, SCOOP_LOOKS) 			or not EventRunner._number(t.get("drift"), 0.0, 0.5) or not EventRunner._number(t.get("refill"), 0.0, 10.0) 			or not _span(t.get("orbit"), 0.1, 0.88) or not _span(t.get("speed"), 0.1, 5.0):
		return "tub is {fish (1 to 12), orbit [from, to] (0.1 to 0.88), drift (0 to 0.5), speed [from, to] (0.1 to 5 per second), refill (0 to 10 seconds), looks (1 to %d)}" % SCOOP_LOOKS
	for k in t:
		if not k in ["fish", "orbit", "drift", "speed", "refill", "looks"]:
			return "a tub has no " + k
	return _check_rivals(g, 1)


## A [from, to] pair of numbers with low <= from <= to <= high.
static func _span(v: Variant, low: float, high: float) -> bool:
	return v is Array and v.size() == 2 and EventRunner._number(v[0], low, high) and EventRunner._number(v[1], float(v[0]), high)


## The rect of the prop covering `cell` in festival data `f` (just the cell when none does).
static func _prop_rect_in(f: Dictionary, cell: Vector2i) -> Rect2i:
	for p in f.get("props", []):
		if p is Dictionary and _rect(p).has_point(cell):
			return _rect(p)
	return Rect2i(cell, Vector2i.ONE)


static func _check_stall(s: Variant, f: Dictionary) -> String:
	if not s is Dictionary:
		return "not an object"
	for k in s:
		if not k in STALL_KEYS:
			return "unknown key " + k
	if not s.get("name") is String or s.name == "":
		return "needs a name"
	if s.has("id") and (not s.id is String or not s.id.is_valid_identifier()):
		return "an id is a short name of letters, digits and _"
	if not _prop_under(f, s.get("cell"), "stall"):
		return "cell needs a cell [x, y] of a stall prop"
	if not s.get("stock") is Array or s.stock.is_empty():
		return "needs stock"
	for e in s.stock:
		if not e is Dictionary or not e.get("item") is String:
			return "a stock row is {item, price?}"
		if e.has("price") and not EventRunner._whole(e.price, 1, 99999):
			return "a price is a whole number of G"
	return ""


## Is `cell` ([x, y]) inside a prop of `kind` in festival data `f`?
static func _prop_under(f: Dictionary, cell: Variant, kind: String) -> bool:
	for p in f.get("props", []):
		if p is Dictionary and p.get("kind") == kind and _rect(p).has_point(_cell(cell)):
			return true
	return false


static func _check_prop(p: Variant, m: MapData) -> String:
	if not p is Dictionary or not p.get("kind") is String:
		return "needs a kind"
	for k in p:
		if not k in PROP_KEYS:
			return "unknown key " + k
	if p.has("display") and (p.kind != "stall" or not str(p.display) in DISPLAYS):
		return "display is only for a stall, one of %s" % [DISPLAYS]
	var c: Variant = p.get("cell")
	var size: Variant = p.get("size", [1, 1])
	if not c is Array or c.size() != 2 or not size is Array or size.size() != 2 or size[0] < 1 or size[1] < 1:
		return "needs cell [x, y] and size [w, h]"
	if not m.in_bounds(Vector2i(int(c[0]), int(c[1]))) or not m.in_bounds(Vector2i(int(c[0] + size[0] - 1), int(c[1] + size[1] - 1))):
		return "off the map"
	return ""


static func _hours_ok(h: Variant) -> bool:
	return h is Array and h.size() == 2 and EventTriggers.clock(h[0]) >= 0 and EventTriggers.clock(h[1]) > EventTriggers.clock(h[0])
