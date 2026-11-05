class_name LitSpots
extends RefCounted
## Where the windows and lanterns that light up at night are, in map units (1 = one cell;
## x east, z south, y up). One layout for both views: the 3D worlds (FarmWorld, MapWorld) build
## their shoji pictures from it and NightLights draws the glow there; the flat view's NightView
## draws the same spots from above. A window is {key: picture, pos: centre, size: Vector2 (w, h),
## normal: Vector3 out of the wall}; a lantern is the centre of its fire box.

const FARM_FRONT := 3.6   # the farmhouse's front wall (z); the engawa fills 3.6 .. 4.0
const FARM_MID := 1.0 + (FARM_FRONT - 1.0) / 2.0   # the middle of its side wall (z)
const SOUTH := Vector3(0, 0, 1)   # the faces the camera sees: +z ...
const EAST := Vector3(1, 0, 0)    # ... and +x


static func spot(key: String, size: Vector2, pos: Vector3, normal: Vector3) -> Dictionary:
	return {"key": key, "pos": pos, "size": size, "normal": normal}


## The farmhouse: the shoji door over the door cell (4, 3), windows beside it and on the +x face.
static func farmhouse() -> Array[Dictionary]:
	return [
		spot("build:shoji_door", Vector2(0.9, 1.3), Vector3(4.5, 0.32 + 0.65, FARM_FRONT + 0.005), SOUTH),
		spot("build:shoji", Vector2(0.8, 0.6), Vector3(2.8, 1.2, FARM_FRONT + 0.005), SOUTH),
		spot("build:shoji", Vector2(0.8, 0.6), Vector3(6.2, 1.2, FARM_FRONT + 0.005), SOUTH),
		spot("build:shoji", Vector2(0.8, 0.6), Vector3(7.005, 1.2, FARM_MID), EAST),
	]


## The front wall (z) of a village house over footprint `r`.
static func village_front(r: Rect2) -> float:
	return r.end.y - 0.15


## A village house over footprint `r` (door cells from its left, a shop's noren door and a plain
## side door `side_door` cells from the left, -1 for none): the lit door (not under a noren),
## the side door and the windows between.
static func village_house(r: Rect2, door: int, noren: bool, side_door := -1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var back := r.position.y + 0.1
	var front := village_front(r)
	var mid_z := back + (front - back) / 2
	var dx := r.position.x + door + 0.5
	if not noren:
		out.append(spot("build:shoji_door", Vector2(0.85, 1.05), Vector3(dx, 0.55, front + 0.005), SOUTH))
	var sx := r.position.x + side_door + 0.5 if side_door >= 0 else -100.0
	if side_door >= 0:
		out.append(spot("build:shoji_door", Vector2(0.75, 1.0), Vector3(sx, 0.52, front + 0.005), SOUTH))
	for x in range(int(r.position.x), int(r.end.x)):
		if absf(x + 0.5 - dx) > 1.2 and absf(x + 0.5 - sx) > 0.9 and (x - int(r.position.x)) % 2 == 1:
			out.append(spot("build:shoji", Vector2(0.7, 0.5), Vector3(x + 0.5, 1.1, front + 0.005), SOUTH))
	out.append(spot("build:shoji", Vector2(0.7, 0.5), Vector3(r.end.x - 0.1 + 0.005, 1.1, mid_z), EAST))
	return out


## The fire box of a stone lantern standing at `mid` (the middle of its cell, on the ground).
static func lantern(mid: Vector3) -> Vector3:
	return mid + Vector3(0, 0.86, 0)


## Every lit window and lantern of a map's props: {windows, lamps}.
static func of_map(props: Array) -> Dictionary:
	var windows: Array[Dictionary] = []
	var lamps: Array[Dictionary] = []
	for p in props:
		var r := Rect2(Vector2(p.cell), Vector2(p.size))
		match str(p.kind):
			"village_house":
				windows.append_array(village_house(r, int(p.get("door", 1)), bool(p.get("noren", false)), int(p.get("side_door", -1))))
			"stone_lantern":
				lamps.append({"pos": lantern(Vector3(r.get_center().x, 0, r.get_center().y))})
	return {"windows": windows, "lamps": lamps}
