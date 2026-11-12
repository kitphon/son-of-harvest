class_name FigureLayer
extends Node2D
## The standing figures of the flat view, drawn by their feet: further down the screen (south) is
## in front. One y-sorted node, the map view's last child (over the ground, the props, roofs,
## lights, mist and the floor's things, under the thrown item in flight, the fliers' Air pass, the
## weather, the night tint and the HUD): Godot sorts every child (and the children of y-sorted
## children) by its origin's y, ties in tree order. In it: the VillagerView (y-sorted: each
## villager's and the child's sprite is a figure, what they hold and the note puff ride on it), the
## AnimalView (y-sorted: each animal and the dog a node of its own; the eggs it draws itself at
## y 0, so under every figure), the farmer (main_2d moves the Player in on every map change; what
## the farmer carries, the lantern, the rod line and the "!" are drawn by the Player, so they go
## with the farmer) and the birds on the ground (BirdView.Ground).
##
## Every figure's origin is FOOT px above the bottom of its picture: the farmer's and the
## villagers' spot (their feet 2 px below it), so figures of any kind compare by where their feet
## touch the ground. The farmer's contact shadow is drawn by `Shadows`, the sibling just before
## this node, under every figure.

const FOOT := 2   # a figure's origin is this far above the bottom row of its picture

var farmer: Node2D
var shadows: Node2D   # the farmer's contact shadow, in the ground order just before the figures


func _init() -> void:
	name = "Figures"
	y_sort_enabled = true


## Adds the shadows and the figure layer at the end of `view` (call after its other children).
static func build(view: Node2D, farmer_node: Node2D = null) -> FigureLayer:
	var layer := FigureLayer.new()
	layer.farmer = farmer_node
	layer.shadows = Node2D.new()
	layer.shadows.name = "Shadows"
	layer.shadows.draw.connect(layer._draw_shadows)
	view.add_child(layer.shadows)
	view.add_child(layer)
	return layer


## The figure layer of a map view (null when it has none).
static func of(view: Node) -> FigureLayer:
	return view.get_node_or_null("Figures") as FigureLayer if view != null else null


## The map view's VillagerView (in its figure layer), or null.
static func villagers_of(view: Node) -> VillagerView:
	var layer := of(view)
	if layer == null:
		return null
	for n in layer.get_children():
		if n is VillagerView:
			return n
	return null


## The map view's AnimalView (in its figure layer), or null.
static func animals_of(view: Node) -> AnimalView:
	var layer := of(view)
	if layer == null:
		return null
	for n in layer.get_children():
		if n is AnimalView:
			return n
	return null


func _process(_delta: float) -> void:
	if shadows != null:
		shadows.queue_redraw()
	var parent := get_parent()
	if parent != null and get_index() != parent.get_child_count() - 1:   # something added to the view later stays under the figures
		if shadows != null and shadows.get_parent() == parent:
			parent.move_child(shadows, -1)
		parent.move_child(self, -1)


func _draw_shadows() -> void:
	if farmer == null or not is_instance_valid(farmer) or not farmer.visible or farmer.get_parent() != self:
		return
	shadows.draw_circle(farmer.position + Vector2(0, 2), 5, Color(0, 0, 0, 0.25))


## The figures in the order Godot draws them (for tests and checks): every canvas item of this
## layer's sort (children, and the children of y-sorted children, recursively) by its origin's y in
## this layer, ties in tree order; each one's own children (not y-sorted) are drawn with it.
func draw_order() -> Array[CanvasItem]:
	var items: Array[CanvasItem] = []
	_collect(self, items)
	var to_me := get_global_transform().affine_inverse()
	var keyed := []
	for i in items.size():
		keyed.append([(to_me * items[i].get_global_transform()).origin.y, i, items[i]])
	keyed.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var out: Array[CanvasItem] = []
	for k in keyed:
		if (k[2] as CanvasItem).is_visible_in_tree():
			out.append(k[2])
	return out


func _collect(n: Node, out: Array[CanvasItem]) -> void:
	for c in n.get_children():
		if c is CanvasItem:
			out.append(c)
			if (c as CanvasItem).y_sort_enabled:
				_collect(c, out)
