class_name BirdRules
extends RefCounted
## Small birds on the outdoor maps (data/birds.json): swallows darting low over spring and
## summer days, a flock of crows flying home at dusk in every season, a heron standing by the
## water in the morning (and lifting off), sparrows hopping on the ground by the houses that fly
## off when the farmer comes near. This is the logic both views share: which kinds show now
## (season, weather look, clock, indoors or not: DriftRules.amount does the window), how many, and
## where each bird is at a time `t` (cells x, height, z), which of its pictures it shows (BirdArt
## key "bird:<kind>:<pose>:<frame>") and which way it faces. The 3D view (BirdLayer) draws them
## as billboards, the flat view (BirdView) from above in pixels. Pure: a bird's place is a
## function of its arguments (a seeded hash, no random numbers); the only memory is the caller's
## `state` dictionary of who has been startled and when. Nothing here draws.

const DATA_PATH := "res://data/birds.json"
const KINDS: Array[String] = ["swallow", "crow", "heron", "sparrow"]
const NO_FARMER := Vector2(-9999.0, -9999.0)
const NO_AIM := Vector2(-99999.0, -99999.0)   # not forced (see forced())

static var _cfg: Dictionary = {}
static var _forced: Array = []
static var _forced_read := false


## data/birds.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## `-- --birds` (every kind) or `--birds=crow,heron` on the command line: those kinds show at full
## strength whatever the season, weather and clock (screenshots), caught mid-flight or standing.
static func forced() -> Array:
	if not _forced_read:
		_forced_read = true
		for arg in OS.get_cmdline_user_args():
			if arg == "--birds":
				_forced = KINDS.duplicate()
			elif arg.begins_with("--birds="):
				for k in arg.trim_prefix("--birds=").split(","):
					if k in KINDS:
						_forced.append(k)
	return _forced


## A steady pseudo-random number in 0..1 from three integers (the drift's, so everywhere the same).
static func rnd(a: int, b: int, c: int) -> float:
	return DriftRules.rnd(a, b, c)


