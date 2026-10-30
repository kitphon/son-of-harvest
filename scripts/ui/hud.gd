class_name Hud
extends CanvasLayer
## Date, clock, weather, money, stamina, the tool in hand, and a line for messages.

const FONT_SIZE := 8

var _info: Label
var _msg: Label
var _msg_time := 0.0


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.position = Vector2(4, 218)
	bg.size = Vector2(196, 48)
	add_child(bg)
	_info = _label(Vector2(8, 220))
	_msg = _label(Vector2(8, 4))
	Game.changed.connect(_refresh)
	Game.message.connect(_show)
	_refresh()


func _label(pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", FONT_SIZE)
	l.add_theme_constant_override("line_spacing", -2)
	add_child(l)
	return l


func _process(delta: float) -> void:
	if _msg_time > 0.0:
		_msg_time -= delta
		if _msg_time <= 0.0:
			_msg.text = ""


func _show(text: String) -> void:
	_msg.text = text
	_msg_time = 3.0


func _refresh() -> void:
	var tool := Game.current_tool()
	var hand := tool.capitalize()
	if tool == "can":
		hand = "Watering can %d/%d" % [Game.water, Game.WATER_MAX]
	elif tool == "seeds":
		var s := Game.current_seed()
		hand = "%s seeds x%d" % [Game.crops[s].name, Game.count("seeds:" + s)]
	_info.text = "%s   %s\n%s (tomorrow %s)\n%d G   bin %d G   stamina %d/%d\n[%d] %s" % [
		Game.date_text(), Game.time_text(),
		Game.weather_today.capitalize(), Game.weather_tomorrow,
		Game.money, Game.bin_total, Game.stamina, Game.max_stamina,
		Game.tool_index + 1, hand]
