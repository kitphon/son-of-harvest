extends Node
## Sound effects, ambient loops and music. Plays sounds by key from data/sfx.json (made by
## SfxSynth on first use) and music tracks from data/music.json (made by MusicSynth on a
## worker thread when first wanted), on three busses, SFX, Ambient and Music, each with a
## volume 0..1 set from the settings (Game.settings, the entries with a "bus"). The ambient
## loops follow the weather, season, hour, map and nearness to water (AmbientPicker) and fade out while the clock
## stands (title screen, menus); the music follows the scene, weather, season and hour
## (MusicPicker) and cross-fades from track to track. Headless runs (tests, smoke runs) have no
## audio device, and Movie Maker screenshots drive the mixer frame by frame: in both every
## step runs except starting the players (`silent`), since a sound still playing when the
## engine quits there is reported as a leak. `-- --movie-audio` keeps sound in a movie run
## (it is written next to the frames as frame.wav). Villagers walking in view whistle now and
## then (Whistles, data/whistles.json), softer the farther off they are.

const DATA := "res://data/sfx.json"
const MUSIC := "res://data/music.json"
const VOICES := 8          # one-shots that can sound at once
const STRIDE_PX := 14.0    # farmer pixels walked per footstep
const SNOW_STEPS := 50     # snow cover from which footsteps crunch

var sounds: Dictionary = {}
var ambient_rules: Array = []
var volumes: Dictionary = {}       # bus -> 0..1
var music: Dictionary = {}         # data/music.json
var rng := RandomNumberGenerator.new()
var silent := DisplayServer.get_name() == "headless" 		or (Engine.get_write_movie_path() != "" and not "--movie-audio" in OS.get_cmdline_user_args())
var _streams: Dictionary = {}      # key -> AudioStreamWAV, made on first use (loops: ahead, see loop_stream)
var _loop_jobs: Dictionary = {}    # loop key -> [WorkerThreadPool task, {stream}] being made
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _loops: Dictionary = {}        # loop key -> AudioStreamPlayer
var _target: Dictionary = {}       # loop key -> level 0..1 it fades to
var _fade_seconds := 4.0
var _songs: Dictionary = {}        # track key -> AudioStreamPlayer
var _song_target: Dictionary = {}  # track key -> level 0..1 it fades to
var _song_level: Dictionary = {}   # track key -> level now
var _song_fade: Dictionary = {}    # track key -> s its fade-in takes
var _song_streams: Dictionary = {} # track key -> AudioStreamWAV, once made
var _song_jobs: Dictionary = {}    # track key -> [WorkerThreadPool task, {stream}] being made
var _walked := 0.0
var last := ""                   # the key played last (tests check when a sound plays)
var _water_map := ""               # the map _water_cells are for
var _water_cells: Array[Vector2i] = []
var _last_bin := 0
var _last_money := 0


func _ready() -> void:
	rng.randomize()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	sounds = data.sounds
	ambient_rules = data.ambient.rules
	_fade_seconds = float(data.ambient.get("fade_seconds", 4.0))
	for bus in data.buses:
		_make_bus(bus)
		set_volume(bus, float(data.buses[bus]))
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)
	for key in AmbientPicker.loops(ambient_rules) + CicadaRules.loops():   # the cicadas' loops come from data/cicadas.json
		var p := AudioStreamPlayer.new()
		p.bus = "Ambient"
		p.volume_linear = 0.0
		add_child(p)
		_loops[key] = p
	music = JSON.parse_string(FileAccess.get_file_as_string(MUSIC))
	for key in MusicPicker.tracks(music.rules):
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_linear = 0.0
		add_child(p)
		_songs[key] = p
		_song_level[key] = 0.0
	if not silent:   # the ambient loops and the tunes are made early, off the main thread
		for key in _loops:
			loop_stream(key)
		for id in Whistles.data().tunes:
			song_stream("whistle:" + id)
	apply_settings()
	Game.settings_changed.connect(apply_settings)
	Game.day_started.connect(play.bind("chime_morning"))
	Game.changed.connect(_watch_payday)
	_last_bin = Game.bin_total
	_last_money = Game.money


