extends SceneTree
## Headless title screen checks (TitleMenu, SaveGame.check, Game.new_game). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_title.gd

const PATH := "user://test_title.json"

var failures := 0


func _init() -> void:
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var g: Node = game_script.new()
	g.crops = crops
	g.rng.seed = 7
	g.new_game()
	_remove()

	# No save: Continue off, the cursor on New game, and it skips Continue both ways.
	var m := TitleMenu.make(g, PATH)
	check(not m.enabled.continue, "no file: continue off")
	check(m.why_no_continue == "No saved game", "no file: says why (%s)" % m.why_no_continue)
	check(m.current() == "new", "no file: cursor on new game")
	m.move(1)
	check(m.current() == "quit", "down skips continue")
	m.move(1)
	check(m.current() == "new", "down wraps to new game")
	m.move(-1)
	check(m.current() == "quit", "up wraps to quit")
	m.move(-1)
	check(m.current() == "new", "up skips continue")
	check(not m.point("continue") and m.current() == "new", "the mouse can't point at continue")
	check(m.point("quit") and m.choose() == "quit", "pointing and choosing quit")
	m.cursor = TitleMenu.ITEMS.find("continue")
	check(m.choose() == "", "choosing an item that is off does nothing")

	# Files that would not load keep Continue off.
	var good := JSON.stringify({"version": 1, "game": g.to_dict()})
	var bad_day: Dictionary = g.to_dict()
	bad_day.day = 99
	var bad_crop: Dictionary = g.to_dict()
	bad_crop.farm.cells[300].crop = "melon_from_nowhere"
	var broken := {
		"empty": "",
		"not json": "{ this is not json",
		"cut off": good.substr(0, good.length() / 2),
		"no version": JSON.stringify({"game": g.to_dict()}),
		"newer version": JSON.stringify({"version": 2, "game": g.to_dict()}),
		"bad day": JSON.stringify({"version": 1, "game": bad_day}),
		"unknown crop": JSON.stringify({"version": 1, "game": bad_crop}),
	}
	for what in broken:
		_put(broken[what])
		m = TitleMenu.make(g, PATH)
		check(not m.enabled.continue and m.why_no_continue != "", "broken file (%s): continue off" % what)
		check(m.current() == "new", "broken file (%s): cursor on new game" % what)

	# A good save: Continue on and chosen first; checking it doesn't load it.
	var saved: Node = game_script.new()
	saved.crops = crops
	saved.rng.seed = 3
	saved.new_game()
	saved.day = 12
	saved.money = 2345
	saved.farm.till(Vector2i(10, 10))
	check(SaveGame.write(saved, PATH) == "", "wrote a save")
	var before: Dictionary = g.to_dict()
	m = TitleMenu.make(g, PATH)
	check(m.enabled.continue and m.why_no_continue == "", "good file: continue on (%s)" % m.why_no_continue)
	check(m.current() == "continue" and m.choose() == "continue", "good file: cursor on continue")
	check(g.to_dict() == before, "checking the save changed nothing")
	m.move(1)
	check(m.current() == "quit", "down from continue is quit")
	m.move(1)
	m.move(1)
	check(m.current() == "continue", "continue can be reached again")
	check(SaveGame.read(g, PATH) == "" and g.to_dict() == saved.to_dict(), "continue loads the save")

	# New game: nothing from the game before is left, whatever was changed.
	g.rng.seed = 11
	g.new_game()
	var fresh: Dictionary = g.to_dict()
	check(fresh.year == 1 and fresh.season == 0 and fresh.day == 1 and fresh.hour == 6 and fresh.minute == 0, "new game: first morning")
	check(fresh.money == 500 and fresh.bin_total == 0 and fresh.stamina == 100 and fresh.max_stamina == 100, "new game: money and stamina")
	check(fresh.tool == "hoe" and fresh.water == g.WATER_MAX, "new game: hoe in hand, full can")
	check(fresh.bag == {"seeds:turnip": 2, "seeds:potato": 1}, "new game: starting bag")
	check(fresh.flags == {}, "new game: no dialogue flags")
	check(SaveGame.read(g, PATH) == "", "loaded the save again")
	g.year = 3
	g.season = 2
	g.hour = 1
	g.minute = 59
	g.weather_today = "storm"
	g.bin_total = 99
	g.max_stamina = 150
	g.stamina = 3
	g.water = 0
	g.tool_index = 4
	g.seed_index = 2
	g.bag["turnip"] = 5
	g._accum = 0.4
	g.snow_cover = 80
	g.tool_levels["hoe"] = 4
	g.flags = {"bin_note_read": true}
	var old_farm: FarmGrid = g.farm
	g.rng.seed = 11
	g.new_game()
	check(g.to_dict() == fresh, "new game after a played game equals a fresh one")
	check(g.farm != old_farm and g._accum == 0.0, "new game: a new farm and a clean clock")
	var tilled := 0
	for d in g.farm.cells:
		tilled += int(d.tilled or d.crop != "")
	check(tilled == 0, "new game: no tilled soil or crops")

	_remove()
	g.free()
	saved.free()
	print("test_title: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func _put(text: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
