class_name FarmActions
extends RefCounted
## Turns the player's actions (tool / interact from the farmer's cell and facing) into farm
## rules. Shared by the 2D and the 3D view.

const T := 16
const HOME := Vector2(4 * T + 8, 4 * T + 10)   # in front of the door, in player pixels
const DEMO_FIRST := 0.3   # `--swing=<tool>`: seconds to the first swing (its hit about frame 13 at 30 fps)
const DEMO_EVERY := 0.9   # and between swings

static var _demo_wait := DEMO_FIRST


## A view's Player hooked to the actions, and the view-side start flag `--talk=<villager>`.
## Both views call this once their map is built.
static func connect_view(player: Player) -> void:
	player.action.connect(on_action)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--talk="):   # `-- --demo --map=town --time=14:30 --talk=tome`: E facing her
			talk_flag.call_deferred(player, arg.trim_prefix("--talk="))


## The `--talk=<villager>` screenshot flag: the farmer stands below them, facing up, and talks
## (`--talk=child` the little one about the house).
static func talk_flag(player: Player, id: String) -> void:
	var w := Villagers.where(id, Game.day_minutes(), Game.trigger_state(Vector2i.ZERO))
	if w.get("map", "") != Game.maps.id:
		push_warning("--talk: %s is not on this map now" % id)
		return
	# Below them, or the first free side (left, right, above) when a wall is below (the crawler on the mat).
	var side := Vector2i.DOWN
	var m := Game.maps.current()
	for d in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		if m == null or m.farm or not m.is_solid(Vector2i(w.pos.floor()) + d):
			side = d
			break
	var c := Vector2i(w.pos.floor()) + side
	player.position = Vector2(c * T) + Vector2(T / 2.0, T / 2.0)
	player.facing = -side
	Game.maps.pos = player.position
	Game.maps.facing = player.facing
	on_action("interact", c, player.facing)


## kind "enter" = the farmer walked into a door cell `origin + facing`. Interact facing a
## villager talks to them (or gives them the item overhead). With an item overhead on the
## farm the hands are full: interact throws it, the tool button sets it down. With the dog in
## the arms either button sets it down (DogActions); with the baby, either button facing the
## cradle lays them back and doors wait (BabyActions); the tool button on the cradle lifts them.
## The tool button facing the crawler lifts them too; held, either button sets them down. With the food slot in hand the tool
## button eats an edible item overhead (a crop, an egg, a fish, a dish). Otherwise interact
## first asks the map's trigger table about the spot faced (examine).
static func on_action(kind: String, origin: Vector2i, facing: Vector2i, charge := 0) -> void:
	if Game.fishing.active():   # the line is out: either button reels in
		reel()
	elif Game.animals.dog.held:
		DogActions.held_action(kind, origin + facing)
	elif Game.baby_held:   # the baby in the arms: back into the cradle, nowhere else (BabyActions)
		BabyActions.held_action(kind, origin + facing)
	elif Game.crawler_held():   # the crawler in the arms: set down in front (or where they were), doors wait
		BabyActions.crawler_held_action(kind, origin, facing)
	elif kind == "enter":
		interact(origin + facing)
	elif kind == "interact" and talk_to(origin, facing):
		pass
	elif kind != "interact" and BabyActions.lift(origin + facing):   # the tool button on the cradle
		pass
	elif kind != "interact" and BabyActions.lift_crawler(origin + facing):   # the tool button facing the crawler
		pass
	elif kind != "interact" and Game.current_tool() == "food" and Game.edible(Game.held):
		eat_held()
	elif kind == "interact" and scion_fruit(origin + facing):   # Kiku's fruiting tree takes the press even with hands full (never a throw at it)
		pass
	elif Game.holding() and Game.maps.on_farm():
		if kind == "interact":
			throw(origin, facing)
		else:
			put_down(origin + facing)
	elif Game.holding() and Game.in_greenhouse() and kind != "interact":   # set down on a bed (no throwing under glass)
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
		Game.message.emit("No room to throw it.")
		return
	Sfx.play("hold_throw")
	var name := item_name(t.item)
	match t.result:
		"ship":
			_after_flight(func(): Sfx.play("bin_lid"))
			Game.message.emit("Shipped: %s (%d G)." % [name, t.value])
		"lost":
			_after_flight(func(): Sfx.play("hold_splash"))
			Game.message.emit(("The %s swam away." if t.item.begins_with("fish:") else "The %s sank in the pond.") % name)
		_:
			_after_flight(func(): Sfx.play("hold_land"))


