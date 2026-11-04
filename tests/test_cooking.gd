extends SceneTree
## Headless checks for cooking (Cooking + data/recipes.json, Game.cook, CookingMenu, the recipe
## lessons, kitchen tools bought at the store and saved, the kitchen corner's stove in the real
## Game). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_cooking.gd

var failures := 0


func _init() -> void:
	_data()
	_prices()
	_cooking()
	_menu()
	_lessons()
	_cards()
	_wild()
	_tools()


## The data: every recipe makes a kitchen-only food, every need is a real item or group, every
## dish has an icon; a few recipes are known at the start, the rest are taught somewhere.
func _data() -> void:
	var d := Cooking.data()
	var foods: Dictionary = _json("res://data/foods.json").foods
	var crops: Dictionary = _json("res://data/crops.json")
	var products: Dictionary = _json("res://data/animals.json").items
	var wild: Dictionary = _json("res://data/forage.json").items
	var real := func(it: String) -> bool:
		return crops.has(it) or products.has(it) or (it.begins_with("wild:") and wild.has(it.trim_prefix("wild:")))
	check(Cooking.check(d, foods) == "", "data/recipes.json passes: %s" % Cooking.check(d, foods))
	var starters := 0
	for id in Cooking.ids():
		var r := Cooking.recipe(id)
		starters += 1 if r.get("start", false) else 0
		check(foods.has(id) and (id == "onigiri" or not foods[id].get("shop", false)), "%s is a kitchen dish in foods.json" % id)
		check(String(r.get("about", "")) != "" and PixelFont.width(String(r.about)) <= 300 - 12, "%s has a short about line" % id)
		check(PixelFont.missing(String(r.about) + String(foods[id].name)) == "", "the pixel font has %s's text" % id)
		var img := PlaceholderArt.tex(PlaceholderArt.item_key(Cooking.dish(id))).get_image()
		check(img.get_size() == Vector2i(14, 14) and img.get_used_rect().has_area(), "%s has an icon" % id)
		for need in r.needs:
			if need.has("item"):
				var it := String(need.item)
				check(real.call(it) or (it.begins_with("food:") and foods.has(it.trim_prefix("food:"))), "%s needs a real item (%s)" % [id, it])
		if r.has("card"):
			check(real.call(String(r.card)) and not products.has(String(r.card)) and not r.get("start", false), "%s's card comes with a real crop or wild thing (%s)" % [id, r.card])
		check(int(foods[id].get("sell", 0)) > 0, "%s can be shipped (sell %d)" % [id, int(foods[id].get("sell", 0))])
	for g in d.groups:
		for it in d.groups[g].get("items", []):
			check(real.call(it), "group %s: %s is a real item" % [g, it])
	check(starters >= 3 and starters < Cooking.ids().size(), "a few recipes known at the start (%d of %d)" % [starters, Cooking.ids().size()])
	check(Cooking.check({"recipes": {"pizza": {"needs": [{"item": "turnip", "n": 1}]}}}, foods) != "", "a recipe for a food that doesn't exist is refused")
	check(Cooking.check({"recipes": {"miso_soup": {"needs": [{"group": "nope", "n": 1}]}}}, foods) != "", "an unknown group is refused")
	check(Cooking.check({"recipes": {"miso_soup": {"needs": [{"item": "turnip", "n": 0}]}}}, foods) != "", "a need of 0 is refused")
	check(Cooking.check({"recipes": {"miso_soup": {"needs": []}}}, foods) != "", "a recipe without needs is refused")


