class_name ToolFxView
extends Node2D
## The tool-use effects in the flat view (rules: ToolFxRules, data/tool_fx.json; the 3D view's is
## ToolFxLayer): on each Game.tool_fx a Burst node that draws its bits as whole pixels, a bit's
## height lifting it up the screen (ToolFxRules.flat_of). Each burst sorts with the standing
## figures: it is put in the map view's FigureLayer (falling back to this node without one) at the
## ground of its first cell, so bits kicked up from the cell below the farmer draw over the farmer's
## feet and bits from the cell above draw behind the farmer, as a sparrow there would. Being in the
## view, they are under the fliers' Air pass, the weather, the night tint (the CanvasModulate) and the
## mine's light, which darken them with everything else; FlatLight gives them the sun's share.
## A burst frees itself once its last particle is gone. main_2d adds one to every map view.

const T := 16
const ANCHOR := 6   # px below the first cell's middle: where its bits fall back, for the sort

static var _seed := 0


func _init() -> void:
	name = "ToolFx"


func _ready() -> void:
	Game.tool_fx.connect(add_burst)


## Where the bursts go: the view's figure layer, else this node.
func host() -> Node2D:
	var layer := FigureLayer.of(get_parent()) if is_inside_tree() else null
	return layer if layer != null and layer.is_inside_tree() else self


## Starts a burst (ToolFxRules.burst); returns its node (null for an empty one).
func add_burst(b: Dictionary) -> Burst:
	if b.is_empty():
		return null
	_seed += 1
	var first: Vector2i = b.cells[0]
	var n := Burst.new(ToolFxRules.particles(b, _seed * 7919 + 13), Vector2(first * T) + Vector2(T / 2.0, T / 2.0 + ANCHOR))
	host().add_child(n)
	return n


## The bursts still flying (in the figure layer or here).
func bursts() -> Array[Burst]:
	var out: Array[Burst] = []
	for c in host().get_children():
		if c is Burst and not c.is_queued_for_deletion():
			out.append(c)
	return out


## One swing's bits: steps them each frame, draws them as whole pixels, frees itself when none
## are left. Its position is the burst's ground spot (map pixels); the bits are drawn from it.
class Burst extends Node2D:
	var parts: Array[Dictionary] = []

	func _init(p: Array[Dictionary], at: Vector2) -> void:
		parts = p
		position = at
		name = "Burst"

	func _process(delta: float) -> void:
		advance(delta)

	## Moves the bits on by `delta` seconds; frees the burst when they are all gone.
	func advance(delta: float) -> void:
		parts = ToolFxRules.step(parts, delta)
		if parts.is_empty():
			queue_free()
			return
		modulate = FlatLight.at(position, 6.0, FarmWorld.PX)
		queue_redraw()

	## The pixels to draw now: [{at: map pixel (top-left), wide, color}].
	func pixels() -> Array[Dictionary]:
		var out: Array[Dictionary] = []
		for s in ToolFxRules.specks(parts):
			var w := maxi(1, roundi(s.size))
			out.append({"at": ToolFxRules.flat_of(s.pos) - Vector2(floori(w / 2.0), w - 1), "wide": w, "color": s.color})
		return out

	func _draw() -> void:
		for p in pixels():
			draw_rect(Rect2(p.at - position, Vector2(p.wide, p.wide)), p.color)
