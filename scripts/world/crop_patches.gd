class_name CropPatches
extends RefCounted
## Tall crops in the flat view, read the way the 3D view reads them (CropClusters): rice and corn
## past the sprout and the vine crops on stakes are drawn as several small pixel plants a cell
## instead of one sprite. The pictures (`stalk:<id>:<growth>:<ripe|growing>:<variant>`), the
## places in the cell, the sizes, the flips, the shades and the variants are CropClusters' own
## (spots_for, a hash of the cell), so a cell grows the same plants in both views and nothing
## jitters. A plant is drawn at its size rounded to whole pixels, feet on its place, plants
## further back first. The tips sway with the wind as the 3D shader's do (sway_tip): the picture is
## cut into a few bands and each band is shifted sideways by whole pixels, the top one the most.

const T := 16
## FarmView and MapView reach this class through load(): their scripts compile in test scripts that
## run before the autoloads exist, and CropClusters (FarmWorld, Game) must not be named there.
const PATH := "res://scripts/world/crop_patches.gd"
const WIND_PATH := "res://data/wind.json"
static var _flat := {}


## The cluster key of a cell's crop key (CropClusters.key_for): "" for a single sprite.
static func cluster_key(crop_key: String) -> String:
	return CropClusters.key_for(crop_key)


## The village paddies' rice key for a season (CropClusters.paddy_key).
static func paddy_key(season: String) -> String:
	return CropClusters.paddy_key(season)


## Draws the clusters of `cells` (cell -> cluster key, CropClusters.key_for / paddy_key) on
## `canvas`. `hold_at(cell)` is how much snow the cell holds and `cover` how much snow lies
## (0..1): a plant stands where the ground under its root is not white, as in the 3D shader
## (SnowLayer.lies). With no hold callable, or no cover, snow hides nothing.
## `sway` is {wind, t} (see sway_now): the tips sway; empty, they stand still.
static func draw(canvas: CanvasItem, cells: Dictionary, hold_at := Callable(), cover := 0.0, sway := {}) -> void:
	for s in standing(cells, hold_at, cover):
		draw_spot(canvas, s, sway)


## The plants that stand (CropClusters.spots_for entries), the further back first, less the ones
## under snow.
static func standing(cells: Dictionary, hold_at := Callable(), cover := 0.0) -> Array[Dictionary]:
	var spots := CropClusters.spots_for(cells)
	spots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pos.z < b.pos.z)
	var out: Array[Dictionary] = []
	for s in spots:
		if cover > 0.0 and hold_at.is_valid() and SnowLayer.lies(Vector2(s.pos.x, s.pos.z), cover * float(hold_at.call(s.cell))):
			continue
		out.append(s)
	return out


## Where a plant's picture goes (a negative width mirrors it): its size rounded to whole pixels,
## the root row on the place, a flat-view pixel a 3D pixel.
static func rect_for(s: Dictionary) -> Rect2:
	var tex := PlaceholderArt.tex(s.tex)
	var w := maxi(1, roundi(tex.get_width() * float(s.size)))
	var h := maxi(1, roundi(tex.get_height() * float(s.size)))
	var foot := Vector2(roundf(s.pos.x * T), roundf(s.pos.z * T))
	# The picture's last row is the rim under the root; the root row stands on the place.
	var rect := Rect2(foot.x - floorf(w / 2.0), foot.y - h + 2, -w if s.flip else w, h)
	if s.flip:   # the rect then runs left from its position
		rect.position.x += w
	return rect


## One plant of CropClusters.spots_for. With a `sway` ({wind, t}) its tip is shifted by whole pixels.
static func draw_spot(canvas: CanvasItem, s: Dictionary, sway := {}) -> void:
	var shade: float = s.shade
	var tex := PlaceholderArt.tex(s.tex)
	var rect := rect_for(s)
	var shifts: Array[int] = []
	if not sway.is_empty() and float(sway.wind) > 0.0:
		shifts = band_shifts(sway_tip(float(sway.wind), float(sway.t), s.pos.x, s.pos.z,
			float(CropClusters.layout(s.key).get("stiff", 1.0))))
	var tint := Color(shade, shade, shade)
	if shifts.is_empty() or shifts.count(0) == shifts.size():
		canvas.draw_texture_rect(tex, rect, false, tint)
		return
	var th := tex.get_height()
	var n := shifts.size()
	for i in n:
		var y0 := th * i / n
		var y1 := th * (i + 1) / n
		var d0 := roundi(rect.size.y * y0 / th)
		var d1 := roundi(rect.size.y * y1 / th)
		if d1 <= d0:
			continue
		var dest := Rect2(rect.position.x + shifts[i], rect.position.y + d0, rect.size.x, d1 - d0)
		canvas.draw_texture_rect_region(tex, dest, Rect2(0, y0, tex.get_width(), y1 - y0), tint)


## The flat-only numbers (data/wind.json "flat"): `rate` sway frames a second, `bands` strips a plant
## is cut into.
static func flat_config() -> Dictionary:
	if _flat.is_empty():
		var f := FileAccess.open(WIND_PATH, FileAccess.READ)
		var d: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		var flat: Dictionary = (d as Dictionary).get("flat", {}) if d is Dictionary else {}
		_flat = {"rate": float(flat.get("rate", 8.0)), "bands": int(flat.get("bands", 4))}
	return _flat


## The sway to hand to draw: the wind and the time kept to the sway's frame rate, so the view
## redraws a few times a second and not every frame. {} when the air is still.
static func sway_now(wind: float, seconds: float) -> Dictionary:
	if wind <= 0.0:
		return {}
	var rate: float = flat_config().rate
	return {"wind": wind, "t": floorf(seconds * rate) / rate}


## How far a plant's very tip is blown sideways, in pixels (not yet rounded): the 3D shader's
## own swing (CropClusters.SWAY units, 1 + 1.5 x wind, the gust swell and the flutter by place, the
## speed 1.3 + 0.9 x wind, the phase by the plant's root x, z) plus its small lean downwind, times
## `stiff` (a vine on a stake sways less). 0 when the air is still.
static func sway_tip(wind: float, t: float, x: float, z: float, stiff := 1.0) -> float:
	if wind <= 0.0:
		return 0.0
	var gust := 1.0 + wind * (0.8 * sin(t * 0.55 + x * 0.25) + 0.4 * sin(t * 1.7 + z * 0.5))
	var ph := t * (1.3 + 0.9 * wind) + x * 0.9 + z * 0.6
	return (sin(ph) * CropClusters.SWAY * (1.0 + 1.5 * wind) * gust + wind * 0.02) * stiff * T


## The whole-pixel shift of each band from the top down: the tip's sway times the shader's height
## weight ((1 - v)^2, v down the picture) at the band's middle, rounded.
static func band_shifts(tip: float, bands := -1) -> Array[int]:
	var n: int = bands if bands > 0 else flat_config().bands
	var out: Array[int] = []
	for i in n:
		var v := (float(i) + 0.5) / float(n)
		out.append(roundi(tip * (1.0 - v) * (1.0 - v)))
	return out
