extends SceneTree
## Headless checks for the small birds outdoors (BirdRules, data/birds.json, BirdArt): swallows in
## spring and summer days, crows at dusk in every season, a heron by the water in the morning,
## sparrows by the houses; the season / weather / clock / indoor gating, the places and heights, the
## farmer startling sparrows and the heron, the pictures, and both views (BirdLayer in 3D, BirdView
## in the flat view) building and showing them. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_birds.gd

var failures := 0
var g: Node
var BR: GDScript
var MM: GDScript


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	BR = load("res://scripts/bird_rules.gd")
	MM = load("res://scripts/world/map_manager.gd")
	g.new_game()
	g.clock_running = false
	_data()
	_gating()
	_scenes()
	_swallows_and_crows()
	_heron()
	_sparrows()
	_art()
	await _views()
	print("test_birds: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _when(season: int, hour: int, minute: int, weather: String) -> void:
	g.season = season
	g.day = 10
	g.hour = hour
	g.minute = minute
	g.weather_today = weather


func _data() -> void:
	var cfg: Dictionary = BR.config()
	for kind in BR.KINDS:
		check(cfg.has(kind) and cfg[kind].has("seasons") and cfg[kind].has("hours") and cfg[kind].has("looks") and int(cfg[kind].count) >= 1, "%s: data has its window and count" % kind)
		check(cfg.art.has(kind), "%s: art colours in the data" % kind)
		for look in ["sunny", "rain", "snow", "storm", "blizzard"]:
			check(cfg[kind].looks.has(look), "%s: a share for %s" % [kind, look])
		check(float(cfg[kind].looks.storm) == 0.0 and float(cfg[kind].looks.blizzard) == 0.0, "%s: none in a storm or blizzard" % kind)
	check(not "winter" in cfg.swallow.seasons and "spring" in cfg.swallow.seasons and "summer" in cfg.swallow.seasons, "swallows: spring and summer")
	check(cfg.crow.seasons.size() == 4, "crows: every season")


## Which kinds show when: season, weather, clock; nothing indoors or in the mine.
func _gating() -> void:
	check(BR.amount("swallow", "spring", "sunny", 12.0) == 1.0 and BR.amount("swallow", "summer", "sunny", 12.0) == 1.0, "swallows: a fair spring or summer noon")
	check(BR.amount("swallow", "fall", "sunny", 12.0) == 0.0 and BR.amount("swallow", "winter", "sunny", 12.0) == 0.0, "swallows: not in fall or winter")
	check(BR.amount("swallow", "spring", "sunny", 22.0) == 0.0 and BR.amount("swallow", "spring", "sunny", 4.0) == 0.0, "swallows: not at night")
	var rain: float = BR.amount("swallow", "spring", "rain", 12.0)
	check(rain > 0.0 and rain < 1.0, "swallows: fewer in rain (%.2f)" % rain)
	check(BR.amount("swallow", "spring", "storm", 12.0) == 0.0, "swallows: none in a storm")
	for s in ["spring", "summer", "fall", "winter"]:
		check(BR.amount("crow", s, "sunny", 17.5) == 1.0, "crows: at dusk in %s" % s)
	check(BR.amount("crow", "fall", "sunny", 12.0) == 0.0 and BR.amount("crow", "fall", "sunny", 22.0) == 0.0 and BR.amount("crow", "fall", "sunny", 7.0) == 0.0, "crows: dusk only, none at noon, night or morning")
	check(BR.amount("crow", "fall", "storm", 17.5) == 0.0 and BR.amount("crow", "winter", "blizzard", 17.5) == 0.0, "crows: none in a storm or blizzard")
	var snow: float = BR.amount("crow", "winter", "snow", 17.5)
	check(snow > 0.0 and snow < 1.0, "crows: fewer in snow (%.2f)" % snow)
	check(BR.amount("heron", "spring", "sunny", 7.0) == 1.0 and BR.amount("heron", "winter", "sunny", 7.0) == 1.0, "heron: the morning, any season")
	check(BR.amount("heron", "spring", "sunny", 12.0) == 0.0 and BR.amount("heron", "spring", "sunny", 22.0) == 0.0, "heron: not at noon or night")
	check(BR.amount("sparrow", "fall", "sunny", 12.0) == 1.0 and BR.amount("sparrow", "fall", "sunny", 22.0) == 0.0, "sparrows: by day, not at night")
	check(BR.amount("sparrow", "fall", "storm", 12.0) == 0.0, "sparrows: none in a storm")
	# Through Game and a map.
	var town: MapData = MM.data("town")
	var house: MapData = MM.data("house")
	var mine: MapData = MM.data("mine_floor")
	_when(0, 12, 0, "sunny")
	var noon: Dictionary = BR.amounts_now(g, town)
	check(noon.has("swallow") and noon.has("sparrow") and not noon.has("crow") and not noon.has("heron"), "spring noon outdoors: swallows and sparrows")
	check(BR.amounts_now(g, house).is_empty() and BR.amounts_now(g, mine).is_empty(), "spring noon indoors / in the mine: nothing")
	check(BR.amounts_now(null, town).is_empty(), "no clock: nothing")
	_when(2, 17, 30, "sunny")
	check(BR.amounts_now(g, town).has("crow"), "fall dusk: crows")
	_when(2, 23, 0, "sunny")
	check(BR.amounts_now(g, town).is_empty(), "night: nothing at all")
	_when(1, 12, 0, "storm")
	check(BR.amounts_now(g, town).is_empty(), "storm: nothing")
	_when(3, 7, 0, "snow")
	check(BR.amounts_now(g, town).has("heron"), "winter morning in snow: the heron")
	for kind in BR.KINDS:
		var n: int = BR.count_for(kind, 1.0)
		check(n == int(BR.config()[kind].count) and n >= 1 and n <= 12, "%s: full amount is the data's count, few (%d)" % [kind, n])
		check(BR.count_for(kind, 0.0) == 0 and BR.count_for(kind, 0.1) >= 1, "%s: zero is none, a thin amount at least one" % kind)


func _scenes() -> void:
	var town: MapData = MM.data("town")
	var ts: Dictionary = BR.scene_of(town, null, 5)
	check(ts.houses.size() >= 4, "town: spots in front of its houses (%d)" % ts.houses.size())
	for h in ts.houses:
		var c := Vector2i(int(h.x), int(h.y))
		check(not town.is_solid(c), "town: a sparrow spot (%s) is on open ground" % c)
	var river: Dictionary = BR.scene_of(MM.data("river"), null, 5)
	check(river.shore.size() > 0, "river: shore cells for the heron (%d)" % river.shore.size())
	var kam: Dictionary = BR.scene_of(MM.data("kaminoda"), null, 5)
	check(kam.shore.size() > 0, "kaminoda: paddy edges for the heron (%d)" % kam.shore.size())
	var fs: Dictionary = BR.scene_of(MM.data("farm"), g.farm, 5)
	check(fs.shore.size() > 0 and fs.houses.size() > 0, "farm: the pond's shore and the farmhouse door (%d / %d)" % [fs.shore.size(), fs.houses.size()])
	check(BR.scene_of(MM.data("house"), null, 5).shore.is_empty(), "a room has no shore")


func _swallows_and_crows() -> void:
	var town: MapData = MM.data("town")
	var scene: Dictionary = BR.scene_of(town, null, 5)
	var cfg: Dictionary = BR.config()
	var seen := 0
	var low := true
	var inside := true
	var frames := {}
	var t := 0.0
	while t < 200.0:
		for b in BR.birds("swallow", 1.0, t, scene, BR.NO_FARMER, {}):
			seen += 1
			low = low and b.pos.y >= float(cfg.swallow.height[0]) - 0.01 and b.pos.y <= float(cfg.swallow.height[1]) + 0.01
			inside = inside and b.pos.x > -5.0 and b.pos.x < town.w + 5.0
			frames[b.frame] = true
			check(b.pose == "fly" and b.id.begins_with("swallow:"), "swallow: pose fly")
		t += 0.5
	check(seen > 20, "swallows: now and then one crosses (%d sightings in 200 s)" % seen)
	check(low and inside, "swallows: low over the ground and crossing within the map's width")
	check(frames.size() >= 2, "swallows: more than one wing frame (%d)" % frames.size())
	check(BR.birds("swallow", 1.0, 3.0, scene, BR.NO_FARMER, {}).size() == BR.birds("swallow", 1.0, 3.0, scene, BR.NO_FARMER, {}).size()
		and str(BR.birds("swallow", 1.0, 40.0, scene, BR.NO_FARMER, {})) == str(BR.birds("swallow", 1.0, 40.0, scene, BR.NO_FARMER, {})), "swallows: a pure function of time (a frame is repeatable)")
	# Crows: a flock, high, all the same way.
	var flock := 0
	var best: Array[Dictionary] = []
	t = 0.0
	while t < 200.0:
		var cs: Array[Dictionary] = BR.birds("crow", 1.0, t, scene, BR.NO_FARMER, {})
		if cs.size() > best.size():
			best = cs
		flock = maxi(flock, cs.size())
		t += 0.5
	check(flock >= 3 and flock <= int(cfg.crow.count), "crows: a flock of %d crosses together" % flock)
	var high := true
	var same := true
	for b in best:
		high = high and b.pos.y >= float(cfg.crow.height[0]) - 0.3
		same = same and (b.dir as Vector2).x * (best[0].dir as Vector2).x > 0.0
	check(high and same, "crows: high up and heading the same way")
	check(BR.birds("crow", 0.2, 10.0, scene, BR.NO_FARMER, {}).size() <= 1 + 0 or BR.count_for("crow", 0.2) < int(cfg.crow.count), "crows: a thin amount is a smaller flock")


func _heron() -> void:
	var river: MapData = MM.data("river")
	var scene: Dictionary = BR.scene_of(river, null, 5)
	var cfg: Dictionary = BR.config()
	var home := Vector2.ZERO
	var t0 := -1.0
	var t := 0.0
	var stood := 0
	var flew := 0
	var absent := 0
	while t < 240.0:
		var hs: Array[Dictionary] = BR.birds("heron", 1.0, t, scene, BR.NO_FARMER, {})
		if hs.is_empty():
			absent += 1
		else:
			var b: Dictionary = hs[0]
			if b.pose == "stand":
				stood += 1
				home = Vector2(b.pos.x, b.pos.z)
				if t0 < 0.0:
					t0 = t
				check(b.pos.y == 0.0 and scene.shore.has(home), "heron: stands on a shore cell")
			else:
				flew += 1
		t += 0.5
	check(stood > 60 and flew > 4 and absent > 4, "heron: stands most of a period, flies in and out (%d stand, %d fly, %d away)" % [stood, flew, absent])
	check(t0 >= 0.0, "heron: found it standing")
	# The farmer comes near: it lifts off, away from him.
	var state := {}
	var near := home + Vector2(1.5, 0.0)
	var b0: Dictionary = BR.birds("heron", 1.0, t0, scene, near, state)[0]
	check(b0.pose == "fly" and not state.is_empty() and float(b0.pos.y) >= 0.0, "heron: the farmer comes near, it takes off")
	var b1: Dictionary = BR.birds("heron", 1.0, t0 + 3.0, scene, near, state)[0]
	check(b1.pos.y > 1.0 and Vector2(b1.pos.x, b1.pos.z).distance_to(home) > 3.0 and b1.pos.x < home.x, "heron: three seconds on it is up and away from him")
	check(BR.birds("heron", 1.0, t0 + float(cfg.heron.fly_time) + 1.0, scene, near, state).is_empty(), "heron: gone once the flight is done")
	check(not state.is_empty(), "heron: still startled while he stays near")
	BR.birds("heron", 1.0, t0 + float(cfg.heron.return_after) + 5.0, scene, BR.NO_FARMER, state)
	check(state.is_empty(), "heron: he has gone, it may come back after a while")
	# No farmer, no state.
	var calm := {}
	BR.birds("heron", 1.0, t0, scene, BR.NO_FARMER, calm)
	check(calm.is_empty(), "heron: nothing remembered without a farmer")


func _sparrows() -> void:
	var town: MapData = MM.data("town")
	var scene: Dictionary = BR.scene_of(town, null, 5)
	var cfg: Dictionary = BR.config()
	var k: Dictionary = cfg.sparrow
	var poses := {}
	var hopped := false
	var near_houses := true
	var t := 0.0
	while t < 60.0:
		var bs: Array[Dictionary] = BR.birds("sparrow", 1.0, t, scene, BR.NO_FARMER, {})
		check(bs.size() == int(k.count), "sparrows: all %d there" % int(k.count))
		for b in bs:
			poses[b.pose] = true
			hopped = hopped or float(b.pos.y) > 0.01
			var at := Vector2(b.pos.x, b.pos.z)
			var best := 999.0
			for h in scene.houses:
				best = minf(best, at.distance_to(h))
			near_houses = near_houses and best < 2.0
			check(b.pose != "fly", "sparrows: on the ground when nobody comes")
		t += 0.1
	check(poses.has("stand") and poses.has("hop") and poses.has("peck"), "sparrows: they stand, hop and peck (%s)" % str(poses.keys()))
	check(hopped and near_houses, "sparrows: hop within a cell or two of the houses")
	# The farmer comes near a spot: those birds fly off and rise.
	var first: Dictionary = BR.birds("sparrow", 1.0, 5.0, scene, BR.NO_FARMER, {})[0]
	var farmer := Vector2(first.pos.x, first.pos.z) + Vector2(0.5, 0.0)
	var state := {}
	var scared: Array[Dictionary] = BR.birds("sparrow", 1.0, 5.0, scene, farmer, state)
	var flying := scared.filter(func(b): return b.pose == "fly")
	check(flying.size() >= 1 and flying.size() < int(k.count) + 1 and state.size() == flying.size(), "sparrows: the ones he comes near fly off (%d)" % flying.size())
	var later: Array[Dictionary] = BR.birds("sparrow", 1.0, 6.5, scene, farmer, state)
	var up := later.filter(func(b): return b.pose == "fly" and b.pos.y > 0.5)
	check(up.size() >= 1, "sparrows: a second and a half on they are in the air")
	var gone: Array = BR.birds("sparrow", 1.0, 5.0 + float(k.fly_time) + 1.0, scene, farmer, state).filter(func(b): return b.pose == "fly")
	check(gone.is_empty(), "sparrows: out of sight when the flight is over")
	BR.birds("sparrow", 1.0, 5.0 + float(k.return_after) + 2.0, scene, BR.NO_FARMER, state)
	check(state.is_empty(), "sparrows: they come back once he has gone")


func _art() -> void:
	var BA: GDScript = load("res://scripts/art/bird_art.gd")
	for kind in BA.POSES:
		for pose in BA.POSES[kind]:
			var n: int = BA.frames(kind, pose)
			var sigs := {}
			for f in n:
				var img: Image = BA.make(kind, pose, f)
				check(img.get_size() == Vector2i(BA.size_of(kind, pose)), "%s %s %d: the size" % [kind, pose, f])
				var solid := 0
				var black := false
				var feet := false
				for y in img.get_height():
					for x in img.get_width():
						var c := img.get_pixel(x, y)
						if c.a > 0.0:
							solid += 1
							black = black or (c.r + c.g + c.b < 0.06)
							feet = feet or y == img.get_height() - 1
				check(solid >= 8, "%s %s %d: drawn (%d px)" % [kind, pose, f, solid])
				check(not black, "%s %s %d: a deep tone rim, not a black outline" % [kind, pose, f])
				check(feet or pose == "fly", "%s %s %d: stands on its bottom row" % [kind, pose, f])
				var mirrored: Image = BA.make(kind, pose, f, true)
				check(mirrored.get_pixel(img.get_width() - 1, 0) == img.get_pixel(0, 0) and mirrored.get_size() == img.get_size(), "%s %s %d: ':r' is the mirror" % [kind, pose, f])
				sigs[img.get_data().hex_encode()] = true
			check(sigs.size() == n, "%s %s: its %d frames differ" % [kind, pose, n])
	check(load("res://scripts/art/placeholder_art.gd").tex("bird:crow:fly:1:r").get_size() == Vector2(18, 12), "PlaceholderArt hands out the key bird:crow:fly:1:r")
	check(BR.key_of({"kind": "heron", "pose": "stand", "frame": 1}) == "bird:heron:stand:1", "the picture key of a bird")


## Both views build the nodes and show or hide them by the rules.
func _views() -> void:
	await process_frame
	var LayerS: GDScript = load("res://scripts/world3d/bird_layer.gd")
	var ViewS: GDScript = load("res://scripts/world/bird_view.gd")
	var MapWorldS: GDScript = load("res://scripts/world3d/map_world.gd")
	var town: MapData = MM.data("town")
	var w3: Node3D = MapWorldS.new()
	root.add_child(w3)
	for step in w3.build_steps(town):
		step.call()
	var layers := w3.get_children().filter(func(n): return n.get_script() == LayerS)
	check(layers.size() == 1, "3D: an outdoor map builds one bird layer (%d)" % layers.size())
	for map_id in ["house", "mine_floor"]:
		var inside: Node3D = MapWorldS.new()
		root.add_child(inside)
		for step in inside.build_steps(MM.data(map_id)):
			step.call()
		check(inside.get_children().filter(func(n): return n.get_script() == LayerS).is_empty(), "3D: %s builds none" % map_id)
		inside.free()
	if layers.size() == 1:
		var layer: Node3D = layers[0]
		_when(0, 12, 0, "sunny")
		layer.refresh()
		check(layer.shown_count() >= int(BR.config().sparrow.count), "3D: birds on a spring noon (%d)" % layer.shown_count())
		var sprites := layer.get_children().filter(func(n): return n is Sprite3D and n.visible)
		check(sprites.size() == layer.shown_count(), "3D: one visible sprite a bird (%d)" % sprites.size())
		_when(0, 12, 0, "storm")
		layer.refresh()
		check(layer.shown_count() == 0 and layer.get_children().filter(func(n): return n is Sprite3D and n.visible).is_empty(), "3D: none in a storm")
		_when(0, 23, 0, "sunny")
		layer.refresh()
		check(layer.shown_count() == 0, "3D: none at night")
		_when(2, 17, 30, "sunny")
		layer.refresh()
		check(layer.shown_count() >= 0 and layer.is_in_group("bird_layers"), "3D: the layer is in its group")
		# The farmer's place startles the sparrows (FarmWorld.set_farmer hands it over).
		_when(0, 12, 0, "sunny")
		layer.refresh()
		var ws: Array[Dictionary] = layer.shown()
		var sp := ws.filter(func(b): return b.kind == "sparrow")
		w3.set_farmer(Vector3(sp[0].pos.x, 0.0, sp[0].pos.z))
		layer.refresh()
		check(layer.shown().any(func(b): return b.kind == "sparrow" and b.pose == "fly"), "3D: set_farmer next to the sparrows sends them up")
	w3.free()
	var M3: GDScript = load("res://scripts/main_3d.gd")
	var made: Array = M3.new_world(MM.data("farm"))
	for step in made[1]:
		step.call()
	check(made[0].get_children().any(func(n): return n.get_script() == LayerS), "3D: the farm builds a bird layer")
	made[0].free()
	# Flat.
	var player := Node2D.new()
	root.add_child(player)
	player.position = Vector2(2, 2) * 16.0
	var v: Node2D = ViewS.new().setup(town, null, player)
	root.add_child(v)
	_when(0, 12, 0, "sunny")
	v.refresh()
	check(v.visible and v.sprites().size() >= int(BR.config().sparrow.count), "flat: birds on a spring noon (%d)" % v.sprites().size())
	var in_px := true
	for s in v.sprites():
		in_px = in_px and s.at == s.at.round() and load("res://scripts/art/placeholder_art.gd").tex(s.key) != null
	check(in_px, "flat: whole pixels, pictures found")
	_when(0, 12, 0, "storm")
	v.refresh()
	check(not v.visible and v.sprites().is_empty(), "flat: hidden in a storm")
	_when(0, 23, 0, "sunny")
	v.refresh()
	check(not v.visible, "flat: hidden at night")
	var room: Node2D = ViewS.new().setup(MM.data("house"), null, player)
	root.add_child(room)
	room.refresh()
	check(not room.visible and room.sprites().is_empty(), "flat: a room gets none")
	var fv: Node2D = ViewS.new().setup(MM.data("farm"), g.farm, player)
	root.add_child(fv)
	_when(2, 12, 0, "sunny")
	fv.refresh()
	check(fv.visible and fv.sprites().size() > 0, "flat: the farm gets sparrows by the door (%d)" % fv.sprites().size())
	check(v.screen_of(Vector3(2, 1, 3)).y < v.screen_of(Vector3(2, 0, 3)).y, "flat: higher is further up the screen")
	v.free()
	room.free()
	fv.free()
	player.free()
