class_name LangCatalog
extends RefCounted
## The English text a language's tables (data/lang/<id>, Lang) have to cover, gathered from
## where it is written: every dialogue line and choice (data/dialogue), the words in the other
## data files (names, labels, messages: any string that reads as words), and the string
## literals in the scripts that reach the screen. Keys are the text as written, %s / %d left
## in, so they are the same keys a table uses.
##
## The scripts are read as text, not run, so a few rules keep out what the player never sees:
## comments, print / push_error / assert lines, the data checks (functions named check... /
## _read...: their messages are for us), ids and paths, art and sound scripts, and NOT_SHOWN.
## A literal that starts or ends with a space is a piece glued to other text (fragments()):
## a table can't translate those, so the code should use one whole format instead.

const DATA_DIR := "res://data/"
const SCRIPTS_DIR := "res://scripts/"
## Data with no words for the player (or the tables themselves).
const DATA_SKIP := ["lang", "font_pixel.json", "camera.json", "light.json", "sfx.json",
	"music.json", "weather_fx.json", "snow_cover.json", "text_box.json", "whistles.json",
	"showcase.json"]   # the trailer views' names are file names for tools/showcase.py
## Data keys whose strings aren't shown.
## (taught: where a recipe's lesson comes from, a note for people reading data/recipes.json.)
const KEY_SKIP := ["bus", "id", "key", "sound", "texture", "art", "look", "face", "mood", "taught"]
## Script folders with no shown text (pixel rows, synth keys).
const SCRIPT_SKIP := ["art/", "audio/"]
## Functions whose strings are messages for us (data checks), not the player.
const FUNC_SKIP := "^_?(check|read|steps|load)(_|$)"
const CALL_SKIP := "\\b(print|prints|printerr|print_debug|push_error|push_warning|assert)\\s*\\("
## Literals in the scripts that look like words but aren't shown (or stay as they are).
const NOT_SHOWN := [
	"SFX", "Master",          # audio bus names
	"Held", "Note",           # node names
	"Pools", "Halos", "Panes", "Glows", "Figures", "Sprite3D",   # night light layers, a class name
	"[A-Za-z]", "{%d}", "%s: \"%s\"",   # a pattern, a placeholder, the lang report's own line
	"Harvest Son",            # the game's name stays as it is in every language
	"ps vita",                # a word looked for in a pad's name (Controls.style_of)
	"Esc",                    # key names stay as on the keyboard
	"Harvest Son Pixel",      # the font's resource name
	"No dialogue %s", "No line %s", "Dialogue is not a dictionary", "No event %s",
	"Event is not a dictionary", "Can't read event %s", "Can't read dialogue %s",   # broken data, for us
	"TOOLS", "%s,", "The save file is from a newer",   # a constant's name, a saved list, a prefix compared
	"Game", "/root/Game",     # the autoload's node name and path
	"Figure", "Cradle", "Drift", "DyeCloth", "Ferry", "Puddles", "Lamp%d", "FieldCopy", "Field",
	"FigureLift", "Icicles", "Washes", "Finishes", "WindSway", "FerryBoat", "Pole", "ShaderWarm", "WarmLamp",
	"SpriteShadow",           # node names
	"StandardMaterial3D", "GeometryInstance3D",   # class names
	"//ICE//",                # a marker in the water shader's code
	"%s %d",                  # Child.help_text's fallback when data/child.json has no message
]


## English text -> Array of where it is written ("data/crops.json", "scripts/x.gd:12").
static func gather() -> Dictionary:
	var out := {}
	_data(DATA_DIR, out)
	_scripts(SCRIPTS_DIR, out, _one_words())
	return out


## The keys of `gather()` in three parts: "dialogue", "data" and "code".
static func parts(cat: Dictionary) -> Dictionary:
	var out := {"dialogue": [], "data": [], "code": []}
	for k in cat:
		var at := String(cat[k][0])
		var part := "code" if at.begins_with("scripts/") else ("dialogue" if at.begins_with("data/dialogue/") else "data")
		out[part].append(k)
	return out


## How far language `id` covers `cat`: {"done": [...], "missing": [...], "stale": [table keys
## no text uses: the English changed or went]}. A pattern key is used when it matches a text
## ("Learned a recipe: %s." for the lesson lines) or a key ("%s x%d").
static func report(id: String, cat: Dictionary) -> Dictionary:
	var before := Lang.current
	Lang.set_language(id)
	var done := []
	var missing := []
	for k in cat:
		(done if Lang.covered(k) else missing).append(k)
	var stale := []
	for k in Lang.table(id):
		if not _used(String(k), cat):
			stale.append(k)
	Lang.set_language(before)
	return {"done": done, "missing": missing, "stale": stale}


