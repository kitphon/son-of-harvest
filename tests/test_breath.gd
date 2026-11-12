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
	_wisps()
	_crawler()
	await _views()
	await _flat_order()
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
		check(layer._mm.instance_count == int(BR.config().cap.puffs_3d), "3D: the MultiMesh holds the data's cap (%d)" % layer._mm.instance_count)
		var low := 99.0
		for i in 300:
			layer._t = 40.0 + i * 0.1
			layer.refresh()
			for p in layer.puffs():
				low = minf(low, float(p.pos.y))
		layer.farmer = {"cell": Vector2(12, 12), "facing": Vector2(1, 0), "running": false, "tired": false, "lift": 1.5}
		var lowest_lifted := 99.0
		for i in 300:
			layer._t = 40.0 + i * 0.1
			layer.refresh()
			for p in layer.puffs():
				lowest_lifted = minf(lowest_lifted, float(p.pos.y))
		check(low < 1.5 and absf(lowest_lifted - low - 1.5) < 0.01, "3D: a lifted sprite (the ferry boat) lifts the farmer's puffs with it (%.2f -> %.2f)" % [low, lowest_lifted])
		check(layer.shown_count() <= int(BR.config().cap.puffs_3d), "3D: never more puffs than the cap")
	await process_frame
	var bv = ViewS.new().setup(town)
	check(bv.z_index == 0, "flat: the puffs have no z of their own (they sort with the figures)")
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


## A breath is a few overlapping sub-puffs, each softer and smaller than the one before it, drawn
## wider than tall in 3D; it stays subtle (never a cloud); the cap trims a crowd.
func _wisps() -> void:
	var cfg: Dictionary = BR.config()
	var cell := Vector2(10, 10)
	var east := Vector2(1, 0)
	var early: Array = BR.wisp(cell, east, "person", 0.1, 1.0, 0.0, 7, 3, cfg)
	var later: Array = BR.wisp(cell, east, "person", 0.7, 1.0, 0.0, 7, 3, cfg)
	check(early.size() == 1, "a breath starts as one puff at the mouth (%d)" % early.size())
	check(later.size() == int(cfg.wisp.count), "later it is %d overlapping sub-puffs (%d)" % [int(cfg.wisp.count), later.size()])
	check(BR.wisp(cell, east, "person", 0.0, 1.0, 0.0, 7, 3, cfg).is_empty(), "no sub-puff before the breath starts")
	var ok := true
	for i in range(1, later.size()):
		if float(later[i].alpha) > float(later[i - 1].alpha) + 0.0001 or float(later[i].size) > float(later[i - 1].size) + 0.0001:
			ok = false
	for p in later:
		if float(p.alpha) > float(cfg.alpha.max) + 0.0001:
			ok = false
	check(ok, "each sub-puff is softer and smaller than the one before, none brighter than the data's alpha")
	check(float(later[0].stretch) > 1.0, "the wisp is wider than tall (stretch %.2f)" % float(later[0].stretch))
	check(float(later[0].size) * float(later[0].stretch) < 0.8, "a puff is never a cloud (%.2f cells wide at most)" % (float(later[0].size) * float(later[0].stretch)))
	check(Color(str(cfg.color)).v > 0.95 and Color(str(cfg.color)).s < 0.1, "the tint is a bright pale white")
	var a: Array = BR.wisp(cell, east, "person", 0.7, 1.0, 0.0, 7, 3, cfg)
	var b: Array = BR.wisp(cell, east, "person", 0.7, 1.0, 0.0, 7, 3, cfg)
	check(a[1].pos == b[1].pos, "a wisp is the same every time (hashed, not random)")
	# The cap.
	var figs := []
	for i in 40:
		figs.append({"id": "crowd:%d" % i, "cell": Vector2(i, 3), "facing": Vector2(1, 0), "kind": "person"})
	var seen := 0
	for k in 200:
		var list: Array = BR.puffs_now(figs, {}, 10.0 + k * 0.37, 1.0, 0.0, cfg)
		seen = maxi(seen, list.size())
	check(seen > int(cfg.cap.puffs_flat), "a crowd of 40 can give more puffs (%d) than the flat cap (%d)" % [seen, int(cfg.cap.puffs_flat)])
	check(BR.capped(BR.puffs_now(figs, {}, 10.0 + 37 * 0.37, 1.0, 0.0, cfg), 5).size() <= 5, "capped keeps at most the limit")
	check(int(cfg.cap.puffs_3d) >= 64 and int(cfg.cap.puffs_flat) > 0, "the caps are in the data")


## The crawler breathes too: its own kind, a lower mouth, a smaller puff, in both views' rules.
func _crawler() -> void:
	var cfg: Dictionary = BR.config()
	var cell := Vector2(4, 4)
	check(BR.kind_of("crawler") == "crawler" and BR.kind_of("toddler") == "child" and BR.kind_of("child") == "child" and BR.kind_of("") == "person", "kinds by stage: crawler, toddler and child, grown")
	check(BR.mouth(cell, Vector2.ZERO, "crawler", cfg).y < BR.mouth(cell, Vector2.ZERO, "child", cfg).y, "a crawler's mouth is lower than a child's")
	check(BR.mouth(cell, Vector2.ZERO, "crawler", cfg).y < BR.mouth(cell, Vector2.ZERO, "person", cfg).y, "... and than a grown person's")
	check(float(BR.shape(cell, Vector2.ZERO, "crawler", 0.5, 1.0, 0.0, cfg).size) < float(BR.shape(cell, Vector2.ZERO, "child", 0.5, 1.0, 0.0, cfg).size), "a crawler's puff is smaller than a child's")
	var shown := 0
	var lowest := 99.0
	var figs := [{"id": "v:child", "cell": cell, "facing": Vector2(0, 1), "kind": "crawler"}]
	for i in 200:
		for p in BR.puffs_now(figs, {}, 30.0 + i * 0.2, 1.0, 0.0, cfg):
			shown += 1
			lowest = minf(lowest, float(p.pos.y))
	check(shown > 0 and lowest < 0.8, "a crawler's breath shows (%d puffs), from low down (%.2f)" % [shown, lowest])
	check(BR.KINDS.has("crawler") and (cfg.scale as Dictionary).has("crawler"), "the data knows the crawler")


