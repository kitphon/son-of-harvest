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
		"player":   # player:<front|back>:<idle|walk|run|tired_idle|tired_walk>:<frame>
			return _player(parts[1] == "back", parts[2], int(parts[3]))
		"target":   # corner brackets laid on the cell the tool will hit
			var c := Color(1, 1, 1, 0.85)
			return _draw(16, 16, [[0, 0, 5, 1, c], [0, 0, 1, 5, c], [11, 0, 5, 1, c], [15, 0, 1, 5, c],
				[0, 15, 5, 1, c], [0, 11, 1, 5, c], [11, 15, 5, 1, c], [15, 11, 1, 5, c]])
		"charge":   # charge:<steps>:<max>, pips over the farmer while a tool charges
			return _charge(int(parts[1]), int(parts[2]))
		"rock", "branch", "weed", "stump":
			return _obstacle(parts[0])
		"crop":     # crop:<id>:<growth 0..3>:<ripe|growing>
			return _crop(parts[1], int(parts[2]), parts[3] == "ripe")
		"build":    # build:<plaster|board|kawara|planks|planks_dark|sugi|bamboo|quilt|noren|shoji_door|shoji>
			return _building(parts[1])
		"ground":   # ground:<grass|tilled|wet|path|tatami|floor|earth|gravel|wall>:<variant> or ground:water:<land sides mask>
			return _ground(parts[1], int(parts[2]))
		"fx":       # fx:<rain|snow|splash>, weather particles (white, tinted by the particle colour)
			return _fx(parts[1])
		"ui":       # ui:<frame|slot|weather|tool|seeds|coin|stamina>:<kind>, HUD pieces
			return _ui(parts[1], parts[2] if parts.size() > 2 else "")
		"title":    # title:bg, the title screen picture (480 x 270)
			return _title_bg()
		"face":     # face:<speaker>:<calm|smile|surprised|worried>, a 40 x 40 text box portrait
			return _face(parts[1], parts[2] if parts.size() > 2 else "calm")
	return _draw(16, 16, [[0, 0, 16, 16, "ff00ff"]])


static func charge_key(steps: int, most: int) -> String:
	return "charge:%d:%d" % [steps, most]


## One 4 x 4 pip per charge step past the tap, filled vermilion once reached, paper while not
## yet; dark outlined so it reads on grass, soil and snow.
static func _charge(steps: int, most: int) -> Image:
	var n := maxi(most, 1)
	var img := _blank(n * 5 + 1, 6)
	for i in n:
		_px(img, i * 5, 0, 6, 6, Color("2a1a10"))
		_px(img, i * 5 + 1, 1, 4, 4, UI_SEAL if i < steps else UI_PAPER)
	return img


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
## The camera looks along a diagonal, so every walking direction is a screen diagonal: the
## front view is turned three-quarters towards the lower left (Down), the back view towards
## the upper left (Left); mirrored they serve Right and Up. Steps go sideways on screen.
const _FARMER_COLORS := {
	"o": "2a1e1e", "h": "c8452c", "H": "8e2c1c", "s": "f2c79b", "S": "d29a6e", "e": "2a2a3a",
	"r": "6b4423", "R": "4e3018", "b": "3b6fd1", "B": "2a50a0", "d": "34426a", "y": "d9b45a",
	"k": "5e3d1e",
}
const _FARMER_FRONT := [
	".....oooooooo...",
	"....ohhhhhhhho..",
	"...ohhhhhhhhhho.",
	".ooHHHHHHHHHHHo.",
	"..osssssrrrrrro.",
	"..osssssssrrrro.",
	"..osessessSrro..",
	"..osessessSrro..",
	"...oSssssSSoo...",
	".....oSSSoo.....",
	"....obbbbbbo....",
	"...obbbbbbbbo...",
	"...obdbbbbdbo...",
	"...obddddddbo...",
	"...oBddddddBo...",
	"....oddddddo....",
	"....oddddddo....",
]
const _FARMER_BACK := [
	".....oooooooo...",
	"....ohhhhhhhho..",
	"...ohhhhhhhhhho.",
	".ooHHHHHHHHHHHo.",
	"..oSrrrrrrrrro..",
	"..oSrrrrrrrrro..",
	"..osrrrrrrrrro..",
	"..oRrrrrrrrrRo..",
	"...oSRrrrrrRo...",
	".....oSSSoo.....",
	"....obbbbbbo....",
	"...obbbbbbbbo...",
	"...obbdbbdbbo...",
	"...obbbddbbbo...",
	"...oBbbddbbBo...",
	"....oddddddo....",
	"....oddddddo....",
]
## Per pose, per frame: [body drop, near leg x shift, near leg lift, far leg x shift,
## far leg lift, near hand x shift, far hand x shift]. Negative x = the way the view faces.
## Walk / run cycles go contact, pass, contact, pass: on contact the legs are spread with the
## opposite arm forward and the body 1 px lower; on a pass one foot is lifted under the body.
const _FARMER_POSES := {
	"idle": [[0, 0, 0, 0, 0, 0, 0]],
	"walk": [[1, -2, 0, 2, 0, 2, -2], [0, 0, 0, 0, 2, 0, 0], [1, 2, 0, -2, 0, -2, 2], [0, 0, 2, 0, 0, 0, 0]],
	"run": [[1, -3, 0, 3, 0, 3, -3], [0, 0, 0, 0, 3, 0, 0], [1, 3, 0, -3, 0, -3, 3], [0, 0, 3, 0, 0, 0, 0]],
	# Tired: slumped 1-2 px lower, slow heavy breaths standing, short dragging steps walking.
	"tired_idle": [[1, 0, 0, 0, 0, 0, 0], [2, 0, 0, 0, 0, 0, 0]],
	"tired_walk": [[2, -1, 0, 1, 0, 1, -1], [1, 0, 0, 0, 1, 0, 0], [2, 1, 0, -1, 0, -1, 1], [1, 0, 1, 0, 0, 0, 0]],
}
const _SWEAT := Color("9fd8f2")


