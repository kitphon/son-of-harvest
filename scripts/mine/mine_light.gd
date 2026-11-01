class_name MineLight
extends RefCounted
## The light down the mine, for both views: a rectangle over the picture that multiplies it
## by the floor's light (MineFloor.light, darker deeper), with the farmer's lantern as a warm
## pool round them (MineFloor.lantern). The pool fades out in pixels, not rings: its falloff
## is cut into eight steps through a 4 x 4 ordered dither, so the edge is a soft speckled
## band. Its rim runs amber and the middle near the lantern's own colour, and three
## unrelated waves make it flicker (reach and brightness together). On a frozen floor
## (`cold`) a few pixels of the dark glint pale blue and twinkle, like ice catching light.
## The views place it: `aim` gets where the farmer is on the rectangle and how many of its
## pixels one cell is. Both views run this same shader on the same clock, so they match.

const SHADER := """
shader_type canvas_item;
render_mode blend_mul;

uniform vec4 glow : source_color = vec4(1.0);
uniform vec2 center = vec2(0.0);           // the farmer, in the rectangle's pixels
uniform vec2 size = vec2(480.0, 270.0);    // the rectangle's size in pixels
uniform float radius = 0.0;                // the lantern's reach in pixels; 0 = no lantern
uniform float soft = 0.5;                  // the share of the reach that fades out
uniform float cold = 0.0;                  // 1 on a frozen floor: ice glints in the dark

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float hash(vec2 v) {
	return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 p = floor(UV * size) + 0.5;
	float flame = 0.03 * sin(TIME * 5.3) + 0.02 * sin(TIME * 11.7 + 1.3) + 0.012 * sin(TIME * 23.1 + 0.7);
	float d = radius > 0.0 ? length(p - center) / (radius * (1.0 + flame)) : 2.0;
	float k = 1.0 - smoothstep(1.0 - soft, 1.0, d);
	ivec2 q = ivec2(mod(p - 0.5, 4.0));
	k = clamp(floor(k * 8.0 + BAYER[q.y * 4 + q.x] / 16.0) / 8.0, 0.0, 1.0);
	vec3 warm = mix(glow.rgb * vec3(1.0, 0.8, 0.56), glow.rgb, k) * (1.0 + flame * 0.8);
	vec3 dark = COLOR.rgb;
	vec2 cell = floor(p / 3.0);
	float twinkle = max(sin(TIME * 2.1 + hash(cell + 7.0) * 40.0), 0.0);
	if (cold > 0.0 && hash(cell) > 0.993) {
		dark = mix(dark, vec3(0.86, 0.94, 1.0), cold * twinkle);
	}
	COLOR = vec4(clamp(mix(dark, warm, k), 0.0, 1.0), 1.0);
}
"""

static var _shader: Shader


## A fresh material for one view's light rectangle.
static func material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	return m


## Points the lantern of floor `f` at `center` (pixels on a rectangle of `size`), one cell
## being `cell_px` pixels across.
static func aim(m: ShaderMaterial, f: MineFloor, center: Vector2, cell_px: float, size: Vector2) -> void:
	m.set_shader_parameter("glow", f.lantern.get("color", Color.WHITE))
	m.set_shader_parameter("center", center)
	m.set_shader_parameter("size", size)
	m.set_shader_parameter("radius", float(f.lantern.get("radius", 0.0)) * cell_px)
	m.set_shader_parameter("soft", clampf(float(f.lantern.get("soft", 0.5)), 0.01, 1.0))
	m.set_shader_parameter("cold", 1.0 if f.frozen else 0.0)
