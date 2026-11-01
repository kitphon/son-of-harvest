class_name Whistles
extends RefCounted
## Villagers whistling as they walk their day plan. Rules and each villager's tune are in
## data/whistles.json. Once a game minute, each villager on the farmer's map who may whistle
## now (allowed: pose, weather look, hours, kind of place) starts their tune with odds
## `chance`, at least `gap_minutes` after starting the last one. The roll is a hash of the
## villager, the day and the minute, so it doesn't hang on the frame rate and a day plays the
## same each time. The Sfx autoload runs it (step) and plays the tune at a level by the
## distance (level); both views draw a note puff over the whistler while it lasts (puff).
## `-- --whistle` (or `--whistle=<id>`) lets anyone allowed whistle at once (screenshots).

const GameRules := preload("res://scripts/autoload/game.gd")   # SECONDS_PER_MINUTE
const DATA := "res://data/whistles.json"

static var _data: Variant = null
static var _started := {}   # id -> minute their last tune started
static var _rolled := -1    # the last whole minute rolled
static var _day := ""
static var forced := _forced_arg()   # "" none, "*" anyone, else a villager id


static func data() -> Dictionary:
	if _data == null:
		_data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	return _data


static func rules() -> Dictionary:
	return data().rules


static func has_tune(id: String) -> bool:
	return data().tunes.has(id)


## May the villager `w` (as Villagers.on_map gives them) whistle now, by the rules alone?
static func allowed(r: Dictionary, w: Dictionary, look: String, hour: int, place: String) -> bool:
	if not has_tune(w.get("id", "")) or Villagers.actors.has(w.id):
		return false
	if not Villagers.pose(w) in r.get("poses", ["walk"]):
		return false
	if r.has("looks") and not look in r.looks:
		return false
	if r.has("places") and not place in r.places:
		return false
	return not r.has("hours") or AmbientPicker.in_hours(hour, int(r.hours[0]), int(r.hours[1]))


## Does villager `id` start a tune at whole minute `minute` of day `day_key`, odds `chance`?
## (A string's hash alone is too even from minute to minute, so it seeds a generator.)
static func rolls(id: String, day_key: String, minute: int, chance: float) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%d" % [id, day_key, minute])
	return rng.randf() < chance


## 1 within hear_full cells of the farmer, falling (squared) to 0 at hear_reach.
static func level(r: Dictionary, cells: float) -> float:
	var full := float(r.get("hear_full", 3.0))
	var reach := float(r.get("hear_reach", 14.0))
	if cells <= full:
		return 1.0
	var k := clampf((reach - cells) / maxf(reach - full, 0.01), 0.0, 1.0)
	return k * k


## The tunes that start now on map `map_id` at minute `t` (state `s`, Game.trigger_state):
## [{id, level}] by the farmer's feet at `farmer` (cells). Rolls each whole minute since the
## last call once (a few at most, after a jump of the clock).
static func step(map_id: String, t: float, s: Dictionary, look: String, hour: int, place: String,
		farmer: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var day := "%d/%s/%d" % [s.year, s.season, s.day]
	var now := floori(t)
	if day != _day or now < _rolled or now - _rolled > 5:
		_day = day
		_started = {}
		_rolled = now - 1
	if now == _rolled and forced == "":
		return out
	var r := rules()
	for w in Villagers.on_map(map_id, t, s):
		if not allowed(r, w, look, hour, place) or playing(w.id, t):
			continue
		var go: bool = forced == "*" or forced == w.id
		var gap := float(r.get("gap_minutes", 40.0))
		if not go and (not _started.has(w.id) or t - float(_started[w.id]) >= gap):
			for m in range(_rolled + 1, now + 1):
				go = go or rolls(w.id, day, m, float(r.get("chance", 0.05)))
		if go:
			_started[w.id] = t
			out.append({"id": w.id, "level": level(r, farmer.distance_to(w.pos))})
	_rolled = now
	return out


## Is villager `id`'s tune still sounding at minute `t`?
static func playing(id: String, t: float) -> bool:
	return puff(id, t) >= 0.0


## How far through their tune villager `id` is at minute `t`, 0..1, or -1 when not whistling.
static func puff(id: String, t: float) -> float:
	if not _started.has(id) or _day == "":
		return -1.0
	var p := (t - float(_started[id])) / minutes(id)
	return p if p >= 0.0 and p < 1.0 else -1.0


## How the note puff looks at `p` (puff, 0..1) in sprite pixels above the head: {key (one
## note, then two beamed, then one again), rise, sway (side to side), alpha (in fast, out slow)}.
static func puff_look(p: float) -> Dictionary:
	return {"key": "fx:notes" if int(p * 3.0) == 1 else "fx:note", "rise": 2.0 + 8.0 * p,
		"sway": 2.5 * sin(p * TAU * 1.5), "alpha": clampf(p / 0.1, 0.0, 1.0) * clampf((1.0 - p) / 0.3, 0.0, 1.0)}


## Game minutes villager `id`'s tune lasts (its seconds by the clock's pace).
static func minutes(id: String) -> float:
	return MusicSynth.loop_seconds(track(id)) / GameRules.SECONDS_PER_MINUTE


## Villager `id`'s tune as a one-bar MusicSynth track on the whistle instrument.
static func track(id: String) -> Dictionary:
	var tune: Dictionary = data().tunes[id]
	var notes := String(tune.notes)
	return {"bpm": tune.bpm, "steps_per_beat": 2, "steps_per_bar": notes.split(" ", false).size(), "bars": 1,
		"root": tune.root, "scale": tune.scale, "voices": [{"instrument": "whistle", "bars": [notes]}]}


## The tune's sound (mono, normalized), exactly its length; it ends on rests, so nothing is cut.
static func render(id: String) -> PackedFloat32Array:
	return MusicSynth.render(track(id), {"whistle": data().instrument}, hash(id), 1)


## Forgets every tune started (a new game, tests).
static func reset() -> void:
	_started = {}
	_rolled = -1
	_day = ""


static func _forced_arg() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg == "--whistle":
			return "*"
		if arg.begins_with("--whistle="):
			return arg.trim_prefix("--whistle=")
	return ""
