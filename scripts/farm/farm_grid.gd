class_name FarmGrid
extends RefCounted
## The farm as a grid of cells. Pure logic, no drawing (FarmView draws it),
## so the same rules work for a 2D or a 3D view later.

signal cells_changed

const W := 32
const H := 20

enum Obj { NONE, ROCK, BRANCH, WEED, STUMP }

## Which tool clears an obstacle and how many hits it takes.
const CLEAR_RULES := {
	Obj.WEED: {"tool": "sickle", "hits": 1},
	Obj.ROCK: {"tool": "hammer", "hits": 1},
	Obj.BRANCH: {"tool": "axe", "hits": 1},
	Obj.STUMP: {"tool": "axe", "hits": 4},
}

const CHEST := Vector2i(7, 3)   # the storage chest, right of the house
const COOP := Rect2i(13, 1, 5, 3)    # the chicken coop's footprint, its door in the front middle
const COOP_DOOR := Vector2i(15, 3)
const WEED_CHANCE := 0.01   # per empty cell per night, not in winter
const STORM_LOSS := 1.0 / 16.0

var crops: Dictionary
var cells: Array = []        # W * H dictionaries, row by row
var fixed: Dictionary = {}   # Vector2i -> "house" / "door" / "chest" / "bin" / "stand" / "pond" / "fence"
var items: Dictionary = {}   # Vector2i -> item id lying on the ground (put down or thrown)


func _init(crop_data: Dictionary) -> void:
	crops = crop_data
	for i in W * H:
		cells.append(_empty_cell())


func _empty_cell() -> Dictionary:
	return {"tilled": false, "wet": false, "obj": Obj.NONE, "crop": "", "stage": 0, "days": 0, "hits": 0}


## New-game layout: buildings along the top, a field full of debris below.
func generate(rng: RandomNumberGenerator) -> void:
	for x in W:
		fixed[Vector2i(x, 0)] = "fence"
		fixed[Vector2i(x, H - 1)] = "fence"
	for y in H:
		fixed[Vector2i(0, y)] = "fence"
		fixed[Vector2i(W - 1, y)] = "fence"
	for y in range(1, 4):
		for x in range(2, 7):
			fixed[Vector2i(x, y)] = "house"
	fixed[Vector2i(4, 3)] = "door"
	fixed[CHEST] = "chest"
	fixed[Vector2i(8, 3)] = "bin"
	fixed[Vector2i(10, 3)] = "stand"
	_place_coop()
	for y in range(2, 5):
		for x in range(25, 29):
			fixed[Vector2i(x, y)] = "pond"

	for y in range(7, H - 1):
		for x in range(1, W - 1):
			if rng.randf() >= 0.15:
				continue
			var r := rng.randf()
			var obj := Obj.WEED
			if r > 0.95:
				obj = Obj.STUMP
			elif r > 0.75:
				obj = Obj.BRANCH
			elif r > 0.5:
				obj = Obj.ROCK
			cell(Vector2i(x, y)).obj = obj
	cells_changed.emit()


## Fixed spots added after the first saves (the storage chest by the house): a farm loaded
## from an older save gets them, on a cleared cell, when their cell is free.
func add_missing_fixed() -> void:
	if not "coop" in fixed.values():
		_place_coop()
		cells_changed.emit()
	if "chest" in fixed.values() or fixed_at(CHEST) != "":
		return
	cells[CHEST.y * W + CHEST.x] = _empty_cell()
	fixed[CHEST] = "chest"
	cells_changed.emit()


## The chicken coop (cleared ground, then its cells; saves from before animals get it too).
func _place_coop() -> void:
	for y in range(COOP.position.y, COOP.end.y):
		for x in range(COOP.position.x, COOP.end.x):
			var c := Vector2i(x, y)
			cells[y * W + x] = _empty_cell()
			items.erase(c)
			fixed[c] = "coop"
	fixed[COOP_DOOR] = "coop_door"


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H


func cell(c: Vector2i) -> Dictionary:
	return cells[c.y * W + c.x]


func fixed_at(c: Vector2i) -> String:
	return fixed.get(c, "")


func is_solid(c: Vector2i) -> bool:
	if not in_bounds(c) or fixed_at(c) != "":
		return true
	return cell(c).obj != Obj.NONE


func can_farm(c: Vector2i) -> bool:
	return in_bounds(c) and fixed_at(c) == ""


func till(c: Vector2i) -> bool:
	if not can_farm(c):
		return false
	var d := cell(c)
	if d.obj != Obj.NONE or d.crop != "" or d.tilled or items.has(c):
		return false
	d.tilled = true
	cells_changed.emit()
	return true


