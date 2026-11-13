extends SceneTree
## A playtest bot: plays year 1 (and with --years=2 on to year 3's first morning, when the
## village record is written) through the real game rules: Game's clock, weather, money,
## stamina, fatigue, sleep and collapse; the field through FarmActions.use_tool (the same
## path as a key press) and Game.pick_up; the shops (Game.open_shop, shop_buy, shop_upgrade,
## shop_collect, shop_build, shop_sell, with their hours, days off and keepers); the coop and
## the barn (Animals); the mine (Game.go_to_map, mine_swing, eat_item); fishing at the pond and
## the river (Fishing, cast_line, reel_in); cooking (Game.cook); talks and gifts
## (Game.talk_to); festivals and contests (Game.enter_contest); and the maps' event trigger tables, played by a small headless
## EventPlayer (heart events, recipe lessons, the radio, the contests' results, the ending).
##
## It follows a plain plan (the constants below, ours, not game rules): plots of 3 x 3 near the
## house, cleared, tilled, sown and watered by season as the tools allow; harvests shipped;
## the coop's hens fed and their eggs shipped, a cow and a sheep bought later; the mine on
## rest days (rain, and winter) for the smithy's ores; tool upgrades at the smithy; the
## kitchen ordered and its tools bought, profitable dishes cooked and shipped (a few filling
## ones kept for the mine, with the stand's food bought on top); the evening's fishing where a
## bite pays more on average (the river or the farm pond); the wild things of the areas walked
## through picked (data/forage.json), with a round of Kaminoda and the hill on dry days the mine
## doesn't take; a daily round of
## the village with a talk and the best gift carried for everyone met; the four contests
## entered with the best thing kept for them. Stamina is spent only while it lasts (food when
## it runs low), and bedtime is 22:00. It walks without a path finder: walking time is the
## straight (x + y) distance at the farmer's running pace (walking when exhausted).
##
## Prints a report per season (income by source, costs, money, collapses, tool levels, the
## upgrades waiting for ores, affection) and at the end the village record's values and grade.
## Compare with `python -I tools/balance.py`. The save slot is kept as it was.
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/play_year.gd
##   ... -- --years=2 --seed=7    (on to year 3's first morning; another rng seed)

const GameRules := preload("res://scripts/autoload/game.gd")   # SECONDS_PER_MINUTE, DAYS_PER_SEASON, SEASONS
const BED_HOUR := 22
const MINE_FATIGUE := 75           # fatigue: up out of the mine (a collapse is at 100)
const RESERVE := 400               # G kept back for seeds and food when buying goals
const EAT_BELOW := 25              # stamina: eat something before working on
const KEEP_STAMINA := 6            # never swing below this (a swing costs up to 10)
const GIFT_STOCK := 3              # of each giftable item kept back from the bin
const MINE_PACK := 150             # stamina of food carried down the mine
const MINE_DISH_STAMINA := 40      # dishes this filling are kept for the mine...
const MINE_DISH_KEEP := 3          # ...this many of each in the chest
const FISH_UNTIL := 20 * 60        # the evening's fishing ends at 20:00
const RIVER_SHORE := Vector2i(8, 5)   # data/maps/river.json "shore": the water is the row below
const PLOT_X: Array[int] = [1, 5, 9, 13, 17, 21, 25]   # plots' left columns (3 wide, a path between)
const PLOT_Y: Array[int] = [8, 12, 16]                 # plots' top rows (3 tall, a path above)
## Plots kept planted by the can's level (watering is the day's biggest stamina cost).
const PLOTS_BY_CAN := {1: 4, 2: 7, 3: 10, 4: 14, 5: 18}
## Crops by season, best first: the bot sows the first one that can still ripen this season.
const CROPS := {
	"spring": ["potato", "turnip", "cucumber"],
	"summer": ["corn", "onion", "tomato", "rice"],
	"fall": ["pumpkin", "daikon", "carrot", "rice", "eggplant"],
}
## Goals bought in order once the money (and an upgrade's ores) are there, from [season, day]
## of year 1: [from, kind, what, how many].
const GOALS := [
	[[0, 1], "rucksack", "", 1], [[0, 1], "upgrade", "can", 2], [[0, 1], "upgrade", "hoe", 2],
	[[0, 18], "animal", "animal:chicken", 2], [[0, 20], "build", "chest", 1],
	[[1, 1], "build", "kitchen", 1], [[1, 5], "kitchen", "", 6], [[1, 10], "animal", "animal:cow", 1],
	[[1, 12], "upgrade", "sickle", 2], [[1, 15], "upgrade", "can", 3], [[1, 20], "animal", "animal:chicken", 2],
	[[2, 1], "animal", "animal:sheep", 1], [[2, 5], "rucksack", "", 1], [[2, 10], "upgrade", "hammer", 2],
	[[2, 15], "animal", "animal:cow", 1], [[2, 20], "build", "room", 1],
	[[3, 1], "upgrade", "hoe", 3], [[3, 5], "upgrade", "can", 4], [[3, 10], "upgrade", "axe", 2],
	[[3, 15], "upgrade", "hammer", 3], [[3, 20], "upgrade", "rod", 2],
]
const SOURCES: Array[String] = ["crops", "dishes", "animals", "fish", "forage", "mine", "prizes"]
const COSTS: Array[String] = ["seeds", "food", "feed", "animals", "tools", "house", "kitchen", "medicine", "doctor"]

var g: Node
var _actions: GDScript               # FarmActions and the Player's speeds, loaded late (they use the Game autoload)
var _player: Dictionary
var _today := 0                    # the day number being played (a collapse ends it early)
var _owed := 0.0                   # walking minutes not yet ticked
var _goals: Array = []
var _events: Array[String] = []    # events asked for by the game (Game.event_requested), played after
var _played: Array[String] = []    # every event played, in order
var _waits: Dictionary = {}        # "upgrade can 2" -> why it waits (ores short), this season
var _row: Dictionary = {}          # this season's report row
var _rows: Array[Dictionary] = []
var _knocked := 0                  # collapses and pass-outs this season
var _bugs: Array[String] = []      # checks the bot makes along the way that failed
var _seed := 1
var _years := 1


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			_seed = a.trim_prefix("--seed=").to_int()
		elif a.begins_with("--years="):
			_years = clampi(a.trim_prefix("--years=").to_int(), 1, 2)


var _frame := 0


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		var keep := FileAccess.get_file_as_string(SaveGame.slot()) if FileAccess.file_exists(SaveGame.slot()) else ""
		_run()
		if keep != "":
			var f := FileAccess.open(SaveGame.slot(), FileAccess.WRITE)
			f.store_string(keep)
			f.close()
		elif FileAccess.file_exists(SaveGame.slot()):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.slot()))
		quit(1 if not _bugs.is_empty() else 0)
	return false


# --- the run -------------------------------------------------------------------

func _run() -> void:
	g = root.get_node("Game")
	_actions = load("res://scripts/farm_actions.gd")
	_player = load("res://scripts/player/player.gd").get_script_constant_map()
	g.rng.seed = _seed
	g.new_game()
	g.clock_running = false   # the bot ticks the clock itself (Game._tick_minute)
	g.message.connect(_on_message)
	g.event_requested.connect(func(id: String) -> void: _events.append(id))
	_goals = GOALS.duplicate(true)
	_new_row()
	print("play_year: seed %d, %d year(s)" % [_seed, _years])
	_check("day_start")
	while true:
		_today = g.day_number()
		var season: int = g.season
		_play_day()
		if g.day_number() == _today:
			_go_to_bed()
		if g.season != season or g.year > 1 + _years - 1 and g.season == 0 and g.day == 1:
			_end_row(season)
			_save_round_trip()
			_new_row()
		_check("day_start")   # in the farmhouse (the ending and the yearly page play here)
		_play_events()
		if g.year > _years:
			break
	_final_report()


