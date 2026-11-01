class_name FishingRace
extends RefCounted
## One go at the fishing race (data/festivals.json → a festival's `game`, kind fishing): a
## count-in of `lead` seconds, then `seconds` to land as many fish as the farmer can with the
## real rod (Game.cast_line / reel_in and the bite rules of data/fish.json), then a moment for
## the call before Game.finish_game ranks the count. Pure timing and the creel; Game steps it
## while the festival runs (the clock holds) and RaceScreen draws it. Format: README.md, Festivals.

const SHOW_RESULT := 2.0   # seconds the "Time!" call stays up before the results
const STAGES: Array[String] = ["go", "time", "done"]   # what advance() calls, in order

var lead := 0.0
var seconds := 0.0
var time := 0.0
var fish: Array[String] = []   # the fish ids landed, in order (the creel; let go at the end)
var _called := 0               # STAGES called so far


func _init(g: Dictionary) -> void:
	lead = float(g.get("lead", 0.0))
	seconds = float(g.seconds)


## Moves the clock on by `delta` seconds. Returns what happened: "go" when the race starts,
## "time" when it ends, "done" when the call has been shown (Game finishes the game then).
func advance(delta: float) -> Array[String]:
	var out: Array[String] = []
	time += delta
	for i in range(_called, STAGES.size()):
		if time < lead + [0.0, seconds, seconds + SHOW_RESULT][i]:
			break
		out.append(STAGES[i])
		_called = i + 1
	return out


## Lines may go out and fish count: after the count-in, before time.
func running() -> bool:
	return time >= lead and time < lead + seconds


## Time is up (the call shows; nothing counts any more).
func over() -> bool:
	return time >= lead + seconds


## Seconds of fishing left (all of them during the count-in, 0 once over).
func left() -> float:
	return clampf(lead + seconds - time, 0.0, seconds)


## Seconds of the count-in still to go (0 once the race is on).
func to_go() -> float:
	return maxf(lead - time, 0.0)


## A fish landed now: into the creel while the race runs. Returns whether it counted.
func land(id: String) -> bool:
	if not running():
		return false
	fish.append(id)
	return true


## The score: fish in the creel.
func score() -> int:
	return fish.size()


## For the save: {time, fish}.
func to_dict() -> Dictionary:
	return {"time": time, "fish": fish.duplicate()}


## A race from game `g` and a saved {time, fish}; null when the save is broken.
static func parse(g: Dictionary, d: Variant) -> FishingRace:
	if not d is Dictionary or not (d.get("time") is float or d.get("time") is int) or not d.get("fish") is Array:
		return null
	var r := FishingRace.new(g)
	r.time = clampf(float(d.time), 0.0, r.lead + r.seconds)
	r._called = (1 if r.time >= r.lead else 0) + (1 if r.time >= r.lead + r.seconds else 0)
	for id in d.fish:
		if not id is String or id == "":
			return null
		r.fish.append(id)
	return r