static func farmer_frames(pose: String) -> int:
	return _FARMER_POSES[pose].size()


## Draw order back to front: far hand, far leg, near leg, body, bag, near hand. The bag hangs
## at the farmer's back on the front view and at the front on the back view.
static func _player(back: bool, pose: String, frame: int) -> Image:
	var p: Array = _FARMER_POSES[pose][frame % farmer_frames(pose)]
	var tired := pose.begins_with("tired")
	var arms: int = p[0] + int(tired)   # tired arms hang a pixel lower
	var img := Image.create_empty(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_hand(img, 11 + p[6], 14 + arms)
	_leg(img, 8 + p[3], p[4])
	_leg(img, 5 + p[1], p[2])
	_map(img, _FARMER_BACK if back else _FARMER_FRONT, p[0])
	var bag_x := 1 if back else 11
	img.fill_rect(Rect2i(bag_x, 14 + p[0], 4, 5), Color(_FARMER_COLORS.o))
	img.fill_rect(Rect2i(bag_x + 1, 15 + p[0], 2, 3), Color(_FARMER_COLORS.y))
	_hand(img, 4 + p[5], 14 + arms)
	if tired:   # a drop of sweat by the brow: in front of the face, or behind the head seen from the back
		var sx := 14 if back else 1
		img.fill_rect(Rect2i(sx, 4 + p[0], 1, 1), Color.WHITE)
		img.fill_rect(Rect2i(sx, 5 + p[0], 1, 2), _SWEAT)
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


## Ground tiles, 16 x 16, no outline. Grass and path come in GROUND_VARIANTS so the field
## does not look stamped; water tiles carry a bank on each side that touches land.
const GROUND_VARIANTS := 4
const WATER_N := 1
const WATER_E := 2
const WATER_S := 4
const WATER_W := 8


## The ground key for a cell: fixed buildings stand on path, the fence on grass.
static func ground_key(farm: FarmGrid, c: Vector2i) -> String:
	var v := posmod(c.x * 7 + c.y * 13 + (c.x * c.y) % 5, GROUND_VARIANTS)
	match farm.fixed_at(c):
		"":
			var d := farm.cell(c)
			if d.wet:
				return "ground:wet:%d" % v
			return "ground:tilled:%d" % v if d.tilled else "ground:grass:%d" % v
		"pond":
			var mask := 0
			for side in [[Vector2i.UP, WATER_N], [Vector2i.RIGHT, WATER_E], [Vector2i.DOWN, WATER_S], [Vector2i.LEFT, WATER_W]]:
				if farm.fixed_at(c + side[0]) != "pond":
					mask |= side[1]
			return "ground:water:%d" % mask
		"fence":
			return "ground:grass:%d" % v
	return "ground:path:%d" % v


static func _ground(kind: String, n: int) -> Image:
	var img := _blank(16, 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind) + n
	match kind:
		"grass":
			img.fill(Color("6fae4a"))
			for i in 10:
				var x := rng.randi_range(0, 15)
				var y := rng.randi_range(1, 15)
				_px(img, x, y, 1, 1, Color("5a9a3a"))
				_px(img, x, y - 1, 1, 1, Color("86c25a") if i % 3 == 0 else Color("5a9a3a"))
			if n == 0:
				_px(img, 11, 4, 1, 1, Color("f4f0e8"))   # a tiny flower now and then
		"tilled", "wet":
			var wet := kind == "wet"
			var base := Color("5a3a22") if wet else Color("a07446")
			img.fill(base)
			# Furrows: a dark trench and a lit ridge every 4 rows.
			for y in [3, 7, 11, 15]:
				_px(img, 0, y, 16, 1, base.darkened(0.3))
				_px(img, 0, y - 2, 16, 1, base.lightened(0.15 if wet else 0.12))
			for i in 6:
				_px(img, rng.randi_range(0, 15), rng.randi_range(0, 15), 1, 1, base.darkened(0.15))
			if wet:
				_px(img, rng.randi_range(2, 9), 5, 3, 1, Color("7a6a6a"))   # a wet glint
		"path":
			img.fill(Color("c2ab80"))
			for i in 7:
				var x := rng.randi_range(0, 14)
				var y := rng.randi_range(0, 14)
				_px(img, x, y, 2, 1, Color("a89068"))
				_px(img, x, y + 1, 2, 1, Color("8f7a58") if i % 2 == 0 else Color("d6c29a"))
		"tatami":
			# Half a mat per cell: pale straw rush in fine weave lines, a dark cloth edge (heri)
			# along the long sides; variants alternate the way the mats lie.
			var across := n % 2 == 0
			img.fill(Color("c8c088"))
			for i in 8:
				var t := i * 2 + 1
				if across:
					_px(img, 0, t, 16, 1, Color("b8b078"))
				else:
					_px(img, t, 0, 1, 16, Color("b8b078"))
			for i in 5:
				_px(img, rng.randi_range(0, 15), rng.randi_range(0, 15), 1, 1, Color("d6d09c"))
			if across:
				_px(img, 0, 0, 1, 16, Color("2e3a2a"))
				_px(img, 15, 0, 1, 16, Color("2e3a2a"))
			else:
				_px(img, 0, 0, 16, 1, Color("2e3a2a"))
				_px(img, 0, 15, 16, 1, Color("2e3a2a"))
		"floor":
			# Polished wooden floor boards running across, 4 px wide.
			img.fill(Color("8a603c"))
			for row in 4:
				_px(img, 0, row * 4 + 3, 16, 1, Color("5e3e26"))
				_px(img, 0, row * 4, 16, 1, Color("a07450"))
				_px(img, (row * 5 + n * 3) % 16, row * 4, 1, 3, Color("5e3e26"))
		"earth":
			# Packed earth of the entry (doma): grey-brown with small pebbles.
			img.fill(Color("8c7a62"))
			for i in 9:
				var x := rng.randi_range(0, 14)
				var y := rng.randi_range(0, 14)
				_px(img, x, y, 1, 1, Color("7a6a54"))
				_px(img, x + 1, y, 1, 1, Color("a0907a") if i % 2 == 0 else Color("6e604c"))
		"gravel":
			# Raked shrine gravel: light grey stones on a paler ground.
			img.fill(Color("c8c4b8"))
			for i in 16:
				var x := rng.randi_range(0, 14)
				var y := rng.randi_range(0, 15)
				_px(img, x, y, 2, 1, Color("a8a498") if i % 2 == 0 else Color("dedad0"))
		"wall":
			img.fill(Color("3e3028"))
		"water":
			img.fill(Color("3d7fc4"))
			for i in 4:
				_px(img, rng.randi_range(1, 10), rng.randi_range(2, 13), rng.randi_range(3, 5), 1, Color("5d9ad8"))
			var bank := Color("6b5a3a")
			var foam := Color("a8d0f0")
			if n & WATER_N:
				_px(img, 0, 0, 16, 2, bank)
				_px(img, 0, 2, 16, 1, foam)
			if n & WATER_S:
				_px(img, 0, 14, 16, 2, bank)
				_px(img, 0, 13, 16, 1, foam)
			if n & WATER_W:
				_px(img, 0, 0, 2, 16, bank)
				_px(img, 2, 0 if not n & WATER_N else 3, 1, 16, foam)
			if n & WATER_E:
				_px(img, 14, 0, 2, 16, bank)
				_px(img, 13, 0 if not n & WATER_N else 3, 1, 16, foam)
			# Banks drawn last on the corners they share.
			if n & WATER_N:
				_px(img, 0, 0, 16, 2, bank)
			if n & WATER_S:
				_px(img, 0, 14, 16, 2, bank)
	return img


## Building surfaces, in the Japanese countryside look (see ROADMAP "Mood and tone"). The
## repeating ones are 16 x 16 = one world unit, laid on boxes with triplanar mapping; the
## shoji door and window and the noren are single pictures.
static func _building(kind: String) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	match kind:
		"plaster":
			# White lime plaster with faint trowel marks.
			var img := _blank(16, 16)
			img.fill(Color("eee8da"))
			for i in 8:
				_px(img, rng.randi_range(0, 13), rng.randi_range(0, 15), rng.randi_range(2, 3), 1, Color("e2dacb"))
			return img
		"board":
			# Charred dark cedar boards standing upright, 4 px wide, with lit edges.
			var img := _blank(16, 16)
			img.fill(Color("3e3028"))
			for col in 4:
				_px(img, col * 4 + 3, 0, 1, 16, Color("261c16"))
				_px(img, col * 4, 0, 1, 16, Color("54443a"))
				for i in 2:
					_px(img, col * 4 + rng.randi_range(1, 2), rng.randi_range(0, 14), 1, 2, Color("32261e"))
			return img
		"planks", "planks_dark":
			# Horizontal boards, 4 px tall, with a dark seam and staggered board ends.
			var base := {"planks": Color("9a7048"), "planks_dark": Color("6a5038")}[kind] as Color
			var img := _blank(16, 16)
			img.fill(base)
			for row in 4:
				_px(img, 0, row * 4 + 3, 16, 1, base.darkened(0.25))
				_px(img, 0, row * 4, 16, 1, base.lightened(0.1))
				_px(img, (row * 7 + 3) % 16, row * 4, 1, 3, base.darkened(0.25))
				for i in 2:
					_px(img, rng.randi_range(0, 15), row * 4 + rng.randi_range(1, 2), 2, 1, base.darkened(0.08))
			return img
		"kawara":
			# Grey-blue clay roof tiles: rounded rows running down the slope (texture v), each
			# 4 px wide with a lit crown and dark troughs, tile ends every 4 px.
			var img := _blank(16, 16)
			img.fill(Color("5a6470"))
			for col in 4:
				_px(img, col * 4, 0, 1, 16, Color("3a424c"))
				_px(img, col * 4 + 1, 0, 1, 16, Color("7a8692"))
				_px(img, col * 4 + 2, 0, 1, 16, Color("68737f"))
			for row in 4:
				_px(img, 0, row * 4 + 3, 16, 1, Color("444c56"))
			return img
		"sugi":
			# Light cedar boards standing upright, 4 px wide, with a straight reddish grain.
			var img := _blank(16, 16)
			img.fill(Color("c49464"))
			for col in 4:
				_px(img, col * 4 + 3, 0, 1, 16, Color("8e6440"))
				_px(img, col * 4 + rng.randi_range(0, 2), 0, 1, 16, Color("b07e52"))
				_px(img, col * 4, rng.randi_range(0, 12), 1, 4, Color("d8ac7c"))
			return img
		"bamboo":
			# Dry bamboo for canes and posts laid along texture v: yellow-green with a lit
			# stripe and a dark node ring every half unit.
			var img := _blank(16, 16)
			img.fill(Color("a8a464"))
			for x in [2, 9]:
				_px(img, x, 0, 2, 16, Color("c8c488"))
			_px(img, 13, 0, 1, 16, Color("8a8650"))
			for y in [5, 13]:
				_px(img, 0, y, 16, 1, Color("6a6a3a"))
				_px(img, 0, y + 1, 16, 1, Color("bcb87c"))
			return img
		"quilt":
			# Indigo futon cover with a small white cross-and-dot weave, 16 x 16.
			var img := _blank(16, 16)
			img.fill(Color("34467a"))
			for y in [2, 10]:
				for x in [2, 10]:
					_px(img, x + 1, y, 1, 3, Color("d8dcea"))
					_px(img, x, y + 1, 3, 1, Color("d8dcea"))
					_px(img, x + 5, y + 5, 1, 1, Color("8a98c4"))
			return img
		"noren":
			# 21 x 8 shop curtain: indigo cloth in three panels (dark slits), a white sprout
			# mark on the middle one, a lighter hem.
			var img := _blank(21, 8)
			img.fill(Color("2c3a5e"))
			for x in [6, 14]:
				_px(img, x, 2, 1, 6, Color("161e32"))
			_px(img, 0, 0, 21, 1, Color("3a4a72"))
			_px(img, 10, 3, 1, 4, Color("eeeae0"))
			_px(img, 8, 3, 2, 1, Color("eeeae0"))
			_px(img, 11, 2, 2, 1, Color("eeeae0"))
			_px(img, 0, 7, 21, 1, Color("222d4a"))
			return img
		"shoji_door":
			# 16 x 24 sliding door: wooden frame, paper panes in a lattice, wooden kick panel.
			var img := _blank(16, 24)
			img.fill(Color("6a4a30"))
			_px(img, 1, 1, 14, 17, Color("f4efe2"))
			for x in [4, 8, 11]:
				_px(img, x, 1, 1, 17, Color("8a6a48"))
			for y in [5, 9, 13]:
				_px(img, 1, y, 14, 1, Color("8a6a48"))
			_px(img, 1, 19, 14, 4, Color("8a6a48"))
			_px(img, 12, 10, 1, 3, Color("3e3028"))   # finger pull
			return img
		"shoji":
			# 12 x 10 window: dark frame, paper panes in a 3 x 2 lattice.
			var img := _blank(12, 10)
			img.fill(Color("4a3424"))
			_px(img, 1, 1, 10, 8, Color("f4efe2"))
			for x in [4, 7]:
				_px(img, x, 1, 1, 8, Color("8a6a48"))
			_px(img, 1, 5, 10, 1, Color("8a6a48"))
			return img
	return _draw(16, 16, [[0, 0, 16, 16, "ff00ff"]])


## Weather particles: a rain streak (thin, brighter at the head), a soft snow flake and a
## splash ring laid flat on the ground.
static func _fx(kind: String) -> Image:
	match kind:
		"rain":
			var img := _blank(1, 8)
			for y in 8:
				img.set_pixel(0, y, Color(0.85, 0.9, 1.0, 0.3 + 0.6 * y / 7.0))
			return img
		"snow":
			var img := _blank(4, 4)
			_px(img, 1, 0, 2, 4, Color.WHITE)
			_px(img, 0, 1, 4, 2, Color.WHITE)
			for p in [Vector2i(0, 0), Vector2i(3, 0), Vector2i(0, 3), Vector2i(3, 3)]:
				img.set_pixelv(p, Color(1, 1, 1, 0.35))
			return img
		"splash":
			var img := _blank(8, 8)
			var c := Color(0.85, 0.92, 1.0, 0.8)
			_px(img, 2, 0, 4, 1, c)
			_px(img, 2, 7, 4, 1, c)
			_px(img, 0, 2, 1, 4, c)
			_px(img, 7, 2, 1, 4, c)
			for p in [Vector2i(1, 1), Vector2i(6, 1), Vector2i(1, 6), Vector2i(6, 6)]:
				img.set_pixelv(p, c)
			return img
	return _draw(4, 4, [[0, 0, 4, 4, "ff00ff"]])


## HUD pieces in warm paper and wood. Frames are 16 x 16 nine-patches with a 4 px border
## (dark edge, two rows of wood, a dark inner line), slots 18 x 18, icons 12 x 12 / 14 x 14.
const UI_WOOD := Color("8a5a32")
const UI_WOOD_LIGHT := Color("a8743f")
const UI_WOOD_DARK := Color("5a3a20")
const UI_PAPER := Color("efe3c4")
const UI_PAPER_FIBRE := Color("e3d4b0")
const UI_SEAL := Color("c8442c")      # vermilion, like a name seal: marks the tool in hand


static func _ui(kind: String, arg: String) -> Image:
	match kind:
		"frame":    # frame:<paper|wood>
			var img := _blank(16, 16)
			_px(img, 0, 0, 16, 16, Color("3a2416"))
			_px(img, 1, 1, 14, 14, UI_WOOD)
			_px(img, 1, 1, 14, 1, UI_WOOD_LIGHT)
			_px(img, 1, 14, 14, 1, Color("6a4222"))
			_px(img, 3, 3, 10, 10, UI_WOOD_DARK)
			for p in [Vector2i(0, 0), Vector2i(15, 0), Vector2i(0, 15), Vector2i(15, 15)]:
				img.set_pixelv(p, Color(0, 0, 0, 0))
			if arg == "wood":
				_px(img, 4, 4, 8, 8, Color("7a4e2a"))
				for y in [5, 9]:
					_px(img, 4, y, 8, 1, Color("6c4424"))
				_px(img, 6, 7, 3, 1, Color("8a5a32"))
			else:
				_px(img, 4, 4, 8, 8, UI_PAPER)
				for p in [Vector2i(5, 6), Vector2i(6, 6), Vector2i(9, 4), Vector2i(10, 9), Vector2i(11, 9), Vector2i(7, 11)]:
					img.set_pixelv(p, UI_PAPER_FIBRE)
			return img
		"slot":     # slot:<on|off>, a recessed paper square on the wooden tool bar
			var img := _blank(18, 18)
			if arg == "on":
				_px(img, 0, 0, 18, 18, UI_SEAL)
				_px(img, 1, 1, 16, 16, Color("f2b05a"))
				_px(img, 2, 2, 14, 14, Color("fbf3dc"))
			else:
				_px(img, 0, 0, 18, 18, Color("3a2416"))
				_px(img, 1, 1, 16, 16, Color("d9c79e"))
				_px(img, 1, 1, 16, 1, Color("bba57a"))
				_px(img, 1, 1, 1, 16, Color("c8b48a"))
			return img
		"weather":  # weather:<sunny|rain|storm|snow|blizzard>
			return _weather_icon(arg)
		"tool":     # tool:<hoe|can|sickle|hammer|axe>, 14 x 14
			return _tool_icon(arg)
		"seeds":    # seeds:<crop>, a paper seed bag with the crop's colour on its label
			var img := _blank(14, 14)
			var look := crop_look(arg)
			_px(img, 3, 4, 8, 9, Color("d8c08a"))
			_px(img, 4, 2, 6, 2, Color("b89a62"))
			_px(img, 3, 4, 8, 1, Color("b89a62"))
			_oval(img, 7, 8.5, 2.5, 2.5, Color(look.get("fruit", "c0a060")))
			_px(img, 6, 6, 2, 1, Color(look.get("leaf", "5fa83a")))
			return _outline(img)
		"coin":     # a gold coin with a square hole
			var img := _blank(9, 9)
			_oval(img, 4.5, 4.5, 4.0, 4.0, Color("c8962a"))
			_oval(img, 4.5, 4.5, 3.0, 3.0, Color("e8c050"))
			_px(img, 3, 3, 3, 3, Color("c8962a"))
			_px(img, 4, 4, 1, 1, Color(0, 0, 0, 0))
			return img
		"more":     # the small vermilion arrow that says a press goes on
			var img := _blank(7, 4)
			for y in 4:
				_px(img, y, y, 7 - y * 2, 1, UI_SEAL)
			return img
		"stamina":  # a rice ball: what keeps the farmer going
			var img := _blank(9, 9)
			for y in 7:
				var half := (y + 1) / 2 + 1
				_px(img, 4 - half + 1, y + 1, half * 2 - 1, 1, Color("fbf8f0"))
			_px(img, 3, 6, 3, 2, Color("26302a"))
			return _outline(img)
	return _draw(16, 16, [[0, 0, 16, 16, "ff00ff"]])


static func _weather_icon(kind: String) -> Image:
	var img := _blank(12, 12)
	if kind == "sunny":
		var ray := Color("e8902a")
		for p in [[5, 0, 2, 2], [5, 10, 2, 2], [0, 5, 2, 2], [10, 5, 2, 2], [1, 1, 2, 2], [9, 1, 2, 2], [1, 9, 2, 2], [9, 9, 2, 2]]:
			_px(img, p[0], p[1], p[2], p[3], ray)
		_oval(img, 6, 6, 3.5, 3.5, Color("f0a830"))
		_oval(img, 5.5, 5.5, 2.0, 2.0, Color("f8d868"))
		return img
	var dark := kind in ["storm", "blizzard"]
	var cloud := Color("6a7282") if dark else Color("a8b2c2")
	var cloud_top := Color("8a92a2") if dark else Color("d4dae4")
	_oval(img, 4, 4.5, 3, 2.5, cloud)
	_oval(img, 7.5, 3.5, 3.5, 3, cloud)
	_px(img, 1, 5, 10, 2, cloud)
	_oval(img, 7, 3, 2, 1.5, cloud_top)
	match kind:
		"rain", "storm":
			var drop := Color("3a78c8")
			for x in [2, 5, 8]:
				_px(img, x, 8 + x % 2, 1, 2, drop)
			if kind == "storm":
				_line(img, Vector2i(7, 6), Vector2i(5, 9), Color("f0d040"))
				_line(img, Vector2i(5, 9), Vector2i(7, 9), Color("f0d040"))
				_line(img, Vector2i(7, 9), Vector2i(6, 11), Color("f0d040"))
		"snow", "blizzard":
			var flake := Color("5a90d0")
			for p in [Vector2i(2, 9), Vector2i(6, 10), Vector2i(9, 8)]:
				_px(img, p.x - 1, p.y, 3, 1, flake)
				_px(img, p.x, p.y - 1, 1, 3, flake)
			if kind == "blizzard":
				_px(img, 0, 7, 4, 1, Color("e4eaf5"))
				_px(img, 8, 11, 4, 1, Color("e4eaf5"))
	return img


static func _tool_icon(kind: String) -> Image:
	var img := _blank(14, 14)
	var wood := Color("9a6a3a")
	var steel := Color("9aa0aa")
	var steel_light := Color("cfd4dc")
	match kind:
		"hoe":
			_line(img, Vector2i(2, 12), Vector2i(9, 4), wood)
			_line(img, Vector2i(3, 12), Vector2i(10, 4), wood)
			_px(img, 8, 1, 5, 2, steel)
			_px(img, 11, 3, 2, 4, steel)
			_px(img, 8, 1, 5, 1, steel_light)
		"can":
			var tin := Color("6a9ab0")
			_px(img, 3, 5, 6, 6, tin)
			_px(img, 3, 5, 6, 1, Color("9ac2d2"))
			_line(img, Vector2i(9, 8), Vector2i(12, 4), tin)
			_px(img, 11, 3, 2, 1, tin)
			_px(img, 4, 2, 4, 1, Color("4a7488"))
			_px(img, 3, 3, 1, 2, Color("4a7488"))
			_px(img, 8, 3, 1, 2, Color("4a7488"))
		"sickle":
			_line(img, Vector2i(2, 12), Vector2i(5, 9), wood)
			_line(img, Vector2i(3, 12), Vector2i(6, 9), wood)
			for p in [Vector2i(5, 8), Vector2i(5, 7), Vector2i(5, 6), Vector2i(6, 5), Vector2i(7, 4), Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 4)]:
				_px(img, p.x, p.y, 1, 1, steel)
			for p in [Vector2i(6, 6), Vector2i(7, 5), Vector2i(8, 4), Vector2i(9, 4), Vector2i(10, 4)]:
				_px(img, p.x, p.y, 1, 1, steel_light)
		"hammer":
			_px(img, 6, 5, 2, 8, wood)
			_px(img, 2, 1, 10, 4, Color("70767e"))
			_px(img, 2, 1, 10, 1, steel_light)
		"axe":
			_line(img, Vector2i(3, 12), Vector2i(9, 2), wood)
			_line(img, Vector2i(4, 12), Vector2i(10, 2), wood)
			_px(img, 8, 1, 4, 5, steel)
			_px(img, 11, 1, 1, 5, steel_light)
		_:
			return _draw(14, 14, [[0, 0, 14, 14, "ff00ff"]])
	return _outline(img)


