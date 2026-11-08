class_name FigureArt
extends RefCounted
## The farmer and the villagers as 24 x 32 pixel figures, our own designs in Japanese country
## clothes (HD-2D lite: chunky figures about 2.6 heads tall). Drawn in code part by part, back
## to front; every part gets its own 1 px dark outline, so a near arm or leg reads against the
## body behind it. Placeholders until real art replaces the keys (PlaceholderArt "player:..."
## and "villager:...").
##
## Directions: the camera looks along a diagonal, so walking along a grid axis is a screen
## diagonal. "front" is turned three-quarters towards the lower left (Down), "back" three-quarters
## towards the upper left (Left); mirrored they serve Right and Up: four directions from two
## drawings. Seen from the front the figure's left side (screen right) is the near one; from the
## back its left side is on the screen's left.
##
## Light from the upper left: each part's right side is a shade darker, its upper left a little
## lighter. The figure's feet stand on the bottom row; the 3D view shows a sprite pixel as
## FarmWorld.FIGURE_PX world units.

const W := 24
const H := 32
const FOOT := 30          # the last row of the feet's fill (the outline is the bottom row)
const OUTLINE := Color("2a1e1e")
const EYE := Color("2a2a3a")
const ROD := Color("c8a85a")            # the farmer's bamboo rod
const ROD_NODE := Color("8a6a32")
const VILLAGER_ROD := Color("7a5a32")   # a villager's (darker, older) rod
const HAMMER_WOOD := Color("a07a4a")
const HAMMER_IRON := Color("5a5e66")
const MORSEL := Color("f4ecd8")
const CUP := Color("d8c8a8")
const CUP_TEA := Color("7aa848")
const SWEAT := Color("9fd8f2")
const BASKET := Color("d9b45a")          # the farmer's straw hip basket (koshi-kago)
const LETTER := Color("f4f0e4")          # a letter in the post pose
const POLE := Color("b89a68")            # the ferry pole in the pole pose (the 3D boat's pole)

const STYLES: Array[String] = ["bun", "short", "headband", "long", "straw_hat", "tenugui"]
const OUTFITS: Array[String] = ["kimono", "happi", "shirt_shorts", "noragi"]
const BUILDS_LIST: Array[String] = ["adult", "elder", "child"]

## Body plans: the head's centre and radii, the shoulder and hip rows, the torso's half widths
## from the body's middle column (12) and the head's lean. An elder stoops (the head a pixel
## forward and lower); a child is shorter, with a big head on a small body.
const BUILDS := {
	"adult": {"cx": 12.0, "cy": 9.0, "rx": 5.0, "ry": 5.2, "sh": 15, "hip": 23, "left": 4, "right": 3},
	"elder": {"cx": 11.0, "cy": 10.0, "rx": 5.0, "ry": 5.0, "sh": 16, "hip": 23, "left": 4, "right": 3},
	"child": {"cx": 12.0, "cy": 14.0, "rx": 4.6, "ry": 4.6, "sh": 19, "hip": 25, "left": 3, "right": 3},
}

## The farmer's own look: an indigo noragi (work jacket) with a white collar band and a straw
## rope belt, slate monpe trousers, dark jika-tabi, a red tenugui tied round the head.
const FARMER_LOOK := {
	"outfit": "noragi", "hair_style": "tenugui", "build": "adult", "hair": "5a3a22", "skin": "f2c79b",
	"top": "3e64b4", "waist": "e8e2d0", "lower": "4a4e5a", "accent": "c8452c", "shoes": "34343e",
}

