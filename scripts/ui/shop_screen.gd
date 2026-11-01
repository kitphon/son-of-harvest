class_name ShopScreen
extends CanvasLayer
## A shop's screen over the room: a wood box with the shop's name and the farmer's money, a
## paper page with the tabs (Buy / Sell / Tools), a list of goods with icons and prices, and
## what the deal costs. Opens on Game.shop_requested (the counter; later its keeper). Up /
## down pick, left / right how many, Enter / Space / E deal, Tab / Q next tab, Esc / I leave;
## the mouse points, a click deals, a click on a tab opens it. Game is paused while it is
## open. Rules: ShopMenu and Shop. `-- --shop=<id>` opens it at the start, for screenshots.

const W := 300              # the paper's width
const TOP := 17             # the heading strip on the wood
const ROW := 18
const ROWS := 7             # rows shown at once; the list scrolls
const LINE := 11
const PAPER := Color("f6ead0")
const HINTS := {
	"buy": "Enter: buy  Left/Right: how many  Esc: leave",
	"sell": "Enter: sell  Left/Right: how many  Esc: leave",
	"tools": "Enter: hand in / pick up  Esc: leave",
	"build": "Enter: order  Esc: leave",
}

var menu: ShopMenu
var _open := false
var _top := 0                       # first row shown
var _dim: ColorRect
var _wood: NinePatchRect
var _paper: NinePatchRect
var _heading: Label
var _money: Label
var _tabs: Array[Label] = []
var _bar: ColorRect                 # under the cursor's row
var _icons: Array[TextureRect] = []
var _names: Array[Label] = []
var _prices: Array[Label] = []
var _hits: Array[Control] = []      # one mouse area per shown row
var _more_up: Label
var _more_down: Label
var _info: Label
var _note: Label
var _hint: Label
var _hours: Label


