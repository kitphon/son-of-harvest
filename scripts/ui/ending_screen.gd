class_name EndingScreen
extends CanvasLayer
## The village record over the room: a wood box with "Village Record" and the stars in all,
## a paper page with one row per category of data/ending.json (its name, the number measured
## and its stars, revealed one row at a time) and the title the farmer earned. Opens on
## Game.ending_requested (the ending event's `ending` step) and clears Game.ending_open when
## closed, so the event goes on. Enter / Space / E shows every row at once, then closes;
## a click does the same. `-- --ending` opens it at the start (with `--demo`: a demo run's
## numbers), for screenshots. Rules: Ending.

const W := 300              # the paper's width
const TOP := 17             # the heading strip on the wood
const ROW := 12
const LINE := 11
const STAR := 7             # one star box, square
const REVEAL := 0.18        # seconds between rows
const PAPER := Color("f6ead0")
const HINT := "Enter: close"

var record: Dictionary = {}
var _open := false
var _shown := 0             # rows revealed
var _time := 0.0
var _dim: ColorRect
var _wood: NinePatchRect
var _paper: NinePatchRect
var _total: Label
var _names: Array[Label] = []
var _values: Array[Label] = []
var _stars: Array[Array] = []   # per row: its star boxes
var _title: Label
var _hint: Label


func _ready() -> void:
	layer = 10   # over the HUD
	_dim = ColorRect.new()
	_dim.color = Color(0.1, 0.07, 0.04, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_click)
	add_child(_dim)
	_wood = _box(_dim, "wood")
	var heading := _label(_wood, Vector2i(9, 5), PAPER)
	heading.text = "Village Record"
	_total = _label(_wood, Vector2i(0, 5), PAPER)
	_paper = _box(_wood, "paper")
	_paper.position = Vector2(4, TOP)
	_build()
	_dim.visible = false
	Game.ending_requested.connect(open)
	if "--ending" in OS.get_cmdline_user_args():
		Game.show_ending.call_deferred()


func _exit_tree() -> void:
	if _open:
		_open = false
		Game.ending_open = false
		Game.unpause()


func is_open() -> bool:
	return _open


func open(r: Dictionary) -> void:
	if _open:
		return
	record = r
	_open = true
	_shown = 0
	_time = 0.0
	Game.pause()
	_dim.visible = true
	_refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	_dim.visible = false
	Game.ending_open = false
	Game.unpause()
	Game.changed.emit()


## Every row at once, or (all shown) close.
func advance() -> void:
	var rows: Array = record.get("rows", [])
	if _shown < rows.size():
		_shown = rows.size()
		_refresh()
		Sfx.play("menu_ok")
	else:
		close()


func _process(delta: float) -> void:
	if not _open or _shown >= record.get("rows", []).size():
		return
	_time += delta
	if _time >= REVEAL:
		_time = 0.0
		_shown += 1
		Sfx.play("menu_move" if _shown < record.rows.size() else "coins")
		_refresh()


# --- drawing ------------------------------------------------------------------

func _build() -> void:
	var count: int = Ending.data().get("categories", []).size()
	var most := 0
	for c in Ending.data().get("categories", []):
		most = maxi(most, c.steps.size())
	var title := _label(_paper, Vector2i(6, 5))
	title.text = "A page for the farmer"
	_rule(16)
	var y := 20
	for i in count:
		_names.append(_label(_paper, Vector2i(8, y + 2)))
		_values.append(_label(_paper, Vector2i(0, y + 2)))
		var boxes: Array[ColorRect] = []
		for k in most:
			var b := ColorRect.new()
			b.size = Vector2(STAR, STAR)
			b.position = Vector2(W - 8 - (most - k) * (STAR + 2), y + 3)
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_paper.add_child(b)
			boxes.append(b)
		_stars.append(boxes)
		y += ROW
	_rule(y + 2)
	_title = _label(_paper, Vector2i(6, y + 6), PlaceholderArt.UI_SEAL)
	_hint = _label(_paper, Vector2i(6, y + 6 + LINE), Hud.INK_SOFT)
	_hint.text = HINT
	_paper.size = Vector2(W, y + 6 + LINE * 2 + 3)
	_wood.size = Vector2(W + 8, TOP + _paper.size.y + 4)
	var screen := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	_wood.position = ((screen - _wood.size) / 2).floor()


func _refresh() -> void:
	var rows: Array = record.get("rows", [])
	var all := _shown >= rows.size()
	_total.text = "%d of %d stars" % [record.get("stars", 0), record.get("max", 0)] if all else ""
	_total.position.x = _wood.size.x - 9 - PixelFont.width(_total.text)
	for i in _names.size():
		var on := i < rows.size() and i < _shown
		_names[i].visible = on
		_values[i].visible = on
		var row: Dictionary = rows[i] if i < rows.size() else {}
		if on:
			_names[i].text = String(row.name)
			_values[i].text = Ending.value_text(row)
			_values[i].position.x = W - 8 - _stars[i].size() * (STAR + 2) - 6 - PixelFont.width(_values[i].text)
		for k in _stars[i].size():
			var b: ColorRect = _stars[i][k]
			b.visible = on and k < int(row.get("max", 0))
			b.color = PlaceholderArt.UI_SEAL if k < int(row.get("stars", 0)) else Hud.RULE
	_title.text = "Written as: " + String(record.get("title", "")) if all else ""
	_hint.visible = all


func _rule(y: int) -> void:
	var rule := ColorRect.new()
	rule.color = Hud.RULE
	rule.position = Vector2(5, y)
	rule.size = Vector2(W - 10, 1)
	_paper.add_child(rule)


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