## Per pose, per frame: [body drop, near leg x shift, near leg lift, far leg x shift, far leg
## lift, near hand x shift, far hand x shift]. Negative x = the way the figure faces (left).
## Walk / run cycles go contact, pass, contact, pass: on contact the legs are spread with the
## opposite arm forward and the body a pixel lower; on a pass one foot is lifted under the body.
const POSES := {
	"idle": [[0, 0, 0, 0, 0, 0, 0]],
	"walk": [[1, -2, 0, 2, 0, 2, -2], [0, 0, 0, 0, 2, 0, 0], [1, 2, 0, -2, 0, -2, 2], [0, 0, 2, 0, 0, 0, 0]],
	"run": [[1, -3, 0, 3, 0, 3, -3], [0, 0, 0, 0, 3, 0, 0], [1, 3, 0, -3, 0, -3, 3], [0, 0, 3, 0, 0, 0, 0]],
	# Tired: slumped, the head hung forward; slow heavy breaths standing, short dragging steps.
	"tired_idle": [[1, 0, 0, 0, 0, 0, 0], [2, 0, 0, 0, 0, 0, 0]],
	"tired_walk": [[2, -1, 0, 1, 0, 1, -1], [1, 0, 0, 0, 1, 0, 0], [2, 1, 0, -1, 0, -1, 1], [1, 0, 1, 0, 0, 0, 0]],
	# Holding: both arms up beside the head steadying the item overhead; shorter, careful steps,
	# the load bobbing with the body.
	"hold_idle": [[0, 0, 0, 0, 0, 0, 0]],
	"hold_walk": [[1, -2, 0, 2, 0, 0, 0], [0, 0, 0, 0, 2, 0, 0], [1, 2, 0, -2, 0, 0, 0], [0, 0, 2, 0, 0, 0, 0]],
	# Fishing: both hands together in front on the rod butt; waiting the rod stands up still, on
	# a bite the farmer leans in and the tip jerks down.
	"fish_wait": [[0, 0, 0, 0, 0, 0, 0]],
	"fish_bite": [[1, -1, 0, 1, 0, 0, 0], [1, -1, 0, 1, 0, 0, 0]],
	# Eating / drinking: standing, the near hand up at the mouth (MOUTH); eating bites, then chews
	# with the hand lowered a little; drinking tips the cup up on the sip.
	"eat": [[0, 0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0, 0]],
	"drink": [[0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0]],
	# A villager's hammer (0 = raised over the shoulder, 1 = the blow, dipping into it) and rod.
	"work": [[0, 0, 0, 0, 0, 0, 0], [1, -1, 0, 1, 0, 0, 0]],
	"fish": [[0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0]],
	# A villager putting a letter in at a door (Ren's round): the near hand up in front with the
	# letter (0), then pushed a pixel further as it slips in (1).
	"post": [[0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0]],
	# A villager poling a boat (Mio's ferry): both hands on a long pole planted at the front
	# (screen left) down into the water, high on it (0), then pushing down on it, the body
	# dipping a pixel (1).
	"pole": [[0, 0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0, 0]],
}
## Per eat / drink frame: [hand offset from the mouth, what it holds: "bite" (a morsel at the
## lips), "chew" (the bitten rest), "cup" (upright at the lips), "tip" (tipped up)].
const MOUTH := {
	"eat": [[Vector2i(0, 1), "bite"], [Vector2i(1, 3), "chew"]],
	"drink": [[Vector2i(0, 2), "cup"], [Vector2i(0, 0), "tip"]],
}
## The farmer's rod tip per fishing frame (sprite pixels; the line starts here), and a villager's.
const ROD_TIPS := {"fish_wait": [Vector2i(1, 2)], "fish_bite": [Vector2i(0, 12), Vector2i(0, 10)]}
const VILLAGER_ROD_TIPS: Array[Vector2i] = [Vector2i(1, 4), Vector2i(1, 7)]


static func frames(pose: String) -> int:
	return POSES[pose].size()


static func row(pose: String, frame: int) -> Array:
	var rows: Array = POSES.get(pose, POSES.idle)
	return rows[frame % rows.size()]


static func rod_tip(pose: String, frame: int) -> Vector2i:
	var tips: Array = ROD_TIPS.get(pose, [Vector2i(1, 2)])
	return tips[frame % tips.size()]


## The body plan of a look ("build": adult / elder / child; unknown or missing: adult).
static func plan(look: Dictionary) -> Dictionary:
	return BUILDS.get(str(look.get("build", "adult")), BUILDS.adult)


## The top row of the head (hair included, a hat's crown not) for a look, standing.
static func head_top(look: Dictionary) -> int:
	var b := plan(look)
	return floori(b.cy - b.ry)


## Where the hands are on a frame: {"near": top-left of the near hand's 2 x 2, "far": the far's}.
static func hands(look: Dictionary, back: bool, pose: String, frame: int) -> Dictionary:
	var r := _rig(look, pose, frame)
	return _hands(r, back, pose, frame)


## The row the held item rests on (just above the raised hands) on a hold frame.
static func hold_row(pose: String, frame: int) -> int:
	return hands(FARMER_LOOK, false, pose, frame).near.y + 1


## Where the mine lantern (7 x 11, its loop at x 3) hangs: from the near hand, swinging with it;
## with the arms up holding something or both hands on the rod, at the near hip instead.
static func lantern_at(pose: String, frame: int, back := false) -> Vector2i:
	var r := _rig(FARMER_LOOK, pose, frame)
	if pose.begins_with("hold") or ROD_TIPS.has(pose):
		return Vector2i(3 if back else 14, r.hip - 3)
	var h: Vector2i = _hands(r, back, pose, frame).near
	return Vector2i(h.x - 2, mini(h.y - 2, H - 11))   # held a little higher rather than in the ground


