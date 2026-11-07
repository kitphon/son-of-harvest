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
##    among them; the lit windows and lamps it listed for NightLights; what it hung in the
##    world's Sway: a noren, a curtain); the next time the same pieces are made again from that,
##    with new materials made like the first ones, and make's return value given back. A build
##    that adds anything else (a MultiMesh, a scripted node, a group other than NightLights', a
##    meta, a snow material on no piece) is not kept and always runs (`kept(id)` false).

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
	var sway := w.get_node_or_null(OutdoorProps.SWAY) as OutdoorProps.Sway
	var before := {"snow": w._snow_mats.size(), "windows": w.windows.size(), "lamps": w.lamps.size(),
		"groups": w.get_groups(), "metas": w.get_meta_list().size(), "sway": sway.count() if sway != null else 0}
	var out: Variant = make.call()
	_made[id] = _record(w, first, before, out)
	built += 1
	return out


## What `w` got from a build since child `first`: the pieces and how to make their materials
## again (_recipe, taken now, so later fades and snow on this world don't reach the next one),
## the lit windows and lamps it listed, what it hung in the world's Sway (the Sway itself a
## piece when the build made it), or null when it made anything else.
static func _record(w: FarmWorld, first: int, before: Dictionary, out: Variant) -> Variant:
	if w.get_meta_list().size() != before.metas:
		return null
	for group in w.get_groups():
		if not group in before.groups and group != NightLights.GROUP:
			return null
	var sway := w.get_node_or_null(OutdoorProps.SWAY) as OutdoorProps.Sway
	var snow_new := {}   # the snow materials the build added
	for m in w._snow_mats.slice(int(before.snow)):
		snow_new[m] = true
	var mats: Array = []
	var snowy: Array[bool] = []
	var index := {}   # material -> its place in mats
	var pieces: Array[Dictionary] = []
	var piece_of := {}   # node -> its place in pieces
	for n in w.get_children().slice(first):
		if n == sway:
			pieces.append({"sway": true})
			continue
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
			mats.append(_recipe(m))
			snowy.append(snow_new.has(m))
		piece_of[mi] = pieces.size()
		pieces.append({"mesh": mi.mesh, "mat": index[m], "at": mi.transform, "shadow": mi.cast_shadow,
			"layers": mi.layers, "visible": mi.visible})
	if snowy.count(true) != snow_new.size():
		return null
	var swaying: Array[Dictionary] = []   # the Sway's new items, their nodes as places in pieces
	if sway != null:
		for i in range(int(before.sway), sway.count()):
			var it: Dictionary = sway.item(i).duplicate()
			var at: Array[int] = []
			for node in it.nodes:
				if not piece_of.has(node):
					return null
				at.append(piece_of[node])
			it.nodes = at
			swaying.append(it)
	return {"pieces": pieces, "mats": mats, "snow": snowy, "out": out, "sway": swaying,
		"windows": w.windows.slice(int(before.windows)), "lamps": w.lamps.slice(int(before.lamps))}


static func _replay(w: FarmWorld, rec: Dictionary) -> Variant:
	var mats: Array[Material] = []
	for i in rec.mats.size():
		var m := _make(rec.mats[i])
		mats.append(m)
		if rec.snow[i]:
			w._snow_mats.append(m as ShaderMaterial)
	var nodes: Array[Node3D] = []
	for piece: Dictionary in rec.pieces:
		if piece.has("sway"):
			nodes.append(OutdoorProps._sway(w))
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = piece.mesh
		mi.material_override = mats[piece.mat]
		mi.transform = piece.at
		mi.cast_shadow = piece.shadow
		mi.layers = piece.layers
		mi.visible = piece.visible
		w.add_child(mi)
		nodes.append(mi)
	mats.clear()   # the pieces hold them now (Occluders.add sees a material no one else has)
	if not rec.sway.is_empty():
		var sway := OutdoorProps._sway(w)
		for it: Dictionary in rec.sway:
			var put := it.duplicate()
			put.nodes = (it.nodes as Array).map(func(i: int) -> Node3D: return nodes[i])
			sway.put(put)
	for win: Dictionary in rec.windows:
		w.windows.append(win.duplicate())
	for lamp: Dictionary in rec.lamps:
		w.lamps.append(lamp.duplicate())
	if not (rec.windows.is_empty() and rec.lamps.is_empty()) and not w.is_in_group(NightLights.GROUP):
		w.add_to_group(NightLights.GROUP)
	return rec.out


static var _blank: StandardMaterial3D   # what a new StandardMaterial3D holds
static var _stored: Array[String] = []  # its stored properties


## How to make a material like `m` again: for a StandardMaterial3D the stored properties that
## differ from a new one, in their order (setting those few is about ten times quicker than
## duplicate(), which sets every one); any other material a copy to duplicate.
static func _recipe(m: Material) -> Variant:
	if m.get_class() != "StandardMaterial3D" or m.get_script() != null:
		return m.duplicate()
	if _blank == null:
		_blank = StandardMaterial3D.new()
		for prop in _blank.get_property_list():
			if prop.usage & PROPERTY_USAGE_STORAGE and prop.name != "script":
				_stored.append(prop.name)
	var out: Array = []
	for name in _stored:
		var v: Variant = m.get(name)
		var b: Variant = _blank.get(name)
		if typeof(v) != typeof(b) or v != b:
			out.append([name, v])
	for name in m.get_meta_list():
		out.append(["metadata/" + name, m.get_meta(name)])
	return out


## A new material from a recipe (_recipe).
static func _make(recipe: Variant) -> Material:
	if recipe is Material:
		return (recipe as Material).duplicate()
	var m := StandardMaterial3D.new()
	for pair: Array in recipe:
		m.set(pair[0], pair[1])
	return m


## A new StandardMaterial3D like `m` (the same as m.duplicate(), quicker), for the tests.
static func copy(m: StandardMaterial3D) -> Material:
	return _make(_recipe(m))


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
