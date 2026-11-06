extends SceneTree
## Headless checks for the trailer views (data/showcase.json, tools/showcase.py): the file
## parses, it names 10 to 12 views with unique names, every view is a list of `--` args, and
## every map (with its spawn), festival and lens the views name exists in data/. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_showcase.gd

var failures := 0


func _init() -> void:
	_views()
	print("test_showcase: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


func _views() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/showcase.json"))
	check(data is Dictionary and data.get("views") is Array, "data/showcase.json parses and has a views list")
	if not (data is Dictionary and data.get("views") is Array):
		return
	var views: Array = data.views
	check(views.size() >= 10 and views.size() <= 12, "10 to 12 views (%d)" % views.size())

	var festivals: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/festivals.json")).get("festivals", {})
	var lenses: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/camera.json")).get("lenses", {})

	var names := {}
	var bad_args := []
	var bad_names := []
	var missing := []
	for v in views:
		if not (v is Dictionary and v.get("name") is String and v.get("args") is Array):
			bad_names.append(str(v))
			continue
		var name: String = v.name
		if names.has(name) or not name.is_valid_filename() or name != name.to_lower() or name.contains(" ") or name.contains("."):
			bad_names.append(name)
		names[name] = true
		if v.args.is_empty():
			bad_args.append("%s: no args" % name)
		for arg in v.args:
			if not (arg is String and arg.begins_with("--")):
				bad_args.append("%s: %s" % [name, str(arg)])
				continue
			if arg.begins_with("--map="):
				var parts: PackedStringArray = arg.trim_prefix("--map=").split("@")
				var map_path := "res://data/maps/%s.json" % parts[0]
				if not FileAccess.file_exists(map_path):
					missing.append("%s: map %s" % [name, parts[0]])
				elif parts.size() > 1:
					var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(map_path))
					if not (map.get("spawns") is Dictionary and map.spawns.has(parts[1])):
						missing.append("%s: spawn %s on %s" % [name, parts[1], parts[0]])
			elif arg.begins_with("--festival="):
				var fid: String = arg.trim_prefix("--festival=")
				if not festivals.has(fid):
					missing.append("%s: festival %s" % [name, fid])
			elif arg.begins_with("--lens="):
				var lid: String = arg.trim_prefix("--lens=")
				if not lenses.has(lid):
					missing.append("%s: lens %s" % [name, lid])
	check(bad_names.is_empty(), "view names are unique, a-z 0-9 _, and each has args: %s" % [bad_names])
	check(bad_args.is_empty(), "every arg is a -- flag: %s" % [bad_args.slice(0, 10)])
	check(missing.is_empty(), "every map, spawn, festival and lens named exists: %s" % [missing])
