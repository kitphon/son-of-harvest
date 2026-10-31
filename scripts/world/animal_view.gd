class_name AnimalView
extends Node2D
## The animals in the flat view: hens on their coop spots (or spread over the farm yard while
## they are out) and the eggs in the nests. Same sprites as AnimalLayer, standing still.

const T := 16

var map: MapData
var on_farm := false


func setup(m: MapData, farm: bool) -> void:
	map = m
	on_farm = farm
	Game.animals.changed.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var a := Game.animals
	var spots: Array[Vector2] = []
	if on_farm and a.outside:
		var yard: Array = a.home_rule("coop").get("yard", [12, 4, 8, 3])
		for i in a.list.size():
			spots.append(Vector2(yard[0] + (i * 3) % int(yard[2]) + 0.5, yard[1] + (i * 2) % int(yard[3]) + 0.5))
	elif not on_farm and map != null and map.id == CoopActions.map_id():
		if not a.outside:
			for i in a.list.size():
				var c := CoopActions.spot(i)
				if c.x >= 0:
					spots.append(Vector2(c) + Vector2(0.5, 0.5))
		var n := 0
		for p in map.props:
			if p.get("use", "") == "nest":
				for y in p.size.y:
					if n < a.eggs.size():
						var e := PlaceholderArt.tex(PlaceholderArt.world_item_key(a.eggs[n]))
						draw_texture(e, Vector2(p.cell.x * T, (p.cell.y + y) * T) + (Vector2(T, T) - e.get_size()) / 2.0)
					n += 1
	for i in spots.size():
		var hen: Dictionary = a.list[i]
		var kind := "chicken" if a.is_adult(hen) else "chick"
		var tex := PlaceholderArt.tex("animal:%s:%s:0" % [kind, "sick" if hen.sick else "idle"])
		draw_texture(tex, spots[i] * T - Vector2(tex.get_width() / 2.0, tex.get_height()) + Vector2(0, 4))
