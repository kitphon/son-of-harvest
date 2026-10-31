class_name Player
extends Node2D
## The farmer: walks (8 ways, faces 4), runs with Shift, uses the tool / interacts
## with the cell in front. Holding the use button charges a charging tool (standing still);
## letting go swings it. Drawn as a placeholder until there is sprite art.

## kind = "tool" or "interact"; from the farmer's cell towards `facing`, `charge` steps.
signal action(kind: String, origin: Vector2i, facing: Vector2i, charge: int)

const T := 16
const WALK_SPEED := 60.0
const RUN_SPEED := 100.0
const FEET := Vector2(5, 3)    # half size of the box that collides

var farm: FarmGrid
var facing := Vector2i.DOWN
var moving := false     # a direction is held (also when walking into a wall)
var running := false
var charging := false   # the use button is held with a charging tool
var charge := 0         # charge steps reached so far
var _charge_time := 0.0
var _charge_tool := ""
var _after_menu := false   # keys held from a menu do nothing until let go


func _ready() -> void:
	Game.changed.connect(queue_redraw)   # picking up / putting down while standing still


func _physics_process(delta: float) -> void:
	# A menu is open: stand still, and opening it drops a charge (as walking away would).
	if Game.paused():
		if charging:
			cancel_charge()
		moving = false
		running = false
		_after_menu = true
		return
	if _after_menu:
		# The Enter / Space that closed the menu must not swing the tool too.
		if Input.is_action_pressed("use_tool") or Input.is_action_pressed("interact"):
			return
		_after_menu = false
	if charging:
		_charge_step(delta)
		return
	if Game.fishing.active():
		# The line is out: stand still; either button reels in.
		moving = false
		running = false
		queue_redraw()
		if Input.is_action_just_pressed("use_tool") or Input.is_action_just_pressed("interact"):
			action.emit("tool", cell_of(position), facing, 0)
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	moving = dir != Vector2.ZERO
	running = moving and Input.is_action_pressed("run") and Game.can_run()
	if moving:
		if absf(dir.x) > absf(dir.y):
			facing = Vector2i(int(signf(dir.x)), 0)
		else:
			facing = Vector2i(0, int(signf(dir.y)))
		var speed := (RUN_SPEED if running else WALK_SPEED) * Game.speed_factor()
		var step := dir * speed * delta
		var moved_x := _try_move(Vector2(step.x, 0))   # one axis at a time, so walls slide
		var moved_y := _try_move(Vector2(0, step.y))
		Game.maps.pos = position
		Game.maps.facing = facing
		var cell := cell_of(position)
		Sfx.walk(step.length(), farm if Game.maps.on_farm() else null, cell, Game.maps.step_at(cell))
		queue_redraw()
		# Walking into a door (or off the map at an exit) goes through it.
		var pushed := not moved_x if facing.x != 0 else not moved_y
		var ahead := cell_of(position + Vector2(facing) * (FEET + Vector2.ONE))
		if pushed and not Game.maps.door_at(ahead).is_empty():
			action.emit("enter", ahead - facing, facing, 0)
			return
	if Input.is_action_just_pressed("use_tool"):
		# Hands full (an item overhead): the button sets it down, nothing charges.
		if Game.max_charge(Game.current_tool()) > 0 and not Game.holding():
			charging = true
			charge = 0
			_charge_time = 0.0
			_charge_tool = Game.current_tool()
			moving = false
			running = false
			queue_redraw()
		else:
			action.emit("tool", cell_of(position), facing, 0)
	if Input.is_action_just_pressed("interact"):
		action.emit("interact", cell_of(position), facing, 0)


## Held: the charge goes up every charge step. Let go: the swing. Switching tools drops it.
func _charge_step(delta: float) -> void:
	if Game.current_tool() != _charge_tool:
		cancel_charge()
	elif Input.is_action_pressed("use_tool"):
		_charge_time += delta
		var c := Game.charge_after(_charge_tool, _charge_time)
		if c != charge:
			charge = c
			queue_redraw()
	else:
		var c := charge
		cancel_charge()
		action.emit("tool", cell_of(position), facing, c)


func cancel_charge() -> void:
	charging = false
	charge = 0
	_charge_time = 0.0
	queue_redraw()


## The cells the tool in hand would work on now (the charge's area while charging).
func area_preview() -> Array[Vector2i]:
	var tool := Game.current_tool()
	if Game.max_charge(tool) == 0:
		return [target_cell()]
	var rows: Array = Game.charge_rule(tool, charge).area
	if Game.maps.mine_floor != null:
		return Game.maps.mine_floor.area_cells(cell_of(position), facing, rows)
	return farm.area_cells(cell_of(position), facing, rows)


static func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))


func target_cell() -> Vector2i:
	return cell_of(position) + facing


## Moves by `d` unless a corner of the feet would end on a solid cell; false when blocked.
func _try_move(d: Vector2) -> bool:
	var np := position + d
	for corner in [Vector2(-FEET.x, -FEET.y), Vector2(FEET.x, -FEET.y),
			Vector2(-FEET.x, FEET.y), Vector2(FEET.x, FEET.y)]:
		if Game.maps.is_solid(cell_of(np + corner), farm):
			return false
	position = np
	return true


func _draw() -> void:
	# Target cell outline (on the farm, down the mine); while charging, every cell of the charge's area and the pips.
	for tc in (area_preview() if charging else [target_cell()]) if Game.maps.on_farm() or Game.maps.mine_floor != null else []:
		draw_rect(Rect2(Vector2(tc * T) - position, Vector2(T, T)), Color(1, 1, 1, 0.6), false, 1.0)
	if charging:
		var pips := PlaceholderArt.tex(PlaceholderArt.charge_key(charge, Game.max_charge(_charge_tool)))
		draw_texture(pips, Vector2(-pips.get_width() / 2.0, -26))
	# Body, head and a dot for the facing.
	draw_circle(Vector2(0, 2), 5, Color(0, 0, 0, 0.25))
	draw_rect(Rect2(-4, -10, 8, 11), Color("3b6fd1"))
	draw_circle(Vector2(0, -13), 4.5, Color("f2c79b"))
	draw_rect(Rect2(-5, -18, 10, 3), Color("c8452c"))   # cap
	draw_circle(Vector2(facing) * 5 + Vector2(0, -6), 1.5, Color.WHITE)
	if Game.fishing.active():   # rod, line and bobber; a "!" over the head on a bite
		var bob := Vector2(Game.fishing.spot * T) + Vector2(8, 8) - position
		var bite := Game.fishing.state == "bite"
		var tip := Vector2(facing) * 10 + Vector2(0, -16)
		draw_line(Vector2(0, -6), tip, Color("6b4a2a"), 1.0)
		draw_line(tip, bob, Color(1, 1, 1, 0.7), 1.0)
		draw_circle(bob + Vector2(0, 1.5 if bite else sin(Game.fishing.time * 3.0)), 2.0, Color("d8402a"))
		if bite:
			var mark := PlaceholderArt.tex("fish_fx:alert")
			draw_texture(mark, Vector2(-mark.get_width() / 2.0, -22 - mark.get_height()))
	if Game.holding():   # carried overhead, arms up
		draw_rect(Rect2(-7, -19, 3, 9), Color("3b6fd1"))
		draw_rect(Rect2(4, -19, 3, 9), Color("3b6fd1"))
		var item := PlaceholderArt.tex(PlaceholderArt.world_item_key(Game.held))
		draw_texture(item, Vector2(-item.get_width() / 2.0, -19 - item.get_height()))
