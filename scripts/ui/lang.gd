class_name Lang
extends RefCounted
## The player's language. The game is written in English; another language is a set of
## tables in data/lang/<id>/*.json ({"text": {"English": "translation"}}), keyed by the English
## text as it is shown. A key with %s / %d (or %02d) is a pattern: "Bought %s" matches
## "Bought Turnip seeds", the %s part is looked up again ("Turnip seeds"), the %d part kept.
## A translation puts the parts back in order at its own %s / %d, or by number at {1}, {2}...
## A multi-line text with no entry of its own is looked up line by line. Text with no entry
## stays in English (the fallback).
##
## Text glued from several keys has no entry of its own, so code keeps each key whole:
## one format per sentence ("Found %s (rucksack full)."), join() for sentences said together,
## list() for "a, b and c". LangCatalog lists the keys; tools/lang_report.gd counts them.
##
## PSEUDO is a test language with no tables: every text comes out about a third wider
## (padded with "="), to see whether a longer language still fits (`-- --lang=pseudo`).
##
## Labels translate themselves: set_language() puts a LangTranslation into Godot's
## TranslationServer, so every Label's text goes through t() as it is drawn. Code that
## measures or wraps text itself (the text box, widths) calls t() / PixelFont.shown_width().

const DIR := "res://data/lang/"
const DEFAULT := "en"
const PSEUDO := "pseudo"
const PSEUDO_GROW := 0.3   # German runs about 30% longer than English
const PSEUDO_PAD := "="

static var current := DEFAULT
static var _table: Dictionary = {}     # English -> translation, for `current`
static var _patterns: Array = []       # [RegEx, [kinds "s" / "d"], translation], most specific first
static var _cache: Dictionary = {}
static var _translations: Dictionary = {}   # language -> its LangTranslation in the TranslationServer


## The languages there are tables for, and English.
static func languages() -> Array[String]:
	var out: Array[String] = [DEFAULT]
	for d in DirAccess.get_directories_at(DIR):
		out.append(d)
	return out


## Switch the language (an unknown one is English). Labels on screen redraw in it at once.
static func set_language(id: String) -> void:
	if id != DEFAULT and id != PSEUDO and not DirAccess.dir_exists_absolute(DIR + id):
		id = DEFAULT
	if id != current or (_table.is_empty() and id != DEFAULT):
		current = id
		_load(id)
	if id == DEFAULT:
		release()
	elif not _translations.has(id):
		var tr := LangTranslation.new()
		tr.locale = id
		TranslationServer.add_translation(tr)
		_translations[id] = tr
	if TranslationServer.get_locale() != id:
		TranslationServer.set_locale(id)


## Takes our translations out of the TranslationServer (English, and at quit: the server
## outlives the scripts, so it must not hold one).
static func release() -> void:
	for tr in _translations.values():
		TranslationServer.remove_translation(tr)
	_translations = {}


## Every entry of language `id`'s tables, read fresh (tests check them).
static func table(id: String) -> Dictionary:
	var out := {}
	var dir := DIR + id + "/"
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".json"):
			continue
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + file))
		if d is Dictionary and d.get("text") is Dictionary:
			for k in d.text:
				if not String(k).begins_with("_"):
					out[k] = d.text[k]
	return out


static func _load(id: String) -> void:
	_cache = {}
	_patterns = []
	_table = {} if id in [DEFAULT, PSEUDO] else table(id)
	for key in _table:
		var p := pattern(String(key))
		if not p.is_empty():
			_patterns.append([p[0], p[1], String(_table[key]), String(key).length() - p[1].size() * 2])
	_patterns.sort_custom(func(a, b): return a[3] > b[3])


## A key with %s / %d as [RegEx matching the text it stands for, kinds "s" / "d" in order];
## [] for a plain key.
static func pattern(k: String) -> Array:
	var found := RegEx.create_from_string("%0?\\d?[sd]").search_all(k)
	if found.is_empty():
		return []
	var src := "^"
	var kinds := []
	var at := 0
	for m in found:
		src += _escape(k.substr(at, m.get_start() - at))
		var is_num := m.get_string().ends_with("d")
		src += "(-?\\d+)" if is_num else "(.+?)"
		kinds.append("d" if is_num else "s")
		at = m.get_end()
	var re := RegEx.create_from_string(src + _escape(k.substr(at)) + "$")
	return [re, kinds] if re.is_valid() else []


