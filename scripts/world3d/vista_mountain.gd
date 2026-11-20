class_name VistaMountain
extends Node3D
## The mountains past the maps in 3D (data/vista.json, VistaRules): a low-poly heightfield of
## faceted triangles over each mountain's area, in the map's own cells (moved by its place on
## the plan, data/world.json). Drawn unshaded with its own light: the sun's direction (Game) on
## each facet's normal over `ambient`, the forest's two tones broken up by a world-locked noise,
## the season's patches (none in spring and fall: data/vista.json), snow above the snow line in
## winter (thick on the gentle slopes, trees through it near the line, blue-grey in shade), and the sky's colour laid over it by its distance from the eye, so the far slopes
## fade into the sky as a real mountain does. From the play camera only its foot shows past the
## south-west edges; the viewpoints (VistaRules.views) turn the camera to see it whole.

const SHADER := """shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 dark : source_color = vec3(0.24, 0.37, 0.23);
uniform vec3 light : source_color = vec3(0.37, 0.54, 0.3);
uniform vec3 accent : source_color = vec3(0.9, 0.7, 0.78);
uniform float accent_share = 0.15;
uniform vec3 snow : source_color = vec3(0.93, 0.95, 0.96);
uniform float snow_line = 10000.0;
uniform vec3 sun_dir = vec3(0.4, 0.8, 0.3);   // toward the sun, world
uniform float ambient = 0.55;
uniform vec3 sky : source_color = vec3(0.7, 0.8, 0.9);
uniform vec3 haze = vec3(24.0, 150.0, 0.6);   // near, far, most
uniform vec3 foot_color : source_color = vec3(0.4, 0.6, 0.3);   // the open grass at its feet (darkened)
uniform float foot_blend = 3.0;   // units up the slope over which it turns from that grass to the forest
varying vec3 world;
varying vec3 wn;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 q = world.xz;
	float n = noise(q * 0.35) * 0.45 + noise(q * 1.1 + 4.1) * 0.3 + noise(q * 3.2 + 9.7) * 0.25;   // clumps of trees, crowns in them
	vec3 c = mix(dark, light, smoothstep(0.3, 0.72, n));
	float a = noise(q * 0.18 + 17.0) * 0.45 + noise(q * 1.6 + 3.0) * 0.55;   // scattered trees, more in some stands
	c = mix(c, accent, step(1.0 - accent_share, a) * 0.8);
	float jag = (noise(q * 0.3) - 0.5) * 3.0;
	c = mix(foot_color, c, smoothstep(0.0, foot_blend, world.y));   // grass at the foot, woods up the slope
	float sun = max(dot(normalize(wn), normalize(sun_dir)), 0.0);
	c *= ambient + (1.0 - ambient) * sun;
	// Snow: a soft line, thick on the gentle slopes and thin on the steep faces, the trees showing
	// dark through it near the line; lit by the sun, blue-grey in shade (not the forest's light).
	float line = snow_line + jag;
	float cover = smoothstep(line - 1.0, line + 2.0, world.y) * mix(0.35, 1.0, smoothstep(0.55, 0.85, normalize(wn).y));
	float trees = smoothstep(0.55, 0.7, noise(q * 2.4 + 3.3)) * (1.0 - smoothstep(line + 3.0, line + 10.0, world.y));
	cover *= 1.0 - trees * 0.6;
	vec3 lit_snow = snow * mix(vec3(0.7, 0.76, 0.88), vec3(1.0), 0.35 + 0.65 * sun);
	c = mix(c, lit_snow, cover);
	float d = length(world - CAMERA_POSITION_WORLD);
	c = mix(c, sky, smoothstep(haze.x, haze.y, d) * haze.z);
	ALBEDO = c;
}
"""

static var _shader: Shader
static var _kept := {}   # "<map id>|<mountain>" -> its mesh: the same map's mountains are the same all run

