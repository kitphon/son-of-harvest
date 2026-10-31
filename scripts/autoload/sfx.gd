extends Node
## Sound effects and ambient loops. Plays sounds by key from data/sfx.json (made by SfxSynth
## on first use), on two busses, SFX and Ambient, each with a volume 0..1 for the settings
## screen. The ambient loops follow the weather, season, hour and map (AmbientPicker) and fade
## out while the clock stands (title screen, menus). Headless runs (tests, smoke runs) have no
## audio device, and Movie Maker screenshots drive the mixer frame by frame: in both every
## step runs except starting the players (`silent`), since a sound still playing when the
## engine quits there is reported as a leak. `-- --movie-audio` keeps sound in a movie run
## (it is written next to the frames as frame.wav).

const DATA := "res://data/sfx.json"
const VOICES := 8          # one-shots that can sound at once
const STRIDE_PX := 14.0    # farmer pixels walked per footstep
const SNOW_STEPS := 50     # snow cover from which footsteps crunch

var sounds: Dictionary = {}
var ambient_rules: Array = []
var volumes: Dictionary = {}       # bus -> 0..1
var rng := RandomNumberGenerator.new()
var silent := DisplayServer.get_name() == "headless" 		or (Engine.get_write_movie_path() != "" and not "--movie-audio" in OS.get_cmdline_user_args())
var _streams: Dictionary = {}      # key -> AudioStreamWAV, made on first use
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _loops: Dictionary = {}        # loop key -> AudioStreamPlayer
var _target: Dictionary = {}       # loop key -> level 0..1 it fades to
var _fade_seconds := 4.0
var _walked := 0.0
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
	for key in AmbientPicker.loops(ambient_rules):
		var p := AudioStreamPlayer.new()
		p.bus = "Ambient"
		p.volume_linear = 0.0
		add_child(p)
		_loops[key] = p
	Game.day_started.connect(play.bind("chime_morning"))
	Game.changed.connect(_watch_payday)
	_last_bin = Game.bin_total
	_last_money = Game.money


func _process(delta: float) -> void:
	var m := Game.maps.current()
	_target = AmbientPicker.pick(ambient_rules, Game.weather_look(Game.weather_today, Game.season_name()),
			Game.season_name(), Game.hour, m.ambient if m != null else "outdoor") if Game.clock_running else {}
	var step := delta / maxf(_fade_seconds, 0.01)
	for key in _loops:
		var p: AudioStreamPlayer = _loops[key]
		var to := float(_target.get(key, 0.0))
		if to > 0.0 and not p.playing and not silent:
			p.stream = stream(key)
			p.play()
		var base := db_to_linear(float(sounds[key].get("volume_db", 0.0)))
		var level := move_toward(p.volume_linear / base, to, step) if p.playing else 0.0
		p.volume_linear = level * base
		if p.playing and level <= 0.0 and to <= 0.0:
			p.stop()


## Plays a one-shot sound by key, with a random pitch from its range.
func play(key: String) -> void:
	if not sounds.has(key):
		push_warning("Sfx: no sound '%s' in %s" % [key, DATA])
		return
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
		var s: Dictionary = sounds[key]
		_streams[key] = SfxSynth.to_stream(SfxSynth.render(s, hash(key)), s.has("loop"))
	return _streams[key]


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
	if stop_all():
		OS.delay_msec(60)


## Silence at once (and before the engine shuts down, so no playback holds its stream).
func stop_all() -> bool:
	var any := false
	for p: AudioStreamPlayer in _voices + _loops.values():
		any = any or p.playing
		p.stop()
	return any
