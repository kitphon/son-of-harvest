class_name PlaceholderArt
extends RefCounted
## Small pixel textures made in code, so the game runs before there is real art.
## Replace each key with a real sprite file later.

static var _cache := {}
static var _images := {}   # key -> its picture as an RGBA8 Image (image(); for laying tiles)


## The farmer's pictures ("player:...") follow the chosen look, so they are kept per look
## (FarmerLooks.cache_key); every other key is kept as it is.
static func tex(key: String) -> Texture2D:
	var ck := FarmerLooks.cache_key(key)
	if not _cache.has(ck):
		_cache[ck] = ImageTexture.create_from_image(_make(key))
	return _cache[ck]


## The picture of `key` as an RGBA8 Image, kept (the 3D grounds lay thousands of tiles; reading
## each back from its texture was most of a map's ground). Shared: copy before changing it.
static func image(key: String) -> Image:
	var ck := FarmerLooks.cache_key(key)
	if not _images.has(ck):
		var img := _make(key)
		img.convert(Image.FORMAT_RGBA8)
		_images[ck] = img
	return _images[ck]


static func _make(key: String) -> Image:
	var parts := key.split(":")
	match parts[0]:
		"player":   # player:<front|back>:<idle|walk|run|tired_idle|tired_walk|hold_idle|hold_walk|fish_wait|fish_bite|eat|drink|scoop|scoop_lift>:<frame>, 24 x 32 (FigureArt), in the chosen look (FarmerLooks.current)
			return FigureArt.draw(FarmerLooks.current_look(), parts[1] == "back", parts[2], int(parts[3]), true)
		"villager": # villager:<id>:<front|back>:<idle|walk|work|fish|post|pole>:<frame>, 24 x 32, from the look in data/villagers/<id>.json
			return FigureArt.draw(Villagers.look(parts[1]), parts[2] == "back", parts[3], int(parts[4]))
		"roof":   # roof:<kawara|thatch|kaya>:<gable|hip>:<storeys>:<w>:<h>, a roof seen from above (RoofArt)
			return RoofArt.draw(parts)
		"target":   # corner brackets laid on the cell the tool will hit
			var c := Color(1, 1, 1, 0.85)
			return _draw(16, 16, [[0, 0, 5, 1, c], [0, 0, 1, 5, c], [11, 0, 5, 1, c], [15, 0, 1, 5, c],
				[0, 15, 5, 1, c], [0, 11, 1, 5, c], [11, 15, 5, 1, c], [15, 11, 1, 5, c]])
		"charge":   # charge:<steps>:<max>, pips over the farmer while a tool charges
			return _charge(int(parts[1]), int(parts[2]))
		"rock", "branch", "weed", "stump":
			return _obstacle(parts[0])
		"mine":     # mine:<rock|big_rock|ice|soft|hole|frost|landing>, what lies on a mine floor (MineFloor; landing: the rope lift's cage); mine:lantern, the farmer's
			return _mine(parts[1])
		"crop":     # crop:<id>:<growth 0..3>:<ripe|growing>
			return _crop(parts[1], int(parts[2]), parts[3] == "ripe")
		"stalk":    # stalk:<id>:<growth 2..3>:<ripe|growing>:<variant 0..2>, one plant of a tall crop's cluster in the 3D view (CropClusters); stalk:rice:0:stubble:<variant>, the cut rice in winter
			if parts[3] == "stubble":
				return _stubble(int(parts[4]))
			return _stalk(parts[1], int(parts[2]), parts[3] == "ripe", int(parts[4]) if parts.size() > 4 else 0)
		"patch":    # patch:paddy_water, a still puddle between the paddy rows in winter (CropClusters.plant_water)
			return _paddy_water()
		"item":     # item:<id>, a picked crop held overhead or lying on the ground (12 x 12)
			return _item(parts[1])
		"animal":   # animal:<chicken|chick|cow|calf|sheep|sheep_shorn|lamb|dog>:<idle|peck|walk|sick, dog: sit|held>:<frame>[:<dl|dr|ul|ur>], AnimalArt (twice the farmer's pixel density; the dog "held" is the small old one)
			if parts[1] == "dog" and parts[2] == "held":
				return _beast(parts[1], parts[2], int(parts[3]))
			return AnimalArt.make(parts[1], parts[2], int(parts[3]), parts[4] if parts.size() > 4 else "dl")
		"build":    # build:<plaster|tsuchi|board|kawara|kawara_edge|thatch|kaya|kaya_edge|hay|planks|planks_dark|sugi|bamboo|quilt|noren|shoji_door|shoji>
			return _building(parts[1])
		"ground":   # ground:<grass|tilled|wet|path|tatami|floor|earth|gravel|wall|cave|rock_wall|scree|paddy>:<variant> or ground:water:<land sides mask>
			return _ground(parts[1], int(parts[2]))
		"fx":       # fx:<rain|snow|splash>, weather particles (white, tinted by the particle colour); fx:<note|notes>, a whistler's note puff
			return _fx(parts[1])
		"cloth":    # cloth:<hex>, one indigo length drying over a pole (DyeCloth: 22 x 24, the pole across the top)
			return _dye_cloth(Color(parts[1]))
		"fish_fx":  # fish_fx:<bobber|alert>, the float on the water and the "!" of a bite
			return _fish_fx(parts[1])
		"tree":     # tree:maple:<spring|summer|fall|winter>:<snow 0|1>, a Japanese maple in the flat view (MapView), 24 x 32
			return _maple_tree(parts[2], parts[3] == "1")
		"ui":       # ui:<frame|slot|weather|tool|seeds|food|item|cursor|coin|stamina|heart>:<kind>, HUD pieces
			return _ui(parts[1], parts[2] if parts.size() > 2 else "")
		"title":    # title:bg, the title screen picture (480 x 270)
			return _title_bg()
		"face":     # face:<speaker>:<calm|smile|surprised|worried>, a 40 x 40 text box portrait
			return _face(parts[1], parts[2] if parts.size() > 2 else "calm")
		"portrait": # portrait:<villager>:<neutral|happy|sad|surprised|angry>, a villager's 40 x 40 text box portrait; portrait:child:<mood>:<crawler|toddler|child>:<style>:<skin>:<hair>:<top> the little one's (Child.portrait_key)
			if parts[1] == Child.ID and parts.size() > 7:   # portrait:child:<mood>:<stage>:<style>:<skin>:<hair>:<top>
				return _child_portrait(parts[2], parts[3], _little_look(PackedStringArray(["", "", "", parts[4], parts[5], parts[6], parts[7]])))
			return _portrait(parts[1], parts[2] if parts.size() > 2 else "neutral")
		"story":    # story:<door_bell|sign_old|sign_new|boat_father|boat_new|noren_rows|noren_flowers|noren_shino|ume_jar|carp_streamer|scion:<sapling|young|tree>:<season>:<snow 0|1>[:<persimmons shown>]|lumber|rope_lift|jizo_bibs|jizo_scarf|kiln_mark|kiln_site|kiln_new|kiln_worn|captain_jar|frog|ribbon_board:<places>|sky_map:<steady|beside>:<near|field>>, things the story leaves in the world (StoryProps)
			if parts[1] == "scion":
				return _scion_story(parts[2] if parts.size() > 2 else "sapling", parts[3] if parts.size() > 3 else "spring", parts.size() > 4 and parts[4] == "1", int(parts[5]) if parts.size() > 5 else -1)
			if parts[1] == "sky_map":
				return _sky_map(parts[2] if parts.size() > 2 else "steady", parts[3] if parts.size() > 3 else "near")
			return _ribbon_board(parts[2] if parts.size() > 2 else "") if parts[1] == "ribbon_board" else _story(parts[1])
		"festival": # festival:<kind>:<w>x<h>[:<cloth hex>], a festival decoration in the flat view (FestivalView)
			var wh := parts[2].split("x") if parts.size() > 2 else PackedStringArray(["1", "1"])
			return _festival(parts[1], int(wh[0]), int(wh[1]), Color(parts[3]) if parts.size() > 3 else Color("c8442c"))
		"child":    # child:<cradle|held>:<empty|asleep|awake|cry>:<skin>:<hair>:<top>, the baby in its bamboo cradle (20 x 14) or held up in the arms (12 x 12), in the child's colours (Child.look); child:carry:<style>:<skin>:<hair>:<top>, the crawler held up in the arms (16 x 14, Child.carry_key); child:figure:<crawler|toddler|child>:<style>:<skin>:<hair>:<top>:<front|back>:<idle|walk>:<frame>, the little one about the house (24 x 32, FigureArt.draw_little)
			if parts[1] == "figure":
				return FigureArt.draw_little(parts[2], _little_look(parts), parts[7] == "back", parts[8], int(parts[9]))
			if parts[1] == "carry":
				return _crawler_carry(parts[2], Color(parts[3]), Color(parts[4]), Color(parts[5]))
			return _baby_cradle(parts[2], Color(parts[3]), Color(parts[4]), Color(parts[5])) if parts[1] == "cradle" 				else _baby_held(parts[2], Color(parts[3]), Color(parts[4]), Color(parts[5]))
		"scoop":    # scoop:fish:<look 0..2>, a goldfish seen from above facing right, 20 x 10 (ScoopScreen turns it to swim; GoldfishScoop looks: orange, white with red, black)
			return _scoop_fish(int(parts[2]) if parts.size() > 2 else 0)
		"mochi":    # mochi:<usu:<dough 0..3>|kine>, the mochi pounding's mortar and mallet (MochiScreen, FestivalView)
			return _usu(int(parts[2]) if parts.size() > 2 else 0) if parts[1] == "usu" else _kine()
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
	if id.begins_with(Forage.PREFIX):
		return "ui:wild:" + id.trim_prefix(Forage.PREFIX)
	if id.begins_with("kitchen:"):
		return "ui:kitchen:" + id.trim_prefix("kitchen:")
	if id in ["hoe", "can", "sickle", "hammer", "axe", "rod"]:
		return "ui:tool:" + id
	if id.begins_with("keep:"):
		return "ui:keep:" + id.trim_prefix("keep:")
	if id.begins_with("ribbon:"):
		return "ui:ribbon:%d" % Keepsakes.ribbon_place(id)
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
	if is_animal_good(id):
		return "item:" + id
	crop_look(id)   # fills _looks
	return "item:" + id if _looks.has(id) else item_key(id)


## One piece of produce in the crop's fruit colour, shaped by its look: a root with its leaf
## tuft, a long or round fruit with a calyx, a tuber, a cob in its husk, a ribbed squash.
static func _item(id: String) -> Image:
	if is_animal_good(id):
		return _animal_good(id, 12)
	var look := crop_look(id)
	var img := _blank(12, 12)
	var leaf := Color(look.get("leaf", "5f9e3a"))
	var fruit := Color(look.get("fruit", "e8a23a"))
	var dark := fruit.darkened(0.3)   # marks kept as they are: ribs, kernel rows, eyes, the root tip
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
	elif shape == "grain":   # a sheaf: straw tied at the middle, ears fanning out on top
		var straw := fruit.darkened(0.15)
		_px(img, 4, 5, 5, 6, straw)
		for x in [5, 7]:   # the stalks between, kept as marks
			_px(img, x, 5, 1, 6, dark)
		_px(img, 4, 8, 5, 1, Color("8a5a2a"))
		for p in [Vector2(3.5, 3.5), Vector2(6.5, 2.5), Vector2(9, 3.5)]:
			_oval(img, p.x, p.y, 1.6, 2.4, fruit)
	elif form == "long":
		_oval(img, 6, 6.5, 2.4, 4.6, fruit)
		_px(img, 5, 1, 3, 2, leaf)                          # calyx
	elif form == "tuber":
		_oval(img, 6, 6.5, 4.3, 3.3, fruit)
		for p in [Vector2i(4, 5), Vector2i(7, 7), Vector2i(5, 8), Vector2i(8, 5)]:
			img.set_pixelv(p, dark)
	else:
		_oval(img, 6, 7, 4.0, 3.8, fruit)
		_px(img, 4, 3, 4, 1, leaf)                          # calyx and stem
		_px(img, 6, 2, 1, 1, leaf.darkened(0.2))
	return ItemArt.refine(img, [dark])


## Egg shells per grade (data/animals.json items): plain white, a warm brown one, and the best
## with a golden blush and a sparkle.
const EGG_SHELLS := {"egg": Color("f2ecdc"), "egg_good": Color("d8b088"), "egg_best": Color("eccb7a")}


## An egg standing on its round end, `size` square (12 in the world, 14 as a slot icon).
static func _egg(id: String, size: int) -> Image:
	var img := _blank(size, size)
	var shell: Color = EGG_SHELLS.get(id, EGG_SHELLS.egg)
	var cx := size / 2.0
	_oval(img, cx, size * 0.58, size * 0.27, size * 0.36, shell)   # one material, toned by ItemArt
	_px(img, int(cx) - 2, int(size * 0.38), 1, 2, shell.lightened(0.5))
	if id == "egg_best":
		_px(img, size - 3, 1, 1, 3, SPARKLE)
		_px(img, size - 4, 2, 3, 1, SPARKLE)
	return ItemArt.refine(img, [shell.lightened(0.5), SPARKLE])


## The first, low resolution animal drawing, side view facing left: only the dog held in the
## farmer's arms (key "animal:dog:held:0", 14 x 11) still uses it; AnimalArt draws every other
## animal and pose. A red-tan shiba-like dog with a cream chest and a tail curled over its back.
const BEASTS := {
	"dog": {"w": 14, "h": 11, "body": Color("c8783c"), "head": Color("c8783c"), "muzzle": Color("f2e2c8"),
		"leg": Color("c8783c"), "hoof": Color("f2e2c8"), "b": [7.5, 5.5, 4.2, 2.3], "hd": [3.0, 3.6, 2.2],
		"legs": [4, 6, 9, 11], "leg_y": 7, "leg_len": 3, "tail": "curl", "ears": true},
}


## idle (frame 1 lifts the head a little), peck (head down: grazing, eating), walk (legs
## swing), sick (lying down, dull, eyes shut); the dog also sit (on its haunches) and held.
static func _beast(kind: String, pose: String, frame: int) -> Image:
	var s: Dictionary = BEASTS[kind]
	var img := _blank(s.w, s.h)
	var sick := pose == "sick"
	var sit := pose == "sit" or pose == "held"
	var body: Color = s.body.darkened(0.15) if sick else s.body
	var head_c: Color = s.head.darkened(0.15) if sick else s.head
	var b: Array = s.b
	var bx: float = b[0] + (1.0 if sit else 0.0)
	var by: float = b[1] + (float(s.leg_len) - 1.0 if sick else (1.0 if sit else 0.0))
	var thick := 2 if s.w > 14 else 1
	# Legs: four, swinging in pairs on a walk; folded away when lying, only the front pair sitting.
	if not sick:
		var swing := frame % 2 * 2 - 1 if pose == "walk" else 0
		for k in s.legs.size():
			if sit and k >= 2:
				continue
			var x: int = s.legs[k] + (swing if k % 3 == 0 else -swing)
			var top: int = s.leg_y - (1 if sit else 0)
			var long: int = s.leg_len + (1 if sit else 0)
			_px(img, x, top, thick, long, s.leg)
			_px(img, x, top + long - 1, thick, 1, s.hoof)
	# The tail, then the body over it.
	var tail_x := int(bx + b[2]) - 1
	_oval(img, tail_x - 0.5, by - b[3] - 0.2, 1.6, 1.5, body)   # the tail curled over its back
	_px(img, int(tail_x - 0.5), int(by - b[3]), 1, 1, s.muzzle)
	if sit:
		_oval(img, bx + 0.5, by + 0.5, b[2] * 0.8, b[3] * 1.05, body)   # haunch down, chest up
		_oval(img, bx - b[2] * 0.45, by - 0.5, b[2] * 0.45, b[3] * 1.1, body)
	else:
		_oval(img, bx, by, b[2], b[3], body)
	_oval(img, bx + 0.5, by + b[3] * 0.55, b[2] * 0.72, b[3] * 0.38, s.muzzle)
	# The head: up, a little raised, down to the grass, sunk while lying, up when sitting.
	var hd: Array = s.hd
	var head := Vector2(hd[0], hd[1])
	if pose == "peck":
		head = Vector2(hd[0] - 0.5, s.h - hd[2] - 1.0)
	elif pose == "idle" and frame % 2 == 1:
		head.y -= 1.0
	elif sick:
		head = Vector2(hd[0] + 0.5, by)
	elif sit:
		head = Vector2(hd[0] + 0.5, hd[1] - 0.5)
	var r: float = hd[2]
	var dark := Color(str(AnimalArt.art().features.nostril))   # eye and nose: no black outline colour
	_oval(img, head.x, head.y, r * 1.1, r, head_c)
	_oval(img, head.x - r * 0.75, head.y + r * 0.35, r * 0.55, r * 0.5, s.muzzle)
	var eye := Vector2i(int(head.x - r * 0.15), int(head.y - r * 0.35))
	if sick:
		_px(img, eye.x - 1, eye.y + 1, 2, 1, head_c.darkened(0.5))
	else:
		_px(img, eye.x, eye.y, 1, 1, dark)
	_px(img, int(head.x), int(head.y - r) - 1, 1, 2, head_c.darkened(0.15))   # pricked shiba ears
	_px(img, int(head.x + r * 0.7), int(head.y - r) - 1, 1, 2, head_c.darkened(0.15))
	if not sick:
		_px(img, int(head.x - r * 1.3), int(head.y + r * 0.1), 1, 1, dark)   # nose
	# Toned like the animals (AnimalArt): three tones a material, a rim in its deep tone.
	return AnimalArt.refine_flat(img, [dark, Color("e8e0d0"), head_c.darkened(0.5)])


## Animal goods as items (data/animals.json): eggs, milk, wool. Grades differ by colour.
static func is_animal_good(id: String) -> bool:
	return EGG_SHELLS.has(id) or MILK_CAPS.has(id) or WOOL_TINTS.has(id)


static func _animal_good(id: String, size: int) -> Image:
	if MILK_CAPS.has(id):
		return _milk(id, size)
	if WOOL_TINTS.has(id):
		return _wool(id, size)
	return _egg(id, size)


## Milk in a squat glass bottle with a paper cap: plain, green-banded, and a red-sealed best
## one with a sparkle.
const MILK_CAPS := {"milk": Color("e8e4dc"), "milk_good": Color("6aa05a"), "milk_best": Color("c8442c")}
const SPARKLE := Color("fff6c0")   # the best grade's star, kept as it is


static func _milk(id: String, size: int) -> Image:
	var img := _blank(size, size)
	var o := (size - 12) / 2
	_px(img, o + 3, o + 4, 6, 7, Color("f6f4ee"))       # the milk through the glass
	_px(img, o + 4, o + 2, 4, 2, Color("e6eef0"))       # neck
	_px(img, o + 4, o + 1, 4, 1, MILK_CAPS[id])         # cap
	_px(img, o + 3, o + 6, 6, 1, MILK_CAPS[id].lightened(0.2))   # label band
	_px(img, o + 4, o + 5, 1, 4, Color(1, 1, 1))        # shine on the glass, kept
	if id == "milk_best":
		_px(img, o + 10, o + 1, 1, 3, SPARKLE)
		_px(img, o + 9, o + 2, 3, 1, SPARKLE)
	return ItemArt.refine(img, [Color(1, 1, 1), SPARKLE])


## A rolled bundle of fleece: plain cream, soft white, and a cloud-white one with a sparkle.
const WOOL_TINTS := {"wool": Color("e8dcc0"), "wool_good": Color("f6f0e2"), "wool_best": Color("ffffff")}


static func _wool(id: String, size: int) -> Image:
	var img := _blank(size, size)
	var c: Color = WOOL_TINTS[id]
	var m := size / 2.0
	_oval(img, m - 1.5, m + 1, size * 0.28, size * 0.25, c.darkened(0.1))
	_oval(img, m + 1.5, m + 1.5, size * 0.28, size * 0.24, c.darkened(0.1))   # the two back puffs one material
	_oval(img, m, m - 0.5, size * 0.3, size * 0.26, c)
	for p in [Vector2i(-2, -1), Vector2i(1, 0), Vector2i(-1, 2), Vector2i(2, 2)]:
		_px(img, int(m) + p.x, int(m) + p.y, 1, 1, c.darkened(0.15))
	if id == "wool_best":
		_px(img, size - 3, 1, 1, 3, SPARKLE)
		_px(img, size - 4, 2, 3, 1, SPARKLE)
	return ItemArt.refine(img, [c.darkened(0.15), SPARKLE])

## rects = [[x, y, w, h, "rrggbb"], ...] on a transparent w x h image.
static func _draw(w: int, h: int, rects: Array) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for r in rects:
		img.fill_rect(Rect2i(r[0], r[1], r[2], r[3]), Color(r[4]))
	return img


## The farmer and villager figures are drawn by FigureArt (24 x 32, front / back, four
## directions with the mirror); these keep the older calls working.
const FIGURE_SIZE := Vector2i(FigureArt.W, FigureArt.H)
const VILLAGER_STYLES: Array[String] = ["bun", "short", "headband", "long", "straw_hat"]
const VILLAGER_OUTFITS: Array[String] = ["kimono", "happi", "shirt_shorts"]
const VILLAGER_BUILDS: Array[String] = ["adult", "elder", "child"]
const _ROD := FigureArt.ROD
const _ROD_NODE := FigureArt.ROD_NODE


static func farmer_frames(pose: String) -> int:
	return FigureArt.frames(pose)


## Where the rod tip is in a fishing frame (sprite pixels, front view facing left; the same
## from the back).
static func rod_tip(pose: String, frame: int) -> Vector2i:
	return FigureArt.rod_tip(pose, frame)


## How many pixels a frame drops the body (and what the raised hands hold) below its rest.
static func farmer_drop(pose: String, frame: int) -> int:
	return FigureArt.row(pose, frame)[0]


## The sprite row a held item's bottom rests on (the raised hands' top) on a hold frame.
static func hold_row(pose: String, frame: int) -> int:
	return FigureArt.hold_row(pose, frame)


## Where the mine lantern (mine:lantern, 7 x 11) goes on a farmer frame: its top-left pixel.
## It hangs from the near hand (screen right from the front, screen left from the back) and
## swings with it; with the arms up or both hands on the rod, at the near hip instead.
static func lantern_at(pose: String, frame: int, back := false) -> Vector2i:
	return FigureArt.lantern_at(pose, frame, back)


## The little one's look from a child:figure key: the style and colours in it, the rest the
## small indigo happi of data/child.json.
static func _little_look(parts: PackedStringArray) -> Dictionary:
	var look: Dictionary = Child.data().get("look", {}).get("clothes", {}).duplicate()
	look.merge({"outfit": "happi", "hair_style": parts[3], "skin": parts[4], "hair": parts[5], "top": parts[6]}, true)
	return look


## The top row of villager `id`'s head on their sprite (where a carried thing rests).
static func villager_top(id: String) -> int:
	return FigureArt.head_top(Villagers.look(id))


## Field objects and crops share one style with the farmer: shapes in 2-3 shades, then a
## 1 px dark outline around the whole silhouette.
const OUTLINE := Color("2a1e1e")
const _SOIL := Color("6b4a2a")
const _STAKE := Color("b08a5a")
const _DEFAULT_LOOK := {"shape": "bush", "leaf": "5f9e3a", "fruit": "e8a23a"}

static var _looks := {}


## A crop's "look" from data/crops.json: shape (root / bush / vine / stalk / ground / grain),
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