var mat: ShaderMaterial
var floor_mat: ShaderMaterial   # the open land's grass (floor_material); FarmWorld sets its snow cover
var tint_mat: ShaderMaterial    # the grass darkening toward the mountains' feet, laid over it (multiplied)


var _map_id := ""
var _at := Vector2.ZERO


## Builds the mountains for map `map_id`, whose top-left corner lies at `at` on the plan: begin,
## then every mountain (FarmWorld and MapWorld lay them a build step each instead, so a new map
## never stalls a frame on all of them at once).
func build(map_id: String, at: Vector2i) -> void:
	begin(map_id, at)
	for i in count():
		add_part(i)


## The node and its materials, no mountain yet.
func begin(map_id: String, at: Vector2i) -> void:
	name = "Vista"
	_map_id = map_id
	_at = Vector2(at)
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	mat = ShaderMaterial.new()
	mat.shader = _shader
	floor_mat = floor_material()
	if _tint_shader == null:
		_tint_shader = Shader.new()
		_tint_shader.code = TINT_SHADER
	tint_mat = ShaderMaterial.new()
	tint_mat.shader = _tint_shader
	refresh()


## How many mountains there are (data/vista.json).
static func count() -> int:
	return VistaRules.config().get("mountains", []).size()


## Lays mountain `i` (its mesh kept a run for this map).
func add_part(i: int) -> void:
	var key := "%s|%d" % [_map_id, i]
	if not _kept.has(key):
		_kept[key] = mesh_of(VistaRules.config().mountains[i], _at, VistaRules.clear_rects(), MapManager.data(_map_id))
	var mesh: ArrayMesh = _kept[key]
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	for k in mesh.get_surface_count():
		var surface := mesh.surface_get_name(k)
		var m: Material = mat
		match surface:
			"floor", "banks":
				m = floor_mat
			"tint":
				m = tint_mat
			"bed":
				m = bed_material()
			"walls":
				m = wall_material()
		mi.set_surface_override_material(k, m)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 4.0
	add_child(mi)


## Works out every mountain's own shape ahead (_grid_of: the same from every map), so the first
## map built pays only for its own open land. Main3D calls it behind the first black.
static func warm() -> void:
	var rects := VistaRules.clear_rects()
	for m: Dictionary in VistaRules.config().get("mountains", []):
		_grid_of(m, rects)


func _ready() -> void:
	Game.minute_passed.connect(refresh)
	Game.day_started.connect(refresh)


const FLOOR := -0.05   # the open land between the land past a map's edges and the mountains
const GRASS_CELLS := 8   # the floor's grass picture: this many cells square, repeated

const TINT_REACH := 12.0   # cells from the mountains' feet over which the grass darkens toward the woods
const TINT_SHADER := """shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 tint : source_color = vec3(0.6, 0.75, 0.58);
uniform float cover = 0.0;   // the world's snow: a snowy field is white to the trees
void fragment() {
	ALBEDO = mix(vec3(1.0), tint, COLOR.r * (1.0 - clamp(cover * 1.5, 0.0, 1.0)));
}
"""

static var _tint_shader: Shader
static var _floor_tex: Texture2D
static var _grass_avg := Color(0.45, 0.65, 0.3)   # the grass picture's average colour
static var _floor_mask: Texture2D


static var _bed_mat: ShaderMaterial
static var _wall_mat: Material


## The stone walls of the river past the apron: the map's own banks' (SunkenGround).
static func wall_material() -> Material:
	if _wall_mat == null:
		_wall_mat = SunkenGround.bank_material()
	return _wall_mat


