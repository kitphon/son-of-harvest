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
	_rules()
	_files()
	_paths_stay_clear()
	_building_day()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_town_today()
		_sprites()
		_start_views()
	elif _frame == 3:
		_check_views()
		_start_farm_views()
	elif _frame == 5:
		_check_farm_views()
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
func _paths_stay_clear() -> void:
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


func _state(extra := {}) -> Dictionary:
	return {"year": 1, "season": "spring", "day": 1, "weekday": "mon", "weather": "sunny", "flags": {}}.merged(extra, true)


## The real data on a spring Monday and other days: who is in the village when.
func _town_today() -> void:
	var s := _state()
	var at := func(t: float) -> Array:
		return Villagers.on_map("town", t, s).map(func(w): return w.id)
	check(at.call(360.0).is_empty(), "nobody out at 6:00")
	check(at.call(600.0) == ["kota", "tome"], "Kota and Tome out at 10:00 %s" % [at.call(600.0)])
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
	check(Villagers.where("hachiro", 600.0, _state({"day": 7, "weekday": "sun"})).pos == Vector2(30.5, 16.5), "Hachiro fishes on Sunday")
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
			check(up.get_size() == Vector2i(16, 24) and up.get_data() != blow.get_data() and up.get_data() != idle.get_data()
				and _has_colour(up, Color("5a5e66")) and _has_colour(blow, Color("5a5e66")), "%s %s work frames: the hammer raised, then the blow" % [id, side])
			check(idle.get_size() == Vector2i(16, 24), "%s %s frame is 16 x 24" % [id, side])
			check(_has_colour(idle, top), "%s %s shows their top colour" % [id, side])
			check(_has_colour(idle, PlaceholderArt.OUTLINE), "%s %s has the outline" % [id, side])
			var a := PlaceholderArt.tex("villager:%s:%s:walk:0" % [id, side]).get_image()
			var b := PlaceholderArt.tex("villager:%s:%s:walk:1" % [id, side]).get_image()
			check(a.get_data() != b.get_data(), "%s %s walk frames differ" % [id, side])
	var w := {"id": "kota", "facing": Vector2i.UP, "moving": true, "walked": 1.2}
	check(Villagers.sprite_key(w) == "villager:kota:back:walk:2", "walk frame by the distance walked: %s" % Villagers.sprite_key(w))
	w = {"id": "kota", "facing": Vector2i.DOWN, "moving": false, "walked": 0.0}
	check(Villagers.sprite_key(w) == "villager:kota:front:idle:0", "standing")


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
	_scene3 = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene3)
	_scene2 = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(_scene2)


func _check_views() -> void:
	var g: Node = root.get_node("Game")
	var want := Villagers.on_map("town", g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	var ids := want.map(func(w): return w.id)
	check(ids == ["kota", "tome"], "Kota and Tome are in the village at 14:20 (the keepers are in their shops) %s" % [ids])
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


## Views are checked by script path: in a --script run the autoload isn't known when this
## file compiles, so naming the view classes here would fail to compile.
func _script_is(n: Node, file: String) -> bool:
	return n.get_script() != null and n.get_script().resource_path.ends_with(file)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
