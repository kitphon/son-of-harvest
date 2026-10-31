extends Node
## Global game state: clock, calendar, weather, money, stamina, tools, the inventory, food and story state.
## Rules follow the design doc; every number here is ours to tune.

signal minute_passed
signal day_started
signal changed                  # anything the HUD shows
signal message(text: String)
signal dialogue_requested(id: String, at: String)   # a TextBox opens it
signal event_requested(id: String)                  # an EventPlayer plays it
signal inventory_requested(mode: String)   # an InventoryScreen opens: "rucksack" or "storage"
signal settings_changed
signal map_changed(map_id: String)   # the views fade out, rebuild for Game.maps and fade in
signal map_entered(map_id: String)   # the farmer stands on the new map (after the fade); event triggers key on this
signal thrown(item: String, from: Vector2i, to: Vector2i, result: String)   # views draw the flight
signal shop_requested(id: String)    # a ShopScreen opens that shop (data/shops.json)

const SECONDS_PER_MINUTE := 0.5
const DAYS_PER_SEASON := 30
const SEASONS: Array[String] = ["spring", "summer", "fall", "winter"]
## Spring 1 of year 1 is a Monday; the week runs on across seasons and years.
const WEEKDAYS: Array[String] = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
const PAYOUT_HOUR := 18
const PASS_OUT_HOUR := 2
const WATER_MAX := 40
const TOOLS: Array[String] = ["hoe", "can", "sickle", "hammer", "axe", "seeds", "food"]   # every tool id
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
var event_running := false      # an event script plays: the clock waits, the script moves the farmer
var settings: Settings          # the player's settings (user://settings.json), not saved with the run
var _pauses := 0                # open menus; while any is open time stands still

var money := 500
var bin_total := 0
var stamina := 100
var max_stamina := 100
var water := WATER_MAX
var tool_index := 0             # the tool slot in hand (inventory "tools")
var seed_index := 0
var food_index := 0             # the food in hand when the food slot is picked (data/foods.json order)
## Rucksack tool / item slots, the item hand and the storage chest (data/inventory.json).
var inventory: Inventory = Inventory.starting(TOOLS)
## What the farmer carries as item id -> count (seeds are "seeds:<crop>"). Setting it puts
## the counts in the bag (the rest in the chest); kept for callers from before slots.
var bag: Dictionary:
	get:
		return inventory.totals()
	set(value):
		inventory.set_carried(value)
var tool_levels: Dictionary = {}   # tool -> level 1..5 (charging tools in data/tools.json)
var flags: Dictionary = {}      # story flags set by dialogue (bool, whole number or word)
var tool_exp: Dictionary = {}      # tool -> experience from using it; levels up at data thresholds
var events_seen: Dictionary = {}   # event id -> true once it has played (once-only triggers)
var fatigue := 0                # 0..FATIGUE_MAX, rises with work and late nights; sleep and food lower it
var work_fatigue_half := false  # a food halves swing fatigue until the day ends
## The item carried overhead in the holding hand ("" = hands free). It is the rucksack's
## hand slot (Inventory "hand"): what the rucksack menu takes in hand is held up the same way.
var held: String:
	get:
		return inventory.id_at("hand", 0)
	set(value):
		inventory.slots.hand[0] = {} if value == "" else {"id": value, "n": 1}
var shipped: Dictionary = {}    # item id -> how many were ever shipped
var shop_jobs: Dictionary = {}  # shop id -> {tool, level, ready (day number), slot}: a tool left for an upgrade

var crops: Dictionary = {}
var weather_chances: Dictionary = {}
var weather_fx: Dictionary = {}    # look per weather: tint, falling particles, lightning
var tools_data: Dictionary = {}    # data/tools.json: charge steps per tool
var snow_rules: Dictionary = {}    # how snow builds up and melts (data/snow_cover.json)
var body: Dictionary = {}          # fatigue, tired states, oversleeping, collapse (data/body.json)
var food_data: Dictionary = {}     # data/foods.json: food and drink, the stand's food stock
var foods: Dictionary = {}         # food id -> {name, price, stamina, fatigue, ...}
var hold_rules: Dictionary = {}    # throw reach, flight, what the bin and the pond do (data/hold.json)
var rng := RandomNumberGenerator.new()
var farm: FarmGrid
var maps := MapManager.new()       # the map the farmer is on and where (saved)
var _accum := 0.0
var _shown_state := "fine"      # the tired state last told to the player


