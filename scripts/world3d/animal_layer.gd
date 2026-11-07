class_name AnimalLayer
extends Node3D
## The animals in 3D, over a FarmWorld or a home's MapWorld (the coop, the barn): animals
## about their spots inside (or in their yard on the farm while they are out), eggs in the
## nests, the feed in the feed box / the hay in the fodder trough, an egg in the incubator,
## and on the farm the dog. Reads Game.animals and rebuilds on its `changed`; the wandering is
## only for the eye (the rules don't move animals). The dog's steps are the rules' (dog_walk,
## called from here with the farmer's cell); the sprite slides between the cells.

const SPEED := {"chicken": 0.6, "chick": 0.6}   # cells a second while walking; others DEFAULT_SPEED
const DEFAULT_SPEED := 0.35
const WALK_FPS := 6.0
## The animal pictures have AnimalArt.SCALE times the farmer's pixel density, so their sprites'
## pixels are that much smaller and the animals keep their world size.
const ANIMAL_PX := FarmWorld.PX / AnimalArt.SCALE

var on_farm := false
var map: MapData            # the home's map when inside
var farmer: Node2D          # the (hidden) 2D Player, for the dog to follow on the farm
var _beasts: Array[Dictionary] = []   # {sprite, kind, sick, home: Rect2, pos, target, wait, pose, time}
var _dog := {}                        # {sprite, pos, pose, time, still} on the farm while not held
var _rng := RandomNumberGenerator.new()


func setup(m: MapData, farm: bool, player: Node2D = null) -> void:
	map = m
	on_farm = farm
	farmer = player
	_rng.seed = 11
	Game.animals.changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_beasts.clear()
	_dog = {}
	var a := Game.animals
	if on_farm:
		for home in a.state:
			if not a.is_out(home):
				continue
			var yard: Array = a.home_rule(home).get("yard", [12, 4, 8, 3])
			var area := Rect2(yard[0], yard[1], yard[2], yard[3])
			for i in a.in_home(home):
				var start := area.position + Vector2(_rng.randf(), _rng.randf()) * area.size
				_add_beast(a.list[i], area, start)
		_add_dog()
		return
	var home := a.home_on_map(map.id) if map != null else ""
	if home == "":
		return
	if not a.is_out(home):
		var roam := 1.6 if home == "coop" else 0.3   # hens peck about, the barn animals stay in their stalls
		for i in a.in_home(home):
			var c := a.spot(i)
			if c.x < 0:
				continue
			var mid := Vector2(c) + Vector2(0.5, 0.5)
			_add_beast(a.list[i], Rect2(mid - Vector2(roam, roam) / 2, Vector2(roam, roam)), mid)
	_eggs_and_feed(home)


func _add_beast(beast: Dictionary, area: Rect2, start: Vector2) -> void:
	var kind := Game.animals.look(beast)
	var facing: String = AnimalArt.FACINGS[_rng.randi() % 2]   # at first they face the camera, left or right
	var s := FarmWorld.make_sprite(PlaceholderArt.tex("animal:%s:idle:0:%s" % [kind, facing]))
	s.pixel_size = ANIMAL_PX
	NightLights.figure(s)
	add_child(s)
	SpriteShadow.attach(s, 0.25)
	_beasts.append({"sprite": s, "kind": kind, "sick": bool(beast.sick), "home": area, "pos": start,
		"target": start, "wait": _rng.randf_range(0.0, 2.0), "pose": "idle", "time": _rng.randf() * 3.0,
		"facing": facing})
	_place(_beasts.back())


func _add_dog() -> void:
	var dog: Dictionary = Game.animals.dog
	if dog.held:
		return
	var s := FarmWorld.make_sprite(PlaceholderArt.tex("animal:dog:idle:0"))
	s.pixel_size = ANIMAL_PX
	NightLights.figure(s)
	s.add_to_group(Parting.GROUP)   # the grass and crops part round the dog too
	add_child(s)
	SpriteShadow.attach(s, 0.25)
	_dog = {"sprite": s, "pos": Vector2(dog.cell) + Vector2(0.5, 0.5), "pose": "idle", "time": 0.0, "still": 0.0,
		"facing": "dl"}
	_place_dog(0.0)