## The figure for a look, side, pose and frame. `farmer` adds the farmer's own pieces (the hip
## basket, sweat when tired, the bamboo rod); a villager's fish pose has their own rod and line.
static func draw(look: Dictionary, back: bool, pose: String, frame: int, farmer := false) -> Image:
	var img := _blank()
	var c := colors(look)
	var r := _rig(look, pose, frame)
	var p := row(pose, frame)
	var style := str(look.get("hair_style", "short"))
	var outfit := str(look.get("outfit", "happi"))
	var hd := _hands(r, back, pose, frame)
	var tired := pose.begins_with("tired")
	var hold := pose.begins_with("hold")
	var rod := ROD_TIPS.has(pose) or pose == "fish"
	var poling := pose == "pole"
	var mouth: Array = MOUTH[pose][frame % frames(pose)] if MOUTH.has(pose) else []
	var sleeve := "wide" if outfit == "kimono" else ("short" if outfit == "shirt_shorts" else "narrow")
	# Screen-left / -right shoulders (the top-left of each sleeve's first row).
	var sh_l := Vector2i(r.x0 - 3 if not back else r.x0 - 2, r.sh + 1)
	var sh_r := Vector2i(r.x1 - 1 if not back else r.x1 + 1, r.sh + 1)
	var near_sh := sh_l if back else sh_r
	var far_sh := sh_r if back else sh_l

	if style == "long" and not back:
		_long_hair_behind(img, r, c)
	# The far arm, behind the body (rod and work poses draw it after, both hands in front).
	if not rod and not poling:
		_arm(img, far_sh, hd.far, c, sleeve, hold)
	# Legs: far first, then near. From the front the far leg is on the left, from the back on the right.
	var far_x: int = (r.bx + 1 if back else r.bx - 3) + p[3]
	var near_x: int = (r.bx - 3 if back else r.bx + 1) + p[1]
	for leg in [[far_x, p[4]], [near_x, p[2]]]:
		_leg(img, r, c, outfit, leg[0], leg[1])
	_torso(img, r, c, outfit, back, farmer)
	if style == "long" and back:
		_long_hair_down_back(img, r, c)
	if farmer:
		_basket(img, r, back)
	if look.has("bag"):   # a shoulder bag: the strap across the body, the bag at the far hip
		_bag(img, r, back, Color(str(look.bag)))
	if rod:   # both arms reach forward to the rod butt in front (screen left)
		var tip: Vector2i = rod_tip(pose, frame) if farmer else VILLAGER_ROD_TIPS[frame % 2]
		_arm(img, far_sh, hd.far, c, sleeve, false)
		_rod(img, hd.near + Vector2i(1, 1), tip, farmer)
		if not farmer:   # the line hangs from the tip
			for y in range(tip.y + 1, H - 1):
				_dot(img, tip.x, y, Color(0.92, 0.92, 0.86, 0.85))
	if poling:   # the pole from over the head down past the feet, both hands on it
		_pole(img, r, frame % 2 == 1)
		_arm(img, far_sh, hd.far, c, sleeve, false)
	_head(img, r, c, style, back, tired)
	if hold:
		_arm(img, near_sh, hd.near, c, sleeve, true)
	elif not mouth.is_empty():
		var at: Vector2i = hd.near
		var what: String = mouth[1] if not back else ""
		_arm(img, near_sh, at, c, sleeve, false, what)
	elif pose == "post":
		_arm(img, near_sh, hd.near, c, sleeve, false)
		_letter(img, hd.near, frame % 2 == 1)
	elif pose == "work":
		_hammer(img, hd.near, frame % 2 == 0, back)
		_arm(img, near_sh, hd.near, c, sleeve, frame % 2 == 0)
	else:
		_arm(img, near_sh, hd.near, c, sleeve, false)
	if tired and farmer:   # a drop of sweat by the brow: before the face, or behind the head
		var sx := roundi(r.cx) + (6 if back else -7)
		var sy := roundi(r.cy) - 3
		_dot(img, sx, sy, Color.WHITE)
		_r(img, sx, sy + 1, 1, 2, SWEAT)
	return img


## The look's colours with their shades: o outline, e eye, h hair, s skin, t top, w waist (obi,
## sash, collar band), l lower (trousers, shorts), a accent (hat, headband, hairpin), k shoes;
## capitals are a shade darker, `<key>+` a little lighter.
static func colors(look: Dictionary) -> Dictionary:
	var pick := func(k: String, fallback: String) -> Color:
		return Color(str(look.get(k, fallback)))
	var c := {"o": OUTLINE, "e": EYE, "h": pick.call("hair", "2a2422"), "s": pick.call("skin", "f2c79b"),
		"a": pick.call("accent", "e0c070"), "t": pick.call("top", "6a7a8a"), "w": pick.call("waist", "c8a050"),
		"l": pick.call("lower", "3a3430"), "k": pick.call("shoes", "6b4423")}
	for k in ["h", "s", "a", "t", "w", "l", "k"]:
		c[k.to_upper()] = (c[k] as Color).darkened(0.25)
		c[k + "+"] = (c[k] as Color).lightened(0.18)
	return c


# --- the rig -------------------------------------------------------------------------------

