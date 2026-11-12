extends SceneTree
## Headless checks for talking to villagers (Talk, Affection, the talk files in data/dialogue,
## gifts, the daily limits, affection in the save, shopkeepers, the event hooks, the bump
## delay). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_talk.gd

var failures := 0
var _frame := 0


func _init() -> void:
	_talk_files()
	_file_errors()
	_picks()
	_gift_lines()
	_reactions()
	_affection()
	_affection_save_data()
	_trigger_rows()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_talk_in_town()
		_gifts()
		_keepers()
		_save_round_trip()
		_event_hook()
		_delay_and_bump()
		_reach()
		_pass_villager()
		_talk_at_river()
		_kiku_scion()
		print("test_talk: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


## Every villager has a talk file that runs, with every pick's lines and the gift answers.
func _talk_files() -> void:
	check(Villagers.all().size() == Villagers.file_ids().size(), "every villager file loads %s" % [Villagers.all().keys()])
	for id in Villagers.all():
		var d := Talk.data(id)
		check(Talk.check(d) == "", "%s's talk file: %s" % [id, Talk.check(d)])
		var r := DialogueRunner.open(Talk.dialogue_id(id), {})
		check(r.error == "", "%s's lines run: %s" % [id, r.error])
		check(DialogueRunner.speakers().has(id), "%s can speak (speakers.json)" % id)
		for row in d.get("picks", []):
			for at in row.at:
				check(DialogueRunner.open(Talk.dialogue_id(id), {}, at).error == "", "%s line %s opens" % [id, at])
		check(not Villagers.all()[id].get("gifts", {}).is_empty(), "%s likes and dislikes something" % id)
		_portraits(id)


## Every line in a villager's talk file shows their own portrait, in a mood of its own; a loved
## gift lights the face up and a disliked or hated one doesn't.
func _portraits(id: String) -> void:
	var lines := {}
	for l in DialogueRunner.open(Talk.dialogue_id(id), {}).lines:
		if l.has("id"):
			lines[l.id] = l
		if l.has("text"):
			check(l.get("speaker", "") == id and l.has("mood") and not l.has("face"),
				"%s says %s with a mood" % [id, l.get("id", l.text)])
			check(DialogueRunner.portrait_key(l) == "portrait:%s:%s" % [id, l.get("mood", "")], "%s line %s: their portrait" % [id, l.get("id", "")])
	check(DialogueRunner.mood_of(lines.gift_love) in ["happy", "surprised"], "%s: a loved gift looks pleased" % id)
	check(DialogueRunner.mood_of(lines.gift_like) == "happy", "%s: a liked gift, a smile" % id)
	for at in ["gift_dislike", "gift_hate"]:
		check(DialogueRunner.mood_of(lines[at]) in ["sad", "angry"], "%s: %s doesn't smile" % [id, at])
	var moods := {}
	for at in lines:
		moods[DialogueRunner.mood_of(lines[at])] = true
	check(moods.size() >= 4, "%s shows at least four moods %s" % [id, moods.keys()])


func _file_errors() -> void:
	var good := {"picks": [{"if": {"band": [0, 2]}, "at": ["a"]}, {"at": ["a"]}],
		"lines": [{"id": "a", "text": "Hi."}]}
	for g in Talk.GIFT_LINES:
		good.lines.append({"id": g, "text": "Thanks."})
	check(Talk.check(good) == "", "a small talk file passes: %s" % Talk.check(good))
	var with_items: Dictionary = good.duplicate(true)
	with_items.gift_items = {"keep:daruma": "a", "food:onigiri": "a", "dish:like": "a", "keepsake:neutral": "a"}
	check(Talk.check(with_items) == "", "gift_items for a keepsake, a dish and by reaction pass: %s" % Talk.check(with_items))
	var bad := [
		["no last plain pick", func(d): d.picks.pop_back()],
		["a plain pick before the end", func(d): d.picks[0].erase("if")],
		["a pick of a missing line", func(d): d.picks[1].at = ["zz"]],
		["an unknown condition", func(d): d.picks[0].if = {"mood": 1}],
		["a band past 6", func(d): d.picks[0].if = {"band": [0, 7]}],
		["a backwards time", func(d): d.picks[0].if = {"time": ["12:00", "09:00"]}],
		["again not true / false", func(d): d.picks[0].if = {"again": 1}],
		["a bad season", func(d): d.picks[0].if = {"season": ["monsoon"]}],
		["a map with no file", func(d): d.picks[0].if = {"map": ["moon"]}],
		["no gift answer", func(d): d.lines.pop_back()],
		["gift_items not a table", func(d): d.gift_items = ["a"]],
		["a gift line for a crop", func(d): d.gift_items = {"turnip": "a"}],
		["a gift line for an unknown keepsake", func(d): d.gift_items = {"keep:kite": "a"}],
		["a gift line for a bought food", func(d): d.gift_items = {"food:sakura_mochi": "a"}],
		["a dish reaction that isn't one", func(d): d.gift_items = {"dish:adore": "a"}],
		["a gift line that is missing", func(d): d.gift_items = {"keep:daruma": "zz"}],
	]
	for b in bad:
		var d: Dictionary = good.duplicate(true)
		b[1].call(d)
		check(Talk.check(d) != "", "refused: " + b[0])
	var v: Dictionary = Villagers.all().tome.duplicate(true)
	v.gifts = {"adore": ["turnip"]}
	check(Villagers.check(v) != "", "a villager with an unknown gift reaction is refused")
	v.gifts = {"neutral": ["turnip"]}
	check(Villagers.check(v) != "", "neutral is everything not listed, not a list")
	v.gifts = {"like": []}
	check(Villagers.check(v) != "", "an empty gift list is refused")


## Keepsakes and dishes get the villager's own answer (gift_items): by the item first, then
## by kind and reaction, else the plain gift_<reaction>; every line named opens.
func _gift_lines() -> void:
	check(Talk.is_dish("food:onigiri") and not Talk.is_dish("food:sakura_mochi") and not Talk.is_dish("onigiri"),
		"a dish is a food with a recipe; a bought sweet isn't")
	check(Talk.gift_line("tome", "keep:omamori", "love") == "gift_omamori", "Tome's own line for the charm she loves")
	check(Talk.gift_line("kota", "keep:omamori", "dislike") == "gift_omamori", "and Kota's own, glum one")
	check(Talk.gift_line("tome", "keep:daruma", "neutral") == "gift_keepsake", "a keepsake with no line of its own: by its reaction")
	check(Talk.gift_line("sayo", "food:tamagoyaki", "love") == "gift_tamagoyaki", "Sayo's own line for tamagoyaki")
	check(Talk.gift_line("sayo", "food:grilled_fish", "dislike") == "gift_dish_dislike", "a fish dish she doesn't like: the dish line")
	check(Talk.gift_line("hachiro", "food:miso_soup", "like") == "gift_dish_like", "a dish he likes")
	check(Talk.gift_line("tome", "food:sakura_mochi", "love") == "gift_love", "a bought sweet isn't a dish: the plain line")
	check(Talk.gift_line("kota", "corn", "love") == "gift_love" and Talk.gift_line("kota", "carrot", "hate") == "gift_hate", "crops answer as before")
	check(Talk.gift_line("tome", "ribbon:moon_night:1", "neutral") == "gift_neutral", "a ribbon isn't a keepsake to answer")
	check(Talk.gift_line("kota", "food:milk_pudding", "hate") == "gift_milk_pudding", "an item's own line wins over any reaction")
	check(Talk.gift_line("hachiro", "keep:paper_fan", "dislike") == "gift_dislike", "no keepsake:dislike line: the plain one")
	check(Talk.gift_line("nobody", "keep:daruma", "like") == "gift_like", "no talk file: the plain line")
	var named := 0
	for id in Villagers.all():
		var items: Dictionary = Talk.data(id).get("gift_items", {})
		for k in items:
			named += 1
			check(DialogueRunner.open(Talk.dialogue_id(id), {}, items[k]).error == "", "%s's line %s for %s opens" % [id, items[k], k])
		for item in Villagers.all()[id].gifts.get("love", []):
			if item.begins_with("keep:"):
				check(items.has(item), "%s answers the keepsake they love (%s) in their own words" % [id, item])
		for r in ["love", "like", "neutral", "dislike"]:
			check(items.has("dish:" + r), "%s has a dish:%s line" % [id, r])
	check(named >= 40, "the four villagers have their own gift lines (%d)" % named)


func _state(extra := {}) -> Dictionary:
	return {"year": 1, "season": "spring", "day": 1, "weekday": "mon", "weather": "sunny", "flags": {},
		"time": 600, "band": 0, "again": false, "day_number": 0}.merged(extra, true)


## The first pick that holds names the lines; the day picks one of them.
func _picks() -> void:
	check(Talk.pick("tome", _state({"time": 450})) == "new_morning", "a stranger meets Tome in the morning")
	check(Talk.pick("tome", _state({"time": 900})) in ["new_1", "new_2"], "and later in the day")
	check(Talk.pick("tome", _state({"again": true})) in ["again_1", "again_2"], "a second talk the same day")
	check(Talk.pick("tome", _state({"band": 5})) in ["close_1", "close_2", "close_3"], "a dear friend")
	check(Talk.pick("tome", _state({"band": 2, "season": "winter"})) in ["winter_1", "winter_2"], "winter")
	check(Talk.pick("tome", _state({"band": 2, "season": "summer"})) in ["summer_1", "summer_2"], "summer")
	check(Talk.pick("tome", _state({"band": 2, "weekday": "sun"})) == "sunday", "her Sunday walk")
	var a := Talk.pick("tome", _state({"band": 2, "day_number": 0}))
	var b := Talk.pick("tome", _state({"band": 2, "day_number": 1}))
	check(a in ["spring_1", "spring_2"] and b in ["spring_1", "spring_2"] and a != b, "another line the next day (%s, %s)" % [a, b])
	check(Talk.pick("tome", _state({"band": 2, "day_number": 2})) == a, "the lines take turns")
	check(Talk.pick("sayo", _state({"band": 2, "weather": "rain"})) == "rain", "Sayo on a wet day")
	# Kota and Tome talk about the weather: rain and storm lines, two of each, a storm line of its own.
	check(Talk.pick("kota", _state({"band": 2, "weather": "rain"})) in ["rain_1", "rain_2"], "Kota on a wet day")
	check(Talk.pick("kota", _state({"band": 2, "weather": "storm"})) in ["storm_1", "storm_2"], "Kota in a storm")
	check(Talk.pick("kota", _state({"band": 2, "weather": "sunny"})) not in ["rain_1", "rain_2", "storm_1", "storm_2"], "Kota on a sunny day has no weather line")
	check(Talk.pick("tome", _state({"band": 2, "weather": "rain"})) in ["rain_1", "rain_2"], "Tome on a wet day")
	check(Talk.pick("tome", _state({"band": 2, "weather": "storm"})) in ["storm_1", "storm_2"], "Tome in a storm")
	# Snow: Kota and Tome have a snow pick of their own; a winter storm is a blizzard (snow), not thunder.
	for who in ["kota", "tome"]:
		check(Talk.pick(who, _state({"band": 2, "weather": "snow", "season": "winter"})) in ["snow_1", "snow_2"], "%s on a snowy day" % who)
		check(Talk.pick(who, _state({"band": 2, "weather": "storm", "season": "winter"})) in ["snow_1", "snow_2"], "%s in a winter blizzard" % who)
		check(Talk.pick(who, _state({"band": 2, "weather": "storm", "season": "spring"})) in ["storm_1", "storm_2"], "%s in a spring storm is still thunder" % who)
		check(Talk.pick(who, _state({"band": 2, "weather": "sunny", "season": "winter"})) in ["winter", "winter_1", "winter_2"], "%s on a dry winter day has a winter line" % who)
	# Hachiro: rain, storm and snow picks of his own, the same rules as Kota and Tome.
	check(Talk.pick("hachiro", _state({"band": 2, "weather": "rain"})) in ["rain_1", "rain_2"], "Hachiro on a wet day")
	check(Talk.pick("hachiro", _state({"band": 2, "weather": "storm"})) in ["storm_1", "storm_2"], "Hachiro in a storm")
	check(Talk.pick("hachiro", _state({"band": 2, "weather": "snow", "season": "winter"})) in ["snow_1", "snow_2"], "Hachiro on a snowy day")
	check(Talk.pick("hachiro", _state({"band": 2, "weather": "storm", "season": "winter"})) in ["snow_1", "snow_2"], "Hachiro in a winter blizzard")
	check(Talk.pick("hachiro", _state({"band": 2, "weather": "storm", "season": "spring"})) in ["storm_1", "storm_2"], "Hachiro in a spring storm is still thunder")
	check(Talk.pick("hachiro", _state({"band": 2, "weather": "sunny"})) not in ["rain_1", "rain_2", "storm_1", "storm_2", "snow_1", "snow_2"], "Hachiro on a sunny day has no weather line")
	# A weather line comes before his heart lines, as for Kota and Tome.
	check(Talk.pick("hachiro", _state({"band": 6, "flags": {"heart_hachiro_6": true}, "weather": "rain"})) in ["rain_1", "rain_2"], "Hachiro's rain line before his heart lines")
	check(Talk.pick("hachiro", _state({"band": 2, "time": 480})) in ["morning_1", "morning_2"], "Hachiro before the smithy opens")
	check(Talk.pick("kota", _state({"band": 2, "season": "summer", "time": 900})) in ["cicada_1", "cicada_2"], "Kota's summer afternoons")
	check(Talk.pick("sayo", _state({"band": 6, "flags": {"heart_sayo_6": true}, "season": "fall", "day": 15, "festival": "moon_night", "time": 1200}))
		== "festival_moon_night", "a festival line comes before the heart lines")
	check(Talk.pick("hachiro", _state({"band": 2, "season": "summer", "day": 20, "festival": "lantern_night", "time": 900})) != "festival_lantern_night",
		"but only in the festival's hours")
	check(Talk.pick("nobody", _state()) == "", "no talk file, no line")
	# Each villager with hearts talks about forage on a weekday of their own, from band 2 on.
	var forage_days := {"tome": "thu", "hachiro": "tue", "sayo": "wed", "kota": "fri", "fumi": "sat", "ichiro": "wed", "genzo": "mon", "haru": "thu", "shige": "tue", "nana": "sun", "kiku": "fri"}
	for id in forage_days:
		for s in ["spring", "summer", "fall", "winter"]:
			var day := _state({"weekday": forage_days[id], "season": s, "time": 780})
			check(Talk.pick(id, day.merged({"band": 2}, true)) == "forage_" + s, "%s's forage line in %s" % [id, s])
			check(Talk.pick(id, day.merged({"band": 5}, true)) == "forage_" + s, "%s's forage line before the close ones" % id)
			check(Talk.pick(id, day.merged({"band": 1}, true)) != "forage_" + s, "%s keeps it from a stranger" % id)
			check(Talk.pick(id, day.merged({"band": 2, "weekday": "tue" if forage_days[id] == "mon" else "mon"}, true)) != "forage_" + s, "%s only on their day" % id)
	# At the river (a fair Sunday) both fishers have lines for it, whatever the band.
	var river := _state({"weekday": "sun", "map": "river", "time": 900})
	for id in ["hachiro", "kota"]:
		check(Talk.pick(id, river.merged({"band": 2}, true)).begins_with("river_"), "%s talks about the river there" % id)
		check(Talk.pick(id, river.merged({"band": 5}, true)).begins_with("river_"), "%s's river lines come before the close ones" % id)
		check(not Talk.pick(id, river.merged({"band": 2, "map": "town"}, true)).begins_with("river_"), "%s has no river line in the village" % id)
	check(Talk.pick("kota", river.merged({"again": true}, true)) in ["again_1", "again_2"], "a second talk at the river is still the again line")


## Kiku's lines about her persimmon twig: each stage's row holds only with that stage (the
## scion key, Talk.holds), the fall row only in fall, and nothing about it before it is planted.
func _kiku_scion() -> void:
	var sapling := ["scion_sapling_1", "scion_sapling_2"]
	var young := ["scion_young_1", "scion_young_2"]
	var fall := ["scion_fall_1", "scion_fall_2"]
	var tree := ["scion_tree_1", "scion_tree_2"]
	var close_dear := ["dear_1", "dear_2", "dear_3", "close_1", "close_2"]
	var six := {"band": 6, "flags": {"heart_kiku_6": true}}
	# The twig rows take Tuesdays and Saturdays only (talk_kiku.json).
	for day in 4:
		check(Talk.pick("kiku", _state(six.merged({"scion": "sapling", "weekday": "tue", "day_number": day}, true))) in sapling, "a sapling on a Tuesday: her twig lines (day %d)" % day)
		check(Talk.pick("kiku", _state(six.merged({"scion": "young", "weekday": "sat", "day_number": day}, true))) in young, "a young tree on a Saturday (day %d)" % day)
		check(Talk.pick("kiku", _state(six.merged({"scion": "tree", "season": "fall", "weekday": "tue", "day_number": day}, true))) in fall, "a fruiting tree in fall on a Tuesday (day %d)" % day)
		check(Talk.pick("kiku", _state(six.merged({"scion": "tree", "season": "winter", "weekday": "sat", "day_number": day}, true))) in tree, "a tree in winter on a Saturday (day %d)" % day)
	check(Talk.pick("kiku", _state(six.merged({"scion": "sapling", "weekday": "tue"}, true))) == "scion_sapling_1", "the first sapling line on the first day")
	check(Talk.pick("kiku", _state(six.merged({"scion": "tree", "season": "fall", "weekday": "sat"}, true))) == "scion_fall_1", "the first fall line on the first day")
	check(Talk.pick("kiku", _state(six.merged({"scion": "young", "season": "fall", "weekday": "tue"}, true))) in young, "a young tree doesn't fruit: no fall line")
	check(Talk.pick("kiku", _state(six.merged({"scion": "sapling", "season": "fall", "weekday": "sat"}, true))) in sapling, "a sapling in fall: no fall line")
	check(Talk.pick("kiku", _state(six.merged({"scion": "", "season": "fall", "weekday": "tue"}, true))) in ["dear_1", "dear_2", "dear_3", "fall_1", "fall_2"],
		"nothing planted: no twig line in fall")
	check(Talk.pick("kiku", _state(six.merged({"scion": "", "weekday": "tue"}, true))) in ["dear_1", "dear_2", "dear_3"], "nothing planted: her heart lines")
	check(Talk.pick("kiku", _state(six.merged({"scion": "sapling", "weekday": "mon"}, true))) in ["dear_1", "dear_2", "dear_3"], "a sapling on a Monday: her heart lines, not the twig")
	var bad := Talk.data("kiku").duplicate(true)
	bad.picks.insert(0, {"if": {"scion": ["bush"]}, "at": ["plain_1"]})
	check(Talk.check(bad).begins_with("pick 0: scion needs"), "a twig stage that doesn't exist is refused (%s)" % Talk.check(bad))
	# Share: over 700 days (each day's weekday from its number, as Game does), the twig comes up
	# on about a third or less of Kiku's talks, and her close and dear lines keep every other day,
	# as they were before the twig was planted.
	var weekdays := ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
	for stage in ["sapling", "young", "tree"]:
		var twig := 0
		var cd_other := 0   # close / dear picks on the days the twig rows don't take
		var other := 0
		var cd_all := 0
		for dn in 700:
			var pick := Talk.pick("kiku", _state(six.merged({"scion": stage, "weekday": weekdays[dn % 7], "day_number": dn, "season": "spring"}, true)))
			if pick.begins_with("scion_"):
				twig += 1
			else:
				other += 1
				if pick in close_dear:
					cd_other += 1
			if pick in close_dear:
				cd_all += 1
		var share := float(twig) / 700.0
		check(share >= 0.25 and share <= 0.35, "%s: the twig comes up on about a third of talks (%.3f)" % [stage, share])
		check(cd_other == other, "%s: her close and dear lines on every other day (%d of %d)" % [stage, cd_other, other])
		check(float(cd_all) / 700.0 >= 0.65, "%s: close and dear still most of her talks (%.3f)" % [stage, float(cd_all) / 700.0])
	# After the farmer has picked a persimmon (kiku_scion_picked), a fall Tuesday or Saturday
	# brings the picked lines; before the first pick, never. They take only the twig's days.
	var picked := ["scion_picked_1", "scion_picked_2", "scion_picked_3", "scion_picked_4"]
	var fruit := {"band": 6, "flags": {"heart_kiku_6": true, "kiku_scion_picked": true}}
	for day in 4:
		check(Talk.pick("kiku", _state(fruit.merged({"scion": "tree", "season": "fall", "weekday": "tue", "day_number": day}, true))) in picked, "picked, a fall Tuesday: the picked lines (day %d)" % day)
		check(Talk.pick("kiku", _state(fruit.merged({"scion": "tree", "season": "fall", "weekday": "sat", "day_number": day}, true))) in picked, "picked, a fall Saturday (day %d)" % day)
	check(Talk.pick("kiku", _state(fruit.merged({"scion": "tree", "season": "fall", "weekday": "mon"}, true))) in ["dear_1", "dear_2", "dear_3"], "picked, a fall Monday: her heart lines")
	# Outside fall, after the pick, the twig's days bring that season's own after-the-pick lines;
	# before the pick, the usual tree lines; every other day her heart lines.
	var after := {"winter": ["scion_picked_winter_1", "scion_picked_winter_2"], "spring": ["scion_picked_spring_1", "scion_picked_spring_2"], "summer": ["scion_picked_summer_1", "scion_picked_summer_2"]}
	for sn in after:
		var n_after := 0
		var n_stray := 0
		var n_before := 0
		var n_heart := 0
		var n_other := 0
		for dn in 700:
			var wd2: String = weekdays[dn % 7]
			var p2 := Talk.pick("kiku", _state(fruit.merged({"scion": "tree", "season": sn, "weekday": wd2, "day_number": dn}, true)))
			if p2 in after[sn]:
				n_after += 1
				if not wd2 in ["tue", "sat"]:
					n_stray += 1
			else:
				n_other += 1
				if p2 in ["dear_1", "dear_2", "dear_3"]:
					n_heart += 1
			if Talk.pick("kiku", _state(six.merged({"scion": "tree", "season": sn, "weekday": wd2, "day_number": dn}, true))) in tree:
				n_before += 1
		check(n_after == 200 and n_stray == 0, "picked, %s: its own lines on the twig's days only, 2 in 7 (%d of 700, %d stray)" % [sn, n_after, n_stray])
		check(n_heart == n_other, "picked, %s: her close and dear lines on every other day (%d of %d)" % [sn, n_heart, n_other])
		check(n_before == 200, "not picked, %s: the usual tree lines as before (%d of 700)" % [sn, n_before])
		for i2 in 2:
			var seen_line := false
			for dn in 14:
				if Talk.pick("kiku", _state(fruit.merged({"scion": "tree", "season": sn, "weekday": "tue", "day_number": dn}, true))) == after[sn][i2]:
					seen_line = true
			check(seen_line, "picked, %s: line %d comes up" % [sn, i2 + 1])
	var fruit_days := 0
	var fruit_stray := 0
	var unpicked_picked := 0
	for dn in 700:
		var wd: String = weekdays[dn % 7]
		if Talk.pick("kiku", _state(fruit.merged({"scion": "tree", "season": "fall", "weekday": wd, "day_number": dn}, true))) in picked:
			fruit_days += 1
			if not wd in ["tue", "sat"]:
				fruit_stray += 1
		if Talk.pick("kiku", _state(six.merged({"scion": "tree", "season": "fall", "weekday": wd, "day_number": dn}, true))) in picked:
			unpicked_picked += 1
	check(fruit_days == 200 and fruit_stray == 0, "picked: the picked lines on the twig's days only (%d of 700, %d off the days)" % [fruit_days, fruit_stray])
	check(unpicked_picked == 0, "never picked: no picked line (%d of 700)" % unpicked_picked)
	var before := 0
	for dn in 700:
		if Talk.pick("kiku", _state(six.merged({"weekday": weekdays[dn % 7], "day_number": dn, "season": "spring"}, true))) in close_dear:
			before += 1
	check(before == 700, "unplanted: close and dear lines every talk at band 6 (%d of 700)" % before)
	# Through Game.talk_to: the stage comes from the planting day, the season from the clock.
	check(_kiku_talk(false, 0, 0) in ["dear_1", "dear_2", "dear_3"], "unplanted: no twig line (%s)" % _kiku_talk(false, 0, 0))
	check(_kiku_talk(false, 0, 2) in ["dear_1", "dear_2", "dear_3", "fall_1", "fall_2"], "unplanted in fall: no twig line")
	check(_kiku_talk(true, 0, 0) in sapling, "planted today, a Tuesday: a sapling line (%s)" % _kiku_talk(true, 0, 0))
	check(_kiku_talk(true, 130, 0) in young, "planted 130 days ago: a young tree line (%s)" % _kiku_talk(true, 130, 0))
	check(_kiku_talk(true, 250, 2) in fall, "planted 250 days ago, fall: a fruiting tree line (%s)" % _kiku_talk(true, 250, 2))
	check(_kiku_talk(true, 250, 3) in tree, "planted 250 days ago, winter: a tree line (%s)" % _kiku_talk(true, 250, 3))
	check(_kiku_talk(true, 250, 2) in fall, "fall, not picked yet: the fruit question (%s)" % _kiku_talk(true, 250, 2))
	check(_kiku_talk(true, 250, 2, true) in picked, "picked, fall, a Tuesday: the picked lines (%s)" % _kiku_talk(true, 250, 2, true))
	check(_kiku_talk(true, 250, 3, true) in after["winter"], "picked, winter, a Tuesday: the winter lines (%s)" % _kiku_talk(true, 250, 3, true))
	check(_kiku_talk(true, 250, 0, true) in after["spring"], "picked, spring, a Tuesday: the spring lines (%s)" % _kiku_talk(true, 250, 0, true))
	check(_kiku_talk(true, 250, 1, true) in after["summer"], "picked, summer, a Tuesday: the summer lines (%s)" % _kiku_talk(true, 250, 1, true))


## Kiku's line on a fresh game at 9:00 on a Tuesday of `season`, her heart at band 6 with the band
## 6 scene seen; the twig planted `age` days ago when `planted`. The line she opens with, or "".
func _kiku_talk(planted: bool, age: int, season: int, picked := false) -> String:
	var g := _game()
	var seen := _listen(g)
	g.weather_today = "sunny"
	g.hour = 9
	g.minute = 0
	g.season = season
	for d in range(1, 40):   # the first Tuesday of the season (the twig's days are Tuesdays and Saturdays)
		g.day = d
		if g.weekday() == "tue":
			break
	g.affection.add("kiku", 9999)
	g.flags["heart_kiku_6"] = true
	if planted:
		g.flags[Scion.FLAG] = "door"
		g.flags[Scion.day_flag()] = g.day_number() - age
	if picked:
		g.flags[Scion.PICKED_FLAG] = true
	g.talk_to("kiku", Vector2i.UP)
	return str(seen.said.back()[1]) if not seen.said.is_empty() else ""


func _reactions() -> void:
	check(Villagers.reaction("tome", "eggplant") == "love" and Villagers.reaction("tome", "turnip") == "like", "Tome: eggplant loved, turnips liked")
	check(Villagers.reaction("tome", "fish:dojo") == "dislike" and Villagers.reaction("tome", "medicine") == "hate", "dislike and hate")
	check(Villagers.reaction("tome", "fish:koi") == "neutral" and Villagers.reaction("tome", "seeds:turnip") == "neutral", "anything else is neutral")
	check(Villagers.reaction("hachiro", "fish:koi") == "like" and Villagers.reaction("hachiro", "fish:unagi") == "love",
		"fish:* covers every fish, a fish of its own wins")
	check(Villagers.reaction("kota", "carrot") == "hate" and Villagers.reaction("nobody", "carrot") == "neutral", "Kota and carrots")


## Points, bands, one counted talk and one gift a day.
func _affection() -> void:
	var r := Affection.rules()
	var a := Affection.new()
	check(a.of("tome") == int(r.start) and a.band("tome") == 0, "everyone starts a stranger")
	check(a.talk("tome", 3) == int(r.talk) and a.talk("tome", 3) == 0 and a.talked_on("tome", 3), "a talk counts once a day")
	check(a.talk("tome", 4) == int(r.talk) and a.of("tome") == 2 * int(r.talk), "and again the next day")
	var g := a.give("tome", "eggplant", 4)
	check(g.ok and g.reaction == "love" and g.change == int(r.gift.love), "a loved gift %s" % [g])
	g = a.give("tome", "eggplant", 4)
	check(not g.ok and g.reaction == "again" and g.change == 0, "one gift a day")
	g = a.give("kota", "carrot", 4)
	check(g.ok and g.reaction == "hate" and a.of("kota") == 0 and g.change == 0, "affection doesn't go below 0")
	a.add("sayo", 9999)
	check(a.of("sayo") == Affection.max_points() and a.band("sayo") == 6, "nor above the most")
	var starts: Array = r.bands
	check(starts.size() == 7, "7 heart bands")
	for i in starts.size():
		check(Affection.band_of(int(starts[i])) == i and (i == 0 or Affection.band_of(int(starts[i]) - 1) == i - 1),
			"band %d starts at %d" % [i, starts[i]])
	check(a.bands().size() == Villagers.all().size() and a.bands().sayo == 6, "bands() for every villager")


func _affection_save_data() -> void:
	var a := Affection.new()
	a.add("tome", 40)
	a.talk("kota", 7)
	a.give("sayo", "tomato", 7)
	var p := Affection.parse(JSON.parse_string(JSON.stringify(a.to_dict())))
	check(p[0] == "" and p[1].of("tome") == 40 and p[1].talked_on("kota", 7) and p[1].gifted_on("sayo", 7)
		and p[1].of("sayo") == int(Affection.rules().gift.love), "affection survives JSON")
	check(Affection.parse({"points": {"gone": 3}})[0] == "", "a villager whose file is gone keeps loading")
	for bad in [[], {"points": []}, {"points": {"tome": -1}}, {"points": {"tome": 9999}}, {"points": {"tome": 1.5}},
			{"talked": {"": 1}}, {"gifted": {"tome": "x"}}]:
		check(Affection.parse(bad)[0] != "", "refused affection %s" % [bad])


## Event trigger rows: the "talk" cause names who, and any row may ask for heart bands.
func _trigger_rows() -> void:
	var row := {"event": "rainy_day", "on": "talk", "who": "tome", "hearts": {"tome": [2, 6]}}
	check(EventTriggers.check_row(row) == "", "a talk row passes: %s" % EventTriggers.check_row(row))
	var s := {"year": 1, "season": "spring", "day": 1, "weekday": "mon", "time": 600, "weather": "sunny",
		"flags": {}, "seen": {}, "cell": Vector2i.ZERO, "who": "tome", "hearts": {"tome": 3}}
	check(EventTriggers.matches(row, "talk", s), "talking to Tome at band 3 plays it")
	check(not EventTriggers.matches(row, "talk", s.merged({"who": "kota"}, true)), "not for Kota")
	check(not EventTriggers.matches(row, "talk", s.merged({"hearts": {"tome": 1}}, true)), "not before band 2")
	check(not EventTriggers.matches(row, "examine", s), "not on another cause")
	for bad in [{"event": "rainy_day", "on": "talk"}, {"event": "rainy_day", "on": "enter", "who": "tome"},
			{"event": "rainy_day", "on": "talk", "who": ""}, {"event": "rainy_day", "on": "enter", "hearts": {"tome": [3, 1]}},
			{"event": "rainy_day", "on": "enter", "hearts": {"tome": [0, 7]}}, {"event": "rainy_day", "on": "enter", "hearts": []}]:
		check(EventTriggers.check_row(bad) != "", "refused row %s" % [bad])


# --- on the real Game -------------------------------------------------------

func _game() -> Node:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.events_seen = {"first_morning": true, "rainy_day": true}
	return g


func _listen(g: Node) -> Dictionary:
	var seen := {"said": [], "shops": [], "notes": []}
	g.dialogue_requested.connect(func(id, at): seen.said.append([id, at]))
	g.shop_requested.connect(func(id): seen.shops.append(id))
	g.message.connect(func(t): seen.notes.append(t))
	return seen


## Tome at the torii at 7:40: E facing her turns her round and opens her line; once a day it counts.
func _talk_in_town() -> void:
	var g := _game()
	var seen := _listen(g)
	g.hour = 7
	g.minute = 40
	g.go_to_map("town", Vector2i(18, 9), Vector2i.UP)
	var w: Dictionary = Talk.facing_villager(g.maps.current(), Vector2i(18, 9), Vector2i.UP, g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	check(w.get("id", "") == "tome", "the farmer below the torii faces Tome %s" % [w])
	check(Talk.facing_villager(g.maps.current(), Vector2i(18, 9), Vector2i.LEFT, g.day_minutes(), g.trigger_state(Vector2i.ZERO)).is_empty(),
		"nobody to the left")
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	actions.on_action("interact", Vector2i(18, 9), Vector2i.UP)
	check(seen.said == [["talk_tome", "new_morning"]], "E opens Tome's morning line %s" % [seen.said])
	check(g.affection.of("tome") == int(Affection.rules().talk), "the first talk of the day counts")
	var t: float = g.day_minutes()
	var turned: Dictionary = Villagers.where("tome", t, g.trigger_state(Vector2i.ZERO))
	check(turned.facing == Vector2i.DOWN and not turned.moving, "she turns to the farmer %s" % [turned])
	actions.on_action("interact", Vector2i(18, 9), Vector2i.UP)
	check(seen.said.size() == 2 and seen.said[1][1] in ["again_1", "again_2"], "a second talk: %s" % [seen.said])
	check(g.affection.of("tome") == int(Affection.rules().talk), "it doesn't count again")
	# She stands a moment after the talk, then her plan runs on that much later.
	var stand := float(Villagers.common().talk_turn_minutes)
	check(Villagers.where("tome", t + stand + 1.0, g.trigger_state(Vector2i.ZERO)).facing == Vector2i.UP, "then turns back to the torii")
	check(is_equal_approx(Villagers.delay_of("tome", t + stand + 1.0), stand), "the talk joined her delay")
	g.end_day()
	check(not g.affection.talked_on("tome", g.day_number()) and g.affection.of("tome") == int(Affection.rules().talk), "a new day, a new talk")


## On a fair Sunday at 14:30 Hachiro and Kota fish the river; E facing Hachiro there opens a
## river line (Game.talk_to passes the map he stands on to the pick).
func _talk_at_river() -> void:
	var g := _game()
	var seen := _listen(g)
	g.day = 7   # spring 7, the first Sunday
	g.weather_today = "sunny"
	g.hour = 14
	g.minute = 30
	g.go_to_map("river", Vector2i(10, 4), Vector2i.DOWN)
	var s: Dictionary = g.trigger_state(Vector2i.ZERO)
	var w: Dictionary = Talk.facing_villager(g.maps.current(), Vector2i(10, 4), Vector2i.DOWN, g.day_minutes(), s)
	check(g.weekday() == "sun" and w.get("id", "") == "hachiro", "the farmer on the shore above Hachiro faces him %s" % [w])
	check(g.talk_to("hachiro", Vector2i.UP) == "talk" and seen.said.size() == 1 and seen.said[0][0] == "talk_hachiro"
		and seen.said[0][1].begins_with("river_"), "Hachiro talks about the river %s" % [seen.said])
	check(not Villagers.where("hachiro", g.day_minutes(), s).fishing, "he reels in to talk")
	check(g.talk_to("kota", Vector2i.UP) == "talk" and seen.said[1][1].begins_with("river_"), "and so does Kota %s" % [seen.said])


## E with an item overhead gives it away; one gift a day, a second one stays in hand.
func _gifts() -> void:
	var g := _game()
	var seen := _listen(g)
	g.hour = 7
	g.minute = 40
	g.go_to_map("town", Vector2i(18, 9), Vector2i.UP)
	g.held = "eggplant"
	check(g.talk_to("tome", Vector2i.DOWN) == "gift", "holding an item, E is a gift")
	check(not g.holding() and seen.said.back() == ["talk_tome", "gift_love"], "she takes it and loves it %s" % [seen.said])
	check(g.affection.of("tome") == int(Affection.rules().gift.love), "affection goes up by the reaction")
	check(not g.affection.talked_on("tome", g.day_number()), "a gift isn't the day's talk")
	g.held = "medicine"
	g.talk_to("tome", Vector2i.DOWN)
	check(g.held == "medicine" and seen.said.back() == ["talk_tome", "gift_again"], "the second gift today is refused and kept")
	check(g.affection.of("tome") == int(Affection.rules().gift.love), "and changes nothing")
	g.end_day()
	g.hour = 7
	g.minute = 40
	g.talk_to("tome", Vector2i.DOWN)
	check(not g.holding() and seen.said.back() == ["talk_tome", "gift_hate"], "the next day she takes it, unhappily")
	check(g.affection.of("tome") == maxi(int(Affection.rules().gift.love) + int(Affection.rules().gift.hate), 0), "and likes the farmer less")


## Keepers: talking to Sayo across the store counter opens the store; with her out it's shut.
func _keepers() -> void:
	var g := _game()
	var seen := _listen(g)
	g.hour = 10
	g.go_to_map("store", Vector2i(3, 4), Vector2i.UP)
	var w: Dictionary = Talk.facing_villager(g.maps.current(), Vector2i(3, 4), Vector2i.UP, g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	check(w.get("id", "") == "sayo", "Sayo stands behind the counter %s" % [w])
	check(Talk.keeper_shop("sayo", "store", Vector2i(3, 2)) == "general" and Talk.keeper_shop("sayo", "town", Vector2i(3, 2)) == ""
		and Talk.keeper_shop("tome", "store", Vector2i(3, 2)) == "", "keeper_shop knows who keeps what, where")
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	actions.on_action("interact", Vector2i(3, 4), Vector2i.UP)
	check(seen.shops == ["general"] and seen.said.is_empty(), "talking to her opens the Yorozu Store %s %s" % [seen.shops, seen.said])
	check(g.affection.talked_on("sayo", g.day_number()), "and counts as the day's talk")
	g.go_to_map("smithy", Vector2i(3, 4), Vector2i.UP)
	actions.on_action("interact", Vector2i(3, 4), Vector2i.UP)
	check(seen.shops == ["general", "smithy"], "Hachiro opens the smithy %s" % [seen.shops])
	# Held back half an hour at 9:10 (a long chat outside), she isn't at the counter yet.
	g.hour = 9
	g.minute = 10
	Villagers.add_delay("sayo", g.day_minutes(), 30.0)
	check(not Villagers.is_on("sayo", "store", g.day_minutes(), g.trigger_state(Vector2i.ZERO)), "a late Sayo is still outside")
	check(not g.open_shop("general") and seen.notes.back() == "Nobody is at the counter.", "the counter is shut without its keeper")
	check(g.open_shop("general", true), "the screenshot flag still opens it")
	g.hour = 12
	g.minute = 0
	check(g.open_shop("general"), "the delay is gone at noon and she is in")
	g.held = "tomato"
	g.minute = 5
	check(g.talk_to("sayo", Vector2i.DOWN) == "gift" and seen.said.back() == ["talk_sayo", "gift_love"], "a keeper takes gifts too")


func _save_round_trip() -> void:
	var g := _game()
	g.affection.add("kota", 33)
	g.affection.talk("tome", g.day_number())
	g.affection.give("sayo", "tomato", g.day_number())
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	check(SaveGame.VERSION >= 3 and d.has("affection"), "save version 3 or later writes affection")
	g.new_game()
	check(g.affection.of("kota") == 0, "a new game forgets it")
	check(g.from_dict(d) == "" and g.affection.of("kota") == 33 and g.affection.talked_on("tome", g.day_number())
		and g.affection.gifted_on("sayo", g.day_number()), "loading puts it back, the daily limits too")
	var old := d.duplicate(true)
	old.erase("affection")
	check(g.from_dict(old, 2) == "" and g.affection.of("kota") == 0, "a version 2 save loads with everyone a stranger")
	check(g.from_dict(old, 3) != "", "a version 3 save without affection is broken")
	var broken := d.duplicate(true)
	broken.affection = {"points": {"kota": "lots"}}
	g.affection.add("tome", 5)
	check(g.from_dict(broken) != "" and g.affection.of("tome") == 5, "broken affection is refused and changes nothing")


## The event command adds affection.
func _event_hook() -> void:
	var g := _game()
	var data := {"steps": [{"do": "affection", "who": "kota", "amount": 12}, {"do": "affection", "who": "kota", "amount": -2}]}
	var r := EventRunner.new(data, g)
	check(r.error == "", "an affection step passes: %s" % r.error)
	r.start(Vector2.ZERO, Vector2i.DOWN)
	r.update(0.0)
	check(r.done() and g.affection.of("kota") == 10, "the steps add and take affection (%d)" % g.affection.of("kota"))
	for bad in [{"do": "affection", "who": "kota"}, {"do": "affection", "amount": 3}, {"do": "affection", "who": "kota", "amount": 0},
			{"do": "affection", "who": "kota", "amount": 1.5}]:
		check(EventRunner.new({"steps": [bad]}, g).error != "", "refused step %s" % [bad])


## A villager walking into the farmer waits (their delay grows, at most delay_max, cleared
## at 12:00); the farmer can't step into a villager but can step away.
func _delay_and_bump() -> void:
	var g := _game()
	var s: Dictionary = g.trigger_state(Vector2i.ZERO)
	Villagers.reset_day()
	# Tome walks east along the road at 7:05 (x 10.0, y 10.5).
	var w := Villagers.where("tome", 425.0, s)
	var farmer: Vector2 = w.pos + Vector2(0.6, 0)
	check(Villagers.bump("town", 425.0, 0.5, farmer, s) == ["tome"], "Tome bumps into the farmer ahead")
	check(is_equal_approx(Villagers.delay_of("tome", 425.0), 0.5), "and waits half a minute")
	var now: Vector2 = Villagers.where("tome", 425.0, s).pos
	check(Villagers.bump("town", 425.0, 0.5, now - Vector2(0.6, 0), s).is_empty(), "the farmer behind her doesn't stop her")
	for i in 100:   # a long wait
		Villagers.add_delay("tome", 425.0, 1.0)
	check(is_equal_approx(Villagers.delay_of("tome", 425.0), float(Villagers.common().delay_max)), "the delay stops at delay_max")
	check(Villagers.where("tome", 455.0, s).pos.is_equal_approx(w.pos), "her plan runs that much later")
	check(Villagers.delay_of("tome", 721.0) == 0.0, "cleared at 12:00")
	var at: Vector2 = Villagers.where("tome", 460.0 + 30.0, s).pos   # standing at the torii (delayed)
	check(Villagers.blocks("town", 490.0, s, at + Vector2(0, 1.0), at + Vector2(0, 0.6)), "a step into her is blocked")
	check(not Villagers.blocks("town", 490.0, s, at + Vector2(0, 0.6), at + Vector2(0, 0.65)), "a step away is not")
	check(not Villagers.blocks("town", 490.0, s, at + Vector2(0, 2.0), at + Vector2(0, 1.9)), "nor a step that stays clear")
	Villagers.reset_day()


## E without lining up to the pixel (playtest 2026-11-13): from the cell beside the one below Tome,
## feet leaning towards her, E talks to her (and the HUD says Talk); leaning away or standing in
## the middle it does not; a step short of her cell, near enough, it does.
func _reach() -> void:
	var g := _game()
	var seen := _listen(g)
	var hints: GDScript = load("res://scripts/ui/action_hints.gd")   # it reads Game: loaded once the tree runs
	g.hour = 7
	g.minute = 40
	Villagers.reset_day()
	var w := Villagers.where("tome", g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	var tc := Vector2i(w.pos.floor())
	var below := tc + Vector2i.DOWN
	var left := below + Vector2i.LEFT
	g.go_to_map("town", left, Vector2i.UP)
	var feet := Vector2(left) + Vector2(0.9, 0.5)   # leaning right, towards the cell below her
	check(hints.reach(left, Vector2i.UP, feet) == below, "reach: leaning towards her, E reaches the cell below her")
	check(hints.pick(left, Vector2i.UP, feet).interact == "Talk", "reach: and the HUD says Talk")
	check(hints.reach(left, Vector2i.UP, Vector2(left) + Vector2(0.5, 0.5)) == left, "reach: from the middle of the cell, not")
	check(hints.reach(left, Vector2i.UP, Vector2(left) + Vector2(0.1, 0.5)) == left, "reach: leaning away, not")
	g.maps.pos = feet * 16.0
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	actions.on_action("interact", left, Vector2i.UP)
	check(seen.said.size() == 1 and seen.said[0][0] == "talk_tome", "reach: E talks to her from beside %s" % [seen.said])
	# A step further off, straight below: the feet near the top of their cell, within TALK_REACH.
	var two := tc + Vector2i(0, 2)
	g.go_to_map("town", two, Vector2i.UP)
	var near := Vector2(w.pos.x, float(two.y) + 0.05)
	check(near.distance_to(w.pos) <= hints.TALK_REACH and hints.reach(two, Vector2i.UP, near) == two + Vector2i.UP,
		"reach: two cells below, the feet %.2f from her, E reaches her" % near.distance_to(w.pos))
	var far := Vector2(w.pos.x, float(two.y) + 0.9)
	check(hints.reach(two, Vector2i.UP, far) == two, "reach: from the bottom of that cell (%.2f away) it does not" % far.distance_to(w.pos))
	# A thing on the ground, too: a turnip lying up and to the right of the cell in front.
	g.go_to_map("farm", Vector2i(10, 12), Vector2i.UP)
	var f: FarmGrid = g.farm
	for c in [Vector2i(10, 11), Vector2i(11, 11), Vector2i(9, 11)]:
		f.cell(c).obj = FarmGrid.Obj.NONE
		f.take_item_at(c)
	check(f.place_item(Vector2i(11, 11), "turnip"), "reach: a turnip lies beside the cell in front")
	g.maps.pos = (Vector2(10, 12) + Vector2(0.8, 0.5)) * 16.0
	actions.on_action("interact", Vector2i(10, 12), Vector2i.UP)
	check(g.held == "turnip" and f.item_at(Vector2i(11, 11)) == "", "reach: E picks it up, leaning towards it (%s)" % g.held)
	Villagers.reset_day()


## A villager in the only way out (playtest 2026-11-13: trapped in a dead end): pushing into them
## for PASS_AFTER lets the farmer slip past; once clear of them they stop the feet again.
func _pass_villager() -> void:
	var g := _game()
	g.hour = 7
	g.minute = 40
	Villagers.reset_day()
	var w := Villagers.where("tome", g.day_minutes(), g.trigger_state(Vector2i.ZERO))
	g.go_to_map("town", Vector2i(w.pos.floor()) + Vector2i(0, 2), Vector2i.UP)
	var p: Node2D = load("res://scripts/player/player.gd").new()
	p.farm = g.farm
	var at: Vector2 = w.pos * 16.0
	p.position = at + Vector2(0, 20)
	for i in 30:
		p._try_move(Vector2(0, -1))
	check(p.position.y > at.y + 0.6 * 16.0, "pass: walking into her stops short (%.1f px below)" % (p.position.y - at.y))
	p._push_villager(Vector2.UP, Vector2(0, -1), p.PASS_AFTER * 0.5)
	check(not p.passing and not p._try_move(Vector2(0, -1)), "pass: a moment's push still stops")
	p._push_villager(Vector2.UP, Vector2(0, -1), p.PASS_AFTER * 0.6)
	check(p.passing, "pass: pushing on, the farmer may pass")
	for i in 40:
		p._try_move(Vector2(0, -1))
	check(p.position.y < at.y - 0.7 * 16.0, "pass: and walks through to the far side (%.1f px above)" % (at.y - p.position.y))
	p._end_pass()
	check(not p.passing, "pass: clear of her, villagers stop the feet again")
	p._push_villager(Vector2.DOWN, Vector2(0, 1), 0.1)
	for i in 40:
		p._try_move(Vector2(0, 1))
	check(p.position.y < at.y - 0.6 * 16.0, "pass: and walking back into her is stopped again")
	p._push_villager(Vector2.LEFT, Vector2(-1, 0), 1.0)
	check(not p.passing or g.villager_in_way(p.position, p.position + Vector2(-1, 0)), "pass: pushing where no villager stands passes nothing")
	p.free()
	Villagers.reset_day()


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
