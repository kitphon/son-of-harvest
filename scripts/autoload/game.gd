extends Node
## Global game state: clock, calendar, weather, money, stamina, tools and the bag.
## Rules follow the design doc; every number here is ours to tune.

signal minute_passed
signal day_started
signal changed                  # anything the HUD shows
signal message(text: String)
signal dialogue_requested(id: String, at: String)   # a TextBox opens it
signal settings_changed

const SECONDS_PER_MINUTE := 0.5
const DAYS_PER_SEASON := 30
const SEASONS: Array[String] = ["spring", "summer", "fall", "winter"]
const PAYOUT_HOUR := 18
const PASS_OUT_HOUR := 2
const WATER_MAX := 40
const TOOLS: Array[String] = ["hoe", "can", "sickle", "hammer", "axe", "seeds"]
const SEED_COST := 1            # stamina per seed bag; the other tools cost by charge (data/tools.json)

var year := 1
var season := 0
var day := 1
var hour := 6
var minute := 0
var weather_today := "sunny"
var weather_tomorrow := "sunny"
var snow_cover := 0             # snow lying on the ground, 0 (none) .. 100 (all white)
var flashes_enabled := true     # lightning flashes in storms; off for photosensitive players
var clock_running := true      # off on the title screen
var dialogue_open := false      # a text box is up: the clock and the farmer wait (counts as paused)
var settings: Settings          # the player's settings (user://settings.json), not saved with the run
var _pauses := 0                # open menus; while any is open time stands still

var money := 500
var bin_total := 0
var stamina := 100
var max_stamina := 100
var water := WATER_MAX
var tool_index := 0
var seed_index := 0
var bag: Dictionary = {}        # item id -> count; seeds are "seeds:<crop>"
var tool_levels: Dictionary = {}   # tool -> level 1..5 (charging tools in data/tools.json)
var flags: Dictionary = {}      # story flags set by dialogue (bool, whole number or word)

var crops: Dictionary = {}
var weather_chances: Dictionary = {}
var weather_fx: Dictionary = {}    # look per weather: tint, falling particles, lightning
var tools_data: Dictionary = {}    # data/tools.json: charge steps per tool
var snow_rules: Dictionary = {}    # how snow builds up and melts (data/snow_cover.json)
var rng := RandomNumberGenerator.new()
var farm: FarmGrid
var _accum := 0.0


func _ready() -> void:
	rng.randomize()
	crops = _load_json("res://data/crops.json")
	weather_chances = _load_json("res://data/weather.json")
	weather_fx = _load_json("res://data/weather_fx.json")
	tools_data = _load_json("res://data/tools.json")
	snow_rules = _load_json("res://data/snow_cover.json")
	_setup_input()
	settings = Settings.make()
	var err := settings.read()
	if err != "":
		push_warning(err + "; using the default settings")
	apply_settings()
	new_game()


## A fresh run: every value back to the start and a newly laid-out farm, so nothing from an
## earlier game in the same session is left over. New run state belongs in this list too.
func new_game() -> void:
	year = 1
	season = 0
	day = 1
	hour = 6
	minute = 0
	weather_today = "sunny"
	money = 500
	bin_total = 0
	max_stamina = 100
	stamina = max_stamina
	water = WATER_MAX
	snow_cover = 0
	tool_index = 0
	seed_index = 0
	_accum = 0.0
	farm = FarmGrid.new(crops)
	farm.generate(rng)
	bag = {"seeds:turnip": 2, "seeds:potato": 1}
	reset_tool_levels()
	flags = {}
	weather_tomorrow = roll_weather(_tomorrow_season())
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo":
			_demo_field()
		elif arg.begins_with("--weather="):   # e.g. `-- --demo --weather=storm` for screenshots
			weather_today = arg.trim_prefix("--weather=")
			snow_cover = next_snow_cover(0, weather_look(weather_today, season_name()), season_name(), snow_rules)


## `-- --demo`: 10:00 with a few sown, growing and ripe plots by the house, for screenshots.
func _demo_field() -> void:
	hour = 10
	for y in range(5, 8):
		for x in range(2, 11):
			var c := Vector2i(x, y)
			farm.cell(c).obj = FarmGrid.Obj.NONE
			farm.till(c)
	farm.sow(Vector2i(3, 6), "turnip", "spring")
	farm.sow(Vector2i(6, 6), "potato", "spring")
	farm.sow(Vector2i(9, 6), "cucumber", "spring")
	for y in range(5, 8):
		for x in range(2, 11):
			var d := farm.cell(Vector2i(x, y))
			d.stage = (x - 2) / 3 + 1
			d.wet = x % 2 == 0
	farm.cell(Vector2i(5, 8)).obj = FarmGrid.Obj.ROCK
	farm.cell(Vector2i(7, 8)).obj = FarmGrid.Obj.STUMP
	farm.cell(Vector2i(9, 8)).obj = FarmGrid.Obj.WEED
	farm.cells_changed.emit()