## Rows and columns of a frame: the body plan moved by the frame's drop; running and tired
## figures hang the head forward.
static func _rig(look: Dictionary, pose: String, frame: int) -> Dictionary:
	var b := plan(look)
	var p := row(pose, frame)
	var d: int = p[0]
	var tired := pose.begins_with("tired")
	var lean := -1.0 if pose == "run" or tired or pose == "fish_bite" else 0.0
	var bx := 12
	return {"bx": bx, "cx": float(b.cx) + lean, "cy": float(b.cy) + d + (1.0 if tired else 0.0),
		"rx": float(b.rx), "ry": float(b.ry), "sh": int(b.sh) + d, "hip": int(b.hip) + d,
		"x0": bx - int(b.left), "x1": bx + int(b.right), "tired": tired, "child": int(b.sh) > 17}


## The hands' top-left pixels. Hanging: at the hip, swung by the pose; tired a pixel lower.
static func _hands(r: Dictionary, back: bool, pose: String, frame: int) -> Dictionary:
	var p := row(pose, frame)
	var down: int = r.hip - 1 + (1 if r.tired else 0)
	var near := Vector2i((r.x0 - 2 if back else r.x1) + p[5], down)
	var far := Vector2i((r.x1 + 2 if back else r.x0 - 3) + p[6], down)
	var top := floori(r.cy - r.ry)
	if pose.begins_with("hold"):   # up beside the head, at its top
		near = Vector2i(r.x0 - 3 if back else r.x1 + 1, top - 1)
		far = Vector2i(r.x1 + 1 if back else r.x0 - 3, top - 1)
	elif ROD_TIPS.has(pose) or pose == "fish":   # together in front on the rod butt
		near = Vector2i(r.x0 - 1, r.hip - 4)
		far = Vector2i(r.x0 - 3, r.hip - 5)
	elif MOUTH.has(pose):   # the near hand at the mouth (from the back, at the cheek)
		var m: Vector2i = MOUTH[pose][frame % frames(pose)][0]
		var mouth := Vector2i(roundi(r.cx) - (6 if back else 4), roundi(r.cy) + 3)
		near = mouth + m
	elif pose == "pole":   # on the pole in front: the near hand high, the far one at the waist
		var pushed := frame % 2
		near = _on_pole(r, r.sh - 3 + 2 * pushed)
		far = _on_pole(r, r.hip - 3 + pushed)
	elif pose == "post":   # up in front at the chest (from the back, up at the shoulder, toward the door)
		near = Vector2i(r.x0 - 3 - frame % 2, r.sh + (-2 if back else 1) - frame % 2)
	elif pose == "work":
		if frame % 2 == 0:   # raised over the near shoulder
			near = Vector2i(r.x0 - 3 if back else r.x1 + 2, r.sh - 4)
		else:   # the blow, out in front at the waist
			near = Vector2i(r.x0 - 3, r.hip - 4)
	return {"near": near, "far": far}


# --- parts ---------------------------------------------------------------------------------

## One leg (trousers, shorts or under a robe only the foot): 3 px wide from the hips to the
## ground, `lift` px shorter when the foot is off the ground; the shoe a toe longer forward.
static func _leg(dst: Image, r: Dictionary, c: Dictionary, outfit: String, x: int, lift: int) -> void:
	var L := _blank()
	var bottom := FOOT - lift
	if outfit == "kimono":   # short steps under the robe: white tabi and a zori show
		var y := FOOT - mini(lift, 1)
		_r(L, x, y - 1, 3, 1, Color("f0ece0"))
		_r(L, x - 1, y, 4, 1, c.k)
		_stamp(dst, L)
		return
	var top: int = r.hip - 1
	var shin: Color = c.s if outfit == "shirt_shorts" else c.l
	var shin_dark: Color = c.S if outfit == "shirt_shorts" else c.L
	_r(L, x, top, 3, bottom - top - 1, shin)
	_r(L, x + 2, top, 1, bottom - top - 1, shin_dark)
	if outfit == "noragi":   # monpe gathered at the ankle
		_r(L, x, bottom - 3, 3, 1, shin_dark)
	_r(L, x - 1, bottom - 1, 4, 2, c.k)
	_r(L, x + 2, bottom - 1, 1, 1, c.K)
	_dot(L, x - 1, bottom, c.K)
	_stamp(dst, L)


