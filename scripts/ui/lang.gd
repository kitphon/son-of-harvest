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
## Labels translate themselves: set_language() puts a LangTranslation into Godot's
## TranslationServer, so every Label's text goes through t() as it is drawn. Code that
## measures or wraps text itself (the text box, widths) calls t() / PixelFont.shown_width().

const DIR := "res://data/lang/"
const DEFAULT := "en"

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
	if id != DEFAULT and not DirAccess.dir_exists_absolute(DIR + id):
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
	_table = {} if id == DEFAULT else table(id)
	var placeholder := RegEx.create_from_string("%0?\\d?[sd]")
	for key in _table:
		var k := String(key)
		var found := placeholder.search_all(k)
		if found.is_empty():
			continue
		var src := "^"
		var kinds := []
		var at := 0
		for m in found:
			src += _escape(k.substr(at, m.get_start() - at))
			var is_num := m.get_string().ends_with("d")
			src += "(-?\\d+)" if is_num else "(.+?)"
			kinds.append("d" if is_num else "s")
			at = m.get_end()
		src += _escape(k.substr(at)) + "$"
		var re := RegEx.create_from_string(src)
		if re.is_valid():
			_patterns.append([re, kinds, String(_table[key]), k.length() - found.size() * 2])
	_patterns.sort_custom(func(a, b): return a[3] > b[3])


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
	var out := PixelFont.shape(_find(text, 0))
	if _cache.size() > 4000:
		_cache = {}
	_cache[text] = out
	return out


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
