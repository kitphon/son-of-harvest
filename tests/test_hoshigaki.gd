extends SceneTree
## Headless checks for the drying persimmon strings under the eaves in late fall (HoshigakiRules,
## data/hoshigaki.json; HoshigakiArt; HoshigakiLayer in 3D, HoshigakiView in the flat view): the
## gating (the fall's window of days, outdoors only, taken in on a day of rain, storm or snow), the
## drying by the days hung (stages darker and smaller), the sway with the wind (still in calm,
## more with more wind, within its reach), the picture (a straw rope, the persimmons in three tones
## lit from the upper left, the stalk's knot on the rope), the placement (the farmhouse always,
## some village houses by a hash, spots on the eave line, tucked, clear of the doors, the same every
## time), and both views building and showing by the rules (on the real eave lines in 3D, fading
## with their house; under the painted roofs' bottom eave in the flat view). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_hoshigaki.gd

var failures := 0
var g: Node
var FW: GDScript
var MW: GDScript
var MAIN: GDScript
var HL: GDScript   # HoshigakiLayer, HoshigakiView, Occluders: loaded once the autoloads are up
var HV: GDScript
var OC: GDScript


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	FW = load("res://scripts/world3d/farm_world.gd")
	MW = load("res://scripts/world3d/map_world.gd")
	MAIN = load("res://scripts/main_3d.gd")
	HL = load("res://scripts/world3d/hoshigaki_layer.gd")
	HV = load("res://scripts/world/hoshigaki_view.gd")
	OC = load("res://scripts/world3d/occluders.gd")
	g.new_game()
	g.clock_running = false
	_data()
	_gating()
	_drying()
	_sway()
	_art()
	_placement()
	await _layer_farm()
	await _layer_town()
	await _flat()
	print("test_hoshigaki: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _when(season: int, day: int, weather: String, hour := 11) -> void:
	g.season = season
	g.day = day
	g.hour = hour
	g.minute = 0
	g.weather_today = weather
	g.snow_cover = 0


func _data() -> void:
	var cfg := HoshigakiRules.config()
	check((cfg.seasons as Array) == ["fall"], "data: fall only (%s)" % [cfg.seasons])
	check(int(cfg.days[0]) >= 5 and int(cfg.days[1]) == 30 and int(cfg.days[0]) < int(cfg.days[1]), "data: a late-fall window (%s)" % [cfg.days])
	for look in ["rain", "storm", "snow"]:
		check((cfg.taken_in as Array).has(look), "data: %s takes them in" % look)
	check(int(cfg.fruit[0]) == 6 and int(cfg.fruit[1]) == 10, "data: 6 to 10 persimmons a string (%s)" % [cfg.fruit])
	check((cfg.stages as Array).size() >= 3, "data: at least three drying stages")


func _gating() -> void:
	check(not HoshigakiRules.forced_on() and HoshigakiRules.forced_days() == HoshigakiRules.NONE, "not forced in a test run")
	check(HoshigakiRules.hangs("fall", 20, "sunny"), "pure: a sunny late-fall day: out")
	check(HoshigakiRules.hangs("fall", 10, "sunny"), "pure: the window's first day: out")
	check(HoshigakiRules.hangs("fall", 30, "sunny"), "pure: the season's last day: out")
	check(not HoshigakiRules.hangs("fall", 9, "sunny"), "pure: before the window: none")
	check(not HoshigakiRules.hangs("fall", 3, "sunny"), "pure: early fall: none")
	for look in ["rain", "storm", "snow"]:
		check(not HoshigakiRules.hangs("fall", 20, look), "pure: taken in on a day of %s" % look)
	for s in ["spring", "summer", "winter"]:
		check(not HoshigakiRules.hangs(s, 20, "sunny"), "pure: %s: none" % s)
	var town: MapData = MapManager.data("town")
	var farm: MapData = MapManager.data("farm")
	_when(2, 20, "sunny")
	check(HoshigakiRules.hangs_now(g, town) and HoshigakiRules.hangs_now(g, farm), "game: fall 20, sunny: out in the village and on the farm")
	_when(2, 20, "rain")
	check(not HoshigakiRules.hangs_now(g, farm), "game: fall rain: taken in")
	_when(2, 5, "sunny")
	check(not HoshigakiRules.hangs_now(g, farm), "game: fall 5: not yet")
	_when(3, 20, "sunny")
	check(not HoshigakiRules.hangs_now(g, farm), "game: winter: none")
	_when(2, 20, "sunny")
	for id in ["house", "mine_floor", "greenhouse", "store", "coop"]:
		var m: MapData = MapManager.data(id)
		check(not HoshigakiRules.outdoors(m) and not HoshigakiRules.hangs_now(g, m), "%s: none (indoors, the mine or under glass)" % id)
	check(not HoshigakiRules.hangs_now(null, farm) and not HoshigakiRules.hangs_now(g, null), "no game or no map: none")


func _drying() -> void:
	var cfg := HoshigakiRules.config()
	check(HoshigakiRules.days_hung(10) == 0 and HoshigakiRules.days_hung(20) == 10, "days hung from the window's first day")
	check(HoshigakiRules.stage(0) == 0, "fresh on the first day")
	var last := (cfg.stages as Array).size() - 1
	check(HoshigakiRules.stage(int(cfg.dry.full_days)) == last and HoshigakiRules.stage(60) == last, "fully dried at full_days and after")
	var prev := -1
	var mono := true
	for d in 25:
		var s := HoshigakiRules.stage(d)
		mono = mono and s >= prev
		prev = s
	check(mono, "the stage never goes back as the days pass")
	var lum := func(i: int) -> float: return Color(str(cfg.stages[i].base)).get_luminance()
	var area := func(i: int) -> int: return int(cfg.stages[i].big[0]) * int(cfg.stages[i].big[1])
	var darker := true
	var smaller := true
	for i in range(1, last + 1):
		darker = darker and float(lum.call(i)) < float(lum.call(i - 1))
		smaller = smaller and int(area.call(i)) <= int(area.call(i - 1))
	check(darker, "each stage darker than the one before")
	check(smaller and int(area.call(last)) < int(area.call(0)), "shrinking as they dry")
	var fresh := Color(str(cfg.stages[0].base))
	var dry := Color(str(cfg.stages[last].base))
	check(fresh.r > 0.85 and fresh.g > 0.45 and fresh.b < 0.3, "fresh: a bright orange (%s)" % fresh.to_html(false))
	check(dry.r < 0.6 and dry.r > dry.g * 1.6 and dry.b < dry.g, "dried: a deep red-brown (%s)" % dry.to_html(false))
	_when(2, 20, "sunny")
	check(HoshigakiRules.days_now(g) == 10, "days now in the window: the real days hung")
	_when(1, 20, "sunny")
	check(HoshigakiRules.days_now(g) == int(cfg.force.days), "days now outside the window: force.days")


func _sway() -> void:
	var cfg := HoshigakiRules.config()
	var still := true
	for i in 200:
		still = still and HoshigakiRules.sway_angle(0.0, i * 0.37, 0.4) == 0.0
	check(still, "sway: dead calm, the strings hang still")
	var peaks := []
	for w in [0.1, 0.4, 1.0]:
		var peak := 0.0
		for i in 1200:
			peak = maxf(peak, absf(HoshigakiRules.sway_angle(w, i * 0.05, 0.3)))
		peaks.append(peak)
	check(peaks[0] > 0.0 and peaks[1] > peaks[0] and peaks[2] > peaks[1], "sway: more wind, a wider swing (%s)" % [peaks])
	check(float(peaks[2]) <= deg_to_rad(float(cfg.sway.max_deg)) + 0.0001, "sway: within its reach at a gale")
	check(HoshigakiRules.sway_angle(0.6, 3.0, 0.1) != HoshigakiRules.sway_angle(0.6, 3.0, 0.7), "sway: the strings do not swing as one")
	check(absi(HoshigakiRules.flat_shift(1.0, 2.0, 0.2)) <= int(cfg.flat.shift_px) and HoshigakiRules.flat_shift(0.0, 2.0, 0.2) == 0, "flat: a pixel's shift at most, none in calm")


func _art() -> void:
	var cfg := HoshigakiRules.config()
	for small in [false, true]:
		for st in (cfg.stages as Array).size():
			var img: Image = PlaceholderArt.image(HoshigakiRules.art_key(8, st, small))
			var look: Dictionary = cfg.stages[st]
			var light := Color(str(look.light))
			var base := Color(str(look.base))
			var dark := Color(str(look.dark))
			var n := {"light": 0, "base": 0, "dark": 0}
			var rx := HoshigakiArt.rope_x(small)
			for y in img.get_height():
				for x in img.get_width():
					var p := img.get_pixel(x, y)
					if p.a == 0.0:
						continue
					if p.is_equal_approx(light):
						n.light += 1
					elif p.is_equal_approx(base):
						n.base += 1
					elif p.is_equal_approx(dark):
						n.dark += 1
			var what := "%s stage %d" % ["small" if small else "big", st]
			check(n.light > 0 and n.base > 0 and n.dark > 0, "art %s: three tones (%s)" % [what, n])
			check(img.get_pixel(rx, 0).a > 0.0 and img.get_pixel(rx, img.get_height() - 1).a > 0.0, "art %s: the rope from top to tail" % what)
			check(img.get_pixel(0, 0).a == 0.0, "art %s: the corner beside the loop is clear" % what)
		var a: Image = PlaceholderArt.image(HoshigakiRules.art_key(6, 0, small))
		var b: Image = PlaceholderArt.image(HoshigakiRules.art_key(10, 0, small))
		check(b.get_height() > a.get_height(), "art: more persimmons, a longer string")
	# Lit from the upper left: in a fresh big fruit the light tone sits above and left of the dark.
	var img: Image = PlaceholderArt.image(HoshigakiRules.art_key(6, 0, false))
	var w: int = int(cfg.stages[0].big[0])
	var rx := HoshigakiArt.rope_x(false)
	var ly := 0.0
	var lx := 0.0
	var dy := 0.0
	var dx := 0.0
	var nl := 0
	var nd := 0
	var top := HoshigakiArt.LOOP + 1   # the first fruit (left of the rope): rows top .. top + h
	for y in range(top, top + int(cfg.stages[0].big[1])):
		for x in range(rx - w, rx):
			var p := img.get_pixel(x, y)
			if p.is_equal_approx(Color(str(cfg.stages[0].light))):
				ly += y
				lx += x
				nl += 1
			elif p.is_equal_approx(Color(str(cfg.stages[0].dark))):
				dy += y
				dx += x
				nd += 1
	check(nl > 0 and nd > 0 and ly / nl < dy / nd and lx / nl < dx / nd, "art: the light on the upper left, the shade on the lower right")
	var stem := Color(str(cfg.rope.stem))
	check(img.get_pixel(rx, HoshigakiArt.LOOP).is_equal_approx(stem), "art: the stalk's knot on the rope")
	check(PlaceholderArt.tex(HoshigakiRules.art_key(7, 1, false)) is Texture2D, "art: a texture from the key")


func _placement() -> void:
	var cfg := HoshigakiRules.config()
	var a := Vector3(1.45, 1.45, 4.05)
	var b := Vector3(7.55, 1.45, 4.05)
	var out := Vector3(0, 0, 1)
	var door := [Vector2(4, 5)]
	var s1 := HoshigakiRules.spots(a, b, out, door)
	check(s1.size() >= 4 and s1.size() <= int(cfg.eave.most), "the farmhouse's eave carries strings (%d)" % s1.size())
	check(str(s1) == str(HoshigakiRules.spots(a, b, out, door)), "the same eave: the same strings every time")
	var ok := true
	var fruit_ok := true
	var prev := -10.0
	var gaps := true
	for s in s1:
		var at: Vector3 = s.at
		ok = ok and is_equal_approx(at.y, 1.45) and is_equal_approx(at.z, 4.05 - float(cfg.eave.tuck)) \
			and at.x >= a.x + float(cfg.eave.inset) - 0.001 and at.x <= b.x - float(cfg.eave.inset) + 0.001
		check(at.x < 4.0 - float(cfg.eave.door_margin) or at.x > 5.0 + float(cfg.eave.door_margin), "clear of the door (x %.2f)" % at.x)
		fruit_ok = fruit_ok and int(s.fruit) >= int(cfg.fruit[0]) and int(s.fruit) <= int(cfg.fruit[1])
		gaps = gaps and at.x - prev >= float(cfg.eave.gap[0]) - 0.001
		prev = at.x
	check(ok, "every string on the eave line, inset, tucked under the soffit")
	check(fruit_ok, "6 to 10 persimmons on each")
	check(gaps, "no two closer than the smallest gap")
	check(HoshigakiRules.spots(a, a + Vector3(0.5, 0, 0), out).is_empty(), "an eave too short for its insets: none")
	var flat := HoshigakiRules.flat_spots(32, 112, 64, [Vector2i(64, 80)])
	var half := HoshigakiRules.flat_half_width()
	var clear := true
	for s in flat:
		clear = clear and (int(s.x) + half < 64 - int(cfg.flat.door_margin) or int(s.x) - half >= 80 + int(cfg.flat.door_margin))
		clear = clear and int(s.x) - half >= 32 and int(s.x) + half < 112 and int(s.y) == 64
		clear = clear and int(s.fruit) <= int(cfg.flat.most_fruit)
	check(flat.size() >= 3, "flat: the farmhouse's 80 px eave carries strings (%d)" % flat.size())
	check(clear, "flat: under the eave's own columns, clear of the door, short enough")
	# The village houses: some, not all, by a hash of their cell.
	var picked := 0
	var all := 0
	for id in ["town", "kaminoda", "minamino", "sakurazaka"]:
		for p in (MapManager.data(id) as MapData).props:
			if str(p.kind) == "village_house":
				all += 1
				if HoshigakiRules.village_hangs(Vector2i(p.cell)):
					picked += 1
	check(picked > 0 and picked < all, "a few village houses hang strings (%d of %d)" % [picked, all])
	check(not HL.hosts_for(MapManager.data("town")).is_empty(), "the village has at least one")


func _on_eave(at: Vector3, eaves: Array[Dictionary]) -> bool:
	var tuck := float(HoshigakiRules.config().eave.tuck)
	for e in eaves:
		var p := at + (e.out as Vector3) * tuck
		var q := Geometry3D.get_closest_point_to_segment(p, e.a, e.b)
		if q.distance_to(p) < 0.001:
			return true
	return false


func _layer_farm() -> void:
	var farm: MapData = MapManager.data("farm")
	_when(2, 20, "sunny")
	var pair = MAIN.new_world(farm)
	var fw: Node3D = pair[0]
	root.add_child(fw)
	for step in pair[1]:
		step.call()
	var layers := fw.get_children().filter(func(n): return n.get_script() == HL)
	check(layers.size() == 1, "3D: the farm builds one hoshigaki layer (%d)" % layers.size())
	if layers.size() == 1:
		var layer = layers[0]
		layer.refresh()
		check(layer.string_count() >= 4 and layer.visible, "3D farm: strings out on fall 20 (%d)" % layer.string_count())
		var on := true
		var front := true
		for s in layer.spot_list():
			on = on and _on_eave(s.at, fw.eaves)
			front = front and absf((s.at as Vector3).z - (4.05 - float(HoshigakiRules.config().eave.tuck))) < 0.001
			check((s.at as Vector3).x < 4.0 or (s.at as Vector3).x > 5.0, "3D farm: no string over the door (x %.2f)" % (s.at as Vector3).x)
		check(on and front, "3D farm: every string on the farmhouse's listed front eave")
		check(layer.shown_stage() == HoshigakiRules.stage(10), "3D: the picture of 10 days hung (stage %d)" % layer.shown_stage())
		var nodes: Array = layer.string_nodes(0)
		var sp: Sprite3D = nodes[0]
		var pivot: Node3D = nodes[1]
		check(sp.texture.get_height() == PlaceholderArt.image(HoshigakiRules.art_key(int(layer.spot_list()[0].fruit), layer.shown_stage(), false)).get_height(), "3D: the string's picture")
		check(sp.position.y < 0.0 and is_equal_approx(sp.position.y, -sp.texture.get_height() * sp.pixel_size / 2.0), "3D: hung from the pivot by its top")
		fw.set_wind(0.0)
		layer.refresh()
		check(is_zero_approx(pivot.rotation.z), "3D: calm, the strings still")
		var peak := 0.0
		fw.set_wind(0.9)
		for i in 300:
			layer._t = i * 0.05
			layer.refresh()
			peak = maxf(peak, absf(pivot.rotation.z))
		check(peak > 0.03, "3D: a strong wind swings them (%.3f rad)" % peak)
		fw.set_wind(0.0)
		# Fading with the farmhouse: its Occluders group set see-through.
		var gi := -1
		for i in fw.occluders.count():
			if fw.occluders.tag_of(i) == FW.FARM_HOUSE:
				gi = i
		check(gi >= 0, "3D: the farmhouse is an occluder tagged %s" % FW.FARM_HOUSE)
		if gi >= 0:
			fw.occluders._groups[gi].now = OC.FADED
			layer.refresh()
			check(is_equal_approx(sp.modulate.a, 1.0 - OC.FADED) and sp.alpha_cut == SpriteBase3D.ALPHA_CUT_DISABLED, "3D: the strings fade with the house (alpha %.2f)" % sp.modulate.a)
			fw.occluders._groups[gi].now = 0.0
			layer.refresh()
			check(is_equal_approx(sp.modulate.a, 1.0) and sp.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD, "3D: solid again with the house")
		_when(2, 29, "sunny")
		layer.refresh()
		check(layer.shown_stage() == HoshigakiRules.stage(19), "3D: darker on fall 29 (stage %d)" % layer.shown_stage())
		_when(2, 20, "rain")
		layer.refresh()
		check(not layer.visible, "3D: taken in on a rainy day")
		_when(0, 20, "sunny")
		layer.refresh()
		check(not layer.visible, "3D: none in spring")
	root.remove_child(fw)
	fw.free()
	await process_frame


func _layer_town() -> void:
	var town: MapData = MapManager.data("town")
	_when(2, 20, "sunny")
	var w: Node3D = MW.new()
	w.build(town)
	root.add_child(w)
	await process_frame
	var layer = null
	for n in w.get_children():
		if n.get_script() == HL:
			layer = n
	check(layer != null, "3D: the village's world builds a hoshigaki layer")
	if layer != null:
		layer.refresh()
		check(layer.string_count() > 0 and layer.visible, "3D town: strings out (%d)" % layer.string_count())
		var on := true
		for s in layer.spot_list():
			on = on and _on_eave(s.at, w.eaves)
		check(on, "3D town: every string on a listed eave line")
		var hosts: Array = HL.hosts_for(town)
		var per_host := true
		for h in hosts:
			per_host = per_host and not HL.eave_of(h, w.eaves).is_empty()
			for s in layer.spot_list():
				var at: Vector3 = s.at
				for r: Vector2 in h.bare:
					if at.x > float(h.x0) and at.x < float(h.x1) and absf(at.z - float(h.front)) < 0.8:
						check(at.x < r.x or at.x > r.y, "3D town: no string over a door (x %.2f)" % at.x)
		check(per_host, "3D town: every picked house has its front eave listed")
	w.free()
	var room: Node3D = HL.new(MapManager.data("house"), [] as Array[Dictionary])
	check(room.string_count() == 0, "a room: no strings")
	room.free()
	await process_frame


func _flat() -> void:
	_when(2, 20, "sunny")
	var town: MapData = MapManager.data("town")
	var view: Node2D = HV.new().setup(town)
	root.add_child(view)
	view.refresh()
	var shown: Array = view.shown()
	check(shown.size() > 0 and view.visible, "flat town: strings shown (%d)" % shown.size())
	var under := true
	for it in shown:
		var s: Dictionary = it.spot
		var ok := false
		for p in town.props:
			if str(p.kind) == "village_house":
				var inner := Rect2(Vector2(p.cell * 16), Vector2(p.size * 16)).grow(-1)
				ok = ok or (int(s.y) == int(inner.end.y) and int(s.x) >= int(inner.position.x) and int(s.x) < int(inner.end.x))
		under = under and ok
	check(under, "flat town: every string under a village roof's bottom eave")
	var doors_clear := true
	for door in town.doors:
		for c: Vector2i in door.cells:
			for it in shown:
				var s: Dictionary = it.spot
				if int(s.y) == (c.y + 1) * 16 - 1 and int(s.x) + 3 >= c.x * 16 and int(s.x) - 3 < c.x * 16 + 16:
					doors_clear = false
	check(doors_clear, "flat town: none in front of a door")
	check(str(shown[0].key).ends_with(":small") if not shown.is_empty() else false, "flat: the small pictures")
	_when(2, 20, "storm")
	view.refresh()
	check(not view.visible, "flat: a storm takes them in")
	view.free()
	_when(2, 20, "sunny")
	var fspots: Array = HV.spots_for(MapManager.data("farm"), g.farm)
	var house: Rect2 = load("res://scripts/farm/farm_view.gd").roof_rect(g.farm, "house")
	var row := int(house.end.y) / 16 - 1
	var door_ok := true
	for s in fspots:
		for k in range(-HoshigakiRules.flat_half_width(), HoshigakiRules.flat_half_width() + 1):
			if g.farm.fixed_at(Vector2i((int(s.x) + k) / 16, row)) != "house":
				door_ok = false
	check(fspots.size() >= 3, "flat farm: strings under the farmhouse's roof (%d)" % fspots.size())
	check(door_ok, "flat farm: none in front of the farmhouse's door")
	check(HV.spots_for(MapManager.data("house")).is_empty() and HV.spots_for(MapManager.data("greenhouse")).is_empty(), "flat: none in a room or the greenhouse")
	# main_2d builds it on the farm.
	g.maps.place("farm", Vector2i(4, 5), Vector2i.DOWN)
	var scene: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var hv = null
	for n in scene.view.get_children():
		if n.get_script() == HV:
			hv = n
	check(hv != null and hv.visible and hv.shown().size() >= 3, "flat (main_2d): the farm's view hangs them")
	scene.free()
	await process_frame
