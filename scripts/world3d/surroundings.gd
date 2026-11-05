class_name Surroundings
extends Node3D
## The land past an outdoor map's edge, so the camera never looks off the world into empty
## sky: an apron of ground under and round the map whose cells repeat the nearest edge
## cell's kind (grass stays grass, a road or the river runs on out of sight, paddies go on),
## and a wood of pines on the far sides, only where it stands behind the whole map on screen
## (the camera looks in from +x / +z), so it never covers a cell the farmer can reach.
## Snow lies on the apron as on the map (SnowLayer's ground shader, the edge cells' hold).

const MARGIN := 14          # cells of apron round the map (the view reaches ~10 past an edge)
const T := 16
const TREE_SHARE := 45      # % of the allowed cells with a pine
const PINE_SHAPES := 3      # Trees.pine shapes the wood picks from, by cell
const TREE_KINDS: Array[String] = ["grass"]   # ground a pine stands on

var material: ShaderMaterial   # the apron's ground; FarmWorld.set_snow sets its cover
var snow_mats: Array[ShaderMaterial] = []   # the snow on the pines' pads, set with it


## Builds the apron for a w x h map. `kind_at(c)` gives an in-map cell's ground kind
## (grass, path, water...), `hold_at(c)` how much snow it holds (0..1).
func build(w: int, h: int, kind_at: Callable, hold_at: Callable) -> void:
	var cw := w + MARGIN * 2
	var ch := h + MARGIN * 2
	var img := Image.create(cw * T, ch * T, false, Image.FORMAT_RGBA8)
	var mask := Image.create_empty(cw * SnowLayer.MASK_PER_CELL, ch * SnowLayer.MASK_PER_CELL, false, Image.FORMAT_L8)
	for y in range(-MARGIN, h + MARGIN):
		for x in range(-MARGIN, w + MARGIN):
			var c := Vector2i(x, y)   # under the map too: its edge pixels must not show a gap
			var tile := PlaceholderArt.tex(ground_key(kind_at, w, h, c)).get_image()
			tile.convert(Image.FORMAT_RGBA8)
			img.blit_rect(tile, Rect2i(0, 0, T, T), Vector2i(x + MARGIN, y + MARGIN) * T)
			var v: float = hold_at.call(edge_cell(c, w, h))
			var m := SnowLayer.MASK_PER_CELL
			mask.fill_rect(Rect2i((x + MARGIN) * m, (y + MARGIN) * m, m, m), Color(v, v, v))
	material = SnowLayer.ground_material(ImageTexture.create_from_image(img), ImageTexture.create_from_image(mask))
	var plane := PlaneMesh.new()
	plane.size = Vector2(cw, ch)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = material
	ground.position = Vector3(w / 2.0, -0.02, h / 2.0)   # just under the map's ground
	add_child(ground)
	_make_pines(w, h, kind_at)
	_make_tufts(w, h, kind_at, hold_at)


## Grass tufts on the apron's grass (GrassTufts), the edge cell's snow hold under each.
func _make_tufts(w: int, h: int, kind_at: Callable, hold_at: Callable) -> void:
	var cells: Array[Vector2i] = []
	for y in range(-MARGIN, h + MARGIN):
		for x in range(-MARGIN, w + MARGIN):
			var c := Vector2i(x, y)
			if (x < 0 or y < 0 or x >= w or y >= h) and kind_at.call(edge_cell(c, w, h)) == "grass":
				cells.append(c)
	var tufts := GrassTufts.new()
	add_child(tufts)
	snow_mats.append(tufts.snow_material())
	tufts.plant(cells, func(c: Vector2i) -> float: return hold_at.call(edge_cell(c, w, h)))


## The in-map cell nearest `c` (itself when inside).
static func edge_cell(c: Vector2i, w: int, h: int) -> Vector2i:
	return Vector2i(clampi(c.x, 0, w - 1), clampi(c.y, 0, h - 1))