static func _escape(s: String) -> String:
	var out := ""
	for ch in s:
		out += ("\\" + ch) if ch in "\\^$.|?*+()[]{}" else ch
	return out


## `text` in the player's language (English: as it is).
static func t(text: String) -> String:
	if current == DEFAULT or text == "":
		return text
	if _cache.has(text):
		return _cache[text]
	var out := _stretch(text) if current == PSEUDO else PixelFont.shape(_find(text, 0))
	if _cache.size() > 4000:
		_cache = {}
	_cache[text] = out
	return out


## Pieces said together (the sentences of one message), each looked up on its own.
static func join(parts: Array, sep := " ") -> String:
	var out := PackedStringArray()
	for p in parts:
		if str(p) != "":
			out.append(t(str(p)))
	return sep.join(out)


## "a", "a and b", "a, b and c", built from the keys "%s, %s" and "%s and %s" so a table
## words the list its own way. English out; Labels translate it as they draw.
static func list(items: Array) -> String:
	if items.is_empty():
		return ""
	var head := str(items[0])
	for i in range(1, items.size() - 1):
		head = "%s, %s" % [head, items[i]]
	return head if items.size() == 1 else "%s and %s" % [head, items.back()]


## PSEUDO: each line with letters padded to PSEUDO_GROW wider (a line padded already, e.g.
## join()'s pieces drawn by a Label, is left as it is).
static func _stretch(text: String) -> String:
	var lines := PackedStringArray()
	for line in text.split("\n"):
		var w := PixelFont.width(line)
		if w > 0 and not line.ends_with(PSEUDO_PAD) and RegEx.create_from_string("[A-Za-z]").search(line) != null:
			line += PSEUDO_PAD.repeat(ceili(w * PSEUDO_GROW / maxf(PixelFont.width(PSEUDO_PAD), 1.0)))
		lines.append(line)
	return "\n".join(lines)


## Whether `text` has an entry (exact or by pattern) in the current language.
static func has(text: String) -> bool:
	if current == DEFAULT:
		return false
	if _table.has(text) or _table.has(text.left(1).to_upper() + text.substr(1)):
		return true
	for p in _patterns:
		if p[0].search(text) != null:
			return true
	return false


## Whether `text` comes out wholly in the current language: an entry, or a pattern whose %s
## parts are all covered too (a loose pattern like "%s, %s" alone doesn't count), or every line.
static func covered(text: String, depth := 0) -> bool:
	if current == DEFAULT or text == "":
		return current == DEFAULT
	if _table.has(text) or _table.has(text.left(1).to_upper() + text.substr(1)):
		return true
	if depth > 3:
		return false
	for p in _patterns:
		var m: RegExMatch = p[0].search(text)
		if m == null:
			continue
		for i in p[1].size():
			if p[1][i] == "s" and not covered(m.get_string(i + 1), depth + 1):
				return false
		return true
	if "\n" in text:
		for line in text.split("\n"):
			if not covered(line, depth):
				return false
		return true
	return false


static func _find(text: String, depth: int) -> String:
	if _table.has(text):
		return _table[text]
	var upper := text.left(1).to_upper() + text.substr(1)   # "Made grilled fish": names lowered in a sentence
	if upper != text and _table.has(upper):
		return _table[upper]
	if depth > 3:
		return text
	for p in _patterns:
		var m: RegExMatch = p[0].search(text)
		if m == null:
			continue
		var parts := []
		for i in p[1].size():
			var s := m.get_string(i + 1)
			parts.append(s if p[1][i] == "d" else _find(s, depth + 1))
		return _fill(p[2], parts)
	if "\n" in text:
		var lines := PackedStringArray()
		for line in text.split("\n"):
			lines.append(_find(line, depth))
		return "\n".join(lines)
	return text


## The translation with its parts put in: {n} by number, else %s / %d in order.
static func _fill(pattern: String, parts: Array) -> String:
	var out := pattern
	for i in parts.size():
		out = out.replace("{%d}" % (i + 1), parts[i])
	var at := 0
	var res := ""
	var i := 0
	while at < out.length():
		var c := out[at]
		if c == "%" and at + 1 < out.length() and out[at + 1] in "sd" and i < parts.size():
			res += str(parts[i])
			i += 1
			at += 2
		else:
			res += c
			at += 1
	return res
