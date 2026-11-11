extends SceneTree
## Headless checks for relationships: the heart band on the text box's name tag, birthdays
## (villager files, the calendar, gifts counting x5, the birthday lines), the small nightly
## loss for villagers left alone, the heart events (one per villager at bands 3, 5 and 6, and
## the band 6 talk lines), birthday day plans, fair weather and the HUD tag on a birthday, mine finds and cooked dishes as
## gifts, the villagers' own lines for keepsakes and dishes, a loved keepsake kept in its
## new owner's home, and marriage (data/marriage.json: the rules for the mizuhiki knot, the
## answers, the proposal, the wedding day and its trigger, the spouse's day plan and lines,
## the spouse's morning help, the save). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_relationships.gd

var failures := 0
var _frame := 0


func _init() -> void:
	_heart_art()
	_birthday_data()
	_birthday_gifts()
	_gift_pace()
	_neglect()
	_heart_event_rows()
	_band6_talk()
	_birthday_plans()
	_mine_gifts()
	_dish_gifts()
	_keepsake_gifts()
	_sakurazaka_friends()
	_marriage_rules()
	_married_plans_and_lines()
	_spouse_help_rules()
	_spouse_special_days()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_hearts_in_text_box()
		_birthday_talk()
		_dish_gift_in_game()
		_keepsake_gift_in_game()
		_genzo_friend()
		_haru_friend()
		_shige_friend()
		_nana_friend()
		_kiku_friend()
		_keepsake_homes()   # builds the 3D view, which needs the Game autoload
		_keepsake_kept_in_game()
		_neglect_in_game()
		_heart_events_play()
		_birthday_weather()
		_birthday_tag()
		_marriage_in_game()
		_spouse_help_in_game()
		print("test_relationships: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


# --- pure logic and data ----------------------------------------------------

## A married spouse keeps the farmhouse on festival days and their birthday (and Ren on his
## Sundays off): the married_ plan wins, they wake and end the day at the farmhouse and never
## go to their old home; single, the old plans still hold.
func _spouse_special_days() -> void:
	const OLD_HOME := {"sayo": "sayo_house", "haru": "haru_house", "ichiro": "ichiro_house", "mio": "mio_hut",
		"kaede": "kaede_house", "shino": "shino_house", "ren": "post_office", "fumi": ""}
	var people := Villagers.all()
	for id in Marriage.candidates():
		var v: Dictionary = people[id]
		var days := []
		for f in ["blossom_day", "lantern_night", "moon_night", "years_turn"]:
			days.append({"name": f, "s": {"year": 1, "season": "spring", "day": 3, "weekday": "wed", "weather": "sunny", "festival": f}})
		var born: Dictionary = v.birthday
		days.append({"name": "birthday", "s": {"year": 1, "season": born.season, "day": int(born.day), "weekday": "wed", "weather": "sunny", "festival": ""}})
		if id == "ren":
			days.append({"name": "sunday", "s": {"year": 1, "season": "spring", "day": 7, "weekday": "sun", "weather": "sunny", "festival": ""}})
		for d in days:
			var married: Dictionary = d.s.merged({"flags": {"married_" + id: true}})
			var plan := Villagers.pick_plan(v, married)
			var single := Villagers.pick_plan(v, d.s.merged({"flags": {}}))
			if plan == str(v.default) and single == str(v.default):
				continue   # nothing special that day (Sayo's birthday: her married days already hold)
			var built: Array = DayPlan.build(v.plans[plan], Villagers.speed_of(v))
			check(built[0] == "" and plan.begins_with("married"), "%s married on %s: a married plan (%s) %s" % [id, d.name, plan, built[0]])
			if built[0] != "":
				continue
			var p: DayPlan = built[1]
			var maps := {}
			for e in p.entries:
				maps[e.map] = true
			var last := ""
			for e in p.entries:
				if e.map != DayPlan.AWAY:
					last = e.map
			check(p.where(6 * 60 + 30).map == "house" and last == "house", "%s married on %s: wakes and ends the day at the farmhouse" % [id, d.name])
			check(OLD_HOME[id] == "" or not maps.has(OLD_HOME[id]), "%s married on %s: never back in %s" % [id, d.name, OLD_HOME[id]])
			check(not single.begins_with("married"), "%s single on %s keeps the old plan (%s)" % [id, d.name, single])


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
	for id in Villagers.friends():
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


## The pace of a gift and a talk every day (the year playtest found 8 / 3 put everyone at
## band 6 by summer): a liked gift reaches band 3 in about a season, a loved one in two to
## four weeks, and band 6 takes more than a season of loved gifts.
func _gift_pace() -> void:
	var days_to := func(item: String, band: int) -> int:
		var a := Affection.new()
		for d in range(1, 400):
			a.give("tome", item, d)
			a.talk("tome", d)
			if a.band("tome") >= band:
				return d
		return 999
	var liked: int = days_to.call("turnip", 3)
	var loved: int = days_to.call("eggplant", 3)
	var loved6: int = days_to.call("eggplant", 6)
	check(liked >= 25 and liked <= 40, "a liked gift a day: band 3 in about a season (%d days)" % liked)
	check(loved >= 14 and loved <= 28, "a loved gift a day: band 3 in two to four weeks (%d days)" % loved)
	check(loved6 > 30, "band 6 takes more than a season of loved gifts (%d days)" % loved6)


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
## be talked to, played once; then one at band 5 and one at band 6, each after the last
## (every villager has all three, the 5 / 6 checks run where
## the event file is there).
func _heart_event_rows() -> void:
	var maps := {"tome": ["town", "tome_house"], "kota": ["town", "kota_house"],
		"sayo": ["town", "store", "sayo_house"], "hachiro": ["town", "smithy"],
		"fumi": ["town", "teahouse", "sakurazaka"], "ichiro": ["town", "sakurazaka", "ichiro_house"],
		"genzo": ["town", "kaminoda", "genzo_house"], "haru": ["town", "kaminoda", "haru_house", "hill"],
		"shige": ["town", "minamino", "shige_house"], "nana": ["town", "minamino", "shige_house"], "mio": ["town", "river", "mio_hut"], "kaede": ["town", "minamino", "kaede_house"],
		"kiku": ["town", "minamino", "kiku_house"],
		"shino": ["town", "minamino", "shino_house", "river"],
		"ren": ["town", "post_office", "sakurazaka", "kaminoda", "minamino", "river"]}
	for id in ["tome", "kota", "sayo", "hachiro", "fumi", "ichiro", "genzo", "haru", "shige", "nana", "kiku", "mio", "kaede", "shino", "ren"]:
		check(_has_event("heart_%s_5" % id) and _has_event("heart_%s_6" % id), "%s has heart events at 5 and 6" % id)
	for id in Villagers.friends():
		check(maps.has(id) and _has_event("heart_" + id), "%s has a heart event" % id)
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
			if not _has_event(five):
				continue
			check(t.pick("talk", s.merged({"hearts": {id: 5}, "seen": after}, true)) == five, "on %s, band 5 plays %s" % [m, five])
			check(t.pick("talk", s.merged({"hearts": {id: 6}, "seen": after}, true)) == five, "on %s, still at band 6 if missed" % m)
			check(t.pick("talk", s.merged({"hearts": {id: 4}, "seen": after}, true)) != five, "on %s, not at band 4" % m)
			check(t.pick("talk", s.merged({"hearts": {id: 5}}, true)) == "heart_" + id, "on %s, band 3's comes first" % m)
			# The third one at band 6 only, only after the one at 5 was seen, and once.
			var six := "heart_%s_6" % id
			if not _has_event(six):
				continue
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
	for id in Villagers.friends():
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


## Festival keepsakes as gifts: the ones in the lists are real keepsakes, every villager loves
## one, every keepsake is welcome somewhere (loved or liked), and a ribbon (a prize, not a present) is neutral.
func _keepsake_gifts() -> void:
	var kept: Dictionary = Keepsakes.data().keepsakes
	var welcome := {}
	for id in Villagers.all():
		var loves := 0
		for r in Villagers.all()[id].gifts:
			for item in Villagers.all()[id].gifts[r]:
				if item.begins_with("keep:"):
					check(kept.has(item.trim_prefix("keep:")), "%s's %s %s is a keepsake" % [id, r, item])
					loves += 1 if r == "love" else 0
					if r in ["love", "like"]:
						welcome[item] = true
		check(loves == 1, "%s loves one keepsake (%d)" % [id, loves])
	for k in kept:
		if "keep:" + k == Marriage.item():   # the mizuhiki knot is a proposal, not a present
			check(not welcome.has("keep:" + k), "nobody takes the mizuhiki knot as a gift")
			continue
		check(welcome.has("keep:" + k), "someone likes keep:%s" % k)
	check(Villagers.reaction("kota", "keep:clay_rabbit") == "love" and Villagers.reaction("hachiro", "keep:wind_chime") == "dislike"
		and Villagers.reaction("tome", "keep:omamori") == "love" and Villagers.reaction("sayo", "keep:daruma") == "dislike",
		"Kota's rabbit, Tome's charm; no chime by the forge, no daruma for Sayo")
	check(Villagers.reaction("tome", "ribbon:moon_night:1") == "neutral", "a ribbon is neither here nor there")


## A keepsake held overhead is given like any gift and leaves the hands.
func _keepsake_gift_in_game() -> void:
	var g := _game()
	var said := []
	g.dialogue_requested.connect(func(id, at): said.append([id, at]))
	g.season = g.SEASONS.find("summer")
	g.day = 2
	g.weather_today = "sunny"
	g.hour = 9
	g.inventory.slots.hand[0] = {"id": "keep:wind_chime", "n": 1}
	check(g.talk_to("sayo", Vector2i.DOWN) == "gift" and said.back() == ["talk_sayo", "gift_wind_chime"], "Sayo loves the wind chime, and says so her own way %s" % [said.back()])
	check(g.affection.of("sayo") == int(Affection.rules().gift.love) and not g.holding() and g.count("keep:wind_chime") == 0, "it counts as a loved gift and is given away")


## Each villager's loved keepsake has a place in their home: a keepsake prop gated by
## Keepsakes.given_flag, there only with that flag, drawn in both views from the item's icon.
func _keepsake_homes() -> void:
	var homes := {"tome": "tome_house", "kota": "kota_house", "sayo": "sayo_house", "hachiro": "smithy",
		"fumi": "teahouse", "ichiro": "ichiro_house", "genzo": "genzo_house", "haru": "haru_house", "shige": "shige_house", "nana": "shige_house", "kiku": "kiku_house"}
	for id in homes:
		var loved: Array = Villagers.all()[id].gifts.love.filter(func(i): return i.begins_with("keep:"))
		var flag := Keepsakes.given_flag(id, loved[0])
		var kept := func(f: Dictionary) -> Array:
			return MapManager.load_map(homes[id], null, f)[1].props.filter(func(p): return p.kind == "keepsake")
		check(kept.call({}).is_empty(), "nothing of %s's on show before it is given" % loved[0])
		var on: Array = kept.call({flag: true})
		check(on.size() == 1 and on[0].item == loved[0], "%s keeps %s at home once %s is set" % [id, loved[0], flag])
		var other_keep := "keep:daruma" if loved[0] == "keep:paper_fan" else "keep:paper_fan"
		check(kept.call({Keepsakes.given_flag(id, other_keep): true}).is_empty(), "another keepsake's flag shows nothing in %s" % homes[id])
		var m: MapData = MapManager.load_map(homes[id], null, {flag: true})[1]
		for sp in m.spawns:
			check(not m.is_solid(m.spawns[sp][0]), "%s spawn %s isn't under the keepsake" % [homes[id], sp])
		var key := StoryView.art_key(on[0])
		check(key == "ui:keep:" + loved[0].trim_prefix("keep:"), "its picture is the keepsake's icon (%s)" % key)
		var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
		w.build(m)
		var tex := PlaceholderArt.tex(key)
		check(w.find_children("*", "Sprite3D", true, false).any(func(n): return n.texture == tex), "%s in 3D shows %s" % [homes[id], loved[0]])
		w.free()
		var v2: StoryView = StoryView.new(m)
		check(v2.map.props.filter(func(p): return p.kind in StoryView.KINDS).size() == 1, "the flat view of %s draws it" % homes[id])
		v2.free()


# --- on the real Game -------------------------------------------------------

## Giving a keepsake the villager loves sets its flag, so it shows in their home (the cached
## map follows Game.flags) and stays after a save; a keepsake only liked sets nothing.
func _keepsake_kept_in_game() -> void:
	var g := _game()
	g.season = g.SEASONS.find("summer")
	g.day = 3
	g.weather_today = "sunny"
	g.hour = 9
	var shown := func(map_id: String) -> bool:
		return MapManager.data(map_id).props.any(func(p): return p.kind == "keepsake")
	check(not shown.call("kota_house"), "a new game has no rabbit at Kota's")
	g.inventory.slots.hand[0] = {"id": "keep:paper_fan", "n": 1}
	g.talk_to("kota", Vector2i.DOWN)
	check(not g.flags.has(Keepsakes.given_flag("kota", "keep:paper_fan")) and not shown.call("kota_house"), "a fan he only likes isn't put on show")
	g.day = 4
	g.inventory.slots.hand[0] = {"id": "keep:clay_rabbit", "n": 1}
	g.talk_to("kota", Vector2i.DOWN)
	check(g.flags.get("kept_kota_clay_rabbit", false) == true, "the rabbit he loves sets kept_kota_clay_rabbit")
	check(shown.call("kota_house"), "and now stands in his house")
	var saved: Dictionary = g.to_dict()
	g.new_game()
	check(not shown.call("kota_house"), "a new game takes it away")
	check(g.from_dict(JSON.parse_string(JSON.stringify(saved))) == "" and shown.call("kota_house"), "it comes back with the save")
	g.new_game()


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
	check(said.back() == ["talk_sayo", "gift_dish_dislike"] and not g.holding(), "Sayo takes the fish dish, without joy, in her own words %s" % [said.back()])
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
const SIX_FLAGS := {"tome": "", "kota": "kota_streamer", "sayo": "sayo_ledger", "hachiro": "hachiro_strike", "fumi": "fumi_kettle", "ichiro": "ichiro_mark", "genzo": "genzo_straw", "haru": "haru_wave", "shige": "shige_vine", "nana": "nana_sky", "kiku": "kiku_graft", "mio": "mio_ferry", "kaede": "kaede_fortune", "shino": "shino_first", "ren": "ren_route"}
## The flag each band 6 scene looks back on (Fumi's comes from her band 3 scene).
const FIVE_FLAGS := {"tome": "tome_grandma", "kota": "kota_carp_promise", "sayo": "sayo_sign", "hachiro": "hachiro_bell", "fumi": "fumi_honest", "ichiro": "ichiro_kiln", "genzo": "genzo_jizo", "haru": "haru_go", "shige": "shige_share", "nana": "nana_beside", "kiku": "kiku_glad", "mio": "mio_keep", "kaede": "kaede_recite", "shino": "shino_own", "ren": "ren_van"}

func _heart_events_play() -> void:
	for id in Villagers.friends():
		for band in [3, 5, 6].filter(func(b): return b == 3 or _has_event("heart_%s_%d" % [id, b])):
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
		"sayo": ["new sign", "minding his store"], "fumi": ["bean paste", "owed to her"],
		"ichiro": ["dug the clay", "never said thanks"],
		"genzo": ["watched you tie", "let the jizo go without"],
		"haru": ["Nobody holding the door", "eleven times"],
		"shige": ["both patches", "at the fence"],
		"nana": ["blinking beside each other", "big steady star"],
		"kiku": ["Yours was the first tap", "did not feel like cheating"],
		"mio": ["bell rang", "just for myself"],
		"kaede": ["said them to you again", "my sleeve"],
		"shino": ["wildflower stencil", "Mother's cranes"],
		"ren": ["park at the bridge", "signed by every house"]}
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
	for id in Villagers.friends():
		if not _has_event("heart_%s_6" % id):
			continue
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


