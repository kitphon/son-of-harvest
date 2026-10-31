class_name MenuList
extends RefCounted
## A list of choices and a cursor, without any drawing, so headless tests can check it.
## Items that are off are skipped by the keys and the mouse. The title menu and the pause
## menu both use it.

var items: Array[String] = []
var enabled: Dictionary = {}   # item -> on; an item missing here is on
var cursor := 0


func _init(list: Array[String] = []) -> void:
	items = list.duplicate()


func is_on(item: String) -> bool:
	return items.has(item) and enabled.get(item, true)


func current() -> String:
	return items[cursor] if cursor < items.size() else ""


## Moves the cursor up (-1) or down (+1), wrapping round and skipping items that are off.
func move(step: int) -> void:
	for i in items.size():
		cursor = posmod(cursor + step, items.size())
		if is_on(current()):
			return


## Puts the cursor on `item` (the mouse pointing at it); items that are off are skipped.
func point(item: String) -> bool:
	if not is_on(item):
		return false
	cursor = items.find(item)
	return true


## The item to carry out now, or "" when the one under the cursor is off.
func choose() -> String:
	return current() if is_on(current()) else ""
