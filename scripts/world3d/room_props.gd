class_name RoomProps
extends RefCounted
## The furniture of every room in 3D (the farmhouse, the villagers' homes, the shops, the
## clinic, the smithy) as real meshes: tapered blocks (FarmProps.block) with bevelled tops and
## lathe-turned pots, jars and bales (Shrine.lathe), all in lit materials so the room's light
## shapes them like the walls. Only what gives off light stays unshaded: the andon's paper,
## embers, the forge's fire, a candle flame (GLOWS). Same units as MapWorld: 1 unit = 1 cell;
## things that stand against the back wall sit towards -z (its face is at z 1.0).

const KINDS: Array[String] = ["futon", "low_table", "tansu", "andon", "kamado", "mizuya",
	"nagamochi", "kotatsu", "counter", "shelf", "rice_sacks", "forge", "anvil", "tool_rack",
	"water_tub", "irori", "tokonoma", "butsudan", "zabuton", "byobu", "toy_box", "mizugame"]

const TIMBER := Color("2e221a")
const IRON := Color("26221f")
const WOOD := Color("8a5a34")       # turned and small wooden things (lathe parts carry no UVs)
const STRAW := Color("d8c088")
const ROPE := Color("8a6a3a")
const PAPER := Color("ece4cc")
const LACQUER := Color("1a1616")
const GOLD := Color("c8a040")
const STONE := Color("7a746c")
# The unshaded colours: what gives off light.
const LAMP := Color("ffe6a8")
const EMBER := Color("e8742a")
const FIRE := Color("ff8a30")
const FLAME := Color("ffd060")
const GLOWS: Array[Color] = [LAMP, EMBER, FIRE, FLAME]


## A room prop by its kind (MapWorld calls this for the KINDS).
static func prop(w: FarmWorld, p: Dictionary, mid: Vector3, r: Rect2) -> void:
	var parts := FarmProps.Parts.new()
	match str(p.kind):
		"futon": _futon(parts, r)
		"low_table": _low_table(parts, mid)
		"tansu": _tansu(parts, mid)
		"andon": _andon(parts, mid)
		"kamado": _kamado(parts, mid)
		"mizuya": _mizuya(parts, mid)
		"nagamochi": _nagamochi(parts, mid)
		"kotatsu": _kotatsu(parts, mid)
		"counter": _counter(parts, mid, r)
		"shelf": _shelf(parts, mid, r)
		"rice_sacks": _rice_sacks(parts, mid)
		"forge": _forge(parts, mid, r)
		"anvil": _anvil(parts, mid)
		"tool_rack": _tool_rack(parts, r)
		"water_tub": _water_tub(parts, mid, Color(str(p.get("color", "2a4a5a"))))
		"irori": _irori(parts, mid, r)
		"tokonoma": _tokonoma(parts, mid, r)
		"butsudan": _butsudan(parts, mid)
		"zabuton": _zabuton(parts, mid, Color(str(p.get("color", "8a3a3a"))))
		"byobu": _byobu(parts, mid, r)
		"toy_box": _toy_box(parts, mid)
		"mizugame": _mizugame(parts, mid)
	parts.commit(w)


# --- the farmhouse and the homes ------------------------------------------------

## A futon on the tatami, its head at the back (-z): a white mattress with rounded edges, a
## thick indigo quilt over the lower part with a pale collar, a buckwheat pillow.
static func _futon(p: FarmProps.Parts, r: Rect2) -> void:
	var bed := r.grow(-0.06)
	var cloth := p.st(Color("eeeae0"))
	FarmProps.block(cloth, bed, 0.0, bed, 0.07)
	FarmProps.block(cloth, bed, 0.07, bed.grow(-0.03), 0.1)
	var quilt := Rect2(bed.position.x - 0.02, bed.position.y + bed.size.y * 0.38, bed.size.x + 0.04, bed.size.y * 0.62 + 0.02)
	FarmProps.block(p.st("build:quilt"), quilt, 0.0, quilt, 0.12)
	FarmProps.block(p.st("build:quilt"), quilt, 0.12, quilt.grow(-0.05), 0.16)
	var collar := Rect2(quilt.position.x + 0.01, quilt.position.y - 0.01, quilt.size.x - 0.02, 0.1)
	FarmProps.block(p.st(Color("f2eee4")), collar, 0.0, collar, 0.13)
	FarmProps.block(p.st(Color("f2eee4")), collar, 0.13, collar.grow(-0.03), 0.165)
	var pillow := Rect2(bed.get_center().x - bed.size.x * 0.27, bed.position.y + 0.08, bed.size.x * 0.54, 0.22)
	FarmProps.block(p.st(Color("d8cfa8")), pillow, 0.1, pillow, 0.14)
	FarmProps.block(p.st(Color("d8cfa8")), pillow, 0.14, pillow.grow(-0.04), 0.18)


## A low round table (chabudai): a turned top with a rounded edge on an apron ring and four
## short legs, a teacup and a small teapot on it.
static func _low_table(p: FarmProps.Parts, mid: Vector3) -> void:
	var dark := p.st(Color("4a2e1c"))
	for o in [Vector2(0.22, 0.22), Vector2(-0.22, 0.22), Vector2(0.22, -0.22), Vector2(-0.22, -0.22)]:
		_cube(dark, mid + Vector3(o.x, 0, o.y), Vector3(0.05, 0.27, 0.05))
	Shrine.lathe(dark, mid, [Vector2(0.3, 0.24), Vector2(0.3, 0.28)], 16)
	Shrine.lathe(p.st(WOOD), mid, [Vector2(0.4, 0.28), Vector2(0.42, 0.295), Vector2(0.42, 0.31), Vector2(0.4, 0.325)], 16)
	var cup := mid + Vector3(0.12, 0.325, -0.06)
	Shrine.lathe(p.st(Color("e8e0cc")), cup, [Vector2(0.03, 0.0), Vector2(0.05, 0.075)], 8)
	Shrine.lathe(p.st(Color("7a8a4a")), cup, [Vector2(0.04, 0.075), Vector2(0.04, 0.078)], 8)
	var pot := mid + Vector3(-0.14, 0.325, 0.08)
	Shrine.lathe(p.st(Color("5a3a2a")), pot, [Vector2(0.04, 0.0), Vector2(0.07, 0.04), Vector2(0.06, 0.08),
		Vector2(0.03, 0.09), Vector2(0.015, 0.11)], 8)
	_cube(p.st(Color("5a3a2a")), pot + Vector3(0.09, 0.03, 0), Vector3(0.08, 0.025, 0.025))   # side handle


