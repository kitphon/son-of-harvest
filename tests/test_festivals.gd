extends SceneTree
## Headless checks for festivals (data/festivals.json, Festivals, Game's festival day, shops
## shut for it, the fair weather, villagers gathering, the event once a year, the decorations
## and lights in both views, the HUD tag). Run:
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


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_fireworks()   # loads the glow script, which needs the Game autoload
		_game_day()
		_weather()
		_shops()
		_event()
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
	check(Festivals.props_now("blossom_day", "town", 700).size() == 9 and Festivals.props_now("blossom_day", "town", 1000).is_empty()
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
	var huds: Array = _scene3.get_children().filter(func(n): return _script_is(n, "hud.gd"))
	check(huds.size() == 1 and huds[0]._fest_box.visible and huds[0]._fest.text == "Blossom Day", "the HUD shows the festival")
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
	var glow: GDScript = load("res://scripts/world3d/festival_glow.gd")
	check(glow.fireworks_on(), "fireworks over the village at 20:00")
	g.maps.place("farm", Vector2i(4, 4), Vector2i.DOWN)
	check(not glow.fireworks_on(), "not over the farm")
	_scene3.free()
	_scene2.free()
	g.unpause()


## Views are checked by script path: in a --script run the autoload isn't known when this
## file compiles, so naming the view classes here would fail to compile.
func _script_is(n: Node, file: String) -> bool:
	return n.get_script() != null and n.get_script().resource_path.ends_with(file)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
