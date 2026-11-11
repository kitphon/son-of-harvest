class_name PauseScreen
extends CanvasLayer
## The pause menu over the field: a wood box with a paper page inside, in our pixel font.
## Esc (or a pad's Start) opens it; arrows or W / S move, Enter / Space choose, left / right
## change a setting, Esc goes back; the mouse points and clicks. While it is open Game is
## paused (no time passes, the farmer stands still); weather particles keep falling.
## The pages and choices are PauseMenu. The controls page is wider, shows each action's key
## slots in two columns and its pad button in a third, and scrolls; while it waits for a key
## every key goes to it (while it waits for a pad button, every pad button, trigger and
## right-stick push).
## `-- --pause` (or `--pause=settings`, `--pause=controls`, `--pause=fishlog`, `--pause=shipped`) opens it at the start, for
## screenshots.

const TITLE_SCENE := "res://scenes/title.tscn"
const WIDTH := 150
const ROW_H := 13
const TOP := 17             # the heading strip on the wood
const PAPER := UiStyle.PAPER_TEXT
const NOTCH := Vector2(3, 5)   # one slider step, px; a pixel apart
const CONTROLS_WIDTH := 300
const FISHLOG_WIDTH := 310   # the fish log: icon, name, count, and three detail lines under the list
const FISH_LINES := 3      # detail lines under the fish log (where, season, hours)
const ICON_W := 16         # a fish icon (14 px) and its gap, left of the name
const SLOT_X := 118         # the first key column on the controls page, px from the paper's left
const SLOT_STEP := 58       # from one key column to the next
const VISIBLE := 15         # rows shown at once; a longer page scrolls

var menu: PauseMenu
var _open := false
var _dim: ColorRect
var _wood: NinePatchRect
var _paper: NinePatchRect
var _heading: Label
var _rows: Array[Label] = []    # the rows on screen; row i shows item _top + i
var _slots: Array = []          # per row on the controls page: its key slot Labels
var _top := 0                   # the first item shown
var _bar: ColorRect             # the scroll bar on a page that scrolls
var _icons: Array[TextureRect] = []   # per row on the fish log: the fish icon
var _counts: Array[Label] = []        # per row on the fish log: how many were caught
var _details: Array[Label] = []       # the lines under the fish log
var _notches: Dictionary = {}   # setting -> its slider's ColorRects
var _mark: Label
var _note: Label


func _ready() -> void:
	layer = 10   # over the HUD
	_dim = ColorRect.new()
	_dim.color = UiStyle.DIM
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
	_bar = ColorRect.new()
	_bar.color = Hud.INK_SOFT
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(_bar)
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
	menu = PauseMenu.new(Game.settings, Game.fish_data, Game.fish_caught, Game.shippable_rows(), Game.shipped)
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
	_slots.clear()
	_icons.clear()
	_counts.clear()
	_details.clear()
	_notches.clear()
	_top = 0
	_heading.text = menu.heading()
	var fish := menu.page == "fishlog"
	var iconed := fish or menu.page == "shipped"   # rows with an icon and a count
	var width := FISHLOG_WIDTH if iconed else (CONTROLS_WIDTH if menu.page == "controls" else WIDTH)
	var screen := get_viewport().get_visible_rect().size
	var n := mini(menu.list.items.size(), visible_rows(Game.ui_scale, screen.y, FISH_LINES if fish else 0))
	for i in n:
		var item: String = menu.list.items[i]
		var row := _label(_paper, Vector2i(15 + (ICON_W if iconed else 0), 5 + i * ROW_H))
		row.size = Vector2(width - 8 - 19 - (ICON_W if iconed else 0), ROW_H)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(_on_row_hover.bind(i, -1))
		row.gui_input.connect(_on_row_input.bind(i, -1))
		_rows.append(row)
		if iconed:
			var icon := TextureRect.new()
			icon.position = Vector2(-ICON_W, -1)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
			_icons.append(icon)
			var count := _label(row, Vector2i(0, 0))
			count.size = row.size
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_counts.append(count)
		if menu.page == "controls":
			var keys: Array[Label] = []
			for k in menu.slot_count():
				var key := _label(row, Vector2i(SLOT_X - 15 + k * SLOT_STEP, 0))
				key.size = Vector2(SLOT_STEP - 4, ROW_H)
				key.mouse_filter = Control.MOUSE_FILTER_STOP
				key.mouse_entered.connect(_on_row_hover.bind(i, k))
				key.gui_input.connect(_on_row_input.bind(i, k))
				keys.append(key)
			_slots.append(keys)
		var steps := menu.slider(item).y
		if steps > 0:
			var notches: Array[ColorRect] = []
			for k in steps:
				var c := ColorRect.new()
				c.size = NOTCH
				c.position = Vector2(row.size.x - 3 - (steps - k) * (NOTCH.x + 1), 3).floor()
				c.mouse_filter = Control.MOUSE_FILTER_IGNORE
				row.add_child(c)
				notches.append(c)
			_notches[item] = notches
	var lines := 1 + (FISH_LINES if fish else 0)   # the note line, then the fish log's details
	_paper.size = Vector2(width - 8, 8 + n * ROW_H + lines * ROW_H)
	_note.position.y = 5 + n * ROW_H + 1
	if fish:
		for k in FISH_LINES:
			var d := _label(_paper, Vector2i(9, 5 + (n + 1 + k) * ROW_H + 1), Hud.INK)
			d.size = Vector2(width - 8 - 18, ROW_H)
			d.clip_text = true
			_details.append(d)
	_wood.size = Vector2(width, TOP + _paper.size.y + 4)
	_bar.visible = menu.list.items.size() > n
	_bar.position.x = _paper.size.x - 6
	_wood.position = ((screen - _wood.size) / 2).floor()
	UiScale.apply_layer(self, Rect2(_wood.position, _wood.size), Game.ui_scale, screen)
	_refresh()


