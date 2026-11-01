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
		_show_hold(s, str(w.get("hold", "")))
	for id in _sprites:
		if not seen.has(id):
			_sprites[id].visible = false


## An item an event has the villager hold (a contest entry) rests on top of their head.
func _show_hold(s: Sprite2D, item: String) -> void:
	var h: Sprite2D = s.get_node_or_null("Hold")
	if item == "":
		if h != null:
			h.visible = false
		return
	var tex := PlaceholderArt.tex(PlaceholderArt.world_item_key(item))
	if h == null:
		h = Sprite2D.new()
		h.name = "Hold"
		h.centered = false
		h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.add_child(h)
	h.texture = tex
	h.set_meta("item", item)
	h.offset = Vector2(-tex.get_width() / 2.0, -20 - tex.get_height())
	h.visible = true


## The item villager `id` holds overhead now ("" for none; for tests).
func held_by(id: String) -> String:
	var s: Sprite2D = _sprites.get(id)
	var h: Sprite2D = s.get_node_or_null("Hold") if s != null and s.visible else null
	return str(h.get_meta("item", "")) if h != null and h.visible else ""


func shown() -> Array:
	return _sprites.keys().filter(func(id): return _sprites[id].visible)
