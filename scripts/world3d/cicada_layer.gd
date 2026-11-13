class_name CicadaLayer
extends Node3D
## The cicadas one can see on an outdoor map in 3D (rules: CicadaRules, data/cicadas.json;
## pictures: CicadaArt): a few clinging to the camera side of the broadleaf trees' trunks under the
## crown, pumping as they sing, and one flying off with a buzz when the farmer (or a villager, the
## dog, the walking child) comes close. One camera-facing pixel sprite each (FarmWorld.make_sprite:
## unshaded like the crops, the day / night tint and the sun's colour on them), alpha-cut and
## depth-tested so the trunk hides one round its far side; set a hair towards the eye off the bark
## so it never sinks into it. The farmer's place comes from FarmWorld.set_farmer (`farmer`, cells),
## the other walkers' as `others`. Only outdoor maps build one.

const GROUP := "cicada_layers"
const OFF_BARK := 0.03   # cells towards the eye off the trunk's face

var map: MapData
var farmer := CicadaRules.NO_FARMER
var others: Array = []   # the other walkers' places (cells), from FarmWorld.set_farmer
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _state := {}
var _pool: Array[Sprite3D] = []
var _shown: Array[Dictionary] = []


func _init(m: MapData) -> void:
	map = m
	name = "Cicadas"


func _ready() -> void:
	add_to_group(GROUP)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock and the weather, then places every cicada of the kinds singing now.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var amounts := CicadaRules.amounts_now(game, map)
	_shown.clear()
	var fled := false
	if not amounts.is_empty():
		var key := "%s|%d|%d" % [map.id, game.season, game.day]
		if key != _scene_key:   # a new day: other trees, nobody startled
			_scene_key = key
			_state.clear()
			_scene = CicadaRules.scene_of(map, game.day + 30 * game.season)
		for kind in CicadaRules.KINDS:
			if amounts.has(kind):
				for c in CicadaRules.cicadas(kind, float(amounts[kind]), _t, _scene, farmer, _state, {}, others):
					fled = fled or bool(c.fled)
					_shown.append(c)
	if fled and is_inside_tree():
		var sfx := get_tree().root.get_node_or_null("Sfx")
		if sfx != null:
			sfx.play("cicada_buzz")
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var right := Vector2.RIGHT
	var eye := Vector3(0.634, 0.448, 0.634)   # CameraLens.back at the medium lens
	if cam != null:
		right = Vector2(cam.global_transform.basis.x.x, cam.global_transform.basis.x.z)
		eye = cam.global_transform.basis.z
	while _pool.size() < _shown.size():
		var s := FarmWorld.make_sprite(PlaceholderArt.tex("cicada:semi:cling:0"))
		s.visible = false
		add_child(s)
		_pool.append(s)
	for i in _pool.size():
		var s := _pool[i]
		if i >= _shown.size():
			s.visible = false
			continue
		var c := _shown[i]
		var to_right := (c.dir as Vector2).dot(right) > 0.0
		var tex := PlaceholderArt.tex(CicadaRules.key_of(c) + (":r" if to_right else ""))
		s.texture = tex
		s.offset = Vector2(0, tex.get_height() / 2.0) if CicadaRules.flying(c) else Vector2.ZERO   # a clinging one is centred on its spot
		s.position = (c.pos as Vector3) + (eye * OFF_BARK if not CicadaRules.flying(c) else Vector3.ZERO)
		s.visible = true


## The cicadas showing now (for tests).
func shown() -> Array[Dictionary]:
	return _shown


func shown_count() -> int:
	return _shown.size()