## Dish prices (FEEDBACK item 5): a dish made from fish, eggs or milk sells for a modest gain
## over its cheapest ingredients shipped raw (the cheapest fish of the year, plain eggs and
## milk), never the shortcut grilled fish was (one 18 G fish -> an 80 G dish), and a dearer
## fish or a better grade is worth more raw than in the dish.
func _prices() -> void:
	var d := Cooking.data()
	var foods: Dictionary = _json("res://data/foods.json").foods
	var crops: Dictionary = _json("res://data/crops.json")
	var products: Dictionary = _json("res://data/animals.json").items
	var wild: Dictionary = _json("res://data/forage.json").items
	var fish: Dictionary = _json("res://data/fish.json").fish
	var cheap_fish := 1 << 30
	for f in fish.values():
		if not f.get("once", false):
			cheap_fish = mini(cheap_fish, int(f.sell))
	var value := func(it: String) -> int:
		if crops.has(it):
			return int(crops[it].sell)
		if products.has(it):
			return int(products[it].sell)
		if it.begins_with("wild:"):
			return int(wild[it.trim_prefix("wild:")].sell)
		return int(foods[it.trim_prefix("food:")].get("price", 0))
	for id in Cooking.ids():
		var r := Cooking.recipe(id)
		var raw := 0
		var animal := false
		for need in r.needs:
			var each := 0
			if need.has("item"):
				each = value.call(String(need.item))
			elif d.groups[need.group].has("prefix"):
				each = cheap_fish
				animal = true
			else:
				var items: Array = d.groups[need.group].items
				each = items.map(func(it: String) -> int: return value.call(it)).min()
				animal = animal or products.has(String(items[0]))
			raw += each * int(need.n)
		var dish := int(foods[id].sell) * Cooking.makes(id)
		if animal:
			check(dish > raw and dish * 100 <= raw * 150, "%s sells for a modest gain over its cheapest ingredients (%d G for %d G raw)" % [id, dish, raw])
	check(int(foods.grilled_fish.sell) < int(fish.koi.sell) and int(foods.grilled_fish.sell) < int(fish.wakasagi.sell), "a carp or a smelt is worth more raw than grilled")
	check(int(foods.tamagoyaki.sell) <= 2 * int(products.egg_good.sell), "good eggs are worth as much raw as rolled")


## Game.cook: the kitchen, known recipes, ingredients from the rucksack, the hand and the chest,
## the dish into the rucksack, nothing changes when it can't be done.
func _cooking() -> void:
	var g := _game()
	_empty_bag(g)
	g.inventory.add("cucumber", 1)
	var r: Dictionary = g.cook("onigiri")
	check(not r.ok and r.note == "There's no kitchen here yet", "no kitchen, no cooking (%s)" % r.note)
	g.house_built.append("kitchen")
	var start: Array[String] = []
	for id in Cooking.ids():
		if Cooking.recipe(id).get("start", false):
			start.append(id)
	check(Cooking.known_ids(g.flags) == start, "a new game knows the start recipes %s" % [Cooking.known_ids(g.flags)])
	r = g.cook("turnip_stew")
	check(not r.ok and r.note.begins_with("You don't know"), "an unknown recipe can't be cooked")
	check(not g.cook("pizza").ok, "no such recipe")

	# Onigiri: one pickle vegetable, makes two.
	r = g.cook("onigiri")
	check(r.ok and r.note == "Made onigiri x2", "onigiri cooked (%s)" % r.note)
	check(g.count("cucumber") == 0 and g.count("food:onigiri") == 2, "the cucumber went into two onigiri")
	var before: Dictionary = g.inventory.to_dict()
	r = g.cook("onigiri")
	check(not r.ok and r.note == "Not enough to make onigiri", "nothing to pickle: not cooked (%s)" % r.note)
	check(g.inventory.to_dict() == before, "a failed cooking changes nothing")

	# A learned recipe, its needs split between the rucksack and the chest.
	g.flags[Cooking.flag("turnip_stew")] = true
	check(Cooking.known("turnip_stew", g.flags), "the flag teaches the recipe")
	g.inventory.add("turnip", 1)
	g.inventory.add("turnip", 2, ["chest"])
	g.inventory.add("carrot", 1, ["chest"])
	before = g.inventory.to_dict()
	r = g.cook("turnip_stew")
	check(not r.ok and r.note == "You need a kitchen knife and a clay pot for that" and g.inventory.to_dict() == before,
		"no tools: the stew isn't cooked, nothing used (%s)" % r.note)
	g.kitchen_tools.append("knife")
	r = g.cook("turnip_stew")
	check(not r.ok and r.note == "You need a clay pot for that", "the knife alone isn't enough (%s)" % r.note)
	g.kitchen_tools.append("pot")
	check(g.cook("turnip_stew").ok, "turnip stew from the rucksack and the chest")
	check(g.inventory.count("turnip", ["bag", "chest"]) == 1 and g.inventory.count("turnip", ["bag"]) == 0, "the rucksack's turnip is used first")
	check(g.inventory.count("carrot", ["chest"]) == 0 and g.count("food:turnip_stew") == 1, "the chest's carrot used, the stew in the rucksack")

	# Groups: plain eggs before better ones; any fish; the hand counts too.
	g.inventory.add("egg_best", 1)
	g.inventory.add("egg_good", 1)
	g.inventory.add("egg", 1, ["chest"])
	var need := {"group": "egg", "n": 2}
	check(Cooking.candidates(need, g.inventory) == (["egg", "egg_good", "egg_best"] as Array[String]), "eggs in the group's order")
	check(Cooking.have(need, g.inventory) == 3, "three eggs to cook with")
	check(g.cook("tamagoyaki").ok and g.count("egg_best") == 1 and g.inventory.count("egg", ["chest"]) == 0 and g.count("egg_good") == 0,
		"tamagoyaki takes the plain and the good egg, keeps the golden one")
	g.held = "fish:koi"
	check(Cooking.fits({"group": "fish"}, "fish:koi") and not Cooking.fits({"group": "fish"}, "koi"), "any fish by its prefix")
	check(g.cook("grilled_fish").ok and g.held == "" and g.count("food:grilled_fish") == 1, "the fish overhead is grilled")
	check(g.eat("grilled_fish") or g.stamina == g.max_stamina, "a dish eats like any food")

	# The rucksack full: the dish has nowhere to go, unless the cooking frees a slot.
	_empty_bag(g)
	for i in g.inventory.size("chest"):
		g.inventory.slots.chest[i] = {}
	for i in g.inventory.size("bag"):
		g.inventory.slots.bag[i] = {"id": "seeds:turnip" if i == 0 else "junk_%d" % i, "n": 1}
	g.inventory.add("eggplant", 1, ["chest"])
	before = g.inventory.to_dict()
	r = g.cook("miso_soup")
	check(not r.ok and r.note == "No room in the rucksack for it" and g.inventory.to_dict() == before, "a full rucksack: nothing cooked, nothing used")
	g.inventory.slots.bag[1] = {"id": "onion", "n": 1}
	check(g.cook("miso_soup").ok and g.count("onion") == 0 and g.inventory.count("eggplant", ["chest"]) == 1 and g.count("food:miso_soup") == 1,
		"the onion's slot takes the soup (the group's order: onion before eggplant)")

	# Learned recipes are flags, so they are saved.
	_empty_bag(g)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	g.new_game()
	check(not Cooking.known("turnip_stew", g.flags), "a new game forgets the lesson")
	check(g.from_dict(saved) == "", "the save loads")
	check(Cooking.known("turnip_stew", g.flags), "the learned recipe survives a save")
	saved.flags = {}
	check(g.from_dict(saved) == "" and Cooking.known_ids(g.flags) == start, "a save without lessons knows the start recipes")
	g.free()


