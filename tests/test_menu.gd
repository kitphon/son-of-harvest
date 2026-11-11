extends SceneTree
## Headless pause menu checks (Game's pause rule, Settings, PauseMenu, MenuList, Controls
## with the pad buttons and axes, settings in effect: text speed, HUD, always run, FPS limit,
## UI size, window sizes that don't fit). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_menu.gd

const PATH := "user://test_settings.json"
const ALL := ["language", "display", "window", "vsync", "fps", "ui_scale", "flashes", "text_speed", "always_run", "hud", "hints", "pad_style", "music", "sfx", "ambient"]

var failures := 0
var _frame := 0
var _p: Node2D            # the farmer checked over a few frames
var _start := Vector2.ZERO
var _swings := [0]


func _init() -> void:
	_pause_rule()
	_settings()
	_pause_menu()
	_fish_log()
	_shipped_page()
	_controls()
	_controls_menu()
	_pad()
	_pad_menu()
	_pad_axes()
	_text_speed()
	_window_fit()
	_ui_scale()
	_language()


# The farmer is checked on the Game autoload, which is in the tree from the first frame,
# over a few frames so a key press and its release don't fall in the same one.
func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_volumes_in_effect()
		_settings_in_effect()
		_key_hints()
		_shared_style()
	if _frame < 4:
		_farmer_in_menu(_frame)
		return false
	print("test_menu: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)
	return true


## While a menu is open the clock stands still; menus nest, closes never go below zero.
func _pause_rule() -> void:
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var g: Node = game_script.new()
	g.crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	g.rng.seed = 7
	g.new_game()
	check(g.ticking() and not g.paused(), "a new game ticks")
	g._process(1.0)
	check(g.time_text() == "06:02", "a second is two minutes (%s)" % g.time_text())
	g.pause()
	check(g.paused() and not g.ticking(), "paused: not ticking")
	g._process(30.0)
	check(g.time_text() == "06:02" and g._accum == 0.0, "no time passes in a menu (%s)" % g.time_text())
	g.pause()
	g.unpause()
	check(g.paused(), "a menu over a menu: closing the top one keeps the pause")
	g.unpause()
	check(not g.paused() and g.ticking(), "closing the last menu starts the clock again")
	g.unpause()
	g.pause()
	check(g.paused(), "an extra close doesn't cancel the next pause")
	g.unpause()
	g._process(0.5)
	check(g.time_text() == "06:03", "the clock goes on after the menu")
	g.dialogue_open = true
	check(g.paused() and not g.ticking(), "an open text box counts as paused")
	g.dialogue_open = false
	check(not g.paused(), "closing the text box ends that pause")
	g.clock_running = false
	check(not g.ticking(), "the title screen stops the clock without a pause")
	g.clock_running = true

	# Settings into effect: flashes off in the file, or `--no-flashes`, which wins over it.
	g.settings = Settings.make()
	g.apply_settings([])
	check(g.flashes_enabled, "flashes on by default")
	g.settings.values.flashes = false
	g.apply_settings([])
	check(not g.flashes_enabled and g.lightning_style().is_empty(), "flashes off from the settings")
	g.settings.values.flashes = true
	g.apply_settings(["--demo", "--no-flashes"])
	check(not g.flashes_enabled, "--no-flashes wins over the settings")
	check(g.text_speed == 1.0 and not g.always_run and g.hud_visible, "text speed, always run, HUD: defaults")
	g.settings.values.text_speed = "instant"
	g.settings.values.always_run = true
	g.settings.values.hud = false
	g.apply_settings([])
	check(g.text_speed == 0.0 and g.always_run and not g.hud_visible, "text speed, always run, HUD from the settings")
	check(g.max_fps == 0 and Engine.max_fps == 0 and g.ui_scale == 1.0, "FPS limit off, UI size 100%: defaults")
	g.settings.values.fps = "60"
	g.settings.values.ui_scale = "150%"
	g.apply_settings([])
	check(g.max_fps == 60 and Engine.max_fps == 60 and g.ui_scale == 1.5, "FPS limit 60 and UI size 150%% from the settings (%d, %s)" % [Engine.max_fps, g.ui_scale])
	g.settings.reset()
	g.apply_settings([])
	check(Engine.max_fps == 0, "reset: no FPS limit again")
	g.free()
	# The window scale drops to the biggest that fits on the screen.
	var base := Vector2i(480, 270)
	check(game_script.window_scale(3, base, Vector2i(1920, 1040)) == 3, "3x fits a 1080p screen")
	check(game_script.window_scale(4, base, Vector2i(1920, 1040)) == 3, "4x on a 1080p screen (less the taskbar): 3x")
	check(game_script.window_scale(4, base, Vector2i(2560, 1400)) == 4, "4x on a bigger screen")
	check(game_script.window_scale(2, base, Vector2i(800, 600)) == 1 and game_script.window_scale(0, base, Vector2i(9999, 9999)) == 1, "never below 1x")


## Settings: defaults from data, changing them, a round trip, and refusing broken files.
func _settings() -> void:
	var s := Settings.make()
	check(s.keys() == (ALL as Array[String]), "settings in data order (%s)" % [s.keys()])
	check(s.value("flashes") == true and s.value("window") == "3x" and s.value("display") == "windowed", "defaults")
	check(s.value("vsync") == true and s.value("text_speed") == "normal" and s.value("always_run") == false and s.value("hud") == true, "defaults of the new settings")
	check(s.value_text("flashes") == "On" and s.value_text("window") == "3x" and s.value_text("display") == "Window", "value text")
	check(s.value_text("text_speed") == "Normal" and s.option_value("text_speed") == 1.0, "text speed: label and value")
	check(s.option_value("window") == "3x", "a choice without values stands for itself")
	check(s.adjust("flashes", 1) and s.value("flashes") == false and s.value_text("flashes") == "Off", "flashes flip")
	check(s.adjust("window", 1) and s.value("window") == "4x", "window: next size")
	check(s.adjust("window", 1) and s.value("window") == "2x", "window wraps round")
	check(not s.adjust("window", -1, false) and s.value("window") == "2x", "no wrap: stops at the first")
	check(s.adjust("display", 1) and s.value_text("display") == "Full screen", "display: full screen")
	check(s.adjust("display", 1) and s.value_text("display") == "Borderless", "display: borderless")
	check(s.adjust("display", 1) and s.value("display") == "windowed", "display wraps round")
	for want in [["fast", 2.0], ["instant", 0.0], ["slow", 0.5]]:
		s.adjust("text_speed", 1)
		check(s.value("text_speed") == want[0] and s.option_value("text_speed") == want[1], "text speed %s = %s" % want)
	check(s.adjust("vsync", 1) and s.adjust("hud", 1) and s.adjust("always_run", 1), "the on / off settings flip")
	check(s.value("fps") == "off" and s.value_text("fps") == "Off" and s.option_value("fps") == 0, "FPS limit: off by default")
	for want in [["30", 30], ["60", 60], ["120", 120], ["144", 144], ["off", 0]]:
		s.adjust("fps", 1)
		check(s.value("fps") == want[0] and s.value_text("fps") == want[0].replace("off", "Off") and s.option_value("fps") == want[1], "FPS limit %s = %s" % want)
	check(s.value("ui_scale") == "100%" and s.option_value("ui_scale") == 1.0, "UI size 100% by default")
	check(s.adjust("ui_scale", 1) and s.value_text("ui_scale") == "125%" and s.option_value("ui_scale") == 1.25, "UI size 125%")
	check(s.adjust("ui_scale", 1) and s.option_value("ui_scale") == 1.5 and not s.adjust("ui_scale", 1, false), "UI size 150%, the biggest")

	_remove()
	check(s.read(PATH) == "" and s.value("flashes") == false, "no file: nothing changes")
	check(s.write(PATH) == "", "wrote the settings")
	var t := Settings.make()
	check(t.read(PATH) == "" and t.values == s.values, "round trip (%s)" % [t.values])

	var good := {"version": 2, "settings": {"flashes": false, "display": "fullscreen"}}
	var broken := {
		"empty": "",
		"not json": "{ flashes: off",
		"a list": "[1, 2]",
		"no version": JSON.stringify({"settings": good.settings}),
		"newer version": JSON.stringify({"version": 3, "settings": good.settings}),
		"full as a window size": JSON.stringify({"version": 2, "settings": {"window": "full"}}),
		"unknown display": JSON.stringify({"version": 2, "settings": {"display": "tiny"}}),
		"text speed as a number": JSON.stringify({"version": 2, "settings": {"text_speed": 2}}),
		"vsync as text": JSON.stringify({"version": 2, "settings": {"vsync": "on"}}),
		"hud as a number": JSON.stringify({"version": 2, "settings": {"hud": 0}}),
		"no settings": JSON.stringify({"version": 1}),
		"flashes as text": JSON.stringify({"version": 1, "settings": {"flashes": "yes"}}),
		"unknown window": JSON.stringify({"version": 1, "settings": {"window": "8x"}}),
		"window as number": JSON.stringify({"version": 1, "settings": {"window": 3}}),
		"music too loud": JSON.stringify({"version": 1, "settings": {"music": 150}}),
		"sfx below 0": JSON.stringify({"version": 1, "settings": {"sfx": -10}}),
		"ambient as text": JSON.stringify({"version": 1, "settings": {"ambient": "loud"}}),
		"music in pieces": JSON.stringify({"version": 1, "settings": {"music": 45.5}}),
		"fps as a number": JSON.stringify({"version": 2, "settings": {"fps": 60}}),
		"unknown fps": JSON.stringify({"version": 2, "settings": {"fps": "75"}}),
		"unknown UI size": JSON.stringify({"version": 2, "settings": {"ui_scale": "300%"}}),
	}
	for what in broken:
		_put(broken[what])
		var b := Settings.make()
		b.values.window = "4x"
		var err := b.read(PATH)
		var want := Settings.make().values
		want.window = "4x"
		check(err != "" and b.values == want, "broken file (%s) refused, nothing changed: %s" % [what, err])
	_put(JSON.stringify({"version": 1, "settings": {"window": "2x", "from_later": 70}}))
	var older := Settings.make()
	var want_older := Settings.make().values
	want_older.window = "2x"
	check(older.read(PATH) == "" and older.values == want_older, "missing setting = default, unknown one skipped")
	# A version 1 file: its full-screen window is the borderless display now.
	_put(JSON.stringify({"version": 1, "settings": {"window": "full", "flashes": false}}))
	var v1 := Settings.make()
	check(v1.read(PATH) == "" and v1.value("display") == "borderless" and v1.value("window") == "3x" and v1.value("flashes") == false, "version 1: full = borderless (%s)" % [v1.values])
	_put(JSON.stringify({"version": 1, "settings": {"window": "2x"}}))
	check(v1.read(PATH) == "" and v1.value("display") == "windowed" and v1.value("window") == "2x", "version 1: a window size stays")
	s.reset()
	check(s.values == Settings.make().values and s.value("fps") == "off" and s.value("ui_scale") == "100%", "reset: every setting back to its default")
	check(s.write(PATH) == "" and JSON.parse_string(FileAccess.get_file_as_string(PATH)).version == 2.0, "written as version 2")

	# A whole-number range (the kind a volume setting would use).
	var r := Settings.make()
	r.spec.volume = {"label": "Volume", "kind": "range", "default": 80, "min": 0, "max": 100, "step": 10}
	r.reset()
	check(r.value("volume") is int and r.value_text("volume") == "80", "range default (%s)" % r.value_text("volume"))
	check(r.adjust("volume", 1) and r.value("volume") == 90, "range up a step")
	r.adjust("volume", 1)
	check(not r.adjust("volume", 1, false) and r.value("volume") == 100, "range stops at the top")
	check(r.adjust("volume", 1) and r.value("volume") == 0, "range wraps to the bottom")
	check(r.valid("volume", 50.0) == 50 and r.valid("volume", 55.5) == null and r.valid("volume", 101) == null, "range check")

	# The volume sliders: defaults, %, steps that stop at 0 and 100, a round trip, and the bus
	# volumes the Sfx autoload takes from them.
	var v := Settings.make()
	check(v.value("music") == 70 and v.value("sfx") == 80 and v.value("ambient") == 60, "volume defaults")
	check(v.value_text("music") == "70%" and v.value_text("ambient") == "60%", "volumes in %% (%s)" % v.value_text("music"))
	check(v.bus_volumes() == {"Music": 0.7, "SFX": 0.8, "Ambient": 0.6}, "bus volumes (%s)" % [v.bus_volumes()])
	for i in 3:
		v.adjust("music", 1, false)
	check(v.value("music") == 100 and not v.adjust("music", 1, false), "music stops at 100")
	for i in 12:
		v.adjust("sfx", -1, false)
	check(v.value("sfx") == 0 and v.value_text("sfx") == "0%", "sounds down to 0")
	check(v.bus_volumes().SFX == 0.0 and v.bus_volumes().Music == 1.0, "0 and 100 as bus volumes")
	v.values.ambient = 30
	check(v.write(PATH) == "", "wrote the volumes")
	var w := Settings.make()
	check(w.read(PATH) == "" and w.value("music") == 100 and w.value("sfx") == 0 and w.value("ambient") == 30, "volumes round trip (%s)" % [w.values])
	_put(JSON.stringify({"version": 1, "settings": {"flashes": false, "window": "2x"}}))
	var before := Settings.make()
	check(before.read(PATH) == "" and before.value("music") == 70 and before.value("flashes") == false, "a file from before the volumes: default volumes")
	_remove()


## The pause menu's pages: what each choice does and where the cursor lands.
func _pause_menu() -> void:
	var s := Settings.make()
	var m := PauseMenu.new(s)
	check(m.page == "main" and m.list.items == (["resume", "save", "settings", "fishlog", "shipped", "title"] as Array[String]), "main page")
	check(m.heading() == "Paused" and m.list.current() == "resume", "cursor on resume")
	check(m.choose() == "resume", "resume closes the menu")
	check(m.back() == "resume", "Esc on the main page closes it")
	m.list.move(1)
	check(m.choose() == "save" and m.page == "main", "save stays on the page")
	m.list.move(1)
	check(m.choose() == "" and m.page == "settings", "settings opens its page")
	var rows: Array[String] = []
	rows.assign(ALL + ["reset", "controls", "back"])
	check(m.list.items == rows, "settings rows from data, then reset, controls and back (%s)" % [m.list.items])
	check(m.slider("flashes") == Vector2i.ZERO and m.slider("back") == Vector2i.ZERO, "no slider on on / off rows")
	check(m.label("flashes") == "Lightning: On" and m.label("window") == "Window size: 3x", "rows show values")
	check(m.label("display") == "Display: Window" and m.label("vsync") == "V-sync: On" and m.label("text_speed") == "Text speed: Normal", "the new rows (%s)" % m.label("display"))
	check(m.label("always_run") == "Always run: Off" and m.label("hud") == "Show HUD: On" and m.label("reset") == "Reset to defaults", "toggles and reset rows")
	var shown := []
	for item in m.list.items:
		shown.append(m.label(item))
	check(PixelFont.missing("".join(shown)) == "", "the pixel font has every settings row (%s)" % PixelFont.missing("".join(shown)))
	check(m.list.current() == "language", "the cursor starts on the language")
	m.list.move(1)
	check(m.list.current() == "display" and m.adjust(1) == "setting" and m.label("display") == "Display: Full screen", "right: full screen")
	check(m.adjust(1) == "setting" and m.adjust(1) == "" and s.value("display") == "borderless", "borderless, then the end")
	m.list.point("flashes")
	check(m.choose() == "setting" and s.value("flashes") == false and m.label("flashes") == "Lightning: Off", "enter flips flashes")
	check(m.adjust(1) == "setting" and s.value("flashes") == true, "right flips it back")
	m.list.point("window")
	check(m.adjust(1) == "setting" and s.value("window") == "4x", "right: bigger window")
	check(m.adjust(1) == "" and s.value("window") == "4x", "right at the end does nothing")
	check(m.adjust(-1) == "setting" and s.value("window") == "3x", "left: back a size")
	m.list.point("text_speed")
	check(m.adjust(1) == "setting" and m.label("text_speed") == "Text speed: Fast", "right: faster text")
	check(m.adjust(1) == "setting" and m.adjust(1) == "" and m.label("text_speed") == "Text speed: Instant", "instant, then the end")
	m.list.point("music")
	check(m.label("music") == "Music: 70%" and m.slider("music") == Vector2i(7, 10), "music row: value and slider")
	check(m.adjust(1) == "setting" and s.value("music") == 80 and m.slider("music") == Vector2i(8, 10), "right: louder music")
	check(m.adjust(-1) == "setting" and m.adjust(-1) == "setting" and s.value("music") == 60, "left: softer")
	m.list.move(1)
	check(m.label("sfx") == "Sounds: 80%", "sounds row")
	m.adjust(1)
	m.adjust(1)
	check(m.adjust(1) == "" and s.value("sfx") == 100 and m.slider("sfx") == Vector2i(10, 10), "right at 100 does nothing")
	m.list.move(1)
	for i in 6:
		m.adjust(-1)
	check(m.adjust(-1) == "" and s.value("ambient") == 0 and m.label("ambient") == "Ambient: 0%", "left at 0 does nothing")
	check(m.choose() == "setting" and s.value("ambient") == 10, "enter on a slider steps it up")
	s.values.ambient = 100
	check(m.choose() == "setting" and s.value("ambient") == 0, "enter at the top wraps to 0")
	m.list.move(1)
	check(m.list.current() == "reset" and m.adjust(1) == "" and m.label("reset") == "Reset to defaults", "left / right on reset do nothing")
	s.controls.bind("run", 1, KEY_C)
	check(m.choose() == "setting" and s.values == Settings.make().values and m.note == "Settings back to the defaults.", "reset: settings back to the defaults")
	check(s.controls.keys("run") == [KEY_SHIFT, KEY_C], "reset on the settings page keeps the keys")
	m.list.point("hud")
	check(m.choose() == "setting" and m.note == "", "the next change clears the note")
	m.list.point("back")
	check(m.adjust(1) == "" and m.choose() == "" and m.page == "main", "back returns to the main page")
	check(m.list.current() == "settings", "cursor back on settings")
	m.open("settings")
	check(m.back() == "" and m.page == "main" and m.list.current() == "settings", "Esc on settings goes back one page")

	m.list.point("title")
	check(m.choose() == "" and m.page == "confirm" and m.heading() == "Save first?", "back to title asks first")
	check(m.list.current() == "save_title" and m.label("title") == "Go without saving", "confirm: saving is the first choice")
	check(m.choose() == "save_title", "save, then the title")
	m.list.move(1)
	check(m.choose() == "title", "or go without saving")
	m.list.move(1)
	check(m.choose() == "" and m.page == "main" and m.list.current() == "title", "cancel goes back, cursor on title")
	m.list.point("title")
	m.choose()
	check(m.back() == "" and m.page == "main", "Esc on the question goes back")

	# MenuList on its own: items that are off are skipped by keys and mouse.
	var l := MenuList.new(["a", "b", "c"] as Array[String])
	l.enabled.b = false
	l.move(1)
	check(l.current() == "c" and not l.point("b") and l.point("a"), "off items skipped")
	l.cursor = 1
	check(l.choose() == "", "an item that is off can't be chosen")


## The fish log page: a row per kind, caught ones named with their count, the rest "???".
func _fish_log() -> void:
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fish.json"))
	var caught := {"funa": 12, "ayu": 3}
	var m := PauseMenu.new(Settings.make(), rules, caught)
	m.list.point("fishlog")
	check(m.label("fishlog") == "Fish log" and m.choose() == "" and m.page == "fishlog" and m.heading() == "Fish log", "the main page opens the fish log")
	var ids: Array = rules.fish.keys()
	check(m.list.items.size() == ids.size() + 1 and m.list.items.back() == "back" and m.list.items[0] == ids[0], "a row per kind, then Back")
	check(m.label("funa") == "Crucian carp" and m.count_text("funa") == "x12", "a caught fish: name and count (%s, %s)" % [m.label("funa"), m.count_text("funa")])
	check(m.label("koi") == "???" and m.count_text("koi") == "", "an uncaught fish is ???")
	check(m.total_text() == "2 of %d kinds" % ids.size(), "the total (%s)" % m.total_text())
	check(m.fish_details("koi") == (["", "", ""] as Array[String]) and m.fish_details("back")[0] == "", "no details for an unknown fish or Back")
	var d := m.fish_details("ayu")
	check(d[0] == "Where: the river and the village pond" and d[1] == "Season: Summer" and d[2] == "Hours: 5:00-12:00", "details from the data (%s)" % [d])
	check(m.fish_details("funa")[1] == "Season: All year" and m.fish_details("funa")[2] == "Hours: Any hour", "all year, any hour")
	check(m.adjust(1) == "" and m.choose() == "" and m.page == "fishlog", "left / right and Enter on a fish do nothing")
	m.back()
	check(m.page == "main" and m.list.current() == "fishlog", "Esc goes back with the cursor on the fish log")
	m.choose()
	m.list.point("back")
	m.choose()
	check(m.page == "main" and m.list.current() == "fishlog", "Back returns too")
	var empty := PauseMenu.new(Settings.make())
	empty.open("fishlog")
	check(empty.list.items == (["back"] as Array[String]) and empty.total_text() == "0 of 0 kinds", "no fish data: an empty log opens without trouble")

## The shipped page: a row per thing the bin takes, shipped ones named with their count, the rest "???".
func _shipped_page() -> void:
	var rows := [{"id": "turnip", "name": "Turnip"}, {"id": "egg", "name": "Egg"}, {"id": "fish:funa", "name": "Crucian carp"}]
	var m := PauseMenu.new(Settings.make(), {}, {}, rows, {"turnip": 14, "fish:funa": 2})
	m.list.point("shipped")
	check(m.label("shipped") == "Shipped" and m.choose() == "" and m.page == "shipped" and m.heading() == "Shipped", "the main page opens the shipped page")
	check(m.list.items == (["turnip", "egg", "fish:funa", "back"] as Array[String]), "a row per item, then Back")
	check(m.label("turnip") == "Turnip" and m.count_text("turnip") == "x14", "a shipped item: name and count (%s, %s)" % [m.label("turnip"), m.count_text("turnip")])
	check(m.label("egg") == "???" and m.count_text("egg") == "", "an item never shipped is ???")
	check(m.shipped_total_text() == "2 of 3 shipped", "the total (%s)" % m.shipped_total_text())
	check(m.adjust(1) == "" and m.choose() == "" and m.page == "shipped", "left / right and Enter on an item do nothing")
	m.back()
	check(m.page == "main" and m.list.current() == "shipped", "Esc goes back with the cursor on the shipped page")
	m.choose()
	m.list.point("back")
	m.choose()
	check(m.page == "main" and m.list.current() == "shipped", "Back returns too")
	var empty := PauseMenu.new(Settings.make())
	empty.open("shipped")
	check(empty.list.items == (["back"] as Array[String]) and empty.shipped_total_text() == "0 of 0 shipped", "no rows: an empty page opens without trouble")


## The shipped page fits its width in English, Thai and a third longer (every real name), and its
## rows at every UI size.
func _shipped_fit() -> void:
	var pause: GDScript = load("res://scripts/ui/pause_screen.gd")
	var k: Dictionary = pause.get_script_constant_map()
	var g: Node = root.get_node("Game")
	var real: Array = g.shippable_rows()
	# The real rows: every one has a price, a name and an icon key, and none repeats.
	var seen := {}
	var ok := real.size() >= 40
	for r in real:
		ok = ok and g.sell_price(r.id) > 0 and String(r.name) != "" and not seen.has(r.id)
		seen[r.id] = true
	check(ok, "Game.shippable_rows: %d rows, all sellable, named, unique" % real.size())
	check(seen.has("turnip") and seen.has("egg_good") and seen.has("fish:funa") and seen.has("mine:satetsu") and seen.has("wild:warabi") and seen.has("food:onigiri"), "crops, animal goods, fish, mine finds, wild plants and dishes are all there")
	var t := PauseMenu.new(Settings.make(), {}, {}, real, {"turnip": 1})
	t.open("shipped")
	check(t.shipped_total_text() == "1 of %d shipped" % real.size(), "total over the real rows (%s)" % t.shipped_total_text())
	var all := {}
	for r in real:
		all[r.id] = 99
	var full := PauseMenu.new(Settings.make(), {}, {}, real, all)
	full.open("shipped")
	var name_room: int = k.FISHLOG_WIDTH - 8 - 18 - k.ICON_W - 30
	for lang in ["en", "th", Lang.PSEUDO]:
		Lang.set_language(lang)
		for r in real:
			check(PixelFont.shown_width(Lang.t(full.label(r.id))) <= name_room, "the name of %s fits in %s" % [r.id, lang])
		check(PixelFont.shown_width(Lang.t("%d of %d shipped") % [real.size(), real.size()]) <= k.FISHLOG_WIDTH - 8 - 18, "the shipped total fits in %s" % lang)
	Lang.set_language("en")
	for wanted in [1.0, 1.25, 1.5]:
		var n: int = pause.visible_rows(wanted, 270, 0)
		var h: float = (k.TOP + 8 + n * k.ROW_H + k.ROW_H + 4) * wanted
		check(n >= 5 and h <= 270 and UiScale.fit(wanted, Vector2(k.FISHLOG_WIDTH, h / wanted), Vector2(480, 270)) == wanted, "shipped page at %d%%: %d rows fit (%d px)" % [int(wanted * 100), n, h])


## The fish log fits its width in English, Thai and a third longer, and its rows at every UI size
## The fish log fits, Thai and a third longer, and its rows at every UI size
## (PauseScreen names the Game autoload, so it is loaded by path once the tree is up).
func _fish_log_fit() -> void:
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fish.json"))
	var ids: Array = rules.fish.keys()
	var pause: GDScript = load("res://scripts/ui/pause_screen.gd")
	var k: Dictionary = pause.get_script_constant_map()
	# Every row and detail fits the box, in English and a third longer.
	var room: int = k.FISHLOG_WIDTH - 8 - 18   # a detail line
	var name_room: int = room - k.ICON_W - 30   # a name, with the count and the icon beside it
	var worst := 0
	var all := {}
	for id in ids:
		all[id] = 1
	var full := PauseMenu.new(Settings.make(), rules, all)
	full.open("fishlog")
	for lang in ["en", "th", Lang.PSEUDO]:
		Lang.set_language(lang)
		for id in ids:
			check(PixelFont.shown_width(full.label(id)) <= name_room, "the name of %s fits in %s" % [id, lang])
			for line in full.fish_details(id):
				worst = maxi(worst, PixelFont.shown_width(Lang.t(line)))
		check(worst <= room, "the fish log fits its width in %s (%d of %d px)" % [lang, worst, room])
		worst = 0
	Lang.set_language("en")
	for wanted in [1.0, 1.25, 1.5]:
		var n: int = pause.visible_rows(wanted, 270, k.FISH_LINES)
		var h: float = (k.TOP + 8 + n * k.ROW_H + (1 + k.FISH_LINES) * k.ROW_H + 4) * wanted
		check(n >= 5 and h <= 270 and UiScale.fit(wanted, Vector2(k.FISHLOG_WIDTH, h / wanted), Vector2(480, 270)) == wanted, "fish log at %d%%: %d rows fit (%d px)" % [int(wanted * 100), n, h])


## Controls: defaults from data, binding, swapping, refusing, clearing, the InputMap, the
## settings file and reset.
func _controls() -> void:
	var c := Controls.make()
	var acts := c.actions()
	check(acts.slice(0, 5) == (["move_up", "move_down", "move_left", "move_right", "run"] as Array[String]), "actions in data order (%s)" % [acts.slice(0, 5)])
	for a in ["use_tool", "interact", "next_tool", "next_seed", "rucksack", "pause", "quick_save", "quick_load"]:
		check(a in acts, "%s listed" % a)
	var tools: Array = load("res://scripts/autoload/game.gd").get_script_constant_map().TOOLS
	for i in tools.size():
		check(acts.has("tool_%d" % (i + 1)) and c.keys("tool_%d" % (i + 1))[0] == KEY_1 + i, "tool %d on its number key" % (i + 1))
	check(c.label("tool_1") == "Tool 1: Hoe" and c.label("pause") == "Pause (Esc)", "labels (%s, %s)" % [c.label("tool_1"), c.label("pause")])
	check(c.keys("move_up") == [KEY_W, KEY_UP] and c.keys("run") == [KEY_SHIFT, KEY_NONE], "default keys")
	var names := []
	for a in acts:
		names.append(c.label(a))
		for k in c.keys(a):
			names.append(Controls.key_name(k))
	for k in [KEY_SPACE, KEY_TAB, KEY_BRACKETLEFT, KEY_KP_1, KEY_CTRL]:
		names.append(Controls.key_name(k))
	check(PixelFont.missing("".join(names)) == "", "the pixel font has every label and key name (%s)" % PixelFont.missing("".join(names)))
	var seen := {}
	var dupes := 0
	for a in acts:
		for k in c.keys(a):
			if k != KEY_NONE:
				dupes += int(seen.has(k))
				seen[k] = a
	check(dupes == 0, "no default key starts two actions")

	# Into the InputMap.
	c.apply()
	check(_has_key("move_up", KEY_W) and _has_key("move_up", KEY_UP) and _has_key("rucksack", KEY_I), "keys in the input map")
	check(_has_key("pause", KEY_ESCAPE), "Esc pauses")
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	check(InputMap.event_is_action(start, "pause"), "the pad's Start still pauses")

	# Binding: a free key, a swap with another action, a trade between the action's own slots.
	var r := c.bind("run", 1, KEY_C)
	check(r.done and r.other == "" and c.keys("run") == [KEY_SHIFT, KEY_C], "a free key goes into the slot")
	r = c.bind("move_up", 0, KEY_E)
	check(r.done and r.other == "interact" and c.keys("move_up") == [KEY_E, KEY_UP] and c.keys("interact") == [KEY_W, KEY_K], "a taken key swaps (%s / %s)" % [c.keys("move_up"), c.keys("interact")])
	check(c.owner_of(KEY_W) == "interact" and c.owner_of(KEY_E) == "move_up", "each key has one action")
	r = c.bind("move_up", 1, KEY_E)
	check(r.done and r.other == "" and c.keys("move_up") == [KEY_UP, KEY_E], "the action's own slots trade")
	check(c.bind("move_up", 1, KEY_E).done and c.keys("move_up") == [KEY_UP, KEY_E], "the same key again changes nothing")
	# Refused: the menu key, and a swap that would leave the other action with no key.
	r = c.bind("run", 0, KEY_ESCAPE)
	check(not r.done and r.reason == "reserved" and r.other == "pause" and c.keys("run") == [KEY_SHIFT, KEY_C], "Esc can't be taken")
	r = c.bind("next_tool", 1, KEY_Q)
	check(not r.done and r.reason == "last_key" and r.other == "next_seed" and c.keys("next_seed") == [KEY_Q, KEY_NONE], "no swap that leaves an action without a key")
	r = c.bind("next_tool", 0, KEY_Q)
	check(r.done and c.keys("next_tool") == [KEY_Q, KEY_NONE] and c.keys("next_seed") == [KEY_TAB, KEY_NONE], "a key for a key is fine")
	check(c.bind("pause", 0, KEY_P).done and c.key_count("pause") == 2, "pause gets a second key next to Esc")
	check(c.clear("pause", 0) == "" and c.clear("pause", 1) == "empty", "pause's own key can go, Esc stays")
	check(c.clear("next_seed", 0) == "last_key" and c.clear("use_tool", 1) == "" and c.keys("use_tool") == [KEY_SPACE, KEY_NONE], "clear: never the last key")
	c.apply()
	check(_has_key("move_up", KEY_E) and not _has_key("move_up", KEY_W) and _has_key("interact", KEY_W), "new keys in the input map")
	check(not _has_key("use_tool", KEY_J) and _has_key("pause", KEY_ESCAPE), "a cleared key is gone, Esc stays")

	# Saved with the settings, next to the other settings.
	_remove()
	var s := Settings.make()
	s.values.flashes = false
	s.controls.bound = c.bound.duplicate(true)
	check(s.write(PATH) == "", "wrote settings with keys")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	check(saved.controls.move_up == ["Up", "E"] and saved.controls.run == ["Shift", "C"] and saved.controls.use_tool == ["Space", ""], "keys by name in the file (%s)" % [saved.controls.move_up])
	var t := Settings.make()
	check(t.read(PATH) == "" and t.controls.bound == c.bound and t.value("flashes") == false, "keys round trip")

	var broken := {
		"keys not a dict": [1, 2],
		"keys not a list": {"run": "Shift"},
		"too many slots": {"run": ["Shift", "C", "V"]},
		"unknown key": {"run": ["NoSuchKey"]},
		"Esc taken": {"run": ["Escape"]},
		"a number": {"run": [16]},
		"shared key": {"run": ["X"], "interact": ["X"]},
		"no key at all": {"run": ["", ""]},
	}
	for what in broken:
		_put(JSON.stringify({"version": 1, "settings": {"flashes": false}, "controls": broken[what]}))
		var b := Settings.make()
		b.controls.bind("run", 1, KEY_V)
		var kept: Dictionary = b.controls.bound.duplicate(true)
		var err := b.read(PATH)
		check(err != "" and b.controls.bound == kept and b.value("flashes") == true, "broken keys (%s) refused, nothing changed: %s" % [what, err])
	_put(JSON.stringify({"version": 1, "settings": {"flashes": false}}))
	var older := Settings.make()
	older.controls.bind("run", 1, KEY_V)
	check(older.read(PATH) == "" and older.controls.bound == Controls.make().bound, "a file from before the keys: default keys")
	_put(JSON.stringify({"version": 1, "settings": {}, "controls": {"run": ["W"], "later_action": ["Z"]}}))
	var part := Settings.make()
	check(part.read(PATH) == "" and part.controls.keys("run") == [KEY_W, KEY_NONE] and part.controls.keys("move_up") == [KEY_NONE, KEY_UP], "missing action: defaults less keys taken, unknown action skipped")
	_remove()

	c.reset()
	check(c.bound == Controls.make().bound, "reset: every key back to the default")
	c.apply()
	check(_has_key("move_up", KEY_W) and _has_key("use_tool", KEY_J), "defaults back in the input map")


## The controls page of the pause menu: listening, swapping, cancelling, reset and back.
func _controls_menu() -> void:
	var s := Settings.make()
	var m := PauseMenu.new(s)
	m.open("settings")
	m.list.point("controls")
	check(m.label("controls") == "Controls" and m.adjust(1) == "", "controls row on the settings page")
	check(m.choose() == "" and m.page == "controls" and m.heading() == "Controls", "controls opens its page")
	var want := s.controls.actions()
	want.append_array(["reset", "back"])
	check(m.list.items == want and m.list.current() == "move_up", "one row per action, then reset and back")
	check(m.label("move_up") == "Move up" and m.slot_text("move_up", 0) == "W" and m.slot_text("move_up", 1) == "Up", "row shows its keys")
	check(m.slot_text("run", 1) == "-" and m.slot_text("reset", 0) == "" and m.label("reset") == "Reset to defaults", "empty slot, no slots on reset")
	check(m.hint() == PauseMenu.HINT, "hint line")
	check(m.press(KEY_X) == "" and s.controls.keys("move_up")[0] == KEY_W, "a key without listening does nothing")
	check(m.choose() == "" and m.listening == "move_up" and m.slot_text("move_up", 0) == "...", "enter: listening")
	check(m.hint().begins_with("Press a key for Move up"), "asks for a key (%s)" % m.hint())
	m.adjust(1)
	check(m.slot == 0, "no slot change while listening")
	check(m.press(KEY_ESCAPE) == "" and m.listening == "" and s.controls.keys("move_up")[0] == KEY_W, "Esc cancels")
	check(m.adjust(1) == "" and m.slot == 1 and m.adjust(1) == "" and m.slot == 2 and m.adjust(1) == "" and m.slot == 2, "right: second key slot, the pad slot, stops there")
	check(m.slot_count() == 3 and m.is_pad_slot() and m.slot_text("move_up", 2) == "D-up", "the third slot is the pad button")
	m.adjust(-1)
	m.choose()
	check(m.press(KEY_I) == "controls" and s.controls.keys("move_up") == [KEY_W, KEY_I] and s.controls.keys("rucksack") == [KEY_UP, KEY_NONE], "a taken key swaps")
	check(m.note == "I was on Rucksack: swapped." and m.hint() == m.note, "says what was swapped (%s)" % m.note)
	m.choose()
	check(m.press(KEY_ESCAPE) == "" and m.note == "", "Esc while listening cancels quietly")
	m.adjust(-1)
	m.choose()
	check(m.back() == "" and m.page == "controls" and m.listening == "", "Esc (back) while listening stays on the page")
	m.list.point("next_tool")
	m.adjust(1)
	m.choose()
	check(m.press(KEY_Q) == "" and m.note == "Q is the only key for Next seed / food.", "refused swap says why (%s)" % m.note)
	m.choose()
	check(m.press(KEY_ESCAPE) == "" and s.controls.keys("next_tool") == [KEY_TAB, KEY_NONE], "nothing changed")
	m.list.point("use_tool")
	m.slot = 1
	check(m.clear() == "controls" and s.controls.keys("use_tool") == [KEY_SPACE, KEY_NONE], "delete clears the slot")
	m.slot = 0
	check(m.clear() == "" and m.note == "Tool / put down needs a key.", "never the last key")
	m.list.point("reset")
	check(m.choose() == "controls" and s.controls.bound == Controls.make().bound and m.note == "Keys and buttons back to the defaults.", "reset to defaults")
	m.list.point("back")
	check(m.choose() == "" and m.page == "settings" and m.list.current() == "controls", "back: settings, cursor on controls")
	m.open("controls")
	check(m.back() == "" and m.page == "settings" and m.list.current() == "controls", "Esc on controls goes back one page")
	m.open("controls")
	m.list.point("quick_save")
	m.choose()
	m.press(KEY_BACKSPACE)
	check(s.controls.keys("quick_save") == [KEY_BACKSPACE, KEY_NONE], "any other key can be bound, Backspace too")
	check(m.clear() == "" and m.note == "Quick save needs a key.", "and clearing it is refused")


func _has_key(action: String, code: int) -> bool:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	return InputMap.event_is_action(ev, action, true)

## A changed volume setting reaches the bus as soon as Game applies the settings.
func _volumes_in_effect() -> void:
	var g: Node = root.get_node("Game")
	var sfx: Node = root.get_node("Sfx")
	var kept: Dictionary = g.settings.values.duplicate()
	check(is_equal_approx(sfx.get_volume("Music"), g.settings.value("music") / 100.0), "music volume from the settings on start")
	g.settings.values.music = 30
	g.settings.values.ambient = 0
	g.apply_settings([])
	check(is_equal_approx(sfx.get_volume("Music"), 0.3), "music slider applied at once (%.2f)" % sfx.get_volume("Music"))
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambient")), "ambient at 0 mutes its bus")
	g.settings.values = kept
	g.apply_settings([])
	check(is_equal_approx(sfx.get_volume("SFX"), kept.sfx / 100.0), "volumes back")


## With the menu open the farmer doesn't walk, a charge is dropped, and the key that closed
## the menu doesn't swing the tool.
func _farmer_in_menu(frame: int) -> void:
	var g: Node = root.get_node("Game")
	match frame:
		1:
			var player_script: GDScript = load("res://scripts/player/player.gd")
			_p = player_script.new()
			_p.farm = g.farm
			for x in range(9, 13):
				g.farm.cell(Vector2i(x, 10)).obj = FarmGrid.Obj.NONE
			_p.position = Vector2(10.5, 10.5) * 16
			root.add_child(_p)
			_p.action.connect(func(_k, _o, _f, _c): _swings[0] += 1)
			g.select_tool(g.TOOLS.find("hoe"))
			_p.charging = true
			_p.charge = 1
			g.pause()
			Input.action_press("move_right")
			_start = _p.position
			_p._physics_process(0.2)
			check(not _p.charging and _p.charge == 0, "opening a menu drops the charge")
			check(_p.position == _start and not _p.moving, "no walking in a menu")
			Input.action_release("move_right")
			Input.action_press("use_tool")   # Enter / Space on Resume
			_p._physics_process(0.2)
			g.unpause()
			_p._physics_process(0.2)
			_p._physics_process(0.2)
			check(not _p.charging and _swings[0] == 0, "the key that closed the menu does nothing")
		2:
			Input.action_release("use_tool")
			_p._physics_process(0.2)
		3:
			Input.action_press("move_right")
			_p._physics_process(0.2)
			Input.action_release("move_right")
			check(_p.position.x > _start.x and _swings[0] == 0, "walking again after the menu, no swing")
			_p.queue_free()


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


## Pad buttons: defaults from data, binding with swaps, Start kept on Pause, clearing, the
## InputMap (buttons and the left stick) and the settings file.
func _pad() -> void:
	var c := Controls.make()
	check(c.pad_button("use_tool") == JOY_BUTTON_A and c.pad_button("interact") == JOY_BUTTON_B and c.pad_button("move_up") == JOY_BUTTON_DPAD_UP, "default pad buttons")
	check(c.pad_button("rucksack") == JOY_BUTTON_BACK and c.pad_button("pause") == Controls.NO_BUTTON and c.pad_button("quick_save") == Controls.NO_BUTTON, "rucksack on Back; pause has only its fixed Start")
	check(c.pad_name(JOY_BUTTON_A) == "A" and c.pad_name(JOY_BUTTON_RIGHT_SHOULDER) == "RB" and c.pad_name(Controls.NO_BUTTON) == "-", "pad names from data")
	var names := []
	for b in c.pad_names:
		names.append(c.pad_name(b))
	check(PixelFont.missing("".join(names)) == "", "the pixel font has every pad name (%s)" % PixelFont.missing("".join(names)))
	var seen := {}
	var dupes := 0
	for a in c.actions():
		var b := c.pad_button(a)
		if b != Controls.NO_BUTTON:
			dupes += int(seen.has(b))
			seen[b] = a
	check(dupes == 0 and not seen.has(JOY_BUTTON_START), "no default button on two actions, Start free of them")

	var r := c.bind_pad("quick_save", JOY_BUTTON_LEFT_STICK)
	check(r.done and r.other == "" and c.pad_button("quick_save") == JOY_BUTTON_LEFT_STICK, "a free button goes in")
	r = c.bind_pad("run", JOY_BUTTON_A)
	check(r.done and r.other == "use_tool" and c.pad_button("run") == JOY_BUTTON_A and c.pad_button("use_tool") == JOY_BUTTON_X, "a taken button swaps")
	r = c.bind_pad("quick_load", JOY_BUTTON_B)
	check(r.done and r.other == "interact" and c.pad_button("interact") == Controls.NO_BUTTON, "a swap with an empty slot leaves the other one empty")
	r = c.bind_pad("run", JOY_BUTTON_START)
	check(not r.done and r.reason == "reserved" and r.other == "pause" and c.pad_button("run") == JOY_BUTTON_A, "Start stays on Pause")
	check(not c.bind_pad("run", 99).done, "an unknown button is refused")
	check(c.clear_pad("run") == "" and c.pad_button("run") == Controls.NO_BUTTON and c.clear_pad("run") == "empty", "clearing a pad slot")
	c.apply()
	check(_has_button("quick_save", JOY_BUTTON_LEFT_STICK) and _has_button("use_tool", JOY_BUTTON_X) and not _has_button("use_tool", JOY_BUTTON_A), "pad buttons in the input map")
	check(_has_button("pause", JOY_BUTTON_START) and not _has_button("run", JOY_BUTTON_A), "Start pauses, a cleared button is gone")
	# (event_is_action matches an axis either way, so look at the events themselves.)
	var sticks := []
	for action in ["move_up", "move_down", "move_left", "move_right", "run"]:
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadMotion:
				sticks.append([action, ev.axis, int(ev.axis_value)])
	check(sticks == [["move_up", JOY_AXIS_LEFT_Y, -1], ["move_down", JOY_AXIS_LEFT_Y, 1], ["move_left", JOY_AXIS_LEFT_X, -1], ["move_right", JOY_AXIS_LEFT_X, 1]], "the left stick moves (%s)" % [sticks])

	_remove()
	var s := Settings.make()
	s.controls.pad_bound = c.pad_bound.duplicate()
	check(s.write(PATH) == "", "wrote the pad buttons")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	check(saved.pad.quick_save == "left_stick" and saved.pad.run == "" and saved.pad.use_tool == "x", "pad buttons by id in the file (%s)" % [saved.pad.use_tool])
	var t := Settings.make()
	check(t.read(PATH) == "" and t.controls.pad_bound == c.pad_bound, "pad buttons round trip")
	var broken := {
		"not a dict": [1],
		"a number": {"run": 2},
		"unknown button": {"run": "z"},
		"Start taken": {"run": "start"},
		"shared button": {"run": "a", "use_tool": "a"},
	}
	for what in broken:
		_put(JSON.stringify({"version": 2, "settings": {"hud": false}, "pad": broken[what]}))
		var b := Settings.make()
		b.controls.bind_pad("eat", JOY_BUTTON_GUIDE)
		var kept: Dictionary = b.controls.pad_bound.duplicate()
		var err := b.read(PATH)
		check(err != "" and b.controls.pad_bound == kept and b.value("hud") == true, "broken pad buttons (%s) refused, nothing changed: %s" % [what, err])
	_put(JSON.stringify({"version": 2, "settings": {}, "pad": {"run": "a", "later": "b"}}))
	var part := Settings.make()
	check(part.read(PATH) == "" and part.controls.pad_button("run") == JOY_BUTTON_A and part.controls.pad_button("use_tool") == Controls.NO_BUTTON and part.controls.pad_button("interact") == JOY_BUTTON_B, "missing action: default less buttons taken, unknown skipped")
	_put(JSON.stringify({"version": 1, "settings": {}}))
	check(part.read(PATH) == "" and part.controls.pad_bound == Controls.make().pad_bound, "a file from before the pad: default buttons")
	_remove()
	c.reset()
	check(c.pad_bound == Controls.make().pad_bound, "reset: pad buttons back too")
	c.apply()


## The pad slot on the controls page: listening for a button, keys ignored, Start refused,
## Esc cancels, Delete clears.
func _pad_menu() -> void:
	var s := Settings.make()
	var m := PauseMenu.new(s)
	m.open("controls")
	m.list.point("use_tool")
	m.slot = 2
	check(m.choose() == "" and m.listening_pad() and m.slot_text("use_tool", 2) == "...", "enter on the pad slot: listening")
	check(m.hint().begins_with("Press a pad button for Tool / put down"), "asks for a button (%s)" % m.hint())
	check(m.press(KEY_X) == "" and m.listening_pad(), "a key doesn't go into the pad slot")
	check(m.press_pad(JOY_BUTTON_B) == "controls" and s.controls.pad_button("use_tool") == JOY_BUTTON_B and s.controls.pad_button("interact") == JOY_BUTTON_A, "a pad button goes in, swapped")
	check(m.note == "B was on Talk / throw: swapped." and not m.listening_pad(), "says what was swapped (%s)" % m.note)
	check(m.press_pad(JOY_BUTTON_Y) == "", "a button without listening does nothing")
	m.choose()
	check(m.press_pad(JOY_BUTTON_START) == "" and m.note == "Start stays on Pause." and m.listening == "", "Start is refused and ends the listening")
	m.choose()
	check(m.press(KEY_ESCAPE) == "" and m.listening == "" and s.controls.pad_button("use_tool") == JOY_BUTTON_B, "Esc cancels")
	check(m.clear() == "controls" and s.controls.pad_button("use_tool") == Controls.NO_BUTTON and m.slot_text("use_tool", 2) == "-", "delete clears the pad slot")
	check(m.clear() == "", "an empty pad slot: nothing to clear")
	m.slot = 0
	m.choose()
	check(m.press_pad(JOY_BUTTON_A) == "" and m.listening == "use_tool", "a key slot doesn't take a pad button")
	m.press(KEY_ESCAPE)


## The text speed setting on the text box's runner: x letters per second, 0 = whole lines.
func _text_speed() -> void:
	var counts := []
	for f in [1.0, 2.0, 0.5]:
		var r := DialogueRunner.open("bin_note", {})
		r.set_speed(f)
		r.update(0.1)
		counts.append(r.shown)
	check(counts == [4, 8, 2], "letters in 0.1 s at normal, fast, slow (%s)" % [counts])
	var r := DialogueRunner.open("bin_note", {})
	r.set_speed(0.0)
	check(r.revealed(), "instant: the line is whole at once")
	r.press()
	check(r.done() or r.revealed(), "instant: the next line is whole too")
	r.set_speed(1.0)
	check(not r.instant and r.chars_per_second == 40.0, "back to normal")


## The settings in effect on the real Game: the HUD hides, the farmer runs.
func _settings_in_effect() -> void:
	var g: Node = root.get_node("Game")
	var kept: Dictionary = g.settings.values.duplicate()
	var hud: CanvasLayer = load("res://scripts/ui/hud.gd").new()   # by path: Hud names the Game autoload
	root.add_child(hud)
	g.settings.values.hud = true
	g.apply_settings([])
	check(hud.visible, "HUD shown")
	g.settings.values.hud = false
	g.settings.values.always_run = true
	g.apply_settings([])
	check(not hud.visible and g.always_run, "HUD hidden at once, always run on")
	# The UI size: the HUD's corners grow at once, each box where HudLayout puts it.
	g.settings.values.ui_scale = "150%"
	g.apply_settings([])
	var grown := 0
	for key in hud._placed:
		var box: Control = hud._placed[key]
		grown += int(box.scale == Vector2(1.5, 1.5) and box.position == HudLayout.scaled_box(key, 1.5).position)
	check(grown == HudLayout.BOXES.size(), "UI size 150%%: every HUD box grown and placed (%d of %d)" % [grown, HudLayout.BOXES.size()])
	g.settings.values.ui_scale = "100%"
	g.apply_settings([])
	var back := 0
	for key in hud._placed:
		var box: Control = hud._placed[key]
		back += int(box.scale == Vector2.ONE and box.position == Vector2(HudLayout.BOXES[key].position))
	check(back == HudLayout.BOXES.size(), "UI size 100%%: the HUD as it was (%d of %d)" % [back, HudLayout.BOXES.size()])
	g.settings.values = kept
	g.apply_settings([])
	hud.queue_free()
	# The pause menu shows fewer rows at a bigger UI size, so the box still fits (by path:
	# PauseScreen names the Game autoload too).
	var pause: GDScript = load("res://scripts/ui/pause_screen.gd")
	var k: Dictionary = pause.get_script_constant_map()
	var rows := []
	for wanted in [1.0, 1.25, 1.5]:
		var n: int = pause.visible_rows(wanted, 270)
		var h: float = (k.TOP + 8 + n * k.ROW_H + k.ROW_H + 4) * wanted
		check(h <= 270 and UiScale.fit(wanted, Vector2(k.CONTROLS_WIDTH, h / wanted), Vector2(480, 270)) == wanted, "pause menu at %d%%: %d rows fit (%d px)" % [int(wanted * 100), n, h])
		rows.append(n)
	check(rows[0] == k.VISIBLE and rows[2] < rows[1] and rows[1] < rows[0], "bigger UI, fewer rows (%s)" % [rows])
	_fish_log_fit()
	_shipped_fit()


func _has_button(action: String, button: int) -> bool:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	return InputMap.event_is_action(ev, action, true)


## Triggers and the right stick in a pad slot: names, binding, the input map, the file,
## the menu taking an axis push; the left stick stays the move actions'.
func _pad_axes() -> void:
	var c := Controls.make()
	var rt := Controls.button_of("right_trigger")
	var rs_up := Controls.button_of("rs_up")
	check(Controls.is_axis(rt) and Controls.is_axis(rs_up) and rt != rs_up, "triggers and right-stick directions have pad codes")
	check(c.pad_name(rt) == "RT" and c.pad_name(Controls.button_of("left_trigger")) == "LT" and c.pad_name(rs_up) == "RS-up", "axis names from data")
	var on_axes := c.actions().filter(func(a): return Controls.is_axis(c.pad_button(a)))
	check(on_axes.is_empty(), "no axis on an action by default (%s)" % [on_axes])
	var r := c.bind_pad("quick_save", rt)
	check(r.done and c.pad_button("quick_save") == rt, "the right trigger goes into a pad slot")
	r = c.bind_pad("next_tool", rt)
	check(r.done and r.other == "quick_save" and c.pad_button("quick_save") == JOY_BUTTON_RIGHT_SHOULDER, "an axis swaps like a button")
	check(c.bind_pad("eat", rs_up).done and c.pad_button("eat") == rs_up, "a right-stick direction goes in")
	var ls := Controls.axis_code(JOY_AXIS_LEFT_Y, -1)
	check(not c.bind_pad("run", ls).done and c.pad_button("run") == JOY_BUTTON_X, "the left stick can't be bound")
	check(Controls.motion_code(JOY_AXIS_RIGHT_Y, -0.9) == rs_up and Controls.motion_code(JOY_AXIS_TRIGGER_RIGHT, 1.0) == rt, "a full push is the axis' code")
	check(Controls.motion_code(JOY_AXIS_RIGHT_Y, -0.3) == Controls.NO_BUTTON, "a nudge is nothing")
	c.apply()
	var axes := []
	for action in ["next_tool", "eat"]:
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadMotion:
				axes.append([action, ev.axis, int(ev.axis_value)])
	check(axes == [["next_tool", JOY_AXIS_TRIGGER_RIGHT, 1], ["eat", JOY_AXIS_RIGHT_Y, -1]], "axes in the input map (%s)" % [axes])
	var pull := InputEventJoypadMotion.new()
	pull.axis = JOY_AXIS_TRIGGER_RIGHT
	pull.axis_value = 1.0
	check(InputMap.event_is_action(pull, "next_tool") and not _has_button("next_tool", JOY_BUTTON_RIGHT_SHOULDER), "pulling RT is Next tool, RB no longer")

	_remove()
	var s := Settings.make()
	s.controls.pad_bound = c.pad_bound.duplicate()
	check(s.write(PATH) == "", "wrote the axes")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	check(saved.pad.next_tool == "right_trigger" and saved.pad.eat == "rs_up" and saved.pad.quick_save == "right_shoulder", "axes by id under pad (%s)" % [saved.pad])
	var t := Settings.make()
	check(t.read(PATH) == "" and t.controls.pad_bound == c.pad_bound, "axes round trip")
	_put(JSON.stringify({"version": 2, "settings": {}, "pad": {"run": "ls_up"}}))
	check(Settings.make().read(PATH) != "", "an unknown axis id is refused")
	_remove()

	# The menu: Enter on the pad slot, then a trigger pull.
	var m := PauseMenu.new(Settings.make())
	m.open("controls")
	m.list.point("run")
	m.slot = 2
	m.choose()
	var lt := Controls.motion_code(JOY_AXIS_TRIGGER_LEFT, 0.8)
	check(m.press_pad(lt) == "controls" and m.settings.controls.pad_button("run") == lt and m.slot_text("run", 2) == "LT", "a trigger pull goes into the listening slot")
	c.reset()
	c.apply()


## Window sizes bigger than the screen are left out of the menu; a saved one shows (and is
## used as) the biggest that fits, and stays saved for a bigger screen.
func _window_fit() -> void:
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var options := ["2x", "3x", "4x"]
	var base := Vector2i(480, 270)
	check(game_script.too_big_windows(options, base, Vector2i(1920, 1040)) == ["4x"], "1080p: 4x doesn't fit")
	check(game_script.too_big_windows(options, base, Vector2i(2560, 1400)).is_empty(), "1440p: all fit")
	check(game_script.too_big_windows(options, base, Vector2i(800, 600)) == ["3x", "4x"], "a tiny screen: the smallest option stays")
	var s := Settings.make()
	s.hidden.window = ["4x"]
	s.values.window = "4x"
	check(s.value_text("window") == "3x" and s.option_value("window") == "3x", "a saved 4x shows the real 3x")
	check(not s.adjust("window", 1, false) and s.value("window") == "4x", "right at the biggest that fits: nothing changes")
	check(s.adjust("window", -1, false) and s.value("window") == "2x", "left from the real 3x: 2x")
	check(s.adjust("window", 1) and s.value("window") == "3x" and s.adjust("window", 1) and s.value("window") == "2x", "4x is stepped over")
	s.values.window = "4x"
	var m := PauseMenu.new(s)
	m.open("settings")
	check(m.label("window") == "Window size: 3x", "the menu row (%s)" % m.label("window"))
	s.hidden = {}
	check(s.value_text("window") == "4x", "a bigger screen: 4x again")


## UiScale: pivots keep a box where it was, sizes stop where a piece stops fitting, the HUD's
## corners don't run into each other, the pause menu shows fewer rows to fit.
## The HUD's key hints: what E / Space would do at the spot in front (ActionHints, read-only),
## shown with the player's keys, left out while paused or with the setting off.
func _key_hints() -> void:
	var g: Node = root.get_node("Game")
	var hints: GDScript = load("res://scripts/ui/action_hints.gd")   # by path: it names the Game autoload
	var hud_script: GDScript = load("res://scripts/ui/hud.gd")
	check(hud_script.hint_pairs({"interact": "Talk", "use_tool": "Water"}, "E", "Space") == ["E", "Talk", "Space", "Water"]
		and hud_script.hint_pairs({"interact": "", "use_tool": "Till"}, "E", "Space") == ["Space", "Till"]
		and hud_script.hint_pairs({"interact": "Reel in", "use_tool": "Reel in"}, "E", "Space") == ["E/Space", "Reel in"]
		and hud_script.hint_pairs({"interact": "Talk", "use_tool": ""}, "", "Space").is_empty(), "hint pairs: both, one, shared, no key")
	check(hints.key_text("interact") == "E" and hints.key_text("use_tool") == "Space", "hints use the bound keys (%s, %s)" % [hints.key_text("interact"), hints.key_text("use_tool")])
	g.new_game()
	g.select_tool(0)   # the hoe
	var at := func(origin: Vector2i, facing: Vector2i) -> Dictionary: return hints.pick(origin, facing)
	var bin: Dictionary = at.call(Vector2i(8, 4), Vector2i.UP)
	check(bin.interact == "Ship" and bin.use_tool == "Till", "facing the bin: E Ship, Space Till (%s)" % [bin])
	g.held = "turnip"
	var full: Dictionary = at.call(Vector2i(14, 10), Vector2i.DOWN)
	check(full.interact == "Throw" and full.use_tool == "Put down", "hands full on the farm: throw / put down (%s)" % [full])
	g.held = ""
	var pond := Vector2i(-1, -1)
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			if pond.x < 0 and g.farm.fixed_at(Vector2i(x, y)) == "pond" and g.farm.fixed_at(Vector2i(x, y + 1)) == "":
				pond = Vector2i(x, y + 1)
	g.select_tool(g.TOOLS.find("rod"))
	check(pond.x >= 0 and at.call(pond, Vector2i.UP).use_tool == "Cast" and at.call(pond, Vector2i.DOWN).use_tool == "", "the rod: Cast only at water")
	var door: Vector2i = MapManager.data("town").doors[1].cells[0]   # Tome's door
	g.maps.place("town", door + Vector2i.DOWN, Vector2i.UP)
	var town: Dictionary = at.call(door + Vector2i.DOWN, Vector2i.UP)
	check(town.interact == "Enter" and town.use_tool == "", "a door in the village: E Enter, no tool work off the farm (%s)" % [town])
	g.maps.place("farm", Vector2i(8, 4), Vector2i.UP)
	var hud: CanvasLayer = hud_script.new()
	root.add_child(hud)
	g.select_tool(0)
	hud._show_hints()
	check(hud._hint_box.visible and hud._hint_labels[1].text == "Ship", "the HUD shows the hints")
	g.pause()
	hud._show_hints()
	check(not hud._hint_box.visible, "no hints while a menu is open")
	g.unpause()
	var kept: Dictionary = g.settings.values.duplicate()
	g.settings.values.hints = false
	g.apply_settings([])
	hud._show_hints()
	check(not hud._hint_box.visible and not g.key_hints, "Key hints off: none shown")
	g.settings.values = kept
	g.apply_settings([])
	_last_device(g, hints, hud)
	hud.queue_free()


## The last device used: a pad button or a stick pushed past the deadzone switches the key hints
## to the player's pad buttons, a key or click switches back, drift and mouse movement do not.
func _last_device(g: Node, hints: GDScript, hud: CanvasLayer) -> void:
	var seen: Array = []
	var on_change := func(pad: bool) -> void: seen.append(pad)
	g.input_device_changed.connect(on_change)
	var btn := InputEventJoypadButton.new()
	btn.button_index = JOY_BUTTON_X
	btn.pressed = true
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.pressed = true
	var drift := InputEventJoypadMotion.new()
	drift.axis = JOY_AXIS_LEFT_X
	drift.axis_value = 0.1
	var push := InputEventJoypadMotion.new()
	push.axis = JOY_AXIS_LEFT_X
	push.axis_value = 0.9
	var move := InputEventMouseMotion.new()
	check(not g.pad_active, "the keyboard is the device at first")
	g.note_input(drift)
	check(not g.pad_active and seen.is_empty(), "stick drift under the deadzone does not switch")
	g.note_input(btn)
	check(g.pad_active and seen == [true], "a pad button switches to the pad (%s)" % [seen])
	g.note_input(btn)
	check(seen == [true], "the same device again changes nothing")
	g.note_input(move)
	g.note_input(drift)
	check(g.pad_active and seen == [true], "mouse movement and drift keep the pad")
	g.note_input(key)
	check(not g.pad_active and seen == [true, false], "a key switches back to the keyboard")
	g.note_input(push)
	check(g.pad_active, "a stick pushed past the deadzone switches to the pad")
	check(hints.key_text("interact") == "B" and hints.key_text("use_tool") == "A",
		"pad hints show the pad buttons (%s, %s)" % [hints.key_text("interact"), hints.key_text("use_tool")])
	g.maps.place("farm", Vector2i(8, 4), Vector2i.UP)
	g.select_tool(0)
	hud._show_hints()
	check(hud._hint_labels[0].text == "B" and hud._hint_labels[2].text == "A", "the HUD shows B and A for the pad (%s, %s)" % [hud._hint_labels[0].text, hud._hint_labels[2].text])
	var c: Controls = g.settings.controls
	check(c.bind_pad("interact", JOY_BUTTON_Y).done, "rebinding interact to Y")
	hud._show_hints()
	check(hud._hint_labels[0].text == "Y" and hints.key_text("interact") == "Y", "after remapping the hint shows Y (%s)" % hud._hint_labels[0].text)
	c.clear_pad("interact")
	check(hints.key_text("interact") == "E", "an action without a pad button shows its key")
	g.note_input(key)
	hud._show_hints()
	check(hud._hint_labels[0].text == "E" and hints.key_text("use_tool") == "Space", "the keyboard shows keys again (%s)" % hud._hint_labels[0].text)
	c.reset()
	g.input_device_changed.disconnect(on_change)
	_pad_style(g, hints, hud)


## PlayStation names: detection from a pad's name / guid, Auto following the pad last used, the
## Pad buttons setting overriding it, and the HUD label and the controls page with each style.
func _pad_style(g: Node, hints: GDScript, hud: CanvasLayer) -> void:
	check(Controls.style_of("PS5 Controller", "") == "playstation" and Controls.style_of("DualSense Wireless Controller", "") == "playstation"
		and Controls.style_of("Sony DualShock 4", "") == "playstation" and Controls.style_of("PS4 Controller", "") == "playstation", "Sony pads are found by name")
	check(Controls.style_of("Wireless Controller", "030000004c050000cc09000000000000") == "playstation", "a Sony pad is found by the vendor id in its guid")
	check(Controls.style_of("Xbox 360 Controller", "030000005e0400008e02000000000000") == "xbox" and Controls.style_of("", "") == "xbox"
		and Controls.style_of("Nintendo Switch Pro Controller", "03000000057e00000920000000000000") == "xbox", "other pads and no name stay Xbox style")
	var c: Controls = g.settings.controls
	check(c.pad_name(JOY_BUTTON_A, "playstation") == "Cross" and c.pad_name(JOY_BUTTON_B, "playstation") == "Circle"
		and c.pad_name(JOY_BUTTON_X, "playstation") == "Square" and c.pad_name(JOY_BUTTON_Y, "playstation") == "Triangle"
		and c.pad_name(JOY_BUTTON_LEFT_SHOULDER, "playstation") == "L1" and c.pad_name(JOY_BUTTON_RIGHT_SHOULDER, "playstation") == "R1"
		and c.pad_name(JOY_BUTTON_START, "playstation") == "Options" and c.pad_name(Controls.button_of("left_trigger"), "playstation") == "L2"
		and c.pad_name(Controls.button_of("right_trigger"), "playstation") == "R2", "PlayStation names from data")
	check(c.pad_name(JOY_BUTTON_A) == "A" and c.pad_name(JOY_BUTTON_A, "xbox") == "A", "Xbox names stay the default")
	var ok := true
	for b in c.pad_names:
		ok = ok and c.pad_names_ps.has(b) and c.pad_name(b, "playstation") != "-"
	check(ok, "every pad input has a PlayStation name")
	g.joy_lookup = func(device: int) -> Array: return ["PS5 Controller", ""] if device == 1 else ["Xbox Controller", ""]
	var press := func(device: int) -> InputEventJoypadButton:
		var e := InputEventJoypadButton.new()
		e.button_index = JOY_BUTTON_X
		e.pressed = true
		e.device = device
		return e
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.pressed = true
	g.settings.values.pad_style = "auto"
	g.apply_settings()
	g.note_input(key)
	g.pad_device = -1
	g.note_input(press.call(0))
	check(g.pad_style() == "xbox" and hints.key_text("interact") == "B", "Auto: an Xbox pad shows B (%s)" % hints.key_text("interact"))
	g.maps.place("farm", Vector2i(8, 4), Vector2i.UP)
	g.select_tool(0)
	g.note_input(press.call(1))
	hud._show_hints()
	check(g.pad_style() == "playstation" and hints.key_text("interact") == "Circle" and hints.key_text("use_tool") == "Cross",
		"Auto: a PlayStation pad shows Circle and Cross (%s, %s)" % [hints.key_text("interact"), hints.key_text("use_tool")])
	check(hud._hint_labels[0].text == "Circle" and hud._hint_labels[2].text == "Cross", "the HUD label says Circle and Cross (%s, %s)" % [hud._hint_labels[0].text, hud._hint_labels[2].text])
	g.note_input(press.call(0))
	hud._show_hints()
	check(hud._hint_labels[0].text == "B", "switching to the Xbox pad redraws with B (%s)" % hud._hint_labels[0].text)
	g.settings.values.pad_style = "playstation"
	g.apply_settings()
	hud._show_hints()
	check(g.pad_style() == "playstation" and hud._hint_labels[0].text == "Circle", "the setting PlayStation wins over an Xbox pad (%s)" % hud._hint_labels[0].text)
	g.note_input(press.call(1))
	g.settings.values.pad_style = "xbox"
	g.apply_settings()
	hud._show_hints()
	check(g.pad_style() == "xbox" and hud._hint_labels[0].text == "B", "the setting Xbox wins over a PlayStation pad (%s)" % hud._hint_labels[0].text)
	g.settings.values.pad_style = "playstation"
	g.apply_settings()
	var menu := PauseMenu.new(g.settings)
	menu.page = "controls"
	var ps_ok := menu.slot_text("interact", g.settings.controls.slots) == "Circle"
	g.settings.values.pad_style = "xbox"
	g.apply_settings()
	check(ps_ok and menu.slot_text("interact", g.settings.controls.slots) == "B", "the controls page names the pad slot in the chosen style")
	g.settings.values.pad_style = "auto"
	g.apply_settings()
	var saved := Settings.make()
	saved.values.pad_style = "playstation"
	check(saved.write(PATH) == "", "settings written")
	var loaded := Settings.make()
	check(loaded.read(PATH) == "" and loaded.value("pad_style") == "playstation", "the Pad buttons setting is saved")
	loaded.reset()
	check(loaded.value("pad_style") == "auto", "reset puts the Pad buttons setting back to Auto")
	_remove()
	g.joy_lookup = Callable()
	g.pad_device = -1
	g.note_input(key)


func _ui_scale() -> void:
	var screen := Vector2(480, 270)
	check(UiScale.pivot(Rect2(165, 85, 150, 100), screen) == Vector2(240, 135), "a box in the middle grows from the middle")
	var placed := UiScale.placed(Rect2(165, 85, 150, 100), 1.5, screen)
	check(placed.size == Vector2(225, 150) and placed.get_center().distance_to(Vector2(240, 135)) < 1.0, "a centred box stays centred (%s)" % [placed])
	check(UiScale.fit(1.5, Vector2(472, 62), screen) == 1.0, "the full-width text box has no room to grow")
	check(UiScale.fit(1.5, Vector2(300, 200), screen) == 1.25 and UiScale.fit(1.25, Vector2(150, 94), screen) == 1.25, "a size that doesn't fit drops a step")
	check(UiScale.fit(0.5, Vector2(10, 10), screen) == 1.0, "never below 100%")
	for wanted in [1.0, 1.25, 1.5]:
		var rects := {}
		var inside := true
		for key in HudLayout.BOXES:
			if key == "message":
				continue   # it grows with its text; checked below by its corner
			rects[key] = HudLayout.scaled_box(key, wanted)
			inside = inside and Rect2(Vector2.ZERO, screen).encloses(rects[key])
		var clash := []
		for a in rects:
			for b in rects:
				if a < b and HudLayout.GROUPS[a] != HudLayout.GROUPS[b] and rects[a].intersects(rects[b]):
					clash.append([a, b])
		check(inside and clash.is_empty(), "HUD at %d%%: on screen, corners apart (%s)" % [int(wanted * 100), clash])
		var msg := HudLayout.scaled_box("message", wanted)
		check(msg.position.x >= 0 and msg.position.y >= 0 and msg.position.x < 8 and msg.position.y < 8, "the message box keeps its corner at %d%%" % int(wanted * 100))
	check(HudLayout.scaled_box("clock", 1.0) == Rect2(HudLayout.BOXES.clock), "100%: the HUD as laid out")


## The language setting (data/settings.json) and the Thai tables (data/lang/th): text on
## screen switches with it, missing text stays English, every Thai line can be drawn and
## every dialogue line still fits the text box.
# Every screen takes its panels and colours from UiStyle (the washi paper and dark wood look).
func _shared_style() -> void:
	var dir := DirAccess.open("res://scripts/ui")
	var own := 0
	for f in dir.get_files():
		if not f.ends_with(".gd") or f == "ui_style.gd":
			continue
		var src := FileAccess.get_file_as_string("res://scripts/ui/" + f)
		check(not src.contains("NinePatchRect.new()"), "%s builds no panel of its own" % f)
		check(not src.contains('"ui:frame:'), "%s takes no frame art by hand" % f)
		if src.contains("UiStyle.panel("):
			own += 1
	check(own >= 9, "the HUD and the screens build panels through UiStyle (%d files)" % own)
	for kind in ["paper", "wood"]:
		var b := UiStyle.panel(null, kind)
		check(b.texture == PlaceholderArt.tex("ui:frame:" + kind), "%s panel uses its frame art" % kind)
		check(b.patch_margin_left == 4 and b.patch_margin_bottom == 4, "%s panel keeps a 4 px border" % kind)
		check(b.axis_stretch_horizontal == NinePatchRect.AXIS_STRETCH_MODE_TILE, "%s panel tiles its centre" % kind)
		b.free()
	var hud: GDScript = load("res://scripts/ui/hud.gd")
	var pause: GDScript = load("res://scripts/ui/pause_screen.gd")
	var shop: GDScript = load("res://scripts/ui/shop_screen.gd")
	check(hud.INK == UiStyle.INK and hud.INK_SOFT == UiStyle.INK_SOFT and hud.NINE_MARGIN == UiStyle.NINE_MARGIN, "the HUD ink is the shared ink")
	check(pause.PAPER == UiStyle.PAPER_TEXT and shop.PAPER == UiStyle.PAPER_TEXT, "screen title text is the shared paper colour")
	# The paper tile wraps: nothing in its centre differs from the page tone by more than fibre.
	var img := PlaceholderArt.tex("ui:frame:paper").get_image()
	var ok := true
	for y in range(4, 28):
		for x in range(4, 28):
			ok = ok and img.get_pixel(x, y).v > 0.8
	check(ok, "the washi centre stays light and even")
	var wood := PlaceholderArt.tex("ui:frame:wood").get_image()
	check(wood.get_pixel(1, 16).v < 0.65 and wood.get_pixel(0, 16).v < 0.3, "the frame border is dark wood")


func _language() -> void:
	var s := Settings.make()
	check(s.value("language") == "en" and s.spec.language.options == ["en", "th"], "language: English by default, Thai offered")
	check(s.adjust("language", 1) and s.value("language") == "th" and s.value_text("language") == "ไทย", "language: Thai, shown in Thai")
	var m := PauseMenu.new(s)
	m.open("settings")
	check(m.label("language") == "Language: ไทย", "the language row (%s)" % m.label("language"))
	check(Lang.languages().has("th"), "data/lang/th is a language")
	check(Lang.t("Settings") == "Settings", "English: text as it is")
	Lang.set_language("th")
	check(Lang.current == "th" and TranslationServer.get_locale() == "th", "Thai is on (%s)" % TranslationServer.get_locale())
	check(Lang.t("Settings") == PixelFont.shape("ตั้งค่า"), "a word in Thai (%s)" % Lang.t("Settings"))
	check(TranslationServer.translate("Settings") == Lang.t("Settings"), "Labels get the same Thai through the TranslationServer")
	check(Lang.t("Language: ไทย") == PixelFont.shape("ภาษา: ไทย"), "a settings row by its pattern (%s)" % Lang.t("Language: ไทย"))
	check(Lang.t("Bought Turnip seeds for 40 G.") == PixelFont.shape("ซื้อเมล็ดเทอร์นิป ราคา 40 G"), "a message: pattern, a name in it, the number kept (%s)" % Lang.t("Bought Turnip seeds for 40 G."))
	check(Lang.t("Spring 3, Year 2") == PixelFont.shape("ใบไม้ผลิ 3 ปี 2"), "the date, parts put back by number (%s)" % Lang.t("Spring 3, Year 2"))
	check(Lang.t("Made grilled fish x2.") == PixelFont.shape("ทำ ปลาย่าง เสร็จแล้ว x2"), "a name lowered in a sentence is still found (%s)" % Lang.t("Made grilled fish x2."))
	check(Lang.t("Resume\nBack") == PixelFont.shape("เล่นต่อ\nกลับ"), "lines looked up one by one")
	check(Lang.t("Nothing in the tables says this") == "Nothing in the tables says this", "missing text stays English")
	check(PixelFont.shown_width("Settings") == PixelFont.width(PixelFont.shape("ตั้งค่า")), "widths measure the Thai")
	# Thai marks: tone marks over a vowel above sit higher; over ป they move left; ำ splits.
	var shaped := PixelFont.shape("ที่ ป้า น้ำ")
	check(shaped.unicode_at(2) == PixelFont.mark_point("่", 1), "a tone mark over ี goes high")
	check(shaped.unicode_at(5) == PixelFont.mark_point("้", 2), "a tone mark over ป moves left")
	check(shaped.unicode_at(9) == PixelFont.mark_point("้", 1) and shaped.unicode_at(10) == PixelFont.mark_point("ํ", 0) and shaped.substr(11) == "า", "น้ำ: the tone goes over the ring, ำ becomes ring and า (%s)" % [shaped.to_utf32_buffer()])
	check(PixelFont.shape(shaped) == shaped and PixelFont.width("ที่") == PixelFont.width("ท"), "shaping twice changes nothing; marks take no room")
	# Every Thai entry: placeholders kept, drawable; dialogue lines fit the box and exist.
	var table := Lang.table("th")
	var bad := []
	var holes := RegEx.create_from_string("%0?\\d?[sd]|\\{\\d\\}")
	for k in table:
		var v := String(table[k])
		if PixelFont.missing(v.replace("{1}", "").replace("{2}", "").replace("{3}", "")) != "":
			bad.append("%s: can't draw %s" % [k, PixelFont.missing(v)])
		if holes.search_all(String(k)).size() != holes.search_all(v).size():
			bad.append("%s: parts don't match" % k)
	check(bad.is_empty(), "every Thai entry has its parts and every glyph (%s)" % [bad])
	var lines := {}
	for file in DirAccess.get_files_at("res://data/dialogue/"):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/" + file))
		if d is Dictionary and d.get("lines") is Array:
			for l in d.lines:
				if l is Dictionary and l.has("text"):
					lines[l.text] = "line"
					for c in l.get("choices", []):
						lines[c.text] = "choice"
	var dlg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/lang/th/dialogue.json")).text
	var stale := []
	var long := []
	var done := 0
	for k in dlg:
		if k.begins_with("_") or "%" in k:
			continue
		if not lines.has(k):
			stale.append(k)
			continue
		done += 1
		var th := Lang.t(k)
		if lines[k] == "choice" and PixelFont.width(th) > TextBoxLayout.CHOICE_TEXT_W:
			long.append(k)
		if lines[k] == "line" and TextBoxLayout.wrap_rows(th, TextBoxLayout.text_w(true)).size() > TextBoxLayout.ROWS:
			long.append(k)
	check(stale.is_empty(), "every Thai dialogue key is a line in data/dialogue (%s)" % [stale])
	check(long.is_empty() and done > 50, "%d Thai dialogue lines fit the text box (%s)" % [done, long])
	var settings_text := []
	for key in s.spec:
		settings_text.append(s.spec[key].label)
	for label in settings_text:
		check(Lang.has(label), "the setting %s has its Thai" % label)
	Lang.set_language("en")
	check(Lang.t("Settings") == "Settings" and TranslationServer.get_locale() == "en", "back to English")
