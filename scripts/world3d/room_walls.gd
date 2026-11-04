class_name RoomWalls
extends RefCounted
## The walls and floor edges of a room (an indoor map's "wall" cells) as lit meshes, built
## like FarmProps from tapered blocks, so the lamp and the sun shape them.
##
## The camera looks in from +x / +z, so the back walls (the top row and the left column)
## stand full height and show their room face: a timber frame in the Japanese manner, posts
## every other cell standing proud of the infill, a board skirting (koshi-ita) under a rail,
## the infill (plaster in a house, `walls: "board"` for the coop and barn), a beam across at
## lintel height (nageshi) and a head beam on top; a paper window set below the nageshi every
## fourth cell (in a plaster wall). The front walls (the bottom row and the right column) are
## cut down to a low sill on the room side of their cells, the posts as stubs, so the room
## stays in view; the rest of those cells shows the dark ground beyond. A wall inside the
## room (a partition) is a low sill down the middle of its cells.
##
## Floors: a polished step edge (agari-kamachi) lies along every boards or tatami cell where it
## meets the packed earth, and a flat shoe stone below the step in the door's column.

const HIGH := 1.7            # top of a back wall
const SILL := 0.22           # top of a front sill
const SILL_DEPTH := 0.35     # how far a front sill reaches into its cell from the room side
const SKIRT := 0.45          # top of the board skirting
const NAGESHI := 1.28        # bottom of the beam across
const POST := 0.06           # half a post's width
const WOOD := Color("3a2c22")
const RAIL := Color("4e3a2a")
const STONE := Color("8a8680")


static func build(w: FarmWorld, m: MapData) -> void:
	var p := FarmProps.Parts.new()
	var infill := "build:sugi" if m.walls == "board" else "build:plaster"
	for y in m.h:
		for x in m.w:
			var c := Vector2i(x, y)
			if m.tile(c) != "wall":
				continue
			if c.x == 0 and c.y == 0:
				_corner(p, infill)
			elif c.y == 0 or c.x == 0:
				_back(w, p, Face.new(c), infill, m.walls != "board")
			elif c.x == m.w - 1 or c.y == m.h - 1:
				for s in Face.fronts(m, c):
					_front(p, s)
			else:
				_partition(p, m, c)
	_doors(p, m)
	_steps(p, m)
	p.commit(w)


## The back corner cell: the wall body only, its top under the head beam.
static func _corner(p: FarmProps.Parts, infill: String) -> void:
	var r := Rect2(0, 0, 1, 1)
	FarmProps.block(p.st("build:board"), r, 0.0, r, SKIRT)
	FarmProps.block(p.st(infill), r, SKIRT, r, HIGH - 0.12)
	FarmProps.block(p.st(WOOD), r.grow(0.01), HIGH - 0.12, r.grow(0.01), HIGH + 0.02)


## A full-height back wall cell, its room face towards `s`.
static func _back(w: FarmWorld, p: FarmProps.Parts, s: Face, infill: String, windows: bool) -> void:
	s.slab(p.st("build:board"), 0, 1, -0.02, 1, 0, SKIRT)
	s.slab(p.st(RAIL), 0, 1, -0.035, 1, SKIRT, SKIRT + 0.05)
	s.slab(p.st(infill), 0, 1, 0.02, 1, SKIRT + 0.05, HIGH - 0.12)
	s.slab(p.st(WOOD), 0, 1, -0.03, 1, NAGESHI, NAGESHI + 0.08)
	s.slab(p.st(WOOD), 0, 1, -0.03, 1.01, HIGH - 0.12, HIGH + 0.02)
	if s.along % 2 == 0 or s.along == 1:   # every other cell, and the inner corner
		s.slab(p.st(WOOD), -POST, POST, -0.04, 0.2, 0, HIGH - 0.12)
	if windows and s.along % 4 == 3:
		# A shoji window under the nageshi: a dark frame proud of the plaster, a plank sill.
		s.slab(p.st(WOOD), 0.12, 0.88, -0.025, 0.02, 0.62, 1.24)
		s.slab(p.st("build:planks"), 0.08, 0.92, -0.045, 0.02, 0.58, 0.62)
		var r := s.rect(0.16, 0.84, -0.031, -0.031)
		w._picture("build:shoji", Vector2(0.68, 0.54), Vector3(r.get_center().x, 0.93, r.get_center().y),
			0.0 if s.normal.y != 0 else 90.0)


## A front sill along the room side of a bottom-row or right-column cell, its post stub.
static func _front(p: FarmProps.Parts, s: Face) -> void:
	s.slab(p.st("build:board"), 0, 1, 0.02, SILL_DEPTH, 0, SILL)
	s.slab(p.st(WOOD), 0, 1, -0.01, SILL_DEPTH + 0.01, SILL, SILL + 0.05)
	if s.along % 2 == 0:
		s.slab(p.st(WOOD), -POST, POST, 0.06, 0.18, 0, SILL + 0.14)


