class_name Player
extends Node2D
## The farmer: walks (8 ways, faces 4), runs with Shift, uses the tool / interacts
## with the cell in front. Drawn as a placeholder until there is sprite art.

signal action(kind: String, target: Vector2i)   # kind = "tool" or "interact"

const T := 16
const WALK_SPEED := 60.0
const RUN_SPEED := 100.0
const FEET := Vector2(5, 3)    # half size of the box that collides

var farm: FarmGrid
var facing := Vector2i.DOWN
var moving := false     # a direction is held (also when walking into a wall)
var running := false


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	moving = dir != Vector2.ZERO
	running = moving and Input.is_action_pressed("run")
	if moving:
		if absf(dir.x) > absf(dir.y):
			facing = Vector2i(int(signf(dir.x)), 0)
		else:
			facing = Vector2i(0, int(signf(dir.y)))
		var speed := RUN_SPEED if running else WALK_SPEED
		var step := dir * speed * delta
		_try_move(Vector2(step.x, 0))   # one axis at a time, so walls slide
		_try_move(Vector2(0, step.y))
		queue_redraw()
	if Input.is_action_just_pressed("use_tool"):
		action.emit("tool", target_cell())
	if Input.is_action_just_pressed("interact"):
		action.emit("interact", target_cell())


static func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))


func target_cell() -> Vector2i:
	return cell_of(position) + facing


func _try_move(d: Vector2) -> void:
	var np := position + d
	for corner in [Vector2(-FEET.x, -FEET.y), Vector2(FEET.x, -FEET.y),
			Vector2(-FEET.x, FEET.y), Vector2(FEET.x, FEET.y)]:
		if farm.is_solid(cell_of(np + corner)):
			return
	position = np


func _draw() -> void:
	# Target cell outline.
	var tc := target_cell()
	draw_rect(Rect2(Vector2(tc * T) - position, Vector2(T, T)), Color(1, 1, 1, 0.6), false, 1.0)
	# Body, head and a dot for the facing.
	draw_circle(Vector2(0, 2), 5, Color(0, 0, 0, 0.25))
	draw_rect(Rect2(-4, -10, 8, 11), Color("3b6fd1"))
	draw_circle(Vector2(0, -13), 4.5, Color("f2c79b"))
	draw_rect(Rect2(-5, -18, 10, 3), Color("c8452c"))   # cap
	draw_circle(Vector2(facing) * 5 + Vector2(0, -6), 1.5, Color.WHITE)