## One day from waking up to going to bed (or a collapse).
func _play_day() -> void:
	if g.weekday() == "sat":
		_check("examine", {"spot": Vector2i(6, 1)})   # the radio (a recipe on Saturdays)
	_leave_house()
	if not _alive():
		return
	_eat_if_low()
	_animals_morning()
	if not _alive():
		return
	var fest: String = g.festival_today()
	var rest_day: bool = g.weather_today == "rain" or g.season_name() == "winter"
	_field(false)
	if not _alive():
		return
	if fest != "":
		_festival(fest)
	else:
		_village_round()
		if _alive() and rest_day and g.hour < 15:
			_mine_trip()
		elif _alive() and g.hour < 14:
			_hill_round()
	if not _alive():
		return
	if g.season_name() != "winter":
		_field(true)   # clearing and new plots with what stamina is left
	if _alive() and g.hour < 19 and g.stamina > 20:
		_fish(FISH_UNTIL - g.hour * 60 - g.minute, _fish_place())
	if _alive():
		_evening()


func _alive() -> bool:
	return g.day_number() == _today


func _go_to_bed() -> void:
	_go_home_inside()
	var spot: Array = MapManager.data(MapManager.HOME).spawns.home
	g.maps.place(MapManager.HOME, spot[0], spot[1])
	g.sleep()


# --- time, walking and maps ----------------------------------------------------

## Time passes for `minutes` of walking or work (not indoors: the clock stands there). False
## when the day ended meanwhile (a collapse at full fatigue, passing out at 2:00).
func _pass(minutes: float) -> bool:
	_owed += minutes
	while _owed >= 1.0 and _alive():
		_owed -= 1.0
		if not g.indoors():
			g._tick_minute()
	if not _alive():
		_owed = 0.0
	return _alive()


func _here() -> Vector2i:
	return Vector2i((g.maps.pos / 16.0).floor())


## Walks to cell `c` on this map (straight distance at the running pace) and faces `face`.
func _walk(c: Vector2i, face := Vector2i.DOWN) -> bool:
	var d := absi(c.x - _here().x) + absi(c.y - _here().y)
	var speed: float = float(_player.RUN_SPEED if g.can_run() else _player.WALK_SPEED) * g.speed_factor()
	g.maps.place(g.maps.id, c, face)
	return _pass(d / (speed / 16.0) / GameRules.SECONDS_PER_MINUTE)


func _go(map_id: String, cell: Vector2i, face := Vector2i.DOWN) -> void:
	g.go_to_map(map_id, cell, face)
	g.map_arrived()
	_check("enter")
	_play_events()


## Through the door at `cell` of this map (its hours and shops checked by Game.use_door).
func _door(cell: Vector2i) -> bool:
	var door: Dictionary = g.maps.door_at(cell)
	var was: String = g.maps.id
	g.use_door(door)
	if g.maps.id == was:
		return false
	g.map_arrived()
	_check("enter")
	_play_events()
	return true


func _leave_house() -> void:
	if g.maps.id == MapManager.HOME:
		_go(MapManager.FARM, Vector2i(4, 4))


func _to_farm() -> void:
	match g.maps.id:
		MapManager.FARM:
			return
		"town":
			_walk(Vector2i(0, 10))
			_go(MapManager.FARM, Vector2i(30, 6), Vector2i.LEFT)
		MapManager.HOME, "coop", "barn":
			var door := {MapManager.HOME: Vector2i(4, 4), "coop": Vector2i(15, 4), "barn": Vector2i(21, 4)}
			_go(MapManager.FARM, door[g.maps.id])
		_:
			_to_town()
			_to_farm()


func _to_town() -> void:
	match g.maps.id:
		"town":
			return
		MapManager.FARM:
			_walk(Vector2i(30, 6), Vector2i.RIGHT)
			_go("town", Vector2i(1, 10), Vector2i.RIGHT)
		"sakurazaka":
			_walk(Vector2i(0, 10), Vector2i.LEFT)
			_go("town", Vector2i(34, 10), Vector2i.LEFT)
		"mine":
			_walk(Vector2i(0, 7), Vector2i.LEFT)
			_go("sakurazaka", Vector2i(28, 10), Vector2i.LEFT)
			_to_town()
		"mine_floor":
			_go("mine", Vector2i(7, 3))
			_to_town()
		"minamino":
			_walk(Vector2i(4, 0), Vector2i.UP)
			_go("town", Vector2i(4, 20), Vector2i.UP)
		"river":
			_walk(Vector2i(4, 0), Vector2i.UP)
			_go("minamino", Vector2i(4, 18), Vector2i.UP)
			_to_town()
		"kaminoda":
			_walk(Vector2i(10, 19), Vector2i.DOWN)
			_go("town", Vector2i(10, 1), Vector2i.DOWN)
		"hill":
			_walk(Vector2i(19, 29), Vector2i.DOWN)
			_go("kaminoda", Vector2i(22, 1), Vector2i.DOWN)
			_to_town()
		_:
			# A house or shop: out through its door (spawn [4, 5] / [3, 4] inside), then on to
			# the village from the area it opens onto.
			var m: MapData = g.maps.current()
			for door in m.doors:
				g.maps.place(m.id, door.cells[0] + Vector2i.UP, Vector2i.DOWN)
				if _door(door.cells[0]):
					_to_town()
					return
			_go("town", Vector2i(2, 10))


func _to_river() -> void:
	if g.maps.id == "river":
		return
	_to_town()
	_walk(Vector2i(4, 21), Vector2i.DOWN)
	_go("minamino", Vector2i(4, 1))
	_forage()
	_walk(Vector2i(3, 19), Vector2i.DOWN)
	_go("river", Vector2i(5, 1))


## The bamboo hill's wild things, and Kaminoda's on the way (data/forage.json).
func _hill_round() -> void:
	_to_town()
	_walk(Vector2i(10, 0), Vector2i.UP)
	_go("kaminoda", Vector2i(10, 18), Vector2i.UP)
	_forage()
	_walk(Vector2i(22, 0), Vector2i.UP)
	_go("hill", Vector2i(19, 28), Vector2i.UP)
	_forage()
	_to_farm()
	_ship_at_bin()


## Picks every wild thing growing on this map, nearest spot first, into the rucksack.
func _forage() -> void:
	var left: Dictionary = g.forage_here()
	while not left.is_empty() and _alive():
		var best: Vector2i = left.keys()[0]
		for c in left:
			if absi(c.x - _here().x) + absi(c.y - _here().y) < absi(best.x - _here().x) + absi(best.y - _here().y):
				best = c
		left.erase(best)
		if g.held != "":
			_to_bag()
		_walk(best + Vector2i.DOWN, Vector2i.UP)
		if g.forage_pick(best).to == "hand":
			_to_bag()
		_pass(0.3)


func _go_home_inside() -> void:
	_to_farm()
	if g.maps.id == MapManager.FARM:
		_walk(Vector2i(4, 4), Vector2i.UP)
		_go(MapManager.HOME, Vector2i(4, 5), Vector2i.UP)


