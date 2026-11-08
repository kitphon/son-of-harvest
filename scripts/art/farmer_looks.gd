class_name FarmerLooks
extends RefCounted
## The farmer's look chosen on a new game: a hair style, a hair colour, a skin tone and a set of
## clothes, each one of the choices in data/farmer_looks.json. Looks only: nothing in the rules
## reads it. A choice is {"style": id, "hair": id, "skin": id, "clothes": id}; the first id of
## each list is the farmer's old look, so FigureArt draws the default exactly as before.
##
## `current` is the look the game's farmer has now (Game.farmer_look sets it); PlaceholderArt
## draws the "player:..." pictures from it and keeps them apart per look (cache_key).

const PATH := "res://data/farmer_looks.json"
const PARTS: Array[String] = ["style", "hair", "skin", "clothes"]

static var current: Dictionary = {}:   # {} or a full choice; {} is the default
	set(v):
		current = v
		_sig = signature(v)
static var _sig := ""   # signature(current), kept: the farmer's sprite asks every frame
static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _data


## The choices of one part, in order (the first is the default).
static func options(part: String) -> Array:
	return data().get(part, [])


static func ids(part: String) -> Array[String]:
	var out: Array[String] = []
	for o in options(part):
		out.append(str(o.id))
	return out


static func default_choice() -> Dictionary:
	var d := {}
	for part in PARTS:
		d[part] = ids(part)[0]
	return d


## A full choice from `choice`: a part missing, not a word or not in the data (a choice taken
## out of the data later) is the default's.
static func normalize(choice: Dictionary) -> Dictionary:
	var d := default_choice()
	for part in PARTS:
		var v = choice.get(part)
		if v is String and v in ids(part):
			d[part] = v
	return d


static func is_default(choice: Dictionary) -> bool:
	return normalize(choice) == default_choice()


## A saved look as a full choice, or null when it is broken (not a dictionary of parts to
## words). An id the data no longer has falls back to the default: it is looks only, so the
## save still loads.
static func parse(v: Variant) -> Variant:
	if not v is Dictionary:
		return null
	for k in v:
		if not k is String or not k in PARTS or not v[k] is String:
			return null
	return normalize(v)


## The option of `part` the choice has.
static func option(choice: Dictionary, part: String) -> Dictionary:
	var id := str(normalize(choice)[part])
	for o in options(part):
		if o.id == id:
			return o
	return options(part)[0]


static func index_of(choice: Dictionary, part: String) -> int:
	return ids(part).find(str(normalize(choice)[part]))


## The choice with `part` stepped by `step` through its options, wrapping round.
static func stepped(choice: Dictionary, part: String, step: int) -> Dictionary:
	var d := normalize(choice)
	var list := ids(part)
	d[part] = list[posmod(list.find(d[part]) + step, list.size())]
	return d


## The FigureArt look of a choice: the farmer's own look with the chosen colours and style.
static func figure_look(choice: Dictionary) -> Dictionary:
	var look := FigureArt.FARMER_LOOK.duplicate()
	var style := option(choice, "style")
	var clothes := option(choice, "clothes")
	for k in ["top", "waist", "lower", "accent", "shoes"]:
		look[k] = str(clothes[k])
	look.hair_style = str(style.hair_style)
	if style.has("accent"):
		look.accent = str(style.accent)
	look.hair = str(option(choice, "hair").color)
	look.skin = str(option(choice, "skin").color)
	return look


## The look of the game's farmer now.
static func current_look() -> Dictionary:
	return figure_look(current)


## "" for the default look, else the ids joined: what tells one look's pictures from another's.
static func signature(choice: Dictionary) -> String:
	if is_default(choice):
		return ""
	var d := normalize(choice)
	var parts: Array[String] = []
	for part in PARTS:
		parts.append(str(d[part]))
	return ".".join(parts)


## The cache key of an art key: a "player:..." picture is drawn from the current look, so it
## carries the look's signature (the default's keys stay as they were).
static func cache_key(key: String) -> String:
	if not key.begins_with("player:"):
		return key
	return key if _sig == "" else key + "@" + _sig


## A debug flag's look (`--look=style:2,hair:1,skin:3,clothes:4`): each part by its place in
## the list (0 = the default) or by its id; parts left out keep the default.
static func from_flag(text: String) -> Dictionary:
	var d := default_choice()
	for piece in text.split(",", false):
		var kv := piece.split(":")
		if kv.size() != 2 or not kv[0] in PARTS:
			push_warning("No look part " + piece)
			continue
		var list := ids(kv[0])
		var i := int(kv[1]) if kv[1].is_valid_int() else list.find(kv[1])
		if i < 0 or i >= list.size():
			push_warning("No look " + piece)
			continue
		d[kv[0]] = list[i]
	return d
