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


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_save()
		_morning()
		_play_birth()
		_baby_in_arms()
		_baby_save()
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
