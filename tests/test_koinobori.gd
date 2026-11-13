extends SceneTree
## Headless checks for the carp streamers (koinobori: KoinoboriRules, data/koinobori.json, KoiArt,
## KoinoboriProps in 3D, KoinoboriView in the flat view): the gating (season, days, hours, the
## wet looks), the wind's fill and flap (limp in a calm, streaming in a wind), the pictures, the
## prop's place on the village map (a free cell clear of paths, doors and spawns, every door and
## spawn still reachable) and both views building and showing it. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_koinobori.gd

var failures := 0
var g: Node


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	g.new_game()
	g.clock_running = false
	_data()
	_gating()
	_wind()
	_art()
	_place()
	await _views()
	print("test_koinobori: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _data() -> void:
	var cfg := KoinoboriRules.config()
	var ids: Array = (cfg.carp as Array).map(func(c): return c.id)
	check(ids == ["black", "red", "blue"], "three carp: black, red, blue (%s)" % [ids])
	var lens: Array = (cfg.carp as Array).map(func(c): return float(c.length))
	check(lens[0] > lens[1] and lens[1] > lens[2], "the black carp the biggest, the blue the smallest")
	var ys: Array = (cfg.carp as Array).map(func(c): return float(c.y))
	check(ys[0] > ys[1] and ys[1] > ys[2] and ys[2] < float(cfg.streamer.y) and float(cfg.streamer.y) < float(cfg.wheel.y) and float(cfg.wheel.y) <= float(cfg.pole.height),
		"wheel on top, the streamer under it, the carp black, red, blue down the pole")
	check(cfg.season == "spring" and int(cfg.days[0]) >= 16 and int(cfg.days[1]) == 30, "late spring: the last half of the season")
	check(not KoinoboriRules.forced(), "not forced in a plain run")


func _up(season: String, day: int, hour: int, look: String, p := {}) -> bool:
	return KoinoboriRules.up(p, season, day, hour * 60, look)


func _gating() -> void:
	check(_up("spring", 20, 10, "sunny"), "up on a sunny late spring morning")
	check(_up("spring", 16, 10, "sunny") and _up("spring", 30, 10, "sunny"), "up on the first and the last day of its days")
	check(not _up("spring", 15, 10, "sunny") and not _up("spring", 1, 10, "sunny"), "not in early spring")
	for s in ["summer", "fall", "winter"]:
		check(not _up(s, 20, 10, "sunny"), "not in %s" % s)
	for look in ["rain", "storm", "snow", "blizzard"]:
		check(not _up("spring", 20, 10, look), "taken down in %s" % look)
	check(not _up("spring", 20, 5, "sunny") and _up("spring", 20, 6, "sunny") and _up("spring", 20, 17, "sunny") and not _up("spring", 20, 18, "sunny"),
		"between 6:00 and 18:00 only")
	var own := {"season": "summer", "days": [1, 3], "hours": ["08:00", "09:00"]}
	check(KoinoboriRules.up(own, "summer", 2, 8 * 60 + 30, "sunny") and not KoinoboriRules.up(own, "spring", 20, 8 * 60 + 30, "sunny")
		and not KoinoboriRules.up(own, "summer", 2, 10 * 60, "sunny"), "a prop's own season, days and hours win")
	g.season = 0
	g.day = 20
	g.hour = 10
	g.minute = 0
	g.weather_today = "sunny"
	check(KoinoboriRules.up_now({}, g), "up_now by the clock: up")
	g.weather_today = "rain"
	check(not KoinoboriRules.up_now({}, g), "up_now: down in the rain")
	g.weather_today = "sunny"
	g.season = 1
	check(not KoinoboriRules.up_now({}, g), "up_now: down in summer")
	g.season = 0


func _fills(wind: float, seconds := 120.0) -> Dictionary:
	var seen := {0: 0, 1: 0, 2: 0}
	var fmin := 1.0
	var fmax := 0.0
	var n := int(seconds * 12)
	for i in n:
		var c := KoinoboriRules.carp(wind, float(i) / 12.0, 0.9)
		seen[c.level] += 1
		fmin = minf(fmin, float(c.fill))
		fmax = maxf(fmax, float(c.fill))
	return {"seen": seen, "min": fmin, "max": fmax, "n": n}


func _swaps(wind: float) -> int:
	var last := -1
	var n := 0
	for i in 20 * 12:
		var f: int = KoinoboriRules.carp(wind, float(i) / 12.0, 0.0).frame
		if last >= 0 and f != last:
			n += 1
		last = f
	return n


func _wind() -> void:
	var calm := _fills(0.0)
	check(calm.seen[0] == calm.n and calm.max == 0.0, "no wind: always limp, no fill")
	var gale := _fills(0.9)
	check(gale.seen[2] > gale.n * 0.75, "a gale: mostly full (%d of %d)" % [gale.seen[2], gale.n])
	var breeze := _fills(g.wind_for("sunny", g.wind_rules))
	check(float(g.wind_for("sunny", g.wind_rules)) > 0.0 and breeze.seen[0] > 0 and breeze.seen[2] > 0, "a sunny breeze gusts between limp and full: %s" % [breeze.seen])
	check(breeze.seen[0] + breeze.seen[1] + breeze.seen[2] == breeze.n, "levels are 0, 1 or 2 only")
	var low := _fills(0.05)
	var mid := _fills(0.15)
	check(low.seen[2] < mid.seen[2] and mid.seen[2] < gale.seen[2], "a stronger wind fills the carp more (%d < %d < %d full)" % [low.seen[2], mid.seen[2], gale.seen[2]])
	check(KoinoboriRules.level_of(0.0) == 0 and KoinoboriRules.level_of(0.5) == 1 and KoinoboriRules.level_of(1.0) == 2, "fill 0 / 0.5 / 1 is level 0 / 1 / 2")
	check(KoinoboriRules.fill_of(0.0) == 0.0 and KoinoboriRules.fill_of(1.0) == 1.0, "the fill runs from 0 to 1")
	var a := KoinoboriRules.carp(0.4, 3.0, 0.0)
	var b := KoinoboriRules.carp(0.4, 3.0, 2.1)
	check(KoinoboriRules.carp(0.4, 3.0, 0.0) == a and a.frame in [0, 1], "the same time gives the same picture")
	var apart := false
	for i in 200:
		if KoinoboriRules.carp(0.3, float(i) * 0.37, 0.0).fill != KoinoboriRules.carp(0.3, float(i) * 0.37, 2.1).fill:
			apart = true
	check(apart and b.level in [0, 1, 2], "each carp's gusts a little apart (phase)")
	check(_swaps(0.9) > _swaps(0.0), "a filled carp flaps faster than a limp one (%d > %d swaps in 20 s)" % [_swaps(0.9), _swaps(0.0)])
	check(_swaps(0.0) > 0, "a limp one still sways")
	var cfg := KoinoboriRules.config()
	check(KoinoboriRules.wheel_speed(0.0) > 0.0 and KoinoboriRules.wheel_speed(0.3) > KoinoboriRules.wheel_speed(0.0), "the wheel turns slowly in a calm, faster in a wind")
	var frames := {}
	for i in 60:
		frames[KoinoboriRules.wheel_frame(float(i) / 60.0)] = true
	check(frames.size() == int(cfg.wheel.frames), "a turn runs through every wheel frame (%d)" % frames.size())
	check(KoinoboriRules.wheel_frame(-0.1) in range(int(cfg.wheel.frames)), "the wheel's frame is always in range")


func _lum(c: Color) -> float:
	return c.r * 0.3 + c.g * 0.59 + c.b * 0.11


func _count(img: Image, c: Color) -> int:
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var q := img.get_pixel(x, y)
			if absf(q.r - c.r) + absf(q.g - c.g) + absf(q.b - c.b) < 0.02 and q.a > 0.5:
				n += 1
	return n


func _art() -> void:
	var cfg := KoinoboriRules.config()
	for c: Dictionary in cfg.carp:
		var id := str(c.id)
		var size := KiSize.of(c)
		var seen := {}
		for level in 3:
			for frame in 2:
				var img := PlaceholderArt.tex(KoinoboriRules.art_key(id, level, frame)).get_image()
				check(img.get_size() == Vector2i(size, size), "%s %d:%d is %d square" % [id, level, frame, size])
				var opaque := 0
				for y in img.get_height():
					for x in img.get_width():
						if img.get_pixel(x, y).a > 0.5:
							opaque += 1
				check(opaque > 30, "%s %d:%d has a body (%d px)" % [id, level, frame, opaque])
				seen[img.get_data()] = true
		check(seen.size() == 6, "%s: six different pictures (%d)" % [id, seen.size()])
		var full := PlaceholderArt.tex(KoinoboriRules.art_key(id, 2, 0)).get_image()
		var base := Color(str(c.base))
		check(_count(full, Color(str(c.light))) >= 3 and _count(full, base) >= 8 and _count(full, Color(str(c.dark))) >= 3 and _count(full, Color(str(c.belly))) + _count(full, Color(str(c.belly)).darkened(0.2)) >= 3,
			"%s full: light, base, dark and the pale belly (in light and shade) all there" % id)
		var pad := KiSize.pad(c)
		# lit from the upper left: the upper third of the body is lighter than the lower third
		var cols := full.get_width()
		var lo_y := pad - int(ceil(float(c.radius)))
		var hi_y := pad + int(ceil(float(c.radius)))
		var up_sum := 0.0
		var up_n := 0
		var dn_sum := 0.0
		var dn_n := 0
		for y in range(lo_y, hi_y + 1):
			for x in range(pad, cols):
				var px := full.get_pixel(x, y)
				if px.a < 0.5 or px.is_equal_approx(Color(str(c.belly))):
					continue
				if y < pad - 1:
					up_sum += _lum(px)
					up_n += 1
				elif y > pad + 1:
					dn_sum += _lum(px)
					dn_n += 1
		check(up_n > 0 and dn_n > 0 and up_sum / up_n > dn_sum / dn_n, "%s: the upper side catches the light (%.3f > %.3f)" % [id, up_sum / maxf(up_n, 1), dn_sum / maxf(dn_n, 1)])
		check(_count(full, KoiArt.RING) >= 2, "%s: the mouth ring" % id)
		var limp := PlaceholderArt.tex(KoinoboriRules.art_key(id, 0, 0)).get_image()
		var low := 0
		for y in range(pad + int(ceil(float(c.length))) / 2, limp.get_height()):
			for x in limp.get_width():
				if limp.get_pixel(x, y).a > 0.5:
					low += 1
		check(low > 10, "%s limp hangs down the pole" % id)
	var stream := PlaceholderArt.tex(KoinoboriRules.art_key("stream", 2, 0)).get_image()
	var stripes := 0
	for col in cfg.streamer.stripes:
		if _count(stream, Color(str(col))) > 0:
			stripes += 1
	check(stripes >= 4, "the streamer shows its stripes (%d of 5 colours as drawn)" % stripes)
	var frames := {}
	for f in int(cfg.wheel.frames):
		var img := PlaceholderArt.tex(KoinoboriRules.art_key("wheel", 0, f)).get_image()
		check(img.get_size() == Vector2i(KoiArt.WHEEL_SIZE, KoiArt.WHEEL_SIZE), "wheel frame %d size" % f)
		frames[img.get_data()] = true
	check(frames.size() == int(cfg.wheel.frames), "every wheel frame is a different picture (%d)" % frames.size())


## Size and padding of a carp's picture from its data, as KoiArt makes it.
class KiSize:
	static func pad(c: Dictionary) -> int:
		return KoiArt.pad(float(c.radius))

	static func of(c: Dictionary) -> int:
		return KoiArt.size_of(float(c.length), float(c.radius))


## Cells the farmer can stand on from `from`, 4-connected, over non-solid cells.
func _reach(m: MapData, from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var todo: Array[Vector2i] = [from]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + (d as Vector2i)
			if m.in_bounds(n) and not seen.has(n) and not m.is_solid(n):
				seen[n] = true
				todo.append(n)
	return seen


func _place() -> void:
	var m := MapManager.data("town")
	var poles := m.props.filter(func(p): return p.kind == KoinoboriRules.KIND)
	check(poles.size() == 1, "one carp streamer pole on the village map")
	if poles.is_empty():
		return
	var p: Dictionary = poles[0]
	var c: Vector2i = p.cell
	check(p.size == Vector2i.ONE and m.is_solid(c), "it stands on one cell the farmer cannot walk through")
	var others := m.props.filter(func(q): return q != p and Rect2i(q.cell, q.size).has_point(c))
	check(others.is_empty(), "no other prop on its cell")
	check(m.tiles[c.y * m.w + c.x] == "grass", "on grass, not on a path (%s)" % m.tiles[c.y * m.w + c.x])
	var path_next := false
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = c + (d as Vector2i)
		if m.in_bounds(n):
			check(not m.is_solid(n), "its neighbour %s is open ground" % n)
			check(m.door_at(n).is_empty(), "no door right beside it (%s)" % n)
			for key in m.spawns:
				check(Vector2i(m.spawns[key][0]) != n and Vector2i(m.spawns[key][0]) != c, "spawn %s is not on or beside it" % key)
			if m.tiles[n.y * m.w + n.x] in ["path", "gravel"]:
				path_next = true
	check(path_next, "it stands beside Kota's lane, in view of the walkers")
	# the house with children: Kota's, the one south-west of the road
	var kota := m.prop_at(Vector2i(8, 14))
	check(kota.get("kind", "") == "village_house" and absf(c.x - (kota.cell.x + kota.size.x / 2.0)) < 6.0 and absi(c.y - kota.cell.y) < 6,
		"next to Kota's house")
	# nothing is cut off: every spawn and every door is still reachable from the start
	var reach := _reach(m, Vector2i(m.spawns["start"][0]))
	for key in m.spawns:
		check(reach.has(Vector2i(m.spawns[key][0])), "spawn %s still reachable" % key)
	for door in m.doors:
		var ok := false
		for dc: Vector2i in door.cells:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if reach.has(dc + (d as Vector2i)):
					ok = true
		check(ok, "door %s still reachable" % [door.to])
	# the same with the pole cell open: the pole costs no one a way (the neighbours join up around it)
	check(m.spawns.has("koinobori") and m.is_solid(c) and not m.is_solid(Vector2i(m.spawns["koinobori"][0])), "a spawn by the pole for screenshots, on open ground")


func _views() -> void:
	var m := MapManager.data("town")
	g.season = 0
	g.day = 20
	g.hour = 10
	g.minute = 0
	g.weather_today = "sunny"
	# 3D
	var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
	root.add_child(w)   # the world needs the tree before it builds (its Main3D helpers)
	w.build(m)
	var rig: Node3D = w.get_node_or_null("Koinobori")   # KoinoboriProps.NAME (the script names the Game autoload, so it is not named here)
	check(rig != null and rig.visible and rig.get_child_count() >= 6, "3D: the pole, wheel, streamer and carp are built and up on a late spring morning")
	if rig != null:
		var cfg := KoinoboriRules.config()
		check(rig.sprites().size() == 5, "3D: five hung things (wheel, streamer, three carp)")
		var keys: Dictionary = rig.keys()
		check(keys.has("wheel") and keys.has("stream") and keys.has("black") and keys.has("red") and keys.has("blue"), "3D: a picture for each (%s)" % [keys])
		var tall := true
		for s in rig.sprites():
			tall = tall and s.position.y > 0.3 and s.texture != null
		check(tall, "3D: each sprite has its picture and hangs up the pole")
		var top := (rig.sprites()[0] as Sprite3D).position.y
		# the 3D scale: every picture at FarmWorld.PX times data/koinobori.json scale_3d, not the flat 1:1
		# (KoinoboriProps and FarmWorld are reached by load() here: naming them in code breaks the
		# compile of this script, as the Game autoload does in farm_world.gd)
		var scale := float(cfg.get("scale_3d", 1.0))
		var px: float = load("res://scripts/world3d/farm_world.gd").PX * scale
		check(scale > 0.0 and scale < 1.0 and is_equal_approx(px, load("res://scripts/world3d/koinobori_props.gd").pixel()), "3D: the rig scale is scale_3d (%.3f)" % scale)
		check(is_equal_approx(top, float(cfg.wheel.y) * px), "3D: the wheel at the top (%.2f)" % top)
		for s in rig.sprites():
			check(is_equal_approx((s as Sprite3D).pixel_size, px), "3D: sprite pixel size is the scaled one (%.4f)" % (s as Sprite3D).pixel_size)
		# the largest carp (black) no longer than a village house's wall, and the pole about 1.5 eave heights
		var wall: float = load("res://scripts/world3d/lit_spots.gd").VILLAGE_WALL
		var black := rig.sprites()[2] as Sprite3D
		check(float(black.texture.get_width()) * px <= wall, "3D: the black carp's picture no longer than a wall (%.2f <= %.2f)" % [float(black.texture.get_width()) * px, wall])
		var pole_top := float(cfg.pole.height) * px
		check(pole_top > wall and pole_top < wall * 2.0, "3D: the pole stands above the eaves, under twice their height (%.2f)" % pole_top)
		# the carp hang apart: the gap between neighbours is more than their two half-thicknesses
		for i in range(2, 4):
			var upper := rig.sprites()[i] as Sprite3D
			var lower := rig.sprites()[i + 1] as Sprite3D
			var gap := upper.position.y - lower.position.y
			var need := (float(cfg.carp[i - 2].radius) + float(cfg.carp[i - 1].radius)) * px
			check(gap > need, "3D: carp %d and %d do not overlap (gap %.3f > %.3f)" % [i - 1, i, gap, need])
		rig.wind = 0.0
		rig._frame = -1
		rig.pose(5.0)
		check(["black", "red", "blue"].all(func(k): return str(rig.keys()[k]).begins_with("koi:%s:0:" % k)), "3D: limp carp in still air (%s)" % [rig.keys()])
		rig.wind = 1.0
		rig._frame = -1
		rig.pose(5.5)
		check(["black", "red", "blue"].all(func(k): return str(rig.keys()[k]).begins_with("koi:%s:2:" % k)), "3D: full carp in a gale (%s)" % [rig.keys()])
		g.weather_today = "rain"
		rig.refresh()
		check(not rig.visible, "3D: the pole comes down in the rain")
		g.weather_today = "sunny"
		g.hour = 19
		rig.refresh()
		check(not rig.visible, "3D: and at dusk")
		g.hour = 10
		g.season = 2
		rig.refresh()
		check(not rig.visible, "3D: and outside its season")
		g.season = 0
		rig.refresh()
		check(rig.visible, "3D: up again on the day")
	w.queue_free()
	# flat view
	var v: Node2D = load("res://scripts/world/koinobori_view.gd").new(m)
	root.add_child(v)
	check(v.has_props() and v.pole_up(), "flat: the pole is up on a late spring morning")
	var fk: Dictionary = v.keys()
	check(fk.size() == 5 and fk.has("wheel") and fk.has("black"), "flat: five pictures chosen (%s)" % [fk])
	g.weather_today = "storm"
	v.refresh()
	check(not v.pole_up(), "flat: down in a storm")
	g.weather_today = "sunny"
	g.day = 3
	v.refresh()
	check(not v.pole_up(), "flat: down in early spring")
	g.day = 20
	v.refresh()
	check(v.pole_up(), "flat: up again")
	v.queue_free()
	# the flat scene builds the village with its KoinoboriView
	var scene: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	g.go_to_map("town", Vector2i(4, 14), Vector2i.DOWN)
	for i in 30:
		await process_frame
		if scene.view.get("map") != null and scene.view.map.id == "town":
			break
	var kv: Node = scene.view.get_node_or_null("Koinobori")
	check(kv != null and kv.has_props() and kv.pole_up(), "flat scene: the village has its KoinoboriView, the pole up")
	check(scene.view.map.id == "town" and kv != null and kv.keys().size() == 5, "flat scene: showing five pictures")
	scene.queue_free()
	await process_frame