static func put_down(c: Vector2i) -> void:
	if Game.put_down(c):
		Sfx.play("hold_land")
	else:
		Game.message.emit("No room to put it down.")


static func item_name(id: String) -> String:
	return Game.item_name(id)


## The rod: a tap casts at the water in front (farm pond or a village pond).
static func cast(origin: Vector2i, facing: Vector2i) -> void:
	match Game.cast_line(origin, facing):
		"cast":
			Sfx.play("tool_rod")
		"hands_full":
			Game.message.emit("Your hands are full.")
		"no_water":
			Game.message.emit("Cast the rod at water.")
		"race_wait":
			Game.message.emit("Wait for the call!" if not Game.race.over() else "Time is up!")


static func reel() -> void:
	var r := Game.reel_in()
	match r.result:
		"catch":
			Sfx.play("fish_catch")
			if r.get("race", false):
				Game.message.emit("Caught: %s! %d in the creel." % [item_name(r.fish), Game.race.score()])
			else:
				Game.message.emit("Caught: %s!" % item_name(r.fish))
		"none":
			Game.message.emit("Nothing on the hook.")
		_:
			Game.message.emit("Reeled in the line.")


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


## Using what is in front: a door first (on any map), then a festival's judges' table or
## stall, the map's props (the futon, a shop counter), or on the farm the bin, the seed stand and ripe crops.
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
			Game.message.emit("Picked up the %s." % item_name(found))
			return
	if forage(c):
		return
	if scion_fruit(c):
		return
	if festival_spot(c):
		return
	if examine_prop(c):
		return
	if BabyActions.look_in(c):   # the baby's cradle: a line by the clock
		return
	if Game.in_greenhouse():   # the beds: an item lying there, else a ripe crop, goes up overhead
		var crop := _ripe_here(c)
		var got := Game.pick_up(c)
		if got != "":
			if crop:
				_pick_puff(c)
			Sfx.play("pick")
			Game.message.emit("Picked up: %s." % item_name(got))
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
			"cook":   # the kitchen corner's stove and cupboard
				Game.open_cooking()
			"ribbons":   # the farmhouse's board of contest ribbons
				Game.message.emit(Keepsakes.board_text(Game.flags))
		return
	if DogActions.interact(c):
		return
	var farm := Game.farm
	match farm.fixed_at(c):
		"bin":
			Sfx.play("bin_lid")
			var got := Game.ship_produce()
			if got > 0:
				Game.message.emit("Put %d G of crops in the bin." % got)
			else:
				Game.talk("bin_note")   # nothing to ship: read the note on the lid
		"chest":
			Game.open_inventory("storage")
		"silo":
			use_silo()
		"stand":
			buy_food() if Game.current_tool() == "food" else buy_seeds()
		_:
			# An item on the ground, else a ripe crop, goes up overhead.
			var crop := _ripe_here(c)
			var id := Game.pick_up(c)
			if id != "":
				if crop:
					_pick_puff(c)
				Sfx.play("pick")
				Game.message.emit("Picked up: %s." % item_name(id))


## E at the fodder silo: all the fodder it has made goes to the barn's loft.
static func use_silo() -> void:
	var a := Game.animals
	var n := a.silo_take()
	if n > 0:
		Sfx.play("feed_pour")
		Game.message.emit("Carried %d fodder from the silo to the barn's loft (%d there now)." % [n, a.stock_of("barn")])
	else:
		Game.message.emit(Lang.join(["The silo has no fodder yet.", "Cut grass turns to fodder overnight (%d bundles waiting)." % a.silo.grass]))


## Something growing wild on `c` (data/forage.json) is picked: overhead, or into the rucksack
## while the hands are full. Returns whether a wild spot was there.
static func forage(c: Vector2i) -> bool:
	var r := Game.forage_pick(c)
	if r.id == "":
		return false
	match r.to:
		"hand":
			Sfx.play("pick")
			Game.message.emit("Picked the %s." % item_name(r.id).to_lower())
		"rucksack":
			Sfx.play("pick")
			Game.message.emit("Put the %s in the rucksack." % item_name(r.id).to_lower())
		_:
			Game.message.emit("No room for the %s." % item_name(r.id).to_lower())
	return true


