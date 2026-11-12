class_name GreenhouseProps
extends RefCounted
## The greenhouse in 3D (FarmGrid.GREENHOUSE, built by Hachiro): a long low glasshouse of our
## own in the satoyama manner. A fieldstone footing and a charred-board skirting (koshi-ita)
## carry a light cedar frame, a post at every cell and a plate along the top, glazed all round
## with small panes; a low gable roof of glass on thin rafters, its ridge along x under a cedar
## ridge board; a glazed sliding door with a dark frame on the front (+z) over
## FarmGrid.GREENHOUSE_DOOR, a step stone before it, and a rain barrel at the +x corner. Through
## the glass the beds show: dark soil and rows of green, and a paper lantern hanging inside by the
## door, which lights the glass near it at night (LitSpots.greenhouse, drawn by NightLights like a
## house's windows). Snow lies on the glass slopes, the ridge cap and the barrel's lid
## (FarmWorld._snow_top, as on the other roofs). Same units as FarmWorld.

const TIMBER := Color("6e4c30")     # the cedar frame, left unpainted (lighter than the barn's)
const DARK := Color("2e221a")
const STONE := Color("8a8680")
const EAVE := LitSpots.GREENHOUSE_EAVE   # top of the walls
const RISE := LitSpots.GREENHOUSE_RISE   # the ridge above the eaves (a low roof, about 27°)
const OVER := LitSpots.GREENHOUSE_OVER   # the glass roof past the walls all round


## The glass: the pane picture laid like the other surfaces, see-through, lit, both faces drawn.
static func glass_material() -> StandardMaterial3D:
	var m := FarmWorld.surface_material("build:glass")
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.55)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.2
	return WetRules.mark(m, "glass")   # a little darker and glossier in rain (WetRules)


