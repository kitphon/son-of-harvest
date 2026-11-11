class_name LitSpots
extends RefCounted
## Where the windows and lanterns that light up at night are, in map units (1 = one cell;
## x east, z south, y up). One layout for both views: the 3D worlds (FarmWorld, MapWorld) build
## their shoji pictures from it and NightLights draws the glow there; the flat view's NightView
## draws the same spots from above. A window is {key: picture, pos: centre, size: Vector2 (w, h),
## normal: Vector3 out of the wall}; a lantern is the centre of its fire box.

const FARM_FRONT := 3.6   # the farmhouse's front wall (z); the engawa fills 3.6 .. 4.0
const FARM_MID := 1.0 + (FARM_FRONT - 1.0) / 2.0   # the middle of its side wall (z)
## The greenhouse's walls and roof (GreenhouseProps builds by these): the walls' top, the ridge
## above it, the glass roof past the walls all round.
const GREENHOUSE_EAVE := 1.5
const GREENHOUSE_RISE := 0.7   # a low roof, about 27°
const GREENHOUSE_OVER := 0.12
const SOUTH := Vector3(0, 0, 1)   # the faces the camera sees: +z ...
const EAST := Vector3(1, 0, 0)    # ... and +x


static func spot(key: String, size: Vector2, pos: Vector3, normal: Vector3) -> Dictionary:
	return {"key": key, "pos": pos, "size": size, "normal": normal}


## The farmhouse: the shoji door over the door cell (4, 3), windows beside it and on the +x face.
## Each knows its wall's ends (`span`, see wall_span) for the stone lanterns' wash.
static func farmhouse() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		spot("build:shoji_door", Vector2(0.9, 1.3), Vector3(4.5, 0.32 + 0.65, FARM_FRONT + 0.005), SOUTH),
		spot("build:shoji", Vector2(0.8, 0.6), Vector3(2.8, 1.2, FARM_FRONT + 0.005), SOUTH),
		spot("build:shoji", Vector2(0.8, 0.6), Vector3(6.2, 1.2, FARM_FRONT + 0.005), SOUTH),
		spot("build:shoji", Vector2(0.8, 0.6), Vector3(7.005, 1.2, FARM_MID), EAST),
	]
	for s in out:
		s.span = wall_span(s, Rect2(2.0, 1.0, 5.0, FARM_FRONT - 1.0))
	return out


## The greenhouse (FarmGrid.GREENHOUSE, once built): a paper lantern kept inside by the door lights
## the glass near it, a patch of the front wall left of the door and one of the +x gable wall
## (GreenhouseProps' walls, glazed from the skirting at 0.5 to the eaves at 1.5). The pane picture
## `build:glass_lit` is the glazing lit from within, brightest in the middle, so the panes read lit
## and not a window; small patches, about a shoji window's size, so the light stays soft.
static func greenhouse() -> Array[Dictionary]:
	var r := Rect2(FarmGrid.GREENHOUSE)
	var body := Rect2(r.position.x + 0.1, r.position.y + 0.1, r.size.x - 0.2, r.size.y - 0.2)
	var out: Array[Dictionary] = [
		spot("build:glass_lit", Vector2(0.9, 0.7), Vector3(FarmGrid.GREENHOUSE_DOOR.x - 0.75, 1.0, body.end.y + 0.005), SOUTH),
		spot("build:glass_lit", Vector2(0.9, 0.7), Vector3(body.end.x + 0.005, 1.0, body.end.y - 0.9), EAST),
	]
	for s in out:
		s.span = wall_span(s, body)
	# The flat view draws the greenhouse's front wall from above as a band of glass over the board
	# skirting (FarmView._draw_greenhouse), not on its footprint line as the houses' walls: its
	# strip goes on the glass (`flat_z`, the strip's lower edge, map units).
	out[0].flat_z = flat_glass_z()
	# Its +x patch is on the gable wall, which the flat view does not draw (only the roof's edge
	# shows there): no strip or halo for it (`flat_hide`); its pool on the ground stays.
	out[1].flat_hide = true
	return out


