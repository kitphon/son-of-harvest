extends SceneTree
## Headless checks for the mine (data/mine.json, MineFloor, Game.mine_swing / go_to_map down
## the mine, the maps and their doors, stamina, the save, the light, winter floors, the rope lift
## landings, the art). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_mine.gd

var failures := 0


func _init() -> void:
	var rules: Dictionary = _json("res://data/mine.json")
	_data(rules)
	_odds(rules)
	_worth(rules)
	_layout(rules)
	_break_and_dig(rules)
	_maps()
	_game_mine(rules)
	_save(rules)
	_light(rules)
	_winter(rules)
	_game_winter(rules)
	_landings(rules)
	_landing_game(rules)
	_landing_save(rules)
	_art(rules)
	print("test_mine: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


## Every find in the tables is an item with a name, a kind, a price and a look.
func _data(rules: Dictionary) -> void:
	var items: Dictionary = rules.items
	for id in items:
		var it: Dictionary = items[id]
		check(it.has("name") and it.kind in ["stone", "ore", "gem"] and int(it.get("sell", 0)) > 0, "%s has a name, kind and price" % id)
		check(it.has("look") and it.look.has("shape"), "%s has a look" % id)
	var kinds := {}
	for id in items:
		kinds[items[id].kind] = int(kinds.get(items[id].kind, 0)) + 1
	check(int(kinds.get("ore", 0)) >= 3 and int(kinds.get("gem", 0)) >= 2 and int(kinds.get("stone", 0)) >= 1, "ores, gems and stones (%s)" % kinds)
	var last := 0
	for b in rules.floors:
		check(int(b.from) > last, "floor bands go deeper (%d)" % int(b.from))
		last = int(b.from)
		for key in ["rocks", "big_rocks", "soft"]:
			check(b[key].size() == 2 and int(b[key][0]) <= int(b[key][1]) and int(b[key][0]) >= 0, "band %d: %s range" % [b.from, key])
		for src in ["rock", "big_rock", "soft"]:
			check(b.finds.has(src) and not b.finds[src].is_empty(), "band %d finds from %s" % [b.from, src])
			for f in b.finds[src]:
				check(f == "none" or items.has(f), "band %d %s: %s is an item" % [b.from, src, f])
		check(int(b.hits.rock) >= 1 and int(b.hits.big_rock) > int(b.hits.rock), "band %d: big rocks are tougher" % b.from)
	check(int(rules.floors[0].from) == 1, "the first band starts at floor 1")
	for s in rules.seasons:
		check(s in ["spring", "summer", "fall", "winter"], "season %s" % s)
		for f in rules.seasons[s]:
			check(items.has(f), "season %s: %s is an item" % [s, f])
	check(MapManager.has(rules.entrance_map) and MapManager.has(rules.floor_map), "the mine maps exist")
	check(MapManager.data(rules.entrance_map).spawns.has(rules.entrance_spawn), "the entrance has the cave spawn")


## What a floor is worth (FEEDBACK item 4): with the rope lift a winter trip starts at floor
## 15 every day, so the deep floors must be a good side income, not the game's best money.
## G of every find a floor hides on average (counts at their middle, winter's odds; a trip breaks about half of them on its way to the hole): the deep
## band's floor stays under a cap (a trip goes about five floors), deeper still pays more, and
## a frozen floor's ice never makes the shallow floors the better trip. The First Stone
## contest's rivals were scaled with the prices: hoshigane still beats them all.
func _worth(rules: Dictionary) -> void:
	var worth := func(d: int, s: String) -> float:
		var b: Dictionary = MineFloor.band(rules, d)
		var g := 0.0
		for src in ["rock", "big_rock", "soft"]:
			var n: Array = b.get({"rock": "rocks", "big_rock": "big_rocks", "soft": "soft"}[src])
			var w := MineFloor.odds(rules, d, s, src)
			var total := 0.0
			var value := 0.0
			for id in w:
				total += w[id]
				value += w[id] * (int(rules.items[id].sell) if rules.items.has(id) else 0)
			g += (float(n[0]) + float(n[1])) / 2.0 * value / total
		return g
	var deep: float = worth.call(15, "winter")
	check(deep <= 800.0, "a deep floor hides about %d G in winter, under 800 (1335 before FEEDBACK item 4)" % deep)
	check(deep > worth.call(10, "winter") and worth.call(10, "winter") > worth.call(5, "winter"), "deeper floors still hide more")
	var w: Dictionary = rules.winter
	var ice := 0.0
	var total := 0.0
	for id in w.finds:
		total += float(w.finds[id])
		ice += float(w.finds[id]) * (int(rules.items[id].sell) if rules.items.has(id) else 0)
	ice *= (float(w.ice[0]) + float(w.ice[1])) / 2.0 / total
	check(worth.call(int(w.to), "winter") + ice < deep, "a frozen floor with its ice (%d G) is still worth less than a deep one" % (worth.call(int(w.to), "winter") + ice))
	var top := 0
	for f in _json("res://data/festivals.json").festivals.values():
		if f.get("contest", {}).get("takes", "") == "mine":
			for r in f.contest.rivals:
				top = maxi(top, int(r.score[1]))
	check(top > 0 and int(rules.items.hoshigane.sell) > top, "hoshigane (%d G) beats every First Stone rival (top %d)" % [int(rules.items.hoshigane.sell), top])


## Bands per depth, season factors, deeper floors hold richer ore.
func _odds(rules: Dictionary) -> void:
	check(int(MineFloor.band(rules, 1).from) == 1 and int(MineFloor.band(rules, 3).from) == 1, "floors 1-3: the first band")
	check(int(MineFloor.band(rules, 4).from) == 4 and int(MineFloor.band(rules, 7).from) == 4, "floors 4-7: the second band")
	check(int(MineFloor.band(rules, 99).from) == int(rules.floors.back().from), "deep floors keep the last band")
	var fall := MineFloor.odds(rules, 10, "fall", "rock")
	var winter := MineFloor.odds(rules, 10, "winter", "rock")
	check(is_equal_approx(winter.suisho, fall.suisho * 2.0), "rock crystal twice as likely in winter")
	check(is_equal_approx(winter.kogane, fall.kogane), "other finds keep their weight")
	check(not MineFloor.odds(rules, 1, "spring", "rock").has("kogane") and MineFloor.odds(rules, 10, "spring", "rock").has("kogane"), "kogane ore only deeper down")
	check(MineFloor.odds(rules, 20, "spring", "big_rock").has("hoshigane") and not MineFloor.odds(rules, 5, "spring", "big_rock").has("hoshigane"), "hoshigane only in the deepest band")
	check(MineFloor.odds(rules, 1, "spring", "rock").has("none"), "a rock can hide nothing")
	for d in [1, 4, 8, 13, 40]:
		for s in ["spring", "summer", "fall", "winter"]:
			for src in ["rock", "big_rock", "soft"]:
				check(not MineFloor.odds(rules, d, s, src).is_empty(), "floor %d %s %s has finds" % [d, s, src])
	check(MineFloor.item_id("akagane") == "mine:akagane" and MineFloor.item_id("") == "" and MineFloor.item_id("stairs") == "", "find -> rucksack id")
	# Rolled finds follow the weights (a big sample; seeds 0..1999 on floor 1).
	var cave := MapManager.data(rules.floor_map)
	var counts := {}
	var rocks := 0
	for seed in 2000:
		var f := MineFloor.make(rules, cave, 1, "spring", seed)
		for c in f.rocks:
			if f.rocks[c].kind == "rock" and f.rocks[c].find != "stairs":
				rocks += 1
				counts[f.rocks[c].find] = int(counts.get(f.rocks[c].find, 0)) + 1
	var w: Dictionary = MineFloor.odds(rules, 1, "spring", "rock")
	var total := 0.0
	for k in w:
		total += w[k]
	var ok := true
	for k in w:
		var share := float(counts.get("" if k == "none" else k, 0)) / rocks
		ok = ok and absf(share - w[k] / total) < 0.02
	check(ok, "floor 1 rock finds follow the weights (%s of %d)" % [counts, rocks])


## The same seed lays out the same floor; rocks keep off walls, doors and the ladder; one hole down.
func _layout(rules: Dictionary) -> void:
	var cave := MapManager.data(rules.floor_map)
	var start: Vector2i = cave.spawns.start[0]
	var a := MineFloor.make(rules, cave, 5, "summer", 1234)
	var b := MineFloor.make(rules, cave, 5, "summer", 1234)
	var c := MineFloor.make(rules, cave, 5, "summer", 4321)
	check(a.rocks == b.rocks and a.soft == b.soft and a.stairs == b.stairs, "same seed, same floor")
	check(a.rocks != c.rocks or a.stairs != c.stairs, "another seed, another floor")
	check(a.depth == 5 and a.seed == 1234 and a.season == "summer" and not a.open, "floor keeps its depth, seed and season; the hole starts hidden")
	var under_soft := 0
	var bad := 0
	var n := 300
	for seed in n:
		for d in [1, 5, 9, 15]:
			var f := MineFloor.make(rules, cave, d, "fall", seed)
			var band := MineFloor.band(rules, d)
			var big := 0
			var small := 0
			for cell in f.rocks:
				if f.rocks[cell].kind == "big_rock":
					big += 1
				else:
					small += 1
				bad += int(f.rocks[cell].hits != int(band.hits[f.rocks[cell].kind]))
			bad += int(small < int(band.rocks[0]) or small > int(band.rocks[1]))
			bad += int(big < int(band.big_rocks[0]) or big > int(band.big_rocks[1]))
			bad += int(f.soft.size() < int(band.soft[0]) or f.soft.size() > int(band.soft[1]))
			for cell in f.rocks.keys() + f.soft.keys():
				bad += int(cave.is_solid(cell) or not cave.door_at(cell).is_empty())
				bad += int(absi(cell.x - start.x) <= int(rules.safe_radius) and absi(cell.y - start.y) <= int(rules.safe_radius))
				bad += int(f.rocks.has(cell) and f.soft.has(cell))
			var holes := 0
			for cell in f.rocks:
				holes += int(f.rocks[cell].find == "stairs")
			for cell in f.soft:
				holes += int(f.soft[cell] == "stairs")
			bad += int(holes != 1 or f.stairs == Vector2i(-1, -1))
			bad += int(absi(f.stairs.x - start.x) + absi(f.stairs.y - start.y) < int(rules.stairs.min_distance))
			under_soft += int(f.soft.has(f.stairs))
	check(bad == 0, "every floor keeps the rules (%d problems in %d floors)" % [bad, n * 4])
	var share := float(under_soft) / (n * 4)
	check(absf(share - float(rules.stairs.under_soft)) < 0.06, "the hole is under a soft spot on about %d%% of floors (%.2f)" % [int(float(rules.stairs.under_soft) * 100), share])


## Hammer blows, digging, the hole opening and becoming a door down.
func _break_and_dig(rules: Dictionary) -> void:
	var cave := MapManager.data(rules.floor_map)
	var f := MineFloor.make(rules, cave, 8, "spring", 77)
	var seen := [0]
	f.changed.connect(func(): seen[0] += 1)
	var rock := Vector2i(-1, -1)
	for cell in f.rocks:
		if f.rocks[cell].kind == "rock" and f.rocks[cell].find != "stairs":
			rock = cell
			break
	var hits: int = f.rocks[rock].hits
	check(hits == 2, "floor 8 rocks take 2 hits")
	check(f.is_solid(rock), "a rock blocks the way")
	f.rocks[rock].find = "kogane"
	check(f.hit(rock, 1) == {"result": "tough", "find": ""} and f.rocks.has(rock) and seen[0] == 0, "one blow: still standing")
	check(f.hit(rock, 1) == {"result": "broke", "find": "kogane"} and not f.rocks.has(rock) and seen[0] == 1, "the second breaks it, ore inside")
	check(not f.is_solid(rock), "a broken rock leaves open ground")
	check(f.hit(rock, 4).result == "none", "nothing left to hit")
	var big := MineFloor.make(rules, cave, 8, "spring", 77)
	for cell in big.rocks:
		if big.rocks[cell].kind == "big_rock":
			check(big.hit(cell, 5).result == "tough" and big.hit(cell, 1).result == "broke", "a big rock takes 6 hits on floor 8, in any blows")
			break
	# Soft ground and the hole.
	var spot := Vector2i(-1, -1)
	for cell in f.soft:
		if f.soft[cell] != "stairs":
			spot = cell
	f.soft[spot] = "clay"
	check(f.dig(spot) == {"result": "dug", "find": "clay"} and not f.soft.has(spot), "the hoe digs out a soft spot")
	check(f.dig(spot).result == "none" and f.dig(Vector2i(1, 7)).result == "none", "nothing to dig on hard floor")
	check(f.door_at(f.stairs).is_empty() and not f.is_solid(f.stairs) or f.rocks.has(f.stairs), "the hidden hole is no door")
	if f.rocks.has(f.stairs):
		f.rocks[f.stairs].done = 0
		check(f.hit(f.stairs, 9) == {"result": "broke", "find": "stairs"}, "the hole was under a rock")
	else:
		check(f.dig(f.stairs) == {"result": "dug", "find": "stairs"}, "the hole was under soft ground")
	check(f.open and f.is_solid(f.stairs), "the open hole is walked into like a door")
	var door := f.door_at(f.stairs)
	check(door.to == cave.id and door.spawn == cave.spawns.start[0] and door.get("down", false), "the hole leads to the next floor's ladder")
	check(f.door_at(f.stairs + Vector2i.RIGHT).is_empty(), "only the hole is a door")
	# Areas: walls and the map edge cut a charged hoe.
	var rows: Array = ["@", "#", "#", "#", "#", "#"]
	var cells := f.area_cells(Vector2i(8, 1), Vector2i.UP, rows)
	check(cells.is_empty(), "nothing to dig in the rock behind the ladder")
	cells = f.area_cells(Vector2i(8, 1), Vector2i.DOWN, rows)
	check(cells.size() == 2 and cells[0] == Vector2i(8, 2) and cells[1] == Vector2i(8, 3), "the hoe stops at the pillar (%s)" % [cells])
	# Finds left lying.
	f.leave(Vector2i(3, 3), "mine:stone")
	check(f.loose.get(Vector2i(3, 3)) == "mine:stone" and f.take(Vector2i(3, 3)) == "mine:stone" and f.take(Vector2i(3, 3)) == "", "a find left lying is picked up once")


## The ways in and out: village east edge -> entrance -> cave -> back up.
func _maps() -> void:
	var town := MapManager.data("town")
	var entrance := MapManager.data("mine")
	var cave := MapManager.data("mine_floor")
	var east := MapManager.data("sakurazaka")
	check(town.door_at(Vector2i(36, 10)).to == "sakurazaka" and east.door_at(Vector2i(30, 10)).to == "mine" and east.door_at(Vector2i(30, 11)).to == "mine",
		"the village road's east end leads through Sakurazaka to the mine")
	check(entrance.door_at(Vector2i(-1, 7)).to == "sakurazaka" and east.door_at(Vector2i(-1, 10)).to == "town", "the entrance leads back through Sakurazaka to the village")
	check(entrance.door_at(Vector2i(7, 2)).to == "mine_floor" and entrance.prop_at(Vector2i(8, 2)).kind == "cave_mouth", "the cave mouth goes down")
	check(cave.door_at(Vector2i(8, 0)).to == "mine" and cave.prop_at(Vector2i(8, 0)).kind == "ladder", "the ladder goes back up")
	check(not cave.indoor and cave.sheltered and cave.light != null, "down the mine: the clock runs, no weather, the cave's own light")
	check(MapManager.data("house").sheltered and not town.sheltered and not entrance.sheltered, "buildings are sheltered, outdoors isn't")
	check(cave.tile(Vector2i(0, 0)) == "rock_wall" and cave.is_solid(Vector2i(0, 0)) and cave.tile(Vector2i(8, 1)) == "cave", "rock walls and cave floor")


## Game: going down, deeper, back up; swings cost stamina and fatigue; finds go to the rucksack.
func _game_mine(rules: Dictionary) -> void:
	var g := _game(rules)
	var cave := MapManager.data("mine_floor")
	check(g.mine_deepest == 0 and g.maps.mine_floor == null, "a new game hasn't been down")
	g.use_door(MapManager.data("mine").door_at(Vector2i(7, 2)))
	check(g.maps.id == "mine_floor" and g.maps.mine_floor != null and g.maps.mine_floor.depth == 1, "the cave mouth leads to floor 1")
	check(g.mine_deepest == 1 and g.maps.mine_floor.season == "spring", "floor 1 reached, laid out for spring")
	check(not g.indoors() and g.sheltered(), "the clock runs in the mine, but no weather")
	var f: MineFloor = g.maps.mine_floor
	f.open = true
	check(g.maps.door_at(f.stairs).get("down", false) and g.maps.is_solid(f.stairs, g.farm), "the open hole is a door on the map")
	var seed1 := f.seed
	g.use_door(g.maps.door_at(f.stairs))
	check(g.maps.mine_floor.depth == 2 and g.mine_deepest == 2 and g.maps.mine_floor != f, "the hole leads to a fresh floor 2")
	check(g.maps.mine_floor.seed != seed1, "a new seed for every floor")
	var rocky: Vector2i = g.maps.mine_floor.rocks.keys()[0]
	check(g.maps.is_solid(rocky, g.farm) and not cave.is_solid(rocky), "rocks block the farmer")
	g.use_door(cave.door_at(Vector2i(8, 0)))
	check(g.maps.id == "mine" and g.maps.mine_floor == null and g.mine_deepest == 2, "the ladder goes straight back up; the deepest floor stays")
	g.use_door(MapManager.data("mine").door_at(Vector2i(7, 2)))
	check(g.maps.mine_floor.depth == 1 and g.mine_deepest == 2, "the next visit starts at floor 1 again")
	g.go_to_map("sakurazaka", Vector2i(28, 10), Vector2i.LEFT)
	check(g.maps.mine_floor == null, "no floor outside the mine")

	# A hammer swing on a rock: stamina by charge (data/tools.json), the find in the rucksack.
	g.use_door(MapManager.data("mine").door_at(Vector2i(7, 2)))
	f = g.maps.mine_floor
	var rock := _rock(f, "rock")
	f.rocks[rock].find = "akagane"
	var st: int = g.stamina
	var r: Dictionary = g.mine_swing("hammer", rock + Vector2i.UP, Vector2i.DOWN, 0)
	check(r.result == "swung" and r.worked and r.finds == [{"item": "mine:akagane", "to": "bag"}], "the rock breaks: akagane ore in the rucksack (%s)" % r)
	check(g.stamina == st - int(g.charge_rule("hammer", 0).stamina) and g.count("mine:akagane") == 1, "a hammer tap costs 2 stamina, like on the field")
	check(int(g.tool_exp.hammer) == int(g.tools_data.exp_per_swing.work), "the hammer learns from it")
	st = g.stamina
	r = g.mine_swing("hammer", rock + Vector2i.UP, Vector2i.DOWN, 1)
	check(r.result == "swung" and not r.worked and g.stamina == st - int(g.charge_rule("hammer", 1).stamina), "a swing at nothing still costs (a charged one more)")
	# Fatigue as for field work: rain adds to every swing.
	g.weather_today = "rain"
	var tired: int = g.fatigue
	g.mine_swing("hoe", Vector2i(8, 1), Vector2i.DOWN, 0)
	check(g.fatigue == tired + int(g.body.work.rain), "rain makes mine work tiring too")
	g.weather_today = "sunny"
	# A big rock needs several blows; tough says so.
	var big := _rock(f, "big_rock")
	if big.x < 0:   # floor 1 may have none: make one
		big = _rock(f, "rock")
		f.rocks[big].kind = "big_rock"
		f.rocks[big].hits = int(rules.floors[0].hits.big_rock)
	f.rocks[big].find = "meno"
	r = g.mine_swing("hammer", big + Vector2i.UP, Vector2i.DOWN, 0)
	check(r.tough and not r.worked and f.rocks.has(big), "a big rock is tough")
	var blows := 1
	while f.rocks.has(big) and blows < 20:
		r = g.mine_swing("hammer", big + Vector2i.UP, Vector2i.DOWN, 0)
		blows += 1
	check(blows == int(rules.floors[0].hits.big_rock) and g.count("mine:meno") == 1, "and breaks after %d taps, agate inside" % blows)
	# The hoe digs soft ground; a charged hoe works the whole line.
	var spot: Vector2i = f.soft.keys()[0]
	f.soft[spot] = "clay"
	r = g.mine_swing("hoe", spot + Vector2i.UP, Vector2i.DOWN, 0)
	check(r.worked and g.count("mine:clay") == 1, "the hoe digs up clay")
	# The hole: a swing that finds it says so.
	if f.rocks.has(f.stairs):
		f.rocks[f.stairs].done = 99
		r = g.mine_swing("hammer", f.stairs + Vector2i.UP, Vector2i.DOWN, 0)
	else:
		r = g.mine_swing("hoe", f.stairs + Vector2i.UP, Vector2i.DOWN, 0)
	check(r.hole and f.open, "the way down is found")
	# Wrong tools and full hands cost nothing.
	st = g.stamina
	check(g.mine_swing("sickle", Vector2i(8, 1), Vector2i.DOWN, 0).result == "wrong_tool" and g.stamina == st, "the sickle does nothing here")
	g.held = "turnip"
	check(g.mine_swing("hammer", Vector2i(8, 1), Vector2i.DOWN, 0).result == "hands_full" and g.stamina == st, "no swinging with an item overhead")
	g.held = ""
	# A full rucksack: the find goes up overhead, then it stays on the ground.
	var junk := 0
	while g.can_carry("mine:kogane"):
		g.add_item("food:onigiri" if junk % 2 == 0 else "seeds:turnip", 99)
		junk += 1
		if junk > 40:
			break
	check(not g.can_carry("mine:kogane"), "the rucksack is full")
	var two: Array[Vector2i] = []
	for cell in f.rocks:
		if f.rocks[cell].find != "stairs" and f.rocks.has(cell + Vector2i.DOWN) == false and f.rocks.size() > 0:
			two.append(cell)
	f.rocks[two[0]].find = "kogane"
	f.rocks[two[0]].done = 99
	r = g.mine_swing("hammer", two[0] + Vector2i.UP, Vector2i.DOWN, 0)
	check(r.finds == [{"item": "mine:kogane", "to": "hand"}] and g.held == "mine:kogane", "no room in the rucksack: up overhead")
	g.held = ""
	f.rocks[two[1]].find = "hisui"
	f.rocks[two[1]].done = 99
	g.held = "turnip"
	var left: String = g._keep_find("mine:hisui", two[1])
	check(left == "floor" and f.loose.get(two[1]) == "mine:hisui", "hands full too: it stays on the ground")
	g.held = ""
	check(g.mine_pick_up(two[1]) == "mine:hisui" and g.held == "mine:hisui" and not f.loose.has(two[1]), "E picks it up overhead")
	# Prices and names: shipped like crops, sold for the data's price.
	check(g.sell_price("mine:kogane") == int(rules.items.kogane.sell) and g.sell_price("mine:nothing") == 0, "mine finds have bin prices")
	check(g.item_name("mine:shirogane") == "Shirogane ore" and g.item_name("mine:suisho") == "Rock crystal", "and names")
	g.free()


## Only the deepest floor is saved; a save made down the mine loads at the cave mouth.
func _save(rules: Dictionary) -> void:
	var g := _game(rules)
	g.use_door(MapManager.data("mine").door_at(Vector2i(7, 2)))
	g.maps.mine_floor.open = true
	g.use_door(g.maps.door_at(g.maps.mine_floor.stairs))
	g.maps.mine_floor.open = true
	g.use_door(g.maps.door_at(g.maps.mine_floor.stairs))
	check(g.mine_deepest == 3, "three floors down")
	var d: Dictionary = g.to_dict()
	check(d.mine == {"deepest": 3, "landings": []}, "the deepest floor is saved (no landing yet)")
	var spot: Array = MapManager.data(rules.entrance_map).spawns[rules.entrance_spawn]
	check(d.map.id == "mine" and Vector2(d.map.x, d.map.y) == MapManager.cell_pos(spot[0]), "a save down the mine puts the farmer at the cave mouth")
	check(not JSON.stringify(d).contains("rocks"), "no floor layout in the save")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(d))
	var h := _game(rules)
	check(h.from_dict(saved) == "" and h.mine_deepest == 3 and h.maps.id == "mine" and h.maps.mine_floor == null, "loads: deepest 3, at the entrance")
	var old: Dictionary = saved.duplicate(true)
	old.erase("mine")
	check(h.from_dict(old) == "" and h.mine_deepest == 0, "a save from before the mine: nothing reached")
	var odd: Dictionary = saved.duplicate(true)
	odd.map = {"id": "mine_floor", "x": 136, "y": 26, "facing": [0, 1]}
	check(h.from_dict(odd) == "" and h.maps.id == "mine", "a save that says mine floor loads at the entrance")
	for bad in [{"deepest": -1}, {"deepest": "x"}, {}, "x", {"deepest": 1.5}]:
		var broken: Dictionary = saved.duplicate(true)
		broken.mine = bad
		check(h.from_dict(broken) != "", "refused mine %s" % JSON.stringify(bad))
	g.new_game()
	check(g.mine_deepest == 0 and g.maps.mine_floor == null, "a new game forgets the mine")
	g.free()
	h.free()


