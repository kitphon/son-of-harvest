extends SceneTree
## Headless rule checks for FarmGrid. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_farm.gd

var failures := 0


func _init() -> void:
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1

	# Turnip: stages 1 + 2 watered days -> ripe on day 3, gone after picking.
	var f := FarmGrid.new(crops)
	var c := Vector2i(10, 10)
	check(f.till(c), "till")
	check(not f.till(c), "till twice refused")
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			f.till(c + Vector2i(dx, dy))
	check(f.sow(c, "turnip", "spring") == 9, "seed bag sows 3x3")
	var days := 0
	while not f.is_ripe(c) and days < 20:
		f.water_cell(c)
		f.day_end("spring", "sunny", rng)
		days += 1
	check(days == 3, "turnip ripe after 3 watered days (got %d)" % days)
	check(f.harvest(c) == "turnip", "harvest turnip")
	check(f.cell(c).crop == "", "turnip gone after picking")

	# Unwatered crops don't grow; rain waters them.
	var u := Vector2i(10, 11)
	f.day_end("spring", "sunny", rng)
	check(f.cell(u).stage == 0, "dry crop did not grow")
	f.day_end("spring", "rain", rng)
	check(f.cell(u).wet, "rain waters tilled cells")

	# Cucumber regrows to stage 2 after picking.
	var g := FarmGrid.new(crops)
	var k := Vector2i(5, 10)
	g.till(k)
	g.sow(k, "cucumber", "spring")
	for i in 8:
		g.water_cell(k)
		g.day_end("spring", "sunny", rng)
	check(g.harvest(k) == "cucumber", "cucumber ripe after 8 days")
	check(g.cell(k).stage == 2, "cucumber back to stage 2")

	# Out of season crops wither; wrong season refuses seeds.
	g.day_end("summer", "sunny", rng)
	check(g.cell(k).crop == "", "spring crop withers in summer")
	check(g.sow(k, "turnip", "summer") == 0, "turnip not sown in summer")

	# Obstacles: the right tool, the right number of hits.
	var h := FarmGrid.new(crops)
	var s := Vector2i(3, 12)
	h.cell(s).obj = FarmGrid.Obj.STUMP
	check(h.is_solid(s), "stump blocks")
	check(h.hit(s, "hammer") == 0, "hammer does nothing to a stump")
	check(h.hit(s, "axe") == 1 and h.hit(s, "axe") == 1 and h.hit(s, "axe") == 1, "3 axe hits")
	check(h.hit(s, "axe") == 2 and not h.is_solid(s), "4th hit clears the stump")

	print("test_farm: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
