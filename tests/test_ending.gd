extends SceneTree
## Headless checks for the ending (Ending + data/ending.json, Game.ending_values / show_ending,
## the ending event and its trigger, the yearly pages and the first-day look back, the
## EndingScreen). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_ending.gd

var failures := 0
var _frame := 0


func _init() -> void:
	_grading()
	_friend()
	_compare()
	_trigger()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_data()
		_values()
		_first_day()
		_pages()
		_event_plays()
		_year_event_plays()
		_screen()
		_scroll()
		_spouse()
		print("test_ending: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


## data/ending.json passes, its text fits the screen and the font; bad data is refused.
func _data() -> void:
	var S: Dictionary = load("res://scripts/ui/ending_screen.gd").get_script_constant_map()   # loaded late: it uses the Game autoload
	var d := Ending.data()
	check(Ending.check(d) == "", "data/ending.json passes: %s" % Ending.check(d))
	for c in d.categories:
		check(PixelFont.missing(String(c.name)) == "" and PixelFont.width(String(c.name)) <= S.NAME_W, "%s's name fits" % c.id)
	check(d.get("field", []).size() >= 2, "a few field rows")
	for f in d.get("field", []):
		check(PixelFont.missing(String(f.name)) == "" and PixelFont.width(String(f.name)) <= S.NAME_W, "%s's name fits" % f.id)
	for r in d.ranks:
		check(PixelFont.missing(String(r.title)) == "" and PixelFont.width("Written as: " + String(r.title)) <= S.W - 12, "the title %s fits" % r.title)
	check(d.ranks.size() >= 3, "a few ranks")
	# Every mine trip starts at floor 1 (the year playtest reached floor 6 mining every winter day),
	# so the deepest step must be a floor one day's trip can reach.
	for c in d.categories:
		if c.measure == "mine_deepest":
			check(int(c.steps.back()) <= 20, "the deepest mine step is one day's trip (%d)" % int(c.steps.back()))
	check(Ending.check({"categories": [{"id": "a", "name": "A", "measure": "luck", "steps": [1]}], "ranks": [{"min": 0, "title": "T"}]}) != "",
		"an unknown measure is refused")
	check(Ending.check({"categories": [{"id": "a", "name": "A", "measure": "mine_deepest", "steps": [5, 5]}], "ranks": [{"min": 0, "title": "T"}]}) != "",
		"steps that don't rise are refused")
	check(Ending.check({"categories": [{"id": "a", "name": "A", "measure": "mine_deepest", "steps": [5]}], "ranks": [{"min": 2, "title": "T"}]}) != "",
		"ranks must start at 0")
	check(Ending.check({"categories": [{"id": "a", "name": "A", "measure": "mine_deepest", "steps": [5]}], "ranks": [{"min": 0, "title": "T"}],
		"field": [{"id": "f", "name": "F", "measure": "mine_deepest"}]}) != "", "a field row measures the field")
	# The widest numbers still fit their columns (a long run's shipping, a big gain).
	var big := {"value": 12345678, "unit": "G", "then": 12345678, "gain": 12345678}
	check(PixelFont.width(Ending.then_text(big)) <= S.THEN_R - 8 - S.NAME_W - 4, "the first day column fits")
	check(PixelFont.width(Ending.value_text(big)) <= S.NOW_R - S.THEN_R - 6, "the now column fits")
	check(PixelFont.width(Ending.gain_text(big)) <= S.GAIN_R - S.NOW_R - 6, "the gain column fits")


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


## The look back: the first day's numbers and the gain since the last page beside each row.
func _compare() -> void:
	var d := {"categories": [{"id": "m", "name": "Mine", "measure": "mine_deepest", "steps": [5, 10]},
		{"id": "f", "name": "Fish", "measure": "fish_kinds", "steps": [2, 4]}],
		"field": [{"id": "w", "name": "Weeds", "measure": "debris"}, {"id": "g", "name": "Money", "measure": "money", "unit": "G"}],
		"ranks": [{"min": 0, "title": "Low"}, {"min": 2, "title": "Mid"}]}
	var rec := Ending.grade({"mine_deepest": 12, "fish_kinds": 3}, {}, d)
	var first := {"values": {"mine_deepest": 0, "fish_kinds": 0}, "field": {"debris": 90, "money": 500}}
	var r := Ending.compare(rec, first, {}, {"debris": 20, "money": 3000}, d)
	check(r.first and r.rows[0].then == 0 and r.rows[0].gain == null and r.gained_stars == r.stars, "no earlier page: then only (%s)" % [r.rows[0]])
	check(r.field.size() == 2 and r.field[0].value == 20 and r.field[0].then == 90 and r.field[1].unit == "G", "the field then and now")
	check(Ending.then_text(r.field[1]) == "500 G" and Ending.gain_text(r.field[1]) == "", "first day text; no gain without a page")
	var unknown := Ending.compare(rec, {}, {}, {}, d)
	check(unknown.rows[0].then == -1 and Ending.then_text(unknown.rows[0]) == "-", "a first day not kept shows a dash")
	var last := {"year": 2, "values": {"mine_deepest": 7, "fish_kinds": 3}, "field": {"debris": 35, "money": 1000}, "stars": 2, "rank": 1}
	r = Ending.compare(rec, first, last, {"debris": 20, "money": 3000}, d)
	check(not r.first and r.last_year == 2 and r.rows[0].gain == 5 and r.rows[1].gain == 0, "gains since the last page")
	check(r.gained_stars == r.stars - 2, "stars gained (%d)" % r.gained_stars)
	check(Ending.gain_text(r.rows[0]) == "+5" and Ending.gain_text(r.rows[1]) == "" and Ending.gain_text(r.field[0]) == "-15"
		and Ending.gain_text(r.field[1]) == "+2,000", "gains are signed and split")
	check(not rec.rows[0].has("then"), "compare leaves the graded record as it was")
	var pages := {2: {"year": 2}, 3: {"year": 3}, 5: {"year": 5}}
	check(Ending.last_page(pages, 5).year == 3 and Ending.last_page(pages, 9).year == 5 and Ending.last_page(pages, 2).is_empty(),
		"the last page is the latest earlier one")
	var page := Ending.page_of(4, {"mine_deepest": 3}, {"money": 9}, r)
	check(page == {"year": 4, "values": {"mine_deepest": 3}, "field": {"money": 9}, "stars": r.stars, "rank": r.rank}, "a page keeps its numbers")
	check(Ending.parse_kept(page, true) == ["", page], "a page loads back")
	check(Ending.parse_kept({"values": {"luck": 1}, "field": {}}, false)[0] != "" and Ending.parse_kept({"values": {}, "field": {"money": -1}}, false)[0] != ""
		and Ending.parse_kept({"values": {}, "field": {}}, true)[0] != "", "broken numbers are refused")


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
	# The yearly page: whenever the year has turned (record_due), every year; year 3's is the ending.
	var due := {"record_due": true}
	check(t.pick("day_start", s.merged({"year": 2, "flags": due}, true)) == "year_record", "year 2's New Year: the first yearly page")
	check(t.pick("day_start", s.merged({"flags": due}, true)) == "ending", "year 3: the ending instead")
	check(t.pick("day_start", s.merged({"year": 5, "flags": due, "seen": {"ending": true, "year_record": true}}, true)) == "year_record",
		"every later New Year")
	check(t.pick("day_start", s.merged({"year": 5, "seen": {"ending": true, "year_record": true}}, true)) == "", "not when no page is due")


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
	# The crop and recipe steps follow the content: the top step is every crop / recipe, and
	# the recipes known from the start earn no star.
	var steps := {}
	for c in Ending.data().categories:
		steps[c.measure] = c.steps
	check(int(steps.crop_kinds.back()) == g.crops.size(), "the top crops step is every crop (%d)" % g.crops.size())
	check(int(steps.recipes_known.back()) == Cooking.ids().size(), "the top recipes step is every recipe (%d)" % Cooking.ids().size())
	check(int(steps.recipes_known[0]) > v.recipes_known, "the start recipes (%d) earn no star" % v.recipes_known)
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
	# Neighbours: villagers without hearts known to neighbour_band; friends don't count here.
	check(v.neighbours_known == 0, "no neighbours known yet")
	var near := int(Affection.rules().bands[int(Ending.data().neighbour_band)])
	g.affection.add("kiku", near)
	g.affection.add("nana", near - 1)
	g.affection.add("yae", near + 30)
	g.affection.add("fumi", near)
	check(g.ending_values().neighbours_known == 2 and g.ending_values().heart_bands == 4, "Kiku and Dr. Yae known, Nana not quite; Fumi counts as a friend (%s)" % [g.ending_values()])
	var neighbours := 0
	for id in Villagers.all():
		neighbours += 0 if Villagers.friends().has(id) else 1
	check(int(steps.neighbours_known.back()) == neighbours, "the top neighbours step is everyone without hearts (%d)" % neighbours)
	check(v.recipes_known == Cooking.known_ids(g.flags).size(), "recipes known")
	g.animals.add("chicken")
	var cared: int = g.ending_values().animal_care
	g.animals.list.back().happy = g.animals.happy_max()
	check(g.ending_values().animal_care == cared + 1, "a happy animal counts")
	g.animals.list.back().happy = 0
	check(g.ending_values().animal_care == cared, "an unhappy one doesn't")


## A new game keeps its first day: nothing measured yet, a field full of debris, the starting money.
func _first_day() -> void:
	var g := _game()
	check(g.first_day.values == g.ending_values() and g.first_day.values == g.start_values(), "the first day's numbers (%s)" % [g.first_day.values])
	var f: Dictionary = g.first_day.field
	check(f.debris > 20 and f.tilled == 0 and f.money == g.START_MONEY, "the first day's field (%s)" % [f])
	check(g.field_counts() == f and g.year_pages.is_empty(), "nothing changed yet, no page")
	g.farm.cell(Vector2i(11, 10)).obj = FarmGrid.Obj.NONE
	g.farm.till(Vector2i(11, 10))
	g.money += 250
	var now: Dictionary = g.field_counts()
	check(now.tilled == 1 and now.money == g.START_MONEY + 250, "the field counts follow the farm (%s)" % [now])
	check(g.first_day.field.tilled == 0, "the first day stays as it was")


## The year turning puts a page due; showing it writes the page, and the next one compares.
func _pages() -> void:
	var g := _game()
	g.season = 3
	g.day = 30
	g.end_day()
	check(g.year == 2 and EventRunner.is_set(g.flags, "record_due"), "the New Year puts a page due")
	g.mine_deepest = 6
	var r: Dictionary = g.show_ending("year")
	check(r.page == "year" and r.year == 2 and r.first, "year 2's page is the first")
	check(not g.flags.has("record_due") and g.flags.has("record_first") and not g.flags.has("record_more"), "the page is no longer due; first-year flag")
	check(g.year_pages.has(2) and g.year_pages[2].values.mine_deepest == 6 and g.year_pages[2].stars == r.stars, "year 2's page is kept")
	check(r.rows.size() == Ending.data().categories.size() and r.field.size() == Ending.data().field.size(), "every category and field row")
	g.year = 3
	g.mine_deepest = 20
	r = g.show_ending()
	check(r.page == "ending" and not r.first and r.last_year == 2, "year 3's record compares with year 2")
	var mine: Dictionary = r.rows.filter(func(x): return x.id == "mine")[0]
	check(mine.gain == 14 and mine.then == 0 and mine.value == 20, "the deepest floor: 0 then, 20 now, +14 (%s)" % [mine])
	check(g.flags.has("record_more") and not g.flags.has("record_first"), "more stars than last year")
	g.year = 4
	r = g.show_ending("year")
	check(r.last_year == 3 and r.gained_stars == 0 and not g.flags.has("record_more") and not g.flags.has("record_first"), "a steady year")
	check(g.year_pages.keys().size() == 3, "a page a year")
	# An old save's run with no page yet, past year 2: not the first-year lines.
	g.year_pages = {}
	g.year = 6
	g.show_ending("year")
	check(not g.flags.has("record_first"), "no first-year lines after year 2")


## The ending event runs to the end on the real Game (no screen: the record step goes straight
## on), sets the rank and friend flags and ending_seen.
func _event_plays() -> void:
	for who in Villagers.friends():
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


## The yearly event runs to the end, shows the year page and sends Tome home again.
func _year_event_plays() -> void:
	var g := _game()
	g.year = 2
	g.flags["record_due"] = true
	var r := EventRunner.open("year_record", g)
	check(r.error == "", "the yearly page runs: %s" % r.error)
	if r.error != "":
		return
	r.start(Vector2(40, 40), Vector2i.DOWN)
	var came := false
	for i in 400:
		if r.done():
			break
		r.update(0.5)
		came = came or r.actors.has("tome")
	check(r.done() and came and not r.actors.has("tome"), "Tome comes in and leaves")
	check(g.year_pages.has(2) and not g.flags.has("record_due"), "the page is written")
	for at in ["greet", "after"]:
		check(DialogueRunner.open("year_record", {}, at).error == "", "the yearly lines load (%s)" % at)
	check(EventRunner.new({"steps": [{"do": "ending", "page": "book"}]}, g).error != "", "an unknown page is refused")


## The screen: opens on the record, waits (ending_open), reveals rows, closes on two presses.
func _screen() -> void:
	var g := _game()
	var sc: CanvasLayer = load("res://scripts/ui/ending_screen.gd").new()   # loaded late: it uses the Game autoload
	root.add_child(sc)
	var r: Dictionary = g.show_ending()
	check(sc.is_open() and g.ending_open and g.paused(), "the ending step opens the screen and waits")
	var count: int = r.rows.size() + r.field.size()
	check(sc._names.size() == count and sc.all_rows().size() == count, "a row per category and field row")
	check(sc._stars[r.rows.size()].is_empty() and not sc._stars[0].is_empty(), "stars on categories only")
	check(not sc._names[0].visible and sc._title.text == "", "rows are revealed one by one")
	check(sc._heading.text == "A page for the farmer" and not sc._gain_head.visible, "the ending's heading; no gain without a page")
	var ev := EventRunner.new({"steps": [{"do": "ending"}]}, g)
	ev.update(0.1)
	check(not ev.done(), "an ending step waits while the record is up")
	sc.advance()
	check(sc._names[count - 1].visible and sc._title.text == "Written as: " + String(r.title), "a press shows every row and the title")
	check(sc._thens[0].text == Ending.then_text(r.rows[0]) and sc._values[count - 1].text == Ending.value_text(r.field.back()), "first day and now side by side")
	check(sc._total.text == "%d of %d stars" % [r.stars, r.max], "the stars in all")
	sc.advance()
	check(not sc.is_open() and not g.ending_open and not g.paused(), "a second press closes it")
	ev.update(0.1)
	check(ev.done(), "then the event goes on")
	# Next year's page: its heading and the gains.
	g.year += 1
	g.mine_deepest = 9
	r = g.show_ending("year")
	sc.advance()
	var mine: int = r.rows.map(func(x): return x.id).find("mine")
	check(sc._heading.text == "The farmer's page, year %d" % g.year and sc._gain_head.visible, "a yearly page's heading and gain column")
	check(sc._gains[mine].text == "+9", "the gain since the last page (%s)" % sc._gains[mine].text)
	sc.advance()
	check(not sc.is_open(), "it closes the same way")
	sc.queue_free()


## The scroll: unrolls on open and ends open; every word, stamp and the seal stay on the paper,
## the scroll stays on the screen, for every title and for big numbers.
func _scroll() -> void:
	var g := _game()
	var sc: CanvasLayer = load("res://scripts/ui/ending_screen.gd").new()
	root.add_child(sc)
	var S: Dictionary = sc.get_script().get_script_constant_map()
	var screen: Vector2 = sc.screen_size()
	check(Rect2(Vector2.ZERO, screen).encloses(Rect2(sc._scroll.position, sc._scroll.size)), "the scroll fits the screen (%s)" % sc._scroll.size)
	var r: Dictionary = g.show_ending()
	check(not sc.unrolled() and sc._paper.size.y < sc.full_h * 0.2, "it opens rolled up (%d of %d)" % [sc._paper.size.y, sc.full_h])
	var frames := 0
	var last := -1.0
	var grows := true
	while not sc.unrolled() and frames < 100:
		sc._process(1.0 / 30.0)
		frames += 1
		grows = grows and sc._paper.size.y >= last
		last = sc._paper.size.y
	check(sc.unrolled() and frames <= int(S.UNROLL * 30) + 1 and grows, "it unrolls in %d frames, never shrinking" % frames)
	check(sc._paper.size.y == sc.full_h and sc._bottom.position.y == sc._paper.position.y + sc.full_h - S.TUCK, "it ends open, the bottom roller under the paper")
	check(not sc._names[0].visible, "the rows wait for the scroll to open")
	for i in 200:
		sc._process(1.0 / 30.0)
	var count: int = r.rows.size() + r.field.size()
	check(sc._names[count - 1].visible and sc._seal.visible and sc._title.text != "", "then the rows, the title and the seal come up")
	check(sc._paper.size.y == sc.full_h, "and it stays open")
	_on_paper(sc, S, "the real record")
	for rank in Ending.data().ranks:
		sc.record.title = String(rank.title)
		sc._refresh()
		check(sc._seal.position.x + S.SEAL + 4 <= sc._hint.position.x, "the seal clears the hint for \"%s\"" % rank.title)
		_on_paper(sc, S, rank.title)
	var big: Dictionary = sc.record.duplicate(true)
	for row in big.rows + big.field:   # money in the millions; counts (crops, hearts, floors) in the hundreds
		var most := 9999999 if row.get("unit", "") == "G" else 999
		row.then = most
		row.value = most
		row.gain = -most
		row.stars = row.get("max", 0)
	big.first = false
	sc.record = big
	sc._refresh()
	_on_paper(sc, S, "big numbers")
	for i in count:
		check(sc._thens[i].position.x >= S.MARGIN + S.NAME_W and sc._values[i].position.x > S.THEN_R 			and sc._gains[i].position.x > S.NOW_R, "row %d's columns stay apart with big numbers" % i)
		if not sc._stars[i].is_empty():
			check(sc._gains[i].position.x + PixelFont.width(sc._gains[i].text) < sc._stars[i][0].position.x, "row %d's gain clears its stars" % i)
	sc.advance()
	check(not sc.is_open(), "it closes")
	sc.queue_free()


## A married farmer's record names the spouse and the wedding day (undated for a save from
## before the day was kept); a single farmer's shows nothing. The screen and the yearly page.
func _spouse() -> void:
	var S: Dictionary = load("res://scripts/ui/ending_screen.gd").get_script_constant_map()
	var dated := Ending.spouse_line("sayo", "Sayo", "Spring 14")
	check(dated == "Married Sayo on Spring 14", "the dated line (%s)" % dated)
	check(Ending.spouse_line("fumi", "Fumi", "") == "Married to Fumi", "the undated line")
	check(Ending.spouse_line("", "", "Spring 14") == "", "no spouse, no line")
	for line in [dated, Ending.spouse_line("fumi", "Fumi", "Summer 30"), Ending.spouse_line("sayo", "Sayo", "")]:
		check(PixelFont.missing(line) == "" and PixelFont.width(line) <= S.W - S.MARGIN * 2, "the line fits the paper: %s" % line)
	var g := _game()
	check(g.show_ending().spouse == "", "a single farmer's record has no line")
	g.flags["spouse"] = "sayo"
	g.flags["married_sayo"] = true
	g.flags[Marriage.DAY] = 13
	check(g.short_date_of(13) == "Spring 14" and g.date_of(13) == "Spring 14, Year 1", "the short date and the full one")
	var sc: CanvasLayer = load("res://scripts/ui/ending_screen.gd").new()   # loaded late: it uses the Game autoload
	root.add_child(sc)
	var r: Dictionary = g.show_ending()
	check(r.spouse == "Married Sayo on Spring 14", "the record names Sayo and the wedding day (%s)" % r.spouse)
	sc.advance()
	check(sc._spouse.visible and sc._spouse.text == "Married Sayo on Spring 14", "the screen shows the line once the rows are up")
	_on_paper(sc, S, "married")
	sc.advance()
	check(not sc.is_open(), "the screen closes")
	# The yearly page has it too; a save from before the day was kept says undated.
	g.flags.erase(Marriage.DAY)
	r = g.show_ending("year")
	check(r.spouse == "Married to Sayo", "undated when the day is not known (%s)" % r.spouse)
	sc.advance()
	check(sc._spouse.visible and sc._spouse.text == "Married to Sayo", "the yearly page shows it too")
	sc.advance()
	# Single again: no line, on the screen or in the record.
	g.flags.erase("spouse")
	g.flags.erase("married_sayo")
	r = g.show_ending("year")
	check(r.spouse == "", "no line once single")
	sc.advance()
	check(not sc._spouse.visible and sc._spouse.text == "", "unmarried: nothing shown under the title")
	sc.advance()
	sc.queue_free()


## Every shown label and picture lies inside the paper's margins.
func _on_paper(sc: CanvasLayer, S: Dictionary, what: String) -> void:
	var inside := Rect2(S.MARGIN - 1, S.TUCK, S.W - (S.MARGIN - 1) * 2, sc.full_h - S.TUCK * 2)
	var bad := []
	for n in sc._paper.get_children():
		if not n.visible:
			continue
		var rect := Rect2()
		if n is Label:
			if n.text == "":
				continue
			rect = Rect2(n.position, Vector2(PixelFont.width(n.text), PixelFont.size()))
		elif n is TextureRect and n.stretch_mode != TextureRect.STRETCH_TILE:
			rect = Rect2(n.position, n.size)
		else:
			continue
		if not inside.encloses(rect):
			bad.append(n.text if n is Label else str(rect))
	check(bad.is_empty(), "nothing outside the paper (%s): %s" % [what, bad])


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
