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

## The farmhouse in the flat view is drawn as house boxes on cells y 1..3 (FarmGrid.generate), so
## its lower edge is the line z = 4. A pool in front of a south wall starts at the wall (z 3.6)
## and would be drawn over the roof's last 6 px, so on the farm such pools are cut at this line.
## The 3D view is not touched (NightLights.pools_from keeps the full pools).
const FARM_ROOF_EDGE := 4.0

var windows: Array[Dictionary] = []   # LitSpots windows of this map
var lamps: Array[Dictionary] = []     # LitSpots lanterns
var roof_edge := INF                  # map units: pools facing south do not go above this line
## This frame's brightness (Game.window_light) and what it lights: the pools (NightLights.pools_from),
## all in map units.
var glow := 0.0
var pools: Array[Dictionary] = []
## Today's festival on this map: its lights (FestivalProps.glows, 3D map units) light the ground
## round them while it is on, as strong as they stand out (`fest_dark`, FestivalGlow.darkness).
var festival := ""
var festival_map := ""
var festival_lights: Array[Dictionary] = []
var fest_dark := 0.0

## The CanvasModulate over the picture (main_2d sets it).
var tint: CanvasModulate
var _pool_layer: Node2D
var _halo_layer: Node2D
var _pane_layer: Node2D


## `props` are the map's props (MapData.props); the farm has the farmhouse (and the greenhouse once
## built, LitSpots.farm) and no lanterns.
## `map_id`: the map, for today's festival lights there (FestivalProps.glows_of).
func setup(props: Array, on_farm: bool, map_id := "") -> NightView:
	if on_farm:
		windows = LitSpots.farm(Game.house_built)   # the farmhouse, and the greenhouse once built
		roof_edge = FARM_ROOF_EDGE
	else:
		var spots := LitSpots.of_map(props)
		windows = spots.windows
		lamps = spots.lamps
	var fest := Game.festival_today()
	if map_id != "" and fest != "" and str(Festivals.get_festival(fest).get("map", "")) == map_id:
		festival = fest
		festival_map = map_id
		festival_lights = FestivalProps.glows_of(fest, map_id)
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
	if Game.window_light() != glow or festival_dark() != fest_dark:
		_refresh()


## How much the festival's lights stand out now: FestivalGlow.darkness while it is on here, else 0.
func festival_dark() -> float:
	if festival == "" or not Festivals.on_now(festival, festival_map, Game.hour * 60 + Game.minute):
		return 0.0
	var d := FestivalGlow.darkness(Game.light_color())
	return d if d > 0.05 else 0.0


## Works out the brightness and the pools, and redraws when it changed.
func _refresh() -> void:
	glow = Game.window_light()
	fest_dark = festival_dark()
	var rules: Dictionary = Game.light_data().get("pools", {})
	pools = NightLights.pools_from(windows, lamps, glow, rules)
	pools.append_array(NightLights.festival_pools(festival_lights, fest_dark, rules))
	visible = not pools.is_empty()
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


## A pool's drawn shape: [polygon, uvs] (the falloff's UVs). A south-facing pool is cut at
## roof_edge so it stops at the roof's lower edge; the cut keeps the UVs of the cut points.
func pool_shape(p: Dictionary) -> Array:
	var poly := pool_polygon(p)
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	if roof_edge < INF and p.normal.z > 0.5:
		return clip_top(poly, uvs, roof_edge * T)
	return [poly, uvs]


## The polygon cut to y >= `y_min` (Sutherland-Hodgman on one edge), each point with its UV.
static func clip_top(poly: PackedVector2Array, uvs: PackedVector2Array, y_min: float) -> Array:
	var out_p := PackedVector2Array()
	var out_u := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var ua := uvs[i]
		var ub := uvs[(i + 1) % n]
		var a_in := a.y >= y_min
		var b_in := b.y >= y_min
		if a_in:
			out_p.append(a)
			out_u.append(ua)
		if a_in != b_in:
			var t := (y_min - a.y) / (b.y - a.y)
			out_p.append(a.lerp(b, t))
			out_u.append(ua.lerp(ub, t))
	return [out_p, out_u]


func _draw_pools() -> void:
	for p in pools:
		var shape := pool_shape(p)
		if shape[0].size() >= 3:
			_pool_layer.draw_colored_polygon(shape[0], Color(1, 1, 1, clampf(p.strength, 0.0, 1.0)), shape[1])


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
