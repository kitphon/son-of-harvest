class_name NightLights
extends Control
## Lit house windows and stone lanterns over the 3D view at dusk and night. main_3d puts it in
## the tint's layer, after the multiply tint, so the warm light is added on top of the night
## blue instead of being darkened by it. Three passes, in this order:
##  1. pools (this node): a soft warm pool on the ground in front of every lit window and round
##     every stone lantern, its edge cut into dithered steps like the mine lantern's;
##  2. wall washes (after a BackBufferCopy, so the copy holds the picture with the pools but no
##     glow yet): a soft warm disc on the wall round every lit window and door, added only where
##     the copy is pale (the plaster and the paper; see `wall_wash`), as the tint caps the real
##     lamps' light on near-white plaster;
##  3. glows: each window of the FarmWorld on show (`FarmWorld.windows`, the farmhouse and
##     the village houses) gets its own paper picture added in warm light over its pane and a
##     soft glow round it, each lantern (`FarmWorld.lamps`) a glow round its fire box;
##  4. figures (the last child): the overlay knows no depth, so a farmer, villager or animal
##     standing in front of a glow (on its lit side, not hidden behind a building) is drawn
##     back from the copy over its own pixels, and the glow behind it no longer tints it.
## How bright is Game.window_light() (data/light.json "windows": with the dark, in the lit
## hours); the pools follow it too (data/light.json "pools"). A window turned from the camera,
## or behind another building, stays dark; a building faded see-through lets the light through
## as much. A pool or lantern behind a solid building is not drawn.

const GROUP := "lit_windows"
const FIGURES := "night_figures"   # sprites that stand in front of the glows (farmer, villagers, animals)
const DOT_SIZE := 32

const POOL_SHADER := """
shader_type canvas_item;
render_mode blend_add;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	float k = 1.0 - smoothstep(0.1, 1.0, length(UV * 2.0 - 1.0));
	ivec2 q = ivec2(mod(floor(FRAGCOORD.xy), 4.0));
	k = clamp(floor(k * 6.0 + BAYER[q.y * 4 + q.x] / 16.0) / 6.0, 0.0, 1.0);
	COLOR = vec4(COLOR.rgb, COLOR.a * k);
}
"""

## The wall wash: a soft disc (UV -1..1 from the window's middle) in dithered steps, kept to the
## pale pixels of the copy: its blue over the tint's blue is about the surface's brightness
## before the tint, near 1 on white plaster, low on dark wood, roof tiles and the ground.
const WASH_SHADER := """
shader_type canvas_item;
render_mode blend_add;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec3 tint = vec3(1.0);
uniform vec2 pale = vec2(0.45, 0.72);

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	float k = 1.0 - smoothstep(0.0, 1.0, length(UV));
	ivec2 q = ivec2(mod(floor(FRAGCOORD.xy), 4.0));
	k = clamp(floor(k * 6.0 + BAYER[q.y * 4 + q.x] / 16.0) / 6.0, 0.0, 1.0);
	float b = textureLod(screen, SCREEN_UV, 0.0).b / max(tint.b, 0.05);
	COLOR = vec4(COLOR.rgb, COLOR.a * k * smoothstep(pale.x, pale.y, b));
}
"""

const FIGURE_SHADER := """
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;

void fragment() {
	if (texture(TEXTURE, UV).a < 0.5) {
		discard;
	}
	COLOR = vec4(textureLod(screen, SCREEN_UV, 0.0).rgb, 1.0);
}
"""

static var _dot: Texture2D

var washes: Control    # pass 2: warm light on the pale walls round lit windows
var glows: Control     # pass 3: panes, halos, lantern glows
var figures: Control   # pass 4: the figures in front, drawn back from the copy
var copy: BackBufferCopy
## This frame's work, worked out in _process and drawn by the three passes.
var _pools: Array[Dictionary] = []     # {pts: PackedVector2Array, color}
var _panes: Array[Dictionary] = []     # {win, k} windows to draw
var _washes: Array[Dictionary] = []    # {pts, uvs, color} wall washes
var _lamps: Array[Dictionary] = []     # {at: Vector2, px, color}
var _lit: Array[Dictionary] = []       # {rect: Rect2, pos, normal} everything glowing on screen
var _shields: Array[Dictionary] = []   # {pts, uvs, tex} figure quads drawn back


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = _shader_material(POOL_SHADER)
	copy = BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)
	washes = _layer("Washes")
	washes.material = _shader_material(WASH_SHADER)
	washes.draw.connect(_draw_washes)
	glows = _layer("Glows")
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glows.material = add
	glows.draw.connect(_draw_glows)
	figures = _layer("Figures")
	figures.material = _shader_material(FIGURE_SHADER)
	figures.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	figures.draw.connect(_draw_figures)
	if _dot == null:
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


