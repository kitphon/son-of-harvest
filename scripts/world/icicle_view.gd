class_name IcicleView
extends Node2D
## Icicles under the painted roofs in the flat view (IcicleRules, data/icicles.json; the 3D
## view's is IcicleLayer): whole-pixel strips 1 or 2 px wide hanging from the row under each
## roof picture's bottom eave (the farm's farmhouse, coop and barn: FarmView.roof_rect; a map's
## village houses: their roof picture, the prop's box less a pixel all round, as MapView draws
## it), clear of the doors drawn on the roofs' front rows. The lit left pixel paler, the shaded
## right one bluer, the point see-through; while they drip a drop pixel falls from some of the
## points (redrawn `flat.drip_rate` times a second, only then). Redrawn otherwise only when the
## length moves a step. Made with the map's view; nothing hangs indoors or in the mine.

const T := 16
const DROP_FALL := 6   # pixels a drop falls before it is gone

var map: MapData
var farm: FarmGrid
var _spots: Array[Dictionary] = []
var _step := -1
var _drip := false
var _frame := -1
var _amount := 0.0
var _t := 0.0


func setup(m: MapData, f: FarmGrid = null) -> IcicleView:
	map = m
	farm = f
	name = "Icicles"
	_spots = spots_for(m, f)
	_t = float(m.w * 11 + m.h * 5) * 0.37
	refresh()
	return self


## Where the icicles hang on map `m` (the farm's buildings when `f` is the farm's grid).
static func spots_for(m: MapData, f: FarmGrid = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not IcicleRules.outdoors(m):
		return out
	var cfg := IcicleRules.config()
	if f != null:
		for kind: String in FarmView.ROOFS:
			var r := FarmView.roof_rect(f, kind)
			if not r.has_area():
				continue
			var bare: Array = []
			var row := int(r.end.y) / T - 1
			for x in range(int(r.position.x) / T, int(r.end.x) / T):
				if f.fixed_at(Vector2i(x, row)) != kind:   # a door drawn on the roof's front row
					bare.append(Vector2i(x * T, x * T + T))
			out.append_array(IcicleRules.flat_spots(int(r.position.x), int(r.end.x), int(r.end.y), bare, cfg))
		return out
	for p in m.props:
		if str(p.kind) != "village_house":
			continue
		var inner := Rect2(Vector2(p.cell * T), Vector2(p.size * T)).grow(-1)
		var front := int(p.cell.y) + int(p.size.y) - 1
		var bare: Array = []
		for door in m.doors:
			for c: Vector2i in door.cells:
				if c.y == front and c.x >= int(p.cell.x) and c.x < int(p.cell.x) + int(p.size.x):
					bare.append(Vector2i(c.x * T + 2, c.x * T + T - 2))
		out.append_array(IcicleRules.flat_spots(int(inner.position.x), int(inner.end.x), int(inner.end.y), bare, cfg))
	return out


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the season, the snow, the weather and the clock.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if game == null:
		return
	var cfg := IcicleRules.config()
	var a := IcicleRules.amount_now(game, map, cfg)
	var step := IcicleRules.step_of(a, cfg)
	var drip := IcicleRules.dripping_now(game, map, cfg)
	var frame := floori(_t * float(cfg.flat.drip_rate)) if drip else -1
	if step != _step or drip != _drip or frame != _frame:
		_step = step
		_drip = drip
		_frame = frame
		_amount = float(step) * float(cfg.step)
		visible = not shown().is_empty()
		queue_redraw()


## The icicles showing now: [{s: the spot, len: pixels}].
func shown() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cfg := IcicleRules.config()
	for s in _spots:
		var l := IcicleRules.flat_len(s, _amount, cfg)
		if l > 0:
			out.append({"s": s, "len": l})
	return out


## Are drops falling now (for tests)?
func dripping() -> bool:
	return _drip


func _draw() -> void:
	var cfg := IcicleRules.config()
	var col: Dictionary = cfg.colors
	var ice := Color(str(col.ice))
	var core := Color(str(col.flat_core))
	var rim := Color(str(col.flat_rim))
	var tip := Color(str(col.tip))
	var drop := Color(str(col.drop))
	ice.a = float(cfg.alpha.flat)
	core.a = float(cfg.alpha.flat)
	rim.a = float(cfg.alpha.flat)
	tip.a = float(cfg.alpha.flat_tip)
	drop.a = 0.85
	for it in shown():
		var s: Dictionary = it.s
		var l: int = it.len
		var x := float(s.x)
		var y := float(s.y)
		# The top row two pixels, the lit one left, the shaded one right (a wide one for half its
		# length), then one pixel down to a see-through point.
		draw_rect(Rect2(x + 1, y, 1, maxi(1, l / 2) if s.wide else 1), rim)
		draw_rect(Rect2(x, y, 1, 1), ice)
		if l > 2:
			draw_rect(Rect2(x, y + 1, 1, l - 2), ice if s.wide else core)
		if l > 1:
			draw_rect(Rect2(x, y + l - 1, 1, 1), tip)
		if _drip and s.drip:
			var period := IcicleRules.drip_period(float(s.seed), cfg)
			var k := floori(fposmod(_t / period + float(s.seed), 1.0) * DROP_FALL)
			draw_rect(Rect2(x, y + l + 1 + k, 1, 1), drop)
