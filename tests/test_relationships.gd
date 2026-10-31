extends SceneTree
## Headless checks for relationships: the heart band on the text box's name tag, birthdays
## (villager files, the calendar, gifts counting x5, the birthday lines), the small nightly
## loss for villagers left alone, the heart events (one per villager at band 3 and one at band
## 5), birthday day plans, fair weather and the HUD tag on a birthday, mine finds as gifts. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_relationships.gd

var failures := 0
var _frame := 0


func _init() -> void:
	_heart_art()
	_birthday_data()
	_birthday_gifts()
	_neglect()
	_heart_event_rows()
	_birthday_plans()
	_mine_gifts()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_hearts_in_text_box()
		_birthday_talk()
		_neglect_in_game()
		_heart_events_play()
		_birthday_weather()
		_birthday_tag()
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
	var maps := {"tome": ["town", "tome_house"], "kota": ["town", "kota_house"],
		"sayo": ["town", "store", "sayo_house"], "hachiro": ["town", "smithy"]}
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
			# The second one at band 5, only after the first was seen.
			var after := {"heart_" + id: true, "store_intro": true, "smithy_intro": true}
			var five := "heart_%s_5" % id
			check(t.pick("talk", s.merged({"hearts": {id: 5}, "seen": after}, true)) == five, "on %s, band 5 plays %s" % [m, five])
			check(t.pick("talk", s.merged({"hearts": {id: 6}, "seen": after}, true)) == five, "on %s, still at band 6 if missed" % m)
			check(t.pick("talk", s.merged({"hearts": {id: 4}, "seen": after}, true)) != five, "on %s, not at band 4" % m)
			check(t.pick("talk", s.merged({"hearts": {id: 5}}, true)) == "heart_" + id, "on %s, band 3's comes first" % m)
			check(not t.pick("talk", s.merged({"hearts": {id: 6}, "seen": after.merged({five: true})}, true)) in ["heart_" + id, five],
				"on %s, each plays once" % m)


## Each villager has a birthday plan, picked on their birthday (Sayo's Sunday off still wins),
## not the day after or on someone else's, and differing from their usual day.
func _birthday_plans() -> void:
	check(Villagers.check_conditions({"birthday": true}) == "" and Villagers.check_conditions({"birthday": "yes"}) != "", "birthday is a rule condition, true or false")
	for id in Villagers.all():
		var v: Dictionary = Villagers.all()[id]
		var b: Dictionary = v.birthday
		check(v.plans.has("birthday"), "%s has a birthday plan" % id)
		var s := {"year": 1, "season": b.season, "day": int(b.day), "weekday": "wed", "weather": "sunny", "flags": {}, "festival": ""}
		check(Villagers.pick_plan(v, s) == "birthday", "%s follows it on the day" % id)
		check(Villagers.pick_plan(v, s.merged({"day": int(b.day) % 30 + 1}, true)) != "birthday", "%s doesn't the day after" % id)
		check(v.plans.birthday != v.plans[v.default], "%s's birthday isn't a usual day" % id)
		var other := "kota" if id != "kota" else "tome"
		var bo: Dictionary = Villagers.all()[other].birthday
		check(Villagers.pick_plan(v, s.merged({"season": bo.season, "day": int(bo.day)}, true)) != "birthday", "%s keeps to their day on %s's birthday" % [id, other])
	var sayo: Dictionary = Villagers.all().sayo
	var sb: Dictionary = sayo.birthday
	check(Villagers.pick_plan(sayo, {"year": 1, "season": sb.season, "day": int(sb.day), "weekday": "sun", "weather": "sunny", "flags": {}, "festival": ""}) == "day_off",
		"a Sunday birthday is Sayo's day off (the store is shut anyway)")
	# On their birthdays the keepers leave the counter early, so the shop shuts.
	var h: Dictionary = Villagers.all().hachiro.birthday
	var st := {"year": 1, "season": h.season, "day": int(h.day), "weekday": "wed", "weather": "sunny", "flags": {}, "festival": ""}
	Villagers.reset_day()
	check(not Villagers.is_on("hachiro", "smithy", 12 * 60, st) and Villagers.where("hachiro", 12 * 60, st).map == "town", "Hachiro is out of the smithy at noon on his birthday")
	st = st.merged({"season": sb.season, "day": int(sb.day)}, true)
	check(Villagers.is_on("sayo", "store", 10 * 60, st) and Villagers.where("sayo", 13 * 60 + 20, st).map == "tome_house",
		"Sayo keeps the store in the morning and lunches at Tome's on her birthday")
	check(Villagers.where("tome", 13 * 60 + 20, st).map == "tome_house", "and Tome is home then")
	Villagers.reset_day()


