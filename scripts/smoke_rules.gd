class_name SmokeRules
extends RefCounted
## The hearth smoke's rules both views share (data/smoke.json): the meal windows and their fade,
## the weather that buries it, where a roof's vent is, and how far along its rise a puff is (its
## lean, sway, growth and opacity as plain fractions). The 3D view (HearthSmoke) scales them in
## world units, the flat view (SmokeView) in pixels. Pure: nothing here draws.

const DATA_PATH := "res://data/smoke.json"
## The village roofs' eave overhang and pitch, and the soffit height at the front eave, as
## MapWorld._village_house builds them (copied here, so the vent sits on that ridge).
const OVERHANG := 0.35
const PITCH := 0.5
const WALL_LOW := 1.45
## The vent sits a little over the ridge tiles.
const RIDGE_LIFT := 0.04
## The farmhouse's roof (FarmWorld._house_body): eave rectangle, soffit height, pitch.
const FARM_EAVE := Rect2(1.45, 0.55, 6.1, 3.5)
const FARM_LOW := 1.45
const FARM_PITCH := 1.25

static var _cfg: Dictionary = {}


## data/smoke.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## How strong the smoke is at `hour` (a float on the game clock, 0..24): 0 outside the windows,
## 1 inside them, eased in and out over `fade_hours` at each end.
static func strength_at(hour: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var fade := maxf(float(cfg.fade_hours), 0.001)
	var best := 0.0
	for w in cfg.windows:
		var a := float(w[0])
		var b := float(w[1])
		if hour < a or hour > b:
			continue
		var s := clampf(minf((hour - a) / fade, (b - hour) / fade), 0.0, 1.0)
		best = maxf(best, s * s * (3.0 - 2.0 * s))
	return best


## The smoke's strength now: the clock of `game` (the Game autoload), 0 when its weather look is
## one of `hide_in` (a storm) or when there is no clock.
static func strength_now(game: Object, cfg := {}) -> float:
	if game == null:
		return 0.0
	if cfg.is_empty():
		cfg = config()
	var look: String = game.weather_look(game.weather_today, game.season_name())
	if look in cfg.hide_in:
		return 0.0
	return strength_at(float(game.hour) + float(game.minute) / 60.0, cfg)


## Where smoke leaves a roof: over the middle of `eave` (x / z of its outer edge) at the ridge
## height. Its soffit is `low` at the eaves, rising `pitch` per unit run; a hip roof's ridge
## is half its shorter side up, a roof whose ridge runs along x is half its depth (z) up.
static func vent_at(eave: Rect2, low: float, pitch: float, hip: bool) -> Vector3:
	var half := minf(eave.size.x, eave.size.y) / 2.0 if hip else eave.size.y / 2.0
	var c := eave.get_center()
	return Vector3(c.x, low + half * pitch + RIDGE_LIFT, c.y)


## The farmhouse's vent.
static func farm_vent() -> Vector3:
	return vent_at(FARM_EAVE, FARM_LOW, FARM_PITCH, false)


## The vent of a village house over footprint `r` with `style` (LitSpots.village_style), built
## as MapWorld._village_house builds its roof: the walls and roof of the upper storey when it
## has two.
static func village_vent(r: Rect2, style: Dictionary) -> Vector3:
	var back := r.position.y + 0.1
	var front := LitSpots.village_front(r)
	var cx := r.get_center().x
	var wide := r.size.x - 0.2
	var body := Rect2(cx - wide / 2.0, back, wide, front - back)
	var wall := WALL_LOW + OVERHANG * PITCH
	if int(style.get("storeys", 1)) >= 2:
		body = body.grow(-LitSpots.UPPER_INSET)
		wall = LitSpots.UPPER_TOP
	var hip := str(style.get("roof", "gable")) == "hip"
	var eave := body.grow(OVERHANG) if hip else Rect2(body.position.x - 0.25, body.position.y - OVERHANG, body.size.x + 0.5, body.size.y + OVERHANG * 2.0)
	return vent_at(eave, wall - OVERHANG * PITCH, PITCH, hip)


## The vents (x / z in map units, y the ridge height) of every village house in `props`.
static func village_vents(props: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for p in props:
		if str(p.kind) != "village_house":
			continue
		out.append(village_vent(Rect2(Vector2(p.cell), Vector2(p.size)), LitSpots.village_style(p)))
	return out


## A starting offset (seconds into a rise) for a smoke with seed `sd`, so neighbours are out of step.
static func start_time(sd: int, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	return float(sd % 97) / 97.0 * float(cfg.period)


## Puff `k` of `n` at time `t` (seconds) in a wind of 0..1, for smoke seed `sd`: how far along
## its rise `u` (0..1), the sideways drift `lean` and the wobble `sx` / `sz` (fractions: the
## caller multiplies by its own lean and wobble), `grow` (the size factor, 1 at the start) and
## `alpha` (0..1 of the strongest opacity, before the strength).
static func puff(t: float, k: int, n: int, sd: int, wind: float, cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var u := fposmod(t / float(cfg.period) + float(k) / n, 1.0)
	return {
		"u": u,
		"lean": u * u * (0.3 + wind),
		"sx": sin(u * 5.0 + k * 2.1 + float(sd)),
		"sz": cos(u * 4.0 + k),
		"grow": 1.0 + (float(cfg.grow) - 1.0) * u,
		"alpha": sin(PI * u),
	}
