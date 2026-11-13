class_name KoinoboriView
extends Node2D
## The carp streamers in the flat view (rules: KoinoboriRules, pictures: KoiArt; the 3D view's is
## KoinoboriProps): for each "koinobori" prop its stone socket all year and, while the pole is up
## (KoinoboriRules.up_now, read each game minute), the bamboo pole, the wheel, the streamer and
## the three carp, the same pictures the 3D view hangs, drawn whole-pixel from the pole's foot at
## the middle of its cell (a point (x, y up, z) of the 3D prop shows at (x, z - y) cells). They
## change KoinoboriRules `rate` times a second (data/koinobori.json), the view redrawing only
## then. MapView leaves these props out of its boxes.

const T := 16

var map: MapData
var _props: Array[Dictionary] = []
var _t := 0.0
var _turns := 0.0
var _frame := -1
var _wind := 0.0
var _up := false
var _keys := {}   # id -> the picture key shown now


func _init(m: MapData) -> void:
	map = m
	name = "Koinobori"
	for p in m.props:
		if p.kind == KoinoboriRules.KIND:
			_props.append(p)


func _ready() -> void:
	add_to_group(FlatLight.GROUP)   # the pictures take the world's light (redrawn when it changes)
	var game := (Engine.get_main_loop() as SceneTree).root.get_node("Game")
	game.minute_passed.connect(refresh)
	game.day_started.connect(refresh)
	refresh()


func has_props() -> bool:
	return not _props.is_empty()


## Is the pole up now (on the first prop)?
func pole_up() -> bool:
	return _up


## The picture key of each hung thing as drawn now, by id (wheel, stream, black, red, blue).
func keys() -> Dictionary:
	return _keys


## Reads the clock, today's weather and the wind.
func refresh() -> void:
	if _props.is_empty():
		return
	var game := (Engine.get_main_loop() as SceneTree).root.get_node("Game")
	_up = KoinoboriRules.up_now(_props[0], game)
	_wind = KoinoboriRules.wind_now(game)
	_pose(_t)
	queue_redraw()


func _process(delta: float) -> void:
	if _props.is_empty() or not _up:
		return
	_pose(_t + delta)


## The pictures for time `t` (s); redraws only when the frame `rate` makes changes.
func _pose(t: float) -> void:
	var cfg := KoinoboriRules.config()
	_turns += maxf(t - _t, 0.0) * KoinoboriRules.wheel_speed(KoinoboriRules.effective(_wind, t, 0.0, cfg), cfg)
	_t = t
	var f := int(floor(t * float(cfg.rate)))
	if f == _frame and not _keys.is_empty():
		return
	_frame = f
	var keys := {}
	keys["wheel"] = KoinoboriRules.art_key("wheel", 0, KoinoboriRules.wheel_frame(_turns, cfg))
	for th in _things(cfg):
		var c := KoinoboriRules.carp(_wind, t, float(th.phase), cfg)
		keys[th.id] = KoinoboriRules.art_key(str(th.id), int(c.level), int(c.frame))
	if keys != _keys:
		_keys = keys
		queue_redraw()


## The hung things below the wheel: {id, y (px up the pole), phase, pad, size}, the streamer first.
static func _things(cfg: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var s: Dictionary = cfg.streamer
	out.append({"id": "stream", "y": float(s.y), "phase": 1.7, "pad": KoiArt.pad(float(s.radius))})
	var i := 0
	for c: Dictionary in cfg.carp:
		out.append({"id": str(c.id), "y": float(c.y), "phase": 0.9 + 1.3 * i, "pad": KoiArt.pad(float(c.radius))})
		i += 1
	return out


func _draw() -> void:
	var cfg := KoinoboriRules.config()
	for p in _props:
		var foot := Vector2((p.cell.x + 0.5) * T, (p.cell.y + 0.5) * T)
		var stone := Color(str(cfg.pole.stone))
		draw_rect(Rect2(foot.x - 3, foot.y - 2, 6, 3), stone.darkened(0.25))
		draw_rect(Rect2(foot.x - 3, foot.y - 3, 6, 2), stone)
		draw_rect(Rect2(foot.x - 2, foot.y - 4, 4, 1), stone.lightened(0.1))
		if _up:
			_draw_pole(foot, cfg)


func _draw_pole(foot: Vector2, cfg: Dictionary) -> void:
	var h := float(cfg.pole.height)
	var light := FlatLight.at_mid(Vector3(foot.x / T, h / 2.0 / T, foot.y / T))
	var bamboo := Color(str(cfg.pole.color)) * light
	var knot := Color(str(cfg.pole.node)) * light
	var x := floorf(foot.x) - 1
	draw_rect(Rect2(x, foot.y - 4 - h, 2, h), bamboo)
	draw_rect(Rect2(x, foot.y - 4 - h, 1, h), bamboo.lightened(0.12))   # the lit edge
	var k := 9.0
	while k < h:
		draw_rect(Rect2(x - 1, foot.y - 4 - k, 4, 1), knot)
		k += 10.0
	# the hung things, the wheel on top, the streamer and the carp over the pole
	_draw_picture("wheel", foot, float(cfg.wheel.y), Vector2i((KoiArt.WHEEL_SIZE - 1) / 2, (KoiArt.WHEEL_SIZE - 1) / 2))
	for th in _things(cfg):
		_draw_picture(str(th.id), foot, float(th.y), Vector2i(int(th.pad), int(th.pad)))


## Picture `id` with its anchor pixel `anchor` `y_px` pixels up the pole at `foot`.
func _draw_picture(id: String, foot: Vector2, y_px: float, anchor: Vector2i) -> void:
	if not _keys.has(id):
		return
	var tex := PlaceholderArt.tex(str(_keys[id]))
	var at := Vector2(floorf(foot.x) - anchor.x, foot.y - 4 - y_px - anchor.y)
	var light := FlatLight.at_mid(Vector3(foot.x / T, y_px / T, foot.y / T))
	draw_texture(tex, at, light)
