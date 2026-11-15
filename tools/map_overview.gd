extends SceneTree
## Every map whole in the flat view, one picture each: the real flat scene (scenes/main_2d.tscn)
## in a viewport the size of the map, its own camera over the middle, the HUD and screens hidden.
## The farmer stands at the map's first spawn; the clock is at noon on a fair spring day unless
## `--season=`, `--time=H:MM` say otherwise. Needs a window (not --headless):
##   Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/map_overview.gd -- --out=shots/maps
## (writes shots/maps/<map id>.png at one pixel a pixel; add `--maps=town,farm` for some only).
## `--world` draws the outdoor maps of data/world.json and lays them on one picture as they meet,
## shots/maps/_world.png (one pixel a pixel) and _world_half.png.

const T := 16

var _out := "res://shots/maps"
var _only: Array = []
var _season := "spring"
var _hour := 12
var _minute := 0
var _world := false
var _shots := {}   # map id -> its picture, for --world


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = "res://" + arg.trim_prefix("--out=")
		elif arg.begins_with("--maps="):
			_only = Array(arg.trim_prefix("--maps=").split(",", false))
		elif arg == "--world":
			_world = true
		elif arg.begins_with("--season="):
			_season = arg.trim_prefix("--season=")
		elif arg.begins_with("--time="):
			var hm := arg.trim_prefix("--time=").split(":")
			_hour = int(hm[0])
			_minute = int(hm[1]) if hm.size() > 1 else 0
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var game: Node = root.get_node("Game")
	var maps: GDScript = load("res://scripts/world/map_manager.gd")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	game.new_game()
	game.set("season", ["spring", "summer", "fall", "winter"].find(_season))
	game.weather_today = "sunny"
	game.snow_cover = 0
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json")).maps
	var ids: Array = maps.ids() if _only.is_empty() else _only
	if _world:
		ids = plan.keys()
	for id in ids:
		var m = maps.data(id)
		if m == null:
			print("map_overview: no map ", id)
			continue
		var spawn: Array = m.spawns.values()[0] if not m.spawns.is_empty() else [Vector2i.ZERO, Vector2i.DOWN]
		game.go_to_map(id, Vector2i(spawn[0]), Vector2i.DOWN)
		game.hour = _hour
		game.minute = _minute
		var vp := SubViewport.new()
		vp.size = Vector2i(m.w * T, m.h * T) if id != "farm" else Vector2i(32 * T, 20 * T)
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		root.add_child(vp)
		var scene: Node = load("res://scenes/main_2d.tscn").instantiate()
		vp.add_child(scene)
		for i in 3:
			await process_frame
		for c in scene.get_children():
			if c is CanvasLayer:
				c.visible = false
		var cam := Camera2D.new()
		cam.position = Vector2(vp.size) / 2.0
		scene.add_child(cam)
		cam.make_current()
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		var path := "%s/%s.png" % [_out, id]
		img.save_png(path)
		_shots[id] = img
		print("map_overview: ", path, " ", img.get_size())
		vp.queue_free()
		await process_frame
	if _world:
		_lay_world(plan)
	quit()


## The water running off the maps drawn on in the dark gaps (data/world.json `waters`, WorldPlan):
## a stream going up or down carried on to the picture's edge, two that meet carried to their
## meeting, the one that meets carried on past it. Only on cells no map covers.
func _draw_off_plan(world: Image, plan: Dictionary, lo: Vector2i) -> void:
	var cfg: Dictionary = WorldPlan.config()
	var places: Dictionary = WorldPlan.places(cfg)
	var runs: Array[Dictionary] = WorldPlan.off_plan_runs(places)
	var waters: Dictionary = cfg.get("waters", {})
	var far := maxi(world.get_width(), world.get_height()) / T
	var cells: Array[Vector2i] = []
	for r in runs:
		var w: Dictionary = waters.get(r.key, {})
		if w.has("meets"):
			var b := WorldPlan.run_of(runs, str(w.meets))
			var m := WorldPlan.meeting(r, b)
			if m.has_area():
				cells.append_array(WorldPlan.carried(r, m))
				for y in range(m.position.y, m.end.y):
					for x in range(m.position.x, m.end.x):
						cells.append(Vector2i(x, y))
				continue
		cells.append_array(WorldPlan.carried(r, Rect2i(), far))
	var water := Color("3d6680")
	for c in cells:
		var px := c * T - lo
		if WorldPlan.owner(c, places) == "" and Rect2i(Vector2i.ZERO, world.get_size()).encloses(Rect2i(px, Vector2i(T, T))):
			world.fill_rect(Rect2i(px, Vector2i(T, T)), water)


## The pictures laid at their places on the plan (data/world.json), the gaps between them dark.
func _lay_world(plan: Dictionary) -> void:
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-(1 << 20), -(1 << 20))
	for id in _shots:
		var at := Vector2i(int(plan[id][0]), int(plan[id][1])) * T
		lo = Vector2i(mini(lo.x, at.x), mini(lo.y, at.y))
		hi = Vector2i(maxi(hi.x, at.x + _shots[id].get_width()), maxi(hi.y, at.y + _shots[id].get_height()))
	var world := Image.create(hi.x - lo.x, hi.y - lo.y, false, Image.FORMAT_RGBA8)
	world.fill(Color("1c1a18"))
	for id in _shots:
		var img: Image = _shots[id]
		img.convert(Image.FORMAT_RGBA8)
		var at := Vector2i(int(plan[id][0]), int(plan[id][1])) * T - lo
		world.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
	_draw_off_plan(world, plan, lo)
	world.save_png(_out + "/_world.png")
	var half := world.duplicate()
	half.resize(world.get_width() / 2, world.get_height() / 2, Image.INTERPOLATE_NEAREST)
	half.save_png(_out + "/_world_half.png")
	print("map_overview: the world ", world.get_size())
