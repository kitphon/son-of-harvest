class_name PauseMenu
extends RefCounted
## The pause menu's pages and choices, without any drawing (PauseScreen draws it, headless
## tests check it). Pages: "main" (Resume / Save / Settings / Back to title), "settings"
## (one row per setting in data/settings.json, then Back) and "confirm" (save before going
## back to the title?). choose(), back() and adjust() change pages and settings themselves
## and return what the screen must do: "resume", "save", "setting" (a setting changed: apply
## and write it), "title", "save_title" (save, then the title), or "" for nothing.

const PAGES := {
	"main": ["resume", "save", "settings", "title"],
	"confirm": ["save_title", "title", "cancel"],
}
const HEADINGS := {"main": "Paused", "settings": "Settings", "confirm": "Save first?"}
const LABELS := {
	"resume": "Resume", "save": "Save", "settings": "Settings", "title": "Back to title",
	"save_title": "Save, then go", "cancel": "Cancel", "back": "Back",
}

var settings: Settings
var page := "main"
var list: MenuList


func _init(s: Settings) -> void:
	settings = s
	open("main")


## Shows a page with the cursor on `on` (or the first item).
func open(p: String, on := "") -> void:
	page = p
	var items: Array[String] = []
	if p == "settings":
		items = settings.keys()
		items.append("back")
	else:
		items.assign(PAGES[p])
	list = MenuList.new(items)
	list.cursor = maxi(items.find(on), 0)


func heading() -> String:
	return HEADINGS[page]


## A row's text; a setting shows its value ("Lightning: On"). On the confirm page going
## without saving says so.
func label(item: String) -> String:
	if page == "settings" and item != "back":
		return "%s: %s" % [settings.spec[item].get("label", item), settings.value_text(item)]
	if page == "confirm" and item == "title":
		return "Go without saving"
	return LABELS.get(item, item)


## Enter / click on the row under the cursor.
func choose() -> String:
	var item := list.choose()
	match page:
		"main":
			match item:
				"resume", "save":
					return item
				"settings":
					open("settings")
				"title":
					open("confirm", "save_title")
		"settings":
			if item == "back":
				open("main", "settings")
			elif item != "":
				settings.adjust(item, 1)
				return "setting"
		"confirm":
			if item == "cancel":
				open("main", "title")
			elif item != "":
				return item
	return ""


## Esc / the pad's back button: closes the menu from the first page, else one page back.
func back() -> String:
	match page:
		"main":
			return "resume"
		"settings":
			open("main", "settings")
		"confirm":
			open("main", "title")
	return ""


## Left (-1) / right (+1) on a setting row changes it, stopping at the ends.
func adjust(step: int) -> String:
	var item := list.current()
	if page != "settings" or item == "back":
		return ""
	return "setting" if settings.adjust(item, step, false) else ""
