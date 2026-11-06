class_name FieldProps
extends RefCounted
## The farm-country props along the lanes as real meshes (CountryProps calls these): the rice
## drying rack (hasa-kake: lashed poles, paired rails, sheaves of straw draped over them in
## fall), the kitchen garden (a framed bed of ridges with greens, cabbages and spring onions;
## bare in winter) and the low board fence. All lit; the same cells and heights as the boxes
## they replace. Snow lies on their tops where `snow` is true. Same units: 1 unit = 1 cell.

const TIMBER := Color("4a3424")
const POLE := Color("6a5238")
const STRAW_LASH := Color("c8b078")
const SHEAF := [Color("d8b85a"), Color("caa84c")]
const SOIL := Color("6a4a30")
const SOIL_RIDGE := Color("7a5a3c")


# --- the drying rack ----------------------------------------------------------

## A rice drying rack along `r` (as long as it is wide): a pole every cell, two pairs of rails
## lashed to them (0.75 and 1.2 up), straw sheaves hanging over the rails in fall. `season` is
## the map's.
static func hasa(w: FarmWorld, r: Rect2, mid: Vector3, season: String, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var long := r.size.x
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x) * 29 + int(r.position.y) * 11 + 3
	var pole := p.st(POLE)
	var lash := p.st(STRAW_LASH)
	var rails: Array[float] = [0.75, 1.2]
	for i in int(long) + 1:
		var x := r.position.x + clampf(i, 0.15, long - 0.15)
		var lean := rng.randf_range(-0.012, 0.012)
		Shrine.lathe(pole, Vector3(x, 0, mid.z), [Vector2(0.058, 0.0), Vector2(0.05, 0.7), Vector2(0.04, 1.4)], 6)
		OutdoorProps._tube(pole, Vector3(x, 1.4, mid.z), Vector3.UP, [Vector2(0.044, 0.0), Vector2(0.0, 0.025)], 6, null)
		Shrine.lathe(p.st(Color("4a3a28")), Vector3(x, 0, mid.z), [Vector2(0.066, 0.0), Vector2(0.066, 0.04)], 6)   # the foot in the earth
		for y in rails:   # the lashing where the rails cross the pole
			Shrine.lathe(lash, Vector3(x + lean, y - 0.045, mid.z), [Vector2(0.066, 0.0), Vector2(0.066, 0.09)], 6)
	var x0 := r.position.x + 0.1
	var length := long - 0.2
	for y in rails:
		for dz in [-0.052, 0.052]:
			OutdoorProps._tube(pole, Vector3(x0, y, mid.z + dz), Vector3.RIGHT, [Vector2(0.026, 0.0), Vector2(0.024, length)], 6, null)
	if season == "fall":
		var n := int(long * 4)
		for i in n:
			var x := r.position.x + 0.2 + (long - 0.4) * (i + 0.5) / n
			for y in rails:
				_sheaf(p, Vector3(x, y, mid.z), SHEAF[(i + (1 if y > 1.0 else 0)) % 2], rng)
	if snow:   # the rails and pole tops carry a line of snow
		var sn := p.st(FarmProps.Parts.SNOW)
		for y in rails:
			var strip := Rect2(x0, mid.z - 0.045, length, 0.09)
			FarmProps.block(sn, strip, y + 0.022, strip.grow(-0.02), y + 0.05)
		for i in int(long) + 1:
			var x := r.position.x + clampf(i, 0.15, long - 0.15)
			var cap := Rect2(x - 0.04, mid.z - 0.04, 0.08, 0.08)
			FarmProps.block(sn, cap, 1.42, cap.grow(-0.02), 1.46)
	p.commit(w)


