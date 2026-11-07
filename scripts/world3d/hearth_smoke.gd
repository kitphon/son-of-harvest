class_name HearthSmoke
extends Node3D
## Hearth smoke: a few thin pale puffs rising from a roof's vent at meal times (data/smoke.json),
## the same idea as StallWares.Steam but larger and slower. Only outdoor maps build them: the
## farmhouse (FarmWorld) and the village houses (MapWorld). The clock decides when they show
## (the `windows`, fading in and out at each end); the world's wind leans them (FarmWorld.wind,
## so a gale leans them more); a weather look in `hide_in` buries them. Lit, no shadow.

const DATA_PATH := "res://data/smoke.json"
## The village roofs' eave overhang and pitch, and the soffit height at the front eave, as
## MapWorld._village_house builds them (copied here, so the vent sits on that ridge).
const OVERHANG := 0.35
const PITCH := 0.5
const WALL_LOW := 1.45
## The vent sits a little over the ridge tiles.
const RIDGE_LIFT := 0.04

static var _cfg: Dictionary = {}

var _sd := 0
var _t := 0.0
var _wind := 0.0
var _strength := 0.0
var _rgb := Color.WHITE
var _puffs: Array[MeshInstance3D] = []


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


## Where smoke leaves a roof: over the middle of `eave` (x / z of its outer edge) at the ridge
## height. Its soffit is `low` at the eaves, rising `pitch` per unit run; a hip roof's ridge
## is half its shorter side up, a roof whose ridge runs along x is half its depth (z) up.
static func vent_at(eave: Rect2, low: float, pitch: float, hip: bool) -> Vector3:
	var half := minf(eave.size.x, eave.size.y) / 2.0 if hip else eave.size.y / 2.0
	var c := eave.get_center()
	return Vector3(c.x, low + half * pitch + RIDGE_LIFT, c.y)


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


func _init(sd := 0, at := Vector3.ZERO) -> void:
	_sd = sd
	position = at
	var cfg := config()
	_rgb = Color(str(cfg.color))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A soft blob of radius 1 (scaled per puff): fat in the middle, rounded at both ends.
	Shrine.lathe(st, Vector3.ZERO, [Vector2(0.55, -0.4), Vector2(1.0, -0.1), Vector2(1.0, 0.3), Vector2(0.6, 0.6), Vector2(0.0, 0.7)], 7)
	var mesh := st.commit()
	for k in int(cfg.puffs):
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(_rgb, 0.0)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_puffs.append(mi)
	_t = float(sd % 97) / 97.0 * float(cfg.period)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock, the weather and the wind, then shows or hides the smoke and places the puffs.
func refresh() -> void:
	var cfg := config()
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if game == null:   # no clock (a bare script run): no smoke
		_strength = 0.0
		visible = false
		return
	var hour := float(game.hour) + float(game.minute) / 60.0
	var look: String = game.weather_look(game.weather_today, game.season_name())
	var world := get_parent() as FarmWorld
	_wind = world.wind if world != null else 0.0
	_strength = 0.0 if look in cfg.hide_in else strength_at(hour, cfg)
	visible = _strength > 0.0
	if visible:
		_place(cfg)


## Puff `k` at its point of the rise: up from the vent, leaning with the wind, larger as it
## goes, fading in then out; the puffs are out of step with each other.
func _place(cfg: Dictionary) -> void:
	var n := _puffs.size()
	var period := float(cfg.period)
	var wobble := float(cfg.wobble)
	for k in n:
		var u := fposmod(_t / period + float(k) / n, 1.0)
		var mi := _puffs[k]
		var lean := u * u * float(cfg.lean) * (0.3 + _wind)
		mi.position = Vector3(lean + sin(u * 5.0 + k * 2.1 + float(_sd)) * wobble, u * float(cfg.rise), cos(u * 4.0 + k) * wobble * 0.5)
		mi.scale = Vector3.ONE * float(cfg.size) * (1.0 + (float(cfg.grow) - 1.0) * u)
		var m := mi.material_override as StandardMaterial3D
		m.albedo_color = Color(_rgb, float(cfg.alpha) * sin(PI * u) * _strength)


## How strong the smoke is now, 0..1 (for tests and the clock's ease).
func strength() -> float:
	return _strength


## The puffs, one mesh each (for tests).
func puff_count() -> int:
	return _puffs.size()
