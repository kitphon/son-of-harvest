extends SceneTree
## Headless checks for maps (data/maps, MapData, MapManager, Game map rules). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_maps.gd

var failures := 0


func _init() -> void:
	_map_files()
	_map_rules()
	_clinic()
	_lenses()
	_sprite_casts()


## Billboard sprites cast nothing themselves (their shadow is SpriteShadow's caster, steady under
## any lens); the farmer, villagers, animals and the dog each get a SpriteShadow.
func _sprite_casts() -> void:
	var fw_src := FileAccess.get_file_as_string("res://scripts/world3d/farm_world.gd")
	var make := fw_src.substr(fw_src.find("static func make_sprite"), 600)
	check("s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF" in make, "sprite shadows: a billboard sprite casts no shadow of its own (FarmWorld.make_sprite)")
	var main_src := FileAccess.get_file_as_string("res://scripts/main_3d.gd")
	var vill_src := FileAccess.get_file_as_string("res://scripts/world3d/villager_sprites.gd")
	var animal_src := FileAccess.get_file_as_string("res://scripts/world3d/animal_layer.gd")
	check("SpriteShadow.attach(sprite" in main_src and "SpriteShadow.attach(s" in vill_src and animal_src.count("SpriteShadow.attach(s") == 2, "sprite shadows: the farmer, villagers, animals and the dog each get a SpriteShadow")


## Footprints in lying snow (Footprints rules, data/footprints.json, FootprintLayer in
## the world): left / right pairs a step apart along the walk, a ring of at most `cap`, fading
## with age (quicker in falling snow), none under the cover threshold, on ground that holds little
## snow, across a jump, indoors; the world feeds the farmer and the walkers of Parting.GROUP and
## clears them on a map change and a new day.
func _footprints() -> void:
	var g: Node = root.get_node("Game")
	var FP: GDScript = load("res://scripts/footprints.gd")
	var PG: GDScript = load("res://scripts/world3d/parting.gd")
	g.new_game()
	check(FileAccess.file_exists("res://data/footprints.json"), "footprints: the numbers are in data/footprints.json")
	var r: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/footprints.json"))
	for k in FP.DEFAULTS:
		check(r.has(k), "footprints: data has %s" % k)
	check(float(r.step) > 0.2 and float(r.side) > 0.0 and float(r.side) < float(r.step) and int(r.cap) >= 40 and int(r.life) >= 30 and float(r.snowing_rate) > 1.0
		and float(r.min_cover) > 0.0 and float(r.min_cover) < 100.0, "footprints: sane numbers")
	var walk := func(fp, id, from: Vector2, to: Vector2, n: int, hold := Callable()) -> void:
		for i in range(n + 1):
			fp.feed({id: from.lerp(to, float(i) / n)}, hold)
	# A straight walk east: pairs left and right of the line, a step apart, along the walk.
	var fp: Object = FP.new(r)
	walk.call(fp, "farmer", Vector2(2, 5), Vector2(12, 5), 200)
	var expected := 10.0 / float(r.step)
	check(fp.prints.size() >= expected - 2 and fp.prints.size() <= expected + 1, "footprints: about one every %.2f cells (%d for 10 cells)" % [float(r.step), fp.prints.size()])
	var ok_dir := true
	var ok_side := true
	var ok_gap := true
	for i in fp.prints.size():
		var p: Dictionary = fp.prints[i]
		ok_dir = ok_dir and p.dir.distance_to(Vector2.RIGHT) < 0.001
		ok_side = ok_side and is_equal_approx(absf(p.pos.y - 5.0), float(r.side)) and (i == 0 or signf(p.pos.y - 5.0) != signf(fp.prints[i - 1].pos.y - 5.0))
		ok_gap = ok_gap and (i == 0 or (p.pos.x - fp.prints[i - 1].pos.x) >= float(r.step) - 0.2 and (p.pos.x - fp.prints[i - 1].pos.x) <= float(r.step) + 0.2)
	check(ok_dir and ok_side and ok_gap, "footprints: turned along the walk, left and right in turn at +-%.2f, spaced by the step" % float(r.side))
	# Standing still, a jump, a walker gone and back.
	var n_before: int = fp.prints.size()
	for i in 30:
		fp.feed({"farmer": Vector2(12, 5)})
	check(fp.prints.size() == n_before, "footprints: none while standing still")
	fp.feed({"farmer": Vector2(40, 5)})
	fp.feed({"farmer": Vector2(40.1, 5)})
	check(fp.prints.size() == n_before, "footprints: a jump (a door) leaves no trail across it")
	fp.feed({})
	fp.feed({"farmer": Vector2(20, 20)})
	check(fp.prints.size() == n_before, "footprints: a walker back on the map starts afresh (no print first)")
	# Two walkers each leave their own.
	var two: Object = FP.new(r)
	for i in 21:
		two.feed({"farmer": Vector2(2 + i * 0.5, 5), 77: Vector2(2 + i * 0.5, 9)})
	check(two.prints.filter(func(p): return absf(p.pos.y - 5.0) < 0.5).size() > 5 and two.prints.filter(func(p): return absf(p.pos.y - 9.0) < 0.5).size() > 5, "footprints: the villagers' and the dog's walkers leave theirs too")
	# Ground that holds little snow leaves none.
	var bare: Object = FP.new(r)
	walk.call(bare, "farmer", Vector2(2, 5), Vector2(12, 5), 50, func(_at): return 0.3)
	check(bare.prints.is_empty(), "footprints: none where the ground holds under min_hold of the snow")
	# The ring: never over cap, the oldest go first.
	var ring: Object = FP.new(r)
	walk.call(ring, "farmer", Vector2(0, 0), Vector2(150, 0), 3000)
	check(ring.prints.size() == int(r.cap), "footprints: a ring of at most %d (%d)" % [int(r.cap), ring.prints.size()])
	check(ring.prints[ring.prints.size() - 1].pos.x > 148.0 and ring.prints[0].pos.x > 150.0 - (int(r.cap) + 1) * float(r.step) * 1.15, "footprints: the oldest are dropped, the newest kept")
	# Fading: age by game minutes, gone after life, quicker while snow falls.
	var old: Object = FP.new(r)
	walk.call(old, "farmer", Vector2(2, 5), Vector2(6, 5), 20)
	var n0: int = old.prints.size()
	check(n0 > 3 and is_equal_approx(old.strength(old.prints[0]), 1.0), "footprints: fresh prints show in full")
	old.age(float(r.life) / 2.0)
	check(is_equal_approx(old.strength(old.prints[0]), 0.5) and old.prints.size() == n0, "footprints: half way through their life they show half")
	old.age(float(r.life) / 2.0)
	check(old.prints.is_empty(), "footprints: gone after %d minutes" % int(r.life))
	var snowy: Object = FP.new(r)
	walk.call(snowy, "farmer", Vector2(2, 5), Vector2(6, 5), 20)
	snowy.age(float(r.life) / float(r.snowing_rate) + 0.01, true)
	check(snowy.prints.is_empty(), "footprints: fresh snowfall fills them in %.1f times as fast" % float(r.snowing_rate))
	walk.call(snowy, "farmer", Vector2(2, 5), Vector2(6, 5), 20)
	snowy.clear()
	check(snowy.prints.is_empty(), "footprints: clear() empties the ring")
	# The threshold and shelter.
	check(not fp.active(float(r.min_cover) - 1.0, false) and fp.active(float(r.min_cover), false) and fp.active(100.0, false), "footprints: only from min_cover percent of snow")
	check(not fp.active(100.0, true), "footprints: none indoors or in the mine (sheltered)")

	# In the world: the farmer and a PG.GROUP walker, snow 80 on the farm.
	var row := -1
	for y in FarmGrid.H:
		var all := true
		for x in range(4, 16):
			all = all and FP.ground_hold(Vector2(x + 0.5, y + 0.5)) >= float(r.min_hold)
		if all:
			row = y
			break
	check(row >= 0, "footprints: the farm has a row of ground that holds snow (row %d)" % row)
	var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	root.add_child(w)
	var walker := Sprite3D.new()
	walker.add_to_group(PG.GROUP)
	w.add_child(walker)
	g.snow_cover = 20
	for i in 40:
		walker.position = Vector3(4.0 + i * 0.3, 0, row + 2.5)
		w.set_farmer(Vector3(4.0 + i * 0.3, 0, row + 0.5))
	check(w.prints == null, "footprints: no layer, no prints while snow lies under the threshold (cover %d)" % g.snow_cover)
	g.snow_cover = 80
	g.weather_today = "sunny"
	for i in 40:
		walker.position = Vector3(4.0 + i * 0.3, 0, row + 2.5)
		w.set_farmer(Vector3(4.0 + i * 0.3, 0, row + 0.5))
	check(w.prints != null and w.prints.count() > 8, "footprints: with snow 80 the world's layer holds the trail (%d)" % (w.prints.count() if w.prints != null else -1))
	if w.prints != null:
		check(w.prints.count() == w.prints.trail.prints.size() and w.prints.count() <= int(r.cap), "footprints: the layer draws exactly the trail, within the cap")
		var rows := {}
		for p in w.prints.trail.prints:
			rows[floori(p.pos.y)] = true
		check(rows.has(row) and rows.has(row + 2), "footprints: the farmer's and the PG.GROUP walker's prints are both there")
		check(w.prints.trail.strength(w.prints.trail.prints[0]) > 0.99, "footprints: a fresh print is drawn in full strength")
		w.age_prints(float(r.life) / 2.0)
		check(w.prints.count() > 0 and is_equal_approx(w.prints.trail.strength(w.prints.trail.prints[0]), 0.5), "footprints: aging dims the world's prints")
		w.clear_prints()
		check(w.prints.count() == 0 and w.prints.trail.prints.is_empty(), "footprints: cleared by clear_prints (map change, new day)")
		for i in 12:
			w.set_farmer(Vector3(4.0 + i * 0.6, 0, row + 0.5))
		check(w.prints.count() > 0, "footprints: and a new trail starts after")
		g.snow_cover = 10
		w.set_farmer(Vector3(10.0, 0, row + 0.5))
		check(w.prints.count() == 0, "footprints: the snow melting below the threshold takes the prints with it")
	w.free()
	g.snow_cover = 0
	# Snow lies in patches: a print appears only where the cover's own noise says snow lies.
	var SL: GDScript = load("res://scripts/world3d/snow_layer.gd")
	g.snow_cover = 80
	var lying := 0
	var total := 0
	for y in range(0, 64):
		for x in range(0, 64):
			total += 1
			if SL.lies(Vector2(x * 0.5 + 0.25, y * 0.5 + 0.25), 0.4):
				lying += 1
	check(absf(float(lying) / total - 0.4 * 0.926) < 0.08, "footprints: at cover 0.4 about that share of the ground has snow lying (%.2f)" % (float(lying) / total))
	check(not SL.lies(Vector2(3.3, 2.1), 0.0) and SL.lies(Vector2(3.3, 2.1), 1.0), "footprints: no snow lies at amount 0, all of it at 1")
	check(SL.noise_at(Vector2(1.3, 2.7)) == SL.noise_at(Vector2(1.3 + 8.0, 2.7 + 16.0)), "footprints: the noise repeats every 8 cells like the shader's texture")
	var with_snow: Object = FP.new(r)
	var any_ground: Object = FP.new(r)
	walk.call(with_snow, "farmer", Vector2(0.5, row + 0.5), Vector2(15.5, row + 0.5), 300, FP.ground_snow)
	walk.call(any_ground, "farmer", Vector2(0.5, row + 0.5), Vector2(15.5, row + 0.5), 300, FP.ground_hold)
	var all_lie := true
	for p in with_snow.prints:
		all_lie = all_lie and SL.lies(p.pos, 0.8 * float(p.hold))
	var bare_ones: Array = any_ground.prints.filter(func(p): return not SL.lies(p.pos, 0.8 * float(p.hold)))
	check(bare_ones.size() > 0, "footprints: the row has bare patches inside the snow (%d prints would be bare)" % bare_ones.size())
	check(all_lie and with_snow.prints.size() > 0 and with_snow.prints.size() == any_ground.prints.size() - bare_ones.size(), "footprints: a trail stops at a bare patch and goes on in the snow (%d of %d)" % [with_snow.prints.size(), any_ground.prints.size()])
	check(FP.ground_snow(Vector2(bare_ones[0].pos)) == 0.0 if bare_ones.size() > 0 else false, "footprints: ground_snow is 0 on a bare patch")
	var lay: Object = load("res://scripts/world3d/footprint_layer.gd").new()
	check("snow_at(world.xz" in lay.SHADER and "COLOR.r" in lay.SHADER, "footprints: the 3D shader tests the same snow noise (snow_at) per pixel")
	lay.free()
	g.snow_cover = 0
	var main_src := FileAccess.get_file_as_string("res://scripts/main_3d.gd")
	var enter := main_src.substr(main_src.find("func _enter_map"), 3200)
	var day := main_src.substr(main_src.find("func _on_day_started"), 300)
	check("world.clear_prints()" in enter and "world.clear_prints()" in day and "age_prints" in main_src, "footprints: Main3D clears them on a map change and a new day and ages them each minute")


## Camera lenses (data/camera.json): ps1 is the measured camera, every lens frames the feet alike.
func _lenses() -> void:
	var cam_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/camera.json"))
	var ps1 := CameraLens.pick(cam_data, "ps1")
	check(absf(ps1.dist - 10087.0 / 400.0) < 0.05, "ps1 lens: the eye 25.2 cells away (%.2f)" % ps1.dist)
	check(ps1.back.distance_to(Vector3(0.634, 0.448, 0.634)) < 0.005, "ps1 lens: yaw 45, pitch 26.6")
	for lid in cam_data.lenses:
		var l := CameraLens.pick(cam_data, lid)
		check(is_equal_approx(l.dist * tan(deg_to_rad(l.fov) / 2.0), float(cam_data.half_height)), "lens %s frames the feet alike" % lid)
	check(CameraLens.pick(cam_data).id == cam_data.use, "no --lens: the lens camera.json uses")


var _frame := 0
var _since_door := -1.0          # seconds since the door (the fade runs on real time)
var _warm_before := 0            # ShaderWarm.shown before the door
var _warm_shadows := {}          # the sun's shadow switch seen while the warm-up quads were up
var _scene: Node
var _entered: Array = []
var _farm_world_ok := false


func _process(delta: float) -> bool:
	_frame += 1
	if _since_door >= 0.0:
		_since_door += delta
	if _scene != null and _scene._warm != null:
		_warm_shadows[_scene.sun.shadow_enabled] = true
	if _frame == 1:
		_homes_3d()
		_minka()
		_shrine()
		_farm_props()
		_room_walls()
		_room_props()
		_stable_props()
		_straw_bedding()
		_trees()
		_outdoor_props()
		_field_props()
		_festival_meshes()
		_stall_wares()
		_bamboo_pieces()
		_grass()
		_crop_clusters()
		_parting()
		_water()
		_water_ice()
		_game_maps()
		_bed_and_doors()
		_clinic_doors()
		_story_props()
		_ferry_boat()
		_dye_cloth()
		_shino_noren()
		_kiku_scion()
		_nana_props()
		_cradle()
		_lane_and_kiln_props()
		_map_snow()
		_footprints()
		_edges_and_fades()
		_backdrop()
		_walk_slide()
		_fade_steps()
		_mesh_cache()
		_occluder_own()
		_kept_lit_and_swaying()
		_shader_warm()
		_hearth_smoke()
		_start_view()
	elif _frame == 3:
		_crops_clock()
		var g: Node = root.get_node("Game")
		_k("shader_warm").clear()   # every kind of the house is new: the fade's black draws them
		_warm_before = _k("shader_warm").shown
		g.use_door(MapManager.data("farm").doors[0])
		check(_scene.fade.busy() and g.paused(), "a door starts the fade and holds the farmer")
		_since_door = 0.0
	elif _since_door > 1.0 or _frame > 2000:
		_check_view()
		print("test_maps: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


## The real 3D view: through the farm house door, the fade runs, the house is built.
func _start_view() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	# The farm's morning events would take the farmer over on entry; this test is about doors.
	g.events_seen = {"first_morning": true, "rainy_day": true}
	g.map_entered.connect(func(id): _entered.append(id))
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)
	check(_entered == ["farm"], "the view says the farmer entered the farm %s" % [_entered])
	# No fade led here (the title, a load): the first map is built and warmed under black too.
	check(_scene.fade.busy() and _scene.fade.holding() and is_equal_approx(_scene.fade.alpha(), 1.0) and not g.paused()
		and _scene._warm != null and _scene._warm.get_child_count() > 5,
		"shader warm: the first map starts under black, its kinds drawn (%d)" % (_scene._warm.get_child_count() if _scene._warm != null else 0))
	_farm_world_ok = _scene.world.surroundings != null and _scene.world.occluders.count() == 4
	var sun_now: Dictionary = g.sun_light()
	check(is_equal_approx(_scene.sun.rotation_degrees.x, -sun_now.elevation) and is_equal_approx(_scene.sun.rotation_degrees.y, sun_now.yaw)
		and _scene.sun.light_color == sun_now.color, "on the farm the sun follows the clock (%s)" % _scene.sun.rotation_degrees)
	check(_scene.world.windows.size() == 4, "the farmhouse lights three windows and its door (%d)" % _scene.world.windows.size())
	var season_was: int = g.season
	var ice_m: ShaderMaterial = _scene.world.surroundings.water.material_override
	check(is_equal_approx(float(ice_m.get_shader_parameter("ice_on")), 0.0), "the 3D view's pond is open in spring")
	g.season = g.SEASONS.find("winter")
	_scene._show_weather()
	check(is_equal_approx(float(ice_m.get_shader_parameter("ice_on")), 1.0), "the 3D view's pond ices at the shore in winter")
	g.season = season_was
	_scene._show_weather()
	check(is_equal_approx(float(ice_m.get_shader_parameter("ice_on")), 0.0), "and thaws out of winter")
	var lights := _scene.find_children("*", "Control", true, false).filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("night_lights.gd"))
	check(lights.size() == 1, "the 3D view draws the lit windows")
	if lights.size() == 1:
		# The glows come after a copy of the picture, and the figures in front are drawn back
		# from that copy, so a window's glow never tints the farmer standing before it.
		var kids: Array = lights[0].get_children()
		var copy_at := kids.find(lights[0].copy)
		check(copy_at >= 0 and lights[0].copy.copy_mode == BackBufferCopy.COPY_MODE_VIEWPORT
			and copy_at < kids.find(lights[0].glows) and kids.find(lights[0].glows) < kids.find(lights[0].figures),
			"night lights: pools, then a copy of the picture, then the glows, then the figures")
		check(lights[0].figures.material is ShaderMaterial and "hint_screen_texture" in lights[0].figures.material.shader.code,
			"the figures are drawn back from the copy (the screen as it was before the glows)")
		# The night lift (the field's, then the figures') comes first, from its own copy of the tinted picture (no pools yet), so it
		# can tell their own pixels from what stands in front of them.
		var fc := kids.find(lights[0].field_copy)
		check(fc >= 0 and fc < kids.find(lights[0].field) and kids.find(lights[0].field) < kids.find(lights[0].pools)
			and kids.find(lights[0].field) < kids.find(lights[0].figure_lift) and kids.find(lights[0].figure_lift) < kids.find(lights[0].pools)
			and kids.find(lights[0].pools) < copy_at and "hint_screen_texture" in lights[0].field.material.shader.code,
			"night lights: the lift's copy, the field's lift, the figures' lift, the pools, then the copy for the walls and glows")
		check(_scene.sprite.is_in_group(lights[0].FIGURES), "the farmer is a figure the glows keep off")
	# The real lamps: a bounded few OmniLight3Ds without shadows, lit at night, all off by day.
	var lamps: Node3D = _scene.lamps
	var lr: Dictionary = g.light_data().lamps
	check(lamps != null and lamps.lights.size() == int(lr.max) and lamps.tint == _scene.tint
		and lamps.lights.all(func(l): return l is OmniLight3D and not l.shadow_enabled and (l.light_cull_mask & lamps.GROUND_LAYER) == 0),
		"the view has %d night lamps, no shadows, leaving the ground out" % int(lr.max))
	if lamps != null:
		var h: int = g.hour
		var mi: int = g.minute
		g.hour = 21
		g.minute = 0
		_scene.tint.color = g.light_color()
		lamps._process(0.0)
		var on: Array = lamps.lights.filter(func(l): return l.visible)
		var want: int = mini(_scene.world.windows.size(), int(lr.max))
		var warm: bool = on.all(func(l): return l.light_energy > 0.0 and l.light_color.r == 1.0 and l.light_color.b < l.light_color.g)
		check(on.size() == want and warm, "at 21:00 the farmhouse's windows light warm lamps (%d of %d)" % [on.size(), want])
		# The farmer in front of a lit farmhouse window takes the night lift in pass 0 (its own
		# copy shown), carrying (1, 1, 1, lift), and is drawn back in pass 4 over the glows.
		var nl: Control = lights[0] if lights.size() == 1 else null
		var fig_at: Vector3 = _scene.sprite.global_position
		var win: Dictionary = _scene.world.windows[0]
		_scene.sprite.global_position = Vector3(win.pos.x, 0.0, win.pos.z) + win.normal * 0.8
		if nl != null:
			nl._process(0.0)
			var mine: Array = nl._warm.filter(func(q): return q.tex == _scene.sprite.texture)
			# Drawn back for its lift alone (not only for standing in front of a glow).
			nl._shields.clear()
			nl._shielded.clear()
			nl._plan_warmth()
			var shield: bool = nl._shields.any(func(q): return q.tex == _scene.sprite.texture)
			check(mine.size() == 1 and mine[0].color.a > 0.01 and is_equal_approx(mine[0].color.r, 1.0)
				and nl.field_copy.visible and nl.figure_lift.visible and shield,
				"night lights: the farmer by a lit window takes the lift in pass 0 and is drawn back (%d quads)" % mine.size())
		g.hour = 12
		_scene.tint.color = g.light_color()
		lamps._process(0.0)
		if nl != null:
			nl._process(0.0)
			check(nl._warm.is_empty() and nl._field_quads.is_empty() and not nl.field_copy.visible,
				"night lights: by day nothing is lifted and the lift's copy is off")
		_scene.sprite.global_position = fig_at
		check(lamps.lights.all(func(l): return not l.visible), "at noon every lamp is off: the daytime picture is untouched")
		g.hour = h
		g.minute = mi
		_scene.tint.color = g.light_color()
		lamps._process(0.0)


## A few frames into the farm: its tall crops sway on their own clock (CropClusters.clock, not the
## shader's TIME), every picture told each frame, so NightLights' field lift can follow the sway.
func _crops_clock() -> void:
	var is_cc := func(n: Node) -> bool: return n.get_script() != null and n.get_script().resource_path.ends_with("crop_clusters.gd")
	var ccs := _scene.find_children("*", "Node3D", true, false).filter(is_cc)
	var ticking := not ccs.is_empty()
	for cc in ccs:
		ticking = ticking and cc.clock > 0.0 and cc.materials().all(func(m): return is_equal_approx(float(m.get_shader_parameter("clock")), cc.clock))
	check(ticking, "the 3D view's tall crops sway on their clock, every picture told (%d)" % ccs.size())


func _check_view() -> void:
	var g: Node = root.get_node("Game")
	check(not _scene.fade.busy() and not g.paused(), "the fade ended and let go of the pause")
	check(_entered == ["farm", "house"], "map_entered after the fade %s" % [_entered])
	check(_scene.world.get_script().resource_path.ends_with("map_world.gd") and _scene.world.map.id == "house", "the view rebuilt as the house")
	check(_farm_world_ok, "the farm has land past its fence and its house, stand, coop and barn can fade")
	check(_scene.player.position == g.maps.pos and _scene.player.facing == Vector2i.UP, "the farmer stands at the house spawn")
	check(_k("shader_warm").shown > _warm_before and _scene._warm == null and _scene.find_children("ShaderWarm", "", true, false).is_empty(),
		"shader warm: the house's kinds drawn in the fade's black (%d) and taken away before it cleared" % (_k("shader_warm").shown - _warm_before))
	check(_warm_shadows.has(true) and _warm_shadows.has(false) and not _scene.sun.shadow_enabled,
		"shader warm: drawn with the sun's shadows on and off (%s), off again in the house" % [_warm_shadows.keys()])
	var plain: Dictionary = g.sun_light(true)
	check(is_equal_approx(_scene.sun.rotation_degrees.x, -plain.elevation) and is_equal_approx(_scene.sun.rotation_degrees.y, plain.yaw)
		and _scene.sun.light_color == plain.color, "in the house the plain fixed sun (%s)" % _scene.sun.rotation_degrees)
	var events: Array = _scene.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("event_player.gd"))
	check(events.size() == 1 and events[0].map_id == "house" and events[0].table.map_id == "house",
		"the event triggers follow the map")
	_kept_worlds(g)
	_prebuilt_worlds(g)
	_scene.free()
	check(not g.paused(), "leaving the view keeps no pause")
	g.new_game()


