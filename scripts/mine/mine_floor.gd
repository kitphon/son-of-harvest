class_name MineFloor
extends RefCounted
## One floor of the mine, as pure rules (tested headless): where the rocks and soft spots lie
## on the cave map, what each one hides and where the hole down is. Made fresh on every
## entry from a seed (make), so the same seed, depth and season always lay out the same
## floor. Nothing here is saved: leaving goes back up, and the next visit is a new floor.
## MapManager asks it about solid cells and the hole (a door); the views draw it and redraw
## on `changed`, and light it with `light` and the farmer's `lantern`. In winter the shallow
## floors are frozen: frost on the ground, blocks of ice to break. Every landing floor has a
## rope lift by the ladder (`landing`, `lift`). Numbers and finds come
## from data/mine.json.

signal changed

var depth := 1
var seed := 0
var season := "spring"
var map: MapData
var rocks: Dictionary = {}     # cell -> {kind: "rock" / "big_rock" / "ice", hits: needed, done: taken, find: item or "" or "stairs"}
var soft: Dictionary = {}      # cell -> what digging finds there (item, "" or "stairs")
var stairs := Vector2i(-1, -1) # where the hole down is hidden
var open := false              # the hole is uncovered: walking into it goes down
var loose: Dictionary = {}     # cell -> a find left lying (no room for it), picked up with E
var frozen := false            # a winter floor (data/mine.json "winter")
var frost: Array[Vector2i] = []   # cells lying white with frost on a frozen floor (only a look)
var light := Color.WHITE       # the floor's light: the picture is multiplied by it
var lantern := {}              # the farmer's lantern: {radius (cells), soft, color}
var landing := false           # a landing floor: the rope lift stands at `lift` (data/mine.json "landings")
var lift := Vector2i(-1, -1)


## A new floor at `depth` on the cave `cave_map` in `season_id`, laid out from `floor_seed`.
static func make(rules: Dictionary, cave_map: MapData, floor_depth: int, season_id: String, floor_seed: int) -> MineFloor:
	var f := MineFloor.new()
	f.depth = maxi(floor_depth, 1)
	f.seed = floor_seed
	f.season = season_id
	f.map = cave_map
	f.frozen = is_frozen(rules, f.depth, season_id)
	f.light = light_at(rules, f.depth, season_id)
	var l: Dictionary = rules.get("light", {}).get("lantern", {})
	f.lantern = {"radius": float(l.get("radius", 0.0)), "soft": float(l.get("soft", 0.5)),
		"color": Color(str(l.get("color", "ffffff")))}
	if is_landing(rules, f.depth):
		f.landing = true
		var at: Array = rules.landings.get("cell", [0, 0])
		f.lift = Vector2i(int(at[0]), int(at[1]))
	f._lay_out(rules)
	return f