func _process(delta: float) -> void:
	if not ticking():
		return
	_accum += delta
	while _accum >= SECONDS_PER_MINUTE:
		_accum -= SECONDS_PER_MINUTE
		_tick_minute()


func _tick_minute() -> void:
	minute += 1
	if minute == 60:
		minute = 0
		hour = (hour + 1) % 24
		if hour == PAYOUT_HOUR:
			pay_bin()
		elif hour == PASS_OUT_HOUR:
			pass_out()
	minute_passed.emit()
	changed.emit()


# --- pausing ----------------------------------------------------------------

## A menu opens: the clock stops and the farmer stands still until every menu is closed.
## Menus nest (a menu on top of another), so each open is one count and each close one less.
func pause() -> void:
	_pauses += 1


func unpause() -> void:
	_pauses = maxi(_pauses - 1, 0)


func paused() -> bool:
	return _pauses > 0 or dialogue_open


## Does time pass now (not on the title screen, no menu open)?
func ticking() -> bool:
	return clock_running and not paused()


# --- settings ---------------------------------------------------------------

## Puts the settings into effect. `-- --no-flashes` always wins over the file.
func apply_settings(args := OS.get_cmdline_user_args()) -> void:
	if settings == null:
		return
	flashes_enabled = bool(settings.value("flashes")) and not "--no-flashes" in args
	_apply_window(str(settings.value("window")))
	settings_changed.emit()


## Window size as a whole multiple of the 480 x 270 picture, or full screen.
func _apply_window(mode: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if mode == "full":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	var n := maxi(mode.trim_suffix("x").to_int(), 1)
	var base := Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var size := base * n
	if DisplayServer.window_get_size() == size:
		return
	var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)


# --- calendar and weather ---------------------------------------------------

func season_name() -> String:
	return SEASONS[season]


func date_text() -> String:
	return "%s %d, Year %d" % [season_name().capitalize(), day, year]


func time_text() -> String:
	return "%02d:%02d" % [hour, minute]


## Day / night light: minute of the day -> colour, linear in between, times the weather tint.
const LIGHT := [
	[0, Color(0.42, 0.45, 0.72)], [300, Color(0.42, 0.45, 0.72)], [420, Color.WHITE],
	[960, Color.WHITE], [1080, Color(1.0, 0.8, 0.65)], [1200, Color(0.42, 0.45, 0.72)],
	[1440, Color(0.42, 0.45, 0.72)],
]


func light_color() -> Color:
	var m := hour * 60 + minute
	var c := Color.WHITE
	for i in range(1, LIGHT.size()):
		if m <= LIGHT[i][0]:
			var a: Array = LIGHT[i - 1]
			var b: Array = LIGHT[i]
			c = a[1].lerp(b[1], float(m - a[0]) / float(b[0] - a[0]))
			break
	return c * Color(weather_style().get("tint", "ffffff"))


## Which look today's weather has: a storm in winter is a blizzard (snow, not rain).
static func weather_look(weather: String, season_id: String) -> String:
	return "blizzard" if weather == "storm" and season_id == "winter" else weather


func weather_style() -> Dictionary:
	return weather_fx.get(weather_look(weather_today, season_name()), {})


## Lightning for today's look ({} when there is none, or flashes are turned off).
func lightning_style() -> Dictionary:
	return weather_style().get("lightning", {}) if flashes_enabled else {}


## Snow on the ground the morning after: a snowfall adds to it (a blizzard covers everything),
## any other day melts some, a lot outside winter, and rain washes more away. So snow lies
## from the first snowfall through winter, thins over clear days and is gone on spring 1.
static func next_snow_cover(cover: int, look: String, season_id: String, rules: Dictionary) -> int:
	var fall := int(rules.get("fall", {}).get(look, 0))
	if fall > 0:
		return mini(cover + fall, 100)
	var melt := int(rules.get("melt_per_day", {}).get(season_id, 100))
	if look == "rain" or look == "storm":
		melt += int(rules.get("rain_melt", 0))
	return maxi(cover - melt, 0)


func _tomorrow_season() -> int:
	return season if day < DAYS_PER_SEASON else (season + 1) % 4


func roll_weather(season_idx: int) -> String:
	var r := rng.randf()
	var table: Dictionary = weather_chances.get(SEASONS[season_idx], {})
	for kind in table:
		r -= float(table[kind])
		if r < 0.0:
			return kind
	return "sunny"


