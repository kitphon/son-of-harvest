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
		"rock", "branch", "weed", "stump":
			return _obstacle(parts[0])
		"crop":     # crop:<id>:<growth 0..3>:<ripe|growing>
			return _crop(parts[1], int(parts[2]), parts[3] == "ripe")
	return _draw(16, 16, [[0, 0, 16, 16, "ff00ff"]])


## The sprite key for what stands on a field cell ("" for nothing). Growth is drawn in four
## looks: 0 seed, 1 sprout, 2 young, 3 grown (ripe adds the produce).
static func cell_key(farm: FarmGrid, d: Dictionary) -> String:
	match d.obj:
		FarmGrid.Obj.ROCK:
			return "rock"
		FarmGrid.Obj.BRANCH:
			return "branch"
		FarmGrid.Obj.WEED:
			return "weed"
		FarmGrid.Obj.STUMP:
			return "stump"
	if d.crop == "":
		return ""
	var ripe := farm.ripe_stage(d.crop)
	var growth := 0 if d.stage == 0 else (3 if d.stage >= ripe else clampi(1 + 2 * (d.stage - 1) / maxi(ripe - 1, 1), 1, 2))
	return "crop:%s:%d:%s" % [d.crop, growth, "ripe" if d.stage >= ripe else "growing"]


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


## Field objects and crops share one style with the farmer: shapes in 2-3 shades, then a
## 1 px dark outline around the whole silhouette.
const OUTLINE := Color("2a1e1e")
const _SOIL := Color("6b4a2a")
const _STAKE := Color("b08a5a")
const _DEFAULT_LOOK := {"shape": "bush", "leaf": "5f9e3a", "fruit": "e8a23a"}

static var _looks := {}


## A crop's "look" from data/crops.json: shape (root / bush / vine / stalk / ground),
## leaf and fruit colours, and per-shape extras (leaves, bulb, fruit_shape, flower, fruit_top).
static func crop_look(id: String) -> Dictionary:
	if _looks.is_empty():
		var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
		for k in crops:
			_looks[k] = crops[k].get("look", _DEFAULT_LOOK)
	return _looks.get(id, _DEFAULT_LOOK)


