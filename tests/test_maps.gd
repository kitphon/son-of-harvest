extends SceneTree
## Headless checks for maps (data/maps, MapData, MapManager, Game map rules). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_maps.gd

var failures := 0


func _init() -> void:
	_map_files()
	_map_rules()
	_clinic()
	_lenses()


## Camera lenses (data/camera.json): ps1 is the measured camera, every lens frames the feet alike.
func _lenses() -> void:
	var cam_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/camera.json"))
	var ps1 := CameraLens.pick(cam_data, "ps1")
	check(absf(ps1.dist - 10087.0 / 400.0) < 0.05, "ps1 lens: the eye 25.2 cells away (%.2f)" % ps1.dist)
	check(ps1.back.distance_to(Vector3(0.634, 0.448, 0.634)) < 0.005, "ps1 lens: yaw 45, pitch 26.6")
	for lid in cam_data.lenses:
		var l := CameraLens.pick(cam_data, lid)
		check(is_equal_approx(l.dist * tan(deg_to_rad(l.fov) / 2.0), float(cam_data.half_height)), "lens %s frames the feet alike" % lid)
	check(CameraLens.pick(cam_data).id == cam_data.use, "no --lens: the lens camera.json uses")


var _frame := 0
var _since_door := -1.0          # seconds since the door (the fade runs on real time)
var _scene: Node
var _entered: Array = []
var _farm_world_ok := false


func _process(delta: float) -> bool:
	_frame += 1
	if _since_door >= 0.0:
		_since_door += delta
	if _frame == 1:
		_homes_3d()
		_minka()
		_shrine()
		_farm_props()
		_room_walls()
		_room_props()
		_trees()
		_grass()
		_game_maps()
		_bed_and_doors()
		_clinic_doors()
		_story_props()
		_map_snow()
		_edges_and_fades()
		_start_view()
	elif _frame == 3:
		var g: Node = root.get_node("Game")
		g.use_door(MapManager.data("farm").doors[0])
		check(_scene.fade.busy() and g.paused(), "a door starts the fade and holds the farmer")
		_since_door = 0.0
	elif _since_door > 1.0 or _frame > 2000:
		_check_view()
		print("test_maps: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


## The real 3D view: through the farm house door, the fade runs, the house is built.
func _start_view() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	# The farm's morning events would take the farmer over on entry; this test is about doors.
	g.events_seen = {"first_morning": true, "rainy_day": true}
	g.map_entered.connect(func(id): _entered.append(id))
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)
	check(_entered == ["farm"], "the view says the farmer entered the farm %s" % [_entered])
	_farm_world_ok = _scene.world.surroundings != null and _scene.world.occluders.count() == 4
	check(_scene.world.windows.size() == 4, "the farmhouse lights three windows and its door (%d)" % _scene.world.windows.size())
	var lights := _scene.find_children("*", "Control", true, false).filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("night_lights.gd"))
	check(lights.size() == 1, "the 3D view draws the lit windows")


func _check_view() -> void:
	var g: Node = root.get_node("Game")
	check(not _scene.fade.busy() and not g.paused(), "the fade ended and let go of the pause")
	check(_entered == ["farm", "house"], "map_entered after the fade %s" % [_entered])
	check(_scene.world.get_script().resource_path.ends_with("map_world.gd") and _scene.world.map.id == "house", "the view rebuilt as the house")
	check(_farm_world_ok, "the farm has land past its fence and its house, stand, coop and barn can fade")
	check(_scene.player.position == g.maps.pos and _scene.player.facing == Vector2i.UP, "the farmer stands at the house spawn")
	var events: Array = _scene.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("event_player.gd"))
	check(events.size() == 1 and events[0].map_id == "house" and events[0].table.map_id == "house",
		"the event triggers follow the map")
	_scene.free()
	check(not g.paused(), "leaving the view keeps no pause")
	g.new_game()


