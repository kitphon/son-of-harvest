class_name Hud
extends CanvasLayer
## Paper-and-wood HUD in our pixel font: date, clock and the weather for today and tomorrow
## (top right), the tool bar (the rucksack's tool slots) with the tool in hand and its level
## pips and, when there is one, the item held in the other hand (bottom left), money, shipping bin and a
## stamina bar (bottom right), and a message line (top left). Reads Game and redraws on its
## signals.

const INK := Color("3b2a1a")
const INK_SOFT := Color("7a6040")
const RULE := Color("d2bf94")
const NINE_MARGIN := 4

var _date: Label
var _time: Label
var _today: TextureRect
var _tomorrow: TextureRect
var _slots: Array[TextureRect] = []
var _slot_icons: Array[TextureRect] = []
var _item_name: Label
var _item_count: Label
var _item_level: TextureRect   # one pip per tool level after the name, filled up to the level
var _hand_box: NinePatchRect
var _hand_icon: TextureRect
var _money: Label
var _bin: Label
var _stamina_fill: ColorRect
var _msg_box: NinePatchRect
var _msg: Label
var _msg_time := 0.0


func _ready() -> void:
	_build_clock(HudLayout.BOXES.clock)
	_build_tools(HudLayout.BOXES.tools, HudLayout.BOXES.item)
	_build_status(HudLayout.BOXES.status)
	_msg_box = _box(HudLayout.BOXES.message, "paper")
	_msg = _label(_msg_box, Vector2i(6, 5))
	_msg_box.visible = false
	Game.changed.connect(_refresh)
	Game.message.connect(_show)
	_refresh()


func _build_clock(r: Rect2i) -> void:
	var box := _box(r, "paper")
	_date = _label(box, Vector2i(6, 5))
	var rule := ColorRect.new()
	rule.color = RULE
	rule.position = Vector2(5, 15)
	rule.size = Vector2(r.size.x - 10, 1)
	box.add_child(rule)
	_time = _label(box, Vector2i(6, 19))
	_time.scale = Vector2(2, 2)
	_today = _icon(box, Vector2i(54, 21))
	var arrow := _label(box, Vector2i(68, 23), INK_SOFT)
	arrow.text = ">"
	_tomorrow = _icon(box, Vector2i(74, 21))


func _build_tools(r: Rect2i, item_r: Rect2i) -> void:
	var item := _box(item_r, "paper")
	_item_name = _label(item, Vector2i(6, 6))
	_item_count = _label(item, Vector2i(6, 6), INK_SOFT)
	_item_level = _icon(item, Vector2i(6, 7))
	var bar := _box(r, "wood")
	for i in Game.inventory.size("tools"):
		var slot := _icon(bar, Vector2i(5 + i * (HudLayout.SLOT + HudLayout.SLOT_GAP), 5))
		_slots.append(slot)
		_slot_icons.append(_icon(slot, Vector2i(2, 2)))
	_hand_box = _box(HudLayout.BOXES.hand, "wood")
	_icon(_hand_box, Vector2i(5, 5)).texture = PlaceholderArt.tex("ui:slot:off")
	_hand_icon = _icon(_hand_box, Vector2i(7, 7))


func _build_status(r: Rect2i) -> void:
	var box := _box(r, "paper")
	_icon(box, Vector2i(6, 6)).texture = PlaceholderArt.tex("ui:coin")
	_money = _label(box, Vector2i(18, 6))
	_bin = _label(box, Vector2i(18, 16), INK_SOFT)
	_icon(box, Vector2i(6, 27)).texture = PlaceholderArt.tex("ui:stamina")
	var back := ColorRect.new()
	back.color = PlaceholderArt.UI_WOOD_DARK
	back.position = Vector2(18, 29)
	back.size = Vector2(r.size.x - 24, 5)
	box.add_child(back)
	_stamina_fill = ColorRect.new()
	_stamina_fill.position = Vector2(1, 1)
	_stamina_fill.size = Vector2(back.size.x - 2, 3)
	back.add_child(_stamina_fill)