## The eggs lie in the nest cells in order, the feed box / fodder trough shows a mound a
## portion, the incubator its egg.
func _eggs_and_feed(home: String) -> void:
	var a := Game.animals
	var nests: Array[Vector3] = []
	var box := Rect2()
	var incubator := Vector3(-1, 0, -1)
	for p in map.props:
		match str(p.get("use", "")):
			"nest":
				for i in p.size.y:
					nests.append(Vector3(p.cell.x + 0.42, 0.34, p.cell.y + i + 0.5))
			"feed_box", "fodder_box":
				box = Rect2(Vector2(p.cell), Vector2(p.size))
			"incubator":
				incubator = Vector3(p.cell.x + 0.45, 0.48, p.cell.y + 0.4)
	if home == "coop":
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
		var barn := home != "coop"
		# Hay in the barn's trough is lit and has strands like the bundles, not a flat yellow.
		var feed := FarmWorld.surface_material("build:hay") if barn else FarmWorld.flat_material(Color("c8a050"))
		var places := maxi(int(a.home_rule(home).get("capacity", 6)), 1)
		var step := (box.size.x - 0.3) / places
		for i in mini(int(a.state[home].box), places):
			var mesh := SphereMesh.new()
			mesh.radius = minf(step * 0.45, 0.32 if barn else 0.2)
			mesh.height = mesh.radius * 0.9
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.material_override = feed
			mi.position = Vector3(box.position.x + 0.15 + step * (i + 0.5), 0.22 if barn else 0.12, box.get_center().y + (0.05 if barn else -0.1))
			add_child(mi)


func _process(delta: float) -> void:
	for h in _beasts:
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
				h.pos += to.limit_length(SPEED.get(h.kind, DEFAULT_SPEED) * delta)
				h.facing = AnimalArt.facing_of(to, h.facing)   # screen right is +x / -z from this camera
		_place(h)
	if on_farm and farmer != null and not Game.paused():
		Game.animals.dog_walk(delta, Player.cell_of(farmer.position), func(c: Vector2i) -> bool: return not Game.farm.is_solid(c), _rng)
	if not _dog.is_empty():
		_place_dog(delta)


func _place(h: Dictionary) -> void:
	var frame := int(h.time * (WALK_FPS if h.pose == "walk" else 1.5)) % 2
	h.sprite.texture = PlaceholderArt.tex("animal:%s:%s:%d:%s" % [h.kind, h.pose, frame, h.facing])
	h.sprite.position = Vector3(h.pos.x, 0, h.pos.y)


## The dog slides towards its cell (a little faster than it steps), sits after a while still.
func _place_dog(delta: float) -> void:
	var dog: Dictionary = Game.animals.dog
	var goal := Vector2(dog.cell) + Vector2(0.5, 0.5)
	var to: Vector2 = goal - _dog.pos
	var speed := 1.3 / maxf(float(Game.animals.dog_rule().get("step_seconds", 0.3)), 0.05)
	_dog.time += delta
	if to.length() > 0.02:
		_dog.pos += to.limit_length(speed * delta)
		_dog.pose = "walk"
		_dog.still = 0.0
		_dog.facing = AnimalArt.facing_of(to, _dog.facing)
	else:
		_dog.still += delta
		_dog.pose = "sit" if _dog.still > 2.5 else "idle"
	var frame := int(_dog.time * (WALK_FPS * 1.5 if _dog.pose == "walk" else 1.5)) % 2
	_dog.sprite.texture = PlaceholderArt.tex("animal:dog:%s:%d:%s" % [_dog.pose, frame, _dog.facing])
	_dog.sprite.position = Vector3(_dog.pos.x, 0, _dog.pos.y)
