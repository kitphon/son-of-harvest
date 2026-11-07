class_name WaterView
extends Sprite2D
## The moving skin on the water in the flat view: the farm pond (FarmView), the village pond and
## the river (MapView). It is the 2D twin of the 3D sheet (scripts/world3d/water_surface.gd): pale
## sun glints and a few darker troughs drifting over the water, nothing else. The ground tile
## under it (PlaceholderArt "water") stays the still base.
## The picture is one pixel per map pixel (16 per cell) with alpha on the water pixels only: a
## land side keeps its bank (2 px) and foam line (1 px) still, as the 3D sheet insets 3 px there
## (LAND_INSET). The shader samples the pattern at the centre of its pixel, so the glints step in
## pixel-art jumps and keep the pixel grid. Nearest filtering, no smoothing. Under the view's
## CanvasModulate like the ground, so it darkens at dusk and night with it.
## The constants below copy the 3D sheet's SHADER (speeds, thresholds, colours). The alphas are
## lower here (glint 0.3, trough 0.2 against 0.5 and 0.32): the 3D sheet takes the sun's light
## term, this flat picture takes none, so the same alpha read too strong on the blue. They are
## not in data yet, so change both together.

const T := 16
const INSET := 3   # px in from a land side (the bank and foam line of the ground tile)

const SHADER := """shader_type canvas_item;
uniform vec2 size_px = vec2(16.0, 16.0);   // the map in pixels
uniform vec3 glint_color : source_color = vec3(1.0, 0.93, 0.7);
uniform vec3 trough_color : source_color = vec3(0.13, 0.31, 0.56);
uniform vec2 drift = vec2(0.5, 0.25);
void fragment() {
	if (texture(TEXTURE, UV).a < 0.5) {
		discard;   // a bank, the foam line or land
	}
	vec2 pix = floor(UV * size_px);
	vec2 p = (pix + 0.5) / 16.0;   // cell units, as the 3D sheet's world.xz
	float t = TIME;
	vec2 q = p - drift * t * 0.18;
	float a = sin(q.x * 2.3 + q.y * 1.1 + t * 0.55) + sin(q.x * 1.3 - q.y * 2.5 - t * 0.4);
	float b = sin((q.x + q.y) * 3.7 + sin(q.y * 2.1 + t * 0.5) * 1.7 - t * 0.9);
	float h = 0.25 * a + 0.5 * b;   // -1 .. 1
	if (h > 0.62) {
		COLOR = vec4(glint_color, 0.3);
	} else if (h < -0.7) {
		COLOR = vec4(trough_color, 0.2);
	} else {
		discard;
	}
}
"""

var water_cells := 0   # how many water cells the picture covers (0 = no sheet)


## Sets the picture for a w x h map. `water_at(c)` is true on a water cell (in bounds only).
## `edge_bank`: a land side past the map's edge still gets its bank (the farm's ground does; a
## map's tile does not). Call once before it is in the tree or right after; it draws nothing
## itself.
func build(w: int, h: int, water_at: Callable, edge_bank: bool) -> void:
	water_cells = 0
	var img := Image.create(w * T, h * T, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			if not water_at.call(c):
				continue
			water_cells += 1
			var x0 := 0 if not _land(water_at, w, h, c + Vector2i.LEFT, edge_bank) else INSET
			var x1 := T if not _land(water_at, w, h, c + Vector2i.RIGHT, edge_bank) else T - INSET
			var y0 := 0 if not _land(water_at, w, h, c + Vector2i.UP, edge_bank) else INSET
			var y1 := T if not _land(water_at, w, h, c + Vector2i.DOWN, edge_bank) else T - INSET
			img.fill_rect(Rect2i(c.x * T + x0, c.y * T + y0, x1 - x0, y1 - y0), Color.WHITE)
	centered = false
	position = Vector2.ZERO
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture = ImageTexture.create_from_image(img)
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("size_px", Vector2(w * T, h * T))
	material = m
	visible = water_cells > 0


## The mask's alpha at map pixel `p` (true = the surface is drawn there). For tests.
func surface_at(p: Vector2i) -> bool:
	var img := texture.get_image()
	if img == null or p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
		return false
	return img.get_pixelv(p).a > 0.5


static func _land(water_at: Callable, w: int, h: int, n: Vector2i, edge_bank: bool) -> bool:
	if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
		return edge_bank
	return not water_at.call(n)