## The title screen: an early morning over a satoyama valley. Banded sky with a pale sun,
## two hazy mountain ridges, a cedar hill with a small torii on the left, a thatched farm
## house on the right, and flooded rice paddies with young seedlings in front.
const TITLE_SIZE := Vector2i(480, 270)


static func _title_bg() -> Image:
	var w := TITLE_SIZE.x
	var h := TITLE_SIZE.y
	var img := _blank(w, h)
	var top := Color("8fb8d6")
	var glow := Color("f4dcb6")
	for y in 170:
		var t := floorf(float(y) / 170.0 * 9.0) / 8.0   # 9 bands, no smooth gradient
		_px(img, 0, y, w, 1, top.lerp(glow, t))
	_oval(img, 364, 104, 21, 21, Color("f8e8c8"))
	_oval(img, 364, 104, 13, 13, Color("fdf6e4"))
	for i in 3:   # thin morning clouds
		_px(img, 60 + i * 130, 40 + i * 14, 70 - i * 10, 2, Color("d8e4ea"))
		_px(img, 74 + i * 130, 38 + i * 14, 36 - i * 6, 2, Color("e6ecee"))

	_ridge(img, Color("a7b8c6"), func(x: float): return 128.0 + 16.0 * sin(x * 0.011 + 0.6) + 7.0 * sin(x * 0.043))
	_ridge(img, Color("88a198"), func(x: float): return 152.0 + 10.0 * sin(x * 0.017 + 2.1) + 5.0 * sin(x * 0.061 + 1.0))
	# The cedar hill on the left, cedars as small dark triangles along its top.
	var hill := func(x: float): return 136.0 + pow(x / 190.0, 2.0) * 60.0
	_ridge(img, Color("5b7d50"), hill)
	for i in 14:
		var cx := 6 + i * 13 + (i * 7) % 5
		var base := int(hill.call(float(cx))) + 4
		var tall := 16 + (i * 5) % 9
		for r in tall:
			var half := r * 4 / tall
			_px(img, cx - half, base - tall + r, half * 2 + 1, 1, Color("3e5e3e") if i % 3 else Color("46694a"))
	_torii(img, 112, int(hill.call(112.0)) + 2)
	_farm_house(img, 392, 182)

	# Rice paddies: levee lines further apart nearer the eye, water showing the sky.
	_px(img, 0, 182, w, h - 182, Color("6f9a4a"))
	var y := 184
	var gap := 6
	var row := 0
	while y < h:
		var water := Color("c3d8de").lerp(Color("a9c6d2"), float(y - 184) / float(h - 184))
		_px(img, 0, y, w, gap, water)
		var step := 6 + gap / 2
		for x in range((row * 3) % step, w, step):   # seedling tufts
			_px(img, x, y + gap / 2 - 1, 1, maxi(gap / 3, 1) + 1, Color("6aa04a"))
			if gap > 9:
				_px(img, x + 1, y + gap / 2, 1, gap / 3, Color("8cbf5a"))
		_px(img, 0, y + gap, w, 1, Color("8a7a50"))
		_px(img, 0, y + gap + 1, w, 1 + gap / 6, Color("6f9a4a"))
		y += gap + 2 + gap / 6
		gap += 3
		row += 1
	return img


