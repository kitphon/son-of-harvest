extends Control
## The title screen: the game's name over a quiet morning valley and a paper-and-wood menu
## (New game / Continue / Quit). Arrows or W / S move, Enter / Space choose; the mouse
## points and clicks. The choices themselves live in TitleMenu. With `-- --demo` it goes
## straight to the field, so screenshots and smoke runs still start there.
##
## New game first opens the look step (LookMenu): the farmer's hair, hair color, skin and
## clothes, with the figure turning and walking beside the rows. Up / down pick a row, left /
## right change it, Enter on Start (or on the last row) begins, Esc goes back to the menu. Keys,
## pad and mouse all work. `-- --new-game` opens the step at once (screenshots).

const FIELD_SCENE := "res://scenes/main.tscn"
const TITLE := "Harvest Son"
const TITLE_SCALE := 3
const MENU := Rect2i(184, 168, 112, 52)
const ROW_H := 13
const INK_OFF := UiStyle.INK_OFF

var menu: TitleMenu
var _rows: Array[Label] = []
var _mark: Label
var _note: Label
var _note_box: NinePatchRect

const NOTE_H := 18
const NOTE_PAD := 7
const WASH := UiStyle.WASH

## The look step's box, its preview (the figure at PREVIEW_SCALE) and its columns.
const LOOK_BOX := Rect2i(84, 80, 312, 150)
const PREVIEW := Rect2i(12, 24, 84, 112)
const PREVIEW_SCALE := 3
const LOOK_ROW_Y := 30
const LOOK_ROW_H := 16
const LABEL_X := 118      # the row names
const LABEL_W := 72
const VALUE_X := 204      # "<" here, the value after it, ">" at VALUE_END
const VALUE_END := 296
const STEP_TIME := 0.18   # seconds per walk frame in the preview
const TURN_TIME := 2.4    # seconds before the preview turns to the next side

var start_scene := FIELD_SCENE   # the tests clear it, so starting doesn't load the field
var look: LookMenu               # the look step, while it is open
var _look_box: NinePatchRect
var _look_rows: Array[Label] = []
var _look_values: Array[Label] = []
var _look_arrows: Array[Label] = []
var _look_mark: Label
var _preview: TextureRect
var _preview_t := 0.0
var _menu_nodes: Array[Control] = []   # the title menu's box, hidden while the look step is up


func _ready() -> void:
	Game.clock_running = false   # no time passes on the title screen
	if "--demo" in OS.get_cmdline_user_args():
		_start.call_deferred()
		return
	menu = TitleMenu.make(Game)

	var bg := TextureRect.new()
	bg.texture = PlaceholderArt.tex("title:bg")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title_w := PixelFont.width(TITLE) * TITLE_SCALE
	var title_pos := Vector2i((PlaceholderArt.TITLE_SIZE.x - title_w) / 2, 34)
	# A soft paper wash behind the name and its brush stroke: the sky and hills still show
	# through, but the letters no longer sit straight on the picture (FEEDBACK item 7).
	_wash(Rect2i(title_pos.x - 10, title_pos.y - 6, title_w + 20, 42))
	var shadow := _label(self, title_pos + Vector2i(TITLE_SCALE, TITLE_SCALE), UiStyle.PAPER_TEXT)
	shadow.text = TITLE
	shadow.scale = Vector2.ONE * TITLE_SCALE
	var title := _label(self, title_pos, Hud.INK)
	title.text = TITLE
	title.scale = Vector2.ONE * TITLE_SCALE
	var rule := ColorRect.new()   # a vermilion stroke under the name, like a brush mark
	rule.color = PlaceholderArt.UI_SEAL
	rule.position = Vector2(title_pos.x + title_w / 2 - 30, title_pos.y + 30)
	rule.size = Vector2(60, 2)
	add_child(rule)

	var box := _box(MENU)
	for i in TitleMenu.ITEMS.size():
		var item: String = TitleMenu.ITEMS[i]
		var row := _label(box, Vector2i(18, 5 + i * ROW_H))
		row.text = TitleMenu.LABELS[item]
		row.size = Vector2(MENU.size.x - 22, ROW_H)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(func(): if menu.point(item): _refresh())
		row.gui_input.connect(_on_row_input.bind(item))
		_rows.append(row)
	_mark = _label(box, Vector2i(9, 5), PlaceholderArt.UI_SEAL)
	_mark.text = ">"
	# The note under the menu sits on the rice rows, so it gets its own paper strip.
	_note_box = _box(Rect2i(0, MENU.end.y + 4, 16, NOTE_H))
	_note_box.visible = false
	_note = _label(_note_box, Vector2i(NOTE_PAD, 4), Hud.INK)
	_menu_nodes = [box]
	_build_look()
	if menu.why_no_continue != "" and FileAccess.file_exists(SaveGame.SLOT):
		_say("The saved game can't be loaded: %s." % menu.why_no_continue)
	elif menu.enabled.continue and SaveGame.backup_note() != "":
		_say(SaveGame.backup_note())
	_refresh()
	if "--new-game" in OS.get_cmdline_user_args():
		open_look()


