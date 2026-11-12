extends SceneTree
## Headless checks for breath in the cold (BreathRules, data/breath.json): how cold it is by season,
## day, clock and weather look (none indoors or in the mine), the gaps between each figure's puffs
## (its own, never in step), a puff's shape (mouth by facing, drift, wind, fade, growth), the
## flat view's whole pixels, and both views building and placing the puffs (BreathLayer in 3D,
## BreathView in the flat view). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_breath.gd

var failures := 0
var g: Node
var BR: GDScript


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	BR = load("res://scripts/breath_rules.gd")
	g.new_game()
	g.clock_running = false
	_cold()
	_gating()
	_puffs()
	_shape()
	_tracking()
	_pixels()
	await _views()
	print("test_breath: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


## The cold by season, day, clock and weather look (BreathRules.cold_strength).
func _cold() -> void:
	check(BR.cold_strength("winter", 15, "sunny", 6.5) == 1.0, "winter at dawn is full cold")
	check(BR.cold_strength("winter", 15, "sunny", 22.0) == 1.0, "winter at night is full cold")
	check(absf(BR.cold_strength("winter", 15, "sunny", 12.5) - 0.55) < 0.001, "winter midday is milder (0.55)")
	check(BR.cold_strength("winter", 15, "sunny", 12.5) < BR.cold_strength("winter", 15, "sunny", 6.5), "midday below dawn")
	check(BR.cold_strength("winter", 15, "sunny", 11.0) < 1.0, "the midday ease starts after 10:00")
	check(BR.cold_strength("fall", 20, "sunny", 6.0) == 0.0, "fall before its last ten days: none")
	check(absf(BR.cold_strength("fall", 25, "sunny", 6.0) - 0.7) < 0.001, "late fall mornings 0.7")
	check(BR.cold_strength("fall", 25, "sunny", 9.0) == 0.0, "late fall after 8:00: none")
	check(absf(BR.cold_strength("spring", 3, "sunny", 7.0) - 0.7) < 0.001, "early spring mornings 0.7")
	check(BR.cold_strength("spring", 8, "sunny", 7.0) == 0.0, "spring after its first week: none")
	check(BR.cold_strength("summer", 10, "sunny", 6.0) == 0.0, "summer: none")
	check(BR.cold_strength("winter", 10, "rain", 6.5) == 0.5, "rain thins it to half")
	check(BR.cold_strength("winter", 10, "snow", 6.5) == 1.0, "snow is as cold as sun")
	check(BR.cold_strength("winter", 10, "storm", 6.5) == 0.0, "a storm hides it")
	check(BR.cold_strength("winter", 10, "blizzard", 6.5) == 0.0, "a blizzard hides it")


## Indoors, in the mine and without a clock: none. Outdoors on a winter dawn: full.
func _gating() -> void:
	var MM: GDScript = load("res://scripts/world/map_manager.gd")
	var town: MapData = MM.data("town")
	var house: MapData = MM.data("house")
	var mine: MapData = MM.data("mine_floor")
	g.season = 3   # winter
	g.day = 10
	g.hour = 6
	g.minute = 30
	g.weather_today = "sunny"
	check(BR.strength_now(g, town) == 1.0, "winter dawn outdoors: full")
	check(BR.strength_now(g, house) == 0.0, "indoors: none")
	check(BR.strength_now(g, mine) == 0.0, "the mine: none")
	check(BR.strength_now(null, town) == 0.0, "no clock: none")
	g.hour = 12
	g.minute = 30
	check(absf(BR.strength_now(g, town) - 0.55) < 0.001, "winter midday outdoors: 0.55")
	g.season = 1   # summer
	check(BR.strength_now(g, town) == 0.0, "summer: none")
	g.season = 3
	g.hour = 6
	g.minute = 30


## Each figure's puffs: its own gap (2..4 s, moved by the jitter), never two at once, the colder
## the more of them, a runner's and a tired farmer's faster.
func _puffs() -> void:
	var cfg: Dictionary = BR.config()
	var onsets := _onsets("v:tome", 1.0, 1.0, 120.0)
	check(onsets.size() > 20, "a figure puffs often in full cold (%d in 120 s)" % onsets.size())
	var gaps := []
	for i in range(1, onsets.size()):
		gaps.append(onsets[i] - onsets[i - 1])
	var lo := 99.0
	var hi := 0.0
	var mean := 0.0
	for x in gaps:
		lo = minf(lo, x)
		hi = maxf(hi, x)
		mean += x
	mean /= maxf(gaps.size(), 1)
	check(lo > float(cfg.life), "puffs never overlap (shortest gap %.2f s)" % lo)
	check(hi <= 4.0 * (1.0 + float(cfg.gap.jitter) * 2.0) + 0.01, "no gap longer than the data allows (%.2f s)" % hi)
	check(mean > 2.0 and mean < 4.0, "a puff every 2..4 s on average (%.2f s)" % mean)
	var other := _onsets("v:kota", 1.0, 1.0, 120.0)
	check(other.size() > 0 and (other[0] != onsets[0] or other.size() != onsets.size()), "two figures do not puff in step")
	check(_onsets("v:tome", 1.0, 1.6, 120.0).size() > onsets.size(), "a running farmer puffs faster")
	check(_onsets("v:tome", 0.5, 1.0, 120.0).size() < onsets.size(), "a weaker cold: fewer puffs")
	check(_onsets("v:tome", 0.0, 1.0, 120.0).is_empty(), "no cold: no puffs")
	var u_ok := true
	for i in 2000:
		var ph: Dictionary = BR.phase(BR.seed_of("v:tome"), i * 0.06, 1.0, 1.0, cfg)
		if not ph.is_empty() and not (float(ph.u) >= 0.0 and float(ph.u) < 1.0):
			u_ok = false
	check(u_ok, "a breath's life share is 0..1")
	check(BR.seed_of("v:tome") == BR.seed_of("v:tome") and BR.seed_of("v:tome") != BR.seed_of("v:kota"), "seeds: steady and per figure")


## The times (seconds) a figure's breath starts over `span` seconds.
func _onsets(id: String, strength: float, rate: float, span: float) -> Array:
	var out := []
	var was := false
	var seed: int = BR.seed_of(id)
	var t := 0.0
	while t < span:
		var on: bool = not BR.phase(seed, t, rate, strength).is_empty()
		if on and not was:
			out.append(t)
		was = on
		t += 0.02
	return out


## A puff's shape: from the mouth on the side it faces, forward and up, growing, fading in and out,
## at most the data's alpha, scaled by the strength, drifting with the wind.
func _shape() -> void:
	var cfg: Dictionary = BR.config()
	var cell := Vector2(10, 10)
	var east := Vector2(1, 0)
	var e: Dictionary = BR.shape(cell, east, "person", 0.5, 1.0, 0.0, cfg)
	check(e.pos.x > cell.x and absf(e.pos.z - cell.y) < 0.3, "facing east: the puff leaves to the east")
	var n: Dictionary = BR.shape(cell, Vector2(0, -1), "person", 0.5, 1.0, 0.0, cfg)
	check(n.pos.z < cell.y, "facing north: the puff leaves to the north")
	var s: Dictionary = BR.shape(cell, Vector2.ZERO, "person", 0.5, 1.0, 0.0, cfg)
	check(s.pos.z > cell.y, "no facing: south, towards the camera")
	check(BR.mouth(cell, east, "child", cfg).y < BR.mouth(cell, east, "person", cfg).y, "a child's mouth is lower than a grown one's")
	check(BR.mouth(cell, Vector2.ZERO, "animal", cfg).y < BR.mouth(cell, Vector2.ZERO, "child", cfg).y, "an animal's mouth is lowest")
	check(BR.shape(cell, east, "person", 0.0, 1.0, 0.0, cfg).alpha == 0.0, "a puff starts unseen")
	check(BR.shape(cell, east, "person", 1.0, 1.0, 0.0, cfg).alpha == 0.0, "a puff ends unseen")
	var mid: Dictionary = BR.shape(cell, east, "person", 0.3, 1.0, 0.0, cfg)
	check(mid.alpha > 0.0 and mid.alpha <= float(cfg.alpha.max) + 0.0001, "a puff shows at most the data's alpha")
	check(absf(BR.shape(cell, east, "person", 0.3, 0.5, 0.0, cfg).alpha - mid.alpha * 0.5) < 0.0001, "the strength scales the alpha")
	var ok := true
	for i in 21:
		var a: float = BR.shape(cell, east, "person", i * 0.05, 1.0, 0.5, cfg).alpha
		if a < 0.0 or a > float(cfg.alpha.max) + 0.0001:
			ok = false
	check(ok, "alpha stays within 0..max")
	check(BR.shape(cell, east, "person", 0.9, 1.0, 0.0, cfg).size > BR.shape(cell, east, "person", 0.1, 1.0, 0.0, cfg).size, "a puff grows")
	check(BR.shape(cell, east, "person", 1.0, 1.0, 0.0, cfg).pos.y > BR.shape(cell, east, "person", 0.0, 1.0, 0.0, cfg).pos.y, "a puff rises")
	var still: Dictionary = BR.shape(cell, east, "person", 0.9, 1.0, 0.0, cfg)
	var windy: Dictionary = BR.shape(cell, east, "person", 0.9, 1.0, 1.0, cfg)
	check(windy.pos.x > still.pos.x, "the wind bends a puff along its way")


## The facing and movement of a figure from one frame to the next, the given facing winning.
func _tracking() -> void:
	var st := {}
	var r1: Dictionary = BR.track(st, "x", Vector2(1, 1), Vector2.ZERO)
	check(not r1.moving and r1.facing.is_equal_approx(Vector2(0, 1)), "a new figure stands, facing south")
	var r2: Dictionary = BR.track(st, "x", Vector2(2, 1), Vector2.ZERO)
	check(r2.moving and r2.facing.is_equal_approx(Vector2(1, 0)), "a figure that walks east faces east")
	var r3: Dictionary = BR.track(st, "x", Vector2(2, 1), Vector2.ZERO)
	check(not r3.moving and r3.facing.is_equal_approx(Vector2(1, 0)), "standing still keeps the way it faced")
	var r4: Dictionary = BR.track(st, "x", Vector2(2, 1), Vector2(0, -1))
	check(r4.facing.is_equal_approx(Vector2(0, -1)), "a given facing wins")


## The flat view's whole pixels: one pixel, a 2x2 block, or a plus.
func _pixels() -> void:
	check(BR.pixels(0.8).size() == 1, "under 1.5 px: one pixel")
	check(BR.pixels(2.2).size() == 4, "2 px: a 2x2 block")
	check(BR.pixels(3.1).size() == 5, "3 px: a plus")


## Both views build and place the puffs: the 3D layer on an outdoor map only, the flat view's
## screen mapping in whole pixels.
func _views() -> void:
	var MM: GDScript = load("res://scripts/world/map_manager.gd")
	var LayerS: GDScript = load("res://scripts/world3d/breath_layer.gd")
	var ViewS: GDScript = load("res://scripts/world/breath_view.gd")
	var MapWorldS: GDScript = load("res://scripts/world3d/map_world.gd")
	var town: MapData = MM.data("town")
	var w3: Node3D = MapWorldS.new()
	root.add_child(w3)
	for step in w3.build_steps(town):
		step.call()
	var layers := w3.get_children().filter(func(n): return n.get_script() == LayerS)
	check(layers.size() == 1, "3D: an outdoor map builds one breath layer (%d)" % layers.size())
	var inside: Node3D = MapWorldS.new()
	root.add_child(inside)
	for step in inside.build_steps(MM.data("house")):
		step.call()
	check(inside.get_children().filter(func(n): return n.get_script() == LayerS).is_empty(), "3D: a room builds none")
	if not layers.is_empty():
		var layer = layers[0]
		layer.farmer = {"cell": Vector2(12, 12), "facing": Vector2(1, 0), "running": false, "tired": false}
		var shown := 0
		for i in 300:
			layer._t = 40.0 + i * 0.1
			layer.refresh()
			shown = maxi(shown, layer.shown_count())
		check(shown > 0, "3D: the farmer breathes in the cold (at most %d puffs in a frame)" % shown)
		check(layer.figures().size() >= 1, "3D: the farmer is one of the figures")
	await process_frame
	var bv = ViewS.new().setup(town)
	check(bv.z_index == int(BR.config().flat.z), "flat: the puffs draw at the data's z")
	var lift := int(BR.config().flat.height_px)
	check(bv.screen_of(Vector3(1, 1, 1)) == Vector2(16, 16 - lift), "flat: a puff at (1, 1) and height 1 is at (16, %d) px" % (16 - lift))
	var figs := [{"id": "farmer", "cell": Vector2(5, 5), "facing": Vector2(1, 0), "kind": "person"}]
	var count := 0
	var whole := true
	for i in 300:
		bv._t = 40.0 + i * 0.1
		for p in bv.puffs_for(figs):
			count += 1
			if not (p.at as Vector2).is_equal_approx((p.at as Vector2).round()):
				whole = false
	check(count > 0, "flat: the farmer's puffs show (%d)" % count)
	check(whole, "flat: the puffs sit on whole pixels")
	bv.free()
	for n in [w3, inside]:
		n.free()