## One sheaf of rice straw draped over the rail at `rail` (height y of its top): two hanging
## bundles, one each side, bound near the top, ears fraying at the foot.
static func _sheaf(p: FarmProps.Parts, rail: Vector3, col: Color, rng: RandomNumberGenerator) -> void:
	var st := p.st(col)
	var k := rng.randf_range(0.92, 1.05)
	for dz in [-0.045, 0.045]:
		var at := Vector3(rail.x, rail.y - 0.37 * k, rail.z + dz)
		Shrine.lathe(st, at, [Vector2(0.03, 0.0), Vector2(0.055, 0.1 * k), Vector2(0.08, 0.26 * k), Vector2(0.088, 0.38 * k)], 7)
	Shrine.lathe(p.st(Color("8a7240")), Vector3(rail.x, rail.y - 0.15 * k, rail.z), [Vector2(0.108, 0.0), Vector2(0.108, 0.035)], 7)   # the binding
	var ears := p.st(Color("e6c868"))
	for e in 3:   # a few ears hanging out of the foot
		var a := rng.randf() * TAU
		var d := Vector3(cos(a) * 0.35, -1.0, sin(a) * 0.35).normalized()
		OutdoorProps._tube(ears, Vector3(rail.x, rail.y - 0.34 * k, rail.z) + Vector3(cos(a), 0, sin(a)) * 0.03, d,
			[Vector2(0.004, 0.0), Vector2(0.011, 0.07)], 4, null)


# --- the kitchen garden -------------------------------------------------------

## A kitchen garden over `r`: a bed of dark earth in a low plank frame, ridged in rows (every
## half cell), the rows alternating leafy greens, cabbages and spring onions along it. The plants
## are left out in winter; snow lies on the bed where it lies.
static func garden(w: FarmWorld, r: Rect2, mid: Vector3, season: String, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var bed := Rect2(r.position + Vector2(0.05, 0.05), r.size - Vector2(0.1, 0.1))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x) * 37 + int(r.position.y) * 19 + 5
	FarmProps.block(p.st(SOIL), bed, 0.0, bed.grow(-0.03), 0.1)
	# The plank frame round it, standing a little higher than the earth.
	var frame := p.st("build:planks_dark")
	var t := 0.045
	for edge in [Rect2(bed.position.x, bed.position.y, bed.size.x, t), Rect2(bed.position.x, bed.end.y - t, bed.size.x, t)]:
		FarmProps.block(frame, edge, 0.0, edge, 0.125)
	for edge in [Rect2(bed.position.x, bed.position.y + t, t, bed.size.y - 2 * t), Rect2(bed.end.x - t, bed.position.y + t, t, bed.size.y - 2 * t)]:
		FarmProps.block(frame, edge, 0.0, edge, 0.125)
	var rows := int(r.size.y * 2)
	var cols := int(r.size.x * 3)
	var span_x := Vector2(r.position.x + 0.1, r.position.x + 0.3 + (cols - 1) * 0.32 + 0.1)
	for row in rows:
		var z := r.position.y + 0.25 + row * 0.5
		var ridge := Rect2(span_x.x, z - 0.13, span_x.y - span_x.x, 0.26)
		FarmProps.block(p.st(SOIL_RIDGE), ridge, 0.09, ridge.grow(-0.07), 0.15)
	if season != "winter":
		var greens: Array[Color] = [Color("5a9a3a"), Color("4c8a34"), Color("68a642")]
		var cabbage := Color("8cb860")
		if season == "fall":
			greens = [Color("7a9a3a"), Color("6c8a32"), Color("8aa644")]
			cabbage = Color("a0b45c")
		for row in rows:
			for i in cols:
				var at := Vector3(r.position.x + 0.2 + i * 0.32, 0.15, r.position.y + 0.25 + row * 0.5)
				at.x += rng.randf_range(-0.02, 0.02)
				var tone := greens[(i + row) % 3]
				match row % 3:
					0: _greens(p, at, tone, rng)
					1: _cabbage(p, at, tone, cabbage, rng)
					_: _onions(p, at, tone, rng)
	if snow:
		var cover := bed.grow(-0.05)
		FarmProps.block(p.st(FarmProps.Parts.SNOW), cover, 0.105, cover.grow(-0.03), 0.17)
	p.commit(w)


## A small head of leafy greens (komatsuna): six leaves rising and arching out.
static func _greens(p: FarmProps.Parts, at: Vector3, col: Color, rng: RandomNumberGenerator) -> void:
	var st := p.st(col)
	var turn := rng.randf() * TAU
	for k in 6:
		var a := turn + TAU * k / 6.0
		var e := rng.randf_range(0.65, 1.0)
		var d := Vector3(cos(a) * cos(e), sin(e), sin(a) * cos(e)).normalized()
		OutdoorProps._leaf(st, null, at, d, rng.randf_range(0.17, 0.22), 0.09, col)


