class_name PauseMenu
extends RefCounted
## The pause menu's pages and choices, without any drawing (PauseScreen draws it, headless
## tests check it). Pages: "main" (Resume / Save / Settings / Back to title), "settings"
## (one row per setting in data/settings.json, then Controls and Back; ranges such as the
## volumes get a slider), "controls" (one row per game action with its key slots, then Reset
## to defaults and Back) and "confirm" (save before going back to the title?). choose(),
## back(), adjust(), press() and clear() change pages and settings themselves and return what
## the screen must do: "resume", "save", "setting" (a setting changed: apply and write it),
## "controls" (the keys changed: apply and write them), "title", "save_title" (save, then the
## title), or "" for nothing.
## On the controls page left / right pick a key slot, Enter starts listening, the next key
## pressed goes into the slot (press()); a key another action has is swapped over. Esc
## cancels listening, Delete / Backspace empties the slot.

const PAGES := {
	"main": ["resume", "save", "settings", "title"],
	"confirm": ["save_title", "title", "cancel"],
}
const HEADINGS := {"main": "Paused", "settings": "Settings", "controls": "Controls", "confirm": "Save first?"}
const LABELS := {
	"resume": "Resume", "save": "Save", "settings": "Settings", "title": "Back to title",
	"save_title": "Save, then go", "cancel": "Cancel", "back": "Back",
	"controls": "Controls", "reset": "Reset to defaults",
}
const HINT := "Enter: new key   Del: clear"

var settings: Settings
var page := "main"
var list: MenuList
var slot := 0          # the key slot picked on the controls page
var listening := ""    # the action waiting for a key, or ""
var note := ""         # what the last change on the controls page did


func _init(s: Settings) -> void:
	settings = s
	open("main")


## Shows a page with the cursor on `on` (or the first item).
func open(p: String, on := "") -> void:
	page = p
	slot = 0
	listening = ""
	note = ""
	var items: Array[String] = []
	if p == "settings":
		items = settings.keys()
		items.append_array(["controls", "back"])
	elif p == "controls":
		items = settings.controls.actions()
		items.append_array(["reset", "back"])
	else:
		items.assign(PAGES[p])
	list = MenuList.new(items)
	list.cursor = maxi(items.find(on), 0)


func heading() -> String:
	return HEADINGS[page]


## A row's text; a setting shows its value ("Lightning: On"). On the confirm page going
## without saving says so.
func label(item: String) -> String:
	if page == "controls" and is_action(item):
		return settings.controls.label(item)
	if page == "settings" and item not in ["controls", "back"]:
		return "%s: %s" % [settings.spec[item].get("label", item), settings.value_text(item)]
	if page == "confirm" and item == "title":
		return "Go without saving"
	return LABELS.get(item, item)


func is_action(item: String) -> bool:
	return page == "controls" and settings.controls.bound.has(item)


## A key slot's text on the controls page ("..." while it waits for a key); "" off that page.
func slot_text(item: String, k: int) -> String:
	if not is_action(item):
		return ""
	if listening == item and slot == k:
		return "..."
	return Controls.key_name(settings.controls.keys(item)[k])


## The line under the controls page: what to press, or what the last change did.
func hint() -> String:
	if listening != "":
		return "Press a key for %s  (Esc: cancel)" % settings.controls.spec[listening].label
	return note if note != "" else HINT


## A range setting's slider: (steps filled, steps in all); (0, 0) for rows without one.
func slider(item: String) -> Vector2i:
	if page != "settings" or settings.spec.get(item, {}).get("kind") != "range":
		return Vector2i.ZERO
	var s: Dictionary = settings.spec[item]
	var step := maxi(int(s.get("step", 1)), 1)
	return Vector2i((int(settings.value(item)) - int(s.min)) / step, (int(s.max) - int(s.min)) / step)


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
			elif item == "controls":
				open("controls")
			elif item != "":
				settings.adjust(item, 1)
				return "setting"
		"controls":
			if item == "back":
				open("settings", "controls")
			elif item == "reset":
				settings.controls.reset()
				note = "Keys back to the defaults"
				return "controls"
			elif is_action(item):
				listening = item
		"confirm":
			if item == "cancel":
				open("main", "title")
			elif item != "":
				return item
	return ""


## A key pressed while listening goes into the slot; Esc (Controls.CANCEL) stops listening.
func press(code: int) -> String:
	if listening == "":
		return ""
	var action := listening
	listening = ""
	note = ""
	if code == Controls.CANCEL:
		return ""
	var c := settings.controls
	var r := c.bind(action, slot, code)
	var key := Controls.key_name(code)
	if r.done:
		if r.other != "":
			note = "%s was on %s: swapped" % [key, c.spec[r.other].label]
		return "controls"
	if r.reason == "reserved":
		note = "%s stays on %s" % [key, c.spec[r.other].label] if r.other != "" else "%s can't be used" % key
	elif r.reason == "last_key":
		note = "%s is the only key for %s" % [key, c.spec[r.other].label]
	return ""


## Delete / Backspace on an action row empties the slot under the cursor.
func clear() -> String:
	var item := list.current()
	if not is_action(item) or listening != "":
		return ""
	note = ""
	match settings.controls.clear(item, slot):
		"":
			return "controls"
		"last_key":
			note = "%s needs a key" % settings.controls.spec[item].label
	return ""


## Esc / the pad's back button: closes the menu from the first page, else one page back.
func back() -> String:
	match page:
		"main":
			return "resume"
		"settings":
			open("main", "settings")
		"controls":
			if listening != "":
				listening = ""
			else:
				open("settings", "controls")
		"confirm":
			open("main", "title")
	return ""


## Left (-1) / right (+1) on a setting row changes it, stopping at the ends; on an action row
## it picks the key slot.
func adjust(step: int) -> String:
	var item := list.current()
	if is_action(item):
		if listening == "":
			slot = clampi(slot + step, 0, settings.controls.slots - 1)
		return ""
	if page != "settings" or item in ["controls", "back"]:
		return ""
	return "setting" if settings.adjust(item, step, false) else ""