## Sleep before midnight: full stamina. After midnight: three quarters.
func sleep() -> void:
	var late := hour < 6
	end_day()
	stamina = max_stamina * 3 / 4 if late else max_stamina
	# Sleeping saves the game (the morning after), like writing in a diary.
	var err := SaveGame.write(self)
	message.emit("Good morning! Game saved." if err == "" else "Good morning! " + err)
	changed.emit()


## Still awake at PASS_OUT_HOUR: wake at home with half stamina.
func pass_out() -> void:
	end_day()
	stamina = max_stamina / 2
	message.emit("You passed out from exhaustion...")
	changed.emit()


func end_day() -> void:
	pay_bin()
	day += 1
	if day > DAYS_PER_SEASON:
		day = 1
		season = (season + 1) % 4
		if season == 0:
			year += 1
	weather_today = weather_tomorrow
	weather_tomorrow = roll_weather(_tomorrow_season())
	snow_cover = next_snow_cover(snow_cover, weather_look(weather_today, season_name()), season_name(), snow_rules)
	farm.day_end(season_name(), weather_today, rng)
	hour = 6
	minute = 0
	_accum = 0.0
	day_started.emit()
	changed.emit()


# --- money, bag, stamina ----------------------------------------------------

func pay_bin() -> void:
	if bin_total <= 0:
		return
	money += bin_total
	message.emit("Shipping paid %d G" % bin_total)
	bin_total = 0
	changed.emit()


## Puts every crop in the bag into the shipping bin; returns the value added.
func ship_produce() -> int:
	var total := 0
	for id in bag.keys():
		if crops.has(id):
			total += int(crops[id].sell) * int(bag[id])
			bag.erase(id)
	bin_total += total
	changed.emit()
	return total


func count(id: String) -> int:
	return int(bag.get(id, 0))


func add_item(id: String, n := 1) -> void:
	bag[id] = count(id) + n
	changed.emit()


func take_item(id: String, n := 1) -> bool:
	if count(id) < n:
		return false
	bag[id] = count(id) - n
	if bag[id] == 0:
		bag.erase(id)
	changed.emit()
	return true


func spend_stamina(n: int) -> bool:
	if stamina < n:
		message.emit("Too tired. Go to bed.")
		return false
	stamina -= n
	changed.emit()
	return true


# --- tool levels and charging ----------------------------------------------

## Every charging tool back to level 1 (a new game).
func reset_tool_levels() -> void:
	tool_levels = {}
	for tool in tools_data.get("tools", {}):
		tool_levels[tool] = 1


## How many levels a tool has (0 for one that doesn't charge, like the seed bag).
func tool_max_level(tool: String) -> int:
	return tools_data.get("tools", {}).get(tool, {}).get("max_charge", []).size()


func tool_level(tool: String) -> int:
	return clampi(int(tool_levels.get(tool, 1)), 1, maxi(tool_max_level(tool), 1))


## The highest charge step the tool's level allows (0 = taps only).
func max_charge(tool: String) -> int:
	if tool_max_level(tool) == 0:
		return 0
	return int(tools_data.tools[tool].max_charge[tool_level(tool) - 1])


## Charge steps reached after holding the button for `seconds`.
func charge_after(tool: String, seconds: float) -> int:
	var step := float(tools_data.get("charge_seconds", 0.6))
	return mini(int(seconds / step), max_charge(tool))


## One charge step's rule: {area, stamina, hits?}. The charge is kept within the tool level.
func charge_rule(tool: String, charge: int) -> Dictionary:
	return tools_data.tools[tool].charges[clampi(charge, 0, max_charge(tool))]


func current_tool() -> String:
	return TOOLS[tool_index]


func current_seed() -> String:
	return crops.keys()[seed_index]


func cycle_seed() -> void:
	seed_index = (seed_index + 1) % crops.size()
	changed.emit()


func select_tool(i: int) -> void:
	tool_index = posmod(i, TOOLS.size())
	changed.emit()


## Opens dialogue `id` (data/dialogue/<id>.json) in the view's text box, at line `at`.
func talk(id: String, at := "") -> void:
	dialogue_requested.emit(id, at)


# --- save / load ------------------------------------------------------------

## Whole numbers in the save: name -> [lowest, highest]. Stamina is checked against max.
const SAVED_NUMBERS := {
	"year": [1, 9999], "season": [0, 3], "day": [1, DAYS_PER_SEASON], "hour": [0, 23],
	"minute": [0, 59], "money": [0, 1 << 50], "bin_total": [0, 1 << 50],
	"max_stamina": [1, 9999], "water": [0, WATER_MAX], "snow_cover": [0, 100],
}
## Numbers added after the first saves went out: an older save without them gets these.
const SAVED_DEFAULTS := {"snow_cover": 0}


