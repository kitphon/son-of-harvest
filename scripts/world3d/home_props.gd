class_name HomeProps
extends RefCounted
## The furniture of the villagers' homes in 3D (data/maps/tome_house.json, kota_house.json,
## sayo_house.json): a sunken hearth, the alcove, a family altar, cushions, a folding screen,
## a toy box and a water jar. Same placeholder surfaces and units as MapWorld (1 unit = 1
## cell); things that stand against the back wall sit towards -z.

const TIMBER := Color("2e221a")
const KINDS: Array[String] = ["irori", "tokonoma", "butsudan", "zabuton", "byobu", "toy_box", "mizugame"]


## A home prop by its kind (MapWorld calls this).
static func prop(w: FarmWorld, p: Dictionary, mid: Vector3, r: Rect2) -> void:
	var timber := FarmWorld.flat_material(TIMBER)
	match str(p.kind):
		"irori":
			# A square hearth sunk in the floor: a dark wooden frame round grey ash, glowing
			# charcoal, and an iron kettle hanging over it from a hook pole out of the roof.
			var side := minf(r.size.x, r.size.y) - 0.3
			for o in [Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(1, 0, 0)]:
				var along_x: bool = o.x == 0
				var size := Vector3(side + 0.12, 0.07, 0.12) if along_x else Vector3(0.12, 0.07, side + 0.12)
				w._box(size, mid + o * (side / 2) + Vector3(0, 0.035, 0), FarmWorld.surface_material("build:planks_dark"))
			w._box(Vector3(side - 0.1, 0.02, side - 0.1), mid + Vector3(0, 0.02, 0), FarmWorld.flat_material(Color("8a847a")))
			for o in [Vector3(-0.12, 0, 0.05), Vector3(0.1, 0, -0.08), Vector3(0.02, 0, 0.14)]:
				w._box(Vector3(0.16, 0.05, 0.08), mid + o + Vector3(0, 0.05, 0), FarmWorld.flat_material(Color("ff7a2a")))
			w._box(Vector3(0.04, 1.3, 0.04), mid + Vector3(0, 1.15, 0), timber)   # the hook pole (jizai-kagi)
			w._box(Vector3(0.22, 0.05, 0.06), mid + Vector3(0, 0.95, 0), FarmWorld.surface_material("build:planks"))   # its fish-shaped catch
			var kettle := CylinderMesh.new()
			kettle.top_radius = 0.13
			kettle.bottom_radius = 0.17
			kettle.height = 0.2
			kettle.radial_segments = 12
			var mi := MeshInstance3D.new()
			mi.mesh = kettle
			mi.material_override = FarmWorld.flat_material(Color("2a2624"))
			mi.position = mid + Vector3(0, 0.42, 0)
			w.add_child(mi)
			w._box(Vector3(0.08, 0.06, 0.04), mid + Vector3(0.18, 0.46, 0), FarmWorld.flat_material(Color("2a2624")))   # spout
		"tokonoma":
			# The alcove against the back wall: a raised plank dais, a hanging scroll of ink on
			# pale paper, a rough corner post, and a vase with a branch.
			var at := mid + Vector3(0, 0, -0.15)
			var wide := r.size.x - 0.12
			w._box(Vector3(wide, 0.14, 0.62), at + Vector3(0, 0.07, 0), FarmWorld.surface_material("build:planks"))
			w._box(Vector3(wide, 0.03, 0.04), at + Vector3(0, 0.15, 0.3), timber)
			w._box(Vector3(0.12, 1.7, 0.12), Vector3(r.end.x - 0.08, 0.85, at.z + 0.28), FarmWorld.flat_material(Color("6a4a30")))
			var scroll := Vector3(at.x - wide / 4, 0, at.z - 0.28)
			w._box(Vector3(0.42, 0.9, 0.02), scroll + Vector3(0, 0.95, 0), FarmWorld.flat_material(Color("8a6a3a")))
			w._box(Vector3(0.32, 0.72, 0.03), scroll + Vector3(0, 0.95, 0), FarmWorld.flat_material(Color("ece4cc")))
			for k in 3:
				w._box(Vector3(0.05, 0.14 + 0.05 * k, 0.04), scroll + Vector3(-0.06 + k * 0.06, 1.1 - k * 0.12, 0), FarmWorld.flat_material(Color("1e1a18")))
			w._box(Vector3(0.48, 0.04, 0.04), scroll + Vector3(0, 0.48, 0.01), FarmWorld.flat_material(Color("3a2a1a")))
			var vase := Vector3(at.x + wide / 4, 0, at.z)
			w._box(Vector3(0.14, 0.24, 0.14), vase + Vector3(0, 0.26, 0), FarmWorld.flat_material(Color("4a6a7a")))
			w._box(Vector3(0.03, 0.4, 0.03), vase + Vector3(0.03, 0.55, 0), timber, Vector3(0, 0, -0.3))
			for o in [Vector3(0.12, 0.72, 0), Vector3(0.02, 0.64, 0.02), Vector3(0.16, 0.6, 0)]:
				w._box(Vector3(0.06, 0.06, 0.06), vase + o, FarmWorld.flat_material(Color("f0a8b8")))
		"butsudan":
			# The family altar: a black lacquer cabinet against the back wall, doors open on a
			# gold inside, a candle and a small bowl of rice in front.
			var at := mid + Vector3(0, 0, -0.22)
			var black := FarmWorld.flat_material(Color("1a1616"))
			w._box(Vector3(0.62, 0.5, 0.44), at + Vector3(0, 0.25, 0), black)
			w._box(Vector3(0.62, 0.7, 0.44), at + Vector3(0, 0.85, 0), black)
			w._box(Vector3(0.5, 0.6, 0.02), at + Vector3(0, 0.85, 0.2), FarmWorld.flat_material(Color("c8a040")))
			w._box(Vector3(0.2, 0.3, 0.02), at + Vector3(0, 0.82, 0.21), FarmWorld.flat_material(Color("3a2a1a")))
			for x in [-0.36, 0.36]:
				w._box(Vector3(0.12, 0.64, 0.02), at + Vector3(x, 0.85, 0.28), black, Vector3(0, x * 1.4, 0))
			w._box(Vector3(0.04, 0.12, 0.04), at + Vector3(-0.15, 0.56, 0.18), FarmWorld.flat_material(Color("f4f0e0")))
			w._box(Vector3(0.03, 0.04, 0.03), at + Vector3(-0.15, 0.64, 0.18), FarmWorld.flat_material(Color("ffd060")))
			w._box(Vector3(0.12, 0.06, 0.12), at + Vector3(0.12, 0.53, 0.16), FarmWorld.flat_material(Color("f4f0e8")))
		"zabuton":
			# A flat floor cushion, a darker stitch line round its middle.
			w._box(Vector3(0.6, 0.07, 0.6), mid + Vector3(0, 0.035, 0), FarmWorld.flat_material(Color(str(p.get("color", "8a3a3a")))))
			w._box(Vector3(0.08, 0.075, 0.08), mid + Vector3(0, 0.04, 0), FarmWorld.flat_material(Color("2e221a")))
		"byobu":
			# A folding screen: panels of pale paper in dark frames, standing in a zig-zag.
			var n := int(r.size.x) * 2
			var panel := (r.size.x - 0.2) / n
			for i in n:
				var x := r.position.x + 0.1 + panel * (i + 0.5)
				var z := mid.z - 0.2 + (0.08 if i % 2 == 0 else -0.08)
				var yaw := 0.5 if i % 2 == 0 else -0.5
				w._box(Vector3(panel * 1.08, 1.0, 0.04), Vector3(x, 0.52, z), timber, Vector3(0, yaw, 0))
				w._box(Vector3(panel * 0.92, 0.86, 0.05), Vector3(x, 0.52, z), FarmWorld.flat_material(Color("e8dcb8")), Vector3(0, yaw, 0))
				w._box(Vector3(panel * 0.5, 0.18, 0.06), Vector3(x, 0.4 + 0.12 * (i % 3), z), FarmWorld.flat_material(Color("7a9a6a")), Vector3(0, yaw, 0))
		"toy_box":
			# A child's wooden box of toys: a red spinning top on the lid, a ball beside it,
			# and a paper kite leaning on the wall behind.
			w._box(Vector3(0.7, 0.4, 0.5), mid + Vector3(0, 0.2, -0.1), FarmWorld.surface_material("build:planks"))
			w._box(Vector3(0.74, 0.04, 0.54), mid + Vector3(0, 0.42, -0.1), FarmWorld.surface_material("build:planks_dark"))
			w._box(Vector3(0.14, 0.1, 0.14), mid + Vector3(-0.15, 0.49, -0.05), FarmWorld.flat_material(Color("c8442c")), Vector3(0, 0.78, 0))
			w._box(Vector3(0.03, 0.06, 0.03), mid + Vector3(-0.15, 0.57, -0.05), timber)
			w._box(Vector3(0.16, 0.16, 0.16), mid + Vector3(0.38, 0.08, 0.2), FarmWorld.flat_material(Color("e8c050")))
			w._box(Vector3(0.5, 0.6, 0.02), mid + Vector3(0.1, 0.9, -0.42), FarmWorld.flat_material(Color("f4ecd8")), Vector3(0, 0, 0.15))
			w._box(Vector3(0.22, 0.22, 0.03), mid + Vector3(0.1, 0.95, -0.41), FarmWorld.flat_material(Color("c8442c")), Vector3(0, 0, 0.15))
		"mizugame":
			# A big brown glazed water jar on the earth floor, a wooden lid and a ladle on it.
			var jar := CylinderMesh.new()
			jar.top_radius = 0.26
			jar.bottom_radius = 0.2
			jar.height = 0.55
			jar.radial_segments = 12
			var mi := MeshInstance3D.new()
			mi.mesh = jar
			mi.material_override = FarmWorld.flat_material(Color("6a4028"))
			mi.position = mid + Vector3(0, 0.275, 0)
			w.add_child(mi)
			w._box(Vector3(0.5, 0.04, 0.5), mid + Vector3(0, 0.57, 0), FarmWorld.surface_material("build:planks"))
			w._box(Vector3(0.36, 0.03, 0.04), mid + Vector3(0.05, 0.6, 0.05), FarmWorld.surface_material("build:sugi"), Vector3(0, 0.5, 0))
