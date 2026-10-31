class_name EventRunner
extends RefCounted
## Plays one event script from data/events/<id>.json step by step, without any drawing, so
## headless tests can check it. A script is a list of steps: dialogue, waits, walking and
## facing the farmer, flags, items, money, a fade and sounds; branch steps jump on a flag. The
## runner keeps the farmer's scripted position / facing and the fade amount; the view
## (EventPlayer) copies them onto the screen. The format is in README.md → Events; bad data is
## refused with `error` set and the runner finished from the start.

signal sound(key: String)   # the view plays it (Sfx)

const DIR := "res://data/events/"
const SFX := "res://data/sfx.json"
const CROPS := "res://data/crops.json"
const T := 16
const MAX_STEPS := 1000     # instant steps in one update, so a loop without a wait can't hang
const DIRS := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT}
## Keys each command takes besides `do`, `id` and `next`.
const COMMANDS := {
	"say": ["dialogue", "at"], "wait": ["seconds"], "face": ["dir"], "walk": ["to", "by", "run"],
	"set": ["flags"], "clear": ["flags"], "give": ["item", "count"], "money": ["amount"],
	"fade": ["to", "seconds"], "sound": ["key"], "affection": ["who", "amount"],
}

var id := ""
var error := ""             # "" or why the script was refused
var steps: Array = []
var index := -1             # the step going on, -1 once finished
var game: Object            # Game (or a test's copy): flags, talk(), dialogue_open, add_item(), add_money(), affection
var pos := Vector2.ZERO     # the farmer's feet, in cell pixels (16 px = 1 cell)
var facing := Vector2i.DOWN
var walking := false
var running := false
var fade := 0.0             # 0 clear .. 1 black
var walk_speed := 60.0      # pixels a second; EventPlayer sets the Player's walk and run speeds
var run_speed := 100.0
var _ids: Dictionary = {}   # step id -> index
var _active := false        # the step at `index` has begun
var _timer := 0.0
var _path: Array[Vector2] = []
var _fade_from := 0.0
var _fade_to := 0.0
var _fade_len := 0.0
var _fade_time := 0.0

static var _sounds: Array
static var _crops: Dictionary


## Event `event_id` from data/events, played for `owner` (Game or a stand-in).
static func open(event_id: String, owner: Object) -> EventRunner:
	var r := EventRunner.new(read(event_id), owner)
	r.id = event_id
	if r.error == "Event is not a dictionary" and read(event_id) == null:
		r.error = "No event %s" % event_id
	return r


static func read(event_id: String) -> Variant:
	var path := DIR + event_id + ".json"
	if not event_id.is_valid_filename() or event_id.begins_with("triggers_") or not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## The sound keys a `sound` step may name (data/sfx.json).
static func sound_keys() -> Array:
	if _sounds.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SFX))
		_sounds = d.get("sounds", {}).keys() if d is Dictionary else []
	return _sounds


## Items a `give` step may hand over: crops and their seed bags ("seeds:<crop>").
static func item_known(item: String) -> bool:
	if _crops.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(CROPS))
		_crops = d if d is Dictionary else {}
	return _crops.has(item.trim_prefix("seeds:"))


## Is `flag` set in `flags`: true, a number other than 0 or a word other than "" (as dialogue).
static func is_set(flags: Dictionary, flag: String) -> bool:
	var v: Variant = flags.get(flag, false)
	if v is String:
		return v != ""
	return (v is bool and v) or (v is int and v != 0)


func _init(data: Variant, owner: Object) -> void:
	game = owner
	error = _check(data)
	if error != "":
		steps = []
		return
	index = 0


## Where the farmer is when the event starts.
func start(at: Vector2, face: Vector2i) -> void:
	pos = at
	facing = face


func done() -> bool:
	return index < 0


func step() -> Dictionary:
	return {} if done() else steps[index]