## The run's state as plain data, the farm included (SaveGame writes it).
## Tool and seed are saved by name, so reordering data files doesn't change them.
func to_dict() -> Dictionary:
	var d := {}
	for key in SAVED_NUMBERS:
		d[key] = get(key)
	d.stamina = stamina
	d.weather_today = weather_today
	d.weather_tomorrow = weather_tomorrow
	d.tool = current_tool()
	d.seed = current_seed()
	d.bag = bag.duplicate()
	d.tool_levels = tool_levels.duplicate()
	d.flags = flags.duplicate()
	d.farm = farm.to_dict()
	return d


## Puts a saved state back and redraws through the usual signals. Returns "" or what was
## wrong; everything is checked first, so on a problem nothing changes.
func from_dict(data: Dictionary) -> String:
	var n := {}
	for key in SAVED_NUMBERS:
		n[key] = SaveGame.whole(data.get(key, SAVED_DEFAULTS.get(key)), SAVED_NUMBERS[key][0], SAVED_NUMBERS[key][1])
		if n[key] == null:
			return "Saved %s is broken" % key
	n.stamina = SaveGame.whole(data.get("stamina"), 0, n.max_stamina)
	if n.stamina == null:
		return "Saved stamina is broken"
	for key in ["weather_today", "weather_tomorrow"]:
		if not data.get(key) is String or data[key] == "":
			return "Saved %s is broken" % key
		n[key] = data[key]
	n.tool_index = TOOLS.find(data.get("tool", ""))
	if n.tool_index < 0:
		return "Saved tool is broken"
	n.seed_index = crops.keys().find(data.get("seed", ""))
	if n.seed_index < 0:
		return "Saved seed is broken"
	var saved_bag = data.get("bag")
	if not saved_bag is Dictionary:
		return "Saved bag is broken"
	n.bag = {}
	for id in saved_bag:
		var c = SaveGame.whole(saved_bag[id], 1, 999999)
		if not id is String or c == null:
			return "Saved bag is broken"
		n.bag[id] = c
	# Saves from before charging tools have no levels: every tool at level 1.
	n.tool_levels = {}
	for tool in tools_data.get("tools", {}):
		n.tool_levels[tool] = 1
	if data.has("tool_levels"):
		var levels = data.tool_levels
		if not levels is Dictionary:
			return "Saved tool levels are broken"
		for tool in levels:
			if not n.tool_levels.has(tool):
				return "Saved tool levels are broken"
			var lv = SaveGame.whole(levels[tool], 1, tool_max_level(tool))
			if lv == null:
				return "Saved tool levels are broken"
			n.tool_levels[tool] = lv
	# Saves from before dialogue have no flags.
	n.flags = {}
	var saved_flags = data.get("flags", {})
	if not saved_flags is Dictionary:
		return "Saved flags are broken"
	for k in saved_flags:
		var v = DialogueRunner.flag_value(saved_flags[k])
		if not k is String or k == "" or v == null:
			return "Saved flags are broken"
		n.flags[k] = v
	if not data.get("farm") is Dictionary:
		return "Saved farm is missing"
	var err := farm.from_dict(data.farm)
	if err != "":
		return err
	for key in n:
		set(key, n[key])
	_accum = 0.0
	day_started.emit()   # the views put the farmer home and redo weather and light
	changed.emit()
	return ""


func quick_save() -> void:
	var err := SaveGame.write(self)
	message.emit("Game saved" if err == "" else err)


func quick_load() -> void:
	var err := SaveGame.read(self)
	message.emit("Game loaded" if err == "" else "Could not load: " + err)


func _unhandled_input(event: InputEvent) -> void:
	if paused():
		return
	if event.is_action_pressed("quick_save"):
		quick_save()
	elif event.is_action_pressed("quick_load"):
		quick_load()


# --- setup ------------------------------------------------------------------

func _load_json(path: String) -> Dictionary:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		return data
	push_error("Could not read " + path)
	return {}


func _setup_input() -> void:
	var keys := {
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"run": [KEY_SHIFT], "use_tool": [KEY_SPACE, KEY_J], "interact": [KEY_E, KEY_K],
		"next_tool": [KEY_TAB], "next_seed": [KEY_Q],
		"quick_save": [KEY_F5], "quick_load": [KEY_F9], "pause": [KEY_ESCAPE],
	}
	var pad := {"pause": [JOY_BUTTON_START]}
	for i in TOOLS.size():
		keys["tool_%d" % (i + 1)] = [KEY_1 + i]
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		for b in pad.get(action, []):
			var ev := InputEventJoypadButton.new()
			ev.button_index = b
			InputMap.action_add_event(action, ev)
