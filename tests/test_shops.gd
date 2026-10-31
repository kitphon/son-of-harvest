extends SceneTree
## Headless shop checks (data/shops.json, Shop, ShopMenu, Game's shop calls and saved jobs,
## the shop maps and doors, the counter and the screen). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_shops.gd

const TOOLS: Array[String] = ["hoe", "can", "sickle", "hammer", "axe", "seeds", "food"]
const TOOLS_ALL: Array[String] = ["hoe", "can", "sickle", "hammer", "axe", "seeds", "food", "rod"]

var failures := 0
var crops: Dictionary
var foods: Dictionary
var tools_data: Dictionary
var fish_rules: Dictionary
var animal_rules: Dictionary
var _frame := 0


func _init() -> void:
	crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	foods = JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json")).foods
	tools_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	fish_rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/fish.json"))
	animal_rules = Animals.data()
	_data()
	_hours()
	_stock_and_deals()
	_upgrades()
	_maps()
	_game()
	_menu()
	_save()
	_rucksack()
	_animal_goods()
	_builds()
	_rod()
	_extras_save()


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
				elif e.to == "animal":
					check(animal_rules.kinds.has(e.item.trim_prefix("animal:")), "data: %s sells the animal %s" % [id, e.item])
				elif e.to == "feed":
					check(e.item == "feed", "data: %s sells feed" % id)
				elif animal_rules.get("items", {}).has(e.item):
					check(s.item_name(e.item) == animal_rules.items[e.item].name, "data: %s calls %s by its name" % [id, e.item])
				else:
					check(e.item.begins_with("food:") and foods.has(e.item.trim_prefix("food:")), "data: %s food %s exists" % [id, e.item])
		for tool in s.upgrade_tools:
			var top: int = fish_rules.rod.bite_factor.size() if tool == "rod" else tools_data.tools.get(tool, {}).get("max_charge", []).size()
			check(tool in TOOLS_ALL and top > 1, "data: %s upgrades the tool %s" % [id, tool])
			for lv in s.tool_upgrade_levels.get(tool, s.upgrade_levels):
				check(int(lv) >= 2 and int(lv) <= top, "data: %s level %s exists for %s" % [id, lv, tool])
		var last := 0
		for e in s.rucksack_levels:
			check(int(e.slots) > last and int(e.price) > 0, "data: %s rucksack levels grow" % id)
			last = int(e.slots)
		for b in s.builds:
			check(s.build_map == MapManager.HOME and int(s.builds[b].price) > 0 and int(s.builds[b].days) >= 1, "data: %s builds %s" % [id, b])
			var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/house.json"))
			check(raw.extensions.has(b), "data: house.json has the %s extension" % b)
	# Every mix of extensions makes a house that still has its futon, door and spawns free.
	var ext: Array = Shop.make("general", crops, foods).builds.keys()
	for mask in 1 << ext.size():
		var on := []
		for i in ext.size():
			if mask & (1 << i):
				on.append(ext[i])
		var r := MapManager.load_map("house", on)
		check(r[0] == "", "house with %s parses: %s" % [on, r[0]])
		if r[0] == "":
			var m: MapData = r[1]
			check(m.door_at(Vector2i(4, 6)).to == "farm" and m.prop_at(Vector2i(1, 1)).get("use", "") == "sleep", "house with %s: door and futon" % [on])
			for sp in m.spawns:
				check(not m.is_solid(m.spawns[sp][0]), "house with %s: spawn %s is free" % [on, sp])
			check(not m.is_solid(Vector2i(4, 5)), "house with %s: the way in is free" % [on])
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
	check(m.tabs == ["buy", "sell", "build"], "store tabs %s" % [m.tabs])
	check(ShopMenu.new(g, "smithy").tabs == ["tools"], "smithy tab")
	var rows := m.rows()
	check(rows.size() == 13 and rows[0].item == "rucksack" and rows[1].item == "animal:chicken" and rows[4].item == "seeds:turnip",
		"spring stock: the rucksack, 3 supplies, 4 for spring, 5 any")
	m.move(-1)
	check(m.cursor == 12, "the cursor wraps up")
	m.move(1)
	check(m.most() == 1, "one rucksack at a time")
	m.point(4)
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
	check(t.rows().size() == 6 and t.current().state == "offer" and t.current().price == 1000, "smithy offers")
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


