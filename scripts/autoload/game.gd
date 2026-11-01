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
signal cooking_requested             # a CookingScreen opens (the kitchen corner, data/recipes.json)
signal ending_requested(record: Dictionary)   # an EndingScreen shows the village record (Ending.grade)
signal fishing_event(kind: String)   # "bite" / "escaped" while the line is out (FarmActions plays the cue)

const SECONDS_PER_MINUTE := 0.5
const DAYS_PER_SEASON := 30
const SEASONS: Array[String] = ["spring", "summer", "fall", "winter"]
## Spring 1 of year 1 is a Monday; the week runs on across seasons and years.
const WEEKDAYS: Array[String] = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
const PAYOUT_HOUR := 18
const PASS_OUT_HOUR := 2
const WATER_MAX := 40
const TOOLS: Array[String] = ["hoe", "can", "sickle", "hammer", "axe", "seeds", "food", "rod"]   # every tool id
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
var text_speed := 1.0           # the text box's speed from the settings (x letters per second; 0 = at once)
var always_run := false         # settings: the farmer runs unless the run key is held
var hud_visible := true         # settings: the HUD is drawn
var clock_running := true      # off on the title screen
var dialogue_open := false      # a text box is up: the clock and the farmer wait (counts as paused)
var event_running := false      # an event script plays: the clock waits, the script moves the farmer
var ending_open := false        # the village record is on screen (the ending event waits for it)
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
var house_built: Array[String] = []   # house extensions done (data/shops.json builds; the maps follow)
var house_job: Dictionary = {}        # the one being built: {build, shop, ready (day number), late?}
var kitchen_tools: Array[String] = [] # cooking tools owned (data/recipes.json tools; bought at the store)
## The story flag set to the extension's id while its builder is at work on the farm (from the
## morning after the order until it is done; sync_build_flag). Day plans (data/villagers),
## talk picks and map props (the lumber by the farmhouse) read it like any flag.
const BUILD_FLAG := "house_work"
var fishing := Fishing.new()       # the line: cast, wait, bite (rules in data/fish.json)
var fish_caught: Dictionary = {}   # fish id -> how many were caught this game (once-only fish)
var mine_deepest := 0              # the deepest mine floor reached (the only mine state saved)
var first_day: Dictionary = {"values": {}, "field": {}}   # {values, field} measured when the run began (the record's look back)
var year_pages: Dictionary = {}    # year -> the village record's page written that New Year (Ending.page_of)

var crops: Dictionary = {}
var weather_chances: Dictionary = {}
var weather_fx: Dictionary = {}    # look per weather: tint, falling particles, lightning
var tools_data: Dictionary = {}    # data/tools.json: charge steps per tool
var snow_rules: Dictionary = {}    # how snow builds up and melts (data/snow_cover.json)
var body: Dictionary = {}          # fatigue, tired states, oversleeping, collapse (data/body.json)
var food_data: Dictionary = {}     # data/foods.json: food and drink, the stand's food stock
var foods: Dictionary = {}         # food id -> {name, price, stamina, fatigue, ...}
var hold_rules: Dictionary = {}    # throw reach, flight, what the bin and the pond do (data/hold.json)
var fish_data: Dictionary = {}     # data/fish.json: bites, fish per place / season / hour / weather
var mine_data: Dictionary = {}     # data/mine.json: floors, finds per depth / season, mine items
var rng := RandomNumberGenerator.new()
var farm: FarmGrid
var maps := MapManager.new()       # the map the farmer is on and where (saved)
var animals := Animals.new()       # the coop, the barn and the dog (data/animals.json, saved)
var animal_news: Array[String] = []   # what happened to the animals overnight, told in the coop
var affection := Affection.new()   # how much each villager likes the farmer (saved)
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
	fish_data = _load_json("res://data/fish.json")
	mine_data = _load_json("res://data/mine.json")
	settings = Settings.make()
	var err := settings.read()
	if err != "":
		push_warning(err + "; using the default settings")
	_setup_input()
	apply_settings()
	new_game()


## A fresh run: every value back to the start and a newly laid-out farm, so nothing from an
## earlier game in the same session is left over. New run state belongs in this list too.
func new_game() -> void:
	ending_open = false
	year = 1
	season = 0
	day = 1
	hour = 6
	minute = 0
	weather_today = "sunny"
	money = START_MONEY
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
	farm.prop_blocks = farm_prop_blocks   # the farm map's solid story props (the lumber)
	farm.generate(rng)
	inventory = Inventory.starting(TOOLS)
	reset_tool_levels()
	flags = {}
	events_seen = {}
	event_running = false
	maps = MapManager.new()   # on the farm, in front of the house door
	shipped = {}
	shop_jobs = {}
	house_built = []
	house_job = {}
	kitchen_tools = []
	MapManager.set_built(house_built)
	MapManager.set_flags(flags)   # props gated by story flags (the bell, the store's sign)
	animals = Animals.new()
	animals.start()
	animal_news = []
	fishing = Fishing.new(fish_data)
	fish_caught = {}
	affection = Affection.new()
	Villagers.reset_day()
	mine_deepest = 0
	year_pages = {}
	first_day = {"values": ending_values(), "field": field_counts()}   # before --demo digs the field
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--season="):   # `-- --demo --season=winter --mine=3`: day 1 of that season
			var s := SEASONS.find(arg.trim_prefix("--season="))
			if s < 0:
				push_warning("No season " + arg)
			else:
				season = s
	weather_tomorrow = roll_weather(_tomorrow_season())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--festival="):   # `-- --demo --festival=lantern_night`: its day, hours and place
			Festivals.start_at(self, arg.trim_prefix("--festival="))
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
		elif arg.begins_with("--snow="):   # e.g. `-- --demo --season=winter --map=town --snow=80`: snow lying, 0..100
			snow_cover = clampi(int(arg.trim_prefix("--snow=")), 0, 100)
		elif arg.begins_with("--time="):   # e.g. `-- --demo --map=town --time=14:30` (villagers by their plans)
			var t := EventTriggers.clock(arg.trim_prefix("--time="))
			if t < 0 or t >= 24 * 60:
				push_warning("No clock time " + arg)
			else:
				hour = t / 60
				minute = t % 60
		elif arg == "--tired":   # e.g. `-- --demo --tired` to see the exhausted farmer
			fatigue = int(body.get("states", {}).get("exhausted", {}).get("fatigue", 80))
			_shown_state = body_state()
		elif arg.begins_with("--shop="):   # `-- --demo --shop=general` (or general@build): at the counter (ShopScreen opens it)
			var s := shop(arg.trim_prefix("--shop=").get_slice("@", 0))
			var m := MapManager.data(s.map) if s != null and MapManager.has(s.map) else null
			var stall: Dictionary = Festivals.stall_of(s.id)[1] if s != null else {}
			if not stall.is_empty():   # `--festival=blossom_day --shop=stall:blossom_day`: in front of the stall
				maps.place(m.id, Vector2i(int(stall.cell[0]), int(stall.cell[1]) + 1), Vector2i.UP)
			elif m == null or not m.spawns.has("counter"):
				push_warning("No shop counter for " + arg)
			else:
				maps.place(m.id, m.spawns.counter[0], m.spawns.counter[1])
		elif arg.begins_with("--built="):   # e.g. `-- --demo --map=house --built=kitchen,room`: extensions done
			for b in arg.trim_prefix("--built=").split(","):
				_finish_build({"build": b, "shop": _builder_shop(b), "ready": 0})
		elif arg.begins_with("--building="):   # e.g. `-- --demo --building=kitchen`: ordered yesterday, Hachiro at work
			var b := arg.trim_prefix("--building=")
			var sid := _builder_shop(b)
			if sid == "" or has_built(b):
				push_warning("No extension to build for " + arg)
			else:
				house_job = {"build": b, "shop": sid, "ready": day_number() + int(shop(sid).builds[b].days) - 1}
				sync_build_flag()
		elif arg.begins_with("--flags="):   # e.g. `-- --demo --flags=hachiro_bell,sayo_sign=new`: story flags set
			for f in arg.trim_prefix("--flags=").split(",", false):
				flags[f.get_slice("=", 0)] = f.get_slice("=", 1) if "=" in f else true
		elif arg.begins_with("--hearts="):   # e.g. `-- --demo --hearts=4 --talk=tome`: everyone at the start of band 4
			var bands: Array = Affection.rules().get("bands", [0])
			var b := clampi(arg.trim_prefix("--hearts=").to_int(), 0, bands.size() - 1)
			for id in Villagers.all():
				affection.points[id] = int(bands[b])
		elif arg == "--cook":   # `-- --demo --cook`: at the kitchen corner (CookingScreen opens it)
			if not has_built("kitchen"):
				_finish_build({"build": "kitchen", "shop": _builder_shop("kitchen"), "ready": 0})
			var m := MapManager.data("house")
			maps.place(m.id, m.spawns.kitchen[0], m.spawns.kitchen[1])
			if "--demo" in OS.get_cmdline_user_args():
				_demo_kitchen()
		elif arg == "--hens-out":   # e.g. `-- --demo --map=farm@coop --hens-out`: the hens in the yard
			animals.outside = true
		elif arg == "--barn-out":   # e.g. `-- --demo --map=farm@barn --barn-out`: cows and sheep grazing
			animals.state.barn.out = true
		elif arg == "--hold":   # e.g. `-- --demo --hold`: a turnip overhead, a potato in front of the bin
			held = "turnip"
			farm.place_item(Vector2i(8, 4), "potato")
		elif arg.begins_with("--fishing"):   # `-- --demo --fishing` (or =wait, =river, =river:wait): the line in the farm pond (or the river), a fish biting
			var opts := arg.trim_prefix("--fishing").trim_prefix("=").split(":")
			if "river" in opts:
				var m := MapManager.data("river")
				maps.place(m.id, m.spawns.shore[0], m.spawns.shore[1])
				fishing.cast(m.id, m.spawns.shore[0] + m.spawns.shore[1])
			else:
				maps.place(MapManager.FARM, Vector2i(24, 3), Vector2i.RIGHT)
				fishing.cast(MapManager.FARM, Vector2i(25, 3))
			for i in inventory.size("tools"):
				if inventory.id_at("tools", i) == "rod":
					tool_index = i
			if not "wait" in opts:
				fishing.state = "bite"
				fishing.time = -60.0   # the bite waits for the screenshot
		elif arg.begins_with("--contest="):   # `-- --demo --festival=blossom_day --contest=potato`: at the judges' table with it
			var fid := festival_today()
			var c := Festivals.contest(fid)
			if c.is_empty():
				push_warning("No contest today for " + arg)
			else:
				held = arg.trim_prefix("--contest=")
				maps.place(Festivals.get_festival(fid).map, Vector2i(int(c.table[0]), int(c.table[1]) + 1), Vector2i.UP)
		elif arg.begins_with("--mine="):   # `-- --demo --mine=5`: at the ladder of a fresh floor 5
			var m := MapManager.data(mine_map("floor_map"))
			maps.place(m.id, m.spawns.start[0], m.spawns.start[1])
			maps.mine_floor = new_mine_floor(maxi(arg.trim_prefix("--mine=").to_int(), 1))
	# `--map=mine_floor` alone: the first floor.
	if maps.id == mine_map("floor_map") and maps.mine_floor == null:
		maps.mine_floor = new_mine_floor(1)


