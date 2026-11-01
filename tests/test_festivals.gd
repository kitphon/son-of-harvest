extends SceneTree
## Headless checks for festivals (data/festivals.json, Festivals, Game's festival day, shops
## shut for it, the fair weather, villagers gathering (everyone but the doctor, with festival lines), the event once a year, the decorations
## and lights in both views, the HUD tag, the contests and their result lines, the stalls and
## their wares, ribbons and the farmhouse board, the shipping payout held back on the day, the
## mochi pounding: its data, timing, ranking, prizes, ribbon, save and screen; the Moon Night
## fishing race: its data, clock, creel, ranking, prizes, ribbon, save and screen). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_festivals.gd

var failures := 0
var _frame := 0
var _scene3: Node
var _scene2: Node


func _init() -> void:
	_data()
	_calendar()
	_hours()
	_villagers()
	_crowd()
	_contest_data()
	_judging()
	_result_lines()
	_game_data()
	_mochi_timing()
	_game_judging()
	_game_result_lines()
	_race_data()
	_race_timing()
	_race_result_lines()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_fireworks()   # loads the glow script, which needs the Game autoload
		_game_day()
		_weather()
		_shops()
		_event()
		_contest_game()
		_store_note()
		_rivals()
		_game_play()
		_race_play()
		_stall()
		_night_stalls()
		_fall_winter_stalls()
		_ribbons()
		_payout()
		_flat_art()
		_start_views("spring", 8, 10, 30)
	elif _frame == 3:
		_check_views()
		_start_views("summer", 20, 20, 0)
	elif _frame == 5:
		_check_night()
		print("test_festivals: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


func _data() -> void:
	check(Festivals.error() == "", "data/festivals.json loads (%s)" % Festivals.error())
	var seasons := []
	for id in Festivals.all():
		var f := Festivals.get_festival(id)
		seasons.append(f.season)
		check(PixelFont.width(f.name) + 12 <= HudLayout.BOXES.festival.size.x, "%s fits the HUD tag" % f.name)
		check(EventRunner.open(f.event, null).error == "", "%s has its event %s" % [id, f.event])
	seasons.sort()
	check(seasons == ["fall", "spring", "summer", "winter"], "one festival per season %s" % [seasons])
	var good := {"name": "Test Day", "season": "spring", "day": 3, "hours": ["9:00", "12:00"], "map": "town",
		"place": [18, 8], "event": "festival_blossom"}
	check(Festivals.check({"festivals": {"a": good}}) == "", "a plain festival passes")
	var bad := {
		"season": {"season": "monsoon"}, "day": {"day": 31}, "hours": {"hours": ["12:00", "9:00"]},
		"map": {"map": "moon"}, "place": {"place": [17, 6]},   # the torii's left post is solid
		"event": {"event": "no_such_event"}, "closes": {"closes": ["bakery"]}, "key": {"music": "drums"},
		"prop": {"props": [{"kind": "stall", "cell": [35, 5], "size": [2, 1]}]},
		"fireworks": {"fireworks": ["20:00"]},
	}
	for what in bad:
		check(Festivals.check({"festivals": {"a": good.merged(bad[what], true)}}) != "", "a festival with a bad %s is refused" % what)
	check(Festivals.check({"festivals": {"a": good, "b": good}}) != "", "two festivals on one date are refused")
	check(Festivals.check([]) != "", "a file without festivals is refused")


func _calendar() -> void:
	check(Festivals.on_date("spring", 8) == "blossom_day", "Blossom Day is spring 8")
	check(Festivals.on_date("summer", 20) == "lantern_night" and Festivals.on_date("fall", 15) == "moon_night"
		and Festivals.on_date("winter", 30) == "years_turn", "Lantern Night summer 20, Moon Night fall 15, Year's Turn winter 30")
	check(Festivals.on_date("spring", 9) == "" and Festivals.on_date("summer", 8) == "", "other days have none")
	check(Festivals.tomorrow(0, 7) == "blossom_day" and Festivals.tomorrow(3, 29) == "years_turn", "tomorrow's festival")
	check(Festivals.tomorrow(3, 30) == "" and Festivals.tomorrow(0, 8) == "", "no festival tomorrow (winter 30 -> spring 1)")
	check(Festivals.name_of("lantern_night") == "Lantern Night" and Festivals.name_of("") == "", "names")
	check(Festivals.closes("blossom_day", "smithy") and not Festivals.closes("blossom_day", "general")
		and Festivals.closes("years_turn", "general") and not Festivals.closes("", "general"), "which shops close")
	check(Festivals.seen_key("moon_night", 2) == "festival:moon_night:2", "seen key per year")


func _hours() -> void:
	check(not Festivals.in_hours("blossom_day", 599) and Festivals.in_hours("blossom_day", 600)
		and Festivals.in_hours("blossom_day", 959) and not Festivals.in_hours("blossom_day", 960), "Blossom Day 10:00-16:00")
	check(Festivals.in_hours("years_turn", 1439) and not Festivals.in_hours("years_turn", 1139), "Year's Turn runs to midnight")
	check(Festivals.on_now("blossom_day", "town", 700) and not Festivals.on_now("blossom_day", "farm", 700), "on in the village only")
	check(Festivals.props_now("blossom_day", "town", 700).size() == 10 and Festivals.props_now("blossom_day", "town", 1000).is_empty()
		and Festivals.props_now("blossom_day", "store", 700).is_empty(), "props in the hours, on its map")
	var s := {"festival": "blossom_day", "time": 700, "year": 1, "seen": {}}
	check(Festivals.due_event("town", s) == "festival_blossom", "the event is due in the hours")
	check(Festivals.due_event("farm", s) == "" and Festivals.due_event("town", s.merged({"time": 500}, true)) == ""
		and Festivals.due_event("town", s.merged({"festival": ""}, true)) == "", "not on the farm, before the hours, or on a plain day")
	check(Festivals.due_event("town", s.merged({"seen": {"festival:blossom_day:1": true}}, true)) == ""
		and Festivals.due_event("town", s.merged({"seen": {"festival:blossom_day:1": true}, "year": 2}, true)) == "festival_blossom",
		"once a year: seen in year 1, due again in year 2")


func _villagers() -> void:
	var s := {"year": 1, "season": "spring", "day": 8, "weekday": "mon", "weather": "sunny", "flags": {}, "festival": "blossom_day"}
	var w := Villagers.where("tome", 660.0, s)
	check(w.map == "town" and w.pos == Vector2(17.5, 8.5) and w.facing == Vector2i.RIGHT, "Tome stands by the torii on a festival %s" % [w])
	check(Villagers.where("kota", 1300.0, s).map == "town", "Kota is still out at 21:40 on a festival")
	var plain := s.merged({"festival": "", "day": 9, "weekday": "tue"}, true)
	check(Villagers.where("tome", 660.0, plain).pos != Vector2(17.5, 8.5) and Villagers.where("kota", 1300.0, plain).map == "away", "a plain day has the usual plans")
	check(Villagers.check_conditions({"festival": ["no_such_festival"]}) != "" and Villagers.check_conditions({"festival": ["moon_night"]}) == "",
		"a festival rule must name a festival")


## Everyone is out at every festival: Hachiro and Sayo too, by their own festival plans, and
## the people of Kaminoda, Sakurazaka and Minamino (all but Dr. Yae, who stays by the clinic), in
## the festival's hours, each with a line for it, no two on one cell. The rivals of each
## contest are there.
func _crowd() -> void:
	var mid := {"blossom_day": 840, "lantern_night": 1200, "moon_night": 1230, "years_turn": 1290}
	for fid in Festivals.all():
		var f := Festivals.get_festival(fid)
		var s := {"year": 1, "season": f.season, "day": int(f.day), "weekday": "tue", "weather": "sunny", "flags": {}, "festival": fid}
		var cells := {}
		for who in Villagers.all():
			if who == "yae":
				check(Villagers.where(who, float(mid[fid]), s).map != f.map, "Dr. Yae stays by the clinic at %s" % fid)
				continue
			var w := Villagers.where(who, float(mid[fid]), s)
			check(w.map == f.map, "%s is out at %s at %d (%s)" % [who, fid, mid[fid], w])
			var c := Vector2i(w.pos.floor())
			check(not cells.has(c), "%s and %s on one cell %s at %s" % [who, cells.get(c, ""), c, fid])
			cells[c] = who
			var line := Talk.pick(who, {"band": 2, "again": false, "day_number": 0, "time": mid[fid]}.merged(s))
			check(line == "festival_" + fid and Talk.has_line(who, line), "%s says %s at %s (%s)" % [who, "festival_" + fid, fid, line])
			check(Talk.pick(who, {"band": 2, "again": false, "day_number": 0, "time": 400}.merged(s)) != "festival_" + fid,
				"%s's festival line only in its hours" % who)
		for r in Festivals.contest(fid).rivals:
			check(Villagers.where(r.who, float(mid[fid]), s).map == f.map, "rival %s is at %s" % [r.who, fid])
	var blossom := {"year": 1, "season": "spring", "day": 8, "weekday": "mon", "weather": "sunny", "flags": {}, "festival": "blossom_day"}
	check(Villagers.where("sayo", 660.0, blossom).map == "store" and Villagers.where("sayo", 1000.0, blossom).map == "store",
		"on Blossom Day Sayo keeps the store in the morning and after 15:45")
	check(Villagers.where("hachiro", 660.0, blossom).map == "town", "the smithy is shut: Hachiro is at the blossoms in the morning")
	# The outer parts come down the lanes: home in the morning, back after the hours.
	for who in ["genzo", "haru", "fumi", "ichiro", "shige", "nana", "kiku"]:
		check(Villagers.where(who, 420.0, blossom).map != "town" and Villagers.where(who, 1050.0, blossom).map != "town",
			"%s is in the village only for Blossom Day's hours" % who)
	var lantern := {"year": 1, "season": "summer", "day": 20, "weekday": "mon", "weather": "sunny", "flags": {}, "festival": "lantern_night"}
	check(Villagers.where("fumi", 600.0, lantern).map == "teahouse" and Villagers.where("fumi", 1110.0, lantern).map == "town",
		"Lantern Night: Fumi pours tea by day, is in the village by 18:30")
	var plain := blossom.merged({"festival": "", "day": 9, "weekday": "tue"}, true)
	check(Villagers.where("hachiro", 840.0, plain).map == "smithy" and Villagers.where("sayo", 840.0, plain).map == "store", "a plain day: both at work")
	var building := blossom.merged({"flags": {"house_work": true}}, true)
	check(Villagers.where("hachiro", 600.0, building).map == "farm", "a house job under way still comes first for Hachiro")


func _fireworks() -> void:
	check(Festivals.fireworks_now("lantern_night", 1170) and not Festivals.fireworks_now("lantern_night", 1169)
		and not Festivals.fireworks_now("blossom_day", 700), "fireworks 19:30-22:00 on Lantern Night only")
	var size := Vector2(480, 270)
	var glow: GDScript = load("res://scripts/world3d/festival_glow.gd")
	var rising: Dictionary = glow.burst(0, 0.1, size)
	check(rising.rise.size() == 3 and rising.sparks.is_empty(), "a shell climbs first")
	var open: Dictionary = glow.burst(0, 1.0, size)
	check(open.rise.is_empty() and open.sparks.size() == glow.SPARKS, "then bursts into sparks")
	check(glow.burst(0, 1.0, size) == open and glow.burst(1, 1.0, size) != open, "the same shell looks the same; the next differs")
	check(glow.burst(0, 5.0, size).sparks.is_empty() and glow.burst(0, -1.0, size).sparks.is_empty(), "over after it fades")
	for sp in open.sparks:
		if not Rect2(Vector2.ZERO, size).has_point(sp[0]):
			check(false, "spark %s off the screen" % sp[0])
	check(glow.darkness(Color.WHITE) == 0.0 and glow.darkness(Color(0.42, 0.45, 0.72)) == 1.0, "lights glow at night, not by day")


func _game() -> Node:
	return root.get_node("Game")


func _set_day(g: Node, season: String, day: int, h: int, m: int) -> void:
	g.season = g.SEASONS.find(season)
	g.day = day
	g.hour = h
	g.minute = m


## Game's festival day: today's id, in the trigger state for rules and tables.
func _game_day() -> void:
	var g := _game()
	g.new_game()
	_set_day(g, "spring", 8, 12, 0)
	check(g.festival_today() == "blossom_day" and g.trigger_state(Vector2i.ZERO).festival == "blossom_day", "Game knows today is Blossom Day")
	g.day = 9
	check(g.festival_today() == "" and g.trigger_state(Vector2i.ZERO).festival == "", "and spring 9 is a plain day")


## DESIGN: a festival day is fair; the weather rolled for it the evening before is replaced.
func _weather() -> void:
	var g := _game()
	g.new_game()
	var chances: Dictionary = g.weather_chances
	g.weather_chances = {"spring": {"storm": 1.0}, "summer": {"storm": 1.0}}
	_set_day(g, "spring", 6, 20, 0)
	g.end_day()
	check(g.day == 7 and g.weather_tomorrow == "sunny", "the eve of Blossom Day forecasts sun (%s)" % g.weather_tomorrow)
	g.end_day()
	check(g.day == 8 and g.weather_today == "sunny" and g.weather_tomorrow == "storm", "Blossom Day is sunny, the day after rolls as usual")
	g.weather_chances = chances


func _shops() -> void:
	var g := _game()
	g.new_game()
	var said: Array = []
	var hear := func(t): said.append(t)
	g.message.connect(hear)
	var opened: Array = []
	var shop_open := func(id): opened.append(id)
	g.shop_requested.connect(shop_open)
	_set_day(g, "spring", 8, 12, 0)   # a Monday
	check(not g.open_shop("smithy") and said.back() == "Kurogane Smithy is closed today for Blossom Day.", "the smithy shuts for Blossom Day (%s)" % [said])
	check(g.open_shop("general") and opened == ["general"], "the store stays open")
	g.maps.place("town", Vector2i(27, 7), Vector2i.UP)
	g.use_door({"cells": [Vector2i(27, 6)], "to": "smithy", "spawn": Vector2i(4, 5), "facing": Vector2i.UP, "shop": "smithy"})
	check(g.maps.id == "town" and said.back().ends_with("for Blossom Day."), "its door stays shut too")
	g.day = 9
	check(g.open_shop("smithy"), "the smithy opens the day after")
	_set_day(g, "summer", 20, 12, 0)
	check(not g.open_shop("general") and said.back() == "Yorozu Store is closed today for Lantern Night.", "Lantern Night shuts the store all day")
	g.message.disconnect(hear)
	g.shop_requested.disconnect(shop_open)


## Walking into the village during the hours plays the festival's event once that year.
func _event() -> void:
	var g := _game()
	g.new_game()
	g.events_seen = {"first_morning": true, "rainy_day": true}
	g.clock_running = true
	_set_day(g, "spring", 8, 9, 30)
	g.maps.place("town", Vector2i(2, 10), Vector2i.RIGHT)
	var player: Node2D = load("res://scripts/player/player.gd").new()
	player.position = g.maps.pos
	root.add_child(player)
	var ep: Node = load("res://scripts/events/event_player.gd").new(player)
	root.add_child(ep)
	ep.enter_map("town")
	ep.check("enter")
	check(not ep.is_playing(), "nothing before the hours (9:30)")
	g.hour = 10
	g.minute = 0
	ep.check("minute")
	check(ep.is_playing() and ep.runner.id == "festival_blossom", "the hours start with the farmer there: the event plays")
	check(g.events_seen.has("festival:blossom_day:1"), "and it is marked for year 1")
	for i in 20:
		if not ep.is_playing():
			break
		ep._physics_process(0.5)
	check(not ep.is_playing() and g.flags.get("went_blossom_day") == true, "the event ran to its end")
	g.hour = 11
	ep.enter_map("town")
	ep.check("enter")
	check(not ep.is_playing(), "walking in again the same year plays nothing")
	g.year = 2
	ep.check("enter")
	check(ep.is_playing(), "next year's Blossom Day plays it again")
	ep.free()
	player.free()
	g.event_running = false


## Every festival has a contest, and its data is checked.
func _contest_data() -> void:
	for id in Festivals.all():
		var f := Festivals.get_festival(id)
		var c := Festivals.contest(id)
		check(not c.is_empty() and c.takes in Festivals.KINDS, "%s has a contest (%s)" % [id, c.get("takes")])
		check(Festivals.at_table(id, Vector2i(int(c.table[0]), int(c.table[1])))
			and not Festivals.at_table(id, Vector2i(int(f.place[0]), int(f.place[1]))), "%s: the judges' table stands away from the gathering place" % id)
		check(EventRunner.open(c.event, null).error == "", "%s: the result event %s runs" % [id, c.event])
	check(Festivals.at_table("blossom_day", Vector2i(21, 8)) and not Festivals.at_table("blossom_day", Vector2i(22, 8)), "the whole table, not the cherry next to it")
	check(Festivals.stall_at("blossom_day", Vector2i(10, 7)) == "stall:blossom_day", "Blossom Day has the stall")
	check(Festivals.stall_at("lantern_night", Vector2i(10, 7)) == "stall:lantern_night:eats"
		and Festivals.stall_at("lantern_night", Vector2i(22, 7)) == "stall:lantern_night:chimes"
		and not Festivals.at_stall("lantern_night", Vector2i(13, 7)) and not Festivals.at_stall("lantern_night", Vector2i(12, 13)),
		"Lantern Night sells at two of its four stalls, the others are only looks")
	check(Festivals.stall_of("stall:lantern_night:chimes")[0] == "lantern_night" and Festivals.stall_of("stall:lantern_night:chimes")[1].name == "Wind Chime Stall"
		and Festivals.stall_of("stall:blossom_day")[1].name == "Hanami Dango Stall" and Festivals.stall_of("stall:lantern_night")[1].is_empty()
		and Festivals.stall_of("stall:lantern_night:nope")[1].is_empty() and Festivals.stall_of("general")[0] == "", "stall shop ids name the festival and the stall")
	var night: Dictionary = Festivals.get_festival("lantern_night").duplicate(true)
	check(Festivals.check({"festivals": {"a": night}}) == "", "Lantern Night's two stalls pass")
	night.stall[1].id = "eats"
	check(Festivals.check({"festivals": {"a": night}}) != "", "two stalls with one id are refused")
	night.stall[1].id = "a b"
	check(Festivals.check({"festivals": {"a": night}}) != "", "a stall id with a space is refused")
	night.stall[1].erase("id")
	night.stall[0].erase("id")
	check(Festivals.check({"festivals": {"a": night}}) != "", "two stalls without ids are refused")
	var f: Dictionary = Festivals.get_festival("blossom_day").duplicate(true)
	check(Festivals.check({"festivals": {"a": f}}) == "", "Blossom Day's data passes on its own")
	var bad := {
		"takes": {"takes": "food"}, "table": {"table": [9, 7]},   # that is the stall, not a judge_table
		"rival": {"rivals": [{"who": "nobody", "score": [1, 2]}]}, "score": {"rivals": [{"who": "kota", "score": [9, 2]}]},
		"prizes": {"prizes": [{"money": 1}, {"money": 1}, {"money": 1}, {"money": 1}, {"money": 1}, {"money": 1}]},
		"prize": {"prizes": [{"gold": 5}]}, "ask": {"ask": "no_such_line"}, "event": {"event": "no_such_event"},
		"key": {"judge": "tsuru"},
	}
	for what in bad:
		var g := f.duplicate(true)
		g.contest.merge(bad[what], true)
		check(Festivals.check({"festivals": {"a": g}}) != "", "a contest with a bad %s is refused" % what)
	var g := f.duplicate(true)
	g.stall.cell = [20, 8]
	check(Festivals.check({"festivals": {"a": g}}) != "", "a stall must stand on a stall prop")
	g.stall = {"name": "x", "cell": [9, 7], "stock": []}
	check(Festivals.check({"festivals": {"a": g}}) != "", "a stall without stock is refused")


## The judging: rivals rolled per festival and year, the farmer's place, ties and prizes.
func _judging() -> void:
	var r := Festivals.judge("blossom_day", 1, 0)
	check(r.place == r.rivals.size() + 1 and r.winner == r.rivals[0].who and r.prize.is_empty(), "a worthless entry comes last with no prize %s" % [r])
	check(r.rivals.size() == 4 and r.rivals[0].score >= r.rivals[1].score and r.rivals[1].score >= r.rivals[2].score, "rivals best first")
	check(Festivals.judge("blossom_day", 1, 0).rivals == r.rivals, "the same festival and year judge the same")
	var other := false
	for y in range(2, 8):
		other = other or Festivals.judge("blossom_day", y, 0).rivals != r.rivals
	check(other, "other years roll other rivals")
	for c in Festivals.contest("blossom_day").rivals:
		var got: Array = r.rivals.filter(func(x): return x.who == c.who)
		check(got.size() == 1 and got[0].score >= c.score[0] and got[0].score <= c.score[1], "%s scores in their range" % c.who)
	var top: int = r.rivals[0].score
	var win := Festivals.judge("blossom_day", 1, top)
	check(win.place == 1 and win.winner == "farmer" and win.prize.money == 500 and win.prize.item == "food:sakura_mochi",
		"a tie with the best wins first prize %s" % [win.prize])
	var second := Festivals.judge("blossom_day", 1, top - 1)
	var above: int = r.rivals.filter(func(x): return x.score > top - 1).size()
	check(second.place == 1 + above and second.winner == r.rivals[0].who and (above > 1 or (second.prize.keys() == ["money"] and int(second.prize.money) == 200)),
		"one point less than the best rival is behind them %s" % [r.rivals])
	check(Festivals.entry_score("blossom_day", ["spring"], 80) == 120 and Festivals.entry_score("blossom_day", ["fall"], 250) == 250,
		"a spring crop counts half again at Blossom Day")
	check(Festivals.entry_score("lantern_night", [], 200) == 200, "a fish counts its value")


## The result lines for every place and winner end on the right line.
func _result_lines() -> void:
	for id in Festivals.all():
		var c := Festivals.contest(id)
		for place in range(1, c.rivals.size() + 2):
			for rival in c.rivals:
				var flags := {"contest_place_%d" % place: true}
				if place > 1:
					flags["contest_won_" + rival.who] = true
				var d := DialogueRunner.open(Festivals.DIALOGUE, flags, id + "_result")
				var who: Array = []
				var ids: Array = []
				for i in 20:
					if d.done():
						break
					who.append(d.line().get("speaker", ""))
					ids.append(d.line().get("id", ""))
					d.press()
					d.press()
				var want: String = id + ("_%d" % place if place <= 3 else "_out")
				check(d.error == "" and d.done() and want in ids and (place == 1) != (rival.who in who),
					"%s, place %d, %s first: %s %s" % [id, place, rival.who, who, ids])
		check(DialogueRunner.open(Festivals.DIALOGUE, {}, c.ask).error == "", "%s: the judge's ask line" % id)


## Entering in the game: the table, the kind, one entry a year, the prize, flags, the event.
func _contest_game() -> void:
	var g := _game()
	g.new_game()
	var said: Array = []
	var hear := func(t): said.append(t)
	g.message.connect(hear)
	var talks: Array = []
	var talk := func(d, at): talks.append([d, at])
	g.dialogue_requested.connect(talk)
	var events: Array = []
	var ev := func(id): events.append(id)
	g.event_requested.connect(ev)
	check(g.item_kind("potato") == "crop" and g.item_kind("fish:koi") == "fish" and g.item_kind("mine:hisui") == "mine"
		and g.item_kind("milk_good") == "animal" and g.item_kind("food:dango") == "" and g.item_kind("seeds:potato") == "", "entry kinds")
	_set_day(g, "spring", 8, 11, 0)
	g.maps.place("farm", Vector2i(4, 4), Vector2i.DOWN)
	check(g.festival_now() == "" and g.enter_contest().why == "none", "no contest from the farm")
	g.maps.place("town", Vector2i(20, 9), Vector2i.UP)
	check(g.festival_now() == "blossom_day", "the festival is on around the farmer")
	check(g.enter_contest().why == "ask" and talks.back() == ["contests", "blossom_day_ask"], "empty-handed, the judge says what to bring")
	g.held = "fish:koi"
	check(g.enter_contest().why == "kind" and said.back() == "The Blossom Crop Show only takes crops." and g.held == "fish:koi",
		"a fish is turned away and stays in hand")
	g.held = "potato"
	var money: int = g.money
	var potato := Festivals.entry_score("blossom_day", ["spring"], int(g.crops.potato.sell))
	var want := Festivals.judge("blossom_day", 1, potato)
	var r: Dictionary = g.enter_contest()
	check(r.ok and r.score == potato and r.place == want.place and r.item == "potato" and g.held == "", "the potato is handed in and scores %d (%s)" % [potato, r])
	check(g.money == money + int(want.prize.get("money", 0)), "the prize money is paid (%d)" % (g.money - money))
	check(g.flags.get("contest_place_%d" % r.place) == true and (r.place == 1) != g.flags.has("contest_won_" + str(want.rivals[0].who)),
		"the place and winner flags are set %s" % [g.flags])
	check(events == ["contest_blossom"] and g.events_seen.has("contest:blossom_day:1"), "the result event plays, the entry is marked")
	g.held = "turnip"
	check(g.enter_contest().why == "entered" and g.held == "turnip", "one entry a year")
	# Year 2 with a crop that beats the best rival: last year's flags go, first prize comes in.
	g.year = 2
	var best: int = Festivals.judge("blossom_day", 2, 0).rivals[0].score
	var item := "pumpkin"
	for id in ["turnip", "potato", "cucumber"]:
		if Festivals.entry_score("blossom_day", g.crops[id].seasons, g.sell_price(id)) >= best:
			item = id
			break
	g.held = item
	var mochi: int = g.count("food:sakura_mochi")
	var wins := int(g.flags.get("contest_wins", 0))
	r = g.enter_contest()
	check(r.ok and r.place == 1 and g.flags.get("contest_place_1") == true and (want.place == 1 or not g.flags.has("contest_place_%d" % want.place))
		and not g.flags.keys().any(func(k): return k.begins_with("contest_won_")), "year 2: first place with the %s, last year's flags cleared" % item)
	check(g.count("food:sakura_mochi") == mochi + 2 and g.flags.get("contest_prize") == true and int(g.flags.get("contest_wins", 0)) == wins + 1
		and "Prize: 500 G and 2 x Sakura mochi" in said, "first prize: money and two sakura mochi (%s)" % [said])
	var won: Array = [want.place] if want.place <= 3 else []
	won.append(1)
	check(g.count("ribbon:blossom_day:1") == (2 if want.place == 1 else 1) and said.back() == "You got a Blossom Day ribbon (1st)!"
		and Keepsakes.record(g.flags).map(func(e): return e.place) == won and Keepsakes.record(g.flags).back() == {"festival": "blossom_day", "place": 1, "year": 2},
		"a first-place ribbon goes into the rucksack and onto the record (%s)" % [g.flags.get("ribbons")])
	g.hour = 16
	check(g.festival_now() == "" and g.enter_contest().why == "none", "after the hours the table is gone")
	g.message.disconnect(hear)
	g.dialogue_requested.disconnect(talk)
	g.event_requested.disconnect(ev)


## Stands in for Game in the contest result events: the result line opens a box that stays
## open until the test closes it.
class Judge:
	var flags := {}
	var dialogue_open := false
	var lines: Array = []

	func talk(_dialogue: String, at: String, _mood := "") -> void:
		lines.append(at)
		dialogue_open = true


## The contest result events: every rival comes from their festival plan with an entry of the
## contest's kind overhead, stands in front of the judges' table beside the farmer while the
## results are read, then walks back to their plan and leaves the stage.
func _rivals() -> void:
	var g := _game()
	g.new_game()
	var bad := {"steps": [{"do": "actor", "who": "kota", "at": [1, 1], "holds": "no_such_thing"}]}
	check(EventRunner.new(bad, Judge.new()).error != "", "an actor can't carry an unknown item")
	bad = {"steps": [{"do": "actor", "who": "kota", "at": [1, 1], "meanwhile": true}]}
	check(EventRunner.new(bad, Judge.new()).error != "", "meanwhile needs a walk")
	for fid in Festivals.all():
		var f := Festivals.get_festival(fid)
		var c := Festivals.contest(fid)
		var open: PackedStringArray = String(f.hours[0]).split(":")
		_set_day(g, f.season, int(f.day), int(open[0]), int(open[1]) + 30)
		var front := Vector2i(int(c.table[0]), int(c.table[1]) + 1)
		g.maps.place(f.map, front, Vector2i.UP)
		var judge := Judge.new()
		var r := EventRunner.open(c.event, judge)
		check(r.error == "", "%s: %s reads (%s)" % [fid, c.event, r.error])
		r.start(Vector2(front * 16) + Vector2(8, 8), Vector2i.UP)
		for w in Villagers.on_map(f.map, g.day_minutes(), g.trigger_state(front)):
			r.on_stage[w.id] = {"pos": w.pos, "facing": w.facing}
		for _i in 100:
			if judge.dialogue_open or r.done():
				break
			r.update(0.1)
		check(judge.lines == [fid + "_result"], "%s: the results are read (%s)" % [fid, judge.lines])
		var cells := {front: true}
		for rival in c.rivals:
			var a: Dictionary = r.actors.get(rival.who, {})
			if a.is_empty():
				check(false, "%s: %s stands at the table" % [fid, rival.who])
				continue
			var cell := Vector2i(a.pos.floor())
			check(not a.moving and a.pos == Vector2(cell) + Vector2(0.5, 0.5) and a.facing == Vector2i.UP and cell.y == front.y
				and absi(cell.x - front.x) <= 3 and not cells.has(cell) and Festivals._prop_rect(fid, cell).size == Vector2i.ZERO,
				"%s: %s stands in front of the judges' table, facing it (%s)" % [fid, rival.who, a])
			cells[cell] = true
			var entry := String(a.get("holds", ""))
			check(g.item_kind(entry) == c.takes and g.sell_price(entry) > 0, "%s: %s holds up an entry of the kind (%s)" % [fid, rival.who, entry])
		judge.dialogue_open = false
		var back := {}
		for _i in 200:
			if r.done():
				break
			r.update(0.1)
			if r.step().get("do") == "wait" and r.index + 1 < r.steps.size() and r.steps[r.index + 1].get("leave", false):
				for rival in c.rivals:
					back[rival.who] = r.actors.has(rival.who) and r.actors[rival.who].pos == r._plan_spots.get(rival.who) and not r.actors[rival.who].moving
		check(back.size() == c.rivals.size() and back.values().all(func(v): return v), "%s: the rivals are back at their plans' spots (%s)" % [fid, back])
		check(r.done() and r.actors.is_empty(), "%s: then off the stage, back on their festival plans" % fid)


## On Blossom Day Sayo leaves a note on the store counter while she is under the blossoms.
func _store_note() -> void:
	var g := _game()
	g.new_game()
	var said: Array = []
	var hear := func(t): said.append(t)
	g.message.connect(hear)
	_set_day(g, "spring", 8, 14, 0)
	check(not g.open_shop("general") and said.back() == "A note on the counter: \"At the Blossom Day picnic for a while. Back before four! -Sayo\"",
		"Sayo's note at 14:00 on Blossom Day (%s)" % [said])
	g.hour = 16
	check(g.open_shop("general"), "back at the counter at 16:00")
	g.message.disconnect(hear)


## Blossom Day's dango stall: a shop of its own, open only in the festival's hours.
func _stall() -> void:
	var g := _game()
	g.new_game()
	var opened: Array = []
	var shop_open := func(id): opened.append(id)
	g.shop_requested.connect(shop_open)
	var s: Shop = g.shop("stall:blossom_day")
	check(s != null and s.name == "Hanami Dango Stall" and s.stock("spring").size() == 3 and s.open_hour == 10 and s.close_hour == 16,
		"the stall sells its stock in the festival hours")
	var menu := ShopMenu.new(g, "stall:blossom_day")
	check(menu.tabs == ["buy"], "the stall only sells %s" % [menu.tabs])
	_set_day(g, "spring", 8, 9, 0)
	g.maps.place("town", Vector2i(9, 8), Vector2i.UP)
	check(not g.open_stall() and opened.is_empty(), "shut before the festival")
	g.hour = 12
	check(g.open_stall() and opened == ["stall:blossom_day"], "open during it")
	var money: int = g.money
	var r: Dictionary = g.shop_buy("stall:blossom_day", "food:dango", 2)
	check(r.ok and g.money == money - 2 * int(g.foods.dango.price) and g.count("food:dango") == 2, "two dango bought (%s)" % [r])
	_set_day(g, "summer", 20, 18, 0)
	check(not g.open_stall("stall:blossom_day"), "the dango stall isn't out on Lantern Night")
	g.shop_requested.disconnect(shop_open)


## Lantern Night's stalls: the night eats (foods sold only at a stall) and the wind chimes
## (keepsakes: kept, never eaten, shipped or sold), opened with E in front of them.
func _night_stalls() -> void:
	var g := _game()
	g.new_game()
	var opened: Array = []
	var shop_open := func(id): opened.append(id)
	g.shop_requested.connect(shop_open)
	var eats: Shop = g.shop("stall:lantern_night:eats")
	var chimes: Shop = g.shop("stall:lantern_night:chimes")
	check(eats != null and eats.name == "Night Eats Stall" and eats.stock("summer").size() == 3 and eats.open_hour == 17 and eats.close_hour == 22
		and eats.price("food:yakisoba", "summer") == int(g.foods.yakisoba.price), "the eats stall sells at the foods' own prices in the festival hours")
	check(chimes != null and chimes.price("keep:wind_chime", "summer") == 300 and chimes.price("keep:paper_fan", "summer") == 120
		and chimes.item_name("keep:wind_chime") == "Wind chime" and ShopMenu.new(g, "stall:lantern_night:chimes").tabs == ["buy"], "the chime stall's keepsakes and their prices")
	check(g.shop("stall:lantern_night") == null, "no stall without its id")
	# Every stall-only food (shop false with a price) is on some stall, and no stall sells a kitchen dish
	var sold := {}
	for fid in Festivals.all():
		for st in Festivals.stalls(fid):
			for e in st.stock:
				sold[e.item] = true
				check(not g.foods.get(str(e.item).trim_prefix("food:"), {}).has("sell"), "%s at a stall is no kitchen dish" % e.item)
				var n: String = g.item_name(e.item)
				check(n != str(e.item).replace(":", " ").replace("_", " ").capitalize() and PixelFont.width(n) + 12 + PixelFont.width("x99") <= HudLayout.BOXES.item.size.x,
					"%s has a name that fits the item box" % e.item)
	# (or at a shop of its own, e.g. the teahouse's sweets)
	for sid in Shop.ids():
		for season in ["spring", "summer", "fall", "winter"]:
			for e in g.shop(sid).stock(season):
				sold[e.item] = true
	for id in g.foods:
		if not g.foods[id].get("shop", false) and int(g.foods[id].get("price", 0)) > 0:
			check(sold.has("food:" + id), "%s is sold at a festival stall or a shop" % id)
	var FarmActions: GDScript = load("res://scripts/farm_actions.gd")
	_set_day(g, "summer", 20, 16, 0)
	g.maps.place("town", Vector2i(22, 8), Vector2i.UP)
	check(not FarmActions.festival_spot(Vector2i(22, 7)) and opened.is_empty(), "the stalls are shut before 17:00")
	g.hour = 18
	check(FarmActions.festival_spot(Vector2i(23, 7)) and opened == ["stall:lantern_night:chimes"], "E at the chime stall opens it")
	check(FarmActions.festival_spot(Vector2i(9, 7)) and opened.back() == "stall:lantern_night:eats", "E at the eats stall opens that one")
	check(not FarmActions.festival_spot(Vector2i(13, 7)) and opened.size() == 2, "the blue stall is only a look")
	check(g.open_stall() and opened.back() == "stall:lantern_night:eats", "open_stall with no id opens the first")
	var money: int = g.money
	var r: Dictionary = g.shop_buy("stall:lantern_night:chimes", "keep:wind_chime")
	check(r.ok and g.money == money - 300 and g.count("keep:wind_chime") == 1 and g.item_name("keep:wind_chime") == "Wind chime", "a wind chime bought into the rucksack (%s)" % [r])
	r = g.shop_buy("stall:lantern_night:eats", "food:shaved_ice")
	check(r.ok and g.count("food:shaved_ice") == 1 and g.edible("food:shaved_ice"), "shaved ice bought, and it can be eaten")
	var store: Shop = g.shop("general")
	check(g.sell_price("keep:wind_chime") == 0 and store.buy_back("keep:wind_chime") == 0 and not g.edible("keep:wind_chime")
		and store.buy_back("food:yakisoba") == 0 and g.sell_price("food:yakisoba") == 0, "keepsakes and stall food can't be shipped or sold back")
	var bin_total: int = g.bin_total
	g.held = "keep:wind_chime"
	check(g.ship_produce() == 0 and g.count("keep:wind_chime") >= 1 and g.bin_total == bin_total, "the bin leaves the keepsake alone")
	g.held = ""
	check(PlaceholderArt.item_key("keep:wind_chime") == "ui:keep:wind_chime" and PlaceholderArt.item_key("ribbon:moon_night:2") == "ui:ribbon:2", "keepsake and ribbon icon keys")
	for key in ["ui:keep:wind_chime", "ui:keep:paper_fan", "ui:ribbon:1", "ui:ribbon:2", "ui:ribbon:3"]:
		var img := PlaceholderArt.tex(key).get_image()
		check(img.get_size() == Vector2i(14, 14) and img.get_used_rect().has_area(), "%s drawn" % key)
	check(PlaceholderArt.tex("ui:ribbon:1").get_image().get_pixel(10, 5) != PlaceholderArt.tex("ui:ribbon:3").get_image().get_pixel(10, 5), "ribbons differ by place")
	g.shop_requested.disconnect(shop_open)


## Moon Night's and Year's Turn's stalls: a food stall and a keepsake stall each, open only in
## their festival's hours, opened with E in front of them; every keepsake has its own icon.
func _fall_winter_stalls() -> void:
	var g := _game()
	g.new_game()
	var opened: Array = []
	var shop_open := func(id): opened.append(id)
	g.shop_requested.connect(shop_open)
	check(Festivals.stalls("moon_night").size() == 2 and Festivals.stalls("years_turn").size() == 2, "Moon Night and Year's Turn have two stalls each")
	var chestnuts: Shop = g.shop("stall:moon_night:eats")
	var crafts: Shop = g.shop("stall:moon_night:crafts")
	var soba: Shop = g.shop("stall:years_turn:soba")
	var charms: Shop = g.shop("stall:years_turn:charms")
	check(chestnuts != null and chestnuts.name == "Chestnut Roaster" and chestnuts.open_hour == 18 and chestnuts.close_hour == 23
		and chestnuts.price("food:roast_chestnuts", "fall") == int(g.foods.roast_chestnuts.price), "the chestnut roaster in Moon Night's hours")
	check(crafts != null and crafts.price("keep:clay_rabbit", "fall") == 240 and crafts.price("keep:moon_lantern", "fall") == 160
		and crafts.item_name("keep:clay_rabbit") == "Clay rabbit", "the moon craft stall's keepsakes")
	check(soba != null and soba.name == "Year-End Soba Stall" and soba.open_hour == 19 and soba.stock("winter").size() == 2
		and charms != null and charms.price("keep:daruma", "winter") == 280 and charms.price("keep:omamori", "winter") == 150, "Year's Turn's soba and charm stalls")
	check(g.foods.amazake.get("shop", false) and not g.foods.yuzu_tea.get("shop", true), "the stand's amazake stays, the stall pours yuzu tea")
	var FarmActions: GDScript = load("res://scripts/farm_actions.gd")
	_set_day(g, "fall", 15, 17, 0)
	g.maps.place("town", Vector2i(13, 8), Vector2i.UP)
	check(not FarmActions.festival_spot(Vector2i(13, 7)) and opened.is_empty(), "the Moon Night stalls are shut before 18:00")
	g.hour = 19
	check(FarmActions.festival_spot(Vector2i(14, 7)) and opened == ["stall:moon_night:eats"], "E at the chestnut roaster opens it")
	check(FarmActions.festival_spot(Vector2i(9, 7)) and opened.back() == "stall:moon_night:crafts", "E at the craft stall opens that one")
	check(not g.open_stall("stall:years_turn:charms"), "the charm stall isn't out on Moon Night")
	var money: int = g.money
	var r: Dictionary = g.shop_buy("stall:moon_night:crafts", "keep:clay_rabbit")
	check(r.ok and g.money == money - 240 and g.count("keep:clay_rabbit") == 1 and g.sell_price("keep:clay_rabbit") == 0 and not g.edible("keep:clay_rabbit"),
		"a clay rabbit bought, to keep (%s)" % [r])
	r = g.shop_buy("stall:moon_night:eats", "food:baked_imo")
	check(r.ok and g.edible("food:baked_imo") and g.sell_price("food:baked_imo") == 0, "a baked sweet potato to eat, not to ship")
	_set_day(g, "winter", 30, 23, 30)
	g.maps.place("town", Vector2i(14, 3), Vector2i.UP)
	check(FarmActions.festival_spot(Vector2i(14, 2)) and opened.back() == "stall:years_turn:soba", "E at the soba stall at 23:30")
	check(FarmActions.festival_spot(Vector2i(23, 2)) and opened.back() == "stall:years_turn:charms", "E at the charm stall")
	check(FarmActions.festival_spot(Vector2i(14, 4)) and opened.back() == "stall:years_turn:charms", "the judges' table is no stall")
	var seen := {}
	for id in Keepsakes.data().keepsakes:
		var img := PlaceholderArt.tex("ui:keep:" + id).get_image()
		check(img.get_size() == Vector2i(14, 14) and img.get_used_rect().has_area(), "keep:%s drawn" % id)
		var key := Marshalls.raw_to_base64(img.get_data())
		check(not seen.has(key), "keep:%s has its own look" % id)
		seen[key] = true
	for id in ["roast_chestnuts", "baked_imo"]:   # the two new food shapes
		var img := PlaceholderArt.tex(PlaceholderArt.item_key("food:" + id)).get_image()
		check(img.get_used_rect().size.x >= 10 and img.get_pixel(7, 7).a > 0, "food:%s drawn as its own shape" % id)
	g.shop_requested.disconnect(shop_open)


## Ribbons: one per place up to the last ribbon place, by festival; the record (a story flag,
## saved with the flags) and the board in the farmhouse that shows it.
func _ribbons() -> void:
	check(Keepsakes.places().size() == 3 and Keepsakes.ribbon_id("moon_night", 3) == "ribbon:moon_night:3" and Keepsakes.ribbon_id("moon_night", 4) == ""
		and Keepsakes.ribbon_id("moon_night", 0) == "", "ribbons for 1st to 3rd only")
	for fid in Festivals.all():
		for place in [1, 2, 3]:
			var n := Keepsakes.name_of(Keepsakes.ribbon_id(fid, place))
			check(n != "" and PixelFont.width(n) + 12 + PixelFont.width("x99") <= HudLayout.BOXES.item.size.x, "%s fits the item box" % n)
		check(Festivals.contest(fid).prizes.size() <= Keepsakes.places().size(), "%s: a ribbon for every prize place" % fid)
	check(Keepsakes.name_of("ribbon:years_turn:2") == "Year's Turn ribbon (2nd)" and Keepsakes.name_of("ribbon:nowhere:1") == "" and Keepsakes.name_of("potato") == "", "ribbon names")
	var g := _game()
	g.new_game()
	check(not MapManager.data("house").props.any(func(p): return p.kind == "ribbon_board"), "no ribbon board before the first ribbon")
	check(Keepsakes.board_text(g.flags) == "An empty board for contest ribbons.", "an empty record")
	# Last place: no ribbon. A full rucksack: the ribbon is noted on the board anyway.
	_set_day(g, "fall", 15, 19, 0)
	g.maps.place("town", Vector2i(22, 9), Vector2i.UP)
	var said: Array = []
	var hear := func(t): said.append(t)
	g.message.connect(hear)
	g.held = "egg"
	var r: Dictionary = g.enter_contest()
	check(r.ok and r.place == 5 and Keepsakes.record(g.flags).is_empty() and not g.flags.has(Keepsakes.RECORD) and g.count("ribbon:moon_night:5") == 0,
		"an egg comes last at the Moon Offering: no ribbon (%s)" % [r])
	g._give_ribbon("moon_night", 3)
	check(g.count("ribbon:moon_night:3") == 1 and said.back() == "You got a Moon Night ribbon (3rd)!", "a third-place ribbon")
	while g.add_item("mine:stone", 99) == 0:
		pass
	g._give_ribbon("years_turn", 1)
	check(g.count("ribbon:years_turn:1") == 0 and said.back() == "No room in the rucksack for the ribbon. It is on the board at home."
		and Keepsakes.record(g.flags).size() == 2, "a full rucksack: the ribbon is only on the board")
	g.message.disconnect(hear)
	check(Keepsakes.board_places(g.flags) == "31" and Keepsakes.board_text(g.flags) == "Contest ribbons: 2 on the board, 1 of them for first place.", "the board's look and text")
	var house := MapManager.data("house")
	var board: Array = house.props.filter(func(p): return p.kind == "ribbon_board")
	check(board.size() == 1 and board[0].use == "ribbons" and not house.is_solid(board[0].cell + Vector2i.DOWN), "the board hangs in the farmhouse once a ribbon is won, reachable from below")
	check(StoryView.art_key(board[0]) == "story:ribbon_board:31", "the board's picture shows both ribbons")
	var img := PlaceholderArt.tex("story:ribbon_board:31").get_image()
	check(img.get_size() == Vector2i(42, 26) and img.get_pixel(3, 6).is_equal_approx(Keepsakes.ribbon_color(3))
		and img.get_pixel(9, 6).is_equal_approx(Keepsakes.ribbon_color(1)) and img.get_pixel(17, 6).is_equal_approx(PlaceholderArt.UI_PAPER),
		"one rosette per ribbon, in its place's colour, then bare paper")
	# The record is a story flag: it is saved and read back.
	var d: Dictionary = g.to_dict()
	var keep: Dictionary = g.flags.duplicate()
	g.new_game()
	check(g.from_dict(JSON.parse_string(JSON.stringify(d))) == "" and g.flags.get(Keepsakes.RECORD) == keep[Keepsakes.RECORD]
		and g.count("ribbon:moon_night:3") == 1 and MapManager.data("house").props.any(func(p): return p.kind == "ribbon_board"), "ribbons and the record survive a save")
	g.new_game()


## DESIGN: no shipping payout on a festival day; the bin pays with the next day's.
func _payout() -> void:
	var g := _game()
	g.new_game()
	_set_day(g, "spring", 8, 17, 59)
	g.bin_total = 300
	var money: int = g.money
	g._tick_minute()
	check(g.hour == 18 and g.money == money and g.bin_total == 300, "18:00 on Blossom Day pays nothing")
	g.end_day()
	check(g.day == 9 and g.money == money and g.bin_total == 300, "nor does the night after it")
	g.bin_total += 50
	g.hour = 17
	g.minute = 59
	g._tick_minute()
	check(g.money == money + 350 and g.bin_total == 0, "the next day's 18:00 pays both days (%d)" % (g.money - money))
	check(not g.payout_held(), "a plain day holds nothing")
	_set_day(g, "winter", 30, 20, 0)
	g.bin_total = 100
	g.end_day()
	check(g.year == 2 and g.season == 0 and g.day == 1 and g.bin_total == 100, "Year's Turn holds it over the new year")


## Both views on the village on a festival day.
func _start_views(season: String, day: int, h: int, m: int) -> void:
	var g := _game()
	g.new_game()
	g.events_seen = {"first_morning": true, "rainy_day": true}
	_set_day(g, season, day, h, m)
	g.maps.place("town", Vector2i(18, 9), Vector2i.UP)
	g.pause()   # the clock holds while the views are checked
	_scene3 = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene3)
	_scene2 = load("res://scenes/main_2d.tscn").instantiate()
	root.add_child(_scene2)