## Kiku's grown persimmon tree on `c` in fall (data/scion.json pick): a persimmon picked like
## a wild thing, a couple a day. Returns whether the tree bears fruit there.
static func scion_fruit(c: Vector2i) -> bool:
	var r := Game.scion_pick(c)
	if r.id == "":
		return false
	var name := item_name(r.id).to_lower()
	match r.to:
		"hand":
			Sfx.play("pick")
			Game.message.emit("Picked the %s." % name)
		"rucksack":
			Sfx.play("pick")
			Game.message.emit("Put the %s in the rucksack." % name)
		"none":
			Game.message.emit("The rest are for the birds.")
		_:
			Game.message.emit("No room for the %s." % name)
	return true


## A map prop with use "examine" (on any map, the farm too: Hachiro's door bell): plays
## its `sound` (data/sfx.json) and shows its `message`.
static func examine_prop(c: Vector2i) -> bool:
	var prop := Game.maps.current().prop_at(c)
	if prop.get("use", "") != "examine":
		return false
	if prop.has("sound"):
		Sfx.play(str(prop.sound))
	if str(prop.get("message", "")) != "":
		Game.message.emit(str(prop.message))
	return true


## Today's festival, while it is on: its judges' table (enter the contest with the item
## overhead, or hear what it takes), the prop of its game (the mortar: start the mochi
## pounding; the race flag: start the fishing race; the goldfish tub: start the scoop) or its
## stall (opens it like a shop).
static func festival_spot(c: Vector2i) -> bool:
	var fid := Game.festival_now()
	if fid == "":
		return false
	if Festivals.at_game(fid, c):
		Game.start_game()
		return true
	if Festivals.at_table(fid, c):
		var r := Game.enter_contest()
		if r.ok:
			Sfx.play("pick")
		return true
	var stall := Festivals.stall_at(fid, c)
	return stall != "" and Game.open_stall(stall)


static func buy_seeds() -> void:
	var s := Game.current_seed()
	var data: Dictionary = Game.crops[s]
	var price := int(data.seed_price)
	if not (Game.season_name() in data.seasons):
		Game.message.emit("%s seeds are not sold in %s." % [data.name, Game.season_name()])
	elif Game.money < price:
		Game.message.emit("Not enough money (%d G)." % price)
	elif not Game.can_carry("seeds:" + s):
		Game.message.emit("Your rucksack is full.")
	else:
		Game.money -= price
		Game.add_item("seeds:" + s)
		Game.message.emit("Bought %s seeds for %d G." % [data.name, price])


## With the food slot in hand the stand sells the food in hand instead of seeds.
static func buy_food() -> void:
	var id := Game.current_food()
	var data: Dictionary = Game.foods.get(id, {})
	var price := int(data.get("price", 0))
	if not data.get("shop", false):
		Game.message.emit("The stand doesn't sell %s." % String(data.get("name", id)).to_lower())
	elif Game.money < price:
		Game.message.emit("Not enough money (%d G)." % price)
	else:
		Game.money -= price
		Game.add_item("food:" + id)
		Game.message.emit("Bought %s for %d G." % [String(data.name).to_lower(), price])


## The item overhead, eaten with the food slot in hand.
static func eat_held() -> void:
	var item := Game.held
	if Game.eat_item(item, ["hand"]).ok:
		Sfx.play(Game.item_sound(item))


