extends SceneTree
## Headless checks for the public bath, Kawasemi-yu (Baths step 2; docs/DESIGN.md → ที่อาบน้ำ):
## data/baths.json and the sento's shop (hours 14:00-23:00, shut on Thursdays and festival days,
## the 120 G paid once a day at the street door: Game.pay_entry, bath_paid_today, saved), the maps
## data/maps/sento.json, sento_changing.json and sento_bath.json (the lobby, the changing room and
## the bath, each on its own map, the doors each way, every floor cell reachable, the counter, the
## tub's seats before its front), the changing room (Game.change_clothes, in_towel, the towel look,
## the bath's door only in a towel and the lobby's only dressed), getting into the tub (Game.soak with the
## bath's soak_cfg: the day's first bath gives +40 / -20 and runs the clock on an hour, a later one
## only rests, the baths share bathed_today apart from the footbath's soaked_today, the farmer turns to
## face the room once in: Game.soak_look), the pose "bathe" (FigureArt._bathe: the head, the bare
## shoulders and the towel over the water, nothing lower), E at the tub through FarmActions and its
## hint, the 3D build (BathProps: every kind, the water at WATER, the steam) and the flat view
## (BathLook, MapView.COLORS), and the villagers' evening baths (Baths step 3: the {"bathe": minutes}
## step, Villagers.bath_place in the tub's water turned to the room, the towel on the bath's map, the
## nights each comes, a taken seat refused, their bath lines in Thai, the 3D sprite at the water), and
## Kajika-yu up the gorge (Baths step 4: data/maps/kajika.json west of the river map on the plan, the
## way in shut until kajika_built (a door's `needs`), the rock pool's hours 16:00-02:00, only in a
## towel from the hut, stamina full and -30 for 90 minutes, the day's bath shared with the sento, the
## way out only dressed, the 3D pool, hut and screen and the pool's steam). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_baths.gd