## The river's bed past the land beyond the edges: the water tile's picture repeated, holding no
## snow, under Surroundings' moving skin (as the map's own water cells are).
static func bed_material() -> ShaderMaterial:
	if _bed_mat == null:
		var img := Image.create(GRASS_CELLS * 16, GRASS_CELLS * 16, false, Image.FORMAT_RGBA8)
		var tile := PlaceholderArt.image("ground:water:0")
		for y in GRASS_CELLS:
			for x in GRASS_CELLS:
				img.blit_rect(tile, Rect2i(0, 0, 16, 16), Vector2i(x, y) * 16)
		var mask := Image.create(1, 1, false, Image.FORMAT_L8)
		mask.fill(Color.BLACK)   # water holds no snow
		_bed_mat = SnowLayer.ground_material(ImageTexture.create_from_image(img), ImageTexture.create_from_image(mask))
	return _bed_mat


## The floor's ground material: SnowLayer's ground shader on a repeated picture of the grass tiles
## the land past the edges is laid with, so it lights, wets and takes snow as that land does (a
## shader of its own read as a dark band against the grass: the user's word). One per world, so
## the world's snow cover reaches it (FarmWorld._snow_mats).
static func floor_material() -> ShaderMaterial:
	if _floor_tex == null:
		var img := Image.create(GRASS_CELLS * 16, GRASS_CELLS * 16, false, Image.FORMAT_RGBA8)
		for y in GRASS_CELLS:
			for x in GRASS_CELLS:
				var tile := PlaceholderArt.image("ground:grass:%d" % posmod(x * 7 + y * 13 + (x * y) % 5, PlaceholderArt.GROUND_VARIANTS))
				img.blit_rect(tile, Rect2i(0, 0, 16, 16), Vector2i(x, y) * 16)
		_floor_tex = ImageTexture.create_from_image(img)
		var sum := Vector3.ZERO
		for y in img.get_height():
			for x in img.get_width():
				var px := img.get_pixel(x, y)
				sum += Vector3(px.r, px.g, px.b)
		sum /= float(img.get_width() * img.get_height())
		_grass_avg = Color(sum.x, sum.y, sum.z)
		var mask := Image.create(1, 1, false, Image.FORMAT_L8)
		mask.fill(Color.WHITE)   # grass holds snow fully (data/snow_cover.json)
		_floor_mask = ImageTexture.create_from_image(mask)
	return SnowLayer.ground_material(_floor_tex, _floor_mask)


## Does the land past `map`'s edges (Surroundings) stop before cell point `c` (the map's cells)?
## It runs on Backdrop.rim() cells past the back (west, north) edges on a map with the far country,
## Surroundings.MARGIN past the others; the floor starts a cell short of that, under its end, so
## no gap shows between them. Never at a corner of the river carried on past that land
## (river_of): its banks lie over the land beside it (_add_river).
static func floor_at(map: MapData, c: Vector2, back := -1.0) -> bool:
	if back < 0.0:
		back = floor_back(map)
	var front := float(Surroundings.MARGIN) - 1.0
	if not (c.x < -back or c.y < -back or c.x > map.w + front or c.y > map.h + front):
		return false
	var river := river_of(map)
	var p := Vector2i(floori(c.x), floori(c.y))
	return not (river.has(p) or river.has(p + Vector2i.LEFT) or river.has(p + Vector2i.UP) or river.has(p - Vector2i.ONE))


static var _rivers := {}   # map id -> {cell: true} of VistaRules.far_river, the plan does not change in a run


## The water cells of `map` carried on past its apron (VistaRules.far_river), as a set.
static func river_of(map: MapData) -> Dictionary:
	if not _rivers.has(map.id):
		var cells := {}
		for c in VistaRules.far_river(map, Surroundings.MARGIN):
			cells[c] = true
		_rivers[map.id] = cells
	return _rivers[map.id]


## How far past `map`'s back (west, north) edges its land runs, less a cell (floor_at). Asked once
## a map: Backdrop.on_map reads its file each time (asked at every point it cost a second a mountain).
static func floor_back(map: MapData) -> float:
	var far := Backdrop.on_map(map.id) and not VistaRules.on_map(map.id)   # FarmWorld.add_surroundings' rule
	return float(Backdrop.rim() if far else Surroundings.MARGIN) - 1.0