## A tool from the farmer's cell `origin` towards `facing`. `charge` is the charge step the
## button was held to; it picks the area and the stamina cost from data/tools.json. Food
## works on every map.
static func use_tool(origin: Vector2i, facing: Vector2i, charge := 0) -> void:
	if Game.current_tool() == "rod":
		cast(origin, facing)
		return
	if Game.current_tool() == "food":
		var id := Game.current_food()
		if Game.eat(id):
			Sfx.play(Game.eat_sound(id))
		return
	if Game.maps.mine_floor != null:
		mine(origin, facing, charge)
		return
	if not Game.maps.on_farm() and not Game.in_greenhouse():
		return   # tools only work on the farm and in the greenhouse's beds
	var farm := Game.field()
	var tool := Game.current_tool()
	var refill: bool = Game.maps.current().prop_at(origin + facing).get("use", "") == "water"   # the greenhouse's water tub
	var c := Game.field_cell(origin + facing)
	origin = Game.field_cell(origin)
	if tool == "":
		Game.message.emit("No tool in hand (I = rucksack).")
		return
	if tool == "can" and (refill or farm.fixed_at(c) == "pond"):
		Game.water = Game.WATER_MAX
		Sfx.play("pond_fill")
		Game.message.emit("Filled the watering can.")
		Game.changed.emit()
		return
	if tool == "seeds":
		var s := Game.current_seed()
		if Game.count("seeds:" + s) == 0:
			Game.message.emit("No %s seeds (Q = next seed)." % Game.crops[s].name)
			return
		if not Game.spend_stamina(Game.SEED_COST):
			return
		var n := farm.sow(c, s, Game.season_name())
		if n > 0:
			Game.take_item("seeds:" + s)
			Sfx.play("tool_seeds")
			Game.message.emit("Sowed %d cells." % n)
		elif not farm.sheltered and not (Game.season_name() in Game.crops[s].seasons):
			Game.message.emit("%s won't grow in %s." % [Game.crops[s].name, Game.season_name()])
		return
	if tool == "can" and Game.water == 0:
		Game.message.emit("The can is empty. Fill it at the pond.")
		return
	var rule := Game.charge_rule(tool, charge)
	var cells := farm.area_cells(origin, facing, rule.area)
	# A swing always costs stamina, even when it hits nothing.
	if not Game.spend_stamina(Game.swing_stamina(tool, charge)):
		return
	Sfx.play("tool_" + tool)
	var worked := false
	var hits := {}   # what each cell met, for the swing's effect: target -> field cells (ToolFxRules)
	var fx_opts := {}
	match tool:
		"hoe":
			for cell in cells:
				var tilled := farm.till(cell)
				worked = tilled or worked
				_fx_add(hits, "soil" if tilled else "miss", cell)
		"can":
			# Water per cell the can pours on, nearest rows first; a short can stops early.
			var per := int(Game.tools_data.tools.can.get("water_per_cell", 1))
			cells.resize(mini(cells.size(), Game.water / per))
			Game.water -= cells.size() * per
			for cell in cells:
				worked = farm.water_cell(cell) or worked
				_fx_add(hits, "water", cell)
			Game.changed.emit()
		_:
			var tough := false
			var grass := 0   # weeds the sickle cleared: grass for the silo, once it stands
			for cell in cells:
				var weed: bool = farm.in_bounds(cell) and farm.cell(cell).obj == FarmGrid.Obj.WEED
				var got := farm.hit(cell, tool, int(rule.get("hits", 1)))
				tough = got == 1 or tough
				worked = got > 0 or worked
				grass += int(got == 2 and weed and tool == "sickle")
				_fx_add(hits, {"sickle": "weed", "axe": "wood", "hammer": "rock"}.get(tool, "miss") if got > 0 else "miss", cell)
			fx_opts = {"hard": int(rule.get("hits", 1)) > 1, "toward": grass > 0 and Game.animals.silo_built()}
			if tough:
				Game.message.emit("It's tough. Keep hitting.")
			if grass > 0 and Game.animals.silo_built():
				var put := Game.animals.silo_cut(grass)
				if put > 0:
					Game.message.emit("Grass for the silo: %d bundles in the pile." % Game.animals.silo.grass)
				else:
					Game.message.emit("The silo's grass pile is full.")
	_swing_fx(tool, hits, c, origin, facing, fx_opts)
	# Every swing teaches the tool a little, one that did some work more.
	Game.add_tool_exp(tool, Game.swing_exp(worked))


static func _fx_add(hits: Dictionary, target: String, cell: Vector2i) -> void:
	if not hits.has(target):
		hits[target] = []
	hits[target].append(cell)