func _box(r: Rect2i, kind: String) -> NinePatchRect:
	var b := NinePatchRect.new()
	b.texture = PlaceholderArt.tex("ui:frame:" + kind)
	b.patch_margin_left = NINE_MARGIN
	b.patch_margin_top = NINE_MARGIN
	b.patch_margin_right = NINE_MARGIN
	b.patch_margin_bottom = NINE_MARGIN
	b.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.position = r.position
	b.size = r.size
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(b)
	return b


func _label(parent: Control, pos: Vector2i, color := INK) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", PixelFont.font())
	l.add_theme_font_size_override("font_size", PixelFont.size())
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("line_spacing", int(PixelFont.data().line_gap))
	parent.add_child(l)
	return l


func _icon(parent: Control, pos: Vector2i) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func _process(delta: float) -> void:
	if _msg_time > 0.0:
		_msg_time -= delta
		if _msg_time <= 0.0:
			_msg_box.visible = false


func _show(text: String) -> void:
	_msg.text = text
	_msg_box.size.x = PixelFont.width(text) + 12
	_msg_box.visible = text != ""
	_msg_time = 3.0


func _refresh() -> void:
	_date.text = Game.date_text()
	_time.text = Game.time_text()
	_today.texture = PlaceholderArt.tex("ui:weather:" + HudLayout.weather_icon(Game.weather_look(Game.weather_today, Game.season_name())))
	var next_season := Game.season if Game.day < Game.DAYS_PER_SEASON else (Game.season + 1) % Game.SEASONS.size()
	_tomorrow.texture = PlaceholderArt.tex("ui:weather:" + HudLayout.weather_icon(Game.weather_look(Game.weather_tomorrow, Game.SEASONS[next_season])))

	var tool := Game.current_tool()
	for i in _slots.size():
		_slots[i].texture = PlaceholderArt.tex("ui:slot:" + ("on" if i == Game.tool_index else "off"))
		var t := Game.inventory.id_at("tools", i)
		_slot_icons[i].texture = null if t == "" else PlaceholderArt.tex(PlaceholderArt.item_key(t, Game.current_seed(), Game.current_food()))
	var held := Game.inventory.id_at("hand", 0)
	_hand_box.visible = held != ""
	if held != "":
		_hand_icon.texture = PlaceholderArt.tex(PlaceholderArt.item_key(held))
	var item := item_text(tool)
	_item_name.text = item[0]
	_item_count.text = item[1]
	_item_count.position.x = HudLayout.BOXES.item.size.x - 6 - PixelFont.width(item[1])
	var levels := Game.tool_max_level(tool)
	_item_level.visible = levels > 0
	if levels > 0:
		_item_level.texture = PlaceholderArt.tex(PlaceholderArt.charge_key(Game.tool_level(tool), levels))
		_item_level.position.x = 6 + PixelFont.width(item[0]) + 4

	_money.text = "%d G" % Game.money
	_bin.text = "Bin %d G" % Game.bin_total
	var f := clampf(float(Game.stamina) / maxf(Game.max_stamina, 1), 0.0, 1.0)
	_stamina_fill.size.x = roundi((HudLayout.BOXES.status.size.x - 26) * f)
	_stamina_fill.color = Color("6aa84f") if f > 0.5 else (Color("e0a838") if f > 0.25 else PlaceholderArt.UI_SEAL)


## [name, count] for the item box.
static func item_text(tool: String) -> Array[String]:
	if tool == "":
		return ["No tool", ""]
	if tool == "can":
		return [HudLayout.TOOL_NAMES.can, "%d/%d" % [Game.water, Game.WATER_MAX]]
	if tool == "seeds":
		var s := Game.current_seed()
		return ["%s seeds" % Game.crops[s].name, "x%d" % Game.count("seeds:" + s)]
	if tool == "food":
		var f := Game.current_food()
		return [String(Game.foods.get(f, {}).get("name", "Food")), "x%d" % Game.count("food:" + f)]
	return [HudLayout.TOOL_NAMES.get(tool, tool.capitalize()), ""]
