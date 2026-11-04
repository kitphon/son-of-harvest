class_name NightLights
extends Control
## Lit house windows over the 3D view at dusk and night. main_3d puts it in the tint's layer,
## after the multiply tint, so the warm light is added on top of the night blue instead of
## being darkened by it: each window of the FarmWorld on show (`FarmWorld.windows`, the
## farmhouse and the village houses) gets its own paper picture added in warm light over its
## pane, and a soft glow round it. How bright is Game.window_light() (data/light.json
## "windows": with the dark, in the lit hours). A window turned from the camera, or behind
## another building, stays dark; a building faded see-through lets the light through as much.

const GROUP := "lit_windows"
const DOT_SIZE := 32

var _dot: Texture2D


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = add
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = DOT_SIZE
	t.height = DOT_SIZE
	_dot = t


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var glow := Game.window_light()
	var cam := get_viewport().get_camera_3d()
	if glow <= 0.0 or cam == null:
		return
	var rules: Dictionary = Game.light_data().get("windows", {})
	for w in get_tree().get_nodes_in_group(GROUP):
		if w is FarmWorld and w.is_inside_tree() and w.visible:
			for win in w.windows:
				var seen := how_seen(win, cam.global_position, w.occluders)
				if seen > 0.0:
					_draw_window(win, cam, glow * seen, rules)


## How much of window `win` the eye at `eye` sees, 0..1: 0 when its wall is turned away or a
## solid building stands between; a building faded see-through lets through its fade. The
## window's own building (whose box holds the window) never hides it.
static func how_seen(win: Dictionary, eye: Vector3, occ: Occluders) -> float:
	var at: Vector3 = win.pos + win.normal * 0.05
	if win.normal.dot(eye - at) <= 0.0:
		return 0.0
	var seen := 1.0
	for i in occ.count():
		var box := occ.box_of(i)
		if not box.has_point(at) and box.intersects_segment(at, eye) != null:
			seen *= occ.fade_of(i)
	return seen


## The window's four corners in the world, in the order of its picture's UVs (top left first).
static func corners(win: Dictionary) -> Array[Vector3]:
	var right: Vector3 = Vector3.UP.cross(win.normal).normalized()
	var half: Vector2 = win.size / 2.0
	var c: Vector3 = win.pos
	return [c - right * half.x + Vector3.UP * half.y, c + right * half.x + Vector3.UP * half.y,
		c + right * half.x - Vector3.UP * half.y, c - right * half.x - Vector3.UP * half.y]


func _draw_window(win: Dictionary, cam: Camera3D, k: float, rules: Dictionary) -> void:
	var pts := PackedVector2Array()
	for p in corners(win):
		if cam.is_position_behind(p):
			return
		pts.append(cam.unproject_position(p))
	var warm := Color(str(rules.get("color", "ffb25c")))
	var halo := warm
	halo.a = float(rules.get("halo", 0.35)) * k
	var at := cam.unproject_position(win.pos)
	var px := pts[0].distance_to(pts[1]) * float(rules.get("halo_size", 2.4))
	draw_texture_rect(_dot, Rect2(at - Vector2(px, px * 0.8) / 2, Vector2(px, px * 0.8)), false, halo)
	var pane := warm
	pane.a = float(rules.get("pane", 0.85)) * k
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	draw_colored_polygon(pts, pane, uvs, PlaceholderArt.tex(win.key))
