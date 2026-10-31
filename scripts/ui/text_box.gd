class_name TextBox
extends CanvasLayer
## The dialogue text box: a paper box across the bottom of the screen with the speaker's
## portrait in a wooden frame, a wooden name tag (with a villager's heart band after the
## name), the line written out letter by letter and,
## when the line asks, a list of choices above the box. E / Space / Enter (or a click) shows
## the whole line, then goes on; arrows or W / S and the mouse pick a choice. While it is open
## Game.dialogue_open holds the clock and the farmer. The stepping is DialogueRunner's; this
## only draws it. `-- --dialogue=<id>` (or `<id>@<line id>`) opens one at the start.

var runner: DialogueRunner
var _catch: Control          # takes clicks anywhere on screen while the box is open
var _box: NinePatchRect
var _portrait: NinePatchRect
var _face: TextureRect
var _name_tag: NinePatchRect
var _name: Label
var _heart: TextureRect      # on the name tag after a villager's name: their heart band
var _text: Label
var _more: TextureRect
var _choice_box: NinePatchRect
var _choice_rows: Array[Label] = []
var _choice_mark: Label
var _wrapped := ""
var _blink := 0.0


func _ready() -> void:
	layer = 10   # over the HUD
	_catch = Control.new()
	_catch.set_anchors_preset(Control.PRESET_FULL_RECT)
	_catch.mouse_filter = Control.MOUSE_FILTER_STOP
	_catch.gui_input.connect(_on_click)
	add_child(_catch)
	var r := TextBoxLayout.BOX
	_box = _frame(_catch, r, "paper")
	_portrait = _frame(_box, TextBoxLayout.PORTRAIT, "wood")
	_face = TextureRect.new()
	_face.position = Vector2(2, 2)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.add_child(_face)
	_name_tag = _frame(_catch, Rect2i(r.position + Vector2i(TextBoxLayout.TEXT_POS.x - 6, -TextBoxLayout.NAME_H + 4), Vector2i(40, TextBoxLayout.NAME_H)), "wood")
	_name = _label(_name_tag, Vector2i(6, 4), PlaceholderArt.UI_PAPER)
	_heart = TextureRect.new()
	_heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_tag.add_child(_heart)
	_text = _label(_box, TextBoxLayout.TEXT_POS)
	_more = TextureRect.new()
	_more.texture = PlaceholderArt.tex("ui:more")
	_more.position = Vector2(r.size.x - 13, r.size.y - 10)
	_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_more)
	_choice_box = _frame(_catch, Rect2i(), "paper")
	_choice_mark = _label(_choice_box, Vector2i(8, 5), PlaceholderArt.UI_SEAL)
	_choice_mark.text = ">"
	_close()
	Game.dialogue_requested.connect(open)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dialogue="):   # e.g. `-- --demo --dialogue=bin_note@ask`
			var spec := arg.trim_prefix("--dialogue=").split("@")
			open.call_deferred(spec[0], spec[1] if spec.size() > 1 else "")


## Opens dialogue `id` at line `at` ("" = its first line). Bad data is reported, not shown.
func open(id: String, at := "") -> void:
	var r := DialogueRunner.open(id, Game.flags, at)
	if r.error != "":
		push_error("Dialogue %s: %s" % [id, r.error])
		Game.message.emit("Can't read dialogue %s" % id)
		return
	if r.done():
		return
	r.set_speed(Game.text_speed)
	runner = r
	Game.dialogue_open = true
	_catch.visible = true
	_show_line()


func is_open() -> bool:
	return runner != null


func _close() -> void:
	runner = null
	Game.dialogue_open = false
	_catch.visible = false


func _process(delta: float) -> void:
	if runner == null:
		return
	var before := runner.shown
	runner.update(delta)
	if runner.shown != before:
		_refresh_text()
	_blink = fmod(_blink + delta, 0.8)
	_more.visible = runner.revealed() and not runner.line().has("choices") and _blink < 0.5


