extends SceneTree
## A farm building on its own: the farmhouse (FarmWorld._make_house: walls, engawa, the
## thatched Minka roof), or with `--what=coop` / `--what=barn` the coop or the barn (their
## Minka.gable roofs): pictures of it from round about, and a .glb of it to open in Blender. Run:
##   Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/house_model.gd -- --shots=shots
## (writes shots/<what>_<view>.png; needs a window, so not --headless), or
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/house_model.gd -- --glb=models/farmhouse.glb
## (models/ has a .gdignore, so Godot leaves the file alone). The game itself builds the house
## from code; the .glb is a copy to look at or start real art from, not something it loads.

const VIEWS := {   # name: [yaw, pitch, distance] round the house's middle, degrees / units
	"front": [45.0, 30.0, 14.0],     # the game's own side, from further back
	"left": [-20.0, 25.0, 13.0],
	"back": [215.0, 30.0, 14.0],
	"above": [45.0, 60.0, 14.0],
}
const CENTERS := {   # each building's middle, where the views look
	"house": Vector3(4.5, 1.6, 2.3),
	"coop": Vector3(15.5, 1.3, 2.5),
	"barn": Vector3(21.5, 1.3, 2.5),
}

var _house: Node3D   # a FarmWorld; loaded once the autoloads are in (it uses Game)
var _glb := ""
var _what := "house"
var _cam: Camera3D
var _shots := ""
var _views: Array = VIEWS.keys()
var _frame := 0


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots = "res://" + arg.trim_prefix("--shots=")
		elif arg.begins_with("--what="):
			_what = arg.trim_prefix("--what=")
		elif arg.begins_with("--glb="):
			_glb = "res://" + arg.trim_prefix("--glb=")


func _start() -> void:
	_house = load("res://scripts/world3d/farm_world.gd").new()
	match _what:   # loaded, not named: the class names need the autoloads in first
		"coop": load("res://scripts/world3d/coop_props.gd").coop(_house)
		"barn": load("res://scripts/world3d/barn_props.gd").barn(_house)
		_: _house._make_house()
	root.add_child(_house)
	if _glb != "":
		_export(_glb)
	if _shots != "":
		DirAccess.make_dir_recursive_absolute(_shots)
		_stage()


## Ground, sky light and sun as in the game (Main3D's numbers), and a camera.
func _stage() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	ground.mesh = plane
	ground.material_override = StandardMaterial3D.new()
	ground.material_override.albedo_color = Color("6fae4a")
	ground.position = CENTERS[_what] * Vector3(1, 0, 1)
	root.add_child(ground)
	var main: GDScript = load("res://scripts/main_3d.gd")
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("8fc6e8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = main.SKY_LIGHT
	env.ambient_light_energy = main.SKY_ENERGY
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -40, 0)
	sun.light_color = main.SUN_COLOR
	sun.light_energy = main.SUN_ENERGY
	sun.shadow_enabled = true
	root.add_child(sun)
	_cam = Camera3D.new()
	_cam.fov = 28.0
	root.add_child(_cam)
	_cam.make_current()
	_aim(_views[0])


func _aim(view: String) -> void:
	var v: Array = VIEWS[view]
	var yaw := deg_to_rad(v[0])
	var pitch := deg_to_rad(v[1])
	var back := Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))
	var center: Vector3 = CENTERS[_what]
	_cam.position = center + back * float(v[2])
	_cam.look_at(center, Vector3.UP)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_start()
	if _shots == "":
		return true
	if _frame % 8 == 0:   # a few frames for each view to settle (shadows), then save it
		var view: String = _views.pop_front()
		var img := root.get_texture().get_image()
		img.save_png(_shots.path_join("%s_%s.png" % [_what, view]))
		print("house_model: wrote %s_%s.png" % [_what, view])
		if _views.is_empty():
			return true
		_aim(_views[0])
	return false


## The house as a .glb: snow tops (shader, only a look) are left out.
func _export(path: String) -> void:
	for n in _house.get_children():
		if n is GeometryInstance3D and n.material_override is ShaderMaterial:
			n.queue_free()
			_house.remove_child(n)
	for n in _house.get_children():
		n.owner = _house
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(_house, state)
	if err == OK:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		err = doc.write_to_filesystem(state, path)
	print("house_model: %s %s" % [path, "written" if err == OK else "failed (%s)" % error_string(err)])