## The baby's face in a swaddle: a round face at (cx, cy), a tuft of the hair colour on top,
## eyes shut (asleep: a short dark line each) or open (dots), and the mouth open while crying.
## Flat colours; BabyArt.refine tones them.
static func _baby_face(img: Image, cx: int, cy: int, look: String, skin: Color, hair: Color, b: Dictionary) -> void:
	var cheek := Color(str(b.cheek)).lerp(skin, 0.4)
	_oval(img, cx + 0.5, cy + 0.5, 3.2, 2.8, skin)
	_px(img, cx - 1, cy - 3, 3, 1, hair)          # the tuft
	_px(img, cx, cy - 4, 1, 1, hair)
	_px(img, cx - 2, cy + 2, 1, 1, cheek)         # pink cheeks
	_px(img, cx + 3, cy + 2, 1, 1, cheek)
	var eye := Color(str(b.eye))
	if look == "asleep":
		_px(img, cx - 2, cy + 1, 2, 1, eye)
		_px(img, cx + 2, cy + 1, 2, 1, eye)
	else:
		_px(img, cx - 1, cy, 1, 1, eye)
		_px(img, cx + 2, cy, 1, 1, eye)
	if look == "cry":
		_px(img, cx, cy + 2, 2, 2, Color(str(b.mouth)))
	elif look == "awake":
		_px(img, cx + 1, cy + 2, 1, 1, skin.darkened(0.3))


## What stays as drawn in the baby pictures (eyes, cheeks, mouth, dots, the cane's weave).
static func _baby_fixed(skin: Color, b: Dictionary, weave := Color(0, 0, 0, 0)) -> Array:
	return [Color(str(b.eye)), Color(str(b.cheek)).lerp(skin, 0.4), Color(str(b.mouth)), skin.darkened(0.3),
		Color(str(b.pale)), weave]


## The bamboo cradle (a woven basket on two rockers) seen from the front and a little above,
## 20 x 16: the baby's head over the rim on a white pad, an indigo quilt (`top`) over the rest;
## awake, a small fist up by the quilt. "empty": the pad and the quilt folded back. Refined
## (BabyArt): three tones of cane, rocker, pad and quilt lit from the upper left, no black line.
static func _baby_cradle(look: String, skin: Color, hair: Color, top: Color) -> Image:
	var b := BabyArt.colours()
	var img := _blank(20, 16)
	var cane := Color(str(b.cane))
	var weave := FigureArt.tones(cane, false, FigureArt.villager_art())[3] as Color
	var rocker := Color(str(b.rocker))
	_px(img, 3, 3, 14, 3, Color(str(b.pad)))         # the pad inside, over the far rim
	if look == "empty":
		_px(img, 10, 3, 7, 2, top)                   # the quilt folded back
	else:
		_px(img, 8, 3, 10, 3, top)                   # the quilt over the little body
		_px(img, 11, 4, 1, 1, Color(str(b.pale)))    # the happi's pale dots
		_px(img, 15, 4, 1, 1, Color(str(b.pale)))
		_baby_face(img, 5, 3, look, skin, hair, b)
		if look != "asleep":                         # a small fist waving over the quilt
			_px(img, 13, 1, 2, 2, skin)
	_px(img, 1, 6, 18, 2, Color(str(b.cane_rim)))    # the rim, bound with cane
	_px(img, 2, 8, 16, 5, cane)                      # the basket's front
	for x in range(3, 18, 2):                        # the weave, in the cane's deep tone
		_px(img, x, 8, 1, 5, weave)
	_px(img, 2, 10, 16, 1, weave)
	_px(img, 4, 13, 1, 1, rocker)                    # the rockers' legs and curve
	_px(img, 15, 13, 1, 1, rocker)
	_px(img, 2, 14, 16, 1, rocker)
	_px(img, 1, 13, 1, 1, rocker)
	_px(img, 18, 13, 1, 1, rocker)
	return BabyArt.refine(img, _baby_fixed(skin, b, weave), [skin])


## The baby held up in the arms (the hold pose), 12 x 12 like a carried item: a small bundle
## lying across the hands, swaddled in the house's indigo, the face in its white wrap at one end.
static func _baby_held(look: String, skin: Color, hair: Color, top: Color) -> Image:
	var b := BabyArt.colours()
	var img := _blank(12, 12)
	_oval(img, 7.5, 8.5, 4.4, 2.8, top)              # the swaddle
	_px(img, 7, 9, 1, 1, Color(str(b.pale)))
	_px(img, 10, 9, 1, 1, Color(str(b.pale)))
	_oval(img, 3.5, 7.5, 3.4, 3.4, Color(str(b.pad)))  # the white wrap round the face
	_oval(img, 3.5, 7.5, 2.3, 2.2, skin)             # the face
	_px(img, 3, 5, 2, 1, hair)                       # the tuft
	var eye := Color(str(b.eye))
	if look == "asleep":
		_px(img, 2, 7, 1, 1, eye)
		_px(img, 4, 7, 1, 1, eye)
	else:
		_px(img, 2, 6, 1, 1, eye)
		_px(img, 4, 6, 1, 1, eye)
		_px(img, 3, 8, 1, 1, skin.darkened(0.3))
	return BabyArt.refine(img, _baby_fixed(skin, b), [skin])


## The crawler held up in the arms (the hold pose), 16 x 14, a little bigger than the swaddled
## baby: sitting up on the hands facing out, the round head with the spouse's hair (`style`: a
## bun on top for long hair), the indigo happi (`top`) with its pale sash and dots, both arms
## out to the sides and the bare feet hanging below. Refined like the figures (BabyArt).
static func _crawler_carry(style: String, skin: Color, hair: Color, top: Color) -> Image:
	var b := BabyArt.colours()
	var img := _blank(16, 14)
	var pale := Color(str(b.pale))
	_px(img, 1, 7, 3, 2, top)                        # the sleeves, arms out
	_px(img, 12, 7, 3, 2, top)
	_px(img, 0, 7, 1, 2, skin)                       # the small hands
	_px(img, 15, 7, 1, 2, skin)
	_oval(img, 8.0, 9.5, 4.4, 3.4, top)              # the happi over the round body
	_px(img, 4, 10, 8, 1, pale)                      # the sash
	_px(img, 6, 9, 1, 1, pale)                       # the happi's dots
	_px(img, 10, 9, 1, 1, pale)
	_px(img, 5, 12, 2, 2, skin)                      # the bare feet hanging below
	_px(img, 9, 12, 2, 2, skin)
	_oval(img, 8.0, 4.0, 3.6, 3.4, skin)             # the head
	_px(img, 5, 0, 6, 2, hair)                       # the hair on top
	_px(img, 4, 1, 1, 2, hair)
	_px(img, 11, 1, 1, 2, hair)
	if style == "bun":
		_px(img, 7, 0, 2, 1, hair.lightened(0.15))
	elif style == "long" or style == "headband":
		_px(img, 4, 2, 1, 3, hair)
		_px(img, 11, 2, 1, 3, hair)
	var eye := Color(str(b.eye))
	_px(img, 6, 4, 1, 1, eye)                        # eyes open, a small smile, pink cheeks
	_px(img, 9, 4, 1, 1, eye)
	_px(img, 7, 6, 2, 1, skin.darkened(0.3))
	var cheek := Color(str(b.cheek)).lerp(skin, 0.4)
	_px(img, 5, 5, 1, 1, cheek)
	_px(img, 10, 5, 1, 1, cheek)
	return BabyArt.refine(img, _baby_fixed(skin, b) + [hair.lightened(0.15)], [skin])