## Rocks, soft spots, the hole, cave ground and an icon for every find, all different.
func _art(rules: Dictionary) -> void:
	var magenta := PlaceholderArt.tex("unknown:x").get_image().get_data()
	var sizes := {"mine:rock": Vector2i(16, 16), "mine:big_rock": Vector2i(24, 20), "mine:soft": Vector2i(16, 16), "mine:hole": Vector2i(16, 16),
		"mine:ice": Vector2i(16, 16), "mine:frost": Vector2i(16, 16), "mine:lantern": Vector2i(7, 11),
		"mine:landing": Vector2i(16, 26), "story:rope_lift": Vector2i(20, 28)}
	for key in sizes:
		var img := PlaceholderArt.tex(key).get_image()
		check(img.get_size() == sizes[key] and img.get_data() != magenta, "%s drawn" % key)
	var ice := PlaceholderArt.tex("mine:ice").get_image()
	check(ice.get_pixel(9, 10).get_luminance() < ice.get_pixel(5, 10).get_luminance() * 0.6, "the frost stone shows dark inside the ice")
	var frost := PlaceholderArt.tex("mine:frost").get_image()
	var clear := 0
	for y in 16:
		for x in 16:
			clear += int(frost.get_pixel(x, y).a < 0.5)
	check(clear >= 200, "frost is mostly see-through (%d of 256 px)" % clear)
	var lamp := PlaceholderArt.tex("mine:lantern").get_image()
	check(lamp.get_pixel(3, 6).get_luminance() > 0.85 and lamp.get_pixel(3, 6).r > lamp.get_pixel(3, 6).b, "the lantern's flame is bright and warm")
	var hangs := true
	for pose in ["idle", "walk", "run", "tired_idle", "tired_walk", "hold_idle", "hold_walk", "fish_wait"]:
		for fr in PlaceholderArt.farmer_frames(pose):
			var at := PlaceholderArt.lantern_at(pose, fr)
			hangs = hangs and at.x >= -1 and at.x + 7 <= 16 and at.y >= 10 and at.y + 11 <= 28
	check(hangs, "the lantern hangs on the farmer's frame in every pose")
	check(PlaceholderArt.lantern_at("walk", 0) != PlaceholderArt.lantern_at("walk", 2), "the lantern swings with the hand")
	for kind in ["cave", "rock_wall", "scree"]:
		var img := PlaceholderArt.tex("ground:%s:0" % kind).get_image()
		check(img.get_size() == Vector2i(16, 16) and img.get_pixel(8, 8).a == 1.0 and img.get_data() != magenta, "ground %s" % kind)
	var seen := {}
	for id in rules.items:
		var key := PlaceholderArt.item_key("mine:" + id)
		check(key == "ui:mine:" + id and PlaceholderArt.world_item_key("mine:" + id) == key, "%s icon key" % id)
		var img := PlaceholderArt.tex(key).get_image()
		var solid := 0
		for y in img.get_height():
			for x in img.get_width():
				solid += int(img.get_pixel(x, y).a > 0.0)
		check(img.get_size() == Vector2i(14, 14) and solid >= 25, "%s icon (%d px)" % [id, solid])
		seen[img.get_data()] = id
	check(seen.size() == rules.items.size(), "every find looks different")


