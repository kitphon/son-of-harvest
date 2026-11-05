class_name Controls
extends RefCounted
## The player's keys: which keys start which game action. The actions, their labels and
## default keys come from data/controls.json (plus one "pick tool N" action per tool in
## Game.TOOLS); the player's own keys are kept in the settings file (Settings.controls).
## Each action has a few key slots. Binding a key that another action has swaps the two
## (that action gets the old key back), so no key ever starts two actions. apply() puts the
## keys into the InputMap. Keys are physical keys, so a layout change doesn't move them.
## Each action also has one pad button slot (default "pad" in data), rebound the same way
## (bind_pad swaps with the action that had the button); "pad_fixed" buttons (Start on
## Pause) and the left stick's direction on the move actions always stay where data puts them.
## A pad slot can also hold an axis: a trigger or a right-stick direction (PAD_AXES), kept as
## a code from AXIS_BASE up so one int names any pad input; the left stick can't be bound.

const DATA := "res://data/controls.json"
const CANCEL := KEY_ESCAPE   # always cancels a rebind, never bound to anything else
const SHORT_NAMES := {KEY_ESCAPE: "Esc", KEY_NONE: "-"}
const NO_BUTTON := JOY_BUTTON_INVALID   # an empty pad slot
const STICK := {"up": Vector2i(JOY_AXIS_LEFT_Y, -1), "down": Vector2i(JOY_AXIS_LEFT_Y, 1),
	"left": Vector2i(JOY_AXIS_LEFT_X, -1), "right": Vector2i(JOY_AXIS_LEFT_X, 1)}
const PAD_BUTTONS := {
	"a": JOY_BUTTON_A, "b": JOY_BUTTON_B, "x": JOY_BUTTON_X, "y": JOY_BUTTON_Y,
	"back": JOY_BUTTON_BACK, "guide": JOY_BUTTON_GUIDE, "start": JOY_BUTTON_START,
	"left_stick": JOY_BUTTON_LEFT_STICK, "right_stick": JOY_BUTTON_RIGHT_STICK,
	"left_shoulder": JOY_BUTTON_LEFT_SHOULDER, "right_shoulder": JOY_BUTTON_RIGHT_SHOULDER,
	"dpad_up": JOY_BUTTON_DPAD_UP, "dpad_down": JOY_BUTTON_DPAD_DOWN,
	"dpad_left": JOY_BUTTON_DPAD_LEFT, "dpad_right": JOY_BUTTON_DPAD_RIGHT,
}
const AXIS_BASE := 1000   # pad codes from here are axes: AXIS_BASE + axis * 2 + (1 for the + side)
const PAD_AXES := {
	"left_trigger": Vector2i(JOY_AXIS_TRIGGER_LEFT, 1), "right_trigger": Vector2i(JOY_AXIS_TRIGGER_RIGHT, 1),
	"rs_up": Vector2i(JOY_AXIS_RIGHT_Y, -1), "rs_down": Vector2i(JOY_AXIS_RIGHT_Y, 1),
	"rs_left": Vector2i(JOY_AXIS_RIGHT_X, -1), "rs_right": Vector2i(JOY_AXIS_RIGHT_X, 1),
}
const STYLE_XBOX := "xbox"
const STYLE_PLAYSTATION := "playstation"
static var style_now := STYLE_XBOX   # the style Game.pad_style() found last (the pause menu has no Game to ask)
const AXIS_PRESS := 0.6   # how far an axis must go to count when the menu waits for one

