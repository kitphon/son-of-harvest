extends SceneTree
## Headless checks for the child's rules (data/child.json, Child): the data, the news and the
## birth (30 + 30 days, band 6, festival days), the stage by days since the birth, the look
## from the parents, each spouse's three names, the child's hearts (start and floor at band 3),
## the save, and the two scenes: the morning flags (Child.day_start, from Game.end_day), the
## trigger rows in the farmhouse, every spouse's news and birth events and lines (English and
## Thai), the name picked from the three and stored by the event's child step; the baby's
## cradle (step 3): the stage flag, the cradle prop only while the baby stage holds, the lines
## by the clock, lifting the baby and laying them back, no throw, the door rule, the save while
## holding, the art and both views' pictures. Run:
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


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_save()
		_morning()
		_play_birth()
		_baby_in_arms()
		_baby_save()
		_little_talk()
		_little_gifts()
		_little_views()
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
	# The child stage has no plans of its own yet: the toddler's.
	check(Child.plan_name(_state("child")) == "yard" and at.call(11 * 60, _state("child")).map == "farm", "the child stage keeps the toddler's days for now")
	check(Villagers.sprite_key((at.call(11 * 60, _state("child")) as Dictionary).merged({"id": Child.ID})).begins_with("child:figure:child:"), "drawn in the child build")
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
				check(key.begins_with("child:figure:%s:bun:" % Child.figure(st).build), "the key names the build and the small style: %s" % key)
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