func _props() -> Array:
	var p3: Array = _scene3.world.get_children().filter(func(n): return _script_is(n, "festival_props.gd"))
	var p2: Array = _scene2.view.get_children().filter(func(n): return _script_is(n, "festival_view.gd"))
	check(p3.size() == 1 and p2.size() == 1, "both views have a festival layer")
	return [p3[0] if p3.size() == 1 else null, p2[0] if p2.size() == 1 else null]


func _check_views() -> void:
	var g := _game()
	var p := _props()
	if p[0] == null or p[1] == null:
		return
	check(p[0].festival == "blossom_day" and p[0].shown() and p[1].shown(), "Blossom Day decorations stand at 10:30 in both views")
	check(p[0].glows.size() == 1, "the stall's lantern is the one light (%d)" % p[0].glows.size())
	check(p[0].wares == 3, "the dango stall sets out its three wares (%d)" % p[0].wares)
	var v3: Array = _scene3.world.find_children("*", "Node3D", true, false).filter(func(n): return _script_is(n, "villager_sprites.gd"))
	var v2: Array = _scene2.view.find_children("*", "Node2D", true, false).filter(func(n): return _script_is(n, "villager_view.gd"))
	if v3.size() == 1 and v2.size() == 1:
		Villagers.actors = {"kota": {"map": "town", "pos": Vector2(19.5, 9.5), "facing": Vector2i.UP, "moving": false, "walked": 0.0, "holds": "potato"}}
		v3[0].refresh()
		v2[0].refresh()
		check(v3[0].held("kota") == "potato" and v2[0].held("kota") == "potato" and v3[0].held("tome") == "" and v2[0].held("tome") == "",
			"an actor's entry shows over their head in both views")
		Villagers.actors = {}
		v3[0].refresh()
		v2[0].refresh()
		check(v3[0].held("kota") == "" and v2[0].held("kota") == "", "and goes with the event")
	else:
		check(false, "both views have a villager layer (%d, %d)" % [v3.size(), v2.size()])
	var huds: Array = _scene3.get_children().filter(func(n): return _script_is(n, "hud.gd"))
	check(huds.size() == 1 and huds[0]._fest_box.visible and huds[0]._fest.text == "Blossom Day", "the HUD shows the festival")
	var mochi3: Array = _scene3.get_children().filter(func(n): return _script_is(n, "mochi_screen.gd"))
	var mochi2: Array = _scene2.get_children().filter(func(n): return _script_is(n, "mochi_screen.gd"))
	check(mochi3.size() == 1 and mochi2.size() == 1, "both views have the mochi pounding screen")
	if mochi3.size() == 1:
		var pauses: int = g._pauses
		mochi3[0].open("years_turn", "kota")
		check(mochi3[0].is_open() and mochi3[0].game != null and mochi3[0].game.beats.size() == 30 and g._pauses == pauses + 1,
			"the screen opens a game of 30 strikes and holds the clock")
		mochi3[0].game.advance(mochi3[0].game.beats[0])
		mochi3[0].swing()
		check(mochi3[0].game.score == 3 and mochi3[0].game.marks[0] == "great", "a swing right on the first beat lands great")
		mochi3[0]._exit_tree()
		check(g._pauses == pauses and g.game_partner == "", "leaving the view mid-game lets the clock go")
		mochi3[0]._open = false
		mochi3[0].open("moon_night", "")
		check(not mochi3[0].is_open() and g._pauses == pauses, "the mochi screen leaves a fishing race alone")
	var race3: Array = _scene3.get_children().filter(func(n): return _script_is(n, "race_screen.gd"))
	var race2: Array = _scene2.get_children().filter(func(n): return _script_is(n, "race_screen.gd"))
	check(race3.size() == 1 and race2.size() == 1, "both views have the fishing race box")
	if race3.size() == 1 and race2.size() == 1:
		check(not race3[0].is_shown() and not race2[0].is_shown(), "no race, no box")
		g.race = FishingRace.new(Festivals.game("moon_night"))
		g.race.time = 0.5
		race3[0]._refresh()
		check(race3[0].is_shown() and race3[0]._call.text == "Ready... 3" and race3[0]._count.text == "0 fish", "the count-in shows (%s)" % race3[0]._call.text)
		g.race.time = 14.0
		g.race.land("fish:funa")
		g.race.land("fish:koi")
		race3[0]._refresh()
		race2[0]._refresh()
		check(race2[0].is_shown() and race3[0]._clock.visible and race3[0]._clock.text == "0:49" and race3[0]._count.text == "2 fish"
			and race3[0]._icons[1].texture != null and race3[0]._icons[2].texture == null, "the time left, the count and two fish in the creel (%s)" % race3[0]._clock.text)
		g.race.time = 64.0
		race3[0]._refresh()
		check(race3[0]._call.text == "Time!" and race3[0]._bar.size.x == 0.0, "time is called")
		g.race = null
		race3[0]._refresh()
		check(not race3[0].is_shown(), "the box goes with the race")
	g.hour = 16
	g.minute = 0
	p[0].refresh()
	p[1].refresh()
	check(not p[0].shown() and not p[1].shown(), "taken down at 16:00")
	g.hour = 10
	p[0].refresh()
	check(p[0].shown(), "up again in the hours")
	g.day = 9
	g.changed.emit()
	check(not huds[0]._fest_box.visible, "no HUD tag on a plain day")
	var plain3: Node = load("res://scripts/world3d/festival_props.gd").new("town")
	_scene3.world.add_child(plain3)
	var plain2: Node = load("res://scripts/world/festival_view.gd").new("town")
	_scene2.view.add_child(plain2)
	check(plain3.festival == "" and not plain3.shown() and plain3.get_child_count() == 0 and not plain2.shown(), "a plain day builds nothing")
	_scene3.free()
	_scene2.free()
	g.unpause()


