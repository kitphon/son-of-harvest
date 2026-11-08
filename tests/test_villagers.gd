extends SceneTree
## Headless checks for villagers (data/villagers, DayPlan, Villagers, the sprites in both
## views). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_villagers.gd

var failures := 0
var _frame := 0
var _scene3: Node
var _scene2: Node
var _farm3: Node
var _farm2: Node


func _init() -> void:
	_day_minutes()
	_plan_walks()
	_plan_loops_and_carry_on()
	_plan_errors()
	_work_step()
	_fish_step()
	_post_step()
	_ferry_crossing()
	_rules()
	_files()
	_paths_stay_clear()
	_building_day()
	_river_sunday()
	_doctor()
	_whistles()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_town_today()
		_sprites()
		_figures()
		_start_views()
	elif _frame == 3:
		_check_views()
		_start_farm_views()
	elif _frame == 5:
		_check_farm_views()
		_start_river_views()
	elif _frame == 7:
		_check_river_views()
		print("test_villagers: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


func _day_minutes() -> void:
	check(DayPlan.day_minute(6, 0) == 360 and DayPlan.day_minute(23, 59) == 1439, "the day counts from 6:00")
	check(DayPlan.day_minute(1, 30) == 1530 and DayPlan.day_minute(5, 59) == 1799, "after midnight is past 24:00")
	check(DayPlan.minute_of("07:30") == 450 and DayPlan.minute_of("02:00") == 1560, "plan times read the same way")
	check(DayPlan.minute_of("7") == -1 and DayPlan.minute_of("24:00") == -1 and DayPlan.minute_of(9) == -1, "a broken time is refused")


func _plan(entries: Array, speed := 2.0) -> DayPlan:
	var r := DayPlan.build(entries, speed)
	check(r[0] == "", "test plan builds: %s" % r[0])
	return r[1]


## A route walked once: positions along each straight walk, facing by the walk, stands and turns.
func _plan_walks() -> void:
	var p := _plan([
		{"at": "06:00", "map": "away"},
		{"at": "08:00", "map": "town", "from": [2, 3], "route": [{"to": [6, 3]}, {"wait": 10}, {"to": [6, 1]}, {"face": "left"}]},
		{"at": "12:00", "map": "away"},
	])
	check(p.where(400).map == "away" and p.where(1700).map == "away", "away before and after (the night counts as the last entry)")
	var w := p.where(480)
	check(w.map == "town" and w.pos == Vector2(2.5, 3.5) and w.facing == Vector2i.RIGHT, "starts on its from cell %s" % [w])
	check(p.where(479.9).map == "away", "and not before its time")
	w = p.where(481)
	check(w.pos == Vector2(4.5, 3.5) and w.moving and w.facing == Vector2i.RIGHT and is_equal_approx(w.walked, 2.0),
		"walks 2 cells a minute towards the right %s" % [w])
	w = p.where(482.5)
	check(w.pos == Vector2(6.5, 3.5) and not w.moving and w.facing == Vector2i.RIGHT, "stands at the spot through the wait %s" % [w])
	w = p.where(492.5)
	check(w.pos == Vector2(6.5, 2.5) and w.moving and w.facing == Vector2i.UP, "then walks up %s" % [w])
	w = p.where(600)
	check(w.pos == Vector2(6.5, 1.5) and not w.moving and w.facing == Vector2i.LEFT, "ends turned left %s" % [w])
	check(p.walks().size() == 2 and p.walks()[0] == ["town", Vector2(2.5, 3.5), Vector2(6.5, 3.5)], "walks() lists the straight walks")
	check(DayPlan.facing_of(Vector2(-1, 3)) == Vector2i.DOWN and DayPlan.facing_of(Vector2(-3, 1)) == Vector2i.LEFT,
		"a slanting walk faces along its bigger side")


## A loop repeats until the next entry; an entry without a from carries on from the last one.
func _plan_loops_and_carry_on() -> void:
	var p := _plan([
		{"at": "06:00", "map": "town", "from": [0, 0], "route": [{"to": [2, 0]}],
			"loop": [{"to": [2, 2]}, {"wait": 2}, {"to": [2, 0]}, {"wait": 2}]},
		{"at": "07:00", "map": "town", "route": [{"to": [5, 5]}]},
	], 1.0)
	# Route: 2 min to (2, 0); loop pass: 2 down, 2 wait, 2 up, 2 wait = 8 min, from 362.
	check(p.where(363).pos == Vector2(2.5, 1.5), "first time round the loop %s" % [p.where(363)])
	check(p.where(363 + 8 * 5).pos == p.where(363).pos and p.where(365 + 8 * 3).pos == Vector2(2.5, 2.5),
		"the loop repeats every 8 minutes")
	check(p.where(366).facing == Vector2i.UP and p.where(366).moving, "walking back up the loop")
	var at_seven := p.where(419.999)
	var next := p.where(420)
	check(next.pos.distance_to(at_seven.pos) < 0.01, "the next entry starts where the loop left them %s %s" % [at_seven, next])


func _plan_errors() -> void:
	var bad := {
		"first entry not at 6:00": [{"at": "07:00", "map": "away"}],
		"times not in order": [{"at": "06:00", "map": "away"}, {"at": "09:00", "map": "away"}, {"at": "08:00", "map": "away"}],
		"comes onto a map with no from": [{"at": "06:00", "map": "away"}, {"at": "08:00", "map": "town", "route": [{"to": [1, 1]}]}],
		"walks past the next entry": [{"at": "06:00", "map": "town", "from": [0, 0], "route": [{"to": [30, 0]}]}, {"at": "06:05", "map": "away"}],
		"a broken step": [{"at": "06:00", "map": "town", "from": [0, 0], "route": [{"run": [3, 3]}]}],
		"a bad facing": [{"at": "06:00", "map": "town", "from": [0, 0], "route": [{"face": "north"}]}],
		"away with a route": [{"at": "06:00", "map": "away", "route": [{"to": [1, 1]}]}],
		"a loop that takes no time": [{"at": "06:00", "map": "town", "from": [0, 0], "loop": [{"face": "up"}]}],
		"an unknown key": [{"at": "06:00", "map": "away", "speed": 3}],
		"work of no minutes": [{"at": "06:00", "map": "town", "from": [0, 0], "route": [{"work": 0}]}],
	}
	for what in bad:
		check(DayPlan.build(bad[what], 1.5)[0] != "", "refused: " + what)


## A work step stands like a wait, at work: the sprite swings the hammer by the minutes worked.
func _work_step() -> void:
	var p := _plan([
		{"at": "06:00", "map": "farm", "from": [2, 4], "route": [{"face": "up"}], "loop": [{"work": 10}, {"wait": 2}]},
	])
	var w := p.where(363.0)
	check(w.working and is_equal_approx(w.worked, 3.0) and not w.moving and w.facing == Vector2i.UP and w.pos == Vector2(2.5, 4.5),
		"at work 3 minutes in %s" % [w])
	check(not p.where(371.0).working and p.where(371.0).worked == 0.0, "the wait after it is not work")
	check(p.where(373.0).working and is_equal_approx(p.where(373.0).worked, 1.0), "the loop goes back to work")
	var per := float(Villagers.common().get("work_strokes_per_minute", 0))
	check(per > 0, "work strokes per minute in _common.json")
	check(Villagers.work_frame(0.0) == 0 and Villagers.work_frame(1.0 / (per * 2.0) + 0.01) == 1
		and Villagers.work_frame(2.0 / (per * 2.0) + 0.01) == 0, "hammer up, the blow, up again")
	w.id = "hachiro"
	check(Villagers.sprite_key(w).begins_with("villager:hachiro:back:work:"), "the work pose key %s" % Villagers.sprite_key(w))
	w.working = false
	check(Villagers.sprite_key(w) == "villager:hachiro:back:idle:0", "standing, not at work")


## A fish step stands like a wait with a rod out: the sprite's fish pose, the tip bobbing now and then.
func _fish_step() -> void:
	var p := _plan([
		{"at": "06:00", "map": "river", "from": [6, 5], "route": [{"face": "down"}], "loop": [{"fish": 20}, {"wait": 2}]},
	])
	var w := p.where(365.0)
	check(w.fishing and is_equal_approx(w.fished, 5.0) and not w.working and not w.moving and w.facing == Vector2i.DOWN,
		"fishing 5 minutes in %s" % [w])
	check(not p.where(381.0).fishing and p.where(381.0).fished == 0.0, "the wait after it is not fishing")
	check(p.where(383.0).fishing, "the loop casts again")
	var every := float(Villagers.common().get("fish_bob_minutes", 0))
	check(every > 1.0, "fish_bob_minutes in _common.json")
	check(Villagers.fish_frame(0.0) == 0 and Villagers.fish_frame(every - 0.5) == 1 and Villagers.fish_frame(every + 0.5) == 0,
		"the tip still, a bob, still again")
	w = p.where(362.0).merged({"id": "kota"})
	check(Villagers.sprite_key(w) == "villager:kota:front:fish:0", "the fish pose key %s" % Villagers.sprite_key(w))
	check(DayPlan.build([{"at": "06:00", "map": "river", "from": [6, 5], "route": [{"fish": 0}]}], 1.5)[0] != "", "refused: a fish of 0 minutes")


## The first rule that holds picks the plan; flags, days, years and the default.
func _rules() -> void:
	var v := {"default": "usual", "rules": [
		{"if": {"weather": ["rain"]}, "plan": "wet"},
		{"if": {"season": ["winter"], "weekday": ["sun"]}, "plan": "winter_sunday"},
		{"if": {"flags": ["festival_soon"], "not_flags": ["sick"]}, "plan": "busy"},
		{"if": {"days": [10, 12], "year": [2, 9999]}, "plan": "later"},
	]}
	var s := {"year": 1, "season": "spring", "day": 1, "weekday": "mon", "weather": "sunny", "flags": {}}
	check(Villagers.pick_plan(v, s) == "usual", "no rule holds: the default")
	check(Villagers.pick_plan(v, s.merged({"weather": "rain", "season": "winter", "weekday": "sun"}, true)) == "wet", "the first rule that holds wins")
	check(Villagers.pick_plan(v, s.merged({"season": "winter", "weekday": "sun"}, true)) == "winter_sunday", "all conditions of a rule hold")
	check(Villagers.pick_plan(v, s.merged({"season": "winter"}, true)) == "usual", "one condition missing: the rule doesn't hold")
	check(Villagers.pick_plan(v, s.merged({"flags": {"festival_soon": true}}, true)) == "busy", "a set flag")
	check(Villagers.pick_plan(v, s.merged({"flags": {"festival_soon": true, "sick": 1}}, true)) == "usual", "a not_flag that is set")
	check(Villagers.pick_plan(v, s.merged({"day": 11, "year": 2}, true)) == "later" and Villagers.pick_plan(v, s.merged({"day": 11}, true)) == "usual",
		"day and year ranges")
	for c in [{"weekday": ["someday"]}, {"season": "spring"}, {"weather": ["fog"]}, {"days": [5]}, {"birthday": "yes"}, {"flags": [""]}]:
		check(Villagers.check_conditions(c) != "", "refused condition %s" % [c])


## Every file loads, its maps exist, its plans are reachable, its look has the known styles.
func _files() -> void:
	var ids := Villagers.file_ids()
	check(ids.size() >= 4, "at least four villagers %s" % [ids])
	check(Villagers.all().size() == ids.size(), "every villager file passes its check")
	for id in ids:
		var r := Villagers.load_villager(id)
		check(r[0] == "", "%s loads: %s" % [id, r[0]])
		if r[0] != "":
			continue
		var v: Dictionary = r[1]
		check(str(v.look.get("hair_style", "short")) in PlaceholderArt.VILLAGER_STYLES and str(v.look.get("outfit", "happi")) in PlaceholderArt.VILLAGER_OUTFITS,
			"%s has a known hair style and outfit" % id)
		check(str(v.look.get("build", "adult")) in PlaceholderArt.VILLAGER_BUILDS, "%s has a known build" % id)
		var used := {v.default: true}
		for rule in v.rules:
			used[rule.plan] = true
		for name in v.plans:
			check(used.has(name), "%s plan %s is picked by a rule or the default" % [id, name])
			for e in v.plans[name]:
				check(e.map == DayPlan.AWAY or MapManager.has(e.map), "%s plan %s: map %s exists" % [id, name, e.map])
	check(Villagers.check({"id": "x", "name": "X", "look": {}, "plans": {"a": [{"at": "06:00", "map": "away"}]}, "default": "b"}) != "",
		"a default that is not a plan is refused")
	check(Villagers.check({"id": "x", "name": "X", "look": {}, "plans": {"a": [{"at": "06:00", "map": "away"}]}, "default": "a",
		"rules": [{"if": {}, "plan": "zzz"}]}) != "", "a rule naming a missing plan is refused")


## No straight walk in any plan crosses a solid cell (walls, water, houses, posts, trees).
## The maps are read with every house extension built: a spouse lives in the farmhouse's
## second room, which a proposal needs (data/marriage.json).
func _paths_stay_clear() -> void:
	MapManager.set_built(["kitchen", "chest", "room"])
	for id in Villagers.all():
		var v: Dictionary = Villagers.all()[id]
		for name in v.plans:
			var p: DayPlan = DayPlan.build(v.plans[name], Villagers.speed_of(v))[1]
			for e in p.entries:
				if e.map != DayPlan.AWAY:
					var m := MapManager.data(e.map)
					var start := Vector2i(e.pos.floor())
					check(not m.is_solid(start), "%s %s starts the %d entry on an open cell %s" % [id, name, e.start, start])
			for walk in p.walks():
				var m := MapManager.data(walk[0])
				var n := int(walk[1].distance_to(walk[2]) * 10) + 1
				for i in n + 1:
					var c := Vector2i(walk[1].lerp(walk[2], float(i) / n).floor())
					if m.is_solid(c):
						check(false, "%s plan %s walks %s -> %s through solid %s" % [id, name, walk[1], walk[2], c])
						break
	MapManager.set_built([])


## While a house extension is under way (Game.BUILD_FLAG) Hachiro builds on the farm: west
## along the village road, hammering at the farmhouse wall, the smithy without its keeper.
func _building_day() -> void:
	var b := _state({"flags": {"house_work": "kitchen"}})
	check(Villagers.where("hachiro", 600.0, _state()).map == "smithy", "on a plain day Hachiro keeps the smithy at 10:00")
	check(Villagers.where("hachiro", 465.0, b).map == "town" and Villagers.where("hachiro", 465.0, b).moving, "building: off down the road at 7:45")
	var w := Villagers.where("hachiro", 600.0, b)
	check(w.map == "farm" and w.pos == Vector2(2.5, 4.5) and w.facing == Vector2i.UP and w.working, "hammering at the farmhouse wall at 10:00 %s" % [w])
	check(not Villagers.is_on("hachiro", "smithy", 600.0, b) and not Villagers.is_on("hachiro", "smithy", 900.0, b),
		"nobody at the smithy counter while he builds")
	var fetched := false
	var worked := 0
	for t in range(500, 720):
		var at := Villagers.where("hachiro", float(t), b)
		fetched = fetched or (at.pos == Vector2(2.5, 5.5) and at.facing == Vector2i.LEFT)
		worked += 1 if at.working else 0
	check(fetched and worked > 150, "fetches boards from the stack now and then, mostly at work (%d of 220 minutes)" % worked)
	w = Villagers.where("hachiro", 740.0, b)
	check(w.map == "farm" and w.facing == Vector2i.DOWN and not w.working, "a lunch break at 12:20 %s" % [w])
	check(Villagers.where("hachiro", 900.0, b).working, "back at it in the afternoon")
	check(Villagers.where("hachiro", 1110.0, b).map == "smithy" and Villagers.where("hachiro", 1320.0, b).map == "away", "home to the smithy by 18:30, in bed at 22:00")
	var sun := b.merged({"day": 7, "weekday": "sun"}, true)
	check(Villagers.where("hachiro", 600.0, sun).map == "farm", "the job goes on on a Sunday")
	check(Villagers.where("hachiro", 600.0, b.merged({"weather": "storm"}, true)).map == "smithy", "not in a storm: the forge")
	check(Villagers.where("hachiro", 600.0, b.merged({"season": "winter", "day": 11}, true)).map == "town", "his birthday wins over the job")
	# His farm walks keep off the farm's fixed spots (the house, the chest, the bin, the stand,
	# the pond, the coop, the barn, the fence) and off the solid story props that can stand
	# there while he builds (his own lumber, Kota's streamer pole): FarmGrid.prop_blocks.
	var farm := FarmGrid.new({})
	farm.generate(RandomNumberGenerator.new())
	var props: MapData = MapManager.load_map("farm", null, {"house_work": "kitchen", "kota_streamer": true, "hachiro_bell": true})[1]
	farm.prop_blocks = func(c: Vector2i) -> bool: return props.in_bounds(c) and props.is_solid(c)
	check(farm.is_solid(Vector2i(1, 4)) and farm.is_solid(Vector2i(1, 5)), "the lumber is solid on the farm")
	var v: Dictionary = Villagers.all().hachiro
	var p: DayPlan = DayPlan.build(v.plans.building, Villagers.speed_of(v))[1]
	var walks := p.walks().filter(func(x): return x[0] == "farm")
	check(walks.size() >= 4, "building walks on the farm %d" % walks.size())
	for walk in walks:
		var n := int(walk[1].distance_to(walk[2]) * 10) + 1
		for i in n + 1:
			var c := Vector2i(walk[1].lerp(walk[2], float(i) / n).floor())
			if farm.fixed_at(c) != "" or farm.under_prop(c):
				check(false, "the building walk %s -> %s crosses the farm's %s at %s" % [walk[1], walk[2], farm.fixed_at(c) if farm.fixed_at(c) != "" else props.prop_at(c).kind, c])
				break


## A fair Sunday: Hachiro down the lane behind Kota's house to the river by 9:30, rod out on
## the shore until 15:00; Kota beside him 14:10-17:00. A wet Sunday they stay in.
func _river_sunday() -> void:
	var sun := _state({"day": 7, "weekday": "sun"})
	var on := func(t: float, st: Dictionary) -> Array:
		return Villagers.on_map("river", t, st).map(func(w): return w.id).filter(func(id): return id != "mio")   # Mio lives there
	check(on.call(560.0, sun).is_empty(), "nobody at the river at 9:20")
	# Mio works her traps east of the path, clear of the two Sunday fishers' spots.
	for t in [600.0, 700.0, 840.0, 950.0]:
		var m := Villagers.where("mio", t, sun)
		var hm := Villagers.where("hachiro", t, sun)
		var km := Villagers.where("kota", t, sun)
		check(m.map != "river" or ((hm.map != "river" or m.pos.distance_to(hm.pos) >= 1.0) and (km.map != "river" or m.pos.distance_to(km.pos) >= 1.0)),
			"Mio keeps clear of Hachiro and Kota at %d (%s)" % [t, m])
	var w := Villagers.where("hachiro", 555.0, sun)
	check(w.map == "minamino" and w.moving, "Hachiro walks down through Minamino at 9:15 %s" % [w])
	w = Villagers.where("hachiro", 600.0, sun)
	check(w.map == "river" and w.pos == Vector2(10.5, 5.5) and w.facing == Vector2i.DOWN and w.fishing, "Hachiro's rod is out at 10:00 %s" % [w])
	check(on.call(780.0, sun) == ["hachiro"], "alone at the river at 13:00")
	check(on.call(870.0, sun) == ["hachiro", "kota"], "Kota joins him in the afternoon %s" % [on.call(870.0, sun)])
	w = Villagers.where("kota", 870.0, sun)
	check(w.pos.y == 5.5 and w.facing == Vector2i.DOWN and w.pos.x < 8.0, "Kota on the shore left of Hachiro %s" % [w])
	var fishing := 0
	for t in range(860, 1020):
		var k := Villagers.where("kota", float(t), sun)
		fishing += 1 if k.fishing else 0
		var h := Villagers.where("hachiro", float(t), sun)
		if k.map == "river" and h.map == "river" and k.pos.distance_to(h.pos) < 1.0:
			check(false, "Kota and Hachiro walk into each other at %d" % t)
			break
	check(fishing > 100, "Kota is mostly fishing (%d of 160 minutes)" % fishing)
	check(on.call(930.0, sun) == ["kota"] and Villagers.where("hachiro", 960.0, sun).map == "smithy", "Hachiro home by 16:00, Kota stays on")
	check(on.call(1030.0, sun).is_empty() and Villagers.where("kota", 1080.0, sun).map == "kota_house", "Kota home by 18:00")
	check(on.call(870.0, _state({"day": 7, "weekday": "sun", "season": "summer"})) == ["hachiro", "kota"], "summer Sundays at the river too")
	var wet := sun.merged({"weather": "rain"}, true)
	check(on.call(870.0, wet).is_empty() and Villagers.where("hachiro", 870.0, wet).map == "smithy"
		and Villagers.where("kota", 870.0, wet).map == "kota_house", "a wet Sunday: both stay in")
	check(on.call(870.0, _state()).is_empty(), "no river on a Monday")
	# The fish pose: a rod (and its line) that the idle frame doesn't have; the tip bobs.
	for id in ["hachiro", "kota"]:
		var idle := PlaceholderArt.tex("villager:%s:front:idle:0" % id).get_image()
		var up := PlaceholderArt.tex("villager:%s:front:fish:0" % id).get_image()
		var dip := PlaceholderArt.tex("villager:%s:front:fish:1" % id).get_image()
		check(up.get_size() == PlaceholderArt.FIGURE_SIZE and _has_colour(up, Color("7a5a32")) and not _has_colour(idle, Color("7a5a32"))
			and up.get_data() != dip.get_data(), "%s's fish frames: the rod out, then the tip dipped" % id)


## The post step (Ren's round): a {"post": minutes} stand shows the post pose, the letter held up
## for post_hold_minutes and then slipped in; the figure draws it and Ren's mailbag; his round
## stops at each door with it.
func _post_step() -> void:
	var r: Array = DayPlan.build([{"at": "06:00", "map": "town", "from": [5, 7], "route": [{"face": "up"}, {"post": 2}, {"wait": 5}]}], 1.5)
	check(r[0] == "", "a post step is read (%s)" % r[0])
	var p: DayPlan = r[1]
	var a: Dictionary = p.where(360.5)
	var b: Dictionary = p.where(361.5)
	check(a.posting and is_equal_approx(a.posted, 0.5) and not a.working and not a.fishing, "posting half a minute in %s" % [a])
	check(not p.where(363.0).posting, "done after its two minutes")
	a.id = "ren"
	b.id = "ren"
	check(Villagers.pose(a) == "post" and Villagers.sprite_key(a).ends_with(":post:0") and Villagers.sprite_key(b).ends_with(":post:1"),
		"the letter held up, then slipped in (%s, %s)" % [Villagers.sprite_key(a), Villagers.sprite_key(b)])
	check(DayPlan.build([{"at": "06:00", "map": "town", "from": [5, 7], "route": [{"post": 0}]}], 1.5)[0] != "", "refused: a post of 0 minutes")
	var look := Villagers.look("ren")
	var idle := FigureArt.draw(look, false, "idle", 0).get_data()
	check(look.has("bag") and idle != FigureArt.draw(_without(look, "bag"), false, "idle", 0).get_data(),
		"Ren's mailbag is drawn")
	var p0 := FigureArt.draw(look, false, "post", 0).get_data()
	var p1 := FigureArt.draw(look, false, "post", 1).get_data()
	check(p0 != p1 and p0 != idle and FigureArt.draw(look, true, "post", 0).get_data() != FigureArt.draw(look, true, "idle", 0).get_data(),
		"the post pose's two frames, front and back")
	var posts := JSON.stringify(Villagers.all().ren.plans.usual).count('"post"')
	check(posts >= 13, "Ren posts at every door of his round (%d stops)" % posts)
	Villagers.reset_day()
	var w := Villagers.where("ren", 8 * 60 + 35, _state())
	check(w.map == "town" and w.posting and Vector2i(w.pos.floor()) == Vector2i(5, 7) and w.facing == Vector2i.UP,
		"8:35, Ren slips the post in at Tome's door %s" % [w])
	check(FileAccess.get_file_as_string("res://data/sfx.json").contains('"letter_post"'), "the letter's paper sound is in data/sfx.json")


## Mio's ferry crossing (data/ferry.json, FerryRun, the {"ferry": minutes} step): the step is
## read; the phases run board, out, wait, back, off over its minutes; the boat leaves its mooring,
## lies against the far bank and comes back, staying on the water clear of the rocks; she steps
## down into the stern, poles out and back (the pole pose, two frames) and steps off again; on a
## fine spring morning her plan takes it across, never in winter, and her step lasts the run.
func _ferry_crossing() -> void:
	var r: Array = DayPlan.build([{"at": "06:00", "map": "river", "from": [14, 5], "route": [{"ferry": 30}, {"wait": 5}]}], 1.5)
	check(r[0] == "", "a ferry step is read (%s)" % r[0])
	var p: DayPlan = r[1]
	check(p.where(375.0).ferrying and is_equal_approx(p.where(375.0).ferried, 15.0) and not p.where(391.0).ferrying, "ferrying for its minutes, done after")
	check(is_equal_approx(FerryRun.total(), 30.0), "the crossing takes 30 minutes (%s)" % FerryRun.total())
	var names := []
	for m in [0.5, 5.0, 15.0, 25.0, 29.5]:
		names.append(FerryRun.phase(m)[0])
	check(names == ["board", "out", "wait", "back", "off"], "board, out, wait, back, off %s" % [names])
	check(FerryRun.boat_at(0.0) == FerryRun.mooring() and FerryRun.boat_at(15.0) == FerryRun.far() and FerryRun.boat_at(30.0) == FerryRun.mooring(),
		"the boat leaves its mooring, lies at the far bank and comes back")
	var river: MapData = MapManager.load_map("river", null, {})[1]
	var clear := true
	for i in 61:
		var b := FerryRun.boat_at(i * 0.5)
		for c in [Vector2(b.x - 1.35, b.y), Vector2(b.x + 1.35, b.y), Vector2(b.x, b.y - 0.3), Vector2(b.x, b.y + 0.3)]:
			var cell := Vector2i(c.floor())
			if river.tile(cell) != "water" or river.prop_at(cell).get("kind", "") == "river_rock":
				clear = false
	check(clear, "the boat stays on the water, clear of the rocks")
	var w := {"map": "river", "pos": Vector2(14.5, 5.5), "facing": Vector2i.DOWN, "moving": false, "walked": 0.0, "ferrying": true, "ferried": 0.0, "id": "mio"}
	var at := func(m: float) -> Dictionary:
		var x := w.duplicate()
		x.ferried = m
		return FerryRun.ride(x, "spring")
	var stern: Vector2 = FerryRun.mooring() + Vector2(-0.8, 0)
	check(at.call(0.0).pos.is_equal_approx(Vector2(14.5, 5.5)) and at.call(1.99).pos.distance_to(stern) < 0.05 and at.call(1.0).moving,
		"she walks down the landing into the stern")
	var out: Dictionary = at.call(5.0)
	check(out.poling and Villagers.pose(out) == "pole" and out.lift > 0.1 and out.pos.y > stern.y + 0.3, "poling out, standing in the boat %s" % [out])
	var a: Dictionary = at.call(3.0)
	var b: Dictionary = at.call(4.6)
	check(Villagers.sprite_key(a).ends_with(":pole:0") and Villagers.sprite_key(b).ends_with(":pole:1"), "the pole planted, then pushed (%s, %s)" % [Villagers.sprite_key(a), Villagers.sprite_key(b)])
	check(FerryRun.in_use(out) and not FerryRun.in_use({"map": "river", "ferrying": false}), "the boat's pole is in her hands while she crosses, lying on the seats otherwise")
	check(not at.call(15.0).poling and at.call(15.0).pos.is_equal_approx(FerryRun.far() + Vector2(-0.8, 0)), "standing at the far bank")
	check(at.call(20.0).poling and at.call(20.0).facing == Vector2i.UP, "poling back")
	check(at.call(29.99).pos.distance_to(Vector2(14.5, 5.5)) < 0.05 and FerryRun.boat_offset(at.call(29.99)) == Vector2.ZERO, "off on the shore, the boat tied again")
	var winter: Dictionary = w.duplicate()
	winter.ferried = 15.0
	FerryRun.ride(winter, "winter")
	check(not winter.ferrying and winter.pos == Vector2(14.5, 5.5), "no crossing in winter: she stays on the shore")
	var look := Villagers.look("mio")
	var idle := FigureArt.draw(look, false, "idle", 0).get_data()
	var p0 := FigureArt.draw(look, false, "pole", 0).get_data()
	check(p0 != idle and p0 != FigureArt.draw(look, false, "pole", 1).get_data() and FigureArt.draw(look, true, "pole", 0).get_data() != FigureArt.draw(look, true, "idle", 0).get_data(),
		"the pole pose's two frames, front and back")
	for plan in ["usual", "married"]:
		var steps := JSON.stringify(Villagers.all().mio.plans[plan])
		check(steps.contains('{"ferry":30}') or steps.contains('{"ferry":30.0}'), "Mio's %s plan crosses for the run's minutes" % plan)
	Villagers.reset_day()
	var crossed := false
	var mid: Dictionary = {}
	for m in range(9 * 60 + 30, 10 * 60 + 20):
		var v := Villagers.where("mio", m, _state())
		if v.get("ferrying", false) and v.ferried >= 14.0 and v.ferried < 16.0:
			crossed = true
			mid = v
	check(crossed and mid.map == "river" and FerryRun.boat_offset(mid).y > 1.5, "on a fine spring morning she takes the boat across %s" % [mid])
	Villagers.reset_day()
	var any := false
	for m in range(9 * 60 + 30, 10 * 60 + 20):
		any = any or Villagers.where("mio", m, _state({"season": "winter"})).get("ferrying", false)
	check(not any, "never in winter")
	Villagers.reset_day()
	check(Villagers.where("mio", 9 * 60 + 50, _state({"weather": "rain"})).map != "river", "not on a wet day (she mends nets inside)")
	Villagers.reset_day()


func _without(d: Dictionary, key: String) -> Dictionary:
	var out := d.duplicate()
	out.erase(key)
	return out


func _state(extra := {}) -> Dictionary:
	return {"year": 1, "season": "spring", "day": 1, "weekday": "mon", "weather": "sunny", "flags": {}}.merged(extra, true)


## Whistling (data/whistles.json, Whistles): who may whistle when, the odds and the gap, the
## level by distance, how long the puff lasts, and a whole fair day in the village.
func _whistles() -> void:
	var r := Whistles.rules()
	var tunes: Dictionary = Whistles.data().tunes
	for id in tunes:
		check(Villagers.all().has(id), "whistle tune %s is for a villager" % id)
	for id in Villagers.all():
		check(Whistles.has_tune(id), "%s has a whistle tune" % id)
	var walker := {"id": "kota", "pos": Vector2(5, 5), "facing": Vector2i.RIGHT, "moving": true, "walked": 1.0}
	check(Whistles.allowed(r, walker, "sunny", 10, "outdoor"), "walking outdoors on a fair morning: may whistle")
	for look in ["rain", "storm", "snow", "blizzard"]:
		check(not Whistles.allowed(r, walker, look, 10, "outdoor"), "no whistling in %s" % look)
	check(not Whistles.allowed(r, walker, "sunny", 6, "outdoor") and not Whistles.allowed(r, walker, "sunny", 19, "outdoor")
		and not Whistles.allowed(r, walker, "sunny", 23, "outdoor") and Whistles.allowed(r, walker, "sunny", 18, "outdoor"),
		"not at dawn or after dark (7:00..18:59 only)")
	check(not Whistles.allowed(r, walker, "sunny", 10, "indoor") and not Whistles.allowed(r, walker, "sunny", 10, "cave"),
		"not indoors or in the mine")
	check(not Whistles.allowed(r, walker.merged({"moving": false}, true), "sunny", 10, "outdoor")
		and not Whistles.allowed(r, walker.merged({"moving": false, "working": true}, true), "sunny", 10, "outdoor")
		and not Whistles.allowed(r, walker.merged({"moving": false, "fishing": true}, true), "sunny", 10, "outdoor"),
		"only while walking: not standing, hammering or fishing")
	check(not Whistles.allowed(r, walker.merged({"id": "nobody"}, true), "sunny", 10, "outdoor"), "no tune, no whistling")
	Villagers.actors["kota"] = {"map": "town", "pos": Vector2(5, 5), "facing": Vector2i.DOWN, "moving": true, "walked": 0.0}
	check(not Whistles.allowed(r, walker, "sunny", 10, "outdoor"), "not while acting in an event")
	Villagers.actors.erase("kota")
	# The level falls off with distance.
	check(Whistles.level(r, 0.0) == 1.0 and Whistles.level(r, float(r.hear_full)) == 1.0, "full level close by")
	var mid := Whistles.level(r, 8.0)
	check(mid > 0.0 and mid < 1.0 and Whistles.level(r, 6.0) > mid and Whistles.level(r, 10.0) < mid, "softer farther off (8 cells: %.2f)" % mid)
	check(Whistles.level(r, float(r.hear_reach)) == 0.0 and Whistles.level(r, 40.0) == 0.0, "silent beyond hear_reach")
	# The roll: the same each time, near its odds.
	check(Whistles.rolls("tome", "1/spring/3", 500, 0.5) == Whistles.rolls("tome", "1/spring/3", 500, 0.5), "a roll is the same each time")
	var hits := 0
	for m in 20000:
		hits += int(Whistles.rolls("sayo", "1/summer/%d" % (m / 1000), m, float(r.chance)))
	check(absf(hits / 20000.0 - float(r.chance)) < 0.01, "rolls hit at about the chance (%.3f)" % (hits / 20000.0))
	check(not Whistles.rolls("sayo", "x", 1, 0.0) and Whistles.rolls("sayo", "x", 1, 1.0), "odds 0 never, 1 always")
	# A fair spring Monday in the village, the farmer at the road's middle: every tune starts
	# on a walker, at least gap_minutes apart, and lasts its tune's length.
	var s := _state()
	var farmer := Vector2(12, 11)
	var starts := {}
	Whistles.reset()
	for t in range(360, 1260):
		for w in Whistles.step("town", float(t), s, "sunny", t / 60, "outdoor", farmer):
			var at := Villagers.where(w.id, float(t), s)
			check(at.map == "town" and at.moving and t >= 420 and t < 1140, "%s whistles walking in the village by day (%d)" % [w.id, t])
			check(is_equal_approx(w.level, Whistles.level(r, farmer.distance_to(at.pos))), "%s's level by the distance" % w.id)
			check(Whistles.puff(w.id, float(t)) == 0.0 and Whistles.playing(w.id, t + 0.5), "%s's puff starts" % w.id)
			if starts.has(w.id):
				check(t - int(starts[w.id][-1]) >= int(r.gap_minutes), "%s waits the gap (%d after %d)" % [w.id, t, starts[w.id][-1]])
			starts.get_or_add(w.id, []).append(t)
	check(starts.size() >= 1 and starts.keys().all(func(id): return Villagers.all().has(id)),
		"someone whistles over a fair day in the village %s" % [starts])
	var a_tune: String = starts.keys()[0] if not starts.is_empty() else "kota"
	var mins := Whistles.minutes(a_tune)
	check(mins > 2.0 and mins < 10.0, "%s's tune lasts %.1f game minutes (a few seconds)" % [a_tune, mins])
	Whistles.reset()
	Whistles._day = "1/spring/1"
	Whistles._started["kota"] = 600.0
	mins = Whistles.minutes("kota")
	check(Whistles.puff("kota", 600.0 + mins / 2.0) > 0.45 and Whistles.puff("kota", 600.0 + mins / 2.0) < 0.55
		and Whistles.puff("kota", 600.0 + mins + 0.01) < 0.0 and Whistles.puff("kota", 599.0) < 0.0 and Whistles.puff("tome", 600.0) < 0.0,
		"the puff runs 0..1 over the tune, -1 outside it")
	var a := Whistles.puff_look(0.0)
	var b := Whistles.puff_look(0.5)
	check(a.key == "fx:note" and b.key == "fx:notes" and Whistles.puff_look(0.9).key == "fx:note" and b.rise > a.rise
		and a.alpha == 0.0 and b.alpha == 1.0 and Whistles.puff_look(0.95).alpha < 0.5, "the puff: a note, two, one, rising, fading in and out")
	for key in ["fx:note", "fx:notes"]:
		var img := PlaceholderArt.tex(key).get_image()
		check(_has_colour(img, Color("2e2420")) and _has_colour(img, Color("f4ecd8")), "%s: dark ink with a pale rim" % key)
	# No tunes on a wet day, indoors or at night; forced, every walker at once.
	for case in [["rain", "outdoor", 0], ["sunny", "indoor", 0], ["sunny", "outdoor", 19]]:
		Whistles.reset()
		var n := 0
		for t in range(420, 1260):
			n += Whistles.step("town", float(t), _state({"weather": case[0]}), case[0], maxi(t / 60, case[2]), case[1], farmer).size()
		check(n == 0, "no tunes (%s, %s, from %d:00): %d" % [case[0], case[1], case[2], n])
	Whistles.reset()
	Whistles.forced = "*"
	var all_now := Whistles.step("town", 600.0, s, "sunny", 10, "outdoor", farmer).map(func(w): return w.id)
	var walking := Villagers.on_map("town", 600.0, s).filter(func(w): return w.moving).map(func(w): return w.id)
	check(all_now == walking, "--whistle: every walker whistles at once %s %s" % [all_now, walking])
	Whistles.forced = ""
	Whistles.reset()


## Dr. Yae: a villager without hearts (not among the friends, no birthday), at the clinic's
## keeper spot through the clinic's hours but for a dry day's walk to the shrine after lunch,
## at her counter at noon when a collapsed farmer wakes, in her room early and late.
func _doctor() -> void:
	var v: Dictionary = Villagers.all().get("yae", {})
	check(not v.is_empty() and v.get("hearts") == false, "Dr. Yae is a villager without hearts")
	var heartless := Villagers.all().keys().filter(func(id): return Villagers.all()[id].get("hearts", true) == false)
	check(not Villagers.friends().has("yae") and Villagers.friends().size() == Villagers.all().size() - heartless.size() and Villagers.friends().has("tome"),
		"friends() leaves her (and the other villagers without hearts) out, keeps the others")
	check(not v.has("birthday") and Villagers.check(v.merged({"hearts": "no"}, true)) != "", "no birthday; hearts must be true or false")
	var shop: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shops.json")).shops.clinic
	check(shop.keeper == "yae" and shop.map == "clinic", "she keeps the clinic's counter")
	var keeper: Vector2i = MapManager.data("clinic").spawns.keeper[0]
	for weather in ["sunny", "rain", "snow"]:
		var s := _state({"weather": weather})
		check(Villagers.where("yae", 720.0, s).map == "clinic" and Villagers.where("yae", 720.0, s).pos == Vector2(keeper) + Vector2(0.5, 0.5),
			"at noon (%s) she is at the clinic's keeper spot %s" % [weather, Villagers.where("yae", 720.0, s)])
		check(Villagers.where("yae", 420.0, s).map == DayPlan.AWAY and Villagers.where("yae", 1140.0, s).map == DayPlan.AWAY, "away at 7:00 and 19:00 (%s)" % weather)
		var t0 := int(shop.open[0]) * 60.0
		var t1 := int(shop.open[1]) * 60.0 - 1.0
		check(Villagers.is_on("yae", "clinic", t0, s) and Villagers.is_on("yae", "clinic", t1, s), "in at opening and closing (%s)" % weather)
	var walk := Villagers.where("yae", 800.0, _state())
	check(walk.map == "town" and walk.pos == Vector2(19.5, 8.5) and walk.facing == Vector2i.UP, "on a dry day she stands at the torii at 13:20 %s" % [walk])
	check(Villagers.where("yae", 800.0, _state({"weather": "rain"})).map == "clinic", "and stays in when it rains")


## The real data on a spring Monday and other days: who is in the village when.
func _town_today() -> void:
	var s := _state()
	var at := func(t: float) -> Array:
		return Villagers.on_map("town", t, s).map(func(w): return w.id)
	check(at.call(360.0).is_empty(), "nobody out at 6:00")
	check(at.call(600.0) == ["kaede", "kota", "tome"], "Kaede (sweeping the shrine), Kota and Tome out at 10:00 %s" % [at.call(600.0)])
	check(Villagers.on_map("store", 600.0, s).map(func(w): return w.id) == ["sayo"]
		and Villagers.on_map("smithy", 600.0, s).map(func(w): return w.id) == ["hachiro"], "the keepers at their counters at 10:00")
	check(at.call(1260.0).is_empty(), "everyone in at 21:00 %s" % [at.call(1260.0)])
	# Tome's morning: from her door (5, 7) down to the road, east, up to the torii, 1.5 cells / min.
	var w := Villagers.where("tome", 425.0, s)
	check(w.map == "town" and w.pos.is_equal_approx(Vector2(10.0, 10.5)) and w.facing == Vector2i.RIGHT and w.moving,
		"Tome walks along the road at 7:05 %s" % [w])
	w = Villagers.where("tome", 460.0, s)
	check(w.pos == Vector2(18.5, 8.5) and w.facing == Vector2i.UP and not w.moving, "Tome stands at the torii at 7:40 %s" % [w])
	check(Villagers.where("tome", 425.0, _state({"weather": "rain"})).map == "tome_house", "Tome stays home on a wet day")
	check(Villagers.where("tome", 425.0, _state({"season": "winter"})).map == "tome_house"
		and Villagers.where("tome", 620.0, _state({"season": "winter"})).map == "town", "Tome comes out late in winter")
	check(Villagers.is_on("sayo", "store", 720.0, s) and Villagers.is_on("sayo", "town", 720.0, _state({"day": 7, "weekday": "sun"}))
		and not Villagers.is_on("sayo", "town", 1100.0, s), "Sayo is in the store at noon on a shop day, out on her day off, in at 18:20")
	check(Villagers.where("sayo", 720.0, s).pos == Vector2(3.5, 2.5), "Sayo stands at the store's keeper spot at noon")
	check(Villagers.where("sayo", 525.0, s).map == "town", "and sweeps in front before opening")
	check(Villagers.where("sayo", 720.0, _state({"day": 7, "weekday": "sun"})).pos == Vector2(6.5, 8.5), "on Sunday she is off visiting Tome")
	check(Villagers.where("hachiro", 720.0, _state({"weather": "rain"})).map == "smithy", "Hachiro works the forge in the rain")
	check(Villagers.where("hachiro", 600.0, _state({"day": 7, "weekday": "sun"})).map == "river", "Hachiro fishes the river on Sunday")
	check(Villagers.where("nobody", 600.0, s).is_empty() and not Villagers.is_on("nobody", "town", 600.0, s), "an unknown villager is nowhere")
	_homes()


## At home in the mornings, at noon, in the evenings and on wet days; in bed at night.
func _homes() -> void:
	var s := _state()
	var on := func(map_id: String, t: float, st: Dictionary) -> Array:
		return Villagers.on_map(map_id, t, st).map(func(w): return w.id)
	check(on.call("tome_house", 380.0, s) == ["tome"] and on.call("kota_house", 380.0, s) == ["kota"]
		and on.call("sayo_house", 380.0, s) == ["sayo"] and on.call("smithy", 380.0, s) == ["hachiro"], "everyone at home at 6:20")
	var w := Villagers.where("tome", 380.0, s)
	check(w.pos == Vector2(6.5, 3.5) and w.facing == Vector2i.LEFT, "Tome sits right of her hearth %s" % [w])
	check(on.call("tome_house", 740.0, s) == ["tome"] and on.call("kota_house", 740.0, s) == ["kota"], "home for lunch at 12:20")
	check(on.call("tome_house", 1100.0, s) == ["tome"] and on.call("kota_house", 1100.0, s) == ["kota"]
		and on.call("sayo_house", 1050.0, s) == ["sayo"] and on.call("sayo_house", 1230.0, s) == ["sayo"], "home in the evening")
	var rain := _state({"weather": "rain"})
	check(on.call("kota_house", 600.0, rain) == ["kota"] and on.call("tome_house", 900.0, rain) == ["tome"], "home all day in the rain")
	var kota_moves := false
	for t in range(360, 1200, 5):
		kota_moves = kota_moves or Villagers.where("kota", float(t), rain).moving
	check(kota_moves, "Kota gets up and walks to the hearth now and then on a wet day")
	var sun := _state({"day": 7, "weekday": "sun"})
	check(on.call("tome_house", 800.0, sun) == ["sayo", "tome"] and Villagers.where("sayo", 800.0, sun).pos == Vector2(3.5, 3.5),
		"on Sunday afternoon Sayo has tea at Tome's %s" % [on.call("tome_house", 800.0, sun)])
	for id in ["tome", "kota", "sayo", "hachiro"]:
		check(Villagers.where(id, 1320.0, s).map == "away", "%s is in bed at 22:00" % id)
	# Talking at home: facing Tome from the floor below her.
	var m := MapManager.data("tome_house")
	check(Talk.facing_villager(m, Vector2i(6, 4), Vector2i.UP, 380.0, s).get("id", "") == "tome", "Tome can be talked to at home")
	check(Talk.keeper_shop("sayo", "sayo_house", Vector2i(4, 2)) == "", "at home Sayo is not keeping the store")
	# Every stretch a villager spends on a house map is inside that house's door hours (the
	# village doors that lead there), so the farmer finds them in when the door is open.
	var hours := {}
	for d in MapManager.data("town").doors:
		if d.has("hours"):
			hours[d.to] = d.hours
	check(hours.has("tome_house") and hours.has("kota_house") and hours.has("sayo_house"), "the village doors to the homes have hours %s" % [hours.keys()])
	for id in Villagers.all():
		var v: Dictionary = Villagers.all()[id]
		for name in v.plans:
			var p: DayPlan = DayPlan.build(v.plans[name], Villagers.speed_of(v))[1]
			for e in p.entries:
				if hours.has(e.map):
					check(e.start >= hours[e.map][0] and e.end <= hours[e.map][1],
						"%s %s at home on %s %d-%d within its hours %s" % [id, name, e.map, e.start, e.end, hours[e.map]])


## Every villager's frames draw at the farmer's size with their own colours; walking steps.
func _sprites() -> void:
	for id in Villagers.all():
		var top := Color(str(Villagers.look(id).get("top")))
		for side in ["front", "back"]:
			var idle := PlaceholderArt.tex("villager:%s:%s:idle:0" % [id, side]).get_image()
			var up := PlaceholderArt.tex("villager:%s:%s:work:0" % [id, side]).get_image()
			var blow := PlaceholderArt.tex("villager:%s:%s:work:1" % [id, side]).get_image()
			check(up.get_size() == PlaceholderArt.FIGURE_SIZE and up.get_data() != blow.get_data() and up.get_data() != idle.get_data()
				and _has_colour(up, Color("5a5e66")) and _has_colour(blow, Color("5a5e66")), "%s %s work frames: the hammer raised, then the blow" % [id, side])
			check(idle.get_size() == PlaceholderArt.FIGURE_SIZE, "%s %s frame is 24 x 32" % [id, side])
			check(_has_colour(idle, top), "%s %s shows their top colour" % [id, side])
			check(_has_colour(idle, PlaceholderArt.OUTLINE), "%s %s has the outline" % [id, side])
			var a := PlaceholderArt.tex("villager:%s:%s:walk:0" % [id, side]).get_image()
			var b := PlaceholderArt.tex("villager:%s:%s:walk:1" % [id, side]).get_image()
			check(a.get_data() != b.get_data(), "%s %s walk frames differ" % [id, side])
	var w := {"id": "kota", "facing": Vector2i.UP, "moving": true, "walked": 1.2}
	check(Villagers.sprite_key(w) == "villager:kota:back:walk:2", "walk frame by the distance walked: %s" % Villagers.sprite_key(w))
	w = {"id": "kota", "facing": Vector2i.DOWN, "moving": false, "walked": 0.0}
	check(Villagers.sprite_key(w) == "villager:kota:front:idle:0", "standing")


## The figures (FigureArt, 24 x 32): every key of every villager and the farmer is drawn at the
## figure size with the feet on the bottom rows; four directions from two drawings (front and
## back differ, mirrored for Right and Up); faces only from the front; builds set the height.
func _figures() -> void:
	var fig := PlaceholderArt.FIGURE_SIZE
	check(fig == Vector2i(24, 32), "figures are 24 x 32")
	var keys: Array[String] = []
	for side in ["front", "back"]:
		for pose in ["idle", "walk", "run", "tired_idle", "tired_walk", "hold_idle", "hold_walk", "fish_wait", "fish_bite", "eat", "drink"]:
			for f in PlaceholderArt.farmer_frames(pose):
				keys.append("player:%s:%s:%d" % [side, pose, f])
		for id in Villagers.all():
			for p in ["idle:0", "walk:0", "walk:1", "walk:2", "walk:3", "work:0", "work:1", "fish:0", "fish:1"]:
				keys.append("villager:%s:%s:%s" % [id, side, p])
	var bad: Array[String] = []
	for key in keys:
		var img := PlaceholderArt.tex(key).get_image()
		var used := img.get_used_rect()
		var grounded := false
		for x in fig.x:
			grounded = grounded or img.get_pixel(x, fig.y - 1).a > 0.0
		if img.get_size() != fig or not grounded or used.size.y < 20:
			bad.append(key)
	check(bad.is_empty(), "every figure key is drawn 24 x 32, standing on the bottom row (%d keys; off: %s)" % [keys.size(), bad])
	# Four directions: Down = front, Right = front mirrored, Left = back, Up = back mirrored.
	var pics := {}
	for facing in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP]:
		var a := FarmerAnim.new()
		var img := PlaceholderArt.tex(a.key(facing)).get_image().duplicate() as Image
		if FarmerAnim.is_mirrored(facing):
			img.flip_x()
		pics[img.get_data()] = facing
	check(pics.size() == 4, "the four facings show four different pictures")
	for id in Villagers.all():
		var front := PlaceholderArt.tex("villager:%s:front:idle:0" % id).get_image()
		var back := PlaceholderArt.tex("villager:%s:back:idle:0" % id).get_image()
		check(front.get_data() != back.get_data() and _has_colour(front, FigureArt.EYE) and not _has_colour(back, FigureArt.EYE),
			"%s: a face from the front, the back of the head from behind" % id)
	# Builds: children stand shorter than grown-ups, elders stoop a little; all taller than the old 24 px.
	var height := func(id: String) -> int:
		return PlaceholderArt.tex("villager:%s:front:idle:0" % id).get_image().get_used_rect().size.y
	for id in Villagers.all():
		var build := str(Villagers.look(id).get("build", "adult"))
		var h: int = height.call(id)
		match build:
			"child":
				check(h < height.call("hachiro") - 3 and PlaceholderArt.villager_top(id) > PlaceholderArt.villager_top("hachiro"),
					"%s is a child: shorter (%d px)" % [id, h])
			_:
				check(h > 24, "%s stands taller than the old figures (%d px)" % [id, h])
	check(PlaceholderArt.villager_top("tome") > PlaceholderArt.villager_top("sayo"), "Tome (an elder) stoops lower than Sayo")
	var fw: GDScript = load("res://scripts/world3d/farm_world.gd")
	var px: float = fw.FIGURE_PX
	var farmer_h := PlaceholderArt.tex("player:front:idle:0").get_image().get_used_rect().size.y
	check(farmer_h >= 27 and farmer_h * px > 1.08 and farmer_h * px < 1.45,
		"the farmer stands %.2f units: taller than before (1.08), under the eaves (1.45)" % (farmer_h * px))
	# The 3D sprites use the figure's pixel size, the feet on the ground.
	var s: Sprite3D = fw.make_figure(PlaceholderArt.tex("player:front:idle:0"))
	check(is_equal_approx(s.pixel_size, px) and is_equal_approx(s.offset.y, fig.y / 2.0), "a figure sprite stands on its feet at FIGURE_PX")
	s.free()


