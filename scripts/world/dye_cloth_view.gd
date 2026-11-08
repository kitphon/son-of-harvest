class_name DyeClothView
extends Node2D
## Shino's drying rack in the flat view (rules: DyeCloth; the 3D view's is
## OutdoorProps.cloth_rack): the bamboo posts and poles of each "cloth_rack" prop, and while the
## cloth is out (DyeCloth.out_now) one indigo length over each pole, drawn from the same
## PlaceholderArt "cloth:<hex>" pictures, the back pole first. A point (x, y up, z) of the 3D
## rack shows at (x, z - y) cells, as FestivalView's lights do. In a wind the lengths' lower
## strips shift downwind by whole pixels, the hem the most (DyeCloth.stream, the 3D cloth's own
## shear), redrawn at data/wind.json "flat".rate. MapView leaves these props out of its boxes.

const T := 16
const BANDS := 6

var map: MapData
var _racks: Array[Dictionary] = []
var _t := 0.0
var _frame := -1
var _wind := 0.0
var _out := false


func _init(m: MapData) -> void:
	map = m
	name = "DyeCloth"
	for p in m.props:
		if p.kind == DyeCloth.KIND:
			_racks.append(p)
	_t = float(m.w * 13 + m.h * 7) * 0.41


func _ready() -> void:
	add_to_group(FlatLight.GROUP)   # the lengths take the world's light (redrawn when it changes)
	var game := (Engine.get_main_loop() as SceneTree).root.get_node("Game")
	game.minute_passed.connect(refresh)
	refresh()


func has_racks() -> bool:
	return not _racks.is_empty()


## Are the lengths out now (on the first rack)?
func cloth_out() -> bool:
	return _out


## Reads the clock, today's weather and the wind.
func refresh() -> void:
	if _racks.is_empty():
		return
	var game := (Engine.get_main_loop() as SceneTree).root.get_node("Game")
	_out = DyeCloth.out_now(_racks[0], game)
	_wind = game.wind_strength()
	queue_redraw()


func _process(delta: float) -> void:
	if not _out or _wind <= 0.0:
		return
	_t += delta
	var f := int(_t * float(load("res://scripts/world/crop_patches.gd").flat_config().get("rate", 8)))
	if f != _frame:
		_frame = f
		queue_redraw()


## The whole-pixel shift of each strip of a length (top first) at time `t`: the hem's shear
## times the strip's depth down the drop; the top strip, over the pole, stays put.
static func band_shifts(wind: float, t: float, phase: float) -> Array[int]:
	var hem := DyeCloth.stream(wind, t, phase) * DyeCloth.DROP * T
	var out: Array[int] = []
	for i in BANDS:
		out.append(roundi(hem * float(i) / float(BANDS - 1)) if i > 0 else 0)
	return out


func _draw() -> void:
	for p in _racks:
		_draw_rack(p)


func _draw_rack(p: Dictionary) -> void:
	var r := Rect2(Vector2(p.cell[0], p.cell[1]), Vector2(p.size[0], p.size[1]))
	var x0 := (r.position.x + 0.1) * T
	var x1 := (r.end.x - 0.16) * T
	var post := Color("a89a60")
	var pole := Color("cdbd80")
	var shades := DyeCloth.shades(p)
	for i in shades.size():   # the back pole first, the front one over it
		var z := (r.position.y + i + 0.5) * T
		var top := z - DyeCloth.POLE_Y * T
		for x in [x0, x1]:
			draw_rect(Rect2(floorf(x), top - 2, 1, z - top + 2), post)
		if _out:
			_draw_length(shades[i], Vector2(roundf((x0 + x1) / 2), roundf(top)), 1.3 * i + r.position.x)
		draw_rect(Rect2(floorf(x0) - 1, roundf(top) - 1, x1 - x0 + 3, 1), pole)


## One length hung from `at` (the middle of its pole, pixels), cut in BANDS strips shifted
## downwind by the wind.
func _draw_length(c: Color, at: Vector2, phase: float) -> void:
	var tex := PlaceholderArt.tex(DyeCloth.art_key(c))
	var w := tex.get_width()
	var h := tex.get_height()
	var shifts := band_shifts(_wind, _t, phase)
	# measured where the 3D length's middle hangs: half its drop under the pole, over the pole's row
	var light := FlatLight.at_mid(Vector3(at.x / T, DyeCloth.POLE_Y - DyeCloth.DROP / 2, at.y / T + DyeCloth.POLE_Y))
	for i in BANDS:
		var y0 := i * h / BANDS
		var y1 := (i + 1) * h / BANDS
		var src := Rect2(0, y0, w, y1 - y0)
		draw_texture_rect_region(tex, Rect2(at.x - w / 2 + shifts[i], at.y - 1 + y0, w, y1 - y0), src, light)
