class_name MineLight
extends RefCounted
## The light down the mine, for both views: a rectangle over the picture that multiplies it
## by the floor's light (MineFloor.light, darker deeper), with the farmer's lantern as a warm
## circle round them (MineFloor.lantern). The circle is drawn in four rings, like a pixel
## lantern, and breathes a little like a flame. The views place it: `aim` gets where the
## farmer is on the rectangle and how many of its pixels one cell is.

const SHADER := """
shader_type canvas_item;
render_mode blend_mul;

uniform vec4 glow : source_color = vec4(1.0);
uniform vec2 center = vec2(0.0);           // the farmer, in the rectangle's pixels
uniform vec2 size = vec2(480.0, 270.0);    // the rectangle's size in pixels
uniform float radius = 0.0;                // the lantern's reach in pixels; 0 = no lantern
uniform float soft = 0.5;                  // the share of the reach that fades out

void fragment() {
	vec2 p = floor(UV * size) + 0.5;
	float flame = 1.0 + 0.02 * sin(TIME * 6.3) + 0.012 * sin(TIME * 15.1);
	float d = radius > 0.0 ? length(p - center) / (radius * flame) : 2.0;
	float k = 1.0 - smoothstep(1.0 - soft, 1.0, d);
	k = ceil(k * 4.0) / 4.0;
	COLOR = vec4(mix(COLOR.rgb, glow.rgb, k), 1.0);
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