func _layer(n: String) -> Control:
	var c := Control.new()
	c.name = n
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


static func _shader_material(code: String) -> ShaderMaterial:
	var s := Shader.new()
	s.code = code
	var m := ShaderMaterial.new()
	m.shader = s
	return m


## Marks a sprite (with its held item, note and the like as children) as a figure that may stand
## in front of a lit window: the window's glow is kept off it.
static func figure(s: Sprite3D) -> void:
	s.add_to_group(FIGURES)


func _process(_delta: float) -> void:
	_plan()
	queue_redraw()
	washes.queue_redraw()
	glows.queue_redraw()
	figures.queue_redraw()


## Works out this frame's pools, panes, lantern glows and the figures to draw back.
func _plan() -> void:
	_pools.clear()
	_panes.clear()
	_washes.clear()
	_lamps.clear()
	_lit.clear()
	_shields.clear()
	var glow := Game.window_light()
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var eye := cam.global_position
	var pool_rules: Dictionary = Game.light_data().get("pools", {})
	_plan_festival(cam, pool_rules)
	if glow <= 0.0:
		return
	var rules: Dictionary = Game.light_data().get("windows", {})
	var warm := Color(str(rules.get("color", "ffb25c")))
	var wall_rules: Dictionary = pool_rules.get("wall", {})
	var tint := Game.light_color()
	var wm := washes.material as ShaderMaterial
	wm.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	wm.set_shader_parameter("pale", Vector2(float(wall_rules.get("pale_from", 0.45)), float(wall_rules.get("pale_full", 0.72))))
	var back := cam.global_basis.z
	var flat_back := Vector3(back.x, 0, back.z).normalized()
	var worlds: Array[FarmWorld] = []
	for w in get_tree().get_nodes_in_group(GROUP):
		if w is FarmWorld and w.is_inside_tree() and w.visible:
			worlds.append(w)
	for w in worlds:
		for p in pools_of(w, glow, pool_rules):
			var k: float = p.strength * ground_seen(p.center, p.own, eye, w.occluders)
			var pts := _project(pool_corners(p), cam)
			if k > 0.0 and not pts.is_empty():
				var c := Color(str(pool_rules.get("color", "ff9a48")))
				c.a = k
				_pools.append({"pts": pts, "color": c})   # under the copy: figures in a pool keep its light
		for win in w.windows:
			var seen := how_seen(win, eye, w.occluders)
			var pts := _project(corners(win), cam)
			if seen > 0.0 and not pts.is_empty():
				_panes.append({"win": win, "k": glow * seen, "pts": pts})
				var r := _bounds(pts)
				_lit.append({"rect": r.grow(r.size.x * (float(rules.get("halo_size", 2.4)) - 1.0) / 2.0),
					"pos": win.pos, "normal": win.normal})
				var wash := wall_wash(win, glow * seen, wall_rules)
				var wc := Color(str(wall_rules.get("color", "ffa050")))
				wc.a = wash.strength
				for piece in (wash.pieces if wash.strength > 0.0 else []):
					var wpts := _project(piece.corners, cam)
					if not wpts.is_empty():
						_washes.append({"pts": wpts, "uvs": piece.uvs, "color": wc})
						_lit.append({"rect": _bounds(wpts), "pos": win.pos, "normal": win.normal})
		var lamp: Dictionary = pool_rules.get("lamp", {})
		for l in w.lamps:
			var seen := ground_seen(l.pos, l.pos, eye, w.occluders)
			if seen <= 0.0 or cam.is_position_behind(l.pos):
				continue
			var at := cam.unproject_position(l.pos)
			var px := at.distance_to(cam.unproject_position(l.pos + cam.global_basis.x)) * float(lamp.get("glow_size", 0.7))
			var c := warm
			c.a = float(lamp.get("glow", 0.45)) * glow * seen
			_lamps.append({"at": at, "px": px, "color": c})
			_lit.append({"rect": Rect2(at - Vector2(px, px) / 2, Vector2(px, px)), "pos": l.pos, "normal": flat_back})
	if _lit.is_empty():
		return
	for s in get_tree().get_nodes_in_group(FIGURES):
		if s is Sprite3D and s.is_visible_in_tree():
			_shield(s, cam, worlds)


