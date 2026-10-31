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
	a.tool_index = 2
	a.seed_index = 4
	a.bag = {"seeds:turnip": 3, "corn": 2}
	a.tool_levels.hoe = 3
	a.tool_levels.can = 5
	var saved: Dictionary = a.to_dict()
	check(SaveGame.write(a, PATH) == "", "write save")

	# Load into a different new game; the same FarmGrid object is filled in place.
	var b: Node = _game(game_script, crops, 99)
	var grid: FarmGrid = b.farm
	var seen := {"cells": 0, "day": 0, "changed": 0}
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
			["tool_levels", {"hoe": 2.5}]]:
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
