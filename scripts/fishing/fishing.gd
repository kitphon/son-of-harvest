class_name Fishing
extends RefCounted
## The fishing line, as pure rules (tested headless): cast, wait for a bite, a short bite
## window, reel in. Which fish bites comes from the place, season, hour and weather in
## data/fish.json. Game owns one and steps it while the clock runs; the views only read it.

var rules: Dictionary
var state := "idle"           # "idle" (no line out), "wait" (bobber in the water), "bite"
var place := ""               # map id of the water the line is in
var spot := Vector2i.ZERO     # the water cell with the bobber
var time := 0.0               # seconds in the current state
var dry_casts := 0            # casts in a row that brought no fish (the pity counter; saved)
var _next_check := 0.0


func _init(fish_rules := {}) -> void:
	rules = fish_rules


func active() -> bool:
	return state != "idle"


## The bobber lands on `at_spot` in `at_place`; the wait starts.
func cast(at_place: String, at_spot: Vector2i) -> void:
	state = "wait"
	place = at_place
	spot = at_spot
	time = 0.0
	_next_check = float(rules.get("min_wait_seconds", 2.5))


## Takes the line out without a result (a map change, the day ending).
func stop() -> void:
	state = "idle"
	time = 0.0


## Advances `delta` seconds. `chance` is the bite chance per check now (bite_chance()),
## rolled with `rng` once per check. Returns "bite" when a fish bites, "escaped" when the
## bite window ran out, else "".
func step(delta: float, chance: float, rng: RandomNumberGenerator) -> String:
	if state == "idle":
		return ""
	time += delta
	if state == "bite":
		if time >= float(rules.get("bite_seconds", 0.9)):
			state = "idle"
			dry_casts += 1
			return "escaped"
		return ""
	while time >= _next_check:
		_next_check += float(rules.get("check_seconds", 1.0))
		var sure := dry_casts >= int(rules.get("sure_after", 7))
		if sure or rng.randf() < chance:
			state = "bite"
			time = 0.0
			return "bite"
	return ""


## The button while the line is out: during a bite the fish is hooked ("catch"), before it
## the line comes back empty ("early"; it counts against the pity rule only once the fish
## had a chance to bite, so a quick recast isn't a shortcut). The line is out of the water after.
func reel() -> String:
	var was := state
	var checked := time >= float(rules.get("min_wait_seconds", 2.5))
	state = "idle"
	time = 0.0
	match was:
		"bite":
			dry_casts = 0
			return "catch"
		"wait":
			if checked:
				dry_casts += 1
			return "early"
	return "none"


## The chance per check that a fish bites at `hour` in weather look `weather`.
static func bite_chance(fish_rules: Dictionary, hour: int, weather: String) -> float:
	var chance := 0.0
	for band in fish_rules.get("bite_chance", []):
		if hour >= int(band[0]):
			chance = float(band[1])
	return chance * float(fish_rules.get("weather_bite", {}).get(weather, 1.0))


## Does [from, to) on the clock hold `hour`? A range that wraps past midnight works too.
static func in_hours(hours: Array, hour: int) -> bool:
	if hours.size() != 2:
		return true
	var from := int(hours[0])
	var to := int(hours[1])
	return (hour >= from and hour < to) if from <= to else (hour >= from or hour < to)


## Fish id -> weight for everything that can bite in `at_place` now. `caught` is fish id ->
## how many were caught this game (once-only fish drop out after the first).
static func candidates(fish_rules: Dictionary, at_place: String, season: String, hour: int,
		weather: String, caught := {}) -> Dictionary:
	var out := {}
	var fish: Dictionary = fish_rules.get("fish", {})
	for id in fish:
		var f: Dictionary = fish[id]
		var w := float(f.get("places", {}).get(at_place, 0))
		if f.has("seasons") and not (season in f.seasons):
			continue
		if not in_hours(f.get("hours", []), hour):
			continue
		if f.get("once", false) and int(caught.get(id, 0)) > 0:
			continue
		w *= float(f.get("weather", {}).get(weather, 1.0))
		if w > 0.0:
			out[id] = w
	return out


## The fish a roll in [0, 1) picks from weights (candidates()); "" when there is none.
static func pick(weights: Dictionary, roll: float) -> String:
	var total := 0.0
	for id in weights:
		total += float(weights[id])
	var at := roll * total
	for id in weights:
		at -= float(weights[id])
		if at < 0.0:
			return id
	return "" if weights.is_empty() else weights.keys().back()


# --- the fish log (pause menu) ---------------------------------------------------

## One row per fish kind in data/fish.json, in file order: {id, count (0 = never caught)}.
## `caught` is Game.fish_caught (fish id -> how many were caught this game).
static func log_rows(fish_rules: Dictionary, caught: Dictionary) -> Array:
	var out := []
	for id in fish_rules.get("fish", {}):
		out.append({"id": id, "count": int(caught.get(id, 0))})
	return out


## How many kinds were caught at least once (only kinds still in the data count).
static func kinds_caught(fish_rules: Dictionary, caught: Dictionary) -> int:
	var n := 0
	for row in log_rows(fish_rules, caught):
		n += int(row.count > 0)
	return n


## The places a fish bites, as names shown to the player, most common first.
static func places_of(fish_rules: Dictionary, id: String) -> Array[String]:
	var weights: Dictionary = fish_rules.get("fish", {}).get(id, {}).get("places", {})
	var ids := weights.keys()
	ids.sort_custom(func(a, b): return float(weights[a]) > float(weights[b]))
	var out: Array[String] = []
	for p in ids:
		out.append(String(fish_rules.get("places", {}).get(p, {}).get("name", p)))
	return out


## The seasons a fish bites in, as ids in calendar order (`all`); every one when the data names none.
static func seasons_of(fish_rules: Dictionary, id: String, all: Array) -> Array[String]:
	var f: Dictionary = fish_rules.get("fish", {}).get(id, {})
	var out: Array[String] = []
	for s in all:
		if not f.has("seasons") or s in f.seasons:
			out.append(s)
	return out


## The clock hours a fish bites in, [from, to), or [] for all day.
static func hours_of(fish_rules: Dictionary, id: String) -> Array:
	var h: Array = fish_rules.get("fish", {}).get(id, {}).get("hours", [])
	return h if h.size() == 2 else []
