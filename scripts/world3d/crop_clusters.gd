class_name CropClusters
extends Node3D
## Tall crops in the 3D view as clusters of small pixel sprites instead of one billboard a
## cell: rice as nine hills in three rows, corn as three stalks, cucumber and tomato
## as two stakes with the vine up each. Only the grown stages
## (growth 2 and 3 of PlaceholderArt.cell_key) of crops whose look is "grain", "stalk" or "vine"
## stand as clusters; seeds and sprouts, and every other crop, stay single sprites (FarmWorld).
## Each plant is a camera-facing quad in one MultiMesh per picture (`stalk:<id>:<growth>:
## <ripe|growing>:<variant>`), placed, sized, flipped and shaded by a hash of its cell and
## place so a cell always grows the same plants. The tips sway a little in the wind and part
## round the farmer's feet (Parting, `set_farmer`). Unshaded
## like the Sprite3D crops; each plant carries its cell's snow hold and folds away where the
## ground under its root lies white (only the village paddies give a hold: a crop on the farm
## stands in snow as its sprite always did).
##
## The village paddies (map tile "paddy") grow rice by the season: young in spring, tall and
## green in summer, ripe in fall (PADDY). In winter the cut rice stands as stubble (growth 0,
## "stalk:rice:0:stubble:<variant>") in the same nine-hill layout, and where water still stands
## between the rows a few flat patches of grey-blue water lie on the ground (plant_water; the
## numbers in data/paddy.json). Stubble and patches fold away or vanish under snow lying on them,
## by the same snow rule as the rice.

## How a cluster is laid out by the crop's look shape: the places in a cell (x, z from its
## corner), how far each is nudged, the plants' size range. Rice in three rows of three hills
## (young, growth 2: two rows of three smaller ones, the water showing between the rows),
## corn as three stalks, one at the back and two in front. Growth 0 is the winter stubble:
## the same nine places, shorter plants.
const LAYOUT := {
	"grain:2": {"places": [[0.17, 0.3], [0.5, 0.3], [0.83, 0.3], [0.17, 0.8], [0.5, 0.8], [0.83, 0.8]],
		"nudge": 0.04, "size": [0.75, 0.9]},
	"grain:0": {"places": [[0.17, 0.17], [0.5, 0.17], [0.83, 0.17], [0.17, 0.5], [0.5, 0.5],
		[0.83, 0.5], [0.17, 0.83], [0.5, 0.83], [0.83, 0.83]], "nudge": 0.05, "size": [0.9, 1.1]},
	"grain": {"places": [[0.17, 0.17], [0.5, 0.17], [0.83, 0.17], [0.17, 0.5], [0.5, 0.5],
		[0.83, 0.5], [0.17, 0.83], [0.5, 0.83], [0.83, 0.83]], "nudge": 0.05, "size": [0.85, 1.1]},
	"stalk": {"places": [[0.62, 0.25], [0.3, 0.55], [0.7, 0.78]], "nudge": 0.07, "size": [0.85, 1.0]},
	# Vines (cucumber, tomato): two stakes a cell, one behind and to the left, one in front right.
	"vine": {"places": [[0.3, 0.38], [0.7, 0.72]], "nudge": 0.06, "size": [0.9, 1.0], "stiff": 0.6},
}
const VARIANTS := 3
const SWAY := 0.03          # how far a tip swings (units)
## The village paddies' rice by season: [growth, ripe]; growth 0 is the winter stubble. A season
## left out has none.
const PADDY := {"spring": [2, false], "summer": [3, false], "fall": [3, true], "winter": [0, false]}
const WATER_PATH := "res://data/paddy.json"
const WATER_TEX := "patch:paddy_water"
const WATER_Y := 0.02          # lifted off the ground picture so the patch does not flicker into it

## What was planted: the spots_for() entries ({cell, key, tex, pos, size, flip, shade, hold}),
## read by the tests (the MultiMesh's own data can't be read back under the headless renderer).
var planted: Array[Dictionary] = []
var _cells := {}                       # Vector2i -> cluster key, as last planted
var _layers := {}                      # texture key -> MultiMeshInstance3D
var _material: ShaderMaterial
var _cover := 0.0
var wind := 0.0
## The winter water patches (plant_water): flat on the ground, one MultiMesh, their own shader.
var water_planted: Array[Dictionary] = []
var _water_layer: MultiMeshInstance3D
var _water_material: ShaderMaterial
static var _paddy_data := {}
var _sun := Color.WHITE

