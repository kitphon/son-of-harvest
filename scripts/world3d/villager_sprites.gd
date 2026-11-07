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
			s = FarmWorld.make_sprite(PlaceholderArt.tex(Villagers.sprite_key(w)))
			NightLights.figure(s)
			s.add_to_group(Parting.GROUP)   # the grass and crops part round them
			var shadow := MeshInstance3D.new()
			var disc := PlaneMesh.new()
			disc.size = Vector2(0.55, 0.55)
			shadow.mesh = disc
			shadow.material_override = FarmWorld.flat_material(Color(0, 0, 0, 0.3))
			shadow.position = Vector3(0, 0.01, 0)
			s.add_child(shadow)
			add_child(s)
			_sprites[w.id] = s
		s.visible = true
		s.position = Vector3(w.pos.x, 0, w.pos.y)
		var key := Villagers.sprite_key(w)
		if key.ends_with(":work:1") and s.get_meta("key", "") != key:
			Sfx.play("build_knock")   # each blow of the hammer, heard on this map
		s.set_meta("key", key)
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
		held.position = Vector3(0, 23 * FarmWorld.PX, 0)
		s.add_child(held)
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
		s.add_child(note)
	note.texture = PlaceholderArt.tex(look.key)
	note.position = Vector3((4.0 + look.sway) * FarmWorld.PX, (24.0 + look.rise) * FarmWorld.PX, 0)
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
