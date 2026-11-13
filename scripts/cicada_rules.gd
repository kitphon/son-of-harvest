class_name CicadaRules
extends RefCounted
## Cicadas (semi) of summer outdoors (data/cicadas.json): the day cicada's sizzling chorus through
## the summer days, loudest round midday from mid summer on and lingering a few days into fall, and
## the evening cicada's falling call at dusk in late summer; none at night, in rain, storm or snow,
## indoors or in the mine. This is the logic the sound and both views share: how much of each kind
## there is now (the day counted from the first of summer, the clock, the weather look), how loud
## its loop plays on a map (Sfx merges it into the ambient loops), and where the few one can see
## sit: clinging to the camera side of the broadleaf trees' trunks (cells x, height, z), pumping as
## they sing, flying off with a buzz when a walker comes close and coming back once they are gone.
## The 3D view (CicadaLayer) draws them as billboards, the flat view (CicadaView) from above in
## pixels; CicadaArt draws the pictures ("cicada:<kind>:<cling|fly>:<frame>"). Pure: a place is a
## function of its arguments (a seeded hash, no random numbers); the only memory is the caller's
## `state` of which cicadas were startled and when. Nothing here draws or plays.

const DATA_PATH := "res://data/cicadas.json"
const TREES := "res://scripts/world3d/trees.gd"   # loaded when wanted: the 3D scripts need the Game autoload to compile
const KINDS: Array[String] = ["semi", "higurashi"]
const NO_FARMER := Vector2(-9999.0, -9999.0)
const SEASONS: Array[String] = ["spring", "summer", "fall", "winter"]   # Game.SEASONS
const DAYS := 30   # Game.DAYS_PER_SEASON

static var _cfg: Dictionary = {}
static var _forced: Array = []
static var _forced_read := false


## data/cicadas.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## `-- --cicadas` (both kinds) or `--cicadas=semi,higurashi` on the command line: those kinds sing
## and cling to every tree's trunk at full strength whatever the season, weather and clock
## (screenshots; outdoors only all the same).
static func forced() -> Array:
	if not _forced_read:
		_forced_read = true
		for arg in OS.get_cmdline_user_args():
			if arg == "--cicadas":
				_forced = KINDS.duplicate()
			elif arg.begins_with("--cicadas="):
				for id in arg.trim_prefix("--cicadas=").split(","):
					if id in KINDS and not id in _forced:
						_forced.append(id)
	return _forced


## A steady pseudo-random number in 0..1 from three integers (the drift's).
static func rnd(a: int, b: int, c: int) -> float:
	return DriftRules.rnd(a, b, c)


static func _ease(x: float) -> float:
	var s := clampf(x, 0.0, 1.0)
	return s * s * (3.0 - 2.0 * s)


## The day counted from the first of summer: summer 1..30, fall 31..60; 0 in spring and winter.
static func summer_day(season_id: String, day: int) -> int:
	if season_id == "summer":
		return day
	if season_id == "fall":
		return DAYS + day
	return 0