## A wall inside the room (the farmhouse's added room): a low sill down the middle of the
## cell along x where it meets walls left or right, along z where it meets another inner wall
## or the back wall above, a post stub every other cell.
static func _partition(p: FarmProps.Parts, m: MapData, c: Vector2i) -> void:
	var inner := func(n: Vector2i) -> bool:
		return m.in_bounds(n) and m.tile(n) == "wall" and n.x > 0 and n.y > 0 and n.x < m.w - 1 and n.y < m.h - 1
	var wall := func(n: Vector2i) -> bool: return m.in_bounds(n) and m.tile(n) == "wall"
	var half := (SILL_DEPTH - 0.02) / 2
	var runs: Array[Rect2] = []
	if wall.call(c + Vector2i.LEFT) or wall.call(c + Vector2i.RIGHT):
		runs.append(Rect2(c.x, c.y + 0.5 - half, 1, half * 2))
	if inner.call(c + Vector2i.UP) or inner.call(c + Vector2i.DOWN) or c.y == 1 or runs.is_empty():
		runs.append(Rect2(c.x + 0.5 - half, c.y, half * 2, 1))
	for r in runs:
		FarmProps.block(p.st("build:board"), r, 0.0, r, SILL)
		FarmProps.block(p.st(WOOD), r.grow(0.01), SILL, r.grow(0.01), SILL + 0.05)
	if (c.x + c.y) % 2 == 0:
		var post := Rect2(c.x + 0.5 - POST, c.y + 0.5 - POST, POST * 2, POST * 2)
		FarmProps.block(p.st(WOOD), post, 0.0, post, SILL + 0.14)


## A stub post each side of a door in the front wall, the same height as the sill's posts.
static func _doors(p: FarmProps.Parts, m: MapData) -> void:
	for d in m.doors:
		for c: Vector2i in d.cells:
			if not m.in_bounds(c) or m.tile(c) == "wall" or c.y != m.h - 1:
				continue
			for x in [c.x, c.x + 1]:
				var r := Rect2(x - POST, c.y + 0.06, POST * 2, 0.12)
				FarmProps.block(p.st(WOOD), r, 0.0, r, SILL + 0.14)


## The step edge where a raised floor meets the earth, and the shoe stone below the door.
static func _steps(p: FarmProps.Parts, m: MapData) -> void:
	var raised := ["floor", "tatami"]
	for y in m.h:
		for x in m.w:
			var c := Vector2i(x, y)
			if not m.tile(c) in raised:
				continue
			for o: Vector2i in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP]:
				var n := c + o
				if not m.in_bounds(n) or m.tile(n) != "earth":
					continue
				# Along the shared edge, 0.1 into the earth cell.
				var edge := Vector2(c) + Vector2(0.5, 0.5) + Vector2(o) * 0.5
				var across := Vector2(absf(o.y), absf(o.x))
				var r := Rect2(edge - across * 0.5 + Vector2(minf(o.x, 0), minf(o.y, 0)) * 0.1,
					across + Vector2(absf(o.x), absf(o.y)) * 0.1)
				FarmProps.block(p.st(RAIL), r, 0.0, r, 0.08)
				FarmProps.block(p.st(WOOD), r, 0.08, r.grow(-0.01), 0.1)
	var stones := {}
	for d in m.doors:
		for c: Vector2i in d.cells:
			stones[_shoe_stone(m, c.x)] = true
	stones.erase(Vector2i(-1, -1))
	for c: Vector2i in stones:
		var r := Rect2(c.x + 0.22, c.y + 0.14, 0.56, 0.3)
		FarmProps.block(p.st(STONE), r, 0.0, r.grow(-0.03), 0.05)


## The earth cell right below the step in column `x`, if nothing stands on it.
static func _shoe_stone(m: MapData, x: int) -> Vector2i:
	for y in range(1, m.h):
		var c := Vector2i(x, y)
		if m.tile(c) == "earth" and m.tile(c + Vector2i.UP) in ["floor", "tatami"] and m.prop_at(c).is_empty():
			return c
	return Vector2i(-1, -1)


## One wall cell seen from the room: `along` runs with the wall (u 0..1 across the cell) and
## `d` goes from the room face into the wall (negative = standing out into the room).
class Face:
	var cell: Vector2i
	var normal: Vector2i   # into the room
	var along: int

	func _init(c: Vector2i, n := Vector2i.ZERO) -> void:
		cell = c
		normal = n if n != Vector2i.ZERO else (Vector2i(0, 1) if c.y == 0 else Vector2i(1, 0))
		along = c.x if normal.y != 0 else c.y

	## The room sides of a front wall cell: up for the bottom row, left for the right column,
	## where the room (not another wall) is.
	static func fronts(m: MapData, c: Vector2i) -> Array:
		var out := []
		for n: Vector2i in ([Vector2i.UP] if c.y == m.h - 1 else []) + ([Vector2i.LEFT] if c.x == m.w - 1 else []):
			if m.tile(c + n) != "wall":   # a side against another wall cell shows nothing
				out.append(Face.new(c, n))
		return out

	## Where the room face is, as a coordinate on the normal's axis.
	func face() -> float:
		var lo := cell.y if normal.y != 0 else cell.x
		return lo + (1.0 if (normal.y > 0 or normal.x > 0) else 0.0)

	## The rect u0..u1 along, d0..d1 deep (world xz).
	func rect(u0: float, u1: float, d0: float, d1: float) -> Rect2:
		var sign := float(normal.x + normal.y)   # +1 when the room is towards +, -1 towards -
		var a := face() - d0 * sign
		var b := face() - d1 * sign
		var n0 := minf(a, b)
		var n1 := maxf(a, b)
		if normal.y != 0:
			return Rect2(cell.x + u0, n0, u1 - u0, n1 - n0)
		return Rect2(n0, cell.y + u0, n1 - n0, u1 - u0)

	func slab(st: SurfaceTool, u0: float, u1: float, d0: float, d1: float, y0: float, y1: float) -> void:
		var r := rect(u0, u1, d0, d1)
		FarmProps.block(st, r, y0, r, y1)