# --- events (a small headless EventPlayer) -----------------------------------------

## The map's trigger table on `cause` (and a festival due on this map): plays what matches.
func _check(cause: String, extra := {}) -> String:
	var s: Dictionary = g.trigger_state(_here())
	s.merge(extra, true)
	if cause in ["enter", "minute"]:
		var fest := Festivals.due_event(g.maps.id, s)
		if fest != "":
			g.events_seen[Festivals.seen_key(s.festival, s.year)] = true
			_play(fest)
			return fest
	var t := EventTriggers.open(g.maps.id)
	if t.error != "":
		_bug("triggers %s: %s" % [g.maps.id, t.error])
		return ""
	var id := t.pick(cause, s)
	if id != "":
		_play(id)
	return id


## Runs event `id` to its end: dialogue opens no box here (nothing waits on it), walks and
## fades take their seconds; set / give / money / affection / ending steps change the game.
func _play(id: String) -> void:
	var r := EventRunner.open(id, g)
	if r.error != "":
		_bug("event %s: %s" % [id, r.error])
		return
	r.start(g.maps.pos, g.maps.facing)
	g.events_seen[id] = true
	_played.append("%s (%s)" % [id, g.date_text()])
	for _i in 4000:
		if r.done():
			break
		r.update(0.1)
	if not r.done():
		_bug("event %s never ended" % id)
	Villagers.actors = {}


func _play_events() -> void:
	while not _events.is_empty():
		_play(_events.pop_front())


func _on_message(text: String) -> void:
	if text.begins_with("You collapsed") or text.begins_with("You fell asleep outside"):
		_knocked += 1
		if text.begins_with("You collapsed"):
			_cost("doctor", mini(int(g.body.get("collapse", {}).get("fee", 0)), g.money))


func _bug(text: String) -> void:
	if not text in _bugs:
		_bugs.append(text)
		push_warning("play_year: " + text)


# --- tools and the body ----------------------------------------------------------

func _hold_tool(tool: String) -> bool:
	for i in g.inventory.size("tools"):
		if g.inventory.id_at("tools", i) == tool:
			g.select_tool(i)
			return true
	return false


## One use of `tool` from `origin` facing `face` at charge `charge`, by the key's path
## (FarmActions.use_tool). False when it can't (no tool, too little stamina, the day over).
func _use(tool: String, origin: Vector2i, face: Vector2i, charge := 0) -> bool:
	if not _hold_tool(tool):
		return false
	charge = mini(charge, g.max_charge(tool))
	if tool in g.tools_data.tools and int(g.charge_rule(tool, charge).stamina) > g.stamina - KEEP_STAMINA:
		_eat_if_low(true)
		if int(g.charge_rule(tool, charge).stamina) > g.stamina - KEEP_STAMINA:
			return false
	_walk(origin, face)
	g.maps.place(g.maps.id, origin, face)
	_actions.use_tool(origin, face, charge)
	g.finish_swing()   # the cells change on the swing's hit: land it now (the time is passed below)
	# A swing takes about 0.4 s, and each charge step float(charge_seconds) more.
	return _pass((0.4 + charge * float(g.tools_data.get("charge_seconds", 0.6))) / GameRules.SECONDS_PER_MINUTE)


## Eats the cheapest food carried when stamina is low (`now`: whenever it is not full),
## buying an onigiri at the stand when nothing is carried and the farmer is on the farm.
func _eat_if_low(now := false) -> void:
	if g.stamina >= (g.max_stamina - 10 if now else EAT_BELOW):
		return
	var best := ""
	var best_cost := 1 << 30
	for id in g.inventory.totals():
		if not g.edible(id) or id.begins_with("seeds:"):
			continue
		var cost: int = g.sell_price(id) if g.sell_price(id) > 0 else int(g.food_info(id).get("price", 0))
		if _kept_back(id) or cost >= best_cost:
			continue
		best = id
		best_cost = cost
	if best == "" and g.maps.on_farm() and g.money > 100:
		var onigiri: int = g.foods.keys().find("onigiri")
		g.food_index = onigiri
		_walk(Vector2i(10, 4), Vector2i.UP)
		var before: int = g.money
		_actions.buy_food()
		_cost("food", before - g.money)
		best = "food:onigiri"
	if best != "":
		g.eat_item(best)


# --- the field -------------------------------------------------------------------

func _plots() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in PLOT_Y:
		for x in PLOT_X:
			out.append(Vector2i(x, y))
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return absi(a.x - 8) + a.y < absi(b.x - 8) + b.y)
	return out


