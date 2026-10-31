class_name VillagerView
extends Node2D
## The villagers on one map in the flat view: their sprites at their plan's place now
## (Villagers.on_map), feet on the spot, redrawn every frame. Made fresh with the map's view.

const T := 16

var map_id := ""
var _sprites := {}   # villager id -> Sprite2D


func _init(map: String) -> void:
	map_id = map


func _ready() -> void:
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	var seen := {}
	for w in Villagers.on_map(map_id, Game.day_minutes(), Game.trigger_state(Vector2i.ZERO)):
		seen[w.id] = true
		var s: Sprite2D = _sprites.get(w.id)
		if s == null:
			s = Sprite2D.new()
			s.centered = false
			s.offset = Vector2(-8, -21)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(s)
			_sprites[w.id] = s
		s.visible = true
		s.position = w.pos * T
		var key := Villagers.sprite_key(w)
		if key.ends_with(":work:1") and s.get_meta("key", "") != key:
			Sfx.play("build_knock")   # each blow of the hammer, heard on this map
		s.set_meta("key", key)
		s.texture = PlaceholderArt.tex(key)
		s.flip_h = FarmerAnim.is_mirrored(w.facing)
	for id in _sprites:
		if not seen.has(id):
			_sprites[id].visible = false


func shown() -> Array:
	return _sprites.keys().filter(func(id): return _sprites[id].visible)
