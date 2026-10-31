extends SceneTree
## Headless checks for relationships: the heart band on the text box's name tag, birthdays
## (villager files, the calendar, gifts counting x5, the birthday lines), the small nightly
## loss for villagers left alone, the heart events (one per villager at bands 3, 5 and 6, and
## the band 6 talk lines), birthday day plans, fair weather and the HUD tag on a birthday, mine finds and cooked dishes as
## gifts. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_relationships.gd

var failures := 0
var _frame := 0


func _init() -> void:
	_heart_art()
	_birthday_data()
	_birthday_gifts()
	_neglect()
	_heart_event_rows()
	_band6_talk()
	_birthday_plans()
	_mine_gifts()
	_dish_gifts()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_hearts_in_text_box()
		_birthday_talk()
		_dish_gift_in_game()
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
## be talked to, played once; then one at band 5 and one at band 6, each after the last.
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
			# The third one at band 6 only, only after the one at 5 was seen, and once.
			var six := "heart_%s_6" % id
			var after5 := after.merged({five: true})
			check(t.pick("talk", s.merged({"hearts": {id: 6}, "seen": after5}, true)) == six, "on %s, band 6 plays %s" % [m, six])
			check(t.pick("talk", s.merged({"hearts": {id: 5}, "seen": after5}, true)) != six, "on %s, not at band 5" % m)
			check(t.pick("talk", s.merged({"hearts": {id: 6}, "seen": after}, true)) == five, "on %s, band 5's comes before %s" % [m, six])
			check(not t.pick("talk", s.merged({"hearts": {id: 6}, "seen": after5.merged({six: true})}, true)) in ["heart_" + id, five, six],
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


## Dishes in the gift lists are real foods; every villager loves a cooked dish and dislikes
## another, and every cooked dish (a food with a sell, from the kitchen) is welcome somewhere.
func _dish_gifts() -> void:
	var foods: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json")).foods
	var welcome := {}
	for id in Villagers.all():
		var loves := 0
		var dislikes := 0
		for r in Villagers.all()[id].gifts:
			for item in Villagers.all()[id].gifts[r]:
				if not item.begins_with("food:"):
					continue
				var f: Dictionary = foods.get(item.trim_prefix("food:"), {})
				check(not f.is_empty(), "%s's %s %s is a food" % [id, r, item])
				if f.get("shop", true) or int(f.get("sell", 0)) <= 0:
					continue
				loves += 1 if r == "love" else 0
				dislikes += 1 if r in ["dislike", "hate"] else 0
				if r in ["love", "like"]:
					welcome[item] = true
		check(loves > 0 and dislikes > 0, "%s loves a dish and dislikes one (%d, %d)" % [id, loves, dislikes])
	for f in foods:
		if not foods[f].get("shop", true) and int(foods[f].get("sell", 0)) > 0:
			check(welcome.has("food:" + f), "someone likes %s" % f)
	check(Villagers.reaction("tome", "food:furofuki_daikon") == "love" and Villagers.reaction("tome", "food:milk_pudding") == "dislike", "Tome: old-style simmering, no milk pudding")
	check(Villagers.reaction("hachiro", "food:grilled_fish") == "love" and Villagers.reaction("hachiro", "food:kinako_mochi") == "dislike", "Hachiro: fish, no sweets")
	check(Villagers.reaction("kota", "food:milk_pudding") == "love" and Villagers.reaction("sayo", "food:tamagoyaki") == "love", "Kota and Sayo love egg and milk dishes")
	check(Villagers.reaction("sayo", "food:miso_soup") == "neutral", "an unlisted dish is neutral")
	var a := Affection.new()
	var g := a.give("hachiro", "food:daikon_fish", 3, true)
	check(g.ok and g.reaction == "love" and g.change == int(Affection.rules().gift.love) * int(Affection.rules().birthday_times), "a loved dish counts x5 on a birthday too")


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


## A dish carried overhead (cooked dishes come several to a stack) is a gift: one of the
## stack goes, on a birthday x5 with the birthday answer; a disliked dish answers as it is.
func _dish_gift_in_game() -> void:
	var g := _game()
	var said := []
	g.dialogue_requested.connect(func(id, at): said.append([id, at]))
	var b: Dictionary = Villagers.all().hachiro.birthday
	g.season = g.SEASONS.find(b.season)
	g.day = int(b.day)
	g.weather_today = "sunny"
	g.hour = 9
	g.inventory.slots.hand[0] = {"id": "food:grilled_fish", "n": 2}
	check(g.talk_to("hachiro", Vector2i.DOWN) == "gift" and said.back() == ["talk_hachiro", "gift_birthday"], "grilled fish on his birthday %s" % [said.back()])
	check(g.affection.of("hachiro") == int(Affection.rules().gift.love) * int(Affection.rules().birthday_times), "counts x5 (%d)" % g.affection.of("hachiro"))
	check(g.held == "food:grilled_fish" and g.inventory.count("food:grilled_fish", ["hand"]) == 1, "one of the two is given, one stays overhead")
	g.day = int(b.day) % 30 + 1
	g.talk_to("sayo", Vector2i.DOWN)
	check(said.back() == ["talk_sayo", "gift_dislike"] and not g.holding(), "Sayo takes the fish dish, without joy %s" % [said.back()])
	check(g.affection.of("sayo") == maxi(int(Affection.rules().gift.dislike), 0), "and likes the farmer no more for it")


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


## Each heart event (bands 3, 5 and 6) runs to the end on the real Game: flag set, affection
## up, and band 6's own story flag. Kota's second and third read both ways, with and without
## his carp promise; band 6 also with and without the band 5 flags its lines look back on.
const SIX_FLAGS := {"tome": "", "kota": "kota_streamer", "sayo": "sayo_ledger", "hachiro": "hachiro_strike"}
const FIVE_FLAGS := {"tome": "tome_grandma", "kota": "kota_carp_promise", "sayo": "sayo_sign", "hachiro": "hachiro_bell"}

func _heart_events_play() -> void:
	for id in Villagers.all():
		for band in [3, 5, 6]:
			for promise in ([false, true] if (id == "kota" and band == 5) or band == 6 else [false]):
				var ev: String = "heart_" + id + ({3: "", 5: "_5", 6: "_6"}[band])
				var g := _game()
				g.affection.add(id, int(Affection.rules().bands[band]))
				if promise:
					g.flags[FIVE_FLAGS[id] if band == 6 else "kota_carp_promise"] = "new" if id == "sayo" else true
				var before: int = g.affection.of(id)
				var r := EventRunner.open(ev, g)
				check(r.error == "", "%s runs: %s" % [ev, r.error])
				if r.error != "":
					continue
				# Talked to with the villager on the cell above (as a talk trigger plays it), or
				# (the promise runs) played where their plan has them elsewhere.
				r.start(Vector2(8, 8), Vector2i.UP)
				if not promise:
					r.on_stage = {id: {"pos": Vector2(0.5, -0.5), "facing": Vector2i.LEFT}}
				var seen := [0, 0]   # lines said, lines said with the villager and the farmer facing each other
				var on_line := func(_d, _at):   # the text box opens: who stands where
					var a: Dictionary = r.actors.get(id, {})
					seen[0] += 1
					if a.has("pos") and (a.pos + Vector2(a.facing)).floor() == Vector2.ZERO 							and (Vector2(0.5, 0.5) + Vector2(r.facing)).floor() == a.pos.floor() and not a.moving:
						seen[1] += 1
				g.dialogue_requested.connect(on_line)
				var walked := false
				for i in 200:
					if r.done():
						break
					r.update(0.5)
					walked = walked or r.actors.get(id, {}).get("moving", false)
				g.dialogue_requested.disconnect(on_line)
				check(r.done(), "%s ends" % ev)
				check(seen[0] > 0 and seen[1] == seen[0], "%s: %s stands facing the farmer through every line (%d of %d)" % [ev, id, seen[1], seen[0]])
				check(walked == promise and r.actors.is_empty(), "%s: %s %s, gone back to their plan at the end" % [ev, id, "came and went" if promise else "never walked"])
				check(EventRunner.is_set(g.flags, ev), "%s sets its flag" % ev)
				check(g.affection.of(id) > before, "%s likes the farmer more after %s" % [id, ev])
				if band == 6 and SIX_FLAGS[id] != "":
					check(EventRunner.is_set(g.flags, SIX_FLAGS[id]), "%s sets %s" % [ev, SIX_FLAGS[id]])
				if band == 6:
					check(g.heart_band(id) == 6, "%s: still band 6 after it" % ev)
	var d := DialogueRunner.open("heart_events_5", {"kota_carp_promise": true}, "kota")
	_next_line(d)
	check("You promised" in d.text(), "with the promise Kota keeps it too: %s" % d.text())
	d = DialogueRunner.open("heart_events_5", {}, "kota")
	_next_line(d)
	check("didn't" in d.text(), "without it he let the carp be anyway: %s" % d.text())
	# Band 6's lines look back on band 5: each branch shows its own line.
	var looks := {"tome": ["grandchild", "nag it"], "kota": ["promise", "Nobody else"],
		"sayo": ["new sign", "minding his store"]}
	for id in looks:
		d = DialogueRunner.open("heart_events_6", {FIVE_FLAGS[id]: true}, id)
		_next_line(d)
		_next_line(d)
		var with_flag := d.text()
		d = DialogueRunner.open("heart_events_6", {}, id)
		_next_line(d)
		_next_line(d)
		check(looks[id][0] in with_flag and looks[id][1] in d.text(), "%s's band 6 scene: %s / %s" % [id, with_flag, d.text()])
	d = DialogueRunner.open("heart_events_6", {"hachiro_bell": true}, "hachiro_strike")
	_next_line(d)
	check("bell" in d.text(), "Hachiro asks after the bell: %s" % d.text())
	d = DialogueRunner.open("heart_events_6", {}, "hachiro_strike")
	_next_line(d)
	check("remembers" in d.text(), "without it, the blade remembers: %s" % d.text())


## Band 6's talk lines: after the band 6 scene, at band 6 only (the band 4 .. 6 lines before).
func _band6_talk() -> void:
	for id in Villagers.all():
		var st := {"year": 1, "season": "spring", "day": 3, "weekday": "wed", "time": 600, "weather": "sunny",
			"flags": {"heart_%s_6" % id: true}, "festival": "", "band": 6, "again": false, "birthday": false, "day_number": 0}
		var dear := ["dear_1", "dear_2", "dear_3"]
		check(Talk.pick(id, st) in dear, "%s at band 6 after the scene: %s" % [id, Talk.pick(id, st)])
		check(not Talk.pick(id, st.merged({"flags": {}}, true)) in dear, "%s at band 6 before the scene keeps the old lines" % id)
		check(not Talk.pick(id, st.merged({"band": 5}, true)) in dear, "%s at band 5: not the band 6 lines" % id)
		var seen := {}
		for n in 3:
			seen[Talk.pick(id, st.merged({"day_number": n}, true))] = true
		check(seen.size() == 3, "%s's three band 6 lines take turns" % id)


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
