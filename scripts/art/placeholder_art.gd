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
		"player":
			return _player(parts[1] == "back")
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


## 16 x 24 farmer. The bag on one side shows when the sprite is mirrored.
static func _player(back: bool) -> Image:
	var rects := [
		[3, 0, 10, 4, "c8452c"],            # cap
		[4, 4, 8, 6, "6b4423" if back else "f2c79b"],
		[3, 10, 10, 8, "3b6fd1"],           # shirt
		[4, 18, 3, 6, "2a2a3a"], [9, 18, 3, 6, "2a2a3a"],
	]
	if back:
		rects.append([3, 11, 2, 5, "d9b45a"])
	else:
		rects.append_array([[6, 7, 1, 1, "2a2a3a"], [9, 7, 1, 1, "2a2a3a"], [11, 11, 2, 5, "d9b45a"]])
	return _draw(16, 24, rects)


## Growth 0..3 (seed, sprout, young, grown); ripe adds fruit.
static func _crop(growth: int, ripe: bool) -> Image:
	if growth == 0:
		return _draw(16, 16, [[5, 13, 2, 2, "5a3a20"], [9, 12, 2, 2, "5a3a20"]])
	var h := 3 + growth * 3
	var rects := [[7, 16 - h, 2, h, "4f8f35"], [4, 16 - h + 1, 3, 2, "7fc24a"], [9, 16 - h + 2, 3, 2, "7fc24a"]]
	if ripe:
		rects.append_array([[3, 16 - h, 4, 4, "e8a23a"], [9, 16 - h + 2, 4, 4, "e8a23a"]])
	return _draw(16, 16, rects)
