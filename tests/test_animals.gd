extends SceneTree
## Headless checks for the animals (Animals rules, data/animals.json, the coop and barn maps
## and their actions, eggs / milk / wool as held items, the dog, the save, the art). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_animals.gd

var failures := 0
var _frame := 0


func _init() -> void:
	_rules()
	_day()
	_sickness_and_growing()
	_save()
	_game()
	_map_and_art()
	_barn_rules()
	_animal_art()
	_barn_day()
	_dog()
	_barn_save()
	_barn_map_and_art()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_coop_actions()
		_barn_actions()
		print("test_animals: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


func _rules() -> void:
	var d := Animals.data()
	check(d.kinds.has("chicken") and int(d.homes.coop.capacity) >= 2, "animal data read")
	var a := Animals.new()
	a.start()
	check(a.list.size() == d.start.size() and a.list.size() >= 1 and a.list.size() <= 2, "a new game starts with 1-2 chickens")
	check(a.feed_stock == int(d.homes.coop.feed_start) and a.feed_box == 0 and a.eggs.is_empty(), "full feed sack, empty box and nests")
	check(a.list[0].name != a.list[-1].name or a.list.size() == 1, "each hen has her own name")
	check(a.is_adult(a.list[0]) and a.list[0].happy == int(d.kinds.chicken.happy_start), "starting hens are grown, at the start happiness")
	var cap := int(d.homes.coop.capacity)
	while a.list.size() < cap:
		check(a.add("chicken"), "room for hen %d" % (a.list.size() + 1))
	check(not a.add("chicken") and a.room() == 0, "the coop is full at %d" % cap)
	check(not Animals.new().add("dragon"), "an unknown kind isn't added")
	# Grades by happiness.
	check(a.grade_for("egg", 0) == "egg" and a.grade_for("egg", 39) == "egg", "unhappy hens lay plain eggs")
	check(a.grade_for("egg", 40) == "egg_good" and a.grade_for("egg", 74) == "egg_good", "content hens lay good eggs")
	check(a.grade_for("egg", 75) == "egg_best" and a.grade_for("egg", 100) == "egg_best", "happy hens lay the best eggs")
	check(a.sell_price("egg") < a.sell_price("egg_good") and a.sell_price("egg_good") < a.sell_price("egg_best"), "better eggs fetch more")
	# The feed box takes one portion a hen from the sack.
	a = _flock(2)
	a.feed_stock = 3
	check(a.fill_feed_box() == 2 and a.feed_box == 2 and a.feed_stock == 1, "feed box filled for two hens")
	check(a.fill_feed_box() == 0, "a full box takes no more")
	a.feed_box = 0
	check(a.fill_feed_box() == 1 and a.fill_feed_box() == 0 and a.feed_stock == 0, "an empty sack gives what it has")


func _day() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var h: Dictionary = Animals.data().happiness
	# Fed from the box: happier and an egg in the nest by morning.
	var a := _flock(2)
	a.fill_feed_box()
	var start: int = a.list[0].happy
	a.day_end("sunny", rng)
	check(a.list[0].happy == start + int(h.fed) and a.feed_box == 0, "fed hens are happier %d" % a.list[0].happy)
	check(Array(a.eggs) == ["egg", "egg"], "fed hens lay %s" % [a.eggs])
	# Unfed: unhappy and no egg.
	a.eggs.clear()
	a.day_end("sunny", rng)
	check(a.list[0].happy == start + int(h.fed) + int(h.unfed) and a.eggs.is_empty(), "unfed hens lose happiness and lay nothing")
	# Petting counts once a day.
	a = _flock(1)
	check(a.pet(0) and not a.pet(0), "pet once a day")
	a.fill_feed_box()
	a.day_end("sunny", rng)
	check(a.list[0].happy == 30 + int(h.fed) + int(h.petted) and not a.list[0].petted, "petting adds happiness, reset at night")
	# Outside: only in good weather and by day; grazing long enough is a meal and some sun.
	a = _flock(1)
	check(a.toggle_out("rain", 10) == "weather" and not a.outside, "not out in the rain")
	check(a.toggle_out("sunny", 20) == "time" and not a.outside, "not out at night")
	check(Animals.new().why_not_out("sunny", 10) == "none", "no hens, nothing to let out")
	check(a.toggle_out("sunny", 9) == "" and a.outside and a.out_list().size() == 1, "out on a sunny morning")
	for i in int(h.grazing_hours):
		a.hour_passed("sunny")
	check(a.list[0].out_hours == int(h.grazing_hours), "outside hours counted")
	check(a.toggle_out("sunny", 15) == "" and not a.outside, "called back in")
	a.feed_box = 1
	a.day_end("sunny", rng)
	check(a.list[0].happy == 30 + int(h.fed) + int(h.sun) and a.feed_box == 1, "grazed: fed without feed, plus sun %d" % a.list[0].happy)
	check(a.eggs.size() == 1, "a grazed hen lays")
	# Left out in bad weather and overnight.
	a = _flock(1)
	a.toggle_out("sunny", 9)
	a.hour_passed("rain")
	check(a.list[0].happy == 30 + int(h.bad_weather_hour) and a.list[0].out_hours == 0, "rain while out hurts")
	var news := a.day_end("rain", rng)
	check(not a.outside and a.list[0].happy == 30 + int(h.bad_weather_hour) + int(h.unfed) + int(h.left_out_night),
		"left out overnight: unhappy, back inside %d" % a.list[0].happy)
	check("The hens were out all night." in news, "news of the night out %s" % [news])
	# Nests hold at most the coop's capacity of eggs.
	a = _flock(2)
	var cap := int(a.home_rule("coop").capacity)
	for i in cap:
		a.eggs.append("egg")
	a.fill_feed_box()
	a.day_end("sunny", rng)
	check(a.eggs.size() == cap, "full nests: no more eggs")
	check(a.take_egg() == "egg" and a.eggs.size() == cap - 1, "eggs are taken one at a time")
	a.eggs.clear()
	check(a.take_egg() == "", "no egg to take")
	# Happiness stays in range.
	a = _flock(1)
	a.list[0].happy = 99
	a.fill_feed_box()
	a.pet(0)
	a.day_end("sunny", rng)
	check(a.list[0].happy == a.happy_max() and Array(a.eggs) == ["egg_best"], "happiness stops at the max; best egg")


func _sickness_and_growing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var r: Dictionary = Animals.data().duplicate(true)
	r.sickness.chance = 1.0
	var a := Animals.new(r)
	a.feed_stock = 99
	a.add("chicken")
	a.list[0].happy = int(r.sickness.below)
	var news := a.day_end("sunny", rng)
	check(a.list[0].sick and ("%s looks sick." % a.list[0].name) in news, "an unhappy hen falls sick %s" % [news])
	a.fill_feed_box()
	a.day_end("sunny", rng)
	check(a.eggs.is_empty(), "a sick hen doesn't lay")
	check(a.cure(0) and not a.list[0].sick and not a.cure(0), "medicine cures at once")
	# Without medicine she gets well by herself.
	a.list[0].sick = true
	a.list[0].sick_days = 0
	a.list[0].happy = 50
	for i in int(r.sickness.recover_days) - 1:
		a.fill_feed_box()
		a.day_end("sunny", rng)
	check(a.list[0].sick, "still sick before the recovery days")
	a.fill_feed_box()
	news = a.day_end("sunny", rng)
	check(not a.list[0].sick and ("%s is well again." % a.list[0].name) in news, "well again after %d nights" % int(r.sickness.recover_days))
	# A content, fed hen never falls sick, even with chance 1.
	a.fill_feed_box()
	a.day_end("sunny", rng)
	check(not a.list[0].sick, "a happy fed hen stays well")

	# Chicks grow up; only adults lay.
	a = Animals.new()
	a.feed_stock = 99
	check(a.add("chicken", true) and not a.is_adult(a.list[0]) and "(chick)" in a.label(a.list[0]), "a young chick")
	var grow := int(Animals.data().kinds.chicken.adult_days)
	for i in grow - 1:
		a.fill_feed_box()
		news = a.day_end("sunny", rng)
	check(a.eggs.is_empty() and not a.is_adult(a.list[0]), "chicks don't lay")
	a.fill_feed_box()
	news = a.day_end("sunny", rng)
	check(a.is_adult(a.list[0]) and ("%s has grown up." % a.list[0].name) in news, "grown up after %d nights" % grow)
	# The incubator hatches an egg into a chick.
	a = _flock(1)
	check(not a.incubate("turnip"), "only eggs go in the incubator")
	var room := a.room()
	check(a.incubate("egg_good") and a.room() == room - 1 and not a.incubate("egg"), "egg in the incubator takes a place")
	var hatch := int(Animals.data().incubator.hatch_days)
	for i in hatch - 1:
		a.day_end("sunny", rng)
	check(a.list.size() == 1 and a.incubator.days == hatch - 1, "still warming")
	news = a.day_end("sunny", rng)
	check(a.list.size() == 2 and not a.is_adult(a.list[1]) and a.incubator.is_empty(), "a chick hatched")
	check(news.any(func(n): return n.begins_with("A chick hatched")), "news of the chick %s" % [news])
	a = _flock(int(Animals.data().homes.coop.capacity))
	check(not a.incubate("egg"), "no incubating in a full coop")


func _save() -> void:
	var a := _flock(2)
	a.list[1].sick = true
	a.list[1].sick_days = 2
	a.eggs.assign(["egg", "egg_best"])
	a.incubate("egg_good")
	a.fill_feed_box()
	a.toggle_out("sunny", 10)
	a.hour_passed("sunny")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(a.to_dict()))   # numbers come back as floats
	var r := Animals.parse(saved)
	check(r[0] == "" and r[1].to_dict() == a.to_dict(), "animals round trip %s" % r[0])
	var bad := {
		"unknown kind": func(d): d.animals[0].kind = "dragon",
		"happiness over max": func(d): d.animals[0].happy = 999,
		"no name": func(d): d.animals[0].erase("name"),
		"bad egg": func(d): d.eggs.append("turnip"),
		"bad incubator": func(d): d.incubator = {"item": "egg", "days": -1},
		"feed as text": func(d): d.feed_stock = "lots",
		"not a list": func(d): d.animals = {},
		"too many": func(d): for i in 6: d.animals.append(d.animals[0].duplicate()),
	}
	for key in bad:
		var d: Dictionary = saved.duplicate(true)
		bad[key].call(d)
		check(Animals.parse(d)[0] != "", "broken save refused: " + key)


