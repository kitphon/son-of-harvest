class_name FarmActions
extends RefCounted
## Turns the player's actions (tool / interact from the farmer's cell and facing) into farm
## rules. Shared by the 2D and the 3D view.

const T := 16
const HOME := Vector2(4 * T + 8, 4 * T + 10)   # in front of the door, in player pixels


## kind "enter" = the farmer walked into a door cell `origin + facing`. With an item
## overhead on the farm the hands are full: interact throws it, the tool button sets it down.
static func on_action(kind: String, origin: Vector2i, facing: Vector2i, charge := 0) -> void:
	if kind == "enter":
		interact(origin + facing)
	elif Game.holding() and Game.maps.on_farm():
		if kind == "interact":
			throw(origin, facing)
		else:
			put_down(origin + facing)
	elif kind == "interact":
		interact(origin + facing)
	else:
		use_tool(origin, facing, charge)


static func throw(origin: Vector2i, facing: Vector2i) -> void:
	var t := Game.throw_held(origin, facing)
	if t.result == "blocked":
		Game.message.emit("No room to throw it")
		return
	Sfx.play("hold_throw")
	var name := item_name(t.item)
	match t.result:
		"ship":
			_after_flight(func(): Sfx.play("bin_lid"))
			Game.message.emit("Shipped a %s (%d G)" % [name, t.value])
		"lost":
			_after_flight(func(): Sfx.play("hold_splash"))
			Game.message.emit("The %s sank in the pond" % name)
		_:
			_after_flight(func(): Sfx.play("hold_land"))


static func put_down(c: Vector2i) -> void:
	if Game.put_down(c):
		Sfx.play("hold_land")
	else:
		Game.message.emit("No room to put it down")


static func item_name(id: String) -> String:
	return Game.crops[id].name if Game.crops.has(id) else id


## The landing sound waits for the item to come down (data/hold.json flight_seconds).
static func _after_flight(sound: Callable) -> void:
	Game.get_tree().create_timer(float(Game.hold_rules.get("flight_seconds", 0.35))).timeout.connect(sound)


## Using what is in front: a door first (on any map), then the map's props (the futon, a
## shop counter), or on the farm the bin, the seed stand and ripe crops.
static func interact(c: Vector2i) -> void:
	var door := Game.maps.door_at(c)
	if not door.is_empty():
		if door.to != "":
			Sfx.play("door_slide")
		Game.use_door(door)
		return
	if not Game.maps.on_farm():
		var prop := Game.maps.current().prop_at(c)
		match str(prop.get("use", "")):
			"sleep":
				Game.sleep()
			"shop":
				Game.open_shop(str(prop.get("shop", "")))
		return
	var farm := Game.farm
	match farm.fixed_at(c):
		"bin":
			Sfx.play("bin_lid")
			var got := Game.ship_produce()
			if got > 0:
				Game.message.emit("Put %d G of crops in the bin" % got)
			else:
				Game.talk("bin_note")   # nothing to ship: read the note on the lid
		"chest":
			Game.open_inventory("storage")
		"stand":
			buy_food() if Game.current_tool() == "food" else buy_seeds()
		_:
			# An item on the ground, else a ripe crop, goes up overhead.
			var id := Game.pick_up(c)
			if id != "":
				Sfx.play("pick")
				Game.message.emit("Picked up a %s" % item_name(id))


static func buy_seeds() -> void:
	var s := Game.current_seed()
	var data: Dictionary = Game.crops[s]
	var price := int(data.seed_price)
	if not (Game.season_name() in data.seasons):
		Game.message.emit("%s seeds are not sold in %s" % [data.name, Game.season_name()])
	elif Game.money < price:
		Game.message.emit("Not enough money (%d G)" % price)
	elif not Game.can_carry("seeds:" + s):
		Game.message.emit("Your rucksack is full")
	else:
		Game.money -= price
		Game.add_item("seeds:" + s)
		Game.message.emit("Bought %s seeds for %d G" % [data.name, price])


## With the food slot in hand the stand sells the food in hand instead of seeds.
static func buy_food() -> void:
	var id := Game.current_food()
	var data: Dictionary = Game.foods.get(id, {})
	var price := int(data.get("price", 0))
	if not data.get("shop", false):
		Game.message.emit("The stand doesn't sell %s" % String(data.get("name", id)).to_lower())
	elif Game.money < price:
		Game.message.emit("Not enough money (%d G)" % price)
	else:
		Game.money -= price
		Game.add_item("food:" + id)
		Game.message.emit("Bought %s for %d G" % [String(data.name).to_lower(), price])


## A tool from the farmer's cell `origin` towards `facing`. `charge` is the charge step the
## button was held to; it picks the area and the stamina cost from data/tools.json.
static func use_tool(origin: Vector2i, facing: Vector2i, charge := 0) -> void:
	if not Game.maps.on_farm():
		return   # tools only work on the farm for now
	var farm := Game.farm
	var tool := Game.current_tool()
	var c := origin + facing
	if tool == "":
		Game.message.emit("No tool in hand (I = rucksack)")
		return
	if tool == "can" and farm.fixed_at(c) == "pond":
		Game.water = Game.WATER_MAX
		Sfx.play("pond_fill")
		Game.message.emit("Filled the watering can")
		Game.changed.emit()
		return
	if tool == "food":
		var id := Game.current_food()
		if Game.eat(id):
			Sfx.play(Game.eat_sound(id))
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
			Sfx.play("tool_seeds")
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
	Sfx.play("tool_" + tool)
	var worked := false
	match tool:
		"hoe":
			for cell in cells:
				worked = farm.till(cell) or worked
		"can":
			# Water per cell the can pours on, nearest rows first; a short can stops early.
			var per := int(Game.tools_data.tools.can.get("water_per_cell", 1))
			cells.resize(mini(cells.size(), Game.water / per))
			Game.water -= cells.size() * per
			for cell in cells:
				worked = farm.water_cell(cell) or worked
			Game.changed.emit()
		_:
			var tough := false
			for cell in cells:
				var got := farm.hit(cell, tool, int(rule.get("hits", 1)))
				tough = got == 1 or tough
				worked = got > 0 or worked
			if tough:
				Game.message.emit("It's tough. Keep hitting.")
	# Every swing teaches the tool a little, one that did some work more.
	Game.add_tool_exp(tool, Game.swing_exp(worked))


## Number keys / Tab / Q (next seed, or next food with the food slot), the same in both views.
static func handle_input(event: InputEvent) -> void:
	for i in Game.TOOLS.size():
		if event.is_action_pressed("tool_%d" % (i + 1)):
			Game.select_tool(i)
	if event.is_action_pressed("next_tool"):
		Game.select_tool(Game.tool_index + 1)
	if event.is_action_pressed("next_seed"):
		Game.cycle_food() if Game.current_tool() == "food" else Game.cycle_seed()
