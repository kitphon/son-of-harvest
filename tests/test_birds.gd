extends SceneTree
## Headless checks for the small birds outdoors (BirdRules, data/birds.json, BirdArt): swallows in
## spring and summer days, crows at dusk in every season, a heron by the water in the morning,
## sparrows by the houses; the season / weather / clock / indoor gating, the places and heights, the
## farmer startling sparrows and the heron (and the villagers, the dog and the walking child doing
## it too), the shadows (a blob under a bird on the ground, a faint one cast along the sun for a
## flier, none without sun), the pictures, and both views (BirdLayer in 3D, BirdView in the flat
## view) building and showing them, the flat view's fliers drawn over the roofs and figures. Run:
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
	_others()
	_shadows()
	_art()
	await _views()
	await _flat_order()
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


## Villagers, the dog and the walking child startle sparrows and the heron as the farmer does.
func _others() -> void:
	var town: MapData = MM.data("town")
	var scene: Dictionary = BR.scene_of(town, null, 5)
	var cfg: Dictionary = BR.config()
	var k: Dictionary = cfg.sparrow
	check(float(cfg.startle.others) > 0.0 and float(cfg.startle.others) <= 1.0, "startle: the others' share in the data")
	var first: Dictionary = BR.birds("sparrow", 1.0, 5.0, scene, BR.NO_FARMER, {})[0]
	var spot := Vector2(first.pos.x, first.pos.z)
	var villager := spot + Vector2(0.0, 1.0)
	var state := {}
	var bs: Array[Dictionary] = BR.birds("sparrow", 1.0, 5.0, scene, BR.NO_FARMER, state, {}, [villager])
	var up := bs.filter(func(b): return b.pose == "fly")
	check(up.size() >= 1 and state.has(first.id), "sparrows: a villager walking up sends them off with no farmer about (%d)" % up.size())
	var b1: Array = BR.birds("sparrow", 1.0, 6.0, scene, BR.NO_FARMER, state, {}, [villager]).filter(func(b): return b.id == first.id)
	check(not b1.is_empty() and float(b1[0].pos.z) < villager.y, "sparrows: they fly away from the villager (up the map, away from below)")
	BR.birds("sparrow", 1.0, 5.0 + float(k.return_after) + 2.0, scene, BR.NO_FARMER, state, {}, [villager])
	check(state.has(first.id), "sparrows: not back while the villager still stands there")
	BR.birds("sparrow", 1.0, 5.0 + float(k.return_after) + 3.0, scene, BR.NO_FARMER, state, {}, [])
	check(not state.has(first.id), "sparrows: back once the villager has gone")
	var far := spot + Vector2(float(k.scare) * float(cfg.startle.others) + 1.0, 0.0)
	var calm := {}
	BR.birds("sparrow", 1.0, 5.0, scene, BR.NO_FARMER, calm, {}, [far])
	check(not calm.has(first.id), "sparrows: a villager a little further than his scare share does not startle them")
	# The dog by the heron.
	var river: Dictionary = BR.scene_of(MM.data("river"), null, 5)
	var t := 0.0
	var home := Vector2.ZERO
	while t < 240.0:
		var hs: Array[Dictionary] = BR.birds("heron", 1.0, t, river, BR.NO_FARMER, {})
		if not hs.is_empty() and hs[0].pose == "stand":
			home = Vector2(hs[0].pos.x, hs[0].pos.z)
			break
		t += 0.5
	var hstate := {}
	var hb: Array[Dictionary] = BR.birds("heron", 1.0, t, river, BR.NO_FARMER, hstate, {}, [home + Vector2(-1.0, 0.0)])
	check(not hb.is_empty() and hb[0].pose == "fly" and not hstate.is_empty(), "heron: the dog trotting up makes it lift off")
	check(BR.scares("tome") and BR.scares("dog") and BR.scares("child", "toddler") and BR.scares("child", "child"), "startle: villagers, the dog, the toddler and the child do")
	check(not BR.scares("child", "crawler") and not BR.scares("child", "baby"), "startle: the crawler and the baby do not")


