class_name Player
extends Node2D
## The farmer: walks (8 ways, faces 4), runs with Shift, uses the tool / interacts
## with the cell in front. Holding the use button charges a charging tool (standing still);
## letting go swings it. Drawn with the same FigureArt pictures as the 3D view (24 x 32, feet 2 px
## below the spot like the villagers' in VillagerView), picked by FarmerAnim.

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
var anim := FarmerAnim.new()   # which picture: pose and frame by what the farmer does
var figure: Sprite2D           # the farmer's picture (FigureArt via PlaceholderArt)
## The world's light on the farmer (FlatLight; main_2d sets it with the figure's self_modulate):
## what the farmer carries takes it too, the marks over the head do not.
var light := Color.WHITE
const FIGURE_TOP := 2 - PlaceholderArt.FIGURE_SIZE.y   # the picture's top row, from the spot (feet 2 px below)


func _ready() -> void:
	Game.changed.connect(queue_redraw)   # picking up / putting down while standing still
	# The contact shadow under the feet is drawn by the map view's FigureLayer (its Shadows), on the
	# ground under every figure; the farmer sorts with the other figures by the spot (the feet 2 px below).
	figure = Sprite2D.new()
	figure.show_behind_parent = true   # the target box, lantern, carried item and fishing marks draw over it
	figure.name = "Figure"
	figure.centered = false
	figure.offset = Vector2(-PlaceholderArt.FIGURE_SIZE.x / 2, FIGURE_TOP)
	figure.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	figure.texture = PlaceholderArt.tex(anim.key(facing))
	add_child(figure)


## The picture follows what the farmer does (walking, running, tired, eating, fishing, carrying,
## scooping goldfish);
## redrawn each frame as the pose steps.
func _process(delta: float) -> void:
	anim.step(delta, moving, running, Game.body_state() != "fine", Game.holding(), Game.fishing.state, Game.eat_pose, Game.scoop_pose())
	figure.texture = PlaceholderArt.tex(anim.key(facing))
	figure.flip_h = FarmerAnim.is_mirrored(facing)
	queue_redraw()


## Screen x offset of a picture pixel column `x` (its left edge) from the spot, mirrored with the figure.
func _px(x: float) -> float:
	return (x - PlaceholderArt.FIGURE_SIZE.x / 2.0) * (-1.0 if figure.flip_h else 1.0)


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
	if Game.eating():
		# Eating or drinking (Game.eat_pose): stand still, no tool, no interact until it ends.
		moving = false
		running = false
		queue_redraw()
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
	running = moving and Input.is_action_pressed("run") != Game.always_run and Game.can_run()
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
		# Blocked feet stop up to one step short of the edge (running: 1.7 px), so look a step ahead.
		var ahead := cell_of(position + Vector2(facing) * (FEET + Vector2.ONE * (1.0 + step.length())))
		if pushed and not Game.maps.door_at(ahead).is_empty():
			action.emit("enter", ahead - facing, facing, 0)
			return
		# Straight into a corner or a villager: slide round it when the way is clear a little to the side.
		if pushed and minf(absf(dir.x), absf(dir.y)) < 0.25 * maxf(absf(dir.x), absf(dir.y)):
			_slide(Vector2(facing) * speed * delta)
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
	if Game.in_greenhouse():   # the beds: their own grid, at the map's plots corner
		var corner := Game.maps.current().plots.position
		var out: Array[Vector2i] = []
		for c in Game.greenhouse.area_cells(cell_of(position) - corner, facing, rows):
			out.append(c + corner)
		return out
	return farm.area_cells(cell_of(position), facing, rows)


static func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))


func target_cell() -> Vector2i:
	return cell_of(position) + facing


## Moves by `d` unless a corner of the feet would end on a solid cell or the step goes into
## a villager; false when blocked. A solid cell the feet already stand on does not block (a
## crate set down or a villager's spot that came over the feet must never trap the farmer).
func _try_move(d: Vector2) -> bool:
	var np := position + d
	if not _free(position, np):
		return false
	position = np
	return true