## Time passes: the step going on goes on; when it ends, the next ones begin. Instant steps
## (flags, items, facing...) all happen in the same update; time left over from a step that
## ends is not carried into the next one.
func update(delta: float) -> void:
	for _n in MAX_STEPS:
		if done():
			return
		var s: Dictionary = steps[index]
		if not _active:
			_active = true
			_begin(s)
		if _going(s, delta):
			return
		delta = 0.0
		_active = false
		_advance(s)


func _begin(s: Dictionary) -> void:
	match s.get("do", ""):
		"say":
			game.talk(s.dialogue, s.get("at", ""))
		"wait":
			_timer = float(s.seconds)
		"face":
			facing = DIRS[s.dir]
		"walk":
			var cell := Vector2i(floori(pos.x / T), floori(pos.y / T))
			var goal := cell + _vec(s.by) if s.has("by") else _vec(s.to)
			var end := Vector2(goal * T) + Vector2(T / 2.0, T / 2.0)
			_path = [Vector2(end.x, pos.y), end]   # across first, then up or down
			running = bool(s.get("run", false))
		"set":
			for k in s.flags:
				game.flags[k] = DialogueRunner.flag_value(s.flags[k])
		"clear":
			for k in s.flags:
				game.flags.erase(k)
		"give":
			game.add_item(s.item, int(s.get("count", 1)))
		"money":
			game.add_money(int(s.amount))
		"affection":
			game.affection.add(s.who, int(s.amount))
		"fade":
			_fade_from = fade
			_fade_to = 1.0 if s.to == "black" else 0.0
			_fade_len = float(s.get("seconds", 0.5))
			_fade_time = 0.0
		"sound":
			sound.emit(s.key)


## True while step `s` still goes on after `delta` more seconds.
func _going(s: Dictionary, delta: float) -> bool:
	match s.get("do", ""):
		"say":
			return bool(game.dialogue_open)
		"wait":
			_timer -= delta
			return _timer > 0.000001   # float sums: 0.3 s is three 0.1 s frames
		"walk":
			var left := (run_speed if running else walk_speed) * delta
			while not _path.is_empty():
				var d := _path[0] - pos
				if d.length() > 0.0001:
					facing = Vector2i(int(signf(d.x)), 0) if absf(d.x) > absf(d.y) else Vector2i(0, int(signf(d.y)))
				if d.length() > left:
					pos += d.normalized() * left
					walking = true
					return true
				left -= d.length()
				pos = _path.pop_front()
			walking = false
			running = false
			return false
		"fade":
			_fade_time += delta
			var t := 1.0 if _fade_len <= 0.0 else clampf(_fade_time / _fade_len, 0.0, 1.0)
			fade = lerpf(_fade_from, _fade_to, t)
			return t < 1.0
	return false


## On to the step after `s`: a branch's `then` when its flag says so, else `next`, else the
## following step. Past the last step (or at "end") the event is over and the screen clear.
func _advance(s: Dictionary) -> void:
	var target: String = s.get("next", "")
	if s.has("if") or s.has("unless"):
		var on := is_set(game.flags, s.get("if", s.get("unless", "")))
		target = s.then if on == s.has("if") else ""
	if target == "end":
		index = steps.size()
	elif target != "":
		index = int(_ids[target])
	else:
		index += 1
	if index >= steps.size():
		index = -1
		fade = 0.0
		walking = false
		running = false


static func _vec(a: Array) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))


# --- checking the data ------------------------------------------------------

## "" when `data` is a script we can run, else what is wrong with it.
func _check(data: Variant) -> String:
	if not data is Dictionary:
		return "Event is not a dictionary"
	if not data.get("steps") is Array or data.steps.is_empty():
		return "Event has no steps"
	steps = data.steps
	_ids = {}
	for i in steps.size():
		var s: Variant = steps[i]
		if not s is Dictionary:
			return "Step %d is not a dictionary" % i
		if s.has("id"):
			if not s.id is String or s.id == "" or s.id == "end" or _ids.has(s.id):
				return "Step %d has a bad or repeated id" % i
			_ids[s.id] = i
	for i in steps.size():
		var err := _check_step(steps[i])
		if err != "":
			return "Step %d: %s" % [i, err]
	return ""


