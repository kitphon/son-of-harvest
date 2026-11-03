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
		_eave_band(band, corners[i], corners[(i + 1) % 4], low, thick, float(i) * 7.0)

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


## A gable roof over `eave` (x / z of its outer edge) with the ridge along x: the two slopes,
## the trimmed eave band along the front and back, the verge (the roof's cut end, as thick as
## the roof) at both gable ends, the soffit under it and a snow layer. The soffit is at `low`
## at the eaves and rises `pitch` per unit run. `roof_key` covers the slopes and the soffit,
## `edge_key` the eave band and the verges. With `rolls` > 0 the slopes carry raised rows of
## round tiles (kawara) that far apart, running down from the ridge to the eave. Adds its
## meshes to `w` and returns the outer ridge height (the ridge itself is the caller's).
static func gable(w: FarmWorld, eave: Rect2, low: float, pitch: float, thick: float,
		roof_key: String, edge_key: String, rolls := 0.0) -> float:
	var x0 := eave.position.x
	var x1 := eave.end.x
	var z0 := eave.position.y
	var z1 := eave.end.y
	var half := (z1 - z0) / 2.0
	var zm := z0 + half
	var top := low + half * pitch
	var run := sqrt(1.0 + pitch * pitch)
	var outer := SurfaceTool.new()
	var band := SurfaceTool.new()
	var under := SurfaceTool.new()
	var snow := SurfaceTool.new()
	for st in [outer, band, under, snow]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var slopes := func(st: SurfaceTool, lift: float, sign: float) -> void:
		var e := low + lift
		var r := top + lift
		_quad(st, Vector3(x0, e, z1), Vector3(x1, e, z1), Vector3(x1, r, zm), Vector3(x0, r, zm),
			Vector3(0, 1, pitch).normalized() * sign,
			func(p: Vector3) -> Vector2: return Vector2(p.x - x0, (p.z - zm) * run))
		_quad(st, Vector3(x1, e, z0), Vector3(x0, e, z0), Vector3(x0, r, zm), Vector3(x1, r, zm),
			Vector3(0, 1, -pitch).normalized() * sign,
			func(p: Vector3) -> Vector2: return Vector2(x1 - p.x, (zm - p.z) * run))
	slopes.call(outer, thick, 1.0)
	slopes.call(under, 0.0, -1.0)

	# Tile rolls sit centred on the roof; `shift` lines the edge texture's tile ends up with them.
	var count := int((x1 - x0) / rolls) if rolls > 0.0 else 0
	var shift := ((x1 - x0) - count * rolls) / 2.0 if rolls > 0.0 else 0.0

	# Eave bands along the front and back; the verges close the two gable ends: the roof's
	# cross section, a chevron as thick as the roof, the edge texture's dark top at the slope.
	_eave_band(band, Vector3(x0, 0, z1), Vector3(x1, 0, z1), low, thick, -shift)
	_eave_band(band, Vector3(x1, 0, z0), Vector3(x0, 0, z0), low, thick, -shift)
	for x: float in [x0, x1]:
		var n := Vector3(signf(x - (x0 + x1) / 2.0), 0, 0)
		var uv := func(p: Vector3) -> Vector2:
			var d := absf(p.z - zm)
			return Vector2(-d * run, low + thick + (half - d) * pitch - p.y)
		for z: float in [z0, z1]:
			_quad(band, Vector3(x, low, z), Vector3(x, top, zm), Vector3(x, top + thick, zm),
				Vector3(x, low + thick, z), n, uv)

	# Tile rolls: a low ridge of round tiles every `rolls` along x, each a pair of faces
	# leaning left and right, closed at the eave by a little end facing out.
	var crest := top + thick
	if rolls > 0.0:
		var high := 0.06
		var wide := rolls * 0.45
		var x_first := x0 + shift + rolls / 2.0
		for side: float in [1.0, -1.0]:
			var ze := zm + half * side                       # this slope's eave line
			var lift := func(x: float, z: float, up: float) -> Vector3:
				return Vector3(x, low + thick + (half - absf(z - zm)) * pitch + up, z)
			for i in count:
				var x := x_first + i * rolls
				for lean: float in [-1.0, 1.0]:
					var foot_e: Vector3 = lift.call(x + lean * wide / 2, ze, 0.0)
					var foot_r: Vector3 = lift.call(x + lean * wide / 2, zm, 0.0)
					var crown_e: Vector3 = lift.call(x, ze, high)
					var crown_r: Vector3 = lift.call(x, zm, high)
					var n := (crown_r - crown_e).cross(foot_e - crown_e).normalized()
					if n.y < 0.0:
						n = -n
					_quad(outer, foot_e, crown_e, crown_r, foot_r, n,
						func(p: Vector3) -> Vector2: return Vector2(p.x - x0, (p.z - zm) * side * run))
				var face := Vector3(0, 0, side)
				_tri(band, lift.call(x - wide / 2, ze, 0.0), lift.call(x + wide / 2, ze, 0.0),
					lift.call(x, ze, high), face,
					func(p: Vector3) -> Vector2: return Vector2(p.x - x0 - shift, (low + thick + high - p.y) * 3.0))
		crest += high
	slopes.call(snow, thick + (0.09 if rolls > 0.0 else 0.03), 1.0)

	for pair in [[outer, _material(roof_key)], [under, _material(roof_key)], [band, _material(edge_key)]]:
		_add_mesh(w, pair[0], pair[1])
	var snow_mat := SnowLayer.top_material()
	w._snow_mats.append(snow_mat)
	_add_mesh(w, snow, snow_mat).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return crest


## The wall filling a gable end under the roof: a triangle in the plane x = `x` from the
## wall top `base` at z0 / z1 up to `apex` over the middle, facing `facing` (+1 / -1 along x),
## textured like the wall below it (u along z, v down).
static func gable_wall(w: FarmWorld, x: float, z0: float, z1: float, base: float, apex: float,
		key: String, facing: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tri(st, Vector3(x, base, z0), Vector3(x, base, z1), Vector3(x, apex, (z0 + z1) / 2.0),
		Vector3(facing, 0, 0), func(p: Vector3) -> Vector2: return Vector2(p.z * facing, -p.y))
	_add_mesh(w, st, _material(key))


## The roof's trimmed edge on one side, p -> q along the eave line (y ignored), from the soffit
## at `low` up `thick`: a band facing outwards (the corners go round the roof clockwise seen
## from above, so outside is right of the way from p to q), its texture starting at `start`.
static func _eave_band(st: SurfaceTool, p: Vector3, q: Vector3, low: float, thick: float, start: float) -> void:
	var along := (q - p).normalized()
	var out := Vector3(-along.z, 0, along.x)
	var uv := func(v: Vector3) -> Vector2:
		return Vector2(start + (v - p).dot(along), low + thick - v.y)
	_quad(st, p + Vector3(0, low, 0), q + Vector3(0, low, 0),
		q + Vector3(0, low + thick, 0), p + Vector3(0, low + thick, 0), out, uv)


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
