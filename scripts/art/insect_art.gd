class_name InsectArt
extends RefCounted
## The small flying insects as pixel sprites, drawn in code (our own designs): a cabbage-white-like
## butterfly in white or pale yellow a red dragonfly (akatombo) with clear pale wings and a honeybee. Keys
## "insect:<kind>:<pose>:<frame>[:r]" (PlaceholderArt hands them here); kinds butterfly,
## butterfly_y (the pale yellow one) and dragonfly.
##
## - Butterfly, pose "fly", 5 x 4 px: frame 0 wings raised (seen from the side), frame 1 wings
##   spread. The dark tips and the body are the only dark pixels, so a white one reads on the
##   grass and a yellow one on the crops.
## - Bee, pose "fly", 5 x 3 px: a striped amber and dark body 3 px long behind a dark head,
##   pale wings up (frame 0) or down (frame 1), swapped fast so they blur.
## - Dragonfly: pose "fly", 8 x 5 px, a red body 6 px long (eyes, thorax, abdomen) with clear
##   pale wings that catch the light: frame 0 wings up, frame 1 wings out level (swapped fast in
##   a hover so they blur); pose "perch", 8 x 5 px: the legs on the bottom row, the wings flat.
## - Drawn facing screen-left, the head at the left; ":r" is the picture mirrored. Lit from the
##   upper left as the figures and birds are: the left and upper pixels of a part lighter, the
##   lower right darker. Colours (RRGGBB or RRGGBBAA hex) in data/insects.json "art". Each picture
##   is a pure function of its key.

const SIZES := {"butterfly": Vector2i(5, 4), "butterfly_y": Vector2i(5, 4), "dragonfly": Vector2i(8, 5), "bee": Vector2i(5, 3)}
const POSES := {
	"butterfly": {"fly": 2}, "butterfly_y": {"fly": 2},
	"dragonfly": {"fly": 2, "perch": 1}, "bee": {"fly": 2},
}

## Rows of one letter a pixel ("." empty), per kind, pose and frame. Butterfly: w wing, l lit wing,
## s shaded wing, t wing tip, b body. Dragonfly: e eye, o thorax (lit), b abdomen, d abdomen tip
## (shade), w wing, l lit wing, v wing vein, k leg.
const GRIDS := {
	"butterfly:fly:0": [".tl..", ".lww.", ".wws.", "..b.."],
	"butterfly:fly:1": ["tl.wt", "lwbws", ".sbs.", "..b.."],
	"bee:fly:0": ["..lw.", "hybyd", "....."],
	"bee:fly:1": [".....", "hybyd", ".lww."],
	"dragonfly:fly:0": ["..l.w...", ".lwvww..", "..wwww..", "eeobbbbd", "........"],
	"dragonfly:fly:1": ["........", "..l.....", ".lwvwww.", "eeobbbbd", "..wwww.."],
	"dragonfly:perch:0": ["........", ".lwvwww.", "eeobbbbd", "..wwww..", ".kk.k..."],
}


## The picture of an insect (facing left, or mirrored when `right`).
static func make(kind: String, pose: String, frame: int, right := false) -> Image:
	var base := "butterfly" if kind == "butterfly_y" else kind
	var rows: Array = GRIDS.get("%s:%s:%d" % [base, pose, frame], GRIDS["%s:fly:0" % base])
	var size: Vector2i = SIZES[kind]
	var art: Dictionary = (InsectRules.config().art as Dictionary)[kind]
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		var row := str(rows[y]) if y < rows.size() else ""
		for x in size.x:
			var ch := row[x] if x < row.length() else "."
			if ch != ".":
				img.set_pixel(x, y, _colour(base, ch, art))
	if right:
		img.flip_x()
	return img


static func size_of(kind: String) -> Vector2i:
	return SIZES[kind]


## How many frames a pose has (0 for a pose the kind does not have).
static func frames(kind: String, pose: String) -> int:
	return int((POSES.get(kind, {}) as Dictionary).get(pose, 0))


static func _colour(base: String, ch: String, art: Dictionary) -> Color:
	if base == "butterfly":
		match ch:
			"l": return Color(str(art.lit))
			"s": return Color(str(art.shade))
			"t": return Color(str(art.tip))
			"b": return Color(str(art.body))
			_: return Color(str(art.wing))
	if base == "bee":
		match ch:
			"h": return Color(str(art.head))
			"y": return Color(str(art.amber))
			"b": return Color(str(art.stripe))
			"d": return Color(str(art.tip))
			"l": return Color(str(art.wing_lit))
			_: return Color(str(art.wing))
	match ch:
		"e": return Color(str(art.eye))
		"o": return Color(str(art.body_lit))
		"d": return Color(str(art.body_shade))
		"l": return Color(str(art.wing_lit))
		"v": return Color(str(art.wing_vein))
		"k": return Color(str(art.leg))
		"w": return Color(str(art.wing))
		_: return Color(str(art.body))
