class_name Parting
extends RefCounted
## Grass and tall crops parting round the farmer in the 3D view: a plant whose root stands
## within `radius` of the farmer's feet has its tip pushed straight away from them and a
## little down, fully within `full` of the radius and easing to nothing at it (a smoothstep), so the
## blades spring back by themselves as the farmer walks on. The shaders of GrassTufts and
## CropClusters include GLSL (the same math as `push_all`) and read the farmer's feet from the
## `pushers` uniform (the farmer first, then the villagers and the dog nearest them), fed each
## frame by FarmWorld.set_farmer (Main3D._process); sprites in GROUP are the others. The numbers
## are in data/wind.json, "part".

## Defaults when data/wind.json has no "part" (the same as the data).
const RADIUS := 1.0
const BEND := {"grass": 0.18, "crops": 0.22}
const DIP := 0.45
const FULL := 0.3

## The shader part: uniforms and `part_push(root)`, the world (x, z) shift of a tip at `root`.
const GLSL := """
const int PART_MAX = 8;   // the array's size (Parting.MAX_PUSHERS)
uniform vec2 pushers[PART_MAX];   // world (x, z) feet: the farmer first, then the nearest villagers and the dog
uniform int pusher_count = 0;
uniform float part_radius = 1.0;
uniform float part_bend = 0.12;
uniform float part_dip = 0.45;
uniform float part_full = 0.3;   // the share of the radius bent fully
vec2 part_push(vec2 root) {
	vec2 sum = vec2(0.0);
	for (int i = 0; i < PART_MAX; i++) {
		if (i >= pusher_count) {
			break;
		}
		vec2 d = root - pushers[i];
		float dist = length(d);
		if (dist < part_radius) {
			float f = 1.0 - smoothstep(part_radius * part_full, part_radius, dist);
			vec2 away = dist > 0.0001 ? d / dist : vec2(1.0, 0.0);
			sum += away * part_bend * f * min(dist / 0.08, 1.0);
		}
	}
	float l = length(sum);
	return l > part_bend ? sum * (part_bend / l) : sum;   // two at once never bend further than one
}
"""

## The most pushers the shader holds, and the group the villagers' and the dog's sprites are in.
const MAX_PUSHERS := 8
const GROUP := "part_pushers"


## The world (x, z) shift of a tip whose root is at `root` with one pusher at `feet`: away
## from the feet, `bend` within `full` x `radius`, none from `radius` out.
static func push(root: Vector2, feet: Vector2, radius: float, bend: float, full := FULL) -> Vector2:
	var d := root - feet
	var dist := d.length()
	if dist >= radius:
		return Vector2.ZERO
	var f := 1.0 - smoothstep(radius * full, radius, dist)
	var away := d / dist if dist > 0.0001 else Vector2.RIGHT
	return away * bend * f * minf(dist / 0.08, 1.0)


## The shader's part_push: the pushes of every pusher in `feet` summed, none longer than `bend`.
static func push_all(root: Vector2, feet: PackedVector2Array, radius: float, bend: float, full := FULL) -> Vector2:
	var sum := Vector2.ZERO
	for f in feet:
		sum += push(root, f, radius, bend, full)
	return sum.limit_length(bend)


## The pushers fed to the shader: the farmer first, then the `others` nearest to them, at
## most `max_count` in all (data/wind.json "part".max, never over MAX_PUSHERS).
static func pick(farmer: Vector2, others: Array, max_count := MAX_PUSHERS) -> PackedVector2Array:
	var out := PackedVector2Array([farmer])
	var cap := clampi(max_count, 1, MAX_PUSHERS)
	var rest: Array = others.duplicate()
	rest.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(farmer) < b.distance_squared_to(farmer))
	for o in rest:
		if out.size() >= cap:
			break
		out.append(o)
	return out


## The parting numbers from data/wind.json ("part"): {radius, bend for `kind`, dip, full, max}.
static func rules(kind: String) -> Dictionary:
	var part: Dictionary = Game.wind_rules.get("part", {})
	var bend: Dictionary = part.get("bend", {})
	return {"radius": float(part.get("radius", RADIUS)), "bend": float(bend.get(kind, BEND.get(kind, 0.0))),
		"dip": float(part.get("dip", DIP)), "full": float(part.get("full", FULL)),
		"max": clampi(int(part.get("max", MAX_PUSHERS)), 1, MAX_PUSHERS)}


## Feeds `feet` (from `pick`) to a material: the padded array and the count.
static func feed(m: ShaderMaterial, feet: PackedVector2Array) -> void:
	var padded := feet.duplicate()
	padded.resize(MAX_PUSHERS)
	m.set_shader_parameter("pushers", padded)
	m.set_shader_parameter("pusher_count", mini(feet.size(), MAX_PUSHERS))


## Sets a material's parting numbers for `kind` (grass, crops).
static func setup(m: ShaderMaterial, kind: String) -> void:
	var r := rules(kind)
	m.set_shader_parameter("part_radius", r.radius)
	m.set_shader_parameter("part_bend", r.bend)
	m.set_shader_parameter("part_dip", r.dip)
	m.set_shader_parameter("part_full", r.full)
