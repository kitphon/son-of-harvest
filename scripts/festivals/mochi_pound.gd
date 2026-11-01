class_name MochiPound
extends RefCounted
## One go at the mochi pounding (data/festivals.json → a festival's `game`, kind mochi): the
## farmer swings the mallet on the beat while the partner turns the dough between strikes.
## Pure timing: advance(delta) moves the clock and marks the beats let pass, press() judges a
## swing against the nearest beat. MochiScreen draws it and plays the sounds; Game.finish_game
## ranks the score. Format: README.md, Festivals.

const GRADES: Array[String] = ["great", "good", "miss"]

var beats: Array[float] = []    # the strike times, seconds from the start, in order
var round_of: Array[int] = []   # per beat: its round (0 = the first)
var marks: Array[String] = []   # per beat: "" until judged, then great / good / miss
var turns: Array[float] = []    # the partner's hands go in: halfway between strikes of a round
var rounds := 0
var time := 0.0
var score := 0
var counts := {"great": 0, "good": 0, "miss": 0}
var last := ""                  # the last grade given
var last_at := -99.0            # when it was given
var swung_at := -99.0           # the last press (the mallet's swing)
var _great := 0.0
var _good := 0.0
var _points := {}
var _next := 0                  # the first beat not judged yet
var _turn := 0                  # the next turn to pass


func _init(g: Dictionary) -> void:
	_great = float(g.windows.great)
	_good = float(g.windows.good)
	_points = g.points
	var start := float(g.lead)
	rounds = g.rounds.size()
	for i in rounds:
		var r: Dictionary = g.rounds[i]
		for b in int(r.beats):
			beats.append(start + b * float(r.beat))
			round_of.append(i)
			marks.append("")
			if b > 0:
				turns.append(start + (b - 0.5) * float(r.beat))
		start = beats.back() + float(r.beat) + float(g.gap)


## The best score there is (every strike great).
func best() -> int:
	return beats.size() * int(_points.great)


## Moves the clock on by `delta` seconds. Returns what happened, in order: "miss" for each
## beat let pass without a swing, "turn" each time the partner turns the dough.
func advance(delta: float) -> Array[String]:
	var out: Array[String] = []
	time += delta
	while _turn < turns.size() and turns[_turn] <= time:
		_turn += 1
		out.append("turn")
	while _next < beats.size() and time > beats[_next] + _good:
		_mark(_next, "miss")
		out.append("miss")
	return out


## A swing of the mallet now: "great" or "good" within the windows of the next beat, else
## "miss" (off the beat, the partner's hands in the way; the beat stays open). Nothing once done.
func press() -> String:
	if done():
		return ""
	swung_at = time
	var d := absf(time - beats[_next])
	var grade := "great" if d <= _great else "good" if d <= _good else "miss"
	if grade == "miss":
		_add("miss")
	else:
		_mark(_next, grade)
	return grade


## Every beat judged.
func done() -> bool:
	return _next >= beats.size()


## The round being played now (0 = the first; the last once done).
func round_now() -> int:
	return round_of[mini(_next, beats.size() - 1)]


## Seconds to the next beat to strike (negative just after it, inside its window); 99 when done.
func to_next() -> float:
	return beats[_next] - time if not done() else 99.0


## The partner's hands are in the mortar: around a turn, away from the strikes.
func turning() -> bool:
	for t in turns:
		if absf(time - t) < 0.12:
			return true
	return false


## How smooth the dough is, 0 (rice) to `steps` - 1 (round mochi), by the strikes landed.
func dough(steps: int) -> int:
	var landed := int(counts.great) + int(counts.good)
	return clampi(landed * steps / maxi(beats.size(), 1), 0, steps - 1)


func _mark(i: int, grade: String) -> void:
	marks[i] = grade
	_next = i + 1
	_add(grade)


func _add(grade: String) -> void:
	counts[grade] += 1
	score = maxi(score + int(_points[grade]), 0)
	last = grade
	last_at = time
