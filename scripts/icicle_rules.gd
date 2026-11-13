class_name IcicleRules
extends RefCounted
## Icicles (tsurara) hanging from the roofs' low eaves in winter (data/icicles.json). The logic
## both views share: when there are any (winter, outdoors, with snow lying on the roofs; never
## indoors, in the mine or under the greenhouse's glass, which has no eaves of its own), how long
## they are now (grown over the winter's cold days and nights, melted back round a sunny midday
## and frozen again by night), when they drip, and where they hang along an eave: spots from a
## hash of the eave's ends, so no two eaves look alike and every visit looks the same. The 3D view
## (IcicleLayer) hangs them from the real eave lines the roof builders list (Minka: FarmWorld.eaves),
## the flat view (IcicleView) under the painted roofs' bottom eave. Pure: nothing here draws.
## `--icicles` (or `--icicles=long`) forces them on outdoors for a frame.

const DATA_PATH := "res://data/icicles.json"
const NONE := -1.0   # forced(): not forced

static var _cfg: Dictionary = {}
static var _forced_read := false
static var _forced := NONE


## data/icicles.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## The forced amount from `--icicles` (force.plain) or `--icicles=long` (force.long), NONE when
## not asked for.
static func forced() -> float:
	if not _forced_read:
		_forced_read = true
		var force: Dictionary = config().force
		for arg in OS.get_cmdline_user_args():
			if arg == "--icicles":
				_forced = float(force.plain)
			elif arg == "--icicles=long":
				_forced = float(force.long)
	return _forced


## Can icicles hang on map `m` at all (outdoors: not a room, the mine or the greenhouse)?
static func outdoors(m: MapData) -> bool:
	return m != null and not m.indoor and not m.sheltered and m.ambient == "outdoor"


