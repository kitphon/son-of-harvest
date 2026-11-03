class_name CameraLens
extends RefCounted
## The 3D view's follow camera lens (data/camera.json): how steeply the eye looks down, how
## wide it sees, and how far back it stands so every lens frames the farmer's feet the same.

const YAW := 45.0

var id := ""
var fov := 13.69      # vertical, degrees
var pitch := 26.6     # degrees down from level
var dist := 25.2      # from the target to the eye, world units
var back := Vector3(0.634, 0.448, 0.634)   # unit vector from the target towards the eye


## The lens `want` from data/camera.json, or the one it says to use when `want` is empty or unknown.
static func pick(data: Dictionary, want := "") -> CameraLens:
	var lenses: Dictionary = data.get("lenses", {})
	if want != "" and not lenses.has(want):
		push_warning("No lens " + want)
	var lid: String = want if lenses.has(want) else str(data.get("use", ""))
	var d: Dictionary = lenses.get(lid, {})
	var l := CameraLens.new()
	l.id = lid
	l.fov = float(d.get("fov", l.fov))
	l.pitch = float(d.get("pitch", l.pitch))
	var p := deg_to_rad(l.pitch)
	var y := deg_to_rad(YAW)
	l.back = Vector3(cos(p) * sin(y), sin(p), cos(p) * cos(y))
	l.dist = float(data.get("half_height", 3.025)) / tan(deg_to_rad(l.fov) / 2.0)
	return l


## The lens for this run: data/camera.json, `-- --lens=<id>` overriding its "use".
static func current() -> CameraLens:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/camera.json"))
	var want := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lens="):
			want = arg.trim_prefix("--lens=")
	return pick(data if data is Dictionary else {}, want)