func _ready() -> void:
	rng.randomize()
	crops = _load_json("res://data/crops.json")
	weather_chances = _load_json("res://data/weather.json")
	weather_fx = _load_json("res://data/weather_fx.json")
	tools_data = _load_json("res://data/tools.json")
	snow_rules = _load_json("res://data/snow_cover.json")
	body = _load_json("res://data/body.json")
	set_food_data(_load_json("res://data/foods.json"))
	hold_rules = _load_json("res://data/hold.json")
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
	fatigue = 0
	work_fatigue_half = false
	_shown_state = "fine"
	water = WATER_MAX
	snow_cover = 0
	tool_index = 0
	seed_index = 0
	food_index = 0
	_accum = 0.0
	farm = FarmGrid.new(crops)
	farm.generate(rng)
	inventory = Inventory.starting(TOOLS)
	reset_tool_levels()
	flags = {}
	events_seen = {}
	event_running = false
	maps = MapManager.new()   # on the farm, in front of the house door
	shipped = {}
	shop_jobs = {}
	weather_tomorrow = roll_weather(_tomorrow_season())
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo":
			_demo_field()
		elif arg.begins_with("--map="):   # `-- --demo --map=town` (or town@shrine): start on that spawn
			var want := arg.trim_prefix("--map=").split("@")
			var m := MapManager.data(want[0]) if MapManager.has(want[0]) else null
			var spot: Variant = m.spawns.get(want[1] if want.size() > 1 else "start") if m != null else null
			if spot == null:
				push_warning("No map spawn " + arg.trim_prefix("--map="))
			else:
				maps.place(m.id, spot[0], spot[1])
		elif arg.begins_with("--weather="):   # e.g. `-- --demo --weather=storm` for screenshots
			weather_today = arg.trim_prefix("--weather=")
			snow_cover = next_snow_cover(0, weather_look(weather_today, season_name()), season_name(), snow_rules)
		elif arg == "--tired":   # e.g. `-- --demo --tired` to see the exhausted farmer
			fatigue = int(body.get("states", {}).get("exhausted", {}).get("fatigue", 80))
			_shown_state = body_state()
		elif arg.begins_with("--shop="):   # `-- --demo --shop=general`: at the counter (ShopScreen opens it)
			var s := shop(arg.trim_prefix("--shop="))
			var m := MapManager.data(s.map) if s != null and MapManager.has(s.map) else null
			if m == null or not m.spawns.has("counter"):
				push_warning("No shop counter for " + arg)
			else:
				maps.place(m.id, m.spawns.counter[0], m.spawns.counter[1])
		elif arg == "--hold":   # e.g. `-- --demo --hold`: a turnip overhead, a potato in front of the bin
			held = "turnip"
			farm.place_item(Vector2i(8, 4), "potato")


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
	add_item("food:onigiri", 2)
	add_item("food:green_tea", 1)
	farm.cells_changed.emit()
	# Something to see in the rucksack and the chest (`-- --demo --rucksack`).
	inventory.add("turnip", 6)
	inventory.add("potato", 3)
	inventory.add("seeds:cucumber", 4)
	inventory.add("cucumber", 12, ["chest"])
	inventory.add("seeds:turnip", 5, ["chest"])


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
		else:
			add_fatigue(int(body.get("awake_late", {}).get(str(hour), 0)))
	check_body()
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
	return _pauses > 0 or dialogue_open or event_running


## Does time pass now (not on the title screen, no menu open, not inside a building)?
## Indoors only the clock stands; the farmer still walks (paused() is for menus).
func ticking() -> bool:
	return clock_running and not paused() and not indoors()


# --- maps -------------------------------------------------------------------

## DESIGN: time stops in every building, so talking and shopping never race the clock.
func indoors() -> bool:
	var m := maps.current()
	return m != null and m.indoor


## Moves the farmer to `map_id` at `cell` facing `face`; the views fade and rebuild, then
## call map_arrived(). An obstacle that grew on a farm arrival cell is pushed aside.
func go_to_map(map_id: String, cell: Vector2i, face: Vector2i) -> bool:
	if not MapManager.has(map_id) or MapManager.data(map_id) == null:
		return false
	maps.place(map_id, cell, face)
	if maps.on_farm() and farm.in_bounds(cell) and farm.cell(cell).obj != FarmGrid.Obj.NONE:
		farm.cell(cell).obj = FarmGrid.Obj.NONE
		farm.cells_changed.emit()
	map_changed.emit(map_id)
	return true