# Every key goes to the box while it is open, so nothing else (tools, F5 / F9) reacts.
func _input(event: InputEvent) -> void:
	if runner == null or not event is InputEventKey:
		return
	get_viewport().set_input_as_handled()
	if not event.pressed or event.echo:
		return
	if not runner.choices().is_empty():
		if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
			runner.move_choice(-1)
			_refresh_choices()
			return
		if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
			runner.move_choice(1)
			_refresh_choices()
			return
	if event.is_action_pressed("interact") or event.is_action_pressed("use_tool") or event.is_action_pressed("ui_accept"):
		_advance(-1)


func _on_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if runner != null and runner.choices().is_empty():
			_advance(-1)


func _on_choice_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance(i)


## A press (choice -1) or a picked choice: the runner steps, then the box shows where it is.
func _advance(i: int) -> void:
	var at := runner.index
	if runner.choices().is_empty():
		runner.press()
	elif not runner.pick(i):
		return
	if runner.done():
		_close()
	elif runner.index != at:
		_show_line()
	else:
		_refresh_text()


func _show_line() -> void:
	var l := runner.line()
	var speaker: String = l.get("speaker", "")
	_portrait.visible = speaker != ""
	_face.texture = PlaceholderArt.tex("face:%s:%s" % [speaker, l.get("face", "calm")]) if speaker != "" else null
	_name_tag.visible = speaker != ""
	_name.text = DialogueRunner.speakers().get(speaker, {}).get("name", "")
	_name_tag.size.x = PixelFont.width(_name.text) + 12
	var band := Game.heart_band(speaker)
	_heart.visible = band >= 0
	if band >= 0:
		_heart.texture = PlaceholderArt.tex("ui:heart:%d" % band)
		_heart.position = Vector2(_name_tag.size.x - 3, TextBoxLayout.HEART_Y)
		_name_tag.size.x += TextBoxLayout.HEART_W
	# Without a portrait (narration) the text starts at the left of the box.
	var x := TextBoxLayout.TEXT_POS.x if speaker != "" else TextBoxLayout.PORTRAIT.position.x + 2
	_text.position.x = x
	_wrapped = TextBoxLayout.wrapped(runner.text(), TextBoxLayout.TEXT_W + TextBoxLayout.TEXT_POS.x - x)
	_blink = 0.0
	_refresh_text()


func _refresh_text() -> void:
	_text.text = _wrapped.substr(0, runner.shown)
	_refresh_choices()


func _refresh_choices() -> void:
	var list := runner.choices()
	_choice_box.visible = not list.is_empty()
	if list.is_empty():
		return
	while _choice_rows.size() < list.size():
		var row := _label(_choice_box, Vector2i(16, 5 + _choice_rows.size() * TextBoxLayout.CHOICE_ROW))
		var i := _choice_rows.size()
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(func():
			if runner != null and i < runner.choices().size():
				runner.choice = i
				_refresh_choices())
		row.gui_input.connect(_on_choice_input.bind(i))
		_choice_rows.append(row)
	var w := 0
	for c in list:
		w = maxi(w, PixelFont.width(c.text))
	for i in _choice_rows.size():
		_choice_rows[i].visible = i < list.size()
		if i < list.size():
			_choice_rows[i].text = list[i].text
			_choice_rows[i].size = Vector2(w + 4, TextBoxLayout.CHOICE_ROW)
	var size := Vector2i(w + 24, list.size() * TextBoxLayout.CHOICE_ROW + 8)
	_choice_box.size = size
	_choice_box.position = Vector2(TextBoxLayout.BOX.end.x - size.x - 6, TextBoxLayout.BOX.position.y - size.y + 2)
	_choice_mark.position.y = 5 + runner.choice * TextBoxLayout.CHOICE_ROW


func _frame(parent: Control, r: Rect2i, kind: String) -> NinePatchRect:
	var b := NinePatchRect.new()
	b.texture = PlaceholderArt.tex("ui:frame:" + kind)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		b.set_patch_margin(side, Hud.NINE_MARGIN)
	b.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.position = r.position
	b.size = r.size
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b


func _label(parent: Control, pos: Vector2i, color := Hud.INK) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", PixelFont.font())
	l.add_theme_font_size_override("font_size", PixelFont.size())
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("line_spacing", int(PixelFont.data().line_gap))
	parent.add_child(l)
	return l
