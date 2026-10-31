class_name AnimalLayer
extends Node3D
## The animals in 3D, over a FarmWorld or the coop's MapWorld: hens pecking about near their
## spots in the coop (or in the farm yard while they are out), eggs in the nests, the feed in
## the feed box and an egg in the incubator. Reads Game.animals and rebuilds on its `changed`;
## the wandering is only for the eye (the rules don't move animals).

const SPEED := 0.6        # cells a second while a hen walks
const WALK_FPS := 6.0

var on_farm := false
var map: MapData            # the coop map when inside
var _hens: Array[Dictionary] = []   # {sprite, kind, sick, home: Rect2, pos, target, wait, pose, time}
var _rng := RandomNumberGenerator.new()


func setup(m: MapData, farm: bool) -> void:
	map = m
	on_farm = farm
	_rng.seed = 11
	Game.animals.changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_hens.clear()
	var a := Game.animals
	if on_farm:
		if not a.outside:
			return
		var yard: Array = a.home_rule("coop").get("yard", [12, 4, 8, 3])
		var area := Rect2(yard[0], yard[1], yard[2], yard[3])
		for i in a.list.size():
			var start := area.position + Vector2(_rng.randf(), _rng.randf()) * area.size
			_add_hen(a.list[i], area, start)
		return
	if map == null or map.id != CoopActions.map_id():
		return
	if not a.outside:
		for i in a.list.size():
			var c := CoopActions.spot(i)
			if c.x < 0:
				continue
			_add_hen(a.list[i], Rect2(Vector2(c) - Vector2(0.3, 0.3), Vector2(1.6, 1.6)), Vector2(c) + Vector2(0.5, 0.5))
	_eggs_and_feed()


func _add_hen(hen: Dictionary, area: Rect2, start: Vector2) -> void:
	var kind := "chicken" if Game.animals.is_adult(hen) else "chick"
	var s := FarmWorld.make_sprite(PlaceholderArt.tex("animal:%s:idle:0" % kind))
	add_child(s)
	var shadow := MeshInstance3D.new()
	var disc := PlaneMesh.new()
	disc.size = Vector2(0.45, 0.3) if kind == "chicken" else Vector2(0.3, 0.2)
	shadow.mesh = disc
	shadow.material_override = FarmWorld.flat_material(Color(0, 0, 0, 0.25))
	shadow.position = Vector3(0, 0.01, 0)
	s.add_child(shadow)
	_hens.append({"sprite": s, "kind": kind, "sick": bool(hen.sick), "home": area, "pos": start,
		"target": start, "wait": _rng.randf_range(0.0, 2.0), "pose": "idle", "time": _rng.randf() * 3.0})
	_place(_hens.back())


## The eggs lie in the nest cells in order, the feed box shows a mound a portion, the
## incubator its egg.
func _eggs_and_feed() -> void:
	var a := Game.animals
	var nests: Array[Vector3] = []
	var box := Rect2()
	var incubator := Vector3(-1, 0, -1)
	for p in map.props:
		match str(p.get("use", "")):
			"nest":
				for i in p.size.y:
					nests.append(Vector3(p.cell.x + 0.42, 0.34, p.cell.y + i + 0.5))
			"feed_box":
				box = Rect2(Vector2(p.cell), Vector2(p.size))
			"incubator":
				incubator = Vector3(p.cell.x + 0.45, 0.48, p.cell.y + 0.4)
	for i in mini(a.eggs.size(), nests.size()):
		var e := FarmWorld.make_sprite(PlaceholderArt.tex(PlaceholderArt.world_item_key(a.eggs[i])))
		e.pixel_size = FarmWorld.PX * 0.8
		e.position = nests[i]
		add_child(e)
	if a.incubator.size() > 0 and incubator.x >= 0:
		var e := FarmWorld.make_sprite(PlaceholderArt.tex(PlaceholderArt.world_item_key(a.incubator.item)))
		e.pixel_size = FarmWorld.PX * 0.8
		e.position = incubator
		add_child(e)
	if box.has_area():
		var grain := FarmWorld.flat_material(Color("c8a050"))
		var places := maxi(int(a.home_rule("coop").get("capacity", 6)), 1)
		var step := (box.size.x - 0.3) / places
		for i in mini(a.feed_box, places):
			var mesh := SphereMesh.new()
			mesh.radius = minf(step * 0.45, 0.2)
			mesh.height = mesh.radius * 0.9
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.material_override = grain
			mi.position = Vector3(box.position.x + 0.15 + step * (i + 0.5), 0.12, box.get_center().y - 0.1)
			add_child(mi)


func _process(delta: float) -> void:
	for h in _hens:
		h.time += delta
		if h.sick:
			h.pose = "sick"
		elif h.wait > 0.0:
			h.wait -= delta
		else:
			var to: Vector2 = h.target - h.pos
			if to.length() < 0.05:
				h.wait = _rng.randf_range(0.8, 3.0)
				h.pose = "peck" if _rng.randf() < 0.5 else "idle"
				var area: Rect2 = h.home
				h.target = area.position + Vector2(_rng.randf(), _rng.randf()) * area.size
			else:
				h.pose = "walk"
				h.pos += to.limit_length(SPEED * delta)
				h.sprite.flip_h = to.x - to.y > 0.0   # screen right is +x / -z from this camera
		_place(h)


func _place(h: Dictionary) -> void:
	var frame := int(h.time * (WALK_FPS if h.pose == "walk" else 1.5)) % 2
	h.sprite.texture = PlaceholderArt.tex("animal:%s:%s:%d" % [h.kind, h.pose, frame])
	h.sprite.position = Vector3(h.pos.x, 0, h.pos.y)
