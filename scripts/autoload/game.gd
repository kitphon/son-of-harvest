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
var rng := RandomNumberGenerator.new()
var farm: FarmGrid
var _accum := 0.0


func _ready() -> void:
	rng.randomize()
	crops = _load_json("res://data/crops.json")
	weather_chances = _load_json("res://data/weather.json")
	_setup_input()
	new_game()


func new_game() -> void:
	farm = FarmGrid.new(crops)
	farm.generate(rng)
	bag = {"seeds:turnip": 2, "seeds:potato": 1}
	weather_tomorrow = roll_weather(_tomorrow_season())


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
	message.emit("Good morning!")
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
