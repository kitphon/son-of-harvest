class_name FurinLayer
extends Node3D
## The wind chime under the farmhouse's eave over the engawa, in 3D (rules: FurinRules,
## data/furin.json; picture: PlaceholderArt "furin"). A pivot at the hang point under the eave
## turns about its z axis by FurinRules.sway_angle with the farm's wind (FarmWorld.wind, set from
## data/wind.json each morning); the picture hangs under the pivot, one camera-facing sprite
## (FarmWorld.make_sprite). Shown only while FurinRules.hangs_now (summer, out in the open air);
## taken in otherwise. Only the farm builds one (main_3d.new_world).

var map: MapData
var swing := 0.0   # the pivot's angle now, radians (for tests)
var _t := 0.0
var _pivot: Node3D


func _init(m: MapData) -> void:
	map = m
	name = "Furin"


func _ready() -> void:
	var cfg := FurinRules.config()
	var tex := PlaceholderArt.tex(FurinRules.KEY)
	var px := float(cfg.pixel_size)
	_pivot = Node3D.new()
	_pivot.position = FurinRules.place(cfg)
	add_child(_pivot)
	var s := FarmWorld.make_sprite(tex)
	s.pixel_size = px
	s.offset = Vector2.ZERO
	s.position = Vector3(0, -tex.get_height() * px / 2.0, 0)   # hangs from the pivot by its top
	_pivot.add_child(s)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## The clock and the weather decide whether it hangs; the farm's wind swings it.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var fw := get_parent() as FarmWorld
	visible = FurinRules.hangs_now(game, map)
	swing = FurinRules.sway_angle(fw.wind if fw != null else 0.0, _t) if visible else 0.0
	if _pivot != null:
		_pivot.rotation.z = swing