func _check_night() -> void:
	var g := _game()
	var p := _props()
	if p[0] != null:
		check(p[0].festival == "lantern_night" and p[0].shown(), "Lantern Night decorations at 20:00")
		check(p[0].glows.size() == 41, "36 string lanterns, 4 stall lanterns and the drum stage glow (%d)" % p[0].glows.size())
		check(p[0].wares == 5, "the two selling stalls set out their 3 + 2 wares (%d)" % p[0].wares)
	var glow: GDScript = load("res://scripts/world3d/festival_glow.gd")
	check(glow.fireworks_on(), "fireworks over the village at 20:00")
	g.maps.place("farm", Vector2i(4, 4), Vector2i.DOWN)
	check(not glow.fireworks_on(), "not over the farm")
	_scene3.free()
	_scene2.free()
	g.unpause()


## The mochi pounding's data: the game at Year's Turn, its mortar, the checks on bad data.
func _game_data() -> void:
	var g := Festivals.game("years_turn")
	check(g.get("kind") == "mochi" and g.id == "mochi" and Festivals.festival_of_game("mochi") == "years_turn"
		and Festivals.festival_of_game("nope") == "", "Year's Turn has the mochi pounding")
	check(Festivals.at_game("years_turn", Vector2i(20, 4)) and not Festivals.at_game("years_turn", Vector2i(20, 5))
		and not Festivals.at_table("years_turn", Vector2i(20, 4)) and not Festivals.at_game("blossom_day", Vector2i(20, 4)),
		"the game is played at the mortar, apart from the judges' table")
	check(Festivals.ribbon_label("mochi") == "Mochi Pounding" and Festivals.ribbon_label("years_turn") == "Year's Turn"
		and Festivals.ribbon_label("nope") == "", "ribbon keys name a festival or a festival's game")
	for place in [1, 2, 3]:
		var n := Keepsakes.name_of(Keepsakes.ribbon_id("mochi", place))
		check(n != "" and PixelFont.width(n) + 12 + PixelFont.width("x99") <= HudLayout.BOXES.item.size.x, "%s fits the item box" % n)
	check(Keepsakes.name_of("ribbon:mochi:1") == "Mochi Pounding ribbon (1st)", "the mochi ribbon's name")
	check(EventRunner.open(g.event, null).error == "", "the game's result event runs")
	var f: Dictionary = Festivals.get_festival("years_turn").duplicate(true)
	check(Festivals.check({"festivals": {"a": f}}) == "", "Year's Turn with its game passes on its own")
	var bad := {
		"kind": {"kind": "sumo"}, "cell": {"cell": [14, 4]}, "partners": {"partners": ["nobody"]},
		"rounds": {"rounds": []}, "beat": {"rounds": [{"beats": 4, "beat": 0.1}]},
		"good window": {"windows": {"great": 0.07, "good": 0.4}}, "great window": {"windows": {"great": 0.12, "good": 0.1}},
		"miss points": {"points": {"great": 3, "good": 1, "miss": 1}}, "good points": {"points": {"great": 1, "good": 3, "miss": 0}},
		"prizes": {"prizes": [{"money": 1}, {"money": 1}, {"money": 1}, {"money": 1}, {"money": 1}, {"money": 1}]},
		"rival": {"rivals": [{"who": "nobody", "score": [1, 2]}]}, "event": {"event": "no_such_event"},
		"key": {"music": "taiko"}, "id": {"id": "a b"}, "lead": {"lead": 30},
	}
	for what in bad:
		var h := f.duplicate(true)
		h.game.merge(bad[what], true)
		check(Festivals.check({"festivals": {"a": h}}) != "", "a game with a bad %s is refused" % what)
	var h := f.duplicate(true)
	h.game.rivals = [{"who": "hachiro", "score": [1, 2]}]
	h.game.prizes = [{"money": 1}, {"money": 1}]
	check(Festivals.check({"festivals": {"a": h}}) == "", "with no partner among the rivals the farmer makes one more place")
	h.game.rivals.append({"who": "tome", "score": [1, 2]})
	h.game.prizes.append({"money": 1})
	check(Festivals.check({"festivals": {"a": h}}) != "", "a partner among the rivals sits out: one place fewer")