static func greenhouse(w: FarmWorld) -> void:
	var r := Rect2(FarmGrid.GREENHOUSE)
	var front := r.end.y - 0.1
	var back := r.position.y + 0.1
	var depth := front - back
	var mid_z := back + depth / 2
	var left := r.position.x + 0.1
	var right := r.end.x - 0.1
	var cx := (left + right) / 2
	var wide := right - left
	var timber := WetRules.mark(FarmWorld.flat_material(TIMBER), "wood")   # marked: they get wet in rain (WetRules)
	var dark := WetRules.mark(FarmWorld.flat_material(DARK), "wood")
	var glass := glass_material()
	# What shows through the glass first (opaque): the beds inside, dark soil with green rows.
	for i in 3:
		var z := back + 0.45 + i * 0.85
		w._box(Vector3(wide - 0.5, 0.16, 0.6), Vector3(cx, 0.08, z), FarmWorld.flat_material(Color("4a3424")))
		for k in 7:
			var x := left + 0.45 + k * (wide - 0.9) / 6.0
			var green := Color("5e9a3a") if (i + k) % 2 else Color("7aae48")
			w._box(Vector3(0.28, 0.3 + 0.08 * ((i + k) % 3), 0.32), Vector3(x, 0.3, z), FarmWorld.flat_material(green))
	# The footing and the board skirting.
	w._box(Vector3(wide + 0.08, 0.12, depth + 0.08), Vector3(cx, 0.06, mid_z), WetRules.mark(FarmWorld.flat_material(STONE), "stone"))
	var skirt := 0.5
	for side in [[Vector3(wide, skirt - 0.12, 0.08), Vector3(cx, 0.12 + (skirt - 0.12) / 2, front)],
			[Vector3(wide, skirt - 0.12, 0.08), Vector3(cx, 0.12 + (skirt - 0.12) / 2, back)],
			[Vector3(0.08, skirt - 0.12, depth), Vector3(left, 0.12 + (skirt - 0.12) / 2, mid_z)],
			[Vector3(0.08, skirt - 0.12, depth), Vector3(right, 0.12 + (skirt - 0.12) / 2, mid_z)]]:
		w._box(side[0], side[1], FarmWorld.surface_material("build:board"))
	# The glazed walls above it.
	var high := EAVE - skirt
	w._box(Vector3(wide, high, 0.03), Vector3(cx, skirt + high / 2, front), glass)
	w._box(Vector3(wide, high, 0.03), Vector3(cx, skirt + high / 2, back), glass)
	w._box(Vector3(0.03, high, depth), Vector3(left, skirt + high / 2, mid_z), glass)
	w._box(Vector3(0.03, high, depth), Vector3(right, skirt + high / 2, mid_z), glass)
	# The frame: a post at every cell along the front and the back, three a side, the sill
	# rail on the skirting, a mid rail and the top plate.
	for x in range(int(r.position.x), int(r.end.x) + 1):
		var px := clampf(float(x), left, right)
		for z in [front, back]:
			w._box(Vector3(0.07, EAVE, 0.07), Vector3(px, EAVE / 2, z), timber)
	for z in [back, mid_z, front]:
		for x in [left, right]:
			w._box(Vector3(0.07, EAVE, 0.07), Vector3(x, EAVE / 2, z), timber)
	for y in [skirt, 1.0, EAVE]:
		for z in [front, back]:
			w._box(Vector3(wide + 0.07, 0.05, 0.06), Vector3(cx, y, z), timber)
		for x in [left, right]:
			w._box(Vector3(0.06, 0.05, depth + 0.07), Vector3(x, y, mid_z), timber)
	# The roof: two glass slopes from the eaves to the ridge, a little past the walls all round,
	# on thin rafters at every cell, a ridge board and a cap on top.
	var over := OVER
	var run := depth / 2 + over
	var slope := sqrt(run * run + RISE * RISE)
	var tilt := atan2(RISE, depth / 2)
	var lift := EAVE - over * tan(tilt)   # the roof's foot, past the wall
	for s in [1.0, -1.0]:
		var centre := Vector3(cx, lift + RISE * run / (depth / 2) / 2 + 0.03, mid_z + s * run / 2)
		w._box(Vector3(wide + over * 2, 0.02, slope), centre, glass, Vector3(s * tilt, 0, 0))
		# Snow on the glass: a thin sheet just over the slope in each bay between the rafters, so
		# the frame's lines still show through, stopping short of the eave where it slides off.
		var up := Vector3(0, cos(s * tilt), sin(s * tilt))
		var upslope: Vector3 = s * Vector3(0, sin(s * tilt), -cos(s * tilt))
		var bays: Array[float] = [left - over]
		for x in range(int(r.position.x) + 1, int(r.end.x)):
			bays.append(float(x))
		bays.append(right + over)
		for i in bays.size() - 1:
			var at := Vector3((bays[i] + bays[i + 1]) / 2 - cx, 0, 0)
			w._snow_top(Vector3(bays[i + 1] - bays[i] - 0.07, 0.02, slope - 0.2), centre + at + up * 0.02 + upslope * 0.07, Vector3(s * tilt, 0, 0))
		for x in range(int(r.position.x), int(r.end.x) + 1):
			var px := clampf(float(x), left, right)
			w._box(Vector3(0.05, 0.05, slope), centre + Vector3(px - cx, -0.03, 0), timber, Vector3(s * tilt, 0, 0))
		w._box(Vector3(wide + over * 2, 0.05, 0.06), Vector3(cx, lift + 0.02, mid_z + s * (run - 0.02)), timber)   # the eave board
	var ridge := EAVE + RISE
	w._box(Vector3(wide + over * 2 + 0.04, 0.12, 0.08), Vector3(cx, ridge + 0.03, mid_z), timber)
	w._box(Vector3(wide + over * 2 + 0.06, 0.04, 0.2), Vector3(cx, ridge + 0.11, mid_z), dark)
	w._snow_top(Vector3(wide + over * 2 + 0.02, 0.03, 0.18), Vector3(cx, ridge + 0.145, mid_z))
	# The gable ends: the glass triangles over the side walls, a king post in each.
	for x in [left, right]:
		_gable(w, x, back, front, EAVE, ridge, glass)
		w._box(Vector3(0.06, RISE, 0.06), Vector3(x, EAVE + RISE / 2, mid_z), timber)
	# The door: a glazed sliding door in a dark frame, its pull, the step stone.
	var dx := FarmGrid.GREENHOUSE_DOOR.x + 0.5
	w._box(Vector3(0.84, 1.18, 0.05), Vector3(dx, 0.12 + 0.59, front + 0.04), FarmWorld.flat_material(Color("2a3a32")))
	w._box(Vector3(0.72, 1.0, 0.02), Vector3(dx, 0.14 + 0.55, front + 0.07), glass)
	for x in [dx - 0.42, dx + 0.42]:
		w._box(Vector3(0.07, 1.25, 0.08), Vector3(x, 0.62, front + 0.06), dark)
	for y in [0.14, 0.7, 1.24]:
		w._box(Vector3(0.84, 0.06, 0.08), Vector3(dx, y, front + 0.06), dark)
	w._box(Vector3(0.04, 0.12, 0.03), Vector3(dx + 0.3, 0.72, front + 0.11), FarmWorld.flat_material(Color("1e1c1c")))
	w._box(Vector3(0.62, 0.06, 0.3), Vector3(dx, 0.03, front + 0.28), WetRules.mark(FarmWorld.flat_material(STONE), "stone"))
	# A rain barrel of staves at the front +x corner, for the watering can's look of the place.
	var barrel := Vector3(right + 0.3, 0, front - 0.25)
	w._box(Vector3(0.36, 0.5, 0.36), barrel + Vector3(0, 0.25, 0), FarmWorld.surface_material("build:sugi"))
	for y in [0.12, 0.38]:
		w._box(Vector3(0.39, 0.04, 0.39), barrel + Vector3(0, y, 0), FarmWorld.flat_material(Color("3a3430")))
	w._box(Vector3(0.3, 0.01, 0.3), barrel + Vector3(0, 0.5, 0), FarmWorld.flat_material(Color("3a6a7a")))
	w._snow_top(Vector3(0.34, 0.03, 0.34), barrel + Vector3(0, 0.52, 0))
	var hook := LitSpots.greenhouse_lantern()   # the lantern hangs here, from the rafter over it
	_lantern(w, Vector3(hook.x, 0, hook.z), ridge - 0.04 - RISE * absf(hook.z - mid_z) / (depth / 2))
	# The lantern's light on the glass at night: no picture by day, NightLights draws the glow on
	# the walls' glass and, softer, on the roof's (under its snow).
	for spot in LitSpots.greenhouse():
		w.windows.append(spot)
	w.roof_glows.append_array(LitSpots.greenhouse_roof())
	if not w.is_in_group(NightLights.GROUP):
		w.add_to_group(NightLights.GROUP)