## The demo field's three crops per season (winter, with no field crops, shows spring's).
const DEMO_CROPS := {"spring": ["turnip", "potato", "cucumber"], "summer": ["tomato", "corn", "rice"],
	"fall": ["pumpkin", "rice", "daikon"], "winter": ["turnip", "potato", "cucumber"]}


## `-- --demo`: 10:00 with a few sown, growing and ripe plots by the house, for screenshots
## (`--season=fall` sows that season's crops; the third, ripe, is rice in summer and daikon in fall).
func _demo_field() -> void:
	hour = 10
	for y in range(5, 8):
		for x in range(2, 11):
			var c := Vector2i(x, y)
			farm.cell(c).obj = FarmGrid.Obj.NONE
			farm.till(c)
	var sown: Array = DEMO_CROPS[season_name()]
	for i in 3:
		farm.sow(Vector2i(3 + i * 3, 6), sown[i], crops[sown[i]].seasons[0])
	for y in range(5, 8):
		for x in range(2, 11):
			var d := farm.cell(Vector2i(x, y))
			d.stage = mini((x - 2) / 3 + 1, farm.ripe_stage(d.crop))
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
	# The coop with a chick, eggs in the nests and the feed box filled (`-- --demo --map=coop`).
	animals.add("chicken", true)
	animals.eggs.assign(["egg", "egg_good"])
	animals.fill_feed_box()
	# The barn with a cow ready to milk, a calf and a sheep in full wool (`-- --demo --map=barn`).
	for kind in ["cow", "sheep"]:
		animals.add(kind)
		animals.list.back().prod_days = int(animals.gives(animals.list.back()).every)
		animals.list.back().happy = 60
	animals.add("cow", true)
	animals.fill_feed_box("barn")
	animals.dog.affection = int(animals.dog_rule().get("follow_affection", 0))   # follows the farmer


## `-- --demo --cook`: eggs, a fish and vegetables to cook with (the chest when the rucksack is
## full), one recipe learned and one of its two tools (so the screen shows a tool missing).
func _demo_kitchen() -> void:
	for id in ["egg", "egg", "fish:funa", "carrot", "onion"]:
		inventory.add(id, 1, ["bag", "chest"])
	flags[Cooking.flag("turnip_stew")] = true
	if not "knife" in kitchen_tools:
		kitchen_tools.append("knife")


func _process(delta: float) -> void:
	if fishing.active() and not paused():
		var chance := Fishing.bite_chance(fish_data, hour, weather_look(weather_today, season_name())) * rod_bite_factor()
		var ev := fishing.step(delta, chance, rng)
		if ev != "":
			fishing_event.emit(ev)
	if not ticking():
		return
	Villagers.bump(maps.id, day_minutes(), delta / SECONDS_PER_MINUTE, maps.pos / 16.0, trigger_state(Vector2i.ZERO))
	_accum += delta
	while _accum >= SECONDS_PER_MINUTE:
		_accum -= SECONDS_PER_MINUTE
		_tick_minute()


func _tick_minute() -> void:
	minute += 1
	if minute == 60:
		minute = 0
		hour = (hour + 1) % 24
		animals.hour_passed(weather_today)
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


## Under a roof (a building, the mine): no rain or snow falls here.
func sheltered() -> bool:
	var m := maps.current()
	return m != null and m.sheltered


## Moves the farmer to `map_id` at `cell` facing `face`; the views fade and rebuild, then
## call map_arrived(). An obstacle that grew on a farm arrival cell is pushed aside.
func go_to_map(map_id: String, cell: Vector2i, face: Vector2i) -> bool:
	if not MapManager.has(map_id) or MapManager.data(map_id) == null:
		return false
	# Down the mine: the cave mouth leads to floor 1, a floor's hole to the next one, fresh each time.
	var depth := 0
	if map_id == mine_map("floor_map"):
		depth = maps.mine_floor.depth + 1 if maps.mine_floor != null else 1
	maps.place(map_id, cell, face)
	maps.mine_floor = new_mine_floor(depth) if depth > 0 else null
	fishing.stop()
	if maps.on_farm() and farm.in_bounds(cell) and farm.cell(cell).obj != FarmGrid.Obj.NONE:
		farm.cell(cell).obj = FarmGrid.Obj.NONE
		farm.cells_changed.emit()
	map_changed.emit(map_id)
	return true