## Bigger rucksacks: bought once per level, in order, the bag keeps what is in it.
func _rucksack() -> void:
	var s := Shop.make("general", crops, foods)
	check(s.rucksack_offer(8) == {"item": "rucksack", "level": 2, "slots": 12, "price": 2000, "to": "rucksack"}, "first bigger rucksack")
	check(s.rucksack_offer(12).slots == 16 and s.rucksack_offer(12).price == 6000, "then the biggest")
	check(s.rucksack_offer(16).is_empty() and Shop.make("smithy", crops, foods).rucksack_offer(8).is_empty(), "none past the top, none at the smithy")
	var g := _new_game()
	g.inventory.add("turnip", 3)
	g.money = 1999
	var r: Dictionary = g.shop_buy("general", "rucksack")
	check(not r.ok and g.money == 1999 and g.inventory.size("bag") == 8 and r.note == "Not enough money (2000 G)", "rucksack: no money")
	g.money = 9000
	r = g.shop_buy("general", "rucksack")
	check(r.ok and g.money == 7000 and g.inventory.size("bag") == 12 and g.count("turnip") == 3, "rucksack level 2: %s" % r.note)
	var m := ShopMenu.new(g, "general")
	check(m.rows()[0].item == "rucksack" and m.rows()[0].slots == 16, "the menu offers the next one")
	check(m.choose().begins_with("Your rucksack has 16") and g.money == 1000 and g.inventory.size("bag") == 16, "rucksack level 3 through the menu")
	check(m.rows()[0].item != "rucksack", "no rucksack row at the top level")
	g.money = 99999
	r = g.shop_buy("general", "rucksack")
	check(not r.ok and g.money == 99999 and g.inventory.size("bag") == 16 and r.note == "That's the biggest rucksack there is", "rucksack: max level")
	g.free()


## Chickens (only with room in the coop), feed into the coop's sack, Animal Medicine.
func _animal_goods() -> void:
	var g := _new_game()
	var room: int = g.animals.room("coop")
	check(room == 4 and g.shop_room("general", "animal:chicken") == 4, "the coop has room for 4 more")
	g.money = 1499
	var r: Dictionary = g.shop_buy("general", "animal:chicken")
	check(not r.ok and g.money == 1499 and g.animals.list.size() == 2, "chicken: no money")
	g.money = 99999
	r = g.shop_buy("general", "animal:chicken", 5)
	check(not r.ok and g.money == 99999 and g.animals.list.size() == 2 and r.note == "The coop is full", "five don't fit: none bought")
	r = g.shop_buy("general", "animal:chicken", 4)
	check(r.ok and g.money == 99999 - 4 * 1500 and g.animals.list.size() == 6 and g.animals.is_adult(g.animals.list[5]), "4 grown hens: %s" % r.note)
	r = g.shop_buy("general", "animal:chicken")
	check(not r.ok and g.animals.list.size() == 6 and r.note == "The coop is full", "chicken: coop full")
	var m := ShopMenu.new(g, "general")
	m.point(1)
	check(m.current().item == "animal:chicken" and m.most() == 1 and not m.choose().begins_with("Bought") and not m.last_ok, "the menu refuses a hen for a full coop")
	var feed: int = g.animals.feed_stock
	g.money = 199
	check(not g.shop_buy("general", "feed", 20).ok and g.animals.feed_stock == feed, "feed: no money")
	g.money = 200
	r = g.shop_buy("general", "feed", 20)
	check(r.ok and g.money == 0 and g.animals.feed_stock == feed + 20 and g.count("feed") == 0, "20 feed into the sack: %s" % r.note)
	g.money = 600
	r = g.shop_buy("general", "medicine", 2)
	check(r.ok and g.money == 0 and g.count("medicine") == 2 and r.note == "Bought 2 Animal Medicine for 600 G", "medicine: %s" % r.note)
	check(not g.shop_buy("general", "medicine").ok, "medicine: no money")
	# A kind the game doesn't know (cows before the barn) has no room; the shop refuses.
	var fx := {"shops": {"t": {"name": "T", "map": "store", "stock": {"any": [{"item": "animal:cow", "price": 10, "to": "animal"}]}}}}
	var t := Shop.make("t", crops, foods, fx)
	check(not t.buy(g.inventory, 100, "animal:cow", 1, "spring", 0).ok and t.buy(g.inventory, 100, "animal:cow", 1, "spring", 1).to == "animal",
		"no room: refused; room: the caller delivers")
	g.free()


