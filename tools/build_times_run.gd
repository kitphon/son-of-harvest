extends RefCounted
## The work of tools/build_times.gd, loaded at run time (it names classes that reach the Game
## autoload, which a --script tool only has once it runs).

var root: Window
var _lines: Array[String] = []   # the steps' times, printed after the build (a print is slow)


func _time(g: Node, id: String, parts: bool) -> float:
	var m: MapData = MapManager.data(id)
	var t0 := Time.get_ticks_usec()
	var w: FarmWorld
	if m.farm:
		w = FarmWorld.new()
		if parts:
			_steps(w, g, m)
		else:
			w.setup(g.farm, m.gate_cells())
		w.make_story_props(m)
	else:
		w = MapWorld.new()
		if parts:
			_steps(w, g, m)
		else:
			(w as MapWorld).build(m)
	var t1 := Time.get_ticks_usec()
	root.add_child(w)
	var t2 := Time.get_ticks_usec()
	root.remove_child(w)
	w.free()
	for line in _lines:
		print(line)
	_lines.clear()
	if parts:
		print("  %s: build %.1f, into the tree %.1f" % [id, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0])
	return (t2 - t0) / 1000.0


## Each build step (FarmWorld.setup_steps, MapWorld.build_steps) timed, the props summed by kind.
func _steps(w: FarmWorld, g: Node, m: MapData) -> void:
	var steps: Array[Callable] = w.setup_steps(g.farm, m.gate_cells()) if m.farm else (w as MapWorld).build_steps(m)
	var names := {}
	var order: Array = []
	for i in steps.size():
		var step := steps[i]
		var what := step.get_method()
		if what == "occlude" and not m.farm:
			what = "prop " + str(m.props[i - 2].kind)
		var t := Time.get_ticks_usec()
		step.call()
		if not names.has(what):
			names[what] = 0.0
			order.append(what)
		names[what] += (Time.get_ticks_usec() - t) / 1000.0
	for what in order:
		_lines.append("    %-24s %7.1f ms" % [what, names[what]])