## The timing: strikes and turns from the rounds, the windows, misses either way, the score.
func _mochi_timing() -> void:
	var data := {"lead": 1.0, "gap": 1.0, "rounds": [{"beats": 3, "beat": 1.0}, {"beats": 2, "beat": 0.5}],
		"windows": {"great": 0.05, "good": 0.15}, "points": {"great": 3, "good": 1, "miss": -1}}
	var m := MochiPound.new(data)
	check(m.beats == [1.0, 2.0, 3.0, 5.0, 5.5] and m.round_of == [0, 0, 0, 1, 1] and m.turns == [1.5, 2.5, 5.25],
		"strikes a beat apart, the gap between rounds, a turn halfway between strikes (%s %s)" % [m.beats, m.turns])
	check(m.best() == 15 and m.rounds == 2 and m.round_now() == 0 and not m.done() and m.dough(4) == 0, "a fresh go")
	check(m.advance(0.97).is_empty() and m.press() == "great" and m.score == 3 and m.marks[0] == "great", "0.03 s early is great")
	check(m.advance(0.9) == ["turn"] and m.press() == "good" and m.score == 4, "the partner turns, then 0.13 s early is good")
	m.advance(0.4)
	check(m.press() == "miss" and m.score == 3 and m.marks[2] == "", "a swing between beats misses and the beat stays open")
	check(m.advance(1.0) == ["turn", "miss"] and m.marks[2] == "miss" and m.score == 2, "a beat let pass is a miss too")
	check(m.round_now() == 1 and m.to_next() > 1.0, "on to the faster round")
	m.advance(5.0 - m.time)
	check(m.press() == "great" and m.press() == "miss", "a second swing on the same beat misses (hands in the way)")
	m.advance(1.0)
	check(m.done() and m.score == 3 and m.counts == {"great": 2, "good": 1, "miss": 4} and m.press() == "", "done: 6 - 3 = 3 points (%s)" % [m.counts])
	var idle := MochiPound.new(data)
	idle.advance(20.0)
	check(idle.done() and idle.score == 0 and idle.counts.miss == 5, "never swinging scores 0, not below")
	var perfect := MochiPound.new(Festivals.game("years_turn"))
	for b in perfect.beats:
		perfect.advance(b - perfect.time)
		perfect.press()
	check(perfect.done() and perfect.score == perfect.best() and perfect.best() == 90 and perfect.dough(4) == 3,
		"every Year's Turn strike great: 90 points and round mochi")