## Through a door: to its map, or only its message when it leads nowhere yet. A shop's door
## stays shut outside its hours and says so.
func use_door(door: Dictionary) -> void:
	if door.get("to", "") == "":
		message.emit(door.message)
		return
	var s := shop(door.get("shop", ""))
	if s != null and not s.is_open(hour, weekday()):
		message.emit(s.closed_text())
		return
	go_to_map(door.to, door.spawn, door.facing)


## The view finished the change: the farmer is on the map and can see it.
func map_arrived() -> void:
	map_entered.emit(maps.id)


## A new day starts at home: in the house, by the futon.
func go_home() -> void:
	var spot: Array = MapManager.data(MapManager.HOME).spawns.home
	go_to_map(MapManager.HOME, spot[0], spot[1])


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


## Today's weekday ("mon" .. "sun").
func weekday() -> String:
	return WEEKDAYS[day_number() % WEEKDAYS.size()]


## Days since the first morning (0 on spring 1, year 1); shop jobs count in these.
func day_number() -> int:
	return ((year - 1) * SEASONS.size() + season) * DAYS_PER_SEASON + day - 1


## The date of a day number, as date_text() writes it.
func date_of(n: int) -> String:
	var d := posmod(n, DAYS_PER_SEASON) + 1
	var s := posmod(n / DAYS_PER_SEASON, SEASONS.size())
	return "%s %d, Year %d" % [SEASONS[s].capitalize(), d, n / (DAYS_PER_SEASON * SEASONS.size()) + 1]


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


## Sleep before midnight: full stamina. After midnight: three quarters. Fatigue goes down by
## the hours in bed, and a tired farmer or a very late bedtime wakes up later (sleep_rest,
## wake_hour).
func sleep() -> void:
	var late := hour < 6
	var wake := wake_hour(fatigue, hour)
	fatigue = maxi(fatigue - sleep_rest(hour, minute), 0)
	end_day()
	stamina = max_stamina * 3 / 4 if late else max_stamina
	hour = wake
	_shown_state = body_state()
	# Sleeping saves the game (the morning after), like writing in a diary.
	var err := SaveGame.write(self)
	var hello := "Good morning!" if wake == 6 else "You overslept until %d:00." % wake
	message.emit(hello + (" Game saved." if err == "" else " " + err))
	changed.emit()


## Still awake at PASS_OUT_HOUR: wake at home, late, with half stamina.
func pass_out() -> void:
	knock_out("pass_out")


## Fatigue reached FATIGUE_MAX: carried home, the doctor's fee, half the next morning lost.
func collapse() -> void:
	knock_out("collapse")


## Shared by pass_out and collapse: the day ends with no rest; wake hour, fee, stamina and the
## fatigue change come from data/body.json.
func knock_out(kind: String) -> void:
	var r: Dictionary = body.get(kind, {})
	end_day()
	hour = int(r.get("wake", 6))
	var fee := mini(int(r.get("fee", 0)), money)
	money -= fee
	stamina = max_stamina * int(r.get("stamina_pct", 50)) / 100
	fatigue = clampi(fatigue + int(r.get("fatigue_change", 0)), 0, FATIGUE_MAX)
	_shown_state = body_state()
	var text := String(r.get("message", "You passed out..."))
	message.emit(text % fee if "%d" in text else text)
	changed.emit()


func end_day() -> void:
	pay_bin()
	day += 1
	if day > DAYS_PER_SEASON:
		day = 1
		season = (season + 1) % 4
		if season == 0:
			year += 1
	work_fatigue_half = false
	weather_today = weather_tomorrow
	weather_tomorrow = roll_weather(_tomorrow_season())
	snow_cover = next_snow_cover(snow_cover, weather_look(weather_today, season_name()), season_name(), snow_rules)
	farm.day_end(season_name(), weather_today, rng)
	hour = 6
	minute = 0
	_accum = 0.0
	go_home()
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


## Puts every crop the farmer carries (rucksack and hand) into the shipping bin; returns
## the value added.
func ship_produce() -> int:
	var total := 0
	var carried := inventory.totals()
	for id in carried:
		if crops.has(id):
			total += int(crops[id].sell) * int(carried[id])
			shipped[id] = int(shipped.get(id, 0)) + int(carried[id])
			inventory.take(id, int(carried[id]))
	bin_total += total
	changed.emit()
	return total


