class_name WaterIce
extends RefCounted
## Winter ice along the shore of the water, shared by the 3D sheet (WaterSurface) and the flat
## view's skin (WaterView): the shader code (GLSL, pasted into both shaders at "//ICE//"), the
## land mask round a cell it reads, and the uniforms from data/snow_cover.json "ice" (through
## Game.ice_style()). No other script is needed here, so the flat view and tests load it alone.
## The look: thin ice `width` px (ragged between a min and a max, value noise every 4 px) in
## from the bank line (the ground tile's 2 px bank and 1 px foam line, 3 px in from a land
## side), pale blue-white, a darker rim of one pixel where it meets the open water, short
## diagonal cracks and frost specks, and with snow lying a dusting of snow on it (2 x 2 px
## flecks, `snow` x the cover, more of them near the shore). The middle of every cell stays
## open (8 px from any side against a width of 4 at most), so the bobber always floats on water.

## Bits of the land mask round a cell (UV2.x of the 3D sheet's quads, the red channel x 255 of
## WaterView's mask): left, right, up (-z / -y), down, then the four corners.
const BITS := {"left": 1, "right": 2, "up": 4, "down": 8, "up_left": 16, "up_right": 32, "down_left": 64, "down_right": 128}
const STEPS := {"left": Vector2i(-1, 0), "right": Vector2i(1, 0), "up": Vector2i(0, -1), "down": Vector2i(0, 1),
	"up_left": Vector2i(-1, -1), "up_right": Vector2i(1, -1), "down_left": Vector2i(-1, 1), "down_right": Vector2i(1, 1)}

## ice_at(pix, mask): the ice's colour and alpha at world (map) pixel `pix` of a cell whose land
## neighbours are `mask` (BITS); alpha 0 = open water.
const GLSL := """
uniform float ice_on = 0.0;                 // 1 in winter outdoors
uniform vec2 ice_width = vec2(2.0, 4.0);    // px in from the bank line, ragged between the two
uniform float ice_alpha = 0.92;
uniform float ice_edge_alpha = 0.7;
uniform float ice_cracks = 0.35;
uniform float ice_frost = 0.08;
uniform float ice_snow = 0.0;               // the snow lying (0..1) x the dusting's share
uniform vec3 ice_color : source_color = vec3(0.84, 0.9, 0.94);
uniform vec3 ice_edge_color : source_color = vec3(0.6, 0.73, 0.83);
uniform vec3 ice_crack_color : source_color = vec3(0.5, 0.63, 0.75);
uniform vec3 ice_frost_color : source_color = vec3(0.96, 0.98, 1.0);
uniform vec3 ice_snow_color : source_color = vec3(0.94, 0.96, 0.99);
float ice_hash(vec2 v) { return fract(sin(dot(v, vec2(27.619, 57.583))) * 43758.5453); }
float ice_noise(vec2 v) {   // value noise, smooth between whole points
	vec2 i = floor(v);
	vec2 f = fract(v);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(ice_hash(i), ice_hash(i + vec2(1.0, 0.0)), f.x),
		mix(ice_hash(i + vec2(0.0, 1.0)), ice_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
// px from the bank line (3 px in from a land side) at local pixel centre lp (0.5 .. 15.5).
float ice_shore(vec2 lp, int m) {
	float d = 99.0;
	if ((m & 1) != 0) { d = min(d, lp.x - 3.0); }
	if ((m & 2) != 0) { d = min(d, 13.0 - lp.x); }
	if ((m & 4) != 0) { d = min(d, lp.y - 3.0); }
	if ((m & 8) != 0) { d = min(d, 13.0 - lp.y); }
	if ((m & 16) != 0) { d = min(d, length(lp) - 3.0); }
	if ((m & 32) != 0) { d = min(d, length(lp - vec2(16.0, 0.0)) - 3.0); }
	if ((m & 64) != 0) { d = min(d, length(lp - vec2(0.0, 16.0)) - 3.0); }
	if ((m & 128) != 0) { d = min(d, length(lp - vec2(16.0, 16.0)) - 3.0); }
	return d;
}
vec4 ice_at(vec2 pix, float mask) {
	int m = int(round(mask));
	if (ice_on < 0.5 || m == 0) {
		return vec4(0.0);
	}
	vec2 cell = floor(pix / 16.0);
	vec2 lp = pix - cell * 16.0 + 0.5;
	float d = ice_shore(lp, m);
	float w = mix(ice_width.x, ice_width.y, ice_noise(pix / 4.0));
	if (d >= w) {
		return vec4(0.0);   // open water
	}
	float near = clamp(1.0 - d / max(w, 1.0), 0.0, 1.0);   // 1 at the shore .. 0 at the ice's edge
	if (ice_snow > 0.0 && ice_hash(floor(pix / 2.0) + vec2(3.1, 7.7)) < ice_snow * (0.55 + 0.6 * near)) {
		return vec4(ice_snow_color, 1.0);
	}
	if (d > w - 1.0) {
		return vec4(ice_edge_color, ice_edge_alpha);   // the thin rim against the open water
	}
	float k = floor(ice_hash(cell) * 13.0);
	bool diag = mod(pix.x - pix.y + k, 9.0) < 0.5;
	bool anti = mod(pix.x + pix.y + k, 11.0) < 0.5;
	if ((diag || anti) && ice_hash(floor(pix / 3.0) + cell * 7.0) < ice_cracks) {
		return vec4(ice_crack_color, ice_alpha);
	}
	if (ice_hash(pix + vec2(0.5, 1.5)) < ice_frost) {
		return vec4(ice_frost_color, ice_alpha);
	}
	return vec4(ice_color, ice_alpha);
}
"""


