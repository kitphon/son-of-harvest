class_name CradleLayer
extends Node3D
## The baby's bamboo cradle in 3D (rules: Child, BabyActions; the flat view's is CradleView): a
## camera-facing picture (PlaceholderArt "child:cradle:") standing on the cradle prop's cell of
## the map (data/maps/house.json, shown while the child is a baby), at the figures' pixel size.
## The baby in it sleeps or wakes by the clock and the cradle is empty while the farmer holds
## them; read every frame, so it shows the moment the baby is born or lifted. A layer of the
## visit (Main3D._add_layer), not a part of the kept world.

var map_id := ""
var sprite: Sprite3D


func _init(map: String) -> void:
	map_id = map
	name = "Cradle"


func _ready() -> void:
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	var p := Game.cradle_prop(map_id)
	if p.is_empty():
		if sprite != null:
			sprite.visible = false
		return
	var key := Child.cradle_key("empty" if Game.baby_held else Child.cradle_look(int(Game.day_minutes())), Game.child_look())
	if sprite == null:
		sprite = FarmWorld.make_sprite(PlaceholderArt.tex(key))
		sprite.pixel_size = FarmWorld.FIGURE_PX   # the figures' density, like the farmer holding the baby
		add_child(sprite)
	var r := Rect2(Vector2(p.cell), Vector2(p.size))
	sprite.position = Vector3(r.get_center().x, 0, r.get_center().y)
	sprite.visible = true
	if sprite.get_meta("key", "") != key:
		sprite.set_meta("key", key)
		sprite.texture = PlaceholderArt.tex(key)
		sprite.offset = Vector2(0, sprite.texture.get_height() / 2.0)