## The ranking: rivals rolled per year, the partner sitting out, prizes by place.
func _game_judging() -> void:
	var r := Festivals.judge_game("years_turn", 1, 0, "tome")
	check(r.rivals.size() == 4 and not r.rivals.any(func(x): return x.who == "tome") and r.place == 5 and r.prize.is_empty(),
		"with Tome turning, four rivals; 0 points comes last with no prize")
	var k := Festivals.judge_game("years_turn", 1, 0, "kota")
	var hachiro := func(res): return res.rivals.filter(func(x): return x.who == "hachiro")[0].score
	check(not k.rivals.any(func(x): return x.who == "kota") and hachiro.call(k) == hachiro.call(r), "the partner changes who rivals, not their scores")
	check(Festivals.judge_game("years_turn", 1, 0, "tome").rivals == r.rivals, "the same year ranks the same")
	for c in Festivals.game("years_turn").rivals:
		for x in k.rivals + r.rivals:
			if x.who == c.who:
				check(x.score >= c.score[0] and x.score <= c.score[1], "%s scores in their range" % c.who)
	var top: int = r.rivals[0].score
	var win := Festivals.judge_game("years_turn", 1, top, "tome")
	check(win.place == 1 and win.winner == "farmer" and win.prize.money == 400 and win.prize.item == "food:kinako_mochi" and win.prize.count == 3,
		"a tie with the best wins first prize")
	var third := Festivals.judge_game("years_turn", 1, r.rivals[1].score - 1, "tome") if r.rivals[1].score > r.rivals[2].score else {}
	if not third.is_empty():
		check(third.place == 3 and third.prize.size() == 1 and int(third.prize.money) == 80, "behind two rivals: third and 80 G")
	var points := {"tome": 0, "kota": 0}
	var of := func(id): return points.get(id, 0)
	check(Festivals.partner_for("years_turn", of) == "tome", "on a tie Tome turns the dough")
	points.kota = 40
	check(Festivals.partner_for("years_turn", of) == "kota", "Kota turns it once the farmer is closer to him")
	check(Festivals.partner_for("blossom_day", of) == "", "no game, no partner")


