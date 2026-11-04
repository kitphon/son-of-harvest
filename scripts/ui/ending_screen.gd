class_name EndingScreen
extends CanvasLayer
## The village record over the room, as a paper scroll: a wooden roller top and bottom, washi
## between them. On open the scroll unrolls downwards (UNROLL seconds), then the rows come up
## one at a time: per category of data/ending.json its name, the number on the first day, an
## arrow, the number now, the gain since the last page and its ink-stamp stars; then the field
## rows (then and now, no stars); last the title the farmer earned with a red seal beside it.
## The year 3 ending and the yearly pages share it; the heading line says which. Opens on
## Game.ending_requested (the `ending` event step) and clears Game.ending_open when closed,
## so the event goes on. Enter / Space / E unrolls it and shows every row at once, then
## closes; a click does the same. `-- --ending` (or `--ending=year`) opens it at the start
## (with `--demo`: a demo run's numbers, against the untouched first-day field), for
## screenshots. Rules: Ending. Art: PlaceholderArt "ui:scroll:*".

const W := 360              # the paper's width
const KNOB := 6             # a roller's knob sticks out this far past the paper
const ROLLER := 10          # a roller's height
const TUCK := 3             # the paper runs this far under each roller
const MARGIN := 8           # text keeps this far from the paper's sides
const NAME_W := 100         # a row's name fits in this
const THEN_R := 176         # right edges of the first day, now and gain columns
const NOW_R := 240
const GAIN_R := 294
const ROW := 12
const LINE := 11
const STAR := 7             # one star stamp, square
const SEAL := 14            # the seal by the title, square
const ROLLED := 5           # paper showing between the rollers while rolled up
const UNROLL := 0.5         # seconds to unroll
const REVEAL := 0.18        # seconds between rows
const HINT := "Enter: close"

var record: Dictionary = {}
var full_h := 0             # the paper's height unrolled
var _open := false
var _unroll := 1.0          # 0 rolled up .. 1 open
var _shown := 0             # rows revealed
var _time := 0.0
var _dim: ColorRect
var _scroll: Control        # the rollers and the paper
var _paper: Control         # clips its contents to the unrolled part
var _top: TextureRect
var _bottom: TextureRect
var _total: Label
var _heading: Label
var _gain_head: Label
var _names: Array[Label] = []   # per row: the categories, then the field rows
var _thens: Array[Label] = []
var _arrows: Array[TextureRect] = []
var _values: Array[Label] = []
var _gains: Array[Label] = []
var _bands: Array[ColorRect] = []   # a faint wash behind every other row
var _stars: Array[Array] = []   # per row: its star stamps (none on field rows)
var _title: Label
var _seal: TextureRect
var _hint: Label


func _ready() -> void:
	layer = 10   # over the HUD
	_dim = ColorRect.new()
	_dim.color = Color(0.1, 0.07, 0.04, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_click)
	add_child(_dim)
	_scroll = Control.new()
	_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.add_child(_scroll)
	_paper = Control.new()
	_paper.clip_contents = true
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.position = Vector2(KNOB, ROLLER - TUCK)
	_scroll.add_child(_paper)
	_build()
	var roller := PlaceholderArt.tex("ui:scroll:roller_%d" % W)
	_top = _texture(_scroll, roller, Vector2.ZERO)
	_bottom = _texture(_scroll, roller, Vector2.ZERO)
	_scroll.size = Vector2(W + KNOB * 2, ROLLER * 2 - TUCK * 2 + full_h)
	_scroll.position = ((screen_size() - _scroll.size) / 2).floor()
	UiScale.apply_layer(self, Rect2(_scroll.position, _scroll.size), Game.ui_scale, screen_size())   # the UI size setting
	_roll()
	_dim.visible = false
	Game.ending_requested.connect(open)
	for arg in OS.get_cmdline_user_args():
		if arg == "--ending" or arg == "--ending=year":
			Game.show_ending.call_deferred("year" if arg.ends_with("year") else "ending")


