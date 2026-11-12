class_name BreathView
extends Node2D
## Breath in the cold on an outdoor map in the flat view (rules: BreathRules, data/breath.json; the
## 3D view's is BreathLayer): each puff a pixel or two (whole pixels) at the mouth of a figure that
## breathes, lifted up the screen by its height (data "flat".height_px). The figures are the farmer
## (Player), the villagers (VillagerView) and the grown animals and the dog (AnimalView), found in the
## map view's figure layer. Each figure's puffs are one small node of their own in that y-sorted
## FigureLayer (as the birds on the ground are), its origin `flat.nudge_px` below the owner's origin,
## so the breath draws just over its own figure and under any figure in front, and over a figure
## standing behind it (the owner's feet decide, not a z_index). At most data "cap".puffs_flat puffs
## at once. Still under the night tint and the weather, which sit higher. Made with the map's view;
## indoor maps and the mine get nothing.

const T := 16

var map: MapData
var farm: FarmGrid
var player: Node2D
var _t := 0.0
var _state := {}
var _strength := 0.0
var _puffs: Array[Dictionary] = []   # [{at: pixel, px: width in px, alpha, color, id, origin}]
var _nodes := {}   # figure id -> its Wisp node


## One figure's puffs, drawn by a node that sorts with the figures (its origin below the owner's).
class Wisp extends Node2D:
	var puffs: Array[Dictionary] = []   # [{at: pixel in the view, px, alpha, color}]
	var base := Vector2.ZERO            # this node's origin in view pixels (the puffs are drawn from it)

	func _draw() -> void:
		for p in puffs:
			var c: Color = p.color
			c.a = float(p.alpha)
			if c.a < 0.02:
				continue
			var at: Vector2 = (p.at as Vector2) - base
			for d in BreathRules.pixels(float(p.px)):
				draw_rect(Rect2(at + Vector2(d), Vector2.ONE), c)


func setup(m: MapData, f: FarmGrid = null, p: Node2D = null) -> BreathView:
	map = m
	farm = f
	player = p
	name = "Breath"
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
	if visible:
		var wind := float(game.wind_strength())
		_puffs = _to_pixels(BreathRules.capped(BreathRules.puffs_now(figures(), _state, _t, _strength, wind), int(BreathRules.config().cap.puffs_flat)))
	_place()


## The figures that breathe now: [{id, cell, facing, kind, moving, running, tired, origin}] (cells;
## origin: the figure's origin in px, what its puffs sort by). The farmer first, then the villagers
## and the animals of the map view's figure layer.
func figures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if player != null:
		out.append({"id": BreathRules.FARMER, "cell": player.position / float(T), "facing": Vector2(player.facing),
			"kind": "person", "running": bool(player.running), "tired": game != null and game.body_state() != "fine",
			"origin": player.position})
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
## views): [{at, px, alpha, color, id, origin}].
func puffs_for(figs: Array) -> Array[Dictionary]:
	var st := {}
	return _to_pixels(BreathRules.puffs_now(figs, st, _t, _strength if _strength > 0.0 else 1.0, 0.0))


func _to_pixels(list: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var scale := float(BreathRules.config().flat.size_scale)
	for p in list:
		out.append({"at": screen_of(p.pos), "px": float(p.size) * T * scale, "alpha": float(p.alpha),
			"color": p.color, "id": p.id, "origin": p.get("origin", Vector2.ZERO)})
	return out


## The puffs drawn now (for tests): [{at, px, alpha, color, id, origin}].
func puffs() -> Array[Dictionary]:
	return _puffs


## Where the puffs go: the map view's FigureLayer (sorted with the figures by their feet), or this
## node when there is none.
func host() -> Node2D:
	var layer := FigureLayer.of(get_parent()) if is_inside_tree() else null
	return layer if layer != null and layer.is_inside_tree() else self


## Gives each figure that has puffs its node in the figure layer, at its owner's origin (a little
## below it), and hands it that figure's puffs; the others are hidden.
func _place() -> void:
	var h := host()
	var nudge := float(BreathRules.config().flat.nudge_px)
	var by_id := {}
	for p in _puffs:
		if not by_id.has(p.id):
			by_id[p.id] = []
		by_id[p.id].append(p)
	for id in _nodes:
		if is_instance_valid(_nodes[id]):
			(_nodes[id] as Wisp).visible = false
	for id in by_id:
		var n: Wisp = _nodes.get(id)
		if n == null or not is_instance_valid(n):
			n = Wisp.new()
			n.name = "Wisp%d" % _nodes.size()
			_nodes[id] = n
		if n.get_parent() != h:
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			h.add_child(n)
		var origin: Vector2 = (by_id[id] as Array)[0].origin
		n.base = origin + Vector2(0, nudge)
		n.position = n.base if h == self else h.get_global_transform().affine_inverse() * (get_global_transform() * n.base)
		var list: Array[Dictionary] = []
		list.assign(by_id[id])
		n.puffs = list
		n.visible = true
		n.queue_redraw()


## The puff nodes shown now (for tests): one a figure with puffs.
func nodes() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for id in _nodes:
		if is_instance_valid(_nodes[id]) and (_nodes[id] as Node2D).visible:
			out.append(_nodes[id])
	return out


func _exit_tree() -> void:
	for id in _nodes:   # the ones sitting among the figures outside this node go with it
		var n: Node2D = _nodes[id]
		if is_instance_valid(n) and not is_ancestor_of(n):
			n.queue_free()
	_nodes.clear()