## Fills from a ridge line (y for each x) down to the bottom.
static func _ridge(img: Image, c: Color, line: Callable) -> void:
	for x in img.get_width():
		var top := int(line.call(float(x)))
		if top < img.get_height():
			_px(img, x, top, 1, img.get_height() - top, c)


static func _torii(img: Image, cx: int, base: int) -> void:
	var red := UI_SEAL
	var dark := Color("2a1e1e")
	_px(img, cx - 6, base - 15, 2, 15, red)
	_px(img, cx + 4, base - 15, 2, 15, red)
	_px(img, cx - 9, base - 17, 18, 2, dark)    # the top beam, a little wider
	_px(img, cx - 8, base - 15, 16, 1, red)
	_px(img, cx - 7, base - 11, 14, 1, red)     # the lower tie beam
	_px(img, cx - 1, base - 15, 2, 4, red)


static func _farm_house(img: Image, cx: int, base: int) -> void:
	var thatch := Color("a88a52")
	var thatch_dark := Color("7e653a")
	for r in 16:   # a steep thatched roof
		var half := 6 + r * 2
		_px(img, cx - half, base - 30 + r, half * 2, 1, thatch if r % 4 else thatch_dark)
	_px(img, cx - 8, base - 33, 16, 3, Color("5a4a2c"))   # ridge cap
	_px(img, cx - 30, base - 14, 60, 14, Color("e8dcc0"))  # plaster walls
	for x in [cx - 30, cx - 12, cx + 6, cx + 28]:
		_px(img, x, base - 14, 2, 14, Color("4a3424"))     # posts
	_px(img, cx - 10, base - 11, 16, 11, Color("f2ead6"))  # shoji
	for x in [cx - 6, cx - 2, cx + 2]:
		_px(img, x, base - 11, 1, 11, Color("b8a888"))
	_px(img, cx - 32, base - 1, 64, 2, Color("6a4e34"))    # engawa


