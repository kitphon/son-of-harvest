class_name InsectView
extends Node2D
## Small flying insects on an outdoor map in the flat view (rules: InsectRules, data/insects.json;
## pictures: InsectArt; the 3D view's is InsectLayer): each insect's pixel picture at whole pixels,
## its feet (or a flier's belly) at the foot of the picture. Seen from above, an insect's height
## lifts it up the screen (data "flat".height_px). Made with the map's view; indoor maps and the
## mine get nothing.
##
## Two passes, as the birds'. The fliers are drawn by the child `air` (z_index "flat".air_z, the
## birds' air pass) over the roofs, props and figures, under the weather and the night tint. A
## dragonfly resting on a post or a crop top is a small `Perched` node of its own in the map
## view's FigureLayer, which sorts it with the villagers, the animals, the dog and the farmer by
## the point on the ground under it (its origin FigureLayer.FOOT px above that point, as theirs;
## the picture is drawn up at the perch's height): a figure standing in front of the post is drawn
## over it, one behind is hidden by it. With no figure layer (a view on its own) they stay in this
## node.
##
## `player` is the farmer; the villagers (the map view's VillagerView: the child only once walking,
## InsectRules.scares) and the farm dog are the other walkers a resting dragonfly lifts off from.
## Its shadows (InsectRules.shadow_of: a blob under a perched one, a faint sun-cast oval under a flier)
## are drawn in this node's own ground pass, under the figures.

const T := 16

var map: MapData
var farm: FarmGrid
var player: Node2D
var air: Node2D   # the fliers' pass, over the figures
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _farm_key := ""
var _state := {}
var _shown: Array[Dictionary] = []
var _sun := 0.0
var _sun_dir := Vector3.DOWN
var _perched: Array[Node2D] = []   # the resting ones, a node each, in the figure layer


func setup(m: MapData, f: FarmGrid = null, p: Node2D = null) -> InsectView:
	map = m
	farm = f
	player = p
	name = "Insects"
	air = Node2D.new()
	air.name = "Air"
	air.z_index = int(InsectRules.config().flat.get("air_z", 20))
	air.draw.connect(_draw_air)
	add_child(air)
	_t = 0.0 if not InsectRules.forced().is_empty() else float(m.w * 17 + m.h * 31) * 0.27   # `--insects`: from the start, so a frame is the same
	refresh()
	return self


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock, the weather and the wind, then places every insect of the kinds on show.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var amounts := InsectRules.amounts_now(game, map)
	_shown.clear()
	visible = not amounts.is_empty()
	if not visible:
		_place_perched()   # hides them, wherever they sit
		queue_redraw()
		return
	var key := "%s|%d|%d" % [map.id, game.season, game.day]
	var fkey := InsectRules.farm_key(farm)
	if key != _scene_key or fkey != _farm_key:
		if key != _scene_key:
			_state.clear()
		_scene_key = key
		_farm_key = fkey
		_scene = InsectRules.scene_of(map, farm, game.day + 28 * game.season)
	InsectRules.blocked_for(_scene, map, farm, game)   # a building finished today blocks the shadows now
	_sun = game.sun_shadow()
	_sun_dir = game.sun_direction(game.sun_light())
	var farmer := InsectRules.NO_FARMER if player == null else player.position / float(T)
	var others := walkers()
	for kind in InsectRules.KINDS:
		if amounts.has(kind):
			_shown.append_array(InsectRules.insects(kind, float(amounts[kind]), _t, _scene, farmer, _state, {}, others))
	_place_perched()
	queue_redraw()
	air.queue_redraw()


## The other walkers here now, in cells: the villagers of the map view's VillagerView (the child
## once walking) and, on the farm, the dog when it is not in the farmer's arms.
func walkers() -> Array:
	var out := []
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var parent := get_parent()
	if parent != null:
		var views: Array = parent.get_children().filter(func(n): return n is VillagerView)
		var in_layer := FigureLayer.villagers_of(parent)
		if in_layer != null:
			views.append(in_layer)
		for n in views:
			var stage := str(game.flags.get(Child.STAGE, "")) if game != null else ""
			var feet: Dictionary = n.feet()
			for id in feet:
				if InsectRules.scares(str(id), stage):
					out.append(feet[id])
	if farm != null and game != null and game.animals != null and not game.animals.dog.is_empty() and not game.animals.dog.held:
		out.append(Vector2(game.animals.dog.cell) + Vector2(0.5, 0.5))
	return out


