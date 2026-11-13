class_name ActionHints
extends RefCounted
## What the two action buttons would do right now, for the HUD's key hints ("E Talk",
## "Space Water"). Asks the same questions FarmActions.on_action does, in the same order,
## but only looks: nothing here changes the game. "" means the button has nothing to show.

## The tool button's word for each tool where tools work (the farm, a mine floor).
const TOOL_VERBS := {"hoe": "Till", "can": "Water", "sickle": "Cut", "hammer": "Break",
	"axe": "Chop", "seeds": "Sow"}
## Map props by their `use` (and the coop / barn furniture), as the interact button sees them.
const USE_VERBS := {"sleep": "Sleep", "shop": "Shop", "storage": "Open", "cook": "Cook",
	"ribbons": "Look", "examine": "Look", "feed_box": "Feed", "feed_sack": "Look",
	"nest": "Take egg", "incubator": "Incubator", "hatch": "Hatch", "fodder_box": "Feed",
	"fodder": "Feed", "barn_tools": "Look", "barn_gate": "Gate", "cradle": "Look"}


## How far (cells) the feet lean off the middle of their cell, across the facing, before E also
## reaches the cell beside the one in front; how far from the feet a villager a step further on
## may stand and still be talked to (playtest 2026-11-13).
const LEAN := 0.1
const TALK_REACH := 1.6


## The cell E works from (playtest 2026-11-13: E only worked with the farmer lined up to the
## pixel): `origin` when the cell in front has something to use or talk to; else the cell beside
## `origin` on the side the feet (`feet`, in cells) lean towards, when the cell in front of that
## one has something (a door there is left alone: doors are walked into); else, for a villager
## one more step on within TALK_REACH of the feet, the cell in front. `origin` when nothing is found.
static func reach(origin: Vector2i, facing: Vector2i, feet: Vector2) -> Vector2i:
	if usable(origin, facing):
		return origin
	var across := Vector2i(absi(facing.y), absi(facing.x))
	var lean := (feet - Vector2(origin) - Vector2(0.5, 0.5)).dot(Vector2(across))
	if absf(lean) >= LEAN:
		var side := origin + across * int(signf(lean))
		if Game.maps.door_at(side + facing).is_empty() and usable(side, facing):
			return side
	var ahead := origin + facing
	var w := Talk.facing_villager(Game.maps.current(), ahead, facing, Game.day_minutes(), Game.trigger_state(ahead))
	if not w.is_empty() and feet.distance_to(w.pos) <= TALK_REACH:
		return ahead
	return origin


## The feet of the farmer on cell `origin` in cells: where they stand (Game.maps.pos) when that is on
## `origin`, else the cell's middle (a test or a script naming only the cell).
static func feet_on(origin: Vector2i) -> Vector2:
	var p: Vector2 = Game.maps.pos / 16.0
	return p if Vector2i(p.floor()) == origin else Vector2(origin) + Vector2(0.5, 0.5)


## The cell E acts on when reach moved it off the tool's cell (the side cell, or a villager a step
## on): the target marker shows there, subtler than the tool's bracket (playtest 2026-11-13).
## NO_MARK when E works from the farmer's own cell (the tool's cell is the one), when the HUD's
## interact word is empty, or when the hands or a line are doing something else (pick returns
## early for those).
const NO_MARK := Vector2i(-99999, -99999)

static func reach_mark(origin: Vector2i, facing: Vector2i, feet: Vector2) -> Vector2i:
	if Game.fishing.active() or Game.animals.dog.held or Game.baby_held or Game.crawler_held():
		return NO_MARK
	var at := reach(origin, facing, feet)
	if at == origin or interact_verb(at, facing) == "":
		return NO_MARK
	return at + facing


## Does E facing `facing` from cell `origin` have something to do: a word to show, or an "examine"
## row of the map's trigger table for the cell in front?
static func usable(origin: Vector2i, facing: Vector2i) -> bool:
	if interact_verb(origin, facing) != "":
		return true
	var tree := Engine.get_main_loop() as SceneTree
	var p := tree.get_first_node_in_group(EventPlayer.GROUP) as EventPlayer if tree != null else null
	return p != null and p.can_examine(origin + facing)


## {interact, use_tool} for the farmer on cell `origin` facing `facing`; the interact word is
## for the cell E reaches from the feet (`feet`, in cells; reach).
static func pick(origin: Vector2i, facing: Vector2i, feet := Vector2(-1, -1)) -> Dictionary:
	if Game.fishing.active():
		return {"interact": "Reel in", "use_tool": "Reel in"}
	if Game.animals.dog.held:
		return {"interact": "Put down", "use_tool": "Put down"}
	var c := origin + facing
	if Game.baby_held:   # only the cradle takes the baby back (BabyActions)
		var back := "Put back" if Game.is_cradle(c) else ""
		return {"interact": back, "use_tool": back}
	if Game.crawler_held():   # set down in front, or back where they were (BabyActions)
		return {"interact": "Put down", "use_tool": "Put down"}
	var at := reach(origin, facing, feet if feet.x >= 0.0 else feet_on(origin))
	var out := {"interact": interact_verb(at, facing), "use_tool": tool_verb(origin, facing)}
	if Game.holding() and Game.maps.on_farm():
		if out.interact == "":
			out.interact = "Throw"
		if out.use_tool == "":
			out.use_tool = "Put down"
	elif Game.holding() and Game.in_greenhouse() and out.use_tool == "":
		out.use_tool = "Put down"
	return out


