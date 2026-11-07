class_name HearthSmoke
extends Node3D
## Hearth smoke: a few thin pale puffs rising from a roof's vent at meal times (data/smoke.json),
## the same idea as StallWares.Steam but larger and slower. Only outdoor maps build them: the
## farmhouse (FarmWorld) and the village houses (MapWorld). The clock decides when they show
## (the `windows`, fading in and out at each end); the world's wind leans them (FarmWorld.wind,
## so a gale leans them more); a weather look in `hide_in` buries them. Lit, no shadow.

const DATA_PATH := SmokeRules.DATA_PATH
const OVERHANG := SmokeRules.OVERHANG
const PITCH := SmokeRules.PITCH
const WALL_LOW := SmokeRules.WALL_LOW
const RIDGE_LIFT := SmokeRules.RIDGE_LIFT

var _sd := 0
var _t := 0.0
var _wind := 0.0
var _strength := 0.0
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
	_t = SmokeRules.start_time(sd, cfg)
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
	var world := get_parent() as FarmWorld
	_wind = world.wind if world != null else 0.0
	_strength = SmokeRules.strength_now(game, cfg)
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
		mi.position = Vector3(float(q.lean) * float(cfg.lean) + float(q.sx) * wobble, float(q.u) * float(cfg.rise), float(q.sz) * wobble * 0.5)
		mi.scale = Vector3.ONE * float(cfg.size) * float(q.grow)
		var m := mi.material_override as StandardMaterial3D
		m.albedo_color = Color(_rgb, float(cfg.alpha) * float(q.alpha) * _strength)


## How strong the smoke is now, 0..1 (for tests and the clock's ease).
func strength() -> float:
	return _strength


## The puffs, one mesh each (for tests).
func puff_count() -> int:
	return _puffs.size()
