extends SceneTree
## Headless checks for the sounds: data, synthesis, keys used in code, the ambient picker and
## the Sfx autoload. Nothing is heard here (dummy audio driver). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_audio.gd

var failures := 0
var frames := 0
var _stopped_at := 0
var data: Dictionary


func _init() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json"))
	check(data.has("sounds") and data.has("ambient") and data.has("buses"), "sfx data loads")
	var sounds: Dictionary = data.sounds
	var rules: Array = data.ambient.rules

	# Every recipe makes a sound: not silent, normalized, no NaN, a sane length; loops have
	# their exact length and no seam (end runs into start).
	var started := Time.get_ticks_msec()
	for key in sounds:
		var s: Dictionary = sounds[key]
		var wav := SfxSynth.render(s, hash(key))
		var p := SfxSynth.peak(wav)
		check(absf(p - SfxSynth.PEAK) < 0.001, "%s normalized (peak %.3f)" % [key, p])
		check(not is_nan(wav[wav.size() / 2]), "%s has numbers" % key)
		var secs := wav.size() / float(SfxSynth.RATE)
		if s.has("loop"):
			check(wav.size() == int(float(s.loop) * SfxSynth.RATE), "%s loop length" % key)
			check(s.get("bus", "") == "Ambient", "%s on the Ambient bus" % key)
			var jump := 0.0   # the biggest step between neighbouring samples inside the loop
			for i in range(1, wav.size()):
				jump = maxf(jump, absf(wav[i] - wav[i - 1]))
			check(absf(wav[0] - wav[wav.size() - 1]) <= jump, "%s loops without a seam" % key)
		else:
			check(secs > 0.04 and secs < 6.0, "%s length %.2f s" % [key, secs])
			check(absf(wav[0]) < 0.01 and absf(wav[wav.size() - 1]) < 0.01, "%s starts and ends quiet" % key)
			var pitch: Array = s.get("pitch", [1, 1])
			check(pitch[0] > 0 and pitch[0] <= pitch[1], "%s pitch range" % key)
		check(float(s.get("volume_db", 0)) <= 0.0, "%s not louder than full scale" % key)
		var stream := SfxSynth.to_stream(wav, s.has("loop"))
		check(stream.data.size() == wav.size() * 2, "%s as 16-bit" % key)
		check((stream.loop_mode == AudioStreamWAV.LOOP_FORWARD) == s.has("loop"), "%s loop mode" % key)
	print("test_audio: made %d sounds in %d ms" % [sounds.size(), Time.get_ticks_msec() - started])
	check(SfxSynth.render(sounds.tool_hoe, 7) == SfxSynth.render(sounds.tool_hoe, 7), "same seed, same sound")

	# Every key the code plays is in the data (literal keys, tools, footsteps, loops).
	var used := {}
	var call := RegEx.create_from_string("\\bplay(?:\\.bind)?\\(\"([a-z_]+)\"\\)")
	for path in _scripts("res://scripts"):
		for m in call.search_all(FileAccess.get_file_as_string(path)):
			used[m.get_string(1)] = path
	check(used.size() >= 9, "found the play calls in code (%d)" % used.size())
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	for t in game_script.TOOLS:
		if t != "food":   # eating plays the food's own eat / drink sound (tests/test_food.gd)
			used["tool_" + t] = "farm_actions.gd"
	for g in ["grass", "soil", "snow"]:
		used["step_" + g] = "sfx.gd walk"
	used["thunder"] = "sfx.gd thunder_after_flash"
	for key in AmbientPicker.loops(rules):
		used[key] = "ambient rules"
		check(sounds.has(key) and sounds[key].has("loop"), "ambient loop %s is a loop" % key)
	for key in used:
		check(sounds.has(key), "sound '%s' (used in %s) is in data/sfx.json" % [key, used[key]])
	for key in ["menu_move", "menu_ok", "bin_lid", "pond_fill", "pick", "chime_morning", "coins"]:
		check(used.has(key), "%s is played somewhere" % key)

	# The ambient picker: weather look / season / hour -> loops.
	var at := func(look: String, season_id: String, hour: int) -> Dictionary:
		return AmbientPicker.pick(rules, look, season_id, hour)
	var storm: Dictionary = at.call("storm", "summer", 12)
	check(storm.get("amb_rain", 0.0) == 1.0 and storm.get("amb_wind", 0.0) == 1.0, "storm: rain and wind")
	check(not storm.has("amb_cicadas"), "no cicadas in a storm")
	var rain: Dictionary = at.call("rain", "spring", 9)
	check(rain.get("amb_rain", 0.0) > 0.0 and rain.get("amb_rain", 0.0) < 1.0 and not rain.has("amb_wind"), "rain: softer rain, no wind")
	check(at.call("sunny", "summer", 12).keys() == ["amb_cicadas"], "summer noon: cicadas only")
	check(not at.call("rain", "summer", 12).has("amb_cicadas"), "summer rain: no cicadas")
	check(at.call("sunny", "summer", 22).keys() == ["amb_crickets"], "summer night: crickets only")
	check(at.call("sunny", "fall", 2).has("amb_crickets"), "crickets after midnight")
	check(at.call("sunny", "fall", 5).is_empty(), "quiet before dawn")
	check(at.call("sunny", "fall", 12).is_empty(), "fall noon: quiet")
	check(at.call("sunny", "winter", 22).is_empty(), "winter night: quiet")
	check(at.call("sunny", "spring", 22).get("amb_crickets", 0.0) < 1.0, "a few crickets in spring")
	check(at.call("blizzard", "winter", 12).get("amb_wind", 0.0) == 1.0, "blizzard: wind")
	check(at.call("snow", "winter", 12).get("amb_wind", 0.0) < 1.0, "snow: a soft wind")
	check(AmbientPicker.in_hours(3, 19, 4) and not AmbientPicker.in_hours(4, 19, 4), "hours wrap past midnight")
	check(AmbientPicker.in_hours(7, 7, 18) and not AmbientPicker.in_hours(18, 7, 18), "hours from .. to (not incl.)")

	# Lightning tells the view once per flash that it started (thunder follows).
	var l := Lightning.new()
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weather_fx.json"))
	l.reset(fx.storm.lightning)
	var starts := 0
	var bright_starts := 0
	for i in 1200:   # 60 s; flashes come 6..16 s apart
		var b := l.step(0.05)
		if l.started:
			starts += 1
			bright_starts += 1 if b > 0.0 else 0
	check(starts >= 3 and starts <= 10, "a start per flash (%d in 60 s)" % starts)
	check(bright_starts == starts, "the start is the bright moment")
	l.reset({})
	l.step(0.05)
	check(not l.started, "no style, no start")


