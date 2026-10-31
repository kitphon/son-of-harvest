class_name InventoryScreen
extends CanvasLayer
## The rucksack and the storage chest over the field: a wood box with a paper page, a grid of
## slots per place in our pixel font. I (or a pad's Back) opens the rucksack; facing the chest
## by the house and pressing E opens the storage screen (Game.inventory_requested). Arrows or
## W A S D move the cursor, Enter / Space pick up and put down, E takes the thing under the
## cursor in hand, F eats it (food, crops, eggs, milk, fish), Esc / I close; the mouse points, left click picks / puts, right click holds.
## While it is open Game is paused, like the pause menu. The rules are InventoryMenu and
## Inventory. `-- --rucksack` (or `--rucksack=storage`) opens it at the start, for screenshots.

const PITCH := 20           # slot to slot
const LABEL_W := 46         # the place names left of the rows
const TOP := 17             # the heading strip on the wood
const LINE := 11
const PAPER := Color("f6ead0")
const HINT := "Enter: pick / put  E: hold  F: eat  Esc: close"

var menu: InventoryMenu
var _open := false
var _dim: ColorRect
var _wood: NinePatchRect
var _paper: NinePatchRect
var _heading: Label
var _parts: Array[Node] = []        # rebuilt per open
var _slots: Array[TextureRect] = [] # one per shown slot, rows in order
var _icons: Array[TextureRect] = []
var _counts: Array[Label] = []
var _plates: Array[ColorRect] = []   # paper under each count, so it reads over the icon
var _cursor: TextureRect
var _carry: TextureRect
var _carry_count: Label
var _info: Label
var _note: Label


