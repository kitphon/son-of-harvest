class_name ForageLayer
extends Node3D
## What grows wild on the map in 3D (data/forage.json; Game.forage_here): each spot not yet
## picked today stands on its cell as its item's sprite. Rebuilds on Game.forage_changed (a
## pick, the morning). Same units as FarmWorld (1 unit = 1 cell).

var map_id := ""


func _init(id: String) -> void:
	map_id = id


func _ready() -> void:
	Game.forage_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	if Game.maps.id != map_id:
		return
	var here := Game.forage_here()
	for c in here:
		var s := FarmWorld.make_sprite(PlaceholderArt.tex(PlaceholderArt.world_item_key(here[c])))
		s.position = Vector3(c.x + 0.5, 0, c.y + 0.5)
		add_child(s)
