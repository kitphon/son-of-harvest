class_name Controls
extends RefCounted
## The player's keys: which keys start which game action. The actions, their labels and
## default keys come from data/controls.json (plus one "pick tool N" action per tool in
## Game.TOOLS); the player's own keys are kept in the settings file (Settings.controls).
## Each action has a few key slots. Binding a key that another action has swaps the two
## (that action gets the old key back), so no key ever starts two actions. apply() puts the
## keys into the InputMap. Keys are physical keys, so a layout change doesn't move them.

const DATA := "res://data/controls.json"
const CANCEL := KEY_ESCAPE   # always cancels a rebind, never bound to anything else
const SHORT_NAMES := {KEY_ESCAPE: "Esc", KEY_NONE: "-"}
const PAD_BUTTONS := {
	"a": JOY_BUTTON_A, "b": JOY_BUTTON_B, "x": JOY_BUTTON_X, "y": JOY_BUTTON_Y,
	"back": JOY_BUTTON_BACK, "guide": JOY_BUTTON_GUIDE, "start": JOY_BUTTON_START,
	"left_stick": JOY_BUTTON_LEFT_STICK, "right_stick": JOY_BUTTON_RIGHT_STICK,
	"left_shoulder": JOY_BUTTON_LEFT_SHOULDER, "right_shoulder": JOY_BUTTON_RIGHT_SHOULDER,
	"dpad_up": JOY_BUTTON_DPAD_UP, "dpad_down": JOY_BUTTON_DPAD_DOWN,
	"dpad_left": JOY_BUTTON_DPAD_LEFT, "dpad_right": JOY_BUTTON_DPAD_RIGHT,
}

var slots := 2
var order: Array[String] = []   # actions in menu order
var spec: Dictionary = {}       # action -> {label, keys (default key codes), fixed (key codes), pad}
var bound: Dictionary = {}      # action -> key code per slot (KEY_NONE = empty slot)


## `tools` are the tool ids for the "pick tool N" actions; empty = Game.TOOLS.
static func make(path := DATA, tools: Array = []) -> Controls:
	var c := Controls.new()
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		push_error("Could not read " + path)
		data = {}
	c.slots = maxi(int(data.get("slots", 2)), 1)
	for a in data.get("actions", []):
		if a is Dictionary and a.has("id"):
			c._add(str(a.id), str(a.get("label", a.id)), a.get("keys", []), a.get("fixed", []), a.get("pad", []))
	if tools.is_empty():
		tools = load("res://scripts/autoload/game.gd").get_script_constant_map().get("TOOLS", [])
	var tool_keys: Array = data.get("tool_keys", [])
	for i in tools.size():
		var label: String = str(data.get("tool_label", "Tool %d: %s")) % [i + 1, str(tools[i]).capitalize()]
		c._add("tool_%d" % (i + 1), label, [tool_keys[i]] if i < tool_keys.size() else [], [], [])
	c.reset()
	return c


func _add(action: String, label: String, keys: Array, fixed: Array, pad: Array) -> void:
	var codes := []
	for k in keys.slice(0, slots):
		codes.append(key_code(str(k)))
	var fixed_codes := []
	for k in fixed:
		fixed_codes.append(key_code(str(k)))
	var buttons := []
	for b in pad:
		if PAD_BUTTONS.has(b):
			buttons.append(PAD_BUTTONS[b])
	order.append(action)
	spec[action] = {"label": label, "keys": codes, "fixed": fixed_codes, "pad": buttons}


## A key name ("W", "Shift", "F5") as its key code; KEY_NONE for "" or an unknown name.
static func key_code(name: String) -> int:
	return OS.find_keycode_from_string(name) if name != "" else KEY_NONE


## The key as the menu shows it ("-" for an empty slot).
static func key_name(code: int) -> String:
	return SHORT_NAMES.get(code, OS.get_keycode_string(code))


func actions() -> Array[String]:
	return order.duplicate()


## The row label; keys that can't be changed follow in brackets ("Pause (Esc)").
func label(action: String) -> String:
	var s: Dictionary = spec.get(action, {})
	var names: Array[String] = []
	for k in s.get("fixed", []):
		names.append(key_name(k))
	return s.get("label", action) + ("" if names.is_empty() else " (%s)" % ", ".join(names))


