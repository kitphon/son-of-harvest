class_name BreathView
extends Node2D
## Breath in the cold on an outdoor map in the flat view (rules: BreathRules, data/breath.json; the
## 3D view's is BreathLayer): each puff a pixel or two (whole pixels) at the mouth of a figure that
## breathes, lifted up the screen by its height (data "flat".height_px). The figures are the farmer
## (Player), the villagers (VillagerView) and the grown animals and the dog (AnimalView), found in the
## map view's figure layer. The puffs draw over the figures (z_index "flat".z, above the figures'
## own z 0 and under the birds' air pass and the weather, which sit higher), still under the
## night tint. Made with the map's view; indoor maps and the mine get nothing.

const T := 16

var map: MapData
var farm: FarmGrid
var player: Node2D
var _t := 0.0
var _state := {}
var _strength := 0.0
var _puffs: Array[Dictionary] = []   # [{at: pixel, px: width in px, alpha, color}]


func setup(m: MapData, f: FarmGrid = null, p: Node2D = null) -> BreathView:
	map = m
	farm = f
	player = p
	name = "Breath"
	z_index = int(BreathRules.config().flat.z)
	_t = 0.0 if not BreathRules.forced().is_empty() else float(m.w * 17 + m.h * 23) * 0.29   # `--breath`: from the start, so a frame is the same
	refresh()
	return self


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock, the weather and the wind, then places the puffs of the figures that show one.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	_strength = BreathRules.strength_now(game, map)
	visible = _strength > 0.0
	_puffs.clear()
	if not visible:
		queue_redraw()
		return
	var wind := float(game.wind_strength())
	_puffs = _to_pixels(BreathRules.puffs_now(figures(), _state, _t, _strength, wind))
	queue_redraw()


## The figures that breathe now: [{id, cell, facing, kind, moving, running, tired}] (cells). The
## farmer first, then the villagers and the animals of the map view's figure layer.
func figures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if player != null:
		out.append({"id": BreathRules.FARMER, "cell": player.position / float(T), "facing": Vector2(player.facing),
			"kind": "person", "running": bool(player.running), "tired": game != null and game.body_state() != "fine"})
	var view := get_parent()
	if view == null:
		return out
	var villagers := FigureLayer.villagers_of(view)
	if villagers != null:
		out.append_array(villagers.breathers())
	var animals := FigureLayer.animals_of(view)
	if animals != null:
		out.append_array(animals.breathers())
	return out


## Where a puff is on the screen, in whole pixels: its position in cells, its height lifting it.
func screen_of(pos: Vector3) -> Vector2:
	return (Vector2(pos.x, pos.z) * T - Vector2(0, pos.y * float(BreathRules.config().flat.height_px))).round()


## The puffs for the figures `figs` at the time now (the same as refresh draws; for tests and the
## views): [{at, px, alpha, color}].
func puffs_for(figs: Array) -> Array[Dictionary]:
	var st := {}
	return _to_pixels(BreathRules.puffs_now(figs, st, _t, _strength if _strength > 0.0 else 1.0, 0.0))


func _to_pixels(list: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in list:
		out.append({"at": screen_of(p.pos), "px": float(p.size) * T, "alpha": float(p.alpha), "color": p.color})
	return out


## The puffs drawn now (for tests): [{at, px, alpha, color}].
func puffs() -> Array[Dictionary]:
	return _puffs


func _draw() -> void:
	for p in _puffs:
		var c: Color = p.color
		c.a = float(p.alpha)
		if c.a < 0.02:
			continue
		var at: Vector2 = p.at
		for d in BreathRules.pixels(float(p.px)):
			draw_rect(Rect2(at + Vector2(d), Vector2.ONE), c)