func _has_event(id: String) -> bool:
	return FileAccess.file_exists(EventRunner.DIR + id + ".json")


## Fumi and Ichiro of Sakurazaka are friends now: hearts, birthdays and their day plans, their
## close lines, the band 5 scenes' branches, and a place at the end of the record.
func _sakurazaka_friends() -> void:
	var friends := Villagers.friends()
	check(friends.has("fumi") and friends.has("ichiro") and friends.size() == 15, "fifteen villagers with hearts (%s)" % [friends.keys()])
	check(Villagers.all().fumi.birthday.season == "spring" and int(Villagers.all().fumi.birthday.day) == 26 and Villagers.all().ichiro.birthday.season == "fall" and int(Villagers.all().ichiro.birthday.day) == 9,
		"Fumi's birthday spring 26, Ichiro's fall 9")
	var spring := {"year": 1, "season": "spring", "day": 26, "weekday": "fri", "weather": "sunny", "flags": {}, "festival": ""}
	Villagers.reset_day()
	check(Villagers.is_on("fumi", "teahouse", 10 * 60, spring) and Villagers.where("fumi", 13 * 60, spring).map == "sakurazaka"
		and Villagers.is_on("fumi", "teahouse", 17 * 60, spring), "on her birthday Fumi pours in the morning, stands under the cherries after, back by evening")
	var before := spring.merged({"day": 25}, true)
	Villagers.reset_day()
	check(Villagers.is_on("fumi", "teahouse", 11 * 60 + 30, before), "the day before she pours until noon")
	var fall := spring.merged({"season": "fall", "day": 9}, true)
	Villagers.reset_day()
	var w := Villagers.where("ichiro", 12 * 60 + 50, fall)
	check(w.get("map", "") == "sakurazaka" and Vector2i(w.get("pos", Vector2.ZERO).floor()) == Vector2i(9, 9), "on his birthday Ichiro sits on the teahouse gravel past lunch (%s)" % [w])
	check(Villagers.is_on("ichiro", "ichiro_house", 15 * 60, fall), "and is home by mid-afternoon")
	Villagers.reset_day()
	# Their talk: close lines from band 4, their own lines after the band 5 scene (on a Monday,
	# off their forage days).
	var st := {"year": 1, "season": "summer", "day": 3, "weekday": "mon", "time": 15 * 60 + 30, "weather": "sunny",
		"flags": {}, "festival": "", "band": 4, "again": false, "birthday": false, "day_number": 0}
	for id in ["fumi", "ichiro"]:
		var after: String = {"fumi": "after_tea", "ichiro": "kiln"}[id]
		check(Talk.pick(id, st) in ["close_1", "close_2"], "%s at band 4: %s" % [id, Talk.pick(id, st)])
		check(not Talk.pick(id, st.merged({"band": 3}, true)) in ["close_1", "close_2"], "%s at band 3 keeps the plain lines" % id)
		check(Talk.pick(id, st.merged({"band": 5, "flags": {"heart_%s_5" % id: true}}, true)).begins_with(after), "%s after the band 5 scene" % id)
		check(Talk.pick(id, st.merged({"birthday": true}, true)) == "birthday", "%s on the birthday" % id)
	# Band 5 looks back on band 3: Fumi remembers being told the truth.
	var d := DialogueRunner.open("heart_events_5", {"fumi_honest": true}, "fumi")
	_next_line(d)
	_next_line(d)
	check("bean paste" in d.text(), "told the truth, Fumi asks again: %s" % d.text())
	d = DialogueRunner.open("heart_events_5", {}, "fumi")
	_next_line(d)
	_next_line(d)
	check("think best" in d.text(), "else the village's polite answer: %s" % d.text())
	# The ending's closing word: whoever is liked most, Fumi or Ichiro too.
	var bands: Array = Affection.rules().bands
	check(Ending.friend({"fumi": int(bands[4]), "tome": int(bands[3])}) == "fumi" and Ending.friend({"ichiro": int(bands[5]), "kota": int(bands[4])}) == "ichiro",
		"Fumi or Ichiro can close the record")
	var ending := FileAccess.get_file_as_string(EventRunner.DIR + "ending.json")
	for id in friends:
		check(id == "tome" or ("ending_friend_" + id) in ending, "the ending has a part for %s" % id)
		check(id == "tome" or DialogueRunner.open("ending", {}, id).error == "", "and lines for %s" % id)