const SHADER := "shader_type spatial;\nrender_mode unshaded, cull_disabled;\n" + SnowLayer._SNOW_AT + Parting.GLSL + """
uniform sampler2D tex : source_color, filter_nearest;
uniform float sway = 0.03;
uniform float wind = 0.0;   // 0 dead calm .. 1 a gale (data/wind.json, FarmWorld.set_wind)
uniform float stiff = 1.0;   // 1 = the tip sways and parts fully; a stake holds the vine firmer
uniform vec3 sun = vec3(1.0);   // the sun's share by the clock, as on the Sprite3Ds (SpriteLight)
void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	float s = length(MODEL_MATRIX[1].xyz);
	if (snow_at(root.xz, cover * INSTANCE_CUSTOM.r) > 0.5) {
		VERTEX = vec3(0.0);   // under snow: folded away
	} else {
		float k = (1.0 - UV.y) * (1.0 - UV.y);
		// The wind as the grass takes it: a bigger, quicker swing, a slow gust swell and a flutter
		// by place, and a small lean downwind (+x, in the parting's world push below); none of it
		// when the air is still.
		float gust = 1.0 + wind * (0.8 * sin(TIME * 0.55 + root.x * 0.25) + 0.4 * sin(TIME * 1.7 + root.z * 0.5));
		float t = TIME * (1.3 + 0.9 * wind) + root.x * 0.9 + root.z * 0.6;
		VERTEX.x += sin(t) * sway * (1.0 + 1.5 * wind) * gust * k * stiff;
		// Parting round the farmer (Parting): the tip pushed away and down in world (x, z),
		// turned into the billboard's camera-facing axes at the plant's size.
		vec2 p = part_push(root.xz) * k * stiff + vec2(wind * 0.02 * k * stiff, 0.0);
		vec3 w = vec3(p.x, -length(p) * part_dip, p.y);
		VERTEX += vec3(dot(w, INV_VIEW_MATRIX[0].xyz), dot(w, INV_VIEW_MATRIX[1].xyz), dot(w, INV_VIEW_MATRIX[2].xyz)) / s;
	}
	if (INSTANCE_CUSTOM.b > 0.5) {
		UV.x = 1.0 - UV.x;
	}
	// Face the camera like a Sprite3D billboard, standing on its root, at its own size.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, vec4(root, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	COLOR.rgb = vec3(INSTANCE_CUSTOM.g);
}
void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) {
		discard;
	}
	ALBEDO = c.rgb * COLOR.rgb * sun;
}
"""


## The winter water: a flat patch lying on the ground (rotated to the ground by the instance's
## basis), folded out of sight where snow lies on its cell (the same rule as the plants), faced
## and flipped like the plants' pictures, unshaded.
const WATER_SHADER := "shader_type spatial;\nrender_mode unshaded, cull_disabled;\n" + SnowLayer._SNOW_AT + """
uniform sampler2D tex : source_color, filter_nearest;
void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	if (snow_at(root.xz, cover * INSTANCE_CUSTOM.r) > 0.5) {
		VERTEX = vec3(0.0);   // under snow: gone
	}
	if (INSTANCE_CUSTOM.b > 0.5) {
		UV.x = 1.0 - UV.x;
	}
	COLOR.rgb = vec3(INSTANCE_CUSTOM.g);
}
void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) {
		discard;
	}
	ALBEDO = c.rgb * COLOR.rgb;
}
"""


func _init() -> void:
	_material = SnowLayer._material(SHADER)
	_material.set_shader_parameter("sway", SWAY)
	_material.set_shader_parameter("stiff", 1.0)
	Parting.setup(_material, "crops")
	_water_material = SnowLayer._material(WATER_SHADER)
	_water_material.set_shader_parameter("tex", PlaceholderArt.tex(WATER_TEX))
	add_to_group(SpriteLight.GROUP)   # SpriteLight.apply sets the sun's share (set_sun)
	set_sun(SpriteLight.now)


## Snow lying, 0..1 (FarmWorld.set_snow): every picture's material, and the ones made later.
func set_cover(cover: float) -> void:
	_cover = cover
	for m in materials():
		m.set_shader_parameter("cover", cover)
	_water_material.set_shader_parameter("cover", cover)


## The snow lying now (set_cover), 0..1: SpriteLight.field_lifts leaves a plant that may fold away unlit.
func snow_cover() -> float:
	return _cover


