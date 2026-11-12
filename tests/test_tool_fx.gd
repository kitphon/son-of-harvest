extends SceneTree
## Headless checks for the tool-use effects (ToolFxRules, data/tool_fx.json): the rules for every
## tool and target and the ground's colours, the particles (counts, the cap, gravity, bounces,
## rings, dying out), a FarmActions swing paid on the press and landing on the hit frame of the
## farmer's swing pose (the cell's change, the sound, the effect; a map change, the day's end, a
## save and a load mid-swing), the seed scatter, the charge's wind-up pose, in both views
## (ToolFxView in main_2d, ToolFxLayer in main_3d), the mine's swings, the harvest puff, snow bits
## that read on snow, every swing pose from every side, and the bursts freeing themselves. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_tool_fx.gd

var failures := 0
var g: Node
var sfx: Node
var actions: GDScript
var got: Array = []   # the bursts sent out (Game.tool_fx), with the swing's state at that moment


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	sfx = root.get_node("Sfx")
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
		"hammer": {"rock": ["stone"], "ice": ["ice"], "miss": ["puff"]},
		"seeds": {"sow": ["seeds"]}}
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
	check(snow[0] == Color(str(cfg.ground.snow[0])), "snow: the data's tones")
	# The snow's bits are a blue-grey a step darker than the snow lying (data/snow_cover.json), so they read on white.
	var lying := Color(str(JSON.parse_string(FileAccess.get_file_as_string("res://data/snow_cover.json")).ice.colors.snow))
	var snow_bits: Array[Color] = []
	snow_bits.append_array(snow)
	for h in cfg.puff.snow:
		snow_bits.append(Color(str(h)))
	for col in snow_bits:
		check(col.get_luminance() < lying.get_luminance() - 0.1, "snow bit %s reads on the lying snow %s (%.2f vs %.2f)" % [col.to_html(false), lying.to_html(false), col.get_luminance(), lying.get_luminance()])
		check(col.b >= col.r or col.get_luminance() < 0.6, "snow bit %s: blue-grey or soil" % col.to_html(false))
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
	# Seeds: let go at the hand's height over each cell sown, falling to rest on it.
	var sb := ToolFxRules.burst(ToolFxRules.effect("seeds", "sow", "dry"), [Vector2i(3, 5), Vector2i(4, 5)], Vector2(3.5, 4.6), Vector2i.DOWN)
	var sp := ToolFxRules.particles(sb, 5)
	var sk: Dictionary = ToolFxRules.config().kinds.seeds
	check(sp.size() == int(sk.count) * 2, "seeds: %d a cell sown (%d)" % [int(sk.count), sp.size()])
	check(sp.all(func(p): return p.pos.y >= float(sk.drop[0]) - 0.001 and p.pos.x > 2.6 and p.pos.x < 5.4 and p.pos.z > 5.1 and p.pos.z < 5.9), "seeds start at the hand's height over their cells")
	check(sp.all(func(p): return absf(p.size - 2.0) < 0.001), "seed bits are 2 px (%s)" % [sp.map(func(p): return p.size).slice(0, 3)])
	t = 0.0
	var landed := true
	while not sp.is_empty() and t < 3.0:
		sp = ToolFxRules.step(sp, 1.0 / 60.0)
		t += 1.0 / 60.0
		for p in sp:
			landed = landed and p.pos.y > -0.001
	check(sp.is_empty() and landed and t < 1.2, "seeds fall to the ground and die out (%.2f s)" % t)


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
	sfx.last = ""
	var st0: int = g.stamina
	var exp0: int = g.tool_exp.get("hoe", 0) if "tool_exp" in g else 0
	actions.use_tool(c, Vector2i.DOWN, 0)
	check(not g.farm.cell(c + Vector2i.DOWN).tilled, "the hoe does not till on the press")
	check(g.stamina < st0, "the stamina is paid on the press (%d -> %d)" % [st0, g.stamina])
	check(sfx.last == "", "no tool sound on the press (%s)" % sfx.last)
	check(g.swinging() and g.swing_pose() == "swing_hoe" and g.swing_frame() == 0 and got.is_empty(), "the swing starts raised, nothing thrown yet")
	var t := ToolFxRules.swing_times()
	g.swing_step(t.windup * 0.9)
	check(got.is_empty() and g.swing_frame() == 0 and not g.farm.cell(c + Vector2i.DOWN).tilled and sfx.last == "", "still nothing just before the hit")
	g.swing_step(t.windup * 0.2)
	check(g.farm.cell(c + Vector2i.DOWN).tilled, "the hoe tills on the hit")
	check(sfx.last == "tool_hoe", "the tool sound plays on the hit (%s)" % sfx.last)
	if "tool_exp" in g:
		check(int(g.tool_exp.get("hoe", 0)) > exp0, "the tool learns on the hit")
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
	_timing(c)
	_seeds(c)
	_playable(c)
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
	for row in [["hammer", {"kind": "rock", "hits": 1, "done": 1, "find": "akagane"}, false, "rock"],
			["hammer", {"kind": "ice", "hits": 2, "done": 1, "find": ""}, true, "ice"],
			["hoe", {"soft": "kogane"}, false, "soft"]]:
		f.rocks.clear()
		f.soft.clear()
		if row[2]:
			f.rocks[c] = row[1]
		by[row[3]] = actions._mine_bursts(row[0], f, {c: row[1]}, c + Vector2i.UP, Vector2i.DOWN, false)
	var rock: Array = by.rock
	check(rock.size() == 1 and kinds(rock[0]) == ["stone", "glint"] and rock[0].groups[1].colors[0] == Color("c8643a") and rock[0].ground == "mine",
		"a broken rock with akagane: stone chips and a copper glint")
	check(by.ice.size() == 1 and kinds(by.ice[0]) == ["ice", "spark"], "an ice block left standing: ice chips and a spark")
	check(by.soft.size() == 1 and kinds(by.soft[0]) == ["clods", "puff", "glint"] and by.soft[0].groups[0].colors[0] == ToolFxRules.soil_colors("mine")[0],
		"a soft spot dug with kogane: mine soil and a gold glint")
	var miss: Array = actions._mine_bursts("hammer", f, {c: {}}, c + Vector2i.UP, Vector2i.DOWN, false)
	check(miss.size() == 1 and miss[0].target == "miss", "a blow on nothing: a puff")
	check(actions._find_glint("") == null and actions._find_glint("stairs") == null, "no glint for nothing or the hole")
	_mine_timing()