# --- holding and throwing ---------------------------------------------------

func holding() -> bool:
	return held != ""


## What one of `id` fetches in the bin (0 = can't be shipped).
func sell_price(id: String) -> int:
	return int(crops[id].get("sell", 0)) if crops.has(id) else 0


## Hands free: takes the item lying on `c`, else harvests a ripe crop there, into the
## holding hand. Returns the id taken ("" if nothing).
func pick_up(c: Vector2i) -> String:
	if holding() or not farm.in_bounds(c):
		return ""
	var id := farm.take_item_at(c)
	if id == "":
		id = farm.harvest(c)
	if id != "":
		held = id
		changed.emit()
	return id


## Sets the held item down on `c` (a free cell). Returns whether it was put down.
func put_down(c: Vector2i) -> bool:
	if not holding() or not farm.place_item(c, held):
		return false
	inventory.take(held, 1, ["hand"])
	changed.emit()
	return true


## Throws the held item from `origin` towards `facing` (FarmGrid.throw_target with the reach
## from data/hold.json). Shipped: its price goes into the bin, paid like the rest. Lost: gone.
## Landed: it lies on the cell. Blocked: still in hand. Returns {result, cell, item, value}.
func throw_held(origin: Vector2i, facing: Vector2i) -> Dictionary:
	if not holding():
		return {"result": "none", "cell": origin, "item": "", "value": 0}
	var item := held
	var value := sell_price(item)
	# Something the bin can't take bounces off it like off a wall.
	var ship_into: Array = hold_rules.get("ship_into", ["bin"]) if value > 0 else []
	var lost_in: Array = hold_rules.get("lost_in", ["pond"])
	var t := farm.throw_target(origin, facing, int(hold_rules.get("throw_cells", 2)), ship_into, lost_in)
	t.item = item
	t.value = 0
	match t.result:
		"blocked":
			return t
		"ship":
			bin_total += value
			shipped[item] = int(shipped.get(item, 0)) + 1
			t.value = value
		"land":
			farm.place_item(t.cell, item)
	inventory.take(item, 1, ["hand"])   # one off the hand's stack
	thrown.emit(item, origin, t.cell, t.result)
	changed.emit()
	return t


## How many of `id` the farmer carries (rucksack items and the hand).
func count(id: String) -> int:
	return inventory.count(id)


## Is there room in the rucksack for `n` more of `id`?
func can_carry(id: String, n := 1) -> bool:
	return inventory.room_for(id) >= n


## Puts `n` of `id` in the rucksack; returns how many did not fit (0 = all went in).
func add_item(id: String, n := 1) -> int:
	var left := inventory.add(id, n)
	changed.emit()
	return left


## Money from an event or a gift (negative: paid); never below 0 G.
func add_money(n: int) -> void:
	money = maxi(money + n, 0)
	changed.emit()


func take_item(id: String, n := 1) -> bool:
	if not inventory.take(id, n):
		return false
	changed.emit()
	return true


## A name to show for any item id: tools, crops, seed bags; anything else from its id.
func item_name(id: String) -> String:
	if id in TOOLS:
		return HudLayout.TOOL_NAMES.get(id, id.capitalize())
	if crops.has(id):
		return String(crops[id].name)
	if id.begins_with("seeds:") and crops.has(id.trim_prefix("seeds:")):
		return "%s seeds" % crops[id.trim_prefix("seeds:")].name
	return id.replace(":", " ").replace("_", " ").capitalize()


## A swing costs stamina and adds work fatigue. Without enough stamina the farmer still
## works, but every missing point turns into fatigue (overwork), the way to a collapse.
func spend_stamina(n: int) -> bool:
	var missing := maxi(n - stamina, 0)
	stamina -= n - missing
	var tired := work_fatigue() + missing * int(body.get("work", {}).get("overwork_per_stamina", 1))
	add_fatigue(tired / 2 if work_fatigue_half else tired)
	changed.emit()
	return true


# --- food and drink (data/foods.json) --------------------------------------

func set_food_data(data: Dictionary) -> void:
	food_data = data
	foods = data.get("foods", {})


## The food in hand ("" when there is no food data).
func current_food() -> String:
	return foods.keys()[food_index] if food_index < foods.size() else ""


func cycle_food() -> void:
	if foods.size() > 0:
		food_index = (food_index + 1) % foods.size()
	changed.emit()