func _game() -> void:
	var g: Node = (load("res://scripts/autoload/game.gd") as GDScript).new()
	g.crops = _json("res://data/crops.json")
	g.tools_data = _json("res://data/tools.json")
	g.snow_rules = _json("res://data/snow_cover.json")
	g.body = _json("res://data/body.json")
	g.hold_rules = _json("res://data/hold.json")
	g.rng.seed = 5
	g.new_game()
	check(g.animals.list.size() == Animals.data().start.size(), "new game has the starting flock")
	check(g.farm.fixed_at(FarmGrid.COOP_DOOR) == "coop_door" and g.farm.fixed_at(Vector2i(13, 1)) == "coop", "the coop stands on the farm")
	check(g.add_animal("chicken") and g.animals.list.size() == Animals.data().start.size() + 1, "the shop hook adds a hen")
	check(g.sell_price("egg") == int(Animals.data().items.egg.sell) and g.item_name("egg_best") == "Golden yolk egg", "eggs have a price and a name")
	# The clock: an hour outside counts; the night lays eggs.
	g.animals.toggle_out("sunny", 10)
	g.weather_today = "sunny"
	g.minute = 59
	g._tick_minute()
	check(g.animals.list[0].out_hours == 1, "the clock's hour reaches the hens")
	g.animals.toggle_out("sunny", 10)
	g.animals.fill_feed_box()
	g.end_day()
	check(g.animals.eggs.size() == g.animals.list.size(), "a night lays the eggs")
	# The night may have grown a weed (WEED_CHANCE) on the cell between the farmer and the bin,
	# which would stop a throw; these checks are about shipping, so that cell is clear.
	g.farm.cell(Vector2i(8, 4)).obj = FarmGrid.Obj.NONE
	# An egg overhead ships when thrown into the bin.
	g.held = "egg_good"
	var t: Dictionary = g.throw_held(Vector2i(8, 5), Vector2i.UP)
	check(t.result == "ship" and t.value == g.sell_price("egg_good") and g.shipped.get("egg_good") == 1, "egg thrown into the bin is shipped %s" % t)
	g.inventory.add("egg", 2)
	var before: int = g.bin_total
	g.ship_produce()
	check(g.bin_total == before + 2 * g.sell_price("egg"), "eggs in the rucksack ship at the bin too")
	# The barn, cows and sheep through Game.
	check(g.farm.fixed_at(FarmGrid.BARN_DOOR) == "barn_door" and g.farm.fixed_at(FarmGrid.BARN.position) == "barn", "the barn stands on the farm")
	check(g.add_animal("sheep", true) and not g.animals.is_adult(g.animals.list.back()), "the shop hook adds a lamb")
	check(g.sell_price("milk_best") == int(Animals.data().items.milk_best.sell) and g.item_name("wool_good") == "Soft wool", "milk and wool have a price and a name")
	g.held = "milk_good"
	t = g.throw_held(Vector2i(8, 5), Vector2i.UP)
	check(t.result == "ship" and t.value == g.sell_price("milk_good"), "milk thrown into the bin is shipped")
	# Save: version 4 (and later) keeps the animals, barn and dog; a version 1 save gets the starting flock and the coop.
	check(SaveGame.VERSION >= 4, "save version 4 or later")
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	var flock: int = g.animals.list.size()
	var laid: int = g.animals.eggs.size()
	g.new_game()
	check(g.from_dict(d) == "" and g.animals.list.size() == flock and g.animals.eggs.size() == laid and laid > 0, "animals load from a save")
	var old: Dictionary = d.duplicate(true)
	old.erase("animals")
	check(g.from_dict(old, 2) != "", "a version 2 save must have animals")
	var old2: Dictionary = d.duplicate(true)
	old2.animals.erase("barn")
	old2.animals.erase("dog")
	check(g.from_dict(old2, 4) != "", "a version 4 save must have the barn and the dog")
	check(g.from_dict(old2, 3) == "" and g.animals.list.size() == flock and g.animals.state.barn.stock == int(Animals.data().homes.barn.feed_start), "a version 3 save loads with the new-game fodder")
	for s in old.farm.fixed.duplicate():
		if s[2] in ["coop", "coop_door"]:
			old.farm.fixed.erase(s)
	check(g.from_dict(old, 1) == "" and g.animals.list.size() == Animals.data().start.size(), "a version 1 save gets the starting flock")
	check(g.farm.fixed_at(FarmGrid.COOP_DOOR) == "coop_door", "and the coop on its farm")
	g.free()


