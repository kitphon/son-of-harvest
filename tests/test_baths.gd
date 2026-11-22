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
## (BathLook, MapView.COLORS). Run:
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
	_entry()
	_bath()
	_pose()
	_views()
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


## The door under the shop's hours, and the fee once a day.
func _entry() -> void:
	var said: Array[String] = []
	var hear := func(t: String): said.append(t)
	g.message.connect(hear)
	var door: Dictionary = MapManager.data("yumachi").door_at(Vector2i(7, 4))
	g.maps.place("yumachi", Vector2i(7, 5), Vector2i.UP)
	g.day = 1
	while g.weekday() == "thu" or g.festival_today() != "":
		g.day += 1
	g.hour = 11
	g.money = 1000
	g.use_door(door)
	check(g.maps.id == "yumachi" and g.money == 1000 and said.back() == g.shop("sento").closed_text(), "shut before two: the hours said, nothing paid")
	g.hour = 15
	g.use_door(door)
	check(g.maps.id == "sento" and g.money == 880 and g.bath_paid_today, "open: in, 120 G paid")
	check(said.back() == String(g.shop("sento").own().entry_message) % 120, "says the fee")
	g.go_to_map("yumachi", Vector2i(7, 5), Vector2i.UP)
	g.use_door(door)
	check(g.maps.id == "sento" and g.money == 880, "back in the same day for nothing")
	g.go_to_map("yumachi", Vector2i(7, 5), Vector2i.UP)
	var d: Dictionary = g.to_dict()
	check(d.get("bath_paid_today", null) == true, "the day's ticket saved")
	g.bath_paid_today = false
	check(g.from_dict(d) == "" and g.bath_paid_today, "and loaded")
	d.erase("bath_paid_today")
	check(g.from_dict(d) == "" and not g.bath_paid_today, "an older save: not paid yet")
	g.maps.place("yumachi", Vector2i(7, 5), Vector2i.UP)
	g.money = 100
	g.use_door(door)
	check(g.maps.id == "yumachi" and g.money == 100 and said.back() == String(g.shop("sento").own().entry_short) % 120, "short of 120 G: the door stays shut")
	g.money = 1000
	g.bath_paid_today = true
	g.end_day()
	check(not g.bath_paid_today and not g.bathed_today, "a new day: a new ticket")
	g.maps.place("yumachi", Vector2i(7, 5), Vector2i.UP)
	g.hour = 15
	while g.weekday() != "thu":
		g.day += 1
	g.use_door(door)
	check(g.maps.id == "yumachi" and not g.bath_paid_today, "shut on Thursday")
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
	check(g.hour == 17 and g.minute == 0, "an hour gone in the water, though the clock stands indoors (%d:%02d)" % [g.hour, g.minute])
	check(said.back() == String(b.message), "says the bath")
	check(g.soak_look() == Vector2i.UP and g.still_pose() == "walk", "stepping up to the tub, back to the eye")
	g._process(float(b.sit_seconds) + 0.05)
	check(g.soak_phase == "sit" and g.still_pose() == "bathe" and g.soak_look() == Vector2i.DOWN, "sat in the water, turned to face the room")
	check(is_equal_approx(g.soak_seat(true), float(b.seat)) and is_equal_approx(g.soak_lift(true), float(b.lift)), "a cell into the tub, at the water's height")
	check(not g.feet_in(), "no footbath water band in a bath")
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
	g._process(float(b.stand_seconds) + 0.05)
	check(not g.soaking() and g.soak_cfg == g.ashiyu, "out and free; the next soak names its own")
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
