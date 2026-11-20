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


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


func _data() -> void:
	var a: Dictionary = g.ashiyu
	check(float(a.get("seconds", 0.0)) > 1.0 and int(a.get("stamina", 0)) > 0 and int(a.get("fatigue", 0)) < 0, "a soak lasts a few seconds, gives stamina and takes fatigue off")
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
	check(g.soaked_today and g.soaking() and g.still_pose() == "soak", "sat soaking, the day's soak given")
	check(said.back() == String(a.message), "says the soak")
	check(not g.soak().ok, "no second soak while sitting")
	g._process(float(a.seconds) + 0.1)
	check(not g.soaking() and g.still_pose() == "", "the soak ends after %.1f s" % float(a.seconds))
	var st: int = g.stamina
	var fa: int = g.fatigue
	check(g.soak().ok and g.stamina == st and g.fatigue == fa and said.back() == String(a.again_message), "a later soak the same day only rests")
	g._process(float(a.seconds) + 0.1)
	g.stamina = g.max_stamina - 5
	g.fatigue = 3
	g.soaked_today = false
	g.soak()
	check(g.stamina == g.max_stamina and g.fatigue == 0, "never past the max stamina or under no fatigue")
	g._process(float(a.seconds) + 0.1)
	# The save keeps the day's soak; the morning clears it.
	var d: Dictionary = g.to_dict()
	check(d.get("soaked_today", null) == true, "the day's soak saved")
	g.soaked_today = false
	check(g.from_dict(d) == "" and g.soaked_today, "and loaded")
	d.erase("soaked_today")
	check(g.from_dict(d) == "" and not g.soaked_today, "an older save: no soak yet")
	g.soaked_today = true
	g.end_day()
	check(not g.soaked_today and not g.soaking(), "a new day: the footbath rests again")
	# Holding something overhead: put it down first.
	g.held = "crop:turnip"
	check(not g.soak().ok and not g.soaking() and said.back() == String(a.hands_message), "not while holding something")
	g.held = ""
	g.new_game()
	g.clock_running = false


func _pose() -> void:
	check(FG.frames("soak") == 2, "the soak pose has two frames")
	var idle: Image = PA.image("player:front:idle:0")
	for side in ["front", "back"]:
		for f in 2:
			var img: Image = PA.image("player:%s:soak:%d" % [side, f])
			check(img != null and img.get_used_rect().has_area(), "soak %s %d drawn" % [side, f])
			if side == "front":
				check(img.get_used_rect().position.y > idle.get_used_rect().position.y, "sat lower than standing (frame %d)" % f)
	check(PA.image("player:front:soak:0").get_data() != PA.image("player:front:soak:1").get_data(), "the foot stirs the water")
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
	g.soak_left = 0.0
	var th := Lang.table("th")
	check(th.get("Soak", "") != "" and ["message", "again_message", "hands_message"].all(func(k): return th.has(String(g.ashiyu[k]))), "the verb and the messages in Thai")


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