## The heightfield of mountain `m` over its area, faceted (each triangle its own normal), moved
## by -`at`; its foot never dips under the open land (FLOOR). With `map` given, the open land at
## its feet as two more surfaces: "floor", the grass where the map's own land past its edges
## stops (floor_at), so the tilted view never looks into a gap between that land and the
## mountains, and "tint", its darkening toward the feet. The mountain itself is the same from
## every map (_grid_of, kept a run, moved by -`at`); only the open land is the map's. Built from
## packed arrays and the open land's flat runs merged into long quads: built point by point with a
## SurfaceTool for every map it stalled the game a second or more on each new map (2026-11-15).
static func mesh_of(m: Dictionary, at: Vector2, rects: Array[Rect2], map: MapData = null) -> ArrayMesh:
	var g := _grid_of(m, rects)
	var mesh := ArrayMesh.new()
	var off := Vector3(at.x, 0, at.y)
	var rv: PackedVector3Array = g.rv
	if not rv.is_empty():
		var verts := PackedVector3Array()
		verts.resize(rv.size())
		for n in rv.size():
			verts[n] = rv[n] - off
		_add(mesh, "mountain", verts, g.rn)
	if map != null:
		_add_open_land(mesh, g, at, map)
		if str(m.id) == str(VistaRules.config().mountains[0].id):   # once a map, not once a mountain
			_add_river(mesh, map)
	return mesh


static var _grids := {}   # mountain id -> its grid (_grid_of), the same from every map


## Mountain `m`'s grid over its area, kept a run: {cols, rows, ox, oz, s, rise: each point's
## height (FLOOR where it does not rise), up: whether it rises, near: cells to where it rises (a
## chamfer), rv / rn: the rising quads' triangles and their normals, in plan cells}.
static func _grid_of(m: Dictionary, rects: Array[Rect2]) -> Dictionary:
	if _grids.has(m.id):
		return _grids[m.id]
	var area: Array = m.area
	var s := float(m.step)
	var cols := int(ceil((float(area[2]) - float(area[0])) / s)) + 1
	var rows := int(ceil((float(area[3]) - float(area[1])) / s)) + 1
	var ox := float(area[0])
	var oz := float(area[1])
	var sink := float(m.sink)
	var rise := PackedFloat32Array()
	rise.resize(cols * rows)
	var up := PackedByteArray()
	up.resize(cols * rows)
	var near := PackedFloat32Array()
	near.resize(cols * rows)
	for j in rows:
		for i in cols:
			var n := j * cols + i
			var h := VistaRules.height(m, Vector2(ox + i * s, oz + j * s), rects)
			up[n] = 1 if h > 0.05 else 0
			rise[n] = maxf(h - sink, FLOOR) if h > 0.05 else FLOOR
			near[n] = 0.0 if h > 0.05 else INF
	for pass_i in 2:   # how near each point is to where the mountain rises: the grass darkens toward it
		var d := -1 if pass_i == 0 else 1
		for jj in rows:
			var j := jj if pass_i == 0 else rows - 1 - jj
			for ii in cols:
				var i := ii if pass_i == 0 else cols - 1 - ii
				var n := j * cols + i
				var best := near[n]
				if i + d >= 0 and i + d < cols:
					best = minf(best, near[n + d] + s)
				if j + d >= 0 and j + d < rows:
					best = minf(best, near[n + d * cols] + s)
					if i + d >= 0 and i + d < cols:
						best = minf(best, near[n + d * cols + d] + s * 1.414)
				near[n] = best
	var rv := PackedVector3Array()
	var rn := PackedVector3Array()
	for j in rows - 1:
		for i in cols - 1:
			var k := [j * cols + i, j * cols + i + 1, (j + 1) * cols + i + 1, (j + 1) * cols + i]
			if up[k[0]] == 0 and up[k[1]] == 0 and up[k[2]] == 0 and up[k[3]] == 0:
				continue
			var v := [Vector3(ox + i * s, rise[k[0]], oz + j * s), Vector3(ox + (i + 1) * s, rise[k[1]], oz + j * s),
				Vector3(ox + (i + 1) * s, rise[k[2]], oz + (j + 1) * s), Vector3(ox + i * s, rise[k[3]], oz + (j + 1) * s)]
			for tri in [[0, 1, 2], [0, 2, 3]]:
				var a: Vector3 = v[tri[0]]
				var b: Vector3 = v[tri[1]]
				var c: Vector3 = v[tri[2]]
				var nrm := (c - a).cross(b - a).normalized()
				if nrm.y < 0.0:
					nrm = -nrm
				rv.append_array([a, b, c])
				rn.append_array([nrm, nrm, nrm])
	var g := {"cols": cols, "rows": rows, "ox": ox, "oz": oz, "s": s, "rise": rise, "up": up, "near": near, "rv": rv, "rn": rn}
	_grids[m.id] = g
	return g


