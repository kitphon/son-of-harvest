class_name SpriteLight
extends RefCounted
## The light of the world on the pixel sprites of the 3D view (the farmer, villagers, animals,
## the dog, the field's objects and the crop clusters). The sprites stay unshaded, so their
## pixels stay as drawn, crisp and evenly lit; two cheap, steady touches tie them to the light
## round them instead (data/light.json "sprites"):
##  - by day a share of the sun's colour by the clock (Game.sun_light): `sun_tint` is the sun's
##    colour over the plain noon sun (`ref`, the measured SUN_COLOR), so noon, the night, rooms,
##    mine floors and clouded days (all the plain colour) are white and leave the picture as it
##    was, and the golden morning and evening take `share` of the sun's warmth (blue and green
##    held back, never brightened, so nothing washes out). Main3D sets it each game minute on
##    every sprite in GROUP (their modulate's colour; its alpha stays the occluders' and the
##    note puffs') and on the CropClusters (their `sun` uniform); a sprite made later takes `now`.
##  - at night a warm lift from the nearby lit windows, shoji doors, stone lanterns and festival
##    lights (`lift_at`, the same spots as NightLamps): NightLights draws each figure near one
##    back over the tint with `warm` times the lift added in proportion to its own colour (its
##    picture's pixels), so a villager by a lit window reads warm, one in the dark stays blue.
## No sun-and-shadow on the sprites: the only cheap scene query is Occluders' boxes, which hold
## the houses but not the trees, the fences or a hip roof's real outline, so a sprite would
## darken where the ground shows no shadow (WORKLOG 2026-11-07 "Sprites take the world's light").

const GROUP := "sun_sprites"

## The sun's share on the sprites now (Main3D sets it each game minute; white until then).
static var now := Color.WHITE


## The rules, data/light.json "sprites" (Game.light_data() in the game; tests pass their own).
static func rules_of(light: Dictionary) -> Dictionary:
	return light.get("sprites", {})


## The colour a sprite is multiplied by for a sun of colour `sun` by `rules`: each channel the
## sun's over the plain sun's (`ref`), at most 1, `share` of the way from white.
static func sun_tint(sun: Color, rules: Dictionary) -> Color:
	var ref := Color(str(rules.get("ref", "ffedcc")))
	var share := clampf(float(rules.get("share", 0.5)), 0.0, 1.0)
	var f := func(s: float, r: float) -> float: return lerpf(1.0, clampf(s / maxf(r, 0.01), 0.0, 1.0), share)
	return Color(f.call(sun.r, ref.r), f.call(sun.g, ref.g), f.call(sun.b, ref.b))


## Makes `s` take the sun's share (FarmWorld.make_sprite does it for every sprite).
static func lit(s: SpriteBase3D) -> void:
	s.add_to_group(GROUP)
	_paint(s, now)


## Keeps `s` as drawn: a mark over the world (the charge pips, the bite's "!", a note puff) or
## something that gives light (the mine lantern).
static func unlit(s: SpriteBase3D) -> void:
	s.remove_from_group(GROUP)
	_paint(s, Color.WHITE)


## Sets the sun's share `c` on every sprite in GROUP and every CropClusters of `tree`.
static func apply(tree: SceneTree, c: Color) -> void:
	now = Color(c.r, c.g, c.b, 1.0)
	for n in tree.get_nodes_in_group(GROUP):
		if n is SpriteBase3D:
			_paint(n, now)
		elif n is CropClusters:
			n.set_sun(now)


static func _paint(s: SpriteBase3D, c: Color) -> void:
	s.modulate = Color(c.r, c.g, c.b, s.modulate.a)


## The lights a figure can take at night: {pos, energy, normal} (normal zero round a lantern or a
## festival light; a window's lit side otherwise) from the lit windows and stone lanterns of
## `worlds` (FarmWorlds, lit `glow`) and the festival lights of `fests` (standing out `dark`), by
## `rules` ("sprites" → "lift"). A window's light sits `out` cells in front of its pane.
static func spots_of(worlds: Array, fests: Array, glow: float, dark: float, rules: Dictionary) -> Array[Dictionary]:
	var lr: Dictionary = rules.get("lift", {})
	var out: Array[Dictionary] = []
	if glow > 0.0:
		var out_w := float(lr.get("out", 0.3))
		for w in worlds:
			for win in w.windows:
				out.append({"pos": win.pos + win.normal * out_w, "energy": float(lr.get("window", 1.0)) * glow,
					"normal": win.normal, "own": win.pos})
			for l in w.lamps:
				out.append({"pos": l.pos, "energy": float(lr.get("lamp", 1.0)) * glow, "normal": Vector3.ZERO, "own": l.pos})
	if dark > 0.05:
		for f in fests:
			for g in f.glows:
				var k := float(lr.get("line", 0.6)) if str(g.get("pool", "round")) == "line" else 1.0
				out.append({"pos": g.pos, "energy": float(lr.get("festival", 0.8)) * dark * k, "normal": Vector3.ZERO, "own": g.pos})
	return out


## How much warm light a figure whose middle is at `at` takes from `spots` (spots_of), 0 ..
## "lift" → max: each spot within `range` cells gives its energy times (1 - distance / range)²,
## a window only to its lit side; `occ` (Occluders, or null) drops a spot a solid building stands
## between (a building faded see-through lets through its fade).
static func lift_at(at: Vector3, spots: Array, rules: Dictionary, occ: Occluders = null) -> float:
	var lr: Dictionary = rules.get("lift", {})
	var reach := maxf(float(lr.get("range", 2.4)), 0.01)
	var k := 0.0
	for s in spots:
		var d := at.distance_to(s.pos)
		if d >= reach:
			continue
		var n: Vector3 = s.normal
		if n != Vector3.ZERO and (at - s.own).dot(n) <= 0.0:
			continue   # behind the window's wall
		var seen := 1.0 if occ == null else NightLights.light_reaches(at, s.own, occ)
		var f := 1.0 - d / reach
		k += float(s.energy) * f * f * seen
	return minf(k, float(lr.get("max", 0.6)))