const CORNERS: Array[Vector2] = [Vector2(-FEET.x, -FEET.y), Vector2(FEET.x, -FEET.y),
		Vector2(-FEET.x, FEET.y), Vector2(FEET.x, FEET.y)]
## How far to the side (pixels) the farmer slides round what blocks a straight walk: a wall's
## corner (half a cell), a villager (past block_reach, 0.7 cells).
const SLIDE_WALL := 8
const SLIDE_VILLAGER := 12


## May the feet go from `from` to `to`?
func _free(from: Vector2, to: Vector2) -> bool:
	if Game.villager_in_way(from, to):
		return false
	var under := {}
	for corner in CORNERS:
		under[cell_of(from + corner)] = true
	for corner in CORNERS:
		var c := cell_of(to + corner)
		if not under.has(c) and Game.maps.is_solid(c, farm):
			return false
	return true


## Blocked walking straight by `d`: when the way is clear up to a few pixels to one side, step
## that way (at most as far as `d`), so a gap a little off the feet or a villager in the path is
## walked round instead of stuck on. The nearer side wins. True when the farmer moved.
func _slide(d: Vector2) -> bool:
	var side := Vector2(absf(signf(d.y)), absf(signf(d.x)))   # across the walk
	var reach := SLIDE_VILLAGER if Game.villager_in_way(position, position + d) else SLIDE_WALL
	for k in range(1, reach + 1):
		for sgn in [1.0, -1.0]:
			var at: Vector2 = position + side * sgn * k
			if _free(position, at) and _free(at, at + d):
				return _try_move(side * sgn * minf(d.length(), k))
	return false


func _draw() -> void:
	# Target cell outline (on the farm, down the mine); while charging, every cell of the charge's area and the pips.
	for tc in (area_preview() if charging else [target_cell()]) if Game.maps.on_farm() or Game.maps.mine_floor != null or Game.in_greenhouse() else []:
		draw_rect(Rect2(Vector2(tc * T) - position, Vector2(T, T)), Color(1, 1, 1, 0.6), false, 1.0)
	if charging:
		var pips := PlaceholderArt.tex(PlaceholderArt.charge_key(charge, Game.max_charge(_charge_tool)))
		draw_texture(pips, Vector2(-pips.get_width() / 2.0, FIGURE_TOP + FigureArt.head_top(FigureArt.FARMER_LOOK) - 2 - pips.get_height()))
	if Game.maps.mine_floor != null:   # the lantern in hand down the mine, on the side away from the facing
		var lamp := PlaceholderArt.tex("mine:lantern")
		var at := PlaceholderArt.lantern_at(anim.pose, anim.frame(), FarmerAnim.is_back(facing))
		var lx := _px(at.x + 3.5)   # the loop's column
		draw_texture(lamp, Vector2(lx - 3.5, FIGURE_TOP + at.y))
	if Game.fishing.active():   # rod, line and bobber; a "!" over the head on a bite
		var bob := Vector2(Game.fishing.spot * T) + Vector2(8, 8) - position
		var bite := Game.fishing.state == "bite"
		var rt := PlaceholderArt.rod_tip(anim.pose, anim.frame())
		var tip := Vector2(_px(rt.x + 0.5), FIGURE_TOP + rt.y + 0.5)   # the rod itself is in the picture
		draw_line(tip, bob, Color(1, 1, 1, 0.7), 1.0)
		draw_circle(bob + Vector2(0, 1.5 if bite else sin(Game.fishing.time * 3.0)), 2.0, Color("d8402a"))
		if bite:
			var mark := PlaceholderArt.tex("fish_fx:alert")
			draw_texture(mark, Vector2(-mark.get_width() / 2.0, FIGURE_TOP + FigureArt.head_top(FigureArt.FARMER_LOOK) - 2 - mark.get_height()))
	if Game.holding():   # carried overhead, resting on the raised hands of the picture
		var item := PlaceholderArt.tex(Game.held_key())
		var row := PlaceholderArt.hold_row(anim.pose, anim.frame())
		draw_texture(item, Vector2(-item.get_width() / 2.0, FIGURE_TOP + row - item.get_height()), light)