## Runtime checks on the Sfx autoload, which is in the tree from the first frame.
func _process(_delta: float) -> bool:
	frames += 1
	if frames == 1:
		_autoload_checks()
		return false
	if frames == 3:
		var sfx: Node = root.get_node("Sfx")
		var t: Dictionary = sfx.ambient_targets()
		check(t.has("amb_rain") and t.has("amb_wind"), "Sfx picks storm loops in a storm (%s)" % t)
		check(sfx._loops.amb_rain.playing, "rain loop started")
		var g: Node = root.get_node("Game")
		g.clock_running = false
	if frames == 5:
		check(root.get_node("Sfx").ambient_targets().is_empty(), "no ambient while the clock stands")
		root.get_node("Sfx").stop_all()
		_stopped_at = Time.get_ticks_msec()
	if frames > 5 and Time.get_ticks_msec() - _stopped_at > 300:   # the mixer lets go of them
		print("test_audio: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


func _autoload_checks() -> void:
	var sfx: Node = root.get_node_or_null("Sfx")
	check(sfx != null, "Sfx autoload in the tree")
	if sfx == null:
		return
	check(sfx.silent, "headless: players stay silent")
	sfx.silent = false   # play for real on the dummy driver here; stopped before quitting
	for bus in data.buses:
		check(AudioServer.get_bus_index(bus) >= 0, "bus %s exists" % bus)
		check(is_equal_approx(sfx.get_volume(bus), float(data.buses[bus])), "bus %s at its start volume" % bus)
	sfx.set_volume("SFX", 0.5)
	check(is_equal_approx(sfx.get_volume("SFX"), 0.5), "set SFX volume")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")) - linear_to_db(0.5)) < 0.01, "SFX bus dB follows")
	sfx.set_volume("Ambient", 3.0)
	check(sfx.get_volume("Ambient") == 1.0, "volume clamped to 1")
	sfx.set_volume("Ambient", 0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambient")), "volume 0 mutes")
	sfx.set_volume("Ambient", 0.6)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambient")), "unmuted again")
	for key in sfx.sounds:
		if not sfx.sounds[key].has("loop"):
			sfx.play(key)   # must not error without an audio device
	var g: Node = root.get_node("Game")
	var farm: FarmGrid = g.farm
	var c := Vector2i(12, 10)
	farm.cell(c).tilled = false
	check(sfx.ground(farm, c, 0) == "grass", "footsteps on grass")
	check(sfx.ground(farm, c, 80) == "snow", "footsteps in snow")
	farm.cell(c).tilled = true
	check(sfx.ground(farm, c, 80) == "soil", "footsteps on tilled soil")
	check(sfx.ground(farm, Vector2i(-1, -1), 0) == "grass", "footsteps off the grid")
	for i in 10:
		sfx.walk(5.0, farm, c)
	g.weather_today = "storm"
	g.season = 1
	g.hour = 12
	g.clock_running = true


func _scripts(dir: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir + "/" + d))
	return out


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
