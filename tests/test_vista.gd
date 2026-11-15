extends SceneTree
## Headless checks for the view of the mountains (VistaRules, VistaMountain, data/vista.json):
## the mountain never rises on a map anyone walks, it rises past them where the plan leaves room
## (south-west across the river from the long bridge), its mesh in each map's own cells, the
## viewpoints on open cells, the camera blend from the play lens to the view and back, the ease,
## and the 3D worlds that build it. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_vista.gd

var failures := 0
var g: Node
var VM: GDScript   # VistaMountain, loaded at run time (it reads the Game autoload)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	g = root.get_node("Game")
	VM = load("res://scripts/world3d/vista_mountain.gd")
	g.new_game()
	g.clock_running = false
	_data()
	_heights()
	_mesh()
	_views()
	_blend()
	await _worlds()
	print("test_vista: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _data() -> void:
	var cfg := VistaRules.config()
	check(cfg.mountains.size() >= 1 and cfg.views.size() >= 1, "a mountain and a viewpoint")
	for id in cfg.maps:
		check(MapManager.data(id) != null and not MapManager.data(id).indoor, "%s: an outdoor map" % id)
		check(WorldPlan.places().has(id), "%s: on the plan" % id)
	for s in ["spring", "summer", "fall", "winter"]:
		var c: Dictionary = cfg.colors.get(s, {})
		check(c.has("dark") and c.has("light") and c.has("accent") and float(c.accent_share) >= 0.0 and float(c.accent_share) <= 1.0, "%s: the colours" % s)
	check(float(cfg.colors.winter.snow_line) < 1.0 and float(cfg.colors.summer.snow_line) >= 1.0, "snow on it in winter only")
	check(VistaRules.on_map("town") and not VistaRules.on_map("house") and not VistaRules.on_map("mine_floor"), "on the village, not in rooms or the mine")


## Nothing rises on a map; it rises in the plan's empty land, highest along the ridge.
func _heights() -> void:
	for m: Dictionary in VistaRules.config().mountains:
		_heights_of(m)
	# The real map: Arashiyama across the river south-west of the long bridge, Ogura north-west of
	# the village (where the play camera looks), none north-east of the bridge.
	var rects := VistaRules.map_rects()
	var ms: Array = VistaRules.config().mountains
	var arashi: Dictionary = ms.filter(func(x): return x.id == "arashiyama")[0]
	var ogura: Dictionary = ms.filter(func(x): return x.id == "ogura")[0]
	var bridge := Vector2(41, 40)
	check(VistaRules.height(arashi, bridge + Vector2(-33, 36), rects) > 8.0, "Arashiyama south-west of the bridge")
	check(VistaRules.height(ogura, Vector2(-30, -45), rects) > 12.0, "Ogura north-west of the village")
	var ne := 0.0
	for m in ms:
		ne = maxf(ne, VistaRules.height(m, bridge + Vector2(30, -50), rects))
	check(ne == 0.0, "none north-east of the bridge (%.1f)" % ne)


func _heights_of(m: Dictionary) -> void:
	var rects := VistaRules.map_rects()
	var on_map := 0.0
	var any := 0.0
	var area: Array = m.area
	for z in range(int(area[1]), int(area[3]), 2):
		for x in range(int(area[0]), int(area[2]), 2):
			var p := Vector2(x + 0.5, z + 0.5)
			var h := VistaRules.height(m, p, rects)
			check(h >= 0.0, "never below the land (%s)" % p)
			if VistaRules.map_distance(p, rects) <= float(m.foot[0]):
				on_map = maxf(on_map, h)
			any = maxf(any, h)
	check(on_map == 0.0, "%s: nothing rises on or by a map (%.2f)" % [m.id, on_map])
	check(any > 8.0 and any <= VistaRules.peak(m), "%s: it rises past the maps (%.1f, at most the peak %.1f)" % [m.id, any, VistaRules.peak(m)])
	var mid: Array = m.ridge[3]
	check(VistaRules.height(m, Vector2(float(mid[0]), float(mid[1])), rects) > float(mid[2]) - float(m.lumps), "%s: the ridge stands near its height" % m.id)
	check(VistaRules.noise(Vector2(3.3, 7.1)) >= 0.0 and VistaRules.noise(Vector2(3.3, 7.1)) <= 1.0 and VistaRules.noise(Vector2(3.3, 7.1)) == VistaRules.noise(Vector2(3.3, 7.1)), "the lumps' noise: 0..1, the same each time")
	# No cliff where the mesh stops: its outer ring lies flat under the land.
	var edge := 0.0
	for x in range(int(area[0]), int(area[2]) + 1, 2):
		edge = maxf(edge, maxf(VistaRules.height(m, Vector2(x, float(area[1])), rects), VistaRules.height(m, Vector2(x, float(area[3])), rects)))
	for z in range(int(area[1]), int(area[3]) + 1, 2):
		edge = maxf(edge, maxf(VistaRules.height(m, Vector2(float(area[0]), z), rects), VistaRules.height(m, Vector2(float(area[2]), z), rects)))
	check(edge < 1.0, "%s: down to the land at its area's edge, no cliff (%.1f)" % [m.id, edge])


## The mesh lies in the map's own cells: under the land on the map, up past it.
func _mesh() -> void:
	var rects := VistaRules.map_rects()
	var m: Dictionary = VistaRules.config().mountains[0]
	var at: Vector2i = WorldPlan.places().minamino
	var mesh: ArrayMesh = VM.mesh_of(m, Vector2(at), rects)
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var mm := MapManager.data("minamino")
	var top := -INF
	var over := 0
	for v in verts:
		top = maxf(top, v.y)
		if v.x >= 0.0 and v.z >= 0.0 and v.x <= mm.w and v.z <= mm.h and v.y > 0.0:
			over += 1
	check(verts.size() > 0 and verts.size() % 3 == 0, "a mesh of triangles (%d points)" % verts.size())
	check(over == 0, "none of it over Minamino's cells (%d)" % over)
	check(top > 8.0, "it rises (%.1f)" % top)
	var town: ArrayMesh = VM.mesh_of(m, Vector2.ZERO, rects)
	var tv: PackedVector3Array = town.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var aabb := town.get_aabb()
	check(tv.size() == verts.size() and is_equal_approx(aabb.position.x, mesh.get_aabb().position.x + float(at.x)) and is_equal_approx(aabb.position.z, mesh.get_aabb().position.z + float(at.y)), "the same mountain moved by the map's place")


## The viewpoints: on their map, on open cells the farmer can stand on.
func _views() -> void:
	for v: Dictionary in VistaRules.config().views:
		var m := MapManager.data(str(v.map))
		check(m != null and VistaRules.on_map(str(v.map)), "%s: on a map with the mountains" % v.id)
		var r: Array = v.rect
		var open := 0
		for y in range(int(r[1]), int(r[1]) + int(r[3])):
			for x in range(int(r[0]), int(r[0]) + int(r[2])):
				check(m.in_bounds(Vector2i(x, y)), "%s: %d,%d on the map" % [v.id, x, y])
				if not m.is_solid(Vector2i(x, y)):
					open += 1
		check(open > 0, "%s: cells to stand on (%d)" % [v.id, open])
		check(float(v.yaw) == CameraLens.YAW, "%s: the play camera's yaw, so the keys still match the screen" % v.id)
		check(float(v.pitch) < 30.0 - 10.0 and float(v.fov) - float(v.pitch) * 2.0 > 0.0, "%s: tilted up enough to see over the horizon" % v.id)
		check(VistaRules.view_at(str(v.map), Vector2i(int(r[0]), int(r[1]))) == v, "%s: view_at finds it" % v.id)
		check(VistaRules.view_at(str(v.map), Vector2i(int(r[0]) - 1, int(r[1]))).is_empty(), "%s: not beside it" % v.id)
	var tg := VistaRules.view_at("town", Vector2i(41, 40))
	check(tg.get("id", "") == "togetsu", "the middle of the long bridge is a viewpoint")
	var town := MapManager.data("town")
	var south: Dictionary = town.doors.filter(func(d): return d.to == "minamino")[0]
	var last: Vector2i = (south.cells[0] as Vector2i) + Vector2i.UP   # the path's last cell before the way to Minamino
	check(VistaRules.view_at("town", last) == tg and VistaRules.view_at("town", Vector2i(41, 44)) == tg, "the view runs on down the path south of the bridge to the edge (%s)" % last)
	check(VistaRules.view_at("town", Vector2i(41, 35)).is_empty(), "not on the street north of the bridge")
	var sp: Array = MapManager.data("town").spawns.get("togetsu", [])
	check(not sp.is_empty() and VistaRules.view_at("town", Vector2i(sp[0])) == tg, "the togetsu spawn stands in it")
	check(VistaRules.view_at("kaminoda", Vector2i(19, 9)).get("id", "") == "kaminoda", "Kaminoda's lane by the well is a viewpoint")


## The camera between the play lens and the view.
func _blend() -> void:
	var lens := CameraLens.pick(JSON.parse_string(FileAccess.get_file_as_string("res://data/camera.json")))
	var v := VistaRules.view_at("town", Vector2i(41, 40))
	var b0 := VistaRules.blend(lens, v, 0.0)
	check((b0.back as Vector3).is_equal_approx(lens.back) and b0.dist == lens.dist and b0.fov == lens.fov and b0.lift == 0.0, "weight 0: the play camera")
	check(VistaRules.blend(lens, {}, 1.0).back == lens.back, "no view: the play camera")
	var b1 := VistaRules.blend(lens, v, 1.0)
	var yaw := rad_to_deg(atan2((b1.back as Vector3).x, (b1.back as Vector3).z))
	check(absf(wrapf(yaw - float(v.yaw), -180.0, 180.0)) < 0.01, "weight 1: the view's yaw (%.1f)" % yaw)
	check(absf(rad_to_deg(asin((b1.back as Vector3).y)) - float(v.pitch)) < 0.01 and is_equal_approx(b1.fov, float(v.fov)) and is_equal_approx(b1.dist, float(v.dist)), "weight 1: its pitch, lens and distance")
	check(is_equal_approx((b1.back as Vector3).length(), 1.0) and is_equal_approx((VistaRules.blend(lens, v, 0.5).back as Vector3).length(), 1.0), "the way back to the eye stays a unit")
	var half := VistaRules.blend(lens, v, 0.5)
	var hy := rad_to_deg(atan2((half.back as Vector3).x, (half.back as Vector3).z))
	var hp := rad_to_deg(asin((half.back as Vector3).y))
	check(absf(hy - CameraLens.YAW) < 0.01 and hp < lens.pitch and hp > float(v.pitch), "half way: the same yaw, the pitch between (%.1f, %.1f)" % [hy, hp])
	var turned := VistaRules.blend(lens, {"yaw": 160.0, "pitch": 8.0, "fov": 42.0, "dist": 10.0}, 0.5)
	var ty := rad_to_deg(atan2((turned.back as Vector3).x, (turned.back as Vector3).z))
	check(ty > CameraLens.YAW and ty < 160.0, "a view of another yaw: turning the short way round (%.1f)" % ty)
	# The ease: in over `ease` seconds standing in it, out as long after.
	var w := 0.0
	var e := float(v.ease)
	for i in 10:
		w = VistaRules.step(w, true, e / 10.0, e)
	check(is_equal_approx(w, 1.0), "eased in over its seconds")
	w = VistaRules.step(w, false, e / 2.0, e)
	check(is_equal_approx(w, 0.5), "half way back")
	w = VistaRules.step(w, false, e, e)
	check(w == 0.0 and VistaRules.step(1.0, true, 1.0, e) == 1.0, "never past 0 or 1")


## The 3D worlds: the village builds the mountain, a room and the mine do not.
func _worlds() -> void:
	var MapWorldS: GDScript = load("res://scripts/world3d/map_world.gd")
	for id in ["town", "house", "mine_floor"]:
		var w3: Node3D = MapWorldS.new()
		root.add_child(w3)
		for step in w3.build_steps(MapManager.data(id)):
			step.call()
		var has := w3.get_children().any(func(n): return n.get_script() == VM)
		check(has == (id == "town"), "%s: %s" % [id, "builds the mountain" if id == "town" else "none"])
		if has:
			var vm: Node3D = w3.vista
			check(vm.get_child_count() == VistaRules.config().mountains.size() and vm.mat != null, "one mesh a mountain, its material")
			vm.tone("winter", Color.WHITE, Vector3.UP)
			check(float(vm.mat.get_shader_parameter("snow_line")) < 1000.0, "winter: a snow line")
			vm.tone("summer", Color.WHITE, Vector3.UP)
			check(float(vm.mat.get_shader_parameter("snow_line")) >= 1000.0, "summer: none")
		w3.free()
	await process_frame