## Starts the farmer's swing with what it throws (ToolFxRules): a group of bits for each kind of
## thing met, on its cells (map cells: the greenhouse's beds start at its plots corner); a swing
## that did nothing anywhere puffs a little dust on the first cell in front (`front`, a field cell).
static func _swing_fx(tool: String, hits: Dictionary, front: Vector2i, origin: Vector2i, facing: Vector2i, opts := {}) -> void:
	var corner := Game.maps.current().plots.position if Game.in_greenhouse() else Vector2i.ZERO
	var outdoors := Game.maps.on_farm()
	var wet := WetRules.wetness_now(Game, Game.maps.current())
	var ground := ToolFxRules.ground_state(Game.snow_cover / 100.0 if outdoors else 0.0, wet)
	opts = opts.duplicate()
	opts.wet = wet
	var did := hits.keys().any(func(k): return k != "miss")
	if hits.is_empty():
		hits = {"miss": [front]}
	var bursts := []
	for target in hits:
		if target == "miss" and did:
			continue
		var on: Array = []
		for cell in (hits[target] if target != "miss" else [hits[target][0]]):
			on.append(cell + corner)
		var fx := ToolFxRules.effect(tool, target, ground, Game.tool_level(tool), opts)
		bursts.append(ToolFxRules.burst(fx, on, Vector2(origin + corner) + Vector2(0.5, 0.6), facing))
	Game.start_swing(tool, bursts)


## Is there a ripe crop (nothing lying on it) on map cell `c` of the field here?
static func _ripe_here(c: Vector2i) -> bool:
	var f := Game.field()
	var fc := Game.field_cell(c)
	return f.in_bounds(fc) and f.item_at(fc) == "" and f.is_ripe(fc)


## A harvest: a small puff of leaves and soil where the crop came out, at once (no swing).
static func _pick_puff(c: Vector2i) -> void:
	var fx := ToolFxRules.effect("", "crop", "dry")
	Game.tool_fx.emit(ToolFxRules.burst(fx, [c], Vector2(c) + Vector2(0.5, 0.5), Vector2i.DOWN))


## Down the mine the hammer breaks rocks and the hoe digs soft spots (Game.mine_swing); the
## other tools do nothing here (food is eaten before this, in use_tool).
static func mine(origin: Vector2i, facing: Vector2i, charge: int) -> void:
	var tool := Game.current_tool()
	var f := Game.maps.mine_floor
	var rule := Game.charge_rule(tool, charge) if tool in ["hammer", "hoe"] else {}
	var before := {}   # what lay on each cell of the swing before it: for the effect
	for c in f.area_cells(origin, facing, rule.get("area", ["@", "#"])):
		before[c] = f.rocks[c].duplicate() if f.rocks.has(c) else ({"soft": f.soft[c]} if f.soft.has(c) else {})
	var r := Game.mine_swing(tool, origin, facing, charge)
	match r.result:
		"hands_full":
			Game.message.emit("Your hands are full (I = rucksack).")
			return
		"wrong_tool":
			Game.message.emit("Use the hammer on rocks and the hoe on soft ground." if tool != "" else "No tool in hand (I = rucksack).")
			return
	_mine_fx(tool, f, before, origin, facing, int(rule.get("hits", 1)) > 1)
	Sfx.play("tool_" + tool)
	if r.worked and tool == "hammer":
		Sfx.play("rock_break")
	var said: Array[String] = []
	for fd in r.finds:
		said.append({"bag": "Found %s.", "hand": "Found %s (rucksack full).", "floor": "Found %s (left it on the ground)."}[fd.to] % item_name(fd.item))
	if not r.finds.is_empty():
		Sfx.play("mine_find")
	if r.hole:
		said.append("A hole leads further down!")
	elif r.tough:
		said.append("It's tough. Keep hitting.")
	if not said.is_empty():
		Game.message.emit(Lang.join(said))


