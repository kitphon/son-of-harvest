class_name Occluders
extends RefCounted
## Tall things (houses, the coop and barn, trees, the torii) that fade to see-through while
## they stand between the camera and the farmer's patch of ground, so a roof in front never
## hides the farmer or the cells around them. Each one is its group of meshes and their
## combined box; the test is a ray from points round the farmer's feet towards the camera.
##
## The fade is the materials' own alpha (GeometryInstance3D.transparency draws nothing in the
## Compatibility renderer): each thing gets its own copies of its materials, switched to alpha
## blending only while faded; snow tops (shader) hide instead, sprites use their modulate.

const FADED := 0.6       # how see-through a thing in the way gets (1 - alpha)
const SPEED := 4.0       # transparency per second, towards the target
const MIN_HEIGHT := 1.0  # lower things (tables, fences, the bin) never fade
const RING := 1.25       # cells round the feet that should stay in view
## Points on the farmer that must stay visible (feet to head), then the ring round them.
const BODY_HEIGHTS: Array[float] = [0.15, 0.6, 1.1]
const RING_HEIGHT := 0.4

var _groups: Array[Dictionary] = []   # {nodes: Array[GeometryInstance3D], box: AABB, now, target}


## Adds the meshes `nodes` (world-space children of a world at the origin) as one thing;
## too low ones are left out. Returns whether it was added.
func add(nodes: Array) -> bool:
	var geo: Array[GeometryInstance3D] = []
	var box := AABB()
	for n in nodes:
		if n is GeometryInstance3D:
			var b: AABB = n.transform * n.get_aabb()
			box = b if geo.is_empty() else box.merge(b)
			geo.append(n)
	if geo.is_empty() or box.end.y < MIN_HEIGHT:
		return false
	# Each material this thing's own (shared within the thing, never with others): a copy where
	# anything else holds it too, the material itself where only these meshes do (a copy is
	# about ten times dearer than making one, and most builders make theirs fresh).
	var uses := _uses(geo)   # material -> how many of these meshes wear it
	for m: Material in uses:
		if not only_here(m, uses[m]):
			var mine := MeshCache.copy(m)
			for n in geo:
				if n.material_override == m:
					n.material_override = mine
	_groups.append({"nodes": geo, "box": box, "now": 0.0, "target": 0.0})
	return true


## The StandardMaterial3Ds the meshes `geo` wear: material -> how many wear it (its own
## function, so no local of it still holds one of them while add() asks only_here).
static func _uses(geo: Array[GeometryInstance3D]) -> Dictionary:
	var uses := {}
	for n in geo:
		if n.material_override is StandardMaterial3D:
			uses[n.material_override] = int(uses.get(n.material_override, 0)) + 1
	return uses


## Is `m` held by nothing but `count` meshes' material_override (and add()'s own references to
## it while it asks: HELD_HERE)?
static func only_here(m: Material, count: int) -> bool:
	return m.get_reference_count() <= count + HELD_HERE


## Add()'s own references to a material while it asks only_here: the table's key, the loop's
## variable and its copy, this call's argument (measured; test_maps' _occluder_own checks it).
const HELD_HERE := 4


## Adds everything `parent` got after it had `first` children (what one builder made).
func add_children_from(parent: Node, first: int) -> bool:
	return add(parent.get_children().slice(first))


func count() -> int:
	return _groups.size()


## The StandardMaterial3Ds of the things that fade (ShaderWarm warms their faded look).
func materials() -> Array[Material]:
	var seen := {}
	for g in _groups:
		for n: GeometryInstance3D in g.nodes:
			if n.material_override is StandardMaterial3D:
				seen[n.material_override] = true
	var out: Array[Material] = []
	out.assign(seen.keys())
	return out


## Thing `i`'s box (world units).
func box_of(i: int) -> AABB:
	return _groups[i].box


## How see-through thing `i` is now (0 opaque .. FADED).
func fade_of(i: int) -> float:
	return _groups[i].now


## Picks each thing's target for the farmer at `feet` (world units) with the camera along
## `back` (unit, from the ground towards the eye) and moves its fade `delta` seconds on.
func update(feet: Vector3, back: Vector3, delta: float) -> void:
	for g in _groups:
		g.target = FADED if hides(g.box, feet, back) else 0.0
		var was: float = g.now
		g.now = move_toward(g.now, g.target, SPEED * delta)
		if g.now != was:
			for n: GeometryInstance3D in g.nodes:
				_set_alpha(n, 1.0 - g.now)


## One mesh's look at `alpha`: opaque again at 1 (and no alpha blending, so it sorts as before).
static func _set_alpha(n: GeometryInstance3D, alpha: float) -> void:
	if n is SpriteBase3D:
		n.modulate.a = alpha
		return
	var m := n.material_override
	if m is StandardMaterial3D:
		if not m.has_meta("solid"):
			m.set_meta("solid", [m.transparency, m.albedo_color.a])
		var solid: Array = m.get_meta("solid")
		m.transparency = solid[0] if alpha >= 1.0 else BaseMaterial3D.TRANSPARENCY_ALPHA
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY if alpha >= 1.0 else BaseMaterial3D.DEPTH_DRAW_ALWAYS
		m.albedo_color.a = solid[1] * alpha
	elif m is ShaderMaterial:
		n.visible = alpha >= 1.0   # snow tops: gone while the roof is see-through


## Does `box` stand in front of (nearer the camera than) the farmer at `feet` and cover the
## farmer or the ground within RING of them?
static func hides(box: AABB, feet: Vector3, back: Vector3) -> bool:
	if (box.get_center() - feet).dot(Vector3(back.x, 0, back.z)) <= 0.0:
		return false   # behind the farmer: it can't be in the way
	for y in BODY_HEIGHTS:
		if box.intersects_ray(feet + Vector3(0, y, 0), back) != null:
			return true
	for i in 8:
		var a := TAU * i / 8.0
		var p := feet + Vector3(cos(a) * RING, RING_HEIGHT, sin(a) * RING)
		if not box.has_point(p) and box.intersects_ray(p, back) != null:   # ground under it isn't in view anyway
			return true
	return false
