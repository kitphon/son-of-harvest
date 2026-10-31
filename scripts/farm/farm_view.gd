class_name FarmView
extends Node2D
## Draws a FarmGrid: ground tiles and field sprites from PlaceholderArt, buildings as boxes.
## Snow lying on the ground (show_snow / set_snow) goes between the two: a SnowLayer overlay
## over the ground, under the sprites and buildings, so plots and crops stay readable.

const T := 16
const COLORS := {
	"fence": Color("b08a5a"), "house": Color("a0522d"), "door": Color("4a2a14"),
	"bin": Color("7a6a50"), "stand": Color("d9b45a"), "chest": Color("8a5a32"),
}

## Ground only (soil, water, building footprints): the 3D view uses this as the ground
## texture and stands everything else up as sprites / boxes.
var ground_only := false

var farm: FarmGrid:
	set(value):
		farm = value
		farm.cells_changed.connect(_on_cells_changed)
		queue_redraw()

## How much snow each cell holds (SnowLayer.mask_image), kept up to date while snow is shown.
var snow_mask: Image
var _snow: Sprite2D          # snow_mask stretched over the farm, drawn by the snow shader
var _snow_rules: Dictionary
var _objects: Node2D         # sprites and buildings, above the snow


func _ready() -> void:
	if ground_only:
		return
	_objects = Node2D.new()
	_objects.draw.connect(_draw_objects)
	add_child(_objects)


## Lays snow over the ground by `rules` (data/snow_cover.json). Call once, then set_snow.
func show_snow(rules: Dictionary) -> void:
	_snow_rules = rules
	_snow = Sprite2D.new()
	_snow.centered = false
	_snow.scale = Vector2.ONE * float(T) / SnowLayer.MASK_PER_CELL
	_snow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # kinds blend over 1/4 cell, as in 3D
	snow_mask = SnowLayer.mask_image(farm, rules)
	_snow.texture = ImageTexture.create_from_image(snow_mask)
	_snow.material = SnowLayer.canvas_material()
	add_child(_snow)
	if _objects != null:
		move_child(_snow, _objects.get_index())


## Snow on the ground, 0 (none) .. 1 (all white where the ground holds it).
func set_snow(cover: float) -> void:
	if _snow != null:
		(_snow.material as ShaderMaterial).set_shader_parameter("cover", cover)
		_snow.visible = cover > 0.0


func _on_cells_changed() -> void:
	queue_redraw()
	if _objects != null:
		_objects.queue_redraw()
	if _snow != null:
		snow_mask = SnowLayer.mask_image(farm, _snow_rules)
		(_snow.texture as ImageTexture).update(snow_mask)


func _draw() -> void:
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			var c := Vector2i(x, y)
			draw_texture(PlaceholderArt.tex(PlaceholderArt.ground_key(farm, c)), Vector2(c * T))


func _draw_objects() -> void:
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			_draw_cell(Vector2i(x, y))


func _draw_cell(c: Vector2i) -> void:
	var r := Rect2(Vector2(c * T), Vector2(T, T))
	var f := farm.fixed_at(c)
	if f != "":
		# The flat view marks buildings and the fence on top of their ground.
		if f != "pond":
			_objects.draw_rect(r.grow(-5) if f == "fence" else r, COLORS[f])
		return
	var d := farm.cell(c)
	# Same sprites as the 3D view, standing on the cell's bottom edge (tall ones overlap the
	# cell above).
	var key := PlaceholderArt.cell_key(farm, d)
	if key != "":
		var tex := PlaceholderArt.tex(key)
		_objects.draw_texture(tex, r.position + Vector2(0, T - tex.get_height()))
