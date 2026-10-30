extends Node2D
## Puts the farm scene together and turns the player's actions into farm rules.

const T := 16
const HOME := Vector2(4 * T + 8, 4 * T + 10)   # in front of the door
## Day / night tint keyframes: minute of the day -> colour (linear in between).
const TINT := [
	[0, Color(0.42, 0.45, 0.72)], [300, Color(0.42, 0.45, 0.72)], [420, Color.WHITE],
	[960, Color.WHITE], [1080, Color(1.0, 0.8, 0.65)], [1200, Color(0.42, 0.45, 0.72)],
	[1440, Color(0.42, 0.45, 0.72)],
]

var player: Player
var tint: CanvasModulate


func _ready() -> void:
	var view := FarmView.new()
	view.farm = Game.farm
	add_child(view)

	player = Player.new()
	player.farm = Game.farm
	player.position = HOME
	player.action.connect(_on_action)
	add_child(player)

	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = FarmGrid.W * T
	cam.limit_bottom = FarmGrid.H * T
	player.add_child(cam)

	tint = CanvasModulate.new()
	add_child(tint)
	add_child(Hud.new())

	Game.minute_passed.connect(_update_tint)
	Game.day_started.connect(_on_day_started)
	_update_tint()


func _unhandled_input(event: InputEvent) -> void:
	for i in Game.TOOLS.size():
		if event.is_action_pressed("tool_%d" % (i + 1)):
			Game.select_tool(i)
	if event.is_action_pressed("next_tool"):
		Game.select_tool(Game.tool_index + 1)
	if event.is_action_pressed("next_seed"):
		Game.cycle_seed()


func _on_day_started() -> void:
	player.position = HOME
	player.facing = Vector2i.DOWN
	player.queue_redraw()
	_update_tint()


func _update_tint() -> void:
	var m := Game.hour * 60 + Game.minute
	for i in range(1, TINT.size()):
		if m <= TINT[i][0]:
			var a: Array = TINT[i - 1]
			var b: Array = TINT[i]
			var c: Color = a[1].lerp(b[1], float(m - a[0]) / float(b[0] - a[0]))
			if Game.weather_today in ["rain", "storm"]:
				c = c.darkened(0.2)
			tint.color = c
			return


func _on_action(kind: String, c: Vector2i) -> void:
	if kind == "interact":
		_interact(c)
	else:
		_use_tool(c)


func _interact(c: Vector2i) -> void:
	var farm := Game.farm
	match farm.fixed_at(c):
		"bin":
			var got := Game.ship_produce()
			Game.message.emit("Put %d G of crops in the bin" % got if got > 0 else "Nothing to ship")
		"door":
			Game.sleep()
		"stand":
			_buy_seeds()
		_:
			var id := farm.harvest(c)
			if id != "":
				Game.add_item(id)
				Game.message.emit("Picked a %s" % Game.crops[id].name)


func _buy_seeds() -> void:
	var s := Game.current_seed()
	var data: Dictionary = Game.crops[s]
	var price := int(data.seed_price)
	if not (Game.season_name() in data.seasons):
		Game.message.emit("%s seeds are not sold in %s" % [data.name, Game.season_name()])
	elif Game.money < price:
		Game.message.emit("Not enough money (%d G)" % price)
	else:
		Game.money -= price
		Game.add_item("seeds:" + s)
		Game.message.emit("Bought %s seeds for %d G" % [data.name, price])


func _use_tool(c: Vector2i) -> void:
	var farm := Game.farm
	var tool := Game.current_tool()
	if tool == "can" and farm.fixed_at(c) == "pond":
		Game.water = Game.WATER_MAX
		Game.message.emit("Filled the watering can")
		Game.changed.emit()
		return
	if tool == "seeds":
		var s := Game.current_seed()
		if Game.count("seeds:" + s) == 0:
			Game.message.emit("No %s seeds (Q = next seed)" % Game.crops[s].name)
			return
		if not Game.spend_stamina(Game.TOOL_COST.seeds):
			return
		var n := farm.sow(c, s, Game.season_name())
		if n > 0:
			Game.take_item("seeds:" + s)
			Game.message.emit("Sowed %d cells" % n)
		elif not (Game.season_name() in Game.crops[s].seasons):
			Game.message.emit("%s won't grow in %s" % [Game.crops[s].name, Game.season_name()])
		return
	if tool == "can" and Game.water == 0:
		Game.message.emit("The can is empty. Fill it at the pond.")
		return
	# A swing always costs stamina, even when it hits nothing.
	if not Game.spend_stamina(Game.TOOL_COST[tool]):
		return
	match tool:
		"hoe":
			farm.till(c)
		"can":
			Game.water -= 1
			farm.water_cell(c)
			Game.changed.emit()
		_:
			if farm.hit(c, tool) == 1:
				Game.message.emit("It's tough. Keep hitting.")
