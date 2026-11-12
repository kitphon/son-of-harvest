class_name BirdView
extends Node2D
## Small birds on an outdoor map in the flat view (rules: BirdRules, data/birds.json; pictures:
## BirdArt; the 3D view's is BirdLayer): each bird's pixel picture at whole pixels, its feet (or a
## flier's belly) at the foot of the picture. Seen from above, a bird's height lifts it up the
## screen (data "flat".height_px). Made with the map's view; indoor maps and the mine get nothing.
##
## Two passes. This node, in the map view's ground order (over the ground, roofs and props, under
## the figures), draws the shadows on the ground (BirdRules.shadow_of: a soft blob under each bird
## on the ground, a faint one cast along the sun for a flier by day in sun), under every figure.
## Each bird on the ground (standing, pecking, hopping) is a small `Ground` node of its own, sorted
## in among the figures by its feet (slot_of): the flat view draws its figures in tree order (the
## villagers' sprites, the animals' node, then the farmer after the map view) with no y-sort, so a
## bird overlapping a figure is moved to just before the first one standing in front of it, or
## just after the last one behind it; one overlapping none stays in this node. Its child `air` (z_index "flat".air_z) draws the birds in the
## air over the roofs, props and figures, still under the weather and the night tint (the
## CanvasModulate covers every z), and the HUD and the map fade (their own canvas layers).
##
## `player` is the farmer; the villagers (the map view's VillagerView: the child only once walking,
## BirdRules.scares) and the farm dog are the other walkers: sparrows and the heron fly off when
## any of them comes near.

const T := 16

var map: MapData
var farm: FarmGrid
var player: Node2D
var air: Node2D   # the fliers' pass, over the figures
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _built_key := ""   # the farm's buildings when the blocked set was made (BirdRules.built_key)
var _state := {}
var _shown: Array[Dictionary] = []
var _sun := 0.0
var _sun_dir := Vector3.DOWN
var _ground: Array[Node2D] = []   # the birds on the ground, a node each, sorted in among the figures


func setup(m: MapData, f: FarmGrid = null, p: Node2D = null) -> BirdView:
	map = m
	farm = f
	player = p
	name = "Birds"
	air = Node2D.new()
	air.name = "Air"
	air.z_index = int(BirdRules.config().flat.get("air_z", 20))
	air.draw.connect(_draw_air)
	add_child(air)
	_t = 0.0 if not BirdRules.forced().is_empty() else float(m.w * 13 + m.h * 29) * 0.31   # `--birds`: from the start, so a frame is the same
	refresh()
	return self


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock, the weather and the sun, then places every bird of the kinds on show.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var amounts := BirdRules.amounts_now(game, map)
	_shown.clear()
	visible = not amounts.is_empty()
	if not visible:
		_place_ground()   # hides them, wherever they sit
		return
	var key := "%s|%d|%d" % [map.id, game.season, game.day]
	if key != _scene_key:
		_scene_key = key
		_state.clear()
		_scene = BirdRules.scene_of(map, farm, game.day + 28 * game.season)
	var bkey := BirdRules.built_key(game)
	if bkey != _built_key:   # a building finished today: its roof and walls block the shadows now
		_built_key = bkey
		_scene["blocked"] = BirdRules.blocked_cells(map, farm)
	_sun = game.sun_shadow()
	_sun_dir = game.sun_direction(game.sun_light())
	var farmer := BirdRules.NO_FARMER if player == null else player.position / float(T)
	var others := walkers()
	for kind in BirdRules.KINDS:
		if amounts.has(kind):
			_shown.append_array(BirdRules.birds(kind, float(amounts[kind]), _t, _scene, farmer, _state, {}, others))
	_place_ground()
	queue_redraw()
	air.queue_redraw()


## The other walkers here now, in cells: the villagers of the map view's VillagerView (the child
## once walking) and, on the farm, the dog when it is not in the farmer's arms.
func walkers() -> Array:
	var out := []
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var parent := get_parent()
	if parent != null:
		for n in parent.get_children():
			if n is VillagerView:
				var stage := str(game.flags.get(Child.STAGE, "")) if game != null else ""
				var feet: Dictionary = n.feet()
				for id in feet:
					if BirdRules.scares(str(id), stage):
						out.append(feet[id])
	if farm != null and game != null and game.animals != null and not game.animals.dog.is_empty() and not game.animals.dog.held:
		out.append(Vector2(game.animals.dog.cell) + Vector2(0.5, 0.5))
	return out


## Where a bird's feet are on the screen, in whole pixels.
func screen_of(pos: Vector3) -> Vector2:
	return (Vector2(pos.x, pos.z) * T - Vector2(0, pos.y * float(BirdRules.config().flat.height_px))).round()


## The birds now: [{at: pixel (feet), key: picture key, right: faces right, air: drawn in the air
## pass (over the figures)}].
func sprites() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in _shown:
		out.append({"at": screen_of(b.pos), "key": BirdRules.key_of(b), "right": (b.dir as Vector2).x > 0.0, "air": BirdRules.flying(b)})
	return out


## The shadows now: [{rect: Rect2 in whole pixels, alpha}] (BirdRules.shadow_of).
func shadows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in _shown:
		var s := BirdRules.shadow_of(b, _sun, _sun_dir, {}, _scene.get("blocked", {}))
		if s.is_empty():
			continue
		var size := ((s.size as Vector2) * T).round().max(Vector2(2, 1))
		var at := ((s.at as Vector2) * T - size / 2.0).round()
		out.append({"rect": Rect2(at, size), "alpha": float(s.alpha), "air": BirdRules.flying(b)})
	return out


func _draw() -> void:
	for s in shadows():
		draw_blob(self, s.rect, s.alpha)