static func _blank(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _px(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if r.has_area():
		img.fill_rect(r, c)


## Filled ellipse, tested at pixel centres.
static func _oval(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(floori(cy - ry), ceili(cy + ry) + 1):
		for x in range(floori(cx - rx), ceili(cx + rx) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(img, x, y, 1, 1, c)


static func _line(img: Image, a: Vector2i, b: Vector2i, c: Color) -> void:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var p := Vector2(a).lerp(Vector2(b), float(i) / maxi(n, 1)).round()
		_px(img, int(p.x), int(p.y), 1, 1, c)


## Dark outline on every clear pixel that touches the silhouette (4 neighbours).
static func _outline(img: Image) -> Image:
	var src := img.duplicate() as Image
	var size := img.get_size()
	for y in size.y:
		for x in size.x:
			if src.get_pixel(x, y).a > 0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < size.x and q.y < size.y and src.get_pixelv(q).a > 0:
					img.set_pixel(x, y, OUTLINE)
					break
	return img


static func _obstacle(kind: String) -> Image:
	var img := _blank(16, 16)
	match kind:
		"rock":
			_oval(img, 8, 10.5, 6, 4, Color("767676"))
			_oval(img, 7.5, 9.5, 5, 3.2, Color("9e9e9e"))
			_px(img, 5, 7, 3, 1, Color("c8c8c8"))
			_px(img, 10, 10, 1, 2, Color("6a6a6a"))
		"branch":
			_line(img, Vector2i(2, 13), Vector2i(13, 9), Color("5e3d1e"))
			_line(img, Vector2i(2, 12), Vector2i(13, 8), Color("8a6038"))
			_line(img, Vector2i(8, 10), Vector2i(10, 5), Color("7a5230"))
			_px(img, 10, 4, 2, 2, Color("6fae4a"))
		"weed":
			for t in [[3, 6, "3e7a2a"], [6, 3, "4f8f35"], [10, 4, "3e7a2a"], [13, 7, "4f8f35"], [8, 6, "5fa83a"]]:
				_line(img, Vector2i(8, 14), Vector2i(t[0], t[1]), Color(t[2]))
				_line(img, Vector2i(7, 14), Vector2i(t[0] - 1, t[1] + 1), Color(t[2]))
		"stump":
			_px(img, 3, 7, 10, 7, Color("6b4423"))
			_px(img, 5, 9, 1, 4, Color("4e3018"))
			_px(img, 9, 8, 1, 5, Color("4e3018"))
			_px(img, 1, 13, 3, 1, Color("5e3d1e"))
			_px(img, 12, 13, 3, 1, Color("5e3d1e"))
			_oval(img, 8, 7, 5, 2, Color("c49a64"))
			_oval(img, 8, 7, 2.5, 1, Color("a07a4a"))
	return _outline(img)


## Seed and sprout look the same for every crop (in its leaf colour); from growth 2 the shape
## from the crop's look takes over. Vines and stalks are 16 x 24, the rest 16 x 16.
static func _crop(id: String, growth: int, ripe: bool) -> Image:
	var look := crop_look(id)
	var shape: String = look.get("shape", "bush")
	var tall := growth >= 2 and (shape == "vine" or shape == "stalk")
	var img := _blank(16, 24 if tall else 16)
	var g := img.get_height() - 2          # ground row; the row below is left for the outline
	var leaf := Color(look.get("leaf", "5f9e3a"))
	var dark := leaf.darkened(0.25)
	var light := leaf.lightened(0.25)
	var fruit := Color(look.get("fruit", "e8a23a"))
	if growth == 0:
		_px(img, 5, g - 1, 6, 2, _SOIL)
		_px(img, 6, g - 1, 1, 1, Color("e8d8a8"))
		_px(img, 9, g, 1, 1, Color("e8d8a8"))
		return _outline(img)
	if growth == 1:
		_px(img, 7, g - 3, 2, 4, dark)
		_oval(img, 5.5, g - 4, 2.2, 1.3, leaf)
		_oval(img, 10.5, g - 5, 2.2, 1.3, light)
		return _outline(img)
	var big := growth >= 3
	match shape:
		"root":
			_root(img, look, g, big, leaf, dark, light)
			if ripe:
				var b: Array = look.get("bulb", [4.0, 2.5])
				_oval(img, 8, g - b[1] + 1, b[0], b[1], fruit)
				if look.has("fruit_top"):
					_oval(img, 8, g - b[1] * 1.6 + 1, b[0] * 0.8, b[1] * 0.5, Color(look.fruit_top))
				_px(img, 6, g - int(b[1]), 2, 1, fruit.lightened(0.35))
		"bush":
			var r := Vector2(6, 5) if big else Vector2(4, 3)
			_oval(img, 8, g - r.y + 1, r.x, r.y, dark)
			_oval(img, 7.5, g - r.y - 0.5, r.x - 0.5, r.y - 0.5, leaf)
			_px(img, 5, g - 2 * int(r.y) + 2, 2, 1, light)
			if ripe:
				if look.get("fruit_shape", "") == "tuber":
					for p in [Vector2(3.5, g - 0.5), Vector2(12.5, g - 0.5), Vector2(8, g)]:
						_oval(img, p.x, p.y, 2.2, 1.6, fruit)
				else:
					for p in [Vector2(4.5, g - 3), Vector2(11.5, g - 4), Vector2(8, g - 2)]:
						_oval(img, p.x, p.y, 1.6, 2.6, fruit)
						_px(img, int(p.x) - 1, int(p.y - 3), 2, 1, dark)
				if look.has("flower"):
					for p in [Vector2i(6, g - 9), Vector2i(10, g - 8)]:
						_px(img, p.x, p.y, 2, 2, Color(look.flower))
		"vine":
			var top := g - (19 if big else 10)
			_px(img, 7, top - 1, 2, g - top + 2, _STAKE)
			var side := -1
			for y in range(g - 1, top, -3):
				_oval(img, 8 + side * 3, y, 2.6, 1.8, leaf if side < 0 else dark)
				side = -side
			_px(img, 8, top, 2, 2, light)
			if ripe:
				for p in [Vector2(4, g - 6), Vector2(12, g - 10), Vector2(4.5, g - 14)]:
					if look.get("fruit_shape", "") == "long":
						_px(img, int(p.x), int(p.y) - 2, 2, 5, fruit)
						_px(img, int(p.x), int(p.y) - 2, 1, 2, fruit.lightened(0.3))
					else:
						_oval(img, p.x, p.y, 1.9, 1.9, fruit)
						_px(img, int(p.x) - 1, int(p.y) - 1, 1, 1, fruit.lightened(0.4))
		"stalk":
			var h := 20 if big else 10
			_px(img, 7, g - h, 2, h + 1, dark)
			for y in range(g - 2, g - h + 1, -5):
				_line(img, Vector2i(6, y), Vector2i(2, y - 3), leaf)
				_line(img, Vector2i(9, y - 2), Vector2i(13, y - 5), leaf)
			if big:
				_px(img, 7, g - h - 2, 2, 2, Color("d9c27a"))
				_px(img, 6, g - h - 1, 1, 1, Color("d9c27a"))
				_px(img, 9, g - h - 1, 1, 1, Color("d9c27a"))
			if ripe:
				_oval(img, 10.5, g - 11, 1.8, 3.5, fruit)
				_px(img, 10, g - 13, 1, 3, fruit.lightened(0.3))
				_px(img, 9, g - 8, 3, 2, leaf)
		"ground":
			_line(img, Vector2i(2, g), Vector2i(14, g - 1), dark)
			_oval(img, 4, g - 3, 2.8, 2.2, leaf)
			_oval(img, 12, g - 4, 2.8, 2.2, dark)
			if big:
				_oval(img, 8, g - 6, 3, 2.4, light)
			if ripe:
				_oval(img, 8, g - 3.5, 6, 3.6, fruit.darkened(0.15))
				_oval(img, 8, g - 3.5, 3.2, 3.4, fruit)
				_oval(img, 8, g - 3.5, 1.2, 3.2, fruit.darkened(0.1))
				_px(img, 5, g - 5, 1, 2, fruit.lightened(0.3))
				_px(img, 8, g - 9, 1, 2, Color("5e7a2a"))
	return _outline(img)


## Leaves above the ground for root crops: broad (oval leaves), thin (upright blades) or
## feathery (stems with leaflets at the tips).
static func _root(img: Image, look: Dictionary, g: int, big: bool, leaf: Color, dark: Color, light: Color) -> void:
	match look.get("leaves", "broad"):
		"thin":
			var hs := [9, 12, 11, 8] if big else [5, 7, 6, 4]
			for i in 4:
				_px(img, 5 + i * 2, g - hs[i], 1, hs[i] + 1, leaf if i % 2 == 0 else dark)
		"feathery":
			var tips := [Vector2i(3, g - 7), Vector2i(8, g - 10), Vector2i(13, g - 7)] if big \
				else [Vector2i(5, g - 4), Vector2i(8, g - 6), Vector2i(11, g - 4)]
			for t in tips:
				_line(img, Vector2i(8, g), t, dark)
				_oval(img, t.x + 0.5, t.y + 0.5, 1.8, 1.5, leaf)
			_px(img, 8, tips[1].y, 1, 1, light)
		_:
			var s := 1.6 if big else 1.0
			_oval(img, 4.5, g - 3 * s + 1, 2.2, 3 * s, dark)
			_oval(img, 11.5, g - 3 * s + 1, 2.2, 3 * s, dark)
			_oval(img, 8, g - 4 * s + 1, 2.4, 4 * s, leaf)
			_px(img, 8, g - int(7 * s), 1, int(5 * s), light)