func water_cell(c: Vector2i) -> bool:
	if not can_farm(c):
		return false
	var d := cell(c)
	if not d.tilled or d.wet:
		return false
	d.wet = true
	cells_changed.emit()
	return true


## One seed bag sows the 3 x 3 cells around `center`; returns how many took a seed.
func sow(center: Vector2i, crop_id: String, season: String) -> int:
	if not (season in crops[crop_id].seasons):
		return 0
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c := center + Vector2i(dx, dy)
			if not can_farm(c):
				continue
			var d := cell(c)
			if d.tilled and d.crop == "" and d.obj == Obj.NONE and not items.has(c):
				d.crop = crop_id
				d.stage = 0
				d.days = 0
				n += 1
	if n > 0:
		cells_changed.emit()
	return n


func ripe_stage(crop_id: String) -> int:
	return crops[crop_id].stage_days.size()


func is_ripe(c: Vector2i) -> bool:
	if not can_farm(c):
		return false
	var d := cell(c)
	return d.crop != "" and d.stage >= ripe_stage(d.crop)


## Returns the crop id picked ("" if nothing was ripe). Regrowing crops drop back a stage.
func harvest(c: Vector2i) -> String:
	if not is_ripe(c):
		return ""
	var d := cell(c)
	var id: String = d.crop
	var regrow := int(crops[id].get("regrow_stage", -1))
	if regrow >= 0:
		d.stage = regrow
	else:
		d.crop = ""
		d.stage = 0
	d.days = 0
	cells_changed.emit()
	return id


## A swing of sickle / hammer / axe; `power` hits at once (a charged swing).
## Returns 0 nothing, 1 a hit, 2 cleared.
func hit(c: Vector2i, tool: String, power := 1) -> int:
	if not can_farm(c):
		return 0
	var d := cell(c)
	if not CLEAR_RULES.has(d.obj):
		return 0
	var rule: Dictionary = CLEAR_RULES[d.obj]
	if rule.tool != tool:
		return 0
	d.hits += maxi(power, 1)
	if d.hits < rule.hits:
		return 1
	d.obj = Obj.NONE
	d.hits = 0
	cells_changed.emit()
	return 2


# --- items on the ground ------------------------------------------------------

func item_at(c: Vector2i) -> String:
	return items.get(c, "")


## An item can lie on a farm cell with nothing on it: no obstacle, crop or other item.
## Items don't block walking, so a dropped one never traps the farmer.
func can_place(c: Vector2i) -> bool:
	return can_farm(c) and cell(c).obj == Obj.NONE and cell(c).crop == "" and not items.has(c)


func place_item(c: Vector2i, id: String) -> bool:
	if id == "" or not can_place(c):
		return false
	items[c] = id
	cells_changed.emit()
	return true


## Picks up the item on `c`; returns its id ("" if none).
func take_item_at(c: Vector2i) -> String:
	var id: String = items.get(c, "")
	if id != "":
		items.erase(c)
		cells_changed.emit()
	return id


## Where an item thrown from `origin` towards `facing` ends up, up to `reach` cells ahead.
## It flies over crops and other items; a fixed cell in `ship_into` catches it ("ship"), one
## in `lost_in` swallows it ("lost"); anything else solid (building, fence, obstacle, the
## edge) stops it and it drops on the farthest free cell before ("land"). With no free cell
## on the way the throw doesn't happen ("blocked"). Returns {result, cell}.
func throw_target(origin: Vector2i, facing: Vector2i, reach: int, ship_into: Array, lost_in: Array) -> Dictionary:
	var landing := origin
	for i in range(1, reach + 1):
		var c := origin + facing * i
		var f := fixed_at(c)
		if f in ship_into:
			return {"result": "ship", "cell": c}
		if f in lost_in:
			return {"result": "lost", "cell": c}
		if is_solid(c):
			break
		if can_place(c):
			landing = c
	if landing == origin:
		return {"result": "blocked", "cell": origin}
	return {"result": "land", "cell": landing}


## A tool area from data/tools.json (rows of text, drawn facing down: '@' the farmer, '#' a
## cell, rows below '@' ahead) as offsets Vector2i(side, ahead), in the order written.
static func area_offsets(rows: Array) -> Array[Vector2i]:
	var me := Vector2i(-1, -1)
	for y in rows.size():
		var x := String(rows[y]).find("@")
		if x >= 0:
			me = Vector2i(x, y)
	var out: Array[Vector2i] = []
	if me.x < 0:
		return out
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			if row[x] == "#":
				out.append(Vector2i(x, y) - me)
	return out


## An offset from area_offsets turned to the way the farmer faces: "ahead" goes along
## `facing`, "side" along facing turned a quarter (so facing down keeps the drawing as is).
static func turn(offset: Vector2i, facing: Vector2i) -> Vector2i:
	return facing * offset.y + Vector2i(facing.y, -facing.x) * offset.x