## Eats (or drinks) one `id` from the bag: stamina up to the max, fatigue down, and the
## specials (a higher max stamina, half swing fatigue for the day). A food that would do
## nothing is kept. Returns true when it was eaten; says what happened either way.
func eat(id: String) -> bool:
	var f: Dictionary = foods.get(id, {})
	if f.is_empty() or count("food:" + id) == 0:
		message.emit("No %s left" % String(f.get("name", id)).to_lower())
		return false
	var grow := mini(int(f.get("max_stamina", 0)), maxi(int(food_data.get("max_stamina_cap", 200)) - max_stamina, 0))
	var half := bool(f.get("work_fatigue_half", false)) and not work_fatigue_half
	var lowers := int(f.get("fatigue", 0)) < 0 and fatigue > 0
	if stamina >= max_stamina and not lowers and grow == 0 and not half:
		message.emit(String(food_data.get("full_message", "You're full.")))
		return false
	take_item("food:" + id)
	max_stamina += grow
	stamina = clampi(stamina + int(f.get("stamina", 0)), 0, max_stamina)
	add_fatigue(int(f.get("fatigue", 0)))
	work_fatigue_half = work_fatigue_half or half
	_shown_state = body_state()   # feeling better: a later tired state is told again
	var text := "You %s the %s." % ["drank" if f.get("drink", false) else "ate", String(f.name).to_lower()]
	var special := String(f.get("special_message", ""))
	if special != "" and (grow > 0 or half):
		text += " " + (special % grow if "%d" in special else special)
	message.emit(text)
	changed.emit()
	return true


## Sound key for eating `id`: "drink" or "eat" (both in data/sfx.json).
func eat_sound(id: String) -> String:
	return "drink" if foods.get(id, {}).get("drink", false) else "eat"


# --- fatigue and tired states (data/body.json) -----------------------------

const FATIGUE_MAX := 100
const BODY_STATES: Array[String] = ["fine", "tired", "exhausted"]


func add_fatigue(n: int) -> void:
	fatigue = clampi(fatigue + n, 0, FATIGUE_MAX)


## Extra fatigue a swing costs now: rain or storm, late evening, after midnight.
func work_fatigue() -> int:
	var w: Dictionary = body.get("work", {})
	var n := 0
	if weather_today == "rain" or weather_today == "storm":
		n += int(w.get("rain", 0))
	if hour >= int(w.get("late_from_hour", 22)):
		n += int(w.get("late", 0))
	elif hour < 6:
		n += int(w.get("after_midnight", 0))
	return n


## "fine", "tired" or "exhausted": the worst state whose fatigue or stamina mark is reached.
func body_state() -> String:
	var states: Dictionary = body.get("states", {})
	for s in ["exhausted", "tired"]:
		var r: Dictionary = states.get(s, {})
		if r.is_empty():
			continue
		if fatigue >= int(r.fatigue) or stamina * 100 <= int(r.stamina_pct) * max_stamina:
			return s
	return "fine"


## Walking speed factor for the current state (1.0 when fine).
func speed_factor() -> float:
	return float(body.get("states", {}).get(body_state(), {}).get("speed", 1.0))


func can_run() -> bool:
	return body_state() != "exhausted"


## Fatigue lost in bed from h:m until 6:00: more hours in bed, more rest.
func sleep_rest(h: int, m: int) -> int:
	var minutes := posmod(6 * 60 - (h * 60 + m), 24 * 60)
	if minutes == 0:
		minutes = 24 * 60
	var r: Dictionary = body.get("sleep", {})
	return int(r.get("base", 0)) + int(r.get("per_hour", 0)) * minutes / 60


## The hour the farmer wakes after going to bed at `bed_hour` with fatigue `f`.
func wake_hour(f: int, bed_hour: int) -> int:
	var over: Dictionary = body.get("oversleep", {})
	var wake := 6
	for pair in over.get("fatigue", []):
		if f >= int(pair[0]):
			wake = maxi(wake, int(pair[1]))
	return maxi(wake, int(over.get("bed_hour", {}).get(str(bed_hour), 6)))


## Every minute: fatigue at the top collapses the farmer; a worse tired state says so once.
func check_body() -> void:
	if fatigue >= FATIGUE_MAX:
		collapse()
		return
	var s := body_state()
	if BODY_STATES.find(s) > BODY_STATES.find(_shown_state):
		message.emit(String(body.states[s].get("message", "")))
	_shown_state = s


