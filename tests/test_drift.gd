extends SceneTree
## Headless checks for the seasonal drifting life outdoors (DriftRules, data/drift.json): cherry
## petals in spring, leaves in fall, fireflies on summer nights; the season / weather / clock /
## indoor gating, the wind carrying the motes, counts inside the data's bounds, and both views
## (DriftLayer + DriftGlow in 3D, DriftView in the flat view) building and showing them. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_drift.gd

var failures := 0
var g: Node
var DR: GDScript


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	DR = load("res://scripts/drift_rules.gd")
	g.new_game()
	g.clock_running = false
	_gating()
	_motes()
	_scenes()
	await _views()
	print("test_drift: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
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


## Which kinds show when: season, weather look, clock window and its fade; nothing indoors or in the mine.
func _gating() -> void:
	var cfg: Dictionary = DR.config()
	check(DR.amount("petal", "spring", "sunny", 12.0) == 1.0, "petals: a fair spring noon, full")
	check(DR.amount("petal", "summer", "sunny", 12.0) == 0.0 and DR.amount("petal", "fall", "sunny", 12.0) == 0.0 \
		and DR.amount("petal", "winter", "sunny", 12.0) == 0.0, "petals: spring only")
	check(DR.amount("petal", "spring", "sunny", 22.0) == 0.0 and DR.amount("petal", "spring", "sunny", 3.0) == 0.0, "petals: not in the dark")
	var rain: float = DR.amount("petal", "spring", "rain", 12.0)
	check(rain > 0.0 and rain < 1.0, "petals: thinner in rain (%.2f)" % rain)
	check(DR.amount("petal", "spring", "storm", 12.0) == 0.0 and DR.amount("petal", "spring", "snow", 12.0) == 0.0, "petals: none in a storm or snow")
	check(DR.amount("leaf", "fall", "sunny", 12.0) == 1.0 and DR.amount("leaf", "spring", "sunny", 12.0) == 0.0, "leaves: fall only")
	var lrain: float = DR.amount("leaf", "fall", "rain", 12.0)
	check(lrain > 0.0 and lrain < 1.0 and DR.amount("leaf", "fall", "storm", 12.0) == 0.0, "leaves: thinner in rain, none in a storm")
	check(DR.amount("firefly", "summer", "sunny", 22.0) == 1.0 and DR.amount("firefly", "summer", "sunny", 2.0) == 1.0, "fireflies: a clear summer night, 22:00 and 2:00 (the window wraps midnight)")
	check(DR.amount("firefly", "summer", "sunny", 12.0) == 0.0 and DR.amount("firefly", "summer", "sunny", 6.0) == 0.0, "fireflies: not by day")
	check(DR.amount("firefly", "spring", "sunny", 22.0) == 0.0 and DR.amount("firefly", "fall", "sunny", 22.0) == 0.0, "fireflies: summer only")
	check(DR.amount("firefly", "summer", "rain", 22.0) == 0.0 and DR.amount("firefly", "summer", "storm", 22.0) == 0.0, "fireflies: none in rain or a storm")
	var edge: float = DR.amount("firefly", "summer", "sunny", float(cfg.firefly.hours[0]) + float(cfg.firefly.fade_hours) / 2.0)
	check(edge > 0.0 and edge < 1.0, "fireflies: ease in over the fade (%.2f)" % edge)
	# Through Game and a map: outdoor maps only.
	var MM: GDScript = load("res://scripts/world/map_manager.gd")
	var town: MapData = MM.data("town")
	var house: MapData = MM.data("house")
	var mine: MapData = MM.data("mine_floor")
	_when(0, 12, 0, "sunny")
	check(DR.amounts_now(g, town).has("petal") and DR.amounts_now(g, town).size() == 1, "spring noon outdoors: petals only")
	check(DR.amounts_now(g, house).is_empty() and DR.amounts_now(g, mine).is_empty(), "spring noon indoors / in the mine: nothing")
	check(DR.amounts_now(null, town).is_empty(), "no clock: nothing")
	_when(1, 22, 0, "sunny")
	check(DR.amounts_now(g, town).has("firefly") and DR.amounts_now(g, house).is_empty() and DR.amounts_now(g, mine).is_empty(), "summer night: fireflies outdoors, none inside or in the mine")
	_when(1, 22, 0, "storm")
	check(DR.amounts_now(g, town).is_empty(), "summer night storm: nothing")
	_when(2, 12, 0, "sunny")
	check(DR.amounts_now(g, town).has("leaf"), "fall noon: leaves")
	_when(3, 12, 0, "sunny")
	check(DR.amounts_now(g, town).is_empty(), "winter: nothing")
	for kind in DR.KINDS:
		var n: int = DR.count_for(kind, 1.0)
		check(n == int(cfg[kind].count) and n >= 1 and n <= 40, "%s: full amount is the data's count, few (%d)" % [kind, n])
		check(DR.count_for(kind, 0.3) >= 1 and DR.count_for(kind, 0.3) < n and DR.count_for(kind, 0.0) == 0, "%s: a thin amount thins the count, zero is none" % kind)


## Where the motes are: inside bounds, near the trees, pushed along the wind.
func _motes() -> void:
	var cfg: Dictionary = DR.config()
	var area := Rect2(0, 0, 30, 20)
	var scene := {"area": area, "trees": {"petal": [Vector2(10.5, 8.5)], "leaf": []}, "wet": [Vector2(20.5, 5.5)], "dry": [Vector2(5.5, 15.5)]}
	var ms: Array = DR.motes("petal", 1.0, 3.0, 0.0, scene)
	check(ms.size() == int(cfg.petal.count), "petals: the data's count (%d)" % ms.size())
	var ok := true
	var near := 0
	for m in ms:
		ok = ok and m.pos.y >= 0.0 and m.pos.y <= float(cfg.petal.tree_height) + 0.2 and m.alpha >= 0.0 and m.alpha <= 1.0
		if Vector2(m.pos.x, m.pos.z).distance_to(Vector2(10.5, 8.5)) < float(cfg.petal.tree_radius) + float(cfg.petal.drift_wind) * float(cfg.petal.life) * 2.0:
			near += 1
	check(ok, "petals: heights within the tree's, alpha 0..1")
	check(near > ms.size() / 2, "petals: most start near the cherry (%d of %d)" % [near, ms.size()])
	check(DR.motes("leaf", 1.0, 3.0, 0.0, scene).size() == int(cfg.leaf.count), "leaves: the data's count")
	# The wind: the same moment in a gale lies further along the wind's direction than in calm air, and over time the motes move along it.
	var dir: Vector2 = DR.wind_dir()
	var calm: Array = DR.motes("petal", 1.0, 3.0, 0.0, scene)
	var gale: Array = DR.motes("petal", 1.0, 3.0, 1.0, scene)
	var push := 0.0
	var behind := 0
	for i in calm.size():
		var d := Vector2(gale[i].pos.x - calm[i].pos.x, gale[i].pos.z - calm[i].pos.z)
		push += d.dot(dir)
		behind += 1 if d.dot(dir) < -0.001 else 0
	check(push > 0.0 and behind == 0, "petals: a gale carries them further along the wind (%.2f, %d behind)" % [push, behind])
	var later: Array = DR.motes("petal", 1.0, 3.2, 0.5, scene)
	var now: Array = DR.motes("petal", 1.0, 3.0, 0.5, scene)
	var along := 0.0
	var slid := 0
	for i in now.size():
		var d := Vector2(later[i].pos.x - now[i].pos.x, later[i].pos.z - now[i].pos.z)
		if absf(d.x) < 2.0 and absf(d.y) < 2.0:   # the same fall (a restart jumps)
			along += d.dot(dir)
			slid += 1
	check(slid > 0 and along / slid > 0.0, "petals: they drift along the wind's direction over time (%.3f)" % (along / maxf(slid, 1)))
	check(dir.x > 0.0 and dir.y > 0.0, "the wind blows toward +x / +z")
	# Falling means going down: the height of the same mote falls over a short step.
	var fell := 0
	for i in now.size():
		if absf(later[i].pos.y - now[i].pos.y) < 1.0 and later[i].pos.y <= now[i].pos.y + 0.1:
			fell += 1
	check(fell > now.size() / 2, "petals: they fall (%d of %d)" % [fell, now.size()])
	# Fireflies: over the water or the grass spots, low, blinking (alpha between 0 and 1, and not all the same).
	var fl: Array = DR.motes("firefly", 1.0, 5.0, 0.15, scene)
	check(fl.size() == int(cfg.firefly.count), "fireflies: the data's count")
	var lo := float(cfg.firefly.height[0])
	var hi := float(cfg.firefly.height[1])
	var low_ok := true
	var alphas := {}
	for m in fl:
		low_ok = low_ok and m.pos.y >= lo - 0.001 and m.pos.y <= hi + 0.001 and m.alpha >= 0.0 and m.alpha <= 1.0
		alphas[snappedf(m.alpha, 0.05)] = true
	check(low_ok, "fireflies: floating between the data's heights")
	check(alphas.size() > 2, "fireflies: out of step with each other (%d levels)" % alphas.size())
	var wet := 0
	for m in fl:
		if Vector2(m.pos.x, m.pos.z).distance_to(Vector2(20.5, 5.5)) < float(cfg.firefly.wander) * 2.0:
			wet += 1
	check(wet > 0 and wet < fl.size(), "fireflies: some over the water, some over the grass (%d of %d)" % [wet, fl.size()])
	var blinks := false
	for t in [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]:
		for m in DR.motes("firefly", 1.0, t, 0.0, scene):
			blinks = blinks or m.alpha < 0.05
	check(blinks, "fireflies: blink off between")
	# Pure: the same arguments, the same motes.
	check(DR.motes("firefly", 1.0, 5.0, 0.15, scene)[0].pos == fl[0].pos, "motes are a pure function of their arguments")


## The places a map gives: its cherry trees, its water; the farm's pond; festival cherries add to the trees.
func _scenes() -> void:
	var MM: GDScript = load("res://scripts/world/map_manager.gd")
	var sk: MapData = MM.data("sakurazaka")
	var s: Dictionary = DR.scene_of(sk)
	check(s.trees.petal.size() >= 5, "sakurazaka: its cherry trees are the petals' (%d)" % s.trees.petal.size())
	check(s.trees.leaf.size() >= 1, "sakurazaka: its maple is a leaf tree (%d)" % s.trees.leaf.size())
	check(s.area == Rect2(0, 0, sk.w, sk.h), "the area is the whole map")
	var town: MapData = MM.data("town")
	var ts: Dictionary = DR.scene_of(town)
	check(ts.wet.size() > 0 and ts.dry.size() > 0, "town: water and open grass spots (%d / %d)" % [ts.wet.size(), ts.dry.size()])
	var farm: FarmGrid = g.farm
	var fs: Dictionary = DR.scene_of(MM.data("farm"), farm)
	check(fs.wet.size() == 12 and fs.dry.size() > 0, "farm: the pond's twelve cells and grass spots (%d / %d)" % [fs.wet.size(), fs.dry.size()])
	var plus: Dictionary = DR.scene_of(town, null, [{"kind": "sakura", "cell": [12, 7]}])
	check(plus.trees.petal.size() == ts.trees.petal.size() + 1, "a festival cherry adds a petal tree")
	_when(0, 10, 0, "sunny")
	check(DR.festival_props_today(g, town).is_empty(), "no festival today: no extra trees")
	g.day = 8   # Blossom Day
	if g.festival_today() == "blossom_day":
		check(DR.festival_props_today(g, town).size() >= 1 and DR.festival_props_today(g, MM.data("house")).is_empty(), "Blossom Day: the cherries on the festival's map only")


## Both views build the node and show or hide it by the rules.
func _views() -> void:
	await process_frame
	var MM: GDScript = load("res://scripts/world/map_manager.gd")
	var LayerS: GDScript = load("res://scripts/world3d/drift_layer.gd")
	var ViewS: GDScript = load("res://scripts/world/drift_view.gd")
	var MapWorldS: GDScript = load("res://scripts/world3d/map_world.gd")
	# 3D: an outdoor map builds a layer, a room and the mine do not.
	var sk: MapData = MM.data("sakurazaka")
	var w3: Node3D = MapWorldS.new()
	root.add_child(w3)
	for step in w3.build_steps(sk):
		step.call()
	var layers := w3.get_children().filter(func(n): return n.get_script() == LayerS)
	check(layers.size() == 1, "3D: an outdoor map builds one drift layer (%d)" % layers.size())
	var inside: Node3D = MapWorldS.new()
	root.add_child(inside)
	for step in inside.build_steps(MM.data("house")):
		step.call()
	check(inside.get_children().filter(func(n): return n.get_script() == LayerS).is_empty(), "3D: a room builds none")
	var cave: Node3D = MapWorldS.new()
	root.add_child(cave)
	for step in cave.build_steps(MM.data("mine_floor")):
		step.call()
	check(cave.get_children().filter(func(n): return n.get_script() == LayerS).is_empty(), "3D: the mine builds none")
	if layers.size() == 1:
		var layer: Node3D = layers[0]
		_when(0, 12, 0, "sunny")
		layer.refresh()
		check(layer.shown_count() > 0 and layer.fireflies().is_empty(), "3D: petals drift on a spring noon (%d)" % layer.shown_count())
		_when(0, 12, 0, "storm")
		layer.refresh()
		check(layer.shown_count() == 0, "3D: none in a storm")
		_when(2, 12, 0, "sunny")
		layer.refresh()
		check(layer.shown_count() > 0, "3D: leaves in fall (%d)" % layer.shown_count())
		_when(3, 12, 0, "sunny")
		layer.refresh()
		check(layer.shown_count() == 0, "3D: none in winter")
		_when(1, 22, 0, "sunny")
		layer.refresh()
		check(layer.shown_count() == 0 and layer.fireflies().size() > 0, "3D: fireflies on a summer night, no petals (%d)" % layer.fireflies().size())
		# The glow control is made and the layer is in its group.
		check(layer.is_in_group("drift_layers"), "3D: the layer is in the glow group (in tree %s)" % layer.is_inside_tree())
		var wind0: float = w3.wind
		w3.set_wind(1.0)
		_when(0, 12, 0, "sunny")
		layer.refresh()
		check(layer.shown_count() > 0 and w3.wind == 1.0 and wind0 == 0.0, "3D: the layer reads the world's wind")
	var glow: Control = load("res://scripts/world3d/drift_glow.gd").new()
	check(glow != null and glow.mouse_filter == Control.MOUSE_FILTER_IGNORE, "3D: DriftGlow builds")
	glow.free()
	w3.free()
	inside.free()
	cave.free()
	# The farm's world step: Main3D.new_world gives the farm a layer too.
	var M3: GDScript = load("res://scripts/main_3d.gd")
	var made: Array = M3.new_world(MM.data("farm"))
	for step in made[1]:
		step.call()
	check(made[0].get_children().any(func(n): return n.get_script() == LayerS), "3D: the farm builds a drift layer")
	made[0].free()
	# Flat: the view shows petals by day, fireflies at night, nothing indoors.
	var tint := CanvasModulate.new()
	tint.color = Color(0.3, 0.35, 0.55)
	var v: Node2D = ViewS.new().setup(sk)
	v.tint = tint
	root.add_child(v)
	_when(0, 12, 0, "sunny")
	v.refresh()
	check(v.visible and v.specks().size() == int(DR.config().petal.count) and v.flies().is_empty(), "flat: petals on a spring noon (%d)" % v.specks().size())
	var in_px := true
	for s in v.specks():
		in_px = in_px and s.at == s.at.round() and s.color.a >= 0.0 and s.color.a <= 1.0
	check(in_px, "flat: whole pixels")
	_when(0, 12, 0, "storm")
	v.refresh()
	check(not v.visible, "flat: hidden in a storm")
	_when(1, 22, 0, "sunny")
	v.refresh()
	check(v.visible and v.specks().is_empty() and v.flies().size() == int(DR.config().firefly.count), "flat: fireflies on a summer night (%d)" % v.flies().size())
	v._glow.queue_redraw()
	var room: Node2D = ViewS.new().setup(MM.data("house"))
	root.add_child(room)
	room.refresh()
	check(not room.visible and room.specks().is_empty() and room.flies().is_empty(), "flat: a room gets none")
	var fv: Node2D = ViewS.new().setup(MM.data("farm"), g.farm)
	root.add_child(fv)
	_when(2, 12, 0, "sunny")
	fv.refresh()
	check(fv.visible and fv.specks().size() == int(DR.config().leaf.count), "flat: the farm gets leaves in fall (%d)" % fv.specks().size())
	# The drift's pixel on screen follows the height.
	check(v.screen_of(Vector3(2, 1, 3)).y < v.screen_of(Vector3(2, 0, 3)).y, "flat: higher is further up the screen")
	v.free()
	room.free()
	fv.free()
	tint.free()
