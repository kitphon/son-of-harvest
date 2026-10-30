class_name FarmActions
extends RefCounted
## Turns the player's actions (tool / interact on a cell) into farm rules.
## Shared by the 2D and the 3D view.

const T := 16
const HOME := Vector2(4 * T + 8, 4 * T + 10)   # in front of the door, in player pixels


static func on_action(kind: String, c: Vector2i) -> void:
	if kind == "interact":
		interact(c)
	else:
		use_tool(c)


static func interact(c: Vector2i) -> void:
	var farm := Game.farm
	match farm.fixed_at(c):
		"bin":
			var got := Game.ship_produce()
			Game.message.emit("Put %d G of crops in the bin" % got if got > 0 else "Nothing to ship")
		"door":
			Game.sleep()
		"stand":
			buy_seeds()
		_:
			var id := farm.harvest(c)
			if id != "":
				Game.add_item(id)
				Game.message.emit("Picked a %s" % Game.crops[id].name)


static func buy_seeds() -> void:
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


static func use_tool(c: Vector2i) -> void:
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


## Number keys / Tab / Q, the same in both views.
static func handle_input(event: InputEvent) -> void:
	for i in Game.TOOLS.size():
		if event.is_action_pressed("tool_%d" % (i + 1)):
			Game.select_tool(i)
	if event.is_action_pressed("next_tool"):
		Game.select_tool(Game.tool_index + 1)
	if event.is_action_pressed("next_seed"):
		Game.cycle_seed()
