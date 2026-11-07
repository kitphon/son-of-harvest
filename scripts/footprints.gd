class_name Footprints
extends RefCounted
## Footprints pressed into lying snow, the rules both views share (FootprintLayer in 3D,
## FootprintView in the flat view draw them). Walkers (the farmer, the villagers, the dog) are
## fed each frame as {id: cell position}; one that has moved `step` cells since its last print
## leaves another, to the left and right in turn (`side` off its line, turned along the walk).
## Prints are kept in a ring of at most `cap` (the oldest go first), age in game minutes and
## are gone after `life`; while snow falls they age `snowing_rate` times as fast (fresh snow
## fills them). None are made under `min_cover` percent of snow, where the ground holds under
## `min_hold` of it (water, tilled soil), indoors or in the mine (`active`). Numbers:
## data/footprints.json.

const DEFAULTS := {"min_cover": 30, "min_hold": 0.65, "step": 0.55, "side": 0.11, "cap": 160, "life": 90,
	"snowing_rate": 4.0, "jump": 3.0, "size": [0.3, 0.46], "color": "5f76ab", "alpha": 0.95}

var rules: Dictionary = DEFAULTS
var prints: Array = []   # oldest first: {pos: Vector2 (cells), dir: Vector2, age: float (minutes)}
var _last := {}          # walker id -> {pos: Vector2, side: int}


func _init(r: Dictionary = {}) -> void:
	rules = DEFAULTS.duplicate()
	rules.merge(r, true)


## The rules from data/footprints.json.
static func from_game() -> Footprints:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/footprints.json"))
	return Footprints.new(parsed if parsed is Dictionary else {})


## Is there snow enough for prints (cover 0..100), out in the open?
func active(cover: float, sheltered: bool) -> bool:
	return not sheltered and cover >= float(rules.min_cover)


## Feeds the walkers' places now: `walkers` is {id: Vector2 cell position}; `hold` (optional)
## says how much snow the ground at a position holds, 0..1. Returns how many prints were made.
func feed(walkers: Dictionary, hold := Callable()) -> int:
	var made := 0
	for id in _last.keys():
		if not walkers.has(id):
			_last.erase(id)   # gone from the map: starts afresh if it comes back
	for id in walkers:
		var pos: Vector2 = walkers[id]
		if not _last.has(id):
			_last[id] = {"pos": pos, "side": 1 if hash(id) % 2 == 0 else -1}
			continue
		var l: Dictionary = _last[id]
		var d: Vector2 = pos - l.pos
		var dist := d.length()
		if dist > float(rules.jump):
			l.pos = pos   # a jump (a door, an event), not a walk: no trail across it
			continue
		if dist < float(rules.step):
			continue
		var dir := d / dist
		l.side = -int(l.side)
		var at := pos + Vector2(-dir.y, dir.x) * float(rules.side) * int(l.side)
		l.pos = pos
		if hold.is_valid() and float(hold.call(at)) < float(rules.min_hold):
			continue
		prints.append({"pos": at, "dir": dir, "age": 0.0})
		made += 1
	while prints.size() > int(rules.cap):
		prints.pop_front()
	return made


## `minutes` of game time pass (`snowing`: snow is falling, so the prints fill quicker).
func age(minutes: float, snowing := false) -> void:
	var rate := float(rules.snowing_rate) if snowing else 1.0
	for p in prints:
		p.age += minutes * rate
	prints = prints.filter(func(p): return p.age < float(rules.life))


## How strong a print shows, 1 (fresh) .. 0 (filled in).
func strength(p: Dictionary) -> float:
	return clampf(1.0 - float(p.age) / float(rules.life), 0.0, 1.0)


func clear() -> void:
	prints.clear()
	_last.clear()


## How much snow the ground at `at` (cells) holds on the current map, 0..1 (SnowLayer's hold by
## ground kind), for `feed`'s `hold`.
static func ground_hold(at: Vector2) -> float:
	var c := Vector2i(floori(at.x), floori(at.y))
	if Game.maps.on_farm():
		return SnowLayer.hold(Game.farm, c, Game.snow_rules)
	return SnowLayer.map_hold(Game.maps.current(), c, Game.snow_rules)
