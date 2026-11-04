extends SceneTree
## Headless checks for food and drink (Game.eat + data/foods.json, raw farm goods, eating from
## the rucksack and overhead, the stand, the food slot). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_food.gd

var failures := 0


func _init() -> void:
	var data: Dictionary = _json("res://data/foods.json")
	var sounds: Dictionary = _json("res://data/sfx.json").sounds
	var foods: Dictionary = data.foods
	var g := _game()

	# The data: every food is complete, its sound exists, its icon is drawn.
	var on_sale := 0
	for id in foods:
		var f: Dictionary = foods[id]
		check(f.get("name", "") is String and f.name != "", "%s has a name" % id)
		check(int(f.get("stamina", -1)) >= 0 and float(f.get("fatigue", 1)) == int(f.get("fatigue", 1)), "%s: stamina >= 0, whole fatigue" % id)
		check(int(f.get("stamina", 0)) > 0 or int(f.get("fatigue", 0)) < 0 or f.has("max_stamina"), "%s does something" % id)
		if f.get("shop", false):
			on_sale += 1
			check(int(f.get("price", 0)) > 0, "%s on sale has a price" % id)
		check(sounds.has(g.eat_sound(id)), "%s plays a sound in data/sfx.json (%s)" % [id, g.eat_sound(id)])
		check(f.get("look", {}).get("shape", "") in ["rice_ball", "round", "skewer", "cup", "bottle", "bowl", "plate", "fish_plate", "bag", "imo"], "%s has a known icon shape" % id)
		var img := PlaceholderArt.tex("ui:food:" + id).get_image()
		check(img.get_size() == Vector2i(14, 14) and img.get_used_rect().has_area(), "ui:food:%s drawn" % id)
		check(PixelFont.width(String(f.name)) + 12 + PixelFont.width("x99") <= HudLayout.BOXES.item.size.x, "%s fits the item box" % id)
		if f.has("sell"):
			check(int(f.sell) > 0 and int(f.sell) < int(f.price) or int(f.price) == 0, "%s ships for less than the stand asks (%d)" % [id, int(f.sell)])
	check(on_sale >= 5, "the stand sells a few foods (%d)" % on_sale)
	check(g.eat_sound("green_tea") == "drink" and g.eat_sound("onigiri") == "eat", "drinks sound different")
	check(g.TOOLS.has("food") and g.count("food:onigiri") == 1, "food slot and an onigiri at the start")

	# Eating: stamina up to the max, fatigue down, one item used.
	var said: Array[String] = []
	g.message.connect(func(t: String): said.append(t))
	g.stamina = 50
	g.fatigue = 30
	check(g.eat("onigiri"), "eat an onigiri")
	check(g.stamina == 50 + int(foods.onigiri.stamina), "onigiri: stamina + %d" % int(foods.onigiri.stamina))
	check(g.fatigue == 30 + int(foods.onigiri.fatigue), "onigiri: fatigue %d" % int(foods.onigiri.fatigue))
	check(g.count("food:onigiri") == 0 and not g.bag.has("food:onigiri"), "the onigiri is gone from the bag")
	check(said.back() == "You ate the onigiri.", "eat message (%s)" % said.back())
	check(g.eating() and g.eat_pose == "eat" and g.eat_left == float(data.pose.eat), "eating starts the eat pose (%s, %.2f s)" % [g.eat_pose, g.eat_left])
	g.eat_left = 0.0
	g.eat_pose = ""
	check(not g.eat("onigiri") and not g.eating(), "nothing eaten: no pose")
	check(float(data.pose.eat) > 0.0 and float(data.pose.drink) > 0.0 and float(data.pose.eat) <= 3.0 and float(data.pose.drink) <= 3.0, "pose lengths are short")
	check(said.back().begins_with("No "), "none left: nothing eaten")
	g.add_item("food:amazake", 1)
	g.stamina = g.max_stamina - 3
	check(g.eat("amazake") and g.stamina == g.max_stamina, "stamina stops at the max")
	check(said.back() == "You drank the amazake.", "drink message (%s)" % said.back())
	check(g.eat_pose == "drink" and g.eat_left == float(data.pose.drink), "a drink starts the drink pose (%s, %.2f s)" % [g.eat_pose, g.eat_left])
	g.fatigue = 3
	g.add_item("food:green_tea", 1)
	check(g.eat("green_tea") and g.fatigue == 0, "fatigue stops at 0")

	# Full: stamina at the max and no fatigue to lose -> kept for later.
	g.add_item("food:dango", 1)
	g.stamina = g.max_stamina
	g.fatigue = 0
	check(not g.eat("dango") and g.count("food:dango") == 1, "full and rested: the dango is kept")
	check(said.back() == String(data.full_message), "full message")
	g.fatigue = 5
	check(g.eat("dango"), "full stamina but tired: still eats")
	check(not g.eat("pizza"), "unknown food: nothing")

	# Eating out of a tired state: the next tired state is told again.
	var body: Dictionary = g.body
	g.fatigue = int(body.states.tired.fatigue)
	g.check_body()
	check(g.body_state() == "tired", "tired before eating")
	g.add_item("food:green_tea", 2)
	g.eat("green_tea")
	check(g.body_state() == "fine", "tea: fine again")
	var n := said.size()
	g.fatigue = int(body.states.tired.fatigue)
	g.check_body()
	check(said.size() == n + 1 and said.back() == String(body.states.tired.message), "tired again is told again")

	# Special: max stamina grows, up to the cap.
	g.fatigue = 0
	g.stamina = 10
	var max_before: int = g.max_stamina
	g.add_item("food:kagami_mochi", 3)
	check(g.eat("kagami_mochi") and g.max_stamina == max_before + int(foods.kagami_mochi.max_stamina), "kagami mochi raises the max")
	check(said.back().ends_with("Max stamina +%d!" % int(foods.kagami_mochi.max_stamina)), "max stamina message (%s)" % said.back())
	g.max_stamina = int(data.max_stamina_cap) - 4
	g.eat("kagami_mochi")
	check(g.max_stamina == int(data.max_stamina_cap), "max stamina stops at the cap")
	g.stamina = g.max_stamina
	check(not g.eat("kagami_mochi"), "at the cap, full and rested: kept")
	g.max_stamina = max_before
	g.stamina = g.max_stamina

	# Special: half swing fatigue until the day ends.
	g.hour = 10
	g.weather_today = "rain"
	g.fatigue = 0
	g.stamina = 0
	g.spend_stamina(4)   # rain + 4 overwork
	var full_cost: int = g.fatigue
	check(full_cost == int(body.work.rain) + 4 * int(body.work.overwork_per_stamina), "rain overwork fatigue (%d)" % full_cost)
	g.fatigue = 10
	g.add_item("food:yomogi_tea", 2)
	check(g.eat("yomogi_tea") and g.work_fatigue_half, "mugwort tea: half fatigue today")
	check(said.back().ends_with(String(foods.yomogi_tea.special_message)), "half fatigue message")
	g.fatigue = 0
	g.stamina = 0
	g.spend_stamina(4)
	check(g.fatigue == full_cost / 2, "swing fatigue halved (%d -> %d)" % [full_cost, g.fatigue])
	g.end_day()
	check(not g.work_fatigue_half, "the half fatigue ends with the day")
	g.new_game()
	check(not g.work_fatigue_half and g.food_index == 0, "new game: no food effect, first food")

	# The food in hand cycles through the foods on sale and the ones carried (dishes, specials).
	var on_offer := foods.keys().filter(func(id): return foods[id].get("shop", false))
	var seen := {}
	for i in on_offer.size():
		seen[g.current_food()] = true
		g.cycle_food()
	check(seen.keys() == on_offer and g.food_index == 0, "Q cycles the stand's foods and back (%s)" % [seen.keys()])
	g.add_item("food:miso_soup", 1)
	seen = {}
	for i in foods.size():
		seen[g.current_food()] = true
		g.cycle_food()
	check(seen.has("miso_soup") and seen.size() == on_offer.size() + 1, "a dish in the rucksack joins the cycle")
	g.free()
	_raw(data)


