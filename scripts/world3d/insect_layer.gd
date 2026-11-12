class_name InsectLayer
extends Node3D
## Small flying insects on an outdoor map in 3D (rules: InsectRules, data/insects.json; pictures:
## InsectArt): butterflies wandering over the crops and grass, red dragonflies hovering, darting and
## resting on fence posts. One camera-facing pixel sprite per insect (FarmWorld.make_sprite:
## unshaded like the crops, so the day / night tint and the sun's colour lie on them as on the
## field), a picture chosen by its pose and frame and mirrored to the way it faces on the screen.
## The farmer's place comes from FarmWorld.set_farmer (`farmer`, cells), so a resting dragonfly
## lifts off and a butterfly veers away when he comes near, and `others` (cells) are the villagers,
## the dog and the walking child that do it too. The sprites are alpha-cut (drawn with the solid
## things, depth-tested), as the birds'. Only outdoor maps build one.

const GROUP := "insect_layers"

var map: MapData
var farm: FarmGrid
var farmer := InsectRules.NO_FARMER
var others: Array = []   # the other walkers' places (cells), from FarmWorld.set_farmer
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _farm_key := ""
var _state := {}
var _pool: Array[Sprite3D] = []
var _shown: Array[Dictionary] = []


func _init(m: MapData, f: FarmGrid = null) -> void:
	map = m
	farm = f
	name = "Insects"
	_t = 0.0 if not InsectRules.forced().is_empty() else float(m.w * 17 + m.h * 31) * 0.27   # `--insects`: from the start, so a frame is the same


func _ready() -> void:
	add_to_group(GROUP)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock, the weather and the wind, then places every insect of the kinds on show.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var amounts := InsectRules.amounts_now(game, map)
	_shown.clear()
	if not amounts.is_empty():
		var key := "%s|%d|%d" % [map.id, game.season, game.day]
		var fkey := InsectRules.farm_key(farm)
		if key != _scene_key or fkey != _farm_key:   # a new day, or something planted or harvested
			if key != _scene_key:
				_state.clear()
			_scene_key = key
			_farm_key = fkey
			_scene = InsectRules.scene_of(map, farm, game.day + 28 * game.season)
		for kind in InsectRules.KINDS:
			if amounts.has(kind):
				_shown.append_array(InsectRules.insects(kind, float(amounts[kind]), _t, _scene, farmer, _state, {}, others))
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var right := Vector2.RIGHT
	if cam != null:
		right = Vector2(cam.global_transform.basis.x.x, cam.global_transform.basis.x.z)
	while _pool.size() < _shown.size():
		var s := FarmWorld.make_sprite(PlaceholderArt.tex("insect:butterfly:fly:0"))
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
		var tex := PlaceholderArt.tex(InsectRules.key_of(b) + (":r" if to_right else ""))
		s.texture = tex
		s.offset = Vector2(0, tex.get_height() / 2.0)
		s.position = b.pos
		s.visible = true


## The insects showing now (for tests).
func shown() -> Array[Dictionary]:
	return _shown


func shown_count() -> int:
	return _shown.size()
