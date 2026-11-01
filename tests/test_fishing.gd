extends SceneTree
## Headless checks for fishing (Fishing rules, data/fish.json, Game.cast_line / reel_in, the
## catch as a held item, the river, the save, the poses and fish art). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_fishing.gd

var failures := 0


func _init() -> void:
	var rules: Dictionary = _json("res://data/fish.json")
	var fish: Dictionary = rules.fish
	var seasons := ["spring", "summer", "fall", "winter"]
	var weathers: Array = rules.weather_bite.keys()

	# Data: every fish is complete and lives somewhere we know.
	check(fish.size() >= 8, "at least 8 fish (%d)" % fish.size())
	for id in fish:
		var f: Dictionary = fish[id]
		check(f.has("name") and int(f.get("sell", 0)) > 0, "%s has a name and a price" % id)
		check(not f.places.is_empty(), "%s lives somewhere" % id)
		for p in f.places:
			check(rules.places.has(p), "%s: place %s is known" % [id, p])
		for s in f.get("seasons", []):
			check(s in seasons, "%s: season %s" % [id, s])
		var h: Array = f.get("hours", [0, 24])
		check(h.size() == 2 and int(h[0]) >= 0 and int(h[1]) <= 24, "%s: hours" % id)
		check(f.has("look"), "%s has a look" % id)
	var last := -1
	for band in rules.bite_chance:
		check(int(band[0]) > last and float(band[1]) > 0.0 and float(band[1]) <= 1.0, "bite band %s" % [band])
		last = int(band[0])
	check(int(rules.bite_chance[0][0]) == 0, "bite bands start at midnight")

	# Something bites at every place, in every season, hour and weather.
	var empty := 0
	for p in rules.places:
		for s in seasons:
			for hour in 24:
				for w in weathers:
					empty += int(Fishing.candidates(rules, p, s, hour, w).is_empty())
	check(empty == 0, "every place / season / hour / weather has a fish (%d empty)" % empty)

	# Hours, seasons, places, weather, once-only.
	check(Fishing.in_hours([19, 4], 23) and Fishing.in_hours([19, 4], 2) and not Fishing.in_hours([19, 4], 12), "hours wrap past midnight")
	check(Fishing.in_hours([5, 18], 5) and not Fishing.in_hours([5, 18], 18) and Fishing.in_hours([], 3), "hours [from, to)")
	check(Fishing.candidates(rules, "town", "summer", 10, "sunny").has("ayu"), "sweetfish in the village in summer")
	check(not Fishing.candidates(rules, "farm", "summer", 10, "sunny").has("ayu"), "no sweetfish in the farm pond")
	check(not Fishing.candidates(rules, "town", "winter", 10, "sunny").has("ayu"), "no sweetfish in winter")
	check(not Fishing.candidates(rules, "town", "summer", 20, "sunny").has("ayu"), "no sweetfish at night")
	var dry: Dictionary = Fishing.candidates(rules, "farm", "spring", 10, "sunny")
	var wet: Dictionary = Fishing.candidates(rules, "farm", "spring", 10, "rain")
	check(is_equal_approx(wet.dojo, dry.dojo * 2.0), "loaches bite twice as often in rain")
	check(Fishing.candidates(rules, "town", "fall", 23, "sunny").has("moon_koi"), "the moonlit koi on a clear fall night")
	check(not Fishing.candidates(rules, "town", "fall", 23, "rain").has("moon_koi"), "not in rain")
	check(not Fishing.candidates(rules, "town", "fall", 23, "sunny", {"moon_koi": 1}).has("moon_koi"), "caught only once")

	# The river (data/maps/river.json): its own fish, more stream fish than the pond, no pond fish.
	check(rules.places.has("river"), "the river is a fishing place")
	var river_kinds := {}
	for s in seasons:
		for hour in 24:
			for wx in weathers:
				for id in Fishing.candidates(rules, "river", s, hour, wx):
					river_kinds[id] = true
	for id in ["ugui", "oikawa", "kajika", "sake", "nushi"]:
		check(fish.has(id) and fish[id].places.keys() == ["river"], "%s lives only in the river" % id)
		check(river_kinds.has(id), "%s can bite in the river" % id)
	for id in ["funa", "dojo", "wakasagi"]:
		check(not river_kinds.has(id), "no pond fish %s in the river" % id)
	for id in ["ayu", "yamame", "iwana"]:
		check(int(fish[id].places.get("river", 0)) > int(fish[id].places.town), "more %s in the river than the village pond" % id)
	check(Fishing.candidates(rules, "river", "fall", 10, "sunny").has("sake") and not Fishing.candidates(rules, "river", "summer", 10, "sunny").has("sake"), "the salmon run is in fall")
	var run_dry: Dictionary = Fishing.candidates(rules, "river", "fall", 10, "sunny")
	var run_wet: Dictionary = Fishing.candidates(rules, "river", "fall", 10, "rain")
	check(run_wet.sake / _sum(run_wet) > run_dry.sake / _sum(run_dry), "salmon run better in rain")
	check(Fishing.candidates(rules, "river", "winter", 22, "snow").has("kajika") and not Fishing.candidates(rules, "river", "winter", 12, "snow").has("kajika"), "sculpins at night in the cold months")
	check(Fishing.candidates(rules, "river", "summer", 4, "rain").has("nushi"), "the river elder at a wet summer dawn")
	check(not Fishing.candidates(rules, "river", "summer", 4, "sunny").has("nushi") and not Fishing.candidates(rules, "river", "summer", 10, "rain").has("nushi"), "not on a clear day, not late")
	check(not Fishing.candidates(rules, "river", "summer", 4, "rain", {"nushi": 1}).has("nushi"), "the river elder only once")

	# Picking by weight.
	var w := {"a": 1.0, "b": 3.0}
	check(Fishing.pick(w, 0.0) == "a" and Fishing.pick(w, 0.24) == "a" and Fishing.pick(w, 0.26) == "b" and Fishing.pick(w, 0.999) == "b", "pick by weight")
	check(Fishing.pick({}, 0.5) == "", "nothing to pick")

	# Bite chance by hour and weather.
	check(Fishing.bite_chance(rules, 5, "sunny") > Fishing.bite_chance(rules, 12, "sunny"), "dawn bites better than noon")
	check(Fishing.bite_chance(rules, 12, "rain") > Fishing.bite_chance(rules, 12, "sunny"), "rain bites better")
	check(is_equal_approx(Fishing.bite_chance(rules, 23, "sunny"), float(rules.bite_chance.back()[1])), "the last band runs to midnight")

	# The line: wait, bite, escape, reel.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var min_wait := float(rules.min_wait_seconds)
	var line := Fishing.new(rules)
	check(not line.active() and line.step(1.0, 1.0, rng) == "", "idle: nothing happens")
	line.cast("farm", Vector2i(25, 3))
	check(line.active() and line.state == "wait" and line.place == "farm", "cast: waiting")
	check(line.step(min_wait - 0.1, 1.0, rng) == "", "no bite before the shortest wait")
	check(line.step(0.2, 1.0, rng) == "bite" and line.state == "bite", "a sure chance bites at the first check")
	check(line.step(float(rules.bite_seconds) - 0.05, 1.0, rng) == "" and line.state == "bite", "the bite lasts a moment")
	check(line.step(0.1, 1.0, rng) == "escaped" and not line.active() and line.dry_casts == 1, "too late: it got away")
	line.cast("farm", Vector2i(25, 3))
	line.step(min_wait + 0.01, 1.0, rng)
	check(line.reel() == "catch" and line.dry_casts == 0 and not line.active(), "in time: caught, the pity count resets")
	line.cast("farm", Vector2i(25, 3))
	line.step(0.5, 0.0, rng)
	check(line.reel() == "early" and line.dry_casts == 0, "reeled in at once: not a dry cast")
	line.cast("farm", Vector2i(25, 3))
	check(line.step(min_wait + 30.0, 0.0, rng) == "" and line.state == "wait", "chance 0: no bite")
	check(line.reel() == "early" and line.dry_casts == 1, "a real wait that came to nothing is a dry cast")
	check(line.reel() == "none", "nothing to reel")
	line.dry_casts = int(rules.sure_after)
	line.cast("farm", Vector2i(25, 3))
	check(line.step(min_wait + 0.01, 0.0, rng) == "bite", "the pity rule: a sure bite after %d dry casts" % int(rules.sure_after))
	line.stop()
	check(not line.active(), "stop takes the line out")

	# In the game: the rod, casting at the farm pond, the catch overhead, shipping it.
	var g := _game(rules)
	check("rod" in g.TOOLS and g.inventory.count("rod", ["tools"]) == 1, "a new game starts with the rod")
	check(int(g.tools_data.rod.stamina) > 0, "the rod costs stamina (data/tools.json)")
	var by_pond := Vector2i(24, 3)
	check(g.water_ahead(by_pond, Vector2i.RIGHT) == Vector2i(25, 3), "the pond is in front")
	check(g.water_ahead(by_pond, Vector2i.LEFT) == Vector2i(-1, -1), "no water the other way")
	check(g.water_ahead(Vector2i(23, 3), Vector2i.RIGHT) == Vector2i(25, 3), "the rod reaches two cells")
	check(g.cast_line(by_pond, Vector2i.LEFT) == "no_water" and not g.fishing.active(), "no cast without water")
	var st: int = g.stamina
	check(g.cast_line(by_pond, Vector2i.RIGHT) == "cast" and g.fishing.active() and g.fishing.spot == Vector2i(25, 3), "cast into the pond")
	check(g.stamina == st - int(g.tools_data.rod.stamina), "a cast costs stamina")
	check(g.reel_in().result == "early" and not g.holding(), "reeled in early: nothing")
	g.cast_line(by_pond, Vector2i.RIGHT)
	g.fishing.state = "bite"
	var got: Dictionary = g.reel_in()
	check(got.result == "catch" and got.fish.begins_with("fish:") and g.held == got.fish, "the catch goes up overhead (%s)" % got.fish)
	var fid: String = got.fish.trim_prefix("fish:")
	check(int(g.fish_caught.get(fid, 0)) == 1 and rules.fish[fid].places.has("farm"), "counted, and it lives in the farm pond")
	check(g.item_name(got.fish) == String(rules.fish[fid].name), "the fish has its name")
	check(g.cast_line(by_pond, Vector2i.RIGHT) == "hands_full", "no cast with hands full")
	var price: int = g.sell_price(got.fish)
	check(price == int(rules.fish[fid].sell), "the bin pays the fish's price")
	var t: Dictionary = g.throw_held(Vector2i(8, 5), Vector2i.UP)
	check(t.result == "ship" and g.bin_total == price and int(g.shipped.get(got.fish, 0)) == 1, "thrown into the bin: shipped")
	check(g.inventory.add("fish:koi", 3) == 0 and g.count("fish:koi") == 3, "fish go in the rucksack")
	check(not g.inventory.accepts("tools", "fish:koi"), "not in a tool slot")

	# Stopped by a map change and by the night.
	g.cast_line(by_pond, Vector2i.RIGHT)
	g.go_to_map("town", Vector2i(30, 15), Vector2i.RIGHT)
	check(not g.fishing.active(), "a map change takes the line out")
	check(g.water_ahead(Vector2i(30, 15), Vector2i.RIGHT) == Vector2i(31, 15), "the village pond is water")
	check(g.cast_line(Vector2i(30, 15), Vector2i.RIGHT) == "cast" and g.fishing.place == "town", "cast in the village")
	g.fishing.state = "bite"
	var town_fish: String = g.reel_in().fish.trim_prefix("fish:")
	check(rules.fish[town_fish].places.has("town"), "a village fish (%s)" % town_fish)
	g.held = ""

	# The river: down the lane off the village's south edge, a cast from the shore, a river fish.
	var lane: Dictionary = MapManager.data("town").door_at(Vector2i(4, 36))
	check(lane.get("to", "") == "river", "the village's south lane goes to the river")
	g.use_door(lane)
	check(g.maps.id == "river" and not g.indoors(), "at the river")
	var shore: Array = MapManager.data("river").spawns.shore
	check(g.water_ahead(shore[0], Vector2i.DOWN) == shore[0] + Vector2i.DOWN, "the river is in front of the shore")
	check(g.water_ahead(shore[0], Vector2i.UP) == Vector2i(-1, -1), "and none behind")
	check(g.cast_line(shore[0], Vector2i.DOWN) == "cast" and g.fishing.place == "river", "cast in the river")
	var river_seen := {}
	for i in 30:
		g.fishing.state = "bite"
		var rf: String = g.reel_in().fish
		check(rf.begins_with("fish:") and g.held == rf, "a river catch goes overhead (%s)" % rf)
		river_seen[rf.trim_prefix("fish:")] = true
		g.held = ""
		g.cast_line(shore[0], Vector2i.DOWN)
	var only_river := true
	for id in river_seen:
		only_river = only_river and rules.fish[id].places.has("river")
	check(only_river and river_seen.size() >= 2, "river catches are river fish %s" % [river_seen.keys()])
	g.fishing.state = "bite"
	var kept: String = g.reel_in().fish
	check(g.inventory.add(kept, 1) == 0 and g.count(kept) >= 1, "a river fish goes in the rucksack")
	check(g.edible(kept) and g.food_info(kept).name == String(rules.fish[kept.trim_prefix("fish:")].name), "a river fish is food (fish:*)")
	g.held = ""
	check(Villagers.reaction("kota", "fish:nushi") == "love" and Villagers.reaction("kota", "fish:ugui") == "like", "Kota: the river elder best, any fish")
	check(Villagers.reaction("hachiro", "fish:sake") == "love" and Villagers.reaction("tome", "fish:sake") == "like", "the fall salmon for Hachiro and Tome")
	check(Villagers.reaction("sayo", "fish:ugui") == "dislike", "Sayo minds the bony dace")
	g.go_to_map("town", Vector2i(30, 15), Vector2i.RIGHT)
	g.cast_line(Vector2i(30, 15), Vector2i.RIGHT)
	g.end_day()
	check(not g.fishing.active(), "the night takes the line out")

	# Save: what was caught and the pity count; older saves get the rod.
	g.fishing.dry_casts = 3
	var saved: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	var h := _game(rules)
	check(h.from_dict(saved) == "", "a save with fishing loads")
	check(h.fish_caught == g.fish_caught and h.fishing.dry_casts == 3, "caught fish and the pity count come back")
	var old: Dictionary = saved.duplicate(true)
	old.erase("fishing")
	for i in old.inventory.tools.size():
		if old.inventory.tools[i] != null and old.inventory.tools[i].id == "rod":
			old.inventory.tools[i] = null
	old.inventory.tools.resize(7)
	check(h.from_dict(old) == "" and h.inventory.count("rod", ["tools", "chest"]) == 1, "a save from before fishing gets the rod")
	check(h.fish_caught.is_empty() and h.fishing.dry_casts == 0, "and nothing caught yet")
	for bad in [{"caught": []}, {"caught": {"funa": -1}, "dry_casts": 0}, {"caught": {}, "dry_casts": "x"}, "x"]:
		var broken: Dictionary = saved.duplicate(true)
		broken.fishing = bad
		check(h.from_dict(broken) != "", "refused fishing %s" % JSON.stringify(bad))

	# Art: fishing poses, the rod tip on the sprite, bobber, "!", fish and rod icons.
	var anim := FarmerAnim.new()
	anim.step(0.1, false, false, false, false, "wait")
	check(anim.pose == "fish_wait" and anim.key(Vector2i.DOWN) == "player:front:fish_wait:0", "waiting pose")
	anim.step(0.1, true, false, true, true, "bite")
	check(anim.pose == "fish_bite", "the bite pose wins over walking, tired and holding")
	anim.step(0.1, false, false, false, false, "idle")
	check(anim.pose == "idle", "idle line: the usual pose")
	var idle := PlaceholderArt.tex("player:front:idle:0").get_image().get_data()
	for pose in ["fish_wait", "fish_bite"]:
		for back in ["front", "back"]:
			for i in PlaceholderArt.farmer_frames(pose):
				var img := PlaceholderArt.tex("player:%s:%s:%d" % [back, pose, i]).get_image()
				var tip := PlaceholderArt.rod_tip(pose, i)
				check(img.get_size() == Vector2i(16, 24) and img.get_data() != idle, "%s %s %d drawn" % [back, pose, i])
				check(img.get_pixelv(tip).a > 0.0, "%s %s %d: the rod reaches its tip %s" % [back, pose, i, tip])
	check(PlaceholderArt.rod_tip("fish_bite", 0).y > PlaceholderArt.rod_tip("fish_wait", 0).y, "a bite pulls the tip down")
	check(PlaceholderArt.tex("fish_fx:bobber").get_size() == Vector2(5, 7) and PlaceholderArt.tex("fish_fx:alert").get_size() == Vector2(7, 11), "bobber and bite mark")
	var magenta := PlaceholderArt.tex("unknown:x").get_image().get_data()
	check(PlaceholderArt.item_key("rod") == "ui:tool:rod" and PlaceholderArt.tex("ui:tool:rod").get_image().get_data() != magenta, "rod icon")
	var seen := {}
	for id in fish:
		var key := PlaceholderArt.item_key("fish:" + id)
		check(key == "ui:fish:" + id and PlaceholderArt.world_item_key("fish:" + id) == key, "%s icon key" % id)
		var img := PlaceholderArt.tex(key).get_image()
		var solid := 0
		for y in img.get_height():
			for x in img.get_width():
				solid += int(img.get_pixel(x, y).a > 0.0)
		check(img.get_size() == Vector2i(14, 14) and solid >= 20, "%s icon (%d px)" % [id, solid])
		seen[img.get_data()] = id
	check(seen.size() == fish.size(), "every fish looks different")

	g.free()
	h.free()
	print("test_fishing: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func _game(rules: Dictionary) -> Node:
	var g: Node = (load("res://scripts/autoload/game.gd") as GDScript).new()
	g.crops = _json("res://data/crops.json")
	g.tools_data = _json("res://data/tools.json")
	g.snow_rules = _json("res://data/snow_cover.json")
	g.body = _json("res://data/body.json")
	g.hold_rules = _json("res://data/hold.json")
	g.set_food_data(_json("res://data/foods.json"))
	g.fish_data = rules
	g.rng.seed = 7
	g.new_game()
	return g


func _sum(weights: Dictionary) -> float:
	var t := 0.0
	for id in weights:
		t += float(weights[id])
	return t


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
