class_name MusicPicker
extends RefCounted
## Which music track plays and how loud (0..1), from the scene ("title" / "field"), today's
## weather look, the season and the hour. Pure rules from data/music.json → "rules": the first
## rule that fits wins (a missing list = any, hours as in AmbientPicker). The Sfx autoload
## cross-fades to it.


## {track: level} for the track that should play now, or {} for silence.
static func pick(rules: Array, scene: String, look: String, season_id: String, hour: int) -> Dictionary:
	for r in rules:
		if r.has("scenes") and not (scene in r.scenes):
			continue
		if r.has("looks") and not (look in r.looks):
			continue
		if r.has("seasons") and not (season_id in r.seasons):
			continue
		if r.has("hours") and not AmbientPicker.in_hours(hour, int(r.hours[0]), int(r.hours[1])):
			continue
		return {r.track: float(r.get("level", 1.0))} if r.track != "" else {}
	return {}


## Every track the rules can ask for.
static func tracks(rules: Array) -> Array:
	var keys := []
	for r in rules:
		if r.track != "" and not (r.track in keys):
			keys.append(r.track)
	return keys
