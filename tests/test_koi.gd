extends SceneTree
## Headless checks for the koi in the temple garden's pond (KoiPondRules, data/koi.json; KoiPondArt;
## KoiPondLayer in 3D, KoiPondView in the flat view): the pond's water cells (no rocks), fish by
## season, every fish kept in open water off the banks while it swims, moving and turning no faster
## than allowed, over the pond's flat bed (never on the bank's slope), each wandering on its own
## (now resting, now swimming, all over the pond, no crowding), the tail's frames; the pictures; both
## views build the fish on the village and none elsewhere, the flat one under the water's skin. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_koi.gd

var failures := 0
var g: Node
var KL: GDScript   # KoiPondLayer, KoiPondView, SunkenGround, WaterSurface: loaded (their scripts need the autoloads)
var KV: GDScript
var SG: GDScript
var WS: GDScript


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	KL = load("res://scripts/world3d/koi_pond_layer.gd")
	KV = load("res://scripts/world/koi_pond_view.gd")
	SG = load("res://scripts/world3d/sunken_ground.gd")
	WS = load("res://scripts/world3d/water_surface.gd")
	g.new_game()
	_data()
	_swim()
	_wander()
	_art()
	await _view_3d()
	await _view_flat()
	print("test_koi: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


func _town() -> MapData:
	return MapManager.data("town")


func _data() -> void:
	var cfg := KoiPondRules.config()
	check(not (cfg.ponds as Array).is_empty() and float(cfg.margin) > 0.0 and float(cfg.margin) < 0.5 and float(cfg.speed.winter) < float(cfg.speed.cruise),
		"data/koi.json: ponds, a margin under half a cell, slower in winter")
	for s in ["spring", "summer", "fall", "winter"]:
		check(KoiPondRules.count_in(s) > 0, "koi show in %s (%d)" % [s, KoiPondRules.count_in(s)])
	check(KoiPondRules.count_in("winter") < KoiPondRules.count_in("summer"), "fewer koi show in winter")
	for p in cfg.patterns:
		check(KoiPondArt.COLOURS.has(p), "pattern %s has its colours" % p)
	check(KoiPondRules.ponds_on("town").size() == 1 and KoiPondRules.ponds_on("farm").is_empty() and KoiPondRules.ponds_on("river").is_empty(),
		"the temple pond is the village's; the farm pond and the river have none")
	var t := _town()
	var cells := KoiPondRules.water_cells(t, KoiPondRules.ponds_on("town")[0])
	var bad := cells.keys().filter(func(c): return t.tile(c) != "water" or not t.prop_at(c).is_empty())
	check(cells.size() >= 25 and bad.is_empty(), "the pond's water: %d cells, none under a rock or on land" % cells.size())


func _swim() -> void:
	var t := _town()
	var pond: Dictionary = KoiPondRules.ponds_on("town")[0]
	var k := KoiPondRules.make(t, pond, "summer", 7)
	check(k.fish.size() == KoiPondRules.count_in("summer"), "summer: %d fish" % k.fish.size())
	check(KoiPondRules.make(t, pond, "winter", 7).fish.size() == KoiPondRules.count_in("winter"), "winter: fewer fish")
	var start: Array = k.fish.map(func(f): return f.pos)
	var stray := 0
	var fast := 0
	var sharp := 0
	var travelled := 0.0
	var cfg := KoiPondRules.config()
	var cap := float(cfg.speed.cruise) * (1.0 + float(cfg.speed.spread)) * float(cfg.leg[1]) + 0.01
	for i in 1800:   # a minute at 30 frames a second
		var before: Array = k.fish.map(func(f): return [f.pos, f.heading])
		k.step(1.0 / 30.0)
		for j in k.fish.size():
			var f: Dictionary = k.fish[j]
			if not k.allowed(f.pos):
				stray += 1
			var moved: float = (f.pos as Vector2).distance_to(before[j][0])
			travelled += moved
			if moved > cap / 30.0 + 0.0001:
				fast += 1
			if absf(wrapf(float(f.heading) - float(before[j][1]), -PI, PI)) > float(cfg.turn) / 30.0 + 0.0001:
				sharp += 1
	check(stray == 0, "every fish stays in open water off the banks and rocks (%d strays)" % stray)
	var on_slope := k.fish.filter(func(f): return not k.shape.on_bed(f.pos))
	check(k.shape != null and on_slope.is_empty(), "every fish keeps over the pond's flat bed, off the bank's slope")
	check(fast == 0 and sharp == 0, "no fish swims or turns faster than allowed (%d / %d)" % [fast, sharp])
	var moved_far := 0
	for j in k.fish.size():
		if (k.fish[j].pos as Vector2).distance_to(start[j]) > 0.5:
			moved_far += 1
	check(travelled / k.fish.size() > 4.0 and moved_far >= k.fish.size() / 2, "they swim about (%.1f cells each in a minute, %d moved off)" % [travelled / k.fish.size(), moved_far])
	var frames := {}
	for f in k.fish:
		for ph in [-1.2, 0.0, 1.2]:
			f.phase = ph
			frames[KoiPondRules.frame_of(f)] = true
	check(frames.size() == 3, "the tail's three frames")


## Each fish wanders on its own (the user, 2026-11-16): over three minutes every fish both rests
## and swims, goes to many places all over the pond, and the school does not crowd into one spot.
func _wander() -> void:
	var t := _town()
	var pond: Dictionary = KoiPondRules.ponds_on("town")[0]
	var k := KoiPondRules.make(t, pond, "summer", 31)
	var rested := {}
	var swam := {}
	var places := {}
	var rest_frames := 0
	var frames := 5400   # three minutes at 30 a second
	for i in frames:
		k.step(1.0 / 30.0)
		for j in k.fish.size():
			var f: Dictionary = k.fish[j]
			if KoiPondRules.resting(f):
				rested[j] = true
				rest_frames += 1
			elif float(f.speed) > 0.1:
				swam[j] = true
			if not places.has(j):
				places[j] = {}
			places[j][Vector2i((f.pos as Vector2).floor())] = true
	var share := float(rest_frames) / (frames * k.fish.size())
	check(rested.size() == k.fish.size() and swam.size() == k.fish.size(), "every fish both rests and swims (%d rested, %d swam of %d)" % [rested.size(), swam.size(), k.fish.size()])
	check(share > 0.15 and share < 0.7, "they rest a fair share of the time, not all of it (%.0f%%)" % (share * 100.0))
	var few := places.keys().filter(func(j): return places[j].size() < 6)
	check(few.is_empty(), "every fish goes all over the pond (fish with under 6 cells visited: %s)" % [few])
	var spread := 0.0
	var pairs := 0
	for a in k.fish.size():
		for b in range(a + 1, k.fish.size()):
			spread += (k.fish[a].pos as Vector2).distance_to(k.fish[b].pos)
			pairs += 1
	check(spread / pairs > 1.5, "the school does not crowd into one spot (mean %.2f cells apart)" % (spread / pairs))
	var cfg := KoiPondRules.config()
	check(not cfg.has("gather"), "no fish is drawn to the farmer (each wanders on its own)")


func _art() -> void:
	for p in KoiPondArt.COLOURS:
		for fr in 3:
			var img := PlaceholderArt.image("pondkoi:%s:%d" % [p, fr])
			var solid := 0
			for y in img.get_height():
				for x in img.get_width():
					solid += 1 if img.get_pixel(x, y).a > 0.5 else 0
			check(img.get_width() == KoiPondArt.W and img.get_height() == KoiPondArt.H and solid >= 25 and img.get_pixel(15, 0).a < 0.5 and img.get_pixel(15, 6).a < 0.5,
				"koi picture %s:%d: %dx%d, %d solid px" % [p, fr, img.get_width(), img.get_height(), solid])
	var up := PlaceholderArt.image("pondkoi:orange:0")
	var down := PlaceholderArt.image("pondkoi:orange:2")
	check(up.get_data() != down.get_data(), "the tail bends both ways")
	var kohaku := PlaceholderArt.image("pondkoi:kohaku:1")
	var red := 0
	for x in KoiPondArt.W:
		for y in KoiPondArt.H:
			var c := kohaku.get_pixel(x, y)
			red += 1 if c.a > 0.5 and c.r > 0.7 and c.g < 0.4 else 0
	check(red >= 4, "kohaku: red patches on white (%d red px)" % red)


func _view_3d() -> void:
	await process_frame
	g.maps.place("town", Vector2i(26, 25), Vector2i.LEFT)
	var main3d: GDScript = load("res://scripts/main_3d.gd")
	var pair: Array = main3d.new_world(_town())
	var mw: Node3D = pair[0]
	root.add_child(mw)
	for step in pair[1]:
		step.call()
	var layers := mw.get_children().filter(func(n): return n.get_script() == KL)
	check(layers.size() == 1, "3D: the village builds one koi layer (%d)" % layers.size())
	if layers.size() == 1:
		var layer: Node3D = layers[0]
		check(layer.fish_count() == KoiPondRules.count_in(g.season_name()), "3D: %d fish" % layer.fish_count())
		var sprites := layer.get_children().filter(func(n): return n is Sprite3D)
		var flat := true
		for s: Sprite3D in sprites:
			flat = flat and s.axis == Vector3.AXIS_Y and s.billboard == BaseMaterial3D.BILLBOARD_DISABLED 				and s.position.y < -float(SG.DROP) + float(WS.LIFT) and s.position.y > -float(SG.DROP)
		check(sprites.size() == layer.fish_count() and flat, "3D: each fish a flat sprite on the sunk bed, under the water's skin")
		var before: Vector3 = sprites[0].position
		for i in 30:
			layer._process(1.0 / 30.0)
		check(sprites[0].position.distance_to(before) > 0.0 or layer.schools[0].fish[0].rest > 0.0, "3D: the fish move")
	root.remove_child(mw)
	mw.free()
	var pair2: Array = main3d.new_world(MapManager.data("river"))
	var rw: Node3D = pair2[0]
	root.add_child(rw)
	for step in pair2[1]:
		step.call()
	check(rw.get_children().filter(func(n): return n.get_script() == KL).is_empty(), "3D: the river has no koi layer")
	root.remove_child(rw)
	rw.free()


func _view_flat() -> void:
	g.maps.place("town", Vector2i(26, 25), Vector2i.LEFT)
	var scene: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var mv: Node = scene.get("view")
	var views := mv.get_children().filter(func(n): return n.get_script() == KV) if mv != null else []
	check(views.size() == 1, "flat: the village draws its koi (%d)" % views.size())
	if views.size() == 1:
		var kv: Node2D = views[0]
		var water: Node = mv.get("_water")
		check(kv.fish_count() == KoiPondRules.count_in(g.season_name()), "flat: %d fish" % kv.fish_count())
		check(water != null and kv.get_index() < water.get_index(), "flat: the koi under the water's moving skin")
	root.remove_child(scene)
	scene.free()
