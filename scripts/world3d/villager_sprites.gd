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
		_show_hold(s, str(w.get("hold", "")))
	for id in _sprites:
		if not seen.has(id):
			_sprites[id].visible = false


## An item an event has the villager hold (a contest entry) rests on top of their head.
func _show_hold(s: Sprite3D, item: String) -> void:
	var h: Sprite3D = s.get_node_or_null("Hold")
	if item == "":
		if h != null:
			h.visible = false
		return
	var tex := PlaceholderArt.tex(PlaceholderArt.world_item_key(item))
	if h == null:
		h = FarmWorld.make_sprite(tex)
		h.name = "Hold"
		s.add_child(h)
	h.texture = tex
	h.set_meta("item", item)
	h.offset = Vector2(0, tex.get_height() / 2.0)
	h.position = Vector3(0, (s.texture.get_height() - 1) * FarmWorld.PX, 0)
	h.visible = true


## The item villager `id` holds overhead now ("" for none; for tests).
func held_by(id: String) -> String:
	var s: Sprite3D = _sprites.get(id)
	var h: Sprite3D = s.get_node_or_null("Hold") if s != null and s.visible else null
	return str(h.get_meta("item", "")) if h != null and h.visible else ""


## Ids of the villagers shown now (for tests).
func shown() -> Array:
	return _sprites.keys().filter(func(id): return _sprites[id].visible)
