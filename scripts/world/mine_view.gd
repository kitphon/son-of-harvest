class_name MineView
extends Node2D
## A mine floor in the flat view, over the cave's MapView: frost, soft spots and the open hole
## on the ground, then rocks (and ice) and finds left lying. Reads a MineFloor and redraws on `changed`.

const T := 16

var floor_: MineFloor


func _init(f: MineFloor) -> void:
	floor_ = f
	floor_.changed.connect(queue_redraw)


func _draw() -> void:
	for c in floor_.frost:
		draw_texture(PlaceholderArt.tex("mine:frost"), Vector2(c * T))
	for c in floor_.soft:
		draw_texture(PlaceholderArt.tex("mine:soft"), Vector2(c * T))
	if floor_.open:
		draw_texture(PlaceholderArt.tex("mine:hole"), Vector2(floor_.stairs * T))
	for c in floor_.rocks:
		var tex := PlaceholderArt.tex("mine:" + str(floor_.rocks[c].kind))
		# Bottom-centred on the cell, so a big rock spills over its edges like a boulder.
		draw_texture(tex, Vector2(c * T) + Vector2((T - tex.get_width()) / 2.0, T - tex.get_height()))
	for c in floor_.loose:
		var tex := PlaceholderArt.tex(PlaceholderArt.world_item_key(floor_.loose[c]))
		draw_texture(tex, Vector2(c * T) + (Vector2(T, T) - tex.get_size()) / 2.0)
