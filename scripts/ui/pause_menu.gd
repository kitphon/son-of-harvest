class_name PauseMenu
extends RefCounted
## The pause menu's pages and choices, without any drawing (PauseScreen draws it, headless
## tests check it). Pages: "main" (Resume / Save / Settings / Back to title), "settings"
## (one row per setting in data/settings.json, then Reset to defaults, Controls and Back;
## ranges such as the volumes get a slider), "controls" (one row per game action with its key
## slots and its pad button, then Reset to defaults and Back) and "confirm" (save before going back to the title?). choose(),
## back(), adjust(), press() and clear() change pages and settings themselves and return what
## the screen must do: "resume", "save", "setting" (a setting changed: apply and write it),
## "controls" (the keys changed: apply and write them), "title", "save_title" (save, then the
## title), or "" for nothing.
## On the controls page left / right pick a key slot or the pad slot (the last one), Enter
## starts listening, the next key pressed goes into a key slot (press()), the next pad button
## into the pad slot (press_pad()); one another action has is swapped over. Esc cancels
## listening, Delete / Backspace empties the slot.

const PAGES := {
	"main": ["resume", "save", "settings", "fishlog", "title"],
	"confirm": ["save_title", "title", "cancel"],
}
const HEADINGS := {"main": "Paused", "settings": "Settings", "controls": "Controls", "confirm": "Save first?", "fishlog": "Fish log"}
const LABELS := {
	"resume": "Resume", "save": "Save", "settings": "Settings", "title": "Back to title",
	"save_title": "Save, then go", "cancel": "Cancel", "back": "Back",
	"controls": "Controls", "reset": "Reset to defaults", "fishlog": "Fish log",
}
const UNKNOWN := "???"   # a fish never caught
const HINT := "Enter: new key / button   Del: clear"
const SETTINGS_ROWS: Array[String] = ["reset", "controls", "back"]   # after the settings

var settings: Settings
var fish_rules: Dictionary   # data/fish.json and the catch counts, for the fish log page
var fish_caught: Dictionary
var page := "main"
var list: MenuList
var slot := 0          # the slot picked on the controls page (the last one is the pad's)
var listening := ""    # the action waiting for a key, or ""
var note := ""         # what the last change on the settings / controls page did


func _init(s: Settings, rules := {}, caught := {}) -> void:
	settings = s
	fish_rules = rules
	fish_caught = caught
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
		items.append_array(SETTINGS_ROWS)
	elif p == "controls":
		items = settings.controls.actions()
		items.append_array(["reset", "back"])
	elif p == "fishlog":
		for row in Fishing.log_rows(fish_rules, fish_caught):
			items.append(row.id)
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
	if page == "controls" and is_action(item):
		return settings.controls.label(item)
	if page == "settings" and item not in SETTINGS_ROWS:
		return "%s: %s" % [settings.spec[item].get("label", item), settings.value_text(item)]
	if page == "confirm" and item == "title":
		return "Go without saving"
	if is_fish(item):
		return String(fish_rules.fish[item].name) if count(item) > 0 else UNKNOWN
	return LABELS.get(item, item)


func is_action(item: String) -> bool:
	return page == "controls" and settings.controls.bound.has(item)


## A row of the fish log that is a fish (not Back).
func is_fish(item: String) -> bool:
	return page == "fishlog" and fish_rules.get("fish", {}).has(item)


## How many of a fish were caught.
func count(item: String) -> int:
	return int(fish_caught.get(item, 0))


## The count shown at a fish's row ("x3"); "" for a fish never caught.
func count_text(item: String) -> String:
	return "x%d" % count(item) if is_fish(item) and count(item) > 0 else ""


## The fish log's total: "5 of 19 kinds".
func total_text() -> String:
	return "%d of %d kinds" % [Fishing.kinds_caught(fish_rules, fish_caught), fish_rules.get("fish", {}).size()]


## The three lines under the fish log for the fish under the cursor: where, which seasons,
## which hours. Empty for a fish never caught and for Back.
func fish_details(item: String) -> Array[String]:
	var out: Array[String] = ["", "", ""]
	if not is_fish(item) or count(item) == 0:
		return out
	var places: Array = []
	for p in Fishing.places_of(fish_rules, item):
		places.append(Lang.t(p))
	out[0] = "Where: %s" % Lang.list(places)
	var seasons := Fishing.seasons_of(fish_rules, item, Game.SEASONS)
	if seasons.size() == Game.SEASONS.size():
		out[1] = "Season: %s" % Lang.t("All year")
	else:
		var names: Array = []
		for s in seasons:
			names.append(Lang.t(Game.SEASON_NAMES[s]))
		out[1] = "Season: %s" % Lang.list(names)
	var h := Fishing.hours_of(fish_rules, item)
	out[2] = "Hours: %s" % (Lang.t("Any hour") if h.is_empty() else "%d:00-%d:00" % [h[0], h[1]])
	return out