static func _blank(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _px(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if r.has_area():
		img.fill_rect(r, c)


## A w x h block at (x, y) that wraps past the image's edges, so a tile's features that run over
## an edge reappear on the far side and the tile repeats without a seam.
static func _wrap(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var size := img.get_size()
	for j in h:
		for i in w:
			img.set_pixel(posmod(x + i, size.x), posmod(y + j, size.y), c)


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
## pit with the top of a ladder in it. On a frozen floor a block of ice stands up (16 x 16,
## a jagged chunk with a lit top, a crack and the frost stone dark inside) and frost lies
## flat (16 x 16, a see-through sheet with rime feathers). The farmer's lantern down the mine is
## 7 x 11 (lantern_at says where it hangs on the farmer's frame).
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
		"ice":
			# A chunk of ice with a jagged top: the lit top face, a clear blue front lit from
			# the left with trapped air in it, a crack, frost round its foot, and the dark
			# splinter of the frost stone it hides frozen inside.
			var img := _blank(16, 16)
			_px(img, 2, 6, 12, 9, Color("4f86ad"))        # the body, its shaded right side
			_px(img, 3, 7, 9, 7, Color("78b4d8"))
			_px(img, 3, 7, 1, 7, Color("a8d8f0"))         # the lit left edge
			var tops := [5, 3, 4, 2, 4, 3, 1, 3, 4, 2, 4, 5]
			for i in tops.size():   # the top face, broken into points
				_px(img, 2 + i, tops[i], 1, 7 - tops[i], Color("bfe6f8"))
				_px(img, 2 + i, tops[i], 1, 1, Color("eaf8ff"))
			for p in [Vector2i(8, 8), Vector2i(8, 9), Vector2i(9, 9), Vector2i(9, 10), Vector2i(10, 10), Vector2i(9, 11)]:
				img.set_pixelv(p, Color("2e5878"))        # the frost stone inside
			img.set_pixelv(Vector2i(8, 9), Color("9ccce8"))
			for p in [Vector2i(5, 9), Vector2i(6, 12), Vector2i(11, 8)]:
				img.set_pixelv(p, Color("cdeefc"))        # air caught in the ice
			_line(img, Vector2i(12, 6), Vector2i(11, 9), Color("3e7298"))   # a crack
			_line(img, Vector2i(11, 9), Vector2i(12, 12), Color("3e7298"))
			for x in range(2, 14):   # rime round the foot
				img.set_pixel(x, 14, Color("eaf8ff") if x % 3 == 0 else Color("a8d8f0"))
			img.set_pixel(5, 3, Color.WHITE)               # a glint
			return _outline(img)
		"frost":
			# Hoarfrost on the earth: a thin see-through sheet with three feathers of rime
			# (a diagonal stem, barbs every other pixel) and loose glints between them.
			var img := _blank(16, 16)
			var sheet := Color(0.86, 0.94, 1.0, 0.22)
			_oval(img, 7, 8, 6.0, 4.5, sheet)
			_oval(img, 10.5, 9.5, 4.0, 3.5, sheet)
			var rime := Color(0.92, 0.97, 1.0, 0.75)
			var barb := Color(0.9, 0.96, 1.0, 0.45)
			for f in [[Vector2i(3, 9), Vector2i(1, -1)], [Vector2i(8, 6), Vector2i(1, 1)], [Vector2i(9, 12), Vector2i(1, -1)]]:
				var at: Vector2i = f[0]
				var d: Vector2i = f[1]
				for k in 5:   # a crooked stem with a barb either side every other pixel
					var q := at + d * k
					img.set_pixelv(q, rime if k < 4 else barb)
					if k % 2 == 1:
						img.set_pixelv(q + Vector2i(d.x, 0), barb)
						img.set_pixelv(q + Vector2i(0, d.y), barb)
				img.set_pixelv(at, Color(1, 1, 1, 0.95))
			for p in [Vector2i(2, 10), Vector2i(13, 6), Vector2i(7, 12), Vector2i(3, 4), Vector2i(14, 12)]:
				img.set_pixelv(p, Color(1, 1, 1, 0.85))
			return img
		"lantern":
			# The farmer's lantern, 7 x 11: an iron loop, a dark cap, glowing paper panes
			# between iron posts with the flame bright in the middle, a dark foot.
			var img := _blank(7, 11)
			var iron := Color("3a3430")
			_px(img, 2, 1, 3, 1, iron)                    # the loop
			_px(img, 1, 2, 1, 1, iron)
			_px(img, 5, 2, 1, 1, iron)
			_px(img, 1, 3, 5, 1, Color("5a4632"))         # the cap
			_px(img, 1, 4, 5, 5, iron)                    # the posts
			_px(img, 2, 4, 3, 5, Color("e8a040"))         # the panes
			_px(img, 2, 5, 3, 3, Color("ffd070"))
			_px(img, 3, 6, 1, 1, Color("fff4d0"))         # the flame
			_px(img, 1, 9, 5, 1, Color("5a4632"))         # the foot
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
		"landing":
			return _lift_cage()
	return _draw(16, 16, [[0, 0, 16, 16, "ff00ff"]])


## A landing's rope lift down the mine (mine:landing, 16 x 26): the rope comes down out of the
## dark above to a timber cage (two posts, a top bar with the rope's iron ring, a rail half way,
## a plank floor), a lit lantern hung on its left post so the landing shows from the ladder.
static func _lift_cage() -> Image:
	var img := _blank(16, 26)
	var timber := Color("6a4a2a")
	var timber_light := Color("8e6a3e")
	var rope := Color("c8a868")
	_px(img, 7, 0, 2, 10, rope)                  # the rope, up into the dark
	_px(img, 7, 0, 1, 10, rope.lightened(0.2))
	for y in [2, 5, 8]:                          # its twist
		_px(img, 8, y, 1, 1, rope.darkened(0.3))
	_px(img, 6, 9, 4, 2, Color("3a3430"))        # the iron ring
	_px(img, 2, 11, 12, 2, timber)               # the top bar
	_px(img, 2, 11, 12, 1, timber_light)
	_px(img, 2, 11, 2, 13, timber)               # the posts
	_px(img, 12, 11, 2, 13, timber)
	_px(img, 2, 11, 1, 13, timber_light)
	_px(img, 4, 17, 8, 1, timber_light)          # the rail
	_px(img, 1, 22, 14, 3, Color("8a6a3a"))      # the plank floor, its board ends
	_px(img, 1, 22, 14, 1, Color("b08a58"))
	for x in [4, 8, 12]:
		_px(img, x, 23, 1, 2, Color("5a3d22"))
	_px(img, 0, 13, 2, 1, Color("3a3430"))       # the lantern's hook off the left post
	_px(img, 0, 14, 3, 1, Color("3a3430"))       # its cap
	_px(img, 0, 15, 3, 3, Color("e8a040"))       # its glowing panes
	_px(img, 1, 16, 1, 1, Color("fff4d0"))       # the flame
	_px(img, 0, 18, 3, 1, Color("3a3430"))
	return _outline(img)


## A mine find as a 14 x 14 icon from its look: a rounded stone, a lump of clay, a heap of
## black sand, a lump of rock with a bright vein of ore, a cut gem, an amber drop, a crystal.
## The kitchen tools in the store and on the cooking screen, 14 x 14: knife, clay pot,
## teapot, iron rice pot, bamboo steamer, mochi mallet; outlined like the other item icons.
static func _kitchen_icon(id: String) -> Image:
	var img := _blank(14, 14)
	var steel := Color("b8c0c8")
	var wood := Color("9a6a3a")
	var clay := Color("a8583a")
	var iron := Color("4a4848")
	var bamboo := Color("c8b070")
	match id:
		"knife":
			_line(img, Vector2i(2, 11), Vector2i(5, 8), wood)   # the handle
			_line(img, Vector2i(3, 11), Vector2i(6, 8), wood)
			for i in 6:   # the blade, widest at the heel
				_px(img, 6 + i, 7 - i, 2, 2 if i < 4 else 1, steel)
			_line(img, Vector2i(7, 8), Vector2i(12, 3), steel.lightened(0.3))
		"pot":
			_oval(img, 7, 8.5, 5.5, 3.5, clay)
			_px(img, 2, 5, 10, 2, clay.darkened(0.2))   # the lid's rim
			_px(img, 6, 3, 2, 2, clay.darkened(0.3))    # its knob
			_px(img, 4, 8, 3, 1, clay.lightened(0.25))
		"teapot":
			_oval(img, 6.5, 8, 4, 3.5, Color("5a7a5a"))
			_px(img, 5, 4, 3, 1, Color("4a6a4a"))
			_line(img, Vector2i(10, 8), Vector2i(12, 6), Color("5a7a5a"))   # the spout
			_line(img, Vector2i(1, 6), Vector2i(3, 8), wood)   # the side handle
		"rice_pot":
			_px(img, 2, 6, 10, 6, iron)
			_px(img, 1, 8, 12, 1, iron.lightened(0.15))   # the flange
			_px(img, 2, 4, 10, 2, wood)   # the wooden lid
			_px(img, 6, 3, 2, 1, wood.darkened(0.25))
		"steamer":
			_px(img, 2, 4, 10, 4, bamboo)
			_px(img, 2, 8, 10, 4, bamboo.darkened(0.12))
			_px(img, 2, 7, 10, 1, bamboo.darkened(0.35))   # the two baskets' seam
			_px(img, 3, 3, 8, 1, bamboo.lightened(0.2))
		"mallet":
			_px(img, 7, 2, 2, 7, wood)   # the handle
			_px(img, 3, 1, 6, 3, wood.darkened(0.15))   # the head
			_px(img, 2, 9, 10, 4, wood.darkened(0.3))   # the mortar
			_px(img, 3, 9, 8, 1, Color("f0ece0"))   # the rice in it
		_:
			_oval(img, 7, 7, 5, 5, steel)
	return _outline(img)


## A wild thing (data/forage.json look): a bamboo shoot in its husk, a curled bracken frond, a
## round bud in its scales, a cluster of berries on a leaf, a chestnut burr split open, an
## akebi pod open on its pulp, or a mushroom (cap colour, stem accent).
static func _wild_icon(look: Dictionary) -> Image:
	var img := _blank(14, 14)
	var c := Color(look.get("color", "8a6a3a"))
	var a := Color(look.get("accent", "f0e2b0"))
	# Flat materials (the colour, the accent), then ItemArt.refine; the small marks stay as laid.
	var marks := []
	match look.get("shape", ""):
		"shoot":
			for y in 10:
				var half := (y + 2) / 3 + 1
				_px(img, 7 - half, y + 2, half * 2, 1, c)
			_px(img, 6, 1, 2, 2, c)
			_px(img, 5, 10, 4, 2, a)
		"fern":
			_line(img, Vector2i(7, 13), Vector2i(7, 5), c)
			_oval(img, 7, 4, 2.5, 2.5, c)
			_line(img, Vector2i(3, 9), Vector2i(11, 7), c)
			_px(img, 6, 12, 3, 2, a)
			marks = [c.darkened(0.3)]
			img.set_pixel(8, 4, marks[0])   # the curl's eye
		"bud":
			_oval(img, 7, 8, 4.0, 4.5, c)
			_oval(img, 7, 6, 2.0, 2.5, a)
			_line(img, Vector2i(4, 9), Vector2i(7, 12), c)
			_line(img, Vector2i(10, 9), Vector2i(7, 12), c)
		"berries":
			_oval(img, 7, 10, 5.0, 2.5, a)
			marks = [c.lightened(0.4)]
			for p in [[5, 6], [8.5, 6], [6.5, 8.5], [9.5, 9], [4.5, 9]]:
				_oval(img, p[0], p[1], 1.8, 1.8, c)
				img.set_pixel(int(p[0]) - 1, int(p[1]) - 1, marks[0])
		"nut":
			_oval(img, 7, 8, 5.5, 4.5, a)
			for x in [2, 5, 9, 12]:
				_px(img, x, 3 + x % 3, 1, 1, a)
			_oval(img, 5.5, 8.5, 2.2, 2.5, c)
			_oval(img, 8.5, 8.5, 2.2, 2.5, c)
			marks = [c.lightened(0.4)]
			_px(img, 5, 7, 1, 1, marks[0])
		"pod":
			_oval(img, 7, 7, 3.5, 5.5, c)
			_oval(img, 7, 7, 1.5, 4.0, a)
			_px(img, 7, 1, 1, 2, Color("6a4a2a"))
			marks = [Color("1e1e1e")]
			_px(img, 6, 6, 1, 1, marks[0])
			_px(img, 8, 9, 1, 1, marks[0])
		"mushroom":
			_px(img, 6, 7, 3, 6, a)
			_oval(img, 7, 6, 5.5, 3.0, c)
			marks = [c.lightened(0.35)]
			_px(img, 5, 4, 2, 1, marks[0])
	return ItemArt.refine(img, marks)


static func _mine_icon(look: Dictionary) -> Image:
	var img := _blank(14, 14)
	var body := Color(look.get("body", "8e8a84"))
	var shine := Color(look.get("shine", body.lightened(0.4).to_html()))
	var marks := [shine]   # small glints stay as laid; the larger faces below are materials
	match look.get("shape", "stone"):
		"stone":
			_oval(img, 7, 8, 5.5, 4.2, body)
			_px(img, 4, 6, 3, 1, shine)
		"lump":
			_oval(img, 7, 8.5, 5.0, 3.8, body)
			_px(img, 4, 6, 2, 1, shine)
			marks.append(body.darkened(0.25))
			_line(img, Vector2i(5, 10), Vector2i(9, 9), marks[1])   # a thumb mark
		"sand":
			for y in range(5, 12):
				var half := (y - 4) + 1
				_px(img, 7 - half, y, half * 2, 1, body)
			for p in [Vector2i(6, 6), Vector2i(4, 9), Vector2i(8, 8), Vector2i(10, 10), Vector2i(7, 10)]:
				img.set_pixelv(p, shine)
		"ore":
			var vein := Color(look.get("vein", "c8643a"))
			_oval(img, 7, 8, 5.8, 4.5, body)
			_line(img, Vector2i(3, 9), Vector2i(10, 5), vein)
			_line(img, Vector2i(6, 11), Vector2i(10, 9), vein)
			marks.append(vein.lightened(0.4))
			img.set_pixel(8, 6, marks[1])
		"gem":
			for y in 4:   # the crown (its own facet colour) widening, then the point
				_px(img, 4 - y, 3 + y, 6 + y * 2, 1, body.lightened(0.15))
			for y in 5:
				_px(img, 1 + y, 7 + y, 12 - y * 2, 1, body)
			_px(img, 4, 4, 2, 1, shine)
		"drop":
			_oval(img, 7, 8.5, 4.2, 4.0, body)
			for y in 3:
				_px(img, 6 - y / 2, 3 + y, 2 + y, 1, body)
			_px(img, 5, 7, 2, 2, shine)
			marks.append(body.darkened(0.25))
			img.set_pixel(8, 10, marks[1])   # something old caught inside
		"crystal":
			marks = []
			for i in 3:   # three points from a cluster, each with a lit facet down its left edge
				var x := 3 + i * 3
				var tall := 8 - absi(i - 1) * 2
				_px(img, x, 12 - tall, 3, tall, body)
				_px(img, x + 1, 11 - tall, 1, 1, body)
				_px(img, x, 12 - tall, 1, tall, shine)
			_px(img, 2, 11, 10, 2, Color("6a625a"))   # the rock it grows from
		"shard":
			# Two splinters of ice rising apart from a frosted rock, each split down the middle
			# into a lit facet and a body one, a glint near each tip.
			var facet := body.lerp(shine, 0.5)
			for sp in [[5, 1, 2], [10, 5, 2]]:   # tip x, tip y, half width at the widest
				for y in range(sp[1], 11):
					var half := mini((y - sp[1]) / 2 + 1, sp[2])
					_px(img, sp[0] - half, y, half, 1, facet)
					_px(img, sp[0], y, half, 1, body)
				img.set_pixel(sp[0] - 1, sp[1] + 2, shine)
			img.set_pixel(4, 1, shine)
			_px(img, 2, 11, 10, 2, Color("6a625a"))   # the rock they grow from
			marks.append(Color("dcecf4"))
			for x in [3, 6, 9, 11]:
				img.set_pixel(x, 11, marks[1])   # frost on it
	return ItemArt.refine(img, marks)


## Seed and sprout look the same for every crop (in its leaf colour); from growth 2 the shape
## from the crop's look takes over. Vines and stalks are 16 x 24, the rest 16 x 16.
static func _crop(id: String, growth: int, ripe: bool) -> Image:
	var look := crop_look(id)
	var shape: String = look.get("shape", "bush")
	# The single-sprite crops (and every crop's seed and sprout) are drawn by CropArt; only the tall
	# crops' grown look stays below (the 3D and flat views stand those as `stalk:` clusters).
	if growth < 2 or CropArt.draws_grown(shape):
		return CropArt.draw(id, growth, ripe)
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
		"grain":   # a clump of upright blades; ripe, the stems go straw and the ears bow over
			var hs := [8, 11, 13, 10, 7] if big else [4, 6, 7, 5, 3]
			var stem := leaf.lerp(fruit.darkened(0.2), 0.55) if ripe else leaf
			for i in 5:
				_px(img, 4 + i * 2, g - hs[i], 1, hs[i] + 1, stem if i % 2 == 0 else stem.darkened(0.2))
			_px(img, 8, g - hs[2] + 1, 1, 3, stem.lightened(0.25))
			if ripe:
				for i in 5:
					var x := 4 + i * 2
					var top: int = g - hs[i]
					var side := -1 if i < 2 else 1
					_px(img, x, top, 1, 2, fruit)
					_px(img, x + side, top + 1, 1, 3, fruit)
					_px(img, x + side, top + 3, 1, 1, fruit.darkened(0.2))
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


## One plant of a tall crop's cluster (CropClusters stands several on a cell in the 3D view):
## a vine crop (cucumber, tomato) as one stake with the vine's leaves up it and the fruit hanging
## when ripe; a grain crop (rice) as one hill of thin blades, ripe with straw stems and gold ears bowing
## over; a stalk crop (corn) as one stalk with its leaves, the tassel when grown, the cob
## when ripe. `variant` (0..2) leans the blades or sets the leaves another way, so a field of
## them doesn't repeat. The rim is a deep shade of the leaf, not the black outline: a cell
## holds many small plants, and black round each blade turned the field to noise.
static func _stalk(id: String, growth: int, ripe: bool, variant: int) -> Image:
	var look := crop_look(id)
	var leaf := Color(look.get("leaf", "5f9e3a"))
	var dark := leaf.darkened(0.25)
	var light := leaf.lightened(0.25)
	var fruit := Color(look.get("fruit", "e8a23a"))
	var big := growth >= 3
	var img: Image
	if look.get("shape", "") == "stalk":
		img = _blank(11, 24 if big else 15)
		var g := img.get_height() - 2
		var h := 19 if big else 10
		_px(img, 5, g - h, 1, h + 1, leaf)
		_px(img, 6, g - h + 2, 1, h - 1, dark)
		var side := 1 if variant % 2 == 0 else -1
		for y in range(g - 2 - variant, g - h + 2, -4):
			var tip := Vector2i(5 + side * 5, y - 3)
			_line(img, Vector2i(5 + side, y), tip, leaf if side < 0 else dark)
			_px(img, tip.x, tip.y + 1, 1, 1, light if side < 0 else leaf)   # the end hangs over
			side = -side
		if big:
			var tassel := Color("d9c27a")
			_px(img, 5, g - h - 2, 1, 2, tassel)
			_px(img, 4, g - h - 1, 1, 1, tassel)
			_px(img, 6, g - h - 1, 1, 1, tassel.darkened(0.15))
		if ripe:
			var x := 7 if variant != 1 else 2
			_oval(img, x + 1, g - 10, 1.4, 3.2, fruit)
			_px(img, x + 1, g - 12, 1, 3, fruit.lightened(0.3))
			_px(img, x, g - 7, 3, 2, leaf)   # the husk
	elif look.get("shape", "") == "vine":   # a stake with the vine climbing it
		img = _blank(13, 23 if big else 14)
		var g := img.get_height() - 2
		var top := g - (18 if big else 9)
		_px(img, 6, top - 1, 1, g - top + 2, _STAKE)
		_px(img, 7, top, 1, g - top + 1, _STAKE.darkened(0.25))
		# A ripe vine's fruit hangs at these places; no leaf is drawn beside it, so it shows.
		var hang: Array = []
		if ripe:
			hang = [Vector2(3.0, g - 6 - variant), Vector2(10.0, g - 10), Vector2(3.5, g - 14 + variant)] if big \
				else [Vector2(3.0, g - 4), Vector2(10.0, g - 6)]
		var side := 1 if variant % 2 == 0 else -1
		for y in range(g - 1 - variant, top + 1, -3):
			if not (ripe and _hangs_by(hang, side, y)):
				_oval(img, 6.5 + side * 3.0, y, 2.6, 1.8, leaf if side < 0 else dark)
				_px(img, 6 + (1 if side > 0 else 0), y, 1, 1, dark)   # the leaf stalk to the stake
			side = -side
		_px(img, 6, top - 1, 2, 2, light)   # the growing tip
		if ripe:
			# A long fruit (cucumber) ripens to its own pale yellow-green, lit on the left and dark
			# along the right edge, so it stands off the dark leaves; round fruit keep the colour.
			var pale := Color(look["ripe_fruit"]) if look.has("ripe_fruit") else fruit
			for p in hang:
				if look.get("fruit_shape", "") == "long":
					_px(img, int(p.x), int(p.y) - 2, 1, 5, pale)
					_px(img, int(p.x), int(p.y) - 2, 1, 1, pale.lightened(0.45))
					_px(img, int(p.x) + 1, int(p.y) - 2, 1, 5, pale.darkened(0.4))
				else:
					_oval(img, p.x, p.y, 1.9, 1.9, fruit)
					_px(img, int(p.x) - 1, int(p.y) - 1, 1, 1, fruit.lightened(0.4))
	else:   # grain: one hill of rice
		img = _blank(9, 16 if big else 11)
		var g := img.get_height() - 2
		var hs := [9, 12, 14, 11, 8] if big else [5, 7, 8, 6, 4]
		var leans: Array = [[-3, -2, 0, 1, 3], [-2, -1, 1, 2, 3], [-3, -1, 0, 2, 2]][variant % 3]
		var stem := leaf.lerp(fruit.darkened(0.2), 0.55) if ripe else leaf
		for i in 5:
			var foot := Vector2i(3 + i / 2, g)
			var top := Vector2i(4 + leans[i], g - hs[i])
			_line(img, foot, top, stem if i % 2 == 0 else stem.darkened(0.2))
		_line(img, Vector2i(4, g - 1), Vector2i(4 + leans[2], g - hs[2] + 2), stem.lightened(0.2))
		if ripe:
			for i in 5:
				var top := Vector2i(4 + leans[i], g - hs[i])
				var side := -1 if leans[i] < 0 else 1
				_px(img, top.x, top.y, 1, 2, fruit)
				_px(img, top.x + side, top.y + 1, 1, 3, fruit)
				_px(img, top.x + side, top.y + 3, 1, 1, fruit.darkened(0.2))
	return _rim(img, leaf.darkened(0.6))


## True when a ripe vine's fruit (`hang`, the spots of _stalk) hangs on `side` (-1 left, 1 right)
## at height `y`: the leaf there is left off. A leaf is 1.8 up and down and the fruit 2 either way,
## so a leaf one step (3) past the fruit still touches it: the window is 6.5 (two steps).
static func _hangs_by(hang: Array, side: int, y: int) -> bool:
	for p: Vector2 in hang:
		if (p.x < 6.5) == (side < 0) and absf(p.y - y) < 6.5:
			return true
	return false


## Like `_outline`, in a colour of its own.
static func _rim(img: Image, c: Color) -> Image:
	var src := img.duplicate() as Image
	var size := img.get_size()
	for y in size.y:
		for x in size.x:
			if src.get_pixel(x, y).a > 0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < size.x and q.y < size.y and src.get_pixelv(q).a > 0:
					img.set_pixel(x, y, c)
					break
	return img


## One hill of cut rice stubble (CropClusters, the paddies in winter): four short straw stalks, a
## pixel apart and cut off at different heights, a lighter cut end on each. No rim: a dark rim
## filled the gaps between the stalks and made them read as lumps. `variant` (0..2) leans them
## another way, as for the rice.
const _STRAW := Color("b89a5a")

static func _stubble(variant: int) -> Image:
	var img := _blank(9, 6)
	var g := img.get_height() - 1
	var hs := [4, 3, 5, 3]
	var leans: Array = [[0, 1, 0, -1], [1, 0, 0, -1], [0, -1, 0, 1]][variant % 3]
	for i in 4:
		var foot := Vector2i(1 + 2 * i, g)
		var top := Vector2i(foot.x + leans[i], g - hs[i])
		_line(img, foot, top, _STRAW if i % 2 == 0 else _STRAW.darkened(0.2))
		_px(img, top.x, top.y, 1, 1, _STRAW.lightened(0.35))   # the cut end
	return img


## One length of indigo cloth hung over a drying pole (Shino's rack, DyeCloth): the fold over
## the pole a little lighter where the sun catches it, soft vertical folds down the drop, the hem
## a shade darker and slightly uneven, a few paler streaks where the dye took less.
static func _dye_cloth(c: Color) -> Image:
	var w := DyeCloth.ART_W
	var h := DyeCloth.ART_H
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(c.to_html(false))
	var hem := []
	for x in w:
		hem.append(h - 1 - (1 if (x * 7 + rng.randi_range(0, 3)) % 5 == 0 else 0))
	for x in w:
		var fold := 0.5 + 0.5 * sin(float(x) * 0.95 + 0.6)   # soft folds across the width
		for y in hem[x] + 1:
			var k := 1.0 + 0.12 * (fold - 0.5)
			if y <= 1:
				k = 1.22   # the fold over the pole, catching the light
			elif y == 2:
				k = 0.8    # its shadow under the pole
			if y >= hem[x] - 1:
				k *= 0.82   # the hem
			var px := Color(c.r * k, c.g * k, c.b * k)
			if x == 0 or x == w - 1:
				px = px.darkened(0.15)   # the selvedges
			img.set_pixel(x, y, px)
	for i in 3:   # streaks where the dye took less
		var sx := rng.randi_range(2, w - 3)
		for y in range(rng.randi_range(4, 8), rng.randi_range(12, h - 3)):
			img.set_pixel(sx, y, img.get_pixel(sx, y).lightened(0.12))
	return img


## A door curtain Shino dyed (StoryView "noren", 22 x 10): indigo cloth hanging in three
## panels with dark slits between, a paler band where it folds over the rod and a deeper hem.
## The mark, resisted white: `rows` the farmer's field (furrows of little sprouts across the
## panels), `flowers` her wildflowers (five-petal blossoms scattered, one with a pale centre),
## `shino` her own dye house's mark (a ring round an indigo leaf, on the middle panel).
static func _noren_story(style: String) -> Image:
	var img := _blank(22, 10)
	var cloth := Color("23356a") if style != "shino" else Color("1c2c5c")
	var white := Color("eeeae0")
	img.fill(cloth)
	_px(img, 0, 0, 22, 1, cloth.lightened(0.25))   # over the rod
	_px(img, 0, 9, 22, 1, cloth.darkened(0.3))     # the hem
	for x in [7, 14]:
		_px(img, x, 3, 1, 7, Color(0, 0, 0, 0))   # the slits between the panels
	match style:
		"rows":
			for y in [3, 6]:
				_px(img, 1, y + 1, 20, 1, cloth.lightened(0.12))   # the furrow
				for x in range(2, 21, 3):
					if x == 7 or x == 14:
						continue
					_px(img, x, y, 1, 1, white)   # a sprout on the ridge
					_px(img, x - 1, y - 1, 1, 1, white)
					_px(img, x + 1, y - 1, 1, 1, white)
		"flowers":
			for at in [Vector2i(3, 3), Vector2i(10, 6), Vector2i(17, 3), Vector2i(4, 7), Vector2i(18, 7)]:
				_px(img, at.x, at.y - 1, 1, 1, white)
				_px(img, at.x - 1, at.y, 3, 1, white)
				_px(img, at.x, at.y + 1, 1, 1, white)
				_px(img, at.x, at.y, 1, 1, Color("e8c860") if at == Vector2i(10, 6) else cloth.lightened(0.3))
		_:   # her own mark: a ring round an indigo leaf
			for p in [Vector2i(10, 3), Vector2i(11, 3), Vector2i(9, 4), Vector2i(12, 4), Vector2i(9, 5), Vector2i(12, 5), Vector2i(9, 6), Vector2i(12, 6), Vector2i(10, 7), Vector2i(11, 7)]:
				_px(img, p.x, p.y, 1, 1, white)
			_px(img, 10, 4, 2, 2, white)   # the leaf
			_px(img, 11, 6, 1, 1, white)   # its stem
	return img


## Kiku's persimmon, planted (StoryView "scion", story:scion:<stage>:<season>:<snow 0|1>; the
## stages and sizes in data/scion.json, Scion). sapling (16 x 26): the twig beside a little
## bamboo stake, tied to it with straw. young (22 x 34): the stake gone, a thin trunk with a few
## branches and a small round crown. tree (26 x 42): a stouter trunk, a wide crown, persimmons
## in fall (fruit: data/scion.json) and in winter the one left on a bare branch for the birds.
## By season: spring pale new leaves, summer full green (small green fruit on the tree), fall
## orange and red leaves, winter bare with a straw wrap round the foot; snow on the upper side
## of the bare branches when the farm lies under snow.
static func _scion_story(stage: String, season: String, snow: bool, shown: int = -1) -> Image:
	var img: Image
	match stage:
		"young":
			img = _scion_young(season)
		"tree":
			img = _scion_tree(season, shown)
		_:
			img = _scion_sapling(season)
	if snow and season == "winter":   # snow on the upper side of every branch pixel above the wrap
		var size := img.get_size()
		var top := size.y - (9 if stage == "sapling" else 12)
		var src := img.duplicate() as Image
		for y in range(1, top):
			for x in size.x:
				if src.get_pixel(x, y).a > 0.5 and src.get_pixel(x, y - 1).a < 0.5:
					img.set_pixel(x, y - 1, Color("f4f8fc"))
	return _outline(img)


const SCION_LEAVES := {"spring": [Color("a8d870"), Color("d8e890")], "summer": [Color("4c9438"), Color("68b04a")],
	"fall": [Color("d8741e"), Color("e8a038")]}
const PERSIMMON := Color("e86a14")


static func _scion_sapling(season: String) -> Image:
	var img := _blank(16, 26)
	var bark := Color("6a5238") if season != "winter" else Color("56402c")
	var straw := Color("d8b866")
	var stake := Color("b09a5a")
	_px(img, 11, 9, 1, 17, stake)                       # the stake
	_px(img, 11, 8, 1, 1, stake.lightened(0.25))
	_px(img, 7, 14, 2, 12, bark)                        # the trunk, a thin young one
	_px(img, 8, 10, 1, 4, bark)
	_px(img, 9, 8, 1, 3, bark)
	_px(img, 5, 12, 2, 1, bark)                         # two side twigs
	_px(img, 9, 15, 2, 1, bark)
	if season == "winter":
		_px(img, 5, 12, 1, 1, bark.darkened(0.2))
		_scion_wrap(img, 8, 17, 25, straw)
		_px(img, 6, 16, 4, 1, straw.lightened(0.1))     # the tuft on top
	else:
		_px(img, 7, 20, 5, 1, straw)                    # the straw tie round trunk and stake
		_px(img, 7, 21, 5, 1, straw.darkened(0.18))
		_px(img, 10, 22, 1, 1, straw)                   # its loose end
		var leaf: Color = SCION_LEAVES[season][0]
		var leaf2: Color = SCION_LEAVES[season][1]
		var spots := [[4, 10], [9, 6], [6, 7], [10, 12], [3, 13], [11, 9]]
		for i in spots.size():
			var at: Array = spots[i]
			if season == "spring":   # small, bud-like
				_px(img, at[0], at[1], 2, 2, leaf)
				_px(img, at[0], at[1], 1, 1, leaf2)
			else:
				_px(img, at[0], at[1], 3, 2, leaf)
				_px(img, at[0] + 1, at[1] - 1, 2, 1, leaf2)
				_px(img, at[0], at[1] + 2, 2, 1, leaf.darkened(0.2))
		if season == "fall":                            # one small persimmon on the low twig
			_persimmon(img, 9, 16, 3)
	return img


## The straw wrap round a trunk's foot against the frost, from row y0 to y1 about x (wider down).
static func _scion_wrap(img: Image, x: int, y0: int, y1: int, straw: Color) -> void:
	for y in range(y0, y1):
		var w := 4 + (y - y0) / 3
		_px(img, x - w / 2, y, w, 1, straw if y % 2 == 0 else straw.darkened(0.12))
	_px(img, x - 3, y0 + 2, 7, 1, straw.darkened(0.35))   # its binding


## A persimmon: a round orange fruit of `d` px with a green calyx on top and a light spot.
static func _persimmon(img: Image, x: int, y: int, d: int) -> void:
	_px(img, x, y, d, d, PERSIMMON)
	if d >= 3:   # shaded underside
		_px(img, x + 1, y + d - 1, d - 1, 1, PERSIMMON.darkened(0.2))
	_px(img, x + d / 2, y - 1, 1, 1, Color("5c8a34"))
	_px(img, x, y, 1, 1, Color("f4a050"))


## Leaf lumps for a crown: [cx, cy, rx, ry, shade] ovals in the season's two greens (or fall's
## oranges, every third one redder).
static func _scion_crown(img: Image, season: String, lumps: Array) -> void:
	var leaf: Color = SCION_LEAVES[season][0]
	var leaf2: Color = SCION_LEAVES[season][1]
	for i in lumps.size():
		var l: Array = lumps[i]
		var c := leaf.darkened(float(l[4]))
		if season == "fall" and i % 3 == 1:
			c = Color("c4421e").darkened(float(l[4]) * 0.5)
		_oval(img, l[0], l[1], l[2], l[3], c)
	for i in lumps.size():   # a light fleck on the upper side of each lump
		var l: Array = lumps[i]
		_px(img, int(l[0] - l[2] * 0.4), int(l[1] - l[3] * 0.6), 2, 1, leaf2 if season != "fall" or i % 3 != 1 else Color("e86a2a"))


static func _scion_young(season: String) -> Image:
	var img := _blank(22, 34)
	var bark := Color("6a5238") if season != "winter" else Color("56402c")
	_px(img, 10, 17, 2, 17, bark)                       # the trunk
	for seg in [[Vector2i(11, 18), Vector2i(5, 11)], [Vector2i(11, 17), Vector2i(17, 10)], [Vector2i(10, 17), Vector2i(10, 4)],
			[Vector2i(10, 9), Vector2i(7, 5)], [Vector2i(11, 12), Vector2i(14, 6)], [Vector2i(6, 12), Vector2i(3, 9)],
			[Vector2i(16, 11), Vector2i(19, 8)]]:
		_line(img, seg[0], seg[1], bark)
	if season == "winter":
		_scion_wrap(img, 11, 25, 33, Color("d8b866"))
		return img
	_scion_crown(img, season, [
		[5.5, 10.0, 3.6, 3.0, 0.14], [16.5, 9.5, 3.6, 3.0, 0.08], [8.0, 6.0, 3.6, 3.2, 0.04],
		[14.0, 5.5, 3.4, 3.0, 0.1], [11.0, 9.5, 4.0, 3.4, 0.0], [11.0, 3.2, 2.8, 2.4, 0.06],
		[8.5, 13.0, 3.0, 2.4, 0.16], [14.5, 13.0, 3.0, 2.4, 0.12],
	] if season != "spring" else [   # spring: the leaves just out, smaller lumps with the branches between
		[5.0, 10.5, 2.4, 2.0, 0.1], [17.0, 9.5, 2.4, 2.0, 0.04], [7.5, 5.5, 2.4, 2.0, 0.0],
		[14.0, 5.5, 2.4, 2.0, 0.08], [10.5, 3.5, 2.2, 1.8, 0.0], [12.0, 10.0, 2.4, 2.0, 0.12],
	])
	return img


static func _scion_tree(season: String, shown: int = -1) -> Image:
	var img := _blank(26, 42)
	var bark := Color("5e4632") if season != "winter" else Color("4e3a28")
	_px(img, 12, 20, 3, 22, bark)                       # the trunk, stouter now
	_px(img, 11, 39, 5, 3, bark)                        # its foot spreading
	_px(img, 12, 24, 1, 6, bark.lightened(0.15))        # the light side of the bark
	for seg in [[Vector2i(13, 22), Vector2i(5, 13)], [Vector2i(13, 21), Vector2i(21, 12)], [Vector2i(13, 21), Vector2i(13, 4)],
			[Vector2i(13, 10), Vector2i(8, 4)], [Vector2i(13, 13), Vector2i(18, 5)], [Vector2i(6, 14), Vector2i(2, 10)],
			[Vector2i(20, 13), Vector2i(24, 9)], [Vector2i(9, 18), Vector2i(4, 18)], [Vector2i(17, 18), Vector2i(22, 18)]]:
		_line(img, seg[0], seg[1], bark)
		if Vector2(seg[0]).distance_to(Vector2(seg[1])) > 9.0:   # the long limbs two px thick
			_line(img, seg[0] + Vector2i(1, 0), seg[1] + Vector2i(1, 0), bark)
	if season == "winter":
		_scion_wrap(img, 13, 31, 39, Color("d8b866"))
		_persimmon(img, 21, 13, 3)                      # the one left for the birds
		return img
	if season == "spring":
		_scion_crown(img, season, [
			[5.0, 12.5, 3.0, 2.4, 0.1], [21.0, 11.5, 3.0, 2.4, 0.04], [9.0, 5.5, 3.0, 2.4, 0.0],
			[17.5, 6.0, 3.0, 2.4, 0.08], [13.0, 4.0, 2.8, 2.2, 0.0], [13.5, 12.0, 3.2, 2.6, 0.12],
			[4.5, 17.5, 2.6, 2.0, 0.14], [21.5, 17.5, 2.6, 2.0, 0.1],
		])
		return img
	_scion_crown(img, season, [
		[5.5, 13.0, 4.6, 3.6, 0.14], [20.5, 12.5, 4.6, 3.6, 0.08], [9.0, 7.0, 4.6, 3.8, 0.04],
		[17.5, 7.0, 4.4, 3.6, 0.1], [13.0, 11.0, 5.2, 4.2, 0.0], [13.0, 3.6, 3.6, 3.0, 0.06],
		[8.5, 17.0, 4.0, 3.0, 0.16], [17.5, 17.0, 4.0, 3.0, 0.12], [3.5, 17.5, 2.6, 2.2, 0.18],
		[22.5, 17.5, 2.6, 2.2, 0.16],
	])
	if season == "fall":   # the persimmons hanging under the leaves
		var hanging := [[4, 17], [9, 12], [16, 14], [20, 18], [12, 18], [18, 8], [7, 7], [22, 11]]
		for i in hanging.size():
			if shown < 0 or i < shown:   # `shown`: what is left after picking (Scion.drawn_left)
				_persimmon(img, hanging[i][0], hanging[i][1], 3)
	elif season == "summer":   # small green fruit setting
		for at in [[6, 16], [16, 15], [11, 19], [20, 10]]:
			_px(img, at[0], at[1], 2, 2, Color("8cb848"))
			_px(img, at[0], at[1], 1, 1, Color("b4d468"))
	return img


## A still puddle between the winter paddy rows: dull grey-blue water with a paler strip where the
## grey sky shows on it, an oval about 12 x 5 px (CropClusters.plant_water, data/paddy.json).
static func _paddy_water() -> Image:
	var img := _blank(12, 5)
	_oval(img, 6, 2.5, 6, 2.5, Color("5d7680"))
	_oval(img, 6.5, 2, 3.5, 1, Color("7d939b"))
	_px(img, 4, 2, 2, 1, Color("9aaeb4"))
	return img


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
			# Rice straw spread on the coop's and barn's earth floor: a worn mat of dull gold
			# stalks lying every way, close in tone to the earth so it reads as bedding (bright
			# lone stalks looked like yellow lumps on the floor).
			img.fill(Color("8e7c5c"))
			for i in 30:
				var x := rng.randi_range(0, 13)
				var y := rng.randi_range(0, 15)
				var c: Color = [Color("a8925e"), Color("b8a06a"), Color("9a8656")][i % 3]
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
		"paddy":
			# A flooded rice paddy: still water catching the sky over mud, rows of rice tufts.
			img.fill(Color("6a94a0"))
			for i in 3:
				_px(img, rng.randi_range(0, 11), rng.randi_range(1, 14), rng.randi_range(3, 5), 1, Color("8cb4bc"))
			for row in 4:
				for col in 4:
					var x := col * 4 + 1 + (row + n) % 2
					var y := row * 4 + 1
					_px(img, x, y + 1, 1, 2, Color("4e7e34"))
					_px(img, x + 1, y, 1, 3, Color("62983e"))
					_px(img, x + 1, y, 1, 1, Color("94c464"))
					_px(img, x, y + 3, 2, 1, Color("587e88"))   # the tuft's shadow on the water
		"paddy_flood":
			# The flat view's paddy ground where rice is drawn over it (CropPatches.paddy_ground):
			# the same still water as "paddy" but no painted tufts, the plants are drawn on top.
			# Two faint strips of sky on the water and a few dark specks keep it from looking flat.
			# Every feature wraps past the tile's edges (_wrap), so the tile repeats without a seam.
			img.fill(Color("6a94a0"))
			for i in 2:   # a soft sky reflection: a pale band, its middle lighter than its ends
				var x := rng.randi_range(0, 15)
				var y := rng.randi_range(1, 14)
				var w := rng.randi_range(5, 8)
				_wrap(img, x, y, w, 1, Color("7fa8b2"))
				_wrap(img, x + 1, y, w - 2, 1, Color("8fb6be"))
			for i in 3:   # small ripple lines: a pale stroke with a dark one under it
				var x := rng.randi_range(0, 15)
				var y := rng.randi_range(0, 15)
				var w := rng.randi_range(2, 4)
				_wrap(img, x, y, w, 1, Color("8fb6be"))
				_wrap(img, x + 1, y + 1, w - 1, 1, Color("5e8a94"))
			for i in 3:
				_wrap(img, rng.randi_range(0, 15), rng.randi_range(0, 15), 1, 1, Color("5e8a94"))
		"paddy_mud":
			# The flat view's paddy ground in winter, drained after the harvest: dark mud with grain,
			# a wet sheen in pale streaks, a few puddles (dark blue-grey, a light glint on each) and
			# straw bits from the cut stubble, so the stubble and the water patches read against it.
			# Every feature wraps past the tile's edges (_wrap), so the tile repeats without a seam.
			img.fill(Color("6e604c"))
			for i in 12:
				_wrap(img, rng.randi_range(0, 15), rng.randi_range(0, 15), 1, 1, Color("5a4e40") if i % 2 == 0 else Color("7a6a55"))
			for i in 4:   # wet sheen: a short pale streak with a dark line under it
				var x := rng.randi_range(0, 15)
				var y := rng.randi_range(0, 15)
				var w := rng.randi_range(2, 4)
				_wrap(img, x, y, w, 1, Color("86806c"))
				_wrap(img, x + 1, y + 1, w - 1, 1, Color("5a4e40"))
			for i in 2:   # puddles: a rounded blue-grey pool, darker along its lower edge
				var x := rng.randi_range(0, 11)
				var y := rng.randi_range(1, 12)
				_wrap(img, x + 1, y, 3, 1, Color("56666c"))
				_wrap(img, x, y + 1, 5, 2, Color("56666c"))
				_wrap(img, x + 1, y + 3, 3, 1, Color("4a5a5e"))
				_wrap(img, x + 1, y + 1, 2, 1, Color("8aa0a6"))
			for i in 4:   # straw bits: short dull gold strokes, lying every way
				var x := rng.randi_range(0, 15)
				var y := rng.randi_range(0, 15)
				var c := Color("9c8752") if i % 2 == 0 else Color("7a6840")
				if i % 2 == 0:
					_wrap(img, x, y, 2, 1, c)
				else:
					_wrap(img, x, y, 1, 2, c)
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
		"tsuchi":
			# Earthen wall plaster (tsuchikabe), warm ochre, with darker straw flecks and a few
			# pale trowel strokes.
			var img := _blank(16, 16)
			img.fill(Color("c8a878"))
			for i in 10:
				_px(img, rng.randi_range(0, 14), rng.randi_range(0, 15), rng.randi_range(1, 2), 1, Color("a88a5c"))
			for i in 6:
				_px(img, rng.randi_range(0, 13), rng.randi_range(0, 15), 3, 1, Color("d4b88a"))
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
		"kawara_edge":
			# The tiled roof's eave and verge, a sixth of a unit deep at the top of the texture:
			# a row of round tile ends (one each 4 px, under the rolls) on the dark lip of the
			# flat tiles; the rest is the plain grey of the verge's clay.
			var img := _blank(16, 16)
			img.fill(Color("4c5560"))
			for col in 4:
				var x := col * 4
				_px(img, x, 0, 4, 3, Color("2e343c"))
				_px(img, x + 1, 0, 2, 3, Color("7a8692"))
				_px(img, x + 1, 1, 1, 1, Color("9aa6b0"))
			_px(img, 0, 3, 16, 1, Color("2a3038"))
			for row in 3:
				_px(img, 0, 6 + row * 4, 16, 1, Color("3e4650"))
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
		"kaya":
			# The farmhouse's old grass thatch (Minka): grey-brown and weathered, the strands
			# running down the slope (texture v) in long streaks of lighter and darker straw,
			# one soft shadow a unit where a course laps over the next, a few flecks of moss.
			var img := _blank(16, 16)
			img.fill(Color("85714e"))
			for x in 16:
				var tone := rng.randi_range(0, 4)
				var top := rng.randi_range(0, 15)
				var c := Color("76633f") if tone < 2 else (Color("94805a") if tone == 4 else Color("85714e"))
				_px(img, x, top, 1, 16 - top, c)
				_px(img, x, 0, 1, top, c.lerp(Color("85714e"), 0.5))
			for i in 14:
				_px(img, rng.randi_range(0, 15), rng.randi_range(0, 12), 1, rng.randi_range(3, 5), Color("a08c64") if i % 2 else Color("625236"))
			for x in 16:
				_px(img, x, 14 + (1 if x % 3 == 0 else 0), 1, 1, Color("6a5a3c"))
			for i in 4:
				_px(img, rng.randi_range(0, 14), rng.randi_range(0, 13), 2, 1, Color("6a7444"))
			return img
		"hay":
			# Dried grass fodder (the barn's bundles and the hay in the trough): muted olive
			# gold, short strands lying mostly one way in lighter and darker tones, a few dark
			# gaps between them, so a bundle reads as packed grass and not a solid block.
			var img := _blank(16, 16)
			img.fill(Color("a08a52"))
			for i in 40:
				var x := rng.randi_range(0, 15)
				var y := rng.randi_range(0, 15)
				var c: Color = [Color("8a7444"), Color("b49c62"), Color("c2aa6e"), Color("7a663c")][i % 4]
				_px(img, x, y, rng.randi_range(2, 4), 1, c)
			for i in 10:
				_px(img, rng.randi_range(0, 15), rng.randi_range(0, 15), 1, 1, Color("5e5030"))
			return img
		"kaya_edge":
			# The thatch's trimmed eave edge, half a unit deep: the cut ends of the straw in tight
			# layers, dark in the shade under the slope, pale gold at the fresh-cut bottom
			# (texture v down = down the edge).
			var img := _blank(16, 16)
			for y in 16:
				_px(img, 0, y, 16, 1, Color("5e4e32").lerp(Color("bea26a"), clampf((y - 1) / 6.0, 0.0, 1.0)))
			for i in 48:
				var x := rng.randi_range(0, 15)
				var y := rng.randi_range(0, 8)
				_px(img, x, y, 1, 1, Color("dcc48c") if y > 3 and i % 3 else Color("4a3c26"))
			for y in [3, 6]:
				for x in range(0, 16, 2):
					_px(img, x + (y % 2), y, 1, 1, Color("6a5838"))
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
		"stand_sign":
			# 16 x 10 price board for the seed stand: a pale cedar board in a dark frame, three
			# brushed marks (a sprout and two price strokes) and a vermilion seal; no real text.
			var img := _blank(16, 10)
			img.fill(Color("4a3424"))
			_px(img, 1, 1, 14, 8, Color("d8bc8e"))
			_px(img, 3, 3, 1, 5, Color("2a2018"))
			_px(img, 2, 3, 1, 1, Color("2a2018"))
			_px(img, 4, 2, 1, 1, Color("2a2018"))
			for y in [3, 6]:
				_px(img, 6, y, 5, 1, Color("2a2018"))
			_px(img, 8, 4, 1, 2, Color("2a2018"))
			_px(img, 12, 6, 2, 2, Color("b83a2a"))
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
		"note", "notes":
			return _note_puff(kind == "notes")
	return _draw(4, 4, [[0, 0, 4, 4, "ff00ff"]])


## A music note in dark ink with a pale rim, so it reads on grass, path and snow: one eighth
## note (8 x 12) or two beamed together (11 x 12). Over a villager who whistles (Whistles).
static func _note_puff(pair: bool) -> Image:
	var ink := _blank(11 if pair else 8, 12)
	var c := Color("2e2420")
	var heads := [1, 6] if pair else [1]
	for x in heads:
		_px(ink, x, 8, 3, 2, c)        # the head, a squat oval
		_px(ink, x + 1, 7, 2, 1, c)
		_px(ink, x + 2, 1, 1, 7, c)    # the stem
	if pair:
		_px(ink, 3, 1, 6, 2, c)        # the beam
	else:
		_px(ink, 4, 2, 1, 2, c)        # the flag
		_px(ink, 5, 3, 1, 3, c)
	var img := _blank(ink.get_width(), ink.get_height())
	var rim := Color("f4ecd8")
	for y in img.get_height():
		for x in img.get_width():
			if ink.get_pixel(x, y).a > 0.0:
				img.set_pixel(x, y, c)
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if Rect2i(Vector2i.ZERO, ink.get_size()).has_point(q) and ink.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, rim)
					break
	return img


## HUD pieces in warm paper and wood. Frames are 16 x 16 nine-patches with a 4 px border
## (dark edge, two rows of wood, a dark inner line), slots 18 x 18, icons 12 x 12 / 14 x 14.
const UI_WOOD := Color("8a5a32")
const UI_WOOD_LIGHT := Color("a8743f")
const UI_WOOD_DARK := Color("5a3a20")
const UI_PAPER := Color("efe3c4")
const UI_PAPER_FIBRE := Color("e3d4b0")
const UI_SEAL := Color("c8442c")      # vermilion, like a name seal: marks the tool in hand


## The shared panel (UiStyle): 32 x 32, a 4 px dark wood border and a 24 x 24 centre that tiles.
## Paper = washi: a warm base with faint speckle and long pale fibres that wrap round the tile,
## so the seams do not show. Wood = planks with grain lines. Fixed seed, so it is always the same.
static func _ui_frame(kind: String) -> Image:
	var n := 32
	var m := 4
	var c := n - m * 2   # the tiling centre
	var img := _blank(n, n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261106 if kind == "paper" else 20261107
	_px(img, 0, 0, n, n, Color("3a2416"))
	_px(img, 1, 1, n - 2, n - 2, UI_WOOD)
	# Wood border: light bevel top and left, shade bottom and right, grain dashes along each side.
	_px(img, 1, 1, n - 2, 1, UI_WOOD_LIGHT)
	_px(img, 1, 1, 1, n - 2, Color("96653a"))
	_px(img, 1, n - 2, n - 2, 1, Color("6a4222"))
	_px(img, n - 2, 1, 1, n - 2, Color("6a4222"))
	for i in 14:
		var t := rng.randi_range(2, n - 6)
		var l := rng.randi_range(3, 8)
		var col := Color("7c4f2a") if i % 2 == 0 else Color("9a6a3c")
		match i % 4:
			0: _px(img, t, 2, l, 1, col)
			1: _px(img, t, n - 3, l, 1, col)
			2: _px(img, 2, t, 1, l, col)
			3: _px(img, n - 3, t, 1, l, col)
	_px(img, 3, 3, n - 6, n - 6, UI_WOOD_DARK)   # the dark inner line between wood and page
	# The tiling centre.
	var page := _blank(c, c)
	if kind == "wood":
		_px(page, 0, 0, c, c, Color("7a4e2a"))
		for y in [5, 11, 17, 23]:
			_px(page, 0, y, c, 1, Color("6c4424"))   # plank seams
		for i in 16:
			var l := rng.randi_range(4, 11)
			var x := rng.randi_range(0, c - 1)
			var y := rng.randi_range(0, c - 1)
			if y % 6 == 5:
				continue
			for k in l:
				page.set_pixel((x + k) % c, y, Color("8a5a32") if i % 2 == 0 else Color("6e4727"))
	else:
		_px(page, 0, 0, c, c, UI_PAPER)
		for i in 70:   # faint speckle, two tones
			page.set_pixel(rng.randi_range(0, c - 1), rng.randi_range(0, c - 1), UI_PAPER_FIBRE if i % 3 else Color("f4ead0"))
		for i in 9:   # long fibres at slight angles
			var x := rng.randi_range(0, c - 1)
			var y := rng.randi_range(0, c - 1)
			var dy := rng.randi_range(-1, 1)
			for k in rng.randi_range(5, 10):
				var fy := y + (k * dy) / 4
				page.set_pixel((x + k) % c, posmod(fy, c), Color("dccba0") if i % 2 == 0 else Color("f8f0da"))
	img.blit_rect(page, Rect2i(0, 0, c, c), Vector2i(m, m))
	for p in [Vector2i(0, 0), Vector2i(n - 1, 0), Vector2i(0, n - 1), Vector2i(n - 1, n - 1)]:
		img.set_pixelv(p, Color(0, 0, 0, 0))
	return img


static func _ui(kind: String, arg: String) -> Image:
	match kind:
		"frame":    # frame:<paper|wood>
			return _ui_frame(arg)
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
			return ItemArt.refine(img)
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
		"wild":     # wild:<id>, 14 x 14, a wild thing picked on the hill from its look in data/forage.json
			return _wild_icon(Forage.item(Forage.PREFIX + arg).get("look", {}))
		"kitchen":  # kitchen:<id>, 14 x 14, a cooking tool (data/recipes.json tools)
			return _kitchen_icon(arg)
		"keep":     # keep:<id>, 14 x 14, a keepsake from its look in data/keepsakes.json
			return _keepsake_icon(Keepsakes.keepsake("keep:" + arg).get("look", {}))
		"ribbon":   # ribbon:<place>, 14 x 14, a contest rosette in the place's colour
			var img := _blank(14, 14)
			_rosette(img, 7, 5, Keepsakes.ribbon_color(int(arg)))
			return _outline(img)
		"coin":     # a gold coin with a square hole
			var img := _blank(9, 9)
			_oval(img, 4.5, 4.5, 4.0, 4.0, Color("c8962a"))
			_oval(img, 4.5, 4.5, 3.0, 3.0, Color("e8c050"))
			_px(img, 3, 3, 3, 3, Color("c8962a"))
			_px(img, 4, 4, 1, 1, Color(0, 0, 0, 0))
			return img
		"heart":    # heart:<band 0..6>, 9 x 8, on the text box's name tag (colours in data/text_box.json)
			return _heart(int(arg))
		"more":     # the small vermilion arrow that says a press goes on
			var img := _blank(7, 4)
			for y in 4:
				_px(img, y, y, 7 - y * 2, 1, UI_SEAL)
			return img
		"scroll":   # scroll:<washi|roller_<w>|star_on|star_off|seal|arrow>, the village record (EndingScreen)
			return _scroll_art(arg)
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
	if is_animal_good(id):
		return _animal_good(id, 14)
	var img := _blank(14, 14)
	var look := crop_look(id)
	if _looks.has(id):
		var fruit := Color(look.get("fruit", "e8a23a"))
		var leaf := Color(look.get("leaf", "5fa83a"))
		var long: bool = look.get("shape", "") in ["vine", "stalk"]
		var rx := 2.5 if long else 4.0
		var ry := 5.0 if long else 4.0
		_oval(img, 7, 8.5, rx, ry, fruit)   # one material: ItemArt gives its lit and shaded sides
		if look.has("fruit_top"):
			_px(img, 4, 5, 6, 2, Color(look.fruit_top))
		_px(img, 6, 1, 2, 4, leaf)
		_px(img, 4, 2, 2, 2, leaf)
		_px(img, 8, 2, 2, 2, leaf.darkened(0.2))   # the leaf behind
		return ItemArt.refine(img)
	var cloths := [Color("3a5a8c"), Color("a8433a"), Color("5a8a4a"), Color("c8963a"), Color("7a4a8a")]
	var cloth: Color = cloths[posmod(hash(id), cloths.size())]
	_oval(img, 7, 9, 5.5, 4.0, cloth)
	_px(img, 5, 3, 4, 3, cloth)
	_px(img, 3, 2, 3, 2, cloth.darkened(0.2))   # the knot's ears
	_px(img, 8, 2, 3, 2, cloth.darkened(0.2))
	var dots := Color("f4ecd8")
	for p in [Vector2i(4, 9), Vector2i(8, 8), Vector2i(10, 11), Vector2i(6, 11)]:
		img.set_pixelv(p, dots)
	return ItemArt.refine(img, [dots])


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
	var eye := Color("1a1a1a")   # a small fixed mark, not toned
	img.set_pixel(3 if shape != "eel" else 1, int(cy) - 1, eye)
	return ItemArt.refine(img, [eye])


## The float and the bite mark. The bobber is red over white with a dark stem (5 x 7); the
const HEART_ROWS: Array[String] = [".##...##.", "#oo#.#oo#", "#ooo#ooo#", "#ooooooo#",
	".#ooooo#.", "..#ooo#..", "...#o#...", "....#...."]


## The heart band as one small heart: filled with the band's colour, a light glint top left;
## the last band has a gold glint instead, so a dear friend reads at a glance.
static func _heart(band: int) -> Image:
	var colors: Array = DialogueRunner.settings().get("hearts", ["efe3c4"])
	var fill := Color(colors[clampi(band, 0, colors.size() - 1)])
	var img := _blank(9, 8)
	for y in HEART_ROWS.size():
		for x in HEART_ROWS[y].length():
			match HEART_ROWS[y][x]:
				"#": img.set_pixel(x, y, Color("3a2416"))
				"o": img.set_pixel(x, y, fill)
	if band > 0:
		img.set_pixel(2, 2, Color("f0c850") if band >= colors.size() - 1 else fill.lightened(0.45))
	return img


## The 3D maple's leaf colours by season and its orange lumps (Trees.LEAVES.maple, Trees.MAPLE_FLAME;
## a test keeps them equal). Kept here, not read from Trees, so this script compiles alone.
const MAPLE_LEAVES := {"spring": Color("86b844"), "summer": Color("2f6e32"), "fall": Color("c42a1e")}
const MAPLE_FLAME := Color("dc6a1e")


## A Japanese maple for the flat view (24 x 32, the trunk's foot at (12, 30)): a small layered
## crown, a wide lower tier of four lumps, a narrower middle pair and a top lump, in the 3D
## maple's colours (Trees.LEAVES; the orange lumps among the reds in fall). In winter it is bare
## branches off the trunk, with snow on their upper side when the map has snow.
static func _maple_tree(season: String, snow: bool) -> Image:
	var img := _blank(24, 32)
	var bark := Color("4a3428")
	var leaf: Color = MAPLE_LEAVES.get(season, Color(0, 0, 0, 0))
	if leaf.a == 0.0:   # winter: bare branches
		_px(img, 11, 15, 2, 15, bark)
		for seg in [[Vector2i(12, 15), Vector2i(6, 9)], [Vector2i(12, 15), Vector2i(18, 9)], [Vector2i(12, 15), Vector2i(12, 3)],
				[Vector2i(6, 9), Vector2i(2, 5)], [Vector2i(6, 9), Vector2i(4, 13)], [Vector2i(18, 9), Vector2i(22, 5)],
				[Vector2i(18, 9), Vector2i(20, 13)], [Vector2i(12, 6), Vector2i(8, 2)], [Vector2i(12, 6), Vector2i(16, 2)]]:
			_line(img, seg[0], seg[1], bark)
		if snow:   # snow on the upper side of every branch pixel
			for y in range(1, 32):
				for x in 24:
					if img.get_pixel(x, y).a > 0.5 and img.get_pixel(x, y - 1).a < 0.5:
						img.set_pixel(x, y - 1, Color("f4f8fc"))
		return img
	_px(img, 11, 15, 2, 15, bark)
	# [x, y, rx, ry, colour, fall: lump turns orange]
	var lumps := [
		[5.5, 13.0, 4.0, 3.2, leaf.darkened(0.16), true], [18.5, 13.0, 4.0, 3.2, leaf.darkened(0.08), true],
		[8.0, 16.5, 4.0, 3.0, leaf.darkened(0.08), false], [16.0, 16.5, 4.0, 3.0, leaf.darkened(0.16), true],
		[8.0, 9.0, 4.0, 3.2, leaf.darkened(0.03), false], [16.0, 9.0, 4.0, 3.2, leaf.darkened(0.03), false],
		[12.0, 11.0, 4.0, 3.0, leaf, false], [12.0, 6.0, 3.2, 3.0, leaf.lightened(0.1), false],
	]
	for i in lumps.size():
		var l: Array = lumps[i]
		var c: Color = l[4]
		if season == "fall" and l[5]:
			c = MAPLE_FLAME.darkened(0.04 * (i % 3))
		_oval(img, l[0], l[1], l[2], l[3], c)
	return _outline(img)


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
## a stick, a cup with a saucer line, a glass bottle with a paper cap, a full bowl, a slice on
## a plate, a grilled fish on a plate, a paper bag of roast chestnuts, a baked sweet potato
## split open.
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
		"bowl":   # a lacquer or pottery bowl (accent) full to the rim (color)
			_oval(img, 7, 6, 6.0, 2.5, c)
			_px(img, 1, 6, 13, 3, a)
			_oval(img, 7, 9, 5.5, 3.0, a)
			_px(img, 5, 12, 5, 1, a.darkened(0.25))
			_px(img, 3, 7, 4, 1, a.lightened(0.25))
			_oval(img, 7, 5.5, 4.5, 1.5, c.lightened(0.15))
		"plate":   # a long plate (accent) with a slice of something on it (color)
			_oval(img, 7, 9.5, 6.5, 3.0, a)
			_oval(img, 7, 9, 5.0, 2.0, a.lightened(0.35))
			_px(img, 3, 5, 8, 4, c)
			_px(img, 3, 5, 8, 1, c.lightened(0.25))
			_px(img, 6, 5, 1, 4, c.darkened(0.15))
		"fish_plate":   # a whole grilled fish (color) on a long plate (accent)
			_oval(img, 7, 10, 6.5, 2.5, a)
			_oval(img, 6, 7, 4.5, 2.0, c)
			_px(img, 10, 5, 2, 5, c.darkened(0.15))
			_px(img, 3, 6, 1, 1, Color("1e1e1e"))
			_px(img, 5, 6, 4, 1, c.darkened(0.35))
		"bag":   # a paper bag (accent), folded open, full of chestnuts (color)
			_px(img, 3, 6, 8, 7, a)
			_px(img, 3, 6, 8, 1, a.darkened(0.15))
			for p in [[5, 4], [8, 4], [6.5, 2.5], [9.5, 5.5], [4, 5.5]]:
				_oval(img, p[0], p[1], 1.8, 1.6, c)
				img.set_pixel(int(p[0]) - 1, int(p[1]) - 1, c.lightened(0.35))
			_px(img, 5, 9, 4, 1, a.darkened(0.25))   # a printed band on the bag
		"imo":   # a baked sweet potato: dark skin (accent) split open to its gold inside (color)
			_oval(img, 7, 8, 6.0, 3.2, a)
			_oval(img, 7, 7.5, 4.0, 1.8, c)
			_oval(img, 6, 7, 1.5, 0.8, c.lightened(0.35))
			_px(img, 1, 9, 2, 1, a.darkened(0.2))
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


## The tools, 14 x 14, laid in flat materials (wood, steel, tin, bamboo) and toned by ItemArt:
## the light from the upper left gives the lit sides, the parts' lower edges their deep line.
## Only the whetted edges of the sickle and the axe keep a fixed bright glint.
const TOOL_WOOD := Color("9a6a3a")
const TOOL_STEEL := Color("9aa0aa")
const TOOL_IRON := Color("70767e")
const TOOL_EDGE := Color("cfd4dc")
const TOOL_TIN := Color("6a9ab0")
const TOOL_TIN_HANDLE := Color("4a7488")
const FLOAT_RED := Color("d8402a")
const FLOAT_WHITE := Color("f4ecd8")


static func _tool_icon(kind: String) -> Image:
	var img := _blank(14, 14)
	var wood := TOOL_WOOD
	var steel := TOOL_STEEL
	match kind:
		"hoe":
			_line(img, Vector2i(2, 12), Vector2i(9, 4), wood)
			_line(img, Vector2i(3, 12), Vector2i(10, 4), wood)
			_px(img, 8, 1, 5, 2, steel)
			_px(img, 11, 3, 2, 4, steel)
		"can":
			_px(img, 3, 5, 6, 6, TOOL_TIN)
			_line(img, Vector2i(9, 8), Vector2i(12, 4), TOOL_TIN)
			_px(img, 11, 3, 2, 1, TOOL_TIN)
			_px(img, 4, 2, 4, 1, TOOL_TIN_HANDLE)
			_px(img, 3, 3, 1, 2, TOOL_TIN_HANDLE)
			_px(img, 8, 3, 1, 2, TOOL_TIN_HANDLE)
		"sickle":
			_line(img, Vector2i(2, 12), Vector2i(5, 9), wood)
			_line(img, Vector2i(3, 12), Vector2i(6, 9), wood)
			for p in [Vector2i(5, 8), Vector2i(5, 7), Vector2i(5, 6), Vector2i(6, 5), Vector2i(7, 4), Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 4)]:
				_px(img, p.x, p.y, 1, 1, steel)
			for p in [Vector2i(6, 6), Vector2i(7, 5), Vector2i(8, 4), Vector2i(9, 4), Vector2i(10, 4)]:
				_px(img, p.x, p.y, 1, 1, TOOL_EDGE)
		"hammer":
			_px(img, 6, 5, 2, 8, wood)
			_px(img, 2, 1, 10, 4, TOOL_IRON)
		"axe":
			_line(img, Vector2i(3, 12), Vector2i(9, 2), wood)
			_line(img, Vector2i(4, 12), Vector2i(10, 2), wood)
			_px(img, 8, 1, 4, 5, steel)
			_px(img, 11, 1, 1, 5, TOOL_EDGE)
		"rod":   # a bamboo rod, its line hanging to a red float
			_line(img, Vector2i(1, 12), Vector2i(10, 1), _ROD)
			_line(img, Vector2i(2, 12), Vector2i(4, 10), _ROD_NODE)
			for p in [Vector2i(4, 9), Vector2i(7, 5)]:
				img.set_pixelv(p, _ROD_NODE)
			_px(img, 10, 10, 3, 2, FLOAT_RED)
			_px(img, 10, 12, 3, 1, FLOAT_WHITE)
			ItemArt.refine(img)
			_line(img, Vector2i(11, 2), Vector2i(11, 9), Color("e8e8e8"))   # the line, laid after: no rim
			return img
		_:
			return _draw(14, 14, [[0, 0, 14, 14, "ff00ff"]])
	return ItemArt.refine(img, [TOOL_EDGE])


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
	var ink := PortraitArt.eye()
	var lips := PortraitArt.mouth(skin)
	var img := _blank(40, 40)                                            # the figure alone; the background goes under at the end
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
	var clothes := Color(look.get("clothes", "3b6fd1"))
	PortraitArt.refine(img, [{"base": skin, "skin": true, "extra": [[skin.darkened(0.15), 0]]}, {"base": hair},
		{"base": hat, "extra": [[hat.darkened(0.25), 0]]}, {"base": clothes}])
	var eye_y := 21
	match expression:
		"smile":
			for x in [14, 23]:
				_px(img, x, eye_y, 1, 1, ink)
				_px(img, x + 1, eye_y - 1, 2, 1, ink)
				_px(img, x + 3, eye_y, 1, 1, ink)
			_px(img, 17, 27, 6, 1, lips)
			_px(img, 16, 26, 1, 1, lips)
			_px(img, 23, 26, 1, 1, lips)
			_px(img, 12, 24, 3, 1, Color("e89a8a"))
			_px(img, 25, 24, 3, 1, Color("e89a8a"))
		"surprised":
			for x in [15, 24]:
				_px(img, x, eye_y - 1, 2, 3, ink)
				_px(img, x - 1, eye_y - 5, 4, 1, hair.darkened(0.3))
			_px(img, 19, 26, 2, 2, lips)
		"worried":
			for x in [15, 24]:
				_px(img, x, eye_y, 2, 2, ink)
			_px(img, 13, eye_y - 3, 2, 1, hair.darkened(0.3))
			_px(img, 15, eye_y - 4, 2, 1, hair.darkened(0.3))
			_px(img, 23, eye_y - 4, 2, 1, hair.darkened(0.3))
			_px(img, 25, eye_y - 3, 2, 1, hair.darkened(0.3))
			_px(img, 18, 27, 4, 1, lips)
			_px(img, 17, 28, 1, 1, lips)
			_px(img, 22, 28, 1, 1, lips)
		_:   # calm
			for x in [15, 24]:
				_px(img, x, eye_y, 2, 2, ink)
			_px(img, 18, 27, 4, 1, lips)
	return _portrait_on(img, Color(look.get("bg", "c8d8c0")))


# --- villager portraits ------------------------------------------------------

## A villager's head and shoulders for the text box (40 x 40): colours from their look in
## data/villagers, the background and marks (wrinkles, stubble, child, plaster, mole) from
## their face in data/dialogue/speakers.json. The hair style and outfit shape them; `mood`
## (DialogueRunner.MOODS; any other draws neutral) sets the eyes, brows and mouth.
static func _portrait(id: String, mood: String) -> Image:
	var look := Villagers.look(id).duplicate()
	look.hair_style = portrait_hair_style(id)
	return _portrait_of(look, DialogueRunner.speakers().get(id, {}).get("face", {}), mood)


## The little one's head and shoulders (the text box when the farmer talks to them): the
## spouse's hair colour and style at `stage` (Child.small_style), the skin between the parents,
## the small happi. The crawler and the toddler get the rounder, wider-eyed baby face; the
## child stage the boy-sized face of the young villagers.
static func _child_portrait(mood: String, stage: String, look: Dictionary) -> Image:
	var face: Dictionary = DialogueRunner.speakers().get(Child.ID, {}).get("face", {})
	return _portrait_of(look, face, mood, stage != "child")


static func _portrait_of(look: Dictionary, face: Dictionary, mood: String, young := false) -> Image:
	var marks: Array = face.get("marks", [])
	var skin := Color(look.get("skin", "f2c79b"))
	var hair := Color(look.get("hair", "4a3020"))
	var child := "child" in marks
	var img := _blank(40, 40)                                      # the figure alone; the background goes under at the end
	var cx := 20.0
	var cy := 23.0 if young else (22.0 if child else 20.0)
	var rx := 9.5 if young else (9.0 if child else 9.5)
	var ry := 8.5 if young else (9.5 if child else 10.5)
	_portrait_hair_behind(img, look, cy)
	_portrait_body(img, look, child)
	_px(img, 18 if child else 17, int(cy) + 7, 4 if child else 6, 6, skin.darkened(0.18))   # neck
	for side in [-1.0, 1.0]:                                       # ears
		_oval(img, cx + side * (rx + 0.5), cy + 2, 2.2, 3.0, OUTLINE)
		_oval(img, cx + side * (rx + 0.5), cy + 2, 1.4, 2.2, skin.darkened(0.08))
	_oval(img, cx, cy, rx + 1, ry + 1, OUTLINE)
	_oval(img, cx, cy, rx, ry, skin)
	_px(img, 26 if child else 27, int(cy) - 2, 2, 9, skin.darkened(0.06))   # the shaded side
	var ey := int(cy) + 2                                          # eye row
	var my := ey + (5 if child else 6)                             # mouth row
	_portrait_hair(img, look, cy)
	PortraitArt.refine(img, _portrait_materials(look))             # the three tones, the deep lines, the rim
	_px(img, 20, ey + 2, 1, 2, skin.darkened(0.2))                 # nose
	if "wrinkles" in marks:
		for x in [13, 26]:
			_px(img, x, ey - 1, 1, 1, skin.darkened(0.2))
			_px(img, x, ey + 1, 1, 1, skin.darkened(0.2))
		_px(img, 16, my - 2, 1, 2, skin.darkened(0.14))
		_px(img, 23, my - 2, 1, 2, skin.darkened(0.14))
	if "stubble" in marks:
		for y in range(my - 1, int(cy + ry)):
			for x in range(12, 28):
				if (x + y) % 2 == 0 and PortraitArt.is_tone(img.get_pixel(x, y), skin, true):
					img.set_pixel(x, y, skin.darkened(0.16))
	if "plaster" in marks:                                         # a sticking plaster on the cheek
		_px(img, 24, ey + 3, 4, 2, Color("f4dcb0"))
		_px(img, 25, ey + 3, 2, 2, Color("dcbc90"))
	if "mole" in marks:
		img.set_pixel(24, my - 1, skin.darkened(0.45))
	var brow := hair.darkened(0.35) if hair.v > 0.3 else hair
	_portrait_mood(img, mood, ey, my, brow, 2 if "stubble" in marks else 1, child or "wrinkles" in marks, PortraitArt.mouth(skin))
	if young:                                                      # round cheeks
		_px(img, 12, ey + 3, 3, 2, Color("eaa08c"))
		_px(img, 25, ey + 3, 3, 2, Color("eaa08c"))
	return _portrait_on(img, Color(face.get("bg", "c8d8c0")))


## Portrait `fig` (drawn on a clear picture) over its background, lighter towards the top.
static func _portrait_on(fig: Image, bg: Color) -> Image:
	var img := _blank(40, 40)
	_px(img, 0, 0, 40, 40, bg)
	for y in 12:                                                   # light from above
		_px(img, 0, y, 40, 1, bg.lightened(0.14 * (1.0 - y / 12.0)))
	img.blend_rect(fig, Rect2i(0, 0, 40, 40), Vector2i.ZERO)
	return img


## The materials of a portrait in `look` for PortraitArt.refine, each with the plain darker and
## lighter shades the drawing gives it (the neck, the ears, the shaded cheek; the hair's combed
## lines, partings and shine; the top's folds and kimono line; the accent's knots and pins).
static func _portrait_materials(look: Dictionary) -> Array:
	var skin := Color(look.get("skin", "f2c79b"))
	var hair := Color(look.get("hair", "4a3020"))
	var top := Color(look.get("top", "3b6fd1"))
	var out := [
		{"base": skin, "skin": true, "extra": [[skin.darkened(0.18), 0], [skin.darkened(0.08), 1], [skin.darkened(0.06), 0]]},
		{"base": hair, "extra": [[hair.darkened(0.12), 0], [hair.darkened(0.14), 0], [hair.darkened(0.15), 0], [hair.darkened(0.3), 3],
			[hair.lightened(0.1), 2], [hair.lightened(0.12), 2], [hair.lightened(0.15), 2]]},
		{"base": top, "extra": [[top.darkened(0.12), 0], [top.darkened(0.18), 0], [top.darkened(0.25), 3]]},
		{"base": Color(look.get("lower", "3a3430"))},
	]
	for h in [look.get("accent", look.get("waist", "c8a050")), look.get("accent", look.get("waist", "e8e2d0")), look.get("waist", "c8a050")]:
		var c := Color(str(h))
		out.append({"base": c, "extra": [[c.darkened(0.1), 0], [c.darkened(0.18), 0], [c.darkened(0.2), 0], [c.lightened(0.2), 2]]})
	return out


## The hair styles a portrait can draw: the figures' own (FigureArt) and a few more that only
## the portrait knows, so people whose figures share a hair style still look apart in the text
## box: hime (a blunt fringe and straight locks cut at the chin), ponytail (tied high with a
## side-swept fringe), braid (one braid over the shoulder) and low_knot (parted in the middle,
## a knot at the nape with a hairpin through it).
const PORTRAIT_HAIR: Array[String] = ["bun", "short", "headband", "long", "straw_hat", "hime", "ponytail", "braid", "low_knot"]


## The hair style villager `id`'s portrait is drawn with: their face's "portrait_hair" in
## data/dialogue/speakers.json when it names one of PORTRAIT_HAIR, else their look's hair_style.
static func portrait_hair_style(id: String) -> String:
	var face: Dictionary = DialogueRunner.speakers().get(id, {}).get("face", {})
	var own := str(face.get("portrait_hair", ""))
	return own if own in PORTRAIT_HAIR else str(Villagers.look(id).get("hair_style", ""))


## The hair behind the head and shoulders: long hair down the back (long, hime), a ponytail
## swinging out to the right, a low knot at the nape on the left with its hairpin.
static func _portrait_hair_behind(img: Image, look: Dictionary, cy: float) -> void:
	var hair := Color(look.get("hair", "4a3020"))
	var accent := Color(look.get("accent", look.get("waist", "c8a050")))
	var y := int(cy)
	match look.get("hair_style", ""):
		"long", "hime":
			_px(img, 8, y - 6, 24, 22, OUTLINE)
			_px(img, 9, y - 6, 22, 21, hair)
		"ponytail":
			_oval(img, 32, cy - 1, 3.6, 8.5, OUTLINE)
			_oval(img, 32, cy - 1, 2.6, 7.5, hair)
			_px(img, 33, y - 4, 1, 8, hair.lightened(0.12))           # a shine down the tail
			_px(img, 27, y - 12, 5, 4, OUTLINE)
			_px(img, 28, y - 11, 4, 3, hair)
		"low_knot":
			_oval(img, 10, cy + 6, 4.4, 3.6, OUTLINE)
			_oval(img, 10, cy + 6, 3.4, 2.6, hair)
			_px(img, 8, y + 5, 3, 1, hair.lightened(0.12))
			_line(img, Vector2i(4, y + 2), Vector2i(15, y + 9), accent)   # the hairpin through it
			_px(img, 3, y + 1, 2, 2, accent.lightened(0.2))


## Shoulders and collar by outfit: a kimono's crossed white collar, a happi coat's open
## front with its bands, or a boy's round-necked shirt.
static func _portrait_body(img: Image, look: Dictionary, child: bool) -> void:
	var top := Color(look.get("top", "3b6fd1"))
	var accent := Color(look.get("accent", look.get("waist", "e8e2d0")))
	var w := 13.0 if child else (18.0 if look.get("outfit", "") == "happi" else 16.0)
	_oval(img, 20, 45, w + 1, 12, OUTLINE)
	_oval(img, 20, 45, w, 11, top)
	match look.get("outfit", ""):
		"kimono":
			var collar := Color("f4efe4")
			for d in [0, 1]:
				_line(img, Vector2i(15 + d, 34), Vector2i(19 + d, 40), collar)
				_line(img, Vector2i(24 - d, 34), Vector2i(20 - d, 40), collar)
			_line(img, Vector2i(14, 34), Vector2i(18, 40), top.darkened(0.25))
		"happi":
			_px(img, 17, 35, 6, 5, Color(look.get("lower", "3a3430")))      # the undershirt
			for d in [0, 1]:
				_line(img, Vector2i(15 + d, 34), Vector2i(17 + d, 40), accent)
				_line(img, Vector2i(24 - d, 34), Vector2i(22 - d, 40), accent)
		_:
			_oval(img, 20, 35, 4.5, 1.6, top.darkened(0.18))                 # a round neckline
			_px(img, 11, 38, 2, 2, top.darkened(0.12))                       # a fold at the sleeve


## Hair by style: a grey bun with a hairpin, short hair under a smith's headband, long hair
## with a fringe and a hair ornament, tufts under a straw hat, or one of the portrait-only
## styles (PORTRAIT_HAIR): a hime cut, a ponytail, a braid, a low knot.
static func _portrait_hair(img: Image, look: Dictionary, cy: float) -> void:
	var hair := Color(look.get("hair", "4a3020"))
	var accent := Color(look.get("accent", look.get("waist", "c8a050")))
	var y := int(cy)
	match look.get("hair_style", ""):
		"bun":
			_oval(img, 20, cy - 14, 4.5, 3.5, OUTLINE)
			_oval(img, 20, cy - 14, 3.5, 2.5, hair)
			_oval(img, 20, cy - 9, 10.5, 4.6, hair)
			for side in [-1.0, 1.0]:                                  # soft wings over the ears
				_oval(img, 20 + side * 9.5, cy - 3, 2.6, 5.5, hair)
			for x in [14, 18, 23]:                                    # combed lines
				_px(img, x, y - 11, 1, 3, hair.darkened(0.12))
			var pin := Color(look.get("waist", "c8a050"))
			_px(img, 22, y - 15, 6, 1, pin)
			_px(img, 27, y - 16, 2, 2, pin.lightened(0.2))
		"headband":
			_oval(img, 20, cy - 9, 10.5, 4.6, hair)
			for x in [12, 17, 22, 26]:                                # spiky on top
				_px(img, x, y - 15, 2, 3, hair)
			_px(img, 10, y - 6, 2, 5, hair)
			_px(img, 28, y - 6, 2, 5, hair)
			_px(img, 9, y - 7, 22, 3, accent)                         # the tenugui headband
			_px(img, 9, y - 5, 22, 1, accent.darkened(0.2))
			_px(img, 29, y - 9, 3, 3, accent)                         # its knot and tails
			_px(img, 31, y - 6, 2, 4, accent.darkened(0.1))
			_px(img, 33, y - 5, 1, 3, accent.darkened(0.1))
		"long":
			_oval(img, 20, cy - 9, 10.8, 4.8, hair)
			_px(img, 10, y - 7, 3, 16, hair)                          # locks framing the face
			_px(img, 27, y - 7, 3, 16, hair)
			_px(img, 12, y - 5, 16, 2, hair)                          # the fringe...
			for x in [15, 20, 24]:
				img.set_pixel(x, y - 3, hair)                         # ...cut a little uneven
			_px(img, 18, y - 13, 1, 3, hair.lightened(0.15))          # a shine
			_oval(img, 27, cy - 11, 1.8, 1.8, accent)                 # a flower kanzashi
			_px(img, 28, y - 9, 1, 3, accent.darkened(0.2))
		"hime":
			_oval(img, 20, cy - 9, 10.8, 4.8, hair)
			_px(img, 10, y - 7, 3, 13, hair)                          # straight locks cut at the chin
			_px(img, 27, y - 7, 3, 13, hair)
			_px(img, 11, y - 6, 18, 3, hair)                          # a blunt, level fringe
			_px(img, 11, y - 3, 18, 1, hair.darkened(0.15))
			_px(img, 12, y - 13, 16, 1, accent)                       # a ribbon over the crown
			_px(img, 18, y - 12, 1, 2, hair.lightened(0.15))          # a shine
		"ponytail":
			_oval(img, 20, cy - 9, 10.5, 4.4, hair)
			_px(img, 10, y - 7, 2, 6, hair)                           # short side locks
			_px(img, 28, y - 7, 2, 5, hair)
			_px(img, 12, y - 6, 10, 2, hair)                          # the fringe swept to one side
			_px(img, 12, y - 4, 5, 1, hair)
			for x in [15, 19, 24]:                                    # combed back
				_px(img, x, y - 12, 1, 3, hair.darkened(0.14))
			_px(img, 28, y - 12, 3, 2, accent)                        # the hair tie
		"braid":
			_oval(img, 20, cy - 9, 10.5, 4.6, hair)
			_px(img, 20, y - 14, 1, 5, hair.darkened(0.3))           # a middle parting
			_px(img, 10, y - 7, 2, 8, hair)
			_px(img, 28, y - 7, 2, 8, hair)
			_px(img, 12, y - 6, 7, 1, hair)
			_px(img, 21, y - 6, 7, 1, hair)
			for i in 5:                                               # the braid over the left shoulder
				_oval(img, 11, cy + 5 + i * 3, 2.6, 2.0, OUTLINE)
				_oval(img, 11, cy + 5 + i * 3, 1.8, 1.3, hair if i % 2 == 0 else hair.lightened(0.1))
			_px(img, 9, y + 19, 4, 2, accent)                         # tied with a straw cord
		"low_knot":
			_oval(img, 20, cy - 9, 10.6, 4.6, hair)
			_px(img, 20, y - 14, 1, 6, hair.darkened(0.3))           # parted in the middle
			for side in [-1.0, 1.0]:                                  # swept down over the ears to the jaw
				_oval(img, 20 + side * 9.2, cy - 1, 2.8, 7.5, hair)
			_line(img, Vector2i(12, y - 5), Vector2i(19, y - 8), hair)
			_line(img, Vector2i(21, y - 8), Vector2i(28, y - 5), hair)
			_px(img, 23, y - 12, 1, 3, hair.lightened(0.15))          # a shine
		"straw_hat":
			_px(img, 10, y - 7, 3, 5, hair)                           # tufts under the brim
			_px(img, 27, y - 7, 3, 5, hair)
			_px(img, 14, y - 6, 3, 2, hair)
			_px(img, 21, y - 6, 4, 2, hair)
			_oval(img, 20, cy - 8, 16, 3.6, OUTLINE)
			_oval(img, 20, cy - 8, 15, 2.8, accent)                   # the brim
			_oval(img, 20, cy - 12, 8.5, 5.5, OUTLINE)
			_oval(img, 20, cy - 12, 7.5, 4.8, accent)                 # the crown
			_px(img, 13, y - 11, 14, 2, Color("5a6a3a"))              # a cord band
			for x in range(14, 27, 3):                                # the weave
				_px(img, x, y - 14, 1, 1, accent.darkened(0.18))
				_px(img, x - 1, y - 8, 1, 1, accent.darkened(0.18))
		_:
			_oval(img, 20, cy - 9, 10.5, 4.6, hair)


## The eyes, brows and mouth for `mood`. `ey` / `my` are the eye and mouth rows, `brow_h`
## the brows' thickness; `soft` eyes (an old woman's, a boy's) are drawn rounder.
static func _portrait_mood(img: Image, mood: String, ey: int, my: int, brow: Color, brow_h: int, soft: bool, lips: Color) -> void:
	var ink := PortraitArt.eye()
	var white := Color("f8f4ec")
	var eyes := [15, 23]                                          # each eye's left pixel
	match mood:
		"happy":
			for x in eyes:                                        # closed, smiling eyes
				_px(img, x - 1, ey, 1, 1, ink)
				_px(img, x, ey - 1, 2, 1, ink)
				_px(img, x + 2, ey, 1, 1, ink)
				_px(img, x - 1, ey - 4, 4, brow_h, brow)
			_px(img, 16, my - 1, 1, 1, lips)                       # an open smile
			_px(img, 23, my - 1, 1, 1, lips)
			_px(img, 17, my, 6, 1, lips)
			_px(img, 18, my + 1, 4, 1, Color("b84a4a"))
			_px(img, 12, ey + 3, 3, 1, Color("e89a8a"))           # blush
			_px(img, 25, ey + 3, 3, 1, Color("e89a8a"))
		"sad":
			for x in eyes:
				_px(img, x, ey + 1, 2, 2 if soft else 1, ink)
			for i in brow_h:                                      # brows up in the middle
				_line(img, Vector2i(13, ey - 2 + i), Vector2i(16, ey - 4 + i), brow)
				_line(img, Vector2i(26, ey - 2 + i), Vector2i(23, ey - 4 + i), brow)
			_px(img, 18, my, 4, 1, lips)                           # a frown
			_px(img, 17, my + 1, 1, 1, lips)
			_px(img, 22, my + 1, 1, 1, lips)
			_px(img, 15, ey + 3, 1, 2, Color("8ac8f0"))           # a tear
		"surprised":
			for x in eyes:
				_px(img, x - 1, ey - 2, 4, 5, white)
				_px(img, x, ey - 1, 2, 3, ink)
				_px(img, x - 1, ey - 5, 1, brow_h, brow)          # brows up high, arched
				_px(img, x, ey - 6, 2, brow_h, brow)
				_px(img, x + 2, ey - 5, 1, brow_h, brow)
			_px(img, 19, my - 1, 2, 3, lips)                       # an O
			_px(img, 19, my, 2, 1, Color("b84a4a"))
		"angry":
			for x in eyes:
				_px(img, x, ey, 2, 2, ink)
			for i in brow_h + 1:                                  # brows down in the middle
				_line(img, Vector2i(13, ey - 4 + i), Vector2i(16, ey - 2 + i), brow)
				_line(img, Vector2i(26, ey - 4 + i), Vector2i(23, ey - 2 + i), brow)
			_px(img, 17, my - 1, 6, 3, lips)                       # gritted teeth
			_px(img, 18, my, 4, 1, white)
			var red := Color("d8342c")                            # a cross mark of temper
			for p in [Vector2i(32, 4), Vector2i(35, 4), Vector2i(32, 8), Vector2i(35, 8)]:
				_px(img, p.x, p.y, 1, 2, red)
			_px(img, 33, 6, 2, 2, red)
		_:   # neutral
			for x in eyes:
				_px(img, x, ey - (1 if soft else 0), 2, 3 if soft else 2, ink)
				if soft:
					img.set_pixel(x, ey - 1, white)
				_px(img, x - 1, ey - 3 - (1 if soft else 0), 4, brow_h, brow)
			_px(img, 18, my, 4, 1, lips)


## A keepsake: a glass wind chime (bell, clapper, paper strip), a round paper fan on a
## bamboo handle, a small clay rabbit, a round paper lantern with a moon on it, a red
## daruma with gold trim and one painted eye, a cloth charm bag on its cord, or a red and
## white mizuhiki knot (the proposal item, data/marriage.json).
static func _keepsake_icon(look: Dictionary) -> Image:
	var img := _blank(14, 14)
	var c := Color(look.get("color", "a8d4ec"))
	var a := Color(look.get("accent", "c8442c"))
	match look.get("shape", ""):
		"chime":
			_px(img, 6, 0, 2, 2, Color("6a5a48"))          # the cord
			_oval(img, 7, 4.5, 3.5, 3.0, c)               # the glass bell
			_px(img, 3, 5, 8, 2, c)
			_px(img, 4, 3, 1, 2, c.lightened(0.5))
			_px(img, 5, 4, 4, 1, a)                       # a painted band
			_px(img, 7, 7, 1, 2, Color("6a5a48"))         # the clapper string
			_px(img, 6, 9, 3, 5, Color("f4f0e6"))         # the paper strip that catches the wind
			_px(img, 6, 10, 3, 1, a)
		"fan":
			_px(img, 6, 8, 2, 6, Color("c8a060"))          # the bamboo handle
			_oval(img, 7, 5.5, 5.5, 4.5, c)
			_oval(img, 7, 5.5, 2.5, 2.0, a)               # a painted flower
			for x in [3, 7, 11]:                          # the ribs
				_line(img, Vector2i(7, 9), Vector2i(x, 2), c.darkened(0.15))
		"rabbit":
			_oval(img, 7, 9.5, 4.5, 3.5, c)                # the body, sitting
			_oval(img, 9, 6, 2.5, 2.2, c)                 # the head
			_px(img, 8, 1, 1, 4, c)                       # the long ears
			_px(img, 10, 1, 1, 4, c)
			_px(img, 8, 2, 1, 2, a.lightened(0.4))
			img.set_pixel(10, 6, a)                       # a red eye
			_px(img, 3, 9, 2, 2, a.lightened(0.3))        # a painted spot on the flank
			_px(img, 2, 13, 10, 1, c.darkened(0.25))      # where it sits
		"lantern":
			_px(img, 6, 0, 2, 2, Color("4a3424"))          # the hanger
			_px(img, 4, 2, 6, 1, Color("2e2a26"))          # the top and bottom rims
			_px(img, 4, 12, 6, 1, Color("2e2a26"))
			_oval(img, 7, 7.5, 5.0, 4.8, c)               # the glowing paper
			for y in [5, 8, 10]:                          # its ribs
				_px(img, 3, y, 8, 1, c.darkened(0.12))
			_oval(img, 7, 6.5, 2.0, 2.0, a)               # a dark night sky...
			_oval(img, 7.5, 6.5, 1.3, 1.3, Color("f8f4e0"))  # ...round a full moon
		"daruma":
			_oval(img, 7, 7.5, 5.5, 6.0, c)               # the round red body
			_oval(img, 7, 6, 3.2, 2.8, Color("f4ead8"))   # the face
			_px(img, 5, 5, 1, 2, Color("1e1e1e"))         # one eye painted in (the other waits for a wish)
			_px(img, 8, 5, 1, 2, Color("f4ead8").darkened(0.2))
			_px(img, 4, 10, 6, 1, a)                      # gold trim on the belly
			_px(img, 6, 11, 2, 1, a)
		"charm":
			_line(img, Vector2i(5, 0), Vector2i(7, 3), a)  # the cord loop
			_line(img, Vector2i(9, 0), Vector2i(7, 3), a)
			_px(img, 4, 3, 6, 10, c)                      # the cloth bag
			_px(img, 4, 3, 6, 1, c.darkened(0.2))
			_px(img, 5, 6, 4, 5, c.lightened(0.15))       # a brocade panel with a gold mark
			_px(img, 6, 7, 2, 3, a)
		"knot":   # a mizuhiki knot: red and white paper cords tied in three loops, two tails below
			for p in [[4, 4], [10, 4], [7, 8]]:           # the loops: a red ring round a white one
				_oval(img, p[0], p[1], 3.0, 2.6, c)
				_oval(img, p[0], p[1], 1.6, 1.3, a)
				_oval(img, p[0], p[1], 0.6, 0.6, Color(0, 0, 0, 0))
			_px(img, 6, 5, 3, 2, c.darkened(0.2))         # where the cords cross
			_line(img, Vector2i(6, 10), Vector2i(4, 13), c)   # the tails
			_line(img, Vector2i(8, 10), Vector2i(10, 13), c)
			_line(img, Vector2i(7, 10), Vector2i(7, 13), a)
		_:
			_oval(img, 7, 7, 5, 5, c)
	return _outline(img)


## A contest rosette: a round of pleats in `c` with a darker heart and two tails below it;
## `small` for the board at home (5 px across instead of 9).
static func _rosette(img: Image, cx: int, cy: int, c: Color, small := false) -> void:
	var r := 2.5 if small else 4.5
	var tail := 1 if small else 2
	_px(img, cx - 1 - tail, cy + 1, tail, 4 if small else 6, c.darkened(0.15))
	_px(img, cx + 1, cy + 1, tail, 4 if small else 6, c.darkened(0.15))
	_oval(img, cx, cy, r, r, c)
	_oval(img, cx, cy, r * 0.45, r * 0.45, c.darkened(0.25) if c.v > 0.6 else c.lightened(0.3))
	img.set_pixel(cx - 1, cy - 1, Color("e8c050"))   # the gold button


## The farmhouse's ribbon board (StoryProps / StoryView): a framed paper board with one
## rosette per ribbon won, in the order won ("112" = two firsts, then a second), six to a row.
static func _ribbon_board(places: String) -> Image:
	var img := _blank(42, 26)
	_px(img, 0, 0, 42, 26, Color("4a3424"))   # the frame
	_px(img, 1, 1, 40, 24, Color("6a4a30"))
	_px(img, 2, 2, 38, 22, UI_PAPER)
	for i in mini(places.length(), Keepsakes.BOARD_MOST):
		var x := 5 + (i % 6) * 6
		var y := 6 + (i / 6) * 11
		_rosette(img, x, y, Keepsakes.ribbon_color(int(places[i])), true)
	return img


## Nana's sky map (heart_nana_6, nana_sky), drawn in pencil on an old bedsheet and pinned to
## Shige's hen barn (30 x 20): a pale sheet with a fold or two, red pins at the top corners, a
## crescent moon and a scatter of small stars; her mother's star, the small one that blinks (a
## tiny cross with dashes round it); her father's by the band 5 answer: `steady` the big one far
## left that never moves, `beside` a middling one right by her mother's; and the farmer's by the
## band 6 answer: `near` close to her father's, `field` low on the right over three drawn rows,
## a little twinkly.
static func _sky_map(father: String, farmer: String) -> Image:
	var img := _blank(30, 20)
	var sheet := Color("dcd4bc")   # a little dim, so it does not wash out on a sunlit wall
	var lead := Color("23283e")
	var soft := Color("55596e")
	_px(img, 0, 0, 30, 20, sheet)
	_px(img, 0, 0, 1, 18, sheet.darkened(0.22))    # its edges, shadowed against the boards
	_px(img, 29, 2, 1, 16, sheet.darkened(0.22))
	_px(img, 0, 18, 30, 2, sheet.darkened(0.3))    # the hem, turned over
	_px(img, 11, 0, 1, 20, sheet.darkened(0.06))   # a fold down the sheet
	_px(img, 0, 11, 30, 1, sheet.darkened(0.05))   # and one across
	_px(img, 1, 0, 2, 2, Color("c8342c"))          # the pins
	_px(img, 27, 0, 2, 2, Color("c8342c"))
	var star := func(x: int, y: int, r: int, c: Color) -> void:
		_px(img, x - r, y, r * 2 + 1, 1, c)
		_px(img, x, y - r, 1, r * 2 + 1, c)
	# The moon, a crescent top left, and the small stars Nana dotted everywhere.
	_px(img, 4, 3, 2, 4, lead)
	_px(img, 5, 2, 2, 1, lead)
	_px(img, 5, 7, 2, 1, lead)
	for q in [[9, 3], [14, 2], [24, 4], [16, 9], [7, 13], [13, 15], [22, 8], [3, 9], [27, 12], [19, 3]]:
		img.set_pixel(q[0], q[1], soft)
	# Her mother's: small, and it blinks (the dashes round it).
	star.call(18, 6, 1, lead)
	for q in [[16, 4], [20, 4], [16, 8], [20, 8]]:
		img.set_pixel(q[0], q[1], soft)
	var dad := Vector2i(7, 9)
	if father == "beside":
		dad = Vector2i(22, 6)
		star.call(dad.x, dad.y, 1, lead)
		img.set_pixel(dad.x - 1, dad.y - 1, soft)
		img.set_pixel(dad.x + 1, dad.y + 1, soft)
	else:   # the big one that never moves
		star.call(dad.x, dad.y, 2, lead)
		_px(img, dad.x - 1, dad.y - 1, 3, 3, lead)
	if farmer == "field":   # out by itself over the farmer's field: three rows of it
		for y in [15, 16, 17]:
			_px(img, 19, y, 9, 1, Color("4a6a2a") if y % 2 == 1 else Color("7a5a3a"))
		star.call(23, 12, 1, Color("b07418"))
		for q in [[21, 10], [25, 10], [21, 14], [25, 14]]:
			img.set_pixel(q[0], q[1], Color("c8902a"))
	else:   # close to her father's
		var at := dad + Vector2i(4, 3) if father != "beside" else dad + Vector2i(3, 4)
		star.call(at.x, at.y, 1, Color("b07418"))
	return img


## What the band 5 and 6 heart events leave in the world (map props gated by a flag, StoryProps):
## Hachiro's iron door bell (12 x 16, hanging from its bracket), the store's new sign board
## (48 x 14; "old" = the old name freshly painted, "new" = Sayo's own red board), Tome's
## jar of pickled plums with a note on the lid (12 x 12) and Kota's carp streamer on its
## bamboo pole (26 x 40). While a house extension is being built, the builder's lumber lies
## beside the farmhouse: a stack of planed boards on two bearers with a saw on top (16 x 28,
## a 1 x 2 cell stack seen from the front).
static func _story(kind: String) -> Image:
	match kind:
		"noren_rows", "noren_flowers", "noren_shino":
			return _noren_story(kind.get_slice("_", 1))
		"boat_father", "boat_new":
			# The name Mio painted on her boat's side (heart_mio_6, mio_boat): a pale painted
			# plaque, 14 x 6, with her father's coiled red dragon (Tatsu) on it, or her new name's
			# mark, a blue fish leaping a wave.
			var img := _blank(14, 6)
			var plaque := Color("e8e0cc")
			_px(img, 0, 0, 14, 6, plaque)
			_px(img, 0, 5, 14, 1, plaque.darkened(0.2))
			if kind == "boat_father":
				var red := Color("b8302a")
				for pt in [[2, 3], [3, 2], [4, 1], [5, 1], [6, 2], [7, 3], [8, 3], [9, 2], [10, 1], [11, 2]]:
					_px(img, pt[0], pt[1], 1, 2, red)
				_px(img, 11, 1, 2, 1, red)      # the head
				img.set_pixel(12, 2, Color("f0c040"))
			else:
				var blue := Color("2e4e8a")
				_px(img, 4, 2, 5, 2, blue)      # the fish
				_px(img, 3, 1, 1, 1, blue)
				_px(img, 3, 4, 1, 1, blue)
				_px(img, 9, 3, 1, 1, blue)
				img.set_pixel(7, 2, plaque)     # its eye
				for x in range(1, 13):          # the wave under it
					img.set_pixel(x, 4 + (x % 3 == 0 as int), Color("4a8ab8"))
			return img
		"captain_jar":
			# Nana's jar by her father's door (heart_nana, nana_captain "jar"), 10 x 13: a glass
			# jar of ditch water with weed in it, Captain the tadpole (a black head, a wiggle of
			# tail), a paper lid tied on with red string and the name brushed on a paper slip.
			var img := _blank(10, 13)
			var glass := Color("a8c4c8")
			_px(img, 1, 3, 8, 10, glass)                   # the jar
			_px(img, 1, 12, 8, 1, glass.darkened(0.25))
			_px(img, 2, 5, 6, 7, Color("6e9a86"))         # the water
			_px(img, 2, 5, 6, 1, Color("9cc4b4"))         # its top, catching the light
			_px(img, 3, 8, 1, 4, Color("3e6a3a"))         # weed
			_px(img, 6, 9, 1, 3, Color("3e6a3a"))
			_px(img, 4, 7, 2, 2, Color("1e1a16"))         # Captain's head
			_px(img, 6, 8, 1, 1, Color("1e1a16"))         # and tail
			img.set_pixel(7, 7, Color("1e1a16"))
			_px(img, 1, 3, 1, 9, glass.lightened(0.35))   # the glint down one side
			_px(img, 0, 1, 10, 2, Color("ece4cc"))        # the paper lid
			_px(img, 0, 2, 10, 1, Color("c8342c"))        # the string round it
			_px(img, 3, 0, 4, 1, Color("ece4cc"))
			return _outline(img)
		"frog":
			# Captain grown (heart_nana_6), singing on a stone at the ditch's edge, 12 x 10: a
			# green frog facing out, eyes up on top, his throat puffed pale, the stone under him
			# and a reed beside.
			var img := _blank(12, 10)
			var green := Color("5a8a3a")
			_px(img, 1, 7, 10, 3, Color("7e7a72"))        # the stone
			_px(img, 1, 7, 10, 1, Color("a29e94"))
			_px(img, 3, 3, 6, 4, green)                    # his body
			_px(img, 2, 5, 8, 2, green)
			_px(img, 3, 2, 2, 2, green.lightened(0.2))     # the eyes
			_px(img, 7, 2, 2, 2, green.lightened(0.2))
			img.set_pixel(4, 2, Color("1e1a16"))
			img.set_pixel(7, 2, Color("1e1a16"))
			_px(img, 4, 5, 4, 2, Color("e2dca8"))         # the throat, puffed to sing
			_px(img, 2, 6, 1, 1, green.darkened(0.3))      # the feet
			_px(img, 9, 6, 1, 1, green.darkened(0.3))
			_px(img, 11, 0, 1, 8, Color("6e8a3a"))         # a reed
			return _outline(img)
		"jizo_bibs":
			# The new red bib Genzo asked for (heart_genzo_5), tied over the jizo's old one:
			# bright red cloth narrowing to a rounded hem, a white sewn edge, the ties at the neck.
			var img := _blank(8, 7)
			var red := Color("e23a2c")
			_px(img, 1, 0, 6, 1, red.darkened(0.25))   # the ties round the neck
			_px(img, 1, 1, 6, 3, red)
			_px(img, 2, 4, 4, 1, red)
			_px(img, 2, 5, 4, 1, Color("f2ece0"))     # the white hem
			_px(img, 2, 1, 1, 2, red.lightened(0.3))  # a fold catching the light
			return _outline(img)
		"jizo_scarf":
			# Nana's red scarf (nana_scarf), 10 x 9: a knitted band round the neck with two cream
			# stripes and one end hanging down the front, a cream stripe near its tip.
			var img := _blank(10, 9)
			var red := Color("d02a3c")
			var cream := Color("f2e6c8")
			_px(img, 0, 0, 10, 3, red)
			_px(img, 0, 1, 10, 1, red.lightened(0.15))
			_px(img, 1, 3, 8, 1, red.darkened(0.2))   # the shadow under the wind
			_px(img, 3, 0, 1, 3, cream)               # the stripes round it
			_px(img, 6, 0, 1, 3, cream)
			_px(img, 5, 3, 3, 5, red)                  # the hanging end
			_px(img, 5, 5, 3, 1, cream)
			_px(img, 5, 8, 3, 1, red.darkened(0.2))   # fringe
			return _outline(img)
		"kiln_mark":
			# The three thumbprints in the clay over the kiln's mouth (heart_ichiro_6): the
			# father's, Ichiro's and the farmer's, each a pressed dark oval with a lighter rim.
			# The farmer's print only, 10 x 8, on the new kiln beside Ichiro's: a lighter rim
			# round a dark oval with two ridges of the thumb's skin, big enough to read.
			var img := _blank(10, 8)
			var clay := Color("b08458")
			_px(img, 1, 0, 8, 8, clay.lightened(0.2))
			_px(img, 0, 1, 10, 6, clay.lightened(0.2))
			_px(img, 2, 1, 6, 6, Color("4a2e1c"))
			_px(img, 1, 2, 8, 4, Color("4a2e1c"))
			_px(img, 3, 3, 4, 1, clay.darkened(0.1))   # ridges
			_px(img, 3, 5, 4, 1, clay.darkened(0.1))
			return img
		"kiln_site":
			# The new kiln half built (32 x 30): a ring of two courses of clay bricks round wet
			# clay, the mouth gap in front with a timber form, a stack of bricks and a shovel.
			var img := _blank(32, 30)
			var b1 := Color("b4553a")
			var b2 := Color("9a4630")
			_px(img, 5, 12, 22, 9, Color("8a6a4a"))              # the wet clay inside
			for row in 2:
				for k in 6:
					_px(img, 3 + k * 4 + (row * 2), 14 + row * 5, 4, 4, b1 if (k + row) % 2 == 0 else b2)
			_px(img, 11, 19, 10, 6, Color("1e1612"))              # the open mouth
			_px(img, 10, 17, 2, 9, Color("7a5a3a"))               # the form
			_px(img, 20, 17, 2, 9, Color("7a5a3a"))
			_px(img, 10, 16, 12, 2, Color("7a5a3a"))
			for row in 3:
				for k in 3 - row:
					_px(img, 24 + k * 3 + row, 24 - row * 2, 3, 2, b1 if (row + k) % 2 == 0 else b2)
			_px(img, 1, 14, 1, 12, Color("c9a468"))               # the shovel
			_px(img, 0, 24, 3, 4, Color("8a8f96"))
			return _outline(img)
		"kiln_new":
			# The finished new kiln (32 x 30): the same dome of baked clay as the old one, a
			# stone-framed mouth, a chimney and Ichiro's print over the mouth.
			var img := _blank(32, 30)
			var clay := Color("9a7656")
			_px(img, 21, 2, 4, 10, clay.darkened(0.3))            # the chimney
			_px(img, 5, 10, 22, 4, clay.lightened(0.06))          # the dome's crown
			_px(img, 2, 14, 28, 14, clay)
			_px(img, 2, 25, 28, 3, clay.darkened(0.15))           # the soot-dark foot
			_px(img, 10, 21, 12, 7, Color("1e1612"))              # the mouth
			_px(img, 8, 19, 16, 2, Color("a29e94"))               # the lintel
			_px(img, 8, 21, 2, 7, Color("8e8a80"))
			_px(img, 22, 21, 2, 7, Color("8e8a80"))
			_px(img, 5, 14, 8, 4, clay.lightened(0.25))           # Ichiro's print
			_px(img, 6, 15, 6, 2, Color("4a2e1c"))
			return _outline(img)
		"kiln_worn":
			# The old kiln's wear over its 2 x 2 footing (32 x 32, see-through elsewhere): two
			# hairline cracks in the clay, a branch off the left one, and a chip knocked out of the
			# front-right corner with its pale broken edge. Drawn on top of the kiln's box.
			var img := _blank(32, 32)
			var crack := Color("2e1d12")
			for q in [[6, 6], [6, 7], [7, 8], [7, 9], [7, 10], [6, 11], [6, 12], [7, 13], [8, 14], [8, 15], [7, 16], [8, 12], [9, 12], [10, 13]]:
				_px(img, q[0], q[1], 1, 1, crack)
			for q in [[25, 8], [25, 9], [24, 10], [24, 11], [23, 12], [23, 13], [24, 14], [23, 15], [22, 16]]:
				_px(img, q[0], q[1], 1, 1, crack)
			_px(img, 23, 22, 4, 1, Color("c9a07a"))   # the broken edge, lit
			_px(img, 23, 23, 4, 2, crack)              # the dark hollow
			return img
		"rope_lift":
			# The rope lift's winch at the cave mouth (20 x 28), once a landing is reached: a
			# timber gantry over a stone-lipped shaft, a drum wound with rope between its posts,
			# a crank on the right, the rope running down into the dark and a lantern hung lit
			# off the beam.
			var img := _blank(20, 28)
			var timber := Color("6a4a2a")
			var timber_light := Color("8e6a3e")
			var rope := Color("c8a868")
			_oval(img, 10, 24.5, 8.5, 3.0, Color("6e655a"))   # the shaft's stone lip
			_oval(img, 10, 24.5, 6.5, 2.0, Color("0c0a08"))   # the dark down it
			_px(img, 2, 3, 16, 2, timber)                # the beam
			_px(img, 2, 3, 16, 1, timber_light)
			_px(img, 2, 5, 2, 21, timber)                # the posts
			_px(img, 16, 5, 2, 21, timber)
			_px(img, 2, 5, 1, 21, timber_light)
			_px(img, 4, 9, 12, 4, Color("5a3d22"))       # the drum
			for x in range(5, 15, 2):                    # rope wound round it
				_px(img, x, 9, 1, 4, rope)
			_px(img, 4, 9, 12, 1, Color("8a6a3a"))
			_px(img, 18, 10, 2, 1, Color("3a3430"))      # the crank's arm and grip
			_px(img, 19, 10, 1, 4, Color("3a3430"))
			_px(img, 9, 13, 2, 11, rope)                 # the rope down the shaft
			_px(img, 9, 13, 1, 11, rope.lightened(0.2))
			_px(img, 6, 5, 1, 1, Color("3a3430"))        # the lantern off the beam: its hook,
			_px(img, 5, 6, 3, 1, Color("3a3430"))        # cap,
			_px(img, 5, 7, 3, 2, Color("e8a040"))        # glowing panes
			_px(img, 6, 7, 1, 1, Color("fff4d0"))        # and flame
			return _outline(img)
		"lumber":
			var img := _blank(16, 28)
			var board := Color("d8b07a")
			var bearer := Color("6a4a2a")
			_px(img, 1, 22, 14, 4, bearer)               # the bearers it rests on, off the ground
			for i in 5:                                  # boards, the ends showing, stacked up
				var y := 18 - i * 4
				_px(img, 1 + i % 2, y, 13, 4, board.darkened(0.06 * (i % 2)))
				_px(img, 1 + i % 2, y, 13, 1, board.lightened(0.2))
				_px(img, 1 + i % 2, y + 3, 13, 1, board.darkened(0.25))
			_px(img, 3, 0, 9, 2, Color("b8bcc4"))        # a saw lying on the top board
			_px(img, 11, 0, 4, 2, Color("8a5a32"))
			return _outline(img)
		"door_bell":
			var img := _blank(12, 16)
			var iron := Color("3a3a40")
			var iron_light := Color("6a6e78")
			_px(img, 1, 0, 10, 2, iron)           # the bracket off the eave post
			_px(img, 1, 0, 10, 1, iron_light)
			_px(img, 5, 2, 2, 3, Color("8a6a3a")) # the cord
			_px(img, 4, 5, 4, 2, iron)            # the bell's crown
			_px(img, 3, 7, 6, 3, iron)
			_px(img, 2, 10, 8, 2, iron)
			_px(img, 1, 12, 10, 1, iron)
			_px(img, 4, 6, 1, 5, iron_light)      # the shine down one side
			_px(img, 5, 13, 2, 1, Color("2a2a2e"))   # the clapper
			_px(img, 5, 14, 2, 2, Color("c8442c"))   # a red tassel under it
			return _outline(img)
		"sign_old", "sign_new":
			var img := _blank(48, 14)
			var fresh := kind == "sign_new"
			var board := Color("b8322a") if fresh else Color("4a3424")
			var ink := Color("f4ecd8") if fresh else Color("e8c868")
			_px(img, 0, 0, 48, 14, Color("2e221a"))   # the frame
			_px(img, 1, 1, 46, 12, board)
			_px(img, 1, 1, 46, 1, board.lightened(0.2))
			if fresh:
				# Sayo's brushwork: three loose, flowing marks.
				for i in 3:
					var x := 6 + i * 14
					_line(img, Vector2i(x, 4), Vector2i(x + 6, 3), ink)
					_line(img, Vector2i(x + 3, 3), Vector2i(x + 1, 10), ink)
					_line(img, Vector2i(x + 1, 10), Vector2i(x + 7, 8), ink)
					_px(img, x + 6, 6, 2, 1, ink)
			else:
				# The old name repainted: three square, heavy marks like the father's lettering.
				for i in 3:
					var x := 6 + i * 14
					_px(img, x, 3, 8, 2, ink)
					_px(img, x + 3, 3, 2, 8, ink)
					_px(img, x, 7, 8, 1, ink)
					_px(img, x + (0 if i % 2 == 0 else 6), 9, 2, 2, ink)
			return img
		"ume_jar":
			var img := _blank(12, 12)
			var glaze := Color("8a5030")
			_oval(img, 6, 7.5, 5, 4.2, glaze)                # the jar
			_px(img, 3, 3, 6, 2, Color("e8dcc0"))            # cloth over the mouth
			_px(img, 2, 4, 8, 1, Color("c8442c"))            # tied with red string
			_px(img, 3, 6, 3, 3, glaze.lightened(0.25))      # the glaze's shine
			_px(img, 6, 7, 4, 3, Color("f4f0e0"))            # the note tucked under the string
			_px(img, 7, 8, 2, 1, Color("3a2a1a"))
			return _outline(img)
		"carp_streamer":
			# Kota's streamer on a bamboo pole: the old black carp with its one white spot,
			# mouth tied to the pole, tail out in the wind; a gilt ball on the pole's top.
			var img := _blank(26, 40)
			var bamboo := Color("a89a5a")
			_px(img, 2, 2, 2, 38, bamboo)
			for y in [10, 20, 30]:
				_px(img, 2, y, 2, 1, bamboo.darkened(0.3))   # the nodes
			_oval(img, 3, 1.5, 1.6, 1.4, Color("e8c868"))
			var black := Color("26262c")
			_oval(img, 12, 8, 8, 3.6, black)                  # the body
			_px(img, 4, 5, 2, 7, Color("c8442c"))             # the red mouth ring on the pole
			for i in 3:                                        # the tail fins, forked
				_px(img, 19 + i, 5 - i, 2, 2, black)
				_px(img, 19 + i, 10 + i, 2, 2, black)
			_px(img, 23, 3, 2, 2, black)
			_px(img, 23, 12, 2, 2, black)
			_px(img, 7, 7, 2, 2, Color("f4f0e0"))            # the eye
			_px(img, 8, 8, 1, 1, black)
			_px(img, 14, 6, 3, 2, Color("f4f0e0"))           # the one white spot
			for x in [11, 15, 18]:
				_px(img, x, 10, 2, 1, Color("4a4a56"))       # scales
			return _outline(img)
	return _draw(16, 16, [[0, 0, 16, 16, "ff00ff"]])


## Festival decorations in the flat view (FestivalView), drawn front-on like the 3D props
## (FestivalProps) seen from the south: a point (x, y up, z) of the prop, in cells from the
## middle of its ground, lands at anchor + (x, z - y) * 16 in the picture. So a lantern hung
## 1.6 high sits 26 px above the cell's middle, where FestivalView puts its glow.
const FEST_RED := Color("d8402c")
const FEST_PAPER := Color("f0e6c8")
const FEST_INK := Color("2a2420")
const FEST_WHITE := Color("f4f0e6")
const FEST_WOOD := Color("6a4a30")
const RACE_CLOTH := Color("2a3a6a")    # the fishing race's banner (FestivalView, FestivalProps)
const RACE_MARK := Color("f0ead8")
const RACE_CREEL := Color("b8985a")


## The picture's size for a decoration kind over w x h cells.
static func festival_size(kind: String, w: int, h: int) -> Vector2i:
	match kind:
		"sakura": return Vector2i(34, 44)
		"picnic_mat", "red_mat": return Vector2i(w * 16 - 2, h * 16 - 2)
		"stall": return Vector2i(w * 16 + 8, 44)
		"judge_table": return Vector2i(w * 16 + 8, 40)
		"lantern_line": return Vector2i(w * 16, 36)
		"drum_stage": return Vector2i(w * 16 + 10, 48)
		"moon_table": return Vector2i(18, 22)
		"pampas": return Vector2i(18, 32)
		"paper_lantern": return Vector2i(14, 30)
		"kadomatsu": return Vector2i(18, 28)
		"bonfire": return Vector2i(22, 24)
		"mochi_usu": return Vector2i(32, 24)
		"race_flag": return Vector2i(18, 40)
		"display_goldfish": return Vector2i(34, 14)   # the stall displays that sell nothing (StallWares.DISPLAYS)
		"display_masks": return Vector2i(34, 16)
		"ware_dango", "ware_sakura_mochi", "ware_green_tea", "ware_yakisoba", "ware_shaved_ice", "ware_marble_soda", "ware_wind_chime", "ware_paper_fan", "ware_roast_chestnuts", "ware_baked_imo", "ware_clay_rabbit", "ware_moon_lantern", "ware_year_soba", "ware_yuzu_tea", "ware_daruma", "ware_omamori": return Vector2i(8, 12)   # the wares on a stall counter (StallWares.LOOKS)
	return Vector2i(w * 16, h * 16)


## The pixel in the picture that stands on the middle of the prop's cells.
static func festival_anchor(kind: String, w: int, h: int) -> Vector2i:
	var size := festival_size(kind, w, h)
	match kind:
		"sakura": return Vector2i(17, 36)
		"stall": return Vector2i(size.x / 2, 36)
		"judge_table": return Vector2i(size.x / 2, 32)
		"lantern_line": return Vector2i(size.x / 2, 33)
		"drum_stage": return Vector2i(size.x / 2, 32)
		"moon_table": return Vector2i(9, 15)
		"pampas": return Vector2i(9, 28)
		"paper_lantern": return Vector2i(7, 27)
		"kadomatsu": return Vector2i(9, 25)
		"bonfire": return Vector2i(11, 15)
		"mochi_usu": return Vector2i(16, 20)
		"race_flag": return Vector2i(6, 37)
		"display_goldfish", "display_masks": return Vector2i(size.x / 2, size.y - 1)
		"ware_dango", "ware_sakura_mochi", "ware_green_tea", "ware_yakisoba", "ware_shaved_ice", "ware_marble_soda", "ware_wind_chime", "ware_paper_fan", "ware_roast_chestnuts", "ware_baked_imo", "ware_clay_rabbit", "ware_moon_lantern", "ware_year_soba", "ware_yuzu_tea", "ware_daruma", "ware_omamori": return Vector2i(4, 11)
	return size / 2


static func _festival(kind: String, w: int, h: int, cloth: Color) -> Image:
	if kind == "mochi_usu":   # the mochi pounding's mortar, the dough half pounded
		return _usu(2)
	if kind.begins_with("ware_"):   # one ware on a stall counter
		return _ware(kind.substr(5))
	var size := festival_size(kind, w, h)
	var a := festival_anchor(kind, w, h)
	var img := _blank(size.x, size.y)
	match kind:
		"sakura":
			# A leaning dark trunk, a cloud of pink puffs (lit from the top left), petals below.
			var bark := Color("4a3028")
			for i in 17:
				_px(img, a.x - 1 + i / 8, a.y - i - 1, 3, 1, bark)
			_px(img, a.x - 3, a.y - 1, 7, 1, bark)
			var pinks := [Color("f4b8c8"), Color("eca0b6"), Color("f8d0dc")]
			var puffs := [[0.0, -1.45, 7.0], [0.35, -1.2, 6.5], [-0.32, -1.37, 6.5], [0.1, -1.0, 6.5], [-0.05, -1.8, 5.5]]
			for i in puffs.size():
				var c := Vector2(a.x + puffs[i][0] * 16, a.y + puffs[i][1] * 16)
				_oval(img, c.x, c.y, puffs[i][2], puffs[i][2] * 0.9, (pinks[i % 3] as Color).darkened(0.08))
			for i in puffs.size():
				var c := Vector2(a.x + puffs[i][0] * 16 - 1.5, a.y + puffs[i][1] * 16 - 1.5)
				_oval(img, c.x, c.y, puffs[i][2] * 0.6, puffs[i][2] * 0.5, pinks[i % 3])
			for i in 9:   # blossom spots on the cloud
				_px(img, a.x - 9 + (i * 7) % 19, a.y - 28 + (i * 5) % 15, 1, 1, Color("fff0f4"))
			_outline(img)
			var petal := Color("f6c4d2")
			for i in 12:   # petals on the grass round the trunk (after the outline: no dark edge)
				var ang := i * 2.4
				var d := (0.25 + (i % 4) * 0.17) * 16
				_px(img, int(a.x + cos(ang) * d), int(a.y + sin(ang) * d * 0.4), 1, 1, petal)
			return img
		"picnic_mat", "red_mat":
			# A woven mat, a darker hem, a lunch box with a lid and two teacups.
			var mat := Color("3a6ab0") if kind == "picnic_mat" else Color("b02a24")
			img.fill(mat)
			for y in range(1, size.y, 3):
				_px(img, 0, y, size.x, 1, mat.lightened(0.12))
			_px(img, 0, 0, size.x, 1, mat.darkened(0.3))
			_px(img, 0, size.y - 1, size.x, 1, mat.darkened(0.3))
			_px(img, 0, 0, 1, size.y, mat.darkened(0.3))
			_px(img, size.x - 1, 0, 1, size.y, mat.darkened(0.3))
			var box := Vector2i(a.x - 5, a.y - 2)
			_px(img, box.x - 1, box.y - 1, 8, 7, OUTLINE)
			_px(img, box.x, box.y + 3, 6, 2, Color("2a1a14"))
			_px(img, box.x, box.y, 6, 3, Color("b02a24") if kind == "picnic_mat" else Color("2a1a14"))
			_px(img, box.x + 1, box.y, 4, 1, Color("e8c050"))
			for x in [a.x + 3, a.x + 6]:
				_px(img, x, a.y + 1, 2, 2, Color("e8e0cc"))
				_px(img, x, a.y + 1, 2, 1, Color("6a8a5a"))   # green tea
			return img
		"stall":
			# A plank counter on four posts, a sloping roof and a short curtain in its cloth,
			# a red lantern at the front corner (the 3D stall's lamp).
			var ww := roundi((w - 0.2) * 16)
			var x0 := a.x - ww / 2
			for x in [x0, x0 + ww - 1]:
				_px(img, x, a.y - 30, 1, 24, FEST_WOOD.darkened(0.2))   # back posts
				_px(img, x, a.y - 19, 1, 24, FEST_WOOD)                 # front posts
			var planks := Color("9a7048")
			_px(img, x0, a.y - 18, ww, 10, planks.lightened(0.1))      # the counter top
			for y in [a.y - 15, a.y - 11]:
				_px(img, x0, y, ww, 1, planks.darkened(0.1))
			_px(img, x0 - 1, a.y - 8, ww + 2, 1, Color("8a6a48"))
			_px(img, x0, a.y - 7, ww, 10, planks)                       # its front, boards
			for y in [a.y - 4, a.y]:
				_px(img, x0, y, ww, 1, planks.darkened(0.25))
			_px(img, x0 + 7, a.y - 7, 1, 10, planks.darkened(0.25))
			_px(img, x0 + ww - 9, a.y - 7, 1, 10, planks.darkened(0.25))
			# The roof, lower at the front: its slope in bands, the eave darker.
			for i in 14:
				var c := cloth.lightened(0.15) if i < 5 else (cloth if i < 11 else cloth.darkened(0.2))
				_px(img, x0 - 3, a.y - 33 + i, ww + 6, 1, c)
			for x in range(x0, x0 + ww, 6):
				_px(img, x, a.y - 33, 1, 11, cloth.darkened(0.12))
			var curtain := cloth.lerp(Color.WHITE, 0.25)
			_px(img, x0, a.y - 19, ww, 5, curtain)
			for x in range(x0 + 4, x0 + ww - 1, 5):
				_px(img, x, a.y - 17, 1, 3, curtain.darkened(0.25))   # the slits
			_outline(img)
			_lamp(img, Vector2i(a.x + roundi((w - 0.2) * 8), a.y - 13), FEST_RED, 2)
			return img
		"judge_table":
			# A low table under a white cloth, a red and white curtain along the front, the name
			# board on two posts behind it and three ribbon rosettes waiting for the winners.
			var ww := roundi((w - 0.15) * 16)
			var x0 := a.x - ww / 2
			for x in [x0 + 1, x0 + ww - 2]:
				_px(img, x, a.y - 26, 1, 22, FEST_WOOD)
			_px(img, x0 + 1, a.y - 26, ww - 2, 5, Color("e8dcc0"))
			_px(img, x0 + 4, a.y - 24, ww - 8, 1, FEST_INK)             # the brushed name
			_px(img, x0 + 4, a.y - 23, 3, 1, FEST_INK)
			_px(img, x0 + ww - 9, a.y - 23, 4, 1, FEST_INK)
			_px(img, x0, a.y - 14, ww, 9, FEST_WHITE)                   # the cloth on top
			_px(img, x0, a.y - 14, ww, 1, Color.WHITE)
			var n := ww / 4
			for i in n:                                                 # the striped curtain
				_px(img, x0 + i * ww / n, a.y - 5, ww / n + 1, 9, FEST_RED if i % 2 == 0 else FEST_WHITE.darkened(0.05))
			_outline(img)
			for i in 3:
				_rosette(img, a.x + (i - 1) * 7, a.y - 11, [FEST_RED, FEST_WHITE, Color("2c4a8a")][i], true)
			return img
		"lantern_line":
			# A pole at each end, a sagging rope and a lantern every cell, red and white in turn.
			var pole := Color("5a4030")
			_px(img, 1, a.y - 30, 2, 31, pole)
			_px(img, size.x - 3, a.y - 30, 2, 31, pole)
			for x in range(2, size.x - 2):
				var sag := roundi(sin(PI * fposmod(x - 8.0, 16.0) / 16.0))
				_px(img, x, a.y - 29 + sag, 1, 1, FEST_INK)
			_outline(img)
			for i in w:
				_lamp(img, Vector2i(i * 16 + 8, a.y - 26), FEST_RED if i % 2 == 0 else FEST_PAPER, 3)
			return img
		"drum_stage":
			# A plank platform on legs with red and white cloth round it, a big drum on top.
			var hw := 14
			for x in [a.x - 13, a.x + 11]:
				_px(img, x, a.y + 6, 2, 8, Color("5a3a24"))
			var deck := Color("9a7048")
			_px(img, a.x - hw, a.y - 30, hw * 2, 30, deck)
			for y in range(a.y - 27, a.y, 4):
				_px(img, a.x - hw, y, hw * 2, 1, deck.darkened(0.2))
			for i in 6:
				_px(img, a.x - hw + i * hw * 2 / 6, a.y, hw * 2 / 6 + 1, 7, FEST_RED if i % 2 == 0 else FEST_WHITE)
			var drum := Vector2i(a.x, a.y - 21)
			_px(img, drum.x - 7, drum.y + 5, 14, 2, Color("3a2418"))    # its stand
			_oval(img, drum.x, drum.y, 7, 6, Color("8a4a2a"))           # the body, lying on its side
			_oval(img, drum.x + 3, drum.y - 1, 4, 5, Color("e8dcc0"))   # the head, turned to the corner
			for i in 5:
				_px(img, drum.x - 5 + i * 2, drum.y - 5 + (i % 2), 1, 1, Color("e8c050"))   # tacks
			_outline(img)
			return img
		"moon_table":
			# A small white wooden stand with a pyramid of round dango.
			_px(img, a.x - 5, a.y - 10, 10, 10, Color("e8dcc0"))
			_px(img, a.x - 4, a.y, 8, 4, Color("d8c8a0"))
			_px(img, a.x - 4, a.y + 1, 8, 1, Color("c0b088"))
			var dango := Color("f8f4ea")
			for row in 3:
				var n := 3 - row
				for i in n:
					_oval(img, a.x - (n - 1) * 1.6 + i * 3.2, a.y - 6 - row * 2.6, 1.6, 1.6, dango)
			_outline(img)
			return img
		"pampas":
			# Pampas grass in a tall blue-grey vase: grey stalks, pale silver plumes.
			for i in 5:
				_line(img, Vector2i(a.x, a.y - 7), Vector2i(a.x + (i - 2) * 3, a.y - 19 + absi(i - 2)), Color("8a8a6a"))
			for i in 5:
				var tip := Vector2(a.x + (i - 2) * 3.6, a.y - 22 + absi(i - 2))
				_oval(img, tip.x, tip.y, 1.4, 3.2, Color("e4dcc4"))
				_px(img, int(tip.x), int(tip.y) - 2, 1, 2, Color("f8f4ea"))
			_px(img, a.x - 2, a.y - 7, 4, 1, Color("6a7a8a"))
			_px(img, a.x - 2, a.y - 6, 5, 6, Color("4a5a6a"))
			_px(img, a.x - 1, a.y - 5, 1, 4, Color("6a7a8a"))
			_outline(img)
			return img
		"race_flag":
			# The fishing race's start: a bamboo pole with a tall indigo banner (a white fish on
			# it) hung from a crossbar, and the race's creel at its foot.
			var pole := Color("b89a5a")
			_px(img, a.x - 1, a.y - 34, 2, 35, pole)
			_px(img, a.x - 1, a.y - 34, 1, 35, pole.lightened(0.2))
			_px(img, a.x, a.y - 33, 11, 1, pole)
			_px(img, a.x - 3, a.y, 6, 1, pole.darkened(0.35))
			_px(img, a.x + 1, a.y - 32, 9, 22, RACE_CLOTH)
			_px(img, a.x + 1, a.y - 32, 9, 2, RACE_CLOTH.lightened(0.25))   # the hem at the top
			_px(img, a.x + 9, a.y - 30, 1, 20, RACE_CLOTH.darkened(0.25))
			_oval(img, a.x + 5.5, a.y - 21.5, 2.2, 4.5, RACE_MARK)          # the fish, nose up
			_px(img, a.x + 4, a.y - 16, 3, 1, RACE_MARK)                     # its tail
			_px(img, a.x + 3, a.y - 15, 1, 1, RACE_MARK)
			_px(img, a.x + 7, a.y - 15, 1, 1, RACE_MARK)
			_px(img, a.x + 4, a.y - 6, 7, 6, RACE_CREEL)                     # the creel
			_px(img, a.x + 4, a.y - 6, 7, 1, RACE_CREEL.lightened(0.2))
			for y in [a.y - 4, a.y - 2]:
				_px(img, a.x + 4, y, 7, 1, RACE_CREEL.darkened(0.25))       # its weave
			_outline(img)
			return img
		"display_goldfish":
			# A round wooden tub of water with three goldfish, two paper scoops (poi) lying beside it.
			var tub := Color("8a6a44")
			_oval(img, 11, 7, 11, 6, tub.darkened(0.25))
			_oval(img, 11, 7, 10, 5, tub)
			_oval(img, 11, 6.5, 9, 4, Color("7fb4cc"))
			_oval(img, 10, 6, 5, 2, Color("a4d0e0"))
			for f in [[6, 6], [12, 8], [15, 5]]:   # the fish: an orange body, a tail, a white fleck
				_px(img, f[0], f[1], 3, 2, Color("f08a2a"))
				_px(img, f[0] - 1, f[1], 1, 1, Color("e86a20"))
				_px(img, f[0] + 1, f[1], 1, 1, Color("f8c890"))
			for x in [24, 29]:   # the scoops: a white paper ring on a stick
				_oval(img, x + 1, 9, 2.8, 2.2, Color("e8e0cc"))
				_oval(img, x + 1, 9, 1.6, 1.2, Color("c8d8e0"))
				_px(img, x + 3, 10, 3, 1, Color("c8a06a"))
			_outline(img)
			return img
		"display_masks":
			# Two tiers of festival masks on a wooden stand: a white fox with red marks, a red demon,
			# a white round-faced one with red cheeks, a rabbit, a brown tanuki.
			var wood := Color("8a6a44")
			_px(img, 1, 14, 32, 2, wood)
			_px(img, 1, 14, 32, 1, wood.lightened(0.15))
			_px(img, 2, 8, 30, 2, wood.darkened(0.1))
			var white := Color("f4f0e4")
			for k in 4:   # the back tier
				var x := 5 + k * 8
				match k:
					0:   # fox
						_px(img, x - 2, 0, 2, 3, white)
						_px(img, x + 2, 0, 2, 3, white)
						_oval(img, x + 0.5, 4.5, 3.5, 3.5, white)
						_px(img, x - 3, 4, 2, 1, Color("c8282c"))
						_px(img, x + 3, 4, 2, 1, Color("c8282c"))
						_px(img, x, 6, 1, 1, FEST_INK)
					1:   # demon
						_px(img, x - 2, 0, 1, 2, white)
						_px(img, x + 3, 0, 1, 2, white)
						_oval(img, x + 0.5, 4.5, 3.5, 3.5, Color("c8282c"))
						_px(img, x - 2, 3, 5, 1, FEST_INK)
						_px(img, x - 1, 6, 1, 1, white)
						_px(img, x + 2, 6, 1, 1, white)
					2:   # round white face, red cheeks, black hair
						_oval(img, x + 0.5, 4.5, 3.7, 3.7, white)
						_px(img, x - 3, 1, 8, 2, FEST_INK)
						_px(img, x - 2, 5, 1, 1, Color("e86a78"))
						_px(img, x + 3, 5, 1, 1, Color("e86a78"))
						_px(img, x, 6, 1, 1, Color("c8282c"))
					_:   # rabbit
						_px(img, x - 1, 0, 1, 3, white)
						_px(img, x + 2, 0, 1, 3, white)
						_oval(img, x + 0.5, 5, 3.2, 3.2, white)
						_px(img, x - 1, 4, 1, 1, Color("c8282c"))
						_px(img, x + 2, 4, 1, 1, Color("c8282c"))
			for k in 3:   # the front tier
				var x := 9 + k * 8
				if k == 1:   # tanuki
					_oval(img, x + 0.5, 11.5, 3.2, 2.6, Color("7a5a3c"))
					_px(img, x - 2, 11, 2, 1, FEST_INK)
					_px(img, x + 2, 11, 2, 1, FEST_INK)
				else:
					_oval(img, x + 0.5, 11.5, 3.2, 2.6, white)
					_px(img, x - 2, 11, 1, 1, Color("c8282c"))
					_px(img, x + 2, 11, 1, 1, Color("c8282c"))
					_px(img, x, 13, 1, 1, FEST_INK)
			_outline(img)
			return img
		"paper_lantern":
			# A standing paper lantern on a short pole.
			_px(img, a.x - 1, a.y - 17, 2, 18, FEST_INK)
			_px(img, a.x - 2, a.y, 4, 1, FEST_INK)
			_outline(img)
			_lamp(img, Vector2i(a.x, a.y - 20), FEST_PAPER, 4)
			return img
		"kadomatsu":
			# Three cut bamboo stalks in a straw-bound base, pine sprigs round them.
			var bamboo := Color("5a9a48")
			for s in [[-1, 22], [-3, 16], [2, 13]]:
				var x: int = a.x + s[0]
				var top: int = a.y - s[1]
				_px(img, x, top, 2, s[1] - 4, bamboo)
				_px(img, x, top, 1, s[1] - 4, bamboo.lightened(0.2))
				_px(img, x, top, 2, 1, Color("d8e8b0"))       # the slanted cut
				_px(img, x + 1, top - 1, 1, 1, Color("d8e8b0"))
				_px(img, x, top + 6, 2, 1, bamboo.darkened(0.25))   # a node
			var pine := Color("2f5a34")
			for dx in [-6, 4]:
				for k in 3:
					_px(img, a.x + dx + k % 2, a.y - 9 + k, 4 - k, 1, pine)
			_px(img, a.x - 4, a.y - 7, 8, 7, Color("c8a868"))           # the straw base
			for y in [a.y - 5, a.y - 2]:
				_px(img, a.x - 4, y, 8, 1, Color("6a4a2a"))              # its rope bands
			_outline(img)
			return img
		"bonfire":
			# A ring of stones, crossed logs and the flame.
			var stone := Color("7a766e")
			for i in 8:
				var ang := i * TAU / 8
				_px(img, roundi(a.x + cos(ang) * 6) - 1, roundi(a.y + sin(ang) * 5) - 1, 3, 2, stone if i % 2 == 0 else stone.darkened(0.15))
			_line(img, Vector2i(a.x - 5, a.y + 2), Vector2i(a.x + 5, a.y - 2), Color("4a3020"))
			_line(img, Vector2i(a.x - 5, a.y - 2), Vector2i(a.x + 5, a.y + 2), Color("4a3020"))
			for y in 10:   # the flame, a cone narrowing upwards
				var half := 3.5 * (1.0 - y / 10.0)
				_px(img, roundi(a.x - half), a.y - 1 - y, maxi(1, roundi(half * 2)), 1, Color("ffb040"))
			for y in 6:
				var half := 1.8 * (1.0 - y / 6.0)
				_px(img, roundi(a.x - half), a.y - 1 - y, maxi(1, roundi(half * 2)), 1, Color("fff0a0"))
			_outline(img)
			return img
	img.fill(Color.MAGENTA)
	return img


## One paper lantern hung with its middle at `at`: a round ribbed body, dark caps, outlined.
## `half` is half its width.
static func _lamp(img: Image, at: Vector2i, color: Color, half: int) -> void:
	_px(img, at.x - half - 1, at.y - half - 2, half * 2 + 3, half * 2 + 5, OUTLINE)
	_px(img, at.x - half, at.y - half, half * 2 + 1, half * 2 + 1, color)
	_px(img, at.x - half + 1, at.y - half - 1, half * 2 - 1, 1, color)
	_px(img, at.x - half + 1, at.y + half + 1, half * 2 - 1, 1, color)
	for y in range(at.y - half + 1, at.y + half, 2):
		_px(img, at.x - half, y, half * 2 + 1, 1, color.darkened(0.12))   # the ribs
	_px(img, at.x - half + 1, at.y - half, 1, half * 2, color.lightened(0.3))
	_px(img, at.x - half + 1, at.y - half - 2, half * 2 - 1, 1, FEST_INK)
	_px(img, at.x - half + 1, at.y + half + 2, half * 2 - 1, 1, FEST_INK)


# --- the village record scroll (EndingScreen) ----------------------------------------------

const SCROLL_WASHI := Color("f6ead0")
const SCROLL_STAR := ["...X...", "..XXX..", "XXXXXXX", ".XXXXX.", "..XXX..", ".XX.XX.", ".X...X."]


## The record's paper scroll: a 32 x 32 washi tile (seamless, long pale fibres and specks), a
## roller (roller_<w>: a rod <w> px long with a knob each end, 10 px tall, w + 12 wide),
## the 7 x 7 ink-stamp star (on: vermilion with thin ink spots; off: a faint unstamped star),
## the 14 x 14 red seal (a sprout carved out of a square, our own mark) and a 3 x 5 arrow
## that points from the first day's number to today's.
static func _scroll_art(kind: String) -> Image:
	if kind.begins_with("roller_"):
		return _scroll_roller(int(kind.trim_prefix("roller_")))
	match kind:
		"washi":
			var img := _blank(32, 32)
			img.fill(SCROLL_WASHI)
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			for i in 16:   # fibres: short wavy strands, wrapped so the tile repeats
				var c := Color("fcf5e4") if i % 2 == 0 else Color("eee2c4")
				var x := rng.randi_range(0, 31)
				var y := rng.randi_range(0, 31)
				for k in rng.randi_range(3, 7):
					img.set_pixel(posmod(x + k, 32), posmod(y, 32), c)
					if rng.randf() < 0.3:
						y += 1 if rng.randf() < 0.5 else -1
			for i in 10:   # specks of bark in the pulp
				img.set_pixel(rng.randi_range(0, 31), rng.randi_range(0, 31), Color("e2d1aa"))
			return img
		"star_on", "star_off":
			var img := _blank(7, 7)
			var on := kind == "star_on"
			for y in 7:
				for x in 7:
					if SCROLL_STAR[y][x] == "X":
						img.set_pixel(x, y, UI_SEAL if on else Color("e2d0a4"))
			if on:   # the stamp took the ink unevenly
				for p in [Vector2i(3, 2), Vector2i(4, 3), Vector2i(1, 2)]:
					img.set_pixelv(p, Color("dc6a4c"))
			return img
		"seal":
			var img := _blank(14, 14)
			var light := Color("f6dccc")
			_px(img, 0, 0, 14, 14, UI_SEAL)
			for p in [Vector2i(0, 0), Vector2i(13, 0), Vector2i(0, 13), Vector2i(13, 13)]:
				img.set_pixelv(p, Color(0, 0, 0, 0))
			for r in [[2, 2, 10, 1], [2, 11, 10, 1], [2, 2, 1, 10], [11, 2, 1, 10]]:
				_px(img, r[0], r[1], r[2], r[3], light)   # the carved border
			_px(img, 6, 5, 1, 5, light)                   # the sprout's stem
			for p in [Vector2i(4, 4), Vector2i(5, 4), Vector2i(4, 5), Vector2i(5, 6),
					Vector2i(8, 4), Vector2i(9, 4), Vector2i(9, 5), Vector2i(7, 6), Vector2i(8, 5)]:
				img.set_pixelv(p, light)                  # its two leaves
			_px(img, 4, 9, 6, 1, light)                   # the ground
			for p in [Vector2i(2, 6), Vector2i(11, 9), Vector2i(7, 11), Vector2i(1, 12)]:
				img.set_pixelv(p, Color("d86a50"))        # worn spots where the ink was thin
			return img
		"arrow":
			var img := _blank(3, 5)
			for p in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2), Vector2i(1, 3), Vector2i(0, 4)]:
				img.set_pixelv(p, Color("a08a68"))
			return img
	return _draw(16, 16, [[0, 0, 16, 16, "ff00ff"]])


