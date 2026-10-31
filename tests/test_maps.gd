extends SceneTree
## Headless checks for maps (data/maps, MapData, MapManager, Game map rules). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_maps.gd

var failures := 0


func _init() -> void:
	_map_files()
	_map_rules()


var _frame := 0
var _since_door := -1.0          # seconds since the door (the fade runs on real time)
var _scene: Node
var _entered: Array = []


func _process(delta: float) -> bool:
	_frame += 1
	if _since_door >= 0.0:
		_since_door += delta
	if _frame == 1:
		_homes_3d()
		_game_maps()
		_bed_and_doors()
		_story_props()
		_start_view()
	elif _frame == 3:
		var g: Node = root.get_node("Game")
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


func _check_view() -> void:
	var g: Node = root.get_node("Game")
	check(not _scene.fade.busy() and not g.paused(), "the fade ended and let go of the pause")
	check(_entered == ["farm", "house"], "map_entered after the fade %s" % [_entered])
	check(_scene.world.get_script().resource_path.ends_with("map_world.gd") and _scene.world.map.id == "house", "the view rebuilt as the house")
	check(_scene.player.position == g.maps.pos and _scene.player.facing == Vector2i.UP, "the farmer stands at the house spawn")
	var events: Array = _scene.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("event_player.gd"))
	check(events.size() == 1 and events[0].map_id == "house" and events[0].table.map_id == "house",
		"the event triggers follow the map")
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


## The homes build in 3D without the magenta stand-in box (MapWorld needs the autoloads, so
## this runs on the first frame).
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
		check(stand_in == 0 and meshes > 60, "%s builds in 3D (%d meshes, %d stand-ins)" % [id, meshes, stand_in])
		w.free()


## The props the band 5 heart events leave (StoryProps): each shows only with its flag (the
## sign by its value), follows the shared flags, survives save / load, builds in both views,
## and the bell rings when used.
func _story_props() -> void:
	var where := {"door_bell": "farm", "store_sign": "town", "ume_jar": "house"}
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
	for key in ["story:door_bell", "story:sign_old", "story:sign_new", "story:ume_jar"]:
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
	for n in [a, b]:
		n.free()


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
	var keep_save := FileAccess.get_file_as_string(SaveGame.SLOT) if FileAccess.file_exists(SaveGame.SLOT) else ""
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
	if keep_save != "":
		var f := FileAccess.open(SaveGame.SLOT, FileAccess.WRITE)
		f.store_string(keep_save)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.SLOT))
	g.new_game()


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