## Mine finds in the gift lists are real finds (data/mine.json); each villager likes some.
func _mine_gifts() -> void:
	var finds: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/mine.json")).items
	for id in Villagers.all():
		var any_good := false
		for r in Villagers.all()[id].gifts:
			for item in Villagers.all()[id].gifts[r]:
				if item.begins_with("mine:"):
					check(finds.has(item.trim_prefix("mine:")), "%s's %s %s is a mine find" % [id, r, item])
					any_good = any_good or r in ["love", "like"]
		check(any_good, "%s likes something from the mine" % id)
	check(Villagers.reaction("hachiro", "mine:hoshigane") == "love" and Villagers.reaction("hachiro", "mine:stone") == "dislike", "Hachiro loves good ore, not a grey stone")
	check(Villagers.reaction("kota", "mine:suisho") == "love", "Kota loves a crystal")


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


## Each heart event (bands 3 and 5) runs to the end on the real Game: flag set, affection up.
## Kota's second one reads both ways, with and without his carp promise.
func _heart_events_play() -> void:
	for id in Villagers.all():
		for band in [3, 5]:
			for promise in ([false, true] if id == "kota" and band == 5 else [false]):
				var ev: String = "heart_" + id + ("_5" if band == 5 else "")
				var g := _game()
				g.affection.add(id, int(Affection.rules().bands[band]))
				if promise:
					g.flags["kota_carp_promise"] = true
				var before: int = g.affection.of(id)
				var r := EventRunner.open(ev, g)
				check(r.error == "", "%s runs: %s" % [ev, r.error])
				if r.error != "":
					continue
				r.start(Vector2.ZERO, Vector2i.UP)
				for i in 200:
					if r.done():
						break
					r.update(0.5)
				check(r.done(), "%s ends" % ev)
				check(EventRunner.is_set(g.flags, ev), "%s sets its flag" % ev)
				check(g.affection.of(id) > before, "%s likes the farmer more after %s" % [id, ev])
	var d := DialogueRunner.open("heart_events_5", {"kota_carp_promise": true}, "kota")
	_next_line(d)
	check("You promised" in d.text(), "with the promise Kota keeps it too: %s" % d.text())
	d = DialogueRunner.open("heart_events_5", {}, "kota")
	_next_line(d)
	check("didn't" in d.text(), "without it he let the carp be anyway: %s" % d.text())


func _next_line(d: DialogueRunner) -> void:
	if not d.revealed():
		d.press()
	d.press()


## The day before a villager's birthday the next day's weather is always fair (DESIGN), even
## when the season's odds say rain; other days roll as usual.
func _birthday_weather() -> void:
	var g := _game()
	var odds: Dictionary = g.weather_chances
	g.weather_chances = {}
	for s in g.SEASONS:
		g.weather_chances[s] = {"rain": 1.0}
	for id in Villagers.all():
		var b: Dictionary = Villagers.all()[id].birthday
		var at: int = g.SEASONS.find(b.season) * g.DAYS_PER_SEASON + int(b.day) - 1 - 2   # two days before
		at = posmod(at, 4 * g.DAYS_PER_SEASON)
		g.season = at / g.DAYS_PER_SEASON
		g.day = at % g.DAYS_PER_SEASON + 1
		g.end_day()
		check(g.fair_tomorrow() and g.weather_tomorrow == "sunny", "the day before %s's birthday, tomorrow is fair (%s)" % [id, g.weather_tomorrow])
		g.end_day()
		check(g.season_name() == b.season and g.day == int(b.day), "%s: the day is %s %d" % [id, b.season, b.day])
		check(g.birthdays_today() == [id], "Game.birthdays_today is %s" % [g.birthdays_today()])
		check(g.weather_today == "sunny", "%s's birthday is fair (%s)" % [id, g.weather_today])
		check(not g.fair_tomorrow() and g.weather_tomorrow == "rain", "the day after rolls as usual (%s)" % g.weather_tomorrow)
	g.weather_chances = odds
	g.new_game()


## The HUD tag under the clock names a birthday as it names a festival; it fits the box.
func _birthday_tag() -> void:
	check(HudLayout.day_tag([]) == "" and HudLayout.day_tag(["tome"]) == "Tome's birthday", "the tag reads Tome's birthday")
	for id in Villagers.all():
		var tag := HudLayout.day_tag([id])
		check(PixelFont.width(tag) + 12 <= HudLayout.BOXES.festival.size.x, "%s fits the HUD tag" % tag)
	var g := _game()
	var hud: CanvasLayer = load("res://scripts/ui/hud.gd").new()
	root.add_child(hud)
	var b: Dictionary = Villagers.all().sayo.birthday
	g.season = g.SEASONS.find(b.season)
	g.day = int(b.day)
	g.changed.emit()
	check(hud._fest_box.visible and hud._fest.text == "Sayo's birthday", "on Sayo's birthday the HUD says so (%s)" % hud._fest.text)
	g.day = int(b.day) + 1
	g.changed.emit()
	check(not hud._fest_box.visible, "and not the day after")
	hud.free()


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
