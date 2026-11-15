class_name VistaRules
extends RefCounted
## The view of the mountains (data/vista.json): the mountains' ground past the maps and the
## viewpoints where the camera turns toward them and tilts up. Pure: VistaMountain builds the
## mesh from height(), Main3D eases its camera by view_at() / step() / blend(). test_vista.

const PATH := "res://data/vista.json"

static var _cfg := {}


static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _cfg


## `-- --vista` on the command line: standing in a viewpoint, the camera is there from the first
## frame (no ease), for screenshots.
static func forced() -> bool:
	return "--vista" in OS.get_cmdline_user_args()


## Does map `id` show the mountains?
static func on_map(id: String) -> bool:
	return id in config().get("maps", [])


## The maps' rectangles on the plan (Rect2, cells).
static func map_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var at := WorldPlan.places()
	for id in at:
		var m := MapManager.data(id)
		out.append(Rect2(Vector2(at[id]), Vector2(m.w, m.h)))
	return out


## How far plan point `p` lies from the nearest map (0 inside one).
static func map_distance(p: Vector2, rects: Array[Rect2]) -> float:
	var best := INF
	for r in rects:
		var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
		var dz := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
		best = minf(best, Vector2(dx, dz).length())
	return best


## The mountain `m`'s ground at plan point `p` (world units over the land; 0 where it does not
## rise), `rects` the maps' (map_rects): the ridge's height less the slope down from it, lumps on
## top, eased down to nothing near any map.
static func height(m: Dictionary, p: Vector2, rects: Array[Rect2]) -> float:
	var ridge: Array = m.ridge
	var best := -INF
	for i in ridge.size() - 1:
		var a := Vector2(float(ridge[i][0]), float(ridge[i][1]))
		var b := Vector2(float(ridge[i + 1][0]), float(ridge[i + 1][1]))
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var top := lerpf(float(ridge[i][2]), float(ridge[i + 1][2]), t)
		best = maxf(best, top - float(m.slope) * p.distance_to(a + ab * t))
	var h := maxf(best, 0.0)
	if h > 0.0:
		h += float(m.lumps) * (noise(p / float(m.lump_scale)) - 0.35) * clampf(h / 4.0, 0.0, 1.0)
	var foot: Array = m.foot
	var k := smoothstep(float(foot[0]), float(foot[1]), map_distance(p, rects))
	return maxf(h, 0.0) * k


## The highest the ridge goes (for the snow line).
static func peak(m: Dictionary) -> float:
	var top := 0.0
	for r in m.ridge:
		top = maxf(top, float(r[2]))
	return top + float(m.lumps)


## A smooth value noise, 0..1.
static func noise(p: Vector2) -> float:
	var i := p.floor()
	var f := p - i
	f = f * f * (Vector2(3, 3) - 2.0 * f)
	var a := _hash(i)
	var b := _hash(i + Vector2(1, 0))
	var c := _hash(i + Vector2(0, 1))
	var d := _hash(i + Vector2(1, 1))
	return lerpf(lerpf(a, b, f.x), lerpf(c, d, f.x), f.y)


static func _hash(p: Vector2) -> float:
	var v := sin(p.x * 127.1 + p.y * 311.7) * 43758.5453
	return v - floorf(v)


## The viewpoint on map `map_id` at cell `c`, {} for none.
static func view_at(map_id: String, c: Vector2i) -> Dictionary:
	for v: Dictionary in config().get("views", []):
		if str(v.map) == map_id:
			var r: Array = v.rect
			if Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])).has_point(c):
				return v
	return {}


## The view weight `w` (0 play camera .. 1 the viewpoint's) moved on by `delta` seconds toward
## 1 inside a viewpoint (`inside`), toward 0 outside, over `ease` seconds.
static func step(w: float, inside: bool, delta: float, ease_s: float) -> float:
	var d := delta / maxf(ease_s, 0.01)
	return clampf(w + d if inside else w - d, 0.0, 1.0)


## The camera between `lens` (CameraLens) and viewpoint `view` at weight `w` (eased):
## {back: unit vector target -> eye, dist, fov, lift}.
static func blend(lens: CameraLens, view: Dictionary, w: float) -> Dictionary:
	var out := {"back": lens.back, "dist": lens.dist, "fov": lens.fov, "lift": 0.0}
	if view.is_empty() or w <= 0.0:
		return out
	var e := smoothstep(0.0, 1.0, w)
	var yaw0 := CameraLens.YAW
	var yaw1 := float(view.yaw)
	var turn := wrapf(yaw1 - yaw0, -180.0, 180.0)   # the short way round
	var yaw := deg_to_rad(yaw0 + turn * e)
	var pitch := deg_to_rad(lerpf(lens.pitch, float(view.pitch), e))
	out.back = Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))
	out.dist = lerpf(lens.dist, float(view.dist), e)
	out.fov = lerpf(lens.fov, float(view.fov), e)
	out.lift = float(view.get("lift", 0.0)) * e
	return out
