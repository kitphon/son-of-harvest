class_name HoshigakiRules
extends RefCounted
## Hoshigaki: strings of peeled persimmons drying under the eaves in late fall (data/hoshigaki.json).
## The logic both views share: when they hang (the fall's window of days, outdoors only, taken in
## on a day of rain, storm or snow), how far they have dried (by the days hung: from fresh bright
## orange to a shrunken deep red-brown, in picture stages), how they sway with the wind
## (data/wind.json: still in dead calm, a slow swing growing with the wind), which houses hang
## them (the farmhouse always, the village houses by a hash of their cell) and where the strings
## hang along an eave (spots from a hash of the eave's ends, clear of the doors). The 3D view
## (HoshigakiLayer) hangs them from the real eave lines the roof builders list (FarmWorld.eaves),
## the flat view (HoshigakiView) under the painted roofs' bottom eave; the pictures are
## HoshigakiArt's. Pure: nothing here draws. `--hoshigaki` (or `--hoshigaki=<days hung>`) forces
## them out on an outdoor map whatever the date and weather.

const DATA_PATH := "res://data/hoshigaki.json"
const KEY := "hoshigaki"
const NONE := -1   # forced(): not forced
const STEP_BIG := 3     # picture rows between one persimmon's stem and the next (3D picture)
const STEP_SMALL := 2   # the same in the flat view's smaller picture

static var _cfg: Dictionary = {}
static var _forced_read := false
static var _forced := NONE
static var _forced_on := false


## data/hoshigaki.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## Whether `--hoshigaki` (or `--hoshigaki=N`) asks for them; reads the command line once.
static func forced_on() -> bool:
	_read_force()
	return _forced_on


## The days hung `--hoshigaki=N` asks for, NONE for plain `--hoshigaki` or none at all.
static func forced_days() -> int:
	_read_force()
	return _forced


static func _read_force() -> void:
	if _forced_read:
		return
	_forced_read = true
	for arg in OS.get_cmdline_user_args():
		if arg == "--hoshigaki":
			_forced_on = true
		elif arg.begins_with("--hoshigaki="):
			_forced_on = true
			_forced = maxi(0, int(arg.get_slice("=", 1)))


## Can strings hang on map `m` at all (outdoors: not a room, the mine or the greenhouse)?
static func outdoors(m: MapData) -> bool:
	return m != null and not m.indoor and not m.sheltered and m.ambient == "outdoor"


## Is day `day` of season `season` in the hanging window (the fall's days[0] .. days[1])?
static func in_window(season: String, day: int, cfg := {}) -> bool:
	var c := cfg if not cfg.is_empty() else config()
	return season in (c.seasons as Array) and day >= int(c.days[0]) and day <= int(c.days[1])


## Do they hang out in season `season` on day `day` under weather look `look`?
static func hangs(season: String, day: int, look: String, cfg := {}) -> bool:
	var c := cfg if not cfg.is_empty() else config()
	return in_window(season, day, c) and not look in (c.taken_in as Array)


## The days the strings have hung by day `day` (0 on the window's first day).
static func days_hung(day: int, cfg := {}) -> int:
	var c := cfg if not cfg.is_empty() else config()
	return maxi(0, day - int(c.days[0]))


## How far they have dried after `days` hung, 0 fresh .. 1 fully dried.
static func dried(days: int, cfg := {}) -> float:
	var c := cfg if not cfg.is_empty() else config()
	return clampf(float(days) / maxf(float(c.dry.full_days), 1.0), 0.0, 1.0)


## The picture stage (0 .. stages - 1) after `days` hung: the dried share in even steps.
static func stage(days: int, cfg := {}) -> int:
	var c := cfg if not cfg.is_empty() else config()
	var n: int = (c.stages as Array).size()
	return mini(n - 1, floori(dried(days, c) * float(n)))


## Do they hang on map `m` now (`game` the Game autoload)? Forced on outdoors by `--hoshigaki`.
static func hangs_now(game: Object, m: MapData, cfg := {}) -> bool:
	if game == null or not outdoors(m):
		return false
	if forced_on():
		return true
	return hangs(str(game.season_name()), int(game.day), _look(game), cfg)


## The days hung now: `--hoshigaki=N`'s N, the real days in the window, else force.days.
static func days_now(game: Object, cfg := {}) -> int:
	var c := cfg if not cfg.is_empty() else config()
	if forced_days() != NONE:
		return forced_days()
	if game == null:
		return 0
	if in_window(str(game.season_name()), int(game.day), c):
		return days_hung(int(game.day), c)
	return int(c.force.days)


## How far a string is swung off plumb, in radians, at wind `wind` (0 .. 1) and time `t`
## (seconds), `phase` its own (0 .. 1) so the strings do not swing as one. Zero in dead calm.
static func sway_angle(wind: float, t: float, phase: float, cfg := {}) -> float:
	var c := cfg if not cfg.is_empty() else config()
	var s: Dictionary = c.sway
	var w := clampf(wind, 0.0, 1.0)
	if w <= 0.0:
		return 0.0
	var reach := deg_to_rad(float(s.max_deg)) * w
	var gust := 1.0 - float(s.gust_depth) * (0.5 + 0.5 * sin(TAU * (float(s.gust_hz) * t + phase * 0.5)))
	var rate := float(s.rate_hz) * (1.0 + float(s.rate_gain) * w) * (0.85 + 0.3 * phase)
	return reach * gust * sin(TAU * (rate * t + phase))


