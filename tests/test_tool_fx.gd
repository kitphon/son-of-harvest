extends SceneTree
## Headless checks for the tool-use effects (ToolFxRules, data/tool_fx.json): the rules for every
## tool and target and the ground's colours, the particles (counts, the cap, gravity, bounces,
## rings, dying out), a FarmActions swing sending its effect out on the hit frame of the farmer's
## swing pose in both views (ToolFxView in main_2d, ToolFxLayer in main_3d), the mine's swings,
## the harvest puff, and the bursts freeing themselves. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_tool_fx.gd

var failures := 0
var g: Node
var actions: GDScript
var got: Array = []   # the bursts sent out (Game.tool_fx), with the swing's state at that moment


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	actions = load("res://scripts/farm_actions.gd")
	g.new_game()
	g.clock_running = false
	g.tool_fx.connect(func(b): got.append({"burst": b, "frame": g.swing_frame(), "time": float(g.swing.get("time", -1.0)), "pose": g.swing_pose()}))
	_rules()
	_colors()
	_particles()
	_actions()
	_mine()
	_art()
	await _view("res://scenes/main_2d.tscn", false)
	await _view("res://scenes/main.tscn", true)
	print("test_tool_fx: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func kinds(fx: Dictionary) -> Array:
	return fx.get("groups", []).map(func(gr): return gr.kind)


## Every tool and target gives its effect; unknown ones none; levels add a little.
func _rules() -> void:
	var expect := {"hoe": {"soil": ["clods", "puff"], "soft": ["clods"], "miss": ["puff"]},
		"can": {"water": ["spray"]},
		"sickle": {"weed": ["blades"], "miss": ["puff"]},
		"axe": {"wood": ["chips"], "miss": ["puff"]},
		"hammer": {"rock": ["stone"], "ice": ["ice"], "miss": ["puff"]}}
	for tool in expect:
		check(ToolFxRules.TARGETS.has(tool), "%s has targets" % tool)
		for target in expect[tool]:
			var ground := "dry" if target != "soft" else "wet"
			var fx := ToolFxRules.effect(tool, target, ground, 1)
			check(kinds(fx) == expect[tool][target], "%s on %s throws %s (%s)" % [tool, target, expect[tool][target], kinds(fx)])
			for gr in fx.get("groups", []):
				check(gr.count > 0 and not gr.colors.is_empty(), "%s on %s: %s has a count and colours" % [tool, target, gr.kind])
	check(kinds(ToolFxRules.effect("hoe", "soil", "mine")) == ["clods", "puff"], "the mine's soil dusts")
	check(kinds(ToolFxRules.effect("hoe", "soil", "wet")) == ["clods"] and kinds(ToolFxRules.effect("hoe", "soil", "snow")) == ["clods"], "wet soil and snow don't dust")
	check(ToolFxRules.effect("hoe", "rock", "dry").is_empty() and ToolFxRules.effect("can", "miss", "dry").is_empty() == false, "a target the tool can't meet: none; the can's miss still puffs")
	check(ToolFxRules.effect("seeds", "miss", "dry").is_empty() and ToolFxRules.effect("rod", "water", "dry").is_empty(), "seeds and the rod throw nothing")
	check(kinds(ToolFxRules.effect("hammer", "rock", "dry", 1, {"hard": true})) == ["stone", "spark"], "a hard blow sparks")
	var ore := ToolFxRules.effect("hammer", "rock", "mine", 1, {"glint": Color("c8643a")})
	check(kinds(ore) == ["stone", "glint"] and ore.groups[1].colors[0] == Color("c8643a"), "an ore glints in its colour")
	check(ToolFxRules.effect("sickle", "weed", "dry", 1, {"toward": true}).groups[0].toward, "with the silo the grass flies to the farmer")
	check(kinds(ToolFxRules.effect("", "crop", "dry")) == ["leaf_puff"], "a harvest pick-up puffs leaves")
	var c1 := ToolFxRules.count_of("clods", 1)
	var c5 := ToolFxRules.count_of("clods", 5)
	check(c5 > c1 and c5 <= ceili(c1 * 1.6) + 1, "higher tool levels throw a little more (%d -> %d)" % [c1, c5])
	var t := ToolFxRules.swing_times()
	check(t.windup > 0.0 and t.blow > 0.0 and t.windup + t.blow < 0.6, "the swing is short (%s)" % t)


## The soil's colours by the ground; the puff's by the ground.
func _colors() -> void:
	var cfg := ToolFxRules.config()
	check(ToolFxRules.ground_state(0.0, 0.0) == "dry" and ToolFxRules.ground_state(0.0, 1.0) == "wet"
		and ToolFxRules.ground_state(0.5, 1.0) == "snow" and ToolFxRules.ground_state(0.0, 0.0, true) == "mine"
		and ToolFxRules.ground_state(0.0, float(cfg.wet_from) - 0.01) == "dry", "ground states: dry, wet from wet_from, snow over all, the mine")
	var dry := ToolFxRules.soil_colors("dry")
	var wet := ToolFxRules.soil_colors("wet", 1.0)
	check(dry.size() == cfg.ground.dry.size() and dry[0] == Color(str(cfg.ground.dry[0])), "dry soil: the data's tones")
	var darker := true
	for i in dry.size():
		darker = darker and wet[i].get_luminance() < dry[i].get_luminance() * 0.8
		darker = darker and wet[i].is_equal_approx(WetRules.tone(dry[i], WetRules.surface("tilled"), 1.0))
	check(wet.size() == dry.size() and darker, "wet soil: the dry tones in wet.json's tilled wet tone")
	var half := ToolFxRules.soil_colors("wet", 0.5)
	check(half[0].get_luminance() > wet[0].get_luminance() and half[0].get_luminance() < dry[0].get_luminance(), "half wet: between")
	var snow := ToolFxRules.soil_colors("snow")
	check(snow[0] == Color(str(cfg.ground.snow[0])) and snow[0].get_luminance() > 0.9, "snow: white bits in it")
	check(ToolFxRules.soil_colors("mine")[0] == Color(str(cfg.ground.mine[0])), "the mine's soil")
	var puff := func(gnd: String) -> Color: return ToolFxRules.effect("hoe", "miss", gnd).groups[0].colors[0]
	check(puff.call("dry") == Color(str(cfg.puff.dust[0])) and puff.call("snow") == Color(str(cfg.puff.snow[0]))
		and puff.call("wet") == Color(str(cfg.puff.wet[0])), "the miss puff: dust, snow or wet")
	check(ToolFxRules.effect("hoe", "soil", "wet", 1, {"wet": 1.0}).groups[0].colors[0].is_equal_approx(wet[0]), "the hoe's clods on wet ground")


## Particles: as many as planned, the cap, the bounce and rest, the drops' rings, dying out.
func _particles() -> void:
	var b := ToolFxRules.burst(ToolFxRules.effect("hoe", "soil", "dry"), [Vector2i(3, 4)], Vector2(3.5, 3.6), Vector2i.DOWN)
	check(b.cells == [Vector2i(3, 4)] and b.facing == Vector2i.DOWN, "a burst keeps its cells and facing")
	var parts := ToolFxRules.particles(b, 1)
	check(parts.size() == ToolFxRules.planned(b).total, "one particle per bit planned (%d)" % parts.size())
	check(parts.all(func(p): return p.pos.x > 3.0 and p.pos.x < 4.0 and p.pos.z > 4.0 and p.pos.z < 5.0), "they start on the cell")
	check(ToolFxRules.particles(b, 1).map(func(p): return p.pos) == parts.map(func(p): return p.pos), "the same seed, the same burst")
	var many: Array = []
	for y in 6:
		for x in 5:
			many.append(Vector2i(x, y))
	var big := ToolFxRules.burst(ToolFxRules.effect("hoe", "soil", "dry", 5), many, Vector2(2.5, -0.4), Vector2i.DOWN)
	var most := int(ToolFxRules.config().max_particles)
	check(ToolFxRules.planned(big).total > most and ToolFxRules.particles(big, 2).size() <= most, "a wide charged swing stays under max_particles (%d)" % ToolFxRules.particles(big, 2).size())
	var rose := false
	var below := false
	var rested := false
	var t := 0.0
	while not parts.is_empty() and t < 5.0:
		parts = ToolFxRules.step(parts, 1.0 / 60.0)
		t += 1.0 / 60.0
		for p in parts:
			rose = rose or p.pos.y > 0.1
			below = below or p.pos.y < -0.001
			rested = rested or p.rest
		if t > 0.2 and t < 0.25:
			check(not ToolFxRules.specks(parts).is_empty(), "mid-flight there is something to draw")
	check(parts.is_empty() and t < 1.0, "the clods die out within their life (%.2f s)" % t)
	check(rose and not below and rested, "they fly up, never sink below the ground, and come to rest")
	# The can: drops from the spout land on their cells as rings.
	var w := ToolFxRules.burst(ToolFxRules.effect("can", "water", "dry"), [Vector2i(3, 5), Vector2i(3, 6)], Vector2(3.5, 4.6), Vector2i.DOWN)
	var drops := ToolFxRules.particles(w, 3)
	check(drops.all(func(p): return p.kind == "drop" and p.pos.y > 0.3 and absf(p.pos.z - 5.05) < 0.01), "the drops start at the spout")
	var rings := 0
	var landed_ok := true
	t = 0.0
	while not drops.is_empty() and t < 5.0:
		drops = ToolFxRules.step(drops, 1.0 / 60.0)
		t += 1.0 / 60.0
		for p in drops:
			if p.kind == "ring" and p.age == 0.0:
				rings += 1
				landed_ok = landed_ok and p.pos.z > 4.6 and p.pos.z < 7.4 and is_equal_approx(p.pos.y, 0.0)
	check(rings == ToolFxRules.planned(w).total and landed_ok, "every drop lands on the cells as a ring (%d)" % rings)
	check(drops.is_empty(), "and the rings fade out")
	var ring := {"kind": "ring", "pos": Vector3.ZERO, "age": 0.1, "life": 0.4, "delay": 0.0, "color": Color.WHITE, "size": 1.0, "ring": {"radius": 0.2}}
	check(ToolFxRules.specks([ring] as Array[Dictionary]).size() == 8, "a ring is drawn as eight specks")
	# The sickle with the silo: the bits head for the farmer.
	var gb := ToolFxRules.burst(ToolFxRules.effect("sickle", "weed", "dry", 1, {"toward": true}), [Vector2i(3, 6)], Vector2(3.5, 3.6), Vector2i.DOWN)
	var gp := ToolFxRules.particles(gb, 4)
	check(gp.all(func(p): return p.vel.z < 0.0), "the cut grass flies toward the farmer")
	check(ToolFxRules.flat_of(Vector3(1, 0.5, 2)) == Vector2(16, 24), "the flat view: half a cell up is 8 px up the screen")


func select(tool: String) -> void:
	for i in g.inventory.size("tools"):
		if g.inventory.id_at("tools", i) == tool:
			g.select_tool(i)


func clear(c: Vector2i) -> void:
	var f: FarmGrid = g.farm
	for y in range(c.y - 3, c.y + 4):
		for x in range(c.x - 3, c.x + 4):
			var p := Vector2i(x, y)
			if f.in_bounds(p) and f.fixed_at(p) == "":
				f.cell(p).obj = FarmGrid.Obj.NONE
				f.cell(p).crop = ""
				f.cell(p).tilled = false
				f.cell(p).wet = false
				f.take_item_at(p)


## Runs the swing to its end by hand.
func finish_swing() -> void:
	for i in 60:
		if not g.swinging():
			return
		g.swing_step(1.0 / 30.0)


## FarmActions: what each swing hands Game.start_swing, sent out only on the hit.
func _actions() -> void:
	g.stamina = g.max_stamina
	var c := Vector2i(14, 12)
	clear(c)
	g.snow_cover = 0
	g.weather_today = "sunny"
	select("hoe")
	got.clear()
	actions.use_tool(c, Vector2i.DOWN, 0)
	check(g.farm.cell(c + Vector2i.DOWN).tilled, "the hoe still tills on the press")
	check(g.swinging() and g.swing_pose() == "swing_hoe" and g.swing_frame() == 0 and got.is_empty(), "the swing starts raised, nothing thrown yet")
	var t := ToolFxRules.swing_times()
	g.swing_step(t.windup * 0.9)
	check(got.is_empty() and g.swing_frame() == 0, "still nothing just before the hit")
	g.swing_step(t.windup * 0.2)
	check(got.size() == 1 and got[0].frame == 1 and got[0].pose == "swing_hoe" and got[0].time >= t.windup, "the effect goes out as the blow frame starts (%s)" % [got])
	if got.size() == 1:
		var b: Dictionary = got[0].burst
		check(b.target == "soil" and b.cells == [c + Vector2i.DOWN] and b.ground == "dry" and kinds(b) == ["clods", "puff"], "the hoe: clods and dust on the tilled cell (%s)" % [b.cells])
	g.swing_step(t.blow)
	check(not g.swinging() and got.size() == 1, "the swing ends; the effect went out once")
	# A useless swing: a puff on the first cell only.
	got.clear()
	actions.use_tool(c, Vector2i.DOWN, 0)
	finish_swing()
	check(got.size() == 1 and got[0].burst.target == "miss" and kinds(got[0].burst) == ["puff"], "the hoe on tilled soil: a puff only")
	# The can on the tilled cell: a spray, no darkening of its own (the watered tile already is).
	select("can")
	got.clear()
	actions.use_tool(c, Vector2i.DOWN, 0)
	finish_swing()
	check(got.size() == 1 and got[0].burst.target == "water" and kinds(got[0].burst) == ["spray"], "the can: a spray only, the cell's wet tile is the darkening")
	# The sickle on a weed, the axe on a branch and a stump, the hammer on a rock.
	for row in [["sickle", FarmGrid.Obj.WEED, "weed", 0], ["axe", FarmGrid.Obj.BRANCH, "wood", 0], ["axe", FarmGrid.Obj.STUMP, "wood", 0],
			["hammer", FarmGrid.Obj.ROCK, "rock", 0], ["hammer", FarmGrid.Obj.ROCK, "rock", 1]]:
		clear(c)
		g.farm.cell(c + Vector2i.DOWN).obj = row[1]
		g.tool_levels[row[0]] = 2 if row[3] == 1 else 1
		select(row[0])
		g.stamina = g.max_stamina
		got.clear()
		actions.use_tool(c, Vector2i.DOWN, row[3])
		finish_swing()
		check(got.size() == 1 and got[0].burst.target == row[2], "%s on %s: %s (%s)" % [row[0], row[1], row[2], got.map(func(x): return x.burst.target)])
		if row[3] == 1 and got.size() == 1:
			check("spark" in kinds(got[0].burst), "a charged hammer blow sparks")
	g.tool_levels["hammer"] = 1
	# Wet and snowy ground for the hoe.
	select("hoe")
	clear(c)
	g.weather_today = "rain"
	g.hour = 12
	got.clear()
	actions.use_tool(c, Vector2i.DOWN, 0)
	finish_swing()
	check(got.size() == 1 and got[0].burst.ground == "wet", "rain: the clods are wet (%s)" % [got[0].burst.ground if got.size() == 1 else "-"])
	clear(c)
	g.weather_today = "sunny"
	g.snow_cover = 60
	got.clear()
	actions.use_tool(c, Vector2i.DOWN, 0)
	finish_swing()
	check(got.size() == 1 and got[0].burst.ground == "snow", "snow lying: snowy clods")
	g.snow_cover = 0
	g.hour = 10
	# The silo: the cut grass flies toward the farmer.
	clear(c)
	g.animals.built.append(str(g.animals.silo_rule().get("build", "silo")))
	g.farm.cell(c + Vector2i.DOWN).obj = FarmGrid.Obj.WEED
	select("sickle")
	got.clear()
	actions.use_tool(c, Vector2i.DOWN, 0)
	finish_swing()
	check(got.size() == 1 and got[0].burst.groups[0].get("toward", false), "with the silo the sickle's grass flies to the farmer")
	g.animals.built.clear()
	# No stamina: no swing at all (the rule refuses it).
	g.stamina = 0
	g.fatigue = g.FATIGUE_MAX if "FATIGUE_MAX" in g else 100
	got.clear()
	var was: bool = g.swinging()
	actions.use_tool(c, Vector2i.DOWN, 0)
	check(g.swinging() == was or got.is_empty(), "a refused swing throws nothing")
	finish_swing()
	g.fatigue = 0
	g.stamina = g.max_stamina
	# The harvest pick-up: a leaf puff at once.
	clear(c)
	var p := c + Vector2i.DOWN
	g.farm.cell(p).tilled = true
	g.farm.cell(p).crop = "turnip"
	g.farm.cell(p).stage = g.farm.ripe_stage("turnip")
	got.clear()
	actions.interact(p)
	check(g.holding() and got.size() == 1 and got[0].burst.target == "crop" and got[0].burst.cells == [p], "a harvest puffs leaves where the crop came out")
	g.held = ""


## The mine: stone chips, ice, a spark on a rock left standing, an ore's glint, soil from a soft spot.
func _mine() -> void:
	var f := MineFloor.new()
	var c := Vector2i(5, 5)
	var by := {}
	g.start_swing("", [])
	for row in [["hammer", {"kind": "rock", "hits": 1, "done": 1, "find": "akagane"}, false, "rock"],
			["hammer", {"kind": "ice", "hits": 2, "done": 1, "find": ""}, true, "ice"],
			["hoe", {"soft": "kogane"}, false, "soft"]]:
		f.rocks.clear()
		f.soft.clear()
		if row[2]:
			f.rocks[c] = row[1]
		actions._mine_fx(row[0], f, {c: row[1]}, c + Vector2i.UP, Vector2i.DOWN, false)
		by[row[3]] = g.swing.bursts
	var rock: Array = by.rock
	check(rock.size() == 1 and kinds(rock[0]) == ["stone", "glint"] and rock[0].groups[1].colors[0] == Color("c8643a") and rock[0].ground == "mine",
		"a broken rock with akagane: stone chips and a copper glint")
	check(by.ice.size() == 1 and kinds(by.ice[0]) == ["ice", "spark"], "an ice block left standing: ice chips and a spark")
	check(by.soft.size() == 1 and kinds(by.soft[0]) == ["clods", "puff", "glint"] and by.soft[0].groups[0].colors[0] == ToolFxRules.soil_colors("mine")[0],
		"a soft spot dug with kogane: mine soil and a gold glint")
	actions._mine_fx("hammer", f, {c: {}}, c + Vector2i.UP, Vector2i.DOWN, false)
	check(g.swing.bursts.size() == 1 and g.swing.bursts[0].target == "miss", "a blow on nothing: a puff")
	check(actions._find_glint("") == null and actions._find_glint("stairs") == null, "no glint for nothing or the hole")
	g.swing = {}


## The swing poses: the farmer's art draws every tool's two frames, the blow different from the wind-up.
func _art() -> void:
	for tool in FigureArt.SWING_TOOLS:
		var pose := "swing_" + tool
		check(FigureArt.frames(pose) == 2, "%s has two frames" % pose)
		for back in [false, true]:
			var a := FigureArt.draw(FigureArt.FARMER_LOOK, back, pose, 0, true)
			var b := FigureArt.draw(FigureArt.FARMER_LOOK, back, pose, 1, true)
			check(a.get_data() != b.get_data() and a.get_data() != FigureArt.draw(FigureArt.FARMER_LOOK, back, "idle", 0, true).get_data(),
				"%s %s: the blow differs from the wind-up and from standing" % [pose, "back" if back else "front"])
	var anim := FarmerAnim.new()
	anim.step(0.1, true, false, false, false, "", "", "", "swing_axe", 1)
	check(anim.pose == "swing_axe" and anim.frame() == 1 and anim.key(Vector2i.DOWN) == "player:front:swing_axe:1", "FarmerAnim shows the swing's frame, over walking")
	anim.step(0.1, false, false)
	check(anim.pose == "idle", "and goes back after it")


## A real view: a swing through the Player's action shows the swing pose, sends the effect on the
## hit frame into the view's effect layer, the farmer stands still, and the burst frees itself.
func _view(path: String, three_d: bool) -> void:
	var name := "3D" if three_d else "flat"
	g.new_game()
	g.clock_running = false
	g.events_seen = {"first_morning": true, "rainy_day": true}
	g.hour = 10
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	for i in 3:
		await process_frame
	var player: Node2D = scene.player
	var c := Vector2i(14, 12)
	clear(c)
	select("hoe")
	player.position = Vector2(c * 16) + Vector2(8, 8)
	player.facing = Vector2i.DOWN
	got.clear()
	var nodes_before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	player.action.emit("tool", c, Vector2i.DOWN, 0)
	await process_frame
	var anim: RefCounted = scene.anim if three_d else player.anim
	check(anim.pose == "swing_hoe", "%s: the farmer is in the hoe's swing pose (%s)" % [name, anim.pose])
	var frames := 0
	while got.is_empty() and frames < 600:
		check(anim.frame() == 0 or not got.is_empty(), "%s: no blow frame before the effect" % name)
		await process_frame
		frames += 1
	check(got.size() == 1 and got[0].frame == 1, "%s: the effect went out on the hit frame" % name)
	await process_frame
	if g.swinging():
		check(anim.key(Vector2i.DOWN) == "player:front:swing_hoe:1", "%s: the blow frame shows (%s)" % [name, anim.key(Vector2i.DOWN)])
		check(not player.moving, "%s: the farmer stands still during the swing" % name)
	var layer: Node = scene.view.get_node_or_null("ToolFx") if not three_d else scene.world.get_node_or_null("ToolFx")
	check(layer != null, "%s: the view has its effect layer" % name)
	if layer == null:
		scene.queue_free()
		await process_frame
		return
	var bursts: Array = layer.bursts()
	check(bursts.size() == 1, "%s: one burst flying (%d)" % [name, bursts.size()])
	if not three_d and bursts.size() == 1:
		var fl: Node = load("res://scripts/world/figure_layer.gd").of(scene.view)
		check(bursts[0].get_parent() == fl, "flat: the burst sorts with the figures")
		check(bursts[0].position.y > player.position.y, "flat: the burst below the farmer sorts in front of the farmer")
		var px: Array = bursts[0].pixels()
		check(not px.is_empty() and px.all(func(p): return p.at == p.at.round()), "flat: whole pixels")
	if three_d and bursts.size() == 1:
		check(bursts[0].multimesh.visible_instance_count > 0, "3D: the burst shows its specks")
	# It dies out by itself and frees itself.
	var waited := 0
	while not layer.bursts().is_empty() and waited < 600:
		await process_frame
		waited += 1
	check(layer.bursts().is_empty(), "%s: the burst dies out and frees itself (%d frames)" % [name, waited])
	await process_frame
	check(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) <= nodes_before, "%s: no nodes left behind (%d -> %d)" % [name, nodes_before, Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	# Many swings at once: all freed again.
	for i in 5:
		layer.add_burst(ToolFxRules.burst(ToolFxRules.effect("hammer", "rock", "dry", 1, {"hard": true}), [c + Vector2i.DOWN], Vector2(c) + Vector2(0.5, 0.6), Vector2i.DOWN))
	check(layer.bursts().size() == 5, "%s: five bursts at once" % name)
	for b in layer.bursts():
		b.advance(5.0)
	await process_frame
	check(layer.bursts().is_empty(), "%s: all freed after their life" % name)
	scene.queue_free()
	await process_frame
	await process_frame
