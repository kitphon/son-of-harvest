extends SceneTree
## Headless checks for the ending (Ending + data/ending.json, Game.ending_values / show_ending,
## the ending event and its trigger, the EndingScreen). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_ending.gd

var failures := 0
var _frame := 0


func _init() -> void:
	_data()
	_grading()
	_friend()
	_trigger()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_values()
		_event_plays()
		_screen()
		print("test_ending: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


## data/ending.json passes, its text fits the screen and the font; bad data is refused.
func _data() -> void:
	var d := Ending.data()
	check(Ending.check(d) == "", "data/ending.json passes: %s" % Ending.check(d))
	for c in d.categories:
		check(PixelFont.missing(String(c.name)) == "" and PixelFont.width(String(c.name)) <= 120, "%s's name fits" % c.id)
	for r in d.ranks:
		check(PixelFont.missing(String(r.title)) == "" and PixelFont.width("Written as: " + String(r.title)) <= 300 - 12, "the title %s fits" % r.title)
	check(d.ranks.size() >= 3, "a few ranks")
	check(Ending.check({"categories": [{"id": "a", "name": "A", "measure": "luck", "steps": [1]}], "ranks": [{"min": 0, "title": "T"}]}) != "",
		"an unknown measure is refused")
	check(Ending.check({"categories": [{"id": "a", "name": "A", "measure": "mine_deepest", "steps": [5, 5]}], "ranks": [{"min": 0, "title": "T"}]}) != "",
		"steps that don't rise are refused")
	check(Ending.check({"categories": [{"id": "a", "name": "A", "measure": "mine_deepest", "steps": [5]}], "ranks": [{"min": 2, "title": "T"}]}) != "",
		"ranks must start at 0")


## Stars per step reached, ranks by stars in all.
func _grading() -> void:
	check(Ending.stars(0, [1, 3]) == 0 and Ending.stars(3, [1, 3]) == 2 and Ending.stars(2, [1, 3]) == 1, "a star for each step reached")
	var d := {"categories": [{"id": "m", "name": "Mine", "measure": "mine_deepest", "steps": [5, 10]},
		{"id": "f", "name": "Fish", "measure": "fish_kinds", "steps": [2, 4], "unit": "kinds"}],
		"ranks": [{"min": 0, "title": "Low"}, {"min": 2, "title": "Mid"}, {"min": 4, "title": "Top"}], "friend_band": 3}
	var r := Ending.grade({"mine_deepest": 12, "fish_kinds": 1}, {}, d)
	check(r.stars == 2 and r.max == 4 and r.title == "Mid" and r.rank == 1, "2 of 4 stars is the middle rank (%s)" % [r])
	check(r.rows[0].stars == 2 and r.rows[1].stars == 0 and r.rows[1].unit == "kinds" and r.rows[1].max == 2, "rows keep their stars, unit and max")
	check(Ending.grade({}, {}, d).title == "Low", "nothing done: the lowest rank")
	check(Ending.grade({"mine_deepest": 99, "fish_kinds": 99}, {}, d).title == "Top", "everything: the top rank")
	# The real data: an empty run is the first rank, a full one the last.
	var real := Ending.data()
	var none := Ending.grade({}, {})
	check(none.stars == 0 and none.rank == 0, "a new game's record is empty")
	var full := {}
	for m in Ending.MEASURES:
		full[m] = 1000000
	var all := Ending.grade(full, {})
	check(all.stars == all.max and all.rank == real.ranks.size() - 1, "every step reached: the top rank (%d stars)" % all.max)
	check(int(real.ranks.back().min) <= all.max, "the top rank can be reached")
	check(Ending.value_text({"value": 123400, "unit": "G"}) == "123,400 G" and Ending.value_text({"value": 7}) == "7"
		and Ending.value_text({"value": 1000}) == "1,000", "numbers are split with commas")


## The closing speaker: the villager liked most, if close enough; else Tome.
func _friend() -> void:
	var bands: Array = Affection.rules().bands
	check(Ending.friend({}) == "tome", "nobody: Tome")
	check(Ending.friend({"kota": int(bands[2]), "sayo": 0}) == "tome", "nobody at band 3: Tome")
	check(Ending.friend({"kota": int(bands[3]), "sayo": int(bands[4])}) == "sayo", "the one liked most")
	check(Ending.friend({"kota": int(bands[3]), "hachiro": int(bands[3])}) == "hachiro", "ties go to the first id")


## The farmhouse table plays the ending once, on a morning of year 3 or later.
func _trigger() -> void:
	var t := EventTriggers.open("house")
	check(t.error == "", "triggers_house: %s" % t.error)
	var s := {"year": 3, "season": "spring", "day": 1, "weekday": "mon", "time": 360, "weather": "sunny",
		"flags": {}, "seen": {}, "cell": Vector2i(2, 2)}
	check(t.pick("day_start", s) == "ending", "the first morning of year 3 plays the ending")
	check(t.pick("day_start", s.merged({"year": 2}, true)) != "ending", "not in year 2")
	check(t.pick("day_start", s.merged({"year": 4, "season": "fall", "day": 9}, true)) == "ending", "missed, it comes later")
	check(t.pick("day_start", s.merged({"seen": {"ending": true}}, true)) != "ending", "only once")


# --- on the real Game -------------------------------------------------------

func _game() -> Node:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.events_seen = {"first_morning": true, "rainy_day": true}
	return g


## Game.ending_values measures the run.
func _values() -> void:
	var g := _game()
	var v: Dictionary = g.ending_values()
	for m in Ending.MEASURES:
		check(v.has(m), "ending_values has %s" % m)
	check(v.shipped_value == 0 and v.crop_kinds == 0 and v.mine_deepest == 0 and v.house_built == 0, "a new game measures nothing (%s)" % [v])
	g.shipped = {"turnip": 10, "potato": 2, "fish:koi": 1}
	g.mine_deepest = 14
	g.fish_caught = {"koi": 1, "ayu": 2}
	g.house_built.append("kitchen")
	g.tool_levels["hoe"] = 3
	g.tool_levels["can"] = 2
	g.flags["contest_wins"] = 2
	g.affection.add("tome", int(Affection.rules().bands[3]))
	v = g.ending_values()
	var want: int = 10 * g.sell_price("turnip") + 2 * g.sell_price("potato") + g.sell_price("fish:koi")
	check(v.shipped_value == want, "shipped value at today's prices (%d, want %d)" % [v.shipped_value, want])
	check(v.crop_kinds == 2, "two crop kinds shipped (fish don't count)")
	check(v.mine_deepest == 14 and v.fish_kinds == 2 and v.house_built == 1 and v.contest_wins == 2, "mine, fish, house, contests")
	check(v.tool_levels == 3, "tool levels above 1 added up (%d)" % v.tool_levels)
	check(v.heart_bands == 3, "heart bands added up (%d)" % v.heart_bands)
	check(v.recipes_known == Cooking.known_ids(g.flags).size(), "recipes known")
	g.animals.add("chicken")
	var cared: int = g.ending_values().animal_care
	g.animals.list.back().happy = g.animals.happy_max()
	check(g.ending_values().animal_care == cared + 1, "a happy animal counts")
	g.animals.list.back().happy = 0
	check(g.ending_values().animal_care == cared, "an unhappy one doesn't")


## The ending event runs to the end on the real Game (no screen: the record step goes straight
## on), sets the rank and friend flags and ending_seen.
func _event_plays() -> void:
	for who in ["tome", "kota", "sayo", "hachiro"]:
		var g := _game()
		if who != "tome":
			g.affection.add(who, int(Affection.rules().bands[4]))
		var r := EventRunner.open("ending", g)
		check(r.error == "", "the ending runs: %s" % r.error)
		if r.error != "":
			return
		r.start(Vector2(40, 40), Vector2i.DOWN)
		var acted := false
		for i in 400:
			if r.done():
				break
			r.update(0.5)
			acted = acted or r.actors.has(who)
		check(r.done(), "the ending ends (%s)" % who)
		check(EventRunner.is_set(g.flags, "ending_seen"), "it sets ending_seen")
		check(EventRunner.is_set(g.flags, "ending_friend_" + who), "%s closes it" % who)
		check(EventRunner.is_set(g.flags, "ending_rank_0"), "a new game is the first rank")
		check(acted, "%s comes in" % who)
	var g := _game()
	g.flags["ending_rank_3"] = true
	g.flags["ending_friend_kota"] = true
	g.show_ending()
	check(not g.flags.has("ending_rank_3") and not g.flags.has("ending_friend_kota"), "an earlier record's flags are cleared")
	check(DialogueRunner.open("ending", {}, "verdict").error == "", "the ending's lines load")


## The screen: opens on the record, waits (ending_open), reveals rows, closes on two presses.
func _screen() -> void:
	var g := _game()
	var sc: CanvasLayer = load("res://scripts/ui/ending_screen.gd").new()   # loaded late: it uses the Game autoload
	root.add_child(sc)
	var r: Dictionary = g.show_ending()
	check(sc.is_open() and g.ending_open and g.paused(), "the ending step opens the screen and waits")
	check(sc._names.size() == r.rows.size(), "a row per category")
	check(not sc._names[0].visible and sc._title.text == "", "rows are revealed one by one")
	var ev := EventRunner.new({"steps": [{"do": "ending"}]}, g)
	ev.update(0.1)
	check(not ev.done(), "an ending step waits while the record is up")
	sc.advance()
	check(sc._names[r.rows.size() - 1].visible and sc._title.text == "Written as: " + String(r.title), "a press shows every row and the title")
	check(sc._total.text == "%d of %d stars" % [r.stars, r.max], "the stars in all")
	sc.advance()
	check(not sc.is_open() and not g.ending_open and not g.paused(), "a second press closes it")
	ev.update(0.1)
	check(ev.done(), "then the event goes on")
	sc.queue_free()


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