## The swing's effect down the mine: stone (or ice) chips off each rock hit, a spark on a hard blow
## (charged, or the rock still standing), soil from a soft spot dug, and a glint in the find's own
## colour when an ore or a gem comes out; a swing that met nothing puffs dust on the cell in front.
static func _mine_fx(tool: String, f: MineFloor, before: Dictionary, origin: Vector2i, facing: Vector2i, charged: bool) -> void:
	var bursts := []
	var level := Game.tool_level(tool)
	var farmer := Vector2(origin) + Vector2(0.5, 0.6)
	for c in before:
		var was: Dictionary = before[c]
		var target := ""
		var opts := {}
		var find := ""
		if tool == "hammer" and was.has("kind"):
			target = "ice" if was.kind == "ice" else "rock"
			opts.hard = charged or f.rocks.has(c)
			find = str(was.find) if not f.rocks.has(c) else ""
		elif tool == "hoe" and was.has("soft") and not f.soft.has(c):
			target = "soft"
			find = str(was.soft)
		if target == "":
			continue
		var glint: Variant = _find_glint(find)
		if glint != null:
			opts.glint = glint
		bursts.append(ToolFxRules.burst(ToolFxRules.effect(tool, target, "mine", level, opts), [c], farmer, facing))
	if bursts.is_empty():
		bursts.append(ToolFxRules.burst(ToolFxRules.effect(tool, "miss", "mine", level), [origin + facing], farmer, facing))
	Game.start_swing(tool, bursts)


## The glint colour of a mine find (an ore's vein, a gem's shine; data/mine.json items' look), or
## null for a stone, nothing or the hole.
static func _find_glint(find: String) -> Variant:
	if find == "" or find == "stairs":
		return null
	var id := MineFloor.item_id(find).trim_prefix("mine:")
	var item: Dictionary = Game.mine_data.get("items", {}).get(id, {})
	if not str(item.get("kind", "")) in ["ore", "gem"]:
		return null
	var look: Dictionary = item.get("look", {})
	return Color(str(look.get("vein", look.get("shine", look.get("body", "ffffff")))))


## `--swing=<tool>` (hoe, water or can, sickle, axe, hammer): every DEMO_EVERY seconds the farmer
## swings that tool at the cell in front, made ready for it first (bare ground for the hoe, a dry
## tilled cell for the can, a weed, a branch, a rock; down the mine a rock or a soft spot), with
## the stamina and the can topped up. The Player calls it each physics step.
static func demo_tick(player: Player, delta: float) -> void:
	if Game.demo_swing == "" or Game.swinging() or Game.paused():
		return
	_demo_wait -= delta
	if _demo_wait > 0.0:
		return
	_demo_wait = DEMO_EVERY
	var tool := "can" if Game.demo_swing == "water" else Game.demo_swing
	for i in Game.inventory.size("tools"):
		if Game.inventory.id_at("tools", i) == tool:
			Game.select_tool(i)
	if Game.current_tool() != tool:
		push_warning("--swing: no %s in the rucksack" % tool)
		Game.demo_swing = ""
		return
	var at := Player.cell_of(player.position)
	_demo_ready(tool, at + player.facing)
	Game.stamina = Game.max_stamina
	Game.fatigue = 0
	Game.water = Game.WATER_MAX
	use_tool(at, player.facing, 0)


static func _demo_ready(tool: String, c: Vector2i) -> void:
	var f := Game.maps.mine_floor
	if f != null:
		if f.map.in_bounds(c) and not f.map.is_solid(c) and c != f.stairs:
			if tool == "hammer" and not f.rocks.has(c):
				f.rocks[c] = {"kind": "rock", "hits": 1, "done": 0, "find": ""}
			elif tool == "hoe" and not f.soft.has(c) and not f.rocks.has(c):
				f.soft[c] = ""
			f.changed.emit()
		return
	if not Game.maps.on_farm() and not Game.in_greenhouse():
		return
	var field := Game.field()
	var fc := Game.field_cell(c)
	if not field.can_farm(fc):
		return
	var d := field.cell(fc)
	field.items.erase(fc)
	d.crop = ""
	d.stage = 0
	d.hits = 0
	d.obj = {"sickle": FarmGrid.Obj.WEED, "axe": FarmGrid.Obj.BRANCH, "hammer": FarmGrid.Obj.ROCK}.get(tool, FarmGrid.Obj.NONE)
	d.tilled = tool == "can"
	d.wet = false
	field.cells_changed.emit()


## Number keys / Tab / Q (next seed, or next food with the food slot), the same in both views.
static func handle_input(event: InputEvent) -> void:
	for i in Game.TOOLS.size():
		if event.is_action_pressed("tool_%d" % (i + 1)):
			Game.select_tool(i)
	if event.is_action_pressed("next_tool"):
		Game.select_tool(Game.tool_index + 1)
	if event.is_action_pressed("next_seed"):
		Game.cycle_food() if Game.current_tool() == "food" else Game.cycle_seed()
