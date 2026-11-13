class_name ReachMap
extends RefCounted
## Where low geometry really stands in a built world, finer than the map's cells: the footprint
## (on the ground plane, in 1/8-cell tiles) of every mesh triangle that reaches into the height a
## figure occupies. FarmWorld.wall_pull reads it next to the map's solid cells, so a prop drawn
## bigger than its cell (a lantern's cap, a well's roof posts, the coop's and barn's wall bases, the
## fence's posts and rails, a stall's counter) pulls the figure beside it clear as a wall does.
## Eaves and roofs hang above a figure's head (the soffits are 1.45 up, a figure's top about 1.3)
## and are left out: they are the roof's own business (Occluders fades it).
##
## Built once per world after its meshes are in (FarmWorld.build_reach). The meshes' footprints are
## kept for the whole run per mesh (MeshCache shares the meshes), so a second world only places
## them. Numbers: data/camera.json "figure_pull" -> "reach". Ours.

static var _cache := {}   # Mesh -> PackedVector2Array of footprint points in the mesh's own space
static var built := 0     # meshes rasterized (tests)

var res := 0.125
var tiles := {}           # tile key -> true
var _low := 0.2
var _high := 1.3
var _max_cells := 900


func _init(rules := {}) -> void:
	var r: Dictionary = rules.get("reach", {}) if not rules.is_empty() else FarmWorld.pull_rules().get("reach", {})
	res = maxf(float(r.get("res", 0.125)), 0.02)
	_low = float(r.get("low", 0.2))
	_high = float(r.get("high", 1.3))
	_max_cells = int(r.get("max_cells", 900))


static func key(fx: int, fz: int) -> int:
	return (fz + 4096) * 65536 + (fx + 4096)


func has_tile(fx: int, fz: int) -> bool:
	return tiles.has(key(fx, fz))


func count() -> int:
	return tiles.size()


## True when the tile (x, z) of the ground plane under world point (x, z) is in the footprint.
func has_point(x: float, z: float) -> bool:
	return tiles.has(key(floori(x / res), floori(z / res)))


## Adds what `root`'s meshes (and theirs below) stand on; nodes with a script (the weather, birds,
## insects, grass, crops ... layers), the ground layer's meshes and what is hidden are left out,
## and so are the `skip` nodes (the land past the map's edge).
func collect(root: Node, skip: Array = []) -> void:
	_walk(root, Transform3D.IDENTITY, skip)


func _walk(n: Node, xf: Transform3D, skip: Array) -> void:
	for c in n.get_children():
		if c in skip or c.get_script() != null:
			continue
		var t := xf
		if c is Node3D:
			if not (c as Node3D).visible:
				continue
			t = xf * (c as Node3D).transform
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.mesh != null and mi.layers != NightLamps.GROUND_LAYER \
					and mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
				add_mesh(mi.mesh, t)
		if c.get_child_count() > 0:
			_walk(c, t, skip)


## Adds mesh `m` placed by `xf`.
func add_mesh(m: Mesh, xf: Transform3D) -> void:
	var upright := absf(xf.basis.y.x) < 1e-4 and absf(xf.basis.y.z) < 1e-4 and absf(xf.origin.y) < 1e-4 \
		and absf(xf.basis.x.y) < 1e-4 and absf(xf.basis.z.y) < 1e-4 and absf(xf.basis.y.y - 1.0) < 1e-4
	if upright:   # the usual case: kept per mesh, placed by the turn and the spot
		var pts: Variant = _cache.get(m)
		if pts == null:
			pts = _raster(m, Transform3D.IDENTITY, res * 0.5, _low, _high, _max_cells)
			_cache[m] = pts
			built += 1
		var b := xf.basis
		for p: Vector2 in pts:
			var x := b.x.x * p.x + b.z.x * p.y + xf.origin.x
			var z := b.x.z * p.x + b.z.z * p.y + xf.origin.z
			tiles[key(floori(x / res), floori(z / res))] = true
	else:
		for p: Vector2 in _raster(m, xf, res * 0.5, _low, _high, _max_cells):
			tiles[key(floori(p.x / res), floori(p.y / res))] = true


## The ground points (a grid `pitch` apart) under the triangles of `m` (placed by `xf`) that reach
## into the heights low..high: inside the triangle's picture on the ground, or within a
## pitch of its edge (a wall's triangle stands on a line). Triangles whose picture is over `max_cells`
## grid points (a huge slab) are left out.
static func _raster(m: Mesh, xf: Transform3D, pitch: float, low: float, high: float, max_cells: int) -> PackedVector2Array:
	var faces := m.get_faces()
	var seen := {}
	var out := PackedVector2Array()
	var tol := pitch * 0.75
	var inv := 1.0 / pitch
	for i in range(0, faces.size() - 2, 3):
		var a := xf * faces[i]
		var b := xf * faces[i + 1]
		var c := xf * faces[i + 2]
		if maxf(a.y, maxf(b.y, c.y)) < low or minf(a.y, minf(b.y, c.y)) > high:
			continue
		var x0 := minf(a.x, minf(b.x, c.x)) - tol
		var x1 := maxf(a.x, maxf(b.x, c.x)) + tol
		var z0 := minf(a.z, minf(b.z, c.z)) - tol
		var z1 := maxf(a.z, maxf(b.z, c.z)) + tol
		var gx0 := ceili(x0 * inv)
		var gx1 := floori(x1 * inv)
		var gz0 := ceili(z0 * inv)
		var gz1 := floori(z1 * inv)
		if (gx1 - gx0 + 1) * (gz1 - gz0 + 1) > max_cells:
			continue
		var pa := Vector2(a.x, a.z)
		var pb := Vector2(b.x, b.z)
		var pc := Vector2(c.x, c.z)
		var area := (pb - pa).cross(pc - pa)
		for gz in range(gz0, gz1 + 1):
			for gx in range(gx0, gx1 + 1):
				var k := gz * 65536 + gx
				if seen.has(k):
					continue
				var p := Vector2(gx * pitch, gz * pitch)
				var hit := false
				if absf(area) > 1e-9:
					var s1 := (pb - pa).cross(p - pa)
					var s2 := (pc - pb).cross(p - pb)
					var s3 := (pa - pc).cross(p - pc)
					hit = (s1 >= 0.0 and s2 >= 0.0 and s3 >= 0.0) or (s1 <= 0.0 and s2 <= 0.0 and s3 <= 0.0)
				if not hit:
					hit = _near(p, pa, pb, tol) or _near(p, pb, pc, tol) or _near(p, pc, pa, tol)
				if hit:
					seen[k] = true
					out.append(p)
	return out


static func _near(p: Vector2, a: Vector2, b: Vector2, tol: float) -> bool:
	var ab := b - a
	var len2 := ab.length_squared()
	var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0) if len2 > 1e-12 else 0.0
	return p.distance_squared_to(a + ab * t) <= tol * tol
