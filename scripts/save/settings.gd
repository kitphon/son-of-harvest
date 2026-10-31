class_name Settings
extends RefCounted
## The player's settings (lightning flashes, window size, later volume), kept in their own
## file apart from the game save. Which settings there are, their kind and default come from
## data/settings.json, so a new one is only a data entry. Reading checks the whole file
## first: a broken file is refused and every setting stays at its default.

const VERSION := 1
const PATH := "user://settings.json"
const DATA := "res://data/settings.json"

var spec: Dictionary = {}     # setting -> {label, kind, default, options | min, max, step}
var values: Dictionary = {}   # setting -> its value now


static func make(spec_path := DATA) -> Settings:
	var s := Settings.new()
	var data = JSON.parse_string(FileAccess.get_file_as_string(spec_path))
	if data is Dictionary:
		for key in data:
			if data[key] is Dictionary:
				s.spec[key] = data[key]
	s.reset()
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


## The value as the menu shows it: "On" / "Off", the option, or the number.
func value_text(key: String) -> String:
	var v = value(key)
	if v is bool:
		return "On" if v else "Off"
	if v is float:
		return str(int(v))
	return str(spec.get(key, {}).get("option_labels", {}).get(v, v))


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
## round when `wrap`, else stop at the ends. Returns whether the value changed.
func adjust(key: String, step: int, wrap := true) -> bool:
	var s: Dictionary = spec.get(key, {})
	var old = value(key)
	var v = old
	match s.get("kind", ""):
		"bool":
			v = not old
		"choice":
			var i: int = s.options.find(old) + step
			i = posmod(i, s.options.size()) if wrap else clampi(i, 0, s.options.size() - 1)
			v = s.options[i]
		"range":
			var lo := int(s.min)
			var hi := int(s.max)
			v = int(old) + step * int(s.get("step", 1))
			if wrap and v > hi:
				v = lo
			elif wrap and v < lo:
				v = hi
			v = clampi(v, lo, hi)
	values[key] = v
	return v != old


func to_dict() -> Dictionary:
	return {"version": VERSION, "settings": values.duplicate()}


## Takes the settings from saved data. Returns "" or what was wrong; on a problem nothing
## changes. A setting missing from the file keeps its default (an older file); a setting
## this build doesn't know is skipped (a newer file).
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
	var n := {}
	for key in spec:
		n[key] = default_value(key)
		if saved.has(key):
			n[key] = valid(key, saved[key])
			if n[key] == null:
				return "Setting %s is broken" % key
	values = n
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
