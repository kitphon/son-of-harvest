class_name DappleRules
extends RefCounted
## Sunlight through leaves (komorebi) on a map under the wood's canopy (2026-11-25, the user: make
## Kajika-yu shadier). A map's `shade` (MapData.shade, data/maps): `dapple` how strongly the leaf
## shadows lie on its ground and water (0 none .. 1), `dapple_color` the colour they multiply the
## picture by in the deepest shade; the flecks between them keep the picture's own light. They come
## and go with the sun's shadows (Game.sun_shadow: none at night, in rain or under cloud) and drift
## slowly as the leaves stir. The 3D view lays them as one multiplying sheet over the ground
## (DappleLayer, its own shader with the same pattern); the flat view draws them in whole 4-pixel
## blocks (DappleView). Pure: nothing here draws.

const BLOCK := 4   # the flat view's pixels a block

## How strong the dapples are now on map `m` (0..1): its `dapple` times the sun's shadows; none
## indoors, under rock or without a clock (`game` the Game autoload).
static func strength(game: Object, m: MapData) -> float:
	if game == null or m == null or m.indoor or m.sheltered:
		return 0.0
	return clampf(float(m.shade.get("dapple", 0.0)) * float(game.sun_shadow()), 0.0, 1.0)


## The leaf shadows' own colour on map `m` (what the deepest shade multiplies by).
static func shade_color(m: MapData) -> Color:
	return Color(str(m.shade.get("dapple_color", "b8c8a8"))) if m != null else Color.WHITE


## The light at plan point `p` (cells) at time `t` (seconds): 0 in the leaves' shadow, 1 in a fleck
## of sun between them, a short soft edge (the 3D shader draws the same).
static func light_at(p: Vector2, t: float) -> float:
	var q := p * 0.9 + Vector2(t * 0.05, t * 0.02)
	var n := 0.6 * VistaRules.noise(q) + 0.4 * VistaRules.noise(q * 2.3 + Vector2(7.1, 3.3))
	return smoothstep(0.58, 0.68, n)


## What the picture at `p` is multiplied by now: the shade's colour in the leaves' shadow, white in
## the flecks, eased toward white by `strength`.
static func multiply_at(p: Vector2, t: float, strength_now: float, shade: Color) -> Color:
	var c := shade.lerp(Color.WHITE, light_at(p, t))
	return Color.WHITE.lerp(c, clampf(strength_now, 0.0, 1.0))