## Shadows: a soft blob under a bird on the ground always; a flier's only in sun, cast along it.
func _shadows() -> void:
	var cfg: Dictionary = BR.config()
	var sh: Dictionary = cfg.shadow
	for kind in BR.KINDS:
		check(float(sh.size.get(kind, 0.0)) > 0.0, "shadow: a size for %s" % kind)
	var dir: Vector3 = g.sun_direction({"elevation": 40.0, "yaw": -40.0})
	var ground := {"kind": "sparrow", "pose": "stand", "pos": Vector3(4.5, 0.0, 6.5), "alpha": 1.0}
	var s0: Dictionary = BR.shadow_of(ground, 0.0, dir)
	check(not s0.is_empty() and s0.at == Vector2(4.5, 6.5) and float(s0.alpha) > 0.0, "shadow: a sparrow standing has a blob at its feet without sun")
	check(not BR.shadow_of(ground, 1.0, dir).is_empty(), "shadow: and in sun too")
	var hop := ground.duplicate()
	hop.pose = "hop"
	hop.pos = Vector3(4.5, 0.25, 6.5)
	var sh_hop: Dictionary = BR.shadow_of(hop, 1.0, dir)
	check(float(sh_hop.alpha) < float(s0.alpha) and (sh_hop.size as Vector2).x < (s0.size as Vector2).x, "shadow: a hop lifts it off its blob (smaller, fainter)")
	var crow := {"kind": "crow", "pose": "fly", "pos": Vector3(10.0, 2.5, 8.0), "alpha": 1.0}
	check(BR.shadow_of(crow, 0.0, dir).is_empty(), "shadow: a flier casts none without sun")
	var sc: Dictionary = BR.shadow_of(crow, 1.0, dir)
	check(not sc.is_empty() and float(sc.alpha) < float(sh.ground_alpha), "shadow: a flier in sun casts a faint one")
	if not sc.is_empty():
		var off: Vector2 = (sc.at as Vector2) - Vector2(10.0, 8.0)
		check(off.length() > 0.3 and off.dot(Vector2(dir.x, dir.z)) > 0.0, "shadow: offset along the sun's way (%s)" % off)
		check(off.length() <= float(sh.max_offset) + 0.001, "shadow: never further than max_offset")
	var low_sun: Dictionary = BR.shadow_of(crow, 1.0, g.sun_direction({"elevation": 4.0, "yaw": -40.0}))
	check(not low_sun.is_empty() and ((low_sun.at as Vector2) - Vector2(10.0, 8.0)).length() <= float(sh.max_offset) + 0.001, "shadow: a low sun's long shadow is held to max_offset")
	var high := crow.duplicate()
	high.pos = Vector3(10.0, 6.0, 8.0)
	check(float(BR.shadow_of(high, 1.0, dir).get("alpha", 0.0)) < float(sc.alpha), "shadow: fainter the higher it flies")
	# Through the game's sun: by the weather and the clock (Game.sun_shadow).
	var cases := [[0, 10, "sunny", true], [1, 14, "sunny", true], [0, 10, "rain", false], [3, 10, "snow", false], [0, 21, "sunny", false], [0, 3, "sunny", false]]
	for c in cases:
		_when(c[0], c[1], 0, c[2])
		var sun: float = g.sun_shadow()
		var d: Vector3 = g.sun_direction(g.sun_light())
		var s: Dictionary = BR.shadow_of(crow, sun, d)
		if c[3]:
			check(not s.is_empty(), "shadow: a flier casts one at %d:00 %s (sun %.2f)" % [c[1], c[2], sun])
		else:
			check(s.is_empty(), "shadow: a flier casts none at %d:00 %s (sun %.2f)" % [c[1], c[2], sun])
		check(not BR.shadow_of(ground, sun, d).is_empty(), "shadow: a bird on the ground keeps its blob at %d:00 %s" % [c[1], c[2]])
	_when(0, 10, 0, "sunny")


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
		# Shadows: a blob under each sparrow on the ground (on a fresh layer, nobody about).
		var calm_layer: Node3D = LayerS.new(town)
		w3.add_child(calm_layer)
		_when(0, 10, 0, "sunny")
		calm_layer.refresh()
		var on_ground: Array = calm_layer.shown().filter(func(b): return not BR.flying(b))
		var blobs: Array = calm_layer.get_children().filter(func(n): return n is MeshInstance3D and n.visible)
		check(on_ground.size() > 0 and calm_layer.shadows().size() == calm_layer.shown_count() and blobs.size() == calm_layer.shadows().size(),
			"3D: a shadow under every bird on a sunny morning (%d birds, %d shadows, %d meshes)" % [calm_layer.shown_count(), calm_layer.shadows().size(), blobs.size()])
		var blob_y := true
		for m in blobs:
			blob_y = blob_y and m.position.y > 0.0 and m.position.y < 0.05 and m.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and m.layers == 2
		check(blob_y, "3D: the shadows lie just over the ground, cast nothing and sit on the ground layer (no night lamp light)")
		# Startled by the others: a villager (any Parting sprite in the world) by the sparrows, the farmer far off.
		var sp2: Array = calm_layer.shown().filter(func(b): return b.kind == "sparrow")
		var pushers: String = load("res://scripts/world3d/parting.gd").GROUP   # the villagers' and the dog's sprites
		var crawler := Sprite3D.new()
		crawler.add_to_group(pushers)
		crawler.set_meta("bird_scare", false)   # as VillagerSprites marks the crawler
		var walker := Sprite3D.new()
		walker.add_to_group(pushers)
		w3.add_child(crawler)
		w3.add_child(walker)
		w3.remove_child(layer)   # set_farmer hands its places to the node named Birds: the calm layer now
		layer.free()
		calm_layer.name = "Birds"
		crawler.position = Vector3(sp2[0].pos.x, 0.0, sp2[0].pos.z + 0.3)
		walker.position = Vector3(-50.0, 0.0, -50.0)
		w3.set_farmer(Vector3(-40.0, 0.0, -40.0))
		calm_layer.refresh()
		check(not calm_layer.shown().any(func(b): return b.kind == "sparrow" and b.pose == "fly"), "3D: the crawler sitting by the sparrows startles none")
		walker.position = crawler.position
		w3.set_farmer(Vector3(-40.0, 0.0, -40.0))
		calm_layer.refresh()
		check(calm_layer.others.size() == 1 and calm_layer.shown().any(func(b): return b.kind == "sparrow" and b.pose == "fly"), "3D: a villager or the dog by the sparrows sends them up, the farmer far off")
		var air_shadows: Array = calm_layer.shadows().filter(func(s): return s.air)
		check(not air_shadows.is_empty(), "3D: the startled sparrows cast shadows in the sun")
		_when(0, 10, 0, "rain")
		calm_layer.refresh()
		check(calm_layer.shown_count() > 0 and calm_layer.shadows().filter(func(s): return s.air).is_empty(), "3D: in rain no flier casts a shadow")
		var cut := true
		for n in calm_layer.get_children():
			if n is Sprite3D:
				cut = cut and n.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD
		check(cut, "3D: the bird sprites are alpha-cut (solid, so a faded building blends over them, never hides one in front)")
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
	# Flat shadows: a blob under each sparrow, in whole pixels; none cast by a flier in rain.
	_when(2, 10, 0, "sunny")
	fv.refresh()
	var shs: Array[Dictionary] = fv.shadows()
	var whole := true
	for s in shs:
		whole = whole and s.rect.position == s.rect.position.round() and s.rect.size == s.rect.size.round() and s.alpha > 0.0
	check(shs.size() == fv.sprites().size() and whole, "flat: a shadow under every sparrow, in whole pixels (%d)" % shs.size())
	# The dog by the sparrows at the farmhouse door sends them up (the farmer far off).
	var dog: Dictionary = g.animals.dog
	var dog_cell: Vector2i = dog.cell
	var sp: Dictionary = fv._shown.filter(func(b): return b.kind == "sparrow")[0]
	dog.cell = Vector2i(int(sp.pos.x), int(sp.pos.z))
	dog.held = false
	check(fv.walkers().has(Vector2(dog.cell) + Vector2(0.5, 0.5)), "flat: the dog is one of the walkers on the farm")
	fv.refresh()
	check(fv._shown.any(func(b): return b.kind == "sparrow" and b.pose == "fly"), "flat: the dog by the door sends the sparrows up")
	check(fv.shadows().any(func(s): return s.air), "flat: a startled sparrow casts its shadow in the sun")
	check(fv.sprites().any(func(s): return s.air), "flat: a startled sparrow goes to the air pass")
	_when(2, 10, 0, "rain")
	fv.refresh()
	check(not fv.shadows().any(func(s): return s.air), "flat: in rain no flier casts a shadow")
	dog.cell = dog_cell
	# The villagers of the map view's VillagerView are walkers too.
	_when(0, 10, 0, "sunny")
	var parent := Node2D.new()
	root.add_child(parent)
	var vv: Node2D = load("res://scripts/world/villager_view.gd").new("town")
	parent.add_child(vv)
	var tv: Node2D = ViewS.new().setup(town, null, player)
	parent.add_child(tv)
	vv.refresh()
	check(vv.feet().size() > 0 and tv.walkers().size() == vv.feet().size(), "flat: the villagers in town are walkers (%d of %d)" % [tv.walkers().size(), vv.feet().size()])
	parent.free()
	v.free()
	room.free()
	fv.free()
	player.free()


