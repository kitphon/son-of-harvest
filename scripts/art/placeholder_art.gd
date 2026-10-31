class_name PlaceholderArt
extends RefCounted
## Small pixel textures made in code, so the game runs before there is real art.
## Replace each key with a real sprite file later.

static var _cache := {}


static func tex(key: String) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_make(key))
	return _cache[key]


static func _make(key: String) -> Image:
	var parts := key.split(":")
	match parts[0]:
		"player":   # player:<front|back>:<idle|walk|run>:<frame>
			return _player(parts[1] == "back", parts[2], int(parts[3]))
		"rock":
			return _draw(16, 16, [[2, 8, 12, 8, "8a8a8a"], [4, 6, 8, 3, "9e9e9e"], [4, 9, 4, 2, "c0c0c0"]])
		"branch":
			return _draw(16, 16, [[1, 12, 9, 2, "7a5230"], [7, 10, 8, 2, "7a5230"], [5, 9, 2, 3, "5e3d1e"]])
		"weed":
			return _draw(16, 16, [[3, 8, 2, 8, "3e7a2a"], [7, 5, 2, 11, "4f8f35"], [11, 8, 2, 8, "3e7a2a"],
				[5, 10, 2, 6, "4f8f35"], [9, 9, 2, 7, "3e7a2a"]])
		"stump":
			return _draw(16, 16, [[3, 6, 10, 10, "5e3d1e"], [3, 6, 10, 2, "a07a4a"], [1, 14, 14, 2, "4a2e14"]])
		"crop":
			return _crop(int(parts[1]), parts[2] == "ripe")
	return _draw(16, 16, [[0, 0, 16, 16, "ff00ff"]])


## rects = [[x, y, w, h, "rrggbb"], ...] on a transparent w x h image.
static func _draw(w: int, h: int, rects: Array) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for r in rects:
		img.fill_rect(Rect2i(r[0], r[1], r[2], r[3]), Color(r[4]))
	return img


## Farmer frames, 16 x 24: head and torso from a pixel map, legs and hands placed per frame.
const _FARMER_COLORS := {
	"o": "2a1e1e", "h": "c8452c", "H": "8e2c1c", "s": "f2c79b", "S": "d29a6e", "e": "2a2a3a",
	"r": "6b4423", "R": "4e3018", "b": "3b6fd1", "B": "2a50a0", "d": "34426a", "y": "d9b45a",
	"k": "5e3d1e",
}
const _FARMER_FRONT := [
	"....oooooooo....",
	"...ohhhhhhhho...",
	"..ohhhhhhhhhho..",
	".oHHHHHHHHHHHHo.",
	".oorrsssssssroo.",
	"..orssssssssro..",
	"..ossessssesso..",
	"..ossessssesso..",
	"...oSssssssSo...",
	"....ooSSSSoo....",
	"...obbbbbbbbo...",
	"..obbbbbbbbbbo..",
	"..obbdbbbbdbbo..",
	"..obbddddddbbo..",
	"..oBbddddddbBo..",
	"...oddddddddo...",
	"...oddddddddo...",
]
const _FARMER_BACK := [
	"....oooooooo....",
	"...ohhhhhhhho...",
	"..ohhhhhhhhhho..",
	".oHHHHHHHHHHHHo.",
	".oorrrrrrrrrroo.",
	"..orrrrrrrrrro..",
	"..orrrrrrrrrro..",
	"..oRrrrrrrrrRo..",
	"...oSssssssSo...",
	"....ooSSSSoo....",
	"...obbbbbbbbo...",
	"..obbbbbbbbbbo..",
	"..obbdbbbbdbbo..",
	"..obbbdbbdbbbo..",
	"..oBbbbddbbbBo..",
	"...oddddddddo...",
	"...oddddddddo...",
]
## Per pose, per frame: [body drop, left leg lift, right leg lift, left hand y, right hand y,
## leg spread]. Walk / run cycles go contact, left step, contact, right step.
const _FARMER_POSES := {
	"idle": [[0, 0, 0, 14, 14, 0]],
	"walk": [[1, 0, 0, 14, 14, 0], [0, 2, 0, 15, 13, 0], [1, 0, 0, 14, 14, 0], [0, 0, 2, 13, 15, 0]],
	"run": [[1, 0, 0, 13, 13, 1], [0, 3, 0, 15, 12, 0], [1, 0, 0, 13, 13, 1], [0, 0, 3, 12, 15, 0]],
}


static func farmer_frames(pose: String) -> int:
	return _FARMER_POSES[pose].size()


## The bag hangs on the farmer's left, so it shows on the right of the front view and on the
## left of the back view, and moves sides when the sprite is mirrored.
static func _player(back: bool, pose: String, frame: int) -> Image:
	var p: Array = _FARMER_POSES[pose][frame % farmer_frames(pose)]
	var img := Image.create_empty(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_leg(img, 4 - p[5], p[1])
	_leg(img, 9 + p[5], p[2])
	_map(img, _FARMER_BACK if back else _FARMER_FRONT, p[0])
	var bag_x := 0 if back else 12
	img.fill_rect(Rect2i(bag_x, 15 + p[0], 4, 5), Color(_FARMER_COLORS.o))
	img.fill_rect(Rect2i(bag_x + 1, 16 + p[0], 2, 3), Color(_FARMER_COLORS.y))
	_hand(img, 2, p[3] + p[0])
	_hand(img, 12, p[4] + p[0])
	return img


## A 2 x 2 hand under the sleeve, outlined on the sides and below.
static func _hand(img: Image, x: int, y: int) -> void:
	img.fill_rect(Rect2i(x - 1, y, 4, 3), Color(_FARMER_COLORS.o))
	img.fill_rect(Rect2i(x, y, 2, 2), Color(_FARMER_COLORS.s))


## One leg: 3 px of trousers and boot inside a 1 px outline, from under the body to the ground,
## shorter by `lift` when the foot is off the ground.
static func _leg(img: Image, x: int, lift: int) -> void:
	var bottom := 23 - lift
	img.fill_rect(Rect2i(x - 1, 16, 5, bottom - 15), Color(_FARMER_COLORS.o))
	img.fill_rect(Rect2i(x, 16, 3, bottom - 19), Color(_FARMER_COLORS.d))
	img.fill_rect(Rect2i(x, bottom - 3, 3, 3), Color(_FARMER_COLORS.k))


static func _map(img: Image, rows: Array, dy: int) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != ".":
				img.set_pixel(x, y + dy, Color(_FARMER_COLORS[row[x]]))


## Growth 0..3 (seed, sprout, young, grown); ripe adds fruit.
static func _crop(growth: int, ripe: bool) -> Image:
	if growth == 0:
		return _draw(16, 16, [[5, 13, 2, 2, "5a3a20"], [9, 12, 2, 2, "5a3a20"]])
	var h := 3 + growth * 3
	var rects := [[7, 16 - h, 2, h, "4f8f35"], [4, 16 - h + 1, 3, 2, "7fc24a"], [9, 16 - h + 2, 3, 2, "7fc24a"]]
	if ripe:
		rects.append_array([[3, 16 - h, 4, 4, "e8a23a"], [9, 16 - h + 2, 4, 4, "e8a23a"]])
	return _draw(16, 16, rects)