## Raw farm goods: crops, eggs, milk, any fish and some wild things eat from foods.json "raw"; other things don't.
func _raw(data: Dictionary) -> void:
	var raw: Dictionary = data.raw
	var crops: Dictionary = _json("res://data/crops.json")
	var products: Dictionary = _json("res://data/animals.json").items
	for id in raw:
		check(crops.has(id) or products.has(id) or id == "fish:*" or not Forage.item(id).is_empty(), "raw %s is a real item" % id)
		check(int(raw[id].get("stamina", 0)) > 0 and int(raw[id].get("fatigue", 0)) <= 0, "raw %s gives a little" % id)
	for id in crops:
		check(raw.has(id), "every crop eats raw (%s)" % id)
	for id in crops:
		check(raw.has(id), "every crop can be eaten raw (%s)" % id)
	var g := _game()
	g.fish_data = _json("res://data/fish.json")
	var said: Array[String] = []
	g.message.connect(func(t: String): said.append(t))
	for i in g.inventory.size("bag"):
		g.inventory.slots.bag[i] = {}
	g.stamina = 50
	g.fatigue = 10
	g.add_item("turnip", 2)
	check(g.edible("turnip") and g.eat_item("turnip").ok, "a raw turnip is eaten")
	check(g.stamina == 50 + int(raw.turnip.stamina) and g.fatigue == 10 + int(raw.turnip.fatigue) and g.count("turnip") == 1,
		"turnip: +%d / %d, one gone" % [int(raw.turnip.stamina), int(raw.turnip.fatigue)])
	check(said.back() == "You ate the turnip.", "raw eat message (%s)" % said.back())
	g.add_item("milk", 1)
	check(g.item_sound("milk") == "drink" and g.eat_item("milk").ok and said.back() == "You drank the milk.", "fresh milk is drunk")
	g.add_item("fish:koi", 1)
	check(g.edible("fish:koi") and g.food_info("fish:koi").stamina == raw["fish:*"].stamina and g.food_info("fish:koi").name == "Carp", "any fish by fish:*")
	check(g.eat_item("fish:koi").ok and g.count("fish:koi") == 0, "the carp is eaten")
	for id in ["seeds:turnip", "wool", "mine:stone", "hoe", ""]:
		check(not g.edible(id), "%s can't be eaten" % id)
	g.add_item("wool", 1)
	check(not g.eat_item("wool").ok and g.count("wool") == 1, "wool stays in the rucksack")
	g.stamina = g.max_stamina
	g.fatigue = 0
	check(not g.eat_item("turnip").ok and g.count("turnip") == 1, "full and rested: the turnip is kept")
	g.fatigue = 10
	check(not g.eat_item("turnip", ["hand"]).ok and said.back() == "No turnip left.", "eating from the hand needs it in hand")
	g.held = "potato"
	check(g.eat_item("potato", ["hand"]).ok and g.held == "", "the potato overhead is eaten")

	# The rucksack screen's eat key (InventoryMenu.eat): the slot under the cursor.
	var m := InventoryMenu.new(g.inventory, "storage")
	g.inventory.add("egg", 1, ["chest"])
	m.point("chest", g.inventory.slots.chest.find_custom(func(sl): return sl.get("id", "") == "egg"))
	check(m.eat(g) == "Take it out of the chest first." and not m.last_ok and g.inventory.count("egg", ["chest"]) == 1, "not out of the chest")
	m.point("bag", g.inventory.slots.bag.find_custom(func(sl): return sl.get("id", "") == "turnip"))
	g.stamina = 10
	check(m.eat(g) == "You ate the turnip." and m.last_ok and g.count("turnip") == 0, "F eats the turnip under the cursor")
	m.point("bag", g.inventory.slots.bag.find_custom(func(sl): return sl.get("id", "") == "wool"))
	check(m.eat(g) == "You can't eat that." and not m.last_ok, "F on wool: nothing")
	m.choose()
	check(m.eat(g) == "Put it down first.", "not while carrying a stack")
	m.close()
	g.free()


