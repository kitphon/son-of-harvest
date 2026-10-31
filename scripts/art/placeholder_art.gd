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
		"player":   # player:<front|back>:<idle|walk|run|tired_idle|tired_walk|hold_idle|hold_walk|fish_wait|fish_bite>:<frame>
			return _player(parts[1] == "back", parts[2], int(parts[3]))
		"villager": # villager:<id>:<front|back>:<idle|walk>:<frame>, from the look in data/villagers/<id>.json
			return _villager(Villagers.look(parts[1]), parts[2] == "back", parts[3], int(parts[4]))
		"target":   # corner brackets laid on the cell the tool will hit
			var c := Color(1, 1, 1, 0.85)
			return _draw(16, 16, [[0, 0, 5, 1, c], [0, 0, 1, 5, c], [11, 0, 5, 1, c], [15, 0, 1, 5, c],
				[0, 15, 5, 1, c], [0, 11, 1, 5, c], [11, 15, 5, 1, c], [15, 11, 1, 5, c]])
		"charge":   # charge:<steps>:<max>, pips over the farmer while a tool charges
			return _charge(int(parts[1]), int(parts[2]))
		"rock", "branch", "weed", "stump":
			return _obstacle(parts[0])
		"mine":     # mine:<rock|big_rock|soft|hole>, what lies on a mine floor (MineFloor)
			return _mine(parts[1])
		"crop":     # crop:<id>:<growth 0..3>:<ripe|growing>
			return _crop(parts[1], int(parts[2]), parts[3] == "ripe")
		"item":     # item:<id>, a picked crop held overhead or lying on the ground (12 x 12)
			return _item(parts[1])
		"animal":   # animal:<chicken|chick>:<idle|peck|walk|sick>:<frame>, a farm animal (side view, facing left)
			return _animal(parts[1], parts[2], int(parts[3]))
		"build":    # build:<plaster|board|kawara|thatch|planks|planks_dark|sugi|bamboo|quilt|noren|shoji_door|shoji>
			return _building(parts[1])
		"ground":   # ground:<grass|tilled|wet|path|tatami|floor|earth|gravel|wall|cave|rock_wall|scree>:<variant> or ground:water:<land sides mask>
			return _ground(parts[1], int(parts[2]))
		"fx":       # fx:<rain|snow|splash>, weather particles (white, tinted by the particle colour)
			return _fx(parts[1])
		"fish_fx":  # fish_fx:<bobber|alert>, the float on the water and the "!" of a bite
			return _fish_fx(parts[1])
		"ui":       # ui:<frame|slot|weather|tool|seeds|food|item|cursor|coin|stamina>:<kind>, HUD pieces
			return _ui(parts[1], parts[2] if parts.size() > 2 else "")
		"title":    # title:bg, the title screen picture (480 x 270)
			return _title_bg()
		"face":     # face:<speaker>:<calm|smile|surprised|worried>, a 40 x 40 text box portrait
			return _face(parts[1], parts[2] if parts.size() > 2 else "calm")
	return _draw(16, 16, [[0, 0, 16, 16, "ff00ff"]])


## The icon key for any item id in a slot: tools, seed bags ("seeds:<crop>"), food ("food:<id>"), fish ("fish:<id>"), crops, and a
## wrapped cloth bundle for anything else. The seed bag and food tools show the one chosen now.
static func item_key(id: String, seed := "", food := "") -> String:
	if id == "seeds":
		return "ui:seeds:" + seed
	if id.begins_with("seeds:"):
		return "ui:seeds:" + id.trim_prefix("seeds:")
	if id == "food":
		return "ui:food:" + food
	if id.begins_with("food:"):
		return "ui:food:" + id.trim_prefix("food:")
	if id.begins_with("fish:"):
		return "ui:fish:" + id.trim_prefix("fish:")
	if id.begins_with("mine:"):
		return "ui:mine:" + id.trim_prefix("mine:")
	if id in ["hoe", "can", "sickle", "hammer", "axe", "rod"]:
		return "ui:tool:" + id
	return "ui:item:" + id.replace(":", "_")


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


## The key for an item in the world (held overhead, flying, lying on the ground): a crop as
## its produce sprite, anything else (seeds, food, ...) as its slot icon.
static func world_item_key(id: String) -> String:
	if EGG_SHELLS.has(id):
		return "item:" + id
	crop_look(id)   # fills _looks
	return "item:" + id if _looks.has(id) else item_key(id)


