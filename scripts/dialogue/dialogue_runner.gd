class_name DialogueRunner
extends RefCounted
## Steps through one dialogue from data/dialogue/<id>.json, without any drawing, so headless
## tests can check it. It reveals the line letter by letter (the typewriter), waits for a
## press, offers choices and writes their flags into the shared `flags` dictionary
## (Game.flags, which is saved). The format is in README.md → Dialogue; bad data is refused
## with `error` set and the runner finished from the start.

const DIR := "res://data/dialogue/"
const SPEAKERS := "res://data/dialogue/speakers.json"
const SETTINGS := "res://data/text_box.json"
const EXPRESSIONS: Array[String] = ["calm", "smile", "surprised", "worried"]
## A villager's portrait moods (portrait:<villager>:<mood> in PlaceholderArt). A mood the
## art doesn't have (yet) shows as neutral. `face`, the older key, names one of them.
const MOODS: Array[String] = ["neutral", "happy", "sad", "surprised", "angry"]
const FACE_MOODS := {"calm": "neutral", "smile": "happy", "worried": "sad", "surprised": "surprised"}
const MAX_CHOICES := 4
const LINE_KEYS: Array[String] = ["id", "speaker", "face", "mood", "text", "next", "choices", "set", "if", "then"]

var id := ""
var error := ""             # "" or why the dialogue was refused
var lines: Array = []
var index := -1             # the line on screen, -1 once finished
var shown := 0              # letters of the line revealed so far
var choice := 0             # choice under the cursor
var flags: Dictionary
var chars_per_second := 40.0
var mood := ""              # the mood of lines that name none (an event's say step), "" = neutral
var instant := false        # every line shown whole at once (set_speed(0))
var pauses: Dictionary = {}   # character -> extra seconds after it
var _ids: Dictionary = {}     # line id -> index
var _wait := 0.0
var _base_speed := 40.0       # chars_per_second from the data, before the player's speed

static var _speakers: Dictionary
static var _settings: Dictionary


## The dialogue `id` from data/dialogue, starting at line `at` (an id; "" = the first line).
static func open(dialogue_id: String, shared_flags: Dictionary, at := "") -> DialogueRunner:
	var path := DIR + dialogue_id + ".json"
	var data: Variant = null
	if dialogue_id.is_valid_filename() and FileAccess.file_exists(path):
		data = JSON.parse_string(FileAccess.get_file_as_string(path))
	var r := DialogueRunner.new(data, speakers(), shared_flags, settings(), at)
	r.id = dialogue_id
	if data == null and r.error == "Dialogue is not a dictionary":
		r.error = "No dialogue %s" % dialogue_id
	return r


static func speakers() -> Dictionary:
	if _speakers.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPEAKERS))
		_speakers = d if d is Dictionary else {}
	return _speakers


static func settings() -> Dictionary:
	if _settings.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS))
		_settings = d if d is Dictionary else {}
	return _settings


func _init(data: Variant, who: Dictionary, shared_flags: Dictionary, look := {}, at := "") -> void:
	flags = shared_flags
	chars_per_second = maxf(float(look.get("chars_per_second", 40)), 1.0)
	_base_speed = chars_per_second
	pauses = look.get("pause_seconds", {})
	error = _check(data, who)
	if error == "" and at != "" and not _ids.has(at):
		error = "No line %s" % at
	if error != "":
		lines = []
		return
	_go(at)


# --- stepping ---------------------------------------------------------------

func done() -> bool:
	return index < 0


func line() -> Dictionary:
	return {} if done() else lines[index]


func text() -> String:
	return line().get("text", "")


## The portrait key for the line on screen, "" for none.
func portrait() -> String:
	return portrait_key(line(), mood)


## The mood line `l` is said in: its `mood`, else its `face` as a mood, else `default`; one
## that isn't in MOODS falls back to neutral.
static func mood_of(l: Dictionary, default := "") -> String:
	var m: Variant = l.get("mood", FACE_MOODS.get(l.get("face", ""), default))
	return m if m in MOODS else "neutral"


## Only villagers (data/villagers) have portraits; narration and anyone else show none.
static func has_portrait(speaker: String) -> bool:
	return speaker != "" and Villagers.all().has(speaker)


## "portrait:<speaker>:<mood>" for line `l`, or "" when it shows no portrait.
static func portrait_key(l: Dictionary, default := "") -> String:
	var speaker: Variant = l.get("speaker", "")
	if not speaker is String or not has_portrait(speaker):
		return ""
	return "portrait:%s:%s" % [speaker, mood_of(l, default)]


func revealed() -> bool:
	return not done() and shown >= text().length()


## The choices to pick from now: only once the whole line is shown.
func choices() -> Array:
	return line().get("choices", []) if revealed() else []


## The player's text speed (Game.text_speed): `factor` x the letters per second from
## data/text_box.json; 0 (or less) shows every line whole at once.
func set_speed(factor: float) -> void:
	instant = factor <= 0.0
	chars_per_second = maxf(_base_speed * maxf(factor, 0.0), 1.0)
	if instant and not done():
		shown = text().length()


## Time passes: reveals letters at chars_per_second, waiting longer after punctuation.
func update(delta: float) -> void:
	if done():
		return
	_wait += delta
	var t := text()
	if instant:
		shown = t.length()
		_wait = 0.0
		return
	while shown < t.length():
		var cost := 1.0 / chars_per_second
		if shown > 0:
			cost += float(pauses.get(t[shown - 1], 0.0))
		if _wait + 0.000001 < cost:   # float sums: 0.3 s is three 0.1 s letters
			break
		_wait -= cost
		shown += 1


