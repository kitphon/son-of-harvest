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
		_game_maps()
		_bed_and_doors()
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
	check(t.door_at(Vector2i(5, 6)).to == "" and t.door_at(Vector2i(5, 6)).message != "", "village doors are shut for now")
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