## A chest of drawers (kasane-dansu, two stacked chests) against the back wall: wide drawers
## below, two small drawers and a sliding door above, black iron pulls, corner plates and a
## carrying handle on the side, on a dark plinth.
static func _tansu(p: FarmProps.Parts, mid: Vector3) -> void:
	var at := mid + Vector3(0, 0, -0.2)
	var body := p.st("build:planks_dark")
	var face := p.st("build:planks")
	var iron := p.st(IRON)
	_cube(p.st(TIMBER), at, Vector3(0.86, 0.08, 0.46))
	_cube(body, at + Vector3(0, 0.08, 0), Vector3(0.9, 0.5, 0.5))
	_cube(body, at + Vector3(0, 0.58, 0), Vector3(0.88, 0.48, 0.48))
	_cube(p.st(TIMBER), at + Vector3(0, 1.06, 0), Vector3(0.92, 0.05, 0.5), 0.02)
	var front := at.z + 0.25
	for y in [0.11, 0.345]:   # the wide drawers, two pulls each
		_front(face, at.x - 0.42, at.x + 0.42, y, y + 0.21, front)
		for x in [-0.22, 0.22]:
			_pull(iron, Vector3(at.x + x, y + 0.13, front + 0.012))
	var upper := at.z + 0.24
	for y in [0.62, 0.83]:   # two small drawers on the left
		_front(face, at.x - 0.4, at.x - 0.02, y, y + 0.19, upper)
		_pull(iron, Vector3(at.x - 0.21, y + 0.12, upper + 0.012))
	_front(face, at.x + 0.02, at.x + 0.4, 0.62, 1.02, upper)   # the sliding door
	_front(p.st(TIMBER), at.x + 0.2, at.x + 0.21, 0.62, 1.02, upper + 0.012)
	_cube(iron, Vector3(at.x + 0.08, 0.8, upper + 0.02), Vector3(0.06, 0.08, 0.008))   # its lock plate
	for x in [at.x - 0.44, at.x + 0.38]:   # corner plates on the front edges
		for y in [0.08, 0.5, 0.58, 0.98]:
			_cube(iron, Vector3(x + 0.03, y, (front if y < 0.55 else upper) + 0.016), Vector3(0.06, 0.08, 0.008))
	_cube(iron, Vector3(at.x + 0.452, 0.84, at.z), Vector3(0.012, 0.03, 0.16))   # side handle
	_cube(iron, Vector3(at.x + 0.462, 0.8, at.z), Vector3(0.012, 0.03, 0.22))


## A paper floor lantern (andon): warm-lit paper inside a dark frame on four legs, rails at
## its top, middle and foot, a base board and a carrying handle over the top.
static func _andon(p: FarmProps.Parts, mid: Vector3) -> void:
	var frame := p.st(TIMBER)
	_cube(frame, mid, Vector3(0.34, 0.04, 0.34), 0.015)
	_cube(p.glow(LAMP), mid + Vector3(0, 0.17, 0), Vector3(0.27, 0.45, 0.27))
	for x in [-0.145, 0.145]:
		for z in [-0.145, 0.145]:
			_cube(frame, mid + Vector3(x, 0.04, z), Vector3(0.03, 0.64, 0.03))
	for y in [0.15, 0.39, 0.61]:
		_ring(frame, mid + Vector3(0, y, 0), 0.155, 0.025, 0.02)
	for x in [-0.1, 0.1]:
		_cube(frame, mid + Vector3(x, 0.68, 0), Vector3(0.025, 0.14, 0.025))
	_cube(frame, mid + Vector3(0, 0.8, 0), Vector3(0.24, 0.03, 0.03))


## A clay cooking stove (kamado): a pale clay body on a stone footing, a little narrower at the
## top, an arched fire mouth in front with embers, an iron rice pot with its flange and a
## wooden lid, two split logs by the mouth.
static func _kamado(p: FarmProps.Parts, mid: Vector3) -> void:
	var at := mid + Vector3(0, 0, -0.05)
	var foot := _rect(at, 0.86, 0.76)
	FarmProps.block(p.st(Color("7e7a72")), foot, 0.0, foot, 0.05)
	var clay := p.st(Color("c8b498"))
	var body := _rect(at, 0.8, 0.7)
	FarmProps.block(clay, body, 0.05, body.grow(-0.03), 0.5)
	FarmProps.block(clay, body.grow(-0.03), 0.5, body.grow(-0.06), 0.55)
	var front := at.z + 0.35 - 0.0035
	var dark := p.st(Color("1e140c"))
	FarmProps.block(dark, Rect2(at.x - 0.15, front, 0.3, 0.012), 0.05, Rect2(at.x - 0.15, front - 0.01, 0.3, 0.012), 0.27)
	FarmProps.block(dark, Rect2(at.x - 0.15, front - 0.01, 0.3, 0.012), 0.27, Rect2(at.x - 0.07, front - 0.012, 0.14, 0.012), 0.33)
	_cube(p.glow(EMBER), Vector3(at.x, 0.05, front + 0.016), Vector3(0.22, 0.05, 0.008))
	var pot := Vector3(at.x, 0.5, at.z)
	Shrine.lathe(p.st(Color("2e2a28")), pot, [Vector2(0.1, 0.0), Vector2(0.17, 0.05), Vector2(0.18, 0.07),
		Vector2(0.26, 0.08), Vector2(0.26, 0.1), Vector2(0.18, 0.11), Vector2(0.16, 0.18)], 12)
	Shrine.lathe(p.st(WOOD), pot, [Vector2(0.18, 0.18), Vector2(0.18, 0.21), Vector2(0.14, 0.22)], 12)
	_cube(p.st(Color("5a3a24")), pot + Vector3(0, 0.22, 0), Vector3(0.18, 0.03, 0.04))   # the lid's grip
	var logs := p.st(Color("6a4a30"))
	for i in 2:
		var log_at := Vector3(at.x - 0.3 + i * 0.1, 0.04 + i * 0.07, at.z + 0.44 - i * 0.03)
		_turn_x(logs, log_at, [Vector2(0.04, 0.0), Vector2(0.04, 0.28)], 6)


