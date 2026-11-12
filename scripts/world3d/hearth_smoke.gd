class_name HearthSmoke
extends Node3D
## Hearth smoke: a few thin pale puffs rising from a roof's vent at meal times (data/smoke.json),
## the same idea as StallWares.Steam but larger and slower. Only outdoor maps build them: the
## farmhouse (FarmWorld) and the village houses (MapWorld). The clock decides when they show
## (the `windows`, fading in and out at each end); the world's wind leans them (FarmWorld.wind,
## so a gale leans them more); a weather look in `hide_in` buries them. Lit, no shadow.
## While its own house is see-through (Occluders: the house stands in front of the farmer) the
## smoke fades with it, down to `faded_keep` of its opacity, so no smoke hangs in the air over
## a roof that is barely there. The puffs are smooth (`sides` round, `rings` high), so a
## near one reads as soft smoke, not a faceted stone.

const DATA_PATH := SmokeRules.DATA_PATH
const OVERHANG := SmokeRules.OVERHANG
const PITCH := SmokeRules.PITCH
const WALL_LOW := SmokeRules.WALL_LOW
const RIDGE_LIFT := SmokeRules.RIDGE_LIFT

var _sd := 0
var _t := 0.0
var _wind := 0.0
var _strength := 0.0
var _house := 1.0   # the opacity share left by the house's see-through fade (SmokeRules.house_keep)
var _rgb := Color.WHITE
var _puffs: Array[MeshInstance3D] = []


## data/smoke.json (read once); SmokeRules keeps the rules both views share.
static func config() -> Dictionary:
	return SmokeRules.config()


static func strength_at(hour: float, cfg := {}) -> float:
	return SmokeRules.strength_at(hour, cfg)


static func vent_at(eave: Rect2, low: float, pitch: float, hip: bool) -> Vector3:
	return SmokeRules.vent_at(eave, low, pitch, hip)


static func village_vent(r: Rect2, style: Dictionary) -> Vector3:
	return SmokeRules.village_vent(r, style)


func _init(sd := 0, at := Vector3.ZERO) -> void:
	_sd = sd
	position = at
	var cfg := config()
	_rgb = Color(str(cfg.color))
	var mesh := puff_mesh(cfg)
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
	_t = SmokeRules.start_time(sd, cfg)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## A soft blob of radius 1 (scaled per puff), fat in the middle and rounded at both ends, with
## smooth normals: `sides` round and `rings` high (data/smoke.json).
static func puff_mesh(cfg := {}) -> Mesh:
	if cfg.is_empty():
		cfg = config()
	var m := SphereMesh.new()
	m.radius = 1.0
	m.height = 1.1
	m.radial_segments = int(cfg.sides)
	m.rings = int(cfg.rings)
	return m


## Reads the clock, the weather and the wind, then shows or hides the smoke and places the puffs.
func refresh() -> void:
	var cfg := config()
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if game == null:   # no clock (a bare script run): no smoke
		_strength = 0.0
		visible = false
		return
	var world := get_parent() as FarmWorld
	_wind = world.wind if world != null else 0.0
	_strength = SmokeRules.strength_now(game, cfg)
	_house = SmokeRules.house_keep(world.occluders.fade_at(position) if world != null else 0.0, Occluders.FADED, cfg)
	visible = _strength > 0.0
	if visible:
		_place(cfg)


## Puff `k` at its point of the rise: up from the vent, leaning with the wind, larger as it
## goes, fading in then out; the puffs are out of step with each other.
func _place(cfg: Dictionary) -> void:
	var n := _puffs.size()
	var wobble := float(cfg.wobble)
	for k in n:
		var q := SmokeRules.puff(_t, k, n, _sd, _wind, cfg)
		var mi := _puffs[k]
		mi.position = Vector3(float(q.lean) * float(cfg.lean) + float(q.sx) * wobble, float(q.u) * float(cfg.rise) + 0.15 * mi.scale.y, float(q.sz) * wobble * 0.5)
		mi.scale = Vector3.ONE * float(cfg.size) * float(q.grow)
		var m := mi.material_override as StandardMaterial3D
		m.albedo_color = Color(_rgb, float(cfg.alpha) * float(q.alpha) * _strength * _house)


## How strong the smoke is now, 0..1 (for tests and the clock's ease).
func strength() -> float:
	return _strength


## The share of the smoke's opacity its house's see-through fade leaves now (1 when the house
## is solid; for tests).
func house_keep() -> float:
	return _house


## The puffs, one mesh each (for tests).
func puff_count() -> int:
	return _puffs.size()