## The talk button: shows the rest of the line, or goes on when it is all shown. A line
## with choices waits for `pick` instead.
func press() -> void:
	if done():
		return
	if not revealed():
		shown = text().length()
	elif not line().has("choices"):
		_go(line().get("next", ""), index + 1)


## Moves the choice cursor up (-1) or down (+1), wrapping round.
func move_choice(step: int) -> void:
	var n := choices().size()
	if n > 0:
		choice = posmod(choice + step, n)


## Takes choice `i` (the cursor's when -1): sets its flags and jumps where it says.
func pick(i := -1) -> bool:
	var list := choices()
	if i < 0:
		i = choice
	if i >= list.size():
		return false
	var c: Dictionary = list[i]
	_set_flags(c.get("set", {}))
	_go(c.get("next", ""), index + 1)
	return true


## To line `target` ("" = the line at `fallback`, "end" = finish), passing through branch
## lines ({"if": flag, "then": id}: jump when the flag is set, else go on to the next line).
func _go(target: String, fallback := 0) -> void:
	var i := fallback if target == "" else (-1 if target == "end" else int(_ids[target]))
	for _step in lines.size() + 1:
		if i < 0 or i >= lines.size():
			break
		var l: Dictionary = lines[i]
		if not l.has("if"):
			index = i
			shown = text().length() if instant else 0
			choice = 0
			_wait = 0.0
			_set_flags(l.get("set", {}))
			return
		i = int(_ids[l.then]) if is_set(l["if"]) else i + 1
	index = -1


func is_set(flag: String) -> bool:
	var v: Variant = flags.get(flag, false)
	if v is String:
		return v != ""
	return (v is bool and v) or (v is int and v != 0)


func _set_flags(values: Dictionary) -> void:
	for k in values:
		flags[k] = flag_value(values[k])


# --- checking the data ------------------------------------------------------

## A flag value as it is kept: true / false, a whole number or a word; null when it is
## none of those (JSON numbers come back as floats).
static func flag_value(v: Variant) -> Variant:
	if v is bool or v is String:
		return v
	if (v is int or v is float) and v == floorf(v) and absf(v) < float(1 << 50):
		return int(v)
	return null


static func _flags_ok(values: Variant) -> bool:
	if not values is Dictionary:
		return false
	for k in values:
		if not k is String or k == "" or flag_value(values[k]) == null:
			return false
	return true


## "" when `data` is a dialogue we can run, else what is wrong with it.
func _check(data: Variant, who: Dictionary) -> String:
	if not data is Dictionary:
		return "Dialogue is not a dictionary"
	if not data.get("lines") is Array or data.lines.is_empty():
		return "Dialogue has no lines"
	lines = data.lines
	_ids = {}
	for i in lines.size():
		var l: Variant = lines[i]
		if not l is Dictionary:
			return "Line %d is not a dictionary" % i
		for k in l:
			if not k in LINE_KEYS:
				return "Line %d has an unknown key %s" % [i, k]
		if l.has("id"):
			if not l.id is String or l.id == "" or l.id == "end" or _ids.has(l.id):
				return "Line %d has a bad or repeated id" % i
			_ids[l.id] = i
	for i in lines.size():
		var err := _check_line(lines[i], who)
		if err != "":
			return "Line %d: %s" % [i, err]
	return ""


func _check_line(l: Dictionary, who: Dictionary) -> String:
	if l.has("if"):
		if not l["if"] is String or l["if"] == "" or not _target_ok(l.get("then")) or l.then == "end":
			return "a branch needs a flag and a line to jump to"
		for k in l:
			if not k in ["id", "if", "then"]:
				return "a branch has no %s" % k
		return ""
	if l.has("then"):
		return "then without if"
	if not l.get("text") is String or l.text.strip_edges() == "":
		return "no text"
	var missing := PixelFont.missing(l.text)
	if missing != "":
		return "the font can't draw %s" % missing
	if TextBoxLayout.wrap_rows(l.text, TextBoxLayout.TEXT_W).size() > TextBoxLayout.ROWS:
		return "the text doesn't fit in the box"
	if l.has("speaker"):
		if not l.speaker is String or l.speaker.begins_with("_") or not who.get(l.speaker) is Dictionary:
			return "unknown speaker %s" % str(l.speaker)
	if l.has("face") and (not l.has("speaker") or not l.face in EXPRESSIONS):
		return "bad face %s" % str(l.face)
	if l.has("mood"):
		if not l.has("speaker") or not l.mood is String or l.mood == "":
			return "bad mood %s" % str(l.mood)
		if l.has("face"):
			return "a line has a face or a mood, not both"
	if l.has("next") and not _target_ok(l.next):
		return "next goes nowhere"
	if l.has("set") and not _flags_ok(l.set):
		return "bad flags"
	if l.has("choices"):
		if l.has("next"):
			return "a line with choices has no next"
		var list: Variant = l.choices
		if not list is Array or list.is_empty() or list.size() > MAX_CHOICES:
			return "choices must be 1 to %d" % MAX_CHOICES
		for c in list:
			if not c is Dictionary or not c.get("text") is String or c.text == "":
				return "a choice has no text"
			if PixelFont.missing(c.text) != "" or PixelFont.width(c.text) > TextBoxLayout.CHOICE_TEXT_W:
				return "choice %s doesn't fit" % c.text
			for k in c:
				if not k in ["text", "next", "set"]:
					return "a choice has no %s" % k
			if c.has("next") and not _target_ok(c.next):
				return "choice %s goes nowhere" % c.text
			if c.has("set") and not _flags_ok(c.set):
				return "choice %s has bad flags" % c.text
	return ""


func _target_ok(t: Variant) -> bool:
	return t is String and (t == "end" or _ids.has(t))
