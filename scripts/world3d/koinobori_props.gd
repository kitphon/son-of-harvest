class_name KoinoboriProps
extends RefCounted
## The carp streamers in 3D (rules: KoinoboriRules, pictures: KoiArt, numbers: data/koinobori.json),
## a "koinobori" map prop: a small stone socket that stays all year, and on its days (Rig, shown
## by KoinoboriRules.up_now, checked each game minute) a tall bamboo pole with the spinning wheel
## on top, the five-colour streamer and the black, red and blue carp, each a billboard sprite
## hung by its mouth ring on the pole and drawn from the picture the wind picks (limp, half,
## full, and the tail's two frames), changing KoinoboriRules `rate` times a second. Heights are
## picture pixels (data/koinobori.json) at FarmWorld.PX a pixel times `scale_3d`: the whole rig
## (pictures, hang heights, pole and nodes) is drawn that much smaller than the flat view's 1:1, so
## the carp read as a real koinobori next to the village houses (a carp of about half a wall).

const NAME := "Koinobori"
const FRONT := 0.04   # the sprites stand this far in front of the pole (towards the camera)


## The 3D pixel size of the rig: FarmWorld.PX times data/koinobori.json `scale_3d`.
static func pixel() -> float:
	return FarmWorld.PX * float(KoinoboriRules.config().get("scale_3d", 1.0))


## Builds the prop `p` (its cell r) on `w`; returns the Rig.
static func build(w: FarmWorld, p: Dictionary, r: Rect2) -> Rig:
	var cfg := KoinoboriRules.config()
	var px := pixel()
	var mid := Vector3(r.get_center().x, 0, r.get_center().y)
	var stone := Color(str(cfg.pole.stone))
	w._box(Vector3(0.34, 0.14, 0.34), mid + Vector3(0, 0.07, 0), FarmWorld.flat_material(stone))
	w._box(Vector3(0.22, 0.06, 0.22), mid + Vector3(0, 0.17, 0), FarmWorld.flat_material(stone.lightened(0.08)))
	var rig := Rig.new()
	rig.name = NAME
	rig.prop = p
	rig.foot = mid
	rig.px = px
	w.add_child(rig)
	var h := float(cfg.pole.height) * px
	var bamboo := FarmWorld.flat_material(Color(str(cfg.pole.color)))
	var node_mat := FarmWorld.flat_material(Color(str(cfg.pole.node)))
	_part(rig, Vector3(0.06, h, 0.06), mid + Vector3(0, h / 2.0, 0), bamboo)
	var step := 0.62 * (px / FarmWorld.PX)
	for k in int(h / step):
		_part(rig, Vector3(0.085, 0.03, 0.085), mid + Vector3(0, 0.3 + step * k, 0), node_mat)
	rig.add_hung("wheel", float(cfg.wheel.y), 0.0, Vector2i((KoiArt.WHEEL_SIZE - 1) / 2, (KoiArt.WHEEL_SIZE - 1) / 2), Vector2i(KoiArt.WHEEL_SIZE, KoiArt.WHEEL_SIZE))
	var s: Dictionary = cfg.streamer
	var sp := KoiArt.pad(float(s.radius))
	var ss := KoiArt.size_of(float(s.length), float(s.radius))
	rig.add_hung("stream", float(s.y), 1.7, Vector2i(sp, sp), Vector2i(ss, ss))
	var i := 0
	for c: Dictionary in cfg.carp:
		var cp := KoiArt.pad(float(c.radius))
		var cs := KoiArt.size_of(float(c.length), float(c.radius))
		rig.add_hung(str(c.id), float(c.y), 0.9 + 1.3 * i, Vector2i(cp, cp), Vector2i(cs, cs))
		i += 1
	rig.refresh()
	rig.pose(0.0)
	return rig


static func _part(rig: Node3D, size: Vector3, at: Vector3, mat: Material) -> void:
	var box := BoxMesh.new()
	box.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.material_override = mat
	mi.position = at
	rig.add_child(mi)


## The pole, wheel, streamer and carp of one prop: shown only while the pole is up.
class Rig extends Node3D:
	var prop: Dictionary = {}
	var foot := Vector3.ZERO
	var px := FarmWorld.PX   # the 3D pixel size (KoinoboriProps.pixel)
	var _things: Array[Dictionary] = []   # {id, sprite, phase, key}
	var _t := 0.0
	var _turns := 0.0
	var _frame := -1
	var wind := 0.0

	func _ready() -> void:
		var game := (Engine.get_main_loop() as SceneTree).root.get_node("Game")
		game.minute_passed.connect(refresh)
		game.day_started.connect(refresh)
		refresh()

	## A hung picture (`id`: wheel, stream, black, red, blue): its anchor pixel `anchor` of a `size` picture
	## sits `y_px` pixels up the pole, on its front (both at `px` a pixel).
	func add_hung(id: String, y_px: float, phase: float, anchor: Vector2i, size: Vector2i) -> void:
		var s := FarmWorld.make_sprite(PlaceholderArt.tex(KoinoboriRules.art_key(id, 0, 0)))
		s.pixel_size = px
		s.offset = Vector2(size.x / 2.0 - anchor.x - 0.5, anchor.y + 0.5 - size.y / 2.0)
		s.position = foot + Vector3(0, y_px * px, KoinoboriProps.FRONT)
		add_child(s)
		_things.append({"id": id, "sprite": s, "phase": phase, "key": ""})

	## Shown while the pole is up; reads today's wind.
	func refresh() -> void:
		var game := (Engine.get_main_loop() as SceneTree).root.get_node("Game")
		visible = KoinoboriRules.up_now(prop, game)
		wind = KoinoboriRules.wind_now(game)

	func is_up() -> bool:
		return visible

	## The picture keys the things show now, by id.
	func keys() -> Dictionary:
		var out := {}
		for th in _things:
			out[th.id] = th.key
		return out

	func sprites() -> Array[Sprite3D]:
		var out: Array[Sprite3D] = []
		for th in _things:
			out.append(th.sprite)
		return out

	func _process(delta: float) -> void:
		if visible:
			pose(_t + delta)

	## Sets every picture for time `t` (s): changes only when the frame of the picture `rate` makes changes.
	func pose(t: float) -> void:
		var cfg := KoinoboriRules.config()
		_turns += maxf(t - _t, 0.0) * KoinoboriRules.wheel_speed(KoinoboriRules.effective(wind, t, 0.0, cfg), cfg)
		_t = t
		var f := int(floor(t * float(cfg.rate)))
		if f == _frame:
			return
		_frame = f
		for th in _things:
			var key: String
			if th.id == "wheel":
				key = KoinoboriRules.art_key("wheel", 0, KoinoboriRules.wheel_frame(_turns, cfg))
			else:
				var c := KoinoboriRules.carp(wind, t, float(th.phase), cfg)
				key = KoinoboriRules.art_key(str(th.id), int(c.level), int(c.frame))
			if key != th.key:
				th.key = key
				(th.sprite as Sprite3D).texture = PlaceholderArt.tex(key)
