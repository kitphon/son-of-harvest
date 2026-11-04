extends Control
## The title screen: the game's name over a quiet morning valley and a paper-and-wood menu
## (New game / Continue / Quit). Arrows or W / S move, Enter / Space choose; the mouse
## points and clicks. The choices themselves live in TitleMenu. With `-- --demo` it goes
## straight to the field, so screenshots and smoke runs still start there.

const FIELD_SCENE := "res://scenes/main.tscn"
const TITLE := "Harvest Son"
const TITLE_SCALE := 3
const MENU := Rect2i(184, 168, 112, 52)
const ROW_H := 13
const INK_OFF := Color("b4a27e")

var menu: TitleMenu
var _rows: Array[Label] = []
var _mark: Label
var _note: Label
var _note_box: NinePatchRect

const NOTE_H := 18
const NOTE_PAD := 7
const WASH := Color(0.965, 0.918, 0.816, 0.6)   # the paper colour, a little see-through


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
	var shadow := _label(self, title_pos + Vector2i(TITLE_SCALE, TITLE_SCALE), Color("f6ead0"))
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
	if menu.why_no_continue != "" and FileAccess.file_exists(SaveGame.SLOT):
		_say("The saved game can't be loaded: " + menu.why_no_continue)
	_refresh()


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
	var b := NinePatchRect.new()
	b.texture = PlaceholderArt.tex("ui:frame:paper")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		b.set_patch_margin(side, Hud.NINE_MARGIN)
	b.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
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
	if menu == null or not event is InputEventKey:
		return
	get_viewport().set_input_as_handled()
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
			Game.new_game()
			_start()
		"continue":
			var err := SaveGame.read(Game)
			if err != "":   # the file changed since the menu was made
				menu.enabled.continue = false
				menu.move(1)
				_say("Could not load: " + err)
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
	get_tree().change_scene_to_file(FIELD_SCENE)
