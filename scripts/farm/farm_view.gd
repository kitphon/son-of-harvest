class_name FarmView
extends Node2D
## Draws a FarmGrid: ground tiles and field sprites from PlaceholderArt, buildings as boxes.

const T := 16
const COLORS := {
	"fence": Color("b08a5a"), "house": Color("a0522d"), "door": Color("4a2a14"),
	"bin": Color("7a6a50"), "stand": Color("d9b45a"),
}

## Ground only (soil, water, building footprints): the 3D view uses this as the ground
## texture and stands everything else up as sprites / boxes.
var ground_only := false

var farm: FarmGrid:
	set(value):
		farm = value
		farm.cells_changed.connect(queue_redraw)
		queue_redraw()


func _draw() -> void:
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			_draw_cell(Vector2i(x, y))


func _draw_cell(c: Vector2i) -> void:
	var r := Rect2(Vector2(c * T), Vector2(T, T))
	draw_texture(PlaceholderArt.tex(PlaceholderArt.ground_key(farm, c)), r.position)
	var f := farm.fixed_at(c)
	if f != "":
		# The flat view marks buildings and the fence on top of their ground.
		if ground_only or f == "pond":
			return
		draw_rect(r.grow(-5) if f == "fence" else r, COLORS[f])
		return
	if ground_only:
		return
	var d := farm.cell(c)
	# Same sprites as the 3D view, standing on the cell's bottom edge (tall ones overlap the
	# cell above).
	var key := PlaceholderArt.cell_key(farm, d)
	if key != "":
		var tex := PlaceholderArt.tex(key)
		draw_texture(tex, r.position + Vector2(0, T - tex.get_height()))
