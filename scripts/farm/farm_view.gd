class_name FarmView
extends Node2D
## Draws a FarmGrid with placeholder shapes. Swap for a TileMapLayer + sprites later.

const T := 16
const COLORS := {
	"grass": Color("6fae4a"), "tilled": Color("8a5a32"), "wet": Color("5a3a20"),
	"fence": Color("b08a5a"), "house": Color("a0522d"), "door": Color("4a2a14"),
	"bin": Color("7a6a50"), "stand": Color("d9b45a"), "pond": Color("3d7fc4"),
	"path": Color("b9a27a"),
}
const OBJ_COLORS := {
	FarmGrid.Obj.ROCK: Color("9a9a9a"), FarmGrid.Obj.BRANCH: Color("7a5230"),
	FarmGrid.Obj.WEED: Color("3e7a2a"), FarmGrid.Obj.STUMP: Color("5e3d1e"),
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
	var f := farm.fixed_at(c)
	if f != "":
		if ground_only and f != "pond":
			draw_rect(r, COLORS.grass.darkened(0.15) if f == "fence" else COLORS.path)
			return
		draw_rect(r, COLORS[f])
		if f == "fence":
			draw_rect(r.grow(-5), COLORS.grass)
		return
	var d := farm.cell(c)
	draw_rect(r, COLORS.wet if d.wet else (COLORS.tilled if d.tilled else COLORS.grass))
	if d.tilled:
		draw_line(r.position + Vector2(2, 5), r.position + Vector2(14, 5), Color(0, 0, 0, 0.2))
		draw_line(r.position + Vector2(2, 11), r.position + Vector2(14, 11), Color(0, 0, 0, 0.2))
	if ground_only:
		return
	var center := r.get_center()
	match d.obj:
		FarmGrid.Obj.ROCK:
			draw_circle(center, 5, OBJ_COLORS[d.obj])
		FarmGrid.Obj.BRANCH:
			draw_line(center + Vector2(-6, 3), center + Vector2(6, -3), OBJ_COLORS[d.obj], 2.0)
		FarmGrid.Obj.WEED:
			for dx in [-4, 0, 4]:
				draw_line(center + Vector2(dx, 5), center + Vector2(dx * 1.5, -4), OBJ_COLORS[d.obj], 1.0)
		FarmGrid.Obj.STUMP:
			draw_rect(Rect2(center - Vector2(6, 5), Vector2(12, 10)), OBJ_COLORS[d.obj])
	if d.crop != "":
		var ripe := farm.ripe_stage(d.crop)
		var size := 1.5 + 4.5 * float(d.stage) / ripe
		draw_circle(center, size, Color("e8d34a") if d.stage >= ripe else Color("9ad65a"))