## CookingMenu: the known recipes, ready or not, what they need, cooking the cursor's.
func _menu() -> void:
	var g := _game()
	g.house_built.append("kitchen")
	_empty_bag(g)
	var m := CookingMenu.new(g)
	var rows := m.rows()
	check(rows.size() == Cooking.known_ids(g.flags).size() and rows[0].id == Cooking.known_ids(g.flags)[0], "one row per known recipe")
	check(rows.all(func(r): return not r.ready), "nothing to cook with: none ready")
	m.cursor = Cooking.known_ids(g.flags).find("tamagoyaki")
	check(m.needs_text() == "2 any egg (0)", "what tamagoyaki needs (%s)" % m.needs_text())
	g.inventory.add("egg", 2)
	check(m.current().ready and m.needs_text() == "2 any egg (2)", "two eggs: ready")
	check(m.choose() == "Made tamagoyaki" and m.last_ok and g.count("food:tamagoyaki") == 1, "Enter cooks it")
	check(m.choose() == "Not enough to make tamagoyaki" and not m.last_ok, "again: not enough")
	m.move(-1)
	check(m.current().id == Cooking.known_ids(g.flags)[maxi(Cooking.known_ids(g.flags).find("tamagoyaki") - 1, 0)], "up moves")
	m.cursor = 0
	m.move(-1)
	check(m.cursor == rows.size() - 1, "up from the top wraps")
	check(m.point(1) and m.cursor == 1 and not m.point(99), "the mouse points at rows")
	g.flags[Cooking.flag("ochazuke")] = true
	m.cursor = m.rows().map(func(r): return r.id).find("ochazuke")
	check(m.needs_text() == "1 any fish (0), 1 Green tea (%d)" % g.count("food:green_tea"), "ochazuke needs (%s)" % m.needs_text())
	check(m.rows().size() == rows.size() + 1, "a lesson adds a row")
	g.free()


