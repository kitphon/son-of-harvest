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


func _file_errors() -> void:
	var good := {"picks": [{"if": {"band": [0, 2]}, "at": ["a"]}, {"at": ["a"]}],
		"lines": [{"id": "a", "text": "Hi."}]}
	for g in Talk.GIFT_LINES:
		good.lines.append({"id": g, "text": "Thanks."})
	check(Talk.check(good) == "", "a small talk file passes: %s" % Talk.check(good))
	var bad := [
		["no last plain pick", func(d): d.picks.pop_back()],
		["a plain pick before the end", func(d): d.picks[0].erase("if")],
		["a pick of a missing line", func(d): d.picks[1].at = ["zz"]],
		["an unknown condition", func(d): d.picks[0].if = {"mood": 1}],
		["a band past 6", func(d): d.picks[0].if = {"band": [0, 7]}],
		["a backwards time", func(d): d.picks[0].if = {"time": ["12:00", "09:00"]}],
		["again not true / false", func(d): d.picks[0].if = {"again": 1}],
		["a bad season", func(d): d.picks[0].if = {"season": ["monsoon"]}],
		["no gift answer", func(d): d.lines.pop_back()],
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
	check(Talk.pick("hachiro", _state({"band": 2, "time": 480})) in ["morning_1", "morning_2"], "Hachiro before the smithy opens")
	check(Talk.pick("kota", _state({"band": 2, "season": "summer", "time": 900})) in ["cicada_1", "cicada_2"], "Kota's summer afternoons")
	check(Talk.pick("nobody", _state()) == "", "no talk file, no line")


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
	check(not g.open_shop("general") and seen.notes.back() == "Nobody is at the counter", "the counter is shut without its keeper")
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
	check(SaveGame.VERSION == 3 and d.has("affection"), "save version 3 writes affection")
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


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
