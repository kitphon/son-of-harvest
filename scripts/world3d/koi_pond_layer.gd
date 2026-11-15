class_name KoiPondLayer
extends Node3D
## Koi in the temple garden's pond, in 3D (rules: KoiPondRules, data/koi.json; pictures:
## KoiPondArt). One flat sprite a fish, lying on the sunk pond bed a hair under the water's skin
## (WaterSurface draws its glints and the winter ice over them), turned to the fish's heading,
## its tail frame by its beat. Unshaded like the other sprites, with the sun's share by the clock
## (SpriteLight) and tinted a little by the water over them (TINT). The school is made again when
## the season changes (fewer, slower fish in winter). Only a map with a pond in data/koi.json
## gets fish.

const TINT := KoiPondRules.TINT        # the water's green over the fish
const ABOVE_BED := 0.005                # over the sunk bed, under the skin (WaterSurface.LIFT 0.01)

var map: MapData
var schools: Array[KoiPondRules] = []
var _sprites: Array = []   # per school, its fish's Sprite3Ds
var _season := ""


func _init(m: MapData) -> void:
	map = m
	name = "KoiPond"


func _ready() -> void:
	_make()


func _make() -> void:
	for n in get_children():
		n.free()
	schools.clear()
	_sprites.clear()
	var game := _game()
	_season = game.season_name() if game != null else "spring"
	var ponds := KoiPondRules.ponds_on(map.id)
	for i in ponds.size():
		var school := KoiPondRules.make(map, ponds[i], _season, hash(map.id) + i * 101)
		schools.append(school)
		var list: Array[Sprite3D] = []
		for f in school.fish:
			var s := FarmWorld.make_sprite(PlaceholderArt.tex("pondkoi:%s:1" % f.pattern))
			s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			s.axis = Vector3.AXIS_Y
			s.pixel_size = 1.0 / 16.0
			s.offset = Vector2.ZERO
			s.modulate = TINT
			add_child(s)
			list.append(s)
		_sprites.append(list)
	_place_all()


func _process(delta: float) -> void:
	var game := _game()
	if game != null and game.season_name() != _season:
		_make()
		return
	var farmer: Variant = (game.maps.pos / 16.0) if game != null and game.maps.id == map.id else null
	for school in schools:
		school.step(delta, farmer)
	_place_all()


func _place_all() -> void:
	for i in schools.size():
		var school: KoiPondRules = schools[i]
		for j in school.fish.size():
			var f: Dictionary = school.fish[j]
			var s: Sprite3D = _sprites[i][j]
			s.position = Vector3(f.pos.x, -SunkenGround.DROP + ABOVE_BED, f.pos.y)
			s.rotation = Vector3(0, -float(f.heading), 0)
			s.texture = PlaceholderArt.tex("pondkoi:%s:%d" % [f.pattern, KoiPondRules.frame_of(f)])


func _game() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")


## How many fish swim here (for tests).
func fish_count() -> int:
	var n := 0
	for school in schools:
		n += school.fish.size()
	return n
