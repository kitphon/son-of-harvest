class_name MeshCache
extends RefCounted
## Meshes that come out the same every time they are built, kept for the whole run so the next
## world that needs them (a map's first visit, a new day's rebuild) only places them: the
## farm's fence for its gate, the wood's pine shapes, the farm buildings, the village houses
## by their look and footprint. A world gets the shared ArrayMeshes but its own materials (the
## snow on them and the fades in the farmer's way are per world).
##
## Two ways in; either way the id must name everything the build depends on:
##  - `parts(id, build)`: `build(p: FarmProps.Parts)` fills the pieces the first time `id` is
##    asked for; after that the kept meshes (material key -> ArrayMesh, in the order built) come
##    back (`commit` places them);
##  - `build(w, id, make)`: runs `make()` on the world `w` the first time and keeps what it
##    added (plain MeshInstance3Ds: mesh, material, transform, shadow, layers; the snow materials
##    among them); the next time the same pieces are made again from that, with copies of the
##    materials, and make's return value given back. A build that adds anything else (a Sway, a
##    MultiMesh, lit windows or lamps, a group, a meta, a snow material on no piece) is not kept
##    and always runs (`kept(id)` false).

static var _kept := {}   # id -> {material key: ArrayMesh}
static var _made := {}   # id -> what build() recorded (see _record), or null: not keepable
static var built := 0    # how many times a builder ran (tests)
static var reused := 0   # how many times kept meshes were handed out (tests)


static func parts(id: String, build: Callable) -> Dictionary:
	if _kept.has(id):
		reused += 1
		return _kept[id]
	var p := FarmProps.Parts.new()
	build.call(p)
	var meshes := p.meshes()
	_kept[id] = meshes
	built += 1
	return meshes


## Places kept meshes on `w` as FarmProps.Parts.commit places its pieces: one MeshInstance3D
## a material key, its own material, no shadow from snow or glow. The instances, in order.
static func commit(w: FarmWorld, meshes: Dictionary) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for key in meshes:
		var mi := MeshInstance3D.new()
		mi.mesh = meshes[key]
		mi.material_override = FarmProps.Parts.material(key, w._snow_mats)
		if not FarmProps.Parts.casts_shadow(key):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.add_child(mi)
		out.append(mi)
	return out


static func build(w: FarmWorld, id: String, make: Callable) -> Variant:
	if _made.has(id):
		if _made[id] == null:
			return make.call()
		reused += 1
		return _replay(w, _made[id])
	var first := w.get_child_count()
	var before := {"snow": w._snow_mats.size(), "windows": w.windows.size(), "lamps": w.lamps.size(),
		"groups": w.get_groups().size(), "metas": w.get_meta_list().size()}
	var out: Variant = make.call()
	_made[id] = _record(w, first, before, out)
	built += 1
	return out


## What `w` got from a build since child `first`: the pieces and their materials (copied now, so
## later fades and snow on this world don't reach the next one), or null when it made anything
## but plain mesh pieces.
static func _record(w: FarmWorld, first: int, before: Dictionary, out: Variant) -> Variant:
	if w.windows.size() != before.windows or w.lamps.size() != before.lamps \
			or w.get_groups().size() != before.groups or w.get_meta_list().size() != before.metas:
		return null
	var snow_new := {}   # the snow materials the build added
	for m in w._snow_mats.slice(int(before.snow)):
		snow_new[m] = true
	var mats: Array[Material] = []
	var snowy: Array[bool] = []
	var index := {}   # material -> its place in mats
	var pieces: Array[Dictionary] = []
	for n in w.get_children().slice(first):
		var mi := n as MeshInstance3D
		if mi == null or mi.get_script() != null or mi.get_child_count() > 0 or mi.material_overlay != null \
				or mi.mesh == null or mi.material_override == null:
			return null
		for i in mi.get_surface_override_material_count():
			if mi.get_surface_override_material(i) != null:
				return null
		var m := mi.material_override
		if not index.has(m):
			index[m] = mats.size()
			mats.append(m.duplicate())
			snowy.append(snow_new.has(m))
		pieces.append({"mesh": mi.mesh, "mat": index[m], "at": mi.transform, "shadow": mi.cast_shadow,
			"layers": mi.layers, "visible": mi.visible})
	if snowy.count(true) != snow_new.size():
		return null
	return {"pieces": pieces, "mats": mats, "snow": snowy, "out": out}


static func _replay(w: FarmWorld, rec: Dictionary) -> Variant:
	var mats: Array[Material] = []
	for i in rec.mats.size():
		var m: Material = rec.mats[i].duplicate()
		mats.append(m)
		if rec.snow[i]:
			w._snow_mats.append(m as ShaderMaterial)
	for piece: Dictionary in rec.pieces:
		var mi := MeshInstance3D.new()
		mi.mesh = piece.mesh
		mi.material_override = mats[piece.mat]
		mi.transform = piece.at
		mi.cast_shadow = piece.shadow
		mi.layers = piece.layers
		mi.visible = piece.visible
		w.add_child(mi)
	return rec.out


static func has(id: String) -> bool:
	return _kept.has(id) or _made.has(id)


## Is `id` kept for building again (false: never built, or its build is one that always runs)?
static func kept(id: String) -> bool:
	return _kept.has(id) or (_made.has(id) and _made[id] != null)


static func count() -> int:
	return _kept.size() + _made.size()


## Forgets every kept mesh (tests).
static func clear() -> void:
	_kept.clear()
	_made.clear()
	built = 0
	reused = 0
