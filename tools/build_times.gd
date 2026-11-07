extends SceneTree
## Times the 3D world build of every map (FarmWorld.setup / MapWorld.build plus entering the
## tree), the first build in this run (cold: pictures drawn, meshes made) and a second one
## (warm: what the class-level caches keep). With a window (no --headless) the renderer's own
## work is in it too. Run:
##   Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/build_times.gd [-- --maps=farm,town --parts]
## `--parts` also prints each build step's time, the props summed by kind.

var _frame := 0


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	var g: Node = root.get_node("Game")
	g.new_game()
	var ids: Array = MapManager.ids()
	var parts := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--maps="):
			ids = Array(a.substr(7).split(","))
		parts = parts or a == "--parts"
	ids.erase("mine_floor")   # built from a floor seed, never kept
	var run: RefCounted = load("res://tools/build_times_run.gd").new()
	run.root = root
	var rows := []
	for id in ids:
		var cold: float = run._time(g, id, parts)
		var warm: float = run._time(g, id, parts)
		rows.append([id, cold, warm])
	var total := [0.0, 0.0]
	for r in rows:
		print("build %-14s cold %7.1f ms   warm %7.1f ms" % r)
		total[0] += r[1]
		total[1] += r[2]
	print("build %-14s cold %7.1f ms   warm %7.1f ms" % ["(all)", total[0], total[1]])
	quit()
	return true


