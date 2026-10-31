class_name TitleMenu
extends RefCounted
## The title screen's choices and cursor, without any drawing, so headless tests can check
## it. Continue is only on when the save slot holds a file that would load.

const ITEMS: Array[String] = ["new", "continue", "quit"]
const LABELS := {"new": "New game", "continue": "Continue", "quit": "Quit"}

var enabled := {"new": true, "continue": false, "quit": true}
var cursor := 0
var why_no_continue := ""   # SaveGame.check's answer when Continue is off


## The menu for the save at `path`; the cursor starts on Continue when there is one.
static func make(game, path := SaveGame.SLOT) -> TitleMenu:
	var m := TitleMenu.new()
	m.why_no_continue = SaveGame.check(game, path)
	m.enabled.continue = m.why_no_continue == ""
	m.cursor = ITEMS.find("continue") if m.enabled.continue else 0
	return m


func current() -> String:
	return ITEMS[cursor]


## Moves the cursor up (-1) or down (+1), wrapping round and skipping items that are off.
func move(step: int) -> void:
	for i in ITEMS.size():
		cursor = posmod(cursor + step, ITEMS.size())
		if enabled[current()]:
			return


## Puts the cursor on `item` (the mouse pointing at it); items that are off are skipped.
func point(item: String) -> bool:
	if not enabled.get(item, false):
		return false
	cursor = ITEMS.find(item)
	return true


## The item to carry out now, or "" when the one under the cursor is off.
func choose() -> String:
	return current() if enabled[current()] else ""