## Does the village house with its top-left cell at `cell` hang strings (a hash of the cell
## below village_share)?
static func village_hangs(cell: Vector2i, cfg := {}) -> bool:
	var c := cfg if not cfg.is_empty() else config()
	return _rnd(cell.x, cell.y, 31) < float(c.village_share)


## Where strings hang along an eave from `a` to `b` (world units, y the soffit's height), `out`
## the way out of the eave (level), leaving the x ranges `bare` ([Vector2(x0, x1)]: the doors,
## door_margin more each side) clear: [{at: Vector3 the top, tucked tuck under the soffit,
## fruit: how many persimmons, phase 0..1}], at most eave.most, from a hash of the ends.
static func spots(a: Vector3, b: Vector3, out: Vector3, bare: Array = [], cfg := {}) -> Array[Dictionary]:
	var c := cfg if not cfg.is_empty() else config()
	var e: Dictionary = c.eave
	var res: Array[Dictionary] = []
	var span := Vector2(b.x - a.x, b.z - a.z).length()
	var inset := float(e.inset)
	if span <= inset * 2.0:
		return res
	var along := (b - a) / span
	var key := Vector3i((a * 100.0).round()) + Vector3i((b * 37.0).round())
	var k0 := key.x * 7 + key.z * 131
	var k1 := key.y * 3 + key.z * 17 - key.x
	var d := inset + _rnd(k0, k1, 1) * float(e.gap[0]) * 0.5
	var n := 0
	var margin := float(e.door_margin)
	while d < span - inset and res.size() < int(e.most):
		n += 1
		var p := a + along * d
		var free := true
		for r: Vector2 in bare:
			if p.x >= r.x - margin and p.x <= r.y + margin:
				free = false
		if free and _rnd(k0 + n, k1, 2) >= float(e.skip):
			res.append({"at": p - out * float(e.tuck), "fruit": _fruit(_rnd(k0, k1 + n, 3), c),
				"phase": _rnd(k0 - n, k1, 4)})
		d += lerpf(float(e.gap[0]), float(e.gap[1]), _rnd(k0 + n, k1 + n * 5, 5))
	return res


## The flat view's strings under a painted roof's bottom eave from pixel column `x0` to `x1`
## hanging from row `y`, clear of the columns `bare` ([Vector2i(x, x end)]: the doors) by
## flat.door_margin: [{x: the rope's column, y, fruit, phase}].
static func flat_spots(x0: int, x1: int, y: int, bare: Array = [], cfg := {}) -> Array[Dictionary]:
	var c := cfg if not cfg.is_empty() else config()
	var f: Dictionary = c.flat
	var res: Array[Dictionary] = []
	var half := flat_half_width(c)
	var x := x0 + int(f.inset) + half + floori(_rnd(x0, y, 11) * 3.0)
	var n := 0
	var margin := int(f.door_margin)
	while x + half < x1 - int(f.inset) and res.size() < int(c.eave.most):
		n += 1
		var free := true
		for r: Vector2i in bare:
			if x + half >= r.x - margin and x - half < r.y + margin:
				free = false
		if free and _rnd(x, y, 12) >= float(f.skip):
			res.append({"x": x, "y": y, "fruit": mini(_fruit(_rnd(x, y + n, 13), c), int(f.most_fruit)), "phase": _rnd(x + n, y, 14)})
		x += int(f.gap[0]) + floori(_rnd(x, y, 15) * float(int(f.gap[1]) - int(f.gap[0]) + 1))
	return res


## Half the flat picture's width (columns each side of the rope): the freshest fruit's width.
static func flat_half_width(cfg := {}) -> int:
	var c := cfg if not cfg.is_empty() else config()
	return int((c.stages[0] as Dictionary).small[0])


## The flat view's sideways shift of a string in whole pixels at wind `wind`, time `t`, `phase`.
static func flat_shift(wind: float, t: float, phase: float, cfg := {}) -> int:
	var c := cfg if not cfg.is_empty() else config()
	var most := deg_to_rad(float(c.sway.max_deg))
	return roundi(sway_angle(wind, t, phase, c) / maxf(most, 0.001) * float(c.flat.shift_px))


## The picture key of a string of `fruit` persimmons at stage `st`, `small` for the flat view.
static func art_key(fruit: int, st: int, small: bool) -> String:
	return "%s:%d:%d:%s" % [KEY, fruit, st, "small" if small else "big"]


static func _fruit(r: float, cfg: Dictionary) -> int:
	var lo := int(cfg.fruit[0])
	var hi := int(cfg.fruit[1])
	return mini(hi, lo + floori(r * float(hi - lo + 1)))


static func _look(game: Object) -> String:
	return str(game.weather_look(game.weather_today, game.season_name()))


## 0..1 from three whole numbers, the same every run (Godot's murmur3 hash of them).
static func _rnd(a: int, b: int, c: int) -> float:
	return float(hash(Vector3i(a, b, c)) & 0xffff) / 65536.0