func _label(parent: Control, pos: Vector2i, color := Hud.INK) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", PixelFont.font())
	l.add_theme_font_size_override("font_size", PixelFont.size())
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


## A see-through paper panel with soft corners, behind text laid over the picture.
func _wash(r: Rect2i) -> Panel:
	var p := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = WASH
	style.set_corner_radius_all(4)
	p.add_theme_stylebox_override("panel", style)
	p.position = r.position
	p.size = r.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	return p


func _box(r: Rect2i) -> NinePatchRect:
	var b := UiStyle.panel(null, "paper")
	b.position = r.position
	b.size = r.size
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(b)
	return b


func _refresh() -> void:
	for i in _rows.size():
		var item: String = TitleMenu.ITEMS[i]
		_rows[i].add_theme_color_override("font_color", Hud.INK if menu.enabled[item] else INK_OFF)
	_mark.position.y = 5 + menu.cursor * ROW_H


# Keys are taken here, before Game's F5 / F9, so nothing saves or loads on the title screen.
func _input(event: InputEvent) -> void:
	if menu == null or not (event is InputEventKey or event is InputEventJoypadButton
			or event is InputEventJoypadMotion or event is InputEventAction):
		return
	get_viewport().set_input_as_handled()
	if look != null:
		_look_input(event)
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		menu.move(-1)
		Sfx.play("menu_move")
		_refresh()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		menu.move(1)
		Sfx.play("menu_move")
		_refresh()
	elif event.is_action_pressed("ui_accept"):
		_do(menu.choose())