## The body's garment from the shoulders down.
static func _torso(dst: Image, r: Dictionary, c: Dictionary, outfit: String, back: bool, farmer: bool) -> void:
	var L := _blank()
	var x0: int = r.x0
	var x1: int = r.x1
	var sh: int = r.sh
	var hip: int = r.hip
	var bx: int = r.bx
	var w := x1 - x0 + 1
	var hem := hip + 1
	match outfit:
		"kimono":
			hem = FOOT - 2
		"shirt_shorts":
			hem = hip - 2
	_r(L, x0 + 1, sh, w - 2, 1, c.t)   # rounded shoulders
	_r(L, x0, sh + 1, w, hem - sh, c.t)
	_r(L, x1 - 1, sh + 1, 2, hem - sh, c.T)   # the side away from the light
	_r(L, x0, sh + 1, 1, 3, c["t+"])
	# The neck.
	if not back:
		_r(L, bx - 1, sh - 1, 2, 1, c.S)
	match outfit:
		"kimono":
			if back:   # the obi round the waist and its drum bow (otaiko) on the back
				_r(L, x0, hip - 4, w, 4, c.w)
				_r(L, x0, hip - 1, w, 1, c.W)
				_r(L, bx - 2, sh, 4, 1, c.T)   # the collar's back, standing off the nape
			else:
				_r(L, bx - 2, sh, 4, 1, Color("f4f0e6"))   # the white under-collar: a V
				_r(L, bx - 1, sh + 1, 2, 1, Color("f4f0e6"))
				_dot(L, bx - 3, sh + 1, c.T)
				_dot(L, bx + 1, sh + 2, c.T)
				_r(L, x0, hip - 4, w, 4, c.w)   # the obi, a cord across its middle
				_r(L, x0, hip - 1, w, 1, c.W)
				_r(L, x0, hip - 3, w, 1, c.a)
				for y in range(hip, hem + 1):   # the front panel's edge, left over right
					_dot(L, bx - 2 + (y - hip) / 3, y, c.T)
			_r(L, x0, hem, w, 1, c.T)
		"happi", "noragi":
			var band: Color = c.w
			if back:
				_r(L, bx - 2, sh, 4, 1, band)   # the collar band round the back of the neck
				if outfit == "happi":   # a round family crest (mon) between the shoulders
					_r(L, bx - 1, sh + 2, 2, 1, band)
					_r(L, bx - 2, sh + 3, 1, 2, band)
					_r(L, bx + 1, sh + 3, 1, 2, band)
					_r(L, bx - 1, sh + 5, 2, 1, band)
			else:   # the collar band from the neck down the front edge to the hem
				_r(L, bx - 3, sh, 2, 1, band)
				_r(L, bx + 1, sh, 1, 1, band)
				_r(L, bx - 1, sh, 2, 2, c.s if outfit == "happi" else Color("f4f0e6"))
				for y in range(sh + 1, hem + 1):
					_r(L, bx - 3 + mini((y - sh) / 2, 1), y, 2, 1, band)
				_r(L, bx - 2, sh + 1, 1, 1, band)
			if outfit == "noragi":   # kasuri flecks in the indigo, a straw rope belt
				for y in range(sh + 2, hem):
					for x in range(x0 + 1, x1 - 1):
						if (x * 3 + y * 5) % 11 == 0 and not (x >= bx - 3 and x <= bx - 1):
							_dot(L, x, y, c["t+"])
				for x in range(x0, x1 + 1):
					_dot(L, x, hip - 2, BASKET if x % 2 == 0 else BASKET.darkened(0.3))
			else:
				_r(L, x0, hip - 2, w, 1, c.W)   # the sash
			_r(L, x0, hem, w, 1, c.T)
		"shirt_shorts":
			if not back:
				_r(L, bx - 1, sh, 2, 1, c.s)   # a round neck
			_r(L, x0, hem, w, 1, c.T)
			var shorts_top := hem + 1
			_r(L, x0, shorts_top, w, hip + 2 - shorts_top, c.l)
			_r(L, x1 - 1, shorts_top, 2, hip + 2 - shorts_top, c.L)
			_dot(L, bx, hip + 1, c.L)   # between the legs
	_stamp(dst, L)
	if outfit == "kimono" and back:   # the obi's drum bow (otaiko) standing off the back
		var bow := _blank()
		_r(bow, bx - 3, hip - 6, 6, 6, c.w)
		_r(bow, bx - 3, hip - 6, 6, 1, c["w+"])
		_r(bow, bx + 1, hip - 5, 2, 5, c.W)
		_r(bow, bx - 3, hip - 4, 6, 1, c.a)   # the cord through it
		_stamp(dst, bow)


## A sleeve from shoulder `s` (top-left of its first row) to the hand at `hand` (a 2 x 2), the
## hand last so its fingers close over what it holds (`what`, see MOUTH). Raised (`up`), the
## sleeve runs from the shoulder up to just under the hand.
static func _arm(dst: Image, s: Vector2i, hand: Vector2i, c: Dictionary, sleeve: String, up: bool, what := "") -> void:
	var L := _blank()
	var wide := 4 if sleeve == "wide" else 3
	# The sleeve: a wide x 2 brush along the line from the shoulder to just short of the hand.
	var end := hand + Vector2i(0, 1 if up or hand.y < s.y else -1)
	var n := maxi(absi(end.x - s.x), absi(end.y - s.y))
	for i in n + 1:
		var q := Vector2(s).lerp(Vector2(end), float(i) / maxi(n, 1)).round()
		var col: Color = c.t
		var dark: Color = c.T
		if sleeve == "short" and i > mini(1, n / 3):   # a short sleeve, then the bare arm
			col = c.s
			dark = c.S
		_r(L, int(q.x), int(q.y), wide, 2, col)
		_r(L, int(q.x) + wide - 1, int(q.y), 1, 2, dark)
	if sleeve == "wide" and not up and hand.y > s.y + 3:   # a kimono sleeve hangs below the arm
		var bx := roundi(lerpf(s.x, hand.x, 0.6)) + 1
		_r(L, bx, s.y + 3, 3, hand.y - s.y - 1, c.t)
		_r(L, bx + 2, s.y + 3, 1, hand.y - s.y - 1, c.T)
	match what:   # what the hand at the mouth holds, under the fingers
		"bite":
			_r(L, hand.x - 1, hand.y - 2, 2, 2, MORSEL)
		"chew":
			_r(L, hand.x - 1, hand.y - 1, 1, 1, MORSEL)
		"cup":
			_r(L, hand.x - 1, hand.y - 3, 3, 1, CUP_TEA)
			_r(L, hand.x - 1, hand.y - 2, 3, 3, CUP)
		"tip":
			_r(L, hand.x - 2, hand.y - 2, 4, 2, CUP)
			_dot(L, hand.x - 2, hand.y - 2, CUP_TEA)
	_r(L, hand.x, hand.y, 2, 2, c.s)
	_dot(L, hand.x + 1, hand.y + 1, c.S)
	_stamp(dst, L)


