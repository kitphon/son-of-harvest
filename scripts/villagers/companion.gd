class_name Companion
extends RefCounted
## The spouse walking to Kawasemi-yu with the farmer (their bath night's ask answered "Let's go
## together": Game.go_bath_together; data/baths.json `together`). Three phases:
## - "walk": they walk behind the farmer along the farmer's own path (a trail of the farmer's feet),
##   `gap` cells back, on whatever map the farmer is on; through a door they come in at the door
##   behind them. Stopping, they stop; with the farmer back within `gap` they stand and face them,
##   and a loop of the trail passing by them (`loop_cut`) is cut, so they never walk on to where the
##   farmer was; the farmer may walk back past them (no blocking, no bumps).
## - "bath": once the farmer goes into the changing room, they go and change too (`change`
##   minutes), then into the bath from its glass door to a seat by the farmer's (`seats`, the first
##   free) and stay in the water ({"bathe"} step: Villagers.bath_place eases them in and out) as long
##   as the farmer does: when the farmer gets out of the tub (or leaves the room, or the bath is about
##   to shut at `close`) they get out too and say so (wed_bath_out; the user found it strange that the
##   spouse got up and left on their own, as if strangers).
## - "dress": off to the changing room (`change` minutes), then
## - "walk_back": behind the farmer again, out through the lobby's noren, all the way home, and
## - "settled": in the farmhouse they stay by the door and say they are glad they went (wed_bath_home).
## - "home": their plain married day (plans.married), when they gave up on the way.
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
static var _plan_end := 0.0              # when dressing is done (then the walk back)
static var _seat := 6                    # the tub's cell they sit before
static var _in_at := 0.0                 # the minute they come into the bath's room
static var _sat_at := 0.0                # the minute they are settled in the water
static var _was_soaking := false         # the farmer has been in the water with them
## A line of theirs to say now (talk_<id>.json): "wed_bath_out" getting out with the farmer,
## "wed_bath_home" home again. Game says it and clears it.
static var say := ""
const NOREN := Vector2(6.5, 4.5)         # in the lobby by the noren from the changing room (data/maps/sento.json)


static func cfg() -> Dictionary:
	return Villagers.baths().get("together", {})


static func has(vid: String) -> bool:
	return vid != "" and vid == id


static func clear() -> void:
	id = ""
	phase = ""
	say = ""
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
## (`s` Game.trigger_state, for the seats taken), `soaking` whether the farmer sits in a bath now.
## Moves the walker along the trail and changes phase.
static func track(map_id: String, farmer: Vector2, t: float, s: Dictionary, soaking := false) -> void:
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
			if soaking:
				_was_soaking = true
			# The farmer up out of the water (having been in), out of the bath's room, or the bath about to
			# shut: out together.
			var closing := float(DayPlan.minute_of(str(cfg().get("close", "22:50"))))
			if (_was_soaking and not soaking) or (map_id != "sento_bath" and t >= _in_at) or t >= closing:
				leave_bath(t)
		"dress":
			if t >= _plan_end and not map_id in BATH_MAPS:
				phase = "walk_back"
				_map = ""   # in behind the farmer on their map: the lobby's noren, or the door they came through
				if map_id == "sento":
					_map = "sento"
					_pos = NOREN
					_trail.clear()
				_follow(map_id, farmer)
		"walk_back":
			if map_id in NO_GO:
				_go_home()
			elif map_id == MapManager.HOME and _map == MapManager.HOME and _pos.distance_to(farmer) >= float(cfg().get("gap", 1.2)) - 0.05:
				phase = "settled"   # home again: in through the door they stay there, and say so
				_moving = false
				_facing = DayPlan.facing_of(farmer - _pos)
				say = "wed_bath_home"
			else:
				_follow(map_id, farmer)