func _check_step(s: Dictionary) -> String:
	if s.has("if") or s.has("unless"):
		var flag: Variant = s.get("if", s.get("unless"))
		if s.has("if") and s.has("unless"):
			return "a branch has if or unless, not both"
		if not flag is String or flag == "" or not _target_ok(s.get("then")) or s.then == "end":
			return "a branch needs a flag and a step to jump to"
		for k in s:
			if not k in ["id", "if", "unless", "then"]:
				return "a branch has no %s" % k
		return ""
	var cmd: Variant = s.get("do")
	if not cmd is String or not COMMANDS.has(cmd):
		return "unknown command %s" % str(cmd)
	for k in s:
		if not k in ["id", "do", "next"] and not k in COMMANDS[cmd]:
			return "%s has no %s" % [cmd, k]
	if s.has("next") and not _target_ok(s.next):
		return "next goes nowhere"
	match cmd:
		"say":
			if not s.get("dialogue") is String or (s.has("at") and not s.at is String):
				return "say needs a dialogue id"
			var r := DialogueRunner.open(s.dialogue, {}, s.get("at", ""))
			if r.error != "":
				return "dialogue %s: %s" % [s.dialogue, r.error]
		"wait":
			if not _number(s.get("seconds"), 0.0, 60.0):
				return "wait needs 0 to 60 seconds"
		"face":
			if not DIRS.has(s.get("dir")):
				return "face needs up, down, left or right"
		"walk":
			if s.has("to") == s.has("by") or not _pair(s.get("to", s.get("by"))):
				return "walk needs to [x, y] or by [dx, dy]"
			if s.has("run") and not s.run is bool:
				return "run is true or false"
		"set":
			if not s.get("flags") is Dictionary or s.flags.is_empty():
				return "set needs flags"
			for k in s.flags:
				if not k is String or k == "" or DialogueRunner.flag_value(s.flags[k]) == null:
					return "bad flag %s" % str(k)
		"clear":
			if not s.get("flags") is Array or s.flags.is_empty():
				return "clear needs a list of flags"
			for k in s.flags:
				if not k is String or k == "":
					return "bad flag %s" % str(k)
		"give":
			if not s.get("item") is String or not item_known(s.item):
				return "unknown item %s" % str(s.get("item"))
			if s.has("count") and not _whole(s.count, 1, 999):
				return "count is 1 to 999"
		"money":
			if not _whole(s.get("amount"), -999999, 999999) or int(s.amount) == 0:
				return "money needs a whole amount"
		"affection":
			if not s.get("who") is String or s.who == "" or not _whole(s.get("amount"), -255, 255) or int(s.amount) == 0:
				return "affection needs who and a whole amount"
		"fade":
			if not s.get("to") in ["black", "clear"]:
				return "fade to black or clear"
			if s.has("seconds") and not _number(s.seconds, 0.0, 10.0):
				return "fade takes 0 to 10 seconds"
		"sound":
			if not s.get("key") in sound_keys():
				return "unknown sound %s" % str(s.get("key"))
	return ""


func _target_ok(t: Variant) -> bool:
	return t is String and (t == "end" or _ids.has(t))


static func _number(v: Variant, lo: float, hi: float) -> bool:
	return (v is int or v is float) and v >= lo and v <= hi


static func _whole(v: Variant, lo: int, hi: int) -> bool:
	return _number(v, lo, hi) and v == floorf(v)


static func _pair(v: Variant) -> bool:
	return v is Array and v.size() == 2 and _whole(v[0], -999, 999) and _whole(v[1], -999, 999)
