extends SceneTree
## Headless inventory checks (Inventory slots and rules, InventoryMenu, Game's bag calls, the
## storage chest on the farm, the rucksack key). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_inventory.gd

const TOOLS: Array[String] = ["hoe", "can", "sickle", "hammer", "axe", "seeds", "food", "rod"]

var failures := 0


func _init() -> void:
	_data()
	_slots()
	_move_rules()
	_save_format()
	_menu()
	_arms_full()
	_game()
	_item_art_refined()
	_food_art_refined()
	_fish_mine_wild_art_refined()
	_kitchen_keep_ribbon_art_refined()
	print("test_inventory: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


## The data file has every place, sane numbers and starting things that fit.
func _data() -> void:
	var d := Inventory.data()
	for place in Inventory.PLACES:
		check(int(d.slots.get(place, 0)) >= 1, "data: %s has slots" % place)
	check(int(d.slots.hand) == 1, "data: one hand")
	check(int(d.stack_max) >= 2, "data: items stack")
	check(d.start.tools.size() <= int(d.slots.tools), "data: start tools fit the tool slots")
	for id in d.start.tools:
		check(id in TOOLS, "data: start tool %s is a tool" % id)
	var inv := Inventory.starting(TOOLS)
	check(inv.id_at("tools", 0) == "hoe" and inv.id_at("tools", 5) == "seeds", "start: tools in order")
	check(inv.count("seeds:turnip") == 2 and inv.count("seeds:potato") == 1, "start: seed bags in the rucksack")
	check(inv.totals(["chest"]).is_empty(), "start: empty chest")


func _slots() -> void:
	var d := {"slots": {"tools": 3, "bag": 3, "hand": 1, "chest": 4}, "stack_max": 10}
	var inv := Inventory.empty(TOOLS, d)
	check(inv.size("bag") == 3 and inv.size("chest") == 4 and inv.size("hand") == 1, "sizes from data")
	# Stacking: the same id fills its stack first, then empty slots; the rest doesn't fit.
	check(inv.add("turnip", 7) == 0 and inv.slot("bag", 0) == {"id": "turnip", "n": 7}, "add 7 turnips: one stack")
	check(inv.add("turnip", 5) == 0 and inv.slot("bag", 0).n == 10 and inv.slot("bag", 1) == {"id": "turnip", "n": 2}, "add 5 more: full stack + new one")
	check(inv.add("milk", 1) == 0 and inv.id_at("bag", 2) == "milk", "any id sits in a slot")
	check(inv.room_for("turnip") == 8 and inv.room_for("egg") == 0, "room: what the stacks still take")
	check(inv.add("turnip", 9) == 1 and inv.count("turnip") == 20, "a full bag gives back what didn't fit")
	check(inv.add("egg", 2) == 2, "no slot for a new id")
	# Taking: all or nothing.
	check(not inv.take("turnip", 21) and inv.count("turnip") == 20, "can't take more than there is")
	check(inv.take("turnip", 13) and inv.count("turnip") == 7 and inv.slot("bag", 0).is_empty(), "take empties a slot")
	check(inv.take("milk") and inv.slot("bag", 2).is_empty(), "last one taken empties the slot")
	# Tools go only in tool slots and the chest, never stack; items never go in tool slots.
	check(inv.accepts("tools", "hoe") and inv.accepts("chest", "hoe"), "tools: tool slots and chest")
	check(not inv.accepts("bag", "hoe") and not inv.accepts("hand", "axe"), "tools: not in the bag or hand")
	check(not inv.accepts("tools", "turnip") and inv.accepts("hand", "turnip"), "items: not in tool slots")
	check(inv.add("hoe", 1, ["bag"]) == 1, "a tool won't go in the bag")
	check(inv.add("hoe", 2, ["tools"]) == 0 and inv.id_at("tools", 1) == "hoe", "tools take one slot each")
	check(inv.limit("hoe") == 1 and inv.limit("turnip") == 10, "stack limits")
	# Carried = the bag and the hand, not the chest.
	inv.add("egg", 3, ["chest"])
	inv.slots.hand[0] = {"id": "egg", "n": 1}
	check(inv.count("egg") == 1 and inv.count("egg", ["chest"]) == 3, "carried counts leave the chest out")
	check(inv.totals() == {"turnip": 7, "egg": 1}, "totals of what is carried")
	# A bigger rucksack (shop upgrade later): grow never cuts.
	inv.grow("bag", 6)
	check(inv.size("bag") == 6 and inv.slot("bag", 5).is_empty(), "grow adds empty slots")
	inv.grow("bag", 2)
	check(inv.size("bag") == 6, "grow never shrinks")
	# Old bag counts: into the bag, the rest into the chest, which grows rather than lose any.
	var small := Inventory.empty(TOOLS, {"slots": {"tools": 1, "bag": 1, "hand": 1, "chest": 1}, "stack_max": 5})
	small.set_carried({"turnip": 12, "corn": 3})
	check(small.count("turnip") + small.count("turnip", ["chest"]) == 12 and small.count("corn", ["chest"]) == 3, "set_carried keeps every item")
	check(small.size("chest") > 1, "set_carried grows the chest when it must")


func _move_rules() -> void:
	var inv := Inventory.empty(TOOLS, {"slots": {"tools": 2, "bag": 3, "hand": 1, "chest": 3}, "stack_max": 10})
	inv.add("hoe", 1, ["tools"])
	inv.add("turnip", 6)
	inv.add("potato", 2)
	check(inv.move("bag", 0, "chest", 2) and inv.id_at("chest", 2) == "turnip" and inv.slot("bag", 0).is_empty(), "move to an empty slot")
	check(inv.move("bag", 1, "chest", 2) and inv.id_at("chest", 2) == "potato" and inv.id_at("bag", 1) == "turnip", "move onto another id swaps")
	inv.add("turnip", 8, ["chest"])
	# chest 0 has 8 turnips; bag 1 has 6: 2 go on, 4 stay behind.
	check(inv.move("bag", 1, "chest", 0) and inv.slot("chest", 0).n == 10 and inv.slot("bag", 1).n == 4, "stacking: the rest stays behind")
	check(not inv.move("bag", 1, "chest", 0), "a full stack takes no more")
	check(not inv.move("tools", 0, "bag", 0), "a tool can't move into the bag")
	check(not inv.move("bag", 1, "tools", 1), "an item can't move into a tool slot")
	inv.add("can", 1, ["chest"])
	var can_at := -1
	for i in inv.size("chest"):
		if inv.id_at("chest", i) == "can":
			can_at = i
	check(inv.move("chest", can_at, "tools", 0) and inv.id_at("tools", 0) == "can" and inv.id_at("chest", can_at) == "hoe", "tool swaps with a tool from the chest")
	check(not inv.move("chest", 0, "tools", 0), "an item can't swap into a tool slot")
	check(not inv.move("bag", 2, "chest", 0), "moving an empty slot does nothing")
	# drop / lift (what the menu cursor does).
	var s := inv.lift("bag", 1)
	check(s == {"id": "turnip", "n": 4} and inv.slot("bag", 1).is_empty(), "lift takes the whole stack")
	check(inv.drop("tools", 1, s) == s and inv.slot("tools", 1).is_empty(), "drop refused leaves both alone")
	check(inv.drop("hand", 0, s).is_empty() and inv.slot("hand", 0).n == 4, "drop into the hand")
	check(inv.stow({"id": "turnip", "n": 3}, "bag", 1).is_empty() and inv.slot("bag", 1).n == 3, "stow: back where it came from")


func _save_format() -> void:
	var inv := Inventory.starting(TOOLS)
	inv.add("turnip", 5)
	inv.add("cucumber", 4, ["chest"])
	inv.slots.hand[0] = {"id": "egg", "n": 1}
	var saved: Dictionary = JSON.parse_string(JSON.stringify(inv.to_dict()))   # numbers come back as floats
	var parsed := Inventory.parse(saved, TOOLS)
	check(parsed[0] == "", "saved inventory parses (%s)" % parsed[0])
	if parsed[0] == "":
		check(parsed[1].to_dict() == inv.to_dict(), "saved inventory comes back the same")
		check(typeof(parsed[1].slot("bag", 2).n) == TYPE_INT, "counts come back as ints")
	for bad in [[], {"tools": []}, {"tools": [null], "bag": "x", "hand": [], "chest": []}]:
		check(Inventory.parse(bad, TOOLS)[0] != "", "refused: %s" % JSON.stringify(bad))
	for broken in [["bag", 0, {"id": "hoe", "n": 1}], ["tools", 0, {"id": "turnip", "n": 1}],
			["bag", 0, {"id": "turnip", "n": 0}], ["bag", 0, {"id": "turnip", "n": 100}],
			["bag", 0, {"id": "turnip", "n": 2.5}], ["bag", 0, {"id": "", "n": 1}], ["bag", 0, {"n": 1}],
			["bag", 0, "turnip"], ["tools", 0, {"id": "hoe", "n": 2}], ["hand", 0, {"id": "axe", "n": 1}]]:
		var d: Dictionary = saved.duplicate(true)
		d[broken[0]][broken[1]] = broken[2]
		check(Inventory.parse(d, TOOLS)[0] != "", "refused slot %s" % JSON.stringify(broken))
	# A save with fewer slots than the data has now gets the data's count; more slots are kept.
	var d: Dictionary = saved.duplicate(true)
	d.bag.resize(3)
	d.chest.append(null)
	parsed = Inventory.parse(d, TOOLS)
	check(parsed[0] == "" and parsed[1].size("bag") == inv.size("bag") and parsed[1].size("chest") == inv.size("chest") + 1, "slot counts: data minimum, upgrades kept")


func _menu() -> void:
	var inv := Inventory.empty(TOOLS, {"slots": {"tools": 3, "bag": 10, "hand": 1, "chest": 4}, "stack_max": 10})
	for t in ["hoe", "can"]:
		inv.add(t, 1, ["tools"])
	inv.add("turnip", 6)
	inv.add("potato", 2)
	var m := InventoryMenu.new(inv, "rucksack", 1)
	check(m.rows.size() == 4 and m.rows[0] == ["tools", 0, 3] and m.rows[1] == ["bag", 0, 8] and m.rows[2] == ["bag", 8, 2] and m.rows[3] == ["hand", 0, 1], "rucksack rows")
	check(m.place() == "tools" and m.index() == 1, "cursor starts on the tool in hand")
	m.move(0, 1)
	check(m.place() == "bag" and m.index() == 1, "down keeps the column")
	m.move(0, 1)
	check(m.place() == "bag" and m.index() == 9, "second bag row")
	m.move(0, 1)
	check(m.place() == "hand" and m.index() == 0, "a short row clamps the column")
	m.move(0, 1)
	check(m.place() == "tools", "down from the last row wraps")
	m.move(-1, 0)
	check(m.index() == 2, "left wraps round the row")
	check(m.point("bag", 9) and m.place() == "bag" and m.index() == 9, "pointing at a slot")
	check(not m.point("chest", 0), "the chest isn't on the rucksack screen")
	# Pick up, refuse a wrong place, put down, swap, stack.
	m.point("bag", 0)
	check(m.choose() == "" and m.carry == {"id": "turnip", "n": 6} and inv.slot("bag", 0).is_empty(), "pick up a stack")
	m.point("tools", 2)
	check(m.choose() != "" and m.carry.n == 6, "items don't go in tool slots")
	m.point("bag", 1)
	m.choose()
	check(m.carry == {"id": "potato", "n": 2} and inv.slot("bag", 1) == {"id": "turnip", "n": 6}, "putting down on another id swaps")
	m.point("bag", 5)
	m.choose()
	check(m.carry.is_empty() and inv.slot("bag", 5).n == 2, "put down in an empty slot")
	inv.add("potato", 9, ["bag"])   # tops slot 5 up to 10, 1 goes in the first empty slot (0)
	m.point("bag", 0)
	m.choose()
	m.point("bag", 5)
	m.choose()
	check(m.carry == {"id": "potato", "n": 1}, "a full stack leaves the rest on the cursor")
	check(m.hold() != "", "can't hold while carrying")
	check(m.close() == "" and m.carry.is_empty() and inv.slot("bag", 0) == {"id": "potato", "n": 1}, "closing puts the stack back where it came from")
	# Hold: a tool slot becomes the tool in hand; an item goes in the hand; the hand goes back.
	m.point("tools", 0)
	m.hold()
	check(m.tool_slot == 0, "hold on a tool slot: tool in hand")
	m.point("bag", 1)
	check(m.hold() == "" and inv.slot("hand", 0) == {"id": "turnip", "n": 6} and inv.slot("bag", 1).is_empty(), "hold an item: into the hand")
	m.point("bag", 5)
	m.hold()
	check(inv.id_at("hand", 0) == "potato" and inv.id_at("bag", 5) == "turnip", "hold another item: swaps with the hand")
	m.point("hand", 0)
	check(m.hold() == "" and inv.slot("hand", 0).is_empty() and inv.count("potato") == 11, "hold on the hand: back into the rucksack")
	# Storage: the chest on top; a tool from the chest swaps with the tool in hand.
	inv.add("axe", 1, ["chest"])
	var st := InventoryMenu.new(inv, "storage", 0)
	check(st.rows[0] == ["chest", 0, 4] and st.place() == "chest" and st.heading() == "Storage chest", "storage: chest first")
	st.point("chest", 0)
	check(st.hold() == "" and inv.id_at("tools", 0) == "axe" and inv.id_at("chest", 0) == "hoe", "hold a chest tool: swaps with the tool in hand")
	st.point("bag", 3)
	st.choose()   # an empty slot: nothing picked up
	check(st.carry.is_empty(), "picking an empty slot carries nothing")
	st.point("bag", 5)
	st.choose()
	st.point("chest", 3)
	st.choose()
	check(inv.id_at("chest", 3) == "turnip" and st.carry.is_empty(), "rucksack to chest")
	# Closing with a stack nowhere to go stays open.
	var full := Inventory.empty(TOOLS, {"slots": {"tools": 1, "bag": 1, "hand": 1, "chest": 1}, "stack_max": 10})
	full.add("hoe", 1, ["tools"])
	full.add("can", 1, ["chest"])
	var fm := InventoryMenu.new(full, "storage", 0)
	fm.point("tools", 0)
	fm.choose()
	fm.point("chest", 0)
	fm.choose()   # swap: hoe in the chest, carrying the can
	fm.point("tools", 0)
	fm.choose()   # can into the tool slot
	check(fm.carry.is_empty() and full.id_at("tools", 0) == "can" and full.id_at("chest", 0) == "hoe", "swap tools through the chest")
	full.add("turnip", 1)
	full.slots.hand[0] = {"id": "egg", "n": 1}
	fm.point("bag", 0)
	fm.choose()
	fm.point("hand", 0)
	fm.choose()   # swap: turnip in hand, carrying the egg; the only hole is the bag slot
	fm.point("bag", 0)
	full.slots.bag[0] = {"id": "milk", "n": 1}   # something filled the hole
	check(fm.close() != "" and fm.carry.id == "egg", "no room: the screen stays open")


## With the baby, the crawler or the dog in the arms the hands are full: the rucksack and the chest
## never put an item in the hand slot (hold, choose), and a carried stack can't be put there.
func _arms_full() -> void:
	var g: Node = (load("res://scripts/autoload/game.gd") as GDScript).new()
	g.new_game()
	var inv := Inventory.empty(TOOLS, {"slots": {"tools": 3, "bag": 10, "hand": 1, "chest": 4}, "stack_max": 10})
	inv.add("turnip", 6)
	inv.add("axe", 1, ["chest"])
	for who in ["baby", "crawler", "dog"]:
		g.baby_held = who == "baby"
		g.animals.dog.held = who == "dog"
		Child.carried = {"held": true, "map": "house", "from": Vector2(1, 1), "facing": Vector2i(0, 1)} if who == "crawler" else {}
		check(g.arms_full() and g.holding(), "%s in the arms: arms full" % who)
		var m := InventoryMenu.new(inv, "rucksack", 0, g.arms_full())
		m.point("bag", 0)
		check(m.hold() == "Your hands are full." and inv.id_at("hand", 0) == "" and inv.id_at("bag", 0) == "turnip", "%s: hold puts nothing in the hand" % who)
		check(m.choose() == "" and m.carry.id == "turnip", "%s: picking up from the bag is fine" % who)
		m.point("hand", 0)
		check(m.choose() == "Your hands are full." and m.carry.id == "turnip" and inv.id_at("hand", 0) == "", "%s: carried stack not put in the hand" % who)
		check(m.close() == "" and inv.id_at("bag", 0) == "turnip", "%s: closing puts it back in the rucksack" % who)
		inv.lift("tools", 0)
		inv.add("axe", 1, ["chest"])
		var st := InventoryMenu.new(inv, "storage", 0, g.arms_full())
		st.point("chest", 0)
		check(st.hold() == "" and inv.id_at("tools", 0) == "axe", "%s: a tool from the chest still swaps with the tool in hand" % who)
		st.point("bag", 0)
		check(st.hold() == "Your hands are full." and inv.id_at("hand", 0) == "", "%s: nothing from the rucksack into the hand" % who)
		Child.carried = {}
		g.baby_held = false
		g.animals.dog.held = false
	check(not g.arms_full() and not g.holding(), "hands free: not full")
	var free := InventoryMenu.new(inv, "rucksack", 0, g.arms_full())
	free.point("bag", 0)
	check(free.hold() == "" and inv.id_at("hand", 0) == "turnip", "hands free: hold puts the item in the hand")
	g.free()


func _game() -> void:
	var g: Node = (load("res://scripts/autoload/game.gd") as GDScript).new()
	g.crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	g.tools_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	g.rng.seed = 5
	g.new_game()
	check(g.current_tool() == "hoe" and g.count("seeds:turnip") == 2, "new game: hoe in hand, seed bags")
	check(g.bag == {"seeds:turnip": 2, "seeds:potato": 1, "food:onigiri": 1}, "bag reads the carried totals")
	check(g.add_item("turnip", 3) == 0 and g.count("turnip") == 3, "add_item puts it in the rucksack")
	check(g.take_item("turnip", 2) and g.count("turnip") == 1 and not g.take_item("turnip", 2), "take_item")
	g.bag = {"corn": 4}
	check(g.count("corn") == 4 and g.count("seeds:turnip") == 0, "setting bag replaces what is carried")
	# Shipping takes crops from the rucksack and the hand, not the chest, and leaves seeds.
	g.inventory.add("turnip", 2, ["hand"])
	g.inventory.add("turnip", 5, ["chest"])
	g.add_item("seeds:potato")
	var value: int = g.ship_produce()
	check(value == 4 * int(g.crops.corn.sell) + 2 * int(g.crops.turnip.sell), "ship: rucksack and hand crops (%d)" % value)
	check(g.count("corn") == 0 and g.count("turnip") == 0 and g.inventory.count("turnip", ["chest"]) == 5 and g.count("seeds:potato") == 1, "ship: chest and seeds stay")
	# The tool in hand is a tool slot: an empty slot is no tool.
	g.inventory.lift("tools", 2)
	g.select_tool(2)
	check(g.current_tool() == "", "empty tool slot: no tool")
	g.select_tool(-1)
	check(g.tool_index == g.inventory.size("tools") - 1, "tool keys wrap over the tool slots")
	# A full rucksack: can_carry says no.
	g.bag = {}
	for i in g.inventory.size("bag"):
		g.inventory.slots.bag[i] = {"id": "stone_%d" % i, "n": 1}
	check(not g.can_carry("turnip") and g.add_item("turnip") == 1, "full rucksack")
	check(g.item_name("turnip") == "Turnip" and g.item_name("seeds:potato") == "Potato seeds" and g.item_name("hoe") == "Hoe" and g.item_name("rice_ball") == "Rice Ball", "item names")
	# The storage chest stands by the house, solid, and an older farm gets it.
	var f: FarmGrid = g.farm
	check(f.fixed_at(FarmGrid.CHEST) == "chest" and f.is_solid(FarmGrid.CHEST), "chest by the house")
	f.fixed.erase(FarmGrid.CHEST)
	f.cell(FarmGrid.CHEST).tilled = true
	f.add_missing_fixed()
	check(f.fixed_at(FarmGrid.CHEST) == "chest" and not f.cell(FarmGrid.CHEST).tilled, "older farm gets the chest")
	var before: Dictionary = f.fixed.duplicate()
	f.add_missing_fixed()
	check(f.fixed == before, "never a second chest")
	# The rucksack key.
	g._setup_input()
	check(InputMap.has_action("rucksack"), "rucksack key in the input map")
	var hit := false
	for ev in InputMap.action_get_events("rucksack"):
		hit = hit or (ev is InputEventKey and ev.physical_keycode == KEY_I)
	check(hit, "I opens the rucksack")
	check(PlaceholderArt.item_key("turnip") == "ui:item:turnip" and PlaceholderArt.item_key("seeds:corn") == "ui:seeds:corn" and PlaceholderArt.item_key("seeds", "potato") == "ui:seeds:potato" and PlaceholderArt.item_key("food:mochi") == "ui:food:mochi" and PlaceholderArt.item_key("food", "", "milk") == "ui:food:milk", "icon keys")
	for key in ["ui:item:turnip", "ui:item:rice_ball", "ui:cursor"]:
		var img := PlaceholderArt.tex(key).get_image()
		check(img.get_width() > 0 and not img.is_invisible(), "icon %s drawn" % key)
	g.free()


## The refined item and tool icons (ItemArt, data/item_art.json): the sizes kept, no pixel in
## the old near-black outline colour, the main material in its lit and shade tones (base kept as
## the material's colour), the rim beside it in its own deep tone pulled to the rim colour, and
## at least five colours in each.
func _item_art_refined() -> void:
	var a := ItemArt.art()
	check(a.has("tone") and a.has("deep") and a.has("rim") and a.has("rim_mix"), "item art: numbers in data/item_art.json")
	var old := FigureArt._key(PlaceholderArt.OUTLINE)
	var cases := []   # [key, size, main material colour or null]
	var tool_main := {"hoe": PlaceholderArt.TOOL_WOOD, "can": PlaceholderArt.TOOL_TIN, "sickle": PlaceholderArt.TOOL_WOOD,
		"hammer": PlaceholderArt.TOOL_IRON, "axe": PlaceholderArt.TOOL_WOOD, "rod": null}
	for t in tool_main:
		cases.append(["ui:tool:" + t, 14, tool_main[t]])
	for id in ["turnip", "potato", "cucumber", "tomato", "onion", "corn", "carrot", "eggplant", "pumpkin", "daikon", "rice"]:
		var fruit := Color(PlaceholderArt.crop_look(id).get("fruit", "e8a23a"))
		cases.append(["ui:item:" + id, 14, fruit])
		cases.append(["item:" + id, 12, fruit if id != "corn" else null])
		cases.append(["ui:seeds:" + id, 14, Color("d8c08a")])
	for id in ["egg", "egg_good", "egg_best"]:
		cases.append(["ui:item:" + id, 14, PlaceholderArt.EGG_SHELLS[id]])
		cases.append(["item:" + id, 12, PlaceholderArt.EGG_SHELLS[id]])
	for id in ["milk", "milk_good", "milk_best", "wool", "wool_good", "wool_best"]:
		cases.append(["ui:item:" + id, 14, Color("f6f4ee") if id.begins_with("milk") else PlaceholderArt.WOOL_TINTS[id]])
		cases.append(["item:" + id, 12, null])
	cases.append(["ui:item:lumber", 14, null])
	for c in cases:
		var img := PlaceholderArt.image(c[0])
		var seen := {}
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a == 0.0:
					continue
				seen[p.to_html()] = true
		check(img.get_size() == Vector2i(c[1], c[1]), "item art: %s is %d x %d" % [c[0], c[1], c[1]])
		check(not seen.has(old), "item art: %s has no old outline colour" % c[0])
		check(seen.size() >= 5, "item art: %s has several tones (%d colours)" % [c[0], seen.size()])
		if c[2] != null:
			var tn := ItemArt.tones(c[2])
			check(seen.has(FigureArt._key(tn[0])) and seen.has(FigureArt._key(tn[2])),
				"item art: %s shows its main material's shade and lit tones" % c[0])
			check(seen.has(FigureArt._key(ItemArt.rim_of(c[2]))), "item art: %s is rimmed in its material's deep tone" % c[0])
	# The grades still differ, the pale ones keep a soft rim (lighter than the old outline).
	check(PlaceholderArt.image("item:egg").get_data() != PlaceholderArt.image("item:egg_best").get_data(), "item art: egg grades differ")
	check(ItemArt.rim_of(PlaceholderArt.EGG_SHELLS.egg).v > PlaceholderArt.OUTLINE.v, "item art: the white egg's rim is softer than the old outline")
	# A part line: the can's handle where it meets the tin is the handle's deep tone.
	var can := PlaceholderArt.image("ui:tool:can")
	var deep_handle := FigureArt._key(ItemArt.tones(PlaceholderArt.TOOL_TIN_HANDLE)[3])
	check(can.get_pixel(3, 4).to_html() == deep_handle and can.get_pixel(8, 4).to_html() == deep_handle,
		"item art: the can's handle meets the tin in its deep tone")


## The fish, mine finds and wild things' icons through ItemArt.refine: 14 x 14 kept, no pixel in
## the old near-black outline, at least four colours, the main material (body / colour) in its
## lit tone and its shade or deep one.
func _fish_mine_wild_art_refined() -> void:
	var old := FigureArt._key(PlaceholderArt.OUTLINE)
	var cases := []   # [key, main material colour]
	var fish: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fish.json")).get("fish", {})
	for id in fish:
		cases.append(["ui:fish:" + id, Color(PlaceholderArt.fish_look(id).get("body", "8a8a6a"))])
	var mine: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/mine.json")).get("items", {})
	for id in mine:
		cases.append(["ui:mine:" + id, Color(PlaceholderArt.mine_look(id).get("body", "8e8a84"))])
	var wild: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/forage.json")).get("items", {})
	for id in wild:
		cases.append(["ui:wild:" + id, Color(wild[id].get("look", {}).get("color", "8a6a3a"))])
	check(fish.size() > 0 and mine.size() > 0 and wild.size() > 0, "fish/mine/wild art: the item lists are not empty")
	for c in cases:
		var img := PlaceholderArt.image(c[0])
## The kitchen tools, the keepsakes and the ribbons (ItemArt, the refined pass): every key keeps
## its 14 x 14 picture, has no pixel of the old near-black outline and several colours.
func _kitchen_keep_ribbon_art_refined() -> void:
	var old := FigureArt._key(PlaceholderArt.OUTLINE)
	var keys := []
	for t in ["knife", "pot", "teapot", "rice_pot", "steamer", "mallet"]:
		keys.append("ui:kitchen:" + t)
	for k in ["wind_chime", "paper_fan", "clay_rabbit", "moon_lantern", "daruma", "omamori", "mizuhiki"]:
		keys.append("ui:keep:" + k)
	for place in range(1, Keepsakes.places().size() + 1):
		keys.append("ui:ribbon:%d" % place)
	for key in keys:
		var img := PlaceholderArt.image(key)
		var seen := {}
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a > 0.0:
					seen[p.to_html()] = true
		check(img.get_size() == Vector2i(14, 14), "fish/mine/wild art: %s is 14 x 14" % c[0])
		check(not seen.has(old), "fish/mine/wild art: %s has no old outline colour" % c[0])
		check(seen.size() >= 4, "fish/mine/wild art: %s has several colours (%d)" % [c[0], seen.size()])
		var tn := ItemArt.tones(c[1])
		# Thin parts (a fish's body) can be all lit edge and part line, so the shade tone or the deep one.
		check(seen.has(FigureArt._key(tn[2])) and (seen.has(FigureArt._key(tn[0])) or seen.has(FigureArt._key(tn[3]))),
			"fish/mine/wild art: %s shows its main material's lit tone and its shade or deep one" % c[0])
				if p.a == 0.0:
					continue
				seen[p.to_html()] = true
		check(img.get_size() == Vector2i(14, 14), "kitchen/keep/ribbon art: %s is 14 x 14" % key)
		check(not seen.has(old), "kitchen/keep/ribbon art: %s has no old outline colour" % key)
		check(seen.size() >= 4, "kitchen/keep/ribbon art: %s has several colours (%d)" % [key, seen.size()])


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


## The food icons (ui:food:*, the onigiri in the tool bar too) through ItemArt.refine: every
## food in data/foods.json keeps 14 x 14, has no old outline colour, several tones, and its main
## material (the food itself, or the dish / wrapper it sits in) in its shade, lit and rim tones.
func _food_art_refined() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json"))
	var old := FigureArt._key(PlaceholderArt.OUTLINE)
	var dish_main := ["cup", "bowl", "plate", "fish_plate", "bag", "imo"]   # the accent is the main material
	check(data.foods.size() >= 10, "food art: foods to draw")
	for id in data.foods:
		var look: Dictionary = PlaceholderArt.food_look(str(id))
		var key: String = "ui:food:" + str(id)
		var img := PlaceholderArt.image(key)
		var seen := {}
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a > 0.0:
					seen[p.to_html()] = true
		check(img.get_size() == Vector2i(14, 14), "food art: %s is 14 x 14" % key)
		check(not seen.has(old), "food art: %s has no old outline colour" % key)
		check(seen.size() >= 5, "food art: %s has several tones (%d colours)" % [key, seen.size()])
		var main := Color(look.get("accent" if look.get("shape", "") in dish_main else "color", "fbf8f0"))
		var tn := ItemArt.tones(main)
		check(seen.has(FigureArt._key(tn[0])) and seen.has(FigureArt._key(tn[2])),
			"food art: %s shows its main material's shade and lit tones" % key)
		check(seen.has(FigureArt._key(ItemArt.rim_of(main))), "food art: %s is rimmed in its material's deep tone" % key)
	# Dishes of one shape still differ by their colours.
	check(PlaceholderArt.image("ui:food:green_tea").get_data() != PlaceholderArt.image("ui:food:amazake").get_data(),
		"food art: two cups differ")
