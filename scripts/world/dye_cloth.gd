class_name DyeCloth
extends RefCounted
## Shino's indigo lengths drying on the bamboo rack beside her vats (a "cloth_rack" map prop,
## data/maps/minamino.json). The rack's rows (north to south) are its poles, each with one
## long length hung over it; the shade of each comes from the prop's `shades`, the palest on
## the first pole by the vats and the darkest on the last (more dips in the vat, a deeper
## blue). The lengths are out in the prop's `hours` on dry days; at night and when the day's
## weather look is wet (WET: rain, storm, snow, a blizzard) they are taken in and only the
## bare frame stands. Pure rules: the 3D view (OutdoorProps.cloth_rack) and the flat view
## (DyeClothView) draw it, both swaying in today's wind (data/wind.json).

const KIND := "cloth_rack"
const WET: Array[String] = ["rain", "storm", "snow", "blizzard"]
const DEFAULT_HOURS: Array[String] = ["07:00", "17:00"]
const DEFAULT_SHADE := "2f5a96"
const POLE_Y := 1.7    # world units: the poles' height over the ground
const DROP := 1.45     # how far a length hangs below its pole
const ART_W := 22      # the picture of one length, in pixels (PlaceholderArt "cloth:<hex>")
const ART_H := 24
const STREAM := 0.3    # the downwind shear per unit of wind, OutdoorProps.Sway.CLOTH_STREAM's (copied: the
                       # 3D scripts name the Game autoload and MapView, which reads KIND, compiles first)


## Minutes of the day of "HH:MM".
static func _minutes(s: String) -> int:
	var parts := s.split(":")
	return int(parts[0]) * 60 + (int(parts[1]) if parts.size() > 1 else 0)


## Is the cloth out on rack `p` at `minute_of_day` with today's weather look `look`?
static func out(p: Dictionary, minute_of_day: int, look: String) -> bool:
	if look in WET:
		return false
	var hours: Array = p.get("hours", DEFAULT_HOURS)
	return minute_of_day >= _minutes(str(hours[0])) and minute_of_day < _minutes(str(hours[1]))


## The same for now, by `game` (the Game autoload: its clock and today's look). Views pass it
## (looked up by path, so this script compiles before the autoloads).
static func out_now(p: Dictionary, game: Object) -> bool:
	return out(p, game.hour * 60 + game.minute, game.weather_look(game.weather_today, game.season_name()))


## How far the hem of a length hangs downwind of its pole's line, in drop lengths (+x), wind 0..1
## at time `t` (s), the same shear as the 3D Sway's free cloth (OutdoorProps.Sway._cloth with
## yaw 0: a breeze by the square root of the wind, the stream and its gusting wave).
static func stream(wind: float, t: float, phase: float) -> float:
	if wind <= 0.0:
		return 0.0
	var k := sqrt(wind)
	var tt := t * (1.6 + 1.0 * wind)
	var wave2 := 0.6 * sin(tt * 1.7 + phase * 0.8) + 0.4 * sin(tt * 3.7 + phase * 1.9)
	var g := 1.0 + wind * (0.8 * sin(t * 0.55 + phase * 0.3) + 0.4 * sin(t * 1.7 + phase * 0.5))
	return k * (STREAM + 0.15 * g * wave2)


## How many poles (lengths) the rack has: one a row of its cells.
static func poles(p: Dictionary) -> int:
	var size: Variant = p.get("size", Vector2i.ONE)   # a Vector2i once loaded (MapData), an array in raw data
	return size.y if size is Vector2i else int(size[1])


## The shade of each pole's length, first (north) to last; the last shade repeats if the
## prop names fewer than its poles.
static func shades(p: Dictionary) -> Array[Color]:
	var names: Array = p.get("shades", [DEFAULT_SHADE])
	var out_c: Array[Color] = []
	for i in poles(p):
		out_c.append(Color(str(names[mini(i, names.size() - 1)])))
	return out_c


## The art key of one length in shade `c`.
static func art_key(c: Color) -> String:
	return "cloth:" + c.to_html(false)


## Shows its children only while the cloth on `rack` is out (checked each game minute).
class Show extends Node3D:
	var rack: Dictionary = {}

	func _ready() -> void:
		(Engine.get_main_loop() as SceneTree).root.get_node("Game").minute_passed.connect(refresh)
		refresh()

	func refresh() -> void:
		visible = DyeCloth.out_now(rack, (Engine.get_main_loop() as SceneTree).root.get_node("Game"))
