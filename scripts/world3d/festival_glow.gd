class_name FestivalGlow
extends Control
## Festival lights over the 3D view, added on top of the day / night tint (main_3d puts it in
## the tint's layer, after the tint) so they shine at night: a soft glow round every lantern
## and fire of the FestivalProps on show (in the flat view, of the FestivalView on show), stronger the darker it is, and fireworks in the
## festival's firework hours. Drawn in screen pixels with additive blending; the bursts are a
## pure function of time (`burst`), so they cost a few hundred small rects a frame.

const BURST_EVERY := 1.1      # seconds between launches
const RISE := 0.35            # seconds a shell climbs before it bursts
const FADE := 1.9             # seconds a burst glows
const SPARKS := 26
const COLORS: Array[Color] = [Color("ff6a4a"), Color("ffd060"), Color("7ad0ff"), Color("ff8ad8"), Color("a0ff8a"), Color("fff4d8")]

var time := 0.0               # seconds since fireworks started on screen
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
	t.width = 32
	t.height = 32
	_dot = t


## 0 by day .. 1 at night: how much the lights stand out (from Game.light_color).
static func darkness(light: Color) -> float:
	return clampf((1.0 - light.get_luminance()) / 0.45, 0.0, 1.0)


## Are fireworks going up over the map the farmer is on now?
static func fireworks_on() -> bool:
	var fest := Game.festival_today()
	return fest != "" and not Game.indoors() and Festivals.get_festival(fest).map == Game.maps.id \
		and Festivals.fireworks_now(fest, Game.hour * 60 + Game.minute)


func _process(delta: float) -> void:
	if fireworks_on():
		time += delta
	else:
		time = 0.0
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	var dark := darkness(Game.light_color())
	if dark > 0.05:
		for n in get_tree().get_nodes_in_group(FestivalProps.GROUP):
			if cam != null and n.is_inside_tree() and n.shown():
				_draw_glows(n, cam, dark)
		for n in get_tree().get_nodes_in_group(FestivalView.GROUP):
			if n.is_inside_tree() and n.shown():
				_draw_flat_glows(n, dark)
	if time > 0.0:
		var size := get_viewport_rect().size
		var k := int(time / BURST_EVERY)
		for i in range(maxi(k - 2, 0), k + 1):
			_draw_burst(burst(i, time - i * BURST_EVERY, size))


func _draw_glows(props: FestivalProps, cam: Camera3D, dark: float) -> void:
	for g in props.glows:
		if cam.is_position_behind(g.pos):
			continue
		var at := cam.unproject_position(g.pos)
		var px := at.distance_to(cam.unproject_position(g.pos + cam.global_transform.basis.x)) * float(g.size)
		var c: Color = g.color
		c.a = 0.55 * dark
		draw_texture_rect(_dot, Rect2(at - Vector2(px, px) / 2, Vector2(px, px)), false, c)


## The flat view: its glows are in the FestivalView's pixels, so the canvas transform
## (the camera) puts them on screen.
func _draw_flat_glows(props: FestivalView, dark: float) -> void:
	var xf := props.get_global_transform_with_canvas()
	for g in props.glows:
		var px: float = g.size * xf.get_scale().x
		var c: Color = g.color
		c.a = 0.55 * dark
		draw_texture_rect(_dot, Rect2(xf * g.pos - Vector2(px, px) / 2, Vector2(px, px)), false, c)


## Firework `i`, `t` seconds after its launch, on a screen of `size`: {rise: [from, to] or
## [], sparks: [[pos, colour]]}; empty lists when it is over. Seeded by its number, so the
## same shell always looks the same.
static func burst(i: int, t: float, size: Vector2) -> Dictionary:
	var out := {"rise": [], "sparks": []}
	if t < 0.0 or t > RISE + FADE:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * i + 17
	var center := Vector2(rng.randf_range(0.15, 0.85) * size.x, rng.randf_range(0.12, 0.38) * size.y)
	var color := COLORS[rng.randi() % COLORS.size()]
	var reach := rng.randf_range(0.09, 0.14) * size.y
	if t < RISE:
		var from := Vector2(center.x, size.y * 0.55)
		out.rise = [from.lerp(center, t / RISE * 0.85), from.lerp(center, t / RISE), color]
		return out
	var s := t - RISE
	var spread := reach * (1.0 - exp(-4.0 * s))
	var fade := sqrt(1.0 - s / FADE)   # bright for most of its life, then gone quickly
	for j in SPARKS:
		var a := TAU * j / SPARKS + rng.randf_range(-0.08, 0.08)
		var p := center + Vector2(cos(a), sin(a)) * spread * rng.randf_range(0.8, 1.0) + Vector2(0, 14.0 * s * s)
		var c := color.lerp(Color.WHITE, 0.3) if j % 3 == 0 else color
		c.a = fade
		out.sparks.append([p, c])
	return out


func _draw_burst(b: Dictionary) -> void:
	if not b.rise.is_empty():
		draw_line(b.rise[0], b.rise[1], b.rise[2], 1.0)
	for sp in b.sparks:
		draw_rect(Rect2(sp[0].floor(), Vector2(2, 2)), sp[1])
		var halo: Color = sp[1]
		halo.a *= 0.25
		draw_rect(Rect2(sp[0].floor() - Vector2(1, 1), Vector2(4, 4)), halo)