## Darker deeper: the light blends between its depths and holds below the last; the lantern
## is brighter than any floor; the shader and its aim.
func _light(rules: Dictionary) -> void:
	var stops: Array = rules.light.depths
	check(stops.size() >= 2 and int(stops[0][0]) == 1, "light depths start at floor 1")
	check(MineFloor.light_at(rules, 1).is_equal_approx(Color(str(stops[0][1]))), "floor 1 has the first light")
	var a: Array = stops[0]
	var b: Array = stops[1]
	var mid := (int(a[0]) + int(b[0])) / 2
	var want := Color(str(a[1])).lerp(Color(str(b[1])), float(mid - int(a[0])) / float(int(b[0]) - int(a[0])))
	check(MineFloor.light_at(rules, mid).is_equal_approx(want), "floor %d is blended between the first two" % mid)
	check(MineFloor.light_at(rules, 99).is_equal_approx(Color(str(stops.back()[1]))), "deep floors keep the last light")
	var darker := true
	for d in range(2, 40):
		darker = darker and MineFloor.light_at(rules, d).get_luminance() <= MineFloor.light_at(rules, d - 1).get_luminance() + 0.0001
	check(darker, "no floor is lighter than the one above")
	check(MineFloor.light_at(rules, 20).get_luminance() < MineFloor.light_at(rules, 1).get_luminance() * 0.4, "deep floors are much darker")
	var f := MineFloor.make(rules, MapManager.data(rules.floor_map), 12, "summer", 5)
	check(f.light.is_equal_approx(MineFloor.light_at(rules, 12)) and not f.frozen and f.frost.is_empty(), "a floor keeps its light; summer isn't frozen")
	var lantern: Color = f.lantern.color
	check(float(f.lantern.radius) >= 2.0 and lantern.get_luminance() > MineFloor.light_at(rules, 1).get_luminance(),
		"the lantern reaches %s cells and outshines every floor" % f.lantern.radius)
	var m := MineLight.material()
	check(m.shader != null and m.shader.code.contains("blend_mul"), "the light multiplies the picture")
	MineLight.aim(m, f, Vector2(240, 135), 20.0, Vector2(480, 270))
	check(is_equal_approx(m.get_shader_parameter("radius"), float(f.lantern.radius) * 20.0) and m.get_shader_parameter("center") == Vector2(240, 135),
		"the lantern is aimed at the farmer, in screen pixels")
	check(m.shader.code.contains("BAYER") and not m.shader.code.contains("ceil(k * 4.0)"), "the lantern's edge is dithered, not cut into rings")
	check(m.shader.code.contains("TIME") and is_zero_approx(m.get_shader_parameter("cold")), "the lantern flickers; a warm floor has no ice glints")
	MineLight.aim(m, MineFloor.make(rules, MapManager.data(rules.floor_map), 2, "winter", 5), Vector2(240, 135), 20.0, Vector2(480, 270))
	check(is_equal_approx(m.get_shader_parameter("cold"), 1.0), "a frozen floor's dark glints with ice")