const NONE_Y := -1.6   # a point of the open land under the map's own land: sloped away under it
const LAND_Y := -0.02   # the land past the edges (Surroundings' apron), the banks of the river carried on past it
const BANK_ROWS := 2   # cells of land laid either side of that river, over the open land's slope down under it


## The open land of grid `g` for `map` (at `at` on the plan): the grass quads, a flat run of quads
## all past the map's land merged into one, the ones at that land's end sloped under it; and the
## darkening quads where the grass nears the mountain.
static func _add_open_land(mesh: ArrayMesh, g: Dictionary, at: Vector2, map: MapData) -> void:
	var cols: int = g.cols
	var rows: int = g.rows
	var s: float = g.s
	var ox: float = g.ox - at.x
	var oz: float = g.oz - at.y
	var up: PackedByteArray = g.up
	var near: PackedFloat32Array = g.near
	var back := floor_back(map)
	var open := PackedByteArray()
	open.resize(cols * rows)
	for j in rows:
		for i in cols:
			var n := j * cols + i
			open[n] = 1 if up[n] == 0 and floor_at(map, Vector2(ox + i * s, oz + j * s), back) else 0
	var fv := PackedVector3Array()
	var fuv := PackedVector2Array()
	var tv := PackedVector3Array()
	var tc := PackedColorArray()
	var y_of := func(n: int) -> float: return FLOOR if open[n] == 1 or up[n] == 1 else NONE_Y
	for j in rows - 1:
		var run := -1   # the first quad of a run of all-open quads
		for i in cols:
			var all_open := false
			var any_open := false
			var rises := false
			if i < cols - 1:
				var k := [j * cols + i, j * cols + i + 1, (j + 1) * cols + i + 1, (j + 1) * cols + i]
				all_open = open[k[0]] == 1 and open[k[1]] == 1 and open[k[2]] == 1 and open[k[3]] == 1
				any_open = open[k[0]] == 1 or open[k[1]] == 1 or open[k[2]] == 1 or open[k[3]] == 1
				rises = up[k[0]] == 1 or up[k[1]] == 1 or up[k[2]] == 1 or up[k[3]] == 1
				# The darkening, quad by quad, only where the grass nears the mountain.
				if any_open and not rises:
					var w := [0.0, 0.0, 0.0, 0.0]
					var most := 0.0
					for q in 4:
						w[q] = 1.0 - smoothstep(0.0, TINT_REACH, near[k[q]])
						most = maxf(most, w[q])
					if most > 0.01:
						var v := _quad_corners(ox, oz, s, i, j, [y_of.call(k[0]), y_of.call(k[1]), y_of.call(k[2]), y_of.call(k[3])])
						for q in [0, 1, 2, 0, 2, 3]:
							tv.append(v[q] + Vector3(0, 0.004, 0))
							tc.append(Color(w[q], w[q], w[q]))
			if all_open and not rises:
				if run < 0:
					run = i
				continue
			if run >= 0:   # a run of open quads ends: one long quad
				var v := [Vector3(ox + run * s, FLOOR, oz + j * s), Vector3(ox + i * s, FLOOR, oz + j * s),
					Vector3(ox + i * s, FLOOR, oz + (j + 1) * s), Vector3(ox + run * s, FLOOR, oz + (j + 1) * s)]
				_put_floor(fv, fuv, v)
				run = -1
			if i < cols - 1 and any_open and not rises:   # at the land's end, and by the river: sloped under it
				var k := [j * cols + i, j * cols + i + 1, (j + 1) * cols + i + 1, (j + 1) * cols + i]
				_put_floor(fv, fuv, _quad_corners(ox, oz, s, i, j, [y_of.call(k[0]), y_of.call(k[1]), y_of.call(k[2]), y_of.call(k[3])]))
	if not fv.is_empty():
		var fn := PackedVector3Array()
		fn.resize(fv.size())
		fn.fill(Vector3.UP)
		_add(mesh, "floor", fv, fn, fuv)
		if not tv.is_empty():
			var tn := PackedVector3Array()
			tn.resize(tv.size())
			tn.fill(Vector3.UP)
			_add(mesh, "tint", tv, tn, PackedVector2Array(), tc)


