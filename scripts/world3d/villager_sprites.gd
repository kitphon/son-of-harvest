class_name VillagerSprites
extends Node3D
## The villagers on one map in 3D: a camera-facing sprite with a shadow for everyone whose
## plan puts them on this map now (Villagers.on_map), moved every frame. Made fresh with the
## map's world, so entering a map places them where their plans say (the catch-up).

var map_id := ""
var _sprites := {}   # villager id -> Sprite3D


func _init(map: String) -> void:
	map_id = map


func _ready() -> void:
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	var here := Villagers.on_map(map_id, Game.day_minutes(), Game.trigger_state(Vector2i.ZERO))
	var seen := {}
	for w in here:
		seen[w.id] = true
		var s: Sprite3D = _sprites.get(w.id)
		if s == null:
			s = FarmWorld.make_figure(PlaceholderArt.tex(Villagers.sprite_key(w)))
			NightLights.figure(s)
			s.add_to_group(Parting.GROUP)   # the grass and crops part round them
			s.add_to_group(BreathLayer.GROUP)   # and they breathe in the cold
			SpriteShadow.attach(s)
			add_child(s)
			_sprites[w.id] = s
		s.visible = true
		s.position = Vector3(w.pos.x, float(w.get("lift", 0.0)), w.pos.y)   # lifted standing in the ferry boat
		var key := Villagers.sprite_key(w)
		if key.ends_with(":work:1") and s.get_meta("key", "") != key:
			Sfx.play("build_knock")   # each blow of the hammer, heard on this map
		elif key.ends_with(":post:1") and s.get_meta("key", "") != key:
			Sfx.play("letter_post")   # a letter slipped in at a door on Ren's round
		s.set_meta("key", key)
		s.set_meta("bird_scare", BirdRules.scares(str(w.id), str(w.get("stage", ""))))   # the crawler startles no birds (FarmWorld.set_farmer)
		s.set_meta("facing", Vector2(w.facing))   # for the breath (BreathLayer)
		s.set_meta("breath_kind", "child" if str(w.get("stage", "")) != "" else "person")
		s.texture = PlaceholderArt.tex(key)
		s.flip_h = FarmerAnim.is_mirrored(w.facing)
		_show_held(s, w)
		_show_note(s, w)
	for id in _sprites:
		if not seen.has(id):
			_sprites[id].visible = false


## What an event actor carries (`holds`) rests on top of their head; nothing, no sprite.
func _show_held(s: Sprite3D, w: Dictionary) -> void:
	var item := String(w.get("holds", ""))
	var held: Sprite3D = s.get_node_or_null("Held")
	if item == "":
		if held != null:
			held.visible = false
		return
	if held == null:
		held = FarmWorld.make_sprite(PlaceholderArt.tex(PlaceholderArt.world_item_key(item)))
		held.name = "Held"
		s.add_child(held)
	held.position = Vector3(0, (PlaceholderArt.FIGURE_SIZE.y - PlaceholderArt.villager_top(w.id) - 1) * FarmWorld.FIGURE_PX, 0)
	held.texture = PlaceholderArt.tex(PlaceholderArt.world_item_key(item))
	held.set_meta("item", item)
	held.visible = true


## A music note rising over the head while the villager whistles (Whistles.puff_look).
func _show_note(s: Sprite3D, w: Dictionary) -> void:
	var p := Whistles.puff(w.id, Game.day_minutes())
	var note: Sprite3D = s.get_node_or_null("Note")
	if p < 0.0:
		if note != null:
			note.visible = false
		return
	var look := Whistles.puff_look(p)
	if note == null:
		note = FarmWorld.make_sprite(PlaceholderArt.tex(look.key))
		note.name = "Note"
		note.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED   # it fades
		SpriteLight.unlit(note)   # a mark over the world, as drawn
		s.add_child(note)
	note.texture = PlaceholderArt.tex(look.key)
	var head := PlaceholderArt.FIGURE_SIZE.y - PlaceholderArt.villager_top(w.id)   # px from the feet to the head's top
	note.position = Vector3((4.0 + look.sway) * FarmWorld.PX, head * FarmWorld.FIGURE_PX + (2.0 + look.rise) * FarmWorld.PX, 0)
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


## Ids of the villagers shown now (for tests).
func shown() -> Array:
	return _sprites.keys().filter(func(id): return _sprites[id].visible)