## Through a door: to its map, or only its message when it leads nowhere yet. A shop's door
## stays shut outside its hours, a home's outside its `hours`, and says so.
func use_door(door: Dictionary) -> void:
	if door.get("to", "") == "":
		message.emit(door.message)
		return
	var s := shop(door.get("shop", ""))
	if s != null and _shop_shut(s):
		return
	if not MapData.door_open(door, day_minutes()):
		message.emit(door.closed)
		return
	go_to_map(door.to, door.spawn, door.facing)


## The view finished the change: the farmer is on the map and can see it.
func map_arrived() -> void:
	map_entered.emit(maps.id)
	if maps.mine_floor != null:
		var frozen := ", %s" % str(mine_data.get("winter", {}).get("name", "frozen")) if maps.mine_floor.frozen else ""
		message.emit("Mine floor %d%s" % [maps.mine_floor.depth, frozen])
	# The night's animal news waits for the farmer to look in on them.
	if animals.home_on_map(maps.id) != "" and not animal_news.is_empty():
		message.emit(". ".join(animal_news))
		animal_news.clear()


## A new day starts at home: in the house, by the futon.
func go_home() -> void:
	var spot: Array = MapManager.data(MapManager.HOME).spawns.home
	go_to_map(MapManager.HOME, spot[0], spot[1])


# --- settings ---------------------------------------------------------------

## Puts the settings into effect (on start and the moment one changes in the menu); views
## that draw something a setting changes listen to settings_changed. `-- --no-flashes`
## always wins over the file.
func apply_settings(args := OS.get_cmdline_user_args()) -> void:
	if settings == null:
		return
	flashes_enabled = bool(settings.value("flashes")) and not "--no-flashes" in args
	text_speed = float(settings.option_value("text_speed"))
	always_run = bool(settings.value("always_run"))
	hud_visible = bool(settings.value("hud"))
	_apply_window(str(settings.value("display")), str(settings.value("window")))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.value("vsync") else DisplayServer.VSYNC_DISABLED)
	settings_changed.emit()


const DISPLAY_MODES := {
	"fullscreen": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	"borderless": DisplayServer.WINDOW_MODE_FULLSCREEN,   # Godot's "full screen" is a borderless window
}


## Full screen, a borderless window over the screen, or a window sized as a whole multiple
## of the 480 x 270 picture (the biggest that fits on the screen, at least 1x).
func _apply_window(display: String, scale: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if DISPLAY_MODES.has(display):
		if DisplayServer.window_get_mode() != DISPLAY_MODES[display]:
			DisplayServer.window_set_mode(DISPLAY_MODES[display])
		return
	var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var base := Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	var n := window_scale(scale.trim_suffix("x").to_int(), base, screen.size)
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var size := base * n
	if DisplayServer.window_get_size() == size:
		return
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)


## The window scale to use: `wanted`, less while base x scale is bigger than the screen.
static func window_scale(wanted: int, base: Vector2i, screen: Vector2i) -> int:
	var n := maxi(wanted, 1)
	while n > 1 and (base.x * n > screen.x or base.y * n > screen.y):
		n -= 1
	return n


# --- calendar and weather ---------------------------------------------------

func season_name() -> String:
	return SEASONS[season]


func date_text() -> String:
	return "%s %d, Year %d" % [season_name().capitalize(), day, year]


func time_text() -> String:
	return "%02d:%02d" % [hour, minute]


## The clock as a minute of the game day (6:00 = 360, 1:30 at night = 1530) with the part
## of the minute that has passed, so villagers (Villagers.on_map) walk smoothly between ticks.
func day_minutes() -> float:
	return DayPlan.day_minute(hour, minute) + _accum / SECONDS_PER_MINUTE


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


## Is tomorrow always fair (DESIGN): a festival, or a villager's birthday?
func fair_tomorrow() -> bool:
	var d := day % DAYS_PER_SEASON + 1
	return Festivals.tomorrow(season, day) != "" or not Villagers.birthdays_on(SEASONS[_tomorrow_season()], d).is_empty()


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
	affection.day_end(day_number(), rng)   # before the date moves: who was left alone today
	day += 1
	if day > DAYS_PER_SEASON:
		day = 1
		season = (season + 1) % 4
		if season == 0:
			year += 1
			flags["record_due"] = true   # Tome brings this New Year's page (triggers_house.json)
	work_fatigue_half = false
	_count_build_day()   # before the date moves: did the builder work today?
	animal_news.append_array(animals.day_end(weather_today, rng))
	fishing.stop()
	weather_today = weather_tomorrow
	weather_tomorrow = roll_weather(_tomorrow_season())
	if fair_tomorrow():
		weather_tomorrow = "sunny"   # DESIGN: a festival day and a villager's birthday are always fair
	snow_cover = next_snow_cover(snow_cover, weather_look(weather_today, season_name()), season_name(), snow_rules)
	farm.day_end(season_name(), weather_today, rng)
	hour = 6
	minute = 0
	_accum = 0.0
	if Shop.job_ready(house_job, day_number()):
		_finish_build(house_job)
	sync_build_flag()
	go_home()
	day_started.emit()
	changed.emit()


# --- money, bag, stamina ----------------------------------------------------

## The bin's money comes in at 18:00 or overnight, except on a festival day (DESIGN): then it
## waits in the bin and is paid with the next day's shipping.
func pay_bin() -> void:
	if bin_total <= 0:
		return
	if payout_held():
		message.emit("No shipping pickup on %s. Paid tomorrow." % Festivals.name_of(festival_today()))
		return
	money += bin_total
	message.emit("Shipping paid %d G" % bin_total)
	bin_total = 0
	changed.emit()


## Puts every crop the farmer carries (rucksack and hand) into the shipping bin; returns
## the value added. Dishes go in only from the hand: the ones in the rucksack are lunch.
func ship_produce() -> int:
	var total := 0
	var carried := inventory.totals()
	for id in carried:
		var places: Array = ["hand"] if id.begins_with("food:") else Inventory.CARRIED
		var n := inventory.count(id, places)
		if sell_price(id) > 0 and n > 0:
			total += sell_price(id) * n
			inventory.take(id, n, places)
			_note_shipped(id, n)
	bin_total += total
	changed.emit()
	return total


## Counts `n` of `id` as shipped. The first of a kind may bring the buyer's recipe cards
## (data/recipes.json card): those recipes are learned.
func _note_shipped(id: String, n: int) -> void:
	var first := not shipped.has(id)
	shipped[id] = int(shipped.get(id, 0)) + n
	if not first:
		return
	for r in Cooking.cards(id):
		if not Cooking.known(r, flags):
			flags[Cooking.flag(r)] = true
			# Deferred, so it shows after the bin's own "Put ... G" line.
			message.emit.call_deferred("A recipe card in the bin lid: %s!" % String(foods.get(r, {}).get("name", r)))


# --- animals (data/animals.json) -------------------------------------------

## The shop's hook: one more animal of `kind` ("chicken", "cow", "sheep") into its home,
## grown unless `young` (a calf / lamb). False when the home is full or the kind unknown (the
## shop then keeps the money). Fodder for the barn: animals.add_fodder(n).
func add_animal(kind: String, young := false) -> bool:
	var ok := animals.add(kind, young)
	changed.emit()
	return ok


# --- holding and throwing ---------------------------------------------------

func holding() -> bool:
	return held != "" or animals.dog.held


## The sprite key for what is carried overhead: the held item, or the dog in the arms.
func held_key() -> String:
	return "animal:dog:held:0" if animals.dog.held else PlaceholderArt.world_item_key(held)


