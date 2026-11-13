extends SceneTree
## Headless checks for the flat view (scenes/main_2d.tscn): the scene builds, its Player's
## actions reach FarmActions (tools, holding and throwing, the bin, eating, fishing, doors,
## talking, shops, the mine), the throw is drawn, and the weather and festival lights read
## the same rules as the 3D view (rain / snow, lightning, the lanterns' glow, the lit windows
## and the warm pools at night). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_view2d.gd

var failures := 0
var g: Node
var scene: Node
var player: Node2D
var actions: GDScript   # FarmActions, loaded once Game is up (it names the autoload)
var said := {"dialogue": [], "shop": [], "inventory": [], "thrown": []}


func _initialize() -> void:
	_run()


func _run() -> void:
	g = root.get_node("Game")
	actions = load("res://scripts/farm_actions.gd")
	g.new_game()
	g.clock_running = false   # the trigger tables wait (as on the title screen): no story event gets in the way
	g.hour = 10
	g.dialogue_requested.connect(func(id, at): said.dialogue.append([id, at]))
	g.shop_requested.connect(func(id): said.shop.append(id))
	g.inventory_requested.connect(func(mode): said.inventory.append(mode))
	g.thrown.connect(func(item, _from, to, result): said.thrown.append([item, to, result]))
	scene = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	player = scene.player
	_scene_built()
	await _figure()
	await _figure_sort()
	_tools()
	await _hold_and_throw()
	_bin_and_food()
	await _fishing()
	await _doors()
	await _cradle()
	await _talk_and_shop()
	await _mine()
	await _weather_and_festival()
	await _night()
	await _sprite_light()
	await _water()
	await _ripples()
	await _maples()
	await _maple_art_refined()
	await _footprints()
	await _hearth_smoke()
	await _roofs()
	await _tall_crops()
	await _tall_sway()
	await _persimmon()
	await _silo()
	await _greenhouse()
	scene.free()
	print("test_view2d: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func _scene_built() -> void:
	check(player != null and player.is_inside_tree(), "the 2D scene has its Player")
	check(_is(scene.view, "farm_view.gd") and g.maps.on_farm(), "it starts with the farm view")
	check(player.action.is_connected(actions.on_action), "the Player's actions go to FarmActions")
	check(not g.event_running, "no event is playing")


## The standing figures sort by their feet (FigureLayer, the map view's last child, y-sorted):
## a villager south of the farmer draws over him, one north under him; an animal and a villager the
## same; what the farmer carries is drawn by the Player, so it goes with him; the thrown item, the
## weather and the fades stay where they were; the farmer's shadow is on the ground under them all;
## a map change moves the farmer into the new view's figures.
func _figure_sort() -> void:
	var figs = _figs(scene.view)
	check(load("res://scripts/world/figure_layer.gd").FOOT == FOOT, "the tests' FOOT is FigureLayer's")
	check(figs != null and figs.y_sort_enabled and figs.get_index() == scene.view.get_child_count() - 1, "the flat view's figures are one y-sorted layer, the map view's last child")
	if figs == null:
		return
	var vv = _vv(scene.view)
	var av = _av(scene.view)
	check(player.get_parent() == figs and vv != null and vv.y_sort_enabled and av != null and av.y_sort_enabled and not player.y_sort_enabled,
		"in it: the farmer, the villagers and the animals (each sorting their own figures with the rest)")
	check(figs.shadows != null and figs.shadows.get_index() == figs.get_index() - 1 and player.get_children().all(func(n): return n is Camera2D or n.name == "Figure"),
		"the farmer's contact shadow is drawn on the ground just before the figures, not by the Player")
	check(scene.flying.get_parent() == scene and scene.flying.get_index() > scene.view.get_index() and scene.weather.z_index > 0,
		"the thrown item in flight is drawn after the whole map view, the weather over it")
	var was := player.position
	player.position = Vector2(14 * 16 + 8, 8 * 16 + 8)
	var v := Sprite2D.new()   # a villager sprite as VillagerView makes them
	v.centered = false
	v.offset = player.figure.offset
	v.texture = player.figure.texture
	vv.add_child(v)
	v.position = player.position + Vector2(4, 6)   # south of the farmer, overlapping him
	var order: Array = figs.draw_order()
	check(order.find(v) > order.find(player) and order.find(player) >= 0, "a villager south of the farmer draws over him (%d > %d)" % [order.find(v), order.find(player)])
	v.position = player.position + Vector2(4, -6)   # north of the farmer
	order = figs.draw_order()
	check(order.find(v) < order.find(player) and order.find(v) >= 0, "a villager north of the farmer draws under him (%d < %d)" % [order.find(v), order.find(player)])
	# What the farmer carries overhead is the Player's own drawing: over the villager behind him too.
	g.held = "turnip"
	check(g.holding() and not order.any(func(n): return n.get_parent() == player), "the held item has no node of its own: the Player draws it with the farmer")
	g.held = ""
	v.free()
	# The barn: an animal and a villager sort by their feet, the farmer among them.
	g.animals.add("cow")
	g.go_to_map("barn", Vector2i(3, 6), Vector2i.UP)
	await _wait_view("map_view.gd")
	figs = _figs(scene.view)
	av = _av(scene.view)
	vv = _vv(scene.view)
	check(figs != null and player.get_parent() == figs and player.is_inside_tree(), "a map change moves the farmer into the new view's figures")
	var cows: Array = av.figures() if av != null else []
	check(not cows.is_empty() and cows[0].node != null and cows[0].node.get_parent() == av, "the barn's cow is a node of its own in the animals")
	if not cows.is_empty() and vv != null:
		var cow: Node2D = cows[0].node
		var feet: Vector2 = cows[0].feet
		check(cow.position == feet - Vector2(0, FOOT), "an animal's node sits FOOT px above its feet")
		var w := Sprite2D.new()
		w.centered = false
		w.offset = player.figure.offset
		w.texture = player.figure.texture
		vv.add_child(w)
		w.position = feet - Vector2(0, FOOT) + Vector2(0, 5)   # the villager's feet 5 px in front of the cow's
		order = figs.draw_order()
		check(order.find(w) > order.find(cow), "a villager in front of an animal draws over it")
		w.position = feet - Vector2(0, FOOT) + Vector2(0, -5)
		order = figs.draw_order()
		check(order.find(w) < order.find(cow), "a villager behind an animal draws under it")
		player.position = feet + Vector2(0, -12)
		order = figs.draw_order()
		check(order.find(player) < order.find(cow), "the farmer behind the cow draws under it")
		w.free()
	g.animals.list.pop_back()
	g.go_to_map("farm", Vector2i(14, 8), Vector2i.DOWN)
	await _wait_view("farm_view.gd")
	player.position = was


## The flat farmer is the FigureArt picture the 3D view uses: 24 x 32, feet 2 px below the spot
## like the villagers', turning with the facing and posing with what the farmer does.
func _figure() -> void:
	var fig: Sprite2D = player.get_node_or_null("Figure")
	check(fig != null, "the flat farmer has a figure sprite")
	if fig == null:
		return
	var size := Vector2i(FigureArt.W, FigureArt.H)
	check(fig.texture != null and fig.texture.get_size() == Vector2(size), "its picture is the 24 x 32 FigureArt size")
	check(fig.offset == Vector2(-size.x / 2, 2 - size.y), "its feet stand 2 px below the spot, as the villagers' do")
	for f in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		player.facing = f
		await process_frame
		var key: String = player.anim.key(f)
		check(fig.texture == PlaceholderArt.tex(key), "facing %s shows %s" % [f, key])
		check(fig.texture.get_image().get_data() == FigureArt.draw(FigureArt.FARMER_LOOK, FarmerAnim.is_back(f), player.anim.pose, player.anim.frame(), true).get_data(),
			"facing %s is drawn by FigureArt" % [f])
		check(fig.flip_h == FarmerAnim.is_mirrored(f), "facing %s mirrors %s" % [f, FarmerAnim.is_mirrored(f)])
	check(player.anim.key(Vector2i.DOWN).begins_with("player:front") and player.anim.key(Vector2i.UP).begins_with("player:back"), "down is the front picture, up the back")
	g.held = "turnip"
	player.facing = Vector2i.DOWN
	await process_frame
	await process_frame
	check(player.anim.pose == "hold_idle" and fig.texture == PlaceholderArt.tex(player.anim.key(Vector2i.DOWN)), "carrying an item shows the hold pose")
	g.held = ""
	await process_frame
	check(player.anim.pose == "idle", "putting it down goes back to idle")
	g.start_eat_pose(false)
	await process_frame
	await process_frame
	check(player.anim.pose == "eat" and fig.texture == PlaceholderArt.tex(player.anim.key(Vector2i.DOWN)), "eating shows the eat pose")
	g.eat_pose = ""
	g.eat_left = 0.0
	await process_frame
	await process_frame
	# The goldfish scoop (Game.scooping, ScoopScreen): crouched at the tub with the scoop and bowl.
	player.facing = Vector2i.UP
	g.scooping = true
	await process_frame
	await process_frame
	check(player.anim.pose == "scoop" and fig.texture == PlaceholderArt.tex("player:back:scoop:0"), "the scoop game shows the scoop pose at the tub")
	g.scoop_lifted = true
	await process_frame
	check(player.anim.pose == "scoop_lift", "just after a dip the scoop comes up")
	g.scooping = false
	g.scoop_lifted = false
	await process_frame
	await process_frame
	check(player.anim.pose == "idle", "the scoop game over, back to idle")
	player.facing = Vector2i.DOWN


## Sends an action as the Player does (its signal), from cell `origin` towards `facing`.
func act(kind: String, origin: Vector2i, facing: Vector2i, charge := 0) -> void:
	player.position = Vector2(origin * 16) + Vector2(8, 8)
	player.facing = facing
	player.action.emit(kind, origin, facing, charge)
	while g.swinging():   # a tool swing lands on its hit: step it through, as the frames would (Game.swing_step)
		g.swing_step(1.0 / 30.0)


func select(tool: String) -> void:
	for i in g.inventory.size("tools"):
		if g.inventory.id_at("tools", i) == tool:
			g.select_tool(i)
	check(g.current_tool() == tool, "%s in hand" % tool)


## A clear patch of field around `c` (no weeds, rocks, crops or items).
func clear(c: Vector2i, r := 3) -> void:
	var f: FarmGrid = g.farm
	for y in range(c.y - r, c.y + r + 1):
		for x in range(c.x - r, c.x + r + 1):
			var p := Vector2i(x, y)
			if f.in_bounds(p) and f.fixed_at(p) == "":
				f.cell(p).obj = FarmGrid.Obj.NONE
				f.cell(p).crop = ""
				f.cell(p).tilled = false
				f.take_item_at(p)


func _tools() -> void:
	var c := Vector2i(14, 12)
	clear(c)
	select("hoe")
	var st: int = g.stamina
	act("tool", c, Vector2i.DOWN)
	check(g.farm.cell(c + Vector2i.DOWN).tilled, "the hoe tills the cell in front")
	check(g.stamina < st, "the swing costs stamina")
	select("can")
	var w: int = g.water
	act("tool", c, Vector2i.DOWN)
	check(g.farm.cell(c + Vector2i.DOWN).wet and g.water < w, "the can waters it")


func _hold_and_throw() -> void:
	var c := Vector2i(14, 8)
	clear(c)
	g.held = "turnip"
	act("tool", c, Vector2i.RIGHT)
	check(not g.holding() and g.farm.item_at(c + Vector2i.RIGHT) == "turnip", "the tool button puts it down")
	act("interact", c, Vector2i.RIGHT)
	check(g.held == "turnip" and g.farm.item_at(c + Vector2i.RIGHT) == "", "interact picks it up again")
	act("interact", c, Vector2i.DOWN)
	check(not g.holding() and said.thrown.size() == 1, "interact throws it %s" % [said.thrown])
	if said.thrown.size() != 1:
		return
	var to: Vector2i = said.thrown[0][1]
	check(said.thrown[0][2] == "land" and g.farm.item_at(to) == "turnip", "it lands on the field")
	check(scene.flying.visible and scene.view.hidden_item == to, "the 2D view flies it and hides it on its cell")
	for i in 120:
		if not scene.flying.visible:
			break
		await process_frame
	check(not scene.flying.visible and scene.view.hidden_item == Vector2i(-1, -1), "after the flight it lies on its cell")
	g.farm.take_item_at(to)


func _bin_and_food() -> void:
	var bin := Vector2i(-1, -1)
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			if bin.x < 0 and g.farm.fixed_at(Vector2i(x, y)) == "bin":
				bin = Vector2i(x, y)
	check(bin.x >= 0, "the farm has a bin")
	said.dialogue.clear()
	act("interact", bin + Vector2i.DOWN, Vector2i.UP)
	check(said.dialogue.size() == 1 and said.dialogue[0][0] == "bin_note", "an empty bin shows its note %s" % [said.dialogue])
	g.dialogue_open = false
	select("food")
	g.held = "turnip"
	g.stamina = 10
	act("tool", Vector2i(14, 8), Vector2i.DOWN)
	check(not g.holding() and g.stamina > 10, "the food slot eats the turnip overhead")


func _fishing() -> void:
	select("rod")
	act("tool", Vector2i(24, 3), Vector2i.RIGHT)
	check(g.fishing.active(), "the rod casts into the pond")
	await process_frame   # main_2d's _process sees the cast: a strong ring over the bobber
	var sheet := _water_of(scene.view)
	check(sheet != null and sheet.ripples_alive() == 1 and sheet.ripples[0].w < 0.0,
		"the bobber's landing sends a strong ring over the pond")
	g.fishing.state = "bite"
	act("tool", Vector2i(24, 3), Vector2i.RIGHT)
	check(not g.fishing.active() and str(g.held).begins_with("fish:"), "a press on a bite lands a fish overhead (%s)" % g.held)
	g.held = ""


func _wait_view(file: String) -> void:
	for i in 300:
		if _is(scene.view, file) and not scene.fade.busy():
			return
		await process_frame


func _doors() -> void:
	act("enter", Vector2i(4, 4), Vector2i.UP)   # the farmhouse door at (4, 3)
	check(g.maps.id == "house", "walking into the farmhouse door goes in (%s)" % g.maps.id)
	await _wait_view("map_view.gd")
	check(_is(scene.view, "map_view.gd") and scene.view.map.id == "house", "the 2D view swaps to the house")
	check(player.position == g.maps.pos, "the farmer stands at the door's spawn %s %s" % [player.position, g.maps.pos])


## The baby's cradle in the flat view (CradleView): drawn in the second room while the child
## is a baby, the tool button lifts the baby into the hold pose, the door waits, E lays them back.
func _cradle() -> void:
	g._finish_build({"build": "room", "shop": g._builder_shop("room"), "ready": 0})
	g.flags.merge({"spouse": "sayo", "married_sayo": true})
	Child.tell_news(g.flags, g.day_number())
	Child.give_birth(g.flags, g.day_number(), "Aoi")
	Child.sync_stage(g.flags, g.day_number())
	g.go_to_map("house", Vector2i(10, 2), Vector2i.UP)
	await _wait_view("map_view.gd")
	await process_frame
	var cv: Node = scene.view.get_node_or_null("Cradle")
	check(_is(cv, "cradle_view.gd") and cv.key().begins_with("child:cradle:") and not cv.key().contains(":empty:"), "the flat house draws the baby's cradle")
	act("tool", Vector2i(10, 2), Vector2i.UP)
	await process_frame
	check(g.baby_held and player.anim.key(Vector2i.UP).contains("hold"), "the tool button lifts the baby, the farmer in the hold pose (%s)" % player.anim.key(Vector2i.UP))
	check(cv.key().contains(":empty:"), "the flat cradle is empty while held")
	act("enter", Vector2i(4, 5), Vector2i.DOWN)
	check(g.maps.id == "house" and g.baby_held, "the farmhouse door waits while the baby is held")
	act("interact", Vector2i(10, 2), Vector2i.UP)
	await process_frame
	check(not g.baby_held and not cv.key().contains(":empty:"), "E at the cradle lays the baby back")
	await _crawler()
	for k in ["child_news", "child_born", "child_name", Child.STAGE, "spouse", "married_sayo"]:
		g.flags.erase(k)


## The crawler in the flat view: the tool button facing them lifts them into the hold pose (off
## the floor, the carry picture overhead), the door waits, E sets them down in front.
func _crawler() -> void:
	var was_year: int = g.year
	var was_hour: int = g.hour
	g.year += 1
	Child.give_birth(g.flags, g.day_number() - 30, "Aoi")
	Child.sync_stage(g.flags, g.day_number())
	g.hour = 7
	Villagers.reset_day()
	await process_frame
	var vv = _vv(scene.view)
	var w := Villagers.where(Child.ID, g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	var cell := Vector2i(w.pos.floor())
	check(g.flags.get(Child.STAGE) == "crawler" and vv != null and Child.ID in vv.shown(), "the flat house draws the crawler (%s)" % g.flags.get(Child.STAGE))
	act("tool", cell + Vector2i.LEFT, Vector2i.RIGHT)
	await process_frame
	check(g.crawler_held() and player.anim.key(Vector2i.RIGHT).contains("hold") and not Child.ID in vv.shown(),
		"the tool button lifts the crawler, the farmer in the hold pose, off the floor (%s)" % player.anim.key(Vector2i.RIGHT))
	act("enter", Vector2i(4, 5), Vector2i.DOWN)
	check(g.maps.id == "house" and g.crawler_held(), "the farmhouse door waits while the crawler is held")
	act("interact", cell + Vector2i.LEFT, Vector2i.RIGHT)
	await process_frame
	check(not g.crawler_held() and Child.ID in vv.shown() and vv._sprites[Child.ID].position == (Vector2(cell) + Vector2(0.5, 0.5)) * 16,
		"E sets the crawler down in front, drawn there")
	g.crawler_back()
	g.year = was_year
	g.hour = was_hour
	Villagers.reset_day()


func _talk_and_shop() -> void:
	g.hour = 14
	g.minute = 30
	g.go_to_map("town", Vector2i(2, 10), Vector2i.RIGHT)
	await _wait_view("map_view.gd")
	check(scene.view.map.id == "town", "the 2D view shows the village")
	said.dialogue.clear()
	actions.talk_flag(player, "tome")   # stands below Tome and presses E (as --talk=tome)
	check(said.dialogue.size() == 1 and said.dialogue[0][0] == load("res://scripts/villagers/talk.gd").dialogue_id("tome"), "talking to Tome opens her lines %s" % [said.dialogue])
	check(g.affection.talked_on("tome", g.day_number()), "the talk counts for today")
	g.dialogue_open = false
	g.hour = 11
	g.minute = 0
	var s = g.shop("general")
	g.go_to_map(s.map, g.maps.data(s.map).spawns.start[0], Vector2i.UP)
	await _wait_view("map_view.gd")
	said.shop.clear()
	said.dialogue.clear()
	act("interact", Vector2i(3, 4), Vector2i.UP)   # at the counter, Sayo behind it: she asks buy or talk
	check(said.shop.is_empty() and said.dialogue.size() == 1 and said.dialogue[0][0] == g.KEEPER_DIALOGUE, "Sayo asks first %s" % [said.dialogue])
	g.dialogue_open = false
	g.flags[g.KEEPER_FLAG] = "buy"
	g.dialogue_closed(g.KEEPER_DIALOGUE)
	check(said.shop == ["general"], "Buy opens the store's screen %s" % [said.shop])


func _mine() -> void:
	g.go_to_map(g.mine_map("floor_map"), Vector2i(8, 1), Vector2i.DOWN)
	await _wait_view("map_view.gd")
	var f = g.maps.mine_floor
	check(f != null and scene.view.get_children().any(func(n): return _is(n, "mine_view.gd")), "a mine floor with its rocks in 2D")
	if f == null:
		return
	var c := Vector2i(8, 2)
	f.rocks[c] = {"kind": "rock", "hits": 1, "done": 0, "find": ""}
	select("hammer")
	act("tool", Vector2i(8, 1), Vector2i.DOWN)
	check(not f.rocks.has(c), "the hammer breaks the rock in front")


## Rain / snow and lightning outdoors only, flashes off stops them, and on Lantern Night the
## village's FestivalView lists its lanterns' glows for FestivalGlow.
func _weather_and_festival() -> void:
	var props3d: GDScript = load("res://scripts/world3d/festival_props.gd")   # they name the Game autoload
	var glow: GDScript = load("res://scripts/world3d/festival_glow.gd")
	g.weather_today = "storm"
	scene._show_weather()   # still down the mine: sheltered
	check(scene.weather.fall == "" and not scene.weather._fall.emitting, "no rain falls down the mine")
	check(scene.lightning.step(100.0) == 0.0 and not scene.lightning.started, "no lightning down the mine")
	g.season = 1   # summer 20, 20:00: Lantern Night, into the fireworks
	g.day = 20
	g.hour = 20
	g.minute = 0
	g.go_to_map("town", Vector2i(2, 10), Vector2i.RIGHT)
	await _wait_view("map_view.gd")
	check(scene.weather.fall == "rain" and scene.weather._fall.emitting and scene.weather._splash.emitting, "a storm rains in the village, with splashes")
	check(scene.weather._fall.amount == int(g.weather_style().amount * scene.weather.AMOUNT), "as heavy as the storm's look says (%d)" % scene.weather._fall.amount)
	check(scene.tint.color == g.light_color() and g.light_color().b < 0.75, "the tint is the night light times the storm's tint %s" % scene.tint.color)
	var lit := 0.0
	for i in 200:   # 10 s: the first flash comes within the style's 'first'
		lit = maxf(lit, scene.lightning.step(0.05))
	check(lit > 0.0, "lightning flashes in the storm (%.2f)" % lit)
	var full: Color = Lightning.flash_color(g.lightning_style(), 1.0)
	check(full.r > 0.1 and full.r <= 0.5 and Lightning.flash_color(g.lightning_style(), 0.0) == Color.BLACK, "a flash adds pale light %s" % full)
	scene._update_flash(0.0)
	check(scene.flash.color == Color.BLACK, "no flash while the clock stands")
	g.flashes_enabled = false
	g.settings_changed.emit()
	var none := 0.0
	for i in 400:
		none = maxf(none, scene.lightning.step(0.05))
	check(none == 0.0, "flashes turned off: no lightning in the 2D view")
	g.flashes_enabled = true
	g.season = 3   # a winter storm is a blizzard: snow
	scene._show_weather()
	check(scene.weather.fall == "snow", "a winter storm snows (%s)" % scene.weather.fall)
	g.season = 1
	await process_frame
	check(scene.weather._splash.position == scene.cam.get_screen_center_position(), "the weather follows the camera")
	var fv: Node = null
	for n in scene.view.get_children():
		if _is(n, "festival_view.gd"):
			fv = n
	check(fv != null and fv.festival == "lantern_night" and fv.shown(), "Lantern Night's decorations stand in the 2D village")
	if fv != null:
		var n3d: int = props3d.glows_of("lantern_night", "town").size()
		check(fv.glows.size() == n3d and n3d > 0, "its lights are the 3D props' lights (%d / %d)" % [fv.glows.size(), n3d])
		var lights: Array = props3d.glows_of("lantern_night", "town")
		var hung := n3d > 0
		for i in mini(n3d, fv.glows.size()):
			hung = hung and fv.glows[i].pos == fv.glow_pos(lights[i].pos) and fv.glows[i].pos.y < lights[i].pos.z * 16
		check(hung, "each light shows where its lantern hangs in the picture, above its cell's middle")
		var keys := {}
		for p in Festivals.get_festival("lantern_night").props:
			keys[fv.art_key(p)] = true
		check(keys.has("festival:lantern_line:10x1") and keys.has("festival:stall:2x1:c8442c") and keys.has("festival:drum_stage:2x2"),
			"the decorations are drawn from festival art keys (%s)" % ", ".join(keys.keys()))
		check(fv.is_in_group(fv.GROUP), "FestivalGlow finds it")
	check(scene.glow.is_inside_tree() and glow.fireworks_on() and glow.darkness(g.light_color()) > 0.5, "the glow layer is up, fireworks on, dark enough to shine")
	g.weather_today = "sunny"
	scene._show_weather()
	check(scene.weather.fall == "" and not scene.weather._fall.emitting, "a sunny day: nothing falls")

## Lit windows, lanterns and the warm pools under them at night (NightView): the 3D view's
## spots, pools and brightness (LitSpots, NightLights.pools_from, Game.window_light), on at
## night, off at noon, rising with the dark, drawn under the figures.
func _night() -> void:
	var lights: GDScript = load("res://scripts/world3d/night_lights.gd")   # they name the Game autoload
	var rules: Dictionary = g.light_data().get("pools", {})
	g.weather_today = "sunny"
	g.hour = 21
	g.minute = 0
	await process_frame
	var nv: Node = get_nodes_in_group("night_view")[0] if not get_nodes_in_group("night_view").is_empty() else null
	check(nv != null and _is(nv, "night_view.gd") and nv.get_parent() == scene.view, "the village view has its NightView")
	if nv == null:
		return
	var spots: Dictionary = LitSpots.of_map(g.maps.current().props)
	check(nv.windows.size() == spots.windows.size() and nv.windows.size() > 4 and nv.lamps.size() == spots.lamps.size() and nv.lamps.size() > 0,
		"it lights the village's windows and lanterns (%d / %d)" % [nv.windows.size(), nv.lamps.size()])
	check(is_equal_approx(nv.glow, g.window_light()) and nv.glow == 1.0 and nv.visible, "at 21:00 the windows glow fully (%.2f)" % nv.glow)
	var want: Array = lights.pools_from(nv.windows, nv.lamps, nv.glow, rules)
	# Summer 20 is Lantern Night in the village (17:00..22:00): its lights' pools come after.
	var fest: int = nv.festival_lights.size() if nv.fest_dark > 0.0 else 0
	check(nv.festival == "lantern_night" and fest > 0, "the festival's lights light the ground too (%d)" % fest)
	check(want.size() == nv.windows.size() + nv.lamps.size() and nv.pools.size() == want.size() + fest, "a pool for every lit window and lantern (%d)" % nv.pools.size())
	var same := true
	for i in want.size():
		same = same and is_equal_approx(nv.pools[i].strength, want[i].strength) and nv.pools[i].center == want[i].center
	check(same, "the pools are the 3D view's pools")
	var wp: Dictionary = nv.pools[0]
	var poly: PackedVector2Array = nv.pool_polygon(wp)
	var wall: float = nv.windows[0].pos.z * 16.0
	check(poly.size() == 4 and absf(poly[2].y - wall) < 0.6 and poly[0].y > wall + 24.0 and poly[0].y < wall + 27.0,
		"a window's pool lies on the ground in front of its wall (%s)" % poly)
	var front: Dictionary = nv.windows.filter(func(w): return w.normal.z > 0.5)[0]
	var strip: Rect2 = nv.pane_rect(front)
	check(strip.size.y == 2.0 and absf(strip.get_center().x - front.pos.x * 16.0) < 0.01, "a window shows as a strip on its wall")
	var side: Rect2 = nv.pane_rect(spots.windows.filter(func(w): return w.normal.x > 0.5)[0])
	check(side.size.x == 2.0 and side.size.y > 8.0, "a side window is a strip along its wall")
	# Under the figures: the glow is a child of the view, drawn before its figure layer (the villagers, animals and the farmer).
	var figs = _figs(scene.view)
	check(figs != null and figs.get_index() > nv.get_index() and scene.player.get_parent() == figs and nv.z_index == 0, "the glow is drawn under the villagers, animals and farmer")
	# The night tint is divided out of the colour, so the light is not darkened by it.
	await process_frame
	var mat: ShaderMaterial = nv.get_node("Pools").material
	check(mat.get_shader_parameter("tint") == scene.tint.color, "the shader divides the night tint out")
	# Rising with the dark, gone by day, back before dawn.
	g.hour = 18
	g.minute = 30
	await process_frame
	var dusk: float = nv.glow
	check(dusk > 0.0 and dusk < 1.0 and is_equal_approx(dusk, g.window_light()), "at 18:30 the windows are half lit (%.2f)" % dusk)
	check(nv.pools.size() == want.size() + (fest if nv.fest_dark > 0.0 else 0) and is_equal_approx(nv.pools[0].strength, want[0].strength * dusk), "and the pools fade with them")
	g.hour = 12
	g.minute = 0
	await process_frame
	check(nv.glow == 0.0 and nv.pools.is_empty() and not nv.visible, "at noon: no glow, no pools")
	g.hour = 5
	g.minute = 30
	await process_frame
	check(nv.glow > 0.0 and not nv.pools.is_empty() and nv.visible, "before dawn they are lit again (%.2f)" % nv.glow)
	g.hour = 21
	g.minute = 0
	# The farm: the farmhouse's windows and door, no lanterns.
	g.go_to_map("farm", Vector2i(4, 6), Vector2i.UP)
	await _wait_view("farm_view.gd")
	await process_frame
	var fn: Node = null
	for n in scene.view.get_children():
		if _is(n, "night_view.gd"):
			fn = n
	check(fn != null and fn.windows.size() == LitSpots.farmhouse().size() and fn.lamps.is_empty() and fn.glow == 1.0,
		"the farmhouse's windows glow too")
	# The farmhouse's pools in front of its south wall start at the roof's lower edge (z 4 = 64 px),
	# not over the roof: the raw pool does reach above it, the drawn shape does not.
	var roof_y: float = fn.FARM_ROOF_EDGE * 16.0
	var raw_over := false
	var cut_ok := true
	var south := 0
	for p in fn.pools:
		if p.normal.z < 0.5:
			continue
		south += 1
		var raw: PackedVector2Array = fn.pool_polygon(p)
		for v in raw:
			raw_over = raw_over or v.y < roof_y - 0.5
		var cut: PackedVector2Array = fn.pool_shape(p)[0]
		for v in cut:
			cut_ok = cut_ok and v.y >= roof_y - 0.01
		cut_ok = cut_ok and cut.size() >= 3
	check(south == 3 and raw_over and cut_ok, "the farmhouse's pools stop at the roof's edge (%d south pools, y %.1f)" % [south, roof_y])
	var east_pool: Dictionary = fn.pools.filter(func(p): return p.normal.x > 0.5)[0]
	check(fn.roof_edge == fn.FARM_ROOF_EDGE and fn.pool_shape(east_pool)[0] == fn.pool_polygon(east_pool),
		"the side window's pool is not cut (it lies beside the house)")
	g.hour = 10
	g.minute = 0
	await process_frame
	check(fn != null and not fn.visible and fn.pools.is_empty(), "and not by day")


## The world's light on the flat view's pictures (FlatLight, by the 3D sprites' rules, SpriteLight):
## the sun's share by the clock on the farmer, the villagers, the animals and the field (golden
## morning and evening, plain at noon, at night and indoors), and at night the warm lift near a lit
## window (the same lift_at as the 3D view, at the picture's middle), none in the dark; the modulate
## under the night tint comes out as the 3D view's own x sun x tint + own x sun x warm x lift; the
## marks over the world keep their pictures.
func _sprite_light() -> void:
	var FL: GDScript = load("res://scripts/world/flat_light.gd")
	var SL: GDScript = load("res://scripts/world3d/sprite_light.gd")
	var FW: GDScript = load("res://scripts/world3d/farm_world.gd")
	var CP: GDScript = load("res://scripts/world/crop_patches.gd")
	var rules: Dictionary = SL.rules_of(g.light_data())
	var lr: Dictionary = rules.get("lift", {})
	check(float(lr.get("flat_floor", 0.0)) > 0.0, "flat light: data/light.json has the tint's floor")
	# The modulate's rule: under the tint it is the 3D view's sum.
	var night_tint := Color("46529a")
	var sun := Color(1.0, 0.9, 0.8)
	var warm := Color(str(lr.color))
	var k := 0.4
	var m: Color = FL.color_for(sun, k, rules, night_tint)
	var ok := true
	for i in 3:
		ok = ok and is_equal_approx(m[i] * night_tint[i], sun[i] * night_tint[i] + sun[i] * warm[i] * k)
	check(ok, "flat light: own x modulate x tint = own x sun x tint + own x sun x warm x lift (%s)" % m)
	check(FL.color_for(sun, 0.0, rules, night_tint).is_equal_approx(sun), "flat light: no lift, the sun's share alone")
	check(FL.mid(Vector2(32, 48), 32, FW.FIGURE_PX).is_equal_approx(Vector3(2, 32 * FW.FIGURE_PX / 2.0, 3)),
		"flat light: measured at the picture's middle, as high as the 3D sprite's")
	# By the clock on the farm (sunny): golden in the morning and evening, plain at noon.
	g.weather_today = "sunny"
	var at_time := func(h: int, mm: int) -> void:
		g.hour = h
		g.minute = mm
		scene._update_tint()
	for hm in [[6, 30], [17, 30]]:
		at_time.call(hm[0], hm[1])
		await process_frame
		var want: Color = SL.sun_tint(g.sun_light(false).color, rules)
		var fig: Color = player.figure.self_modulate
		check(not want.is_equal_approx(Color.WHITE) and FL.sun.is_equal_approx(want) and fig.is_equal_approx(want) and player.light.is_equal_approx(want),
			"flat light: the farmer takes the golden share at %d:%02d (%s)" % [hm[0], hm[1], fig])
		check(fig.r >= fig.g and fig.g > fig.b and fig.r <= 1.0, "flat light: warm, never brighter than drawn at %d:%02d" % hm)
	at_time.call(12, 0)
	await process_frame
	check(player.figure.self_modulate.is_equal_approx(Color.WHITE), "flat light: plain at noon")
	check(scene.view._objects.is_in_group(FL.GROUP), "flat light: the field's pictures are redrawn with the light")
	var animals = _av(scene.view)
	check(animals != null and animals.is_in_group(FL.GROUP), "flat light: the animals and the dog are too")
	# A plant of the tall crops is measured at its picture's middle (the 3D field's place).
	var spot := {"tex": "stalk:corn:3:ripe:0", "pos": Vector3(3.5, 0, 4.5), "size": 1.0}
	var tex: Texture2D = PlaceholderArt.tex(spot.tex)
	check(CP.light_mid(spot).is_equal_approx(Vector3(3.5, tex.get_height() * FW.PX / 2.0, 4.5)), "flat light: a plant is measured at its middle")
	# Indoors the sun is plain.
	g.go_to_map("house", Vector2i(4, 6), Vector2i.UP)
	await _wait_view("map_view.gd")
	at_time.call(6, 30)
	await process_frame
	check(player.figure.self_modulate.is_equal_approx(Color.WHITE), "flat light: plain indoors in the morning")
	# Night in the village: warm by a lit window, night blue in the dark.
	g.go_to_map("town", Vector2i(10, 10), Vector2i.DOWN)
	await _wait_view("map_view.gd")
	at_time.call(21, 0)
	await process_frame
	var nv: Node = scene.night
	var spots: Array = SL.spots_of([nv], [{"glows": nv.festival_lights}], g.window_light(), nv.festival_dark(), rules)
	check(not FL.spots.is_empty() and FL.spots.size() == spots.size(), "flat light: the village's lit windows and lanterns light the figures (%d)" % FL.spots.size())
	var win: Dictionary = nv.windows.filter(func(w): return w.normal.z > 0.5)[0]
	var feet := Vector2(win.pos.x, win.pos.z + 0.6) * 16.0
	player.position = feet
	await process_frame
	var near: Color = player.figure.self_modulate
	var lift: float = SL.lift_at(FL.mid(feet, PlaceholderArt.FIGURE_SIZE.y, FW.FIGURE_PX), FL.spots, rules)
	check(lift > 0.1 and near.is_equal_approx(FL.color_for(FL.sun, lift, rules, scene.tint.color)) and near.r > near.b and near.r > 1.0,
		"flat light: by a lit window the farmer reads warm (lift %.2f, %s)" % [lift, near])
	check(FL.at(Vector2(-40, -40) * 16.0, 32, FW.FIGURE_PX).is_equal_approx(Color.WHITE), "flat light: in the dark no lift")
	var villagers: Node = _vv(scene.view)
	var vs: Array = villagers._sprites.values().filter(func(v): return v.visible) if villagers != null else []
	var v_ok := true
	for v in vs:
		v_ok = v_ok and v.self_modulate.is_equal_approx(FL.at(v.position, v.texture.get_height(), FW.FIGURE_PX))
		var note: Node = v.get_node_or_null("Note")
		v_ok = v_ok and (note == null or Color(note.modulate.r, note.modulate.g, note.modulate.b).is_equal_approx(Color.WHITE))
	check(v_ok, "flat light: each villager takes the light where it stands, the note puff does not (%d shown)" % vs.size())
	at_time.call(10, 0)
	await process_frame
	check(FL.spots.is_empty() and player.figure.self_modulate.is_equal_approx(FL.sun), "flat light: by day no lift, the sun's share alone at 10:00")
	g.go_to_map("farm", Vector2i(4, 6), Vector2i.UP)
	await _wait_view("farm_view.gd")


## The water's moving skin (WaterView) in the flat view: the farm pond (FarmView) and the village
## pond / river (MapView) get one, it covers the water cells only, and the bank and foam pixels a
## land side draws on the ground stay still (the sheet starts 3 px in, as in 3D).
## The maple in the flat view is a picture of a tree, not a box (MapView draws PlaceholderArt
## "tree:maple:<season>:<snow>"): every season has a round crown with a trunk and clear corners,
## the leaves in the 3D maple's colours (orange among the reds in fall only), bare branches in
## winter with snow on them only where the map has snow.
func _maples() -> void:
	var mv := MapView.new()
	mv.map = MapManager.data("hill")
	root.add_child(mv)
	await process_frame
	var maples := mv.map.props.filter(func(p): return p.kind == "maple")
	check(maples.size() >= 6, "the hill has its maples in the flat view (%d)" % maples.size())
	# the 3D maple's colours (Trees.LEAVES.maple, Trees.MAPLE_FLAME; this script does not load Trees)
	var flame := Color("dc6a1e")
	var leaves := {"spring": Color("86b844"), "summer": Color("2f6e32"), "fall": Color("c42a1e")}
	for season in ["spring", "summer", "fall", "winter"]:
		for snow in [false, true]:
			var img: Image = PlaceholderArt.image(MapView.maple_key(snow, season))
			var green := 0
			var red := 0
			var orange := 0
			var white := 0
			var bark := 0
			var clear := 0
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					if c.a < 0.5:
						clear += 1
						continue
					if c.g > c.r and c.g > c.b:
						green += 1
					elif c.r > 0.6 and c.g < c.r * 0.5:
						red += 1
					if Vector3(c.r, c.g, c.b).distance_to(Vector3(flame.r, flame.g, flame.b)) < 0.12:
						orange += 1
					if c.r > 0.9 and c.g > 0.9 and c.b > 0.9:
						white += 1
					if c.r < 0.35 and c.g < 0.25 and c.a > 0.5 and c.r > c.g:
						bark += 1
			var what := "%s, snow %s" % [season, snow]
			check(img.get_size() == Vector2i(24, 32), "maple %s: a 24 x 32 picture" % what)
			check(clear > img.get_width() * img.get_height() * 0.4, "maple %s: round, not a box (%d clear)" % [what, clear])
			check(img.get_pixel(0, 0).a < 0.5 and img.get_pixel(23, 0).a < 0.5 and img.get_pixel(0, 31).a < 0.5 and img.get_pixel(23, 31).a < 0.5,
				"maple %s: clear corners" % what)
			check(bark > 10, "maple %s: a trunk or bare branches in bark (%d)" % [what, bark])
			if leaves.has(season):
				check(green + red + orange > 90, "maple %s: a leafy crown (%d)" % [what, green + red + orange])
				check((green > 40) == (season in ["spring", "summer"]), "maple %s: green leaves only in spring and summer (%d)" % [what, green])
				check((orange > 0) == (season == "fall"), "maple %s: orange lumps only in fall (%d)" % [what, orange])
				check(red > 0 or season != "fall", "maple %s: red in fall" % what)
			else:
				check(green == 0 and red == 0 and orange == 0, "maple %s: no leaves in winter" % what)
			check((white > 0) == (season == "winter" and snow), "maple %s: snow on the branches only in winter with snow (%d)" % [what, white])
	mv.free()


## The maple picture is refined (PlaceholderArt._maple_tree through ItemArt.refine): every season
## and snow on / off keeps its 24 x 32 size, has no near-black outline colour (2a1e1e) and has at
## least four colours, so the bark, the leaves' tones and the snow read as separate parts.
func _maple_art_refined() -> void:
	var outline := Color("2a1e1e")
	for season in ["spring", "summer", "fall", "winter"]:
		for snow in [false, true]:
			var img: Image = PlaceholderArt.image(MapView.maple_key(snow, season))
			var what := "%s, snow %s" % [season, snow]
			check(img.get_size() == Vector2i(24, 32), "maple %s refined: still 24 x 32 (%s)" % [what, img.get_size()])
			var outlined := 0
			var colours := {}
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					if c.a < 0.5:
						continue
					colours[c.to_html(false)] = true
					if Vector3(c.r, c.g, c.b).distance_to(Vector3(outline.r, outline.g, outline.b)) < 0.02:
						outlined += 1
			check(outlined == 0, "maple %s refined: no 2a1e1e outline (%d)" % [what, outlined])
			check(colours.size() >= 4, "maple %s refined: at least four colours (%d)" % [what, colours.size()])


func _water() -> void:
	var fv := FarmView.new()
	fv.farm = g.farm
	root.add_child(fv)
	await process_frame
	_check_water(fv, FarmGrid.W, FarmGrid.H, func(c: Vector2i) -> bool: return g.farm.fixed_at(c) == "pond", true, "the farm pond")
	var rules: Dictionary = g.snow_rules
	var fm := _water_of(fv).material as ShaderMaterial
	check(is_equal_approx(float(fm.get_shader_parameter("ice_on")), 0.0), "the flat pond has no ice until it is set")
	_water_of(fv).set_ice(g.ice_for("winter", rules), 0.6)
	check(is_equal_approx(float(fm.get_shader_parameter("ice_on")), 1.0)
		and fm.get_shader_parameter("ice_width") == Vector2(float(rules.ice.width[0]), float(rules.ice.width[1]))
		and is_equal_approx(float(fm.get_shader_parameter("ice_snow")), 0.6 * float(rules.ice.snow)),
		"the flat pond takes the winter ice and its snow from the data")
	_water_of(fv).set_ice(g.ice_for("spring", rules))
	check(is_equal_approx(float(fm.get_shader_parameter("ice_on")), 0.0), "no ice on the flat pond in spring")
	fv.free()
	# The scene pushes the season's ice (outdoors) as it shows the weather.
	var sv := scene.view.get("_water") as WaterView if scene.view != null else null
	if sv != null and not g.sheltered():
		var season_was: int = g.season
		g.season = g.SEASONS.find("winter")
		scene._show_weather()
		check(is_equal_approx(float((sv.material as ShaderMaterial).get_shader_parameter("ice_on")), 1.0), "the flat view's water ices in winter")
		g.season = season_was
		scene._show_weather()
		check(is_equal_approx(float((sv.material as ShaderMaterial).get_shader_parameter("ice_on")), 0.0), "and thaws after")
	else:
		check(false, "the scene's view has water to ice (on %s)" % g.maps.current().id)
	var mv := MapView.new()
	mv.map = MapManager.data("town")
	root.add_child(mv)
	await process_frame
	var town: MapData = mv.map
	_check_water(mv, town.w, town.h, func(c: Vector2i) -> bool: return town.tile(c) == "water", false, "the village water")
	mv.free()


func _check_water(view: Node2D, w: int, h: int, is_water: Callable, edge_bank: bool, what: String) -> void:
	var wv: WaterView = null
	for n in view.get_children():
		if n is WaterView:
			wv = n
	check(wv != null and wv.visible and wv.water_cells > 0, "%s has its moving water" % what)
	if wv == null:
		return
	check(wv.material is ShaderMaterial and (wv.material as ShaderMaterial).shader.code.contains("TIME"),
		"%s's skin is a shader on TIME (drifts)" % what)
	var img: Image = wv.texture.get_image()
	var land := func(n: Vector2i) -> bool:
		if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
			return edge_bank
		return not bool(is_water.call(n))
	var water := 0
	var bad := 0
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			var wet := bool(is_water.call(c))
			water += 1 if wet else 0
			var l: bool = wet and land.call(c + Vector2i.LEFT)
			var r: bool = wet and land.call(c + Vector2i.RIGHT)
			var u: bool = wet and land.call(c + Vector2i.UP)
			var d: bool = wet and land.call(c + Vector2i.DOWN)
			for py in WaterView.T:
				for px in WaterView.T:
					var inside: bool = wet and not (l and px < WaterView.INSET) \
						and not (r and px >= WaterView.T - WaterView.INSET) \
						and not (u and py < WaterView.INSET) \
						and not (d and py >= WaterView.T - WaterView.INSET)
					var p := c * WaterView.T + Vector2i(px, py)
					if (img.get_pixelv(p).a > 0.5) != inside:
						bad += 1
	# Winter ice: each water pixel's red channel is the land round its cell (as the 3D quads).
	var land_bad := 0
	var shore_cells := 0
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			if not bool(is_water.call(c)):
				continue
			var expect := WaterIce.land_mask(c, func(n: Vector2i) -> bool: return not land.call(n))
			shore_cells += 1 if expect != 0 else 0
			if wv.land_at(c * WaterView.T + Vector2i(8, 8)) != expect:
				land_bad += 1
	check(shore_cells > 0 and land_bad == 0, "%s: the mask carries the land round each cell for the ice (%d shore cells, %d wrong)" % [what, shore_cells, land_bad])
	var code: String = (wv.material as ShaderMaterial).shader.code
	check(code.contains("ice_at(") and not code.contains("//ICE//") and code.find("if (ice.a > 0.0)") < code.find("else if (ring > 0.0)"),
		"%s: the ice is drawn first, rings, dimples and glints only on open water" % what)
	check(wv.water_cells == water, "%s: one sheet cell per water cell (%d)" % [what, water])
	check(bad == 0, "%s: the skin covers the water pixels only, banks and foam left still (%d off)" % [what, bad])


## The bobber's rings in the flat view (WaterView.ripple): a call fills a slot, a gentle ring
## lasts RING_LIFE and a strong one RING_LIFE_STRONG, then the slot is empty again. The shader
## gets the same slots, and the ring is drawn by the pond's own sheet only.
func _ripples() -> void:
	var fv := FarmView.new()
	fv.farm = g.farm
	root.add_child(fv)
	await process_frame
	var wv := _water_of(fv)
	check(wv != null and wv.ripples.size() == WaterView.MAX_RIPPLES and wv.ripples_alive() == 0,
		"the pond's sheet has %d ring slots and none at the start" % WaterView.MAX_RIPPLES)
	wv.advance(1.0)   # the clock moves on; the rings start from here
	wv.ripple(Vector2(100, 60))
	wv.ripple(Vector2(100, 60), true)
	check(wv.ripples_alive() == 2 and is_equal_approx(wv.ripples[0].w, WaterView.RING_LIFE)
		and is_equal_approx(wv.ripples[1].w, -WaterView.RING_LIFE_STRONG), "a ripple call fills a slot (gentle, then strong)")
	var m := wv.material as ShaderMaterial
	check(m != null and m.get_shader_parameter("ripples").size() == WaterView.MAX_RIPPLES
		and m.shader.code.contains("ripples[8]"), "the shader reads the ring slots")
	wv.advance(WaterView.RING_LIFE + 0.05)
	check(wv.ripples_alive() == 1, "a gentle ring is gone after %.2f s, a strong one still spreads" % WaterView.RING_LIFE)
	wv.advance(WaterView.RING_LIFE_STRONG)
	check(wv.ripples_alive() == 0, "the strong ring is gone too: the rings expire")
	fv.free()


## Rain dimples in the flat view (WaterView.set_rain): dry until set, the shader reads the style.
func _dimples() -> void:
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weather_fx.json"))
	var fv := FarmView.new()
	fv.farm = g.farm
	root.add_child(fv)
	await process_frame
	var wv := _water_of(fv)
	var m := wv.material as ShaderMaterial
	check(wv != null and wv.rain_density == 0.0 and m.shader.code.contains("dimple_density"), "the flat pond is dry until it rains")
	wv.set_rain(fx.storm.dimples)
	check(is_equal_approx(float(m.get_shader_parameter("dimple_density")), float(fx.storm.dimples.density))
		and is_equal_approx(float(m.get_shader_parameter("dimple_life")), float(fx.storm.dimples.life)), "a storm's density and life reach the flat shader")
	check(wv.ripples_alive() == 0, "dimples use no ring slot")
	wv.set_rain({})
	check(is_equal_approx(float(m.get_shader_parameter("dimple_density")), 0.0), "dry again when it stops")
	fv.free()


func _water_of(view: Node) -> WaterView:
	for n in view.get_children():
		if n is WaterView:
			return n
	return null


func _is(n: Object, file: String) -> bool:
	return n != null and n.get_script() != null and n.get_script().resource_path.ends_with("/" + file)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


## Footprints in lying snow in the flat view (the rules are Footprints', tested in test_maps): the
## farmer's steps leave small prints in a FootprintView of the map's view, none under the snow
## threshold or indoors, gone with the new view, a new day and the snow's age.
func _footprints() -> void:
	var fpc: GDScript = load("res://scripts/footprints.gd")
	var rules: Dictionary = fpc.from_game().rules
	g.weather_today = "sunny"
	g.hour = 10
	g.minute = 0
	g.snow_cover = 80
	g.go_to_map("town", Vector2i(2, 10), Vector2i.RIGHT)
	await _wait_view("map_view.gd")
	var layer: Node = scene.prints
	check(layer != null and _is(layer, "footprint_view.gd") and layer.get_parent() == scene.view and layer.trail.prints.is_empty(), "flat footprints: the view has its FootprintView, empty")
	var row := -1
	for y in scene.view.map.h:
		var all := true
		for x in range(3, 14):
			all = all and fpc.ground_snow(Vector2(x + 0.5, y + 0.5)) >= float(rules.min_hold)
		if all:
			row = y
			break
	check(row >= 0, "flat footprints: the village has a row of ground that holds snow (row %d)" % row)
	var walk := func(x0: float, x1: float, y: float) -> void:
		for i in 41:
			player.position = Vector2(lerpf(x0, x1, i / 40.0), y) * 16.0
			scene._leave_prints()
	walk.call(3.5, 13.5, row + 0.5)
	var n: int = layer.trail.prints.size()
	check(n >= 10 and n <= int(rules.cap), "flat footprints: the farmer's walk leaves a trail (%d)" % n)
	var sides := {}
	for p in layer.trail.prints:
		sides[signf(p.pos.y - (row + 0.5))] = true
	check(sides.has(1.0) and sides.has(-1.0), "flat footprints: left and right prints")
	var SL: GDScript = load("res://scripts/world3d/snow_layer.gd")
	var all_lie := true
	for p in layer.trail.prints:
		all_lie = all_lie and SL.lies(p.pos, 0.8 * float(p.hold))
	check(all_lie, "flat footprints: every print lies where the snow's patch noise has snow")
	var bare_at := Vector2.ZERO
	for i in 400:
		var at := Vector2(3.5 + i * 0.025, row + 0.5)
		if fpc.ground_hold(at) >= float(rules.min_hold) and fpc.ground_snow(at) == 0.0:
			bare_at = at
			break
	check(bare_at != Vector2.ZERO, "flat footprints: the row has a bare patch inside the snow")
	var before_n: int = layer.trail.prints.size()
	for i in 12:
		player.position = (bare_at + Vector2(float(i) * 0.005, 0.0)) * 16.0
		scene._leave_prints()
	check(layer.trail.prints.size() == before_n, "flat footprints: standing on a bare patch leaves no print")
	g.snow_cover = 10
	scene._leave_prints()
	check(layer.trail.prints.is_empty(), "flat footprints: the snow thinning under the threshold takes them away")
	g.snow_cover = 80
	walk.call(3.5, 13.5, row + 0.5)
	scene._on_day_started()
	check(scene.prints.trail.prints.is_empty(), "flat footprints: a new day clears them")
	walk.call(3.5, 13.5, row + 0.5)
	check(not scene.prints.trail.prints.is_empty(), "flat footprints: and a new trail starts")
	scene._age_prints()
	check(is_equal_approx(scene.prints.trail.strength(scene.prints.trail.prints[0]), 1.0 - 1.0 / float(rules.life)), "flat footprints: a minute passing dims them")
	g.go_to_map("house", Vector2i(4, 5), Vector2i.UP)
	await _wait_view("map_view.gd")
	check(scene.prints != layer and scene.prints.trail.prints.is_empty(), "flat footprints: a map change gives a fresh, empty view")
	walk.call(2.5, 6.5, 5.5)
	check(scene.prints.trail.prints.is_empty(), "flat footprints: none indoors, snow or not")
	g.snow_cover = 0




## Hearth smoke in the flat view (SmokeRules, data/smoke.json): the farmhouse and every village house
## send up pixel puffs at meal times (7:00 yes, noon no), indoors none; a storm buries it; the wind
## leans it; the vents are the 3D view's, seen from above.
func _hearth_smoke() -> void:
	var SR: GDScript = load("res://scripts/smoke_rules.gd")
	var cfg: Dictionary = SR.config()
	g.weather_today = "sunny"
	g.snow_cover = 0
	g.hour = 7
	g.minute = 0
	g.go_to_map("farm", Vector2i(10, 8), Vector2i.DOWN)
	await _wait_view("farm_view.gd")
	var sm: Node = scene.smoke
	check(sm != null and _is(sm, "smoke_view.gd") and sm.get_parent() == scene.view, "flat smoke: the farm view has its SmokeView")
	check(sm.vents.size() == 1, "flat smoke: the farmhouse has one vent (%d)" % sm.vents.size())
	if sm.vents.size() == 1:
		var v: Vector3 = SR.farm_vent()
		check(sm.vents[0].is_equal_approx(Vector2(v.x, v.z) * 16.0), "flat smoke: the farmhouse's vent is the 3D view's, from above")
	sm.refresh()
	check(sm.visible and sm.strength() == 1.0, "flat smoke: shown at 7:00")
	check(sm.puffs().size() == int(cfg.puffs), "flat smoke: %d puffs" % int(cfg.puffs))
	var flat: Dictionary = cfg.flat
	var in_reach := true
	for p in sm.puffs():
		in_reach = in_reach and p.pos.y <= sm.vents[0].y + 3.0 and p.pos.y >= sm.vents[0].y - float(flat.rise_px) - 3.0 and p.alpha >= 0.0 and p.alpha <= float(flat.alpha)
	check(in_reach, "flat smoke: the puffs climb from the vent, no further than rise_px")
	g.hour = 12
	sm.refresh()
	check(not sm.visible and sm.strength() == 0.0 and sm.puffs().is_empty(), "flat smoke: gone at noon")
	g.hour = 6
	g.minute = 10
	sm.refresh()
	check(sm.strength() > 0.0 and sm.strength() < 1.0, "flat smoke: eases in at 6:10 (%.2f)" % sm.strength())
	g.hour = 7
	g.minute = 0
	g.weather_today = "storm"
	if g.weather_look("storm", g.season_name()) == "storm":
		sm.refresh()
		check(not sm.visible, "flat smoke: a storm buries it")
	g.weather_today = "sunny"
	sm.refresh()
	var calm: Array = sm.puffs().map(func(p): return p.pos.x)
	g.weather_today = "rain"
	sm.refresh()
	var rainy: Array = sm.puffs().map(func(p): return p.pos.x)
	var leans := false
	for i in calm.size():
		leans = leans or absf(rainy[i] - calm[i]) >= 1.0
	check(leans, "flat smoke: more wind leans the puffs further")
	g.weather_today = "sunny"
	# A village: one vent per house, all alight at 18:00, none at noon; indoors none.
	g.hour = 18
	g.go_to_map("town", Vector2i(2, 10), Vector2i.RIGHT)
	await _wait_view("map_view.gd")
	var houses := 0
	for p in scene.view.map.props:
		houses += 1 if str(p.kind) == "village_house" else 0
	sm = scene.smoke
	check(houses > 0 and sm.vents.size() == houses, "flat smoke: the town has one vent per village house (%d of %d)" % [sm.vents.size(), houses])
	sm.refresh()
	check(sm.visible and sm.puffs().size() == houses * int(cfg.puffs), "flat smoke: every house smokes at 18:00")
	g.hour = 12
	sm.refresh()
	check(not sm.visible, "flat smoke: none in the village at noon")
	g.hour = 7
	g.go_to_map("tome_house", Vector2i(4, 5), Vector2i.UP)
	await _wait_view("map_view.gd")
	check(scene.smoke.vents.is_empty() and not scene.smoke.visible, "flat smoke: indoors, none even at 7:00")
	g.hour = 10


## Tall crops (CropPatches): the flat view reads rice, corn and the vines like the 3D view does.
func _tall_crops() -> void:
	var CP: GDScript = load("res://scripts/world/crop_patches.gd")
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var farm = FarmGrid.new(crops)
	var c = Vector2i(3, 3)
	var fv = FarmView.new()
	fv.farm = farm
	root.add_child(fv)
	var expect = {"rice": [9, 6], "corn": [3, 3], "cucumber": [2, 2], "turnip": [0, 0]}
	for id in expect:
		for growth in [1, 2, 3]:
			var key = CP.cluster_key("crop:%s:%d:growing" % [id, growth])
			var n = CP.standing({c: key}).size() if key != "" else 0
			var want: int = 0 if growth == 1 else expect[id][1 if growth == 2 else 0]
			check(n == want, "flat %s at growth %d stands as %d plants (%d)" % [id, growth, want, n])
	# Planted for real: the cell's sprite is replaced by the cluster, the same key as the 3D view's.
	var d: Dictionary = farm.cell(c)
	d.crop = "rice"
	d.stage = farm.ripe_stage("rice")
	var key = PlaceholderArt.cell_key(farm, d)
	var ck = CP.cluster_key(key)
	check(ck == "stalk:rice:3:ripe", "a ripe rice cell is the cluster %s (%s)" % [ck, key])
	var spots = CP.standing({c: ck})
	check(spots == CP.standing({c: ck}), "the plants stand the same every time (hash of the cell)")
	var spans = {}
	var x0 = 1000.0
	var x1 = -1000.0
	for sp in spots:
		var r = CP.rect_for(sp)
		var ab = r.abs()
		check(ab.size == Vector2(PlaceholderArt.tex(sp.tex).get_size() * float(sp.size)).round(), "a plant is its picture at its size in whole pixels")
		check(ab.end.y >= (c.y + 0.1) * 16 and ab.end.y <= (c.y + 1.0) * 16 + 4, "a plant's foot stands in its cell (%.0f)" % ab.end.y)
		check((r.size.x < 0) == bool(sp.flip), "a flipped plant is drawn mirrored")
		x0 = minf(x0, ab.position.x)
		x1 = maxf(x1, ab.end.x)
		spans[sp.tex] = true
	check(x0 < c.x * 16 + 6 and x1 > (c.x + 1) * 16 - 6, "the rice spreads over the cell (%.0f .. %.0f)" % [x0, x1])
	check(spans.size() >= 2, "the plants use more than one picture variant (%d)" % spans.size())
	# The ripe rice is straw and gold, the green one green (the pictures the 3D view draws).
	var ripe = PlaceholderArt.image(spots[0].tex)
	var gold = 0
	for y in ripe.get_height():
		for x in ripe.get_width():
			var px = ripe.get_pixel(x, y)
			if px.a > 0.5 and px.r > px.b + 0.3 and px.g > 0.55:
				gold += 1
	check(gold >= 8, "a ripe rice hill has gold ears (%d px)" % gold)
	fv.free()
	# The village paddies by season: young, tall, ripe, winter stubble (CropClusters.paddy_key); snow hides the plants on white ground.
	var mv = MapView.new()
	mv.map = MapManager.data("kaminoda")
	mv.snow_rules = g.snow_rules
	root.add_child(mv)
	await process_frame
	var want_key = {"spring": "stalk:rice:2:growing", "summer": "stalk:rice:3:growing", "fall": "stalk:rice:3:ripe", "winter": "stalk:rice:0:stubble"}
	var counts = {}
	for season in want_key:
		mv.set_season(season)
		var cells = mv.paddy_cells()
		counts[season] = CP.standing(cells).size()
		var keys = {}
		for cell in cells:
			keys[cells[cell]] = true
		check(keys.keys() == ([want_key[season]] if want_key[season] != "" else []), "kaminoda %s: paddies grow %s" % [season, want_key[season] if want_key[season] != "" else "nothing"])
	check(counts.winter == counts.summer and counts.spring > 0 and counts.summer > counts.spring, "kaminoda paddies: stubble in winter in the nine-hill layout, fewer plants young (%s)" % [counts])
	mv.set_season("summer")
	var paddies = mv.paddy_cells()
	var bare = CP.standing(paddies).size()
	check(CP.standing(paddies, mv.paddy_hold, 0.0).size() == bare, "no snow lying hides nothing")
	var some = CP.standing(paddies, mv.paddy_hold, 0.8).size()
	var most = CP.standing(paddies, mv.paddy_hold, 1.0).size()
	check(some < bare and most <= some, "snow lying hides the plants on white ground (%d, %d, %d)" % [bare, some, most])
	check(mv.paddy_cells().keys().all(func(cell): return mv.map.tile(cell) == "paddy" and mv.map.prop_at(cell).is_empty()), "only prop-free paddy cells grow rice")
	mv.free()
	await _water_patches()
	await _paddy_ground()
	_paddy_tiles()
	await _water_glint()


## The winter water patches of the flat view (CropPatches.draw_water): the 3D view's places
## (CropClusters.water_spots_for) in winter only, none under snow lying on their paddy, and the
## blob drawn in the data's colours (data/paddy.json), the same colours as the 3D picture.
func _water_patches() -> void:
	var CP: GDScript = load("res://scripts/world/crop_patches.gd")
	var cc: GDScript = load("res://scripts/world3d/crop_clusters.gd")
	var mv = MapView.new()
	mv.map = MapManager.data("kaminoda")
	mv.snow_rules = g.snow_rules
	root.add_child(mv)
	await process_frame
	var per = {}
	for season in ["spring", "summer", "fall", "winter"]:
		mv.set_season(season)
		per[season] = CP.water_to_draw(season, mv.paddy_cells(), mv.paddy_hold, 0.0).size()
	check(per.winter > 0, "flat water: kaminoda has water patches in winter (%d)" % per.winter)
	check(per.spring == 0 and per.summer == 0 and per.fall == 0, "flat water: none in spring, summer or fall (%s)" % [per])
	mv.set_season("winter")
	var cells = mv.paddy_cells()
	var want = cc.water_spots_for(cells.keys())
	var got = CP.water_to_draw("winter", cells)
	var same = got.size() == want.size()
	for i in range(mini(got.size(), want.size())):
		same = same and got[i].pos == want[i].pos and got[i].cell == want[i].cell and got[i].size == want[i].size
	check(same and got.size() > 0, "flat water: the same places and sizes as the 3D view's water_spots_for (%d)" % got.size())
	check(CP.water_to_draw("winter", cells, mv.paddy_hold, 0.0).size() == want.size(), "flat water: no snow, every patch shows")
	var snowy = CP.water_to_draw("winter", cells, mv.paddy_hold, 1.0)
	var lying = want.filter(func(s): return SnowLayer.lies(Vector2(s.pos.x, s.pos.z), mv.paddy_hold(s.cell)))
	check(lying.size() > 0 and snowy.size() + lying.size() == want.size(), "flat water: heavy snow hides %d of %d patches by the paddy's hold" % [lying.size(), want.size()])
	check(snowy.all(func(s): return not SnowLayer.lies(Vector2(s.pos.x, s.pos.z), mv.paddy_hold(s.cell))), "flat water: none left lying under snow")
	# The blob's colours are data/paddy.json's, and the 3D picture uses the same three.
	var data: Dictionary = cc.paddy_data().get("water", {})
	var blob = CP.water_texture().get_image()
	var colours = {}
	for y in blob.get_height():
		for x in blob.get_width():
			var px = blob.get_pixel(x, y)
			if px.a > 0.5:
				colours[px.to_html(false)] = true
	var pic = PlaceholderArt.tex("patch:paddy_water").get_image()
	var pic_colours = {}
	for y in pic.get_height():
		for x in pic.get_width():
			var px = pic.get_pixel(x, y)
			if px.a > 0.5:
				pic_colours[px.to_html(false)] = true
	var json_colours = [data.color, data.glint, data.sky]
	check(colours.size() == 3 and json_colours.all(func(c): return colours.has(c)), "flat water: the blob is drawn in data/paddy.json's colours (%s)" % [colours.keys()])
	check(json_colours.all(func(c): return pic_colours.has(c)), "flat water: the same colours as the 3D picture patch:paddy_water")
	mv.free()



## The tall crops' sway (CropPatches.sway_tip / band_shifts): still at calm, more in a storm, vines
## stiffer than rice, the same every time for a place, only whole pixels, the root row never moved.
func _tall_sway() -> void:
	var CP: GDScript = load("res://scripts/world/crop_patches.gd")
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/wind.json"))
	var calm: float = rules.strength.sunny
	var rain: float = rules.strength.rain
	var storm: float = rules.strength.storm
	check(CP.sway_tip(0.0, 3.0, 4.2, 5.1) == 0.0 and CP.sway_now(0.0, 3.0).is_empty(), "no wind: no sway at all")
	var peak = {}
	for w in [calm, rain, storm]:
		var m := 0.0
		var mv := 0.0
		for i in 400:
			var t := i / float(CP.flat_config().rate)
			m = maxf(m, absf(CP.sway_tip(w, t, 4.2, 5.1)))
			mv = maxf(mv, absf(CP.sway_tip(w, t, 4.2, 5.1, 0.6)))
		peak[w] = [m, mv]
	check(peak[calm][0] < 1.0, "a sunny breeze: the rice tip swings under a pixel (%.2f), a 1 px twitch at the crest at most" % peak[calm][0])
	check(peak[rain][0] > peak[calm][0] and peak[storm][0] > peak[rain][0], "more wind, more sway (%s)" % [peak])
	check(peak[storm][0] >= 2.0, "a storm moves the tip by 2 px or more (%.2f)" % peak[storm][0])
	check(peak[storm][1] < peak[storm][0] * 0.7 and peak[rain][1] < peak[rain][0], "a vine on its stake sways less than rice (%s)" % [peak])
	check(CP.sway_tip(storm, 2.25, 4.2, 5.1) == CP.sway_tip(storm, 2.25, 4.2, 5.1), "the sway is the same for the same time and place")
	var phases = {}
	for x in 6:
		phases[snappedf(CP.sway_tip(storm, 1.0, float(x), 2.0), 0.01)] = true
	check(phases.size() >= 4, "plants in different places sway out of step (%d phases)" % phases.size())
	var sh: Array[int] = CP.band_shifts(2.4, 4)
	check(sh.size() == 4 and sh[0] >= sh[1] and sh[1] >= sh[2] and sh[3] == 0 and sh[0] == 2, "the top band moves most, the root band never (%s)" % [sh])
	check(CP.band_shifts(0.4, 4).all(func(v): return v == 0), "under half a pixel nothing is shifted")
	var a: Dictionary = CP.sway_now(1.0, 5.07)
	var b: Dictionary = CP.sway_now(1.0, 5.11)
	check(a == b and a.t != 5.07, "the sway time is kept to the sway's frame rate (%s)" % [a])
	check(CP.band_shifts(3.0).size() == int(CP.flat_config().bands), "one shift a band")
	# Drawn for real, swaying: the draw runs without error.
	var cv := Node2D.new()
	root.add_child(cv)
	cv.draw.connect(func(): CP.draw(cv, {Vector2i(3, 3): "stalk:rice:3:ripe"}, Callable(), 0.0, {"wind": 1.0, "t": 0.0}))
	cv.queue_redraw()
	await process_frame
	cv.free()


## Kiku's grown persimmon tree through the flat view (data/scion.json pick, Player -> FarmActions):
## the first press picks one overhead, the second puts one in the rucksack (the crown drawn half
## full, then bare), the third says the rest are for the birds and throws nothing; each step
## redraws the tree's picture; the next morning it is full again.
func _persimmon() -> void:
	g.flags["kiku_scion"] = "door"
	g.flags[Scion.day_flag()] = g.day_number() - Scion.from_days("tree")
	g.season = 2
	g.held = ""
	var msgs: Array = []
	g.message.connect(func(t): msgs.append(t))
	var hints: GDScript = load("res://scripts/ui/action_hints.gd")   # loaded here: it names the Game autoload
	g.go_to_map("farm", Vector2i(3, 5), Vector2i.UP)
	await _wait_view("farm_view.gd")
	var tree := Vector2i(3, 4)
	var prop: Dictionary = g.maps.current().prop_at(tree)
	var sv := _story_view()
	check(sv != null and prop.get("kind", "") == "scion", "the flat farm has Kiku's grown tree")
	if sv == null:
		return
	var drawn: Array = []   # the key each redraw of the story props drew for the tree
	sv.draw.connect(func(): drawn.append(StoryView.art_key(prop)))
	sv.queue_redraw()
	await process_frame
	check(drawn.back() == "story:scion:tree:fall:0", "the full crown is drawn (%s)" % [drawn])
	var thrown_before: int = said.thrown.size()
	check(hints.interact_verb(Vector2i(3, 5), Vector2i.UP) == "Pick", "the hint says Pick at the full tree")
	act("interact", Vector2i(3, 5), Vector2i.UP)
	await process_frame
	await process_frame
	check(g.held == "wild:persimmon" and g.scion_picked == 1 and msgs.back() == "Picked the ripe persimmon.",
		"the first press picks one overhead (%s)" % [msgs])
	check(drawn.back() == "story:scion:tree:fall:0:4", "half the crown is drawn (%s)" % [drawn])
	# Holding one with fruit left: the hint still says Pick, and the press puts it in the rucksack.
	check(hints.interact_verb(Vector2i(3, 5), Vector2i.UP) == "Pick" and hints.pick(Vector2i(3, 5), Vector2i.UP).interact == "Pick",
		"holding one with fruit left, the hint says Pick")
	var thrown_held: int = said.thrown.size()
	act("interact", Vector2i(3, 5), Vector2i.UP)
	await process_frame
	await process_frame
	check(g.count("wild:persimmon") == 2 and g.scion_picked == 2 and msgs.back() == "Put the ripe persimmon in the rucksack.",
		"the second press puts one in the rucksack (%s)" % [msgs])
	check(said.thrown.size() == thrown_held, "the press while holding never throws at the tree")
	check(drawn.back() == "story:scion:tree:fall:0:0", "the crown is bare (%s)" % [drawn])
	act("interact", Vector2i(3, 5), Vector2i.UP)
	await process_frame
	await process_frame
	check(msgs.back() == "The rest are for the birds.", "the third press: the birds (%s)" % [msgs])
	check(g.count("wild:persimmon") == 2 and said.thrown.size() == thrown_before, "nothing is thrown at the tree")
	check(hints.interact_verb(Vector2i(3, 5), Vector2i.UP) == "Look", "the hint at the bare tree is not Throw")
	g.held = ""   # hands empty at the bare tree: Look too, and a press still never throws
	check(hints.interact_verb(Vector2i(3, 5), Vector2i.UP) == "Look" and hints.pick(Vector2i(3, 5), Vector2i.UP).use_tool != "Throw",
		"hands empty at the bare tree: the hint says Look")
	act("interact", Vector2i(3, 5), Vector2i.UP)
	await process_frame
	await process_frame
	check(msgs.back() == "The rest are for the birds." and said.thrown.size() == thrown_before and not g.holding(),
		"hands empty at the bare tree: the birds, nothing thrown")
	check(drawn.has("story:scion:tree:fall:0") and drawn.has("story:scion:tree:fall:0:4") and drawn.has("story:scion:tree:fall:0:0"),
		"the view redrew each of the three pictures (%s)" % [drawn])
	var a: Image = PlaceholderArt.tex("story:scion:tree:fall:0").get_image()
	var b: Image = PlaceholderArt.tex("story:scion:tree:fall:0:4").get_image()
	var c: Image = PlaceholderArt.tex("story:scion:tree:fall:0:0").get_image()
	check(_differs(a, b) > 0 and _differs(b, c) > 0 and _differs(a, c) > 0, "the three pictures differ")
	g.end_day()
	g.go_to_map("farm", Vector2i(3, 5), Vector2i.UP)
	await _wait_view("farm_view.gd")
	sv = _story_view()
	if sv == null:
		check(false, "the farm view has its story props the next morning")
		return
	drawn.clear()
	sv.draw.connect(func(): drawn.append(StoryView.art_key(prop)))
	sv.queue_redraw()
	await process_frame
	check(g.scion_picked == 0 and drawn.back() == "story:scion:tree:fall:0", "the next morning the crown is full (%s)" % [drawn])
	g.held = ""
	g.flags.erase("kiku_scion")
	g.new_game()


func _story_view() -> Node:
	for n in scene.view.get_children():
		if _is(n, "story_view.gd"):
			return n
	return null


## The flat view's paddy ground (MapView.ground_key_in, CropPatches.paddy_ground): the paddy cells
## that grow rice get a calm picture with no painted tufts, which the rice is drawn over (flooded
## water in spring to fall, drained mud in winter where the water patches lie). Other cells keep
## their ground picture, and the 3D view's painted paddy tile keeps its tufts.
func _paddy_ground() -> void:
	var mv = MapView.new()
	mv.map = MapManager.data("kaminoda")
	mv.snow_rules = g.snow_rules
	root.add_child(mv)
	await process_frame
	var tuft_html := [Color("4e7e34").to_html(false), Color("62983e").to_html(false), Color("94c464").to_html(false)]
	var water_html := [Color("5d7680").to_html(false), Color("7d939b").to_html(false), Color("9aaeb4").to_html(false), Color("b89a5a").to_html(false)]
	var colours_of = func(img: Image) -> Dictionary:
		var found := {}
		for y in img.get_height():
			for x in img.get_width():
				var px: Color = img.get_pixel(x, y)
				if px.a > 0.5:
					found[px.to_html(false)] = true
		return found
	var has_tufts = func(img: Image) -> bool:
		var found: Dictionary = colours_of.call(img)
		return tuft_html.any(func(h): return found.has(h))
	check(has_tufts.call(PlaceholderArt.image("ground:paddy:0")), "flat paddy ground: the 3D view's painted paddy tile keeps its tufts")
	for season in ["spring", "summer", "fall", "winter"]:
		mv.set_season(season)
		var paddies = mv.paddy_cells()
		var want_kind := "paddy_mud" if season == "winter" else "paddy_flood"
		var bad := 0
		var kinds := {}
		for c in paddies:
			var key: String = mv.ground_key_in(c, paddies)
			kinds[key.get_slice(":", 1)] = true
			if not key.begins_with("ground:%s:" % want_kind) or has_tufts.call(PlaceholderArt.image(key)):
				bad += 1
		check(paddies.size() > 0 and bad == 0 and kinds.keys() == [want_kind], "flat paddy ground in %s: %d rice cells on %s, none with painted tufts (%d off)" % [season, paddies.size(), want_kind, bad])
		var same := true
		for y in mv.map.h:
			for x in mv.map.w:
				var c := Vector2i(x, y)
				if not paddies.has(c) and mv.ground_key_in(c, paddies) != MapView.ground_key(mv.map, c):
					same = false
		check(same, "flat ground: cells without rice keep their ground picture in %s" % season)
		if season == "winter":
			var mud: Dictionary = colours_of.call(PlaceholderArt.image("ground:paddy_mud:0"))
			var clash := water_html.filter(func(h): return mud.has(h))
			check(clash.is_empty(), "flat paddy ground: the drained mud carries no water or stubble colour (%s)" % [clash])
	mv.free()


## The flat view's paddy ground pictures (PlaceholderArt "paddy_flood" and "paddy_mud"): every
## variant is painted, not flat (at least four colours), and repeats seamlessly: the wrap column
## (15 next to 0) and the wrap row (15 next to 0) differ on average no more than the worst of the
## tile's own neighbouring columns or rows does. The drained mud carries no water or stubble colour.
func _paddy_tiles() -> void:
	var dist := func(a: Color, b: Color) -> float:
		return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
	var water_html := ["5d7680", "7d939b", "9aaeb4", "b89a5a"]
	for kind in ["paddy_flood", "paddy_mud"]:
		var flat := 0
		var seam_fail := 0
		for n in PlaceholderArt.GROUND_VARIANTS:
			var img: Image = PlaceholderArt.image("ground:%s:%d" % [kind, n])
			var size := img.get_size()
			var colours := {}
			for y in size.y:
				for x in size.x:
					colours[img.get_pixel(x, y).to_html(false)] = true
			if colours.size() < 4:
				flat += 1
			# Mean difference across each pair of neighbouring columns (x, x + 1) and rows (y, y + 1).
			var col_means := []
			var row_means := []
			for x in size.x:
				var sum := 0.0
				for y in size.y:
					sum += dist.call(img.get_pixel(x, y), img.get_pixel((x + 1) % size.x, y))
				col_means.append(sum / size.y)
			for y in size.y:
				var sum := 0.0
				for x in size.x:
					sum += dist.call(img.get_pixel(x, y), img.get_pixel(x, (y + 1) % size.y))
				row_means.append(sum / size.x)
			var worst_inside := 0.0
			for x in size.x - 1:
				worst_inside = maxf(worst_inside, col_means[x])
			for y in size.y - 1:
				worst_inside = maxf(worst_inside, row_means[y])
			var seam := maxf(col_means[size.x - 1], row_means[size.y - 1])
			if seam > worst_inside + 0.0001:
				seam_fail += 1
			if kind == "paddy_mud":
				for h in water_html:
					if colours.has(h):
						check(false, "flat paddy mud tile %d carries the water / stubble colour %s" % [n, h])
		check(flat == 0, "%s: every variant is painted, not flat (%d with fewer than four colours)" % [kind, flat])
		check(seam_fail == 0, "%s repeats seamlessly: the wrap column and row are no harsher than the tile's inside edges (%d variants over)" % [kind, seam_fail])


## The water patches' glint in the flat view (CropPatches.glint_dots): a patch's light moves over
## time, two patches are not in step, one or two pixels a patch, whole pixels inside the patch,
## faster in a storm than under a calm sky, and none while snow lies on the ground.
func _water_glint() -> void:
	var CP: GDScript = load("res://scripts/world/crop_patches.gd")
	var cc: GDScript = load("res://scripts/world3d/crop_clusters.gd")
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/wind.json"))
	var calm: float = rules.strength.sunny
	var rain: float = rules.strength.rain
	var storm: float = rules.strength.storm
	var mv = MapView.new()
	mv.map = MapManager.data("kaminoda")
	mv.snow_rules = g.snow_rules
	root.add_child(mv)
	await process_frame
	mv.set_season("winter")
	var patches: Array = CP.water_to_draw("winter", mv.paddy_cells())
	check(patches.size() >= 2, "flat glint: the winter paddies have water patches to glint (%d)" % patches.size())
	var rate: float = CP.flat_config().glint.rate
	var frames := 120   # 30 s at the glint's frame rate
	var seen := {}
	var same_steps := 0
	var bad := 0
	var counts := {}
	# A second patch of the same size and facing, moved to another place (so its own phase),
	# so the two columns compare by phase alone.
	var other: Dictionary = patches[0].duplicate()
	other.pos = Vector3(float(patches[0].pos.x) + 0.37, 0.0, float(patches[0].pos.z) + 0.21)
	var left0: int = int(CP.water_rect(patches[0]).abs().position.x)
	var left1: int = int(CP.water_rect(other).abs().position.x)
	for i in frames:
		var at: float = i / rate
		var g0: Array = CP.glint_dots(patches[0], CP.glint_now(rain, at))
		var g1: Array = CP.glint_dots(other, CP.glint_now(rain, at))
		seen[str(g0)] = true
		# Both patches' first light in the same column of its own patch: in step.
		if g0.size() > 0 and g1.size() > 0 and g0[0].x - left0 == g1[0].x - left1:
			same_steps += 1
		for s in patches:
			var dots: Array = CP.glint_dots(s, CP.glint_now(rain, at))
			counts[dots.size()] = true
			var r: Rect2 = CP.water_rect(s).abs()
			for d in dots:
				if not r.has_point(Vector2(d)):
					bad += 1
	check(seen.size() >= 3, "flat glint: a patch's light moves over time (%d positions in 30 s)" % seen.size())
	check(same_steps < frames / 2, "flat glint: two patches are not in step (%d of %d frames in the same column)" % [same_steps, frames])
	check(counts.keys().all(func(n): return n == 1 or n == 2) and counts.has(1) and counts.has(2),
		"flat glint: one or two light pixels a patch (%s)" % [counts.keys()])
	check(bad == 0, "flat glint: whole pixels, inside their patch (%d off)" % bad)
	# Faster in rain and storm: the light changes place more often in a storm than under a calm sky.
	var changes := {}
	for w in [calm, storm]:
		var n := 0
		var last := ""
		for i in frames:
			var dots := str(CP.glint_dots(patches[0], CP.glint_now(w, i / rate)))
			if i > 0 and dots != last:
				n += 1
			last = dots
		changes[w] = n
	check(changes[storm] > changes[calm], "flat glint: a storm moves the light more often than a calm sky (%s)" % [changes])
	# None under snow lying on the ground, none with no glint.
	var leftover := 0
	for s in patches:
		leftover += CP.glint_dots(s, CP.glint_now(storm, 2.0), 1.0).size()
		leftover += CP.glint_dots(s, CP.glint_now(storm, 2.0), 0.4).size()
		leftover += CP.glint_dots(s, {}).size()
	check(leftover == 0, "flat glint: none under snow, none with no glint (%d)" % leftover)
	check(CP.water_on("winter") and not CP.water_on("spring") and not CP.water_on("summer") and not CP.water_on("fall"),
		"flat glint: the water, and so its glint, is winter only")
	# The light's colour is data/paddy.json's water.shine.
	var shine_data := String(cc.paddy_data().get("water", {}).get("shine", ""))
	check(shine_data != "" and CP.shine_colour().is_equal_approx(Color(shine_data)), "flat glint: the light is data/paddy.json's water.shine (%s)" % [shine_data])
	mv.free()


func _colours(img: Image) -> int:
	var seen := {}
	for y in img.get_height():
		for x in img.get_width():
			seen[img.get_pixel(x, y)] = true
	return seen.size()


func _differs(a: Image, b: Image) -> int:
	var n := 0
	for y in a.get_height():
		for x in a.get_width():
			n += 1 if a.get_pixel(x, y) != b.get_pixel(x, y) else 0
	return n


## Painted roofs (RoofArt): each kind is a picture of several colours at the old box's size, a hip
## differs from a gable, thatch from kawara, and the views draw them from their data.
func _roofs() -> void:
	var size := Vector2i(78, 46)
	var pics := {}
	for m in ["kawara", "thatch", "kaya"]:
		for shape in ["gable", "hip"]:
			for storeys in [1, 2]:
				var key: String = RoofArt.key(m, shape, storeys, size)
				var img := PlaceholderArt.image(key)
				pics[key] = img
				check(img.get_size() == size, "roof %s: the old box's size" % key)
				check(_colours(img) >= 6, "roof %s: several colours (%d)" % [key, _colours(img)])
				var clear := 0
				for y in size.y:
					for x in size.x:
						clear += 1 if img.get_pixel(x, y).a < 1.0 else 0
				check(clear == 0, "roof %s: covers its whole box" % key)
	check(_differs(pics[RoofArt.key("kawara", "gable", 1, size)], pics[RoofArt.key("kawara", "hip", 1, size)]) > 100, "roof: a hip differs from a gable")
	check(_differs(pics[RoofArt.key("kawara", "gable", 1, size)], pics[RoofArt.key("kawara", "gable", 2, size)]) > 100, "roof: two storeys differ from one")
	check(_differs(pics[RoofArt.key("thatch", "gable", 1, size)], pics[RoofArt.key("kawara", "gable", 1, size)]) > 1000, "roof: thatch differs from kawara")
	check(_differs(pics[RoofArt.key("kaya", "gable", 1, size)], pics[RoofArt.key("thatch", "gable", 1, size)]) > 1000, "roof: the farmhouse's kaya differs from the coop's thatch")
	# The light is from the upper left: the north slope of a gable is brighter than the south one.
	var gable: Image = pics[RoofArt.key("kawara", "gable", 1, size)]
	check(gable.get_pixel(40, 8).get_luminance() > gable.get_pixel(40, 38).get_luminance(), "roof: the north slope is lit, the south one shaded")
	# The farm's buildings: the rects are the old boxes' footprints.
	var farm: FarmGrid = g.farm
	check(FarmView.roof_rect(farm, "house") == Rect2(32, 16, 80, 48), "roof: the farmhouse's footprint %s" % FarmView.roof_rect(farm, "house"))
	check(FarmView.roof_rect(farm, "coop") == Rect2(Vector2(FarmGrid.COOP.position * 16), Vector2(FarmGrid.COOP.size * 16)), "roof: the coop's footprint")
	check(FarmView.roof_rect(farm, "barn") == Rect2(Vector2(FarmGrid.BARN.position * 16), Vector2(FarmGrid.BARN.size * 16)), "roof: the barn's footprint")
	# The town's houses draw their roofs by their data (roof, storeys).
	g.go_to_map("town", Vector2i(2, 10), Vector2i.RIGHT)
	await _wait_view("map_view.gd")
	var seen := {}
	for p in scene.view.map.props:
		if str(p.kind) == "village_house":
			var st: Dictionary = LitSpots.village_style(p)
			seen["%s%d" % [st.roof, st.storeys]] = true
	check(seen.has("gable1") and seen.has("hip1"), "roof: the town has gable and hip houses (%s)" % [seen.keys()])
	scene.view._objects.queue_redraw()
	await process_frame


## The fodder silo in the flat view: not there until Hachiro has built it, then a solid round
## tower the farmer cannot walk into, grass from the sickle goes in, E carries the fodder out.
func _silo() -> void:
	player.farm = g.farm   # earlier parts started new games: the scene follows the farm that is now
	g.go_to_map("farm", Vector2i(30, 4), Vector2i.UP)
	await process_frame
	check(g.maps.on_farm() and not g.maps.is_solid(Vector2i(29, 1), g.farm), "flat: no silo before it is built, the cells are open")
	g.money = 50000
	check(g.shop_build("general", "silo").ok, "flat: the silo ordered")
	g._finish_build(g.house_job.duplicate())
	g.go_to_map("farm", Vector2i(30, 4), Vector2i.UP)   # waking on the farm: the view follows
	await process_frame
	scene.view._objects.queue_redraw()
	await process_frame
	check(g.farm.fixed_at(Vector2i(29, 1)) == "silo" and FarmView.roof_rect(g.farm, "silo") == Rect2(29 * 16, 16, 32, 32), "flat: the silo's four cells and its box")
	check(g.maps.is_solid(Vector2i(30, 2), g.farm) and not g.maps.is_solid(Vector2i(30, 3), g.farm), "flat: the tower is solid, the cell in front is open")
	player.position = Vector2(Vector2i(30, 3) * 16) + Vector2(8, 8)
	player.facing = Vector2i.UP
	var moved := true
	for k in 20:
		moved = player._try_move(Vector2.UP * 2)
	check(not moved and player.position.y > 3 * 16, "flat: the farmer stops below the silo (y %.1f)" % player.position.y)
	var c := Vector2i(26, 9)
	clear(c)
	g.farm.cell(c + Vector2i.DOWN).obj = FarmGrid.Obj.WEED
	select("sickle")
	act("tool", c, Vector2i.DOWN)
	check(g.animals.silo.grass == 1, "flat: a weed cut with the sickle is a bundle of grass (%d)" % g.animals.silo.grass)
	var box := FarmView.roof_rect(g.farm, "silo")
	if scene.view.farm != g.farm:   # earlier parts started new games on the same scene
		scene.view.farm = g.farm
	var handful: Rect2 = scene.view.silo_pile_rect()
	check(handful.has_area() and box.encloses(handful) and handful.size == Vector2(PlaceholderArt.tex("silo:grass:1:0").get_size()), "flat: the silo's grass pile shows a handful (%s)" % handful)
	g.animals.silo.grass = 30
	var heap: Rect2 = scene.view.silo_pile_rect()
	check(heap.size.x > handful.size.x and heap.end == handful.end, "flat: a big heap at 30, from the same corner (%s)" % heap)
	g.animals.silo.grass = 1
	g.animals.silo.fodder = 4
	var hint_words: String = load("res://scripts/ui/action_hints.gd").pick(Vector2i(30, 3), Vector2i.UP).interact
	check(hint_words == "Fodder 4, grass 1", "flat: the HUD hint at the silo shows the stores: %s" % hint_words)
	var loft: int = g.animals.stock_of("barn")
	act("interact", Vector2i(30, 3), Vector2i.UP)
	check(g.animals.stock_of("barn") == loft + 4 and g.animals.silo.fodder == 0, "flat: E at the silo carries its fodder to the loft")


## The greenhouse in the flat view: open ground before it is built, the glasshouse and its door
## after, through the door to the beds (drawn by a FarmView of Game.greenhouse at the plots
## corner), the hoe, the can, a summer seed in winter, the tub filling the can, picking a ripe
## crop and setting it down on a bed.
func _greenhouse() -> void:
	player.farm = g.farm
	g.go_to_map("farm", Vector2i(27, 17), Vector2i.UP)
	await process_frame
	# The site is open field and the farm is random: debris (15% of the field cells) may lie on the
	# door cell. Clear that one cell so the check reads the door, not the dice.
	g.farm.cell(Vector2i(27, 16)).obj = FarmGrid.Obj.NONE
	check(not g.maps.is_solid(Vector2i(27, 16), g.farm) and g.maps.door_at(Vector2i(27, 16)).is_empty(), "flat: no greenhouse door before it is built")
	g.money = 50000
	check(g.shop_build("general", "greenhouse").ok, "flat: the greenhouse ordered")
	g._finish_build(g.house_job.duplicate())
	g.go_to_map("farm", Vector2i(27, 17), Vector2i.UP)
	await _wait_view("farm_view.gd")
	scene.view._objects.queue_redraw()
	await process_frame
	check(FarmView.roof_rect(g.farm, "greenhouse") == Rect2(25 * 16, 14 * 16, 80, 48), "flat: the greenhouse's box: %s" % FarmView.roof_rect(g.farm, "greenhouse"))
	check(g.maps.is_solid(Vector2i(26, 16), g.farm) and not g.maps.is_solid(Vector2i(27, 17), g.farm), "flat: the glasshouse is solid, the cell before its door open")
	# Snow on its glass roof (and the other farm roofs) over the objects, as the 3D roofs take it:
	# in the glass bays and on the ridge cap, not on the rafters, the eaves' strip or the front wall;
	# the farmhouse's whole roof but its rim and round its door. At night the lantern inside lights
	# the glass, the farmhouse's windows and the greenhouse's.
	var roofs: Image = SnowLayer.farm_roof_mask_image(g.farm, g.snow_rules)
	var px := SnowLayer.ROOF_PER_CELL / 16.0
	var at := func(p: Vector2) -> float: return roofs.get_pixelv(Vector2i(p * px)).r
	var held: Dictionary = g.snow_rules.farm_roofs
	var gh := Vector2(FarmGrid.GREENHOUSE.position * 16)
	var ridge := FarmView.GREENHOUSE_RIDGE
	var foot := FarmGrid.GREENHOUSE.size.y * 16 - FarmView.GREENHOUSE_WALL
	check(absf(at.call(gh + Vector2(4, 6)) - float(held.greenhouse)) < 0.01 and absf(at.call(gh + Vector2(68, ridge + 6)) - float(held.greenhouse)) < 0.01
		and at.call(gh + Vector2(40, ridge + 1)) > 0.0, "flat: snow lies in the greenhouse's glass bays and on its ridge (%.2f)" % at.call(gh + Vector2(4, 6)))
	check(at.call(gh + Vector2(8, 6)) == 0.0 and at.call(gh + Vector2(16, ridge + 6)) == 0.0 and at.call(gh + Vector2(20, foot - 2)) == 0.0
		and at.call(gh + Vector2(20, 1)) == 0.0, "flat: not on the rafters or the strips at the eaves (glass sheds it)")
	check(at.call(gh + Vector2(4, foot + 4)) == 0.0 and at.call(Vector2(FarmGrid.GREENHOUSE_DOOR * 16) + Vector2(8, 8)) == 0.0 and at.call(gh + Vector2(-8, 8)) == 0.0,
		"flat: not on its front wall, door or the field beside it")
	var house := FarmView.roof_rect(g.farm, "house")
	var door := Vector2(4, 3) * 16
	check(absf(at.call(house.position + Vector2(4, 4)) - float(held.house)) < 0.01 and at.call(house.position + Vector2(4, house.size.y - 4)) > 0.0
		and at.call(house.position) == 0.0 and at.call(door + Vector2(8, 8)) == 0.0 and at.call(door + Vector2(-1, 8)) == 0.0,
		"flat: the farmhouse's whole roof takes snow too, its rim and its door bare")
	var silo := FarmView.roof_rect(g.farm, "silo")
	check(not silo.has_area() or (at.call(silo.position + Vector2(16, 10)) > 0.0 and at.call(silo.position + Vector2(16, 24)) == 0.0), "flat: the silo's cone, not its staves")
	scene.view.set_snow(0.8)
	var glow_layer: Node = scene.view.get_node_or_null("Roofs")
	check(scene.view._roof_snow != null and scene.view._roof_snow.visible and scene.view._roof_snow.get_index() > scene.view._objects.get_index()
		and glow_layer != null and glow_layer.get_index() > scene.view._objects.get_index() and glow_layer.get_index() < scene.view._roof_snow.get_index(),
		"flat: the roofs' snow is drawn over the buildings, and over the glow on the glass roof")
	var sm := scene.view._roof_snow.material as ShaderMaterial
	check(sm.shader.code.contains("top_full") and is_equal_approx(float(sm.get_shader_parameter("top_full")), SnowLayer.TOP_FULL),
		"flat: the roofs fill as the 3D snow tops do (whole from half cover)")
	scene.view.set_snow(0.0)
	check(not scene.view._roof_snow.visible, "flat: and gone when no snow lies")
	check(scene.night.windows.size() == LitSpots.farmhouse().size() + LitSpots.greenhouse().size(), "flat: the greenhouse's lit glass with the farmhouse's windows (%d)" % scene.night.windows.size())
	var was := [g.hour, g.minute]
	g.hour = 21
	g.minute = 0
	await process_frame
	var lit: Array = scene.night.pools.filter(func(p: Dictionary) -> bool: return FarmGrid.GREENHOUSE.grow(1).has_point(Vector2i(int(p.center.x), int(p.center.z))))
	check(scene.night.glow == 1.0 and lit.size() == 2, "flat: at night a warm pool in front of the greenhouse's glass and beside it (%d)" % lit.size())
	check(scene.night.roof_glows.size() == 2 and glow_layer.visible, "flat: and the lantern's glow on the glass roof")
	check(scene.night.windows.filter(func(w: Dictionary) -> bool: return w.get("flat_hide", false)).size() == 1
		and scene.night.pools.size() >= scene.night.windows.size(), "flat: the +x patch draws no strip (no side wall) but keeps its pool")
	g.hour = was[0]
	g.minute = was[1]
	await process_frame
	act("enter", Vector2i(27, 17), Vector2i.UP)
	check(g.maps.id == "greenhouse", "flat: the door leads into the greenhouse (%s)" % g.maps.id)
	await _wait_view("map_view.gd")
	var beds: FarmView = null
	for n in scene.view.get_children():
		if n is FarmView:
			beds = n
	check(beds != null and beds.farm == g.greenhouse and beds.position == Vector2(1, 2) * 16, "flat: the beds drawn by a FarmView of the greenhouse grid at the plots corner")
	g.season = 3   # winter
	g.stamina = 100
	g.greenhouse.from_dict(g.new_greenhouse().to_dict())
	var bed := Vector2i(3, 3)   # map cell; the grid's (2, 1)
	select("hoe")
	act("tool", bed + Vector2i.DOWN, Vector2i.UP)
	check(g.greenhouse.cell(Vector2i(2, 1)).tilled, "flat: the hoe tills a bed")
	g.add_item("seeds:tomato")
	select("seeds")
	while g.current_seed() != "tomato":
		g.cycle_seed()
	act("tool", bed + Vector2i.DOWN, Vector2i.UP)
	check(g.greenhouse.cell(Vector2i(2, 1)).crop == "tomato", "flat: a summer seed sown in winter under glass")
	select("can")
	g.water = 0
	act("tool", Vector2i(8, 2), Vector2i.UP)   # the tub at (8, 1)
	check(g.water == g.WATER_MAX, "flat: the tub fills the can")
	act("tool", bed + Vector2i.DOWN, Vector2i.UP)
	check(g.greenhouse.cell(Vector2i(2, 1)).wet, "flat: the can waters the bed")
	var d: Dictionary = g.greenhouse.cell(Vector2i(2, 1))
	d.stage = g.greenhouse.ripe_stage("tomato")
	act("interact", bed + Vector2i.DOWN, Vector2i.UP)
	check(g.held == "tomato", "flat: E picks the ripe tomato overhead (%s)" % g.held)
	var free_bed := Vector2i(6, 3)
	g.greenhouse.till(free_bed - Vector2i(1, 2))
	act("tool", free_bed + Vector2i.DOWN, Vector2i.UP)
	check(not g.holding() and g.greenhouse.item_at(free_bed - Vector2i(1, 2)) == "tomato", "flat: the tool button sets it down on a bed")
	act("interact", free_bed + Vector2i.DOWN, Vector2i.UP)
	check(g.held == "tomato", "flat: and E picks it up again")
	g.held = ""
	g.go_to_map("farm", Vector2i(27, 17), Vector2i.DOWN)
	await _wait_view("farm_view.gd")


## The flat view's figure layer (FigureLayer, found by name: the tests load before the autoloads,
## so they do not name the class) and the villagers' / animals' views in it.
const FOOT := 2   # FigureLayer.FOOT (checked in test_view2d)


func _figs(view: Node) -> Node2D:
	return view.get_node_or_null("Figures") as Node2D if view != null else null


func _vv(view: Node) -> Node:
	return _in_figs(view, "villager_view.gd")


func _av(view: Node) -> Node:
	return _in_figs(view, "animal_view.gd")


func _in_figs(view: Node, file: String) -> Node:
	var layer := _figs(view)
	if layer != null:
		for n in layer.get_children():
			if n.get_script() != null and n.get_script().resource_path.ends_with(file):
				return n
	return null
