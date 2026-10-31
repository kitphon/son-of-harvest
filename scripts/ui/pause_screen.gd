class_name PauseScreen
extends CanvasLayer
## The pause menu over the field: a wood box with a paper page inside, in our pixel font.
## Esc (or a pad's Start) opens it; arrows or W / S move, Enter / Space choose, left / right
## change a setting, Esc goes back; the mouse points and clicks. While it is open Game is
## paused (no time passes, the farmer stands still); weather particles keep falling.
## The pages and choices are PauseMenu. `-- --pause` (or `--pause=settings`) opens it at
## the start, for screenshots.

const TITLE_SCENE := "res://scenes/title.tscn"
const WIDTH := 150
const ROW_H := 13
const TOP := 17             # the heading strip on the wood
const PAPER := Color("f6ead0")

var menu: PauseMenu
var _open := false
var _dim: ColorRect
var _wood: NinePatchRect
var _paper: NinePatchRect
var _heading: Label
var _rows: Array[Label] = []
var _mark: Label
var _note: Label


func _ready() -> void:
	layer = 10   # over the HUD
	_dim = ColorRect.new()
	_dim.color = Color(0.1, 0.07, 0.04, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP   # no clicks reach the field
	add_child(_dim)
	_wood = _box(_dim, "wood")
	_heading = _label(_wood, Vector2i(9, 5), PAPER)
	_paper = _box(_wood, "paper")
	_paper.position = Vector2(4, TOP)
	_mark = _label(_paper, Vector2i(6, 5), PlaceholderArt.UI_SEAL)
	_mark.text = ">"
	_note = _label(_paper, Vector2i(9, 0), Hud.INK_SOFT)
	_dim.visible = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pause"):
			open.call_deferred(arg.trim_prefix("--pause").trim_prefix("="))


func _exit_tree() -> void:
	if _open:   # e.g. the scene changes with the menu open
		_open = false
		Game.unpause()


func is_open() -> bool:
	return _open


func open(page := "") -> void:
	if _open:
		return
	_open = true
	Game.pause()
	menu = PauseMenu.new(Game.settings)
	if page in PauseMenu.HEADINGS:
		menu.open(page)
	_note.text = ""
	_dim.visible = true
	_build()


func close() -> void:
	if not _open:
		return
	_open = false
	_dim.visible = false
	Game.unpause()


# --- drawing ------------------------------------------------------------------

## Lays out the page: the box grows with the rows and sits in the middle of the screen.
func _build() -> void:
	for r in _rows:
		r.queue_free()
	_rows.clear()
	_heading.text = menu.heading()
	for i in menu.list.items.size():
		var item: String = menu.list.items[i]
		var row := _label(_paper, Vector2i(15, 5 + i * ROW_H))
		row.size = Vector2(WIDTH - 8 - 19, ROW_H)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(func(): if menu.list.point(item): _refresh())
		row.gui_input.connect(_on_row_input.bind(item))
		_rows.append(row)
	var n := menu.list.items.size()
	_paper.size = Vector2(WIDTH - 8, 8 + n * ROW_H + ROW_H)   # one line kept for the note
	_note.position.y = 5 + n * ROW_H + 1
	_wood.size = Vector2(WIDTH, TOP + _paper.size.y + 4)
	var screen := get_viewport().get_visible_rect().size
	_wood.position = ((screen - _wood.size) / 2).floor()
	_refresh()


func _refresh() -> void:
	for i in _rows.size():
		_rows[i].text = menu.label(menu.list.items[i])
	_mark.position.y = 5 + menu.list.cursor * ROW_H


func _say(text: String) -> void:
	_note.text = text


func _label(parent: Control, pos: Vector2i, color := Hud.INK) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", PixelFont.font())
	l.add_theme_font_size_override("font_size", PixelFont.size())
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


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
	if not _open and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		open()


# While open, every key and pad button is taken here, so nothing reaches the farm or F5 / F9.
func _input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_do(menu.back())
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		menu.list.move(-1)
		_refresh()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		menu.list.move(1)
		_refresh()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_do(menu.adjust(-1))
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_do(menu.adjust(1))
	elif event.is_action_pressed("ui_accept"):
		_do(menu.choose())


func _on_row_input(event: InputEvent, item: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if menu.list.point(item):
			_do(menu.choose())


## Carries out what the menu asked for, then redraws the page (it may be a new one).
func _do(command: String) -> void:
	var page := menu.page
	match command:
		"resume":
			close()
			return
		"save":
			var err := SaveGame.write(Game)
			_say("Game saved" if err == "" else err)
		"setting":
			Game.apply_settings()
			var err := Game.settings.write()
			_say(err)
		"save_title":
			var err := SaveGame.write(Game)
			if err != "":
				_say(err)
				_refresh()
				return
			_to_title()
			return
		"title":
			_to_title()
			return
	if menu.page != page:
		_say("")
		_build()
	else:
		_refresh()


func _to_title() -> void:
	close()
	get_tree().change_scene_to_file(TITLE_SCENE)