# --- tool levels and charging ----------------------------------------------

## Every charging tool back to level 1 with no experience (a new game).
func reset_tool_levels() -> void:
	tool_levels = {}
	tool_exp = {}
	for tool in tools_data.get("tools", {}):
		tool_levels[tool] = 1
		tool_exp[tool] = 0


## Experience one swing gives: "work" when it changed a cell, "miss" when it hit nothing.
## A use that never swung (too tired, empty can) gives nothing and doesn't call this.
func swing_exp(worked: bool) -> int:
	return int(tools_data.get("exp_per_swing", {}).get("work" if worked else "miss", 0))


## Total experience the tool needs to go from `level` to the next one (-1 at the top level).
func exp_for_next_level(tool: String, level: int) -> int:
	var steps: Array = tools_data.get("tools", {}).get(tool, {}).get("exp_to_level", [])
	if level < 1 or level >= tool_max_level(tool) or level > steps.size():
		return -1
	return int(steps[level - 1])


## Adds experience to a tool and raises its level at each threshold it passes. The total is
## kept at most at the last threshold, so a level-5 tool's number stops growing.
func add_tool_exp(tool: String, amount: int) -> void:
	if tool_max_level(tool) == 0 or amount <= 0:
		return
	var steps: Array = tools_data.tools[tool].get("exp_to_level", [])
	var top := int(steps.back()) if steps.size() > 0 else 0
	tool_exp[tool] = mini(int(tool_exp.get(tool, 0)) + amount, top)
	while true:
		var need := exp_for_next_level(tool, tool_level(tool))
		if need < 0 or tool_exp[tool] < need:
			break
		raise_tool_level(tool)


## One level up for a tool (experience now; the blacksmith later calls this too).
## Returns false when the tool is already at its top level.
func raise_tool_level(tool: String) -> bool:
	var lv := tool_level(tool)
	if tool_max_level(tool) == 0 or lv >= tool_max_level(tool):
		return false
	tool_levels[tool] = lv + 1
	message.emit(String(tools_data.tools[tool].get("level_up", "Tool level %d!")) % (lv + 1))
	changed.emit()
	return true


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


## The tool in hand: the marked tool slot's tool, "" when that slot is empty.
func current_tool() -> String:
	return inventory.id_at("tools", tool_index)


func current_seed() -> String:
	return crops.keys()[seed_index]


func cycle_seed() -> void:
	seed_index = (seed_index + 1) % crops.size()
	changed.emit()


func select_tool(i: int) -> void:
	tool_index = posmod(i, inventory.size("tools"))
	changed.emit()


## Opens the rucksack ("rucksack") or the storage chest ("storage") in the view's screen.
func open_inventory(mode := "rucksack") -> void:
	inventory_requested.emit(mode)


## Opens dialogue `id` (data/dialogue/<id>.json) in the view's text box, at line `at`.
func talk(id: String, at := "") -> void:
	dialogue_requested.emit(id, at)


## Plays event `id` (data/events/<id>.json) in the view's EventPlayer.
func play_event(id: String) -> void:
	event_requested.emit(id)


# --- shops (data/shops.json; rules in Shop) ----------------------------------

## The shop `id` with this game's crop and food data, or null.
func shop(id: String) -> Shop:
	return Shop.make(id, crops, foods) if id != "" else null


## The counter (and later its keeper's talk) opens the shop's screen, or says it is closed.
## `force` skips the hours (the `--shop=<id>` screenshot flag). Returns true when it opened.
func open_shop(id: String, force := false) -> bool:
	var s := shop(id)
	if s == null:
		return false
	if not force and not s.is_open(hour, weekday()):
		message.emit(s.closed_text())
		return false
	shop_requested.emit(id)
	return true


func shop_buy(id: String, item: String, n := 1) -> Dictionary:
	return _shop_paid(shop(id).buy(inventory, money, item, n, season_name()))


func shop_sell(id: String, item: String, n := 1) -> Dictionary:
	return _shop_paid(shop(id).sell(inventory, money, item, n))


## Hands the tool in at shop `id` for its next level (Shop.start_upgrade); the job is saved.
func shop_upgrade(id: String, tool: String) -> Dictionary:
	var r := shop(id).start_upgrade(inventory, money, tool, tool_level(tool), day_number(), shop_jobs.has(id))
	if r.ok:
		shop_jobs[id] = r.job
	return _shop_paid(r)