func _cells(plot: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in 3:
		for dx in 3:
			out.append(plot + Vector2i(dx, dy))
	return out


## Morning (`late` false): harvest and ship what is ripe, water, sow empty tilled plots.
## Afternoon (`late` true): clear and till new plots up to the can's count.
func _field(late: bool) -> void:
	_to_farm()
	var season: String = g.season_name()
	var farm: FarmGrid = g.farm
	var want: int = PLOTS_BY_CAN.get(g.tool_level("can"), 4)
	var used := 0
	for plot in _plots():
		if not _alive() or g.hour >= (17 if late else 12):
			break
		var cells := _cells(plot)
		var planted := cells.any(func(c: Vector2i) -> bool: return farm.cell(c).crop != "")
		var tilled := cells.all(func(c: Vector2i) -> bool: return farm.cell(c).tilled or farm.cell(c).crop != "")
		if planted:
			used += 1
			if not late:
				_harvest(cells)
				_water(plot, cells)
			continue
		if season == "winter" or used >= want:
			continue
		var crop := _crop_to_sow(used)
		if crop == "":
			continue
		if tilled and not late:
			if _sow(plot, crop):
				used += 1
				_water(plot, cells)
		elif late and g.stamina > 30:
			if _clear(plot) and _till(plot):
				if _sow(plot, crop):
					used += 1
					_water(plot, cells)
	_ship_at_bin()


## A crop of the season that still ripens before the season ends: the `k`-th plot gets the
## k-th of them (a mix, so more kinds are shipped).
func _crop_to_sow(k: int) -> String:
	var ok: Array[String] = []
	for id in CROPS.get(g.season_name(), []):
		var c: Dictionary = g.crops[id]
		var days := 0
		for n in c.stage_days:
			days += int(n)
		if g.day + days <= GameRules.DAYS_PER_SEASON:
			ok.append(id)
	return ok[k % ok.size()] if not ok.is_empty() else ""


func _harvest(cells: Array[Vector2i]) -> void:
	for c in cells:
		if g.farm.is_ripe(c) and _alive():
			_walk(c + Vector2i.UP)
			if g.pick_up(c) != "":
				_to_bag()
			_pass(0.5)


## The item overhead into the rucksack (the rucksack screen); a full rucksack goes to the bin.
func _to_bag() -> void:
	var id: String = g.held
	if id == "":
		return
	if g.inventory.room_for(id) < 1:
		var back: Vector2i = _here()
		var map: String = g.maps.id
		if map == MapManager.FARM:
			_ship_at_bin()
			_walk(back)
		if g.inventory.room_for(id) < 1:
			return   # stays in hand
	g.inventory.take(id, 1, ["hand"])
	g.inventory.add(id, 1)
	g.changed.emit()


func _clear(plot: Vector2i) -> bool:
	var farm: FarmGrid = g.farm
	var cells := _cells(plot)
	for x in 3:
		cells.append(plot + Vector2i(x, -1))   # the path row above, where the farmer stands
	for c in cells:
		var guard := 0
		while farm.cell(c).obj != FarmGrid.Obj.NONE and guard < 12:
			guard += 1
			var obj: int = farm.cell(c).obj
			var tool: String = FarmGrid.CLEAR_RULES[obj].tool
			var need: int = int(FarmGrid.CLEAR_RULES[obj].hits) - int(farm.cell(c).hits)
			var charge := 0
			if tool in ["hammer", "axe"]:
				while charge < g.max_charge(tool) and int(g.charge_rule(tool, charge).get("hits", 1)) < need:
					charge += 1
			if not _use(tool, c + Vector2i.UP, Vector2i.DOWN, charge):
				return false
	return true


## Tills every cell of `plot` with the hoe's longest straight charge from the path above.
func _till(plot: Vector2i) -> bool:
	var farm: FarmGrid = g.farm
	for x in 3:
		var col := plot + Vector2i(x, 0)
		for y in 3:
			var c := col + Vector2i(0, y)
			if farm.cell(c).tilled:
				continue
			# Rows left in this column from c down; the hoe reaches 1, 3 or 5 straight ahead.
			var charge := 0
			var rows := 3 - y
			while charge < mini(g.max_charge("hoe"), 2) and _reach("hoe", charge) < rows:
				charge += 1
			if not _use("hoe", c + Vector2i.UP, Vector2i.DOWN, charge):
				return false
			if not farm.cell(c).tilled:
				return false
	return true


func _reach(tool: String, charge: int) -> int:
	return (g.charge_rule(tool, charge).area as Array).size() - 1


func _sow(plot: Vector2i, crop: String) -> bool:
	if g.count("seeds:" + crop) == 0:
		g.seed_index = g.crops.keys().find(crop)
		_walk(Vector2i(10, 4), Vector2i.UP)
		var before: int = g.money
		_actions.buy_seeds()
		_cost("seeds", before - g.money)
		if g.count("seeds:" + crop) == 0:
			return false
	g.seed_index = g.crops.keys().find(crop)
	_use("seeds", plot + Vector2i(1, 0), Vector2i.DOWN)
	return g.farm.cell(plot + Vector2i(1, 1)).crop != ""


## Waters the plot's dry crops with the can's widest charge that fits, filling it at the pond.
func _water(plot: Vector2i, cells: Array[Vector2i]) -> void:
	var farm: FarmGrid = g.farm
	if g.weather_today == "rain":
		return
	for y in 3:
		var row := plot + Vector2i(0, y)
		var dry := [0, 1, 2].filter(func(x: int) -> bool:
			var d: Dictionary = farm.cell(row + Vector2i(x, 0))
			return d.crop != "" and d.tilled and not d.wet)
		if dry.is_empty():
			continue
		if g.water < 9:
			_walk(Vector2i(24, 3), Vector2i.RIGHT)
			_use("can", Vector2i(24, 3), Vector2i.RIGHT)
		var charge := g.max_charge("can") as int
		var width := (g.charge_rule("can", charge).area[1] as String).length()
		if width >= 3 and g.charge_rule("can", charge).area.size() - 1 >= 1:
			# Wide charges water rows from above: one swing for the row (or more rows at once).
			if not _use("can", row + Vector2i(1, -1), Vector2i.DOWN, charge):
				return
		else:
			for x in dry:
				if not _use("can", row + Vector2i(x, -1), Vector2i.DOWN, 0):
					return


# --- shipping, keeping things back -------------------------------------------------

## Things not shipped: the ores the next upgrades take, gifts kept back, the best contest entry.
func _kept_back(id: String) -> bool:
	if id.begins_with("mine:") and _ore_need().has(id):
		return true
	return false


## Mine items the waiting upgrades take: id -> how many in all.
func _ore_need() -> Dictionary:
	var out := {}
	for goal in _goals:
		if goal[1] != "upgrade":
			continue
		var offer := g.shop("smithy").upgrade_offer(goal[2], int(goal[3]) - 1) as Dictionary
		for item in offer.get("items", {}):
			out[item] = int(out.get(item, 0)) + int(offer.items[item])
	return out


## Before the bin: ores for the smithy, a few gift items and the contest entry go into the chest.
func _stash() -> void:
	var inv: Inventory = g.inventory
	var gifts := _gift_items()
	for id in inv.totals().keys():
		var keep := 0
		if id.begins_with("mine:") and _ore_need().has(id):
			keep = int(_ore_need()[id])
		elif id in gifts:
			keep = GIFT_STOCK
		elif id == _contest_pick():
			keep = 1
		elif _cooking_keep(id) > 0:
			keep = _cooking_keep(id)
		elif _mine_dish(id):
			keep = MINE_DISH_KEEP
		var have: int = inv.count(id, ["chest"])
		var n := mini(inv.count(id), keep - have)
		if n > 0 and inv.room_for(id, ["chest"]) >= n and inv.take(id, n):
			inv.add(id, n, ["chest"])


## Ships everything carried (FarmActions.interact at the bin), dishes from the hand.
func _ship_at_bin() -> void:
	_to_farm()
	_stash()
	var inv: Inventory = g.inventory
	_walk(Vector2i(8, 4), Vector2i.UP)
	# Dishes go in from the hand only: each stack up into the hand, then the bin.
	for id in inv.totals().keys():
		var food: Dictionary = g.foods.get(id.trim_prefix("food:"), {})
		if id.begins_with("food:") and int(food.get("sell", 0)) > 0 and not food.get("shop", false) and not _kept_back(id):
			if g.held != "":
				break
			var n := inv.count(id, ["bag"])
			inv.take(id, n, ["bag"])
			inv.add(id, n, ["hand"])
			_count_ship(g.held, n)
			g.ship_produce()
	for id in inv.totals():
		if not id.begins_with("food:") and g.sell_price(id) > 0:
			_count_ship(id, inv.count(id))
	g.ship_produce()
	_pass(1.0)


func _count_ship(id: String, n: int) -> void:
	if n <= 0 or g.sell_price(id) <= 0:
		return
	var v: int = g.sell_price(id) * n
	var src := "crops"
	if id.begins_with("food:"):
		src = "dishes"
	elif id.begins_with("fish:"):
		src = "fish"
	elif id.begins_with("mine:"):
		src = "mine"
	elif id.begins_with("wild:"):
		src = "forage"
	elif not g.crops.has(id):
		src = "animals"
	_row.income[src] = int(_row.income.get(src, 0)) + v


func _cost(kind: String, n: int) -> void:
	if n > 0:
		_row.costs[kind] = int(_row.costs.get(kind, 0)) + n


# --- animals -------------------------------------------------------------------

func _animals_morning() -> void:
	var a: Animals = g.animals
	if a.list.is_empty():
		return
	if not a.in_home("coop").is_empty():
		_to_farm()
		_walk(Vector2i(15, 4), Vector2i.UP)
		_go("coop", Vector2i(4, 5), Vector2i.UP)
		a.fill_feed_box()
		for i in a.in_home("coop"):
			_tend(i)
		while not a.eggs.is_empty():
			g.held = a.take_egg()
			_to_bag()
		_go(MapManager.FARM, Vector2i(15, 4))
	if not a.in_home("barn").is_empty():
		_to_farm()
		_walk(Vector2i(21, 4), Vector2i.UP)
		_go("barn", Vector2i(7, 6), Vector2i.UP)
		a.fill_feed_box("barn")
		for i in a.in_home("barn"):
			_tend(i)
			if a.product_ready(a.list[i]):
				g.held = a.take_product(i)
				_to_bag()
			a.brush(i)
		_go(MapManager.FARM, Vector2i(21, 4))
	_ship_at_bin()


func _tend(i: int) -> void:
	var a: Animals = g.animals
	if a.list[i].sick:
		if g.count("medicine") > 0 or g.inventory.count("medicine", ["chest"]) > 0:
			g.inventory.take("medicine", 1, ["bag", "hand", "chest"])
			a.cure(i)
		else:
			_want_medicine = true
		return
	a.pet(i)


var _want_medicine := false


# --- the village: talks, gifts, shops ----------------------------------------------

## The things a villager loves or likes that the farm makes (kept back for gifts).
func _gift_items() -> Array[String]:
	var out: Array[String] = []
	for id in g.inventory.totals(["bag", "hand", "chest"]):
		for v in Villagers.all():
			if Villagers.reaction(v, id) in ["love", "like"] and not id.begins_with("mine:") and not id in out:
				out.append(id)
	return out


## The gift for villager `who` among what is carried and in the chest: loved first, then
## liked, the cheapest of those; "" for none.
func _gift_for(who: String) -> String:
	var best := ""
	var best_key := 1 << 30
	for id in g.inventory.totals(["bag", "hand", "chest"]):
		if _kept_back(id) or id == _contest_pick() or id.begins_with("seeds:") or g.inventory.is_tool(id):
			continue
		var r := Villagers.reaction(who, id)
		if not r in ["love", "like"]:
			continue
		var key: int = (0 if r == "love" else 100000) + maxi(g.sell_price(id), int(g.food_info(id).get("price", 0)))
		if key < best_key:
			best_key = key
			best = id
	return best


## The daily round of the village: everyone out and about or at a counter gets a talk and a
## gift, and the store and the smithy are visited while they are open.
func _village_round() -> void:
	if g.hour >= 17:
		return
	if g.hour < 9:
		_pass(float((9 - g.hour) * 60 - g.minute))   # the store opens at 9
	if not _alive():
		return
	_to_town()
	_visit_store()
	_to_town()
	for who in Villagers.all():
		_meet(who)
		if not _alive():
			return
	_to_town()
	if g.hour < 10:
		_pass(float((10 - g.hour) * 60 - g.minute))   # the smithy opens at 10 (time stood still in the store)
	if _alive():
		_visit_smithy()
	_to_farm()


## Finds villager `who` where their day plan has them now (the village, a shop, their home)
## and talks to them, with a gift first when there is one.
func _meet(who: String) -> void:
	var day: int = g.day_number()
	if g.affection.talked_on(who, day) and g.affection.gifted_on(who, day):
		return
	var w := Villagers.where(who, g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	if w.is_empty():
		return
	var map: String = w.map
	if map != g.maps.id:
		_to_town()
		if map != "town":
			var door := _town_door_to(map)
			if door == Vector2i(-1, -1):
				return
			_walk(door + Vector2i.DOWN, Vector2i.UP)
			if not _door(door):
				return
			w = Villagers.where(who, g.day_minutes(), g.trigger_state(Vector2i.ZERO))
			if w.get("map", "") != g.maps.id:
				return
	var at := Vector2i((w.pos as Vector2).floor())
	_walk(at + Vector2i.DOWN, Vector2i.UP)
	_talk(who)


func _town_door_to(map: String) -> Vector2i:
	for door in MapManager.data("town").doors:
		if door.to == map:
			return door.cells[0]
	return Vector2i(-1, -1)


## A gift (held out) and a talk: a talk row of the trigger table (a heart event, a recipe
## lesson) plays instead of the villager's own line, as in the views.
func _talk(who: String) -> void:
	var day: int = g.day_number()
	var gift := _gift_for(who) if not g.affection.gifted_on(who, day) else ""
	if gift != "" and g.held == "":
		g.inventory.take(gift, 1, ["bag", "chest"])
		g.inventory.add(gift, 1, ["hand"])
		g.talk_to(who, Vector2i.DOWN)
		if g.held != "":   # not taken: back into the rucksack
			_to_bag()
	if g.affection.talked_on(who, day):
		return
	if _check("talk", {"who": who}) == "":
		g.talk_to(who, Vector2i.DOWN)
	_play_events()
	_pass(2.0)


func _visit_store() -> void:
	var s: Shop = g.shop("general")
	if g.festival_today() != "" or not s.is_open(g.hour, g.weekday()):
		return
	_walk(Vector2i(23, 16), Vector2i.UP)
	if not _door(Vector2i(23, 15)):
		return
	var counter: Array = MapManager.data("store").spawns.counter
	g.maps.place("store", counter[0], counter[1])
	if not g.open_shop("general"):
		return   # Sayo is out
	_talk("sayo")
	var a: Animals = g.animals
	# Supplies: feed for a week ahead, fodder too, medicine when an animal is sick.
	var hens := a.in_home("coop").size()
	if hens > 0 and a.feed_stock < hens * 4:
		_buy("feed", hens * 10, "feed")
	var beasts := a.in_home("barn").size()
	if beasts > 0 and a.stock_of("barn") < beasts * 4:
		_buy("fodder", beasts * 10, "feed")
	if _want_medicine:
		_buy("medicine", 1, "medicine")
		_want_medicine = false
	_sell_here("general")
	_buy_goals("general")


func _visit_smithy() -> void:
	var s: Shop = g.shop("smithy")
	if g.festival_today() != "" or not s.is_open(g.hour, g.weekday()):
		return
	_walk(Vector2i(27, 7), Vector2i.UP)
	if not _door(Vector2i(27, 6)):
		return
	var counter: Array = MapManager.data("smithy").spawns.counter
	g.maps.place("smithy", counter[0], counter[1])
	if not g.open_shop("smithy"):
		return   # Hachiro is out (building on the farm)
	_talk("hachiro")
	if g.shop_jobs.has("smithy"):
		g.shop_collect("smithy")
	_sell_here("smithy")
	_buy_goals("smithy")


func _buy(item: String, n: int, cost_kind: String) -> bool:
	var before: int = g.money
	var r: Dictionary = g.shop_buy("general", item, n)
	_cost(cost_kind, before - g.money)
	return r.ok


## Mine finds this shop buys at more than the bin (the smithy's stones and ores, the store's
## gems), less what the upgrades and the contest keep.
func _sell_here(shop_id: String) -> void:
	var s: Shop = g.shop(shop_id)
	g.inventory.totals(["chest"])
	for id in g.inventory.totals().keys():
		if not id.begins_with("mine:") or s.buy_back(id) <= g.sell_price(id):
			continue
		var n: int = g.inventory.count(id) - int(_ore_need().get(id, 0)) - (1 if id == _contest_pick() else 0)
		if n > 0:
			var before: int = g.money
			g.shop_sell(shop_id, id, n)
			_row.income.mine = int(_row.income.get("mine", 0)) + g.money - before


## Buys the goals of this shop in order while the money lasts (RESERVE kept back).
func _buy_goals(shop_id: String) -> void:
	var now := [g.season + 4 * (g.year - 1), g.day]
	for goal in _goals.duplicate():
		var from: Array = goal[0]
		if from[0] > now[0] or from[0] == now[0] and from[1] > now[1]:
			break
		var done := _try_goal(shop_id, goal)
		if done == "done":
			_goals.erase(goal)
			_row.bought.append(_goal_name(goal))
		elif done == "money":
			break   # save up for it; later goals wait
		# "elsewhere" (another shop) and "wait" (ores, the smithy busy) let later goals go first


func _goal_name(goal: Array) -> String:
	match String(goal[1]):
		"upgrade":
			return "%s %d" % [goal[2], goal[3]]
		"animal":
			return "%d %s" % [goal[3], String(goal[2]).trim_prefix("animal:")]
		"kitchen":
			return "kitchen tools"
		"rucksack":
			return "rucksack"
	return String(goal[2])


func _try_goal(shop_id: String, goal: Array) -> String:
	var spare: int = g.money - RESERVE
	match String(goal[1]):
		"upgrade":
			if shop_id != "smithy":
				return "elsewhere"
			var tool: String = goal[2]
			if g.tool_level(tool) >= int(goal[3]):
				return "done"
			if g.shop_jobs.has("smithy"):
				return "wait"
			if g.tool_level(tool) < int(goal[3]) - 1:
				return "wait"
			var offer: Dictionary = g.shop("smithy").upgrade_offer(tool, g.tool_level(tool))
			if offer.price > spare:
				return "money"
			var short := Shop.short_of(g.inventory, offer.items)
			for item in short:   # the ores kept in the chest come out for it
				var n := mini(int(short[item]), g.inventory.count(item, ["chest"]))
				if n > 0:
					g.inventory.take(item, n, ["chest"])
					g.inventory.add(item, n)
			short = Shop.short_of(g.inventory, offer.items)
			if not short.is_empty():
				_waits[_goal_name(goal)] = "short of " + ", ".join(short.keys().map(func(k: String) -> String: return "%s %d" % [k.trim_prefix("mine:"), short[k]]))
				return "wait"
			# The can goes in only when tomorrow rains or nothing grows (the crops would go dry).
			if tool == "can" and g.season_name() != "winter" and g.weather_tomorrow != "rain":
				return "wait"
			var before: int = g.money
			var r: Dictionary = g.shop_upgrade("smithy", tool)
			_cost("tools", before - g.money)
			_waits.erase(_goal_name(goal))
			return "wait" if r.ok else "money"   # done once it is collected at that level
		"animal":
			if shop_id != "general":
				return "elsewhere"
			var price: int = g.shop("general").price(goal[2], g.season_name())
			if price * int(goal[3]) > spare:
				return "money"
			if g.shop_room("general", goal[2]) < int(goal[3]):
				return "done"   # no room: skip it
			return "done" if _buy(goal[2], int(goal[3]), "animals") else "money"
		"build":
			if shop_id != "general":
				return "elsewhere"
			if g.has_built(goal[2]):
				return "done"
			if not g.house_job.is_empty():
				return "wait"
			if int(g.shop("general").builds[goal[2]].price) > spare:
				return "money"
			var before: int = g.money
			var r: Dictionary = g.shop_build("general", goal[2])
			_cost("house", before - g.money)
			return "done" if r.ok else "money"
		"kitchen":
			if shop_id != "general":
				return "elsewhere"
			if not g.has_built("kitchen"):
				return "wait"
			for o in g.shop("general").kitchen_offers(g.kitchen_tools, g.house_built):
				if int(o.price) > spare:
					return "money"
				var before: int = g.money
				g.shop_buy("general", o.item)
				_cost("kitchen", before - g.money)
				spare = g.money - RESERVE
			return "done" if g.shop("general").kitchen_offers(g.kitchen_tools, g.house_built).is_empty() else "money"
		"rucksack":
			if shop_id != "general":
				return "elsewhere"
			var offer: Dictionary = g.shop("general").rucksack_offer(g.inventory.size("bag"))
			if offer.is_empty():
				return "done"
			if int(offer.price) > spare:
				return "money"
			var before: int = g.money
			g.shop_buy("general", "rucksack")
			_cost("tools", before - g.money)
			return "done"
	return "done"


# --- the mine ------------------------------------------------------------------

## Down from floor 1 (or the deepest landing reached, by the lift) as far as stamina and the clock allow, every rock and soft spot near the
## way broken; back up through the ladder and home.
func _mine_trip() -> void:
	_ship_at_bin()   # room in the rucksack for the finds
	_pack_for_mine()
	_row.mine_trips = int(_row.get("mine_trips", 0)) + 1
	_to_town()
	_walk(Vector2i(35, 10), Vector2i.RIGHT)
	_go("sakurazaka", Vector2i(1, 10), Vector2i.RIGHT)
	_forage()
	_walk(Vector2i(29, 10), Vector2i.RIGHT)
	_go("mine", Vector2i(1, 7), Vector2i.RIGHT)
	_walk(Vector2i(7, 3), Vector2i.UP)
	# The rope lift to the deepest landing reached (Game.mine_start_floors), else the ladder.
	var start: int = g.mine_start_floors().back()
	if start > 1 and g.mine_go_down(start):
		g.map_arrived()
		_check("enter")
		_play_events()
		_row.mine_lifts = int(_row.get("mine_lifts", 0)) + 1
	else:
		_go("mine_floor", Vector2i(8, 1))
	while _alive():
		var f: MineFloor = g.maps.mine_floor
		if f == null or g.hour >= 17:
			break
		if g.stamina < 20:
			_eat_packed()
		if g.stamina < 20 or g.fatigue >= MINE_FATIGUE:
			break
		var target := _nearest_find(f)
		if target == Vector2i(-1, -1):
			if not f.open:
				_bug("mine floor %d: no hole and nothing left to break" % f.depth)
				break
			_walk(f.stairs)
			var door: Dictionary = f.door_at(f.stairs)
			if door.is_empty():
				_bug("mine floor %d: the open hole has no door" % f.depth)
				break
			g.use_door(door)
			g.map_arrived()
			continue
		var before := [g.day_minutes(), g.stamina]
		_break(f, target)
		if [g.day_minutes(), g.stamina] == before:
			break   # no swing: the hands and the rucksack are full, or too tired for it
	if g.maps.mine_floor != null:
		_row.mine_best = maxi(int(_row.get("mine_best", 0)), g.maps.mine_floor.depth)
	_to_town()


## A dish filling enough to be kept for the mine (not one the stand sells).
func _mine_dish(id: String) -> bool:
	var f: Dictionary = g.foods.get(id.trim_prefix("food:"), {})
	return id.begins_with("food:") and not f.get("shop", false) and int(f.get("stamina", 0)) >= MINE_DISH_STAMINA


func _food_stamina(id: String) -> int:
	return int(g.food_info(id).get("stamina", 0))


## The stamina of the food (not raw farm goods) carried now.
func _packed_stamina() -> int:
	var n := 0
	for id in g.inventory.totals():
		if id.begins_with("food:"):
			n += _food_stamina(id) * g.inventory.count(id)
	return n


## Food for the trip, up to MINE_PACK stamina: the dishes kept in the chest first, then the
## stand's food with the most stamina for its price (RESERVE kept back). On the farm.
func _pack_for_mine() -> void:
	var inv: Inventory = g.inventory
	var packed := _packed_stamina()
	for id in inv.totals(["chest"]).keys():
		if packed >= MINE_PACK:
			break
		if not _mine_dish(id):
			continue
		var n := mini(inv.count(id, ["chest"]), ceili(float(MINE_PACK - packed) / _food_stamina(id)))
		n = mini(n, inv.room_for(id))
		if n > 0 and inv.take(id, n, ["chest"]):
			inv.add(id, n)
			packed += n * _food_stamina(id)
	var buy := ""
	var best := INF
	for id in g.foods:
		var f: Dictionary = g.foods[id]
		if f.get("shop", false) and int(f.get("stamina", 0)) > 0 and float(f.price) / int(f.stamina) < best:
			best = float(f.price) / int(f.stamina)
			buy = id
	if buy == "":
		return
	var price := int(g.foods[buy].price)
	g.food_index = g.foods.keys().find(buy)
	_walk(Vector2i(10, 4), Vector2i.UP)
	while packed < MINE_PACK and g.money - price >= RESERVE and inv.room_for("food:" + buy) > 0:
		var before: int = g.money
		_actions.buy_food()
		if g.money == before:
			break
		_cost("food", before - g.money)
		packed += _food_stamina("food:" + buy)


## In the mine with stamina low: the carried food with the most stamina that still fits under
## the max (else the least filling one).
func _eat_packed() -> void:
	var pick := ""
	var pick_n := -1
	var least := ""
	for id in g.inventory.totals():
		if not id.begins_with("food:") or _food_stamina(id) <= 0:
			continue
		var n := _food_stamina(id)
		if g.stamina + n <= g.max_stamina and n > pick_n:
			pick = id
			pick_n = n
		if least == "" or n < _food_stamina(least):
			least = id
	if pick == "":
		pick = least
	if pick != "":
		var before: int = g.stamina
		if g.eat_item(pick).ok:
			_row.mine_food = int(_row.get("mine_food", 0)) + g.stamina - before


## The nearest rock or soft spot (breaking all of them on the way down), or (-1, -1).
func _nearest_find(f: MineFloor) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 1 << 30
	for c in f.rocks.keys() + f.soft.keys():
		var d := absi(c.x - _here().x) + absi(c.y - _here().y)
		if d < best_d:
			best_d = d
			best = c
	# Once the hole is found the bot goes down: deeper floors have the better ores.
	if f.open:
		return Vector2i(-1, -1)
	return best


func _break(f: MineFloor, c: Vector2i) -> void:
	var tool := "hammer" if f.rocks.has(c) else "hoe"
	var guard := 0
	while (f.rocks.has(c) or f.soft.has(c)) and guard < 20 and _alive():
		guard += 1
		var charge := 0
		if tool == "hammer":
			var need: int = int(f.rocks[c].hits) - int(f.rocks[c].done)
			while charge < g.max_charge("hammer") and int(g.charge_rule("hammer", charge).hits) < need:
				charge += 1
		if int(g.charge_rule(tool, charge).stamina) > g.stamina - KEEP_STAMINA:
			_eat_if_low(true)
			if int(g.charge_rule(tool, charge).stamina) > g.stamina - KEEP_STAMINA:
				return
		_hold_tool(tool)
		_walk(c + Vector2i.UP)
		if g.held != "":
			_to_bag()
		var r: Dictionary = g.mine_swing(tool, c + Vector2i.UP, Vector2i.DOWN, charge)
		if r.result != "swung":
			return
		_pass(0.5)


# --- fishing -------------------------------------------------------------------

## What a bite at `place` fetches on average now: data/fish.json's table there for this
## season, hour and weather (fish caught once already left out).
func _bite_value(place: String) -> float:
	var look: String = GameRules.weather_look(g.weather_today, g.season_name())
	var w := Fishing.candidates(g.fish_data, place, g.season_name(), g.hour, look, g.fish_caught)
	var total := 0.0
	var value := 0.0
	for id in w:
		total += float(w[id])
		value += float(w[id]) * int(g.fish_data.fish[id].sell)
	return value / total if total > 0.0 else 0.0


## The river when a bite pays more there than at the farm pond (the walk is a few minutes).
func _fish_place() -> String:
	return "river" if _bite_value("river") > _bite_value(MapManager.FARM) else MapManager.FARM


## Fishes at `place` (the farm pond or the river's shore) for `minutes`, reeling in on every
## bite (the farmer's quick hands).
func _fish(minutes: int, place: String = MapManager.FARM) -> void:
	var spot := Vector2i(24, 3)
	var face := Vector2i.RIGHT
	if place == "river":
		_to_river()
		spot = RIVER_SHORE
		face = Vector2i.DOWN
	else:
		_to_farm()
	if g.held != "":
		_to_bag()
	_walk(spot, face)
	_hold_tool("rod")
	var end: int = g.hour * 60 + g.minute + minutes
	while _alive() and g.hour * 60 + g.minute < end and g.stamina > KEEP_STAMINA + 4:
		if g.held != "":
			_to_bag()
			if g.held != "":
				break
		if g.cast_line(spot, face) != "cast":
			break
		while _alive() and g.fishing.state == "wait" and g.hour * 60 + g.minute < end:
			var chance: float = Fishing.bite_chance(g.fish_data, g.hour, GameRules.weather_look(g.weather_today, g.season_name())) * g.rod_bite_factor()
			for _i in 2:   # a game minute is two half-second steps
				g.fishing.step(GameRules.SECONDS_PER_MINUTE / 2.0, chance, g.rng)
			_pass(1.0)
		if g.fishing.state == "bite":
			var r: Dictionary = g.reel_in()
			if r.fish != "":
				var at: Dictionary = _row.fish_at.get(place, {"n": 0, "g": 0})
				at.n += 1
				at.g += g.sell_price(r.fish)
				_row.fish_at[place] = at
		else:
			g.fishing.stop()
	g.fishing.stop()
	if g.held != "":
		_to_bag()
	_ship_at_bin()


# --- contests and festivals ---------------------------------------------------------

## The next festival's contest kind and the item now kept for it ("" when none fits).
func _contest_pick() -> String:
	var fest := _next_contest()
	if fest == "":
		return ""
	var c := Festivals.contest(fest)
	var best := ""
	var best_score := -1
	var f := Festivals.get_festival(fest)
	for id in g.inventory.totals(["bag", "hand", "chest"]):
		if g.item_kind(id) != c.takes:
			continue
		var seasons: Array = g.crops.get(id, {}).get("seasons", [])
		var score := Festivals.entry_score(fest, seasons, g.sell_price(id))
		if score > best_score:
			best_score = score
			best = id
	return best


## Today's or the next festival with a contest this season ("" when none is left).
func _next_contest() -> String:
	for d in range(g.day, GameRules.DAYS_PER_SEASON + 1):
		var id := Festivals.on_date(g.season_name(), d)
		if id != "" and not Festivals.contest(id).is_empty() and not g.events_seen.has(Festivals.entered_key(id, g.year)):
			return id
	return ""


## A festival day: to the village in its hours, the festival event, the contest with the best
## thing kept, a talk with everyone there.
func _festival(fest: String) -> void:
	var f := Festivals.get_festival(fest)
	var opens := EventTriggers.clock(f.hours[0])
	var entry := _contest_pick()
	if entry != "":
		g.inventory.take(entry, 1, ["bag", "chest"])
		if g.held != "":
			_to_bag()
		g.inventory.add(entry, 1, ["hand"])
	if g.hour * 60 + g.minute < opens:
		_pass(float(opens - g.hour * 60 - g.minute))
	if not _alive():
		return
	_to_town()
	_check("minute")   # the festival's event, when its hours begin with the farmer there
	var c := Festivals.contest(fest)
	if not c.is_empty():
		g.maps.place(f.map, Vector2i(int(c.table[0]), int(c.table[1]) + 1), Vector2i.UP)
		var r: Dictionary = g.enter_contest()
		_play_events()
		if r.ok:
			_row.contests.append("%s: %s, place %d" % [fest, r.item, r.place])
			if not (r.prize as Dictionary).is_empty():
				_row.income.prizes = int(_row.income.get("prizes", 0)) + int(r.prize.get("money", 0))
		else:
			_row.contests.append("%s: not entered (%s)" % [fest, r.why])
	if g.held != "":
		_to_bag()
	for who in Villagers.all():
		_meet(who)
	_to_farm()


# --- the evening ---------------------------------------------------------------

## Cooks what pays (or feeds tomorrow's work), ships it all, goes home.
func _evening() -> void:
	_to_farm()
	if g.has_built("kitchen"):
		_go_home_inside()
		var kitchen: Array = MapManager.data(MapManager.HOME).spawns.kitchen
		g.maps.place(MapManager.HOME, kitchen[0], kitchen[1])
		for id in Cooking.known_ids(g.flags):
			for _n in 10:
				if _gain(id) <= 0:
					break
				if not g.cook(id).ok:
					break
		_to_farm()
	_ship_at_bin()
	if g.hour < BED_HOUR:
		_pass(float((BED_HOUR - g.hour) * 60 - g.minute) if g.hour >= 6 else 0.0)


## What cooking `id` once fetches over its ingredients shipped raw (with what is on hand now).
func _gain(id: String) -> int:
	if not Cooking.missing_tools(id, g.kitchen_tools).is_empty():
		return 0
	if not Cooking.missing(id, g.inventory).is_empty():
		return 0
	var dish: int = int(g.foods.get(id, {}).get("sell", 0)) * Cooking.makes(id)
	var cost := 0
	for need in Cooking.recipe(id).needs:
		var c := Cooking.candidates(need, g.inventory)
		if c.is_empty():
			return 0
		var each: int = g.sell_price(c[0]) if g.sell_price(c[0]) > 0 else int(g.food_info(c[0]).get("price", 0))
		cost += each * int(need.n)
	return dish - cost


## Ingredients kept back for cooking: the eggs, milk and fish a profitable recipe takes.
func _cooking_keep(id: String) -> int:
	if not g.has_built("kitchen") or g.kitchen_tools.is_empty():
		return 0
	for r in Cooking.known_ids(g.flags):
		for need in Cooking.recipe(r).needs:
			if Cooking.fits(need, id):
				return 0 if g.crops.has(id) else 4
	return 0


# --- checks along the way ---------------------------------------------------------

## The save written each night loads back to the same game (a season's state at least).
func _save_round_trip() -> void:
	var before: Dictionary = g.to_dict()
	var text := JSON.stringify(before)
	var err: String = g.from_dict(JSON.parse_string(text))
	if err != "":
		_bug("the save didn't load back on %s: %s" % [g.date_text(), err])
		return
	var after := JSON.stringify(g.to_dict())
	if after != text:
		_bug("the save changed after loading on %s" % g.date_text())


# --- the report ----------------------------------------------------------------

func _new_row() -> void:
	_row = {"income": {}, "costs": {}, "bought": [], "contests": [], "money_start": g.money, "fish_at": {}}
	_knocked = 0
	_waits = {}


func _end_row(season: int) -> void:
	_row.season = GameRules.SEASONS[season]
	_row.money = g.money
	_row.knocked = _knocked
	_row.waits = _waits.duplicate()
	var levels := []
	for t in ["hoe", "can", "sickle", "hammer", "axe", "rod"]:
		levels.append("%s %d" % [t, g.tool_level(t)])
	_row.tools = ", ".join(levels)
	var hearts := []
	for id in Villagers.all():
		hearts.append("%s %d (band %d)" % [id, g.affection.of(id), g.affection.band(id)])
	_row.hearts = ", ".join(hearts)
	var a: Animals = g.animals
	_row.animals = "%d hens, %d in the barn" % [a.in_home("coop").size(), a.in_home("barn").size()]
	_row.built = ", ".join(g.house_built) if not g.house_built.is_empty() else "nothing"
	_row.kitchen_tools = g.kitchen_tools.size()
	_row.recipes = Cooking.known_ids(g.flags).size()
	_row.deepest = g.mine_deepest
	_rows.append(_row)
	var r := _row
	var inc := 0
	for k in SOURCES:
		inc += int(r.income.get(k, 0))
	var cost := 0
	for k in COSTS:
		cost += int(r.costs.get(k, 0))
	print("")
	print("== Year %d %s: income %d G, costs %d G, money %d -> %d G" % [g.year if season < 3 else g.year - 1, r.season, inc, cost, r.money_start, r.money])
	print("   income: " + ", ".join(SOURCES.map(func(k: String) -> String: return "%s %d" % [k, int(r.income.get(k, 0))])))
	print("   costs: " + ", ".join(COSTS.map(func(k: String) -> String: return "%s %d" % [k, int(r.costs.get(k, 0))])))
	print("   bought: " + (", ".join(r.bought) if not r.bought.is_empty() else "nothing"))
	if not r.waits.is_empty():
		print("   waiting: " + ", ".join(r.waits.keys().map(func(k: String) -> String: return "%s (%s)" % [k, r.waits[k]])))
	print("   collapses / passed out: %d" % r.knocked)
	print("   tools: " + r.tools)
	print("   animals: %s; built: %s; kitchen tools %d; recipes known %d; deepest mine floor %d" % [r.animals, r.built, r.kitchen_tools, r.recipes, r.deepest])
	var fished := []
	for place in ["river", MapManager.FARM]:
		var at: Dictionary = r.fish_at.get(place, {"n": 0, "g": 0})
		fished.append("%s %d fish, %d G" % ["river" if place == "river" else "pond", at.n, at.g])
	print("   fishing: %s; mine: %d trips (%d by the lift), deepest trip floor %d, food eaten there %d stamina" % [", ".join(fished), int(r.get("mine_trips", 0)), int(r.get("mine_lifts", 0)), int(r.get("mine_best", 0)), int(r.get("mine_food", 0))])
	print("   affection: " + r.hearts)
	if not r.contests.is_empty():
		print("   contests: " + "; ".join(r.contests))


func _final_report() -> void:
	print("")
	var values: Dictionary = g.ending_values()
	var rec: Dictionary = g.ending_record(values)
	print("== %s: the village record (%s)" % [g.date_text(), "the ending played" if g.events_seen.has("ending") else "graded now; the ending event has not played"])
	for row in rec.rows:
		print("   %-10s %8d  %d / %d stars" % [row.name, int(row.value), int(row.stars), int(row.max)])
	print("   %d / %d stars: rank %d, \"%s\"; closest: %s" % [rec.stars, rec.max, rec.rank, rec.title, rec.friend])
	var unfinished := _goals.map(func(goal: Array) -> String: return _goal_name(goal))
	print("   goals not reached: " + (", ".join(unfinished) if not unfinished.is_empty() else "none"))
	print("   events played: %d (%s)" % [_played.size(), ", ".join(_played.map(func(e: String) -> String: return e.get_slice(" ", 0)))])
	if _bugs.is_empty():
		print("play_year: OK (no problems seen)")
	else:
		print("play_year: %d problem(s): %s" % [_bugs.size(), "; ".join(_bugs)])
