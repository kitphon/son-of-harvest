extends Node3D
## The main view: a 3D farm seen through a fixed, diagonal, narrow camera that follows the
## player, with the farmer and field objects as camera-facing sprites. Other maps (the house,
## the village) are MapWorlds; a change of map fades out, rebuilds the world and fades in.
##
## Camera geometry is Harvest Moon: Back to Nature's field camera, measured in the RE project
## (REA-Harvest_moon_ps1 NOTES.md "Ground truth: ePSXe save state" / "Camera"): rotation yaw 45°,
## pitch 26.6°, the player's feet 10087 units in front of the eye, projection H = 1000 on a
## 240-line screen. One cell there is 400 units, here 1 unit.

const T := 16
const CAM_BACK := Vector3(0.634, 0.448, 0.634)   # from the target towards the eye (unit)
const CAM_DIST := 10087.0 / 400.0                 # 25.2 cells
const CAM_FOV := 13.69                            # vertical, 2 * atan(120 / 1000)
const CAM_MARGIN := Vector2(4, 3)                 # keep the view inside the fence

var player: Player
var sprite: Sprite3D
var anim := FarmerAnim.new()
var target_mark: MeshInstance3D
var area_marks: Array[MeshInstance3D] = []   # brackets on every cell of a charging tool's area
var charge_pips: Sprite3D
var cam: Camera3D
var tint: ColorRect
var weather: WeatherFX
var world: FarmWorld
var env: Environment
var flash: ColorRect
var fade: MapFade
var lightning := Lightning.new()


