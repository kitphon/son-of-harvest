class_name Parting
extends RefCounted
## Grass and tall crops parting round the farmer in the 3D view: a plant whose root stands
## within `radius` of the farmer's feet has its tip pushed straight away from them and a
## little down, fully within `full` of the radius and easing to nothing at it (a smoothstep), so the
## blades spring back by themselves as the farmer walks on. The shaders of GrassTufts and
## CropClusters include GLSL (the same math as `push`) and read the farmer's feet from the
## `farmer` uniform, fed each frame by FarmWorld.set_farmer (Main3D._process). The numbers
## are in data/wind.json, "part".

## Defaults when data/wind.json has no "part" (the same as the data).
const RADIUS := 1.0
const BEND := {"grass": 0.18, "crops": 0.22}
const DIP := 0.45
const FULL := 0.3

## The shader part: uniforms and `part_push(root)`, the world (x, z) shift of a tip at `root`.
const GLSL := """
uniform vec2 farmer = vec2(-10000.0, -10000.0);   // the farmer's feet, world (x, z)
uniform float part_radius = 1.0;
uniform float part_bend = 0.12;
uniform float part_dip = 0.45;
uniform float part_full = 0.3;   // the share of the radius bent fully
vec2 part_push(vec2 root) {
	vec2 d = root - farmer;
	float dist = length(d);
	if (dist >= part_radius) {
		return vec2(0.0);
	}
	float f = 1.0 - smoothstep(part_radius * part_full, part_radius, dist);
	vec2 away = dist > 0.0001 ? d / dist : vec2(1.0, 0.0);
	return away * part_bend * f * min(dist / 0.08, 1.0);
}
"""


## The world (x, z) shift of a tip whose root is at `root` with the farmer at `feet` (the
## shader's part_push): away from the feet, `bend` within `full` x `radius`, none from `radius` out.
static func push(root: Vector2, feet: Vector2, radius: float, bend: float, full := FULL) -> Vector2:
	var d := root - feet
	var dist := d.length()
	if dist >= radius:
		return Vector2.ZERO
	var f := 1.0 - smoothstep(radius * full, radius, dist)
	var away := d / dist if dist > 0.0001 else Vector2.RIGHT
	return away * bend * f * minf(dist / 0.08, 1.0)


## The parting numbers from data/wind.json ("part"): {radius, bend for `kind`, dip, full}.
static func rules(kind: String) -> Dictionary:
	var part: Dictionary = Game.wind_rules.get("part", {})
	var bend: Dictionary = part.get("bend", {})
	return {"radius": float(part.get("radius", RADIUS)), "bend": float(bend.get(kind, BEND.get(kind, 0.0))),
		"dip": float(part.get("dip", DIP)), "full": float(part.get("full", FULL))}


## Sets a material's parting numbers for `kind` (grass, crops).
static func setup(m: ShaderMaterial, kind: String) -> void:
	var r := rules(kind)
	m.set_shader_parameter("part_radius", r.radius)
	m.set_shader_parameter("part_bend", r.bend)
	m.set_shader_parameter("part_dip", r.dip)
	m.set_shader_parameter("part_full", r.full)
