class_name Backdrop
extends Node3D
## The far country past an outdoor map (data/backdrop.json, the 3D view only): layers of
## low-poly mountain ridges past the map's back (north and west) sides, flat coloured as
## silhouettes (no sun shading), toned by season, hazed with the sky's colour by the clock
## (Game.sky_color, the same colour as the clear background above them), their feet fading
## into it like mist, snow caps in winter.
##
## The fixed camera looks 16 degrees down at the top of the frame, so a mountain standing on
## the ground far off is always above the picture. Surroundings stops the land a few cells past
## the back edges (`rim`), and the ridges stand far out and low, below the ground's level: from
## near the back edges the top corners of the frame look over the rim and down onto them, with
## the sky's colour above the peaks. Farther in, the rim hides them.

const PATH := "res://data/backdrop.json"
const NO_SNOW := 10000.0   # a snow line no peak reaches

const SHADER := """shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform vec3 ridge : source_color = vec3(0.4, 0.5, 0.6);
uniform vec3 haze_color : source_color = vec3(0.56, 0.78, 0.91);
uniform vec3 snow_color : source_color = vec3(0.95, 0.97, 0.98);
uniform float haze = 0.3;            // 0..1 of the sky's colour over the whole ridge
uniform float snow_line = 10000.0;   // world height above which snow lies
uniform float mist_top = 0.0;        // the foot fades from here ...
uniform float mist_bottom = -2.0;    // ... to all sky here
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float along = world.x - world.z;
	float jag = sin(along * 1.9) * 0.22 + sin(along * 0.7 + 1.3) * 0.18;
	vec3 c = (world.y > snow_line + jag ? snow_color : ridge) * COLOR.rgb;
	c = mix(c, haze_color, haze);
	c = mix(c, haze_color, smoothstep(mist_top, mist_bottom, world.y));
	ALBEDO = c;
}
"""

## One entry per ridge layer, far first: {mat: ShaderMaterial, cfg: the layer's data}.
var layers: Array[Dictionary] = []


## The file's numbers (data/backdrop.json).
static func config() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return data if data is Dictionary else {}


## Does map `id` have the far country (and so the land cut at the rim)?
static func on_map(id: String) -> bool:
	return id in config().get("maps", [])


## Cells of land past the back edges where the backdrop stands.
static func rim() -> int:
	return int(config().get("rim", 3))


## % of the rim's cells with a pine (Surroundings.TREE_SHARE elsewhere).
static func rim_pines() -> int:
	return int(config().get("rim_pines", Surroundings.TREE_SHARE))


## Builds the ridges round a w x h map and tones them for the clock and season now.
func build(w: int, h: int) -> void:
	var cfg := config()
	var span := float(cfg.get("span", 40.0))
	var shader := SnowLayer.shader(SHADER)   # shared, parsed once a run
	for layer: Dictionary in cfg.get("layers", []):
		var pts := samples(path(w, h, float(layer.gap), span), float(layer.step))
		var tops := tops_for(pts.size(), float(layer.low), float(layer.high), int(layer.seed))
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in pts.size() - 1:
			var tone := 1.0 if i % 2 == 0 else 0.88   # the facets, alternately lighter and darker
			_quad(st, pts[i], pts[i + 1], tops[i], tops[i + 1], float(layer.bottom), tone)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("snow_color", Color(str(cfg.get("snow", "ffffff"))))
		mat.set_shader_parameter("haze", float(layer.get("haze", 0.0)))
		mat.set_shader_parameter("mist_top", float(layer.low))
		mat.set_shader_parameter("mist_bottom", float(layer.low) - float(layer.get("mist", 2.0)))
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		layers.append({"mat": mat, "cfg": layer})
	refresh()


func _ready() -> void:
	Game.minute_passed.connect(refresh)
	Game.day_started.connect(refresh)


## Tones the ridges for Game's clock, weather and season.
func refresh() -> void:
	tone(Game.season_name(), Game.sky_color())


## The ridges' colour for `season_id`, hazed with `sky`, snow caps by the season.
func tone(season_id: String, sky: Color) -> void:
	var caps := float(config().get("caps", {}).get(season_id, 0.0))
	for l in layers:
		var mat: ShaderMaterial = l.mat
		mat.set_shader_parameter("ridge", layer_color(l.cfg, season_id))
		mat.set_shader_parameter("haze_color", sky)
		mat.set_shader_parameter("snow_line", snow_line(l.cfg, caps))


## A layer's colour in `season_id` (the first colour listed when it has none).
static func layer_color(layer: Dictionary, season_id: String) -> Color:
	var colors: Dictionary = layer.colors
	return Color(str(colors.get(season_id, colors.values()[0])))


## The height above which a layer is white: `caps` (0..1) of the way down from its highest peak
## to its lowest; none at 0.
static func snow_line(layer: Dictionary, caps: float) -> float:
	if caps <= 0.0:
		return NO_SNOW
	var high := float(layer.high)
	return high - caps * (high - float(layer.low))


## The ridge's base line `gap` cells past the back edges: from past the north-east end, round
## the north-west corner, down past the south-west end.
static func path(w: int, h: int, gap: float, span: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(w + span, -gap), Vector2(-gap, -gap), Vector2(-gap, h + span)])


## The corner points of `corners` cut into points about `step` apart (corners included once).
static func samples(corners: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in corners.size() - 1:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[k + 1]
		var n := maxi(1, ceili(a.distance_to(b) / step))
		for i in n:
			out.append(a.lerp(b, float(i) / n))
	out.append(corners[corners.size() - 1])
	return out


## The height of each ridge point, from `low` to `high`, by its index and seed (a peak, then a
## saddle more often than not, so the outline reads as mountains).
static func tops_for(count: int, low: float, high: float, seed_value: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in count:
		var r := posmod((i + 1) * 7919 * (seed_value + 3) + i * i * 31, 1000) / 1000.0
		if i % 2 == 1:
			r *= 0.55   # the saddles between peaks sit lower
		out.append(lerpf(low, high, r))
	return out


## One quad of a wall: from `bottom` up to each end's top, two triangles, `tone` in the colour.
func _quad(st: SurfaceTool, a: Vector2, b: Vector2, ta: float, tb: float, bottom: float, tone: float) -> void:
	var c := Color(tone, tone, tone)
	for v in [Vector3(a.x, bottom, a.y), Vector3(b.x, bottom, b.y), Vector3(b.x, tb, b.y),
			Vector3(a.x, bottom, a.y), Vector3(b.x, tb, b.y), Vector3(a.x, ta, a.y)]:
		st.set_color(c)
		st.add_vertex(v)