## How much of kind `kind` shows: 0..1 (the window, the season and the weather look as in
## data/drift.json).
static func amount(kind: String, season_id: String, look: String, hour: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	return DriftRules.amount(kind, season_id, look, hour, cfg)


## What shows now on the map `m` (MapData): {kind: amount} for the kinds above 0. None indoors or
## in the mine, or without a clock (`game` is the Game autoload).
static func amounts_now(game: Object, m: MapData, cfg := {}) -> Dictionary:
	var out := {}
	if game == null or m == null or m.indoor or m.sheltered:
		return out
	if cfg.is_empty():
		cfg = config()
	var look: String = game.weather_look(game.weather_today, game.season_name())
	var hour := float(game.hour) + float(game.minute) / 60.0
	for kind in KINDS:
		var a := amount(kind, game.season_name(), look, hour, cfg)
		if kind in forced():
			a = 1.0
		if a > 0.0:
			out[kind] = a
	return out


## How many birds of `kind` show at `amount_now` (0..1): the data's count scaled, at least one.
static func count_for(kind: String, amount_now: float, cfg := {}) -> int:
	if amount_now <= 0.0:
		return 0
	if cfg.is_empty():
		cfg = config()
	return maxi(int(round(float(cfg[kind].count) * clampf(amount_now, 0.0, 1.0))), 1)


## The places a map's birds use: {area: Rect2 in cells, houses: spots on the ground in front of
## the houses (sparrows), shore: water and paddy cell centres that touch dry ground (the heron),
## seed: an int that changes the choices day to day}. `farm` (FarmGrid) gives the farm's pond and
## the farmhouse door; `seed` is usually Game.day + 28 x season.
static func scene_of(m: MapData, farm: FarmGrid = null, seed_value := 0) -> Dictionary:
	var s := {"area": Rect2(0, 0, m.w, m.h), "houses": [] as Array[Vector2], "shore": [] as Array[Vector2], "seed": seed_value}
	if farm != null:
		for y in m.h:
			for x in m.w:
				var c := Vector2i(x, y)
				if str(farm.fixed.get(c, "")) == "pond":
					for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
						if str(farm.fixed.get(c + d, "")) != "pond":
							s.shore.append(Vector2(x, y) + Vector2(0.5, 0.5))
							break
		for c in farm.fixed:
			if str(farm.fixed[c]) == "door":
				for dx in [-2, 2]:
					var at := Vector2i(c.x + dx, c.y + 2)
					if not farm.fixed.has(at) and farm.in_bounds(at):
						s.houses.append(Vector2(at) + Vector2(0.5, 0.5))
		return s
	for y in m.h:
		for x in m.w:
			var c := Vector2i(x, y)
			if _wet(m, c):
				for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					if m.in_bounds(c + d) and not _wet(m, c + d):
						s.shore.append(Vector2(x, y) + Vector2(0.5, 0.5))
						break
	for p in m.props:
		if str(p.get("kind", "")) != "village_house":
			continue
		var cell := Vector2i(int(p.cell[0]), int(p.cell[1]))
		var size := Vector2i(int(p.size[0]), int(p.size[1]))
		for dx in [0, size.x - 1]:
			var at := Vector2i(cell.x + dx, cell.y + size.y)
			if m.in_bounds(at) and not m.is_solid(at) and m.tile(at) in ["grass", "path", "gravel"]:
				s.houses.append(Vector2(at) + Vector2(0.5, 0.5))
	return s


static func _wet(m: MapData, c: Vector2i) -> bool:
	var t := m.tile(c)
	return t == "water" or t == "paddy"


## Every bird of `kind` now (`t` seconds, `amount_now` 0..1) for a scene from scene_of, the
## farmer's place in cells (NO_FARMER when there is none) and `state`, a Dictionary the caller
## keeps from frame to frame (who was startled and when: this fills it in). Each:
## {id: "kind:i", kind, pos: Vector3 (x, height, z) in cells, pose, frame, dir: Vector2 (the way it
## heads or faces, cells), alpha}. The pictures are "bird:<kind>:<pose>:<frame>" (BirdArt).
static func birds(kind: String, amount_now: float, t: float, scene: Dictionary, farmer: Vector2, state: Dictionary, cfg := {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n := count_for(kind, amount_now, cfg)
	if n == 0:
		return out
	if cfg.is_empty():
		cfg = config()
	var k: Dictionary = cfg[kind]
	# Forced (`--birds`): the birds are placed round `aim` (the farmer, else the map's middle) at t = 0.
	var aim := NO_AIM
	if kind in forced():
		aim = farmer if farmer != NO_FARMER else (scene.area as Rect2).get_center()
	match kind:
		"swallow":
			for i in n:
				var b := _swallow(i, k, t, scene, aim)
				if not b.is_empty():
					out.append(b)
		"crow":
			out.append_array(_crows(n, k, t, scene, aim))
		"heron":
			for i in n:
				var b := _heron(i, k, t, scene, farmer, state, aim)
				if not b.is_empty():
					out.append(b)
		"sparrow":
			for i in n:
				var b := _sparrow(i, k, t, scene, farmer, state, aim)
				if not b.is_empty():
					out.append(b)
	return out


## The picture key of a bird from birds().
static func key_of(b: Dictionary) -> String:
	return "bird:%s:%s:%d" % [b.kind, b.pose, int(b.frame)]


## A straight crossing of the map's width, edge to edge, from rnd-chosen sides: [from, to] in cells
## (a little past each edge, so a bird comes in from out of sight).
static func _crossing(i: int, cycle: int, area: Rect2) -> Array:
	var from_left := rnd(i, cycle, 1) < 0.5
	var y0 := area.position.y + rnd(i, cycle, 2) * area.size.y
	var y1 := clampf(y0 + (rnd(i, cycle, 3) - 0.5) * area.size.y * 0.7, area.position.y, area.end.y)
	var xa := area.position.x - 3.0
	var xb := area.end.x + 3.0
	return [Vector2(xa, y0), Vector2(xb, y1)] if from_left else [Vector2(xb, y0), Vector2(xa, y1)]


## The seconds into a crossing (`dur` long along `line`) at which a bird is over column `x`.
static func _u_at(line: Array, x: float, dur: float) -> float:
	var a: float = (line[0] as Vector2).x
	var b: float = (line[1] as Vector2).x
	return clampf((x - a) / (b - a), 0.0, 1.0) * dur


static func _flap_frame(tt: float, flap: float, offset: float) -> int:
	var ph := fposmod(tt * flap + offset, 1.0)
	return [0, 1, 2, 1][int(ph * 4.0) % 4]


static func _swallow(i: int, k: Dictionary, t: float, scene: Dictionary, aim: Vector2) -> Dictionary:
	var area: Rect2 = scene.area
	var period := float(k.period)
	var speed := float(k.speed)
	var dur := (area.size.x + 6.0) / speed
	var tt := t + rnd(i, 0, 7) * period
	var cycle := floori(tt / period)
	var line := _crossing(i, cycle, area)
	if aim != NO_AIM:   # forced: this one is at the aim's column now, a little above it
		cycle = 0
		line = _crossing(i, 0, area)
		var y := aim.y + (float(i) - 1.5) * 0.9 - 1.0
		line = [Vector2((line[0] as Vector2).x, y), Vector2((line[1] as Vector2).x, y)]
		tt = _u_at(line, aim.x, dur) + t + float(i) * 0.35
	var u := tt - float(cycle) * period
	if u > dur:
		return {}
	var v := u / dur
	var ph := rnd(i, cycle, 4) * TAU
	var at := _swallow_at(line, v, ph, k)
	var ahead := _swallow_at(line, minf(v + 0.02, 1.0), ph, k)
	var hs: Array = k.height
	var h := lerpf(float(hs[0]), float(hs[1]), 0.5 + 0.5 * sin(v * TAU * 1.7 + ph))
	var glide := sin(v * TAU * 2.2 + ph) > cos(PI * float(k.glide))
	return {
		"id": "swallow:%d" % i, "kind": "swallow", "pos": Vector3(at.x, h, at.y),
		"pose": "fly", "frame": 1 if glide else _flap_frame(tt, float(k.flap), rnd(i, 0, 8)),
		"dir": ahead - at, "alpha": 1.0,
	}


static func _swallow_at(line: Array, v: float, ph: float, k: Dictionary) -> Vector2:
	var p: Vector2 = (line[0] as Vector2).lerp(line[1], v)
	return p + Vector2(0, sin(v * TAU * float(k.dart_cycles) + ph) * float(k.dart))


static func _crows(n: int, k: Dictionary, t: float, scene: Dictionary, aim: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var area: Rect2 = scene.area
	var period := float(k.period)
	var dur := (area.size.x + 6.0) / float(k.speed)
	var tt := t + rnd(0, 0, 9) * period
	var cycle := floori(tt / period)
	var line := _crossing(0, cycle, area)
	if aim != NO_AIM:   # forced: the flock is over the aim's column, a little above it
		cycle = 0
		line = _crossing(0, 0, area)
		var y := aim.y + 1.5
		line = [Vector2((line[0] as Vector2).x, y), Vector2((line[1] as Vector2).x, y)]
		tt = _u_at(line, aim.x, dur) + t
	var heading := ((line[1] as Vector2) - (line[0] as Vector2)).normalized()
	var side := Vector2(-heading.y, heading.x)
	var hs: Array = k.height
	for j in n:
		var u := tt - float(cycle) * period - float(j) * float(k.stagger) * (0.4 + rnd(j, cycle, 1))
		if u < 0.0 or u > dur:
			continue
		var v := u / dur
		var p: Vector2 = (line[0] as Vector2).lerp(line[1], v)
		p += side * (rnd(j, cycle, 2) - 0.5) * float(k.spread) + heading * (rnd(j, cycle, 3) - 0.5) * float(k.spread) * 0.6
		var h := lerpf(float(hs[0]), float(hs[1]), rnd(j, cycle, 4)) + sin(u * 1.3 + rnd(j, cycle, 5) * TAU) * 0.15
		out.append({
			"id": "crow:%d" % j, "kind": "crow", "pos": Vector3(p.x, h, p.y), "pose": "fly",
			"frame": _flap_frame(u, float(k.flap), rnd(j, cycle, 6)), "dir": heading, "alpha": 1.0,
		})
	return out


## Seconds since this bird was startled by the farmer, or -1.0 while it was not (and it is not
## startled now). `present` is whether it stands there now; it only startles then. The bird
## returns once `return_after` seconds have passed and the farmer is further than 1.5 x scare.
static func _startled(key: String, home: Vector2, farmer: Vector2, t: float, present: bool, k: Dictionary, state: Dictionary) -> float:
	var scare := float(k.scare)
	if state.has(key):
		var el := t - float((state[key] as Array)[0])
		if el > float(k.return_after) and farmer.distance_to(home) > scare * 1.5:
			state.erase(key)
			return -1.0
		return el
	if present and farmer.distance_to(home) < scare:
		var away := (home - farmer).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		state[key] = [t, away]
		return 0.0
	return -1.0


## A bird leaving its spot: `w` 0..1 along the way, heading `dir`, rising to `rise` cells.
static func _leaving(home: Vector2, dir: Vector2, w: float, dist: float, rise: float, lift: float) -> Vector3:
	var e := pow(w, 1.3)
	var p := home + dir * dist * e
	return Vector3(p.x, lift + rise * minf(e * 2.0, 1.0), p.y)


static func _heron(i: int, k: Dictionary, t: float, scene: Dictionary, farmer: Vector2, state: Dictionary, aim: Vector2) -> Dictionary:
	var shore: Array = scene.shore
	if shore.is_empty():
		return {}
	var sd := int(scene.seed)
	var home: Vector2 = shore[int(rnd(i, sd, 11) * shore.size()) % shore.size()]
	if aim != NO_AIM:   # forced: the shore cell nearest the aim
		for c in shore:
			if (c as Vector2).distance_to(aim) < home.distance_to(aim):
				home = c
	var face := Vector2.RIGHT if rnd(i, sd, 12) < 0.5 else Vector2.LEFT
	var period := float(k.period)
	var tt := t + (period * 0.3 if aim != NO_AIM else rnd(i, 0, 3) * period)
	var cycle := floori(tt / period)
	var u := tt - float(cycle) * period
	var s := u / period
	var key := "heron:%d" % i
	var fly_time := float(k.fly_time)
	var dist := float(k.fly_dist)
	var rise := float(k.fly_height)
	var standing := s >= float(k.land) and s < float(k.stand)
	var el := _startled(key, home, farmer, t, standing and not state.has(key), k, state)
	var b := {"id": key, "kind": "heron", "alpha": 1.0}
	if el >= 0.0:   # startled: lifts off away from the farmer
		var w := el / fly_time
		if w > 1.0:
			return {}
		var away: Vector2 = (state[key] as Array)[1]
		b.pos = _leaving(home, away, w, dist, rise, 0.0)
		b.pose = "fly"
		b.frame = _flap_frame(el, float(k.flap), 0.0)
		b.dir = away
		return b
	var angle := rnd(i, cycle, 6) * TAU
	var dir := Vector2(cos(angle), sin(angle))
	if s < float(k.land):   # gliding in
		var w := 1.0 - s / float(k.land)
		b.pos = _leaving(home, dir, w, dist * 0.25, rise * 0.5, 0.0)
		b.pose = "fly"
		b.frame = _flap_frame(u, float(k.flap), 0.0)
		b.dir = -dir
		return b
	if standing:
		b.pos = Vector3(home.x, 0.0, home.y)
		b.pose = "stand"
		b.frame = 1 if fposmod(tt / 7.0 + rnd(i, 0, 5), 1.0) < 0.3 else 0
		b.dir = face
		return b
	var w := (u - float(k.stand) * period) / fly_time   # the morning's own lift-off
	if w > 1.0:
		return {}
	b.pos = _leaving(home, dir, w, dist, rise, 0.0)
	b.pose = "fly"
	b.frame = _flap_frame(u, float(k.flap), 0.0)
	b.dir = dir
	return b


static func _sparrow(i: int, k: Dictionary, t: float, scene: Dictionary, farmer: Vector2, state: Dictionary, aim: Vector2) -> Dictionary:
	var houses: Array = scene.houses
	if houses.is_empty():
		return {}
	var sd := int(scene.seed)
	var g := i / maxi(int(k.group), 1)
	var spot: Vector2 = houses[int(rnd(g, sd, 21) * houses.size()) % houses.size()]
	if aim != NO_AIM:   # forced: the group's spots are the nearest to the aim that are not under his feet
		var by_dist := houses.filter(func(c): return (c as Vector2).distance_to(aim) > float(k.scare) + 0.6)
		by_dist.sort_custom(func(a, b): return (a as Vector2).distance_to(aim) < (b as Vector2).distance_to(aim))
		if not by_dist.is_empty():
			spot = by_dist[g % by_dist.size()]
	var home := spot + Vector2(rnd(i, sd, 22) - 0.5, rnd(i, sd, 23) - 0.5) * 1.2
	var key := "sparrow:%d" % i
	var el := _startled(key, home, farmer, t, true, k, state)
	var b := {"id": key, "kind": "sparrow", "alpha": 1.0}
	if el >= 0.0:
		var w := el / float(k.fly_time)
		if w > 1.0:
			return {}
		var away: Vector2 = (state[key] as Array)[1]
		b.pos = _leaving(home, away, w, float(k.fly_dist), float(k.fly_height), 0.1)
		b.pose = "fly"
		b.frame = int(fposmod(el * float(k.flap), 2.0))
		b.dir = away
		return b
	var per := float(k.hop) + (rnd(i, 0, 31) - 0.5) * 2.0 * float(k.hop_var)
	var tt := t + rnd(i, 0, 32) * per * 10.0
	var seg := floori(tt / per)
	var ph := tt - float(seg) * per
	var wander := float(k.wander)
	var to := home + (Vector2(rnd(i, seg, 41), rnd(i, seg, 42)) - Vector2(0.5, 0.5)) * wander
	var from := home + (Vector2(rnd(i, seg - 1, 41), rnd(i, seg - 1, 42)) - Vector2(0.5, 0.5)) * wander
	var heading := to - from
	if heading.length() < 0.05:
		heading = Vector2.RIGHT if rnd(i, seg, 44) < 0.5 else Vector2.LEFT
	b.dir = heading
	var hop := float(k.hop_time)
	if ph < hop:
		var p := from.lerp(to, ph / hop)
		b.pos = Vector3(p.x, float(k.hop_height) * sin(PI * ph / hop), p.y)
		b.pose = "hop"
		b.frame = 0
		return b
	b.pos = Vector3(to.x, 0.0, to.y)
	var pecking := rnd(i, seg, 43) < 0.45 and ph > per * 0.4 and ph < per * 0.8
	b.pose = "peck" if pecking else "stand"
	b.frame = 0
	return b
