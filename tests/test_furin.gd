extends SceneTree
## Headless checks for the wind chime under the farmhouse's eave (FurinRules, data/furin.json;
## FurinLayer in 3D, FurinView in the flat view; the picture PlaceholderArt "furin"): it hangs out
## on the farm's open air in summer and is taken in during a storm or a blizzard, indoors and in
## other seasons it is not there; it is still in dead calm and swings more the stronger the wind,
## within its reach; its picture has the bell lit from the upper left in three tones with its
## painted band; and both views build on the farm and show it. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_furin.gd

var failures := 0
var g: Node
var FR: GDScript
var MM: GDScript
var MAIN: GDScript
var FL: GDScript
var FV: GDScript


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	FR = load("res://scripts/furin_rules.gd")
	MM = load("res://scripts/world/map_manager.gd")
	MAIN = load("res://scripts/main_3d.gd")
	FL = load("res://scripts/world3d/furin_layer.gd")
	FV = load("res://scripts/world/furin_view.gd")
	g.new_game()
	g.clock_running = true
	_data()
	_gating()
	_sway()
	_art()
	await _view_3d()
	await _view_flat()
	print("test_furin: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _when(season: int, weather: String) -> void:
	g.season = season
	g.day = 10
	g.hour = 10
	g.minute = 0
	g.weather_today = weather


func _data() -> void:
	var cfg: Dictionary = FR.config()
	check((cfg.seasons as Array) == ["summer"], "data: hangs in summer only (%s)" % [cfg.seasons])
	check((cfg.taken_in as Array).has("storm") and (cfg.taken_in as Array).has("blizzard"), "data: a storm and a blizzard take it in")
	var p: Dictionary = cfg.place
	check(float(p.z) < 4.05 and float(p.top) < 1.45, "data: hung under the eave (soffit 1.45 at z 4.05), z %s top %s" % [p.z, p.top])
	check(float(cfg.pixel_size) > 0.0 and float(cfg.sway.max_deg) > 0.0, "data: a picture size and a reach")


func _gating() -> void:
	var cfg: Dictionary = FR.config()
	check(FR.hangs("summer", "sunny", true, false), "pure: out on a sunny summer day on the farm")
	check(FR.hangs("summer", "rain", true, false), "pure: out in summer rain")
	check(not FR.hangs("summer", "storm", true, false), "pure: taken in during a summer storm")
	check(not FR.hangs("summer", "blizzard", true, false), "pure: taken in in a blizzard")
	check(not FR.hangs("spring", "sunny", true, false) and not FR.hangs("fall", "sunny", true, false) and not FR.hangs("winter", "sunny", true, false),
		"pure: not in spring, fall or winter")
	check(not FR.hangs("summer", "sunny", true, true), "pure: never indoors")
	check(not FR.hangs("summer", "sunny", false, false), "pure: only on the farm")
	check(FR.hangs("summer", "sunny", false, false, {"seasons": ["summer"], "taken_in": []}) == false, "pure: a map that is not the farm has none, whatever the config")
	check(FR.hangs("summer", "sunny", true, false, {"seasons": ["summer"], "taken_in": ["storm"]}), "pure: a config passed in is used")

	var farm: MapData = MM.data("farm")
	_when(1, "sunny")
	check(FR.hangs_now(g, farm), "game: summer, sunny, the farm: hangs")
	_when(1, "storm")
	check(not FR.hangs_now(g, farm), "game: a summer storm takes it in")
	_when(1, "rain")
	check(FR.hangs_now(g, farm), "game: a summer rain: still out")
	_when(0, "sunny")
	check(not FR.hangs_now(g, farm), "game: spring: not out")
	_when(3, "snow")
	check(not FR.hangs_now(g, farm), "game: winter: not out")
	_when(1, "sunny")
	check(not FR.hangs_now(null, farm) and not FR.hangs_now(g, null), "game: no game or no map, nothing")
	check(not FR.hangs_now(g, MM.data("house")), "game: indoors (the farmhouse's rooms) it does not hang")
	_when(1, "sunny")


func _sway() -> void:
	var cfg: Dictionary = FR.config()
	var still := true
	for i in 200:
		if FR.sway_angle(0.0, i * 0.37) != 0.0:
			still = false
	check(still, "sway: dead calm, it hangs still at every time")
	var reach := deg_to_rad(float(cfg.sway.max_deg))
	var winds := [0.1, 0.3, 0.6, 1.0]
	var peaks := []
	for w in winds:
		var peak := 0.0
		for i in 1200:   # 60 s in steps of 0.05 s: several swings and gusts
			peak = maxf(peak, absf(FR.sway_angle(w, i * 0.05)))
		peaks.append(peak)
	var grows := true
	for i in range(1, peaks.size()):
		grows = grows and peaks[i] > peaks[i - 1]
	check(grows and peaks[0] > 0.0, "sway: the swing grows with the wind (%s)" % [peaks])
	check(float(peaks[peaks.size() - 1]) <= reach + 0.0001, "sway: never beyond the reach at a full gale (%s <= %s)" % [peaks[peaks.size() - 1], reach])
	var quicker := 0
	var crossings := func(w: float) -> int:
		var n := 0
		var prev: float = FR.sway_angle(w, 0.0)
		for i in range(1, 2001):
			var a: float = FR.sway_angle(w, i * 0.01)
			if (prev < 0.0) != (a < 0.0):
				n += 1
			prev = a
		return n
	if crossings.call(1.0) > crossings.call(0.1):
		quicker = 1
	check(quicker == 1, "sway: the wind quickens the swings (%d against %d over 20 s)" % [crossings.call(1.0), crossings.call(0.1)])


func _art() -> void:
	var img: Image = PlaceholderArt.image(FR.KEY)
	check(img.get_width() == 14 and img.get_height() == 22, "art: 14 x 22 (%dx%d)" % [img.get_width(), img.get_height()])
	var light := img.get_pixel(4, 4)
	var shade := img.get_pixel(9, 11)
	var glass := img.get_pixel(7, 11)
	check(light.is_equal_approx(Color("f4fbff")) and shade.is_equal_approx(Color("5f8fb4")) and glass.is_equal_approx(Color("a8d4ec")),
		"art: lit from the upper left in three tones (light %s, glass %s, shade %s)" % [light, glass, shade])
	check(img.get_pixel(7, 8).is_equal_approx(Color("c8442c")) and img.get_pixel(7, 9).is_equal_approx(Color("c8442c")), "art: the red band on the bell")
	check(img.get_pixel(10, 16).is_equal_approx(Color("f4f0e6")) and img.get_pixel(10, 16).a > 0.5, "art: a cream paper strip under the rim")
	check(img.get_pixel(0, 21).a == 0.0, "art: the corner outside the bell is clear")
	check(PlaceholderArt.tex(FR.KEY) is Texture2D, "art: a texture from the key")


func _view_3d() -> void:
	await process_frame
	var farm: MapData = MM.data("farm")
	_when(1, "sunny")
	var pair = MAIN.new_world(farm)
	var fw: Node3D = pair[0]
	root.add_child(fw)   # in the tree, so the layers are ready (their pivots built)
	for step in pair[1]:
		step.call()
	var layers := fw.get_children().filter(func(n): return n.get_script() == FL)
	check(layers.size() == 1, "3D: the farm builds one furin (%d)" % layers.size())
	if layers.size() == 1:
		var layer = layers[0]
		layer.refresh()
		check(layer.visible, "3D: summer, sunny: hung under the eave")
		fw.set_wind(0.0)
		layer.refresh()
		check(is_zero_approx(layer.swing) and is_zero_approx(layer._pivot.rotation.z), "3D: calm wind, the chime still")
		var peak := 0.0
		for i in 400:
			layer._t = i * 0.05
			fw.set_wind(0.8)
			layer.refresh()
			peak = maxf(peak, absf(layer.swing))
		check(peak > 0.05, "3D: a strong wind swings it (peak %.3f rad)" % peak)
		_when(1, "storm")
		layer.refresh()
		check(not layer.visible, "3D: a summer storm takes it in")
		_when(0, "sunny")
		layer.refresh()
		check(not layer.visible, "3D: in spring it is not there")
		_when(1, "sunny")
	root.remove_child(fw)
	fw.free()


func _view_flat() -> void:
	g.maps.place("farm", Vector2i(4, 4), Vector2i.DOWN)
	_when(1, "sunny")
	var scene: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var view: Node2D = scene.view
	var fv = null
	for n in view.get_children():
		if n.get_script() == FV:
			fv = n
	check(fv != null, "flat (main_2d): the farm's view has the furin")
	if fv != null:
		fv.refresh()
		check(fv.visible, "flat: summer, sunny: hung")
		var at: Dictionary = fv.placed()
		check(at.top.y > 0 and at.top.y < 4.05 * 16 and at.top.x > 3 * 16 and at.top.x < 4 * 16, "flat: hung over the engawa under the eave (%s)" % [at.top])
		check(absf(float(at.shift)) <= float(FR.config().flat.hang_px), "flat: the sideways swing within its reach (%s)" % [at.shift])
		_when(1, "storm")
		fv.refresh()
		check(not fv.visible, "flat: a summer storm takes it in")
		_when(1, "sunny")
	scene.free()
	g.maps.place("hill", Vector2i(19, 28), Vector2i.UP)
	var hill_scene: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(hill_scene)
	await process_frame
	var none := true
	for n in hill_scene.view.get_children():
		if n.get_script() == FV:
			none = false
	check(none, "flat: the hill has none")
	hill_scene.free()
	await process_frame
