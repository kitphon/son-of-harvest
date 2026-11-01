extends SceneTree
## Headless checks for the sounds and music: data, synthesis, keys used in code, the ambient
## and music pickers and the Sfx autoload. Nothing is heard here (dummy audio driver). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_audio.gd

var failures := 0
var frames := 0
var _stopped_at := 0
var data: Dictionary
var music: Dictionary


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

	_whistles()

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

	# Water: the river on its own map, the pond lapping close to the farm (and village) ponds.
	var on := func(look: String, place: String, map_id: String, water: float) -> Dictionary:
		return AmbientPicker.pick(rules, look, "spring", 12, place, map_id, water)
	check(on.call("sunny", "outdoor", "river", 3.0).keys() == ["amb_river"], "river: running water")
	check(on.call("snow", "outdoor", "river", 3.0).has("amb_river"), "the river runs in winter snow")
	var river_rain: Dictionary = on.call("rain", "outdoor", "river", 3.0)
	check(river_rain.has("amb_rain") and river_rain.get("amb_river", 0.0) > 0.0
			and river_rain.amb_river < on.call("sunny", "outdoor", "river", 3.0).amb_river, "river in rain: rain over a softer river")
	var river_storm: Dictionary = on.call("storm", "outdoor", "river", 3.0)
	check(not river_storm.has("amb_river") and river_storm.has("amb_rain") and river_storm.has("amb_wind"),
			"river in a storm: the storm covers it (%s)" % river_storm)
	check(not on.call("blizzard", "outdoor", "river", 3.0).has("amb_river"), "river in a blizzard: covered")
	check(not on.call("sunny", "indoor", "river", 3.0).has("amb_river"), "no river indoors")
	check(not on.call("sunny", "outdoor", "town", 3.0).has("amb_river"), "no river in the village")
	check(not on.call("sunny", "outdoor", "farm", 3.0).has("amb_river"), "no river on the farm")
	check(not at.call("sunny", "spring", 12).has("amb_river"), "no map id: no river")
	var by_pond: float = on.call("sunny", "outdoor", "farm", 0.5).get("amb_pond", 0.0)
	var off_pond: float = on.call("sunny", "outdoor", "farm", 4.0).get("amb_pond", 0.0)
	check(by_pond > 0.0 and by_pond < on.call("sunny", "outdoor", "river", 3.0).amb_river, "by the pond: a quieter lapping (%s)" % by_pond)
	check(off_pond > 0.0 and off_pond < by_pond, "fainter further off (%s)" % off_pond)
	check(not on.call("sunny", "outdoor", "farm", 8.0).has("amb_pond"), "far from the pond: none")
	check(not on.call("sunny", "outdoor", "farm", -1.0).has("amb_pond"), "no water on the map: no pond")
	check(on.call("sunny", "outdoor", "town", 0.5).has("amb_pond"), "the village pond laps too")
	check(not on.call("storm", "outdoor", "farm", 0.5).has("amb_pond"), "no pond in a storm")
	check(not on.call("sunny", "indoor", "farm", 0.5).has("amb_pond"), "no pond indoors")
	check(AmbientPicker.near_level(1.0, 6.0) == 1.0 and AmbientPicker.near_level(6.0, 6.0) == 0.0
			and AmbientPicker.near_level(-1.0, 6.0) == 0.0, "near: full up to a cell, none at the radius or without water")

	_music()

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
		check(sfx.music_targets() == {"rain": 0.6}, "Sfx picks the soft rain music in a storm (%s)" % sfx.music_targets())
		var g: Node = root.get_node("Game")
		g.maps.id = "store"
	if frames == 4:
		var sfx: Node = root.get_node("Sfx")
		check(sfx.music_targets() == {"store": 1.0}, "Sfx picks the store music inside the store (%s)" % sfx.music_targets())
		var g: Node = root.get_node("Game")
		g.maps.id = "farm"
		g.event_running = true
		check(sfx.event_playing() == "", "no event player in the view: no event id")
		g.event_running = false
		g.clock_running = false
	if frames == 5:
		check(root.get_node("Sfx").music_targets() == {"title": 1.0}, "title music while the clock stands")
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
	var from_settings: Dictionary = root.get_node("Game").settings.bus_volumes()
	check(from_settings.has_all(["Music", "SFX", "Ambient"]), "every bus has a volume setting (%s)" % from_settings)
	for bus in data.buses:
		check(AudioServer.get_bus_index(bus) >= 0, "bus %s exists" % bus)
		var start := float(from_settings.get(bus, data.buses[bus]))
		check(is_equal_approx(sfx.get_volume(bus), start), "bus %s at its volume from the settings" % bus)
	sfx.set_volume("SFX", 0.5)
	check(is_equal_approx(sfx.get_volume("SFX"), 0.5), "set SFX volume")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")) - linear_to_db(0.5)) < 0.01, "SFX bus dB follows")
	sfx.set_volume("Ambient", 3.0)
	check(sfx.get_volume("Ambient") == 1.0, "volume clamped to 1")
	sfx.set_volume("Ambient", 0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambient")), "volume 0 mutes")
	sfx.set_volume("Ambient", 0.6)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambient")), "unmuted again")
	var g0: Node = root.get_node("Game")
	g0.maps.place("farm", Vector2i(24, 3), Vector2i.LEFT)   # beside the pond (x 25..28, y 2..4)
	check(sfx.water_distance() < 1.0, "Sfx: the farmer beside the pond (%s cells)" % sfx.water_distance())
	g0.maps.place("farm", Vector2i(4, 4), Vector2i.DOWN)
	check(sfx.water_distance() > 15.0, "Sfx: far from the pond at the house (%s cells)" % sfx.water_distance())
	g0.maps.place("river", Vector2i(5, 5), Vector2i.DOWN)
	check(sfx.water_distance() < 1.0, "Sfx: the river's water by the shore (%s cells)" % sfx.water_distance())
	g0.maps.place("store", Vector2i(2, 2), Vector2i.DOWN)
	check(sfx.water_distance() < 0.0, "Sfx: no water in the store")
	g0.maps.place("farm", Vector2i(4, 4), Vector2i.DOWN)
	for key in sfx.sounds:
		if not sfx.sounds[key].has("loop"):
			sfx.play(key)   # must not error without an audio device
	var tune: AudioStreamWAV = sfx.make_song("whistle:tome")
	check(tune != null and tune.loop_mode == AudioStreamWAV.LOOP_DISABLED and tune.get_length() > 1.0, "Sfx makes Tome's whistle, played once")
	sfx._song_streams["whistle:tome"] = tune
	sfx.whistle("tome", 0.5)   # must not error without an audio device
	var voice: AudioStreamPlayer = sfx._voices[(sfx._next_voice + sfx.VOICES - 1) % sfx.VOICES]
	check(voice.stream == tune and absf(voice.volume_db - (float(Whistles.data().volume_db) + linear_to_db(0.5))) < 0.01,
		"the whistle plays at its level by distance (%.1f dB)" % voice.volume_db)
	var before: int = sfx._next_voice
	sfx.whistle("tome", 0.0)
	check(sfx._next_voice == before, "out of hearing: no voice used")
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


## Whistling (data/whistles.json): every villager's tune renders a short sound that isn't
## silent, has its tune's length, starts and ends quiet, sits in a whistle's range and differs
## from the others; the rules a whistle needs are there. (Who whistles when: test_villagers.)
func _whistles() -> void:
	var w: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/whistles.json"))
	check(w.has_all(["rules", "tunes", "instrument", "volume_db"]) and float(w.volume_db) <= 0.0, "whistle data loads")
	check(w.instrument.kind == "flute", "the whistle is a flute voice")
	var r: Dictionary = w.rules
	check(r.has_all(["poses", "looks", "hours", "places", "chance", "gap_minutes", "hear_full", "hear_reach"]), "whistle rules complete")
	check(not "rain" in r.looks and not "snow" in r.looks and not "indoor" in r.places and float(r.chance) > 0.0
		and float(r.chance) < 0.5 and float(r.hear_reach) > float(r.hear_full), "whistle rules: dry, outdoors, now and then, fading out")
	var seen := {}
	for id in w.tunes:
		var track := Whistles.track(id)
		var wav := Whistles.render(id)
		var secs := wav.size() / float(SfxSynth.RATE)
		check(absf(SfxSynth.peak(wav) - SfxSynth.PEAK) < 0.001, "%s's whistle normalized" % id)
		check(absf(secs - MusicSynth.loop_seconds(track)) < 0.01 and secs > 1.0 and secs < 4.0, "%s's whistle lasts %.2f s" % [id, secs])
		check(absf(wav[0]) < 0.01 and absf(wav[wav.size() - 1]) < 0.01, "%s's whistle starts and ends quiet" % id)
		var tail := 0.0   # the last 30 ms: the last note has died away (the tune ends on rests)
		for i in range(wav.size() - int(0.03 * SfxSynth.RATE), wav.size()):
			tail = maxf(tail, absf(wav[i]))
		check(tail < 0.02, "%s's whistle is not cut off (%.3f at the end)" % [id, tail])
		var notes := MusicSynth.notes(track, track.voices[0])
		check(notes.size() >= 4 and notes.size() <= 10, "%s's whistle is a short motif (%d notes)" % [id, notes.size()])
		for n in notes:
			var f := MusicSynth.freq(n.midi)
			check(f > 500.0 and f < 2500.0, "%s's whistle note at %d Hz, in a whistle's range" % [id, f])
		var shape := str(notes.map(func(n): return n.midi - notes[0].midi)) + str(track.bpm)
		check(not seen.has(shape), "%s's tune is its own (not %s's)" % [id, seen.get(shape, "")])
		seen[shape] = id
	check(Whistles.render("kota") == Whistles.render("kota"), "a whistle renders the same each time")


## Music: the scores are well formed, every track renders a loop that isn't silent, and
## the picker gives the right track per scene, weather, season and hour.
func _music() -> void:
	music = JSON.parse_string(FileAccess.get_file_as_string("res://data/music.json"))
	check(music.has("tracks") and music.has("instruments") and music.has("rules"), "music data loads")
	var tracks: Dictionary = music.tracks
	for key in MusicPicker.tracks(music.rules):
		check(tracks.has(key), "track %s (in the rules) has a score" % key)
	for key in tracks:
		check(key in MusicPicker.tracks(music.rules), "track %s is picked by some rule" % key)
		var t: Dictionary = tracks[key]
		var scale: Array = t.scale
		check(scale.size() == 5 and int(scale[0]) == 0, "%s: a five-note scale from the root" % key)
		for i in range(1, scale.size()):
			check(int(scale[i]) > int(scale[i - 1]) and int(scale[i]) < 12, "%s: scale rises within an octave" % key)
		check(float(t.get("volume_db", 0)) <= 0.0, "%s not louder than full scale" % key)
		check(MusicSynth.loop_seconds(t) > MusicSynth.TAIL, "%s loop longer than the ring-out" % key)
		var low := 128
		var high := 0
		for v in t.voices:
			check(music.instruments.has(v.instrument), "%s: instrument %s exists" % [key, v.instrument])
			for b in v.bars:
				var tokens := String(b).split(" ", false)
				check(tokens.size() == int(t.steps_per_bar), "%s: bar '%s' has %d steps" % [key, b, t.steps_per_bar])
				for tok in tokens:
					for d in tok.split("+"):
						check(d == "_" or d == "." or d.is_valid_int(), "%s: token '%s'" % [key, tok])
			var ns := MusicSynth.notes(t, v)
			check(not ns.is_empty(), "%s: a %s voice plays notes" % [key, v.instrument])
			for n in ns:
				low = mini(low, n.midi)
				high = maxi(high, n.midi)
		check(low >= 36 and high <= 96, "%s: notes in a sane range (%d..%d)" % [key, low, high])

	# The score reader: holds lengthen a note, "+" makes a chord, rests end the note, and a
	# voice with fewer bars repeats them.
	var t := {"bpm": 120, "steps_per_bar": 4, "bars": 2, "root": 60, "scale": [0, 2, 5, 7, 9]}
	var ns := MusicSynth.notes(t, {"bars": ["0 _ . 5", "-1+2 _ _ _"]})
	check(ns.size() == 4, "four notes (%d)" % ns.size())
	if ns.size() == 4:
		check(ns[0].step == 0 and ns[0].steps == 2 and ns[0].midi == 60, "held root")
		check(ns[1].step == 3 and ns[1].steps == 1 and ns[1].midi == 72, "degree 5 is the octave")
		check(ns[2].midi == 57 and ns[3].midi == 65 and ns[2].steps == 4 and ns[3].steps == 4, "chord below and above, held")
	check(MusicSynth.notes(t, {"bars": ["0 . . ."]}).size() == 2, "one bar repeats")
	check(MusicSynth.notes(t, {"octave": -1, "bars": ["0 . . ."]})[0].midi == 48, "octave down")
	check(is_equal_approx(MusicSynth.freq(69), 440.0) and is_equal_approx(MusicSynth.freq(81), 880.0), "note to Hz")

	# Every track's first bars make sound; one track as a whole loop.
	var started := Time.get_ticks_msec()
	for key in tracks:
		var wav := MusicSynth.render(tracks[key], music.instruments, hash(key), 2)
		check(wav.size() == int(2 * MusicSynth.bar_seconds(tracks[key]) * SfxSynth.RATE), "%s: two bars long" % key)
		check(absf(SfxSynth.peak(wav) - SfxSynth.PEAK) < 0.001 and not is_nan(wav[wav.size() / 2]), "%s normalized" % key)
		var quiet := 0   # quarter seconds without sound in a row
		var longest := 0
		var q := SfxSynth.RATE / 4
		for i in range(0, wav.size() - q, q):
			var e := 0.0
			for j in range(i, i + q, 7):
				e = maxf(e, absf(wav[j]))
			quiet = quiet + 1 if e < 0.01 else 0
			longest = maxi(longest, quiet)
		check(longest < 4, "%s: no silent second (%d quiet quarters)" % [key, longest])
	var title := MusicSynth.render(tracks.title, music.instruments, hash("title"))
	check(title.size() == int(MusicSynth.loop_seconds(tracks.title) * SfxSynth.RATE), "title: exact loop length")
	var jump := 0.0
	for i in range(1, title.size()):
		jump = maxf(jump, absf(title[i] - title[i - 1]))
	check(absf(title[0] - title[title.size() - 1]) <= jump, "title loops without a seam")
	check(title == MusicSynth.render(tracks.title, music.instruments, hash("title")), "same seed, same music")
	var stream := SfxSynth.to_stream(title, true)
	check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end == title.size(), "music stream loops")
	print("test_audio: made the music in %d ms" % (Time.get_ticks_msec() - started))

	# The picker: title screen, weather, night, then the season.
	var at := func(scene: String, look: String, season_id: String, hour: int) -> Dictionary:
		return MusicPicker.pick(music.rules, scene, look, season_id, hour)
	check(at.call("title", "storm", "winter", 23) == {"title": 1.0}, "title screen: title theme")
	check(at.call("field", "sunny", "spring", 10) == {"spring": 1.0}, "spring day")
	check(at.call("field", "sunny", "summer", 10) == {"summer": 1.0}, "summer day")
	check(at.call("field", "sunny", "fall", 18) == {"fall": 1.0}, "fall evening, before night")
	check(at.call("field", "snow", "winter", 6) == {"winter": 1.0}, "winter morning in snow")
	check(at.call("field", "blizzard", "winter", 12) == {"winter": 1.0}, "blizzard: winter music")
	check(at.call("field", "sunny", "summer", 19) == {"night": 1.0}, "night from 19:00")
	check(at.call("field", "sunny", "winter", 2) == {"night": 1.0}, "night after midnight")
	check(at.call("field", "rain", "spring", 10) == {"rain": 1.0}, "rain music")
	check(at.call("field", "rain", "fall", 22) == {"rain": 1.0}, "rain wins over night")
	check(at.call("field", "storm", "summer", 12) == {"rain": 0.6}, "storm: softer rain music")
	# Festivals: their own score while one is on around the farmer, over night and season.
	var fest := func(festival: String, season_id: String, hour: int) -> Dictionary:
		return MusicPicker.pick(music.rules, "field", "sunny", season_id, hour, festival)
	check(fest.call("blossom_day", "spring", 11) == {"fest_blossom": 1.0}, "Blossom Day has its own music")
	check(fest.call("lantern_night", "summer", 20) == {"fest_lanterns": 1.0}, "Lantern Night's music wins over night")
	check(fest.call("moon_night", "fall", 21) == {"fest_moon": 1.0} and fest.call("years_turn", "winter", 23) == {"fest_year": 1.0},
		"Moon Night and Year's Turn")
	check(fest.call("", "spring", 11) == {"spring": 1.0}, "no festival on: the season's music")
	check(MusicPicker.pick(music.rules, "title", "sunny", "spring", 11, "blossom_day") == {"title": 1.0}, "the title screen keeps its theme")
	for id in Festivals.all():
		check(MusicPicker.tracks(music.rules).any(func(t): return fest.call(id, Festivals.get_festival(id).season, 12).has(t) and t.begins_with("fest_")),
			"%s has a festival score" % id)
	# Shops: inside the store and the smithy their own music, over weather, night and season;
	# every other map keeps the old picks (the rules without maps / events give the same).
	var shop := func(map_id: String, look: String, hour: int) -> Dictionary:
		return MusicPicker.pick(music.rules, "field", look, "summer", hour, "", map_id)
	check(shop.call("store", "sunny", 10) == {"store": 1.0}, "the Yorozu Store has its own music")
	check(shop.call("store", "storm", 20) == {"store": 1.0}, "store music over storm and night")
	check(shop.call("smithy", "rain", 9) == {"smithy": 1.0}, "the Kurogane Smithy has its own music")
	check(shop.call("town", "sunny", 10) == {"summer": 1.0} and shop.call("house", "rain", 10) == {"rain": 1.0},
		"other maps: the old picks")
	check(MusicPicker.pick(music.rules, "title", "sunny", "spring", 10, "", "store") == {"title": 1.0}, "title screen over the map")
	# Events: the heart events play the gentle score, the opening of a new game the bright one.
	var ev := func(event_id: String, map_id: String, festival := "") -> Dictionary:
		return MusicPicker.pick(music.rules, "field", "rain", "spring", 21, festival, map_id, event_id)
	for f in DirAccess.get_files_at("res://data/events"):
		if f.begins_with("heart_"):
			check(ev.call(f.get_basename(), "town") == {"heart": 1.0}, "%s plays the heart music" % f.get_basename())
	check(ev.call("heart_sayo_5", "store") == {"heart": 1.0}, "a heart event at the store counter: heart music")
	check(ev.call("heart_tome", "town", "blossom_day") == {"heart": 1.0}, "a heart event on a festival: heart music")
	check(ev.call("opening", "farm") == {"morning": 1.0} and ev.call("first_morning", "farm") == {"morning": 1.0},
		"the opening events play the morning music")
	check(ev.call("store_intro", "store") == {"store": 1.0} and ev.call("smithy_intro", "smithy") == {"smithy": 1.0},
		"a shop's first visit keeps the shop music")
	check(ev.call("pond_first", "farm") == {"rain": 1.0}, "other events keep the music around them")
	check(ev.call("festival_blossom", "town", "blossom_day") == {"fest_blossom": 1.0}, "festival events keep the festival music")
	for id in ["heart", "morning"]:
		var r: Dictionary = music.rules.filter(func(x): return x.track == id)[0]
		for e in r.events:
			check(FileAccess.file_exists("res://data/events/%s.json" % e), "music rule event %s exists" % e)
	for r in music.rules:
		for m in r.get("maps", []):
			check(FileAccess.file_exists("res://data/maps/%s.json" % m), "music rule map %s exists" % m)
	var old_rules: Array = music.rules.filter(func(x): return not x.has("maps") and not x.has("events"))
	var same := true
	for scene in ["title", "field"]:
		for look in ["sunny", "rain", "storm", "snow", "blizzard"]:
			for season_id in ["spring", "summer", "fall", "winter"]:
				for hour in [2, 6, 10, 18, 19, 23]:
					for festival in ["", "blossom_day", "lantern_night", "moon_night", "years_turn"]:
						var was := MusicPicker.pick(old_rules, scene, look, season_id, hour, festival)
						for map_id in ["", "farm", "town", "house", "mine_floor"]:
							for event_id in ["", "pond_first", "festival_blossom"]:
								same = same and MusicPicker.pick(music.rules, scene, look, season_id, hour, festival, map_id, event_id) == was
	check(same, "off the shop maps and outside those events every pick is as before")
	check(MusicPicker.pick([], "field", "sunny", "spring", 10).is_empty(), "no rules: silence")
	check(MusicPicker.pick([{"track": ""}], "field", "sunny", "spring", 10).is_empty(), "an empty track is silence")


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