var failures := 0
var g: Node
# Loaded, not named: these scripts reach the Game autoload, which a --script test only has at run time.
var FA: GDScript
var AH: GDScript
var MV: GDScript
var BP: GDScript
var FG: GDScript
var PA: GDScript
const GORGE_KINDS := ["onsen", "bath_hut", "bamboo_screen", "oke", "bath_pavilion", "yukimi_doro"]   # Kajika-yu's, up the gorge (_kajika)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	FA = load("res://scripts/farm_actions.gd")
	AH = load("res://scripts/ui/action_hints.gd")
	MV = load("res://scripts/world/map_view.gd")
	BP = load("res://scripts/world3d/bath_props.gd")
	FG = load("res://scripts/art/figure_art.gd")
	PA = load("res://scripts/art/placeholder_art.gd")
	g.new_game()
	g.clock_running = false
	_data()
	_map()
	_changing()
	_keeper()
	_entry()
	_bath()
	_pose()
	_views()
	_bathers()
	_kajika()
	print("test_baths: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


func _sento() -> Dictionary:
	return g.baths.get("sento", {})


func _data() -> void:
	var b := _sento()
	check(not b.is_empty() and str(b.get("day", "")) == "bath", "the sento's bath counts toward the baths' one a day")
	check(int(b.get("stamina", 0)) == 40 and int(b.get("fatigue", 0)) == -20 and int(b.get("minutes", 0)) == 60, "+40 stamina, -20 fatigue, an hour (DESIGN)")
	check(int(b.stamina) > int(g.ashiyu.stamina) and int(b.fatigue) < int(g.ashiyu.fatigue), "more than the free footbath")
	check(int(b.fatigue) > -42, "never a stand-in for a night's sleep (about -42 from 22:00)")
	check(is_equal_approx(float(b.lift), BP.WATER), "sat at the water's height (%.2f, the tub's water %.2f)" % [float(b.lift), BP.WATER])
	var keys: Array = b.get("sit_path", [])
	check(keys.size() >= 3 and float(keys[0][0]) == 0.0 and float(keys[-1][0]) == 1.0 and str(keys[-1][3]) == "bathe"
		and is_equal_approx(float(keys[-1][1]), float(b.seat)) and is_equal_approx(float(keys[-1][2]), float(b.lift)), "the way in, keyed from standing to sat in the water")
	check(keys.any(func(k): return float(k[2]) > BP.RIM - 0.05 and str(k[3]) != "bathe"), "over the rim on the feet, not through it")
	for k in ["message", "again_message", "hands_message", "seat_message"]:
		var t := String(b.get(k, ""))
		check(t != "" and t.right(1) in [".", "!", "?"], "%s is a sentence" % k)
	var s: Shop = g.shop("sento")
	check(s != null and s.map == "sento" and s.open_hour == 14 and s.close_hour == 23 and s.days_off == ["thu"], "open 14:00-23:00, shut on Thursdays")
	check(int(s.own().get("entry_fee", 0)) == 120, "120 G to get in")
	check(s.stock(g.season_name()).any(func(e): return str(e.item) == "food:milk"), "the counter sells the milk")
	for fid in Festivals.all():
		check(Festivals.closes(fid, "sento"), "shut on %s" % fid)


## The cells reached from `start` on `m` walking (doors are solid, so a map's own floor only).
func _reach(m: MapData, start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if m.in_bounds(n) and not m.is_solid(n) and not seen.has(n):
				seen[n] = true
				todo.append(n)
	return seen


func _floor_left(m: MapData, seen: Dictionary) -> Array:
	var shut := []
	for y in m.h:
		for x in m.w:
			var c := Vector2i(x, y)
			if not m.is_solid(c) and not seen.has(c):
				shut.append(c)
	return shut


func _map() -> void:
	# Three maps (the user's asks): the lobby, the changing room apart so the lobby never sees into
	# it, and the bath.
	var m: MapData = MapManager.data("sento")
	var c: MapData = MapManager.data("sento_changing")
	var b: MapData = MapManager.data("sento_bath")
	check(m != null and m.indoor and m.name == "Kawasemi-yu" and m.towel == "", "the lobby, indoors, no towels")
	check(c != null and c.indoor and c.towel == "allowed" and c.name == "Changing Room", "the changing room on its own map, a towel allowed")
	check(b != null and b.indoor and b.towel == "always" and b.name == "Kawasemi-yu Bath", "the bath on its own map, all of it in a towel")
	var kinds := {}
	for p in m.props + c.props + b.props:
		kinds[str(p.kind)] = p
	for k in BP.KINDS:
		if not k in GORGE_KINDS:
			check(kinds.has(k), "the bath has its %s" % k)
	for k in ["yubune", "kran", "bath_mural"]:
		check(b.props.any(func(p): return p.kind == k), "%s in the bath" % k)
	check(m.props.any(func(p): return p.kind == "counter" and str(p.get("shop", "")) == "sento"), "the counter in the lobby, the sento's shop")
	var change: Array = c.props.filter(func(p): return str(p.get("use", "")) == "change")
	check(change.size() == 1 and change[0].kind == "basket_shelf" and not m.props.any(func(p): return str(p.get("use", "")) == "change"),
		"the baskets in the changing room only: where one changes")
	var tub: Dictionary = kinds.yubune
	check(str(tub.get("use", "")) == "soak" and str(tub.get("bath", "")) == "sento" and int(tub.cell[1]) == 1, "the tub along the back wall, a bath to soak in")
	check(Vector2i(kinds.bath_mural.cell).y == 0 and int(kinds.bath_mural.cell[0]) == int(tub.cell[0]), "the mountain painted on the wall over the tub")
	var reach := {}
	for map in [m, c, b]:
		var start := Vector2i(map.spawns.start[0][0], map.spawns.start[0][1])
		reach[map.id] = _reach(map, start)
		check(_floor_left(map, reach[map.id]).is_empty(), "%s: every floor reached from its door (%s)" % [map.id, _floor_left(map, reach[map.id])])
	var seats: Array = g.soak_spots(tub)
	check(seats.size() == int(tub.size[0]) and seats.all(func(s): return reach.sento_bath.has(s[0]) and s[1] == Vector2i.UP), "a seat before every cell of the tub's front, facing it (%d)" % seats.size())
	# The doors, each way, the spawns on the floor beyond them, a noren or a glass door hung in each.
	var way := func(from: MapData, to: String) -> Dictionary:
		var ds := from.doors.filter(func(d): return d.to == to)
		return ds[0] if ds.size() == 1 else {}
	var pairs := [[m, "sento_changing", "bath_noren"], [c, "sento", "bath_noren"], [c, "sento_bath", "glass_door"], [b, "sento_changing", "glass_door"]]
	for pr in pairs:
		var d: Dictionary = way.call(pr[0], pr[1])
		check(not d.is_empty() and reach[pr[1]].has(Vector2i(d.spawn)), "%s -> %s: a door, its spawn on the floor" % [pr[0].id, pr[1]])
		check(not d.is_empty() and pr[0].props.any(func(p): return p.kind == pr[2] and Vector2i(p.cell) == Vector2i(d.cells[0])), "%s -> %s: its %s" % [pr[0].id, pr[1], pr[2]])
	check(way.call(c, "sento_bath").towel and way.call(c, "sento").dressed, "into the bath only in a towel, out to the lobby only dressed")
	check(not way.call(m, "sento_changing").towel and not way.call(b, "sento_changing").dressed, "the other ways open")
	var y: MapData = MapManager.data("yumachi")
	var front: Dictionary = y.door_at(Vector2i(7, 4))
	var lobby := Vector2i(m.spawns.start[0][0], m.spawns.start[0][1])
	check(str(front.get("to", "")) == "sento" and str(front.get("shop", "")) == "sento" and Vector2i(front.spawn) == lobby, "Yumachi's bath door leads in, under the shop's hours")
	check(Vector2i(way.call(m, "yumachi").spawn) == Vector2i(7, 5), "and back out before it")


## Into a towel at the baskets and back; the bath only in one, the lobby only dressed.
func _changing() -> void:
	var said: Array[String] = []
	var hear := func(t: String): said.append(t)
	g.message.connect(hear)
	var ch: Dictionary = g.baths.get("changing", {})
	for k in ["to_towel", "to_clothes", "need_towel", "dress_first", "hands"]:
		check(String(ch.get(k, "")).right(1) in [".", "!", "?"], "the changing room's %s is a sentence" % k)
	var c: MapData = MapManager.data("sento_changing")
	var into: Dictionary = c.doors.filter(func(d): return d.to == "sento_bath")[0]
	var out: Dictionary = c.doors.filter(func(d): return d.to == "sento")[0]
	var at := Vector2i(c.spawns.change[0][0], c.spawns.change[0][1])
	g.go_to_map("sento", Vector2i(6, 4), Vector2i.RIGHT)
	FA.on_action("interact", Vector2i(6, 4), Vector2i.UP)
	check(not g.in_towel, "no changing in the lobby")
	g.go_to_map("sento_changing", at, Vector2i.UP)
	check(AH.interact_verb(at, Vector2i.UP) == "Change", "the hint at the baskets: Change")
	g.use_door(into)
	check(g.maps.id == "sento_changing" and said.back() == String(ch.need_towel), "dressed: not into the bath")
	FA.on_action("interact", at, Vector2i.UP)
	check(g.in_towel and g.wearing_towel() and said.back() == String(ch.to_towel), "E at the baskets: into a towel")
	g._process(0.0)
	check(FarmerLooks.towel and FarmerLooks.cache_key("player:front:idle:0").ends_with("@towel"), "the farmer's pictures in the towel kept apart")
	g.use_door(out)
	check(g.maps.id == "sento_changing" and said.back() == String(ch.dress_first), "in a towel: not out to the lobby")
	g.use_door(into)
	check(g.maps.id == "sento_bath" and g.in_towel, "in a towel: into the bath")
	g.use_door(MapManager.data("sento_bath").doors[0])
	check(g.maps.id == "sento_changing" and g.in_towel, "back in the changing room still in the towel")
	g.maps.place("sento_changing", at, Vector2i.UP)
	FA.on_action("interact", at, Vector2i.UP)
	check(not g.in_towel and not g.wearing_towel() and said.back() == String(ch.to_clothes), "E again: dressed")
	g.use_door(out)
	check(g.maps.id == "sento", "dressed: out to the lobby")
	g.go_to_map("sento_changing", at, Vector2i.UP)
	g.held = "crop:turnip"
	FA.on_action("interact", at, Vector2i.UP)
	check(not g.in_towel and said.back() == String(ch.hands), "not while holding something")
	g.held = ""
	g.in_towel = true
	g.go_to_map("yumachi", Vector2i(7, 5), Vector2i.DOWN)
	check(not g.in_towel, "off the bath's maps: dressed (never a towel outside)")
	g.go_to_map("sento_bath", Vector2i(1, 3), Vector2i.RIGHT)
	check(g.in_towel, "on the bath's map: always in the towel")
	g.end_day()
	check(not g.in_towel, "a new day: dressed")
	var th := Lang.table("th")
	check(["to_towel", "to_clothes", "need_towel", "dress_first"].all(func(k): return th.has(String(ch[k]))) and th.has("Change") and th.has("Get in") and th.has("Changing Room") and th.has("Kawasemi-yu Bath"), "the changing room in Thai")
	# The farmer's picture in the towel: no jacket, bare shoulders, arms and feet, the towel's white.
	FarmerLooks.towel = true
	var look := FarmerLooks.current_look()
	check(look.outfit == "towel" and look.top == FarmerLooks.TOWEL, "the look in the towel")
	var img: Image = FG.draw(look, false, "idle", 0, true)
	check(not _has_colour(img, Color(str(FG.FARMER_LOOK.top))), "no jacket under the towel")
	FarmerLooks.towel = false
	g.message.disconnect(hear)
	g.new_game()
	g.clock_running = false


## Masa, the bath's keeper (data/villagers/masa.json): at the counter through the opening hours,
## at the woodpile by the chimney late in the morning, by the river on a dry Thursday, in on a wet
## one, at every festival in the village (the bath shut); no hearts, like Dr. Yae.
func _keeper() -> void:
	var v: Dictionary = Villagers.all().get("masa", {})
	check(not v.is_empty() and v.get("hearts") == false and not v.has("birthday"), "Masa is a villager without hearts")
	var s: Shop = g.shop("sento")
	check(s.keeper == "masa" and str(s.own().get("ask", "")) != "" and str(s.own().get("away", "")) != "", "she keeps the sento's counter, asks first, leaves a note when out")
	var keeper := Vector2(MapManager.data("sento").spawns.keeper[0][0], MapManager.data("sento").spawns.keeper[0][1]) + Vector2(0.5, 0.5)
	var day := {"year": 1, "season": "spring", "day": 2, "weekday": "tue", "weather": "sunny", "flags": {}, "festival": ""}
	for t in [14 * 60, 18 * 60, 22 * 60 + 59]:
		var w := Villagers.where("masa", float(t), day)
		check(w.map == "sento" and w.pos == keeper, "at the counter at %d:%02d (%s)" % [t / 60, t % 60, w])
	check(Villagers.where("masa", 600.0, day).map == DayPlan.AWAY and Villagers.where("masa", 23 * 60 + 30.0, day).map == DayPlan.AWAY, "away at 10:00 and 23:30")
	var wood := Villagers.where("masa", 12 * 60.0, day)
	check(wood.map == "yumachi" and wood.pos.distance_to(Vector2(13.5, 3.5)) < 0.1, "at noon by the woodpile behind the chimney (%s)" % wood)
	var wet := day.merged({"weather": "rain"}, true)
	check(Villagers.where("masa", 12 * 60.0, wet).map == DayPlan.AWAY and Villagers.where("masa", 15 * 60.0, wet).map == "sento", "a wet day: no firewood, the counter all the same")
	var thu := day.merged({"weekday": "thu", "day": 4}, true)
	var off := Villagers.where("masa", 12 * 60.0, thu)
	check(off.map == "yumachi" and off.pos.y > 8.0 and Villagers.where("masa", 15 * 60 + 30.0, thu).map == DayPlan.AWAY, "a dry Thursday: by the river walk, home by half past three (%s)" % off)
	check(Villagers.where("masa", 12 * 60.0, thu.merged({"weather": "rain"}, true)).map == DayPlan.AWAY, "a wet Thursday: in")
	check(Talk.pick("masa", {"band": 2, "again": false, "day_number": 0, "time": 15 * 60}.merged(thu, true)) == "day_off", "on her day off she says so")
	var th := Lang.table("th")
	check(th.has(str(s.own().ask)) and th.has(str(s.own().away)) and th.has("Masa"), "her counter's words in Thai")


## The door under the shop's hours, and the fee once a day.
func _entry() -> void:
	var said: Array[String] = []
	var hear := func(t: String): said.append(t)
	g.message.connect(hear)
	var street: Dictionary = MapManager.data("yumachi").door_at(Vector2i(7, 4))
	var noren: Dictionary = MapManager.data("sento").doors.filter(func(d): return d.to == "sento_changing")[0]
	check(str(noren.get("fee", "")) == "sento" and str(street.get("fee", "")) == "", "the noren into the changing room asks for the day's ticket, not the street door")
	g.maps.place("yumachi", Vector2i(7, 5), Vector2i.UP)
	g.day = 1
	while g.weekday() == "thu" or g.festival_today() != "":
		g.day += 1
	g.hour = 11
	g.money = 1000
	g.use_door(street)
	check(g.maps.id == "yumachi" and g.money == 1000 and said.back() == g.shop("sento").closed_text(), "shut before two: the hours said, nothing paid")
	g.hour = 15
	g.use_door(street)
	check(g.maps.id == "sento" and g.money == 1000 and not g.bath_paid_today, "open: into the lobby for nothing (the milk is for anyone)")
	var own: Dictionary = g.shop("sento").own()
	g.maps.place("sento", Vector2i(6, 4), Vector2i.RIGHT)
	g.use_door(noren)
	check(g.maps.id == "sento" and g.money == 1000 and not g.bath_paid_today and said.back() == String(own.entry_needed) % 120, "unpaid: the noren stays shut, pay at the counter first")
	# At the counter Masa offers the bath first; picking it pays.
	g.ask_keeper("sento", "", "")
	var box: Dictionary = g.dialogue_made[g.KEEPER_DIALOGUE]
	var first: Dictionary = box.lines[0].choices[0]
	check(str(first.text) == String(own.entry_choice) % 120 and first.set.get(g.KEEPER_FLAG, "") == "pay", "the keeper's first answer: pay for a bath (120 G)")
	g.flags[g.KEEPER_FLAG] = "pay"
	g.dialogue_closed(g.KEEPER_DIALOGUE)
	check(g.money == 880 and g.bath_paid_today and said.back() == String(own.entry_message) % 120, "picked: 120 G paid, the key handed over")
	g.ask_keeper("sento", "", "")
	check(not g.dialogue_made[g.KEEPER_DIALOGUE].lines[0].choices.any(func(c): return c.get("set", {}).get(g.KEEPER_FLAG, "") == "pay"), "paid: no second offer today")
	g.dialogue_made.erase(g.KEEPER_DIALOGUE)
	g.use_door(noren)
	check(g.maps.id == "sento_changing" and g.money == 880, "paid: through the noren")
	g.go_to_map("sento", Vector2i(6, 4), Vector2i.RIGHT)
	g.use_door(noren)
	check(g.maps.id == "sento_changing" and g.money == 880, "back through the same day for nothing")
	var d: Dictionary = g.to_dict()
	check(d.get("bath_paid_today", null) == true, "the day's ticket saved")
	g.bath_paid_today = false
	check(g.from_dict(d) == "" and g.bath_paid_today, "and loaded")
	d.erase("bath_paid_today")
	check(g.from_dict(d) == "" and not g.bath_paid_today, "an older save: not paid yet")
	g.go_to_map("sento", Vector2i(6, 4), Vector2i.RIGHT)
	g.money = 100
	g.flags[g.KEEPER_FLAG] = "pay"
	g._keeper_talk = {"shop": "sento", "file": "", "at": ""}
	g.dialogue_made[g.KEEPER_DIALOGUE] = {}
	g.dialogue_closed(g.KEEPER_DIALOGUE)
	check(g.money == 100 and not g.bath_paid_today and said.back() == String(own.entry_short) % 120, "short of 120 G: not paid")
	g.use_door(noren)
	check(g.maps.id == "sento", "and the noren stays shut")
	g.money = 1000
	g.bath_paid_today = true
	g.end_day()
	check(not g.bath_paid_today and not g.bathed_today, "a new day: a new ticket")
	g.maps.place("yumachi", Vector2i(7, 5), Vector2i.UP)
	g.hour = 15
	while g.weekday() != "thu":
		g.day += 1
	g.use_door(street)
	check(g.maps.id == "yumachi" and not g.bath_paid_today, "shut on Thursday")
	g.maps.place("sento", Vector2i(6, 4), Vector2i.RIGHT)
	g.use_door(noren)
	check(g.maps.id == "sento" and not g.bath_paid_today, "and no way through the noren on Thursday either")
	g.message.disconnect(hear)
	g.new_game()
	g.clock_running = false


func _bath() -> void:
	var said: Array[String] = []
	var hear := func(t: String): said.append(t)
	g.message.connect(hear)
	var b := _sento()
	var seat := Vector2i(6, 3)
	g.go_to_map("sento_bath", seat, Vector2i.UP)
	check(AH.interact_verb(seat, Vector2i.UP) == "Get in", "the hint at the tub: Get in (not the footbath's Soak)")
	g.hour = 16
	g.minute = 0
	g.stamina = 30
	g.fatigue = 50
	FA.on_action("interact", seat, Vector2i.UP)
	check(g.soaking() and g.bathed_today and not g.soaked_today, "E at the tub: in, the baths' rest given (not the footbath's)")
	check(g.stamina == 70 and g.fatigue == 30, "+40 stamina, -20 fatigue (%d / %d)" % [g.stamina, g.fatigue])
	check(g.hour == 16 and g.minute == 0 and g.soak_owed == 60 and not g.ticking(), "the hour owed, not jumped: the clock still while stepping in (%d:%02d)" % [g.hour, g.minute])
	check(said.back() == String(b.message), "says the bath")
	check(g.soak_look() == Vector2i.UP and g.still_pose() == "walk", "stepping up to the tub, back to the eye")
	g._process(float(b.sit_seconds) + 0.05)
	check(g.soak_phase == "sit" and g.still_pose() == "bathe" and g.soak_look() == Vector2i.DOWN, "sat in the water, turned to face the room")
	check(is_equal_approx(g.soak_seat(true), float(b.seat)) and is_equal_approx(g.soak_lift(true), float(b.lift)), "a cell into the tub, at the water's height")
	check(not g.feet_in(), "no footbath water band in a bath")
	# Sat, the clock runs at its own pace though indoors (the bathers beside the farmer get out in time).
	g.clock_running = true
	check(g.ticking() and g.soak_clock(), "sat: the clock runs indoors")
	g._process(g.SECONDS_PER_MINUTE * 10.0 + 0.01)
	check(g.hour == 16 and g.minute == 10 and g.soak_owed == 50, "ten minutes sat, ten paid (%d:%02d, %d owed)" % [g.hour, g.minute, g.soak_owed])
	g.clock_running = false
	var biggest := 0.0
	var last := 0.0
	for k in 201:
		g.soak_t = k / 200.0
		var x: float = g.soak_seat(true)
		biggest = maxf(biggest, absf(x - last))
		last = x
	g.soak_t = 1.0
	check(biggest < 0.03, "no jump on the way in (%.3f)" % biggest)
	g.stop_soak()
	check(g.hour == 16 and g.minute == 10 and g.soak_owed == 50, "getting out: no jump of the clock in the room (the bathers stay put) (%d:%02d)" % [g.hour, g.minute])
	check(g.soak_look() == Vector2i.DOWN, "getting out: turned away from the tub (not backing out)")
	g._process(float(b.stand_seconds) * 0.6)
	check(g.soaking() and g.soak_look() == Vector2i.DOWN, "still facing the way out half way")
	g._process(float(b.stand_seconds))
	check(not g.soaking() and g.soak_cfg == g.ashiyu, "out and free; the next soak names its own")
	g.clock_running = true
	check(g.ticking(), "the clock runs in the bath's room though indoors (MapData clock)")
	g.clock_running = false
	g.go_to_map("sento_changing", Vector2i(5, 2), Vector2i.LEFT)
	check(g.hour == 17 and g.minute == 0 and g.soak_owed == 0, "out of the room: the rest of the hour at once, out of sight (%d:%02d)" % [g.hour, g.minute])
	g.go_to_map("sento_bath", seat, Vector2i.UP)
	var st: int = g.stamina
	FA.on_action("interact", seat, Vector2i.UP)
	check(g.soaking() and g.stamina == st and g.hour == 17 and said.back() == String(b.again_message), "a second bath the same day only rests, no hour taken")
	g.stop_soak()
	g._process(float(b.stand_seconds) + 0.05)
	# The footbath keeps its own day: a bath does not use it up, nor the other way round.
	check(not g.soaked_today, "the footbath's rest still there after the bath")
	g.maps.place("sento_bath", Vector2i(6, 4), Vector2i.UP)
	FA.on_action("interact", Vector2i(6, 4), Vector2i.UP)
	check(not g.soaking(), "not from two cells off")
	g.held = "crop:turnip"
	g.maps.place("sento_bath", seat, Vector2i.UP)
	FA.on_action("interact", seat, Vector2i.UP)
	check(not g.soaking() and said.back() == String(b.hands_message), "not while holding something")
	g.held = ""
	var d: Dictionary = g.to_dict()
	check(d.get("bathed_today", null) == true, "the day's bath saved")
	d.erase("bathed_today")
	check(g.from_dict(d) == "" and not g.bathed_today, "an older save: no bath yet")
	g.message.disconnect(hear)
	var th := Lang.table("th")
	check(["message", "again_message", "hands_message", "seat_message"].all(func(k): return th.has(String(b[k]))), "the bath's messages in Thai")
	var sh: Dictionary = g.shop("sento").own()
	check(th.has(String(sh.entry_message)) and th.has(String(sh.entry_short)) and th.has("Kawasemi-yu"), "the fee's messages and the name in Thai")
	g.new_game()
	g.clock_running = false


func _pose() -> void:
	check(FG.frames("bathe") == 2, "the bathing pose breathes in two frames")
	var front: Image = PA.image("player:front:bathe:0")
	var back: Image = PA.image("player:back:bathe:0")
	var idle: Image = PA.image("player:front:idle:0")
	var used := front.get_used_rect()
	check(used.position.y > idle.get_used_rect().position.y + 8, "low in the picture: only the head and shoulders over the water")
	check(used.end.y >= FG.FOOT, "the water across the bottom, where the feet would stand")
	var water := 0
	var towel := 0
	for y in front.get_height():
		for x in front.get_width():
			var c := front.get_pixel(x, y)
			water += int(c.a > 0.0 and c.is_equal_approx(FG.BATH_WATER))
			towel += int(c.a > 0.0 and c.is_equal_approx(FG.TOWEL))
	check(water > 10 and towel > 4, "the water and the towel drawn (%d / %d)" % [water, towel])
	check(back.get_used_rect().size.y > 8, "from behind too")
	check(not _has_colour(front, Color(str(FG.FARMER_LOOK.top))), "no clothes in the bath (the jacket's colour nowhere)")


func _has_colour(img: Image, col: Color) -> bool:
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0 and img.get_pixel(x, y).is_equal_approx(col):
				return true
	return false


func _views() -> void:
	var world: Node3D = load("res://scripts/world3d/map_world.gd").new()
	root.add_child(world)
	world.build(MapManager.data("sento_bath"))
	var steam := world.get_children().filter(func(n): return str(n.name).begins_with("BathSteam"))
	check(steam.size() == BP.STEAM_PUFFS, "steam over the bath (%d)" % steam.size())
	check(steam.all(func(n): return n.position.y > BP.WATER and Rect2(3, 1, 7, 2).has_point(Vector2(n.position.x, n.position.z))), "rising off the tub's water")
	world.queue_free()
	for k in BP.KINDS:
		check(MV.COLORS.has(k), "%s in the flat view" % k)
	var src := FileAccess.get_file_as_string("res://scripts/world/map_view.gd")
	check("BathLook.draw(" in src, "the flat view draws the bath's things (BathLook)")
	var mural: Image = PA.image("bath:mural")
	check(mural.get_size() == Vector2i(192, 32), "the mountain painting 192 x 32")
	check(PA.image("ground:bath_tile:0").get_size() == Vector2i(16, 16), "the tiled floor")


## The villagers' evening baths (Baths step 3): who soaks on which night, in the tub's water up to the
## shoulders facing the room, in a towel on the bath's map, none on Thursdays, wet days or festivals;
## the farmer kept off a taken seat; their lines there.
func _bathers() -> void:
	var r := DayPlan.build([{"at": "06:00", "map": "sento_bath", "from": [5, 3], "route": [{"face": "up"}, {"bathe": 30}]}], 1.5)
	check(r[0] == "" and r[1].where(370.0).bathing and not r[1].where(400.0).bathing, "a bathe step: bathing for its minutes, then not")
	check(DayPlan.build([{"at": "06:00", "map": "sento_bath", "from": [5, 3], "route": [{"bathe": 0}]}], 1.5)[0] != "", "refused: a bathe of 0 minutes")
	var b := _sento()
	var mon := {"year": 1, "season": "spring", "day": 1, "weekday": "mon", "weather": "sunny", "flags": {}, "festival": ""}
	var t := 19 * 60 + 21.0   # a Friday: Tome nearly done, Hachiro just settled
	var fri := mon.merged({"weekday": "fri", "day": 5}, true)
	var here := Villagers.on_map("sento_bath", t, fri)
	var ids := here.map(func(w): return w.id)
	ids.sort()
	check(ids == ["hachiro", "tome"], "a dry Friday at 19:21: Tome and Hachiro in the bath (%s)" % [ids])
	for w in here:
		var seat: Vector2i = w.seat_cell
		check(w.pos.is_equal_approx(Vector2(seat) + Vector2(0.5, 0.5) + Vector2.UP * float(b.seat)) and w.facing == Vector2i.DOWN, "%s sat in the water from %s, facing the room (%s)" % [w.id, seat, w.pos])
		check(is_equal_approx(float(w.bath_lift), float(b.lift)) and Villagers.pose(w) == "bathe", "%s up to the shoulders (the pose bathe, lifted to the water)" % w.id)
		var key := Villagers.sprite_key(w)
		check(key == "villager:%s:front:bathe:0:towel" % w.id, "%s drawn bathing in a towel (%s)" % [w.id, key])
		check(PA.image(key).get_used_rect().position.y > PA.image("villager:%s:front:idle:0" % w.id).get_used_rect().position.y + 8, "%s: only the head and shoulders over the water" % w.id)
	check(Villagers.bath_seats("sento_bath", t, fri).size() == 2, "two seats taken")
	# Getting in and out eased along the bath's sit_path, never a jump (the user saw them pop up in
	# front of the tub): every 0.05 minutes from the walk to the tub to the walk away.
	var jump := 0.0
	var lift_jump := 0.0
	var was: Dictionary = Villagers.where("tome", 18 * 60 + 27.0, mon)
	var sat_up := false
	var out_down := false
	var m0 := 18 * 60 + 27.0
	while m0 < 19 * 60 + 30.0:
		m0 += 0.05
		var now: Dictionary = Villagers.where("tome", m0, mon)
		if now.map == was.map:
			jump = maxf(jump, Vector2(now.pos).distance_to(was.pos))
			lift_jump = maxf(lift_jump, absf(float(now.get("bath_lift", 0.0)) - float(was.get("bath_lift", 0.0))))
		if now.has("seat_cell") and float(now.bathed) > 0.5 and float(now.bathed) < 1.0:
			sat_up = sat_up or (now.facing == Vector2i.UP and Villagers.pose(now.merged({"id": "tome"})) == "walk")
		if now.has("seat_cell") and float(now.bathe_len) - float(now.bathed) < 0.5:
			out_down = out_down or (now.facing == Vector2i.DOWN and float(now.bath_lift) < float(b.lift))
		was = now
	check(jump < 0.15 and lift_jump < 0.1, "Tome into the tub and out again with no jump (%.3f cells, %.3f up)" % [jump, lift_jump])
	check(sat_up and out_down, "stepping in facing the tub, out facing the room, rising out of the water")
	var walking := Villagers.where("tome", 18 * 60 + 28.0, mon)
	check(walking.map == "sento_bath" and walking.moving and Villagers.sprite_key(walking.merged({"id": "tome"})).ends_with(":towel") and not walking.has("seat_cell"), "Tome walks to the tub in her towel (%s)" % walking)
	check(not Villagers.sprite_key(Villagers.where("tome", 18 * 60 + 18.0, mon).merged({"id": "tome"})).ends_with(":towel"), "dressed in the lobby")
	check(Villagers.where("tome", 19 * 60 + 41.0, mon).map == "yumachi", "and home through Yumachi after")
	var nights := {"mon": ["genzo", "shino", "tome"], "tue": ["hachiro", "sayo"], "wed": ["ichiro", "shino"], "thu": [], "fri": ["hachiro", "ren", "tome"], "sat": ["genzo", "ren", "sayo"], "sun": ["ichiro"]}
	for i in g.WEEKDAYS.size():
		var day: String = g.WEEKDAYS[i]
		var s := mon.merged({"weekday": day, "day": i + 1}, true)
		var seen := []
		for m in range(17 * 60, 23 * 60, 5):
			for w in Villagers.on_map("sento_bath", float(m), s):
				if w.has("seat_cell") and not w.id in seen:
					seen.append(w.id)
		seen.sort()
		check(seen == nights[day], "%s: in the bath %s (%s)" % [day, nights[day], seen])
		var inside := true
		for m in range(17 * 60, 23 * 60, 5):
			if not Villagers.bath_seats("sento_bath", float(m), s).is_empty():
				inside = inside and m >= 14 * 60 and m < 23 * 60
		check(inside, "%s: only while the bath is open" % day)
	check(Villagers.on_map("sento_bath", t, mon.merged({"weather": "rain"}, true)).is_empty(), "a wet Monday: no one comes")
	# Every seat of a night apart, whoever overlaps.
	for i in g.WEEKDAYS.size():
		var s := mon.merged({"weekday": g.WEEKDAYS[i], "day": i + 1}, true)
		var clash := false
		for m in range(17 * 60, 23 * 60, 2):
			clash = clash or Villagers.bath_seats("sento_bath", float(m), s).size() != Villagers.on_map("sento_bath", float(m), s).filter(func(w): return w.has("seat_cell")).size()
		check(not clash, "%s: no two bathers on one seat" % g.WEEKDAYS[i])
	# The ones the farmer can marry come on their own nights while single; once married only on the spouse's nights, at the sixth cell.
	for id in ["sayo", "shino", "ren"]:
		var seen := false
		var wed := false
		for i in g.WEEKDAYS.size():
			var s := mon.merged({"weekday": g.WEEKDAYS[i], "day": i + 1}, true)
			var m := mon.merged({"weekday": g.WEEKDAYS[i], "day": i + 8, "flags": {"married_" + id: true, "spouse": id}}, true)
			for x in range(17 * 60, 23 * 60, 5):
				seen = seen or Villagers.where(id, float(x), s).has("seat_cell")
				var mw := Villagers.where(id, float(x), m)
				wed = wed or (mw.has("seat_cell") and (mw.seat_cell != Vector2i(6, 3) or not g.WEEKDAYS[i] in ["tue", "sat"]))
		check(seen and not wed, "%s bathes on their own nights while single, not once married" % id)
	check(Villagers.on_map("sento_bath", t, mon.merged({"season": "winter"}, true)).map(func(w): return w.id).has("tome"), "Tome comes in winter too")
	var fests := ["blossom_day", "lantern_night", "moon_night", "years_turn"]
	for i in fests.size():
		var fest: String = fests[i]
		var none := true
		for m in range(14 * 60, 23 * 60, 10):   # a day of its own: the day's plans are kept by the date (and a festival comes with its date)
			none = none and Villagers.on_map("sento_bath", float(m), mon.merged({"festival": fest, "day": 22 + i}, true)).is_empty()
		check(none, "%s: the bath shut, no bathers" % fest)
	# Every bathe step in every plan sits before a tub.
	for id in Villagers.all():
		for name in Villagers.all()[id].plans:
			for e in Villagers.all()[id].plans[name]:
				for step in e.get("route", []) + e.get("loop", []):
					if step.has("bathe"):
						check(e.map == "sento_bath", "%s %s bathes on the bath's map" % [id, name])
	# Married: the spouse goes on sunny Tuesdays and Saturdays, to the sixth cell, the child stays home.
	var spouses := ["fumi", "haru", "ichiro", "kaede", "mio", "ren", "sayo", "shino"]
	for k in spouses.size():
		var id: String = spouses[k]
		var f := {"married_" + id: true, "spouse": id}
		var tue := mon.merged({"weekday": "tue", "day": 2 + 7 * (k % 3), "flags": f}, true)
		var w := Villagers.where(id, 19 * 60 + 45.0, tue)
		check(w.get("seat_cell", Vector2i(-1, -1)) == Vector2i(6, 3), "married to %s: in the bath at 19:45 on a sunny Tuesday, the sixth cell (%s)" % [id, w])
		var sat := tue.merged({"weekday": "sat", "day": 6 + 7 * (k % 3)}, true)
		check(Villagers.where(id, 19 * 60 + 45.0, sat).has("seat_cell"), "and on Saturday")
		check(not Villagers.where(id, 19 * 60 + 45.0, tue.merged({"weekday": "wed", "day": 3 + 7 * (k % 3)}, true)).has("seat_cell"), "%s: not on Wednesday" % id)
		check(not Villagers.where(id, 19 * 60 + 45.0, tue.merged({"weather": "rain"}, true)).has("seat_cell"), "%s: not on a wet Tuesday" % id)
		for d in [tue, sat]:
			var clash := false
			for m in range(17 * 60, 23 * 60, 2):
				clash = clash or Villagers.bath_seats("sento_bath", float(m), d).size() != Villagers.on_map("sento_bath", float(m), d).filter(func(x): return x.has("seat_cell")).size()
			check(not clash, "married to %s, %s: no two bathers on one seat" % [id, d.weekday])
		var ts := {"band": 6, "again": false, "day_number": 0}
		check(Talk.pick(id, ts.merged(tue, true).merged({"time": 19 * 60 + 45, "map": "sento_bath"}, true)).begins_with("wed_bath_"), "%s says a spouse's line at the bath" % id)
		check(Talk.pick(id, ts.merged(tue, true).merged({"time": 17 * 60, "map": "house"}, true)) == "wed_bath_invite", "%s asks the farmer along at home on a bath night" % id)
		check(Talk.pick(id, ts.merged(tue, true).merged({"weekday": "wed", "time": 17 * 60, "map": "house"}, true)) != "wed_bath_invite", "%s: not on another night" % id)
		for l in Talk.data(id).lines:
			if str(l.get("id", "")).begins_with("wed_bath"):
				check(Lang.table("th").has(str(l.text)), "%s's %s in Thai" % [id, l.id])
	# "Let's go together": the spouse walks with the farmer, behind them along their path, through the
	# doors, into the bath beside them once the farmer goes in to change, and home after (Companion).
	var inv: Dictionary = Talk.data("shino").lines.filter(func(l): return l.get("id", "") == "wed_bath_invite")[0]
	check(inv.get("choices", []).size() == 2 and inv.choices[0].get("set", {}).get(g.BATH_TOGETHER_FLAG, "") == "yes", "the ask has a choice: together, or not tonight")
	check(Talk.pick("shino", {"band": 6, "again": true, "day_number": 0, "time": 17 * 60 + 30, "map": "house"}.merged(mon.merged({"weekday": "tue", "day": 2, "flags": {"married_shino": true, "spouse": "shino"}}, true), true)) == "wed_bath_invite",
		"asked even after an earlier talk that day")
	g.day = 1
	while g.weekday() != "tue" or g.festival_today() != "":
		g.day += 1
	g.weather_today = "sunny"
	g.flags["married_shino"] = true
	g.flags["spouse"] = "shino"
	g.bath_paid_today = false
	g.go_to_map("house", Vector2i(4, 4), Vector2i.UP)
	g.hour = 17
	g.minute = 30
	g.flags[g.BATH_TOGETHER_FLAG] = "no"
	g.dialogue_closed("talk_shino")
	check(g.maps.id == "house" and not g.flags.has(g.BATH_TOGETHER_FLAG), "not tonight: still at home")
	g.flags[g.BATH_TOGETHER_FLAG] = "yes"
	g.dialogue_closed("talk_shino")
	var st: Dictionary = g.trigger_state(Vector2i.ZERO)
	check(g.maps.id == "house" and g.hour == 17 and g.minute == 30 and g.bath_paid_today and Companion.has("shino") and Companion.phase == "walk",
		"together: no jump, Shino comes along from here, the ticket paid (%s %d:%02d)" % [g.maps.id, g.hour, g.minute])
	var gap := float(b.get("together", {}).get("gap", 1.2)) if b.has("together") else float(g.baths.together.gap)
	var feet := Vector2(4.5, 4.5)
	Companion.track("house", feet, 1050.0, st)
	var far := 0.0
	var ok_gap := true
	for k in 40:   # the farmer walks right, then down
		feet += Vector2(0.1, 0.0) if k < 20 else Vector2(0.0, 0.1)
		Companion.track("house", feet, 1050.0, st)
		var w := Villagers.where("shino", 1050.0, st)
		far = maxf(far, Vector2(w.pos).distance_to(feet))
		ok_gap = ok_gap and w.map == "house" and w.companion
	var w1 := Villagers.where("shino", 1050.0, st)
	check(ok_gap and far <= gap + 1.5 and w1.moving and w1.facing == Vector2i.DOWN, "Shino walks behind, turning down after the farmer (%s, farthest %.2f)" % [w1, far])
	Companion.track("house", feet, 1050.0, st)
	check(not Villagers.where("shino", 1050.0, st).moving, "the farmer stops, so does Shino")
	var her: Vector2 = Villagers.where("shino", 1050.0, st).pos
	check(not Villagers.blocks("house", 1050.0, st, feet, her) and not Villagers.near("house", 1050.0, st, her), "no blocking the farmer turning back past her")
	# Back and forth (the user saw them walk backwards after the farmer): they only ever step toward
	# the farmer, facing the way they go, and stand facing the farmer once they are close.
	var away := false
	var backwards := false
	var crowd := false
	for leg in [[Vector2.RIGHT, 30], [Vector2.LEFT, 45], [Vector2.LEFT, 30], [Vector2.RIGHT, 15], [Vector2.LEFT, 15]]:
		for k in int(leg[1]):
			var before: Vector2 = Villagers.where("shino", 1050.0, st).pos
			feet += Vector2(leg[0]) * 0.1
			Companion.track("house", feet, 1050.0, st)
			var w := Villagers.where("shino", 1050.0, st)
			var step: Vector2 = Vector2(w.pos) - before
			if step.length() > 0.001:
				away = away or step.dot(feet - before) <= 0.0
				backwards = backwards or step.dot(Vector2(w.facing)) <= 0.0
				crowd = crowd or Vector2(w.pos).distance_to(feet) < 1.0
	# Turned round to talk to her, then on through her to the other side (the user's case): after the
	# talk she walks after the farmer facing her way, never sliding along turned back to the talk.
	var her_at: Vector2 = Villagers.where("shino", 1050.0, st).pos
	feet = her_at + Vector2(0.8, 0.0)
	Companion.track("house", feet, 1050.0, st)
	Villagers.turn("shino", Vector2i.RIGHT, 1050.0)   # the talk: she turns to the farmer on her right
	var slid := false
	var walked_on := false
	for k in 40:   # the farmer walks left, through her and on
		var before: Vector2 = Villagers.where("shino", 1050.0, st).pos
		feet += Vector2.LEFT * 0.1
		Companion.track("house", feet, 1050.0, st)
		var w := Villagers.where("shino", 1050.0, st)
		var step: Vector2 = Vector2(w.pos) - before
		if step.length() > 0.001:
			walked_on = true
			slid = slid or not w.moving or step.dot(Vector2(w.facing)) <= 0.0
	check(walked_on and not slid, "after a talk, through her and on: she walks after the farmer facing the way she goes")
	# Stopping again after the talk she faces the farmer, never back the way she faced in the talk
	# (the user: she kept turning back to it every time she stopped).
	var stood: Vector2 = Villagers.where("shino", 1050.0, st).pos
	feet = stood + Vector2(0.0, 0.9)   # the farmer just below her, within the gap
	Companion.track("house", feet, 1050.0, st)
	var w2 := Villagers.where("shino", 1050.0, st)
	check(not w2.moving and w2.facing == Vector2i.DOWN, "stood after the talk: facing the farmer below, not the talk's right (%s)" % w2.facing)
	feet = stood + Vector2(-0.9, 0.0)
	Companion.track("house", feet, 1050.0, st)
	check(Villagers.where("shino", 1050.0, st).facing == Vector2i.LEFT, "and to the left when the farmer is there")
	check(not away and not backwards and not crowd, "back and forth: never walking away from the farmer, backwards, or on into them (%s %s %s)" % [away, backwards, crowd])
	Companion.track("farm", Vector2(4.5, 5.5), 1060.0, st)
	var on_farm := Villagers.where("shino", 1060.0, st)
	check(on_farm.map == "farm" and Vector2(on_farm.pos).distance_to(Vector2(4.5, 5.5)) < 0.01, "out of the door behind the farmer (%s)" % on_farm)
	Companion.track("yumachi", Vector2(7.5, 5.5), 1150.0, st)
	check(Villagers.where("shino", 1150.0, st).map == "yumachi", "all the way to Yumachi")
	Companion.track("sento_changing", Vector2(1.5, 3.5), 1160.0, st)
	check(Companion.phase == "bath" and Villagers.where("shino", 1161.0, st).map == DayPlan.AWAY, "the farmer goes in to change: so does Shino")
	var in_bath := {}
	for m in range(1163, 1240):
		var w := Villagers.where("shino", float(m), st)
		if w.has("seat_cell") and float(w.bathed) > 5.0:
			in_bath = w
			break
	check(not in_bath.is_empty() and in_bath.map == "sento_bath" and in_bath.seat_cell == Vector2i(6, 3) and in_bath.bath_pose == "bathe", "Shino in the water at the sixth cell (%s)" % in_bath)
	# She stays in the water as long as the farmer (the user: she got up and left on her own, as if
	# strangers), gets out with them saying so, dresses, and walks home with them.
	Companion.track("sento_bath", Vector2(5.5, 3.5), 1200.0, st, true)
	Companion.track("sento_bath", Vector2(5.5, 3.5), 1290.0, st, true)
	var still: Dictionary = Villagers.where("shino", 1290.0, st)
	check(Companion.phase == "bath" and still.get("bath_pose", "") == "bathe", "an hour and a half on, the farmer still in: so is she (%s)" % still)
	Companion.track("sento_bath", Vector2(5.5, 3.5), 1290.5, st, false)
	check(Companion.phase == "dress" and Companion.say == "wed_bath_out", "the farmer gets out: so does she, saying so (%s %s)" % [Companion.phase, Companion.say])
	Companion.say = ""
	var rising := Villagers.where("shino", 1293.0, st)
	check(rising.map == "sento_bath" and rising.has("seat_cell") and Vector2(rising.pos).y > 2.6 and str(rising.bath_pose) == "walk" and rising.facing == Vector2i.DOWN, "rising out of the water beside the farmer (%s)" % rising)
	var hop := 0.0
	var last_w: Dictionary = Villagers.where("shino", 1290.5, st)
	var mm := 1290.5
	while mm < 1298.0:
		mm += 0.05
		var now_w: Dictionary = Villagers.where("shino", mm, st)
		if now_w.map == last_w.map:
			hop = maxf(hop, Vector2(now_w.pos).distance_to(last_w.pos))
		last_w = now_w
	check(hop < 0.15, "out of the tub and off to the door with no jump (%.3f)" % hop)
	Companion.track("sento_changing", Vector2(1.5, 3.5), 1310.0, st)
	check(Companion.phase == "dress", "the farmer still changing: she waits dressed")
	Companion.track("sento", Vector2(5.5, 4.5), 1311.0, st)
	var lobby := Villagers.where("shino", 1311.0, st)
	check(Companion.phase == "walk_back" and lobby.map == "sento" and Vector2(lobby.pos).distance_to(Companion.NOREN) < 0.3, "out of the noren behind the farmer in the lobby (%s)" % lobby)
	Companion.track("yumachi", Vector2(7.5, 5.5), 1313.0, st)
	Companion.track("town", Vector2(54.5, 29.5), 1320.0, st)
	check(Villagers.where("shino", 1320.0, st).map == "town", "walking home through the village with the farmer")
	Companion.track("house", Vector2(4.5, 4.5), 1340.0, st)
	check(Companion.phase == "walk_back" and Villagers.where("shino", 1340.0, st).map == "house", "in at the farmhouse door behind them")
	Companion.track("house", Vector2(4.5, 3.2), 1340.0, st)
	var home := Villagers.where("shino", 1340.0, st)
	check(Companion.phase == "settled" and Companion.say == "wed_bath_home" and home.map == "house" and not home.moving, "home: she stays in and says so (%s %s)" % [Companion.phase, Companion.say])
	Companion.say = ""
	for l in ["wed_bath_out", "wed_bath_home"]:
		check(Talk.has_line("shino", l), "Shino's %s" % l)
	Companion.clear()
	g.flags[g.BATH_TOGETHER_FLAG] = "yes"
	g.dialogue_closed("talk_shino")
	g.end_day()
	check(Companion.id == "", "the night ends the walk")
	g.flags.erase("married_shino")
	g.flags.erase("spouse")
	var fam := {"married_sayo": true, "spouse": "sayo", Child.BORN: 1, Child.STAGE: "child", "child_name": "Sora"}
	var fam_day := mon.merged({"year": 3, "weekday": "tue", "day": 2, "flags": fam}, true)
	var tagged := false
	for m in range(19 * 60, 21 * 60, 3):
		var c := Villagers.where(Child.ID, float(m), fam_day)
		tagged = tagged or str(c.get("map", "")) in ["yumachi", "sento", "sento_changing", "sento_bath"]
	check(Villagers.where("sayo", 19 * 60 + 45.0, fam_day).has("seat_cell") and not tagged, "the child stays home while Sayo bathes")
	# The farmer kept off a taken seat, a free one fine.
	var said: Array[String] = []
	var hear := func(x: String): said.append(x)
	g.message.connect(hear)
	g.day = 1
	while g.weekday() != "mon" or g.festival_today() != "":
		g.day += 1
	g.weather_today = "sunny"
	g.go_to_map("sento_bath", Vector2i(5, 3), Vector2i.UP)
	g.hour = 19
	g.minute = 22
	g.soak(Vector2i(5, 3), Vector2i.UP)
	check(not g.soaking() and said.back() == String(b.taken_message), "Tome's seat taken: %s" % said.back())
	g.soak(Vector2i(6, 3), Vector2i.UP)
	check(g.soaking(), "the cell beside her free")
	g._stand_up_now()
	# Sat beside a bather, the farmer sees them still there, then get out when their time is up (the
	# user's report: Ren was gone the moment the farmer got in, the hour jumped at once).
	g.day = 1
	while g.weekday() != "sat" or g.festival_today() != "":
		g.day += 1
	g.bathed_today = false
	g.go_to_map("sento_bath", Vector2i(7, 3), Vector2i.UP)
	g.hour = 20
	g.minute = 0
	g.soak(Vector2i(7, 3), Vector2i.UP)
	var ren_in := func() -> bool: return Villagers.bath_seats("sento_bath", g.day_minutes(), g.trigger_state(Vector2i(7, 3))).values().has("ren")
	check(g.soaking() and g.hour == 20 and ren_in.call(), "in beside Ren at 20:00: he is still there")
	g._process(float(b.sit_seconds) + 0.05)
	g.clock_running = true
	g._process(g.SECONDS_PER_MINUTE * 15.0 + 0.01)
	check(g.minute == 15 and ren_in.call(), "a quarter of an hour on, still soaking with him (20:%02d)" % g.minute)
	g.clock_running = false
	g.stop_soak()
	g._process(float(b.stand_seconds) + 0.05)
	check(not g.soaking() and g.minute == 15 and ren_in.call(), "getting out: Ren still in the water, no jump of the clock (20:%02d)" % g.minute)
	g.soak(Vector2i(7, 3), Vector2i.UP)
	g._process(float(b.sit_seconds) + 0.05)
	g.clock_running = true
	for k in 400:   # frame by frame, as the game runs: a bump is judged each frame
		g._process(g.SECONDS_PER_MINUTE * 20.0 / 400.0)
	check(not ren_in.call() and Villagers.where("ren", g.day_minutes(), g.trigger_state(Vector2i(7, 3))).get("map", "") != "", "past 20:29 he has got out (20:%02d)" % g.minute)
	# On his way to the door he passes in front of the farmer sat in the tub (whose spot is the tiles
	# before it): he walks on, no stopping to wait (the user saw bathers stand still for ten seconds).
	for k in 120:
		g._process(g.SECONDS_PER_MINUTE * 6.0 / 120.0)
	check(Villagers.where("ren", g.day_minutes(), g.trigger_state(Vector2i(7, 3))).get("map", "") != "sento_bath" and Villagers.delay_of("ren", g.day_minutes()) == 0.0,
		"by 20:41 he is out of the room, never held up by the farmer in the tub (20:%02d, %s, delay %.1f)" % [g.minute, Villagers.where("ren", g.day_minutes(), g.trigger_state(Vector2i(7, 3))).get("map", ""), Villagers.delay_of("ren", g.day_minutes())])
	g.clock_running = false
	g._stand_up_now()
	g.message.disconnect(hear)
	# Their lines at the bath, in Thai.
	var th := Lang.table("th")
	for id in ["tome", "genzo", "hachiro", "ichiro", "sayo", "shino", "ren"]:
		var at := Talk.pick(id, {"band": 2, "again": false, "day_number": 0, "time": 19 * 60, "map": "sento_bath"}.merged(mon, true))
		check(at.begins_with("bath_") and not at.begins_with("bath_close"), "%s says a bath line there (%s)" % [id, at])
		check(not Talk.pick(id, {"band": 2, "again": false, "day_number": 0, "time": 19 * 60, "map": "town"}.merged(mon, true)).begins_with("bath_"), "%s: not elsewhere" % id)
	for id in ["sayo", "shino", "ren"]:
		var at := Talk.pick(id, {"band": 4, "again": false, "day_number": 0, "time": 19 * 60, "map": "sento_bath"}.merged(mon, true))
		check(at.begins_with("bath_close_"), "%s closer from band 4 (%s)" % [id, at])
	for id in ["tome", "genzo", "hachiro", "ichiro", "sayo", "shino", "ren"]:
		for l in Talk.data(id).lines:
			if str(l.get("id", "")).begins_with("bath_"):
				check(th.has(str(l.text)), "%s's %s in Thai" % [id, l.id])
	# The 3D sprite raised to the water.
	g.go_to_map("sento_bath", Vector2i(6, 3), Vector2i.UP)
	g.day = 1   # a Monday again: Tome's night
	while g.weekday() != "mon" or g.festival_today() != "":
		g.day += 1
	g.hour = 19   # the farmer's bath ran the clock on an hour
	g.minute = 22
	var vs: Node3D = load("res://scripts/world3d/villager_sprites.gd").new("sento_bath")
	root.add_child(vs)
	vs.refresh()
	check(vs.shown().has("tome"), "Tome shown in 3D")
	var sp: Sprite3D = vs._sprites.get("tome")
	check(sp != null and is_equal_approx(sp.position.y, float(b.lift)), "her sprite at the water's height (%s)" % [sp.position if sp != null else null])
	vs.queue_free()
	g.new_game()
	g.clock_running = false


## Kajika-yu, the rock pool up the gorge (Baths step 4).
func _kajika() -> void:
	var said: Array[String] = []
	var hear := func(t: String): said.append(t)
	g.message.connect(hear)
	var k: Dictionary = g.baths.get("kajika", {})
	check(str(k.get("day", "")) == "bath" and int(k.get("minutes", 0)) == 90 and bool(k.get("stamina_full", false)) and int(k.get("fatigue", 0)) == -30, "Kajika-yu: the baths' day, 1.5 h, stamina full, -30 (DESIGN)")
	check(int(k.fatigue) > -42 and int(k.fatigue) < int(_sento().fatigue), "more than the sento, never a night's sleep")
	check(is_equal_approx(float(k.lift), BP.ONSEN_WATER), "sat at the pool's water, sunk with the map's (%.2f)" % float(k.lift))
	check(k.get("hours") == ["16:00", "02:00"] and bool(k.get("towel", false)), "open 16:00-02:00, in a towel")
	check(not g.bath_open(k, 15 * 60 + 59.0) and g.bath_open(k, 16 * 60.0) and g.bath_open(k, 25 * 60 + 59.0) and not g.bath_open(k, 26 * 60.0), "its hours run on past midnight to 02:00")
	var gorge: MapData = MapManager.data("kajika")
	var m: MapData = MapManager.data("kajika_yu")
	var river: MapData = MapManager.data("river")
	check(gorge != null and not gorge.indoor and gorge.towel == "" and not gorge.props.any(func(p): return str(p.get("use", "")) == "soak"), "the gorge only the way along the river (no pool, no towels)")
	check(m != null and not m.indoor and m.towel == "allowed" and m.name == "Kajika-yu", "the hot spring's clearing outdoors, a towel allowed")
	check(WorldPlan.places().get("kajika") == Vector2i(-40, 20) and WorldPlan.places().get("kajika_yu") == Vector2i(-60, 6), "the gorge at [-40, 20] west of the river map, the clearing at [-60, 6] west of the gorge")
	var into: Dictionary = gorge.door_at(Vector2i(-1, 5))
	check(into.get("to", "") == "kajika_yu", "the gorge's path runs on west into the wood to the clearing")
	var pool := m.props.filter(func(p): return p.kind == "onsen")
	check(pool.size() == 1 and str(pool[0].get("use", "")) == "soak" and str(pool[0].get("bath", "")) == "kajika" and str(pool[0].get("seats", "")) == "shore", "the hot spring, a soak of its own, in from its shore")
	var shape := PondShape.of(m, "onsen")
	check(shape != null and shape.cells.size() >= 70 and m.props[0] == pool[0], "its water a soft pond of look onsen (%d cells), the prop first so E finds it" % (shape.cells.size() if shape != null else 0))
	var spots: Array = g.soak_spots(pool[0], m)
	check(spots.size() >= 10 and spots.all(func(s): return m.tile(s[0]) != "water" and not m.is_solid(s[0]) and m.tile(s[0] + s[1]) == "water"), "in from all round its shore (%d spots), each a dry open cell facing its water" % spots.size())
	check(spots.has([Vector2i(9, 12), Vector2i.UP]) and spots.has([Vector2i(13, 11), Vector2i.LEFT]), "from the path's end below it and from its east bank")
	# After the user's photo: a big pool shut in by the wood, boulders standing in its water, the hut
	# at the back past the water, never between the eye (south-east) and the pool.
	var rocks_in := m.props.filter(func(p): return p.kind == "garden_rock" and str(p.get("shape", "")) == "boulder" and m.tile(Vector2i(p.cell)) == "water")
	check(rocks_in.size() >= 3, "big mossy boulders standing in the water (%d)" % rocks_in.size())
	var hut: Array = m.props.filter(func(p): return str(p.get("use", "")) == "change")
	check(hut.size() == 1 and hut[0].kind == "bath_pavilion" and Vector2i(hut[0].cell).y + Vector2i(hut[0].size).y <= shape.bounds.position.y + 1, "the changing house (the user's second photo) at the back of the clearing, past the water")
	var lamp: Array = m.props.filter(func(p): return p.kind == "yukimi_doro")
	check(lamp.size() == 1 and m.tile(Vector2i(lamp[0].cell)) == "water", "the snow-viewing lantern on its rock out in the water")
	check(m.props.filter(func(p): return str(p.get("shape", "")) == "granite").size() >= 4, "pale granite on the shores")
	check(m.tile(Vector2i(m.w - 1, 7)) == "water" and m.look(Vector2i(m.w - 1, 7)) == "onsen" and shape.cells.has(Vector2i(m.w - 1, 8)), "the creek running in from the east edge, one water with the pool")
	var behind := m.props.filter(func(p): return p.kind in ["maple", "sakura", "pine"] and Vector2i(p.cell).y <= 3).size()
	var before := m.props.filter(func(p): return p.kind in ["maple", "sakura", "pine"] and Rect2i(6, 12, 9, 8).has_point(Vector2i(p.cell))).size()
	# Every place the bather needs reached on foot from the way in (the user could not walk to the hut).
	var seen := {Vector2i(19, 18): true}
	var todo: Array[Vector2i] = [Vector2i(19, 18)]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n2: Vector2i = c + d
			if m.in_bounds(n2) and not m.is_solid(n2) and not seen.has(n2):
				seen[n2] = true
				todo.append(n2)
	var hut_front := Vector2i(int(hut[0].cell.x) + int(hut[0].size.x) / 2, int(hut[0].cell.y) + int(hut[0].size.y))
	check(seen.has(hut_front) and seen.has(Vector2i(9, 12)) and seen.has(Vector2i(13, 11)), "the hut's door step, the path's end and the east bank all reached on foot from the way in")
	var clipped := m.props.filter(func(p): return p.kind == "shrub" and not bool(p.get("wild", false))).size()
	check(clipped == 0, "wild undergrowth, no clipped garden shrubs (their flowers read as pink stains, the user saw)")
	check(behind >= 20 and before == 0, "a thick wood behind the pool (%d trees), none between the south shore and the eye (%d)" % [behind, before])
	# Part 2 of the user's photo: the wood close round it, lanterns, the bucket and towel.
	var near := func(kind: String) -> int: return m.props.filter(func(p): return p.kind == kind and Rect2i(0, 0, 20, 14).has_point(Vector2i(p.cell))).size()
	check(near.call("maple") >= 3 and m.props.filter(func(p): return p.kind == "shrub" and bool(p.get("wild", false))).size() >= 15 and near.call("stone_lantern") >= 3 and near.call("oke") == 1, "maples, wild undergrowth (rough bushes), lanterns and the bucket close round the pool")
	check(not (VistaRules.apron_trees("kajika_yu") as Dictionary).is_empty(), "a broadleaf wood past the clearing's edges")
	check(m.props.any(func(p): return p.kind == "bath_pavilion" and str(p.get("use", "")) == "change"), "the changing house to change in")
	var way: Dictionary = river.door_at(Vector2i(-1, 4))
	check(way.get("to", "") == "kajika" and str(way.get("needs", "")) == "kajika_built" and str(way.get("locked", "")) != "", "the shore path up the gorge needs the pool built")
	var back: Dictionary = m.door_at(Vector2i(20, 18))
	check(back.get("to", "") == "kajika" and bool(back.get("dressed", false)), "the way back only dressed")
	# Shut until it is built, then through.
	g.flags.erase("kajika_built")
	g.go_to_map("river", Vector2i(0, 4), Vector2i.LEFT)
	g.use_door(way)
	check(g.maps.id == "river" and said.back() == str(way.locked), "shut before the pool is made, and says why")
	check(not g.door_unlocked(way), "locked by the story")
	g.flags["kajika_built"] = true
	g.use_door(way)
	check(g.maps.id == "kajika" and Vector2i(g.maps.pos / 16.0) == Vector2i(19, 5), "built: up the gorge (%s)" % g.maps.pos)
	g.use_door(into)
	check(g.maps.id == "kajika_yu" and Vector2i(g.maps.pos / 16.0) == Vector2i(19, 18), "on into the clearing (%s)" % g.maps.pos)
	# The pool: shut by day, in a towel only, then the rest.
	var seat := Vector2i(9, 12)
	g.bathed_today = false
	g.hour = 12
	g.minute = 0
	g.go_to_map("kajika_yu", seat, Vector2i.UP)
	FA.on_action("interact", seat, Vector2i.UP)
	check(not g.soaking() and said.back() == str(k.closed_message), "shut at midday")
	g.hour = 20
	FA.on_action("interact", seat, Vector2i.UP)
	check(not g.soaking() and said.back() == str(k.towel_message) and not g.bathed_today, "dressed: change at the hut first")
	g.go_to_map("kajika_yu", Vector2i(4, 3), Vector2i.UP)
	FA.on_action("interact", Vector2i(4, 3), Vector2i.UP)
	check(g.in_towel and g.wearing_towel(), "the hut: into a towel")
	g.use_door(back)
	check(g.maps.id == "kajika_yu", "not out in a towel")
	g.go_to_map("kajika_yu", seat, Vector2i.UP)
	check(g.in_towel, "a towel kept in the clearing")
	g.stamina = 10
	g.fatigue = 60
	FA.on_action("interact", seat, Vector2i.UP)
	check(g.soaking() and g.bathed_today and g.stamina == g.max_stamina and g.fatigue == 30 and g.soak_owed == 90, "in: stamina full, -30, 90 minutes owed (%d / %d)" % [g.stamina, g.fatigue])
	check(said.back() == str(k.message), "says the pool")
	g._process(float(k.sit_seconds) + 0.05)
	check(g.still_pose() == "bathe" and g.soak_look() == Vector2i.DOWN and is_equal_approx(g.soak_lift(true), float(k.lift)), "sat in the water, turned to the eye")
	g.stop_soak()
	g._process(float(k.stand_seconds) + 0.05)
	g.go_to_map("kajika_yu", Vector2i(13, 11), Vector2i.LEFT)
	FA.on_action("interact", Vector2i(13, 11), Vector2i.LEFT)
	check(g.soaking() and g.soak_at == Vector2i(13, 11) and g.soak_facing == Vector2i.LEFT, "in from the east bank too")
	g.stop_soak()
	g._process(float(k.stand_seconds) + 0.05)
	check(not g.soaking(), "out again")
	# The day's bath is shared with the sento's.
	g.go_to_map("kajika_yu", seat, Vector2i.UP)
	var st: int = g.stamina
	g.stamina = 10
	FA.on_action("interact", seat, Vector2i.UP)
	check(g.soaking() and g.stamina == 10 and said.back() == str(k.again_message), "a second bath the same day only rests")
	g.stop_soak()
	g._process(float(k.stand_seconds) + 0.05)
	g.stamina = st
	g.go_to_map("kajika_yu", Vector2i(4, 3), Vector2i.UP)
	FA.on_action("interact", Vector2i(4, 3), Vector2i.UP)
	check(not g.in_towel, "dressed again at the hut")
	g.use_door(back)
	check(g.maps.id == "kajika", "dressed: back down to the gorge")
	g.flags.erase("kajika_built")
	g.message.disconnect(hear)
	# 3D: every kind built, the pool's steam over its water.
	var world: Node3D = load("res://scripts/world3d/map_world.gd").new()
	root.add_child(world)
	world.build(m)
	var steam := world.get_children().filter(func(n): return str(n.name).begins_with("BathSteam"))
	var hot := (MistRules.scene_of(m).kinds as Array).count("onsen")
	check(steam.is_empty() and hot >= 70, "its steam the mist's soft sheets over every water cell (%d), no round puffs (%d)" % [hot, steam.size()])
	world.queue_free()
	for kind in GORGE_KINDS:
		check(MV.COLORS.has(kind) and kind in BP.KINDS, "%s drawn in both views" % kind)