## The flat view's built scene (main_2d.tscn): the ground pass sits in the map view under the
## figures, the air pass draws over the roofs, props, villagers, animals and the farmer, under the
## weather (z 50), with the HUD and the fade on their own canvas layers above.
func _flat_order() -> void:
	_when(0, 12, 0, "sunny")
	var scene: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var view: Node2D = scene.view
	var bv: Node2D = null
	for n in view.get_children():
		if n.get_script() == load("res://scripts/world/bird_view.gd"):
			bv = n
	check(bv != null, "flat (main_2d): the map view has its birds")
	if bv == null:
		scene.free()
		return
	var air: Node2D = bv.air
	var idx := bv.get_index()
	var animals := view.get_children().filter(func(n): return n.get_script() == load("res://scripts/world/animal_view.gd"))
	var villagers := view.get_children().filter(func(n): return n.get_script() == load("res://scripts/world/villager_view.gd"))
	check(not animals.is_empty() and idx < animals[0].get_index(), "flat (main_2d): the ground pass is drawn before the animals and the dog")
	check(idx > 0 and view.get_child(0).get_index() < idx, "flat (main_2d): the ground pass is over the ground, roofs and props (the view's first children)")
	var air_z := _z_of(air)
	check(air_z > _z_of(scene.player) and air_z > _z_of(view) and (villagers.is_empty() or air_z > _z_of(villagers[0])), "flat (main_2d): fliers over the farmer, villagers, roofs and props (z %d)" % air_z)
	check(air_z < _z_of(scene.weather), "flat (main_2d): fliers under the rain and snow (z %d < %d)" % [air_z, _z_of(scene.weather)])
	check(air.get_canvas_layer_node() == null and scene.tint.get_canvas() == air.get_canvas(), "flat (main_2d): fliers on the world's canvas, under the night tint, not glowing")
	check(scene.fade is CanvasLayer and scene.fade.layer > 0, "flat (main_2d): the map fade is over the fliers")
	bv.refresh()
	check(bv.sprites().all(func(s): return s.air == (s.key as String).contains(":fly:")), "flat (main_2d): fliers in the air pass, the rest on the ground")
	await _ground_sort(scene, bv)
	scene.queue_free()
	await process_frame