func _process(delta: float) -> void:
	var m := Game.maps.current()
	_target = AmbientPicker.pick(ambient_rules, Game.weather_look(Game.weather_today, Game.season_name()),
			Game.season_name(), Game.hour, m.ambient if m != null else "outdoor", Game.maps.id,
			water_distance()) if Game.clock_running else {}
	var cicadas := CicadaRules.sound_now(Game, m)   # the summer chorus and the evening cicada
	for key in cicadas:
		_target[key] = maxf(float(_target.get(key, 0.0)), float(cicadas[key]))
	var step := delta / maxf(_fade_seconds, 0.01)
	for key in _loops:
		var p: AudioStreamPlayer = _loops[key]
		var to := float(_target.get(key, 0.0))
		if to > 0.0 and not p.playing and not silent:
			var ls := loop_stream(key)   # null while still being made: it starts a little later
			if ls != null:
				p.stream = ls
				p.play()
		var base := db_to_linear(float(sounds[key].get("volume_db", 0.0)))
		var level := move_toward(p.volume_linear / base, to, step) if p.playing else 0.0
		p.volume_linear = level * base
		if p.playing and level <= 0.0 and to <= 0.0:
			p.stop()
	_music_step(delta)
	_whistle_step()


## Cross-fades the music to the track MusicPicker wants. A track starts once its loop is made;
## from silence it fades in quickly (start_fade), over another track slowly (fade_seconds).
func _music_step(delta: float) -> void:
	var look := Game.weather_look(Game.weather_today, Game.season_name())
	_song_target = MusicPicker.pick(music.rules, "field" if Game.clock_running else "title",
			look, Game.season_name(), Game.hour, Game.festival_now(), Game.maps.id, event_playing())
	var fade := float(music.get("fade_seconds", 3.0))
	for key in _songs:
		var p: AudioStreamPlayer = _songs[key]
		var to := float(_song_target.get(key, 0.0))
		if to > 0.0 and not p.playing and not silent:
			var s := song_stream(key)
			if s != null:
				_song_fade[key] = fade if _songs.values().any(func(o): return o.playing) 						else float(music.get("start_fade", 1.0))
				p.stream = s
				p.play()
		var secs := float(_song_fade.get(key, fade)) if to > float(_song_level[key]) else fade
		_song_level[key] = move_toward(_song_level[key], to, delta / maxf(secs, 0.01)) if p.playing else 0.0
		p.volume_linear = _song_level[key] * db_to_linear(float(music.tracks[key].get("volume_db", 0.0)))
		if p.playing and _song_level[key] <= 0.0 and to <= 0.0:
			p.stop()


## Starts the tunes of villagers who whistle now on the farmer's map (Whistles.step).
func _whistle_step() -> void:
	if not Game.clock_running:
		return
	var m := Game.maps.current()
	for w in Whistles.step(Game.maps.id, Game.day_minutes(), Game.trigger_state(Vector2i.ZERO),
			Game.weather_look(Game.weather_today, Game.season_name()), Game.hour,
			m.ambient if m != null else "outdoor", Game.maps.pos / MapManager.T):
		whistle(w.id, w.level)


## Plays villager `id`'s tune at `level` (0..1, by distance) on the SFX bus. Nothing while its
## sound is still being made (the note puff shows all the same).
func whistle(id: String, level: float) -> void:
	if level <= 0.0:
		return
	var s := song_stream("whistle:" + id)
	if s == null:
		return
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	p.stream = s
	p.bus = "SFX"
	p.volume_db = float(Whistles.data().get("volume_db", -14.0)) + linear_to_db(level)
	p.pitch_scale = 1.0
	if not silent:
		p.play()


## The id of the event script playing in the view, or "" (for the music rules' `events`).
func event_playing() -> String:
	if not Game.event_running:
		return ""
	var ep := get_tree().get_first_node_in_group(EventPlayer.GROUP) as EventPlayer
	return ep.runner.id if ep != null and ep.runner != null else ""


