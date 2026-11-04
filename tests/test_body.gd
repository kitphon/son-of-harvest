extends SceneTree
## Headless checks for fatigue, tired states, oversleeping and collapse (Game + data/body.json). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_body.gd

const SAVE_PATH := SaveGame.SLOT   # Game.sleep() writes the real slot; put back after

var failures := 0


func _init() -> void:
	var keep_save := SaveGame.snapshot(SAVE_PATH)   # the slot, its backup and temp file
	var body: Dictionary = _json("res://data/body.json")
	var g := _game()

	# Tired states from fatigue and stamina; speed and running follow them.
	check(g.fatigue == 0 and g.body_state() == "fine" and g.speed_factor() == 1.0 and g.can_run(), "new game: fine")
	g.fatigue = int(body.states.tired.fatigue)
	check(g.body_state() == "tired" and g.can_run(), "fatigue %d: tired" % g.fatigue)
	check(is_equal_approx(g.speed_factor(), float(body.states.tired.speed)), "tired walks at the tired speed")
	g.fatigue = int(body.states.exhausted.fatigue)
	check(g.body_state() == "exhausted" and not g.can_run(), "fatigue %d: exhausted, no running" % g.fatigue)
	check(is_equal_approx(g.speed_factor(), float(body.states.exhausted.speed)) and g.speed_factor() < 1.0, "exhausted walks slower")
	g.fatigue = 0
	g.stamina = g.max_stamina * int(body.states.tired.stamina_pct) / 100
	check(g.body_state() == "tired", "low stamina: tired")
	g.stamina = 0
	check(g.body_state() == "exhausted", "no stamina: exhausted")
	g.stamina = g.max_stamina

	# A worse state is told once, a better one is quiet.
	var said: Array[String] = []
	g.message.connect(func(t: String): said.append(t))
	g.fatigue = int(body.states.tired.fatigue)
	g.check_body()
	g.check_body()
	check(said == [String(body.states.tired.message)], "tired message once %s" % [said])
	g.fatigue = 0
	g.check_body()
	check(said.size() == 1, "getting better says nothing")

	# Work fatigue: none on a sunny morning, more in rain, late evening and after midnight.
	g.hour = 10
	g.weather_today = "sunny"
	check(g.spend_stamina(2) and g.stamina == g.max_stamina - 2 and g.fatigue == 0, "sunny morning swing: stamina only")
	g.weather_today = "rain"
	g.spend_stamina(2)
	check(g.fatigue == int(body.work.rain), "rain swing adds fatigue (%d)" % g.fatigue)
	g.weather_today = "sunny"
	g.fatigue = 0
	g.hour = 23
	check(g.work_fatigue() == int(body.work.late), "late evening swing")
	g.hour = 1
	check(g.work_fatigue() == int(body.work.after_midnight), "after midnight swing")
	g.hour = 10
	# Overwork: the swing still happens, stamina stops at 0 and the missing points become fatigue.
	g.stamina = 1
	check(g.spend_stamina(5) and g.stamina == 0, "overwork: the swing still happens")
	check(g.fatigue == 4 * int(body.work.overwork_per_stamina), "overwork: 4 missing stamina -> fatigue %d" % g.fatigue)

	# Staying up late adds fatigue on the hour.
	g.fatigue = 0
	g.stamina = g.max_stamina
	g.hour = 21
	g.minute = 59
	g._tick_minute()
	check(g.hour == 22 and g.fatigue == int(body.awake_late["22"]), "awake at 22:00 (+%d)" % g.fatigue)

	# Sleep rest: more hours in bed rest more.
	check(g.sleep_rest(20, 0) > g.sleep_rest(23, 0) and g.sleep_rest(23, 0) > g.sleep_rest(1, 30), "earlier bed rests more")
	check(g.sleep_rest(22, 0) == int(body.sleep.base) + 8 * int(body.sleep.per_hour), "bed at 22:00 = 8 hours")
	# Oversleeping by fatigue and by bedtime.
	check(g.wake_hour(0, 22) == 6, "rested, bed at 22:00: wake at 6")
	for pair in body.oversleep.fatigue:
		check(g.wake_hour(int(pair[0]), 21) == int(pair[1]), "fatigue %d: wake at %d" % [pair[0], pair[1]])
	check(g.wake_hour(int(body.oversleep.fatigue[0][0]) - 1, 21) == 6, "just under the first mark: on time")
	check(g.wake_hour(0, 1) == int(body.oversleep.bed_hour["1"]), "bed at 1:00 oversleeps")
	check(g.wake_hour(int(body.oversleep.fatigue[-1][0]), 1) == int(body.oversleep.fatigue[-1][1]), "the later rule wins")

	# Going to bed: fatigue down by the rest, wakes late when tired, the day moves on.
	g.day = 3
	g.hour = 22
	g.minute = 0
	g.fatigue = 70
	g.sleep()
	check(g.day == 4 and g.hour == g.wake_hour(70, 22) and g.hour > 6, "tired sleep: next day, late (%d:00)" % g.hour)
	check(g.fatigue == maxi(70 - g.sleep_rest(22, 0), 0), "sleep lowered fatigue to %d" % g.fatigue)
	check(said[-1].begins_with("You overslept"), "oversleep message: %s" % said[-1])
	g.hour = 21
	g.fatigue = 10
	g.sleep()
	check(g.hour == 6 and g.fatigue == 0 and said[-1].begins_with("Good morning"), "rested sleep: 6:00")

	# Collapse at full fatigue (here in the field): next day, late, in the clinic bed; the first
	# visit is free, later ones cost the fee; stamina and fatigue from data.
	var c: Dictionary = body.collapse
	check(c.wake_map == "clinic" and MapManager.data("clinic").spawns.has(c.wake_spawn), "collapse wakes on the clinic's %s spawn" % c.wake_spawn)
	check(int(c.fee) > 0 and int(c.free_visits) == 1 and "%d" in String(c.message) and not "%d" in String(c.free_message), "a fee, the first visit free")
	g.money = 500
	g.day = 10
	g.hour = 15
	g.go_to_map("farm", Vector2i(10, 10), Vector2i.DOWN)
	g.fatigue = g.FATIGUE_MAX - 1
	g.spend_stamina(2)   # a rainless afternoon swing: no work fatigue, so add one directly
	g.add_fatigue(5)
	check(g.fatigue == g.FATIGUE_MAX, "fatigue stops at the top")
	g.check_body()
	check(g.day == 11 and g.hour == int(c.wake) and g.minute == 0, "collapse: wake next day at %d:00" % g.hour)
	var bed: Array = MapManager.data("clinic").spawns[c.wake_spawn]
	check(g.maps.id == "clinic" and g.maps.pos == MapManager.cell_pos(bed[0]) and g.maps.facing == bed[1], "collapse: in the clinic bed (%s %s)" % [g.maps.id, g.maps.pos])
	check(g.money == 500, "the first collapse: no fee (%d G)" % g.money)
	check(said[-1] == String(c.free_message), "first collapse message: %s" % said[-1])
	check(g.flags.get("clinic_visits") == 1 and EventRunner.is_set(g.flags, "clinic_wake") and EventRunner.is_set(g.flags, "clinic_free"),
		"the wake and free flags for the doctor's line %s" % [g.flags])
	check(g.stamina == g.max_stamina * int(c.stamina_pct) / 100, "collapse: stamina %d" % g.stamina)
	check(g.fatigue == g.FATIGUE_MAX + int(c.fatigue_change), "collapse: fatigue %d" % g.fatigue)
	# The doctor's line plays on entering the clinic while the flag is set, every time.
	var t := EventTriggers.open("clinic")
	var st := {"year": 1, "season": "spring", "day": 11, "weekday": "thu", "time": 720, "weather": "sunny", "flags": g.flags,
		"seen": {"clinic_wake": true}, "cell": Vector2i(bed[0])}
	check(t.error == "" and t.pick("enter", st) == "clinic_wake", "triggers_clinic: the doctor's line on waking (%s)" % t.error)
	check(t.pick("enter", st.merged({"flags": {}}, true)) == "", "no line on an ordinary visit")
	var r := EventRunner.open("clinic_wake", g)
	check(r.error == "", "clinic_wake runs: %s" % r.error)
	check(DialogueRunner.open("clinic", {}, "wake_free").error == "" and DialogueRunner.open("clinic", {}, "wake_fee").error == "", "the doctor's two wake lines open")
	# The next one in the mine costs the fee.
	g.flags.erase("clinic_wake")
	g.go_to_map("mine", MapManager.data("mine").spawns.start[0], Vector2i.UP)
	g.fatigue = g.FATIGUE_MAX
	g.check_body()
	check(g.maps.id == "clinic" and g.money == 500 - int(c.fee), "a collapse in the mine: the clinic and the doctor's fee (%d G left)" % g.money)
	check(said[-1] == String(c.message) % int(c.fee), "collapse message: %s" % said[-1])
	check(g.flags.get("clinic_visits") == 2 and EventRunner.is_set(g.flags, "clinic_wake") and not EventRunner.is_set(g.flags, "clinic_free"), "a paid visit")
	g.money = 7
	g.fatigue = g.FATIGUE_MAX
	g.check_body()
	check(g.money == 0, "collapse fee never goes below 0 G")
	# The minute tick collapses the farmer too.
	g.hour = 9
	g.minute = 0
	g.fatigue = g.FATIGUE_MAX
	var day_before: int = g.day
	g._tick_minute()
	check(g.day == day_before + 1 and g.hour == int(c.wake), "the clock collapses a farmer at full fatigue")

	# Still up at 2:00: pass out, wake late at home, fatigue up.
	var p: Dictionary = body.pass_out
	g.fatigue = 20
	g.hour = 1
	g.minute = 59
	day_before = g.day
	g._tick_minute()
	check(g.day == day_before + 1 and g.hour == int(p.wake), "pass out: wake at %d:00" % g.hour)
	check(g.fatigue == 20 + int(p.fatigue_change) and g.stamina == g.max_stamina * int(p.stamina_pct) / 100, "pass out: fatigue and stamina")
	check(g.maps.id == MapManager.HOME and g.money == 0, "pass out: at home, no fee")

	# Every number in the rules is in the data file.
	for key in ["work", "awake_late", "sleep", "oversleep", "states", "pass_out", "collapse"]:
		check(body.has(key), "body.json has %s" % key)

	g.free()
	SaveGame.restore(keep_save)
	print("test_body: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func _game() -> Node:
	var g: Node = (load("res://scripts/autoload/game.gd") as GDScript).new()
	g.crops = _json("res://data/crops.json")
	g.tools_data = _json("res://data/tools.json")
	g.snow_rules = _json("res://data/snow_cover.json")
	g.body = _json("res://data/body.json")
	g.rng.seed = 3
	g.new_game()
	return g


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
