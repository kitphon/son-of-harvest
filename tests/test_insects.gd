extends SceneTree
## Headless checks for the small flying insects outdoors (InsectRules, data/insects.json,
## InsectArt): butterflies over the crops and grass of spring and early summer days, red
## dragonflies hovering, darting and resting on posts in late summer and fall; the season / day /
## weather / clock / wind / indoor gating, the places and counts, the paths, the perch and
## lift-off, the startle by the farmer and the other walkers, the pictures, and both views
## (InsectLayer in 3D, InsectView in the flat view) building and showing them. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_insects.gd

var failures := 0
var g: Node
var IR: GDScript
var MM: GDScript
const FARMER_FAR := Vector2(-9999.0, -9999.0)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	IR = load("res://scripts/insect_rules.gd")
	MM = load("res://scripts/world/map_manager.gd")
	g.new_game()
	g.clock_running = false
	_data()
	_gating()
	_scenes()
	_butterflies()
	_dragonflies()
	_perch_and_startle()
	_art()
	_shadows()
	_held()
	await _crop_perches()
	await _views()
	await _flat()
	print("test_insects: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _when(season: int, hour: int, minute: int, weather: String, day := 20) -> void:
	g.season = season
	g.day = day
	g.hour = hour
	g.minute = minute
	g.weather_today = weather


func _data() -> void:
	var cfg: Dictionary = IR.config()
	for kind in IR.KINDS:
		check(cfg.has(kind) and cfg[kind].has("seasons") and cfg[kind].has("hours") and cfg[kind].has("looks") and int(cfg[kind].count) >= 1, "%s: data has its window and count" % kind)
		for look in ["sunny", "rain", "snow", "storm", "blizzard"]:
			check(cfg[kind].looks.has(look), "%s: a share for %s" % [kind, look])
			check(look == "sunny" or float(cfg[kind].looks[look]) == 0.0, "%s: none in %s" % [kind, look])
	for art in ["butterfly", "butterfly_y", "dragonfly"]:
		check(cfg.art.has(art), "%s: art colours in the data" % art)
	check(cfg.butterfly.seasons == ["spring", "summer"] and cfg.dragonfly.seasons == ["summer", "fall"], "butterflies: spring and summer, dragonflies: summer and fall")
	check(cfg.flat.air_z == load("res://scripts/bird_rules.gd").config().flat.air_z, "fliers share the birds' air pass z")


## Which kinds show when: season, day of the season, weather, clock, wind; nothing indoors or in the mine.
func _gating() -> void:
	check(IR.amount("butterfly", "spring", "sunny", 12.0, 5) == 1.0, "butterflies: a fair spring noon")
	check(IR.amount("butterfly", "summer", "sunny", 12.0, 8) == 1.0, "butterflies: early summer")
	check(IR.amount("butterfly", "summer", "sunny", 12.0, 24) == 0.0, "butterflies: not in late summer")
	var edge: float = IR.amount("butterfly", "summer", "sunny", 12.0, 16)
	check(edge > 0.0 and edge < 1.0, "butterflies: thinning out at the end of their days (%.2f)" % edge)
	check(IR.amount("butterfly", "fall", "sunny", 12.0, 5) == 0.0 and IR.amount("butterfly", "winter", "sunny", 12.0, 5) == 0.0, "butterflies: not in fall or winter")
	check(IR.amount("dragonfly", "summer", "sunny", 12.0, 8) == 0.0, "dragonflies: not in early summer")
	check(IR.amount("dragonfly", "summer", "sunny", 12.0, 24) == 1.0, "dragonflies: late summer")
	check(IR.amount("dragonfly", "fall", "sunny", 12.0, 3) == 1.0 and IR.amount("dragonfly", "fall", "sunny", 12.0, 27) == 1.0, "dragonflies: all fall")
	check(IR.amount("dragonfly", "spring", "sunny", 12.0, 5) == 0.0 and IR.amount("dragonfly", "winter", "sunny", 12.0, 5) == 0.0, "dragonflies: not in spring or winter")
	for kind in IR.KINDS:
		var s := "spring" if kind == "butterfly" else "fall"
		check(IR.amount(kind, s, "sunny", 22.0, 5) == 0.0 and IR.amount(kind, s, "sunny", 4.0, 5) == 0.0, "%s: not at night" % kind)
		check(IR.amount(kind, s, "sunny", 6.0, 5) == 0.0 and IR.amount(kind, s, "sunny", 18.5, 5) == 0.0, "%s: not at dawn or dusk" % kind)
		for look in ["rain", "snow", "storm", "blizzard"]:
			check(IR.amount(kind, s, look, 12.0, 5) == 0.0, "%s: none in %s" % [kind, look])
		var dawn: float = IR.amount(kind, s, "sunny", float(IR.config()[kind].hours[0]) + 0.4, 5)
		check(dawn > 0.0 and dawn < 1.0, "%s: easing in through the morning (%.2f)" % [kind, dawn])
	# The wind thins them.
	check(IR.thinned(1.0, 0.0) == 1.0, "no wind: all of them")
	var breeze: float = IR.thinned(1.0, 0.15)
	var gale: float = IR.thinned(1.0, 0.6)
	check(breeze < 1.0 and breeze > 0.7 and gale < breeze and IR.thinned(1.0, 1.0) == 0.0, "the wind thins them (%.2f, %.2f)" % [breeze, gale])
	check(IR.count_for("dragonfly", gale) < IR.count_for("dragonfly", 1.0), "a strong wind: fewer dragonflies (%d < %d)" % [IR.count_for("dragonfly", gale), IR.count_for("dragonfly", 1.0)])
	# Through Game and a map.
	var kam: MapData = MM.data("kaminoda")
	var farm: MapData = MM.data("farm")
	var house: MapData = MM.data("house")
	var mine: MapData = MM.data("mine_floor")
	_when(0, 12, 0, "sunny", 5)
	var spring: Dictionary = IR.amounts_now(g, kam)
	check(spring.has("butterfly") and not spring.has("dragonfly"), "spring noon outdoors: butterflies only")
	check(float(spring.butterfly) < 1.0 and float(spring.butterfly) > 0.7, "spring noon: the fair day's breeze thins them a little (%.2f)" % float(spring.butterfly))
	check(IR.amounts_now(g, kam, {}, 0.0).butterfly == 1.0 and float(IR.amounts_now(g, kam, {}, 0.7).butterfly) < float(spring.butterfly), "amounts_now: the wind it is given")
	check(IR.amounts_now(g, house).is_empty() and IR.amounts_now(g, mine).is_empty(), "indoors / in the mine: nothing")
	check(IR.amounts_now(null, kam).is_empty(), "no clock: nothing")
	_when(2, 11, 0, "sunny", 5)
	var fall: Dictionary = IR.amounts_now(g, farm)
	check(fall.has("dragonfly") and not fall.has("butterfly"), "fall noon on the farm: dragonflies only")
	_when(2, 23, 0, "sunny", 5)
	check(IR.amounts_now(g, kam).is_empty(), "night: nothing")
	for w in ["rain", "storm"]:
		_when(2, 11, 0, w, 5)
		check(IR.amounts_now(g, kam).is_empty(), "%s: nothing" % w)
	_when(3, 11, 0, "snow", 5)
	check(IR.amounts_now(g, kam).is_empty(), "winter snow: nothing")
	for kind in IR.KINDS:
		var n: int = IR.count_for(kind, 1.0)
		check(n == int(IR.config()[kind].count) and n >= 1 and n <= 12, "%s: full amount is the data's count, few (%d)" % [kind, n])
		check(IR.count_for(kind, 0.0) == 0 and IR.count_for(kind, 0.1) >= 1, "%s: zero is none, a thin amount at least one" % kind)
	check(IR.scares("sayo") and IR.scares("child", "toddler") and IR.scares("child", "child") and not IR.scares("child", "crawler") and not IR.scares("child", "baby"), "the walkers that startle them: everyone but the baby and the crawler")


func _scenes() -> void:
	_when(2, 11, 0, "sunny", 20)
	var fs: Dictionary = IR.scene_of(MM.data("farm"), g.farm, 5)
	check(fs.wet.size() >= 12 and fs.perches.size() >= 60 and fs.grass.size() > 100, "farm: the pond, the fence posts and open ground (%d / %d / %d)" % [fs.wet.size(), fs.perches.size(), fs.grass.size()])
	check(fs.lures.is_empty(), "the bare farm: no crops to lure butterflies")
	# Plant: a turnip (a lure), tall corn grown up (a perch) and rice (water).
	var cs: Array[Vector2i] = [Vector2i(10, 10), Vector2i(11, 10), Vector2i(12, 10)]
	for i in 3:
		var d: Dictionary = g.farm.cell(cs[i])
		d.obj = 0
		d.crop = ["turnip", "corn", "rice"][i]
		d.stage = 3
	var ps: Dictionary = IR.scene_of(MM.data("farm"), g.farm, 5)
	check(ps.lures.has(Vector2(10.5, 10.5)) and ps.lures.has(Vector2(11.5, 10.5)) and not ps.lures.has(Vector2(12.5, 10.5)), "farm: planted crops lure butterflies, the rice does not")
	check(ps.wet.has(Vector2(12.5, 10.5)), "farm: the rice stands in water")
	check(ps.perches.any(func(p): return floori(p.x) == 11 and floori(p.z) == 10 and p.y > 0.8), "farm: the grown corn's top is a perch")
	check(not ps.perches.any(func(p): return floori(p.x) == 10 and floori(p.z) == 10), "farm: a turnip is not")
	check(IR.farm_key(g.farm) != "" and IR.farm_key(null) == "", "the farm's key follows its plantings")
	for c in cs:
		var d: Dictionary = g.farm.cell(c)
		d.crop = ""
		d.stage = 0
	var kam: Dictionary = IR.scene_of(MM.data("kaminoda"), null, 5)
	check(kam.wet.size() > 50 and kam.grass.size() > 100 and kam.perches.size() > 8, "kaminoda: paddies, grass and perches (%d / %d / %d)" % [kam.wet.size(), kam.grass.size(), kam.perches.size()])
	check(kam.lures.size() >= 4, "kaminoda: the garden bed's cells lure butterflies (%d)" % kam.lures.size())
	# The wood fence (24, 8, 3 x 1): posts at 24..27 along its middle, 0.72 up (the board tops, FieldProps.board_fence).
	check(kam.perches.any(func(p): return is_equal_approx(p.x, 24.1) and is_equal_approx(p.z, 8.5) and is_equal_approx(p.y, 0.72)), "kaminoda: the wood fence's first post")
	check(kam.perches.any(func(p): return is_equal_approx(p.x, 2.15) and is_equal_approx(p.z, 9.5) and p.y > 1.3), "kaminoda: the drying rack's poles")
	var hill: Dictionary = IR.scene_of(MM.data("hill"), null, 5)
	check(hill.lures.size() > 0, "hill: its forage spots lure butterflies (%d)" % hill.lures.size())
	var riv: Dictionary = IR.scene_of(MM.data("river"), null, 5)
	check(riv.wet.size() > 20, "river: water for the swarms (%d)" % riv.wet.size())


## Every insect of `kind` at time `t` over `scene`, nobody about.
func _at(kind: String, t: float, scene: Dictionary, amount := 1.0, farmer := FARMER_FAR, state := {}, others := []) -> Array:
	return IR.insects(kind, amount, t, scene, farmer, state, {}, others)


func _butterflies() -> void:
	var cfg: Dictionary = IR.config()
	var k: Dictionary = cfg.butterfly
	var scene: Dictionary = IR.scene_of(MM.data("kaminoda"), null, 5)
	var n: int = IR.count_for("butterfly", 1.0)
	check(_at("butterfly", 12.0, scene).size() == n, "butterflies: the count (%d)" % n)
	check(_at("butterfly", 12.0, scene, 0.3).size() == IR.count_for("butterfly", 0.3), "butterflies: a thin amount shows fewer")
	check(str(_at("butterfly", 12.0, scene)) == str(_at("butterfly", 12.0, scene)), "butterflies: a place is a function of the time")
	# Round one lure: nothing else about.
	var one := scene.duplicate(true)
	one.lures = [Vector2(10.5, 10.5)] as Array[Vector2]
	one.grass = [] as Array[Vector2]
	one.near = {}
	var kinds := {}
	var far := 0.0
	var hmin := 99.0
	var hmax := 0.0
	var frames := {}
	var jump := 0.0
	var prev := {}
	for step in 800:
		var t := float(step) * 0.05
		for b in _at("butterfly", t, one):
			var at := Vector2(b.pos.x, b.pos.z)
			far = maxf(far, at.distance_to(Vector2(10.5, 10.5)))
			hmin = minf(hmin, b.pos.y)
			hmax = maxf(hmax, b.pos.y)
			kinds[b.art] = true
			frames[b.frame] = true
			check(b.pose == "fly" and b.kind == "butterfly" and IR.flying(b), "butterfly: in the air")
			if prev.has(b.id):
				jump = maxf(jump, at.distance_to(prev[b.id]))
			prev[b.id] = at
	check(far < 2.2, "butterflies stay round their lure (%.2f cells)" % far)
	check(hmin >= 0.2 and hmax <= float(k.height[1]) + float(k.bob) + 0.05 and hmax > float(k.height[0]), "butterflies fly between the crops' tops and a little above (%.2f..%.2f)" % [hmin, hmax])
	check(kinds.has("butterfly") and kinds.has("butterfly_y"), "butterflies: white and pale yellow")
	check(frames.has(0) and frames.has(1) and frames.size() == 2, "butterflies: two wing frames")
	check(jump < 0.5, "butterflies: a smooth flutter, no jumps (%.2f cells in 0.05 s)" % jump)
	# They wander, not hover in place.
	var spread := 0.0
	var first := Vector2.ZERO
	for step in 400:
		var bs := _at("butterfly", float(step) * 0.05, one)
		var at := Vector2(bs[0].pos.x, bs[0].pos.z)
		if step == 0:
			first = at
		spread = maxf(spread, at.distance_to(first))
	check(spread > 0.8, "a butterfly wanders over a few cells in 20 s (%.2f)" % spread)
	# Over open grass when nothing lures.
	var grass_only := scene.duplicate(true)
	grass_only.lures = [] as Array[Vector2]
	grass_only.near = {}
	check(_at("butterfly", 4.0, grass_only).size() == n, "butterflies: open grass will do")
	var none := scene.duplicate(true)
	none.lures = [] as Array[Vector2]
	none.grass = [] as Array[Vector2]
	none.near = {}
	check(_at("butterfly", 4.0, none).is_empty(), "a map with no ground: none")
	# The farmer walking close makes one veer away.
	var b0: Dictionary = _at("butterfly", 7.3, one)[0]
	var p0 := Vector2(b0.pos.x, b0.pos.z)
	var near_f := p0 + Vector2(0.7, 0.0)
	var b1: Dictionary = _at("butterfly", 7.3, one, 1.0, near_f)[0]
	var p1 := Vector2(b1.pos.x, b1.pos.z)
	check(p1.distance_to(near_f) > p0.distance_to(near_f) + 0.5 and b1.pos.y > b0.pos.y, "a butterfly veers away from the farmer and rises (%.2f -> %.2f)" % [p0.distance_to(near_f), p1.distance_to(near_f)])
	check((b1.dir as Vector2).dot(p1 - near_f) > 0.0, "and faces away from him")
	var b2: Dictionary = _at("butterfly", 7.3, one, 1.0, p0 + Vector2(6.0, 0.0))[0]
	check(b2.pos == b0.pos, "a farmer far off changes nothing")
	var b3: Dictionary = _at("butterfly", 7.3, one, 1.0, FARMER_FAR, {}, [near_f])[0]
	var b4: Dictionary = _at("butterfly", 7.3, one, 1.0, FARMER_FAR, {}, [p0 + Vector2(1.9, 0.0)])[0]
	check(Vector2(b3.pos.x, b3.pos.z).distance_to(near_f) > 0.9 and b3.pos != b0.pos, "a villager or the dog by one makes it veer too")
	check(b4.pos == b0.pos, "...but at a share of the distance: 1.9 cells from a villager is still safe")
	check(IR.key_of(b0) == "insect:%s:fly:%d" % [b0.art, b0.frame], "the picture key of a butterfly")


func _dragonflies() -> void:
	var cfg: Dictionary = IR.config()
	var k: Dictionary = cfg.dragonfly
	var scene: Dictionary = IR.scene_of(MM.data("kaminoda"), null, 5)
	var n: int = IR.count_for("dragonfly", 1.0)
	check(_at("dragonfly", 9.0, scene).size() == n, "dragonflies: the count (%d)" % n)
	check(str(_at("dragonfly", 9.0, scene)) == str(_at("dragonfly", 9.0, scene)), "dragonflies: a place is a function of the time")
	# Over the water: with no open ground every swarm is over a paddy.
	var wet_only := scene.duplicate(true)
	wet_only.grass = [] as Array[Vector2]
	wet_only.perches = [] as Array[Vector3]
	wet_only.near = {}
	var worst := 0.0
	var hmin := 99.0
	var hmax := 0.0
	var jump := 0.0
	var prev := {}
	var frames := {}
	var hovering := 0
	var darting := 0
	var speeds: Array[float] = []
	for step in 600:
		var t := float(step) * 0.05
		for b in _at("dragonfly", t, wet_only):
			var at := Vector2(b.pos.x, b.pos.z)
			var best := 99.0
			for c in wet_only.wet:
				best = minf(best, at.distance_to(c))
			worst = maxf(worst, best)
			hmin = minf(hmin, b.pos.y)
			hmax = maxf(hmax, b.pos.y)
			frames[b.frame] = true
			check(b.pose == "fly" and b.art == "dragonfly", "dragonfly: in the air with no perch about")
			if prev.has(b.id):
				var d := at.distance_to(prev[b.id])
				jump = maxf(jump, d)
				if b.id == "dragonfly:0":
					speeds.append(d / 0.05)
			prev[b.id] = at
	for s in speeds:
		if s < 0.3:
			hovering += 1
		elif s > 2.5:
			darting += 1
	check(worst < 6.0, "dragonflies swarm over the paddies (%.2f cells from the water at most)" % worst)
	check(hmin >= float(k.height[0]) - 0.06 and hmax <= float(k.height[1]) + 0.06, "dragonflies hover between the rice's tips and above (%.2f..%.2f)" % [hmin, hmax])
	check(frames.has(0) and frames.has(1), "dragonflies: the wings beat (two frames)")
	check(jump < 1.0, "dragonflies: even a dart is smooth (%.2f cells in 0.05 s)" % jump)
	check(hovering > speeds.size() / 2 and darting > 20, "one hovers most of the time and darts now and then (%d still, %d darting of %d)" % [hovering, darting, speeds.size()])
	# Over open ground when the map has no water.
	var dry := scene.duplicate(true)
	dry.wet = [] as Array[Vector2]
	dry.near = {}
	check(_at("dragonfly", 9.0, dry).size() == n, "dragonflies: open ground will do")
	# A swarm: the group's members are close together.
	var bs := _at("dragonfly", 9.0, wet_only)
	var sw := 0.0
	for i in int(k.group):
		sw = maxf(sw, Vector2(bs[0].pos.x, bs[0].pos.z).distance_to(Vector2(bs[i].pos.x, bs[i].pos.z)))
	check(sw < 8.0, "a swarm of %d keeps together (%.2f)" % [int(k.group), sw])


## The first time a dragonfly of `scene` rests: [t, its id, the spot] ([] for never in 600 s).
func _find_rest(scene: Dictionary, from := 0.0, amount := 1.0) -> Array:
	for step in 2400:
		var t := from + float(step) * 0.25
		for b in _at("dragonfly", t, scene, amount):
			if b.pose == "perch":
				return [t, b.id, b.pos]
	return []


func _perch_and_startle() -> void:
	var cfg: Dictionary = IR.config()
	var k: Dictionary = cfg.dragonfly
	for map_id in ["kaminoda", "farm"]:
		var scene: Dictionary = IR.scene_of(MM.data(map_id), g.farm if map_id == "farm" else null, 5)
		var rest := _find_rest(scene, 40.0)
		check(not rest.is_empty(), "%s: a dragonfly comes to rest on a perch" % map_id)
		if rest.is_empty():
			continue
		var spot: Vector3 = rest[2]
		check(scene.perches.any(func(p): return p.is_equal_approx(spot)), "%s: it rests on one of the scene's perches (%s)" % [map_id, spot])
		var id: String = rest[1]
		# Its rest: how long, and how it arrives and leaves.
		var t0: float = rest[0]
		var start := t0
		while start > 0.05 and _pose_of(id, start - 0.05, scene) == "perch":
			start -= 0.05
		var end := t0
		while _pose_of(id, end + 0.05, scene) == "perch":
			end += 0.05
		var dur := end - start
		check(dur >= float(k.rest[0]) - 0.2 and dur <= float(k.rest[1]) + 0.2, "%s: it rests %.1f s (%.0f to %.0f)" % [map_id, dur, float(k.rest[0]), float(k.rest[1])])
		var before := _pick(id, start - 0.5, scene)
		check(before.pose == "fly" and Vector3(before.pos).distance_to(spot) < float(k.approach) * 16.0 and Vector3(before.pos).distance_to(spot) > 0.0, "%s: it darts in to the perch before" % map_id)
		var after := _pick(id, end + 0.5, scene)
		check(after.pose == "fly", "%s: and darts off after" % map_id)
		var mid := _pick(id, start + dur / 2.0, scene)
		check(mid.pos == spot and mid.pose == "perch" and mid.frame == 0 and not IR.flying(mid), "%s: at rest it sits on the perch, wings flat (pose perch)" % map_id)
		check(IR.key_of(mid) == "insect:dragonfly:perch:0", "%s: the picture of a resting one" % map_id)
		# No jump into or out of a perch.
		var worst := 0.0
		var last := _pick(id, start - 2.0, scene)
		for s in int(((end + 2.0) - (start - 2.0)) / 0.05):
			var b := _pick(id, start - 2.0 + float(s) * 0.05, scene)
			worst = maxf(worst, Vector3(b.pos).distance_to(last.pos))
			last = b
		check(worst < 1.3, "%s: smooth into and out of the perch (%.2f)" % [map_id, worst])
		# Startle: the farmer walks up to it.
		var tm := start + 1.5
		var state := {}
		var away_scene := scene
		var fresh: Dictionary = _pick_state(id, tm, away_scene, FARMER_FAR, state, [])
		check(fresh.pose == "perch" and state.is_empty(), "%s: nobody about, it keeps its perch" % map_id)
		var spot2 := Vector2(spot.x, spot.z)
		var lifted: Dictionary = _pick_state(id, tm, away_scene, spot2 + Vector2(0.5, 0.0), state, [])
		check(lifted.pose == "fly" and state.has(id), "%s: the farmer walks up and it lifts off" % map_id)
		var gone: Dictionary = _pick_state(id, tm + 1.2, away_scene, spot2 + Vector2(0.5, 0.0), state, [])
		var gd := Vector2(gone.pos.x, gone.pos.z).distance_to(spot2)
		check(gone.pose == "fly" and gd > float(k.flee_dist) * 0.4, "%s: it has flown off (%.1f cells away)" % [map_id, gd])
		var away: Vector2 = (state[id] as Array)[1]
		check(away.dot(spot2 - (spot2 + Vector2(0.5, 0.0))) > 0.9 * away.length() * 0.5, "%s: away from the farmer" % map_id)
		var later: Dictionary = _pick_state(id, tm + float(k.return_after) - 2.0, away_scene, spot2 + Vector2(0.5, 0.0), state, [])
		check(later.pose == "fly" and state.has(id), "%s: it stays away while he stands there" % map_id)
		var back: Dictionary = _pick_state(id, tm + float(k.return_after) + 1.0, away_scene, FARMER_FAR, state, [])
		check(back.pose == "fly" and float((state[id] as Array)[3]) >= 0.0, "%s: he leaves: it starts to come back" % map_id)
		var home: Dictionary = _pick_state(id, tm + float(k.return_after) + float(k.blend) + 1.0, away_scene, FARMER_FAR, state, [])
		check(not state.has(id) and str(home) == str(_pick(id, tm + float(k.return_after) + float(k.blend) + 1.0, scene)), "%s: back to its day, the startle forgotten" % map_id)
		# Other walkers do it too; the farmer far off.
		var st2 := {}
		var by_other: Dictionary = _pick_state(id, tm, scene, FARMER_FAR, st2, [spot2 + Vector2(0.5, 0.0)])
		check(by_other.pose == "fly" and st2.has(id), "%s: a villager or the dog beside it startles it too" % map_id)
		var st3 := {}
		var by_far: Dictionary = _pick_state(id, tm, scene, FARMER_FAR, st3, [spot2 + Vector2(1.8, 0.0)])
		check(by_far.pose == "perch", "%s: a villager 1.8 cells off does not (share %.2f of %.1f)" % [map_id, float(cfg.startle.others), float(k.scare)])
		# The farmer passing a little away does not.
		var st4 := {}
		var pass_by: Dictionary = _pick_state(id, tm, scene, spot2 + Vector2(float(k.scare) + 0.3, 0.0), st4, [])
		check(pass_by.pose == "perch", "%s: the farmer %.1f cells off: it stays" % [map_id, float(k.scare) + 0.3])
		# A flier is never startled (no state).
		var st5 := {}
		_pick_state(id, start - 3.0, scene, spot2, st5, [])
		check(st5.is_empty(), "%s: only a resting one is startled" % map_id)


func _pose_of(id: String, t: float, scene: Dictionary) -> String:
	return str(_pick(id, t, scene).pose)


func _pick(id: String, t: float, scene: Dictionary) -> Dictionary:
	return _pick_state(id, t, scene, FARMER_FAR, {}, [])


func _pick_state(id: String, t: float, scene: Dictionary, farmer: Vector2, state: Dictionary, others: Array) -> Dictionary:
	for b in IR.insects("dragonfly", 1.0, t, scene, farmer, state, {}, others):
		if b.id == id:
			return b
	return {}


func _art() -> void:
	var IA: GDScript = load("res://scripts/art/insect_art.gd")
	for kind in IA.POSES:
		for pose in IA.POSES[kind]:
			var n: int = IA.frames(kind, pose)
			var sigs := {}
			for f in n:
				var img: Image = IA.make(kind, pose, f)
				check(img.get_size() == Vector2i(IA.size_of(kind)), "%s %s %d: the size" % [kind, pose, f])
				var solid := 0
				var black := false
				var feet := false
				var clear_wings := false
				for y in img.get_height():
					for x in img.get_width():
						var c := img.get_pixel(x, y)
						if c.a > 0.0:
							solid += 1
							black = black or (c.r + c.g + c.b < 0.06)
							feet = feet or y == img.get_height() - 1
							clear_wings = clear_wings or (c.a < 0.95 and c.b > c.r)
				check(solid >= 5, "%s %s %d: drawn (%d px)" % [kind, pose, f, solid])
				check(not black, "%s %s %d: no black outline" % [kind, pose, f])
				check(feet or pose == "fly", "%s %s %d: a resting one stands on its bottom row" % [kind, pose, f])
				check(kind != "dragonfly" or clear_wings, "dragonfly %s %d: pale clear wings" % [pose, f])
				var mirrored: Image = IA.make(kind, pose, f, true)
				check(mirrored.get_pixel(img.get_width() - 1, 0) == img.get_pixel(0, 0) and mirrored.get_size() == img.get_size(), "%s %s %d: ':r' is the mirror" % [kind, pose, f])
				sigs[img.get_data().hex_encode()] = true
			check(sigs.size() == n, "%s %s: its %d frames differ" % [kind, pose, n])
	check(IA.size_of("butterfly").x <= 5 and IA.size_of("butterfly").x >= 3, "a butterfly is 3 to 5 px wide")
	var dr: Image = IA.make("dragonfly", "fly", 0)
	var red := 0
	for x in dr.get_width():
		for y in dr.get_height():
			var c := dr.get_pixel(x, y)
			if c.a > 0.9 and c.r > 0.5 and c.g < 0.4 and c.b < 0.3:
				red += 1
	check(red >= 5 and red <= 7, "a dragonfly's red body is 5 to 7 px (%d)" % red)
	var w1: Image = IA.make("butterfly", "fly", 1)
	var y1: Image = IA.make("butterfly_y", "fly", 1)
	check(w1.get_pixel(1, 0) != y1.get_pixel(1, 0) and y1.get_pixel(1, 1).r > y1.get_pixel(1, 1).b + 0.2, "the yellow butterfly is yellow, the other white")
	var pa: GDScript = load("res://scripts/art/placeholder_art.gd")
	check(pa.tex("insect:dragonfly:perch:0:r").get_size() == Vector2(8, 5) and pa.tex("insect:butterfly_y:fly:1").get_size() == Vector2(5, 4), "PlaceholderArt hands out the keys insect:<kind>:<pose>:<frame>[:r]")


## Shadows (data/insects.json "shadow", the birds' rules via InsectRules.shadow_of): a perched
## dragonfly's blob under it at any sun, a flier's faint sun-cast oval only in sun, none on a building.
func _shadows() -> void:
	var sh: Dictionary = IR.config().shadow
	var bsh: Dictionary = (load("res://scripts/bird_rules.gd") as GDScript).config().shadow
	check(sh.size.has("butterfly") and sh.size.has("dragonfly") and float(sh.fly_alpha) > 0.0 and float(sh.fly_alpha) <= float(bsh.fly_alpha), "shadow: data has sizes and a faint flier alpha, not above a bird's (%.2f)" % float(sh.fly_alpha))
	check(float(sh.ground_alpha) <= float(bsh.ground_alpha) and float(sh.size.dragonfly) >= 0.4 and float(sh.size.dragonfly) <= float(bsh.size.sparrow), "shadow: a perched one's blob reads at 480 x 270 and is never darker or larger than a sparrow's")
	check(float(sh.ground_alpha) > 3.0 * float(sh.fly_alpha), "shadow: a perched one's blob is far darker than a flier's cast")
	var dir: Vector3 = g.sun_direction({"elevation": 40.0, "yaw": -40.0})
	var perch := {"id": "dragonfly:0", "kind": "dragonfly", "art": "dragonfly", "pos": Vector3(4.5, 0.7, 6.5), "pose": "perch", "frame": 0, "dir": Vector2.RIGHT, "alpha": 1.0}
	var s0: Dictionary = IR.shadow_of(perch, 0.0, dir)
	check(not s0.is_empty() and (s0.at as Vector2).is_equal_approx(Vector2(4.5, 6.5)), "shadow: a perched dragonfly has a blob under it, with no sun")
	var s1: Dictionary = IR.shadow_of(perch, 1.0, dir)
	var slid: Vector2 = (s1.at as Vector2) - (s0.at as Vector2)
	check(not s1.is_empty() and slid.length() > 0.05 and slid.length() <= float(sh.perch_offset) + 0.001 and s1.size == s0.size, "shadow: in sun the blob falls along the light off its perch (%.2f cells, at most %.2f)" % [slid.length(), float(sh.perch_offset)])
	var lift := clampf(1.0 - 0.7 / float(sh.hop_fade), 0.4, 1.0)
	check(not s0.is_empty() and is_equal_approx(float(s0.get("alpha", -1.0)), float(sh.ground_alpha) * lift), "shadow: its alpha is ground_alpha lifted by the perch's height (%.3f)" % float(s0.get("alpha", -1.0)))
	check(not s0.is_empty() and (s0.size as Vector2).x < 0.6, "shadow: a small blob")
	var fly := {"id": "dragonfly:1", "kind": "dragonfly", "art": "dragonfly", "pos": Vector3(4.5, 1.0, 6.5), "pose": "fly", "frame": 0, "dir": Vector2.RIGHT, "alpha": 1.0}
	check(IR.shadow_of(fly, 0.0, dir).is_empty(), "shadow: a flier casts none without sun")
	var sf: Dictionary = IR.shadow_of(fly, 1.0, dir)
	check(not sf.is_empty() and float(sf.alpha) > 0.0 and float(sf.alpha) <= float(sh.fly_alpha) + 0.001, "shadow: a flier in sun casts a very faint one (%.3f)" % float(sf.get("alpha", -1.0)))
	check(not sf.is_empty() and ((sf.at as Vector2) - Vector2(4.5, 6.5)).length() <= float(sh.max_offset) + 0.001 and not (sf.at as Vector2).is_equal_approx(Vector2(4.5, 6.5)), "shadow: it falls along the sun, held to max_offset")
	check(IR.shadow_of(fly, 1.0, Vector3.UP).is_empty(), "shadow: a flier casts none when the sun is not low over it")
	var bf := fly.duplicate()
	bf.kind = "butterfly"
	var sb: Dictionary = IR.shadow_of(bf, 1.0, dir)
	check(not sb.is_empty() and (sb.size as Vector2).x < (sf.size as Vector2).x, "shadow: a butterfly's oval is smaller than a dragonfly's")
	# Buildings: a blob on one is left out; a flier whose oval lands on one casts none.
	check(IR.shadow_of(perch, 0.0, dir, {}, {Vector2i(4, 6): true}).is_empty(), "shadow: a perched one's blob on a building is left out")
	check(not IR.shadow_of(perch, 1.0, dir, {}, {Vector2i(9, 9): true}).is_empty(), "shadow: a perched one's blob off the buildings stays")
	var wall := {}
	for x in range(-2, 12):
		for y in range(-2, 14):
			wall[Vector2i(x, y)] = true
	check(IR.shadow_of(fly, 1.0, dir, {}, wall).is_empty(), "shadow: a flier whose shadow falls on a building casts none")
	var sc := {}
	var tb: Dictionary = IR.blocked_for(sc, MM.data("town"), null, g)
	check(tb.has(Vector2i(1, 8)) and not tb.has(Vector2i(20, 1)), "shadow: the blocked cells hold the town's houses (%d)" % tb.size())
	sc.blocked = {}   # the same built key: kept, not rebuilt
	check(IR.blocked_for(sc, MM.data("town"), null, g).is_empty(), "shadow: the blocked set is kept while the buildings stay")
	sc.built_key = "changed"   # a building finished: rebuilt
	check(IR.blocked_for(sc, MM.data("town"), null, g).size() == tb.size(), "shadow: rebuilt when the buildings change")


## `--insects=dragonfly:perched`: the first dragonfly rests on the perch nearest the aim, for good
## (held_perch; insects() with the kind forced to perch, set here as the command line sets it).
func _crop_perches() -> void:
	# The perch heights come from the 3D field's own plants: each crop's perch stands where a plant
	# of CropClusters.planted is, at that plant's top (its picture's top row times its size, no more
	# than the quad CropClusters draws and within 3 pixels of it); the eggplant (a single sprite) at
	# its picture's top over the cell's middle.
	var fm: MapData = MM.data("farm")
	var cases := {Vector2i(10, 10): "corn", Vector2i(12, 10): "rice", Vector2i(14, 10): "tomato", Vector2i(16, 10): "cucumber", Vector2i(18, 10): "eggplant"}
	for c in cases:
		var d: Dictionary = g.farm.cell(c)
		d.obj = 0
		d.crop = cases[c]
		d.stage = g.farm.ripe_stage(cases[c])
	var sc: Dictionary = IR.scene_of(fm, g.farm, 5)
	var CC: GDScript = load("res://scripts/world3d/crop_clusters.gd")
	var cc: Node3D = CC.new()
	root.add_child(cc)
	var clusters := {}
	for c in cases:
		var key: String = load("res://scripts/art/placeholder_art.gd").cell_key(g.farm, g.farm.cell(c))
		if CC.key_for(key) != "":
			clusters[c] = CC.key_for(key)
	cc.plant(clusters, func(_c: Vector2i) -> float: return 0.0)
	var kinds: Array = sc.perch_kinds
	check(kinds.size() == (sc.perches as Array).size(), "crop perches: every perch has a kind (%d)" % kinds.size())
	for c in cases:
		var id: String = cases[c]
		var mine: Array = []
		for i in kinds.size():
			if kinds[i] == id and floori(sc.perches[i].x) == c.x and floori(sc.perches[i].z) == c.y:
				mine.append(sc.perches[i])
		check(mine.size() == 1, "crop perches: %s has one perch" % id)
		if mine.size() != 1:
			continue
		var p: Vector3 = mine[0]
		if clusters.has(c):
			var hit: Array = cc.planted.filter(func(sp): return sp.cell == c and is_equal_approx(sp.pos.x, p.x) and is_equal_approx(sp.pos.z, p.z))
			check(hit.size() == 1, "crop perches: %s rests where a plant stands" % id)
			if hit.size() == 1:
				var sp: Dictionary = hit[0]
				var quad: float = (cc._layers[sp.tex].multimesh.mesh as QuadMesh).size.y * float(sp.size)
				check(is_equal_approx(p.y, CC.top_of(sp.tex) * float(sp.size)) and p.y <= quad + 0.001 and quad - p.y <= 3.0 * 0.045 + 0.001, "crop perches: %s rests on its plant's top (%.3f of a %.3f quad)" % [id, p.y, quad])
				check(cc.planted.all(func(o): return o.cell != c or o.pos.y + CC.top_of(o.tex) * float(o.size) <= p.y + 0.001), "crop perches: %s is its tallest plant" % id)
		else:
			var tex: Texture2D = load("res://scripts/art/placeholder_art.gd").tex(load("res://scripts/art/placeholder_art.gd").cell_key(g.farm, g.farm.cell(c)))
			var spr: Node = load("res://scripts/world3d/farm_world.gd").make_sprite(tex)
			var full: float = tex.get_height() * float(spr.pixel_size)
			spr.free()
			check(is_equal_approx(p.x, c.x + 0.5) and p.y <= full + 0.001 and full - p.y <= 3.0 * 0.045 + 0.001, "crop perches: %s rests on its sprite's top (%.3f of %.3f)" % [id, p.y, full])
	var ph: Dictionary = IR.config().dragonfly.perch_h
	check(not ph.has("rice") and not ph.has("corn") and not ph.has("paddy"), "crop perches: no crop height is guessed in the data any more")
	# The paddies' rice: a perch on a plant of the summer rice's own picture.
	var kam: Dictionary = IR.scene_of(MM.data("kaminoda"), null, 3)
	var pk: String = CC.paddy_key(str(IR.config().dragonfly.paddy_perch_season))
	var n := 0
	for i in (kam.perches as Array).size():
		if kam.perch_kinds[i] != "paddy":
			continue
		n += 1
		var q: Vector3 = kam.perches[i]
		var spots: Array = CC.spots_for({Vector2i(floori(q.x), floori(q.z)): pk})
		check(spots.any(func(sp): return is_equal_approx(sp.pos.x, q.x) and is_equal_approx(sp.pos.z, q.z) and is_equal_approx(q.y, CC.top_of(sp.tex) * float(sp.size))), "crop perches: a paddy perch rests on a rice plant's top (%.3f)" % q.y)
	check(n > 0, "crop perches: kaminoda has paddy perches (%d)" % n)
	for season in ["summer", "fall"]:
		check(is_equal_approx(CC.top_of(CC.paddy_key(season) + ":0"), CC.top_of(pk + ":0")), "crop perches: the %s rice is as tall as the summer rice" % season)
	# `--insects=dragonfly:perched:rice`: the nearest perch of that kind.
	var hr: Dictionary = IR.held_perch(sc, Vector2(10.5, 10.5), "rice")
	check(not hr.is_empty() and floori(hr.pos.x) == 12, "crop perches: held on the nearest rice")
	check(IR.held_perch(sc, Vector2(10.5, 10.5), "pumpkin").is_empty(), "crop perches: no perch of a kind the map has none of")
	cc.free()
	for c in cases:
		var d: Dictionary = g.farm.cell(c)
		d.crop = ""
		d.stage = 0


func _held() -> void:
	var sc: Dictionary = IR.scene_of(MM.data("kaminoda"), null, 3)
	check(not (sc.perches as Array).is_empty(), "held: kaminoda has perches (%d)" % (sc.perches as Array).size())
	var aim := Vector2(5.0, 9.0)
	var want := Vector3.ZERO
	var best := INF
	for p in sc.perches:
		if Vector2(p.x, p.z).distance_to(aim) < best:
			best = Vector2(p.x, p.z).distance_to(aim)
			want = p
	var h: Dictionary = IR.held_perch(sc, aim)
	check(h.get("pose", "") == "perch" and (h.get("pos", Vector3.ZERO) as Vector3).is_equal_approx(want), "held: the perch nearest the aim")
	# The farm's gate road has no fence post in 3D, so no fence perch may sit on it.
	var fm: MapData = MM.data("farm")
	var gates := fm.gate_cells()
	var fs: Dictionary = IR.scene_of(fm, g.farm, 3)
	var on_gate := false
	for p in fs.perches:
		on_gate = on_gate or Vector2i(floori(p.x), floori(p.z)) in gates
	check(not gates.is_empty() and not on_gate and not (fs.perches as Array).is_empty(), "held: no fence perch on the gate road (%d gate cells, %d perches)" % [gates.size(), (fs.perches as Array).size()])
	# A fence perch stands on the post's top (OutdoorProps.FENCE_POST_H, 0.64 and its cap), not above it.
	var post_h: float = load("res://scripts/world3d/outdoor_props.gd").FENCE_POST_H
	check(absf(float((IR.config().dragonfly.perch_h as Dictionary).fence) - post_h) <= 0.01, "held: the fence perch is on the post's top (%.3f vs %.3f)" % [float(IR.config().dragonfly.perch_h.fence), post_h])
	IR._forced_read = true
	IR._forced = ["dragonfly"]
	IR._perched_forced = ["dragonfly"]
	var at_t: Array = IR.insects("dragonfly", 1.0, 40.0, sc, aim, {}, {}, [])
	check(not at_t.is_empty() and at_t[0].pose == "perch" and (at_t[0].pos as Vector3).is_equal_approx(want), "held: the first dragonfly rests there at 40 s too")
	check(at_t.size() > 1 and at_t.slice(1).any(func(b): return b.pose == "fly"), "held: the others still fly")
	IR._forced = []
	IR._perched_forced = []
	check(IR.insects("dragonfly", 1.0, 40.0, sc, aim, {}, {}, []).all(func(b): return b.pose == "fly" or b.pose == "perch"), "held: back to the rules when not forced")


## Both 3D views build the node and show or hide it by the rules.
func _views() -> void:
	await process_frame
	var LayerS: GDScript = load("res://scripts/world3d/insect_layer.gd")
	var MapWorldS: GDScript = load("res://scripts/world3d/map_world.gd")
	var kam: MapData = MM.data("kaminoda")
	var w3: Node3D = MapWorldS.new()
	root.add_child(w3)
	for step in w3.build_steps(kam):
		step.call()
	var layers := w3.get_children().filter(func(n): return n.get_script() == LayerS)
	check(layers.size() == 1, "3D: an outdoor map builds one insect layer (%d)" % layers.size())
	for map_id in ["house", "mine_floor"]:
		var inside: Node3D = MapWorldS.new()
		root.add_child(inside)
		for step in inside.build_steps(MM.data(map_id)):
			step.call()
		check(inside.get_children().filter(func(n): return n.get_script() == LayerS).is_empty(), "3D: %s builds none" % map_id)
		inside.free()
	if layers.size() == 1:
		var layer: Node3D = layers[0]
		_when(2, 11, 0, "sunny", 12)
		layer.refresh()
		check(layer.shown_count() >= IR.count_for("dragonfly", 0.85) and layer.is_in_group("insect_layers"), "3D: dragonflies on a fall morning (%d)" % layer.shown_count())
		var sprites := layer.get_children().filter(func(n): return n is Sprite3D and n.visible)
		check(sprites.size() == layer.shown_count(), "3D: one visible sprite an insect (%d)" % sprites.size())
		var cut := true
		for n in layer.get_children():
			if n is Sprite3D:
				cut = cut and n.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD
		check(cut, "3D: the insect sprites are alpha-cut (solid, as the birds')")
		_when(2, 11, 0, "rain", 12)
		layer.refresh()
		check(layer.shown_count() == 0 and layer.get_children().filter(func(n): return n is Sprite3D and n.visible).is_empty(), "3D: none in rain")
		_when(2, 23, 0, "sunny", 12)
		layer.refresh()
		check(layer.shown_count() == 0, "3D: none at night")
		_when(0, 11, 0, "sunny", 5)
		layer.refresh()
		check(layer.shown().all(func(b): return b.kind == "butterfly") and layer.shown_count() > 0, "3D: butterflies on a spring day")
		# set_farmer hands over the farmer's place: a resting dragonfly lifts off.
		_when(2, 11, 0, "sunny", 12)
		layer.refresh()
		var scene: Dictionary = layer._scene
		var rest := _find_rest(scene, 0.0, 0.85)
		check(not rest.is_empty(), "3D: a dragonfly rests on a post here too")
		if not rest.is_empty():
			layer._t = float(rest[0])
			layer.refresh()
			var spot: Vector3 = rest[2]
			check(layer.shown().any(func(b): return b.id == rest[1] and b.pose == "perch"), "3D: it rests on its perch")
			check(layer.shadows().any(func(s): return (s.at as Vector2).distance_to(Vector2(spot.x, spot.z)) <= float(IR.config().shadow.perch_offset) + 0.01), "3D: a blob under the resting dragonfly")
			w3.set_farmer(Vector3(spot.x + 0.4, 0.0, spot.z))
			layer.refresh()
			check(layer.shown().any(func(b): return b.id == rest[1] and b.pose == "fly"), "3D: set_farmer by the perch sends the dragonfly up")
		_when(2, 11, 0, "sunny", 12)
		layer.refresh()
		var meshes := layer.get_children().filter(func(n): return n is MeshInstance3D and n.visible)
		check(meshes.size() == layer.shadows().size(), "3D: a shadow mesh per insect shadow (%d)" % meshes.size())
		var ground := true
		for m in meshes:
			ground = ground and m.layers == load("res://scripts/world3d/night_lamps.gd").GROUND_LAYER and m.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and m.position.y > 0.0 and m.position.y < 0.05
		check(ground, "3D: the insect shadows lie on the ground layer, cast nothing")
	w3.free()
	var M3: GDScript = load("res://scripts/main_3d.gd")
	var made: Array = M3.new_world(MM.data("farm"))
	for step in made[1]:
		step.call()
	check(made[0].get_children().any(func(n): return n.get_script() == LayerS), "3D: the farm builds an insect layer")
	made[0].free()


## The flat view: the node, the air pass, the resting ones among the figures.
func _flat() -> void:
	_when(2, 11, 0, "sunny", 12)
	var scene: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var view: Node2D = scene.view
	var bv: Node2D = null
	for n in view.get_children():
		if n.get_script() == load("res://scripts/world/insect_view.gd"):
			bv = n
	check(bv != null, "flat (main_2d): the map view has its insects")
	if bv == null:
		scene.free()
		return
	var figs: Node2D = view.get_node_or_null("Figures") as Node2D
	var air: Node2D = bv.air
	check(figs != null and bv.get_index() < figs.get_index(), "flat (main_2d): the insect view is before the figure layer")
	var air_z := _z_of(air)
	check(air_z > _z_of(scene.player) and air_z > _z_of(view) and air_z < _z_of(scene.weather), "flat (main_2d): fliers over the farmer, roofs and props, under the rain (z %d)" % air_z)
	check(air.get_canvas_layer_node() == null and scene.tint.get_canvas() == air.get_canvas(), "flat (main_2d): fliers under the night tint")
	bv.refresh()
	check(bv.visible and bv.sprites().size() >= IR.count_for("dragonfly", 0.85), "flat (main_2d): dragonflies on a fall morning (%d)" % bv.sprites().size())
	check(bv.shadows().size() <= bv.sprites().size() and bv.shadows().all(func(s): return float(s.alpha) > 0.0), "flat (main_2d): shadows for some of them, each with an alpha")
	check(bv.sprites().all(func(s): return s.air == (s.key as String).contains(":fly:")), "flat (main_2d): fliers in the air pass, the resting ones not")
	_when(2, 11, 0, "rain", 12)
	bv.refresh()
	check(not bv.visible and bv.sprites().is_empty(), "flat (main_2d): none in rain")
	_when(2, 11, 0, "sunny", 12)
	bv.refresh()
	# Find a moment when one rests: its node is in the figure layer, sorted by the ground under it.
	var found := false
	for step in 1600:
		bv._t = float(step) * 0.5
		bv.refresh()
		if not bv.perched_nodes().is_empty():
			found = true
			break
	check(found, "flat (main_2d): a dragonfly rests on a post within 800 s")
	if found:
		var nodes: Array[Node2D] = bv.perched_nodes()
		var resting := (bv.sprites() as Array).filter(func(s): return not s.air)
		check(nodes.size() == resting.size(), "flat (main_2d): a node for each resting dragonfly (%d)" % nodes.size())
		var n: Node2D = nodes[0]
		var s: Dictionary = resting[0]
		check(n.get_parent() == figs, "flat (main_2d): it is in the figure layer, sorted with the figures")
		check(n.position == (s.ground as Vector2) - Vector2(0, FOOT), "flat (main_2d): its origin is FOOT px above the ground under it, not up on the perch")
		check(bv.shadows().any(func(sh): return (sh.rect as Rect2).get_center().distance_to(s.ground) <= float(IR.config().shadow.perch_offset) * 16.0 + 2.0), "flat (main_2d): a blob on the ground under the resting one")
		check(n.picture.at.y < FOOT and n.picture.at.y == FOOT - ((s.ground as Vector2).y - (s.at as Vector2).y), "flat (main_2d): the picture is drawn up at the perch's height")
		check(not (bv.sprites() as Array).any(func(x): return x.air and (x.key as String).contains(":perch:")), "flat (main_2d): no resting picture in the air pass")
	bv.refresh()
	scene.queue_free()
	await process_frame


const FOOT := 2   # FigureLayer.FOOT (checked in test_view2d)


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
