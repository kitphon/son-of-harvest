class_name PuddleRules
extends RefCounted
## Puddles on the bare outdoor ground in rain (data/puddles.json): the logic both views share.
## How wet the ground is now (grows over the first game hour of rain, dries over a couple of
## hours after a rainy day), where the puddles are (a hash of the cell, on paths and bare ground
## only), how big each one is at a wetness, and where its rain rings are at a time `t`. The 3D
## view (PuddleLayer) draws them as flat quads in world units, the flat view (PuddleView) as
## pixels. Pure: nothing here draws.

const DATA_PATH := "res://data/puddles.json"

static var _cfg: Dictionary = {}


## data/puddles.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## Game hours since the day began (06:00; the small hours belong to the day before): 0..24.
static func since_start(hour: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	return fposmod(hour - float(cfg.day_start), 24.0)


## How wet the open ground is, 0..1: from today's weather `look`, yesterday's `prev_look` ("" =
## none), the clock `hour` (a float, 0..24) and the snow lying (0..100). Rain fills it to the
## look's max over grow_hours; what yesterday's rain left dries out over dry_hours; snow lying
## keeps it all away.
static func wetness(look: String, prev_look: String, hour: float, snow_cover: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	if snow_cover > 0.0:
		return 0.0
	var since := since_start(hour, cfg)
	var carry := float(cfg.looks.get(prev_look, {}).get("max", 0.0)) \
		* clampf(1.0 - since / maxf(float(cfg.dry_hours), 0.001), 0.0, 1.0)
	var top := float(cfg.looks.get(look, {}).get("max", 0.0))
	if top <= 0.0:
		return carry
	return maxf(top * clampf(since / maxf(float(cfg.grow_hours), 0.001), 0.0, 1.0), carry)


## Does the look make rain fall on the puddles now (so they show rings)? `wet` is the wetness.
static func raining(look: String, wet: float, cfg := {}) -> bool:
	if cfg.is_empty():
		cfg = config()
	return wet > 0.0 and cfg.looks.has(look)


## The wetness now on map `m` (MapData) by the game (`game` is the Game autoload): 0 indoors, in
## the mine or without a clock.
static func wetness_now(game: Object, m: MapData, cfg := {}) -> float:
	if game == null or m == null or m.indoor or m.sheltered:
		return 0.0
	var season: String = game.season_name()
	var hour := float(game.hour) + float(game.minute) / 60.0
	var yesterday := str(game.weather_yesterday)
	return wetness(game.weather_look(game.weather_today, season),
		game.weather_look(yesterday, season) if yesterday != "" else "",
		hour, float(game.snow_cover), cfg)


## Is today's weather one that rains on the puddles now (for the rings)?
static func raining_now(game: Object, m: MapData, cfg := {}) -> bool:
	if cfg.is_empty():
		cfg = config()
	var look: String = game.weather_look(game.weather_today, game.season_name())
	return raining(look, wetness_now(game, m, cfg), cfg)


## Can a puddle lie on map cell `c`? The map's path / gravel ground, not solid and with no prop on
## it (not on grass, water, paddies, buildings or floors); on the farm (`farm`, a FarmGrid) the
## doorsteps only. Never indoors or in the mine.
static func eligible(m: MapData, c: Vector2i, farm: FarmGrid = null, cfg := {}) -> bool:
	if cfg.is_empty():
		cfg = config()
	if m.indoor or m.sheltered:
		return false
	if farm != null:
		return str(farm.fixed_at(c)) in cfg.farm_fixed
	return m.in_bounds(c) and m.tile(c) in cfg.tiles and not m.is_solid(c) and m.prop_at(c).is_empty()


## The puddles of a map: [{cell: Vector2i, on, rx, ry, ox, oy, seed}], in cell order. `on` is the
## wetness it starts to gather at, rx / ry its full half sizes (cells), ox / oy its centre's
## offset from the cell's middle (always inside the cell), seed 0..1 for the look.
static func puddles(m: MapData, farm: FarmGrid = null, cfg := {}) -> Array[Dictionary]:
	if cfg.is_empty():
		cfg = config()
	var out: Array[Dictionary] = []
	if m.indoor or m.sheltered:
		return out
	var w: int = FarmGrid.W if farm != null else m.w
	var h: int = FarmGrid.H if farm != null else m.h
	var dens := float(cfg.farm_density if farm != null else cfg.density)
	var key := hash(m.id) & 0xffff
	var on: Array = cfg.on
	var rx: Array = cfg.radius.x
	var ry: Array = cfg.radius.y
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			if DriftRules.rnd(x, y, key + 11) >= dens or not eligible(m, c, farm, cfg):
				continue
			var px := lerpf(float(rx[0]), float(rx[1]), DriftRules.rnd(x, y, key + 23))
			var py := lerpf(float(ry[0]), float(ry[1]), DriftRules.rnd(x, y, key + 31))
			out.append({
				"cell": c,
				"on": lerpf(float(on[0]), float(on[1]), DriftRules.rnd(x, y, key + 41)),
				"rx": px, "ry": py,
				"ox": (DriftRules.rnd(x, y, key + 53) - 0.5) * 2.0 * (0.5 - px) * 0.8,
				"oy": (DriftRules.rnd(x, y, key + 67) - 0.5) * 2.0 * (0.5 - py) * 0.8,
				"seed": DriftRules.rnd(x, y, key + 79)})
	return out


## How much of its full size puddle `p` has at wetness `wet`: 0 (not gathered, or under min_scale)
## .. 1, easing in from its `on` wetness.
static func scale_of(p: Dictionary, wet: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var s := clampf((wet - float(p.on)) / maxf(1.0 - float(p.on), 0.001), 0.0, 1.0)
	s = s * s * (3.0 - 2.0 * s)
	return s if s >= float(cfg.min_scale) else 0.0


## The wetness in steps of 1/50, so the views redo their puddles only when it moves a step.
static func step_of(wet: float) -> int:
	return roundi(clampf(wet, 0.0, 1.0) * 50.0)


## The rain rings in puddle `p` at time `t` seconds, for the flat view (the 3D shader does its own):
## [{pos: Vector2 offset from the puddle's centre in half widths (-1..1 each way), ring: 0..1}];
## `style` is the water's dimples ({density, life} of data/weather_fx.json).
static func dimples(p: Dictionary, t: float, style: Dictionary, cfg := {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if style.is_empty():
		return out
	if cfg.is_empty():
		cfg = config()
	var life := maxf(float(style.get("life", 0.9)), 0.05)
	var dens := float(style.get("density", 0.0)) * float(cfg.dimple.scale)
	var sd := int(float(p.seed) * 1000.0)
	for i in 2:
		var u := t / life + DriftRules.rnd(sd, i, 5) * 7.0
		var slot := floori(u)
		if DriftRules.rnd(sd, slot, 17 + i) < dens:
			var ang := DriftRules.rnd(sd, slot, 29 + i) * TAU
			var rad := DriftRules.rnd(sd, slot, 41 + i) * 0.5
			out.append({"pos": Vector2(cos(ang), sin(ang)) * rad, "ring": u - float(slot)})
	return out
