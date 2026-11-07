class_name SmokeView
extends Node2D
## Hearth smoke in the flat view (rules: SmokeRules, data/smoke.json; the 3D view's is
## HearthSmoke): a few pale pixel puffs climbing from each roof's vent at meal times, easing in
## and out with the clock, leaning with the wind (Game.wind_strength) and buried by a storm. The
## vents are the 3D view's (SmokeRules.farm_vent / village_vents), taken from above: x / z in
## cells. Made with the map's view; outdoor maps only, so an indoor map gets none.

const T := 16

var vents: Array[Vector2] = []   # in pixels
var _t: Array[float] = []        # each smoke's own time into its rise
var _strength := 0.0
var _wind := 0.0
var _rgb := Color.WHITE


## The farmhouse's vent (`on_farm`) or every village house's in `props`; none when `indoor`.
func setup(props: Array, on_farm: bool, indoor := false) -> SmokeView:
	var cfg := SmokeRules.config()
	_rgb = Color(str(cfg.color))
	var at: Array[Vector3] = []
	if on_farm:
		at.append(SmokeRules.farm_vent())
	elif not indoor:
		at = SmokeRules.village_vents(props)
	for v in at:
		vents.append(Vector2(v.x, v.z) * T)
		_t.append(SmokeRules.start_time(int(v.x) * 7 + int(v.z) * 13, cfg))
	refresh()
	return self


func _process(delta: float) -> void:
	for i in _t.size():
		_t[i] += delta
	refresh()


## Reads the clock, the weather and the wind, then shows or hides the smoke.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	_strength = SmokeRules.strength_now(game) if not vents.is_empty() else 0.0
	_wind = game.wind_strength() if game != null else 0.0
	visible = _strength > 0.0
	if visible:
		queue_redraw()


func strength() -> float:
	return _strength


## Every puff now, as {pos: its centre in pixels, width: in pixels, alpha}; none when there is no smoke.
func puffs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _strength <= 0.0:
		return out
	var cfg := SmokeRules.config()
	var flat: Dictionary = cfg.flat
	var n := int(cfg.puffs)
	for i in vents.size():
		for k in n:
			var q := SmokeRules.puff(_t[i], k, n, i, _wind, cfg)
			var pos := vents[i] + Vector2(
				float(q.lean) * float(flat.lean_px) + float(q.sx) * float(flat.wobble_px),
				-float(q.u) * float(flat.rise_px) + float(q.sz) * float(flat.wobble_px) * 0.5)
			out.append({
				"pos": pos.round(),   # pixel art: on whole pixels
				"width": maxi(int(round(float(flat.size_px) * float(q.grow))), 2),
				"alpha": float(flat.alpha) * float(q.alpha) * _strength,
			})
	return out


func _draw() -> void:
	for p in puffs():
		var c := _rgb
		c.a = p.alpha
		var w: int = p.width
		var o: Vector2 = p.pos - Vector2(w, w) / 2.0
		# A rounded pixel blob: the square with its corners taken off.
		draw_rect(Rect2(o + Vector2(0, 1), Vector2(w, w - 2)), c)
		draw_rect(Rect2(o + Vector2(1, 0), Vector2(w - 2, 1)), c)
		draw_rect(Rect2(o + Vector2(1, w - 1), Vector2(w - 2, 1)), c)
