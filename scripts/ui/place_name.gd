class_name PlaceName
extends RefCounted
## The name of the place the farmer has come to, shown a moment at the top left (Hud): the map's
## name on arriving on a map ("Village", "Tome's house"), or the named place's (a zone of
## data/maps, MapData.zones) when the farmer arrives inside one, and a zone's name again on
## walking into it ("Tenryo-ji Temple"). Walking out of a zone shows nothing; coming back into
## the same zone within AGAIN seconds shows nothing either, so stepping to and fro over its edge
## does not flash the name. A mine floor shows none (its own message says the floor). Pure: Hud
## feeds it the map, the farmer's cell and the time, and draws what it returns.

const FADE_IN := 0.25   # seconds the name takes to come up
const HOLD := 2.0       # seconds it stays fully up
const FADE_OUT := 0.7   # seconds it takes to fade away
const AGAIN := 6.0      # seconds after leaving a zone before coming back shows its name again

var zone := ""          # the id of the zone the farmer stands in, "" for none
var clock := 0.0        # seconds walked on this map (walk's deltas)
var _left: Dictionary = {}   # zone id -> clock when the farmer last walked out of it


## The farmer arrives on map `m` at `cell`: the name to show ("" for none).
func arrive(m: MapData, cell: Vector2i, mine_floor := false) -> String:
	clock = 0.0
	_left.clear()
	var z := m.zone_at(cell) if m != null else {}
	zone = str(z.get("id", ""))
	if m == null or mine_floor:
		return ""
	return str(z.name) if not z.is_empty() else m.name


## The farmer stands at `cell` of `m`, `delta` seconds on: a zone's name when they have just
## walked into it, else "".
func walk(m: MapData, cell: Vector2i, delta: float) -> String:
	clock += delta
	if m == null:
		return ""
	var z := m.zone_at(cell)
	var id := str(z.get("id", ""))
	if id == zone:
		return ""
	if zone != "":
		_left[zone] = clock
	zone = id
	if id == "" or (_left.has(id) and clock - float(_left[id]) < AGAIN):
		return ""
	return str(z.name)


## How far up the name is (0..1), `t` seconds after it was shown.
static func alpha(t: float) -> float:
	if t < 0.0 or t >= FADE_IN + HOLD + FADE_OUT:
		return 0.0
	if t < FADE_IN:
		return t / FADE_IN
	if t < FADE_IN + HOLD:
		return 1.0
	return 1.0 - (t - FADE_IN - HOLD) / FADE_OUT