# --- text box portraits ----------------------------------------------------

## A head-and-shoulders face for the text box, in the speaker's colours from
## data/dialogue/speakers.json; the expression changes the eyes, brows and mouth.
static func _face(speaker: String, expression: String) -> Image:
	var look: Dictionary = DialogueRunner.speakers().get(speaker, {}).get("face", {})
	var skin := Color(look.get("skin", "f2c79b"))
	var hair := Color(look.get("hair", "4a3020"))
	var hat := Color(look.get("hat", "c8452c"))
	var ink := Color("2a1e1e")
	var img := _blank(40, 40)
	_px(img, 0, 0, 40, 40, Color(look.get("bg", "c8d8c0")))
	_oval(img, 20, 44, 15, 10, Color(look.get("clothes", "3b6fd1")))     # shoulders
	_px(img, 17, 29, 6, 5, skin.darkened(0.15))                          # neck
	_oval(img, 20, 20, 10.5, 11.5, OUTLINE)
	_oval(img, 20, 20, 9.5, 10.5, skin)
	if look.get("style", "cap") == "bun":
		_oval(img, 20, 4.5, 4.5, 3.5, OUTLINE)
		_oval(img, 20, 4.5, 3.5, 2.5, hair)
		_oval(img, 20, 13, 10, 5.5, hair)
		_px(img, 10, 13, 2, 9, hair)
		_px(img, 28, 13, 2, 9, hair)
		_px(img, 23, 6, 4, 1, hat)                                       # a hairpin
	else:
		_px(img, 10, 13, 2, 7, hair)
		_px(img, 28, 13, 2, 7, hair)
		_oval(img, 20, 11, 10.5, 5.5, hat)                               # the cap
		_px(img, 9, 13, 23, 2, hat.darkened(0.25))                       # its brim
	var eye_y := 21
	match expression:
		"smile":
			for x in [14, 23]:
				_px(img, x, eye_y, 1, 1, ink)
				_px(img, x + 1, eye_y - 1, 2, 1, ink)
				_px(img, x + 3, eye_y, 1, 1, ink)
			_px(img, 17, 27, 6, 1, ink)
			_px(img, 16, 26, 1, 1, ink)
			_px(img, 23, 26, 1, 1, ink)
			_px(img, 12, 24, 3, 1, Color("e89a8a"))
			_px(img, 25, 24, 3, 1, Color("e89a8a"))
		"surprised":
			for x in [15, 24]:
				_px(img, x, eye_y - 1, 2, 3, ink)
				_px(img, x - 1, eye_y - 5, 4, 1, hair.darkened(0.3))
			_px(img, 19, 26, 2, 2, ink)
		"worried":
			for x in [15, 24]:
				_px(img, x, eye_y, 2, 2, ink)
			_px(img, 13, eye_y - 3, 2, 1, hair.darkened(0.3))
			_px(img, 15, eye_y - 4, 2, 1, hair.darkened(0.3))
			_px(img, 23, eye_y - 4, 2, 1, hair.darkened(0.3))
			_px(img, 25, eye_y - 3, 2, 1, hair.darkened(0.3))
			_px(img, 18, 27, 4, 1, ink)
			_px(img, 17, 28, 1, 1, ink)
			_px(img, 22, 28, 1, 1, ink)
		_:   # calm
			for x in [15, 24]:
				_px(img, x, eye_y, 2, 2, ink)
			_px(img, 18, 27, 4, 1, ink)
	return img
