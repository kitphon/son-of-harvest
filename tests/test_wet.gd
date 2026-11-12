extends SceneTree
## Headless checks for the wet look in rain (WetRules, data/wet.json): the wetness by weather and
## clock (growing over the first hour of rain, drying over the next morning), none under snow,
## indoors, under glass or in the mine, the forced wetness (`--wet=`); the surfaces (tilled soil
## darkest, kawara glossiest, thatch little, grass least), the tone and tint sums, identity at 0;
## the ground masks; the 3D materials wetted and put back exactly (WetLayer on a built MapWorld,
## the ground shader's `wet`); the flat view's tints, stone props and eave glints. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_wet.gd

var failures := 0
var g: Node
var FW: GDScript   # FarmWorld, MapWorld, Minka: loaded once the autoloads are up
var MW: GDScript
var MK: GDScript


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	FW = load("res://scripts/world3d/farm_world.gd")
	MW = load("res://scripts/world3d/map_world.gd")
	MK = load("res://scripts/world3d/minka.gd")
	g.new_game()
	g.clock_running = false
	_gating()
	_growth_and_drying()
	_surfaces()
	_masks()
	_materials()
	await _world3d()
	_flat()
	await _farm_buildings()
	_snow_flag()
	print("test_wet: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _when(hour: int, minute: int, weather: String, yesterday := "") -> void:
	g.season = 0
	g.day = 10
	g.hour = hour
	g.minute = minute
	g.weather_today = weather
	g.weather_yesterday = yesterday
	g.snow_cover = 0


func _gating() -> void:
	check(WetRules.wetness("rain", "", 12.0, 0.0) > 0.0 and WetRules.wetness("storm", "", 12.0, 0.0) > 0.0, "rain and storm wet things")
	check(WetRules.wetness("sunny", "", 12.0, 0.0) == 0.0, "a fair day: dry")
	check(WetRules.wetness("snow", "", 12.0, 0.0) == 0.0 and WetRules.wetness("blizzard", "", 12.0, 0.0) == 0.0, "snow and blizzard: dry")
	check(WetRules.wetness("rain", "", 12.0, 30.0) == 0.0, "rain on lying snow: never wet")
	check(WetRules.wetness("sunny", "storm", 7.0, 5.0) == 0.0, "snow lying keeps yesterday's rain away too")
	var town: MapData = MapManager.data("town")
	_when(12, 0, "rain")
	check(WetRules.wetness_now(g, town) == 1.0, "the town at noon in rain: fully wet")
	check(WetRules.wetness_now(g, MapManager.data("house")) == 0.0, "indoors: dry")
	check(WetRules.wetness_now(g, MapManager.data("greenhouse")) == 0.0, "under glass: dry")
	check(WetRules.wetness_now(g, MapManager.data("mine_floor")) == 0.0, "the mine: dry")
	check(WetRules.wetness_of(g, true) == 0.0 and WetRules.wetness_of(g, false) == 1.0, "wetness_of by indoor")
	g.snow_cover = 40
	check(WetRules.wetness_now(g, town) == 0.0, "snow lying in town: dry")
	# Forced (`--wet=`): any weather outdoors, still never indoors or under snow.
	_when(12, 0, "sunny")
	WetRules.forced = 0.6
	check(is_equal_approx(WetRules.wetness_now(g, town), 0.6), "forced 0.6 on a fair day")
	check(WetRules.wetness_now(g, MapManager.data("house")) == 0.0, "forced: still dry indoors")
	g.snow_cover = 50
	check(WetRules.wetness_now(g, town) == 0.0, "forced: still dry under snow")
	WetRules.forced = -1.0
	_when(12, 0, "sunny")
	check(WetRules.wetness_now(g, town) == 0.0, "unforced again: dry")
	check(FileAccess.get_file_as_string("res://scripts/autoload/game.gd").contains("--wet="), "the --wet= flag is read")


func _growth_and_drying() -> void:
	check(WetRules.wetness("rain", "", 6.0, 0.0) == 0.0, "rain at 06:00: not wet yet")
	check(is_equal_approx(WetRules.wetness("rain", "", 6.5, 0.0), 0.5), "rain at 06:30: half")
	check(WetRules.wetness("rain", "", 7.0, 0.0) == 1.0 and WetRules.wetness("storm", "", 15.0, 0.0) == 1.0, "an hour on: fully wet")
	check(WetRules.wetness("rain", "", 2.0, 0.0) == 1.0, "the small hours after a rainy day: still wet")
	var last := -1.0
	var rising := true
	for i in 13:
		var w := WetRules.wetness("rain", "", 6.0 + i * 0.1, 0.0)
		rising = rising and w >= last
		last = w
	check(rising, "it only gets wetter through the first hour")
	check(WetRules.wetness("sunny", "rain", 6.0, 0.0) == 1.0, "the morning after: still wet at 06:00")
	check(is_equal_approx(WetRules.wetness("sunny", "rain", 8.5, 0.0), 0.5), "drying: half by 08:30")
	check(WetRules.wetness("sunny", "rain", 11.0, 0.0) == 0.0 and WetRules.wetness("cloudy", "storm", 13.0, 0.0) == 0.0, "dry by late morning")
	check(WetRules.wetness("rain", "rain", 6.0, 0.0) == 1.0, "a second rainy day starts wet")
	_when(6, 30, "rain")
	check(WetRules.step_of(WetRules.wetness_now(g, MapManager.data("town"))) == 25, "steps of 1/50")


func _surfaces() -> void:
	var d := func(k: String) -> float: return float(WetRules.surface(k).dark)
	var gl := func(k: String) -> float: return float(WetRules.surface(k).gloss)
	check(d.call("tilled") < d.call("path") and d.call("path") < d.call("grass"), "tilled soil darker than a path, a path darker than grass")
	check(d.call("tilled") <= d.call("stone") and d.call("tilled") <= d.call("gravel"), "tilled soil darkest of the ground")
	check(gl.call("kawara") > gl.call("stone") and gl.call("kawara") > gl.call("thatch") * 5.0, "kawara tile glossiest, thatch hardly")
	check(d.call("kawara") < d.call("thatch") and d.call("thatch") < 1.0, "thatch darkens less than tile, but some")
	var brown := Color("a07446")
	var rule := WetRules.surface("tilled")
	check(WetRules.tone(brown, rule, 0.0) == brown, "tone at 0: the colour itself")
	check(WetRules.tint_for(brown, rule, 0.0) == Color.WHITE, "tint at 0: white")
	var t := WetRules.tone(brown, rule, 1.0)
	check(t.v < brown.v * 0.7 and t.s > brown.s, "wet soil darker and more saturated (v %.2f -> %.2f, s %.2f -> %.2f)" % [brown.v, t.v, brown.s, t.s])
	var half := WetRules.tone(brown, rule, 0.5)
	check(half.v < brown.v and half.v > t.v, "half wet in between")
	var k := WetRules.tint_for(brown, rule, 1.0)
	var back := Color(brown.r * k.r, brown.g * k.g, brown.b * k.b)
	check(absf(back.r - t.r) < 0.01 and absf(back.g - t.g) < 0.01 and absf(back.b - t.b) < 0.01, "the tint takes the mean colour to its tone")
	check(WetRules.picture_tint("ground:path:0", "", 1.0) == Color.WHITE and WetRules.picture_tint("ground:path:0", "path", 0.0) == Color.WHITE, "no surface or dry: white")
	check(WetRules.picture_tint("ground:path:0", "path", 1.0).v < 0.8, "a wet path picture: darker")
	check(WetRules.ground_surface("water") == "" and WetRules.ground_surface("bed") == "", "water and the greenhouse beds never wet")
	check(WetRules.ground_surface("tilled") == "tilled" and WetRules.ground_surface("scree") == "gravel", "ground kinds to surfaces")


func _masks() -> void:
	var town: MapData = MapManager.data("town")
	var img := WetRules.map_mask(town)
	check(img.get_width() == town.w and img.get_height() == town.h, "a map's mask: a pixel a cell")
	var path_c := Vector2i(-1, -1)
	var water_c := Vector2i(-1, -1)
	for y in town.h:
		for x in town.w:
			var c := Vector2i(x, y)
			if town.tile(c) == "path" and path_c.x < 0:
				path_c = c
			if town.tile(c) == "water" and water_c.x < 0:
				water_c = c
	var pc := img.get_pixel(path_c.x, path_c.y)
	check(absf(pc.r - float(WetRules.surface("path").dark)) < 0.01 and absf(pc.b - float(WetRules.surface("path").gloss)) < 0.01, "a path cell carries the path's dark and gloss")
	if water_c.x >= 0:
		var wc := img.get_pixel(water_c.x, water_c.y)
		check(absf(wc.r - 1.0) < 0.01 and absf(wc.g - 0.5) < 0.01 and wc.b < 0.01, "a water cell is neutral")
	var inside := WetRules.map_mask(MapManager.data("house"))
	var ip := inside.get_pixel(0, 0)
	check(absf(ip.r - 1.0) < 0.01 and absf(ip.g - 0.5) < 0.01 and ip.b < 0.01, "indoors: neutral")
	# The farm: a tilled cell darker than the grass by it.
	var farm: FarmGrid = g.farm
	var tc := Vector2i(-1, -1)
	var gc := Vector2i(-1, -1)
	for y in farm.h:
		for x in farm.w:
			var c := Vector2i(x, y)
			var k := WetRules.farm_kind(farm, c)
			if k == "tilled" and tc.x < 0:
				tc = c
			if k == "grass" and gc.x < 0:
				gc = c
	if tc.x < 0:   # a new game has no tilled cells: hoe one
		for y in farm.h:
			for x in farm.w:
				if tc.x < 0 and farm.fixed_at(Vector2i(x, y)) == "" and WetRules.farm_kind(farm, Vector2i(x, y)) == "grass" and Vector2i(x, y) != gc:
					tc = Vector2i(x, y)
		farm.cell(tc).tilled = true
	var fm := WetRules.farm_mask(farm)
	check(fm.get_pixel(tc.x, tc.y).r < fm.get_pixel(gc.x, gc.y).r, "the farm's mask: tilled soil darker than grass")


func _materials() -> void:
	var kawara: StandardMaterial3D = FW.surface_material("build:kawara")
	var thatch: StandardMaterial3D = FW.surface_material("build:thatch")
	var stone: StandardMaterial3D = MK.plain(Color("9a968e"))
	var red: StandardMaterial3D = MK.plain(Color("c8342c"))
	var glow: StandardMaterial3D = FW.flat_material(Color("ffe6a8"))
	var paper: StandardMaterial3D = FW.picture_material("build:shoji")
	check(WetRules.material_surface(kawara) == "kawara" and WetRules.material_surface(thatch) == "thatch", "roof pictures to their surfaces")
	check(WetRules.material_surface(FW.surface_material("ground:rock_wall:2")) == "stone", "a picture's variant key")
	check(WetRules.material_surface(stone) == "stone" and WetRules.material_surface(red) == "plain", "a grey plain colour is stone, others plain")
	check(WetRules.material_surface(glow) == "" and WetRules.material_surface(paper) == "", "unshaded glows and paper never wet")
	var before := [kawara.albedo_color, kawara.roughness, kawara.metallic_specular, stone.albedo_color, stone.roughness, stone.metallic_specular]
	check(WetRules.wet_material(kawara, 1.0) and WetRules.wet_material(stone, 1.0), "wetting returns true for wet surfaces")
	WetRules.wet_material(thatch, 1.0)
	check(kawara.albedo_color.v < 0.8 and kawara.roughness < 0.5 and kawara.metallic_specular > 0.8, "wet kawara: darker, glossy")
	check(thatch.roughness > kawara.roughness + 0.4, "wet thatch stays matt")
	check(stone.albedo_color.v < Color("9a968e").v * 0.8 and stone.roughness < 0.9, "wet stone: darker, a little glossy")
	WetRules.wet_material(kawara, 0.0)
	WetRules.wet_material(stone, 0.0)
	var after := [kawara.albedo_color, kawara.roughness, kawara.metallic_specular, stone.albedo_color, stone.roughness, stone.metallic_specular]
	check(after == before, "dry again: exactly as built")
	check(not kawara.has_meta("wet_dry") and not stone.has_meta("wet_dry"), "dry again: no wet record left")
	# An Occluders fade's alpha is kept.
	WetRules.wet_material(stone, 1.0)
	stone.albedo_color.a = 0.4
	WetRules.wet_material(stone, 0.5)
	check(is_equal_approx(stone.albedo_color.a, 0.4), "wetting keeps a fade's alpha")
	WetRules.wet_material(stone, 0.0)
	check(is_equal_approx(stone.albedo_color.a, 0.4) and Color(stone.albedo_color.r, stone.albedo_color.g, stone.albedo_color.b) == Color("9a968e"), "drying keeps it too, the colour back")
	# The ground shader.
	var gm := SnowLayer.ground_material(WetRules.neutral_texture(), WetRules.neutral_texture())
	check(SnowLayer.is_ground(gm) and not SnowLayer.is_ground(SnowLayer.top_material()), "is_ground knows the ground material")
	check(float(gm.get_shader_parameter("wet") if gm.get_shader_parameter("wet") != null else 0.0) == 0.0, "the ground starts dry")
	check(SnowLayer.GROUND_SHADER.contains("if (wet > 0.0)") and SnowLayer.GROUND_SHADER.contains("if (gloss > 0.0)"), "the ground shader leaves dry ground as it was")


func _world3d() -> void:
	var town: MapData = MapManager.data("town")
	_when(12, 0, "sunny")
	var w: Node3D = MW.new()
	w.build(town)
	root.add_child(w)
	await process_frame
	var layer: WetLayer = null
	for n in w.get_children():
		if n is WetLayer:
			layer = n
	check(layer != null, "an outdoor map's world builds a WetLayer")
	if layer == null:
		w.free()
		return
	var snap := func() -> Dictionary:
		var out := {}
		for n in w.find_children("*", "GeometryInstance3D", true, false):
			var m := (n as GeometryInstance3D).material_override
			if m is StandardMaterial3D:
				out[m] = [m.albedo_color, m.roughness, m.metallic_specular]
		return out
	var dry: Dictionary = snap.call()
	check(layer.wetness() == 0.0, "a fair day: the layer dry")
	_when(12, 0, "rain")
	layer.refresh()
	check(layer.wetness() == 1.0, "rain at noon: the layer fully wet")
	var grounds := 0
	var wet_grounds := 0
	var kawara_wet := 0
	var stone_wet := 0
	for n in w.find_children("*", "GeometryInstance3D", true, false):
		var m := (n as GeometryInstance3D).material_override
		if SnowLayer.is_ground(m):
			grounds += 1
			if float(m.get_shader_parameter("wet")) == 1.0:
				wet_grounds += 1
		elif m is StandardMaterial3D and m.has_meta("wet_dry"):
			var kind: String = m.get_meta("wet_dry")[3]
			if kind == "kawara" and m.albedo_color.v < 0.8 and m.roughness < 0.5:
				kawara_wet += 1
			if kind == "stone" and m.albedo_color.v < (m.get_meta("wet_dry")[0] as Color).v:
				stone_wet += 1
	check(grounds >= 2 and wet_grounds == grounds, "the map's ground and the land past its edge wet (%d of %d)" % [wet_grounds, grounds])
	check(kawara_wet > 0, "the village roofs' kawara wet and glossy (%d)" % kawara_wet)
	check(stone_wet > 0, "stone wet (%d)" % stone_wet)
	_when(12, 0, "sunny")
	layer.refresh()
	var again: Dictionary = snap.call()
	var same := again.size() == dry.size()
	for m in dry:
		same = same and again.has(m) and again[m] == dry[m]
	check(same, "a fair day again: every material exactly as built (%d)" % dry.size())
	var still_wet := 0
	for n in w.find_children("*", "GeometryInstance3D", true, false):
		var m := (n as GeometryInstance3D).material_override
		if SnowLayer.is_ground(m) and float(m.get_shader_parameter("wet")) != 0.0:
			still_wet += 1
	check(still_wet == 0, "the grounds dry again")
	# Snow lying: never wet.
	_when(12, 0, "rain")
	g.snow_cover = 60
	layer.refresh()
	check(layer.wetness() == 0.0, "snow lying: the layer dry")
	g.snow_cover = 0
	w.free()
	# Indoors: no layer.
	var hw: Node3D = MW.new()
	hw.build(MapManager.data("house"))
	var has := false
	for n in hw.get_children():
		has = has or n is WetLayer
	check(not has, "an indoor world has no WetLayer")
	hw.free()
	check(FileAccess.get_file_as_string("res://scripts/main_3d.gd").contains("WetLayer.new(m)"), "the farm's 3D world builds a WetLayer")


func _flat() -> void:
	var town: MapData = MapManager.data("town")
	var view := MapView.new()
	view.map = town
	root.add_child(view)
	_when(12, 0, "sunny")
	view.update_wet()
	check(view.wet == 0.0, "flat: dry on a fair day")
	_when(6, 30, "rain")
	view.update_wet()
	check(is_equal_approx(view.wet, 0.5), "flat: half wet at 06:30 in rain")
	_when(12, 0, "rain")
	view.update_wet()
	check(view.wet == 1.0, "flat: wet at noon")
	var roof := RoofArt.key("kawara", "gable", 1, Vector2i(46, 30))
	check(MapView.roof_tint(roof, "kawara", 0.0) == Color.WHITE, "flat roof dry: drawn as it is")
	var kt := MapView.roof_tint(roof, "kawara", 1.0)
	var tt := MapView.roof_tint(RoofArt.key("thatch", "gable", 1, Vector2i(46, 30)), "thatch", 1.0)
	check(kt.v < 0.8 and tt.v > kt.v, "flat roofs: kawara darkens more than thatch")
	var lantern: Color = MapView.COLORS.stone_lantern
	check(MapView.prop_tone(lantern, "stone_lantern", 0.0) == lantern, "flat stone lantern dry: as it is")
	check(MapView.prop_tone(lantern, "stone_lantern", 1.0).v < lantern.v * 0.8, "flat stone lantern wet: darker")
	check(MapView.prop_tone(MapView.COLORS.pine, "pine", 1.0) == MapView.COLORS.pine, "flat: props not listed stay as they are")
	var r := Rect2(16, 16, 46, 30)
	var drips := WetRules.drips(r, 1.0)
	var on_eave := not drips.is_empty()
	for p in drips:
		on_eave = on_eave and p.y == r.end.y - 1.0 and p.x > r.position.x and p.x < r.end.x - 1.0
	check(on_eave, "flat: eave glints on the bottom eave (%d)" % drips.size())
	check(WetRules.drips(r, 0.3).is_empty(), "flat: no eave glints while barely wet")
	g.snow_cover = 20
	view.update_wet()
	check(view.wet == 0.0, "flat: under snow dry")
	g.snow_cover = 0
	view.free()
	var house := MapView.new()
	house.map = MapManager.data("house")
	root.add_child(house)
	_when(12, 0, "storm")
	house.update_wet()
	check(house.wet == 0.0, "flat: indoors dry")
	house.free()
	var fv := FarmView.new()
	fv.farm = g.farm
	root.add_child(fv)
	fv.update_wet()
	check(fv.wet == 1.0, "flat farm: wet in a storm")
	var ground := FarmView.new()
	ground.ground_only = true
	ground.farm = g.farm
	root.add_child(ground)
	ground.update_wet()
	check(ground.wet == 0.0, "the 3D ground's picture stays dry (the shader wets it)")
	fv.free()
	ground.free()


## The silo and the greenhouse on the farm get wet like the other buildings: in 3D their flat-colored
## timber, hoops, stone and the glass are marked surfaces (the staves and cone are pictures) and go
## back exactly; in the flat view their parts take the tones of data/wet.json flat.props and the glass
## roof gets a few rain glints.
func _farm_buildings() -> void:
	var w: Node3D = FW.new()
	load("res://scripts/world3d/silo_props.gd").silo(w)
	load("res://scripts/world3d/greenhouse_props.gd").greenhouse(w)
	var snap := func() -> Dictionary:
		var out := {}
		for n in w.find_children("*", "GeometryInstance3D", true, false):
			var m := (n as GeometryInstance3D).material_override
			if m is StandardMaterial3D:
				out[m] = [m.albedo_color, m.roughness, m.metallic_specular]
		return out
	var dry: Dictionary = snap.call()
	var kinds := {}
	for m in dry:
		var k := WetRules.material_surface(m)
		kinds[k] = int(kinds.get(k, 0)) + 1
	for k in ["wood", "kawara", "stone", "glass", "plain"]:
		check(kinds.get(k, 0) > 0, "3D silo + greenhouse: some %s surfaces (%s)" % [k, kinds])
	var count := WetLayer.apply(w, 1.0)
	check(count > 0, "3D silo + greenhouse: wetted (%d)" % count)
	var glass_ok := false
	var frame_ok := false
	var cone_ok := false
	for m in dry:
		var kind := WetRules.material_surface(m)
		if kind == "glass":
			glass_ok = m.albedo_color.v < dry[m][0].v and is_equal_approx(m.albedo_color.a, dry[m][0].a) and m.roughness < dry[m][1]
		elif kind == "wood" and m.albedo_texture == null:
			frame_ok = m.albedo_color.v < dry[m][0].v
		elif kind == "kawara":
			cone_ok = m.albedo_color.v < dry[m][0].v
	check(glass_ok, "3D greenhouse glass: slightly darker, glossier, same see-through alpha")
	check(frame_ok, "3D greenhouse / silo timber (flat color): darker")
	check(cone_ok, "3D silo's tiled cone: darker")
	WetLayer.apply(w, 0.0)
	var again: Dictionary = snap.call()
	var same := again.size() == dry.size()
	for m in dry:
		same = same and again.has(m) and again[m] == dry[m]
	check(same, "3D silo + greenhouse dry again: every material exactly as built")
	w.free()
	# Flat view: the parts.
	var cfg := WetRules.config()
	for part in ["silo_staves", "silo_cone", "silo_hoops", "silo_hatch", "gh_frame", "gh_glass", "gh_skirt", "gh_door"]:
		check(cfg.flat.props.has(part), "flat part %s has a surface" % part)
		var c := Color("a0764a")
		check(MapView.prop_tone(c, part, 0.0) == c, "flat part %s dry: as it is" % part)
		check(MapView.prop_tone(c, part, 1.0).v < c.v, "flat part %s wet: darker" % part)
	var gl := Color("bcd8d0")
	var gt := MapView.prop_tone(gl, "gh_glass", 1.0)
	var wt := MapView.prop_tone(Color("7a5a3a"), "gh_frame", 1.0)
	check(gt.v > gl.v * 0.85 and gt.v < gl.v, "flat glass: only a slight darkening (%.2f -> %.2f)" % [gl.v, gt.v])
	check(wt.v < Color("7a5a3a").v * 0.85, "flat greenhouse frame: darkens as wood")
	var roof := Rect2(0, 0, 64, 22)
	check(WetRules.glints(roof, 0.3).is_empty(), "flat glass: no glints while barely wet")
	var spots := WetRules.glints(roof, 1.0)
	var inside := not spots.is_empty()
	for p in spots:
		inside = inside and roof.has_point(p)
	check(inside, "flat glass: glints inside the roof when wet (%d)" % spots.size())
	check(WetRules.glints(roof, 1.0) == spots, "flat glass: the glints are always the same ones")
	# Drawn: a built farm's flat view in rain differs from dry, never under snow.
	g.new_game()
	g.clock_running = false
	g._finish_build({"build": "greenhouse", "shop": "general", "ready": 0})
	g._finish_build({"build": "silo", "shop": g._builder_shop("silo"), "ready": 0})
	var fv := FarmView.new()   # no pixels in a headless run: the view's own wetness and part tones
	fv.farm = g.farm
	root.add_child(fv)
	var staves := Color("a0764a")
	_when(12, 0, "sunny")
	fv.update_wet()
	check(fv.wet == 0.0 and fv._wt(staves, "silo_staves") == staves, "flat farm with silo + greenhouse: a fair day draws them as they are")
	check(fv.silo_pile_rect() == Rect2() or fv.wet == 0.0, "flat silo pile: nothing special when dry")
	_when(12, 0, "rain")
	fv.update_wet()
	check(fv.wet == 1.0 and fv._wt(staves, "silo_staves").v < staves.v and fv._wt(Color("55687a"), "silo_cone").v < Color("55687a").v, "flat farm: rain wets the silo's staves and cone")
	check(WetRules.picture_tint("silo:grass:1:0", "grass", 1.0) != Color.WHITE, "flat silo pile: tinted as grass in rain")
	g.snow_cover = 60
	fv.update_wet()
	check(fv.wet == 0.0 and fv._wt(staves, "silo_staves") == staves, "flat farm: rain with snow lying draws the buildings as they are")
	g.snow_cover = 0
	fv.free()


## `--snow=N` wins over `--weather=` whatever their order (Game._ready reads the flags).
func _snow_flag() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/autoload/game.gd")
	check(src.contains("if snow_flag < 0:") and src.contains("snow_flag = clampi("), "Game: --snow= is kept when --weather= comes after it")
