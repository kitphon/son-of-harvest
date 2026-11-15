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
	for mesh: ArrayMesh in _kept[map_id]:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
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
	var rects := VistaRules.map_rects()
	for m: Dictionary in VistaRules.config().get("mountains", []):
		out.append(mesh_of(m, at, rects, map))
	return out


const FLOOR := -0.05   # the forest floor between the land past a map's edges and the mountains


## Does the land past `map`'s edges (Surroundings) stop before cell point `c` (the map's cells)?
## It runs on Backdrop.rim() cells past the back (west, north) edges on a map with the far country,
## Surroundings.MARGIN past the others; the floor starts a cell short of that, under its end, so
## no gap shows between them. Never over water running on off an edge (it stays the river's).
static func floor_at(map: MapData, c: Vector2) -> bool:
	var back := float(Backdrop.rim() if Backdrop.on_map(map.id) else Surroundings.MARGIN) - 1.0
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
			if h > 0.05:
				hs[j * cols + i] = h - sink
			elif map != null and floor_at(map, p - at):
				hs[j * cols + i] = FLOOR
			else:
				hs[j * cols + i] = -sink - 1.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in rows - 1:
		for i in cols - 1:
			var k := [j * cols + i, j * cols + i + 1, (j + 1) * cols + i + 1, (j + 1) * cols + i]
			if hs[k[0]] < -sink and hs[k[1]] < -sink and hs[k[2]] < -sink and hs[k[3]] < -sink:
				continue   # flat ground under the land: nothing to draw
			var v: Array[Vector3] = []
			for n in 4:
				var ii := i + (1 if n == 1 or n == 2 else 0)
				var jj := j + (1 if n >= 2 else 0)
				v.append(Vector3(float(area[0]) + ii * s - at.x, hs[k[n]], float(area[1]) + jj * s - at.y))
			for tri in [[0, 1, 2], [0, 2, 3]]:
				var a: Vector3 = v[tri[0]]
				var b: Vector3 = v[tri[1]]
				var c: Vector3 = v[tri[2]]
				var nrm := (c - a).cross(b - a).normalized()
				if nrm.y < 0.0:
					nrm = -nrm
				for p in [a, b, c]:
					st.set_normal(nrm)
					st.add_vertex(p)
	return st.commit()


## Tones it for Game's clock, weather and season.
func refresh() -> void:
	tone(Game.season_name(), Game.sky_color(), -Game.sun_direction(Game.sun_light()))


func tone(season_id: String, sky: Color, to_sun: Vector3) -> void:
	var cfg := VistaRules.config()
	var c: Dictionary = cfg.colors.get(season_id, cfg.colors.values()[0])
	mat.set_shader_parameter("dark", Color(str(c.dark)))
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