## The coop actions with the real Game autoload (feed box, nests, incubator, hatch, hens).
## (Loaded here, not named: those scripts need the Game autoload, which a --script test
## only has once the tree runs.)
func _coop_actions() -> void:
	var g: Node = root.get_node("Game")
	var CoopActions: GDScript = load("res://scripts/animals/coop_actions.gd")
	var FarmActions: GDScript = load("res://scripts/farm_actions.gd")
	g.new_game()
	g.events_seen = {"first_morning": true, "rainy_day": true}
	var spot: Array = MapManager.data("coop").spawns.start
	check(g.go_to_map("coop", spot[0], spot[1]) and CoopActions.in_coop() and g.indoors(), "into the coop (clock stops)")
	var a: Animals = g.animals
	var box := _prop_cell("feed_box")
	FarmActions.interact(box)
	check(a.feed_box == a.list.size(), "the feed box filled from the sack")
	FarmActions.interact(_prop_cell("feed_sack"))
	a.eggs.assign(["egg_good"])
	FarmActions.interact(_prop_cell("nest"))
	check(g.held == "egg_good" and a.eggs.is_empty(), "an egg from the nest goes overhead")
	FarmActions.on_action("interact", _prop_cell("incubator") + Vector2i.DOWN, Vector2i.UP)
	check(not g.holding() and a.incubator.get("item") == "egg_good", "held egg into the incubator")
	g.weather_today = "sunny"
	g.hour = 10
	var hatch := _prop_cell("hatch")
	FarmActions.interact(hatch)
	check(a.outside and CoopActions.animal_at(CoopActions.spot(0)) == -1, "the hatch lets the hens out")
	FarmActions.interact(hatch)
	check(not a.outside, "and calls them back")
	check(CoopActions.animal_at(CoopActions.spot(0)) == 0 and CoopActions.animal_at(Vector2i(6, 5)) == -1, "hens stand on their spots")
	FarmActions.interact(CoopActions.spot(0))
	check(a.list[0].petted, "talking to a hen pets her")
	a.list[0].sick = true
	FarmActions.interact(CoopActions.spot(0))
	check(a.list[0].sick, "no medicine: still sick")
	g.add_item("medicine")
	FarmActions.interact(CoopActions.spot(0))
	check(not a.list[0].sick and g.count("medicine") == 0, "medicine from the rucksack cures her")
	g.new_game()


func _map_and_art() -> void:
	var r := MapManager.load_map("coop")
	check(r[0] == "", "coop map loads (%s)" % r[0])
	var m: MapData = r[1]
	check(m.indoor, "the coop is a building (clock stops)")
	var uses := []
	for p in m.props:
		uses.append(p.get("use", ""))
	for want in ["feed_box", "nest", "incubator", "feed_sack", "hatch"]:
		check(want in uses, "coop has a %s" % want)
	var spots: Array = Animals.data().homes.coop.spots
	check(spots.size() >= int(Animals.data().homes.coop.capacity), "a spot for every place")
	for s in spots:
		var c := Vector2i(int(s[0]), int(s[1]))
		check(not m.is_solid(c) and m.prop_at(c).is_empty() and m.door_at(c).is_empty(), "spot %s is free floor" % c)
	var farm_door: Dictionary = MapManager.data("farm").door_at(FarmGrid.COOP_DOOR)
	check(farm_door.get("to") == "coop", "the farm's coop door leads in")
	check(m.doors[0].to == "farm" and m.doors[0].spawn == FarmGrid.COOP_DOOR + Vector2i.DOWN, "the coop door leads back out in front of it")
	# Older farms get the coop, on cleared ground.
	var crops := _json("res://data/crops.json")
	var f := FarmGrid.new(crops)
	f.generate(RandomNumberGenerator.new())
	for c in f.fixed.keys():
		if f.fixed[c] in ["coop", "coop_door"]:
			f.fixed.erase(c)
	f.till(Vector2i(14, 2))
	f.place_item(Vector2i(16, 1), "turnip")
	f.add_missing_fixed()
	check(f.fixed_at(Vector2i(14, 2)) == "coop" and not f.cell(Vector2i(14, 2)).tilled and f.item_at(Vector2i(16, 1)) == "", "coop added to an older farm")
	# Art.
	for key in ["animal:chicken:idle:0", "animal:chicken:idle:1", "animal:chicken:peck:1", "animal:chicken:walk:1", "animal:chicken:sick:0"]:
		check(PlaceholderArt.tex(key).get_size() == Vector2(30, 28), key + " is 30 x 28")
	check(PlaceholderArt.tex("animal:chick:walk:1").get_size() == Vector2(18, 16), "chick is 18 x 16")
	check(PlaceholderArt.tex("animal:chicken:idle:0").get_image().get_data() != PlaceholderArt.tex("animal:chicken:sick:0").get_image().get_data(), "a sick hen looks different")
	for egg in ["egg", "egg_good", "egg_best"]:
		check(PlaceholderArt.world_item_key(egg) == "item:" + egg and PlaceholderArt.tex("item:" + egg).get_size() == Vector2(12, 12), egg + " world sprite")
		check(PlaceholderArt.tex(PlaceholderArt.item_key(egg)).get_size() == Vector2(14, 14), egg + " slot icon")
	check(PlaceholderArt.world_item_key("eggplant") == "item:eggplant", "eggplant is still a crop")
	check(PlaceholderArt.tex("ground:straw:0").get_size() == Vector2(16, 16) and PlaceholderArt.tex("build:thatch").get_size() == Vector2(16, 16), "straw floor and thatch")