## The loop for a track, or null while it is still being made. Made on a worker thread so
## the game doesn't stall; in a Movie Maker run (frames don't wait for threads) at once.
func song_stream(key: String) -> AudioStreamWAV:
	if _song_streams.has(key):
		return _song_streams[key]
	if Engine.get_write_movie_path() != "":
		_song_streams[key] = make_song(key)
		return _song_streams[key]
	if not _song_jobs.has(key):
		var out := {}
		var job := song_job(key)   # its inputs copied here: the thread touches nothing shared
		_song_jobs[key] = [WorkerThreadPool.add_task(func(): out.stream = job.call()), out]
		return null
	var job: Array = _song_jobs[key]
	if not WorkerThreadPool.is_task_completed(job[0]):
		return null
	WorkerThreadPool.wait_for_task_completion(job[0])
	_song_jobs.erase(key)
	_song_streams[key] = job[1].stream
	return _song_streams[key]


## A music track's loop, or (key "whistle:<id>") a villager's tune, played once.
func make_song(key: String) -> AudioStreamWAV:
	return song_job(key).call()


## The work of making a track's loop, with its inputs deep-copied now (on the main thread), so a
## worker thread running it reads no Dictionary the game also holds and no lazy static data
## (Whistles.data()): several threads reading them at once crashed the game (signal 11).
func song_job(key: String) -> Callable:
	if key.begins_with("whistle:"):
		var id := key.trim_prefix("whistle:")
		var tune := Whistles.track(id).duplicate(true)
		var inst := {"whistle": (Whistles.data().instrument as Dictionary).duplicate(true)}
		var seed := hash(id)
		return func() -> AudioStreamWAV:
			return SfxSynth.to_stream(MusicSynth.render(tune, inst, seed, 1), false)
	var track: Dictionary = (music.tracks[key] as Dictionary).duplicate(true)
	var insts: Dictionary = (music.instruments as Dictionary).duplicate(true)
	var song_seed := hash(key)
	return func() -> AudioStreamWAV:
		return SfxSynth.to_stream(MusicSynth.render(track, insts, song_seed), true)


## Music wanted right now (track key -> level), for checks.
func music_targets() -> Dictionary:
	return _song_target


## Puts the volume settings into effect (on start and whenever a setting changes).
func apply_settings() -> void:
	if Game.settings == null:
		return
	var v := Game.settings.bus_volumes()
	for bus in v:
		set_volume(bus, v[bus])


## Plays a one-shot sound by key, with a random pitch from its range.
func play(key: String) -> void:
	if not sounds.has(key):
		push_warning("Sfx: no sound '%s' in %s" % [key, DATA])
		return
	last = key
	var s: Dictionary = sounds[key]
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	p.stream = stream(key)
	p.bus = s.get("bus", "SFX")
	p.volume_db = float(s.get("volume_db", 0.0))
	var pitch: Array = s.get("pitch", [1.0, 1.0])
	p.pitch_scale = rng.randf_range(float(pitch[0]), float(pitch[1]))
	if not silent:
		p.play()


## The farmer moved `px` pixels and stands on `cell`: a footstep every stride, by ground.
## Off the farm (`farm` null) the map names the step `kind` ("" = grass or snow).
func walk(px: float, farm: FarmGrid, cell: Vector2i, kind := "") -> void:
	_walked += px
	if _walked < STRIDE_PX:
		return
	_walked = 0.0
	play("step_" + (kind if kind != "" else ground(farm, cell, Game.snow_cover)))


## Which footstep a cell gives: soil when tilled, snow when the ground is white, else grass.
static func ground(farm: FarmGrid, cell: Vector2i, snow_cover: int) -> String:
	if farm != null and farm.in_bounds(cell) and farm.cell(cell).tilled:
		return "soil"
	return "snow" if snow_cover >= SNOW_STEPS else "grass"


## A lightning flash just started: thunder rolls in a moment later.
func thunder_after_flash() -> void:
	var d: Array = sounds.thunder.get("delay", [1.0, 3.0])
	get_tree().create_timer(rng.randf_range(float(d[0]), float(d[1]))).timeout.connect(play.bind("thunder"))


