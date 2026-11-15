class_name KoiPondArt
extends RefCounted
## The temple pond's koi seen from above, as pixel pictures drawn in code (our own designs).
## Keys "pondkoi:<pattern>:<frame>" (PlaceholderArt hands them here), 16 x 7 px, the fish facing
## +x (its head at the right, the tail fin at the left), frame 0 / 1 / 2 the tail bent up,
## straight, down (KoiPondRules.frame_of). Patterns (data/koi.json `patterns`): kohaku white with
## red patches, orange, ogon gold, showa black with red and white, shiro cream, asagi blue-grey
## with orange flanks. A paler line along the back where the light catches it; the pectoral fins a
## pale pair behind the head. Each picture is a pure function of its key.

const W := 16
const H := 7
## The body's half width (pixels either side of the middle row) at each x from the tail's root (4)
## to the snout (14).
const HALF := {4: 0, 5: 1, 6: 1, 7: 2, 8: 2, 9: 2, 10: 2, 11: 2, 12: 1, 13: 1, 14: 0}
## [base, patch, back light] per pattern, patches on the x ranges in PATCHES.
const COLOURS := {
	"kohaku": [Color("f2eee6"), Color("d8402a"), Color("ffffff")],
	"orange": [Color("ec7a2c"), Color("d8602a"), Color("f6a050")],
	"ogon": [Color("e2b848"), Color("d0a038"), Color("f8e08c")],
	"showa": [Color("2c2826"), Color("cc3c2a"), Color("f0ece4")],
	"shiro": [Color("eee8da"), Color("e4dccb"), Color("ffffff")],
	"asagi": [Color("7e94a6"), Color("d8783a"), Color("a8bccb")],
}
const PATCHES := {"kohaku": [[6, 8], [10, 13]], "orange": [], "ogon": [], "showa": [[5, 6], [9, 11]], "shiro": [], "asagi": []}
const FIN := Color(0.96, 0.94, 0.9, 0.75)


static func make(pattern: String, frame: int) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cols: Array = COLOURS.get(pattern, COLOURS.orange)
	var patches: Array = PATCHES.get(pattern, [])
	var bend := frame - 1   # -1 up, 0 straight, 1 down
	var mid := 3
	# the tail fin: a fan at x 0..3, shifted by the bend (more at its tip)
	for x in 4:
		var y0 := mid + (bend if x < 2 else (bend if x == 2 and bend != 0 else 0))
		var spread := 3 - x   # widest at the tip
		for dy in range(-mini(spread, 2), mini(spread, 2) + 1):
			var y := y0 + dy
			if y >= 0 and y < H:
				var tone: Color = cols[0]
				img.set_pixel(x, y, Color(tone.r, tone.g, tone.b, 0.8 if absi(dy) == 2 else 0.95))
	# the body
	for x in HALF:
		var hw: int = HALF[x]
		var shift := bend if x == 4 else 0
		for dy in range(-hw, hw + 1):
			var y := mid + dy + shift
			var tone: Color = cols[0]
			for p in patches:
				if x >= int(p[0]) and x <= int(p[1]) and (dy <= 0 or pattern == "showa"):
					tone = cols[1]
			if pattern == "asagi" and absi(dy) == hw and hw > 0:
				tone = cols[1]
			if dy == 0 and x >= 6 and x <= 12:
				tone = tone.lerp(cols[2], 0.5)   # the light along the back
			img.set_pixel(x, y, tone)
	# the head's tip a shade darker, the pectoral fins behind it
	var head: Color = cols[0]
	img.set_pixel(14, mid, head.darkened(0.12))
	img.set_pixel(11, mid - 3, FIN)
	img.set_pixel(11, mid + 3, FIN)
	img.set_pixel(10, mid - 3, FIN)
	img.set_pixel(10, mid + 3, FIN)
	return img
