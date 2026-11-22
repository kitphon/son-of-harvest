extends SceneTree
## Headless checks for the public bath, Kawasemi-yu (Baths step 2; docs/DESIGN.md → ที่อาบน้ำ):
## data/baths.json and the sento's shop (hours 14:00-23:00, shut on Thursdays and festival days,
## the 120 G paid once a day at the street door: Game.pay_entry, bath_paid_today, saved), the map
## data/maps/sento.json (the lobby and the bath through the noren, every floor cell reachable from
## the door, the counter, the tub's seats before its front), getting into the tub (Game.soak with the
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


func _map() -> void:
	var m: MapData = MapManager.data("sento")
	check(m != null and m.indoor and m.name == "Kawasemi-yu" and Vector2i(m.w, m.h) == Vector2i(15, 8), "the bath's inside, 15 x 8, indoors")
	var kinds := {}
	for p in m.props:
		kinds[str(p.kind)] = p
	for k in BP.KINDS:
		check(kinds.has(k), "the bath has its %s" % k)
	check(str(kinds.counter.get("shop", "")) == "sento", "the counter is the sento's shop")
	check(not m.is_solid(Vector2i(kinds.bath_noren.cell)), "the noren hangs in the doorway, walked through")
	var tub: Dictionary = kinds.yubune
	check(str(tub.get("use", "")) == "soak" and str(tub.get("bath", "")) == "sento" and int(tub.cell[1]) == 1, "the tub along the back wall, a bath to soak in")
	check(Vector2i(kinds.bath_mural.cell).y == 0 and int(kinds.bath_mural.cell[0]) == int(tub.cell[0]), "the mountain painted on the wall over the tub")
	# Every floor cell reached from the door, the bath's included (through the noren).
	var start := Vector2i(m.spawns.start[0][0], m.spawns.start[0][1])
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if m.in_bounds(n) and not m.is_solid(n) and not seen.has(n):
				seen[n] = true
				todo.append(n)
	var shut := []
	for y in m.h:
		for x in m.w:
			var c := Vector2i(x, y)
			if not m.is_solid(c) and not seen.has(c):
				shut.append(c)
	check(shut.is_empty(), "every floor cell reached from the door (%s)" % [shut])
	var seats: Array = g.soak_spots(tub)
	check(seats.size() == int(tub.size[0]) and seats.all(func(s): return seen.has(s[0]) and s[1] == Vector2i.UP), "a seat before every cell of the tub's front, facing it (%d)" % seats.size())
	check(seen.has(Vector2i(m.spawns.counter[0][0], m.spawns.counter[0][1])) and seen.has(Vector2i(m.spawns.bath[0][0], m.spawns.bath[0][1])), "the counter and the bath spawns on the floor")
	check(m.doors.size() == 1 and str(m.doors[0].to) == "yumachi", "out to Yumachi")
	var y: MapData = MapManager.data("yumachi")
	var front: Dictionary = y.door_at(Vector2i(7, 4))
	check(str(front.get("to", "")) == "sento" and str(front.get("shop", "")) == "sento" and Vector2i(front.spawn) == start, "Yumachi's bath door leads in, under the shop's hours")
	check(Vector2i(m.doors[0].spawn) == Vector2i(7, 5), "and back out before it")


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
	var seat := Vector2i(10, 3)
	g.maps.place("sento", seat, Vector2i.UP)
	check(AH.interact_verb(seat, Vector2i.UP) == "Soak", "the hint at the tub: Soak")
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
	g.maps.place("sento", Vector2i(10, 4), Vector2i.UP)
	FA.on_action("interact", Vector2i(10, 4), Vector2i.UP)
	check(not g.soaking(), "not from two cells off")
	g.held = "crop:turnip"
	g.maps.place("sento", seat, Vector2i.UP)
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
	world.build(MapManager.data("sento"))
	var steam := world.get_children().filter(func(n): return str(n.name).begins_with("BathSteam"))
	check(steam.size() == BP.STEAM_PUFFS, "steam over the bath (%d)" % steam.size())
	check(steam.all(func(n): return n.position.y > BP.WATER and Rect2(8, 1, 6, 2).has_point(Vector2(n.position.x, n.position.z))), "rising off the tub's water")
	world.queue_free()
	for k in BP.KINDS:
		check(MV.COLORS.has(k), "%s in the flat view" % k)
	var src := FileAccess.get_file_as_string("res://scripts/world/map_view.gd")
	check("BathLook.draw(" in src, "the flat view draws the bath's things (BathLook)")
	var mural: Image = PA.image("bath:mural")
	check(mural.get_size() == Vector2i(192, 32), "the mountain painting 192 x 32")
	check(PA.image("ground:bath_tile:0").get_size() == Vector2i(16, 16), "the tiled floor")
