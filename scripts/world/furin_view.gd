class_name FurinView
extends Node2D
## The wind chime under the farmhouse's eave, in the flat view (rules: FurinRules, data/furin.json;
## picture: PlaceholderArt "furin"; the 3D view's is FurinLayer). Its top sits at the eave's height
## over the engawa (place: cells, `top` in world height lifted by flat.px_per_height), drawn at
## whole pixels and shifted sideways by the swing (flat.hang_px at a full swing). It takes the
## world's light like the story props. Made only for the farm (main_2d).

const T := 16

var map: MapData
var _t := 0.0


func setup(m: MapData) -> FurinView:
	map = m
	name = "Furin"
	return self


func _ready() -> void:
	add_to_group(FlatLight.GROUP)


func _process(delta: float) -> void:
	_t += delta
	refresh()


func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	visible = FurinRules.hangs_now(game, map)
	queue_redraw()


## Where the chime is now: `top` the cord's pixel, `shift` its sideways swing in whole pixels.
func placed() -> Dictionary:
	var cfg := FurinRules.config()
	var flat: Dictionary = cfg.flat
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var wind: float = game.wind_strength() if game != null else 0.0
	var p := FurinRules.place(cfg)
	var top := Vector2(roundf(p.x * T), roundf(p.z * T - p.y * float(flat.px_per_height)))
	var shift := roundf(sin(FurinRules.sway_angle(wind, _t, cfg)) / maxf(deg_to_rad(float(cfg.sway.max_deg)), 0.001) * float(flat.hang_px))
	return {"top": top, "shift": shift}


func _draw() -> void:
	if not visible:
		return
	var tex := PlaceholderArt.tex(FurinRules.KEY)
	var at := placed()
	var pos := Vector2(roundf(at.top.x - tex.get_width() / 2.0 + at.shift), at.top.y)
	var feet := Vector2(pos.x + tex.get_width() / 2.0, pos.y + tex.get_height() - 1)
	draw_texture(tex, pos, FlatLight.at(feet, tex.get_height(), FlatLight.field_px()))
