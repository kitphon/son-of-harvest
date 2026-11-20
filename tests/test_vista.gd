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
	_floor()
	_far_water()
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
	var kita: Dictionary = ms.filter(func(x): return x.id == "kitayama")[0]
	check(VistaRules.height(kita, Vector2(52, -122), rects) > 8.0, "Kitayama north beyond the bamboo hill")
	var ne := 0.0
	for m in ms:
		ne = maxf(ne, VistaRules.height(m, bridge + Vector2(30, -50), rects))
	check(ne == 0.0, "none north-east of the bridge (%.1f)" % ne)
	# Clear of the water running off the maps (the user saw a mountainside rise over the river's
	# west end): the river out of the gorge runs on in a valley.
	var clear := VistaRules.clear_rects()
	check(clear.size() > rects.size(), "the water running off the maps kept clear too (%d)" % (clear.size() - rects.size()))
	var on_water := 0.0
	for x in range(-100, -21, 4):
		for m in ms:
			on_water = maxf(on_water, VistaRules.height(m, Vector2(x, 27.5), clear))
	check(on_water == 0.0, "no mountain over the river carried west from the gorge (%.1f)" % on_water)
	# No slope close by from the play camera: nothing rises within the land past any map's edges.
	var margin := int(load("res://scripts/world3d/surroundings.gd").MARGIN)
	var close := 0.0
	for m in ms:
		var area: Array = m.area
		for z in range(int(area[1]), int(area[3]), 3):
			for x in range(int(area[0]), int(area[2]), 3):
				var p := Vector2(x, z)
				if VistaRules.map_distance(p, rects) <= margin:
					close = maxf(close, VistaRules.height(m, p, clear))
	check(close == 0.0, "no slope within %d cells of any map (%.2f)" % [margin, close])


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
	var mid: Array = m.ridge[0]   # the ridge's point farthest from every map: its full height there
	for r in m.ridge:
		if VistaRules.map_distance(Vector2(float(r[0]), float(r[1])), rects) > VistaRules.map_distance(Vector2(float(mid[0]), float(mid[1])), rects):
			mid = r
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