## The key in each slot (KEY_NONE for an empty one).
func keys(action: String) -> Array:
	return bound.get(action, []).duplicate()


func reset() -> void:
	bound = {}
	for action in order:
		bound[action] = _defaults(action)


func _defaults(action: String) -> Array:
	return _pad(spec[action].keys.duplicate())


func _pad(codes: Array) -> Array:
	while codes.size() < slots:
		codes.append(KEY_NONE)
	return codes


func is_reserved(code: int) -> bool:
	if code == KEY_NONE or code == CANCEL:
		return true
	for action in order:
		if spec[action].fixed.has(code):
			return true
	return false


## The action that has this key, or "".
func owner_of(code: int) -> String:
	for action in order:
		if spec[action].fixed.has(code) or (code != KEY_NONE and bound[action].has(code)):
			return action
	return ""


## How many keys start the action, fixed ones included.
func key_count(action: String) -> int:
	return spec[action].fixed.size() + bound[action].filter(func(k): return k != KEY_NONE).size()


## Puts `code` in the action's slot. Returns {done, other, reason}: done with other = the
## action that got the old key back in a swap (or ""); not done (nothing changes) with
## reason "reserved" (a key that can't move; other = its action) or "last_key" (the swap
## would leave other with no key at all).
func bind(action: String, slot: int, code: int) -> Dictionary:
	var out := {"done": false, "other": "", "reason": ""}
	if not bound.has(action) or slot < 0 or slot >= slots:
		out.reason = "unknown"
		return out
	if is_reserved(code):
		out.reason = "reserved"
		out.other = owner_of(code)
		return out
	var mine: Array = bound[action]
	var old: int = mine[slot]
	var other := owner_of(code)
	if other == action:
		mine[mine.find(code)] = old   # its own other slot: the two slots trade
	elif other != "":
		var theirs: Array = bound[other]
		if old == KEY_NONE and key_count(other) == 1:
			out.reason = "last_key"
			out.other = other
			return out
		theirs[theirs.find(code)] = old
		out.other = other
	mine[slot] = code
	out.done = true
	return out


## Empties a slot. Returns "" when done, "empty" (nothing there) or "last_key" (the action
## would have no key left).
func clear(action: String, slot: int) -> String:
	if not bound.has(action) or slot < 0 or slot >= slots or bound[action][slot] == KEY_NONE:
		return "empty"
	if key_count(action) == 1:
		return "last_key"
	bound[action][slot] = KEY_NONE
	return ""


## Puts the keys (and the pad buttons from data) into the InputMap, replacing what was there.
func apply() -> void:
	for action in order:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for k in spec[action].fixed + bound[action]:   # fixed keys first
			if k != KEY_NONE:
				var ev := InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(action, ev)
		for b in spec[action].pad:
			var ev := InputEventJoypadButton.new()
			ev.button_index = b
			InputMap.action_add_event(action, ev)


## For the settings file: action -> key names per slot ("" = empty).
func to_dict() -> Dictionary:
	var out := {}
	for action in order:
		out[action] = bound[action].map(func(k): return "" if k == KEY_NONE else OS.get_keycode_string(k))
	return out


## Takes the keys from the settings file. Returns "" or what was wrong; on a problem nothing
## changes. An action missing from the file keeps its default keys, less any the file gives
## to another action (an older file); an action this build doesn't know is skipped.
func from_dict(saved: Variant) -> String:
	if not saved is Dictionary:
		return "The saved keys are broken"
	var n := {}
	var taken := {}
	for action in order:
		if not saved.has(action):
			continue
		var list = saved[action]
		if not list is Array or list.size() > slots:
			return "The keys for %s are broken" % action
		var codes: Array = []
		for name in list:
			var code: int = key_code(name) if name is String else -1
			if code == -1 or (name != "" and (code == KEY_NONE or is_reserved(code))):
				return "The keys for %s are broken" % action
			if code != KEY_NONE:
				if taken.has(code):
					return "Two actions share the key %s" % key_name(code)
				taken[code] = action
			codes.append(code)
		n[action] = _pad(codes)
		if spec[action].fixed.is_empty() and codes.all(func(k): return k == KEY_NONE):
			return "%s has no key" % spec[action].label
	for action in order:
		if not n.has(action):
			n[action] = _defaults(action).map(func(k): return KEY_NONE if taken.has(k) else k)
	bound = n
	return ""