## Winter: floors down to `to` are frozen (ice blocks with their own finds, frost, a cold light);
## deeper floors and other seasons are not. The hole is never under the ice.
func _winter(rules: Dictionary) -> void:
	var w: Dictionary = rules.winter
	var to := int(w.to)
	check(MineFloor.is_frozen(rules, 1, "winter") and MineFloor.is_frozen(rules, to, "winter"), "winter floors 1-%d are frozen" % to)
	check(not MineFloor.is_frozen(rules, to + 1, "winter") and not MineFloor.is_frozen(rules, 1, "fall"), "deeper, or in fall, they aren't")
	for id in w.finds:
		check(id == "none" or rules.items.has(id), "winter find %s is an item" % id)
	check(rules.items.has("hyoseki") and w.finds.has("hyoseki"), "frost stone grows in the ice")
	for band in rules.floors:
		for src in band.finds:
			check(not band.finds[src].has("hyoseki"), "frost stone only comes from ice (band %d %s)" % [band.from, src])
	var warm := MineFloor.light_at(rules, 3, "fall")
	var cold := MineFloor.light_at(rules, 3, "winter")
	check(cold.b / maxf(cold.r, 0.001) > warm.b / maxf(warm.r, 0.001) and cold.is_equal_approx(warm * Color(str(w.light))), "a frozen floor's light is colder")
	check(MineFloor.light_at(rules, to + 1, "winter").is_equal_approx(MineFloor.light_at(rules, to + 1, "fall")), "deeper floors keep their light in winter")
	var cave := MapManager.data(rules.floor_map)
	var start: Vector2i = cave.spawns.start[0]
	var bad := 0
	var finds := {}
	var frost_share := 0.0
	var n := 200
	for seed in n:
		var f := MineFloor.make(rules, cave, 1 + seed % to, "winter", seed)
		bad += int(not f.frozen)
		var ice := 0
		for c in f.rocks:
			if f.rocks[c].kind == "ice":
				ice += 1
				bad += int(f.rocks[c].hits != int(w.hits) or f.rocks[c].find == "stairs" or c == f.stairs)
				finds[f.rocks[c].find] = int(finds.get(f.rocks[c].find, 0)) + 1
		bad += int(ice < int(w.ice[0]) or ice > int(w.ice[1]))
		bad += int(f.stairs == Vector2i(-1, -1))
		var open := 0
		for c in f.frost:
			bad += int(f.rocks.has(c) or f.soft.has(c) or cave.is_solid(c) or not cave.door_at(c).is_empty())
			bad += int(absi(c.x - start.x) <= int(rules.safe_radius) and absi(c.y - start.y) <= int(rules.safe_radius))
		for y in cave.h:
			for x in cave.w:
				var c := Vector2i(x, y)
				open += int(not cave.is_solid(c) and not f.rocks.has(c) and not f.soft.has(c))
		frost_share += float(f.frost.size()) / maxf(open, 1.0)
	check(bad == 0, "frozen floors keep the rules (%d problems in %d floors)" % [bad, n])
	check(finds.has("hyoseki") and finds.has("") and int(finds.hyoseki) > int(finds.get("suisho", 0)), "ice hides frost stone most often (%s)" % [finds])
	check(absf(frost_share / n - float(w.frost)) < 0.08, "about %d%% of the open floor is frosty (%.2f)" % [int(float(w.frost) * 100), frost_share / n])
	var deep := MineFloor.make(rules, cave, to + 3, "winter", 9)
	var none := true
	for c in deep.rocks:
		none = none and deep.rocks[c].kind != "ice"
	check(none and deep.frost.is_empty() and not deep.frozen, "a warm deep floor in winter has no ice or frost")
	var f := MineFloor.make(rules, cave, 2, "winter", 3)
	var block := _rock(f, "ice")
	check(block.x >= 0 and f.is_solid(block), "ice blocks the way")
	f.rocks[block].find = "hyoseki"
	var blows := 0
	var r := {}
	while f.rocks.has(block) and blows < 10:
		r = f.hit(block, 1)
		blows += 1
	check(blows == int(w.hits) and r == {"result": "broke", "find": "hyoseki"}, "ice breaks in %d blows, frost stone inside" % blows)


