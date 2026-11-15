class_name VistaMountain
extends Node3D
## The mountains past the maps in 3D (data/vista.json, VistaRules): a low-poly heightfield of
## faceted triangles over each mountain's area, in the map's own cells (moved by its place on
## the plan, data/world.json). Drawn unshaded with its own light: the sun's direction (Game) on
## each facet's normal over `ambient`, the forest's two tones broken up by a world-locked noise,
## the season's patches (spring's wild cherry, fall's maples), snow above the snow line in
## winter, and the sky's colour laid over it by its distance from the eye, so the far slopes
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
	if (world.y > snow_line + jag) { c = mix(c, snow, 0.85); }
	float lit = ambient + (1.0 - ambient) * max(dot(normalize(wn), normalize(sun_dir)), 0.0);
	c *= lit;
	float d = length(world - CAMERA_POSITION_WORLD);
	c = mix(c, sky, smoothstep(haze.x, haze.y, d) * haze.z);
	ALBEDO = c;
}
"""

static var _shader: Shader
static var _kept := {}   # mesh by map id: the same map's mountains are the same all run

var mat: ShaderMaterial
var floor_mat: ShaderMaterial   # the open land's grass (floor_material); FarmWorld sets its snow cover
var tint_mat: ShaderMaterial    # the grass darkening toward the mountains' feet, laid over it (multiplied)


## Builds the mountains for map `map_id`, whose top-left corner lies at `at` on the plan.
func build(map_id: String, at: Vector2i) -> void:
	name = "Vista"
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	mat = ShaderMaterial.new()
	mat.shader = _shader
	if not _kept.has(map_id):
		_kept[map_id] = _make(Vector2(at), MapManager.data(map_id))
	floor_mat = floor_material()
	if _tint_shader == null:
		_tint_shader = Shader.new()
		_tint_shader.code = TINT_SHADER
	tint_mat = ShaderMaterial.new()
	tint_mat.shader = _tint_shader
	for mesh: ArrayMesh in _kept[map_id]:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		for i in mesh.get_surface_count():
			var surface := mesh.surface_get_name(i)
			mi.set_surface_override_material(i, floor_mat if surface == "floor" else tint_mat if surface == "tint" else mat)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 4.0
		add_child(mi)
	refresh()


func _ready() -> void:
	Game.minute_passed.connect(refresh)
	Game.day_started.connect(refresh)


## One mesh per mountain, in the map's cells (the plan's moved by -`at`), its flat land laid as
## forest floor where `map`'s own land past its edges stops.
static func _make(at: Vector2, map: MapData) -> Array[ArrayMesh]:
	var out: Array[ArrayMesh] = []
	var rects := VistaRules.clear_rects()   # the maps and the water running off them
	for m: Dictionary in VistaRules.config().get("mountains", []):
		out.append(mesh_of(m, at, rects, map))
	return out


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
## no gap shows between them. Never over water running on off an edge (it stays the river's).
static func floor_at(map: MapData, c: Vector2) -> bool:
	var far := Backdrop.on_map(map.id) and not VistaRules.on_map(map.id)   # FarmWorld.add_surroundings' rule
	var back := float(Backdrop.rim() if far else Surroundings.MARGIN) - 1.0
	var front := float(Surroundings.MARGIN) - 1.0
	var past := c.x < -back or c.y < -back or c.x > map.w + front or c.y > map.h + front
	if not past:
		return false
	var edge := Surroundings.edge_cell(Vector2i(floori(c.x), floori(c.y)), map.w, map.h)
	return map.tile(edge) != "water"


## The heightfield of mountain `m` over its area, faceted (each triangle its own normal), moved
## by -`at`; points where it does not rise sit `sink` under the land, or with `map` given lie as
## forest floor (FLOOR) where its land past the edges stops (floor_at), so the tilted view never
## looks down into a gap between that land and the mountains.
static func mesh_of(m: Dictionary, at: Vector2, rects: Array[Rect2], map: MapData = null) -> ArrayMesh:
	var area: Array = m.area
	var s := float(m.step)
	var cols := int(ceil((float(area[2]) - float(area[0])) / s)) + 1
	var rows := int(ceil((float(area[3]) - float(area[1])) / s)) + 1
	var sink := float(m.sink)
	var hs := PackedFloat32Array()
	hs.resize(cols * rows)
	for j in rows:
		for i in cols:
			var p := Vector2(float(area[0]) + i * s, float(area[1]) + j * s)
			var h := VistaRules.height(m, p, rects)
			var open := map != null and floor_at(map, p - at)
			if h > 0.05:
				hs[j * cols + i] = maxf(h - sink, FLOOR) if open else h - sink   # its foot rises from the open land, no dip under it
			elif open:
				hs[j * cols + i] = FLOOR
			else:
				hs[j * cols + i] = -sink - 1.0
	# How near each point is to where the mountain rises (cells, a chamfer over the grid): the
	# open land darkens toward its feet over TINT_REACH.
	var near := PackedFloat32Array()
	near.resize(cols * rows)
	for n in cols * rows:
		near[n] = 0.0 if hs[n] > FLOOR + 0.01 else INF
	for pass_i in 2:
		var js := range(rows) if pass_i == 0 else range(rows - 1, -1, -1)
		var is_ := range(cols) if pass_i == 0 else range(cols - 1, -1, -1)
		var d := -1 if pass_i == 0 else 1
		for j in js:
			for i in is_:
				var n: int = j * cols + i
				var best := near[n]
				if i + d >= 0 and i + d < cols:
					best = minf(best, near[n + d] + s)
				if j + d >= 0 and j + d < rows:
					best = minf(best, near[n + d * cols] + s)
					if i + d >= 0 and i + d < cols:
						best = minf(best, near[n + d * cols + d] + s * 1.414)
				near[n] = best
	var tt := SurfaceTool.new()   # the darkening over the open land
	tt.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st := SurfaceTool.new()   # the mountain: the forest's shader
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gt := SurfaceTool.new()   # the open land at its foot: the ground's own grass (floor_material)
	gt.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grass := false
	var forest := false
	for j in rows - 1:
		for i in cols - 1:
			var k := [j * cols + i, j * cols + i + 1, (j + 1) * cols + i + 1, (j + 1) * cols + i]
			if hs[k[0]] < -sink and hs[k[1]] < -sink and hs[k[2]] < -sink and hs[k[3]] < -sink:
				continue   # flat ground under the land: nothing to draw
			var rises := false
			for n in 4:
				rises = rises or hs[k[n]] > FLOOR + 0.01
			var v: Array[Vector3] = []
			for n in 4:
				var ii := i + (1 if n == 1 or n == 2 else 0)
				var jj := j + (1 if n >= 2 else 0)
				v.append(Vector3(float(area[0]) + ii * s - at.x, hs[k[n]], float(area[1]) + jj * s - at.y))
			var to: SurfaceTool = st if rises else gt
			if rises:
				forest = true
			else:
				grass = true
				for tri in [[0, 1, 2], [0, 2, 3]]:
					for q in tri:
						var w := 1.0 - smoothstep(0.0, TINT_REACH, near[k[q]])
						tt.set_color(Color(w, w, w))
						tt.set_normal(Vector3.UP)
						tt.add_vertex(v[q] + Vector3(0, 0.004, 0))
			for tri in [[0, 1, 2], [0, 2, 3]]:
				var a: Vector3 = v[tri[0]]
				var b: Vector3 = v[tri[1]]
				var c: Vector3 = v[tri[2]]
				var nrm := (c - a).cross(b - a).normalized()
				if nrm.y < 0.0:
					nrm = -nrm
				for p in [a, b, c]:
					to.set_normal(nrm)
					to.set_uv(Vector2(p.x, p.z) / float(GRASS_CELLS))
					to.add_vertex(p)
	var mesh := ArrayMesh.new()
	if forest:
		st.commit(mesh)
	if grass:
		gt.commit(mesh)
		mesh.surface_set_name(mesh.get_surface_count() - 1, "floor")
		tt.commit(mesh)
		mesh.surface_set_name(mesh.get_surface_count() - 1, "tint")
	return mesh


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
