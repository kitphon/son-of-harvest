class_name Kakehi
extends RefCounted
## The bamboo spout (kakehi) pouring the hot spring's water into Kajika-yu's pool (2026-11-28, the
## user asked for the pool to feel more alive: a focal point, the sound of water). A map prop
## `kakehi` on the bank with `dir` (up / down / left / right: toward the water): a culm runs out of
## a mossy stone at the back of its cell, over the bank on a crossed bamboo stand, and its open end
## hangs REACH cells out over the water, where a thin stream falls in an arc to the water (LANDING
## out from the mouth), white foam and a ring spreading from there every RING_EVERY seconds, and
## the pouring sound (data/sfx.json amb_spout, the ambient rule's `near_prop`) near it. Pure
## numbers here, so both views read them: BathProps / KakehiFlow in 3D, BathLook flat.

const KIND := "kakehi"
const REACH := 1.35        # cells from the cell's centre out to the open end, over the water
const BACK := 0.3          # cells back from the centre, where the culm leaves its stone
const BACK_Y := 0.62       # the culm's height there, units
const MOUTH_Y := 0.42      # its open end's height (it slopes down to the water)
const LANDING := 0.36      # cells out past the mouth the stream meets the water
const RING_EVERY := 0.7    # seconds between the rings spreading from where it falls
const DIRS := {"up": Vector2.UP, "down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT}


## The way a spout prop `p` points (toward the water), as a unit vector in cells.
static func dir_of(p: Dictionary) -> Vector2:
	return DIRS.get(str(p.get("dir", "down")), Vector2.DOWN)


## Spout prop `p`'s places in cells (x, z on the map): {back, stand, mouth, landing, dir}.
static func places(p: Dictionary) -> Dictionary:
	var d := dir_of(p)
	var mid := Vector2(p.cell) + Vector2(0.5, 0.5)
	var mouth := mid + d * REACH
	return {"dir": d, "back": mid - d * BACK, "stand": mid + d * 0.45, "mouth": mouth, "landing": mouth + d * LANDING}


## Every spout on map `m`, as places().
static func spouts_of(m: MapData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if m == null:
		return out
	for p in m.props:
		if str(p.get("kind", "")) == KIND:
			out.append(places(p))
	return out


## Where spout `at` (places())'s stream is `t` (0 at the open end, 1 on the water whose top is
## `water_y`) along its fall: out along the culm's way, dropping faster and faster (a thrown arc).
static func arc_at(at: Dictionary, water_y: float, t: float) -> Vector3:
	var flat: Vector2 = (at.mouth as Vector2).lerp(at.landing, t)
	return Vector3(flat.x, lerpf(MOUTH_Y, water_y, t * t), flat.y)


## How many rings are due between clock `from` and `to` (seconds): one every RING_EVERY.
static func rings_between(from: float, to: float) -> int:
	return maxi(floori(to / RING_EVERY) - floori(from / RING_EVERY), 0)
