extends SceneTree
## Headless shop checks (data/shops.json, Shop, ShopMenu, Game's shop calls and saved jobs,
## the shop maps and doors, the counter and the screen). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_shops.gd

const TOOLS: Array[String] = ["hoe", "can", "sickle", "hammer", "axe", "seeds", "food"]

var failures := 0
var crops: Dictionary
var foods: Dictionary
var tools_data: Dictionary
var _frame := 0


func _init() -> void:
	crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	foods = JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json")).foods
	tools_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	_data()
	_hours()
	_stock_and_deals()
	_upgrades()
	_maps()
	_game()
	_menu()
	_save()


# The real Game autoload and a screen need the tree, so they wait for the first frame.
func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_counter_and_screen()
		print("test_shops: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


## Every shop in the data has a known map with a counter for it, sane hours, stock with
## prices, and upgrades only for tools that have that level.
func _data() -> void:
	var ids := Shop.ids()
	check("general" in ids and "smithy" in ids, "data: a general store and a smithy")
	for id in ids:
		var s := Shop.make(id, crops, foods)
		check(s != null and s.name != "", "data: %s loads" % id)
		check(s.open_hour >= 0 and s.open_hour < s.close_hour and s.close_hour <= 24, "data: %s hours" % id)
		for day in s.days_off:
			check(day in Shop.DAY_NAMES, "data: %s day off %s is a weekday" % [id, day])
		check(MapManager.has(s.map) and MapManager.data(s.map).indoor, "data: %s has an indoor map" % id)
		var m := MapManager.data(s.map)
		var counter := false
		for p in m.props:
			counter = counter or (p.get("use", "") == "shop" and p.get("shop", "") == id)
		check(counter, "data: %s map has its counter" % id)
		check(m.spawns.has("counter") and m.prop_at(m.spawns.counter[0] + m.spawns.counter[1]).get("shop", "") == id,
			"data: %s counter spawn faces the counter" % id)
		check(m.spawns.has("keeper"), "data: %s has a keeper spot" % id)
		for season in ["spring", "summer", "fall", "winter"]:
			for e in s.stock(season):
				check(e.price > 0, "data: %s sells %s for a price" % [id, e.item])
				var crop: String = e.item.trim_prefix("seeds:")
				if e.item.begins_with("seeds:"):
					check(crops.has(crop) and season in crops[crop].seasons, "data: %s seeds %s in their season %s" % [id, crop, season])
				else:
					check(e.item.begins_with("food:") and foods.has(e.item.trim_prefix("food:")), "data: %s food %s exists" % [id, e.item])
		for tool in s.upgrade_tools:
			check(tool in TOOLS and tools_data.tools.has(tool), "data: %s upgrades the tool %s" % [id, tool])
			for lv in s.upgrade_levels:
				check(int(lv) >= 2 and int(lv) <= tools_data.tools[tool].max_charge.size(), "data: %s level %s exists for %s" % [id, lv, tool])
	var store := Shop.make("general", crops, foods)
	check(store.price("seeds:turnip", "spring") == int(crops.turnip.seed_price), "data: seed price from crops.json")
	check(store.price("food:milk", "summer") == 100, "data: a price set in shops.json wins")
	check(store.price("seeds:turnip", "summer") == -1, "data: spring seeds aren't sold in summer")
	check(Shop.make("nowhere", crops, foods) == null, "data: unknown shop")


func _fixture() -> Dictionary:
	return {"closed_message": "%s shut. %s, %s.", "shops": {"t": {"name": "Test Shop", "map": "store",
		"open": [9, 17], "days_off": ["sun", "wed"],
		"stock": {"spring": [{"item": "seeds:turnip"}, {"item": "seeds:corn", "price": 999}], "any": [{"item": "food:onigiri"}]},
		"buys": {"crop": 75, "food": 50},
		"upgrades": {"tools": ["hoe", "axe"], "levels": {"2": {"price": 100, "days": 2}, "3": {"price": 300, "days": 0, "items": {"turnip": 2}}}}}}}


func _hours() -> void:
	var s := Shop.make("t", crops, foods, _fixture())
	check(s.is_open(9, "mon") and s.is_open(16, "tue"), "open from 9 to before 17")
	check(not s.is_open(8, "mon") and not s.is_open(17, "mon"), "shut before and from closing")
	check(not s.is_open(12, "sun") and not s.is_open(12, "wed"), "shut on days off")
	check(s.closed_text(_fixture()) == "Test Shop shut. 9:00-17:00, closed Sun, Wed.", "closed text: %s" % s.closed_text(_fixture()))
	s.days_off.clear()
	check(s.days_off_text() == "open every day", "no days off")


func _stock_and_deals() -> void:
	var s := Shop.make("t", crops, foods, _fixture())
	var spring := s.stock("spring")
	check(spring.size() == 3 and spring[0].item == "seeds:turnip" and spring[2].item == "food:onigiri", "season first, then any")
	check(s.stock("fall").size() == 1, "out of season only the any stock")
	var inv := Inventory.empty(TOOLS, {"slots": {"tools": 7, "bag": 2, "hand": 1, "chest": 4}, "stack_max": 10})
	var r := s.buy(inv, 100, "seeds:turnip", 1, "spring")
	check(not r.ok and r.money == 100 and inv.count("seeds:turnip") == 0, "not enough money: nothing bought")
	r = s.buy(inv, 1000, "seeds:turnip", 3, "spring")
	check(r.ok and r.money == 1000 - 3 * int(crops.turnip.seed_price) and inv.count("seeds:turnip") == 3, "bought 3: %s" % r.note)
	check(not s.buy(inv, 9999, "seeds:turnip", 1, "summer").ok, "out of season can't be bought")
	check(not s.buy(inv, 9999, "food:milk", 1, "spring").ok, "not in stock can't be bought")
	inv.add("potato", 10)
	r = s.buy(inv, 99999, "food:onigiri", 1, "spring")
	check(not r.ok and r.money == 99999 and r.note == "Your rucksack is full", "a full rucksack refuses")
	r = s.buy(inv, 99999, "seeds:turnip", 7, "spring")
	check(r.ok and inv.count("seeds:turnip") == 10, "stacking onto the same bag still fits")
	# Selling: a percent of the value, rounded down; only what it buys, only what is carried.
	check(s.buy_back("potato") == int(crops.potato.sell) * 75 / 100, "crop bought at 75%")
	check(s.buy_back("food:onigiri") == int(foods.onigiri.price) / 2, "food bought at 50%")
	check(s.buy_back("seeds:turnip") == 0 and s.buy_back("hoe") == 0, "seeds and tools aren't bought")
	r = s.sell(inv, 0, "potato", 4)
	check(r.ok and r.money == 4 * s.buy_back("potato") and inv.count("potato") == 6, "sold 4: %s" % r.note)
	check(not s.sell(inv, 0, "potato", 7).ok and inv.count("potato") == 6, "can't sell more than carried")
	check(not s.sell(inv, 0, "seeds:turnip", 1).ok, "can't sell what it doesn't buy")
	var list := s.sellable(inv)
	check(list.size() == 1 and list[0].item == "potato" and list[0].have == 6, "sellable: what it buys from the rucksack")


func _upgrades() -> void:
	var s := Shop.make("t", crops, foods, _fixture())
	check(s.upgrade_offer("hoe", 1) == {"level": 2, "price": 100, "days": 2, "items": {}}, "offer for level 2")
	check(s.upgrade_offer("hoe", 3).is_empty() and s.upgrade_offer("can", 1).is_empty(), "no offer past the data or for other tools")
	var inv := Inventory.starting(TOOLS)
	var r := s.start_upgrade(inv, 50, "hoe", 1, 10)
	check(not r.ok and inv.id_at("tools", 0) == "hoe", "no money: the hoe stays")
	r = s.start_upgrade(inv, 500, "hoe", 1, 10, true)
	check(not r.ok and r.note == "One tool at a time, please", "busy smith refuses")
	r = s.start_upgrade(inv, 500, "hoe", 1, 10)
	check(r.ok and r.money == 400 and inv.id_at("tools", 0) == "" and inv.count("hoe", ["tools"]) == 0, "the hoe is handed in")
	check(r.job == {"tool": "hoe", "level": 2, "ready": 12, "slot": 0}, "job %s" % r.job)
	check(not Shop.job_ready(r.job, 11) and Shop.job_ready(r.job, 12), "ready after the days")
	check(not s.start_upgrade(inv, 500, "hoe", 1, 10).ok, "a tool not in the tool slots can't be handed in")
	check(Shop.give_back(inv, r.job) == "tools" and inv.id_at("tools", 0) == "hoe", "the hoe goes back in its slot")
	# Materials: needed and taken; the slot taken meanwhile: another tool slot, else the chest.
	r = s.start_upgrade(inv, 500, "axe", 2, 3)
	check(not r.ok and r.note.begins_with("Bring 2"), "materials missing: %s" % r.note)
	inv.add("turnip", 3)
	r = s.start_upgrade(inv, 500, "axe", 2, 3)
	check(r.ok and inv.count("turnip") == 1 and r.job.ready == 3 and r.note.ends_with("Ready now."), "materials taken, ready the same day")
	inv.slots.tools[4] = {"id": "hoe", "n": 1}
	inv.slots.tools[0] = {}
	check(Shop.give_back(inv, r.job) == "tools" and inv.id_at("tools", 0) == "axe", "the axe takes a free tool slot")
	for i in inv.size("tools"):
		if inv.id_at("tools", i) == "":
			inv.slots.tools[i] = {"id": "seeds", "n": 1}
	inv.slots.tools[0] = {"id": "seeds", "n": 1}
	var chest := inv.size("chest")
	check(Shop.give_back(inv, {"tool": "axe", "level": 3, "ready": 0, "slot": 0}) == "chest" and inv.count("axe", ["chest"]) == 1,
		"no free tool slot: into the chest")
	check(inv.size("chest") >= chest, "the chest never shrinks")


## The village doors lead into the shops and back; the counters are props.
func _maps() -> void:
	var t := MapManager.data("town")
	var store := t.door_at(Vector2i(23, 15))
	var smith := t.door_at(Vector2i(27, 6))
	check(store.to == "store" and store.shop == "general", "the noren house is the store")
	check(smith.to == "smithy" and smith.shop == "smithy", "the north-east house is the smithy")
	for id in ["store", "smithy"]:
		var m := MapManager.data(id)
		check(m.indoor and m.door_at(Vector2i(4, 6)).to == "town", "%s: indoors, door back to the village" % id)
		check(not m.is_solid(m.spawns.keeper[0]), "%s: the keeper spot is free" % id)


## Game: closed doors and counters, buying, selling, an upgrade over days.
func _game() -> void:
	var g := _new_game()
	var seen := {"opened": [], "said": []}
	g.shop_requested.connect(func(id): seen.opened.append(id))
	g.message.connect(func(t): seen.said.append(t))
	g.go_to_map("town", Vector2i(23, 16), Vector2i.UP)
	g.hour = 7
	g.use_door(MapManager.data("town").door_at(Vector2i(23, 15)))
	check(g.maps.id == "town" and seen.said.back().begins_with("Yorozu Store is closed"), "a shut shop's door says so")
	g.hour = 10
	g.use_door(MapManager.data("town").door_at(Vector2i(23, 15)))
	check(g.maps.id == "store", "an open shop's door leads in")
	check(g.weekday() == "mon" and g.day_number() == 0, "the first day is a Monday, day 0")
	g.day = 7
	check(g.weekday() == "sun", "day 7 is a Sunday")
	check(not g.open_shop("general") and seen.opened.is_empty(), "the store's counter is shut on Sunday")
	check(g.open_shop("general", true) and seen.opened == ["general"], "forced open (the screenshot flag)")
	g.day = 1
	check(g.open_shop("general") and seen.opened.size() == 2, "Monday 10:00: open")
	check(not g.open_shop("nowhere"), "no such shop")
	var money: int = g.money
	var r: Dictionary = g.shop_buy("general", "food:dango", 2)
	check(r.ok and g.money == money - 2 * int(foods.dango.price) and g.count("food:dango") == 2, "Game buys: %s" % r.note)
	g.inventory.add("turnip", 5)
	money = g.money
	r = g.shop_sell("general", "turnip", 5)
	check(r.ok and g.money == money + 5 * (int(crops.turnip.sell) * 80 / 100) and g.count("turnip") == 0, "Game sells: %s" % r.note)
	# The smithy: hand in, wait, collect one level up.
	g.money = 5000
	r = g.shop_upgrade("smithy", "hoe")
	check(r.ok and g.money == 4000 and g.shop_jobs.smithy.tool == "hoe" and g.inventory.count("hoe", ["tools"]) == 0, "hoe left at the smithy")
	check(not g.shop_upgrade("smithy", "axe").ok, "one job at a time")
	r = g.shop_collect("smithy")
	check(not r.ok and r.note == "Not ready yet. Come back on Spring 3, Year 1.", "too early: %s" % r.note)
	g.end_day()
	g.end_day()
	r = g.shop_collect("smithy")
	check(r.ok and g.tool_level("hoe") == 2 and g.inventory.id_at("tools", 0) == "hoe" and g.shop_jobs.is_empty(), "collected: %s" % r.note)
	check(int(g.tool_exp.hoe) == int(tools_data.tools.hoe.exp_to_level[0]), "the hoe's experience starts at level 2")
	check(not g.shop_collect("smithy").ok, "nothing more to collect")
	check(g.date_of(0) == "Spring 1, Year 1" and g.date_of(125) == "Spring 6, Year 2", "dates of day numbers")
	g.free()


func _menu() -> void:
	var g := _new_game()
	var m := ShopMenu.new(g, "general")
	check(m.tabs == ["buy", "sell"], "store tabs %s" % [m.tabs])
	check(ShopMenu.new(g, "smithy").tabs == ["tools"], "smithy tab")
	var rows := m.rows()
	check(rows.size() == 9 and rows[0].item == "seeds:turnip", "spring stock: 4 for spring + 5 any")
	m.move(-1)
	check(m.cursor == 8, "the cursor wraps up")
	m.move(1)
	g.money = 300
	m.change_count(1)
	check(m.count == 2 and m.total() == 240, "two turnip bags cost 240")
	m.change_count(1)
	check(m.count == 1, "only two affordable: wraps to 1")
	m.change_count(-1)
	check(m.count == 2, "left from 1 goes to the most")
	var before: int = g.count("seeds:turnip")
	check(m.choose().begins_with("Bought 2") and m.last_ok and g.money == 60 and g.count("seeds:turnip") == before + 2, "bought through the menu")
	check(m.count == 1, "the count drops to what is still affordable")
	m.next_tab()
	check(m.tab_id() == "sell" and m.rows().is_empty() and m.choose() == "Nothing to sell here", "nothing to sell")
	g.inventory.add("potato", 3)
	check(m.rows().size() == 1 and m.most() == 3, "potatoes to sell")
	m.change_count(-1)
	m.choose()
	check(g.count("potato") == 0 and m.rows().is_empty() and m.cursor == 0, "sold them all, list empty")
	var t := ShopMenu.new(g, "smithy")
	check(t.rows().size() == 5 and t.current().state == "offer" and t.current().price == 1000, "smithy offers")
	g.money = 999
	check(not t.choose().is_empty() and not t.last_ok and g.shop_jobs.is_empty(), "not enough money for the smith")
	g.money = 2000
	t.choose()
	check(t.last_ok and t.rows()[0].state == "away" and t.rows()[1].state == "busy", "hoe away, others wait")
	g.tool_levels.axe = 5
	check(t.rows()[4].state == "top", "a top-level axe")
	g.inventory.slots.tools[2] = {}
	g.shop_jobs.clear()
	check(t.rows()[2].state == "missing", "a sickle not in the tool slots")
	g.free()


func _save() -> void:
	var a := _new_game()
	a.money = 3000
	a.shop_upgrade("smithy", "can")
	var saved: Dictionary = a.to_dict()
	check(saved.shop_jobs == {"smithy": {"tool": "can", "level": 2, "ready": 2, "slot": 1}}, "saved job %s" % saved.shop_jobs)
	var b := _new_game()
	check(b.from_dict(JSON.parse_string(JSON.stringify(saved))) == "", "loads")
	check(b.to_dict() == saved and b.shop_jobs.smithy.ready == 2 and b.inventory.count("can", ["tools"]) == 0, "the job comes back")
	var old := saved.duplicate(true)
	old.erase("shop_jobs")
	check(b.from_dict(old) == "" and b.shop_jobs.is_empty(), "a save from before shops loads with no jobs")
	for bad in [[], {"nowhere": {"tool": "can", "level": 2, "ready": 2, "slot": 1}},
			{"general": {"tool": "can", "level": 2, "ready": 2, "slot": 1}},
			{"smithy": {"tool": "seeds", "level": 2, "ready": 2, "slot": 1}},
			{"smithy": {"tool": "can", "level": 9, "ready": 2, "slot": 1}},
			{"smithy": {"tool": "can", "level": 2, "ready": -1, "slot": 1}},
			{"smithy": {"tool": "can", "level": 2, "ready": 2}}]:
		var d := saved.duplicate(true)
		d.shop_jobs = bad
		check(b.from_dict(d) != "", "refused jobs %s" % str(bad))
	a.free()
	b.free()


## On the real Game: E at the counter opens the screen (paused), Esc closes it.
func _counter_and_screen() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.hour = 10
	var screen: Node = load("res://scripts/ui/shop_screen.gd").new()
	root.add_child(screen)
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	g.go_to_map("store", Vector2i(3, 4), Vector2i.UP)
	actions.interact(Vector2i(3, 3))
	check(screen.is_open() and g.paused() and screen.menu.shop.id == "general", "the counter opens the store's screen")
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	screen._input(esc)
	check(not screen.is_open() and not g.paused(), "Esc closes it")
	g.hour = 18
	actions.interact(Vector2i(3, 3))
	check(not screen.is_open(), "after hours the counter stays shut")
	screen.free()
	g.new_game()


func _new_game() -> Node:
	var g: Node = load("res://scripts/autoload/game.gd").new()
	g.crops = crops
	g.tools_data = tools_data
	g.set_food_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json")))
	g.rng.seed = 5
	g.new_game()
	return g


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