## A kitchen cupboard (mizuya) against the back wall: board doors below, a ledge, shoji doors
## above with their lattice, bowls on the ledge.
static func _mizuya(p: FarmProps.Parts, mid: Vector3) -> void:
	var at := mid + Vector3(0, 0, -0.15)
	var body := p.st("build:planks_dark")
	var timber := p.st(TIMBER)
	_cube(timber, at, Vector3(0.86, 0.05, 0.52))
	_cube(body, at + Vector3(0, 0.05, 0), Vector3(0.9, 0.45, 0.55))
	var front := at.z + 0.275
	for x in [-0.42, 0.01]:
		_front(p.st("build:planks"), at.x + x, at.x + x + 0.41, 0.09, 0.46, front)
	for x in [-0.06, 0.06]:
		_cube(p.st(IRON), Vector3(at.x + x, 0.27, front + 0.012), Vector3(0.03, 0.06, 0.01))
	_cube(p.st("build:planks"), at + Vector3(0, 0.5, 0.015), Vector3(0.94, 0.04, 0.58), 0.012)
	var top := at + Vector3(0, 0, -0.05)
	_cube(body, top + Vector3(0, 0.54, 0), Vector3(0.9, 0.56, 0.45))
	var paper_z := top.z + 0.225
	_front(p.st(PAPER), top.x - 0.42, top.x + 0.42, 0.58, 1.06, paper_z)
	for x in [-0.42, -0.14, 0.0, 0.14, 0.42]:   # the lattice and the doors' stiles
		_front(timber, top.x + x - (0.015 if absf(x) > 0.3 or x == 0.0 else 0.008), top.x + x + (0.015 if absf(x) > 0.3 or x == 0.0 else 0.008), 0.58, 1.06, paper_z + 0.006)
	for y in [0.58, 0.74, 0.9, 1.04]:
		_front(timber, top.x - 0.42, top.x + 0.42, y, y + 0.02, paper_z + 0.006)
	_cube(timber, top + Vector3(0, 1.1, 0.03), Vector3(0.94, 0.04, 0.52), 0.015)
	var ledge := at + Vector3(0, 0.54, 0.16)
	Shrine.lathe(p.st(Color("3a5a8c")), ledge + Vector3(0.22, 0, 0), [Vector2(0.04, 0.0), Vector2(0.09, 0.06)], 10)
	Shrine.lathe(p.st(Color("f0ece0")), ledge + Vector3(0.02, 0, 0.02), [Vector2(0.03, 0.0), Vector2(0.06, 0.05)], 10)


## A long lidded chest (nagamochi): plank body, a dark bevelled lid, iron bands and corners,
## a lock plate, and the brackets for a carrying pole on the side.
static func _nagamochi(p: FarmProps.Parts, mid: Vector3) -> void:
	var at := mid + Vector3(0, 0, -0.1)
	_cube(p.st("build:planks"), at, Vector3(0.92, 0.5, 0.55))
	_cube(p.st("build:planks_dark"), at + Vector3(0, 0.5, 0), Vector3(0.96, 0.08, 0.59), 0.03)
	var iron := p.st(IRON)
	var front := at.z + 0.275
	for x in [-0.42, -0.2, 0.2, 0.42]:
		_front(iron, at.x + x - 0.03, at.x + x + 0.03, 0.0, 0.5, front)
	_front(iron, at.x - 0.07, at.x + 0.07, 0.3, 0.44, front)
	_cube(p.st(GOLD), Vector3(at.x, 0.35, front + 0.012), Vector3(0.04, 0.05, 0.008))
	for z in [-0.15, 0.15]:   # pole brackets on the +x end
		_cube(iron, Vector3(at.x + 0.475, 0.32, at.z + z), Vector3(0.03, 0.1, 0.05))


## A kotatsu: a quilt falling from a square table top to the floor, splayed at its foot, a
## straw basket of mikan on the top.
static func _kotatsu(p: FarmProps.Parts, mid: Vector3) -> void:
	FarmProps.block(p.st("build:quilt"), _rect(mid, 0.98, 0.98), 0.0, _rect(mid, 0.84, 0.84), 0.3)
	_cube(p.st("build:planks"), mid + Vector3(0, 0.3, 0), Vector3(0.86, 0.045, 0.86), 0.015)
	var basket := mid + Vector3(-0.12, 0.345, 0.08)
	Shrine.lathe(p.st(Color("c8a868")), basket, [Vector2(0.08, 0.0), Vector2(0.11, 0.05)], 10)
	for o in [Vector3(-0.03, 0.03, -0.02), Vector3(0.04, 0.03, 0.02), Vector3(0.0, 0.08, 0.0)]:
		_ball(p.st(Color("e8a23a")), basket + o, 0.035)