## A cabbage: a round pale head wrapped in a few broad outer leaves.
static func _cabbage(p: FarmProps.Parts, at: Vector3, outer: Color, head: Color, rng: RandomNumberGenerator) -> void:
	RoomProps._ball(p.st(head), at + Vector3(0, 0.0, 0), 0.07)
	var st := p.st(outer)
	var turn := rng.randf() * TAU
	for k in 5:
		var a := turn + TAU * k / 5.0
		var d := Vector3(cos(a) * cos(0.55), sin(0.55), sin(a) * cos(0.55)).normalized()
		OutdoorProps._leaf(st, null, at + Vector3(0, 0.0, 0), d, 0.15, 0.12, outer)


## Spring onions: a bunch of upright stalks, white at the foot, green above.
static func _onions(p: FarmProps.Parts, at: Vector3, col: Color, rng: RandomNumberGenerator) -> void:
	var white := p.st(Color("e4ecd0"))
	var green := p.st(col.lightened(0.1))
	for k in 5:
		var a := rng.randf() * TAU
		var foot := at + Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, 0.06)
		var lean := Vector3(cos(a) * 0.18, 1.0, sin(a) * 0.18).normalized()
		OutdoorProps._tube(white, foot, lean, [Vector2(0.014, 0.0), Vector2(0.012, 0.07)], 5, null)
		OutdoorProps._tube(green, foot + lean * 0.07, lean, [Vector2(0.012, 0.0), Vector2(0.006, rng.randf_range(0.14, 0.2))], 5, null)


# --- the board fence ----------------------------------------------------------

## A low board fence along `r` (x or z, by its shape): square posts with capped tops every cell
## and two rows of weathered boards nailed to the +z (or +x) face, each board a little off its
## neighbour's height. Snow on the caps and the top boards.
static func board_fence(w: FarmWorld, r: Rect2, mid: Vector3, snow: bool) -> void:
	var p := FarmProps.Parts.new()
	var along_x: bool = r.size.x >= r.size.y
	var long: float = r.size.x if along_x else r.size.y
	var a0: float = r.position.x if along_x else r.position.y
	var bc: float = mid.z if along_x else mid.x
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x) * 23 + int(r.position.y) * 7 + 1
	# (along, across) ranges to a ground rectangle.
	var rc := func(s0: float, s1: float, b0: float, b1: float) -> Rect2:
		return Rect2(a0 + s0, bc + b0, s1 - s0, b1 - b0) if along_x else Rect2(bc + b0, a0 + s0, b1 - b0, s1 - s0)
	var posts: Array[float] = []
	for i in int(long) + 1:
		posts.append(clampf(i, 0.1, long - 0.1))
	var post := p.st(TIMBER)
	var sn: SurfaceTool = p.st(FarmProps.Parts.SNOW) if snow else null
	for t in posts:
		FarmProps.block(post, rc.call(t - 0.045, t + 0.045, -0.045, 0.045), 0.0, rc.call(t - 0.038, t + 0.038, -0.038, 0.038), 0.66)
		FarmProps.block(post, rc.call(t - 0.056, t + 0.056, -0.056, 0.056), 0.66, rc.call(t - 0.04, t + 0.04, -0.04, 0.04), 0.72)
		if sn != null:
			FarmProps.block(sn, rc.call(t - 0.05, t + 0.05, -0.05, 0.05), 0.715, rc.call(t - 0.03, t + 0.03, -0.03, 0.03), 0.745)
	var boards := p.st("build:planks")
	var nails := p.st(Color("2a2420"))
	for k in posts.size() - 1:
		for y in [0.22, 0.5]:
			var j := rng.randf_range(-0.012, 0.012)
			var s0 := posts[k] + 0.02
			var s1 := posts[k + 1] - 0.02
			FarmProps.block(boards, rc.call(s0, s1, 0.04, 0.078), y - 0.07 + j, rc.call(s0, s1, 0.04, 0.078), y + 0.07 + j)
			for s in [s0 + 0.04, s1 - 0.04]:   # nail heads
				FarmProps.block(nails, rc.call(s - 0.008, s + 0.008, 0.078, 0.084), y - 0.005 + j, rc.call(s - 0.008, s + 0.008, 0.078, 0.084), y + 0.011 + j)
			if sn != null and y > 0.4:
				FarmProps.block(sn, rc.call(s0, s1, 0.04, 0.078).grow(-0.005), y + 0.07 + j, rc.call(s0, s1, 0.04, 0.078).grow(-0.012), y + 0.092 + j)
	p.commit(w)
