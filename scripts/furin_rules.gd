class_name FurinRules
extends RefCounted
## The wind chime (furin) under the farmhouse's eave over the engawa: the rules (data/furin.json).
## The pure parts take their numbers and the weather look as values. It hangs out on the farm's
## open air in summer and is taken in during a storm or a blizzard (Game.weather_look). It sways
## with the wind (data/wind.json through Game.wind_strength and FarmWorld.wind): still in dead
## calm, further and quicker as the wind grows, with a slow swell of gusts. Drawn by FurinLayer
## (3D) and FurinView (flat view); the picture is PlaceholderArt "furin".

const DATA_PATH := "res://data/furin.json"
const KEY := "furin"

static var _cfg: Dictionary = {}


static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _cfg


## Whether the chime hangs out: on the farm's open air (not indoors), in a season it hangs in, and
## under a weather look that does not take it in. `cfg` defaults to data/furin.json.
static func hangs(season_id: String, look: String, farm: bool, indoor: bool, cfg: Dictionary = {}) -> bool:
	var c := cfg if not cfg.is_empty() else config()
	return farm and not indoor and season_id in (c.seasons as Array) and not look in (c.taken_in as Array)


## hangs for the Game autoload's clock and weather, and the map `map` (MapData).
static func hangs_now(game: Node, map: MapData) -> bool:
	if game == null or map == null:
		return false
	return hangs(game.season_name(), game.weather_look(game.weather_today, game.season_name()), map.farm, map.indoor)


## Where the chime hangs, in world units: x and z in cells, y the height of its top.
static func place(cfg: Dictionary = {}) -> Vector3:
	var p: Dictionary = (cfg if not cfg.is_empty() else config()).place
	return Vector3(float(p.x), float(p.top), float(p.z))


## How far the chime is swung off plumb, in radians, at wind `wind` (0 .. 1) and time `t` (seconds).
## Zero in dead calm; the swing's reach grows with the wind, its rate too, and a gust swell dips it.
static func sway_angle(wind: float, t: float, cfg: Dictionary = {}) -> float:
	var s: Dictionary = (cfg if not cfg.is_empty() else config()).sway
	var w := clampf(wind, 0.0, 1.0)
	if w <= 0.0:
		return 0.0
	var reach := deg_to_rad(float(s.max_deg)) * w
	var gust := 1.0 - float(s.gust_depth) * (0.5 + 0.5 * sin(TAU * float(s.gust_hz) * t))
	var rate := float(s.rate_hz) * (1.0 + float(s.rate_gain) * w)
	return reach * gust * sin(TAU * rate * t)
