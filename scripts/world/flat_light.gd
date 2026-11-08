class_name FlatLight
extends RefCounted
## The world's light on the flat view's pictures (the farmer, villagers, animals, the dog, the
## field's crops and plants, items lying or flying, forage and story props), by the 3D view's own
## rules (SpriteLight, data/light.json "sprites"); nothing here has numbers of its own but the
## night tint's floor ("sprites" → "lift" → "flat_floor"):
##  - by day the sun's share (SpriteLight.sun_tint of Game.sun_light): golden in the morning and
##    evening, plain at noon, at night, indoors, down the mine and under cloud.
##  - at night the warm lift of the lit windows, shoji doors, stone lanterns and festival lights
##    near the picture (SpriteLight.spots_of the map's NightView spots, SpriteLight.lift_at at the
##    picture's middle, the same height the 3D sprite's middle stands at). The 3D view adds
##    `warm` x lift x the picture's own colour over the tinted picture; here the picture is drawn
##    with a modulate that does the same under the CanvasModulate: own x sun x (1 + warm x lift /
##    tint), so after the tint it is own x sun x tint + own x sun x warm x lift. A modulate only
##    touches the picture's own pixels, so whatever stands in front keeps its own.
## The flat view has no buildings in the way of a light (no Occluders), as its pools.
## main_2d sets the light each game minute (`update`); the views draw with `at` / `at_mid`, and
## the ones in GROUP are redrawn when it changes. The marks over the world (the charge pips, the
## bite's "!", a note puff, the mine lantern) keep their pictures.
## The 3D scripts it reads (SpriteLight, FarmWorld, AnimalLayer) name the Game autoload, so they
## are loaded when first used: the views that use this can be compiled before the autoloads.

const T := 16
const GROUP := "flat_lit"   # CanvasItems whose pictures take the light (redrawn when it changes)

## The light now (white and none until main_2d sets it).
static var sun := Color.WHITE        # SpriteLight.sun_tint now
static var spots: Array = []         # SpriteLight.spots_of the map's lights burning now
static var tint := Color.WHITE       # the night tint (the flat view's CanvasModulate)
static var rules: Dictionary = {}    # data/light.json "sprites"
static var _sl: GDScript             # SpriteLight, loaded when first used


static func _sprite_light() -> GDScript:
	if _sl == null:
		_sl = load("res://scripts/world3d/sprite_light.gd")
	return _sl


## The 3D view's world units a picture pixel, by kind (`mid`): a figure (farmer, villager), the
## field (crops, items, forage, story props) and the animals.
static func figure_px() -> float:
	return load("res://scripts/world3d/farm_world.gd").FIGURE_PX


static func field_px() -> float:
	return load("res://scripts/world3d/farm_world.gd").PX


static func animal_px() -> float:
	return load("res://scripts/world3d/animal_layer.gd").ANIMAL_PX


## The 3D point a picture's light is measured at: its feet in the flat view's pixels (x east,
## y south), up half its height, `height` picture pixels at the 3D view's `px` world units a
## pixel (FarmWorld.FIGURE_PX for a figure, FarmWorld.PX for the field, AnimalLayer.ANIMAL_PX).
static func mid(feet: Vector2, height: float, px: float) -> Vector3:
	return Vector3(feet.x / T, height * px / 2.0, feet.y / T)


## The modulate of a picture under the sun's share `sun_c` and a night lift `k` (SpriteLight.lift_at)
## by `r` ("sprites"), drawn under the night tint `tint_c`: sun x (1 + warm x k / tint) per
## channel (the tint at least lift.flat_floor, as NightView's shader divides it).
static func color_for(sun_c: Color, k: float, r: Dictionary, tint_c: Color) -> Color:
	if k <= 0.0:
		return Color(sun_c.r, sun_c.g, sun_c.b)
	var lr: Dictionary = r.get("lift", {})
	var warm := Color(str(lr.get("color", "ffa050")))
	var low := float(lr.get("flat_floor", 0.05))
	var f := func(s: float, w: float, t: float) -> float: return s * (1.0 + w * k / maxf(t, low))
	return Color(f.call(sun_c.r, warm.r, tint_c.r), f.call(sun_c.g, warm.g, tint_c.g), f.call(sun_c.b, warm.b, tint_c.b))


## The lit spots of a flat map's NightView `night` (its windows and lanterns, lit `glow`, and its
## festival lights, standing out `dark`), as SpriteLight.spots_of makes them for the 3D view.
static func spots_from(night: Object, glow: float, dark: float, r: Dictionary) -> Array[Dictionary]:
	if night == null:
		return []
	return _sprite_light().spots_of([night], [{"glows": night.festival_lights}], glow, dark, r)


## Sets the light now; true when it changed (the views in GROUP are then redrawn).
static func update(sun_c: Color, spots_now: Array, tint_c: Color, r: Dictionary) -> bool:
	var s := Color(sun_c.r, sun_c.g, sun_c.b)
	var changed := not s.is_equal_approx(sun) or not tint_c.is_equal_approx(tint) or spots_now != spots or r != rules
	sun = s
	spots = spots_now
	tint = tint_c
	rules = r
	return changed


## The modulate of a picture whose middle is at `at` (map units, y up) in the light now.
static func at_mid(at: Vector3) -> Color:
	if spots.is_empty():
		return sun
	var k: float = _sprite_light().lift_at(at, spots, rules)
	return color_for(sun, k if k > 0.01 else 0.0, rules, tint)


## at_mid for a picture with its feet at `feet` (flat pixels), `height` pixels tall at `px` (mid).
static func at(feet: Vector2, height: float, px: float) -> Color:
	return at_mid(mid(feet, height, px))


## Back to plain light (a test, a view without main_2d).
static func reset() -> void:
	update(Color.WHITE, [], Color.WHITE, {})
