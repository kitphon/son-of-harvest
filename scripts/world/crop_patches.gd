class_name CropPatches
extends RefCounted
## Tall crops in the flat view, read the way the 3D view reads them (CropClusters): rice and corn
## past the sprout and the vine crops on stakes are drawn as several small pixel plants a cell
## instead of one sprite. The pictures (`stalk:<id>:<growth>:<ripe|growing>:<variant>`), the
## places in the cell, the sizes, the flips, the shades and the variants are CropClusters' own
## (spots_for, a hash of the cell), so a cell grows the same plants in both views and nothing
## jitters. A plant is drawn at its size rounded to whole pixels, feet on its place, plants
## further back first. There is no sway here. The winter water patches of the village paddies
## (CropClusters.water_spots_for, data/paddy.json) lie under the stubble as flat pixel blobs.

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


const WATER_W := 12
const WATER_H := 5
static var _water_tex: Texture2D = null


## Draws the winter water patches of `cells` (paddy cell -> key) under the stubble, in `season`
## only (CropClusters.water_on). The places are CropClusters.water_spots_for's, as in 3D; a patch
## is left out where snow lies on its cell (`hold_at` and `cover` as in draw).
static func draw_water(canvas: CanvasItem, season: String, cells: Dictionary, hold_at := Callable(), cover := 0.0) -> void:
	for s in water_to_draw(season, cells, hold_at, cover):
		draw_water_spot(canvas, s)


## The water patches that show: none outside water_on seasons, else the ones not under snow.
static func water_to_draw(season: String, cells: Dictionary, hold_at := Callable(), cover := 0.0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not CropClusters.water_on(season):
		return out
	for s in CropClusters.water_spots_for(cells.keys()):
		if cover > 0.0 and hold_at.is_valid() and SnowLayer.lies(Vector2(s.pos.x, s.pos.z), cover * float(hold_at.call(s.cell))):
			continue
		out.append(s)
	return out


## One water patch: the blob's picture at the spot's size in whole pixels, centred on the place
## (a flat patch on the ground, so its centre is the place), mirrored by its flip, shaded.
static func draw_water_spot(canvas: CanvasItem, s: Dictionary) -> void:
	var tex := water_texture()
	var w := maxi(1, roundi(WATER_W * float(s.size)))
	var h := maxi(1, roundi(WATER_H * float(s.size)))
	var c := Vector2(roundf(s.pos.x * T), roundf(s.pos.z * T))
	var rect := Rect2(c.x - floorf(w / 2.0), c.y - floorf(h / 2.0), -w if s.flip else w, h)
	if s.flip:
		rect.position.x += w
	var shade: float = s.shade
	canvas.draw_texture_rect(tex, rect, false, Color(shade, shade, shade))


## The water patch's picture, cut once from data/paddy.json's colours: a pixel oval 12 x 5 in the
## grey-blue, a paler glint on its upper middle and the strip where the grey sky shows on it,
## the same shapes as the 3D picture patch:paddy_water (PlaceholderArt._paddy_water).
static func water_texture() -> Texture2D:
	if _water_tex == null:
		var d: Dictionary = CropClusters.paddy_data().get("water", {})
		var base := Color(String(d.get("color", "5d7680")))
		var glint := Color(String(d.get("glint", "7d939b")))
		var sky := Color(String(d.get("sky", "9aaeb4")))
		var img := Image.create(WATER_W, WATER_H, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in WATER_H:
			for x in WATER_W:
				var px := x + 0.5
				var py := y + 0.5
				if pow((px - 6.0) / 6.0, 2) + pow((py - 2.5) / 2.5, 2) > 1.0:
					continue
				var c := base
				if pow((px - 6.5) / 3.5, 2) + pow((py - 2.0) / 1.0, 2) <= 1.0:
					c = glint
				if y == 2 and (x == 4 or x == 5):
					c = sky
				img.set_pixel(x, y, c)
		_water_tex = ImageTexture.create_from_image(img)
	return _water_tex