## A wooden roller: the rod (lit from above, a few grain dashes), brass collars and a dark
## lacquered knob at each end.
static func _scroll_roller(rod: int) -> Image:
	var w := rod + 12
	var img := _blank(w, 10)
	var edge := Color("3a2416")
	_px(img, 6, 1, rod, 8, edge)
	_px(img, 6, 2, rod, 1, Color("c89058"))
	_px(img, 6, 3, rod, 2, UI_WOOD_LIGHT)
	_px(img, 6, 5, rod, 2, UI_WOOD)
	_px(img, 6, 7, rod, 1, UI_WOOD_DARK)
	for x in range(14, rod, 23):
		_px(img, 6 + x, 4, 4, 1, UI_WOOD)
		_px(img, 6 + x + 9, 6, 3, 1, UI_WOOD_DARK)
	for x0 in [0, w - 6]:
		_px(img, x0, 0, 6, 10, edge)
		_px(img, x0 + 1, 1, 4, 8, Color("4a2414"))
		_px(img, x0 + 1, 1, 4, 1, Color("8a4a2a"))
		_px(img, x0 + 2, 2, 1, 2, Color("b06a40"))
		for p in [Vector2i(x0, 0), Vector2i(x0 + 5, 0), Vector2i(x0, 9), Vector2i(x0 + 5, 9)]:
			img.set_pixelv(p, Color(0, 0, 0, 0))
	for x in [6, w - 8]:
		_px(img, x, 1, 2, 8, Color("c8962a"))
		_px(img, x, 2, 2, 1, Color("e8c050"))
		_px(img, x, 1, 2, 1, edge)
		_px(img, x, 8, 2, 1, edge)
	return img


