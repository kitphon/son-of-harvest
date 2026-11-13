extends SceneTree
## Headless checks for the icicles on the eaves in winter (IcicleRules, data/icicles.json): the
## gating (winter only, with snow lying on the roofs; none indoors, in the mine or the
## greenhouse), the growth over the winter and with the snow, the melt round a sunny midday and the
## freeze back by night, the drip; the placement (spots along an eave from a hash of its ends:
## the same every time, different on another eave, inside the eave, tucked under it; the flat
## view's spots clear of the doors); the eave lines the roof builders list (Minka.note_eave:
## the farmhouse, the village houses' front eaves, kept through MeshCache, none from the
## greenhouse's glass); and both views building and showing by the rules (IcicleLayer on a built
## world in 3D, IcicleView in the flat view). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_icicles.gd

var failures := 0
var g: Node
var FW: GDScript   # FarmWorld, MapWorld: loaded once the autoloads are up
var MW: GDScript


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	FW = load("res://scripts/world3d/farm_world.gd")
	MW = load("res://scripts/world3d/map_world.gd")
	g.new_game()
	g.clock_running = false
	_gating()
	_growth_and_melt()
	_placement()
	await _eaves()
	await _layer3d()
	_flat()
	print("test_icicles: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _when(season: int, day: int, hour: int, weather: String, cover: int) -> void:
	g.season = season
	g.day = day
	g.hour = hour
	g.minute = 0
	g.weather_today = weather
	g.snow_cover = cover


## Winter with snow on the roofs only; outdoors only.
func _gating() -> void:
	var cfg := IcicleRules.config()
	check(IcicleRules.forced() == IcicleRules.NONE, "not forced in a test run")
	check(IcicleRules.amount("winter", 10, 8.0, "snow", 60.0) > 0.0, "a snowy winter morning: icicles")
	for s in ["spring", "summer", "fall"]:
		check(IcicleRules.amount(s, 10, 8.0, "sunny", 60.0) == 0.0, "%s: none" % s)
	var low := float(cfg.min_cover)
	check(IcicleRules.amount("winter", 10, 8.0, "sunny", low - 1.0) == 0.0, "too little snow on the roofs: none")
	check(IcicleRules.amount("winter", 10, 8.0, "sunny", low) > 0.0, "min_cover of snow: some")
	check(IcicleRules.amount("winter", 10, 8.0, "sunny", 0.0) == 0.0, "no snow lying: none")
	_when(3, 10, 8, "snow", 60)
	var town: MapData = MapManager.data("town")
	var farm: MapData = MapManager.data("farm")
	check(IcicleRules.amount_now(g, town) > 0.0, "the village in winter: icicles")
	check(IcicleRules.amount_now(g, farm) > 0.0, "the farm in winter: icicles")
	for id in ["house", "mine_floor", "greenhouse", "store", "coop"]:
		var m: MapData = MapManager.data(id)
		check(not IcicleRules.outdoors(m) and IcicleRules.amount_now(g, m) == 0.0, "%s: none (indoors, the mine or under glass)" % id)
	_when(1, 10, 8, "sunny", 60)
	check(IcicleRules.amount_now(g, town) == 0.0, "summer in the village: none")


## Longer over the winter's first weeks, a little longer with more snow; a sunny midday melts
## them back, the night freezes them again; grey days never melt; drips only while melting.
func _growth_and_melt() -> void:
	var g1 := IcicleRules.grown(1, 0.5)
	var g5 := IcicleRules.grown(5, 0.5)
	var g18 := IcicleRules.grown(18, 0.5)
	check(g1 < g5 and g5 < g18, "grown over the cold days: day 1 %.2f < day 5 %.2f < day 18 %.2f" % [g1, g5, g18])
	check(IcicleRules.grown(30, 0.5) < g18, "shorter again at the winter's end (%.2f)" % IcicleRules.grown(30, 0.5))
	check(IcicleRules.grown(10, 1.0) > IcicleRules.grown(10, 0.2), "more snow lying: longer")
	check(IcicleRules.grown(18, 1.0) <= 1.0, "never past full")
	var morning := IcicleRules.amount("winter", 10, 8.0, "sunny", 60.0)
	var noon := IcicleRules.amount("winter", 10, 14.0, "sunny", 60.0)
	var night := IcicleRules.amount("winter", 10, 22.0, "sunny", 60.0)
	check(noon < morning * 0.75, "a sunny midday melts them back (%.2f -> %.2f)" % [morning, noon])
	check(is_equal_approx(night, morning), "frozen back by night (%.2f)" % night)
	check(IcicleRules.amount("winter", 10, 11.0, "sunny", 60.0) > noon, "melting through the late morning")
	check(IcicleRules.amount("winter", 10, 18.0, "sunny", 60.0) > noon and IcicleRules.amount("winter", 10, 18.0, "sunny", 60.0) < night,
		"freezing again through the evening")
	for look in ["snow", "blizzard"]:
		check(is_equal_approx(IcicleRules.amount("winter", 10, 14.0, look, 60.0), morning), "%s: no melt at midday" % look)
	check(IcicleRules.dripping("sunny", 13.0, noon), "a sunny midday: dripping")
	check(not IcicleRules.dripping("sunny", 8.0, morning), "a sunny morning: not yet")
	check(not IcicleRules.dripping("sunny", 20.0, night), "the evening: no drip")
	check(not IcicleRules.dripping("snow", 13.0, morning), "a snowy midday: no drip")
	check(not IcicleRules.dripping("sunny", 13.0, 0.0), "no icicles: no drip")
	check(IcicleRules.step_of(0.5) == roundi(0.5 / float(IcicleRules.config().step)), "the steps")


## Spots along an eave: from a hash of its ends, inside it, tucked under it, in varied lengths.
func _placement() -> void:
	var cfg := IcicleRules.config()
	var e: Dictionary = cfg.eave
	var a := Vector3(3.15, 1.45, 7.25)
	var b := Vector3(8.35, 1.45, 7.25)
	var out := Vector3(0, 0, 1)
	var s1 := IcicleRules.spots(a, b, out)
	var s2 := IcicleRules.spots(a, b, out)
	check(s1.size() > 10, "an eave 5.2 long has icicles (%d)" % s1.size())
	check(str(s1) == str(s2), "the same eave: the same icicles every time")
	var other := IcicleRules.spots(a + Vector3(10, 0, 3), b + Vector3(10, 0, 3), out)
	var lens1 := s1.map(func(s: Dictionary) -> float: return snappedf(float(s.len), 0.001))
	var lens2 := other.map(func(s: Dictionary) -> float: return snappedf(float(s.len), 0.001))
	check(str(lens1) != str(lens2), "another eave: other icicles")
	var inside := true
	var lens := {}
	var prev := -1.0
	var gaps_ok := true
	for s in s1:
		var at: Vector3 = s.at
		inside = inside and at.x >= a.x + float(e.inset) - 0.001 and at.x <= b.x - float(e.inset) + 0.001 \
			and is_equal_approx(at.y, 1.45) and is_equal_approx(at.z, 7.25 - float(e.tuck))
		lens[snappedf(float(s.len), 0.05)] = true
		check(float(s.len) >= float(e.length[0]) and float(s.len) <= 1.0, "a length in its range (%.2f)" % s.len)
		check(float(s.width) >= float(e.width[0]) and float(s.width) <= float(e.width[1]), "a width in its range")
		if prev >= 0.0:
			gaps_ok = gaps_ok and at.x - prev >= float(e.gap[0]) - 0.001
		prev = at.x
	check(inside, "every icicle on the eave line, inset from its ends, tucked under the soffit")
	check(gaps_ok, "no two closer than the smallest gap")
	check(lens.size() >= 5, "varied lengths (%d)" % lens.size())
	check(IcicleRules.spots(a, a + Vector3(0.15, 0, 0), out).is_empty(), "an eave too short for its insets: none")
	# Lengths by the amount: the longest at full, none when too short to see.
	var full := s1.filter(func(s: Dictionary) -> bool: return float(s.len) == 1.0)
	if not full.is_empty():
		check(is_equal_approx(IcicleRules.length_of(full[0], 1.0), float(e.max)), "a full one at full amount: eave.max long")
	check(IcicleRules.length_of(s1[0], 0.0) == 0.0, "none at amount 0")
	# The flat view's spots: inside the columns, clear of a door's.
	var flat := IcicleRules.flat_spots(49, 127, 111, [Vector2i(82, 94)])
	var clear := true
	var within := true
	for s in flat:
		clear = clear and (int(s.x) + 1 < 82 or int(s.x) >= 94)
		within = within and int(s.x) >= 49 + int(cfg.flat.inset) and int(s.x) + 1 < 127 - int(cfg.flat.inset) + 1 and int(s.y) == 111
	check(flat.size() >= 6, "a 78 px eave has flat icicles (%d)" % flat.size())
	check(clear, "the flat icicles keep clear of the door")
	check(within, "the flat icicles hang under the eave's own columns, from the row under it")
	check(str(flat) == str(IcicleRules.flat_spots(49, 127, 111, [Vector2i(82, 94)])), "the flat spots are the same every time")
	check(IcicleRules.flat_len(flat[0], 0.0) == 0 and IcicleRules.flat_len({"len": 1.0}, 1.0) == int(cfg.flat.max), "flat lengths: none at 0, flat.max at full")


## The roof builders list their eave lines; a kept build lists them again; glass lists none.
func _eaves() -> void:
	_when(3, 10, 8, "snow", 60)
	var town: MapData = MapManager.data("town")
	var w: Node3D = MW.new()
	w.build(town)
	var eaves: Array[Dictionary] = w.eaves
	check(eaves.size() > 0, "the village's roofs list their eaves (%d)" % eaves.size())
	for p in town.props:
		if str(p.kind) != "village_house":
			continue
		var body := LitSpots.village_body(Rect2(Vector2(p.cell), Vector2(p.size)))
		var front_z := body.end.y + 0.35
		var low := LitSpots.VILLAGE_WALL - 0.35 * 0.5
		var found := false
		for e in eaves:
			var ea: Vector3 = e.a
			var eb: Vector3 = e.b
			if is_equal_approx(ea.z, front_z) and is_equal_approx(eb.z, front_z) and is_equal_approx(ea.y, low) \
					and minf(ea.x, eb.x) < body.position.x and maxf(ea.x, eb.x) > body.end.x and (e.out as Vector3).is_equal_approx(Vector3(0, 0, 1)):
				found = true
		check(found, "the house at %s has its front eave listed (z %.2f, y %.2f, facing out to +z)" % [p.cell, front_z, low])
	var w2: Node3D = MW.new()
	w2.build(town)   # the houses' meshes come from MeshCache now
	check(w2.eaves.size() == eaves.size(), "a kept build lists the same eaves (%d / %d)" % [w2.eaves.size(), eaves.size()])
	w.free()
	w2.free()
	var house: Node3D = MW.new()
	house.build(MapManager.data("house"))
	var has_layer := false
	for n in house.get_children():
		has_layer = has_layer or n is IcicleLayer
	check(not has_layer, "a room's world gets no icicle layer")
	house.free()
	var fw: Node3D = FW.new()
	fw.setup(g.farm)
	var front := false
	for e in fw.eaves:
		var ea: Vector3 = e.a
		front = front or (is_equal_approx(ea.z, 0.55 + 3.5) and is_equal_approx(ea.y, 1.45))
	check(front, "the farmhouse's front eave is listed (z 4.05, y 1.45)")
	fw.free()
	var glass: Node3D = FW.new()
	load("res://scripts/world3d/greenhouse_props.gd").greenhouse(glass)
	check(glass.eaves.is_empty(), "the greenhouse's glass roof lists no eaves")
	glass.free()
	await process_frame


## IcicleLayer on the village's world: shows what the rules give, by the amount; drips at midday.
func _layer3d() -> void:
	var town: MapData = MapManager.data("town")
	_when(3, 10, 8, "sunny", 60)
	var w: Node3D = MW.new()
	w.build(town)
	root.add_child(w)
	await process_frame
	var layer: IcicleLayer = null
	for n in w.get_children():
		if n is IcicleLayer:
			layer = n
	check(layer != null, "an outdoor map's world builds an IcicleLayer")
	if layer == null:
		w.free()
		return
	var count := func() -> int:
		var a: float = float(IcicleRules.step_of(IcicleRules.amount_now(g, town))) * float(IcicleRules.config().step)
		var n := 0
		for s in layer.spot_list():
			if IcicleRules.length_of(s, a) > 0.0:
				n += 1
		return n
	var expected: int = count.call()
	check(layer.spot_list().size() > 50, "the village's eaves carry many icicles (%d)" % layer.spot_list().size())
	check(expected > 0 and layer.shown_count() == expected and layer.visible, "3D: shows what the rules give (%d / %d)" % [layer.shown_count(), expected])
	var on_eave := true
	for i in mini(layer.shown_count(), 40):
		var it: Array = layer.instance(i)
		var top: Vector3 = it[0]
		var hit := false
		for e in w.eaves:
			var ea: Vector3 = e.a
			var eb: Vector3 = e.b
			var tuck := (e.out as Vector3) * float(IcicleRules.config().eave.tuck)
			var p := top + tuck
			var seg := Geometry3D.get_closest_point_to_segment(p, ea, eb)
			hit = hit or seg.distance_to(p) < 0.001
		on_eave = on_eave and hit
	check(on_eave, "3D: every icicle's top on a listed eave line")
	check(layer.drop_count() == 0, "a sunny morning: no drops yet")
	await _fade_with_building(w, layer)
	var morning: int = layer.shown_count()
	var total := func() -> float:
		var sum := 0.0
		for i in layer.shown_count():
			sum += float(layer.instance(i)[1])
		return sum
	var len_morning: float = total.call()
	_when(3, 10, 14, "sunny", 60)
	layer.refresh()
	check(layer.drop_count() > 0, "a sunny 14:00: drops falling (%d)" % layer.drop_count())
	check(layer.shown_count() <= morning and layer.shown_count() == count.call(), "melted back at midday (%d -> %d)" % [morning, layer.shown_count()])
	check(total.call() < len_morning * 0.75, "the icicles are shorter at midday (%.1f -> %.1f in all)" % [len_morning, total.call()])
	_when(1, 10, 8, "sunny", 0)
	layer.refresh()
	check(layer.shown_count() == 0 and not layer.visible and layer.drop_count() == 0, "summer: none")
	w.free()
	var hl := IcicleLayer.new(MapManager.data("house"), [] as Array[Dictionary])
	check(hl.spot_list().is_empty(), "indoors: no spots even with eaves given")
	hl.free()


## A building turning see-through takes its icicles (and drops) with it; the others stay solid.
func _fade_with_building(w: Node3D, layer: IcicleLayer) -> void:
	var tags := {}
	for i in layer.shown_count():
		tags[layer.tag_of_instance(i)] = true
	var named: Array = tags.keys().filter(func(t: String) -> bool: return t != "")
	check(named.size() >= 2, "3D: the eaves carry their building's tag (%d buildings)" % named.size())
	if named.size() < 2:
		return
	var mine: String = named[0]
	var other: String = named[1]
	var tagged_groups := 0
	for gr in w.occluders._groups:
		if str(gr.tag) == mine:
			gr.now = w.occluders.FADED
			tagged_groups += 1
	check(tagged_groups > 0, "an Occluders group carries the icicles' tag")
	await process_frame
	var f_mine := true
	var f_other := true
	for i in layer.shown_count():
		var t := layer.tag_of_instance(i)
		if t == mine:
			f_mine = f_mine and is_equal_approx(layer.instance_fade(i), w.occluders.FADED)
		else:
			f_other = f_other and is_zero_approx(layer.instance_fade(i))
	check(f_mine, "a faded building's icicles take its fade (%.2f)" % layer.fade_of_tag(mine))
	check(f_other and is_zero_approx(layer.fade_of_tag(other)), "other buildings' icicles stay solid")
	for gr in w.occluders._groups:
		if str(gr.tag) == mine:
			gr.now = 0.0
	await process_frame
	check(is_zero_approx(layer.instance_fade(0)) and is_zero_approx(layer.fade_of_tag(mine)), "solid again when the building is")


## IcicleView in the flat view: the village houses and the farm's buildings, clear of their doors.
func _flat() -> void:
	_when(3, 10, 8, "snow", 60)
	var town: MapData = MapManager.data("town")
	var view := IcicleView.new().setup(town)
	root.add_child(view)
	var a: float = float(IcicleRules.step_of(IcicleRules.amount_now(g, town))) * float(IcicleRules.config().step)
	var spots := IcicleView.spots_for(town)
	var expected := spots.filter(func(s: Dictionary) -> bool: return IcicleRules.flat_len(s, a) > 0).size()
	check(expected > 0 and view.shown().size() == expected and view.visible, "flat: shows what the rules give (%d / %d)" % [view.shown().size(), expected])
	var under := true
	for s in spots:
		var ok := false
		for p in town.props:
			if str(p.kind) == "village_house":
				var inner := Rect2(Vector2(p.cell * 16), Vector2(p.size * 16)).grow(-1)
				ok = ok or (int(s.y) == int(inner.end.y) and int(s.x) >= int(inner.position.x) and int(s.x) + 1 < int(inner.end.x))
		under = under and ok
	check(under, "flat: every icicle under a village roof's bottom eave")
	var doors_clear := true
	for door in town.doors:
		for c: Vector2i in door.cells:
			for s in spots:
				if int(s.y) == (c.y + 1) * 16 - 1 and int(s.x) + 1 >= c.x * 16 + 2 and int(s.x) < c.x * 16 + 14:
					doors_clear = false
	check(doors_clear, "flat: none in front of a door")
	_when(3, 10, 13, "sunny", 60)
	view.refresh()
	check(view.dripping(), "flat: drips at a sunny midday")
	_when(2, 10, 8, "sunny", 60)
	view.refresh()
	check(view.shown().is_empty() and not view.visible, "flat: none in the fall")
	view.free()
	# The farm: under the farmhouse's, the coop's and the barn's painted roofs, never over a door.
	_when(3, 10, 8, "snow", 60)
	var fspots := IcicleView.spots_for(MapManager.data("farm"), g.farm)
	var house := FarmView.roof_rect(g.farm, "house")
	var row := int(house.end.y) / 16 - 1
	var house_n := 0
	var door_ok := true
	for s in fspots:
		if int(s.y) == int(house.end.y) and int(s.x) >= int(house.position.x) and int(s.x) < int(house.end.x):
			house_n += 1
			for k in 2:
				if g.farm.fixed_at(Vector2i((int(s.x) + k) / 16, row)) != "house":
					door_ok = false
	check(house_n > 5, "flat farm: icicles under the farmhouse's roof (%d)" % house_n)
	check(door_ok, "flat farm: none in front of the farmhouse's door")
	check(IcicleView.spots_for(MapManager.data("greenhouse")).is_empty() and IcicleView.spots_for(MapManager.data("house")).is_empty(),
		"flat: none in the greenhouse or a room")
	var fv := IcicleView.new().setup(MapManager.data("farm"), g.farm)
	root.add_child(fv)
	check(fv.shown().size() > 0 and fv.visible, "flat farm view: shows them (%d)" % fv.shown().size())
	fv.free()