func _has_colour(img: Image, c: Color) -> bool:
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).is_equal_approx(c):
				return true
	return false


## Both views on the village at 14:20: the farmer walks in and everyone is already where the
## plan puts them at that time (the catch-up on map entry).
func _start_views() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.events_seen = {"first_morning": true, "rainy_day": true}
	g.hour = 14
	g.minute = 20
	g.maps.place("town", Vector2i(2, 10), Vector2i.RIGHT)
	g.pause()   # the clock holds, so the sprites and the check read the same minute
	check(is_equal_approx(g.day_minutes(), 860.0), "Game.day_minutes at 14:20 is %s" % g.day_minutes())
	var st: Dictionary = g.trigger_state(Vector2i.ZERO)
	Whistles.reset()
	Whistles._day = "%d/%s/%d" % [st.year, st.season, st.day]
	Whistles._rolled = 860
	Whistles._started["tome"] = 859.5   # half a minute into her tune
	_scene3 = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene3)
	_scene2 = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(_scene2)


func _check_views() -> void:
	var g: Node = root.get_node("Game")
	var want := Villagers.on_map("town", g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	var ids := want.map(func(w): return w.id)
	check(ids == ["kaede", "kota", "mio", "nana", "tome"], "Kaede (folding charms at the shrine), Kota, Mio (selling her catch at the store's front), Nana and Tome are in the village at 14:20 (the keepers are in their shops) %s" % [ids])
	var layers3: Array = _scene3.world.get_children().filter(func(n): return _script_is(n, "villager_sprites.gd"))
	check(layers3.size() == 1 and layers3[0].map_id == "town", "the 3D village world has its villagers")
	var layers2: Array = _scene2.view.get_children().filter(func(n): return _script_is(n, "villager_view.gd"))
	check(layers2.size() == 1 and layers2[0].map_id == "town", "the 2D village view has its villagers")
	if layers3.size() != 1 or layers2.size() != 1:
		return
	var shown3: Array = layers3[0].shown()
	shown3.sort()
	var shown2: Array = layers2[0].shown()
	shown2.sort()
	check(shown3 == ids and shown2 == ids, "both views show them %s %s" % [shown3, shown2])
	for w in want:
		var s3: Node3D = layers3[0]._sprites[w.id]
		check(Vector2(s3.position.x, s3.position.z).distance_to(w.pos) < 0.05, "%s stands where the plan says in 3D" % w.id)
		var s2: Node2D = layers2[0]._sprites[w.id]
		check(s2.position.distance_to(w.pos * 16) < 1.0, "%s stands where the plan says in 2D" % w.id)
	check(layers3[0].whistling("tome") and layers2[0].whistling("tome") and not layers3[0].whistling("kota") and not layers2[0].whistling("kota"),
		"both views show a note puff over Tome, who whistles, and none over Kota")
	var kota := Villagers.where("kota", g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	check(kota.pos == Vector2(30.5, 17.5) and kota.facing == Vector2i.RIGHT and not kota.moving, "Kota is fishing at the pond by 14:20 %s" % [kota])
	_scene3.free()
	_scene2.free()
	g.unpause()


## Both views on the farm at 10:00 with a build under way: Hachiro at the wall with the
## hammer, the lumber beside the house.
func _start_farm_views() -> void:
	var g: Node = root.get_node("Game")
	g.money = 99999
	check(g.shop_build("general", "kitchen").ok and not g.flags.has(g.BUILD_FLAG), "ordered: he starts tomorrow")
	check(not MapManager.data("farm").props.any(func(p): return p.kind == "lumber"), "no lumber on the order day")
	g.end_day()
	check(g.flags.get(g.BUILD_FLAG) == "kitchen", "the next morning the job is under way")
	g.weather_today = "sunny"
	g.hour = 10
	g.minute = 0
	g.maps.place("farm", Vector2i(4, 5), Vector2i.UP)
	g.pause()
	_farm3 = load("res://scenes/main.tscn").instantiate()
	root.add_child(_farm3)
	_farm2 = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(_farm2)


func _check_farm_views() -> void:
	var g: Node = root.get_node("Game")
	check(MapManager.data("farm").props.any(func(p): return p.kind == "lumber" and p.cell == Vector2i(1, 4)), "the lumber by the house")
	var layers3: Array = _farm3.world.get_children().filter(func(n): return _script_is(n, "villager_sprites.gd"))
	var layers2: Array = _farm2.view.get_children().filter(func(n): return _script_is(n, "villager_view.gd"))
	var story2: Array = _farm2.view.get_children().filter(func(n): return _script_is(n, "story_view.gd"))
	check(story2.size() == 1 and story2[0].map.props.any(func(p): return p.kind == "lumber"), "the flat view draws the lumber")
	if layers3.size() == 1 and layers2.size() == 1:
		check(layers3[0].shown() == ["hachiro"] and layers2[0].shown() == ["hachiro"], "both views show Hachiro on the farm %s %s" % [layers3[0].shown(), layers2[0].shown()])
		var key := Villagers.sprite_key(Villagers.where("hachiro", g.day_minutes(), g.trigger_state(Vector2i.ZERO)).merged({"id": "hachiro"}))
		check(":work:" in key and layers3[0]._sprites.hachiro.texture == PlaceholderArt.tex(key)
			and layers2[0]._sprites.hachiro.texture == PlaceholderArt.tex(key), "in the work pose in both views %s" % key)
		var s3: Node3D = layers3[0]._sprites.hachiro
		check(Vector2(s3.position.x, s3.position.z).distance_to(Vector2(2.5, 4.5)) < 0.05, "at the wall in 3D")
		check(g.farm.is_solid(Vector2i(1, 4)) and g.maps.is_solid(Vector2i(1, 5), g.farm) and not g.farm.is_solid(Vector2i(2, 5)),
			"the lumber blocks the farmer (both views' Player asks Game.maps), the cell he fetches from stays open")
	else:
		check(false, "the farm views have their villager layers")
	_farm3.free()
	_farm2.free()
	g.unpause()
	for i in 2:
		g.weather_today = "sunny"   # a storm day wouldn't count (Game._count_build_day)
		g.end_day()
	check(not g.farm.is_solid(Vector2i(1, 4)), "the lumber's cells are open once it is gone")
	check(g.has_built("kitchen") and not g.flags.has(g.BUILD_FLAG) and not MapManager.data("farm").props.any(func(p): return p.kind == "lumber"),
		"built: the flag and the lumber are gone")


## Both views on the river at 14:30 on a fair Sunday: the farmer walks in and both fishers
## stand where the plan has them, in the fish pose.
func _start_river_views() -> void:
	var g: Node = root.get_node("Game")
	g.year = 1
	g.season = 0
	g.day = 7
	g.weather_today = "sunny"
	g.flags.erase(g.BUILD_FLAG)
	g.hour = 14
	g.minute = 30
	g.maps.place("river", Vector2i(8, 3), Vector2i.DOWN)
	g.pause()
	_scene3 = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene3)
	_scene2 = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(_scene2)


func _check_river_views() -> void:
	var g: Node = root.get_node("Game")
	var want := Villagers.on_map("river", g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	check(g.weekday() == "sun" and want.map(func(w): return w.id) == ["hachiro", "kota"], "both at the river at 14:30 %s" % [want])
	var layers3: Array = _scene3.world.get_children().filter(func(n): return _script_is(n, "villager_sprites.gd"))
	var layers2: Array = _scene2.view.get_children().filter(func(n): return _script_is(n, "villager_view.gd"))
	if layers3.size() == 1 and layers2.size() == 1:
		for w in want:
			var key := Villagers.sprite_key(w)
			var s3: Sprite3D = layers3[0]._sprites.get(w.id)
			var s2: Node2D = layers2[0]._sprites.get(w.id)
			check(s3 != null and s3.visible and Vector2(s3.position.x, s3.position.z).distance_to(w.pos) < 0.05, "%s on the shore in 3D" % w.id)
			check(s2 != null and s2.visible and s2.position.distance_to(w.pos * 16) < 1.0, "%s on the shore in 2D" % w.id)
			check(not w.fishing or (":fish:" in key and s3.texture == PlaceholderArt.tex(key) and s2.texture == PlaceholderArt.tex(key)),
				"%s in the fish pose in both views %s" % [w.id, key])
		check(want.any(func(w): return w.fishing), "someone has a rod out at 14:30")
	else:
		check(false, "the river views have their villager layers")
	_scene3.free()
	_scene2.free()
	g.unpause()


## Views are checked by script path: in a --script run the autoload isn't known when this
## file compiles, so naming the view classes here would fail to compile.
func _script_is(n: Node, file: String) -> bool:
	return n.get_script() != null and n.get_script().resource_path.ends_with(file)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