## Bus volume 0..1 (0 mutes it). For the settings screen.
func set_volume(bus: String, value: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		push_warning("Sfx: no bus '%s'" % bus)
		return
	value = clampf(value, 0.0, 1.0)
	volumes[bus] = value
	AudioServer.set_bus_volume_db(i, linear_to_db(value) if value > 0.0 else -80.0)
	AudioServer.set_bus_mute(i, value <= 0.0)


func get_volume(bus: String) -> float:
	return float(volumes.get(bus, 1.0))


func stream(key: String) -> AudioStreamWAV:
	if not _streams.has(key):
		_streams[key] = make_sound(key)
	return _streams[key]


## A sound made from its recipe (the same every time: the noise is seeded by the key).
func make_sound(key: String) -> AudioStreamWAV:
	return sound_job(key).call()


## The work of making a sound, its recipe deep-copied now (see song_job).
func sound_job(key: String) -> Callable:
	var recipe: Dictionary = (sounds[key] as Dictionary).duplicate(true)
	var seed := hash(key)
	return func() -> AudioStreamWAV:
		return SfxSynth.to_stream(SfxSynth.render(recipe, seed), recipe.has("loop"))


## The ambient loop for a key, or null while it is still being made. Made on a worker thread
## (started at start-up) so the frame it first plays on doesn't stall; in a Movie Maker run
## (frames don't wait for threads) at once.
func loop_stream(key: String) -> AudioStreamWAV:
	if _streams.has(key):
		return _streams[key]
	if Engine.get_write_movie_path() != "":
		return stream(key)
	if not _loop_jobs.has(key):
		var out := {}
		var job := sound_job(key)   # its recipe copied here: the thread touches nothing shared
		_loop_jobs[key] = [WorkerThreadPool.add_task(func(): out.stream = job.call()), out]
		return null
	var job: Array = _loop_jobs[key]
	if not WorkerThreadPool.is_task_completed(job[0]):
		return null
	WorkerThreadPool.wait_for_task_completion(job[0])
	_loop_jobs.erase(key)
	if not _streams.has(key):
		_streams[key] = job[1].stream
	return _streams[key]


## Cells from the farmer's feet (Game.maps.pos) to the nearest water on this map (the farm
## pond, water tiles elsewhere), or -1 when the map has none. For the "near" ambient rules.
func water_distance() -> float:
	if _water_map != Game.maps.id:
		_water_map = Game.maps.id
		_water_cells.clear()
		var m := Game.maps.current()
		if Game.maps.on_farm():
			for c in Game.farm.fixed:
				if Game.farm.fixed[c] == "pond":
					_water_cells.append(c)
		elif m != null:
			for y in m.h:
				for x in m.w:
					if m.tile(Vector2i(x, y)) == "water":
						_water_cells.append(Vector2i(x, y))
	if _water_cells.is_empty():
		return -1.0
	var feet: Vector2 = Game.maps.pos / MapManager.T
	var best := INF
	for c in _water_cells:
		best = minf(best, feet.distance_to(feet.clamp(Vector2(c), Vector2(c) + Vector2.ONE)))   # to its nearest edge
	return best


## Ambient loops wanted right now (loop key -> level), for checks.
func ambient_targets() -> Dictionary:
	return _target


func _make_bus(bus: String) -> void:
	if AudioServer.get_bus_index(bus) >= 0:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus)
	AudioServer.set_bus_send(i, "Master")


## Payday: the bin's value went into the money (Game.pay_bin), so the coins jingle.
func _watch_payday() -> void:
	if _last_bin > 0 and Game.bin_total == 0 and Game.money == _last_money + _last_bin:
		play("coins")
	_last_bin = Game.bin_total
	_last_money = Game.money


## On the way out: stop, then give the mixer thread a moment to let go of the playbacks, or
## the engine reports them as leaked when it quits mid-sound.
func _exit_tree() -> void:
	for key in _song_jobs:
		WorkerThreadPool.wait_for_task_completion(_song_jobs[key][0])
	_song_jobs.clear()
	for key in _loop_jobs:   # loops a map never asked for are never collected: a task left
		WorkerThreadPool.wait_for_task_completion(_loop_jobs[key][0])   # un-waited crashed the quit (signal 11)
	_loop_jobs.clear()
	if stop_all():
		OS.delay_msec(60)


## Silence at once (and before the engine shuts down, so no playback holds its stream).
func stop_all() -> bool:
	var any := false
	for p: AudioStreamPlayer in _voices + _loops.values() + _songs.values():
		any = any or p.playing
		p.stop()
	return any