## What one of `id` fetches in the bin (0 = can't be shipped). Fish are "fish:<id>", dishes
## "food:<id>" (foods.json sell).
func sell_price(id: String) -> int:
	if id.begins_with("fish:"):
		return int(fish_data.get("fish", {}).get(id.trim_prefix("fish:"), {}).get("sell", 0))
	if id.begins_with("mine:"):
		return int(mine_item(id).get("sell", 0))
	if id.begins_with("food:"):
		return int(foods.get(id.trim_prefix("food:"), {}).get("sell", 0))
	return int(crops[id].get("sell", 0)) if crops.has(id) else animals.sell_price(id)


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
			_note_shipped(item, 1)
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


## A name to show for any item id: tools, crops, seed bags, food; anything else from its id.
func item_name(id: String) -> String:
	if id in TOOLS:
		return HudLayout.TOOL_NAMES.get(id, id.capitalize())
	if crops.has(id):
		return String(crops[id].name)
	if id.begins_with("seeds:") and crops.has(id.trim_prefix("seeds:")):
		return "%s seeds" % crops[id.trim_prefix("seeds:")].name
	if id.begins_with("food:") and foods.has(id.trim_prefix("food:")):
		return String(foods[id.trim_prefix("food:")].name)
	if animals.item_info(id).has("name"):
		return String(animals.item_info(id).name)
	if id.begins_with("fish:") and fish_data.get("fish", {}).has(id.trim_prefix("fish:")):
		return String(fish_data.fish[id.trim_prefix("fish:")].name)
	if mine_item(id).has("name"):
		return String(mine_item(id).name)
	if Keepsakes.name_of(id) != "":
		return Keepsakes.name_of(id)
	if id.begins_with("food:") and foods.has(id.trim_prefix("food:")):
		return String(foods[id.trim_prefix("food:")].name)
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


# --- fishing (data/fish.json, Fishing) -------------------------------------

## Is `c` water a line can go into: the farm pond, or a water tile on another map?
func is_water(c: Vector2i) -> bool:
	if maps.on_farm():
		return farm.fixed_at(c) == "pond"
	return maps.current().tile(c) == "water"


## The first water cell up to the rod's reach in front of `origin` (data/tools.json rod);
## anything else solid on the way blocks the cast. Vector2i(-1, -1) when there is none.
func water_ahead(origin: Vector2i, facing: Vector2i) -> Vector2i:
	for i in range(1, int(tools_data.get("rod", {}).get("reach", 2)) + 1):
		var c := origin + facing * i
		if is_water(c):
			return c
		if maps.is_solid(c, farm):
			break
	return Vector2i(-1, -1)


## Casts the rod from `origin` towards `facing`. Returns "cast", "hands_full" (an item
## overhead) or "no_water". A cast costs stamina.
func cast_line(origin: Vector2i, facing: Vector2i) -> String:
	if holding():
		return "hands_full"
	var spot := water_ahead(origin, facing)
	if spot == Vector2i(-1, -1):
		return "no_water"
	spend_stamina(int(tools_data.get("rod", {}).get("stamina", 2)))
	fishing.cast(maps.id, spot)
	changed.emit()
	return "cast"


## The button while the line is out. A bite hooks a fish from what fits the place, season,
## hour and weather (Fishing.candidates); it goes up overhead like a harvest. Returns
## {result: "catch" / "early" / "none", fish: "fish:<id>" or ""}.
func reel_in() -> Dictionary:
	var at := fishing.place
	var r := fishing.reel()
	var out := {"result": r, "fish": ""}
	if r == "catch":
		var look := weather_look(weather_today, season_name())
		var id := Fishing.pick(Fishing.candidates(fish_data, at, season_name(), hour, look, fish_caught), rng.randf())
		if id == "":
			out.result = "none"
		else:
			fish_caught[id] = int(fish_caught.get(id, 0)) + 1
			out.fish = "fish:" + id
			held = out.fish
	changed.emit()
	return out


# --- the mine (data/mine.json, MineFloor) ----------------------------------

const MINE_MAPS := {"entrance_map": "mine", "entrance_spawn": "cave", "floor_map": "mine_floor"}


## A name from data/mine.json: entrance_map, entrance_spawn or floor_map.
func mine_map(key: String) -> String:
	return str(mine_data.get(key, MINE_MAPS[key]))


## A mine find's data ({} for anything that isn't "mine:<id>").
func mine_item(id: String) -> Dictionary:
	return mine_data.get("items", {}).get(id.trim_prefix("mine:"), {}) if id.begins_with("mine:") else {}


## A fresh floor at `depth`, laid out from a new seed for today's season; the deepest floor
## reached goes up with it.
func new_mine_floor(depth: int) -> MineFloor:
	mine_deepest = maxi(mine_deepest, depth)
	return MineFloor.make(mine_data, MapManager.data(mine_map("floor_map")), depth, season_name(), rng.randi())


## A swing down the mine with `tool` from `origin` towards `facing` at charge step `charge`
## (data/tools.json): the hammer breaks rocks, the hoe digs soft spots, and like field work
## every swing costs stamina and fatigue and teaches the tool. Finds go into the rucksack,
## else up overhead, else they stay lying on their cell. Returns {result: "swung",
## "hands_full" or "wrong_tool"; worked, tough, hole (the way down opened), finds: [{item, to:
## "bag" / "hand" / "floor"}]}.
func mine_swing(tool: String, origin: Vector2i, facing: Vector2i, charge := 0) -> Dictionary:
	var out := {"result": "swung", "worked": false, "tough": false, "hole": false, "finds": []}
	var f := maps.mine_floor
	if f == null or not tool in ["hammer", "hoe"]:
		out.result = "wrong_tool"
		return out
	if holding():
		out.result = "hands_full"
		return out
	var rule := charge_rule(tool, charge)
	spend_stamina(int(rule.stamina))
	for c in f.area_cells(origin, facing, rule.area):
		var r: Dictionary = f.hit(c, int(rule.get("hits", 1))) if tool == "hammer" else f.dig(c)
		out.tough = out.tough or r.result == "tough"
		if r.result == "none" or r.result == "tough":
			continue
		out.worked = true
		if r.find == "stairs":
			out.hole = true
		elif r.find != "":
			var id := MineFloor.item_id(r.find)
			out.finds.append({"item": id, "to": _keep_find(id, c)})
	add_tool_exp(tool, swing_exp(out.worked or out.tough))
	changed.emit()
	return out


func _keep_find(id: String, c: Vector2i) -> String:
	if can_carry(id):
		add_item(id)
		return "bag"
	if not holding():
		held = id
		return "hand"
	maps.mine_floor.leave(c, id)
	return "floor"


## Hands free: a find lying on `c` down the mine goes up overhead. Returns its id or "".
func mine_pick_up(c: Vector2i) -> String:
	if holding() or maps.mine_floor == null:
		return ""
	var id := maps.mine_floor.take(c)
	if id != "":
		held = id
		changed.emit()
	return id


## Where a save made down the mine puts the farmer: at the cave mouth (floors are never kept).
func _mine_exit() -> Dictionary:
	var m := MapManager.data(mine_map("entrance_map"))
	var spot: Array = m.spawns[mine_map("entrance_spawn")]
	return {"id": m.id, "pos": MapManager.cell_pos(spot[0]), "facing": spot[1]}


# --- food and drink (data/foods.json) --------------------------------------

func set_food_data(data: Dictionary) -> void:
	food_data = data
	foods = data.get("foods", {})


## The food in hand ("" when there is no food data).
func current_food() -> String:
	return foods.keys()[food_index] if food_index < foods.size() else ""