# --- shops, the clinic, the smithy ----------------------------------------------

## A shop counter along its cells: a dark board front with battens and a kickboard, a plank
## top that overhangs on the customer's side, a brass bell on a cushion at the left end and
## an account book at the right.
static func _counter(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var long := r.size.x - 0.08
	var deep := r.size.y - 0.2
	_cube(p.st("build:planks_dark"), mid, Vector3(long, 0.7, deep))
	var front := mid.z + deep / 2
	_front(p.st(TIMBER), mid.x - long / 2, mid.x + long / 2, 0.0, 0.08, front)
	var n := int(long / 0.5)
	for k in n + 1:
		var x := mid.x - long / 2 + 0.03 + k * (long - 0.06) / n
		_front(p.st(Color("3a2c22")), x - 0.02, x + 0.02, 0.08, 0.7, front)
	_cube(p.st("build:planks"), mid + Vector3(0, 0.7, 0.04), Vector3(long, 0.045, deep + 0.16), 0.015)
	var bell := Vector3(r.position.x + 0.35, 0.745, mid.z)
	_cube(p.st(Color("8a3a3a")), bell, Vector3(0.15, 0.02, 0.15))
	Shrine.lathe(p.st(GOLD), bell + Vector3(0, 0.02, 0), [Vector2(0.05, 0.0), Vector2(0.055, 0.03), Vector2(0.035, 0.08), Vector2(0.0, 0.1)], 10)
	var book := Vector3(r.end.x - 0.4, 0.745, mid.z + 0.05)
	_cube(p.st(Color("34446a")), book, Vector3(0.2, 0.015, 0.26))
	_cube(p.st(Color("f0e8d4")), book + Vector3(0.005, 0.015, 0), Vector3(0.18, 0.02, 0.24))


## Goods shelves against the back wall: a dark frame and back with three plank shelves of
## boxes and turned jars in a row of colours.
static func _shelf(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var at := mid + Vector3(0, 0, -0.22)
	var wide := r.size.x - 0.1
	var frame := p.st("build:planks_dark")
	for x in [-wide / 2 + 0.04, wide / 2 - 0.04]:
		_cube(frame, at + Vector3(x, 0, 0), Vector3(0.08, 1.4, 0.42))
	_cube(frame, at + Vector3(0, 0, -0.19), Vector3(wide, 1.4, 0.04))
	_cube(p.st(TIMBER), at + Vector3(0, 1.4, 0), Vector3(wide, 0.04, 0.44), 0.015)
	var goods := [Color("c8442c"), Color("e8d8a0"), Color("4a78c0"), Color("7aa848"), Color("f0a8b8"), Color("c9a26b")]
	for i in 3:
		var y := 0.23 + i * 0.42
		_cube(p.st("build:planks"), at + Vector3(0, y, 0), Vector3(wide - 0.16, 0.04, 0.38))
		var n := int(wide / 0.24)
		for k in n:
			var h := 0.14 + 0.06 * ((k + i) % 3)
			var x := -wide / 2 + 0.18 + k * (wide - 0.36) / maxf(n - 1, 1)
			var c: Color = goods[(k * 2 + i) % goods.size()]
			var foot := at + Vector3(x, y + 0.04, 0.04)
			if (k + i * 2) % 3 == 0:   # a jar with a pale lid
				Shrine.lathe(p.st(c), foot, [Vector2(0.06, 0.0), Vector2(0.075, h * 0.5), Vector2(0.05, h * 0.85), Vector2(0.05, h)], 8)
				Shrine.lathe(p.st(Color("e8e0cc")), foot, [Vector2(0.055, h), Vector2(0.055, h + 0.025)], 8)
			else:
				_cube(p.st(c), foot, Vector3(0.16, h, 0.2), 0.015)


## Two straw rice bales (tawara) on their sides, one on the other, tied with rope at three
## places, the plaited end caps a shade darker.
static func _rice_sacks(p: FarmProps.Parts, mid: Vector3) -> void:
	for i in 2:
		var at := mid + Vector3(-0.3, 0.2 + i * 0.34, 0.1 - i * 0.1)
		_turn_x(p.st(STRAW), at, [Vector2(0.15, 0.0), Vector2(0.19, 0.06), Vector2(0.2, 0.3), Vector2(0.19, 0.54), Vector2(0.15, 0.6)], 10)
		for s in [0.12, 0.28, 0.44]:
			_turn_x(p.st(ROPE), at, [Vector2(0.205, s), Vector2(0.205, s + 0.04)], 10)
		for s in [-0.012, 0.6]:
			_turn_x(p.st(Color("b89c64")), at, [Vector2(0.13, s), Vector2(0.13, s + 0.012)], 10)


## The forge in the back corner: a stone hearth on a darker footing with the fire bed glowing
## in its top, a hood narrowing up to a chimney through the beam, a box bellows at the side
## with its pull rod and the pipe into the hearth.
static func _forge(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var at := mid + Vector3(-0.05, 0, -0.1)
	var stone := p.st(STONE)
	var hearth := _rect(at, r.size.x - 0.3, r.size.y - 0.4)
	FarmProps.block(p.st(Color("5e5a54")), hearth.grow(0.03), 0.0, hearth.grow(0.03), 0.06)
	FarmProps.block(stone, hearth, 0.06, hearth, 0.55)
	FarmProps.block(stone, hearth, 0.55, hearth.grow(-0.04), 0.6)
	var bed := _rect(at + Vector3(0, 0, 0.05), r.size.x - 0.8, r.size.y - 0.9)
	FarmProps.block(p.glow(FIRE), bed, 0.598, bed, 0.605)
	FarmProps.block(p.glow(FLAME), _rect(at + Vector3(0.05, 0, 0.05), 0.5, 0.4), 0.605, _rect(at + Vector3(0.05, 0, 0.05), 0.4, 0.3), 0.625)
	for o in [Vector3(-0.3, 0, 0.15), Vector3(0.32, 0, -0.1), Vector3(-0.2, 0, -0.18)]:
		_cube(p.glow(EMBER), at + o + Vector3(0, 0.6, 0), Vector3(0.1, 0.04, 0.08))
	var hood_lo := _rect(at + Vector3(0, 0, -0.15), r.size.x - 0.5, r.size.y - 1.0)
	var hood_hi := _rect(at + Vector3(0, 0, -0.3), 0.56, 0.46)
	FarmProps.block(p.st(Color("3a3632")), hood_lo, 1.12, hood_lo, 1.16)
	FarmProps.block(p.st(Color("6e6862")), hood_lo, 1.16, hood_hi, 1.6)
	FarmProps.block(p.st(Color("6e6862")), hood_hi, 1.6, hood_hi.grow(-0.03), 2.2)
	var side := Vector3(at.x + r.size.x / 2 - 0.05, 0, at.z + 0.2)
	_cube(p.st("build:planks_dark"), side, Vector3(0.3, 0.32, 0.5))
	_cube(p.st("build:planks"), side + Vector3(0, 0.32, 0), Vector3(0.32, 0.03, 0.52), 0.01)
	_cube(p.st(WOOD), side + Vector3(0, 0.2, 0.3), Vector3(0.03, 0.03, 0.12))   # the pull rod
	_cube(p.st(WOOD), side + Vector3(0, 0.16, 0.36), Vector3(0.16, 0.08, 0.03))
	_cube(p.st(IRON), side + Vector3(-0.2, 0.1, -0.1), Vector3(0.12, 0.06, 0.06))   # the pipe


## An anvil on a tree stump: the bark round the sides, the pale cut on top, a waisted iron
## body flaring to a flat face with a horn, a hammer resting on it.
static func _anvil(p: FarmProps.Parts, mid: Vector3) -> void:
	Shrine.lathe(p.st(Color("5a3e28")), mid, [Vector2(0.28, 0.0), Vector2(0.26, 0.05), Vector2(0.24, 0.36), Vector2(0.24, 0.4)], 10)
	Shrine.lathe(p.st(Color("a8845a")), mid, [Vector2(0.225, 0.4), Vector2(0.225, 0.41)], 10)
	var iron := p.st(Color("2a2a2e"))
	FarmProps.block(iron, _rect(mid, 0.26, 0.22), 0.41, _rect(mid, 0.2, 0.16), 0.45)
	FarmProps.block(iron, _rect(mid, 0.2, 0.16), 0.45, _rect(mid, 0.13, 0.11), 0.52)
	FarmProps.block(iron, _rect(mid, 0.13, 0.11), 0.52, _rect(mid + Vector3(0.03, 0, 0), 0.42, 0.2), 0.58)
	FarmProps.block(iron, _rect(mid + Vector3(0.03, 0, 0), 0.42, 0.2), 0.58, _rect(mid + Vector3(0.03, 0, 0), 0.42, 0.2), 0.63)
	FarmProps.block(iron, Rect2(mid.x - 0.34, mid.z - 0.025, 0.17, 0.05), 0.59, Rect2(mid.x - 0.25, mid.z - 0.07, 0.08, 0.14), 0.63)
	_cube(p.st(Color("a8743f")), mid + Vector3(0.1, 0.63, 0.05), Vector3(0.26, 0.025, 0.03))   # hammer
	_cube(p.st(IRON), mid + Vector3(-0.02, 0.63, 0.05), Vector3(0.05, 0.05, 0.07))


## Finished tools hung on a board against the wall: hoes, sickles and saws on wooden pegs.
## A rack longer in z than in x hangs on the left wall, the rest on the back wall.
static func _tool_rack(p: FarmProps.Parts, r: Rect2) -> void:
	var on_left := r.size.y > r.size.x
	var length := (r.size.y if on_left else r.size.x) - 0.2
	# Built along x facing +z round the origin, then set against its wall.
	var xf := Transform3D(Basis.IDENTITY, Vector3(r.get_center().x, 0, r.position.y + 0.08))
	if on_left:
		xf = Transform3D(Basis(Vector3.UP, PI / 2), Vector3(r.position.x + 0.08, 0, r.get_center().y))
	var put := func(key: Variant, at: Vector3, size: Vector3) -> void:
		_placed(p.st(key), xf, func(t: SurfaceTool) -> void: _cube(t, at, size))
	put.call("build:board", Vector3(0, 0.55, 0), Vector3(length, 0.9, 0.05))
	put.call(TIMBER, Vector3(0, 1.3, 0.04), Vector3(length, 0.05, 0.03))
	var n := int(length + 0.2) * 2 - 1
	for k in n:
		var x := 0.0 if n == 1 else -(length - 0.4) / 2 + k * (length - 0.4) / (n - 1)
		put.call(TIMBER, Vector3(x, 1.32, 0.06), Vector3(0.03, 0.03, 0.06))   # the peg
		match k % 3:
			0:   # a hoe: a handle and a wide blade at its top
				put.call(Color("a8743f"), Vector3(x, 0.66, 0.06), Vector3(0.04, 0.62, 0.04))
				put.call(Color("8a9096"), Vector3(x, 1.2, 0.08), Vector3(0.17, 0.1, 0.02))
			1:   # a sickle: a short handle, a curved blade
				put.call(Color("a8743f"), Vector3(x, 0.98, 0.06), Vector3(0.04, 0.26, 0.04))
				put.call(Color("8a9096"), Vector3(x + 0.06, 1.2, 0.07), Vector3(0.12, 0.03, 0.02))
				put.call(Color("8a9096"), Vector3(x + 0.12, 1.12, 0.07), Vector3(0.03, 0.09, 0.02))
			2:   # a saw: a grip and a long pale blade
				put.call(Color("a8743f"), Vector3(x, 0.72, 0.06), Vector3(0.04, 0.18, 0.04))
				put.call(Color("a8b0b4"), Vector3(x, 0.9, 0.07), Vector3(0.08, 0.38, 0.015))


## A wooden quench tub full of dark water: cedar staves flaring to the rim, two dark hoops. A
## prop's "color" is the water's (Shino's indigo vats in Minamino).
static func _water_tub(p: FarmProps.Parts, mid: Vector3, water: Color) -> void:
	Shrine.lathe(p.st(Color("b08a5a")), mid, [Vector2(0.25, 0.0), Vector2(0.3, 0.42)], 12)
	Shrine.lathe(p.st(water), mid, [Vector2(0.27, 0.42), Vector2(0.27, 0.423)], 12)
	for y in [0.08, 0.32]:
		var rr: float = 0.255 + 0.05 * y / 0.42
		Shrine.lathe(p.st(TIMBER), mid, [Vector2(rr, y), Vector2(rr + 0.005, y + 0.04)], 12)


## A square hearth sunk in the floor (irori): a dark wooden frame round grey ash with glowing
## charcoal, an iron kettle hanging over it from a hook pole with a fish-shaped catch.
static func _irori(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var side := minf(r.size.x, r.size.y) - 0.3
	var frame := p.st("build:planks_dark")
	var h := (side + 0.12) / 2
	for rect in [Rect2(mid.x - h, mid.z - h, side + 0.12, 0.12), Rect2(mid.x - h, mid.z + h - 0.12, side + 0.12, 0.12),
			Rect2(mid.x - h, mid.z - h + 0.12, 0.12, side - 0.12), Rect2(mid.x + h - 0.12, mid.z - h + 0.12, 0.12, side - 0.12)]:
		FarmProps.block(frame, rect, 0.0, rect, 0.05)
		FarmProps.block(frame, rect, 0.05, rect.grow(-0.012), 0.07)
	FarmProps.block(p.st(Color("8a847a")), _rect(mid, side - 0.1, side - 0.1), 0.0, _rect(mid, side - 0.16, side - 0.16), 0.03)
	for o in [Vector3(-0.12, 0, 0.05), Vector3(0.1, 0, -0.08), Vector3(0.02, 0, 0.14)]:
		_cube(p.glow(EMBER), mid + o + Vector3(0, 0.03, 0), Vector3(0.14, 0.04, 0.08), 0.01)
	var timber := p.st(TIMBER)
	_cube(timber, mid + Vector3(0, 0.62, 0), Vector3(0.035, 1.2, 0.035))   # the hook pole (jizai-kagi)
	var fish := p.st(WOOD)   # its catch: a fish, body tapering to the tail
	FarmProps.block(fish, Rect2(mid.x - 0.14, mid.z - 0.025, 0.2, 0.05), 0.92, Rect2(mid.x - 0.12, mid.z - 0.02, 0.16, 0.04), 0.99)
	FarmProps.block(fish, Rect2(mid.x + 0.06, mid.z - 0.012, 0.03, 0.024), 0.945, Rect2(mid.x + 0.06, mid.z - 0.02, 0.06, 0.04), 0.975)
	var kettle := p.st(Color("2a2624"))
	var k := mid + Vector3(0, 0.32, 0)
	Shrine.lathe(kettle, k, [Vector2(0.1, 0.0), Vector2(0.16, 0.04), Vector2(0.17, 0.11), Vector2(0.12, 0.18), Vector2(0.06, 0.2)], 12)
	Shrine.lathe(kettle, k, [Vector2(0.06, 0.2), Vector2(0.06, 0.21), Vector2(0.02, 0.23)], 12)
	FarmProps.block(kettle, Rect2(k.x + 0.15, k.z - 0.025, 0.04, 0.05), 0.07, Rect2(k.x + 0.2, k.z - 0.015, 0.04, 0.03), 0.15)   # spout
	for x in [-0.1, 0.1]:
		_cube(kettle, k + Vector3(x, 0.15, 0), Vector3(0.02, 0.15, 0.02))
	_cube(kettle, k + Vector3(0, 0.29, 0), Vector3(0.22, 0.02, 0.02))


## The alcove against the back wall (tokonoma): a raised plank dais with a black lacquer edge,
## a hanging scroll of ink on pale paper with its rollers, a rough corner post, and a turned
## vase with a flowering branch.
static func _tokonoma(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var at := mid + Vector3(0, 0, -0.15)
	var wide := r.size.x - 0.12
	_cube(p.st("build:planks"), at, Vector3(wide, 0.14, 0.62), 0.01)
	_front(p.st(LACQUER), at.x - wide / 2, at.x + wide / 2, 0.0, 0.15, at.z + 0.31)
	Shrine.lathe(p.st(Color("6a4a30")), Vector3(r.end.x - 0.1, 0, at.z + 0.26), [Vector2(0.07, 0.0), Vector2(0.06, 0.9), Vector2(0.065, 1.7)], 6)
	var scroll := Vector3(at.x - wide / 4, 0, at.z - 0.29)
	_front(p.st(Color("8a6a3a")), scroll.x - 0.21, scroll.x + 0.21, 0.5, 1.42, scroll.z)
	_front(p.st(PAPER), scroll.x - 0.16, scroll.x + 0.16, 0.6, 1.32, scroll.z + 0.01)
	var ink := p.st(Color("1e1a18"))
	for i in 3:
		var x := scroll.x - 0.06 + i * 0.06
		_front(ink, x - 0.022, x + 0.022, 1.0 - i * 0.12, 1.16 - i * 0.07, scroll.z + 0.02)
	for y in [0.48, 1.42]:
		_cube(p.st(Color("3a2a1a")), Vector3(scroll.x, y - 0.02, scroll.z + 0.02), Vector3(0.5, 0.04, 0.04))
	var vase := Vector3(at.x + wide / 4, 0.14, at.z)
	Shrine.lathe(p.st(Color("4a6a7a")), vase, [Vector2(0.05, 0.0), Vector2(0.08, 0.08), Vector2(0.05, 0.18),
		Vector2(0.04, 0.22), Vector2(0.06, 0.26)], 8)
	_placed(p.st(TIMBER), Transform3D(Basis(Vector3.BACK, -0.35), vase + Vector3(0.02, 0.24, 0)),
		func(t: SurfaceTool) -> void: _cube(t, Vector3.ZERO, Vector3(0.025, 0.42, 0.025)))
	for o in [Vector3(0.14, 0.58, 0), Vector3(0.06, 0.5, 0.03), Vector3(0.18, 0.46, -0.02), Vector3(0.1, 0.62, 0.02)]:
		_cube(p.st(Color("f0a8b8")), vase + o, Vector3(0.06, 0.05, 0.06), 0.012)


## The family altar (butsudan): a black lacquer cabinet against the back wall, its doors
## swung open on a gold inside, a small dark shrine within, a candle and a bowl of rice.
static func _butsudan(p: FarmProps.Parts, mid: Vector3) -> void:
	var at := mid + Vector3(0, 0, -0.22)
	var black := p.st(LACQUER)
	_cube(black, at, Vector3(0.62, 0.5, 0.44))
	_cube(black, at + Vector3(0, 0.5, -0.06), Vector3(0.6, 0.7, 0.32))
	_cube(black, at + Vector3(0, 1.2, 0), Vector3(0.66, 0.05, 0.46), 0.015)
	var inside := at.z + 0.1
	_front(p.st(GOLD), at.x - 0.25, at.x + 0.25, 0.54, 1.16, inside)
	_front(p.st(Color("3a2a1a")), at.x - 0.1, at.x + 0.1, 0.62, 0.95, inside + 0.01)
	for s in [-1.0, 1.0]:   # the doors, open about 60 degrees, gilt on the inside
		var hinge := Vector3(at.x + s * 0.3, 0.52, at.z + 0.11)
		_placed(black, Transform3D(Basis(Vector3.UP, -s * 1.05), hinge),
			func(t: SurfaceTool) -> void: _cube(t, Vector3(s * 0.15, 0, 0.01), Vector3(0.3, 0.66, 0.02)))
		_placed(p.st(GOLD), Transform3D(Basis(Vector3.UP, -s * 1.05), hinge),
			func(t: SurfaceTool) -> void: _cube(t, Vector3(s * 0.15, 0.05, -0.005), Vector3(0.24, 0.56, 0.01)))
	var ledge := at.z + 0.16
	Shrine.lathe(p.st(Color("f4f0e0")), Vector3(at.x - 0.15, 0.5, ledge), [Vector2(0.02, 0.0), Vector2(0.02, 0.12)], 6)
	_cube(p.glow(FLAME), Vector3(at.x - 0.15, 0.62, ledge), Vector3(0.025, 0.045, 0.025))
	Shrine.lathe(p.st(Color("f4f0e8")), Vector3(at.x + 0.12, 0.5, ledge), [Vector2(0.03, 0.0), Vector2(0.06, 0.05), Vector2(0.03, 0.08)], 8)


## A flat floor cushion (zabuton), plump in the middle, a tuft knot at its centre.
static func _zabuton(p: FarmProps.Parts, mid: Vector3, color: Color) -> void:
	var cloth := p.st(color)
	FarmProps.block(cloth, _rect(mid, 0.6, 0.6), 0.0, _rect(mid, 0.6, 0.6), 0.035)
	FarmProps.block(cloth, _rect(mid, 0.6, 0.6), 0.035, _rect(mid, 0.48, 0.48), 0.07)
	_cube(p.st(TIMBER), mid + Vector3(0, 0.068, 0), Vector3(0.06, 0.012, 0.06))


## A folding screen (byobu): panels of pale paper in dark frames, standing in a zig-zag,
## a green painted hill on each.
static func _byobu(p: FarmProps.Parts, mid: Vector3, r: Rect2) -> void:
	var n := int(r.size.x) * 2
	var panel := (r.size.x - 0.2) / n
	for i in n:
		var at := Vector3(r.position.x + 0.1 + panel * (i + 0.5), 0, mid.z - 0.2 + (0.08 if i % 2 == 0 else -0.08))
		var xf := Transform3D(Basis(Vector3.UP, 0.5 if i % 2 == 0 else -0.5), at)
		var hill := 0.36 + 0.1 * (i % 3)
		_placed(p.st(TIMBER), xf, func(t: SurfaceTool) -> void: _cube(t, Vector3(0, 0.02, 0), Vector3(panel * 1.08, 1.0, 0.035)))
		_placed(p.st(Color("e8dcb8")), xf, func(t: SurfaceTool) -> void: _cube(t, Vector3(0, 0.09, 0), Vector3(panel * 0.92, 0.86, 0.045)))
		var lo := Rect2(-panel * 0.4, -0.026, panel * 0.8, 0.052)
		var hi := Rect2(-panel * 0.12, -0.026, panel * 0.24, 0.052)
		_placed(p.st(Color("7a9a6a")), xf, func(t: SurfaceTool) -> void: FarmProps.block(t, lo, 0.12, hi, 0.12 + hill))


## A child's wooden box of toys: a red spinning top on the lid, a ball beside it, a paper
## kite leaning on the wall behind.
static func _toy_box(p: FarmProps.Parts, mid: Vector3) -> void:
	var at := mid + Vector3(0, 0, -0.1)
	_cube(p.st("build:planks"), at, Vector3(0.7, 0.4, 0.5))
	_cube(p.st("build:planks_dark"), at + Vector3(0, 0.4, 0), Vector3(0.74, 0.05, 0.54), 0.015)
	Shrine.lathe(p.st(Color("c8442c")), at + Vector3(-0.15, 0.45, 0.05), [Vector2(0.012, 0.0), Vector2(0.07, 0.05),
		Vector2(0.07, 0.07), Vector2(0.02, 0.09), Vector2(0.012, 0.13)], 8)
	_ball(p.st(Color("e8c050")), mid + Vector3(0.38, 0, 0.2), 0.08)
	var kite := Transform3D(Basis(Vector3.BACK, 0.15), mid + Vector3(0.1, 0.9, -0.42))
	_placed(p.st(Color("f4ecd8")), kite, func(t: SurfaceTool) -> void: _cube(t, Vector3(0, -0.3, 0), Vector3(0.5, 0.6, 0.02)))
	_placed(p.st(Color("c8442c")), kite, func(t: SurfaceTool) -> void: _cube(t, Vector3(0, -0.06, 0.012), Vector3(0.22, 0.22, 0.01)))


## A big glazed water jar (mizugame) on the earth floor: a turned brown body, a wooden lid
## with a grip, a ladle laid across it.
static func _mizugame(p: FarmProps.Parts, mid: Vector3) -> void:
	Shrine.lathe(p.st(Color("6a4028")), mid, [Vector2(0.17, 0.0), Vector2(0.24, 0.12), Vector2(0.27, 0.3),
		Vector2(0.24, 0.48), Vector2(0.2, 0.53), Vector2(0.22, 0.56)], 12)
	Shrine.lathe(p.st(Color("b8925a")), mid, [Vector2(0.25, 0.56), Vector2(0.25, 0.6)], 12)
	_cube(p.st(WOOD), mid + Vector3(0, 0.6, 0), Vector3(0.2, 0.03, 0.04))
	var ladle := Transform3D(Basis(Vector3.UP, 0.5), mid + Vector3(0.05, 0.63, 0.05))
	_placed(p.st(Color("c8a46a")), ladle, func(t: SurfaceTool) -> void: _cube(t, Vector3.ZERO, Vector3(0.36, 0.02, 0.03)))
	_placed(p.st(Color("c8a46a")), ladle, func(t: SurfaceTool) -> void: Shrine.lathe(t, Vector3(0.2, 0, 0), [Vector2(0.04, 0.0), Vector2(0.055, 0.05)], 8))


# --- helpers --------------------------------------------------------------------

## A box standing on `at` (its bottom middle), `size` across; `bevel` cuts its top edges.
static func _cube(st: SurfaceTool, at: Vector3, size: Vector3, bevel := 0.0) -> void:
	var r := _rect(at, size.x, size.z)
	if bevel <= 0.0:
		FarmProps.block(st, r, at.y, r, at.y + size.y)
		return
	FarmProps.block(st, r, at.y, r, at.y + size.y - bevel)
	FarmProps.block(st, r, at.y + size.y - bevel, r.grow(-bevel), at.y + size.y)


## A thin panel on a face looking +z at `z`: x0..x1, y0..y1, standing 0.012 proud.
static func _front(st: SurfaceTool, x0: float, x1: float, y0: float, y1: float, z: float) -> void:
	var r := Rect2(x0, z, x1 - x0, 0.012)
	FarmProps.block(st, r, y0, r, y1)


## An iron drawer pull (warabite): a small plate and the bar hanging under it.
static func _pull(st: SurfaceTool, at: Vector3) -> void:
	_cube(st, at + Vector3(0, 0.0, 0.004), Vector3(0.07, 0.04, 0.008))
	_cube(st, at + Vector3(0, -0.035, 0.012), Vector3(0.12, 0.022, 0.012))


## Four bars round a square of half side `half` at `at` (a rail round a lantern).
static func _ring(st: SurfaceTool, at: Vector3, half: float, high: float, thick: float) -> void:
	for s in [-1.0, 1.0]:
		_cube(st, at + Vector3(0, 0, s * half), Vector3(half * 2 + thick, high, thick))
		_cube(st, at + Vector3(s * half, 0, 0), Vector3(thick, high, half * 2 - thick))


## A round thing (fruit, a ball) of radius `rad` sitting on `at`.
static func _ball(st: SurfaceTool, at: Vector3, rad: float) -> void:
	Shrine.lathe(st, at, [Vector2(rad * 0.4, 0.0), Vector2(rad * 0.9, rad * 0.45), Vector2(rad, rad),
		Vector2(rad * 0.9, rad * 1.55), Vector2(0.0, rad * 2.0)], 8)


## A lathe shape lying along +x from `at` (its axis at `at`'s height): bales, logs.
static func _turn_x(st: SurfaceTool, at: Vector3, profile: Array, sides: int) -> void:
	_placed(st, Transform3D(Basis(Vector3.BACK, -PI / 2), at),
		func(t: SurfaceTool) -> void: Shrine.lathe(t, Vector3.ZERO, profile, sides))


## Builds with `make` round the origin into a spare SurfaceTool and adds it to `st` moved by
## `xf` (turned boxes, things on their side).
static func _placed(st: SurfaceTool, xf: Transform3D, make: Callable) -> void:
	var tmp := SurfaceTool.new()
	tmp.begin(Mesh.PRIMITIVE_TRIANGLES)
	make.call(tmp)
	st.append_from(tmp.commit(), 0, xf)


## The rectangle w x d (x, z) round `at`.
static func _rect(at: Vector3, w: float, d: float) -> Rect2:
	return Rect2(at.x - w / 2, at.z - d / 2, w, d)
