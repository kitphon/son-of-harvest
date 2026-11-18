class_name PondPlantLayer
extends Node3D
## The farm pond's irises and lily pads in 3D (PondPlantRules, data/pond_plants.json;
## pictures: PondPlantArt). Irises stand upright on the bank's slope where they grow, in
## the shallows; pads lie flat a hair over the water's skin (WaterSurface.LIFT), drawn at the
## ground's own pixel size like the koi, drawn after the skin. Made again each morning (the season, the flowers).

const PAD_PX := 1.0 / 16.0

var map_id := "farm"
var pond: PondShape


func _init(shape: PondShape, id := "farm") -> void:
	pond = shape
	map_id = id
	name = "PondPlants"


func _ready() -> void:
	var game := _game()
	if game != null:
		game.day_started.connect(_make)
	_make()


func _make() -> void:
	for n in get_children():
		n.free()
	var game := _game()
	var season: String = game.season_name() if game != null else "summer"
	var day: int = game.day if game != null else 10
	for spot in PondPlantRules.spots(map_id):
		var key := PondPlantRules.key(spot, season, day)
		if key == "":
			continue
		var s := FarmWorld.make_sprite(PlaceholderArt.tex(key))
		var at: Vector2 = spot.pos
		s.position = Vector3(at.x, height(spot, pond), at.y)
		if spot.kind == "lily":
			s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			s.axis = Vector3.AXIS_Y
			s.pixel_size = PAD_PX
			s.offset = Vector2.ZERO
			s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED   # blended, and after the water's skin (itself blended) so the skin never veils it
			s.render_priority = 1
		else:
			FarmWorld.upright(s)
		s.set_meta("pond_plant", spot.kind)
		add_child(s)


## How far below the land `spot` stands (world units, negative): irises on the bank's
## slope where they grow, pads just over the water's skin.
static func height(spot: Dictionary, shape: PondShape) -> float:
	if spot.kind == "lily":
		return -SunkenGround.DROP + 0.025
	return -SunkenGround.DROP * shape.sink(spot.pos)


## How many plants show now (tests).
func count(kind := "") -> int:
	return get_children().filter(func(n: Node) -> bool: return kind == "" or n.get_meta("pond_plant", "") == kind).size()


func _game() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