## The result lines for every place, winner and partner end on the right lines.
func _game_result_lines() -> void:
	var g := Festivals.game("years_turn")
	for partner in g.partners:
		var rivals: Array = g.rivals.filter(func(r): return r.who != partner)
		for place in range(1, rivals.size() + 2):
			for rival in rivals:
				var flags := {"contest_place_%d" % place: true, "contest_partner_" + partner: true}
				if place > 1:
					flags["contest_won_" + rival.who] = true
				var d := DialogueRunner.open(Festivals.DIALOGUE, flags, str(g.id) + "_result")
				var who: Array = []
				var ids: Array = []
				for i in 20:
					if d.done():
						break
					who.append(d.line().get("speaker", ""))
					ids.append(d.line().get("id", ""))
					d.press()
					d.press()
				var want: String = "mochi" + ("_%d" % place if place <= 3 else "_out")
				check(d.error == "" and d.done() and want in ids and (place == 1) != (rival.who in who.slice(0, -1)) and who.back() == partner,
					"mochi, place %d, %s first, %s turning: %s %s" % [place, rival.who, partner, who, ids])


## Playing in the game: the mortar, empty hands, the partner, one go a year, the prize, the
## ribbon, the flags, the save, and the judged contest still beside it.
func _game_play() -> void:
	var g := _game()
	g.new_game()
	var said: Array = []
	var hear := func(t): said.append(t)
	g.message.connect(hear)
	var asked: Array = []
	var ask := func(f, p): asked.append([f, p])
	g.game_requested.connect(ask)
	var events: Array = []
	var ev := func(id): events.append(id)
	g.event_requested.connect(ev)
	_set_day(g, "winter", 30, 19, 30)
	g.maps.place("farm", Vector2i(4, 4), Vector2i.DOWN)
	check(g.start_game().why == "none", "no game from the farm")
	g.maps.place("town", Vector2i(20, 5), Vector2i.UP)
	g.held = "potato"
	check(g.start_game().why == "held" and said.back() == "The mallet takes both hands. Put the Potato down first." and asked.is_empty(),
		"the mallet needs empty hands (%s)" % [said.back()])
	g.held = ""
	var s: Dictionary = g.start_game()
	check(s.ok and s.partner == "tome" and asked == [["years_turn", "tome"]] and g.game_partner == "tome", "the game starts with Tome turning")
	check(g.start_game().why == "busy" and asked.size() == 1, "not twice at once")
	var top: int = Festivals.judge_game("years_turn", 1, 0, "tome").rivals[0].score
	var money: int = g.money
	var wins := int(g.flags.get("contest_wins", 0))
	var r: Dictionary = g.finish_game(top)
	check(r.place == 1 and r.partner == "tome" and g.money == money + 400 and g.count("food:kinako_mochi") == 3 and g.count("ribbon:mochi:1") == 1,
		"first place: 400 G, three kinako mochi and the ribbon (%s)" % [r])
	check(g.flags.get("contest_place_1") == true and g.flags.get("contest_partner_tome") == true and g.flags.get("contest_prize") == true
		and int(g.flags.get("game_best_mochi", 0)) == top and int(g.flags.get("contest_wins", 0)) == wins + 1, "the flags for the lines, the best score, a win")
	check(events == ["contest_mochi"] and g.events_seen.has("game:years_turn:1") and g.game_partner == "", "the result event plays, the go is marked")
	check(Keepsakes.record(g.flags).back() == {"festival": "mochi", "place": 1, "year": 1} and said.has("You got a Mochi Pounding ribbon (1st)!"),
		"the ribbon goes on the board's record")
	check(g.start_game().why == "played" and said.back() == "You already took a turn at the Mochi Pounding this year." and asked.size() == 1, "one go a year")
	# The judged contest beside it goes on as before.
	g.maps.place("town", Vector2i(14, 5), Vector2i.UP)
	g.held = "mine:stone"
	var c: Dictionary = g.enter_contest()
	check(c.ok and g.events_seen.has("contest:years_turn:1") and events.back() == "contest_year" and not g.flags.has("contest_partner_tome"),
		"the First Stone contest still takes its entry the same night")
	# Saved and read back.
	var d: Dictionary = g.to_dict()
	var record := str(g.flags.get(Keepsakes.RECORD))
	g.new_game()
	check(g.from_dict(JSON.parse_string(JSON.stringify(d))) == "" and g.events_seen.has("game:years_turn:1") and int(g.flags.get("game_best_mochi", 0)) == top
		and g.count("ribbon:mochi:1") == 1 and str(g.flags.get(Keepsakes.RECORD)) == record and g.game_partner == "", "the go, the best score and the ribbon survive a save")
	# Year 2, closer to Kota: he turns, and a bad go comes last with nothing.
	g.year = 2
	g.affection.add("kota", 50)
	g.maps.place("town", Vector2i(20, 5), Vector2i.UP)
	check(load("res://scripts/farm_actions.gd").festival_spot(Vector2i(20, 4)) and asked.back() == ["years_turn", "kota"], "E at the mortar starts the game; Kota turns now")
	var count: int = g.count("food:kinako_mochi")
	money = g.money
	r = g.finish_game(0)
	check(r.place == 5 and r.prize.is_empty() and g.money == money and g.count("food:kinako_mochi") == count and g.count("ribbon:mochi:5") == 0
		and g.flags.get("contest_place_5") == true and g.flags.get("contest_won_" + str(r.rivals[0].who)) == true and g.flags.get("contest_partner_kota") == true
		and not g.flags.has("contest_partner_tome") and not g.flags.has("contest_prize") and int(g.flags.get("game_best_mochi", 0)) == top,
		"year 2: last place, no prize or ribbon, the best score kept (%s)" % [r])
	g.hour = 0   # midnight: Year's Turn is over (its hours end at 24:00)
	check(g.start_game().why == "none", "after the hours the mortar is gone")
	g.message.disconnect(hear)
	g.game_requested.disconnect(ask)
	g.event_requested.disconnect(ev)
	# The mortar in 3D: a mesh of its own, not the magenta stand-in.
	_set_day(g, "winter", 30, 19, 30)
	var props: Node = load("res://scripts/world3d/festival_props.gd").new("town")
	root.add_child(props)
	var before := props.get_child_count()
	props._make({"kind": "mochi_usu", "cell": [20, 4]})
	check(props.get_child_count() - before >= 8, "the mortar, its hoops, the dough, the mallet and the pail in 3D (%d)" % (props.get_child_count() - before))
	props.free()
	var usu := PlaceholderArt.tex("mochi:usu:3").get_image()
	var kine := PlaceholderArt.tex("mochi:kine").get_image()
	check(usu.get_size() == Vector2i(32, 24) and kine.get_size() == Vector2i(16, 28) and usu.get_pixel(16, 18).is_equal_approx(PlaceholderArt.MOCHI_HOOP),
		"the mortar and mallet pictures")
	check(PlaceholderArt.tex("mochi:usu:0").get_image().get_data() != usu.get_data(), "the dough changes as it is pounded")
	g.new_game()


