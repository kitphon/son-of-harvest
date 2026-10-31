class_name AmbientPicker
extends RefCounted
## Which ambient loops play and how loud (0..1), from today's weather look, the season and
## the hour. Pure rules from data/sfx.json → "ambient"; the Sfx autoload cross-fades to them.


## loop key -> level for the loops that should sound now (silent loops are left out).
static func pick(rules: Array, look: String, season_id: String, hour: int) -> Dictionary:
	var levels := {}
	for r in rules:
		if r.has("looks") and not (look in r.looks):
			continue
		if r.has("seasons") and not (season_id in r.seasons):
			continue
		if r.has("hours") and not in_hours(hour, int(r.hours[0]), int(r.hours[1])):
			continue
		var level := float(r.get("level", 1.0))
		if level > float(levels.get(r.loop, 0.0)):
			levels[r.loop] = level
	return levels


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