## The ground picture for apron cell `c`: the nearest edge cell's kind, its own variant
## (so the repeat doesn't show), water banks where the stretched kinds meet.
static func ground_key(kind_at: Callable, w: int, h: int, c: Vector2i) -> String:
	var kind: String = kind_at.call(edge_cell(c, w, h))
	if kind == "water":
		var mask := 0
		for side in [[Vector2i.UP, PlaceholderArt.WATER_N], [Vector2i.RIGHT, PlaceholderArt.WATER_E],
				[Vector2i.DOWN, PlaceholderArt.WATER_S], [Vector2i.LEFT, PlaceholderArt.WATER_W]]:
			if kind_at.call(edge_cell(c + side[0], w, h)) != "water":
				mask |= side[1]
		return "ground:water:%d" % mask
	return "ground:%s:%d" % [kind, posmod(c.x * 7 + c.y * 13 + (c.x * c.y) % 5, PlaceholderArt.GROUND_VARIANTS)]


## Does a tall thing at `p` (x, z in cells) stand behind every map cell in its screen column?
## The column is x - z (the camera's right is +x -z), nearness is x + z; the nearest-to-the-
## back map point of column k has nearness |k|. Columns past the map's sides are always fine.
## The margins leave room for a pine's crown (about 0.8 cells round).
static func behind_map(p: Vector2, w: int, h: int) -> bool:
	var k := p.x - p.y
	if k > w + 1.6 or k < -h - 1.6:
		return true
	return p.x + p.y < absf(k) - 0.9


## A pine on apron cell `c`? Off the map, behind it, on grass all round (roads and water
## running out stay clear), and only some cells, picked by the cell so it never changes.
static func pine_at(kind_at: Callable, w: int, h: int, c: Vector2i) -> bool:
	if c.x >= 0 and c.y >= 0 and c.x < w and c.y < h:
		return false
	if not behind_map(Vector2(c) + Vector2(0.5, 0.5), w, h):
		return false
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			if not kind_at.call(edge_cell(c + Vector2i(ox, oy), w, h)) in TREE_KINDS:
				return false
	return posmod(c.x * 92837 + c.y * 68917 + (c.x * c.y) * 31, 100) < TREE_SHARE


## The wood: straight pines (Trees.pine, PINE_SHAPES shapes), each nudged in its cell,
## turned and a little taller or shorter, one MultiMesh per shape and material.
func _make_pines(w: int, h: int, kind_at: Callable) -> void:
	var at := []
	for i in PINE_SHAPES:
		at.append([] as Array[Transform3D])
	for y in range(-MARGIN, h + MARGIN):
		for x in range(-MARGIN, w + MARGIN):
			var c := Vector2i(x, y)
			if not pine_at(kind_at, w, h, c):
				continue
			var r := posmod(c.x * 131 + c.y * 197, 1000) / 1000.0
			var s := 0.85 + 0.45 * r
			var nudge := Vector3(posmod(c.x * 37 + c.y * 11, 7) - 3, 0, posmod(c.x * 17 + c.y * 41, 7) - 3) * 0.08
			var basis := Basis(Vector3.UP, r * TAU).scaled(Vector3(s, s, s))
			at[posmod(c.x * 5 + c.y * 3, PINE_SHAPES)].append(Transform3D(basis, Vector3(x + 0.5, 0, y + 0.5) + nudge))
	for i in PINE_SHAPES:
		if at[i].is_empty():
			continue
		var parts := FarmProps.Parts.new()
		Trees.pine(parts, Vector3.ZERO, 101 + i * 37, false, true)
		var meshes := parts.meshes()
		for key in meshes:
			var mmi := _multi(meshes[key], at[i], FarmProps.Parts.material(key, snow_mats))
			if not FarmProps.Parts.casts_shadow(key):
				mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _multi(mesh: Mesh, at: Array[Transform3D], mat: Material) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = at.size()
	for i in at.size():
		mm.set_instance_transform(i, at[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)
	return mmi