## The pools of the festival lights on show (FestivalProps), as strong as they stand out
## (FestivalGlow.darkness); a building of the map they stand on hides them as it hides the rest.
func _plan_festival(cam: Camera3D, pool_rules: Dictionary) -> void:
	var dark := FestivalGlow.darkness(Game.light_color())
	if dark <= 0.05:
		return
	var c := Color(str(pool_rules.get("color", "ff9a48")))
	for n in get_tree().get_nodes_in_group(FestivalProps.GROUP):
		if not (n.is_inside_tree() and n.is_visible_in_tree() and n.shown()):
			continue
		var occ: Occluders = n.get_parent().occluders if n.get_parent() is FarmWorld else n.occluders
		for p in festival_pools(n.glows, dark, pool_rules):
			var k: float = p.strength * ground_seen(p.center, p.own, cam.global_position, occ)
			var pts := _project(pool_corners(p), cam)
			if k > 0.0 and not pts.is_empty():
				var pc := c
				pc.a = k
				_pools.append({"pts": pts, "color": pc})


## The ground pools of a festival's lights (FestivalProps.glows) when they stand out `dark`
## (0..1), by data/light.json "pools" → "festival", in the shape of `pools_from`: a round pool
## under a standing light (`radius` times its glow's size), a fainter one (`line`) under a string
## lantern, and in front of a stall's counter for its lantern. Both views use it.
static func festival_pools(lights: Array, dark: float, rules: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if dark <= 0.0:
		return out
	var fr: Dictionary = rules.get("festival", {})
	var strength := float(fr.get("strength", 0.36)) * dark
	for g in lights:
		var at: Vector3 = g.pos
		var kind := str(g.get("pool", "round"))
		if kind == "stall":
			var mid: Vector3 = g.mid
			var reach := float(fr.get("stall_reach", 0.7))
			out.append({"center": Vector3(mid.x, 0.02, mid.z + float(fr.get("stall_front", 0.85))),
				"across": Vector3(float(g.wide) / 2.0 + 0.2, 0, 0), "out": Vector3(0, 0, reach),
				"strength": strength, "own": at, "normal": Vector3.ZERO})
			continue
		var r := float(g.size) * float(fr.get("radius", 0.7))
		var k := strength * (float(fr.get("line", 0.45)) if kind == "line" else 1.0)
		out.append({"center": Vector3(at.x, 0.02, at.z), "across": Vector3(r, 0, 0), "out": Vector3(0, 0, r),
			"strength": k, "own": at, "normal": Vector3.ZERO})
	return out


## Draws figure `s` (and its sprite children) back over the glows if it stands in front of one.
func _shield(s: Sprite3D, cam: Camera3D, worlds: Array[FarmWorld]) -> void:
	var quads: Array[Dictionary] = []
	var all: Array = [s]
	all.append_array(s.find_children("*", "Sprite3D", true, false))
	var box := Rect2()
	for part: Sprite3D in all:
		if not part.is_visible_in_tree() or part.texture == null:
			continue
		var pts := _project(sprite_corners(part, cam.global_basis), cam)
		if pts.is_empty():
			continue
		var u0 := 1.0 if part.flip_h else 0.0
		quads.append({"pts": pts, "tex": part.texture,
			"uvs": PackedVector2Array([Vector2(u0, 0), Vector2(1 - u0, 0), Vector2(1 - u0, 1), Vector2(u0, 1)])})
		box = _bounds(pts) if quads.size() == 1 else box.merge(_bounds(pts))
	if quads.is_empty():
		return
	var mid := s.global_position + cam.global_basis.y * (s.texture.get_height() * s.pixel_size / 2.0)
	for w in worlds:
		if hidden(mid, cam.global_position, w.occluders):
			return
	if shielded(box, s.global_position, _lit):
		_shields.append_array(quads)


func _draw() -> void:
	for p in _pools:
		draw_colored_polygon(p.pts, p.color, PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]))


func _draw_washes() -> void:
	for w in _washes:
		washes.draw_colored_polygon(w.pts, w.color, w.uvs)


func _draw_glows() -> void:
	var rules: Dictionary = Game.light_data().get("windows", {})
	for p in _panes:
		_draw_window(p.win, p.pts, p.k, rules)
	for l in _lamps:
		glows.draw_texture_rect(_dot, Rect2(l.at - Vector2(l.px, l.px) / 2, Vector2(l.px, l.px)), false, l.color)


