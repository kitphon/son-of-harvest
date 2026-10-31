class_name MapView
extends Node2D
## Draws a map other than the farm in the flat view: its ground tiles, then walls, props and
## doors as flat boxes (like FarmView marks the farm buildings).

const T := 16
const COLORS := {
	"wall": Color("6a5a48"), "door": Color("4a2a14"), "futon": Color("e8e2d0"),
	"low_table": Color("5a3a24"), "tansu": Color("3e3028"), "andon": Color("ffe6a8"),
	"kamado": Color("c8b498"), "mizuya": Color("4a3424"), "nagamochi": Color("8a6a48"), "kotatsu": Color("3a4a7a"),
	"village_house": Color("a0522d"), "torii": Color("c8442c"), "hokora": Color("8a6a48"),
	"stone_lantern": Color("9a968e"), "pine": Color("2f5a34"),
	"counter": Color("4a3424"), "shelf": Color("6a4a30"), "rice_sacks": Color("d8c088"),
	"forge": Color("7a746c"), "anvil": Color("2a2a2e"), "tool_rack": Color("8a6a48"), "water_tub": Color("2a4a5a"),
	"feed_box": Color("9a7048"), "nest": Color("d8bc78"), "incubator": Color("c8a868"),
	"feed_sack": Color("a88a52"), "hatch": Color("4a2a14"),
	"fodder_box": Color("8a6440"), "stalls": Color("d0b478"), "hay": Color("c8b060"), "barn_gate": Color("4a2a14"),
	"cave_mouth": Color("0c0a08"), "ladder": Color("8a6a3a"),
}

var map: MapData


## The ground key for a cell: water gets banks where it meets land, others a variant by spot.
static func ground_key(m: MapData, c: Vector2i) -> String:
	var kind := m.tile(c)
	if kind == "water":
		var mask := 0
		for side in [[Vector2i.UP, PlaceholderArt.WATER_N], [Vector2i.RIGHT, PlaceholderArt.WATER_E],
				[Vector2i.DOWN, PlaceholderArt.WATER_S], [Vector2i.LEFT, PlaceholderArt.WATER_W]]:
			if m.tile(c + side[0]) != "water":
				mask |= side[1]
		return "ground:water:%d" % mask
	return "ground:%s:%d" % [kind, posmod(c.x * 7 + c.y * 13 + (c.x * c.y) % 5, PlaceholderArt.GROUND_VARIANTS)]


func _draw() -> void:
	for y in map.h:
		for x in map.w:
			var c := Vector2i(x, y)
			draw_texture(PlaceholderArt.tex(ground_key(map, c)), Vector2(c * T))
			if map.tile(c) == "wall":
				draw_rect(Rect2(Vector2(c * T), Vector2(T, T)), COLORS.wall)
	for p in map.props:
		var r := Rect2(Vector2(p.cell * T), Vector2(p.size * T))
		draw_rect(r.grow(-1), COLORS.get(p.kind, Color.MAGENTA))
	for door in map.doors:
		for c in door.cells:
			if map.in_bounds(c):
				draw_rect(Rect2(Vector2(c * T), Vector2(T, T)).grow(-2), COLORS.door)
