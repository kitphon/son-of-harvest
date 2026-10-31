extends SceneTree
## Headless checks for the animals (Animals rules, data/animals.json, the coop map and its
## actions, eggs as held items, the save, the art). Run:
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


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_coop_actions()
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
	check("The hens were out all night" in news, "news of the night out %s" % [news])
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
	check(a.list[0].sick and ("%s looks sick" % a.list[0].name) in news, "an unhappy hen falls sick %s" % [news])
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
	check(not a.list[0].sick and ("%s is well again" % a.list[0].name) in news, "well again after %d nights" % int(r.sickness.recover_days))
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
	check(a.is_adult(a.list[0]) and ("%s has grown up" % a.list[0].name) in news, "grown up after %d nights" % grow)
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
	check(g.sell_price("egg") == int(Animals.data().items.egg.sell) and g.item_name("egg_best") == "Golden Yolk Egg", "eggs have a price and a name")
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
	# An egg overhead ships when thrown into the bin.
	g.held = "egg_good"
	var t: Dictionary = g.throw_held(Vector2i(8, 5), Vector2i.UP)
	check(t.result == "ship" and t.value == g.sell_price("egg_good") and g.shipped.get("egg_good") == 1, "egg thrown into the bin is shipped %s" % t)
	g.inventory.add("egg", 2)
	var before: int = g.bin_total
	g.ship_produce()
	check(g.bin_total == before + 2 * g.sell_price("egg"), "eggs in the rucksack ship at the bin too")
	# Save: version 2 keeps the animals; a version 1 save gets the starting flock and the coop.
	check(SaveGame.VERSION >= 2, "save version 2 or later")
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	var flock: int = g.animals.list.size()
	var laid: int = g.animals.eggs.size()
	g.new_game()
	check(g.from_dict(d) == "" and g.animals.list.size() == flock and g.animals.eggs.size() == laid and laid > 0, "animals load from a save")
	var old: Dictionary = d.duplicate(true)
	old.erase("animals")
	check(g.from_dict(old, 2) != "", "a version 2 save must have animals")
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
		check(PlaceholderArt.tex(key).get_size() == Vector2(14, 12), key + " is 14 x 12")
	check(PlaceholderArt.tex("animal:chick:walk:1").get_size() == Vector2(9, 8), "chick is 9 x 8")
	check(PlaceholderArt.tex("animal:chicken:idle:0").get_image().get_data() != PlaceholderArt.tex("animal:chicken:sick:0").get_image().get_data(), "a sick hen looks different")
	for egg in ["egg", "egg_good", "egg_best"]:
		check(PlaceholderArt.world_item_key(egg) == "item:" + egg and PlaceholderArt.tex("item:" + egg).get_size() == Vector2(12, 12), egg + " world sprite")
		check(PlaceholderArt.tex(PlaceholderArt.item_key(egg)).get_size() == Vector2(14, 14), egg + " slot icon")
	check(PlaceholderArt.world_item_key("eggplant") == "item:eggplant", "eggplant is still a crop")
	check(PlaceholderArt.tex("ground:straw:0").get_size() == Vector2(16, 16) and PlaceholderArt.tex("build:thatch").get_size() == Vector2(16, 16), "straw floor and thatch")


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
