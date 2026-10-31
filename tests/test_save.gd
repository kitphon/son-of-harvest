extends SceneTree
## Headless save / load checks (SaveGame, Game.to_dict / from_dict, FarmGrid). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_save.gd

const PATH := "user://test_save.json"

var failures := 0


func _init() -> void:
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# A farm with crops, obstacles and wet soil, and a Game state away from the defaults.
	var a: Node = _game(game_script, crops, 7)
	var f: FarmGrid = a.farm
	for x in range(3, 8):
		var c := Vector2i(x, 10)
		f.cell(c).obj = FarmGrid.Obj.NONE
		f.till(c)
	f.sow(Vector2i(4, 10), "potato", "spring")
	f.water_cell(Vector2i(3, 10))
	f.cell(Vector2i(4, 10)).stage = 2
	f.cell(Vector2i(4, 10)).days = 1
	f.cell(Vector2i(6, 12)).obj = FarmGrid.Obj.STUMP
	f.cell(Vector2i(6, 12)).hits = 2
	f.cell(Vector2i(7, 12)).obj = FarmGrid.Obj.ROCK
	a.year = 2
	a.season = 1
	a.day = 17
	a.hour = 14
	a.minute = 35
	a.weather_today = "rain"
	a.weather_tomorrow = "storm"
	a.money = 1234
	a.bin_total = 360
	a.max_stamina = 120
	a.stamina = 41
	a.water = 9
	a.snow_cover = 70
	a.fatigue = 63
	a.tool_index = 2
	a.seed_index = 4
	a.bag = {"seeds:turnip": 3, "corn": 2}
	a.tool_levels.hoe = 3
	a.tool_levels.can = 5
	a.flags = {"bin_note_read": true, "times_asked": 3, "answer": "later"}
	a.tool_exp.hoe = 950
	a.tool_exp.axe = 12
	a.events_seen = {"first_morning": true, "pond_first": true}
	a.maps.place("house", Vector2i(3, 2), Vector2i.LEFT)
	var saved: Dictionary = a.to_dict()
	check(SaveGame.write(a, PATH) == "", "write save")

	# Load into a different new game; the same FarmGrid object is filled in place.
	var b: Node = _game(game_script, crops, 99)
	var grid: FarmGrid = b.farm
	var seen := {"cells": 0, "day": 0, "changed": 0, "map": []}
	b.map_changed.connect(func(id): seen.map.append(id))
	grid.cells_changed.connect(func(): seen.cells += 1)
	b.day_started.connect(func(): seen.day += 1)
	b.changed.connect(func(): seen.changed += 1)
	check(b.to_dict() != saved, "second game starts different")
	var err := SaveGame.read(b, PATH)
	check(err == "", "read save (%s)" % err)
	check(b.to_dict() == saved, "loaded state equals saved state")
	check(b.farm == grid, "views keep the same FarmGrid")
	check(seen.cells == 1 and seen.day == 1 and seen.changed >= 1, "load redraws through signals %s" % seen)
	check(grid.cell(Vector2i(4, 10)).crop == "potato" and grid.cell(Vector2i(4, 10)).stage == 2, "crop and stage back")
	check(grid.cell(Vector2i(3, 10)).wet and grid.cell(Vector2i(3, 10)).tilled, "wet soil back")
	check(grid.cell(Vector2i(6, 12)).obj == FarmGrid.Obj.STUMP and grid.cell(Vector2i(6, 12)).hits == 2, "stump and hits back")
	check(grid.fixed == f.fixed and grid.fixed_at(Vector2i(4, 3)) == "door", "buildings back")
	check(typeof(grid.cell(Vector2i(4, 10)).stage) == TYPE_INT and typeof(b.money) == TYPE_INT, "numbers come back as ints")
	check(b.current_tool() == "sickle" and b.hour == 14 and b.weather_tomorrow == "storm", "game fields back")
	check(b.tool_level("hoe") == 3 and b.tool_level("can") == 5 and b.max_charge("hoe") == 3, "tool levels back")
	check(b.tool_exp.hoe == 950 and b.tool_exp.axe == 12 and b.tool_exp.can == 0, "tool exp back")
	check(b.snow_cover == 70, "snow cover back")
	check(b.flags == a.flags and typeof(b.flags.times_asked) == TYPE_INT, "dialogue flags back %s" % b.flags)
	check(b.fatigue == 63, "fatigue back")
	check(b.events_seen == a.events_seen and saved.events_seen == ["first_morning", "pond_first"], "seen events back %s" % b.events_seen)
	check(b.maps.id == "house" and b.maps.pos == MapManager.cell_pos(Vector2i(3, 2)) and b.maps.facing == Vector2i.LEFT, "map and position back")
	check(seen.map == ["house"], "load moves the views to the saved map %s" % [seen.map])
	check(not b.ticking(), "loaded indoors: the clock stands")
	# The loaded farm keeps working by the rules.
	grid.water_cell(Vector2i(4, 10))
	grid.day_end("spring", "sunny", rng)
	check(grid.cell(Vector2i(4, 10)).stage == 3, "loaded crop keeps growing")

	# Missing, broken, newer or tampered files fail cleanly and change nothing.
	var before: Dictionary = b.to_dict()
	check(SaveGame.read(b, "user://no_such_save.json") != "", "missing file refused")
	for bad in ["", "{not json", "[1, 2]", '{"game": {}}', '{"version": 99, "game": {}}',
			'{"version": 1, "game": "x"}', '{"version": 1, "game": {}}']:
		_put(bad)
		check(SaveGame.read(b, PATH) != "", "refused: %s" % bad)
	for broken in [["day", 31], ["hour", "noon"], ["stamina", 500], ["tool", "spoon"], ["seed", "rice"],
			["bag", {"corn": -1}], ["weather_today", 3], ["tool_levels", [1]],
			["tool_levels", {"hoe": 0}], ["tool_levels", {"hoe": 6}], ["tool_levels", {"spoon": 1}],
			["tool_levels", {"hoe": 2.5}],
			["tool_exp", [1]], ["tool_exp", {"hoe": -1}], ["tool_exp", {"spoon": 3}], ["tool_exp", {"hoe": 1.5}],
			["tool_exp", {"hoe": 1 << 40}], ["tool_exp", {"seeds": 1}], ["snow_cover", 101], ["snow_cover", "deep"],
			["flags", [1]], ["flags", {"x": 2.5}], ["flags", {"x": [true]}], ["flags", {"": true}], ["flags", {"x": null}],
			["fatigue", -1], ["fatigue", 101], ["fatigue", 2.5], ["fatigue", "lots"],
			["events_seen", {"x": true}], ["events_seen", [1]], ["events_seen", [""]], ["events_seen", ["a", "a"]],
			["map", "house"], ["map", {"id": "moon", "x": 8, "y": 8, "facing": [0, 1]}],
			["map", {"id": "house", "x": -1, "y": 8, "facing": [0, 1]}], ["map", {"id": "house", "x": 8, "y": 8, "facing": [2, 0]}]]:
		var d := saved.duplicate(true)
		d[broken[0]] = broken[1]
		_put(JSON.stringify({"version": 1, "game": d}))
		check(SaveGame.read(b, PATH) != "", "refused bad %s" % broken[0])
	for farm_break in ["size", "short", "crop", "stage", "obj", "fixed"]:
		var d := saved.duplicate(true)
		match farm_break:
			"size": d.farm.w = 10
			"short": d.farm.cells.pop_back()
			"crop": d.farm.cells[5].crop = "mango"
			"stage": d.farm.cells[4 + 10 * FarmGrid.W].stage = 9
			"obj": d.farm.cells[7].obj = 12
			"fixed": d.farm.fixed.append([99, 0, "fence"])
		_put(JSON.stringify({"version": 1, "game": d}))
		check(SaveGame.read(b, PATH) != "", "refused broken farm (%s)" % farm_break)
	check(b.to_dict() == before, "failed loads changed nothing")

	# A save from before charging tools (no tool_levels) loads with every tool at level 1.
	var old := saved.duplicate(true)
	old.erase("tool_levels")
	_put(JSON.stringify({"version": 1, "game": old}))
	check(SaveGame.read(b, PATH) == "", "old save without tool levels loads")
	check(b.tool_level("hoe") == 1 and b.tool_level("can") == 1, "old save: tools at level 1")

	# A save from before tool experience (no tool_exp) loads with every tool at 0.
	old = saved.duplicate(true)
	old.erase("tool_exp")
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.tool_exp.hoe == 0 and b.tool_level("hoe") == 3, "old save without tool exp loads at 0 (%s)" % err)

	# A save from before snow cover existed still loads, with no snow.
	old = saved.duplicate(true)
	old.erase("snow_cover")
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.snow_cover == 0, "save without snow_cover loads with none (%s)" % err)

	# A save from before dialogue (no flags) loads with no flags set.
	old = saved.duplicate(true)
	old.erase("flags")
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.flags == {}, "save without flags loads with none (%s)" % err)

	# A save from before fatigue existed loads rested.
	old = saved.duplicate(true)
	old.erase("fatigue")
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.fatigue == 0, "save without fatigue loads with none (%s)" % err)

	# A save from before events (no events_seen) loads with none seen, so once-only events can play.
	old = saved.duplicate(true)
	old.erase("events_seen")
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.events_seen == {}, "save without events_seen loads with none (%s)" % err)
	# A save from before maps loads on the farm, in front of the house door.
	old = saved.duplicate(true)
	old.erase("map")
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.maps.id == "farm" and b.maps.pos == MapManager.cell_pos(Vector2i(4, 4)) and b.maps.facing == Vector2i.DOWN,
		"save without a map loads on the farm (%s)" % err)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	a.free()
	b.free()
	print("test_save: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func _game(game_script: GDScript, crops: Dictionary, seed_value: int) -> Node:
	var g: Node = game_script.new()
	g.crops = crops
	g.tools_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	g.reset_tool_levels()
	g.rng.seed = seed_value
	g.farm = FarmGrid.new(crops)
	g.farm.generate(g.rng)
	return g


func _put(text: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