## Takes a finished tool back from shop `id`, one level up (raise_tool_level), its experience
## lifted to that level's start so the bar reads right.
func shop_collect(id: String) -> Dictionary:
	var job: Dictionary = shop_jobs.get(id, {})
	if job.is_empty():
		return {"ok": false, "money": money, "note": "Nothing is waiting for you here"}
	if not Shop.job_ready(job, day_number()):
		return {"ok": false, "money": money, "note": "Not ready yet. Come back on %s." % date_of(int(job.ready))}
	var where := Shop.give_back(inventory, job)
	while tool_level(job.tool) < int(job.level) and raise_tool_level(job.tool):
		pass
	var start := exp_for_next_level(job.tool, int(job.level) - 1)
	tool_exp[job.tool] = maxi(int(tool_exp.get(job.tool, 0)), start)
	shop_jobs.erase(id)
	var note := "Your %s is back, now level %d" % [item_name(job.tool).to_lower(), tool_level(job.tool)]
	changed.emit()
	return {"ok": true, "money": money, "note": note + (" (in the chest)" if where == "chest" else "")}


func _shop_paid(r: Dictionary) -> Dictionary:
	money = int(r.money)
	changed.emit()
	return r


## What trigger tables check (EventTriggers.matches), with the farmer on `cell`.
func trigger_state(cell: Vector2i) -> Dictionary:
	return {"year": year, "season": season_name(), "day": day, "weekday": weekday(),
		"time": hour * 60 + minute, "weather": weather_today, "flags": flags,
		"seen": events_seen, "cell": cell}


# --- save / load ------------------------------------------------------------

## Whole numbers in the save: name -> [lowest, highest]. Stamina is checked against max.
const SAVED_NUMBERS := {
	"year": [1, 9999], "season": [0, 3], "day": [1, DAYS_PER_SEASON], "hour": [0, 23],
	"minute": [0, 59], "money": [0, 1 << 50], "bin_total": [0, 1 << 50],
	"max_stamina": [1, 9999], "water": [0, WATER_MAX], "snow_cover": [0, 100],
	"fatigue": [0, FATIGUE_MAX],
}
## Numbers added after the first saves went out: an older save without them gets these.
const SAVED_DEFAULTS := {"snow_cover": 0, "fatigue": 0}
const SAVED_FLAGS: Array[String] = ["work_fatigue_half"]   # true / false; older saves: false


