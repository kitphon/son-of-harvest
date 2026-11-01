class_name AmbientPicker
extends RefCounted
## Which ambient loops play and how loud (0..1), from today's weather look, the season, the
## hour, the kind of place (the map's "ambient": outdoor, indoor), the map id and how far the
## farmer stands from water. Pure rules from data/sfx.json → "ambient"; the Sfx autoload
## cross-fades to them.


## loop key -> level for the loops that should sound now (silent loops are left out).
## A rule without "places" is for outdoors only; one with "maps" only for those map ids; one
## with "near" (cells) only within that distance of water (`water` cells away, < 0 = none on
## this map), fading out towards the edge.
static func pick(rules: Array, look: String, season_id: String, hour: int, place := "outdoor",
		map_id := "", water := -1.0) -> Dictionary:
	var levels := {}
	for r in rules:
		if not (place in r.get("places", ["outdoor"])):
			continue
		if r.has("maps") and not (map_id in r.maps):
			continue
		if r.has("looks") and not (look in r.looks):
			continue
		if r.has("seasons") and not (season_id in r.seasons):
			continue
		if r.has("hours") and not in_hours(hour, int(r.hours[0]), int(r.hours[1])):
			continue
		var level := float(r.get("level", 1.0))
		if r.has("near"):
			level *= near_level(water, float(r.near))
		if level > float(levels.get(r.loop, 0.0)):
			levels[r.loop] = level
	return levels


## 1 by the water (up to a cell away), falling to 0 at `radius` cells; 0 with no water.
static func near_level(water: float, radius: float) -> float:
	if water < 0.0 or radius <= 1.0:
		return 0.0
	return clampf((radius - water) / (radius - 1.0), 0.0, 1.0)


## hour in [from, to); from > to wraps past midnight (19, 4 = 19:00 .. 3:59).
static func in_hours(hour: int, from: int, to: int) -> bool:
	if from <= to:
		return hour >= from and hour < to
	return hour >= from or hour < to


## Every loop key the rules can ask for.
static func loops(rules: Array) -> Array:
	var keys := []
	for r in rules:
		if not (r.loop in keys):
			keys.append(r.loop)
	return keys
