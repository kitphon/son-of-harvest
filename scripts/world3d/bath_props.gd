class_name BathProps
extends RefCounted
## The bath lane's own props in 3D (Yumachi, 2026-11-22; docs/DESIGN.md → ที่อาบน้ำ).
## `chimney`: the public bath's tall square chimney (entotsu) at its east wall's front corner, rising well
## over the two-storey roof (its ridge near 3.7) so it reads from the lane: a stone plinth, a
## tapering shaft of weathered render, dark iron bands, a sooty lip and an open top. The flat
## view draws it in MapView.draw_chimney.

const HEIGHT := 5.2          # the top of the lip, world units (a cell is 1)
const SHAFT := Color("8c8174")
const BAND := Color("37302b")
const SOOT := Color("2a2522")


static func chimney(w: FarmWorld, mid: Vector3, snowy: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Four sides: the corners half a facet off +z, so a face looks down +z (Shrine.lathe).
	Shrine.lathe(st, mid, [Vector2(0.5, 0.0), Vector2(0.5, 0.35), Vector2(0.42, 0.42)], 4)   # plinth
	Minka.add_mesh(w, st, Minka.plain(Color(Shrine.STONE)))
	var shaft := SurfaceTool.new()
	shaft.begin(Mesh.PRIMITIVE_TRIANGLES)
	Shrine.lathe(shaft, mid, [Vector2(0.4, 0.42), Vector2(0.27, HEIGHT - 0.25)], 4)
	Minka.add_mesh(w, shaft, Minka.plain(SHAFT))
	# Iron bands round the shaft, each a little proud of it where it stands.
	var bands := SurfaceTool.new()
	bands.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in [1.6, 2.9, 4.1]:
		var r := lerpf(0.4, 0.27, (y - 0.42) / (HEIGHT - 0.25 - 0.42)) + 0.025
		Shrine.lathe(bands, mid, [Vector2(r, y), Vector2(r, y + 0.09)], 4)
	Minka.add_mesh(w, bands, Minka.plain(BAND))
	# The lip at the top, sooty, its mouth a dark hollow inside it.
	var lip := SurfaceTool.new()
	lip.begin(Mesh.PRIMITIVE_TRIANGLES)
	Shrine.lathe(lip, mid, [Vector2(0.27, HEIGHT - 0.25), Vector2(0.33, HEIGHT - 0.2), Vector2(0.33, HEIGHT), Vector2(0.24, HEIGHT), Vector2(0.24, HEIGHT - 0.15)], 4)   # down into the mouth, its floor closed dark
	Minka.add_mesh(w, lip, Minka.plain(SOOT))
	if snowy:
		var snow := SurfaceTool.new()
		snow.begin(Mesh.PRIMITIVE_TRIANGLES)
		Shrine.lathe(snow, mid, [Vector2(0.47, 0.42), Vector2(0.4, 0.47)], 4)
		Shrine.lathe(snow, mid, [Vector2(0.34, HEIGHT), Vector2(0.3, HEIGHT + 0.04), Vector2(0.25, HEIGHT + 0.04)], 4)
		Shrine._snow(w, snow)
