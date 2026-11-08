class_name MapView
extends Node2D
## Draws a map other than the farm in the flat view: its ground tiles, then walls, props and
## doors as flat boxes (like FarmView marks the farm buildings). Outdoors, snow lying
## (show_snow / set_snow) goes over the ground under the props, as on the farm, and a second
## overlay whitens the roofs seen from above.

const T := 16
const CROP_PATCHES := "res://scripts/world/crop_patches.gd"   # loaded when drawn: it needs the autoloads
const FLAT_LIGHT := "res://scripts/world/flat_light.gd"       # the same (the paddies' rice takes the world's light)
const COLORS := {
	"wall": Color("6a5a48"), "door": Color("4a2a14"), "futon": Color("e8e2d0"),
	"low_table": Color("5a3a24"), "tansu": Color("3e3028"), "andon": Color("ffe6a8"),
	"kamado": Color("c8b498"), "mizuya": Color("4a3424"), "nagamochi": Color("8a6a48"), "kotatsu": Color("3a4a7a"),
	"village_house": Color("a0522d"), "torii": Color("c8442c"), "hokora": Color("8a6a48"),
	"stone_lantern": Color("9a968e"), "pine": Color("2f5a34"), "bamboo": Color("6e9c42"),
	"well": Color("8e8a80"), "jizo": Color("c8342c"), "persimmon": Color("e8782a"), "sakura": Color("f2bccb"), "maple": Color("c42a1e"),
	"hasa": Color("d8b85a"), "woodpile": Color("8a6440"), "garden": Color("5a9a3a"), "wood_fence": Color("b08a5a"), "kiln": Color("9a7656"),
	"counter": Color("4a3424"), "shelf": Color("6a4a30"), "rice_sacks": Color("d8c088"),
	"forge": Color("7a746c"), "anvil": Color("2a2a2e"), "tool_rack": Color("8a6a48"), "water_tub": Color("2a4a5a"), "river_rock": Color("6e6a62"), "ferry_boat": Color("8a6440"), "landing": Color("9a7650"),
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
var _water: WaterView        # the moving skin on the water cells, over the ground
var season := "spring"       # the season the maples and the paddies' rice are drawn in (set_season)
var snow_rules: Dictionary = {}   # data/snow_cover.json, set by show_snow (what the paddies hold)
var _tall := false           # paddies stand (their rice sways while the wind blows)
var _sway := {}              # the sway handed to CropPatches.draw ({wind, t}, {} in still air)
var _glint := {}             # the water patches' glint time (CropPatches.glint_now; {} where no water shows)
var _cover := 0.0            # snow lying, 0..1 (set_snow): the paddies' rice stands where it is not white


## The picture key of a maple in the flat view: its season and whether the map lies under snow.
static func maple_key(snow: bool, season: String) -> String:
	return "tree:maple:%s:%d" % [season, 1 if snow else 0]


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
	_objects.add_to_group("flat_lit")   # FlatLight.GROUP: redrawn when the light changes
	add_child(_objects)
	if map != null:   # a map with water gets the moving skin (none on a house's floor)
		var water := WaterView.new()
		water.build(map.w, map.h, func(c: Vector2i) -> bool: return map.tile(c) == "water", false)
		if water.water_cells > 0:
			_water = water
			add_child(_water)
			move_child(_water, _objects.get_index())
		else:
			water.free()


## The season the maples are drawn in (the flat view calls it on each day's start).
func set_season(season_name: String) -> void:
	if season_name != season:
		season = season_name
		_objects.queue_redraw()
		queue_redraw()   # the paddies' ground changes with the season (ground_key_in)


## Lays snow over an outdoor map by `rules` (data/snow_cover.json); nothing under a roof.
## Call once, then set_snow.
func show_snow(rules: Dictionary) -> void:
	snow_rules = rules
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
	if not is_equal_approx(cover, _cover):
		_cover = cover
		if _objects != null:
			_objects.queue_redraw()
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
	var paddies := paddy_cells()
	for y in map.h:
		for x in map.w:
			var c := Vector2i(x, y)
			draw_texture(PlaceholderArt.tex(ground_key_in(c, paddies)), Vector2(c * T))
			if map.tile(c) == "wall":
				draw_rect(Rect2(Vector2(c * T), Vector2(T, T)), COLORS.wall)


## The ground picture of cell `c` as the flat view draws it: a paddy cell that grows rice (`paddies`,
## paddy_cells) gets the calm picture CropPatches.paddy_ground gives, so the rice and the winter
## water patches read on it; every other cell is ground_key.
func ground_key_in(c: Vector2i, paddies: Dictionary) -> String:
	return ground_key_at(map, c, season, paddies)


## The same ground key for any map and season, shared with the 3D view (MapWorld.ground_keys):
## a paddy cell in `paddies` (paddy_cells_in) gets CropPatches.paddy_ground, every other cell
## is ground_key.
static func ground_key_at(m: MapData, c: Vector2i, season_name: String, paddies: Dictionary) -> String:
	var key := ground_key(m, c)
	if paddies.has(c):
		return (load(CROP_PATCHES) as GDScript).paddy_ground(season_name, key)
	return key


## The paddy cells with no prop and the rice they grow this season (CropClusters.paddy_key;
## empty in winter): cell -> cluster key.
func paddy_cells() -> Dictionary:
	return paddy_cells_in(map, season)


## paddy_cells for any map and season, shared with the 3D view (MapWorld._plant_paddies).
static func paddy_cells_in(m: MapData, season_name: String) -> Dictionary:
	var cells := {}
	var key: String = (load(CROP_PATCHES) as GDScript).paddy_key(season_name)
	if key == "":
		return cells
	for y in m.h:
		for x in m.w:
			var c := Vector2i(x, y)
			if m.tile(c) == "paddy" and m.prop_at(c).is_empty():
				cells[c] = key
	return cells


## The paddies' rice, under the props; the plants on white ground are left out (as in 3D).
func paddy_hold(c: Vector2i) -> float:
	return SnowLayer.map_hold(map, c, snow_rules)


func _sway_for(seconds: float) -> Dictionary:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	return (load(CROP_PATCHES) as GDScript).sway_now(game.wind_strength() if game != null else 0.0, seconds)


## The water patches' glint on the same wind, kept to its own frame rate; {} in seasons with no water.
func _glint_for(seconds: float) -> Dictionary:
	var crops := load(CROP_PATCHES) as GDScript
	if not crops.water_on(season):
		return {}
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	return crops.glint_now(game.wind_strength() if game != null else 0.0, seconds)


## Redraws the objects when the swaying paddies or the water's glint move on a frame (a few times a second).
func _process(_delta: float) -> void:
	if _tall and _objects != null:
		var now := Time.get_ticks_msec() / 1000.0
		if _sway_for(now) != _sway or _glint_for(now) != _glint:
			_objects.queue_redraw()


func _draw_objects() -> void:
	var paddies := paddy_cells()
	_tall = not paddies.is_empty()
	var now := Time.get_ticks_msec() / 1000.0
	_sway = _sway_for(now)
	_glint = _glint_for(now)
	if _tall:
		# The winter water patches lie under the stubble (CropPatches.draw_water: winter only), each with its glint.
		(load(CROP_PATCHES) as GDScript).draw_water(_objects, season, paddies, paddy_hold, _cover, _glint)
		(load(CROP_PATCHES) as GDScript).draw(_objects, paddies, paddy_hold, _cover, _sway, Callable(load(FLAT_LIGHT), "at_mid"))
	for p in map.props:
		if p.kind in StoryView.KINDS:   # drawn as pictures by StoryView
			continue
		if p.kind == "maple":   # a small tree picture, its foot on the cell's middle (PlaceholderArt "tree:")
			var tex := PlaceholderArt.tex(maple_key(SnowLayer.map_has_snow(map), season))
			_objects.draw_texture(tex, Vector2(p.cell * T) + Vector2(T / 2 - 12, T - 32))
			continue
		var r := Rect2(Vector2(p.cell * T), Vector2(p.size * T))
		if p.kind == "village_house":   # a painted kawara roof, the old box's size (RoofArt)
			var style := LitSpots.village_style(p)
			var inner := r.grow(-1)
			_objects.draw_texture(PlaceholderArt.tex(RoofArt.key("kawara", style.roof, style.storeys, Vector2i(inner.size))), inner.position)
			continue
		if p.kind == "ferry_boat" or p.kind == "landing":
			_draw_river_wood(p.kind, r)
			continue
		var fill: Color = COLORS.get(p.kind, Color.MAGENTA)
		if p.kind == "water_tub" and p.has("color"):   # a tub of its own water (Shino's indigo vats)
			fill = Color(str(p.color))
		_objects.draw_rect(r.grow(-1), fill)
	for door in map.doors:
		for c in door.cells:
			if map.in_bounds(c):
				_objects.draw_rect(Rect2(Vector2(c * T), Vector2(T, T)).grow(-2), COLORS.door)

## Mio's ferry boat (a wooden hull with dark gunwales, its floor and seats inside, a raised bow
## at the east end, the pole lying along it) or her plank landing over the water, in pixels.
func _draw_river_wood(kind: String, r: Rect2) -> void:
	var o := Color("2a1e14")
	if kind == "landing":
		var deck := Rect2(r.position.x + 1, r.position.y - 5, r.size.x - 2, r.size.y + 3)
		_objects.draw_rect(deck.grow(1), o)
		for i in 6:
			var x := deck.position.x + i * deck.size.x / 6.0
			_objects.draw_rect(Rect2(x, deck.position.y, deck.size.x / 6.0 - 1, deck.size.y), Color("9a7650") if i % 2 == 0 else Color("7a5a3a"))
		_objects.draw_rect(Rect2(deck.end.x - 3, deck.end.y - 7, 3, 7), Color("4a3424"))   # the mooring post
		return
	var hull := Rect2(r.position.x + 2, r.get_center().y - 5, r.size.x - 8, 10)
	_objects.draw_rect(hull.grow(1), o)
	_objects.draw_rect(hull, Color("8a6440"))
	_objects.draw_rect(hull.grow(-2), Color("4a3424"))                      # the floor inside
	_objects.draw_colored_polygon(PackedVector2Array([hull.end - Vector2(0, 10), Vector2(hull.end.x + 6, hull.get_center().y), hull.end]), o)
	_objects.draw_colored_polygon(PackedVector2Array([Vector2(hull.end.x, hull.position.y + 1), Vector2(hull.end.x + 4, hull.get_center().y), Vector2(hull.end.x, hull.end.y - 1)]), Color("8a6440"))
	for x in [hull.position.x + 9, hull.end.x - 10]:                       # the seats
		_objects.draw_rect(Rect2(x, hull.position.y + 1, 3, hull.size.y - 2), Color("5e4228"))
	_objects.draw_rect(Rect2(hull.position.x + 3, hull.get_center().y - 1, hull.size.x - 2, 2), Color("b89a68"))   # the pole