## Slots per action row: the key slots, then the pad button.
func slot_count() -> int:
	return settings.controls.slots + 1


func is_pad_slot(k := -1) -> bool:
	return (slot if k < 0 else k) == settings.controls.slots


## Waiting for a pad button (Enter on a pad slot).
func listening_pad() -> bool:
	return listening != "" and is_pad_slot()


## A slot's text on the controls page ("..." while it waits); "" off that page.
func slot_text(item: String, k: int) -> String:
	if not is_action(item):
		return ""
	if listening == item and slot == k:
		return "..."
	if is_pad_slot(k):
		return settings.controls.pad_name(settings.controls.pad_button(item), Controls.style_now)
	return Controls.key_name(settings.controls.keys(item)[k])


## The line under the controls page: what to press, or what the last change did.
func hint() -> String:
	if listening_pad():
		return "Press a pad button for %s  (Esc: cancel)" % settings.controls.spec[listening].label
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
				"fishlog":
					open("fishlog")
				"title":
					open("confirm", "save_title")
		"settings":
			note = ""
			if item == "back":
				open("main", "settings")
			elif item == "controls":
				open("controls")
			elif item == "reset":
				settings.reset()
				note = "Settings back to the defaults."
				return "setting"
			elif item != "":
				settings.adjust(item, 1)
				return "setting"
		"controls":
			if item == "back":
				open("settings", "controls")
			elif item == "reset":
				settings.controls.reset()
				note = "Keys and buttons back to the defaults."
				return "controls"
			elif is_action(item):
				listening = item
		"confirm":
			if item == "cancel":
				open("main", "title")
			elif item != "":
				return item
		"fishlog":
			if item == "back":
				open("main", "fishlog")
	return ""


## A key pressed while listening goes into the slot; Esc (Controls.CANCEL) stops listening.
## While a pad slot listens, keys other than Esc are ignored.
func press(code: int) -> String:
	if listening == "" or (listening_pad() and code != Controls.CANCEL):
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
			note = "%s was on %s: swapped." % [key, c.spec[r.other].label]
		return "controls"
	if r.reason == "reserved":
		note = "%s stays on %s." % [key, c.spec[r.other].label] if r.other != "" else "%s can't be used." % key
	elif r.reason == "last_key":
		note = "%s is the only key for %s." % [key, c.spec[r.other].label]
	return ""


## A pad button pressed while a pad slot listens goes into it; one data keeps on an action
## (Start on Pause) is refused and ends the listening, so Start also cancels.
func press_pad(button: int) -> String:
	if not listening_pad():
		return ""
	var action := listening
	listening = ""
	note = ""
	var c := settings.controls
	var r := c.bind_pad(action, button)
	var name := c.pad_name(button, Controls.style_now)
	if r.done:
		if r.other != "":
			note = "%s was on %s: swapped." % [name, c.spec[r.other].label]
		return "controls"
	if r.reason == "reserved" and r.other != "":
		note = "%s stays on %s." % [name, c.spec[r.other].label]
	return ""


## Delete / Backspace on an action row empties the slot under the cursor.
func clear() -> String:
	var item := list.current()
	if not is_action(item) or listening != "":
		return ""
	note = ""
	if is_pad_slot():
		return "controls" if settings.controls.clear_pad(item) == "" else ""
	match settings.controls.clear(item, slot):
		"":
			return "controls"
		"last_key":
			note = "%s needs a key." % settings.controls.spec[item].label
	return ""


## Esc / the pad's back button: closes the menu from the first page, else one page back.
func back() -> String:
	match page:
		"main":
			return "resume"
		"settings":
			open("main", "settings")
		"fishlog":
			open("main", "fishlog")
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
			slot = clampi(slot + step, 0, slot_count() - 1)
		return ""
	if page != "settings" or item in SETTINGS_ROWS:
		return ""
	note = ""
	return "setting" if settings.adjust(item, step, false) else ""
