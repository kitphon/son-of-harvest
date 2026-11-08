class_name ForageView
extends Node2D
## What grows wild on the map in the flat view (data/forage.json; Game.forage_here): each spot
## not yet picked today, its item's picture standing on the bottom of its cell. Redraws on
## Game.forage_changed (a pick, the morning).

const T := 16

var map_id := ""


func _init(id: String) -> void:
	map_id = id


func _ready() -> void:
	add_to_group(FlatLight.GROUP)   # the world's light on the pictures, redrawn when it changes
	Game.forage_changed.connect(queue_redraw)


func _draw() -> void:
	if Game.maps.id != map_id:
		return
	var here := Game.forage_here()
	for c in here:
		var tex := PlaceholderArt.tex(PlaceholderArt.world_item_key(here[c]))
		var feet := Vector2(c * T) + Vector2(T / 2.0, T - 1)
		draw_texture(tex, Vector2(c * T) + Vector2((T - tex.get_width()) / 2.0, T - tex.get_height() - 1),
			FlatLight.at(feet, tex.get_height(), FlatLight.field_px()))