var slots := 2
var order: Array[String] = []   # actions in menu order
var spec: Dictionary = {}       # action -> {label, keys (default key codes), fixed (key codes), pad, pad_fixed, stick}
var bound: Dictionary = {}      # action -> key code per slot (KEY_NONE = empty slot)
var pad_bound: Dictionary = {}  # action -> its pad button (NO_BUTTON = none)
var pad_names: Dictionary = {}  # pad button -> how the menu shows it (Xbox style)
var pad_names_ps: Dictionary = {}  # pad button -> how a PlayStation pad's button is shown


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
			c._add(str(a.id), str(a.get("label", a.id)), a.get("keys", []), a.get("fixed", []),
				str(a.get("pad", "")), a.get("pad_fixed", []), str(a.get("stick", "")))
	if tools.is_empty():
		tools = load("res://scripts/autoload/game.gd").get_script_constant_map().get("TOOLS", [])
	var tool_keys: Array = data.get("tool_keys", [])
	for i in tools.size():
		var label: String = str(data.get("tool_label", "Tool %d: %s")) % [i + 1, HudLayout.TOOL_NAMES.get(str(tools[i]), str(tools[i]).capitalize())]
		c._add("tool_%d" % (i + 1), label, [tool_keys[i]] if i < tool_keys.size() else [], [], "", [], "")
	for id in PAD_BUTTONS:
		c.pad_names[PAD_BUTTONS[id]] = str(data.get("pad_names", {}).get(id, id))
	for id in PAD_AXES:
		c.pad_names[axis_code(PAD_AXES[id].x, PAD_AXES[id].y)] = str(data.get("pad_names", {}).get(id, id))
	for id in PAD_BUTTONS:
		c.pad_names_ps[PAD_BUTTONS[id]] = str(data.get("pad_names_ps", {}).get(id, c.pad_names[PAD_BUTTONS[id]]))
	for id in PAD_AXES:
		var code := axis_code(PAD_AXES[id].x, PAD_AXES[id].y)
		c.pad_names_ps[code] = str(data.get("pad_names_ps", {}).get(id, c.pad_names[code]))
	c.reset()
	return c


func _add(action: String, label: String, keys: Array, fixed: Array, pad: String, pad_fixed: Array, stick: String) -> void:
	var codes := []
	for k in keys.slice(0, slots):
		codes.append(key_code(str(k)))
	var fixed_codes := []
	for k in fixed:
		fixed_codes.append(key_code(str(k)))
	var buttons := []
	for b in pad_fixed:
		if button_of(b) != NO_BUTTON:
			buttons.append(button_of(b))
	order.append(action)
	spec[action] = {"label": label, "keys": codes, "fixed": fixed_codes, "pad": button_of(pad),
		"pad_fixed": buttons, "stick": STICK.get(stick)}


## A key name ("W", "Shift", "F5") as its key code; KEY_NONE for "" or an unknown name.
static func key_code(name: String) -> int:
	return OS.find_keycode_from_string(name) if name != "" else KEY_NONE


## A pad input's id in data ("a", "dpad_up", "right_trigger") as its code; NO_BUTTON for "" or an unknown id.
static func button_of(id: String) -> int:
	if PAD_AXES.has(id):
		return axis_code(PAD_AXES[id].x, PAD_AXES[id].y)
	return PAD_BUTTONS.get(id, NO_BUTTON)


## The id in data for a pad code ("" for none or an unknown one).
static func pad_id(code: int) -> String:
	for id in PAD_AXES:
		if axis_code(PAD_AXES[id].x, PAD_AXES[id].y) == code:
			return id
	var id = PAD_BUTTONS.find_key(code)
	return id if id != null else ""


## The pad code of an axis pushed to one side (`dir` < 0: the - side).
static func axis_code(axis: int, dir: float) -> int:
	return AXIS_BASE + axis * 2 + (1 if dir > 0 else 0)


static func is_axis(code: int) -> bool:
	return code >= AXIS_BASE


## The pad code a motion event stands for while the menu waits for one: an axis pushed past
## AXIS_PRESS, else NO_BUTTON (a stick resting, or only nudged).
static func motion_code(axis: int, value: float) -> int:
	return axis_code(axis, value) if absf(value) >= AXIS_PRESS else NO_BUTTON


## The pad button as the menu shows it ("-" for an empty slot).
## `style` is "xbox" (A, LB...) or "playstation" (Cross, L1...).
func pad_name(button: int, style := STYLE_XBOX) -> String:
	return (pad_names_ps if style == STYLE_PLAYSTATION else pad_names).get(button, "-")


## The style a pad's own name and SDL guid say it is: "playstation" for a Sony pad (DualShock,
## DualSense, PS3 / PS4 / PS5 by name, or Sony's USB vendor id 054c in the guid), else "xbox".
static func style_of(joy_name: String, guid: String) -> String:
	var n := joy_name.to_lower()
	for word in ["playstation", "dualshock", "dualsense", "sony", "ps3", "ps4", "ps5", "ps vita"]:
		if n.contains(word):
			return STYLE_PLAYSTATION
	# An SDL guid holds the vendor id little-endian at hex digits 8..11: Sony = 054c -> "4c05".
	if guid.length() >= 12 and guid.substr(8, 4).to_lower() == "4c05":
		return STYLE_PLAYSTATION
	return STYLE_XBOX


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
	return s.get("label", action) if names.is_empty() else "%s (%s)" % [s.get("label", action), ", ".join(names)]