## The river carried on past the land beyond `map`'s edges (river_of), cell by cell as that land
## lays the map's own: its bed DROP below the land under Surroundings' skin, a stone wall where it
## meets land (and across its far end), and BANK_ROWS cells of grass either side at the land's
## height, over the open land's slope down under it, so its banks run on level with the stone
## banks before them (a 2-cell slope there read as ground at another level: the user's word).
static func _add_river(mesh: ArrayMesh, map: MapData) -> void:
	var river := river_of(map)
	if river.is_empty():
		return
	var apron := Rect2i(-Surroundings.MARGIN, -Surroundings.MARGIN, map.w + Surroundings.MARGIN * 2, map.h + Surroundings.MARGIN * 2)
	var bed_y := LAND_Y - SunkenGround.DROP
	var bv := PackedVector3Array()
	var buv := PackedVector2Array()
	var land := {}
	var wv := PackedVector3Array()
	var wn := PackedVector3Array()
	for c: Vector2i in river:
		_put_floor(bv, buv, [Vector3(c.x, bed_y, c.y), Vector3(c.x + 1, bed_y, c.y), Vector3(c.x + 1, bed_y, c.y + 1), Vector3(c.x, bed_y, c.y + 1)])
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if river.has(n) or apron.has_point(n):
				continue   # more river, or the apron's own (Surroundings lays it)
			for k in BANK_ROWS:
				land[n + d * k] = true
			_river_wall(wv, wn, c, d, bed_y)
	var lv := PackedVector3Array()
	var luv := PackedVector2Array()
	for c: Vector2i in land:
		if river.has(c) or apron.has_point(c):
			continue
		_put_floor(lv, luv, [Vector3(c.x, LAND_Y, c.y), Vector3(c.x + 1, LAND_Y, c.y), Vector3(c.x + 1, LAND_Y, c.y + 1), Vector3(c.x, LAND_Y, c.y + 1)])
	for part in [["bed", bv, buv], ["banks", lv, luv]]:
		var verts: PackedVector3Array = part[1]
		if verts.is_empty():
			continue
		var nn := PackedVector3Array()
		nn.resize(verts.size())
		nn.fill(Vector3.UP)
		_add(mesh, part[0], verts, nn, part[2])
	if not wv.is_empty():
		_add(mesh, "walls", wv, wn)


