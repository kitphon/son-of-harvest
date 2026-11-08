class_name NightLights
extends Control
## Lit house windows and stone lanterns over the 3D view at dusk and night. main_3d puts it in
## the tint's layer, after the multiply tint, so the warm light is added on top of the night
## blue instead of being darkened by it. The passes, in this order:
##  0. the night lift ("Field" and "FigureLift", after their own BackBufferCopy "FieldCopy" of the
##     tinted picture, only while something is lit): the crops, cluster plants, items and objects
##     (SpriteLight.field_lifts, worked out once a game minute) and the figures (the farmer,
##     villagers, animals, the dog, with what they hold; `figure_lifts`, each frame; the same
##     shader, letting the 3D view's glow by a lit window lie on them: "bloom") near a lit
##     window, door, stone lantern or festival light take warm light added in proportion to their own colour, as
##     strong as SpriteLight.lift_at says (data/light.json "sprites" -> "lift"), so a villager by a
##     lit window reads warm while one in the dark stays night blue. The overlay knows no depth, so
##     each pixel takes it only where the copy shows that picture's own pixel there as the 3D view
##     draws it under the tint (`field_off`): a plant, fence, building corner, figure or anything
##     else standing in front keeps its own pixels, and a figure partly behind a fence is lifted
##     only where it shows. A cluster plant's quad follows its sway and parting
##     (CropClusters.tip_shift).
##  1. pools ("Pools"): a soft warm pool on the ground in front of every lit window and round
##     every stone lantern, its edge cut into dithered steps like the mine lantern's;
##  2. wall washes (after a BackBufferCopy, so the copy holds the picture with the pools but no
##     glow yet): a soft warm disc on the wall round every lit window and door, added only where
##     the copy is pale (the plaster and the paper; see `wall_wash`), as the tint caps the real
##     lamps' light on near-white plaster; and on the earthen and charred board walls of the
##     village houses (their red already at the tint's cap) a warm glow or a faint sheen of their
##     own, kept to the material between the posts and rails (see `finish_wash`);
##  3. glows: each window of the FarmWorld on show (`FarmWorld.windows`, the farmhouse and
##     the village houses) gets its own paper picture added in warm light over its pane and a
##     soft glow round it, each lantern (`FarmWorld.lamps`) a glow round its fire box;
##  4. figures (the last child): the overlay knows no depth, so a farmer, villager or animal
##     standing in front of a glow (on its lit side, not hidden behind a building), or taking the
##     night lift, is drawn back from the copy (which holds its lift) over its own pixels, and the
##     glow behind it no longer tints it.
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

## The earthen and board walls' wash (`finish_wash`): like the pale wash, but kept to the warm
## pixels of the copy (its red over the tint's red above both green and blue, `warm` from / full:
## earth and wood, not the blue roof tiles, the grass or the sky) that are not pale (the plaster
## has its own wash), the posts and rails already cut out of the pieces.
const FINISH_SHADER := """
shader_type canvas_item;
render_mode blend_add;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec3 tint = vec3(1.0);
uniform vec2 pale = vec2(0.45, 0.72);
uniform vec2 warm = vec2(0.03, 0.1);

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	float k = 1.0 - smoothstep(0.0, 1.0, length(UV));
	ivec2 q = ivec2(mod(floor(FRAGCOORD.xy), 4.0));
	k = clamp(floor(k * 6.0 + BAYER[q.y * 4 + q.x] / 16.0) / 6.0, 0.0, 1.0);
	vec3 c = textureLod(screen, SCREEN_UV, 0.0).rgb / max(tint, vec3(0.05));
	float w = smoothstep(warm.x, warm.y, c.r - max(c.g, c.b)) * (1.0 - smoothstep(pale.x, pale.y, c.b));
	COLOR = vec4(COLOR.rgb, COLOR.a * k * w);
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

## Pass 0, the night lift, added: a figure's or a field picture's own colour (its texel) times the warm light
## times its shade (the vertex colour's red; 1 for a sprite) times the lift (its alpha), only on
## the pixels inside the picture's outline where the copy (FieldCopy: the tinted 3D picture,
## before the pools) shows that texel as the 3D view draws it (`off`, the same math as
## NightLights.field_off): what stands in front of it keeps its own pixels. The texel half a
## texel either way is tried too, so a pixel on a texel's edge matches whichever side the 3D view
## drew. `bloom` lets the copy be that much brighter than the texel on top of `match` (the 3D
## view's glow round a lit window lies on a figure standing by it; 0 for the field, as before).
const FIELD_SHADER := """
shader_type canvas_item;
render_mode blend_add;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec3 tint = vec3(1.0);
uniform vec3 sun = vec3(1.0);
uniform vec3 warm = vec3(1.0);
uniform float match = 0.024;
uniform float bloom = 0.0;
varying vec4 lift;

