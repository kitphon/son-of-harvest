class_name FootBath
extends RefCounted
## The village's footbath (ashiyu) in 3D, map prop `ashiyu` (data/ashiyu.json for its rules,
## Game.soak): a long stone tub of hot spring water over the prop's cells, a cedar bench along
## both long sides of its rim where people sit with their feet in the water; over it the prop
## `ashiyu_roof` (its own, so only the roof fades when it stands between the camera and the
## farmer sat at the tub, the low tub never: Occluders.MIN_HEIGHT): a small board gable roof on
## four posts (Minka.gable, which carries the snow), the ridge along x; steam rises
## off the water (StallWares.Steam, grown to the tub's size), made outside the mesh cache since it
## moves. Our own design (2026-11-20), after the footbaths by stations in Kyoto's hills. Same
## units as MapWorld (1 unit = 1 cell).

const RIM_H := 0.36   # the stone rim's top over the ground
const RIM_W := 0.2    # its width
const WATER_Y := 0.26
const BENCH_Y := 0.44
const ROOF_LOW := 1.55
const WATER := Color("6fa8a0")   # the spring's pale milky green
const CEDAR := Color("a07a52")
const STEAM_SCALE := 4.0
const STEAM_PUFFS := 3   # Steam nodes over the tub


## The tub and its benches over `r` (the prop's cells).
static func build(w: FarmWorld, r: Rect2) -> void:
	var p := FarmProps.Parts.new()
	var x0 := r.position.x + 0.06
	var x1 := r.end.x - 0.06
	var z0 := r.position.y + 0.08
	var z1 := r.end.y - 0.08
	var stone := p.st(OutdoorProps.STONE)
	var top := p.st(OutdoorProps.STONE_LIGHT)
	# The rim: four stone walls round the water, a lighter coping on top.
	for b in [Rect2(x0, z0, x1 - x0, RIM_W), Rect2(x0, z1 - RIM_W, x1 - x0, RIM_W),
			Rect2(x0, z0 + RIM_W, RIM_W, z1 - z0 - RIM_W * 2), Rect2(x1 - RIM_W, z0 + RIM_W, RIM_W, z1 - z0 - RIM_W * 2)]:
		FarmProps.block(stone, b, 0.0, b, RIM_H - 0.04)
		FarmProps.block(top, b.grow(0.015), RIM_H - 0.04, b.grow(0.015), RIM_H)
	# The water inside, a little below the rim.
	var inner := Rect2(x0 + RIM_W, z0 + RIM_W, x1 - x0 - RIM_W * 2, z1 - z0 - RIM_W * 2)
	FarmProps.block(p.st(WATER), inner, 0.0, inner, WATER_Y)
	# Cedar benches along both long sides, on the rim.
	var wood := p.st(CEDAR)
	for z in [z0 - 0.04, z1 - RIM_W + 0.02]:
		var seat := Rect2(x0 + 0.1, z, x1 - x0 - 0.2, RIM_W + 0.02)
		FarmProps.block(wood, seat, RIM_H, seat, BENCH_Y)
	p.commit(w)


## The four posts at the tub's corners and the board roof over `r` (the `ashiyu_roof` prop's cells).
static func roof(w: FarmWorld, r: Rect2) -> void:
	var p := FarmProps.Parts.new()
	var x0 := r.position.x + 0.06
	var x1 := r.end.x - 0.06
	var z0 := r.position.y + 0.08
	var z1 := r.end.y - 0.08
	var timber := p.st(OutdoorProps.TIMBER)
	for c in [Vector2(x0 + 0.04, z0 + 0.04), Vector2(x1 - 0.04, z0 + 0.04), Vector2(x0 + 0.04, z1 - 0.04), Vector2(x1 - 0.04, z1 - 0.04)]:
		FarmProps.block(timber, Rect2(c.x - 0.05, c.y - 0.05, 0.1, 0.1), 0.0, Rect2(c.x - 0.04, c.y - 0.04, 0.08, 0.08), ROOF_LOW + 0.05)
	var eave := Rect2(r.position.x - 0.18, r.position.y - 0.18, r.size.x + 0.36, r.size.y + 0.36)
	var crest := Minka.gable(w, eave, ROOF_LOW, 0.5, 0.05, "build:planks_dark", "build:planks_dark")
	var mid_z := r.get_center().y
	FarmProps.block(timber, Rect2(eave.position.x - 0.02, mid_z - 0.05, eave.size.x + 0.04, 0.1), crest - 0.03,
		Rect2(eave.position.x - 0.02, mid_z - 0.035, eave.size.x + 0.04, 0.07), crest + 0.06)
	p.commit(w)


## Steam off the water: a few grown Steam nodes along the tub, each out of step (MapWorld adds it
## after the cached meshes). Returns them (for tests).
static func steam(w: Node3D, r: Rect2) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for k in STEAM_PUFFS:
		var s := StallWares.Steam.new(int(r.position.x) * 7 + k * 31)
		s.scale = Vector3.ONE * STEAM_SCALE
		# Over the tub's far half (+z, toward the eye) and its ends, clear of the bench people sit on.
		s.position = Vector3(r.position.x + r.size.x * [0.15, 0.85, 0.5][k % 3], WATER_Y + 0.15, r.get_center().y + [0.35, 0.35, 0.55][k % 3])
		s.name = "FootBathSteam%d" % k
		w.add_child(s)
		out.append(s)
	return out
