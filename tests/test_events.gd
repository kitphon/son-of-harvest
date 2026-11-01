extends SceneTree
## Headless event checks (EventRunner, EventTriggers, the event data, Game's weekday and
## event pause, examining a spot through FarmActions and the EventPlayer). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_events.gd

var failures := 0
var talked: Array = []   # dialogues the runner asked for, as "id@line"


func _init() -> void:
	var g := _game()
	g.dialogue_requested.connect(func(id, at):
		talked.append(id + "@" + at)
		g.dialogue_open = true)   # the text box opened; the test closes it

	# Every event and every trigger table in data/events loads.
	for file in DirAccess.get_files_at(EventRunner.DIR):
		if not file.ends_with(".json"):
			continue
		if file.begins_with("triggers_"):
			var t := EventTriggers.open(file.get_basename().trim_prefix("triggers_"))
			check(t.error == "" and not t.rows.is_empty(), "data/events/%s loads (%s)" % [file, t.error])
		else:
			var r := EventRunner.open(file.get_basename(), g)
			check(r.error == "" and not r.done(), "data/events/%s loads (%s)" % [file, r.error])
	check(EventRunner.open("no_such_event", g).error == "No event no_such_event", "a missing event is refused")
	check(EventRunner.open("triggers_farm", g).error != "", "a trigger table isn't an event")
	check(EventTriggers.open("no_such_map").error == "" and EventTriggers.open("no_such_map").rows.is_empty(), "a map without a table has no events")

	# The sample first morning, step by step.
	var start := Vector2(4 * 16 + 8, 4 * 16 + 10)
	var bag_before: int = g.count("seeds:turnip")
	var sounds: Array = []
	var r := EventRunner.open("first_morning", g)
	r.sound.connect(func(k): sounds.append(k))
	r.start(start, Vector2i.RIGHT)
	r.update(0.0)
	check(r.fade == 1.0 and r.facing == Vector2i.DOWN and r.step().do == "wait", "starts black, faces down, waits")
	r.update(0.3)
	check(r.step().do == "wait" and sounds.is_empty(), "0.3 s of 0.6: still waiting")
	r.update(0.3)
	check(sounds == ["chime_morning"] and r.step().do == "fade", "after the wait: the chime, then the fade")
	r.update(0.6)
	check(is_equal_approx(r.fade, 0.5), "half way through the fade (%.2f)" % r.fade)
	r.update(0.6)
	check(r.fade == 0.0 and talked == ["first_morning@"] and r.step().do == "say", "faded in, the text box opens")
	r.update(1.0)
	check(r.step().do == "say", "the event waits while the text box is open")
	g.dialogue_open = false
	r.update(0.0)   # time left over from a step isn't carried on, so the walk starts next
	r.update(0.25)
	check(r.walking and r.facing == Vector2i.DOWN and r.pos.y > start.y, "the box closed: walking down")
	r.update(1.0)
	check(r.pos == Vector2(72, 6 * 16 + 8) and not r.walking, "two cells down, on the cell's middle (%s)" % r.pos)
	r.update(0.3)
	r.update(0.4)
	check(r.facing == Vector2i.UP and sounds.back() == "pick", "turns back to the door, picks up the sack")
	check(g.count("seeds:turnip") == bag_before + 3 and talked.back() == "first_morning@sack", "three seed bags given, then the sack lines")
	g.dialogue_open = false
	r.update(0.0)
	check(r.done() and g.flags.get("got_tsuru_seeds") == true and r.fade == 0.0, "flag set and the event is over")
	r.update(1.0)
	check(r.done(), "a finished event stays finished")

	# Branches, jumps, flags, money and walking with `to`, from a script written here.
	g.flags = {"met": 1}
	g.money = 100
	r = EventRunner.new({"steps": [
		{"if": "met", "then": "known"},
		{"do": "money", "amount": 999, "next": "end"},
		{"id": "known", "unless": "rich", "then": "poor"},
		{"do": "clear", "flags": ["rich"]},
		{"id": "poor", "do": "money", "amount": -150},
		{"do": "set", "flags": {"rich": false, "visits": 2.0, "mood": "glad"}},
		{"do": "clear", "flags": ["met"]},
		{"do": "walk", "to": [2, 4], "run": true},
		{"do": "face", "dir": "right"},
	]}, g)
	check(r.error == "", "an inline script loads (%s)" % r.error)
	r.start(Vector2(72, 74), Vector2i.DOWN)
	r.update(0.0)
	check(g.money == 0, "if met -> known; unless rich -> poor; money never below 0 (%d)" % g.money)
	check(g.flags == {"rich": false, "visits": 2, "mood": "glad"} and typeof(g.flags.visits) == TYPE_INT, "set and clear flags %s" % g.flags)
	check(r.running and r.facing == Vector2i.LEFT, "running left to the target column")
	r.update(0.2)
	check(is_equal_approx(r.pos.x, 72 - r.run_speed * 0.2), "runs at the farmer's run speed")
	r.update(0.2)
	check(r.facing == Vector2i.UP or r.pos == Vector2(40, 72), "then up the column")
	r.update(1.0)
	check(r.done() and r.pos == Vector2(40, 72) and r.facing == Vector2i.RIGHT and not r.running, "arrives, faces right, done")

	# A loop with no wait in it can't hang the game: one update stops after MAX_STEPS.
	g.flags = {"x": true}
	r = EventRunner.new({"steps": [{"id": "a", "if": "x", "then": "a"}]}, g)
	r.update(0.0)
	check(not r.done(), "an endless instant loop returns")

	# Bad scripts are refused and say why.
	for bad in [null, [], {"steps": []}, {"steps": [1]}, {"steps": [{"do": "dance"}]},
			{"steps": [{"do": "wait"}]}, {"steps": [{"do": "wait", "seconds": 61}]},
			{"steps": [{"do": "wait", "seconds": 1, "speed": 2}]},
			{"steps": [{"do": "say", "dialogue": "nope"}]}, {"steps": [{"do": "say", "dialogue": "bin_note", "at": "nope"}]},
			{"steps": [{"do": "face", "dir": "north"}]}, {"steps": [{"do": "walk"}]},
			{"steps": [{"do": "walk", "to": [1, 2], "by": [0, 1]}]}, {"steps": [{"do": "walk", "by": [0.5, 1]}]},
			{"steps": [{"do": "walk", "by": [0, 1], "run": "yes"}]},
			{"steps": [{"do": "set", "flags": {"x": [1]}}]}, {"steps": [{"do": "set", "flags": {}}]},
			{"steps": [{"do": "clear", "flags": "x"}]}, {"steps": [{"do": "give", "item": "gold"}]},
			{"steps": [{"do": "give", "item": "seeds:turnip", "count": 0}]}, {"steps": [{"do": "money", "amount": 0}]},
			{"steps": [{"do": "money", "amount": 1.5}]}, {"steps": [{"do": "fade", "to": "white"}]},
			{"steps": [{"do": "sound", "key": "trumpet"}]}, {"steps": [{"do": "wait", "seconds": 1, "next": "x"}]},
			{"steps": [{"if": "x", "then": "end"}]}, {"steps": [{"if": "x", "unless": "y", "then": "a", "id": "a"}]},
			{"steps": [{"id": "a", "do": "wait", "seconds": 1}, {"id": "a", "do": "wait", "seconds": 1}]}]:
		r = EventRunner.new(bad, g)
		check(r.error != "" and r.done(), "refused %s (%s)" % [JSON.stringify(bad), r.error])

	# Trigger rows: the first match in table order wins; conditions narrow it down.
	var s: Dictionary = {"year": 1, "season": "spring", "day": 1, "weekday": "mon", "time": 6 * 60,
		"weather": "sunny", "flags": {}, "seen": {}, "cell": Vector2i(4, 4)}
	var t := EventTriggers.new({"rows": [
		{"event": "rainy_day", "on": "day_start", "weather": ["rain"]},
		{"event": "first_morning", "on": ["enter", "day_start"], "days": [1, 3], "time": ["6:00", "9:00"]},
		{"event": "pond_first", "on": ["enter", "day_start"], "once": false},
	]})
	check(t.error == "", "inline table loads (%s)" % t.error)
	check(t.pick("day_start", s) == "first_morning", "sunny: the rain row is skipped, the next one matches")
	check(t.pick("minute", s) == "", "no row listens to minutes")
	s.weather = "rain"
	check(t.pick("day_start", s) == "rainy_day" and t.pick("enter", s) == "first_morning", "rain on day start: the first row wins")
	s.weather = "sunny"
	s.time = 9 * 60
	check(t.pick("enter", s) == "pond_first", "9:00 is past the window [6:00, 9:00)")
	s.time = 8 * 60 + 59
	s.seen = {"first_morning": true}
	check(t.pick("enter", s) == "pond_first", "a seen event doesn't play again")
	s.seen = {"pond_first": true, "first_morning": true}
	check(t.pick("enter", s) == "pond_first", "once: false plays again")
	var row := {"event": "pond_first", "on": "step", "season": ["spring", "fall"], "weekday": ["mon"],
		"year": [1, 2], "flags": ["a"], "not_flags": ["b"], "seen": ["first_morning"],
		"not_seen": ["rainy_day"], "area": [3, 4, 2, 1]}
	s = {"year": 2, "season": "fall", "day": 9, "weekday": "mon", "time": 600, "weather": "snow",
		"flags": {"a": "yes", "b": 0}, "seen": {"first_morning": true}, "cell": Vector2i(4, 4)}
	check(EventTriggers.check_row(row) == "" and EventTriggers.matches(row, "step", s), "every condition holds")
	for change in [["season", "winter"], ["weekday", "tue"], ["year", 3], ["flags", {"a": true, "b": true}],
			["flags", {}], ["seen", {}], ["seen", {"first_morning": true, "rainy_day": true, "pond_first": false}],
			["cell", Vector2i(5, 5)], ["cell", Vector2i(2, 4)]]:
		var s2 := s.duplicate()
		s2[change[0]] = change[1]
		check(not EventTriggers.matches(row, "step", s2), "no match when %s is %s" % change)
	check(EventTriggers.matches(row, "step", s.merged({"cell": Vector2i(3, 4)}, true)), "the area's corner cell counts")
	check(EventTriggers.clock("6:00") == 360 and EventTriggers.clock("24:00") == 1440 and EventTriggers.clock("6:60") == -1
		and EventTriggers.clock("6") == -1 and EventTriggers.clock("6:5") == -1, "clock times")
	for bad in [1, {"on": "step"}, {"event": "nope", "on": "step"}, {"event": "pond_first"},
			{"event": "pond_first", "on": "talk"}, {"event": "pond_first", "on": []},
			{"event": "pond_first", "on": "step", "colour": "red"}, {"event": "pond_first", "on": "step", "once": 1},
			{"event": "pond_first", "on": "step", "days": [5, 2]}, {"event": "pond_first", "on": "step", "year": [0, 1]},
			{"event": "pond_first", "on": "step", "season": ["monsoon"]}, {"event": "pond_first", "on": "step", "weekday": ["monday"]},
			{"event": "pond_first", "on": "step", "weather": ["fog"]}, {"event": "pond_first", "on": "step", "time": ["9:00", "6:00"]},
			{"event": "pond_first", "on": "step", "time": ["6:00"]}, {"event": "pond_first", "on": "step", "flags": "a"},
			{"event": "pond_first", "on": "step", "not_seen": [""]}, {"event": "pond_first", "on": "step", "area": [1, 1, 0, 1]},
			{"event": "pond_first", "on": "step", "area": [1, 1, 1]},
			{"event": "pond_first", "on": "examine"}, {"event": "pond_first", "on": "step", "spot": [1, 1]},
			{"event": "pond_first", "on": ["examine", "step"], "spot": [1, 1]},
			{"event": "pond_first", "on": "examine", "spot": [1, 1, 1]}, {"event": "pond_first", "on": "examine", "spot": [1, 1, 0, 2]},
			{"event": "pond_first", "on": "examine", "spot": [1.5, 1]}]:
		check(EventTriggers.check_row(bad) != "", "refused row %s" % JSON.stringify(bad))
	check(EventTriggers.new({"rows": [{"event": "nope", "on": "step"}]}).rows.is_empty(), "a table with a bad row has no rows")

	# The farm's table with a new game: the opening on entering, once; a loaded game that has
	# seen it (or a save from before it, with the first morning seen) doesn't play it again.
	g.free()
	g = _game()
	var farm := EventTriggers.open("farm")
	check(farm.pick("enter", g.trigger_state(Vector2i(4, 4))) == "opening", "new game: the opening plays on entering")
	check(farm.pick("day_start", g.trigger_state(Vector2i(4, 4))) == "opening", "and on the first day's start")
	g.events_seen.opening = true   # EventPlayer.play marks it as it starts
	var loaded := _game()
	check(loaded.from_dict(JSON.parse_string(JSON.stringify(g.to_dict()))) == "" and loaded.events_seen.has("opening"), "the save keeps the opening as seen")
	check(farm.pick("enter", loaded.trigger_state(Vector2i(4, 4))) == "" and farm.pick("day_start", loaded.trigger_state(Vector2i(4, 4))) == "",
		"loading that save on the first morning: no opening again")
	loaded.events_seen = {"first_morning": true}
	check(farm.pick("enter", loaded.trigger_state(Vector2i(4, 4))) == "", "an older save that saw the first morning: no opening")
	loaded.free()
	g.day = 2
	g.weather_today = "rain"
	check(farm.pick("day_start", g.trigger_state(Vector2i(4, 4))) == "rainy_day", "the first rainy morning")
	g.events_seen.rainy_day = true
	check(farm.pick("day_start", g.trigger_state(Vector2i(4, 4))) == "", "and only the first")
	check(farm.pick("step", g.trigger_state(Vector2i(24, 3))) == "pond_first", "stepping up to the pond")
	check(farm.pick("step", g.trigger_state(Vector2i(20, 3))) == "", "not further away")

	# Examine: the spot faced, a cell or a rectangle, with the usual conditions on top.
	var spot_row := {"event": "pond_first", "on": "examine", "spot": [18, 1, 2, 2], "time": ["6:00", "18:00"]}
	var ss: Dictionary = g.trigger_state(Vector2i(18, 3))
	check(EventTriggers.check_row(spot_row) == "" and EventTriggers.check_row({"event": "pond_first", "on": "examine", "spot": [4, 4]}) == "", "examine rows with a spot load")
	check(not EventTriggers.matches(spot_row, "examine", ss), "no spot in the state (another cause): no examine match")
	for c in [Vector2i(18, 1), Vector2i(19, 2)]:
		check(EventTriggers.matches(spot_row, "examine", ss.merged({"spot": c}, true)), "examining %s inside the spot" % c)
	for c in [Vector2i(20, 2), Vector2i(18, 3)]:
		check(not EventTriggers.matches(spot_row, "examine", ss.merged({"spot": c}, true)), "examining %s outside the spot" % c)
	check(not EventTriggers.matches(spot_row, "step", ss.merged({"spot": Vector2i(18, 1)}, true)), "an examine row ignores other causes")
	check(not EventTriggers.matches(spot_row, "examine", ss.merged({"spot": Vector2i(18, 1), "time": 18 * 60}, true)), "the time still counts")
	# The tables: shrine, lanterns (snow, then evening, then day), houses, farm and farmhouse.
	var town := EventTriggers.open("town")
	var at := func(t: EventTriggers, c: Vector2i, extra := {}) -> String:
		return t.pick("examine", g.trigger_state(Vector2i(0, 0)).merged({"spot": c}).merged(extra, true))
	check(at.call(town, Vector2i(19, 2)) == "shrine_offering", "the shrine's offering box")
	check(at.call(town, Vector2i(16, 3)) == "lantern_day" and at.call(town, Vector2i(21, 3), {"time": 20 * 60}) == "lantern_night"
		and at.call(town, Vector2i(16, 3), {"time": 20 * 60, "weather": "snow"}) == "lantern_snow", "the lanterns by day, at night, in snow")
	check(at.call(town, Vector2i(5, 6)) == "" and at.call(town, Vector2i(8, 15)) == "" and at.call(town, Vector2i(23, 15)) == "", "the house and shop doors are left to the doors")
	g.events_seen.shrine_offering = true
	check(at.call(town, Vector2i(18, 1)) == "shrine_offering", "examine rows play every time")
	check(at.call(town, Vector2i(17, 3)) == "" and town.pick("step", g.trigger_state(Vector2i(19, 2))) == "", "nothing beside the spots or on stepping")
	check(at.call(farm, Vector2i(5, 3)) == "farm_nameplate" and at.call(farm, Vector2i(31, 4)) == "farm_sign", "the farm's name plate and gate board")
	var house := EventTriggers.open("house")
	check(at.call(house, Vector2i(3, 0)) == "calendar_spring" and at.call(house, Vector2i(3, 0), {"season": "winter"}) == "calendar_winter"
		and at.call(house, Vector2i(6, 1)) == "house_radio", "the farmhouse calendar per season and the radio")
	# The shrine coin: the choice sets a flag, the event pays 5 G and clears it.
	g.money = 100
	g.dialogue_requested.connect(func(id, line):
		talked.append(id + "@" + line)
		g.dialogue_open = true)
	var coin := EventRunner.open("shrine_offering", g)
	coin.start(Vector2(18 * 16 + 8, 3 * 16 + 10), Vector2i.DOWN)
	talked.clear()
	coin.update(0.0)
	check(coin.facing == Vector2i.UP and talked == ["examine_town@offering"], "faces the shrine and asks %s" % [talked])
	g.flags.shrine_coin = true   # what the "Drop in a coin" choice sets
	g.dialogue_open = false
	for i in 20:
		coin.update(0.1)
		g.dialogue_open = false
	check(g.money == 95 and not EventRunner.is_set(g.flags, "shrine_coin") and coin.done()
		and talked == ["examine_town@offering", "examine_town@coin"], "a coin: 5 G, flag cleared %s" % [talked])

	# The opening, played through with every text box closed at once: the farmer comes in at
	# the gate, Tome acts in it (placed, walking, turning, leaving) and gives seed potatoes.
	g.free()
	g = _game()
	g.dialogue_requested.connect(func(id, line):
		talked.append(id + "@" + line)
		g.dialogue_open = true)
	talked.clear()
	var potatoes: int = g.count("seeds:potato")
	r = EventRunner.open("opening", g)
	r.start(Vector2(4 * 16 + 8, 4 * 16 + 10), Vector2i.DOWN)
	r.update(0.0)
	check(r.fade == 1.0 and r.pos == Vector2(30 * 16 + 8, 6 * 16 + 8) and r.facing == Vector2i.LEFT, "black, the farmer at the gate facing in (%s)" % r.pos)
	check(r.actors.has("tome") and r.actors.tome.pos == Vector2(24.5, 6.5) and r.actors.tome.facing == Vector2i.RIGHT, "Tome waits by the pond %s" % [r.actors])
	var tome_walked := false
	var tome_faced := {}
	for i in 600:
		r.update(0.1)
		g.dialogue_open = false
		if r.done():
			break
		tome_walked = tome_walked or r.actors.get("tome", {}).get("moving", false)
		if r.actors.has("tome"):
			tome_faced[r.actors.tome.facing] = true
	check(r.done() and r.actors.is_empty(), "the opening ends, no actors left")
	check(tome_walked and tome_faced.size() == 4, "Tome walked and turned every way (%d)" % tome_faced.size())
	check(talked == ["opening@arrive", "opening@greet", "opening@field", "opening@bin", "opening@road", "opening@gift", "opening@bye", "opening@alone"],
		"the opening's lines in order %s" % [talked])
	check(g.count("seeds:potato") == potatoes + 2 and EventRunner.is_set(g.flags, "met_tome"), "two seed potato bags and the met_tome flag")
	check(r.pos == Vector2(12 * 16 + 8, 5 * 16 + 8) and r.facing == Vector2i.RIGHT, "the farmer ends by the stand, looking after Tome (%s)" % r.pos)

	# A heart scene played by a talk: Kota stays where his plan has him, turns to the farmer
	# and stands there for his lines; the farmer turns to him; at the end he is back in his plan.
	talked.clear()
	r = EventRunner.open("heart_kota_6", g)
	r.start(Vector2(10 * 16 + 8, 5 * 16 + 8), Vector2i.UP)
	r.on_stage = {"kota": {"pos": Vector2(10.5, 4.5), "facing": Vector2i.LEFT}}
	r.update(0.0)
	check(r.actors.has("kota") and r.actors.kota.pos == Vector2(10.5, 4.5) and r.actors.kota.facing == Vector2i.DOWN
		and r.facing == Vector2i.UP, "talked to: Kota stays put and faces the farmer %s" % [r.actors])
	var kota_moved := false
	var kota_in_lines := false
	for i in 100:
		r.update(0.1)
		if g.dialogue_open:
			kota_in_lines = r.actors.has("kota") and r.actors.kota.facing == Vector2i.DOWN
		g.dialogue_open = false
		kota_moved = kota_moved or r.actors.get("kota", {}).get("moving", false)
		if r.done():
			break
	check(r.done() and kota_in_lines and not kota_moved and talked == ["heart_events_6@kota"], "he stands facing the farmer through his lines, never walking")
	check(r.actors.is_empty() and r.pos == Vector2(10 * 16 + 8, 5 * 16 + 8), "the scene ends, Kota back to his plan")

	# Played where his plan has him elsewhere: he comes in from beside the farmer (on the side
	# away from them), walks up to the cell in front, faces them, and walks back off at the end.
	talked.clear()
	r = EventRunner.open("heart_kota_6", g)
	r.start(Vector2(10 * 16 + 8, 5 * 16 + 8), Vector2i.LEFT)
	r.update(0.0)
	check(r.actors.has("kota") and r.actors.kota.pos == Vector2(9.5 - EventRunner.COME_IN, 5.5) and r.actors.kota.facing == Vector2i.RIGHT,
		"off stage: Kota comes in from the left %s" % [r.actors])
	r.update(0.5)
	check(r.actors.kota.moving and r.actors.kota.pos.x > 5.5 and talked.is_empty(), "walking up, no lines yet")
	for i in 40:
		r.update(0.1)
		if g.dialogue_open:
			break
	check(r.actors.kota.pos == Vector2(9.5, 5.5) and r.actors.kota.facing == Vector2i.RIGHT and not r.actors.kota.moving
		and r.facing == Vector2i.LEFT and talked == ["heart_events_6@kota"], "in front of the farmer, facing each other, then his lines %s" % [r.actors])
	g.dialogue_open = false
	var went_back := false
	for i in 100:
		r.update(0.1)
		g.dialogue_open = false
		if r.actors.has("kota") and r.actors.kota.moving:
			went_back = went_back or r.actors.kota.facing == Vector2i.LEFT
		if r.done():
			break
	check(r.done() and went_back and r.actors.is_empty(), "he walks back off the way he came, then is gone")

	# Coming in from the right while the farmer faces down, the walk turns the corner below
	# the farmer, not on the farmer's cell; `face` with a villager turns the farmer to them.
	r = EventRunner.new({"steps": [{"do": "actor", "who": "tome", "at": [14, 5], "to": "farmer", "face": "farmer"},
			{"do": "face", "dir": "tome"}, {"do": "wait", "seconds": 1}]}, g)
	r.start(Vector2(10 * 16 + 8, 5 * 16 + 8), Vector2i.DOWN)
	var on_farmer := false
	for i in 60:
		r.update(0.1)
		if r.actors.has("tome") and Vector2i(r.actors.tome.pos.floor()) == Vector2i(10, 5):
			on_farmer = true
		if r.step().do == "wait":
			break
	check(not on_farmer and r.actors.tome.pos == Vector2(10.5, 6.5) and r.actors.tome.facing == Vector2i.UP and r.facing == Vector2i.DOWN,
		"Tome walks round the farmer to the cell in front, faces up %s" % [r.actors])

	# "wait": false: two actors walk at once; an actor holds an item until it is put down.
	r = EventRunner.new({"steps": [{"do": "actor", "who": "tome", "at": [2, 2], "to": [6, 2], "hold": "turnip", "wait": false},
			{"do": "actor", "who": "kota", "at": [2, 4], "to": [6, 4], "face": "up"},
			{"do": "actor", "who": "tome", "hold": ""}, {"do": "wait", "seconds": 1}]}, g)
	r.start(Vector2(10 * 16 + 8, 8 * 16 + 8), Vector2i.UP)
	r.update(0.1)   # both steps begin; walks move from the next update on
	r.update(0.4)
	check(r.actors.tome.moving and r.actors.kota.moving and r.actors.tome.hold == "turnip" and r.actors.kota.hold == ""
		and r.step().who == "kota", "Tome and Kota walk side by side, Tome with a turnip overhead %s" % [r.actors])
	for i in 30:
		r.update(0.1)
		if r.step().get("do") == "wait":
			break
	check(r.actors.tome.pos == Vector2(6.5, 2.5) and r.actors.kota.pos == Vector2(6.5, 4.5) and r.actors.kota.facing == Vector2i.UP
		and r.actors.tome.hold == "", "both arrive; then Tome puts the turnip down %s" % [r.actors])
	r = EventRunner.new({"steps": [{"do": "actor", "who": "tome", "at": [2, 2], "to": [6, 2], "wait": false}, {"do": "wait", "walks": true}]}, g)
	r.start(Vector2(10 * 16 + 8, 8 * 16 + 8), Vector2i.UP)
	r.update(0.1)
	r.update(0.5)
	check(r.step().get("walks") == true and r.actors.tome.moving, "a wait with walks waits while an actor walks")
	for i in 20:
		r.update(0.1)
	check(r.done(), "and ends once they arrive")
	check(EventRunner.holdable("fish:ayu") and EventRunner.holdable("egg_good") and EventRunner.holdable("potato")
		and not EventRunner.holdable("seeds:potato") and not EventRunner.holdable("fish:") and not EventRunner.holdable("rock"), "what an actor can hold")

	# Actor and place steps that are wrong are refused.
	for bad in [{"do": "actor", "who": "nobody", "at": [1, 1]}, {"do": "actor", "who": "tome"},
			{"do": "actor", "who": "tome", "to": [1]}, {"do": "actor", "who": "tome", "face": "north"},
			{"do": "actor", "who": "tome", "leave": false}, {"do": "actor", "who": "tome", "leave": true, "at": [1, 1]},
			{"do": "actor", "who": "tome", "at": [1, 1], "speed": 2}, {"do": "actor", "who": "tome", "at": "farmer"},
			{"do": "actor", "who": "tome", "to": "home"}, {"do": "actor", "who": "tome", "at": "plan", "face": "kota"},
			{"do": "actor", "who": "tome", "at": [1, 1], "hold": "rock"}, {"do": "actor", "who": "tome", "at": [1, 1], "wait": false},
			{"do": "actor", "who": "tome", "to": [1, 1], "wait": "no"}, {"do": "wait", "walks": 1}, {"do": "wait", "walks": false}, {"do": "actor", "who": "tome", "leave": true, "hold": ""},
			{"do": "face", "dir": "nobody"}, {"do": "place"},{"do": "place", "at": [1, 1], "dir": "in"}]:
		r = EventRunner.new({"steps": [bad]}, g)
		check(r.error != "" and r.done(), "refused %s (%s)" % [JSON.stringify(bad), r.error])

	# The shops: each intro on the first entering only; the keeper stands behind the counter.
	for shop in [["store", "store_intro", "sayo"], ["smithy", "smithy_intro", "hachiro"]]:
		var tbl := EventTriggers.open(shop[0])
		check(tbl.error == "" and tbl.pick("enter", g.trigger_state(Vector2i(4, 5))) == shop[1], "first time in the %s: %s" % [shop[0], shop[1]])
		g.events_seen[shop[1]] = true
		check(tbl.pick("enter", g.trigger_state(Vector2i(4, 5))) == "", "the second time in the %s: nothing" % shop[0])
		talked.clear()
		r = EventRunner.open(shop[1], g)
		r.start(Vector2(4 * 16 + 8, 5 * 16 + 8), Vector2i.UP)
		r.update(0.0)
		var keeper_seen: bool = r.actors.has(shop[2])
		for i in 100:
			r.update(0.1)
			g.dialogue_open = false
			if r.done():
				break
		check(keeper_seen and r.done() and r.pos == Vector2(3 * 16 + 8, 4 * 16 + 8) and r.facing == Vector2i.UP,
			"%s: the keeper is there, the farmer at the counter" % shop[1])
		check(talked == ["shop_intros@" + shop[0]] and EventRunner.is_set(g.flags, "met_" + shop[2]), "%s: the intro lines, met_%s" % [shop[1], shop[2]])

	# Weekdays: spring 1 of year 1 is a Monday and the week runs on across seasons and years
	# (a year is 120 days, so year 2 starts on a Tuesday).
	g.free()
	g = _game()
	var days := []
	for d in [[1, 0, 1], [1, 0, 7], [1, 0, 8], [1, 1, 1], [2, 0, 1]]:
		g.year = d[0]
		g.season = d[1]
		g.day = d[2]
		days.append(g.weekday())
	check(days == ["mon", "sun", "mon", "wed", "tue"], "weekdays %s" % [days])

	# A running event holds the clock, like a text box; a new game clears it and the seen list.
	g.event_running = true
	check(g.paused() and not g.ticking(), "an event pauses the clock")
	g.events_seen = {"x": true}
	g.new_game()
	check(not g.event_running and g.events_seen.is_empty(), "a new game: no event running, none seen")
	g.add_money(-99999)
	check(g.money == 0, "add_money never goes below 0")

	g.free()