## Every file parses; doors lead to real maps, onto free cells; every way in has a way back.
func _map_files() -> void:
	var ids := MapManager.ids()
	for want in ["farm", "house", "town"]:
		check(want in ids, "map %s has a file" % want)
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var farm := FarmGrid.new(crops)
	farm.generate(RandomNumberGenerator.new())
	for id in ids:
		var r := MapManager.load_map(id)
		check(r[0] == "", "map %s loads (%s)" % [id, r[0]])
		if r[0] != "":
			continue
		var m: MapData = r[1]
		var solid := func(c: Vector2i) -> bool: return farm.is_solid(c) if m.farm else m.is_solid(c)
		for key in m.spawns:
			check(not solid.call(m.spawns[key][0]), "%s spawn %s is free" % [id, key])
		for door in m.doors:
			for c in door.cells:
				check(solid.call(c), "%s door %s is a solid cell (walked into, not over)" % [id, c])
			if door.to == "":
				continue
			var to := MapManager.data(door.to)
			check(to != null, "%s door leads to a known map (%s)" % [id, door.to])
			if to == null:
				continue
			var spawn: Vector2i = door.spawn
			check(to.in_bounds(spawn) and to.door_at(spawn).is_empty(), "%s -> %s spawn on the map, not on a door" % [id, door.to])
			if not to.farm:
				check(not to.is_solid(spawn), "%s -> %s spawn is free" % [id, door.to])
			var back := false
			for d in to.doors:
				back = back or d.to == id
			check(back, "%s -> %s has a way back" % [id, door.to])
	var fm := MapManager.data("farm")
	check(fm.farm and fm.w == FarmGrid.W and fm.h == FarmGrid.H, "farm map is the FarmGrid's size")
	check(farm.fixed_at(fm.doors[0].cells[0]) == "door", "the farm's house door is FarmGrid's door cell")
	for c in fm.gate_cells():
		check(farm.fixed_at(c) == "fence", "the gate %s is a fence cell left open" % c)
	check(MapManager.data("house").indoor and not MapManager.data("town").indoor and not fm.indoor, "only the house is indoors")
	check(MapManager.data("house").spawns.has("home"), "the house has a home spawn")
	# Broken data is refused.
	for bad in [null, {}, {"id": "x", "size": [2, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["ab"], "spawns": {"start": [[0, 0], "up"]}},
			{"id": "x", "size": [1, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["a"], "spawns": {}},
			{"id": "x", "size": [1, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["a"], "spawns": {"start": [[0, 0], "up"]},
				"doors": [{"cells": [[0, 1]], "to": "farm"}]},
			{"id": "x", "size": [1, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["a"], "spawns": {"start": [[0, 0], "up"]},
				"props": [{"kind": "pine", "cell": [1, 0]}]}]:
		check(MapData.parse(bad)[0] != "", "refused broken map %s" % str(bad).left(60))


## Cells, props and doors on the house and the village.
func _map_rules() -> void:
	var h := MapManager.data("house")
	check(h.is_solid(Vector2i(0, 0)) and h.is_solid(Vector2i(-1, 3)) and h.is_solid(Vector2i(8, 3)), "walls and off the map are solid")
	check(not h.is_solid(Vector2i(3, 3)) and h.tile(Vector2i(3, 3)) == "tatami", "tatami is walkable")
	check(h.is_solid(Vector2i(1, 2)) and h.prop_at(Vector2i(1, 2)).get("use", "") == "sleep", "the futon is solid and sleeps")
	check(h.door_at(Vector2i(4, 6)).to == "farm", "the house door goes to the farm")
	check(h.step(Vector2i(3, 3)) == "floor" and h.step(Vector2i(3, 5)) == "soil", "footsteps by floor")
	var t := MapManager.data("town")
	check(t.door_at(Vector2i(-1, 10)).to == "farm", "walking off the west edge goes to the farm")
	_homes(t)
	check(t.is_solid(Vector2i(17, 6)) and t.is_solid(Vector2i(20, 6)) and not t.is_solid(Vector2i(18, 6)), "torii posts block, the path through it doesn't")
	check(t.is_solid(Vector2i(32, 15)), "the pond is solid")
	check(MapView.ground_key(t, Vector2i(31, 14)) == "ground:water:%d" % (PlaceholderArt.WATER_N | PlaceholderArt.WATER_W), "pond banks")
	# The river: down the lane off the village's south edge and back; water across the map with
	# banks only at the shores (none at the map's side edges, it flows on), rocks in the current.
	var rv := MapManager.data("river")
	var mn := MapManager.data("minamino")
	check(t.door_at(Vector2i(4, 22)).get("to", "") == "minamino" and mn.door_at(Vector2i(4, -1)).get("to", "") == "town"
		and mn.door_at(Vector2i(4, 20)).get("to", "") == "river" and rv.door_at(Vector2i(4, -1)).get("to", "") == "minamino",
		"the village lane, Minamino and the river path join up")
	check(not t.is_solid(Vector2i(4, 21)) and t.tile(Vector2i(4, 21)) == "path", "the lane runs to the village's south edge")
	# The bamboo hill up the village's north lane: doors both ways, the clumps solid, the path
	# open from the foot to the lookout, the cliff along the top.
	var hl := MapManager.data("hill")
	var kn := MapManager.data("kaminoda")
	check(t.door_at(Vector2i(10, -1)).get("to", "") == "kaminoda" and kn.door_at(Vector2i(10, 20)).get("to", "") == "town"
		and kn.door_at(Vector2i(10, 20)).spawn == t.spawns.north[0], "the village's north lane and Kaminoda join up")
	check(kn.door_at(Vector2i(22, -1)).get("to", "") == "hill" and hl.door_at(Vector2i(19, 30)).get("to", "") == "kaminoda"
		and hl.door_at(Vector2i(19, 30)).spawn == kn.spawns.hill[0], "Kaminoda's lane north and the hill path join up")
	var clumps := hl.props.filter(func(p): return p.kind == "bamboo")
	check(clumps.size() > 50 and clumps.all(func(p): return hl.is_solid(Vector2i(p.cell)) and hl.tile(Vector2i(p.cell)) == "grass"), "bamboo clumps stand solid on grass")
	var seen := {hl.spawns.start[0]: true}
	var todo: Array = [hl.spawns.start[0]]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for o in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + o
			if hl.in_bounds(n) and not seen.has(n) and not hl.is_solid(n):
				seen[n] = true
				todo.append(n)
	check(seen.has(hl.spawns.top[0]), "the lookout can be walked to from the foot")
	check(hl.is_solid(Vector2i(5, 0)) and hl.tile(Vector2i(5, 0)) == "rock_wall", "the cliff along the top")
	# Maples (momiji): a few on the hill, one each in Kaminoda and Sakurazaka, all on open grass
	# clear of the paths, the bamboo and every other prop.
	for spot in [["hill", 3], ["kaminoda", 1], ["sakurazaka", 1]]:
		var mm := MapManager.data(spot[0])
		var maples := mm.props.filter(func(p): return p.kind == "maple")
		check(maples.size() >= spot[1], "%s has %d maples at least" % [spot[0], spot[1]])
		for mp in maples:
			var mc := Vector2i(mp.cell)
			var crowded := mm.props.filter(func(p): return p != mp and Rect2i(Vector2i(p.cell), Vector2i(p.get("size", [1, 1]))).has_point(mc))
			check(mm.tile(mc) == "grass" and crowded.is_empty(), "%s: the maple at %s stands on free grass" % [spot[0], mc])
	# The village's outer parts: every door of each can be walked to from its way in, and every
	# house door leads to a room whose way out comes back in front of it.
	for id in ["kaminoda", "sakurazaka", "minamino"]:
		var m := MapManager.data(id)
		var reach := _walkable(m, m.spawns.start[0])
		for door in m.doors:
			var near: bool = door.cells.any(func(c: Vector2i):
				return [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].any(func(o): return reach.has(c + o)))
			check(near, "%s: the door to %s can be walked to" % [id, door.to])
			var room := MapManager.data(door.to)
			if room.indoor:
				var out: Dictionary = room.doors[0]
				check(out.to == id and reach.has(out.spawn) and room.door_at(room.spawns.start[0] + Vector2i.DOWN) == out,
					"%s: %s's door comes back out in front of it" % [id, door.to])
	check(rv.tile(Vector2i(0, 7)) == "water" and rv.is_solid(Vector2i(10, 7)) and not rv.is_solid(rv.spawns.shore[0]), "the river is solid, the shore is not")
	check(MapView.ground_key(rv, Vector2i(0, 6)) == "ground:water:%d" % PlaceholderArt.WATER_N, "no bank at the map's edge, one at the shore")
	check(MapView.ground_key(rv, Vector2i(19, 9)) == "ground:water:%d" % PlaceholderArt.WATER_S, "the far shore's bank")
	check(rv.props.filter(func(p): return p.kind == "river_rock").all(func(p): return rv.tile(p.cell) == "water"), "the rocks stand in the water")
	# Ambient by place.
	var rules: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json")).ambient.rules
	var outside := AmbientPicker.pick(rules, "rain", "summer", 12, "outdoor")
	var inside := AmbientPicker.pick(rules, "rain", "summer", 12, "indoor")
	check(inside.get("amb_rain", 0.0) > 0.0 and inside.amb_rain < outside.get("amb_rain", 0.0), "rain is muffled indoors")
	check(AmbientPicker.pick(rules, "sunny", "summer", 12, "indoor").is_empty(), "no cicadas indoors")
	check(AmbientPicker.pick(rules, "sunny", "summer", 12) == AmbientPicker.pick(rules, "sunny", "summer", 12, "outdoor"), "outdoor is the default place")


## The villagers' homes: doors from the village with hours, the way back out, the furniture.
func _homes(t: MapData) -> void:
	var want := {Vector2i(5, 6): "tome_house", Vector2i(8, 15): "kota_house", Vector2i(25, 15): "sayo_house"}
	for c in want:
		var d := t.door_at(c)
		check(d.get("to", "") == want[c] and d.has("hours") and d.closed != "", "the village door %s leads to %s, with hours" % [c, want[c]])
		var m := MapManager.data(want[c])
		check(m != null and m.indoor and m.door_at(m.doors[0].cells[0]).to == "town" and m.doors[0].spawn == c + Vector2i.DOWN,
			"%s is indoors and its door comes out in front of the village door" % want[c])
		check(m != null and m.spawns.has("home") and not m.is_solid(m.spawns.home[0]), "%s has a free home spot" % want[c])
	var door := t.door_at(Vector2i(5, 6))
	check(MapData.door_open(door, 7 * 60) and MapData.door_open(door, 6 * 60) and not MapData.door_open(door, 19 * 60)
		and not MapData.door_open(door, 25 * 60) and MapData.door_open({}, 25 * 60), "a home is open 6:00-19:00, a door without hours always")
	check(t.door_at(Vector2i(23, 15)).to == "store" and not t.door_at(Vector2i(23, 15)).has("hours"), "the store's own door keeps its shop hours")
	var store_house: Dictionary = t.prop_at(Vector2i(23, 14))
	check(store_house.get("side_door", -1) == 4 and store_house.cell.x + 4 == 25, "the store house draws Sayo's side door over its door cell")
	# Every prop kind on every map has a look in the flat view, and the homes build in 3D
	# without the magenta stand-in box.
	for id in MapManager.ids():
		var m := MapManager.data(id)
		for p in m.props:
			check(MapView.COLORS.has(p.kind), "map %s prop %s has a flat colour" % [id, p.kind])
	for id in ["tome_house", "kota_house", "sayo_house"]:
		var kinds := MapManager.data(id).props.map(func(p): return p.kind)
		for k in (["irori", "tokonoma", "zabuton", "andon"] if id != "sayo_house" else ["tokonoma", "low_table", "zabuton", "byobu"]):
			check(k in kinds, "%s has a %s" % [id, k])
	for bad in [["06:00"], ["20:00", "06:00"], ["6", "20:00"]]:
		check(MapData.parse({"id": "x", "size": [2, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["aa"], "spawns": {"start": [[0, 0], "up"]},
			"doors": [{"cells": [[1, 0]], "to": "town", "spawn": [5, 7], "facing": "down", "hours": bad, "closed": "Shut."}]})[0] != "",
			"refused door hours %s" % [bad])
	check(MapData.parse({"id": "x", "size": [2, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["aa"], "spawns": {"start": [[0, 0], "up"]},
		"doors": [{"cells": [[1, 0]], "to": "town", "spawn": [5, 7], "facing": "down", "hours": ["06:00", "20:00"]}]})[0] != "",
		"door hours without a closed message are refused")


## The land past an outdoor map's edge (Surroundings) and buildings fading while in the
## farmer's way (Occluders), in the 3D view.
func _edges_and_fades() -> void:
	# Loaded, not named: these scripts reach the Game autoload, which a --script test only has at run time.
	var Surroundings: GDScript = load("res://scripts/world3d/surroundings.gd")
	var Occluders: GDScript = load("res://scripts/world3d/occluders.gd")
	var town := MapManager.data("town")
	var world: Node3D = load("res://scripts/world3d/map_world.gd").new()
	root.add_child(world)
	world.build(town)
	check(world.surroundings != null and world.surroundings.material != null, "the village has land past its edge")
	var kind := func(c: Vector2i) -> String: return town.tile(c)
	# The road off the village's west edge (0, 10) runs on; grass stays grass.
	check(Surroundings.ground_key(kind, town.w, town.h, Vector2i(-5, 10)).begins_with("ground:path:"),
		"the west road runs on past the edge")
	check(Surroundings.ground_key(kind, town.w, town.h, Vector2i(3, -4)).begins_with("ground:grass:"), "grass past the north edge")
	check(Surroundings.edge_cell(Vector2i(-3, 40), town.w, town.h) == Vector2i(0, town.h - 1), "an apron cell takes the nearest edge cell")
	# Pines only off the map, behind it on screen, never on the road or the near (south / east) sides.
	var pines := 0
	var margin: int = Surroundings.MARGIN
	var wrong := []
	for y in range(-margin, town.h + margin):
		for x in range(-margin, town.w + margin):
			var c := Vector2i(x, y)
			if not Surroundings.pine_at(kind, town.w, town.h, c):
				continue
			pines += 1
			if town.in_bounds(c) or (c.y >= 0 and c.x >= 0) and c.x - c.y <= town.w + 1 and c.x - c.y >= -town.h - 1 					or (c.x < 0 and absi(c.y - 10) <= 1):
				wrong.append(c)
	check(pines > 50 and wrong.is_empty(), "a wood behind the village (%d pines), none in the way %s" % [pines, wrong.slice(0, 5)])
	check(Surroundings.behind_map(Vector2(5.5, -0.5), town.w, town.h) and Surroundings.behind_map(Vector2(-0.5, 6.5), town.w, town.h)
		and not Surroundings.behind_map(Vector2(5.5, town.h + 0.5), town.w, town.h)
		and not Surroundings.behind_map(Vector2(town.w + 0.5, 6.5), town.w, town.h), "behind the map: north and west yes, south and east no")
	# Each village house is one thing that fades: behind it the farmer sees through it, in front not.
	var house: Dictionary = {}
	for p in town.props:
		if p.kind == "village_house":
			house = p
			break
	var occ: RefCounted = world.occluders
	var back := Vector3(0.634, 0.448, 0.634).normalized()
	var mid := Vector3(house.cell.x + house.size.x / 2.0, 0, 0)
	var behind := mid + Vector3(0, 0, house.cell.y - 0.5)
	var front := mid + Vector3(0, 0, house.cell.y + house.size.y + 1.5)
	var it := -1   # the house's own group
	for i in occ.count():
		var c: Vector3 = occ.box_of(i).get_center()
		if Rect2(Vector2(house.cell), Vector2(house.size)).has_point(Vector2(c.x, c.z)):
			it = i
	check(occ.count() >= 5 and it >= 0, "the village's houses and trees can fade (%d)" % occ.count())
	occ.update(behind, back, 1.0)
	check(it >= 0 and occ.fade_of(it) == Occluders.FADED, "behind a house it fades")
	occ.update(front, back, 1.0)
	check(it >= 0 and occ.fade_of(it) == 0.0, "in front of it the house is solid again")
	check(not Occluders.hides(AABB(Vector3(0, 0, 0), Vector3(4, 2.5, 3)), Vector3(2, 0, 5), back),
		"a house behind the farmer never fades")
	check(Occluders.hides(AABB(Vector3(0, 0, 0), Vector3(4, 2.5, 3)), Vector3(2, 0, -0.5), back),
		"a house in front of the farmer fades")
	_lit_windows(world, occ)
	world.free()
	var room: Node3D = load("res://scripts/world3d/map_world.gd").new()
	root.add_child(room)
	room.build(MapManager.data("house"))
	check(room.surroundings == null, "no land past a room's walls")
	room.free()


## Lit windows at night (NightLights): the village's houses list theirs (shops' doors under a
## noren stay dark), each faces the camera side and is seen from the eye unless a solid
## building stands between; a faded one lets the light through as much as it is faded.
func _lit_windows(world: Node3D, occ: RefCounted) -> void:
	var NightLights: GDScript = load("res://scripts/world3d/night_lights.gd")
	var houses := MapManager.data("town").props.filter(func(p): return p.kind == "village_house")
	var shops := houses.filter(func(p): return p.get("noren", false))
	check(world.windows.size() >= houses.size() * 2 and world.is_in_group(NightLights.GROUP),
		"the village's %d houses have lit windows (%d)" % [houses.size(), world.windows.size()])
	var facing: bool = world.windows.all(func(w): return w.normal == Vector3(0, 0, 1) or w.normal.is_equal_approx(Vector3(1, 0, 0)))
	check(facing, "every lit window faces +z or +x (the camera side)")
	var doors: Array = world.windows.filter(func(w): return w.key == "build:shoji_door")
	check(doors.size() >= houses.size() - shops.size(), "homes' doors light up, shops' doors under a noren not (%d doors)" % doors.size())
	# The layout is LitSpots', shared with the flat view's NightView.
	var spots: Dictionary = LitSpots.of_map(MapManager.data("town").props)
	var same: bool = spots.windows.size() == world.windows.size() and spots.lamps.size() == world.lamps.size()
	for i in mini(spots.windows.size(), world.windows.size()):
		var a: Dictionary = spots.windows[i]
		var b: Dictionary = world.windows[i]
		same = same and a.key == b.key and a.pos.is_equal_approx(b.pos) and a.size == b.size and a.normal.is_equal_approx(b.normal)
	for i in mini(spots.lamps.size(), world.lamps.size()):
		same = same and spots.lamps[i].pos.is_equal_approx(world.lamps[i].pos)
	check(same, "the village's lit windows and lanterns are the LitSpots layout (%d / %d)" % [world.windows.size(), world.lamps.size()])
	var eye := Vector3(0.634, 0.448, 0.634).normalized() * 25.0
	var seen := 0
	for w in world.windows:
		var cam_at: Vector3 = w.pos + eye
		var k: float = NightLights.how_seen(w, cam_at, occ)
		check(k >= 0.0 and k <= 1.0, "how_seen is 0..1")
		if k == 1.0:
			seen += 1
	check(seen >= world.windows.size() / 2, "most windows are in plain view of the eye (%d of %d)" % [seen, world.windows.size()])
	var win: Dictionary = world.windows[0]
	var away := {"key": win.key, "pos": win.pos, "size": win.size, "normal": -win.normal}
	check(NightLights.how_seen(away, win.pos + eye, occ) == 0.0, "a window turned from the eye stays dark")
	# A solid box between the window and the eye hides it; faded, it lets the light through.
	var Occluders: GDScript = load("res://scripts/world3d/occluders.gd")
	var lone := {"key": "build:shoji", "pos": Vector3(0, 1, 0), "size": Vector2(0.7, 0.5), "normal": Vector3(0, 0, 1)}
	var blocker: RefCounted = Occluders.new()
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2, 3, 1)
	box.mesh = mesh
	box.position = Vector3(0, 1.5, 3)
	box.material_override = StandardMaterial3D.new()
	blocker.add([box])
	check(NightLights.how_seen(lone, Vector3(0, 1, 20), blocker) == 0.0, "a solid house in front hides a window")
	blocker.update(Vector3(0, 0, 2), Vector3(0, 0, 1), 10.0)   # the farmer behind it: it fades
	var through: float = NightLights.how_seen(lone, Vector3(0, 1, 20), blocker)
	check(is_equal_approx(through, Occluders.FADED), "a faded house lets the window's light through (%.2f)" % through)
	check(NightLights.how_seen(lone, Vector3(20, 1, 20), blocker) == 1.0, "seen past the house's side")
	var c: Array = NightLights.corners(lone)
	check(c[0].distance_to(Vector3(-0.35, 1.25, 0)) < 0.001 and c[2].distance_to(Vector3(0.35, 0.75, 0)) < 0.001, "corners: top left to bottom right")
	box.free()
	var room: Node3D = load("res://scripts/world3d/map_world.gd").new()
	room.build(MapManager.data("house"))
	check(room.windows.is_empty() and room.lamps.is_empty(), "no lit windows inside the farmhouse (its own lamp light)")
	room.free()
	_light_pools(world, occ)
	_glow_off_figures()


## Warm pools on the ground at night (NightLights.pools_of, data/light.json "pools"): one for
## every lit window and stone lantern, none by day, as bright as the windows glow at the hour.
func _light_pools(world: Node3D, occ: RefCounted) -> void:
	var NightLights: GDScript = load("res://scripts/world3d/night_lights.gd")
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var light: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
	var pr: Dictionary = light.pools
	var lanterns := MapManager.data("town").props.filter(func(p): return p.kind == "stone_lantern")
	check(lanterns.size() > 0 and world.lamps.size() == lanterns.size() and world.is_in_group(NightLights.GROUP),
		"the village's %d stone lanterns burn at night (%d)" % [lanterns.size(), world.lamps.size()])
	var full: Array = NightLights.pools_of(world, 1.0, pr)
	check(full.size() == world.windows.size() + world.lamps.size(), "a pool for every lit window and lantern (%d)" % full.size())
	check(full.all(func(p): return p.strength > 0.0 and absf(p.center.y) < 0.05), "every pool lies on the ground, lit")
	check(NightLights.pools_of(world, 0.0, pr).is_empty(), "no pools while the windows are dark")
	# A window's pool lies in front of its wall, against it; a lantern's round its foot.
	var win: Dictionary = world.windows[0]
	var wp: Dictionary = full[0]
	var near: float = (wp.center - wp.out - Vector3(win.pos.x, 0.02, win.pos.z)).length()
	check(wp.out.dot(win.normal) > 0.0 and near < 0.01, "a window's pool starts at its wall and lies out in front")
	var lp: Dictionary = full[world.windows.size()]
	var foot: Vector3 = world.lamps[0].pos
	check(Vector2(lp.center.x - foot.x, lp.center.z - foot.z).length() < 0.01 and is_equal_approx(lp.across.length(), lp.out.length()),
		"a lantern's pool is a circle round its foot")
	var c: Array = NightLights.pool_corners(wp)
	check(c.size() == 4 and c.all(func(v): return absf(v.y - 0.02) < 0.001), "a pool's corners lie on the ground")
	# They follow the windows' schedule: the same dusk / dawn rise and lit hours.
	var rules: Dictionary = light.windows
	var base: Array = full.map(func(p): return p.strength)
	for m in [12 * 60, 17 * 60, 18 * 60 + 30, 19 * 60, 21 * 60, 23 * 60 + 50, 60, 2 * 60, 5 * 60 + 30, 6 * 60 + 40]:
		var glow: float = game_script.window_glow(game_script.sky_at(m, light.sky), m, rules)
		var ps: Array = NightLights.pools_of(world, glow, pr)
		var same := ps.size() == (0 if glow <= 0.0 else base.size())
		for i in ps.size():
			same = same and is_equal_approx(ps[i].strength, base[i] * glow)
		check(same, "the pools at %02d:%02d follow the windows' glow (%.2f)" % [m / 60, m % 60, glow])
	check(game_script.window_glow(game_script.sky_at(720, light.sky), 720, rules) == 0.0
		and game_script.window_glow(game_script.sky_at(1260, light.sky), 1260, rules) == 1.0
		and game_script.window_glow(game_script.sky_at(120, light.sky), 120, rules) == 0.0,
		"pools: off at noon and at 2:00, full at 21:00")
	# A pool behind a solid building is not drawn; its own house never hides it.
	var eye := Vector3(0.634, 0.448, 0.634).normalized() * 25.0
	var seen := 0
	for p in full:
		var k: float = NightLights.ground_seen(p.center, p.own, p.center + eye, occ)
		if k == 1.0:
			seen += 1
	check(seen >= full.size() / 2, "most pools are in plain view of the eye (%d of %d)" % [seen, full.size()])
	var Occluders: GDScript = load("res://scripts/world3d/occluders.gd")
	var blocker: RefCounted = Occluders.new()
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2, 3, 1)
	box.mesh = mesh
	box.position = Vector3(0, 1.5, 3)
	box.material_override = StandardMaterial3D.new()
	blocker.add([box])
	check(NightLights.ground_seen(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(0, 1, 20), blocker) == 0.0, "a house in front hides a pool")
	check(NightLights.ground_seen(Vector3(0, 0, 1), Vector3(0, 1, 3), Vector3(0, 1, 20), blocker) == 1.0, "the house that casts a pool never hides it")
	box.free()
	_wall_wash(world)
	_finish_wash(world)
	_lamp_wash(world)
	_night_lamps(world)


## The warm wash on the pale walls round the lit windows (NightLights.wall_wash, data/light.json
## "pools" → "wall"), drawn over the tint since the tint caps the real lamps on white plaster:
## pieces on the window's wall plane round (not over) the pane, from the ground to over the
## window, `reach` either side, the falloff's middle at the window; as bright as the windows
## glow; a door brighter; kept to pale pixels by its shader, in its own pass between the copy
## and the glows.
func _wall_wash(world: Node3D) -> void:
	var NightLights: GDScript = load("res://scripts/world3d/night_lights.gd")
	var light: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
	var wr: Dictionary = light.pools.get("wall", {})
	check(not wr.is_empty() and float(wr.get("strength", 0)) > 0.0 and float(wr.reach) > 0.0
		and float(wr.pale_from) < float(wr.pale_full), "data/light.json pools.wall: a strength, a reach, pale_from under pale_full")
	var reach := float(wr.get("reach", 1.0))
	var on_plane := true
	var no_pane := true
	var spans := true
	var centred := true
	var lit := true
	for win in world.windows:
		var wash: Dictionary = NightLights.wall_wash(win, 1.0, wr)
		lit = lit and wash.strength > 0.0 and wash.pieces.size() >= 3
		var right: Vector3 = Vector3.UP.cross(win.normal).normalized()
		var half: Vector2 = win.size / 2.0
		var lo := INF
		var hi := -INF
		var top := -INF
		var foot := INF
		for piece in wash.pieces:
			var cs: Array = piece.corners
			var bb := Rect2()
			for i in 4:
				var d: Vector3 = cs[i] - win.pos
				on_plane = on_plane and absf(d.dot(win.normal)) < 0.0001
				var x := d.dot(right)
				lo = minf(lo, x)
				hi = maxf(hi, x)
				top = maxf(top, cs[i].y)
				foot = minf(foot, cs[i].y)
				var p := Vector2(x, cs[i].y)
				bb = Rect2(p, Vector2.ZERO) if i == 0 else bb.expand(p)
				# The uv is the point's offset from the window's middle in reaches (y down).
				centred = centred and piece.uvs[i].is_equal_approx(Vector2(x, win.pos.y - cs[i].y) / reach)
			var pane := Rect2(-half.x, win.pos.y - half.y, win.size.x, win.size.y)
			no_pane = no_pane and bb.intersection(pane).get_area() < 0.0001
		spans = spans and is_equal_approx(lo, -reach) and is_equal_approx(hi, reach) and foot <= 0.0 \
			and top > win.pos.y + half.y
	check(lit, "every lit window washes its wall (in three or four pieces)")
	check(on_plane, "the wash lies on the window's wall plane")
	check(no_pane, "the wash keeps off the pane itself")
	check(spans, "the wash runs `reach` either side, from the ground to over the window")
	check(centred, "the wash's falloff is centred on the window")
	var win: Dictionary = world.windows[0]
	var full: float = NightLights.wall_wash(win, 1.0, wr).strength
	check(NightLights.wall_wash(win, 0.0, wr).strength == 0.0 and is_equal_approx(NightLights.wall_wash(win, 0.5, wr).strength, full * 0.5),
		"the wash follows the windows' glow (none by day)")
	var small := {"key": "build:shoji", "pos": Vector3(0, 1, 0), "size": Vector2(0.7, 0.5), "normal": Vector3(0, 0, 1)}
	var door := {"key": "build:shoji_door", "pos": Vector3(0, 0.55, 0), "size": Vector2(0.8, 1.1), "normal": Vector3(0, 0, 1)}
	check(NightLights.wall_wash(door, 1.0, wr).strength > NightLights.wall_wash(small, 1.0, wr).strength, "a door washes its wall brighter than a window")
	check(NightLights.wall_wash(door, 1.0, wr).pieces.size() == 3, "a door down to the ground: no piece under it")
	# Its pass: after the copy, before the glows, its shader keeping it to the pale pixels.
	var nl: Control = NightLights.new()
	root.add_child(nl)
	var order: bool = nl.copy.get_index() < nl.washes.get_index() and nl.washes.get_index() < nl.glows.get_index() \
		and nl.glows.get_index() < nl.figures.get_index()
	check(order, "the wash is drawn after the copy and before the glows and the figures")
	var code: String = (nl.washes.material as ShaderMaterial).shader.code
	check("hint_screen_texture" in code and "blend_add" in code and "pale" in code and "tint" in code,
		"the wash's shader adds light only where the copy is pale for the tint")
	# The pale mask splits the walls: white plaster's picture over pale_full, the dark boards'
	# under pale_from (the night sun and sky light keep a lit face near its picture).
	var blue := func(key: String) -> float:
		var img: Image = PlaceholderArt.tex(key).get_image()
		var sum := 0.0
		for y in img.get_height():
			for x in img.get_width():
				sum += img.get_pixel(x, y).b
		return sum / (img.get_width() * img.get_height())
	var plaster: float = blue.call("build:plaster")
	var board: float = blue.call("build:board")
	check(plaster > float(wr.pale_full) and board < float(wr.pale_from),
		"plaster (%.2f) takes the wash, dark boards (%.2f) do not" % [plaster, board])
	nl.free()


## The stone lanterns' wash on the house walls they stand in front of (NightLights.lamp_walls /
## lamp_wash / lamp_washes, data/light.json "pools" → "wall" → "lamp"): smaller and weaker than a
## window's, of the wall's own material, fading with the distance to nothing at `out`, on the
## wall plane within its ends (and the finish's bands, off the posts), round the panes, never
## behind the wall, through another building or by day.
func _lamp_wash(world: Node3D) -> void:
	var NightLights: GDScript = load("res://scripts/world3d/night_lights.gd")
	var light: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
	var wr: Dictionary = light.pools.wall
	var lr: Dictionary = wr.get("lamp", {})
	check(not lr.is_empty() and float(lr.share) > 0.0 and float(lr.share) < 1.0 and float(lr.reach) > 0.0
		and float(lr.reach) < float(wr.reach) and float(lr.out) > 0.0,
		"data/light.json pools.wall.lamp: a share under 1, a reach under the window's, an out")
	var reach := float(lr.reach)
	# The walls: every window's pane on exactly one, every village window with its wall's ends.
	var walls: Array = NightLights.lamp_walls(world.windows)
	var panes := 0
	for wall in walls:
		panes += wall.panes.size()
	check(walls.size() > 0 and walls.size() < world.windows.size() and panes == world.windows.size()
		and world.windows.all(func(w): return w.has("span")),
		"the lit windows stand on %d walls (%d panes), each knowing its ends" % [walls.size(), panes])
	var washes: Array = NightLights.lamp_washes(world.windows, world.lamps, 1.0, wr, world.occluders)
	var kinds := {}
	for lw in washes:
		kinds[lw.finish] = int(kinds.get(lw.finish, 0)) + 1
	check(kinds.get("", 0) >= 1 and kinds.get("earth", 0) >= 1,
		"the lanterns by the clinic's plaster and Tome's earthen wall wash them (%s)" % [kinds])
	# The shrine's lanterns stand in no wall's light.
	var far: Array = world.lamps.filter(func(l): return l.pos.z < 5.0)
	check(far.size() == 2 and NightLights.lamp_washes(world.windows, far, 1.0, wr, world.occluders).is_empty(),
		"the shrine's lanterns, far from any wall, wash none")
	var on_wall := true
	var within := true
	var bands_ok := true
	var no_pane := true
	var weaker := true
	var centred := true
	for l in world.lamps:
		for wall in walls:
			var lw: Dictionary = NightLights.lamp_wash(l, wall, 1.0, wr)
			if lw.strength <= 0.0:
				continue
			var ca: float = l.pos.dot(wall.right)
			var base := float(wr.strength) if wall.finish == "" else float(wr.finishes[wall.finish].strength)
			# A window's wash of the material is `base` at the least (a door's more).
			weaker = weaker and lw.strength <= base * float(lr.share) + 0.0001 and lw.strength < base
			for piece in lw.pieces:
				var bb := Rect2()
				for i in 4:
					var c: Vector3 = piece.corners[i]
					on_wall = on_wall and absf(c.dot(wall.normal) - wall.plane) < 0.0001
					var p := Vector2(c.dot(wall.right), c.y)
					bb = Rect2(p, Vector2.ZERO) if i == 0 else bb.expand(p)
					within = within and p.x >= wall.span.x - 0.0001 and p.x <= wall.span.y + 0.0001 and p.y >= -0.0001 \
						and absf(p.x - ca) <= reach + 0.0001 and absf(p.y - l.pos.y) <= reach + 0.0001
					centred = centred and piece.uvs[i].is_equal_approx(Vector2(p.x - ca, l.pos.y - p.y) / reach)
				if wall.finish != "":
					bands_ok = bands_ok and wall.bands.any(func(b: Vector2): return bb.position.y >= b.x - 0.0001 and bb.end.y <= b.y + 0.0001)
					for post: Vector2 in wall.posts:
						bands_ok = bands_ok and (bb.end.x <= post.x + 0.0001 or bb.position.x >= post.y - 0.0001)
				for pane: Array in wall.panes:
					no_pane = no_pane and bb.intersection(Rect2(pane[0], pane[2], pane[1] - pane[0], pane[3] - pane[2])).get_area() < 0.0001
	check(on_wall, "a lantern's wash lies on its wall's plane")
	check(within, "it keeps within the wall's ends, above the ground, `reach` round the fire box")
	check(centred, "its falloff is centred on the point of the wall square to the fire box")
	check(bands_ok, "on earthen and board walls it keeps to the finish's heights and off the posts")
	check(no_pane, "it keeps off the panes")
	check(weaker, "a lantern washes its wall more faintly than a window would")
	# A plain test wall: the falloff with distance, behind it, by day, a building between.
	var wall: Dictionary = {"normal": Vector3(0, 0, 1), "right": Vector3(1, 0, 0), "plane": 2.0, "span": Vector2(-3, 3),
		"finish": "", "bands": [Vector2(-INF, INF)], "posts": [], "panes": [[0.5, 1.2, 0.8, 1.3]]}
	var at := func(d: float) -> Dictionary: return {"pos": Vector3(0, 0.86, 2.0 + d)}
	var near: float = NightLights.lamp_wash(at.call(0.3), wall, 1.0, wr).strength
	var mid: float = NightLights.lamp_wash(at.call(0.9), wall, 1.0, wr).strength
	check(near > mid and mid > 0.0 and is_equal_approx(near, float(wr.strength) * float(lr.share) * (1.0 - 0.3 / float(lr.out))),
		"the wash fades with the lantern's distance from the wall (%.3f near, %.3f further)" % [near, mid])
	check(NightLights.lamp_wash(at.call(float(lr.out) + 0.01), wall, 1.0, wr).pieces.is_empty()
		and NightLights.lamp_wash(at.call(-0.4), wall, 1.0, wr).pieces.is_empty(),
		"none from `out` cells away or behind the wall")
	check(NightLights.lamp_wash(at.call(0.3), wall, 0.0, wr).strength == 0.0
		and is_equal_approx(NightLights.lamp_wash(at.call(0.3), wall, 0.5, wr).strength, near * 0.5),
		"it follows the lights' glow (none by day)")
	check(NightLights.lamp_wash({"pos": Vector3(3.0 + reach + 0.1, 0.86, 2.5)}, wall, 1.0, wr).pieces.is_empty(),
		"none from a lantern past the wall's end")
	var odd: Dictionary = wall.duplicate()
	odd.finish = "glass"
	check(NightLights.lamp_wash(at.call(0.3), odd, 1.0, wr).pieces.is_empty(), "a finish without rules gets none")
	var win := {"key": "build:shoji", "pos": Vector3(0.85, 1.05, 2.0), "size": Vector2(0.7, 0.5), "normal": Vector3(0, 0, 1),
		"span": Vector2(-3.85, 2.15)}
	var lamp := {"pos": Vector3(0, 0.86, 2.6)}
	var Occluders: GDScript = load("res://scripts/world3d/occluders.gd")
	var occ: RefCounted = Occluders.new()
	check(NightLights.lamp_washes([win], [lamp], 1.0, wr, occ).size() == 1, "a lantern in the open washes the wall")
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2, 2, 0.2)
	box.mesh = mesh
	box.position = Vector3(0, 1.0, 2.3)
	box.material_override = StandardMaterial3D.new()
	occ.add([box])
	check(NightLights.lamp_washes([win], [lamp], 1.0, wr, occ).is_empty(), "a building between the lantern and the wall stops its wash")
	box.free()


## The earthen and charred board walls' own warm light at night (NightLights.finish_wash,
## data/light.json "pools" → "wall" → "finishes"): the timber and yakisugi houses dress their
## windows (LitSpots.wall_look); the pieces stay inside the plain wash, on the material's heights,
## within the wall and off the posts and the pane; earth a soft glow, boards a fainter, greyer
## sheen; in its own pass with the pale wash, its shader keeping it to warm, not pale pixels.
func _finish_wash(world: Node3D) -> void:
	var NightLights: GDScript = load("res://scripts/world3d/night_lights.gd")
	var light: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
	var wr: Dictionary = light.pools.wall
	var fr: Dictionary = wr.get("finishes", {})
	check(fr.has("earth") and fr.has("board") and float(fr.earth.strength) > 0.0 and float(fr.board.strength) > 0.0
		and float(wr.warm_from) < float(wr.warm_full), "data/light.json pools.wall: earth and board finishes, warm_from under warm_full")
	var earth := Color(str(fr.earth.color))
	var board := Color(str(fr.board.color))
	check(float(fr.board.strength) < float(fr.earth.strength) and board.s < earth.s,
		"the boards take a fainter, greyer sheen than the earthen wall (%.2f / %.2f, saturation %.2f / %.2f)"
		% [float(fr.board.strength), float(fr.earth.strength), board.s, earth.s])
	# Which windows are dressed: the town's timber and yakisugi houses, not the plaster ones.
	var kinds := {}
	var plain := 0
	for w in world.windows:
		if w.has("finish"):
			kinds[w.finish] = int(kinds.get(w.finish, 0)) + 1
		elif NightLights.finish_wash(w, 1.0, wr).pieces.is_empty():
			plain += 1
	check(kinds.get("earth", 0) > 0 and kinds.get("board", 0) > 0 and plain > 0 and plain + kinds.earth + kinds.board == world.windows.size(),
		"timber and yakisugi houses' windows dressed, plaster ones get no finish wash (%s, %d plain)" % [kinds, plain])
	var reach := float(wr.reach)
	var inside := true
	var on_band := true
	var off_posts := true
	var no_pane := true
	var lit := true
	for win in world.windows.filter(func(w): return w.has("finish")):
		var own: Dictionary = NightLights.finish_wash(win, 1.0, wr)
		lit = lit and own.strength > 0.0 and not own.pieces.is_empty()
		var right: Vector3 = Vector3.UP.cross(win.normal).normalized()
		var half: Vector2 = win.size / 2.0
		var pane := Rect2(-half.x, win.pos.y - half.y, win.size.x, win.size.y)
		for piece in own.pieces:
			var bb := Rect2()
			for i in 4:
				var d: Vector3 = piece.corners[i] - win.pos
				var p := Vector2(d.dot(right), piece.corners[i].y)
				bb = Rect2(p, Vector2.ZERO) if i == 0 else bb.expand(p)
				inside = inside and absf(d.dot(win.normal)) < 0.0001 and absf(p.x) <= reach + 0.0001 \
					and p.x >= win.span.x - 0.0001 and p.x <= win.span.y + 0.0001 \
					and piece.uvs[i].is_equal_approx(Vector2(p.x, win.pos.y - p.y) / reach)
			on_band = on_band and win.bands.any(func(b: Vector2): return bb.position.y >= b.x - 0.0001 and bb.end.y <= b.y + 0.0001)
			for post: Vector2 in win.posts:
				off_posts = off_posts and (bb.end.x <= post.x + 0.0001 or bb.position.x >= post.y - 0.0001)
			no_pane = no_pane and bb.intersection(pane).get_area() < 0.0001
	check(lit, "every dressed window lights its own wall")
	check(inside, "the finish wash lies on the wall plane, within reach and the wall's ends, centred on the window")
	check(on_band, "the finish wash keeps to the material's heights")
	check(off_posts, "the finish wash keeps off the front posts")
	check(no_pane, "the finish wash keeps off the pane")
	# The heights clear the timber: the skirt, the rails and the front beam.
	var top := LitSpots.VILLAGE_WALL
	var rail_ok := true
	for b: Vector2 in LitSpots.wall_look("timber", 0.0, top).bands:
		rail_ok = rail_ok and b.x >= LitSpots.TIMBER_SKIRT - 0.0001 and (b.y <= LitSpots.TIMBER_RAIL - LitSpots.RAIL / 2 + 0.0001
			or b.x >= LitSpots.TIMBER_RAIL + LitSpots.RAIL / 2 - 0.0001) and b.y <= top - LitSpots.RAIL + 0.0001
	for b: Vector2 in LitSpots.wall_look("yakisugi", 0.0, top).bands:
		rail_ok = rail_ok and b.y <= top - LitSpots.YAKISUGI_BAND - LitSpots.RAIL / 2 + 0.0001
	check(rail_ok and LitSpots.wall_look("plaster", 0.0, top).is_empty() and LitSpots.wall_look("upper_yakisugi", 1.3, 2.9).is_empty(),
		"the bands clear the skirt, rails and beam; plaster walls have no finish")
	# A timber house's posts: one at every cell's edge, cut from its wash.
	var r := Rect2(10, 4, 5, 3)
	var spots: Array = LitSpots.village_house(r, 2, false, -1, 1, "timber")
	var door: Dictionary = spots[0]
	var cut := true
	for x in [10.1, 11.0, 12.0, 13.0, 14.0, 14.9]:
		cut = cut and door.posts.any(func(p: Vector2): return x - door.pos.x > p.x and x - door.pos.x < p.y)
	check(cut and door.finish == "earth", "a timber house's door: posts cut at the corners and every cell's edge")
	var win: Dictionary = spots[1]
	var full: float = NightLights.finish_wash(win, 1.0, wr).strength
	check(NightLights.finish_wash(win, 0.0, wr).strength == 0.0 and is_equal_approx(NightLights.finish_wash(win, 0.5, wr).strength, full * 0.5)
		and NightLights.finish_wash(door, 1.0, wr).strength > full, "the finish wash follows the glow; a door brighter")
	# Its pass: with the pale wash, between the copy and the glows.
	var nl: Control = NightLights.new()
	root.add_child(nl)
	check(nl.copy.get_index() < nl.finishes.get_index() and nl.finishes.get_index() < nl.glows.get_index(),
		"the finish wash is drawn after the copy and before the glows")
	var code: String = (nl.finishes.material as ShaderMaterial).shader.code
	check("hint_screen_texture" in code and "blend_add" in code and "warm" in code and "pale" in code,
		"the finish wash's shader reads the copy for warm, not pale pixels")
	nl.free()
	# The shader's mask on the pictures (as if lit white): earthen plaster takes it, white
	# plaster (its own wash) and the blue roof tiles do not, the boards some.
	var weight := func(key: String) -> float:
		var img: Image = PlaceholderArt.tex(key).get_image()
		var sum := 0.0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				sum += smoothstep(float(wr.warm_from), float(wr.warm_full), c.r - maxf(c.g, c.b)) \
					* (1.0 - smoothstep(float(wr.pale_from), float(wr.pale_full), c.b))
		return sum / (img.get_width() * img.get_height())
	var w_earth: float = weight.call("build:tsuchi")
	var w_plaster: float = weight.call("build:plaster")
	var w_roof: float = weight.call("build:kawara")
	var w_board: float = weight.call("build:board")
	check(w_earth > 0.8 and w_plaster < 0.01 and w_roof < 0.01 and w_board > 0.1,
		"the mask: earth %.2f, boards %.2f take it, plaster %.2f and roof tiles %.2f not" % [w_earth, w_board, w_plaster, w_roof])


## Real warm lights at night (NightLamps, data/light.json "lamps"): one for every lit window and
## lantern while they glow, none by day, the nearest few kept with the farthest faded, the colour
## divided by the tint, and the ground, water and grass left to the drawn pools.
func _night_lamps(world: Node3D) -> void:
	var NightLamps: GDScript = load("res://scripts/world3d/night_lamps.gd")
	var light: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
	var lr: Dictionary = light.lamps
	var all: Array = NightLamps.spots_of([world], [], 1.0, 0.0, lr)
	check(all.size() == world.windows.size() + world.lamps.size(), "a lamp for every lit window and lantern (%d)" % all.size())
	check(NightLamps.spots_of([world], [], 0.0, 0.0, lr).is_empty(), "no lamps while the windows are dark (by day)")
	var win: Dictionary = world.windows[0]
	check(all[0].pos.is_equal_approx(win.pos + win.normal * float(lr.out)) and is_equal_approx(all[0].energy, float(lr.window)),
		"a window's lamp hangs %.2f in front of its pane, as bright as lamps.window" % float(lr.out))
	var lamp: Dictionary = all[world.windows.size()]
	var fire: Vector3 = world.lamps[0].pos
	check(lamp.pos.distance_to(fire) < float(lr.lamp_out) + 0.001 and lamp.pos.x > fire.x and lamp.pos.z > fire.z
		and is_equal_approx(lamp.energy, float(lr.lamp)), "a stone lantern's lamp sits by its fire box, toward the camera")
	var half: Array = NightLamps.spots_of([world], [], 0.5, 0.0, lr)
	check(half.size() == all.size() and is_equal_approx(half[0].energy, all[0].energy * 0.5), "the lamps dim with the windows' glow")
	# The nearest few, nearest first; the last one kept fades out before it is dropped.
	var row: Array = []
	for i in 12:
		row.append({"pos": Vector3(i, 1, 0), "energy": 1.0})
	var picked: Array = NightLamps.nearest(row, Vector3(0, 0, 0), 8, 1.5)
	var order := picked.size() <= 8
	for i in range(1, picked.size()):
		order = order and picked[i].pos.x > picked[i - 1].pos.x
	check(order and picked.size() == 8 and picked[0].energy == 1.0, "at most 8 lamps, nearest first (%d)" % picked.size())
	check(is_equal_approx(picked[7].energy, 1.0 / 1.5) and picked[6].energy == 1.0, "the farthest kept fades as it nears the cut (%.2f)" % picked[7].energy)
	var even: Array = NightLamps.nearest(row, Vector3(7.5, 0, 0), 7, 1.5)   # x 4 and 11 as near: the 7th sits at the cut
	check(even.size() == 6 and even.all(func(s): return s.pos.x != 11.0 and s.pos.x != 4.0), "a lamp right at the cut is faded out, not kept (%d)" % even.size())
	check(NightLamps.nearest(row.slice(0, 5), Vector3.ZERO, 8, 1.5).size() == 5, "fewer spots than lamps: all of them, full")
	check(NightLamps.nearest(row, Vector3(11, 0, 0), 8, 1.5)[0].pos.x == 11.0, "the nearest the middle of the view come first")
	# The tint multiplies the picture afterwards: the light's colour is warm / tint, so it lands as warm.
	var night: Color = Color(str(light.sky[0][1]))
	var warm := Color(str(lr.color))
	var t: Dictionary = NightLamps.color_through(warm, night, float(lr.boost))
	var lands := Color(t.color.r * t.energy * night.r, t.color.g * t.energy * night.g, t.color.b * t.energy * night.b)
	check(maxf(t.color.r, maxf(t.color.g, t.color.b)) == 1.0 and t.energy > 1.0 and lands.is_equal_approx(warm),
		"through the night blue the lamps land warm %s (colour %s x %.2f)" % [lands, t.color, t.energy])
	var day: Dictionary = NightLamps.color_through(warm, Color.WHITE, float(lr.boost))
	check(day.color.is_equal_approx(warm) and is_equal_approx(day.energy, 1.0), "under no tint the colour is its own")
	check(NightLamps.color_through(warm, Color(0.01, 0.01, 0.01), float(lr.boost)).energy == float(lr.boost), "a near-black tint is held at the boost")
	check(int(lr.max) <= 8 and int(lr.max) > 0, "a bounded number of lamps (%d)" % int(lr.max))
	# The ground, the water and the grass are on GROUND_LAYER, which the lamps leave out.
	var is_ground := func(n: Node) -> bool:
		var m: Material = n.material_override
		if m is ShaderMaterial and "uniform sampler2D ground" in str((m as ShaderMaterial).shader.code):
			return true
		return n.get_script() != null and n.get_script().resource_path.get_file() in ["water_surface.gd", "grass_tufts.gd"]
	var grounds: Array = world.find_children("*", "GeometryInstance3D", true, false).filter(is_ground)
	var plain_ground: Array = world.find_children("*", "MeshInstance3D", true, false).filter(func(n): return n.mesh != null and n.mesh.get_class() == "PlaneMesh")   # not a QuadMesh picture
	var lit: Array = (grounds + plain_ground).filter(func(n): return n.layers != NightLamps.GROUND_LAYER or (n.layers & NightLamps.LIT_MASK) != 0)
	check(not grounds.is_empty() and not plain_ground.is_empty() and lit.is_empty(),
		"the ground, water and grass are left out of the lamps (%d lit as the ground; still lit: %s)" % [grounds.size() + plain_ground.size(),
		lit.map(func(n): return "%s %s" % [n.get_class(), n.get_script().resource_path.get_file() if n.get_script() else ""])])


## The glow keeps off figures in front of it (NightLights.shielded, sprite_corners, hidden).
func _glow_off_figures() -> void:
	var NightLights: GDScript = load("res://scripts/world3d/night_lights.gd")
	var lit := [{"rect": Rect2(100, 50, 40, 30), "pos": Vector3(4, 1.1, 3.6), "normal": Vector3(0, 0, 1)}]
	check(NightLights.shielded(Rect2(110, 40, 16, 30), Vector3(4, 0, 4.5), lit), "a figure in front of a window and over its glow: kept off")
	check(not NightLights.shielded(Rect2(110, 40, 16, 30), Vector3(4, 0, 2.5), lit), "a figure behind the window's wall is not (nothing to show)")
	check(not NightLights.shielded(Rect2(200, 40, 16, 30), Vector3(4, 0, 4.5), lit), "a figure away from the glow on screen is left alone")
	var side := [{"rect": Rect2(100, 50, 40, 30), "pos": Vector3(7, 1.1, 2), "normal": Vector3(1, 0, 0)}]
	check(NightLights.shielded(Rect2(110, 40, 16, 30), Vector3(8, 0, 2), side) and not NightLights.shielded(Rect2(110, 40, 16, 30), Vector3(6, 0, 2), side),
		"a side window: in front means out past its wall")
	var lamp := [{"rect": Rect2(100, 50, 40, 30), "pos": Vector3(5, 0.86, 5), "normal": Vector3(0.7, 0, 0.7)}]
	check(NightLights.shielded(Rect2(110, 40, 16, 30), Vector3(6, 0, 6), lamp) and not NightLights.shielded(Rect2(110, 40, 16, 30), Vector3(4, 0, 4), lamp),
		"a lantern's glow keeps off a figure nearer the eye, not one behind it")
	var fw: GDScript = load("res://scripts/world3d/farm_world.gd")
	var art: GDScript = load("res://scripts/art/placeholder_art.gd")
	var s: Sprite3D = fw.make_sprite(art.tex("item:turnip"))
	var h: float = s.texture.get_height() * fw.PX
	var hw: float = s.texture.get_width() * fw.PX / 2.0
	var root3 := Node3D.new()
	root.add_child(root3)
	root3.add_child(s)
	s.position = Vector3(2, 0, 3)
	var c: Array = NightLights.sprite_corners(s, Basis.IDENTITY)
	check(c[0].distance_to(Vector3(2 - hw, h, 3)) < 0.001 and c[2].distance_to(Vector3(2 + hw, 0, 3)) < 0.001,
		"a figure's quad: feet on the ground, top left to bottom right")
	var Occluders: GDScript = load("res://scripts/world3d/occluders.gd")
	var occ: RefCounted = Occluders.new()
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(4, 3, 2)
	box.mesh = mesh
	box.position = Vector3(2, 1.5, 6)
	box.material_override = StandardMaterial3D.new()
	occ.add([box])
	check(NightLights.hidden(Vector3(2, 0.5, 3), Vector3(2, 5, 25), occ), "a figure behind a solid house is hidden (no glow kept off it)")
	check(not NightLights.hidden(Vector3(2, 0.5, 9), Vector3(2, 5, 25), occ), "one in front of it is not")
	occ.update(Vector3(2, 0, 3), Vector3(0, 0.45, 1).normalized(), 10.0)
	check(not NightLights.hidden(Vector3(2, 0.5, 3), Vector3(2, 5, 25), occ), "behind a house faded see-through it shows again")
	box.free()
	root3.free()


## Winter snow off the farm: outdoor maps hold it by tile kind (paths a little less, water
## none) and on their roofs, in both views; rooms and the mine floors stay bare.
func _map_snow() -> void:
	var rules: Dictionary = root.get_node("Game").snow_rules
	var town := MapManager.data("town")
	var k := SnowLayer.MASK_PER_CELL
	var grass := SnowLayer.map_hold(town, Vector2i(0, 0), rules)
	var path := SnowLayer.map_hold(town, Vector2i(0, 10), rules)
	var gravel := SnowLayer.map_hold(town, Vector2i(15, 2), rules)
	var pond := SnowLayer.map_hold(town, Vector2i(32, 15), rules)
	check(grass == 1.0 and path < grass and gravel < grass and gravel > 0.0 and pond == 0.0,
		"village snow: grass %s, path %s, gravel %s, pond %s" % [grass, path, gravel, pond])
	for kind in ["gravel", "scree", "rock_wall"]:
		check(rules.ground.has(kind), "snow hold for %s ground" % kind)
	for id in ["town", "river", "mine"]:
		check(SnowLayer.map_has_snow(MapManager.data(id)), "snow lies on %s" % id)
	for id in ["house", "store", "smithy", "coop", "barn", "tome_house", "mine_floor", "farm"]:
		check(not SnowLayer.map_has_snow(MapManager.data(id)), "no map snow on %s" % id)
	var room := SnowLayer.map_mask_image(MapManager.data("house"), rules)
	var room_white := 0.0
	for y in room.get_height():
		for x in room.get_width():
			room_white = maxf(room_white, room.get_pixel(x, y).r)
	check(room_white == 0.0, "a room's mask holds no snow")
	var mask := SnowLayer.map_mask_image(town, rules)
	check(mask.get_size() == Vector2i(town.w * k, town.h * k) and absf(mask.get_pixel(1, 10 * k + 1).r - path) < 0.01,
		"the village mask spans the map and holds the path value")
	var roofs := SnowLayer.roof_mask_image(town, rules)
	var door: Vector2i = town.doors[1].cells[0]   # Tome's door, on her house front
	check(roofs.get_pixel(4 * k + 1, 4 * k + 1).r > 0.5 and roofs.get_pixel(door.x * k + 1, door.y * k + 1).r == 0.0
		and roofs.get_pixel(4 * k + 1, door.y * k + 1).r == 0.0 and roofs.get_pixel(1, 10 * k + 1).r == 0.0,
		"2D roof snow over the houses, not on their front row or the road")

	# The flat view: ground snow under the props, roof snow over them, hidden without cover.
	var v2 := MapView.new()
	v2.map = town
	root.add_child(v2)
	v2.show_snow(rules)
	var sprites: Array = v2.get_children().filter(func(n): return n is Sprite2D and not n is WaterView)
	var objects: Node = v2.get_children().filter(func(n): return not n is Sprite2D)[0]
	check(sprites.size() == 2 and sprites[0].get_index() < objects.get_index() and sprites[1].get_index() > objects.get_index(),
		"2D village: snow under the props and on the roofs")
	v2.set_snow(0.0)
	check(not sprites[0].visible and not sprites[1].visible, "2D village: no cover, no snow")
	v2.set_snow(0.7)
	check(sprites.all(func(s): return s.visible and is_equal_approx(s.material.get_shader_parameter("cover"), 0.7)),
		"2D village: the snow takes the cover")
	v2.free()
	var room_2d := MapView.new()
	room_2d.map = MapManager.data("house")
	root.add_child(room_2d)
	room_2d.show_snow(rules)
	check(room_2d.get_children().all(func(n): return not n is Sprite2D) and room_2d.snow_mask == null, "2D: no snow indoors")
	room_2d.set_snow(1.0)
	room_2d.free()

	# 3D: the village ground and roofs take the cover; the mine floor has nothing to whiten.
	var tops := func(w: Node3D) -> Array:
		return w.get_children().filter(func(n): return n is MeshInstance3D and n.material_override is ShaderMaterial)
	var v3: Node3D = load("res://scripts/world3d/map_world.gd").new()
	v3.build(town)
	v3.set_snow(0.5)
	var snowy: Array = tops.call(v3)
	# The ground, five house roofs, the torii, the hokora roof and two lanterns: one cover each.
	check(snowy.size() >= 10 and snowy.all(func(n): return is_equal_approx(n.material_override.get_shader_parameter("cover"), 0.5)),
		"3D village: ground and roof tops take the cover (%d)" % snowy.size())
	v3.free()
	for id in ["mine_floor", "house"]:
		var w3: Node3D = load("res://scripts/world3d/map_world.gd").new()
		w3.build(MapManager.data(id))
		check(tops.call(w3).is_empty(), "3D %s: no snow" % id)
		w3.free()


## The homes build in 3D without the magenta stand-in box (MapWorld needs the autoloads, so
## this runs on the first frame).
## The farmhouse's thatched roof (Minka): every face turned the way its normal says (Godot
## draws clockwise fronts), the soffit at the front eave above the farmer's head, the ridge
## where the pitch puts it.
## The far country (Backdrop, data/backdrop.json): on the listed outdoor maps only, the land
## stopping at the rim, the ridges past it and below the ground, toned by season, hazed with the
## sky by the clock, snow caps in winter; and, through the game's own lens with the camera held
## at the village's north edge, peaks in the frame with sky above them, not hidden by the land.
func _backdrop() -> void:
	var Backdrop: GDScript = load("res://scripts/world3d/backdrop.gd")
	var Surroundings: GDScript = load("res://scripts/world3d/surroundings.gd")
	var cfg: Dictionary = Backdrop.config()
	var rim: int = Backdrop.rim()
	var listed := true
	for id in ["farm", "town", "hill", "kaminoda", "sakurazaka", "minamino", "river"]:
		listed = listed and Backdrop.on_map(id) and MapManager.data(id) != null
	for id in ["house", "mine", "mine_floor", "store", "clinic"]:
		listed = listed and not Backdrop.on_map(id)
	check(listed, "the far country on the seven outdoor maps, not in rooms, the mine or its cave mouth")
	check(rim > 0 and rim < Surroundings.MARGIN and Backdrop.rim_pines() < Surroundings.TREE_SHARE and cfg.layers.size() >= 2,
		"the land stops %d cells past the back edges, a thinner wood on the rim" % rim)
	var town := MapManager.data("town")
	var world: Node3D = load("res://scripts/world3d/map_world.gd").new()
	root.add_child(world)
	world.build(town)
	var bd = world.backdrop
	check(bd != null and bd.layers.size() == cfg.layers.size() and world.surroundings.back == rim,
		"the village has the ridges and its land stops at the rim")
	var past_rim := 0
	var wood := 0
	for n in world.surroundings.get_children():
		if n is MultiMeshInstance3D:
			for i in n.multimesh.instance_count:
				var o: Vector3 = n.multimesh.get_instance_transform(i).origin
				wood += 1
				if o.x < -rim or o.z < -rim:
					past_rim += 1
	check(wood > 0 and past_rim == 0, "pines on the rim, none past it (%d pine parts)" % wood)
	# The ridges: past the rim, below the ground, so they never stand in front of the land.
	var points := []   # [layer index, Vector3 peak]
	var bad := 0
	for i in cfg.layers.size():
		var layer: Dictionary = cfg.layers[i]
		var pts: PackedVector2Array = Backdrop.samples(Backdrop.path(town.w, town.h, float(layer.gap), float(cfg.span)), float(layer.step))
		var tops: PackedFloat32Array = Backdrop.tops_for(pts.size(), float(layer.low), float(layer.high), int(layer.seed))
		for k in pts.size():
			points.append([i, Vector3(pts[k].x, tops[k], pts[k].y)])
			if (pts[k].x >= -rim and pts[k].y >= -rim) or tops[k] >= 0.0 or float(layer.bottom) > float(layer.low) - 20.0:
				bad += 1
	check(points.size() > 40 and bad == 0, "the ridges stand past the rim and below the ground (%d points, %d wrong)" % [points.size(), bad])
	# Tone: the season's colour, the sky's colour as the haze, snow caps in winter only.
	var sky := Color("e8cdbd")
	bd.tone("winter", sky)
	var near: ShaderMaterial = bd.layers[-1].mat
	var winter_line: float = near.get_shader_parameter("snow_line")
	var hazed: Color = near.get_shader_parameter("haze_color")
	var toned: Color = near.get_shader_parameter("ridge")
	bd.tone("summer", sky)
	var summer_line: float = near.get_shader_parameter("snow_line")
	check(winter_line < float(cfg.layers[-1].high) and summer_line >= Backdrop.NO_SNOW, "snow caps in winter (line %.1f), none in summer" % winter_line)
	check(hazed.is_equal_approx(sky) and toned.is_equal_approx(Color(str(cfg.layers[-1].colors.winter)))
		and Color(near.get_shader_parameter("ridge")).is_equal_approx(Color(str(cfg.layers[-1].colors.summer))),
		"the ridges take the season's colour and the sky's as their haze")
	var g: Node = root.get_node("Game")
	bd.refresh()
	check(Color(near.get_shader_parameter("haze_color")).is_equal_approx(g.sky_color()), "the haze follows Game.sky_color by the clock")
	check(float(cfg.layers[0].haze) > float(cfg.layers[-1].haze), "the far ridge more hazed than the near one")
	# Through the game's lens, the camera held at the north edge (Main3D's clamp): peaks in the
	# frame, over the rim's line of sight, sky's room above some.
	var lens: RefCounted = load("res://scripts/world3d/camera_lens.gd").pick(
		JSON.parse_string(FileAccess.get_file_as_string("res://data/camera.json")))
	var margin: Vector2 = load("res://scripts/main_3d.gd").CAM_MARGIN
	var shown := [0, 0]
	var open_sky := 0
	for target in [Vector3(town.w / 2.0, 0, margin.y), Vector3(margin.x, 0, town.h / 2.0), Vector3(margin.x, 0, margin.y)]:
		for p in points:
			if _in_frame(lens, target, p[1], rim):
				shown[p[0]] += 1
				if _in_frame(lens, target, p[1] + Vector3(0, 0.6, 0), rim):
					open_sky += 1
	check(shown[0] >= 3 and shown[1] >= 3 and open_sky >= 3,
		"the %s lens shows the ridges from the back edges (far %d, near %d peaks, %d with sky above)" % [lens.id, shown[0], shown[1], open_sky])
	var mid := 0
	for p in points:
		if _in_frame(lens, Vector3(town.w / 2.0, 0, town.h / 2.0), p[1], rim):
			mid += 1
	check(mid == 0, "from the middle of the village the rim hides them (%d)" % mid)
	world.free()
	for id in ["house", "mine"]:
		var other: Node3D = load("res://scripts/world3d/map_world.gd").new()
		root.add_child(other)
		other.build(MapManager.data(id))
		check(other.backdrop == null and (other.surroundings == null or other.surroundings.back == Surroundings.MARGIN),
			"no ridges at the %s, its land (if any) runs on" % id)
		other.free()


## Is `p` inside the 480 x 270 frame of `lens` looking at `target`, and not under the land
## (its line of sight meets the ground past the rim, or not at all)?
func _in_frame(lens: RefCounted, target: Vector3, p: Vector3, rim: int) -> bool:
	var eye: Vector3 = target + lens.back * lens.dist
	var fwd: Vector3 = -lens.back
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd)
	var v := p - eye
	var depth := v.dot(fwd)
	var t := tan(deg_to_rad(lens.fov) / 2.0)
	if depth <= 0.0 or absf(v.dot(up) / depth) > t or absf(v.dot(right) / depth) > t * 480.0 / 270.0:
		return false
	if p.y >= 0.0:
		return true
	var ground := eye + v * (eye.y / (eye.y - p.y))
	return ground.x < -rim or ground.z < -rim


func _minka() -> void:
	var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	var crest: float = load("res://scripts/world3d/minka.gd").roof(w, Rect2(1.45, 0.55, 6.1, 3.5), 1.45, 1.25, 0.5)
	check(is_equal_approx(crest, 1.45 + 1.75 * 1.25 + 0.5 + 0.4), "Minka ridge height (%.2f)" % crest)
	var faces := 0
	var wrong := 0
	var low := 99.0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				faces += 1
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
				for k in 3:
					if v[i + k].z > 4.0:
						low = minf(low, v[i + k].y)
	check(faces >= 26 and wrong == 0, "Minka faces turned outwards (%d of %d wrong)" % [wrong, faces])
	check(low >= 1.4, "Minka front eave above the farmer's head (%.2f)" % low)
	check(_walls_facing_in(w, Vector2(4.5, 2.3)) == 0, "Minka's eave band faces away from the house")
	w.free()
	# The gable roofs of the coop (thatch) and the barn (kawara with tile rolls).
	var minka: GDScript = load("res://scripts/world3d/minka.gd")
	for rolls in [0.0, 0.25]:
		w = load("res://scripts/world3d/farm_world.gd").new()
		var eave := Rect2(18.78, 0.68, 5.44, 3.6)
		crest = minka.gable(w, eave, 1.45, 0.55, 0.15, "build:kawara", "build:kawara_edge", rolls)
		var want := 1.45 + 1.8 * 0.55 + 0.15 + (0.06 if rolls > 0.0 else 0.0)
		check(is_equal_approx(crest, want), "gable ridge height %.3f (rolls %.2f)" % [crest, rolls])
		faces = 0
		wrong = 0
		low = 99.0
		for n in w.get_children():
			if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
				var arr: Array = n.mesh.surface_get_arrays(0)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				for i in range(0, v.size(), 3):
					faces += 1
					if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
						wrong += 1
					for k in 3:
						if v[i + k].z > 4.2:
							low = minf(low, v[i + k].y)
		var expect := 24 + (21 * 2 * 5 if rolls > 0.0 else 0)   # slopes, soffit, bands, verges, snow; 21 rolls a side
		check(faces == expect and wrong == 0, "gable faces turned outwards (%d of %d wrong, %d expected)" % [wrong, faces, expect])
		check(low >= 1.45, "gable front eave above the farmer's head (%.2f)" % low)
		check(_walls_facing_in(w, eave.get_center()) == 0, "gable eave bands and verges face outwards (rolls %.2f)" % rolls)
		w.free()
	# The tiled ridge: it rises at both ends (the curl) and stays level in the middle (the
	# onigawara are BoxMeshes, not counted here).
	w = load("res://scripts/world3d/farm_world.gd").new()
	minka.ridge(w, 0.0, 5.0, 2.0, 1.5)
	var tops := {}   # x rounded to a tenth: highest y of the ridge meshes there
	faces = 0
	wrong = 0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				faces += 1
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
				for k in 3:
					var key := snappedf(v[i + k].x, 0.1)
					tops[key] = maxf(tops.get(key, -1.0), v[i + k].y)
	check(faces > 0 and wrong == 0, "ridge faces turned outwards (%d of %d wrong)" % [wrong, faces])
	var level: float = tops.get(0.8, 0.0)   # where the curl starts (sweep 0.8); one span between
	check(is_equal_approx(level, tops.get(4.2, -1.0)) and tops.get(0.0, 0.0) > level + 0.1
		and tops.get(5.0, 0.0) > level + 0.1, "the ridge curls up at both ends (%s)" % [tops])
	w.free()
	_hip_roof()
	_village_styles()


## Every ArrayMesh face of `w`: [faces, wrongly wound, lowest y of a vertex past z `front`, highest y].
func _mesh_faces(w: Node3D, front: float) -> Array:
	var faces := 0
	var wrong := 0
	var low := 99.0
	var high := -99.0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				faces += 1
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
				for k in 3:
					high = maxf(high, v[i + k].y)
					if v[i + k].z > front:
						low = minf(low, v[i + k].y)
	return [faces, wrong, low, high]


## The tiled hip roof (Minka.hip): faces wound to their normals, the upright ones (eave bands,
## roll ends, the hips' end faces) facing out, the eave all round at its height, the ridge
## height, tile rolls on all four slopes that stop at the hips (nothing stands more than the
## hip crest off the roof surface), a snow layer driven by set_snow, and the ridge ends.
func _hip_roof() -> void:
	var minka: GDScript = load("res://scripts/world3d/minka.gd")
	var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	var eave := Rect2(1.0, 1.0, 5.5, 3.45)
	var crest: float = minka.hip(w, eave, 1.45, 0.5, 0.14, "build:kawara", "build:kawara_edge", 0.25)
	check(is_equal_approx(crest, 1.45 + 3.45 / 2.0 * 0.5 + 0.14 + 0.06), "hip ridge height %.3f" % crest)
	var f := _mesh_faces(w, eave.end.y - 0.01)
	check(f[0] > 200 and f[1] == 0, "hip roof faces turned outwards (%d of %d wrong)" % [f[1], f[0]])
	check(f[2] >= 1.45 - 0.001, "hip roof's front eave above the farmer's head (%.2f)" % f[2])
	check(_walls_facing_in(w, eave.get_center()) == 0, "hip roof's eave bands, roll ends and hip ends face outwards")
	# Off the roof surface: the height grows with the distance to the nearest eave line.
	var above := 0.0
	var outside := 0
	var end_rolls := 0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.material_override is StandardMaterial3D:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in v.size():
				var p := v[i]
				if not eave.grow(0.001).has_point(Vector2(p.x, p.z)):
					outside += 1
				var d := maxf(0.0, minf(minf(p.z - eave.position.y, eave.end.y - p.z), minf(p.x - eave.position.x, eave.end.x - p.x)))
				above = maxf(above, p.y - (1.45 + 0.14 + d * 0.5))
			for i in range(0, v.size(), 3):
				if absf(nm[i].x) > 0.99 and minf(v[i].y, minf(v[i + 1].y, v[i + 2].y)) > 1.55 and v[i].y < 1.7:
					end_rolls += 1   # a roll's round end on a hip end's eave
	check(outside == 0, "nothing of the hip roof past its eave line (%d)" % outside)
	check(above <= 0.13 + 0.001, "rolls and hips keep to the roof (%.3f above it at most)" % above)
	check(end_rolls >= 10, "the hip ends carry tile rolls too (%d roll ends)" % end_rolls)
	var snow := w.get_children().filter(func(n): return n is MeshInstance3D and n.material_override is ShaderMaterial and n.material_override in w._snow_mats)
	check(snow.size() == 1, "the hip roof has a snow layer driven by set_snow")
	var ends: Vector2 = minka.hip_ridge_ends(eave)
	check(ends.x < eave.position.x + 3.45 / 2.0 and ends.y > eave.end.x - 3.45 / 2.0 and ends.x < ends.y,
		"the main ridge reaches a little past the hips (%.2f .. %.2f)" % [ends.x, ends.y])
	w.free()


## The village houses' looks (LitSpots.village_style, MapWorld._village_house): defaults, every
## map house's fields known, a mix across the villages, and each look built: faces outwards,
## the front eave over the farmer, windows as LitSpots lays them, the upper ones seen between the
## pent roof and the main eave, snow on every roof, one fading thing.
func _village_styles() -> void:
	var plain: Dictionary = LitSpots.village_style({})
	check(plain == {"roof": "gable", "storeys": 1, "wall": "plaster"}, "a village house's plain look (%s)" % plain)
	var seen := {}
	var odd: Array = []
	for id in ["town", "kaminoda", "minamino", "sakurazaka"]:
		for p in MapManager.data(id).props:
			if p.kind != "village_house":
				continue
			var s: Dictionary = LitSpots.village_style(p)
			if not (s.roof in ["gable", "hip"] and s.wall in ["plaster", "yakisugi", "timber"] and int(p.get("storeys", 1)) in [1, 2]):
				odd.append("%s %s" % [id, p.cell])
			for k in s:
				seen["%s=%s" % [k, s[k]]] = true
	check(odd.is_empty(), "every village house's look is a known one %s" % [odd])
	var want := ["roof=gable", "roof=hip", "storeys=1", "storeys=2", "wall=plaster", "wall=yakisugi", "wall=timber"]
	check(want.all(func(k): return seen.has(k)), "the villages mix every roof, storey and wall (%s)" % [seen.keys()])
	# Sayo's store keeps its one-storey gable: the new sign stands on its front slope.
	for p in MapManager.data("town").props:
		if p.kind == "village_house" and p.get("side_door", -1) >= 0:
			var s: Dictionary = LitSpots.village_style(p)
			check(s.roof == "gable" and s.storeys == 1, "the store under its roof sign stays a one-storey gable")
	var r := Rect2(0, 0, 5, 3)
	var heights := {}
	for roof in ["gable", "hip"]:
		for storeys in [1, 2]:
			for wall in ["plaster", "yakisugi", "timber"]:
				var style := {"roof": roof, "storeys": storeys, "wall": wall}
				var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
				w.map = MapManager.data("town")
				w.occlude(func(): w._village_house(r, 2, false, -1, style))
				var front := LitSpots.village_front(r)
				var f := _mesh_faces(w, front + 0.05)
				var name := "%s / %d / %s" % [roof, storeys, wall]
				var mid := Vector2(r.get_center().x, (r.position.y + 0.1 + front) / 2.0)
				check(f[1] == 0 and _walls_facing_in(w, mid) == 0, "%s: faces turned and facing outwards" % name)
				check(f[2] >= 1.45 - 0.001, "%s: front eave above the farmer's head (%.2f)" % [name, f[2]])
				heights[name] = f[3]
				var spots: Array = LitSpots.village_house(r, 2, false, -1, storeys)
				var same: bool = spots.size() == w.windows.size()
				for i in mini(spots.size(), w.windows.size()):
					same = same and spots[i].pos.is_equal_approx(w.windows[i].pos) and spots[i].normal.is_equal_approx(w.windows[i].normal)
				var uppers: Array = w.windows.filter(func(s): return s.pos.y > 2.0)
				check(same and uppers.size() == (3 if storeys == 2 else 0), "%s: lit windows as LitSpots lays them (%d, %d upstairs)" % [name, w.windows.size(), uppers.size()])
				var snowy := w.get_children().filter(func(n): return n is MeshInstance3D and n.material_override is ShaderMaterial and n.material_override in w._snow_mats)
				check(snowy.size() == storeys, "%s: snow on each roof (%d)" % [name, snowy.size()])
				check(w.occluders.count() == 1 and w.occluders.box_of(0).end.y >= f[3] - 0.01,
					"%s: one thing that fades, as tall as the house" % name)
				w.free()
	# Upstairs windows: above where the pent roof meets the wall, below the line under the main
	# eave seen from the camera (its eye slope about 0.5 along the diagonal).
	var hide_below := LitSpots.UPPER_TOP - 0.35 * 0.5 - 0.35 * sqrt(2.0) * 0.5
	var up: Dictionary = LitSpots.village_house(r, 2, false, -1, 2).back()
	check(up.pos.y - up.size.y / 2 > LitSpots.UPPER_FLOOR and up.pos.y + up.size.y / 2 < hide_below,
		"upper windows between the pent roof (%.2f) and the main eave's shadow line (%.2f)" % [LitSpots.UPPER_FLOOR, hide_below])
	check(heights["gable / 2 / plaster"] > heights["gable / 1 / plaster"] + 0.8 and heights["hip / 1 / plaster"] <= heights["gable / 1 / plaster"] + 0.3,
		"two storeys stand taller; a hip roof about as tall as a gable (%s)" % [heights])


## The shrine pieces (Shrine): every mesh face turned to its normal, the lantern's facets
## facing away from its axis, the torii's kasagi rising to its ends.
func _shrine() -> void:
	var shrine: GDScript = load("res://scripts/world3d/shrine.gd")
	var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	shrine.stone_lantern(w, Vector3(3.5, 0, 3.5))
	var faces := 0
	var wrong := 0
	var inward := 0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				faces += 1
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
				var c := (v[i] + v[i + 1] + v[i + 2]) / 3.0
				if Vector2(nm[i].x, nm[i].z).dot(Vector2(c.x - 3.5, c.z - 3.5)) < -0.0001:
					inward += 1
	check(faces > 100 and wrong == 0 and inward == 0, "stone lantern facets turned outwards (%d wrong, %d inward of %d)" % [wrong, inward, faces])
	w.free()
	w = load("res://scripts/world3d/farm_world.gd").new()
	shrine.torii(w, Vector3(19, 0, 6.5), Rect2(17, 6, 4, 1))
	shrine.hokora(w, Vector3(19, 0, 2))
	faces = 0
	wrong = 0
	var ends := -1.0
	var middle := -1.0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				faces += 1
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
			if n.material_override is StandardMaterial3D and n.material_override.albedo_color == shrine.BLACK:
				for p in v:
					if is_equal_approx(p.x, 19.0):
						middle = maxf(middle, p.y)
					elif absf(p.x - 19.0) > 2.1:
						ends = maxf(ends, p.y)
	check(faces > 0 and wrong == 0, "torii and hokora faces turned outwards (%d of %d wrong)" % [wrong, faces])
	check(middle > 2.0 and ends > middle + 0.12, "the kasagi rises to its ends (middle %.2f, ends %.2f)" % [middle, ends])
	w.free()


## The bin, chest and seed stand (FarmProps): every face drawn the way its normal points, a
## tapered block's faces all turned out from its middle, every material lit, and the stand's
## front eave clear of the farmer (1.45 or more over z past its posts).
func _farm_props() -> void:
	var props: GDScript = load("res://scripts/world3d/farm_props.gd")
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	props.block(st, Rect2(0, 0, 1, 0.8), 0.0, Rect2(0.1, 0.1, 0.8, 0.6), 0.5)
	var arr: Array = st.commit().surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var out := 0
	for i in range(0, v.size(), 3):
		var c := (v[i] + v[i + 1] + v[i + 2]) / 3.0
		if nm[i].dot(c - Vector3(0.5, 0.25, 0.4)) > 0.0 and (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) < 0.0:
			out += 1
	check(v.size() == 36 and out == 12, "a tapered block's 12 triangles face out (%d)" % out)
	for what in ["bin", "chest", "stand"]:
		var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
		props.call(what, w)
		var faces := 0
		var wrong := 0
		var unlit := 0
		var low_eave := 9.0
		for n in w.get_children():
			if not n is MeshInstance3D:
				continue
			var mat: Variant = n.material_override
			if mat is StandardMaterial3D and mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				unlit += 1
			if n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
				arr = n.mesh.surface_get_arrays(0)
				v = arr[Mesh.ARRAY_VERTEX]
				nm = arr[Mesh.ARRAY_NORMAL]
				for i in range(0, v.size(), 3):
					faces += 1
					if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
						wrong += 1
				for p in v:
					if p.z > 4.06:
						low_eave = minf(low_eave, p.y)
		check(faces > 50 and wrong == 0 and unlit == 0,
			"%s: %d faces, %d drawn the wrong way, %d unlit materials" % [what, faces, wrong, unlit])
		if what == "stand":
			check(low_eave >= 1.45, "the seed stand's front eave clears the farmer (%.2f)" % low_eave)
		w.free()


## Interiors (RoomWalls): every face drawn the way its normal points, all lit; the back walls'
## room face stays within 0.05 of the wall line (things hung on it sit 0.08 out), the front
## sills stay low; a shoe stone below the door's step where the earth there is clear; the
## coop's and barn's walls are boards, a house's plaster.
func _room_walls() -> void:
	for id in ["house", "clinic", "store", "smithy", "coop", "barn"]:
		var m := MapManager.data(id)
		var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
		load("res://scripts/world3d/room_walls.gd").build(w, m)
		var wrong := 0
		var unlit := 0
		var proud := 0.0
		var front_top := 0.0
		var keys := []
		var stones := 0
		for n in w.get_children():
			if not n is MeshInstance3D:
				continue
			var mat: Variant = n.material_override
			if mat is StandardMaterial3D:
				if mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
					unlit += 1
				if mat.albedo_texture != null:
					keys.append(mat.albedo_texture)
			if not n.mesh is ArrayMesh:
				continue
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
			var is_stone: bool = mat is StandardMaterial3D and mat.albedo_color == Color("8a8680")
			for p in v:
				if p.y > 0.5 and p.x > 1.2 and p.z < 1.5:    # the back wall, past the corner post
					proud = maxf(proud, p.z - 1.0)
				if p.x > 1.2 and p.z > m.h - 1.5 and p.x < m.w - 1:   # along the front sill
					front_top = maxf(front_top, p.y)
				if is_stone and p.y > 0.0:
					stones += 1
		var free_stone := false   # the earth below the step in the door's column is clear
		for d in m.doors:
			for c: Vector2i in d.cells:
				free_stone = free_stone or load("res://scripts/world3d/room_walls.gd")._shoe_stone(m, c.x) != Vector2i(-1, -1)
		var plaster := PlaceholderArt.tex("build:plaster") in keys
		check(wrong == 0 and unlit == 0, "%s walls: %d faces the wrong way, %d unlit" % [id, wrong, unlit])
		check(proud <= 0.05, "%s: the back wall's face stands %.3f out (things hang at 0.08)" % [id, proud])
		check(front_top <= 0.4, "%s: the front sill keeps the room in view (%.2f high)" % [id, front_top])
		check(plaster == (m.walls == "plaster"), "%s: walls are %s" % [id, m.walls])
		check((stones > 0) == free_stone, "%s: a shoe stone below the door's step (%d corners)" % [id, stones])
		w.free()
	var bad := MapData.parse({"id": "x", "size": [1, 1], "ground": ["."], "legend": {".": {"tile": "earth"}}, "walls": "glass"})
	check(bad[0] != "", "a map with unknown walls is refused")


## The rooms' furniture (RoomProps): every kind is used by some map and has a look; each
## piece is built of lit meshes (only GLOWS colours unshaded: the lamp, embers, fire), its
## faces wound to their normals, inside its footprint (a little overhang allowed) and clear
## of the full-height back walls above and to the left (their posts stand 0.04 out), so
## nothing pokes through the timber. The front walls are low sills inside their own cells.
func _room_props() -> void:
	var rp: GDScript = load("res://scripts/world3d/room_props.gd")
	var used := {}
	var glowing := {}
	for id in MapManager.ids():
		var m := MapManager.data(id)
		for p in m.props:
			if not str(p.kind) in rp.KINDS:
				continue
			used[p.kind] = true
			var r := Rect2(Vector2(p.cell), Vector2(p.size))
			var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
			rp.prop(w, p, Vector3(r.get_center().x, 0, r.get_center().y), r)
			var shapes := 0
			var unlit := 0
			var wrong := 0
			var outside := 0
			var in_wall := 0
			for n in w.get_children():
				if not n is MeshInstance3D:
					continue
				if not n.mesh is ArrayMesh:
					shapes += 1
					continue
				var mat: StandardMaterial3D = n.material_override
				if mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
					if mat.albedo_color in rp.GLOWS:
						glowing[p.kind] = true
					else:
						unlit += 1
				var arr: Array = n.mesh.surface_get_arrays(0)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
				for i in range(0, idx.size(), 3):
					var c := (v[idx[i + 1]] - v[idx[i]]).cross(v[idx[i + 2]] - v[idx[i]])
					if c.length() > 1e-9 and c.dot(nm[idx[i]]) >= 0.0:
						wrong += 1
				for q in v:
					if not r.grow(0.16).has_point(Vector2(q.x, q.z)):
						outside += 1
					for o in [Vector2(-0.035, 0), Vector2(0, -0.035)]:
						var cell := Vector2i((Vector2(q.x, q.z) + o).floor())
						if m.in_bounds(cell) and m.tile(cell) == "wall":
							in_wall += 1
							break
			check(shapes == 0 and unlit == 0 and wrong == 0 and outside == 0 and in_wall == 0,
				"%s %s at %s: %d primitive shapes, %d unlit, %d faces the wrong way, %d corners outside, %d in a wall"
				% [id, p.kind, p.cell, shapes, unlit, wrong, outside, in_wall])
			w.free()
	var texts := ""   # the house's extensions (kotatsu, nagamochi) are only in its file
	for id in MapManager.ids():
		texts += FileAccess.get_file_as_string("res://data/maps/%s.json" % id)
	for kind in rp.KINDS:
		check(used.has(kind) or texts.contains('"%s"' % kind), "some map has a %s" % kind)
	for kind in ["andon", "kamado", "forge", "irori", "butsudan"]:
		check(glowing.has(kind), "the %s gives off light (an unshaded glow)" % kind)


## The coop's and barn's furniture (CoopProps, BarnProps): every prop is lit meshes (no
## primitive shapes, nothing unshaded but the incubator's lantern), its faces wound to their
## normals, standing inside its own cells (a little overhang allowed), clear of the back walls
## (the hatch and the gate sit in the side wall on purpose), and where AnimalLayer lays things
## on them they still show: an egg above the straw of its nest and above the incubator's straw,
## the feed above the trough's floor.
func _stable_props() -> void:
	var seen := {}
	var rp: GDScript = load("res://scripts/world3d/room_props.gd")
	var makers := {"coop": load("res://scripts/world3d/coop_props.gd"), "barn": load("res://scripts/world3d/barn_props.gd")}
	for id in ["coop", "barn"]:
		var m := MapManager.data(id)
		for p in m.props:
			var kind := str(p.kind)
			if not kind in ["feed_box", "nest", "incubator", "feed_sack", "hatch", "fodder_box", "stalls", "hay", "barn_gate"]:
				continue
			seen[kind] = true
			var r := Rect2(Vector2(p.cell), Vector2(p.size))
			var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
			var mid := Vector3(r.get_center().x, 0, r.get_center().y)
			makers[id].prop(w, p, mid, r)
			var meshes := 0
			var shapes := 0
			var unlit := 0
			var wrong := 0
			var outside := 0
			var in_wall := 0
			var tris := PackedVector3Array()   # three points a triangle, in the world's frame
			for n in w.get_children():
				if not n is MeshInstance3D:
					continue
				if not n.mesh is ArrayMesh:
					shapes += 1
					continue
				meshes += 1
				var mat: StandardMaterial3D = n.material_override
				if mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and not mat.albedo_color in rp.GLOWS:
					unlit += 1
				var arr: Array = n.mesh.surface_get_arrays(0)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
				for i in range(0, idx.size(), 3):
					var c := (v[idx[i + 1]] - v[idx[i]]).cross(v[idx[i + 2]] - v[idx[i]])
					if c.length() > 1e-9 and c.dot(nm[idx[i]]) >= 0.0:
						wrong += 1
				for i in idx:
					tris.append(v[i])
				for q in v:
					if not r.grow(0.2).has_point(Vector2(q.x, q.z)):
						outside += 1
					if kind in ["hatch", "barn_gate"]:
						continue
					for o in [Vector2(-0.035, 0), Vector2(0, -0.035)]:
						var cell := Vector2i((Vector2(q.x, q.z) + o).floor())
						if m.in_bounds(cell) and m.tile(cell) == "wall":
							in_wall += 1
							break
			check(meshes >= 1 and shapes == 0 and unlit == 0 and wrong == 0 and outside == 0 and in_wall == 0,
				"%s %s at %s: %d meshes, %d primitive shapes, %d unlit, %d faces the wrong way, %d corners outside, %d in a wall"
				% [id, kind, p.cell, meshes, shapes, unlit, wrong, outside, in_wall])
			var glows := 0
			for n in w.get_children():
				if n is MeshInstance3D and n.material_override.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
					glows += 1
			check((glows > 0) == (kind == "incubator"), "%s: only the incubator's lantern gives off light (%d glows)" % [kind, glows])
			# What AnimalLayer puts on the piece: the highest mesh point near each spot.
			var spots: Array[Vector3] = []
			if kind == "nest":
				for i in int(r.size.y):
					spots.append(Vector3(p.cell.x + 0.42, 0.34, p.cell.y + i + 0.5))
			elif kind == "incubator":
				spots.append(Vector3(p.cell.x + 0.45, 0.48, p.cell.y + 0.4))
			elif kind == "feed_box":
				spots.append(Vector3(r.get_center().x, 0.12, r.get_center().y - 0.1))
			elif kind == "fodder_box":
				spots.append(Vector3(r.get_center().x, 0.22, r.get_center().y + 0.05))
			for spot in spots:
				var top := _height_at(tris, Vector2(spot.x, spot.z))
				check(top >= 0.0 and top <= spot.y, "%s %s: the egg / feed spot at %s stands clear of the mesh (surface at %.2f)" % [id, kind, spot, top])
			w.free()
	for kind in ["feed_box", "nest", "incubator", "feed_sack", "hatch", "fodder_box", "stalls", "hay", "barn_gate"]:
		check(seen.has(kind), "the coop / barn have a %s" % kind)


## The barn's straw stalls (BarnProps._bedding): each space between the partitions has straw
## bedding under it. Its middle stands 0.02 to 0.06 up (a pad an animal
## stands on), and across the stall nothing rises above 0.06, so the cows and sheep and the items
## they stand by still sit right. The partitions and the stall's count (six) stay as they were.
func _straw_bedding() -> void:
	var bp: GDScript = load("res://scripts/world3d/barn_props.gd")
	var m := MapManager.data("barn")
	for p in m.props:
		if str(p.kind) != "stalls":
			continue
		var r := Rect2(Vector2(p.cell), Vector2(p.size))
		var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
		var mid := Vector3(r.get_center().x, 0, r.get_center().y)
		bp.prop(w, p, mid, r)
		var tris := PackedVector3Array()
		for n in w.get_children():
			if n is MeshInstance3D and n.mesh is ArrayMesh:
				var arr: Array = n.mesh.surface_get_arrays(0)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
				for i in idx:
					tris.append(v[i])
		var blocked := {}
		for b in p.get("blocks", []):
			blocked[int(b[0])] = true
		var stalls := 0
		var middle_ok := 0
		var over := 0
		var covered := 0
		var k := 0
		var n := int(r.size.x)
		while k < n:
			if blocked.has(k):
				k += 1
				continue
			var first := k
			while k < n and not blocked.has(k):
				k += 1
			stalls += 1
			var x_from := r.position.x + first
			var x_to := r.position.x + k
			var centre := _height_at(tris, Vector2((x_from + x_to) / 2.0, r.position.y + 0.5))
			if centre >= 0.02 and centre <= 0.06:
				middle_ok += 1
			for i in 5 * (k - first):
				for j in 5:
					var q := Vector2(x_from + 0.1 + (x_to - x_from - 0.2) * i / (5.0 * (k - first) - 1.0), r.position.y + 0.1 + 0.2 * j)
					var top := _height_at(tris, q)
					if top > 0.06:
						over += 1
					elif top >= 0.02:
						covered += 1
		check(stalls == 6, "the barn's stalls: six spaces between the partitions (%d)" % stalls)
		check(middle_ok == stalls, "barn stalls: the bedding's middle stands 0.02 to 0.06 up in every stall (%d of %d)" % [middle_ok, stalls])
		check(over == 0 and covered >= 60, "barn stalls: nothing in a stall rises above 0.06 (%d over), and the bedding covers the stalls (%d spots)" % [over, covered])
		w.free()


## The highest surface of `tris` (triangles, three points each) above the ground point `at`
## (x, z), or -1.0 if there is none: a vertical ray's hit on the upward faces.
func _height_at(tris: PackedVector3Array, at: Vector2) -> float:
	var best := -1.0
	for i in range(0, tris.size(), 3):
		var a := tris[i]
		var b := tris[i + 1]
		var c := tris[i + 2]
		var n := (b - a).cross(c - a)
		if absf(n.y) < 1e-9:
			continue
		# barycentric in x, z
		var d := (b.x - a.x) * (c.z - a.z) - (c.x - a.x) * (b.z - a.z)
		var u := ((at.x - a.x) * (c.z - a.z) - (c.x - a.x) * (at.y - a.z)) / d
		var v := ((b.x - a.x) * (at.y - a.z) - (at.x - a.x) * (b.z - a.z)) / d
		if u < -1e-6 or v < -1e-6 or u + v > 1.0 + 1e-6:
			continue
		best = maxf(best, a.y + u * (b.y - a.y) + v * (c.y - a.y))
	return best


## Trees (Trees): lit meshes wound to their normals, inside about 0.95 of the trunk (the
## wood scales its pines up to 1.3, still inside 1.0) and
## 2.3 high (the wood's margins count on it); broadleaf leaves by season, bare in winter,
## persimmons hanging in fall and winter, petals under a cherry in bloom; snow on the bare
## branches in winter and on the pines' tiers only when asked; the wood past the map's edge is MultiMeshes of the same pines with
## its snow driven by the world's set_snow.
func _trees() -> void:
	var trees: GDScript = load("res://scripts/world3d/trees.gd")
	# The flat view's maple picture keeps the 3D maple's colours (PlaceholderArt copies them, it does not load Trees).
	var flat_art: GDScript = load("res://scripts/art/placeholder_art.gd")
	for season in ["spring", "summer", "fall"]:
		check(flat_art.MAPLE_LEAVES[season] == trees.LEAVES.maple[season], "the flat maple's %s leaves are the 3D maple's" % season)
	check(flat_art.MAPLE_FLAME == trees.MAPLE_FLAME, "the flat maple's orange is the 3D maple's")
	check(not trees.LEAVES.maple.has("winter") or trees.LEAVES.maple.winter.a == 0.0, "the 3D maple is bare in winter, as the flat one")
	var parts_of := func(build: Callable) -> Node3D:
		var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
		var p = load("res://scripts/world3d/farm_props.gd").Parts.new()
		build.call(p)
		p.commit(w)
		return w
	var look := func(w: Node3D) -> Dictionary:
		var out := {"bad": 0, "colours": [], "snow": 0, "reach": 0.0, "top": 0.0}
		for n in w.get_children():
			if not n is MeshInstance3D:
				continue
			if not n.mesh is ArrayMesh:
				out.bad += 1
				continue
			var mat: Material = n.material_override
			if mat is ShaderMaterial:
				out.snow += 1
			elif mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				out.bad += 1
			else:
				out.colours.append(mat.albedo_color)
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				var c := (v[i + 1] - v[i]).cross(v[i + 2] - v[i])
				if c.length() > 1e-9 and c.dot(nm[i]) >= 0.0:
					out.bad += 1
			for q in v:
				out.reach = maxf(out.reach, Vector2(q.x, q.z).length())
				out.top = maxf(out.top, q.y)
		return out
	for kind in ["persimmon", "sakura", "maple"]:
		for season in ["spring", "summer", "fall", "winter"]:
			for seed in [3, 40]:
				var w: Node3D = parts_of.call(func(p): trees.broadleaf(p, Vector3.ZERO, kind, season, seed))
				var l: Dictionary = look.call(w)
				var leaf: Color = trees.LEAVES[kind][season]
				var leafy: bool = leaf in l.colours or leaf.darkened(0.14) in l.colours
				var fruit: bool = trees.FRUIT in l.colours
				check(l.bad == 0 and l.reach < 0.95 and l.top < 2.3, "%s in %s (seed %d): %d faults, reaches %.2f, %.2f high" % [kind, season, seed, l.bad, l.reach, l.top])
				check(leafy == (season != "winter"), "%s in %s: leaves %s" % [kind, season, leafy])
				check(fruit == (kind == "persimmon" and season in ["fall", "winter"]), "%s in %s: fruit %s" % [kind, season, fruit])
				check(kind != "maple" or ((trees.MAPLE_FLAME in l.colours or trees.MAPLE_FLAME.darkened(0.04) in l.colours) == (season == "fall")), "maple in %s: orange among the reds only in fall" % season)
				check((trees.PETAL in l.colours) == (kind == "sakura" and season == "spring"), "%s in %s: petals on the ground" % [kind, season])
				w.free()
	# Snow on the bare branches: a snow piece (driven by set_snow) in winter with snow, none
	# without snow, none in a leafy season; the sheets stay in the tree's reach and the winding
	# is right (the same look checks as above).
	for kind in ["persimmon", "sakura", "maple"]:
		for seed in [3, 40]:
			for case in [["winter", true], ["winter", false], ["spring", true]]:
				var w: Node3D = parts_of.call(func(p): trees.broadleaf(p, Vector3.ZERO, kind, case[0], seed, case[1]))
				var l: Dictionary = look.call(w)
				var snow_mesh: bool = false
				for n in w.get_children():
					if n is MeshInstance3D and n.material_override is ShaderMaterial and n.material_override in w._snow_mats:
						snow_mesh = true
				var want: bool = case[0] == "winter" and case[1]
				check(l.bad == 0 and l.reach < 0.95 and l.top < 2.3 and (l.snow > 0) == want and snow_mesh == want,
					"%s in %s (seed %d, snow %s): %d faults, reaches %.2f, %.2f high, %d snow" % [kind, case[0], seed, case[1], l.bad, l.reach, l.top, l.snow])
				w.free()
	for garden in [true, false]:
		for snow in [true, false]:
			var w: Node3D = parts_of.call(func(p): trees.pine(p, Vector3.ZERO, 7, garden, snow))
			var l: Dictionary = look.call(w)
			check(l.bad == 0 and l.reach * (1.0 if garden else 1.3) < 1.0 and l.top * 1.3 < 2.6 and (l.snow > 0) == snow and trees.NEEDLES[0] in l.colours,
				"pine (garden %s, snow %s): %d faults, reaches %.2f, %.2f high, %d snow" % [garden, snow, l.bad, l.reach, l.top, l.snow])
			w.free()
	var m: Node3D = load("res://scripts/world3d/map_world.gd").new()
	m.build(MapManager.data("kaminoda"))
	var wood: Array = m.surroundings.get_children().filter(func(n): return n is MultiMeshInstance3D)
	var instances := 0
	for n in wood:
		instances += n.multimesh.instance_count
	var driven: bool = not m.surroundings.snow_mats.is_empty() and m.surroundings.snow_mats.all(func(s): return s in m._snow_mats)
	check(wood.size() >= 4 and instances > 20 and driven, "the wood: %d MultiMeshes, %d pine parts, snow driven %s" % [wood.size(), instances, driven])
	m.free()


## The outdoor small props (OutdoorProps): bamboo, well, jizo, woodpile and river rock are lit
## meshes (no boxes / cylinders left in their cells), inside their cells, the faces turned out,
## the snow skins only where snow lies, the bamboo's colours by season, one mesh a clump
## (shared look, own yaw) swaying about its foot without leaving its cell.
func _outdoor_props() -> void:
	var op: GDScript = load("res://scripts/world3d/outdoor_props.gd")
	var g: Node = root.get_node("Game")
	var faults := func(w: Node3D) -> Dictionary:
		var out := {"bad": 0, "tris": 0, "lo": Vector3(1e9, 1e9, 1e9), "hi": Vector3(-1e9, -1e9, -1e9), "snow": 0, "unlit": 0, "prim": 0}
		for n in w.get_children():
			if not n is MeshInstance3D:
				continue
			if not n.mesh is ArrayMesh:
				out.prim += 1
				continue
			var mat: Material = n.material_override
			if mat is ShaderMaterial:
				out.snow += 1
			elif mat is StandardMaterial3D and mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				out.unlit += 1
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				out.tris += 1
				var c := (v[i + 1] - v[i]).cross(v[i + 2] - v[i])
				if c.length() > 1e-9 and c.dot(nm[i]) >= 0.0:
					out.bad += 1
			for q in v:
				var gq: Vector3 = n.transform * q
				out.lo = out.lo.min(gq)
				out.hi = out.hi.max(gq)
		return out
	var mid := Vector3(5.5, 0, 7.5)
	var new_world := func() -> Node3D:
		return load("res://scripts/world3d/farm_world.gd").new()
	# Bamboo: a clump is one lit mesh at its cell's middle, culms 2.2..3.6 high, nodes and
	# leaves in the season's colours, snow only where it lies, tips staying near the cell.
	var seen_culm := {}
	for season in ["spring", "summer", "fall", "winter"]:
		for snow in [false, true]:
			var w: Node3D = new_world.call()
			op.bamboo(w, mid, Vector2i(5, 7), season, snow)
			var f: Dictionary = faults.call(w)
			var rows: Dictionary = op.BAMBOO[season]
			var meshes := w.get_children().filter(func(n): return n is MeshInstance3D)
			var body: MeshInstance3D = meshes[0]
			var cols: PackedColorArray = body.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
			var culm := 0
			var node := 0
			var leaf := 0
			for col in cols:
				var rc: Color = rows.culm
				culm += 1 if absf(col.r - rc.r) < 0.08 and absf(col.g - rc.g) < 0.08 and absf(col.b - rc.b) < 0.08 else 0
				node += 1 if col.is_equal_approx(rows.node) else 0
				leaf += 1 if rows.leaves.any(func(l): return col.is_equal_approx(l)) else 0
			check(meshes.size() == (2 if snow else 1) and f.prim == 0 and f.unlit == 0 and f.bad == 0 and f.snow == (1 if snow else 0),
				"bamboo (%s, snow %s): %d mesh(es), %d primitives, %d unlit, %d facing faults, %d snow" % [season, snow, meshes.size(), f.prim, f.unlit, f.bad, f.snow])
			check(body.position == mid and body.material_override.vertex_color_use_as_albedo and node >= 40 and leaf >= 100 and culm >= 40,
				"bamboo (%s): at its cell, %d culm / %d node ring / %d leaf vertices" % [season, culm, node, leaf])
			check(f.hi.y > 2.2 and f.hi.y < 3.7 and f.lo.y >= -0.02 and f.lo.x > mid.x - 0.95 and f.hi.x < mid.x + 0.95 and f.lo.z > mid.z - 0.95 and f.hi.z < mid.z + 0.95,
				"bamboo (%s): %.2f..%.2f high, x %.2f..%.2f, z %.2f..%.2f" % [season, f.lo.y, f.hi.y, f.lo.x - mid.x, f.hi.x - mid.x, f.lo.z - mid.z, f.hi.z - mid.z])
			if snow:
				check(meshes[1].material_override in w._snow_mats, "bamboo (%s): snow skin driven by set_snow" % season)
			seen_culm[season] = rows.culm
			w.free()
	check(seen_culm["spring"] != seen_culm["summer"] and seen_culm["summer"] != seen_culm["fall"] and seen_culm["fall"] != seen_culm["winter"], "bamboo: a colour for each season")
	# Many clumps: the same shapes shared, each its own yaw; the sway leans them about their
	# feet and never moves a foot.
	var w: Node3D = new_world.call()
	for i in 6:
		op.bamboo(w, Vector3(i + 0.5, 0, 0.5), Vector2i(i, 0), "summer", false)
	var sway: Node = w.get_node(op.SWAY)
	var first: MeshInstance3D = w.get_children().filter(func(n): return n is MeshInstance3D)[0]
	var shapes := {}
	for n in w.get_children():
		if n is MeshInstance3D:
			shapes[n.mesh] = true
	check(sway.count() == 6 and shapes.size() <= op.CLUMP_LOOKS and shapes.size() >= 2, "bamboo: 6 clumps, %d shared shapes, one sway" % shapes.size())
	var before: Basis = first.basis
	sway.pose(0.7)
	var moved: bool = first.basis != before
	var at := first.position
	sway.pose(2.9)
	check(moved and first.position == at and absf(sway.angle_of(0)) <= 0.0281, "bamboo: the sway leans a clump (%s) about its foot, at most 0.028 rad" % moved)
	w.free()
	# The small props alone: all lit meshes inside their cells.
	var cell := Rect2(5, 7, 1, 1)
	for kind in ["well", "jizo", "river_rock"]:
		for snow in [false, true]:
			var pw: Node3D = new_world.call()
			match kind:
				"well": op.well(pw, mid)
				"jizo": op.jizo(pw, mid, snow)
				_: op.river_rock(pw, mid, snow)
			var f: Dictionary = faults.call(pw)
			var inside: bool = f.lo.x >= cell.position.x - 0.03 and f.hi.x <= cell.end.x + 0.03 and f.lo.z >= cell.position.y - 0.03 and f.hi.z <= cell.end.y + 0.03
			var want_snow: bool = snow or kind == "well"   # the well's roof always carries its snow layer
			check(f.prim == 0 and f.unlit == 0 and f.bad == 0 and f.tris > 100 and inside and (f.snow > 0) == want_snow,
				"%s (snow %s): %d tris, %d primitives, %d unlit, %d facing faults, inside %s, %d snow" % [kind, snow, f.tris, f.prim, f.unlit, f.bad, inside, f.snow])
			if kind == "well":
				check(f.hi.y > 1.4 and f.hi.y < 1.9, "well: roof at %.2f" % f.hi.y)
			elif kind == "jizo":
				check(f.hi.y > 0.6 and f.hi.y < 0.8, "jizo: %.2f high" % f.hi.y)
			else:
				check(f.hi.y > 0.2 and f.hi.y < 0.5, "river rock: %.2f high" % f.hi.y)
			pw.free()
	for length in [1, 2]:
		var r := Rect2(5, 7, length, 1)
		for snow in [false, true]:
			var pw: Node3D = new_world.call()
			op.woodpile(pw, r, Vector3(r.get_center().x, 0, r.get_center().y), snow)
			var f: Dictionary = faults.call(pw)
			var inside: bool = f.lo.x >= r.position.x - 0.03 and f.hi.x <= r.end.x + 0.03 and f.lo.z >= r.position.y - 0.03 and f.hi.z <= r.end.y + 0.03
			check(f.prim == 0 and f.unlit == 0 and f.bad == 0 and f.tris > 200 and inside and (f.snow > 0) == snow and f.hi.y > 0.9 and f.hi.y < 1.1,
				"woodpile %dx1 (snow %s): %d tris, %d primitives, %d facing faults, inside %s, %d snow, %.2f high" % [length, snow, f.tris, f.prim, f.bad, inside, f.snow, f.hi.y])
			pw.free()
	# Ichiro's kiln (2 x 2): lit meshes inside its cells, a low dome under its chimney, snow
	# skins only where snow lies, the two thumbprints over its mouth.
	var kr := Rect2(5, 7, 2, 2)
	for snow in [false, true]:
		var pw: Node3D = new_world.call()
		op.kiln(pw, kr, Vector3(kr.get_center().x, 0, kr.get_center().y), snow)
		var f: Dictionary = faults.call(pw)
		var inside: bool = f.lo.x >= kr.position.x - 0.03 and f.hi.x <= kr.end.x + 0.03 and f.lo.z >= kr.position.y - 0.03 and f.hi.z <= kr.end.y + 0.03
		var marks := pw.get_children().filter(func(n): return n is MeshInstance3D and n.material_override is StandardMaterial3D and n.material_override.albedo_color == Color("4a2e1c")).size()
		check(f.prim == 0 and f.unlit == 0 and f.bad == 0 and f.tris > 200 and inside and (f.snow > 0) == snow and f.hi.y > 0.95 and f.hi.y < 1.1 and marks == 2,
			"kiln (snow %s): %d tris, %d primitives, %d facing faults, inside %s, %d snow, %.2f high, %d thumbprints" % [snow, f.tris, f.prim, f.bad, inside, f.snow, f.hi.y, marks])
		pw.free()
	for i in 3:
		var spot: Vector3 = op.kiln_mark_at(kr, i)
		check(absf(spot.x - kr.get_center().x) + 0.1 < 0.47 and spot.y > 0.5 and spot.y < 0.7 and spot.z > kr.get_center().y + 0.75 and spot.z < kr.end.y,
			"thumbprint %d sits on the kiln's face over the mouth (%s)" % [i, spot])
	# The old kiln's wear: one lit mesh of cracks and a chip in a dark colour, flat on the face
	# (in the footprint, facing the front); the finished new kiln has none.
	var seam_color := Color("2e1d12")
	var seams := func(w: Node3D) -> int:
		return w.get_children().filter(func(n): return n is MeshInstance3D and n.material_override is StandardMaterial3D and n.material_override.albedo_color == seam_color).size()
	var worn_pw: Node3D = new_world.call()
	op.kiln(worn_pw, kr, Vector3(kr.get_center().x, 0, kr.get_center().y), false)
	var wf: Dictionary = faults.call(worn_pw)
	var slo := Vector3(1e9, 1e9, 1e9)
	var shi := Vector3(-1e9, -1e9, -1e9)
	for n in worn_pw.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.material_override is StandardMaterial3D and n.material_override.albedo_color == seam_color:
			for v in n.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
				slo = slo.min(v)
				shi = shi.max(v)
	check(seams.call(worn_pw) == 1 and wf.bad == 0 and wf.prim == 0 and wf.unlit == 0 and slo.x > kr.position.x and shi.x < kr.end.x
		and slo.z > kr.get_center().y + 0.7 and shi.z < kr.end.y and slo.y > 0.2 and shi.y < 0.7,
		"the old kiln's cracks and chip: one lit mesh of seams on the face (%s .. %s)" % [slo, shi])
	worn_pw.free()
	var new_pw: Node3D = new_world.call()
	op.kiln(new_pw, kr, Vector3(kr.get_center().x, 0, kr.get_center().y), false, [1], false)
	check(seams.call(new_pw) == 0, "the finished new kiln has no cracks")
	new_pw.free()
	var bw: Node3D = new_world.call()
	op.jizo_bibs(bw, mid)
	var bf: Dictionary = faults.call(bw)
	check(bf.prim == 0 and bf.unlit == 0 and bf.bad == 0 and bf.lo.x > 5.3 and bf.hi.x < 5.7 and bf.lo.z > 7.39 and bf.hi.z < 7.7
		and bf.lo.y > 0.15 and bf.hi.y < 0.5, "the jizo's new bib and tie: lit meshes on his chest and neck (%s .. %s)" % [bf.lo, bf.hi])
	bw.free()
	# On the maps: no box or cylinder left in the cells of these props, and a bamboo mesh for
	# every clump in the data.
	var spots := {"hill": ["bamboo"], "kaminoda": ["well", "jizo", "woodpile", "bamboo"], "river": ["river_rock"],
		"minamino": ["well", "jizo", "woodpile", "bamboo", "hen_barn", "ditch"], "sakurazaka": ["jizo", "woodpile", "bamboo", "kiln"]}
	for id in spots:
		var m: Node3D = load("res://scripts/world3d/map_world.gd").new()
		m.build(MapManager.data(id))
		var stray := 0
		var clumps := 0
		var rects: Array[Rect2] = []
		for p in MapManager.data(id).props:
			if str(p.kind) in spots[id]:
				rects.append(Rect2(Vector2(p.cell), Vector2(p.get("size", [1, 1]))))
		for n in m.get_children():
			if n is MeshInstance3D and n.mesh is ArrayMesh and n.material_override is StandardMaterial3D and n.material_override.vertex_color_use_as_albedo:
				clumps += 1
			if n is MeshInstance3D and (n.mesh is BoxMesh or n.mesh is CylinderMesh or n.mesh is SphereMesh):
				var q: Vector3 = n.position
				for r in rects:
					if r.has_point(Vector2(q.x, q.z)) and q.y < 1.6:
						stray += 1
		var want_clumps: int = MapManager.data(id).props.filter(func(p): return p.kind == "bamboo").size()
		check(clumps == want_clumps and stray == 0, "%s: %d bamboo meshes for %d clumps, %d boxes / cylinders left in the props' cells" % [id, clumps, want_clumps, stray])
		m.free()


## What a built world holds: mesh instances only as ArrayMeshes (no BoxMesh / cylinder / sphere
## left), triangles facing their normals, the bounds in world space, the snow-driven skins and
## the unshaded (glow) ones.
func _mesh_report(w: Node3D) -> Dictionary:
	var out := {"bad": 0, "tris": 0, "lo": Vector3(1e9, 1e9, 1e9), "hi": Vector3(-1e9, -1e9, -1e9), "snow": 0, "unlit": 0, "prim": 0}
	for n in w.get_children():
		if not n is MeshInstance3D:
			continue
		if not n.mesh is ArrayMesh:
			out.prim += 1
			continue
		var mat: Material = n.material_override
		if mat is ShaderMaterial:
			out.snow += 1
		elif mat is StandardMaterial3D and mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
			out.unlit += 1
		var arr: Array = n.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		for i in range(0, v.size(), 3):
			out.tris += 1
			var c := (v[i + 1] - v[i]).cross(v[i + 2] - v[i])
			if c.length() > 1e-9 and c.dot(nm[i]) >= 0.0:
				out.bad += 1
		for q in v:
			var gq: Vector3 = n.transform * q
			out.lo = out.lo.min(gq)
			out.hi = out.hi.max(gq)
	return out


## The farm's bamboo fence and the New Year bamboo as lit meshes: no box or cylinder left, faces
## turned out, the fence on its line (posts at the border cells' middles, 0.64 high, rails and
## canes inside them), cut at the gate, snow skins driven by set_snow; the kadomatsu with three
## cut culms of different heights (a pale cut face each), node rings, pine, snow only where it
## lies, and inside its cell.
func _bamboo_pieces() -> void:
	var fm: GDScript = load("res://scripts/world3d/festival_meshes.gd")
	var farm_script: GDScript = load("res://scripts/world3d/farm_world.gd")
	var W := float(FarmGrid.W)
	var H := float(FarmGrid.H)
	var counts := []
	for gate in [false, true]:
		var w: Node3D = farm_script.new()
		if gate:
			w.gaps.append(Vector2i(0, 5))
		w._make_fence()
		var rep: Dictionary = _mesh_report(w)
		counts.append(rep.tris)
		var snow_ok: bool = rep.snow == 1 and w.get_children().all(func(n): return not (n is MeshInstance3D and n.material_override is ShaderMaterial) or n.material_override in w._snow_mats)
		check(rep.prim == 0 and rep.unlit == 0 and rep.bad == 0 and rep.tris > 20000 and snow_ok,
			"fence (gate %s): %d tris, %d primitives, %d unlit, %d facing faults, snow skin driven %s" % [gate, rep.tris, rep.prim, rep.unlit, rep.bad, snow_ok])
		check(rep.lo.x > 0.5 - 0.15 and rep.hi.x < W - 0.5 + 0.15 and rep.lo.z > 0.5 - 0.15 and rep.hi.z < H - 0.5 + 0.15 and rep.lo.y >= -0.02
			and rep.hi.y > 0.66 and rep.hi.y < 0.72, "fence line and height: x %.2f..%.2f, z %.2f..%.2f, y %.2f..%.2f" % [rep.lo.x, rep.hi.x, rep.lo.z, rep.hi.z, rep.lo.y, rep.hi.y])
		var in_gate := 0
		for n in w.get_children():
			if n is MeshInstance3D and n.mesh is ArrayMesh:
				for q in n.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
					if absf(q.x - 0.5) < 0.2 and q.z > 5.0 and q.z < 6.0:
						in_gate += 1
		check((in_gate == 0) == gate, "fence: %d vertices in the gate cell (gate %s)" % [in_gate, gate])
		w.free()
	check(counts[1] < counts[0], "fence: the gate takes pieces out (%d < %d tris)" % [counts[1], counts[0]])
	var mid := Vector3(5.5, 0, 7.5)
	for snow in [false, true]:
		var w: Node3D = farm_script.new()
		fm.kadomatsu(w, mid, snow)
		var rep: Dictionary = _mesh_report(w)
		var cut := 0
		var rings := 0
		for n in w.get_children():
			if not n is MeshInstance3D:   # the world's WindSway
				continue
			var mat: Material = n.material_override
			if mat is StandardMaterial3D and mat.albedo_color.is_equal_approx(Color("d8e8b0")):
				cut += n.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
			if mat is StandardMaterial3D and mat.albedo_color.is_equal_approx(fm.KADO_NODE):
				rings += n.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
		check(rep.prim == 0 and rep.unlit == 0 and rep.bad == 0 and rep.tris > 600 and rep.snow == (6 if snow else 0),
			"kadomatsu (snow %s): %d tris, %d primitives, %d unlit, %d facing faults, %d snow skins" % [snow, rep.tris, rep.prim, rep.unlit, rep.bad, rep.snow])
		check(cut == 3 * 8 * 3 and rings >= 3 * 96 and rep.hi.y > 1.3 and rep.hi.y < 1.45 and rep.lo.y >= -0.03
			and rep.lo.x > mid.x - 0.6 and rep.hi.x < mid.x + 0.6 and rep.lo.z > mid.z - 0.6 and rep.hi.z < mid.z + 0.6,
			"kadomatsu: 3 cut faces (%d verts), %d node ring vertices, %.2f..%.2f high, inside its cell" % [cut, rings, rep.lo.y, rep.hi.y])
		w.free()


## The farm-country props (FieldProps): the drying rack, the kitchen garden and the board fence
## as lit meshes on every map that has them, inside their cells and as high as the boxes were,
## their faces turned out, no box left on the maps, snow only where it lies, the fall straw on
## the rack, the winter garden bare.
func _field_props() -> void:
	var fp: GDScript = load("res://scripts/world3d/field_props.gd")
	var new_world := func() -> Node3D:
		return load("res://scripts/world3d/farm_world.gd").new()
	var tris := {}
	var seen := {}
	for id in ["kaminoda", "minamino", "sakurazaka", "town"]:
		for p in MapManager.data(id).props:
			var kind := str(p.kind)
			if not kind in ["hasa", "garden", "wood_fence"]:
				continue
			seen[kind] = true
			var r := Rect2(Vector2(p.cell), Vector2(p.get("size", [1, 1])))
			var mid := Vector3(r.get_center().x, 0, r.get_center().y)
			for season in ["spring", "fall", "winter"]:
				for snow in [false, true]:
					var w: Node3D = new_world.call()
					match kind:
						"hasa": fp.hasa(w, r, mid, season, snow)
						"garden": fp.garden(w, r, mid, season, snow)
						_: fp.board_fence(w, r, mid, snow)
					var f: Dictionary = _mesh_report(w)
					var inside: bool = f.lo.x >= r.position.x - 0.03 and f.hi.x <= r.end.x + 0.03 and f.lo.z >= r.position.y - 0.03 and f.hi.z <= r.end.y + 0.03
					var high := {"hasa": [1.4, 1.5], "garden": [0.12, 0.45], "wood_fence": [0.68, 0.78]}[kind] as Array
					check(f.prim == 0 and f.unlit == 0 and f.bad == 0 and f.tris > 50 and inside and f.lo.y >= -0.01 and f.hi.y > high[0] and f.hi.y < high[1] and (f.snow > 0) == snow,
						"%s %s %s (%s, snow %s): %d tris, %d primitives, %d unlit, %d facing faults, inside %s, %.2f..%.2f high, %d snow" % [id, kind, r, season, snow, f.tris, f.prim, f.unlit, f.bad, inside, f.lo.y, f.hi.y, f.snow])
					if not snow:
						tris["%s|%s|%d|%d" % [kind, season, r.size.x, r.size.y]] = f.tris
					w.free()
	check(seen.size() == 3, "all three kinds sit on the maps checked (%s)" % [seen.keys()])
	var hasa_key := func(season: String) -> int:
		for k in tris:
			if k.begins_with("hasa|" + season):
				return tris[k]
		return 0
	check(hasa_key.call("fall") > hasa_key.call("spring") + 1000, "the rack carries sheaves in fall (%d tris against %d in spring)" % [hasa_key.call("fall"), hasa_key.call("spring")])
	var garden_key := func(season: String) -> int:
		for k in tris:
			if k.begins_with("garden|" + season):
				return tris[k]
		return 0
	check(garden_key.call("winter") < garden_key.call("spring") / 2 and garden_key.call("winter") > 20, "the garden is bare in winter (%d tris against %d in spring)" % [garden_key.call("winter"), garden_key.call("spring")])
	# On the maps themselves: no box left in the cells of these props.
	for id in ["kaminoda", "minamino"]:
		var m: Node3D = load("res://scripts/world3d/map_world.gd").new()
		m.build(MapManager.data(id))
		var rects: Array[Rect2] = []
		for p in MapManager.data(id).props:
			if str(p.kind) in ["hasa", "garden", "wood_fence"]:
				rects.append(Rect2(Vector2(p.cell), Vector2(p.get("size", [1, 1]))))
		var stray := 0
		for n in m.get_children():
			if n is MeshInstance3D and (n.mesh is BoxMesh or n.mesh is CylinderMesh or n.mesh is SphereMesh):
				for r in rects:
					if r.has_point(Vector2(n.position.x, n.position.z)) and n.position.y < 1.6:
						stray += 1
		check(not rects.is_empty() and stray == 0, "%s: %d boxes / cylinders left in the cells of %d racks, gardens and fences" % [id, stray, rects.size()])
		m.free()


## The festival decorations (FestivalMeshes): every prop of every festival as lit meshes only
## (the paper of the lanterns and the flame unshaded), faces turned out, near their cells and as
## tall as before, the lights (glows) listed as before (the wares: `_stall_wares`).
func _festival_meshes() -> void:
	var fprops: GDScript = load("res://scripts/world3d/festival_props.gd")
	var kinds := {}
	var tall := {"stall": [1.5, 1.9], "judge_table": [1.25, 1.4], "lantern_line": [1.85, 2.0], "drum_stage": [1.5, 1.8], "moon_table": [0.6, 0.8],
		"pampas": [1.3, 1.6], "paper_lantern": [1.4, 1.6], "kadomatsu": [1.2, 1.45], "bonfire": [0.5, 0.9], "mochi_usu": [0.8, 1.0],
		"race_flag": [1.6, 1.8], "picnic_mat": [0.1, 0.25], "red_mat": [0.1, 0.25]}
	for fest in Festivals.all():
		var data: Dictionary = Festivals.get_festival(fest)
		for p in data.get("props", []):
			var kind := str(p.kind)
			if not tall.has(kind):
				continue
			var fpn: Node3D = fprops.new(str(data.get("map", "town")))
			fpn.festival = fest
			fpn._make(p)
			var r := Rect2(Vector2(p.cell[0], p.cell[1]), Vector2(p.get("size", [1, 1])[0], p.get("size", [1, 1])[1]))
			var rep: Dictionary = _mesh_report(fpn)
			var near: bool = rep.lo.x >= r.position.x - 0.6 and rep.hi.x <= r.end.x + 0.6 and rep.lo.z >= r.position.y - 0.7 and rep.hi.z <= r.end.y + 0.7
			var band: Array = tall[kind]
			kinds[kind] = true
			check(rep.prim == 0 and rep.bad == 0 and rep.tris > 100 and near and rep.lo.y >= -0.03 and rep.hi.y >= band[0] and rep.hi.y <= band[1],
				"%s %s at %s: %d tris, %d primitives, %d facing faults, near its cell %s, %.2f..%.2f high" % [fest, kind, r, rep.tris, rep.prim, rep.bad, near, rep.lo.y, rep.hi.y])
			var glowing: bool = kind in ["stall", "lantern_line", "drum_stage", "paper_lantern", "bonfire"]
			check((fpn.glows.size() > 0) == glowing, "%s: lights listed (%d)" % [kind, fpn.glows.size()])
			# Unshaded parts exist only on the lantern paper and the flame.
			var paper: bool = kind in ["stall", "lantern_line", "paper_lantern", "bonfire"]
			check((rep.unlit > 0) == paper, "%s: %d unshaded parts" % [kind, rep.unlit])
			fpn.free()
	check(kinds.size() >= 12, "festival kinds checked: %d" % kinds.size())


## The festival stalls' wares (StallWares): every item any stall sells has a mesh; each selling
## stall of every festival sets its stock out as one lit vertex-coloured mesh (no pictures left),
## faces turned out, on the counter top between the posts and under the curtain's hem, no taller
## than TALL; steam over each hot item, rising and fading; the wind chimes' strips blow in the
## wind with the curtain; the lights unchanged (one per stall); an item without a mesh keeps its
## picture in its slot.
func _stall_wares() -> void:
	var fprops: GDScript = load("res://scripts/world3d/festival_props.gd")
	var sw: GDScript = load("res://scripts/world3d/stall_wares.gd")
	var stalls := 0
	for fest in Festivals.all():
		var data: Dictionary = Festivals.get_festival(fest)
		for s in Festivals.stalls(fest):
			var items: Array = s.get("stock", []).map(func(it: Dictionary) -> String: return str(it.item))
			var no_look := items.filter(func(it: String) -> bool: return not sw.has_look(it))
			check(no_look.is_empty(), "%s: every ware has a mesh (%s without)" % [fest, no_look])
			var prop: Dictionary = {}
			for p in data.get("props", []):
				if str(p.kind) == "stall" and Festivals.stall_of_prop(fest, p) == s:
					prop = p
			if prop.is_empty():
				check(false, "%s: the stall at %s has a prop" % [fest, s.cell])
				continue
			stalls += 1
			var fpn: Node3D = fprops.new(str(data.get("map", "town")))
			fpn.festival = fest
			fpn._make(prop)
			var r := Rect2(Vector2(prop.cell[0], prop.cell[1]), Vector2(prop.size[0], prop.size[1]))
			var mid := Vector3(r.get_center().x, 0, r.get_center().y)
			var sprites := fpn.get_children().filter(func(n): return n is Sprite3D).size()
			var ware_meshes := fpn.get_children().filter(func(n): return n is MeshInstance3D and n.has_meta("wares"))
			var steams := fpn.get_children().filter(func(n): return n is Node3D and n.has_method("strength"))
			var hot := items.filter(func(it: String) -> bool: return it in sw.STEAMING).size()
			check(sprites == 0 and ware_meshes.size() == 1 and fpn.wares == items.size(),
				"%s %s: %d pictures, %d ware meshes, %d wares counted (%d sold)" % [fest, s.get("id", ""), sprites, ware_meshes.size(), fpn.wares, items.size()])
			if ware_meshes.size() != 1:
				fpn.free()
				continue
			var mi: MeshInstance3D = ware_meshes[0]
			var mat: StandardMaterial3D = mi.material_override
			var arr: Array = mi.mesh.surface_get_arrays(0)
			var lo := Vector3(1e9, 1e9, 1e9)
			var hi := -lo
			var bad := 0
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				var c := (v[i + 1] - v[i]).cross(v[i + 2] - v[i])
				if c.length() > 1e-9 and c.dot(nm[i]) >= 0.0:
					bad += 1
			for q in v:
				lo = lo.min(q)
				hi = hi.max(q)
			var colours := {}
			for c in (arr[Mesh.ARRAY_COLOR] as PackedColorArray):
				colours[c.to_html(false)] = true
			check(mi.get_meta("wares") == items and mat.vertex_color_use_as_albedo and mat.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED
					and colours.size() >= 6 and bad == 0 and v.size() / 3 > 300,
				"%s %s: wares %s as one lit mesh, %d tris, %d colours, %d facing faults" % [fest, s.get("id", ""), mi.get_meta("wares"), v.size() / 3, colours.size(), bad])
			var wd := r.size.x - 0.2   # FestivalMeshes.stall: posts at mid.x +- wd / 2, the counter top z -0.43..0.23
			var on_counter: bool = lo.y >= sw.COUNTER_TOP - 0.03 and hi.y <= sw.COUNTER_TOP + sw.TALL and hi.y < 1.25 - 0.2 \
				and lo.x >= mid.x - wd / 2 + 0.03 and hi.x <= mid.x + wd / 2 - 0.03 and lo.z >= mid.z - 0.43 and hi.z <= mid.z + 0.23
			check(on_counter, "%s %s: wares on the counter, x %.2f..%.2f (posts %.2f / %.2f), y %.3f..%.3f, z %.2f..%.2f (counter %.2f..%.2f)" % [
				fest, s.get("id", ""), lo.x, hi.x, mid.x - wd / 2, mid.x + wd / 2, lo.y, hi.y, lo.z, hi.z, mid.z - 0.43, mid.z + 0.23])
			check(steams.size() == hot, "%s %s: steam over %d hot wares (%d)" % [fest, s.get("id", ""), hot, steams.size()])
			for st in steams:
				var before: Vector3 = st.get_child(0).position
				var a0: float = st.strength()
				st._process(0.4)
				check(st.get_child(0).position != before and st.strength() > 0.0 and st.strength() <= 3 * 0.6 and a0 > 0.0,
					"%s: steam moves and fades (%.2f then %.2f)" % [fest, a0, st.strength()])
			check(fpn.glows.size() == 1 and fpn.glows[0].pool == "stall", "%s %s: the stall's one light (%d)" % [fest, s.get("id", ""), fpn.glows.size()])
			var sway: Node = fpn.get_node_or_null("WindSway")   # OutdoorProps.SWAY
			var cloth: int = sway.count_of("cloth") if sway != null else 0
			var strips := 2 if "keep:wind_chime" in items else 0
			var pieces := maxi(2, int((r.size.x - 0.2) / 0.3))
			check(cloth == pieces + strips, "%s %s: %d cloth pieces in the wind (curtain %d, chime strips %d)" % [fest, s.get("id", ""), cloth, pieces, strips])
			fpn.free()
	check(stalls >= 7, "selling stalls checked: %d" % stalls)
	# The stalls that sell nothing set out a display (goldfish tub, masks): one lit mesh on the counter,
	# under TALL, clear of the posts and the lantern, no shop; the goldfish swim and wiggle in the tub.
	var shown := {}
	for fest in Festivals.all():
		var data: Dictionary = Festivals.get_festival(fest)
		for prop in data.get("props", []):
			if str(prop.kind) != "stall" or not prop.has("display"):
				continue
			var kind := str(prop.display)
			shown[kind] = true
			check(kind in sw.DISPLAYS and Festivals.stall_of_prop(fest, prop).is_empty(), "%s: the %s display is on a stall that sells nothing" % [fest, kind])
			var dn: Node3D = fprops.new(str(data.get("map", "town")))
			dn.festival = fest
			dn._make(prop)
			var dr := Rect2(Vector2(prop.cell[0], prop.cell[1]), Vector2(prop.size[0], prop.size[1]))
			var dmid := Vector3(dr.get_center().x, 0, dr.get_center().y)
			var meshes := dn.get_children().filter(func(n): return n is MeshInstance3D and n.has_meta("display"))
			check(meshes.size() == 1 and meshes[0].get_meta("display") == kind and dn.wares == 0
				and dn.get_children().filter(func(n): return n is Sprite3D).is_empty(), "%s %s: one display mesh, no wares, no pictures (%d)" % [fest, kind, meshes.size()])
			if meshes.size() == 1:
				var arr: Array = meshes[0].mesh.surface_get_arrays(0)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				var lo := Vector3(1e9, 1e9, 1e9)
				var hi := -lo
				var bad := 0
				for i in range(0, v.size(), 3):
					var c := (v[i + 1] - v[i]).cross(v[i + 2] - v[i])
					if c.length() > 1e-9 and c.dot(nm[i]) >= 0.0:
						bad += 1
				for q in v:
					lo = lo.min(q)
					hi = hi.max(q)
				var colours := {}
				for c in (arr[Mesh.ARRAY_COLOR] as PackedColorArray):
					colours[c.to_html(false)] = true
				var wd := dr.size.x - 0.2
				var mat: StandardMaterial3D = meshes[0].material_override
				check(mat.vertex_color_use_as_albedo and mat.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED and colours.size() >= 6 and bad == 0 and v.size() / 3 > 300,
					"%s %s: a lit vertex-coloured mesh, %d tris, %d colours, %d facing faults" % [fest, kind, v.size() / 3, colours.size(), bad])
				check(lo.y >= sw.COUNTER_TOP - 0.03 and hi.y <= sw.COUNTER_TOP + sw.TALL and hi.y < 1.25 - 0.2 and lo.x >= dmid.x - wd / 2 + 0.03 and hi.x <= dmid.x + wd / 2 - 0.3
						and lo.z >= dmid.z - 0.43 and hi.z <= dmid.z + 0.23,
					"%s %s: on the counter, clear of the lantern, x %.2f..%.2f, y %.3f..%.3f, z %.2f..%.2f" % [fest, kind, lo.x, hi.x, lo.y, hi.y, lo.z, hi.z])
			var swimmers := dn.get_children().filter(func(n): return n is Node3D and n.has_method("positions"))
			check(swimmers.size() == (1 if kind == "goldfish" else 0), "%s %s: swimming fish %d" % [fest, kind, swimmers.size()])
			for sn in swimmers:
				var before: Array = sn.positions()
				sn._process(0.5)
				var after: Array = sn.positions()
				var moved := 0
				var inside := true
				var fish: Array = sn.get_children().filter(func(n): return n is MeshInstance3D and n.mesh.get_surface_count() > 0 and n.material_override.vertex_color_use_as_albedo)
				for i in before.size():
					moved += 1 if before[i] != after[i] else 0
					inside = inside and Vector2(after[i].x, after[i].z).length() < 0.185 and after[i].y < sn.WATER_Y
				check(before.size() >= 3 and moved == before.size() and inside and fish.size() == before.size(),
					"%s: %d goldfish swim round in the tub and stay under its water (%d moved)" % [fest, before.size(), moved])
				var yaw0: float = fish[0].rotation.y
				sn._process(0.3)
				check(not is_equal_approx(fish[0].rotation.y, yaw0), "%s: a goldfish wiggles as it swims" % fest)
			dn.free()
	check(shown.size() == sw.DISPLAYS.size(), "every display is used: %s" % [shown.keys()])
	check(Festivals.get_festival("lantern_night").props.filter(func(p): return p.kind == "stall").all(func(p): return p.has("display") or not Festivals.stall_of_prop("lantern_night", p).is_empty()),
		"no Lantern Night stall is bare")
	# An item with no mesh keeps its picture in its slot.
	var w: Node3D = fprops.new("town")
	w._wares(Vector3(10, 0, 7.5), Rect2(9, 7, 2, 1), {"stock": [{"item": "food:dango"}, {"item": "food:milk"}]})
	var pics := w.get_children().filter(func(n): return n is Sprite3D)
	check(w.wares == 2 and pics.size() == 1 and absf(pics[0].position.x - sw.slot(Vector3(10, 0, 7.5), Rect2(9, 7, 2, 1), 1, 2).x) < 0.001,
		"an item with no mesh keeps its picture (%d wares, %d pictures)" % [w.wares, pics.size()])
	w.free()


## Grass tufts (GrassTufts): the same tufts for a cell every time, inside it; on a map only
## on free grass cells with no prop, each carrying its cell's snow hold, the material driven
## by set_snow; the apron grows them too; none indoors; on the farm none on tilled ground,
## things or fixed cells, and tilling a cell clears its tufts.
func _grass() -> void:
	var gt: GDScript = load("res://scripts/world3d/grass_tufts.gd")
	var cells: Array[Vector2i] = []
	for i in 200:
		cells.append(Vector2i(i % 20, i / 20))
	var spots: Array = gt.spots_for(cells)
	var inside := spots.all(func(s): return Rect2(Vector2(s.cell), Vector2.ONE).grow(-0.1).has_point(Vector2(s.pos.x, s.pos.z)))
	var share := spots.size() / float(cells.size() * gt.PER_CELL) * 100.0
	check(inside and absf(share - gt.SHARE) < 10 and gt.spots_for(cells) == spots,
		"tufts inside their cells, %.0f%% of the places (%d%% wanted), the same each time" % [share, gt.SHARE])
	var tuft_cells := func(t: MultiMeshInstance3D) -> Array:
		var out := []
		for sp in t.planted:
			out.append([Vector2i(int(floor(sp.pos.x)), int(floor(sp.pos.z))), sp.hold])
		return out
	var m := MapManager.data("kaminoda")
	var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
	w.build(m)
	var bad := 0
	var hold_wrong := 0
	var rules: Dictionary = root.get_node("Game").snow_rules
	for e in tuft_cells.call(w.tufts):
		var c: Vector2i = e[0]
		if m.tile(c) != "grass" or not m.prop_at(c).is_empty() or m.is_solid(c):
			bad += 1
		if absf(e[1] - SnowLayer.map_hold(m, c, rules)) > 0.01:
			hold_wrong += 1
	var apron: Array = w.surroundings.get_children().filter(func(n): return n is MultiMeshInstance3D and n.get_script() == gt)
	check(w.tufts.multimesh.instance_count > 100 and bad == 0 and hold_wrong == 0 and w.tufts.snow_material() in w._snow_mats,
		"kaminoda: %d tufts, %d off free grass, %d with the wrong snow hold" % [w.tufts.multimesh.instance_count, bad, hold_wrong])
	check(apron.size() == 1 and apron[0].multimesh.instance_count > 100 and apron[0].snow_material() in w._snow_mats,
		"the apron past kaminoda's edge grows tufts, their snow driven")
	w.free()
	var house: Node3D = load("res://scripts/world3d/map_world.gd").new()
	house.build(MapManager.data("house"))
	check(house.tufts == null, "no grass tufts indoors")
	house.free()
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var farm := FarmGrid.new(crops)
	farm.generate(RandomNumberGenerator.new())
	var fw: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	fw.setup(farm)
	var on_bad := func() -> int:
		var n := 0
		for e in tuft_cells.call(fw.tufts):
			var d: Dictionary = farm.cell(e[0])
			if farm.fixed_at(e[0]) != "" or d.tilled or d.obj != FarmGrid.Obj.NONE or d.crop != "" or farm.items.has(e[0]):
				n += 1
		return n
	var grown: Array = tuft_cells.call(fw.tufts).map(func(e): return e[0])
	var target := Vector2i(-1, -1)
	for c in grown:
		if farm.can_farm(c) and farm.cell(c).obj == FarmGrid.Obj.NONE:
			target = c
			break
	check(fw.tufts.multimesh.instance_count > 100 and on_bad.call() == 0, "the farm: %d tufts, %d on tilled ground or things" % [fw.tufts.multimesh.instance_count, on_bad.call()])
	check(target != Vector2i(-1, -1) and farm.till(target), "a grassy farm cell can be tilled")
	var after: Array = tuft_cells.call(fw.tufts).map(func(e): return e[0])
	check(not target in after and on_bad.call() == 0, "tilling %s cleared its tufts" % [target])
	fw.free()


## Tall crops (CropClusters): only rice and corn past the sprout stand as clusters, the rest
## (and their seeds and sprouts) stay one sprite a cell; the plants stay inside their cell,
## the same each time, rice in nine hills (six young), corn in three stalks; the pictures are
## small single plants, ripe rice gold-eared; on the farm a cluster cell has no sprite and a
## harvest takes its plants away; the village paddies grow rice by the season (cut stubble in
## winter, with its grey-blue water patches, _paddy_winter), each plant carrying the paddy's snow
## hold, the cover driven by set_snow.
## Grass and tall crops part round the farmer (Parting): the push math, the data, the shader
## code and the `farmer` uniform reaching every tuft and crop material through FarmWorld.
func _parting() -> void:
	var pt: GDScript = load("res://scripts/world3d/parting.gd")
	var part: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/wind.json")).get("part", {})
	var radius := float(part.get("radius", 0.0))
	var bend: Dictionary = part.get("bend", {})
	check(radius >= 0.7 and radius <= 1.5 and float(bend.get("grass", 0)) > 0.0 and float(bend.get("crops", 0)) > float(bend.get("grass", 0))
		and float(part.get("dip", -1)) >= 0.0 and float(part.get("dip", 2)) <= 1.0 and float(part.get("full", -1)) >= 0.0 and float(part.get("full", 1)) < 0.8,
		"parting: data/wind.json has a radius of about a cell (%.2f), a bend for grass and a bigger one for crops, a dip 0..1, a full share under 0.8" % radius)
	var g: Dictionary = pt.rules("grass")
	var c: Dictionary = pt.rules("crops")
	check(is_equal_approx(g.radius, radius) and is_equal_approx(g.bend, float(bend.grass)) and is_equal_approx(c.bend, float(bend.crops)),
		"parting: Parting.rules reads the data (grass %.2f, crops %.2f)" % [g.bend, c.bend])
	var feet := Vector2(5.5, 5.5)
	var at := func(dx: float, dz: float) -> Vector2:
		return pt.push(feet + Vector2(dx, dz), feet, 1.0, 0.2, 0.3)
	check(at.call(1.0, 0.0) == Vector2.ZERO and at.call(0.0, 1.3) == Vector2.ZERO and at.call(-3.0, 2.0) == Vector2.ZERO,
		"parting: nothing bends from the radius out")
	var right: Vector2 = at.call(0.3, 0.0)
	var up: Vector2 = at.call(0.0, -0.3)
	var diag: Vector2 = at.call(-0.4, 0.4)
	check(right.x > 0.0 and is_zero_approx(right.y) and up.y < 0.0 and is_zero_approx(up.x) and diag.x < 0.0 and diag.y > 0.0
		and absf(diag.angle_to(Vector2(-1, 1))) < 0.001, "parting: a tip is pushed straight away from the feet")
	var prev := INF
	var smooth := true
	var top := 0.0
	for i in range(1, 101):
		var l: float = (at.call(i / 100.0, 0.0) as Vector2).length()
		top = maxf(top, l)
		if i >= 8:
			smooth = smooth and l <= prev + 0.000001 and (prev == INF or prev - l < 0.012)
			prev = l
	check(smooth and top <= 0.2 + 0.000001 and top > 0.199 and is_equal_approx((at.call(0.25, 0.0) as Vector2).length(), 0.2)
		and (at.call(0.95, 0.0) as Vector2).length() < 0.005, "parting: the full bend near the feet (%.3f of 0.2), easing smoothly to nothing at the radius" % top)
	check((at.call(0.0, 0.0) as Vector2).is_finite() and (at.call(0.0, 0.0) as Vector2).length() < 0.001,
		"parting: a root right under the feet does not jump")
	# The shaders carry the same function and use it.
	var gt: GDScript = load("res://scripts/world3d/grass_tufts.gd")
	var cc: GDScript = load("res://scripts/world3d/crop_clusters.gd")
	check(pt.GLSL in gt.SHADER and "part_push(root.xz)" in gt.SHADER and pt.GLSL in cc.SHADER and "part_push(root.xz)" in cc.SHADER
		and "smoothstep(part_radius * part_full, part_radius, dist)" in pt.GLSL, "parting: the tufts' and crops' shaders include part_push and call it")
	# The uniform: the farmer's feet reach every tuft and crop material through FarmWorld.
	var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
	w.build(MapManager.data("kaminoda"))
	w.crops.plant({Vector2i(20, 20): "stalk:corn:3:growing"}, func(_c: Vector2i) -> float: return 0.0)   # a picture the paddies don't have
	w.set_farmer(Vector3(10.5, 0.0, 13.5))
	var mats: Array = [w.tufts.material_override, w.surroundings.tufts.material_override]
	mats.append_array(w.crops.materials())
	var fed := mats.all(func(m: ShaderMaterial) -> bool: return m.get_shader_parameter("pusher_count") == 1 and m.get_shader_parameter("pushers")[0] == Vector2(10.5, 13.5))
	var tuned: bool = is_equal_approx(float(w.tufts.material_override.get_shader_parameter("part_bend")), g.bend) \
		and is_equal_approx(float(w.crops.materials()[1].get_shader_parameter("part_bend")), c.bend) \
		and is_equal_approx(float(w.crops.materials()[1].get_shader_parameter("part_radius")), radius) \
		and is_equal_approx(float(w.tufts.material_override.get_shader_parameter("part_full")), float(part.full))
	check(fed and tuned and mats.size() >= 3, "parting: FarmWorld.set_farmer feeds the feet to the map's and the apron's tufts and every crop picture (%d materials), each with its bend" % mats.size())
	w.crops.plant({Vector2i(21, 20): "stalk:rice:3:ripe", Vector2i(20, 20): "stalk:corn:3:growing"}, func(_c: Vector2i) -> float: return 0.0)
	check(w.crops.materials().all(func(m: ShaderMaterial) -> bool: return m.get_shader_parameter("pusher_count") == 1 and m.get_shader_parameter("pushers")[0] == Vector2(10.5, 13.5)),
		"parting: a crop picture made later starts with the feet where they are")
	w.free()
	# Several pushers: the villagers' and the dog's sprites part the plants too, the cap holds.
	var cap := int(part.get("max", 0))
	check(cap >= 2 and cap <= pt.MAX_PUSHERS and pt.rules("grass").max == cap and ("PART_MAX = %d" % pt.MAX_PUSHERS) in pt.GLSL
		and "uniform vec2 pushers[PART_MAX]" in pt.GLSL, "parting: data/wind.json caps the pushers at %d, no more than the shader's array of %d" % [cap, pt.MAX_PUSHERS])
	var near: Vector2 = pt.push(feet + Vector2(0.4, 0.0), feet, 1.0, 0.2, 0.3)
	check((pt.push_all(feet + Vector2(0.4, 0.0), PackedVector2Array([feet]), 1.0, 0.2, 0.3) as Vector2).is_equal_approx(near),
		"parting: the farmer alone parts the plants exactly as before")
	var villager := feet + Vector2(3.0, 0.0)
	var both := PackedVector2Array([feet, villager])
	var beside_v: Vector2 = pt.push_all(villager + Vector2(0.4, 0.0), both, 1.0, 0.2, 0.3)
	check(beside_v.x > 0.0 and absf(beside_v.length() - near.length()) < 0.0001, "parting: a plant beside a villager leans away from them as from the farmer (%.3f)" % beside_v.length())
	check(pt.push_all(feet + Vector2(1.5, 0.0), both, 1.0, 0.2, 0.3) == Vector2.ZERO, "parting: a plant out of every radius stands")
	var pinched: Vector2 = pt.push_all(feet + Vector2(0.5, 0.0), PackedVector2Array([feet, feet + Vector2(1.0, 0.0), feet + Vector2(0.9, 0.1)]), 1.0, 0.2, 0.3)
	check(pinched.length() <= 0.2 + 0.000001, "parting: pushers together never bend a tip past the bend (%.3f)" % pinched.length())
	var many: Array = []
	for i in 20:
		many.append(feet + Vector2(20.0 - i, 0.5))
	var picked: PackedVector2Array = pt.pick(feet, many, cap)
	check(picked.size() == cap and picked[0] == feet, "parting: the farmer first, %d pushers at most of %d" % [cap, many.size() + 1])
	var nearest := true
	for i in range(2, picked.size()):
		nearest = nearest and picked[i].distance_to(feet) >= picked[i - 1].distance_to(feet)
	check(nearest and picked[1].distance_to(feet) < picked[picked.size() - 1].distance_to(feet) + 0.001, "parting: past the farmer the nearest come first (%s)" % picked[1])
	check(pt.pick(feet, many, 99).size() == pt.MAX_PUSHERS and pt.pick(feet, [], cap).size() == 1, "parting: never over the array, just the farmer when nobody is near")
	# In the tree: sprites in the group feed the shaders through FarmWorld.set_farmer.
	var w2: Node3D = load("res://scripts/world3d/map_world.gd").new()
	w2.build(MapManager.data("kaminoda"))
	root.add_child(w2)
	var npc := Node3D.new()
	npc.position = Vector3(12.0, 0.0, 13.5)
	npc.add_to_group(pt.GROUP)
	w2.add_child(npc)
	var stray := Node3D.new()   # another world's figure is not this one's
	stray.add_to_group(pt.GROUP)
	root.add_child(stray)
	w2.set_farmer(Vector3(10.5, 0.0, 13.5))
	var gm: ShaderMaterial = w2.tufts.material_override
	check(gm.get_shader_parameter("pusher_count") == 2 and gm.get_shader_parameter("pushers")[1] == Vector2(12.0, 13.5)
		and gm.get_shader_parameter("pushers")[0] == Vector2(10.5, 13.5), "parting: a figure in the group is a second pusher, a stray one is not")
	npc.visible = false
	w2.set_farmer(Vector3(10.5, 0.0, 13.5))
	check(gm.get_shader_parameter("pusher_count") == 1, "parting: a hidden figure parts nothing")
	# A vine on its stake: the villagers' and the dog's pushes go through the same shader path as the
	# farmer's, scaled by the vine layer's stiffness, so the stake holds the vine as firm for them.
	npc.visible = true
	w2.crops.plant({Vector2i(12, 13): "stalk:cucumber:3:ripe"}, func(_c: Vector2i) -> float: return 0.0)
	w2.set_farmer(Vector3(10.5, 0.0, 13.5))
	var vines: Array = w2.crops.materials().filter(func(m: ShaderMaterial) -> bool: return m.get_shader_parameter("stiff") < 1.0)
	var cc_gd: GDScript = load("res://scripts/world3d/crop_clusters.gd")
	var stiff := float(cc_gd.layout("stalk:cucumber:3:ripe").get("stiff", 1.0))
	var pushed_firm := func(m: ShaderMaterial) -> bool:
		return is_equal_approx(float(m.get_shader_parameter("stiff")), stiff) and m.get_shader_parameter("pusher_count") == 2 \
			and m.get_shader_parameter("pushers")[1] == Vector2(12.0, 13.5)
	check(vines.size() >= 1 and stiff < 1.0 and vines.all(pushed_firm) and "part_push(root.xz) * k * stiff" in cc_gd.SHADER,
		"parting: a villager beside a vine stake is a pusher too, scaled by the vine's stiffness %.2f (%d vine pictures)" % [stiff, vines.size()])
	stray.queue_free()
	w2.queue_free()
	var vs_src := FileAccess.get_file_as_string("res://scripts/world3d/villager_sprites.gd")
	var an_src := FileAccess.get_file_as_string("res://scripts/world3d/animal_layer.gd")
	check("add_to_group(Parting.GROUP)" in vs_src and "add_to_group(Parting.GROUP)" in an_src, "parting: the villagers' and the dog's sprites join the group")


func _crop_clusters() -> void:
	var cc: GDScript = load("res://scripts/world3d/crop_clusters.gd")
	check(cc.key_for("crop:rice:3:ripe") == "stalk:rice:3:ripe" and cc.key_for("crop:corn:2:growing") == "stalk:corn:2:growing"
		and cc.key_for("crop:rice:1:growing") == "" and cc.key_for("crop:corn:0:growing") == ""
		and cc.key_for("crop:tomato:3:ripe") == "stalk:tomato:3:ripe" and cc.key_for("crop:cucumber:2:growing") == "stalk:cucumber:2:growing"
		and cc.key_for("crop:tomato:1:growing") == "" and cc.key_for("crop:turnip:3:ripe") == "" and cc.key_for("crop:potato:3:ripe") == "" and cc.key_for("weed") == "",
		"clusters: rice, corn, cucumber and tomato from growth 2; seeds, sprouts and other crops stay sprites")
	var cells := {}
	for i in 30:
		cells[Vector2i(i % 6, i / 6)] = ["stalk:rice:3:ripe", "stalk:rice:2:growing", "stalk:corn:3:ripe"][i % 3]
	var spots: Array = cc.spots_for(cells)
	var inside := spots.all(func(s): return Rect2(Vector2(s.cell), Vector2.ONE).grow(-0.05).has_point(Vector2(s.pos.x, s.pos.z)))
	var per := {}
	for s in spots:
		per[s.key] = per.get(s.key, 0) + 1
	check(inside and cc.spots_for(cells) == spots and per == {"stalk:rice:3:ripe": 90, "stalk:rice:2:growing": 60, "stalk:corn:3:ripe": 30},
		"clusters: plants inside their cells, the same each time, %s" % [per])
	var variants := {}
	for s in spots:
		variants[s.tex] = true
	var ripe := PlaceholderArt.tex("stalk:rice:3:ripe:0").get_image()
	var young := PlaceholderArt.tex("stalk:rice:2:growing:1").get_image()
	var corn := PlaceholderArt.tex("stalk:corn:3:ripe:2").get_image()
	# Vines: a stake each, the fruit showing only when ripe, taller grown than young.
	var vine_ok := true
	for id in ["cucumber", "tomato"]:
		var fc := Color(PlaceholderArt.crop_look(id).get("ripe_fruit", PlaceholderArt.crop_look(id).fruit))
		var counts := {}
		for st in ["3:ripe", "3:growing", "2:ripe", "2:growing"]:
			var im := PlaceholderArt.tex("stalk:%s:%s:1" % [id, st]).get_image()
			var n := 0
			for y in im.get_height():
				for x in im.get_width():
					if im.get_pixel(x, y).is_equal_approx(fc):
						n += 1
			counts[st] = [n, im.get_height()]
		vine_ok = vine_ok and counts["3:ripe"][0] >= 8 and counts["3:growing"][0] == 0 and counts["2:ripe"][0] >= 4 and counts["2:growing"][0] == 0 			and counts["3:ripe"][1] > counts["2:ripe"][1]
		check(vine_ok, "clusters: the %s vine shows fruit only when ripe, taller grown (%s)" % [id, counts])
	var vspots: Array = cc.spots_for({Vector2i(3, 3): "stalk:cucumber:3:ripe", Vector2i(4, 3): "stalk:tomato:2:growing"})
	check(vspots.size() == 4 and vspots.all(func(s): return Rect2(Vector2(s.cell), Vector2.ONE).grow(-0.05).has_point(Vector2(s.pos.x, s.pos.z)))
		and cc.layout("stalk:tomato:3:ripe").get("stiff", 1.0) < 1.0, "clusters: two stakes a vine cell, inside it, held firmer than rice")
	# A ripe cucumber stands apart: its fruit is paler than its leaves, and no leaf touches it
	# (only its own lit and shaded tones, or the leaf rim, lie beside a fruit pixel).
	var cuc: Dictionary = PlaceholderArt.crop_look("cucumber")
	var pale := Color(cuc.get("ripe_fruit", "000000"))
	var leafc := Color(cuc.leaf)
	var same := func(a: Color, b: Color) -> bool: return absf(a.r - b.r) < 0.02 and absf(a.g - b.g) < 0.02 and absf(a.b - b.b) < 0.02
	var tones := [pale, pale.lightened(0.45), pale.darkened(0.4)]
	var is_fruit := func(c: Color) -> bool: return c.a >= 0.5 and tones.any(func(t: Color) -> bool: return same.call(c, t))
	var rim := leafc.darkened(0.6)
	var stand_off := true
	var fruit_px := 0
	for v in 3:
		for growth in [2, 3]:
			var im := PlaceholderArt.tex("stalk:cucumber:%d:ripe:%d" % [growth, v]).get_image()
			var iw := im.get_width()
			var ih := im.get_height()
			for y in ih:
				for x in iw:
					if not is_fruit.call(im.get_pixel(x, y)):
						continue
					fruit_px += 1
					for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
						var q: Vector2i = Vector2i(x, y) + d
						if q.x < 0 or q.y < 0 or q.x >= iw or q.y >= ih:
							continue
						var n := im.get_pixel(q.x, q.y)
						if n.a >= 0.5 and not is_fruit.call(n) and not same.call(n, rim):
							stand_off = false
	var lum := func(c: Color) -> float: return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
	check(stand_off and fruit_px >= 40 and lum.call(pale) - lum.call(leafc) >= 0.15,
		"clusters: a ripe cucumber's fruit is paler than its leaves (%.2f vs %.2f) and no leaf touches it (%d fruit pixels)" % [lum.call(pale), lum.call(leafc), fruit_px])
	var gold := 0
	var fruit := Color(PlaceholderArt.crop_look("rice").fruit)
	for y in ripe.get_height():
		for x in ripe.get_width():
			if ripe.get_pixel(x, y).is_equal_approx(fruit):
				gold += 1
	check(variants.size() == 9 and ripe.get_width() < 12 and young.get_height() < ripe.get_height() and corn.get_height() > ripe.get_height() and gold >= 10,
		"clusters: %d pictures, a rice hill %dx%d (young %d high), a corn stalk %d high, %d gold ear pixels"
		% [variants.size(), ripe.get_width(), ripe.get_height(), young.get_height(), corn.get_height(), gold])
	# On the farm: a rice cell grown is a cluster, not a sprite; harvested, its plants go.
	var g: Node = root.get_node("Game")
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var farm := FarmGrid.new(crops)
	farm.generate(RandomNumberGenerator.new())
	var fw: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	fw.setup(farm)
	var rc := Vector2i(-1, -1)
	var tc := Vector2i(-1, -1)
	for i in farm.cells.size():
		var c := Vector2i(i % FarmGrid.W, i / FarmGrid.W)
		if farm.can_farm(c) and farm.cell(c).obj == FarmGrid.Obj.NONE and farm.fixed_at(c) == "":
			if rc.x < 0:
				rc = c
			elif tc.x < 0 and c.y == rc.y and c.x > rc.x + 1:
				tc = c
	farm.till(rc)
	farm.sow(rc, "rice", "summer")
	farm.till(tc)
	farm.sow(tc, "onion", "summer")
	farm.cell(rc).stage = farm.ripe_stage("rice")
	farm.cell(tc).stage = farm.ripe_stage("onion")
	farm.cells_changed.emit()
	var on_rc: Array = fw.crops.planted.filter(func(s): return s.cell == rc)
	check(on_rc.size() == 9 and not fw._sprites.has(rc) and fw._sprites.has(tc) and fw.crops.planted.size() == 9
		and fw.crops.layer_counts().values().reduce(func(a, b): return a + b, 0) == 9,
		"the farm: ripe rice %s is 9 plants and no sprite, the onion %s a sprite" % [rc, tc])
	farm.cell(rc).stage = 1
	farm.cells_changed.emit()
	check(fw.crops.planted.is_empty() and fw._sprites.has(rc), "the farm: rice at its sprout is a sprite again")
	# A tomato vine: two stakes, fruit when ripe, a sprite again at its sprout.
	farm.cell(tc).crop = ""
	farm.sow(tc, "tomato", "summer")
	farm.cell(tc).stage = farm.ripe_stage("tomato")
	farm.cells_changed.emit()
	var on_tc: Array = fw.crops.planted.filter(func(s): return s.cell == tc)
	check(on_tc.size() == 2 and not fw._sprites.has(tc) and on_tc.all(func(s): return s.key == "stalk:tomato:3:ripe"),
		"the farm: a ripe tomato %s is 2 stakes and no sprite (%d)" % [tc, on_tc.size()])
	farm.cell(tc).stage = 0
	farm.cells_changed.emit()
	check(fw.crops.planted.is_empty() and fw._sprites.has(tc), "the farm: a tomato at its seed is a sprite again")
	farm.cell(tc).crop = ""
	farm.cells_changed.emit()
	farm.cell(rc).crop = ""
	farm.cells_changed.emit()
	check(fw.crops.planted.is_empty() and not fw._sprites.has(rc), "the farm: the cell cleared, nothing stands")
	fw.free()
	# The village paddies by season.
	var keep: int = g.season
	var m := MapManager.data("kaminoda")
	var paddies := 0
	for y in m.h:
		for x in m.w:
			if m.tile(Vector2i(x, y)) == "paddy" and m.prop_at(Vector2i(x, y)).is_empty():
				paddies += 1
	var rules: Dictionary = g.snow_rules
	for si in 4:
		g.season = si
		var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
		w.build(m)
		var season: String = g.season_name()
		var want: String = cc.paddy_key(season)
		var cl: Array = w.crops.planted
		var keys := {}
		var bad_hold := 0
		for s in cl:
			keys[s.key] = true
			if m.tile(s.cell) != "paddy" or absf(s.hold - SnowLayer.map_hold(m, s.cell, rules)) > 0.01:
				bad_hold += 1
		w.set_snow(0.4)
		var driven: bool = w.crops.materials().all(func(mat): return is_equal_approx(float(mat.get_shader_parameter("cover")), 0.4))
		var water: Array = w.crops.water_planted
		var bad_water := 0
		for s in water:
			if m.tile(s.cell) != "paddy" or absf(s.hold - SnowLayer.map_hold(m, s.cell, rules)) > 0.01:
				bad_water += 1
		check(keys.keys() == [want] and cl.size() == paddies * cc.layout(want).places.size() and bad_hold == 0 and driven
			and (water.size() > 0) == cc.water_on(season) and bad_water == 0,
			"kaminoda in %s: %d paddy cells grow %s (%d plants), %d off a paddy or wrong hold, snow driven %s, %d water patches (%d off a paddy or wrong hold)"
			% [season, paddies, want, cl.size(), bad_hold, driven, water.size(), bad_water])
		w.free()
	g.season = keep
	check(cc.paddy_key("spring") == "stalk:rice:2:growing" and cc.paddy_key("summer") == "stalk:rice:3:growing"
		and cc.paddy_key("fall") == "stalk:rice:3:ripe" and cc.paddy_key("winter") == "stalk:rice:0:stubble"
		and cc.water_on("winter") and not cc.water_on("spring") and not cc.water_on("summer") and not cc.water_on("fall"),
		"paddies: young in spring, tall and green in summer, ripe in fall, cut stubble and water in winter")
	_paddy_winter(cc)
	_paddy_ground_3d()


## The 3D ground of the village paddies (MapWorld.ground_keys): a paddy cell that grows rice takes
## the flat view's calm ground, paddy_mud in winter and paddy_flood in the other seasons, every
## cell's key is the one MapView.ground_key_in gives, and a paddy tile with no rice keeps the
## painted "paddy" tile.
func _paddy_ground_3d() -> void:
	var mw: GDScript = load("res://scripts/world3d/map_world.gd")
	var m := MapManager.data("kaminoda")
	var mv := MapView.new()
	mv.map = m
	var rice := {}      # season -> cells drawn with rice
	var bad := 0        # rice cells whose 3D key is not the season's calm ground
	var disagree := 0   # cells where the 3D and flat keys differ
	var painted := 0    # paddy tiles with no rice
	var painted_bad := 0
	var sample := {}    # season -> the key of one rice cell
	for season in ["winter", "spring", "summer", "fall"]:
		mv.season = season   # the field itself: set_season redraws, and this view is not in the tree
		var flat_paddies: Dictionary = mv.paddy_cells()
		var keys: Dictionary = mw.ground_keys(m, season)
		var want := "ground:paddy_mud:" if season == "winter" else "ground:paddy_flood:"
		rice[season] = flat_paddies.size()
		for y in m.h:
			for x in m.w:
				var c := Vector2i(x, y)
				if keys[c] != mv.ground_key_in(c, flat_paddies):
					disagree += 1
				if flat_paddies.has(c):
					if not keys[c].begins_with(want):
						bad += 1
					if not sample.has(season):
						sample[season] = keys[c]
				elif m.tile(c) == "paddy":
					painted += 1
					if not keys[c].begins_with("ground:paddy:"):
						painted_bad += 1
	mv.free()
	check(rice.values().all(func(n): return n > 0), "paddy ground 3d: rice cells in every season %s" % [rice])
	check(sample.get("winter", "").begins_with("ground:paddy_mud:") and sample.get("summer", "").begins_with("ground:paddy_flood:"),
		"paddy ground 3d: a rice cell is paddy_mud in winter (%s) and paddy_flood in summer (%s)" % [sample.get("winter", ""), sample.get("summer", "")])
	check(bad == 0, "paddy ground 3d: every rice cell has its season's calm ground (%d off)" % bad)
	check(disagree == 0, "paddy ground 3d: the 3D and flat views pick the same ground key for every cell (%d differ)" % disagree)
	check(painted_bad == 0, "paddy ground 3d: paddy tiles with no rice keep the painted tile (%d of %d painted)" % [painted_bad, painted])


## The winter paddies (CropClusters): the stubble and the water patches as pictures, the water
## patches' places and counts from data/paddy.json, and the snow rule: a plant or patch folds away
## exactly where the shader's snow_at says snow or its rim lies on its cell (the paddy's hold),
## more of them as the cover grows.
func _paddy_winter(cc: GDScript) -> void:
	var g: Node = root.get_node("Game")
	var keep: int = g.season
	var stub := PlaceholderArt.tex("stalk:rice:0:stubble:0").get_image()
	var young := PlaceholderArt.tex("stalk:rice:2:growing:1").get_image()
	var straw := 0   # straw browns are much redder than blue; the dark rim is not (r - b 0.16 vs 0.24 and up)
	for y in stub.get_height():
		for x in stub.get_width():
			var c := stub.get_pixel(x, y)
			if c.a >= 0.5 and c.r - c.b > 0.2:
				straw += 1
	var pond := PlaceholderArt.tex("patch:paddy_water").get_image()
	var grey := 0
	for y in pond.get_height():
		for x in pond.get_width():
			var c := pond.get_pixel(x, y)
			if c.a >= 0.5 and c.b > c.r and c.b > 0.3 and c.r < 0.7:
				grey += 1
	check(stub.get_height() < young.get_height() and straw >= 8 and stub.get_width() == 9 and stub.get_height() == 6,
		"paddy winter: the stubble is %dx%d (young rice %d high) with %d straw pixels" % [stub.get_width(), stub.get_height(), young.get_height(), straw])
	check(pond.get_width() == 12 and pond.get_height() == 5 and grey >= 30 and pond.get_pixel(0, 0).a < 0.5,
		"paddy winter: the water patch is a 12x5 grey-blue oval (%d pixels)" % grey)
	# The data: winter only, a chance per row gap, the row gaps between the rows.
	var data: Dictionary = cc.paddy_data().get("water", {})
	check(data.get("seasons", []) == ["winter"] and float(data.get("chance", 0)) > 0.0 and float(data.get("chance", 2)) < 1.0
		and (data.z as Array).size() == 2 and float(data.z[0]) > 0.17 and float(data.z[1]) < 0.83 and float(data.z[0]) < float(data.z[1]),
		"paddy winter: data/paddy.json puts water in winter only, a chance under 1, two row gaps between the rows")
	# A few patches, between the rows: no patch off a row gap, the count near the chance.
	var cells: Array = []
	for i in 400:
		cells.append(Vector2i(i % 20, i / 20))
	var spots: Array = cc.water_spots_for(cells)
	var between := spots.all(func(s): return absf(s.pos.z - s.cell.y - 0.33) <= float(data.nudge) + 0.001 or absf(s.pos.z - s.cell.y - 0.67) <= float(data.nudge) + 0.001)
	var inside := spots.all(func(s): return Rect2(Vector2(s.cell), Vector2.ONE).has_point(Vector2(s.pos.x, s.pos.z)))
	var expected := 2.0 * cells.size() * float(data.chance)
	var spread := 4.0 * sqrt(2.0 * cells.size() * float(data.chance) * (1.0 - float(data.chance)))
	check(between and inside and absf(spots.size() - expected) <= spread and spots == cc.water_spots_for(cells),
		"paddy winter: %d water patches on 400 cells (about %d expected), each between two rows and inside its cell" % [spots.size(), expected])
	# Snow: the plants and patches fold where the shader's rule says, and more of them as it grows.
	var m := MapManager.data("kaminoda")
	g.season = g.SEASONS.find("winter")
	var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
	w.build(m)
	var folded_by_rule := func(list: Array, cover: float) -> int:
		var n := 0
		for s in list:
			var amount := cover * float(s.hold)
			if SnowLayer.snow_kind(SnowLayer.noise_at(Vector2(s.pos.x, s.pos.z)), amount) > 0:
				n += 1
		return n
	var plants: Array = w.crops.planted
	var patches: Array = w.crops.water_planted
	var none_at_0: int = folded_by_rule.call(plants, 0.0) + folded_by_rule.call(patches, 0.0)
	var part: int = folded_by_rule.call(plants, 0.8)
	var water_part: int = folded_by_rule.call(patches, 0.8)
	check(none_at_0 == 0 and part > 0 and part < plants.size() and water_part > 0 and water_part < patches.size()
		and folded_by_rule.call(plants, 1.0) >= part and folded_by_rule.call(patches, 1.0) >= water_part,
		"paddy winter: no snow, nothing folds; heavy snow (0.8) folds %d of %d stubble plants and %d of %d patches, by the paddy's hold" % [part, plants.size(), water_part, patches.size()])
	check("snow_at(root.xz, cover * INSTANCE_CUSTOM.r) > 0.5" in cc.SHADER and "snow_at(root.xz, cover * INSTANCE_CUSTOM.r) > 0.5" in cc.WATER_SHADER
		and "render_mode unshaded" in cc.WATER_SHADER,
		"paddy winter: the plants' and the patches' shaders fold them on the same snow rule")
	w.set_snow(0.8)
	check(is_equal_approx(float(w.crops._water_material.get_shader_parameter("cover")), 0.8) and w.crops.materials().all(func(mat): return is_equal_approx(float(mat.get_shader_parameter("cover")), 0.8)),
		"paddy winter: set_snow drives the patches' cover too")
	_paddy_glint(cc, w, patches)
	w.free()
	g.season = keep


## The 3D winter patches' glint (CropClusters.WATER_SHADER, glint_columns is its sum in GDScript):
## phase by place, quicker in a storm, none under snow, the colour and numbers from data.
func _paddy_glint(cc: GDScript, w: Node3D, patches: Array) -> void:
	var wind_d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/wind.json"))
	var gd: Dictionary = wind_d["3d"]["glint"]
	var cfg: Dictionary = cc.glint_config()
	check(patches.size() > 3 and is_equal_approx(float(cfg.speed), float(gd.speed)) and is_equal_approx(float(cfg.swing), float(gd.swing))
		and is_equal_approx(float(cfg.faster), float(gd.faster)) and is_equal_approx(float(cfg.rate), float(gd.rate)),
		"3d glint: the numbers come from data/wind.json \"3d\"")
	var gv: Vector4 = w.crops._water_material.get_shader_parameter("glint")
	var sv: Vector3 = w.crops._water_material.get_shader_parameter("shine")
	var shine := Color(String(JSON.parse_string(FileAccess.get_file_as_string("res://data/paddy.json")).water.shine))
	check(is_equal_approx(gv.y, float(gd.speed)) and is_equal_approx(gv.w, float(gd.swing)) and is_equal_approx(sv.x, shine.r) and is_equal_approx(sv.z, shine.b),
		"3d glint: the material carries data's numbers and water.shine")
	check("glint_columns" in cc.WATER_SHADER and "cover <= 0.0" in cc.WATER_SHADER and "px.y == 1.0" in cc.WATER_SHADER,
		"3d glint: the shader draws it only with no snow cover, on the second row")
	# Phase by place: patches are not in step.
	var in_step := 0
	var frames := 0
	var a: Vector3 = patches[0].pos
	var b: Vector3 = a
	for s in patches:
		if absf(fposmod(s.pos.x * 12.9898 + s.pos.z * 78.233, 1.0) - fposmod(a.x * 12.9898 + a.z * 78.233, 1.0)) > 0.15:
			b = s.pos
			break
	for f in 120:
		var t := f * 0.25
		if cc.glint_columns(a, 0.0, t)[0] == cc.glint_columns(b, 0.0, t)[0]:
			in_step += 1
		frames += 1
	check(b != a and in_step < frames / 2, "3d glint: two patches are not in step (%d of %d frames in the same column)" % [in_step, frames])
	# One or two lights, whole columns inside the oval, both seen.
	var seen := {}
	var inside := true
	for s in patches:
		var cols: Array = cc.glint_columns(s.pos, 0.5, 3.0)
		seen[cols.size()] = true
		for c in cols:
			inside = inside and c >= 3 and c <= 8
	check(seen.has(1) and seen.has(2) and inside, "3d glint: one or two lights a patch (both seen), inside the oval")
	# Quicker in a storm: more column changes in 30 s.
	var changes := func(wind: float) -> int:
		var n := 0
		var last: int = cc.glint_columns(a, wind, 0.0)[0]
		for f in 1200:
			var c: int = cc.glint_columns(a, wind, f * 0.025)[0]
			if c != last:
				n += 1
			last = c
		return n
	var calm: int = changes.call(0.15)
	var storm: int = changes.call(1.0)
	check(storm > calm and calm > 0, "3d glint: more changes in a storm (%d) than a sunny day (%d)" % [storm, calm])
	var moved := {}
	for f in 300:
		moved[cc.glint_columns(a, 0.15, f * 0.1)[0]] = true
	check(moved.size() >= 3, "3d glint: a light takes at least 3 places in 30 s (%d)" % moved.size())
	check(cc.glint_columns(a, 1.0, 5.0, 0.4).is_empty() and cc.glint_columns(a, 0.0, 5.0, 1.0).is_empty() and not cc.glint_columns(a, 1.0, 5.0, 0.0).is_empty(),
		"3d glint: none with snow lying")


## The moving skin on the water (WaterSurface): a sheet over the farm pond, the village pond
## and the river, pulled in from the banks, kept inside the water.
func _water() -> void:
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var farm := FarmGrid.new(crops)
	farm.generate(RandomNumberGenerator.new())
	var fw: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	fw.setup(farm)
	var sheet = fw.surroundings.water
	var pond := 0
	var covered := 0
	var stray := 0
	var cover := {}
	for q in sheet.quads:
		cover[q.cell] = q.rect
		if q.cell.x >= 0 and q.cell.y >= 0 and q.cell.x < FarmGrid.W and q.cell.y < FarmGrid.H and farm.fixed_at(q.cell) != "pond":
			stray += 1
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			if farm.fixed_at(Vector2i(x, y)) == "pond":
				pond += 1
				covered += 1 if cover.has(Vector2i(x, y)) else 0
	check(pond > 0 and covered == pond and stray == 0, "the farm pond: %d of %d water cells under the sheet, %d quads on land" % [covered, pond, stray])
	var inset := 0
	for c in cover:
		var r: Rect2 = cover[c]
		if r.size.x < 1.0 - 0.001 or r.size.y < 1.0 - 0.001:
			inset += 1
		if r.position.x < c.x - 0.001 or r.position.y < c.y - 0.001 or r.end.x > c.x + 1.001 or r.end.y > c.y + 1.001:
			stray += 1
	check(inset > 0 and inset < cover.size() and stray == 0, "the sheet is pulled in from the banks only (%d of %d quads) and stays in its cells" % [inset, cover.size()])
	check(sheet.material_override is ShaderMaterial and sheet.material_override.shader.code.contains("TIME")
		and sheet.position.y > 0.0 and sheet.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and sheet.mesh != null,
		"the sheet moves with time, lies above the ground and casts no shadow")
	# Ripple rings: slots, strength, life, reuse of the oldest, and the shader draws them.
	check(sheet.material_override.shader.code.contains("ripples[8]") and sheet.ripples.size() == sheet.MAX_RIPPLES
		and sheet.ripples_alive() == 0, "the sheet has room for %d ripple rings and none at the start" % sheet.MAX_RIPPLES)
	sheet.ripple(Vector2(25.5, 3.5))
	sheet.ripple(Vector2(25.5, 3.5), true)
	check(sheet.ripples_alive() == 2 and sheet.ripples[0].w > 0.0 and sheet.ripples[1].w < 0.0
		and absf(sheet.ripples[1].w) > absf(sheet.ripples[0].w), "a ring is gentle, a strong one lasts longer")
	sheet.advance(sheet.RING_LIFE + 0.05)
	check(sheet.ripples_alive() == 1, "a gentle ring fades out first")
	sheet.advance(sheet.RING_LIFE_STRONG)
	check(sheet.ripples_alive() == 0 and is_equal_approx(float(sheet.material_override.get_shader_parameter("clock")), sheet.clock),
		"every ring fades out and the shader's clock follows")
	for i in sheet.MAX_RIPPLES + 3:
		sheet.ripple(Vector2(1, 1))
	check(sheet.ripples_alive() == sheet.MAX_RIPPLES and sheet.ripples.size() == sheet.MAX_RIPPLES,
		"more rings than slots reuse the oldest slot")
	# Rain dimples: dry by default, set from data/weather_fx.json, in the shader, no slots used.
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weather_fx.json"))
	var rain_d: Dictionary = fx.rain.dimples
	var storm_d: Dictionary = fx.storm.dimples
	var m3: ShaderMaterial = sheet.material_override
	check(sheet.rain_density == 0.0 and is_equal_approx(float(m3.get_shader_parameter("dimple_density")), 0.0)
		and m3.shader.code.contains("dimple_density"), "the water is dry until it rains")
	fw.set_rain(rain_d)
	check(is_equal_approx(float(m3.get_shader_parameter("dimple_density")), float(rain_d.density))
		and is_equal_approx(float(m3.get_shader_parameter("dimple_life")), float(rain_d.life)), "rain sets the dimples' density and life on the sheet")
	check(float(storm_d.density) > float(rain_d.density) and float(storm_d.life) < float(rain_d.life), "a storm dimples more and quicker than rain")
	check(sheet.ripples_alive() == sheet.MAX_RIPPLES, "dimples take none of the bobber's ring slots")
	fw.set_rain({})
	check(is_equal_approx(float(m3.get_shader_parameter("dimple_density")), 0.0), "no dimples once it stops")
	for look in ["sunny", "snow", "blizzard"]:
		check(not fx[look].has("dimples"), "%s has no rain dimples" % look)
	fw.free()
	for id in ["river", "town"]:
		var m := MapManager.data(id)
		var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
		w.build(m)
		var water_cells := 0
		for y in m.h:
			for x in m.w:
				if m.tile(Vector2i(x, y)) == "water":
					water_cells += 1
		var inside: Array = w.surroundings.water.quads.filter(func(q): return q.cell.x >= 0 and q.cell.y >= 0 and q.cell.x < m.w and q.cell.y < m.h)
		check(water_cells > 0 and inside.size() == water_cells, "%s: %d of %d water cells under the sheet" % [id, inside.size(), water_cells])
		if id == "river":
			check(w.surroundings.water.quads.size() > water_cells, "the river runs on past the edges under the sheet")
		w.free()
	var house: Node3D = load("res://scripts/world3d/map_world.gd").new()
	house.build(MapManager.data("house"))
	check(house.surroundings == null, "no water sheet indoors (so no dimples)")
	house.free()


## Winter ice on the water (data/snow_cover.json "ice", WaterSurface.set_ice): winter only, thin
## at the shore with the middle open, the land round each cell on the sheet's quads, the
## uniforms from the data, the snow dusting by the cover, rings and dimples on open water only.
func _water_ice() -> void:
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/snow_cover.json"))
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var style: Dictionary = game_script.ice_for("winter", rules)
	check(not style.is_empty(), "winter has ice on the water")
	for s in ["spring", "summer", "fall"]:
		check(game_script.ice_for(s, rules).is_empty(), "no ice in %s" % s)
	var wmin := float(style.width[0])
	var wmax := float(style.width[1])
	check(wmin >= 1.0 and wmax >= wmin and wmax <= 16.0 / 3.0, "the ice is %s..%s px from the bank, a third of a cell at most" % [wmin, wmax])
	check(WaterIce.shore_px(Vector2(8, 8), 255) >= wmax, "a cell's middle stays open even with land all round (the bobber's water)")
	var narrow := WaterIce.BITS.left | WaterIce.BITS.right
	var open := 0
	for px in 16:
		if WaterIce.shore_px(Vector2(px + 0.5, 8.5), narrow) >= wmax and px >= 3 and px < 13:
			open += 1
	check(open >= 2, "a channel one cell wide keeps open water down its middle (%d px)" % open)
	# The ice grows over the winter and with the snow lying, and never past the open middle.
	var early: Array = game_script.ice_for("winter", rules, 1, 0).width
	var mid: Array = game_script.ice_for("winter", rules, 22, 0).width
	var late: Array = game_script.ice_for("winter", rules, 30, 0).width
	var snowy: Array = game_script.ice_for("winter", rules, 22, 100).width
	check(float(early[1]) < float(mid[1]) - 1.0 and float(late[1]) < float(mid[1]) - 0.5,
		"the ice is thin early (%.2f), widest in late winter (%.2f) and recedes by the end (%.2f)" % [early[1], mid[1], late[1]])
	check(float(snowy[1]) > float(mid[1]) and float(snowy[0]) > float(mid[0]),
		"snow lying widens it (%.2f -> %.2f)" % [mid[1], snowy[1]])
	check(float(game_script.ice_for("winter", rules, 12, 100).width[1]) > float(game_script.ice_for("winter", rules, 12, 0).width[1]),
		"with snow lying the ice is wider on the same day")
	var cap_ok := true
	for d in range(1, 31):
		for cv in [0, 50, 100]:
			var gw: Array = game_script.ice_for("winter", rules, d, cv).width
			cap_ok = cap_ok and float(gw[0]) > 0.0 and float(gw[1]) >= float(gw[0]) and float(gw[1]) <= float(rules.ice.grow.max) 				and WaterIce.shore_px(Vector2(8.5, 8.5), 255) >= float(gw[1]) and float(gw[1]) <= 16.0 / 3.0
	check(cap_ok, "every day and cover keeps the cell's middle open")
	check(game_script.ice_for("spring", rules, 22, 100).is_empty(), "no grown ice outside winter")
	var wv := WaterView.new()
	wv.build(3, 3, func(c: Vector2i) -> bool: return c == Vector2i(1, 1), false)
	wv.set_ice(game_script.ice_for("winter", rules, 1, 0), 0.0)
	check((wv.material as ShaderMaterial).get_shader_parameter("ice_width") == Vector2(float(early[0]), float(early[1])),
		"the flat view takes the same grown width")
	wv.free()
	# The sheet's quads carry the land round their cell; inner cells have none (no ice there).
	var fw: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	var farm := FarmGrid.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json")))
	farm.generate(RandomNumberGenerator.new())
	var pond := func(c: Vector2i) -> bool: return farm.fixed_at(Vector2i(clampi(c.x, 0, FarmGrid.W - 1), clampi(c.y, 0, FarmGrid.H - 1))) == "pond"
	var sheet: Node3D = load("res://scripts/world3d/water_surface.gd").new()
	fw.add_child(sheet)
	var cells: Array[Vector2i] = []
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			if pond.call(Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	sheet.set_cells(cells, pond)
	var wrong := 0
	var inner := 0
	var shore := 0
	for q in sheet.quads:
		var expect := 0
		for k in WaterIce.STEPS:
			if not pond.call(q.cell + WaterIce.STEPS[k]):
				expect |= int(WaterIce.BITS[k])
		wrong += 0 if int(q.land) == expect else 1
		inner += 1 if int(q.land) == 0 else 0
		shore += 1 if int(q.land) != 0 else 0
	check(cells.size() > 0 and wrong == 0 and inner > 0 and shore > 0,
		"the pond's quads carry the land round them (%d shore cells, %d open ones, %d wrong)" % [shore, inner, wrong])
	var code: String = sheet.material_override.shader.code
	check(code.contains("ice_at(") and not code.contains("//ICE//") and code.find("ice.a > 0.0") < code.find("ripples[i]"),
		"the sheet's shader draws the ice first, the rings and dimples only off it")
	var m: ShaderMaterial = sheet.material_override
	check(is_equal_approx(float(m.get_shader_parameter("ice_on")), 0.0), "no ice until it is set")
	sheet.set_ice(style, 0.8)
	check(is_equal_approx(float(m.get_shader_parameter("ice_on")), 1.0)
		and m.get_shader_parameter("ice_width") == Vector2(wmin, wmax)
		and is_equal_approx(float(m.get_shader_parameter("ice_snow")), 0.8 * float(style.snow))
		and m.get_shader_parameter("ice_color") == Color(String(style.colors.ice))
		and m.get_shader_parameter("ice_snow_color") == Color(String(style.colors.snow)),
		"winter sets the ice's width, colours and the snow on it from the data")
	sheet.set_ice(style, 0.0)
	check(is_equal_approx(float(m.get_shader_parameter("ice_snow")), 0.0), "no snow lying, no snow on the ice")
	sheet.set_ice({})
	check(is_equal_approx(float(m.get_shader_parameter("ice_on")), 0.0), "the ice goes in spring")
	# Ice set before the sheet is built carries into it, and a world passes it on.
	var built: Node3D = load("res://scripts/world3d/water_surface.gd").new()
	built.set_ice(style, 0.5)
	built.set_cells(cells, pond)
	check(is_equal_approx(float(built.material_override.get_shader_parameter("ice_on")), 1.0), "a sheet built in winter has its ice")
	built.free()
	fw.free()
	var town: Node3D = load("res://scripts/world3d/map_world.gd").new()
	town.set_ice(style, 0.3)
	town.build(MapManager.data("town"))
	var tm: ShaderMaterial = town.surroundings.water.material_override
	check(is_equal_approx(float(tm.get_shader_parameter("ice_on")), 1.0)
		and is_equal_approx(float(tm.get_shader_parameter("ice_snow")), 0.3 * float(style.snow)), "the village water takes the world's ice")
	town.set_ice({})
	check(is_equal_approx(float(tm.get_shader_parameter("ice_on")), 0.0), "and lets it go")
	town.free()


## Upright faces (eave bands, verges, roll ends) of the meshes in `w` whose normal points
## back towards `mid` (x, z) instead of away from it.
func _walls_facing_in(w: Node3D, mid: Vector2) -> int:
	var bad := 0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				if absf(nm[i].y) > 0.1:
					continue
				var c := (v[i] + v[i + 1] + v[i + 2]) / 3.0
				if Vector2(nm[i].x, nm[i].z).dot(Vector2(c.x, c.z) - mid) <= 0.0:
					bad += 1
	return bad


func _homes_3d() -> void:
	for id in ["tome_house", "kota_house", "sayo_house"]:
		var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
		w.build(MapManager.data(id))
		var stand_in := 0
		var meshes := 0
		for n in w.get_children():
			if n is MeshInstance3D:
				meshes += 1
				var mat: Variant = n.material_override
				if mat is StandardMaterial3D and mat.albedo_color == Color.MAGENTA:
					stand_in += 1
		check(stand_in == 0 and meshes > 30, "%s builds in 3D (%d meshes, %d stand-ins)" % [id, meshes, stand_in])
		w.free()
	var river: Node3D = load("res://scripts/world3d/map_world.gd").new()
	river.build(MapManager.data("river"))
	var magenta := 0
	for n in river.get_children():
		if n is MeshInstance3D and n.material_override is StandardMaterial3D and n.material_override.albedo_color == Color.MAGENTA:
			magenta += 1
	check(magenta == 0 and river.get_child_count() > 10, "the river builds in 3D (%d nodes, %d stand-ins)" % [river.get_child_count(), magenta])
	river.free()


## The props the band 5 heart events leave (StoryProps): each shows only with its flag (the
## sign by its value), follows the shared flags, survives save / load, builds in both views,
## and the bell rings when used.
func _story_props() -> void:
	var where := {"door_bell": "farm", "store_sign": "town", "ume_jar": "house", "carp_streamer": "farm"}
	var kinds := func(id: String, f: Dictionary) -> Array:
		var out := []
		for p in MapManager.load_map(id, null, f)[1].props:
			if p.kind in StoryView.KINDS:
				out.append(p.kind + ("" if not p.has("style") else ":" + p.style))
		return out
	for kind in where:
		check(kinds.call(where[kind], {}).is_empty(), "no %s without its flag" % kind)
	check(kinds.call("farm", {"hachiro_bell": true}) == ["door_bell"], "the bell hangs once hachiro_bell is set")
	check(kinds.call("farm", {"hachiro_bell": false}).is_empty(), "no bell while hachiro_bell is false")
	check(kinds.call("house", {"tome_grandma": true}) == ["ume_jar"], "Tome's jar is in the house once tome_grandma is set")
	check(kinds.call("farm", {"kota_streamer": true}) == ["carp_streamer"], "Kota's streamer flies once kota_streamer is set (band 6)")
	check(kinds.call("farm", {"kota_streamer": true, "hachiro_bell": true}) == ["door_bell", "carp_streamer"], "the bell and the streamer together")
	var pole: Dictionary = MapManager.load_map("farm", null, {"kota_streamer": true})[1].prop_at(Vector2i(1, 6))
	var grid := FarmGrid.new({})
	grid.generate(RandomNumberGenerator.new())
	check(pole.get("kind", "") == "carp_streamer" and not grid.fixed.has(Vector2i(1, 6)), "the streamer stands on open ground at the front left of the house")
	check(kinds.call("town", {"sayo_sign": "old"}) == ["store_sign:old"], "sayo_sign old: the old name repainted")
	check(kinds.call("town", {"sayo_sign": "new"}) == ["store_sign:new"], "sayo_sign new: Sayo's own sign")
	check(kinds.call("town", {"sayo_sign": true}).is_empty(), "sayo_sign set to true (no answer) shows no sign")
	check(kinds.call("town", {"hachiro_bell": true, "tome_grandma": true}).is_empty(), "other flags show no sign")
	check(MapManager.gate_flags(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/town.json"))) == ["sayo_sign"],
		"the village is gated by sayo_sign only")
	var bell: Dictionary = MapManager.load_map("farm", null, {"hachiro_bell": true})[1].prop_at(Vector2i(5, 3))
	check(bell.get("use", "") == "examine" and root.get_node("Sfx").sounds.has(bell.get("sound", "")) and str(bell.get("message", "")) != "",
		"the bell rings with a known sound and a message")
	var jar_map: MapData = MapManager.load_map("house", ["chest", "kitchen", "room"], {"tome_grandma": true})[1]
	check(jar_map.prop_at(Vector2i(5, 1)).get("kind", "") == "ume_jar" and jar_map.is_solid(Vector2i(5, 1)),
		"the jar stands on its own cell with every extension built")
	for key in ["story:door_bell", "story:sign_old", "story:sign_new", "story:ume_jar", "story:carp_streamer"]:
		var img := PlaceholderArt.tex(key).get_image()
		check(img.get_width() > 8 and img.get_pixel(img.get_width() / 2, img.get_height() / 2) != Color.MAGENTA, "art %s is drawn" % key)

	# The shared flags (Game.flags): the cached map follows them, and they come back with a save.
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var a: Node = game_script.new()
	a.crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	a.new_game()
	var on := func(id: String, kind: String) -> bool:
		return MapManager.data(id).props.any(func(p): return p.kind == kind)
	check(not on.call("farm", "door_bell") and not on.call("town", "store_sign"), "a new game has no story props")
	a.flags["hachiro_bell"] = true   # as the event's "set" step writes it
	a.flags["sayo_sign"] = "new"
	check(on.call("farm", "door_bell") and on.call("town", "store_sign") and not on.call("house", "ume_jar"),
		"setting the flags puts the bell and the sign in the cached maps")
	var saved: Dictionary = a.to_dict()
	a.new_game()
	check(not on.call("farm", "door_bell"), "a new game takes the bell away again")
	var b: Node = game_script.new()
	b.crops = a.crops
	b.new_game()
	check(b.from_dict(JSON.parse_string(JSON.stringify(saved))) == "", "the save loads")
	var sign: Array = MapManager.data("town").props.filter(func(p): return p.kind == "store_sign")
	check(on.call("farm", "door_bell") and sign.size() == 1 and sign[0].style == "new" and not on.call("house", "ume_jar"),
		"the bell and Sayo's sign come back with the save")

	# Both views draw them from the story art.
	var town_3d: Node3D = load("res://scripts/world3d/map_world.gd").new()
	town_3d.build(MapManager.data("town"))
	var sign_tex := PlaceholderArt.tex("story:sign_new")
	check(town_3d.get_children().any(func(n): return n is MeshInstance3D and n.material_override is StandardMaterial3D 		and n.material_override.albedo_texture == sign_tex), "the village in 3D has Sayo's sign")
	town_3d.free()
	var farm_3d: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	farm_3d.make_story_props(MapManager.data("farm"))
	var bell_tex := PlaceholderArt.tex("story:door_bell")
	check(farm_3d.get_children().any(func(n): return n is Sprite3D and n.texture == bell_tex), "the farm in 3D has the bell")
	farm_3d.free()
	var town_2d := MapView.new()
	town_2d.map = MapManager.data("town")
	var story_2d := StoryView.new(town_2d.map)
	check(story_2d.map.props.filter(func(p): return p.kind in StoryView.KINDS).size() == 1, "the flat view gets the one sign")
	town_2d.free()
	story_2d.free()

	# Using the bell on the farm (the real Game autoload, as the views call it).
	var g: Node = root.get_node("Game")
	g.new_game()
	g.flags["hachiro_bell"] = true
	g.maps.place("farm", Vector2i(5, 4), Vector2i.UP)
	var said := []
	var hear := func(t): said.append(t)
	g.message.connect(hear)
	load("res://scripts/farm_actions.gd").interact(Vector2i(5, 3))
	g.message.disconnect(hear)
	check(said == [bell.message], "using the bell rings it %s" % [said])

	# Solid story props on the farm block in FarmGrid (the farmer in both views, the dog,
	# throws) while their flag shows them; the bell on the house wall is not solid.
	check(not g.farm.is_solid(Vector2i(1, 4)) and g.farm.can_farm(Vector2i(1, 4)), "no lumber: its cells are open ground")
	g.flags[g.BUILD_FLAG] = "kitchen"
	g.flags["kota_streamer"] = true
	for c in [Vector2i(1, 4), Vector2i(1, 5), Vector2i(1, 6)]:
		check(g.farm.is_solid(c) and g.maps.is_solid(c, g.farm) and not g.farm.can_farm(c) and not g.farm.till(c),
			"the lumber and the streamer pole block %s" % c)
	# under_prop, not is_solid: the field is rolled at random and a rock or weed may lie there.
	check(not g.farm.under_prop(Vector2i(2, 4)) and not g.farm.under_prop(Vector2i(2, 5)) and not g.farm.under_prop(Vector2i(1, 7)),
		"the cells beside them stay open (Hachiro works and fetches from there)")
	check(MapManager.data("farm").prop_at(Vector2i(5, 3)).get("kind", "") == "door_bell" and not MapManager.data("farm").is_solid(Vector2i(5, 3)),
		"the bell's prop is not solid")
	check(g.farm.throw_target(Vector2i(4, 5), Vector2i.LEFT, 4, ["bin"], ["pond"]) == {"result": "land", "cell": Vector2i(2, 5)},
		"a throw at the lumber drops before it")
	var nights := FarmGrid.new({})
	nights.generate(RandomNumberGenerator.new())
	nights.prop_blocks = g.farm_prop_blocks
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 400:
		nights.day_end("spring", "sunny", rng)
	check(nights.cell(Vector2i(1, 4)).obj == FarmGrid.Obj.NONE and nights.cell(Vector2i(1, 6)).obj == FarmGrid.Obj.NONE
		and nights.cell(Vector2i(2, 5)).obj != FarmGrid.Obj.NONE, "no weeds grow under them (beside them they do)")
	g.maps.place("farm", Vector2i(3, 4), Vector2i.LEFT)
	said.clear()
	g.message.connect(hear)
	load("res://scripts/farm_actions.gd").interact(Vector2i(1, 4))
	g.message.disconnect(hear)
	check(said.size() == 1 and said[0].begins_with("Planed boards"), "the lumber can still be looked at %s" % [said])
	g.flags.erase(g.BUILD_FLAG)
	g.flags.erase("kota_streamer")
	check(not g.farm.is_solid(Vector2i(1, 4)) and not g.farm.is_solid(Vector2i(1, 6)) and g.farm.can_farm(Vector2i(1, 5)),
		"gone with their flags: open ground again")
	for n in [a, b]:
		n.free()


## What Genzo's and Ichiro's heart events leave out in the lanes: the jizo's new red bibs in
## Kaminoda (genzo_jizo, heart_genzo_5) and the farmer's thumbprint on Ichiro's kiln in
## Sakurazaka (ichiro_mark, heart_ichiro_6). Gated by the flags the events set, drawn in both
## views, and examining the jizo or the kiln reads the line for what is there.
func _lane_and_kiln_props() -> void:
	var sets := func(event: String) -> Dictionary:
		var out := {}
		for step in JSON.parse_string(FileAccess.get_file_as_string("res://data/events/%s.json" % event)).steps:
			if step.get("do", "") == "set":
				out.merge(step.flags)
		return out
	check(sets.call("heart_genzo_5").get("genzo_jizo", false) and sets.call("heart_ichiro_6").get("ichiro_mark", false),
		"the events set genzo_jizo and ichiro_mark")
	var raw := func(id: String) -> Variant:
		return JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/%s.json" % id))
	check(MapManager.gate_flags(raw.call("kaminoda")) == ["genzo_jizo"] and MapManager.gate_flags(raw.call("sakurazaka")) == ["ichiro_mark", "ichiro_kiln"],
		"Kaminoda is gated by genzo_jizo, Sakurazaka by ichiro_mark and ichiro_kiln")
	var kinds := func(id: String, f: Dictionary) -> Array:
		var out := []
		for p in MapManager.load_map(id, null, f)[1].props:
			if p.kind in StoryView.KINDS:
				out.append(p.kind)
		return out
	check(kinds.call("kaminoda", {}).is_empty() and kinds.call("sakurazaka", {}).is_empty(), "no bibs or third mark without their flags")
	check(kinds.call("kaminoda", {"genzo_jizo": true}) == ["jizo_bibs", "jizo_bibs"], "both jizo by the lane wear new bibs once genzo_jizo is set")
	check(kinds.call("sakurazaka", {"ichiro_kiln": true}) == ["kiln_site"], "the new kiln is going up once ichiro_kiln is set (and nothing else)")
	check(kinds.call("sakurazaka", {"ichiro_kiln": true, "ichiro_mark": true}) == ["kiln_mark", "kiln_new"],
		"once ichiro_mark is set too the site gives way to the finished kiln and the farmer's thumbprint")
	check(kinds.call("sakurazaka", {"ichiro_mark": true}) == ["kiln_mark", "kiln_new"], "ichiro_mark alone shows the finished kiln")
	check(kinds.call("kaminoda", {"ichiro_mark": true}).is_empty() and kinds.call("sakurazaka", {"genzo_jizo": true}).is_empty(),
		"each flag shows only its own prop")
	check(kinds.call("minamino", {"genzo_jizo": true}).is_empty(), "the other villages' jizo keep their old bibs")
	var lane: MapData = MapManager.load_map("kaminoda", null, {"genzo_jizo": true})[1]
	for c in [Vector2i(8, 12), Vector2i(9, 12)]:
		var bib := lane.prop_at(c)
		check(bib.get("kind", "") == "jizo_bibs" and bib.get("use", "") == "examine" and lane.is_solid(c)
			and lane.props.any(func(p): return p.kind == "jizo" and p.cell == c), "the bib is on the jizo at %s, which still blocks" % c)
	var plain_lane: MapData = MapManager.load_map("kaminoda", null, {})[1]
	check(plain_lane.prop_at(Vector2i(8, 12)).get("kind", "") == "jizo", "without the flag the jizo is the prop there")
	var kiln_map: MapData = MapManager.load_map("sakurazaka", null, {})[1]
	var kiln := kiln_map.prop_at(Vector2i(23, 17))
	check(kiln.get("kind", "") == "kiln" and kiln.size == Vector2i(2, 2) and kiln_map.is_solid(Vector2i(24, 18)) and str(kiln.get("message", "")) != "",
		"the kiln stands below Ichiro's house, 2 x 2 and solid, with a line to read")
	for c in [Vector2i(22, 16), Vector2i(25, 16), Vector2i(19, 16), Vector2i(25, 18)]:
		check(not kiln_map.is_solid(c), "the kiln leaves %s open (Ichiro's path and work spot, the kiln spawn)" % c)
	var marked: MapData = MapManager.load_map("sakurazaka", null, {"ichiro_mark": true})[1]
	var site: MapData = MapManager.load_map("sakurazaka", null, {"ichiro_kiln": true})[1]
	var site_prop := site.prop_at(Vector2i(21, 18))
	check(site_prop.get("kind", "") == "kiln_site" and site_prop.size == Vector2i(2, 2) and site.is_solid(Vector2i(20, 17))
		and site.prop_at(Vector2i(24, 18)).get("kind", "") == "kiln", "the site is a solid 2 x 2 beside the old kiln, which stays")
	check(site.prop_at(Vector2i(24, 18)).cell == kiln.cell and not site.is_solid(Vector2i(22, 18)) and not site.is_solid(Vector2i(18, 18)),
		"the old kiln has not moved and the cells between and the newkiln spawn stay open")
	var mark := marked.prop_at(Vector2i(21, 18))
	check(mark.get("kind", "") == "kiln_mark" and mark.cell == site_prop.cell and mark.size == kiln.size and mark.message != kiln.message
		and marked.prop_at(Vector2i(24, 18)).get("kind", "") == "kiln", "with ichiro_mark, the new kiln reads the line about the farmer's print; the old kiln stays")
	check(MapManager.data("sakurazaka").spawns.has("newkiln"), "the newkiln spawn exists (screenshots)")
	for key in ["story:jizo_bibs", "story:kiln_mark", "story:kiln_site", "story:kiln_new"]:
		var img := PlaceholderArt.tex(key).get_image()
		check(img.get_width() >= 6 and img.get_pixel(img.get_width() / 2, img.get_height() / 2) != Color.MAGENTA, "art %s is drawn" % key)

	# 3D: the new red cloth on the jizo, a third thumbprint on the kiln.
	var count := func(m: MapData, color: Color) -> int:
		var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
		w.build(m)
		var n := w.get_children().filter(func(c): return c is MeshInstance3D and c.material_override is StandardMaterial3D and c.material_override.albedo_color == color).size()
		w.free()
		return n
	var new_red: Color = load("res://scripts/world3d/outdoor_props.gd").NEW_RED
	check(count.call(plain_lane, new_red) == 0 and count.call(lane, new_red) == 2, "in 3D the new red cloth is there only with the flag (one mesh a jizo)")
	var dark := Color("4a2e1c")
	check(count.call(kiln_map, dark) == 2 and count.call(marked, dark) == 4, "in 3D the old kiln has two thumbprints; the finished new one adds Ichiro's and the farmer's")
	check(count.call(site, dark) == 2, "in 3D the site has no thumbprints yet (only the old kiln's two)")
	var wear: Color = Color("2e1d12")
	check(count.call(kiln_map, wear) == 1 and count.call(site, wear) == 1 and count.call(marked, wear) == 1,
		"in 3D the old kiln keeps its cracks while the new kiln goes up beside it")
	var brick: Color = Color("b4553a")
	check(count.call(kiln_map, brick) == 0 and count.call(site, brick) >= 1 and count.call(marked, brick) == 0,
		"in 3D the clay bricks are there only while the kiln is going up")
	# Flat view: StoryView draws them, MapView has a colour for the kiln.
	var flat := StoryView.new(lane)
	check(MapView.COLORS.has("kiln") and flat.map.props.filter(func(p): return p.kind in StoryView.KINDS).size() == 2,
		"the flat view has the kiln's colour and the two bibs")
	var wear_img: Image = PlaceholderArt.tex("story:kiln_worn").get_image()
	check(wear_img.get_size() == Vector2i(32, 32) and wear_img.get_pixel(6, 6) == Color("2e1d12") and wear_img.get_pixel(0, 0).a == 0.0,
		"the flat old kiln has its cracks as a 32 x 32 overlay (dark lines, the rest see-through)")
	flat.free()

	# Examining them in the game (the real Game, as the views call it).
	var g: Node = root.get_node("Game")
	g.new_game()
	var said := []
	var hear := func(t): said.append(t)
	g.message.connect(hear)
	var fa: GDScript = load("res://scripts/farm_actions.gd")
	g.maps.place("sakurazaka", Vector2i(25, 18), Vector2i.LEFT)
	fa.interact(Vector2i(24, 18))
	g.flags["ichiro_kiln"] = true
	fa.interact(Vector2i(21, 18))
	g.flags["ichiro_mark"] = true
	fa.interact(Vector2i(21, 18))
	g.maps.place("kaminoda", Vector2i(9, 13), Vector2i.UP)
	fa.interact(Vector2i(9, 12))
	g.flags["genzo_jizo"] = true
	fa.interact(Vector2i(9, 12))
	g.message.disconnect(hear)
	check(said == [kiln.message, site_prop.message, mark.message, lane.prop_at(Vector2i(9, 12)).message],
		"examining: the old kiln, the site, the new kiln with the farmer's print, then the bibs (the old jizo says nothing) %s" % [said])
	g.new_game()


## Game: the clock stops indoors, map signals, day end puts the farmer home, the saved part.
func _game_maps() -> void:
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var g: Node = game_script.new()
	g.crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	g.rng.seed = 3
	g.new_game()
	var seen := {"changed": [], "entered": []}
	g.map_changed.connect(func(id): seen.changed.append(id))
	g.map_entered.connect(func(id): seen.entered.append(id))
	check(g.maps.id == "farm" and g.ticking(), "a new game starts on the farm, ticking")
	check(g.go_to_map("house", Vector2i(4, 5), Vector2i.UP), "into the house")
	check(seen.changed == ["house"] and seen.entered.is_empty(), "map_changed at once, map_entered waits for the view")
	g.map_arrived()
	check(seen.entered == ["house"], "map_entered after the fade")
	check(g.indoors() and not g.ticking() and not g.paused(), "indoors: no time, but not paused (the farmer walks)")
	var before: String = g.time_text()
	g._process(30.0)
	check(g.time_text() == before, "no time passes indoors (%s)" % g.time_text())
	check(not g.go_to_map("moon", Vector2i.ZERO, Vector2i.DOWN) and g.maps.id == "house", "an unknown map is refused")
	g.use_door({"to": "", "message": "Locked."})
	check(g.maps.id == "house", "a door with only a message goes nowhere")
	# A villager's home: in by day, shut at night with its message.
	var said := []
	g.message.connect(func(text): said.append(text))
	var tome_door: Dictionary = MapManager.data("town").door_at(Vector2i(5, 6))
	g.go_to_map("town", Vector2i(5, 7), Vector2i.UP)
	g.hour = 19
	g.minute = 30
	g.use_door(tome_door)
	check(g.maps.id == "town" and not said.is_empty() and said.back() == tome_door.closed, "Tome's house is shut at 19:30 %s" % [said])
	g.hour = 8
	g.minute = 0
	g.use_door(tome_door)
	check(g.maps.id == "tome_house" and g.maps.pos == MapManager.cell_pos(Vector2i(4, 5)) and g.indoors(), "and open at 8:00")
	g.use_door(MapManager.data("tome_house").doors[0])
	check(g.maps.id == "town" and g.maps.pos == MapManager.cell_pos(Vector2i(5, 7)), "out again in front of her door")
	g.go_to_map("house", Vector2i(4, 5), Vector2i.UP)
	g.use_door(MapManager.data("house").doors[0])
	check(g.maps.id == "farm" and g.maps.pos == MapManager.cell_pos(Vector2i(4, 4)) and g.maps.facing == Vector2i.DOWN, "out of the house to the farm door")
	check(g.ticking(), "outside the clock runs again")
	g._process(1.0)
	check(g.time_text() != before, "time passes outside")
	# Arriving on a cell where a weed grew pushes it aside.
	g.farm.cell(Vector2i(30, 6)).obj = FarmGrid.Obj.WEED
	g.go_to_map("farm", Vector2i(30, 6), Vector2i.LEFT)
	check(g.farm.cell(Vector2i(30, 6)).obj == FarmGrid.Obj.NONE, "arrival cell cleared")
	# Night: wake at home, in the house by the futon.
	g.go_to_map("town", Vector2i(2, 10), Vector2i.RIGHT)
	g.end_day()
	var home: Array = MapManager.data("house").spawns.home
	check(g.maps.id == "house" and g.maps.pos == MapManager.cell_pos(home[0]), "a new day starts at home")
	# The saved part, and checks on it.
	g.maps.pos = Vector2(40.6, 50.2)
	var d: Dictionary = g.maps.to_dict()
	check(d == {"id": "house", "x": 41, "y": 50, "facing": [0, 1]}, "map save data %s" % d)
	check(MapManager.check_saved(d)[0] == "", "saved map checks")
	for bad in [{"id": "moon", "x": 1, "y": 1, "facing": [0, 1]}, {"id": "house", "x": 999, "y": 1, "facing": [0, 1]},
			{"id": "house", "x": 1, "y": 1, "facing": [1, 1]}, {"id": "house", "x": 1.5, "y": 1, "facing": [0, 1]}, "house"]:
		check(MapManager.check_saved(bad)[0] != "", "refused saved map %s" % str(bad))
	g.free()


## On the real Game: the futon sleeps, the farm door leads in, tools rest indoors.
func _bed_and_doors() -> void:
	var g: Node = root.get_node("Game")
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	var keep_save := SaveGame.snapshot()   # the slot, its backup and temp file
	g.new_game()
	actions.interact(Vector2i(4, 3))
	check(g.maps.id == "house" and g.maps.facing == Vector2i.UP, "using the farm house door goes in")
	var day: int = g.day
	var stamina: int = g.stamina
	g.select_tool(g.TOOLS.find("hoe"))
	actions.use_tool(Vector2i(3, 3), Vector2i.DOWN, 0)
	check(g.stamina == stamina, "no tool swings indoors")
	actions.interact(Vector2i(1, 2))
	check(g.day == day + 1 and g.maps.id == "house", "the futon sleeps (next day, still home)")
	actions.on_action("enter", Vector2i(4, 5), Vector2i.DOWN)
	check(g.maps.id == "farm", "walking into the house door goes out")
	# Sleeping wrote the real save slot: put it back.
	SaveGame.restore(keep_save)
	g.new_game()


## The village clinic: a small house east of the smithy, its door clear of the river lane, a
## path down to the road; inside a bed (no sleeping), the doctor's counter and the way out.
func _clinic() -> void:
	var t := MapManager.data("town")
	var d := t.door_at(Vector2i(33, 6))
	check(d.get("to", "") == "clinic" and d.get("shop", "") == "clinic", "the small house east of the smithy is the clinic")
	var house: Dictionary = t.prop_at(Vector2i(32, 5))
	check(house.get("kind", "") == "village_house" and Vector2i(house.cell).x + int(house.door) == 33, "the clinic house draws its door at the door cell")
	for y in [7, 8, 9]:
		check(t.tile(Vector2i(33, y)) == "path" and not t.is_solid(Vector2i(33, y)), "a path from the clinic door to the road (33, %d)" % y)
	check(Vector2i(t.spawns.clinic[0]) == Vector2i(33, 7) and t.spawns.clinic[1] == Vector2i.DOWN, "the town's clinic spawn is outside its door")
	check(Vector2i(house.cell).x > 10, "the clinic is far from the river lane on the west side")
	var c := MapManager.data("clinic")
	check(c.indoor and c.door_at(Vector2i(4, 6)).to == "town" and Vector2i(c.door_at(Vector2i(4, 6)).spawn) == Vector2i(33, 7), "clinic: indoors, door back to the village by its door")
	var bed: Vector2i = c.spawns.bed[0]
	check(not c.is_solid(bed) and c.prop_at(bed + Vector2i.LEFT).get("kind", "") == "futon" and c.prop_at(bed + Vector2i.LEFT).get("use", "") == "",
		"the bed spawn stands by the clinic bed, which doesn't sleep")
	check(not c.is_solid(c.spawns.keeper[0]) and not c.is_solid(c.spawns.counter[0]), "the doctor's spot and the counter spot are free")


## Through the clinic door while it is open, shut after hours; its bed is not the farmer's futon.
func _clinic_doors() -> void:
	var g: Node = root.get_node("Game")
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	g.new_game()
	var said := []
	var note := func(t): said.append(t)
	g.message.connect(note)
	var door := MapManager.data("town").door_at(Vector2i(33, 6))
	g.go_to_map("town", Vector2i(33, 7), Vector2i.UP)
	g.hour = 20
	g.use_door(door)
	check(g.maps.id == "town" and said.size() > 0 and said.back().begins_with("Hinata Clinic is closed"), "the clinic is shut at 20:00 (%s)" % [said])
	g.hour = 10
	g.use_door(door)
	check(g.maps.id == "clinic", "an open clinic's door leads in")
	var day: int = g.day
	actions.interact(Vector2i(1, 2))
	check(g.day == day and g.maps.id == "clinic", "the clinic bed doesn't sleep")
	g.message.disconnect(note)
	g.new_game()


## The cells reachable on foot from `from` (not solid, inside the map).
func _walkable(m: MapData, from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var todo: Array = [from]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for o in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + o
			if m.in_bounds(n) and not seen.has(n) and not m.is_solid(n):
				seen[n] = true
				todo.append(n)
	return seen


## A world3d script by its file name, loaded when the tests run (it reaches the Game autoload).
## Hearth smoke (HearthSmoke, data/smoke.json): the farmhouse and every village house on an
## outdoor map send up smoke at meal times (7:00 yes, 12:00 no), indoors none; a storm buries it;
## the wind leans it; the farmhouse's vent sits over its ridge.
func _hearth_smoke() -> void:
	var HS: GDScript = _k("hearth_smoke")   # loaded at run time: a class name here would compile farm_world too early
	var g: Node = root.get_node("Game")
	var hour0: int = g.hour
	var min0: int = g.minute
	var weather0: String = g.weather_today
	var cfg: Dictionary = HS.config()
	check(cfg.windows.size() == 2 and int(cfg.puffs) > 0, "smoke data: two meal windows and puffs (%s)" % [cfg.windows])
	check(HS.strength_at(7.0) == 1.0 and HS.strength_at(18.0) == 1.0, "smoke: full at 7:00 and 18:00")
	check(HS.strength_at(12.0) == 0.0 and HS.strength_at(3.0) == 0.0, "smoke: none at noon or 3:00")
	check(HS.strength_at(6.0) == 0.0 and HS.strength_at(20.0) == 0.0, "smoke: none at the window's edges (6:00, 20:00)")
	var mid: float = HS.strength_at(6.0 + float(cfg.fade_hours) / 2.0)
	check(mid > 0.0 and mid < 1.0, "smoke: eases in over the fade (%.2f)" % mid)
	# The farmhouse: over the ridge's middle (Minka.roof: eave Rect2(1.45, 0.55, 6.1, 3.5), soffit 1.45, pitch 1.25).
	var farm: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	farm._make_hearth_smoke()
	var farm_smoke := farm.get_children().filter(func(n): return n.get_script() == HS)
	check(farm_smoke.size() == 1, "the farmhouse has one hearth smoke (%d)" % farm_smoke.size())
	if farm_smoke.size() == 1:
		var fs: Node3D = farm_smoke[0]
		check(fs.position.distance_to(Vector3(4.5, 1.45 + 1.75 * 1.25 + HS.RIDGE_LIFT, 2.3)) < 0.001, "the farmhouse's smoke rises from the ridge's middle (%s)" % fs.position)
		g.hour = 7
		g.minute = 0
		fs.refresh()
		check(fs.visible and fs.strength() == 1.0, "farmhouse smoke at 7:00")
		g.hour = 12
		fs.refresh()
		check(not fs.visible and fs.strength() == 0.0, "farmhouse smoke gone at 12:00")
		g.hour = 7
		fs.refresh()
		g.weather_today = "storm"
		if g.weather_look("storm", g.season_name()) == "storm":
			fs.refresh()
			check(not fs.visible, "a storm buries the farmhouse's smoke")
		g.weather_today = weather0
		# The wind leans the puffs: a gale moves the top of a rise further than a calm day.
		fs.refresh()
		var calm: Array = []
		for mi in fs._puffs:
			calm.append(mi.position.x)
		farm.set_wind(1.0)
		fs.refresh()
		var gale: Array = []
		for mi in fs._puffs:
			gale.append(mi.position.x)
		var leans := false
		for i in calm.size():
			leans = leans or absf(gale[i] - calm[i]) > 0.001
		check(leans, "the wind leans the farmhouse's smoke")
	farm.free()
	# A village: every house with its own smoke, shown at 7:00, gone at noon; indoors none.
	var town_data := MapManager.data("town")
	var houses := 0
	for p in town_data.props:
		if p.kind == "village_house":
			houses += 1
	var town: Node3D = load("res://scripts/world3d/map_world.gd").new()
	town.build(town_data)
	var smokes := town.get_children().filter(func(n): return n.get_script() == HS)
	check(houses > 0 and smokes.size() == houses, "town: one hearth smoke per village house (%d of %d)" % [smokes.size(), houses])
	g.hour = 7
	g.minute = 0
	var shown := 0
	for n in smokes:
		n.refresh()
		shown += 1 if n.visible else 0
	check(shown == smokes.size() and smokes.size() > 0, "town: every house smokes at 7:00 (%d)" % shown)
	g.hour = 12
	var still := 0
	for n in smokes:
		n.refresh()
		still += 1 if n.visible else 0
	check(still == 0, "town: no smoke at noon (%d)" % still)
	# The first house's vent stands over its roof, not in the walls.
	if not smokes.is_empty():
		var at: Vector3 = smokes[0].position
		check(at.y > 2.0 and at.y < 4.5, "a village house's vent is over its roof (%.2f)" % at.y)
	# The rules both views share (SmokeRules): the 3D smoke asks them, so the two cannot drift apart.
	var SR: GDScript = load("res://scripts/smoke_rules.gd")
	check(SR.strength_at(7.0) == HS.strength_at(7.0) and SR.strength_at(6.1) == HS.strength_at(6.1), "SmokeRules and HearthSmoke give the same strength")
	g.hour = 7
	g.minute = 0
	g.weather_today = "sunny"
	check(SR.strength_now(g) == 1.0, "SmokeRules.strength_now: 7:00 in fair weather")
	g.hour = 12
	check(SR.strength_now(g) == 0.0 and SR.strength_now(null) == 0.0, "SmokeRules.strength_now: noon, and no clock, none")
	g.hour = 7
	g.weather_today = "storm"
	if g.weather_look("storm", g.season_name()) == "storm":
		check(SR.strength_now(g) == 0.0, "SmokeRules.strength_now: a storm buries it")
	g.weather_today = weather0
	check(SR.farm_vent().is_equal_approx(Vector3(4.5, 1.45 + 1.75 * 1.25 + SR.RIDGE_LIFT, 2.3)), "SmokeRules.farm_vent is the ridge's middle")
	check(SR.village_vents(town_data.props).size() == houses, "SmokeRules.village_vents: one per village house")
	var q0: Dictionary = SR.puff(0.0, 0, 4, 0, 0.0)
	var q1: Dictionary = SR.puff(0.0, 0, 4, 0, 1.0)
	check(is_equal_approx(float(q0.u), 0.0) and float(q0.alpha) == 0.0 and float(q1.lean) == 0.0, "a puff starts at the vent, clear")
	var qa: Dictionary = SR.puff(1.5, 0, 4, 0, 0.0)
	var qb: Dictionary = SR.puff(1.5, 0, 4, 0, 1.0)
	check(float(qb.lean) > float(qa.lean) and float(qa.grow) > 1.0, "the wind leans a puff more; it grows as it rises")
	town.free()
	var inside: Node3D = load("res://scripts/world3d/map_world.gd").new()
	inside.build(MapManager.data("tome_house"))
	check(inside.get_children().filter(func(n): return n.get_script() == HS).is_empty(), "indoors (Tome's house): no hearth smoke")
	inside.free()
	g.hour = hour0
	g.minute = min0
	g.weather_today = weather0


func _k(file: String) -> GDScript:
	return load("res://scripts/world3d/%s.gd" % file)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


## Faster first visits (2026-11-07): meshes the same every build are kept a run (MeshCache) and
## placed again; a world built again looks the same piece by piece, with its own materials.
func _mesh_cache() -> void:
	var MeshCacheS: GDScript = load("res://scripts/world3d/mesh_cache.gd")
	var fw: GDScript = load("res://scripts/world3d/farm_world.gd")
	var snow_layer: GDScript = load("res://scripts/world3d/snow_layer.gd")
	var runs := [0]
	var make := func(w: Node3D) -> float:
		runs[0] += 1
		w._box(Vector3(1, 0.5, 1), Vector3(2.5, 0.25, 3.5), w.flat_material(Color("2e221a")))
		w._snow_top(Vector3(0.9, 0.03, 0.9), Vector3(2.5, 0.52, 3.5))
		return 1.5
	var a: Node3D = fw.new()
	var b: Node3D = fw.new()
	var id := "test|box %d" % Time.get_ticks_usec()
	var out_a: Variant = MeshCacheS.build(a, id, make.bind(a))
	var out_b: Variant = MeshCacheS.build(b, id, make.bind(b))
	var ka := a.get_children()
	var kb := b.get_children()
	var same := ka.size() == 2 and kb.size() == 2
	for i in mini(ka.size(), kb.size()):
		same = same and ka[i].mesh == kb[i].mesh and ka[i].transform == kb[i].transform and ka[i].cast_shadow == kb[i].cast_shadow \
			and ka[i].material_override != kb[i].material_override and ka[i].material_override.get_class() == kb[i].material_override.get_class()
	check(runs[0] == 1 and out_a == 1.5 and out_b == 1.5 and same and MeshCacheS.kept(id),
		"mesh cache: the second build places the kept meshes (built %d times, %s / %s, same pieces %s)" % [runs[0], out_a, out_b, same])
	check(b._snow_mats.size() == 1 and kb.size() == 2 and b._snow_mats[0] == kb[1].material_override
		and kb[1].material_override.shader == snow_layer.top_material().shader,
		"mesh cache: the snow top's own material is in the new world's snow (set_snow drives it)")
	a.free()
	b.free()
	# A build with a lit window is kept too: the window is listed on every world, the build ran once.
	runs[0] = 0
	var lit := func(w: Node3D) -> void:
		runs[0] += 1
		w._lit_picture("build:shoji", Vector2(0.5, 0.5), Vector3(1, 1, 1))
	id = "test|lit %d" % Time.get_ticks_usec()
	for i in 2:
		var w: Node3D = fw.new()
		MeshCacheS.build(w, id, lit.bind(w))
		check(w.windows.size() == 1, "mesh cache: a lit window is made on every world (%d)" % i)
		w.free()
	check(runs[0] == 1 and MeshCacheS.kept(id), "mesh cache: a build with a lit window is kept (ran %d times)" % runs[0])
	# One that makes anything else (here a MultiMesh) is not kept: it runs each time.
	runs[0] = 0
	var multi := func(w: Node3D) -> void:
		runs[0] += 1
		w._multi(BoxMesh.new(), [Transform3D()] as Array[Transform3D], w.flat_material(Color.RED))
	id = "test|multi %d" % Time.get_ticks_usec()
	for i in 2:
		var w: Node3D = fw.new()
		MeshCacheS.build(w, id, multi.bind(w))
		check(w.get_child_count() == 1 and w.get_child(0) is MultiMeshInstance3D, "mesh cache: a MultiMesh is made on every world (%d)" % i)
		w.free()
	check(runs[0] == 2 and not MeshCacheS.kept(id), "mesh cache: a build with a MultiMesh is not kept (ran %d times)" % runs[0])
	runs[0] = 0
	id = "test|parts %d" % Time.get_ticks_usec()
	var parts := func(p: RefCounted) -> void:
		runs[0] += 1
		load("res://scripts/world3d/farm_props.gd").block(p.st(Color.RED), Rect2(0, 0, 1, 1), 0.0, Rect2(0, 0, 1, 1), 1.0)
	var m1: Dictionary = MeshCacheS.parts(id, parts)
	var m2: Dictionary = MeshCacheS.parts(id, parts)
	check(runs[0] == 1 and m1 == m2 and m1.size() == 1, "mesh cache: parts are built once and handed out again")
	# Real maps: a second village, farm, room and hill look the same piece by piece and share meshes.
	var g: Node = root.get_node("Game")
	# The farm from one fixed field: Game's own field comes from an unseeded rng, and its share of
	# field pieces (never kept) made the half-shared check pass or fail from run to run.
	var field := FarmGrid.new(g.crops)
	var seeded := RandomNumberGenerator.new()
	seeded.seed = 20261107
	field.generate(seeded)
	for map_id in ["town", "farm", "house", "hill"]:
		var m := MapManager.data(map_id)
		var worlds := []
		for i in 2:
			var w: Node3D = fw.new() if m.farm else load("res://scripts/world3d/map_world.gd").new()
			if m.farm:
				w.setup(field, m.gate_cells())
			else:
				w.build(m)
			worlds.append(w)
		var p0: Array = worlds[0].find_children("*", "GeometryInstance3D", true, false)
		var p1: Array = worlds[1].find_children("*", "GeometryInstance3D", true, false)
		var shared := 0
		var meshes := 0
		var alike: bool = p0.size() == p1.size() and worlds[0].windows.size() == worlds[1].windows.size() \
			and worlds[0]._snow_mats.size() == worlds[1]._snow_mats.size() and worlds[0].occluders.count() == worlds[1].occluders.count()
		var own := true
		for i in mini(p0.size(), p1.size()):
			var x: GeometryInstance3D = p0[i]
			var y: GeometryInstance3D = p1[i]
			alike = alike and x.get_class() == y.get_class() and x.transform.is_equal_approx(y.transform) and x.cast_shadow == y.cast_shadow \
				and x.layers == y.layers and x.visible == y.visible
			if x is MeshInstance3D and y is MeshInstance3D:
				shared += int(x.mesh == y.mesh)
				meshes += 1
				var ma: Material = x.material_override
				var mb: Material = y.material_override
				own = own and (ma == null or ma != mb)
				if ma is StandardMaterial3D and mb is StandardMaterial3D:
					alike = alike and ma.albedo_color == mb.albedo_color and ma.albedo_texture == mb.albedo_texture and ma.transparency == mb.transparency \
						and ma.vertex_color_use_as_albedo == mb.vertex_color_use_as_albedo and ma.shading_mode == mb.shading_mode
				elif ma is ShaderMaterial and mb is ShaderMaterial:
					alike = alike and ma.shader == mb.shader
				if x.mesh is ArrayMesh and y.mesh is ArrayMesh and x.mesh != y.mesh:
					alike = alike and x.mesh.get_surface_count() == y.mesh.get_surface_count() \
						and x.mesh.surface_get_array_len(0) == y.mesh.surface_get_array_len(0)
		check(alike and own and shared * 2 > meshes,
			"mesh cache: %s built again looks the same (%d pieces, %d of %d meshes shared, own materials %s, alike %s)" % [map_id, p0.size(), shared, meshes, own, alike])
		for w in worlds:
			w.free()
	check(PlaceholderArt.image("ground:grass:0").get_data() == PlaceholderArt.tex("ground:grass:0").get_image().get_data(),
		"the kept tile pictures are the textures' pictures")


## A thing that fades in the farmer's way gets its own materials (Occluders.add): one only its
## meshes hold is used as it is (no copy), one anything else holds is copied (cheaper rebuilds,
## 2026-11-07).
func _occluder_own() -> void:
	var occ: RefCounted = _k("occluders").new()
	var parent := Node3D.new()
	var fresh: Array[int] = []
	for i in 3:
		var mi := MeshInstance3D.new()
		mi.mesh = BoxMesh.new()
		mi.mesh.size = Vector3(1, 2, 1)
		mi.material_override = StandardMaterial3D.new()
		parent.add_child(mi)
		fresh.append(mi.material_override.get_instance_id())
	# Two meshes wear one material, which nothing else holds.
	var kids := parent.get_children()
	kids[2].material_override = kids[1].material_override
	fresh[2] = fresh[1]
	var outside := MeshInstance3D.new()   # not in the thing, wears a material of it
	var held := StandardMaterial3D.new()  # and one a variable here holds
	held.albedo_color = Color(0.2, 0.4, 0.6)
	var a := MeshInstance3D.new()
	a.mesh = BoxMesh.new()
	a.mesh.size = Vector3(1, 2, 1)
	a.material_override = held
	parent.add_child(a)
	var shared_with_outside := MeshInstance3D.new()
	shared_with_outside.mesh = BoxMesh.new()
	shared_with_outside.mesh.size = Vector3(1, 2, 1)
	shared_with_outside.material_override = StandardMaterial3D.new()
	outside.material_override = shared_with_outside.material_override
	parent.add_child(shared_with_outside)
	occ.add(parent.get_children())
	kids = parent.get_children()
	var kept_fresh: bool = kids[0].material_override.get_instance_id() == fresh[0] and kids[1].material_override.get_instance_id() == fresh[1] \
		and kids[1].material_override == kids[2].material_override
	check(kept_fresh, "occluders: a material only the thing's meshes hold is used as it is, still one for both that share it")
	check(kids[3].material_override != held and kids[3].material_override.albedo_color == held.albedo_color
		and kids[4].material_override != outside.material_override,
		"occluders: a material held elsewhere (a variable, a mesh outside) is copied")
	# The copy is the same as duplicate() would make.
	var src: StandardMaterial3D = _k("farm_world").surface_material("build:plaster")
	src.albedo_color = Color(0.9, 0.8, 0.7, 0.5)
	src.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	src.set_meta("solid", [0, 1.0])
	var c: Material = _k("mesh_cache").copy(src)
	var d: Material = src.duplicate()
	var same := c != src
	for prop in d.get_property_list():
		if prop.usage & PROPERTY_USAGE_STORAGE:
			var x: Variant = c.get(prop.name)
			var y: Variant = d.get(prop.name)
			same = same and typeof(x) == typeof(y) and x == y
	check(same and c.get_meta("solid") == [0, 1.0], "mesh cache: a material made from its recipe equals its duplicate()")
	outside.free()
	parent.free()


## Village houses (lit windows, a shop's noren in the wind), the farmhouse and the stand are kept
## a run too (MeshCache): a second world gets the same windows, the noren in its own Sway, the
## NightLights group, and the same Sway poses.
func _kept_lit_and_swaying() -> void:
	var g: Node = root.get_node("Game")
	var mw: GDScript = load("res://scripts/world3d/map_world.gd")
	var worlds := []
	for i in 2:
		var w: Node3D = mw.new()
		w.build(MapManager.data("town"))
		worlds.append(w)
	var a: Node3D = worlds[0]
	var b: Node3D = worlds[1]
	var house_ids := 0
	for p in MapManager.data("town").props:
		if str(p.kind) == "village_house":
			house_ids += int(_k("mesh_cache").kept("prop|%s|%s|%s|%s" % ["town", p, g.season_name(), _k("snow_layer").map_has_snow(MapManager.data("town"))]))
	check(house_ids == 6, "mesh cache: the village's six houses (the post office since Ren) are kept with their windows (%d)" % house_ids)
	check(a.windows.size() > 0 and a.windows == b.windows and a.lamps == b.lamps and b.is_in_group(_k("night_lights").GROUP),
		"mesh cache: a village built again lists the same lit windows and lamps (%d, %d) and glows" % [b.windows.size(), b.lamps.size()])
	var sa: Node3D = a.get_node_or_null("WindSway")
	var sb: Node3D = b.get_node_or_null("WindSway")
	var ok: bool = sa != null and sb != null and sa.count() == sb.count() and sa.count_of("cloth") > 0
	if ok:
		sa.wind = 0.8
		sb.wind = 0.8
		sa.pose(3.7)
		sb.pose(3.7)
		for i in sa.count():
			ok = ok and sa.kind_of(i) == sb.kind_of(i) and sa.nodes_of(i).size() == sb.nodes_of(i).size()
			for k in sa.nodes_of(i).size():
				var na: Node3D = sa.nodes_of(i)[k]
				var nb: Node3D = sb.nodes_of(i)[k]
				ok = ok and na != nb and nb.get_parent() == b and na.transform.is_equal_approx(nb.transform) \
					and a.get_children().find(na) == b.get_children().find(nb)
	check(ok, "mesh cache: the noren sway in the second village as in the first (own nodes, same poses in a wind)")
	for w in worlds:
		w.free()
	# The farm: the farmhouse with its windows and the stand with its noren are kept.
	var fw: Node3D = _k("farm_world").new()
	fw.setup(g.farm, MapManager.data("farm").gate_cells())
	check(_k("mesh_cache").kept("farm|house") and _k("mesh_cache").kept("farm|stand") and fw.windows.size() == _k("lit_spots").farmhouse().size()
		and fw.get_node_or_null("WindSway") != null,
		"mesh cache: the farmhouse (with its %d windows) and the stand (its noren swaying) are kept" % fw.windows.size())
	fw.free()


## Shader warm-up (ShaderWarm): a material's kind is its switches and textures, not its colours;
## a world's new kinds (with the faded twins of what fades) are kept once and drawn by tiny quads
## in front of the camera.
func _shader_warm() -> void:
	var a: StandardMaterial3D = _k("farm_world").surface_material("build:plaster")
	var b: StandardMaterial3D = _k("farm_world").surface_material("build:plaster")
	b.albedo_color = Color(0.3, 0.5, 0.7)
	var c: StandardMaterial3D = _k("farm_world").flat_material(Color.RED)
	check(_k("shader_warm").signature(a) == _k("shader_warm").signature(b) and _k("shader_warm").signature(a) != _k("shader_warm").signature(c)
		and _k("shader_warm").signature(a) != _k("shader_warm").signature(_k("shader_warm").faded(a)) and _k("shader_warm").signature(a) != _k("shader_warm").signature(a, true),
		"shader warm: one kind for the same switches in another colour; another when flat, faded or on a MultiMesh")
	_k("shader_warm").clear()
	var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
	w.build(MapManager.data("town"))
	var first: Array = _k("shader_warm").news(w)
	var again: Array = _k("shader_warm").news(w)
	var faded := first.filter(func(k): return k.mat is StandardMaterial3D and k.mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA)
	var multi := first.filter(func(k): return k.multi)
	check(first.size() > 5 and again.is_empty() and faded.size() > 0 and multi.size() > 0 and _k("shader_warm").count() == first.size(),
		"shader warm: the village's kinds kept once (%d, %d faded, %d on MultiMeshes; again %d)" % [first.size(), faded.size(), multi.size(), again.size()])
	var cam := Camera3D.new()
	var holder := Node3D.new()
	holder.add_child(cam)
	var node: Node3D = _k("shader_warm").show(holder, cam, first)
	var near := true
	var quads: Array = node.get_children().filter(func(q): return q is GeometryInstance3D)
	for q in quads:
		near = near and (q.position - cam.position).length() < 1.0 and q.material_override in first.map(func(k): return k.mat)
	check(quads.size() == first.size() and near and _k("shader_warm").show(holder, cam, again) == null,
		"shader warm: one tiny quad a new kind, just in front of the camera; none when nothing is new")
	# The night's lamps make another variant on what they light: those quads stand under a lamp
	# like theirs (no shadows, the same cull mask) reaching only the quads; the ground's do not.
	var lamps: Array = node.get_children().filter(func(q): return q is OmniLight3D)
	var lit := first.filter(func(k): return k.lit)
	var reach := true
	var layers_ok := true
	for i in quads.size():
		layers_ok = layers_ok and quads[i].layers == (_k("night_lamps").LIT_MASK if first[i].lit else _k("night_lamps").GROUND_LAYER)
		if lamps.size() == 1:
			reach = reach and (quads[i].position - lamps[0].position).length() < lamps[0].omni_range
	check(lamps.size() == 1 and not lamps[0].shadow_enabled and lamps[0].light_cull_mask == _k("night_lamps").LIT_MASK
		and lamps[0].omni_range < _k("shader_warm").NEAR and reach and layers_ok and lit.size() > 5 and lit.size() < first.size(),
		"shader warm: a lamp over the lit kinds' quads (%d of %d lit), reaching only them" % [lit.size(), first.size()])
	holder.free()
	w.free()
	# A kind first seen on the ground is kept again where a lamp lights it; not the other way.
	_k("shader_warm").clear()
	var plain: StandardMaterial3D = _k("farm_world").flat_material(Color(0.2, 0.6, 0.3))
	var on_ground := MeshInstance3D.new()
	on_ground.material_override = plain
	on_ground.layers = _k("night_lamps").GROUND_LAYER
	var on_wall := MeshInstance3D.new()
	on_wall.material_override = plain
	var wn := Node3D.new()
	wn.add_child(on_ground)
	var ground_first: Array = _k("shader_warm").news(wn)
	wn.add_child(on_wall)
	var then_lit: Array = _k("shader_warm").news(wn)
	var wn2 := Node3D.new()
	var g2 := MeshInstance3D.new()
	g2.material_override = plain.duplicate()
	g2.layers = _k("night_lamps").GROUND_LAYER
	wn2.add_child(g2)
	var ground_after: Array = _k("shader_warm").news(wn2)
	check(ground_first.size() == 1 and not ground_first[0].lit and then_lit.size() == 1 and then_lit[0].lit and ground_after.is_empty(),
		"shader warm: a kind seen on the ground, then lit, is kept lit too; on the ground again, nothing new")
	wn.free()
	wn2.free()
	_k("shader_warm").clear()


## Maps next door built ahead (Main3D._prebuild): while the farmer stands still the farm's
## doors' maps are built a few steps a frame and kept (outdoor first, none past KEEP_WORLDS);
## going through finds the world ready; one half built is finished on the way in.
func _prebuilt_worlds(g: Node) -> void:
	g.maps.place("farm", Vector2i(10, 10), Vector2i.DOWN)
	_scene._enter_map()
	_scene._drop_worlds()
	var before: int = _scene.prebuilt
	_scene.player.moving = true
	_scene._prebuild(1.0)
	check(_scene._pre.is_empty(), "built ahead: nothing while the farmer walks")
	_scene.player.moving = false
	_scene._prebuild(0.1)
	check(_scene._pre.is_empty(), "built ahead: not before the farmer has stood still a moment")
	var first := ""
	for i in 3000:
		_scene._prebuild(0.1)
		if first == "" and not _scene._pre.is_empty():
			first = _scene._pre.id
		if _scene._pre.is_empty() and _scene._next_prebuild() == null:
			break
	var ids: Array = _scene._worlds.keys()
	ids.sort()
	check(first == "town" and ids == ["barn", "coop", "house", "town"] and _scene.prebuilt - before == 4,
		"built ahead from the farm: the village first, then the house, coop and barn (%s first, %s)" % [first, ids])
	var ok := true
	for id in ids:
		var w: Node = _scene._worlds[id].world
		ok = ok and not w.is_inside_tree() and w.away and _scene._worlds[id].key == _scene.world_key(MapManager.data(id))
	check(ok, "built ahead: kept out of the tree, away, for today's look")
	var town_world: Node = _scene._worlds.town.world if _scene._worlds.has("town") else null
	g.maps.place("town", Vector2i(2, 10), Vector2i.RIGHT)
	_scene._enter_map()
	check(town_world != null and _scene.world == town_world and _scene.world.is_inside_tree(), "built ahead: the village is ready on the way in")
	# Half built: the rest of its steps on the way in, the same world.
	_scene._drop_worlds()
	var guard := 0
	while (_scene._pre.is_empty() or _scene._pre.next < 1) and guard < 100:
		_scene._prebuild(0.1)
		guard += 1
	var half_id: String = _scene._pre.get("id", "")
	var half: Node = _scene._pre.get("world")
	var at: int = _scene._pre.get("next", 0)
	var steps: int = _scene._pre.get("steps", []).size()
	check(half_id != "" and at < steps, "built ahead: one under way (%s, step %d of %d)" % [half_id, at, steps])
	if half_id != "" and at < steps:
		var m := MapManager.data(half_id)
		g.maps.place(half_id, m.spawns.values()[0][0], Vector2i.DOWN)
		_scene._enter_map()
		check(_scene.world == half and _scene._pre.is_empty() and _scene.world.get_meta("map_id") == half_id,
			"built ahead: the half built %s is finished on the way in" % half_id)
	_scene._still = 1.0
	_scene._prebuild(0.1)
	_scene._on_day_started()
	check(_scene._pre.is_empty() and _scene._worlds.is_empty(), "built ahead: a new day drops them")

## Walking (playtest 2026-11-07: the farmer stuck on things until wiggled free): straight into a
## corner a few pixels off a gap slides into the gap and through it; a solid cell that came
## over the feet never traps them.
func _walk_slide() -> void:
	var g: Node = root.get_node("Game")
	var farm := FarmGrid.new(g.crops)
	var at := Vector2i(-1, -1)   # a clear 5 x 5 patch of field
	for y in range(4, FarmGrid.H - 6):
		for x in range(4, FarmGrid.W - 6):
			var ok := true
			for dy in 5:
				for dx in 5:
					if not farm.can_farm(Vector2i(x + dx, y + dy)):
						ok = false
			if ok:
				at = Vector2i(x, y)
				break
		if at.x >= 0:
			break
	check(at.x >= 0, "walking: a clear patch of field to test on")
	if at.x < 0:
		return
	for dy in 5:
		for dx in 5:
			farm.cell(at + Vector2i(dx, dy)).obj = FarmGrid.Obj.NONE
	var gap := at + Vector2i(2, 2)
	farm.cell(gap + Vector2i.LEFT).obj = FarmGrid.Obj.ROCK
	farm.cell(gap + Vector2i.RIGHT).obj = FarmGrid.Obj.ROCK
	var saved_farm: FarmGrid = g.farm
	var saved_id: String = g.maps.id
	var saved_pos: Vector2 = g.maps.pos
	g.farm = farm
	g.maps.id = MapManager.FARM
	var p: Node2D = load("res://scripts/player/player.gd").new()
	p.farm = farm
	# Below the gap, 6 px right of its middle: the right foot hits the rock beside it.
	p.position = Vector2(gap.x * 16 + 8 + 6, (gap.y + 1) * 16 + 4)
	var d := Vector2(0, -2)
	check(not p._try_move(d), "walking: 6 px off the gap the step up is blocked by the rock")
	var x0 := p.position.x
	check(p._slide(d) and p.position.x < x0 and p.position.y == (gap.y + 1) * 16 + 4, "walking: blocked, the farmer slides sideways towards the gap (%s)" % p.position)
	for i in 40:
		if not p._try_move(d):
			p._slide(d)
	check(p.position.y < gap.y * 16, "walking: holding up walks round the corner and through the gap (%s)" % p.position)
	# Far off any gap: no slide.
	var q: Node2D = load("res://scripts/player/player.gd").new()
	q.farm = farm
	farm.cell(gap).obj = FarmGrid.Obj.ROCK
	q.position = Vector2(gap.x * 16 + 8, (gap.y + 1) * 16 + 4)
	check(not q._try_move(d) and not q._slide(d) and q.position == Vector2(gap.x * 16 + 8, (gap.y + 1) * 16 + 4), "walking: a wall with no gap near stays a wall")
	# A rock over the feet: every step out is free, a step into another rock is not.
	var r: Node2D = load("res://scripts/player/player.gd").new()
	r.farm = farm
	var mid := at + Vector2i(2, 4)
	r.position = Vector2(mid.x * 16 + 8, mid.y * 16 + 8)
	farm.cell(mid).obj = FarmGrid.Obj.ROCK
	check(r._try_move(Vector2(0, 2)) and r._try_move(Vector2(2, 0)), "walking: a solid cell under the feet lets them walk off it")
	farm.cell(mid + Vector2i.LEFT).obj = FarmGrid.Obj.ROCK
	r.position = Vector2(mid.x * 16 + 8, mid.y * 16 + 8)
	check(not r._try_move(Vector2(-4, 0)), "walking: but not into the next one")
	# Running into a map's edge exit (playtest 2026-11-07: only walking went through): the feet
	# stop up to a running step short of the edge, and the exit is still found.
	g.maps.place("town", Vector2i(0, 10), Vector2i.LEFT)
	var e: Node2D = load("res://scripts/player/player.gd").new()
	e.farm = saved_farm
	var entered := []
	e.action.connect(func(kind, origin, face, _c): entered.append([kind, origin, face]))
	for gap_px in [0.2, 1.0, 1.6]:
		entered.clear()
		e.position = Vector2(5.0 + gap_px, 10 * 16 + 10)
		Input.action_press("move_left")
		Input.action_press("run")
		e._physics_process(1.0 / 60.0)
		Input.action_release("move_left")
		Input.action_release("run")
		check(not entered.is_empty() and entered[0][0] == "enter" and entered[0][2] == Vector2i.LEFT,
			"walking: running into the village's west exit %.1f px short of the edge goes through (%s, running %s)" % [gap_px, entered, e.running])
	for n in [p, q, r, e]:
		n.free()
	g.farm = saved_farm
	g.maps.id = saved_id
	g.maps.pos = saved_pos


## The map fade: never jumps on a slow frame, swaps at black, stays black HOLD_FRAMES frames.
func _fade_steps() -> void:
	var g: Node = root.get_node("Game")
	var fade_script: GDScript = load("res://scripts/ui/map_fade.gd")
	var f: Node = fade_script.new()
	var MAX_STEP: float = fade_script.MAX_STEP
	var OUT_S: float = fade_script.OUT_SECONDS
	var IN_S: float = fade_script.IN_SECONDS
	var HOLD: int = fade_script.HOLD_FRAMES
	root.add_child(f)
	var swaps := [0]
	f.run(func(): swaps[0] += 1)
	check(f.busy() and g.paused(), "fade: running holds the clock")
	f._process(1.0)   # a one-second hitch
	check(f.alpha() <= MAX_STEP / OUT_S + 0.001, "fade: a slow frame moves it one small step (%.2f)" % f.alpha())
	var frames := 0
	while swaps[0] == 0 and frames < 100:
		f._process(1.0)
		frames += 1
	check(swaps[0] == 1 and is_equal_approx(f.alpha(), 1.0), "fade: the swap comes at black")
	for i in HOLD:
		f._process(1.0)
	check(is_equal_approx(f.alpha(), 1.0), "fade: black for %d frames after the swap" % HOLD)
	f._process(1.0)
	check(f.alpha() < 1.0 and f.alpha() >= 1.0 - MAX_STEP / IN_S - 0.001, "fade: back in by small steps (%.2f)" % f.alpha())
	check(f.busy() and not g.paused(), "fade: the farmer may walk as the picture comes back")
	f.run(func(): swaps[0] += 10)   # a second change on the way back: dark again, swapped again
	frames = 0
	while f.busy() and frames < 200:
		f._process(1.0 / 60.0)
		frames += 1
	check(swaps[0] == 11 and not f.busy() and f.alpha() == 0.0 and not g.paused(), "fade: a change on the way back swaps again, then the fade ends (%d)" % swaps[0])
	f.free()


## Worlds built today are kept for going back (a build is a long frame): back on the farm the
## same world returns, its field changes caught up; a new day or a changed map builds anew.
func _kept_worlds(g: Node) -> void:
	var farm_kept: Dictionary = _scene._worlds.get("farm", {})
	check(not farm_kept.is_empty() and not farm_kept.world.is_inside_tree() and farm_kept.world.away, "kept worlds: the farm's world waits out of the tree while in the house")
	if farm_kept.is_empty():
		return
	var house_world: Node = _scene.world
	var c := Vector2i(-1, -1)
	for i in g.farm.cells.size():
		var cc := Vector2i(i % FarmGrid.W, i / FarmGrid.W)
		if g.farm.can_farm(cc) and g.farm.cell(cc).obj == FarmGrid.Obj.NONE and not g.farm.cell(cc).tilled:
			c = cc
			break
	g.farm.till(c)
	check(farm_kept.world._stale, "kept worlds: a field change while away only marks the farm stale")
	g.maps.place("farm", Vector2i(10, 10), Vector2i.DOWN)
	_scene._enter_map()
	check(_scene.world == farm_kept.world and _scene.world.is_inside_tree() and not _scene.world.away and not _scene.world._stale,
		"kept worlds: back on the farm the same world returns and catches up")
	check(_scene.world.find_children("*", "", false, false).filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("villager_sprites.gd")).size() == 1,
		"kept worlds: one fresh set of villagers and animals on it")
	check(_scene._worlds.has("house") and _scene._worlds.house.world == house_world, "kept worlds: and the house waits in turn")
	g.maps.place("house", Vector2i(3, 3), Vector2i.UP)
	_scene._enter_map()
	check(_scene.world == house_world, "kept worlds: the house again, not rebuilt")
	_scene._on_day_started()
	check(_scene._worlds.is_empty(), "kept worlds: a new day drops them")
	g.day += 1
	g.maps.place("farm", Vector2i(10, 10), Vector2i.DOWN)
	_scene._enter_map()
	check(_scene.world != farm_kept.world, "kept worlds: the next day the farm is built anew")


## Mio's ferry boat and landing on the river (heart_mio_6 names the boat): both stand on the
## water below her hut and keep the shore open, the name shows by her answer (mio_boat), its two
## pictures are drawn and differ, and the 3D river builds the hull.
func _ferry_boat() -> void:
	var river: MapData = MapManager.load_map("river", null, {})[1]
	var boat := river.prop_at(Vector2i(14, 7))
	var stage := river.prop_at(Vector2i(13, 6))
	check(boat.get("kind", "") == "ferry_boat" and boat.size == Vector2i(3, 1) and stage.get("kind", "") == "landing", "the boat (3 x 1) and its landing below Mio's hut")
	for c in [Vector2i(13, 6), Vector2i(13, 7), Vector2i(14, 7), Vector2i(15, 7)]:
		check(river.tile(c) == "water", "%s is on the water" % c)
	for c in [Vector2i(13, 5), Vector2i(14, 5), Vector2i(12, 5)]:
		check(not river.is_solid(c), "the shore at %s stays open" % c)
	check(river.spawns.has("ferry"), "a ferry spawn to look at it from")
	var names := func(f: Dictionary) -> Array:
		var out := []
		for p in MapManager.load_map("river", null, f)[1].props:
			if p.kind == "boat_name":
				out.append(StoryView.art_key(p))
		return out
	check(names.call({}).is_empty(), "no name before Mio has named the boat")
	check(names.call({"mio_boat": "father"}) == ["story:boat_father"] and names.call({"mio_boat": "new"}) == ["story:boat_new"],
		"her father's name or the new one, by her answer")
	var a := PlaceholderArt.tex("story:boat_father").get_image()
	var b := PlaceholderArt.tex("story:boat_new").get_image()
	check(a.get_size() == Vector2i(14, 6) and a.get_data() != b.get_data(), "the two names are drawn and differ")
	var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
	w.build(river)
	var ride: Node3D = w.get_node_or_null("FerryBoat")
	var hull := 0 if ride == null else ride.get_children().filter(func(c): return c is MeshInstance3D and c.material_override is StandardMaterial3D and c.material_override.albedo_color == Color("8a6440")).size()
	w.free()
	check(hull > 0, "the 3D river has the boat's hull, in the piece that moves (%d)" % hull)
	var named: Node3D = load("res://scripts/world3d/map_world.gd").new()
	named.build(MapManager.load_map("river", null, {"mio_boat": "new"})[1])
	var on_boat: Node3D = named.get_node_or_null("FerryBoat")
	check(on_boat != null and on_boat.get_children().any(func(c): return c is MeshInstance3D and c.mesh is QuadMesh),
		"its painted name goes with it")
	named.free()
	var fv := FerryView.new(river)
	check(fv.has_boat(), "the flat view draws the boat")
	fv.free()


## Shino's drying rack by her vats (DyeCloth): in Minamino beside the vats, its cells solid and
## her work spots open; out 7:00-17:00 on dry days only; three shades, the palest first; the
## pictures drawn; the 3D rack builds its frame and three swaying lengths shown by the clock;
## the flat view's strips shift downwind, the hem the most, none in still air.
func _dye_cloth() -> void:
	var m: MapData = MapManager.load_map("minamino", null, {})[1]
	var rack := m.prop_at(Vector2i(0, 15))
	check(rack.get("kind", "") == DyeCloth.KIND and rack.size == Vector2i(2, 3), "the drying rack (2 x 3) west of Shino's vats")
	check(m.prop_at(Vector2i(2, 15)).get("kind", "") == "water_tub", "the first pole is beside the vats")
	for c in [Vector2i(0, 15), Vector2i(1, 16), Vector2i(1, 17)]:
		check(m.is_solid(c), "the rack stands on %s" % c)
	for c in [Vector2i(1, 14), Vector2i(2, 16), Vector2i(3, 16), Vector2i(4, 16)]:
		check(not m.is_solid(c), "Shino's way at %s stays open" % c)
	check(DyeCloth.out(rack, 10 * 60, "sunny") and DyeCloth.out(rack, 7 * 60, "sunny") and DyeCloth.out(rack, 16 * 60 + 59, "sunny"),
		"out in her hours on a dry day")
	check(not DyeCloth.out(rack, 6 * 60 + 59, "sunny") and not DyeCloth.out(rack, 17 * 60, "sunny") and not DyeCloth.out(rack, 22 * 60, "sunny"),
		"taken in before seven and from five")
	for look in ["rain", "storm", "snow", "blizzard"]:
		check(not DyeCloth.out(rack, 10 * 60, look), "taken in on a %s day" % look)
	check(DyeCloth.out(rack, 10 * 60, "sunny", "mon", "spring", 1) and not DyeCloth.out(rack, 10 * 60, "sunny", "sun", "spring", 7),
		"in on Sundays, when her vats rest")
	check(not DyeCloth.out(rack, 10 * 60, "sunny", "tue", "winter", 4) and DyeCloth.out(rack, 10 * 60, "sunny", "wed", "winter", 5),
		"in on her birthday (winter 4), out the day after")
	var shades := DyeCloth.shades(rack)
	check(shades.size() == 3 and shades[0].get_luminance() > shades[1].get_luminance() and shades[1].get_luminance() > shades[2].get_luminance(),
		"three lengths, the palest on the first pole and the darkest on the last")
	var a := PlaceholderArt.tex(DyeCloth.art_key(shades[0])).get_image()
	var b := PlaceholderArt.tex(DyeCloth.art_key(shades[2])).get_image()
	check(a.get_size() == Vector2i(DyeCloth.ART_W, DyeCloth.ART_H) and a.get_data() != b.get_data() and a.get_pixel(5, 10).a > 0.9,
		"the lengths are drawn, each in its own blue")
	var g: Node = root.get_node("Game")
	var keep := [g.hour, g.minute, g.weather_today]
	g.hour = 10
	g.minute = 0
	g.weather_today = "sunny"
	var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
	w.build(m)
	root.add_child(w)
	var show: Node3D = w.get_node_or_null("DyeCloth")
	var sway: Node = w.get_node_or_null("WindSway")   # OutdoorProps.SWAY
	check(show != null and show.get_child_count() == 3 and show.visible, "the 3D rack hangs its three lengths at 10:00 on a sunny day")
	var poles := w.get_children().filter(func(c): return c is MeshInstance3D and c.material_override is StandardMaterial3D and c.material_override.albedo_color == Color("cdbd80")).size()
	check(poles > 0, "and its bamboo poles (%d)" % poles)
	if show != null and sway != null:
		var cloth: MeshInstance3D = show.get_child(2)
		var i := -1
		for k in sway.count():
			if cloth in sway.nodes_of(k):
				i = k
		check(i >= 0 and sway.kind_of(i) == "cloth", "each length sways as a cloth")
		if i >= 0:
			sway.wind = 0.0
			sway.pose(3.0)
			var rest: Vector3 = sway.moved(i, Vector3(0, -DyeCloth.DROP, 0))
			sway.wind = 0.5
			sway.pose(3.0)
			var blown: Vector3 = sway.moved(i, Vector3(0, -DyeCloth.DROP, 0))
			check(rest.is_equal_approx(Vector3(0, -DyeCloth.DROP, 0)) and blown.x > 0.1, "still in calm air, the hem blown downwind in a wind (%s)" % blown)
		g.hour = 18
		show.refresh()
		check(not show.visible, "taken in at 18:00, the frame left standing")
		g.hour = 10
		g.weather_today = "rain"
		show.refresh()
		check(not show.visible, "and on a rainy morning")
	w.queue_free()
	var calm := DyeClothView.band_shifts(0.0, 4.0, 0.0)
	var gale := DyeClothView.band_shifts(1.0, 4.0, 0.0)
	check(calm.all(func(x): return x == 0), "the flat view's lengths hang straight in still air")
	var rising := true
	for k in range(1, gale.size()):
		rising = rising and gale[k] >= gale[k - 1]
	check(DyeCloth.STREAM == load("res://scripts/world3d/outdoor_props.gd").Sway.CLOTH_STREAM, "the flat view's shear is the 3D cloth's")
	check(gale[0] == 0 and gale.back() > 0 and rising, "in a gale the strips shift downwind, the hem the most %s" % [gale])
	g.weather_today = "sunny"
	var v := DyeClothView.new(m)
	root.add_child(v)
	check(v.has_racks() and v.cloth_out(), "the flat view hangs the cloth at 10:00 on a sunny day")
	g.hour = 20
	v.refresh()
	check(not v.cloth_out(), "and takes it in at night")
	v.queue_free()
	g.hour = keep[0]
	g.minute = keep[1]
	g.weather_today = keep[2]


## The noren Shino dyed (heart_shino_6, shino_noren rows / flowers): over the farmhouse door
## by the farmer's answer, and her own new one with the dye house's mark over her door; none
## before; the three pictures drawn and different; the doors still work; the 3D noren sways.
func _shino_noren() -> void:
	var keys := func(map_id: String, f: Dictionary) -> Array:
		var out := []
		for p in MapManager.load_map(map_id, null, f)[1].props:
			if p.kind == "noren":
				out.append(StoryView.art_key(p))
		return out
	check(keys.call("farm", {}).is_empty() and keys.call("minamino", {}).is_empty(), "no noren before Shino has dyed one")
	check(keys.call("farm", {"shino_noren": "rows"}) == ["story:noren_rows"] and keys.call("farm", {"shino_noren": "flowers"}) == ["story:noren_flowers"],
		"the farmhouse noren by the farmer's answer: the field's rows or her wildflowers")
	check(keys.call("minamino", {"shino_noren": "rows"}) == ["story:noren_shino"] and keys.call("minamino", {"shino_noren": "flowers"}) == ["story:noren_shino"],
		"and her own new one over the dye house door either way")
	var imgs := []
	for k in ["story:noren_rows", "story:noren_flowers", "story:noren_shino"]:
		imgs.append(PlaceholderArt.tex(k).get_image())
	check(imgs[0].get_size() == Vector2i(22, 10) and imgs[0].get_data() != imgs[1].get_data() and imgs[1].get_data() != imgs[2].get_data() and imgs[0].get_data() != imgs[2].get_data(),
		"the three noren are drawn and differ")
	var m: MapData = MapManager.load_map("minamino", null, {"shino_noren": "rows"})[1]
	check(m.door_at(Vector2i(1, 13)).get("to", "") == "shino_house", "the dye house door still opens under it")
	var farm: MapData = MapManager.load_map("farm", null, {"shino_noren": "rows"})[1]
	check(not farm.door_at(Vector2i(4, 3)).is_empty() or farm.is_solid(Vector2i(4, 3)) == MapManager.load_map("farm", null, {})[1].is_solid(Vector2i(4, 3)),
		"the farmhouse door is as it was")
	var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
	w.build(m)
	var cloth: MeshInstance3D = null
	for c in w.get_children():
		if c is MeshInstance3D and c.material_override is StandardMaterial3D and c.material_override.albedo_texture == PlaceholderArt.tex("story:noren_shino"):
			cloth = c
	var sway: Node = w.get_node_or_null("WindSway")
	var swaying := false
	if sway != null and cloth != null:
		for i in sway.count():
			swaying = swaying or cloth in sway.nodes_of(i)
	check(cloth != null and swaying, "the 3D dye house hangs it, swaying in the wind")
	w.free()


## The persimmon twig Kiku gave (heart_kiku_6, kiku_scion door / field): planted by the farmhouse
## door or at the field's edge by the farmer's answer, none before; solid, off the door path, the
## plots' rows, the bin and the gate road; the four seasons' pictures drawn and different.
func _kiku_scion() -> void:
	var cells := func(f: Dictionary) -> Array:
		var out := []
		for p in MapManager.load_map("farm", null, f)[1].props:
			if p.kind == "scion":
				out.append(p.cell)
		return out
	check(cells.call({}).is_empty() and cells.call({"kiku_graft": true}).is_empty(), "no sapling before the farmer has chosen where it goes")
	check(cells.call({"kiku_scion": "door"}) == [Vector2i(3, 4)] and cells.call({"kiku_scion": "field"}) == [Vector2i(30, 8)],
		"the sapling by the farmhouse door or at the field's edge by the answer")
	var base: MapData = MapManager.load_map("farm", null, {})[1]
	for answer in ["door", "field"]:
		var m: MapData = MapManager.load_map("farm", null, {"kiku_scion": answer})[1]
		var c: Vector2i = cells.call({"kiku_scion": answer})[0]
		check(m.is_solid(c) and not base.is_solid(c), "the %s sapling blocks its own cell" % answer)
		var fixed := FarmGrid.new({})
		fixed.generate(RandomNumberGenerator.new())
		check(fixed.fixed_at(c) == "" and c.y != 5 and c != Vector2i(4, 4) and c != Vector2i(4, 3) and c != Vector2i(8, 6)
			and m.door_at(c).is_empty() and not m.doors.any(func(d): return c in d.cells), "and sits clear of the fixtures, doors and the road of row 5 (%s)" % answer)
	var seasons := ["spring", "summer", "fall", "winter"]
	for stage in Scion.stage_ids():
		var imgs := []
		for k in seasons:
			var img := PlaceholderArt.tex(Scion.art_key(stage, k, false)).get_image()
			check(img.get_size() == Scion.size(stage), "the %s %s is drawn at its size" % [k, stage])
			imgs.append(img.get_data())
		for i in 4:
			for j in range(i + 1, 4):
				check(imgs[i] != imgs[j], "the %s's seasons differ (%d, %d)" % [stage, i, j])
		check(PlaceholderArt.tex(Scion.art_key(stage, "winter", true)).get_image().get_data() != imgs[3], "snow lies on the winter %s" % stage)
	check(Scion.stage_ids() == ["sapling", "young", "tree"], "three stages: sapling, young, tree")
	var sizes := Scion.stage_ids().map(func(s): return Scion.size(s))
	check(sizes[0].y < sizes[1].y and sizes[1].y < sizes[2].y, "it grows taller each stage")
	check(sizes.all(func(z): return z.x <= 26), "never wider than the cell and a third either side (clear of the door's column)")
	# Persimmons: only the grown tree in fall; the fall picture has more orange than the young one's.
	check(Scion.fruits("tree", "fall") and not Scion.fruits("tree", "summer") and not Scion.fruits("young", "fall") and not Scion.fruits("sapling", "fall"),
		"persimmons hang on the grown tree in fall")
	var orange := func(key: String) -> int:
		var img := PlaceholderArt.tex(key).get_image()
		var n := 0
		for y in img.get_height():
			for x in img.get_width():
				n += int(img.get_pixel(x, y).is_equal_approx(PlaceholderArt.PERSIMMON))
		return n
	check(orange.call(Scion.art_key("tree", "fall", false)) >= 8 * 4 and orange.call(Scion.art_key("young", "fall", false)) == 0,
		"the tree's fall crown hangs persimmons, the young tree's none")
	check(orange.call(Scion.art_key("tree", "fall", false, 1)) < orange.call(Scion.art_key("tree", "fall", false)) and orange.call(Scion.art_key("tree", "fall", false, 2)) == 0
		and Scion.art_key("tree", "summer", false, 1) == Scion.art_key("tree", "summer", false), "picking takes persimmons off the drawn tree (fall only)")
	# Growth by the days since planting (kiku_scion_day), a year being 120 days.
	var days: int = 4 * root.get_node("Game").DAYS_PER_SEASON
	var f := {"kiku_scion": "door", "kiku_scion_day": 10}
	check(Scion.stage(f, 10) == "sapling" and Scion.stage(f, 10 + days - 1) == "sapling", "a sapling through its first year")
	check(Scion.stage(f, 10 + days) == "young" and Scion.stage(f, 10 + 2 * days - 1) == "young", "a young tree in its second")
	check(Scion.stage(f, 10 + 2 * days) == "tree" and Scion.stage(f, 10 + 9 * days) == "tree", "a small fruiting tree from its third on")
	check(Scion.stage(f, 3) == "sapling", "a day before planting reads as planted today")
	# An old save: the place chosen, no day kept. It is given the day it is first seen.
	var old := {"kiku_scion": "field"}
	check(Scion.stage(old, 400) == "sapling", "no planting day: a sapling")
	check(Scion.record(old, 400) and old.kiku_scion_day == 400 and not Scion.record(old, 500) and old.kiku_scion_day == 400,
		"an old save's twig is planted the day it is loaded on, once")
	check(not Scion.record({}, 5) and not Scion.record({"kiku_graft": true}, 5), "nothing kept before the farmer chose a place")
	# The event keeps the day: heart_kiku_6 has the date step, and it sets today's day number.
	var ev: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EventRunner.DIR + "heart_kiku_6.json"))
	check(ev.steps.any(func(s): return s.get("do") == "date" and s.get("flag") == Scion.day_flag()), "Kiku's band 6 scene keeps the planting day")
	var g: Node = root.get_node("Game")
	var keep: Dictionary = g.flags.duplicate()
	g.flags.erase("kiku_scion_day")
	var r := EventRunner.new({"steps": [{"do": "date", "flag": "kiku_scion_day"}]}, g)
	check(r.error == "", "a date step is a step (%s)" % r.error)
	r.update(0.1)
	check(g.flags.get("kiku_scion_day") == g.day_number(), "the date step keeps today's day number (%s)" % str(g.flags.get("kiku_scion_day")))
	g.flags = keep
	var key := StoryView.art_key({"kind": "scion"})
	var game_season: String = g.season_name()
	check(key == Scion.art_key(Scion.stage(g.flags, g.day_number()), game_season, Scion.snowy(game_season, g.snow_cover)), "the picture follows the age and the season")
	var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	var farm_w: Node3D = w
	var props_script = load("res://scripts/world3d/story_props.gd")
	var sprites := 0
	var m: MapData = MapManager.load_map("farm", null, {"kiku_scion": "door"})[1]
	for p in m.props:
		if p.kind == "scion":
			props_script.prop(farm_w, p)
	for c in farm_w.get_children():
		sprites += int(c is Sprite3D and c.texture == PlaceholderArt.tex(key))
	check(sprites == 1, "the 3D view stands one sapling sprite")
	w.free()

## What Nana's heart scenes leave in Minamino (data/maps/minamino.json): Captain's jar by
## Shige's door once she kept him till he has legs (nana_captain "jar"), gone at her band 6
## scene; Captain the frog in the ditch behind the beds (heart_nana_6) and her sky map on the
## hen barn's front (nana_sky), its stars by her answers; the barn and the ditch always there,
## solid; the pictures in both views.
func _nana_props() -> void:
	var kinds := func(f: Dictionary) -> Array:
		var out := []
		for p in MapManager.load_map("minamino", null, f)[1].props:
			if p.kind in ["captain_jar", "frog", "sky_map"]:
				out.append(p.kind)
		return out
	check(kinds.call({}).is_empty() and kinds.call({"heart_nana": true, "nana_captain": "pond"}).is_empty(), "no jar, frog or sky map before Nana's scenes (or with Captain let go)")
	check(kinds.call({"heart_nana": true, "nana_captain": "jar"}) == ["captain_jar"], "Captain's jar by Shige's door once Nana keeps him till he has legs")
	check(kinds.call({"nana_captain": "jar", "heart_nana_6": true, "nana_sky": true}) == ["frog", "sky_map"]
		and kinds.call({"nana_captain": "pond", "heart_nana_6": true, "nana_sky": true}) == ["frog", "sky_map"],
		"at band 6 the jar is gone, Captain sings in the ditch and the sky map hangs on the barn")
	var dlg := FileAccess.get_file_as_string("res://data/dialogue/heart_events.json")
	check('"set": {"nana_captain": "pond"}' in dlg and '"set": {"nana_captain": "jar"}' in dlg, "Nana's band 3 answers set nana_captain")
	check(StoryView.sky_map_key({}) == "story:sky_map:steady:near" and StoryView.sky_map_key({"nana_beside": true, "nana_star": "field"}) == "story:sky_map:beside:field"
		and StoryView.sky_map_key({"nana_steady": true, "nana_star": "near"}) == "story:sky_map:steady:near", "the sky map's stars by her answers")
	var datas := []
	var sized := true
	for k in ["story:sky_map:steady:near", "story:sky_map:steady:field", "story:sky_map:beside:near", "story:sky_map:beside:field"]:
		var img: Image = PlaceholderArt.tex(k).get_image()
		sized = sized and img.get_size() == Vector2i(30, 20)
		datas.append(img.get_data())
	var differ := true
	for i in datas.size():
		for j in range(i + 1, datas.size()):
			differ = differ and datas[i] != datas[j]
	check(sized and differ, "the four sky maps are drawn, 30 x 20, and differ")
	check(PlaceholderArt.tex("story:captain_jar").get_size() == Vector2(10, 13) and PlaceholderArt.tex("story:frog").get_size() == Vector2(12, 10), "the jar and the frog are drawn")
	var jar_f := {"nana_captain": "jar", "heart_nana": true}
	var m: MapData = MapManager.load_map("minamino", null, jar_f)[1]
	check(m.is_solid(Vector2i(19, 4)) and m.is_solid(Vector2i(20, 5)) and m.is_solid(Vector2i(16, 2)) and m.is_solid(Vector2i(10, 7)) and not m.is_solid(Vector2i(10, 8)),
		"the hen barn, the ditch and the jar block their cells")
	check(m.door_at(Vector2i(11, 6)).get("to", "") == "shige_house", "Shige's door still opens beside the jar")
	# 3D: the barn and the ditch are lit meshes (the box check in _lane_and_kiln_props), the pictures by flag.
	var pics := func(f: Dictionary) -> Array:
		var was: Dictionary = MapManager.flags
		MapManager.set_flags(f)   # the sky map's stars come from the shared flags, as in the game
		var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
		w.build(MapManager.load_map("minamino", null, f)[1])
		MapManager.set_flags(was)
		var out := []
		for c in w.get_children():
			var tex: Variant = null
			if c is Sprite3D:
				tex = c.texture
			elif c is MeshInstance3D and c.material_override is StandardMaterial3D:
				tex = c.material_override.albedo_texture
			for k in ["story:captain_jar", "story:frog", StoryView.sky_map_key(f)]:
				if tex != null and tex == PlaceholderArt.tex(k):
					out.append([k, c.position])
		w.free()
		return out
	var jar: Array = pics.call(jar_f)
	check(jar.size() == 1 and jar[0][0] == "story:captain_jar" and Rect2(10, 7, 1, 1).has_point(Vector2(jar[0][1].x, jar[0][1].z)), "the 3D jar stands on its cell (%s)" % [jar])
	var six := {"nana_captain": "jar", "heart_nana_6": true, "nana_sky": true, "nana_beside": true, "nana_star": "field"}
	var later: Array = pics.call(six)
	var frog: Array = later.filter(func(e): return e[0] == "story:frog")
	var sky: Array = later.filter(func(e): return e[0] == "story:sky_map:beside:field")
	check(later.size() == 2 and frog.size() == 1 and Rect2(15, 2, 3, 1).has_point(Vector2(frog[0][1].x, frog[0][1].z))
		and sky.size() == 1 and absf(sky[0][1].z - load("res://scripts/world3d/outdoor_props.gd").hen_barn_front(Rect2(19, 5, 2, 1)) - 0.04) < 0.001 and sky[0][1].x > 19.0 and sky[0][1].x < 21.0,
		"the 3D frog in the ditch and the sky map on the barn's front (%s)" % [later])
	# The flat view draws them from the same keys (StoryView) and leaves them out of its boxes.
	check(StoryView.KINDS.has("captain_jar") and StoryView.KINDS.has("frog") and StoryView.KINDS.has("sky_map") and MapView.COLORS.has("hen_barn") and MapView.COLORS.has("ditch"),
		"the flat view knows the jar, the frog, the sky map, the barn and the ditch")
	_nana_scarf()


## Nana's birthday scarf on the jizo by the Minamino lane (nana_scarf): the silent event that
## sets it once the farmer is in Minamino on fall 19 from 9:40, the prop gated by it in both
## views, the jizo still blocking and readable.
func _nana_scarf() -> void:
	var ev: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/events/nana_scarf.json"))
	check(ev is Dictionary and ev.steps.size() == 1 and ev.steps[0].get("do", "") == "set" and ev.steps[0].flags == {"nana_scarf": true},
		"the nana_scarf event only sets the flag")
	var tbl := EventTriggers.open("minamino", true)
	check(tbl.error == "", "Minamino's trigger table loads (%s)" % tbl.error)
	var s := {"year": 1, "season": "fall", "day": 19, "weekday": "mon", "time": 10 * 60, "weather": "sunny", "flags": {}, "seen": {}, "cell": Vector2i(5, 17)}
	check(tbl.pick("enter", s) == "nana_scarf" and tbl.pick("minute", s) == "nana_scarf", "on her birthday the scarf is set on entering and each minute")
	check(tbl.pick("enter", s.merged({"time": 9 * 60 + 39}, true)) == "" and tbl.pick("enter", s.merged({"time": 23 * 60 + 59}, true)) == "nana_scarf",
		"not before 9:40, still on late in the day")
	check(tbl.pick("enter", s.merged({"day": 18}, true)) == "" and tbl.pick("enter", s.merged({"season": "winter"}, true)) == "" and tbl.pick("enter", s.merged({"seen": {"nana_scarf": true}}, true)) == "",
		"not on other days or seasons, and only once")
	var scarves := func(f: Dictionary) -> Array:
		return MapManager.load_map("minamino", null, f)[1].props.filter(func(p): return p.kind == "jizo_scarf")
	check(scarves.call({}).is_empty() and scarves.call({"nana_scarf": true}).size() == 1, "the scarf shows only with nana_scarf")
	var m: MapData = MapManager.load_map("minamino", null, {"nana_scarf": true})[1]
	var scarf := m.prop_at(Vector2i(5, 18))
	check(scarf.get("kind", "") == "jizo_scarf" and scarf.get("use", "") == "examine" and str(scarf.get("message", "")) != "" and m.is_solid(Vector2i(5, 18))
		and m.props.any(func(p): return p.kind == "jizo" and p.cell == Vector2i(5, 18)), "the scarf is on the jizo at (5, 18), which still blocks")
	check(MapManager.load_map("minamino", null, {})[1].prop_at(Vector2i(5, 18)).get("kind", "") == "jizo", "without the flag the jizo is the prop there")
	check(MapManager.load_map("kaminoda", null, {"nana_scarf": true})[1].props.all(func(p): return p.kind != "jizo_scarf"), "the Kaminoda jizo get no scarf")
	check(StoryView.KINDS.has("jizo_scarf") and StoryView.art_key(scarf) == "story:jizo_scarf", "the flat view draws it from story:jizo_scarf")
	var img: Image = PlaceholderArt.tex("story:jizo_scarf").get_image()
	check(img.get_width() >= 8 and img.get_pixel(img.get_width() / 2, 1) != Color.MAGENTA, "the scarf is drawn")
	var count := func(mp: MapData) -> int:
		var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
		w.build(mp)
		var n := w.get_children().filter(func(c): return c is MeshInstance3D and c.material_override is StandardMaterial3D and c.material_override.albedo_color == load("res://scripts/world3d/outdoor_props.gd").SCARF_RED).size()
		w.free()
		return n
	check(count.call(MapManager.load_map("minamino", null, {})[1]) == 0 and count.call(m) == 1, "in 3D the red scarf is there only with the flag (one mesh)")


## The baby's cradle (Child, data/maps/house.json): in the second room only while child_stage is
## "baby"; the 3D house builds round it with no stand-in box (CradleLayer shows it), and the
## layer stands its picture on the cradle's cell, empty while the baby is held.
func _cradle() -> void:
	var g: Node = root.get_node("Game")
	var has := func(f: Dictionary) -> bool:
		return MapManager.load_map("house", ["room"], f)[1].props.any(func(p): return p.kind == Child.CRADLE)
	check(has.call({Child.STAGE: "baby"}) and not has.call({}) and not has.call({Child.STAGE: "crawler"}), "the house's cradle only while the child is a baby")
	var m: MapData = MapManager.load_map("house", ["room"], {Child.STAGE: "baby"})[1]
	var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
	w.build(m)
	var magenta := 0
	for c in w.find_children("*", "MeshInstance3D", true, false):
		var mat: Variant = (c as MeshInstance3D).material_override
		magenta += int(mat is StandardMaterial3D and mat.albedo_color == Color.MAGENTA)
	check(magenta == 0, "the 3D house has no stand-in box for the cradle")
	w.free()
	g.new_game()
	g._finish_build({"build": "room", "shop": g._builder_shop("room"), "ready": 0})
	g.flags.merge({"spouse": "fumi", "married_fumi": true})
	Child.tell_news(g.flags, g.day_number())
	Child.give_birth(g.flags, g.day_number(), "Nagisa")
	Child.sync_stage(g.flags, g.day_number())
	g.maps.place("house", Vector2i(10, 2), Vector2i.UP)
	var layer: Node3D = load("res://scripts/world3d/cradle_layer.gd").new("house")
	root.add_child(layer)
	check(layer.sprite != null and layer.sprite.visible and layer.sprite.position == Vector3(10.5, 0, 1.5)
		and is_equal_approx(layer.sprite.pixel_size, load("res://scripts/world3d/farm_world.gd").FIGURE_PX), "the 3D cradle stands on its cell at the figures' size")
	var full: String = layer.sprite.get_meta("key")
	g.lift_baby()
	layer.refresh()
	check(full.begins_with("child:cradle:") and not full.contains(":empty:") and layer.sprite.get_meta("key").contains(":empty:"), "and shows it empty while the baby is held")
	layer.free()
	g.new_game()
