class_name GoldfishScoop
extends RefCounted
## One go at the goldfish scoop (data/festivals.json → a festival's `game`, kind scoop): a round
## tub with goldfish swimming slow loops in it and the farmer's paper scoop held still over the
## water at SPOT. Each press dips the scoop: a fish right under it comes up clean, one at the
## scoop's rim comes up with a struggle, and an empty dip only splashes. Every dip wets the paper
## (`wear` per grade, from `paper`); when it is used up the paper tears and the go is over, the
## fish on it slipping back. A scooped fish's place in the tub is filled from the keeper's bucket
## after `refill` seconds. The tub is a unit circle (radius 1, the middle at 0, 0). Pure timing
## and geometry like MochiPound; ScoopScreen draws it, Game.finish_game ranks the score (fish
## scooped). Format: README.md, Festivals.

const GRADES: Array[String] = ["clean", "edge", "splash"]
const SPOT := Vector2(0.45, 0.0)   # where the scoop hangs over the water (in tub radii)
const STAGES: Array[String] = ["go", "time"]   # what advance() calls, in order

var lead := 0.0
var seconds := 0.0
var time := 0.0
var full := 0.0                 # the paper's strength at the start
var paper := 0.0                # what is left of it
var torn := false
var score := 0                  # fish in the bowl
var counts := {"clean": 0, "edge": 0, "splash": 0}
var bowl: Array[int] = []       # the looks of the fish scooped, in order
var fish: Array[Dictionary] = []   # the tub: {r, drift, wob, wph, w, ph, look, back}
var last := ""                  # the last dip's grade (clean, edge, splash or tear)
var last_at := -99.0
var dipped_at := -99.0          # the last dip (the scoop is lifted out for `dip` seconds)
var _wear := {}
var _reach := {}
var _dip := 0.0
var _refill := 0.0
var _orbit: Array = [0.3, 0.8]
var _drift := 0.0
var _speed: Array = [0.6, 1.2]
var _looks := 1
var _rng := RandomNumberGenerator.new()
var _called := 0


## A go at game `g` with the tub's fish rolled from `seed` (the same seed swims the same way).
func _init(g: Dictionary, seed := 0) -> void:
	lead = float(g.get("lead", 0.0))
	seconds = float(g.seconds)
	full = float(g.paper)
	paper = full
	_wear = g.wear
	_reach = g.reach
	_dip = float(g.dip)
	var t: Dictionary = g.tub
	_refill = float(t.refill)
	_orbit = t.orbit
	_drift = float(t.drift)
	_speed = t.speed
	_looks = int(t.looks)
	_rng.seed = seed
	for i in int(t.fish):
		fish.append({})
		_roll(i, 0.0)


## Moves the clock on by `delta` seconds. Returns "go" when the count-in ends and "time" when
## the time runs out (not called after a tear: the go is over then already).
func advance(delta: float) -> Array[String]:
	var out: Array[String] = []
	time += delta
	for i in range(_called, STAGES.size()):
		if time < lead + [0.0, seconds][i]:
			break
		_called = i + 1
		if not (STAGES[i] == "time" and torn):
			out.append(STAGES[i])
	return out


## Dips may be made: after the count-in, before the time is up, the paper whole.
func running() -> bool:
	return time >= lead and time < lead + seconds and not torn


## The go is over: torn, or the time is up.
func done() -> bool:
	return torn or time >= lead + seconds


## Seconds left (all of them during the count-in, 0 once over).
func left() -> float:
	return clampf(lead + seconds - time, 0.0, seconds)


## Seconds of the count-in still to go (0 once on).
func to_go() -> float:
	return maxf(lead - time, 0.0)


## The scoop is out of the water after a dip (presses do nothing meanwhile).
func lifted() -> bool:
	return time - dipped_at < _dip


## Fish `i`'s place in the tub now (unit circle).
func pos(i: int) -> Vector2:
	var f := fish[i]
	var r := clampf(float(f.r) + float(f.drift) * sin(float(f.wob) * time + float(f.wph)), 0.1, 0.88)
	var a := float(f.ph) + float(f.w) * time
	return Vector2(cos(a), sin(a)) * r


## Fish `i` swims round clockwise (w > 0) or the other way; ScoopScreen turns its picture.
func heading(i: int) -> Vector2:
	var a := float(fish[i].ph) + float(fish[i].w) * time
	return Vector2(-sin(a), cos(a)) * signf(float(fish[i].w))


## Fish `i` is in the water (not scooped and waiting in the bucket).
func swimming(i: int) -> bool:
	return float(fish[i].back) <= time


## The fish nearest the scoop now (-1 for none in the water) and how far it is.
func nearest() -> Array:
	var best := -1
	var d := 99.0
	for i in fish.size():
		if swimming(i) and pos(i).distance_to(SPOT) < d:
			d = pos(i).distance_to(SPOT)
			best = i
	return [best, d]


## What a dip now would bring up: clean, edge or splash (by the nearest fish's distance).
func under() -> String:
	var d: float = nearest()[1]
	return "clean" if d <= float(_reach.clean) else "edge" if d <= float(_reach.edge) else "splash"


## A dip of the scoop now: "clean" / "edge" (a fish in the bowl), "splash" (nothing under it),
## "tear" (the paper gave way; a fish on it slips back), or "" (not running, or still lifted).
func press() -> String:
	if not running() or lifted():
		return ""
	dipped_at = time
	var n := nearest()
	var grade := under()
	paper -= float(_wear[grade])
	if paper <= 0.0:
		paper = 0.0
		torn = true
		grade = "tear"
	else:
		counts[grade] += 1
	if grade in ["clean", "edge"]:
		score += 1
		bowl.append(int(fish[n[0]].look))
		_roll(n[0], time + _refill)
	last = grade
	last_at = time
	return grade


## The paper left, 0 (torn) to 1 (fresh).
func strength() -> float:
	return paper / full if full > 0.0 else 0.0


## A fresh fish for place `i` in the tub, in the water from `back` on.
func _roll(i: int, back: float) -> void:
	fish[i] = {
		"r": _rng.randf_range(float(_orbit[0]), float(_orbit[1])),
		"drift": _rng.randf_range(0.0, _drift),
		"wob": _rng.randf_range(0.4, 1.1),
		"wph": _rng.randf_range(0.0, TAU),
		"w": _rng.randf_range(float(_speed[0]), float(_speed[1])) * (1.0 if _rng.randf() < 0.5 else -1.0),
		"ph": _rng.randf_range(0.0, TAU),
		"look": _rng.randi_range(0, _looks - 1),
		"back": back,
	}