## Game in winter: down the cave mouth to a frozen floor 1, its message, the hammer on ice.
func _game_winter(rules: Dictionary) -> void:
	var g := _game(rules)
	g.season = 3
	var said := []
	g.message.connect(func(t): said.append(t))
	g.use_door(MapManager.data("mine").door_at(Vector2i(7, 2)))
	var f: MineFloor = g.maps.mine_floor
	check(f.season == "winter" and f.frozen and not f.frost.is_empty(), "winter: floor 1 is frozen")
	g.map_arrived()
	check(not said.is_empty() and said.back() == "Mine floor 1, frozen", "it says so: %s" % [said])
	var block := _rock(f, "ice")
	f.rocks[block].find = "hyoseki"
	f.rocks[block].done = int(rules.winter.hits) - 1
	var res: Dictionary = g.mine_swing("hammer", block + Vector2i.UP, Vector2i.DOWN, 0)
	check(res.worked and res.finds == [{"item": "mine:hyoseki", "to": "bag"}] and g.count("mine:hyoseki") == 1, "the hammer breaks ice: %s" % res)
	check(g.item_name("mine:hyoseki") == "Frost stone" and g.sell_price("mine:hyoseki") == int(rules.items.hyoseki.sell), "frost stone's name and price")
	g.season = 0
	g.use_door(MapManager.data("mine_floor").door_at(Vector2i(8, 0)))
	g.use_door(MapManager.data("mine").door_at(Vector2i(7, 2)))
	check(not g.maps.mine_floor.frozen, "spring: the cave has thawed")
	g.free()


