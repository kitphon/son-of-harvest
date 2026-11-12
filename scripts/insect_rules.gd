class_name InsectRules
extends RefCounted
## Small flying insects on the outdoor maps (data/insects.json): white and pale yellow
## butterflies wandering over the crops, forage spots, garden beds and open grass of spring and
## early summer days, and red dragonflies (akatombo) of late summer and fall that hover, dart and
## hover again in small swarms over the paddies, the water and open ground, now and then landing
## on a fence post, a drying rack's pole or a tall crop's top to rest with their wings flat. This
## is the logic both views share: which kinds show now (season, the day of the season, weather
## look, clock, the wind thinning them, indoors or not: DriftRules.amount does the window), how
## many, and where each one is at a time `t` (cells x, height, z), which of its pictures it shows
## (InsectArt key "insect:<kind>:<pose>:<frame>") and which way it faces. The 3D view
## (InsectLayer) draws them as billboards, the flat view (InsectView) from above in pixels. Pure:
## a place is a function of its arguments (a seeded hash, no random numbers); the only memory is
## the caller's `state` dictionary of which resting dragonflies were startled and when. Nothing
## here draws.

const DATA_PATH := "res://data/insects.json"
const KINDS: Array[String] = ["butterfly", "dragonfly"]
const NO_FARMER := Vector2(-9999.0, -9999.0)
const NO_AIM := Vector2(-99999.0, -99999.0)   # not forced (see forced())

static var _cfg: Dictionary = {}
static var _forced: Array = []
static var _perched_forced: Array = []
static var _forced_read := false


## data/insects.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## `-- --insects` (every kind) or `--insects=dragonfly,butterfly` on the command line: those kinds
## show at full strength whatever the season, weather and clock (screenshots), placed round the
## farmer (the map's middle without one) at the start. `--insects=dragonfly:perched` also holds the
## first dragonfly resting on the perch nearest the farmer (held_perch), for a frame of it.
static func forced() -> Array:
	_read_args()
	return _forced


## The kinds forced to perch (`--insects=<kind>:perched`).
static func perched_forced() -> Array:
	_read_args()
	return _perched_forced


static func _read_args() -> void:
	if _forced_read:
		return
	_forced_read = true
	for arg in OS.get_cmdline_user_args():
		if arg == "--insects":
			_forced = KINDS.duplicate()
		elif arg.begins_with("--insects="):
			for item in arg.trim_prefix("--insects=").split(","):
				var parts := item.split(":")
				if parts[0] in KINDS:
					_forced.append(parts[0])
					if parts.size() > 1 and parts[1] == "perched":
						_perched_forced.append(parts[0])


## A steady pseudo-random number in 0..1 from three integers (the drift's, so everywhere the same).
static func rnd(a: int, b: int, c: int) -> float:
	return DriftRules.rnd(a, b, c)


static func _ease(x: float) -> float:
	var s := clampf(x, 0.0, 1.0)
	return s * s * (3.0 - 2.0 * s)


