class_name CradleView
extends Node2D
## The baby's bamboo cradle in the flat view (rules: Child, BabyActions; the 3D view's is
## CradleLayer): the cradle prop of the current map (data/maps/house.json, shown while the child
## is a baby) as its PlaceholderArt "child:cradle:" picture, centred in its cell and standing on
## the bottom edge like the story props. The baby in it sleeps or wakes by the clock
## (Child.cradle_look) and the cradle is empty while the farmer holds them; both are read every
## frame, so it shows the moment the baby is born or lifted. MapView leaves the prop out of its boxes.

const T := 16

var _key := ""
var _cell := Vector2i.ZERO


func _init() -> void:
	name = "Cradle"


func _ready() -> void:
	add_to_group(FlatLight.GROUP)   # the picture takes the world's light (redrawn when it changes)
	refresh()


func _process(_delta: float) -> void:
	refresh()


## The picture shown now ("" for none).
func key() -> String:
	return _key


func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node("Game")
	var p: Dictionary = game.cradle_prop(game.maps.id)
	var k := ""
	if not p.is_empty():
		_cell = Vector2i(p.cell)
		k = Child.cradle_key("empty" if game.baby_held else Child.cradle_look(int(game.day_minutes())), game.child_look())
	if k != _key:
		_key = k
		queue_redraw()


func _draw() -> void:
	if _key == "":
		return
	var tex := PlaceholderArt.tex(_key)
	var r := Rect2(Vector2(_cell * T), Vector2(T, T))
	draw_texture(tex, Vector2(roundf(r.get_center().x - tex.get_width() / 2.0), r.end.y - tex.get_height() - 1),
		FlatLight.at(Vector2(r.get_center().x, r.end.y - 1), tex.get_height(), FlatLight.field_px()))