static func _used(k: String, cat: Dictionary) -> bool:
	if cat.has(k) or cat.has(k.left(1).to_lower() + k.substr(1)) or cat.has(k.left(1).to_upper() + k.substr(1)):
		return true
	var p := Lang.pattern(k)
	if p.is_empty():
		return false
	for text in cat:
		if p[0].search(text) != null:
			return true
	return false


## Literals in the scripts that are pieces of a sentence (a space at either end).
static func fragments(cat: Dictionary) -> Array:
	var out := []
	for k in cat:
		var s := String(k)
		if String(cat[k][0]).begins_with("scripts/") and s.strip_edges() != s:
			out.append("%s: \"%s\"" % [cat[k][0], s])
	return out


static func _add(out: Dictionary, text: String, at: String) -> void:
	if not out.has(text):
		out[text] = []
	out[text].append(at)


## Words, not an id, a path, a colour or a number.
static func _words(s: String) -> bool:
	if s.begins_with("res://") or s.begins_with("user://") or s.begins_with("--") or s.begins_with("shader_type"):
		return false
	if "\\" in s or "|" in s or s.begins_with("^"):   # a pattern or a key, not words
		return false
	return RegEx.create_from_string("[A-Za-z]").search(s) != null \
		and RegEx.create_from_string("^[a-z0-9_:./@%*<>#-]*$").search(s) == null


# --- data ---

static func _data(dir: String, out: Dictionary) -> void:
	for d in DirAccess.get_directories_at(dir):
		if not d in DATA_SKIP:
			_data(dir + d + "/", out)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json") and not f in DATA_SKIP:
			var at := (dir + f).trim_prefix("res://")
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + f))
			_walk(d, at, out)


static func _walk(v: Variant, at: String, out: Dictionary) -> void:
	if v is Dictionary:
		for k in v:
			if String(k).begins_with("_") or k in KEY_SKIP:
				continue
			if v[k] is String:   # one lowercase word is an id, except as a name ("egg", "frozen")
				var named: bool = k == "name" and RegEx.create_from_string("[A-Za-z]").search(v[k]) != null
				if named or (_words(v[k]) and RegEx.create_from_string("[A-Z]|[a-z] [a-z]").search(v[k]) != null):
					_add(out, v[k], at)
			else:
				_walk(v[k], at, out)
	elif v is Array:
		for e in v:
			_walk(e, at, out)


# --- scripts ---

static func _scripts(dir: String, out: Dictionary, shown: Dictionary) -> void:
	for d in DirAccess.get_directories_at(dir):
		if not (d + "/") in SCRIPT_SKIP:
			_scripts(dir + d + "/", out, shown)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			_script(dir + f, out, shown)


static func _script(path: String, out: Dictionary, shown: Dictionary) -> void:
	var at := path.trim_prefix("res://")
	var func_re := RegEx.create_from_string("^\\s*(static\\s+)?func\\s+(\\w+)")
	var skip_func := RegEx.create_from_string(FUNC_SKIP)
	var skip_call := RegEx.create_from_string(CALL_SKIP)
	var in_func := ""
	var in_long := false   # inside a """ string (shader code)
	var n := 0
	for line in FileAccess.get_file_as_string(path).split("\n"):
		n += 1
		if in_long:
			in_long = line.count("\"\"\"") % 2 == 0
			continue
		var m := func_re.search(line)
		if m != null:
			in_func = m.get_string(2)
		elif not line.begins_with("\t") and line.strip_edges() != "" and not line.begins_with("#"):
			in_func = ""   # back at the top of the file
		if line.count("\"\"\"") % 2 == 1:
			in_long = true
			continue
		if skip_call.search(line) != null or (in_func != "" and skip_func.search(in_func) != null):
			continue
		for s in _literals(line):
			if (_words(s) or s in shown) and not s in NOT_SHOWN:
				_add(out, s, "%s:%d" % [at, n])


## One lowercase word in a script ("ready") reads like an id; it counts as shown text when
## some language's table has it (someone found it on screen).
static func _one_words() -> Dictionary:
	var out := {}
	for id in Lang.languages():
		if id != Lang.DEFAULT:
			for k in Lang.table(id):
				if RegEx.create_from_string("^[a-z]+$").search(String(k)) != null:
					out[k] = true
	return out


## The "..." and '...' strings on one line of GDScript, unescaped, before any # comment
## (StringName &"" and NodePath ^"" left out).
static func _literals(line: String) -> Array[String]:
	var found: Array[String] = []
	var i := 0
	while i < line.length():
		var c := line[i]
		if c == "#":
			break
		if c != "\"" and c != "'":
			i += 1
			continue
		var kind := line[i - 1] if i > 0 else ""
		var s := ""
		i += 1
		while i < line.length() and line[i] != c:
			if line[i] == "\\" and i + 1 < line.length():
				i += 1
				s += {"n": "\n", "t": "\t"}.get(line[i], line[i])
			else:
				s += line[i]
			i += 1
		i += 1
		if kind != "&" and kind != "^":
			found.append(s)
	return found
