class_name Hud
extends CanvasLayer
## Paper-and-wood HUD in our pixel font: date, clock and the weather for today and tomorrow
## (top right) with today's festival (or a villager's birthday) under it, the tool bar (the rucksack's tool slots) with the tool in hand and its level
## pips and, when there is one, the item held in the other hand (bottom left), money, shipping bin and a
## stamina bar (bottom right), and a message line (top left). Reads Game and redraws on its
## signals; hidden while the "Show HUD" setting is off, its corners grown by the "UI size"
## setting (HudLayout.scaled_box). Over the tool bar, while the "Key hints" setting is on, a line
## says what the interact and tool buttons would do at the spot in front (ActionHints), with
## the player's own keys.

const INK := Color("3b2a1a")
const INK_SOFT := Color("7a6040")
const RULE := Color("d2bf94")
const NINE_MARGIN := 4

var _date: Label
var _time: Label
var _today: TextureRect
var _tomorrow: TextureRect
var _fest_box: NinePatchRect
var _fest: Label
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
var _hint_box: NinePatchRect
var _hint_labels: Array[Label] = []   # key, word, key, word
var _hint_time := 0.0                 # seconds to the next look
var _placed: Dictionary = {}   # box key in HudLayout.BOXES -> its box, placed by the UI size


func _ready() -> void:
	_build_clock(HudLayout.BOXES.clock)
	_fest_box = _box(HudLayout.BOXES.festival, "paper", "festival")
	_fest = _label(_fest_box, Vector2i(6, 5))
	_build_tools(HudLayout.BOXES.tools, HudLayout.BOXES.item)
	_build_status(HudLayout.BOXES.status)
	_msg_box = _box(HudLayout.BOXES.message, "paper", "message")
	_msg = _label(_msg_box, Vector2i(6, 5))
	_msg_box.visible = false
	_hint_box = _box(HudLayout.BOXES.hint, "paper", "hint")
	for i in 4:
		_hint_labels.append(_label(_hint_box, Vector2i(6, 4), PlaceholderArt.UI_SEAL if i % 2 == 0 else INK))
	_hint_box.visible = false
	Game.changed.connect(_refresh)
	Game.message.connect(_show)
	Game.settings_changed.connect(_on_settings)
	_on_settings()
	_refresh()


func _build_clock(r: Rect2i) -> void:
	var box := _box(r, "paper", "clock")
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
	var item := _box(item_r, "paper", "item")
	_item_name = _label(item, Vector2i(6, 6))
	_item_count = _label(item, Vector2i(6, 6), INK_SOFT)
	_item_level = _icon(item, Vector2i(6, 7))
	var bar := _box(r, "wood", "tools")
	for i in Game.inventory.size("tools"):
		var slot := _icon(bar, Vector2i(5 + i * (HudLayout.SLOT + HudLayout.SLOT_GAP), 5))
		_slots.append(slot)
		_slot_icons.append(_icon(slot, Vector2i(2, 2)))
	_hand_box = _box(HudLayout.BOXES.hand, "wood", "hand")
	_icon(_hand_box, Vector2i(5, 5)).texture = PlaceholderArt.tex("ui:slot:off")
	_hand_icon = _icon(_hand_box, Vector2i(7, 7))


func _build_status(r: Rect2i) -> void:
	var box := _box(r, "paper", "status")
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


func _box(r: Rect2i, kind: String, key: String) -> NinePatchRect:
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
	_placed[key] = b
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
	_hint_time -= delta
	if _hint_time <= 0.0:
		_hint_time = 0.1
		_show_hints()
	if _msg_time > 0.0:
		_msg_time -= delta
		if _msg_time <= 0.0:
			_msg_box.visible = false


## Esc -> Settings -> Show HUD hides all of it (messages too).
func _on_settings() -> void:
	visible = Game.hud_visible
	for key in _placed:
		var r := HudLayout.scaled_box(key, Game.ui_scale)
		_placed[key].position = r.position
		_placed[key].scale = Vector2.ONE * HudLayout.group_scale(key, Game.ui_scale)


## The key hints for the farmer's spot now, or none while a menu, a text box or an event
## holds the game (or the setting is off).
func _show_hints() -> void:
	var pairs: Array[String] = []
	if Game.key_hints and not Game.paused():
		var h := ActionHints.pick(Player.cell_of(Game.maps.pos), Game.maps.facing)
		pairs = hint_pairs(h, ActionHints.key_text("interact"), ActionHints.key_text("use_tool"))
	var x := 6
	for i in _hint_labels.size():
		var text := pairs[i] if i < pairs.size() else ""
		_hint_labels[i].text = text
		_hint_labels[i].position.x = x
		if text != "":
			x += PixelFont.width(text) + (4 if i % 2 == 0 else 10)
	_hint_box.visible = not pairs.is_empty()
	_hint_box.size.x = x - 10 + 6 if not pairs.is_empty() else HudLayout.BOXES.hint.size.x


## [key, word, key, word] for the hints `h` (ActionHints.pick): interact first, then the tool
## button; a button with nothing to do (or no key bound) is left out, and two buttons doing
## the same share one hint ("E/Space Reel in").
static func hint_pairs(h: Dictionary, interact_key: String, tool_key: String) -> Array[String]:
	var out: Array[String] = []
	if h.get("interact", "") != "" and h.interact == h.get("use_tool", "") and interact_key != "" and tool_key != "":
		return ["%s/%s" % [interact_key, tool_key], h.interact]
	if h.get("interact", "") != "" and interact_key != "":
		out.append_array([interact_key, h.interact])
	if h.get("use_tool", "") != "" and tool_key != "":
		out.append_array([tool_key, h.use_tool])
	return out


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
	# The festival's name all day, in the seal red while it is on; else a villager's birthday.
	var fest := Game.festival_today()
	_fest.text = Festivals.name_of(fest) if fest != "" else HudLayout.day_tag(Game.birthdays_today())
	if fest == "" and Marriage.day_tag(Game.flags) != "":   # the wedding day comes before a birthday
		_fest.text = Marriage.day_tag(Game.flags)
	_fest_box.visible = _fest.text != ""
	_fest.add_theme_color_override("font_color", PlaceholderArt.UI_SEAL if Festivals.in_hours(fest, Game.hour * 60 + Game.minute) else INK)

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
