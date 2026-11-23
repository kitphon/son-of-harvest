class_name Companion
extends RefCounted
## The spouse walking to Kawasemi-yu with the farmer (their bath night's ask answered "Let's go
## together": Game.go_bath_together; data/baths.json `together`). Three phases:
## - "walk": they walk behind the farmer along the farmer's own path (a trail of the farmer's feet),
##   `gap` cells back, on whatever map the farmer is on; through a door they come in at the door
##   behind them. Stopping, they stop; the farmer may walk back past them (no blocking, no bumps).
## - "bath": once the farmer goes into the changing room, they go and change too (`change`
##   minutes), then into the bath from its glass door to a seat by the farmer's (`seats`, the first
##   free), soak `bathe` minutes ({"bathe"} step: Villagers.bath_place eases them in and out) and
##   go back out to change.
## - "home": their plain married day (plans.married) for the rest of the day.
## Walking past `give_up` without reaching the bath, or down the mine, they go home. Cleared at
## night, on a new game and a load (not saved). Villagers.where asks `place` for them.

const BATH_MAPS: Array[String] = ["sento_changing", "sento_bath"]
const NO_GO: Array[String] = ["mine", "mine_floor"]   # they don't follow down the mine

static var id := ""
static var phase := ""
static var _map := ""
static var _pos := Vector2.ZERO
static var _trail: Array[Vector2] = []   # the farmer's steps after _pos, oldest first
static var _facing := Vector2i.DOWN
static var _moving := false
static var _walked := 0.0
static var _plan: DayPlan = null         # the bath or home phase's plan
static var _plan_end := 0.0              # the bath plan's last minute (then home)


static func cfg() -> Dictionary:
	return Villagers.baths().get("together", {})


static func has(vid: String) -> bool:
	return vid != "" and vid == id


static func clear() -> void:
	id = ""
	phase = ""
	_map = ""
	_trail.clear()
	_plan = null


## Villager `vid` comes along, starting from where they stand (`w`, as Villagers.where gives).
static func start(vid: String, w: Dictionary) -> void:
	clear()
	id = vid
	phase = "walk"
	_map = str(w.get("map", ""))
	_pos = Vector2(w.get("pos", Vector2.ZERO))
	_facing = w.get("facing", Vector2i.DOWN)


## Every frame (Game._process): the farmer on `map_id` with the feet at `farmer` (cells) at minute `t`
## (`s` Game.trigger_state, for the seats taken).
## Moves the walker along the trail and changes phase.
static func track(map_id: String, farmer: Vector2, t: float, s: Dictionary) -> void:
	if id == "":
		return
	match phase:
		"walk":
			if map_id in NO_GO or t >= float(DayPlan.minute_of(str(cfg().get("give_up", "22:00")))):
				_go_home()
			elif map_id in BATH_MAPS:
				_start_bath(t, s)
			else:
				_follow(map_id, farmer)
		"bath":
			if t >= _plan_end:
				_go_home()


## {map, pos, facing, moving, walked, ...} as DayPlan.where gives, with `companion` true; {} for
## someone else.
static func place(t: float) -> Dictionary:
	var out := {"map": DayPlan.AWAY, "pos": _pos, "facing": _facing, "moving": false, "walked": 0.0, "working": false, "worked": 0.0,
		"fishing": false, "fished": 0.0, "posting": false, "posted": 0.0, "bathing": false, "bathed": 0.0, "bathe_len": 0.0, "ferrying": false, "ferried": 0.0}
	if phase == "walk":
		out.map = _map
		out.moving = _moving
		out.walked = _walked
	elif _plan != null:
		out = _plan.where(t)
	out.companion = phase != "home"
	return out


static func _follow(map_id: String, farmer: Vector2) -> void:
	if map_id != _map:   # through a door: in at the farmer's spot, the door, behind them
		_map = map_id
		_pos = farmer
		_trail.clear()
	if _trail.is_empty() or _trail.back().distance_to(farmer) >= 0.05:
		_trail.append(farmer)
	var gap := float(cfg().get("gap", 1.2))
	var length := 0.0
	var at := _pos
	for p in _trail:
		length += at.distance_to(p)
		at = p
	var need := length - gap
	var was := _pos
	while need > 0.0 and not _trail.is_empty():
		var seg := _trail[0] - _pos
		if seg.length() <= need:
			need -= seg.length()
			_pos = _trail.pop_front()
		else:
			_pos += seg.normalized() * need
			need = 0.0
	var step := _pos - was
	_moving = step.length() > 0.001
	if _moving:
		_walked += step.length()
		_facing = DayPlan.facing_of(step)


## Into the bath by the farmer: a plan of its own from minute `t`.
static func _start_bath(t: float, s: Dictionary) -> void:
	var c := cfg()
	var now := ceili(t)
	var seat := int(c.get("seats", [6])[0])
	var taken := Villagers.bath_seats("sento_bath", t + float(c.get("change", 3)), s)
	for x in c.get("seats", [6]):
		if not taken.has(Vector2i(int(x), 3)):
			seat = int(x)
			break
	var speed := Villagers.speed_of(Villagers.all().get(id, {}))
	var walk := ceili(float(absi(seat - 1)) / speed) + 1
	var t_in := now + int(c.get("change", 3))
	var t_out := t_in + walk + int(c.get("bathe", 50))
	var t_gone := t_out + walk
	var r := DayPlan.build([
		{"at": "06:00", "map": DayPlan.AWAY},
		{"at": _hm(t_in), "map": "sento_bath", "from": [1, 3], "route": [{"to": [seat, 3]}, {"face": "up"}, {"bathe": int(c.get("bathe", 50))}]},
		{"at": _hm(t_out), "map": "sento_bath", "route": [{"to": [1, 3]}, {"face": "left"}]},
		{"at": _hm(t_gone), "map": DayPlan.AWAY}], speed)
	if r[0] != "":
		push_error("Companion bath: " + r[0])
		_go_home()
		return
	_plan = r[1]
	_plan_end = float(t_gone + int(c.get("change", 3)))
	phase = "bath"


static func _go_home() -> void:
	var v: Dictionary = Villagers.all().get(id, {})
	var r := DayPlan.build(v.get("plans", {}).get("married", [{"at": "06:00", "map": DayPlan.AWAY}]), Villagers.speed_of(v))
	_plan = r[1] if r[0] == "" else null
	phase = "home"


static func _hm(m: int) -> String:
	return "%02d:%02d" % [(m / 60) % 24, m % 60]