## The rope lift landings in data/mine.json: every fifth floor down to 15; the lift stands by
## the ladder inside its safe square, so a landing floor's layout is the same as without it.
func _landings(rules: Dictionary) -> void:
	var land: Dictionary = rules.landings
	check(MineFloor.landings(rules) == [5, 10, 15], "landings at floors 5, 10 and 15")
	check(MineFloor.is_landing(rules, 10) and not MineFloor.is_landing(rules, 1) and not MineFloor.is_landing(rules, 20), "floor 10 is one, 1 and 20 aren't")
	var cave := MapManager.data(rules.floor_map)
	var lift := Vector2i(int(land.cell[0]), int(land.cell[1]))
	var start: Vector2i = cave.spawns.start[0]
	check(not cave.is_solid(lift) and cave.door_at(lift).is_empty(), "the lift stands on open cave floor")
	check(absi(lift.x - start.x) <= int(rules.safe_radius) and absi(lift.y - start.y) <= int(rules.safe_radius), "inside the ladder's safe square")
	for t in ["found", "ask", "ladder", "ride"]:
		check(land.get(t) is String and land[t] != "", "landing text %s" % t)
	check(TextBoxLayout.wrap_rows(land.ask, TextBoxLayout.TEXT_W).size() <= TextBoxLayout.ROWS, "the question fits in the text box")
	var f := MineFloor.make(rules, cave, 10, "spring", 99)
	check(f.landing and f.lift == lift and f.is_solid(lift), "floor 10: the rope lift stands there and blocks the way")
	check(not f.rocks.has(lift) and not f.soft.has(lift) and f.stairs != lift, "nothing laid on the lift's cell")
	var plain := MineFloor.make(rules, cave, 11, "spring", 99)
	check(not plain.landing and not plain.is_solid(lift), "floor 11 has no lift")
	var no_lift := rules.duplicate(true)
	no_lift.erase("landings")
	var same := MineFloor.make(no_lift, cave, 10, "spring", 99)
	check(same.rocks.keys() == f.rocks.keys() and same.soft == f.soft and same.stairs == f.stairs, "the lift doesn't change the floor's layout")


