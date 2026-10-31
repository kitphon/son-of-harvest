extends SceneTree
## Headless checks for the flat view (scenes/main_2d.tscn): the scene builds, its Player's
## actions reach FarmActions (tools, holding and throwing, the bin, eating, fishing, doors,
## talking, shops, the mine) and the throw is drawn. Run:
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
	_tools()
	await _hold_and_throw()
	_bin_and_food()
	_fishing()
	await _doors()
	await _talk_and_shop()
	await _mine()
	scene.free()
	print("test_view2d: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func _scene_built() -> void:
	check(player != null and player.is_inside_tree(), "the 2D scene has its Player")
	check(_is(scene.view, "farm_view.gd") and g.maps.on_farm(), "it starts with the farm view")
	check(player.action.is_connected(actions.on_action), "the Player's actions go to FarmActions")
	check(not g.event_running, "no event is playing")


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


func _is(n: Object, file: String) -> bool:
	return n != null and n.get_script() != null and n.get_script().resource_path.ends_with("/" + file)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
