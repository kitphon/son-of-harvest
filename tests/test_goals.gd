extends SceneTree
## Headless checks of Tome's first-week list (data/goals.json, Goals, Game.check_goals and the
## rewards, the notes in data/dialogue/goals.json, the save, the HUD's goal tag). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_goals.gd

const STATS := ["planted", "talked", "forage", "fish", "crops_shipped", "earned"]

var failures := 0
var _frame := 0


func _init() -> void:
	_data()
	_rules()
	_game()
	_save()


# The HUD reads the Game autoload, which needs the tree: it waits for the first frame.
func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_hud()
		print("test_goals: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


## Every goal: a unique id, a short text that fits the HUD tag at full progress, a known stat,
## a count, a reward of known things, and a note that opens in the text box.
func _data() -> void:
	var all := Goals.all()
	check(all.size() >= 4, "data: %d goals" % all.size())
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var foods: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json")).get("foods", {})
	var seen := {}
	for g in all:
		var id := String(g.get("id", ""))
		check(id != "" and not seen.has(id), "data: goal id %s once" % id)
		seen[id] = true
		check(String(g.get("text", "")) != "" and g.get("stat", "") in STATS and int(g.get("count", 0)) > 0,
			"data: %s has a text, a known stat (%s) and a count" % [id, g.get("stat")])
		var full := Goals.hud_text(g, {g.stat: int(g.count)})
		check(HudLayout.goal_width(Goals.message("hud_tag"), full) <= HudLayout.BOXES.goal.size.x,
			"data: %s fits the HUD goal box (%s)" % [id, full])
		var r: Dictionary = g.get("reward", {})
		check(int(r.get("money", 0)) > 0 or not r.get("items", {}).is_empty() or r.has("animal"), "data: %s has a reward" % id)
		for item in r.get("items", {}):
			var known: bool = (item.begins_with("seeds:") and crops.has(item.trim_prefix("seeds:"))) or (item.begins_with("food:") and foods.has(item.trim_prefix("food:"))) or crops.has(item)
			check(known and int(r.items[item]) > 0, "data: %s gives a known item %s" % [id, item])
		if r.has("animal"):
			check(r.animal in ["chicken", "cow", "sheep"] and String(r.get("animal_name", "")) != "" and int(r.get("animal_money", 0)) > 0,
				"data: %s's animal has a name and its worth in money" % id)
		var say: Dictionary = g.get("say", {})
		var run := DialogueRunner.open(String(say.get("dialogue", "")), {}, String(say.get("at", "")))
		check(run.error == "" and not run.done(), "data: %s's note opens (%s)" % [id, run.error])
	for key in ["hud", "hud_tag", "done", "money", "item", "animal"]:
		check(Goals.message(key) != "", "data: message %s" % key)
	# The early ones are reachable in the first days: no crop has to ripen and no big sum is needed.
	var early := 0
	for g in all.slice(0, 3):
		early += int(g.stat in ["planted", "talked", "forage", "fish"])
	check(early == 3, "data: the first three goals need nothing to ripen")


## Goals by themselves: the current one, progress, what is reached, the texts, parse.
func _rules() -> void:
	var gl := Goals.new()
	var first: Dictionary = Goals.all()[0]
	check(gl.current().id == first.id, "the list starts at its first goal")
	check(Goals.progress(first, {}) == 0 and Goals.progress(first, {first.stat: 9999}) == int(first.count), "progress is kept in 0 .. count")
	check(Goals.hud_text(first, {first.stat: 1}) == Goals.message("hud") % [first.text, 1, int(first.count)], "the HUD line: %s" % Goals.hud_text(first, {first.stat: 1}))
	check(gl.reached({}).is_empty(), "nothing reached at the start")
	var stats := {"fish": 1}
	check(gl.reached(stats) == ["fish"], "a later goal is reached on its own: %s" % [gl.reached(stats)])
	gl.done.append("fish")
	check(gl.reached(stats).is_empty() and gl.current().id == first.id, "done once; the HUD still shows the first")
	gl.add("forage")
	gl.add("forage", 2)
	gl.add("forage", -5)
	check(gl.counts.forage == 3, "counts add up, never down")
	check(Goals.done_text(first, ["+150 G"]) == (Goals.message("done") % first.text) + " +150 G", "the done line: %s" % Goals.done_text(first, ["+150 G"]))
	var p := Goals.parse(gl.to_dict())
	check(p[0] == "" and p[1].done == gl.done and p[1].counts == gl.counts, "to_dict and back")
	p = Goals.parse({"done": ["fish", "fish", "gone_goal"], "counts": {}})
	check(p[0] == "" and p[1].done == ["fish"], "repeats and unknown ids are dropped")
	check(Goals.parse({"done": [3], "counts": {}})[0] != "" and Goals.parse({"done": [], "counts": {"forage": -1}})[0] != ""
		and Goals.parse("x")[0] != "", "broken saved goals are refused")
	check(Goals.all_done().current().is_empty(), "all_done: nothing left")


## On a scratch Game: each goal is reached by playing, paid once, its note opened when
## nothing holds the screen.
func _game() -> void:
	var g := _new_game()
	var notes: Array = []
	g.dialogue_requested.connect(func(id: String, at: String) -> void: notes.append([id, at]))
	check(g.goals_on and g.goals.done.is_empty() and g.check_goals().is_empty(), "a new game: the list on, nothing done")
	# Plant: nine plots of turnips.
	var money: int = g.money
	var planted := 0
	for y in FarmGrid.H:
		for x in FarmGrid.W:
			var c := Vector2i(x, y)
			if planted < 9 and g.farm.can_farm(c) and g.farm.cell(c).obj == FarmGrid.Obj.NONE and g.farm.cell(c).crop == "":
				g.farm.cell(c).tilled = true
				g.farm.cell(c).crop = "turnip"
				planted += 1
	check(g.goal_stats().planted == 9, "nine plots planted")
	g.pause()
	check(g.check_goals() == ["plant"] and g.money == money + 150, "plant: done, +150 G")
	check(notes.is_empty() and g.goals.waiting == ["plant"], "a menu is open: the note waits")
	g.unpause()
	check(g.check_goals().is_empty() and notes == [["goals", "plant"]] and g.goals.waiting.is_empty(), "then it opens: %s" % [notes])
	check(g.check_goals().is_empty() and g.money == money + 150, "paid only once")
	check(g.goals.current().id == "hello", "the HUD moves on to the next")
	# Hello: three villagers talked to (any day).
	var people: Array = Villagers.all().keys()
	for i in 3:
		g.affection.talk(people[i], i + 1)
	var rice: int = g.count("food:onigiri")
	check(g.check_goals() == ["hello"] and g.count("food:onigiri") == rice + 3, "hello: three rice balls")
	# Forage: four wild things on the hill.
	g.go_to_map("hill", Vector2i(6, 26), Vector2i.UP)
	var picked := 0
	for c in g.forage_here().keys():
		if picked < 4:
			g.held = ""
			picked += int(g.forage_pick(c).to != "")
	g.held = ""
	check(g.goal_stats().forage == 4, "four wild things counted")
	check(g.check_goals() == ["forage"] and g.count("seeds:cucumber") == 1, "forage: a bag of cucumber seeds")
	# Fish: one caught.
	money = g.money
	g.fish_caught["dace"] = 1
	check(g.check_goals() == ["fish"] and g.money == money + 120, "fish: +120 G")
	# Ship: five crops into the bin; the pay counts towards earn.
	var potatoes: int = g.count("seeds:potato")
	g.inventory.add("turnip", 5)
	g.ship_produce()
	check(g.check_goals() == ["ship"] and g.count("seeds:potato") == potatoes + 2, "ship: two bags of seed potatoes")
	g.pay_bin()
	check(g.goal_stats().earned == 5 * int(g.crops.turnip.sell) and g.check_goals().is_empty(), "the cart's pay is counted (%d G)" % g.goal_stats().earned)
	# Earn: the cart has paid 1000 G in all; a chick comes to the coop.
	var flock: int = g.animals.list.size()
	g.bin_total = 1000
	g.pay_bin()
	check(g.check_goals() == ["earn"] and g.animals.list.size() == flock + 1 and int(g.animals.list.back().age) == 0
		and g.animals.list.back().kind == "chicken", "earn: a chick in the coop")
	check(g.goals.current().is_empty() and g.check_goals().is_empty(), "the list is done")
	g.free()
	# Several at once, all paid in list order; a full coop pays the chick's worth instead.
	g = _new_game()
	while g.animals.add("chicken"):
		pass
	g.fish_caught["dace"] = 1
	g.goals.add("earned", 2000)
	money = g.money
	check(g.check_goals() == ["fish", "earn"] and g.money == money + 120 + 700, "two at once; a full coop: +700 G (%d)" % (g.money - money))
	check(g.goals.waiting == ["earn"], "one note opens now, the next waits")
	# Items that don't fit the rucksack go in the chest.
	var full := _new_game()
	full.inventory.take("food:onigiri", full.count("food:onigiri"))
	full.inventory.add("turnip", 9999)
	for i in 3:
		full.affection.talk(people[i], 1)
	full.check_goals()
	check(full.inventory.count("food:onigiri", ["chest"]) == 3, "no room: the rice balls are in the chest")
	full.free()
	g.free()


## The save keeps what is done and the counts; a save from before the list has it all done.
func _save() -> void:
	var g := _new_game()
	g.goals.done.append("plant")
	g.goals.add("forage", 2)
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	var h := _new_game()
	check(h.from_dict(d) == "" and h.goals.done == ["plant"] and int(h.goals.counts.forage) == 2, "saved and loaded")
	d.erase("goals")
	check(h.from_dict(d) == "" and h.goals.current().is_empty(), "a save from before the list: all of it done")
	d.goals = {"done": "plant"}
	check(h.from_dict(d) != "", "broken goals refuse the load")
	g.free()
	h.free()


## The real HUD: the goal tag under the clock, moved down under a festival tag, gone when done.
func _hud() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.goals_on = true
	var hud: CanvasLayer = load("res://scripts/ui/hud.gd").new()   # by path: Hud names the Game autoload
	root.add_child(hud)
	hud._refresh()
	var first: Dictionary = Goals.all()[0]
	check(hud._goal_box.visible and hud._goal.text == Goals.hud_text(first, g.goal_stats()), "HUD: the goal shown: %s" % hud._goal.text)
	check(hud._goal_tag.text == Goals.message("hud_tag"), "HUD: its tag")
	var box: Control = hud._goal_box
	var holder: Control = hud._placed.goal
	check(is_equal_approx(holder.position.x + box.position.x + box.size.x, HudLayout.BOXES.goal.end.x), "HUD: right-aligned with the clock")
	check(not hud._fest_box.visible and is_equal_approx(holder.position.y + box.position.y, HudLayout.BOXES.festival.position.y), "HUD: in the festival tag's place on a plain day")
	hud._fest_box.visible = true
	hud._refresh_goal()
	check(is_equal_approx(holder.position.y + box.position.y, HudLayout.BOXES.goal.position.y), "HUD: under the festival tag on a festival day")
	g.goals = Goals.all_done()
	hud._refresh()
	check(not hud._goal_box.visible, "HUD: hidden once the list is done")
	g.goals = Goals.new()
	g.goals_on = false
	hud._refresh()
	check(not hud._goal_box.visible, "HUD: hidden while the list is off")
	g.goals_on = true
	hud.queue_free()


func _new_game() -> Node:
	var g: Node = load("res://scripts/autoload/game.gd").new()
	g.crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	g.tools_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	g.set_food_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json")))
	g.fish_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/fish.json"))
	g.mine_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/mine.json"))
	g.rng.seed = 5
	g.new_game()
	return g


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