## Where the flat view's strip of the greenhouse's lit front glass ends (map units, z): one pixel
## above the board skirting, in the band of glass FarmView._draw_greenhouse draws over it.
static func flat_glass_z() -> float:
	var foot := float(FarmGrid.GREENHOUSE.end.y) * FarmView.T
	return (foot - FarmView.GREENHOUSE_SKIRT - 1.0) / FarmView.T


## The paper lantern hanging inside the greenhouse by the door (GreenhouseProps._lantern): the
## middle of its washi, behind the lit patch of the front glass.
static func greenhouse_lantern() -> Vector3:
	return Vector3(FarmGrid.GREENHOUSE_DOOR.x - 0.75, 1.08, FarmGrid.GREENHOUSE.end.y - 0.1 - 0.45)


## data/light.json "roof_glow" from the Game autoload ({} without it: the defaults). Looked up by
## name, as this class is compiled by tests that run without the autoloads.
static func roof_rules() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var game: Node = tree.root.get_node_or_null("Game") if tree != null else null
	return game.light_data().get("roof_glow", {}) if game != null else {}


## The lantern's glow on the greenhouse's glass roof, seen from outside at night (NightLights in
## 3D, NightView flat): a soft disc on each slope round the point over the lantern, `radius` along
## the slope either way, the front slope's right over it and the back slope's by the ridge, at
## `back` of the strength (farther from the lantern), cut to the glass (both from data/light.json
## "roof_glow"). Each {slope: 1 front /
## -1 back, at: the disc's middle (on the glass), centre: Vector2 (x, t: along the slope down from
## the ridge), length: the slope's, radius, share (of the strength), corners (4, on the glass, top
## left first) and uvs (-1..1 from the middle, `radius` to the edge), normal (out of the slope),
## own: the lantern (inside its building's box)}. GreenhouseProps builds its roof by the same numbers.
static func greenhouse_roof(rules: Variant = null) -> Array[Dictionary]:
	if rules == null:
		rules = roof_rules()
	var radius := maxf(float(rules.get("radius", 1.7)), 0.1)
	var back := float(rules.get("back", 0.5))
	var r := Rect2(FarmGrid.GREENHOUSE)
	var front := r.end.y - 0.1
	var depth := r.size.y - 0.2
	var mid_z := front - depth / 2
	var tilt := atan2(GREENHOUSE_RISE, depth / 2)
	var length := (depth / 2 + GREENHOUSE_OVER) / cos(tilt)
	var top := GREENHOUSE_EAVE + GREENHOUSE_RISE + 0.03   # the glass's middle at the ridge
	var lamp := greenhouse_lantern()
	var x_ends := Vector2(r.position.x + 0.1 - GREENHOUSE_OVER + 0.03, r.end.x - 0.1 + GREENHOUSE_OVER - 0.03)
	var t_ends := Vector2(0.06, length - 0.04)
	var out: Array[Dictionary] = []
	for s in [1.0, -1.0]:
		var normal := Vector3(0, cos(tilt), s * sin(tilt))
		var on := func(x: float, t: float) -> Vector3:
			return Vector3(x, top - t * sin(tilt), mid_z + s * t * cos(tilt)) + normal * 0.03
		var c := Vector2(lamp.x, clampf((lamp.z - mid_z) / cos(tilt), t_ends.x, t_ends.y) if s > 0.0 else 0.3)
		var x0 := maxf(c.x - radius, x_ends.x)
		var x1 := minf(c.x + radius, x_ends.y)
		var t0 := maxf(c.y - radius, t_ends.x)
		var t1 := minf(c.y + radius, t_ends.y)
		var corners: Array[Vector3] = []
		var uvs := PackedVector2Array()
		for p in [Vector2(x0, t0), Vector2(x1, t0), Vector2(x1, t1), Vector2(x0, t1)]:
			corners.append(on.call(p.x, p.y))
			uvs.append((p - c) / radius)
		out.append({"slope": int(s), "at": on.call(c.x, c.y), "centre": c, "length": length, "radius": radius,
			"share": 1.0 if s > 0.0 else back, "corners": corners, "uvs": uvs, "normal": normal, "own": lamp})
	return out


