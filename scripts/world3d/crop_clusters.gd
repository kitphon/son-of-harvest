class_name CropClusters
extends Node3D
## Tall crops in the 3D view as clusters of small pixel sprites instead of one billboard a
## cell: rice as nine hills in three rows, corn as three stalks. Only the grown stages
## (growth 2 and 3 of PlaceholderArt.cell_key) of crops whose look is "grain" or "stalk"
## stand as clusters; seeds and sprouts, and every other crop, stay single sprites (FarmWorld).
## Each plant is a camera-facing quad in one MultiMesh per picture (`stalk:<id>:<growth>:
## <ripe|growing>:<variant>`), placed, sized, flipped and shaded by a hash of its cell and
## place so a cell always grows the same plants. The tips sway a little in the wind. Unshaded
## like the Sprite3D crops; each plant carries its cell's snow hold and folds away where the
## ground under its root lies white (only the village paddies give a hold: a crop on the farm
## stands in snow as its sprite always did).
##
## The village paddies (map tile "paddy") grow rice by the season: young in spring, tall and
## green in summer, ripe in fall, none in winter (PADDY).

## How a cluster is laid out by the crop's look shape: the places in a cell (x, z from its
## corner), how far each is nudged, the plants' size range. Rice in three rows of three hills
## (young, growth 2: two rows of three smaller ones, the water showing between the rows),
## corn as three stalks, one at the back and two in front.
const LAYOUT := {
	"grain:2": {"places": [[0.17, 0.3], [0.5, 0.3], [0.83, 0.3], [0.17, 0.8], [0.5, 0.8], [0.83, 0.8]],
		"nudge": 0.04, "size": [0.75, 0.9]},
	"grain": {"places": [[0.17, 0.17], [0.5, 0.17], [0.83, 0.17], [0.17, 0.5], [0.5, 0.5],
		[0.83, 0.5], [0.17, 0.83], [0.5, 0.83], [0.83, 0.83]], "nudge": 0.05, "size": [0.85, 1.1]},
	"stalk": {"places": [[0.62, 0.25], [0.3, 0.55], [0.7, 0.78]], "nudge": 0.07, "size": [0.85, 1.0]},
}
const VARIANTS := 3
const SWAY := 0.03          # how far a tip swings (units)
## The village paddies' rice by season: [growth, ripe]; a season left out has none.
const PADDY := {"spring": [2, false], "summer": [3, false], "fall": [3, true]}

## What was planted: the spots_for() entries ({cell, key, tex, pos, size, flip, shade, hold}),
## read by the tests (the MultiMesh's own data can't be read back under the headless renderer).
var planted: Array[Dictionary] = []
var _cells := {}                       # Vector2i -> cluster key, as last planted
var _layers := {}                      # texture key -> MultiMeshInstance3D
var _material: ShaderMaterial
var _cover := 0.0

const SHADER := "shader_type spatial;\nrender_mode unshaded, cull_disabled;\n" + SnowLayer._SNOW_AT + """
uniform sampler2D tex : source_color, filter_nearest;
uniform float sway = 0.03;
void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	float s = length(MODEL_MATRIX[1].xyz);
	if (snow_at(root.xz, cover * INSTANCE_CUSTOM.r) > 0.5) {
		VERTEX = vec3(0.0);   // under snow: folded away
	} else {
		float k = (1.0 - UV.y) * (1.0 - UV.y);
		float t = TIME * 1.3 + root.x * 0.9 + root.z * 0.6;
		VERTEX.x += sin(t) * sway * k;
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
	ALBEDO = c.rgb * COLOR.rgb;
}
"""


func _init() -> void:
	_material = SnowLayer._material(SHADER)
	_material.set_shader_parameter("sway", SWAY)


## Snow lying, 0..1 (FarmWorld.set_snow): every picture's material, and the ones made later.
func set_cover(cover: float) -> void:
	_cover = cover
	for m in materials():
		m.set_shader_parameter("cover", cover)


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


## The rice in the village paddies this season ("" for none).
static func paddy_key(season: String) -> String:
	if not PADDY.has(season):
		return ""
	var p: Array = PADDY[season]
	return "stalk:rice:%d:%s" % [p[0], "ripe" if p[1] else "growing"]


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
