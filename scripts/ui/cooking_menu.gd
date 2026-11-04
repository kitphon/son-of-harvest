class_name CookingMenu
extends RefCounted
## The cooking screen's list and cursor, without any drawing (CookingScreen draws it,
## headless tests check it). The rows are the recipes the farmer knows (Cooking.known_ids),
## in data order, ready or not (ingredients and kitchen tools); up / down pick one, choose() cooks it once through the game `g` (Game.cook)
## and returns its note.

var g                       # the Game (the autoload, or a test's)
var cursor := 0
var last_ok := false        # did the last choose() cook something


func _init(game) -> void:
	g = game


## {id, dish (rucksack item), makes, ready (everything is there), missing (needs not met),
## no_tools (kitchen tools not owned)}.
func rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in Cooking.known_ids(g.flags):
		var miss := Cooking.missing(id, g.inventory)
		var kit := Cooking.missing_tools(id, g.kitchen_tools)
		out.append({"id": id, "dish": Cooking.dish(id), "makes": Cooking.makes(id), "ready": miss.is_empty() and kit.is_empty(),
			"missing": miss, "no_tools": kit})
	return out


func current() -> Dictionary:
	var r := rows()
	return r[cursor] if cursor < r.size() else {}


func move(dy: int) -> void:
	var n := rows().size()
	if n > 0:
		cursor = posmod(cursor + dy, n)


## Puts the cursor on row `i` (the mouse). False when there is no such row.
func point(i: int) -> bool:
	if i < 0 or i >= rows().size():
		return false
	cursor = i
	return true


## What one cooking of the cursor's recipe needs, with what there is: "2 Turnip (3)".
func needs_text() -> String:
	return ", ".join(needs_parts())


## needs_text's parts, one per need; `tr`: in the player's language (Lang).
func needs_parts(tr := false) -> Array[String]:
	var row := current()
	var parts: Array[String] = []
	if row.is_empty():
		return parts
	for need in Cooking.recipe(row.id).get("needs", []):
		var part := "%d %s (%d)" % [int(need.n), need_name(need), Cooking.have(need, g.inventory)]
		parts.append(Lang.t(part) if tr else part)
	return parts


## The cursor's recipe's kitchen tools: "" when it needs none, else "Uses Kitchen knife, Clay
## pot", each one not owned marked "(buy at store)" (the Yorozu Store sells it).
func tools_text(tr := false) -> String:
	var row := current()
	if row.is_empty() or Cooking.tools(row.id).is_empty():
		return ""
	var names: Array[String] = []
	for t in Cooking.tools(row.id):
		var n := ("%s (buy at store)" if t in row.no_tools else "%s") % Cooking.tool_name(t)
		names.append(Lang.t(n) if tr else n)
	return (Lang.t("Uses %s") if tr else "Uses %s") % ", ".join(names)


## A row's state at the right of the list: "ready", "needs Clay pot" (the kitchen tool it lacks;
## "needs 2 tools" for more) or "missing" (not enough to cook it).
static func state_text(row: Dictionary) -> String:
	if row.ready:
		return "ready"
	var kit: Array = row.get("no_tools", [])
	if kit.size() == 1:
		return "needs %s" % Cooking.tool_name(kit[0])
	if kit.size() > 1:
		return "needs %d tools" % kit.size()
	return "missing"


## A need's name: the item's own, or the group's (any fish, any egg).
func need_name(need: Dictionary) -> String:
	if need.has("item"):
		return g.item_name(need.item)
	return "any %s" % String(Cooking.data().get("groups", {}).get(need.group, {}).get("name", need.group))


## Enter: cooks the cursor's recipe once.
func choose() -> String:
	var row := current()
	last_ok = false
	if row.is_empty():
		return ""
	var r: Dictionary = g.cook(row.id)
	last_ok = bool(r.ok)
	return str(r.note)
