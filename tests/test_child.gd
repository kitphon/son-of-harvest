extends SceneTree
## Headless checks for the child's rules (data/child.json, Child): the data, the news and the
## birth (30 + 30 days, band 6, festival days), the stage by days since the birth, the look
## from the parents, each spouse's three names, the child's hearts (start and floor at band 3),
## the save, and the two scenes: the morning flags (Child.day_start, from Game.end_day), the
## trigger rows in the farmhouse, every spouse's news and birth events and lines (English and
## Thai), the name picked from the three and stored by the event's child step; the baby's
## cradle (step 3): the stage flag, the cradle prop only while the baby stage holds, the lines
## by the clock, lifting the baby and laying them back, no throw, the door rule, the save while
## holding, the art and both views' pictures; the crawler in the arms (data/child.json hold):
## lifted by the tool button facing them, the picture, set down in front or back where they were,
## the door, the night, a map change and a load putting them back to the plan, both views, no
## toddler or older lifted. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_child.gd

var failures := 0
var _frame := 0


func _init() -> void:
	_data()
	_news()
	_birth()
	_stages()
	_look()
	_names()
	_hearts()
	_day_start()
	_event_step()
	_triggers()
	_scenes()
	_thai()
	_cradle_rules()
	_cradle_map()
	_little_data()
	_little_days()
	_little_art()
	_little_lines()
	_child_days()
	_child_help_rules()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_save()
		_morning()
		_play_birth()
		_baby_in_arms()
		_baby_save()
		_crawler_in_arms()
		_crawler_save()
		_crawler_only()
		_little_talk()
		_little_gifts()
		_little_views()
		_child_help_in_game()
		_child_views()
		print("test_child: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


## A married farmer's flags: spouse `id`, wedding on day `wedding`.
func _married(id: String, wedding: int) -> Dictionary:
	return {"spouse": id, "married_" + id: true, "wedding_day": wedding}


func _data() -> void:
	check(Child.check() == "", "data/child.json is usable (%s)" % Child.check())
	check(Child.stage_ids() == ["baby", "crawler", "toddler", "child"], "four stages")
	check(int(Child.data().news_after_days) == 30 and int(Child.data().birth_after_days) == 30, "30 days to the news, 30 more to the birth")


func _news() -> void:
	var f := _married("sayo", 100)
	check(not Child.news_due(f, 129, 6, false), "29 days after the wedding: not yet")
	check(Child.news_due(f, 130, 6, false), "30 days after the wedding at band 6: the news")
	check(Child.news_due(f, 150, 6, false), "later days still bring it")
	check(not Child.news_due(f, 130, 5, false), "band 5: the news waits")
	check(Child.news_due(f, 131, 6, false), "and comes once the hearts are back")
	check(not Child.news_due(f, 130, 6, true), "not on a festival day")
	check(not Child.news_due({}, 130, 6, false), "single: no news")
	check(not Child.news_due({"spouse": "sayo", "wedding_day": 100}, 130, 6, false), "no married flag: no news")
	check(not Child.news_due({"spouse": "sayo", "married_sayo": true}, 130, 6, false), "no wedding day: no news")
	check(not Child.news_due(_married("ren", 100), 130, 5, false) and Child.news_due(_married("ren", 100), 130, 6, false), "the same for every spouse")
	Child.tell_news(f, 130)
	check(f.child_news == 130 and Child.has_news(f) and Child.news_day(f) == 130, "the news sets child_news to the day")
	check(not Child.news_due(f, 131, 6, false), "told once")


func _birth() -> void:
	var f := _married("fumi", 100)
	check(not Child.birth_due(f, 200, false), "no news, no birth")
	Child.tell_news(f, 130)
	check(not Child.birth_due(f, 159, false), "29 days after the news: not yet")
	check(Child.birth_due(f, 160, false), "30 days after the news: the birth")
	check(not Child.birth_due(f, 160, true), "not on a festival day")
	check(Child.birth_due(f, 161, false), "the next plain morning instead")
	check(not Child.is_born(f) and Child.child_name(f) == "" and Child.age(f, 160) == -1 and Child.stage(f, 160) == "", "nobody yet")
	Child.give_birth(f, 161, "Makoto")
	check(f.child_born == 161 and f.child_name == "Makoto" and Child.is_born(f) and Child.child_name(f) == "Makoto", "the birth sets child_born and child_name")
	check(not Child.birth_due(f, 170, false), "born once")
	check(Child.born_day({"child_born": "x"}) == -1 and Child.born_day({"child_born": 2.5}) == -1 and Child.born_day({"child_born": -3}) == -1, "a broken flag is no birth")


func _stages() -> void:
	var cases := {-1: "", 0: "baby", 29: "baby", 30: "crawler", 59: "crawler", 60: "toddler", 119: "toddler", 120: "child", 5000: "child"}
	for d in cases:
		check(Child.stage_at(d) == cases[d], "day %d is %s (%s)" % [d, cases[d], Child.stage_at(d)])
	var f := {"child_born": 200}
	check(Child.age(f, 200) == 0 and Child.stage(f, 200) == "baby", "the birth day is day 0")
	check(Child.age(f, 290) == 90 and Child.stage(f, 290) == "toddler", "90 days on: a toddler")
	check(Child.stage(f, 320) == "child", "120 days on: a child")


func _look() -> void:
	var spouse: Dictionary = Villagers.all().fumi.look
	var l := Child.look(spouse, "f2c79b")
	check(l.hair_style == spouse.hair_style and l.hair == spouse.hair, "the spouse's hair style and colour")
	check(l.skin == Color.html("f2c79b").lerp(Color.html(str(spouse.skin)), 0.5).to_html(false), "the skin is between the two (%s)" % l.skin)
	var dark := Child.look(spouse, "75492f")
	check(dark.skin != l.skin and dark.hair == l.hair, "another farmer skin, another child skin, the same hair")
	check(Child.mix("000000", "ffffff", 0.5) == "7f7f7f" or Child.mix("000000", "ffffff", 0.5) == "808080", "the middle of black and white (%s)" % Child.mix("000000", "ffffff", 0.5))
	check(Child.mix("a8714c", "a8714c", 0.5) == "a8714c", "the middle of one colour is itself")
	check(l.has("top") and l.has("waist"), "the happi's colours are in the look")
	check(Child.look({}, "f2c79b").hair_style != "", "a spouse without a look still gives a usable one")


func _names() -> void:
	var seen := {}
	for id in ["sayo", "fumi", "haru", "ichiro", "mio", "kaede", "shino", "ren"]:
		var n := Child.names(id)
		check(n.size() == 3, "%s offers three names" % id)
		for s in n:
			check(not seen.has(s), "%s is offered once" % s)
			seen[s] = true
	check(Child.names("sayo") == ["Hikari", "Sora", "Aoi"], "Sayo's three")
	check(Child.names("tome").is_empty() and Child.names("").is_empty(), "no names for someone who cannot marry")
	for id in Marriage.candidates():
		check(Child.names(id).size() == 3, "every candidate has names (%s)" % id)


func _hearts() -> void:
	var a := Affection.new()
	var starts: Array = Affection.rules().bands
	check(a.of(Child.ID) == int(starts[3]) and a.band(Child.ID) == 3, "the child starts at band 3 (%d)" % a.of(Child.ID))
	check(a.of("tome") == 0, "villagers still start as strangers")
	a.add(Child.ID, -200)
	check(a.of(Child.ID) == int(starts[3]) and a.band(Child.ID) == 3, "never below band 3")
	a.add(Child.ID, 100)
	check(a.band(Child.ID) >= 4, "and up from there (%d)" % a.of(Child.ID))
	a.add(Child.ID, -1000)
	check(a.band(Child.ID) == 3, "a bad day takes it back to the floor, no further")
	a.add("tome", -5)
	check(a.of("tome") == 0, "other villagers floor at 0")
	var back: Array = Affection.parse(a.to_dict())
	check(back[0] == "" and back[1].of(Child.ID) == a.of(Child.ID), "the child's hearts survive to_dict / parse")
	check(not Affection.new().bands().has(Child.ID), "the child is not in the villagers' bands table")


## The save: the flags and the child's hearts go through Game's save and back.
func _save() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.flags = _married("kaede", 40)
	Child.tell_news(g.flags, 70)
	Child.give_birth(g.flags, 100, "Rin")
	g.affection.add(Child.ID, 30)
	var points: int = g.affection.of(Child.ID)
	var path := "user://test_child.json"
	check(SaveGame.write(g, path) == "", "write the save")
	g.new_game()
	check(not Child.is_born(g.flags) and g.affection.of(Child.ID) == Child.start_points(), "a new game has no child")
	var err := SaveGame.read(g, path)
	check(err == "", "read the save (%s)" % err)
	check(Child.news_day(g.flags) == 70 and Child.born_day(g.flags) == 100 and Child.child_name(g.flags) == "Rin", "child_news, child_born and child_name back")
	check(typeof(g.flags.child_born) == TYPE_INT, "day numbers come back as ints")
	check(g.affection.of(Child.ID) == points and g.affection.band(Child.ID) >= 3, "the child's hearts back (%d)" % g.affection.of(Child.ID))
	check(Child.stage(g.flags, 130) == "crawler", "the stage follows the loaded birth day")
	# A save from before the child has none of it: no child, the hearts at their start.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for k in ["child_news", "child_born", "child_name"]:
		data.game.flags.erase(k)
	data.game.affection.points.erase(Child.ID)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	g.new_game()
	check(SaveGame.read(g, path) == "" and not Child.has_news(g.flags) and not Child.is_born(g.flags) and g.affection.of(Child.ID) == Child.start_points(), "an old save: no child")
	SaveGame.restore({path: null, path + SaveGame.BACKUP: null, path + SaveGame.TEMP: null})
	g.new_game()


## The morning flags: due on the right mornings only, cleared on the others.
func _day_start() -> void:
	var f := _married("mio", 100)
	check(Child.day_start(f, 129, 6, false) == "" and not f.has(Child.NEWS_DUE), "29 days on: nothing due")
	check(Child.day_start(f, 130, 6, false) == "news" and f.get(Child.NEWS_DUE) == true, "30 days on at band 6: the news is due")
	check(Child.day_start(f, 131, 5, false) == "" and not f.has(Child.NEWS_DUE), "band 5 the next morning: not due until the hearts are back")
	check(Child.day_start(f, 132, 6, true) == "" and not f.has(Child.NEWS_DUE), "not on a festival morning")
	check(Child.day_start(f, 133, 6, false) == "news", "due again on the next plain morning")
	Child.tell_news(f, 133)
	check(Child.day_start(f, 134, 6, false) == "" and not f.has(Child.NEWS_DUE) and not f.has(Child.BIRTH_DUE), "told: nothing due")
	check(Child.day_start(f, 162, 0, false) == "", "29 days after the news: no birth yet")
	check(Child.day_start(f, 163, 0, true) == "" and not f.has(Child.BIRTH_DUE), "30 days on, a festival: the birth waits")
	check(Child.day_start(f, 164, 0, false) == "birth" and f.get(Child.BIRTH_DUE) == true, "the next plain morning: the birth is due (the hearts don't matter)")
	Child.give_birth(f, 164, "Kai")
	check(Child.day_start(f, 165, 6, false) == "" and not f.has(Child.BIRTH_DUE), "born: nothing more")
	var single := {}
	check(Child.day_start(single, 500, 6, false) == "" and single.is_empty(), "single: no flags at all")


## The scenes' child step.
func _event_step() -> void:
	var f := _married("shino", 10)
	f[Child.NEWS_DUE] = true
	Child.event_step(f, "birth", 60)
	check(not Child.is_born(f), "no birth before the news")
	Child.event_step(f, "news", 40)
	check(Child.news_day(f) == 40 and not f.has(Child.NEWS_DUE), "news: child_news is the day, the due flag gone")
	Child.event_step(f, "news", 41)
	check(Child.news_day(f) == 40, "a second news step changes nothing")
	f[Child.BIRTH_DUE] = true
	f[Child.NAME] = "Shun"
	Child.event_step(f, "birth", 70)
	check(Child.born_day(f) == 70 and Child.child_name(f) == "Shun" and not f.has(Child.BIRTH_DUE), "birth: child_born is the day, the picked name kept")
	Child.event_step(f, "birth", 80)
	check(Child.born_day(f) == 70, "born once")
	var g := _married("ren", 10)
	Child.tell_news(g, 40)
	g[Child.NAME] = "Hikari"   # not one of Ren's
	Child.event_step(g, "birth", 70)
	check(Child.child_name(g) == "Riku", "a name that isn't the spouse's falls back to their first (%s)" % Child.child_name(g))


## The farmhouse's trigger rows: each spouse's scene on its due morning, and only theirs.
func _triggers() -> void:
	var t := EventTriggers.open("house", true)
	check(t.error == "", "triggers_house.json loads (%s)" % t.error)
	var base := {"year": 1, "season": "summer", "day": 10, "weekday": "mon", "time": 360, "weather": "sunny", "seen": {}, "cell": Vector2i(2, 2), "hearts": {}}
	for id in Marriage.candidates():
		var f := _married(id, 1)
		check(t.pick("day_start", base.merged({"flags": f})) == "", "%s: no due flag, no scene" % id)
		f[Child.NEWS_DUE] = true
		check(t.pick("day_start", base.merged({"flags": f})) == Child.NEWS_EVENT % id, "%s's news on the due morning" % id)
		check(t.pick("enter", base.merged({"flags": f})) == "", "%s: only on waking (day_start), not on walking in" % id)
		check(t.pick("day_start", base.merged({"flags": f, "seen": {Child.NEWS_EVENT % id: true}}, true)) == "", "%s's news plays once" % id)
		f.erase(Child.NEWS_DUE)
		f[Child.BIRTH_DUE] = true
		check(t.pick("day_start", base.merged({"flags": f})) == Child.BIRTH_EVENT % id, "%s's birth on its due morning" % id)
		check(t.pick("day_start", base.merged({"flags": f, "seen": {Child.BIRTH_EVENT % id: true}}, true)) == "", "%s's birth plays once" % id)
	var other := _married("sayo", 1)
	other.erase("married_sayo")
	other[Child.BIRTH_DUE] = true
	check(t.pick("day_start", base.merged({"flags": other})) == "", "no married flag: no scene")


## Every spouse has both scenes, built as DESIGN says, and lines that offer exactly their names.
func _scenes() -> void:
	for id in Marriage.candidates():
		var news := EventRunner.open(Child.NEWS_EVENT % id, null)
		var birth := EventRunner.open(Child.BIRTH_EVENT % id, null)
		check(news.error == "" and birth.error == "", "%s: both scenes load (%s / %s)" % [id, news.error, birth.error])
		var ntext := JSON.stringify(news.steps)
		var btext := JSON.stringify(birth.steps)
		check(ntext.contains('"step":"news"') and ntext.contains('"at":"%s_news"' % id) and ntext.contains('"who":"%s"' % id),
			"%s's news: told by them, with the news step" % id)
		check(btext.contains('"step":"birth"') and btext.contains('"at":"%s_names"' % id) and btext.contains('"who":"%s"' % id)
			and btext.contains('"who":"yae"') and btext.contains('"who":"tome"'), "%s's birth: Dr. Yae and Tome there, the names, the birth step" % id)
		check(not ntext.contains('"step":"birth"') and not btext.contains('"step":"news"'), "%s: each scene sets only its own flag" % id)
		var r := DialogueRunner.open(Child.DIALOGUE, {}, id + "_news")
		check(r.error == "" and r.line().get("speaker") == id, "%s tells the news in their own lines" % id)
		r = DialogueRunner.open(Child.DIALOGUE, {}, id + "_names")
		check(r.error == "" and r.line().get("speaker") == id, "%s offers the names" % id)
		var texts := _run_to_choices(r).map(func(c): return c.text)
		check(texts == Child.names(id), "%s offers their three names %s (%s)" % [id, Child.names(id), texts])
		for i in texts.size():
			var flags := {}
			var d := DialogueRunner.open(Child.DIALOGUE, flags, id + "_names")
			_run_to_choices(d)
			d.pick(i)
			var first: String = d.line().get("text", "")
			var who_spoke: String = d.line().get("speaker", "")
			for _n in 20:
				if d.done():
					break
				d.update(100.0)
				d.press()
			check(flags.get(Child.NAME) == Child.names(id)[i], "%s: picking %s sets child_name" % [id, Child.names(id)[i]])
			check(who_spoke == id and first.begins_with(Child.names(id)[i]) and d.done(), "%s answers the name %s, then the scene's talk ends" % [id, Child.names(id)[i]])
	# No gendered words for the child, the spouse or the farmer (docs/STYLE_EN.md).
	var gendered := RegEx.create_from_string("\\b([Hh]e|[Ss]he|[Hh]is|[Hh]er|[Hh]im|[Bb]oy|[Gg]irl|[Ss]on|[Dd]aughter|[Hh]usband|[Ww]ife|[Bb]ride|[Gg]room)\\b")
	var found := []
	for l in JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/child.json")).lines:
		var m := gendered.search(str(l.get("text", "")))
		if m != null:
			found.append(m.get_string())
	check(found.is_empty(), "no he / she, son / daughter, husband / wife in the child's lines: %s" % [found])


## Steps a dialogue to its line with choices; returns them ([] if none).
func _run_to_choices(r: DialogueRunner) -> Array:
	for _i in 50:
		if r.done():
			return []
		r.update(100.0)
		if not r.choices().is_empty():
			return r.choices()
		r.press()
	return []


## The Thai table covers every line and choice of the child's scenes.
func _thai() -> void:
	Lang.set_language("th")
	var missing := []
	for l in JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/child.json")).lines:
		if l.has("text") and not Lang.covered(l.text):
			missing.append(l.text)
		for c in l.get("choices", []):
			if not Lang.covered(c.text) or Lang.t(c.text) == c.text:
				missing.append(c.text)
	Lang.set_language("en")
	Lang.release()
	check(missing.is_empty(), "the child's lines are all in Thai, still English: %s" % [missing.slice(0, 5)])


## Game.end_day sets the due flag: 29 days after the wedding nothing, 30 the news.
func _morning() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.season = 1
	g.day = 10
	while Festivals.on_date("summer", g.day + 1) != "" or Festivals.on_date("summer", g.day + 2) != "":
		g.day += 1
	g.flags = _married("haru", g.day_number() + 1 - 29)
	g.affection.add("haru", Affection.max_points())
	g.end_day()
	check(not g.flags.has(Child.NEWS_DUE), "the morning 29 days after the wedding: no news due")
	g.end_day()
	check(g.flags.get(Child.NEWS_DUE) == true and g.festival_today() == "", "30 days after: Game.end_day sets child_news_due")
	g.new_game()


## The birth scene played on the real Game: the farmer picks the second name.
func _play_birth() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.flags = _married("kaede", 5)
	Child.tell_news(g.flags, 10)
	g.flags[Child.BIRTH_DUE] = true
	var heard: Array = []
	var answer := func(id: String, at: String) -> void:
		heard.append(id + "@" + at)
		var d := DialogueRunner.open(id, g.flags, at)
		for _i in 50:
			if d.done():
				break
			d.update(100.0)
			if not d.choices().is_empty():
				d.pick(1)
			else:
				d.press()
	g.dialogue_requested.connect(answer)
	var r := EventRunner.open(Child.BIRTH_EVENT % "kaede", g)
	r.start(Vector2(40, 40), Vector2i.DOWN)
	for _i in 400:
		if r.done():
			break
		r.update(0.1)
	g.dialogue_requested.disconnect(answer)
	check(r.done() and heard == ["child@birth", "child@kaede_names"], "the birth scene plays through its two talks %s" % [heard])
	check(Child.born_day(g.flags) == g.day_number() and Child.child_name(g.flags) == "Michi" and not g.flags.has(Child.BIRTH_DUE),
		"the scene's end: born today, named Michi (%s), the due flag gone" % Child.child_name(g.flags))
	g.new_game()



## The stage flag and the cradle's rows: the line and the picture by the clock, the name put in.
func _cradle_rules() -> void:
	var f := _married("sayo", 10)
	Child.sync_stage(f, 50)
	check(not f.has(Child.STAGE), "no child: no stage flag")
	Child.tell_news(f, 40)
	Child.give_birth(f, 70, "Sora")
	for t in [[70, "baby"], [99, "baby"], [100, "crawler"], [130, "toddler"], [190, "child"]]:
		Child.sync_stage(f, t[0])
		check(f.get(Child.STAGE) == t[1], "day %d: child_stage %s (%s)" % [t[0], t[1], f.get(Child.STAGE)])
	check(Child.is_baby(f, 70) and Child.is_baby(f, 99) and not Child.is_baby(f, 100), "a baby from the birth until day 30")
	var g := _married("sayo", 10)
	g[Child.NEWS] = 40
	g[Child.BIRTH_DUE] = true
	Child.event_step(g, "birth", 70)
	check(g.get(Child.STAGE) == "baby", "the birth sets child_stage to baby")
	Child.day_start(g, 100, 6, false)
	check(g.get(Child.STAGE) == "crawler", "a morning keeps the stage flag in step")
	var by_hour := {}
	for h in 24:
		var line := Child.cradle_line(f, h * 60)
		check("Sora" in line and not "%s" in line, "%d:00: the line names the baby (%s)" % [h, line])
		by_hour[h] = [Child.cradle_look(h * 60), line]
	check(by_hour[2][0] == "asleep" and by_hour[23][0] == "asleep", "asleep at night")
	check(by_hour[5][0] == "cry", "crying before dawn")
	check(by_hour[8][0] == "awake" and by_hour[15][0] == "awake", "awake by day")
	check(by_hour[11][0] == "asleep", "a nap late in the morning")
	var lines := {}
	for h in by_hour:
		lines[by_hour[h][1]] = true
	check(lines.size() >= 5, "the line changes through the day (%d lines)" % lines.size())
	check(Child.cradle_line(f, 0) == Child.cradle_line(f, 4 * 60 + 29), "midnight to 4:29 is one row")
	check(Child.cradle_time(23 * 60 + 59) == Child.cradle_time(19 * 60 + 30), "the last row runs to midnight")
	var words := RegEx.create_from_string("(?i)\\b(he|she|him|her|his|hers|boy|girl|son|daughter)\\b")
	for r in Child.data().cradle.times:
		check(words.search(r.line) == null, "no gendered words: %s" % r.line)
	Lang.set_language("th")
	for r in Child.data().cradle.times:
		check(Lang.covered(r.line) and Lang.t(r.line) != r.line, "in Thai: %s" % r.line)
	for k in ["You lift %s from the cradle.", "You lay %s back in the cradle.", "Lay %s back in the cradle first.", "Hold", "Put back"]:
		check(Lang.covered(k), "in Thai: %s" % k)
	Lang.set_language("en")
	Lang.release()
	# The art: the cradle 20 x 16 in four looks, the baby held 12 x 12 like a carried item.
	var look := Child.look({"hair_style": "long", "hair": "2a1a14", "skin": "f0c8a0"}, "c08a60")
	var seen := {}
	for st in ["empty", "asleep", "awake", "cry"]:
		var img := PlaceholderArt.tex(Child.cradle_key(st, look)).get_image()
		check(img.get_size() == Vector2i(20, 16), "the cradle %s is 20 x 16" % st)
		seen[img.get_data()] = st
	check(seen.size() == 4, "the four cradle pictures differ")
	var held := PlaceholderArt.tex(Child.held_key("awake", look)).get_image()
	check(held.get_size() == Vector2i(12, 12), "the baby held is 12 x 12, like an item overhead")
	check(Child.held_key("cry", look) == Child.held_key("awake", look) and Child.held_key("asleep", look) != Child.held_key("awake", look), "held: asleep or awake")
	# Refined like the figures: no pure-black outline pixel, several tones, the keys' sizes kept.
	var fair := Child.look({"hair_style": "long", "hair": "7a5a3a", "skin": "f0c8a0"}, "c08a60")   # dark hair has dark tones of its own
	for key in [Child.cradle_key("awake", fair), Child.cradle_key("empty", fair), Child.held_key("asleep", fair), Child.carry_key(fair)]:
		var pic := PlaceholderArt.tex(key).get_image()
		var tones := {}
		var dark := 0
		for yy in pic.get_height():
			for xx in pic.get_width():
				var px := pic.get_pixel(xx, yy)
				if px.a > 0.0:
					tones[px.to_html()] = true
					if px.is_equal_approx(PlaceholderArt.OUTLINE) or maxf(px.r, maxf(px.g, px.b)) < 0.08:
						dark += 1
		check(dark == 0, "%s: no black outline pixels (the old line colour or near 0) (%d)" % [key.get_slice(":", 1), dark])
		check(tones.size() >= 8, "%s: several tones (%d)" % [key.get_slice(":", 1), tones.size()])
	check(PlaceholderArt.tex(Child.carry_key(look)).get_image().get_size() == Vector2i(16, 14), "the carried crawler stays 16 x 14")
	var skin := Color(look.skin)
	var found := false
	for y in held.get_height():
		for x in held.get_width():
			found = found or held.get_pixel(x, y).is_equal_approx(skin)
	check(found, "the held baby has the child's skin (Child.look)")


## The cradle prop in the second room only while the baby stage holds, and only once the
## room is built.
func _cradle_map() -> void:
	var cradles := func(ext: Array, f: Dictionary) -> Array:
		var out := []
		for p in MapManager.load_map("house", ext, f)[1].props:
			if p.kind == Child.CRADLE:
				out.append(p)
		return out
	check(cradles.call(["room"], {}).is_empty(), "no child: no cradle")
	for st in ["crawler", "toddler", "child"]:
		check(cradles.call(["room"], {Child.STAGE: st}).is_empty(), "no cradle once the child is a %s" % st)
	var c: Array = cradles.call(["room"], {Child.STAGE: "baby"})
	check(c.size() == 1 and Vector2i(c[0].cell) == Vector2i(10, 1), "the baby's cradle in the second room at (10, 1)")
	check(cradles.call([], {Child.STAGE: "baby"}).is_empty(), "no cradle without the second room")
	var m: MapData = MapManager.load_map("house", ["room"], {Child.STAGE: "baby"})[1]
	check(m.is_solid(Vector2i(10, 1)) and not m.is_solid(Vector2i(10, 2)) and not m.is_solid(Vector2i(9, 1)), "the cradle is solid, the cells in front free")


# --- step 4: the crawler and the toddler -----------------------------------------------

## A day's state as Game.trigger_state gives it: Sayo's spouse, the child at `stage`.
func _state(stage: String, weather := "sunny", time := 600, festival := "", weekday := "mon") -> Dictionary:
	var f := _married("sayo", 0)
	f[Child.BORN] = 0
	f[Child.NEWS] = 0
	f[Child.NAME] = "Sora"
	if stage != "":
		f[Child.STAGE] = stage
	return {"year": 1, "season": "spring", "day": 2, "weekday": weekday, "time": time, "weather": weather,
		"flags": f, "seen": {}, "cell": Vector2i.ZERO, "hearts": {}, "festival": festival}


func _little_data() -> void:
	check(Child.FIGURE_STAGES == ["crawler", "toddler", "child"], "three stages are figures of their own")
	var s := _state("crawler")
	check(Child.about(s.flags), "a crawler is about")
	s.flags[Child.STAGE] = "baby"
	check(not Child.about(s.flags) and Child.plan(s) == null, "a baby is in the cradle, not about")
	s.flags.erase(Child.BORN)
	s.flags[Child.STAGE] = "toddler"
	check(not Child.about(s.flags), "no birth, no little one")
	check(Child.takes_gifts("toddler") and Child.takes_gifts("child") and not Child.takes_gifts("crawler") and not Child.takes_gifts("baby"),
		"gifts from the toddler on")
	check(Child.small_style("long") == "bun" and Child.small_style("straw_hat") == "short" and Child.small_style("bun") == "bun",
		"long hair is tied up in a bun, no hats or headbands on the little one")
	check(Villagers.reaction(Child.ID, "food:dango") == "love" and Villagers.reaction(Child.ID, "wild:kuwa") == "like"
		and Villagers.reaction(Child.ID, "wild:fukinoto") == "hate" and Villagers.reaction(Child.ID, "turnip") == "neutral",
		"the little one loves sweets, likes berries, hates bitter shoots")
	# Every house cell the plans use is free in the farmhouse with the second room (and no cradle).
	var house: MapData = MapManager.load_map("house", ["room"], {Child.STAGE: "toddler"})[1]
	var bad := []
	for st in ["crawler", "toddler"]:
		var d := Child.days_of(st)
		for name in d.plans:
			var p: DayPlan = DayPlan.build(d.plans[name], float(d.speed))[1]
			for e in p.entries:
				if e.map == "house" and house.is_solid(Vector2i(e.pos.floor())):
					bad.append("%s %s start" % [st, name])
			for w in p.walks():
				if w[0] == "house":
					for k in 11:
						var c := Vector2i((w[1] as Vector2).lerp(w[2], k / 10.0).floor())
						if house.is_solid(c):
							bad.append("%s %s %s" % [st, name, c])
		var off: Array = Child.data().days.by_spouse[st]
		if house.is_solid(Vector2i(9, 3) + Vector2i(int(off[0]), int(off[1]))):
			bad.append("%s by the spouse" % st)
	check(bad.is_empty(), "the plans walk only on free floor in the second room %s" % [bad])
	# The spouse's spot at home leaves the way into the second room open: (8, 3) stays free of the little one.
	for st in ["crawler", "toddler"]:
		var off: Array = Child.data().days.by_spouse[st]
		check(Vector2i(9, 3) + Vector2i(int(off[0]), int(off[1])) != Vector2i(8, 3), "%s by the spouse leaves the door of the room free" % st)


func _little_days() -> void:
	Villagers.reset_day()
	# The crawler: at Sayo's side while she is home, on the mat on their own while she keeps the store, in bed at night.
	var s := _state("crawler")
	var at := func(t: int, st: Dictionary) -> Dictionary:
		return Villagers.where(Child.ID, float(DayPlan.day_minute(t / 60, t % 60)), st)
	var sayo: Dictionary = Villagers.where("sayo", float(DayPlan.day_minute(7, 0)), s)
	var w: Dictionary = at.call(7 * 60, s)
	check(sayo.map == "house" and w.map == "house" and w.pos == sayo.pos + Vector2(0, 1), "7:00: the crawler on the mat in front of Sayo (%s, %s)" % [w.pos, sayo.pos])
	check(w.facing == Vector2i.UP and not w.moving, "turned up to Sayo, still")
	check(w.stage == "crawler" and w.look == Child.colours(s.flags), "drawn as the crawler in the child's colours")
	w = at.call(11 * 60, s)
	check(Villagers.where("sayo", float(DayPlan.day_minute(11, 0)), s).map != "house" and w.map == "house", "11:00: Sayo at the store, the crawler at home")
	var spots := {}
	for m in range(9 * 60, 16 * 60, 7):
		var p: Dictionary = at.call(m, s)
		check(p.map == "house", "the crawler never leaves the house (%d)" % m)
		spots[Vector2i(p.pos.floor())] = true
	check(spots.size() >= 3, "and crawls about the mat (%d cells)" % spots.size())
	check(at.call(21 * 60, s).map == DayPlan.AWAY and at.call(3 * 60, s).map == DayPlan.AWAY, "in bed at night")
	var on_map := Villagers.on_map("house", float(DayPlan.day_minute(7, 0)), s)
	check(on_map.any(func(v): return v.id == Child.ID) and on_map.any(func(v): return v.id == "sayo"), "on_map shows the little one with Sayo")
	check(Villagers.sprite_key(w.merged({"id": Child.ID})).begins_with("child:figure:crawler:bun:"), "the crawler's sprite key %s" % Villagers.sprite_key(w.merged({"id": Child.ID})))
	# The toddler: beside Sayo at home, out in the yard by the kennel on a dry day, in on a wet one or a festival.
	s = _state("toddler")
	w = at.call(7 * 60, s)
	sayo = Villagers.where("sayo", float(DayPlan.day_minute(7, 0)), s)
	check(w.map == "house" and w.pos == sayo.pos + Vector2(1, 0) and w.facing == Vector2i.LEFT, "7:00: the toddler beside Sayo, turned to her")
	var home: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/animals.json")).dog.home
	var kennel := Vector2(home[0], home[1]) + Vector2(0.5, 0.5)
	for m in [9 * 60 + 30, 11 * 60, 13 * 60 + 20, 15 * 60]:
		w = at.call(m, s)
		check(w.map == "farm" and w.pos.distance_to(kennel) <= 2.5, "%d: the toddler in the yard by the dog's kennel (%s)" % [m, w.pos])
	check(Child.plan_name(s) == "yard", "a sunny day: the yard")
	check(at.call(17 * 60, s).map == "house" and at.call(21 * 60, s).map == DayPlan.AWAY, "home by the evening, in bed at night")
	for wet in ["rain", "storm", "snow"]:
		var ws := _state("toddler", wet)
		check(Child.plan_name(ws) == "indoors" and at.call(11 * 60, ws).map == "house", "%s: the toddler stays in" % wet)
	var fs := _state("toddler", "sunny", 600, "blossom_day")
	check(Child.plan_name(fs) == "indoors", "a festival day: in the house")
	# The child stage has plans of its own (step 5, _child_days).
	check(Child.plan_name(_state("child")) == "out" and at.call(8 * 60, _state("child")).map == "farm", "the child stage: out in the yard at 8:00")
	check(Villagers.sprite_key((at.call(8 * 60, _state("child")) as Dictionary).merged({"id": Child.ID})).begins_with("child:figure:child:"), "drawn in the child build")
	# No little one, no figure.
	var none := _state("")
	none.flags.erase(Child.BORN)
	Villagers.reset_day()
	check(Villagers.where(Child.ID, 600.0, none).is_empty() and not Villagers.on_map("house", 420.0, none).any(func(v): return v.id == Child.ID),
		"no child: nobody under the id child")
	Villagers.reset_day()


func _little_art() -> void:
	var look := Child.look({"hair_style": "long", "hair": "3a2420", "skin": "f2c79b"}, "e0a878")
	var keys := {}
	for st in ["crawler", "toddler", "child"]:
		for back in [Vector2i.DOWN, Vector2i.LEFT]:
			for mv in [false, true]:
				var key := Child.figure_key({"stage": st, "look": look, "facing": back, "moving": mv, "walked": 0.5})
				var style := "long" if st == "child" else "bun"   # the child grows the long hair out
				check(key.begins_with("child:figure:%s:%s:" % [Child.figure(st).build, style]), "the key names the build and the small style: %s" % key)
				var img := PlaceholderArt.image(key)
				check(img.get_size() == PlaceholderArt.FIGURE_SIZE, "%s is a figure's size" % key)
				keys[img.get_data()] = true
	check(keys.size() == 12, "front, back, still and walking differ for each build (%d)" % keys.size())
	var walk := {}
	for f in 4:
		walk[PlaceholderArt.image("child:figure:crawler:bun:e0a878:3a2420:2e4a8c:front:walk:%d" % f).get_data()] = true
	check(walk.size() >= 2, "the crawl moves (%d frames differ)" % walk.size())
	var tops := {}
	for b in ["crawler", "toddler", "child"]:
		var img := PlaceholderArt.image("child:figure:%s:short:e0a878:3a2420:2e4a8c:front:idle:0" % b)
		tops[b] = img.get_used_rect().position.y
		check(img.get_used_rect().end.y == FigureArt.H, "%s stands on the bottom row" % b)
	check(tops.crawler > tops.toddler and tops.toddler > tops.child, "the crawler lowest, then the toddler, then the child %s" % [tops])
	var skin := Color("e0a878").lerp(Color("f2c79b"), 0.5)
	var img := PlaceholderArt.image(Child.figure_key({"stage": "toddler", "look": look, "facing": Vector2i.DOWN, "moving": false, "walked": 0.0}))
	var found := false
	for y in img.get_height():
		for x in img.get_width():
			found = found or img.get_pixel(x, y).is_equal_approx(Color(look.skin))
	check(found and Color(look.skin).is_equal_approx(Color(skin.to_html(false))), "the toddler in the skin between the parents")


func _little_lines() -> void:
	var d := Talk.data(Child.ID)
	check(Talk.check(d) == "", "talk_child.json is a talk file (%s)" % Talk.check(d))
	var r := DialogueRunner.open(Talk.dialogue_id(Child.ID), {})
	check(r.error == "", "its lines run (%s)" % r.error)
	check(DialogueRunner.speakers().has(Child.ID) and DialogueRunner.portrait_key({"speaker": Child.ID}) == "", "the little one can speak, with no portrait")
	var longest := ""
	for who in Marriage.candidates():
		for n in Child.names(who):
			if PixelFont.width(n) > PixelFont.width(longest):
				longest = n
	var named := Child.named_dialogue(d, longest)
	var gendered := RegEx.create_from_string("\\b(he|she|him|her|his|hers|boy|girl|son|daughter|mama|papa|dada)\\b")
	var thai := 0
	for l in named.lines:
		check(not "%s" in l.text, "the name is put in: %s" % l.text)
		check(TextBoxLayout.wrap_rows(l.text, TextBoxLayout.text_w(false)).size() <= TextBoxLayout.ROWS, "with %s it fits: %s" % [longest, l.text])
		check(gendered.search(l.text.to_lower()) == null, "no gendered word: %s" % l.text)
	Lang.set_language("th")
	for l in d.lines:
		check(Lang.covered(l.text), "Thai: %s" % l.text)
		if Lang.covered(l.text):
			thai += 1
	for l in named.lines:
		var t := Lang.t(l.text)
		check(not longest in t and TextBoxLayout.wrap_rows(t, TextBoxLayout.text_w(false)).size() <= TextBoxLayout.ROWS, "Thai with the name fits: %s" % t)
	check(Lang.covered("%s is too little for presents yet." % longest) and Lang.covered("Little one"), "the crawler's gift note and the speaker in Thai")
	Lang.set_language("en")
	check(thai == d.lines.size(), "every line in Thai (%d of %d)" % [thai, d.lines.size()])
	# Picks by the stage.
	var s := _state("crawler")
	s.merge({"band": 3, "again": false, "day_number": 4, "stage": "crawler", "map": "house"})
	check(Talk.pick(Child.ID, s).begins_with("crawler_"), "a crawler babbles (%s)" % Talk.pick(Child.ID, s))
	s.time = 7 * 60
	check(Talk.pick(Child.ID, s) == "crawler_morning", "early: yawning")
	s.time = 600
	s.stage = "toddler"
	check(Talk.pick(Child.ID, s).begins_with("toddler_"), "a toddler talks (%s)" % Talk.pick(Child.ID, s))
	s.map = "farm"
	check(Talk.pick(Child.ID, s).begins_with("yard_"), "in the yard, about the yard")
	s.map = "house"
	s.band = 5
	check(Talk.pick(Child.ID, s).begins_with("close_"), "band 5: close lines")
	s.again = true
	check(Talk.pick(Child.ID, s).begins_with("again_"), "again today: busy")
	s.stage = "crawler"
	check(Talk.pick(Child.ID, s).begins_with("crawler_again_"), "the crawler again: busy too")


## The little one at home: a crawler at Sayo's side in the farmhouse at 7:00.
func _little_home(g: Node, stage: String) -> void:
	g.new_game()
	g.clock_running = false
	g._finish_build({"build": "room", "shop": g._builder_shop("room"), "ready": 0})
	g.year = 2
	var m := _married("sayo", 5)
	for k in m:
		g.flags[k] = m[k]
	var from := {"crawler": 30, "toddler": 60, "child": 120}[stage] as int
	Child.tell_news(g.flags, g.day_number() - from)
	Child.give_birth(g.flags, g.day_number() - from, "Sora")
	Child.sync_stage(g.flags, g.day_number())
	g.hour = 7
	g.minute = 0
	g.weather_today = "sunny"
	Villagers.reset_day()


func _little_talk() -> void:
	var g: Node = root.get_node("Game")
	var FA: GDScript = load("res://scripts/farm_actions.gd")
	var AH: GDScript = load("res://scripts/ui/action_hints.gd")
	_little_home(g, "crawler")
	check(g.flags.get(Child.STAGE) == "crawler", "30 days on: a crawler")
	var w: Dictionary = Villagers.where(Child.ID, g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	var cell := Vector2i(w.pos.floor())
	check(w.map == "house" and cell == Vector2i(9, 4), "the crawler on the mat at (9, 4) (%s)" % cell)
	var said: Array = []
	var hear := func(id: String, at: String) -> void: said.append([id, at])
	g.dialogue_requested.connect(hear)
	var notes: Array = []
	var note := func(t: String) -> void: notes.append(t)
	g.message.connect(note)
	var from := cell + Vector2i.LEFT
	g.maps.place("house", from, Vector2i.RIGHT)
	check(AH.pick(from, Vector2i.RIGHT).get("interact", "") == "Talk", "the key hint says Talk %s" % [AH.pick(from, Vector2i.RIGHT)])
	var before: int = g.affection.of(Child.ID)
	FA.on_action("interact", from, Vector2i.RIGHT)
	check(said.size() == 1 and said[0][0] == "talk_child" and said[0][1] == "crawler_morning", "E: the crawler's morning line %s" % [said])
	check(g.affection.of(Child.ID) == before + int(Affection.rules().talk), "a talk counts once a day (%d -> %d)" % [before, g.affection.of(Child.ID)])
	check(g.heart_band(Child.ID) == 3, "the name tag's hearts: band 3")
	var made: Dictionary = g.dialogue_made.get("talk_child", {})
	var line: Dictionary = made.get("lines", []).filter(func(l): return l.get("id") == "crawler_morning")[0] if not made.is_empty() else {}
	check(line.get("text", "").contains("Sora") and not line.get("text", "").contains("%s"), "the line has the name in it: %s" % line.get("text", ""))
	check(Villagers.where(Child.ID, g.day_minutes(), g.trigger_state(Vector2i.ZERO)).facing == Vector2i.LEFT, "the crawler turns to the farmer")
	FA.on_action("interact", from, Vector2i.RIGHT)
	check(said.back()[1].begins_with("crawler_again_") and g.affection.of(Child.ID) == before + int(Affection.rules().talk), "again: busy, no more hearts")
	# A crawler takes no gifts: the farmer keeps the item.
	g.held = "food:dango"
	FA.on_action("interact", from, Vector2i.RIGHT)
	check(g.held == "food:dango" and notes.back() == "Sora is too little for presents yet.", "the crawler takes no gift (%s)" % notes.back())
	g.held = ""
	# Many nights untalked to: the hearts never fall below band 3.
	var rng := RandomNumberGenerator.new()
	for d in 60:
		g.affection.day_end(g.day_number() + 1 + d, rng)
	check(g.affection.band(Child.ID) == 3, "two months of neglect: still band 3")
	g.dialogue_requested.disconnect(hear)
	g.message.disconnect(note)


func _little_gifts() -> void:
	var g: Node = root.get_node("Game")
	_little_home(g, "toddler")
	var said: Array = []
	var hear := func(id: String, at: String) -> void: said.append([id, at])
	g.dialogue_requested.connect(hear)
	var before: int = g.affection.of(Child.ID)
	g.held = "food:dango"
	check(g.talk_to(Child.ID, Vector2i.DOWN) == "gift", "the toddler takes a gift")
	check(not g.holding() and said.back() == ["talk_child", "gift_love"], "dango, loved %s" % [said])
	check(g.affection.of(Child.ID) - before == int(Affection.rules().gift.love), "a loved gift's hearts (%d)" % (g.affection.of(Child.ID) - before))
	g.held = "wild:fukinoto"
	g.talk_to(Child.ID, Vector2i.DOWN)
	check(g.held == "wild:fukinoto" and said.back() == ["talk_child", "gift_again"], "one gift a day: the second is kept")
	g.held = ""
	g.dialogue_requested.disconnect(hear)


## Both views draw the little one on the house map: the crawler beside Sayo, then the toddler in the yard.
func _little_views() -> void:
	var g: Node = root.get_node("Game")
	_little_home(g, "crawler")
	var v3: Node = load("res://scripts/world3d/villager_sprites.gd").new("house")
	var v2: Node = load("res://scripts/world/villager_view.gd").new("house")
	root.add_child(v3)
	root.add_child(v2)
	check(Child.ID in v3.shown() and Child.ID in v2.shown(), "both views show the crawler in the farmhouse")
	var s3: Sprite3D = v3._sprites[Child.ID]
	var s2: Sprite2D = v2._sprites[Child.ID]
	check(str(s3.get_meta("key")).begins_with("child:figure:crawler:") and s2.get_meta("key") == s3.get_meta("key"), "the crawler's picture in both (%s)" % s3.get_meta("key"))
	check(Vector2(s3.position.x, s3.position.z) == Vector2(9.5, 4.5) and s2.position == Vector2(9.5, 4.5) * 16, "at the spot in both")
	v3.queue_free()
	v2.queue_free()
	_little_home(g, "toddler")
	g.hour = 11
	var y3: Node = load("res://scripts/world3d/villager_sprites.gd").new("farm")
	var y2: Node = load("res://scripts/world/villager_view.gd").new("farm")
	root.add_child(y3)
	root.add_child(y2)
	check(Child.ID in y3.shown() and Child.ID in y2.shown() and str(y3._sprites[Child.ID].get_meta("key")).begins_with("child:figure:toddler:"),
		"11:00 on a dry day: the toddler in the yard in both views")
	y3.queue_free()
	y2.queue_free()
	g.new_game()


## A married farmer in the farmhouse with a baby born today, the second room built, standing
## below the cradle facing it.
func _baby_home(g: Node) -> void:
	g.new_game()
	g.clock_running = false
	g._finish_build({"build": "room", "shop": g._builder_shop("room"), "ready": 0})
	var m := _married("sayo", 5)
	for k in m:
		g.flags[k] = m[k]
	Child.tell_news(g.flags, g.day_number())
	Child.give_birth(g.flags, g.day_number(), "Sora")
	Child.sync_stage(g.flags, g.day_number())
	g.maps.place("house", Vector2i(10, 2), Vector2i.UP)


## Looking in, lifting, no throw, the door rule, laying back, the views' pictures, the morning.
func _baby_in_arms() -> void:
	var g: Node = root.get_node("Game")
	var FA: GDScript = load("res://scripts/farm_actions.gd")   # they name the Game autoload: loaded once it is up
	var AH: GDScript = load("res://scripts/ui/action_hints.gd")
	var CL: GDScript = load("res://scripts/world3d/cradle_layer.gd")
	var said: Array = []
	var hear := func(t: String) -> void: said.append(t)
	var thrown: Array = []
	var fly := func(item, _a, _b, _r) -> void: thrown.append(item)
	g.message.connect(hear)
	g.thrown.connect(fly)
	_baby_home(g)
	var at := Vector2i(10, 2)
	var cradle := Vector2i(10, 1)
	check(g.is_cradle(cradle) and not g.is_cradle(at), "the cradle is at (10, 1) in the farmhouse")
	check(g.cradle_prop("farm").is_empty(), "no cradle on the farm")
	g.hour = 8
	g.minute = 0
	check(AH.pick(at, Vector2i.UP) == {"interact": "Look", "use_tool": "Hold"}, "the key hints: Look and Hold %s" % [AH.pick(at, Vector2i.UP)])
	FA.on_action("interact", at, Vector2i.UP)
	check(not said.is_empty() and said.back() == Child.cradle_line(g.flags, 8 * 60) and not g.baby_held, "E looks in: the 8:00 line %s" % [said])
	g.hour = 2
	FA.on_action("interact", at, Vector2i.UP)
	check(said.back() == Child.cradle_line(g.flags, 2 * 60) and said.back() != Child.cradle_line(g.flags, 8 * 60), "at 2:00 another line (%s)" % said.back())
	g.hour = 8
	var crad := CradleView.new()
	root.add_child(crad)
	crad.refresh()
	check(crad.key() == Child.cradle_key("awake", g.child_look()), "the flat view's cradle: the baby awake at 8:00 (%s)" % crad.key())
	var layer: Node3D = CL.new("house")
	root.add_child(layer)
	check(layer.sprite != null and layer.sprite.visible and layer.sprite.get_meta("key") == crad.key(), "the 3D view's cradle: the same picture")
	FA.on_action("tool", at, Vector2i.UP)
	check(g.baby_held and g.holding() and g.held == "", "the tool button lifts the baby (the hand slot stays empty)")
	check(said.back() == "You lift Sora from the cradle.", "lifted: %s" % said.back())
	check(g.held_key() == Child.held_key("awake", g.child_look()), "the baby is the picture overhead (%s)" % g.held_key())
	crad.refresh()
	layer.refresh()
	check(crad.key() == Child.cradle_key("empty", g.child_look()) and layer.sprite.get_meta("key") == crad.key(), "both views show the cradle empty")
	check(AH.pick(at, Vector2i.UP) == {"interact": "Put back", "use_tool": "Put back"} and AH.pick(at, Vector2i.LEFT) == {"interact": "", "use_tool": ""},
		"the key hints while held: Put back at the cradle only")
	# Not thrown, not set down, no sleep: only the cradle takes the baby.
	for kind in ["interact", "tool"]:
		FA.on_action(kind, at, Vector2i.LEFT)
		check(g.baby_held and thrown.is_empty() and g.farm.item_at(at + Vector2i.LEFT) == "", "%s facing the floor: still held, nothing thrown or put down" % kind)
	check(said.back() == "Your hands are full.", "the hands are full")
	var day: int = g.day
	g.maps.place("house", Vector2i(1, 3), Vector2i.UP)
	FA.on_action("interact", Vector2i(1, 3), Vector2i.UP)   # the futon
	check(g.baby_held and g.maps.id == "house" and g.day == day, "no sleeping with the baby in the arms")
	g.maps.place("house", Vector2i(4, 5), Vector2i.DOWN)
	FA.on_action("enter", Vector2i(4, 5), Vector2i.DOWN)   # the farmhouse door
	check(g.maps.id == "house" and g.baby_held, "the door waits: still in the farmhouse with the baby")
	check(said.back() == "Lay Sora back in the cradle first.", "the door rule says why: %s" % said.back())
	g.maps.place("house", at, Vector2i.UP)
	FA.on_action("interact", at, Vector2i.UP)
	check(not g.baby_held and not g.holding() and said.back() == "You lay Sora back in the cradle.", "E at the cradle lays the baby back")
	FA.on_action("tool", at, Vector2i.UP)
	FA.on_action("tool", at, Vector2i.UP)
	check(not g.baby_held, "the tool button at the cradle lays the baby back too")
	# Map changes and the night put the baby back (an event, a collapse).
	g.lift_baby()
	g.go_to_map("farm", Vector2i(4, 4), Vector2i.DOWN)
	check(not g.baby_held, "a map change lays the baby back")
	g.maps.place("house", at, Vector2i.UP)
	check(g.lift_baby(), "lifted again")
	g.end_day()
	check(not g.baby_held, "a new day lays the baby back")
	g.maps.place("house", at, Vector2i.UP)
	g.held = "turnip"
	check(not g.lift_baby(), "no lifting with an item in hand")
	g.held = ""
	# 30 days after the birth: a crawler, the cradle gone.
	for i in 29:
		g.end_day()
	check(Child.stage(g.flags, g.day_number()) == "crawler" and g.flags.get(Child.STAGE) == "crawler", "30 days on: a crawler (%s)" % g.flags.get(Child.STAGE))
	g.maps.place("house", at, Vector2i.UP)
	check(not g.is_cradle(cradle) and not g.lift_baby(), "no cradle, nothing to lift")
	crad.refresh()
	layer.refresh()
	check(crad.key() == "" and not layer.sprite.visible, "both views drop the cradle")
	crad.free()
	layer.free()
	g.message.disconnect(hear)
	g.thrown.disconnect(fly)
	g.new_game()


## Saved while holding: on load the baby is back in the cradle.
func _baby_save() -> void:
	var g: Node = root.get_node("Game")
	_baby_home(g)
	check(g.lift_baby(), "lift the baby")
	var path := "user://test_child_baby.json"
	check(SaveGame.write(g, path) == "", "write the save while holding")
	g.new_game()
	var err := SaveGame.read(g, path)
	check(err == "", "read it (%s)" % err)
	check(not g.baby_held and not g.holding() and g.held == "", "loaded: the arms are empty")
	check(g.maps.id == "house" and g.is_cradle(Vector2i(10, 1)) and g.flags.get(Child.STAGE) == "baby", "and the baby is in the cradle")
	SaveGame.restore({path: null, path + SaveGame.BACKUP: null, path + SaveGame.TEMP: null})
	g.new_game()


# --- holding the crawler (data/child.json hold) -----------------------------------------

func _crawler_where(g: Node, t := -1.0) -> Dictionary:
	return Villagers.where(Child.ID, g.day_minutes() if t < 0.0 else t, g.trigger_state(Vector2i.ZERO))


## Lifting, the picture, the hints, the door, setting down in front and back where they were,
## the stay and the plan after it, both views, a map change and the night.
func _crawler_in_arms() -> void:
	var g: Node = root.get_node("Game")
	var FA: GDScript = load("res://scripts/farm_actions.gd")
	var AH: GDScript = load("res://scripts/ui/action_hints.gd")
	var said: Array = []
	var hear := func(t: String) -> void: said.append(t)
	var thrown: Array = []
	var fly := func(item, _a, _b, _r) -> void: thrown.append(item)
	g.message.connect(hear)
	g.thrown.connect(fly)
	check(Child.liftable("crawler") and not Child.liftable("toddler") and not Child.liftable("child") and not Child.liftable("baby"), "hold.stages: the crawler only")
	check(Child.hold_stay() > 0.0, "a set-down crawler stays a while (%s min)" % Child.hold_stay())
	_little_home(g, "crawler")
	var w := _crawler_where(g)
	var cell := Vector2i(w.pos.floor())
	var from := cell + Vector2i.LEFT
	g.maps.place("house", from, Vector2i.RIGHT)
	check(AH.pick(from, Vector2i.RIGHT) == {"interact": "Talk", "use_tool": "Hold"}, "the key hints facing the crawler: Talk and Hold %s" % [AH.pick(from, Vector2i.RIGHT)])
	FA.on_action("tool", from, Vector2i.RIGHT)
	check(g.crawler_held() and g.holding() and g.held == "" and not g.baby_held, "the tool button lifts the crawler (the hand slot stays empty)")
	check(not said.is_empty() and said.back() == "You pick Sora up.", "lifted: %s" % [said])
	check(g.held_key() == Child.carry_key(g.child_look()) and g.held_key().begins_with("child:carry:"), "the crawler is the picture overhead (%s)" % g.held_key())
	check(_crawler_where(g).map == DayPlan.AWAY and Villagers.on_map("house", g.day_minutes(), g.trigger_state(Vector2i.ZERO)).filter(func(v): return v.id == Child.ID).is_empty(),
		"held: not on the floor any more")
	var img := PlaceholderArt.tex(g.held_key()).get_image()
	var baby := PlaceholderArt.tex(Child.held_key("awake", g.child_look())).get_image()
	var top := Color(str(g.child_look().get("top", "2e4a8c")))
	var skin := Color(str(g.child_look().get("skin", "e0b088")))
	var has_top := false
	var has_skin := false
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			has_top = has_top or px.is_equal_approx(top)
			has_skin = has_skin or px.is_equal_approx(skin)
	check(img.get_size() == Vector2i(16, 14) and img.get_width() > baby.get_width(), "the held crawler is 16 x 14, bigger than the swaddled baby (%s)" % img.get_size())
	check(has_top and has_skin, "in the child's colours: the happi and the skin")
	check(AH.pick(from, Vector2i.RIGHT) == {"interact": "Put down", "use_tool": "Put down"} and AH.pick(from, Vector2i.UP) == {"interact": "Put down", "use_tool": "Put down"},
		"the key hints while held: Put down either way")
	# Views: nobody on the floor while held.
	var v3: Node = load("res://scripts/world3d/villager_sprites.gd").new("house")
	var v2: Node = load("res://scripts/world/villager_view.gd").new("house")
	root.add_child(v3)
	root.add_child(v2)
	check(not Child.ID in v3.shown() and not Child.ID in v2.shown(), "both views: the crawler is not on the floor while held")
	# The door waits.
	g.maps.place("house", Vector2i(4, 5), Vector2i.DOWN)
	FA.on_action("enter", Vector2i(4, 5), Vector2i.DOWN)
	check(g.maps.id == "house" and g.crawler_held(), "the door waits: still in the farmhouse with the crawler")
	check(said.back() == "Set Sora down first.", "the door rule says why: %s" % said.back())
	# Set down on the free cell in front, turned to the farmer.
	var stand := from
	var face := Vector2i.ZERO
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]:
		if g.crawler_spot_free(stand + d):
			face = d
			break
	check(face != Vector2i.ZERO, "a free cell beside (%s)" % stand)
	g.maps.place("house", stand, face)
	FA.on_action("interact", stand, face)
	var put := _crawler_where(g)
	check(not g.crawler_held() and not g.holding() and thrown.is_empty() and said.back() == "You set Sora down.", "E sets the crawler down, nothing thrown (%s)" % said.back())
	check(put.map == "house" and Vector2i(put.pos.floor()) == stand + face and put.facing == -face and not put.moving, "on the cell in front, turned to the farmer (%s %s)" % [put.pos, put.facing])
	v3.refresh()
	v2.refresh()
	check(Child.ID in v3.shown() and Child.ID in v2.shown() and v2._sprites[Child.ID].position == put.pos * 16 \
			and Vector2(v3._sprites[Child.ID].position.x, v3._sprites[Child.ID].position.z) == put.pos, "both views draw the crawler where set down")
	check(AH.pick(stand, face).use_tool == "Hold", "and the tool button may lift them again")
	# The stay: the plan has them again after it.
	var later := _crawler_where(g, g.day_minutes() + Child.hold_stay() + 1.0)
	check(later.pos != put.pos or later.facing != put.facing, "after the stay the day plan has them again (%s)" % later.pos)
	# Lifted again, facing a wall: back where they were lifted.
	FA.on_action("tool", stand, face)
	check(g.crawler_held(), "lifted again")
	g.maps.place("house", Vector2i(9, 1), Vector2i.UP)
	check(not g.crawler_spot_free(Vector2i(9, 0)), "the wall above (9, 1)")
	FA.on_action("tool", Vector2i(9, 1), Vector2i.UP)
	var back := _crawler_where(g)
	check(not g.crawler_held() and back.pos == put.pos and back.facing == put.facing, "facing the wall: set back down where they were (%s)" % back.pos)
	# The futon: sets the crawler down, no sleep while held.
	FA.on_action("tool", stand, face)
	var day: int = g.day
	g.maps.place("house", Vector2i(1, 3), Vector2i.UP)
	FA.on_action("interact", Vector2i(1, 3), Vector2i.UP)
	check(g.day == day and not g.crawler_held() and g.maps.id == "house", "no sleeping with the crawler in the arms: set down first")
	# A map change while held: the plan's place again.
	g.maps.place("house", stand, face)
	check(g.lift_crawler(stand + face), "lifted for the map change")
	g.go_to_map("farm", Vector2i(4, 4), Vector2i.DOWN)
	check(not g.crawler_held() and Child.carried.is_empty(), "a map change puts the crawler back")
	g.maps.place("house", stand, face)
	check(Vector2i(_crawler_where(g).pos.floor()) == cell, "back at the plan's place (%s)" % _crawler_where(g).pos)
	# The night.
	g.maps.place("house", from, Vector2i.RIGHT)
	check(g.lift_crawler(cell), "lifted at night")
	g.end_day()
	check(not g.crawler_held() and Child.carried.is_empty(), "a new day puts the crawler back")
	# No lifting with something in hand.
	g.hour = 7
	g.minute = 0
	Villagers.reset_day()
	g.maps.place("house", from, Vector2i.RIGHT)
	g.held = "turnip"
	FA.on_action("tool", from, Vector2i.RIGHT)
	check(not g.lift_crawler(cell) and not g.crawler_held() and g.held == "turnip", "no lifting with an item in hand")
	g.held = ""
	v3.queue_free()
	v2.queue_free()
	g.message.disconnect(hear)
	g.thrown.disconnect(fly)
	g.new_game()
	check(Child.carried.is_empty(), "a new game: nobody held")


## Saved while holding the crawler: on load the arms are empty and the crawler at the plan's place.
func _crawler_save() -> void:
	var g: Node = root.get_node("Game")
	_little_home(g, "crawler")
	var w := _crawler_where(g)
	var cell := Vector2i(w.pos.floor())
	g.maps.place("house", cell + Vector2i.LEFT, Vector2i.RIGHT)
	check(g.lift_crawler(cell), "lift the crawler")
	var path := "user://test_child_crawler.json"
	check(SaveGame.write(g, path) == "", "write the save while holding the crawler")
	g.new_game()
	var err := SaveGame.read(g, path)
	check(err == "", "read it (%s)" % err)
	Villagers.reset_day()
	check(not g.crawler_held() and not g.holding() and Child.carried.is_empty(), "loaded: the arms are empty")
	var after := _crawler_where(g)
	check(after.map == "house" and Vector2i(after.pos.floor()) == cell, "and the crawler at the plan's place (%s)" % after.pos)
	SaveGame.restore({path: null, path + SaveGame.BACKUP: null, path + SaveGame.TEMP: null})
	g.new_game()


## The toddler and the child are not lifted: the tool button does the tool's work.
func _crawler_only() -> void:
	var g: Node = root.get_node("Game")
	var FA: GDScript = load("res://scripts/farm_actions.gd")
	var AH: GDScript = load("res://scripts/ui/action_hints.gd")
	for stage in ["toddler", "child"]:
		_little_home(g, stage)
		g.hour = 6
		g.minute = 30
		var w := _crawler_where(g)
		check(w.get("map", "") == "house", "%s in the farmhouse at 6:30 (%s)" % [stage, w.get("map", "")])
		var cell := Vector2i(w.pos.floor())
		g.maps.place("house", cell + Vector2i.LEFT, Vector2i.RIGHT)
		check(g.crawler_at(cell).is_empty() and not g.lift_crawler(cell), "the %s cannot be lifted" % stage)
		FA.on_action("tool", cell + Vector2i.LEFT, Vector2i.RIGHT)
		check(not g.crawler_held() and not g.holding(), "the tool button facing the %s lifts nobody" % stage)
		check(AH.pick(cell + Vector2i.LEFT, Vector2i.RIGHT).use_tool != "Hold", "no Hold hint for the %s" % stage)
	g.new_game()


# --- step 5: the child out with the spouse, festivals, the morning help ---------------

## A day's state with spouse `id` and a child at the child stage, named Sora.
func _kid_state(id: String, weather := "sunny", festival := "", weekday := "mon") -> Dictionary:
	var s := _state("child", weather, 600, festival, weekday)
	s.flags = _married(id, 0)
	s.flags[Child.BORN] = 0
	s.flags[Child.NEWS] = 0
	s.flags[Child.NAME] = "Sora"
	s.flags[Child.STAGE] = "child"
	return s


func _kid_at(hm: String, s: Dictionary) -> Dictionary:
	return Villagers.where(Child.ID, float(DayPlan.minute_of(hm)), s)


func _child_days() -> void:
	check(Child.small_style("long", "child") == "long" and Child.small_style("headband", "child") == "headband"
		and Child.small_style("straw_hat", "child") == "short" and Child.small_style("tenugui", "child") == "short"
		and Child.small_style("long", "toddler") == "bun", "the child grows the long hair out and wears a headband, still no hats")
	var win := Child.with_window("child", "out", "sayo")
	check(win == [DayPlan.minute_of("10:00"), DayPlan.minute_of("20:00")], "out with the spouse 10:00 to 20:00 (%s)" % [win])
	check(Child.with_window("child", "out", "mio")[0] == DayPlan.minute_of("10:30"), "with Mio after the ferry: 10:30")
	check(Child.with_window("child", "festival", "mio") == [DayPlan.minute_of("06:00"), DayPlan.minute_of("20:30")], "a festival: all day together")
	check(Child.with_window("child", "indoors", "sayo").is_empty() and Child.with_window("toddler", "yard", "sayo").is_empty(),
		"no time out on a wet day, nor for the toddler")
	Villagers.reset_day()
	var s := _kid_state("sayo")
	check(Child.plan_name(s) == "out", "a sunny day: out")
	var home: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/animals.json")).dog.home
	var kennel := Vector2(home[0], home[1]) + Vector2(0.5, 0.5)
	var w := _kid_at("06:30", s)
	check(w.map == "house" and w.pos == Villagers.where("sayo", float(DayPlan.minute_of("06:30")), s).pos + Vector2(1, 0), "6:30: beside Sayo at home")
	for hm in ["07:30", "08:20", "09:10"]:
		w = _kid_at(hm, s)
		check(w.map == "farm" and w.pos.distance_to(kennel) <= 2.5, "%s: in the yard with the dog (%s)" % [hm, w.pos])
	w = _kid_at("09:55", s)
	check(w.map == "farm" and w.pos.x > 20.0, "9:55: off across the farm to the gate (%s)" % w.pos)
	var sayo := Villagers.where("sayo", float(DayPlan.minute_of("12:00")), s)
	w = _kid_at("12:00", s)
	check(sayo.map == "store" and w.map == "store" and w.pos == sayo.pos + Child.side_of("sayo", "store") and w.get("with_spouse", false),
		"12:00: at Sayo's side in the store (%s, %s)" % [w.pos, sayo.pos])
	check(w.facing == DayPlan.facing_of(-Child.side_of("sayo", "store")) and not w.moving, "turned to her")
	var talk := Talk.pick(Child.ID, s.merged({"band": 3, "again": false, "day_number": 0, "stage": "child", "map": "store", "time": 720}, true))
	check(talk == "child_sayo", "talking at the store: about helping Sayo (%s)" % talk)
	w = _kid_at("18:00", s)
	sayo = Villagers.where("sayo", float(DayPlan.minute_of("18:00")), s)
	check(w.map == "house" and sayo.map == "house" and w.pos == sayo.pos + Vector2(1, 0), "home with Sayo in the evening")
	check(_kid_at("20:30", s).map == DayPlan.AWAY and _kid_at("03:00", s).map == DayPlan.AWAY, "in bed from 20:00")
	# Wet days: in the house, even while the spouse works.
	for wet in ["rain", "storm", "snow"]:
		var ws := _kid_state("sayo", wet)
		Villagers.reset_day()
		check(Child.plan_name(ws) == "indoors" and _kid_at("12:00", ws).map == "house" and _kid_at("08:00", ws).map == "house", "%s: the child stays in" % wet)
	# Every spouse: with them from the time out on, on free floor wherever they stand, home together.
	for id in Marriage.candidates():
		for day in [["mon", ""], ["sun", ""], ["mon", "blossom_day"], ["mon", "lantern_night"], ["mon", "moon_night"], ["mon", "years_turn"]]:
			var ks := _kid_state(id, "sunny", day[1], day[0])
			Villagers.reset_day()
			var plan := Child.plan_name(ks)
			check(plan == ("festival" if day[1] != "" else "out"), "%s %s: the plan %s" % [id, day, plan])
			var span := Child.with_window("child", plan, id)
			var bad := []
			var maps := {}
			for m in range(int(span[0]), int(span[1]), 5):
				var kid := Villagers.where(Child.ID, float(m), ks)
				var sp := Villagers.where(id, float(m), ks)
				if sp.map == DayPlan.AWAY:
					continue
				if kid.map != sp.map or kid.pos.distance_to(sp.pos) > 1.01:
					bad.append("%d: not by them (%s %s / %s %s)" % [m, kid.map, kid.pos, sp.map, sp.pos])
					continue
				maps[kid.map] = true
				if kid.moving or kid.map == "farm":
					continue
				var md: MapData = MapManager.load_map(kid.map, ["room"], {})[1]
				var c := Vector2i(kid.pos.floor())
				if md == null or not md.in_bounds(c) or md.is_solid(c) or not md.door_at(c).is_empty() or md.prop_at(c).get("kind", "") == "counter":
					bad.append("%d: %s %s" % [m, kid.map, c])
			check(bad.is_empty(), "%s %s: at their side on free floor %s" % [id, day, bad.slice(0, 4)])
			check(day[1] != "" or day[0] == "sun" or maps.size() >= 2, "%s: out to their work and home again %s" % [id, maps.keys()])
			check(Villagers.where(Child.ID, float(DayPlan.minute_of("19:50")), ks).map in ["house", DayPlan.AWAY] or day[1] != "",
				"%s %s: home by the evening" % [id, day])
	# A festival: together all day, at the festival with them.
	var fs := _kid_state("sayo", "sunny", "blossom_day")
	Villagers.reset_day()
	sayo = Villagers.where("sayo", float(DayPlan.minute_of("13:30")), fs)
	w = _kid_at("13:30", fs)
	check(w.map == sayo.map and sayo.map == "town", "Blossom Day 13:30: in the village with Sayo (%s)" % w.map)
	check(Talk.pick(Child.ID, fs.merged({"band": 3, "again": false, "day_number": 0, "stage": "child", "map": "town", "time": 810}, true)).begins_with("child_festival_"),
		"talking on the festival: the festival lines")
	Villagers.reset_day()


func _child_help_rules() -> void:
	var farm := FarmGrid.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json")))
	var weeds := func() -> int:
		var n := 0
		for i in farm.cells.size():
			if farm.cells[i].obj == FarmGrid.Obj.WEED and farm.can_farm(Vector2i(i % FarmGrid.W, i / FarmGrid.W)):
				n += 1
		return n
	for c in [Vector2i(6, 10), Vector2i(7, 10), Vector2i(8, 11)]:
		farm.cell(c).obj = FarmGrid.Obj.WEED
	var before: int = weeds.call()
	check(before >= 3, "a field with weeds (%d)" % before)
	var f: Dictionary = _kid_state("sayo").flags
	var most := int(Child.data().help.weeds)
	check(most == 2 and int(Child.data().help.band) == 5, "two weeds from band 5")
	check(Child.help(f, farm, 4, "sunny") == 0 and weeds.call() == before, "band 4: no help")
	check(Child.help(f, farm, 5, "rain") == 0 and Child.help(f, farm, 6, "snow") == 0 and Child.help(f, farm, 6, "storm") == 0, "wet days: no help")
	f[Child.STAGE] = "toddler"
	check(Child.help(f, farm, 6, "sunny") == 0, "a toddler doesn't weed yet")
	f[Child.STAGE] = "child"
	check(not f.has(Child.HELP_WEEDS), "no flag without help")
	check(Child.help(f, farm, 5, "sunny") == most and weeds.call() == before - most and f.get(Child.HELP_WEEDS, false), "band 5, sunny: two weeds pulled, flagged")
	var wet := 0
	for d in farm.cells:
		wet += 1 if d.wet else 0
	check(wet == 0, "the child only weeds; the watering is the spouse's")
	check(Child.help_text(2, "Sora") == "Sora pulled up 2 weeds in the field this morning.", "the message: %s" % Child.help_text(2, "Sora"))
	check(Child.help_text(1, "Sora") == "Sora pulled up a weed in the field this morning." and Child.help_text(0, "Sora") == "", "one weed, and none")
	var lone := FarmGrid.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json")))
	for i in lone.cells.size():
		lone.cells[i].obj = FarmGrid.Obj.NONE
	lone.cell(Vector2i(6, 10)).obj = FarmGrid.Obj.WEED
	check(Child.help(f, lone, 6, "sunny") == 1 and lone.pull_weeds(2) == 0, "one weed left: one pulled, then none")
	check(Child.help(f, lone, 6, "sunny") == 0 and not f.has(Child.HELP_WEEDS), "nothing to pull: no flag")
	for k in ["Sora pulled up a weed in the field this morning.", "Sora pulled up 2 weeds in the field this morning."]:
		Lang.set_language("th")
		var t := Lang.t(k)
		Lang.set_language("en")
		check(t != k and not "%" in t, "the help message in Thai: %s" % t)


func _child_help_in_game() -> void:
	var g: Node = root.get_node("Game")
	_little_home(g, "child")
	var messages := []
	var note := func(t: String) -> void: messages.append(t)
	g.message.connect(note)
	for c in [Vector2i(6, 10), Vector2i(7, 10), Vector2i(8, 11)]:
		g.farm.cell(c).obj = FarmGrid.Obj.WEED
	g.affection.points[Child.ID] = int(Affection.rules().bands[5])
	g.weather_tomorrow = "sunny"
	g.end_day()
	check(g.weather_today == "sunny" and g.child_help_news == "Sora pulled up 2 weeds in the field this morning.", "a sunny morning at band 5: the news waits (%s)" % g.child_help_news)
	check(g.flags.get(Child.HELP_WEEDS, false), "the flag for the day")
	g.go_to_spawn("farm", "home")
	messages.clear()
	g.map_arrived()
	var told: String = messages.back() if not messages.is_empty() else ""
	check("Sora pulled up 2 weeds" in told and (g.help_news == "") and g.child_help_news == "", "told on stepping out (%s)" % told)
	var spouse_at := told.find("Sayo")
	check(spouse_at < 0 or spouse_at < told.find("Sora"), "after the spouse's line (%s)" % told)
	var said := []
	var hear := func(id: String, at: String) -> void: said.append([id, at])
	g.dialogue_requested.connect(hear)
	g.hour = 8
	g.talk_to(Child.ID, Vector2i.DOWN)
	check(not said.is_empty() and said.back() == ["talk_child", "child_helped"], "talking that morning: the weeds %s" % [said])
	g.dialogue_requested.disconnect(hear)
	# Band 4 the next morning: no help.
	g.affection.points[Child.ID] = int(Affection.rules().bands[4])
	g.weather_tomorrow = "sunny"
	g.end_day()
	check(g.child_help_news == "" and not g.flags.has(Child.HELP_WEEDS), "band 4: no help")
	g.message.disconnect(note)
	g.new_game()


## Both views draw the child at Sayo's side in the store at noon.
func _child_views() -> void:
	var g: Node = root.get_node("Game")
	_little_home(g, "child")
	g.hour = 12
	var v3: Node = load("res://scripts/world3d/villager_sprites.gd").new("store")
	var v2: Node = load("res://scripts/world/villager_view.gd").new("store")
	root.add_child(v3)
	root.add_child(v2)
	check(Child.ID in v3.shown() and Child.ID in v2.shown() and "sayo" in v3.shown(), "noon: the child with Sayo in the store in both views")
	if Child.ID in v3.shown() and Child.ID in v2.shown():
		var key := str(v3._sprites[Child.ID].get_meta("key"))
		check(key.begins_with("child:figure:child:") and v2._sprites[Child.ID].get_meta("key") == key, "in the child build in both (%s)" % key)
	v3.queue_free()
	v2.queue_free()
	g.new_game()
