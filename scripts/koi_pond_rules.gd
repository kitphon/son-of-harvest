class_name KoiPondRules
extends RefCounted
## Koi swimming in the temple garden's pond: the rules (data/koi.json). One KoiPondRules is a
## school in one pond (a rect of a map, its water cells with no prop on them), stepped by its
## layer (KoiPondLayer in 3D, KoiPondView in the flat view): each fish cruises toward an aim (a
## cell's middle it can reach in a straight line through open water), turning at most `turn`
## radians a second, never closer than `margin` to a bank or a rock; on reaching it some rest,
## drifting slowly, then pick a new aim. A fish near the farmer standing on the bank aims for the
## water by his feet more often (koi come for food). Fewer fish show in winter, and slower.
## Pure: positions are in cells (x, y as on the map), the farmer's spot is passed in.

const DATA_PATH := "res://data/koi.json"
const TINT := Color(0.86, 0.95, 0.93)   # the water's green over the fish (both views)

static var _cfg: Dictionary = {}

var cells: Dictionary = {}          # Vector2i -> true: the water the fish keep to
var fish: Array[Dictionary] = []    # {pos: Vector2 (cells), heading (radians, 0 = +x), speed (cells/s), aim: Vector2, pattern, rest (s left), phase (tail, radians), share}
var cruise := 0.45
var open: Array = []                # the cells whose middle a fish may be at (allowed), worked out once
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
	k.cruise = float(k._cfg_now.speed.winter if season == "winter" else k._cfg_now.speed.cruise)
	k.open = k.cells.keys().filter(func(c: Vector2i) -> bool: return k.allowed(Vector2(c) + Vector2(0.5, 0.5)))
	k.open.sort()
	var open := k.open
	if open.is_empty():
		return k
	var patterns: Array = k._cfg_now.patterns
	for i in count_in(season, k._cfg_now):
		var at: Vector2 = Vector2(open[k._rng.randi() % open.size()]) + Vector2(0.5, 0.5)
		var share := 1.0 + k._rng.randf_range(-1.0, 1.0) * float(k._cfg_now.speed.spread)
		k.fish.append({"pos": at, "heading": k._rng.randf() * TAU, "speed": 0.0, "aim": at, "pattern": str(patterns[i % patterns.size()]),
			"rest": k._rng.randf_range(0.0, 2.0), "phase": k._rng.randf() * TAU, "share": share})
	return k


## Whether a fish can be at `p` (cells): its cell is the school's water and so are the cells
## `margin` off it in the four ways.
func allowed(p: Vector2) -> bool:
	var m := float(_cfg_now.margin)
	for o in [Vector2.ZERO, Vector2(m, 0), Vector2(-m, 0), Vector2(0, m), Vector2(0, -m)]:
		if not cells.has(Vector2i((p + o).floor())):
			return false
	return true


## Whether the straight swim from `a` to `b` stays in open water.
func clear(a: Vector2, b: Vector2) -> bool:
	var n := maxi(int(ceil(a.distance_to(b) / 0.15)), 1)
	for i in n + 1:
		if not allowed(a.lerp(b, float(i) / n)):
			return false
	return true


## Moves every fish `delta` seconds on; `farmer` is the farmer's spot (cells) or null.
func step(delta: float, farmer: Variant = null) -> void:
	for f in fish:
		_step_fish(f, delta, farmer)


func _step_fish(f: Dictionary, delta: float, farmer: Variant) -> void:
	var pos: Vector2 = f.pos
	var want := cruise * float(f.share)
	if float(f.rest) > 0.0:
		f.rest = float(f.rest) - delta
		want *= 0.2
		if float(f.rest) <= 0.0:
			f.aim = _new_aim(pos, farmer)
	elif pos.distance_to(f.aim) < 0.3:
		var rest: Dictionary = _cfg_now.rest
		if _rng.randf() < float(rest.chance):
			f.rest = _rng.randf_range(float(rest.rest_s[0]), float(rest.rest_s[1]))
		else:
			f.aim = _new_aim(pos, farmer)
	f.speed = move_toward(float(f.speed), want, delta * 0.6)
	var to: Vector2 = (f.aim as Vector2) - pos
	if to.length() > 0.05:
		var diff := wrapf(to.angle() - float(f.heading), -PI, PI)
		f.heading = float(f.heading) + clampf(diff, -float(_cfg_now.turn) * delta, float(_cfg_now.turn) * delta)
	var next := pos + Vector2.from_angle(float(f.heading)) * float(f.speed) * delta
	if allowed(next):
		f.pos = next
	else:   # nosing a bank: slow down, turn hard toward the aim (a new one if it lies behind the bank)
		f.speed = float(f.speed) * 0.5
		if not clear(pos, f.aim):
			f.aim = _new_aim(pos, farmer)
	f.phase = float(f.phase) + delta * TAU * float(_cfg_now.wiggle_hz) * clampf(0.35 + float(f.speed) / maxf(cruise, 0.01), 0.35, 1.6)


## A new aim from `pos`: a reachable cell's middle, the water by the farmer's feet more often when
## he stands within reach on the bank.
func _new_aim(pos: Vector2, farmer: Variant) -> Vector2:
	var g: Dictionary = _cfg_now.gather
	if farmer is Vector2 and pos.distance_to(farmer) <= float(g.reach) and _rng.randf() < float(g.chance):
		var near := nearest_to(farmer)
		if near != Vector2.INF and clear(pos, near):
			return near
	if open.is_empty():
		return pos
	for i in 12:
		var c: Vector2 = Vector2(open[_rng.randi() % open.size()]) + Vector2(0.5, 0.5)
		if c.distance_to(pos) > 0.6 and clear(pos, c):
			return c
	return pos


## The open water cell's middle nearest `p` (Vector2.INF when there is none).
func nearest_to(p: Vector2) -> Vector2:
	var best := Vector2.INF
	for c in open:
		var m := Vector2(c) + Vector2(0.5, 0.5)
		if best == Vector2.INF or m.distance_to(p) < best.distance_to(p):
			best = m
	return best


## The tail's frame now for fish `f` (0, 1, 2: bent one way, straight, the other way).
static func frame_of(f: Dictionary) -> int:
	var s := sin(float(f.phase))
	return 0 if s < -0.4 else (2 if s > 0.4 else 1)
