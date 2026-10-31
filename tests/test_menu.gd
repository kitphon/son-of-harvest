extends SceneTree
## Headless pause menu checks (Game's pause rule, Settings, PauseMenu, MenuList). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_menu.gd

const PATH := "user://test_settings.json"

var failures := 0
var _frame := 0
var _p: Node2D            # the farmer checked over a few frames
var _start := Vector2.ZERO
var _swings := [0]


func _init() -> void:
	_pause_rule()
	_settings()
	_pause_menu()
	_controls()
	_controls_menu()


# The farmer is checked on the Game autoload, which is in the tree from the first frame,
# over a few frames so a key press and its release don't fall in the same one.
func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_volumes_in_effect()
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
	g.free()


## Settings: defaults from data, changing them, a round trip, and refusing broken files.
func _settings() -> void:
	var s := Settings.make()
	check(s.keys() == (["flashes", "window", "music", "sfx", "ambient"] as Array[String]), "settings in data order (%s)" % [s.keys()])
	check(s.value("flashes") == true and s.value("window") == "3x", "defaults")
	check(s.value_text("flashes") == "On" and s.value_text("window") == "3x", "value text")
	check(s.adjust("flashes", 1) and s.value("flashes") == false and s.value_text("flashes") == "Off", "flashes flip")
	check(s.adjust("window", 1) and s.value("window") == "4x", "window: next size")
	check(s.adjust("window", 1) and s.value_text("window") == "Full screen", "window: full screen")
	check(s.adjust("window", 1) and s.value("window") == "2x", "window wraps round")
	check(not s.adjust("window", -1, false) and s.value("window") == "2x", "no wrap: stops at the first")

	_remove()
	check(s.read(PATH) == "" and s.value("flashes") == false, "no file: nothing changes")
	check(s.write(PATH) == "", "wrote the settings")
	var t := Settings.make()
	check(t.read(PATH) == "" and t.values == s.values, "round trip (%s)" % [t.values])

	var good := {"version": 1, "settings": {"flashes": false, "window": "full"}}
	var broken := {
		"empty": "",
		"not json": "{ flashes: off",
		"a list": "[1, 2]",
		"no version": JSON.stringify({"settings": good.settings}),
		"newer version": JSON.stringify({"version": 2, "settings": good.settings}),
		"no settings": JSON.stringify({"version": 1}),
		"flashes as text": JSON.stringify({"version": 1, "settings": {"flashes": "yes"}}),
		"unknown window": JSON.stringify({"version": 1, "settings": {"window": "8x"}}),
		"window as number": JSON.stringify({"version": 1, "settings": {"window": 3}}),
		"music too loud": JSON.stringify({"version": 1, "settings": {"music": 150}}),
		"sfx below 0": JSON.stringify({"version": 1, "settings": {"sfx": -10}}),
		"ambient as text": JSON.stringify({"version": 1, "settings": {"ambient": "loud"}}),
		"music in pieces": JSON.stringify({"version": 1, "settings": {"music": 45.5}}),
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
	check(m.page == "main" and m.list.items == (["resume", "save", "settings", "title"] as Array[String]), "main page")
	check(m.heading() == "Paused" and m.list.current() == "resume", "cursor on resume")
	check(m.choose() == "resume", "resume closes the menu")
	check(m.back() == "resume", "Esc on the main page closes it")
	m.list.move(1)
	check(m.choose() == "save" and m.page == "main", "save stays on the page")
	m.list.move(1)
	check(m.choose() == "" and m.page == "settings", "settings opens its page")
	check(m.list.items == (["flashes", "window", "music", "sfx", "ambient", "controls", "back"] as Array[String]), "settings rows from data, then controls and back")
	check(m.slider("flashes") == Vector2i.ZERO and m.slider("back") == Vector2i.ZERO, "no slider on on / off rows")
	check(m.label("flashes") == "Lightning: On" and m.label("window") == "Window: 3x", "rows show values")
	check(m.choose() == "setting" and s.value("flashes") == false and m.label("flashes") == "Lightning: Off", "enter flips flashes")
	check(m.adjust(1) == "setting" and s.value("flashes") == true, "right flips it back")
	m.list.move(1)
	check(m.adjust(1) == "setting" and s.value("window") == "4x", "right: bigger window")
	check(m.adjust(1) == "setting" and m.label("window") == "Window: Full screen", "right: full screen")
	check(m.adjust(1) == "" and s.value("window") == "full", "right at the end does nothing")
	check(m.adjust(-1) == "setting" and s.value("window") == "4x", "left: back a size")
	m.list.move(1)
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
	m.list.move(2)
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
	check(m.adjust(1) == "" and m.slot == 1 and m.adjust(1) == "" and m.slot == 1, "right: second slot, stops there")
	m.choose()
	check(m.press(KEY_I) == "controls" and s.controls.keys("move_up") == [KEY_W, KEY_I] and s.controls.keys("rucksack") == [KEY_UP, KEY_NONE], "a taken key swaps")
	check(m.note == "I was on Rucksack: swapped" and m.hint() == m.note, "says what was swapped (%s)" % m.note)
	m.choose()
	check(m.press(KEY_ESCAPE) == "" and m.note == "", "Esc while listening cancels quietly")
	m.adjust(-1)
	m.choose()
	check(m.back() == "" and m.page == "controls" and m.listening == "", "Esc (back) while listening stays on the page")
	m.list.point("next_tool")
	m.adjust(1)
	m.choose()
	check(m.press(KEY_Q) == "" and m.note == "Q is the only key for Next seed / food", "refused swap says why (%s)" % m.note)
	m.choose()
	check(m.press(KEY_ESCAPE) == "" and s.controls.keys("next_tool") == [KEY_TAB, KEY_NONE], "nothing changed")
	m.list.point("use_tool")
	m.slot = 1
	check(m.clear() == "controls" and s.controls.keys("use_tool") == [KEY_SPACE, KEY_NONE], "delete clears the slot")
	m.slot = 0
	check(m.clear() == "" and m.note == "Tool / put down needs a key", "never the last key")
	m.list.point("reset")
	check(m.choose() == "controls" and s.controls.bound == Controls.make().bound and m.note == "Keys back to the defaults", "reset to defaults")
	m.list.point("back")
	check(m.choose() == "" and m.page == "settings" and m.list.current() == "controls", "back: settings, cursor on controls")
	m.open("controls")
	check(m.back() == "" and m.page == "settings" and m.list.current() == "controls", "Esc on controls goes back one page")
	m.open("controls")
	m.list.point("quick_save")
	m.choose()
	m.press(KEY_BACKSPACE)
	check(s.controls.keys("quick_save") == [KEY_BACKSPACE, KEY_NONE], "any other key can be bound, Backspace too")
	check(m.clear() == "" and m.note == "Quick save needs a key", "and clearing it is refused")


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