## A stone wall on side `d` of river cell `c`, from the land down to the bed, facing into the water.
static func _river_wall(wv: PackedVector3Array, wn: PackedVector3Array, c: Vector2i, d: Vector2i, bed_y: float) -> void:
	var a: Vector3
	var b: Vector3
	match d:
		Vector2i.UP:
			a = Vector3(c.x + 1, 0, c.y)
			b = Vector3(c.x, 0, c.y)
		Vector2i.DOWN:
			a = Vector3(c.x, 0, c.y + 1)
			b = Vector3(c.x + 1, 0, c.y + 1)
		Vector2i.LEFT:
			a = Vector3(c.x, 0, c.y)
			b = Vector3(c.x, 0, c.y + 1)
		_:
			a = Vector3(c.x + 1, 0, c.y + 1)
			b = Vector3(c.x + 1, 0, c.y)
	var top := Vector3(0, LAND_Y, 0)
	var low := Vector3(0, bed_y, 0)
	for p in [a + top, b + top, b + low, a + top, b + low, a + low]:
		wv.append(p)
		wn.append(-Vector3(d.x, 0, d.y))


static func _quad_corners(ox: float, oz: float, s: float, i: int, j: int, ys: Array) -> Array:
	return [Vector3(ox + i * s, ys[0], oz + j * s), Vector3(ox + (i + 1) * s, ys[1], oz + j * s),
		Vector3(ox + (i + 1) * s, ys[2], oz + (j + 1) * s), Vector3(ox + i * s, ys[3], oz + (j + 1) * s)]


static func _put_floor(fv: PackedVector3Array, fuv: PackedVector2Array, v: Array) -> void:
	for q in [0, 1, 2, 0, 2, 3]:
		var p: Vector3 = v[q]
		fv.append(p)
		fuv.append(Vector2(p.x, p.z) / float(GRASS_CELLS))


## Adds a named surface of triangles to `mesh`.
static func _add(mesh: ArrayMesh, name: String, verts: PackedVector3Array, normals: PackedVector3Array, uvs := PackedVector2Array(), colors := PackedColorArray()) -> void:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	if not uvs.is_empty():
		arr[Mesh.ARRAY_TEX_UV] = uvs
	if not colors.is_empty():
		arr[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_name(mesh.get_surface_count() - 1, name)


## Tones it for Game's clock, weather and season.
func refresh() -> void:
	tone(Game.season_name(), Game.sky_color(), -Game.sun_direction(Game.sun_light()))


func tone(season_id: String, sky: Color, to_sun: Vector3) -> void:
	var cfg := VistaRules.config()
	var c: Dictionary = cfg.colors.get(season_id, cfg.colors.values()[0])
	mat.set_shader_parameter("dark", Color(str(c.dark)))
	var foot := Color(str(c.get("foot", "9abf8e")))
	if tint_mat != null:
		tint_mat.set_shader_parameter("tint", foot)
	mat.set_shader_parameter("foot_color", Color(_grass_avg.r * foot.r, _grass_avg.g * foot.g, _grass_avg.b * foot.b))   # where the darkened grass ends
	mat.set_shader_parameter("foot_blend", float(cfg.get("foot_blend", 3.0)))
	mat.set_shader_parameter("light", Color(str(c.light)))
	mat.set_shader_parameter("accent", Color(str(c.accent)))
	mat.set_shader_parameter("accent_share", float(c.accent_share))
	mat.set_shader_parameter("snow", Color(str(cfg.snow)))
	var top := 0.0
	for m in cfg.mountains:
		top = maxf(top, VistaRules.peak(m))
	mat.set_shader_parameter("snow_line", top * float(c.snow_line) if float(c.snow_line) < 1.0 else 10000.0)
	mat.set_shader_parameter("sun_dir", to_sun if to_sun.y > 0.05 else Vector3(0.2, 1.0, 0.2))
	mat.set_shader_parameter("ambient", float(cfg.ambient))
	mat.set_shader_parameter("sky", sky)
	var hz: Array = cfg.haze
	mat.set_shader_parameter("haze", Vector3(float(hz[0]), float(hz[1]), float(hz[2])))