## One piece of produce in the crop's fruit colour, shaped by its look: a root with its leaf
## tuft, a long or round fruit with a calyx, a tuber, a cob in its husk, a ribbed squash.
static func _item(id: String) -> Image:
	if EGG_SHELLS.has(id):
		return _egg(id, 12)
	var look := crop_look(id)
	var img := _blank(12, 12)
	var leaf := Color(look.get("leaf", "5f9e3a"))
	var fruit := Color(look.get("fruit", "e8a23a"))
	var dark := fruit.darkened(0.3)
	var shine := fruit.lightened(0.45)
	var shape: String = look.get("shape", "bush")
	var form: String = look.get("fruit_shape", "round")
	if shape == "root":
		var b: Array = look.get("bulb", [3.5, 3.0])
		_oval(img, 6, 7.5, float(b[0]), maxf(float(b[1]), 2.5), fruit)
		if look.has("fruit_top"):
			_oval(img, 6, 6.0, float(b[0]) - 0.5, 1.3, Color(look.fruit_top))
		_px(img, 6, 10, 1, 1, dark)                       # root tip
		_line(img, Vector2i(6, 4), Vector2i(4, 1), leaf)
		_line(img, Vector2i(6, 4), Vector2i(6, 1), leaf.darkened(0.2))
		_line(img, Vector2i(6, 4), Vector2i(8, 1), leaf)
		_px(img, 4, 6, 1, 1, shine)
	elif shape == "stalk":
		_oval(img, 6, 6.5, 2.2, 4.5, fruit)
		for y in [3, 5, 7, 9]:
			_px(img, 5, y, 1, 1, dark)
		_line(img, Vector2i(3, 10), Vector2i(4, 4), leaf)   # husk leaves on both sides
		_line(img, Vector2i(9, 10), Vector2i(8, 4), leaf.darkened(0.2))
	elif shape == "ground":
		_oval(img, 6, 7, 5.0, 3.6, fruit)
		for x in [3, 6, 9]:
			_px(img, x, 5, 1, 4, dark)
		_px(img, 5, 2, 2, 2, Color("6b4a2a"))                # stem
	elif form == "long":
		_oval(img, 6, 6.5, 2.4, 4.6, fruit)
		_px(img, 5, 1, 3, 2, leaf)                          # calyx
		_px(img, 5, 4, 1, 3, shine)
	elif form == "tuber":
		_oval(img, 6, 6.5, 4.3, 3.3, fruit)
		for p in [Vector2i(4, 5), Vector2i(7, 7), Vector2i(5, 8), Vector2i(8, 5)]:
			img.set_pixelv(p, dark)
		_px(img, 4, 4, 1, 1, shine)
	else:
		_oval(img, 6, 7, 4.0, 3.8, fruit)
		_px(img, 4, 3, 4, 1, leaf)                          # calyx and stem
		_px(img, 6, 2, 1, 1, leaf.darkened(0.2))
		_px(img, 4, 5, 1, 2, shine)
	return _outline(img)


## Egg shells per grade (data/animals.json items): plain white, a warm brown one, and the best
## with a golden blush and a sparkle.
const EGG_SHELLS := {"egg": Color("f2ecdc"), "egg_good": Color("d8b088"), "egg_best": Color("eccb7a")}
const _HEN_WHITE := Color("f4f0e6")
const _HEN_SHADE := Color("d8d0c0")
const _COMB := Color("c8442c")
const _BEAK := Color("e8a23a")
const _CHICK := Color("f2d25a")


## An egg standing on its round end, `size` square (12 in the world, 14 as a slot icon).
static func _egg(id: String, size: int) -> Image:
	var img := _blank(size, size)
	var shell: Color = EGG_SHELLS.get(id, EGG_SHELLS.egg)
	var cx := size / 2.0
	_oval(img, cx, size * 0.58, size * 0.27, size * 0.36, shell.darkened(0.18))
	_oval(img, cx - 0.4, size * 0.56, size * 0.23, size * 0.32, shell)
	_px(img, int(cx) - 2, int(size * 0.38), 1, 2, shell.lightened(0.5))
	if id == "egg_best":
		_px(img, size - 3, 1, 1, 3, Color("fff6c0"))
		_px(img, size - 4, 2, 3, 1, Color("fff6c0"))
	return _outline(img)


## A hen (14 x 12) or a chick (9 x 8) seen from the side, facing left (mirrored for right):
## idle (frame 1 turns the head), peck (head down to the ground), walk (two steps), sick
## (grey, fluffed up, head sunk, eyes shut).
static func _animal(kind: String, pose: String, frame: int) -> Image:
	if kind == "chick":
		return _chick(pose, frame)
	var img := _blank(14, 12)
	var sick := pose == "sick"
	var white := _HEN_WHITE.darkened(0.15) if sick else _HEN_WHITE
	var shade := _HEN_SHADE.darkened(0.15) if sick else _HEN_SHADE
	var legs := 0 if pose != "walk" else frame % 2 + 1
	# Legs and feet.
	for x in [6 + (1 if legs == 1 else 0), 9 - (1 if legs == 2 else 0)]:
		_px(img, x, 9, 1, 2, _BEAK)
		_px(img, x - 1, 11, 2, 1, _BEAK)
	# Tail feathers up behind, the body, a folded wing.
	_px(img, 11, 2, 2, 4, shade)
	_px(img, 12, 1, 1, 2, shade)
	_oval(img, 8, 6.8 if not sick else 7.2, 5.2 if not sick else 5.6, 3.4, white)
	_oval(img, 8.5, 8.4, 4.0, 1.4, shade)
	_line(img, Vector2i(7, 6), Vector2i(10, 7), shade)
	# The head: up and alert, turned, pecking low, or sunk into the shoulders.
	var head := Vector2(3.5, 3.5)
	if pose == "peck":
		head = Vector2(2.5, 7.0 + frame % 2)
	elif sick:
		head = Vector2(4.0, 5.0)
	_oval(img, head.x, head.y, 2.3, 2.2, white)
	var hx := int(head.x)
	var hy := int(head.y)
	_px(img, hx - 1, hy - 3, 3, 1, _COMB)            # comb
	_px(img, hx, hy - 4, 1, 1, _COMB)
	if not (pose == "idle" and frame % 2 == 1):
		_px(img, hx - 3, hy, 2, 1, _BEAK)            # beak, out in front
		_px(img, hx - 2, hy + 1, 1, 2, _COMB)        # wattle
		_px(img, hx - 1, hy - 1, 1, 1, OUTLINE if not sick else shade.darkened(0.4))
	else:
		_px(img, hx - 2, hy, 1, 1, _BEAK)            # head turned: beak towards us
		_px(img, hx - 1, hy + 1, 1, 1, _COMB)
		_px(img, hx, hy - 1, 1, 1, OUTLINE)
	return _outline(img)