## A small paper lantern (chochin) at `at` (x / z, on the ground) hanging on a cord from a rafter
## at height `roof`: washi between a dark top and foot, its middle at the height of the glass it
## lights.
static func _lantern(w: FarmWorld, at: Vector3, roof: float) -> void:
	var dark := FarmWorld.flat_material(DARK)
	w._box(Vector3(0.17, 0.22, 0.17), at + Vector3(0, 1.08, 0), FarmWorld.flat_material(Color("ead9b4")))
	w._box(Vector3(0.2, 0.04, 0.2), at + Vector3(0, 1.21, 0), dark)
	w._box(Vector3(0.2, 0.04, 0.2), at + Vector3(0, 0.95, 0), dark)
	var hang := roof - 1.23
	w._box(Vector3(0.015, hang, 0.015), at + Vector3(0, 1.23 + hang / 2, 0), dark)


## A gable triangle in the plane x = `x`, from the eaves at z `back` and `front` (height `eave`)
## up to `ridge` over the middle.
static func _gable(w: FarmWorld, x: float, back: float, front: float, eave: float, ridge: float, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := [Vector3(x, eave, back), Vector3(x, eave, front), Vector3(x, ridge, (back + front) / 2)]
	st.set_normal(Vector3(1, 0, 0))
	for p in pts:
		st.set_uv(Vector2(p.z, -p.y))
		st.add_vertex(p)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	w.add_child(mi)
