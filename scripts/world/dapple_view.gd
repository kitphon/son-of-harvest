class_name DappleView
extends Node2D
## The leaf shadows (komorebi, DappleRules) over a shaded map in the flat view: whole blocks of
## DappleRules.BLOCK pixels multiplying the ground and props under the figures, redrawn a few
## times a second as the leaves drift.

const T := 16
const REDRAW := 0.25   # seconds between redraws

var map: MapData
var _t := 0.0
var _since := 0.0
var _strength := 0.0


func setup(m: MapData) -> DappleView:
	map = m
	name = "Dapple"
	var mul := CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	material = mul
	_t = float(m.w * 7 + m.h * 3)
	return self


func _process(delta: float) -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var wind: float = float(game.wind_strength()) if game != null else 0.0
	_t += delta * (0.5 + wind)
	_since += delta
	if _since < REDRAW:
		return
	_since = 0.0
	_strength = DappleRules.strength(game, map)
	visible = _strength > 0.0
	if visible:
		queue_redraw()


func _draw() -> void:
	if map == null or _strength <= 0.0:
		return
	var shade := DappleRules.shade_color(map)
	var b := DappleRules.BLOCK
	for y in range(0, map.h * T, b):
		for x in range(0, map.w * T, b):
			var c := DappleRules.multiply_at(Vector2(x + b * 0.5, y + b * 0.5) / T, _t, _strength, shade)
			if c.r < 0.995:
				draw_rect(Rect2(x, y, b, b), c)