func _ready() -> void:
	# The player's movement / collision is the 2D Player (in cell pixels), kept invisible;
	# the 3D sprite follows it.
	player = Player.new()
	player.farm = Game.farm
	player.visible = false
	player.action.connect(FarmActions.on_action)
	add_child(player)

	sprite = FarmWorld.make_sprite(PlaceholderArt.tex(anim.key(Vector2i.DOWN)))
	add_child(sprite)
	var shadow := MeshInstance3D.new()
	var disc := PlaneMesh.new()
	disc.size = Vector2(0.6, 0.6)
	shadow.mesh = disc
	shadow.material_override = FarmWorld.flat_material(Color(0, 0, 0, 0.3))
	shadow.position = Vector3(0, 0.01, 0)
	sprite.add_child(shadow)

	target_mark = MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(1, 1)
	target_mark.mesh = quad
	# Brackets on the cell in front, where the tool lands (not the cell the farmer stands on).
	var mark_mat := FarmWorld.flat_material(Color(1, 1, 1, 0.99))
	mark_mat.albedo_texture = PlaceholderArt.tex("target")
	mark_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	target_mark.material_override = mark_mat
	add_child(target_mark)
	charge_pips = FarmWorld.make_sprite(PlaceholderArt.tex(PlaceholderArt.charge_key(0, 1)))
	charge_pips.position = Vector3(0, 1.3, 0)   # over the farmer's head
	charge_pips.visible = false
	sprite.add_child(charge_pips)

	cam = Camera3D.new()
	cam.fov = CAM_FOV
	cam.far = 200.0
	add_child(cam)
	cam.make_current()

	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("8fc6e8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 0.7
	add_child(sun)

	weather = WeatherFX.new()
	add_child(weather)
	weather.show_weather(Game.weather_style())
	lightning.reset(Game.lightning_style())

	# Day / night and the weather tint: multiply the whole 3D picture, under the HUD.
	var layer := CanvasLayer.new()
	layer.layer = 0
	tint = ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mul := CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	tint.material = mul
	layer.add_child(tint)
	# Lightning: a short wash of pale sky light added over the picture (Lightning times it).
	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flash.material = add
	flash.color = Color.BLACK
	layer.add_child(flash)
	add_child(layer)
	add_child(Hud.new())
	fade = MapFade.new()
	add_child(fade)
	add_child(TextBox.new())
	add_child(PauseScreen.new())

	Game.minute_passed.connect(_update_tint)
	Game.day_started.connect(_on_day_started)
	Game.map_changed.connect(func(_id): fade.run(_enter_map))
	Game.settings_changed.connect(func(): lightning.reset(Game.lightning_style()))
	_enter_map()
	Game.map_arrived()


## Builds the world for Game.maps and puts the farmer where it says.
func _enter_map() -> void:
	if world != null:
		world.queue_free()
	var m := Game.maps.current()
	if Game.maps.on_farm():
		world = FarmWorld.new()
		world.setup(Game.farm, m.gate_cells())
	else:
		world = MapWorld.new()
		(world as MapWorld).build(m)
	add_child(world)
	move_child(world, 0)
	player.farm = Game.farm
	player.position = Game.maps.pos
	player.facing = Game.maps.facing
	player.cancel_charge()
	env.background_color = m.background
	target_mark.visible = Game.maps.on_farm()
	_show_weather()
	_update_tint()
	_follow()


## Weather falls outdoors only; the farm ground shows the snow lying.
func _show_weather() -> void:
	weather.show_weather({} if Game.indoors() else Game.weather_style())
	lightning.reset({} if Game.indoors() else Game.lightning_style())
	world.set_snow(Game.snow_cover / 100.0)


func _unhandled_input(event: InputEvent) -> void:
	FarmActions.handle_input(event)


func _process(delta: float) -> void:
	anim.step(delta, player.moving, player.running, Game.body_state() != "fine")
	_update_flash(delta)
	_follow()


func _follow() -> void:
	var feet := Vector3(player.position.x / T, 0, player.position.y / T)
	sprite.position = feet
	sprite.texture = PlaceholderArt.tex(anim.key(player.facing))
	sprite.flip_h = FarmerAnim.is_mirrored(player.facing)
	var tc := player.target_cell()
	target_mark.position = Vector3(tc.x + 0.5, 0.02, tc.y + 0.5)
	if Game.maps.on_farm():
		_show_charge()

	var m := Game.maps.current()
	var target := Vector3(_clamp_view(feet.x, CAM_MARGIN.x, m.w), 0, _clamp_view(feet.z, CAM_MARGIN.y, m.h))
	cam.position = target + CAM_BACK * CAM_DIST
	cam.look_at(target, Vector3.UP)
	weather.follow(target)


## The camera target kept `margin` inside a map side of `size`; a small room stays centred.
static func _clamp_view(v: float, margin: float, size: int) -> float:
	if size <= margin * 2:
		return size / 2.0
	return clampf(v, margin, size - margin)


## While a tool charges: the brackets cover the whole area and pips count the steps.
func _show_charge() -> void:
	var cells: Array[Vector2i] = []
	if player.charging:
		cells = player.area_preview()
	target_mark.visible = not player.charging
	while area_marks.size() < cells.size():
		var m := MeshInstance3D.new()
		m.mesh = target_mark.mesh
		m.material_override = target_mark.material_override
		add_child(m)
		area_marks.append(m)
	for i in area_marks.size():
		area_marks[i].visible = i < cells.size()
		if i < cells.size():
			area_marks[i].position = Vector3(cells[i].x + 0.5, 0.02, cells[i].y + 0.5)
	charge_pips.visible = player.charging
	if player.charging:
		charge_pips.texture = PlaceholderArt.tex(
			PlaceholderArt.charge_key(player.charge, Game.max_charge(Game.current_tool())))


## The farmer is put home by the map change (Game.go_home) that comes with the new day.
func _on_day_started() -> void:
	player.cancel_charge()
	_show_weather()
	_update_tint()


func _update_flash(delta: float) -> void:
	var b := lightning.step(delta) if Game.ticking() else 0.0
	if lightning.started: Sfx.thunder_after_flash()
	var style := Game.lightning_style()
	var sky := Color(style.get("sky", "ffffff")) * float(style.get("strength", 0.0)) * b
	flash.color = Color(sky.r, sky.g, sky.b, 1.0)


## Day / night light outdoors; a room has its own steady lamp light.
func _update_tint() -> void:
	var m := Game.maps.current()
	tint.color = m.light if m.light != null else Game.light_color()
