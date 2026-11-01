class_name MapView
extends Node2D
## Draws a map other than the farm in the flat view: its ground tiles, then walls, props and
## doors as flat boxes (like FarmView marks the farm buildings). Outdoors, snow lying
## (show_snow / set_snow) goes over the ground under the props, as on the farm, and a second
## overlay whitens the roofs seen from above.

const T := 16
const COLORS := {
	"wall": Color("6a5a48"), "door": Color("4a2a14"), "futon": Color("e8e2d0"),
	"low_table": Color("5a3a24"), "tansu": Color("3e3028"), "andon": Color("ffe6a8"),
	"kamado": Color("c8b498"), "mizuya": Color("4a3424"), "nagamochi": Color("8a6a48"), "kotatsu": Color("3a4a7a"),
	"village_house": Color("a0522d"), "torii": Color("c8442c"), "hokora": Color("8a6a48"),
	"stone_lantern": Color("9a968e"), "pine": Color("2f5a34"), "bamboo": Color("6e9c42"),
	"counter": Color("4a3424"), "shelf": Color("6a4a30"), "rice_sacks": Color("d8c088"),
	"forge": Color("7a746c"), "anvil": Color("2a2a2e"), "tool_rack": Color("8a6a48"), "water_tub": Color("2a4a5a"), "river_rock": Color("6e6a62"),
	"feed_box": Color("9a7048"), "nest": Color("d8bc78"), "incubator": Color("c8a868"),
	"feed_sack": Color("a88a52"), "hatch": Color("4a2a14"),
	"fodder_box": Color("8a6440"), "stalls": Color("d0b478"), "hay": Color("c8b060"), "barn_gate": Color("4a2a14"),
	"cave_mouth": Color("0c0a08"), "ladder": Color("8a6a3a"),
	"irori": Color("8a847a"), "tokonoma": Color("c9a26b"), "butsudan": Color("1a1616"), "zabuton": Color("8a3a3a"),
	"byobu": Color("e8dcb8"), "toy_box": Color("c8442c"), "mizugame": Color("6a4028"),
}

var map: MapData
## How much snow each cell holds (SnowLayer.map_mask_image), set by show_snow.
var snow_mask: Image
var _snow: Sprite2D          # on the ground, under the props
var _roof_snow: Sprite2D     # on the roofs, over the props
var _objects: Node2D         # props and doors, above the ground snow


## The ground key for a cell: water gets banks where it meets land, others a variant by spot.
## Water at the map's edge has no bank there (the river flows on off the map).
static func ground_key(m: MapData, c: Vector2i) -> String:
	var kind := m.tile(c)
	if kind == "water":
		var mask := 0
		for side in [[Vector2i.UP, PlaceholderArt.WATER_N], [Vector2i.RIGHT, PlaceholderArt.WATER_E],
				[Vector2i.DOWN, PlaceholderArt.WATER_S], [Vector2i.LEFT, PlaceholderArt.WATER_W]]:
			var n: Vector2i = c + side[0]
			if m.in_bounds(n) and m.tile(n) != "water":
				mask |= side[1]
		return "ground:water:%d" % mask
	return "ground:%s:%d" % [kind, posmod(c.x * 7 + c.y * 13 + (c.x * c.y) % 5, PlaceholderArt.GROUND_VARIANTS)]


func _ready() -> void:
	_objects = Node2D.new()
	_objects.draw.connect(_draw_objects)
	add_child(_objects)


## Lays snow over an outdoor map by `rules` (data/snow_cover.json); nothing under a roof.
## Call once, then set_snow.
func show_snow(rules: Dictionary) -> void:
	if not SnowLayer.map_has_snow(map):
		return
	snow_mask = SnowLayer.map_mask_image(map, rules)
	_snow = _snow_sprite(snow_mask)
	add_child(_snow)
	move_child(_snow, _objects.get_index())
	_roof_snow = _snow_sprite(SnowLayer.roof_mask_image(map, rules))
	add_child(_roof_snow)
	move_child(_roof_snow, _objects.get_index() + 1)


## Snow on the ground and roofs, 0 (none) .. 1 (all white where the ground holds it).
func set_snow(cover: float) -> void:
	for s in [_snow, _roof_snow]:
		if s != null:
			(s.material as ShaderMaterial).set_shader_parameter("cover", cover)
			s.visible = cover > 0.0


func _snow_sprite(mask: Image) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.scale = Vector2.ONE * float(T) / SnowLayer.MASK_PER_CELL
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.texture = ImageTexture.create_from_image(mask)
	s.material = SnowLayer.canvas_material()
	return s


func _draw() -> void:
	for y in map.h:
		for x in map.w:
			var c := Vector2i(x, y)
			draw_texture(PlaceholderArt.tex(ground_key(map, c)), Vector2(c * T))
			if map.tile(c) == "wall":
				draw_rect(Rect2(Vector2(c * T), Vector2(T, T)), COLORS.wall)


func _draw_objects() -> void:
	for p in map.props:
		if p.kind in StoryView.KINDS:   # drawn as pictures by StoryView
			continue
		var r := Rect2(Vector2(p.cell * T), Vector2(p.size * T))
		_objects.draw_rect(r.grow(-1), COLORS.get(p.kind, Color.MAGENTA))
	for door in map.doors:
		for c in door.cells:
			if map.in_bounds(c):
				_objects.draw_rect(Rect2(Vector2(c * T), Vector2(T, T)).grow(-2), COLORS.door)
