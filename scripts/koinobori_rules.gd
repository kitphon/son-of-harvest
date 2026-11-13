class_name KoinoboriRules
extends RefCounted
## Carp streamers (koinobori) on a bamboo pole in the village in late spring (data/koinobori.json).
## The logic both views share: whether the pole stands today (season, day of the season, clock,
## the weather look: taken down in rain and storm), and what the wind makes of each hanging
## thing now: how full a carp is (limp, half, full), which flap frame it shows and how fast the
## wheel on top turns. The 3D view (KoinoboriProps) and the flat view (KoinoboriView) draw the
## same KoiArt pictures from these. Pure: nothing here draws.

const DATA_PATH := "res://data/koinobori.json"
const KIND := "koinobori"
const LEVELS := 3   # limp, half filled, full

static var _cfg: Dictionary = {}
static var _forced_read := false
static var _forced := false
static var _forced_wind := -1.0


## data/koinobori.json (read once).
static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## `-- --koinobori` on the command line: the pole stands whatever the season, day, hour and
## weather (screenshots); `--koinobori=<0..1>` also sets the wind it feels (0 limp, 0.8 streaming).
static func forced() -> bool:
	_read_args()
	return _forced


## The wind `--koinobori=<n>` asked for, -1 when it did not.
static func forced_wind() -> float:
	_read_args()
	return _forced_wind


static func _read_args() -> void:
	if _forced_read:
		return
	_forced_read = true
	for arg in OS.get_cmdline_user_args():
		if arg == "--koinobori":
			_forced = true
		elif arg.begins_with("--koinobori="):
			_forced = true
			var v := arg.trim_prefix("--koinobori=")
			if v.is_valid_float():
				_forced_wind = clampf(float(v), 0.0, 1.0)


static func _minutes(s: String) -> int:
	var parts := s.split(":")
	return int(parts[0]) * 60 + (int(parts[1]) if parts.size() > 1 else 0)


## Does the pole stand on prop `p` (its own `season`, `days`, `hours` over the data's) in `season_id`
## on `day` of it at `minute_of_day`, under today's weather look `look`?
static func up(p: Dictionary, season_id: String, day: int, minute_of_day: int, look: String, cfg := {}) -> bool:
	if cfg.is_empty():
		cfg = config()
	if look in (cfg.wet as Array):
		return false
	if season_id != str(p.get("season", cfg.season)):
		return false
	var days: Array = p.get("days", cfg.days)
	if day < int(days[0]) or day > int(days[1]):
		return false
	var hours: Array = p.get("hours", cfg.hours)
	return minute_of_day >= _minutes(str(hours[0])) and minute_of_day < _minutes(str(hours[1]))


## The same for now, by `game` (the Game autoload; views pass it, looked up by path so this
## script compiles before the autoloads). `--koinobori` keeps it up.
static func up_now(p: Dictionary, game: Object) -> bool:
	if forced():
		return true
	return up(p, game.season_name(), game.day, game.hour * 60 + game.minute, game.weather_look(game.weather_today, game.season_name()))


## The wind the pole feels now: today's (Game.wind_strength), or what `--koinobori=<n>` set.
static func wind_now(game: Object) -> float:
	return forced_wind() if forced_wind() >= 0.0 else float(game.wind_strength())


static func _smooth(x: float) -> float:
	var s := clampf(x, 0.0, 1.0)
	return s * s * (3.0 - 2.0 * s)


## The wind a hanging thing feels at time `t` (s): the day's strength times a slow gust swing, wide
## in a breeze and narrowing to nothing in a gale (the `phase` keeps each carp's gusts a little
## apart); never below 0.
static func effective(wind: float, t: float, phase: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	var g := float(cfg.wind.gust) * (1.0 - clampf(wind, 0.0, 1.0))   # a steady wind gusts less, a breeze a lot
	return maxf(wind * (1.0 + g * (0.6 * sin(t * 0.45 + phase) + 0.4 * sin(t * 1.3 + phase * 1.7))), 0.0)


## How full a carp is, 0 (limp) .. 1 (wholly filled), in an effective wind.
static func fill_of(eff: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	return _smooth((eff - float(cfg.wind.calm)) / maxf(float(cfg.wind.full) - float(cfg.wind.calm), 0.001))


## The fill cut into a level: 0 limp and hanging, 1 half filled and slanting, 2 full and streaming.
static func level_of(fill: float, cfg := {}) -> int:
	if cfg.is_empty():
		cfg = config()
	var cuts: Array = cfg.wind.levels
	return 0 if fill < float(cuts[0]) else (1 if fill < float(cuts[1]) else 2)


## What a carp (or the streamer) with `phase` shows at time `t` (s) in `wind`: {fill, level, frame},
## its flap frame (0 or 1) swapping faster the fuller it is.
static func carp(wind: float, t: float, phase: float, cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var fill := fill_of(effective(wind, t, phase, cfg), cfg)
	var hz := float(cfg.flap.base) + float(cfg.flap.gain) * fill
	return {"fill": fill, "level": level_of(fill, cfg), "frame": posmod(int(floor(t * hz * 2.0 + phase * 3.0)), 2)}


## How many periods a second the wheel turns in an effective wind `eff` (a calm still turns it
## slowly). The views add this up over time (`turns`), so the wheel never jumps when the wind changes.
static func wheel_speed(eff: float, cfg := {}) -> float:
	if cfg.is_empty():
		cfg = config()
	return float(cfg.wheel.base) + float(cfg.wheel.gain) * eff


## The wheel's picture frame after `turns` periods.
static func wheel_frame(turns: float, cfg := {}) -> int:
	if cfg.is_empty():
		cfg = config()
	var n := int(cfg.wheel.frames)
	return posmod(int(floor(turns * float(n))), n)


## The art key of one carp of the data's list by `id` ("black", "red", "blue"), the streamer
## ("stream") or the wheel ("wheel") at `level` and `frame` (the wheel's `level` is 0).
static func art_key(id: String, level: int, frame: int) -> String:
	return "koi:%s:%d:%d" % [id, level, frame]
