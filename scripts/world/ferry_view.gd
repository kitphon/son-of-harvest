class_name FerryView
extends Node2D
## Mio's ferry boat in the flat view, with its painted name once she has named it (the river
## map's "ferry_boat" and "boat_name" props; MapView and StoryView leave them out): a wooden hull
## with dark gunwales, its floor and seats inside, a raised bow at the east end and the pole
## lying along it (in Mio's hands while she crosses), drawn where its prop lies and moved each frame by FerryRun.boat_offset from
## where Mio's plan has her (tied up, or out across the river). The 3D view's is
## OutdoorProps.ferry_boat's BoatRide.

const T := 16

var map: MapData
var _boat: Dictionary = {}
var _names: Array[Dictionary] = []
var _pole_out := false   # the pole in Mio's hands (FerryRun.in_use): not lying along the seats


func _init(m: MapData) -> void:
	map = m
	name = "Ferry"
	for p in m.props:
		if p.kind == "ferry_boat":
			_boat = p
		elif p.kind == "boat_name":
			_names.append(p)


func _ready() -> void:
	add_to_group(FlatLight.GROUP)   # the name takes the world's light (redrawn when it changes)
	refresh()


func _process(_delta: float) -> void:
	refresh()


func has_boat() -> bool:
	return not _boat.is_empty()


## Moves the boat to where Mio's crossing has it now.
func refresh() -> void:
	if _boat.is_empty():
		return
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	var w := Villagers.where(FerryRun.villager(), game.day_minutes(), game.trigger_state(Vector2i.ZERO))
	position = (FerryRun.boat_offset(w) * T).round()
	if FerryRun.in_use(w) != _pole_out:
		_pole_out = not _pole_out
		queue_redraw()


func _draw() -> void:
	if _boat.is_empty():
		return
	var r := Rect2(Vector2(_boat.cell * T), Vector2(_boat.size * T))
	var o := Color("2a1e14")
	var hull := Rect2(r.position.x + 2, r.get_center().y - 5, r.size.x - 8, 10)
	draw_rect(hull.grow(1), o)
	draw_rect(hull, Color("8a6440"))
	draw_rect(hull.grow(-2), Color("4a3424"))                      # the floor inside
	draw_colored_polygon(PackedVector2Array([hull.end - Vector2(0, 10), Vector2(hull.end.x + 6, hull.get_center().y), hull.end]), o)
	draw_colored_polygon(PackedVector2Array([Vector2(hull.end.x, hull.position.y + 1), Vector2(hull.end.x + 4, hull.get_center().y), Vector2(hull.end.x, hull.end.y - 1)]), Color("8a6440"))
	for x in [hull.position.x + 9, hull.end.x - 10]:                # the seats
		draw_rect(Rect2(x, hull.position.y + 1, 3, hull.size.y - 2), Color("5e4228"))
	if not _pole_out:   # the pole along the seats
		draw_rect(Rect2(hull.position.x + 3, hull.get_center().y - 1, hull.size.x - 2, 2), Color("b89a68"))
	for p in _names:   # on the boat's side, low in its cell
		var tex := PlaceholderArt.tex(StoryView.art_key(p))
		var c := Rect2(Vector2(p.cell * T), Vector2(p.size * T))
		var bottom := c.end.y - 3
		draw_texture(tex, Vector2(roundf(c.get_center().x - tex.get_width() / 2.0), bottom - tex.get_height() - 1),
			FlatLight.at(Vector2(c.get_center().x, bottom - 1) + position, tex.get_height(), FlatLight.field_px()))
