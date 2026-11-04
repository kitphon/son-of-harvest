extends SceneTree
## How far each language's tables (data/lang/<id>) cover the game's English (LangCatalog):
## per part (dialogue, data, code) the lines done and still missing, the table entries no text
## uses any more (stale: the English changed), and the script literals glued to other text.
## Writes build/lang/<id>_todo.json, a table of the missing lines with empty translations, in
## the tables' own format, for a translator to fill in and move to data/lang/<id>/. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/lang_report.gd
## `-- --lang=th` reports one language; `-- --list` prints every missing line; `-- --english`
## also writes build/lang/english.txt, every English text under the place it is written (for
## reading the source text through).

const OUT := "res://build/lang/"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var only := ""
	for a in args:
		if a.begins_with("--lang="):
			only = a.trim_prefix("--lang=")
	var cat := LangCatalog.gather()
	var parts := LangCatalog.parts(cat)
	print("English: %d texts (dialogue %d, data %d, code %d)" % [cat.size(), parts.dialogue.size(), parts.data.size(), parts.code.size()])
	var glued := LangCatalog.fragments(cat)
	print("Glued pieces in the scripts: %d" % glued.size())
	for g in glued:
		print("  " + g)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if "--english" in args:
		_english(cat)
	for id in Lang.languages():
		if id == Lang.DEFAULT or (only != "" and id != only):
			continue
		var r := LangCatalog.report(id, cat)
		print("\n%s: %d of %d done (%d%%), %d missing, %d stale" % [id, r.done.size(), cat.size(),
			100 * r.done.size() / maxi(cat.size(), 1), r.missing.size(), r.stale.size()])
		for p in ["dialogue", "data", "code"]:
			var miss := 0
			for k in parts[p]:
				if k in r.missing:
					miss += 1
			print("  %-8s %4d of %4d done" % [p, parts[p].size() - miss, parts[p].size()])
		for k in r.stale:
			print("  stale: \"%s\"" % k)
		var todo := {}
		for k in r.missing:
			todo[k] = ""
			if "--list" in args:
				print("  missing (%s): \"%s\"" % [cat[k][0], k])
		var file := OUT + id + "_todo.json"
		var f := FileAccess.open(file, FileAccess.WRITE)
		f.store_string(JSON.stringify({"_note": "Lines still in English for %s (tools/lang_report.gd). Fill in each translation and move the entries into data/lang/%s/." % [id, id], "text": todo}, "\t"))
		f.close()
		print("  wrote %s" % ProjectSettings.globalize_path(file))
	Lang.release()
	quit(0)


func _english(cat: Dictionary) -> void:
	var by_place := {}
	for k in cat:
		var place := String(cat[k][0]).get_slice(":", 0)
		if not by_place.has(place):
			by_place[place] = []
		by_place[place].append(k)
	var places := by_place.keys()
	places.sort()
	var f := FileAccess.open(OUT + "english.txt", FileAccess.WRITE)
	for place in places:
		f.store_line("== " + place)
		for k in by_place[place]:
			f.store_line(String(k).replace("
", "\n"))
	f.close()
	print("wrote %s" % ProjectSettings.globalize_path(OUT + "english.txt"))
