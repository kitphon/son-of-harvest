class_name DriftView
extends Node2D
## Seasonal life drifting through an outdoor map in the flat view (rules: DriftRules,
## data/drift.json; the 3D view's is DriftLayer and DriftGlow): single-pixel cherry petals and
## maple leaves falling on the wind (Game.wind_strength) and, on summer nights, fireflies that
## blink. Seen from above, a mote's height lifts it up the screen (data "flat".height_px), on
## whole pixels. Fireflies are drawn added, their colour divided by the scene's night tint
## (`tint`, a CanvasModulate) as NightView does, so they land on the tinted picture as they
## are. Made with the map's view; indoor maps and the mine get nothing.

const T := 16

var map: MapData
var farm: FarmGrid
var tint: CanvasModulate
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _wind := 0.0
var _amounts := {}
var _glow: Node2D


func setup(m: MapData, f: FarmGrid = null) -> DriftView:
	map = m
	farm = f
	name = "Drift"
	_t = float(m.w * 31 + m.h * 17) * 0.37
	_glow = Node2D.new()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	refresh()
	return self


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock, the weather and the wind.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	_amounts = DriftRules.amounts_now(game, map)
	visible = not _amounts.is_empty()
	if not visible:
		return
	_wind = game.wind_strength()
	var key := "%s|%d|%d" % [map.id, game.season, game.day]
	if key != _scene_key:
		_scene_key = key
		_scene = DriftRules.scene_of(map, farm, DriftRules.festival_props_today(game, map))
	queue_redraw()
	_glow.queue_redraw()


## Where a mote is on the screen, in whole pixels.
func screen_of(pos: Vector3) -> Vector2:
	return (Vector2(pos.x, pos.z) * T - Vector2(0, pos.y * float(DriftRules.config().flat.height_px))).round()


## The petals and leaves now: [{at: pixel, wide: pixels, color}] (alpha in the colour).
func specks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for kind in ["petal", "leaf"]:
		if not _amounts.has(kind):
			continue
		for m in DriftRules.motes(kind, float(_amounts[kind]), _t, _wind, _scene):
			var c: Color = m.color
			c.a = float(m.alpha)
			out.append({"at": screen_of(m.pos), "wide": 2 if kind == "leaf" else 1, "color": c})
	return out


## The fireflies now: [{at: pixel, alpha, color}].
func flies() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _amounts.has("firefly"):
		for m in DriftRules.motes("firefly", float(_amounts.firefly), _t, _wind, _scene):
			out.append({"at": screen_of(m.pos), "alpha": float(m.alpha), "color": m.color})
	return out


func _draw() -> void:
	for s in specks():
		draw_rect(Rect2(s.at, Vector2(s.wide, 1)), s.color)


func _draw_glow() -> void:
	var tc := tint.color if tint != null else Color.WHITE
	var halo := float(DriftRules.config().flat.halo)
	for f in flies():
		var a: float = f.alpha
		if a < 0.05:
			continue
		var c: Color = f.color
		var col := Color(c.r / maxf(tc.r, 0.05), c.g / maxf(tc.g, 0.05), c.b / maxf(tc.b, 0.05), a)
		_glow.draw_rect(Rect2(f.at, Vector2.ONE), col)
		if a > 0.6:
			var h := Color(col, a * halo)
			for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
				_glow.draw_rect(Rect2(f.at + d, Vector2.ONE), h)
