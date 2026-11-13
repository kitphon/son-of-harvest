extends SceneTree
## Headless checks for the cicadas of summer (CicadaRules, data/cicadas.json, CicadaArt): the day
## chorus and the evening cicada by the day of summer, the clock and the weather; none at night,
## in rain, storm or snow, indoors, in the mine or in spring and winter, a few early fall days;
## their loops and how loud they play by map and wind (the Sfx autoload adding them to the ambient
## loops); the trunks they cling to, on the camera's side, the singing pulse, flying off from the
## farmer and the other walkers and coming back; the pictures; and both views (CicadaLayer in 3D,
## CicadaView in the flat view). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_cicadas.gd

var failures := 0
var g: Node
var CR: GDScript
var MM: GDScript
const FAR := Vector2(-9999.0, -9999.0)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	CR = load("res://scripts/cicada_rules.gd")
	MM = load("res://scripts/world/map_manager.gd")
	g.new_game()
	g.clock_running = true
	_data()
	_gating()
	_sound()
	_trunks()
	_startle()
	_art()
	await _sfx()
	await _views()
	await _flat()
	print("test_cicadas: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _when(season: int, day: int, hour: int, minute: int, weather: String) -> void:
	g.season = season
	g.day = day
	g.hour = hour
	g.minute = minute
	g.weather_today = weather


func _data() -> void:
	var cfg: Dictionary = CR.config()
	check(cfg.kinds == ["semi", "higurashi"] and CR.KINDS == ["semi", "higurashi"], "data: the two kinds")
	var sfx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json"))
	for key in CR.loops():
		check(sfx.sounds.has(key) and sfx.sounds[key].has("loop") and sfx.sounds[key].get("bus", "") == "Ambient", "data: %s is an ambient loop in data/sfx.json" % key)
	check(sfx.sounds.has("cicada_buzz") and not sfx.sounds.cicada_buzz.has("loop"), "data: the buzz of one flying off is a one-shot")
	check(not sfx.ambient.rules.any(func(r): return str(r.loop) in CR.loops()), "data: the ambient rules leave the cicadas to CicadaRules")
	for kind in cfg.trunks:
		check(kind == "pine" or load("res://scripts/world3d/trees.gd").LEAVES.has(kind), "data: the trunk kind %s is a tree the 3D view draws" % kind)
		check(float(cfg.trunks[kind][0]) < float(cfg.trunks[kind][1]), "data: %s's heights low to high" % kind)
	for kind in CR.KINDS:
		for part in ["eye", "head", "body", "wing", "lit", "vein"]:
			check(Color.html_is_valid(str(cfg.art[kind][part])), "data: %s art %s is a colour" % [kind, part])


func _gating() -> void:
	var a := func(kind: String, season: String, day: int, hour: float, look := "sunny") -> float:
		return CR.amount(kind, season, look, hour, day)
	check(CR.summer_day("summer", 5) == 5 and CR.summer_day("fall", 2) == 32 and CR.summer_day("spring", 9) == 0 and CR.summer_day("winter", 9) == 0, "the days count from the first of summer")
	var noon: float = a.call("semi", "summer", 20, 12.5)
	check(noon > 0.95, "semi: full on a mid-summer noon (%s)" % noon)
	check(a.call("semi", "summer", 20, 8.0) > 0.0 and a.call("semi", "summer", 20, 8.0) < noon, "semi: softer in the morning")
	check(a.call("semi", "summer", 20, 17.0) < noon and a.call("semi", "summer", 20, 17.0) > 0.0, "semi: easing off in the late afternoon")
	check(a.call("semi", "summer", 20, 19.0) == 0.0 and a.call("semi", "summer", 20, 22.0) == 0.0 and a.call("semi", "summer", 20, 5.0) == 0.0, "semi: none at dusk's end, at night or before dawn")
	check(a.call("semi", "summer", 2, 12.5) == 0.0, "semi: not yet on the first days of summer")
	check(a.call("semi", "summer", 6, 12.5) > 0.0 and a.call("semi", "summer", 6, 12.5) < noon, "semi: a few early in summer")
	check(a.call("semi", "summer", 28, 12.5) > 0.9, "semi: still full late in summer")
	var fall2: float = a.call("semi", "fall", 2, 12.5)
	check(fall2 > 0.0 and fall2 < noon, "semi: lingering a few early fall days (%s)" % fall2)
	check(a.call("semi", "fall", 8, 12.5) == 0.0, "semi: gone by the second week of fall")
	for season in ["spring", "winter"]:
		check(a.call("semi", season, 15, 12.5) == 0.0 and a.call("higurashi", season, 15, 18.0) == 0.0, "none in %s" % season)
	for look in ["rain", "storm", "snow", "blizzard"]:
		check(a.call("semi", "summer", 20, 12.5, look) == 0.0 and a.call("higurashi", "summer", 25, 18.0, look) == 0.0, "none in %s" % look)
	var dusk: float = a.call("higurashi", "summer", 25, 18.0)
	check(dusk > 0.9, "higurashi: full at dusk in late summer (%s)" % dusk)
	check(a.call("higurashi", "summer", 25, 12.5) == 0.0, "higurashi: not at midday")
	check(a.call("higurashi", "summer", 25, 21.0) == 0.0, "higurashi: not at night")
	check(a.call("higurashi", "summer", 8, 18.0) == 0.0, "higurashi: not in early summer")
	check(a.call("higurashi", "fall", 4, 18.0) > 0.0, "higurashi: a few evenings into fall")
	# The map: outdoors only.
	_when(1, 20, 12, 30, "sunny")
	var town: MapData = MM.data("town")
	check(CR.outdoors(town) and CR.amounts_now(g, town).has("semi"), "amounts_now: the day chorus in the village")
	for id in ["house", "store", "mine_floor"]:
		check(CR.amounts_now(g, MM.data(id)).is_empty(), "amounts_now: none in %s" % id)
	_when(1, 20, 23, 0, "sunny")
	check(CR.amounts_now(g, town).is_empty(), "amounts_now: none at night")


func _sound() -> void:
	var cfg: Dictionary = CR.config()
	var full := {"semi": 1.0}
	var hill: Dictionary = CR.sound_levels(full, "hill", 0.0)
	var farm: Dictionary = CR.sound_levels(full, "farm", 0.0)
	var town: Dictionary = CR.sound_levels(full, "town", 0.0)
	check(hill.keys() == ["amb_cicadas"], "sound: the day chorus plays amb_cicadas only")
	check(float(hill.amb_cicadas) > float(town.amb_cicadas) and float(town.amb_cicadas) > float(farm.amb_cicadas), "sound: loudest on the wooded hill, softer on the open farm (%s, %s, %s)" % [hill, town, farm])
	check(is_equal_approx(float(town.amb_cicadas), float(cfg.map_level.default)), "sound: a map not named takes the default share")
	var windy: Dictionary = CR.sound_levels(full, "town", 1.0)
	check(float(windy.amb_cicadas) < float(town.amb_cicadas) and float(windy.amb_cicadas) > 0.0, "sound: the wind covers them a little")
	var eve: Dictionary = CR.sound_levels({"higurashi": 1.0}, "town", 0.0)
	check(eve.keys() == ["amb_higurashi"], "sound: the evening cicada plays amb_higurashi")
	check(CR.sound_levels({}, "town", 0.0).is_empty(), "sound: nothing singing, nothing playing")
	# Through the game: the village at noon and at dusk, the store, a stopped clock.
	g.maps.place("town", Vector2i(18, 8), Vector2i.UP)
	_when(1, 25, 12, 30, "sunny")
	var now: Dictionary = CR.sound_now(g, g.maps.current())
	check(now.has("amb_cicadas") and not now.has("amb_higurashi"), "sound_now: the day chorus at noon (%s)" % now)
	_when(1, 25, 18, 0, "sunny")
	now = CR.sound_now(g, g.maps.current())
	check(now.has("amb_higurashi"), "sound_now: the evening cicada at dusk (%s)" % now)
	_when(1, 25, 12, 30, "rain")
	check(CR.sound_now(g, g.maps.current()).is_empty(), "sound_now: none in rain")
	_when(1, 25, 12, 30, "sunny")
	check(CR.sound_now(g, MM.data("store")).is_empty(), "sound_now: none indoors")
	g.clock_running = false
	check(CR.sound_now(g, g.maps.current()).is_empty(), "sound_now: none on the title screen (no clock)")
	g.clock_running = true


func _trunks() -> void:
	var hill: MapData = MM.data("hill")
	var scene: Dictionary = CR.scene_of(hill, 7)
	var trees := hill.props.filter(func(p): return (CR.config().trunks as Dictionary).has(str(p.kind)))
	check(scene.trunks.size() == trees.size() and trees.size() > 5, "trunks: every tree of the hill (%d)" % trees.size())
	check(CR.scene_of(MM.data("farm"), 7).trunks.is_empty(), "trunks: the farm has none")
	var all: Array = CR.spots("semi", 1.0, scene)
	var half: Array = CR.spots("semi", 0.5, scene)
	check(not all.is_empty() and half.size() <= all.size(), "spots: fewer when fewer sing (%d, %d)" % [half.size(), all.size()])
	check(CR.spots("semi", 1.0, scene) == all, "spots: the same all day")
	check(CR.spots("semi", 1.0, CR.scene_of(hill, 8)) != all, "spots: other trees another day")
	check(CR.spots("semi", 0.0, scene).is_empty(), "spots: none at 0")
	var front := Vector2(cos(deg_to_rad(float(CR.config().front))), sin(deg_to_rad(float(CR.config().front))))
	var on_trunk := true
	var facing := true
	for s in all:
		var tr: Dictionary = scene.trunks[s.tree]
		var spot: Vector3 = s.spot
		var span: Array = CR.config().trunks[tr.kind]
		on_trunk = on_trunk and spot.y >= float(span[0]) - 0.001 and spot.y <= float(span[1]) + 0.001
		var lean: Vector3 = tr.lean
		var axis: Vector3 = lean * (spot.y / lean.y)
		var off := Vector2(spot.x, spot.z) - ((tr.foot as Vector2) + Vector2(axis.x, axis.z))
		facing = facing and off.normalized().dot(front) > 0.3 and off.length() < 0.13
	check(on_trunk, "spots: on the trunk below the crown")
	check(facing, "spots: on the camera's side of the trunk, against the bark")
	# A village pine leans: its cicadas follow the trunk (Trees.pine_lean).
	var town_scene: Dictionary = CR.scene_of(MM.data("town"), 3)
	var pines: Array = town_scene.trunks.filter(func(t): return t.kind == "pine")
	check(not pines.is_empty() and pines.all(func(t): return (t.lean as Vector3).y < 1.0 and (t.lean as Vector3).y > 0.95), "trunks: the village pines lean a little")
	# The singing pulse: a clinging one swaps its two frames.
	var frames := {}
	for i in 20:
		for c in CR.cicadas("semi", 1.0, float(i) * 0.05, scene, FAR, {}):
			if c.id == all[0].id:
				frames[c.frame] = true
	check(frames.size() == 2, "cicadas: a singing one pumps (frames %s)" % str(frames.keys()))


func _startle() -> void:
	var scene: Dictionary = CR.scene_of(MM.data("hill"), 7)
	var state := {}
	var first: Array = CR.cicadas("semi", 1.0, 10.0, scene, FAR, state)
	check(not first.is_empty() and first.all(func(c): return c.pose == "cling" and not c.fled), "startle: all clinging with nobody near")
	var target: Dictionary = first[0]
	var spot: Vector3 = target.pos
	var farmer := Vector2(spot.x + 1.0, spot.z)
	var now: Array = CR.cicadas("semi", 1.0, 10.0, scene, farmer, state)
	var it: Array = now.filter(func(c): return c.id == target.id)
	check(it.size() == 1 and it[0].fled and it[0].pose == "cling", "startle: it takes fright as he comes near")
	now = CR.cicadas("semi", 1.0, 10.5, scene, farmer, state)
	it = now.filter(func(c): return c.id == target.id)
	check(it.size() == 1 and it[0].pose == "fly" and not it[0].fled, "startle: then flies")
	if it.size() == 1:
		var p: Vector3 = it[0].pos
		check(p.y > spot.y and p.x > farmer.x - 99.0 and Vector2(p.x, p.z).distance_to(farmer) > Vector2(spot.x, spot.z).distance_to(farmer), "startle: up and away from him")
		check((it[0].dir as Vector2).dot(Vector2(spot.x, spot.z) - farmer) > 0.0, "startle: facing the way it flies")
	now = CR.cicadas("semi", 1.0, 13.0, scene, farmer, state)
	check(not now.any(func(c): return c.id == target.id), "startle: gone from sight after its flight")
	var cfg: Dictionary = CR.config()
	var back := float(cfg.return_after)
	now = CR.cicadas("semi", 1.0, 10.0 + back + 5.0, scene, farmer, state)
	check(not now.any(func(c): return c.id == target.id), "startle: not back while he stands there")
	var t_back := 10.0 + back + 10.0
	now = CR.cicadas("semi", 1.0, t_back, scene, FAR, state)
	check(not now.any(func(c): return c.id == target.id), "startle: once he is gone, the wait starts again")
	var seen_fly := false
	var seen_home := false
	for i in 120:
		now = CR.cicadas("semi", 1.0, t_back + float(i) * 0.25, scene, FAR, state)
		for c in now:
			if c.id == target.id:
				seen_fly = seen_fly or c.pose == "fly"
				if c.pose == "cling":
					seen_home = (c.pos as Vector3).is_equal_approx(spot)
	check(seen_fly and seen_home and not state.has(target.id), "startle: it flies back in to the same spot")
	# The other walkers: a villager nearer than his reach share, the crawler not at all.
	var others_state := {}
	var reach := float(cfg.scare) * float(cfg.startle.others)
	var near_v := Vector2(spot.x + reach * 0.8, spot.z)
	var far_v := Vector2(spot.x + reach * 1.2, spot.z)
	check(CR.cicadas("semi", 1.0, 1.0, scene, FAR, others_state, {}, [far_v]).filter(func(c): return c.fled).is_empty() or not others_state.has(target.id), "startle: a villager beyond the others' reach leaves it")
	others_state.clear()
	CR.cicadas("semi", 1.0, 1.0, scene, FAR, others_state, {}, [near_v])
	check(others_state.has(target.id), "startle: a villager close by sends it off")
	check(CR.scares("kota") and not CR.scares("child", "crawler") and CR.scares("child", "child"), "startle: the crawler does not, the walking child does")


func _art() -> void:
	for kind in CR.KINDS:
		for pose in ["cling", "fly"]:
			check(CicadaArt.frames(pose) == 2, "art: %s has two frames" % pose)
			for f in 2:
				var img: Image = load("res://scripts/art/placeholder_art.gd").image("cicada:%s:%s:%d" % [kind, pose, f])
				check(img.get_size() == CicadaArt.size_of(pose), "art: %s %s %d is %s" % [kind, pose, f, CicadaArt.size_of(pose)])
				var solid := 0
				for y in img.get_height():
					for x in img.get_width():
						solid += 1 if img.get_pixel(x, y).a > 0.0 else 0
				check(solid >= img.get_width() * img.get_height() / 2, "art: %s %s %d is mostly drawn (%d px)" % [kind, pose, f, solid])
		var l: Image = CicadaArt.make(kind, "cling", 0)
		var r: Image = CicadaArt.make(kind, "cling", 0, true)
		check(l.get_pixel(0, 1) == r.get_pixel(3, 1), "art: ':r' is the mirror")
		# The wings are pale against the bark (Trees.BARK) and the body darker than them.
		var art: Dictionary = CR.config().art[kind]
		check(Color(str(art.wing)).get_luminance() > load("res://scripts/world3d/trees.gd").BARK.get_luminance() + 0.4, "art: %s's wings read on the bark" % kind)
		check(Color(str(art.body)).get_luminance() < Color(str(art.wing)).get_luminance(), "art: %s's body darker than its wings" % kind)
	check(CicadaArt.make("semi", "cling", 0).get_pixel(1, 2) != CicadaArt.make("higurashi", "cling", 0).get_pixel(1, 2), "art: the two kinds' bodies differ")


## The Sfx autoload adds the cicadas' loops to the ambient ones.
func _sfx() -> void:
	var sfx: Node = root.get_node("Sfx")
	for key in CR.loops():
		check(sfx._loops.has(key), "Sfx: a player for %s" % key)
	g.maps.place("town", Vector2i(18, 8), Vector2i.UP)
	_when(1, 25, 12, 30, "sunny")
	sfx._process(0.016)
	var t: Dictionary = sfx.ambient_targets()
	check(t.has("amb_cicadas") and not t.has("amb_crickets"), "Sfx: the chorus on a summer noon in the village (%s)" % t)
	_when(1, 25, 18, 0, "sunny")
	sfx._process(0.016)
	t = sfx.ambient_targets()
	check(t.has("amb_higurashi"), "Sfx: the evening cicada at dusk (%s)" % t)
	_when(1, 25, 23, 0, "sunny")
	sfx._process(0.016)
	t = sfx.ambient_targets()
	check(not t.has("amb_cicadas") and not t.has("amb_higurashi") and t.has("amb_crickets"), "Sfx: crickets, not cicadas, at night (%s)" % t)
	_when(1, 25, 12, 30, "storm")
	sfx._process(0.016)
	t = sfx.ambient_targets()
	check(not t.has("amb_cicadas"), "Sfx: no cicadas in a storm (%s)" % t)
	g.maps.place("store", Vector2i(3, 3), Vector2i.UP)
	_when(1, 25, 12, 30, "sunny")
	sfx._process(0.016)
	check(not sfx.ambient_targets().has("amb_cicadas"), "Sfx: no cicadas in the store")
	var loop: PackedFloat32Array = SfxSynth.render(sfx.sounds.amb_higurashi, 1)
	check(loop.size() == int(9.6 * SfxSynth.RATE), "synth: the evening call's loop is its length")
	# A phrase keeps its own length: the call's pulses stop before the next voice starts.
	var quiet := 0.0
	for i in range(int(3.45 * SfxSynth.RATE), int(3.65 * SfxSynth.RATE)):   # between the first voice's end and the second's rise
		quiet = maxf(quiet, absf(loop[i]))
	check(quiet < 0.25, "synth: a phrase ends with its own dur (%s)" % quiet)
	await process_frame


func _views() -> void:
	await process_frame
	var LayerS: GDScript = load("res://scripts/world3d/cicada_layer.gd")
	var MapWorldS: GDScript = load("res://scripts/world3d/map_world.gd")
	var w3: Node3D = MapWorldS.new()
	root.add_child(w3)
	for step in w3.build_steps(MM.data("hill")):
		step.call()
	var layers := w3.get_children().filter(func(n): return n.get_script() == LayerS)
	check(layers.size() == 1, "3D: an outdoor map builds one cicada layer (%d)" % layers.size())
	for map_id in ["house", "mine_floor"]:
		var inside: Node3D = MapWorldS.new()
		root.add_child(inside)
		for step in inside.build_steps(MM.data(map_id)):
			step.call()
		check(inside.get_children().filter(func(n): return n.get_script() == LayerS).is_empty(), "3D: %s builds none" % map_id)
		inside.free()
	if layers.size() == 1:
		var layer: Node3D = layers[0]
		_when(1, 22, 12, 30, "sunny")
		layer.refresh()
		check(layer.shown_count() > 0 and layer.is_in_group("cicada_layers"), "3D: cicadas on the hill's trees at noon (%d)" % layer.shown_count())
		var sprites := layer.get_children().filter(func(n): return n is Sprite3D and n.visible)
		check(sprites.size() == layer.shown_count(), "3D: one visible sprite a cicada")
		check(sprites.all(func(s): return s.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD), "3D: alpha-cut, depth-tested")
		_when(1, 22, 12, 30, "rain")
		layer.refresh()
		check(layer.shown_count() == 0 and layer.get_children().filter(func(n): return n is Sprite3D and n.visible).is_empty(), "3D: none in rain")
		_when(0, 22, 12, 30, "sunny")
		layer.refresh()
		check(layer.shown_count() == 0, "3D: none in spring")
		_when(1, 22, 12, 30, "sunny")
		layer.refresh()
		var c: Dictionary = layer.shown()[0]
		var spot: Vector3 = c.pos
		w3.set_farmer(Vector3(spot.x + 0.5, 0.0, spot.z))
		layer.refresh()   # takes fright
		layer._t += 0.5
		layer.refresh()   # and flies
		check(layer.shown().any(func(b): return b.id == c.id and b.pose == "fly"), "3D: set_farmer by the tree sends it off")
	w3.free()
	var M3: GDScript = load("res://scripts/main_3d.gd")
	var made: Array = M3.new_world(MM.data("town"))
	for step in made[1]:
		step.call()
	check(made[0].get_children().any(func(n): return n.get_script() == LayerS), "3D: the village builds a cicada layer")
	made[0].free()


## The flat view: the node, the clinging ones among the figures, the fliers in the air pass.
func _flat() -> void:
	g.maps.place("hill", Vector2i(19, 28), Vector2i.UP)
	_when(1, 22, 12, 30, "sunny")
	var scene: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var view: Node2D = scene.view
	var cv: Node2D = null
	for n in view.get_children():
		if n.get_script() == load("res://scripts/world/cicada_view.gd"):
			cv = n
	check(cv != null, "flat (main_2d): the hill's view has its cicadas")
	if cv == null:
		scene.free()
		return
	var figs: Node2D = view.get_node_or_null("Figures") as Node2D
	cv.refresh()
	var sprites: Array = cv.sprites()
	check(not sprites.is_empty() and sprites.all(func(s): return not s.air), "flat (main_2d): clinging cicadas at noon (%d)" % sprites.size())
	var nodes: Array[Node2D] = cv.clinging_nodes()
	check(nodes.size() == sprites.size() and nodes.all(func(n): return n.get_parent() == figs), "flat (main_2d): each a node in the figure layer")
	if not nodes.is_empty():
		var s: Dictionary = sprites[0]
		check(nodes[0].picture.at.y < FOOT and (s.at as Vector2).y < (s.ground as Vector2).y, "flat (main_2d): drawn up the trunk, sorted by its foot")
	check(_z_of(cv.air) > _z_of(scene.player), "flat (main_2d): fliers over the farmer")
	# The farmer walks up to one: it flies off into the air pass.
	var first: Dictionary = cv._shown[0]
	var spot: Vector3 = first.pos
	scene.player.position = Vector2(spot.x + 0.6, spot.z) * 16.0
	cv._t += 0.1
	cv.refresh()
	cv._t += 0.5
	cv.refresh()
	check(cv.sprites().any(func(x): return x.air and (x.key as String).contains(":fly:")), "flat (main_2d): the one by the farmer flies, in the air pass")
	_when(1, 22, 12, 30, "rain")
	cv.refresh()
	check(not cv.visible and cv.clinging_nodes().is_empty(), "flat (main_2d): none in rain")
	scene.queue_free()
	await process_frame
	# Indoors the flat view makes none.
	g.maps.place("store", Vector2i(3, 3), Vector2i.UP)
	var inside: Node = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(inside)
	await process_frame
	check(not inside.view.get_children().any(func(n): return n.get_script() == load("res://scripts/world/cicada_view.gd")), "flat (main_2d): none in the store")
	inside.queue_free()
	await process_frame


const FOOT := 2   # FigureLayer.FOOT (checked in test_view2d)


## The z a canvas item is drawn at (its z_index added to its parents' while relative).
func _z_of(n: CanvasItem) -> int:
	var z := 0
	var c: Node = n
	while c is CanvasItem:
		z += (c as CanvasItem).z_index
		if not (c as CanvasItem).z_as_relative:
			break
		c = c.get_parent()
	return z