## The wind, 0..1 (FarmWorld.set_wind): every picture's material, and the ones made later.
func set_wind(strength: float) -> void:
	wind = clampf(strength, 0.0, 1.0)
	for m in materials():
		m.set_shader_parameter("wind", wind)


## The sun's share on the pictures (SpriteLight.apply): every picture's material, and the ones made later.
func set_sun(c: Color) -> void:
	_sun = c
	for m in materials():
		m.set_shader_parameter("sun", Vector3(c.r, c.g, c.b))


## The pushers' feet in the world (FarmWorld.set_farmer, each frame; Parting.pick): the plants
## round them part. Set on the shared material too, so pictures made later start with it.
func set_pushers(feet: PackedVector2Array) -> void:
	for m in materials():
		Parting.feed(m, feet)


## Every picture's material (each picture has its own copy of the shared one).
func materials() -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = [_material]
	for t in _layers:
		out.append(_layers[t].material_override)
	return out


## The cluster key for a cell's crop key (`crop:<id>:<growth>:<state>` from
## PlaceholderArt.cell_key), or "" when that crop at that growth is a single sprite.
static func key_for(crop_key: String) -> String:
	var parts := crop_key.split(":")
	if parts.size() < 4 or parts[0] != "crop" or int(parts[2]) < 2:
		return ""
	if not LAYOUT.has(PlaceholderArt.crop_look(parts[1]).get("shape", "")):
		return ""
	return "stalk:%s:%s:%s" % [parts[1], parts[2], parts[3]]


## The rice in the village paddies this season ("" for none): the stubble in winter.
static func paddy_key(season: String) -> String:
	if not PADDY.has(season):
		return ""
	var p: Array = PADDY[season]
	if p[0] == 0:
		return "stalk:rice:0:stubble"
	return "stalk:rice:%d:%s" % [p[0], "ripe" if p[1] else "growing"]


## Whether the paddies' water patches show this season (data/paddy.json water.seasons).
static func water_on(season: String) -> bool:
	return season in paddy_data().get("water", {}).get("seasons", [])


## data/paddy.json, read once.
static func paddy_data() -> Dictionary:
	if _paddy_data.is_empty():
		_paddy_data = JSON.parse_string(FileAccess.get_file_as_string(WATER_PATH))
	return _paddy_data


## Stands the water patches on the given cells (the paddy cells with no prop): none for a season
## without water (the caller checks water_on). Each patch carries its cell's snow hold, and snow
## lying on it hides it.
func plant_water(cells: Array, hold_at: Callable) -> void:
	var spots := water_spots_for(cells)
	for s in spots:
		s.hold = float(hold_at.call(s.cell))
	if _water_layer == null:
		_water_layer = _make_water_layer()
	var mm := _water_layer.multimesh
	mm.instance_count = spots.size()
	for i in spots.size():
		var s: Dictionary = spots[i]
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.RIGHT, -PI / 2.0).scaled(Vector3.ONE * s.size), s.pos))
		mm.set_instance_custom_data(i, Color(s.hold, s.shade, 1.0 if s.flip else 0.0, 0))
	water_planted = spots


## One MultiMesh for the water patches: a quad the picture's size, lying flat in the ground plane
## (the instance's basis turns it, see plant_water).
func _make_water_layer() -> MultiMeshInstance3D:
	var tex := PlaceholderArt.tex(WATER_TEX)
	var quad := QuadMesh.new()
	quad.size = Vector2(tex.get_width(), tex.get_height()) * FarmWorld.PX
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.use_custom_data = true
	mmi.multimesh.mesh = quad
	mmi.material_override = _water_material
	add_child(mmi)
	return mmi


## Where the water patches stand: per cell and row gap (data/paddy.json) a patch when its hash
## passes `chance`, across the cell and wandering a little off its row gap, sized, flipped and
## shaded by its own hash. Sorted by cell, then row gap.
static func water_spots_for(cells: Array) -> Array[Dictionary]:
	var d: Dictionary = paddy_data().get("water", {})
	var out: Array[Dictionary] = []
	var sorted := cells.duplicate()
	sorted.sort()
	for c: Vector2i in sorted:
		var zs: Array = d.z
		for k in zs.size():
			if _rand(c, k, 6) >= float(d.chance):
				continue
			var xs: Array = d.x
			var size: Array = d.size
			var x: float = c.x + lerpf(float(xs[0]), float(xs[1]), _rand(c, k, 7))
			var z: float = c.y + float(zs[k]) + (_rand(c, k, 8) * 2.0 - 1.0) * float(d.nudge)
			out.append({"cell": c, "tex": WATER_TEX, "pos": Vector3(x, WATER_Y, z),
				"size": lerpf(float(size[0]), float(size[1]), _rand(c, k, 9)),
				"flip": _rand(c, k, 10) < 0.5, "shade": 0.9 + 0.16 * _rand(c, k, 11), "hold": 0.0})
	return out


