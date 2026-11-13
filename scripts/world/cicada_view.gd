class_name CicadaView
extends Node2D
## The cicadas one can see on an outdoor map in the flat view (rules: CicadaRules,
## data/cicadas.json; pictures: CicadaArt; the 3D view's is CicadaLayer): a few clinging to the
## trees' trunks in summer and one flying off with a buzz when a walker comes close. Each picture
## at whole pixels; seen from above, a cicada's height lifts it up the screen (data "flat"
## height_px). Made with the map's view; indoor maps and the mine get nothing.
##
## Two passes, as the insects'. A clinging cicada is a small `Clinging` node of its own in the
## map view's FigureLayer, sorted with the figures by the point on the ground under it (its origin
## FigureLayer.FOOT px above that point; the picture drawn up the trunk, centred on its spot), so
## the farmer standing in front of the tree is drawn over it. The fliers are drawn by the child
## `air` (z_index "flat".air_z) over the roofs, props and figures, under the weather and the night
## tint. With no figure layer (a view on its own) the clinging ones stay in this node.
##
## `player` is the farmer; the villagers (the map view's VillagerView: the child only once walking,
## CicadaRules.scares) and the farm dog are the other walkers they fly off from.

const T := 16

var map: MapData
var player: Node2D
var air: Node2D   # the fliers' pass, over the figures
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _state := {}
var _shown: Array[Dictionary] = []
var _clinging: Array[Node2D] = []


func setup(m: MapData, p: Node2D = null) -> CicadaView:
	map = m
	player = p
	name = "Cicadas"
	air = Node2D.new()
	air.name = "Air"
	air.z_index = int(CicadaRules.config().flat.get("air_z", 20))
	air.draw.connect(_draw_air)
	add_child(air)
	refresh()
	return self


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock and the weather, then places every cicada of the kinds singing now.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var amounts := CicadaRules.amounts_now(game, map)
	_shown.clear()
	visible = not amounts.is_empty()
	if visible:
		var key := "%s|%d|%d|%s" % [map.id, game.season, game.day, CicadaRules.scion_stage(game.flags, game.day_number())]
		if key != _scene_key:
			_scene_key = key
			_state.clear()
			_scene = CicadaRules.scene_of(map, game.day + 30 * game.season)
			CicadaRules.add_scion(_scene, map, CicadaRules.scion_stage(game.flags, game.day_number()), str(game.flags.get(Scion.FLAG, "")))
		var farmer := CicadaRules.NO_FARMER if player == null else player.position / float(T)
		var others := walkers()
		var fled := false
		for kind in CicadaRules.KINDS:
			if amounts.has(kind):
				for c in CicadaRules.cicadas(kind, float(amounts[kind]), _t, _scene, farmer, _state, {}, others):
					fled = fled or bool(c.fled)
					_shown.append(c)
		if fled and is_inside_tree():
			var sfx := get_tree().root.get_node_or_null("Sfx")
			if sfx != null:
				sfx.play("cicada_buzz")
	_place_clinging()
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
				if CicadaRules.scares(str(id), stage):
					out.append(feet[id])
	if map != null and map.farm and game != null and game.animals != null and not game.animals.dog.is_empty() and not game.animals.dog.held:
		out.append(Vector2(game.animals.dog.cell) + Vector2(0.5, 0.5))
	return out


## Where a cicada is on the screen, in whole pixels, `lift` the height's share of it.
func screen_of(pos: Vector3, lift := true) -> Vector2:
	var up := pos.y * float(CicadaRules.config().flat.height_px) if lift else 0.0
	return (Vector2(pos.x, pos.z) * T - Vector2(0, up)).round()


## The cicadas now: [{at: pixel (a clinging one's middle, a flier's belly), ground: pixel (the
## point on the ground under it), key: picture key, right: faces right, air: drawn in the air pass}].
func sprites() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var scion := {}   # the cells of Kiku's persimmon (its trunk, a story prop drawn over the figures)
	for t in _scene.get("trunks", []):
		if t.kind == "scion":
			scion[t.cell] = true
	for c in _shown:
		out.append({"at": screen_of(c.pos), "ground": screen_of(c.pos, false), "key": CicadaRules.key_of(c),
			"right": (c.dir as Vector2).x > 0.0, "air": CicadaRules.flying(c),
			"scion": scion.has(Vector2i(floori(c.pos.x), floori(c.pos.z)))})
	return out


## One clinging cicada, its own small node so it sorts with the figures (FigureLayer).
class Clinging extends Node2D:
	var picture := {}

	func _draw() -> void:
		if not picture.is_empty():
			CicadaView._draw_cicada(self, picture)


## Where the clinging ones go: the map view's FigureLayer, or this node when there is none.
func cling_host() -> Node2D:
	var layer := FigureLayer.of(get_parent()) if is_inside_tree() else null
	return layer if layer != null and layer.is_inside_tree() else self


func _place_clinging() -> void:
	var on_trunks := sprites().filter(func(s): return not s.air)
	while _clinging.size() < on_trunks.size():
		var n := Clinging.new()
		n.name = "Cicada%d" % _clinging.size()
		add_child(n)
		_clinging.append(n)
	var fig := cling_host()
	for i in _clinging.size():
		var n: Clinging = _clinging[i]
		if i >= on_trunks.size() or not visible:
			n.visible = false
			continue
		var s: Dictionary = on_trunks[i]
		# Kiku's persimmon's cicadas go over the story props (StoryView, drawn over the figures); the rest sort with the figures.
		var host: Node2D = self if s.scion else fig
		if n.get_parent() != host:
			n.get_parent().remove_child(n)
			host.add_child(n)
		var to_host := Transform2D.IDENTITY if host == self else host.get_global_transform().affine_inverse() * get_global_transform()
		var ground: Vector2 = (to_host * (s.ground as Vector2)).round()
		var lift: float = (s.ground as Vector2).y - (s.at as Vector2).y
		n.position = ground - Vector2(0, FigureLayer.FOOT)
		n.picture = {"at": Vector2(0, FigureLayer.FOOT - lift), "key": s.key, "right": s.right, "air": false}
		n.visible = true
		n.queue_redraw()


## The nodes of the clinging cicadas shown now (for tests), in sprites() order.
func clinging_nodes() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for n in _clinging:
		if n.visible:
			out.append(n)
	return out


func _exit_tree() -> void:
	for n in _clinging:   # the ones among the figures outside this node go with it
		if is_instance_valid(n) and not is_ancestor_of(n):
			n.queue_free()
	_clinging.clear()


func _draw_air() -> void:
	for s in sprites():
		if s.air:
			_draw_cicada(air, s)


## A clinging cicada's picture is centred on its spot; a flier's sits on its belly.
static func _draw_cicada(canvas: CanvasItem, s: Dictionary) -> void:
	var tex := PlaceholderArt.tex(str(s.key) + (":r" if s.right else ""))
	var h := tex.get_height()
	var up := float(h) if bool(s.get("air", true)) else floorf(h / 2.0)
	canvas.draw_texture(tex, (s.at as Vector2) - Vector2(floorf(tex.get_width() / 2.0), up))