## The head: a skin oval, the hair by style over it, the face (from the front) or the back of the
## head with a sliver of cheek; hats and bands on top.
static func _head(dst: Image, r: Dictionary, c: Dictionary, style: String, back: bool, tired: bool) -> void:
	var L := _blank()
	var cx: float = r.cx
	var cy: float = r.cy
	var rx: float = r.rx
	var ry: float = r.ry
	var top := floori(cy - ry)
	var icx := roundi(cx)
	var icy := floori(cy)
	_oval(L, cx, cy, rx, ry, c.s)
	# Hair: the crown and, from the front, the back of the head (screen right); from the back all
	# but the near cheek and the nape.
	for y in range(top - 1, ceili(cy + ry) + 1):
		for x in range(floori(cx - rx) - 1, ceili(cx + rx) + 1):
			if not _inside(x, y) or L.get_pixel(x, y).a == 0.0:
				continue
			var fx := x + 0.5 - cx
			var fy := y + 0.5 - cy
			var hair := false
			if back:
				hair = not (fx < -3.0 and fy > -0.5 and fy < 3.0) and not (absf(fx) < 1.6 and fy > 3.2)
			else:
				hair = fy < -1.6 or (fx > 1.5 and fy < 2.6) or (fy < -0.6 and (x + y) % 2 == 0 and fx < 1.5)
			if hair:
				_dot(L, x, y, c.h)
	# Hair shading: lighter up on the left, darker low on the right.
	for y in range(top, icy + 4):
		for x in range(floori(cx - rx), ceili(cx + rx)):
			if _inside(x, y) and _same(L.get_pixel(x, y), c.h):
				var fx := x + 0.5 - cx
				var fy := y + 0.5 - cy
				if fx + fy < -5.5:
					_dot(L, x, y, c["h+"])
				elif fx + fy > 3.0 or fx > 3.4:
					_dot(L, x, y, c.H)
	if not back:   # the face, turned towards the lower left
		var ey := icy
		for ex in [icx - 4, icx - 1]:
			if tired:   # heavy lids
				_dot(L, ex, ey, c.S)
				_dot(L, ex, ey + 1, c.e)
			else:
				_r(L, ex, ey, 1, 2, c.e)
		_dot(L, icx - 1, ey + 2, c.s.lerp(Color("e87060"), 0.35))   # a little colour in the cheek
		_dot(L, icx - 3, ey + 3, c.S)   # the mouth
		_dot(L, icx + 2, ey + 1, c.S)   # the ear
		_dot(L, icx + 2, ey, c.s)
		_r(L, icx, ey + 3, 2, 1, c.S)   # the jaw's shade
	else:
		_dot(L, icx - 5, icy + 1, c.S)   # the near ear's edge
	match style:
		"short":
			for x in [icx - 2, icx + 1, icx + 3]:
				_dot(L, x, top - 1, c.h)
		"bun", "long":
			_r(L, icx - 2, top - 1, 4, 1, c.h)
			if style == "bun":   # the knot on the crown, a hairpin through it
				var bxc := cx + (0.5 if back else 2.0)
				_oval(L, bxc, top - 1.0, 2.4, 2.0, c.h)
				_dot(L, roundi(bxc) - 1, top - 2, c["h+"])
				_dot(L, roundi(bxc) + 2, top - 3, c.a)
				_dot(L, roundi(bxc) + 3, top - 4, c.a)
			elif not back:   # a side lock framing the face
				_r(L, floori(cx - rx), icy - 1, 1, 5, c.h)
				_dot(L, floori(cx - rx) + 1, icy - 1, c.h)
		"headband", "tenugui":
			var band: Color = c.a
			var rows := 2 if style == "tenugui" else 1
			for x in range(floori(cx - rx), ceili(cx + rx) + 1):
				for i in rows:
					if _inside(x, icy - 3 + i) and L.get_pixel(x, icy - 3 + i).a > 0.0:
						_dot(L, x, icy - 3 + i, band if (style == "headband" or (x + i) % 3 != 0) else c["a+"])
			_dot(L, icx - 1, top - 1, c.h)
			_dot(L, icx + 2, top - 1, c.h)
			if back:   # the knot round at the back right, its ends hanging off the head
				_r(L, icx + 2, icy - 4, 2, 2 + rows, band)
				_r(L, icx + 4, icy - 3 + rows, 1, 3, band)
				_r(L, icx + 5, icy - 2 + rows, 1, 2, c.A)
			else:   # the knot behind the head, the ends flying out
				_r(L, ceili(cx + rx), icy - 3, 2, rows, band)
				_r(L, ceili(cx + rx) + 1, icy - 3 + rows, 1, 2, c.A)
				_dot(L, ceili(cx + rx) + 2, icy - 2 + rows, band)
	_stamp(dst, L)
	if style == "straw_hat":
		_hat(dst, cx, top, c)


