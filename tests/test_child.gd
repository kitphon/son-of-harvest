extends SceneTree
## Headless checks for the child's rules (data/child.json, Child): the data, the news and the
## birth (30 + 30 days, band 6, festival days), the stage by days since the birth, the look
## from the parents, each spouse's three names, the child's hearts (start and floor at band 3)
## and the save. Run:
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


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_save()
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
	check(Child.names("sayo") == ["Hinata", "Sora", "Aoi"], "Sayo's three")
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
