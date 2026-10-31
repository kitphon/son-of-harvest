class_name FarmerAnim
extends RefCounted
## Picks the farmer's sprite frame from where they face, whether they move or run, and time.
## Front image for Down / Right, back for Up / Left; Right and Up are the mirror images.

const WALK_FPS := 8.0     # 4 frames = 0.5 s per two steps; at 60 px/s a step is ~1 cell
const RUN_FPS := 12.0     # 0.33 s per two steps at 100 px/s

var pose := "idle"
var time := 0.0


## Advance by `delta` seconds. A new pose starts on its first step frame, so a key press
## shows a lifted foot at once.
func step(delta: float, moving: bool, running: bool) -> void:
	var p := "idle" if not moving else ("run" if running else "walk")
	if p != pose:
		pose = p
		time = 1.0 / _fps() if moving else 0.0
	elif moving:
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
	return RUN_FPS if pose == "run" else WALK_FPS
