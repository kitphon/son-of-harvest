class_name DayPlan
extends RefCounted
## One villager's day, built from a plan in data/villagers/<id>.json: entries that start at a
## time on a map, each with a route of steps walked once and an optional loop walked over and
## over until the next entry. Positions are a pure function of the time (`where`), so a map
## that the farmer walks into mid-day shows everyone where the plan says they are by now
## (DESIGN: catch-up on map entry) without the other maps being simulated.
##
## Steps: {"to": [x, y]} walks straight to a cell, {"wait": minutes} stands, {"work": minutes}
## stands at work (hammering; the sprite's work pose), {"fish": minutes} stands with a rod
## out (the fish pose, at the river), {"face": "up"} turns. Times are game minutes of the day counted from 6:00 on (DESIGN: the day ends at
## 6:00), so a time after midnight is past 24:00 (day_minute). Cells are map cells; positions
## come out as cell units with the middle of a cell at +0.5. Format: README.md, Villagers.

const AWAY := "away"           # not on any map we draw (inside a house that has no map yet)
const DAY_START := 6 * 60
const DAY_END := DAY_START + 24 * 60
const FACINGS := MapData.FACINGS
const STEP_KEYS: Array[String] = ["to", "wait", "work", "fish", "face"]
const ENTRY_KEYS: Array[String] = ["_note", "at", "map", "from", "route", "loop"]

var speed := 1.5               # cells per game minute
## Per entry: {start, end, map, legs, cycle, cycle_start, cycle_len, pos, facing}. A leg is
## {t0, t1, a, b, face, walk, work, fish}: a walk from a to b, or a stand at a (a turn is a
## stand of 0; work = standing at work, fish = standing with a rod out).
var entries: Array[Dictionary] = []


## The clock as a minute of this game day: before 6:00 counts as after midnight.
static func day_minute(hour: int, minute: int) -> int:
	var m := hour * 60 + minute
	return m + 24 * 60 if m < DAY_START else m


## "H:MM" -> a minute of the game day, -1 when it isn't a time.
static func minute_of(t: Variant) -> int:
	var m := EventTriggers.clock(t)
	if m < 0 or m >= 24 * 60:
		return -1
	return day_minute(m / 60, m % 60)


static func cell_middle(c: Vector2i) -> Vector2:
	return Vector2(c) + Vector2(0.5, 0.5)


## The facing for a walk along `v`: the bigger of its sides (the farmer's four facings).
static func facing_of(v: Vector2) -> Vector2i:
	if absf(v.x) >= absf(v.y):
		return Vector2i.RIGHT if v.x >= 0 else Vector2i.LEFT
	return Vector2i.DOWN if v.y >= 0 else Vector2i.UP


## [error, DayPlan] from a plan's entry list; the error says which entry is wrong.
static func build(data: Variant, walk_speed: float) -> Array:
	var p := DayPlan.new()
	p.speed = walk_speed
	var err := p._read(data)
	return [err, p if err == "" else null]


func _read(data: Variant) -> String:
	if not data is Array or data.is_empty():
		return "a plan needs a list of entries"
	if speed <= 0.0:
		return "the walk speed must be above 0"
	for i in data.size():
		var e: Variant = data[i]
		if not e is Dictionary:
			return "entry %d is not an object" % i
		for k in e:
			if not k in ENTRY_KEYS:
				return "entry %d: unknown key %s" % [i, k]
		var start := minute_of(e.get("at"))
		if start < 0:
			return "entry %d: at needs a time \"H:MM\"" % i
		if i == 0 and start != DAY_START:
			return "the first entry starts at 06:00"
		if i > 0 and start <= entries[i - 1].start:
			return "entry %s is not after the one before" % e.at
		if not e.get("map") is String or e.map == "":
			return "entry %s needs a map" % e.at
		var out := {"start": start, "end": DAY_END, "map": e.map, "legs": [], "cycle": [],
			"cycle_start": 0.0, "cycle_len": 0.0, "pos": Vector2.ZERO, "facing": Vector2i.DOWN}
		if i > 0:
			entries[i - 1].end = start
		if e.map == AWAY:
			if e.has("from") or e.has("route") or e.has("loop"):
				return "entry %s is away and has nowhere to walk" % e.at
			entries.append(out)
			continue
		if e.has("from"):
			var c: Variant = MapData._cell(e.from)
			if c == null:
				return "entry %s: from needs a cell [x, y]" % e.at
			out.pos = cell_middle(c)
		elif i > 0 and entries[i - 1].map == e.map:
			var was := where(start)   # carries on from where the last entry left them
			out.pos = was.pos
			out.facing = was.facing
		else:
			return "entry %s comes onto %s and needs a from cell" % [e.at, e.map]
		var at := [out.pos, out.facing, float(start)]
		var err := _steps(e.get("route", []), at, out.legs)
		if err != "":
			return "entry %s route: %s" % [e.at, err]
		if e.has("loop"):
			err = _steps(e.loop, at, out.legs)   # the first time round starts where the route ends
			if err == "":
				out.cycle_start = at[2]
				err = _steps(e.loop, at, out.cycle)
			if err != "":
				return "entry %s loop: %s" % [e.at, err]
			out.cycle_len = at[2] - out.cycle_start
			if out.cycle_len <= 0.0:
				return "entry %s loop takes no time" % e.at
		entries.append(out)
	for i in entries.size():
		var e := entries[i]
		if e.cycle.is_empty() and not e.legs.is_empty() and e.legs[-1].t1 > e.end:
			return "entry %s does not get there before the next one" % data[i].at
	return ""


