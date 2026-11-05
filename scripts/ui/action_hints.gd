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
	"fodder": "Feed", "barn_tools": "Look", "barn_gate": "Gate"}


## {interact, use_tool} for the farmer on cell `origin` facing `facing`.
static func pick(origin: Vector2i, facing: Vector2i) -> Dictionary:
	if Game.fishing.active():
		return {"interact": "Reel in", "use_tool": "Reel in"}
	if Game.animals.dog.held:
		return {"interact": "Put down", "use_tool": "Put down"}
	var c := origin + facing
	var out := {"interact": interact_verb(origin, facing), "use_tool": tool_verb(origin, facing)}
	if Game.holding() and Game.maps.on_farm():
		if out.interact == "":
			out.interact = "Throw"
		if out.use_tool == "":
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
	if CoopActions.in_coop() and CoopActions.animal_at(c) >= 0 \
			or BarnActions.in_barn() and Game.animals.animal_at("barn", c) >= 0:
		return "Tend"
	if Game.maps.mine_floor != null and not Game.holding() and Game.maps.mine_floor.loose.has(c):
		return "Pick up"
	if Game.forage_here().has(c):
		return "Pick"
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
	if Game.holding():
		return ""
	if Game.farm.item_at(c) != "":
		return "Pick up"
	return "Harvest" if Game.farm.is_ripe(c) else ""


## The tool button: eat, cast, or the tool's own work where tools work.
static func tool_verb(origin: Vector2i, facing: Vector2i) -> String:
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
	return TOOL_VERBS.get(tool, "") if Game.maps.on_farm() else ""


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
