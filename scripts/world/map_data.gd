class_name MapData
extends RefCounted
## One map from data/maps/<id>.json: its size, ground, solid cells, props (furniture,
## buildings), doors and spawn spots. Pure data and rules, no drawing (MapView / MapWorld
## draw it). The farm's file only adds doors and spawns: its ground and buildings are the
## FarmGrid's (`farm` is true).
##
## A door is a list of cells (solid ones, or cells just off the map edge for a walk-off exit).
## Walking into one, or using it, goes to `to` at `spawn` facing `facing`; a door without `to`
## only shows its `message` (a locked house). A door with `shop` (data/shops.json) is shut
## outside that shop's hours; one with `hours` ["H:MM", "H:MM"] (a villager's home) is open
## from the first time until the second and shows its `closed` message otherwise.

const FACINGS := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT}

var id := ""
var name := ""
var w := 0
var h := 0
var farm := false          # ground, solids and objects come from FarmGrid
var indoor := false        # the clock stands still in here (DESIGN: time stops in buildings)
var sheltered := false     # under a roof of rock (the mine): no weather, but the clock runs
var ambient := "outdoor"   # which ambient rules apply (data/sfx.json "places")
var light = null           # a fixed Color for the room, or null for the day / night light
var background := Color("8fc6e8")
var tiles: Array[String] = []          # w * h ground kinds, row by row
var steps: Array[String] = []          # w * h footstep kinds ("" = by the ground)
var _solid: Array[bool] = []
var props: Array[Dictionary] = []      # {kind, cell, size, use, ...the rest from the file}
var doors: Array[Dictionary] = []      # {cells: Array[Vector2i], to, spawn, facing, message, gate, shop, hours?, closed?}
var spawns: Dictionary = {}            # name -> [cell, facing]


## [error, MapData]: the error is "" when the file's data is usable.
static func parse(d: Variant) -> Array:
	var m := MapData.new()
	var err := m._read(d)
	return [err, m if err == "" else null]


func _read(d: Variant) -> String:
	if not d is Dictionary:
		return "not an object"
	id = str(d.get("id", ""))
	name = str(d.get("name", id))
	var size = d.get("size")
	if id == "" or not size is Array or size.size() != 2 or int(size[0]) < 1 or int(size[1]) < 1:
		return "needs an id and a size"
	w = int(size[0])
	h = int(size[1])
	farm = bool(d.get("farm", false))
	indoor = bool(d.get("indoor", false))
	sheltered = bool(d.get("sheltered", indoor))
	ambient = str(d.get("ambient", "indoor" if indoor else "outdoor"))
	if d.has("light"):
		light = Color(str(d.light))
	if d.has("background"):
		background = Color(str(d.background))
	for i in w * h:
		tiles.append("grass")
		steps.append("")
		_solid.append(false)
	if not farm:
		var err := _read_ground(d)
		if err != "":
			return err
	for p in d.get("props", []):
		var cell = _cell(p.get("cell"))
		var psize = _cell(p.get("size", [1, 1]))
		if cell == null or psize == null or psize.x < 1 or psize.y < 1 \
				or not in_bounds(cell) or not in_bounds(cell + psize - Vector2i.ONE):
			return "prop %s is off the map" % str(p.get("kind", "?"))
		var prop: Dictionary = p.duplicate()
		prop.cell = cell
		prop.size = psize
		# Props block their whole footprint unless they name the blocking cells (a torii's posts).
		var blocks: Array = p.get("blocks", []).duplicate()
		if not p.has("blocks") and bool(p.get("solid", true)):
			for y in psize.y:
				for x in psize.x:
					blocks.append([x, y])
		for b in blocks:
			var o = _cell(b)
			if o == null:
				return "prop %s has a broken block" % prop.kind
			_solid[(cell.y + o.y) * w + cell.x + o.x] = true
		props.append(prop)
	for door in d.get("doors", []):
		var cells: Array[Vector2i] = []
		for c in door.get("cells", []):
			var v = _cell(c)
			if v == null:
				return "a door has a broken cell"
			cells.append(v)
		if cells.is_empty():
			return "a door has no cells"
		var out := {"cells": cells, "to": str(door.get("to", "")), "message": str(door.get("message", "")),
			"gate": bool(door.get("gate", false)), "shop": str(door.get("shop", ""))}
		if out.to != "":
			out.spawn = _cell(door.get("spawn"))
			out.facing = FACINGS.get(door.get("facing", "down"))
			if out.spawn == null or out.facing == null:
				return "door to %s needs a spawn cell and a facing" % out.to
		elif out.message == "":
			return "a door needs a target map or a message"
		if door.has("hours"):
			var hours = door.hours
			var open := DayPlan.minute_of(hours[0]) if hours is Array and hours.size() == 2 else -1
			var close := DayPlan.minute_of(hours[1]) if open >= 0 else -1
			if close <= open or str(door.get("closed", "")) == "":
				return "door to %s needs hours [\"H:MM\", \"H:MM\"] in order and a closed message" % out.to
			out.hours = [open, close]
			out.closed = str(door.closed)
		doors.append(out)
	var sp = d.get("spawns", {})
	if not sp is Dictionary or not sp.has("start"):
		return "needs a start spawn"
	for key in sp:
		var cell = _cell(sp[key][0]) if sp[key] is Array and sp[key].size() == 2 else null
		var face = FACINGS.get(sp[key][1]) if cell != null else null
		if cell == null or face == null or not in_bounds(cell):
			return "spawn %s is broken" % key
		spawns[key] = [cell, face]
	return ""


func _read_ground(d: Dictionary) -> String:
	var legend = d.get("legend")
	var rows = d.get("ground")
	if not legend is Dictionary or not rows is Array or rows.size() != h:
		return "needs a legend and %d ground rows" % h
	for y in h:
		var row := str(rows[y])
		if row.length() != w:
			return "ground row %d is not %d long" % [y, w]
		for x in w:
			var key: Variant = legend.get(row[x])
			if not key is Dictionary or not key.has("tile"):
				return "ground '%s' is not in the legend" % row[x]
			tiles[y * w + x] = str(key.tile)
			steps[y * w + x] = str(key.get("step", ""))
			_solid[y * w + x] = bool(key.get("solid", false))
	return ""


static func _cell(v: Variant) -> Variant:
	if not v is Array or v.size() != 2:
		return null
	for n in v:
		if not (n is int or n is float) or n != floorf(n):
			return null
	return Vector2i(int(v[0]), int(v[1]))


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h


## Walls, water, solid props and everything off the map (the farm asks FarmGrid instead).
func is_solid(c: Vector2i) -> bool:
	return not in_bounds(c) or _solid[c.y * w + c.x]


func tile(c: Vector2i) -> String:
	return tiles[c.y * w + c.x] if in_bounds(c) else ""


## The footstep sound kind on a cell, "" to let the ground decide (Sfx.ground).
func step(c: Vector2i) -> String:
	return steps[c.y * w + c.x] if in_bounds(c) else ""


## Is `door` open at minute `t` of the game day (DayPlan.day_minute)? Doors without hours always are.
static func door_open(door: Dictionary, t: float) -> bool:
	return not door.has("hours") or (t >= door.hours[0] and t < door.hours[1])


func door_at(c: Vector2i) -> Dictionary:
	for door in doors:
		if c in door.cells:
			return door
	return {}


## Fence cells the farm leaves open for its gate doors.
func gate_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for door in doors:
		if door.gate:
			out.append_array(door.cells)
	return out


func prop_at(c: Vector2i) -> Dictionary:
	for p in props:
		if Rect2i(p.cell, p.size).has_point(c):
			return p
	return {}