# --- the barn, cows and sheep, the dog ----------------------------------------

func _barn_rules() -> void:
	var d := Animals.data()
	check(d.kinds.cow.home == "barn" and d.kinds.sheep.home == "barn" and int(d.homes.barn.capacity) >= 2, "cows and sheep live in the barn")
	var a := Animals.new()
	a.start()
	check(a.in_home("barn").is_empty() and a.state.barn.stock == int(d.homes.barn.feed_start) and a.state.barn.box == 0, "a new game: empty barn, fodder in stock")
	var hens := a.in_home("coop").size()
	var coop_room := a.room("coop")
	check(a.add("cow") and a.add("sheep") and a.room("barn") == int(d.homes.barn.capacity) - 2, "a cow and a sheep in the barn")
	check(a.room("coop") == coop_room and a.in_home("coop").size() == hens, "the coop's places are its own")
	# Spots count within each home.
	var cow := a.list.size() - 2
	check(a.spot(cow) == Vector2i(int(d.homes.barn.spots[0][0]), int(d.homes.barn.spots[0][1])), "the first barn animal stands in the first stall")
	check(a.spot(1) == Vector2i(int(d.homes.coop.spots[1][0]), int(d.homes.coop.spots[1][1])), "hens keep their coop spots")
	check(a.animal_at("barn", a.spot(cow)) == cow and a.animal_at("coop", a.spot(cow)) != cow, "animal_at asks one home")
	check(a.home_on_map("barn") == "barn" and a.home_on_map("coop") == "coop" and a.home_on_map("farm") == "", "homes by map")
	# Fodder: one portion per barn animal; the coop's box stays as it was.
	var stock: int = a.state.barn.stock
	check(a.fill_feed_box("barn") == 2 and a.state.barn.box == 2 and a.state.barn.stock == stock - 2 and a.feed_box == 0, "fodder box filled for two")
	a.add_fodder(5)
	check(a.state.barn.stock == stock + 3, "the shop's fodder hook")
	while a.room("barn") > 0:
		a.add("sheep")
	check(not a.add("cow") and a.add("chicken") == (coop_room > 0), "a full barn takes no more, the coop still does")
	check(a.grade_for("milk", 10) == "milk" and a.grade_for("milk", 50) == "milk_good" and a.grade_for("milk", 90) == "milk_best", "milk grades")
	check(a.grade_for("wool", 10) == "wool" and a.grade_for("wool", 90) == "wool_best", "wool grades")
	check(a.sell_price("milk") < a.sell_price("milk_good") and a.sell_price("milk_good") < a.sell_price("milk_best"), "better milk fetches more")
	check(a.sell_price("wool") < a.sell_price("wool_good") and a.sell_price("wool_good") < a.sell_price("wool_best"), "better wool fetches more")


func _barn_day() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var h: Dictionary = Animals.data().happiness
	# Milking: ready after one fed night, doesn't pile up, graded by happiness.
	var a := _herd(["cow"])
	check(not a.product_ready(a.list[0]) and a.take_product(0) == "", "a new cow has no milk yet")
	a.fill_feed_box("barn")
	a.day_end("sunny", rng)
	check(a.product_ready(a.list[0]) and a.state.barn.box == 0, "a fed night gives milk")
	a.fill_feed_box("barn")
	a.day_end("sunny", rng)
	check(int(a.list[0].prod_days) == 1, "unmilked milk doesn't pile up")
	check(a.take_product(0) == "milk" and not a.product_ready(a.list[0]) and a.take_product(0) == "", "milked once: plain milk at %d" % a.list[0].happy)
	a.day_end("sunny", rng)
	check(not a.product_ready(a.list[0]), "an unfed night gives no milk")
	a.list[0].happy = 90
	a.fill_feed_box("barn")
	a.day_end("sunny", rng)
	check(a.take_product(0) == "milk_best", "a happy cow gives the best milk")
	# Shearing: wool grows back over `every` fed nights; the sheep looks shorn until then.
	a = _herd(["sheep"])
	var every := int(Animals.data().kinds.sheep.gives.every)
	check(every > 1 and a.look(a.list[0]) == "sheep_shorn", "a sheep starts shorn, wool every %d nights" % every)
	for i in every - 1:
		a.fill_feed_box("barn")
		a.day_end("sunny", rng)
	check(not a.product_ready(a.list[0]), "wool not grown yet")
	a.fill_feed_box("barn")
	a.day_end("sunny", rng)
	check(a.product_ready(a.list[0]) and a.look(a.list[0]) == "sheep", "full wool after %d nights" % every)
	check(a.take_product(0).begins_with("wool") and a.look(a.list[0]) == "sheep_shorn", "sheared")
	# Brushing: once a day, happiness at night; hens can't be brushed.
	a = _herd(["cow"])
	a.add("chicken")
	check(a.brush(0) and not a.brush(0) and not a.brush(1), "brush once a day, not the hens")
	a.fill_feed_box("barn")
	a.day_end("sunny", rng)
	check(a.list[0].happy == 30 + int(h.fed) + int(h.brushed) and not a.list[0].brushed, "brushing adds happiness, reset at night")
	a.pet(0)
	a.brush(0)
	a.fill_feed_box("barn")
	a.day_end("sunny", rng)
	check(a.list[0].happy == 30 + 2 * int(h.fed) + 2 * int(h.brushed) + int(h.petted), "talking and brushing add up")
	# Going out: the barn gate is its own door; grazing feeds them.
	a = _herd(["cow", "sheep"])
	a.add("chicken")
	check(a.toggle_out("rain", 10, "barn") == "weather" and a.toggle_out("sunny", 20, "barn") == "time", "not out in rain or at night")
	check(a.toggle_out("sunny", 10, "barn") == "" and a.is_out("barn") and not a.outside, "the barn animals go out, the hens stay in")
	check(a.out_list("barn").size() == 2 and a.out_list("coop").is_empty() and a.animal_at("barn", a.spot(0)) == -1, "out on the farm")
	for i in int(h.grazing_hours):
		a.hour_passed("sunny")
	check(a.list[0].out_hours == int(h.grazing_hours) and a.list[2].out_hours == 0, "grazing hours only for those out")
	a.toggle_out("sunny", 15, "barn")
	a.day_end("sunny", rng)
	check(a.list[0].happy == 30 + int(h.fed) + int(h.sun) and a.product_ready(a.list[0]), "grazing is a meal: milk by morning")
	check(a.list[2].happy == 30 + int(h.unfed), "the unfed hen")
	a.toggle_out("sunny", 10, "barn")
	var news := a.day_end("sunny", rng)
	check(not a.is_out("barn") and String(Animals.data().homes.barn.out_news) in news, "left out: news, back in %s" % [news])
	# Sickness: no milk while sick, medicine or time cures.
	var r: Dictionary = Animals.data().duplicate(true)
	r.sickness.chance = 1.0
	a = Animals.new(r)
	a.add_fodder(99)
	a.add("cow")
	a.list[0].happy = 0
	news = a.day_end("sunny", rng)
	check(a.list[0].sick and ("%s looks sick." % a.list[0].name) in news, "an unhappy cow falls sick")
	a.fill_feed_box("barn")
	a.day_end("sunny", rng)
	check(not a.product_ready(a.list[0]) and a.take_product(0) == "", "a sick cow gives no milk")
	check(a.cure(0) and not a.list[0].sick, "medicine cures her")
	# A calf grows into a cow and only then gives milk.
	a = Animals.new()
	a.add_fodder(99)
	check(a.add("cow", true) and a.look(a.list[0]) == "calf" and "(calf)" in a.label(a.list[0]), "a young calf")
	var grow := int(Animals.data().kinds.cow.adult_days)
	for i in grow - 1:
		a.fill_feed_box("barn")
		a.day_end("sunny", rng)
	check(not a.is_adult(a.list[0]) and not a.product_ready(a.list[0]), "calves give no milk")
	a.fill_feed_box("barn")
	news = a.day_end("sunny", rng)
	check(a.is_adult(a.list[0]) and a.look(a.list[0]) == "cow" and ("%s has grown up." % a.list[0].name) in news, "grown up after %d nights" % grow)
	a.fill_feed_box("barn")
	a.day_end("sunny", rng)
	check(a.product_ready(a.list[0]), "and gives milk")
	check(Animals.new().add("sheep", true) and Animals.new().look({"kind": "sheep", "age": 0, "sick": false, "prod_days": 0}) == "lamb", "lambs")


