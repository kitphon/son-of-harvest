extends SceneTree
## Headless checks for the morning mist (MistRules, data/mist.json): the season / weather /
## clock / wind / indoor gating, the density curve over the dawn hours, the cells it rises from
## (water, paddies, the farm's pond), the sheets low and drifting on the wind, and both views
## (MistLayer in 3D, MistView in the flat view) building and showing it. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_mist.gd

var failures := 0
var g: Node
var MR: GDScript


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	MR = load("res://scripts/mist_rules.gd")
	g.new_game()
	g.clock_running = false
	_curve()
	_gating()
	_scenes()
	_sheets()
	await _views()
	print("test_mist: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
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


## The clock's share: none at night or by day, gathering before dawn, full 5:00..6:30, gone by 8:00.
func _curve() -> void:
	check(MR.curve(2.0) == 0.0 and MR.curve(12.0) == 0.0 and MR.curve(20.0) == 0.0, "curve: none at night, noon or evening")
	check(MR.curve(5.0) == 1.0 and MR.curve(5.5) == 1.0 and MR.curve(6.5) == 1.0, "curve: thickest 5:00..6:30")
	check(MR.curve(8.0) == 0.0 and MR.curve(8.5) == 0.0, "curve: gone by 8:00")
	var gather: float = MR.curve(4.25)
	check(gather > 0.0 and gather < 1.0, "curve: gathering before dawn (%.2f)" % gather)
	var a: float = MR.curve(6.75)
	var b: float = MR.curve(7.25)
	var c: float = MR.curve(7.75)
	check(a > b and b > c and c > 0.0 and a < 1.0, "curve: thinning after 6:30 (%.2f > %.2f > %.2f)" % [a, b, c])
	var smooth := true
	var last: float = MR.curve(6.5)
	for k in 30:
		var v: float = MR.curve(6.5 + 1.5 * float(k + 1) / 30.0)
		smooth = smooth and v <= last + 0.0001 and last - v < 0.12
		last = v
	check(smooth, "curve: thins smoothly, no jumps")


## Season, weather look, wind and indoors.
func _gating() -> void:
	check(MR.amount("water", "spring", "sunny", 5.5) > 0.9 and MR.amount("paddy", "fall", "sunny", 5.5) > 0.9, "spring and fall: thick over water and paddies")
	var sw: float = MR.amount("water", "summer", "sunny", 5.5)
	check(sw > 0.0 and sw < MR.amount("water", "spring", "sunny", 5.5) * 0.6, "summer: a little (%.2f)" % sw)
	check(MR.amount("water", "winter", "sunny", 5.5) > 0.0 and MR.amount("paddy", "winter", "sunny", 5.5) == 0.0, "winter: over open water only")
	check(MR.amount("water", "spring", "storm", 5.5) == 0.0 and MR.amount("water", "winter", "blizzard", 5.5) == 0.0, "none in a storm or a blizzard")
	var rain: float = MR.amount("water", "spring", "rain", 5.5)
	check(rain > 0.0 and rain < 0.5, "rain: thin (%.2f)" % rain)
	check(MR.amount("water", "winter", "snow", 5.5) > 0.0, "a snowy winter morning: some over the water")
	var calm: float = MR.amount("water", "spring", "sunny", 5.5, 0.0)
	var breeze: float = MR.amount("water", "spring", "sunny", 5.5, 0.5)
	var gale: float = MR.amount("water", "spring", "sunny", 5.5, 1.0)
	check(calm > breeze and breeze > gale, "thinner in wind (%.2f > %.2f > %.2f)" % [calm, breeze, gale])
	check(MR.amount("water", "spring", "sunny", 12.0) == 0.0, "none at noon")
	var MM: GDScript = load("res://scripts/world/map_manager.gd")
	var town: MapData = MM.data("town")
	var kami: MapData = MM.data("kaminoda")
	_when(0, 5, 30, "sunny")
	check(MR.amounts_now(g, town).has("water"), "spring dawn in the village: mist")
	check(MR.amounts_now(g, MM.data("house")).is_empty() and MR.amounts_now(g, MM.data("mine_floor")).is_empty() \
		and MR.amounts_now(g, MM.data("greenhouse")).is_empty(), "none indoors, in the mine or in the greenhouse")
	check(MR.amounts_now(null, town).is_empty(), "no clock: nothing")
	_when(0, 9, 0, "sunny")
	check(MR.amounts_now(g, town).is_empty(), "9:00: burnt off")
	_when(0, 5, 30, "storm")
	check(MR.amounts_now(g, town).is_empty(), "a storm at dawn: nothing")
	_when(3, 5, 30, "sunny")
	check(MR.amounts_now(g, town).has("water") and not MR.amounts_now(g, kami).has("paddy"), "winter dawn: the water steams, the paddies do not")
	_when(2, 6, 0, "sunny")
	check(MR.amounts_now(g, kami).has("paddy"), "fall dawn: over the paddies")
	# The day's wind is read when none is given: rain's wind thins more than the look alone.
	_when(0, 5, 30, "rain")
	var r: Dictionary = MR.amounts_now(g, town)
	check(r.has("water") and float(r.water) < MR.amount("water", "spring", "rain", 5.5, 0.0), "rain: the day's wind thins it too")


## The cells a map's mist rises from.
func _scenes() -> void:
	var MM: GDScript = load("res://scripts/world/map_manager.gd")
	var ks: Dictionary = MR.scene_of(MM.data("kaminoda"))
	check(ks.cells.size() > 50 and ks.kinds.has("paddy") and ks.cells.size() == ks.kinds.size(), "kaminoda: its paddies (%d)" % ks.cells.size())
	var rs: Dictionary = MR.scene_of(MM.data("river"))
	check(rs.cells.size() > 20 and rs.kinds.has("water") and not rs.kinds.has("paddy"), "river: its water (%d)" % rs.cells.size())
	var fs: Dictionary = MR.scene_of(MM.data("farm"), g.farm)
	check(fs.cells.size() == 12 and fs.kinds.count("water") == 12, "farm: the pond's twelve cells (%d)" % fs.cells.size())
	var hill: Dictionary = MR.scene_of(MM.data("hill"))
	check(hill.cells.is_empty(), "the hill: no water, no mist")
	check(MR.count_for(0) == 0 and MR.count_for(1) == 1 and MR.count_for(10000) == int(MR.config().max), "counts: none, at least one, capped")


## The sheets: low, soft, inside the bounds of the data, drifting with the wind, pure.
func _sheets() -> void:
	var cfg: Dictionary = MR.config()
	var scene := {"area": Rect2(0, 0, 30, 20), "cells": [Vector2(10.5, 10.5), Vector2(11.5, 10.5), Vector2(10.5, 11.5)], "kinds": ["water", "water", "paddy"]}
	var all: Array = MR.sheets(scene, {"water": 1.0, "paddy": 1.0}, 3.0, 0.0)
	check(all.size() == MR.count_for(3), "sheets: the count for the cells (%d)" % all.size())
	var ok := true
	var near := true
	var hi := float(cfg.height[1]) + float(cfg.bob) + 0.001
	for s in all:
		ok = ok and s.pos.y > 0.0 and s.pos.y <= hi and s.alpha >= 0.0 and s.alpha <= float(cfg.alpha) + 0.0001
		ok = ok and s.size.x >= float(cfg.size[0]) * 0.8 and s.size.y < s.size.x
		near = near and Vector2(s.pos.x, s.pos.z).distance_to(Vector2(11.0, 11.0)) < 4.0
	check(ok, "sheets: low, longer than wide, alpha within the data's")
	check(near, "sheets: they keep near the cells they rise from")
	# Over the tall fall rice the paddies' sheets lie higher than over the water, low over young spring rice.
	var paddy_scene := {"area": Rect2(0, 0, 30, 20), "cells": [Vector2(10.5, 10.5)], "kinds": ["paddy"]}
	var tall: Array = MR.sheets(paddy_scene, {"paddy": 1.0}, 3.0, 0.0, "fall")
	var young: Array = MR.sheets(paddy_scene, {"paddy": 1.0}, 3.0, 0.0, "spring")
	var fh: Array = cfg.paddy_height.fall
	check(tall.size() == 1 and tall[0].pos.y >= float(fh[0]) - float(cfg.bob) - 0.001 and young[0].pos.y < tall[0].pos.y,
		"paddies: over the fall rice's tips, lower over the spring rice (%.2f / %.2f)" % [tall[0].pos.y, young[0].pos.y])
	# Past the map's edge a sheet fades out: never thicker at the edge than in the open, none well outside.
	var edge_scene := {"area": Rect2(0, 0, 30, 20), "cells": [Vector2(0.5, 10.5)], "kinds": ["water"]}
	var open_scene := {"area": Rect2(-10, -10, 50, 40), "cells": [Vector2(0.5, 10.5)], "kinds": ["water"]}
	var never_more := true
	for t in [0.0, 3.0, 6.0, 9.0, 12.0]:
		var e: Dictionary = MR.sheets(edge_scene, {"water": 1.0}, t, 0.0)[0]
		var m: Dictionary = MR.sheets(open_scene, {"water": 1.0}, t, 0.0)[0]
		never_more = never_more and e.alpha <= m.alpha + 0.0001
	check(never_more, "edge: never thicker at the map's edge")
	var outside: Dictionary = MR.sheets({"area": Rect2(5, 5, 10, 10), "cells": [Vector2(0.5, 0.5)], "kinds": ["water"]}, {"water": 1.0}, 3.0, 0.0)[0]
	check(outside.alpha == 0.0, "edge: none well outside the map")
	var water_only: Array = MR.sheets(scene, {"water": 1.0}, 3.0, 0.0)
	check(water_only.all(func(s): return s.kind == "water"), "sheets: none over a kind with no mist now")
	check(MR.sheets(scene, {}, 3.0, 0.0).is_empty(), "sheets: none with no mist")
	# Wind: the same moment in a gale lies further along the wind's direction over the life's late half.
	var big := {"area": Rect2(0, 0, 40, 40), "cells": [], "kinds": []}
	for y in 10:
		for x in 10:
			big.cells.append(Vector2(x + 10.5, y + 10.5))
			big.kinds.append("water")
	var dir: Vector2 = MR.wind_dir()
	var now: Array = MR.sheets(big, {"water": 1.0}, 3.0, 0.5)
	var later: Array = MR.sheets(big, {"water": 1.0}, 3.5, 0.5)
	var along := 0.0
	var same := 0
	for i in mini(now.size(), later.size()):
		var d := Vector2(later[i].pos.x - now[i].pos.x, later[i].pos.z - now[i].pos.z)
		if d.length() < 1.0:
			along += d.dot(dir)
			same += 1
	check(same > 0 and along / same > 0.0, "sheets: drift along the wind over time (%.3f)" % (along / maxf(same, 1)))
	var calm0: Array = MR.sheets(big, {"water": 1.0}, 3.0, 0.0)
	var calm: Array = MR.sheets(big, {"water": 1.0}, 3.5, 0.0)
	var slow := 0.0
	for i in mini(calm0.size(), calm.size()):
		var d := Vector2(calm[i].pos.x - calm0[i].pos.x, calm[i].pos.z - calm0[i].pos.z)
		if d.length() < 1.0:
			slow += absf(d.dot(dir))
	check(slow < along, "sheets: slower in still air")
	check(MR.sheets(big, {"water": 1.0}, 3.0, 0.5)[0].pos == now[0].pos, "sheets are a pure function of their arguments")
	var fades := false
	for t in [0.0, 2.0, 4.0, 6.0, 8.0]:
		for s in MR.sheets(big, {"water": 1.0}, t, 0.0):
			fades = fades or s.alpha < 0.02
	check(fades, "sheets: fade in and out over their lives")
	# The colour: pale, taken toward the dawn sky's hue (peach at sunrise, never dark).
	_when(0, 6, 30, "sunny")
	var c: Color = MR.color_now(g)
	check(c.get_luminance() > 0.7 and c.r >= c.b, "colour: pale and warm at sunrise (%s)" % c.to_html(false))
	_when(0, 5, 0, "sunny")
	var e: Color = MR.color_now(g)
	check(e.get_luminance() > 0.6 and e.b > e.g, "colour: lavender before sunrise (%s)" % e.to_html(false))


## Both views build the node and show or hide it by the rules.
func _views() -> void:
	await process_frame
	var MM: GDScript = load("res://scripts/world/map_manager.gd")
	var LayerS: GDScript = load("res://scripts/world3d/mist_layer.gd")
	var ViewS: GDScript = load("res://scripts/world/mist_view.gd")
	var MapWorldS: GDScript = load("res://scripts/world3d/map_world.gd")
	var rv: MapData = MM.data("river")
	var w3: Node3D = MapWorldS.new()
	root.add_child(w3)
	for step in w3.build_steps(rv):
		step.call()
	var layers := w3.get_children().filter(func(n): return n.get_script() == LayerS)
	check(layers.size() == 1, "3D: an outdoor map builds one mist layer (%d)" % layers.size())
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
		_when(0, 5, 30, "sunny")
		layer.refresh()
		check(layer.shown_count() > 0, "3D: mist on a spring dawn (%d)" % layer.shown_count())
		_when(0, 10, 0, "sunny")
		layer.refresh()
		check(layer.shown_count() == 0, "3D: none at 10:00")
		_when(0, 5, 30, "storm")
		layer.refresh()
		check(layer.shown_count() == 0, "3D: none in a storm")
		_when(3, 5, 30, "sunny")
		layer.refresh()
		check(layer.shown_count() > 0, "3D: the river steams on a winter dawn (%d)" % layer.shown_count())
	w3.free()
	inside.free()
	cave.free()
	var k3: Node3D = MapWorldS.new()
	root.add_child(k3)
	for step in k3.build_steps(MM.data("kaminoda")):
		step.call()
	var kl: Array = k3.get_children().filter(func(n): return n.get_script() == LayerS)
	if kl.size() == 1:
		_when(3, 5, 30, "sunny")
		kl[0].refresh()
		check(kl[0].shown_count() == 0, "3D: winter paddies: none")
		_when(2, 5, 30, "sunny")
		kl[0].refresh()
		check(kl[0].shown_count() > 0, "3D: fall paddies at dawn (%d)" % kl[0].shown_count())
	else:
		check(false, "3D: kaminoda builds a mist layer")
	k3.free()
	# The farm's world step: Main3D.new_world gives the farm a layer too.
	var M3: GDScript = load("res://scripts/main_3d.gd")
	var made: Array = M3.new_world(MM.data("farm"))
	for step in made[1]:
		step.call()
	check(made[0].get_children().any(func(n): return n.get_script() == LayerS), "3D: the farm builds a mist layer")
	made[0].free()
	# Flat: the view shows sheets at dawn, nothing by day, nothing indoors.
	var v: Node2D = ViewS.new().setup(MM.data("town"))
	root.add_child(v)
	_when(0, 5, 30, "sunny")
	v.refresh()
	var ps: Array = v.patches()
	check(v.visible and ps.size() > 0, "flat: mist on a spring dawn (%d)" % ps.size())
	check(ps.all(func(p): return p.at == p.at.round()), "flat: centred on whole pixels")
	var ring: PackedVector2Array = ViewS.ring(Vector2(40, 40), Vector2(16, 8), 0.3)
	check(ring.size() == ViewS.POINTS and Geometry2D.triangulate_polygon(ring).size() > 0, "flat: a ring is a good polygon")
	_when(0, 12, 0, "sunny")
	v.refresh()
	check(not v.visible and v.patches().is_empty(), "flat: hidden at noon")
	_when(0, 5, 30, "storm")
	v.refresh()
	check(not v.visible, "flat: hidden in a storm")
	var room: Node2D = ViewS.new().setup(MM.data("house"))
	root.add_child(room)
	_when(0, 5, 30, "sunny")
	room.refresh()
	check(not room.visible and room.patches().is_empty(), "flat: a room gets none")
	var fv: Node2D = ViewS.new().setup(MM.data("farm"), g.farm)
	root.add_child(fv)
	fv.refresh()
	check(fv.visible and fv.patches().size() > 0, "flat: the farm's pond at dawn (%d)" % fv.patches().size())
	# The flat view builds with it: main_2d's map view holds a MistView.
	var main2d: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(main2d)
	await process_frame
	var found := _find(main2d, ViewS)
	check(found != null, "flat: main_2d's view holds a mist view")
	if found != null:   # drawn over the ferry boat, under the figures (child order of the map view)
		var ferry := _find(main2d, load("res://scripts/world/ferry_view.gd"))
		var villager := _find(main2d, load("res://scripts/world/villager_view.gd"))
		var same := ferry != null and villager != null and found.get_parent() == ferry.get_parent() and villager.get_parent() == ferry.get_parent()
		check(same and found.get_index() > ferry.get_index(), "flat: mist draws above the ferry boat")
		check(same and found.get_index() < villager.get_index(), "flat: mist draws below the figures")
	main2d.queue_free()
	v.free()
	room.free()
	fv.free()
	await process_frame


func _find(n: Node, s: GDScript) -> Node:
	if n.get_script() == s:
		return n
	for c in n.get_children():
		var f := _find(c, s)
		if f != null:
			return f
	return null
