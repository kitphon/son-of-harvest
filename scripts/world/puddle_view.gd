class_name PuddleView
extends Node2D
## Puddles on the bare ground of an outdoor map in rain, in the flat view (rules: PuddleRules,
## data/puddles.json; the 3D view's is PuddleLayer): each a pixel ellipse of the dark wet tone
## with a darker rim and a lighter sky reflection on its upper rows, and while it rains small rain
## rings (redrawn `flat.rate` times a second, only then). Redrawn otherwise only when the wetness
## moves a step. Drawn over the ground, under everything else. Made with the map's view; none indoors.

const T := 16

var map: MapData
var farm: FarmGrid
var _places: Array[Dictionary] = []
var _step := -1
var _day_key := ""
var _rain := false
var _frame := -1
var _wet := 0.0
var _t := 0.0


func setup(m: MapData, f: FarmGrid = null) -> PuddleView:
	map = m
	farm = f
	name = "Puddles"
	_places = PuddleRules.puddles(m, f)
	_t = float(m.w * 13 + m.h * 7) * 0.31
	refresh()
	return self


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the weather and the clock.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if game == null:
		return
	var wet := PuddleRules.wetness_now(game, map)
	var step := PuddleRules.step_of(wet)
	var key := "%s|%d|%d" % [map.id, game.season, game.day]
	if key != _day_key:
		_day_key = key
		if farm != null:
			_places = PuddleRules.puddles(map, farm)
		_step = -1
	var rain := wet > 0.0 and PuddleRules.raining_now(game, map)
	var frame := floori(_t * float(PuddleRules.config().flat.rate)) if rain else -1
	if step != _step or rain != _rain or frame != _frame:
		_step = step
		_rain = rain
		_frame = frame
		_wet = float(step) / 50.0
		visible = not shown().is_empty()
		queue_redraw()


## The puddles showing now: [{p: the place, scale}].
func shown() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in _places:
		var s := PuddleRules.scale_of(p, _wet)
		if s > 0.0:
			out.append({"p": p, "scale": s})
	return out


## Are the rain rings drawing now (for tests)?
func raining() -> bool:
	return _rain


func _draw() -> void:
	var cfg := PuddleRules.config()
	var wet_c := Color(str(cfg.colors.wet))
	var sky_c := Color(str(cfg.colors.sky))
	var rim_c := Color(str(cfg.colors.rim))
	var ring_c := Color(str(cfg.colors.ring))
	var core_a := float(cfg.alpha.core)
	var rim_a := float(cfg.alpha.rim)
	var sky_a := float(cfg.alpha.sky)
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var style: Dictionary = game.dimple_style() if _rain and game != null else {}
	for e in shown():
		var p: Dictionary = e.p
		var s: float = e.scale
		var cx := (float(p.cell.x) + 0.5 + float(p.ox)) * T
		var cy := (float(p.cell.y) + 0.5 + float(p.oy)) * T
		var rx := maxf(float(p.rx) * T * s, 1.0)
		var ry := maxf(float(p.ry) * T * s, 1.0)
		for y in range(roundi(cy - ry), roundi(cy + ry)):
			var v := (float(y) + 0.5 - cy) / ry
			var half := rx * sqrt(maxf(1.0 - v * v, 0.0))
			var x0 := roundi(cx - half)
			var x1 := roundi(cx + half)
			if x1 <= x0:
				continue
			var edge := absf(v) > 0.78
			var col := rim_c if edge else wet_c
			col.a = rim_a if edge else core_a
			if not edge and v < -0.1:   # the far side holds the sky
				col = col.lerp(sky_c, sky_a * clampf(-v, 0.0, 1.0))
			draw_rect(Rect2(x0, y, x1 - x0, 1), col)
			if not edge:   # the row's two end pixels are the rim
				var side := rim_c
				side.a = rim_a
				draw_rect(Rect2(x0, y, 1, 1), side)
				draw_rect(Rect2(x1 - 1, y, 1, 1), side)
		if not style.is_empty():
			for d in PuddleRules.dimples(p, _t, style):
				var rr := roundi(maxf(float(d.ring) * float(cfg.dimple.ring) * rx, 0.5))
				var up := roundi(rr * 0.6)
				var at := Vector2(roundi(cx + d.pos.x * rx), roundi(cy + d.pos.y * ry))
				var col := ring_c
				col.a = 1.0 - float(d.ring)
				draw_rect(Rect2(at.x - rr, at.y, 1, 1), col)
				draw_rect(Rect2(at.x + rr, at.y, 1, 1), col)
				draw_rect(Rect2(at.x, at.y - up, 1, 1), col)
				draw_rect(Rect2(at.x, at.y + up, 1, 1), col)