func _dog() -> void:
	var r: Dictionary = Animals.data().dog
	var home := Vector2i(int(r.home[0]), int(r.home[1]))
	var a := Animals.new()
	a.start()
	check(a.dog.cell == home and a.dog.affection == int(r.affection_start) and not a.dog.held, "the dog starts at home")
	check(a.dog_pet() and not a.dog_pet() and a.dog.affection == int(r.affection_start) + int(r.petted), "petted once a day")
	check(a.dog_lift() and a.dog.held and not a.dog_lift(), "picked up")
	a.dog_put(home + Vector2i(2, 0))
	check(not a.dog.held and a.dog.cell == home + Vector2i(2, 0), "set down in front")
	a.dog_lift()
	a.dog_put(home)
	var aff := int(r.affection_start) + int(r.petted) + int(r.lifted)
	check(a.dog.affection == aff, "picking up counts once a day (%d)" % a.dog.affection)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	a.dog_lift()
	a.dog_put(home + Vector2i(3, 3))
	a.day_end("sunny", rng)
	check(a.dog.affection == aff and a.dog.cell == home and not a.dog.held and not a.dog.petted, "a night: home again, nothing lost")
	a.day_end("sunny", rng)
	check(a.dog.affection == aff + int(r.ignored), "a day without a pat loses affection")
	a.dog_lift()
	a.day_end("sunny", rng)
	check(not a.dog.held, "the night puts it down")
	# Steps: following once fond, wandering near home otherwise, never into walls or the farmer.
	var free := func(c: Vector2i) -> bool: return c.x > 0 and c.y > 0 and c.x < FarmGrid.W - 1 and c.y < FarmGrid.H - 1
	a.dog.affection = int(r.follow_affection) - 1
	var far := home + Vector2i(int(r.follow_range) - 1, 0)
	var moved := 0
	for i in 300:
		moved += 1 if a.dog_step(far, free, rng) else 0
		var off: Vector2i = a.dog.cell - home
		if absi(off.x) + absi(off.y) > int(r.wander_range):
			check(false, "wandered too far: %s" % a.dog.cell)
			break
	check(moved > 30 and moved < 270, "a shy dog wanders now and then (%d steps of 300)" % moved)
	a.dog.cell = home
	a.dog.affection = int(r.follow_affection)
	check(a.dog_follows() and a.dog_step(far, free, rng) and a.dog.cell == home + Vector2i.RIGHT and a.dog.facing == Vector2i.RIGHT, "a fond dog follows")
	for i in 40:
		a.dog_step(far, free, rng)
		check(a.dog.cell != far, "never onto the farmer")
	var gap: Vector2i = far - a.dog.cell
	check(absi(gap.x) + absi(gap.y) == int(r.follow_from), "stops %d cells off" % int(r.follow_from))
	a.dog.cell = home
	check(not a.dog_step(far, func(_c): return false, rng) and a.dog.cell == home, "walls stop it")
	a.dog_lift()
	check(not a.dog_step(far, free, rng), "doesn't walk while held")
	a.dog_put(home)
	a.dog_walk(float(r.step_seconds) * 3.5, far, free, rng)
	check(a.dog.cell == home + Vector2i(3, 0), "dog_walk steps every %ss" % r.step_seconds)


func _barn_save() -> void:
	var a := _herd(["cow", "sheep"])
	a.add("cow", true)
	a.add("chicken")
	a.list[0].prod_days = 1
	a.list[1].brushed = true
	a.list[1].sick = true
	a.fill_feed_box("barn")
	a.toggle_out("sunny", 10, "barn")
	a.hour_passed("sunny")
	a.dog_pet()
	a.dog.cell = Vector2i(14, 9)
	a.dog.affection = 33
	var saved: Dictionary = JSON.parse_string(JSON.stringify(a.to_dict()))
	var r := Animals.parse(saved)
	check(r[0] == "" and r[1].to_dict() == a.to_dict(), "barn and dog round trip %s" % r[0])
	check(r[0] == "" and r[1].dog.cell == Vector2i(14, 9) and r[1].is_out("barn") and r[1].state.barn.box == 3, "dog cell, gate and fodder kept")
	var bad := {
		"no barn": func(d): d.erase("barn"),
		"barn gate as text": func(d): d.barn.out = "open",
		"fodder below 0": func(d): d.barn.stock = -1,
		"no dog": func(d): d.erase("dog"),
		"dog on the fence": func(d): d.dog.cell = [0, 5],
		"dog off the farm": func(d): d.dog.cell = [40, 5],
		"dog too fond": func(d): d.dog.affection = 999,
		"dog without a name": func(d): d.dog.erase("name"),
		"brushed as text": func(d): d.animals[0].brushed = "yes",
		"product days below 0": func(d): d.animals[0].prod_days = -2,
		"too many in the barn": func(d): for i in 6: d.animals.append(d.animals[0].duplicate()),
	}
	for key in bad:
		var d: Dictionary = saved.duplicate(true)
		bad[key].call(d)
		check(Animals.parse(d)[0] != "", "broken save refused: " + key)
	# A version 2 save: no barn, no dog, hens without the new fields.
	var old: Dictionary = _flock(2).to_dict()
	old.erase("barn")
	old.erase("dog")
	for h in old.animals:
		h.erase("brushed")
		h.erase("prod_days")
	old = JSON.parse_string(JSON.stringify(old))
	r = Animals.parse(old, Animals.data(), 2)
	check(r[0] == "" and r[1].list.size() == 2 and r[1].state.barn.stock == int(Animals.data().homes.barn.feed_start), "a version 2 save gets the new-game fodder %s" % r[0])
	check(r[0] == "" and r[1].dog.affection == int(Animals.data().dog.affection_start) and r[1].list[0].prod_days == 0, "and the new dog")
	check(Animals.parse(old, Animals.data(), 3)[0] == "", "a version 3 save gets them too")
	check(Animals.parse(old, Animals.data(), 4)[0] != "", "a version 4 save must have the barn and the dog")


