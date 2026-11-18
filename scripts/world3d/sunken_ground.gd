class_name SunkenGround
extends RefCounted
## The ground as a grid of cells instead of one flat sheet, so water lies lower than the land
## (2026-11-14): every water cell's quad sits DROP below the rest, and where water meets land a
## bank of stone stands from the land's edge down to the water (only the banks that face into the
## water; one along a map's edge where the water runs on past it is left out). The ground picture
## is mapped over the grid exactly as it was over the flat sheet (u = x / columns, v = y / rows),
## so the snow, wet and tile pictures land on the same cells. WaterSurface lies its LIFT over the
## sunken bed; the bridge's deck stays at the land's height, over the water.
## A soft pond (PondShape, the temple's jade pond, 2026-11-16) has no stone walls: the cells it
## reaches are laid as SUB x SUB quads whose corners sink by PondShape.sink, so its bank slopes
## down from a rounded shoreline to the bed; each corner's height is worked out once (a grid over
## the pond's bounds) and its normal from the grid round it, so the slope shades smoothly. A map
## may have several (`ponds`: the temple's and Ogura pond's; the farm's own, 2026-11-18).

const DROP := 0.35   # how far the water lies below the land (world units, a cell is 1)
const BANK_KEY := "ground:scree:1"   # the bank's grey river stones (PlaceholderArt, repeated a unit)
const SUB := 8          # quads a side in a cell a soft pond reaches (fine, so the slope's facets don't read as blocks)


## The ground mesh over `cols` x `rows` cells whose top-left corner stands at `origin` (cells);
## `is_water(c)` (c counted from that corner) says which cells are sunk; `pond` (map cells from
## that corner too) lays its cells as a sloping bank instead; so does each of `ponds`.
static func ground(cols: int, rows: int, origin: Vector2, is_water: Callable, ponds: Array = []) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var heights: Array[PackedFloat32Array] = []
	for pond in ponds:
		heights.append(_pond_heights(pond))
	for y in rows:
		for x in cols:
			var soft := false
			for i in ponds.size():
				if (ponds[i] as PondShape).bounds.has_point(Vector2i(origin) + Vector2i(x, y)):
					_soft_cell(st, cols, rows, origin, Vector2i(x, y), ponds[i], heights[i])
					soft = true
					break
			if soft:
				continue
			var h := -DROP if is_water.call(Vector2i(x, y)) else 0.0
			var x0 := origin.x + x
			var z0 := origin.y + y
			var uv0 := Vector2(float(x) / cols, float(y) / rows)
			var uv1 := Vector2(float(x + 1) / cols, float(y + 1) / rows)
			var v := [Vector3(x0, h, z0), Vector3(x0 + 1, h, z0), Vector3(x0 + 1, h, z0 + 1), Vector3(x0, h, z0 + 1)]
			var uv := [uv0, Vector2(uv1.x, uv0.y), uv1, Vector2(uv0.x, uv1.y)]
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_normal(Vector3.UP)
				st.set_uv(uv[i])
				st.add_vertex(v[i])
	return st.commit()


## The height of every quad corner over `pond`'s bounds (SUB a cell), row by row.
static func _pond_heights(pond: PondShape) -> PackedFloat32Array:
	var n := pond.bounds.size * SUB + Vector2i.ONE
	var out := PackedFloat32Array()
	out.resize(n.x * n.y)
	for j in n.y:
		for i in n.x:
			out[j * n.x + i] = -DROP * pond.sink(Vector2(pond.bounds.position) + Vector2(i, j) / SUB)
	return out


## One cell of a soft pond: SUB x SUB quads, their corners at the grid's heights, the normals from
## the grid round each corner, the picture mapped as on a flat cell.
static func _soft_cell(st: SurfaceTool, cols: int, rows: int, origin: Vector2, c: Vector2i, pond: PondShape, heights: PackedFloat32Array) -> void:
	var n := pond.bounds.size * SUB + Vector2i.ONE
	var base := (Vector2i(origin) + c - pond.bounds.position) * SUB
	var h := func(i: int, j: int) -> float: return heights[clampi(j, 0, n.y - 1) * n.x + clampi(i, 0, n.x - 1)]
	var step := 1.0 / SUB
	for j in SUB:
		for i in SUB:
			for k in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var gi: int = base.x + i + k.x
				var gj: int = base.y + j + k.y
				var hx := float(h.call(gi + 1, gj)) - float(h.call(gi - 1, gj))
				var hz := float(h.call(gi, gj + 1)) - float(h.call(gi, gj - 1))
				var q := Vector2(c) + Vector2(i + k.x, j + k.y) * step
				var w := origin + q
				st.set_normal(Vector3(-hx / (2 * step), 1.0, -hz / (2 * step)).normalized())
				st.set_uv(Vector2(q.x / cols, q.y / rows))
				st.add_vertex(Vector3(w.x, h.call(gi, gj), w.y))


