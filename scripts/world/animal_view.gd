class_name AnimalView
extends Node2D
## The animals in the flat view: animals on their spots in the coop / barn (or spread over
## their yard on the farm while they are out), the eggs in the nests, and the dog on the farm
## (stepped by the rules like in AnimalLayer). Same sprites as AnimalLayer, standing still.
## They and the eggs take the world's light (FlatLight) where they stand.

const T := 16

var map: MapData
var on_farm := false
var farmer: Node2D
var _rng := RandomNumberGenerator.new()


func setup(m: MapData, farm: bool, player: Node2D = null) -> void:
	map = m
	on_farm = farm
	farmer = player
	add_to_group(FlatLight.GROUP)   # redrawn when the light changes
	Game.animals.changed.connect(queue_redraw)
	queue_redraw()


func _process(delta: float) -> void:
	if on_farm and farmer != null and not Game.paused():
		Game.animals.dog_walk(delta, Player.cell_of(farmer.position), func(c: Vector2i) -> bool: return not Game.farm.is_solid(c), _rng)
		queue_redraw()


func _draw() -> void:
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
		if home == "coop":
			var n := 0
			for p in map.props:
				if p.get("use", "") == "nest":
					for y in p.size.y:
						if n < a.eggs.size():
							var e := PlaceholderArt.tex(PlaceholderArt.world_item_key(a.eggs[n]))
							var ep := Vector2(p.cell.x * T, (p.cell.y + y) * T) + (Vector2(T, T) - e.get_size()) / 2.0
							draw_texture(e, ep, FlatLight.at(ep + Vector2(e.get_width() / 2.0, e.get_height()), e.get_height(), FlatLight.field_px() * 0.8))
						n += 1
	for s in shown:
		var tex := PlaceholderArt.tex("animal:%s:%s:0" % [a.look(s[0]), "sick" if s[0].sick else "idle"])
		_draw_animal(tex, s[1] * T + Vector2(0, 4))
	if on_farm and not a.dog.held:
		var tex := PlaceholderArt.tex("animal:%s:idle:0" % a.dog_look())
		var at := (Vector2(a.dog.cell) + Vector2(0.5, 0.5)) * T
		_draw_animal(tex, at + Vector2(0, 4))


## An animal picture with its feet at `feet`, at the flat view's pixel size (the pictures have
## AnimalArt.SCALE times the density).
func _draw_animal(tex: Texture2D, feet: Vector2) -> void:
	var size := tex.get_size() / float(AnimalArt.SCALE)
	draw_texture_rect(tex, Rect2(feet - Vector2(size.x / 2.0, size.y), size), false,
		FlatLight.at(feet, tex.get_height(), FlatLight.animal_px()))
