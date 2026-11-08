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
			s.offset = Vector2(-PlaceholderArt.FIGURE_SIZE.x / 2, 2 - PlaceholderArt.FIGURE_SIZE.y)   # feet 2 px below the spot
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(s)
			_sprites[w.id] = s
		s.visible = true
		s.position = (w.pos - Vector2(0, float(w.get("lift", 0.0)))) * T   # lifted standing in the ferry boat
		var key := Villagers.sprite_key(w)
		if key.ends_with(":work:1") and s.get_meta("key", "") != key:
			Sfx.play("build_knock")   # each blow of the hammer, heard on this map
		elif key.ends_with(":post:1") and s.get_meta("key", "") != key:
			Sfx.play("letter_post")   # a letter slipped in at a door on Ren's round
		s.set_meta("key", key)
		s.texture = PlaceholderArt.tex(key)
		s.flip_h = FarmerAnim.is_mirrored(w.facing)
		# The world's light (FlatLight) on the figure and what it carries; the note puff keeps its picture.
		s.self_modulate = FlatLight.at(s.position, s.texture.get_height(), FlatLight.figure_px())
		_show_held(s, w)
		_show_note(s, w)
	for id in _sprites:
		if not seen.has(id):
			_sprites[id].visible = false


## What an event actor carries (`holds`) rests on top of their head; nothing, no sprite.
func _show_held(s: Sprite2D, w: Dictionary) -> void:
	var item := String(w.get("holds", ""))
	var held: Sprite2D = s.get_node_or_null("Held")
	if item == "":
		if held != null:
			held.visible = false
		return
	if held == null:
		held = Sprite2D.new()
		held.name = "Held"
		held.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.add_child(held)
	held.texture = PlaceholderArt.tex(PlaceholderArt.world_item_key(item))
	held.position = Vector2(0, 3 - PlaceholderArt.FIGURE_SIZE.y + PlaceholderArt.villager_top(w.id))   # on top of the head
	held.offset = Vector2(0, -held.texture.get_height() / 2.0)
	held.set_meta("item", item)
	held.self_modulate = s.self_modulate
	held.visible = true


## A music note rising over the head while the villager whistles (Whistles.puff_look).
func _show_note(s: Sprite2D, w: Dictionary) -> void:
	var p := Whistles.puff(w.id, Game.day_minutes())
	var note: Sprite2D = s.get_node_or_null("Note")
	if p < 0.0:
		if note != null:
			note.visible = false
		return
	if note == null:
		note = Sprite2D.new()
		note.name = "Note"
		note.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.add_child(note)
	var look := Whistles.puff_look(p)
	note.texture = PlaceholderArt.tex(look.key)
	note.position = Vector2(4.0 + look.sway, PlaceholderArt.villager_top(w.id) - PlaceholderArt.FIGURE_SIZE.y - 1.0 - look.rise).round()
	note.modulate.a = look.alpha
	note.visible = true


## Is a note puff showing over villager `id` now? (for tests)
func whistling(id: String) -> bool:
	var n: Node = _sprites[id].get_node_or_null("Note") if _sprites.has(id) and _sprites[id].visible else null
	return n != null and n.visible


## The item villager `id` carries overhead now ("" for none; for tests).
func held(id: String) -> String:
	var h: Node = _sprites[id].get_node_or_null("Held") if _sprites.has(id) and _sprites[id].visible else null
	return h.get_meta("item", "") if h != null and h.visible else ""


func shown() -> Array:
	return _sprites.keys().filter(func(id): return _sprites[id].visible)


## Where the shown villagers stand, {id: Vector2 cell position} (the footprints in snow).
func feet() -> Dictionary:
	var out := {}
	for id in _sprites:
		if _sprites[id].visible:
			out[id] = _sprites[id].position / T
	return out