func _on_row_input(event: InputEvent, item: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if menu.point(item):
			_refresh()
			_do(menu.choose())


func _do(item: String) -> void:
	Sfx.play("menu_ok")
	match item:
		"new":
			open_look()
		"continue":
			var err := SaveGame.read(Game)
			if err != "":   # the file changed since the menu was made
				menu.enabled.continue = false
				menu.move(1)
				_say("Could not load: %s." % err)
				return
			_start()
		"quit":
			get_tree().quit()


func _say(text: String) -> void:
	_note.text = text
	var w := PixelFont.shown_width(text) + NOTE_PAD * 2
	_note_box.size = Vector2(w, NOTE_H)
	_note_box.position.x = (PlaceholderArt.TITLE_SIZE.x - w) / 2
	_note_box.visible = true
	_refresh()


func _start() -> void:
	Game.clock_running = true
	if start_scene != "":
		get_tree().change_scene_to_file(start_scene)


# --- the look step ---------------------------------------------------------------------------

func _build_look() -> void:
	_look_box = _box(LOOK_BOX)
	_look_box.visible = false
	var head := _label(_look_box, Vector2i(12, 7))
	head.text = "Your farmer"
	head.size = Vector2(LOOK_BOX.size.x - 24, ROW_H)
	var frame := UiStyle.panel_at(_look_box, "wood", PREVIEW)
	var paper := UiStyle.panel_at(frame, "paper", Rect2i(3, 3, PREVIEW.size.x - 6, PREVIEW.size.y - 6))
	_preview = TextureRect.new()
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.stretch_mode = TextureRect.STRETCH_SCALE
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.size = Vector2(FigureArt.W, FigureArt.H) * PREVIEW_SCALE
	_preview.position = ((Vector2(paper.size) - _preview.size) / 2.0).floor()
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(_preview)
	for i in LookMenu.ITEMS.size():
		var item: String = LookMenu.ITEMS[i]
		var y := _look_row_y(i)
		var row := _label(_look_box, Vector2i(LABEL_X, y))
		row.text = LookMenu.LABELS[item]
		row.size = Vector2(LABEL_W, ROW_H)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(func(): if look != null and look.point(item): _look_refresh())
		row.gui_input.connect(_on_look_row_input.bind(item, 0))
		_look_rows.append(row)
		if not item in FarmerLooks.PARTS:
			continue
		var value := _label(_look_box, Vector2i(VALUE_X + 10, y))
		value.size = Vector2(VALUE_END - VALUE_X - 20, ROW_H)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_look_values.append(value)
		for side in [-1, 1]:
			var arrow := _label(_look_box, Vector2i(VALUE_X if side < 0 else VALUE_END - 6, y), UiStyle.INK_SOFT)
			arrow.text = "<" if side < 0 else ">"
			arrow.size = Vector2(6, ROW_H)
			arrow.mouse_filter = Control.MOUSE_FILTER_STOP
			arrow.gui_input.connect(_on_look_row_input.bind(item, side))
			_look_arrows.append(arrow)
	_look_mark = _label(_look_box, Vector2i(LABEL_X - 9, _look_row_y(0)), PlaceholderArt.UI_SEAL)
	_look_mark.text = ">"


## The row's top: the parts one under the other, Start a little apart below them.
func _look_row_y(i: int) -> int:
	return LOOK_ROW_Y + i * LOOK_ROW_H + (6 if LookMenu.ITEMS[i] == "start" else 0)


## Opens the look step from the farmer's look now (the default, or `--look=`'s).
func open_look() -> void:
	look = LookMenu.new(Game.farmer_look)
	_preview_t = 0.0
	_look_box.visible = true
	for n in _menu_nodes:
		n.visible = false
	_note_box.visible = false
	_look_refresh()


## Back to the title menu, nothing started.
func close_look() -> void:
	look = null
	_look_box.visible = false
	for n in _menu_nodes:
		n.visible = true
	_refresh()


## Starts the new game in the chosen look.
func confirm_look() -> void:
	var chosen := look.choice.duplicate()
	close_look()
	Game.new_game()
	Game.farmer_look = chosen
	_start()


func _look_refresh() -> void:
	if look == null:
		return
	var parts := FarmerLooks.PARTS
	for i in _look_values.size():
		_look_values[i].text = look.value_name(parts[i])
	for i in _look_rows.size():
		_look_rows[i].add_theme_color_override("font_color", PlaceholderArt.UI_SEAL if i == look.cursor else Hud.INK)
	_look_mark.position.y = _look_row_y(look.cursor)
	_show_preview()


## The figure in the preview: walking, turned to one of the four sides in turn.
func _show_preview() -> void:
	var side := int(_preview_t / TURN_TIME) % 4   # front, back, then both mirrored
	var frame := int(_preview_t / STEP_TIME) % FigureArt.frames("walk")
	_preview.texture = ImageTexture.create_from_image(FigureArt.draw(look.look(), side % 2 == 1, "walk", frame, true))
	_preview.flip_h = side >= 2


func _process(delta: float) -> void:
	if look == null:
		return
	var before := int(_preview_t / STEP_TIME)
	_preview_t += delta
	if int(_preview_t / STEP_TIME) != before:
		_show_preview()


func _look_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		look_do("up")
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		look_do("down")
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		look_do("left")
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		look_do("right")
	elif event.is_action_pressed("ui_accept"):
		look_do("accept")
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		look_do("cancel")


## One step on the look screen: up, down, left, right, accept (Start begins, a part's row goes
## to the next row) or cancel.
func look_do(what: String) -> void:
	match what:
		"up", "down":
			look.move(-1 if what == "up" else 1)
			Sfx.play("menu_move")
		"left", "right":
			if look.turn(-1 if what == "left" else 1):
				Sfx.play("menu_move")
		"accept":
			Sfx.play("menu_ok")
			if look.current() == "start":
				confirm_look()
				return
			look.move(1)
		"cancel":
			Sfx.play("menu_move")
			close_look()
			return
	_look_refresh()


func _on_look_row_input(event: InputEvent, item: String, side: int) -> void:
	if look == null or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	look.point(item)
	if side != 0:
		look_do("right" if side > 0 else "left")
	elif item == "start":
		look_do("accept")
	else:
		_look_refresh()
