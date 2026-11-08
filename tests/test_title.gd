extends SceneTree
## Headless title screen checks (TitleMenu, SaveGame.check, Game.new_game, the new game's look
## step: FarmerLooks, LookMenu, the screen, FigureArt drawing the chosen look). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_title.gd

const PATH := "user://test_title.json"

var failures := 0
var _frame := 0


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
		"newer version": JSON.stringify({"version": SaveGame.VERSION + 1, "game": g.to_dict()}),
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
	check(fresh.fatigue == 0 and g.body_state() == "fine", "new game: rested")
	check(g.current_tool() == "hoe" and fresh.tool_slot == 0 and fresh.water == g.WATER_MAX, "new game: hoe in hand, full can")
	check(g.bag == {"seeds:turnip": 2, "seeds:potato": 1, "food:onigiri": 1}, "new game: starting bag")
	check(g.inventory.totals(["chest", "hand"]).is_empty(), "new game: empty chest and hand")
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
	g.add_item("turnip", 5)
	g.inventory.add("corn", 3, ["chest"])
	g._accum = 0.4
	g.snow_cover = 80
	g.tool_levels["hoe"] = 4
	g.flags = {"bin_note_read": true}
	g.tool_exp["hoe"] = 700
	g.fatigue = 90
	g._shown_state = "exhausted"
	var old_farm: FarmGrid = g.farm
	g.rng.seed = 11
	g.new_game()
	check(g.to_dict() == fresh, "new game after a played game equals a fresh one")
	check(g.farm != old_farm and g._accum == 0.0, "new game: a new farm and a clean clock")
	check(g.fatigue == 0 and g._shown_state == "fine", "new game: fatigue and the tired warning reset")
	var tilled := 0
	for d in g.farm.cells:
		tilled += int(d.tilled or d.crop != "")
	check(tilled == 0, "new game: no tilled soil or crops")

	# The look: kept by the game, saved, and back to the default on a new game.
	g.farmer_look = {"style": "long", "clothes": "plum"}
	check(g.farmer_look == {"style": "long", "hair": "chestnut", "skin": "warm", "clothes": "plum"}, "a look is kept whole (%s)" % g.farmer_look)
	check(FarmerLooks.current == g.farmer_look and g.to_dict().look == g.farmer_look, "the game's look is the art's and the save's")
	g.rng.seed = 11
	g.new_game()
	check(g.farmer_look == FarmerLooks.default_choice() and FarmerLooks.current == g.farmer_look and g.to_dict() == fresh, "new game: the default look")

	_remove()
	g.free()
	saved.free()
	_looks()