## The forest floor past the land round a map (VistaMountain.floor_at): from a cell short of where
## the land stops (Backdrop's rim on the back sides, Surroundings' apron on the others), so the
## tilted view never looks into a gap there (the user saw white sky past the bamboo hill's west
## edge); never over water running on off an edge.
func _floor() -> void:
	var hill := MapManager.data("hill")
	var rim := int(load("res://scripts/world3d/backdrop.gd").rim())
	var margin := int(load("res://scripts/world3d/surroundings.gd").MARGIN)
	# On a map with the mountains the land runs its whole apron on every side (no rim: the paths
	# and the river run on as far west and north as south and east; the user saw them cut short).
	check(not VM.floor_at(hill, Vector2(-rim - 1, 10)) and not VM.floor_at(hill, Vector2(-margin + 2, 10)) and VM.floor_at(hill, Vector2(-margin, 10)) and VM.floor_at(hill, Vector2(20, -margin - 1)), "the hill: open land only past its whole apron, west and north too")
	check(not VM.floor_at(hill, Vector2(20, hill.h + 5)) and VM.floor_at(hill, Vector2(20, hill.h + margin)), "past its south edge only where the land past it stops")
	var town := MapManager.data("town")
	check(not VM.floor_at(town, Vector2(town.w + margin + 2, 40)) and VM.floor_at(town, Vector2(town.w + margin + 2, 20)), "not over the river running on east, beside it yes")
	var ogura: Dictionary = VistaRules.config().mountains.filter(func(x): return x.id == "ogura")[0]
	var at: Vector2i = WorldPlan.places().hill
	var om: ArrayMesh = VM.mesh_of(ogura, Vector2(at), VistaRules.map_rects(), hill)
	var verts := PackedVector3Array()
	var floor_surface := -1
	for i in om.get_surface_count():
		verts.append_array(om.surface_get_arrays(i)[Mesh.ARRAY_VERTEX])
		if om.surface_get_name(i) == "floor":
			floor_surface = i
	check(floor_surface >= 0 and (om.surface_get_arrays(floor_surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() > 0, "the open land a surface of its own")
	# Its grass darkens toward the mountains' feet (the user's ask): the tint's weight 1 at a foot,
	# 0 far off, and more where nearer.
	var tint := -1
	for i in om.get_surface_count():
		if om.surface_get_name(i) == "tint":
			tint = i
	check(tint >= 0, "a darkening over the open land")
	if tint >= 0:
		var tv: PackedVector3Array = om.surface_get_arrays(tint)[Mesh.ARRAY_VERTEX]
		var tc: PackedColorArray = om.surface_get_arrays(tint)[Mesh.ARRAY_COLOR]
		var lo := 1.0
		var hi := 0.0
		for c in tc:
			lo = minf(lo, c.r)
			hi = maxf(hi, c.r)
		check(tv.size() == tc.size() and lo < 0.05 and hi > 0.6, "light far from the mountains, dark at their feet (%.2f .. %.2f)" % [lo, hi])
	var floor_pts := 0
	var gap := 0
	for v in verts:
		if is_equal_approx(v.y, VM.FLOOR):
			floor_pts += 1
		if v.x < -margin - 1.0 and v.x > -30.0 and v.z > 0.0 and v.z < hill.h and v.y < VM.FLOOR - 0.01:
			gap += 1
	check(floor_pts > 0 and gap == 0, "the hill's west: floor out to the mountain, nothing sunk past the rim (%d floor points, %d sunk)" % [floor_pts, gap])


## The water running off a mountain map carried on past its apron (data/vista.json `far_water`,
## VistaRules.far_river): laid cell by cell as the apron lays the map's own (its bed, stone walls,
## grass banks at the land's height either side, Surroundings' skin over it), so no hole opens over
## the river like a chasm and its banks run on level (the user saw both past the river map's west
## edge, 2026-11-20); only down the plan's corridors; the open land runs on past its far end.
func _far_water() -> void:
	var river := MapManager.data("river")
	var margin := int(load("res://scripts/world3d/surroundings.gd").MARGIN)
	var far := VistaRules.far_water()
	check(far > margin * 3, "the river runs on well past the apron (%d cells)" % far)
	var cells := VistaRules.far_river(river, margin)
	var west := cells.filter(func(c: Vector2i) -> bool: return c.x < 0)
	var rows := {}
	for c: Vector2i in west:
		rows[c.y] = true
	check(west.size() == 4 * (far - margin) and rows.keys().size() == 4 and Vector2i(-margin - 1, 6) in west and Vector2i(-far, 9) in west, "west: the river's four rows from the apron's end out to far_water (%d cells)" % west.size())
	check(not cells.any(func(c: Vector2i) -> bool: return c.x < 0 and (c.y < 6 or c.y > 9)), "none over the banks")
	var east := cells.filter(func(c: Vector2i) -> bool: return c.x >= river.w)
	check(east.size() > 0 and east.all(func(c: Vector2i) -> bool: return c.x < 20 + 56), "east: into the village's river, not past the village (%d cells)" % east.size())
	var saku := MapManager.data("sakurazaka")
	var down := VistaRules.far_river(saku, margin).filter(func(c: Vector2i) -> bool: return c.y >= saku.h)
	check(down.all(func(c: Vector2i) -> bool: return c.y + 6 < 43), "Sakurazaka's creek south: only to where it meets the river")
	# The open land: none at a corner of that river, grass beside it.
	check(not VM.floor_at(river, Vector2(-30, 7)) and not VM.floor_at(river, Vector2(-30, 10)) and not VM.floor_at(river, Vector2(-30, 6)), "no open land at the river's corners past the apron")
	check(VM.floor_at(river, Vector2(-30, 2)) and VM.floor_at(river, Vector2(-30, 12)), "beside it: the open land")
	check(VM.floor_at(river, Vector2(-far - 6, 7)), "past its far end the open land runs on over its line")
	var ogura: Dictionary = VistaRules.config().mountains.filter(func(x): return x.id == "ogura")[0]
	var first: Dictionary = VistaRules.config().mountains[0]
	var rm: ArrayMesh = VM.mesh_of(first, Vector2(WorldPlan.places().river), VistaRules.map_rects(), river)
	var parts := {}
	for i in rm.get_surface_count():
		parts[rm.surface_get_name(i)] = rm.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]
	var bed: PackedVector3Array = parts.get("bed", PackedVector3Array())
	var banks: PackedVector3Array = parts.get("banks", PackedVector3Array())
	var walls: PackedVector3Array = parts.get("walls", PackedVector3Array())
	var bed_y: float = VM.LAND_Y - float(load("res://scripts/world3d/sunken_ground.gd").DROP)
	check(bed.size() == cells.size() * 6 and Array(bed).all(func(v: Vector3) -> bool: return is_equal_approx(v.y, bed_y)), "a bed quad a river cell at the water's depth (%d)" % bed.size())
	check(banks.size() > 0 and Array(banks).all(func(v: Vector3) -> bool: return is_equal_approx(v.y, VM.LAND_Y)), "its banks at the land's height, level with the apron's")
	var on_rows := Array(banks).filter(func(v: Vector3) -> bool: return v.x < -margin - 1 and v.x > -far)
	check(on_rows.all(func(v: Vector3) -> bool: return (v.z >= 4.0 and v.z <= 6.0) or (v.z >= 10.0 and v.z <= 12.0)), "two cells of grass either side of the river's rows")
	check(walls.size() > 0 and Array(walls).all(func(v: Vector3) -> bool: return is_equal_approx(v.y, VM.LAND_Y) or is_equal_approx(v.y, bed_y)), "stone walls from the land down to the bed")
	var other: ArrayMesh = VM.mesh_of(ogura, Vector2(WorldPlan.places().river), VistaRules.map_rects(), river)
	var twice := false
	for i in other.get_surface_count():
		twice = twice or other.surface_get_name(i) in ["bed", "banks", "walls"]
	check(ogura == first or not twice, "laid once a map, with the first mountain only")
	# The open land runs west past the river's far end, so no sky shows under the far hills.
	var west_land := INF
	for m: Dictionary in VistaRules.config().mountains:
		west_land = minf(west_land, float(m.area[0]))
	check(west_land <= float(WorldPlan.places().river.x) - far - 60.0, "the open land reaches %.0f, well west of the river's far end" % west_land)


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
	check(VistaRules.view_at("kaminoda", Vector2i(19, 9)).is_empty(), "Kaminoda's lane by the well is not a viewpoint (the user's word)")
	var hill := MapManager.data("hill")
	var whole := true
	for y in hill.h:
		for x in hill.w:
			whole = whole and VistaRules.view_at("hill", Vector2i(x, y)).get("id", "") == "hill"
	check(whole, "the whole bamboo hill is a viewpoint")
	check(VistaRules.view_at("hill", Vector2i(sp_cell(hill, "start"))).get("id", "") == "hill" and VistaRules.view_at("hill", Vector2i(sp_cell(hill, "top"))).get("id", "") == "hill", "from its foot to its top")
	_more_views()


## The viewpoints added 2026-11-19: the gorge, the farm pond, Minamino's riverside.
func _more_views() -> void:
	var river := MapManager.data("river")
	var whole := true
	for y in river.h:
		for x in river.w:
			whole = whole and VistaRules.view_at("river", Vector2i(x, y)).get("id", "") == "gorge"
	check(whole, "the whole river gorge is a viewpoint")
	check(VistaRules.view_at("river", sp_cell(river, "shore")).get("id", "") == "gorge", "the shore spawn stands in it")
	# The farm pond: its banks and the fishing spot, never the farm's daily ways.
	check(VistaRules.view_at("farm", Vector2i(24, 3)).get("id", "") == "farm_pond", "the pond's fishing spot is a viewpoint")
	check(VistaRules.view_at("farm", Vector2i(25, 4)).get("id", "") == "farm_pond", "the pond's south-west bank is one")
	var busy := [Vector2i(31, 5), Vector2i(31, 6), Vector2i(29, 6), Vector2i(21, 5), Vector2i(23, 6), Vector2i(29, 3), Vector2i(30, 4), Vector2i(21, 4)]
	for c in FarmGrid.SILO.size.x * FarmGrid.SILO.size.y:
		busy.append(FarmGrid.SILO.position + Vector2i(c % FarmGrid.SILO.size.x, c / FarmGrid.SILO.size.x))
	var farm := MapManager.data("farm")
	for id in farm.spawns:
		if id != "silo":
			busy.append(sp_cell(farm, id))
	var clear := true
	for c: Vector2i in busy:
		if not VistaRules.view_at("farm", c).is_empty():
			clear = false
			print("  on a viewpoint: farm %s" % c)
	check(clear, "the gate road, the barn's yard and door, the silo and its front, the spawns: no viewpoint")
	var pond_cells := 0
	for c in FarmGrid.POND:
		if VistaRules.view_at("farm", c).get("id", "") == "farm_pond":
			pond_cells += 1
	check(pond_cells == FarmGrid.POND.size(), "the pond lies inside its viewpoint (%d of %d)" % [pond_cells, FarmGrid.POND.size()])
	# Minamino's riverside: the lane's end, not the way round Kiku's front to her door.
	var mina := MapManager.data("minamino")
	check(VistaRules.view_at("minamino", sp_cell(mina, "river")).get("id", "") == "minamino_bank", "Minamino's riverside spawn stands in it")
	var kiku: Dictionary = mina.doors.filter(func(d): return d.to == "kiku_house")[0]
	var ok := true
	for x in range(18, 24):
		ok = ok and VistaRules.view_at("minamino", Vector2i(x, 15)).is_empty()
	check(ok and VistaRules.view_at("minamino", kiku.cells[0] as Vector2i).is_empty(), "the path round Kiku's front and her door are no viewpoint")
	for id in ["start", "shige", "kaede", "kiku", "shino", "shrine", "barn"]:
		check(VistaRules.view_at("minamino", sp_cell(mina, id)).is_empty(), "Minamino's %s spawn is no viewpoint" % id)
	check(VistaRules.view_at("sakurazaka", Vector2i(15, 10)).is_empty(), "Sakurazaka's roofed bridge is no viewpoint")


func sp_cell(m: MapData, id: String) -> Vector2i:
	return Vector2i(m.spawns[id][0])


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
	# A step each (a new map's mountains once stalled the game 2.4 s in one frame): the node and its
	# materials with the land past the edges, then one mountain a step, its shape worked out once.
	var probe: Node3D = MapWorldS.new()
	root.add_child(probe)
	var steps: Array = probe.build_steps(MapManager.data("minamino"))
	check(steps.size() >= VM.count() + 2, "the mountains a build step each (%d steps)" % steps.size())
	VM.warm()
	check(VM._grids.size() == VistaRules.config().mountains.size(), "every mountain's own shape worked out once (%d)" % VM._grids.size())
	var parts_before := -1
	for st in steps:
		st.call()
		if probe.vista != null and parts_before < 0:
			parts_before = probe.vista.get_child_count()
	check(parts_before == 0 and probe.vista.get_child_count() == VM.count(), "begun empty, a mountain added a step (%d, then %d)" % [parts_before, probe.vista.get_child_count()])
	probe.free()
	# Past a cliff the land runs on as grass with its trees, not as bare stone
	# (data/vista.json apron_runs_as; the user saw an empty stone yard there).
	check(VistaRules.apron_kind("rock_wall") == "grass" and VistaRules.apron_kind("scree") == "grass" and VistaRules.apron_kind("path") == "path", "a cliff or scree at the edge runs on as grass, a path as a path")
	var hw: Node3D = MapWorldS.new()
	root.add_child(hw)
	for st in hw.build_steps(MapManager.data("hill")):
		st.call()
	var north := 0   # (a headless MultiMesh keeps no transforms: ask where the pines stand)
	var hill_map := MapManager.data("hill")
	var soft := func(c: Vector2i) -> String: return VistaRules.apron_kind(hill_map.tile(c))
	for shape: Array in hw.surroundings._pine_spots(hill_map.w, hill_map.h, soft):
		for xf: Transform3D in shape:
			if xf.origin.z < -2.0:
				north += 1
	check(north > 0, "trees past the hill's north edge (%d spots; on Nishiki Hill broadleaf, Surroundings.broadleaf)" % north)
	hw.free()
	# The farm lays them a step each too (its own step list: a slip there left the farm unbuilt).
	var M3: GDScript = load("res://scripts/main_3d.gd")
	var made: Array = M3.new_world(MapManager.data("farm"))
	for st in made[1]:
		st.call()
	check(made[0].vista != null and made[0].vista.get_child_count() == VM.count(), "the farm builds its mountains, a step each")
	made[0].free()
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
			# The open land at the mountains' feet: the ground's own grass, lit, wetted and snowed on as the land past the edges.
			var SL: GDScript = load("res://scripts/world3d/snow_layer.gd")
			var uses := false
			for mi in vm.get_children():
				for i in (mi.mesh as ArrayMesh).get_surface_count():
					if (mi.mesh as ArrayMesh).surface_get_name(i) == "floor":
						uses = uses or mi.get_surface_override_material(i) == vm.floor_mat
			check(SL.is_ground(vm.floor_mat) and uses, "the open land wears the ground's grass material")
			w3.set_snow(0.6)
			check(is_equal_approx(float(vm.floor_mat.get_shader_parameter("cover")), 0.6) and is_equal_approx(float(vm.tint_mat.get_shader_parameter("cover")), 0.6), "and takes the world's snow cover, its darkening too")
			check(w3.surroundings.share == VistaRules.apron_pines() and VistaRules.apron_pines() < int(load("res://scripts/world3d/surroundings.gd").TREE_SHARE), "a thinner wood past the edges (%d in a hundred)" % w3.surroundings.share)
			vm.tone("spring", Color.WHITE, Vector3.UP)
			var fc: Color = vm.mat.get_shader_parameter("foot_color")
			check(fc.g > fc.r and fc.g > fc.b and float(vm.mat.get_shader_parameter("foot_blend")) > 0.0, "the slopes' feet take the darkened grass's colour (%s)" % fc)
			vm.tone("fall", Color.WHITE, Vector3.UP)
			check(Color(vm.tint_mat.get_shader_parameter("tint")).is_equal_approx(Color(str(VistaRules.config().colors.fall.foot))), "the darkening by the season")
		w3.free()
	await process_frame