func _exit_tree() -> void:
	if _open:
		_open = false
		Game.ending_open = false
		Game.unpause()


## The game's base screen; the window scales it by whole steps, so the scroll is laid out once.
static func screen_size() -> Vector2:
	return Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))


func is_open() -> bool:
	return _open


func unrolled() -> bool:
	return _unroll >= 1.0


func open(r: Dictionary) -> void:
	if _open:
		return
	record = r
	_open = true
	_unroll = 0.0
	_shown = 0
	_time = 0.0
	Game.pause()
	_dim.visible = true
	_roll()
	_refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	_dim.visible = false
	Game.ending_open = false
	Game.unpause()
	Game.changed.emit()


## The rows shown, in order: the categories, then the field.
func all_rows() -> Array:
	return record.get("rows", []) + record.get("field", [])


## Unrolled with every row at once, or (all shown) close.
func advance() -> void:
	var rows := all_rows()
	if not unrolled() or _shown < rows.size():
		_unroll = 1.0
		_roll()
		_shown = rows.size()
		_refresh()
		Sfx.play("menu_ok")
	else:
		close()


func _process(delta: float) -> void:
	if not _open:
		return
	if not unrolled():
		_unroll = minf(_unroll + delta / UNROLL, 1.0)
		_roll()
		return
	var count := all_rows().size()
	if _shown >= count:
		return
	_time += delta
	if _time >= REVEAL:
		_time = 0.0
		_shown += 1
		Sfx.play("menu_move" if _shown < count else "coins")
		_refresh()


# --- drawing ------------------------------------------------------------------

## The paper's height for how far it is unrolled (eased: fast, then settling), the bottom
## roller just under it. The top roller stays put.
func _roll() -> void:
	var t := 1.0 - pow(1.0 - _unroll, 2.0)
	var h := ROLLED + roundi((full_h - ROLLED) * t)
	_paper.size = Vector2(W, h)
	_bottom.position = Vector2(0, _paper.position.y + h - TUCK)


func _build() -> void:
	var cats: Array = Ending.data().get("categories", [])
	var count: int = cats.size()
	var most := 0
	for c in cats:
		most = maxi(most, c.steps.size())
	var washi := _texture(_paper, PlaceholderArt.tex("ui:scroll:washi"), Vector2.ZERO)
	washi.stretch_mode = TextureRect.STRETCH_TILE
	var heading := _label(_paper, Vector2i(MARGIN, TUCK + 2))
	heading.text = "Village Record"
	_total = _label(_paper, Vector2i(0, TUCK + 2), PlaceholderArt.UI_SEAL)
	_heading = _label(_paper, Vector2i(MARGIN, TUCK + 2 + LINE), Hud.INK_SOFT)
	_rule(TUCK + 4 + LINE * 2)
	var y := TUCK + 7 + LINE * 2
	for head in [["First day", THEN_R], ["Now", NOW_R], ["Gained", GAIN_R]]:
		var l := _label(_paper, Vector2i(head[1] - PixelFont.shown_width(head[0]), y), Hud.INK_SOFT)
		l.text = head[0]
		_gain_head = l
	y += LINE
	var arrow := PlaceholderArt.tex("ui:scroll:arrow")
	var stamp := PlaceholderArt.tex("ui:scroll:star_off")
	for i in count + Ending.data().get("field", []).size():
		if i == count:
			_rule(y + 2)
			y += 4
		var band := _rect(_paper, Vector2(MARGIN - 3, y + 1), Vector2(W - (MARGIN - 3) * 2, ROW),
			Color(0.78, 0.64, 0.4, 0.14))
		_bands.append(band)
		_names.append(_label(_paper, Vector2i(MARGIN, y + 2)))
		_thens.append(_label(_paper, Vector2i(0, y + 2), Hud.INK_SOFT))
		_arrows.append(_texture(_paper, arrow, Vector2(0, y + 4)))
		_values.append(_label(_paper, Vector2i(0, y + 2)))
		_gains.append(_label(_paper, Vector2i(0, y + 2), PlaceholderArt.UI_SEAL))
		var boxes: Array[TextureRect] = []
		for k in (most if i < count else 0):
			boxes.append(_texture(_paper, stamp, Vector2(W - MARGIN - (most - k) * (STAR + 2) + 2, y + 3)))
		_stars.append(boxes)
		y += ROW
	_rule(y + 2)
	_seal = _texture(_paper, PlaceholderArt.tex("ui:scroll:seal"), Vector2(0, y + 5))
	_title = _label(_paper, Vector2i(MARGIN, y + 7), PlaceholderArt.UI_SEAL)
	_hint = _label(_paper, Vector2i(W - MARGIN - PixelFont.shown_width(HINT), y + 7), Hud.INK_SOFT)
	_hint.text = HINT
	full_h = y + 5 + SEAL + 2 + TUCK
	washi.size = Vector2(W, full_h)
	for x in [0, W - 1]:   # the paper's cut edges, a shade darker
		_rect(_paper, Vector2(x, 0), Vector2(1, full_h), Color("dcc89c"))
	_rect(_paper, Vector2(0, TUCK), Vector2(W, 2), Color(0.35, 0.22, 0.1, 0.22))   # the top roller's shadow


