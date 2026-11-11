class_name SiloProps
extends RefCounted
## The fodder silo in 3D (FarmGrid.SILO, built by Hachiro): a round tower of cedar staves on a
## fieldstone footing, bound with iron hoops, under a conical tiled roof with a little finial;
## a low hatch and a plank step on the front (+z) face where the farmer stands to take the fodder,
## and a pitched cap over a loading door high on the +x side. Snow lies on the cone in winter. Our own design, in the farm's
## satoyama look (the coop's and the barn's materials).

const TIMBER := Color("2e221a")
const IRON := Color("3a3430")
const SEGMENTS := 20


## One round piece: a cylinder (or cone) of the given radii and height, its foot at `y`.
static func _drum(w: FarmWorld, centre: Vector2, top: float, bottom: float, high: float, y: float, mat: Material) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = high
	m.radial_segments = SEGMENTS
	m.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = Vector3(centre.x, y + high / 2.0, centre.y)
	w.add_child(mi)
	return mi


static func silo(w: FarmWorld) -> void:
	var r := Rect2(FarmGrid.SILO)
	var c := r.get_center()
	var radius := 0.84
	var wall := 1.8
	var timber := FarmWorld.flat_material(TIMBER)
	var iron := FarmWorld.flat_material(IRON)
	_drum(w, c, radius + 0.06, radius + 0.1, 0.3, 0.0, FarmWorld.flat_material(Color("8a8680")))   # the stone footing
	_drum(w, c, radius, radius, wall, 0.3, FarmWorld.surface_material("build:sugi"))   # the staves
	for y in [0.65, 1.15, 1.65]:   # the hoops
		_drum(w, c, radius + 0.025, radius + 0.025, 0.07, y, iron)
	# The roof: a cone with an overhang, tile-grey (kawara), a stepped eave ring and a finial.
	var top := 0.3 + wall
	_drum(w, c, radius + 0.04, radius + 0.04, 0.1, top - 0.02, timber)
	_drum(w, c, 0.04, radius + 0.26, 0.8, top + 0.08, FarmWorld.surface_material("build:kawara"))
	# Snow on the cone (FarmWorld._snow_top's shader, driven by set_snow): the same cone lifted
	# 0.12, from 0.2 over its foot up, so it lies just over the tiles and leaves the eave ring bare.
	var snow := SnowLayer.top_material()
	w._snow_mats.append(snow)
	var fall := (radius + 0.26 - 0.04) / 0.8   # the cone's radius lost a unit up
	_drum(w, c, 0.04, radius + 0.26 - fall * 0.08, 0.72, top + 0.2, snow).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_drum(w, c, 0.015, 0.05, 0.2, top + 0.86, iron)
	_drum(w, c, 0.07, 0.07, 0.04, top + 1.04, iron)
	# The front (+z): a dark hatch low down with a plank door, a stone step.
	var fz := c.y + radius
	w._box(Vector3(0.5, 0.62, 0.05), Vector3(c.x, 0.3 + 0.31, fz - 0.03), FarmWorld.flat_material(Color("1a1410")))
	w._box(Vector3(0.44, 0.5, 0.04), Vector3(c.x, 0.3 + 0.28, fz + 0.0), FarmWorld.surface_material("build:planks_dark"))
	w._box(Vector3(0.56, 0.05, 0.05), Vector3(c.x, 0.3 + 0.62, fz + 0.01), timber)
	w._box(Vector3(0.8, 0.06, 0.3), Vector3(c.x, 0.03, fz + 0.2), FarmWorld.flat_material(Color("8a8680")))
	# The loading door high on the +x side, with a small pitched cap, and a ladder of rungs below.
	var sx := c.x + radius
	w._box(Vector3(0.05, 0.5, 0.36), Vector3(sx - 0.02, 1.5, c.y), FarmWorld.flat_material(Color("1a1410")))
	w._box(Vector3(0.05, 0.44, 0.3), Vector3(sx + 0.01, 1.48, c.y), FarmWorld.surface_material("build:planks_dark"))
	w._box(Vector3(0.14, 0.05, 0.46), Vector3(sx + 0.02, 1.8, c.y), timber, Vector3(0, 0, -0.35))
	for z in [c.y - 0.2, c.y + 0.2]:
		w._box(Vector3(0.05, 1.5, 0.05), Vector3(sx + 0.05, 1.0, z), timber)
	for i in 5:
		w._box(Vector3(0.05, 0.04, 0.45), Vector3(sx + 0.05, 0.45 + i * 0.26, c.y), timber)