## How far they have grown over the winter, 0..1: grow.curve by the day of the season (1..30),
## straight between its points, and a little more with more snow lying (`cover` 0..1).
static func grown(day: int, cover: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var curve: Array = cfg.grow.curve
	var v := float(curve[0][1])
	if day >= int(curve[curve.size() - 1][0]):
		v = float(curve[curve.size() - 1][1])
	else:
		for i in curve.size() - 1:
			var a: Array = curve[i]
			var b: Array = curve[i + 1]
			if day >= int(a[0]) and day <= int(b[0]):
				v = lerpf(float(a[1]), float(b[1]), float(day - int(a[0])) / maxf(float(int(b[0]) - int(a[0])), 1.0))
				break
	return clampf(v + float(cfg.grow.cover_bonus) * clampf(cover, 0.0, 1.0), 0.0, 1.0)


## The share melted off at `hour` (0..24) under weather look `look`: melt.looks[look] at most,
## ramping up from hours[0] to hours[1], held to hours[2], frozen back by hours[3]; 0 at night,
## in the morning and on a grey day (snow, blizzard, rain).
static func melt(look: String, hour: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var most := float(cfg.melt.looks.get(look, 0.0))
	if most <= 0.0:
		return 0.0
	var h: Array = cfg.melt.hours
	var t := 0.0
	if hour <= float(h[0]) or hour >= float(h[3]):
		t = 0.0
	elif hour < float(h[1]):
		t = (hour - float(h[0])) / (float(h[1]) - float(h[0]))
	elif hour <= float(h[2]):
		t = 1.0
	else:
		t = 1.0 - (hour - float(h[2])) / (float(h[3]) - float(h[2]))
	t = t * t * (3.0 - 2.0 * t)
	return most * t


## The icicles' length now, 0..1 of the longest, in season `season` on day `day` at `hour` under
## weather look `look` with `cover` (0..100) of snow lying. 0 out of season or with too little
## snow on the roofs (min_cover).
static func amount(season: String, day: int, hour: float, look: String, cover: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	if not season in (cfg.seasons as Array) or cover < float(cfg.min_cover):
		return 0.0
	return grown(day, cover / 100.0, cfg) * (1.0 - melt(look, hour, cfg))


## The amount on map `m` now (`game` is the Game autoload): 0 indoors, in the mine and the
## greenhouse; the forced amount outdoors when `--icicles` asks.
static func amount_now(game: Object, m: MapData, cfg := {}) -> float:
	if game == null or not outdoors(m):
		return 0.0
	if forced() != NONE:
		return forced()
	return amount(game.season_name(), int(game.day), _hour(game), _look(game), float(game.snow_cover), cfg)


## Do they drip now: while melting (a look of drip.looks, within drip.hours) and there are any.
static func dripping(look: String, hour: float, amount_now_: float, cfg := {}) -> bool:
	if cfg.is_empty():
		cfg = config()
	var h: Array = cfg.drip.hours
	return amount_now_ > 0.0 and look in (cfg.drip.looks as Array) and hour >= float(h[0]) and hour < float(h[1])


static func dripping_now(game: Object, m: MapData, cfg := {}) -> bool:
	if game == null or not outdoors(m):
		return false
	return dripping(_look(game), _hour(game), amount_now(game, m, cfg), cfg)


## `a` in whole steps of `step` (the views redo their icicles only when the step moves).
static func step_of(a: float, cfg := {}) -> int:
	if cfg.is_empty():
		cfg = config()
	return roundi(a / float(cfg.step))


## Where icicles hang along an eave from `a` to `b` (world units; its soffit's outer edge, y the
## eave's height), `out` the way out of the eave (level): [{at: Vector3 the top, len: 0..1 of
## eave.max, width, seed 0..1, drip: does it drip}], from a hash of the ends. They start `inset`
## in from each end, tucked `tuck` in under the soffit.
static func spots(a: Vector3, b: Vector3, out: Vector3, cfg := {}) -> Array[Dictionary]:
	if cfg.is_empty():
		cfg = config()
	var e: Dictionary = cfg.eave
	var res: Array[Dictionary] = []
	var span := Vector2(b.x - a.x, b.z - a.z).length()
	var inset := float(e.inset)
	if span <= inset * 2.0:
		return res
	var along := (b - a) / span
	var key := Vector3i((a * 100.0).round()) + Vector3i((b * 37.0).round())
	var k0 := key.x * 7 + key.z * 131
	var k1 := key.y * 3 + key.z * 17 - key.x
	var d := inset + _rnd(k0, k1, 1) * float(e.gap[1]) * 0.5
	var n := 0
	while d < span - inset:
		n += 1
		var r := _rnd(k0 + n, k1, 2)
		if r >= float(e.skip):
			var long := _rnd(k0, k1 + n, 3) < float(e.long)
			var l := 1.0 if long else lerpf(float(e.length[0]), 1.0, pow(_rnd(k0 + n, k1 + n, 4), 1.5))
			res.append({"at": a + along * d - out * float(e.tuck), "len": l,
				"width": lerpf(float(e.width[0]), float(e.width[1]), _rnd(k0 - n, k1, 5)),
				"seed": _rnd(k0, k1 - n, 6), "drip": _rnd(k0 + n * 3, k1, 7) < float(cfg.drip.share)})
		d += lerpf(float(e.gap[0]), float(e.gap[1]), _rnd(k0 + n, k1 + n * 5, 8))
	return res


## How long icicle `spot` (spots) is at `amount_now_`, in world units; 0 below eave.min.
static func length_of(spot: Dictionary, amount_now_: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var l := float(cfg.eave.max) * float(spot.len) * amount_now_
	return l if l >= float(cfg.eave.min) else 0.0


## The flat view's icicles under a painted roof's bottom eave from pixel column `x0` to `x1`
## (the roof picture's own columns) hanging from row `y`, leaving the columns of `bare` ([x, x
## end) ranges: the doors) clear: [{x, y, len: 0..1, wide: 2 px wide down half its length (else
## only its top row), seed, drip}]; x and x + 1 are inside the eave.
static func flat_spots(x0: int, x1: int, y: int, bare: Array = [], cfg := {}) -> Array[Dictionary]:
	if cfg.is_empty():
		cfg = config()
	var f: Dictionary = cfg.flat
	var res: Array[Dictionary] = []
	var x := x0 + int(f.inset) + floori(_rnd(x0, y, 11) * float(f.gap[1]))
	var n := 0
	while x < x1 - int(f.inset) - 1:
		n += 1
		var free := true
		for r: Vector2i in bare:
			if x >= r.x - 1 and x < r.y + 1:
				free = false
		if free and _rnd(x, y, 12) >= float(f.skip):
			var long := _rnd(x, y + n, 13) < float(f.long)
			var l := 1.0 if long else lerpf(float(f.length[0]), 1.0, pow(_rnd(x + n, y, 14), 1.5))
			res.append({"x": x, "y": y, "len": l, "wide": l >= float(f.wide_from), "seed": _rnd(x, y, 15),
				"drip": _rnd(x, y, 16) < float(cfg.drip.share)})
			x += 1   # its top row is two pixels wide
		x += int(f.gap[0]) + floori(_rnd(x, y, 17) * float(int(f.gap[1]) - int(f.gap[0]) + 1))
	return res


## How many pixels flat icicle `spot` hangs at `amount_now_`: at least 1 while it shows, 0 when
## too short to see.
static func flat_len(spot: Dictionary, amount_now_: float, cfg := {}) -> int:
	if cfg.is_empty():
		cfg = config()
	return floori(float(cfg.flat.max) * float(spot.len) * amount_now_ + 0.25)


## The drip's fall period of a spot with `seed` (drip.period, seconds).
static func drip_period(seed: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	return lerpf(float(cfg.drip.period[0]), float(cfg.drip.period[1]), seed)


static func _hour(game: Object) -> float:
	return float(game.hour) + float(game.minute) / 60.0


static func _look(game: Object) -> String:
	return str(game.weather_look(game.weather_today, game.season_name()))


## 0..1 from three whole numbers, the same every run (Godot's murmur3 hash of them).
static func _rnd(a: int, b: int, c: int) -> float:
	return float(hash(Vector3i(a, b, c)) & 0xffff) / 65536.0