## Game: reaching a landing keeps it and shows the winch; the cave mouth then asks how far down
## and the lift starts the trip at a landing; the deepest floor counts only what was walked.
func _landing_game(rules: Dictionary) -> void:
	var g := _game(rules)
	var mouth := MapManager.data("mine").door_at(Vector2i(7, 2))
	check(g.mine_landings.is_empty() and g.mine_start_floors() == [1], "a new game: only the ladder")
	check(not g.mine_go_down(5) and g.maps.id != "mine_floor", "no lift to a landing not reached")
	g.use_door(mouth)
	check(g.maps.mine_floor.depth == 1 and not g.dialogue_made.has(g.MINE_LIFT_DIALOGUE), "no landing yet: the cave mouth goes straight to floor 1")
	for i in 4:   # down to floor 5
		g.maps.mine_floor.open = true
		g.use_door(g.maps.door_at(g.maps.mine_floor.stairs))
	check(g.maps.mine_floor.depth == 5 and g.maps.mine_floor.landing, "floor 5 is a landing")
	check(g.mine_landings == [5] and g.flags.get(rules.landings.flag) == true, "landing 5 kept, the winch's flag set")
	check(g.mine_news.contains("5"), "the news waits for the arrival")
	g.map_arrived()
	check(g.mine_news == "", "and is said once")
	check(MapManager.data("mine").prop_at(Vector2i(9, 3)).get("kind", "") == "rope_lift", "the winch shows at the cave mouth")
	g.go_to_map("mine", Vector2i(7, 3), Vector2i.DOWN)
	check(g.mine_start_floors() == [1, 5], "the ladder or the lift to 5")
	g.use_door(mouth)
	check(g.maps.id == "mine" and g.dialogue_made.has(g.MINE_LIFT_DIALOGUE), "now the cave mouth asks first")
	var r := DialogueRunner.new(g.dialogue_made[g.MINE_LIFT_DIALOGUE], DialogueRunner.speakers(), g.flags, DialogueRunner.settings())
	check(r.error == "", "the question is a dialogue that runs (%s)" % r.error)
	r.set_speed(0)
	check(r.choices().size() == 2 and str(r.choices()[1].text).contains("5"), "two choices: the ladder, the lift to 5")
	r.pick(1)
	check(r.done() and g.flags.get(g.MINE_START_FLAG) == 5, "picking the lift sets the floor")
	g.dialogue_closed(g.MINE_LIFT_DIALOGUE)
	check(g.maps.id == "mine_floor" and g.maps.mine_floor.depth == 5 and not g.flags.has(g.MINE_START_FLAG), "the lift goes down to floor 5; the pick is forgotten")
	check(g.mine_deepest == 5, "the deepest floor stays what was walked")
	g.maps.mine_floor.open = true
	g.use_door(g.maps.door_at(g.maps.mine_floor.stairs))
	check(g.maps.mine_floor.depth == 6 and g.mine_deepest == 6, "and on down from there")
	g.go_to_map("mine", Vector2i(7, 3), Vector2i.DOWN)
	g.use_door(mouth)
	r = DialogueRunner.new(g.dialogue_made[g.MINE_LIFT_DIALOGUE], DialogueRunner.speakers(), g.flags, DialogueRunner.settings())
	r.set_speed(0)
	r.pick(0)
	g.dialogue_closed(g.MINE_LIFT_DIALOGUE)
	check(g.maps.mine_floor.depth == 1 and g.mine_deepest == 6, "the ladder still starts at floor 1")
	g.go_to_map("mine", Vector2i(7, 3), Vector2i.DOWN)
	g.dialogue_closed("bin_note")
	check(g.maps.id == "mine", "another text box closing goes nowhere")
	g.mine_landings.assign([5, 10, 15])
	check(g.mine_start_floors() == [1, 5, 10, 15], "four choices with every landing")
	g.mine_landings.assign([5, 10, 15, 20])
	check(g.mine_start_floors() == [1, 10, 15, 20], "never more than four: the deepest three landings")
	g.free()