## The hit's timing against the world changing mid-swing: a map change and the day's end land the
## swing first, a swing whose map changed without that lands on nothing, a save holds the result,
## a load drops the swing; the charge's wind-up pose.
func _timing(c: Vector2i) -> void:
	var front := c + Vector2i.DOWN
	select("hoe")
	g.stamina = g.max_stamina
	# A map change before the hit: the swing lands on the farm first.
	clear(c)
	got.clear()
	var home: String = g.maps.id
	actions.use_tool(c, Vector2i.DOWN, 0)
	check(g.swinging() and not g.farm.cell(front).tilled, "mid-swing: not tilled yet")
	g.go_to_map("town", Vector2i(5, 5), Vector2i.DOWN)
	check(not g.swinging() and g.farm.cell(front).tilled and got.size() == 1, "a map change mid-swing: it lands on the farm before leaving")
	g.go_to_map(home, c, Vector2i.DOWN)
	# A swing whose map changed under it (nothing landed it): it lands on nothing.
	clear(c)
	got.clear()
	actions.use_tool(c, Vector2i.DOWN, 0)
	g.swing.map = "elsewhere"
	g.swing_step(ToolFxRules.swing_times().windup + 0.01)
	check(not g.farm.cell(front).tilled and got.is_empty(), "a swing whose map changed lands on nothing")
	g.finish_swing()
	# The day's end mid-swing (a collapse): it lands first.
	clear(c)
	got.clear()
	actions.use_tool(c, Vector2i.DOWN, 0)
	var day0: int = g.day_number()
	g.end_day()
	check(not g.swinging() and got.size() == 1 and got[0].burst.target == "soil" and g.day_number() == day0 + 1, "the day's end mid-swing: the swing landed on the day it was swung")
	g.go_to_map(home, c, Vector2i.DOWN)
	g.hour = 10
	g.stamina = g.max_stamina
	# A save mid-swing holds the result; a load mid-swing drops the swing.
	var path := "user://test_tool_fx_save.json"
	clear(c)
	got.clear()
	actions.use_tool(c, Vector2i.DOWN, 0)
	var err := SaveGame.write(g, path)
	check(err == "" and not g.swinging() and g.farm.cell(front).tilled, "a save mid-swing: the swing lands first (%s)" % err)
	g.farm.cell(front).tilled = false
	check(SaveGame.read(g, path) == "" and g.farm.cell(front).tilled, "and the save holds the tilled cell")
	g.farm.cell(front + Vector2i.DOWN).tilled = false
	got.clear()
	actions.use_tool(front, Vector2i.DOWN, 0)
	check(g.swinging(), "a swing before the load")
	check(SaveGame.read(g, path) == "" and not g.swinging() and got.is_empty(), "a load mid-swing drops the swing")
	g.swing_step(1.0)
	check(got.is_empty() and not g.farm.cell(front + Vector2i.DOWN).tilled, "and it never lands on the loaded game")
	for f in [path, path + ".bak"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	g.clock_running = false
	g.hour = 10
	g.stamina = g.max_stamina
	# Holding the button to charge shows the tool's wind-up frame.
	g.charge_tool = "hoe"
	check(g.swing_pose() == "swing_hoe" and g.swing_frame() == 0, "charging the hoe: its wind-up pose (%s)" % g.swing_pose())
	g.charge_tool = "rod"
	check(g.swing_pose() == "", "the rod doesn't charge a swing pose")
	g.charge_tool = ""
	check(g.swing_pose() == "", "and none after")


## The seed scatter: the swing_seeds pose, the cells sown and the packet taken on the hit, seeds
## falling on the cells sown; a scatter that sows nothing still poses but throws nothing.
func _seeds(c: Vector2i) -> void:
	clear(c)
	var front := c + Vector2i.DOWN
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			g.farm.cell(front + Vector2i(dx, dy)).tilled = true
	select("seeds")
	while not g.season_name() in g.crops[g.current_seed()].seasons:
		g.cycle_seed()
	var s: String = g.current_seed()
	g.add_item("seeds:" + s)
	var packets: int = g.count("seeds:" + s)
	g.stamina = g.max_stamina
	got.clear()
	sfx.last = ""
	actions.use_tool(c, Vector2i.DOWN, 0)
	check(g.swing_pose() == "swing_seeds" and g.swing_frame() == 0, "seeds: the scatter pose, the hand back first (%s)" % g.swing_pose())
	check(g.farm.cell(front).crop == "" and g.count("seeds:" + s) == packets and sfx.last == "", "seeds: nothing sown on the press")
	g.swing_step(ToolFxRules.swing_times().windup + 0.01)
	check(g.farm.cell(front).crop == s and g.count("seeds:" + s) == packets - 1 and sfx.last == "tool_seeds", "seeds: sown and the packet taken on the hit")
	check(got.size() == 1 and got[0].burst.target == "sow" and kinds(got[0].burst) == ["seeds"] and got[0].burst.cells.size() == 9, "seeds fall on the 9 cells sown (%s)" % [got.map(func(x): return x.burst.get("cells", []).size())])
	g.finish_swing()
	got.clear()
	actions.use_tool(c, Vector2i.DOWN, 0)
	check(g.swing_pose() == "swing_seeds", "a scatter on sown ground still poses")
	g.finish_swing()
	check(got.is_empty() and g.count("seeds:" + s) == packets - 1, "but throws nothing and keeps the packet")
	clear(c)


## By hand through the buttons (FarmActions.on_action, each swing stepped to its end): till,
## water, sow, grow and harvest one cell.
func _playable(c: Vector2i) -> void:
	clear(c)
	var p := c + Vector2i.DOWN
	g.stamina = g.max_stamina
	g.water = g.WATER_MAX
	select("hoe")
	actions.on_action("tool", c, Vector2i.DOWN)
	finish_swing()
	check(g.farm.cell(p).tilled, "by hand: the hoe tilled")
	select("can")
	actions.on_action("tool", c, Vector2i.DOWN)
	finish_swing()
	check(g.farm.cell(p).wet, "by hand: the can watered")
	select("seeds")
	while not g.season_name() in g.crops[g.current_seed()].seasons:
		g.cycle_seed()
	var s: String = g.current_seed()
	g.add_item("seeds:" + s)
	actions.on_action("tool", c, Vector2i.DOWN)
	finish_swing()
	check(g.farm.cell(p).crop == s, "by hand: sown with %s" % s)
	g.farm.cell(p).stage = g.farm.ripe_stage(s)
	g.held = ""
	actions.on_action("interact", c, Vector2i.DOWN)
	check(g.held == s or g.held.begins_with(s), "by hand: harvested, the %s overhead (%s)" % [s, g.held])
	g.held = ""
	clear(c)


## FarmActions.mine on a real floor: the press pays, the rock breaks and the sounds play on the hit.
func _mine_timing() -> void:
	var f: MineFloor = g.new_mine_floor(1)
	g.maps.mine_floor = f
	var origin := Vector2i(-1, -1)
	for y in range(1, 20):
		for x in range(1, 30):
			var a := Vector2i(x, y)
			var b := a + Vector2i.DOWN
			if f.map.in_bounds(b) and not f.map.is_solid(a) and not f.map.is_solid(b) and b != f.stairs and a != f.stairs and not f.rocks.has(a) and not f.soft.has(b):
				origin = a
				break
		if origin.x >= 0:
			break
	check(origin.x >= 0, "the mine floor has room for a swing")
	if origin.x < 0:
		g.maps.mine_floor = null
		return
	var r := origin + Vector2i.DOWN
	f.rocks[r] = {"kind": "rock", "hits": 1, "done": 0, "find": ""}
	select("hammer")
	g.held = ""
	g.stamina = g.max_stamina
	got.clear()
	sfx.last = ""
	actions.use_tool(origin, Vector2i.DOWN, 0)
	check(f.rocks.has(r) and g.stamina < g.max_stamina and sfx.last == "" and g.swing_pose() == "swing_hammer", "mine: paid on the press, the rock still there")
	g.swing_step(ToolFxRules.swing_times().windup + 0.01)
	check(not f.rocks.has(r) and sfx.last == "rock_break" and got.size() == 1 and got[0].burst.target == "rock", "mine: the rock breaks with its sound and chips on the hit")
	g.finish_swing()
	# A soft spot with the hoe.
	f.soft[r] = ""
	select("hoe")
	got.clear()
	actions.use_tool(origin, Vector2i.DOWN, 0)
	check(f.soft.has(r), "mine: the soft spot still there on the press")
	g.finish_swing()
	check(not f.soft.has(r) and got.size() == 1 and got[0].burst.target == "soft", "mine: dug on the hit")
	# Hands full: no swing at all.
	g.held = "turnip"
	got.clear()
	actions.use_tool(origin, Vector2i.DOWN, 0)
	check(not g.swinging() and got.is_empty(), "mine: hands full, no swing")
	g.held = ""
	g.maps.mine_floor = null


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
	# Every tool stays inside the 24 x 32 picture on both frames, front and back (the blow's heads
	# once went past the left edge and were lost).
	for tool in FigureArt.SWING_TOOLS:
		for back in [false, true]:
			for fr in 2:
				var out := FigureArt.tool_clipped(tool, back, fr)
				check(out == 0, "%s %s frame %d: the tool is all inside the picture (%d px off)" % [tool, "back" if back else "front", fr, out])
	# The scatter: seeds over the fist at the basket, then falling under the open hand.
	for back in [false, true]:
		var hd: Dictionary = FigureArt.hands(FigureArt.FARMER_LOOK, back, "swing_seeds", 1)
		var img := FigureArt.draw(FigureArt.FARMER_LOOK, back, "swing_seeds", 1, true)
		var seeds := 0
		for y in range(hd.near.y + 2, FigureArt.H):
			for x in range(maxi(hd.near.x - 3, 0), mini(hd.near.x + 3, FigureArt.W)):
				var col := img.get_pixel(x, y)
				seeds += int(col.is_equal_approx(FigureArt.SEED) or col.is_equal_approx(FigureArt.SEED_DARK))
		check(seeds >= 3, "swing_seeds %s: seeds falling under the hand (%d)" % ["back" if back else "front", seeds])
		var h0: Dictionary = FigureArt.hands(FigureArt.FARMER_LOOK, back, "swing_seeds", 0)
		check(h0.near.y > hd.near.y, "swing_seeds %s: the hand down at the basket first, then up and out" % ["back" if back else "front"])
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
	# Holding the button charges the hoe in its wind-up pose; letting go swings and tills on the hit.
	var c2 := c + Vector2i(3, 0)
	clear(c2)
	player.position = Vector2(c2 * 16) + Vector2(8, 8)
	player.facing = Vector2i.DOWN
	Input.action_press("use_tool")
	for i in 6:
		await physics_frame
		await process_frame
	check(player.charging and anim.pose == "swing_hoe" and anim.frame() == 0, "%s: charging shows the hoe raised (%s %d, charging %s)" % [name, anim.pose, anim.frame(), player.charging])
	Input.action_release("use_tool")
	var w2 := 0
	while not g.swinging() and w2 < 60:
		await physics_frame
		w2 += 1
	check(g.swinging() and not g.farm.cell(c2 + Vector2i.DOWN).tilled and g.charge_tool == "", "%s: letting go swings; nothing tilled before the hit" % name)
	w2 = 0
	while g.swinging() and w2 < 600:
		await process_frame
		w2 += 1
	check(g.farm.cell(c2 + Vector2i.DOWN).tilled, "%s: the charged swing tilled on the hit" % name)
	# `--charge=hoe` (Game.demo_charge): the button held from the start and never let go: the
	# wind-up pose and the pips stay while the charge climbs; clearing the flag lets go and swings.
	var c3 := c + Vector2i(6, 0)
	clear(c3)
	player.position = Vector2(c3 * 16) + Vector2(8, 8)
	player.facing = Vector2i.DOWN
	g.demo_charge = "hoe"
	for i in 90:
		await physics_frame
		await process_frame
	check(player.charging and g.charge_tool == "hoe" and anim.pose == "swing_hoe" and anim.frame() == 0, "%s: --charge holds the hoe's wind-up (%s %d, charging %s)" % [name, anim.pose, anim.frame(), player.charging])
	check(player.charge >= 1 and not g.swinging() and not g.farm.cell(c3 + Vector2i.DOWN).tilled, "%s: --charge climbs and never lets go (charge %d)" % [name, player.charge])
	g.demo_charge = ""
	w2 = 0
	while not g.swinging() and w2 < 60:
		await physics_frame
		w2 += 1
	check(g.swinging(), "%s: clearing --charge lets go and swings" % name)
	w2 = 0
	while g.swinging() and w2 < 600:
		await process_frame
		w2 += 1
	check(g.farm.cell(c3 + Vector2i.DOWN).tilled, "%s: the released charge tilled on the hit" % name)
	scene.queue_free()
	await process_frame
	await process_frame