func _draw_figures() -> void:
	for q in _shields:
		figures.draw_colored_polygon(q.pts, Color.WHITE, q.uvs, q.tex)


## How much of window `win` the eye at `eye` sees, 0..1: 0 when its wall is turned away or a
## solid building stands between; a building faded see-through lets through its fade. The
## window's own building (whose box holds the window) never hides it.
static func how_seen(win: Dictionary, eye: Vector3, occ: Occluders) -> float:
	var at: Vector3 = win.pos + win.normal * 0.05
	if win.normal.dot(eye - at) <= 0.0:
		return 0.0
	return _through(at, at, eye, occ)


## How much of the ground (or lantern) at `at` the eye sees past the buildings, 0..1; the thing
## whose box holds `own` (the pool's window or lantern) never hides it.
static func ground_seen(at: Vector3, own: Vector3, eye: Vector3, occ: Occluders) -> float:
	return _through(at + Vector3(0, 0.05, 0), own, eye, occ)


static func _through(at: Vector3, own: Vector3, eye: Vector3, occ: Occluders) -> float:
	var seen := 1.0
	for i in occ.count():
		var box := occ.box_of(i)
		if not box.has_point(own) and not box.has_point(at) and box.intersects_segment(at, eye) != null:
			seen *= occ.fade_of(i)
	return seen


## Is the point `at` (a figure's middle) behind a solid building from the eye? Then there is
## nothing of it on screen to keep the glow off.
static func hidden(at: Vector3, eye: Vector3, occ: Occluders) -> bool:
	for i in occ.count():
		var box := occ.box_of(i)
		if occ.fade_of(i) < 0.3 and not box.has_point(at) and box.intersects_segment(at, eye) != null:
			return true
	return false


## Does a figure standing at `foot`, covering `rect` on screen, stand in front of one of the
## glows in `lit` ({rect, pos, normal}): overlapping it on screen, on its lit side (out past
## the window's wall, or nearer the eye than the lantern)? Then the glow is kept off it.
static func shielded(rect: Rect2, foot: Vector3, lit: Array) -> bool:
	for l in lit:
		if rect.intersects(l.rect) and (foot - Vector3(l.pos.x, 0, l.pos.z)).dot(l.normal) > 0.0:
			return true
	return false


## The window's four corners in the world, in the order of its picture's UVs (top left first).
static func corners(win: Dictionary) -> Array[Vector3]:
	var right: Vector3 = Vector3.UP.cross(win.normal).normalized()
	var half: Vector2 = win.size / 2.0
	var c: Vector3 = win.pos
	return [c - right * half.x + Vector3.UP * half.y, c + right * half.x + Vector3.UP * half.y,
		c + right * half.x - Vector3.UP * half.y, c - right * half.x - Vector3.UP * half.y]


## The ground pools of `world`'s lit windows and lanterns when the windows glow `glow` (0..1),
## by data/light.json "pools": {center, across, out (half axes on the ground), strength, own (the
## point inside the thing that casts it), normal (a window's lit side; zero round a lantern)}. A window's pool lies against
## its wall, as wide as `wide` windows (at least min_wide), reaching 2 * out from the wall, a
## bigger pane (a door) a little brighter; a lantern's is a circle round its foot.
static func pools_of(world: FarmWorld, glow: float, rules: Dictionary) -> Array[Dictionary]:
	return pools_from(world.windows, world.lamps, glow, rules)