## The farm cells a tool area covers from the farmer's cell; cells off the grid and on
## buildings / the pond / the fence are left out.
func area_cells(origin: Vector2i, facing: Vector2i, rows: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for o in area_offsets(rows):
		var c := origin + turn(o, facing)
		if can_farm(c):
			out.append(c)
	return out


## Everything the farm holds as plain JSON-safe data (SaveGame writes it).
## The fixed cells are saved too, so later changes to the layout (extensions) keep.
func to_dict() -> Dictionary:
	var rows := []
	for d in cells:
		rows.append(d.duplicate())
	var spots := []
	for c in fixed:
		spots.append([c.x, c.y, fixed[c]])
	var lying := []
	for c in items:
		lying.append([c.x, c.y, items[c]])
	return {"w": W, "h": H, "cells": rows, "fixed": spots, "items": lying}


## Puts a saved farm back in place (views keep their reference to this grid).
## Returns "" or what was wrong; on a problem nothing changes.
func from_dict(data: Dictionary) -> String:
	if SaveGame.whole(data.get("w"), W, W) == null or SaveGame.whole(data.get("h"), H, H) == null:
		return "The saved farm has another size"
	var rows = data.get("cells")
	if not rows is Array or rows.size() != W * H:
		return "The saved farm cells are missing"
	var new_cells := []
	for i in rows.size():
		var d = _cell_from(rows[i])
		if d == null:
			return "Saved farm cell %d,%d is broken" % [i % W, i / W]
		new_cells.append(d)
	var spots = data.get("fixed")
	if not spots is Array:
		return "The saved farm buildings are missing"
	var new_fixed := {}
	for s in spots:
		if not s is Array or s.size() != 3 or not s[2] is String or s[2] == "":
			return "A saved farm building is broken"
		var x = SaveGame.whole(s[0], 0, W - 1)
		var y = SaveGame.whole(s[1], 0, H - 1)
		if x == null or y == null:
			return "A saved farm building is broken"
		new_fixed[Vector2i(x, y)] = s[2]
	# Saves from before holding have no items on the ground.
	var lying = data.get("items", [])
	if not lying is Array:
		return "The saved items on the ground are broken"
	var new_items := {}
	for s in lying:
		if not s is Array or s.size() != 3 or not s[2] is String or s[2] == "":
			return "A saved item on the ground is broken"
		var x = SaveGame.whole(s[0], 0, W - 1)
		var y = SaveGame.whole(s[1], 0, H - 1)
		if x == null or y == null or new_items.has(Vector2i(x, y)):
			return "A saved item on the ground is broken"
		new_items[Vector2i(x, y)] = s[2]
	cells = new_cells
	fixed = new_fixed
	items = new_items
	cells_changed.emit()
	return ""


func _cell_from(v: Variant) -> Variant:
	if not v is Dictionary or not v.get("tilled") is bool or not v.get("wet") is bool:
		return null
	var crop = v.get("crop")
	if not crop is String or (crop != "" and not crops.has(crop)):
		return null
	var d := {
		"tilled": v.tilled, "wet": v.wet, "crop": crop,
		"obj": SaveGame.whole(v.get("obj"), 0, Obj.size() - 1),
		"stage": SaveGame.whole(v.get("stage"), 0, ripe_stage(crop) if crop != "" else 0),
		"days": SaveGame.whole(v.get("days"), 0, 999),
		"hits": SaveGame.whole(v.get("hits"), 0, 99),
	}
	if null in d.values():
		return null
	return d


## The night: growth on watered cells, out-of-season crops wither, weeds, storm damage,
## then today's rain waters the field.
func day_end(season: String, weather: String, rng: RandomNumberGenerator) -> void:
	for i in cells.size():
		var pos := Vector2i(i % W, i / W)
		if fixed_at(pos) != "":
			continue
		var d: Dictionary = cells[i]
		d.hits = 0
		if d.crop != "":
			var data: Dictionary = crops[d.crop]
			if not (season in data.seasons):
				d.crop = ""
				d.stage = 0
				d.days = 0
			elif d.wet and d.stage < data.stage_days.size():
				d.days += 1
				if d.days >= int(data.stage_days[d.stage]):
					d.stage += 1
					d.days = 0
			if d.crop != "" and weather == "storm" and rng.randf() < STORM_LOSS:
				d.crop = ""
				d.stage = 0
				d.days = 0
		elif d.obj == Obj.NONE and not items.has(pos) and season != "winter" and rng.randf() < WEED_CHANCE:
			d.obj = Obj.WEED
			d.tilled = false
		d.wet = d.tilled and weather == "rain"
	cells_changed.emit()
