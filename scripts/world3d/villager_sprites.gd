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
	for id in _sprites:
		if not seen.has(id):
			_sprites[id].visible = false


## Ids of the villagers shown now (for tests).
func shown() -> Array:
	return _sprites.keys().filter(func(id): return _sprites[id].visible)
