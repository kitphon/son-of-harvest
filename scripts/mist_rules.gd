class_name MistRules
extends RefCounted
## Morning mist (asagiri) lying low over the water and the rice paddies at dawn (data/mist.json).
## The logic both views share: how thick it is now (season, weather look, clock, wind, indoors
## or not) over each kind of ground, which cells make it on a map, and where each soft sheet is
## at a time `t` (cells x, height, z), drifting slowly on the wind of data/wind.json. The 3D view
## (MistLayer) lays them as low flat sheets, the flat view (MistView) draws them from above as
## stepped ellipses. Pure: nothing here draws.

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
			if kind in from:
				s.cells.append(Vector2(x, y) + Vector2(0.5, 0.5))
				s.kinds.append(kind)
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
static func color_now(game: Object, cfg := {}) -> Color:
	if cfg.is_empty():
		cfg = config()
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
	var n := count_for(cells.size(), cfg)
	var dir := wind_dir(cfg)
	var side := Vector2(-dir.y, dir.x)
	var angle := dir.angle()
	var speed := float(cfg.drift) + float(cfg.drift_wind) * clampf(wind, 0.0, 1.0)
	var sz: Array = cfg.size
	var hs: Array = cfg.height
	var ph: Array = (cfg.get("paddy_height", {}) as Dictionary).get(season_id, cfg.height)
	for i in n:
		var life := float(cfg.life) * (1.0 + (DriftRules.rnd(i, 0, 61) - 0.5) * 2.0 * float(cfg.life_var))
		var tt := t + DriftRules.rnd(i, 0, 62) * life
		var cycle := floori(tt / life)
		var u := tt / life - float(cycle)
		var at := int(DriftRules.rnd(i, cycle, 63) * cells.size()) % cells.size()
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