## The same for any lists of windows and lamps (LitSpots): the flat view's NightView uses it too.
static func pools_from(windows: Array, lamps: Array, glow: float, rules: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if glow <= 0.0:
		return out
	var wr: Dictionary = rules.get("window", {})
	var lr: Dictionary = rules.get("lamp", {})
	for win in windows:
		var n: Vector3 = win.normal
		var right := Vector3.UP.cross(n).normalized()
		var half := maxf(win.size.x * float(wr.get("wide", 2.0)) / 2.0, float(wr.get("min_wide", 1.2)) / 2.0)
		var reach := float(wr.get("out", 0.8))
		var area: float = win.size.x * win.size.y
		var k := float(wr.get("strength", 0.3)) * clampf(sqrt(area / 0.35), 0.8, 1.5) * glow
		out.append({"center": Vector3(win.pos.x, 0.02, win.pos.z) + n * reach, "across": right * half,
			"out": n * reach, "strength": k, "own": win.pos + n * 0.05, "normal": n})
	for l in lamps:
		var r := float(lr.get("radius", 1.2))
		out.append({"center": Vector3(l.pos.x, 0.02, l.pos.z), "across": Vector3(r, 0, 0),
			"out": Vector3(0, 0, r), "strength": float(lr.get("strength", 0.4)) * glow, "own": l.pos,
			"normal": Vector3.ZERO})
	return out


## The warm wash on the wall round lit window `win` when it glows `glow` (0..1), by data/light.json
## "pools" → "wall": {pieces: [{corners (on the window's wall plane, top left first), uvs (-1..1
## from the window's middle, `reach` cells to the edge)}], strength}. The wash runs `reach`
## either side of the window, from the ground up to `up` over the window, in up to four pieces
## round the pane itself (left, right, above, below), so the paper keeps the pane's own warm
## colour; a bigger pane (a door) is a little brighter, as its pool is.
static func wall_wash(win: Dictionary, glow: float, rules: Dictionary) -> Dictionary:
	var reach := maxf(float(rules.get("reach", 1.5)), 0.01)
	var right: Vector3 = Vector3.UP.cross(win.normal).normalized()
	var c: Vector3 = win.pos
	var half: Vector2 = win.size / 2.0
	var top: float = c.y + half.y + float(rules.get("up", 0.6))
	var foot := minf(0.0, c.y - half.y)
	var area: float = win.size.x * win.size.y
	var k := float(rules.get("strength", 0.3)) * clampf(sqrt(area / 0.35), 0.8, 1.5) * glow
	var pieces: Array[Dictionary] = []
	# [x0, x1, y0, y1] in cells along the wall from the window's middle and heights.
	for r in [[-reach, -half.x, foot, top], [half.x, reach, foot, top],
			[-half.x, half.x, c.y + half.y, top], [-half.x, half.x, foot, c.y - half.y]]:
		if r[1] - r[0] < 0.001 or r[3] - r[2] < 0.001:
			continue
		var corners: Array[Vector3] = []
		var uvs := PackedVector2Array()
		for p in [Vector2(r[0], r[3]), Vector2(r[1], r[3]), Vector2(r[1], r[2]), Vector2(r[0], r[2])]:
			corners.append(Vector3(c.x, p.y, c.z) + right * p.x)
			uvs.append(Vector2(p.x, c.y - p.y) / reach)
		pieces.append({"corners": corners, "uvs": uvs})
	return {"pieces": pieces, "strength": maxf(k, 0.0)}


## A pool's four ground corners in the order of its UVs (the quad its round falloff fills).
static func pool_corners(p: Dictionary) -> Array[Vector3]:
	var c: Vector3 = p.center
	return [c - p.across + p.out, c + p.across + p.out, c + p.across - p.out, c - p.across - p.out]


## A billboard sprite's four corners in the world for a camera turned `basis`, in the order of
## its picture's UVs (top left first): its item rect (pixels, y up) along the camera's right / up.
static func sprite_corners(s: SpriteBase3D, basis: Basis) -> Array[Vector3]:
	var r := s.get_item_rect()
	var px := s.pixel_size
	var right := basis.x.normalized() * px
	var up := basis.y.normalized() * px
	var o := s.global_position
	return [o + right * r.position.x + up * r.end.y, o + right * r.end.x + up * r.end.y,
		o + right * r.end.x + up * r.position.y, o + right * r.position.x + up * r.position.y]


static func _project(pts: Array[Vector3], cam: Camera3D) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		if cam.is_position_behind(p):
			return PackedVector2Array()
		out.append(cam.unproject_position(p))
	return out


static func _bounds(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


func _draw_window(win: Dictionary, pts: PackedVector2Array, k: float, rules: Dictionary) -> void:
	var warm := Color(str(rules.get("color", "ffb25c")))
	var halo := warm
	halo.a = float(rules.get("halo", 0.35)) * k
	var at := (pts[0] + pts[2]) / 2.0
	var px := pts[0].distance_to(pts[1]) * float(rules.get("halo_size", 2.4))
	glows.draw_texture_rect(_dot, Rect2(at - Vector2(px, px * 0.8) / 2, Vector2(px, px * 0.8)), false, halo)
	var pane := warm
	pane.a = float(rules.get("pane", 0.85)) * k
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	glows.draw_colored_polygon(pts, pane, uvs, PlaceholderArt.tex(win.key))
