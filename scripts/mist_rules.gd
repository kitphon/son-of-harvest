class_name MistRules
extends RefCounted
## Morning mist (asagiri) lying low over the water and the rice paddies at dawn (data/mist.json).
## The logic both views share: how thick it is now (season, weather look, clock, wind, indoors
## or not) over each kind of ground, which cells make it on a map, and where each soft sheet is
## at a time `t` (cells x, height, z), drifting slowly on the wind of data/wind.json. The 3D view
## (MistLayer) lays them as low flat sheets, the flat view (MistView) draws them from above as
## stepped ellipses. Pure: nothing here draws.
## Over a hot spring (Kajika-yu's water, look `onsen`; 2026-11-24, the user's photo of a forest
## onsen) the steam lies on the water all day and night (kind `onsen`, data/mist.json `onsen`): its
## own share by season and weather, a gentle swell by the clock, smaller, lower, slower sheets that
## keep to the pool, counted apart from the river's so its mist never thins them. And the steam
## rising off it in thin wisps (`onsen` `wisps`, 2026-11-28: wisp_spots, wisps; SteamWisps in 3D).

const DATA_PATH := "res://data/mist.json"
const KINDS: Array[String] = ["water", "paddy"]

static var _cfg: Dictionary = {}


## data/mist.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## The clock's share of the mist, 0..1, at `hour` (a float, 0..24): the data's curve keys,
## eased between them, 0 outside them.
static func curve(hour: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var keys: Array = cfg.curve
	if keys.is_empty() or hour <= float(keys[0][0]) or hour >= float(keys[-1][0]):
		return 0.0
	for i in range(1, keys.size()):
		var b: Array = keys[i]
		if hour <= float(b[0]):
			var a: Array = keys[i - 1]
			var s := clampf((hour - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001), 0.0, 1.0)
			return lerpf(float(a[1]), float(b[1]), s * s * (3.0 - 2.0 * s))
	return 0.0


## How thick the mist over ground `kind` (water, paddy) is: 0..1, from the season, the weather
## look, the clock `hour` and the wind (0..1).
static func amount(kind: String, season_id: String, look: String, hour: float, wind := 0.0, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var s := float((cfg.seasons.get(season_id, {}) as Dictionary).get(kind, 0.0))
	var w := float((cfg.looks as Dictionary).get(look, 0.0))
	if s <= 0.0 or w <= 0.0:
		return 0.0
	var thin := clampf(1.0 - float(cfg.wind_thin) * clampf(wind, 0.0, 1.0), 0.0, 1.0)
	return clampf(s * w * thin * curve(hour, cfg), 0.0, 1.0)


## The mist now on map `m` (MapData): {kind: amount} for the kinds above 0. None indoors, under a
## roof or in the mine, or without a clock (`game` is the Game autoload). `wind` < 0 reads
## today's wind from `game`.
static func amounts_now(game: Object, m: MapData, wind := -1.0, cfg := {}) -> Dictionary:
	var out := {}
	if game == null or m == null or m.indoor or m.sheltered:
		return out
	if cfg.is_empty():
		cfg = config()
	var look: String = game.weather_look(game.weather_today, game.season_name())
	var hour := float(game.hour) + float(game.minute) / 60.0
	var w := wind if wind >= 0.0 else float(game.wind_strength())
	for kind in KINDS:
		var a := amount(kind, game.season_name(), look, hour, w, cfg)
		if a > 0.0:
			out[kind] = a
	var hot := onsen_amount(game.season_name(), look, hour, w, cfg) if m.looks.has("onsen") else 0.0   # only where a hot spring is
	if hot > 0.0:
		out["onsen"] = hot
	return out


## How thick the steam over a hot spring is (0..1): data/mist.json `onsen` by season and weather
## look, its own `curve` over the whole day (thicker in the cold of the night and the morning), the
## wind thinning it a little less than the river's mist (`wind_thin`).
static func onsen_amount(season_id: String, look: String, hour: float, wind := 0.0, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var o: Dictionary = cfg.get("onsen", {})
	var s := float((o.get("seasons", {}) as Dictionary).get(season_id, 0.0))
	var w := float((o.get("looks", {}) as Dictionary).get(look, 0.0))
	if s <= 0.0 or w <= 0.0:
		return 0.0
	var thin := clampf(1.0 - float(o.get("wind_thin", 0.0)) * clampf(wind, 0.0, 1.0), 0.0, 1.0)
	return clampf(s * w * thin * curve(fposmod(hour, 24.0), o), 0.0, 1.0)


## The farm's planted rice plots (any growth): their cells, row by row. Rice stands in water, so
## each is a paddy to the mist, like the village paddies.
static func rice_cells(farm: FarmGrid) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if farm == null:
		return out
	for y in farm.h:
		for x in farm.w:
			var d: Dictionary = farm.cells[y * farm.w + x]
			var id := str(d.get("crop", ""))
			if id != "" and bool((farm.crops.get(id, {}) as Dictionary).get("holds_water", false)):
				out.append(Vector2i(x, y))
	return out


## The cells a map's mist rises from: {area: Rect2 in cells, cells: Array[Vector2] (cell
## centres), kinds: Array[String] (each cell's kind)}. `farm` (FarmGrid) gives the farm's pond.
static func scene_of(m: MapData, farm: FarmGrid = null, cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var s := {"area": Rect2(0, 0, m.w, m.h), "cells": [] as Array[Vector2], "kinds": [] as Array[String]}
	var from: Array = cfg.sources
	for y in m.h:
		for x in m.w:
			var c := Vector2i(x, y)
			var kind := ""
			if farm != null:
				kind = "water" if str(farm.fixed.get(c, "")) == "pond" else ""
			else:
				kind = m.tile(c)
				if kind == "water" and m.look(c) == "onsen":
					kind = "onsen"   # a hot spring's water steams on its own (onsen_amount)
			if kind in from:
				s.cells.append(Vector2(x, y) + Vector2(0.5, 0.5))
				s.kinds.append(kind)
	for c in rice_cells(farm):
		s.cells.append(Vector2(c) + Vector2(0.5, 0.5))
		s.kinds.append("paddy")
	return s


## How many sheets a scene of `cells` source cells has: per_cell of them, at least 1, at most max
## (0 with no cells).
static func count_for(cells: int, cfg := {}) -> int:
	if cells <= 0:
		return 0
	if cfg.is_empty():
		cfg = config()
	return clampi(int(round(float(cells) * float(cfg.per_cell))), 1, int(cfg.max))


## The drift direction (unit, x / z) of the wind.
static func wind_dir(cfg := {}) -> Vector2:
	if cfg.is_empty():
		cfg = config()
	return Vector2(float(cfg.wind_dir[0]), float(cfg.wind_dir[1])).normalized()


## The mist's colour now: its own, taken toward the hue of the sky by sky_share (the sky made
## bright, so the hue tints it without darkening it; the tint over the picture darkens it).
static func color_now(game: Object, cfg := {}, kind := "") -> Color:
	if cfg.is_empty():
		cfg = config()
	if kind == "onsen":   # a hot spring's steam: its own colour and share of the sky's hue (white, not the sunset's pink)
		cfg = cfg.merged(cfg.get("onsen", {}), true)
	var base := Color(str(cfg.color))
	if game == null:
		return base
	var sky: Color = game.sky_color()
	var top := maxf(maxf(sky.r, sky.g), maxf(sky.b, 0.001))
	var hue := Color(sky.r / top, sky.g / top, sky.b / top)
	return base.lerp(base * hue, clampf(float(cfg.sky_share), 0.0, 1.0))


## Every sheet at time `t` (seconds) for a scene from scene_of, `amounts` from amounts_now and a
## wind of 0..1, in season `season_id` (the paddies' sheets lie over the rice's tips, data
## paddy_height): [{pos: Vector3 (x, height, z) in cells, size: Vector2 (along the wind, across),
## angle (radians, the wind's direction on the ground, x toward z), alpha, kind}]. Sheets over a
## kind with no mist now are left out. A pure function of its arguments: the views only move `t` on.
static func sheets(scene: Dictionary, amounts: Dictionary, t: float, wind: float, season_id := "", cfg := {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cells: Array = scene.get("cells", [])
	if amounts.is_empty() or cells.is_empty():
		return out
	if cfg.is_empty():
		cfg = config()
	var kinds: Array = scene.kinds
	# The hot spring's sheets are their own set (data onsen), the rest the morning mist's.
	var plain: Array[int] = []
	var hot: Array[int] = []
	for k in cells.size():
		(hot if kinds[k] == "onsen" else plain).append(k)
	out.append_array(_sheets_of(scene, plain, count_for(plain.size(), cfg), 0, amounts, t, wind, season_id, cfg))
	var o: Dictionary = cfg.get("onsen", {})
	if not hot.is_empty() and float(amounts.get("onsen", 0.0)) > 0.0:
		var oc := cfg.merged(o, true)   # its own size, height, drift and life over the mist's
		var n := clampi(int(round(float(hot.size()) * float(o.get("per_cell", 1.0)))), 1, int(o.get("max", 16)))
		out.append_array(_sheets_of(scene, hot, n, 500, amounts, t, wind, season_id, oc))
	return out


## The sheets of one set: `n` sheets homed on the source cells `pick` (indexes into the scene's
## cells), numbered from `first` (their own random draws), with the settings of `cfg`.
static func _sheets_of(scene: Dictionary, pick: Array[int], n: int, first: int, amounts: Dictionary, t: float, wind: float, season_id: String, cfg: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if pick.is_empty():
		return out
	var cells: Array = scene.cells
	var kinds: Array = scene.kinds
	var dir := wind_dir(cfg)
	var side := Vector2(-dir.y, dir.x)
	var angle := dir.angle()
	var speed := float(cfg.drift) + float(cfg.drift_wind) * clampf(wind, 0.0, 1.0)
	var sz: Array = cfg.size
	var hs: Array = cfg.height
	var ph: Array = (cfg.get("paddy_height", {}) as Dictionary).get(season_id, cfg.height)
	for j0 in n:
		var i := first + j0
		var life := float(cfg.life) * (1.0 + (DriftRules.rnd(i, 0, 61) - 0.5) * 2.0 * float(cfg.life_var))
		var tt := t + DriftRules.rnd(i, 0, 62) * life
		var cycle := floori(tt / life)
		var u := tt / life - float(cycle)
		var at: int = pick[int(DriftRules.rnd(i, cycle, 63) * pick.size()) % pick.size()]
		var kind: String = kinds[at]
		var a := float(amounts.get(kind, 0.0))
		if a <= 0.0:
			continue
		var j := float(cfg.jitter)
		var home: Vector2 = cells[at] + Vector2(DriftRules.rnd(i, cycle, 64) - 0.5, DriftRules.rnd(i, cycle, 65) - 0.5) * 2.0 * j
		var phase := DriftRules.rnd(i, cycle, 66) * TAU
		var p := home + dir * speed * life * (u - 0.5) + side * sin(u * TAU + phase) * float(cfg.wobble) * 0.5
		var along := lerpf(float(sz[0]), float(sz[1]), DriftRules.rnd(i, cycle, 67)) * (1.0 + float(cfg.swell) * (u - 0.5))
		var hr: Array = ph if kind == "paddy" else hs
		var h := lerpf(float(hr[0]), float(hr[1]), DriftRules.rnd(i, cycle, 68)) + sin(t * 0.4 + phase) * float(cfg.bob)
		# In and out softly over its life (a sine's bell, eased at both ends), and out past the
		# map's edge (the flat view shows black there).
		var fade := sin(u * PI)
		var area: Rect2 = scene.get("area", Rect2(p - Vector2.ONE * 9.0, Vector2.ONE * 18.0))
		var inside := minf(minf(p.x - area.position.x, area.end.x - p.x), minf(p.y - area.position.y, area.end.y - p.y))
		fade *= clampf((inside + 0.25) / 1.25, 0.0, 1.0)
		out.append({
			"pos": Vector3(p.x, maxf(h, 0.02), p.y),
			"size": Vector2(along, along * float(cfg.across)),
			"angle": angle,
			"alpha": clampf(float(cfg.alpha) * a * fade * fade, 0.0, 1.0),
			"kind": kind,
		})
	return out


## Where steam wisps rise from on hot spring `pond`: points `spot_step` cells apart over its deep
## bed (PondShape.DEEP), clear of its rocks by `rock_share` of their clear reach (PondShape.rocks).
static func wisp_spots(pond: PondShape, cfg := {}) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if pond == null:
		return out
	if cfg.is_empty():
		cfg = config()
	var w: Dictionary = (cfg.get("onsen", {}) as Dictionary).get("wisps", {})
	var step := maxf(float(w.get("spot_step", 0.5)), 0.1)
	var share := float(w.get("rock_share", 0.75))
	var n := Vector2i((Vector2(pond.bounds.size) / step).ceil())
	for j in n.y:
		for i in n.x:
			var p := Vector2(pond.bounds.position) + (Vector2(i, j) + Vector2(0.5, 0.5)) * step
			if pond.field(p) < PondShape.DEEP:
				continue
			var clear := true
			for rk in pond.rocks:
				if (rk[0] as Vector2).distance_to(p) < float(rk[1]) * share:
					clear = false
					break
			if clear:
				out.append(p)
	return out


## The steam wisps showing at time `t` (seconds) at steam `amount` (0..1, onsen_amount) and `wind`
## (0..1), rising from `spots` (wisp_spots): [{pos: Vector3 (cells x, units over the water, cells
## z), size: Vector2 (units wide, tall), alpha, rise: 0..1 of its life}]. Each slot lives its own
## life over and over, each time from another spot (a hash of the slot and the round).
static func wisps(spots: Array[Vector2], amount: float, t: float, wind := 0.0, cfg := {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if spots.is_empty() or amount <= 0.0:
		return out
	if cfg.is_empty():
		cfg = config()
	var w: Dictionary = (cfg.get("onsen", {}) as Dictionary).get("wisps", {})
	var n := roundi(float(w.get("count", 0)) * clampf(amount, 0.0, 1.0))
	var life: Array = w.get("life", [4.0, 6.0])
	var rise: Array = w.get("rise", [1.0, 1.5])
	var width: Array = w.get("width", [0.3, 0.5])
	var along := wind_dir(cfg) * clampf(wind, 0.0, 1.0) * float(w.get("drift_wind", 0.0))
	for i in n:
		var span := lerpf(float(life[0]), float(life[1]), _h(i, 0, 1))
		var u := t / span + _h(i, 0, 2)
		var round_no := floori(u)
		var f := u - round_no
		var spot: Vector2 = spots[posmod(i * 7919 + round_no * 104729, spots.size())]
		var drift := along * f * span + Vector2(sin(t * 0.9 + i * 1.7), 0.0) * float(w.get("sway", 0.0)) * f
		var wide := lerpf(float(width[0]), float(width[1]), _h(i, round_no, 3)) * (1.0 + float(w.get("grow", 0.0)) * f)
		var fade := smoothstep(0.0, maxf(float(w.get("fade_in", 0.2)), 0.01), f) * (1.0 - smoothstep(float(w.get("fade_out", 0.5)), 1.0, f))
		out.append({
			"pos": Vector3(spot.x + drift.x, lerpf(float(rise[0]), float(rise[1]), _h(i, round_no, 4)) * f, spot.y + drift.y),
			"size": Vector2(wide, wide * float(w.get("tall", 1.8))),
			"alpha": float(w.get("alpha", 0.4)) * fade * clampf(amount * 1.2, 0.0, 1.0),
			"rise": f,
		})
	return out


## A hash of a wisp's slot `i`, round `r` and use `k`, 0..1.
static func _h(i: int, r: int, k: int) -> float:
	return float(posmod(i * 7919 + r * 104729 + k * 31337 + (i * k * 613) % 997, 1000)) / 1000.0
