class_name FarmActions
extends RefCounted
## Turns the player's actions (tool / interact from the farmer's cell and facing) into farm
## rules. Shared by the 2D and the 3D view.

const T := 16
const HOME := Vector2(4 * T + 8, 4 * T + 10)   # in front of the door, in player pixels


static func on_action(kind: String, origin: Vector2i, facing: Vector2i, charge := 0) -> void:
	if kind == "interact":
		interact(origin + facing)
	else:
		use_tool(origin, facing, charge)


static func interact(c: Vector2i) -> void:
	var farm := Game.farm
	match farm.fixed_at(c):
		"bin":
			var got := Game.ship_produce()
			if got > 0:
				Game.message.emit("Put %d G of crops in the bin" % got)
			else:
				Game.talk("bin_note")   # nothing to ship: read the note on the lid
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


## A tool from the farmer's cell `origin` towards `facing`. `charge` is the charge step the
## button was held to; it picks the area and the stamina cost from data/tools.json.
static func use_tool(origin: Vector2i, facing: Vector2i, charge := 0) -> void:
	var farm := Game.farm
	var tool := Game.current_tool()
	var c := origin + facing
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
		if not Game.spend_stamina(Game.SEED_COST):
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
	var rule := Game.charge_rule(tool, charge)
	var cells := farm.area_cells(origin, facing, rule.area)
	# A swing always costs stamina, even when it hits nothing.
	if not Game.spend_stamina(int(rule.stamina)):
		return
	match tool:
		"hoe":
			for cell in cells:
				farm.till(cell)
		"can":
			# Water per cell the can pours on, nearest rows first; a short can stops early.
			var per := int(Game.tools_data.tools.can.get("water_per_cell", 1))
			cells.resize(mini(cells.size(), Game.water / per))
			Game.water -= cells.size() * per
			for cell in cells:
				farm.water_cell(cell)
			Game.changed.emit()
		_:
			var tough := false
			for cell in cells:
				tough = farm.hit(cell, tool, int(rule.get("hits", 1))) == 1 or tough
			if tough:
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
