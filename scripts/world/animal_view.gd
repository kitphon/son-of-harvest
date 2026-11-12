class_name AnimalView
extends Node2D
## The animals in the flat view: animals on their spots in the coop / barn (or spread over
## their yard on the farm while they are out), the eggs in the nests, and the dog on the farm
## (stepped by the rules like in AnimalLayer). Same sprites as AnimalLayer, standing still.
## They and the eggs take the world's light (FlatLight) where they stand.
## It sits in the map view's FigureLayer, y-sorted: each animal and the dog is a `Beast` node of
## its own, its origin FigureLayer.FOOT px above its feet, so they sort with the villagers, the
## farmer and each other by their feet; the eggs are drawn by this node itself at y 0, under them all.

const T := 16

var map: MapData
var on_farm := false
var farmer: Node2D
var _rng := RandomNumberGenerator.new()


func setup(m: MapData, farm: bool, player: Node2D = null) -> void:
	map = m
	on_farm = farm
	farmer = player
	name = "Animals"
	y_sort_enabled = true
	add_to_group(FlatLight.GROUP)   # redrawn when the light changes
	Game.animals.changed.connect(queue_redraw)
	queue_redraw()
	sync()


func _process(delta: float) -> void:
	if on_farm and farmer != null and not Game.paused():
		Game.animals.dog_walk(delta, Player.cell_of(farmer.position), func(c: Vector2i) -> bool: return not Game.farm.is_solid(c), _rng)
		queue_redraw()
	sync()


## One animal (or the dog) standing: its picture with its feet FigureLayer.FOOT px below the origin.
class Beast extends Node2D:
	var tex: Texture2D

	func _draw() -> void:
		if tex != null:
			AnimalView._draw_animal(self, tex, Vector2(0, FigureLayer.FOOT), position + Vector2(0, FigureLayer.FOOT))


## Puts a Beast node at each animal shown now (the dog last), hiding the spare ones; each is
## redrawn every frame (the light, a step, a change of pose).
func sync() -> void:
	var shown := _shown()
	var beasts := beasts()
	for i in range(beasts.size(), shown.size()):
		var b := Beast.new()
		b.name = "Beast%d" % i
		add_child(b)
		beasts.append(b)
	for i in beasts.size():
		var b: Beast = beasts[i]
		b.visible = i < shown.size()
		if b.visible:
			b.tex = shown[i][0]
			b.position = (shown[i][1] as Vector2) - Vector2(0, FigureLayer.FOOT)
			b.queue_redraw()


## The animal nodes, shown or not, in order (the shown ones first, the dog last of them).
func beasts() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for n in get_children():
		if n is Beast:
			out.append(n)
	return out


func _draw() -> void:
	var a := Game.animals
	if not on_farm and map != null and a.home_on_map(map.id) == "coop":   # the eggs in the nests, under the hens
		var n := 0
		for p in map.props:
			if p.get("use", "") == "nest":
				for y in p.size.y:
					if n < a.eggs.size():
						var e := PlaceholderArt.tex(PlaceholderArt.world_item_key(a.eggs[n]))
						var ep := Vector2(p.cell.x * T, (p.cell.y + y) * T) + (Vector2(T, T) - e.get_size()) / 2.0
						draw_texture(e, ep, FlatLight.at(ep + Vector2(e.get_width() / 2.0, e.get_height()), e.get_height(), FlatLight.field_px() * 0.8))
					n += 1


## Where the animals stand and what they cover, in this node's pixels, the dog last:
## [{feet, rect, node: its Beast}] (tests).
func figures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var shown := _shown()
	var beasts := beasts()
	for i in shown.size():
		var size := (shown[i][0] as Texture2D).get_size() / float(AnimalArt.SCALE)
		out.append({"feet": shown[i][1], "rect": Rect2((shown[i][1] as Vector2) - Vector2(size.x / 2.0, size.y), size),
			"node": beasts[i] if i < beasts.size() else null})
	return out


## The grown animals and the dog drawn now as breathers (BreathRules): [{id, cell, facing, kind}]
## (the dog's id "dog", a young one is left out: it does not breathe yet).
func breathers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in _shown():
		var animal = s[2]
		if animal != null and not Game.animals.is_adult(animal):
			continue
		var cell := ((s[1] as Vector2) - Vector2(0, 4)) / float(T)
		out.append({"id": "dog" if animal == null else "a:%s" % str(animal.name), "cell": cell, "origin": (s[1] as Vector2) - Vector2(0, FigureLayer.FOOT),
			"facing": Vector2.ZERO, "kind": "animal"})
	return out


## The animals drawn now: [[picture, feet in pixels, animal (null for the dog)]] (the dog last).
func _shown() -> Array[Array]:
	var a := Game.animals
	var shown: Array[Array] = []   # [animal, spot]
	if on_farm:
		for home in a.state:
			if not a.is_out(home):
				continue
			var yard: Array = a.home_rule(home).get("yard", [12, 4, 8, 3])
			var n := 0
			for i in a.in_home(home):
				shown.append([a.list[i], Vector2(yard[0] + (n * 3) % int(yard[2]) + 0.5, yard[1] + (n * 2) % int(yard[3]) + 0.5)])
				n += 1
	elif map != null and a.home_on_map(map.id) != "":
		var home := a.home_on_map(map.id)
		if not a.is_out(home):
			for i in a.in_home(home):
				var c := a.spot(i)
				if c.x >= 0:
					shown.append([a.list[i], Vector2(c) + Vector2(0.5, 0.5)])
	var out: Array[Array] = []
	for s in shown:
		out.append([PlaceholderArt.tex("animal:%s:%s:0" % [a.look(s[0]), "sick" if s[0].sick else "idle"]), s[1] * T + Vector2(0, 4), s[0]])
	if on_farm and not a.dog.held:
		out.append([PlaceholderArt.tex("animal:%s:idle:0" % a.dog_look()), (Vector2(a.dog.cell) + Vector2(0.5, 0.5)) * T + Vector2(0, 4), null])
	return out


## An animal picture on `canvas` with its feet at `feet`, at the flat view's pixel size (the
## pictures have AnimalArt.SCALE times the density), lit as it stands at `world` (map pixels).
static func _draw_animal(canvas: CanvasItem, tex: Texture2D, feet: Vector2, world: Vector2) -> void:
	var size := tex.get_size() / float(AnimalArt.SCALE)
	canvas.draw_texture_rect(tex, Rect2(feet - Vector2(size.x / 2.0, size.y), size), false,
		FlatLight.at(world, tex.get_height(), FlatLight.animal_px()))