func _herd(kinds: Array) -> Animals:
	var a := Animals.new()
	a.add_fodder(99)
	for k in kinds:
		a.add(k)
	return a


## The barn and the dog with the real Game autoload (fodder, tools on the animals, the gate,
## medicine; petting / lifting / putting down the dog through FarmActions).
func _barn_actions() -> void:
	var g: Node = root.get_node("Game")
	var BarnActions: GDScript = load("res://scripts/animals/barn_actions.gd")
	var FarmActions: GDScript = load("res://scripts/farm_actions.gd")
	var said: Array[String] = []
	g.message.connect(func(t): said.append(t))
	g.new_game()
	g.events_seen = {"first_morning": true, "rainy_day": true}
	var a: Animals = g.animals
	check(g.add_animal("cow") and g.add_animal("sheep"), "the shop hook adds a cow and a sheep")
	var cow := a.in_home("barn")[0]
	var sheep := a.in_home("barn")[1]
	a.list[cow].prod_days = 1
	a.list[sheep].prod_days = int(a.gives(a.list[sheep]).every)
	var spot: Array = MapManager.data("barn").spawns.start
	check(g.go_to_map("barn", spot[0], spot[1]) and BarnActions.in_barn() and g.indoors(), "into the barn (clock stops)")
	FarmActions.interact(_barn_prop("fodder_box"))
	check(a.state.barn.box == 2, "fodder into the box")
	FarmActions.interact(_barn_prop("fodder"))
	check(said.back().begins_with("The fodder box is full"), "the hay tells the box is full: %s" % said.back())
	var at_cow := a.spot(cow)
	FarmActions.on_action("interact", at_cow + Vector2i.DOWN, Vector2i.UP)
	check(g.held == "milk" and not a.product_ready(a.list[cow]), "E on the cow milks her: %s" % g.held)
	FarmActions.on_action("interact", at_cow + Vector2i.DOWN, Vector2i.UP)
	check(a.list[cow].brushed and g.held == "milk", "E again brushes")
	FarmActions.on_action("interact", at_cow + Vector2i.DOWN, Vector2i.UP)
	check(a.list[cow].petted, "and then talks")
	var at_sheep := a.spot(sheep)
	FarmActions.interact(at_sheep)
	FarmActions.interact(at_sheep)
	FarmActions.interact(at_sheep)
	check(a.product_ready(a.list[sheep]) and said.back() == "Your hands are full.", "hands full: no shearing (%s)" % said.back())
	g.held = ""
	FarmActions.interact(at_sheep)
	check(g.held.begins_with("wool") and a.look(a.list[sheep]) == "sheep_shorn", "sheared: %s overhead" % g.held)
	FarmActions.interact(_barn_prop("barn_tools"))
	check(said.back().begins_with("The brush"), "the tools on the wall")
	g.weather_today = "sunny"
	g.hour = 10
	FarmActions.interact(_barn_prop("barn_gate"))
	check(a.is_out("barn") and a.animal_at("barn", at_cow) == -1 and not a.outside, "the gate lets them out to graze")
	FarmActions.interact(_barn_prop("barn_gate"))
	check(not a.is_out("barn"), "and calls them back")
	a.list[cow].sick = true
	g.add_item("medicine")
	FarmActions.interact(at_cow)
	check(not a.list[cow].sick and g.count("medicine") == 0, "medicine cures the cow")
	var door: Dictionary = MapManager.data("barn").doors[0]
	g.held = ""
	check(g.go_to_map(door.to, door.spawn, door.facing) and g.maps.on_farm(), "back out on the farm")
	# The dog.
	var dog: Vector2i = a.dog.cell
	var aff: int = a.dog.affection
	FarmActions.on_action("interact", dog + Vector2i.DOWN, Vector2i.UP)
	check(a.dog.petted and a.dog.affection > aff and not a.dog.held, "E pets the dog")
	FarmActions.on_action("interact", dog + Vector2i.DOWN, Vector2i.UP)
	check(a.dog.held and g.holding() and g.held == "" and g.held_key() == "animal:dog:held:0", "E again picks it up")
	FarmActions.on_action("enter", dog + Vector2i.DOWN, Vector2i.UP)
	check(a.dog.held and said.back().begins_with("Put"), "no doors with the dog in the arms")
	FarmActions.on_action("tool", dog + Vector2i.DOWN, Vector2i.RIGHT)
	check(not a.dog.held and a.dog.cell == dog + Vector2i(1, 1) and not g.holding(), "set down in front")
	g.new_game()


func _barn_prop(use: String) -> Vector2i:
	for p in MapManager.data("barn").props:
		if p.get("use", "") == use:
			return p.cell
	return Vector2i(-1, -1)


