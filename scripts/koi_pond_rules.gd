class_name KoiPondRules
extends RefCounted
## Koi swimming in the temple garden's pond: the rules (data/koi.json). One KoiPondRules is a
## school in one pond (a rect of a map, its water cells with no prop on them), stepped by its
## layer (KoiPondLayer in 3D, KoiPondView in the flat view). Each fish wanders on its own: it
## swims to a random spot of open water it can reach in a straight line, at a pace of its own for
## that leg (`leg`), turning at most `turn` radians a second; there it may stop a while, hanging
## still with its tail barely moving (`rest`), and now and then it pauses on the way too
## (`pause_per_s`). It keeps `margin` off the rocks and over the pond's flat bed, clear of the
## sloping bank (PondShape.on_bed). Fewer fish show in winter, and slower. Pure: positions are in
## cells (x, y as on the map).

const DATA_PATH := "res://data/koi.json"
const TINT := Color(0.86, 0.95, 0.93)   # the water's green over the fish (both views)

static var _cfg: Dictionary = {}

var cells: Dictionary = {}          # Vector2i -> true: the water the fish keep to
var fish: Array[Dictionary] = []    # {pos: Vector2 (cells), heading (radians, 0 = +x), speed (cells/s), aim: Vector2, pattern, rest (s left), phase (tail, radians), share, leg}
var cruise := 0.45
var open: Array = []                # the cells whose middle a fish may be at (allowed), worked out once
var shape: PondShape                # the pond's soft shore (the fish keep over its bed), or null
var _cfg_now: Dictionary
var _rng := RandomNumberGenerator.new()


static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## The ponds (data/koi.json `ponds`) on map `map_id`.
static func ponds_on(map_id: String, cfg: Dictionary = {}) -> Array:
	var c := cfg if not cfg.is_empty() else config()
	return (c.ponds as Array).filter(func(p): return str(p.map) == map_id)


## The water cells of `pond` on `map` the fish swim in: water, inside its rect, no prop on it.
static func water_cells(map: MapData, pond: Dictionary) -> Dictionary:
	var out := {}
	var r := Rect2i(Vector2i(int(pond.cell[0]), int(pond.cell[1])), Vector2i(int(pond.size[0]), int(pond.size[1])))
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if map.tile(c) == "water" and map.prop_at(c).is_empty():
				out[c] = true
	return out


## How many fish show in `season`.
static func count_in(season: String, cfg: Dictionary = {}) -> int:
	var c := cfg if not cfg.is_empty() else config()
	return int((c.count as Dictionary).get(season, 0))


## A school in `pond` of `map` for `season`, placed from `seed`.
static func make(map: MapData, pond: Dictionary, season: String, seed: int, cfg: Dictionary = {}) -> KoiPondRules:
	var k := KoiPondRules.new()
	k._cfg_now = cfg if not cfg.is_empty() else config()
	k._rng.seed = seed
	k.cells = water_cells(map, pond)
	k.shape = PondShape.of(map)
	k.cruise = float(k._cfg_now.speed.winter if season == "winter" else k._cfg_now.speed.cruise)
	k.open = k.cells.keys().filter(func(c: Vector2i) -> bool: return k.allowed(Vector2(c) + Vector2(0.5, 0.5)))
	k.open.sort()
	if k.open.is_empty():
		return k
	var patterns: Array = k._cfg_now.patterns
	var rest: Dictionary = k._cfg_now.rest
	for i in count_in(season, k._cfg_now):
		var at: Vector2 = Vector2(k.open[k._rng.randi() % k.open.size()]) + Vector2(0.5, 0.5)
		var share := 1.0 + k._rng.randf_range(-1.0, 1.0) * float(k._cfg_now.speed.spread)
		k.fish.append({"pos": at, "heading": k._rng.randf() * TAU, "speed": 0.0, "aim": at, "pattern": str(patterns[i % patterns.size()]),
			"rest": k._rng.randf_range(0.0, float(rest.rest_s[1])), "phase": k._rng.randf() * TAU, "share": share, "leg": 1.0})
	return k


