extends Node
## Global game state: clock, calendar, weather, money, stamina, tools and the bag.
## Rules follow the design doc; every number here is ours to tune.

signal minute_passed
signal day_started
signal changed                  # anything the HUD shows
signal message(text: String)

const SECONDS_PER_MINUTE := 0.5
const DAYS_PER_SEASON := 30
const SEASONS: Array[String] = ["spring", "summer", "fall", "winter"]
const PAYOUT_HOUR := 18
const PASS_OUT_HOUR := 2
const WATER_MAX := 40
const TOOLS: Array[String] = ["hoe", "can", "sickle", "hammer", "axe", "seeds"]
const TOOL_COST := {"hoe": 2, "can": 1, "sickle": 1, "hammer": 2, "axe": 2, "seeds": 1}

var year := 1
var season := 0
var day := 1
var hour := 6
var minute := 0
var weather_today := "sunny"
var weather_tomorrow := "sunny"
var clock_running := true

var money := 500
var bin_total := 0
var stamina := 100
var max_stamina := 100
var water := WATER_MAX
var tool_index := 0
var seed_index := 0
var bag: Dictionary = {}        # item id -> count; seeds are "seeds:<crop>"

var crops: Dictionary = {}
var weather_chances: Dictionary = {}
var weather_fx: Dictionary = {}    # look per weather: tint, falling particles
var rng := RandomNumberGenerator.new()
var farm: FarmGrid
var _accum := 0.0


func _ready() -> void:
	rng.randomize()
	crops = _load_json("res://data/crops.json")
	weather_chances = _load_json("res://data/weather.json")
	weather_fx = _load_json("res://data/weather_fx.json")
	_setup_input()
	new_game()


func new_game() -> void:
	farm = FarmGrid.new(crops)
	farm.generate(rng)
	bag = {"seeds:turnip": 2, "seeds:potato": 1}
	weather_tomorrow = roll_weather(_tomorrow_season())
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo":
			_demo_field()
		elif arg.begins_with("--weather="):   # e.g. `-- --demo --weather=storm` for screenshots
			weather_today = arg.trim_prefix("--weather=")


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
	if not clock_running:
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


# --- save / load ------------------------------------------------------------

## Whole numbers in the save: name -> [lowest, highest]. Stamina is checked against max.
const SAVED_NUMBERS := {
	"year": [1, 9999], "season": [0, 3], "day": [1, DAYS_PER_SEASON], "hour": [0, 23],
	"minute": [0, 59], "money": [0, 1 << 50], "bin_total": [0, 1 << 50],
	"max_stamina": [1, 9999], "water": [0, WATER_MAX],
}


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
	d.farm = farm.to_dict()
	return d


## Puts a saved state back and redraws through the usual signals. Returns "" or what was
## wrong; everything is checked first, so on a problem nothing changes.
func from_dict(data: Dictionary) -> String:
	var n := {}
	for key in SAVED_NUMBERS:
		n[key] = SaveGame.whole(data.get(key), SAVED_NUMBERS[key][0], SAVED_NUMBERS[key][1])
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
		"quick_save": [KEY_F5], "quick_load": [KEY_F9],
	}
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
