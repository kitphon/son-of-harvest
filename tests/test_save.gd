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
	a.food_index = 3
	a.work_fatigue_half = true
	a.bag = {"seeds:turnip": 3, "corn": 2, "food:milk": 4}
	a.inventory.add("cucumber", 7, ["chest"])
	a.inventory.add("egg", 1, ["hand"])
	a.inventory.move("tools", 0, "chest", 4)   # the hoe put away in the chest
	a.tool_levels.hoe = 3
	a.tool_levels.can = 5
	a.flags = {"bin_note_read": true, "times_asked": 3, "answer": "later"}
	a.tool_exp.hoe = 950
	a.tool_exp.axe = 12
	a.events_seen = {"first_morning": true, "pond_first": true}
	a.maps.place("house", Vector2i(3, 2), Vector2i.LEFT)
	a.shipped = {"turnip": 14, "corn": 2}
	f.place_item(Vector2i(9, 5), "potato")
	f.place_item(Vector2i(10, 6), "turnip")
	a.first_day = {"values": {"shipped_value": 0, "recipes_known": 4}, "field": {"debris": 88, "tilled": 0, "money": 500}}
	a.farmer_look = {"style": "bun", "hair": "auburn", "skin": "tan", "clothes": "plum"}
	a.year_pages = {2: {"year": 2, "values": {"mine_deepest": 5, "fish_kinds": 1}, "field": {"debris": 40, "money": 900}, "stars": 3, "rank": 0}}
	var saved: Dictionary = a.to_dict()
	_clear(PATH)   # no backup left from an earlier run (it would stand in for the broken files below)
	check(SaveGame.write(a, PATH) == "", "write save")
	check(not FileAccess.file_exists(PATH + SaveGame.TEMP), "no temp file left after saving")
	check(not FileAccess.file_exists(PATH + SaveGame.BACKUP), "the first save has no backup")
	# The title's check loads into a scratch game with the real data: a save holding a food
	# (milk, as in the save the playtest's title refused) passes.
	a.food_index = a.foods.keys().find("milk")
	check(SaveGame.write(a, PATH) == "", "write a save holding milk")
	check(SaveGame.check(a, PATH) == "", "the title's check passes a save holding milk (%s)" % SaveGame.check(a, PATH))
	a.food_index = 3
	check(SaveGame.write(a, PATH) == "", "write save again")
	_remove_backup(PATH)

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
	check(b.count("corn") == 2 and b.count("egg") == 1 and b.inventory.count("cucumber", ["chest"]) == 7, "rucksack, hand and chest back")
	check(b.inventory.id_at("chest", 4) == "hoe" and b.inventory.id_at("tools", 0) == "", "tools back in their slots")
	check(b.current_food() == a.current_food() and b.current_food() != "" and b.work_fatigue_half, "food in hand and today's half fatigue back")
	check(b.count("food:milk") == 4, "food in the bag back")
	check(b.held == "egg" and b.shipped == a.shipped and typeof(b.shipped.turnip) == TYPE_INT, "held item (the hand slot) and shipping counts back")
	check(grid.items == {Vector2i(9, 5): "potato", Vector2i(10, 6): "turnip"}, "items on the ground back %s" % grid.items)
	check(b.first_day == a.first_day and b.year_pages == a.year_pages and b.year_pages.keys()[0] is int
		and typeof(b.year_pages[2].values.mine_deepest) == TYPE_INT, "the first day and the yearly pages back %s" % [b.year_pages])
	check(b.farmer_look == a.farmer_look and saved.look == {"style": "bun", "hair": "auburn", "skin": "tan", "clothes": "plum"}
		and FarmerLooks.current == a.farmer_look, "the farmer's look back %s" % [b.farmer_look])
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
	for broken in [["day", 31], ["hour", "noon"], ["stamina", 500], ["tool_slot", 8], ["tool_slot", -1],
			["tool_slot", "hoe"], ["seed", "moonflower"], ["inventory", []], ["inventory", {"bag": "x"}],
			["weather_today", 3], ["tool_levels", [1]],
			["tool_levels", {"hoe": 0}], ["tool_levels", {"hoe": 6}], ["tool_levels", {"spoon": 1}],
			["tool_levels", {"hoe": 2.5}],
			["tool_exp", [1]], ["tool_exp", {"hoe": -1}], ["tool_exp", {"spoon": 3}], ["tool_exp", {"hoe": 1.5}],
			["tool_exp", {"hoe": 1 << 40}], ["tool_exp", {"seeds": 1}], ["snow_cover", 101], ["snow_cover", "deep"],
			["flags", [1]], ["flags", {"x": 2.5}], ["flags", {"x": [true]}], ["flags", {"": true}], ["flags", {"x": null}],
			["fatigue", -1], ["fatigue", 101], ["fatigue", 2.5], ["fatigue", "lots"],
			["events_seen", {"x": true}], ["events_seen", [1]], ["events_seen", [""]], ["events_seen", ["a", "a"]],
			["map", "house"], ["map", {"id": "moon", "x": 8, "y": 8, "facing": [0, 1]}],
			["map", {"id": "house", "x": -1, "y": 8, "facing": [0, 1]}], ["map", {"id": "house", "x": 8, "y": 8, "facing": [2, 0]}],
			["food", "pizza"], ["food", 3], ["work_fatigue_half", 1], ["work_fatigue_half", "yes"],
			["shipped", [1]], ["shipped", {"turnip": 0}], ["shipped", {"turnip": 1.5}],
			["shipped", {"": 2}],
			["records", []], ["records", {"first_day": {}, "pages": []}], ["records", {"first_day": saved.records.first_day}],
			["records", {"first_day": {"values": {"luck": 1}, "field": {}}, "pages": []}],
			["records", {"first_day": {"values": {}, "field": {"money": -5}}, "pages": []}],
			["records", {"first_day": saved.records.first_day, "pages": [{"year": 2}]}],
			["records", {"first_day": saved.records.first_day, "pages": [saved.records.pages[0], saved.records.pages[0]]}],
			["look", "bun"], ["look", [1]], ["look", {"style": 2}], ["look", {"nose": "big"}]]:
		var d := saved.duplicate(true)
		d[broken[0]] = broken[1]
		_put(JSON.stringify({"version": 1, "game": d}))
		check(SaveGame.read(b, PATH) != "", "refused bad %s" % broken[0])
	for farm_break in ["size", "short", "crop", "stage", "obj", "fixed", "items", "item_spot", "item_id", "item_twice"]:
		var d := saved.duplicate(true)
		match farm_break:
			"size": d.farm.w = 10
			"short": d.farm.cells.pop_back()
			"crop": d.farm.cells[5].crop = "mango"
			"stage": d.farm.cells[4 + 10 * FarmGrid.W].stage = 9
			"obj": d.farm.cells[7].obj = 12
			"fixed": d.farm.fixed.append([99, 0, "fence"])
			"items": d.farm.items = {"x": 1}
			"item_spot": d.farm.items.append([3, 99, "turnip"])
			"item_id": d.farm.items.append([3, 9, ""])
			"item_twice": d.farm.items.append([9, 5, "corn"])
		_put(JSON.stringify({"version": 1, "game": d}))
		check(SaveGame.read(b, PATH) != "", "refused broken farm (%s)" % farm_break)
	check(b.to_dict() == before, "failed loads changed nothing")

	# A save from before slots (a bag of counts, the tool by name, no chest on the farm) loads
	# with the tools in their starting slots and the bag's things in the rucksack.
	var old := saved.duplicate(true)
	old.erase("inventory")
	old.erase("tool_slot")
	old.tool = "sickle"
	old.bag = {"seeds:turnip": 3, "corn": 2}
	old.farm.fixed = old.farm.fixed.filter(func(s): return s[2] != "chest")
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "", "save from before slots loads (%s)" % err)
	check(b.current_tool() == "sickle" and b.tool_index == 2 and b.inventory.id_at("tools", 0) == "hoe", "old save: tool in hand by name")
	check(b.bag == {"seeds:turnip": 3, "corn": 2} and b.inventory.totals(["chest"]).is_empty(), "old save: bag into the rucksack")
	check(b.farm.fixed_at(FarmGrid.CHEST) == "chest", "old save: the farm gets the chest")
	for bad_old in [["tool", "spoon"], ["bag", {"corn": -1}], ["bag", {"hoe": 1}], ["bag", [1]]]:
		var d := old.duplicate(true)
		d[bad_old[0]] = bad_old[1]
		_put(JSON.stringify({"version": 1, "game": d}))
		check(SaveGame.read(b, PATH) != "", "old save: refused bad %s" % bad_old[0])
	# A save from before charging tools (no tool_levels) loads with every tool at level 1.
	old = saved.duplicate(true)
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

	# Kiku's persimmon keeps its planting day; a save from before the day was kept (the place
	# chosen, no day) loads with the twig planted on the loaded day, a sapling (Scion).
	old = saved.duplicate(true)
	old.flags = {"kiku_scion": "door", "kiku_scion_day": 37}
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.flags.get("kiku_scion_day") is int and b.flags.kiku_scion_day == 37, "the persimmon's planting day loads (%s)" % err)
	old.flags = {"kiku_scion": "field"}
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.flags.get("kiku_scion_day") == b.day_number() and Scion.stage(b.flags, b.day_number()) == "sapling",
		"an old save's persimmon is planted the day it loads (%s, %s)" % [err, str(b.flags.get("kiku_scion_day"))])

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
	# A save from before food (no food in hand, no half fatigue) loads with the first food.
	old = saved.duplicate(true)
	old.erase("food")
	old.erase("work_fatigue_half")
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.food_index == 0 and not b.work_fatigue_half, "save without food loads with the first food (%s)" % err)
	# A save from before holding: nothing shipped, nothing on the ground.
	old = saved.duplicate(true)
	old.erase("shipped")
	old.farm.erase("items")
	_put(JSON.stringify({"version": 1, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.shipped == {} and b.farm.items.is_empty(), "save without holding loads with nothing shipped (%s)" % err)
	# A save from before the yearly pages: none written, and of the first day what every game starts with.
	old = saved.duplicate(true)
	old.erase("records")
	_put(JSON.stringify({"version": 5, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.year_pages == {} and b.first_day.values == b.start_values() and b.first_day.field == {"money": b.START_MONEY},
		"save without records loads with no page and the start's numbers (%s)" % err)
	var back := Ending.compare(b.ending_record(), b.first_day, {}, b.field_counts())
	check(Ending.then_text(back.field[0]) == "-" and Ending.then_text(back.field.back()) == "500 G", "the field not kept shows a dash")

	# A save from before the look was chosen: the farmer's old look; a look the data no longer
	# has (a choice taken out later) loads as the default's, the rest kept.
	old = saved.duplicate(true)
	old.erase("look")
	_put(JSON.stringify({"version": 6, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.farmer_look == FarmerLooks.default_choice() and FarmerLooks.current == b.farmer_look
		and PlaceholderArt.tex("player:front:idle:0").get_image().get_data() == FigureArt.draw(FigureArt.FARMER_LOOK, false, "idle", 0, true).get_data(),
		"save without a look loads the default look (%s)" % err)
	old = saved.duplicate(true)
	old.look = {"style": "gone_now", "skin": "tan"}
	_put(JSON.stringify({"version": 6, "game": old}))
	err = SaveGame.read(b, PATH)
	check(err == "" and b.farmer_look == {"style": "tenugui", "hair": "chestnut", "skin": "tan", "clothes": "indigo"},
		"a look the data no longer has falls back, part by part (%s)" % err)
	_atomic(a, b)

	_clear(PATH)
	a.free()
	b.free()
	print("test_save: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func _game(game_script: GDScript, crops: Dictionary, seed_value: int) -> Node:
	var g: Node = game_script.new()
	g.crops = crops
	g.tools_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	g.reset_tool_levels()
	g.set_food_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json")))
	g.rng.seed = seed_value
	g.farm = FarmGrid.new(crops)
	g.farm.generate(g.rng)
	return g


## Saving goes through a temp file renamed over the slot, keeps the good save it replaces as
## a backup, and loading copes with a slot that is cut off (read mid-write) or missing.
func _atomic(a: Node, b: Node) -> void:
	const P := "user://test_save_atomic.json"
	_clear(P)
	a.money = 1111
	check(SaveGame.write(a, P) == "", "atomic: first save")
	var first := FileAccess.get_file_as_string(P)
	check(not FileAccess.file_exists(P + SaveGame.TEMP) and not FileAccess.file_exists(P + SaveGame.BACKUP), "atomic: one file, no temp, no backup")
	a.money = 2222
	check(SaveGame.write(a, P) == "", "atomic: second save")
	var second := FileAccess.get_file_as_string(P)
	check(FileAccess.get_file_as_string(P + SaveGame.BACKUP) == first, "atomic: the save it replaced is the backup")
	check(second != first and JSON.parse_string(second).game.money == 2222, "atomic: the slot holds the new save")
	check(not FileAccess.file_exists(P + SaveGame.TEMP), "atomic: the temp file was renamed away")
	check(SaveGame.backup_note(P) == "", "atomic: no note while the slot is good")

	# A temp file left by a save that died half-way changes nothing; the next save replaces it.
	_put_at(P + SaveGame.TEMP, second.substr(0, 100))
	check(SaveGame.read(b, P) == "" and b.money == 2222, "atomic: a stray temp file is ignored")
	check(SaveGame.write(a, P) == "" and not FileAccess.file_exists(P + SaveGame.TEMP), "atomic: the next save clears the stray temp")

	# The slot cut off half-way (as a reader sees a file mid-write): Continue loads the backup.
	_put_at(P, second.substr(0, second.length() / 2))
	b.money = 5
	check(SaveGame.check(b, P) == "", "truncated: the check passes on the backup (%s)" % SaveGame.check(b, P))
	check(SaveGame.read(b, P) == "" and b.money == 2222, "truncated: loads the backup (%d)" % b.money)
	check(SaveGame.backup_note(P).contains("cut off"), "truncated: the title says the backup is used (%s)" % SaveGame.backup_note(P))
	# The next save over a broken slot keeps the good backup rather than the broken file.
	a.money = 3333
	check(SaveGame.write(a, P) == "", "truncated: saving over it works")
	check(JSON.parse_string(FileAccess.get_file_as_string(P + SaveGame.BACKUP)).game.money == 2222, "truncated: the good backup is kept")

	# Cut off with no backup: a clear message, no crash, the game unchanged.
	_remove_backup(P)
	_put_at(P, second.substr(0, second.length() / 3))
	var before: Dictionary = b.to_dict()
	var err := SaveGame.read(b, P)
	check(err == "The save file is cut off or broken", "truncated, no backup: says so (%s)" % err)
	check(SaveGame.check(b, P) == err and b.to_dict() == before, "truncated, no backup: check agrees, game unchanged")
	check(SaveGame.backup_note(P) == "", "truncated, no backup: no backup note")
	for cut in [0, 1, 10, 1000, second.length() - 1]:
		_put_at(P, second.substr(0, cut))
		check(SaveGame.read(b, P) != "" and b.to_dict() == before, "truncated at %d: refused, game unchanged" % cut)

	# The slot gone (a crash between keeping the backup and the rename): the backup loads.
	_put_at(P + SaveGame.BACKUP, first)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(P))
	check(SaveGame.read(b, P) == "" and b.money == 1111, "missing slot: loads the backup")
	check(SaveGame.backup_note(P).contains("missing"), "missing slot: the title says so")

	# A save from a newer version is never swapped for the backup.
	_put_at(P, JSON.stringify({"version": SaveGame.VERSION + 1, "game": {}}))
	check(SaveGame.read(b, P).contains("newer version"), "newer slot: refused, no fallback")
	_clear(P)


func _clear(path: String) -> void:
	for p in [path, path + SaveGame.BACKUP, path + SaveGame.TEMP]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _remove_backup(path: String) -> void:
	if FileAccess.file_exists(path + SaveGame.BACKUP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + SaveGame.BACKUP))


func _put_at(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _put(text: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
