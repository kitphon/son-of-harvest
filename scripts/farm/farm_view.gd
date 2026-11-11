class_name FarmView
extends Node2D
## Draws a FarmGrid: ground tiles and field sprites from PlaceholderArt, buildings as boxes.
## Snow lying on the ground (show_snow / set_snow) goes between the two: a SnowLayer overlay
## over the ground, under the sprites and buildings, so plots and crops stay readable.
## The crops, their plants and the items lying on the field take the world's light (FlatLight,
## by the 3D sprites' rules); the ground, fences, roofs and doors do not (the 3D view's meshes).

const T := 16
const CROP_PATCHES := "res://scripts/world/crop_patches.gd"   # loaded when drawn: it needs the autoloads
const FLAT_LIGHT := "res://scripts/world/flat_light.gd"       # the same
const COLORS := {
	"fence": Color("b08a5a"), "house": Color("a0522d"), "door": Color("4a2a14"),
	"bin": Color("7a6a50"), "stand": Color("d9b45a"), "chest": Color("8a5a32"),
	"coop": Color("8a6a48"), "coop_door": Color("4a2a14"),
	"barn": Color("6a4a30"), "barn_door": Color("3a2010"),
	"silo": Color("a0764a"),
}

## The farm buildings drawn as painted roofs (RoofArt), by the material the 3D view roofs them in:
## the farmhouse and the coop thatch, the barn kawara tile.
const ROOFS := {"house": "kaya", "coop": "thatch", "barn": "kawara"}

## The greenhouse drawn from above (_draw_greenhouse), in pixels from its box's top: the ridge
## board's top, the wall under the roof's foot (glass over the board skirting) and the skirting.
const GREENHOUSE_RIDGE := 14.0
const GREENHOUSE_WALL := 12.0
const GREENHOUSE_SKIRT := 5.0


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
var _roof_snow: Sprite2D     # on the buildings' roofs, over the objects (SnowLayer.farm_roof_mask_image)
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
	_objects.add_to_group("flat_lit")   # FlatLight.GROUP: redrawn when the light changes
	add_child(_objects)
	if farm != null:   # the pond's moving skin (none on a farm without one)
		var water := WaterView.new()
		water.build(farm.w, farm.h, func(c: Vector2i) -> bool: return farm.fixed_at(c) == "pond", true)
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
		# The roofs (the farmhouse, coop, barn, silo, greenhouse) whiten over the objects, as a
		# map's houses do in MapView.
		# A mask pixel a picture pixel, so the snow keeps to the roofs as drawn (their eaves, the
		# doors, the greenhouse's rafters), filling them as the 3D view's snow tops do.
		_roof_snow = Sprite2D.new()
		_roof_snow.centered = false
		_roof_snow.scale = Vector2.ONE * float(T) / SnowLayer.ROOF_PER_CELL
		_roof_snow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_roof_snow.texture = ImageTexture.create_from_image(SnowLayer.farm_roof_mask_image(farm, rules))
		_roof_snow.material = SnowLayer.roof_canvas_material()
		add_child(_roof_snow)
		move_child(_roof_snow, _objects.get_index() + 1)


## Puts `n` over the buildings but under their roofs' snow (NightView's glow on the greenhouse's
## glass roof, which the snow lying on it covers).
func add_under_roof_snow(n: CanvasItem) -> void:
	add_child(n)
	if _objects != null:
		move_child(n, _objects.get_index() + 1)


## Snow on the ground, 0 (none) .. 1 (all white where the ground holds it).
func set_snow(cover: float) -> void:
	for s in [_snow, _roof_snow]:
		if s != null:
			(s.material as ShaderMaterial).set_shader_parameter("cover", cover)
			s.visible = cover > 0.0


func _on_cells_changed() -> void:
	queue_redraw()
	if _objects != null:
		_objects.queue_redraw()
	if _snow != null:
		snow_mask = SnowLayer.mask_image(farm, _snow_rules)
		(_snow.texture as ImageTexture).update(snow_mask)
	if _roof_snow != null:   # a building put up (FarmGrid.set_wings) gets its roof's snow
		(_roof_snow.texture as ImageTexture).update(SnowLayer.farm_roof_mask_image(farm, _snow_rules))


func _draw() -> void:
	for y in farm.h:
		for x in farm.w:
			var c := Vector2i(x, y)
			draw_texture(PlaceholderArt.tex(PlaceholderArt.ground_key(farm, c)), Vector2(c * T))


func _draw_objects() -> void:
	_tall = false
	_sway = _sway_for(Time.get_ticks_msec() / 1000.0)
	for kind in ROOFS:   # the roofs first: the doors in their front rows are drawn over them below
		var r := roof_rect(farm, kind)
		if r.has_area():
			_objects.draw_texture(PlaceholderArt.tex(RoofArt.key(ROOFS[kind], "gable", 1, Vector2i(r.size))), r.position)
	_draw_silo()
	_draw_greenhouse()
	for y in farm.h:
		for x in farm.w:
			_draw_cell(Vector2i(x, y))


## The fodder silo, once built: a round wooden tower with iron hoops and a grey tiled cone (the
## 3D view's SiloProps), a little hatch low on the front.
func _draw_silo() -> void:
	var r := roof_rect(farm, "silo")
	if not r.has_area():
		return
	var o := r.position
	_objects.draw_rect(Rect2(o + Vector2(3, 12), Vector2(26, 19)), Color("a0764a"))
	for x in [8, 13, 19, 24]:   # the staves
		_objects.draw_rect(Rect2(o + Vector2(x, 12), Vector2(1, 19)), Color("86603a"))
	for y in [17, 24]:   # the hoops
		_objects.draw_rect(Rect2(o + Vector2(3, y), Vector2(26, 2)), Color("3a3430"))
	_objects.draw_rect(Rect2(o + Vector2(13, 24), Vector2(6, 7)), Color("3a2010"))
	_objects.draw_colored_polygon(PackedVector2Array([o + Vector2(16, 1), o + Vector2(31, 14), o + Vector2(1, 14)]), Color("55687a"))
	_objects.draw_line(o + Vector2(16, 1), o + Vector2(16, 14), Color("6d8397"), 1.0)
	_objects.draw_rect(Rect2(o + Vector2(15, 0), Vector2(2, 2)), Color("3a3430"))


