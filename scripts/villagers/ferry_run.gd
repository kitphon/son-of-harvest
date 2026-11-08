class_name FerryRun
extends RefCounted
## Mio's ferry crossing (data/ferry.json): where the boat and its poler are a given number of
## minutes into a day plan's {"ferry": minutes} step. Pure: the plan (DayPlan) says when the step
## runs, Villagers.where moves the poler by `ride`, and the views move the boat by `boat_at`
## (OutdoorProps.ferry_boat's BoatRide in 3D, FerryView in the flat view). Positions are in
## cells (x east, y south), like a plan's.

const PATH := "res://data/ferry.json"
const PHASES: Array[String] = ["board", "out", "wait", "back", "off"]

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		var d: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		_data = d if d is Dictionary else {}
	return _data


static func _v(key: String) -> Vector2:
	var a: Array = data().get(key, [0, 0])
	return Vector2(float(a[0]), float(a[1]))


static func villager() -> String:
	return str(data().get("villager", "mio"))


static func map_id() -> String:
	return str(data().get("map", "river"))


static func mooring() -> Vector2:
	return _v("mooring")


static func far() -> Vector2:
	return _v("far")


static func lift() -> float:
	return float(data().get("lift", 0.0))


## The whole crossing in minutes (the phases' total; a ferry step must last this long).
static func total() -> float:
	var t := 0.0
	for ph in data().get("phases", []):
		t += float(ph[1])
	return t


## Does the boat go out in season `season`?
static func runs_in(season: String) -> bool:
	return not season in (data().get("no_seasons", []) as Array)


## [phase name, fraction 0..1 through it] at `m` minutes into the step; "" before 0 or past the end.
static func phase(m: float) -> Array:
	if m < 0.0:
		return ["", 0.0]
	var t := 0.0
	for ph in data().get("phases", []):
		var span := float(ph[1])
		if m < t + span:
			return [str(ph[0]), (m - t) / span]
		t += span
	return ["", 1.0]


## The boat's middle at `m` minutes into the step (the mooring outside the crossing).
static func boat_at(m: float) -> Vector2:
	var ph := phase(m)
	var e := smoothstep(0.0, 1.0, float(ph[1]))
	match str(ph[0]):
		"out": return mooring().lerp(far(), e)
		"wait": return far()
		"back": return far().lerp(mooring(), e)
	return mooring()


## Where the boat is pushed off its mooring by now, from the poler's place in their plan
## (`w`, Villagers.where; {} for none): the boat's offset in cells (0, 0 when tied up).
static func boat_offset(w: Dictionary) -> Vector2:
	if not w.get("ferrying", false) or str(w.get("map", "")) != map_id():
		return Vector2.ZERO
	return boat_at(float(w.get("ferried", 0.0))) - mooring()


## Is the boat's pole in the poler's hands (from boarding to stepping off)?
static func in_use(w: Dictionary) -> bool:
	return w.get("ferrying", false) and str(w.get("map", "")) == map_id()


## The poler's pose frame: the pole planted high (0), then pushed down (1), each pole_minutes.
static func pole_frame(m: float) -> int:
	return int(floorf(m / float(data().get("pole_minutes", 1.5)))) % 2


## Moves villager place `w` (a DayPlan.where result with `ferrying`, `ferried` and its shore
## `pos`) onto the boat by the step's minutes: down the landing into the stern and off again
## (walking), poling out and back (`poling`), standing at the far bank; `lift` while in the boat.
## Out of season the boat stays tied and they stand on the shore. Returns `w`.
static func ride(w: Dictionary, season: String) -> Dictionary:
	if not w.get("ferrying", false):
		return w
	if not runs_in(season):
		w.ferrying = false
		return w
	var m := float(w.ferried)
	var ph := phase(m)
	var f := float(ph[1])
	var shore: Vector2 = w.pos
	var stern := boat_at(m) + _v("stand")
	var step_on := _v("board_at")
	w.lift = 0.0
	w.poling = false
	match str(ph[0]):
		"board", "off":
			var k := f if ph[0] == "board" else 1.0 - f
			var stern0 := mooring() + _v("stand")
			w.pos = shore.lerp(step_on, k * 2.0) if k < 0.5 else step_on.lerp(stern0, k * 2.0 - 1.0)
			w.moving = true
			w.walked = m * 1.5
			w.facing = Vector2i.DOWN if ph[0] == "board" else Vector2i.UP
			if k >= 0.5:
				w.lift = lift() * (k * 2.0 - 1.0)
		"out", "back":
			w.pos = stern
			w.poling = true
			w.facing = Vector2i.DOWN if ph[0] == "out" else Vector2i.UP
			w.lift = lift()
		"wait":
			w.pos = stern
			w.facing = Vector2i.DOWN
			w.lift = lift()
	return w