func _refresh() -> void:
	var rows := all_rows()
	var all := _shown >= rows.size()
	_total.text = "%d of %d stars" % [record.get("stars", 0), record.get("max", 0)] if all else ""
	_total.position.x = W - MARGIN - PixelFont.shown_width(_total.text)
	_heading.text = "A page for the farmer" if record.get("page", "ending") == "ending" \
		else "The farmer's page, year %d" % int(record.get("year", 0))
	_gain_head.visible = not record.get("first", true)
	var on_tex := PlaceholderArt.tex("ui:scroll:star_on")
	var off_tex := PlaceholderArt.tex("ui:scroll:star_off")
	for i in _names.size():
		var on := i < rows.size() and i < _shown
		for l in [_names[i], _thens[i], _values[i], _gains[i]]:
			l.visible = on
		_bands[i].visible = on and i % 2 == 1
		_arrows[i].visible = false
		var row: Dictionary = rows[i] if i < rows.size() else {}
		if on:
			_names[i].text = String(row.name)
			_put(_thens[i], Ending.then_text(row), THEN_R)
			_put(_values[i], Ending.value_text(row), NOW_R)
			_put(_gains[i], Ending.gain_text(row), GAIN_R)
			var gap := int(_values[i].position.x) - THEN_R   # the arrow sits midway when there is room
			_arrows[i].position.x = THEN_R + (gap - 3) / 2
			_arrows[i].visible = gap >= 7
		for k in _stars[i].size():
			var b: TextureRect = _stars[i][k]
			b.visible = on and k < int(row.get("max", 0))
			b.texture = on_tex if k < int(row.get("stars", 0)) else off_tex
	_title.text = "Written as: %s" % String(record.get("title", "")) if all else ""
	_seal.position.x = MARGIN + PixelFont.shown_width(_title.text) + 5
	_seal.visible = all
	_hint.visible = all


func _put(l: Label, text: String, right: int) -> void:
	l.text = text
	l.position.x = right - PixelFont.shown_width(text)


func _rule(y: int) -> void:
	_rect(_paper, Vector2(MARGIN - 3, y), Vector2(W - (MARGIN - 3) * 2, 1), Hud.RULE)


func _rect(parent: Control, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.position = pos
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _label(parent: Control, pos: Vector2i, color := Hud.INK) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", PixelFont.font())
	l.add_theme_font_size_override("font_size", PixelFont.size())
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _texture(parent: Control, tex: Texture2D, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.position = pos
	t.size = tex.get_size()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


# --- input --------------------------------------------------------------------

# While open, every key and pad button is taken here, so nothing reaches the room.
func _input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") \
			or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		advance()


func _on_click(event: InputEvent) -> void:
	if _open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
