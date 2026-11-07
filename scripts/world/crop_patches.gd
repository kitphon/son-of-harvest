class_name CropPatches
extends RefCounted
## Tall crops in the flat view, read the way the 3D view reads them (CropClusters): rice and corn
## past the sprout and the vine crops on stakes are drawn as several small pixel plants a cell
## instead of one sprite. The pictures (`stalk:<id>:<growth>:<ripe|growing>:<variant>`), the
## places in the cell, the sizes, the flips, the shades and the variants are CropClusters' own
## (spots_for, a hash of the cell), so a cell grows the same plants in both views and nothing
## jitters. A plant is drawn at its size rounded to whole pixels, feet on its place, plants
## further back first. There is no sway here.

const T := 16
## FarmView and MapView reach this class through load(): their scripts compile in test scripts that
## run before the autoloads exist, and CropClusters (FarmWorld, Game) must not be named there.
const PATH := "res://scripts/world/crop_patches.gd"


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
static func draw(canvas: CanvasItem, cells: Dictionary, hold_at := Callable(), cover := 0.0) -> void:
	for s in standing(cells, hold_at, cover):
		draw_spot(canvas, s)


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


## One plant of CropClusters.spots_for.
static func draw_spot(canvas: CanvasItem, s: Dictionary) -> void:
	var shade: float = s.shade
	canvas.draw_texture_rect(PlaceholderArt.tex(s.tex), rect_for(s), false, Color(shade, shade, shade))
