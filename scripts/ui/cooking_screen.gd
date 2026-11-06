class_name CookingScreen
extends CanvasLayer
## The kitchen corner's cooking screen over the room: a wood box with "Kitchen" and how many
## recipes are known, a paper page listing the known recipes with their dish icons, what the
## one under the cursor needs (and how many of each the rucksack and the chest hold), the
## kitchen tools it uses (and which are missing) and what cooking said. Opens on Game.cooking_requested (E at the stove or the cupboard). Up / down
## pick, Enter / Space / E cook once, Esc / I leave; the mouse points, a click cooks. Game is
## paused while it is open. Rules: CookingMenu and Cooking. `-- --cook` opens it at the start
## (with `--demo`: a few things to cook with), for screenshots.

const W := 300              # the paper's width
const TOP := 17             # the heading strip on the wood
const ROW := 18
const ROWS := 7             # rows shown at once; the list scrolls
const LINE := 11
const ABOUT_ROWS := 2
const PAPER := UiStyle.PAPER_TEXT
const HINT := "Enter: cook  Esc: leave"

var menu: CookingMenu
var _open := false
var _top := 0                       # first row shown
var _dim: ColorRect
var _wood: NinePatchRect
var _paper: NinePatchRect
var _heading: Label
var _count: Label
var _bar: ColorRect                 # under the cursor's row
var _icons: Array[TextureRect] = []
var _names: Array[Label] = []
var _states: Array[Label] = []
var _hits: Array[Control] = []      # one mouse area per shown row
var _more_up: Label
var _more_down: Label
var _about: Label
var _needs: Label
var _tools: Label
var _note: Label


func _ready() -> void:
	layer = 10   # over the HUD
	_dim = ColorRect.new()
	_dim.color = UiStyle.DIM
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_wood = _box(_dim, "wood")
	_heading = _label(_wood, Vector2i(9, 5), PAPER)
	_heading.text = "Kitchen"
	_count = _label(_wood, Vector2i(0, 5), PAPER)
	_paper = _box(_wood, "paper")
	_paper.position = Vector2(4, TOP)
	_build()
	_dim.visible = false
	Game.cooking_requested.connect(open)
	if "--cook" in OS.get_cmdline_user_args():
		Game.open_cooking.call_deferred()


func _exit_tree() -> void:
	if _open:
		_open = false
		Game.unpause()


func is_open() -> bool:
	return _open


## Opens the screen; not over another menu or a text box.
func open() -> void:
	if _open or Game.paused():
		return
	_open = true
	Game.pause()
	menu = CookingMenu.new(Game)
	_top = 0
	_dim.visible = true
	_note.text = ""
	_refresh()
	Sfx.play("menu_ok")


func close() -> void:
	if not _open:
		return
	_open = false
	_dim.visible = false
	Game.unpause()
	Game.changed.emit()


# --- drawing ------------------------------------------------------------------

func _build() -> void:
	var title := _label(_paper, Vector2i(6, 5))
	title.text = "Recipes"
	var rule := ColorRect.new()
	rule.color = Hud.RULE
	rule.position = Vector2(5, 16)
	rule.size = Vector2(W - 10, 1)
	_paper.add_child(rule)
	_bar = ColorRect.new()
	_bar.color = UiStyle.BAR
	_bar.size = Vector2(W - 10, ROW)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(_bar)
	var y := 20
	for i in ROWS:
		var hit := Control.new()
		hit.position = Vector2(5, y)
		hit.size = Vector2(W - 10, ROW)
		hit.mouse_filter = Control.MOUSE_FILTER_STOP
		hit.gui_input.connect(_on_row_input.bind(i))
		_paper.add_child(hit)
		_hits.append(hit)
		_icons.append(_icon(_paper, Vector2i(8, y + 2)))
		_names.append(_label(_paper, Vector2i(28, y + 5)))
		_states.append(_label(_paper, Vector2i(0, y + 5)))
		y += ROW
	_more_up = _label(_paper, Vector2i(W - 70, 5), Hud.INK_SOFT)
	_more_down = _label(_paper, Vector2i(W - 70, y + 4), Hud.INK_SOFT)
	_about = _label(_paper, Vector2i(6, y + 4))
	_about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # wraps in a longer language
	_about.size.x = W - 12
	_about.max_lines_visible = ABOUT_ROWS
	y += LINE * (ABOUT_ROWS - 1)
	_needs = _label(_paper, Vector2i(6, y + 4 + LINE))
	_tools = _label(_paper, Vector2i(6, y + 4 + LINE * 2))
	_note = _label(_paper, Vector2i(6, y + 4 + LINE * 3), PlaceholderArt.UI_SEAL)
	var hint := _label(_paper, Vector2i(6, y + 4 + LINE * 4), Hud.INK_SOFT)
	hint.text = HINT
	_paper.size = Vector2(W, y + 4 + LINE * 5 + 3)
	_wood.size = Vector2(W + 8, TOP + _paper.size.y + 4)
	var screen := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	_wood.position = ((screen - _wood.size) / 2).floor()
	UiScale.apply_layer(self, Rect2(_wood.position, _wood.size), Game.ui_scale, screen)   # the UI size setting