## How much of the season's days kind `kind` has on day `day`: 1 where the data has no "days" for
## the season, else 1 inside [first, last] easing in and out over "fade_days" at each end.
static func day_share(kind: String, season_id: String, day: int, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var k: Dictionary = cfg[kind]
	var days: Dictionary = k.get("days", {})
	if not days.has(season_id):
		return 1.0
	var a := float((days[season_id] as Array)[0])
	var b := float((days[season_id] as Array)[1])
	var fade := maxf(float(k.get("fade_days", 1)), 0.001)
	var d := float(day)
	return _ease(minf((d - a + 1.0) / fade, (b - d + 1.0) / fade))


## How much of kind `kind` shows: 0..1, from the season, the day, the weather look and the clock
## `hour` (the wind comes in thinned()).
static func amount(kind: String, season_id: String, look: String, hour: float, day := 1, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	return DriftRules.amount(kind, season_id, look, hour, cfg) * day_share(kind, season_id, day, cfg)


## `amount_now` after the wind (0..1, data/wind.json) thins it: times 1 - "wind_thin" x wind.
static func thinned(amount_now: float, wind: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	return amount_now * clampf(1.0 - float(cfg.get("wind_thin", 1.0)) * clampf(wind, 0.0, 1.0), 0.0, 1.0)


## What shows now on the map `m` (MapData): {kind: amount} for the kinds above 0. None indoors or in
## the mine, or without a clock (`game` is the Game autoload). `wind` is the wind of the day (-1:
## ask the game).
static func amounts_now(game: Object, m: MapData, cfg := {}, wind := -1.0) -> Dictionary:
	var out := {}
	if game == null or m == null or m.indoor or m.sheltered:
		return out
	if cfg.is_empty():
		cfg = config()
	var look: String = game.weather_look(game.weather_today, game.season_name())
	var hour := float(game.hour) + float(game.minute) / 60.0
	if wind < 0.0:
		wind = float(game.wind_strength())
	for kind in KINDS:
		var a := thinned(amount(kind, game.season_name(), look, hour, int(game.day), cfg), wind, cfg)
		if kind in forced():
			a = 1.0
		if a > 0.0:
			out[kind] = a
	return out


## How many of `kind` show at `amount_now` (0..1): the data's count scaled, at least one.
static func count_for(kind: String, amount_now: float, cfg := {}) -> int:
	if amount_now <= 0.0:
		return 0
	if cfg.is_empty():
		cfg = config()
	return maxi(int(round(float(cfg[kind].count) * clampf(amount_now, 0.0, 1.0))), 1)


## The places a map's insects use: {area: Rect2 in cells, lures: crop, forage and garden cell
## centres (butterflies), grass: open ground cell centres, wet: water and paddy cell centres (the
## farm: the pond and the rice), perches: Vector3 (x, height, z) spots a dragonfly can rest on,
## seed, near: a cache the rules fill}. `farm` (FarmGrid) gives the farm's crops, pond and fence.
static func scene_of(m: MapData, farm: FarmGrid = null, seed_value := 0, cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var dk: Dictionary = cfg.dragonfly
	var ph: Dictionary = dk.perch_h
	var lures: Array[Vector2] = []
	var grass: Array[Vector2] = []
	var wet: Array[Vector2] = []
	var perches: Array[Vector3] = []
	if farm != null:
		var stage_min := int(dk.perch_stage)
		var gates := m.gate_cells()   # the gate road has no post (FarmWorld._make_fence leaves it open)
		for y in farm.h:
			for x in farm.w:
				var c := Vector2i(x, y)
				var mid := Vector2(x, y) + Vector2(0.5, 0.5)
				var f := str(farm.fixed.get(c, ""))
				if f == "pond":
					wet.append(mid)
					continue
				if f == "fence":
					if not c in gates:
						perches.append(Vector3(mid.x, float(ph.fence), mid.y))
					continue
				if f != "":
					continue
				var d: Dictionary = farm.cell(c)
				var id := str(d.get("crop", ""))
				if id != "":
					if bool((farm.crops.get(id, {}) as Dictionary).get("holds_water", false)):
						wet.append(mid)
					else:
						lures.append(mid)
					if int(d.get("stage", 0)) >= stage_min and ph.has(id):
						perches.append(Vector3(mid.x, float(ph[id]), mid.y))
				elif not farm.is_solid(c):
					grass.append(mid)
	else:
		for y in m.h:
			for x in m.w:
				var c := Vector2i(x, y)
				var mid := Vector2(x, y) + Vector2(0.5, 0.5)
				var t := m.tile(c)
				if t == "water" or t == "paddy":
					wet.append(mid)
					if t == "paddy" and rnd(x, y, 81) < float(dk.paddy_perch_share):
						perches.append(Vector3(mid.x, float(ph.paddy), mid.y))
				elif t == "grass" and not m.is_solid(c):
					grass.append(mid)
		for p in m.props:
			var kind := str(p.get("kind", ""))
			if kind == "garden":
				for y in int(p.size[1]):
					for x in int(p.size[0]):
						lures.append(Vector2(int(p.cell[0]) + x, int(p.cell[1]) + y) + Vector2(0.5, 0.5))
			elif kind == "wood_fence" or kind == "hasa":
				_posts(p, float(ph[kind]), perches, 0.1 if kind == "wood_fence" else 0.15)
		for sp in Forage.spots(m.id):
			lures.append(Vector2(sp.cell) + Vector2(0.5, 0.5))
	return {"area": Rect2(0, 0, m.w, m.h), "lures": lures, "grass": grass, "wet": wet, "perches": perches,
		"seed": seed_value, "near": {}}


## The post tops of a fence or drying rack prop `p` (a post at each whole step along it, as the 3D
## props stand them), at height `h`, into `out`.
static func _posts(p: Dictionary, h: float, out: Array[Vector3], edge: float) -> void:
	var cell := Vector2(float(p.cell[0]), float(p.cell[1]))
	var size := Vector2(float(p.size[0]), float(p.size[1]))
	var along_x := size.x >= size.y
	var long := size.x if along_x else size.y
	for i in int(long) + 1:
		var a := clampf(float(i), edge, long - edge)
		var at := Vector2(cell.x + a, cell.y + size.y / 2.0) if along_x else Vector2(cell.x + size.x / 2.0, cell.y + a)
		out.append(Vector3(at.x, h, at.y))


## A key that changes when the farm's plantings do (the crops' count), so the views rebuild the
## scene's lures and perches then.
static func farm_key(farm: FarmGrid) -> String:
	if farm == null:
		return ""
	var n := 0
	for d in farm.cells:
		if str((d as Dictionary).get("crop", "")) != "":
			n += 1
	return str(n)


## Every insect of `kind` now (`t` seconds, `amount_now` 0..1) for a scene from scene_of, the
## farmer's place in cells (NO_FARMER when there is none), `state` (a Dictionary the caller keeps
## from frame to frame: which resting dragonflies were startled and when) and `others`, the other
## walkers' places in cells (villagers, the dog, the walking child). Each: {id: "kind:i", kind,
## art (the picture's kind: butterfly, butterfly_y, dragonfly), pos: Vector3 (x, height, z) in
## cells, pose ("fly" or "perch"), frame, dir: Vector2 (the way it faces), alpha}.
static func insects(kind: String, amount_now: float, t: float, scene: Dictionary, farmer: Vector2, state: Dictionary, cfg := {}, others: Array = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n := count_for(kind, amount_now, cfg)
	if n == 0:
		return out
	if cfg.is_empty():
		cfg = config()
	var k: Dictionary = cfg[kind]
	var aim := NO_AIM
	if kind in forced():
		aim = farmer if farmer != NO_FARMER else (scene.area as Rect2).get_center()
	var walkers := _walkers(farmer, others, cfg)
	var held := kind in perched_forced()
	for i in n:
		if i == 0 and held:   # `:perched`: the first one rests on the perch nearest the aim, for good
			var r := held_perch(scene, aim)
			if not r.is_empty():
				out.append(r)
			continue
		var b := _butterfly(i, k, t, scene, walkers, aim) if kind == "butterfly" else _dragonfly(i, k, t, scene, walkers, state, aim)
		if not b.is_empty():
			out.append(b)
	return out


## A dragonfly held resting on the perch nearest `aim` (a screenshot's; it never lifts off, so no
## state): wings flat, facing right. {} when the map has no perch.
static func held_perch(scene: Dictionary, aim: Vector2) -> Dictionary:
	var best := Vector3.ZERO
	var found := false
	var best_d := INF
	for p in scene.perches:
		var d := Vector2(p.x, p.z).distance_to(aim)
		if d < best_d:
			best_d = d
			best = p
			found = true
	if not found:
		return {}
	return {"id": "dragonfly:0", "kind": "dragonfly", "art": "dragonfly", "pos": best, "pose": "perch",
		"frame": 0, "dir": Vector2.RIGHT, "alpha": 1.0}


## The shadow insect `b` throws on the ground (data/insects.json "shadow", the birds' rules via
## BirdRules.shadow_of, the same shape: {at, size, alpha}, or {}). A perched dragonfly's soft blob
## on the ground under it; a flier's faint sun-cast oval (none without sun). Nothing falls on a
## building: `blocked` (scene.blocked, blocked_for) leaves out a flier's oval that lands on one and a
## perched one's blob that sits on one.
static func shadow_of(b: Dictionary, sun: float, sun_dir: Vector3, cfg := {}, blocked := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var s := BirdRules.shadow_of(b, sun, sun_dir, cfg, blocked)
	if s.is_empty() or flying(b):
		return s
	if blocked.has(Vector2i(floori(s.at.x), floori(s.at.y))):
		return {}
	return s


## The buildings' cells a shadow is kept off (BirdRules.blocked_cells with the insects' lists),
## rebuilt when the farm's buildings change (BirdRules.built_key) and kept in `scene`.
static func blocked_for(scene: Dictionary, m: MapData, farm: FarmGrid, game: Object) -> Dictionary:
	var key := BirdRules.built_key(game)
	if not scene.has("blocked") or scene.get("built_key", null) != key:
		scene.built_key = key
		scene.blocked = BirdRules.blocked_cells(m, farm, config())
	return scene.blocked


## The picture key of an insect from insects().
static func key_of(b: Dictionary) -> String:
	return "insect:%s:%s:%d" % [b.art, b.pose, int(b.frame)]


## Is insect `b` in the air? Fliers draw over the roofs and figures in the flat view; a resting
## one keeps to the figures' order.
static func flying(b: Dictionary) -> bool:
	return str(b.get("pose", "")) == "fly"


## The walkers an insect takes fright at: [[place (cells), its share], ...], the farmer whole
## (share 1) and every other at the data's "startle" "others" share.
static func _walkers(farmer: Vector2, others: Array, cfg: Dictionary) -> Array:
	var out := [[farmer, 1.0]]
	var share := float(cfg.get("startle", {}).get("others", 1.0))
	for o in others:
		if o is Vector2:
			out.append([o, share])
	return out


## Does a walker of villager id `id` (the child: at `stage`) startle them? Everyone does but the
## little one before the stages of the data's "startle" "child_stages".
static func scares(id: String, stage := "", cfg := {}) -> bool:
	if id != "child":
		return true
	if cfg.is_empty():
		cfg = config()
	return stage in (cfg.get("startle", {}).get("child_stages", []) as Array)


## `pool` cells sorted by distance to `aim` (those within `skip` of it left out), kept in the scene.
static func _by_aim(scene: Dictionary, name: String, pool: Array, aim: Vector2, skip: float) -> Array:
	var key := "%s|%d,%d" % [name, roundi(aim.x * 4.0), roundi(aim.y * 4.0)]
	var cache: Dictionary = scene.near
	if not cache.has(key):
		var sorted := pool.filter(func(c): return (c as Vector2).distance_to(aim) > skip)
		sorted.sort_custom(func(a, b): return (a as Vector2).distance_to(aim) < (b as Vector2).distance_to(aim))
		cache[key] = sorted
	return cache[key]


## The cells of `pools` within `roam` of `home`, kept in the scene under `key`.
static func _near(scene: Dictionary, key: String, home: Vector2, roam: float, pools: Array) -> Array:
	var cache: Dictionary = scene.near
	if not cache.has(key):
		var list := []
		for pool in pools:
			for c in pool:
				var at := Vector2(c.x, c.z) if c is Vector3 else (c as Vector2)
				if at.distance_to(home) <= roam:
					list.append(c)
		cache[key] = list
	return cache[key]


# --- butterflies --------------------------------------------------------------------------------

static func _butterfly(i: int, k: Dictionary, t: float, scene: Dictionary, walkers: Array, aim: Vector2) -> Dictionary:
	var sd := int(scene.seed)
	var lures: Array = scene.lures
	var grass: Array = scene.grass
	var pool: Array = lures if (not lures.is_empty() and (grass.is_empty() or rnd(i, sd, 51) < float(k.lure_share))) else grass
	if pool.is_empty():
		return {}
	var home: Vector2 = pool[int(rnd(i, sd, 52) * pool.size()) % pool.size()]
	if aim != NO_AIM:   # forced: the i-th of the nearest places that are not under his feet
		var by: Array = _by_aim(scene, "b", lures + grass, aim, 1.6)
		if not by.is_empty():
			home = by[(i * 4) % by.size()]
	var near: Array = _near(scene, "b%d|%d,%d" % [i, roundi(home.x * 4.0), roundi(home.y * 4.0)], home, float(k.roam), [lures, grass])
	var leg := float(k.leg) * (1.0 + (rnd(i, 0, 57) - 0.5) * 2.0 * float(k.leg_var))
	var tt := t + (0.0 if aim != NO_AIM else rnd(i, 0, 53) * leg * 20.0) + float(i) * leg * 0.37
	var seg := floori(tt / leg)
	var u := tt / leg - float(seg)
	var a := _waypoint(i, seg, near, home)
	var b := _waypoint(i, seg + 1, near, home)
	var p := a.lerp(b, _ease(u))
	var heading := b - a
	var ph := rnd(i, 0, 58) * TAU
	if heading.length() < 0.05:
		heading = Vector2.RIGHT if rnd(i, seg, 59) < 0.5 else Vector2.LEFT
	p += Vector2(sin(tt * float(k.wobble_freq) + ph), cos(tt * float(k.wobble_freq) * 0.8 + ph * 1.7)) * float(k.wobble)   # a flutter that never jumps
	var hs: Array = k.height
	var h := lerpf(float(hs[0]), float(hs[1]), 0.5 + 0.5 * sin(tt * 0.45 + ph)) + sin(tt * 3.1 + ph) * float(k.bob)
	var dir := heading
	for w in walkers:   # a walker close by makes it veer away (and rise a little)
		var r := float(k.veer) * float(w[1])
		var d := p.distance_to(w[0])
		if d < r:
			var away: Vector2 = (p - (w[0] as Vector2)).normalized() if d > 0.001 else Vector2.RIGHT
			p += away * (r - d) * float(k.veer_push)
			h += (1.0 - d / r) * float(k.veer_rise)
			dir = away
	var gliding := sin(tt * 0.7 + ph) > cos(PI * float(k.glide))
	var frame := 1 if gliding else (0 if fposmod(tt * float(k.flap) + rnd(i, 0, 60), 1.0) < 0.5 else 1)
	return {
		"id": "butterfly:%d" % i, "kind": "butterfly", "art": "butterfly_y" if rnd(i, 0, 61) < float(k.yellow_share) else "butterfly",
		"pos": Vector3(p.x, maxf(h, 0.2), p.y), "pose": "fly", "frame": frame, "dir": dir, "alpha": 1.0,
	}


static func _waypoint(i: int, seg: int, near: Array, home: Vector2) -> Vector2:
	if near.is_empty():
		return home
	var c: Vector2 = near[int(rnd(i, seg, 54) * near.size()) % near.size()]
	return c + (Vector2(rnd(i, seg, 55), rnd(i, seg, 56)) - Vector2(0.5, 0.5)) * 1.2


# --- dragonflies --------------------------------------------------------------------------------

## Where a hovering and darting dragonfly is round `home` at time `t`: {pos, dir, frame}.
static func _hover(i: int, k: Dictionary, t: float, home: Vector2) -> Dictionary:
	var cyc := float(k.cycle) * (1.0 + (rnd(i, 0, 64) - 0.5) * 2.0 * float(k.cycle_var))
	var tt := t + rnd(i, 0, 65) * cyc * 9.0
	var n := floori(tt / cyc)
	var u := tt / cyc - float(n)
	var roam := float(k.roam)
	var a := home + (Vector2(rnd(i, n, 66), rnd(i, n, 67)) - Vector2(0.5, 0.5)) * 2.0 * roam
	var b := home + (Vector2(rnd(i, n + 1, 66), rnd(i, n + 1, 67)) - Vector2(0.5, 0.5)) * 2.0 * roam
	var hs: Array = k.height
	var ha := lerpf(float(hs[0]), float(hs[1]), rnd(i, n, 68))
	var hb := lerpf(float(hs[0]), float(hs[1]), rnd(i, n + 1, 68))
	var hv := float(k.hover)
	var ph := rnd(i, 0, 69) * TAU
	var p := a
	var h := ha
	if u < hv:   # hovering: a tremble in place
		p += Vector2(sin(tt * 3.1 + ph), cos(tt * 2.3 + ph)) * 0.05
		h += sin(tt * 4.0 + ph) * 0.03
	else:   # darting to the next hover point
		var e := _ease((u - hv) / (1.0 - hv))
		p = a.lerp(b, e)
		h = lerpf(ha, hb, e)
	var dir := b - a
	if dir.length() < 0.05:
		dir = Vector2.RIGHT if rnd(i, n, 70) < 0.5 else Vector2.LEFT
	return {"pos": Vector3(p.x, h, p.y), "dir": dir, "frame": int(fposmod(tt * float(k.flap), 2.0))}


static func _dragonfly(i: int, k: Dictionary, t: float, scene: Dictionary, walkers: Array, state: Dictionary, aim: Vector2) -> Dictionary:
	var sd := int(scene.seed)
	var g := i / maxi(int(k.group), 1)
	var wet: Array = scene.wet
	var grass: Array = scene.grass
	var pool: Array = wet if (not wet.is_empty() and (grass.is_empty() or rnd(g, sd, 71) < float(k.wet_share))) else grass
	if pool.is_empty():
		pool = scene.lures
	if pool.is_empty():
		return {}
	var home: Vector2 = pool[int(rnd(g, sd, 72) * pool.size()) % pool.size()]
	if aim != NO_AIM:   # forced: the group's home is among the nearest water, else ground, not under his feet
		var by: Array = _by_aim(scene, "dw", wet, aim, 2.4)
		if by.is_empty():
			by = _by_aim(scene, "dg", grass, aim, 2.4)
		if not by.is_empty():
			home = by[(g * 5) % by.size()]
	home += (Vector2(rnd(i, sd, 73), rnd(i, sd, 74)) - Vector2(0.5, 0.5)) * float(k.spread)
	var b := _normal(i, k, t, scene, home)
	var key := "dragonfly:%d" % i
	if not state.has(key):
		if b.pose == "perch":
			_try_startle(key, b.pos, walkers, t, k, state)
		if not state.has(key):
			return b
	return _startled(i, key, k, t, home, walkers, state, b)


## A dragonfly on its day's course: hovering and darting round `home`, and now and then a visit to
## a perch within "perch_range" of it (dart there, rest, dart back). {id, kind, art, pos, pose,
## frame, dir, alpha}.
static func _normal(i: int, k: Dictionary, t: float, scene: Dictionary, home: Vector2) -> Dictionary:
	var h := _hover(i, k, t, home)
	var b := {"id": "dragonfly:%d" % i, "kind": "dragonfly", "art": "dragonfly", "alpha": 1.0,
		"pos": h.pos, "pose": "fly", "frame": h.frame, "dir": h.dir}
	if (scene.perches as Array).is_empty():
		return b
	var pm := float(k.perch_period)
	var ptt := t + rnd(i, 0, 75) * pm * 7.0
	var m := floori(ptt / pm)
	var pu := ptt - float(m) * pm
	if rnd(i, m, 76) >= float(k.perch_chance):
		return b
	var near: Array = _near(scene, "p%d|%d,%d" % [i, roundi(home.x * 4.0), roundi(home.y * 4.0)], home, float(k.perch_range), [scene.perches])
	if near.is_empty():
		return b
	var spot: Vector3 = near[int(rnd(i, m, 77) * near.size()) % near.size()]
	var a0 := pm * (0.15 + 0.3 * rnd(i, m, 78))
	var app := float(k.approach)
	var rest := lerpf(float((k.rest as Array)[0]), float((k.rest as Array)[1]), rnd(i, m, 79))
	var lift := float(k.lift)
	if pu < a0:
		return b
	if pu < a0 + app:   # darting from where it was hovering to the perch
		var from: Vector3 = _hover(i, k, t - (pu - a0), home).pos
		b.pos = from.lerp(spot, _ease((pu - a0) / app))
		b.dir = Vector2(spot.x - from.x, spot.z - from.z)
	elif pu < a0 + app + rest:   # resting, wings flat
		b.pos = spot
		b.pose = "perch"
		b.frame = 0
		b.dir = Vector2.RIGHT if rnd(i, m, 80) < 0.5 else Vector2.LEFT
	elif pu < a0 + app + rest + lift:   # off again, back to its hovering
		var w := _ease((pu - a0 - app - rest) / lift)
		b.pos = spot.lerp(h.pos, w)
		b.dir = Vector2(h.pos.x - spot.x, h.pos.z - spot.z)
	if (b.dir as Vector2).length() < 0.05:
		b.dir = h.dir
	return b


## Starts a startle for the resting dragonfly `key` at `spot` if a walker is within its share of
## "scare": state[key] = [t, the way away, the spot, when it began to return (-1: not yet)].
static func _try_startle(key: String, spot: Vector3, walkers: Array, t: float, k: Dictionary, state: Dictionary) -> void:
	var at := Vector2(spot.x, spot.z)
	var near := NO_FARMER
	var best := INF
	for w in walkers:
		var d := at.distance_to(w[0])
		if d < float(k.scare) * float(w[1]) and d < best:
			best = d
			near = w[0]
	if near == NO_FARMER:
		return
	var away := (at - near).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	state[key] = [t, away, spot, -1.0]


## A startled dragonfly: darts away from where it rested, hovers there, and once `return_after`
## seconds have passed and every walker is further than 1.5 x "scare" from its perch, flies back
## to its day `b` over "blend" seconds (and the state is erased).
static func _startled(i: int, key: String, k: Dictionary, t: float, home: Vector2, walkers: Array, state: Dictionary, b: Dictionary) -> Dictionary:
	var st: Array = state[key]
	var el := t - float(st[0])
	var away: Vector2 = st[1]
	var from: Vector3 = st[2]
	var flee := float(k.flee_time)
	var dest := Vector2(from.x, from.z) + away * float(k.flee_dist)
	var out := {"id": key, "kind": "dragonfly", "art": "dragonfly", "alpha": 1.0, "pose": "fly", "dir": away}
	var end := Vector3(dest.x, float(k.flee_height), dest.y)
	if el < flee:
		out.pos = from.lerp(end, _ease(el / flee))
		out.frame = int(fposmod(el * float(k.flap), 2.0))
		return out
	var alt := _hover(i, k, t, dest)
	var pos: Vector3 = alt.pos
	var settle := maxf(float(k.get("settle", 1.0)), 0.001)
	if el < flee + settle:
		pos = end.lerp(pos, _ease((el - flee) / settle))
	if float(st[3]) < 0.0 and el > float(k.return_after):
		var clear := true
		for w in walkers:
			clear = clear and Vector2(from.x, from.z).distance_to(w[0]) > float(k.scare) * float(w[1]) * 1.5
		if clear:
			st[3] = t
	var dir: Vector2 = alt.dir
	if float(st[3]) >= 0.0:
		var w := (t - float(st[3])) / maxf(float(k.blend), 0.001)
		if w >= 1.0:
			state.erase(key)
			return b
		pos = pos.lerp(b.pos, _ease(w))
		if w > 0.5:
			dir = b.dir
	out.pos = pos
	out.dir = dir
	out.frame = alt.frame
	return out