## A wide straw hat: a domed crown with a band, a brim wider than the shoulders.
static func _hat(dst: Image, cx: float, top: int, c: Dictionary) -> void:
	var L := _blank()
	var brim := top + 2
	_oval(L, cx, brim - 0.5, 3.6, 3.2, c.a)
	_r(L, 0, brim, W, 4, Color(0, 0, 0, 0))   # only the dome above the brim
	_r(L, roundi(cx) - 7, brim, 14, 2, c.a)
	_r(L, roundi(cx) - 7, brim + 1, 14, 1, c.A)
	_r(L, roundi(cx) - 3, brim - 1, 7, 1, Color("8e2c1c"))   # the band
	for x in range(roundi(cx) - 6, roundi(cx) + 7, 3):   # the weave
		_dot(L, x, brim, c["a+"])
	_dot(L, roundi(cx) - 2, brim - 3, c["a+"])
	_stamp(dst, L)


## Long hair hanging behind the shoulders (seen from the front, on the far side), tied low.
static func _long_hair_behind(dst: Image, r: Dictionary, c: Dictionary) -> void:
	var L := _blank()
	var icx := roundi(r.cx)
	_r(L, icx + 1, roundi(r.cy), 5, r.sh + 6 - roundi(r.cy), c.h)
	_r(L, icx + 4, roundi(r.cy) + 2, 2, r.sh + 4 - roundi(r.cy), c.H)
	_r(L, icx + 2, r.sh + 1, 3, 1, c.a)   # the tie
	_stamp(dst, L)


## Long hair down the back over the clothes, tied at the nape.
static func _long_hair_down_back(dst: Image, r: Dictionary, c: Dictionary) -> void:
	var L := _blank()
	var icx := roundi(r.cx)
	_r(L, icx - 2, roundi(r.cy) + 2, 5, r.sh + 6 - roundi(r.cy) - 2, c.h)
	_r(L, icx + 1, roundi(r.cy) + 2, 2, r.sh + 6 - roundi(r.cy) - 2, c.H)
	_r(L, icx - 1, r.sh + 6, 3, 1, c.h)
	_r(L, icx - 2, r.sh, 5, 1, c.a)   # the tie
	_stamp(dst, L)


## The farmer's straw hip basket (koshi-kago) at the near hip.
static func _basket(dst: Image, r: Dictionary, back: bool) -> void:
	var L := _blank()
	var x: int = r.x0 - 2 if back else r.x1 + 1
	var y: int = r.hip - 3
	_r(L, x, y, 4, 4, BASKET)
	_r(L, x, y, 4, 1, BASKET.lightened(0.2))
	for i in 4:
		_dot(L, x + i, y + 1 + i % 2 + 1, BASKET.darkened(0.3))
	_r(L, x + 1, y - 2, 2, 1, BASKET.darkened(0.4))   # the cord to the belt
	_dot(L, x + (3 if back else 0), y - 1, BASKET.darkened(0.4))
	_stamp(dst, L)


## A canvas shoulder bag (a mailbag): its strap from the near shoulder down across the body to
## the bag hanging at the far hip, a flap with a buckle. From the back the strap crosses the
## other way and the bag hangs on the screen's right.
static func _bag(dst: Image, r: Dictionary, back: bool, col: Color) -> void:
	var L := _blank()
	var strap := col.darkened(0.35)
	var x: int = r.x1 if back else r.x0 - 4
	var y: int = r.hip - 4
	var top := Vector2i(r.x0 + 1 if back else r.x1 - 1, r.sh)
	var foot := Vector2i(x + 2, y)
	var n := maxi(absi(foot.x - top.x), absi(foot.y - top.y))
	for i in n + 1:
		var p := Vector2(top).lerp(Vector2(foot), float(i) / n)
		_dot(L, roundi(p.x), roundi(p.y), strap)
	_r(L, x, y, 5, 4, col)
	_r(L, x, y + 3, 5, 1, col.darkened(0.2))
	_r(L, x, y, 5, 2, col.lightened(0.15))          # the flap
	_dot(L, x + 2, y + 1, Color("c8a050"))           # its buckle
	_stamp(dst, L)


