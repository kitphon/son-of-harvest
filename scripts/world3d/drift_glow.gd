class_name DriftGlow
extends Control
## The summer night's fireflies in the 3D view: a tiny warm point with a faint halo at each
## firefly of the maps on show (DriftLayer.fireflies), added over the night tint like the other
## lights, so they glow instead of being darkened by it. A firefly is one pixel of the game's
## picture, with a faint plus of dim ones round it at the crest of its blink.


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = add


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var halo := float(DriftRules.config().flat.halo)
	for n in get_tree().get_nodes_in_group(DriftLayer.GROUP):
		var layer := n as DriftLayer
		if layer == null or not layer.is_visible_in_tree():
			continue
		for f in layer.fireflies():
			var w: Vector3 = f.pos
			var a: float = f.alpha
			if a < 0.05 or cam.is_position_behind(w):
				continue
			var at := cam.unproject_position(w).round()
			var c: Color = f.color
			draw_rect(Rect2(at, Vector2.ONE), Color(c, a))
			if a > 0.6:   # at the crest of the blink a faint plus round it
				var h := Color(c, a * halo)
				for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
					draw_rect(Rect2(at + d, Vector2.ONE), h)
