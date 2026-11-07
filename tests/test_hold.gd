extends SceneTree
## Headless checks for holding and throwing items (FarmGrid items / throw_target, Game.pick_up /
## put_down / throw_held, data/hold.json, the holding poses and item art). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_hold.gd

var failures := 0


func _init() -> void:
	var rules: Dictionary = _json("res://data/hold.json")
	check(int(rules.throw_cells) >= 1 and float(rules.flight_seconds) > 0.0, "hold rules read")
	check("bin" in rules.ship_into and "pond" in rules.lost_in, "the bin ships, the pond swallows")

	# Items on the ground: only on empty farm cells, one per cell; they block till and sow.
	var g := _game()
	var f: FarmGrid = g.farm
	_clear(f)
	var c := Vector2i(12, 10)
	check(f.can_place(c) and f.place_item(c, "turnip") and f.item_at(c) == "turnip", "item put on an empty cell")
	check(not f.place_item(c, "potato"), "one item per cell")
	check(not f.is_solid(c), "items don't block walking")
	check(not f.till(c), "can't till under an item")
	check(not f.place_item(Vector2i(8, 3), "turnip") and not f.place_item(Vector2i(0, 5), "turnip"), "not on the bin or the fence")
	f.cell(Vector2i(13, 10)).obj = FarmGrid.Obj.ROCK
	check(not f.place_item(Vector2i(13, 10), "turnip"), "not on a rock")
	f.cell(Vector2i(13, 10)).obj = FarmGrid.Obj.NONE
	for x in range(10, 15):
		f.till(Vector2i(x, 11))
	f.place_item(Vector2i(11, 11), "corn")
	check(f.sow(Vector2i(11, 12), "turnip", "spring") == 2, "sowing skips the cell with an item")
	check(f.cell(Vector2i(11, 11)).crop == "" and not f.place_item(Vector2i(10, 11), "corn"), "no seed under the item, no item on a crop")
	check(f.take_item_at(c) == "turnip" and f.item_at(c) == "" and f.take_item_at(c) == "", "item taken up once")

	# Where a throw ends up.
	var ship: Array = rules.ship_into
	var lost: Array = rules.lost_in
	var reach := int(rules.throw_cells)
	var t := f.throw_target(Vector2i(12, 8), Vector2i.DOWN, 2, ship, lost)
	check(t.result == "land" and t.cell == Vector2i(12, 10), "lands two cells ahead %s" % t)
	f.place_item(Vector2i(12, 10), "corn")
	t = f.throw_target(Vector2i(12, 8), Vector2i.DOWN, 2, ship, lost)
	check(t.result == "land" and t.cell == Vector2i(12, 9), "an item on the spot: lands short %s" % t)
	f.cell(Vector2i(12, 9)).obj = FarmGrid.Obj.ROCK
	t = f.throw_target(Vector2i(12, 8), Vector2i.DOWN, 2, ship, lost)
	check(t.result == "blocked", "a rock right ahead: no throw %s" % t)
	f.cell(Vector2i(12, 9)).obj = FarmGrid.Obj.NONE
	f.take_item_at(Vector2i(12, 10))
	t = f.throw_target(Vector2i(12, 9), Vector2i.DOWN, 2, ship, lost)
	check(t.result == "land" and t.cell == Vector2i(12, 10), "doesn't land on the crop beyond %s" % t)
	for y in range(10, 13):
		for x in range(15, 18):
			f.till(Vector2i(x, y))
	check(f.sow(Vector2i(16, 11), "turnip", "spring") == 9, "crops on 15..17 x 10..12")
	t = f.throw_target(Vector2i(14, 11), Vector2i.RIGHT, 2, ship, lost)
	check(t.result == "blocked", "can't land on crops %s" % t)
	t = f.throw_target(Vector2i(14, 11), Vector2i.RIGHT, 4, ship, lost)
	check(t.result == "land" and t.cell == Vector2i(18, 11), "a long throw flies over the crops %s" % t)
	t = f.throw_target(Vector2i(8, 5), Vector2i.UP, 2, ship, lost)
	check(t.result == "ship" and t.cell == Vector2i(8, 3), "two cells from the bin: shipped %s" % t)
	t = f.throw_target(Vector2i(8, 5), Vector2i.UP, 2, [], lost)
	check(t.result == "land" and t.cell == Vector2i(8, 4), "an item the bin won't take drops in front %s" % t)
	t = f.throw_target(Vector2i(26, 6), Vector2i.UP, 2, ship, lost)
	check(t.result == "lost" and t.cell == Vector2i(26, 4), "into the pond %s" % t)
	t = f.throw_target(Vector2i(3, 5), Vector2i.UP, 2, ship, lost)
	check(t.result == "land" and t.cell == Vector2i(3, 4), "the house stops it %s" % t)
	t = f.throw_target(Vector2i(2, 10), Vector2i.LEFT, 2, ship, lost)
	check(t.result == "land" and t.cell == Vector2i(1, 10), "the fence stops it inside the field %s" % t)
	t = f.throw_target(Vector2i(1, 10), Vector2i.LEFT, 2, ship, lost)
	check(t.result == "blocked", "against the fence: no throw %s" % t)
	check(reach == 2, "throw reach is 2 cells (data)")

	# Game: pick up, put down, throw.
	g.free()
	g = _game()
	f = g.farm
	_clear(f)
	check(g.held == "" and not g.holding() and g.shipped == {}, "new game: hands free, nothing shipped")
	f.place_item(Vector2i(8, 6), "potato")
	check(g.pick_up(Vector2i(8, 6)) == "potato" and g.held == "potato" and f.item_at(Vector2i(8, 6)) == "", "picked up from the ground")
	f.place_item(Vector2i(9, 6), "corn")
	check(g.pick_up(Vector2i(9, 6)) == "" and f.item_at(Vector2i(9, 6)) == "corn", "hands full: can't pick up more")
	check(not g.put_down(Vector2i(9, 6)) and g.held == "potato", "can't put down on another item")
	check(not g.put_down(Vector2i(8, 3)) and g.held == "potato", "can't put down on the bin")
	check(g.put_down(Vector2i(8, 7)) and g.held == "" and f.item_at(Vector2i(8, 7)) == "potato", "put down")
	check(not g.put_down(Vector2i(8, 8)), "nothing to put down")
	# A ripe crop is harvested straight into the hand (not the bag).
	var k := Vector2i(14, 14)
	f.till(k)
	f.sow(k, "cucumber", "spring")
	f.cell(k).stage = f.ripe_stage("cucumber")
	check(g.pick_up(k) == "cucumber" and g.held == "cucumber" and g.inventory.count("cucumber", ["bag"]) == 0, "ripe crop goes overhead")
	check(f.cell(k).crop == "cucumber" and f.cell(k).stage < f.ripe_stage("cucumber"), "the vine regrows")
	check(g.pick_up(Vector2i(14, 15)) == "", "hands full: no second harvest")
	# Throwing into the bin ships at the crop's price, paid with the rest of the bin.
	var events := []
	g.thrown.connect(func(item, from, to, result): events.append([item, from, to, result]))
	var price := int(g.crops.cucumber.sell)
	g.bin_total = 100
	t = g.throw_held(Vector2i(8, 5), Vector2i.UP)
	check(t.result == "ship" and t.value == price and g.bin_total == 100 + price, "shipped: price into the bin %s" % t)
	check(g.held == "" and g.shipped == {"cucumber": 1}, "hands free, shipping counted")
	check(events == [["cucumber", Vector2i(8, 5), Vector2i(8, 3), "ship"]], "thrown signal for the view %s" % [events])
	var money: int = g.money
	g.pay_bin()
	check(g.money == money + 100 + price and g.bin_total == 0, "paid out like the bin")
	check(g.throw_held(Vector2i(8, 5), Vector2i.UP).result == "none", "nothing to throw")
	# Into the pond: gone. Against a wall: stays in hand. Otherwise lands on the field.
	g.held = "turnip"
	t = g.throw_held(Vector2i(26, 6), Vector2i.UP)
	check(t.result == "lost" and g.held == "" and g.bin_total == 0 and f.item_at(Vector2i(26, 4)) == "", "sank in the pond")
	g.held = "turnip"
	t = g.throw_held(Vector2i(1, 10), Vector2i.LEFT)
	check(t.result == "blocked" and g.held == "turnip" and events.size() == 2, "blocked: still held, no flight")
	t = g.throw_held(Vector2i(12, 8), Vector2i.DOWN)
	check(t.result == "land" and f.item_at(Vector2i(12, 10)) == "turnip" and g.held == "", "landed on the field")
	check(g.pick_up(Vector2i(12, 10)) == "turnip", "and can be picked up again")
	# Something without a price bounces off the bin.
	g.held = "stone"
	t = g.throw_held(Vector2i(8, 5), Vector2i.UP)
	check(t.result == "land" and t.cell == Vector2i(8, 4) and g.shipped.get("stone", 0) == 0, "the bin won't take an item without a price")
	# The bag route counts shipping too.
	g.bag = {"turnip": 3}
	g.ship_produce()
	check(g.shipped.turnip == 3, "shipping from the bag is counted")
	# The held item is the rucksack's hand slot: a stack there goes up one throw at a time.
	g.held = ""
	g.inventory.add("turnip", 2, ["hand"])
	t = g.throw_held(Vector2i(16, 12), Vector2i.DOWN)
	check(t.result != "blocked" and g.held == "turnip" and g.inventory.count("turnip", ["hand"]) == 1, "a stack in the hand throws one at a time %s" % t)
	g.held = "potato"
	g.new_game()
	check(g.held == "" and g.shipped == {} and g.farm.items.is_empty(), "new game: hands and ground empty")

	# Holding poses and item art.
	var a := FarmerAnim.new()
	a.step(0.1, false, false, false, true)
	check(a.key(Vector2i.DOWN) == "player:front:hold_idle:0", "hold idle frame")
	a.step(0.1, true, false, true, true)
	check(a.pose == "hold_walk" and a.frame() == 1, "holding wins over tired")
	var t0 := a.time
	a.step(0.0, true, true, false, true)
	check(a.pose == "hold_walk" and a._fps() == FarmerAnim.RUN_FPS and a.time == t0, "running with a load steps faster")
	a.step(0.1, false, false, false, false)
	check(a.pose == "idle", "hands free: back to idle")
	for pose in ["hold_idle", "hold_walk"]:
		for back in ["front", "back"]:
			for i in PlaceholderArt.farmer_frames(pose):
				var img := PlaceholderArt.tex("player:%s:%s:%d" % [back, pose, i]).get_image()
				var hand: Vector2i = FigureArt.hands(FigureArt.FARMER_LOOK, back == "back", pose, i).near
				check(img.get_size() == PlaceholderArt.FIGURE_SIZE and img.get_pixelv(hand).a > 0.0
					and PlaceholderArt.hold_row(pose, i) <= FigureArt.head_top(FigureArt.FARMER_LOOK) + PlaceholderArt.farmer_drop(pose, i),
					"%s %s %d: 24 x 32, hands up at the top of the head" % [back, pose, i])
	check(PlaceholderArt.tex("player:front:hold_idle:0").get_image().get_data() != PlaceholderArt.tex("player:front:idle:0").get_image().get_data(), "hold idle looks different")
	check(PlaceholderArt.farmer_drop("hold_walk", 0) == 1 and PlaceholderArt.farmer_drop("hold_walk", 1) == 0, "the load bobs")
	var seen := {}
	for id in g.crops:
		var img := PlaceholderArt.tex(PlaceholderArt.world_item_key(id)).get_image()
		var solid := 0
		for y in img.get_height():
			for x in img.get_width():
				solid += int(img.get_pixel(x, y).a > 0.0)
		check(img.get_size() == Vector2i(12, 12) and solid >= 20, "item art for %s (%d px)" % [id, solid])
		seen[img.get_data()] = id
	check(seen.size() == g.crops.size(), "every crop's item looks different")

	# Weeds never grow under an item (300 spring nights on a fresh field).
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	f = g.farm
	_clear(f)
	var lying := Vector2i(20, 15)
	f.place_item(lying, "potato")
	for i in 300:
		f.day_end("spring", "sunny", rng)
	check(f.cell(lying).obj == FarmGrid.Obj.NONE and f.item_at(lying) == "potato", "no weed under an item, it stays overnight")

	g.free()
	print("test_hold: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


## A field with no debris, so cells are free unless a check puts something there.
func _clear(f: FarmGrid) -> void:
	for d in f.cells:
		d.obj = FarmGrid.Obj.NONE


func _game() -> Node:
	var g: Node = (load("res://scripts/autoload/game.gd") as GDScript).new()
	g.crops = _json("res://data/crops.json")
	g.tools_data = _json("res://data/tools.json")
	g.snow_rules = _json("res://data/snow_cover.json")
	g.body = _json("res://data/body.json")
	g.hold_rules = _json("res://data/hold.json")
	g.rng.seed = 3
	g.new_game()
	return g


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
