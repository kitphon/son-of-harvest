class_name KoiPondView
extends Node2D
## Koi in the temple garden's pond, in the flat view (rules: KoiPondRules, data/koi.json;
## pictures: KoiPondArt; the 3D view's is KoiPondLayer). Each fish its picture turned to its
## heading about its middle, at the fish's spot in whole pixels, tinted by the water over it, and
## under the water's moving skin (main_2d puts this node under MapView's water). It takes the
## world's light (FlatLight). Made only for a map with a pond in data/koi.json.

const T := 16

var map: MapData
var schools: Array[KoiPondRules] = []
var _season := ""


func setup(m: MapData) -> KoiPondView:
	map = m
	name = "KoiPond"
	return self


func _ready() -> void:
	add_to_group(FlatLight.GROUP)
	_make()


func _make() -> void:
	schools.clear()
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	_season = game.season_name() if game != null else "spring"
	var ponds := KoiPondRules.ponds_on(map.id)
	for i in ponds.size():
		schools.append(KoiPondRules.make(map, ponds[i], _season, hash(map.id) + i * 101))


func _process(delta: float) -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if game != null and game.season_name() != _season:
		_make()
	var farmer: Variant = (game.maps.pos / float(T)) if game != null and game.maps.id == map.id else null
	for school in schools:
		school.step(delta, farmer)
	queue_redraw()


func _draw() -> void:
	for school in schools:
		for f in school.fish:
			var tex := PlaceholderArt.tex("pondkoi:%s:%d" % [f.pattern, KoiPondRules.frame_of(f)])
			var at: Vector2 = ((f.pos as Vector2) * T).round()
			draw_set_transform(at, float(f.heading), Vector2.ONE)
			draw_texture(tex, -Vector2(tex.get_size()) / 2.0, FlatLight.at(at, 0, FlatLight.field_px()) * KoiPondRules.TINT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## How many fish swim here (for tests).
func fish_count() -> int:
	var n := 0
	for school in schools:
		n += school.fish.size()
	return n