## One bird on the ground, its own small node so it can sit in the figures' drawing order: its
## feet at the node's position.
class Ground extends Node2D:
	var bird := {}

	func _draw() -> void:
		if not bird.is_empty():
			BirdView._draw_bird(self, bird)


## The figures a bird on the ground can overlap, in the order they are drawn: the map view's
## villagers (VillagerView), its animals and the dog (AnimalView, one node for all) and the farmer
## (drawn after the map view). [{feet: y in this node's pixels, rect: Rect2, anchor: the node drawn}].
func figures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var to_me := get_global_transform().affine_inverse()
	var parent := get_parent()
	if parent != null:
		for n in parent.get_children():
			if n is VillagerView:
				for s in (n as VillagerView).figures():
					var x := to_me * s.get_global_transform()
					var r := Rect2(s.offset, s.texture.get_size()) if s.texture != null else Rect2()
					out.append({"feet": (x * Vector2.ZERO).y, "rect": x * r, "anchor": s})
			elif n is AnimalView and (n as AnimalView).visible:
				var x := to_me * (n as AnimalView).get_global_transform()
				for f in (n as AnimalView).figures():
					out.append({"feet": (x * (f.feet as Vector2)).y, "rect": x * (f.rect as Rect2), "anchor": n})
	if player != null and player.is_inside_tree() and player.visible and player.get_parent() != null:
		var x := to_me * player.get_global_transform()
		var size := Vector2(PlaceholderArt.FIGURE_SIZE)
		out.append({"feet": (x * Vector2.ZERO).y, "rect": x * Rect2(Vector2(-size.x / 2.0, Player.FIGURE_TOP), size), "anchor": player})
	return out


## Where bird `s` (one of sprites(), on the ground) is drawn among the figures `figs` it overlaps:
## just before the first one (in drawing order) whose feet are below its own (in front of it), else
## just after the last one it overlaps (all behind it); {} when it overlaps none (drawn in this node,
## under them all). {anchor, after}.
static func slot_of(s: Dictionary, figs: Array[Dictionary]) -> Dictionary:
	var tex := PlaceholderArt.tex(str(s.key))
	var at: Vector2 = s.at
	var r := Rect2(at - Vector2(floorf(tex.get_width() / 2.0), tex.get_height()), tex.get_size())
	var last := {}
	for f in figs:
		if not (f.rect as Rect2).intersects(r):
			continue
		if float(f.feet) >= at.y:
			return {"anchor": f.anchor, "after": false}
		last = {"anchor": f.anchor, "after": true}
	return last


## Puts each bird on the ground in its own node, in the figures' drawing order (slot_of): so a
## sparrow in front of a villager or the farmer draws over them and one behind draws under.
func _place_ground() -> void:
	var on_ground := sprites().filter(func(s): return not s.air)
	while _ground.size() < on_ground.size():
		var n := Ground.new()
		n.name = "Ground%d" % _ground.size()
		add_child(n)
		_ground.append(n)
	var figs: Array[Dictionary] = []
	if not on_ground.is_empty() and visible and is_inside_tree():
		figs = figures()
	for i in _ground.size():
		var n: Ground = _ground[i]
		if i >= on_ground.size() or not visible:
			n.visible = false
			continue
		var s: Dictionary = on_ground[i]
		var slot := slot_of(s, figs)
		var host: Node = self if slot.is_empty() else (slot.anchor as Node).get_parent()
		if n.get_parent() != host:
			n.get_parent().remove_child(n)
			host.add_child(n)
		if not slot.is_empty():
			var to := (slot.anchor as Node).get_index() + (1 if slot.after else 0)
			if n.get_index() < to:
				to -= 1
			if n.get_index() != to:
				host.move_child(n, to)
		n.position = s.at if host == self else ((host as CanvasItem).get_global_transform().affine_inverse() * (get_global_transform() * (s.at as Vector2))).round()
		n.bird = {"at": Vector2.ZERO, "key": s.key, "right": s.right}
		n.visible = true
		n.queue_redraw()


## The nodes of the birds on the ground shown now (for tests), in sprites() order.
func ground_nodes() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for n in _ground:
		if n.visible:
			out.append(n)
	return out


func _exit_tree() -> void:
	for n in _ground:   # the ones sitting among the figures outside this node go with it
		if is_instance_valid(n) and not is_ancestor_of(n):
			n.queue_free()
	_ground.clear()


func _draw_air() -> void:
	for s in sprites():
		if s.air:
			_draw_bird(air, s)


static func _draw_bird(canvas: CanvasItem, s: Dictionary) -> void:
	var tex := PlaceholderArt.tex(str(s.key) + (":r" if s.right else ""))
	canvas.draw_texture(tex, (s.at as Vector2) - Vector2(floorf(tex.get_width() / 2.0), tex.get_height()))


## A soft dark oval in whole-pixel rows over `r`: a faint rim and a darker core.
static func draw_blob(canvas: CanvasItem, r: Rect2, alpha: float) -> void:
	for layer in [[1.0, 0.5], [0.6, 0.5]]:
		var w: float = r.size.x * float(layer[0])
		var h: float = maxf(r.size.y * float(layer[0]), 1.0)
		var c := r.get_center()
		var rows := int(ceilf(h))
		for i in rows:
			var y := (float(i) + 0.5) / float(rows) * 2.0 - 1.0
			var half := roundf(w / 2.0 * sqrt(maxf(1.0 - y * y, 0.0)))
			if half < 1.0:
				continue
			canvas.draw_rect(Rect2(Vector2(roundf(c.x - half), roundf(c.y - h / 2.0) + i), Vector2(half * 2.0, 1.0)), Color(0, 0, 0, alpha * float(layer[1])))