## The landing floors from data/mine.json, shallowest first.
static func landings(rules: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for d in rules.get("landings", {}).get("floors", []):
		if int(d) > 1 and not int(d) in out:
			out.append(int(d))
	out.sort()
	return out


## Is floor `floor_depth` a landing (a rope lift stands there)?
static func is_landing(rules: Dictionary, floor_depth: int) -> bool:
	return floor_depth in landings(rules)


## Is floor `floor_depth` frozen in `season_id`? Winter reaches down to the "winter" `to` floor.
static func is_frozen(rules: Dictionary, floor_depth: int, season_id: String) -> bool:
	var w: Dictionary = rules.get("winter", {})
	return season_id in w.get("seasons", []) and floor_depth <= int(w.get("to", 0))


## The light on floor `floor_depth`: the "light" depths blended between the two floors around
## it (held past the last), times the cold of a frozen floor.
static func light_at(rules: Dictionary, floor_depth: int, season_id := "") -> Color:
	var stops: Array = rules.get("light", {}).get("depths", [])
	var c := Color.WHITE
	if not stops.is_empty():
		c = Color(str(stops[0][1]))
		for i in range(1, stops.size()):
			var a: Array = stops[i - 1]
			var b: Array = stops[i]
			if floor_depth >= int(b[0]):
				c = Color(str(b[1]))
			elif floor_depth > int(a[0]):
				c = Color(str(a[1])).lerp(Color(str(b[1])), float(floor_depth - int(a[0])) / float(int(b[0]) - int(a[0])))
	if is_frozen(rules, floor_depth, season_id):
		c *= Color(str(rules.get("winter", {}).get("light", "ffffff")))
	return c


## The band of data/mine.json "floors" for a depth: the last one that starts at or above it.
static func band(rules: Dictionary, floor_depth: int) -> Dictionary:
	var out := {}
	for b in rules.get("floors", []):
		if floor_depth >= int(b.get("from", 1)):
			out = b
	return out


## Find -> weight for breaking `source` ("rock", "big_rock", "soft") at a depth in a season;
## "none" is the weight of finding nothing. Season factors multiply the finds they name.
static func odds(rules: Dictionary, floor_depth: int, season_id: String, source: String) -> Dictionary:
	var out := {}
	var factors: Dictionary = rules.get("seasons", {}).get(season_id, {})
	var finds: Dictionary = band(rules, floor_depth).get("finds", {}).get(source, {})
	for id in finds:
		var w := float(finds[id]) * float(factors.get(id, 1.0))
		if w > 0.0:
			out[id] = w
	return out


## The rucksack id of a find ("mine:<id>"); "" for nothing.
static func item_id(find: String) -> String:
	return "" if find == "" or find == "none" or find == "stairs" else "mine:" + find


func _lay_out(rules: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var b := band(rules, depth)
	var start: Vector2i = map.spawns.start[0]
	var safe := int(rules.get("safe_radius", 1))
	var free: Array[Vector2i] = []
	for y in map.h:
		for x in map.w:
			var c := Vector2i(x, y)
			if map.is_solid(c) or not map.door_at(c).is_empty() or c == lift:
				continue
			if absi(c.x - start.x) <= safe and absi(c.y - start.y) <= safe:
				continue
			free.append(c)
	# A fixed order to shuffle from: the seed alone decides the layout.
	for i in range(free.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := free[i]
		free[i] = free[j]
		free[j] = t
	var hits: Dictionary = b.get("hits", {})
	for kind in ["big_rock", "rock"]:
		var want := _count(b.get(kind + "s", [0, 0]), rng)
		for i in mini(want, free.size()):
			var c: Vector2i = free.pop_back()
			rocks[c] = {"kind": kind, "hits": maxi(int(hits.get(kind, 1)), 1), "done": 0,
				"find": _roll(odds(rules, depth, season, kind), rng)}
	for i in mini(_count(b.get("soft", [0, 0]), rng), free.size()):
		var c: Vector2i = free.pop_back()
		soft[c] = _roll(odds(rules, depth, season, "soft"), rng)
	# The hole down: under a soft spot or a rock far enough from the ladder.
	var st: Dictionary = rules.get("stairs", {})
	var far := int(st.get("min_distance", 0))
	var under_soft := rng.randf() < float(st.get("under_soft", 0.0))
	var spots: Array[Vector2i] = []
	for pool in ([soft, rocks] if under_soft else [rocks, soft]):
		for c in pool:
			if absi(c.x - start.x) + absi(c.y - start.y) >= far:
				spots.append(c)
		if not spots.is_empty():
			break
	spots.sort()   # dictionaries keep insertion order, but sort anyway: the pick is the seed's
	if spots.is_empty():
		return
	stairs = spots[rng.randi_range(0, spots.size() - 1)]
	if rocks.has(stairs):
		rocks[stairs].find = "stairs"
	else:
		soft[stairs] = "stairs"
	if frozen:
		_freeze(rules.get("winter", {}), free, rng)


## A frozen floor: blocks of ice on free cells (after the hole is placed, so it is never under
## the ice), then frost over a share of what is still open.
func _freeze(w: Dictionary, free: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	var finds := {}
	for id in w.get("finds", {}):
		if float(w.finds[id]) > 0.0:
			finds[id] = float(w.finds[id])
	for i in mini(_count(w.get("ice", [0, 0]), rng), free.size()):
		var c: Vector2i = free.pop_back()
		rocks[c] = {"kind": "ice", "hits": maxi(int(w.get("hits", 1)), 1), "done": 0, "find": _roll(finds, rng)}
	for i in mini(roundi(float(w.get("frost", 0.0)) * free.size()), free.size()):
		frost.append(free.pop_back())


static func _count(range_: Array, rng: RandomNumberGenerator) -> int:
	return rng.randi_range(int(range_[0]), int(range_[1])) if range_.size() == 2 else 0


static func _roll(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var id := Fishing.pick(weights, rng.randf())
	return "" if id == "none" else id


## Rocks block the way, and so do the open hole (walking into it goes down, like a door) and
## a landing's rope lift.
func is_solid(c: Vector2i) -> bool:
	return rocks.has(c) or (open and c == stairs) or (landing and c == lift)


## The open hole as a door down to the next floor, at the same ladder spot; {} elsewhere.
func door_at(c: Vector2i) -> Dictionary:
	if not open or c != stairs:
		return {}
	return {"cells": [c], "to": map.id, "spawn": map.spawns.start[0], "facing": map.spawns.start[1],
		"message": "", "gate": false, "shop": "", "down": true}


## The cells a tool's charge area covers from `origin` (FarmGrid's area rows), on the cave
## floor: walls and the map's edge cut it.
func area_cells(origin: Vector2i, facing: Vector2i, rows: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for o in FarmGrid.area_offsets(rows):
		var c := origin + FarmGrid.turn(o, facing)
		if map.in_bounds(c) and not map.is_solid(c):
			out.append(c)
	return out


## A hammer blow of `power` hits on `c`: {result: "none" (no rock), "tough" (still standing),
## "broke"; find: what it hid (an item id from data, "" or "stairs")}. The hole opens here.
func hit(c: Vector2i, power := 1) -> Dictionary:
	if not rocks.has(c):
		return {"result": "none", "find": ""}
	var r: Dictionary = rocks[c]
	r.done += maxi(power, 1)
	if r.done < r.hits:
		return {"result": "tough", "find": ""}
	rocks.erase(c)
	if r.find == "stairs":
		open = true
	changed.emit()
	return {"result": "broke", "find": r.find}


## The hoe on `c`: a soft spot is dug out ({result: "dug", find}); anywhere else "none".
func dig(c: Vector2i) -> Dictionary:
	if not soft.has(c):
		return {"result": "none", "find": ""}
	var find: String = soft[c]
	soft.erase(c)
	if find == "stairs":
		open = true
	changed.emit()
	return {"result": "dug", "find": find}


## A find with no room in the hands or the rucksack stays on its cell.
func leave(c: Vector2i, id: String) -> void:
	loose[c] = id
	changed.emit()


## Takes the find lying on `c` ("" when there is none).
func take(c: Vector2i) -> String:
	var id: String = loose.get(c, "")
	if id != "":
		loose.erase(c)
		changed.emit()
	return id