## The run's state as plain data, the farm included (SaveGame writes it).
## The seed is saved by name, so reordering data files doesn't change it; the tool in hand is
## a tool slot.
func to_dict() -> Dictionary:
	var d := {}
	for key in SAVED_NUMBERS:
		d[key] = get(key)
	d.stamina = stamina
	d.weather_today = weather_today
	d.weather_tomorrow = weather_tomorrow
	d.tool_slot = tool_index
	d.seed = current_seed()
	d.inventory = inventory.to_dict()
	d.food = current_food()
	for key in SAVED_FLAGS:
		d[key] = get(key)
	d.tool_levels = tool_levels.duplicate()
	d.flags = flags.duplicate()
	d.tool_exp = tool_exp.duplicate()
	var seen := events_seen.keys()
	seen.sort()
	d.events_seen = seen
	d.map = maps.to_dict()
	d.shipped = shipped.duplicate()
	d.shop_jobs = shop_jobs.duplicate(true)
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
	n.seed_index = crops.keys().find(data.get("seed", ""))
	if n.seed_index < 0:
		return "Saved seed is broken"
	# Saves from before food have none in hand: the first one.
	var food = data.get("food", "")
	n.food_index = (foods.keys().find(food) if food != "" else 0) if food is String else -1
	if n.food_index < 0:
		return "Saved food is broken"
	for key in SAVED_FLAGS:
		if not data.get(key, false) is bool:
			return "Saved %s is broken" % key
		n[key] = data.get(key, false)
	if data.has("inventory"):
		var parsed := Inventory.parse(data.inventory, TOOLS)
		if parsed[0] != "":
			return parsed[0]
		n.inventory = parsed[1]
		n.tool_index = SaveGame.whole(data.get("tool_slot"), 0, n.inventory.size("tools") - 1)
		if n.tool_index == null:
			return "Saved tool slot is broken"
	else:
		# Saves from before slots: a bag of counts and the tool by name. The tools go in
		# their starting slots, the bag's things in the rucksack (the rest in the chest).
		var saved_bag = data.get("bag")
		if not saved_bag is Dictionary:
			return "Saved bag is broken"
		var counts := {}
		for id in saved_bag:
			var c = SaveGame.whole(saved_bag[id], 1, 999999)
			if not id is String or id == "" or id in TOOLS or c == null:
				return "Saved bag is broken"
			counts[id] = c
		n.inventory = Inventory.starting(TOOLS)
		n.inventory.set_carried(counts)
		n.tool_index = -1
		for i in n.inventory.size("tools"):
			if n.inventory.id_at("tools", i) == data.get("tool", ""):
				n.tool_index = i
		if n.tool_index < 0:
			return "Saved tool is broken"
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
	# Saves from before tool experience have none: every tool at 0.
	n.tool_exp = {}
	for tool in n.tool_levels:
		n.tool_exp[tool] = 0
	if data.has("tool_exp"):
		var exps = data.tool_exp
		if not exps is Dictionary:
			return "Saved tool experience is broken"
		for tool in exps:
			if not n.tool_exp.has(tool):
				return "Saved tool experience is broken"
			var steps: Array = tools_data.tools[tool].get("exp_to_level", [])
			var e = SaveGame.whole(exps[tool], 0, int(steps.back()) if steps.size() > 0 else 0)
			if e == null:
				return "Saved tool experience is broken"
			n.tool_exp[tool] = e
	# Saves from before events have none seen.
	n.events_seen = {}
	var saved_seen = data.get("events_seen", [])
	if not saved_seen is Array:
		return "Saved events are broken"
	for e in saved_seen:
		if not e is String or e == "" or n.events_seen.has(e):
			return "Saved events are broken"
		n.events_seen[e] = true
	# Saves from before maps load on the farm, in front of the house door.
	var place := {"id": MapManager.FARM, "pos": MapManager.new().pos, "facing": Vector2i.DOWN}
	if data.has("map"):
		var r := MapManager.check_saved(data.map)
		if r[0] != "":
			return r[0]
		place = r[1]
	# Saves from before holding: nothing shipped yet (the held item is the inventory's hand).
	var saved_shipped = data.get("shipped", {})
	if not saved_shipped is Dictionary:
		return "Saved shipping counts are broken"
	n.shipped = {}
	for id in saved_shipped:
		var c = SaveGame.whole(saved_shipped[id], 1, 1 << 50)
		if not id is String or id == "" or c == null:
			return "Saved shipping counts are broken"
		n.shipped[id] = c
	# Saves from before shops have no tools at the smithy.
	var saved_jobs = data.get("shop_jobs", {})
	if not saved_jobs is Dictionary:
		return "Saved shop jobs are broken"
	n.shop_jobs = {}
	for sid in saved_jobs:
		var s := shop(sid) if sid is String else null
		var j = saved_jobs[sid]
		if s == null or not j is Dictionary or not j.get("tool") is String or not j.tool in s.upgrade_tools:
			return "Saved shop jobs are broken"
		var job := {"tool": j.tool, "level": SaveGame.whole(j.get("level"), 2, tool_max_level(j.tool)),
			"ready": SaveGame.whole(j.get("ready"), 0, 1 << 40), "slot": SaveGame.whole(j.get("slot"), 0, 998)}
		if null in job.values():
			return "Saved shop jobs are broken"
		n.shop_jobs[sid] = job
	if not data.get("farm") is Dictionary:
		return "Saved farm is missing"
	var err := farm.from_dict(data.farm)
	if err != "":
		return err
	farm.add_missing_fixed()   # saves from before the storage chest get it by the house
	for key in n:
		set(key, n[key])
	maps = MapManager.new()
	maps.id = place.id
	maps.pos = place.pos
	maps.facing = place.facing
	_accum = 0.0
	_shown_state = body_state()
	day_started.emit()   # the views redo weather and light
	map_changed.emit(maps.id)   # and put the farmer where the save says
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
		"next_tool": [KEY_TAB], "next_seed": [KEY_Q], "rucksack": [KEY_I],
		"quick_save": [KEY_F5], "quick_load": [KEY_F9], "pause": [KEY_ESCAPE],
	}
	var pad := {"pause": [JOY_BUTTON_START], "rucksack": [JOY_BUTTON_BACK]}
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
