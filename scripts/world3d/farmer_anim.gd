class_name FarmerAnim
extends RefCounted
## Picks the farmer's sprite frame from where they face, whether they move or run, and time.
## Front image for Down / Right, back for Up / Left; Right and Up are the mirror images.

const WALK_FPS := 8.0     # 4 frames = 0.5 s per two steps; at 60 px/s a step is ~1 cell
const RUN_FPS := 12.0     # 0.33 s per two steps at 100 px/s
const TIRED_WALK_FPS := 6.0   # slower, dragging steps (the exhausted farmer is slower too)
const TIRED_IDLE_FPS := 1.5   # one slow breath in, one out
const EAT_FPS := 5.0     # bite, chew, bite...: 1.2 s of eating (foods.json pose) = three bites
const DRINK_FPS := 2.0   # cup at the lips, tipped up: one sip a second

var pose := "idle"
var time := 0.0
var fast := false   # running: a hold walk steps at the run rate
var _swing_frame := 0   # on a tool swing (pose swing_<tool>): the frame Game.swing_frame() says


## Advance by `delta` seconds. A new pose starts on its first step frame, so a key press
## shows a lifted foot at once. `tired` (Game.body_state() not "fine") swaps idle / walk for
## the tired poses; a tired farmer who can still run runs normally. `holding` (an item
## overhead) wins over both: hold_idle / hold_walk, the walk stepping faster when running.
## `fishing` (Fishing.state while the line is out: "wait" / "bite") wins over everything.
## `eating` (Game.eat_pose: "eat" / "drink") wins over the tired poses; the farmer stands.
## `scooping` (Game.scoop_pose(): "scoop" / "scoop_lift" at the goldfish tub) wins over all.
## `swing` (Game.swing_pose(): "swing_<tool>" while a tool swing plays, else "") wins over the
## rest; `swing_frame` (Game.swing_frame()) is its frame: 0 the wind-up, 1 the blow.
func step(delta: float, moving: bool, running: bool, tired := false, holding := false, fishing := "", eating := "", scooping := "", swing := "", swing_frame := 0) -> void:
	var p := "idle" if not moving else ("run" if running else "walk")
	_swing_frame = swing_frame
	if scooping != "":
		p = scooping
	elif swing != "":
		p = swing
	elif fishing != "" and fishing != "idle":
		p = "fish_" + fishing
	elif holding:
		p = "hold_walk" if moving else "hold_idle"
	elif eating != "":
		p = eating
	elif tired and p != "run":
		p = "tired_" + p
	fast = running
	if p != pose:
		pose = p
		time = 1.0 / _fps() if moving else 0.0
	else:
		time += delta


func frame() -> int:
	if pose == "idle" or pose == "hold_idle" or pose == "fish_wait":
		return 0
	if pose.begins_with("swing_"):
		return _swing_frame
	return int(time * _fps()) % PlaceholderArt.farmer_frames(pose)


func key(facing: Vector2i) -> String:
	return "player:%s:%s:%d" % ["back" if is_back(facing) else "front", pose, frame()]


static func is_back(facing: Vector2i) -> bool:
	return facing == Vector2i.UP or facing == Vector2i.LEFT


static func is_mirrored(facing: Vector2i) -> bool:
	return facing == Vector2i.RIGHT or facing == Vector2i.UP


func _fps() -> float:
	match pose:
		"run":
			return RUN_FPS
		"hold_walk":
			return RUN_FPS if fast else WALK_FPS
		"tired_walk":
			return TIRED_WALK_FPS
		"tired_idle":
			return TIRED_IDLE_FPS
		"eat":
			return EAT_FPS
		"drink":
			return DRINK_FPS
	return WALK_FPS
