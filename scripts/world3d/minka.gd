class_name Minka
extends RefCounted
## A thick thatched hip roof (kayabuki) for a farmhouse, built as real meshes: the outer
## slopes, the trimmed eave edge all round, the soffit under the overhang, and a dark ridge
## (kuragi) with pairs of crossed riders (umanori). The faces carry their own UVs in world
## units (16 texture pixels a unit, like every surface here): u along the eave, v down the
## slope, so the straw runs down every face and the courses stay level.

## The roof over `eave` (x / z of its outer eave line) with the soffit at `low` at the eaves,
## rising `pitch` per unit run to a ridge along x, `thick` deep. Adds its meshes to `w` and
## returns the ridge's top height.
static func roof(w: FarmWorld, eave: Rect2, low: float, pitch: float, thick: float) -> float:
	var x0 := eave.position.x
	var x1 := eave.end.x
	var z0 := eave.position.y
	var z1 := eave.end.y
	var half := (z1 - z0) / 2.0
	var zm := z0 + half
	var top := low + half * pitch          # the soffit's ridge height
	var rx0 := x0 + half
	var rx1 := x1 - half
	var run := sqrt(1.0 + pitch * pitch)   # slope length per unit run

	var straw := _material("build:kaya")
	var edge := _material("build:kaya_edge")
	var outer := SurfaceTool.new()
	var band := SurfaceTool.new()
	var under := SurfaceTool.new()
	var snow := SurfaceTool.new()
	for st in [outer, band, under, snow]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# The four slopes at a lift: front and back trapezoids, the two hip ends.
	var slopes := func(st: SurfaceTool, lift: float, sign: float) -> void:
		var e := low + lift
		var r := top + lift
		var n_front := Vector3(0, 1, pitch).normalized() * sign
		var n_back := Vector3(0, 1, -pitch).normalized() * sign
		var n_left := Vector3(-pitch, 1, 0).normalized() * sign
		var n_right := Vector3(pitch, 1, 0).normalized() * sign
		var a := Vector3(x0, e, z1)
		var b := Vector3(x1, e, z1)
		var c := Vector3(rx1, r, zm)
		var d := Vector3(rx0, r, zm)
		var uv_f := func(p: Vector3) -> Vector2: return Vector2(p.x, (p.z - zm) * run)
		_quad(st, a, b, c, d, n_front, uv_f)
		var a2 := Vector3(x1, e, z0)
		var b2 := Vector3(x0, e, z0)
		var uv_b := func(p: Vector3) -> Vector2: return Vector2(-p.x, (zm - p.z) * run)
		_quad(st, a2, b2, d, c, n_back, uv_b)
		var uv_l := func(p: Vector3) -> Vector2: return Vector2(-p.z, (rx0 - p.x) * run)
		_tri(st, Vector3(x0, e, z0), Vector3(x0, e, z1), d, n_left, uv_l)
		var uv_r := func(p: Vector3) -> Vector2: return Vector2(p.z, (p.x - rx1) * run)
		_tri(st, Vector3(x1, e, z1), Vector3(x1, e, z0), c, n_right, uv_r)
	slopes.call(outer, thick, 1.0)
	slopes.call(under, 0.0, -1.0)
	slopes.call(snow, thick + 0.03, 1.0)

	# The trimmed edge: a band round the eave line from the soffit up to the outer slopes.
	var corners := [Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(x1, 0, z0), Vector3(x0, 0, z0)]
	for i in 4:
		var p: Vector3 = corners[i]
		var q: Vector3 = corners[(i + 1) % 4]
		var along := (q - p).normalized()
		var out := Vector3(along.z, 0, -along.x)   # turned right of the way round: outwards
		var start := float(i) * 7.0                # each side its own stretch of texture
		var uv := func(v: Vector3) -> Vector2:
			return Vector2(start + (v - p).dot(along), low + thick - v.y)
		_quad(band, p + Vector3(0, low, 0), q + Vector3(0, low, 0),
			q + Vector3(0, low + thick, 0), p + Vector3(0, low + thick, 0), out, uv)

	for pair in [[outer, straw], [under, straw], [band, edge]]:
		_add_mesh(w, pair[0], pair[1])
	var snow_mat := SnowLayer.top_material()
	w._snow_mats.append(snow_mat)
	_add_mesh(w, snow, snow_mat).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# The ridge: a dark straw-bound beam a little past the ridge ends, riders crossed over it.
	var crest := top + thick
	var wood := FarmWorld.flat_material(Color("3a2c22"))
	var cap := FarmWorld.flat_material(Color("2a2420"))
	w._box(Vector3(rx1 - rx0 + 0.5, 0.2, 0.34), Vector3((rx0 + rx1) / 2, crest + 0.04, zm), cap)
	w._box(Vector3(rx1 - rx0 + 0.56, 0.06, 0.38), Vector3((rx0 + rx1) / 2, crest + 0.16, zm), wood)
	var count := maxi(2, int((rx1 - rx0) / 0.55))
	for i in count + 1:
		var x := lerpf(rx0, rx1, float(i) / count)
		for side in [1.0, -1.0]:
			w._box(Vector3(0.07, 0.07, 0.5), Vector3(x, crest + 0.2, zm),
				wood, Vector3(deg_to_rad(50.0) * side, 0, 0))
	return crest + 0.4


static func _material(key: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = PlaceholderArt.tex(key)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_scale = Vector3(1, 1, 1)
	return m


static func _add_mesh(w: FarmWorld, st: SurfaceTool, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	w.add_child(mi)
	return mi


## A quad a-b-c-d (in order round its edge) facing `n`; `uv` maps a world point to its UV
## (world units, so one texture per unit).
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, uv: Callable) -> void:
	_tri(st, a, b, c, n, uv)
	_tri(st, a, c, d, n, uv)


## Godot draws a triangle's front where its corners run clockwise, so the order is turned to
## face `n` whichever way the corners came.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, uv: Callable) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
	for p in [a, b, c]:
		st.set_normal(n)
		st.set_uv(uv.call(p))
		st.add_vertex(p)