## The key in each slot (KEY_NONE for an empty one).
func keys(action: String) -> Array:
	return bound.get(action, []).duplicate()


func reset() -> void:
	bound = {}
	pad_bound = {}
	for action in order:
		bound[action] = _defaults(action)
		pad_bound[action] = spec[action].pad


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


# --- pad buttons ----------------------------------------------------------------

func pad_button(action: String) -> int:
	return pad_bound.get(action, NO_BUTTON)


## A button that can't be bound: none, or one data keeps on an action (Start on Pause).
func is_pad_reserved(button: int) -> bool:
	if button == NO_BUTTON or not pad_names.has(button):
		return true
	for action in order:
		if spec[action].pad_fixed.has(button):
			return true
	return false


## The action that has this pad button, or "".
func pad_owner(button: int) -> String:
	for action in order:
		if spec[action].pad_fixed.has(button) or (button != NO_BUTTON and pad_bound[action] == button):
			return action
	return ""


## Puts the pad button on the action. Returns {done, other, reason} like bind(): another
## action that had it gets this one's old button (or none); a reserved button is refused.
## A pad slot may be empty (the keys still work), so there is no "last_key" here.
func bind_pad(action: String, button: int) -> Dictionary:
	var out := {"done": false, "other": "", "reason": ""}
	if not pad_bound.has(action):
		out.reason = "unknown"
		return out
	if is_pad_reserved(button):
		out.reason = "reserved"
		out.other = pad_owner(button)
		return out
	var other := pad_owner(button)
	if other != "" and other != action:
		pad_bound[other] = pad_bound[action]
		out.other = other
	pad_bound[action] = button
	out.done = true
	return out


## Empties the action's pad slot. Returns "" when done, "empty" when there was nothing.
func clear_pad(action: String) -> String:
	if pad_button(action) == NO_BUTTON:
		return "empty"
	pad_bound[action] = NO_BUTTON
	return ""


## For the settings file: action -> pad button id ("" = none).
func pad_to_dict() -> Dictionary:
	var out := {}
	for action in order:
		out[action] = pad_id(pad_bound[action])
	return out


## Takes the pad buttons from the settings file. Returns "" or what was wrong; on a problem
## nothing changes. Like from_dict: a missing action keeps its default unless the file gave
## that button to another action; an unknown action is skipped.
func pad_from_dict(saved: Variant) -> String:
	if not saved is Dictionary:
		return "The saved pad buttons are broken"
	var n := {}
	var taken := {}
	for action in order:
		if not saved.has(action):
			continue
		var id = saved[action]
		var button: int = button_of(id) if id is String else NO_BUTTON
		if not id is String or (id != "" and is_pad_reserved(button)):
			return "The pad button for %s is broken" % action
		if button != NO_BUTTON:
			if taken.has(button):
				return "Two actions share the pad button %s" % pad_name(button)
			taken[button] = action
		n[action] = button
	for action in order:
		if not n.has(action):
			n[action] = NO_BUTTON if taken.has(spec[action].pad) else spec[action].pad
	pad_bound = n
	return ""


## Puts the keys and pad buttons into the InputMap, replacing what was there.
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
		for b in spec[action].pad_fixed + [pad_bound[action]]:
			if b != NO_BUTTON and is_axis(b):
				var ev := InputEventJoypadMotion.new()
				ev.axis = (b - AXIS_BASE) / 2
				ev.axis_value = 1.0 if (b - AXIS_BASE) % 2 == 1 else -1.0
				InputMap.action_add_event(action, ev)
			elif b != NO_BUTTON:
				var ev := InputEventJoypadButton.new()
				ev.button_index = b
				InputMap.action_add_event(action, ev)
		if spec[action].stick != null:
			var ev := InputEventJoypadMotion.new()
			ev.axis = spec[action].stick.x
			ev.axis_value = spec[action].stick.y
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