## The lessons: one event per taught recipe sets its flag, and a trigger row plays it.
func _lessons() -> void:
	var taught := {}
	var dir := DirAccess.open("res://data/events")
	for f in dir.get_files():
		if f.begins_with("recipe_") and f.ends_with(".json"):
			var ev: Dictionary = _json("res://data/events/" + f)
			check(EventRunner.open(f.trim_suffix(".json"), null).error == "", "%s is a good event" % f)
			for s in ev.steps:
				if s.get("do", "") == "set":
					for k in s.flags:
						taught[k] = f.trim_suffix(".json")
	var rows := {}
	for f in dir.get_files():
		if f.begins_with("triggers_"):
			for row in _json("res://data/events/" + f).rows:
				rows[row.event] = row
	for id in Cooking.ids():
		if Cooking.recipe(id).get("start", false) or Cooking.recipe(id).has("card"):
			continue
		var ev := String(taught.get(Cooking.flag(id), ""))
		check(ev != "", "%s is taught by an event" % id)
		check(rows.has(ev) and Cooking.flag(id) in rows[ev].get("not_flags", []), "%s plays from a trigger row until it is learned" % ev)
	var s := {"year": 1, "season": "spring", "day": 1, "weekday": "mon", "time": 600, "weather": "sunny",
		"flags": {}, "seen": {}, "cell": Vector2i.ZERO, "who": "tome", "hearts": {"tome": 1}}
	var town := EventTriggers.open("town")
	check(town.error == "" and town.pick("talk", s) == "recipe_tome", "a friendly talk with Tome teaches the stew")
	check(town.pick("talk", s.merged({"hearts": {"tome": 0}}, true)) == "", "not to a stranger")
	check(town.pick("talk", s.merged({"flags": {Cooking.flag("turnip_stew"): true}}, true)) == "", "not twice")
	var house := EventTriggers.open("house")
	var radio := s.merged({"spot": Vector2i(6, 1), "weekday": "sat"}, true)
	check(house.pick("examine", radio) == "recipe_radio", "the radio's Saturday cooking hour")
	check(house.pick("examine", radio.merged({"weekday": "fri"}, true)) == "house_radio", "on other days only static")