## Stands the clusters: `cells` maps a cell to its cluster key; `hold_at(c)` is how much snow
## the cell holds. Does nothing when the cells and keys are as last time.
func plant(cells: Dictionary, hold_at: Callable) -> void:
	if cells == _cells:
		return
	_cells = cells.duplicate()
	var spots := spots_for(cells)
	var by_tex := {}
	for s in spots:
		s.hold = float(hold_at.call(s.cell))
		if not by_tex.has(s.tex):
			by_tex[s.tex] = []
		by_tex[s.tex].append(s)
	for t in _layers.keys():
		if not by_tex.has(t):
			_layers[t].queue_free()
			_layers.erase(t)
	for t in by_tex:
		if not _layers.has(t):
			_layers[t] = _layer(t)
		var mm: MultiMesh = _layers[t].multimesh
		var list: Array = by_tex[t]
		mm.instance_count = list.size()
		for i in list.size():
			var s: Dictionary = list[i]
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * s.size), s.pos))
			mm.set_instance_custom_data(i, Color(s.hold, s.shade, 1.0 if s.flip else 0.0, 0))
	planted = spots


## The pictures standing now (texture key -> how many plants), for the tests.
func layer_counts() -> Dictionary:
	var out := {}
	for t in _layers:
		out[t] = _layers[t].multimesh.instance_count
	return out


## One MultiMesh for one picture: a quad the picture's size (FarmWorld.PX a pixel) standing
## on its bottom middle.
func _layer(tex_key: String) -> MultiMeshInstance3D:
	var tex := PlaceholderArt.tex(tex_key)
	var quad := QuadMesh.new()
	quad.size = Vector2(tex.get_width(), tex.get_height()) * FarmWorld.PX
	quad.center_offset = Vector3(0, quad.size.y / 2.0, 0)
	var m := _material.duplicate() as ShaderMaterial
	m.set_shader_parameter("tex", tex)
	m.set_shader_parameter("cover", _cover)
	m.set_shader_parameter("wind", wind)
	m.set_shader_parameter("sun", Vector3(_sun.r, _sun.g, _sun.b))
	m.set_shader_parameter("stiff", float(layout(tex_key).get("stiff", 1.0)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.use_custom_data = true
	mmi.multimesh.mesh = quad
	mmi.material_override = m
	add_child(mmi)
	return mmi


## Where the plants stand: per cell the layout of its crop's shape, each place nudged,
## sized, flipped, shaded and given a variant by its own hash. Sorted by cell, then place.
static func spots_for(cells: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var keys := cells.keys()
	keys.sort()
	for c: Vector2i in keys:
		var key: String = cells[c]
		var lay := layout(key)
		var nudge: float = lay.nudge
		var size: Array = lay.size
		var places: Array = lay.places
		for k in places.size():
			var x: float = c.x + places[k][0] + (_rand(c, k, 0) * 2.0 - 1.0) * nudge
			var z: float = c.y + places[k][1] + (_rand(c, k, 1) * 2.0 - 1.0) * nudge
			out.append({"cell": c, "key": key,
				"tex": "%s:%d" % [key, int(_rand(c, k, 2) * VARIANTS) % VARIANTS],
				"pos": Vector3(x, 0.0, z), "size": lerpf(size[0], size[1], _rand(c, k, 3)),
				"flip": _rand(c, k, 4) < 0.5, "shade": 0.9 + 0.16 * _rand(c, k, 5), "hold": 0.0})
	return out


## The LAYOUT entry for a cluster key: by the crop's shape, or by shape and growth.
static func layout(key: String) -> Dictionary:
	var shape: String = PlaceholderArt.crop_look(key.get_slice(":", 1)).get("shape", "grain")
	return LAYOUT.get("%s:%s" % [shape, key.get_slice(":", 2)], LAYOUT[shape])


## A number 0..1 fixed by the cell, the place in it and what it is for.
static func _rand(c: Vector2i, k: int, what: int) -> float:
	return posmod(hash(Vector4i(c.x, c.y, k + 50, what)), 10007) / 10007.0