func _refresh() -> void:
	var rows := menu.rows()
	_count.text = "%d of %d known" % [rows.size(), Cooking.ids().size()]
	_count.position.x = _wood.size.x - 9 - PixelFont.shown_width(_count.text)
	_top = clampi(_top, maxi(menu.cursor - ROWS + 1, 0), menu.cursor)
	for i in ROWS:
		var k := _top + i
		var on := k < rows.size()
		_icons[i].visible = on
		_names[i].visible = on
		_states[i].visible = on
		if not on:
			continue
		var row: Dictionary = rows[k]
		_icons[i].texture = PlaceholderArt.tex(PlaceholderArt.item_key(row.dish))
		_names[i].text = String(Game.foods.get(row.id, {}).get("name", row.id))
		if int(row.makes) > 1:
			_names[i].text = "%s x%d" % [_names[i].text, int(row.makes)]
		_states[i].text = CookingMenu.state_text(row)
		_states[i].position.x = W - 8 - PixelFont.shown_width(_states[i].text)
		var ink := Hud.INK if row.ready else Hud.INK_SOFT
		_names[i].add_theme_color_override("font_color", ink)
		_states[i].add_theme_color_override("font_color", PlaceholderArt.UI_SEAL if row.ready else Hud.INK_SOFT)
	_bar.visible = not rows.is_empty()
	_bar.position = Vector2(5, 20 + (menu.cursor - _top) * ROW)
	_more_up.text = "more above" if _top > 0 else ""
	_more_down.text = "more below" if _top + ROWS < rows.size() else ""
	var row := menu.current()
	_about.text = String(Cooking.recipe(row.id).get("about", "")) if not row.is_empty() else ""
	_needs.text = Lang.t("Needs %s") % ", ".join(menu.needs_parts(true)) if not row.is_empty() else ""
	_tools.text = menu.tools_text(true)
	_tools.add_theme_color_override("font_color", Hud.INK if row.is_empty() or row.no_tools.is_empty() else PlaceholderArt.UI_SEAL)
	if rows.is_empty():
		_names[0].visible = true
		_names[0].text = "You don't know any recipes yet."
		_names[0].add_theme_color_override("font_color", Hud.INK_SOFT)


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
	var b := UiStyle.panel(null, kind)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b


# --- input --------------------------------------------------------------------

# While open, every key and pad button is taken here, so nothing reaches the room.
func _input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("rucksack") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		menu.move(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		menu.move(1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_cook()
		return
	else:
		return
	Sfx.play("menu_move")
	_refresh()


func _cook() -> void:
	_note.text = menu.choose()
	Sfx.play("cook" if menu.last_ok else "menu_ok")
	_refresh()


func _on_row_input(event: InputEvent, i: int) -> void:
	if not _open:
		return
	if event is InputEventMouseMotion:
		if menu.point(_top + i):
			_refresh()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and menu.point(_top + i):
		_cook()
