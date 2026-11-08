class_name FarmView
extends Node2D
## Draws a FarmGrid: ground tiles and field sprites from PlaceholderArt, buildings as boxes.
## Snow lying on the ground (show_snow / set_snow) goes between the two: a SnowLayer overlay
## over the ground, under the sprites and buildings, so plots and crops stay readable.

const T := 16
const CROP_PATCHES := "res://scripts/world/crop_patches.gd"   # loaded when drawn: it needs the autoloads
const COLORS := {
	"fence": Color("b08a5a"), "house": Color("a0522d"), "door": Color("4a2a14"),
	"bin": Color("7a6a50"), "stand": Color("d9b45a"), "chest": Color("8a5a32"),
	"coop": Color("8a6a48"), "coop_door": Color("4a2a14"),
	"barn": Color("6a4a30"), "barn_door": Color("3a2010"),
}

## The farm buildings drawn as painted roofs (RoofArt), by the material the 3D view roofs them in:
## the farmhouse and the coop thatch, the barn kawara tile.
const ROOFS := {"house": "kaya", "coop": "thatch", "barn": "kawara"}


## The pixel rectangle of the fixed cells of `kind` (empty when there are none).
static func roof_rect(grid: FarmGrid, kind: String) -> Rect2:
	var box := Rect2i()
	var first := true
	for c in grid.fixed:
		if grid.fixed[c] == kind:
			box = Rect2i(c, Vector2i.ONE) if first else box.expand(c).expand(c + Vector2i.ONE)
			first = false
	return Rect2(Vector2(box.position * T), Vector2(box.size * T))


## Ground only (soil, water, building footprints): the 3D view uses this as the ground
## texture and stands everything else up as sprites / boxes.
var ground_only := false
var gaps: Array[Vector2i] = []   # fence cells left open (the gate), drawn as plain ground

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
## A thrown item's landing cell while it is still in the air (main_2d), not drawn yet.
var hidden_item := Vector2i(-1, -1):
	set(value):
		hidden_item = value
		if _objects != null:
			_objects.queue_redraw()


var _water: WaterView        # the moving skin on the pond (over the ground, under the objects)
var _tall := false           # the last draw had tall crops (they sway while the wind blows)
var _sway := {}              # the sway handed to CropPatches.draw ({wind, t}, {} in still air)


func _ready() -> void:
	if ground_only:
		return
	_objects = Node2D.new()
	_objects.draw.connect(_draw_objects)
	add_child(_objects)
	if farm != null:   # the pond's moving skin (none on a farm without one)
		var water := WaterView.new()
		water.build(FarmGrid.W, FarmGrid.H, func(c: Vector2i) -> bool: return farm.fixed_at(c) == "pond", true)
		if water.water_cells > 0:
			_water = water
			add_child(_water)
			move_child(_water, _objects.get_index())
		else:
			water.free()


## The tall crops' sway at a time: the wind (Game.wind_strength) kept to the sway's frame rate.
func _sway_for(seconds: float) -> Dictionary:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var patches: GDScript = load(CROP_PATCHES)
	return patches.sway_now(game.wind_strength() if game != null else 0.0, seconds)


## Redraws the objects when the swaying crops move on a frame (a few times a second).
func _process(_delta: float) -> void:
	if _tall and _objects != null and _sway_for(Time.get_ticks_msec() / 1000.0) != _sway:
		_objects.queue_redraw()


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
	_tall = false
	_sway = _sway_for(Time.get_ticks_msec() / 1000.0)
	for kind in ROOFS:   # the roofs first: the doors in their front rows are drawn over them below
		var r := roof_rect(farm, kind)
		if r.has_area():
			_objects.draw_texture(PlaceholderArt.tex(RoofArt.key(ROOFS[kind], "gable", 1, Vector2i(r.size))), r.position)
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			_draw_cell(Vector2i(x, y))


func _draw_cell(c: Vector2i) -> void:
	var r := Rect2(Vector2(c * T), Vector2(T, T))
	var f := farm.fixed_at(c)
	if f != "":
		# The flat view marks buildings and the fence on top of their ground (roofs: _draw_objects).
		if f != "pond" and not f in ROOFS and not c in gaps:
			_objects.draw_rect(r.grow(-5) if f == "fence" else r, COLORS[f])
		return
	var d := farm.cell(c)
	# Same sprites as the 3D view, standing on the cell's bottom edge (tall ones overlap the
	# cell above).
	var key := PlaceholderArt.cell_key(farm, d)
	var patches: GDScript = load(CROP_PATCHES)   # tall crops: several small plants, as in 3D (CropPatches)
	var cluster: String = patches.cluster_key(key)
	if cluster != "":
		_tall = true
		patches.draw(_objects, {c: cluster}, Callable(), 0.0, _sway)
	elif key != "":
		var tex := PlaceholderArt.tex(key)
		_objects.draw_texture(tex, r.position + Vector2(0, T - tex.get_height()))
	if farm.item_at(c) != "" and c != hidden_item:   # put down or thrown: lying in the middle of the cell
		var it := PlaceholderArt.tex(PlaceholderArt.world_item_key(farm.item_at(c)))
		_objects.draw_texture(it, r.position + (Vector2(T, T) - it.get_size()) / 2.0 + Vector2(0, 2))