## Q with the food slot: the next food the stand sells or the farmer carries (dishes from the
## kitchen and specials only show up while there are some).
func cycle_food() -> void:
	for i in foods.size():
		food_index = (food_index + 1) % foods.size()
		var id: String = foods.keys()[food_index]
		if foods[id].get("shop", false) or count("food:" + id) > 0:
			break
	changed.emit()


## What eating `item` does: a food ("food:<id>") or a raw farm good (foods.json "raw", fish:*
## for any fish), with its name; {} when it can't be eaten.
func food_info(item: String) -> Dictionary:
	if item.begins_with("food:"):
		return foods.get(item.trim_prefix("food:"), {})
	var raw: Dictionary = food_data.get("raw", {})
	var f: Dictionary = raw.get(item, raw.get("fish:*", {}) if item.begins_with("fish:") else {})
	if f.is_empty():
		return {}
	var out := f.duplicate()
	out.name = item_name(item)
	return out


func edible(item: String) -> bool:
	return not food_info(item).is_empty()


## Eats (or drinks) one food `id` (data/foods.json) from the bag; see eat_item.
func eat(id: String) -> bool:
	return eat_item("food:" + id).ok


## Eats (or drinks) one `item` from `places`: stamina up to the max, fatigue down, and the
## specials (a higher max stamina, half swing fatigue for the day). A food that would do
## nothing is kept. Returns {ok, note}; says the note either way.
func eat_item(item: String, places: Array = Inventory.CARRIED) -> Dictionary:
	var f := food_info(item)
	var name := String(f.get("name", item_name(item))).to_lower()
	if f.is_empty():
		return _ate(false, "You can't eat the %s" % name)
	if inventory.count(item, places) == 0:
		return _ate(false, "No %s left" % name)
	var grow := mini(int(f.get("max_stamina", 0)), maxi(int(food_data.get("max_stamina_cap", 200)) - max_stamina, 0))
	var half := bool(f.get("work_fatigue_half", false)) and not work_fatigue_half
	var lowers := int(f.get("fatigue", 0)) < 0 and fatigue > 0
	if stamina >= max_stamina and not lowers and grow == 0 and not half:
		return _ate(false, String(food_data.get("full_message", "You're full.")))
	inventory.take(item, 1, places)
	max_stamina += grow
	stamina = clampi(stamina + int(f.get("stamina", 0)), 0, max_stamina)
	add_fatigue(int(f.get("fatigue", 0)))
	work_fatigue_half = work_fatigue_half or half
	_shown_state = body_state()   # feeling better: a later tired state is told again
	var text := "You %s the %s." % ["drank" if f.get("drink", false) else "ate", name]
	var special := String(f.get("special_message", ""))
	if special != "" and (grow > 0 or half):
		text += " " + (special % grow if "%d" in special else special)
	changed.emit()
	return _ate(true, text)


func _ate(ok: bool, note: String) -> Dictionary:
	message.emit(note)
	return {"ok": ok, "note": note}


## Sound key for eating food `id`: "drink" or "eat" (both in data/sfx.json).
func eat_sound(id: String) -> String:
	return item_sound("food:" + id)


## Sound key for eating any edible `item`.
func item_sound(item: String) -> String:
	return "drink" if food_info(item).get("drink", false) else "eat"


# --- cooking (data/recipes.json, Cooking) ----------------------------------

## E at the kitchen corner's stove or cupboard: the cooking screen, once the kitchen is built.
func open_cooking() -> bool:
	if not has_built("kitchen"):
		message.emit("There's no kitchen here yet")
		return false
	cooking_requested.emit()
	return true


## Cooks recipe `id` once (Cooking.cook): needs the kitchen, the recipe known and its kitchen
## tools owned (kitchen_tools); the
## ingredients come from the rucksack, the hand and the chest, the dishes go into the
## rucksack. Returns {ok, note}.
func cook(id: String) -> Dictionary:
	var name := String(foods.get(id, {}).get("name", id))
	if not has_built("kitchen"):
		return {"ok": false, "note": "There's no kitchen here yet"}
	if not Cooking.known(id, flags):
		return {"ok": false, "note": "You don't know how to make that yet"}
	var lack := Cooking.missing_tools(id, kitchen_tools)
	if not lack.is_empty():
		var names := lack.map(func(t: String) -> String: return Cooking.a_tool(t))
		return {"ok": false, "note": "You need %s for that" % " and ".join(names)}
	var r := Cooking.cook(id, inventory)
	changed.emit()
	match r.result:
		"cooked":
			var n := Cooking.makes(id)
			return {"ok": true, "note": "Made %s%s" % [name.to_lower(), " x%d" % n if n > 1 else ""]}
		"missing":
			return {"ok": false, "note": "Not enough to make %s" % name.to_lower()}
		"full":
			return {"ok": false, "note": "No room in the rucksack for it"}
	return {"ok": false, "note": "No such recipe"}


# --- the ending (data/ending.json, Ending) -----------------------------------

const FIELD_TOOLS: Array[String] = ["hoe", "can", "sickle", "hammer", "axe"]
const START_MONEY := 500

## What every new game measures before any work: nothing, and the recipes known from the start.
func start_values() -> Dictionary:
	var v := {}
	for m in Ending.MEASURES:
		v[m] = 0
	v.recipes_known = Cooking.known_ids({}).size()
	return v


## The numbers the village record grades (Ending.MEASURES), measured from this run.
func ending_values() -> Dictionary:
	var value := 0
	var kinds := 0
	for id in shipped:
		value += int(shipped[id]) * sell_price(id)
		if crops.has(id):
			kinds += 1
	var cared := 0
	for a in animals.list:
		if int(a.happy) * 2 >= animals.happy_max():
			cared += 1
	var hearts := 0
	for id in Villagers.all():
		hearts += affection.band(id)
	var levels := 0
	for t in FIELD_TOOLS:
		levels += maxi(int(tool_levels.get(t, 1)) - 1, 0)
	return {"shipped_value": value, "crop_kinds": kinds, "animal_care": cared, "heart_bands": hearts,
		"mine_deepest": mine_deepest, "fish_kinds": fish_caught.size(), "house_built": house_built.size(),
		"tool_levels": levels, "contest_wins": int(flags.get("contest_wins", 0)),
		"recipes_known": Cooking.known_ids(flags).size()}


## The field's numbers for the record's look back (Ending.FIELD_MEASURES).
func field_counts() -> Dictionary:
	var debris := 0
	var tilled := 0
	for d in farm.cells:
		if int(d.obj) != FarmGrid.Obj.NONE:
			debris += 1
		if d.tilled:
			tilled += 1
	return {"debris": debris, "tilled": tilled, "money": money}


## The record for this run (Ending.grade).
func ending_record(values := ending_values()) -> Dictionary:
	var points := {}
	for id in Villagers.all():
		points[id] = affection.of(id)
	return Ending.grade(values, points)


## The `ending` event step: grades the run, puts the first day and the last page beside it
## (Ending.compare), writes this year's page (year_pages), sets the flags the lines branch on
## (ending_rank_<n>, ending_friend_<id>, record_first for year 2's first page, record_more with
## more stars than it; earlier ones cleared, record_due too) and opens the EndingScreen.
## `page`: "ending" (year 3, the full record) or "year" (the yearly page).
## ending_open stays true until the screen is closed; with no screen it never opens.
func show_ending(page := "ending") -> Dictionary:
	var values := ending_values()
	var field := field_counts()
	var r := Ending.compare(ending_record(values), first_day, Ending.last_page(year_pages, year), field)
	r.page = page
	r.year = year
	year_pages[year] = Ending.page_of(year, values, field, r)
	for k in flags.keys():
		if String(k).begins_with("ending_rank_") or String(k).begins_with("ending_friend_") \
				or k in ["record_due", "record_first", "record_more"]:
			flags.erase(k)
	flags["ending_rank_%d" % r.rank] = true
	flags["ending_friend_" + r.friend] = true
	if r.first and year <= 2:
		flags["record_first"] = true
	elif not r.first and r.gained_stars > 0:
		flags["record_more"] = true
	if not ending_requested.get_connections().is_empty():
		ending_open = true
		ending_requested.emit(r)
	return r


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