## Out of the water now (minute `t`): eased up out of the tub by the seat they sat at, to the glass
## door and off to dress (`change` minutes); then they walk home behind the farmer. Says a line
## ("wed_bath_out") when they were in the water with the farmer.
static func leave_bath(t: float) -> void:
	var c := cfg()
	var speed := Villagers.speed_of(Villagers.all().get(id, {}))
	var walk := ceili(float(absi(_seat - 1)) / speed) + 1
	var now := ceili(t)
	if t < _in_at:   # still changing: off to dress again at once
		_plan = DayPlan.build([{"at": "06:00", "map": DayPlan.AWAY}], speed)[1]
		_plan_end = float(now + int(c.get("change", 3)))
		phase = "dress"
		return
	var b: Dictionary = Villagers.baths().get("sento", {})
	var t0 := floori(t) - int(ceil(float(b.get("villager_in", 3.0)))) - 1   # in the water since then: fully sat
	var t_up := now + int(ceil(float(b.get("villager_out", 2.5))))
	var r := DayPlan.build([
		{"at": "06:00", "map": DayPlan.AWAY},
		{"at": _hm(t0), "map": "sento_bath", "from": [_seat, 3], "route": [{"face": "up"}, {"bathe": t_up - t0}]},
		{"at": _hm(t_up), "map": "sento_bath", "route": [{"to": [1, 3]}, {"face": "left"}]},
		{"at": _hm(t_up + walk), "map": DayPlan.AWAY}], speed)
	if r[0] != "":
		push_error("Companion out of the bath: " + r[0])
		_go_home()
		return
	if t >= _sat_at:
		say = "wed_bath_out"
	_plan = r[1]
	_plan_end = float(t_up + walk + int(c.get("change", 3)))
	phase = "dress"


## {map, pos, facing, moving, walked, ...} as DayPlan.where gives, with `companion` true; {} for
## someone else.
static func place(t: float) -> Dictionary:
	var out := {"map": DayPlan.AWAY, "pos": _pos, "facing": _facing, "moving": false, "walked": 0.0, "working": false, "worked": 0.0,
		"fishing": false, "fished": 0.0, "posting": false, "posted": 0.0, "bathing": false, "bathed": 0.0, "bathe_len": 0.0, "ferrying": false, "ferried": 0.0}
	if phase in ["walk", "walk_back", "settled"]:
		out.map = _map if _map != "" else DayPlan.AWAY
		out.moving = _moving and phase != "settled"
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
	# The farmer back within reach (turned round, walking to them): stand and face them, the trail
	# forgotten, so no one walks on to where the farmer was and through them (the user saw them walk
	# backwards after the farmer, back and forth).
	if _pos.distance_to(farmer) <= gap:
		_trail.clear()
		_trail.append(farmer)
		_moving = false
		if _pos.distance_to(farmer) > 0.05:
			_facing = DayPlan.facing_of(farmer - _pos)
		return
	# A loop in the trail coming back past them (the farmer went on, turned and came back by): cut it,
	# going on from the last of the farmer's steps that passes close by.
	for k in range(_trail.size() - 1, 0, -1):
		if _trail[k].distance_to(_pos) <= float(cfg().get("loop_cut", 0.5)):
			_trail = _trail.slice(k)
			break
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


## Into the bath by the farmer: a plan of its own from minute `t`, changing first, then in the water
## at a seat by the farmer's until the farmer gets out (leave_bath).
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
	var closing := DayPlan.minute_of(str(c.get("close", "22:50")))
	var stay := maxi(closing - t_in - walk, 1)   # in the water till the farmer gets out (or the bath shuts)
	var r := DayPlan.build([
		{"at": "06:00", "map": DayPlan.AWAY},
		{"at": _hm(t_in), "map": "sento_bath", "from": [1, 3], "route": [{"to": [seat, 3]}, {"face": "up"}, {"bathe": stay}]},
		{"at": _hm(t_in + walk + stay), "map": DayPlan.AWAY}], speed)
	if r[0] != "":
		push_error("Companion bath: " + r[0])
		_go_home()
		return
	_plan = r[1]
	_seat = seat
	_in_at = float(t_in)
	_sat_at = float(t_in + walk) + float(Villagers.baths().get("sento", {}).get("villager_in", 3.0))
	_was_soaking = false
	phase = "bath"


static func _go_home() -> void:
	var v: Dictionary = Villagers.all().get(id, {})
	var r := DayPlan.build(v.get("plans", {}).get("married", [{"at": "06:00", "map": DayPlan.AWAY}]), Villagers.speed_of(v))
	_plan = r[1] if r[0] == "" else null
	phase = "home"


static func _hm(m: int) -> String:
	return "%02d:%02d" % [(m / 60) % 24, m % 60]
