class_name WetLayer
extends Node3D
## The wet look of an outdoor world in rain, in 3D (rules: WetRules, data/wet.json): set on the
## world it is a child of (FarmWorld, MapWorld). The grounds (the map's and the land past its
## edge: SnowLayer's ground shader) get the `wet` uniform, which darkens, saturates and glosses
## each cell by its surface (their wet masks); the lit StandardMaterial3Ds of the props and
## buildings (kawara and thatch roofs, stone lanterns and rocks, the well, wood) are wetted by
## WetRules.wet_material, and put back exactly as they were at wetness 0. Redone only when the
## wetness moves a step or the world gets new children (a festival's props, the day's figures).

var map: MapData
var _step := -1
var _children := -1


func _init(m: MapData) -> void:
	map = m
	name = "Wet"


func _ready() -> void:
	refresh()


func _process(_delta: float) -> void:
	refresh()


## Reads the weather and the clock; rewets the world when the wetness moved a step.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var w := get_parent()
	if game == null or w == null:
		return
	var step := WetRules.step_of(WetRules.wetness_now(game, map))
	if step > 0 and w.get("wet_dirty") == true:   # the farm's field changed (a cell hoed in the rain)
		w.call("update_wet_mask")
	var n := w.get_child_count()
	if step != _step or (n != _children and step > 0):
		_step = step
		_children = n
		apply(w, float(step) / 50.0)


## The wetness this layer last set (0..1).
func wetness() -> float:
	return maxf(_step, 0) / 50.0


## Wets everything of world `w` to `wet` (0 = dry, as built). Returns how many materials it set.
static func apply(w: Node, wet: float) -> int:
	var cfg := WetRules.config()
	var count := 0
	for n in w.find_children("*", "GeometryInstance3D", true, false):
		var m := (n as GeometryInstance3D).material_override
		if m is StandardMaterial3D:
			if WetRules.wet_material(m, wet, cfg):
				count += 1
		elif SnowLayer.is_ground(m):
			(m as ShaderMaterial).set_shader_parameter("wet", wet)
			count += 1
	return count