## The daikon and rice recipes: their cards come with the first of the crop shipped (by the bin
## or thrown in); dishes ship at their sell price, from the hand only.
func _cards() -> void:
	var g := _game()
	_empty_bag(g)
	g.house_built.append("kitchen")
	var daikon := Cooking.cards("daikon")
	var rice := Cooking.cards("rice")
	check(daikon == (["furofuki_daikon", "daikon_fish"] as Array[String]) and rice == (["takikomi_gohan", "kinako_mochi"] as Array[String]),
		"two recipe cards each for daikon and rice (%s, %s)" % [daikon, rice])
	check(Cooking.cards("turnip").is_empty(), "no card with turnips")
	check(not Cooking.known("furofuki_daikon", g.flags) and not g.cook("furofuki_daikon").ok, "no card yet: unknown")
	g.inventory.add("daikon", 3)
	g.inventory.take("daikon", 2)
	check(g.ship_produce() == int(g.crops.daikon.sell), "the daikon shipped at %d G" % int(g.crops.daikon.sell))
	check(daikon.all(func(id): return Cooking.known(id, g.flags)), "the first daikon shipped brings its cards")
	check(not Cooking.known("kinako_mochi", g.flags), "rice cards wait for rice")
	g.held = "rice"
	var t: Dictionary = g.throw_held(Vector2i(8, 5), Vector2i.UP)
	check(t.result == "ship" and rice.all(func(id): return Cooking.known(id, g.flags)), "rice thrown in the bin brings the rice cards (%s)" % t.result)
	g.inventory.add("rice", 2)
	g.inventory.add("carrot", 1)
	g.kitchen_tools.assign(Cooking.tool_ids())
	check(g.cook("kinako_mochi").ok and g.count("food:kinako_mochi") == 3 and g.count("rice") == 0, "kinako mochi from two rice, three of them")
	g.inventory.add("daikon", 1)
	g.inventory.add("fish:funa", 1)
	check(not g.cook("takikomi_gohan").ok, "takikomi gohan needs rice")
	check(g.cook("daikon_fish").ok and g.count("food:daikon_fish") == 1, "fish and daikon cooked")
	var known_after := Cooking.known_ids(g.flags)
	var saved: Dictionary = g.to_dict()
	g.new_game()
	check(g.from_dict(saved) == "" and Cooking.known_ids(g.flags) == known_after, "the cards survive a save")
	# Dishes in the rucksack stay there; one held out goes in at its sell price.
	_empty_bag(g)
	g.bin_total = 0
	g.inventory.add("food:kinako_mochi", 3)
	g.inventory.add("turnip", 1)
	var sell := int(g.foods.kinako_mochi.sell)
	check(g.sell_price("food:kinako_mochi") == sell and g.sell_price("food:kagami_mochi") == 0, "a dish's sell price from foods.json")
	check(g.ship_produce() == int(g.crops.turnip.sell) and g.count("food:kinako_mochi") == 3, "the bin leaves the rucksack's dishes alone")
	g.inventory.move("bag", g.inventory.slots.bag.find_custom(func(s): return s.get("id", "") == "food:kinako_mochi"), "hand", 0)
	check(g.inventory.count("food:kinako_mochi", ["hand"]) == 3, "three mochi in hand")
	check(g.ship_produce() == 3 * sell and g.count("food:kinako_mochi") == 0, "held out at the bin: shipped (%d G)" % g.bin_total)
	check(int(g.shipped.get("food:kinako_mochi", 0)) == 3 and g.ending_values().shipped_value >= 3 * sell, "dishes count as shipped for the record")
	g.free()


## Wild things in recipes (data/forage.json): the greens and mushrooms groups use the cheapest
## first, Haru, Genzo and Kiku teach in their parts once they know the farmer, and the first
## bamboo shoot, chestnuts or matsutake shipped brings a card.
func _wild() -> void:
	var g := _game()
	_empty_bag(g)
	g.house_built.append("kitchen")
	g.kitchen_tools.assign(Cooking.tool_ids())
	check(Cooking.cards("wild:bamboo_shoot") == (["takenoko_gohan"] as Array[String]) and Cooking.cards("wild:chestnut") == (["kuri_gohan"] as Array[String])
		and Cooking.cards("wild:matsutake") == (["dobin_mushi"] as Array[String]), "cards with bamboo shoots, chestnuts and matsutake")
	g.inventory.add("wild:bamboo_shoot", 2)
	check(g.ship_produce() == 2 * g.sell_price("wild:bamboo_shoot") and g.sell_price("wild:bamboo_shoot") > 0, "bamboo shoots shipped")
	check(Cooking.known("takenoko_gohan", g.flags) and not Cooking.known("kuri_gohan", g.flags), "the first bamboo shoot brings its card, only that one")
	g.held = "wild:matsutake"
	var t: Dictionary = g.throw_held(Vector2i(8, 5), Vector2i.UP)
	check(t.result == "ship" and Cooking.known("dobin_mushi", g.flags), "a matsutake thrown in brings dobin mushi (%s)" % t.result)
	# The greens: the cheapest go first, a dear butterbur bud is kept back while there's enough.
	for f in ["sansai_tempura", "kinoko_jiru", "kusa_mochi"]:
		g.flags[Cooking.flag(f)] = true
	g.inventory.add("wild:fukinoto", 1)
	g.inventory.add("wild:tsukushi", 1)
	g.inventory.add("wild:warabi", 1)
	var r: Dictionary = g.cook("sansai_tempura")
	check(r.ok and g.count("food:sansai_tempura") == 1 and g.count("wild:fukinoto") == 1 and g.count("wild:tsukushi") == 0 and g.count("wild:warabi") == 0,
		"tempura from horsetail and bracken, the butterbur bud kept (%s)" % r.note)
	check(not g.cook("sansai_tempura").ok, "one green is not enough")
	g.inventory.add("wild:matsutake", 1)
	g.inventory.add("wild:nameko", 1)
	g.inventory.add("turnip", 1)
	check(g.cook("kinoko_jiru").ok and g.count("wild:nameko") == 0 and g.count("wild:matsutake") == 1, "mushroom soup takes the nameko, not the matsutake")
	g.inventory.add("rice", 2)
	g.inventory.add("wild:yomogi", 1)
	check(g.cook("kusa_mochi").ok and g.count("food:kusa_mochi") == 3 and g.count("rice") == 0, "kusa mochi from two rice and mugwort, three of them")
	g.inventory.add("fish:funa", 1)
	check(g.cook("dobin_mushi").ok and g.count("wild:matsutake") == 0, "dobin mushi from the matsutake and a fish")
	g.free()
	# The lessons: in their parts and homes (and Haru on the hill), once known to band 1, once.
	var s := {"year": 1, "season": "spring", "day": 3, "weekday": "wed", "time": 600, "weather": "sunny",
		"flags": {}, "seen": {}, "cell": Vector2i.ZERO, "who": "haru", "hearts": {"haru": 1, "genzo": 1, "kiku": 1}}
	for m in [["kaminoda", "haru"], ["kaminoda", "genzo"], ["hill", "haru"], ["haru_house", "haru"], ["genzo_house", "genzo"], ["minamino", "kiku"], ["kiku_house", "kiku"]]:
		var table := EventTriggers.open(m[0])
		check(table.error == "" and table.pick("talk", s.merged({"who": m[1]}, true)) == "recipe_" + m[1], "%s teaches in %s" % [m[1], m[0]])
		check(table.pick("talk", s.merged({"who": m[1], "hearts": {m[1]: 0}}, true)) == "", "%s: not to a stranger" % m[1])
	var lesson := {"haru": "sansai_tempura", "genzo": "kinoko_jiru", "kiku": "kusa_mochi"}
	for who in lesson:
		var learned := s.merged({"who": who, "flags": {Cooking.flag(lesson[who]): true}}, true)
		check(EventTriggers.open("kaminoda" if who != "kiku" else "minamino").pick("talk", learned) == "", "%s: not twice" % who)
	check(EventTriggers.open("kaminoda").pick("talk", s.merged({"who": "kiku"}, true)) == "", "Kiku doesn't teach in Kaminoda")