## The greenhouse, once built (the 3D view's GreenhouseProps): a low gable roof of glass panes
## in a cedar grid seen from above, the ridge board along the middle, the back slope a shade
## darker than the front; under the front eave the board skirting and the glazed sliding door.
## Through the panes the green rows of the beds show.
func _draw_greenhouse() -> void:
	var r := roof_rect(farm, "greenhouse")
	if not r.has_area():
		return
	r = r.merge(Rect2(Vector2(FarmGrid.GREENHOUSE_DOOR * T), Vector2(T, T)))
	var o := r.position
	var wide := r.size.x
	var front := r.size.y - GREENHOUSE_WALL   # the roof's foot; the wall and the door below it
	var ridge := GREENHOUSE_RIDGE
	_objects.draw_rect(Rect2(o + Vector2(0, 1), Vector2(wide, front)), Color("7a5a3a"))   # the frame's edge
	for half in [[1.0, ridge, Color("a6c4bc")], [ridge + 2.0, front - 1.0, Color("bcd8d0")]]:
		var top: float = half[0]
		var bottom: float = half[1]
		_objects.draw_rect(Rect2(o + Vector2(1, top), Vector2(wide - 2, bottom - top)), half[2])
		for i in int(wide / 8):   # the green rows inside, seen through the panes
			_objects.draw_rect(Rect2(o + Vector2(3 + i * 8, top + 3), Vector2(4, bottom - top - 6)), Color("7aa86a") if i % 2 else Color("8cb67a"))
		for x in range(8, int(wide), 8):   # the rafters
			_objects.draw_rect(Rect2(o + Vector2(x, top), Vector2(1, bottom - top)), Color("8a6a48"))
		_objects.draw_line(o + Vector2(3, top + 2), o + Vector2(wide - 3, top + 2), Color("e4f0ea"), 1.0)   # a glint along the slope
	_objects.draw_rect(Rect2(o + Vector2(0, ridge), Vector2(wide, 2)), Color("6e4c30"))   # the ridge board
	_objects.draw_rect(Rect2(o + Vector2(0, ridge + 0.5), Vector2(wide, 1)), Color("2e221a"))
	var wall := o + Vector2(0, front)
	_objects.draw_rect(Rect2(wall, Vector2(wide, GREENHOUSE_WALL)), Color("b8d4cc"))   # the glazed front wall
	_objects.draw_rect(Rect2(wall + Vector2(0, GREENHOUSE_WALL - GREENHOUSE_SKIRT), Vector2(wide, GREENHOUSE_SKIRT)), Color("3e3028"))   # the board skirting
	for x in range(0, int(wide) + 1, 16):
		_objects.draw_rect(Rect2(wall + Vector2(clampf(x, 0, wide - 1), 0), Vector2(1, GREENHOUSE_WALL)), Color("6e4c30"))
	var door := Vector2(FarmGrid.GREENHOUSE_DOOR.x * T + 3, o.y + r.size.y - 14)
	_objects.draw_rect(Rect2(door, Vector2(10, 14)), Color("2a3a32"))
	_objects.draw_rect(Rect2(door + Vector2(1, 1), Vector2(8, 7)), Color("cfe4dc"))
	_objects.draw_rect(Rect2(door + Vector2(7, 9), Vector2(1, 2)), Color("1e1c1c"))



func _draw_cell(c: Vector2i) -> void:
	var r := Rect2(Vector2(c * T), Vector2(T, T))
	var f := farm.fixed_at(c)
	if f != "":
		# The flat view marks buildings and the fence on top of their ground (roofs: _draw_objects).
		if not f in ["pond", "silo", "greenhouse", "greenhouse_door"] and not f in ROOFS and not c in gaps:
			_objects.draw_rect(r.grow(-5) if f == "fence" else r, COLORS[f])
		return
	var d := farm.cell(c)
	# Same sprites as the 3D view, standing on the cell's bottom edge (tall ones overlap the
	# cell above).
	var key := PlaceholderArt.cell_key(farm, d)
	var patches: GDScript = load(CROP_PATCHES)   # tall crops: several small plants, as in 3D (CropPatches)
	var light: GDScript = load(FLAT_LIGHT)
	var px: float = light.field_px()
	var cluster: String = patches.cluster_key(key)
	if cluster != "":
		_tall = true
		patches.draw(_objects, {c: cluster}, Callable(), 0.0, _sway, Callable(light, "at_mid"))
	elif key != "":
		var tex := PlaceholderArt.tex(key)
		_objects.draw_texture(tex, r.position + Vector2(0, T - tex.get_height()),
			light.at(r.position + Vector2(T / 2.0, T), tex.get_height(), px))
	if farm.item_at(c) != "" and c != hidden_item:   # put down or thrown: lying in the middle of the cell
		var it := PlaceholderArt.tex(PlaceholderArt.world_item_key(farm.item_at(c)))
		var at := r.position + (Vector2(T, T) - it.get_size()) / 2.0 + Vector2(0, 2)
		_objects.draw_texture(it, at, light.at(at + Vector2(it.get_width() / 2.0, it.get_height()), it.get_height(), px))