static func _chick(pose: String, frame: int) -> Image:
	var img := _blank(9, 8)
	var body := _CHICK.darkened(0.2) if pose == "sick" else _CHICK
	var low := pose == "peck"
	var step := frame % 2 if pose == "walk" else 0
	_px(img, 4 - step, 6, 1, 2, _BEAK)
	_px(img, 6 + step, 6, 1, 2, _BEAK)
	_oval(img, 5, 4.5, 3.4, 2.4, body)
	_oval(img, 2.5 if not low else 2.0, 2.5 if not low else 4.5, 1.8, 1.8, body)
	var hy := 2 if not low else 4
	_px(img, 0, hy + 1, 1, 1, _BEAK)
	_px(img, 2, hy, 1, 1, OUTLINE)
	_px(img, 5, 4, 2, 1, body.darkened(0.15))         # little wing
	return _outline(img)


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
	# Holding: both arms up by the head steadying the item overhead (the hand shifts are
	# unused); shorter, careful steps, and the load bobs with the body.
	"hold_idle": [[0, 0, 0, 0, 0, 0, 0]],
	"hold_walk": [[1, -2, 0, 2, 0, 0, 0], [0, 0, 0, 0, 2, 0, 0], [1, 2, 0, -2, 0, 0, 0], [0, 0, 2, 0, 0, 0, 0]],
	# Fishing: both hands together in front on the rod butt (hand shifts towards the water);
	# waiting the rod stands up still, on a bite the farmer leans in and the tip jerks down.
	"fish_wait": [[0, 0, 0, 0, 0, -1, -5]],
	"fish_bite": [[1, -1, 0, 1, 0, -1, -5], [1, -1, 0, 1, 0, -1, -5]],
}
## The rod's tip per fishing pose frame, in sprite pixels (the line starts here).
const _ROD_TIPS := {"fish_wait": [Vector2i(0, 1)], "fish_bite": [Vector2i(0, 8), Vector2i(0, 6)]}
const _ROD := Color("c8a85a")
const _ROD_NODE := Color("8a6a32")
const _SWEAT := Color("9fd8f2")


static func farmer_frames(pose: String) -> int:
	return _FARMER_POSES[pose].size()


## Where the rod tip is in a fishing frame (sprite pixels, front view facing left).
static func rod_tip(pose: String, frame: int) -> Vector2i:
	var tips: Array = _ROD_TIPS.get(pose, [Vector2i(0, 1)])
	return tips[frame % tips.size()]


## How many pixels a frame drops the body (and what the raised hands hold) below its rest.
static func farmer_drop(pose: String, frame: int) -> int:
	return _FARMER_POSES[pose][frame % farmer_frames(pose)][0]