## Every lit window of the farm: the farmhouse's, and the greenhouse's once it is in `built`
## (Game.house_built).
static func farm(built: Array) -> Array[Dictionary]:
	var out := farmhouse()
	if "greenhouse" in built:
		out.append_array(greenhouse())
	return out


## The front wall (z) of a village house over footprint `r`.
static func village_front(r: Rect2) -> float:
	return r.end.y - 0.15


## How far the upper storey of a two-storey village house stands in from the walls below
## (its pent roof fills the gap), how high its walls start and end, and its windows' middle.
const UPPER_INSET := 0.3
const UPPER_FLOOR := 1.915   # where the pent roof meets the upper wall
const UPPER_TOP := 2.9
const UPPER_WINDOW := 2.2   # under the main eave seen from the camera, over the pent roof


## A village house's look, from its map prop: `roof` gable or hip, `storeys` 1 or 2, `wall`
## plaster (white over a dark board skirt), yakisugi (charred boards up to a plaster band) or
## timber (earthen plaster between exposed posts and rails). Unset fields take the plain look.
static func village_style(p: Dictionary) -> Dictionary:
	return {
		"roof": str(p.get("roof", "gable")),
		"storeys": clampi(int(p.get("storeys", 1)), 1, 2),
		"wall": str(p.get("wall", "plaster")),
	}


## The walls of a village house: the soffit height at the front eave (the walls go up to it:
## eaves 0.35 out, 1.45 high, rising 0.5 a unit), the timber look's skirt top and rail height,
## and the yakisugi look's plaster band under the eaves.
const VILLAGE_WALL := 1.45 + 0.35 * 0.5
const TIMBER_SKIRT := 0.35
const TIMBER_RAIL := 1.42
const YAKISUGI_BAND := 0.22
const RAIL := 0.07       # the rails' and the front beam's height
const POST_CUT := 0.07   # half a front post (0.1 wide) and a little: a wall's warm light keeps off it


## A village house's walls over footprint `r` (x / z): in from the sides and the back by 0.1, to
## the front wall.
static func village_body(r: Rect2) -> Rect2:
	return Rect2(r.position.x + 0.1, r.position.y + 0.1, r.size.x - 0.2, village_front(r) - r.position.y - 0.1)


## The x of the posts on the front of walls `body` in `finish` (MapWorld._house_walls): the
## corners and the middle (an upper floor's middle only when wider than 4); the timber look one at
## every cell's edge.
static func front_posts(body: Rect2, finish: String, skirt: bool) -> Array[float]:
	var posts: Array[float] = [body.position.x, body.end.x]
	if finish == "timber":
		for x in range(int(ceil(body.position.x)), int(floor(body.end.x)) + 1):
			if x > body.position.x + 0.3 and x < body.end.x - 0.3:
				posts.append(float(x))
	elif skirt or body.size.x > 4.0:
		posts.append(body.get_center().x)
	return posts


## The wall material round a window that is not plaster, for its own warm light at night
## (NightLights.finish_wash): {kind: "earth" (the timber look's earthen plaster) or "board" (the
## yakisugi look's charred boards), bands: the heights it covers clear of the rails and the beam};
## {} for plaster (the pale wash's).
static func wall_look(finish: String, base: float, top: float) -> Dictionary:
	match finish:
		"yakisugi":
			return {"kind": "board", "bands": [Vector2(base, top - YAKISUGI_BAND - RAIL / 2)]}
		"timber":
			return {"kind": "earth", "bands": [Vector2(TIMBER_SKIRT, TIMBER_RAIL - RAIL / 2),
				Vector2(TIMBER_RAIL + RAIL / 2, top - RAIL)]}
		"upper_timber":
			return {"kind": "earth", "bands": [Vector2(base, top - RAIL)]}
	return {}