## The interact button: talk to the villager in front, else what stands on the cell faced.
static func interact_verb(origin: Vector2i, facing: Vector2i) -> String:
	var m := Game.maps.current()
	var w := Talk.facing_villager(m, origin, facing, Game.day_minutes(), Game.trigger_state(origin))
	if not w.is_empty():
		return "Give" if Game.holding() else "Talk"
	var c := origin + facing
	var door := Game.maps.door_at(c)
	if not door.is_empty():
		if door.get("down", false):
			return "Go down"
		return "Enter" if door.to != "" else "Look"
	if BarnActions.in_barn() and Game.holding() and Game.held == Game.animals.breed_item():
		var cow := Game.animals.animal_at("barn", c)   # the cord: "Tie" where it would take, else the usual refusal ("Tend")
		if cow >= 0 and Game.animals.why_not_breed(cow) == "":
			return "Tie"
	if CoopActions.in_coop() and CoopActions.animal_at(c) >= 0 \
			or BarnActions.in_barn() and Game.animals.animal_at("barn", c) >= 0:
		return "Tend"
	if Game.maps.mine_floor != null and not Game.holding() and Game.maps.mine_floor.loose.has(c):
		return "Pick up"
	if Game.forage_here().has(c):
		return "Pick"
	var scion := Game.scion_fruit_left(c)   # Kiku's tree: a pick while fruit hangs, else the birds' line (on_action)
	if scion > 0:
		return "Pick"
	if scion == 0:
		return "Look"
	var fid := Game.festival_now()
	if fid != "":
		if Festivals.at_game(fid, c):
			return "Play"
		if Festivals.at_table(fid, c):
			return "Enter contest"
		if Festivals.stall_at(fid, c) != "":
			return "Shop"
	var use := str(m.prop_at(c).get("use", ""))
	if USE_VERBS.has(use):
		return USE_VERBS[use]
	if Game.in_greenhouse() and not Game.holding():   # the beds, as the field (FarmActions.interact)
		var f := Game.field()
		var bed := Game.field_cell(c)
		if f.item_at(bed) != "":
			return "Pick up"
		return "Harvest" if f.is_ripe(bed) else ""
	if not Game.maps.on_farm():
		return ""
	if Game.animals.dog.cell == c:
		return "Pet"
	match Game.farm.fixed_at(c):
		"bin":
			return "Ship"
		"chest":
			return "Open"
		"stand":
			return "Buy"
		"silo":   # the stores, since no other screen shows them
			return "Fodder %d, grass %d" % [int(Game.animals.silo.fodder), int(Game.animals.silo.grass)]
	if Game.holding():
		return ""
	if Game.farm.item_at(c) != "":
		return "Pick up"
	return "Harvest" if Game.farm.is_ripe(c) else ""


## The tool button: eat, cast, or the tool's own work where tools work.
static func tool_verb(origin: Vector2i, facing: Vector2i) -> String:
	if not Game.holding() and Game.is_cradle(origin + facing):
		return "Hold"   # lifts the baby (BabyActions.lift, before the tool's own work)
	if not Game.holding() and not Game.crawler_at(origin + facing).is_empty():
		return "Hold"   # lifts the crawler (BabyActions.lift_crawler)
	var tool := Game.current_tool()
	if tool == "food":
		if Game.edible(Game.held) or Game.count("food:" + Game.current_food()) > 0:
			return "Eat"
		return ""
	if tool == "rod":
		return "Cast" if not Game.holding() and Game.water_ahead(origin, facing) != Vector2i(-1, -1) else ""
	if Game.holding():
		return ""
	var f := Game.maps.mine_floor
	if f != null:   # down the mine only the rock or soft spot in front takes a tool
		var c := origin + facing
		if tool == "hammer" and f.rocks.has(c):
			return "Break"
		return "Dig" if tool == "hoe" and f.soft.has(c) else ""
	if tool == "can" and Game.maps.current().prop_at(origin + facing).get("use", "") == "water":
		return "Fill"   # the greenhouse's water tub
	return TOOL_VERBS.get(tool, "") if Game.maps.on_farm() or Game.in_greenhouse() else ""


## The button shown for an action: its first bound key ("E", "Space"), or, while the pad was the
## last device used (Game.pad_active), the player's own pad button ("A" / "Cross", "LB" / "L1"). An action with
## no pad button shows its key.
static func key_text(action: String) -> String:
	var controls: Controls = Game.settings.controls if Game.settings != null else null
	if controls == null:
		return ""
	if Game.pad_active and controls.pad_button(action) != Controls.NO_BUTTON:
		return Game.pad_text(controls.pad_button(action))
	for k in controls.keys(action):
		if k != KEY_NONE:
			return Controls.key_name(k)
	return ""
