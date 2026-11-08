extends SceneTree
## Headless checks for the puddles in rain (PuddleRules, data/puddles.json): gating (rain and
## storm only, none in snow, with snow lying, indoors or in the mine), growth over the first hour
## of rain, drying after a rainy day, placement (path and gravel only, never grass, water,
## buildings or props; the farm's doorsteps), sizes by wetness, the rain rings, and both views
## (PuddleLayer in 3D, PuddleView in the flat view) building and showing by the rules. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_puddles.gd

var failures := 0
var g: Node
var PR: GDScript


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	PR = load("res://scripts/puddle_rules.gd")
	g.new_game()
	g.clock_running = false
	_gating()
	_growth_and_drying()
	_placement()
	_sizes()
	_rings()
	await _views()
	print("test_puddles: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _when(season: int, hour: int, minute: int, weather: String, yesterday := "") -> void:
	g.season = season
	g.day = 10
	g.hour = hour
	g.minute = minute
	g.weather_today = weather
	g.weather_yesterday = yesterday
	g.snow_cover = 0


## Rain and storm make it wet; nothing else does; lying snow, indoors and the mine keep it dry.
func _gating() -> void:
	check(PR.wetness("rain", "", 12.0, 0.0) > 0.0 and PR.wetness("storm", "", 12.0, 0.0) > 0.0, "rain and storm make the ground wet")
	check(PR.wetness("sunny", "", 12.0, 0.0) == 0.0, "a fair day: dry")
	check(PR.wetness("snow", "", 12.0, 0.0) == 0.0 and PR.wetness("blizzard", "", 12.0, 0.0) == 0.0, "snow and blizzard: dry")
	check(PR.wetness("rain", "", 12.0, 20.0) == 0.0, "rain on lying snow: dry")
	check(PR.wetness("storm", "rain", 12.0, 5.0) == 0.0, "snow lying also dries yesterday's rain at once")
	check(PR.wetness("storm", "", 12.0, 0.0) > PR.wetness("rain", "", 12.0, 0.0), "a storm is wetter than rain")
	var town: MapData = MapManager.data("town")
	_when(0, 12, 0, "rain")
	check(PR.wetness_now(g, town) > 0.0, "town in rain at noon: wet")
	check(PR.raining_now(g, town), "rain falls on the puddles in rain")
	_when(0, 12, 0, "sunny", "")
	check(PR.wetness_now(g, town) == 0.0 and not PR.raining_now(g, town), "town on a fair day: dry")
	_when(3, 12, 0, "storm")   # a winter storm is a blizzard
	check(PR.wetness_now(g, town) == 0.0, "a winter storm (a blizzard): dry")
	_when(0, 12, 0, "rain")
	var house: MapData = MapManager.data("house")
	var mine: MapData = MapManager.data("mine_floor")
	check(PR.wetness_now(g, house) == 0.0, "indoors: dry")
	check(PR.wetness_now(g, mine) == 0.0, "the mine: dry")
	check(PR.puddles(house).is_empty() and PR.puddles(mine).is_empty(), "no puddle places indoors or in the mine")


## 0 at the start of the day's rain, full after grow_hours; yesterday's rain dries over dry_hours.
func _growth_and_drying() -> void:
	var cfg: Dictionary = PR.config()
	var top := float(cfg.looks.rain.max)
	check(PR.wetness("rain", "", 6.0, 0.0) == 0.0, "rain just begun at 06:00: no puddles yet")
	var half: float = PR.wetness("rain", "", 6.5, 0.0)
	check(is_equal_approx(half, top * 0.5 / float(cfg.grow_hours)), "half way through the growth hour: half wet (%.2f)" % half)
	check(is_equal_approx(PR.wetness("rain", "", 7.0, 0.0), top) and is_equal_approx(PR.wetness("rain", "", 20.0, 0.0), top), "full after the first hour and stays")
	var last := -1.0
	var rising := true
	for i in 13:
		var w: float = PR.wetness("storm", "", 6.0 + float(i) * 0.1, 0.0)
		rising = rising and w >= last
		last = w
	check(rising, "wetness only grows through the first hour")
	check(is_equal_approx(PR.wetness("sunny", "rain", 6.0, 0.0), top), "after a rainy day the ground starts the morning wet")
	var d1: float = PR.wetness("sunny", "rain", 7.0, 0.0)
	check(is_equal_approx(d1, top * 0.5), "one hour into a couple of dry hours: half dry (%.2f)" % d1)
	check(PR.wetness("sunny", "rain", 8.0, 0.0) == 0.0 and PR.wetness("sunny", "rain", 15.0, 0.0) == 0.0, "dry again two hours after")
	check(PR.wetness("sunny", "snow", 6.0, 0.0) == 0.0, "yesterday's snow leaves nothing")
	check(PR.wetness("rain", "storm", 6.0, 0.0) > PR.wetness("rain", "", 6.0, 0.0), "rain after a storm starts from what the storm left")
	check(is_equal_approx(PR.since_start(2.0), 20.0), "the small hours still belong to the day before 06:00")
	_when(0, 7, 0, "sunny", "rain")
	var town: MapData = MapManager.data("town")
	check(is_equal_approx(PR.wetness_now(g, town), top * 0.5), "wetness_now reads Game.weather_yesterday")
	check(not PR.raining_now(g, town), "the drying ground gets no rain rings")
	g.new_game()
	check(g.weather_yesterday == "", "a new game has no yesterday")
	_when(0, 7, 0, "rain")
	g.weather_tomorrow = "sunny"
	g.weather_yesterday = ""
	g.end_day()
	check(g.weather_yesterday == "rain", "the day's end keeps its weather as yesterday's")


## Only path and gravel that are free of solid ground and props; the farm's doorsteps; stable per map.
func _placement() -> void:
	var cfg: Dictionary = PR.config()
	var any := 0
	for id in ["town", "kaminoda", "sakurazaka", "hill", "river", "minamino"]:
		var m: MapData = MapManager.data(id)
		var ps: Array[Dictionary] = PR.puddles(m)
		any += ps.size()
		var ok := true
		for p in ps:
			var c: Vector2i = p.cell
			ok = ok and m.tile(c) in cfg.tiles and not m.is_solid(c) and m.prop_at(c).is_empty()
			ok = ok and absf(float(p.ox)) + float(p.rx) <= 0.5 and absf(float(p.oy)) + float(p.ry) <= 0.5   # inside its cell
			ok = ok and float(p.rx) > float(p.ry)
		check(ok, "%s: every puddle on free path or gravel, inside its cell" % id)
		check(ps == PR.puddles(m), "%s: the places do not change between calls" % id)
		var path_cells := 0
		var hit := 0
		for y in m.h:
			for x in m.w:
				var c := Vector2i(x, y)
				if PR.eligible(m, c):
					path_cells += 1
				else:
					for p in ps:
						if p.cell == c:
							hit += 1
		check(hit == 0, "%s: none on grass, water, paddies, floors or props" % id)
		if path_cells > 10:
			check(ps.size() > 0 and ps.size() < path_cells, "%s: some of its %d path cells hold a puddle (%d)" % [id, path_cells, ps.size()])
	check(any > 20, "the villages have puddles in all (%d)" % any)
	var town: MapData = MapManager.data("town")
	var grass := Vector2i(-1, -1)
	var water := Vector2i(-1, -1)
	for y in town.h:
		for x in town.w:
			var c := Vector2i(x, y)
			if town.tile(c) == "grass" and grass.x < 0:
				grass = c
			if town.tile(c) == "water" and water.x < 0:
				water = c
	check(not PR.eligible(town, grass) and not PR.eligible(town, water), "grass and water cells are never eligible")
	check(not PR.eligible(town, Vector2i(-3, 2)), "off the map is never eligible")
	# The farm: doorsteps only, no grass, tilled soil or pond.
	var farm: FarmGrid = g.farm
	var fm: MapData = MapManager.data("farm")
	var fps: Array[Dictionary] = PR.puddles(fm, farm)
	var fok := true
	for p in fps:
		fok = fok and str(farm.fixed_at(p.cell)) in cfg.farm_fixed
	check(fok and fps.size() > 0, "the farm: puddles only on its doorsteps (%d)" % fps.size())
	check(not PR.eligible(fm, Vector2i(10, 10), farm), "the farm's open field and plots are never eligible")
	farm.cell(Vector2i(10, 10)).tilled = true
	check(not PR.eligible(fm, Vector2i(10, 10), farm), "tilled soil never")
	check(not PR.eligible(fm, Vector2i(26, 3), farm), "the pond never")


## Puddles gather one by one, grow with the wetness, vanish when it goes.
func _sizes() -> void:
	var town: MapData = MapManager.data("town")
	var ps: Array[Dictionary] = PR.puddles(town)
	var shown := func(wet: float) -> int:
		var n := 0
		for p in ps:
			if PR.scale_of(p, wet) > 0.0:
				n += 1
		return n
	check(shown.call(0.0) == 0, "no wetness: no puddle")
	var a: int = shown.call(0.3)
	var b: int = shown.call(0.8)
	var c: int = shown.call(1.0)
	check(a > 0 and a < b and b <= c, "more puddles gather as it gets wetter (%d, %d, %d)" % [a, b, c])
	check(c < ps.size() or c == ps.size(), "a storm fills at most all of them")
	var big := ps[0]
	var s1: float = PR.scale_of(big, float(big.on) + (1.0 - float(big.on)) * 0.5)
	var s2: float = PR.scale_of(big, 1.0)
	check(s1 > 0.0 and s1 < s2 and is_equal_approx(s2, 1.0), "a puddle's size grows to full (%.2f -> %.2f)" % [s1, s2])
	check(PR.scale_of(big, float(big.on) * 0.5) == 0.0, "under its own start wetness: none")
	check(PR.step_of(0.0) == 0 and PR.step_of(1.0) == 50 and PR.step_of(0.8) == 40, "wetness steps of 1/50")


## The rain rings: from the water's style, none without it, always inside the puddle, growing with time.
func _rings() -> void:
	var town: MapData = MapManager.data("town")
	var p: Dictionary = PR.puddles(town)[0]
	var style: Dictionary = g.weather_fx.rain.dimples
	check(PR.dimples(p, 3.0, {}).is_empty(), "no style, no rings")
	var seen := 0
	var inside := true
	var rings_ok := true
	for i in 200:
		for d in PR.dimples(p, float(i) * 0.25, style):
			seen += 1
			inside = inside and (d.pos as Vector2).length() <= 0.51
			rings_ok = rings_ok and float(d.ring) >= 0.0 and float(d.ring) < 1.0
	check(seen > 10, "rings appear over time in rain (%d in 50 s)" % seen)
	check(inside and rings_ok, "rings stay inside the puddle and run 0..1")
	var storm_seen := 0
	for i in 200:
		storm_seen += PR.dimples(p, float(i) * 0.25, g.weather_fx.storm.dimples).size()
	check(storm_seen > seen, "a storm has more rings than rain (%d > %d)" % [storm_seen, seen])


func _views() -> void:
	var town: MapData = MapManager.data("town")
	_when(0, 12, 0, "rain")
	var layer := PuddleLayer.new(town)
	root.add_child(layer)
	var view := PuddleView.new().setup(town)
	root.add_child(view)
	await process_frame
	var expected := 0
	var wet: float = float(PR.step_of(PR.wetness_now(g, town))) / 50.0
	for p in PR.puddles(town):
		if PR.scale_of(p, wet) > 0.0:
			expected += 1
	check(expected > 0, "rain at noon puts puddles on the town's paths (%d)" % expected)
	check(layer.shown_count() == expected and layer.visible, "3D layer shows what the rules give (%d)" % layer.shown_count())
	check(layer.raining(), "3D layer: rings in rain")
	check(view.shown().size() == expected and view.visible, "flat view shows what the rules give (%d)" % view.shown().size())
	check(view.raining(), "flat view: rings in rain")
	# A fair day: gone.
	_when(0, 12, 0, "sunny")
	layer.refresh()
	view.refresh()
	check(layer.shown_count() == 0 and not layer.visible and not layer.raining(), "3D layer: none on a fair day")
	check(view.shown().is_empty() and not view.visible, "flat view: none on a fair day")
	# Just begun: nothing; then gathering.
	_when(0, 6, 0, "storm")
	layer.refresh()
	view.refresh()
	check(layer.shown_count() == 0 and view.shown().is_empty(), "storm at 06:00: not yet")
	_when(0, 6, 30, "storm")
	layer.refresh()
	view.refresh()
	var mid: int = layer.shown_count()
	check(mid > 0 and mid == view.shown().size(), "storm at 06:30: some gathered, both views alike (%d)" % mid)
	_when(0, 7, 30, "storm")
	layer.refresh()
	view.refresh()
	check(layer.shown_count() > mid, "storm at 07:30: more (%d)" % layer.shown_count())
	# Drying the morning after.
	_when(0, 7, 0, "sunny", "storm")
	layer.refresh()
	view.refresh()
	var drying: int = layer.shown_count()
	check(drying > 0 and not layer.raining(), "the morning after a storm: still wet, no rings (%d)" % drying)
	_when(0, 9, 0, "sunny", "storm")
	layer.refresh()
	view.refresh()
	check(layer.shown_count() == 0 and view.shown().is_empty(), "two hours on: dry")
	# Snow lying.
	_when(0, 12, 0, "rain")
	g.snow_cover = 30
	layer.refresh()
	view.refresh()
	check(layer.shown_count() == 0 and view.shown().is_empty(), "snow lying: none")
	g.snow_cover = 0
	layer.free()
	view.free()
	# Indoors: nothing built.
	var house: MapData = MapManager.data("house")
	var hl := PuddleLayer.new(house)
	root.add_child(hl)
	await process_frame
	check(hl.shown_count() == 0 and not hl.visible, "indoors: none")
	hl.free()
	# The farm's own world and a flat map view carry them in their builds.
	check(FileAccess.get_file_as_string("res://scripts/main_3d.gd").contains("PuddleLayer.new(m, Game.farm)"), "the farm's 3D world builds a PuddleLayer")
	check(FileAccess.get_file_as_string("res://scripts/world3d/map_world.gd").contains("PuddleLayer.new(map)"), "the outdoor maps' 3D worlds build a PuddleLayer")
	check(FileAccess.get_file_as_string("res://scripts/main_2d.gd").contains("PuddleView.new()"), "the flat view builds a PuddleView")