## Rows shown at once at UI size `ui_scale` on a screen `screen_h` high: VISIBLE, fewer when
## the box grown by the UI size would not fit (a long page then scrolls).
## `extra` lines are kept under the list (the fish log's details).
static func visible_rows(ui_scale: float, screen_h: float, extra := 0) -> int:
	var room := floori((screen_h / maxf(ui_scale, 1.0) - TOP - 4 - 8 - ROW_H - extra * ROW_H) / ROW_H)
	return clampi(room, 1, VISIBLE)


func _refresh() -> void:
	var items := menu.list.items
	var n := _rows.size()
	_top = clampi(_top, menu.list.cursor - n + 1, menu.list.cursor)   # the cursor stays in view
	_top = clampi(_top, 0, items.size() - n)
	for i in n:
		var item: String = items[_top + i]
		_rows[i].text = menu.label(item)
		if i < _slots.size():
			for k in _slots[i].size():
				var key: Label = _slots[i][k]
				key.text = menu.slot_text(item, k)
				var on: bool = _top + i == menu.list.cursor and k == menu.slot
				key.add_theme_color_override("font_color", PlaceholderArt.UI_SEAL if on else (Hud.INK_SOFT if key.text == "-" else Hud.INK))
	if menu.page == "shipped":
		for i in n:
			var item: String = items[_top + i]
			_counts[i].text = menu.count_text(item)
			_icons[i].texture = PlaceholderArt.tex(PlaceholderArt.item_key(item)) if menu.is_shipped_row(item) else null
			_icons[i].modulate = Color.WHITE if menu.shipped_count(item) > 0 else Color.BLACK
	if menu.page == "fishlog":
		var shown: Array[String] = ["", "", ""]
		for i in n:
			var item: String = items[_top + i]
			_counts[i].text = menu.count_text(item)
			_icons[i].texture = PlaceholderArt.tex("ui:fish:" + item) if menu.is_fish(item) else null
			_icons[i].modulate = Color.WHITE if menu.count(item) > 0 else Color.BLACK   # a silhouette until caught
		shown = menu.fish_details(items[menu.list.cursor])
		for k in _details.size():
			_details[k].text = shown[k]
	for item in _notches:
		var filled := menu.slider(item).x
		for k in _notches[item].size():
			_notches[item][k].color = Hud.INK if k < filled else Color(Hud.INK_SOFT, 0.3)
	_mark.position.y = 5 + (menu.list.cursor - _top) * ROW_H
	if _bar.visible:
		var track := n * ROW_H
		_bar.size = Vector2(2, maxf(track * n / float(items.size()), 4)).floor()
		_bar.position.y = floorf(5 + (track - _bar.size.y) * _top / float(items.size() - n))
	if menu.page == "controls":
		_note.text = menu.hint()
	elif menu.page == "fishlog":
		_note.text = menu.total_text()
	elif menu.page == "shipped":
		_note.text = menu.shipped_total_text()


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
	var b := UiStyle.panel(null, kind)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b


# --- input --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	# Not over a text box or an event: they have the keys until they end.
	if not _open and not Game.dialogue_open and not Game.event_running and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		open()


# While open, every key and pad button is taken here, so nothing reaches the farm or F5 / F9.
func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventJoypadMotion:
		# A trigger or the right stick pushed far enough goes into a listening pad slot.
		if menu.listening_pad() and Controls.motion_code(event.axis, event.axis_value) != Controls.NO_BUTTON:
			get_viewport().set_input_as_handled()
			_do(menu.press_pad(Controls.motion_code(event.axis, event.axis_value)))
		return
	if not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if menu.listening_pad():
		# Every pad button (or axis, above) goes into the slot; of the keys only Esc counts (it cancels).
		if event is InputEventJoypadButton and event.pressed:
			_do(menu.press_pad(event.button_index))
		elif event is InputEventKey and event.pressed and not event.echo:
			_do(menu.press(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode))
		return
	if menu.listening != "":
		# Every key goes into the slot (Esc cancels); of the pad only its back button counts.
		if event is InputEventKey and event.pressed and not event.echo:
			_do(menu.press(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode))
		elif event.is_action_pressed("ui_cancel"):
			_do(menu.back())
		return
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
	elif event is InputEventKey and event.pressed and event.physical_keycode in [KEY_DELETE, KEY_BACKSPACE]:
		_do(menu.clear())


## The mouse over row i (and key slot k on the controls page; -1 = the row itself).
func _on_row_hover(i: int, k: int) -> void:
	if menu.listening == "" and menu.list.point(menu.list.items[_top + i]):
		if k >= 0:
			menu.slot = k
		_refresh()


func _on_row_input(event: InputEvent, i: int, k: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if menu.listening != "":
			_do(menu.back())   # a click while waiting for a key cancels
		elif menu.list.point(menu.list.items[_top + i]):
			if k >= 0:
				menu.slot = k
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
			_say("Game saved." if err == "" else err)
		"setting":
			var ui := Game.ui_scale
			Game.apply_settings()
			var err := Game.settings.write()
			if Game.ui_scale != ui:   # the UI size changed: the box grows or shrinks at once
				var cursor := menu.list.cursor
				_build()
				menu.list.cursor = cursor
				_refresh()
			_say(err if err != "" else menu.note)
		"controls":
			Game.settings.controls.apply()
			var err := Game.settings.write()
			if err != "":
				menu.note = err
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
