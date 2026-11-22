extends SceneTree
## Headless checks for the village footbath (ashiyu): data/ashiyu.json, Game.soak (the day's first
## soak gives stamina and takes fatigue off, a later one only rests, not while holding something,
## cleared each morning, saved), the sitting pose "soak" (FigureArt, FarmerAnim, Game.still_pose:
## the farmer kept still), the prop on the village map (where the station east of the street stood:
## the tub `ashiyu` with "use": "soak", its roof `ashiyu_roof` apart so only the roof fades), E at
## it through FarmActions and its hint, the 3D build (FootBath: the low tub, the roof, the steam)
## and the flat view (MapView). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_ashiyu.gd

var failures := 0
var g: Node
# Loaded, not named: these scripts reach the Game autoload, which a --script test only has at run time.
var FA: GDScript
var AH: GDScript
var MV: GDScript
var FB: GDScript
var OC: GDScript
var AN: GDScript
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
	FB = load("res://scripts/world3d/foot_bath.gd")
	OC = load("res://scripts/world3d/occluders.gd")
	AN = load("res://scripts/world3d/farmer_anim.gd")
	FG = load("res://scripts/art/figure_art.gd")
	PA = load("res://scripts/art/placeholder_art.gd")
	g.new_game()
	g.clock_running = false
	_data()
	_soak()
	_pose()
	_map()
	_action()
	_views()
	print("test_ashiyu: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


## Sits the soak down all the way / gets up all the way (the transitions played through).
func _sit() -> void:
	g._process(float(g.ashiyu.sit_seconds) + 0.05)


func _up() -> void:
	g.stop_soak()
	g._process(float(g.ashiyu.stand_seconds) + 0.05)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


func _data() -> void:
	var a: Dictionary = g.ashiyu
	check(int(a.get("stamina", 0)) > 0 and int(a.get("fatigue", 0)) < 0, "a soak gives stamina and takes fatigue off")
	check(float(a.get("seat", 0.0)) > 0.5 and float(a.seat) < 1.0, "the farmer sits on the bench, short of the cell's far side (%.2f)" % float(a.get("seat", 0.0)))
	check(int(a.stamina) <= 30 and int(a.fatigue) >= -20, "worth a walk, never a stand-in for sleep (%d / %d)" % [int(a.stamina), int(a.fatigue)])
	for k in ["message", "again_message", "hands_message"]:
		var t := String(a.get(k, ""))
		check(t != "" and t.right(1) in [".", "!", "?"], "%s is a sentence" % k)


func _soak() -> void:
	var said: Array[String] = []
	g.message.connect(func(t: String): said.append(t))
	var a: Dictionary = g.ashiyu
	g.stamina = 50
	g.fatigue = 40
	var r: Dictionary = g.soak()
	check(r.ok and g.stamina == 50 + int(a.stamina) and g.fatigue == 40 + int(a.fatigue), "the first soak: stamina + %d, fatigue %d" % [int(a.stamina), int(a.fatigue)])
	check(g.soaked_today and g.soaking() and g.soak_phase == "down" and g.still_pose() == "walk" and g.soak_seat() == 0.0, "sitting down: from where he stood, stepping toward the tub")
	g._process(float(a.sit_seconds) * 0.5)
	check(g.soak_amount() > 0.1 and g.soak_amount() < 0.9 and g.soak_seat() > 0.0 and g.soak_seat() < float(a.seat), "half way down: part way onto the seat (%.2f)" % g.soak_amount())
	g._process(float(a.sit_seconds))
	check(g.soak_phase == "sit" and g.still_pose() == "soak" and is_equal_approx(g.soak_amount(), 1.0), "sat after %.1f s, the feet in" % float(a.sit_seconds))
	# Eased all the way, never a jump; over the rim only with the legs up (the user found the jumps
	# and the glide through the rim unnatural): the keys of data/ashiyu.json sit_path.
	var saved_t: float = g.soak_t
	var keys: Array = a.sit_path
	check(keys.size() >= 5 and float(keys[0][0]) == 0.0 and float(keys[-1][0]) == 1.0 and is_equal_approx(float(keys[-1][1]), float(a.seat)) and is_equal_approx(float(keys[-1][2]), float(a.lift)), "the way from standing to the seat, keyed from 0 to 1")
	var biggest := 0.0
	var over_bare := 0
	var poses := {}
	var last: float = 0.0
	for k in 201:
		g.soak_t = k / 200.0
		var x: float = g.soak_seat()
		biggest = maxf(biggest, absf(x - last))
		last = x
		if x > 0.6 and x < 0.8 and not g.still_pose() in ["soak_lift", "soak_swing"]:
			over_bare += 1   # crossing the rim (0.6 .. 0.8 cells on) with the legs down
		poses[g.still_pose()] = true
	check(biggest < 0.03, "no jump along the way (the biggest step %.3f cells in 1/200 of it)" % biggest)
	check(over_bare == 0, "across the rim only with the legs lifted (%d)" % over_bare)
	check(["walk", "soak_down", "soak", "soak_lift", "soak_swing"].all(func(p): return poses.has(p)), "a few steps, bending, sat on the bench, the legs up and over, the feet in (%s)" % [poses.keys()])
	g.soak_t = 0.5
	check(not g.feet_in(), "on the bench the feet are not in yet")
	g.soak_t = 1.0
	check(g.feet_in(), "sat: the feet in")
	g.soak_t = saved_t
	check(said.back() == String(a.message), "says the soak")
	check(not g.soak().ok, "no second soak while sitting")
	check(is_equal_approx(g.soak_seat(), float(a.seat)), "drawn on the bench, the feet in the water")
	g._process(600.0)
	check(g.soaking(), "still soaking after ten minutes: until E again")
	g.stop_soak()
	check(g.soaking() and g.soak_phase == "up", "E again: getting up, not up at once")
	g._process(float(a.stand_seconds) * 0.5)
	check(g.soaking() and g.soak_amount() < 0.95 and g.soak_seat() < float(a.seat), "half way up")
	g._process(float(a.stand_seconds))
	check(not g.soaking() and g.still_pose() == "" and g.soak_seat() == 0.0, "up after %.1f s and free" % float(a.stand_seconds))
	var st: int = g.stamina
	var fa: int = g.fatigue
	check(g.soak().ok and g.stamina == st and g.fatigue == fa and said.back() == String(a.again_message), "a later soak the same day only rests")
	_up()
	g.stamina = g.max_stamina - 5
	g.fatigue = 3
	g.soaked_today = false
	g.soak()
	check(g.stamina == g.max_stamina and g.fatigue == 0, "never past the max stamina or under no fatigue")
	_up()
	# The save keeps the day's soak; the morning clears it.
	var d: Dictionary = g.to_dict()
	check(d.get("soaked_today", null) == true, "the day's soak saved")
	g.soaked_today = false
	check(g.from_dict(d) == "" and g.soaked_today, "and loaded")
	d.erase("soaked_today")
	check(g.from_dict(d) == "" and not g.soaked_today, "an older save: no soak yet")
	g.soaked_today = true
	g.soaking_now = true
	g.end_day()
	check(not g.soaked_today and not g.soaking(), "a new day: up from the footbath, its rest given again")
	# Holding something overhead: put it down first.
	g.held = "crop:turnip"
	check(not g.soak().ok and not g.soaking() and said.back() == String(a.hands_message), "not while holding something")
	g.held = ""
	g.new_game()
	g.clock_running = false


func _pose() -> void:
	check(FG.frames("soak") == 2 and FG.frames("soak_down") == 1 and FG.frames("soak_lift") == 1, "the soak pose has two frames, the half crouch and the legs lifting one each")
	var lifted: Image = PA.image("player:front:soak_swing:0")
	check(lifted.get_used_rect().end.y < PA.image("player:front:soak:0").get_used_rect().end.y, "the legs lifted over the rim (soak_swing) end higher than sat")
	var crouch: Image = PA.image("player:front:soak_down:0")
	check(crouch.get_used_rect().position.y > PA.image("player:front:idle:0").get_used_rect().position.y
		and crouch.get_used_rect().position.y < PA.image("player:front:soak:0").get_used_rect().position.y, "the half crouch between standing and sat")
	var idle: Image = PA.image("player:front:idle:0")
	for side in ["front", "back"]:
		for f in 2:
			var img: Image = PA.image("player:%s:soak:%d" % [side, f])
			check(img != null and img.get_used_rect().has_area(), "soak %s %d drawn" % [side, f])
			if side == "front":
				check(img.get_used_rect().position.y > idle.get_used_rect().position.y, "sat lower than standing (frame %d)" % f)
	check(PA.image("player:front:soak:0").get_data() != PA.image("player:front:soak:1").get_data(), "the foot stirs the water")
	var from_back: Image = PA.image("player:back:soak:0")
	check(from_back.get_used_rect().end.y <= PA.image("player:front:soak:0").get_used_rect().end.y - 3, "from behind no legs: they are in front of him in the water (%s)" % from_back.get_used_rect())
	# Sat, not stood: a lap across both legs under the waist (FigureArt._lap): the trousers' colour
	# runs from the lap's outer edge to the inner leg, where stood the shins have their edge there.
	var sat: Image = PA.image("player:front:soak:0")
	var hip: int = int(FG.plan(FG.FARMER_LOOK).hip) + int(FG.row("soak", 0)[0])
	check(sat.get_pixel(8, hip).is_equal_approx(sat.get_pixel(10, hip)) and sat.get_pixel(13, hip).is_equal_approx(sat.get_pixel(14, hip)) and sat.get_pixel(11, hip).is_equal_approx(sat.get_pixel(8, hip))
		and not idle.get_pixel(8, FG.FOOT - 3).is_equal_approx(idle.get_pixel(10, FG.FOOT - 3)), "a lap across the legs when sat (the hands at the knees)")
	var anim: RefCounted = AN.new()
	anim.step(0.1, false, false, false, false, "", "soak")
	check(anim.pose == "soak" and anim.key(Vector2i.DOWN).begins_with("player:front:soak:"), "FarmerAnim takes the soak pose")


func _map() -> void:
	var t := MapManager.data("town")
	var tub: Dictionary = t.prop_at(Vector2i(46, 22))
	check(tub.get("kind", "") == "ashiyu" and str(tub.get("use", "")) == "soak" and Vector2i(tub.size) == Vector2i(3, 2), "the footbath east of the street, used to soak")
	check(t.is_solid(Vector2i(45, 22)) and t.is_solid(Vector2i(47, 23)), "its tub stands solid")
	var roofs := t.props.filter(func(p): return p.kind == "ashiyu_roof")
	check(roofs.size() == 1 and Vector2i(roofs[0].cell) == Vector2i(tub.cell) and Vector2i(roofs[0].size) == Vector2i(tub.size) and not bool(roofs[0].get("solid", true)), "its roof apart over the same cells")
	check(not t.props.any(func(p): return p.kind == "station" and Vector2i(p.cell) == Vector2i(44, 22)), "no station there now")
	var sp: Array = t.spawns.get("ashiyu", [])
	check(not sp.is_empty() and Vector2i(sp[0]) == Vector2i(46, 21) and (sp[1] == Vector2i.DOWN or str(sp[1]) == "down") and not t.is_solid(Vector2i(46, 21)) and t.tile(Vector2i(46, 21)) == "path", "a spawn on the lane before it, facing it")


func _action() -> void:
	g.maps.place("town", Vector2i(46, 21), Vector2i.DOWN)
	check(AH.interact_verb(Vector2i(46, 21), Vector2i.DOWN) == "Soak", "the hint: Soak")
	g.stamina = 40
	g.soaked_today = false
	FA.on_action("interact", Vector2i(46, 21), Vector2i.DOWN)
	check(g.soaking() and g.soaked_today and g.stamina == 40 + int(g.ashiyu.stamina), "E at the footbath soaks the feet")
	check(AH.pick(Vector2i(46, 21), Vector2i.DOWN).interact == "Get up", "the hint while soaking: Get up")
	check(g.soak_at == Vector2i(46, 21) and g.soak_facing == Vector2i.DOWN, "sat on that seat")
	_up()
	# Only the middle of each long side is a seat: never the ends or corners (the user saw him sat by a post).
	var tub: Dictionary = g.maps.current().prop_at(Vector2i(46, 22))
	check(g.soak_spots(tub) == [[Vector2i(46, 21), Vector2i.DOWN], [Vector2i(46, 24), Vector2i.UP]], "two seats: the middle of the north and the south side")
	check(AH.interact_verb(Vector2i(45, 21), Vector2i.DOWN) == "" and AH.interact_verb(Vector2i(44, 23), Vector2i.RIGHT) == "", "no Soak hint at an end or a corner")
	var said: Array[String] = []
	var hear := func(t: String): said.append(t)
	g.message.connect(hear)
	g.maps.place("town", Vector2i(47, 21), Vector2i.DOWN)
	FA.on_action("interact", Vector2i(47, 21), Vector2i.DOWN)
	check(not g.soaking() and said.back() == String(g.ashiyu.seat_message), "E at an end: sit in the middle")
	g.message.disconnect(hear)
	g.maps.place("town", Vector2i(46, 24), Vector2i.UP)
	FA.on_action("interact", Vector2i(46, 24), Vector2i.UP)
	check(g.soaking() and g.soak_at == Vector2i(46, 24) and g.soak_facing == Vector2i.UP, "the south seat, facing the tub")
	_sit()
	check(is_equal_approx(g.soak_seat(true), float(g.ashiyu.seat_back)) and is_equal_approx(g.soak_lift(true), float(g.ashiyu.lift_back))
		and g.soak_seat(true) < g.soak_seat(false), "from behind on the rim itself, nearer than the front seat")
	_up()
	var sfx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json")).sounds
	check(sfx.has("soak_in") and sfx.has("soak_out") and str(sfx.soak_in.get("file", "")) == "res://sounds/water_splash.mp3", "a sound for the feet going in (the recorded splash the user picked) and coming out")
	check("sfx.play(\"soak_in\")" in FileAccess.get_file_as_string("res://scripts/autoload/game.gd") and "Sfx.play(\"soak_out\")" in FileAccess.get_file_as_string("res://scripts/player/player.gd"), "played on sitting down and getting up")
	var src := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	check("if Input.is_action_just_pressed(\"interact\") and Game.soak_phase != \"up\":
				Game.stop_soak()" in src, "the farmer's E stands him up while soaking")
	g.go_to_map("town", Vector2i(46, 25), Vector2i.UP)
	check(not g.soaking(), "a map change stands him up")
	var th := Lang.table("th")
	check(th.get("Soak", "") != "" and th.get("Get up", "") != "" and ["message", "again_message", "hands_message"].all(func(k): return th.has(String(g.ashiyu[k]))), "the verb and the messages in Thai")


func _views() -> void:
	var world: Node3D = load("res://scripts/world3d/map_world.gd").new()
	root.add_child(world)
	world.build(MapManager.data("town"))
	var steam := world.get_children().filter(func(n): return str(n.name).begins_with("FootBathSteam"))
	check(steam.size() == FB.STEAM_PUFFS, "steam over the water (%d)" % steam.size())
	check(steam.all(func(n): return n.position.y > FB.WATER_Y and Rect2(45, 22, 3, 2).has_point(Vector2(n.position.x, n.position.z))), "rising off the tub")
	check(FB.BENCH_Y < OC.MIN_HEIGHT and FB.ROOF_LOW > OC.MIN_HEIGHT, "the low tub never fades, the roof may")
	world.queue_free()
	check(MV.COLORS.has("ashiyu") and MV.COLORS.has("ashiyu_roof"), "both kinds in the flat view")