## Adds to window `s` on walls `body` (from `base` to `top`, in `finish`) what its wall's own warm
## light needs (see wall_look): `finish` (the kind), `bands`, `span` (the wall's ends along it from
## the window's middle, in NightLights's `right` direction, in from the side's corner posts) and
## `posts` (the front posts' widths along it, Vector2 from / to).
## A plaster window gets its wall's `span` only (the stone lanterns' wash needs it too).
static func _dress(s: Dictionary, finish: String, body: Rect2, base: float, top: float, skirt: bool) -> Dictionary:
	s.span = wall_span(s, body)
	var look := wall_look(finish, base, top)
	if look.is_empty():
		return s
	var at: Vector3 = s.pos
	var posts: Array[Vector2] = []
	if s.normal == SOUTH:
		for x in front_posts(body, finish, skirt):
			posts.append(Vector2(x - at.x - POST_CUT, x - at.x + POST_CUT))
	s.finish = look.kind
	s.bands = look.bands
	s.posts = posts
	return s


## The ends of window `s`'s wall over walls `body` (x / z), along NightLights's `right` direction
## from the window's middle: a front wall's corners; a side wall's in from its corner posts.
static func wall_span(s: Dictionary, body: Rect2) -> Vector2:
	var at: Vector3 = s.pos
	if s.normal == SOUTH:
		return Vector2(body.position.x - at.x, body.end.x - at.x)
	var right: Vector3 = Vector3.UP.cross(s.normal).normalized()
	var a: float = (Vector3(at.x, at.y, body.position.y) - at).dot(right)
	var b: float = (Vector3(at.x, at.y, body.end.y) - at).dot(right)
	return Vector2(minf(a, b) + 0.08, maxf(a, b) - 0.08)


## A village house over footprint `r` (door cells from its left, a shop's noren door and a plain
## side door `side_door` cells from the left, -1 for none): the lit door (not under a noren),
## the side door and the windows between; with two `storeys` also the upper windows over the
## pent roof, in front and on the +x side. Walls of `wall` (village_style) other than plaster
## dress each window for their own warm light (_dress).
static func village_house(r: Rect2, door: int, noren: bool, side_door := -1, storeys := 1, wall := "plaster") -> Array[Dictionary]:
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
	if storeys >= 2:
		var up_front := front - UPPER_INSET + 0.005
		var xs := [r.get_center().x] if r.size.x < 5 else [r.position.x + 1.5, r.end.x - 1.5]
		for x: float in xs:
			out.append(spot("build:shoji", Vector2(0.9, 0.34), Vector3(x, UPPER_WINDOW, up_front), SOUTH))
		out.append(spot("build:shoji", Vector2(0.6, 0.34), Vector3(r.end.x - 0.1 - UPPER_INSET + 0.005, UPPER_WINDOW, mid_z), EAST))
	var body := village_body(r)
	for s in out:
		if s.pos.y > UPPER_FLOOR:
			_dress(s, "upper_" + wall, body.grow(-UPPER_INSET), VILLAGE_WALL - 0.3, UPPER_TOP, false)
		else:
			_dress(s, wall, body, 0.0, VILLAGE_WALL, true)
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
				windows.append_array(village_house(r, int(p.get("door", 1)), bool(p.get("noren", false)), int(p.get("side_door", -1)),
					village_style(p).storeys, village_style(p).wall))
			"stone_lantern":
				lamps.append({"pos": lantern(Vector3(r.get_center().x, 0, r.get_center().y))})
	return {"windows": windows, "lamps": lamps}
