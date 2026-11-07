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
	_tools()
	await _hold_and_throw()
	_bin_and_food()
	await _fishing()
	await _doors()
	await _talk_and_shop()
	await _mine()
	await _weather_and_festival()
	await _night()
	await _water()
	await _ripples()
	await _maples()
	await _footprints()
	scene.free()
	print("test_view2d: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func _scene_built() -> void:
	check(player != null and player.is_inside_tree(), "the 2D scene has its Player")
	check(_is(scene.view, "farm_view.gd") and g.maps.on_farm(), "it starts with the farm view")
	check(player.action.is_connected(actions.on_action), "the Player's actions go to FarmActions")
	check(not g.event_running, "no event is playing")


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
	player.facing = Vector2i.DOWN


## Sends an action as the Player does (its signal), from cell `origin` towards `facing`.
func act(kind: String, origin: Vector2i, facing: Vector2i, charge := 0) -> void:
	player.position = Vector2(origin * 16) + Vector2(8, 8)
	player.facing = facing
	player.action.emit(kind, origin, facing, charge)


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
	act("interact", Vector2i(3, 4), Vector2i.UP)   # at the counter
	check(said.shop == ["general"], "the counter opens the store's screen %s" % [said.shop])


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
	# Under the figures: the glow is a child of the view, drawn before the villagers; the farmer is above the view.
	var order := true
	for n in scene.view.get_children():
		if _is(n, "villager_view.gd") or _is(n, "animal_view.gd"):
			order = order and n.get_index() > nv.get_index()
	check(order and scene.player.get_index() > scene.view.get_index() and nv.z_index == 0, "the glow is drawn under the villagers, animals and farmer")
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


func _water() -> void:
	var fv := FarmView.new()
	fv.farm = g.farm
	root.add_child(fv)
	await process_frame
	_check_water(fv, FarmGrid.W, FarmGrid.H, func(c: Vector2i) -> bool: return g.farm.fixed_at(c) == "pond", true, "the farm pond")
	fv.free()
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
			all = all and fpc.ground_hold(Vector2(x + 0.5, y + 0.5)) >= float(rules.min_hold)
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