## House extensions: ordered and paid at the store, one at a time, finished overnight on the
## ready day; the house map and the chest follow.
func _builds() -> void:
	var g := _new_game()
	var said := []
	g.message.connect(func(t): said.append(t))
	g.money = 4999
	var r: Dictionary = g.shop_build("general", "kitchen")
	check(not r.ok and g.money == 4999 and g.house_job.is_empty() and r.note == "Not enough money (5000 G)", "build: no money")
	g.money = 30000
	r = g.shop_build("general", "kitchen")
	check(r.ok and g.money == 25000 and g.house_job == {"build": "kitchen", "ready": 3, "shop": "general"}, "kitchen ordered: %s" % r.note)
	check(r.note == "Ordered the kitchen corner for 5000 G. Done in 3 days.", "order note: %s" % r.note)
	check(not g.shop_build("general", "kitchen").ok and not g.shop_build("general", "room").ok and g.money == 25000, "one job at a time")
	check(not g.shop_build("general", "nowhere").ok and not g.shop_build("smithy", "kitchen").ok, "unknown builds refused")
	var m := ShopMenu.new(g, "general")
	m.next_tab(2)
	var states := []
	for row in m.rows():
		states.append(row.state)
	check(m.tab_id() == "build" and states == ["busy", "building", "busy"], "build rows: %s" % [states])
	g.end_day()
	g.end_day()
	check(not g.has_built("kitchen") and MapManager.data("house").prop_at(Vector2i(1, 5)).is_empty(), "not done before the ready day")
	g.end_day()
	check(g.has_built("kitchen") and g.house_job.is_empty() and g.day_number() == 3, "done on day 3")
	check(MapManager.data("house").prop_at(Vector2i(1, 5)).get("kind", "") == "kamado", "the house map has the stove now")
	check(g.maps.id == "house" and "Hachiro the carpenter has finished the kitchen corner." in said, "the morning message")
	r = g.shop_build("general", "kitchen")
	check(not r.ok and r.note == "The kitchen corner is already built" and g.money == 25000, "build: already built")
	r = g.shop_build("general", "chest")
	check(r.ok and m.rows()[0].state == "building" and m.rows()[1].state == "done", "chest ordered, kitchen done")
	g.end_day()
	g.end_day()
	check(g.has_built("chest") and g.inventory.size("chest") == 48, "the chest has 48 slots")
	check(MapManager.data("house").prop_at(Vector2i(4, 1)).get("use", "") == "storage", "a chest lid in the house")
	r = g.shop_build("general", "room")
	for i in 5:
		g.end_day()
	var house := MapManager.data("house")
	check(g.has_built("room") and house.w == 12 and house.prop_at(Vector2i(9, 2)).get("kind", "") == "kotatsu", "the second room")
	check(not house.is_solid(Vector2i(7, 3)) and house.is_solid(Vector2i(7, 2)) and house.prop_at(Vector2i(1, 5)).kind == "kamado",
		"an opening into the room, the stove still there")
	check(g.house_built == ["kitchen", "chest", "room"], "all three built")
	g.new_game()
	check(MapManager.built.is_empty() and MapManager.data("house").w == 8, "a new game has the plain house")
	g.free()