func _barn_map_and_art() -> void:
	var r := MapManager.load_map("barn")
	check(r[0] == "", "barn map loads (%s)" % r[0])
	var m: MapData = r[1]
	check(m.indoor, "the barn is a building (clock stops)")
	var uses := []
	for p in m.props:
		uses.append(p.get("use", ""))
	for want in ["fodder_box", "fodder", "barn_tools", "barn_gate"]:
		check(want in uses, "barn has a %s" % want)
	var spots: Array = Animals.data().homes.barn.spots
	check(spots.size() >= int(Animals.data().homes.barn.capacity), "a stall for every place")
	for s in spots:
		var c := Vector2i(int(s[0]), int(s[1]))
		check(not m.is_solid(c) and m.door_at(c).is_empty() and m.prop_at(c).get("use", "") == "", "stall %s is free floor" % c)
		check(not m.is_solid(c + Vector2i.DOWN), "stall %s can be reached from the front" % c)
	check(not m.is_solid(_barn_prop("fodder_box") + Vector2i(11, 1)), "the fodder box can be reached by the last stall")
	var farm_door: Dictionary = MapManager.data("farm").door_at(FarmGrid.BARN_DOOR)
	check(farm_door.get("to") == "barn", "the farm's barn door leads in")
	check(m.doors[0].to == "farm" and m.doors[0].spawn == FarmGrid.BARN_DOOR + Vector2i.DOWN, "the barn door leads back out in front of it")
	# On the farm: its own spot, the pasture and the dog's home are open ground.
	var crops := _json("res://data/crops.json")
	var f := FarmGrid.new(crops)
	f.generate(RandomNumberGenerator.new())
	for y in range(FarmGrid.BARN.position.y, FarmGrid.BARN.end.y):
		for x in range(FarmGrid.BARN.position.x, FarmGrid.BARN.end.x):
			check(f.fixed_at(Vector2i(x, y)) in ["barn", "barn_door"], "barn cell %d, %d" % [x, y])
	check(not FarmGrid.BARN.intersects(FarmGrid.COOP) and FarmGrid.BARN.end.x <= 25, "the barn is clear of the coop and the pond")
	var yard: Array = Animals.data().homes.barn.yard
	for y in range(yard[1], yard[1] + yard[3]):
		for x in range(yard[0], yard[0] + yard[2]):
			check(f.fixed_at(Vector2i(x, y)) == "" and y < 7, "pasture %d, %d is open grass" % [x, y])
	var home: Array = Animals.data().dog.home
	check(f.fixed_at(Vector2i(int(home[0]), int(home[1]))) == "", "the dog's home cell is open")
	for c in f.fixed.keys():
		if f.fixed[c] in ["barn", "barn_door"]:
			f.fixed.erase(c)
	f.till(Vector2i(20, 2))
	f.add_missing_fixed()
	check(f.fixed_at(Vector2i(20, 2)) == "barn" and not f.cell(Vector2i(20, 2)).tilled and f.fixed_at(FarmGrid.BARN_DOOR) == "barn_door", "barn added to an older farm")
	# Art.
	var sizes := {"cow": Vector2(52, 38), "calf": Vector2(34, 26), "sheep": Vector2(40, 32), "sheep_shorn": Vector2(40, 32),
		"lamb": Vector2(26, 22), "dog": Vector2(30, 24)}
	for kind in sizes:
		for pose in ["idle", "peck", "walk", "sick"]:
			for frame in 2:
				var key := "animal:%s:%s:%d" % [kind, pose, frame]
				check(PlaceholderArt.tex(key).get_size() == sizes[kind], key + " size")
	check(PlaceholderArt.tex("animal:dog:sit:0").get_size() == sizes.dog, "dog sit")
	check(PlaceholderArt.tex("animal:dog:held:0").get_size() == Vector2(14, 11), "the dog in the arms keeps its small picture")
	var data_of := func(k): return PlaceholderArt.tex(k).get_image().get_data()
	check(data_of.call("animal:sheep:idle:0") != data_of.call("animal:sheep_shorn:idle:0"), "a shorn sheep looks different")
	check(data_of.call("animal:cow:idle:0") != data_of.call("animal:cow:sick:0"), "a sick cow looks different")
	check(data_of.call("animal:cow:walk:0") != data_of.call("animal:cow:walk:1"), "the cow walks")
	for id in ["milk", "milk_good", "milk_best", "wool", "wool_good", "wool_best"]:
		check(PlaceholderArt.world_item_key(id) == "item:" + id and PlaceholderArt.tex("item:" + id).get_size() == Vector2(12, 12), id + " world sprite")
		check(PlaceholderArt.tex(PlaceholderArt.item_key(id)).get_size() == Vector2(14, 14), id + " slot icon")
	check(data_of.call("item:milk") != data_of.call("item:milk_best") and data_of.call("item:wool") != data_of.call("item:wool_good"), "grades look different")

func _prop_cell(use: String) -> Vector2i:
	for p in MapManager.data("coop").props:
		if p.get("use", "") == use:
			return p.cell
	return Vector2i(-1, -1)


func _flock(n: int) -> Animals:
	var a := Animals.new()
	a.feed_stock = 99
	for i in n:
		a.add("chicken")
	return a


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


# --- the animal sprites (AnimalArt): sizes, facings, states -------------------------

func _animal_art() -> void:
	check(AnimalArt.SCALE >= 2, "animal sprites are denser than the farmer's (the layer sets pixel_size = PX / SCALE)")
	var poses := ["idle", "peck", "walk", "sick"]
	for kind in AnimalArt.KINDS:
		var size: Vector2i = AnimalArt.size_of(kind)
		var seen := {}
		for facing in AnimalArt.FACINGS:
			for pose in poses + (["sit"] if kind == "dog" else []):
				for frame in 2:
					var key := "animal:%s:%s:%d:%s" % [kind, pose, frame, facing]
					var img := PlaceholderArt.tex(key).get_image()
					check(img.get_size() == Vector2i(size), key + " size")
					check(_opaque(img) > size.x * size.y / 12, key + " is drawn")
					check(_feet_row(img) == size.y - 1, key + " stands on the bottom row (its outline)")
		var tex_default := PlaceholderArt.tex("animal:%s:idle:0" % kind).get_image().get_data()
		check(tex_default == PlaceholderArt.tex("animal:%s:idle:0:dl" % kind).get_image().get_data(), kind + ": no facing means down-left")
		# Four facings that differ: the right ones are the left ones mirrored, front and back differ.
		var dl := PlaceholderArt.tex("animal:%s:idle:0:dl" % kind).get_image()
		var dr := PlaceholderArt.tex("animal:%s:idle:0:dr" % kind).get_image()
		var ul := PlaceholderArt.tex("animal:%s:idle:0:ul" % kind).get_image()
		var ur := PlaceholderArt.tex("animal:%s:idle:0:ur" % kind).get_image()
		var mirrored := dl.duplicate() as Image
		mirrored.flip_x()
		check(dr.get_data() == mirrored.get_data() and dr.get_data() != dl.get_data(), kind + ": down-right mirrors down-left")
		mirrored = ul.duplicate() as Image
		mirrored.flip_x()
		check(ur.get_data() == mirrored.get_data() and ul.get_data() != dl.get_data(), kind + ": up faces differ from down faces")
		# The states: sick differs from idle, a step differs from the other, grazing from standing.
		var idle := PlaceholderArt.tex("animal:%s:idle:0" % kind).get_image().get_data()
		check(idle != PlaceholderArt.tex("animal:%s:sick:0" % kind).get_image().get_data(), kind + ": sick looks different")
		check(PlaceholderArt.tex("animal:%s:walk:0" % kind).get_image().get_data() != PlaceholderArt.tex("animal:%s:walk:1" % kind).get_image().get_data(), kind + ": walks")
		check(idle != PlaceholderArt.tex("animal:%s:peck:1" % kind).get_image().get_data(), kind + ": grazes with its head down")
	# Bigger animals are bigger: cow > sheep > dog, hen > chick; the young are smaller.
	var area := func(k): return AnimalArt.size_of(k).x * AnimalArt.size_of(k).y
	check(area.call("cow") > area.call("sheep") and area.call("sheep") > area.call("dog") and area.call("sheep") > area.call("chicken") and area.call("dog") > area.call("chick") and area.call("chicken") > area.call("chick"), "kinds keep their relative sizes")
	check(area.call("calf") < area.call("cow") and area.call("lamb") < area.call("sheep") and area.call("lamb") < area.call("sheep_shorn"), "the young are smaller")
	# Facing from a step: the camera's right is +x -z, towards it +x +z.
	check(AnimalArt.facing_of(Vector2(1, 0)) == "dr" and AnimalArt.facing_of(Vector2(0, 1)) == "dl", "steps towards the camera face down")
	check(AnimalArt.facing_of(Vector2(-1, 0)) == "ul" and AnimalArt.facing_of(Vector2(0, -1)) == "ur", "steps away face up")
	check(AnimalArt.facing_of(Vector2(1, -1)) == "dr" and AnimalArt.facing_of(Vector2.ZERO, "ul") == "ul", "a sideways step keeps the near/far side; no step keeps the facing")
	check(AnimalArt.facing_of(Vector2(1, -1), "ul") == "ur" and AnimalArt.facing_of(Vector2(-1, 1), "dr") == "dl", "a pure left or right step keeps the front or back")
	_animal_art_refined()