## The birds on the ground sort in among the figures by their feet in the built main_2d view: a
## sparrow just in front of a villager or the farmer (feet lower on the screen) is drawn after
## them, one just behind is drawn before them; one overlapping nobody stays in the bird view (under
## them all); the fliers stay in the air pass; the shadows stay in the bird view's own drawing.
func _ground_sort(scene: Node, bv: Node2D) -> void:
	var view: Node2D = scene.view
	var player: Node2D = scene.player
	player.position = Vector2(-5000, -5000)   # far off: nothing startled
	if not g.animals.dog.is_empty():
		g.animals.dog.held = true   # the dog out of the way (no walker by the door)
	_when(0, 12, 0, "sunny")
	bv.refresh()
	var ground: Array = bv.sprites().filter(func(s): return not s.air)
	check(not ground.is_empty(), "flat (main_2d): sparrows on the ground by the farmhouse door at a spring noon (%d)" % ground.size())
	if ground.is_empty():
		return
	check(bv.ground_nodes().size() == ground.size(), "flat (main_2d): one node a bird on the ground (%d for %d)" % [bv.ground_nodes().size(), ground.size()])
	check(bv.ground_nodes().all(func(n): return n.get_parent() == bv), "flat (main_2d): with nobody about the birds on the ground stay in the bird view, under every figure")
	var s: Dictionary = ground[0]
	var at: Vector2 = s.at
	var node: Node2D = bv.ground_nodes()[0]
	var vv: Node = null
	for n in view.get_children():
		if n.get_script() == load("res://scripts/world/villager_view.gd"):
			vv = n
	check(vv != null, "flat (main_2d): the map view has its villagers")
	if vv == null:
		return
	# A villager sprite as VillagerView makes them (feet 2 px below the spot), standing by the bird.
	var v := Sprite2D.new()
	v.centered = false
	v.offset = player.figure.offset   # as VillagerView sets it
	v.texture = player.figure.texture   # a figure-sized picture
	vv.add_child(v)
	vv._sprites["test_walker"] = v
	v.position = at + Vector2(0, -6)   # just behind the bird (north): the bird draws over them
	bv._place_ground()
	var order := _draw_order(scene)
	check(node.get_parent() == vv and order.find(node) > order.find(v), "flat (main_2d): a sparrow in front of a villager is drawn after them (%s, %d > %d)" % [node.get_parent().name, order.find(node), order.find(v)])
	check(node.position == at, "flat (main_2d): the bird keeps its place among the villagers (%s, %s)" % [node.position, at])
	v.position = at + Vector2(0, 6)   # just in front (south): the villager draws over the bird
	bv._place_ground()
	order = _draw_order(scene)
	check(order.find(node) < order.find(v), "flat (main_2d): a sparrow behind a villager is drawn before them (%d < %d)" % [order.find(node), order.find(v)])
	v.position = at + Vector2(200, 0)   # far to one side: overlaps nobody
	bv._place_ground()
	check(node.get_parent() == bv, "flat (main_2d): a sparrow overlapping nobody goes back to the bird view")
	vv._sprites.erase("test_walker")
	v.free()
	# The farmer (drawn after the whole map view).
	player.position = at + Vector2(0, -6)
	bv._place_ground()
	order = _draw_order(scene)
	var last_of_player := order.find(player)
	for c in player.get_children():
		last_of_player = maxi(last_of_player, order.find(c))
	check(order.find(node) > last_of_player, "flat (main_2d): a sparrow in front of the farmer is drawn over the farmer and what he carries (%d > %d)" % [order.find(node), last_of_player])
	check(order.find(node) < order.find(scene.flying), "flat (main_2d): ... still under a thrown item in flight")
	check(_z_of(node) == _z_of(player) and _z_of(node) < _z_of(scene.weather) and _z_of(node) < _z_of(bv.air), "flat (main_2d): ... at the figures' z, under the weather and the fliers")
	check(node.get_canvas() == scene.tint.get_canvas() and node.get_canvas_layer_node() == null, "flat (main_2d): ... on the world's canvas, under the night tint")
	player.position = at + Vector2(0, 6)
	bv._place_ground()
	order = _draw_order(scene)
	check(order.find(node) < order.find(player) and order.find(node) > order.find(view), "flat (main_2d): a sparrow behind the farmer is drawn after the map view and before the farmer")
	# The dog (AnimalView): in front of the bird.
	if not g.animals.dog.is_empty():
		var animals: Node = view.get_children().filter(func(n): return n.get_script() == load("res://scripts/world/animal_view.gd"))[0]
		g.animals.dog.held = false
		var placed := false
		for dy in [0, 1, -1]:
			g.animals.dog.cell = Vector2i(floori(at.x / 16.0), floori(at.y / 16.0) + dy)
			var f: Dictionary = animals.figures().back()
			if (f.feet as Vector2).y > at.y and (f.rect as Rect2).intersects(Rect2(at - Vector2(4, 6), Vector2(8, 6))):
				placed = true
				break
		player.position = Vector2(-5000, -5000)
		bv._place_ground()
		order = _draw_order(scene)
		check(placed and order.find(node) < order.find(animals) and order.find(node) > order.find(vv), "flat (main_2d): a sparrow behind the dog is drawn before the animals' node (%s)" % node.get_parent().name)
		g.animals.dog.held = true
	# The fliers stay in the air pass, the shadows in the bird view's own drawing.
	player.position = Vector2(-5000, -5000)
	bv._place_ground()
	check(bv.air.get_parent() == bv and bv.air.z_index == int(BR.config().flat.air_z), "flat (main_2d): the fliers' pass is where it was (z %d)" % bv.air.z_index)
	check(not bv.ground_nodes().any(func(n): return (str(n.bird.key)).contains(":fly:")), "flat (main_2d): no flier among the birds on the ground")
	# A map change takes the nodes sitting among the figures away with the bird view.
	player.position = at + Vector2(0, -6)
	bv._place_ground()
	var outside: Node2D = node
	check(outside.get_parent() == scene, "flat (main_2d): the bird sits in the scene beside the farmer")
	bv.get_parent().remove_child(bv)
	check(outside.is_queued_for_deletion(), "flat (main_2d): its bird view leaving takes it along")
	bv.queue_free()
	await process_frame


## Every canvas item under `n` in drawing order (tree order; all at z 0 here but the noted ones).
func _draw_order(n: Node, out: Array = []) -> Array:
	out.append(n)
	for c in n.get_children():
		_draw_order(c, out)
	return out


## The z a canvas item is drawn at (its z_index added to its parents' while relative).
func _z_of(n: CanvasItem) -> int:
	var z := 0
	var c: Node = n
	while c is CanvasItem:
		z += (c as CanvasItem).z_index
		if not (c as CanvasItem).z_as_relative:
			break
		c = c.get_parent()
	return z