## Every tool with levels back to level 1 with no experience (a new game).
func reset_tool_levels() -> void:
	tool_levels = {}
	tool_exp = {}
	for tool in leveled_tools():
		tool_levels[tool] = 1
		tool_exp[tool] = 0


## The tools that have levels: the charging tools (data/tools.json), then the rod, whose
## levels are bite factors in data/fish.json (raised only by the smithy, no experience).
func leveled_tools() -> Array[String]:
	var out: Array[String] = []
	out.assign(tools_data.get("tools", {}).keys())
	if not rod_rule().get("bite_factor", []).is_empty():
		out.append("rod")
	return out


func rod_rule() -> Dictionary:
	return fish_data.get("rod", {})


## How much the rod's level multiplies the bite chance (1 without levels).
func rod_bite_factor() -> float:
	var f: Array = rod_rule().get("bite_factor", [])
	return float(f[tool_level("rod") - 1]) if f.size() > 0 else 1.0


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
	if not tools_data.get("tools", {}).has(tool) or tool_max_level(tool) == 0 or amount <= 0:
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
	var rule: Dictionary = tools_data.tools.get(tool, rod_rule() if tool == "rod" else {})
	message.emit(String(rule.get("level_up", "Tool level %d!")) % (lv + 1))
	changed.emit()
	return true


## How many levels a tool has (0 for one without levels, like the seed bag).
func tool_max_level(tool: String) -> int:
	if tool == "rod":
		return rod_rule().get("bite_factor", []).size()
	return tools_data.get("tools", {}).get(tool, {}).get("max_charge", []).size()


func tool_level(tool: String) -> int:
	return clampi(int(tool_levels.get(tool, 1)), 1, maxi(tool_max_level(tool), 1))


## The highest charge step the tool's level allows (0 = taps only).
func max_charge(tool: String) -> int:
	if not tools_data.get("tools", {}).has(tool) or tool_max_level(tool) == 0:
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


## E facing villager `id` (Talk.facing_villager) from the farmer's side `face` (the way the
## villager turns): an item overhead is a gift, a keeper at their counter opens the shop,
## anyone else says a line picked for now (Talk.pick). Returns "gift", "shop" or "talk".
func talk_to(id: String, face: Vector2i) -> String:
	var t := day_minutes()
	var today := day_number()
	Villagers.turn(id, face, t)
	var file := Talk.dialogue_id(id)
	var birthday := Villagers.has_birthday(id, season_name(), day)
	if holding():
		var r := affection.give(id, held, today, birthday)
		if r.ok:
			inventory.take(held, 1, ["hand"])   # one of a stack in hand (dishes come several at a time)
			changed.emit()
		var answer := "gift_" + str(r.reaction)
		if birthday and r.reaction in ["love", "like", "neutral"] and Talk.has_line(id, "gift_birthday"):
			answer = "gift_birthday"   # glad of being remembered; a bad gift still answers as it is
		talk(file, answer)
		return "gift"
	var w := Villagers.where(id, t, trigger_state(Vector2i.ZERO))
	var shop_id := Talk.keeper_shop(id, maps.id, Vector2i(w.get("pos", Vector2(-1, -1)).floor()))
	var s := trigger_state(Vector2i.ZERO)
	s.merge({"band": affection.band(id), "again": affection.talked_on(id, today), "day_number": today, "birthday": birthday})
	affection.talk(id, today)
	if shop_id != "" and open_shop(shop_id):
		return "shop"
	var at := Talk.pick(id, s)
	if at != "":
		talk(file, at)
	return "talk"


## The heart band (0 .. 6) the text box shows for `speaker`, or -1 when the speaker isn't a
## villager (the farmer, narration, people without a villager file).
func heart_band(speaker: String) -> int:
	return affection.band(speaker) if Villagers.all().has(speaker) else -1


## Is a villager in the way of the farmer stepping from `from` to `to` (cell pixels)?
func villager_in_way(from: Vector2, to: Vector2) -> bool:
	return Villagers.blocks(maps.id, day_minutes(), trigger_state(Vector2i.ZERO), from / 16.0, to / 16.0)


## Plays event `id` (data/events/<id>.json) in the view's EventPlayer.
func play_event(id: String) -> void:
	event_requested.emit(id)


# --- shops (data/shops.json; rules in Shop) ----------------------------------

## The shop `id` with this game's crop and food data, or null.
func shop(id: String) -> Shop:
	if id.begins_with(Festivals.STALL_PREFIX):   # a festival stall (data/festivals.json stall)
		return Shop.make(id, crops, foods, Festivals.stall_shop_data(id))
	return Shop.make(id, crops, foods) if id != "" else null


## The counter (and later its keeper's talk) opens the shop's screen, or says it is closed.
## `force` skips the hours (the `--shop=<id>` screenshot flag). Returns true when it opened.
func open_shop(id: String, force := false) -> bool:
	var s := shop(id)
	if s == null:
		return false
	if not force and _shop_shut(s):
		return false
	# A shop with a keeper sells only while they are in (their day plan puts them at the counter).
	if not force and s.keeper != "" and not Villagers.is_on(s.keeper, s.map, day_minutes(), trigger_state(Vector2i.ZERO)):
		message.emit(keeper_away_text(s))
		return false
	shop_requested.emit(id)
	return true


## What the counter of shop `s` says while its keeper is out: the builder's note while they
## are at work on the farm (data/shops.json builds away), else that nobody is there.
func keeper_away_text(s: Shop) -> String:
	var b := shop(str(house_job.get("shop", ""))) if flags.has(BUILD_FLAG) else null
	if b != null and b.builder == s.keeper and b.builds.has(house_job.build):
		var what := b.item_name(house_job.build).to_lower()
		if int(house_job.get("late", 0)) > 0:
			return b.build_away_late % [what, date_of(int(house_job.ready)).get_slice(",", 0)]
		return b.build_away % what
	return "Nobody is at the counter"


## Is shop `s` shut now (its hours, its day off, or a festival that closes it)? Says why.
func _shop_shut(s: Shop) -> bool:
	var fest := festival_today()
	if Festivals.closes(fest, s.id):
		message.emit("%s is closed today for %s." % [s.name, Festivals.name_of(fest)])
		return true
	if not s.is_open(hour, weekday()):
		message.emit(s.closed_text())
		return true
	return false


## The villagers whose birthday is today (data/villagers birthday), sorted.
func birthdays_today() -> Array[String]:
	return Villagers.birthdays_on(season_name(), day)


## Today's festival id (data/festivals.json), or "".
func festival_today() -> String:
	return Festivals.on_date(season_name(), day)


## The festival going on around the farmer now (today's, in its hours, on its map), or "".
func festival_now() -> String:
	var id := festival_today()
	return id if id != "" and Festivals.on_now(id, maps.id, hour * 60 + minute) else ""


## Is the shipping payout held back today (a festival day)?
func payout_held() -> bool:
	return festival_today() != ""


# --- festival contests and stalls (data/festivals.json; rules in Festivals) ---

## What kind of entry `id` is for a contest: "crop", "fish", "mine", "animal" (eggs, milk,
## wool) or "" for anything else (seeds, food, tools).
func item_kind(id: String) -> String:
	if id.begins_with("fish:"):
		return "fish"
	if id.begins_with("mine:"):
		return "mine"
	if crops.has(id):
		return "crop"
	return "animal" if animals.sell_price(id) > 0 else ""