## The refined look (data/animal_art.json): three tones a material, deep part lines, a rim in the
## material's own deep tone instead of the old near-black outline; sizes and the sick dullness kept.
func _animal_art_refined() -> void:
	var old_line := FigureArt._key(Color("2a1e1e"))
	var sizes := {"chicken": Vector2i(30, 28), "chick": Vector2i(18, 16), "cow": Vector2i(52, 38), "calf": Vector2i(34, 26),
		"sheep": Vector2i(40, 32), "sheep_shorn": Vector2i(40, 32), "lamb": Vector2i(26, 22), "dog": Vector2i(30, 24)}
	var main_part := {"chicken": "hen", "chick": "chick"}
	for kind in AnimalArt.KINDS:
		check(AnimalArt.size_of(kind) == sizes[kind], kind + " keeps its size %s" % AnimalArt.size_of(kind))
		var part: String = main_part.get(kind, "body")
		var m := AnimalArt.tones_of(kind, part)
		var sick_m := AnimalArt.tones_of(kind, part, true)
		for facing in AnimalArt.FACINGS:
			for pose in ["idle", "peck", "walk", "sick"] + (["sit"] if kind == "dog" else []):
				for frame in 2:
					var key := "animal:%s:%s:%d:%s" % [kind, pose, frame, facing]
					var img := PlaceholderArt.tex(key).get_image()
					var cols := _colours(img)
					check(not cols.has(old_line), key + ": no pixel in the old outline colour")
					var rim := _rim_colours(img)
					var tm: Dictionary = sick_m if pose == "sick" else m
					var want: Color = tm.deep.lerp(Color(str(AnimalArt.art().rim)), float(AnimalArt.art().rim_mix))
					var rim_keys := {}
					for c: Color in rim:
						rim_keys[c.to_html()] = true
					check(rim_keys.has(FigureArt._key(want)), key + ": the rim round the %s is its own deep tone pulled to the rim colour" % part)
					var tones := 0
					for role in ["shade", "base", "lit"]:
						if cols.has(FigureArt._key(tm[role])):
							tones += 1
					check(tones == 3, key + ": the %s shows its shade, base and lit tones (%d)" % [part, tones])
					if pose == "sick":
						check(not cols.has(FigureArt._key(m.base)) and not cols.has(FigureArt._key(m.lit)), key + ": sick keeps its dull colours")
					if kind in ["chicken", "chick", "sheep", "lamb"]:   # pale birds and wool: a grey rim, not a black one
						var dark := 0
						var light := 0.0
						for c: Color in rim:
							if c.v < 0.12:
								dark += 1
							light = maxf(light, c.v)
						check(light > 0.22, key + ": the pale coat's rim is a soft grey, lighter than the old outline (%.2f)" % light)
						if kind in ["chicken", "chick"]:
							check(dark == 0, key + ": a hen or chick has no near-black rim (%d dark rim colours)" % dark)
	# Part lines in a material's deep tone: the hen's wing, the wool over the sheep's legs and face.
	var hen := _colours(PlaceholderArt.tex("animal:chicken:idle:0:dl").get_image())
	check(hen.has(FigureArt._key(AnimalArt.tones_of("chicken", "wing").deep)), "the hen's wing is lined in its deep tone")
	var sheep := _colours(PlaceholderArt.tex("animal:sheep:idle:0:dl").get_image())
	check(sheep.has(FigureArt._key(AnimalArt.tones_of("sheep", "body").deep)), "the wool's edge over the legs and face is its deep tone")
	var cow := _colours(PlaceholderArt.tex("animal:cow:idle:0:dl").get_image())
	check(cow.has(FigureArt._key(AnimalArt.tones_of("cow", "muzzle").deep)), "the cow's muzzle is lined in its deep tone")
	# The dog in the arms: the same toning, its size kept.
	var held := PlaceholderArt.tex("animal:dog:held:0").get_image()
	var hc := _colours(held)
	check(held.get_size() == Vector2i(14, 11) and not hc.has(old_line) and hc.size() >= 8, "the dog in the arms is toned, no old outline (%d colours)" % hc.size())


## The colour keys of a picture's drawn pixels.
func _colours(img: Image) -> Dictionary:
	var out := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				out[c.to_html()] = true
	return out


## The colours on the picture's outer edge (drawn pixels next to a clear one or the canvas edge).
func _rim_colours(img: Image) -> Array:
	var out := {}
	var size := img.get_size()
	for y in size.y:
		for x in size.x:
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= size.x or q.y >= size.y or img.get_pixelv(q).a == 0.0:
					out[c.to_html()] = c
					break
	return out.values()


func _opaque(img: Image) -> int:
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				n += 1
	return n


## The lowest row with a drawn pixel.
func _feet_row(img: Image) -> int:
	for y in range(img.get_height() - 1, -1, -1):
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				return y
	return -1