## Views are checked by script path: in a --script run the autoload isn't known when this
## file compiles, so naming the view classes here would fail to compile.
func _script_is(n: Node, file: String) -> bool:
	return n.get_script() != null and n.get_script().resource_path.ends_with(file)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


## The flat view's pictures (FestivalView / PlaceholderArt "festival:" keys): every decoration
## of the four festivals has its own art standing on the middle of its cells, where the 3D
## prop stands, and every 3D light lands on a lit part of a picture (a lantern, the drum, the fire).
func _flat_art() -> void:
	var view: GDScript = load("res://scripts/world/festival_view.gd")   # they name the Game autoload
	var props3d: GDScript = load("res://scripts/world3d/festival_props.gd")
	for id in Festivals.all():
		var fest: Dictionary = Festivals.get_festival(id)
		var pics: Array = []   # [origin, image]
		for p in fest.get("props", []):
			var key: String = view.art_key(p)
			var img: Image = PlaceholderArt.tex(key).get_image()
			var size: Array = p.get("size", [1, 1])
			var anchor := PlaceholderArt.festival_anchor(str(p.kind), int(size[0]), int(size[1]))
			check(key.begins_with("festival:%s:" % p.kind) and img.get_size() == PlaceholderArt.festival_size(str(p.kind), int(size[0]), int(size[1])),
				"%s: the %s has its own picture (%s)" % [id, p.kind, key])
			var magenta := false
			var low := -1   # the lowest opaque row
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					if c.a > 0:
						low = y
						magenta = magenta or c.is_equal_approx(Color.MAGENTA)
			check(not magenta and low >= 0, "%s: the %s picture is drawn, not the magenta fallback" % [id, p.kind])
			check(low >= anchor.y - 1, "%s: the %s stands on its ground (lowest row %d, ground %d)" % [id, p.kind, low, anchor.y])
			var mid := Vector2(p.cell[0] + size[0] / 2.0, p.cell[1] + size[1] / 2.0) * 16
			check(view.ground_mid(p) == mid and view.art_origin(p) + Vector2(anchor) == mid, "%s: the %s stands where the 3D prop does" % [id, p.kind])
			pics.append([view.art_origin(p), img])
		var lights: Array = props3d.glows_of(id, str(fest.get("map", "")))
		var lit := 0
		for g in lights:
			var at: Vector2 = view.glow_pos(g.pos)
			for pic in pics:
				var q := Vector2i((at - pic[0]).floor())
				var img: Image = pic[1]
				if Rect2i(Vector2i.ZERO, img.get_size()).has_point(q) and img.get_pixelv(q).a > 0 and img.get_pixelv(q) != PlaceholderArt.OUTLINE:
					lit += 1
					break
		check(lit == lights.size(), "%s: every light sits on its lamp in the flat view (%d / %d)" % [id, lit, lights.size()])


## The fishing race's data: the game at Moon Night, its flag by the village pond, the checks.
func _race_data() -> void:
	var g := Festivals.game("moon_night")
	check(g.get("kind") == "fishing" and g.id == "fishing" and Festivals.festival_of_game("fishing") == "moon_night",
		"Moon Night has the fishing race")
	check(Festivals.at_game("moon_night", Vector2i(30, 13)) and not Festivals.at_game("moon_night", Vector2i(30, 14))
		and not Festivals.at_table("moon_night", Vector2i(30, 13)), "the race starts at its flag, apart from the judges' table")
	check(Festivals.partner_for("moon_night", func(_id): return 0) == "", "a race has no partner")
	check(Festivals.ribbon_label("fishing") == "Moon Pond Race", "the race's ribbon key names it")
	for place in [1, 2, 3]:
		var n := Keepsakes.name_of(Keepsakes.ribbon_id("fishing", place))
		check(n != "" and PixelFont.width(n) + 12 + PixelFont.width("x99") <= HudLayout.BOXES.item.size.x, "%s fits the item box" % n)
	check(EventRunner.open(g.event, null).error == "", "the race's result event runs")
	var f: Dictionary = Festivals.get_festival("moon_night").duplicate(true)
	check(Festivals.check({"festivals": {"a": f}}) == "", "Moon Night with its race passes on its own")
	var bad := {
		"seconds": {"seconds": 5}, "lead": {"lead": 20}, "partners": {"partners": ["tome"]},
		"rounds": {"rounds": [{"beats": 4, "beat": 1.0}]}, "cell": {"cell": [22, 8]},
		"prizes": {"prizes": [{"money": 1}, {"money": 1}, {"money": 1}, {"money": 1}, {"money": 1}, {"money": 1}, {"money": 1}]},
	}
	for what in bad:
		var h := f.duplicate(true)
		h.game.merge(bad[what], true)
		check(Festivals.check({"festivals": {"a": h}}) != "", "a race with a bad %s is refused" % what)
	var h := f.duplicate(true)
	h.game.erase("seconds")
	check(Festivals.check({"festivals": {"a": h}}) != "", "a race needs its seconds")
	var m: Dictionary = Festivals.get_festival("years_turn").duplicate(true)
	m.game.seconds = 60
	check(Festivals.check({"festivals": {"a": m}}) != "", "only a race has seconds")
	h = f.duplicate(true)
	h.game.prizes.append({"money": 1})
	h.game.prizes.append({"money": 1})
	check(Festivals.check({"festivals": {"a": h}}) == "", "four rivals and the farmer: five places, no one sits out")