## The flat view's puffs sort with the figures: each figure's puffs are one node in the figure
## layer at the owner's origin, so they draw just over their own figure, over a figure standing
## behind, and under one in front. Built main_2d, a fake villager in front and behind the farmer.
func _flat_order() -> void:
	g.season = 3
	g.day = 10
	g.hour = 6
	g.minute = 30
	g.weather_today = "sunny"
	var scene: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var view: Node2D = scene.view
	var bv = null
	for n in view.get_children():
		if n.get_script() != null and (n.get_script() as Script).resource_path.ends_with("breath_view.gd"):
			bv = n
	check(bv != null, "flat (main_2d): the map view has its breath view")
	var figs: Node2D = view.get_node_or_null("Figures")
	var vv = null
	if figs != null:
		for n in figs.get_children():
			if n.get_script() != null and (n.get_script() as Script).resource_path.ends_with("villager_view.gd"):
				vv = n
	if bv == null or figs == null or vv == null:
		scene.queue_free()
		await process_frame
		return
	var player: Node2D = scene.player
	player.position = Vector2(200, 200)
	var white := Color(str(BR.config().color))
	var farmer_puff := {"id": "farmer", "origin": player.position, "at": player.position + Vector2(4, -14), "px": 3.0, "alpha": 0.4, "color": white}
	var walker := Sprite2D.new()   # a villager sprite as VillagerView makes them
	walker.centered = false
	walker.offset = player.figure.offset
	walker.texture = player.figure.texture
	vv.add_child(walker)
	vv._sprites["test_walker"] = walker
	walker.position = player.position + Vector2(0, -6)   # six px behind the farmer (north)
	bv._puffs.assign([farmer_puff, {"id": "v:test_walker", "origin": walker.position, "at": walker.position + Vector2(4, -14), "px": 3.0, "alpha": 0.4, "color": white}])
	bv._place()
	var fnode: Node2D = bv._nodes.get("farmer")
	var wnode: Node2D = bv._nodes.get("v:test_walker")
	check(fnode != null and wnode != null and fnode.get_parent() == figs and wnode.get_parent() == figs, "flat (main_2d): each figure's puffs are a node of the figure layer")
	check(bv.nodes().size() == 2, "flat (main_2d): one node a figure with puffs (%d)" % bv.nodes().size())
	var order: Array = figs.draw_order()
	check(order.find(fnode) > order.find(player), "flat (main_2d): the farmer's puff is drawn over the farmer (%d > %d)" % [order.find(fnode), order.find(player)])
	check(order.find(wnode) > order.find(walker) and order.find(wnode) < order.find(player), "flat (main_2d): a puff of the figure behind is over its own figure and under the farmer in front (%d, %d, %d)" % [order.find(walker), order.find(wnode), order.find(player)])
	check(order.find(fnode) > order.find(wnode), "flat (main_2d): the farmer's puff is over the one behind")
	walker.position = player.position + Vector2(0, 6)   # now six px in front (south)
	bv._puffs[1].origin = walker.position
	bv._place()
	order = figs.draw_order()
	check(order.find(fnode) < order.find(walker) and order.find(fnode) < order.find(wnode), "flat (main_2d): the farmer's puff is under a figure in front and its puff (%d < %d)" % [order.find(fnode), order.find(walker)])
	check(order.find(wnode) > order.find(walker), "flat (main_2d): ... and that figure's puff is over it")
	check(is_equal_approx(fnode.position.y, player.position.y + float(BR.config().flat.nudge_px)), "flat (main_2d): a puff node sits the data's nudge below its owner's origin")
	check(fnode.z_index == player.z_index and fnode.get_canvas_layer_node() == null, "flat (main_2d): ... at the figures' z, on the world's canvas under the night tint")
	bv._puffs.clear()
	bv._place()
	check(bv.nodes().is_empty(), "flat (main_2d): the nodes hide when nothing breathes")
	# A real frame: the farmer's puff node follows the farmer.
	vv._sprites.erase("test_walker")
	walker.free()
	var found := false
	for i in 200:
		bv._t = 30.0 + i * 0.1
		bv.refresh()
		if bv._nodes.has("farmer") and (bv._nodes.farmer as Node2D).visible:
			found = true
			check(absf((bv._nodes.farmer as Node2D).position.y - (player.position.y + float(BR.config().flat.nudge_px))) < 0.01, "flat (main_2d): a live puff node is at the farmer's origin")
			break
	check(found, "flat (main_2d): the farmer breathes in the cold in the built view")
	check(bv.puffs().size() <= int(BR.config().cap.puffs_flat), "flat (main_2d): never more puffs than the flat cap")
	scene.queue_free()
	await process_frame
