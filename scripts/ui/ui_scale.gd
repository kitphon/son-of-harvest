class_name UiScale
extends RefCounted
## The "UI size" setting (Game.ui_scale) on a piece of the UI: the HUD's corner groups, a
## menu box, the text box. A piece grows about a pivot that keeps it where it was: the point
## that splits the screen the way the piece's free space is split, so a box in the middle
## grows from its middle and one by an edge keeps hugging that edge (its margins shrink in
## step). It grows only as far as it still fits on the screen; at 1.0 nothing moves.
## Non-whole sizes draw some picture pixels a screen pixel wider than others: the price of
## a bigger UI on a 480 x 270 picture.

const STEP := 0.25


## The pivot for `rect` on `screen`: per axis, the free space before the rect over all the
## free space, times the screen. A rect as big as the screen pivots on its middle.
static func pivot(rect: Rect2, screen: Vector2) -> Vector2:
	var p := screen / 2.0
	var free := screen - rect.size
	if free.x > 0.0:
		p.x = screen.x * rect.position.x / free.x
	if free.y > 0.0:
		p.y = screen.y * rect.position.y / free.y
	return p


## The scale to use: `wanted`, less if `size` scaled would not fit on `screen`, in STEPs
## (the sizes the setting offers, so a piece that can't have 125% doesn't get 108%), never
## below 1.
static func fit(wanted: float, size: Vector2, screen: Vector2) -> float:
	var s := maxf(wanted, 1.0)
	if size.x > 0.0 and size.x * s > screen.x:
		s = floorf(screen.x / size.x / STEP) * STEP
	if size.y > 0.0 and size.y * s > screen.y:
		s = floorf(screen.y / size.y / STEP) * STEP
	return maxf(s, 1.0)


## Where `rect` lands at scale `s` about its pivot (what fit() allows of `wanted`).
static func placed(rect: Rect2, wanted: float, screen: Vector2) -> Rect2:
	var s := fit(wanted, rect.size, screen)
	return Rect2(offset(rect, s, screen) + rect.position * s, rect.size * s)


## What to add to a point scaled by `s` so that `rect` grows about its pivot (whole pixels).
static func offset(rect: Rect2, s: float, screen: Vector2) -> Vector2:
	return (pivot(rect, screen) * (1.0 - s)).round()


## Scales a whole CanvasLayer so that `rect` (its main box, in layer pixels) grows about its
## pivot; whatever else is on the layer (a dim, a click catcher) grows with it and, the pivot
## being on screen, still covers the screen.
static func apply_layer(layer: CanvasLayer, rect: Rect2, wanted: float, screen: Vector2) -> void:
	var s := fit(wanted, rect.size, screen)
	layer.scale = Vector2(s, s)
	layer.offset = offset(rect, s, screen)
