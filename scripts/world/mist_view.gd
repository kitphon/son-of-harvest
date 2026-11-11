class_name MistView
extends Node2D
## Morning mist over an outdoor map's water and paddies in the flat view (rules: MistRules,
## data/mist.json; the 3D view's is MistLayer). Each soft sheet is seen from above as a few
## stepped ellipses one inside the other (data "flat".rings), long along the wind, filled
## without smoothing round a whole-pixel centre, so the bank is denser in the middle and the edges stay crisp pixel steps,
## not a blur. A sheet's height lifts it up the screen (data "flat".height_px). Drawn plain:
## the scene's CanvasModulate night tint lies over it. Made with the map's view; indoor maps
## and the mine get nothing.

const T := 16
const POINTS := 14

var map: MapData
var farm: FarmGrid
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _wind := 0.0
var _amounts := {}
var _rgb := Color.WHITE
var _season := ""


func setup(m: MapData, f: FarmGrid = null) -> MistView:
	map = m
	farm = f
	name = "Mist"
	_t = float(m.w * 23 + m.h * 11) * 0.41
	refresh()
	return self


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock, the weather and the wind.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	_wind = float(game.wind_strength()) if game != null else 0.0
	_amounts = MistRules.amounts_now(game, map, _wind)
	visible = not _amounts.is_empty()
	if not visible:
		return
	var key := "%s|%d|%d|%d" % [map.id, game.season, game.day, MistRules.rice_cells(farm).size()]
	if key != _scene_key:
		_scene_key = key
		_scene = MistRules.scene_of(map, farm)
	_rgb = MistRules.color_now(game)
	_season = game.season_name()
	queue_redraw()


## The sheets now, on screen: [{at: pixel centre, size: Vector2 pixels (along, across), angle,
## alpha}].
func patches() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _amounts.is_empty():
		return out
	var hp := float(MistRules.config().flat.height_px)
	for s in MistRules.sheets(_scene, _amounts, _t, _wind, _season):
		var p: Vector3 = s.pos
		out.append({
			"at": (Vector2(p.x, p.z) * T - Vector2(0, p.y * hp)).round(),
			"size": (s.size as Vector2) * T,
			"angle": float(s.angle),
			"alpha": float(s.alpha),
		})
	return out


## The outline of one ring: an ellipse of half-axes `half` turned by `angle` round `at` (a whole
## pixel); the polygon is filled without smoothing, so its edge falls on whole pixels.
static func ring(at: Vector2, half: Vector2, angle: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rot := Transform2D(angle, Vector2.ZERO)
	for k in POINTS:
		var a := TAU * float(k) / float(POINTS)
		pts.append(at + rot * Vector2(cos(a) * half.x, sin(a) * half.y))   # not rounded: two points on one pixel would break the polygon
	return pts


func _draw() -> void:
	var fl: Dictionary = MistRules.config().flat
	var rings := maxi(int(fl.rings), 1)
	var share := float(fl.ring_alpha)
	for p in patches():
		var a: float = p.alpha
		if a < 0.004:
			continue
		var c := Color(_rgb, a * share)
		for k in rings:
			var scale := 1.0 - float(k) / float(rings) * 0.75
			var half: Vector2 = p.size * 0.5 * scale
			if half.y < 1.0:
				break
			draw_colored_polygon(ring(p.at, half, p.angle), c)