## Appends the legs for `steps`, walking on from `at` = [pos, facing, minute] (updated).
func _steps(steps: Variant, at: Array, legs: Array) -> String:
	if not steps is Array:
		return "needs a list of steps"
	for s in steps:
		if not s is Dictionary or s.size() != 1 or not s.keys()[0] in STEP_KEYS:
			return "a step is one of {\"to\": [x, y]}, {\"wait\": minutes}, {\"work\": minutes}, {\"fish\": minutes}, {\"face\": \"up\"}"
		var pos: Vector2 = at[0]
		var t: float = at[2]
		if s.has("to"):
			var c: Variant = MapData._cell(s.to)
			if c == null:
				return "to needs a cell [x, y]"
			var b := cell_middle(c)
			if b == pos:
				continue
			var face := facing_of(b - pos)
			var t1 := t + pos.distance_to(b) / speed
			legs.append({"t0": t, "t1": t1, "a": pos, "b": b, "face": face, "walk": true, "work": false, "fish": false})
			at[0] = b
			at[1] = face
			at[2] = t1
		elif s.has("wait") or s.has("work") or s.has("fish"):
			var k: String = s.keys()[0]
			if not (s[k] is int or s[k] is float) or s[k] <= 0:
				return "%s needs minutes above 0" % k
			legs.append({"t0": t, "t1": t + float(s[k]), "a": pos, "b": pos, "face": at[1], "walk": false, "work": k == "work", "fish": k == "fish"})
			at[2] = t + float(s[k])
		else:
			if not FACINGS.has(s.face):
				return "face is up, down, left or right"
			at[1] = FACINGS[s.face]
			legs.append({"t0": t, "t1": t, "a": pos, "b": pos, "face": at[1], "walk": false, "work": false, "fish": false})
	return ""


## The entry that runs at minute `t` of the game day (the first one before 6:00).
func entry_at(t: float) -> Dictionary:
	var out := entries[0]
	for e in entries:
		if e.start <= t:
			out = e
	return out


## Where the plan has the villager at minute `t` (day_minute, a fraction for a part-minute):
## {map, pos (cells, Vector2), facing, moving, walked (cells into the current walk), working,
## worked (minutes into the current stretch of work), fishing, fished (minutes with the rod out)}.
func where(t: float) -> Dictionary:
	var e := entry_at(t)
	var out := {"map": e.map, "pos": e.pos, "facing": e.facing, "moving": false, "walked": 0.0, "working": false, "worked": 0.0, "fishing": false, "fished": 0.0}
	if e.map == AWAY:
		return out
	var legs: Array = e.legs
	if not e.cycle.is_empty() and t >= e.cycle_start:
		legs = e.cycle
		t = e.cycle_start + fmod(t - e.cycle_start, e.cycle_len)
	var leg: Variant = null
	for l in legs:
		if l.t0 <= t:
			leg = l
	if leg == null:
		return out
	out.facing = leg.face
	if t >= leg.t1:
		out.pos = leg.b
		return out
	out.working = leg.work
	out.worked = t - leg.t0 if leg.work else 0.0
	out.fishing = leg.fish
	out.fished = t - leg.t0 if leg.fish else 0.0
	out.pos = leg.a.lerp(leg.b, (t - leg.t0) / (leg.t1 - leg.t0))
	out.moving = leg.walk
	out.walked = (t - leg.t0) * speed if leg.walk else 0.0
	return out


## Every straight walk in the plan as [map, from, to] (positions in cells), for path checks.
func walks() -> Array:
	var out := []
	for e in entries:
		for l in e.legs + e.cycle:
			if l.walk:
				out.append([e.map, l.a, l.b])
	return out