## The rod at the smithy: levels from data/fish.json, a bite factor per level.
func _rod() -> void:
	var g := _new_game()
	check(g.tool_max_level("rod") == 4 and g.tool_level("rod") == 1 and is_equal_approx(g.rod_bite_factor(), 1.0), "the rod starts at level 1")
	check(g.max_charge("rod") == 0, "the rod still doesn't charge")
	var s: Shop = g.shop("smithy")
	check(s.upgrade_offer("rod", 1) == {"level": 2, "price": 800, "days": 2, "items": {}}, "rod level 2 offer")
	check(s.upgrade_offer("rod", 4).is_empty(), "no rod level 5")
	g.money = 799
	check(not g.shop_upgrade("smithy", "rod").ok and g.inventory.count("rod", ["tools"]) == 1, "rod: no money")
	g.money = 800
	var r: Dictionary = g.shop_upgrade("smithy", "rod")
	check(r.ok and g.money == 0 and g.inventory.count("rod", ["tools"]) == 0, "rod handed in: %s" % r.note)
	g.end_day()
	g.end_day()
	r = g.shop_collect("smithy")
	check(r.ok and g.tool_level("rod") == 2 and is_equal_approx(g.rod_bite_factor(), 1.2) and g.inventory.count("rod", ["tools"]) == 1, "rod level 2: %s" % r.note)
	g.tool_levels.rod = 4
	var t := ShopMenu.new(g, "smithy")
	check(t.rows()[5].item == "rod" and t.rows()[5].state == "top" and is_equal_approx(g.rod_bite_factor(), 1.6), "rod at the top level")
	g.money = 99999
	check(not g.shop_upgrade("smithy", "rod").ok and g.money == 99999, "rod: max level refused")
	g.free()


## Saving: built extensions, the job underway, the rod's level; older saves and broken ones.
func _extras_save() -> void:
	var a := _new_game()
	a.money = 99999
	a.shop_build("general", "room")
	for i in 5:
		a.end_day()
	a.shop_build("general", "chest")
	a.tool_levels.rod = 3
	a.go_to_map("house", Vector2i(9, 3), Vector2i.UP)   # in the second room
	var saved: Dictionary = a.to_dict()
	check(saved.house == {"built": ["room"], "job": {"build": "chest", "ready": 7, "shop": "general"}}, "saved house %s" % saved.house)
	check(saved.tool_levels.rod == 3, "the rod's level is saved")
	var b := _new_game()
	check(b.from_dict(JSON.parse_string(JSON.stringify(saved))) == "", "loads")
	check(b.to_dict() == saved and b.has_built("room") and MapManager.data("house").w == 12 and b.maps.id == "house", "the house comes back")
	b.end_day()
	b.end_day()
	check(b.has_built("chest") and b.inventory.size("chest") == 48, "the saved job finishes")
	var old := saved.duplicate(true)
	old.erase("house")
	old.map = {"id": "house", "x": 72, "y": 58, "facing": [0, -1]}
	old.tool_levels.erase("rod")
	check(b.from_dict(old) == "" and b.house_built.is_empty() and b.house_job.is_empty() and MapManager.data("house").w == 8 and b.tool_level("rod") == 1,
		"a save from before extensions and rod levels")
	var in_room := saved.duplicate(true)
	in_room.house.built = []
	check(b.from_dict(in_room) != "", "standing in a room that isn't built is refused")
	for bad in [[], {"built": ["attic"], "job": {}}, {"built": ["room", "room"], "job": {}}, {"built": "room", "job": {}},
			{"built": ["room"], "job": {"build": "room", "ready": 1, "shop": "general"}},
			{"built": ["room"], "job": {"build": "chest", "ready": -1, "shop": "general"}},
			{"built": ["room"], "job": {"build": "chest", "ready": 1, "shop": "smithy"}},
			{"built": ["room"], "job": {"build": "chest", "ready": 1}}]:
		var d := saved.duplicate(true)
		d.house = bad
		check(b.from_dict(d) != "", "refused house %s" % str(bad))
	var d2 := saved.duplicate(true)
	d2.tool_levels.rod = 5
	check(b.from_dict(d2) != "", "a rod past its top level is refused")
	a.free()
	b.free()
	MapManager.set_built([])


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
	g.fish_data = fish_rules
	g.rng.seed = 5
	g.new_game()
	return g


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