## Whether a fish can be at `p` (cells): its cell is the school's water and so are the cells
## `margin` off it in the four ways, all over the flat bed (not on the bank's slope).
func allowed(p: Vector2) -> bool:
	var m := float(_cfg_now.margin)
	for o in [Vector2.ZERO, Vector2(m, 0), Vector2(-m, 0), Vector2(0, m), Vector2(0, -m)]:
		var q: Vector2 = p + o
		if not cells.has(Vector2i(q.floor())) or (shape != null and not shape.on_bed(q)):
			return false
	return true


## Whether the straight swim from `a` to `b` stays in open water.
func clear(a: Vector2, b: Vector2) -> bool:
	var n := maxi(int(ceil(a.distance_to(b) / 0.15)), 1)
	for i in n + 1:
		if not allowed(a.lerp(b, float(i) / n)):
			return false
	return true


## Moves every fish `delta` seconds on.
func step(delta: float) -> void:
	for f in fish:
		_step_fish(f, delta)


## Whether fish `f` is resting (hanging still) now.
static func resting(f: Dictionary) -> bool:
	return float(f.rest) > 0.0


func _step_fish(f: Dictionary, delta: float) -> void:
	var pos: Vector2 = f.pos
	var rest: Dictionary = _cfg_now.rest
	var want := cruise * float(f.share) * float(f.leg)
	if resting(f):
		f.rest = float(f.rest) - delta
		want = float(rest.drift)
		if not resting(f):
			_new_leg(f, pos)
	elif pos.distance_to(f.aim) < 0.3:
		if _rng.randf() < float(rest.chance):
			f.rest = _rng.randf_range(float(rest.rest_s[0]), float(rest.rest_s[1]))
		else:
			_new_leg(f, pos)
	elif _rng.randf() < float(_cfg_now.pause_per_s) * delta:   # a pause on the way
		f.rest = _rng.randf_range(float(rest.rest_s[0]), float(rest.rest_s[1])) * 0.5
	f.speed = move_toward(float(f.speed), want, delta * 0.5)
	var to: Vector2 = (f.aim as Vector2) - pos
	if to.length() > 0.05 and not resting(f):
		var diff := wrapf(to.angle() - float(f.heading), -PI, PI)
		f.heading = float(f.heading) + clampf(diff, -float(_cfg_now.turn) * delta, float(_cfg_now.turn) * delta)
	var next := pos + Vector2.from_angle(float(f.heading)) * float(f.speed) * delta
	if allowed(next):
		f.pos = next
	else:   # nosing a bank or a rock: slow down; a new aim if this one lies behind it
		f.speed = float(f.speed) * 0.5
		if not clear(pos, f.aim):
			_new_leg(f, pos)
	var beat := 0.15 if resting(f) else clampf(0.35 + float(f.speed) / maxf(cruise, 0.01), 0.35, 1.6)
	f.phase = float(f.phase) + delta * TAU * float(_cfg_now.wiggle_hz) * beat


## A new leg for fish `f` at `pos`: a random reachable spot of open water and a pace for it.
func _new_leg(f: Dictionary, pos: Vector2) -> void:
	var leg: Array = _cfg_now.leg
	f.leg = _rng.randf_range(float(leg[0]), float(leg[1]))
	f.aim = _new_aim(pos)


## A random spot of open water reachable from `pos` in a straight line (`pos` when none is).
func _new_aim(pos: Vector2) -> Vector2:
	if open.is_empty():
		return pos
	for i in 16:
		var c: Vector2 = Vector2(open[_rng.randi() % open.size()]) + Vector2(_rng.randf_range(0.15, 0.85), _rng.randf_range(0.15, 0.85))
		if c.distance_to(pos) > 0.8 and allowed(c) and clear(pos, c):
			return c
	return pos


## The tail's frame now for fish `f` (0, 1, 2: bent one way, straight, the other way).
static func frame_of(f: Dictionary) -> int:
	var s := sin(float(f.phase))
	return 0 if s < -0.4 else (2 if s > 0.4 else 1)