## The ice's width pair [min, max] px on day `day` of the season with snow lying `cover` (0..1):
## style.width scaled by style.grow.curve (day, factor points, linear between: thin at the start
## of winter, full about day 22, receding to the end) and by 1 + grow.cover_bonus x cover, the
## top capped at grow.max (4.4, so the middle 8 px of every cell stays open and fishing is untouched).
## A style with no "grow" keeps its width.
static func grown_width(style: Dictionary, day: int, cover: float) -> Array:
	var w: Array = style.get("width", [2, 4])
	var grow: Dictionary = style.get("grow", {})
	if grow.is_empty():
		return w
	var curve: Array = grow.get("curve", [])
	var f := 1.0
	if not curve.is_empty():
		f = float(curve[0][1])
		var d := float(day)
		if d >= float(curve[curve.size() - 1][0]):
			f = float(curve[curve.size() - 1][1])
		else:
			for i in range(1, curve.size()):
				if d <= float(curve[i][0]):
					var a: Array = curve[i - 1]
					var b: Array = curve[i]
					var t := clampf((d - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001), 0.0, 1.0)
					f = lerpf(float(a[1]), float(b[1]), t)
					break
	f *= 1.0 + float(grow.get("cover_bonus", 0.0)) * clampf(cover, 0.0, 1.0)
	var cap := float(grow.get("max", 4.0))
	return [minf(float(w[0]) * f, cap), minf(float(w[1]) * f, cap)]


## Puts an ice style ({} = none) and the snow lying (0..1) into a water material (the 3D
## sheet's or WaterView's: the same uniforms).
static func push(m: ShaderMaterial, style: Dictionary, snow: float) -> void:
	m.set_shader_parameter("ice_on", 0.0 if style.is_empty() else 1.0)
	if style.is_empty():
		return
	var w: Array = style.get("width", [2, 4])
	m.set_shader_parameter("ice_width", Vector2(float(w[0]), float(w[1])))
	m.set_shader_parameter("ice_alpha", float(style.get("alpha", 0.92)))
	m.set_shader_parameter("ice_edge_alpha", float(style.get("edge_alpha", 0.7)))
	m.set_shader_parameter("ice_cracks", float(style.get("cracks", 0.35)))
	m.set_shader_parameter("ice_frost", float(style.get("frost", 0.08)))
	m.set_shader_parameter("ice_snow", clampf(snow, 0.0, 1.0) * float(style.get("snow", 0.85)))
	var colors: Dictionary = style.get("colors", {})
	for k in colors:
		m.set_shader_parameter("ice_color" if k == "ice" else "ice_%s_color" % k, Color(String(colors[k])))


## The land round cell `c` as BITS (`water_at(n)` is false on land).
static func land_mask(c: Vector2i, water_at: Callable) -> int:
	var m := 0
	for k in STEPS:
		if not water_at.call(c + STEPS[k]):
			m |= int(BITS[k])
	return m


## The shader's ice_shore in GDScript (for tests): px from the bank line at local pixel centre
## `lp` (0.5 .. 15.5) of a cell with land `mask` round it; ice lies where this is under the
## width (99 with no land round).
static func shore_px(lp: Vector2, mask: int) -> float:
	var d := 99.0
	var corners := {16: Vector2(0, 0), 32: Vector2(16, 0), 64: Vector2(0, 16), 128: Vector2(16, 16)}
	if mask & 1:
		d = minf(d, lp.x - 3.0)
	if mask & 2:
		d = minf(d, 13.0 - lp.x)
	if mask & 4:
		d = minf(d, lp.y - 3.0)
	if mask & 8:
		d = minf(d, 13.0 - lp.y)
	for bit in corners:
		if mask & bit:
			d = minf(d, lp.distance_to(corners[bit]) - 3.0)
	return d
