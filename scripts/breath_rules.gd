class_name BreathRules
extends RefCounted
## Breath in the cold (data/breath.json): on cold mornings and evenings the figures outdoors
## breathe out small pale puffs. This is the logic both views share: how cold it is now (season,
## day, clock, weather look; none indoors or in the mine), which figures breathe (the farmer, the
## villagers and the walking child, the grown animals and the dog, all placed by the views), and
## for each one its puffs at a time `t`: a puff every few seconds with its own gap, from the
## figure's id, so no two puff in step. A puff starts at the mouth on the side the figure faces,
## drifts forward and up on the wind of data/wind.json, grows and fades out in about a second.
## The 3D view (BreathLayer) draws them in world units, the flat view (BreathView) on whole
## pixels. Pure: nothing here draws. `--breath` (or `--breath=strong`) forces the strength on
## for a demo run.

const DATA_PATH := "res://data/breath.json"
const KINDS: Array[String] = ["person", "child", "crawler", "animal"]
const FARMER := "farmer"

static var _cfg: Dictionary = {}
static var _forced_read := false
static var _forced := {}


## data/breath.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## `--breath` (full cold everywhere outdoors) or `--breath=strong` (and the puffs come faster):
## {strength, rate} from the command line, {} when not asked for.
static func forced() -> Dictionary:
	if not _forced_read:
		_forced_read = true
		for arg in OS.get_cmdline_user_args():
			if arg == "--breath":
				_forced = {"strength": 1.0, "rate": 1.0}
			elif arg == "--breath=strong":
				_forced = {"strength": 1.0, "rate": 1.6}
	return _forced


## 0..1 while `hour` (a float, 0..24) is in the window [a, b], easing in and out over `fade`
## hours at its ends. A window of a whole day (24 hours or more) is 1 all day, no fade.
static func window(hour: float, a: float, b: float, fade: float) -> float:
	var span := b - a
	if span >= 24.0:
		return 1.0
	var into := hour - a
	if span < 0.0:   # past midnight
		span += 24.0
		if into < 0.0:
			into += 24.0
	if into < 0.0 or into > span:
		return 0.0
	var s := clampf(minf(into / maxf(fade, 0.001), (span - into) / maxf(fade, 0.001)), 0.0, 1.0)
	return s * s * (3.0 - 2.0 * s)