## How much of its season kind `kind` has on `day` of `season_id`: 0 outside its "days", easing in
## over "fade_in" days and out over "fade_out" days.
static func day_share(kind: String, season_id: String, day: int, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var k: Dictionary = cfg[kind]
	var d := float(summer_day(season_id, day))
	if d <= 0.0:
		return 0.0
	var a := float(k.days[0])
	var b := float(k.days[1])
	if d < a or d > b:
		return 0.0
	return _ease((d - a + 1.0) / maxf(float(k.fade_in), 0.001)) * _ease((b - d + 1.0) / maxf(float(k.fade_out), 0.001))


## The clock's share: 0 outside [from, to], easing over "fade_hours" at each end.
static func hour_share(kind: String, hour: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var k: Dictionary = cfg[kind]
	var a := float(k.hours[0])
	var b := float(k.hours[1])
	if hour < a or hour > b:
		return 0.0
	var fade := maxf(float(k.fade_hours), 0.001)
	return _ease(minf(hour - a, b - hour) / fade)


## How much of kind `kind` there is: 0..1 by the season's day, the weather look and the clock `hour`.
static func amount(kind: String, season_id: String, look: String, hour: float, day: int, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var share := float((cfg[kind].looks as Dictionary).get(look, 0.0))
	if share <= 0.0:
		return 0.0
	return share * day_share(kind, season_id, day, cfg) * hour_share(kind, hour, cfg)


## Is map `m` (MapData) one where cicadas sing? Outdoors only: not a room, not under rock.
static func outdoors(m: MapData) -> bool:
	return m != null and not m.indoor and not m.sheltered and m.ambient == "outdoor"


## {kind: amount} now on map `m` for the kinds above 0 (`game` is the Game autoload); {} indoors
## or in the mine; the forced kinds (`--cicadas`) at 1.
static func amounts_now(game: Object, m: MapData, cfg := {}) -> Dictionary:
	var out := {}
	if game == null or not outdoors(m):
		return out
	if cfg.is_empty():
		cfg = config()
	var look: String = game.weather_look(game.weather_today, game.season_name())
	var hour := float(game.hour) + float(game.minute) / 60.0
	for kind in KINDS:
		var a := amount(kind, game.season_name(), look, hour, int(game.day), cfg)
		if kind in forced():
			a = 1.0
		if a > 0.0:
			out[kind] = a
	return out


## The loops to play for `amounts` ({kind: amount}) on map `map_id` in a wind of `wind` (0..1):
## {loop key: level 0..1}, the kind's "level" x the map's share x the wind's quieting.
static func sound_levels(amounts: Dictionary, map_id: String, wind := 0.0, cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var maps: Dictionary = cfg.get("map_level", {})
	var place := float(maps.get(map_id, maps.get("default", 1.0)))
	var quiet := clampf(1.0 - float(cfg.get("wind_quiet", 0.0)) * clampf(wind, 0.0, 1.0), 0.0, 1.0)
	var out := {}
	for kind in amounts:
		var level := float(amounts[kind]) * float(cfg[kind].get("level", 1.0)) * place * quiet
		if level > 0.0:
			out[str(cfg[kind].loop)] = level
	return out


## The cicada loops wanted now on the current map (the Sfx autoload adds them to the ambient
## loops): {} without a clock, indoors or in the mine.
static func sound_now(game: Object, m: MapData) -> Dictionary:
	if game == null or not bool(game.clock_running):
		return {}
	return sound_levels(amounts_now(game, m), str(game.maps.id), float(game.wind_strength()))


## Every loop key the cicadas can ask for (Sfx makes a player for each).
static func loops(cfg := {}) -> Array:
	if cfg.is_empty():
		cfg = config()
	var out := []
	for kind in KINDS:
		out.append(str(cfg[kind].loop))
	return out


## The trunks of map `m` the cicadas cling to: {trunks: [{cell: Vector2i, kind, foot: Vector2
## (cells), lo, hi, lean: the trunk's axis, a unit vector}], seed}. Only the trees of "trunks" (a
## prop's foot is its first cell's middle, as MapWorld builds it; a village pine leans as
## Trees.pine_lean says). The farm has none.
static func scene_of(m: MapData, seed_value := 0, cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var kinds: Dictionary = cfg.trunks
	var trunks: Array[Dictionary] = []
	if m != null:
		for p in m.props:
			var kind := str(p.kind)
			if not kinds.has(kind):
				continue
			var c := Vector2i(int(p.cell[0]), int(p.cell[1]))
			var span: Array = kinds[kind]
			var lean: Vector3 = load(TREES).pine_lean(c.x * 31 + c.y * 17, true) if kind == "pine" else Vector3.UP   # MapWorld._pine's seed
			trunks.append({"cell": c, "kind": kind, "foot": Vector2(c) + Vector2(0.5, 0.5),
				"lo": float(span[0]), "hi": float(span[1]), "lean": lean})
	return {"trunks": trunks, "seed": seed_value}


## Kiku's persimmon's stage for the cicadas' key: "" while it is not planted (Scion.planted).
static func scion_stage(flags: Dictionary, today: int) -> String:
	return Scion.stage(flags, today) if Scion.planted(flags) else ""


## Adds Kiku's persimmon to `scene` (scene_of) as a trunk when it stands on the farm: the farm's
## scion prop whose flag_value is `flag_value` (the story flag kiku_scion, "" when none), at `stage`
## (Scion.stage: a trunk only where cfg.scion has it, so never the sapling). Returns `scene`.
static func add_scion(scene: Dictionary, m: MapData, stage: String, flag_value: String, cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var span: Variant = (cfg.get("scion", {}) as Dictionary).get(stage)
	if m == null or span == null or flag_value == "":
		return scene
	for p in m.props:
		if str(p.get("kind", "")) != "scion" or str(p.get("flag_value", "")) != flag_value:
			continue
		var c := Vector2i(int(p.cell[0]), int(p.cell[1]))
		# The picture stands on its plane `scion_plane` cells toward the camera from the cell's middle
		# (StoryProps, "scion"), so the cicadas sit on that plane, not behind it.
		var plane := float(cfg.get("scion_plane", 0.0))
		(scene.trunks as Array).append({"cell": c, "kind": "scion", "foot": Vector2(c.x + 0.5, c.y + 0.5 + plane),
			"lo": float(span[0]), "hi": float(span[1]), "lean": Vector3.UP})
	return scene


## The trunk's radius at height `h` (cells): "radius" at the foot narrowing to "radius_top" at 1.2.
static func radius_at(h: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	return lerpf(float(cfg.radius), float(cfg.radius_top), clampf(h / 1.2, 0.0, 1.0))


## Where the clinging cicadas of `kind` sit at `amount_now` (0..1) in `scene`: [{id, kind, tree,
## spot: Vector3}] (x, height, z in cells, on the trunk's camera side), the same all day.
static func spots(kind: String, amount_now: float, scene: Dictionary, cfg := {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if amount_now <= 0.0:
		return out
	if cfg.is_empty():
		cfg = config()
	var k: Dictionary = cfg[kind]
	var salt := KINDS.find(kind) * 1000 + 7
	var seed_value := int(scene.get("seed", 0))
	var all := kind in forced()
	var share := 1.0 if all else float(k.tree_share) * clampf(amount_now, 0.0, 1.0)
	var trunks: Array = scene.trunks
	for i in trunks.size():
		var tr: Dictionary = trunks[i]
		var c: Vector2i = tr.cell
		if rnd(c.x * 7 + salt, c.y * 13, seed_value) >= share:
			continue
		var n := 2 if rnd(c.x + salt, c.y, seed_value + 5) < float(k.pair_share) else 1
		for j in n:
			var r1 := rnd(c.x * 3 + j, c.y * 5 + salt, seed_value + 11)
			var r2 := rnd(c.x * 11 + salt, c.y * 3 + j, seed_value + 17)
			var h := lerpf(float(tr.lo), float(tr.hi), r1)
			if j == 1:   # the second sits apart from the first, above or below it
				h = lerpf(float(tr.lo), float(tr.hi), fposmod(r1 + 0.5, 1.0))
			var ang := deg_to_rad(float(cfg.front) + (r2 * 2.0 - 1.0) * float(cfg.front_spread))
			var foot: Vector2 = tr.foot
			var lean: Vector3 = tr.get("lean", Vector3.UP)
			var axis := lean * (h / maxf(lean.y, 0.5))   # the trunk's middle at height h
			var r := radius_at(h, cfg) * float((cfg.get("trunk_radius", {}) as Dictionary).get(str(tr.kind), 1.0))
			var off := Vector2(cos(ang), sin(ang)) * r
			out.append({"id": "%s:%d,%d:%d" % [kind, c.x, c.y, j], "kind": kind, "tree": i,
				"spot": Vector3(foot.x + axis.x + off.x, h, foot.y + axis.z + off.y)})
	return out


## The cicadas of `kind` now, at time `t` (seconds): [{id, kind, pos: Vector3 (cells x, height, z),
## pose: "cling" | "fly", frame, dir: Vector2 (the way it faces on the ground), fled: true on the
## call it took fright}]. `farmer` (cells) and `others` (the other walkers, cells) startle a
## clinging one within "scare" cells (the others at "startle" "others" of it): it flies off away
## from them for "flee_time" and is gone, then comes back along the same path "return_after"
## seconds later once every walker is further than 1.5 x "scare". `state` is the caller's memory.
static func cicadas(kind: String, amount_now: float, t: float, scene: Dictionary, farmer: Vector2, state: Dictionary, cfg := {}, others: Array = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if cfg.is_empty():
		cfg = config()
	var k: Dictionary = cfg[kind]
	var scare := float(cfg.scare)
	var flee := maxf(float(cfg.flee_time), 0.01)
	var back := float(cfg.return_after)
	var walkers := [[farmer, 1.0]]   # [place, share of the reach]: the farmer whole, the others at "startle" "others"
	for o in others:
		if o is Vector2:
			walkers.append([o, float(cfg.get("startle", {}).get("others", 1.0))])
	# `--cicadas` (forced): they start settled, whoever stands by, for "forced_calm" seconds (the frame shows them on the trunks at once).
	if kind in forced() and t < float(cfg.get("forced_calm", 0.0)):
		walkers = []
	for s in spots(kind, amount_now, scene, cfg):
		var spot: Vector3 = s.spot
		var ground := Vector2(spot.x, spot.z)
		var near := _nearest(ground, walkers, scare)   # [walker, how close as a share of its reach] or []
		var far := _clear(ground, walkers, scare * 1.5)
		var id: String = s.id
		var c := {"id": id, "kind": kind, "pos": spot, "pose": "cling", "dir": Vector2.LEFT, "fled": false}
		var st: Dictionary = state.get(id, {})
		if st.is_empty() and not near.is_empty():
			var away := ground - (near[0] as Vector2)
			away = away.normalized() if away.length() > 0.01 else Vector2(1, 1).normalized()
			st = {"at": t, "away": away}
			state[id] = st
			c.fled = true
		if not st.is_empty():
			var e := t - float(st.at)
			var u := -1.0   # how far out along the path (0 on the trunk, 1 gone); < 0 = gone from sight
			if e < flee:
				u = e / flee
			elif e < back or not far:
				if not far:   # someone is still near: the wait starts once they have gone
					st.at = t - flee
				u = -1.0
			elif e < back + flee:
				u = 1.0 - (e - back) / flee
				if not near.is_empty():   # frightened again on the way in: turn back out from here
					st.at = t - (1.0 - u) * flee
			else:
				state.erase(id)
				u = 0.0
			if u < 0.0:
				continue
			if u > 0.0:
				var away: Vector2 = st.away
				var p := 1.0 - pow(1.0 - u, 2.0)   # fast off the trunk, slowing far out
				var wob := sin(t * 9.0 + spot.x * 3.0) * 0.18 * u
				var side := Vector2(-away.y, away.x)
				var g := ground + away * float(cfg.flee_dist) * p + side * wob
				c.pos = Vector3(g.x, spot.y + float(cfg.flee_height) * p, g.y)
				c.pose = "fly"
				c.dir = away if e < flee else -away
				c.frame = int(floor(t * float(cfg.flap))) % 2
				out.append(c)
				continue
		c.frame = int(floor(t * float(k.pulse) + float(s.tree) * 0.37)) % 2
		out.append(c)
	return out


## The closest walker within its reach of `at`: [place, share of the reach] or [] when none is.
static func _nearest(at: Vector2, walkers: Array, reach: float) -> Array:
	var best := []
	var best_k := INF
	for w in walkers:
		var r := reach * float(w[1])
		var d := at.distance_to(w[0] as Vector2)
		if r > 0.0 and d <= r and d / r < best_k:
			best_k = d / r
			best = [w[0], best_k]
	return best


## No walker within its share of `reach` of `at`.
static func _clear(at: Vector2, walkers: Array, reach: float) -> bool:
	return _nearest(at, walkers, reach).is_empty()


## The picture key of cicada `c` (CicadaArt, PlaceholderArt "cicada:").
static func key_of(c: Dictionary) -> String:
	return "cicada:%s:%s:%d" % [c.kind, c.pose, int(c.get("frame", 0))]


static func flying(c: Dictionary) -> bool:
	return str(c.get("pose", "")) == "fly"


## Does a walker of villager id `id` (the child: at `stage`) startle them? Everyone does but the
## little one before the stages of "startle" "child_stages" (as InsectRules.scares).
static func scares(id: String, stage := "", cfg := {}) -> bool:
	if id != "child":
		return true
	if cfg.is_empty():
		cfg = config()
	return stage in (cfg.get("startle", {}).get("child_stages", []) as Array)