# The look step's screen reads the Game autoload, which is in the tree from the first frame.
func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_look_screen()
		print("test_title: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


## FarmerLooks' data and rules, LookMenu, and FigureArt drawing the looks: the default exactly
## as before, every other choice a picture of its own, the cache kept apart per look.
func _looks() -> void:
	var def := FarmerLooks.default_choice()
	check(def == {"style": "tenugui", "hair": "chestnut", "skin": "warm", "clothes": "indigo"}, "the default is the old look's (%s)" % def)
	for part in FarmerLooks.PARTS:
		var opts := FarmerLooks.options(part)
		var ids := FarmerLooks.ids(part)
		var unique := {}
		for id in ids:
			unique[id] = true
		var named := opts.all(func(o): return o.get("name") is String and o.name != "")
		check(opts.size() >= 4 and unique.size() == ids.size() and named, "%s: four or more choices, ids unique, all named" % part)
	for o in FarmerLooks.options("style"):
		check(o.hair_style in FigureArt.STYLES, "style %s is a FigureArt style" % o.id)
	for part in ["hair", "skin"]:
		for o in FarmerLooks.options(part):
			check(Color.html_is_valid(str(o.color)), "%s %s is a colour" % [part, o.id])
	for o in FarmerLooks.options("clothes"):
		check(["top", "waist", "lower", "accent", "shoes"].all(func(k): return Color.html_is_valid(str(o.get(k, "")))), "clothes %s has its five colours" % o.id)
	check(FarmerLooks.figure_look(def) == FigureArt.FARMER_LOOK and FarmerLooks.figure_look({}) == FigureArt.FARMER_LOOK, "the default's FigureArt look is the farmer's own")
	check(FarmerLooks.normalize({"style": "mohawk", "hair": 3, "skin": "tan"}) == {"style": "tenugui", "hair": "chestnut", "skin": "tan", "clothes": "indigo"},
		"unknown or broken parts fall back to the default")
	check(FarmerLooks.parse("x") == null and FarmerLooks.parse({"nose": "big"}) == null and FarmerLooks.parse({"style": 2}) == null, "a broken saved look is refused")
	check(FarmerLooks.parse({}) == def and FarmerLooks.parse({"style": "gone_now"}) == def, "a look the data no longer has loads as the default")
	check(FarmerLooks.from_flag("style:2,hair:1,skin:3,clothes:4") == {"style": "bun", "hair": "black", "skin": "brown", "clothes": "ash"}, "the debug flag by places")
	check(FarmerLooks.from_flag("clothes:moss,style:9,nose:1") == {"style": "tenugui", "hair": "chestnut", "skin": "warm", "clothes": "moss"}, "the debug flag by ids, bad pieces left out")
	check(FarmerLooks.stepped(def, "skin", -1).skin == "deep" and FarmerLooks.stepped(def, "skin", 1).skin == "light", "stepping wraps round")
	check(FarmerLooks.signature(def) == "" and FarmerLooks.signature({"hair": "gray"}) == "tenugui.gray.warm.indigo", "the signature: none for the default")

	# The default is drawn pixel for pixel as before (the hashes of the pictures before looks
	# could be chosen), on every pose and side.
	var golden := {"front:idle:0": "987fa7b0d21e5e769aeea6be99ad3980", "back:walk:1": "4efbbfcec7c2807c30541bebe4da6112",
		"front:fish_bite:1": "54f4db4f0a564832b52d4e318a6e33a3", "back:hold_walk:2": "f02aac49b7c952a7f561911fbfcfcc9e"}
	for k in golden:
		var bits: PackedStringArray = k.split(":")
		var img := FigureArt.draw(FarmerLooks.figure_look(def), bits[0] == "back", bits[1], int(bits[2]), true)
		check(img.get_data().hex_encode().md5_text() == golden[k], "the default look's %s unchanged" % k)
	var same := true
	for pose in FigureArt.POSES:
		for f in FigureArt.frames(pose):
			for back in [false, true]:
				same = same and FigureArt.draw(FarmerLooks.figure_look(def), back, pose, f, true).get_data() == FigureArt.draw(FigureArt.FARMER_LOOK, back, pose, f, true).get_data()
	check(same, "the default look draws every pose like the farmer's own")
	# Every choice changes the picture, and no two of a part look alike.
	for part in FarmerLooks.PARTS:
		var seen := {}
		for id in FarmerLooks.ids(part):
			var c := def.duplicate()
			c[part] = id
			var data := FigureArt.draw(FarmerLooks.figure_look(c), false, "idle", 0, true).get_data()
			var back := FigureArt.draw(FarmerLooks.figure_look(c), true, "walk", 1, true).get_data()
			seen[data.hex_encode() + back.hex_encode()] = id
		check(seen.size() == FarmerLooks.ids(part).size(), "every %s choice looks different (%d of %d)" % [part, seen.size(), FarmerLooks.ids(part).size()])
	# The art cache keeps each look's pictures apart, and the default's keys as they were.
	FarmerLooks.current = {}
	var plain := PlaceholderArt.tex("player:front:idle:0")
	check(plain.get_image().get_data() == FigureArt.draw(FigureArt.FARMER_LOOK, false, "idle", 0, true).get_data(), "the default look's picture")
	var other := {"style": "straw_hat", "hair": "black", "skin": "deep", "clothes": "moss"}
	FarmerLooks.current = FarmerLooks.normalize(other)
	check(FarmerLooks.cache_key("player:front:idle:0") == "player:front:idle:0@straw_hat.black.deep.moss" and FarmerLooks.cache_key("crop:turnip:1:growing") == "crop:turnip:1:growing",
		"a look's pictures carry its signature, other art doesn't")
	var dressed := PlaceholderArt.tex("player:front:idle:0")
	check(dressed != plain and dressed.get_image().get_data() == FigureArt.draw(FarmerLooks.figure_look(other), false, "idle", 0, true).get_data(), "another look: its own picture")
	check(PlaceholderArt.image("player:back:walk:1").get_data() == FigureArt.draw(FarmerLooks.figure_look(other), true, "walk", 1, true).get_data(), "PlaceholderArt.image follows the look too")
	FarmerLooks.current = FarmerLooks.default_choice()
	check(PlaceholderArt.tex("player:front:idle:0") == plain, "back to the default: the first picture again")

	# LookMenu: a row per part and Begin; left / right turn the row under the cursor.
	var m := LookMenu.new({"skin": "tan"})
	check(m.items == ["style", "hair", "skin", "clothes", "start"] and m.choice.skin == "tan" and m.current() == "style", "the look menu starts on the hair, from the look given")
	check(m.turn(1) and m.choice.style == "short" and m.value_name("style") == "Short", "right: the next hair style")
	check(m.turn(-1) and m.turn(-1) and m.choice.style == "straw_hat", "left wraps to the last")
	m.move(-1)
	check(m.current() == "start" and not m.turn(1) and m.choice == FarmerLooks.normalize({"style": "straw_hat", "skin": "tan"}), "Begin isn't turned")
	check(m.look() == FarmerLooks.figure_look(m.choice) and m.look().hair_style == "straw_hat" and m.look().accent == "d9b45a", "the menu's look, the straw hat's own straw")


## The title screen's look step: New game opens it (the menu hidden), the keys and actions
## change the rows and the preview, Esc goes back with nothing started, Begin starts the new
## game in the chosen look.
func _look_screen() -> void:
	var game: Node = root.get_node("Game")
	game.new_game()
	var t: Control = load("res://scripts/ui/title_screen.gd").new()
	t.start_scene = ""
	root.add_child(t)
	check(t.menu != null and t.look == null and not t._look_box.visible, "the title opens on its menu")
	t.menu.cursor = TitleMenu.ITEMS.find("new")
	t._do(t.menu.choose())
	check(t.look != null and t._look_box.visible and not t._menu_nodes[0].visible, "new game opens the look step, the menu hidden")
	check(t._preview.texture.get_image().get_data() == FigureArt.draw(FigureArt.FARMER_LOOK, false, "walk", 0, true).get_data(), "the preview: the default look walking")
	check(t._look_values.map(func(l): return l.text) == ["Tenugui", "Chestnut", "Warm beige", "Indigo"], "the rows show the default's names")
	var press := func(action: String) -> void:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = true
		t._input(e)
	press.call("ui_right")
	check(t.look.choice.style == "short" and t._look_values[0].text == "Short", "right changes the hair")
	check(t._preview.texture.get_image().get_data() == FigureArt.draw(FarmerLooks.figure_look(t.look.choice), false, "walk", 0, true).get_data(),
		"the preview follows the choice")
	press.call("ui_down")
	press.call("ui_left")
	check(t.look.current() == "hair" and t.look.choice.hair == "gray" and t._look_values[1].text == "Gray", "down, then left wraps the hair color")
	check(t._look_mark.position.y == t._look_row_y(1), "the mark on the row")
	t._process(t.TURN_TIME)
	check(t._preview.flip_h == false and t._preview.texture.get_image().get_data() != FigureArt.draw(FarmerLooks.figure_look(t.look.choice), false, "walk", 0, true).get_data(),
		"the preview turns round as time goes")
	press.call("ui_cancel")
	check(t.look == null and not t._look_box.visible and t._menu_nodes[0].visible and game.farmer_look == FarmerLooks.default_choice(),
		"Esc: back to the menu, nothing chosen")
	game.money = 777
	t._do("new")
	check(t.look.choice == FarmerLooks.default_choice(), "opened again: from the game's look")
	for a in ["ui_down", "ui_right", "ui_right", "ui_accept", "ui_left", "ui_accept", "ui_right"]:   # hair color +2, skin -1, clothes +1
		press.call(a)
	check(t.look.current() == "clothes" and t.look.choice == {"style": "tenugui", "hair": "dark_brown", "skin": "deep", "clothes": "persimmon"},
		"accept on a row goes to the next (%s)" % t.look.choice)
	press.call("ui_accept")
	check(t.look.current() == "start" and t.look != null, "then Begin")
	var chosen: Dictionary = t.look.choice.duplicate()
	press.call("ui_accept")
	check(t.look == null and game.farmer_look == chosen and FarmerLooks.current == chosen and game.to_dict().look == chosen, "Begin: the new game has the chosen look")
	check(game.money == 500 and game.day == 1 and game.clock_running, "Begin: a fresh game, the clock going")
	check(PlaceholderArt.tex("player:front:idle:0").get_image().get_data() == FigureArt.draw(FarmerLooks.figure_look(chosen), false, "idle", 0, true).get_data(),
		"the field's farmer is drawn in the chosen look")
	t.free()
	game.new_game()


func _put(text: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for p in [PATH, PATH + SaveGame.BACKUP, PATH + SaveGame.TEMP]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
