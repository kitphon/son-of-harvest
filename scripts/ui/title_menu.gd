class_name TitleMenu
extends MenuList
## The title screen's choices (cursor and skipping in MenuList). Continue is only on when
## the save slot holds a file that would load.

const ITEMS: Array[String] = ["new", "continue", "quit"]
const LABELS := {"new": "New game", "continue": "Continue", "quit": "Quit"}

var why_no_continue := ""   # SaveGame.check's answer when Continue is off


func _init() -> void:
	super(ITEMS)
	enabled = {"new": true, "continue": false, "quit": true}


## The menu for the save at `path`; the cursor starts on Continue when there is one.
static func make(game, path := "") -> TitleMenu:
	var m := TitleMenu.new()
	m.why_no_continue = SaveGame.check(game, path)
	m.enabled.continue = m.why_no_continue == ""
	m.cursor = ITEMS.find("continue") if m.enabled.continue else 0
	return m
