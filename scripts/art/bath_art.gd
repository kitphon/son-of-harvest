class_name BathArt
extends RefCounted
## The public bath's own pictures (Kawasemi-yu, data/maps/sento.json; 2026-11-22, Baths step 2):
## `tile` the glazed tiles of the tub and the washing island (16 x 16: four rows of pale tiles,
## grey grout, a glaze glint), `mural` the mountain painted across the bath's back wall (192 x 32):
## our own Ogura (data/vista.json), a broad forested mountain over the river under a clear sky,
## in the flat bright colours of a bathhouse painting. PlaceholderArt "bath:<tile|mural>".

const TILE := Color("d8e4e6")
const TILE_SHADE := Color("c4d2d6")
const GROUT := Color("8f9ea2")
const GLAZE := Color("f4fafa")


static func make(kind: String) -> Image:
	match kind:
		"tile":
			return tile()
		"mural":
			return mural()
	return Image.create(1, 1, false, Image.FORMAT_RGBA8)


## Four rows of four-pixel tiles, every other row half a tile over, a glint on each tile's top left.
static func tile() -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(TILE)
	for row in 4:
		var y := row * 4
		var off := (row % 2) * 2
		img.fill_rect(Rect2i(0, y + 3, 16, 1), GROUT)
		for k in 5:
			var x := (k * 4 + off) % 16
			img.fill_rect(Rect2i(x, y, 1, 3), GROUT)
			img.set_pixel((x + 1) % 16, y, GLAZE)
			img.set_pixel((x + 2) % 16, y + 2, TILE_SHADE)
	return img


## The mountain on the bath's wall: a sky paling to the horizon with two soft clouds, a far blue
## ridge, Ogura's broad green mass with darker forest bands and lit slopes on the left, a line of
## pines along its foot, the river along the bottom with white ripples.
static func mural() -> Image:
	var w := 192
	var h := 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var sky_top := Color("5f9ed8")
	var sky_low := Color("cfe6f2")
	for y in h:
		img.fill_rect(Rect2i(0, y, w, 1), sky_top.lerp(sky_low, clampf(y / 16.0, 0.0, 1.0)))
	for cl in [[34, 5, 22], [128, 7, 28]]:   # two soft clouds
		for i in 3:
			img.fill_rect(Rect2i(cl[0] + i * 4, cl[1] - (1 if i == 1 else 0), cl[2] - i * 6, 2), Color("f6fafc"))
	# The far ridge: low, blue-grey, along the whole width.
	for x in w:
		var top := 15 + roundi(2.0 * sin(x * 0.07) + 1.5 * sin(x * 0.19 + 1.0))
		img.fill_rect(Rect2i(x, top, 1, h - top), Color("8aa4b8"))
	# Ogura: a broad dome left of the middle, its shoulder running off to the right.
	var green := Color("4e8a4a")
	var dark := Color("35663a")
	var lit := Color("74a85c")
	for x in w:
		var u := (x - 70.0) / 70.0
		var top := 6.0 + 10.0 * u * u + 1.2 * sin(x * 0.3)
		if x > 120:
			top = minf(top, 15.0 + 1.5 * sin(x * 0.25))
		var t := clampi(roundi(top), 4, h)
		for y in range(t, h):
			var col := green
			if (y - t) % 6 == 4 or (x * 7 + y * 3) % 23 == 0:
				col = dark
			elif x < 70 and y - t < 3:
				col = lit   # the slopes lit from the left
			img.set_pixel(x, y, col)
	# The pines along the foot.
	for k in 26:
		var x := 4 + k * 7 + (k * 5) % 3
		var base := 26
		for i in 5:
			img.fill_rect(Rect2i(x - i / 2, base - 5 + i, 1 + (i / 2) * 2, 1), Color("244a2e"))
	# The river along the bottom.
	img.fill_rect(Rect2i(0, 27, w, 5), Color("5aa0c8"))
	for k in 18:
		var x := (k * 11 + 3) % w
		img.fill_rect(Rect2i(x, 28 + k % 3, 4, 1), Color("e8f4fa"))
	return img
