class_name NightView
extends Node2D
## The flat view's lit windows and lanterns at night: a warm strip on every lit window and
## shoji door of the farmhouse and the village houses, a small round glow and a stone lantern's
## fire, and a soft warm pool on the ground in front of each window and round each lantern, its
## edge cut into dithered steps. The same spots (LitSpots), the same pools (NightLights.pools_from)
## and the same brightness (Game.window_light: data/light.json "windows" / "pools", dusk to dawn,
## the lit hours) as the 3D view; only the drawing is from above.
## The node is a child of the FarmView / MapView, drawn after the ground and buildings and before
## the villagers, animals and the farmer, so the glow lies under the figures and never tints them.
## The scene's CanvasModulate (the night tint, `tint`) multiplies everything drawn, glow included,
## so the shader divides its colour by it: the warm light lands on the tinted ground as it is.

const T := 16
const GROUP := "night_view"

const SHADER := """
shader_type canvas_item;
render_mode blend_add;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

uniform vec4 warm = vec4(1.0, 0.7, 0.3, 1.0);
uniform vec4 tint = vec4(1.0);
uniform bool soft = true;
varying vec2 spot;

void vertex() {
	spot = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float k = 1.0;
	if (soft) {
		k = 1.0 - smoothstep(0.1, 1.0, length(UV * 2.0 - 1.0));
		ivec2 q = ivec2(mod(floor(spot), 4.0));
		k = clamp(floor(k * 6.0 + BAYER[q.y * 4 + q.x] / 16.0) / 6.0, 0.0, 1.0);
	}
	COLOR = vec4(warm.rgb / max(tint.rgb, vec3(0.05)), k * COLOR.a);
}
"""

var windows: Array[Dictionary] = []   # LitSpots windows of this map
var lamps: Array[Dictionary] = []     # LitSpots lanterns
## This frame's brightness (Game.window_light) and what it lights: the pools (NightLights.pools_from),
## all in map units.
var glow := 0.0
var pools: Array[Dictionary] = []

## The CanvasModulate over the picture (main_2d sets it).
var tint: CanvasModulate
var _pool_layer: Node2D
var _halo_layer: Node2D
var _pane_layer: Node2D


## `props` are the map's props (MapData.props); the farm has the farmhouse and no lanterns.
func setup(props: Array, on_farm: bool) -> NightView:
	if on_farm:
		windows = LitSpots.farmhouse()
	else:
		var spots := LitSpots.of_map(props)
		windows = spots.windows
		lamps = spots.lamps
	return self


func _ready() -> void:
	add_to_group(GROUP)
	_pool_layer = _layer("Pools", _material("pools", true), _draw_pools)
	_halo_layer = _layer("Halos", _material("windows", true), _draw_halos)
	_pane_layer = _layer("Panes", _material("windows", false), _draw_panes)
	_refresh()


func _layer(n: String, m: ShaderMaterial, drawer: Callable) -> Node2D:
	var c := Node2D.new()
	c.name = n
	c.material = m
	c.draw.connect(drawer)
	add_child(c)
	return c


## A layer's material: the colour of data/light.json `rules` ("windows" or "pools").
static func _material(rules: String, soft: bool) -> ShaderMaterial:
	var s := Shader.new()
	s.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = s
	var col := Color("ff9a48") if rules == "pools" else Color("ffb25c")
	m.set_shader_parameter("warm", Color(str(Game.light_data().get(rules, {}).get("color", col.to_html(false)))))
	m.set_shader_parameter("soft", soft)
	return m


func _process(_delta: float) -> void:
	if tint != null:
		for l: Node2D in [_pool_layer, _halo_layer, _pane_layer]:
			(l.material as ShaderMaterial).set_shader_parameter("tint", tint.color)
	if Game.window_light() != glow:
		_refresh()


## Works out the brightness and the pools, and redraws when it changed.
func _refresh() -> void:
	glow = Game.window_light()
	pools = NightLights.pools_from(windows, lamps, glow, Game.light_data().get("pools", {}))
	visible = glow > 0.0 and (not windows.is_empty() or not lamps.is_empty())
	for l: Node2D in [_pool_layer, _halo_layer, _pane_layer]:
		if l != null:
			l.queue_redraw()


## Map units (x east, z south) to this node's pixels.
static func px(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z) * T


## A pool's polygon in pixels, in the order of its round falloff's UVs.
static func pool_polygon(p: Dictionary) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c in NightLights.pool_corners(p):
		out.append(px(c))
	return out


## A window's strip on its wall seen from above: 2 px thick, as wide as the pane.
static func pane_rect(win: Dictionary) -> Rect2:
	var at := px(win.pos)
	var w: float = win.size.x * T
	if win.normal.x > 0.5:   # the east wall: the strip runs along z
		return Rect2(at.x - 2.0, at.y - w / 2.0, 2.0, w).abs()
	return Rect2(at.x - w / 2.0, at.y - 2.0, w, 2.0)


func _draw_pools() -> void:
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	for p in pools:
		_pool_layer.draw_colored_polygon(pool_polygon(p), Color(1, 1, 1, clampf(p.strength, 0.0, 1.0)), uvs)


func _draw_halos() -> void:
	var rules: Dictionary = Game.light_data().get("windows", {})
	var lamp: Dictionary = Game.light_data().get("pools", {}).get("lamp", {})
	var a := float(rules.get("halo", 0.35)) * glow
	for win in windows:
		var r := pane_rect(win)
		var size: float = win.size.x * T * float(rules.get("halo_size", 2.4))
		_halo_layer.draw_rect(Rect2(r.get_center() - Vector2(size, size) / 2.0, Vector2(size, size)), Color(1, 1, 1, a))
	for l in lamps:
		var size := float(lamp.get("glow_size", 0.7)) * T
		_halo_layer.draw_rect(Rect2(px(l.pos) - Vector2(size, size) / 2.0, Vector2(size, size)),
			Color(1, 1, 1, float(lamp.get("glow", 0.45)) * glow))


func _draw_panes() -> void:
	var a := float(Game.light_data().get("windows", {}).get("pane", 0.85)) * glow
	for win in windows:
		_pane_layer.draw_rect(pane_rect(win), Color(1, 1, 1, a))
	for l in lamps:
		_pane_layer.draw_rect(Rect2(px(l.pos) - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, a))
