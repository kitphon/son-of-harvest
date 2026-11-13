class_name CicadaArt
extends RefCounted
## The cicadas as tiny pixel sprites, drawn in code (our own designs): the day cicada (semi) with a
## dark green-black body and the evening cicada (higurashi) with an amber one, both with clear
## pale wings folded like a tent over the back, so they read as a pale spot on the dark bark. Keys
## "cicada:<kind>:<pose>:<frame>[:r]" (PlaceholderArt hands them here).
##
## - Pose "cling", 4 x 6 px, seen from behind clinging head-up to a trunk: two dark eyes either
##   side of the head on the top row, the body down the middle between the folded wings, the
##   wing tips meeting at the bottom. Frame 1 is the body pumping as it sings (the wing tips part
##   a pixel and the body shows lighter at the tail).
## - Pose "fly", 5 x 4 px, seen from above: frame 0 wings forward, frame 1 back (swapped fast so
##   they blur).
## - Drawn facing screen-left; ":r" is the picture mirrored (the pictures are nearly symmetric).
##   Lit from the upper left as the other small life is: the left wing's edge the lit colour.
##   Colours (RRGGBB or RRGGBBAA hex) in data/cicadas.json "art". Each picture is a pure function
##   of its key.

const SIZES := {"cling": Vector2i(4, 6), "fly": Vector2i(5, 4)}
const POSES := {"cling": 2, "fly": 2}

## Rows of one letter a pixel ("." empty): e eye, h head, b body, w wing, l lit wing, v wing vein.
const GRIDS := {
	"cling:0": ["ehhe", "lbbw", "lbbv", "lwwv", "lwwv", ".vv."],
	"cling:1": ["ehhe", "lbbw", "lbbv", "lwhv", "lw.v", "v..v"],
	"fly:0": ["l.e.l", "lwbwv", ".vbv.", "..b.."],
	"fly:1": [".hhh.", "lwbwv", "lwbwv", "v.b.v"],
}


## The picture of a cicada of `kind` (semi, higurashi) in `pose` (facing left, or mirrored when
## `right`).
static func make(kind: String, pose: String, frame: int, right := false) -> Image:
	var p := pose if SIZES.has(pose) else "cling"
	var rows: Array = GRIDS.get("%s:%d" % [p, frame], GRIDS["%s:0" % p])
	var size: Vector2i = SIZES[p]
	var arts: Dictionary = CicadaRules.config().art
	var art: Dictionary = arts.get(kind, arts.semi)
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		var row := str(rows[y]) if y < rows.size() else ""
		for x in size.x:
			var ch := row[x] if x < row.length() else "."
			if ch != ".":
				img.set_pixel(x, y, colour(ch, art))
	if right:
		img.flip_x()
	return img


static func size_of(pose: String) -> Vector2i:
	return SIZES.get(pose, SIZES.cling)


## How many frames a pose has (0 for a pose there is none of).
static func frames(pose: String) -> int:
	return int(POSES.get(pose, 0))


static func colour(ch: String, art: Dictionary) -> Color:
	match ch:
		"e": return Color(str(art.eye))
		"h": return Color(str(art.head))
		"b": return Color(str(art.body))
		"l": return Color(str(art.lit))
		"v": return Color(str(art.vein))
		_: return Color(str(art.wing))