## Saved as mine.landings (save version 6); older saves get every landing down to the deepest
## floor (every trip began at floor 1, so they were walked through); bad lists are refused.
func _landing_save(rules: Dictionary) -> void:
	check(SaveGame.VERSION == 6, "save version 6")
	var g := _game(rules)
	g.mine_deepest = 12
	g.mine_landings.assign([5, 10])
	var saved: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	check(saved.mine.landings == [5.0, 10.0], "the landings are saved")
	var h := _game(rules)
	check(h.from_dict(saved) == "" and h.mine_landings == [5, 10] and h.mine_deepest == 12, "and load")
	var old: Dictionary = saved.duplicate(true)
	old.mine = {"deepest": 17}
	old.flags.erase(rules.landings.flag)
	check(h.from_dict(old, 5) == "" and h.mine_landings == [5, 10, 15] and h.flags.get(rules.landings.flag) == true,
		"a version 5 save at floor 17: landings 5, 10, 15 and the winch")
	old.mine = {"deepest": 4}
	check(h.from_dict(old, 5) == "" and h.mine_landings.is_empty() and not h.flags.has(rules.landings.flag), "one at floor 4: none")
	check(h.from_dict(old, 6) != "", "a version 6 save must have its landings")
	for bad in [[7], [15], ["x"], [5.5], "x", [0]]:
		var broken: Dictionary = saved.duplicate(true)
		broken.mine.landings = bad
		check(h.from_dict(broken) != "", "refused landings %s (deepest 12)" % JSON.stringify(bad))
	g.new_game()
	check(g.mine_landings.is_empty() and g.mine_start_floors() == [1], "a new game forgets the landings")
	g.free()
	h.free()


func _rock(f: MineFloor, kind: String) -> Vector2i:
	for cell in f.rocks:
		if f.rocks[cell].kind == kind and f.rocks[cell].find != "stairs" and not f.rocks.has(cell + Vector2i.UP):
			return cell
	return Vector2i(-1, -1)


func _game(rules: Dictionary) -> Node:
	var g: Node = (load("res://scripts/autoload/game.gd") as GDScript).new()
	g.crops = _json("res://data/crops.json")
	g.tools_data = _json("res://data/tools.json")
	g.snow_rules = _json("res://data/snow_cover.json")
	g.body = _json("res://data/body.json")
	g.hold_rules = _json("res://data/hold.json")
	g.set_food_data(_json("res://data/foods.json"))
	g.fish_data = _json("res://data/fish.json")
	g.mine_data = rules
	g.rng.seed = 7
	g.new_game()
	return g


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