## Draw order back to front: far hand, far leg, near leg, body, bag, near hand. The bag hangs
## at the farmer's back on the front view and at the front on the back view.
static func _player(back: bool, pose: String, frame: int) -> Image:
	var p: Array = _FARMER_POSES[pose][frame % farmer_frames(pose)]
	var tired := pose.begins_with("tired")
	var arms: int = p[0] + int(tired)   # tired arms hang a pixel lower
	var hold := pose.begins_with("hold")
	var img := Image.create_empty(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if not hold:
		_hand(img, 11 + p[6], 14 + arms)
	_leg(img, 8 + p[3], p[4])
	_leg(img, 5 + p[1], p[2])
	_map(img, _FARMER_BACK if back else _FARMER_FRONT, p[0])
	var bag_x := 1 if back else 11
	img.fill_rect(Rect2i(bag_x, 14 + p[0], 4, 5), Color(_FARMER_COLORS.o))
	img.fill_rect(Rect2i(bag_x + 1, 15 + p[0], 2, 3), Color(_FARMER_COLORS.y))
	if hold:
		_raised_arm(img, 1, p[0])
		_raised_arm(img, 13, p[0])
	else:
		_hand(img, 4 + p[5], 14 + arms)
	if _ROD_TIPS.has(pose):   # the bamboo rod from the hands up to its tip, a node every few px
		var tip := rod_tip(pose, frame)
		var butt := Vector2i(4 + p[5], 15 + arms)
		_line(img, butt, tip, _ROD)
		for t in [0.3, 0.6]:
			var q := Vector2(butt).lerp(Vector2(tip), t).round()
			_px(img, int(q.x), int(q.y), 1, 1, _ROD_NODE)
	if tired:   # a drop of sweat by the brow: in front of the face, or behind the head seen from the back
		var sx := 14 if back else 1
		img.fill_rect(Rect2i(sx, 4 + p[0], 1, 1), Color.WHITE)
		img.fill_rect(Rect2i(sx, 5 + p[0], 1, 2), _SWEAT)
	return img


## An arm lifted from the shoulder up the side of the head, its hand at the top of the cap
## where the held item rests (the view draws the item just above the sprite).
static func _raised_arm(img: Image, x: int, dy: int) -> void:
	img.fill_rect(Rect2i(x - 1, dy, 4, 12), Color(_FARMER_COLORS.o))
	img.fill_rect(Rect2i(x, 3 + dy, 2, 8), Color(_FARMER_COLORS.b))
	img.fill_rect(Rect2i(x, 10 + dy, 2, 1), Color(_FARMER_COLORS.B))
	img.fill_rect(Rect2i(x, dy, 2, 2), Color(_FARMER_COLORS.s))


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


## Villager frames, 16 x 24 like the farmer and seen the same way (front = three-quarters
## towards Down, back = towards Left; mirrored for Right / Up). The head is a hair style over
## a shared face, the body an outfit; colours come from the villager's look (hair, skin, top,
## waist, lower, accent, shoes; darker shades are worked out). Map letters: o outline,
## h / H hair, s / S skin, e eye, a / A accent (hat, headband, hairpin), t / T top, w waist
## (obi, sash), l / L lower (trousers, shorts).
const VILLAGER_STYLES: Array[String] = ["bun", "short", "headband", "long", "straw_hat"]
const VILLAGER_OUTFITS: Array[String] = ["kimono", "happi", "shirt_shorts"]
const _VILLAGER_HEADS := {
	"bun": [[
		"..........ooo...", ".....ooooohhho..", "....ohhhhhhhhho.", "...ohhhhhhhhhho.", "..ohhssssshhhho.",
	], [
		"......ooo.......", ".....ohhho......", "....ohhhhhoo....", "...ohhhhhhhhho..", "..oHhhhhhhhhho..",
	]],
	"short": [[
		"................", ".....ooooooo....", "....ohhhhhhhoo..", "...ohhhhhhhhhho.", "..ohhhsssshhhho.",
	], [
		"................", ".....ooooooo....", "....ohhhhhhhoo..", "...ohhhhhhhhhho.", "..oHhhhhhhhhho..",
	]],
	"headband": [[
		"................", ".....ooooooo....", "....ohhhhhhhoo..", "...oaaaaaaaaaaoo", "..ohhsssssshhhoA",
	], [
		"................", ".....ooooooo....", "....ohhhhhhhoo..", "oo.oaaaaaaaaaao.", "Ao.oHhhhhhhhho..",
	]],
	"long": [[
		"................", ".....oooooooo...", "....ohhhhhhhhoa.", "...ohhhhhhhhhhoa", "..ohhsssssshhhho",
	], [
		"................", ".....oooooooo...", ".aoohhhhhhhhho..", "aohhhhhhhhhhho..", "..oHhhhhhhhhho..",
	]],
	"straw_hat": [[
		"......oooo......", ".....oaaaaoo....", "....oaaaaaaao...", ".ooAAAAAAAAAAAoo", "..ohhsssssshhho.",
	], [
		"......oooo......", ".....oaaaaoo....", "....oaaaaaaao...", ".ooAAAAAAAAAAAoo", "..oHhhhhhhhhho..",
	]],
}
const _VILLAGER_FACE := [
	"..osssssssshhho.", "..osessessShho..", "..osessessShho..", "...oSssssSSoo...", ".....oSSSoo.....",
]
const _VILLAGER_NAPE := [
	"..oShhhhhhhhho..", "..oshhhhhhhhho..", "..oHhhhhhhhhHo..", "...oSHhhhhhHo...", ".....oSSSoo.....",
]
## Rows 10 down; a kimono runs on to the ankles, the others stop where the legs start (16).
const _VILLAGER_BODIES := {
	"kimono": [
		"....otTttTto....", "...ottTttTtto...", "...owwwwwwwwo...", "...otttttttTo...", "...otttttttTo...",
		"...otttttttTo...", "...otttttttTo...", "...otttttttTo...", "...otttttttTo...", "...otttttttTo...",
		"...otttttttTo...", "...oTTTTTTTTo...",
	],
	"happi": [
		"....otTttTto....", "...ottTttTtto...", "...owwwwwwwwo...", "...otttttttTo...", "...oTttttttTo...",
		"....ollllllo....", "....ollllllo....",
	],
	"shirt_shorts": [
		"....otttttto....", "...otttttttto...", "...otttttttto...", "...oTttttttTo...", "....ollllllo....",
		"....ollllllo....", "....oLLLLLLo....",
	],
}


## The villager's picture for a pose and frame; `walk` frames step like the farmer's walk.
static func _villager(look: Dictionary, back: bool, pose: String, frame: int) -> Image:
	var p: Array = _FARMER_POSES["walk" if pose == "walk" else "idle"][frame % farmer_frames("walk" if pose == "walk" else "idle")]
	var style := str(look.get("hair_style", "short"))
	var outfit := str(look.get("outfit", "happi"))
	var c := _villager_colors(look)
	var img := _blank(16, 24)
	var hand := func(x: int, y: int) -> void:
		_px(img, x - 1, y, 4, 3, c.o)
		_px(img, x, y, 2, 2, c.s)
	hand.call(11 + p[6], 14 + p[0])
	if outfit == "kimono":   # short steps under the robe: only the sandals show
		for f in [[8 + p[3], p[4]], [5 + p[1], p[2]]]:
			_px(img, f[0] - 1, 21 - mini(f[1], 1), 5, 3, c.o)
			_px(img, f[0], 22 - mini(f[1], 1), 3, 1, c.k)
	else:
		var shin: Color = c.s if outfit == "shirt_shorts" else c.l
		for f in [[8 + p[3], p[4]], [5 + p[1], p[2]]]:
			var bottom: int = 23 - f[1]
			_px(img, f[0] - 1, 16, 5, bottom - 15, c.o)
			_px(img, f[0], 16, 3, bottom - 19, shin)
			_px(img, f[0], bottom - 3, 3, 3, c.k)
	var head: Array = _VILLAGER_HEADS.get(style, _VILLAGER_HEADS.short)[1 if back else 0]
	var rows: Array = head + (_VILLAGER_NAPE if back else _VILLAGER_FACE) + _VILLAGER_BODIES.get(outfit, _VILLAGER_BODIES.happi)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != "." and y + p[0] < 24:
				img.set_pixel(x, y + p[0], c[row[x]])
	hand.call(4 + p[5], 14 + p[0])
	return img


static func _villager_colors(look: Dictionary) -> Dictionary:
	var pick := func(k: String, fallback: String) -> Color:
		return Color(str(look.get(k, fallback)))
	var c := {"o": OUTLINE, "e": Color("2a2a3a"), "h": pick.call("hair", "2a2422"), "s": pick.call("skin", "f2c79b"),
		"a": pick.call("accent", "e0c070"), "t": pick.call("top", "6a7a8a"), "w": pick.call("waist", "c8a050"),
		"l": pick.call("lower", "3a3430"), "k": pick.call("shoes", "6b4423")}
	for k in ["h", "s", "a", "t", "l"]:
		c[k.to_upper()] = (c[k] as Color).darkened(0.25)
	return c


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


static var _food_looks := {}
static var _fish_looks := {}
static var _mine_looks := {}


## A fish's icon look from data/fish.json (body, belly, fin colours and a shape).
static func fish_look(id: String) -> Dictionary:
	if _fish_looks.is_empty():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fish.json"))
		for k in data.get("fish", {}):
			_fish_looks[k] = data.fish[k].get("look", {})
	return _fish_looks.get(id, {})


## A mine find's icon look from data/mine.json (shape, body, shine / vein colours).
static func mine_look(id: String) -> Dictionary:
	if _mine_looks.is_empty():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/mine.json"))
		for k in data.get("items", {}):
			_mine_looks[k] = data.items[k].get("look", {})
	return _mine_looks.get(id, {})


## A food's icon look from data/foods.json (shape, color, accent).
static func food_look(id: String) -> Dictionary:
	if _food_looks.is_empty():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json"))
		for k in data.get("foods", {}):
			_food_looks[k] = data.foods[k].get("look", {})
	return _food_looks.get(id, {})


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


## A mine floor's pieces. Rocks stand up as sprites: a rock is 16 x 16 (dark cave stone
## with a pale chip), a big rock 24 x 20 (a split boulder with a seam). The soft spot and the
## hole lie flat on the ground (16 x 16): a mound of loose dark earth with cracks, and a black
## pit with the top of a ladder in it.
static func _mine(kind: String) -> Image:
	match kind:
		"rock":
			var img := _blank(16, 16)
			_oval(img, 8, 10.5, 6.5, 4.5, Color("4e463e"))
			_oval(img, 7.5, 9.5, 5.5, 3.6, Color("6e655a"))
			_px(img, 5, 7, 3, 1, Color("9a9084"))
			_px(img, 10, 10, 1, 2, Color("3a342e"))
			_px(img, 8, 12, 2, 1, Color("3a342e"))
			return _outline(img)
		"big_rock":
			var img := _blank(24, 20)
			_oval(img, 12, 12.5, 10.5, 7.0, Color("463e38"))
			_oval(img, 11.5, 11.5, 9.0, 6.0, Color("665c52"))
			_oval(img, 8.5, 9.5, 4.0, 2.4, Color("7a7064"))
			_line(img, Vector2i(13, 6), Vector2i(15, 17), Color("2e2824"))   # the seam
			_line(img, Vector2i(14, 11), Vector2i(19, 13), Color("2e2824"))
			_px(img, 6, 8, 4, 1, Color("a09484"))
			return _outline(img)
		"soft":
			var img := _blank(16, 16)
			_oval(img, 8, 8.5, 6.5, 5.5, Color("3e3028"))
			_oval(img, 8, 8, 5.5, 4.5, Color("6a5440"))
			for p in [Vector2i(5, 6), Vector2i(9, 5), Vector2i(11, 9), Vector2i(6, 10), Vector2i(8, 8)]:
				_px(img, p.x, p.y, 2, 1, Color("806650"))
			_line(img, Vector2i(4, 8), Vector2i(7, 9), Color("3a2c22"))
			_line(img, Vector2i(9, 10), Vector2i(12, 7), Color("3a2c22"))
			return img
		"hole":
			var img := _blank(16, 16)
			_oval(img, 8, 8, 7.0, 6.5, Color("2a221c"))
			_oval(img, 8, 8.5, 5.8, 5.2, Color("0c0a08"))
			for x in [5, 10]:   # the ladder's rails and rungs going down
				_px(img, x, 4, 1, 9, Color("8a6a3a"))
			for y in [5, 8, 11]:
				_px(img, 5, y, 6, 1, Color("a8844a"))
			return img
	return _draw(16, 16, [[0, 0, 16, 16, "ff00ff"]])


## A mine find as a 14 x 14 icon from its look: a rounded stone, a lump of clay, a heap of
## black sand, a lump of rock with a bright vein of ore, a cut gem, an amber drop, a crystal.
static func _mine_icon(look: Dictionary) -> Image:
	var img := _blank(14, 14)
	var body := Color(look.get("body", "8e8a84"))
	var shine := Color(look.get("shine", body.lightened(0.4).to_html()))
	match look.get("shape", "stone"):
		"stone":
			_oval(img, 7, 8, 5.5, 4.2, body)
			_px(img, 4, 6, 3, 1, shine)
			_px(img, 9, 10, 2, 1, body.darkened(0.25))
		"lump":
			_oval(img, 7, 8.5, 5.0, 3.8, body)
			_oval(img, 6, 6.5, 3.0, 2.0, body.lightened(0.08))
			_px(img, 4, 6, 2, 1, shine)
			_line(img, Vector2i(5, 10), Vector2i(9, 9), body.darkened(0.25))   # a thumb mark
		"sand":
			for y in range(5, 12):
				var half := (y - 4) + 1
				_px(img, 7 - half, y, half * 2, 1, body)
			for p in [Vector2i(6, 6), Vector2i(4, 9), Vector2i(8, 8), Vector2i(10, 10), Vector2i(7, 10)]:
				img.set_pixelv(p, shine)
		"ore":
			var vein := Color(look.get("vein", "c8643a"))
			_oval(img, 7, 8, 5.8, 4.5, body)
			_oval(img, 6, 7, 3.5, 2.5, body.lightened(0.12))
			_line(img, Vector2i(3, 9), Vector2i(10, 5), vein)
			_line(img, Vector2i(6, 11), Vector2i(10, 9), vein)
			_px(img, 8, 6, 1, 1, vein.lightened(0.4))
		"gem":
			for y in 4:   # the crown widening, then the point
				_px(img, 4 - y, 3 + y, 6 + y * 2, 1, body.lightened(0.15))
			for y in 5:
				_px(img, 1 + y, 7 + y, 12 - y * 2, 1, body)
			_px(img, 4, 4, 2, 1, shine)
			_px(img, 2, 7, 10, 1, body.darkened(0.2))
		"drop":
			_oval(img, 7, 8.5, 4.2, 4.0, body)
			for y in 3:
				_px(img, 6 - y / 2, 3 + y, 2 + y, 1, body)
			_px(img, 5, 7, 2, 2, shine)
			_px(img, 8, 10, 1, 1, body.darkened(0.25))   # something old caught inside
		"crystal":
			for i in 3:   # three points from a cluster
				var x := 3 + i * 3
				var tall := 8 - absi(i - 1) * 2
				_px(img, x, 12 - tall, 3, tall, body)
				_px(img, x + 1, 11 - tall, 1, 1, body)
				_px(img, x, 12 - tall, 1, tall, shine)
			_px(img, 2, 11, 10, 2, Color("6a625a"))   # the rock it grows from
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
		"straw":
			# Rice straw spread on the coop's earth floor: pale gold stalks lying every way.
			img.fill(Color("8c7a62"))
			for i in 22:
				var x := rng.randi_range(0, 13)
				var y := rng.randi_range(0, 15)
				var c := Color("d8bc78") if i % 3 else Color("b89a5a")
				if i % 2 == 0:
					_px(img, x, y, 3, 1, c)
				else:
					_line(img, Vector2i(x, y), Vector2i(x + 2, y - 2), c)
		"gravel":
			# Raked shrine gravel: light grey stones on a paler ground.
			img.fill(Color("c8c4b8"))
			for i in 16:
				var x := rng.randi_range(0, 14)
				var y := rng.randi_range(0, 15)
				_px(img, x, y, 2, 1, Color("a8a498") if i % 2 == 0 else Color("dedad0"))
		"wall":
			img.fill(Color("3e3028"))
		"cave":
			# The mine floor: trodden dark earth with grit and a flat stone here and there.
			img.fill(Color("5a4c40"))
			for i in 12:
				var x := rng.randi_range(0, 15)
				var y := rng.randi_range(0, 15)
				_px(img, x, y, 1, 1, Color("4a3e34") if i % 2 == 0 else Color("6e6052"))
			if n % 2 == 0:
				_px(img, rng.randi_range(2, 10), rng.randi_range(2, 11), 3, 2, Color("6a625a"))
		"rock_wall":
			# Bare rock: dark grey-brown blocks split by black cracks, lit on their top edges.
			img.fill(Color("4e4640"))
			for i in 5:
				var x := rng.randi_range(0, 12)
				var y := rng.randi_range(0, 12)
				_px(img, x, y, rng.randi_range(3, 6), 1, Color("6a625a"))
				_px(img, x, y + 1, 1, rng.randi_range(2, 4), Color("2e2824"))
		"scree":
			# Loose grey rubble under the cliff.
			img.fill(Color("9a9086"))
			for i in 14:
				var x := rng.randi_range(0, 14)
				var y := rng.randi_range(0, 15)
				_px(img, x, y, 2, 1, Color("7a7068") if i % 2 == 0 else Color("b8b0a4"))
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
		"thatch":
			# A thick thatched roof of grass (kaya): straw-gold strands running down the slope
			# (texture v), darker weathered ones between, a cut edge line every 8 px.
			var img := _blank(16, 16)
			img.fill(Color("a88a52"))
			for i in 24:
				var x := rng.randi_range(0, 15)
				var y := rng.randi_range(0, 13)
				_px(img, x, y, 1, rng.randi_range(2, 4), Color("c4a868") if i % 2 else Color("806838"))
			for row in 2:
				_px(img, 0, row * 8 + 7, 16, 1, Color("6a5430"))
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
		"item":     # item:<id>, 14 x 14: a crop as its fruit, anything else a wrapped bundle
			return _item_icon(arg)
		"cursor":   # vermilion corner brackets round the slot under the menu cursor, 22 x 22
			var c := UI_SEAL
			return _draw(22, 22, [[0, 0, 6, 2, c], [0, 0, 2, 6, c], [16, 0, 6, 2, c], [20, 0, 2, 6, c],
				[0, 20, 6, 2, c], [0, 16, 2, 6, c], [16, 20, 6, 2, c], [20, 16, 2, 6, c]])
		"food":     # food:<id>, 14 x 14, drawn from the food's look in data/foods.json
			return _food_icon(food_look(arg))
		"fish":     # fish:<id>, 14 x 14, drawn from the fish's look in data/fish.json
			return _fish_icon(fish_look(arg))
		"mine":     # mine:<id>, 14 x 14, a stone, ore or gem from its look in data/mine.json
			return _mine_icon(mine_look(arg))
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


## A crop (data/crops.json) as its fruit with a leaf tuft, in the crop's own colours; any
## other id as a furoshiki bundle, the cloth colour picked from the id so items differ.
static func _item_icon(id: String) -> Image:
	if EGG_SHELLS.has(id):
		return _egg(id, 14)
	var img := _blank(14, 14)
	var look := crop_look(id)
	if _looks.has(id):
		var fruit := Color(look.get("fruit", "e8a23a"))
		var leaf := Color(look.get("leaf", "5fa83a"))
		var long: bool = look.get("shape", "") in ["vine", "stalk"]
		var rx := 2.5 if long else 4.0
		var ry := 5.0 if long else 4.0
		_oval(img, 7, 8.5, rx, ry, fruit.darkened(0.25))
		_oval(img, 6.5, 8, rx - 0.7, ry - 0.7, fruit)
		_px(img, 5, 6, 2, 1, fruit.lightened(0.35))
		if look.has("fruit_top"):
			_px(img, 4, 5, 6, 2, Color(look.fruit_top))
		_px(img, 6, 1, 2, 4, leaf)
		_px(img, 4, 2, 2, 2, leaf)
		_px(img, 8, 2, 2, 2, leaf.darkened(0.2))
		return _outline(img)
	var cloths := [Color("3a5a8c"), Color("a8433a"), Color("5a8a4a"), Color("c8963a"), Color("7a4a8a")]
	var cloth: Color = cloths[posmod(hash(id), cloths.size())]
	_oval(img, 7, 9, 5.5, 4.0, cloth)
	_px(img, 5, 3, 4, 3, cloth)
	_px(img, 3, 2, 3, 2, cloth.darkened(0.2))   # the knot's ears
	_px(img, 8, 2, 3, 2, cloth.darkened(0.2))
	_px(img, 6, 4, 2, 2, cloth.lightened(0.3))
	for p in [Vector2i(4, 9), Vector2i(8, 8), Vector2i(10, 11), Vector2i(6, 11)]:
		img.set_pixelv(p, Color("f4ecd8"))
	return _outline(img)


## A fish seen from the side, head left: a body shape (deep, long, slim, trout, eel,
## catfish) in its body colour with a pale belly, a forked tail and a fin, an eye.
static func _fish_icon(look: Dictionary) -> Image:
	var img := _blank(14, 14)
	var body := Color(look.get("body", "8a8a6a"))
	var belly := Color(look.get("belly", "d8d0a8"))
	var fin := Color(look.get("fin", "5a5a3a"))
	var shape: String = look.get("shape", "long")
	var ry: float = {"deep": 3.6, "long": 2.8, "slim": 2.0, "trout": 2.6, "eel": 1.3, "catfish": 2.6}.get(shape, 2.6)
	var rx := 5.5 if shape == "eel" else 4.5
	var cy := 7.0
	if shape == "eel":   # a long wavy body over the whole icon
		for x in range(1, 13):
			var y := cy + sin(x * 0.7) * 1.2
			_px(img, x, roundi(y - ry), 1, 2, body)
			_px(img, x, roundi(y - ry) + 2, 1, 1, belly)
	else:
		_oval(img, 6.0, cy, rx, ry, body)
		_oval(img, 6.0, cy + ry * 0.45, rx - 1.0, ry * 0.45, belly)
		for i in 3:   # the forked tail
			_px(img, 10 + i, int(cy) - 1 - i, 1, 1 + i, fin)
			_px(img, 10 + i, int(cy) + 1, 1, 1 + i, fin)
		_px(img, 5, int(cy - ry) - 1, 3, 1, fin)   # back fin
		if shape == "trout":
			for p in [Vector2i(4, 6), Vector2i(7, 5), Vector2i(8, 7)]:
				img.set_pixelv(p, fin)
	if shape == "catfish":
		_line(img, Vector2i(2, int(cy)), Vector2i(0, int(cy) + 3), fin)   # whiskers
		_line(img, Vector2i(2, int(cy) - 1), Vector2i(0, int(cy) - 3), fin)
	_outline(img)
	img.set_pixel(3 if shape != "eel" else 1, int(cy) - 1, Color("1a1a1a"))
	return img


## The float and the bite mark. The bobber is red over white with a dark stem (5 x 7); the
## alert a vermilion "!" on a paper bubble (7 x 11).
static func _fish_fx(kind: String) -> Image:
	match kind:
		"bobber":
			var img := _blank(5, 7)
			_px(img, 2, 0, 1, 1, Color("2a1e1e"))
			_oval(img, 2.5, 3.0, 2.0, 1.6, Color("d8402a"))
			_oval(img, 2.5, 5.0, 2.0, 1.4, Color("f4ecd8"))
			_px(img, 1, 2, 1, 1, Color("f08a6a"))
			return img
		"alert":
			var img := _blank(7, 11)
			_px(img, 0, 0, 7, 11, OUTLINE)
			_px(img, 1, 1, 5, 9, UI_PAPER)
			_px(img, 3, 2, 1, 4, UI_SEAL)
			_px(img, 2, 2, 3, 3, UI_SEAL)
			_px(img, 3, 7, 1, 2, UI_SEAL)
			for p in [Vector2i(0, 0), Vector2i(6, 0), Vector2i(0, 10), Vector2i(6, 10)]:
				img.set_pixelv(p, Color(0, 0, 0, 0))
			return img
	return _draw(4, 4, [[0, 0, 4, 4, "ff00ff"]])


## Food shapes: a rice ball with a nori band, a round sweet on its leaf, three dumplings on
## a stick, a cup with a saucer line, a glass bottle with a paper cap.
static func _food_icon(look: Dictionary) -> Image:
	var img := _blank(14, 14)
	var c := Color(look.get("color", "fbf8f0"))
	var a := Color(look.get("accent", "26302a"))
	match look.get("shape", ""):
		"rice_ball":
			for y in 9:
				var half := (y + 1) / 2 + 1
				_px(img, 7 - half, y + 2, half * 2, 1, c)
			_px(img, 5, 8, 4, 4, a)
			img.set_pixel(4, 4, c.darkened(0.08))
		"round":
			_oval(img, 7, 10, 5.5, 2.0, a)
			_oval(img, 7, 7.5, 4.5, 3.5, c)
			_oval(img, 5.5, 6, 1.5, 1.0, c.lightened(0.4))
		"skewer":
			_line(img, Vector2i(2, 12), Vector2i(12, 2), Color("c8a060"))
			_oval(img, 4.5, 9.5, 2.2, 2.2, a)
			_oval(img, 7, 7, 2.2, 2.2, Color("fbf8f0"))
			_oval(img, 9.5, 4.5, 2.2, 2.2, c)
		"cup":
			_px(img, 2, 12, 10, 1, a.darkened(0.2))
			_px(img, 3, 5, 8, 7, a)
			_px(img, 4, 5, 6, 2, c)
			_px(img, 4, 7, 6, 4, a.lightened(0.15))
			_outline(img)
			for x in [5, 8]:   # steam, after the outline so it stays soft
				_px(img, x, 1 + x % 2, 1, 2, Color(1, 1, 1, 0.7))
			return img
		"bottle":
			_px(img, 4, 4, 6, 9, c)
			_px(img, 5, 2, 4, 2, c)
			_px(img, 5, 1, 4, 2, a)
			_px(img, 4, 7, 6, 3, a.lightened(0.3))
		_:
			_px(img, 3, 3, 8, 8, c)
	return _outline(img)


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
		"rod":   # a bamboo rod, its line hanging to a red float
			_line(img, Vector2i(1, 12), Vector2i(10, 1), _ROD)
			_line(img, Vector2i(2, 12), Vector2i(4, 10), _ROD_NODE)
			for p in [Vector2i(4, 9), Vector2i(7, 5)]:
				img.set_pixelv(p, _ROD_NODE)
			_outline(img)
			_line(img, Vector2i(11, 2), Vector2i(11, 9), Color("e8e8e8"))   # line, no outline
			_px(img, 10, 10, 3, 2, Color("d8402a"))
			_px(img, 10, 12, 3, 1, Color("f4ecd8"))
			return img
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