## Genzo of Kaminoda is a friend too: a birthday and its day plan, close lines, the jizo lines
## after his band 5 scene, the answers in his scenes, the seed rice at band 3, a place at the end
## of the record and one Neighbours row less.
func _genzo_friend() -> void:
	var v: Dictionary = Villagers.all().genzo
	check(Villagers.friends().has("genzo") and v.get("hearts", true) != false, "Genzo has hearts now")
	check(v.birthday.season == "summer" and int(v.birthday.day) == 13, "Genzo's birthday is summer 13")
	var summer := {"year": 1, "season": "summer", "day": 13, "weekday": "wed", "weather": "sunny", "flags": {}, "festival": ""}
	Villagers.reset_day()
	var w := Villagers.where("genzo", 12 * 60 + 50, summer)
	check(w.get("map", "") == "kaminoda" and Vector2i(w.get("pos", Vector2.ZERO).floor()) == Vector2i(19, 9), "on his birthday Genzo sits by the well past noon (%s)" % [w])
	check(Villagers.is_on("genzo", "genzo_house", 15 * 60, summer) and Villagers.is_on("genzo", "genzo_house", 8 * 60, summer), "home in the morning and again by mid-afternoon")
	Villagers.reset_day()
	check(Villagers.pick_plan(v, summer.merged({"weather": "rain"}, true)) == "birthday", "even a wet birthday is his birthday plan")
	var st := {"year": 1, "season": "spring", "day": 3, "weekday": "wed", "time": 15 * 60 + 30, "weather": "sunny",
		"flags": {}, "festival": "", "band": 4, "again": false, "birthday": false, "day_number": 0}
	check(Talk.pick("genzo", st) in ["close_1", "close_2"] and not Talk.pick("genzo", st.merged({"band": 3}, true)) in ["close_1", "close_2"], "close lines from band 4: %s" % Talk.pick("genzo", st))
	check(Talk.pick("genzo", st.merged({"band": 5, "flags": {"heart_genzo_5": true}}, true)).begins_with("jizo"), "the jizo lines after the band 5 scene")
	check(Talk.pick("genzo", st.merged({"birthday": true}, true)) == "birthday" and Talk.has_line("genzo", "gift_birthday"), "birthday lines")
	# The scenes have both answers' lines.
	for at in ["genzo_iron", "genzo_cold"]:
		var d := DialogueRunner.open("heart_events", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	for at in ["genzo_tie", "genzo_show"]:
		var d := DialogueRunner.open("heart_events_5", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	var rice := FileAccess.get_file_as_string(EventRunner.DIR + "heart_genzo.json")
	check("seeds:rice" in rice, "Genzo gives seed rice at band 3")
	# The record: Genzo counts as a friend, so he no longer makes a Neighbours row.
	check(Ending.friend({"genzo": int(Affection.rules().bands[5]), "kota": int(Affection.rules().bands[4])}) == "genzo", "Genzo can close the record")
	check("ending_friend_genzo" in FileAccess.get_file_as_string(EventRunner.DIR + "ending.json") and DialogueRunner.open("ending", {}, "genzo").error == "", "the ending has a part and lines for Genzo")
	var g := _game()
	g.affection.add("genzo", int(Affection.rules().bands[int(Ending.data().neighbour_band)]))
	check(g.ending_values().neighbours_known == 0 and g.ending_values().heart_bands >= 1, "Genzo is a friend (a heart band), not a neighbour")


## Haru of Kaminoda is a friend too: a birthday and its day plan (up on the hill all the middle
## of the day), close lines, the sandal lines after her band 5 scene, the answers in her scenes,
## the cucumber seed at band 3, a place at the end of the record and one Neighbours row less.
func _haru_friend() -> void:
	var v: Dictionary = Villagers.all().haru
	check(Villagers.friends().has("haru") and v.get("hearts", true) != false, "Haru has hearts now")
	check(v.birthday.season == "summer" and int(v.birthday.day) == 27, "Haru's birthday is summer 27")
	var summer := {"year": 1, "season": "summer", "day": 27, "weekday": "thu", "weather": "sunny", "flags": {}, "festival": ""}
	Villagers.reset_day()
	var w := Villagers.where("haru", 11 * 60, summer)
	check(w.get("map", "") == "hill" and Vector2i(w.get("pos", Vector2.ZERO).floor()) == Vector2i(21, 4), "on her birthday Haru sits at the lookout all morning (%s)" % [w])
	check(Villagers.is_on("haru", "haru_house", 8 * 60, summer) and Villagers.where("haru", 17 * 60, summer).get("map", "") == "kaminoda"
		and Villagers.is_on("haru", "haru_house", 19 * 60, summer), "home early, her garden by late afternoon, home by evening")
	Villagers.reset_day()
	check(Villagers.where("haru", 11 * 60, summer.merged({"day": 26}, true)).get("map", "") == "kaminoda", "the day before she is at the drying rack at eleven")
	Villagers.reset_day()
	check(Villagers.pick_plan(v, summer.merged({"weather": "rain"}, true)) == "birthday", "even a wet birthday is her birthday plan")
	var st := {"year": 1, "season": "spring", "day": 3, "weekday": "wed", "time": 15 * 60 + 30, "weather": "sunny",
		"flags": {}, "festival": "", "band": 4, "again": false, "birthday": false, "day_number": 0}
	check(Talk.pick("haru", st) in ["close_1", "close_2"] and not Talk.pick("haru", st.merged({"band": 3}, true)) in ["close_1", "close_2"], "close lines from band 4: %s" % Talk.pick("haru", st))
	check(Talk.pick("haru", st.merged({"band": 5, "flags": {"heart_haru_5": true}}, true)).begins_with("sandals"), "the sandal lines after the band 5 scene")
	check(Talk.pick("haru", st.merged({"band": 5, "map": "hill"}, true)).begins_with("hill"), "on the hill her hill lines still")
	check(Talk.pick("haru", st.merged({"birthday": true, "map": "hill"}, true)) == "birthday" and Talk.has_line("haru", "gift_birthday"), "birthday lines, on the hill too")
	# The scenes have both answers' lines.
	for at in ["haru_tight", "haru_loose"]:
		var d := DialogueRunner.open("heart_events", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	for at in ["haru_stay", "haru_go"]:
		var d := DialogueRunner.open("heart_events_5", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	# Band 5's answers leave a mark that band 6 looks back on; band 6 sets its flags and has both tag answers.
	var five_text := FileAccess.get_file_as_string("res://data/dialogue/heart_events_5.json")
	check('"set": {"haru_stay": true}' in five_text and '"set": {"haru_go": true}' in five_text, "Haru's band 5 answers set haru_stay / haru_go")
	for at in ["haru_place", "haru_name", "haru_end"]:
		var d := DialogueRunner.open("heart_events_6", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	check("haru_wave" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_haru_6.json"), "Haru's band 6 sets haru_wave")
	check("seeds:cucumber" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_haru.json"), "Haru gives cucumber seed at band 3")
	check("Haru, she'll want some" in FileAccess.get_file_as_string("res://data/dialogue/heart_events.json"), "Genzo calls Haru she")
	# The record: Haru counts as a friend, so she no longer makes a Neighbours row.
	check(Ending.friend({"haru": int(Affection.rules().bands[5]), "genzo": int(Affection.rules().bands[4])}) == "haru", "Haru can close the record")
	check("ending_friend_haru" in FileAccess.get_file_as_string(EventRunner.DIR + "ending.json") and DialogueRunner.open("ending", {}, "haru").error == "", "the ending has a part and lines for Haru")
	var g := _game()
	g.affection.add("haru", int(Affection.rules().bands[int(Ending.data().neighbour_band)]))
	check(g.ending_values().neighbours_known == 0 and g.ending_values().heart_bands >= 1, "Haru is a friend (a heart band), not a neighbour")


## Shige of Minamino is a friend too: a birthday and its day plan (Nana hides his hoe: the
## roadside shrine in the morning, the beds by his house with empty hands after lunch), close
## lines, the pumpkin lines after his band 5 scene, the answers in his scenes, the seed he
## gives at bands 3 and 5, a place at the end of the record and one Neighbours row less.
func _shige_friend() -> void:
	var v: Dictionary = Villagers.all().shige
	check(Villagers.friends().has("shige") and v.get("hearts", true) != false, "Shige has hearts now")
	check(v.birthday.season == "winter" and int(v.birthday.day) == 18, "Shige's birthday is winter 18")
	var winter := {"year": 1, "season": "winter", "day": 18, "weekday": "thu", "weather": "sunny", "flags": {}, "festival": ""}
	Villagers.reset_day()
	var w := Villagers.where("shige", 11 * 60, winter)
	check(w.get("map", "") == "minamino" and Vector2i(w.get("pos", Vector2.ZERO).floor()) == Vector2i(2, 9), "on his birthday Shige sits by the roadside shrine in the morning (%s)" % [w])
	check(Villagers.is_on("shige", "shige_house", 8 * 60, winter) and Villagers.is_on("shige", "shige_house", 12 * 60 + 30, winter)
		and Villagers.where("shige", 14 * 60, winter).get("map", "") == "minamino" and Villagers.is_on("shige", "shige_house", 17 * 60, winter),
		"home early and for lunch, the beds after lunch, home by evening")
	Villagers.reset_day()
	check(Villagers.where("shige", 11 * 60, winter.merged({"day": 17}, true)).get("pos", Vector2.ZERO).floor() != Vector2(2, 9), "the day before he is at work at eleven")
	Villagers.reset_day()
	check(Villagers.pick_plan(v, winter.merged({"weather": "snow"}, true)) == "birthday", "even a snowy birthday is his birthday plan")
	var st := {"year": 1, "season": "spring", "day": 3, "weekday": "wed", "time": 15 * 60 + 30, "weather": "sunny",
		"flags": {}, "festival": "", "band": 4, "again": false, "birthday": false, "day_number": 0}
	check(Talk.pick("shige", st) in ["close_1", "close_2"] and not Talk.pick("shige", st.merged({"band": 3}, true)) in ["close_1", "close_2"], "close lines from band 4: %s" % Talk.pick("shige", st))
	check(Talk.pick("shige", st.merged({"band": 5, "flags": {"heart_shige_5": true}}, true)).begins_with("pumpkin"), "the pumpkin lines after the band 5 scene")
	check(not Talk.pick("shige", st.merged({"band": 6}, true)).begins_with("pumpkin"), "no pumpkin lines before the scene")
	check(Talk.pick("shige", st.merged({"birthday": true}, true)) == "birthday" and Talk.has_line("shige", "gift_birthday"), "birthday lines")
	check(Talk.pick("shige", st.merged({"band": 1, "weekday": "tue"}, true)) != "forage_spring" and Talk.pick("shige", st.merged({"band": 2, "weekday": "tue"}, true)) == "forage_spring",
		"forage lines from band 2, like the other friends")
	# The scenes have both answers' lines.
	for at in ["shige_smile", "shige_frown"]:
		var d := DialogueRunner.open("heart_events", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	for at in ["shige_fence", "shige_share"]:
		var d := DialogueRunner.open("heart_events_5", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	# Band 5's answers leave a mark that band 6 looks back on; band 6 has both answers' lines and sets shige_vine.
	var shige5 := FileAccess.get_file_as_string("res://data/dialogue/heart_events_5.json")
	check('"set": {"shige_fence": true}' in shige5 and '"set": {"shige_share": true}' in shige5, "Shige's band 5 answers set shige_fence / shige_share")
	for at in ["shige_pot", "shige_tin", "shige_end"]:
		var d := DialogueRunner.open("heart_events_6", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	check("shige_vine" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_shige_6.json"), "Shige's band 6 sets shige_vine")
	check("seeds:tomato" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_shige.json"), "Shige gives tomato seed at band 3")
	check("seeds:pumpkin" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_shige_5.json"), "and pumpkin seed at band 5")
	check("'Shige's birthday.'" in DialogueRunner.open("examine_house", {}, "winter_birthday").text(), "the calendar names Shige's birthday")
	# The record: Shige counts as a friend, so he no longer makes a Neighbours row.
	check(Ending.friend({"shige": int(Affection.rules().bands[5]), "haru": int(Affection.rules().bands[4])}) == "shige", "Shige can close the record")
	check("ending_friend_shige" in FileAccess.get_file_as_string(EventRunner.DIR + "ending.json") and DialogueRunner.open("ending", {}, "shige").error == "", "the ending has a part and lines for Shige")
	var g := _game()
	g.affection.add("shige", int(Affection.rules().bands[int(Ending.data().neighbour_band)]))
	check(g.ending_values().neighbours_known == 0 and g.ending_values().heart_bands >= 1, "Shige is a friend (a heart band), not a neighbour")


## Nana of Minamino is a friend too: a birthday (fall 19) and its day plan (the jizo on the lane in
## the morning, the pond till dusk), close lines, the star lines after her band 5 scene, the answers
## in her scenes, the seed and the cucumbers she gives, a place at the end of the record and the
## Neighbours row down to Kiku and Dr. Yae.
func _nana_friend() -> void:
	var v: Dictionary = Villagers.all().nana
	check(Villagers.friends().has("nana") and v.get("hearts", true) != false, "Nana has hearts now")
	check(v.birthday.season == "fall" and int(v.birthday.day) == 19, "Nana's birthday is fall 19")
	var fall := {"year": 1, "season": "fall", "day": 19, "weekday": "thu", "weather": "sunny", "flags": {}, "festival": ""}
	Villagers.reset_day()
	var w := Villagers.where("nana", 10 * 60, fall)
	check(w.get("map", "") == "minamino" and Vector2i(w.get("pos", Vector2.ZERO).floor()) == Vector2i(4, 18), "on her birthday Nana dresses the jizo on the lane in the morning (%s)" % [w])
	check(Villagers.is_on("nana", "shige_house", 8 * 60, fall) and Villagers.is_on("nana", "shige_house", 12 * 60 + 30, fall)
		and Villagers.where("nana", 17 * 60 + 30, fall).get("map", "") == "town" and Villagers.is_on("nana", "shige_house", 19 * 60, fall),
		"home early and for lunch, at the pond till dusk, home by evening")
	Villagers.reset_day()
	check(Villagers.where("nana", 10 * 60, fall.merged({"day": 18}, true)).get("map", "") != "minamino" or Villagers.where("nana", 10 * 60, fall.merged({"day": 18}, true)).get("pos", Vector2.ZERO).floor() != Vector2(4, 18), "the day before she is at her weeding at ten")
	var st := {"year": 1, "season": "spring", "day": 3, "weekday": "wed", "time": 15 * 60 + 30, "weather": "sunny",
		"flags": {}, "festival": "", "band": 4, "again": false, "birthday": false, "day_number": 0}
	check(Talk.pick("nana", st) in ["close_1", "close_2"] and not Talk.pick("nana", st.merged({"band": 3}, true)) in ["close_1", "close_2"], "close lines from band 4: %s" % Talk.pick("nana", st))
	check(Talk.pick("nana", st.merged({"band": 5, "flags": {"heart_nana_5": true}}, true)).begins_with("stars"), "the star lines after the band 5 scene")
	check(not Talk.pick("nana", st.merged({"band": 6}, true)).begins_with("stars"), "no star lines before the scene")
	check(Talk.pick("nana", st.merged({"birthday": true}, true)) == "birthday" and Talk.has_line("nana", "gift_birthday"), "birthday lines")
	check(Talk.pick("nana", st.merged({"band": 1, "weekday": "sun"}, true)) != "forage_spring" and Talk.pick("nana", st.merged({"band": 2, "weekday": "sun"}, true)) == "forage_spring",
		"forage lines from band 2, like the other friends")
	for at in ["nana_pond", "nana_legs"]:
		var d := DialogueRunner.open("heart_events", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	for at in ["nana_steady", "nana_beside"]:
		var d := DialogueRunner.open("heart_events_5", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	# Band 5's answers leave a mark that band 6 looks back on; band 6 has both answers' lines and sets nana_sky.
	var nana5 := FileAccess.get_file_as_string("res://data/dialogue/heart_events_5.json")
	check('"set": {"nana_steady": true}' in nana5 and '"set": {"nana_beside": true}' in nana5, "Nana's band 5 answers set nana_steady / nana_beside")
	for at in ["nana_near", "nana_field", "nana_end"]:
		var d := DialogueRunner.open("heart_events_6", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	check("nana_sky" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_nana_6.json") and "nana_star" in FileAccess.get_file_as_string("res://data/dialogue/heart_events_6.json"), "Nana's band 6 sets nana_sky and the star's place")
	check(Talk.pick("nana", st.merged({"band": 6, "flags": {"heart_nana_5": true, "heart_nana_6": true}}, true)).begins_with("dear"), "Nana's dear lines after the band 6 scene")
	check(not Talk.pick("nana", st.merged({"band": 5, "flags": {"heart_nana_5": true, "heart_nana_6": true}}, true)).begins_with("dear"), "no dear lines below band 6")
	check("seeds:corn" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_nana.json"), "Nana gives corn seed at band 3")
	check("\"cucumber\"" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_nana_5.json"), "and cucumbers at band 5")
	check("'Nana's birthday.'" in DialogueRunner.open("examine_house", {}, "fall_birthday").text(), "the calendar names Nana's birthday")
	check(Ending.friend({"nana": int(Affection.rules().bands[5]), "haru": int(Affection.rules().bands[4])}) == "nana", "Nana can close the record")
	check("ending_friend_nana" in FileAccess.get_file_as_string(EventRunner.DIR + "ending.json") and DialogueRunner.open("ending", {}, "nana").error == "", "the ending has a part and lines for Nana")
	var g := _game()
	g.affection.add("nana", int(Affection.rules().bands[int(Ending.data().neighbour_band)]))
	check(g.ending_values().neighbours_known == 0 and g.ending_values().heart_bands >= 1, "Nana is a friend (a heart band), not a neighbour")


## Kiku of Minamino is a friend too: a birthday (winter 25) and its day plan (the shrine in the
## morning, her hearth after), close lines, the bell lines after her band 5 scene, the answers in
## her scenes, the seed and the daikon she gives, a place at the end of the record and the
## Neighbours row down to Dr. Yae alone.
func _kiku_friend() -> void:
	var v: Dictionary = Villagers.all().kiku
	check(Villagers.friends().has("kiku") and v.get("hearts", true) != false, "Kiku has hearts now")
	check(v.birthday.season == "winter" and int(v.birthday.day) == 25, "Kiku's birthday is winter 25")
	var winter := {"year": 1, "season": "winter", "day": 25, "weekday": "thu", "weather": "sunny", "flags": {}, "festival": ""}
	Villagers.reset_day()
	var w := Villagers.where("kiku", 9 * 60 + 30, winter)
	check(w.get("map", "") == "minamino" and Vector2i(w.get("pos", Vector2.ZERO).floor()) == Vector2i(2, 9), "on her birthday Kiku bows at the water shrine in the morning (%s)" % [w])
	check(Villagers.is_on("kiku", "kiku_house", 7 * 60, winter) and Villagers.is_on("kiku", "kiku_house", 15 * 60, winter) and Villagers.is_on("kiku", "kiku_house", 18 * 60, winter),
		"home early and from the shrine on, her hearth till bed")
	Villagers.reset_day()
	check(Villagers.where("kiku", 15 * 60 + 30, winter.merged({"day": 24}, true)).get("map", "") == "minamino", "the day before she is out in the orchard at half past three")
	var st := {"year": 1, "season": "spring", "day": 3, "weekday": "wed", "time": 15 * 60 + 30, "weather": "sunny",
		"flags": {}, "festival": "", "band": 4, "again": false, "birthday": false, "day_number": 0}
	check(Talk.pick("kiku", st) in ["close_1", "close_2"] and not Talk.pick("kiku", st.merged({"band": 3}, true)) in ["close_1", "close_2"], "close lines from band 4: %s" % Talk.pick("kiku", st))
	check(Talk.pick("kiku", st.merged({"band": 5, "flags": {"heart_kiku_5": true}}, true)).begins_with("bell"), "the bell lines after the band 5 scene")
	check(not Talk.pick("kiku", st.merged({"band": 6}, true)).begins_with("bell"), "no bell lines before the scene")
	check(Talk.pick("kiku", st.merged({"birthday": true}, true)) == "birthday" and Talk.has_line("kiku", "gift_birthday"), "birthday lines")
	check(Talk.pick("kiku", st.merged({"band": 1, "weekday": "fri"}, true)) != "forage_spring" and Talk.pick("kiku", st.merged({"band": 2, "weekday": "fri"}, true)) == "forage_spring",
		"forage lines from band 2, like the other friends")
	for at in ["kiku_glad", "kiku_honest"]:
		var d := DialogueRunner.open("heart_events", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	for at in ["kiku_miss", "kiku_glad"]:
		var d := DialogueRunner.open("heart_events_5", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	var kiku5 := FileAccess.get_file_as_string("res://data/dialogue/heart_events_5.json")
	check('"set": {"kiku_miss": true}' in kiku5 and '"set": {"kiku_glad": true}' in kiku5, "Kiku's band 5 answers set kiku_miss / kiku_glad")
	for at in ["kiku_door", "kiku_edge", "kiku_end"]:
		var d := DialogueRunner.open("heart_events_6", {}, at)
		check(d.error == "" and d.text() != "", "%s has its line" % at)
	check("kiku_graft" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_kiku_6.json") and "kiku_scion" in FileAccess.get_file_as_string("res://data/dialogue/heart_events_6.json"), "Kiku's band 6 sets kiku_graft and the twig's place")
	check(Talk.pick("kiku", st.merged({"band": 6, "flags": {"heart_kiku_5": true, "heart_kiku_6": true}}, true)).begins_with("dear"), "Kiku's dear lines after the band 6 scene")
	check(not Talk.pick("kiku", st.merged({"band": 5, "flags": {"heart_kiku_5": true, "heart_kiku_6": true}}, true)).begins_with("dear"), "no dear lines below band 6")
	check("seeds:daikon" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_kiku.json"), "Kiku gives daikon seed at band 3")
	check("\"daikon\"" in FileAccess.get_file_as_string(EventRunner.DIR + "heart_kiku_5.json"), "and daikon at band 5")
	check("'Kiku's birthday.'" in DialogueRunner.open("examine_house", {}, "winter_birthday").text(), "the calendar names Kiku's birthday")
	check(Ending.friend({"kiku": int(Affection.rules().bands[5]), "haru": int(Affection.rules().bands[4])}) == "kiku", "Kiku can close the record")
	check("ending_friend_kiku" in FileAccess.get_file_as_string(EventRunner.DIR + "ending.json") and DialogueRunner.open("ending", {}, "kiku").error == "", "the ending has a part and lines for Kiku")
	var g := _game()
	g.affection.add("kiku", int(Affection.rules().bands[int(Ending.data().neighbour_band)]))
	check(g.ending_values().neighbours_known == 0 and g.ending_values().heart_bands >= 1, "Kiku is a friend (a heart band), not a neighbour")


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
	for id in Villagers.friends():
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
	for id in Villagers.friends():
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


# --- marriage (data/marriage.json, Marriage) ----------------------------------------

## The data, the rules for the knot in their order, the wedding day past festivals, the
## morning it is due and the trigger rows that play the wedding in the village.
func _marriage_rules() -> void:
	check(Marriage.check() == "", "marriage data: %s" % Marriage.check())
	check(Marriage.candidates() == ["sayo", "fumi", "haru", "ichiro", "mio", "kaede", "shino", "ren"] and Marriage.item() == "keep:mizuhiki", "all eight can marry: Sayo, Fumi, Haru, Ichiro, Mio, Kaede, Shino and Ren; the knot is %s" % Marriage.item())
	check(Keepsakes.name_of(Marriage.item()) == "Mizuhiki knot" and Keepsakes.keepsake(Marriage.item()).look.shape == "knot", "the knot is a keepsake of its own look")
	var art := PlaceholderArt.tex(PlaceholderArt.item_key(Marriage.item()))
	check(art != null and art.get_width() == 14, "the knot has its icon")
	var seen := {"heart_sayo_6": true}
	var room := ["room"]
	check(Marriage.answer("tome", 6, {}, seen, room) == "not_candidate" and Marriage.answer("kota", 6, {}, seen, room) == "not_candidate", "Tome and Kota can't be asked")
	check(Marriage.answer("sayo", 5, {}, seen, room) == "band", "band 5: not yet")
	check(Marriage.answer("sayo", 6, {}, {}, room) == "band", "band 6 without her band 6 scene: not yet")
	check(Marriage.answer("sayo", 6, {}, seen, ["kitchen"]) == "room", "no second room: ask again once it's built")
	check(Marriage.answer("sayo", 6, {}, seen, room) == "", "band 6, her scene seen, the room built: yes")
	check(Marriage.answer("sayo", 6, {"engaged": "sayo"}, seen, room) == "waiting", "already promised to her: wait for the shrine")
	check(Marriage.answer("sayo", 6, {"engaged": "fumi"}, seen, room) == "taken", "promised to Fumi: Sayo says no")
	check(Marriage.answer("sayo", 6, {"spouse": "sayo"}, seen, room) == "married", "married to her: one promise is plenty")
	check(Marriage.answer("fumi", 6, {"spouse": "sayo"}, {"heart_fumi_6": true}, room) == "taken", "married to Sayo: Fumi says no")
	check(Marriage.answer("sayo", 2, {"spouse": "fumi"}, {}, []) == "taken", "being married is the first answer, before the band")
	# Three days on, past festival days.
	var none := func(_n: int) -> bool: return false
	check(Marriage.wedding_day(10, none) == 13, "the wedding three days after the proposal (%d)" % Marriage.wedding_day(10, none))
	check(Marriage.wedding_day(10, func(n: int) -> bool: return n == 13 or n == 14) == 15, "moved past festival days")
	# The morning it is due, and every morning after until the wedding has played.
	var f := {}
	Marriage.engage(f, "sayo", 10, none)
	check(f.engaged == "sayo" and f.engaged_sayo == true and f.wedding_day == 13, "engaged flags %s" % [f])
	check(not Marriage.day_start(f, 12) and not f.has(Marriage.DUE) and Marriage.day_tag(f) == "", "not due the day before")
	check(Marriage.day_start(f, 13) and f.wedding_due == true and Marriage.day_tag(f) == "Wedding day", "due on the day, with the HUD tag")
	check(Marriage.day_start(f, 14), "still due the day after if missed")
	check(not Marriage.day_start({"spouse": "sayo"}, 20), "nothing due once married")
	# The village plays it from 10:00 on a day it is due, the bride's own one.
	var t := EventTriggers.open("town")
	check(t.error == "", "triggers_town: %s" % t.error)
	var s := {"year": 1, "season": "spring", "day": 14, "weekday": "sun", "time": 600, "weather": "sunny",
		"flags": {"wedding_due": true, "engaged": "sayo", "engaged_sayo": true}, "seen": {}, "cell": Vector2i(2, 10), "hearts": {}}
	check(t.pick("enter", s) == "wedding_sayo" and t.pick("minute", s) == "wedding_sayo", "walking in at 10:00 plays Sayo's wedding")
	check(t.pick("enter", s.merged({"time": 9 * 60 + 59}, true)) == "", "not before 10:00")
	check(t.pick("enter", s.merged({"flags": {"engaged": "sayo", "engaged_sayo": true}}, true)) == "", "not before the day")
	check(t.pick("enter", s.merged({"seen": {"wedding_sayo": true}}, true)) == "", "once")
	check(t.pick("enter", s.merged({"flags": {"wedding_due": true, "engaged": "fumi", "engaged_fumi": true}}, true)) == "wedding_fumi", "Fumi's for Fumi")
	check(t.pick("enter", s.merged({"flags": {"wedding_due": true, "engaged": "haru", "engaged_haru": true}}, true)) == "wedding_haru", "Haru's for Haru")
	var guests := FileAccess.get_file_as_string(EventRunner.DIR + "wedding_haru.json")
	check(guests.contains('"who": "genzo"') and guests.contains('"at": "haru_wedding"'), "Genzo of Kaminoda is at Haru's wedding")
	check(t.pick("enter", s.merged({"flags": {"wedding_due": true, "engaged": "ichiro", "engaged_ichiro": true}}, true)) == "wedding_ichiro", "Ichiro's for Ichiro")
	guests = FileAccess.get_file_as_string(EventRunner.DIR + "wedding_ichiro.json")
	check(guests.contains('"who": "fumi"') and guests.contains('"at": "ichiro_wedding"') and guests.count('"who": "ichiro", "at"') == 1, "Fumi is at Ichiro's wedding, Ichiro placed once")
	check(t.pick("enter", s.merged({"flags": {"wedding_due": true, "engaged": "mio", "engaged_mio": true}}, true)) == "wedding_mio", "Mio's for Mio")
	guests = FileAccess.get_file_as_string(EventRunner.DIR + "wedding_mio.json")
	check(guests.contains('"who": "hachiro"') and guests.contains('"at": "mio_wedding"') and guests.count('"who": "mio", "at"') == 1, "Hachiro is at Mio's wedding, Mio placed once")
	check(t.pick("enter", s.merged({"flags": {"wedding_due": true, "engaged": "kaede", "engaged_kaede": true}}, true)) == "wedding_kaede", "Kaede's for Kaede")
	guests = FileAccess.get_file_as_string(EventRunner.DIR + "wedding_kaede.json")
	check(guests.contains('"who": "nana"') and guests.contains('"at": "kaede_wedding"') and guests.count('"who": "kaede", "at"') == 1, "Nana is at Kaede's wedding, Kaede placed once")
	check(t.pick("enter", s.merged({"flags": {"wedding_due": true, "engaged": "shino", "engaged_shino": true}}, true)) == "wedding_shino", "Shino's for Shino")
	guests = FileAccess.get_file_as_string(EventRunner.DIR + "wedding_shino.json")
	check(guests.contains('"who": "kiku"') and guests.contains('"at": "shino_wedding"') and guests.count('"who": "shino", "at"') == 1, "Kiku is at Shino's wedding, Shino placed once")
	check(t.pick("enter", s.merged({"flags": {"wedding_due": true, "engaged": "ren", "engaged_ren": true}}, true)) == "wedding_ren", "Ren's for Ren")
	guests = FileAccess.get_file_as_string(EventRunner.DIR + "wedding_ren.json")
	check(guests.contains('"who": "genzo"') and guests.contains('"at": "ren_wedding"') and guests.count('"who": "ren", "at"') == 1, "Genzo is at Ren's wedding, Ren placed once")
	# Every candidate's scenes run and set what they say.
	for id in Marriage.candidates():
		for kind in ["propose", "wedding"]:
			check(EventRunner.open(Marriage.event(kind, id), null).error == "", "%s runs" % Marriage.event(kind, id))
	var tables := {"fumi": ["town", "teahouse", "sakurazaka"], "haru": ["town", "kaminoda", "hill", "haru_house"], "ichiro": ["town", "sakurazaka"], "mio": ["town", "river", "mio_hut"], "kaede": ["town", "minamino", "kaede_house"], "shino": ["town", "minamino", "shino_house", "river"], "ren": ["town", "post_office", "sakurazaka", "kaminoda", "minamino", "river"]}
	for id in tables:
		for m in tables[id]:
			check(("heart_%s_6" % id) in FileAccess.get_file_as_string(EventRunner.DIR + "triggers_%s.json" % m), "%s's band 6 scene on %s" % [id, m])


## The spouse's married day plans (at the farmhouse mornings and evenings, their own work in
## between) and lines (engaged, at home, out), and Tome's word about the knot.
func _married_plans_and_lines() -> void:
	var day := {"year": 1, "season": "summer", "day": 3, "weekday": "wed", "weather": "sunny", "flags": {"married_sayo": true}, "festival": ""}
	Villagers.reset_day()
	check(Villagers.where("sayo", 7 * 60, day).map == "house" and Vector2i(Villagers.where("sayo", 7 * 60, day).pos.floor()) == Vector2i(9, 3),
		"married, Sayo wakes at the farmhouse, by the kotatsu (%s)" % [Villagers.where("sayo", 7 * 60, day)])
	check(Villagers.is_on("sayo", "store", 12 * 60, day) and Villagers.is_on("sayo", "house", 19 * 60, day) and Villagers.where("sayo", 22 * 60, day).map == "away",
		"keeps the store by day, home at the farmhouse in the evening, in bed by 21:00")
	check(Talk.keeper_shop("sayo", "house", Vector2i(9, 3)) == "", "at the farmhouse she is not keeping the store")
	var sun := day.merged({"weekday": "sun"}, true)
	Villagers.reset_day()
	check(Villagers.is_on("sayo", "house", 10 * 60, sun) and Villagers.is_on("sayo", "tome_house", 13 * 60, sun), "a Sunday at home, tea at Tome's")
	var fest := day.merged({"season": "spring", "day": Festivals.get_festival("blossom_day").get("day", 1), "festival": "blossom_day"}, true)
	Villagers.reset_day()
	check(Villagers.where("sayo", 14 * 60, fest).map == "town", "a festival still takes her to the village")
	var single := day.merged({"flags": {}}, true)
	Villagers.reset_day()
	check(Villagers.where("sayo", 7 * 60, single).map == "sayo_house", "single, Sayo wakes in her own rooms")
	var fday := day.merged({"flags": {"married_fumi": true}}, true)
	Villagers.reset_day()
	check(Villagers.is_on("fumi", "house", 7 * 60, fday) and Villagers.is_on("fumi", "teahouse", 10 * 60, fday) and Villagers.is_on("fumi", "house", 19 * 60, fday),
		"married, Fumi pours at the teahouse by day and comes home to the farmhouse")
	Villagers.reset_day()
	check(Villagers.is_on("fumi", "teahouse", 14 * 60, fday.merged({"weather": "rain"}, true)) and Villagers.is_on("fumi", "house", 7 * 60, fday.merged({"weather": "rain"}, true)),
		"a wet day at the counter, from the farmhouse")
	var hday := day.merged({"flags": {"married_haru": true}}, true)
	Villagers.reset_day()
	check(Villagers.is_on("haru", "house", 7 * 60, hday) and Villagers.is_on("haru", "kaminoda", 9 * 60, hday)
		and Villagers.is_on("haru", "hill", 15 * 60, hday) and Villagers.is_on("haru", "house", 19 * 60, hday) and Villagers.where("haru", 22 * 60, hday).map == "away",
		"married, Haru goes up to Kaminoda and the hill by day and comes home to the farmhouse")
	Villagers.reset_day()
	check(Villagers.is_on("haru", "house", 14 * 60, hday.merged({"weather": "rain"}, true)), "a wet day Haru weaves by the farmhouse kotatsu")
	Villagers.reset_day()
	check(Villagers.where("haru", 7 * 60, day.merged({"flags": {}}, true)).map == "haru_house", "single, Haru wakes in her own house")
	var iday := day.merged({"flags": {"married_ichiro": true}}, true)
	Villagers.reset_day()
	check(Villagers.is_on("ichiro", "house", 6 * 60 + 10, iday) and Villagers.is_on("ichiro", "sakurazaka", 9 * 60, iday)
		and Villagers.is_on("ichiro", "sakurazaka", 12 * 60 + 20, iday) and Villagers.is_on("ichiro", "house", 18 * 60, iday) and Villagers.where("ichiro", 21 * 60, iday).map == "away",
		"married, Ichiro cuts wood and lunches at the teahouse by day, home to the farmhouse at 17:00, asleep by 20:00")
	Villagers.reset_day()
	var iwet := iday.merged({"weather": "rain"}, true)
	check(Villagers.is_on("ichiro", "house", 6 * 60 + 30, iwet) and Villagers.is_on("ichiro", "ichiro_house", 12 * 60, iwet) and Villagers.is_on("ichiro", "house", 18 * 60, iwet),
		"a wet day Ichiro splits wood in his old entry, from the farmhouse")
	Villagers.reset_day()
	check(Villagers.where("ichiro", 6 * 60 + 10, day.merged({"flags": {}}, true)).map == "ichiro_house", "single, Ichiro wakes in his own house")
	var mday := day.merged({"flags": {"married_mio": true}}, true)
	Villagers.reset_day()
	check(Villagers.is_on("mio", "house", 6 * 60 + 10, mday) and Villagers.is_on("mio", "river", 9 * 60, mday) and Villagers.is_on("mio", "town", 14 * 60, mday)
		and Villagers.is_on("mio", "river", 16 * 60, mday) and Villagers.is_on("mio", "house", 19 * 60, mday) and Villagers.where("mio", 22 * 60, mday).map == "away",
		"married, Mio works the river and sells at the store by day, home to the farmhouse at 18:00")
	Villagers.reset_day()
	check(Villagers.is_on("mio", "house", 12 * 60, mday.merged({"weather": "rain"}, true)), "a wet day Mio mends nets by the farmhouse kotatsu")
	Villagers.reset_day()
	check(Villagers.where("mio", 6 * 60 + 10, day.merged({"flags": {}}, true)).map == "mio_hut", "single, Mio wakes in her hut")
	var kday := day.merged({"flags": {"married_kaede": true}}, true)
	Villagers.reset_day()
	check(Villagers.is_on("kaede", "house", 6 * 60 + 30, kday) and Villagers.is_on("kaede", "town", 9 * 60, kday) and Villagers.is_on("kaede", "town", 14 * 60, kday)
		and Villagers.is_on("kaede", "house", 18 * 60, kday) and Villagers.where("kaede", 22 * 60, kday).map == "away",
		"married, Kaede keeps the shrine by day, home to the farmhouse by 16:30")
	Villagers.reset_day()
	check(Villagers.is_on("kaede", "house", 12 * 60, kday.merged({"weather": "rain"}, true)), "a wet day Kaede folds charms by the farmhouse kotatsu")
	Villagers.reset_day()
	check(Villagers.where("kaede", 6 * 60 + 10, day.merged({"flags": {}}, true)).map == "kaede_house" and Villagers.is_on("kaede", "town", 9 * 60, day.merged({"flags": {}}, true)),
		"single, Kaede wakes in her house in Minamino and sweeps the shrine by 9:00")
	var shday := day.merged({"flags": {"married_shino": true}}, true)
	Villagers.reset_day()
	check(Villagers.is_on("shino", "house", 6 * 60 + 30, shday) and Villagers.is_on("shino", "minamino", 9 * 60, shday) and Villagers.is_on("shino", "shino_house", 12 * 60, shday)
		and Villagers.is_on("shino", "minamino", 14 * 60, shday) and Villagers.is_on("shino", "house", 18 * 60, shday) and Villagers.where("shino", 22 * 60, shday).map == "away",
		"married, Shino works her vats in Minamino by day, lunch at the dye house, home to the farmhouse by 16:45")
	Villagers.reset_day()
	check(Villagers.is_on("shino", "house", 12 * 60, shday.merged({"weather": "rain"}, true)), "a wet day Shino sews by the farmhouse kotatsu")
	Villagers.reset_day()
	var sh1 := day.merged({"flags": {}}, true)
	check(Villagers.where("shino", 6 * 60 + 10, sh1).map == "shino_house" and Villagers.is_on("shino", "minamino", 9 * 60, sh1) and Villagers.is_on("shino", "river", 13 * 60, sh1),
		"single, Shino wakes in her dye house, works the vats by 9:00 and rinses at the river at 13:00")
	var rday := day.merged({"flags": {"married_ren": true}}, true)
	Villagers.reset_day()
	var on_round := [[6 * 60 + 30, "house"], [7 * 60 + 30, "post_office"], [9 * 60, "town"], [10 * 60, "sakurazaka"], [11 * 60 + 20, "kaminoda"], [12 * 60 + 30, "post_office"],
		[13 * 60 + 40, "river"], [14 * 60 + 20, "minamino"], [16 * 60, "post_office"], [18 * 60, "house"]]
	var round_ok: bool = Villagers.where("ren", 22 * 60, rday).map == "away"
	for at in on_round:
		round_ok = round_ok and Villagers.is_on("ren", at[1], at[0], rday)
	check(round_ok, "married, Ren leaves the farmhouse for the post office and walks his round through every part, home by 17:45")
	Villagers.reset_day()
	check(Villagers.is_on("ren", "sakurazaka", 10 * 60, rday.merged({"weather": "rain"}, true)), "the post goes out in the rain too")
	Villagers.reset_day()
	var r1 := day.merged({"flags": {}}, true)
	check(Villagers.where("ren", 6 * 60 + 10, r1).map == "post_office" and Villagers.is_on("ren", "kaminoda", 11 * 60 + 20, r1)
		and Villagers.is_on("ren", "town", 12 * 60, r1.merged({"weekday": "sun"}, true)),
		"single, Ren wakes in the post office, is in Kaminoda by 11:20 and by the pond on a Sunday")
	Villagers.reset_day()
	# Their lines: engaged, then married at home (morning, evening) and out.
	var st := {"year": 1, "season": "summer", "day": 3, "weekday": "wed", "time": 7 * 60, "weather": "sunny",
		"festival": "", "band": 6, "again": false, "birthday": false, "day_number": 0, "map": "house"}
	for id in Marriage.candidates():
		var wed := {"married_" + id: true, "spouse": id, "heart_%s_6" % id: true}
		check(Talk.pick(id, st.merged({"flags": wed}, true)).begins_with("wed_morning"), "%s at home in the morning" % id)
		check(Talk.pick(id, st.merged({"flags": wed, "time": 20 * 60}, true)).begins_with("wed_evening"), "%s at home in the evening" % id)
		check(Talk.pick(id, st.merged({"flags": wed, "time": 15 * 60 + 30, "map": "sakurazaka"}, true)).begins_with("wed_out"), "%s out of the house" % id)
		check(Talk.pick(id, st.merged({"flags": {"engaged_" + id: true, "heart_%s_6" % id: true}, "map": "town"}, true)).begins_with("engaged"), "%s engaged" % id)
		check(not Talk.pick(id, st.merged({"flags": {"married_" + id: true}, "again": true}, true)).begins_with("wed"), "%s: talked twice, the again lines" % id)
		var seen := {}
		for n in 3:
			seen[Talk.pick(id, st.merged({"flags": wed, "day_number": n}, true))] = true
		check(seen.size() == 3, "%s's married morning lines take turns" % id)
		for why in Marriage.REASONS:
			check(DialogueRunner.open(Marriage.dialogue(), {}, "%s_%s" % [id, why]).error == "", "%s answers %s" % [id, why])
	var fri := st.merged({"weekday": "fri", "map": "town", "time": 10 * 60, "band": 3}, true)
	check(Talk.pick("tome", fri.merged({"flags": {"heart_sayo_6": true}}, true)) == "knot_hint", "Tome tells of the knot on a Friday once Sayo's band 6 scene is seen")
	check(Talk.pick("tome", fri.merged({"flags": {"heart_fumi_6": true}}, true)) == "knot_hint", "or Fumi's")
	check(Talk.pick("tome", fri.merged({"flags": {"heart_haru_6": true}}, true)) == "knot_hint", "or Haru's")
	check(Talk.pick("tome", fri.merged({"flags": {"heart_ichiro_6": true}}, true)) == "knot_hint", "or Ichiro's")
	check(Talk.pick("tome", fri.merged({"flags": {"heart_mio_6": true}}, true)) == "knot_hint", "or Mio's")
	check(Talk.pick("tome", fri.merged({"flags": {"heart_kaede_6": true}}, true)) == "knot_hint", "or Kaede's")
	check(Talk.pick("tome", fri.merged({"flags": {"heart_shino_6": true}}, true)) == "knot_hint", "or Shino's")
	check(Talk.pick("tome", fri.merged({"flags": {"heart_ren_6": true}}, true)) == "knot_hint", "or Ren's")
	var rst := st.merged({"map": "town", "time": 15 * 60}, true)
	check(Talk.pick("ren", rst.merged({"flags": {"heart_ren_6": true}}, true)).begins_with("dear"), "Ren's dear lines while single")
	check(not Talk.pick("ren", rst.merged({"flags": {"heart_ren_6": true, "married_ren": true}}, true)).begins_with("dear"), "not once married")
	var shst := st.merged({"map": "minamino", "time": 15 * 60}, true)
	check(Talk.pick("shino", shst.merged({"flags": {"heart_shino_6": true}}, true)).begins_with("dear"), "Shino's dear lines while single")
	check(not Talk.pick("shino", shst.merged({"flags": {"heart_shino_6": true, "married_shino": true}}, true)).begins_with("dear"), "not once married")
	var kst := st.merged({"map": "town", "time": 15 * 60}, true)
	check(Talk.pick("kaede", kst.merged({"flags": {"heart_kaede_6": true}}, true)).begins_with("dear"), "Kaede's dear lines while single")
	check(not Talk.pick("kaede", kst.merged({"flags": {"heart_kaede_6": true, "married_kaede": true}}, true)).begins_with("dear"), "not once married")
	var mst := st.merged({"map": "river", "time": 15 * 60}, true)
	check(Talk.pick("mio", mst.merged({"flags": {"heart_mio_6": true}}, true)).begins_with("dear"), "Mio's dear lines while single")
	check(not Talk.pick("mio", mst.merged({"flags": {"heart_mio_6": true, "married_mio": true}}, true)).begins_with("dear"), "not once married")
	var ist := st.merged({"map": "sakurazaka", "time": 15 * 60}, true)
	check(Talk.pick("ichiro", ist.merged({"flags": {"heart_ichiro_6": true}}, true)).begins_with("dear"), "Ichiro's dear lines while single")
	check(not Talk.pick("ichiro", ist.merged({"flags": {"heart_ichiro_6": true, "married_ichiro": true}}, true)).begins_with("dear"), "not once married")
	var hst := st.merged({"map": "kaminoda", "time": 10 * 60}, true)
	check(Talk.pick("haru", hst.merged({"flags": {"heart_haru_6": true}}, true)).begins_with("dear"), "Haru's dear lines while single")
	check(not Talk.pick("haru", hst.merged({"flags": {"heart_haru_6": true, "married_haru": true}}, true)).begins_with("dear"), "not once married")
	check(Talk.pick("tome", fri.merged({"flags": {"heart_sayo_6": true, "engaged": "sayo"}}, true)) != "knot_hint", "not once engaged")
	check(Talk.pick("tome", fri.merged({"flags": {"spouse": "sayo"}}, true)) == "newlyweds", "a word for the newly married")
	check(Talk.pick("tome", fri.merged({"flags": {}}, true)) != "knot_hint", "nothing about it before")


## The spouse's morning help (data/marriage.json help): the watering cap on fair days only,
## dry unripe crops only, the coop's feed box topped up to the cap from the stock, and nothing
## for a single farmer (or one only engaged).
func _spouse_help_rules() -> void:
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var h: Dictionary = Marriage.data().get("help", {})
	var cap := int(h.get("water", 0))
	var feed_cap := int(h.get("feed", 0))
	check(cap > 0 and cap < 9 and feed_cap > 0 and feed_cap < 6, "help is modest: fewer plots than a seed bag, under a full coop (%d, %d)" % [cap, feed_cap])
	check("sunny" in h.get("weather", []) and not "rain" in h.get("weather", []), "help waters on sunny days, not in the rain")
	var make := func() -> FarmGrid:
		var f := FarmGrid.new(crops)
		for c in [Vector2i(10, 10), Vector2i(13, 10)]:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					f.till(c + Vector2i(dx, dy))
			f.sow(c, "turnip", "spring")
		f.till(Vector2i(20, 15))   # tilled, nothing sown: not watered
		return f
	var flock := Animals.new()
	flock.start()
	for i in 3:
		flock.add("chicken")
	var hens := flock.in_home("coop").size()
	var stock := flock.stock_of("coop")
	var wed := {"spouse": "sayo", "married_sayo": true}
	# Single, or only engaged: nothing.
	var f: FarmGrid = make.call()
	for flags in [{}, {"engaged": "sayo", "engaged_sayo": true}, {"spouse": "sayo"}]:
		var none := Marriage.help(flags, f, flock, "sunny")
		check(none.watered == 0 and none.fed == 0, "no help when not married (%s)" % [flags])
	check(Marriage.help_text({"watered": 0, "fed": 0}, "Sayo") == "", "nothing done, nothing said")
	check(_wet(f) == 0 and flock.feed_box == 0 and flock.stock_of("coop") == stock, "single: the field stays dry and the feed untouched")
	# Married, a sunny morning: the cap, then the rest.
	var done := Marriage.help(wed, f, flock, "sunny")
	check(done.watered == cap and _wet(f) == cap, "the spouse waters %d plots, no more (%s)" % [cap, done])
	check(done.fed == mini(feed_cap, hens) and flock.feed_box == done.fed and flock.stock_of("coop") == stock - done.fed,
		"the coop's box gets %d portions from the farmer's stock (%s)" % [feed_cap, done])
	check("Sayo" in Marriage.help_text(done, "Sayo") and Marriage.help_text(done, "Sayo").ends_with("."), "the morning line names her: %s" % Marriage.help_text(done, "Sayo"))
	done = Marriage.help(wed, f, flock, "sunny")
	check(done.watered == mini(cap, 18 - cap) and _wet(f) == mini(18, 2 * cap), "the next call waters the next dry plots (%s)" % [done])
	check(done.fed == mini(feed_cap, hens - feed_cap) and flock.feed_box == hens, "the box topped up to one portion a hen (%d of %d)" % [flock.feed_box, hens])
	done = Marriage.help(wed, f, flock, "sunny")
	check(done.fed == 0 and Marriage.help_text({"watered": 0, "fed": 0}, "Sayo") == "", "a full box: no feed")
	check(_wet_at(f, Vector2i(20, 15)) == false, "a tilled plot with no crop is left dry")
	# Rain (and storms) water the field already: no watering, the box still.
	var g: FarmGrid = make.call()
	flock.feed_box = 0
	for w in ["rain", "storm", "snow"]:
		check(Marriage.help(wed, g, flock, w).watered == 0, "no watering on a %s day" % w)
	check(flock.feed_box == hens, "the box is filled whatever the weather")
	# Ripe crops aren't watered; an empty stock gives no feed.
	var r: FarmGrid = make.call()
	for i in r.cells.size():
		if r.cells[i].crop != "":
			r.cells[i].stage = r.ripe_stage(r.cells[i].crop)
	var empty := Animals.new()
	empty.start()
	empty.state["coop"].stock = 0
	done = Marriage.help(wed, r, empty, "sunny")
	check(done.watered == 0 and done.fed == 0, "ripe crops and an empty sack: nothing to do (%s)" % [done])
	var texts := {}
	for d in [{"watered": 1, "fed": 0}, {"watered": 0, "fed": 1}, {"watered": 1, "fed": 1}]:
		texts[Marriage.help_text(d, "Fumi")] = true
	check(texts.size() == 3 and not texts.has(""), "a line each for watered, fed and both")
	# The chore is the spouse's talk for the day: flags set by the help, cleared the next night,
	# and the talk picker names that chore's line (one of two per chore kind, Sayo and Fumi).
	var tk: FarmGrid = make.call()
	var fl := Animals.new()
	fl.start()
	for i in 2:
		fl.add("chicken")
	var tf := {"married_sayo": true, "spouse": "sayo"}
	var both := Marriage.help(tf, tk, fl, "sunny")
	check(both.watered > 0 and both.fed > 0 and tf.get("help_water", false) and tf.get("help_feed", false),
		"both chores set their flags for the day (%s)" % [both])
	var wet_day := Marriage.help(tf, make.call(), fl, "rain")
	check(wet_day.watered == 0 and not tf.has("help_water") and tf.has("help_feed") == (wet_day.fed > 0),
		"the next night's flags follow that night's chores: no watering in the rain, the feed flag only if feed went in (%s %s)" % [wet_day, tf])
	var dry := Marriage.help(tf, make.call(), fl, "rain")
	check(dry.fed == 0 and not tf.has("help_feed"), "a full box and a rainy day: no chore flags at all (%s %s)" % [dry, tf])
	for id in Marriage.candidates():
		var st := {"year": 1, "season": "spring", "day": 3, "weekday": "wed", "time": 9 * 60, "weather": "sunny",
			"festival": "", "band": 6, "again": false, "birthday": false, "day_number": 0, "map": "farm", "flags": {}}
		for chore in ["help_water", "help_feed"]:
			for n in 2:
				check(Talk.has_line(id, "%s_%d" % [chore, n + 1]), "%s has %s_%d" % [id, chore, n + 1])
		var both_f := {"married_" + id: true, "help_water": true, "help_feed": true}
		check(Talk.pick(id, st.merged({"flags": both_f}, true)).begins_with("help_water"), "%s: the watering line first when both were done" % id)
		check(Talk.pick(id, st.merged({"flags": {"married_" + id: true, "help_feed": true}}, true)).begins_with("help_feed"), "%s: the feed line when only the feed was done" % id)
		check(Talk.pick(id, st.merged({"flags": {"married_" + id: true}}, true)).begins_with("help") == false, "%s: no chore line on a day without one" % id)
		# The chore lines are for the morning only (before noon): at 10:00 the chore, at 14:00 a married line.
		check(Talk.pick(id, st.merged({"time": 10 * 60, "flags": both_f}, true)).begins_with("help_water"), "%s: at 10:00 the chore line" % id)
		check(Talk.pick(id, st.merged({"time": 14 * 60, "flags": both_f}, true)).begins_with("wed_out"), "%s: at 14:00 no chore line, a married line instead" % id)
		check(Talk.pick(id, st.merged({"flags": {"married_" + id: true, "help_water": true}, "again": true}, true)).begins_with("again"), "%s: talked twice, the again lines" % id)
	_spouse_help_beds(crops, make, fl)
	var solo := Marriage.help({}, make.call(), fl, "sunny")
	check(solo.watered == 0 and solo.fed == 0, "single: no chore flags")


## The greenhouse's beds: watered on top of the field's cap, any weather in beds_weather, only
## when handed in (built), dry planted ones, and nothing when single.
func _spouse_help_beds(crops: Dictionary, make: Callable, fl: Animals) -> void:
	var h: Dictionary = Marriage.data().get("help", {})
	var cap := int(h.get("water", 0))
	var bcap := int(h.get("water_beds", 0))
	check(bcap > 0 and bcap < 32, "the beds' share is modest: %d of 32" % bcap)
	check("rain" in h.get("beds_weather", []) and "sunny" in h.get("beds_weather", []), "beds are watered on wet days too (glass)")
	var beds := FarmGrid.new(crops, Vector2i(8, 4), true)
	for y in 4:
		for x in 8:
			beds.till(Vector2i(x, y))
	beds.sow(Vector2i(1, 1), "turnip", "spring")
	beds.sow(Vector2i(5, 1), "turnip", "spring")
	beds.till(Vector2i(7, 3))
	var wed := {"spouse": "sayo", "married_sayo": true}
	var f: FarmGrid = make.call()
	var none := Marriage.help(wed, f, fl, "sunny")
	check(none.watered == cap and _wet(beds) == 0, "no beds handed in: only the field's %d" % none.watered)
	var d := Marriage.help(wed, make.call(), fl, "sunny", beds)
	var planted := 0
	for c in beds.cells:
		if c.crop != "":
			planted += 1
	check(d.watered == cap + mini(bcap, planted) and _wet(beds) == mini(bcap, planted), "field plus beds: %d (%d beds wet of %d planted)" % [d.watered, _wet(beds), planted])
	check(not beds.cell(Vector2i(7, 3)).wet, "an empty tilled bed stays dry")
	var rain := Marriage.help(wed, make.call(), fl, "rain", FarmGrid.new(crops, Vector2i(8, 4), true))
	check(rain.watered == 0, "rain, empty beds: nothing")
	var wet_beds := FarmGrid.new(crops, Vector2i(8, 4), true)
	for x in 8:
		wet_beds.till(Vector2i(x, 0))
		wet_beds.sow(Vector2i(x, 0), "turnip", "spring")
	var r2 := Marriage.help(wed, make.call(), fl, "rain", wet_beds)
	check(r2.watered == bcap and _wet(wet_beds) == bcap, "rain: the field is left to the rain, %d beds watered" % r2.watered)
	check(wed.get("help_water", false), "beds alone set the watering chore flag")
	var single := Marriage.help({}, make.call(), fl, "sunny", wet_beds)
	check(single.watered == 0, "single: the beds are not watered")


func _wet(f: FarmGrid) -> int:
	var n := 0
	for d in f.cells:
		if d.wet:
			n += 1
	return n


func _wet_at(f: FarmGrid, c: Vector2i) -> bool:
	return bool(f.cell(c).wet)


## In the game: married, the morning help happens in Game.end_day and is told on stepping
## out; single it doesn't; after a save and load it goes on.
func _spouse_help_in_game() -> void:
	var g := _game()
	var messages := []
	g.message.connect(func(t): messages.append(t))
	g.season = g.SEASONS.find("spring")
	g.day = 3
	g.weather_tomorrow = "sunny"
	var c := Vector2i(6, 12)
	for x in range(c.x - 1, c.x + 2):
		for y in range(c.y - 1, c.y + 2):
			g.farm.cell(Vector2i(x, y)).obj = FarmGrid.Obj.NONE
			g.farm.till(Vector2i(x, y))
	check(g.farm.sow(c, "turnip", "spring") == 9, "nine turnips sown")
	g.weather_tomorrow = "sunny"
	g.end_day()
	check(g.weather_today != "sunny" or _wet(g.farm) == 0, "single: the field is dry in the morning")
	check(g.help_news == "", "single: no help news")
	g.flags["spouse"] = "sayo"
	g.flags["married_sayo"] = true
	g.weather_tomorrow = "sunny"
	g.end_day()
	var cap := int(Marriage.data().help.water)
	check(g.weather_today == "sunny" and _wet(g.farm) == cap, "married, a sunny morning: %d plots watered (%d wet)" % [cap, _wet(g.farm)])
	check(g.help_news != "" and "Sayo" in g.help_news, "the news waits: %s" % g.help_news)
	g.go_to_spawn("farm", "home")
	messages.clear()
	g.map_arrived()
	check(messages.size() > 0 and "Sayo" in messages.back(), "told on stepping out (%s)" % [messages])
	check(g.help_news == "", "told once")
	# Talking to her that day: the line for the chore done this morning.
	var said := []
	g.dialogue_requested.connect(func(id, at): said.append([id, at]))
	g.talk_to("sayo", Vector2i.DOWN)
	check(g.flags.get("help_water", false) and not said.is_empty() and said.back()[0] == "talk_sayo" and said.back()[1] in ["help_water_1", "help_water_2"],
		"talking to Sayo after the watering picks its line %s" % [said])
	# With the greenhouse built, her morning reaches the beds too; without it, never.
	var beds_cap := int(Marriage.data().help.water_beds)
	var bc := Vector2i(1, 1)
	for x in range(bc.x - 1, bc.x + 2):
		for y in range(bc.y - 1, bc.y + 2):
			g.beds().till(Vector2i(x, y))
	g.beds().sow(bc, "turnip", "winter")
	g.weather_tomorrow = "sunny"
	g.end_day()
	check(_wet(g.beds()) == 0, "greenhouse not built: the beds stay dry")
	g.house_built.append("greenhouse")
	g.weather_tomorrow = "sunny"
	g.end_day()
	check(_wet(g.beds()) == mini(beds_cap, 9) and _wet(g.farm) == cap, "greenhouse built: %d beds watered besides the field's %d" % [_wet(g.beds()), _wet(g.farm)])
	check(g.child_help_news == "", "the child's help pulls no weeds under glass")
	g.house_built.erase("greenhouse")
	# Saved and loaded, married: the help goes on.
	var path := "user://test_spouse_help.json"
	check(SaveGame.write(g, path) == "", "write the save")
	var h := _game()
	check(SaveGame.read(h, path) == "" and Marriage.spouse(h.flags) == "sayo", "married after loading")
	check(_wet(h.farm) == cap, "the watered plots are saved (%d)" % _wet(h.farm))
	h.weather_tomorrow = "sunny"
	h.end_day()
	check(h.weather_today == "sunny" and _wet(h.farm) == cap and h.help_news != "", "after loading, the next morning's help (%d wet)" % _wet(h.farm))
	SaveGame.restore({path: null, path + SaveGame.BACKUP: null, path + SaveGame.TEMP: null})
	h.new_game()


## In the game: buy the knot, the answers with the knot kept, the proposal with it given,
## the wedding three mornings on, the spouse flags, and the save.
func _marriage_in_game() -> void:
	var g := _game()
	var said := []
	var played := []
	var messages := []
	g.dialogue_requested.connect(func(id, at): said.append([id, at]))
	g.event_requested.connect(func(id): played.append(id))
	g.message.connect(func(t): messages.append(t))
	g.season = g.SEASONS.find("summer")
	g.day = 10
	g.weather_today = "sunny"
	g.hour = 10
	g.money = 5000
	var blossom := -1
	for n in 120:
		if g.festival_on_day(n) == "blossom_day":
			blossom = n
			break
	check(blossom >= 0 and Festivals.on_date("spring", blossom + 1) == "blossom_day", "Game.festival_on_day finds Blossom Day on day number %d" % blossom)
	check(Marriage.wedding_day(blossom - 3, func(n: int) -> bool: return g.festival_on_day(n) != "") == blossom + 1, "never on Blossom Day")
	var r: Dictionary = g.shop_buy("general", Marriage.item())
	check(r.get("ok", false) and g.count(Marriage.item()) == 1 and g.money == 3500, "the store sells the knot for 1500 G %s" % [r])
	g.inventory.take(Marriage.item(), 1)
	g.inventory.slots.hand[0] = {"id": Marriage.item(), "n": 1}
	# Not yet: band 5, then band 6 without the room.
	g.affection.add("sayo", int(Affection.rules().bands[5]))
	check(g.talk_to("sayo", Vector2i.DOWN) == "kept" and said.back() == ["marriage", "sayo_band"] and g.holding(), "band 5: not yet, the knot stays in hand %s" % [said.back()])
	g.affection.add("sayo", int(Affection.rules().bands[6]))
	g.events_seen["heart_sayo_6"] = true
	check(g.talk_to("sayo", Vector2i.DOWN) == "kept" and said.back() == ["marriage", "sayo_room"] and g.holding(), "no second room: ask again %s" % [said.back()])
	check(g.talk_to("tome", Vector2i.DOWN) == "kept" and messages.back() == Marriage.text("not_candidate") and g.holding(), "Tome leaves the knot in hand")
	var talks: int = said.size()
	var before: int = g.affection.of("sayo")
	g.house_built.append("room")
	check(g.talk_to("sayo", Vector2i.DOWN) == "propose" and played.back() == "propose_sayo" and not g.holding() and g.count(Marriage.item()) == 0,
		"with the room: the knot is given and the proposal plays %s" % [played])
	check(said.size() == talks and g.affection.of("sayo") == before, "a proposal is not a gift: no gift line, no gift points")
	var today: int = g.day_number()
	check(g.flags.engaged == "sayo" and g.flags.engaged_sayo and g.flags.wedding_day == today + 3, "engaged, the wedding on day %s" % [g.flags.get("wedding_day")])
	var ev := EventRunner.open("propose_sayo", g)
	ev.start(Vector2(8, 8), Vector2i.UP)
	ev.on_stage = {"sayo": {"pos": Vector2(0.5, -0.5), "facing": Vector2i.LEFT}}
	for i in 200:
		if ev.done():
			break
		ev.update(0.5)
	check(ev.done() and said.back() == ["marriage", "sayo_yes"] and ev.actors.is_empty(), "the proposal scene plays out, Sayo back to her plan")
	g.inventory.slots.hand[0] = {"id": Marriage.item(), "n": 1}
	g.talk_to("sayo", Vector2i.DOWN)
	check(said.back() == ["marriage", "sayo_waiting"], "a second knot: she said yes already")
	g.affection.add("fumi", int(Affection.rules().bands[6]))
	g.events_seen["heart_fumi_6"] = true
	g.talk_to("fumi", Vector2i.DOWN)
	check(said.back() == ["marriage", "fumi_taken"] and g.holding(), "promised to Sayo, Fumi says no")
	g.inventory.slots.hand[0] = {}
	# The mornings: due on the third.
	for n in 2:
		g.end_day()
		check(not EventRunner.is_set(g.flags, Marriage.DUE), "not due on the morning %d after" % (n + 1))
	messages.clear()
	g.end_day()
	check(EventRunner.is_set(g.flags, Marriage.DUE) and Marriage.text("due") in messages and Marriage.day_tag(g.flags) != "", "the wedding is due on the third morning, and the game says so")
	# The wedding at the shrine.
	ev = EventRunner.open("wedding_sayo", g)
	ev.start(Vector2(2.5, 10.5) * 16, Vector2i.RIGHT)
	var cast := {}
	for i in 400:
		if ev.done():
			break
		ev.update(0.5)
		for id in ev.actors:
			cast[id] = true
	check(ev.done() and said.back() == ["marriage", "sayo_wedding"], "the wedding plays out")
	check(cast.has("sayo") and cast.has("tome") and cast.size() >= 6, "Sayo, Tome and the guests are there (%s)" % [cast.keys()])
	check(Vector2i((ev.pos / 16.0).floor()) == Vector2i(18, 5), "the farmer stands before the shrine (%s)" % [ev.pos / 16.0])
	check(Marriage.spouse(g.flags) == "sayo" and EventRunner.is_set(g.flags, "married_sayo"), "married to Sayo")
	check(Marriage.engaged(g.flags) == "" and not EventRunner.is_set(g.flags, "engaged_sayo") and not EventRunner.is_set(g.flags, Marriage.DUE)
		and g.flags.get(Marriage.DAY) is int, "the engaged flags are cleared; the wedding day stays for the record")
	messages.clear()
	g.end_day()
	check(not Marriage.text("due") in messages and Marriage.day_tag(g.flags) == "", "nothing due the next morning")
	# Saved and loaded.
	var path := "user://test_marriage.json"
	check(SaveGame.write(g, path) == "", "write the save")
	var h := _game()
	check(Marriage.spouse(h.flags) == "", "a new game is single")
	check(SaveGame.read(h, path) == "" and Marriage.spouse(h.flags) == "sayo" and EventRunner.is_set(h.flags, "married_sayo"), "married after loading")
	SaveGame.restore({path: null, path + SaveGame.BACKUP: null, path + SaveGame.TEMP: null})
	h.new_game()