var _frame := 0
var _player: Node
var _events: Node   # EventPlayer; loaded by path, since it needs the Game autoload to compile
var _saved: Dictionary


## Ends the event playing in the EventPlayer at once, as if it had run to its end.
func _stop() -> void:
	var g: Node = root.get_node("Game")
	_events.runner = null
	g.event_running = false
	g.dialogue_open = false
	Villagers.actors = {}


## On the real Game, in the tree: interact facing a spot asks the trigger table first; an item
## held overhead on the farm is thrown instead.
func _process(_delta: float) -> bool:
	_frame += 1
	var g: Node = root.get_node("Game")
	if _frame == 1:
		g.new_game()
		g.events_seen = {"first_morning": true, "rainy_day": true}
		g.dialogue_requested.connect(func(_id, _at): g.dialogue_open = true)   # a text box stands open
		_player = load("res://scripts/player/player.gd").new()
		_player.farm = g.farm
		root.add_child(_player)
		_events = load("res://scripts/events/event_player.gd").new(_player)
		root.add_child(_events)
	elif _frame == 3:
		var actions: GDScript = load("res://scripts/farm_actions.gd")
		g.held = "turnip"
		actions.on_action("interact", Vector2i(3, 4), Vector2i.UP)
		check(not _events.is_playing() and g.held == "turnip", "holding a turnip on the farm: interact throws (blocked here), no examine")
		g.held = ""
		actions.on_action("interact", Vector2i(3, 4), Vector2i.UP)
		check(_events.is_playing() and g.events_seen.has("farm_nameplate"), "interact facing the name plate plays its event")
		g.dialogue_open = false   # (paused while the box is open; this checks the runner)
		check(not actions.examine(Vector2i(31, 4)) and not g.events_seen.has("farm_sign"), "no second examine while one plays")
		check(not actions.examine(Vector2i(10, 10)), "nothing to examine on open ground")
		_stop()
		g.new_game()   # a new game from the title: the farm's "enter" plays the opening
		_player.position = g.maps.pos
		_events.enter_map("farm")
	elif _frame == 5:
		check(_events.is_playing() and _events.runner.id == "opening", "a new game plays the opening")
		var here: Array = Villagers.on_map("farm", g.day_minutes(), g.trigger_state(Vector2i.ZERO)).map(func(w): return w.id)
		check(here == ["tome"], "Tome stands on the farm while the opening plays %s" % [here])
		_saved = JSON.parse_string(JSON.stringify(g.to_dict()))
		_stop()
		check(Villagers.on_map("farm", g.day_minutes(), g.trigger_state(Vector2i.ZERO)).is_empty(), "after the event Tome is gone again")
		g.new_game()
		check(g.from_dict(_saved) == "", "Continue: the save loads")
		_player.position = g.maps.pos
		_events.enter_map("farm")
	elif _frame == 7:
		check(not _events.is_playing(), "Continue on the first morning doesn't replay the opening")
		_events.enter_map("store")
	elif _frame == 9:
		check(_events.is_playing() and _events.runner.id == "store_intro", "first time in the store: the intro")
		var here: Array = Villagers.on_map("store", g.day_minutes(), g.trigger_state(Vector2i.ZERO)).map(func(w): return w.id)
		check(here == ["sayo"], "Sayo behind the counter %s" % [here])
		_stop()
		_events.enter_map("store")
	elif _frame == 11:
		check(not _events.is_playing(), "the store intro plays once")
		_events.enter_map("smithy")
	elif _frame == 13:
		check(_events.is_playing() and _events.runner.id == "smithy_intro", "first time in the smithy: the intro")
		_stop()
		_events.enter_map("smithy")
	elif _frame == 15:
		check(not _events.is_playing(), "the smithy intro plays once")
		_events.free()
		_player.free()
		g.dialogue_open = false
		g.event_running = false
		g.new_game()
		print("test_events: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


func _game() -> Node:
	var g: Node = (load("res://scripts/autoload/game.gd") as GDScript).new()
	g.crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	g.tools_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	g.body = JSON.parse_string(FileAccess.get_file_as_string("res://data/body.json"))
	g.rng.seed = 5
	g.new_game()
	return g


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