# --- the mochi pounding (MochiScreen; the mortar also stands in FestivalView) -------

const MOCHI_WOOD := Color("9a6a3a")
const MOCHI_WOOD_DARK := Color("6a4428")
const MOCHI_HOOP := Color("3e2c20")
const MOCHI_DOUGH := Color("f8f4ea")
const MOCHI_DOUGH_SHADE := Color("e2d8c4")


## The picture of one ware `name` (the item id after its colon, StallWares.LOOKS) as it stands on a
## stall's counter in the flat view: 8 x 12, the counter row at the bottom, steam puffs in the top
## rows over the hot ones (StallWares.STEAMING). Pixel-drawn from the same look as the 3D meshes.
static func _ware(name: String) -> Image:
	var img := _blank(8, 12)
	var wood := Color("a8845a")
	var dark := Color("6a4a30")
	var white := Color("ece4d4")
	var red := Color("a82a20")
	var ink := Color("2e2a28")
	match name:
		"dango":   # three skewers of pink, white and green dumplings on a tray
			_px(img, 0, 11, 8, 1, wood)
			for x in [1, 5]:
				_px(img, x + 1, 5, 1, 6, wood.lightened(0.2))
				_px(img, x, 4, 2, 2, Color("e88aa0"))
				_px(img, x, 6, 2, 2, white)
				_px(img, x, 8, 2, 2, Color("8ab05a"))
		"sakura_mochi":   # pink rice cakes wrapped in leaves on a plate
			_px(img, 0, 11, 8, 1, white)
			for x in [0, 4]:
				_oval(img, x + 2, 9, 2.1, 1.8, Color("f0a8b8"))
				_px(img, x + 1, 9, 3, 1, Color("5a8a3c"))
		"green_tea":   # a pot with a spout and a cup, steaming
			_px(img, 0, 6, 5, 5, Color("5a7a5c"))
			_px(img, 1, 5, 3, 1, Color("5a7a5c"))
			_px(img, 5, 7, 2, 1, Color("5a7a5c"))
			_px(img, 5, 9, 3, 2, white)
			_px(img, 5, 9, 3, 1, Color("8ab05a"))
		"yakisoba":   # noodles heaped on an iron griddle
			_px(img, 0, 10, 8, 2, ink)
			_oval(img, 4, 8, 3.6, 2.4, Color("d8a850"))
			_px(img, 2, 7, 1, 1, Color("5a8a3c"))
			_px(img, 5, 8, 1, 1, Color("c84a30"))
		"shaved_ice":   # a footed glass with a mound of ice and a little flag
			_px(img, 3, 10, 2, 2, Color("b8d8e4"))
			_px(img, 1, 6, 6, 4, Color("b8d8e4"))
			_oval(img, 4, 5, 3.2, 2, Color("f4f8fa"))
			_px(img, 4, 2, 1, 3, wood)
			_px(img, 5, 2, 2, 1, red)
		"marble_soda":   # blue bottles standing in a tub of water
			_px(img, 0, 9, 8, 3, dark)
			_px(img, 0, 9, 8, 1, Color("7fb4cc"))
			for x in [1, 5]:
				_px(img, x, 4, 2, 5, Color("6ab8d8"))
				_px(img, x, 2, 1, 2, Color("6ab8d8"))
		"wind_chime":   # a glass bell and paper strips hanging from a stand
			_px(img, 0, 1, 8, 1, dark)
			_px(img, 1, 1, 1, 10, dark)
			_px(img, 3, 2, 3, 3, Color("b8d8e4"))
			_px(img, 4, 5, 1, 2, ink)
			_px(img, 3, 7, 3, 3, Color("f0b8c8"))
		"paper_fan":   # round paper fans stood in a block
			_px(img, 1, 10, 6, 2, wood)
			_oval(img, 2.5, 6, 2.4, 3, Color("e8d8b0"))
			_oval(img, 5.5, 6, 2.4, 3, Color("d8503a"))
			_px(img, 2, 8, 1, 3, dark)
			_px(img, 5, 8, 1, 3, dark)
		"roast_chestnuts":   # chestnuts in a pan on a brazier
			_px(img, 1, 10, 6, 2, ink)
			_px(img, 0, 8, 8, 2, ink)
			for x in [1, 3, 5]:
				_oval(img, x + 1, 7.4, 1.4, 1.5, Color("7a4a2a"))
		"baked_imo":   # sweet potatoes on hot stones
			_px(img, 0, 10, 8, 2, Color("5a5450"))
			_oval(img, 2.5, 8.5, 2.5, 1.5, Color("8a3a4a"))
			_oval(img, 5.5, 8.2, 2.4, 1.5, Color("a04a50"))
		"clay_rabbit":   # little clay rabbits on a cloth
			_px(img, 0, 11, 8, 1, Color("a84a3a"))
			for x in [0, 4]:
				_px(img, x + 1, 5, 1, 3, Color("d8c0a0"))
				_px(img, x + 2, 5, 1, 2, Color("d8c0a0"))
				_oval(img, x + 2, 9, 2.1, 1.9, Color("d8c0a0"))
				_px(img, x + 1, 8, 1, 1, red)
		"moon_lantern":   # a round moon lantern, warm inside
			_px(img, 3, 1, 2, 2, dark)
			_oval(img, 4, 7, 3.5, 3.6, Color("f0d890"))
			_px(img, 0, 11, 8, 1, dark)
			_px(img, 3, 6, 2, 3, Color("fff0b0"))
		"year_soba":   # a bowl of year-end soba, steaming, with a stack of bowls
			_px(img, 0, 8, 5, 4, red)
			_px(img, 0, 7, 5, 1, Color("c8b890"))
			_px(img, 5, 5, 3, 7, Color("2a1a14"))
			_px(img, 5, 7, 3, 1, red)
			_px(img, 5, 9, 3, 1, red)
		"yuzu_tea":   # a cup of yuzu tea with a yellow fruit
			_px(img, 0, 8, 4, 4, white)
			_px(img, 0, 8, 4, 1, Color("e8c040"))
			_oval(img, 6, 10, 1.9, 1.9, Color("e8c040"))
		"daruma":   # red daruma dolls with white faces
			for x in [0, 4]:
				_oval(img, x + 2, 8, 2.4, 3.4, red)
				_oval(img, x + 2, 7, 1.6, 1.4, white)
				_px(img, x + 1, 7, 1, 1, ink)
				_px(img, x + 3, 7, 1, 1, ink)
		"omamori":   # charms on a little rack
			_px(img, 0, 1, 8, 1, dark)
			_px(img, 0, 1, 1, 10, dark)
			_px(img, 7, 1, 1, 10, dark)
			for x in [2, 4]:
				_px(img, x, 2, 2, 5, [Color("c8282c"), Color("d8a830")][(x / 2) % 2])
				_px(img, x, 5, 2, 1, white)
	if name in ["green_tea", "yakisoba", "roast_chestnuts", "baked_imo", "year_soba", "yuzu_tea"]:
		for p in [Vector2i(3, 0), Vector2i(4, 1), Vector2i(3, 2), Vector2i(5, 0)]:
			if name == "yakisoba" or name == "roast_chestnuts" or name == "baked_imo":
				p.y += 3
			_px(img, p.x, p.y, 1, 1, Color(1, 1, 1, 0.6))
	return img