## The ferry pole's x at row `y`: a straight line leaning from its top over the near shoulder
## in front (screen left) down to the water below the feet.
static func _pole_x(r: Dictionary, y: int) -> int:
	var top := Vector2(r.x0 - 1, 0)
	var foot := Vector2(r.x0 - 6, H - 1)
	return roundi(lerpf(top.x, foot.x, float(y) / float(H - 1)))


## A hand's top-left on the pole at row `y`.
static func _on_pole(r: Dictionary, y: int) -> Vector2i:
	return Vector2i(_pole_x(r, y) - 1, y)


## The ferry pole down the figure's front, from the top edge to the bottom; pushed, its top is
## lower by two pixels (driven into the river bed).
static func _pole(dst: Image, r: Dictionary, pushed: bool) -> void:
	for y in range(2 if pushed else 0, H):
		_dot(dst, _pole_x(r, y), y, POLE if y % 7 != 3 else POLE.darkened(0.3))


## The letter in the post pose, held at `hand` (the hand's top-left): a pale envelope above
## the fingers, or only its end once `slipped` in at the door.
static func _letter(dst: Image, hand: Vector2i, slipped: bool) -> void:
	var w := 2 if slipped else 4
	_r(dst, hand.x - (1 if slipped else 2), hand.y - 2, w, 2, LETTER)
	_r(dst, hand.x - (1 if slipped else 2), hand.y - 1, w, 1, LETTER.darkened(0.15))


## A bamboo rod from the hands (`butt`) up to its tip, a node every few px (the farmer's), or a
## villager's plain darker pole.
static func _rod(dst: Image, butt: Vector2i, tip: Vector2i, farmer: bool) -> void:
	var col := ROD if farmer else VILLAGER_ROD
	var n := maxi(absi(tip.x - butt.x), absi(tip.y - butt.y))
	for i in n + 1:
		var q := Vector2(butt).lerp(Vector2(tip), float(i) / maxi(n, 1)).round()
		_dot(dst, int(q.x), int(q.y), col)
	if farmer:
		for t in [0.3, 0.6]:
			var q := Vector2(butt).lerp(Vector2(tip), t).round()
			_dot(dst, int(q.x), int(q.y), ROD_NODE)


## A carpenter's hammer in the near hand: raised up past the head, or brought down in front.
static func _hammer(dst: Image, hand: Vector2i, raised: bool, back: bool) -> void:
	var L := _blank()
	if raised:   # the handle up from the fist, the iron head across its top
		var x := hand.x + (0 if back else 1)
		_r(L, x, hand.y - 6, 1, 6, HAMMER_WOOD)
		_r(L, x - 2, hand.y - 8, 5, 2, HAMMER_IRON)
		_dot(L, x - 2, hand.y - 8, HAMMER_IRON.lightened(0.25))
	else:   # the blow: the handle out in front, the head turned down on the work
		_r(L, hand.x - 3, hand.y + 1, 3, 1, HAMMER_WOOD)
		_r(L, hand.x - 5, hand.y - 1, 2, 4, HAMMER_IRON)
		_dot(L, hand.x - 5, hand.y - 1, HAMMER_IRON.lightened(0.25))
	_stamp(dst, L)


# --- painting helpers -----------------------------------------------------------------------

static func _blank() -> Image:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var rect := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, W, H))
	if rect.has_area():
		img.fill_rect(rect, c)


static func _dot(img: Image, x: int, y: int, c: Color) -> void:
	if _inside(x, y):
		img.set_pixel(x, y, c)


## Filled ellipse, tested at pixel centres.
static func _oval(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(floori(cy - ry), ceili(cy + ry) + 1):
		for x in range(floori(cx - rx), ceili(cx + rx) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_dot(img, x, y, c)


## Lays part `layer` over `dst`: first a 1 px outline round the part's silhouette (4 neighbours),
## then the part itself.
static func _stamp(dst: Image, layer: Image, outline := true) -> void:
	var used := layer.get_used_rect()
	if not used.has_area():
		return
	if outline:
		var g := used.grow(1).intersection(Rect2i(0, 0, W, H))
		for y in range(g.position.y, g.end.y):
			for x in range(g.position.x, g.end.x):
				if layer.get_pixel(x, y).a > 0.0:
					continue
				if _solid(layer, x - 1, y) or _solid(layer, x + 1, y) or _solid(layer, x, y - 1) or _solid(layer, x, y + 1):
					dst.set_pixel(x, y, OUTLINE)
	dst.blend_rect(layer, used, used.position)


static func _same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.01


static func _solid(img: Image, x: int, y: int) -> bool:
	return _inside(x, y) and img.get_pixel(x, y).a > 0.0