func _ready() -> void:
	layer = 10   # over the HUD
	_dim = ColorRect.new()
	_dim.color = Color(0.1, 0.07, 0.04, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_wood = _box(_dim, "wood")
	_heading = _label(_wood, Vector2i(9, 5), PAPER)
	_paper = _box(_wood, "paper")
	_paper.position = Vector2(4, TOP)
	_dim.visible = false
	Game.inventory_requested.connect(open)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rucksack"):
			var mode := arg.trim_prefix("--rucksack").trim_prefix("=")
			open.call_deferred(mode if mode != "" else "rucksack")


func _exit_tree() -> void:
	if _open:
		_open = false
		Game.unpause()


func is_open() -> bool:
	return _open


## Opens the rucksack ("rucksack") or the chest ("storage"); not over another menu or a text box.
func open(mode := "rucksack") -> void:
	if _open or Game.paused():
		return
	_open = true
	Game.pause()
	menu = InventoryMenu.new(Game.inventory, mode, Game.tool_index)
	_dim.visible = true
	_build()
	_note.text = ""
	Sfx.play("menu_ok")


## Closes unless a carried stack can't be put down anywhere.
func close() -> void:
	if not _open:
		return
	var why := menu.close()
	if why != "":
		_note.text = why
		_refresh()
		return
	_open = false
	_dim.visible = false
	Game.unpause()
	Game.changed.emit()


# --- drawing ------------------------------------------------------------------

func _build() -> void:
	for p in _parts:
		p.queue_free()
	_parts.clear()
	_slots.clear()
	_icons.clear()
	_counts.clear()
	_plates.clear()
	_heading.text = menu.heading()
	var y := 5
	var last_place := ""
	for r in menu.rows.size():
		var place: String = menu.rows[r][0]
		if place != last_place:
			if last_place != "":
				y += 3
			var name := _label(_paper, Vector2i(6, y + 5))
			name.text = InventoryMenu.LABELS[place]
			_parts.append(name)
			last_place = place
		for c in menu.rows[r][2]:
			var slot := _icon(_paper, Vector2i(6 + LABEL_W + c * PITCH, y))
			slot.mouse_filter = Control.MOUSE_FILTER_STOP
			slot.gui_input.connect(_on_slot_input.bind(place, int(menu.rows[r][1]) + c))
			_parts.append(slot)
			_slots.append(slot)
			_icons.append(_icon(slot, Vector2i(2, 2)))
			var plate := ColorRect.new()
			plate.color = PAPER
			plate.position = Vector2(0, 9)
			plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(plate)
			_plates.append(plate)
			_counts.append(_label(slot, Vector2i(0, 7)))
		y += PITCH
	_info = _label(_paper, Vector2i(6, y + 3))
	_note = _label(_paper, Vector2i(6, y + 3 + LINE), PlaceholderArt.UI_SEAL)
	var hint := _label(_paper, Vector2i(6, y + 3 + LINE * 2), Hud.INK_SOFT)
	hint.text = HINT
	_parts.append_array([_info, _note, hint])
	_cursor = _icon(_paper, Vector2i.ZERO)
	_cursor.texture = PlaceholderArt.tex("ui:cursor")
	_carry = _icon(_paper, Vector2i.ZERO)
	_carry_count = _label(_carry, Vector2i(0, 3))
	_parts.append_array([_cursor, _carry])
	var cols := 0
	for r in menu.rows:
		cols = maxi(cols, r[2])
	_paper.size = Vector2(maxi(6 + LABEL_W + cols * PITCH + 4, PixelFont.width(HINT) + 12), y + 3 + LINE * 3 + 3)
	_wood.size = Vector2(_paper.size.x + 8, TOP + _paper.size.y + 4)
	var screen := get_viewport().get_visible_rect().size
	_wood.position = ((screen - _wood.size) / 2).floor()
	_refresh()


func _refresh() -> void:
	var inv := menu.inv
	var k := 0
	for r in menu.rows:
		for c in r[2]:
			var place: String = r[0]
			var i: int = r[1] + c
			var s := inv.slot(place, i)
			var in_hand := place == "tools" and i == menu.tool_slot
			_slots[k].texture = PlaceholderArt.tex("ui:slot:" + ("on" if in_hand else "off"))
			_icons[k].texture = null if s.is_empty() else PlaceholderArt.tex(PlaceholderArt.item_key(s.id, Game.current_seed(), Game.current_food()))
			var n := "" if s.is_empty() or int(s.n) < 2 else str(s.n)
			_counts[k].text = n
			_counts[k].position.x = 16 - PixelFont.width(n)
			_plates[k].visible = n != ""
			_plates[k].position.x = _counts[k].position.x - 1
			_plates[k].size = Vector2(PixelFont.width(n) + 1, 8)
			k += 1
	var at := _slot_of(menu.row, menu.col)
	_cursor.position = at.position - Vector2(2, 2)
	_carry.visible = not menu.carry.is_empty()
	if _carry.visible:
		_carry.texture = PlaceholderArt.tex(PlaceholderArt.item_key(menu.carry.id, Game.current_seed(), Game.current_food()))
		_carry.position = at.position + Vector2(8, -7)
		_carry_count.text = str(menu.carry.n) if int(menu.carry.n) > 1 else ""
		_carry_count.position.x = 15 - PixelFont.width(_carry_count.text)
	var id: String = menu.carry.get("id", menu.id_here())
	var count := int(menu.carry.get("n", menu.inv.slot(menu.place(), menu.index()).get("n", 0)))
	_info.text = "" if id == "" else Game.item_name(id) + (" x%d" % count if count > 1 else "")
	if id != "" and Game.TOOLS.has(id) and Game.tool_max_level(id) > 0:
		_info.text += "  Lv %d" % Game.tool_level(id)


func _slot_of(r: int, c: int) -> TextureRect:
	var k := 0
	for j in r:
		k += int(menu.rows[j][2])
	return _slots[k + c]


func _label(parent: Control, pos: Vector2i, color := Hud.INK) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", PixelFont.font())
	l.add_theme_font_size_override("font_size", PixelFont.size())
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _icon(parent: Control, pos: Vector2i) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func _box(parent: Control, kind: String) -> NinePatchRect:
	var b := NinePatchRect.new()
	b.texture = PlaceholderArt.tex("ui:frame:" + kind)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		b.set_patch_margin(side, Hud.NINE_MARGIN)
	b.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b


# --- input --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _open and not Game.paused() and event.is_action_pressed("rucksack"):
		get_viewport().set_input_as_handled()
		open("rucksack")


# While open, every key and pad button is taken here, so nothing reaches the farm.
func _input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("rucksack") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		return
	var step := Vector2i.ZERO
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		step = Vector2i.UP
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		step = Vector2i.DOWN
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		step = Vector2i.LEFT
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		step = Vector2i.RIGHT
	elif event.is_action_pressed("ui_accept"):
		_do(menu.choose())
	elif event.is_action_pressed("interact"):
		_do(menu.hold())
	elif event.is_action_pressed("eat"):
		var item := menu.id_here()
		_note.text = menu.eat(Game)
		Sfx.play(Game.item_sound(item) if menu.last_ok else "menu_ok")
	else:
		return
	if step != Vector2i.ZERO:
		menu.move(step.x, step.y)
		Sfx.play("menu_move")
	_refresh()


func _on_slot_input(event: InputEvent, place: String, i: int) -> void:
	if event is InputEventMouseMotion:
		if menu.point(place, i):
			_refresh()
	elif event is InputEventMouseButton and event.pressed and menu.point(place, i):
		if event.button_index == MOUSE_BUTTON_LEFT:
			_do(menu.choose())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_do(menu.hold())
		_refresh()


## Shows the menu's note and puts its tool in hand into Game (the HUD follows).
func _do(note: String) -> void:
	_note.text = note
	if menu.tool_slot != Game.tool_index:
		Game.select_tool(menu.tool_slot)
	else:
		Game.changed.emit()
	Sfx.play("menu_ok")