## E at today's judges' table (Festivals.at_table) during the festival. Empty-handed the judge
## says what the contest takes; with an entry of the right kind overhead it is handed in and
## judged at once (Festivals.judge): the prize is paid, the flags for the result lines are set
## and the contest's event plays. One entry a year. Returns Festivals.judge's result with ok,
## or {ok: false, why: "none" | "entered" | "ask" | "kind"}.
func enter_contest() -> Dictionary:
	var fid := festival_now()
	var c := Festivals.contest(fid)
	if c.is_empty():
		return {"ok": false, "why": "none"}
	if events_seen.has(Festivals.entered_key(fid, year)):
		message.emit("You already entered the %s this year." % c.name)
		return {"ok": false, "why": "entered"}
	if held == "":
		talk(Festivals.DIALOGUE, c.ask)
		return {"ok": false, "why": "ask"}
	if item_kind(held) != c.takes:
		message.emit("The %s only takes %s." % [c.name, {"crop": "crops", "fish": "fish", "animal": "eggs, milk or wool", "mine": "ores and stones from the mine"}[c.takes]])
		return {"ok": false, "why": "kind"}
	var item := held
	var seasons: Array = crops.get(item, {}).get("seasons", [])
	var r := Festivals.judge(fid, year, Festivals.entry_score(fid, seasons, sell_price(item)))
	r.ok = true
	r.item = item
	held = ""
	events_seen[Festivals.entered_key(fid, year)] = true
	for k in flags.keys():
		if k.begins_with("contest_place_") or k.begins_with("contest_won_") or k == "contest_prize":
			flags.erase(k)
	flags["contest_place_%d" % r.place] = true
	if r.winner != "farmer":
		flags["contest_won_" + r.winner] = true
	if r.place == 1:
		flags["contest_wins"] = int(flags.get("contest_wins", 0)) + 1
	_pay_prize(r.prize)
	_give_ribbon(fid, r.place)
	changed.emit()
	play_event(c.event)
	return r


## A ribbon for placing (Keepsakes.ribbon_id; none below the last place) into the rucksack,
## and noted on the farmhouse board's record even when the rucksack is full.
func _give_ribbon(fid: String, place: int) -> void:
	var ribbon := Keepsakes.ribbon_id(fid, place)
	if ribbon == "":
		return
	Keepsakes.note(flags, fid, place, year)
	if add_item(ribbon) == 0:
		message.emit("You got a %s!" % item_name(ribbon))
	else:
		message.emit("No room in the rucksack for the ribbon. It is on the board at home.")


func _pay_prize(prize: Dictionary) -> void:
	if prize.is_empty():
		return
	flags["contest_prize"] = true
	var got: Array[String] = []
	if int(prize.get("money", 0)) > 0:
		add_money(int(prize.money))
		got.append("%d G" % int(prize.money))
	if prize.has("item"):
		var n := int(prize.get("count", 1))
		var left := add_item(prize.item, n)
		if left < n:
			got.append(("%d x %s" % [n - left, item_name(prize.item)]) if n - left > 1 else item_name(prize.item))
		if left > 0:
			message.emit("No room in the rucksack for the rest of the prize")
	message.emit("Prize: " + " and ".join(got))


## E at one of today's festival stalls (Festivals.stall_at: its shop id; "" = the first)
## while the festival is on opens it as a shop.
func open_stall(shop_id := "") -> bool:
	var fid := festival_now()
	var list := Festivals.stalls(fid)
	if shop_id == "" and not list.is_empty():
		shop_id = Festivals.stall_shop_id(fid, list[0])
	var fs := Festivals.stall_of(shop_id)
	if fid == "" or fs[0] != fid or fs[1].is_empty():
		return false
	shop_requested.emit(shop_id)
	return true


## Buys `n` of `item` at shop `id`: the next rucksack ("rucksack"), goods into the rucksack,
## animals into their home (add_animal; "animal:<kind>:young" = a chick / calf / lamb), feed
## into the coop's sack, fodder into the barn's loft.
func shop_buy(id: String, item: String, n := 1) -> Dictionary:
	var s := shop(id)
	if item == "rucksack":
		return _shop_paid(s.buy_rucksack(inventory, money))
	if item.begins_with("kitchen:"):
		var k := s.buy_kitchen_tool(money, item.trim_prefix("kitchen:"), kitchen_tools, house_built)
		if k.ok:
			kitchen_tools.append(k.tool)
		return _shop_paid(k)
	var r := s.buy(inventory, money, item, n, season_name(), shop_room(id, item))
	if r.ok and r.to == "animal":
		var a := Shop.animal_of(item)
		for i in n:
			add_animal(a.kind, a.young)
	elif r.ok and r.to == "feed":
		animals.add_feed(n)
	elif r.ok and r.to == "fodder":
		animals.add_fodder(n)
	return _shop_paid(r)


## How many of `item` from shop `id` there is room for: in the rucksack, in the animal's home
## (0 for a kind the game doesn't know), any amount of feed or fodder.
func shop_room(id: String, item: String) -> int:
	match str(shop(id).entry(item).get("to", "rucksack")):
		"animal":
			var kind := animals.kind_rule(Shop.animal_of(item).kind)
			return maxi(animals.room(kind.get("home", "")), 0) if not kind.is_empty() else 0
		"feed", "fodder":
			return ShopMenu.MOST
	return inventory.room_for(item)


## Orders house extension `build` at shop `id` (Shop.start_build); one at a time, saved.
func shop_build(id: String, build: String) -> Dictionary:
	var r := shop(id).start_build(money, build, house_built, house_job, day_number())
	if r.ok:
		house_job = r.job
		house_job.shop = id
	return _shop_paid(r)


## Sets BUILD_FLAG to the job's id while it is under way (the day after it was ordered up to
## its ready day), clears it otherwise. The builder's day plan and the lumber follow the flag.
func sync_build_flag() -> void:
	var s := shop(str(house_job.get("shop", ""))) if not house_job.is_empty() else null
	var b: Dictionary = s.builds.get(house_job.build, {}) if s != null else {}
	if not b.is_empty() and day_number() > int(house_job.ready) - int(b.days) - int(house_job.get("late", 0)):
		flags[BUILD_FLAG] = house_job.build
	else:
		flags.erase(BUILD_FLAG)


## Does a solid prop of the farm map (data/maps/farm.json, the ones its story flags show)
## stand on cell `c`? FarmGrid.prop_blocks: the farmer, the dog and throws stop at it.
func farm_prop_blocks(c: Vector2i) -> bool:
	var m := MapManager.data(MapManager.FARM)
	return m != null and m.in_bounds(c) and m.is_solid(c)


## Today was a day of the job under way (BUILD_FLAG set) but the builder's day plan was not
## his building one (data/shops.json builds plan): a storm kept him at the forge, or his
## birthday. Such a day doesn't count: the job is due a day later and `late` counts the lost
## days (saved; the counter's note and the build tab say so).
func _count_build_day() -> void:
	if not flags.has(BUILD_FLAG) or house_job.is_empty():
		return
	var s := shop(str(house_job.get("shop", "")))
	var v: Dictionary = Villagers.all().get(s.builder, {}) if s != null else {}
	if v.is_empty() or s.build_plan == "" or Villagers.pick_plan(v, trigger_state(Vector2i.ZERO)) == s.build_plan:
		return
	house_job.ready = int(house_job.ready) + 1
	house_job.late = int(house_job.get("late", 0)) + 1


func has_built(build: String) -> bool:
	return build in house_built


## The shop that builds extension `build` ("" when none does).
func _builder_shop(build: String) -> String:
	for sid in Shop.ids():
		if shop(sid).builds.has(build):
			return sid
	return ""