## The usu (32 x 24): a stout cut log, hollowed on top, two dark hoops round it, with the
## dough in the bowl. `dough` 0 is steamed rice (lumpy, grains showing), 3 a smooth shiny mound.
static func _usu(dough: int) -> Image:
	var img := _blank(32, 24)
	_px(img, 3, 7, 26, 15, MOCHI_WOOD)
	_px(img, 5, 12, 22, 6, MOCHI_WOOD.darkened(0.08))   # the waist, a shade darker
	_oval(img, 16, 21.5, 13, 2.5, MOCHI_WOOD_DARK)        # the foot
	for y in [9, 18]:
		_px(img, 3, y, 26, 2, MOCHI_HOOP)
	for x in [8, 15, 23]:
		_px(img, x, 12, 1, 5, MOCHI_WOOD_DARK)             # grain lines
	_oval(img, 16, 6, 14, 4.5, MOCHI_WOOD.lightened(0.15))   # the cut top
	_oval(img, 16, 6, 11, 3.2, MOCHI_WOOD_DARK)            # the bowl
	var d := clampi(dough, 0, 3)
	var rise: float = [0.0, 0.5, 1.2, 2.2][d]
	_oval(img, 16, 6 - rise * 0.5, 9 - (1 if d == 0 else 0), 2.4 + rise, MOCHI_DOUGH_SHADE)
	_oval(img, 16, 5.5 - rise * 0.6, 8 - (1 if d == 0 else 0), 1.8 + rise * 0.8, MOCHI_DOUGH)
	if d == 0:   # grains of rice still showing
		for g in [Vector2i(10, 5), Vector2i(13, 6), Vector2i(17, 4), Vector2i(20, 6), Vector2i(15, 7), Vector2i(22, 5)]:
			_px(img, g.x, g.y, 1, 1, MOCHI_DOUGH_SHADE)
	elif d == 3:   # the shine of finished mochi
		_px(img, 12, int(4 - rise * 0.6), 3, 1, Color.WHITE)
	return _outline(img)