## The race's clock and creel: the count-in, the race, the call, what counts, the save.
func _race_timing() -> void:
	var r := FishingRace.new({"lead": 1.0, "seconds": 5})
	check(not r.running() and not r.over() and r.left() == 5.0 and r.to_go() == 1.0 and r.score() == 0, "a fresh race waits for the call")
	check(not r.land("fish:funa") and r.score() == 0, "a fish before the call doesn't count")
	check(r.advance(1.0) == ["go"] and r.running() and r.to_go() == 0.0, "the call after the count-in")
	check(r.land("fish:funa") and r.land("fish:koi") and r.score() == 2 and r.fish == ["fish:funa", "fish:koi"], "fish go in the creel")
	check(r.advance(2.0).is_empty() and is_equal_approx(r.left(), 3.0), "the time runs down")
	check(r.advance(3.0) == ["time"] and r.over() and not r.running() and r.left() == 0.0, "time is called")
	check(not r.land("fish:funa") and r.score() == 2, "a fish after the call doesn't count")
	check(r.advance(FishingRace.SHOW_RESULT) == ["done"] and r.advance(1.0).is_empty(), "then the results, once")
	var all := FishingRace.new({"seconds": 2})
	check(all.advance(10.0) == ["go", "time", "done"], "no lead: a long step passes everything in order")
	var back := FishingRace.parse({"lead": 1.0, "seconds": 5}, JSON.parse_string(JSON.stringify({"time": 2.5, "fish": ["fish:funa"]})))
	check(back != null and back.time == 2.5 and back.fish == ["fish:funa"] and back.running(), "a race reads back from a save")
	for broken in [null, {"time": "x", "fish": []}, {"time": 1, "fish": [3]}, {"fish": []}]:
		check(FishingRace.parse({"seconds": 5}, broken) == null, "a broken saved race is refused (%s)" % [broken])


## The result lines for every place and winner end on the right lines.
func _race_result_lines() -> void:
	var g := Festivals.game("moon_night")
	for place in range(1, g.rivals.size() + 2):
		for rival in g.rivals:
			var flags := {"contest_place_%d" % place: true}
			if place > 1:
				flags["contest_won_" + rival.who] = true
			var d := DialogueRunner.open(Festivals.DIALOGUE, flags, str(g.id) + "_result")
			var who: Array = []
			var ids: Array = []
			for i in 20:
				if d.done():
					break
				who.append(d.line().get("speaker", ""))
				ids.append(d.line().get("id", ""))
				d.press()
				d.press()
			var want: String = "fishing" + ("_%d" % place if place <= 3 else "_out")
			check(d.error == "" and d.done() and want in ids and (place == 1) != (rival.who in who),
				"fishing race, place %d, %s first: %s %s" % [place, rival.who, who, ids])


## Racing: the flag, the rod, the count-in, casting at the pond, fish into the creel (never a
## once-only fish), the clock holding, the save in the middle, time, the result, one go a year,
## and leaving the map mid-race.
func _race_play() -> void:
	var g := _game()
	g.new_game()
	var said: Array = []
	var hear := func(t): said.append(t)
	g.message.connect(hear)
	var asked: Array = []
	var ask := func(f, p): asked.append([f, p])
	g.game_requested.connect(ask)
	var events: Array = []
	var ev := func(id): events.append(id)
	g.event_requested.connect(ev)
	var cues: Array = []
	var cue := func(w): cues.append(w)
	g.race_changed.connect(cue)
	_set_day(g, "fall", 15, 18, 30)
	g.maps.place("farm", Vector2i(4, 4), Vector2i.DOWN)
	check(g.start_game().why == "none", "no race from the farm")
	var origin := Vector2i(30, 14)
	g.maps.place("town", origin, Vector2i.RIGHT)
	check(g.water_ahead(origin, Vector2i.RIGHT) == Vector2i(31, 14), "below the flag the village pond is right in front")
	g.held = "potato"
	check(g.start_game().why == "held" and said.back() == "The rod takes both hands. Put the Potato down first." and asked.is_empty(), "the rod needs empty hands")
	g.held = ""
	g.inventory.take("rod", 1, ["tools"])
	g.inventory.add("rod", 1, ["chest"])
	check(g.start_game().why == "rod" and g.race == null, "no rod in the tool slots, no race")
	g.inventory.take("rod", 1, ["chest"])
	g.inventory.add("rod", 1, ["tools"])
	g.tool_index = 0
	var s: Dictionary = g.start_game()
	check(s.ok and s.partner == "" and asked == [["moon_night", ""]] and g.race != null and g.current_tool() == "rod" and cues == ["start"],
		"the race starts with the rod in hand")
	check(g.start_game().why == "busy" and asked.size() == 1, "not twice at once")
	check(not g.ticking(), "the clock holds through the race")
	check(g.cast_line(origin, Vector2i.RIGHT) == "race_wait" and not g.fishing.active(), "no casting in the count-in")
	g._race_step(3.0)
	check(cues.back() == "go" and g.race.running(), "the call")
	check(g.cast_line(origin, Vector2i.RIGHT) == "cast" and g.fishing.place == "town", "the line goes into the village pond")
	g.fishing.state = "bite"
	var r: Dictionary = g.reel_in()
	check(r.result == "catch" and r.get("race", false) and g.held == "" and g.race.score() == 1 and g.race.fish[0] == r.fish and cues.back() == "fish",
		"a landed fish goes in the creel, not overhead (%s)" % [r])
	check(int(g.fish_caught.get(r.fish.trim_prefix("fish:"), 0)) == 1, "and counts as caught")
	g.hour = 22   # the moonlit koi's hour (a once-only fish of the village pond)
	for i in 40:
		g.fishing.cast("town", Vector2i(31, 14))
		g.fishing.state = "bite"
		g.reel_in()
	check(g.race.score() == 41 and not "fish:moon_koi" in g.race.fish and not g.fish_caught.has("moon_koi"), "once-only fish don't bite in a race")
	g.hour = 18
	# Saved in the middle and read back: the race goes on.
	g.race.fish = g.race.fish.slice(0, 3)
	g.race.time = 20.0
	var d: Dictionary = g.to_dict()
	g.new_game()
	check(g.from_dict(JSON.parse_string(JSON.stringify(d))) == "" and g.race != null and g.race.score() == 3 and g.race.time == 20.0 and g.race.running(),
		"a race saved in the middle goes on after loading")
	var broken: Dictionary = JSON.parse_string(JSON.stringify(d))
	broken.fishing.race = {"time": 1}
	check(g.from_dict(broken) == "Saved fishing race is broken" and g.race.score() == 3, "a broken saved race is refused")
	broken.fishing.race = {"time": 1, "fish": []}
	broken.day = 16
	check(g.from_dict(broken) == "Saved fishing race is broken", "a race saved on a day without one is refused")
	# Time: the line comes in, the count is judged.
	var top: int = Festivals.judge_game("moon_night", 1, 0).rivals[0].score
	g.race.fish.clear()
	for i in top:
		g.race.fish.append("fish:funa")
	g.cast_line(origin, Vector2i.RIGHT)
	var money: int = g.money
	cues.clear()
	g._race_step(60.0)
	check(cues == ["time", "done"] and not g.fishing.active() and g.race == null, "time is called, the line comes in, the race ends (%s)" % [cues])
	check(events == ["contest_fishing"] and g.events_seen.has("game:moon_night:1") and g.money == money + 400 and g.count("food:grilled_fish") == 2
		and g.count("ribbon:fishing:1") == 1 and int(g.flags.get("game_best_fishing", 0)) == top and g.flags.get("contest_place_1") == true
		and not g.flags.keys().any(func(k): return k.begins_with("contest_partner_")), "a tie with the best: first prize, the ribbon, the result event")
	check(Keepsakes.record(g.flags).back() == {"festival": "fishing", "place": 1, "year": 1} and said.has("You got a Moon Pond Race ribbon (1st)!"),
		"the ribbon goes on the board's record")
	check(g.ticking(), "the clock runs again")
	check(g.start_game().why == "played" and said.back() == "You already took a turn at the Moon Pond Race this year.", "one go a year")
	# Year 2: walking off mid-race ends it with the creel as it is (one fish: last, no ribbon).
	g.year = 2
	g.maps.place("town", origin, Vector2i.RIGHT)
	check(load("res://scripts/farm_actions.gd").festival_spot(Vector2i(30, 13)) and g.race != null, "E at the flag starts the race")
	g._race_step(3.0)
	g.race.land("fish:funa")
	g.go_to_map("farm", Vector2i(4, 4), Vector2i.DOWN)
	check(g.race == null and events.back() == "contest_fishing" and g.events_seen.has("game:moon_night:2") and g.flags.get("contest_place_6") == true
		and Keepsakes.record(g.flags).back().year == 1 and int(g.flags.get("game_best_fishing", 0)) == top,
		"leaving the village ends the race and judges its one fish")
	g.message.disconnect(hear)
	g.game_requested.disconnect(ask)
	g.event_requested.disconnect(ev)
	g.race_changed.disconnect(cue)
	# The flag in 3D: a mesh of its own, not the magenta stand-in.
	var props: Node = load("res://scripts/world3d/festival_props.gd").new("town")
	root.add_child(props)
	var before := props.get_child_count()
	props._make({"kind": "race_flag", "cell": [30, 13]})
	check(props.get_child_count() - before >= 6, "the pole, the banner, its fish and the creel in 3D (%d)" % (props.get_child_count() - before))
	props.free()
	g.new_game()
