class_name Settings
extends RefCounted
## The player's settings (display, window size, v-sync, flashes, text speed, volumes...), kept in their own
## file apart from the game save. Which settings there are, their kind and default come from
## data/settings.json, so a new one is only a data entry. Reading checks the whole file
## first: a broken file is refused and every setting stays at its default. The player's keys
## (Controls, data/controls.json) are kept in the same file under "controls", the pad
## buttons under "pad".
## Version 2 split the old "window" ("2x" .. "4x" or "full") into "display" and "window";
## a version 1 file is read with "full" as the borderless display.

const VERSION := 2
const PATH := "user://settings.json"
const DATA := "res://data/settings.json"

var spec: Dictionary = {}     # setting -> {label, kind, default, options | min, max, step, unit}
var values: Dictionary = {}   # setting -> its value now
var controls: Controls        # the player's keys
var hidden: Dictionary = {}   # choice setting -> options left out of the menu now (window sizes too big for the screen)


static func make(spec_path := DATA) -> Settings:
	var s := Settings.new()
	var data = JSON.parse_string(FileAccess.get_file_as_string(spec_path))
	if data is Dictionary:
		for key in data:
			if data[key] is Dictionary:
				s.spec[key] = data[key]
	s.reset()
	s.controls = Controls.make()
	return s


func reset() -> void:
	values = {}
	for key in spec:
		values[key] = default_value(key)


func default_value(key: String) -> Variant:
	var d = spec.get(key, {}).get("default")
	var v = valid(key, d)
	return d if v == null else v


func keys() -> Array[String]:
	var out: Array[String] = []
	out.assign(spec.keys())
	return out


func value(key: String) -> Variant:
	return values.get(key, default_value(key))


## The value as the menu shows it: "On" / "Off", the option, or the number (with its unit).
func value_text(key: String) -> String:
	var v = value(key)
	if v is bool:
		return "On" if v else "Off"
	if v is float or v is int:
		return str(int(v)) + str(spec.get(key, {}).get("unit", ""))
	v = shown(key)
	return str(spec.get(key, {}).get("option_labels", {}).get(v, v))


## The option in effect: the value, or for a hidden one the nearest option below it that
## isn't (a saved 4x window on a screen where 3x is the most: 3x). The value itself stays, so
## a bigger screen gets it back.
func shown(key: String) -> Variant:
	var v = value(key)
	var off: Array = hidden.get(key, [])
	if not off.has(v):
		return v
	var options: Array = spec.get(key, {}).get("options", [])
	for i in range(options.find(v), -1, -1):
		if not off.has(options[i]):
			return options[i]
	return v


## What a choice's option in effect stands for (its "values" entry in data), else the option itself.
func option_value(key: String) -> Variant:
	var v = shown(key)
	return spec.get(key, {}).get("values", {}).get(v, v)


## The value checked against the setting's kind, or null when it doesn't fit.
func valid(key: String, v: Variant) -> Variant:
	var s: Dictionary = spec.get(key, {})
	match s.get("kind", ""):
		"bool":
			return v if v is bool else null
		"choice":
			return v if v is String and s.options.has(v) else null
		"range":
			return SaveGame.whole(v, int(s.min), int(s.max))
	return null


## The next value (step +1) or the one before (-1): on / off flips, options and ranges wrap
## round when `wrap`, else stop at the ends; options in `hidden` are skipped. Returns whether
## the value (as shown) changed.
func adjust(key: String, step: int, wrap := true) -> bool:
	var s: Dictionary = spec.get(key, {})
	var old = value(key)
	var v = old
	match s.get("kind", ""):
		"bool":
			v = not old
		"choice":
			# Hidden options are stepped over; from a hidden value the step starts at the shown one.
			var options: Array = s.options.filter(func(o): return not hidden.get(key, []).has(o))
			if options.is_empty():
				return false
			old = shown(key)
			var i: int = options.find(old) + step
			i = posmod(i, options.size()) if wrap else clampi(i, 0, options.size() - 1)
			v = options[i]
		"range":
			var lo := int(s.min)
			var hi := int(s.max)
			v = int(old) + step * int(s.get("step", 1))
			if wrap and v > hi:
				v = lo
			elif wrap and v < lo:
				v = hi
			v = clampi(v, lo, hi)
	if v == old:
		return false
	values[key] = v
	return true


## Bus volumes 0..1 (for Sfx.set_volume): every range setting with a "bus", scaled by its range.
func bus_volumes() -> Dictionary:
	var out := {}
	for key in spec:
		var s: Dictionary = spec[key]
		if s.has("bus") and s.get("kind") == "range":
			var lo := float(s.min)
			out[s.bus] = clampf((float(value(key)) - lo) / maxf(float(s.max) - lo, 1.0), 0.0, 1.0)
	return out


func to_dict() -> Dictionary:
	return {"version": VERSION, "settings": values.duplicate(), "controls": controls.to_dict(),
		"pad": controls.pad_to_dict()}


## Takes the settings from saved data. Returns "" or what was wrong; on a problem nothing
## changes. A setting missing from the file keeps its default (an older file); a setting
## this build doesn't know is skipped (a newer file). A file without "controls" keeps the
## default keys (and one without "pad" the default pad buttons).
func from_dict(data: Variant) -> String:
	if not data is Dictionary:
		return "The settings file is broken"
	var version = SaveGame.whole(data.get("version"), 1, 1 << 30)
	if version == null:
		return "The settings file has no version"
	if version > VERSION:
		return "The settings file is from a newer version (%d)" % version
	var saved = data.get("settings")
	if not saved is Dictionary:
		return "The settings file is broken"
	if version == 1 and saved.get("window") is String and saved.window == "full":
		saved = saved.duplicate()
		saved.erase("window")
		if not saved.has("display"):
			saved.display = "borderless"   # what "full" was: a window over the whole screen
	var n := {}
	for key in spec:
		n[key] = default_value(key)
		if saved.has(key):
			n[key] = valid(key, saved[key])
			if n[key] == null:
				return "Setting %s is broken" % key
	var keys := Controls.make()
	if data.has("controls"):
		var err := keys.from_dict(data.controls)
		if err != "":
			return err
	if data.has("pad"):
		var err := keys.pad_from_dict(data.pad)
		if err != "":
			return err
	values = n
	controls.bound = keys.bound
	controls.pad_bound = keys.pad_bound
	return ""


## Returns "" when read (a missing file is fine: the defaults), else what was wrong.
func read(path := PATH) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return "The settings file is broken"
	return from_dict(json.data)


func write(path := PATH) -> String:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return "Could not save settings (%s)" % error_string(FileAccess.get_open_error())
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	return ""
