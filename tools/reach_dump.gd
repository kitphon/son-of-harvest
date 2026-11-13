extends SceneTree
## Measuring tool (FarmWorld.wall_pull, ReachMap): for every map (or `-- --only=<id>`), builds its 3D world and prints
## the build time, the reach's size, the walkable cells the low geometry reaches into, and where a figure's
## pull changes with the reach. Run: Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/reach_dump.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var g := root.get_node("Game")
	g.new_game()
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	var ids: Array[String] = []
	for f in DirAccess.get_files_at("res://data/maps"):
		ids.append(f.get_basename())
	for id in ids:
		if only != "" and id != only:
			continue
		var m = load("res://scripts/world/map_manager.gd").data(id)
		if m == null or m.farm or id.begins_with("mine"):
			continue
		var w = load("res://scripts/world3d/map_world.gd").new()
		root.add_child(w)
		var t0 := Time.get_ticks_usec()
		w.build(m)
		var t1 := Time.get_ticks_usec()
		var counts := {}
		var per := int(1.0 / w.reach.res)
		for k in w.reach.tiles:
			var fx: int = (k & 0xffff) - 4096
			var fz: int = (k >> 16) - 4096
			var c := Vector2i(floori(float(fx) / per), floori(float(fz) / per))
			if m.in_bounds(c) and not m.is_solid(c):
				counts[c] = int(counts.get(c, 0)) + 1
		var list := []
		for c in counts:
			if counts[c] >= 3:
				list.append("%d,%d:%d" % [c.x, c.y, counts[c]])
		var fw = load("res://scripts/world3d/farm_world.gd")
		var l := CameraLens.pick(JSON.parse_string(FileAccess.get_file_as_string("res://data/camera.json")), "medium")
		var tg := Vector3(10.5, 0, 10.5)
		var cam := Transform3D(Basis(), tg + l.back * l.dist).looking_at(tg, Vector3.UP)
		var solid := func(c: Vector2i) -> bool: return m.is_solid(c)
		var diff := []
		var worst := 0.0
		for y in m.h:
			for x in m.w:
				if m.is_solid(Vector2i(x, y)):
					continue
				for off in [Vector2(0.5, 0.5), Vector2(0.5, 0.19), Vector2(0.81, 0.5), Vector2(0.19, 0.5), Vector2(0.5, 0.81)]:
					var feet := Vector3(x + off.x, 0, y + off.y)
					var a: float = fw.wall_pull(feet, 0.3, 0.3, cam, solid)
					var b: float = fw.wall_pull(feet, 0.3, 0.3, cam, solid, {}, w.reach)
					if b > a + 0.03:
						diff.append("%.2f,%.2f:%.2f>%.2f" % [feet.x, feet.z, a, b])
						worst = maxf(worst, b - a)
		print("   pulls changed at %d spots (worst +%.2f): %s" % [diff.size(), worst, " ".join(diff.slice(0, 25))])
		print("%s: build %.0f ms (reach part %d tiles, rasterized %d) walkable cells reached: %d  %s" % [id, (t1 - t0) / 1000.0, w.reach.count(), load("res://scripts/world3d/reach_map.gd").built, list.size(), " ".join(list.slice(0, 60))])
		w.queue_free()
	quit()