vec3 to_lin(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 to_srgb(vec3 c) {
	return mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

float off(vec3 seen, vec3 own, float shade) {
	vec3 da = seen - to_srgb(to_lin(own) * shade * sun) * tint;
	vec3 db = seen - own * shade * sun * tint;
	vec3 a = max(-da, da - bloom);
	vec3 b = max(-db, db - bloom);
	return min(max(a.r, max(a.g, a.b)), max(b.r, max(b.g, b.b)));
}

void vertex() {
	lift = COLOR;
}

void fragment() {
	if (texture(TEXTURE, UV).a < 0.5) {
		discard;   // outside the picture's outline, as the figures' pass
	}
	vec3 seen = textureLod(screen, SCREEN_UV, 0.0).rgb;
	vec2 h = 0.5 / vec2(textureSize(TEXTURE, 0));
	vec2 tries[5] = vec2[5](vec2(0.0), vec2(h.x, 0.0), vec2(-h.x, 0.0), vec2(0.0, h.y), vec2(0.0, -h.y));
	vec4 hit = vec4(0.0);
	for (int i = 0; i < 5; i++) {
		vec4 own = texture(TEXTURE, UV + tries[i]);
		if (own.a >= 0.5 && off(seen, own.rgb, lift.r) < match) {
			hit = own;
			break;
		}
	}
	if (hit.a < 0.5) {
		discard;
	}
	COLOR = vec4(hit.rgb * warm * lift.r, lift.a);
}
"""

static var _dot: Texture2D

var field_copy: BackBufferCopy   # pass 0's copy of the tinted picture (shown only while the field is lit)
var field: Control     # pass 0: the field's lift, kept to its own pixels
var figure_lift: Control   # pass 0 too: the figures' lift, kept to their own pixels (same copy)
var pools: Control     # pass 1: the ground pools
var washes: Control    # pass 2: warm light on the pale walls round lit windows
var finishes: Control  # pass 2 too: on the earthen and charred board walls
var glows: Control     # pass 3: panes, halos, lantern glows
var figures: Control   # pass 4: the figures in front or lifted, drawn back from the copy
var copy: BackBufferCopy
## This frame's work, worked out in _process and drawn by the three passes.
var _pools: Array[Dictionary] = []     # {pts: PackedVector2Array, color}
var _panes: Array[Dictionary] = []     # {win, k} windows to draw
var _washes: Array[Dictionary] = []    # {pts, uvs, color} wall washes
var _finishes: Array[Dictionary] = []  # {pts, uvs, color} earthen and board wall washes
var _lamps: Array[Dictionary] = []     # {at: Vector2, px, color}
var _lit: Array[Dictionary] = []       # {rect: Rect2, pos, normal} everything glowing on screen
var _shields: Array[Dictionary] = []   # {pts, uvs, tex} figure quads drawn back
var _warm: Array[Dictionary] = []      # {pts, uvs, tex, color (1, 1, 1, lift)} the figures' lift (FigureLift)
var _shielded := {}                     # the figures already in _shields this frame
var _field_quads: Array[Dictionary] = []   # {pts, uvs, tex, color (shade, shade, shade, lift)} pass 0
## The field's lifts (SpriteLight.field_lifts), worked out once a game minute or when the field
## changes (`_field_key`: how many lit sprites there are and which plantings), projected each frame.
var _field: Array[Dictionary] = []
var _field_dirty := true
var _field_key := []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	field_copy = BackBufferCopy.new()
	field_copy.name = "FieldCopy"
	field_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	field_copy.visible = false
	add_child(field_copy)
	field = _layer("Field")
	field.material = _shader_material(FIELD_SHADER)
	field.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	field.visible = false
	field.draw.connect(_draw_field)
	figure_lift = _layer("FigureLift")   # reads the same FieldCopy: no copy between
	figure_lift.material = _shader_material(FIELD_SHADER)
	figure_lift.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	figure_lift.visible = false
	figure_lift.draw.connect(_draw_figure_lift)
	pools = _layer("Pools")
	pools.material = _shader_material(POOL_SHADER)
	pools.draw.connect(_draw_pools)
	copy = BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)
	washes = _layer("Washes")
	washes.material = _shader_material(WASH_SHADER)
	washes.draw.connect(_draw_washes)
	finishes = _layer("Finishes")
	finishes.material = _shader_material(FINISH_SHADER)
	finishes.draw.connect(_draw_finishes)
	glows = _layer("Glows")
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glows.material = add
	glows.draw.connect(_draw_glows)
	figures = _layer("Figures")
	figures.material = _shader_material(FIGURE_SHADER)
	figures.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	figures.draw.connect(_draw_figures)
	Game.minute_passed.connect(_on_minute)
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
	_plan_warmth()
	# The lift's copy costs a full-screen copy a frame: only while a figure or the field is lit.
	field_copy.visible = not (_field_quads.is_empty() and _warm.is_empty())
	field.visible = not _field_quads.is_empty()
	figure_lift.visible = not _warm.is_empty()
	field.queue_redraw()
	figure_lift.queue_redraw()
	pools.queue_redraw()
	washes.queue_redraw()
	finishes.queue_redraw()
	glows.queue_redraw()
	figures.queue_redraw()


## Works out this frame's pools, panes, lantern glows and the figures to draw back.
func _plan() -> void:
	_pools.clear()
	_panes.clear()
	_washes.clear()
	_finishes.clear()
	_lamps.clear()
	_lit.clear()
	_shields.clear()
	_shielded.clear()
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
	var fm := finishes.material as ShaderMaterial
	fm.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	fm.set_shader_parameter("pale", Vector2(float(wall_rules.get("pale_from", 0.45)), float(wall_rules.get("pale_full", 0.72))))
	fm.set_shader_parameter("warm", Vector2(float(wall_rules.get("warm_from", 0.03)), float(wall_rules.get("warm_full", 0.1))))
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
				var own := finish_wash(win, glow * seen, wall_rules)
				for piece in (own.pieces if own.strength > 0.0 else []):
					var fpts := _project(piece.corners, cam)
					if not fpts.is_empty():
						var fc: Color = own.color
						fc.a = own.strength
						_finishes.append({"pts": fpts, "uvs": piece.uvs, "color": fc})
						_lit.append({"rect": _bounds(fpts), "pos": win.pos, "normal": win.normal})
		# The stone lanterns' wash on the walls they stand in front of (lamp_washes).
		for lw in lamp_washes(w.windows, w.lamps, glow, wall_rules, w.occluders):
			var at: Vector3 = lw.at + lw.normal * 0.05
			var k: float = lw.strength * (_through(at, lw.own, eye, w.occluders) if lw.normal.dot(eye - at) > 0.0 else 0.0)
			if k <= 0.0:
				continue
			var lc: Color = lw.color
			lc.a = k
			for piece in lw.pieces:
				var lpts := _project(piece.corners, cam)
				if not lpts.is_empty():
					(_washes if lw.finish == "" else _finishes).append({"pts": lpts, "uvs": piece.uvs, "color": lc})
					_lit.append({"rect": _bounds(lpts), "pos": lw.at, "normal": lw.normal})
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
	var quads := _quads(s, cam)
	if quads.is_empty():
		return
	var box := _bounds(quads[0].pts)
	for q in quads:
		box = box.merge(_bounds(q.pts))
	var mid := s.global_position + cam.global_basis.y * (s.texture.get_height() * s.pixel_size / 2.0)
	for w in worlds:
		if hidden(mid, cam.global_position, w.occluders):
			return
	if shielded(box, s.global_position, _lit):
		_shields.append_array(quads)
		_shielded[s] = true


## Figure `s` and its visible sprite children as screen quads: {pts, tex, uvs}.
## With `lit_only` the marks over it (SpriteLight.unlit: a note puff, the lantern) are left out.
static func _quads(s: Sprite3D, cam: Camera3D, lit_only := false) -> Array[Dictionary]:
	var quads: Array[Dictionary] = []
	var all: Array = [s]
	all.append_array(s.find_children("*", "Sprite3D", true, false))
	for part: Sprite3D in all:
		if not part.is_visible_in_tree() or part.texture == null:
			continue
		if lit_only and part != s and not part.is_in_group(SpriteLight.GROUP):
			continue
		var pts := _project(sprite_corners(part, cam.global_basis), cam)
		if pts.is_empty():
			continue
		var u0 := 1.0 if part.flip_h else 0.0
		quads.append({"pts": pts, "tex": part.texture,
			"uvs": PackedVector2Array([Vector2(u0, 0), Vector2(1 - u0, 0), Vector2(1 - u0, 1), Vector2(u0, 1)])})
	return quads


## Pass 0's work: every figure near a light that burns now (SpriteLight.spots_of: the lit
## windows and lanterns of the worlds on show, the festival lights), with its lift
## (`figure_lifts`, each frame: figures move), and the field's crops, plants, items and objects by
## the same rule (SpriteLight.field_lifts, kept for a game minute), each plant's quad where its
## sway and parting put it now. A lifted figure not behind a building is drawn back in pass 4 too,
## so the glows added after the copy stay off it as they did.
func _plan_warmth() -> void:
	_warm.clear()
	_field_quads.clear()
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var glow := Game.window_light()
	var dark := FestivalGlow.darkness(Game.light_color())
	if glow <= 0.0 and dark <= 0.05:
		_field.clear()
		_field_dirty = true
		return
	var worlds: Array[FarmWorld] = []
	for w in get_tree().get_nodes_in_group(GROUP):
		if w is FarmWorld and w.is_inside_tree() and w.is_visible_in_tree():
			worlds.append(w)
	var fests: Array = []
	for n in get_tree().get_nodes_in_group(FestivalProps.GROUP):
		if n.is_inside_tree() and n.is_visible_in_tree() and n.shown():
			fests.append(n)
	var rules := SpriteLight.rules_of(Game.light_data())
	var spots := SpriteLight.spots_of(worlds, fests, glow, dark, rules)
	if spots.is_empty():
		_field.clear()
		return
	var lr: Dictionary = rules.get("lift", {})
	var warm := Color(str(lr.get("color", "ffa050")))
	var occ: Occluders = worlds[0].occluders if worlds.size() == 1 else null
	var eye := cam.global_position
	var behind := func(at: Vector3) -> bool:
		for w in worlds:
			if hidden(at, eye, w.occluders):
				return true
		return false
	var tint := Game.light_color()
	for layer: Control in [field, figure_lift]:
		var fm := layer.material as ShaderMaterial
		fm.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
		fm.set_shader_parameter("sun", Vector3(SpriteLight.now.r, SpriteLight.now.g, SpriteLight.now.b))
		fm.set_shader_parameter("warm", Vector3(warm.r, warm.g, warm.b))
		fm.set_shader_parameter("match", float(lr.get("match", 0.024)))
	(figure_lift.material as ShaderMaterial).set_shader_parameter("bloom", float(lr.get("bloom", 0.0)))
	# The field (its lifts kept for a game minute), in its own pass before the pools.
	if _field_dirty or _field_changed():
		_field_dirty = false
		var lit: Array = []
		_field_key = [get_tree().get_node_count_in_group(SpriteLight.GROUP)]
		for n in get_tree().get_nodes_in_group(SpriteLight.GROUP):
			if n is CropClusters:
				_field_key.append(n)
				_field_key.append(n.planted)
			elif n is Sprite3D:
				lit.append(n)
		_field = SpriteLight.field_lifts(lit, _field_key.filter(func(x): return x is CropClusters), spots, rules, occ)
	var shown: Array[Dictionary] = []
	for e in _field:
		if e.has("sprite") and not is_instance_valid(e.sprite):
			_field_dirty = true   # replaced (a new picture): worked out again next frame
		elif not behind.call(e.mid):
			shown.append(e)
	_field_quads = field_quads(shown, cam)
	var figs: Array = []
	for s in get_tree().get_nodes_in_group(FIGURES):
		if s is Sprite3D and s.is_visible_in_tree() and s.texture != null:
			figs.append(s)
	var lifted := figure_lifts(figs, spots, rules, occ)
	_warm = field_quads(lifted, cam)
	for e in lifted:
		if not _shielded.has(e.sprite) and not behind.call(e.mid):
			_shields.append_array(_quads(e.sprite, cam))
			_shielded[e.sprite] = true


## The figures' share of the night lift (`lift_at` at the middle of the figure's picture, its
## item rect, so its frame, flip and pixel size count): every figure of `figs` (shown Sprite3Ds in
## FIGURES) that takes some (over 0.01), as SpriteLight.field_lifts' sprite entries {sprite, at,
## mid, k}, so `field_quads` makes their quads (the figure and the lit sprites it holds; the
## marks over it left out) and FIELD_SHADER keeps the lift to the figure's own pixels. A figure
## behind a building is not skipped: the building's pixels are not the figure's, so it takes the
## lift only where it shows.
static func figure_lifts(figs: Array, spots: Array, rules: Dictionary, occ: Occluders = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if spots.is_empty():
		return out
	for s in figs:
		if not (s is Sprite3D) or s.texture == null or not s.is_visible_in_tree():
			continue
		var mid := SpriteLight.middle(s)
		var k := SpriteLight.lift_at(mid, spots, rules, occ)
		if k > 0.01:
			out.append({"sprite": s, "at": s.global_position, "mid": mid, "k": k})
	return out


func _on_minute() -> void:
	_field_dirty = true   # the windows' glow and the festival's darkness move with the clock


## Whether the field changed since its lifts were worked out (`_field_key`: how many lit sprites
## there were, then each CropClusters and its planting, a new array when it is replanted):
## checked each frame without walking the group.
func _field_changed() -> bool:
	if _field_key.is_empty() or int(_field_key[0]) != get_tree().get_node_count_in_group(SpriteLight.GROUP):
		return true
	for i in range(1, _field_key.size(), 2):
		var cc = _field_key[i]
		if not is_instance_valid(cc) or not is_same(cc.planted, _field_key[i + 1]):
			return true
	return false


## Pass 0's quads for the field's lifts `field` (SpriteLight.field_lifts entries) seen by `cam`:
## {pts, uvs, tex, color}, the colour (shade, shade, shade, lift): a plant's own shade (1 for a
## sprite) and its lift, which FIELD_SHADER turns into warm light. A sprite gone, hidden or moved
## since its lift was worked out is left out until the next minute; a plant's quad stands where
## its sway and parting put it now (field_corners).
static func field_quads(field: Array, cam: Camera3D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in field:
		var quads: Array[Dictionary] = []
		var shade := 1.0
		if e.has("sprite"):
			var s = e.sprite
			if not is_instance_valid(s) or not s.is_visible_in_tree() or s.global_position.distance_to(e.at) > 0.05:
				continue
			quads = _quads(s, cam, true)
		else:
			if not is_instance_valid(e.crops) or not e.crops.is_visible_in_tree():
				continue
			var pts := _project(field_corners(e, cam.global_basis), cam)
			if pts.is_empty():
				continue
			var u0 := 1.0 if e.plant.flip else 0.0
			quads = [{"pts": pts, "tex": e.tex,
				"uvs": PackedVector2Array([Vector2(u0, 0), Vector2(1 - u0, 0), Vector2(1 - u0, 1), Vector2(u0, 1)])}]
			shade = float(e.plant.shade)
		for q in quads:
			q.color = Color(shade, shade, shade, e.k)
			out.append(q)
	return out


## A CropClusters plant's quad standing on `root` (its picture `tex` at `size`, FarmWorld.PX a
## pixel, faced like a billboard for a camera turned `basis`), in the order of its UVs.
static func plant_corners(root: Vector3, tex: Texture2D, size: float, basis: Basis) -> Array[Vector3]:
	var right := basis.x.normalized() * (tex.get_width() * FarmWorld.PX * size / 2.0)
	var up := basis.y.normalized() * (tex.get_height() * FarmWorld.PX * size)
	return [root - right + up, root + right + up, root + right, root - right]


## A lit plant's quad (a SpriteLight.field_lifts entry: {crops, plant, tex, root}) where its
## CropClusters draws it now: plant_corners with the two top corners moved by the plant's sway and
## parting at the cluster's clock, wind and pushers (CropClusters.tip_shift), so the lift stays on
## the plant as it moves.
static func field_corners(e: Dictionary, basis: Basis) -> Array[Vector3]:
	var size := float(e.plant.size)
	var pts := plant_corners(e.root, e.tex, size, basis)
	var cc = e.crops
	var stiff := float(CropClusters.layout(str(e.plant.key)).get("stiff", 1.0))
	var shift := CropClusters.tip_shift(e.root, size, stiff, cc.clock, cc.wind, cc.pushers, cc.part, basis.x)
	pts[0] += shift
	pts[1] += shift
	return pts


## The GDScript twin of FIELD_SHADER's `off`: how far the copy's pixel `seen` is from texel `own`
## of a field picture as the 3D view draws it under the tint (`tint`), shaded `shade` (a plant's;
## 1 for a sprite) in the sun's share `sun`: the plants' shader multiplies in linear light, a
## sprite's modulate on its colour, so the nearer of the two. Under data/light.json "sprites" →
## "lift" → "match" the pixel is that picture's and takes the lift; past it something else stands
## in front there. `bloom` (the figures' "bloom"; 0 for the field) lets `seen` be that much
## brighter than the texel on top: the 3D view's glow round a lit window lies on what stands by it.
static func field_off(seen: Color, own: Color, shade: float, sun: Color, tint: Color, bloom := 0.0) -> float:
	var off := INF
	for lin in [true, false]:
		var d := 0.0
		for i in 3:
			var o: float = own[i]
			var drawn: float = (_to_srgb(_to_lin(o) * shade * sun[i]) if lin else o * shade * sun[i]) * tint[i]
			var diff: float = seen[i] - drawn
			d = maxf(d, maxf(-diff, diff - bloom))
		off = minf(off, d)
	return off


static func _to_lin(c: float) -> float:
	return c / 12.92 if c < 0.04045 else pow((c + 0.055) / 1.055, 2.4)


static func _to_srgb(c: float) -> float:
	return c * 12.92 if c < 0.0031308 else 1.055 * pow(maxf(c, 0.0), 1.0 / 2.4) - 0.055


func _draw_field() -> void:
	for q in _field_quads:
		field.draw_colored_polygon(q.pts, q.color, q.uvs, q.tex)


func _draw_figure_lift() -> void:
	for q in _warm:
		figure_lift.draw_colored_polygon(q.pts, q.color, q.uvs, q.tex)


func _draw_pools() -> void:
	for p in _pools:
		pools.draw_colored_polygon(p.pts, p.color, PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]))


func _draw_washes() -> void:
	for w in _washes:
		washes.draw_colored_polygon(w.pts, w.color, w.uvs)


func _draw_finishes() -> void:
	for w in _finishes:
		finishes.draw_colored_polygon(w.pts, w.color, w.uvs)


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


## How much of the light at `own` (a window's pane, a lantern's fire box) reaches `at` past the
## buildings, 0..1 (SpriteLight.lift_at): a solid one between drops it, a faded one lets its fade.
static func light_reaches(at: Vector3, own: Vector3, occ: Occluders) -> float:
	return _through(at, own, own, occ)


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
	var pieces: Array[Dictionary] = []
	for r in _wash_rects(win, rules):
		pieces.append(_wash_piece(win, r, rules))
	return {"pieces": pieces, "strength": _wash_strength(win, glow, float(rules.get("strength", 0.3)))}


## The warm light on window `win`'s own wall when that is not plaster (LitSpots.wall_look: the
## timber look's earthen plaster, "earth", or the yakisugi look's charred boards, "board"), by
## data/light.json "pools" → "wall" → "finishes" → its kind: {pieces (as wall_wash's), strength,
## color}. The same disc round the window as the pale wash, cut to the material: to its `bands`
## (heights clear of the rails and the beam), to its wall's `span` and round its front `posts`, so
## the timber stays dark; the shader keeps it to the warm, not pale pixels. A plaster window, or a
## kind without rules, gets none.
static func finish_wash(win: Dictionary, glow: float, rules: Dictionary) -> Dictionary:
	var fr: Dictionary = rules.get("finishes", {}).get(str(win.get("finish", "")), {})
	var none := {"pieces": [] as Array[Dictionary], "strength": 0.0, "color": Color.BLACK}
	if fr.is_empty():
		return none
	var span: Vector2 = win.get("span", Vector2(-INF, INF))
	var pieces: Array[Dictionary] = []
	for r in _wash_rects(win, rules):
		for band: Vector2 in win.get("bands", [Vector2(-INF, INF)]):
			var y0 := maxf(r[2], band.x)
			var y1 := minf(r[3], band.y)
			if y1 - y0 < 0.001:
				continue
			# The stretches along the wall between the posts.
			var runs: Array = [[maxf(r[0], span.x), minf(r[1], span.y)]]
			for post: Vector2 in win.get("posts", []):
				var next: Array = []
				for run in runs:
					if post.y <= run[0] or post.x >= run[1]:
						next.append(run)
						continue
					next.append([run[0], post.x])
					next.append([post.y, run[1]])
				runs = next
			for run in runs:
				if run[1] - run[0] >= 0.001:
					pieces.append(_wash_piece(win, [run[0], run[1], y0, y1], rules))
	return {"pieces": pieces, "strength": _wash_strength(win, glow, float(fr.get("strength", 0.2))),
		"color": Color(str(fr.get("color", "ffa050")))}


## The pale wash's rects round window `win`: [x0, x1, y0, y1] in cells along the wall from the
## window's middle (right of it +) and heights: `reach` either side, from the ground to `up` over
## the window, in four pieces round the pane (left, right, above, below; none under a door).
static func _wash_rects(win: Dictionary, rules: Dictionary) -> Array:
	var reach := maxf(float(rules.get("reach", 1.5)), 0.01)
	var c: Vector3 = win.pos
	var half: Vector2 = win.size / 2.0
	var top: float = c.y + half.y + float(rules.get("up", 0.6))
	var foot := minf(0.0, c.y - half.y)
	var out: Array = []
	for r in [[-reach, -half.x, foot, top], [half.x, reach, foot, top],
			[-half.x, half.x, c.y + half.y, top], [-half.x, half.x, foot, c.y - half.y]]:
		if r[1] - r[0] >= 0.001 and r[3] - r[2] >= 0.001:
			out.append(r)
	return out


## Rect `r` of _wash_rects on window `win`'s wall plane: {corners (top left first), uvs (-1..1
## from the window's middle, `reach` cells to the edge)}.
static func _wash_piece(win: Dictionary, r: Array, rules: Dictionary) -> Dictionary:
	var reach := maxf(float(rules.get("reach", 1.5)), 0.01)
	var right: Vector3 = Vector3.UP.cross(win.normal).normalized()
	var c: Vector3 = win.pos
	var corners: Array[Vector3] = []
	var uvs := PackedVector2Array()
	for p in [Vector2(r[0], r[3]), Vector2(r[1], r[3]), Vector2(r[1], r[2]), Vector2(r[0], r[2])]:
		corners.append(Vector3(c.x, p.y, c.z) + right * p.x)
		uvs.append(Vector2(p.x, c.y - p.y) / reach)
	return {"corners": corners, "uvs": uvs}


## A wash's strength at `glow`: `base`, a bigger pane (a door) a little brighter, as its pool is.
static func _wash_strength(win: Dictionary, glow: float, base: float) -> float:
	var area: float = win.size.x * win.size.y
	return maxf(base * clampf(sqrt(area / 0.35), 0.8, 1.5) * glow, 0.0)


## The walls the lit windows `windows` stand on, for the stone lanterns' wash (lamp_wash): one per
## wall plane and ends, {normal, right (along the wall, as wall_wash's), plane (the wall's offset
## along normal), span (its ends along right), finish ("" for plaster, else LitSpots.wall_look's
## kind), bands, posts (Vector2 from / to along right), panes ([x0, x1, y0, y1] along right / up:
## its windows, kept clear as the window's own wash keeps the pane)}. A window without a `span`
## stands for a wall of its own, as wide as a lantern's wash.
static func lamp_walls(windows: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for win in windows:
		var n: Vector3 = win.normal
		var right := Vector3.UP.cross(n).normalized()
		var a: float = win.pos.dot(right)
		var span: Vector2 = win.get("span", Vector2(-INF, INF))
		var ends := Vector2(a + span.x, a + span.y)
		var plane: float = win.pos.dot(n)
		var wall: Dictionary = {}
		for w in out:
			if w.normal.is_equal_approx(n) and absf(w.plane - plane) < 0.02 and _same(w.span.x, ends.x) and _same(w.span.y, ends.y):
				wall = w
		if wall.is_empty():
			var posts: Array[Vector2] = []
			for post: Vector2 in win.get("posts", []):
				posts.append(post + Vector2(a, a))
			wall = {"normal": n, "right": right, "plane": plane, "span": ends, "finish": str(win.get("finish", "")),
				"bands": win.get("bands", [Vector2(-INF, INF)]), "posts": posts, "panes": []}
			out.append(wall)
		var half: Vector2 = win.size / 2.0
		wall.panes.append([a - half.x, a + half.x, win.pos.y - half.y, win.pos.y + half.y])
	return out


static func _same(a: float, b: float) -> bool:
	return a == b or absf(a - b) < 0.02


## The warm wash stone lantern `lamp` ({pos: its fire box}) puts on `wall` (lamp_walls) when the
## lights glow `glow` (0..1), by data/light.json "pools" → "wall" → "lamp": {pieces (as
## wall_wash's, uvs -1..1 from the point of the wall square to the fire box, `reach` cells to the
## edge), strength, color, finish, at (that point, kept within the wall's ends), normal, own (the
## fire box: the lantern never hides its own wash)}. Only a wall the lantern stands in front of,
## nearer than `out` cells, takes it; it fades out linearly to `out` and is the window's wash of
## that material (strength, color) times `share`: a lantern is a small light, so its wash is
## weaker and smaller than a window's. It keeps to the wall's ends and, on earthen or board
## walls, to the finish's bands clear of the posts (as finish_wash); it keeps off the wall's
## panes. A finish without rules gets none.
static func lamp_wash(lamp: Dictionary, wall: Dictionary, glow: float, rules: Dictionary) -> Dictionary:
	var p: Vector3 = lamp.pos
	var none := {"pieces": [] as Array[Dictionary], "strength": 0.0, "color": Color.BLACK, "finish": wall.finish,
		"at": Vector3.ZERO, "normal": wall.normal, "own": p}
	var lr: Dictionary = rules.get("lamp", {})
	var d: float = p.dot(wall.normal) - wall.plane
	var out := maxf(float(lr.get("out", 1.8)), 0.01)
	var reach := maxf(float(lr.get("reach", 1.1)), 0.01)
	var ca: float = p.dot(wall.right)
	if glow <= 0.0 or d <= 0.0 or d >= out or ca + reach <= wall.span.x or ca - reach >= wall.span.y:
		return none
	var base := float(rules.get("strength", 0.3))
	var color := Color(str(rules.get("color", "ffa050")))
	if wall.finish != "":
		var fr: Dictionary = rules.get("finishes", {}).get(wall.finish, {})
		if fr.is_empty():
			return none
		base = float(fr.get("strength", 0.2))
		color = Color(str(fr.get("color", "ffa050")))
	var rects: Array = []
	var x0 := maxf(ca - reach, wall.span.x)
	var x1 := minf(ca + reach, wall.span.y)
	for band: Vector2 in (wall.bands if wall.finish != "" else [Vector2(-INF, INF)]):
		rects.append([x0, x1, maxf(maxf(p.y - reach, 0.0), band.x), minf(p.y + reach, band.y)])
	if wall.finish != "":
		for post: Vector2 in wall.posts:
			rects = _cut(rects, [post.x, post.y, -INF, INF])
	for pane: Array in wall.panes:
		rects = _cut(rects, pane)
	var pieces: Array[Dictionary] = []
	var origin: Vector3 = wall.normal * wall.plane
	for r: Array in rects:
		if r[1] - r[0] < 0.001 or r[3] - r[2] < 0.001:
			continue
		var corners: Array[Vector3] = []
		var uvs := PackedVector2Array()
		for q in [Vector2(r[0], r[3]), Vector2(r[1], r[3]), Vector2(r[1], r[2]), Vector2(r[0], r[2])]:
			corners.append(origin + wall.right * q.x + Vector3.UP * q.y)
			uvs.append(Vector2(q.x - ca, p.y - q.y) / reach)
		pieces.append({"corners": corners, "uvs": uvs})
	if pieces.is_empty():
		return none
	var at: Vector3 = origin + wall.right * clampf(ca, wall.span.x, wall.span.y) + Vector3.UP * p.y
	return {"pieces": pieces, "strength": base * float(lr.get("share", 0.5)) * (1.0 - d / out) * glow,
		"color": color, "finish": wall.finish, "at": at, "normal": wall.normal, "own": p}


## Every stone lantern's wash on the lit windows' walls (lamp_walls, lamp_wash) whose light
## reaches the wall: a solid building between the fire box and the wall drops it, a faded one lets
## its fade through (light_reaches). The eye's view of the wall is left to the caller.
static func lamp_washes(windows: Array, lamps: Array, glow: float, rules: Dictionary, occ: Occluders) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if glow <= 0.0 or lamps.is_empty():
		return out
	var walls := lamp_walls(windows)
	for l in lamps:
		for wall in walls:
			var lw := lamp_wash(l, wall, glow, rules)
			if lw.strength <= 0.0:
				continue
			if occ != null:
				lw.strength *= light_reaches(lw.at + wall.normal * 0.05, l.pos, occ)
			if lw.strength > 0.0:
				out.append(lw)
	return out


## Rects `rects` ([x0, x1, y0, y1]) with `hole` cut out of them: what is left of each, in up to
## four rects (left, right, below, above the hole).
static func _cut(rects: Array, hole: Array) -> Array:
	var out: Array = []
	for r: Array in rects:
		if hole[1] <= r[0] or hole[0] >= r[1] or hole[3] <= r[2] or hole[2] >= r[3]:
			out.append(r)
			continue
		var mx0 := maxf(r[0], hole[0])
		var mx1 := minf(r[1], hole[1])
		for c in [[r[0], mx0, r[2], r[3]], [mx1, r[1], r[2], r[3]],
				[mx0, mx1, r[2], maxf(r[2], hole[2])], [mx0, mx1, minf(r[3], hole[3]), r[3]]]:
			if c[1] - c[0] >= 0.001 and c[3] - c[2] >= 0.001:
				out.append(c)
	return out


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
