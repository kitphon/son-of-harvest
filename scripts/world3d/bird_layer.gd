class_name BirdLayer
extends Node3D
## Small birds on an outdoor map in 3D (rules: BirdRules, data/birds.json; pictures: BirdArt):
## swallows darting low, crows flying home at dusk, a heron by the water, sparrows hopping by the
## houses. One camera-facing pixel sprite per bird (FarmWorld.make_sprite: unshaded like the
## crops, so the day / night tint and the sun's colour lie on them as on the field), a picture
## chosen by the bird's pose and frame and mirrored to the way it faces on the screen. The farmer's
## place comes from FarmWorld.set_farmer (`farmer`, cells), so sparrows and the heron fly off when
## he comes near. Only outdoor maps build one.

const GROUP := "bird_layers"

var map: MapData
var farm: FarmGrid
var farmer := BirdRules.NO_FARMER
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _state := {}
var _pool: Array[Sprite3D] = []
var _shown: Array[Dictionary] = []


func _init(m: MapData, f: FarmGrid = null) -> void:
	map = m
	farm = f
	name = "Birds"
	_t = 0.0 if not BirdRules.forced().is_empty() else float(m.w * 13 + m.h * 29) * 0.31   # `--birds`: from the start, so a frame is the same


func _ready() -> void:
	add_to_group(GROUP)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock and the weather, then places every bird of the kinds on show.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var amounts := BirdRules.amounts_now(game, map)
	_shown.clear()
	if not amounts.is_empty():
		var key := "%s|%d|%d" % [map.id, game.season, game.day]
		if key != _scene_key:
			_scene_key = key
			_state.clear()
			_scene = BirdRules.scene_of(map, farm, game.day + 28 * game.season)
		for kind in BirdRules.KINDS:
			if amounts.has(kind):
				_shown.append_array(BirdRules.birds(kind, float(amounts[kind]), _t, _scene, farmer, _state))
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var right := Vector2.RIGHT
	if cam != null:
		right = Vector2(cam.global_transform.basis.x.x, cam.global_transform.basis.x.z)
	while _pool.size() < _shown.size():
		var s := FarmWorld.make_sprite(PlaceholderArt.tex("bird:sparrow:stand:0"))
		s.visible = false
		add_child(s)
		_pool.append(s)
	for i in _pool.size():
		var s := _pool[i]
		if i >= _shown.size():
			s.visible = false
			continue
		var b := _shown[i]
		var to_right := (b.dir as Vector2).dot(right) > 0.0
		var tex := PlaceholderArt.tex(BirdRules.key_of(b) + (":r" if to_right else ""))
		s.texture = tex
		s.offset = Vector2(0, tex.get_height() / 2.0)
		s.position = b.pos
		s.visible = true


## The birds showing now (for tests).
func shown() -> Array[Dictionary]:
	return _shown


func shown_count() -> int:
	return _shown.size()