func _ready() -> void:
	layer = 10   # over the HUD
	_dim = ColorRect.new()
	_dim.color = Color(0.1, 0.07, 0.04, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_wood = _box(_dim, "wood")
	_heading = _label(_wood, Vector2i(9, 5), PAPER)
	_money = _label(_wood, Vector2i(0, 5), PAPER)
	_paper = _box(_wood, "paper")
	_paper.position = Vector2(4, TOP)
	_build()
	_dim.visible = false
	Game.shop_requested.connect(open)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shop="):
			_open_forced.call_deferred(arg.trim_prefix("--shop="))


func _exit_tree() -> void:
	if _open:
		_open = false
		Game.unpause()


func is_open() -> bool:
	return _open


## `--shop=<id>` or `--shop=<id>@<tab>` (e.g. general@build).
func _open_forced(arg: String) -> void:
	var want := arg.split("@")
	Game.open_shop(want[0], true)
	if _open and want.size() > 1 and want[1] in menu.tabs:
		menu.next_tab(menu.tabs.find(want[1]) - menu.tab)
		_refresh()


## Opens shop `id`; not over another menu or a text box.
func open(id: String) -> void:
	if _open or Game.paused() or Game.shop(id) == null:
		return
	_open = true
	Game.pause()
	menu = ShopMenu.new(Game, id)
	_top = 0
	_dim.visible = true
	_heading.text = menu.shop.name
	_hours.text = "Open %s, %s" % [menu.shop.hours_text(), menu.shop.days_off_text()]
	if id.begins_with(Festivals.STALL_PREFIX):   # a festival stall stands for its festival only
		_hours.text = "Open %s, %s only" % [menu.shop.hours_text(), Festivals.name_of(Festivals.stall_of(id)[0])]
	for i in _tabs.size():
		_tabs[i].visible = i < menu.tabs.size()
		if i < menu.tabs.size():
			_tabs[i].text = ShopMenu.TAB_NAMES[menu.tabs[i]]
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
	var x := 6
	for i in 3:
		var t := _label(_paper, Vector2i(x, 5))
		t.mouse_filter = Control.MOUSE_FILTER_STOP
		t.gui_input.connect(_on_tab_input.bind(i))
		_tabs.append(t)
		x += 44
	var rule := ColorRect.new()
	rule.color = Hud.RULE
	rule.position = Vector2(5, 16)
	rule.size = Vector2(W - 10, 1)
	_paper.add_child(rule)
	_bar = ColorRect.new()
	_bar.color = Color("ead9b0")
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
		_icons.append(_icon(_paper, Vector2i(8, y + 1)))
		_names.append(_label(_paper, Vector2i(28, y + 5)))
		_prices.append(_label(_paper, Vector2i(0, y + 5)))
		y += ROW
	_more_up = _label(_paper, Vector2i(W - 70, 5), Hud.INK_SOFT)
	_more_down = _label(_paper, Vector2i(W - 70, y + 4), Hud.INK_SOFT)
	_info = _label(_paper, Vector2i(6, y + 4))
	_note = _label(_paper, Vector2i(6, y + 4 + LINE), PlaceholderArt.UI_SEAL)
	_hint = _label(_paper, Vector2i(6, y + 4 + LINE * 2), Hud.INK_SOFT)
	_hours = _label(_paper, Vector2i(6, y + 4 + LINE * 3), Hud.INK_SOFT)
	_paper.size = Vector2(W, y + 4 + LINE * 4 + 3)
	_wood.size = Vector2(W + 8, TOP + _paper.size.y + 4)
	var screen := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	_wood.position = ((screen - _wood.size) / 2).floor()
	UiScale.apply_layer(self, Rect2(_wood.position, _wood.size), Game.ui_scale, screen)   # the UI size setting


func _refresh() -> void:
	_money.text = "%d G" % Game.money
	_money.position.x = _wood.size.x - 9 - PixelFont.width(_money.text)
	for i in menu.tabs.size():
		_tabs[i].add_theme_color_override("font_color", Hud.INK if i == menu.tab else Hud.INK_SOFT)
		_tabs[i].text = ("> " if i == menu.tab else "  ") + ShopMenu.TAB_NAMES[menu.tabs[i]]
	var rows := menu.rows()
	_top = clampi(_top, maxi(menu.cursor - ROWS + 1, 0), menu.cursor)
	for i in ROWS:
		var k := _top + i
		var on := k < rows.size()
		_icons[i].visible = on
		_names[i].visible = on
		_prices[i].visible = on
		if not on:
			continue
		var row: Dictionary = rows[k]
		_icons[i].texture = PlaceholderArt.tex(PlaceholderArt.item_key(row.item))
		_names[i].text = _row_name(row)
		_prices[i].text = _row_price(row, k == menu.cursor)
		_prices[i].position.x = W - 8 - PixelFont.width(_prices[i].text)
		var soft: bool = menu.tab_id() in ["tools", "build"] and row.state in ["top", "missing", "busy", "done", "short"]
		soft = soft or (menu.tab_id() in ["buy", "build"] and row.get("state", "offer") == "offer" and int(row.price) > Game.money)
		soft = soft or (menu.tab_id() == "buy" and row.to == "animal" and Game.shop_room(menu.shop.id, row.item) <= 0)
		_names[i].add_theme_color_override("font_color", Hud.INK_SOFT if soft else Hud.INK)
		_prices[i].add_theme_color_override("font_color", Hud.INK_SOFT if soft else Hud.INK)
	_bar.visible = not rows.is_empty()
	_bar.position = Vector2(5, 20 + (menu.cursor - _top) * ROW)
	_more_up.text = "more above" if _top > 0 else ""
	_more_down.text = "more below" if _top + ROWS < rows.size() else ""
	_info.text = _info_text()
	_hint.text = HINTS.get(menu.tab_id(), "Esc: leave")
	if rows.is_empty():
		_names[0].visible = true
		_names[0].text = "You have nothing they buy." if menu.tab_id() == "sell" else "Nothing today."
		_names[0].add_theme_color_override("font_color", Hud.INK_SOFT)


func _row_name(row: Dictionary) -> String:
	var name := menu.shop.item_name(row.item)
	match menu.tab_id():
		"buy":
			if row.item == "rucksack":
				return "%s (%d slots)" % [name, int(row.slots)]
		"build":
			match str(row.state):
				"done":
					return "%s  built" % name
				"building":
					return "%s  being built" % name
		"sell":
			return "%s (%d)" % [name, int(row.have)]
		"tools":
			match str(row.state):
				"offer", "missing", "busy", "short":
					return "%s  Lv %d > %d" % [name, int(row.level), int(row.level) + 1]
				"top":
					return "%s  Lv %d" % [name, int(row.level)]
				"away":
					return "%s  at the forge" % name
				"ready":
					return "%s  Lv %d ready" % [name, int(row.level)]
	return name


func _row_price(row: Dictionary, here: bool) -> String:
	if menu.tab_id() == "tools":
		match str(row.state):
			"offer", "missing", "busy", "short":
				return "%d G" % int(row.price)
			"ready":
				return "pick up"
			"away":
				return Game.date_of(int(row.ready)).get_slice(",", 0)
		return ""
	if menu.tab_id() == "build":
		match str(row.state):
			"done":
				return ""
			"building":
				return Game.date_of(int(row.ready)).get_slice(",", 0)
		return "%d G" % int(row.price)
	if here and menu.count > 1:
		return "x%d  %d G" % [menu.count, menu.total()]
	return "%d G" % int(row.price)


func _info_text() -> String:
	var row := menu.current()
	if row.is_empty():
		return ""
	match menu.tab_id():
		"buy":
			if row.item == "rucksack":
				return "Now %d slots. What's in it stays." % Game.inventory.size("bag")
			match str(row.to):
				"kitchen":
					return "%s For the kitchen." % Cooking.tool_info(str(row.tool)).get("about", "")
				"animal":
					var room := Game.shop_room(menu.shop.id, row.item)
					var home: String = Game.animals.kind_rule(Shop.animal_of(row.item).kind).get("home", "coop")
					return "Room in the %s: %d" % [home, room] if room > 0 else "The %s is full." % home
				"feed":
					return "Feed in the coop's sack: %d" % Game.animals.feed_stock
				"fodder":
					return "Fodder in the barn's loft: %d" % Game.animals.stock_of("barn")
			return "In your rucksack: %d" % Game.count(str(row.item))
		"build":
			var b: Dictionary = menu.shop.builds.get(row.item, {})
			match str(row.state):
				"offer":
					return "%s %d %s." % [b.get("about", ""), int(row.days), "day" if int(row.days) == 1 else "days"]
				"busy":
					return "Another job is underway."
				"building":
					if int(row.get("late", 0)) > 0:
						return menu.shop.build_late % Game.date_of(int(row.ready))
					return "Done on %s." % Game.date_of(int(row.ready))
			return str(b.get("about", ""))
		"sell":
			return "%d G each" % int(row.price)
		"tools":
			match str(row.state):
				"offer":
					if not row.get("items", {}).is_empty():
						return "Needs %s. %d %s." % [menu.shop.materials_text(row.items), int(row.days), "day" if int(row.days) == 1 else "days"]
					return "Takes %d %s. The %s stays here." % [int(row.days), "day" if int(row.days) == 1 else "days",
						menu.shop.item_name(row.item).to_lower()]
				"short":
					return "Still needs %s." % menu.shop.materials_text(row.lack)
				"missing":
					return "Bring it in your tool slots."
				"busy":
					return "Another tool is being worked on."
				"away":
					return "Ready on %s." % Game.date_of(int(row.ready))
				"top":
					return "It can't be improved any more."
	return ""


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
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		menu.change_count(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		menu.change_count(1)
	elif event.is_action_pressed("next_tool") or event.is_action_pressed("next_seed"):
		menu.next_tab()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_deal()
		return
	else:
		return
	Sfx.play("menu_move")
	_refresh()


func _deal() -> void:
	_note.text = menu.choose()
	Sfx.play("coins" if menu.last_ok else "menu_ok")
	_refresh()


func _on_row_input(event: InputEvent, i: int) -> void:
	if not _open:
		return
	if event is InputEventMouseMotion:
		if menu.point(_top + i):
			_refresh()
	elif event is InputEventMouseButton and event.pressed and menu.point(_top + i):
		if event.button_index == MOUSE_BUTTON_LEFT:
			_deal()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			menu.change_count(1)
			_refresh()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			menu.change_count(-1)
			_refresh()


func _on_tab_input(event: InputEvent, i: int) -> void:
	if _open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and i < menu.tabs.size() and i != menu.tab:
		menu.next_tab(i - menu.tab)
		Sfx.play("menu_move")
		_refresh()