## The stand and the food slot through FarmActions on the real Game autoload.
func _process(_delta: float) -> bool:
	var g: Node = root.get_node("Game")
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	var stand := Vector2i(-1, -1)
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			if stand.x < 0 and g.farm.fixed_at(Vector2i(x, y)) == "stand":
				stand = Vector2i(x, y)
	check(stand.x >= 0, "the farm has a stand")
	g.select_tool(g.TOOLS.find("food"))
	g.food_index = g.foods.keys().find("milk")
	g.money = 1000
	var had: int = g.count("food:milk")
	var seeds_before: Dictionary = g.bag.duplicate()
	actions.interact(stand)
	check(g.count("food:milk") == had + 1 and g.money == 1000 - int(g.foods.milk.price), "the stand sells the food in hand")
	g.food_index = g.foods.keys().find("kagami_mochi")
	actions.interact(stand)
	check(g.count("food:kagami_mochi") == 0 and g.money == 1000 - int(g.foods.milk.price), "not for sale: nothing bought")
	g.food_index = g.foods.keys().find("milk")
	g.money = 1
	actions.interact(stand)
	check(g.count("food:milk") == had + 1 and g.money == 1, "too little money: nothing bought")
	seeds_before["food:milk"] = had + 1
	check(g.bag == seeds_before, "buying food leaves the seeds alone")
	g.stamina = 20
	actions.use_tool(Vector2i(8, 8), Vector2i.DOWN, 0)
	check(g.count("food:milk") == had and g.stamina == 20 + int(g.foods.milk.stamina), "use with the food slot drinks the milk")
	_pose(g)
	# The food slot works on any map; with an edible item overhead the tool button eats it.
	g.maps.place("house", Vector2i(4, 5), Vector2i.UP)
	g.stamina = 20
	g.add_item("food:onigiri", 1)
	g.food_index = g.foods.keys().find("onigiri")
	var rice: int = g.count("food:onigiri")
	actions.use_tool(Vector2i(4, 5), Vector2i.UP, 0)
	check(g.count("food:onigiri") == rice - 1, "eating indoors")
	g.held = "tomato"
	g.stamina = 20
	actions.on_action("use_tool", Vector2i(4, 5), Vector2i.UP, 0)
	check(g.held == "" and g.stamina == 20 + int(g.food_data.raw.tomato.stamina), "the tomato overhead is eaten")
	g.held = "wool"
	actions.on_action("use_tool", Vector2i(4, 5), Vector2i.UP, 0)
	check(g.held == "wool", "wool overhead isn't eaten")
	g.held = ""
	g.maps.place("farm", Vector2i(4, 4), Vector2i.DOWN)
	g.select_tool(g.TOOLS.find("seeds"))
	print("test_food: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)
	return true


## The eat / drink pose on the real Game: it lasts foods.json pose seconds, stands still while
## a menu is open, the Player neither moves nor acts during it, then the farmer is idle again;
## FarmerAnim and the placeholder frames in both views.
func _pose(g: Node) -> void:
	var pose: Dictionary = g.food_data.pose
	check(g.eat_pose == "drink" and is_equal_approx(g.eat_left, float(pose.drink)), "the milk starts the drink pose")
	var player: Node2D = (load("res://scripts/player/player.gd") as GDScript).new()
	player.farm = g.farm
	player.position = Vector2(8 * 16 + 8, 8 * 16 + 8)
	root.add_child(player)
	var acted: Array = []
	player.action.connect(func(kind, _o, _f, _c): acted.append(kind))
	var at: Vector2 = player.position
	Input.action_press("use_tool")
	Input.action_press("interact")
	Input.action_press("move_right")
	player._physics_process(0.1)
	check(acted.is_empty() and not player.moving and player.position == at, "no tool, no interact, no step while drinking %s" % [acted])
	Input.action_release("use_tool")
	Input.action_release("interact")
	Input.action_release("move_right")
	g.dialogue_open = true
	g._process(5.0)
	check(g.eating() and is_equal_approx(g.eat_left, float(pose.drink)), "a text box open: the pose waits")
	g.dialogue_open = false
	g._process(float(pose.drink) / 2.0)
	check(g.eating() and is_equal_approx(g.eat_left, float(pose.drink) / 2.0), "half way through the sip")
	g._process(float(pose.drink) / 2.0 + 0.01)
	check(not g.eating() and g.eat_pose == "" and g.eat_left == 0.0, "the drink pose ends after %.2f s" % float(pose.drink))
	Input.action_press("use_tool")
	Input.action_press("move_right")
	player._physics_process(0.1)
	# Same frame as the presses above, so those still count as just pressed: look for the tool.
	check(acted.has("tool") and player.moving, "after the pose the tool button and walking work again %s" % [acted])
	Input.action_release("use_tool")
	Input.action_release("move_right")
	player.queue_free()
	g.start_eat_pose(false)
	check(g.eat_pose == "eat" and is_equal_approx(g.eat_left, float(pose.eat)), "start_eat_pose(false): eat for %.2f s" % float(pose.eat))
	g._process(float(pose.eat) + 0.01)
	check(not g.eating(), "the eat pose ends")

	# FarmerAnim: eat / drink win over the tired poses (not over holding), the frames run at their rates.
	var anim := FarmerAnim.new()
	anim.step(0.0, false, false, true, false, "", "eat")
	check(anim.key(Vector2i.DOWN) == "player:front:eat:0", "eat starts on the bite (%s)" % anim.key(Vector2i.DOWN))
	anim.step(1.0 / FarmerAnim.EAT_FPS + 0.01, false, false, true, false, "", "eat")
	check(anim.key(Vector2i.UP) == "player:back:eat:1", "then the chew (%s)" % anim.key(Vector2i.UP))
	anim.step(0.0, false, false, false, false, "", "drink")
	check(anim.key(Vector2i.LEFT) == "player:back:drink:0", "drink starts at the lips (%s)" % anim.key(Vector2i.LEFT))
	anim.step(0.0, false, false, false, true, "", "drink")
	check(anim.pose == "hold_idle", "hands full overhead: the hold pose stays")
	anim.step(0.0, false, false, true, false, "", "")
	check(anim.pose == "tired_idle", "after the pose: idle again (tired here)")
	var idle := PlaceholderArt.tex("player:front:idle:0").get_image()
	for pose_name in ["eat", "drink"]:
		var frames: Array = []
		for f in PlaceholderArt.farmer_frames(pose_name):
			for side in ["front", "back"]:
				var img := PlaceholderArt.tex("player:%s:%s:%d" % [side, pose_name, f]).get_image()
				check(img.get_size() == Vector2i(16, 24) and img.get_used_rect().has_area(), "player:%s:%s:%d drawn" % [side, pose_name, f])
			frames.append(PlaceholderArt.tex("player:front:%s:%d" % [pose_name, f]).get_image().get_data())
		check(PlaceholderArt.farmer_frames(pose_name) == 2 and frames[0] != frames[1], "%s has two different frames" % pose_name)
		check(frames[0] != idle.get_data(), "%s doesn't look like standing idle" % pose_name)


func _game() -> Node:
	var g: Node = (load("res://scripts/autoload/game.gd") as GDScript).new()
	g.crops = _json("res://data/crops.json")
	g.tools_data = _json("res://data/tools.json")
	g.snow_rules = _json("res://data/snow_cover.json")
	g.body = _json("res://data/body.json")
	g.set_food_data(_json("res://data/foods.json"))
	g.rng.seed = 4
	g.new_game()
	return g


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