## Goldfish tones per look (GoldfishScoop `look`): body base, fin / patch base. Each is toned in
## three (lit from the upper left, so the upper edge of the fish is lit) with a darker rim.
## The black look is a dark blue-grey, not near black, so it shows against the tub's water (value
## about 0.72, WATER in ScoopScreen); its fins are pale and its back edge and eye ring are lit.
const SCOOP_FISH := [[Color("f06a2a"), Color("f8b070")], [Color("f4ece0"), Color("e0482a")], [Color("4a5668"), Color("b8c4d4")]]
const SCOOP_FISH_SIZE := Vector2i(20, 10)


## The key of goldfish `look` (clamped to the looks there are).
static func scoop_fish_key(look: int) -> String:
	return "scoop:fish:%d" % clampi(look, 0, SCOOP_FISH.size() - 1)


static func _scoop_fish(look: int) -> Image:
	var tones: Array = SCOOP_FISH[clampi(look, 0, SCOOP_FISH.size() - 1)]
	var body: Color = tones[0]
	var fin: Color = tones[1]
	var img := _blank(SCOOP_FISH_SIZE.x, SCOOP_FISH_SIZE.y)
	# The tail: a fan behind the body, thin and pale.
	for pt in [[0, 1, 3], [1, 2, 4], [2, 3, 5], [3, 4, 3]]:
		_px(img, pt[0], pt[1], 1, pt[2] + (2 if pt[0] == 0 else 0), fin.darkened(0.12))
	_px(img, 1, 3, 5, 4, fin)
	_px(img, 1, 3, 4, 1, fin.lightened(0.18))
	# The side fins, one each side of the body.
	_px(img, 8, 0, 3, 2, fin.darkened(0.08))
	_px(img, 8, 8, 3, 2, fin.darkened(0.22))
	# The body: deep tone, then base, then the lit upper edge.
	_oval(img, 12, 5, 7, 3.3, body.darkened(0.3))
	_oval(img, 12, 4.6, 6.4, 2.7, body)
	# The black look (2) lifts its back edge further and rings its eyes pale, so its shape shows.
	_oval(img, 11.4, 3.6, 4.6, 1.2, body.lightened(0.4 if look == 2 else 0.22))
	# The eye and a patch.
	_px(img, 16, 3, 1, 1, Color("14181c"))
	_px(img, 16, 6, 1, 1, Color("14181c"))
	if look == 2:
		for eye in [Vector2i(16, 3), Vector2i(16, 6)]:
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var p: Vector2i = eye + Vector2i(dx, dy)
					if (dx != 0 or dy != 0) and img.get_pixel(p.x, p.y).a > 0.0:
						img.set_pixel(p.x, p.y, Color("dfe6ee"))
	_px(img, 9, 3, 3, 2, fin)
	_px(img, 9, 3, 2, 1, fin.lightened(0.18))
	# A darker rim instead of a black outline.
	var rim := body.darkened(0.5)
	var keep := img.duplicate()
	for y in img.get_height():
		for x in img.get_width():
			if keep.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < img.get_width() and n.y < img.get_height() and keep.get_pixel(n.x, n.y).a > 0.0:
					img.set_pixel(x, y, Color(rim, 0.85))
					break
	return img


## The kine (16 x 28): a wooden mallet standing up, a barrel head on a long handle whose end
## (the hands, KINE_GRIP) is at the bottom. MochiScreen swings it round that end.
const KINE_GRIP := Vector2(8, 27)


static func _kine() -> Image:
	var img := _blank(16, 28)
	_px(img, 7, 8, 2, 20, Color("c8a06a"))
	_px(img, 7, 8, 1, 20, Color("dab47c"))
	_px(img, 1, 1, 14, 8, MOCHI_WOOD)
	_px(img, 1, 1, 14, 1, MOCHI_WOOD.lightened(0.2))
	_px(img, 1, 1, 2, 8, MOCHI_WOOD_DARK)    # the end grain at either side
	_px(img, 13, 1, 2, 8, MOCHI_WOOD_DARK)
	_px(img, 1, 4, 14, 1, MOCHI_HOOP)
	return _outline(img)
