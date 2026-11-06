class_name UiStyle
extends RefCounted
## The one look every screen shares: washi paper pages in dark wood frames, warm ink text.
## The pieces are drawn in code (PlaceholderArt "ui:frame:<paper|wood>": a 32 x 32 nine-patch with a
## 4 px border and a 24 x 24 tiling centre, so the paper fibre and the wood grain never stretch).
## Every screen builds its boxes with `panel()` and takes its colours from here, so changing the
## look means changing this file and the frame art, not each screen.

const INK := Color("3b2a1a")            # text on paper
const INK_SOFT := Color("7a6040")       # notes, hints, off entries
const INK_OFF := Color("b4a27e")        # greyed-out entries
const RULE := Color("d2bf94")           # thin rules on paper
const BAR := Color("ead9b0")            # the cursor bar on a paper list
const PAPER_TEXT := Color("f6ead0")     # light text on the wooden title strips
const SEAL := Color("c8442c")           # vermilion, like a name seal: marks and warnings
const WASH := Color(0.965, 0.918, 0.816, 0.6)   # paper, a little see-through, over the picture
const DIM := Color(0.1, 0.07, 0.04, 0.45)       # the warm dark behind a full screen
const NINE_MARGIN := 4


## A paper or wood panel (kind = "paper" or "wood"), added to `parent` when given. The caller sets
## position and size.
static func panel(parent: Node, kind: String) -> NinePatchRect:
	var b := NinePatchRect.new()
	b.texture = PlaceholderArt.tex("ui:frame:" + kind)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		b.set_patch_margin(side, NINE_MARGIN)
	b.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent != null:
		parent.add_child(b)
	return b


## Same, placed at a rectangle.
static func panel_at(parent: Node, kind: String, r: Rect2i) -> NinePatchRect:
	var b := panel(parent, kind)
	b.position = r.position
	b.size = r.size
	return b