## How cold it is for breath, 0..1, from the season, the day (1..30), the weather look and the
## clock `hour`: the largest of the data's `cold` entries that holds now, lowered by the midday
## window of the winter days, and by the weather look's share.
static func cold_strength(season_id: String, day: int, look: String, hour: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var share := float((cfg.looks as Dictionary).get(look, 0.0))
	if share <= 0.0:
		return 0.0
	var best := 0.0
	for e in cfg.cold:
		if str(e.season) != season_id or day < int(e.days[0]) or day > int(e.days[1]):
			continue
		var s := float(e.strength) * window(hour, float(e.hours[0]), float(e.hours[1]), float(e.fade_hours))
		if e.has("midday"):   # the middle of a winter day is milder
			var md: Dictionary = e.midday
			var w := window(hour, float(md.hours[0]), float(md.hours[1]), float(md.fade_hours))
			s *= lerpf(1.0, float(md.share), w)
		best = maxf(best, s)
	return best * share


## The breath strength on the map `m` now (0..1; 0 when none): `game` is the Game autoload. None
## indoors, in a room or the mine (sheltered), or without a clock. The `--breath` run forces it.
static func strength_now(game: Object, m: MapData, cfg := {}) -> float:
	if game == null or m == null or m.indoor or m.sheltered:
		return 0.0
	var f := forced()
	if not f.is_empty():
		return float(f.strength)
	if cfg.is_empty():
		cfg = config()
	var look: String = game.weather_look(game.weather_today, game.season_name())
	var hour := float(game.hour) + float(game.minute) / 60.0
	return cold_strength(game.season_name(), int(game.day), look, hour, cfg)


## A figure's own number, from its id (the same every run).
static func seed_of(id: String) -> int:
	var h := 2166136261
	for c in id.to_utf8_buffer():
		h = ((h ^ c) * 16777619) & 0xffffffff
	return h


## The puff rate factor of a figure: walking, running (the farmer) and tired (the farmer) raise it.
static func rate_of(moving: bool, running: bool, tired: bool, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var r := 1.0
	if moving:
		r = float(cfg.rate.walk)
	if running:
		r = float(cfg.rate.run)
	if tired:
		r = maxf(r, float(cfg.rate.tired))
	var f := forced()
	if not f.is_empty():
		r *= float(f.rate)
	return r


## Where a figure's breaths start, the seconds between them: the figure's own gap (from its
## seed, within the data's min..max) shortened by its rate.
static func gap_of(seed: int, rate: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var g: Dictionary = cfg.gap
	return lerpf(float(g.min), float(g.max), rnd(seed, 0, 1)) / maxf(rate, 0.01)


## The breath of a figure now: {} when none shows, else {u (0..1: the puff's age over its life),
## age, cycle}. Breath number `cycle` starts at `cycle` gaps, moved by the jitter; a breath shows
## with the chance `strength` (so the colder, the more of them), and at most one shows at once
## (the gap is always longer than a puff lives).
static func phase(seed: int, t: float, rate: float, strength: float, cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	if strength <= 0.0 or rate <= 0.0:
		return {}
	var life := float(cfg.life)
	var g := gap_of(seed, rate, cfg)
	var jit := float(cfg.gap.jitter) * g
	var c0 := floori(t / g)
	for c in [c0, c0 - 1]:
		if c < 0 or rnd(seed, c, 2) >= strength:
			continue
		var start := float(c) * g + (rnd(seed, c, 3) * 2.0 - 1.0) * jit
		var age := t - start
		if age >= 0.0 and age < life:
			return {"u": age / life, "age": age, "cycle": c}
	return {}


## The facing as a unit vector (x, z in cells), south when there is none.
static func unit_facing(facing: Vector2) -> Vector2:
	return facing.normalized() if facing.length() > 0.001 else Vector2(0, 1)


## Where a figure's mouth is: x, height, z (cells), above its feet at `cell` (Vector2: x, y of the
## cells, y being the 3D z), a little out in front on the side it faces.
static func mouth(cell: Vector2, facing: Vector2, kind: String, cfg := {}) -> Vector3:
	if cfg.is_empty():
		cfg = config()
	var f := unit_facing(facing)
	var fwd := float(cfg.mouth.forward)
	return Vector3(cell.x + f.x * fwd, float((cfg.mouth as Dictionary).get(kind, 1.0)), cell.y + f.y * fwd)


## One puff at life share `u` (0..1), as the figure's mouth, drift and fade: {pos: Vector3 (x,
## height, z in cells), alpha, size (cells), color}. `wind` is 0..1.
static func shape(cell: Vector2, facing: Vector2, kind: String, u: float, strength: float, wind: float, cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var m := mouth(cell, facing, kind, cfg)
	var f := unit_facing(facing)
	var d: Dictionary = cfg.drift
	var dir := DriftRules.wind_dir()
	var at := Vector2(m.x, m.z) + f * float(d.forward) * u + dir * wind * float(d.wind_push) * u
	var h := m.y + float(d.rise) * u
	var size := lerpf(float(cfg.size.start), float(cfg.size.end), u) * float((cfg.get("scale", {}) as Dictionary).get(kind, 1.0))
	var a: Dictionary = cfg.alpha
	var fade := smoothstep(0.0, float(a["in"]), u) * (1.0 - smoothstep(float(a.out_from), 1.0, u))
	return {
		"pos": Vector3(at.x, h, at.y),
		"alpha": float(a.max) * clampf(strength, 0.0, 1.0) * clampf(fade, 0.0, 1.0),
		"size": size,
		"color": Color(str(cfg.color)),
		"stretch": float((cfg.get("wisp", {}) as Dictionary).get("stretch", 1.0)),
	}


## The kind of a villager from its stage ("" for a grown villager): the little ones breathe lower
## and smaller.
static func kind_of(stage: String) -> String:
	if stage == "crawler":
		return "crawler"
	return "child" if stage != "" else "person"


## A breath as its overlapping sub-puffs (data "wisp"): the first starts at the mouth, each next
## one `lag` of the life later, with its own weight and size, set a little aside and up by the
## hash of the breath (`seed`, `cycle`). [{pos, alpha, size, color, stretch}], empty before the first.
static func wisp(cell: Vector2, facing: Vector2, kind: String, u: float, strength: float, wind: float, seed := 0, cycle := 0, cfg := {}) -> Array[Dictionary]:
	if cfg.is_empty():
		cfg = config()
	var w: Dictionary = cfg.get("wisp", {"count": 1, "lag": 0.0, "weight": [1.0], "size": [1.0], "spread": 0.0})
	var out: Array[Dictionary] = []
	var f := unit_facing(facing)
	var side := Vector2(-f.y, f.x)
	for j in int(w.count):
		var d := float(w.lag) * j
		if u <= d:
			continue
		var p := shape(cell, facing, kind, (u - d) / (1.0 - d), strength, wind, cfg)
		p.size = float(p.size) * float(w.size[j])
		p.alpha = float(p.alpha) * float(w.weight[j])
		if j > 0:
			var spread := float(w.spread) * float(p.size)
			var lat := (rnd(seed, cycle, 10 + j) * 2.0 - 1.0) * spread
			var up := (rnd(seed, cycle, 20 + j) * 2.0 - 1.0) * spread * 0.6
			var pos: Vector3 = p.pos
			p.pos = Vector3(pos.x + side.x * lat, pos.y + up, pos.z + side.y * lat)
		out.append(p)
	return out


## The first `limit` puffs of a list (the farmer's first): the most shown at once (data "cap").
static func capped(list: Array[Dictionary], limit: int) -> Array[Dictionary]:
	return list.slice(0, maxi(limit, 0))


## Follows a figure from the last frame: its facing (a unit vector) and whether it moved. A
## given facing (a villager's, the farmer's) wins; otherwise it faces the way it last walked,
## south at first. `state` is the view's own dictionary, keyed by the figure's id.
static func track(state: Dictionary, id: String, cell: Vector2, given: Vector2) -> Dictionary:
	var s: Dictionary = state.get(id, {"at": cell, "dir": Vector2(0, 1)})
	var step: Vector2 = cell - (s.at as Vector2)
	var moving := step.length() > 0.0005
	var dir: Vector2 = s.dir
	if moving:
		dir = step.normalized()
	if given.length() > 0.001:
		dir = given.normalized()
	state[id] = {"at": cell, "dir": dir}
	return {"facing": dir, "moving": moving}


## The puffs of the figures now, at time `t` (seconds), strength 0..1 and wind 0..1. Each figure is
## {id, cell (Vector2), facing (Vector2, zero when unknown), kind, moving, running, tired, lift
## (cells up, optional), origin (the flat view's figure origin in px, optional)}; the moving flag
## and facing are filled in from `state` (track). Returns [{pos, alpha, size, color, stretch, u,
## id, origin?}] for the ones that show: a breath gives several sub-puffs (wisp).
static func puffs_now(figs: Array, state: Dictionary, t: float, strength: float, wind: float, cfg := {}) -> Array[Dictionary]:
	if cfg.is_empty():
		cfg = config()
	var out: Array[Dictionary] = []
	for f in figs:
		var id := str(f.id)
		var tr := track(state, id, f.cell, f.facing)
		var rate := rate_of(tr.moving or bool(f.get("moving", false)), bool(f.get("running", false)), bool(f.get("tired", false)), cfg)
		var ph := phase(seed_of(id), t, rate, strength, cfg)
		if ph.is_empty():
			continue
		var lift := float(f.get("lift", 0.0))   # a figure lifted standing in the ferry boat
		for p in wisp(f.cell, tr.facing, str(f.kind), float(ph.u), strength, wind, seed_of(id), int(ph.cycle), cfg):
			p.pos = (p.pos as Vector3) + Vector3(0, lift, 0)
			p["u"] = ph.u
			p["id"] = id
			if f.has("origin"):
				p["origin"] = f.origin
			out.append(p)
	return out


## The whole pixels of a flat puff `size_px` across, as offsets from its anchor: one pixel, a 2x2
## block, or a plus of five.
static func pixels(size_px: float) -> Array[Vector2i]:
	var n := roundi(size_px)
	if n <= 1:
		return [Vector2i.ZERO]
	if n == 2:
		return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]


## A steady pseudo-random number in 0..1 from three integers (the drift's, so everywhere the same).
static func rnd(a: int, b: int, c: int) -> float:
	return DriftRules.rnd(a, b, c)