## Kitchen tools: the data, the start recipes need none, the store sells each once after the
## kitchen is built, the cooking menu says what is missing, the save keeps them and an old
## save's kitchen gets the tools of the recipes it already knew.
func _tools() -> void:
	var d := Cooking.data()
	var foods: Dictionary = _json("res://data/foods.json").foods
	var used := {}
	for id in Cooking.ids():
		for t in Cooking.tools(id):
			used[t] = true
		if Cooking.recipe(id).get("start", false):
			check(Cooking.tools(id).is_empty(), "%s (a start recipe) cooks with no tools" % id)
	for t in Cooking.tool_ids():
		var info := Cooking.tool_info(t)
		check(used.has(t), "some recipe uses the %s" % t)
		check(PixelFont.missing(String(info.name) + String(info.get("about", ""))) == "", "the pixel font has the %s's text" % t)
		check(PixelFont.width(String(info.get("about", "")) + " For the kitchen.") <= 300 - 12, "the %s's about line fits the shop" % t)
		var img := PlaceholderArt.tex(PlaceholderArt.item_key("kitchen:" + t)).get_image()
		check(img.get_size() == Vector2i(14, 14) and img.get_used_rect().has_area(), "the %s has an icon" % t)
	check(Cooking.missing_tools("turnip_stew", ["knife"]) == (["pot"] as Array[String]), "the stew still lacks the pot")
	check(Cooking.tools_for(["onigiri", "ochazuke", "turnip_stew"]) == (["knife", "pot", "teapot"] as Array[String]), "tools for known recipes, in tool order")
	var bad := d.duplicate(true)
	bad.recipes.turnip_stew.tools = ["wok"]
	check(Cooking.check(bad, foods) != "", "an unknown tool is refused")
	bad = d.duplicate(true)
	bad.recipes.onigiri.tools = ["knife"]
	check(Cooking.check(bad, foods) != "", "a start recipe that needs a tool is refused")
	bad = d.duplicate(true)
	bad.tools.knife.price = 0
	check(Cooking.check(bad, foods) != "", "a tool without a price is refused")

	# The store: nothing before the kitchen, each tool once after it.
	var g := _game()
	_empty_bag(g)
	g.money = 5000
	var s: Shop = g.shop("general")
	check(s.kitchen_offers(g.kitchen_tools, g.house_built).is_empty(), "no kitchen tools for sale before the kitchen")
	var r: Dictionary = g.shop_buy("general", "kitchen:knife")
	check(not r.ok and r.note == "There's no kitchen to put it in yet" and g.money == 5000 and g.kitchen_tools.is_empty(), "no kitchen: not sold (%s)" % r.note)
	var m := ShopMenu.new(g, "general")
	check(not m.rows().any(func(row): return String(row.item).begins_with("kitchen:")), "no kitchen rows in the buy tab yet")
	g.house_built.append("kitchen")
	var offers := s.kitchen_offers(g.kitchen_tools, g.house_built)
	check(offers.size() == Cooking.tool_ids().size() and offers[0] == {"item": "kitchen:knife", "tool": "knife", "price": 600, "to": "kitchen"},
		"after the kitchen: every tool for sale (%s)" % [offers.slice(0, 1)])
	var rows := m.rows()
	check(rows[1].item == "kitchen:knife" and rows[0].item == "rucksack", "the buy tab: the rucksack, then the kitchen tools")
	m.cursor = 1
	check(m.most() == 1 and s.item_name("kitchen:knife") == "Kitchen knife", "one knife at a time, by its name")
	check(m.choose() == "Bought a kitchen knife for 600 G" and m.last_ok and g.money == 4400 and g.kitchen_tools == (["knife"] as Array[String]),
		"the knife bought through the menu")
	check(not m.rows().any(func(row): return row.item == "kitchen:knife"), "the knife's row is gone")
	r = g.shop_buy("general", "kitchen:knife")
	check(not r.ok and r.note == "You already have a kitchen knife" and g.money == 4400, "not twice")
	check(g.inventory.count("kitchen:knife", ["bag", "hand", "chest"]) == 0, "a kitchen tool doesn't take a rucksack slot")
	g.money = 100
	r = g.shop_buy("general", "kitchen:mallet")
	check(not r.ok and r.note == "Not enough money (2000 G)" and not "mallet" in g.kitchen_tools, "no money, no mallet")
	r = g.shop_buy("smithy", "kitchen:pot")
	check(not r.ok and not "pot" in g.kitchen_tools, "the smithy sells no pots")

	# The cooking menu: a known recipe without its tools is not ready and says what is missing.
	g.flags[Cooking.flag("potato_stew")] = true
	g.inventory.add("potato", 2)
	g.inventory.add("onion", 1)
	var cm := CookingMenu.new(g)
	cm.cursor = cm.rows().map(func(row): return row.id).find("potato_stew")
	check(not cm.current().ready and cm.current().missing.is_empty() and cm.current().no_tools == (["pot"] as Array[String]),
		"the stew has its ingredients but no pot")
	check(cm.tools_text() == "Uses Kitchen knife, Clay pot (buy at store)", "the tools line (%s)" % cm.tools_text())
	check(CookingMenu.state_text(cm.current()) == "needs Clay pot", "the row says which tool is missing (%s)" % CookingMenu.state_text(cm.current()))
	var kept: Array = g.kitchen_tools.duplicate()
	g.kitchen_tools.clear()
	for id in Cooking.ids():
		g.flags[Cooking.flag(id)] = true
	for i in cm.rows().size():
		cm.cursor = i
		check(PixelFont.width(cm.tools_text()) <= 300 - 12, "%s's tools line fits the page (%s)" % [cm.current().id, cm.tools_text()])
	g.kitchen_tools.assign(kept)
	for id in Cooking.ids():
		if not id in ["potato_stew", "turnip_stew"] and not Cooking.recipe(id).get("start", false):
			g.flags.erase(Cooking.flag(id))
	cm.cursor = cm.rows().map(func(row): return row.id).find("potato_stew")
	check(cm.choose() == "You need a clay pot for that" and not cm.last_ok and g.count("potato") == 2, "Enter says what's missing")
	g.money = 900
	check(g.shop_buy("general", "kitchen:pot").ok and cm.current().ready and cm.tools_text() == "Uses Kitchen knife, Clay pot", "with the pot: ready")
	check(cm.choose() == "Made potato stew" and g.count("food:potato_stew") == 1, "potato stew cooked")
	cm.cursor = cm.rows().map(func(row): return row.id).find("onigiri")
	check(cm.tools_text() == "", "onigiri needs no tools")

	# The save keeps the tools; broken lists are refused; old saves get what they knew.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	check(saved.kitchen_tools == ["knife", "pot"], "the tools are saved (%s)" % [saved.kitchen_tools])
	g.new_game()
	check(g.kitchen_tools.is_empty(), "a new game has no kitchen tools")
	check(g.from_dict(saved) == "" and g.kitchen_tools == (["knife", "pot"] as Array[String]), "the tools load back")
	for broken in [{"x": 1}, ["wok"], ["knife", "knife"], [3]]:
		var b := saved.duplicate(true)
		b.kitchen_tools = broken
		check(g.from_dict(b) == "Saved kitchen tools are broken" and g.kitchen_tools == (["knife", "pot"] as Array[String]), "refused %s" % [broken])
	var old := saved.duplicate(true)
	old.erase("kitchen_tools")
	check(g.from_dict(old) == "" and g.kitchen_tools.is_empty(), "a version 5 save without the key has none")
	old.flags[Cooking.flag("ochazuke")] = true
	check(g.from_dict(old, 4) == "" and g.kitchen_tools == (["knife", "pot", "teapot"] as Array[String]),
		"a version 4 save's kitchen gets the tools of the recipes it knew (%s)" % [g.kitchen_tools])
	check(g.cook("ochazuke").note.begins_with("Not enough"), "so its ochazuke only waits for fish and tea")
	old.house.built = []
	check(g.from_dict(old, 4) == "" and g.kitchen_tools.is_empty(), "no kitchen in the old save: no tools")
	g.free()