## Every file parses; doors lead to real maps, onto free cells; every way in has a way back.
func _map_files() -> void:
	var ids := MapManager.ids()
	for want in ["farm", "house", "town"]:
		check(want in ids, "map %s has a file" % want)
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var farm := FarmGrid.new(crops)
	farm.generate(RandomNumberGenerator.new())
	for id in ids:
		var r := MapManager.load_map(id)
		check(r[0] == "", "map %s loads (%s)" % [id, r[0]])
		if r[0] != "":
			continue
		var m: MapData = r[1]
		var solid := func(c: Vector2i) -> bool: return farm.is_solid(c) if m.farm else m.is_solid(c)
		for key in m.spawns:
			check(not solid.call(m.spawns[key][0]), "%s spawn %s is free" % [id, key])
		for door in m.doors:
			for c in door.cells:
				check(solid.call(c), "%s door %s is a solid cell (walked into, not over)" % [id, c])
			if door.to == "":
				continue
			var to := MapManager.data(door.to)
			check(to != null, "%s door leads to a known map (%s)" % [id, door.to])
			if to == null:
				continue
			var spawn: Vector2i = door.spawn
			check(to.in_bounds(spawn) and to.door_at(spawn).is_empty(), "%s -> %s spawn on the map, not on a door" % [id, door.to])
			if not to.farm:
				check(not to.is_solid(spawn), "%s -> %s spawn is free" % [id, door.to])
			var back := false
			for d in to.doors:
				back = back or d.to == id
			check(back, "%s -> %s has a way back" % [id, door.to])
	var fm := MapManager.data("farm")
	check(fm.farm and fm.w == FarmGrid.W and fm.h == FarmGrid.H, "farm map is the FarmGrid's size")
	check(farm.fixed_at(fm.doors[0].cells[0]) == "door", "the farm's house door is FarmGrid's door cell")
	for c in fm.gate_cells():
		check(farm.fixed_at(c) == "fence", "the gate %s is a fence cell left open" % c)
	check(MapManager.data("house").indoor and not MapManager.data("town").indoor and not fm.indoor, "only the house is indoors")
	check(MapManager.data("house").spawns.has("home"), "the house has a home spawn")
	# Broken data is refused.
	for bad in [null, {}, {"id": "x", "size": [2, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["ab"], "spawns": {"start": [[0, 0], "up"]}},
			{"id": "x", "size": [1, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["a"], "spawns": {}},
			{"id": "x", "size": [1, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["a"], "spawns": {"start": [[0, 0], "up"]},
				"doors": [{"cells": [[0, 1]], "to": "farm"}]},
			{"id": "x", "size": [1, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["a"], "spawns": {"start": [[0, 0], "up"]},
				"props": [{"kind": "pine", "cell": [1, 0]}]}]:
		check(MapData.parse(bad)[0] != "", "refused broken map %s" % str(bad).left(60))


## Cells, props and doors on the house and the village.
func _map_rules() -> void:
	var h := MapManager.data("house")
	check(h.is_solid(Vector2i(0, 0)) and h.is_solid(Vector2i(-1, 3)) and h.is_solid(Vector2i(8, 3)), "walls and off the map are solid")
	check(not h.is_solid(Vector2i(3, 3)) and h.tile(Vector2i(3, 3)) == "tatami", "tatami is walkable")
	check(h.is_solid(Vector2i(1, 2)) and h.prop_at(Vector2i(1, 2)).get("use", "") == "sleep", "the futon is solid and sleeps")
	check(h.door_at(Vector2i(4, 6)).to == "farm", "the house door goes to the farm")
	check(h.step(Vector2i(3, 3)) == "floor" and h.step(Vector2i(3, 5)) == "soil", "footsteps by floor")
	var t := MapManager.data("town")
	check(t.door_at(Vector2i(-1, 10)).to == "farm", "walking off the west edge goes to the farm")
	_homes(t)
	check(t.is_solid(Vector2i(17, 6)) and t.is_solid(Vector2i(20, 6)) and not t.is_solid(Vector2i(18, 6)), "torii posts block, the path through it doesn't")
	check(t.is_solid(Vector2i(32, 15)), "the pond is solid")
	check(MapView.ground_key(t, Vector2i(31, 14)) == "ground:water:%d" % (PlaceholderArt.WATER_N | PlaceholderArt.WATER_W), "pond banks")
	# The river: down the lane off the village's south edge and back; water across the map with
	# banks only at the shores (none at the map's side edges, it flows on), rocks in the current.
	var rv := MapManager.data("river")
	var mn := MapManager.data("minamino")
	check(t.door_at(Vector2i(4, 22)).get("to", "") == "minamino" and mn.door_at(Vector2i(4, -1)).get("to", "") == "town"
		and mn.door_at(Vector2i(4, 20)).get("to", "") == "river" and rv.door_at(Vector2i(4, -1)).get("to", "") == "minamino",
		"the village lane, Minamino and the river path join up")
	check(not t.is_solid(Vector2i(4, 21)) and t.tile(Vector2i(4, 21)) == "path", "the lane runs to the village's south edge")
	# The bamboo hill up the village's north lane: doors both ways, the clumps solid, the path
	# open from the foot to the lookout, the cliff along the top.
	var hl := MapManager.data("hill")
	var kn := MapManager.data("kaminoda")
	check(t.door_at(Vector2i(10, -1)).get("to", "") == "kaminoda" and kn.door_at(Vector2i(10, 20)).get("to", "") == "town"
		and kn.door_at(Vector2i(10, 20)).spawn == t.spawns.north[0], "the village's north lane and Kaminoda join up")
	check(kn.door_at(Vector2i(22, -1)).get("to", "") == "hill" and hl.door_at(Vector2i(19, 30)).get("to", "") == "kaminoda"
		and hl.door_at(Vector2i(19, 30)).spawn == kn.spawns.hill[0], "Kaminoda's lane north and the hill path join up")
	var clumps := hl.props.filter(func(p): return p.kind == "bamboo")
	check(clumps.size() > 50 and clumps.all(func(p): return hl.is_solid(Vector2i(p.cell)) and hl.tile(Vector2i(p.cell)) == "grass"), "bamboo clumps stand solid on grass")
	var seen := {hl.spawns.start[0]: true}
	var todo: Array = [hl.spawns.start[0]]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for o in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + o
			if hl.in_bounds(n) and not seen.has(n) and not hl.is_solid(n):
				seen[n] = true
				todo.append(n)
	check(seen.has(hl.spawns.top[0]), "the lookout can be walked to from the foot")
	check(hl.is_solid(Vector2i(5, 0)) and hl.tile(Vector2i(5, 0)) == "rock_wall", "the cliff along the top")
	# The village's outer parts: every door of each can be walked to from its way in, and every
	# house door leads to a room whose way out comes back in front of it.
	for id in ["kaminoda", "sakurazaka", "minamino"]:
		var m := MapManager.data(id)
		var reach := _walkable(m, m.spawns.start[0])
		for door in m.doors:
			var near: bool = door.cells.any(func(c: Vector2i):
				return [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].any(func(o): return reach.has(c + o)))
			check(near, "%s: the door to %s can be walked to" % [id, door.to])
			var room := MapManager.data(door.to)
			if room.indoor:
				var out: Dictionary = room.doors[0]
				check(out.to == id and reach.has(out.spawn) and room.door_at(room.spawns.start[0] + Vector2i.DOWN) == out,
					"%s: %s's door comes back out in front of it" % [id, door.to])
	check(rv.tile(Vector2i(0, 7)) == "water" and rv.is_solid(Vector2i(10, 7)) and not rv.is_solid(rv.spawns.shore[0]), "the river is solid, the shore is not")
	check(MapView.ground_key(rv, Vector2i(0, 6)) == "ground:water:%d" % PlaceholderArt.WATER_N, "no bank at the map's edge, one at the shore")
	check(MapView.ground_key(rv, Vector2i(19, 9)) == "ground:water:%d" % PlaceholderArt.WATER_S, "the far shore's bank")
	check(rv.props.filter(func(p): return p.kind == "river_rock").all(func(p): return rv.tile(p.cell) == "water"), "the rocks stand in the water")
	# Ambient by place.
	var rules: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json")).ambient.rules
	var outside := AmbientPicker.pick(rules, "rain", "summer", 12, "outdoor")
	var inside := AmbientPicker.pick(rules, "rain", "summer", 12, "indoor")
	check(inside.get("amb_rain", 0.0) > 0.0 and inside.amb_rain < outside.get("amb_rain", 0.0), "rain is muffled indoors")
	check(AmbientPicker.pick(rules, "sunny", "summer", 12, "indoor").is_empty(), "no cicadas indoors")
	check(AmbientPicker.pick(rules, "sunny", "summer", 12) == AmbientPicker.pick(rules, "sunny", "summer", 12, "outdoor"), "outdoor is the default place")


## The villagers' homes: doors from the village with hours, the way back out, the furniture.
func _homes(t: MapData) -> void:
	var want := {Vector2i(5, 6): "tome_house", Vector2i(8, 15): "kota_house", Vector2i(25, 15): "sayo_house"}
	for c in want:
		var d := t.door_at(c)
		check(d.get("to", "") == want[c] and d.has("hours") and d.closed != "", "the village door %s leads to %s, with hours" % [c, want[c]])
		var m := MapManager.data(want[c])
		check(m != null and m.indoor and m.door_at(m.doors[0].cells[0]).to == "town" and m.doors[0].spawn == c + Vector2i.DOWN,
			"%s is indoors and its door comes out in front of the village door" % want[c])
		check(m != null and m.spawns.has("home") and not m.is_solid(m.spawns.home[0]), "%s has a free home spot" % want[c])
	var door := t.door_at(Vector2i(5, 6))
	check(MapData.door_open(door, 7 * 60) and MapData.door_open(door, 6 * 60) and not MapData.door_open(door, 19 * 60)
		and not MapData.door_open(door, 25 * 60) and MapData.door_open({}, 25 * 60), "a home is open 6:00-19:00, a door without hours always")
	check(t.door_at(Vector2i(23, 15)).to == "store" and not t.door_at(Vector2i(23, 15)).has("hours"), "the store's own door keeps its shop hours")
	var store_house: Dictionary = t.prop_at(Vector2i(23, 14))
	check(store_house.get("side_door", -1) == 4 and store_house.cell.x + 4 == 25, "the store house draws Sayo's side door over its door cell")
	# Every prop kind on every map has a look in the flat view, and the homes build in 3D
	# without the magenta stand-in box.
	for id in MapManager.ids():
		var m := MapManager.data(id)
		for p in m.props:
			check(MapView.COLORS.has(p.kind), "map %s prop %s has a flat colour" % [id, p.kind])
	for id in ["tome_house", "kota_house", "sayo_house"]:
		var kinds := MapManager.data(id).props.map(func(p): return p.kind)
		for k in (["irori", "tokonoma", "zabuton", "andon"] if id != "sayo_house" else ["tokonoma", "low_table", "zabuton", "byobu"]):
			check(k in kinds, "%s has a %s" % [id, k])
	for bad in [["06:00"], ["20:00", "06:00"], ["6", "20:00"]]:
		check(MapData.parse({"id": "x", "size": [2, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["aa"], "spawns": {"start": [[0, 0], "up"]},
			"doors": [{"cells": [[1, 0]], "to": "town", "spawn": [5, 7], "facing": "down", "hours": bad, "closed": "Shut."}]})[0] != "",
			"refused door hours %s" % [bad])
	check(MapData.parse({"id": "x", "size": [2, 1], "legend": {"a": {"tile": "grass"}}, "ground": ["aa"], "spawns": {"start": [[0, 0], "up"]},
		"doors": [{"cells": [[1, 0]], "to": "town", "spawn": [5, 7], "facing": "down", "hours": ["06:00", "20:00"]}]})[0] != "",
		"door hours without a closed message are refused")


## The land past an outdoor map's edge (Surroundings) and buildings fading while in the
## farmer's way (Occluders), in the 3D view.
func _edges_and_fades() -> void:
	# Loaded, not named: these scripts reach the Game autoload, which a --script test only has at run time.
	var Surroundings: GDScript = load("res://scripts/world3d/surroundings.gd")
	var Occluders: GDScript = load("res://scripts/world3d/occluders.gd")
	var town := MapManager.data("town")
	var world: Node3D = load("res://scripts/world3d/map_world.gd").new()
	root.add_child(world)
	world.build(town)
	check(world.surroundings != null and world.surroundings.material != null, "the village has land past its edge")
	var kind := func(c: Vector2i) -> String: return town.tile(c)
	# The road off the village's west edge (0, 10) runs on; grass stays grass.
	check(Surroundings.ground_key(kind, town.w, town.h, Vector2i(-5, 10)).begins_with("ground:path:"),
		"the west road runs on past the edge")
	check(Surroundings.ground_key(kind, town.w, town.h, Vector2i(3, -4)).begins_with("ground:grass:"), "grass past the north edge")
	check(Surroundings.edge_cell(Vector2i(-3, 40), town.w, town.h) == Vector2i(0, town.h - 1), "an apron cell takes the nearest edge cell")
	# Pines only off the map, behind it on screen, never on the road or the near (south / east) sides.
	var pines := 0
	var margin: int = Surroundings.MARGIN
	var wrong := []
	for y in range(-margin, town.h + margin):
		for x in range(-margin, town.w + margin):
			var c := Vector2i(x, y)
			if not Surroundings.pine_at(kind, town.w, town.h, c):
				continue
			pines += 1
			if town.in_bounds(c) or (c.y >= 0 and c.x >= 0) and c.x - c.y <= town.w + 1 and c.x - c.y >= -town.h - 1 					or (c.x < 0 and absi(c.y - 10) <= 1):
				wrong.append(c)
	check(pines > 50 and wrong.is_empty(), "a wood behind the village (%d pines), none in the way %s" % [pines, wrong.slice(0, 5)])
	check(Surroundings.behind_map(Vector2(5.5, -0.5), town.w, town.h) and Surroundings.behind_map(Vector2(-0.5, 6.5), town.w, town.h)
		and not Surroundings.behind_map(Vector2(5.5, town.h + 0.5), town.w, town.h)
		and not Surroundings.behind_map(Vector2(town.w + 0.5, 6.5), town.w, town.h), "behind the map: north and west yes, south and east no")
	# Each village house is one thing that fades: behind it the farmer sees through it, in front not.
	var house: Dictionary = {}
	for p in town.props:
		if p.kind == "village_house":
			house = p
			break
	var occ: RefCounted = world.occluders
	var back := Vector3(0.634, 0.448, 0.634).normalized()
	var mid := Vector3(house.cell.x + house.size.x / 2.0, 0, 0)
	var behind := mid + Vector3(0, 0, house.cell.y - 0.5)
	var front := mid + Vector3(0, 0, house.cell.y + house.size.y + 1.5)
	var it := -1   # the house's own group
	for i in occ.count():
		var c: Vector3 = occ.box_of(i).get_center()
		if Rect2(Vector2(house.cell), Vector2(house.size)).has_point(Vector2(c.x, c.z)):
			it = i
	check(occ.count() >= 5 and it >= 0, "the village's houses and trees can fade (%d)" % occ.count())
	occ.update(behind, back, 1.0)
	check(it >= 0 and occ.fade_of(it) == Occluders.FADED, "behind a house it fades")
	occ.update(front, back, 1.0)
	check(it >= 0 and occ.fade_of(it) == 0.0, "in front of it the house is solid again")
	check(not Occluders.hides(AABB(Vector3(0, 0, 0), Vector3(4, 2.5, 3)), Vector3(2, 0, 5), back),
		"a house behind the farmer never fades")
	check(Occluders.hides(AABB(Vector3(0, 0, 0), Vector3(4, 2.5, 3)), Vector3(2, 0, -0.5), back),
		"a house in front of the farmer fades")
	_lit_windows(world, occ)
	world.free()
	var room: Node3D = load("res://scripts/world3d/map_world.gd").new()
	root.add_child(room)
	room.build(MapManager.data("house"))
	check(room.surroundings == null, "no land past a room's walls")
	room.free()


## Lit windows at night (NightLights): the village's houses list theirs (shops' doors under a
## noren stay dark), each faces the camera side and is seen from the eye unless a solid
## building stands between; a faded one lets the light through as much as it is faded.
func _lit_windows(world: Node3D, occ: RefCounted) -> void:
	var NightLights: GDScript = load("res://scripts/world3d/night_lights.gd")
	var houses := MapManager.data("town").props.filter(func(p): return p.kind == "village_house")
	var shops := houses.filter(func(p): return p.get("noren", false))
	check(world.windows.size() >= houses.size() * 2 and world.is_in_group(NightLights.GROUP),
		"the village's %d houses have lit windows (%d)" % [houses.size(), world.windows.size()])
	var facing: bool = world.windows.all(func(w): return w.normal == Vector3(0, 0, 1) or w.normal.is_equal_approx(Vector3(1, 0, 0)))
	check(facing, "every lit window faces +z or +x (the camera side)")
	var doors: Array = world.windows.filter(func(w): return w.key == "build:shoji_door")
	check(doors.size() >= houses.size() - shops.size(), "homes' doors light up, shops' doors under a noren not (%d doors)" % doors.size())
	var eye := Vector3(0.634, 0.448, 0.634).normalized() * 25.0
	var seen := 0
	for w in world.windows:
		var cam_at: Vector3 = w.pos + eye
		var k: float = NightLights.how_seen(w, cam_at, occ)
		check(k >= 0.0 and k <= 1.0, "how_seen is 0..1")
		if k == 1.0:
			seen += 1
	check(seen >= world.windows.size() / 2, "most windows are in plain view of the eye (%d of %d)" % [seen, world.windows.size()])
	var win: Dictionary = world.windows[0]
	var away := {"key": win.key, "pos": win.pos, "size": win.size, "normal": -win.normal}
	check(NightLights.how_seen(away, win.pos + eye, occ) == 0.0, "a window turned from the eye stays dark")
	# A solid box between the window and the eye hides it; faded, it lets the light through.
	var Occluders: GDScript = load("res://scripts/world3d/occluders.gd")
	var lone := {"key": "build:shoji", "pos": Vector3(0, 1, 0), "size": Vector2(0.7, 0.5), "normal": Vector3(0, 0, 1)}
	var blocker: RefCounted = Occluders.new()
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2, 3, 1)
	box.mesh = mesh
	box.position = Vector3(0, 1.5, 3)
	box.material_override = StandardMaterial3D.new()
	blocker.add([box])
	check(NightLights.how_seen(lone, Vector3(0, 1, 20), blocker) == 0.0, "a solid house in front hides a window")
	blocker.update(Vector3(0, 0, 2), Vector3(0, 0, 1), 10.0)   # the farmer behind it: it fades
	var through: float = NightLights.how_seen(lone, Vector3(0, 1, 20), blocker)
	check(is_equal_approx(through, Occluders.FADED), "a faded house lets the window's light through (%.2f)" % through)
	check(NightLights.how_seen(lone, Vector3(20, 1, 20), blocker) == 1.0, "seen past the house's side")
	var c: Array = NightLights.corners(lone)
	check(c[0].distance_to(Vector3(-0.35, 1.25, 0)) < 0.001 and c[2].distance_to(Vector3(0.35, 0.75, 0)) < 0.001, "corners: top left to bottom right")
	box.free()
	var room: Node3D = load("res://scripts/world3d/map_world.gd").new()
	room.build(MapManager.data("house"))
	check(room.windows.is_empty(), "no lit windows inside the farmhouse (its own lamp light)")
	room.free()


## Winter snow off the farm: outdoor maps hold it by tile kind (paths a little less, water
## none) and on their roofs, in both views; rooms and the mine floors stay bare.
func _map_snow() -> void:
	var rules: Dictionary = root.get_node("Game").snow_rules
	var town := MapManager.data("town")
	var k := SnowLayer.MASK_PER_CELL
	var grass := SnowLayer.map_hold(town, Vector2i(0, 0), rules)
	var path := SnowLayer.map_hold(town, Vector2i(0, 10), rules)
	var gravel := SnowLayer.map_hold(town, Vector2i(15, 2), rules)
	var pond := SnowLayer.map_hold(town, Vector2i(32, 15), rules)
	check(grass == 1.0 and path < grass and gravel < grass and gravel > 0.0 and pond == 0.0,
		"village snow: grass %s, path %s, gravel %s, pond %s" % [grass, path, gravel, pond])
	for kind in ["gravel", "scree", "rock_wall"]:
		check(rules.ground.has(kind), "snow hold for %s ground" % kind)
	for id in ["town", "river", "mine"]:
		check(SnowLayer.map_has_snow(MapManager.data(id)), "snow lies on %s" % id)
	for id in ["house", "store", "smithy", "coop", "barn", "tome_house", "mine_floor", "farm"]:
		check(not SnowLayer.map_has_snow(MapManager.data(id)), "no map snow on %s" % id)
	var room := SnowLayer.map_mask_image(MapManager.data("house"), rules)
	var room_white := 0.0
	for y in room.get_height():
		for x in room.get_width():
			room_white = maxf(room_white, room.get_pixel(x, y).r)
	check(room_white == 0.0, "a room's mask holds no snow")
	var mask := SnowLayer.map_mask_image(town, rules)
	check(mask.get_size() == Vector2i(town.w * k, town.h * k) and absf(mask.get_pixel(1, 10 * k + 1).r - path) < 0.01,
		"the village mask spans the map and holds the path value")
	var roofs := SnowLayer.roof_mask_image(town, rules)
	var door: Vector2i = town.doors[1].cells[0]   # Tome's door, on her house front
	check(roofs.get_pixel(4 * k + 1, 4 * k + 1).r > 0.5 and roofs.get_pixel(door.x * k + 1, door.y * k + 1).r == 0.0
		and roofs.get_pixel(4 * k + 1, door.y * k + 1).r == 0.0 and roofs.get_pixel(1, 10 * k + 1).r == 0.0,
		"2D roof snow over the houses, not on their front row or the road")

	# The flat view: ground snow under the props, roof snow over them, hidden without cover.
	var v2 := MapView.new()
	v2.map = town
	root.add_child(v2)
	v2.show_snow(rules)
	var sprites: Array = v2.get_children().filter(func(n): return n is Sprite2D)
	var objects: Node = v2.get_children().filter(func(n): return not n is Sprite2D)[0]
	check(sprites.size() == 2 and sprites[0].get_index() < objects.get_index() and sprites[1].get_index() > objects.get_index(),
		"2D village: snow under the props and on the roofs")
	v2.set_snow(0.0)
	check(not sprites[0].visible and not sprites[1].visible, "2D village: no cover, no snow")
	v2.set_snow(0.7)
	check(sprites.all(func(s): return s.visible and is_equal_approx(s.material.get_shader_parameter("cover"), 0.7)),
		"2D village: the snow takes the cover")
	v2.free()
	var room_2d := MapView.new()
	room_2d.map = MapManager.data("house")
	root.add_child(room_2d)
	room_2d.show_snow(rules)
	check(room_2d.get_children().all(func(n): return not n is Sprite2D) and room_2d.snow_mask == null, "2D: no snow indoors")
	room_2d.set_snow(1.0)
	room_2d.free()

	# 3D: the village ground and roofs take the cover; the mine floor has nothing to whiten.
	var tops := func(w: Node3D) -> Array:
		return w.get_children().filter(func(n): return n is MeshInstance3D and n.material_override is ShaderMaterial)
	var v3: Node3D = load("res://scripts/world3d/map_world.gd").new()
	v3.build(town)
	v3.set_snow(0.5)
	var snowy: Array = tops.call(v3)
	# The ground, five house roofs, the torii, the hokora roof and two lanterns: one cover each.
	check(snowy.size() >= 10 and snowy.all(func(n): return is_equal_approx(n.material_override.get_shader_parameter("cover"), 0.5)),
		"3D village: ground and roof tops take the cover (%d)" % snowy.size())
	v3.free()
	for id in ["mine_floor", "house"]:
		var w3: Node3D = load("res://scripts/world3d/map_world.gd").new()
		w3.build(MapManager.data(id))
		check(tops.call(w3).is_empty(), "3D %s: no snow" % id)
		w3.free()


## The homes build in 3D without the magenta stand-in box (MapWorld needs the autoloads, so
## this runs on the first frame).
## The farmhouse's thatched roof (Minka): every face turned the way its normal says (Godot
## draws clockwise fronts), the soffit at the front eave above the farmer's head, the ridge
## where the pitch puts it.
func _minka() -> void:
	var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	var crest: float = load("res://scripts/world3d/minka.gd").roof(w, Rect2(1.45, 0.55, 6.1, 3.5), 1.45, 1.25, 0.5)
	check(is_equal_approx(crest, 1.45 + 1.75 * 1.25 + 0.5 + 0.4), "Minka ridge height (%.2f)" % crest)
	var faces := 0
	var wrong := 0
	var low := 99.0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				faces += 1
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
				for k in 3:
					if v[i + k].z > 4.0:
						low = minf(low, v[i + k].y)
	check(faces >= 26 and wrong == 0, "Minka faces turned outwards (%d of %d wrong)" % [wrong, faces])
	check(low >= 1.4, "Minka front eave above the farmer's head (%.2f)" % low)
	check(_walls_facing_in(w, Vector2(4.5, 2.3)) == 0, "Minka's eave band faces away from the house")
	w.free()
	# The gable roofs of the coop (thatch) and the barn (kawara with tile rolls).
	var minka: GDScript = load("res://scripts/world3d/minka.gd")
	for rolls in [0.0, 0.25]:
		w = load("res://scripts/world3d/farm_world.gd").new()
		var eave := Rect2(18.78, 0.68, 5.44, 3.6)
		crest = minka.gable(w, eave, 1.45, 0.55, 0.15, "build:kawara", "build:kawara_edge", rolls)
		var want := 1.45 + 1.8 * 0.55 + 0.15 + (0.06 if rolls > 0.0 else 0.0)
		check(is_equal_approx(crest, want), "gable ridge height %.3f (rolls %.2f)" % [crest, rolls])
		faces = 0
		wrong = 0
		low = 99.0
		for n in w.get_children():
			if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
				var arr: Array = n.mesh.surface_get_arrays(0)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				for i in range(0, v.size(), 3):
					faces += 1
					if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
						wrong += 1
					for k in 3:
						if v[i + k].z > 4.2:
							low = minf(low, v[i + k].y)
		var expect := 24 + (21 * 2 * 5 if rolls > 0.0 else 0)   # slopes, soffit, bands, verges, snow; 21 rolls a side
		check(faces == expect and wrong == 0, "gable faces turned outwards (%d of %d wrong, %d expected)" % [wrong, faces, expect])
		check(low >= 1.45, "gable front eave above the farmer's head (%.2f)" % low)
		check(_walls_facing_in(w, eave.get_center()) == 0, "gable eave bands and verges face outwards (rolls %.2f)" % rolls)
		w.free()
	# The tiled ridge: it rises at both ends (the curl) and stays level in the middle (the
	# onigawara are BoxMeshes, not counted here).
	w = load("res://scripts/world3d/farm_world.gd").new()
	minka.ridge(w, 0.0, 5.0, 2.0, 1.5)
	var tops := {}   # x rounded to a tenth: highest y of the ridge meshes there
	faces = 0
	wrong = 0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				faces += 1
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
				for k in 3:
					var key := snappedf(v[i + k].x, 0.1)
					tops[key] = maxf(tops.get(key, -1.0), v[i + k].y)
	check(faces > 0 and wrong == 0, "ridge faces turned outwards (%d of %d wrong)" % [wrong, faces])
	var level: float = tops.get(0.8, 0.0)   # where the curl starts (sweep 0.8); one span between
	check(is_equal_approx(level, tops.get(4.2, -1.0)) and tops.get(0.0, 0.0) > level + 0.1
		and tops.get(5.0, 0.0) > level + 0.1, "the ridge curls up at both ends (%s)" % [tops])
	w.free()


## The shrine pieces (Shrine): every mesh face turned to its normal, the lantern's facets
## facing away from its axis, the torii's kasagi rising to its ends.
func _shrine() -> void:
	var shrine: GDScript = load("res://scripts/world3d/shrine.gd")
	var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	shrine.stone_lantern(w, Vector3(3.5, 0, 3.5))
	var faces := 0
	var wrong := 0
	var inward := 0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				faces += 1
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
				var c := (v[i] + v[i + 1] + v[i + 2]) / 3.0
				if Vector2(nm[i].x, nm[i].z).dot(Vector2(c.x - 3.5, c.z - 3.5)) < -0.0001:
					inward += 1
	check(faces > 100 and wrong == 0 and inward == 0, "stone lantern facets turned outwards (%d wrong, %d inward of %d)" % [wrong, inward, faces])
	w.free()
	w = load("res://scripts/world3d/farm_world.gd").new()
	shrine.torii(w, Vector3(19, 0, 6.5), Rect2(17, 6, 4, 1))
	shrine.hokora(w, Vector3(19, 0, 2))
	faces = 0
	wrong = 0
	var ends := -1.0
	var middle := -1.0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				faces += 1
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
			if n.material_override is StandardMaterial3D and n.material_override.albedo_color == shrine.BLACK:
				for p in v:
					if is_equal_approx(p.x, 19.0):
						middle = maxf(middle, p.y)
					elif absf(p.x - 19.0) > 2.1:
						ends = maxf(ends, p.y)
	check(faces > 0 and wrong == 0, "torii and hokora faces turned outwards (%d of %d wrong)" % [wrong, faces])
	check(middle > 2.0 and ends > middle + 0.12, "the kasagi rises to its ends (middle %.2f, ends %.2f)" % [middle, ends])
	w.free()


## The bin, chest and seed stand (FarmProps): every face drawn the way its normal points, a
## tapered block's faces all turned out from its middle, every material lit, and the stand's
## front eave clear of the farmer (1.45 or more over z past its posts).
func _farm_props() -> void:
	var props: GDScript = load("res://scripts/world3d/farm_props.gd")
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	props.block(st, Rect2(0, 0, 1, 0.8), 0.0, Rect2(0.1, 0.1, 0.8, 0.6), 0.5)
	var arr: Array = st.commit().surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var out := 0
	for i in range(0, v.size(), 3):
		var c := (v[i] + v[i + 1] + v[i + 2]) / 3.0
		if nm[i].dot(c - Vector3(0.5, 0.25, 0.4)) > 0.0 and (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) < 0.0:
			out += 1
	check(v.size() == 36 and out == 12, "a tapered block's 12 triangles face out (%d)" % out)
	for what in ["bin", "chest", "stand"]:
		var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
		props.call(what, w)
		var faces := 0
		var wrong := 0
		var unlit := 0
		var low_eave := 9.0
		for n in w.get_children():
			if not n is MeshInstance3D:
				continue
			var mat: Variant = n.material_override
			if mat is StandardMaterial3D and mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				unlit += 1
			if n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
				arr = n.mesh.surface_get_arrays(0)
				v = arr[Mesh.ARRAY_VERTEX]
				nm = arr[Mesh.ARRAY_NORMAL]
				for i in range(0, v.size(), 3):
					faces += 1
					if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
						wrong += 1
				for p in v:
					if p.z > 4.06:
						low_eave = minf(low_eave, p.y)
		check(faces > 50 and wrong == 0 and unlit == 0,
			"%s: %d faces, %d drawn the wrong way, %d unlit materials" % [what, faces, wrong, unlit])
		if what == "stand":
			check(low_eave >= 1.45, "the seed stand's front eave clears the farmer (%.2f)" % low_eave)
		w.free()


## Interiors (RoomWalls): every face drawn the way its normal points, all lit; the back walls'
## room face stays within 0.05 of the wall line (things hung on it sit 0.08 out), the front
## sills stay low; a shoe stone below the door's step where the earth there is clear; the
## coop's and barn's walls are boards, a house's plaster.
func _room_walls() -> void:
	for id in ["house", "clinic", "store", "smithy", "coop", "barn"]:
		var m := MapManager.data(id)
		var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
		load("res://scripts/world3d/room_walls.gd").build(w, m)
		var wrong := 0
		var unlit := 0
		var proud := 0.0
		var front_top := 0.0
		var keys := []
		var stones := 0
		for n in w.get_children():
			if not n is MeshInstance3D:
				continue
			var mat: Variant = n.material_override
			if mat is StandardMaterial3D:
				if mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
					unlit += 1
				if mat.albedo_texture != null:
					keys.append(mat.albedo_texture)
			if not n.mesh is ArrayMesh:
				continue
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				if (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).dot(nm[i]) >= 0.0:
					wrong += 1
			var is_stone: bool = mat is StandardMaterial3D and mat.albedo_color == Color("8a8680")
			for p in v:
				if p.y > 0.5 and p.x > 1.2 and p.z < 1.5:    # the back wall, past the corner post
					proud = maxf(proud, p.z - 1.0)
				if p.x > 1.2 and p.z > m.h - 1.5 and p.x < m.w - 1:   # along the front sill
					front_top = maxf(front_top, p.y)
				if is_stone and p.y > 0.0:
					stones += 1
		var free_stone := false   # the earth below the step in the door's column is clear
		for d in m.doors:
			for c: Vector2i in d.cells:
				free_stone = free_stone or load("res://scripts/world3d/room_walls.gd")._shoe_stone(m, c.x) != Vector2i(-1, -1)
		var plaster := PlaceholderArt.tex("build:plaster") in keys
		check(wrong == 0 and unlit == 0, "%s walls: %d faces the wrong way, %d unlit" % [id, wrong, unlit])
		check(proud <= 0.05, "%s: the back wall's face stands %.3f out (things hang at 0.08)" % [id, proud])
		check(front_top <= 0.4, "%s: the front sill keeps the room in view (%.2f high)" % [id, front_top])
		check(plaster == (m.walls == "plaster"), "%s: walls are %s" % [id, m.walls])
		check((stones > 0) == free_stone, "%s: a shoe stone below the door's step (%d corners)" % [id, stones])
		w.free()
	var bad := MapData.parse({"id": "x", "size": [1, 1], "ground": ["."], "legend": {".": {"tile": "earth"}}, "walls": "glass"})
	check(bad[0] != "", "a map with unknown walls is refused")


## The rooms' furniture (RoomProps): every kind is used by some map and has a look; each
## piece is built of lit meshes (only GLOWS colours unshaded: the lamp, embers, fire), its
## faces wound to their normals, inside its footprint (a little overhang allowed) and clear
## of the full-height back walls above and to the left (their posts stand 0.04 out), so
## nothing pokes through the timber. The front walls are low sills inside their own cells.
func _room_props() -> void:
	var rp: GDScript = load("res://scripts/world3d/room_props.gd")
	var used := {}
	var glowing := {}
	for id in MapManager.ids():
		var m := MapManager.data(id)
		for p in m.props:
			if not str(p.kind) in rp.KINDS:
				continue
			used[p.kind] = true
			var r := Rect2(Vector2(p.cell), Vector2(p.size))
			var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
			rp.prop(w, p, Vector3(r.get_center().x, 0, r.get_center().y), r)
			var shapes := 0
			var unlit := 0
			var wrong := 0
			var outside := 0
			var in_wall := 0
			for n in w.get_children():
				if not n is MeshInstance3D:
					continue
				if not n.mesh is ArrayMesh:
					shapes += 1
					continue
				var mat: StandardMaterial3D = n.material_override
				if mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
					if mat.albedo_color in rp.GLOWS:
						glowing[p.kind] = true
					else:
						unlit += 1
				var arr: Array = n.mesh.surface_get_arrays(0)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
				for i in range(0, idx.size(), 3):
					var c := (v[idx[i + 1]] - v[idx[i]]).cross(v[idx[i + 2]] - v[idx[i]])
					if c.length() > 1e-9 and c.dot(nm[idx[i]]) >= 0.0:
						wrong += 1
				for q in v:
					if not r.grow(0.16).has_point(Vector2(q.x, q.z)):
						outside += 1
					for o in [Vector2(-0.035, 0), Vector2(0, -0.035)]:
						var cell := Vector2i((Vector2(q.x, q.z) + o).floor())
						if m.in_bounds(cell) and m.tile(cell) == "wall":
							in_wall += 1
							break
			check(shapes == 0 and unlit == 0 and wrong == 0 and outside == 0 and in_wall == 0,
				"%s %s at %s: %d primitive shapes, %d unlit, %d faces the wrong way, %d corners outside, %d in a wall"
				% [id, p.kind, p.cell, shapes, unlit, wrong, outside, in_wall])
			w.free()
	var texts := ""   # the house's extensions (kotatsu, nagamochi) are only in its file
	for id in MapManager.ids():
		texts += FileAccess.get_file_as_string("res://data/maps/%s.json" % id)
	for kind in rp.KINDS:
		check(used.has(kind) or texts.contains('"%s"' % kind), "some map has a %s" % kind)
	for kind in ["andon", "kamado", "forge", "irori", "butsudan"]:
		check(glowing.has(kind), "the %s gives off light (an unshaded glow)" % kind)


## Trees (Trees): lit meshes wound to their normals, inside about 0.95 of the trunk (the
## wood scales its pines up to 1.3, still inside 1.0) and
## 2.3 high (the wood's margins count on it); broadleaf leaves by season, bare in winter,
## persimmons hanging in fall and winter, petals under a cherry in bloom; snow on the pines'
## tiers only when asked; the wood past the map's edge is MultiMeshes of the same pines with
## its snow driven by the world's set_snow.
func _trees() -> void:
	var trees: GDScript = load("res://scripts/world3d/trees.gd")
	var parts_of := func(build: Callable) -> Node3D:
		var w: Node3D = load("res://scripts/world3d/farm_world.gd").new()
		var p = load("res://scripts/world3d/farm_props.gd").Parts.new()
		build.call(p)
		p.commit(w)
		return w
	var look := func(w: Node3D) -> Dictionary:
		var out := {"bad": 0, "colours": [], "snow": 0, "reach": 0.0, "top": 0.0}
		for n in w.get_children():
			if not n is MeshInstance3D:
				continue
			if not n.mesh is ArrayMesh:
				out.bad += 1
				continue
			var mat: Material = n.material_override
			if mat is ShaderMaterial:
				out.snow += 1
			elif mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				out.bad += 1
			else:
				out.colours.append(mat.albedo_color)
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				var c := (v[i + 1] - v[i]).cross(v[i + 2] - v[i])
				if c.length() > 1e-9 and c.dot(nm[i]) >= 0.0:
					out.bad += 1
			for q in v:
				out.reach = maxf(out.reach, Vector2(q.x, q.z).length())
				out.top = maxf(out.top, q.y)
		return out
	for kind in ["persimmon", "sakura"]:
		for season in ["spring", "summer", "fall", "winter"]:
			for seed in [3, 40]:
				var w: Node3D = parts_of.call(func(p): trees.broadleaf(p, Vector3.ZERO, kind, season, seed))
				var l: Dictionary = look.call(w)
				var leaf: Color = trees.LEAVES[kind][season]
				var leafy: bool = leaf in l.colours or leaf.darkened(0.14) in l.colours
				var fruit: bool = trees.FRUIT in l.colours
				check(l.bad == 0 and l.reach < 0.95 and l.top < 2.3, "%s in %s (seed %d): %d faults, reaches %.2f, %.2f high" % [kind, season, seed, l.bad, l.reach, l.top])
				check(leafy == (season != "winter"), "%s in %s: leaves %s" % [kind, season, leafy])
				check(fruit == (kind == "persimmon" and season in ["fall", "winter"]), "%s in %s: fruit %s" % [kind, season, fruit])
				check((trees.PETAL in l.colours) == (kind == "sakura" and season == "spring"), "%s in %s: petals on the ground" % [kind, season])
				w.free()
	for garden in [true, false]:
		for snow in [true, false]:
			var w: Node3D = parts_of.call(func(p): trees.pine(p, Vector3.ZERO, 7, garden, snow))
			var l: Dictionary = look.call(w)
			check(l.bad == 0 and l.reach * (1.0 if garden else 1.3) < 1.0 and l.top * 1.3 < 2.6 and (l.snow > 0) == snow and trees.NEEDLES[0] in l.colours,
				"pine (garden %s, snow %s): %d faults, reaches %.2f, %.2f high, %d snow" % [garden, snow, l.bad, l.reach, l.top, l.snow])
			w.free()
	var m: Node3D = load("res://scripts/world3d/map_world.gd").new()
	m.build(MapManager.data("kaminoda"))
	var wood: Array = m.surroundings.get_children().filter(func(n): return n is MultiMeshInstance3D)
	var instances := 0
	for n in wood:
		instances += n.multimesh.instance_count
	var driven: bool = not m.surroundings.snow_mats.is_empty() and m.surroundings.snow_mats.all(func(s): return s in m._snow_mats)
	check(wood.size() >= 4 and instances > 20 and driven, "the wood: %d MultiMeshes, %d pine parts, snow driven %s" % [wood.size(), instances, driven])
	m.free()


## Grass tufts (GrassTufts): the same tufts for a cell every time, inside it; on a map only
## on free grass cells with no prop, each carrying its cell's snow hold, the material driven
## by set_snow; the apron grows them too; none indoors; on the farm none on tilled ground,
## things or fixed cells, and tilling a cell clears its tufts.
func _grass() -> void:
	var gt: GDScript = load("res://scripts/world3d/grass_tufts.gd")
	var cells: Array[Vector2i] = []
	for i in 200:
		cells.append(Vector2i(i % 20, i / 20))
	var spots: Array = gt.spots_for(cells)
	var inside := spots.all(func(s): return Rect2(Vector2(s.cell), Vector2.ONE).grow(-0.1).has_point(Vector2(s.pos.x, s.pos.z)))
	var share := spots.size() / float(cells.size() * gt.PER_CELL) * 100.0
	check(inside and absf(share - gt.SHARE) < 10 and gt.spots_for(cells) == spots,
		"tufts inside their cells, %.0f%% of the places (%d%% wanted), the same each time" % [share, gt.SHARE])
	var tuft_cells := func(t: MultiMeshInstance3D) -> Array:
		var out := []
		for sp in t.planted:
			out.append([Vector2i(int(floor(sp.pos.x)), int(floor(sp.pos.z))), sp.hold])
		return out
	var m := MapManager.data("kaminoda")
	var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
	w.build(m)
	var bad := 0
	var hold_wrong := 0
	var rules: Dictionary = root.get_node("Game").snow_rules
	for e in tuft_cells.call(w.tufts):
		var c: Vector2i = e[0]
		if m.tile(c) != "grass" or not m.prop_at(c).is_empty() or m.is_solid(c):
			bad += 1
		if absf(e[1] - SnowLayer.map_hold(m, c, rules)) > 0.01:
			hold_wrong += 1
	var apron: Array = w.surroundings.get_children().filter(func(n): return n is MultiMeshInstance3D and n.get_script() == gt)
	check(w.tufts.multimesh.instance_count > 100 and bad == 0 and hold_wrong == 0 and w.tufts.snow_material() in w._snow_mats,
		"kaminoda: %d tufts, %d off free grass, %d with the wrong snow hold" % [w.tufts.multimesh.instance_count, bad, hold_wrong])
	check(apron.size() == 1 and apron[0].multimesh.instance_count > 100 and apron[0].snow_material() in w._snow_mats,
		"the apron past kaminoda's edge grows tufts, their snow driven")
	w.free()
	var house: Node3D = load("res://scripts/world3d/map_world.gd").new()
	house.build(MapManager.data("house"))
	check(house.tufts == null, "no grass tufts indoors")
	house.free()
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var farm := FarmGrid.new(crops)
	farm.generate(RandomNumberGenerator.new())
	var fw: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	fw.setup(farm)
	var on_bad := func() -> int:
		var n := 0
		for e in tuft_cells.call(fw.tufts):
			var d: Dictionary = farm.cell(e[0])
			if farm.fixed_at(e[0]) != "" or d.tilled or d.obj != FarmGrid.Obj.NONE or d.crop != "" or farm.items.has(e[0]):
				n += 1
		return n
	var grown: Array = tuft_cells.call(fw.tufts).map(func(e): return e[0])
	var target := Vector2i(-1, -1)
	for c in grown:
		if farm.can_farm(c) and farm.cell(c).obj == FarmGrid.Obj.NONE:
			target = c
			break
	check(fw.tufts.multimesh.instance_count > 100 and on_bad.call() == 0, "the farm: %d tufts, %d on tilled ground or things" % [fw.tufts.multimesh.instance_count, on_bad.call()])
	check(target != Vector2i(-1, -1) and farm.till(target), "a grassy farm cell can be tilled")
	var after: Array = tuft_cells.call(fw.tufts).map(func(e): return e[0])
	check(not target in after and on_bad.call() == 0, "tilling %s cleared its tufts" % [target])
	fw.free()


## Upright faces (eave bands, verges, roll ends) of the meshes in `w` whose normal points
## back towards `mid` (x, z) instead of away from it.
func _walls_facing_in(w: Node3D, mid: Vector2) -> int:
	var bad := 0
	for n in w.get_children():
		if n is MeshInstance3D and n.mesh is ArrayMesh and n.mesh.get_surface_count() > 0:
			var arr: Array = n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				if absf(nm[i].y) > 0.1:
					continue
				var c := (v[i] + v[i + 1] + v[i + 2]) / 3.0
				if Vector2(nm[i].x, nm[i].z).dot(Vector2(c.x, c.z) - mid) <= 0.0:
					bad += 1
	return bad


func _homes_3d() -> void:
	for id in ["tome_house", "kota_house", "sayo_house"]:
		var w: Node3D = load("res://scripts/world3d/map_world.gd").new()
		w.build(MapManager.data(id))
		var stand_in := 0
		var meshes := 0
		for n in w.get_children():
			if n is MeshInstance3D:
				meshes += 1
				var mat: Variant = n.material_override
				if mat is StandardMaterial3D and mat.albedo_color == Color.MAGENTA:
					stand_in += 1
		check(stand_in == 0 and meshes > 30, "%s builds in 3D (%d meshes, %d stand-ins)" % [id, meshes, stand_in])
		w.free()
	var river: Node3D = load("res://scripts/world3d/map_world.gd").new()
	river.build(MapManager.data("river"))
	var magenta := 0
	for n in river.get_children():
		if n is MeshInstance3D and n.material_override is StandardMaterial3D and n.material_override.albedo_color == Color.MAGENTA:
			magenta += 1
	check(magenta == 0 and river.get_child_count() > 10, "the river builds in 3D (%d nodes, %d stand-ins)" % [river.get_child_count(), magenta])
	river.free()


## The props the band 5 heart events leave (StoryProps): each shows only with its flag (the
## sign by its value), follows the shared flags, survives save / load, builds in both views,
## and the bell rings when used.
func _story_props() -> void:
	var where := {"door_bell": "farm", "store_sign": "town", "ume_jar": "house", "carp_streamer": "farm"}
	var kinds := func(id: String, f: Dictionary) -> Array:
		var out := []
		for p in MapManager.load_map(id, null, f)[1].props:
			if p.kind in StoryView.KINDS:
				out.append(p.kind + ("" if not p.has("style") else ":" + p.style))
		return out
	for kind in where:
		check(kinds.call(where[kind], {}).is_empty(), "no %s without its flag" % kind)
	check(kinds.call("farm", {"hachiro_bell": true}) == ["door_bell"], "the bell hangs once hachiro_bell is set")
	check(kinds.call("farm", {"hachiro_bell": false}).is_empty(), "no bell while hachiro_bell is false")
	check(kinds.call("house", {"tome_grandma": true}) == ["ume_jar"], "Tome's jar is in the house once tome_grandma is set")
	check(kinds.call("farm", {"kota_streamer": true}) == ["carp_streamer"], "Kota's streamer flies once kota_streamer is set (band 6)")
	check(kinds.call("farm", {"kota_streamer": true, "hachiro_bell": true}) == ["door_bell", "carp_streamer"], "the bell and the streamer together")
	var pole: Dictionary = MapManager.load_map("farm", null, {"kota_streamer": true})[1].prop_at(Vector2i(1, 6))
	var grid := FarmGrid.new({})
	grid.generate(RandomNumberGenerator.new())
	check(pole.get("kind", "") == "carp_streamer" and not grid.fixed.has(Vector2i(1, 6)), "the streamer stands on open ground at the front left of the house")
	check(kinds.call("town", {"sayo_sign": "old"}) == ["store_sign:old"], "sayo_sign old: the old name repainted")
	check(kinds.call("town", {"sayo_sign": "new"}) == ["store_sign:new"], "sayo_sign new: Sayo's own sign")
	check(kinds.call("town", {"sayo_sign": true}).is_empty(), "sayo_sign set to true (no answer) shows no sign")
	check(kinds.call("town", {"hachiro_bell": true, "tome_grandma": true}).is_empty(), "other flags show no sign")
	check(MapManager.gate_flags(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/town.json"))) == ["sayo_sign"],
		"the village is gated by sayo_sign only")
	var bell: Dictionary = MapManager.load_map("farm", null, {"hachiro_bell": true})[1].prop_at(Vector2i(5, 3))
	check(bell.get("use", "") == "examine" and root.get_node("Sfx").sounds.has(bell.get("sound", "")) and str(bell.get("message", "")) != "",
		"the bell rings with a known sound and a message")
	var jar_map: MapData = MapManager.load_map("house", ["chest", "kitchen", "room"], {"tome_grandma": true})[1]
	check(jar_map.prop_at(Vector2i(5, 1)).get("kind", "") == "ume_jar" and jar_map.is_solid(Vector2i(5, 1)),
		"the jar stands on its own cell with every extension built")
	for key in ["story:door_bell", "story:sign_old", "story:sign_new", "story:ume_jar", "story:carp_streamer"]:
		var img := PlaceholderArt.tex(key).get_image()
		check(img.get_width() > 8 and img.get_pixel(img.get_width() / 2, img.get_height() / 2) != Color.MAGENTA, "art %s is drawn" % key)

	# The shared flags (Game.flags): the cached map follows them, and they come back with a save.
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var a: Node = game_script.new()
	a.crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	a.new_game()
	var on := func(id: String, kind: String) -> bool:
		return MapManager.data(id).props.any(func(p): return p.kind == kind)
	check(not on.call("farm", "door_bell") and not on.call("town", "store_sign"), "a new game has no story props")
	a.flags["hachiro_bell"] = true   # as the event's "set" step writes it
	a.flags["sayo_sign"] = "new"
	check(on.call("farm", "door_bell") and on.call("town", "store_sign") and not on.call("house", "ume_jar"),
		"setting the flags puts the bell and the sign in the cached maps")
	var saved: Dictionary = a.to_dict()
	a.new_game()
	check(not on.call("farm", "door_bell"), "a new game takes the bell away again")
	var b: Node = game_script.new()
	b.crops = a.crops
	b.new_game()
	check(b.from_dict(JSON.parse_string(JSON.stringify(saved))) == "", "the save loads")
	var sign: Array = MapManager.data("town").props.filter(func(p): return p.kind == "store_sign")
	check(on.call("farm", "door_bell") and sign.size() == 1 and sign[0].style == "new" and not on.call("house", "ume_jar"),
		"the bell and Sayo's sign come back with the save")

	# Both views draw them from the story art.
	var town_3d: Node3D = load("res://scripts/world3d/map_world.gd").new()
	town_3d.build(MapManager.data("town"))
	var sign_tex := PlaceholderArt.tex("story:sign_new")
	check(town_3d.get_children().any(func(n): return n is MeshInstance3D and n.material_override is StandardMaterial3D 		and n.material_override.albedo_texture == sign_tex), "the village in 3D has Sayo's sign")
	town_3d.free()
	var farm_3d: Node3D = load("res://scripts/world3d/farm_world.gd").new()
	farm_3d.make_story_props(MapManager.data("farm"))
	var bell_tex := PlaceholderArt.tex("story:door_bell")
	check(farm_3d.get_children().any(func(n): return n is Sprite3D and n.texture == bell_tex), "the farm in 3D has the bell")
	farm_3d.free()
	var town_2d := MapView.new()
	town_2d.map = MapManager.data("town")
	var story_2d := StoryView.new(town_2d.map)
	check(story_2d.map.props.filter(func(p): return p.kind in StoryView.KINDS).size() == 1, "the flat view gets the one sign")
	town_2d.free()
	story_2d.free()

	# Using the bell on the farm (the real Game autoload, as the views call it).
	var g: Node = root.get_node("Game")
	g.new_game()
	g.flags["hachiro_bell"] = true
	g.maps.place("farm", Vector2i(5, 4), Vector2i.UP)
	var said := []
	var hear := func(t): said.append(t)
	g.message.connect(hear)
	load("res://scripts/farm_actions.gd").interact(Vector2i(5, 3))
	g.message.disconnect(hear)
	check(said == [bell.message], "using the bell rings it %s" % [said])

	# Solid story props on the farm block in FarmGrid (the farmer in both views, the dog,
	# throws) while their flag shows them; the bell on the house wall is not solid.
	check(not g.farm.is_solid(Vector2i(1, 4)) and g.farm.can_farm(Vector2i(1, 4)), "no lumber: its cells are open ground")
	g.flags[g.BUILD_FLAG] = "kitchen"
	g.flags["kota_streamer"] = true
	for c in [Vector2i(1, 4), Vector2i(1, 5), Vector2i(1, 6)]:
		check(g.farm.is_solid(c) and g.maps.is_solid(c, g.farm) and not g.farm.can_farm(c) and not g.farm.till(c),
			"the lumber and the streamer pole block %s" % c)
	# under_prop, not is_solid: the field is rolled at random and a rock or weed may lie there.
	check(not g.farm.under_prop(Vector2i(2, 4)) and not g.farm.under_prop(Vector2i(2, 5)) and not g.farm.under_prop(Vector2i(1, 7)),
		"the cells beside them stay open (Hachiro works and fetches from there)")
	check(MapManager.data("farm").prop_at(Vector2i(5, 3)).get("kind", "") == "door_bell" and not MapManager.data("farm").is_solid(Vector2i(5, 3)),
		"the bell's prop is not solid")
	check(g.farm.throw_target(Vector2i(4, 5), Vector2i.LEFT, 4, ["bin"], ["pond"]) == {"result": "land", "cell": Vector2i(2, 5)},
		"a throw at the lumber drops before it")
	var nights := FarmGrid.new({})
	nights.generate(RandomNumberGenerator.new())
	nights.prop_blocks = g.farm_prop_blocks
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 400:
		nights.day_end("spring", "sunny", rng)
	check(nights.cell(Vector2i(1, 4)).obj == FarmGrid.Obj.NONE and nights.cell(Vector2i(1, 6)).obj == FarmGrid.Obj.NONE
		and nights.cell(Vector2i(2, 5)).obj != FarmGrid.Obj.NONE, "no weeds grow under them (beside them they do)")
	g.maps.place("farm", Vector2i(3, 4), Vector2i.LEFT)
	said.clear()
	g.message.connect(hear)
	load("res://scripts/farm_actions.gd").interact(Vector2i(1, 4))
	g.message.disconnect(hear)
	check(said.size() == 1 and said[0].begins_with("Planed boards"), "the lumber can still be looked at %s" % [said])
	g.flags.erase(g.BUILD_FLAG)
	g.flags.erase("kota_streamer")
	check(not g.farm.is_solid(Vector2i(1, 4)) and not g.farm.is_solid(Vector2i(1, 6)) and g.farm.can_farm(Vector2i(1, 5)),
		"gone with their flags: open ground again")
	for n in [a, b]:
		n.free()


## Game: the clock stops indoors, map signals, day end puts the farmer home, the saved part.
func _game_maps() -> void:
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var g: Node = game_script.new()
	g.crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	g.rng.seed = 3
	g.new_game()
	var seen := {"changed": [], "entered": []}
	g.map_changed.connect(func(id): seen.changed.append(id))
	g.map_entered.connect(func(id): seen.entered.append(id))
	check(g.maps.id == "farm" and g.ticking(), "a new game starts on the farm, ticking")
	check(g.go_to_map("house", Vector2i(4, 5), Vector2i.UP), "into the house")
	check(seen.changed == ["house"] and seen.entered.is_empty(), "map_changed at once, map_entered waits for the view")
	g.map_arrived()
	check(seen.entered == ["house"], "map_entered after the fade")
	check(g.indoors() and not g.ticking() and not g.paused(), "indoors: no time, but not paused (the farmer walks)")
	var before: String = g.time_text()
	g._process(30.0)
	check(g.time_text() == before, "no time passes indoors (%s)" % g.time_text())
	check(not g.go_to_map("moon", Vector2i.ZERO, Vector2i.DOWN) and g.maps.id == "house", "an unknown map is refused")
	g.use_door({"to": "", "message": "Locked."})
	check(g.maps.id == "house", "a door with only a message goes nowhere")
	# A villager's home: in by day, shut at night with its message.
	var said := []
	g.message.connect(func(text): said.append(text))
	var tome_door: Dictionary = MapManager.data("town").door_at(Vector2i(5, 6))
	g.go_to_map("town", Vector2i(5, 7), Vector2i.UP)
	g.hour = 19
	g.minute = 30
	g.use_door(tome_door)
	check(g.maps.id == "town" and not said.is_empty() and said.back() == tome_door.closed, "Tome's house is shut at 19:30 %s" % [said])
	g.hour = 8
	g.minute = 0
	g.use_door(tome_door)
	check(g.maps.id == "tome_house" and g.maps.pos == MapManager.cell_pos(Vector2i(4, 5)) and g.indoors(), "and open at 8:00")
	g.use_door(MapManager.data("tome_house").doors[0])
	check(g.maps.id == "town" and g.maps.pos == MapManager.cell_pos(Vector2i(5, 7)), "out again in front of her door")
	g.go_to_map("house", Vector2i(4, 5), Vector2i.UP)
	g.use_door(MapManager.data("house").doors[0])
	check(g.maps.id == "farm" and g.maps.pos == MapManager.cell_pos(Vector2i(4, 4)) and g.maps.facing == Vector2i.DOWN, "out of the house to the farm door")
	check(g.ticking(), "outside the clock runs again")
	g._process(1.0)
	check(g.time_text() != before, "time passes outside")
	# Arriving on a cell where a weed grew pushes it aside.
	g.farm.cell(Vector2i(30, 6)).obj = FarmGrid.Obj.WEED
	g.go_to_map("farm", Vector2i(30, 6), Vector2i.LEFT)
	check(g.farm.cell(Vector2i(30, 6)).obj == FarmGrid.Obj.NONE, "arrival cell cleared")
	# Night: wake at home, in the house by the futon.
	g.go_to_map("town", Vector2i(2, 10), Vector2i.RIGHT)
	g.end_day()
	var home: Array = MapManager.data("house").spawns.home
	check(g.maps.id == "house" and g.maps.pos == MapManager.cell_pos(home[0]), "a new day starts at home")
	# The saved part, and checks on it.
	g.maps.pos = Vector2(40.6, 50.2)
	var d: Dictionary = g.maps.to_dict()
	check(d == {"id": "house", "x": 41, "y": 50, "facing": [0, 1]}, "map save data %s" % d)
	check(MapManager.check_saved(d)[0] == "", "saved map checks")
	for bad in [{"id": "moon", "x": 1, "y": 1, "facing": [0, 1]}, {"id": "house", "x": 999, "y": 1, "facing": [0, 1]},
			{"id": "house", "x": 1, "y": 1, "facing": [1, 1]}, {"id": "house", "x": 1.5, "y": 1, "facing": [0, 1]}, "house"]:
		check(MapManager.check_saved(bad)[0] != "", "refused saved map %s" % str(bad))
	g.free()


## On the real Game: the futon sleeps, the farm door leads in, tools rest indoors.
func _bed_and_doors() -> void:
	var g: Node = root.get_node("Game")
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	var keep_save := SaveGame.snapshot()   # the slot, its backup and temp file
	g.new_game()
	actions.interact(Vector2i(4, 3))
	check(g.maps.id == "house" and g.maps.facing == Vector2i.UP, "using the farm house door goes in")
	var day: int = g.day
	var stamina: int = g.stamina
	g.select_tool(g.TOOLS.find("hoe"))
	actions.use_tool(Vector2i(3, 3), Vector2i.DOWN, 0)
	check(g.stamina == stamina, "no tool swings indoors")
	actions.interact(Vector2i(1, 2))
	check(g.day == day + 1 and g.maps.id == "house", "the futon sleeps (next day, still home)")
	actions.on_action("enter", Vector2i(4, 5), Vector2i.DOWN)
	check(g.maps.id == "farm", "walking into the house door goes out")
	# Sleeping wrote the real save slot: put it back.
	SaveGame.restore(keep_save)
	g.new_game()


## The village clinic: a small house east of the smithy, its door clear of the river lane, a
## path down to the road; inside a bed (no sleeping), the doctor's counter and the way out.
func _clinic() -> void:
	var t := MapManager.data("town")
	var d := t.door_at(Vector2i(33, 6))
	check(d.get("to", "") == "clinic" and d.get("shop", "") == "clinic", "the small house east of the smithy is the clinic")
	var house: Dictionary = t.prop_at(Vector2i(32, 5))
	check(house.get("kind", "") == "village_house" and Vector2i(house.cell).x + int(house.door) == 33, "the clinic house draws its door at the door cell")
	for y in [7, 8, 9]:
		check(t.tile(Vector2i(33, y)) == "path" and not t.is_solid(Vector2i(33, y)), "a path from the clinic door to the road (33, %d)" % y)
	check(Vector2i(t.spawns.clinic[0]) == Vector2i(33, 7) and t.spawns.clinic[1] == Vector2i.DOWN, "the town's clinic spawn is outside its door")
	check(Vector2i(house.cell).x > 10, "the clinic is far from the river lane on the west side")
	var c := MapManager.data("clinic")
	check(c.indoor and c.door_at(Vector2i(4, 6)).to == "town" and Vector2i(c.door_at(Vector2i(4, 6)).spawn) == Vector2i(33, 7), "clinic: indoors, door back to the village by its door")
	var bed: Vector2i = c.spawns.bed[0]
	check(not c.is_solid(bed) and c.prop_at(bed + Vector2i.LEFT).get("kind", "") == "futon" and c.prop_at(bed + Vector2i.LEFT).get("use", "") == "",
		"the bed spawn stands by the clinic bed, which doesn't sleep")
	check(not c.is_solid(c.spawns.keeper[0]) and not c.is_solid(c.spawns.counter[0]), "the doctor's spot and the counter spot are free")


## Through the clinic door while it is open, shut after hours; its bed is not the farmer's futon.
func _clinic_doors() -> void:
	var g: Node = root.get_node("Game")
	var actions: GDScript = load("res://scripts/farm_actions.gd")
	g.new_game()
	var said := []
	var note := func(t): said.append(t)
	g.message.connect(note)
	var door := MapManager.data("town").door_at(Vector2i(33, 6))
	g.go_to_map("town", Vector2i(33, 7), Vector2i.UP)
	g.hour = 20
	g.use_door(door)
	check(g.maps.id == "town" and said.size() > 0 and said.back().begins_with("Hinata Clinic is closed"), "the clinic is shut at 20:00 (%s)" % [said])
	g.hour = 10
	g.use_door(door)
	check(g.maps.id == "clinic", "an open clinic's door leads in")
	var day: int = g.day
	actions.interact(Vector2i(1, 2))
	check(g.day == day and g.maps.id == "clinic", "the clinic bed doesn't sleep")
	g.message.disconnect(note)
	g.new_game()


## The cells reachable on foot from `from` (not solid, inside the map).
func _walkable(m: MapData, from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var todo: Array = [from]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for o in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + o
			if m.in_bounds(n) and not seen.has(n) and not m.is_solid(n):
				seen[n] = true
				todo.append(n)
	return seen


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
