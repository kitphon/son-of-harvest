class_name FarmActions
extends RefCounted
## Turns the player's actions (tool / interact from the farmer's cell and facing) into farm
## rules. Shared by the 2D and the 3D view.

const T := 16
const HOME := Vector2(4 * T + 8, 4 * T + 10)   # in front of the door, in player pixels


## kind "enter" = the farmer walked into a door cell `origin + facing`. Interact facing a
## villager talks to them (or gives them the item overhead). With an item overhead on the
## farm the hands are full: interact throws it, the tool button sets it down. With the dog in
## the arms either button sets it down (DogActions). Otherwise interact first asks the map's
## trigger table about the spot faced (examine).
static func on_action(kind: String, origin: Vector2i, facing: Vector2i, charge := 0) -> void:
	if Game.fishing.active():   # the line is out: either button reels in
		reel()
	elif Game.animals.dog.held:
		DogActions.held_action(kind, origin + facing)
	elif kind == "enter":
		interact(origin + facing)
	elif kind == "interact" and talk_to(origin, facing):
		pass
	elif Game.holding() and Game.maps.on_farm():
		if kind == "interact":
			throw(origin, facing)
		else:
			put_down(origin + facing)
	elif kind == "interact":
		if not examine(origin + facing):
			interact(origin + facing)
	else:
		use_tool(origin, facing, charge)


## The villager in front (or across a counter) turns to the farmer and talks, takes a gift
## or opens their shop; a "talk" row of the map's trigger table plays its event instead.
static func talk_to(origin: Vector2i, facing: Vector2i) -> bool:
	var w := Talk.facing_villager(Game.maps.current(), origin, facing, Game.day_minutes(), Game.trigger_state(origin))
	if w.is_empty():
		return false
	var p := Game.get_tree().get_first_node_in_group(EventPlayer.GROUP) as EventPlayer
	if p != null and p.talked_to(w.id):
		Villagers.turn(w.id, -facing, Game.day_minutes())
		return true
	if Game.talk_to(w.id, -facing) == "gift":
		Sfx.play("pick")
	return true


## An "examine" row of the map's trigger table for cell `c` plays its event (EventPlayer).
static func examine(c: Vector2i) -> bool:
	var p := Game.get_tree().get_first_node_in_group(EventPlayer.GROUP) as EventPlayer
	return p != null and p.examine(c)


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
			Game.message.emit(("The %s swam away" if t.item.begins_with("fish:") else "The %s sank in the pond") % name)
		_:
			_after_flight(func(): Sfx.play("hold_land"))


static func put_down(c: Vector2i) -> void:
	if Game.put_down(c):
		Sfx.play("hold_land")
	else:
		Game.message.emit("No room to put it down")


static func item_name(id: String) -> String:
	return Game.item_name(id)


## The rod: a tap casts at the water in front (farm pond or a village pond).
static func cast(origin: Vector2i, facing: Vector2i) -> void:
	match Game.cast_line(origin, facing):
		"cast":
			Sfx.play("tool_rod")
		"hands_full":
			Game.message.emit("Your hands are full")
		"no_water":
			Game.message.emit("Cast the rod at water")


static func reel() -> void:
	var r := Game.reel_in()
	match r.result:
		"catch":
			Sfx.play("fish_catch")
			Game.message.emit("Caught a %s!" % item_name(r.fish))
		"none":
			Game.message.emit("Nothing on the hook")
		_:
			Game.message.emit("Reeled in the line")


## Cues from the line while it waits (Game.fishing_event); both views connect this.
static func on_fishing_event(kind: String) -> void:
	match kind:
		"bite":
			Sfx.play("fish_bite")
		"escaped":
			Sfx.play("fish_escape")
			Game.message.emit("It got away...")


## The landing sound waits for the item to come down (data/hold.json flight_seconds).
static func _after_flight(sound: Callable) -> void:
	Game.get_tree().create_timer(float(Game.hold_rules.get("flight_seconds", 0.35))).timeout.connect(sound)


## Using what is in front: a door first (on any map), then the map's props (the futon, a
## shop counter), or on the farm the bin, the seed stand and ripe crops.
static func interact(c: Vector2i) -> void:
	var door := Game.maps.door_at(c)
	if not door.is_empty():
		if door.get("down", false):
			Sfx.play("mine_down")   # the hole to the next mine floor
		elif door.to != "":
			Sfx.play("door_slide")
		Game.use_door(door)
		return
	if CoopActions.interact(c):   # the hens, feed box, nests, incubator and hatch
		return
	if BarnActions.interact(c):   # the cows and sheep, fodder, tools and gate
		return
	if Game.maps.mine_floor != null:   # a find left lying down the mine
		var found := Game.mine_pick_up(c)
		if found != "":
			Sfx.play("pick")
			Game.message.emit("Picked up the %s" % item_name(found))
			return
	if not Game.maps.on_farm():
		var prop := Game.maps.current().prop_at(c)
		match str(prop.get("use", "")):
			"sleep":
				Game.sleep()
			"shop":
				Game.open_shop(str(prop.get("shop", "")))
			"storage":   # the house's chest lid (bigger chest extension): the same storage
				Game.open_inventory("storage")
		return
	if DogActions.interact(c):
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
	if Game.current_tool() == "rod":
		cast(origin, facing)
		return
	if Game.maps.mine_floor != null:
		mine(origin, facing, charge)
		return
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


## Down the mine the hammer breaks rocks and the hoe digs soft spots (Game.mine_swing); food
## still works, the other tools do nothing here.
static func mine(origin: Vector2i, facing: Vector2i, charge: int) -> void:
	var tool := Game.current_tool()
	if tool == "food":
		var id := Game.current_food()
		if Game.eat(id):
			Sfx.play(Game.eat_sound(id))
		return
	var r := Game.mine_swing(tool, origin, facing, charge)
	match r.result:
		"hands_full":
			Game.message.emit("Your hands are full (I = rucksack)")
			return
		"wrong_tool":
			Game.message.emit("Use the hammer on rocks and the hoe on soft ground" if tool != "" else "No tool in hand (I = rucksack)")
			return
	Sfx.play("tool_" + tool)
	if r.worked and tool == "hammer":
		Sfx.play("rock_break")
	var said: Array[String] = []
	for f in r.finds:
		said.append("Found %s%s" % [item_name(f.item), {"bag": "", "hand": " (rucksack full)", "floor": " (left it on the ground)"}[f.to]])
	if not r.finds.is_empty():
		Sfx.play("mine_find")
	if r.hole:
		said.append("A hole leads further down!")
	elif r.tough:
		said.append("It's tough. Keep hitting.")
	if not said.is_empty():
		Game.message.emit(". ".join(said))


## Number keys / Tab / Q (next seed, or next food with the food slot), the same in both views.
static func handle_input(event: InputEvent) -> void:
	for i in Game.TOOLS.size():
		if event.is_action_pressed("tool_%d" % (i + 1)):
			Game.select_tool(i)
	if event.is_action_pressed("next_tool"):
		Game.select_tool(Game.tool_index + 1)
	if event.is_action_pressed("next_seed"):
		Game.cycle_food() if Game.current_tool() == "food" else Game.cycle_seed()