## The stove and the cupboard in the real Game: E opens the cooking screen once the kitchen is
## built; the cooking screen in the 3D view opens and cooks.
func _process(_delta: float) -> bool:
	var g: Node = root.get_node("Game")
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	var opened := [0]
	g.cooking_requested.connect(func(): opened[0] += 1)
	g.maps.place("house", Vector2i(2, 5), Vector2i.LEFT)
	actions.interact(Vector2i(1, 5))
	check(opened[0] == 0, "no kitchen: the corner is bare (%s, %s)" % [g.house_built, g.maps.current().prop_at(Vector2i(1, 5))])
	g.house_built.append("kitchen")
	MapManager.set_built(g.house_built)
	g.maps.place("house", Vector2i(2, 5), Vector2i.LEFT)
	var cook_props: Array = g.maps.current().props.filter(func(p): return p.get("use", "") == "cook")
	check(cook_props.size() == 2, "the kitchen's stove and cupboard cook")
	check(MapManager.data("house").spawns.has("kitchen"), "a kitchen spawn by the stove")
	for p in cook_props:
		actions.interact(p.cell)
	check(opened[0] == 2, "E at the stove or the cupboard opens the cooking screen (%d)" % opened[0])
	var screen: CanvasLayer = load("res://scripts/ui/cooking_screen.gd").new()
	root.add_child(screen)
	g.open_cooking()
	check(screen.is_open() and g.paused(), "the screen opens and pauses the game")
	g.inventory.add("cucumber", 1)
	screen.menu.cursor = 0
	screen._cook()
	check(g.count("food:onigiri") >= 2 and screen._note.text == "Made onigiri x2", "cooking from the screen (%s)" % screen._note.text)
	screen.close()
	check(not screen.is_open() and not g.paused(), "closed again")
	g.house_built.erase("kitchen")
	MapManager.set_built(g.house_built)
	print("test_cooking: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)
	return true


func _game() -> Node:
	var g: Node = (load("res://scripts/autoload/game.gd") as GDScript).new()
	g.crops = _json("res://data/crops.json")
	g.tools_data = _json("res://data/tools.json")
	g.snow_rules = _json("res://data/snow_cover.json")
	g.body = _json("res://data/body.json")
	g.fish_data = _json("res://data/fish.json")
	g.set_food_data(_json("res://data/foods.json"))
	g.rng.seed = 4
	g.new_game()
	return g


func _empty_bag(g: Node) -> void:
	for i in g.inventory.size("bag"):
		g.inventory.slots.bag[i] = {}


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