## The banks round the water of the same grid: a wall on every side of a water cell that meets a
## land cell inside the grid (`inside(c)` false leaves a side out, e.g. the map's own cells under
## the apron), facing into the water; none round a soft pond's cells (`ponds`). Null when there is none.
static func banks(cols: int, rows: int, origin: Vector2, is_water: Callable, inside := Callable(), ponds: Array = []) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	for y in rows:
		for x in cols:
			var c := Vector2i(x, y)
			if not is_water.call(c) or (inside.is_valid() and not inside.call(c)):
				continue
			if ponds.any(func(pond: PondShape) -> bool: return pond.cells.has(Vector2i(origin) + c)):
				continue
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var n: Vector2i = c + d
				if n.x < 0 or n.y < 0 or n.x >= cols or n.y >= rows or is_water.call(n):
					continue
				_wall(st, origin + Vector2(c), d)
				any = true
	return st.commit() if any else null


## One wall on side `d` of the cell at `at`, from the land's height down to the water's, facing in.
static func _wall(st: SurfaceTool, at: Vector2, d: Vector2i) -> void:
	var a: Vector3
	var b: Vector3
	match d:
		Vector2i.UP:
			a = Vector3(at.x + 1, 0, at.y)
			b = Vector3(at.x, 0, at.y)
		Vector2i.DOWN:
			a = Vector3(at.x, 0, at.y + 1)
			b = Vector3(at.x + 1, 0, at.y + 1)
		Vector2i.LEFT:
			a = Vector3(at.x, 0, at.y)
			b = Vector3(at.x, 0, at.y + 1)
		_:
			a = Vector3(at.x + 1, 0, at.y + 1)
			b = Vector3(at.x + 1, 0, at.y)
	var down := Vector3(0, -DROP, 0)
	var normal := -Vector3(d.x, 0, d.y)
	for p in [a, b, b + down, a, b + down, a + down]:
		st.set_normal(normal)
		st.add_vertex(p)


## The bank's material: dressed stone repeated a unit (lit, so the sun and the lamps reach it).
static func bank_material() -> Material:
	var m := FarmWorld.surface_material(BANK_KEY)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED   # either winding shows
	return m


## Adds the ground (with `mat`) and its banks to `parent` at `y`; returns the ground's node.
static func place(parent: Node3D, cols: int, rows: int, origin: Vector2, is_water: Callable, mat: Material, y := 0.0, inside := Callable(), ponds: Array = []) -> MeshInstance3D:
	var g := MeshInstance3D.new()
	g.mesh = ground(cols, rows, origin, is_water, ponds)
	g.material_override = mat
	g.position = Vector3(0, y, 0)
	g.layers = NightLamps.GROUND_LAYER   # the night's lamps leave it to the drawn pools
	g.set_meta("ground", true)
	parent.add_child(g)
	var bm := banks(cols, rows, origin, is_water, inside, ponds)
	if bm != null:
		var b := MeshInstance3D.new()
		b.mesh = bm
		b.material_override = bank_material()
		b.position = Vector3(0, y, 0)
		parent.add_child(b)
	return g


## Which cells of `map` lie sunk: its water tiles, or the farm's pond cells when `farm` is given
## (the farm's map tiles say nothing of the pond). Cells past the edge take the nearest edge
## cell's, as the land past the edges continues the water (Surroundings).
static func water_of(map: MapData, farm: FarmGrid = null) -> Callable:
	if farm != null:
		return func(c: Vector2i) -> bool:
			return str(farm.fixed.get(Vector2i(clampi(c.x, 0, farm.w - 1), clampi(c.y, 0, farm.h - 1)), "")) == "pond"
	return func(c: Vector2i) -> bool:
		return map.tile(Vector2i(clampi(c.x, 0, map.w - 1), clampi(c.y, 0, map.h - 1))) == "water"


## How far the ground lies below the land at `p` (cells, x / z), smoothed between cell centres
## (0 on land, -DROP over open water, between at a bank), so something drifting or flying low
## over the shore sinks and rises with the water without a jump (the mist, the heron).
static func sink_at(p: Vector2, is_water: Callable) -> float:
	var q := p - Vector2(0.5, 0.5)
	var x0 := floori(q.x)
	var y0 := floori(q.y)
	var fx := q.x - x0
	var fy := q.y - y0
	var w := 0.0
	for d in [[0, 0, (1.0 - fx) * (1.0 - fy)], [1, 0, fx * (1.0 - fy)], [0, 1, (1.0 - fx) * fy], [1, 1, fx * fy]]:
		if is_water.call(Vector2i(x0 + int(d[0]), y0 + int(d[1]))):
			w += float(d[2])
	return -DROP * w
