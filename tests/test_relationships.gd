extends SceneTree
## Headless checks for relationships: the heart band on the text box's name tag, birthdays
## (villager files, the calendar, gifts counting x5, the birthday lines), the small nightly
## loss for villagers left alone, and the heart events (one per villager at band 3). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_relationships.gd

var failures := 0
var _frame := 0


func _init() -> void:
	_heart_art()
	_birthday_data()
	_birthday_gifts()
	_neglect()
	_heart_event_rows()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_hearts_in_text_box()
		_birthday_talk()
		_neglect_in_game()
		_heart_events_play()
		print("test_relationships: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


# --- pure logic and data ----------------------------------------------------

## One heart colour per band, each heart drawn differently, the name tag wide enough for it.
func _heart_art() -> void:
	var colors: Array = DialogueRunner.settings().get("hearts", [])
	check(colors.size() == Affection.rules().bands.size(), "a heart colour for every band (%d)" % colors.size())
	var seen := {}
	for b in colors.size():
		var img := PlaceholderArt.tex("ui:heart:%d" % b).get_image()
		check(img.get_width() == 9 and img.get_height() == 8, "heart %d is 9 x 8" % b)
		seen[img.get_data()] = true
	check(seen.size() == colors.size(), "every band's heart looks different")
	var widest := 0
	for id in Villagers.all():
		widest = maxi(widest, PixelFont.width(DialogueRunner.speakers()[id].name))
	check(TextBoxLayout.TEXT_POS.x - 6 + widest + 12 + TextBoxLayout.HEART_W < TextBoxLayout.BOX.size.x, "the longest name and its heart fit over the box")


## Every villager has a birthday on a day of their own, not on a festival, and the calendar
## names them on that day.
func _birthday_data() -> void:
	var taken := {}
	var calendar := FileAccess.get_file_as_string("res://data/dialogue/examine_house.json")
	for id in Villagers.all():
		var b: Dictionary = Villagers.all()[id].get("birthday", {})
		check(not b.is_empty(), "%s has a birthday" % id)
		if b.is_empty():
			continue
		var key := "%s %d" % [b.season, b.day]
		check(not taken.has(key), "%s's birthday %s is nobody else's" % [id, key])
		taken[key] = true
		check(Festivals.on_date(b.season, int(b.day)) == "", "%s's birthday isn't a festival" % id)
		check(Villagers.has_birthday(id, b.season, int(b.day)) and not Villagers.has_birthday(id, b.season, int(b.day) % 30 + 1),
			"has_birthday knows %s's day" % id)
		check(Villagers.birthdays_on(b.season, int(b.day)) == [id], "birthdays_on(%s) is %s" % [key, id])
		var line := DialogueRunner.open("examine_house", {}, b.season + "_birthday")
		check(line.error == "" and Villagers.all()[id].name in line.text() and ("%dth" % b.day in line.text() or "%dst" % b.day in line.text()),
			"the %s calendar marks %s on the %d: %s" % [b.season, id, b.day, line.text()])
		check(Talk.has_line(id, "birthday") and Talk.has_line(id, "gift_birthday"), "%s has birthday lines" % id)
	check(calendar.count("_birthday\"") >= 4, "every season's calendar has a birthday part")
	var v: Dictionary = Villagers.all()["tome"].duplicate(true)
	for bad in [{"season": "spring"}, {"season": "monsoon", "day": 3}, {"season": "fall", "day": 31}, {"season": "fall", "day": 2.5}, "fall 24"]:
		v.birthday = bad
		check(Villagers.check(v) != "", "refused birthday %s" % [bad])
	check(Talk._check_if({"birthday": "yes"}) != "", "a birthday pick is true or false")
	check(Talk.holds({"birthday": true}, {"birthday": true, "season": "fall", "weekday": "mon", "weather": "sunny", "day": 1, "year": 1, "flags": {}, "time": 600, "band": 0, "again": false}),
		"a birthday pick holds on the day")


## On a birthday a gift counts birthday_times over, good or bad; one gift a day still.
func _birthday_gifts() -> void:
	var r := Affection.rules()
	var times := int(r.birthday_times)
	check(times == 5, "birthday gifts count x5 (DESIGN)")
	var a := Affection.new()
	var g := a.give("tome", "eggplant", 10, true)
	check(g.ok and g.reaction == "love" and a.of("tome") == int(r.gift.love) * times, "a loved birthday gift: %d" % a.of("tome"))
	check(not a.give("tome", "turnip", 10, true).ok, "still one gift a day")
	a.add("kota", 100)
	a.give("kota", "carrot", 10, true)
	check(_change("kota", "carrot") < 0 and a.of("kota") == 100 + _change("kota", "carrot") * times,
		"a bad birthday gift hurts x5 too (%d)" % a.of("kota"))
	var plain := Affection.new()
	plain.give("tome", "eggplant", 10)
	check(plain.of("tome") == int(r.gift.love), "on other days it counts once")


func _change(id: String, item: String) -> int:
	return int(Affection.rules().gift.get(Villagers.reaction(id, item), 0))


## A met villager nobody talked to or gave to may lose a little in the night; one who was
## talked to, given something, or never met doesn't.
func _neglect() -> void:
	var n: Dictionary = Affection.rules().neglect
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var a := Affection.new()
	a.add("tome", 200)
	a.add("kota", 200)
	a.add("sayo", 200)
	var nights := 400
	for d in nights:
		a.talk("kota", d)
		a.give("sayo", "turnip", d)
		a.day_end(d, rng)
	var lost := 200 - a.of("tome")
	check(a.of("kota") == Affection.max_points(), "a daily talk is never lost")
	check(a.of("sayo") >= 200, "a daily gift is never lost")
	check(a.of("hachiro") == 0, "a villager never met stays where they are")
	var expect := nights * float(n.chance) * int(n.loss)
	check(lost > expect * 0.5 and lost < expect * 1.5, "left alone, Tome loses about %d in %d nights (lost %d)" % [int(expect), nights, lost])
	check(int(n.loss) <= 1 and float(n.chance) <= 0.25, "the loss is small")
	var low := Affection.new()
	low.add("tome", 1)
	for d in 200:
		low.day_end(d, rng)
	check(low.of("tome") == 0, "it stops at 0")


## Every villager has a heart event at band 3: a talk row in each map's table where they can
## be talked to, played once.
func _heart_event_rows() -> void:
	var maps := {"tome": ["town"], "kota": ["town"], "sayo": ["town", "store"], "hachiro": ["town", "smithy"]}
	for id in Villagers.all():
		check(maps.has(id), "%s has a heart event" % id)
		for m in maps.get(id, []):
			var t := EventTriggers.open(m)
			check(t.error == "", "triggers_%s: %s" % [m, t.error])
			var s := {"year": 1, "season": "spring", "day": 3, "weekday": "wed", "time": 600, "weather": "sunny",
				"flags": {"met_sayo": true, "met_hachiro": true}, "seen": {"store_intro": true, "smithy_intro": true},
				"cell": Vector2i.ZERO, "who": id, "hearts": {id: 3}}
			check(t.pick("talk", s) == "heart_" + id, "on %s, talking to %s at band 3 plays heart_%s" % [m, id, id])
			check(t.pick("talk", s.merged({"hearts": {id: 2}}, true)) != "heart_" + id, "on %s, not at band 2" % m)
			check(t.pick("talk", s.merged({"hearts": {id: 6}}, true)) == "heart_" + id, "on %s, still at band 6 if missed" % m)
			check(t.pick("talk", s.merged({"seen": {"heart_" + id: true, "store_intro": true, "smithy_intro": true}}, true)) != "heart_" + id,
				"on %s, only once" % m)


# --- on the real Game -------------------------------------------------------

func _game() -> Node:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.events_seen = {"first_morning": true, "rainy_day": true}
	return g


## The name tag shows a heart in the villager's band colour; the farmer and narration get none.
func _hearts_in_text_box() -> void:
	var g := _game()
	check(g.heart_band("farmer") == -1 and g.heart_band("") == -1 and g.heart_band("tsuru") == -1, "only villagers have a heart")
	check(g.heart_band("tome") == 0, "a stranger is band 0")
	g.affection.add("tome", int(Affection.rules().bands[3]))
	check(g.heart_band("tome") == 3, "the band follows Game.affection")
	var tb: CanvasLayer = load("res://scripts/ui/text_box.gd").new()   # loaded late: it uses the Game autoload
	root.add_child(tb)
	tb.open("talk_tome", "new_1")
	check(tb._heart.visible and tb._heart.texture == PlaceholderArt.tex("ui:heart:3"), "Tome's line shows her band 3 heart")
	var tag_w: float = tb._name_tag.size.x
	check(tb._heart.position.x + 9 <= tag_w - 3 and tb._heart.position.x >= tb._name.position.x + PixelFont.width("Tome"), "the heart sits after her name, inside the tag")
	tb.open("examine_house", "spring")
	check(not tb._heart.visible, "narration shows no heart")
	tb.open("examine_house", "radio")
	check(not tb._heart.visible, "nor does the farmer")
	tb.open("talk_kota", "new_1")
	check(tb._heart.visible and tb._heart.texture == PlaceholderArt.tex("ui:heart:0"), "Kota, not met yet, shows an empty heart")
	tb._close()
	tb.free()


## On Tome's birthday she says her birthday line, and a gift gets her birthday answer x5.
func _birthday_talk() -> void:
	var g := _game()
	var said := []
	g.dialogue_requested.connect(func(id, at): said.append([id, at]))
	var b: Dictionary = Villagers.all().tome.birthday
	g.season = g.SEASONS.find(b.season)
	g.day = int(b.day)
	g.weather_today = "sunny"
	g.hour = 9
	g.talk_to("tome", Vector2i.DOWN)
	check(said.back() == ["talk_tome", "birthday"], "on her birthday Tome says so %s" % [said])
	g.held = "eggplant"
	check(g.talk_to("tome", Vector2i.DOWN) == "gift" and said.back() == ["talk_tome", "gift_birthday"], "a birthday gift gets her birthday answer %s" % [said.back()])
	check(g.affection.of("tome") == int(Affection.rules().talk) + int(Affection.rules().gift.love) * 5, "and counts x5 (%d)" % g.affection.of("tome"))
	g.day = int(b.day) % 30 + 1
	g.held = "medicine"
	g.talk_to("tome", Vector2i.DOWN)
	check(said.back() == ["talk_tome", "gift_hate"], "the next day a hated gift answers as usual")
	var b2: Dictionary = Villagers.all().kota.birthday
	g.season = g.SEASONS.find(b2.season)
	g.day = int(b2.day)
	g.held = "carrot"
	g.talk_to("kota", Vector2i.DOWN)
	check(said.back() == ["talk_kota", "gift_hate"], "a hated birthday gift isn't thanked %s" % [said.back()])


## Game.end_day runs the nightly loss, before the date moves (a talk that day keeps it).
func _neglect_in_game() -> void:
	var g := _game()
	g.rng.seed = 11
	g.affection.add("tome", 120)
	g.affection.add("kota", 120)
	for i in 120:
		g.affection.talk("kota", g.day_number())
		g.end_day()
	check(g.affection.of("tome") < 120, "left alone a season and more, Tome likes the farmer a little less (%d)" % g.affection.of("tome"))
	check(g.affection.of("tome") > 120 - 40, "but only a little")
	check(g.affection.of("kota") > 120, "Kota, talked to every day, lost nothing")


## Each heart event runs to the end on the real Game: flag set, affection up.
func _heart_events_play() -> void:
	for id in Villagers.all():
		var g := _game()
		g.affection.add(id, int(Affection.rules().bands[3]))
		var before: int = g.affection.of(id)
		var r := EventRunner.open("heart_" + id, g)
		check(r.error == "", "heart_%s runs: %s" % [id, r.error])
		if r.error != "":
			continue
		r.start(Vector2.ZERO, Vector2i.UP)
		for i in 200:
			if r.done():
				break
			r.update(0.5)
		check(r.done(), "heart_%s ends" % id)
		check(EventRunner.is_set(g.flags, "heart_" + id), "heart_%s sets its flag" % id)
		check(g.affection.of(id) > before, "%s likes the farmer more after it" % id)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
