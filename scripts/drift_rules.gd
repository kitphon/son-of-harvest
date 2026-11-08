class_name DriftRules
extends RefCounted
## Seasonal life drifting through the open air outdoors (data/drift.json): cherry petals in
## spring, maple and persimmon leaves in fall, fireflies on summer nights. This is the logic both
## views share: which kinds show now (season, weather look, clock, indoors or not), how many, and
## where each mote is at a time `t` (cells x, height, z), carried by the same wind as the rice and
## the hearth smoke (Game.wind_strength). The 3D view (DriftLayer, DriftGlow) draws them in world
## units, the flat view (DriftView) from above in pixels. Pure: nothing here draws.

const DATA_PATH := "res://data/drift.json"
const KINDS: Array[String] = ["petal", "leaf", "firefly"]

static var _cfg: Dictionary = {}


## data/drift.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## A steady pseudo-random number in 0..1 from three integers (same everywhere, every run).
static func rnd(a: int, b: int, c: int) -> float:
	var x := (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)
	x = (x ^ (x >> 15)) * 2246822519 & 0xffffffff
	x = (x ^ (x >> 13)) * 3266489917 & 0xffffffff
	x = x ^ (x >> 16)
	return float(x & 0xffff) / 65536.0


## How much of kind `kind` shows: 0..1, from the season, the weather look and the clock `hour`
## (a float, 0..24; a window past midnight wraps), easing in and out at the window's ends.
static func amount(kind: String, season_id: String, look: String, hour: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var k: Dictionary = cfg[kind]
	if not season_id in k.seasons:
		return 0.0
	var share := float((k.looks as Dictionary).get(look, 0.0))
	if share <= 0.0:
		return 0.0
	var a := float(k.hours[0])
	var b := float(k.hours[1])
	var fade := maxf(float(k.fade_hours), 0.001)
	var into := hour - a
	var span := b - a
	if span < 0.0:   # past midnight
		span += 24.0
		if into < 0.0:
			into += 24.0
	if into < 0.0 or into > span:
		return 0.0
	var s := clampf(minf(into / fade, (span - into) / fade), 0.0, 1.0)
	return s * s * (3.0 - 2.0 * s) * share


## What shows now on the map `m` (MapData): {kind: amount} for the kinds above 0. None indoors
## or in the mine, or without a clock (`game` is the Game autoload).
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
		if a > 0.0:
			out[kind] = a
	return out


## How many motes of `kind` show at `amount` (0..1): the data's count scaled, at least one.
static func count_for(kind: String, amount_now: float, cfg := {}) -> int:
	if amount_now <= 0.0:
		return 0
	if cfg.is_empty():
		cfg = config()
	return maxi(int(round(float(cfg[kind].count) * clampf(amount_now, 0.0, 1.0))), 1)


## The places a map's motes use: {area: Rect2 in cells, trees: {kind: Array[Vector2] of cell
## centres}, wet: water cell centres, dry: open grass cell centres}. `farm` (FarmGrid) gives the
## farm's pond and fixed buildings; `festival_props` are today's festival decorations here
## (their cherry trees add to the petals' trees). Props of a map: kinds by data/drift.json "trees".
static func scene_of(m: MapData, farm: FarmGrid = null, festival_props: Array = [], cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var s := {"area": Rect2(0, 0, m.w, m.h), "trees": {}, "wet": [] as Array[Vector2], "dry": [] as Array[Vector2]}
	var by_kind := {}
	for kind in ["petal", "leaf"]:
		s.trees[kind] = [] as Array[Vector2]
		for t in cfg[kind].trees:
			by_kind[t] = kind
	for p in m.props + festival_props:
		var kind: String = by_kind.get(str(p.get("kind", "")), "")
		if kind != "":
			var c := Vector2(int(p.cell[0]), int(p.cell[1])) if p.cell is Array else Vector2(p.cell)
			s.trees[kind].append(c + Vector2(0.5, 0.5))
	for y in m.h:
		for x in m.w:
			var c := Vector2i(x, y)
			var water := false
			var open := false
			if farm != null:
				var f := str(farm.fixed.get(c, ""))
				water = f == "pond"
				open = f == "" and (x + y * 3) % 5 == 0 and x > 0 and y > 0 and x < m.w - 1 and y < m.h - 1
			else:
				water = m.tile(c) == "water"
				open = m.tile(c) == "grass" and not m.is_solid(c) and (x * 7 + y * 13) % 5 == 0
			if water:
				s.wet.append(Vector2(x, y) + Vector2(0.5, 0.5))
			elif open:
				s.dry.append(Vector2(x, y) + Vector2(0.5, 0.5))
	return s


## The festival decorations on map `m` today (data/festivals.json props), [] when there are none.
static func festival_props_today(game: Object, m: MapData) -> Array:
	var f := Festivals.get_festival(game.festival_today())
	if f.is_empty() or str(f.get("map", "")) != m.id:
		return []
	var out := []
	for p in f.get("props", []):
		if str(p.get("kind", "")) == "sakura":
			out.append(p)
	return out


## Every mote of `kind` at time `t` (seconds), for a scene from scene_of, `amount_now` 0..1 and a
## wind of 0..1: [{pos: Vector3 (x, height, z) in cells, alpha, color: Color, size: cells}].
## A pure function of its arguments: the views only move `t` on.
static func motes(kind: String, amount_now: float, t: float, wind: float, scene: Dictionary, cfg := {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n := count_for(kind, amount_now, cfg)
	if n == 0:
		return out
	if cfg.is_empty():
		cfg = config()
	var k: Dictionary = cfg[kind]
	for i in n:
		out.append(_firefly(i, k, t, wind, scene, cfg) if kind == "firefly" else _faller(kind, i, k, t, wind, scene, cfg))
	return out


## The drift direction (unit, x / z) of the wind.
static func wind_dir(cfg := {}) -> Vector2:
	if cfg.is_empty():
		cfg = config()
	return Vector2(float(cfg.wind_dir[0]), float(cfg.wind_dir[1])).normalized()


static func _faller(kind: String, i: int, k: Dictionary, t: float, wind: float, scene: Dictionary, cfg: Dictionary) -> Dictionary:
	var life := float(k.life) * (1.0 + (rnd(i, 0, 1) - 0.5) * 2.0 * float(k.life_var))
	var tt := t + rnd(i, 0, 2) * life
	var cycle := floori(tt / life)
	var u := tt / life - float(cycle)
	var area: Rect2 = scene.area
	var trees: Array = scene.trees.get(kind, [])
	var from: Vector2
	var top: float
	if not trees.is_empty() and rnd(i, cycle, 3) < float(k.near_tree):
		var tr: Vector2 = trees[int(rnd(i, cycle, 4) * trees.size()) % trees.size()]
		var r := float(k.tree_radius)
		from = tr + Vector2((rnd(i, cycle, 5) - 0.5) * 2.0 * r, (rnd(i, cycle, 6) - 0.5) * 2.0 * r * 0.6)
		top = float(k.tree_height) * (0.75 + 0.25 * rnd(i, cycle, 7))
	else:
		from = area.position + Vector2(rnd(i, cycle, 5) * area.size.x, rnd(i, cycle, 6) * area.size.y)
		top = float(k.sky_height) * (0.6 + 0.4 * rnd(i, cycle, 7))
	var dir := wind_dir(cfg)
	var speed := float(k.drift) + float(k.drift_wind) * wind
	var phase := rnd(i, cycle, 8)
	var swing := sin((u * float(k.sway_cycles) + phase) * TAU) * float(k.sway)
	var at := from + dir * speed * life * u + Vector2(-dir.y, dir.x) * swing * 0.5
	# A fluttering fall: the sway also rocks the height a little, and the mote slows toward the ground.
	var h := top * (1.0 - u) + absf(swing) * 0.08
	var colors: Array = k.colors
	return {
		"pos": Vector3(at.x, maxf(h, 0.0), at.y),
		"alpha": clampf(minf(u / 0.12, (1.0 - u) / 0.15), 0.0, 1.0),
		"color": Color(str(colors[int(rnd(i, cycle, 9) * colors.size()) % colors.size()])),
		"size": float(k.size),
	}


static func _firefly(i: int, k: Dictionary, t: float, wind: float, scene: Dictionary, cfg: Dictionary) -> Dictionary:
	var wet: Array = scene.wet
	var dry: Array = scene.dry
	var spots: Array = wet if (rnd(i, 1, 1) < float(k.water_share) and not wet.is_empty()) or dry.is_empty() else dry
	var home: Vector2
	if spots.is_empty():
		var a: Rect2 = scene.area
		home = a.position + Vector2(rnd(i, 1, 2) * a.size.x, rnd(i, 1, 3) * a.size.y)
	else:
		home = spots[int(rnd(i, 1, 2) * spots.size()) % spots.size()] + Vector2(rnd(i, 1, 4) - 0.5, rnd(i, 1, 5) - 0.5) * 0.8
	var sp := float(k.speed) * (0.7 + 0.6 * rnd(i, 2, 1))
	var w := float(k.wander)
	var at := home + Vector2(sin(t * sp + rnd(i, 2, 2) * TAU), cos(t * sp * 0.77 + rnd(i, 2, 3) * TAU)) * w
	at += wind_dir(cfg) * wind * float(k.wind_push) * (0.5 + 0.5 * sin(t * 0.3 + rnd(i, 2, 4) * TAU))
	var hs: Array = k.height
	var h := lerpf(float(hs[0]), float(hs[1]), 0.5 + 0.5 * sin(t * sp * 1.3 + rnd(i, 2, 5) * TAU))
	var blink := maxf(0.0, sin((t * float(k.blink) * (0.8 + 0.4 * rnd(i, 3, 1)) + rnd(i, 3, 2)) * TAU))
	return {
		"pos": Vector3(at.x, h, at.y),
		"alpha": blink * blink,
		"color": Color(str(k.light)),
		"size": float(k.size),
	}