## Where an insect's feet are on the screen, in whole pixels, `lift` the height's share of it.
func screen_of(pos: Vector3, lift := true) -> Vector2:
	var up := pos.y * float(InsectRules.config().flat.height_px) if lift else 0.0
	return (Vector2(pos.x, pos.z) * T - Vector2(0, up)).round()


## The shadows now: [{rect: Rect2 in whole pixels, alpha}] (InsectRules.shadow_of: a perched
## dragonfly's blob under it, a flier's faint sun-cast oval). Under the figures, in the ground pass.
func shadows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var blocked: Dictionary = _scene.get("blocked", {})
	for b in _shown:
		var s := InsectRules.shadow_of(b, _sun, _sun_dir, {}, blocked)
		if s.is_empty():
			continue
		var size := ((s.size as Vector2) * T).round().max(Vector2(2, 1))
		var at := ((s.at as Vector2) * T - size / 2.0).round()
		out.append({"rect": Rect2(at, size), "alpha": float(s.alpha)})
	return out


func _draw() -> void:
	for s in shadows():
		BirdView.draw_blob(self, s.rect, s.alpha)


## The insects now: [{at: pixel (feet), ground: pixel (the point on the ground under it), key:
## picture key, right: faces right, air: drawn in the air pass (over the figures)}].
func sprites() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in _shown:
		out.append({"at": screen_of(b.pos), "ground": screen_of(b.pos, false), "key": InsectRules.key_of(b),
			"right": (b.dir as Vector2).x > 0.0, "air": InsectRules.flying(b)})
	return out


## One resting insect, its own small node so it sorts with the figures (FigureLayer): its origin
## FigureLayer.FOOT px above the ground under it, the picture drawn up at its perch's height.
class Perched extends Node2D:
	var picture := {}

	func _draw() -> void:
		if not picture.is_empty():
			InsectView._draw_insect(self, picture)


## Where the resting ones go: the map view's FigureLayer (sorted with the figures by the ground
## under them), or this node when there is none.
func perch_host() -> Node2D:
	var layer := FigureLayer.of(get_parent()) if is_inside_tree() else null
	return layer if layer != null and layer.is_inside_tree() else self


func _place_perched() -> void:
	var resting := sprites().filter(func(s): return not s.air)
	while _perched.size() < resting.size():
		var n := Perched.new()
		n.name = "Perched%d" % _perched.size()
		add_child(n)
		_perched.append(n)
	var host := perch_host()
	for i in _perched.size():
		var n: Perched = _perched[i]
		if i >= resting.size() or not visible:
			n.visible = false
			continue
		var s: Dictionary = resting[i]
		if n.get_parent() != host:
			n.get_parent().remove_child(n)
			host.add_child(n)
		var to_host := Transform2D.IDENTITY if host == self else host.get_global_transform().affine_inverse() * get_global_transform()
		var ground: Vector2 = (to_host * (s.ground as Vector2)).round()
		var lift: float = (s.ground as Vector2).y - (s.at as Vector2).y   # the perch's height on the screen
		n.position = ground - Vector2(0, FigureLayer.FOOT)
		n.picture = {"at": Vector2(0, FigureLayer.FOOT - lift), "key": s.key, "right": s.right}
		n.visible = true
		n.queue_redraw()


## The nodes of the resting insects shown now (for tests), in sprites() order.
func perched_nodes() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for n in _perched:
		if n.visible:
			out.append(n)
	return out


func _exit_tree() -> void:
	for n in _perched:   # the ones sitting among the figures outside this node go with it
		if is_instance_valid(n) and not is_ancestor_of(n):
			n.queue_free()
	_perched.clear()


func _draw_air() -> void:
	for s in sprites():
		if s.air:
			_draw_insect(air, s)


static func _draw_insect(canvas: CanvasItem, s: Dictionary) -> void:
	var tex := PlaceholderArt.tex(str(s.key) + (":r" if s.right else ""))
	canvas.draw_texture(tex, (s.at as Vector2) - Vector2(floorf(tex.get_width() / 2.0), tex.get_height()))
