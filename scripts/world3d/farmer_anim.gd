class_name FarmerAnim
extends RefCounted
## Picks the farmer's sprite frame from where they face, whether they move or run, and time.
## Front image for Down / Right, back for Up / Left; Right and Up are the mirror images.

const WALK_FPS := 8.0     # 4 frames = 0.5 s per two steps; at 60 px/s a step is ~1 cell
const RUN_FPS := 12.0     # 0.33 s per two steps at 100 px/s
const TIRED_WALK_FPS := 6.0   # slower, dragging steps (the exhausted farmer is slower too)
const TIRED_IDLE_FPS := 1.5   # one slow breath in, one out

var pose := "idle"
var time := 0.0


## Advance by `delta` seconds. A new pose starts on its first step frame, so a key press
## shows a lifted foot at once. `tired` (Game.body_state() not "fine") swaps idle / walk for
## the tired poses; a tired farmer who can still run runs normally.
func step(delta: float, moving: bool, running: bool, tired := false) -> void:
	var p := "idle" if not moving else ("run" if running else "walk")
	if tired and p != "run":
		p = "tired_" + p
	if p != pose:
		pose = p
		time = 1.0 / _fps() if moving else 0.0
	else:
		time += delta


func frame() -> int:
	if pose == "idle":
		return 0
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
		"tired_walk":
			return TIRED_WALK_FPS
		"tired_idle":
			return TIRED_IDLE_FPS
	return WALK_FPS
