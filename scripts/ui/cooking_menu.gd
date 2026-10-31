class_name CookingMenu
extends RefCounted
## The cooking screen's list and cursor, without any drawing (CookingScreen draws it,
## headless tests check it). The rows are the recipes the farmer knows (Cooking.known_ids),
## in data order; up / down pick one, choose() cooks it once through the game `g` (Game.cook)
## and returns its note.

var g                       # the Game (the autoload, or a test's)
var cursor := 0
var last_ok := false        # did the last choose() cook something


func _init(game) -> void:
	g = game


## {id, dish (rucksack item), makes, ready (everything is there), missing (needs not met)}.
func rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in Cooking.known_ids(g.flags):
		var miss := Cooking.missing(id, g.inventory)
		out.append({"id": id, "dish": Cooking.dish(id), "makes": Cooking.makes(id), "ready": miss.is_empty(), "missing": miss})
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
	var row := current()
	if row.is_empty():
		return ""
	var parts: Array[String] = []
	for need in Cooking.recipe(row.id).get("needs", []):
		parts.append("%d %s (%d)" % [int(need.n), need_name(need), Cooking.have(need, g.inventory)])
	return ", ".join(parts)


## A need's name: the item's own, or the group's (any fish, any egg).
func need_name(need: Dictionary) -> String:
	if need.has("item"):
		return g.item_name(need.item)
	return "any " + String(Cooking.data().get("groups", {}).get(need.group, {}).get("name", need.group))


## Enter: cooks the cursor's recipe once.
func choose() -> String:
	var row := current()
	last_ok = false
	if row.is_empty():
		return ""
	var r: Dictionary = g.cook(row.id)
	last_ok = bool(r.ok)
	return str(r.note)
