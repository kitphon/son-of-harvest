extends SceneTree
## Headless forage checks (data/forage.json, Forage, Game.forage_pick and the picked spots,
## the morning regrowth, the save, shipping and eating, FarmActions on the hill, the views,
## the art). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_forage.gd

const SEASONS := ["spring", "summer", "fall", "winter"]
const AREAS := ["kaminoda", "sakurazaka", "minamino"]
const SHAPES := ["shoot", "fern", "bud", "berries", "pod", "nut", "mushroom"]

var failures := 0
var _frame := 0


func _init() -> void:
	_data()
	_rules()
	_game()
	_save()


# The real Game autoload, FarmActions and the views need the tree, so they wait for the first frame.
func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_actions_and_views()
		_persimmon()
		print("test_forage: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


## Every item has a name that fits the item box, a price and a look; every spot is on a free
## cell of a known map that the farmer can stand next to, and grows known items.
func _data() -> void:
	var d := Forage.data()
	var items: Dictionary = d.get("items", {})
	check(items.size() >= 8, "data: %d wild items" % items.size())
	for id in items:
		var it: Dictionary = items[id]
		check(str(it.get("name", "")) != "" and PixelFont.width(str(it.name)) + 12 + PixelFont.width("x99") <= HudLayout.BOXES.item.size.x,
			"data: %s has a name that fits the item box" % id)
		check(int(it.get("sell", 0)) > 0 and int(it.sell) <= 100, "data: %s sells for %s" % [id, it.get("sell")])
		check(it.get("look", {}).get("shape", "") in SHAPES, "data: %s has a known shape" % id)
	check(d.spots.has("hill"), "data: the bamboo hill has spots")
	for map_id in d.spots:
		var m := MapManager.data(map_id)
		check(m != null and not m.indoor, "data: %s is an outdoor map" % map_id)
		if m == null:
			continue
		var seen := {}
		for s in Forage.spots(map_id):
			var c: Vector2i = s.cell
			check(c.x >= 0 and c.y >= 0 and c.x < m.w and c.y < m.h and not m.is_solid(c) and m.door_at(c).is_empty()
				and m.tile(c) not in ["water", "path", "gravel"], "data: %s spot %s is on a free cell off the lanes" % [map_id, c])
			check(not seen.has(c), "data: %s spot %s once" % [map_id, c])
			seen[c] = true
			var free := false
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var n: Vector2i = c + dir
				free = free or (n.x >= 0 and n.y >= 0 and n.x < m.w and n.y < m.h and not m.is_solid(n))
			check(free, "data: %s spot %s can be reached" % [map_id, c])
			var grows := 0
			for season in SEASONS:
				if s.has(season):
					grows += 1
					check(items.has(str(s[season])), "data: %s spot %s grows %s" % [map_id, c, s[season]])
			check(grows > 0, "data: %s spot %s grows something" % [map_id, c])
	for season in SEASONS:
		check(Forage.growing("hill", season).size() >= 3, "data: the hill has spots in %s" % season)
	check(Forage.growing("hill", "spring").size() >= 8 and Forage.growing("hill", "fall").size() >= 8, "data: spring and fall are full")
	# The outer parts: a smaller round each, with wild things found on no other map.
	for map_id in AREAS:
		for season in ["spring", "summer", "fall"]:
			check(Forage.growing(map_id, season).size() >= 4, "data: %s has spots in %s" % [map_id, season])
		check(Forage.growing(map_id, "winter").size() >= 1, "data: %s has something in winter" % map_id)
		var own := {}
		for s in Forage.spots(map_id):
			for season in SEASONS:
				if s.has(season):
					own[str(s[season])] = true
		for other in d.spots:
			if other != map_id:
				for s in Forage.spots(other):
					for season in SEASONS:
						own.erase(str(s.get(season, "")))
		check(not own.is_empty(), "data: %s has a wild thing of its own (%s)" % [map_id, own.keys()])


## Forage.growing: by the season, without the picked cells; item lookups.
func _rules() -> void:
	var spring := Forage.growing("hill", "spring")
	check(spring.get(Vector2i(6, 25)) == "wild:bamboo_shoot" and Forage.growing("hill", "fall").get(Vector2i(6, 25)) == "wild:hiratake",
		"one spot: a bamboo shoot in spring, mushrooms in fall")
	check(not Forage.growing("hill", "winter").has(Vector2i(6, 25)), "nothing there in winter")
	var left := Forage.growing("hill", "spring", {Vector2i(6, 25): true})
	check(left.size() == spring.size() - 1 and not left.has(Vector2i(6, 25)), "a picked spot is gone")
	check(Forage.growing("town", "spring").is_empty() and Forage.growing("nowhere", "spring").is_empty(), "no spots elsewhere")
	check(Forage.item("wild:matsutake").get("name") == "Matsutake" and Forage.item("matsutake").is_empty() and Forage.item("mine:stone").is_empty(),
		"items only by their wild: id")


## On a Game: picked overhead, then into the rucksack, then no room; sold and named; back
## the next morning.
func _game() -> void:
	var g := _new_game()
	g.go_to_map("hill", Vector2i(6, 26), Vector2i.UP)
	var all: int = g.forage_here().size()
	check(all == Forage.growing("hill", "spring").size(), "spring on the hill: %d spots" % all)
	var r: Dictionary = g.forage_pick(Vector2i(6, 25))
	check(r.id == "wild:bamboo_shoot" and r.to == "hand" and g.held == "wild:bamboo_shoot", "picked overhead: %s" % [r])
	check(g.forage_here().size() == all - 1 and g.forage_pick(Vector2i(6, 25)).id == "", "the spot is bare now")
	check(g.forage_pick(Vector2i(7, 25)).id == "", "nothing on a plain cell")
	r = g.forage_pick(Vector2i(3, 25))
	check(r.id == "wild:warabi" and r.to == "rucksack" and g.count("wild:warabi") == 1 and g.held == "wild:bamboo_shoot",
		"hands full: into the rucksack")
	g.inventory.add("turnip", 9999)
	r = g.forage_pick(Vector2i(14, 26))
	check(r.id == "wild:fukinoto" and r.to == "" and g.forage_here().has(Vector2i(14, 26)), "no room: it stays")
	check(g.sell_price("wild:bamboo_shoot") == int(Forage.item("wild:bamboo_shoot").sell) and g.sell_price("wild:nothing") == 0, "wild things sell")
	check(g.item_name("wild:warabi") == "Bracken", "named")
	check(g.edible("wild:kiichigo") and g.edible("wild:akebi") and g.edible("wild:kuwa") and not g.edible("wild:bamboo_shoot") and not g.edible("wild:matsutake"),
		"berries, mulberries and akebi are eaten raw, the rest not")
	g.inventory.take("turnip", g.count("turnip"))
	var bin: int = g.bin_total
	var worth := int(Forage.item("wild:warabi").sell) + int(Forage.item("wild:bamboo_shoot").sell)
	check(g.ship_produce() == worth and g.bin_total == bin + worth and g.count("wild:warabi") == 0, "the bin takes them (rucksack and hand)")
	g.go_to_map("town", Vector2i(10, 10), Vector2i.UP)
	check(g.forage_picked.has("hill") and g.forage_here().is_empty(), "the village has no spots; the hill keeps its picks")
	g.go_to_map("kaminoda", Vector2i(9, 3), Vector2i.UP)
	var fields: int = g.forage_here().size()
	r = g.forage_pick(Vector2i(9, 2))
	check(fields == Forage.growing("kaminoda", "spring").size() and r.id == "wild:seri" and g.held == "wild:seri"
		and g.forage_picked.kaminoda.size() == 1 and g.forage_picked.hill.size() == 2, "Kaminoda: water dropwort by the paddy, picked apart from the hill's")
	g.end_day()
	check(g.forage_picked.is_empty(), "next morning: everything is back")
	g.season = 3
	g.go_to_map("hill", Vector2i(36, 25), Vector2i.UP)
	check(g.forage_here().size() == Forage.growing("hill", "winter").size() and g.forage_here().get(Vector2i(36, 24)) == "wild:enoki",
		"winter on the hill: a few enoki")
	g.free()


## The picked spots are saved for the day; a broken list is refused; an old save has none.
func _save() -> void:
	var g := _new_game()
	g.go_to_map("hill", Vector2i(6, 26), Vector2i.UP)
	g.forage_pick(Vector2i(6, 25))
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	check(d.forage.picked.hill.size() == 1 and int(d.forage.picked.hill[0][0]) == 6 and int(d.forage.picked.hill[0][1]) == 25, "saved: %s" % [d.forage])
	var b := _new_game()
	check(b.from_dict(d) == "" and b.forage_picked.get("hill", {}).has(Vector2i(6, 25)) and b.forage_picked.hill.size() == 1, "loaded the pick")
	var broken := d.duplicate(true)
	broken.forage.picked.hill = [[6]]
	check(b.from_dict(broken) == "Saved forage is broken", "a broken cell is refused")
	broken.forage = []
	check(b.from_dict(broken) == "Saved forage is broken", "a broken forage block is refused")
	var old := d.duplicate(true)
	old.erase("forage")
	check(b.from_dict(old) == "" and b.forage_picked.is_empty(), "an old save: nothing picked")
	g.free()
	b.free()


## On the real Game: E facing a spot picks it (FarmActions), the 3D layer and the flat view
## show one thing per spot left, and the icons are drawn (not the magenta fallback).
func _actions_and_views() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.go_to_map("hill", Vector2i(18, 11), Vector2i.UP)
	var said := []
	g.message.connect(func(t): said.append(t))
	# Loaded here, not named: they use the Game autoload, which a --script run only has at run time.
	var layer: Node3D = load("res://scripts/world3d/forage_layer.gd").new("hill")
	root.add_child(layer)
	var view: Node2D = load("res://scripts/world/forage_view.gd").new("hill")
	root.add_child(view)
	check(_live(layer) == g.forage_here().size() and _live(layer) > 0, "3D: one sprite per spot (%d)" % _live(layer))
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	actions.interact(Vector2i(18, 10))
	check(g.held == "wild:warabi" and said.back() == "Picked the bracken.", "E picks the bracken: %s" % [said])
	check(_live(layer) == g.forage_here().size(), "3D: the picked one is gone")
	actions.on_action("interact", Vector2i(18, 11), Vector2i.UP)
	check(g.held == "wild:warabi" and g.count("wild:warabi") == 1, "the bare spot gives nothing more")
	g.end_day()
	check(_live(layer) == Forage.growing("hill", "spring").size(), "3D: in the morning it has them all again")
	layer.free()
	view.free()
	g.go_to_map("minamino", Vector2i(28, 5), Vector2i.UP)
	layer = load("res://scripts/world3d/forage_layer.gd").new("minamino")
	root.add_child(layer)
	view = load("res://scripts/world/forage_view.gd").new("minamino")
	root.add_child(view)
	check(_live(layer) == Forage.growing("minamino", "spring").size() and _live(layer) > 0, "3D: Minamino's spots (%d)" % _live(layer))
	layer.free()
	view.free()
	for id in Forage.data().items:
		var img: Image = PlaceholderArt.tex(PlaceholderArt.item_key("wild:" + id)).get_image()
		check(img.get_width() == 14 and img.get_pixel(7, 7).a > 0.0, "art: wild:%s is drawn" % id)
	check(PlaceholderArt.world_item_key("wild:akebi") == "ui:wild:akebi", "art: the overhead picture is the icon")
	g.new_game()


## Kiku's grown persimmon tree (data/scion.json pick): two persimmons a day in fall from the
## fruiting stage on, drawn with what is left, back in the morning, saved, shippable, eaten and
## a gift Kiku loves; nothing from a young tree or out of season.
func _persimmon() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.flags["kiku_scion"] = "door"
	g.flags[Scion.day_flag()] = g.day_number() - Scion.from_days("tree")
	g.season = 2
	g.go_to_map("farm", Vector2i(3, 5), Vector2i.UP)
	var tree := Vector2i(3, 4)
	var said := []
	g.message.connect(func(t): said.append(t))
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	check(Scion.pick_item() == "wild:persimmon" and Forage.item("wild:persimmon").name == "Ripe persimmon" and g.sell_price("wild:persimmon") == 30,
		"the persimmon is a wild item that sells")
	check(g.scion_fruit_left(tree) == 2 and g.scion_fruit_left(Vector2i(4, 4)) == -1, "two picks on the fruiting tree, none on bare ground")
	var key0: String = StoryView.art_key({"kind": "scion"})
	check(key0 == "story:scion:tree:fall:0", "full tree key: " + key0)
	var sprite: Sprite3D = null
	var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	root.add_child(w)
	load("res://scripts/world3d/story_props.gd").prop(w, g.maps.current().prop_at(tree))
	for c in w.get_children():
		if c is Sprite3D:
			sprite = c
	check(sprite != null and sprite.texture == PlaceholderArt.tex(key0), "3D: the full tree is standing")
	var view: Node2D = load("res://scripts/world/story_view.gd").new(g.maps.current())
	root.add_child(view)
	actions.interact(tree)
	check(g.held == "wild:persimmon" and g.scion_picked == 1 and said.back() == "Picked the ripe persimmon.", "E picks one overhead: %s" % [said])
	check(g.flags.get(Scion.PICKED_FLAG, false) == true, "the first pick sets kiku_scion_picked (Kiku's talk)")
	var key1: String = StoryView.art_key({"kind": "scion"})
	check(key1 == "story:scion:tree:fall:0:4" and sprite.texture == PlaceholderArt.tex(key1), "3D: half the fruit is gone (%s)" % key1)
	check(Scion.drawn_left(1) == 4 and Scion.drawn_left(2) == 0 and Scion.drawn_left(0) == 8, "the drawn share")
	actions.interact(tree)
	check(g.held == "wild:persimmon" and g.count("wild:persimmon") == 2 and g.scion_picked == 2, "the second goes in the rucksack")
	var key2: String = StoryView.art_key({"kind": "scion"})
	check(key2 == "story:scion:tree:fall:0:0" and sprite.texture == PlaceholderArt.tex(key2), "3D: bare (%s)" % key2)
	var full := PlaceholderArt.tex(key0).get_image().get_data()
	check(PlaceholderArt.tex(key1).get_image().get_data() != full and PlaceholderArt.tex(key2).get_image().get_data() != PlaceholderArt.tex(key1).get_image().get_data(),
		"the three pictures differ")
	actions.interact(tree)
	check(g.count("wild:persimmon") == 2 and said.back() == "The rest are for the birds.", "a third: left for the birds (%s)" % [said.back()])
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	check(int(d.forage.scion) == 2, "saved: %s" % [d.forage])
	var b: Node = load("res://scripts/autoload/game.gd").new()
	b.crops = g.crops
	b.tools_data = g.tools_data
	b.set_food_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json")))
	b.fish_data = g.fish_data
	b.new_game()
	check(b.from_dict(d) == "" and b.scion_picked == 2, "loaded the picks")
	var old := d.duplicate(true)
	old.forage.erase("scion")
	check(b.from_dict(old) == "" and b.scion_picked == 0, "an old save: none picked")
	b.free()
	g.stamina = 10
	check(g.edible("wild:persimmon") and g.eat_item("wild:persimmon").ok, "it is eaten raw")
	check('"wild:persimmon"' in FileAccess.get_file_as_string("res://data/villagers/kiku.json"), "Kiku likes it as a gift")
	g.end_day()
	g.go_to_map("farm", Vector2i(3, 5), Vector2i.UP)
	check(g.scion_picked == 0 and g.scion_fruit_left(tree) == 2, "back in the morning (%d, %s, %s)" % [g.scion_picked, g.maps.id, g.season_name()])
	g.season = 0
	check(g.scion_fruit_left(tree) == -1 and actions.scion_fruit(tree) == false, "no persimmons out of fall")
	g.season = 2
	g.flags[Scion.day_flag()] = g.day_number() - Scion.from_days("young")
	check(g.scion_fruit_left(tree) == -1, "a young tree bears none")
	view.free()
	w.free()
	g.new_game()


func _live(n: Node) -> int:
	var k := 0
	for c in n.get_children():
		if not c.is_queued_for_deletion():
			k += 1
	return k


func _new_game() -> Node:
	var g: Node = load("res://scripts/autoload/game.gd").new()
	g.crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	g.tools_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	g.set_food_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json")))
	g.fish_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/fish.json"))
	g.rng.seed = 5
	g.new_game()
	return g


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