## An extension is done: it counts as built, its extras come in (a bigger chest), the maps
## change (MapManager.built); the views see it on the next map change (waking up at home).
func _finish_build(job: Dictionary) -> void:
	var s := shop(str(job.get("shop", "")))
	if s == null or not s.builds.has(job.build):
		return
	if not job.build in house_built:
		house_built.append(job.build)
	var b: Dictionary = s.builds[job.build]
	if b.has("chest_slots"):
		inventory.grow("chest", int(b.chest_slots))
	if house_job.get("build", "") == job.build:
		house_job = {}
	sync_build_flag()
	MapManager.set_built(house_built)
	message.emit(s.build_done % s.item_name(job.build).to_lower())
	changed.emit()


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
		"seen": events_seen, "cell": cell, "hearts": affection.bands(),
		"festival": festival_today()}


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
	if maps.id == mine_map("floor_map"):
		var out := _mine_exit()
		d.map = {"id": out.id, "x": roundi(out.pos.x), "y": roundi(out.pos.y), "facing": [out.facing.x, out.facing.y]}
	d.shipped = shipped.duplicate()
	d.shop_jobs = shop_jobs.duplicate(true)
	d.house = {"built": house_built.duplicate(), "job": house_job.duplicate()}
	d.kitchen_tools = kitchen_tools.duplicate()
	d.animals = animals.to_dict()
	d.fishing = {"caught": fish_caught.duplicate(), "dry_casts": fishing.dry_casts}
	d.affection = affection.to_dict()
	d.mine = {"deepest": mine_deepest}
	var pages := []
	for y in year_pages:
		pages.append(year_pages[y].duplicate(true))
	pages.sort_custom(func(a, b): return a.year < b.year)
	d.records = {"first_day": first_day.duplicate(true), "pages": pages}
	d.farm = farm.to_dict()
	return d


## Puts a saved state back and redraws through the usual signals. Returns "" or what was
## wrong; everything is checked first, so on a problem nothing changes.
func from_dict(data: Dictionary, version := SaveGame.VERSION) -> String:
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
	for tool in leveled_tools():   # saves from before rod levels: the rod at level 1
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
			var steps: Array = tools_data.tools.get(tool, {}).get("exp_to_level", [])
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
	# Saves from before house extensions have none built and none ordered.
	var saved_house = data.get("house", {"built": [], "job": {}})
	if not saved_house is Dictionary or not saved_house.get("built") is Array or not saved_house.get("job") is Dictionary:
		return "Saved house is broken"
	n.house_built = [] as Array[String]
	for b in saved_house.built:
		if not b is String or _builder_shop(b) == "" or b in n.house_built:
			return "Saved house is broken"
		n.house_built.append(b)
	n.house_job = {}
	var hj: Dictionary = saved_house.job
	if not hj.is_empty():
		var hs := shop(hj.get("shop")) if hj.get("shop") is String else null
		var ready = SaveGame.whole(hj.get("ready"), 0, 1 << 40)
		var late = SaveGame.whole(hj.get("late", 0), 0, 9999)   # saves from before lost days: none
		if hs == null or not hj.get("build") is String or not hs.builds.has(hj.build) or hj.build in n.house_built 				or ready == null or late == null:
			return "Saved house is broken"
		n.house_job = {"build": hj.build, "shop": hj.shop, "ready": ready}
		if late > 0:
			n.house_job.late = late
	# Version 5 added kitchen tools; an older kitchen gets the tools of the recipes it knows, so
	# whatever it cooked before still cooks.
	n.kitchen_tools = [] as Array[String]
	if version >= 5 or data.has("kitchen_tools"):
		var saved_kit = data.get("kitchen_tools", [])
		if not saved_kit is Array:
			return "Saved kitchen tools are broken"
		for t in saved_kit:
			if not t is String or Cooking.tool_info(t).is_empty() or t in n.kitchen_tools:
				return "Saved kitchen tools are broken"
			n.kitchen_tools.append(t)
	elif "kitchen" in n.house_built:
		n.kitchen_tools = Cooking.tools_for(Cooking.known_ids(n.flags))
	# Saves from before maps load on the farm, in front of the house door.
	var place := {"id": MapManager.FARM, "pos": MapManager.new().pos, "facing": Vector2i.DOWN}
	if data.has("map"):
		var r := MapManager.check_saved(data.map, n.house_built)
		if r[0] != "":
			return r[0]
		place = r[1]
		if place.id == mine_map("floor_map"):
			place = _mine_exit()
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
	# Version 2 added the animals; older saves start with the new-game flock.
	var flock := Animals.new()
	if version >= 2 or data.has("animals"):
		var parsed_animals := Animals.parse(data.get("animals"), Animals.data(), version)
		if parsed_animals[0] != "":
			return parsed_animals[0]
		flock = parsed_animals[1]
	else:
		flock.start()
	n.animals = flock
	n.animal_news = [] as Array[String]
	# Saves from before fishing: nothing caught, and the rod goes in a free tool slot (else the chest).
	var saved_fishing = data.get("fishing", {"caught": {}, "dry_casts": 0})
	if not saved_fishing is Dictionary or not saved_fishing.get("caught") is Dictionary:
		return "Saved fishing is broken"
	n.fish_caught = {}
	for id in saved_fishing.caught:
		var c = SaveGame.whole(saved_fishing.caught[id], 1, 1 << 50)
		if not id is String or id == "" or c == null:
			return "Saved fishing is broken"
		n.fish_caught[id] = c
	var dry = SaveGame.whole(saved_fishing.get("dry_casts"), 0, 9999)
	if dry == null:
		return "Saved fishing is broken"
	if not data.has("fishing") and n.inventory.count("rod", ["tools", "chest"]) == 0:
		n.inventory.add("rod", 1, ["tools", "chest"])
	# Version 3 added affection; older saves start with everyone a stranger.
	var friends := Affection.new()
	if version >= 3 or data.has("affection"):
		var parsed_friends := Affection.parse(data.get("affection"))
		if parsed_friends[0] != "":
			return parsed_friends[0]
		friends = parsed_friends[1]
	n.affection = friends
	# Saves from before the mine: no floor reached yet.
	var saved_mine = data.get("mine", {"deepest": 0})
	n.mine_deepest = SaveGame.whole(saved_mine.get("deepest") if saved_mine is Dictionary else null, 0, 9999)
	if n.mine_deepest == null:
		return "Saved mine is broken"
	# Saves from before the yearly pages: no page written yet, and of the first day only what
	# every new game starts with is known (the field's debris and tilling show as "-").
	n.first_day = {"values": start_values(), "field": {"money": START_MONEY}}
	n.year_pages = {}
	if data.has("records"):
		var rec = data.records
		if not rec is Dictionary or not rec.get("pages") is Array:
			return "Saved records are broken"
		var kept := Ending.parse_kept(rec.get("first_day"), false)
		if kept[0] != "":
			return "Saved records are broken"
		n.first_day = kept[1]
		for p in rec.pages:
			var pg := Ending.parse_kept(p, true)
			if pg[0] != "" or n.year_pages.has(pg[1].year):
				return "Saved records are broken"
			n.year_pages[pg[1].year] = pg[1]
	if not data.get("farm") is Dictionary:
		return "Saved farm is missing"
	var err := farm.from_dict(data.farm)
	if err != "":
		return err
	farm.add_missing_fixed()   # saves from before the storage chest / the coop / the barn get them
	for key in n:
		set(key, n[key])
	sync_build_flag()
	MapManager.set_built(house_built)
	MapManager.set_flags(flags)
	fishing = Fishing.new(fish_data)
	fishing.dry_casts = dry
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


## The game actions and their keys: the player's own from the settings, else the defaults in
## data/controls.json.
func _setup_input() -> void:
	(settings.controls if settings != null else Controls.make()).apply()
